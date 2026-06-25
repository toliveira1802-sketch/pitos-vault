---
type: roadmap
date: 2026-06-19
project: DAP 4.0 — dap-aios (portal Consultor)
topic: Roadmap de arquitetura → VPS pra operar o Consultor em produção
tags: [roadmap, adr, dap-aios, consultor, producao, deploy, claudin]
status: aprovado (decisões travadas) — execução pendente
---

# ROADMAP — Portal Consultor em Produção

> **Objetivo único.** Levar o portal **Consultor** a rodar em **produção na VPS**, com
> a equipe da oficina operando **dado real** (OS, quotes, clientes, agenda). Cadência
> **staging-first rígida**: nada vai a prod sem passar por staging validado pelo Thales.
> Anna e RAG **ficam fora** deste milestone (entram depois).

---

## Decisões travadas (ADR — Fase 0)

| # | Decisão | Razão |
|---|---------|-------|
| **D1** | **`hlhf` (Supabase atual) vira PROD.** Cria-se um **Supabase novo só pra STAGING** com dado sintético. | O `hlhf` já contém o negócio real (418 clientes, 546 veículos, 659 OS, 1616 eventos). Promover é zero-migração e zero-risco de perder dado; criar prod novo exigiria migrar tudo. Staging novo para de mutar o dado real (hoje `db:push` de staging bate no `hlhf`). |
| **D2** | **Criação de quote (proposta) ENTRA no escopo.** | Hoje o consultor só *converte* quote em OS; não há UI pra criar proposta. Sem isso o ciclo cliente→proposta→OS não fecha dentro do portal. |
| **D3** | **As 6 telas vazias ficam ESCONDIDAS do nav em prod** (feature-flag): Leads-editável, Aprovações, Conversas, e os 4 sub-dashboards (Operacional/Financeiro/Produtividade/Agenda-do-Dia). | Fora do escopo mínimo. Esconder > exibir `<EmBreve>`. Cada uma vira milestone próprio depois. |
| **D4** | **Imagem buildada uma vez e PROMOVIDA** staging→prod; **migrations versionadas** no deploy (fim do `db:push` direto no banco). | Paridade staging/prod garantida; deploy auditável e reversível. |
| **D5** | **Staging-first rígido.** Toda fatia valida em staging + ok do Thales antes de prod. | Padrão world-class; a VPS já tem o padrão (container `aios-staging` + Grafana). |

---

## Estado atual — o delta (Fase 1, read-only)

**Sólido e REAL (não mexer):** Clientes, Veículos, **OS completa**, Pátio, **Agenda**, KPIs,
Pendências, Inbox ao vivo. Auth real bem construída (Supabase Auth, choke point cobrindo
todas as rotas `/api`, `requirePermission` por endpoint, fail-closed). Código prod-ready
(mesma imagem serve todos os portais; roteamento client-side). CI robusto (typecheck, lint,
test+cov, build, smoke E2E).

**O que trava operar em prod:**

| Frente | Gap | Evidência |
|--------|-----|-----------|
| Auth (P0) | Client sobe em "modo dev sem login" se faltar `VITE_SUPABASE_*` no build — sem guard de boot | `client/src/auth/LoginPage.tsx:21-43` |
| Auth (P0) | Role-override religa em prod via `AIOS_ROLE_OVERRIDE=1` | `server/src/middleware/requireAuth.ts:52` |
| Dados (P0) | Não existe Supabase de prod; staging escreve no `hlhf` (dado real) via `db:push` | `.env.production:4`, `docs/RUNBOOK-DEPLOY.md:88` |
| Infra (P1) | Não existe `docker-compose.prod.yml`, tag `dap-aios:prod`, nem ingress CF de prod | infra inventory |
| RLS (P1) | Tabelas-núcleo: RLS *enabled sem policy* — funciona só pelo bypass do superuser, não versionado em migration | `server/migrations/0004_pale_paper_doll.sql:19-39` |
| Funcional (P1) | Sem UI pra criar quote (só converter) | `client/.../QuotesPage.tsx` |
| Funcional (P2) | Checklist "Tarefas do Dia" não persiste; meta comercial hardcoded (150000); código morto (`lib/pendenciasMock.ts`) | `MeuDapPage.tsx:31,56` |

---

## Roadmap — milestones com gate

> Caminho crítico: **M0 → M1 → M2 → (M3 ∥ M4) → M5 → M6 → M7**.

### M0 — Travar arquitetura ✅ (este documento)
Decisões D1–D5. **Gate:** aprovado.

### M1 — Hardening de auth P0
- Boot-guard no client: **falhar o build/boot** se `VITE_SUPABASE_*` ausente (mata o modo stub).
- **Hard-block** do role-override quando `NODE_ENV==='production'` (ignora `AIOS_ROLE_OVERRIDE`).
- Provisionar + documentar `SUPABASE_JWT_SECRET` (validação local de assinatura).
- Higiene: garantir `SUPABASE_SERVICE_ROLE_KEY` server-side only (nunca no bundle).
- **Ferramentas:** tdd-workflow + `security-reviewer`. **Gate:** TDD verde + review sem CRITICAL.

### M2 — Staging isolado (para de mutar dado real)
- Provisionar **Supabase STAGING novo**; rodar migrations do zero; seed sintético.
- `.env` de staging apontando pro banco novo; repontar o container `aios-staging`.
- **Gate:** staging 100% desacoplado do `hlhf`; nenhum `db:push` toca prod.

### M3 — Gaps funcionais do escopo (∥ M4)
- **Criar quote no portal** (UI + endpoint: itens, margem, vínculo cliente/veículo, emite evento).
- **Esconder os 6 stubs** do nav em prod (feature-flag de portal).
- **Persistir** o checklist "Tarefas do Dia" (endpoint + tabela) — ou cortar do MVP.
- **Meta comercial** vinda do backend (fim do `150000` hardcoded).
- Limpar código morto / comentários enganosos (`pendenciasMock`, stale em `ConsultorDashboardPage.tsx:7`).
- **Ferramentas:** tdd-workflow + `code-reviewer`. **Gate:** ciclo OS↔quote↔cliente↔agenda completo, zero tela vazia exposta.

### M4 — RLS do núcleo versionado (∥ M3)
- Migration versionada que garante RLS `enabled` + `REVOKE` `anon`/`authenticated` no núcleo do
  consultor, e **decide**: policies de escrita role-aware OU modelo documentado "RLS = rede de
  segurança + autz na app". Fim do estado enabled-sem-policy dependente de aplicação manual.
- **Ferramentas:** `database-reviewer` + `security-reviewer`. **Gate:** estado RLS idêntico e
  versionado em dev/staging/prod.

### M5 — Infra de produção
- `docker-compose.prod.yml` (`aios-prod`, porta loopback nova, `env_file` de prod).
- Tag `dap-aios:prod` — **promover** a imagem validada em staging (não rebuildar).
- `.env.production` do build de prod apontando pro **`hlhf`** (Supabase prod) + `.env` de prod
  na VPS (`ANNA_WEBHOOK_SECRET`, `NODE_ENV=production`, flags do escopo Consultor).
- **Migrations versionadas no deploy** (substituir `db:push`) + snapshot obrigatório antes.
- **Gate:** build de prod fala com o banco certo; deploy reversível.

### M6 — Roteamento + observabilidade
- Ingress Cloudflare Tunnel pro hostname de prod (`consultor.*` = prod, `staging.consultor.*` =
  staging) — **precisa token CF de escrita** (foi revogado no hardening; reprovisionar).
- Confirmar caminho real do tráfego (Caddy vs direto-5001) por SSH; atualizar runbook (drift).
- Instrumentar `/metrics` (Prometheus) + dashboards/alertas do Consultor (container down, 5xx,
  latência) no Grafana de `/opt/monitoring`.
- **Gate:** prod acessível no domínio + observável.

### M7 — Usuários, validação e cutover
- Provisionar usuários reais da equipe (consultor/gestor/admin) via script; **runbook** de
  criação/desativação documentado.
- **Validação completa em staging** (walkthrough do Thales na mão).
- **Cutover prod:** deploy, smoke (4 subdomínios + login + escrita), event-log conferido,
  rollback pronto.
- **Gate:** equipe opera o Consultor em prod sem erro. 🎯

---

## Princípios de processo

- **Fatia fina ponta-a-ponta** — cada milestone entrega algo operável, não meia-camada.
- **Gate antes de cada subida** — nada a staging sem verde; nada a prod sem staging validado.
- **Branch isolada + commits atômicos**; push a `main`/prod **só com ok do Thales**.
- **Handoff ao fim de cada fatia** em `Status/` (retomável).
- **Qualidade mínima por fatia:** `pnpm check · build · test · lint · test:e2e:smoke`.

## Riscos abertos

- Promover `hlhf` a prod com staging ainda apontando pra ele **até M2 concluir** — durante a
  janela, evitar `db:push` de dev/staging contra o `hlhf`.
- Token CF de escrita revogado — M6 depende de reprovisionar.
- Drift doc↔VPS (composes, Caddy) — confirmar por SSH antes de replicar pra prod.

## Próximo passo

Começar **M1 (hardening de auth P0)** — é código puro, alto valor de segurança, não depende de
infra. Em paralelo, decidir janela pra provisionar o Supabase de staging (M2, ação externa que
precisa de ok do Thales).
