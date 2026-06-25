---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-operacao/README]]"
tags:
  - dap40
  - arquitetura
---

# Arquitetura

## Stack

| Camada       | Tecnologia                                       | Por quê                                                |
| ------------ | ------------------------------------------------ | ------------------------------------------------------ |
| **Server**   | Node.js 22 + Express 5 + TypeScript              | Mesmo runtime do client. Express 5 tem async errors.   |
| **Client**   | React 18 + Vite 7 + Tailwind 3 + shadcn (Radix)  | Build rápido, lib madura, design system consistente.   |
| **Routing**  | wouter (hash router)                             | 1KB, zero deps, SPA estática deployável em qualquer lugar. |
| **State**    | TanStack Query v5                                | Server state separado de client state.                 |
| **DB**       | SQLite via libsql + Drizzle ORM                  | Zero ops, ACID, suficiente pra single-process.         |
| **Auth**     | passport-local + bcrypt + express-session        | Cookie httpOnly, sem JWT (sessão server-side).         |
| **Sessions** | `memorystore` (TTL 24h, sweep 60min)             | Sem leak, swap-in pra Redis quando precisar.           |
| **Security** | helmet (CSP estrito) + express-rate-limit + CSRF intrínseco via SameSite=Lax | Defesa em profundidade. |
| **Process**  | systemd (`dap-operacao.service`)                 | Restart on-failure, journal logging, alinha com VPS.   |
| **Edge**     | Cloudflare Tunnel + TLS auto                     | Sem porta exposta, sem certbot, DDoS protection grátis. |

## Topologia

```
Browser ─── HTTPS ───> Cloudflare Edge
                         │
                         │ tunnel (mTLS)
                         ▼
                    cloudflared (VPS, systemd)
                         │ HTTP
                         ▼
                Express :5001 (dap-operacao.service)
                    ├─ /api/*       → routes (16 arquivos)
                    ├─ /uploads/*   → multer disk storage
                    ├─ /assets/*    → Vite build (dist/public/assets)
                    └─ /*           → SPA fallback (index.html)
                         │
                         ▼
                  SQLite (/opt/dap-operacao/oficina.db)
```

## Layout do repo

```
dap-operacao/
├── client/src/
│   ├── components/        ui/ (shadcn) + os/ (cards de OS) + 2 root
│   ├── pages/             1 página por rota: dashboard, customers, orders,
│   │                       service-order-detail, patio, agenda, financeiro,
│   │                       timeline, users-management, login, not-found,
│   │                       comercial/, portais/
│   ├── hooks/             use-mobile, use-toast
│   └── lib/               auth (context), queryClient, money, utils
├── server/
│   ├── index.ts           bootstrap: helmet, JSON, trust-proxy, error handler
│   ├── routes/            16 modules + index.ts (orchestrator)
│   ├── middleware/        auth.ts (requireAuth/requireRole) + upload.ts (multer)
│   └── storage.ts         drizzle queries (one big file por intenção)
├── shared/schema.ts       Drizzle tables + zod insert schemas + helpers
├── migrations/            drizzle-kit output
├── tests/                 18 vitest files
└── script/build.ts        Vite + esbuild → dist/index.cjs + dist/public/
```

## Decisões técnicas relevantes

### 1. Hash router em vez de history API
- **Por que**: SPA pode ser servida de qualquer path sem precisar configurar fallback no server. Simplifica deploy atrás de proxies que mexem em path.
- **Trade-off**: URLs ficam `/#/timeline` em vez de `/timeline`. Aceitável pra portal interno.

### 2. SQLite + Drizzle em vez de Postgres
- **Por que**: Zero serviço extra pra orquestrar. Backup = `cp oficina.db`. ACID completo. Performance suficiente pra ~10k OS/ano. P1 já usa Postgres/Supabase pra leads — esse portal não precisa.
- **Trade-off**: Sem multi-writer concorrente. OK pra single-process.

### 3. Money como integer cents
- **Por que**: Floats em JS quebram em soma. `toCents("1.234,56") → 123456`. Ler com `formatCentsBRL(123456) → "R$ 1.234,56"`.
- **Helpers em** `shared/schema.ts`.

### 4. Multi-tenant por `organizationId` (não por database)
- **Por que**: Toda query filtra por `organizationId` (`requireAuth` injeta `req.session.organizationId`). Deletar org cascateia tudo (`onDelete: "cascade"`). Permite expandir pra múltiplas oficinas (DAP Performance, Project) sem reestruturar.
- **Default org**: `slug: "dap-prime"`, criada no boot se ausente.

### 5. `app.set("trust proxy", 1)`
- **Por que**: Cloudflare Tunnel termina TLS 1 hop antes. Sem isso, Express vê `req.protocol === "http"` e o cookie `secure: true` é silently dropped → login retorna 200 mas não persiste sessão.
- **Bug histórico**: corrigido em commit `54e99b2`.

### 6. CSP estrito em produção
- `default-src 'self'` — tudo same-origin
- `script-src 'self'` — sem inline JS, sem CDN
- `style-src 'self' 'unsafe-inline' fonts.googleapis.com` — shadcn emite inline `style=` props
- `connect-src 'self'` — sem telemetria third-party
- `frame-ancestors 'none'` — não embedável (defesa contra clickjacking junto de X-Frame-Options)
- CSP **desativado em dev** porque interfere com Vite HMR

### 7. Code-split por vendor
Bundle entry caiu de 508KB → 110KB raw (152KB → 26KB gzip). Cache survive entre deploys quando só app code muda.

```
vendor-react       150KB  react + react-dom + scheduler + wouter
vendor-radix        66KB  @radix-ui/* + cmdk + vaul
vendor-forms        59KB  rhf + @hookform + zod
vendor-tanstack     36KB  @tanstack/react-query
vendor-icons        18KB  lucide-react + react-icons
vendor              75KB  resto
entry              110KB  app code + páginas eager
```

## Segurança

### Headers (helmet defaults + CSP custom)
- `Strict-Transport-Security: max-age=31536000; includeSubDomains` (HSTS 1 ano)
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: SAMEORIGIN`
- `Referrer-Policy: no-referrer`
- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Resource-Policy: same-origin`
- CSP detalhado acima

### Auth flow
1. `POST /api/auth/login` — bcrypt compare, set `req.session.userId` + `organizationId`
2. Cookie `connect.sid` retorna com `HttpOnly; Secure; SameSite=Lax; Max-Age=86400`
3. Toda rota `/api/*` (exceto login/me/logout) passa por `requireAuth`
4. `requireRole("admin")` adiciona check de role pra rotas privilegiadas

### Rate limiting
- `POST /api/auth/login`: **5 tentativas/min/IP** (express-rate-limit), `skipSuccessfulRequests: true` — login certo não consome a quota.

### Upload
- `multer` disk storage em `/opt/dap-operacao/uploads/`
- Limite 15MB por arquivo
- Whitelist MIME: `image/jpeg|png|webp` + `video/mp4|webm`
- Filename randomizado: `${Date.now()}-${random8}${ext}`
- Servido via `/uploads/*` static (mesma origem, dentro do CSP)

### Bootstrap admin (produção)
- Em produção, se não houver users, app **recusa subir** sem `BOOTSTRAP_ADMIN_PASSWORD` env (mínimo 12 chars).
- Demo seed (admin/tecnico/recepcao com senhas óbvias) **só em dev**.
