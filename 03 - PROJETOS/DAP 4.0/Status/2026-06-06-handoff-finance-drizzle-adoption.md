---
type: handoff
date: 2026-06-06
time: "05:20"
project: dap-aios (banco hlhf)
topic: Adoção das 10 tabelas de financeiro no schema Drizzle (fecha drift de db:push na metade que faltava)
tags: [handoff, claudin, dap-aios, drizzle, supabase, rls, financeiro, hlhf, schema]
---

# Handoff — Financeiro adotado no Drizzle (PR #55 mergeado)

> Continuação direta da rodada de RLS hardening (`2026-06-05-handoff-rls-hardening-hlhf.md`).
> Aquela fechou as 21 tabelas-núcleo no Drizzle (PR #50); esta fecha **a metade que faltava**:
> as 10 tabelas de financeiro que eram órfãs do Drizzle.

## Resumo executivo

As 10 tabelas de financeiro do Portal Gestão (`suppliers`, `purchase_orders`,
`purchase_order_items`, `invoices`, `invoice_items`, `bills`, `dre_accounts`,
`dre_entries`, `labor_entries`, `delivery_costs`) existiam no `hlhf` criadas
**fora do Drizzle** (frente gestão/financeiro) → eram **órfãs**. Como o schema
Drizzle não as conhecia, um `db:push --force` futuro **dropava as tabelas + o RLS**
delas — exatamente o mecanismo que matou o hardening do R13. Agora estão modeladas
em `packages/types/src/schema/finance.ts` com `.enableRLS()`, fechando a causa-raiz
do drift nas duas metades (21 core + 10 financeiro).

**PR #55 mergeado na `main` via `--admin --squash` (commit `00f5f43`).**

## O que foi implementado (com evidência)

### `schema/finance.ts` (novo)
- 10 tabelas modeladas **1:1 com o banco** (introspect via MCP coluna-a-coluna): colunas,
  tipos, nullability, FKs com `onDelete` correto (restrict/set null/cascade), unique em
  `dre_accounts.code`, self-ref em `dre_accounts.parent_id`.
- **Defaults modelados FIEL ao banco** (`.defaultNow()`, `.default('pendente')`, `.default(0)`,
  etc. — NÃO `$defaultFn`), senão o generate emitiria `ALTER ... DROP DEFAULT` e a migration
  não seria no-op. Esse foi o pulo do gato pra fidelidade.
- `.enableRLS()` em todas + relations + zod select schemas.
- Plugado no barrel `packages/types/src/index.ts`.

### Migration `0007_calm_stone_men.sql`
- **Idempotente** via DO block guardado por `to_regclass('public.suppliers') IS NULL`:
  no-op total no `hlhf` (as 10 já existem → bloco pulado), provisão completa em ambiente novo.
- **Guard aninhado** (fix do review do Codex, commit `c1f704a`): os 10 `CREATE POLICY ...
  TO authenticated USING (auth.uid())` ficam dentro de `IF EXISTS (pg_roles authenticated)`.
  Em Postgres vanilla (CI) a role/função do Supabase não existem → pula as policies (tabelas
  + RLS default-deny já isolam); em Supabase cria tudo.
- Policies seguem o padrão da casa (`*_write_audit_admin`, role-aware audit_admin) — vivem na
  migration SQL, não no schema TS (convenção: nenhuma migration drizzle modela policy).

## Bug pego pelo Codex (e por que escapou local) — IMPORTANTE

A `0007` original criava as policies **sem guard de ambiente**. Em Postgres vanilla (jobs CI
`Test + coverage`/`Smoke E2E` rodam `db:setup` contra `postgres:16-alpine`), `authenticated`
e `auth.uid()` não existem → o `CREATE POLICY` falhava. O job só "passava" porque o
`migrate.ts` tem um **fallback leniente** que mascarava o erro (deixava as tabelas de
financeiro sem criar no test DB — passou só porque nenhum teste toca elas ainda).

**Por que escapou da validação local:** só validei o caminho no-op no `hlhf` (tabelas já
existem → guard externo pula tudo). O caminho fresh-env (PG vanilla) só é exercido no CI.
Lição: validar os DOIS caminhos da migration idempotente, não só o no-op.

Fix em `c1f704a`. Confirmado no log do CI pós-fix: `[migrate] ok via Drizzle migrate`
(passou de primeira, sem fallback, sem `Failed query: CREATE POLICY`).

## Verificações (evidência)

- ✅ `0007` aplicada no `hlhf` (2026-06-06) — **no-op verificado**: estado pós-apply idêntico
  ao baseline (10 tabelas, `rls=true`, 1 policy cada, FKs intactos, zero grant anon/authenticated).
- ✅ `pnpm check` (types + server + client) exit 0.
- ✅ Lint: `finance.ts` zero warnings.
- ✅ CI: 9 checks required verdes (Typecheck, Lint, Test+coverage, Test client, Build, Install,
  gitleaks, Dependency audit, Smoke E2E). Fresh-env provado no CI (vanilla PG).
- ⚠️ `E2E Playwright` (full) falha por `DATABASE_URL` ausente — **não-required**, pré-existente
  (mesmo estado #49/#50). Não bloqueia.

## Arquivos tocados

| Arquivo | Mudança |
|---------|---------|
| `packages/types/src/schema/finance.ts` | novo — 10 tabelas + RLS + relations + zod |
| `packages/types/src/index.ts` | export do finance |
| `server/migrations/0007_calm_stone_men.sql` | nova migration idempotente + guard de policies |
| `server/migrations/meta/{_journal.json,0007_snapshot.json}` | snapshot drizzle |
| `dap-aios/CLAUDE.md` | corrigida linha falsa "Drizzle ainda NÃO modela RLS" |

## Commits / PR

- `fadf57a` feat(finance): adota 10 tabelas ... · `c1f704a` fix(finance): guarda policies por role authenticated
- **PR #55** → squash `00f5f43` na `main` (via `--admin`; thread do Codex resolvido).

## Como conferir

- `pg_class`/`pg_policy` no `hlhf`: 10 tabelas `relrowsecurity=true`, 1 policy `*_write_audit_admin` cada.
- `db:push --force` agora **não dropa** mais as 10 (estão no schema). Causa-raiz do drift R13 fechada.

## Riscos / notas

- **Delta cosmético:** o `hlhf` mantém nomes de constraint legados (`*_fkey`/`*_key`) vs convenção
  drizzle (`*_fk`/`*_unique`). Inofensivo — só vira churn (drop+recreate da MESMA FK) se adotarem
  `db:push`. Pra zerar: renomear as constraints do `hlhf` ou nomear explícito no schema.
- **`0007` NÃO registrada no `__drizzle_migrations` do `hlhf`** (aplicada via MCP como no-op, igual
  a `0004`). Quando um `db:migrate` rodar de ambiente com devDeps, aplica no-op e registra.

## Pendências (não desta rodada)

- **Construir backend/rotas que consomem o financeiro** — hoje `FinanceiroPage.tsx` usa mock
  (`gestao/financeiro/data.ts`). O schema é a fundação; o wiring de dados reais é frente própria.
- Toggle "leaked password protection" no painel Supabase Auth (WARN advisor).
- Corrigir caminho do compose no `docs/RUNBOOK-DEPLOY.md` (aponta pro stack errado).
- Trazer as constraints legadas do `hlhf` pra convenção drizzle (se adotarem `db:push`).

## Próxima rodada sugerida

Backend do financeiro no `dap-aios`: service + rotas (`requirePermission('finance', …)`) +
event log, ligando a `FinanceiroPage` aos dados reais. Schema já pronto e tipado em `@aios/types`.
Paraleliza por agregado (suppliers / purchase_orders / invoices / bills / dre).
