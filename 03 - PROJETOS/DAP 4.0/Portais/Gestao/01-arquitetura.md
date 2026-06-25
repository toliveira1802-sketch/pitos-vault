---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-gestao/README]]"
tags:
  - dap40
  - arquitetura
  - gestao
---

# Arquitetura — DAP Gestão

## Stack

| Camada       | Tecnologia                                      | Por quê                                                |
| ------------ | ----------------------------------------------- | ------------------------------------------------------ |
| **Server**   | Node.js 22 + Express 5 + TypeScript             | Mesmo runtime do client. Express 5 tem async errors.   |
| **Client**   | React 18 + Vite 7 + Tailwind 3 + shadcn (Radix) | Stack idêntica ao dap-operacao — familiaridade = velocidade. |
| **Routing**  | wouter (hash router)                            | 1 KB, zero deps, SPA estática deployável em qualquer lugar. |
| **State**    | TanStack Query v5                               | Server state separado de client state.                 |
| **DB**       | Supabase Postgres + `@supabase/supabase-js`    | Read-mostly, multi-fonte, `gestao` schema isolado.     |
| **Auth**     | passport-local + bcrypt + express-session       | Cookie httpOnly, sem JWT (sessão server-side).         |
| **Sessions** | `memorystore` (TTL 24h, sweep 60min)            | Single-process pra v0; trocar pra Postgres connect-pg-simple quando virar multi-instance. |
| **Security** | helmet (CSP estrito) + express-rate-limit + SameSite=Lax | Defesa em profundidade.                            |
| **Process**  | systemd (`dap-gestao.service`, port 5003)       | Restart on-failure, journal logging, alinha com dap-operacao. |
| **Edge**     | Cloudflare Tunnel (mesmo `dap4`) + TLS auto     | Sem porta exposta, sem certbot, DDoS protection.       |

## Topologia

```
Browser ─── HTTPS ───> Cloudflare Edge (gestao.doctorautoprime40.com)
                         │
                         │ tunnel "dap4" (mTLS)
                         ▼
                    cloudflared (VPS 76.13.170.42, systemd)
                         │ HTTP
                         ▼
                Express :5003 (dap-gestao.service)
                    ├─ /api/auth/*  → routes/auth.ts (login/logout/me)
                    ├─ /assets/*    → Vite build (dist/public/assets)
                    └─ /*           → SPA fallback (index.html)
                         │
                         │ @supabase/supabase-js (HTTPS, REST)
                         │ SUPABASE_SERVICE_ROLE_KEY (bypass RLS)
                         ▼
                   Supabase DOCTOR PRIME (acuufrgoyjwzlyhopaus)
                         └── schema gestao (5 tabelas)
                              ├── organizations (1)
                              ├── users (1: admin via BOOTSTRAP)
                              ├── kpi_snapshots (0 — job v1)
                              ├── okrs (0 — UI v1)
                              └── adrs (0 — UI v1)
```

## Decisões técnicas relevantes

### 1. `@supabase/supabase-js` em vez de drizzle-pg
- **Por quê**: Gestão é **read-mostly aggregator**. Maioria das queries são simples (lista de orgs, lista de OKRs do ciclo, snapshot do dia). `@supabase/supabase-js` dá API simples (`.from().select()`), tipos auto-gerados via Supabase CLI quando precisar, e Realtime built-in pra dashboards live.
- **Trade-off**: pra queries complexas multi-tabela, drizzle (que dap-operacao usa) tem mais ergonomia. Aceito — Gestão raramente precisa disso.

### 2. Schema isolado `gestao` no DOCTOR PRIME
- **Por quê**: mesmo Postgres do dap-operacao (`oficina`) e do P1 legacy (`public`). Cross-schema joins triviais quando v1 cruzar leads + OS + OKRs.
- **Single source of truth**: 1 backup, 1 billing, 1 monitoring, 1 Supabase MCP credencial.

### 3. Single-process, memorystore (mesmo padrão dap-operacao)
- **Por quê**: Audiência é executivo (chairman, diretor, CFO) — múltiplos acessos simultâneos, mas baixíssima carga de QPS. Single-process aguenta tranquilamente.
- Sessions in-memory são suficientes; multi-instance só justifica quando houver SLA crítico, que não há pra portal executivo.

### 4. RLS habilitado mas server bypassa via service_role
- **Por quê**: Server usa `SUPABASE_SERVICE_ROLE_KEY` (JWT que ignora RLS). Toda autenticação acontece no server (passport-local). Cliente nunca toca diretamente o Supabase.
- RLS habilitado serve como defense-in-depth: se algum dia expusermos o schema via PostgREST autenticado, default deny protege.

### 5. Read-mostly + cache agressivo (planejado v1)
- TanStack Query staleTime de 5min nas views agregadas — KPIs executivos não mudam minuto-a-minuto.
- Job diário de snapshot grava `kpi_snapshots` antes do horário comercial (cron 6h da manhã).

### 6. Bootstrap admin obrigatório em produção
- Em `NODE_ENV=production`, server **recusa subir** sem `BOOTSTRAP_ADMIN_PASSWORD` (mín. 12 chars) caso a tabela `gestao.users` esteja vazia.
- Em dev/test, seedara 4 personas com senhas óbvias pro fluxo de testing rápido.

### 7. Code-split com vendor chunks
Stack idêntica ao dap-operacao — mesmo manualChunks (formato objeto, sem circular dep).

```
vendor-react       react + react-dom + scheduler + wouter
vendor-radix       @radix-ui/* + cmdk + vaul
vendor-forms       rhf + @hookform + zod
vendor-tanstack    @tanstack/react-query
vendor-supabase    @supabase/supabase-js
```

## Segurança

### Headers (helmet defaults + CSP custom)
- `Strict-Transport-Security: max-age=31536000; includeSubDomains` (HSTS 1 ano)
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: SAMEORIGIN`
- CSP: `script-src 'self' https://static.cloudflareinsights.com` (CF Web Analytics permitido)

### Auth flow
1. `POST /api/auth/login` — bcrypt compare contra `gestao.users`, set `req.session.userId` + `organizationId`
2. Cookie `connect.sid` retorna com `HttpOnly; Secure; SameSite=Lax; Max-Age=86400`
3. Toda rota `/api/*` (exceto login/me/logout) passa por `requireAuth`
4. `requireRole("admin"|"chairman"|"diretor"|"cfo")` adiciona check de role pra rotas privilegiadas

### Rate limiting
- `POST /api/auth/login`: **5 tentativas/min/IP** (express-rate-limit), `skipSuccessfulRequests: true`.

### Service role isolation
- `SUPABASE_SERVICE_ROLE_KEY` **só** usada server-side (em `server/storage.ts`).
- Nunca exposta no bundle do cliente.
- Cliente fala apenas com `/api/*` do nosso server, que repassa via service role.

## Schema `gestao`

5 tabelas. Multi-tenant por `organization_id`. RLS habilitado em todas (default deny — server bypassa via service role).

| Tabela              | Função                                                                        |
| ------------------- | ----------------------------------------------------------------------------- |
| `organizations`     | Tenant root. Default seed: `dap-prime`.                                       |
| `users`             | Backend users (passport-local, bcrypt 10 rounds). Roles: admin/chairman/diretor/cfo. |
| `kpi_snapshots`     | Snapshot diário de KPI por unidade × métrica (`unit_slug`, `metric_key`, `metric_value`). Unique por (org × unit × metric × date). |
| `okrs`              | Objective + Key Result, por ciclo (`2026-Q2`, `2026-H2`...). Status machine.    |
| `adrs`              | Strategic Decision Records numerados por org. Suporta supersede chain.        |

## Trade-offs reconhecidos

| Trade-off                    | Por que aceitamos                                                              |
| ---------------------------- | ------------------------------------------------------------------------------ |
| Sessions in-memory (memorystore) | Single-process, baixa carga executiva — não precisa multi-instance.        |
| sem cache local de KPIs      | TanStack Query staleTime resolve perceptualmente; cache pesado é prematuro.    |
| @supabase/supabase-js só      | Suficiente pra v0; drizzle se justificar em features específicas no futuro.   |
| Latência ~80–120ms (cross-region) | DOCTOR PRIME us-west-2 — refresh de KPI 5min torna isso irrelevante.       |
