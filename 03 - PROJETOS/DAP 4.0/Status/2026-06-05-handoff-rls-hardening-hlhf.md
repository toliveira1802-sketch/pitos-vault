---
type: handoff
date: 2026-06-05
time: "02:01"
project: dap-aios + dap4 (banco hlhf)
topic: RLS hardening do Supabase hlhf — fechado buraco crítico vivo (anon/authenticated com CRUD total + RLS off nas 32 tabelas)
tags: [handoff, claudin, dap-aios, dap4, supabase, rls, seguranca, hlhf, hotfix]
---

# Handoff — RLS hardening do `hlhf` (fechado buraco crítico de exposição de dados)

> Rodada de **segurança P0**. Saiu do `/resume-handoff` (frente Anna/Meta fechada) → atacamos o
> item de segurança aberto. O que era listado como "P1 antes de volume" se revelou **buraco
> crítico VIVO**: a `anon key` (pública, embutida no bundle JS) tinha CRUD total em todas as
> tabelas. Fechado e verificado em produção nesta sessão.

## Resumo executivo

O Supabase **`hlhfqnhsvwxodtwdkkhf`** (banco dos portais, compartilhado dap-aios + Anna/dap4) estava com:
- **RLS desabilitado nas 32 tabelas** (0 com `rls_enabled`).
- **`anon` E `authenticated` com `SELECT/INSERT/UPDATE/DELETE/TRUNCATE`** em todas as 32 tabelas + 2 views.
- Resultado: qualquer um com a `anon key` (vive no JS público do frontend) podia **ler e apagar**
  `customers`, `vehicles`, `leads`, `users`, `roles`, `permissions`, financeiro (`invoices`/`bills`/`dre_*`)
  e `messages`, direto via PostgREST. Exfiltração + destruição com chave pública.

**Fix aplicado via MCP (Thales escolheu "tudo cru via MCP agora, Drizzle re-sincroniza depois").**
Buraco fechado, backends intactos, verificado.

## O que foi implementado (com evidência)

### Migration `rls_hardening_01_revoke_and_enable`
- `REVOKE ALL ON ALL TABLES/SEQUENCES IN SCHEMA public FROM anon, authenticated` — mata o vetor na raiz.
- `ENABLE ROW LEVEL SECURITY` nas 32 tabelas (loop sobre `pg_class relkind='r'`) → **default-deny** (sem policy permissiva = nega).

### Migration `rls_hardening_02_cleanup_policies_views`
- Drop das 10 policies `_select_authenticated` (eram `USING (true)` = leitura financeira aberta a qualquer logado).
- Mantidas as 10 `_write_audit_admin` (role-aware, restritas a `audit_admin` — intenção documentada).
- 2 views `SECURITY DEFINER` (`vw_margem_os`, `vw_ranking_suppliers`) → `security_invoker = on`.
- Function `set_updated_at()` → `search_path = ''` (anti-hijack).

### Verificação (produção, pós-apply)
- `pg_class`: **32/32 tabelas com `rls_enabled=true`**; **0 grants** restantes pra anon/authenticated.
- Smoke por role: `anon` → `permission denied for table customers`; `authenticated` → `permission denied for table invoices`.
- Caminho privilegiado (postgres/MCP, `rolbypassrls`): lê normal (`customers=2`, `users=6`).
- Advisor de segurança Supabase: **todos os ERRORs zerados** (antes ~44 ERRORs entre rls_disabled, policy_exists_rls_disabled, security_definer_view; + 1 WARN function search_path). Sobraram 24 INFO `rls_enabled_no_policy` = **estado desejado** (default-deny) + 1 WARN auth (toggle de painel).

## Por que foi seguro (fato que sustenta tudo)

`pg_roles` confirma: `postgres` (pooler do dap-aios) e `service_role` (Anna no dap4) têm **`rolbypassrls = true`**.
Os dois backends ignoram RLS por completo → ativar RLS + revogar anon/authenticated **não tocou em nenhum app**.
A arquitetura já manda frontend→backend (nunca frontend→Supabase direto), então anon/authenticated não deviam ter acesso mesmo.

## ⚠️ Risco crítico aberto — o hardening É FRÁGIL hoje

O handoff R13 (`dap-aios/handoff-aios-r13-postgres-migration.md`, commit `d765088`) mostra que **RLS já
tinha sido religado** nas 19 tabelas originais — e **EVAPOROU**. Causa-raiz confirmada: **o schema Drizzle
do dap-aios NÃO modela RLS** (zero `pgPolicy`/`.enableRLS()` em `packages/types/src/schema/*.ts`). Quando
as 13 tabelas de financeiro/marketing entraram e/ou rodou `db:push`, o RLS se perdeu no drift.

**Sem modelar RLS no Drizzle, o fix desta sessão VAI reverter de novo.** Esse é o próximo passo obrigatório.

## Modelagem Drizzle — CONCLUÍDA nesta sessão ✅

A causa-raiz (schema Drizzle não modelava RLS → drift do R13) foi fechada:
1. ✅ `.enableRLS()` adicionado nas **21 tabelas geridas pelo Drizzle** (`packages/types/src/schema/*.ts`: core, consultor, agents, calculators, events, marketing, rag, service-orders, service-order-items).
2. ✅ `pnpm --filter @aios/server db:generate` → **`migrations/0004_pale_paper_doll.sql`** = 21× `ENABLE ROW LEVEL SECURITY` (inspecionado: nada de DROP policy, nada toca financeiro/roles; idempotente — as 21 já têm RLS vivo da leva 1).
3. ✅ Gate local: `pnpm check` verde (types+server+client) · **350/350 testes verde**.

### PR #50 MERGEADO em main ✅ (squash `3d51d31`)

- 9 checks obrigatórios verdes; merge via `--admin` (o "E2E Playwright" full sempre falha por `DATABASE_URL` ausente no job — não-required, mesmo estado do #49).
- **Review P1 do Codex incorporado:** RLS **não cobre TRUNCATE** (row security só vale pra SELECT/INSERT/UPDATE/DELETE). A 0004 agora **versiona o `REVOKE ALL`** de anon/authenticated (tables+sequences) num DO-block guardado por existência da role — idempotente, à prova de ambiente. Sem isso, um ambiente novo subiria RLS com o grant de TRUNCATE ainda aberto.

### Deploy CONCLUÍDO ✅ (staging, 2026-06-05 ~06:25 UTC)

VPS `76.13.170.42`: source `git reset --hard origin/main` → `3d51d31`; backup `dap-aios:staging-bak-2026-06-05-rls`; `docker build`; `docker compose -f docker-compose.staging.yml -p doctor-auto-ai up -d --force-recreate aios-staging`. Container **healthy**. Smoke verde: health 200 + **consultor/mecanico/gestao/aios todos 200**. Pós-deploy: RLS confirmado vivo (32/32, 0 grants anon/auth).

⚠️ **Gotcha (RUNBOOK impreciso):** o serviço NÃO está em `/opt/doctor-auto-ai/docker-compose.yml` (esse é o stack do dap4). O `aios-staging` vive em **`/opt/dap-aios/src/docker-compose.staging.yml`** com project `doctor-auto-ai`. Comando certo de recreate: `cd /opt/dap-aios/src && docker compose -f docker-compose.staging.yml -p doctor-auto-ai up -d --force-recreate aios-staging`.

**`db:push` PULADO de propósito:** estado RLS+REVOKE já vivo no `hlhf` (via MCP), `db:push` não roda no host (sem node_modules), migration idempotente. Consequência: a 0004 ainda não está registrada no `__drizzle_migrations` do `hlhf` — quando um `db:migrate`/`push` rodar de um ambiente com devDeps, aplica no-op e registra. Sem impacto de segurança.

### Pendências (não-bloqueantes)

- Toggle "leaked password protection" no painel Supabase Auth (WARN).
- Validar Realtime client-side nos portais (não deve haver; dap4 usa socket.io).
- Trazer as 10 tabelas de financeiro pro schema Drizzle (frente própria).
- Corrigir o caminho do compose no `docs/RUNBOOK-DEPLOY.md`.

### Pendência separada (fora do Drizzle)

As **10 tabelas de financeiro** (`bills`, `invoices`, `invoice_items`, `dre_accounts`, `dre_entries`, `labor_entries`, `purchase_orders`, `purchase_order_items`, `suppliers`, `delivery_costs`) **não estão no schema Drizzle** — foram criadas fora dele pela frente gestão/financeiro. O RLS delas foi religado via MCP (leva 1), mas **o Drizzle não as gere** → trazê-las pro schema (`.enableRLS()` + colunas) é frente própria, pra elas não ficarem órfãs num futuro `db:push`. Policies fine-grained (authenticated) só quando algum portal precisar — hoje default-deny basta (backend bypassa).

## Pendências menores (não-DDL)

- **Leaked password protection** (Supabase Auth) desligado → toggle no painel (HaveIBeenPwned). WARN do advisor.
- **Validar Supabase Realtime client-side:** se algum portal abrir canal Realtime com anon/authenticated, quebra (REVOKE). Arquitetura diz que não usa (dap4 usa socket.io), mas confirmar pós-deploy dos portais.

## Rollback (se algo quebrar)

- `GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;`
- `ALTER TABLE ... DISABLE ROW LEVEL SECURITY;`
- Recriar as 10 `_select_authenticated` (defs salvas no histórico desta sessão).

## Arquivos/objetos tocados

| Objeto | Mudança |
|--------|---------|
| `hlhf` (produção) | 2 migrations: revoke+enable RLS, cleanup policies/views/function |
| `dap-aios/CLAUDE.md` | corrigida afirmação falsa "RLS nas 19 tabelas" → 32 default-deny + aviso de drift Drizzle |
| memória `dap-deploy-infra-gotchas` | atualizada (RLS off → religado, frágil sem Drizzle modeling) |

## Como conferir

- Advisor: MCP Supabase `get_advisors(hlhf, security)` → 0 ERROR.
- Estado: `select relname, relrowsecurity from pg_class ... where relkind='r'` → todos true.
- Grants: `role_table_grants where grantee in ('anon','authenticated')` → vazio.

## Próxima rodada sugerida

Modelar `.enableRLS()` no Drizzle do dap-aios (frente de código, PR no repo dap-aios) — fecha a causa-raiz do drift e torna o hardening permanente. Paraleliza bem: 9 arquivos de schema, mecânico.
