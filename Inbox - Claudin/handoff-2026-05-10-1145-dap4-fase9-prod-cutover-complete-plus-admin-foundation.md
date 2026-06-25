---
type: handoff
date: 2026-05-10
time: 11:45
project: dap4-portals (monorepo)
topic: Fase 9 100% em prod (4 commits 360cb76→f9d19eb→93884c4, 6 migrations aplicadas: 0004→0005→0006→0003→0007→0008→0009). DOCTOR PRIME 1:1 paridade staging + 1 nova foundation table (oficina.platform_audit_log). Apps/admin Tasks 10.1+10.2 fechadas anteriores; 10.3-10.11 ainda pendentes (8 tasks, decisão arquitetural inline-styles tomada, plano enxuto documentado pra próxima sessão).
tags: [handoff, claudin, dap4, monorepo, drizzle, supabase, fase9, fase10, doctor-prime, apps-admin, schema-expansion]
---

# Handoff — dap4-portals: Fase 9 prod cutover COMPLETO + apps/admin foundation

> **Carry-over** do `handoff-2026-05-10-1010-dap4-fase9-staging-validated-bugs-fixed-prod-pending.md`. Aquele handoff deixou Task 9.7 step 3 pendente (apply em prod do schema expansion). Esta sessão fechou.

## Contexto

Sessão começou com `/resume-handoff` carregando o estado de 10:10 (4 commits pushados em `feat/schema-expansion-fase9`, validação em staging branch validada com $0.013, prod-apply pendente). Thales deu "segue 9.7" → executei pre-flight checks completos antes de tocar prod, **descobri que o caminho (a) do handoff anterior era inviável em prod** (estado pré-existente diferente do staging branch fresh), pivotei pra opção A (incremental com 2 hand-written migrations extra), executei e validei.

Depois Thales escolheu seguir com Tasks 10.3-10.11 do apps/admin. Cumpri Foundation A1 (platform_audit_log) e parei na A2 antes de virar trabalho de exploração — context budget comprometido pelo grande volume de work spent na Fase 9 cutover.

## O que funcionou (com evidência)

### Fase 9 cutover prod (DOCTOR PRIME = `acuufrgoyjwzlyhopaus`)

**3 commits novos pushados em `origin/feat/schema-expansion-fase9`:**

```
93884c4 feat(db): add oficina.platform_audit_log + migration 0009
f9d19eb chore(db): add 0007 + 0008 hand-written migrations to close prod gaps
360cb76 feat(db): add 0005 + 0006 hand-written migrations for prod aios+crm bootstrap
```

**6 migrations aplicadas em prod via Supabase MCP** (ordem de apply, NÃO cronológica):

| Migration | Tipo | Conteúdo | Status |
|-----------|------|----------|--------|
| `drizzle_0004_fix_enums_in_config_and_search_path` | Drizzle managed | 2 enums oficina (service_order_status, pendencia_status) | ✅ |
| `drizzle_0005_create_aios_crm_schemas` | Hand-written (fora journal) | CREATE SCHEMA IF NOT EXISTS aios + crm | ✅ |
| `drizzle_0006_aios_crm_foundation_tables` | Hand-written (fora journal) | 2 enums crm + aios.conversations + crm.{tenants,users,leads} + FKs | ✅ |
| `drizzle_0003_schema_expansion_sprints_1_4` | Drizzle managed | 21 tables + 4 CHECKs + 12 RLS + 58 indexes | ✅ (timeout HTTP mas executou — confirmado via SQL counts) |
| `drizzle_0007_fix_touch_updated_at_search_path` | Hand-written (fora journal) | ALTER FUNCTION search_path | ✅ |
| `drizzle_0008_aios_messages_forward_looking` | Hand-written (fora journal) | aios.messages forward-looking | ✅ |
| `drizzle_0009_add_platform_audit_log` | Drizzle managed | oficina.platform_audit_log + RLS sem policy + 3 indexes | ✅ |

**Estado final em DOCTOR PRIME (1:1 paridade staging + 1 nova table):**
- 45 tables (oficina 23, gestao 8, aios 5, crm 9) · 4 enums · 3 helpers · 32 RLS policies · 7 CHECK constraints · 76 FKs · ~153 indexes · 1 trigger
- **0 advisor warns tocando nossas 4 schemas** (foi 1 antes do 0007, 148 antes do cutover)
- Os 147 advisor lints remanescentes são todos legacy (`public.*` views/funcs + 162 hand-written pré-Drizzle)

### Bugs latentes descobertos e fixados

1. **Schema mismatch entre staging e prod** — caminho (a) do handoff anterior (`0001 → 0002 → 0004 → 0003`) quebraria em prod com `duplicate_object`: 20 policies + 3 CHECK constraints da 0002 já existiam em prod via 162 hand-written pré-Drizzle. Fix: skip 0001/0002 em prod (já noop), aplicar só novidades.

2. **Drizzle snapshots drift latente** — `meta/000{2,3}_snapshot.json` referenciavam `aios.conversations`, `crm.tenants`, `crm.users`, `crm.leads` como existentes mas nenhuma migration `.sql` as criava. Em staging fresh isso passava porque tabelas foram criadas pelas 162 hand-written originais (que rodaram parcial+falharam mas deixaram parte). Em prod, schemas aios/crm sequer existiam. Fix: 0005 + 0006 hand-written paralelas.

3. **`gestao.touch_updated_at` legacy sem search_path** — bug pré-Drizzle. Drizzle 0001 corrige mas 0001 era noop em prod. Fix: 0007 ALTER FUNCTION standalone.

### Foundation A1 (oficina.platform_audit_log)

- Adicionado ao Drizzle TS schema (`packages/db/src/schema/oficina.ts`) com decisão arquitetural documentada inline.
- Migration 0009 gerada via `drizzle-kit generate` (renomeada de 0005 → 0009 pra manter monotonicidade no on-disk numbering vs prod-applied sequence).
- RLS habilitada **SEM pgPolicy** — acesso só via apps/admin/server (service_role bypass) + middleware requirePlatformOwner. Documentado.
- 3 indexes: user_id, action, created_at (cobrem 3 query shapes previsíveis: "what did this staffer do", "who did X recently", "audit feed last N hours").
- userId é uuid (auth.users.id) — cross-tenant by design, NÃO integer FK pra oficina.users.
- 54/54 tests verde, generate canary "No schema changes 😴".

## O que NÃO funcionou

- **Caminho (a) do handoff anterior em prod** — `0001 → 0002 → 0004 → 0003` quebraria em 0002 (duplicate_object) e em 0003 (FKs órfãs aios/crm). Pivotei pra opção A (incremental + 0005/0006 hand-written). Documentado no commit body de 360cb76.
- **`apply_migration` MCP timeout HTTP na 0003** — execução continuou no servidor apesar do timeout retornar erro. Validei via SQL counts pós-fato: tudo executou (43 tables, 32 policies, 7 CHECKs, 150 indexes). Pra próximas migrations grandes (~28KB), considerar split em chunks ou usar `execute_sql` em transação.

## O que ainda não foi tentado

### Apps/admin Tasks 10.3-10.11 (Fase 10) — 8 tasks pendentes, ~10-15h total

**Decisão arquitetural tomada (não implementada ainda):** AdminLayout vai usar **inline-styles dark theme** (não Tailwind/shadcn). Justificativa: apps/admin é portal **interno** (DAP staff = roles `owner|system`), barra de design é "Linear-internal/dense functional", não "cinematic". Cinematic visuals ficam pros portais cliente-facing (operacao/aios). Refatorar pra Tailwind/shadcn depois é trabalho de ~1h sem risco.

**Plano enxuto pra retomar próxima sessão:**

#### Foundation (A2)
- A2: 10.8 AdminLayout
  - Add 3 deps em `apps/admin/package.json`: `wouter` `@tanstack/react-query` `lucide-react` (pnpm install)
  - Criar `apps/admin/client/src/lib/queryClient.ts` (cópia simplificada de operacao)
  - Criar `apps/admin/client/src/lib/auth.tsx` (consume @dap/auth, AuthProvider + useAuth hook)
  - Criar `apps/admin/client/src/components/AdminLayout.tsx` (sidebar + main + topbar)
  - Sidebar com 5 links: SQL Console, Tables Browser, Staff, RBAC, Routes
  - **EmpresaSwitcher cross-tenant** = TODO comment (precisa backend pra listar orgs cross-tenant)
  - **Impersonation footer** = TODO comment (precisa flow grande)
  - Update `App.tsx` pra usar Router + AuthProvider + 5 stubs de page

#### Pages simples (B)
- B1: 10.9 Login + reset-password — copy verbatim `apps/operacao/client/src/pages/login.tsx` + check role pós-login (`owner|system` only, else redirect + toast)
- B2: 10.7 Route-map — `apps/admin/client/src/lib/routes-manifest.ts` (manifest estático de TODAS as rotas dos 4 apps), UI search/filter por persona/portal. Auto-gen script defer.

#### Pages com backend (C)
- C1: 10.4 Tables-browser — 4 endpoints (list, columns, rows paginado, count timeout 5s) + UI tree + 3 tests. Mais simples, valida pattern RPC+UI.
- C2: 10.6 RBAC matrix — UI roles × permissions read-only sourced from `@dap/aios-schema/rbac.ts`. GET /api/admin/rbac.
- C3: 10.5 Staff management — 5 endpoints (list, invite token assinado 24h single-use, patch role, patch active, force-password-reset), UI tabela + modal invite, 3 tests. **bcrypt obrigatório, NUNCA senha-padrão `123456`.**
- C4: 10.3 SQL console — **CRITICAL SECURITY**. RPC `admin_execute_query` SECURITY DEFINER + whitelist (SELECT/INSERT/UPDATE/DELETE/EXPLAIN/ANALYZE — NUNCA DROP/TRUNCATE/CREATE/ALTER/GRANT/REVOKE) + audit log obrigatório (insert em platform_audit_log) + 30s timeout + role guard validado pelo RPC (não só pelo client). UI: tables sidebar + editor + Run/EXPLAIN + history (no full results write). DestructiveConfirm modal pra DELETE/UPDATE/INSERT regex match. Quick-queries presets. 6 tests. **SUBSTITUI `DevSQL.tsx` do DoctorAuto sem `exec_sql` backdoor.**

#### Polish (D)
- D1: 10.10 E2E Playwright + smoke (login owner → SQL console → SELECT → result; login admin oficina → 403 em /api/admin/*) + README com seção "Acesso restrito"
- D2: 10.11 Edit `dap4-portals/README.md` adicionando apps/admin + ADR-002 em `gestao.adrs` ("apps/admin como 5º app, sem service_role no client, restrito a owner|system")

### Carry-overs antigos (não atacados nesta sessão)

- **🚨 SECURITY** rotacionar `C:\THALES\autodiag-copilot\.env.local` (parado 25+ dias)
- **🚨 SECURITY** reset 2 senhas DOCTOR PRIME expostas em chat
- Postgres test DB local (bloqueia 18 test files de operacao)
- Task 9.1 step 6 (ALTER service_orders.status text→enum + backfill)
- `@dap/ui` exports cleanup em apps/aios

## Arquivos tocados (3 commits)

| Arquivo | Status | Notas |
|---------|--------|-------|
| `packages/db/migrations/0005_create_aios_crm_schemas.sql` | Novo (hand-written) | CREATE SCHEMA aios + crm idempotente |
| `packages/db/migrations/0006_aios_crm_foundation_tables.sql` | Novo (hand-written) | 2 enums crm + 4 tables + FKs |
| `packages/db/migrations/0007_fix_touch_updated_at_search_path_in_prod.sql` | Novo (hand-written) | ALTER FUNCTION search_path |
| `packages/db/migrations/0008_aios_messages_forward_looking.sql` | Novo (hand-written) | aios.messages + FK |
| `packages/db/migrations/0009_add_platform_audit_log.sql` | Novo (Drizzle generated, manual ENABLE RLS appended) | Renomeado de 0005 → 0009 |
| `packages/db/migrations/meta/0009_snapshot.json` | Novo | Auto-gerado, renomeado |
| `packages/db/migrations/meta/_journal.json` | Modificado | tag corrigida pra 0009_add_platform_audit_log |
| `packages/db/src/schema/oficina.ts` | Modificado | +platformAuditLog table + jsonb/timestamp imports |

## Decisões tomadas

- **Pre-flight checks ANTES de aplicar migrations validadas em staging.** Lição grande: staging fresh ≠ prod com estado pré-existente. Comparar policies/checks/funções por nome via SQL.
- **Caminho (a) descartado, opção A (incremental) escolhida** — gerar 0005 + 0006 hand-written (CREATE SCHEMA + foundation tables faltantes), skip 0001 (noop em prod) + 0002 (já tem em prod), aplicar só novidades.
- **Hand-written migrations ficam FORA do `_journal.json` Drizzle** (mesmo padrão das 162 hand-written pré-Drizzle). Snapshots Drizzle já refletem estado pós-apply correto, mexer no journal é mais invasivo. Rodando `db:generate` continua "No schema changes 😴".
- **Renomear 0005→0009 quando Drizzle gerou** com mesmo número que hand-written. Atualizei só o `tag` no journal entry, mantendo idx 5 (Drizzle não usa idx pra ordering, só pra tracking).
- **`platform_audit_log` em `oficina` schema** (não `gestao` ou novo `crm.platform_audit_log`). Razão: oficina já tem RLS helper pattern estabelecido + comentário inline indica que mover pra crm em refactor futuro fica documentado.
- **`platform_audit_log.userId` é uuid** (auth.users.id), NÃO integer FK pra oficina.users. Cross-tenant by design.
- **RLS habilitada SEM pgPolicy em platform_audit_log** — acesso só via apps/admin/server (service_role bypass) + middleware requirePlatformOwner. Advisor `rls_enabled_no_policy` warn nessa tabela é EXPECTED, documentado.
- **AdminLayout = inline-styles** — apps/admin é portal interno DAP staff, dense+functional > cinematic.
- **Pausar antes de A2** — context budget comprometido pelo trabalho da Fase 9. Próxima sessão começa com plano enxuto documentado.

## Bloqueios & perguntas abertas

- **Apps/admin Tasks 10.3-10.11** — 8 tasks pendentes, plano enxuto pronto, próxima sessão executa.
- **Apps/admin não tem Tailwind nem deps básicas** (wouter, react-query, lucide). Add no início da próxima sessão.
- **EmpresaSwitcher cross-tenant** — design não detalhado no plano-mãe. Header `X-Inspect-Org` no backend. UI seleciona qual org está inspecionando (read context only). Decisão durante implementação.
- **Impersonation flow** — "Acessar como" footer com audit log obrigatório. Big design decision (gera token assinado? redirect cross-app?). Decisão durante implementação.
- **Tabela `platform_audit_log` está em `oficina`** — long-term deve mover pra `crm` (cross-portal natural home). Refactor diferido, não bloqueia.

## Próximo passo exato

**Recomendação primária: A2 → B1 → B2 (foundation + 2 simples)** numa próxima sessão fresca.

Sequência prática (estimativa: 2-3h pra A2+B1+B2):

1. `cd C:/THALES/DAP4/dap4-portals/apps/admin`
2. Edit `package.json` add 3 deps: `wouter` `@tanstack/react-query` `lucide-react`
3. `pnpm install` (root)
4. `pnpm --filter @dap/admin check` — confirmar typecheck verde
5. Criar `client/src/lib/queryClient.ts` (cópia simplificada de operacao — só QueryClient)
6. Criar `client/src/lib/auth.tsx` — consume `@dap/auth`, exposing AuthProvider + useAuth() (cópia adaptada de operacao)
7. Criar `client/src/components/AdminLayout.tsx` — sidebar (5 links hard-coded) + main + topbar com nome/email do user
8. Criar 5 page stubs em `client/src/pages/`: sql-console.tsx, tables-browser.tsx, staff-management.tsx, rbac-matrix.tsx, route-map.tsx (cada uma com h1 + "TODO Sprint 6 page X")
9. Criar `client/src/pages/login.tsx` (cópia operacao verbatim, ADR-001) + `reset-password.tsx`
10. Update `App.tsx` — Router (wouter) + AuthProvider + Switch com 7 routes (5 pages + login + reset)
11. Pós-login: check role → if !owner|system, redirect ao login + toast "Sem permissão"
12. `pnpm --filter @dap/admin check` + `test` — validar
13. Commit + push

**Recomendações alternativas:**
- Pular pra C4 SQL console direto (a mais valiosa, substitui DevSQL.tsx do DoctorAuto). Mas precisa A2 antes pra ter shell.
- Atacar carry-overs SECURITY primeiro (rotacionar .env.local + reset 2 senhas) — quick win operacional.

## Setup / comandos úteis

```bash
# Entrar
cd C:/THALES/DAP4/dap4-portals

# State da branch
git branch --show-current  # feat/schema-expansion-fase9
git log --oneline -5       # 93884c4 → f9d19eb → 360cb76 → 5300c66 → 4c298a2
git status                 # clean
git --no-pager diff main..HEAD --stat  # vê delta de toda a fase 9

# Build / tests
pnpm --filter @dap/db check              # exit 0
pnpm --filter @dap/db test               # 54/54 verde
pnpm --filter @dap/db db:generate        # "No schema changes 😴" (canary)
pnpm --filter @dap/admin check           # exit 0 (skeleton ainda)
pnpm --filter @dap/admin test            # 12/12 verde (gate tests)

# Migrations atuais
ls packages/db/migrations/ | grep -v meta
# 0000_equal_doctor_spectrum.sql                4 schemas + 22 tables + FKs + indexes
# 0001_helper_functions.sql                      3 functions + 1 trigger (touch_updated_at FIXADO)
# 0002_rls_policies_and_checks.sql               18 ENABLE RLS + 3 CHECK + 20 CREATE POLICY
# 0003_schema_expansion_sprints_1_4.sql          21 tables + 4 CHECK + 12 RLS + 58 indexes
# 0004_fix_enums_in_config_and_search_path.sql   2 CREATE TYPE oficina enums
# 0005_create_aios_crm_schemas.sql               2 CREATE SCHEMA (hand-written)
# 0006_aios_crm_foundation_tables.sql            2 enums crm + 4 tables (hand-written)
# 0007_fix_touch_updated_at_search_path_in_prod.sql  1 ALTER FUNCTION (hand-written)
# 0008_aios_messages_forward_looking.sql         1 CREATE TABLE + FK (hand-written)
# 0009_add_platform_audit_log.sql                1 CREATE TABLE + 3 indexes + ENABLE RLS

# DOCTOR PRIME via Supabase MCP
# Project ID: acuufrgoyjwzlyhopaus
# Org ID: aldpajllerexnbfqrrgb

# Validação consolidada (já rodada, retorna 45 tables/32 policies/7 checks/etc):
# Ver memory project_doctor_prime_drift_2026_05_08.md pra detalhes
```

**Repo:** `https://github.com/toliveira1802-sketch/dap4-portals` — branch `feat/schema-expansion-fase9` em `93884c4` (sync com origin). Main em `edc927c` (não tocado nesta sessão).

**Plans fonte:**
- `C:\THALES\DAP4\docs\superpowers\plans\2026-05-06-dap4-monorepo-migration.md` (master)
- `C:\THALES\DAP4\docs\superpowers\plans\2026-05-09-dap4-schema-expansion-plus-admin.md` (em execução, 18 tasks)
- Status do plano 2026-05-09:
  - ✅ Tasks 9.1, 9.2, 9.3, 9.4, 9.5 (schemas)
  - ✅ Task 9.7 (3 steps fechados nesta sessão: generate ✓, validate staging ✓, **apply prod ✓**)
  - ❌ Task 9.6 (schema rename docs) — sem evidência clara, low priority
  - ⏸ Task 9.7 step 4 (view splice manual `v_kpis_oficina_mes_atual`) — TS string em packages/db/src/views/
  - ✅ Tasks 10.1, 10.2 (apps/admin skeleton + gate)
  - ❌ Tasks 10.3-10.11 (sql-console, tables-browser, staff, rbac, route-map, AdminLayout, login, E2E, docs) — **plano enxuto documentado pra próxima sessão**

**Memory atualizada:**
- `project_doctor_prime_drift_2026_05_08.md` — refletindo cutover 2026-05-10, todos gaps fechados, tech debt zero em nossas 4 schemas

**Custo Supabase nesta sessão:** $0 (apenas MCP queries em prod e branch já existente do handoff anterior).
