---
type: handoff
date: 2026-05-08
time: 18:40
project: dap4-portals (monorepo)
topic: 2 cleanups (hoist pnpm.overrides + 6 erros typecheck operacao) + drizzle-kit pull contra DOCTOR PRIME → drift detectado (oficina+gestao paridade, aios+crm aspiracional, RLS + CHECK = tech debt). 3 commits pushados.
tags: [handoff, claudin, dap4, monorepo, drizzle, introspect, drift, supabase]
---

# Handoff — dap4-portals: 2 cleanups + introspect DOCTOR PRIME (drift detectado)

> **Carry-over** do `handoff-2026-05-08-1434-dap4-monorepo-task38-fechada-db-baseline.md` (Task 3.8 fechada + operacao adopta @dap/db + drizzle-kit baseline 0000).

## Contexto

Sessão executou os 2 cleanups carry-over de 3-4 handoffs (hoist `pnpm.overrides` e 6 erros pré-existentes do typecheck operacao) — finalmente quitados. Em seguida, primeiro `drizzle-kit pull` contra DOCTOR PRIME real pra detectar drift entre schema TS e estado de produção. Drift mapeado, decisão tomada de NÃO gerar 0001 diferencial agora.

Commits: 3 (`b3963de`, `0df4ad9`, `7cf7c5a`). Estado atual em `main`.

## O que funcionou (com evidência)

- **Hoist `pnpm.overrides` apps/aios → root** — block movido pra `package.json` raiz. Warning constante a cada `pnpm install` ("This will not take effect. You should configure 'pnpm.overrides' at the root of the workspace instead") finalmente eliminado. Carry-over de 4 handoffs.
  - evidência: commit `b3963de`. `pnpm install` agora limpo, sem o warning.
- **6 erros pré-existentes typecheck operacao → 0** — adicionado `nanoid` (dep, usado em `server/vite.ts:7` pra cache-bust de `src/main.tsx`) + `@types/express-serve-static-core` (devDep, necessário pro `declare module "express-serve-static-core"` em `server/middleware/auth.ts:32` que adiciona `Request.user` — sem essa aug, 4 erros TS2339 em cascata). `tsc` operacao agora silencioso.
  - evidência: commit `0df4ad9`. `pnpm --filter @dap/operacao check` retorna sem output (verde).
- **Introspect config + gitignore** — `packages/db/drizzle.introspect.config.ts` + `.gitignore` (`/.introspect/`) criados pra rodar `drizzle-kit pull` isolado sem poluir `migrations/`.
  - evidência: commit `7cf7c5a`
- **`drizzle-kit pull` contra DOCTOR PRIME** — rodou com sucesso após várias tentativas (ver "O que NÃO funcionou"). Resultado: 18 tabelas / 162 columns / 41 indexes / 39 FKs / 20 policies / 3 CHECK constraints / 0 enums detectados. Files gerados em `.introspect/` (depois deletados — gitignored, mas continham SQL completa de prod).

## Drift detectado (resumo executivo)

### Paridade nome-level

| Schema | TS prevê | DB real | Status |
|---|---|---|---|
| oficina | 13 tabelas | 13 tabelas | ✅ paridade |
| gestao | 5 tabelas | 5 tabelas | ✅ paridade |

### Aspiracional (TS antecipa, DB ainda não tem)

| Schema | TS prevê | DB real | Diagnóstico |
|---|---|---|---|
| aios | 2 tabelas (conversations, messages) | schema NÃO existe | Fase 4 futura — virá com a feature work do gateway |
| crm | 3 tabelas + 2 enums (lead_status, lead_tier) | schema NÃO existe | Multi-tenant futuro |

### 🚨 Tech debt: DB tem, schema TS NÃO descreve

- **20 RLS policies** em oficina + gestao:
  - `tenant_isolation_all` em organizations, kpi_snapshots, okrs, adrs
  - `tenant_or_self_select` em users (gestao + oficina) — `auth_user_id = auth.uid()` OR org-level
  - `tenant_modify` em users
  - Funções helper SQL: `gestao.current_user_org_id()`, `oficina.current_user_org_id()`
- **3 CHECK constraints** (closed enums via SQL) em gestao:
  - `okrs.status` → `['em_curso', 'em_risco', 'atingido', 'falhou', 'cancelado']`
  - `adrs.status` → `['proposed', 'accepted', 'superseded', 'deprecated']`
  - `users.role` → `['admin', 'chairman', 'diretor', 'cfo']`
  - Em oficina o schema TS comenta explicitamente "Open-domain text columns STAY as text" — mas gestao não documentou isso e ganhou CHECK via migration. Drift entre intenção e realidade.

### Decisão

**NÃO gerar 0001 diferencial agora.** Drift é (a) aspiracional ou (b) tech debt não urgente. `db:push` está bloqueado mentalmente até refletir RLS + CHECK no Drizzle schema (senão drizzle-kit tentaria dropar tudo).

## O que NÃO funcionou (e por quê)

- **Senha `Doctorauto1234@@@` original do DOCTOR PRIME** — não autentica (`28P01 password authentication failed for user "postgres"`). Após reset via dashboard, nova senha `9HahLsdgbHqPJ6Z5` funcionou.
- **`drizzle-kit pull` ficando em "0 tables fetching" infinito** — manifestação confusa de senha errada. Drizzle-kit não retorna erro 28P01 explicitamente como o `pg.Client` direto. Validar conectividade primeiro com `pg.Client` antes de gastar tempo no drizzle-kit.
- **Connection string colada com host legacy** (`db.acuufrgoyjwzlyhopaus.supabase.co:6543`) — formato antigo do Supabase pooler (PgBouncer local) descontinuado. Hoje pooler é Supavisor (`aws-0-<region>.pooler.supabase.com`, username `postgres.<ref>`). Gerou várias tentativas frustradas até descobrir.
- **Tentativa de Supavisor regions** — testar regiões diferentes:
  - sa-east-1: `Tenant or user not found` ❌
  - us-east-1: `Tenant or user not found` ❌
  - us-west-2: `password authentication failed` ✅ (= região correta, senha errada)
  - **us-west-2 confirmado como região do DOCTOR PRIME**.
- **Direct connection (5432, host `db.<ref>.supabase.co`)** — voltou a funcionar com a senha nova. Antes travava (suspeitei IPv6 issue), na verdade era só senha errada com manifestação confusa. **Direct connection é o caminho mais limpo pra `drizzle-kit pull`**.
- **2 senhas expostas no chat hoje** (a antiga `Doctorauto1234@@@` que falhou, e a nova `9HahLsdgbHqPJ6Z5` que funcionou). Recomendado **resetar mais uma vez** pra higiene + atualizar `.env`/vault locais.

## O que ainda não foi tentado

- **Refletir 20 RLS policies no Drizzle schema** — drizzle-orm 0.36+ tem `pgPolicy()`. Médio esforço, mas necessário pra `db:push` ficar safe.
- **Refletir 3 CHECK constraints no Drizzle schema** (gestao) — adicionar `check()` no schema ou virar `pgEnum`. Decidir antes se quer fechar enums (gestao) ou manter abertos (oficina convention).
- **Criar tabelas aios + crm em prod** — quando rolar Fase 4 / multi-tenant rollout. Schema TS já descreve, então `drizzle-kit generate` vai produzir 0001_* diferencial automaticamente nessa hora.
- **`apps/operacao/tests/auth-jwt.test.ts`** (carry-over) — copiar template de gestao (4/4) e adaptar. Low-risk fillin.
- **Drizzle schema migration runtime gestao → Drizzle** (carry-over Task 3.7) — ~50+ files. Big lift.
- **`@dap/ui` exports map TS-friendly** (carry-over) — eliminar aliases em `apps/aios/{tsconfig,vite.config}`.
- **Resetar senha DOCTOR PRIME mais uma vez** — higiene pós-exposição de 2 senhas no chat.
- **Mount `@dap/kommo` em algum portal** (carry-over) — diferido até portal precisar.
- **🚨 SECURITY (carry-over de 5 handoffs):** `C:\THALES\autodiag-copilot\.env.local` com secrets parados há 23 dias. Rotacionar.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `package.json` (root) | Modificado | + bloco `pnpm.overrides` movido do aios |
| `apps/aios/package.json` | Modificado | bloco `pnpm.overrides` removido |
| `apps/operacao/package.json` | Modificado | + `nanoid` (dep), `@types/express-serve-static-core` (devDep) |
| `pnpm-lock.yaml` | Modificado | sync das 2 mudanças |
| `packages/db/drizzle.introspect.config.ts` | Novo | config separada pra `drizzle-kit pull` (out: `./.introspect`, gitignored) |
| `packages/db/.gitignore` | Novo | ignora `.introspect/`, `node_modules/`, `tsconfig.tsbuildinfo` |
| `packages/db/.introspect/**` | Local-only | gerado pelo pull, depois deletado (continha schema completo de prod) |

## Decisões tomadas

- **Cleanups (3) primeiro, depois introspect** — sequência correta. Os 2 cleanups eram dívida acumulada de 3-4 handoffs; resolver antes deixou monorepo em estado limpo pro introspect.
- **Direct connection (5432) para drizzle-kit pull, não pooler** — mais limpo, session-mode garantido. Pooler `:6543` é transaction-mode e pode quebrar queries longas de introspect.
- **NÃO gerar 0001 diferencial** — drift é aspiracional + tech debt não urgente. Forçar `db:generate` agora geraria SQL que tenta dropar RLS/CHECK.
- **Deletar `.introspect/` pós-análise** — gitignored mas continha SQL completa de prod. Boa prática.
- **Memory atualizada** — 2 arquivos novos:
  - `feedback_supabase_connection_strings.md` — gotchas connection string (legacy vs Supavisor, IPv6, regiões, URL-encoding de `@`)
  - `project_doctor_prime_drift_2026_05_08.md` — snapshot do drift detectado (estado real do DB em 2026-05-08)
- **Recomendado resetar senha mais uma vez** — pós-sessão. Sem urgência se reset for hoje/amanhã.

## Bloqueios & perguntas abertas

- **🟡 Refletir RLS + CHECK no Drizzle schema** — desbloqueia `db:push` futuro. Sem isso, qualquer `db:push` é destrutivo.
- **🟡 Quando criar aios + crm em prod?** — depende do roadmap (Fase 4 do gateway aios; multi-tenant rollout do crm).
- **🚨 SECURITY:** carry-over de 5 handoffs sobre `autodiag-copilot/.env.local`. Reset urgente. Mais hoje: senhas DOCTOR PRIME expostas no chat — reset recomendado.
- **Onde mora autodiag-copilot longo prazo?** (carry-over) Provavelmente esse é o "código pré-existente" que vai mesclar com `apps/tools` no refactor futuro.
- **gestao runtime → Drizzle (Task 3.7 cleanup)** — ainda aguarda decisão estratégica de quando.

## Próximo passo exato

**Recomendação: refletir RLS + CHECK constraints no Drizzle schema** pra desbloquear `db:push` safely.

Sugestão de ordem prática (próxima sessão):

1. **Adicionar `pgPolicy()` em `packages/db/src/schema/oficina.ts` + `gestao.ts`** — refletir as 20 policies detectadas. Use os helpers `gestao.current_user_org_id()` / `oficina.current_user_org_id()` via `sql\`...\`` literal. Padrão: `tenant_isolation_all` permissivo `for: "all"`, `tenant_or_self_select` permissivo `for: "select"`, `tenant_modify` permissivo `for: "all"`.

2. **Adicionar `check()` em gestao schema** — 3 CHECK constraints: okrs.status, adrs.status, users.role. Decidir antes: manter como CHECK aberto ou converter pra `pgEnum` (mais limpo type-side).

3. **Re-rodar `drizzle-kit pull`** contra DOCTOR PRIME pra confirmar paridade pós-reflexão. Idealmente, `drizzle-kit generate` deveria reportar "No schema changes" se reflexão foi 1:1.

4. **Resetar senha DOCTOR PRIME** — pós-exposição (carry-over).

5. **`apps/operacao/tests/auth-jwt.test.ts`** (carry-over) — fillin low-risk.

6. **Quando criar tabelas aios+crm em prod**: rodar `db:generate` → vai produzir 0001_*.sql diferencial automaticamente. Apply via `db:push` (após RLS reflexão) ou aplicar SQL manualmente.

## Setup / comandos úteis

```bash
# Entrar
cd C:/THALES/DAP4/dap4-portals

# State
git log --oneline -10
pnpm ls -r --depth -1   # 14 workspace projects

# Build / tests
pnpm --filter @dap/operacao check    # agora verde (0 erros)
pnpm --filter @dap/operacao build
pnpm --filter @dap/gestao test       # 8/8 inclui auth-jwt

# DB introspect (drift detection)
DATABASE_URL="postgresql://postgres:<senha>@db.acuufrgoyjwzlyhopaus.supabase.co:5432/postgres" \
  pnpm --filter @dap/db exec drizzle-kit pull --config=drizzle.introspect.config.ts
# Output em packages/db/.introspect/ (gitignored). Comparar com src/schema/*.ts.
# Deletar pós-análise: rm -rf packages/db/.introspect

# Migration baseline já gerada (não aplicada)
ls packages/db/migrations/    # 0000_equal_doctor_spectrum.sql + meta/
```

**DOCTOR PRIME connection string:**
```
postgresql://postgres:<senha>@db.acuufrgoyjwzlyhopaus.supabase.co:5432/postgres
                                                                       └─ direct (5432)
                                                                       └─ Supavisor pooler (us-west-2):
   postgresql://postgres.acuufrgoyjwzlyhopaus:<senha>@aws-0-us-west-2.pooler.supabase.com:5432/postgres
```

**Plano fonte:** `C:\THALES\DAP4\docs\superpowers\plans\2026-05-06-dap4-monorepo-migration.md`. Tasks 3.0-3.8 todas com ✅. Task 4+ não iniciadas.

**Repo monorepo:** `https://github.com/toliveira1802-sketch/dap4-portals` — branch `main` em `7cf7c5a`.

**Commits dessa sessão (3):**
```
7cf7c5a chore(db): introspect config separado pra drift detection
0df4ad9 fix(operacao): adicionar deps faltantes (nanoid + @types/express-serve-static-core)
b3963de chore: hoist pnpm.overrides apps/aios → root package.json
```

**Memory atualizada:**
- ✅ `feedback_supabase_connection_strings.md` — direct vs Supavisor, IPv6, regiões, URL-encoding `@`
- ✅ `project_doctor_prime_drift_2026_05_08.md` — snapshot drift (oficina+gestao OK, aios+crm aspiracional, RLS+CHECK debt)
- (anteriores: project_dap_portal_architecture, project_dap_tools_product, feedback_drizzle_kit_namespace, feedback_supabase_typescript_schema_inference)
