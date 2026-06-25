---
type: handoff
date: 2026-05-07
time: 11:27
project: dap4-portals (monorepo)
topic: Status carry-over + DRIFT detectado nos repos legacy (Auth ADR-001) + Task 3.1 ainda pending
tags: [handoff, claudin, dap4, monorepo, drift, auth-supabase]
---

# Handoff — dap4-portals: drift detectado, Fase 3 ainda não começou

> **Carry-over** do handoff `handoff-2026-05-06-0757-dap4-portals-bootstrap.md`.
> Esse documento substitui o anterior como referência ativa. O bootstrap
> handoff continua válido pra histórico de Fases 0+1+2.

## Contexto

Monorepo único pnpm workspace `dap4-portals`
(`https://github.com/toliveira1802-sketch/dap4-portals`) já tem Fases 0+1+2
fechadas (16/35 tasks): bootstrap + subtree merge dos 4 portais legacy
preservando histórico. Próximo era dispatch da Task 3.1 (`@dap/types`).

**Nada foi executado entre 2026-05-06 07:57 e agora.** O Thales mudou
de contexto pra outras frentes (dap-drive-plan virou desktop Tauri, e
ADR-001 Auth Unification fechou Fase 3 nos repos standalone). Resultado:
**dois drifts** que o monorepo precisa absorver antes do sunset (Task 7).

Stack canônica continua: pnpm 9 · Node 20 LTS · TS 5.6 · Express 5 ·
Drizzle ORM · Supabase Postgres único · Vite + React 18 · Wouter · Radix UI
· Tailwind 3.4 · Vitest. Layout: `apps/{aios,operacao,gestao,tools}` +
`packages/{config,types,ui,db,auth,agents,kommo}`.

## ⚠️ DRIFT detectado (CRÍTICO antes da Task 7 / sunset)

Quando o monorepo bootstrapou (2026-05-06 07:57), os subtree merges
pegaram esses HEADs dos repos legacy:

| Portal | HEAD no merge | HEAD atual no standalone | Drift |
|---|---|---|---|
| `apps/aios` | aios `7734617` (branch feat/aios-nucleo-consultor) | a verificar | ? |
| `apps/operacao` | operacao `19fe2d9` | **provavelmente avançado (ADR-001 ambos portais)** | 🟠 a confirmar |
| `apps/gestao` | gestao `c976c11` | gestao `64560a6` | 🔴 **5 commits ahead** |
| `apps/tools` | tools `91c8b77` (adc-DAp40) | a verificar | ? |

### Drift confirmado: `dap-gestao` Auth Unification ADR-001

5 commits novos em `C:\THALES\DAP4\dap-gestao` master após o subtree merge:

```
64560a6 docs(adr): preencher seção Implementation outcome do ADR-001
43e8d45 feat(auth): /reset-password route + hash bootstrap + hide Google (Fase 3)
de68af1 feat(auth): Supabase Auth — JWT backend + browser GoTrue REST (ADR-001 Fase 3)
512088a feat(schema): add authUserId field + nullable password (ADR-001)
9c7af1b docs(adr): ADR-001 — unificar auth dos portais sob Supabase Auth
```

Mudanças principais (ver handoff irmão `handoff-2026-05-07-1127-dap-gestao-supabase-auth-fase3-done.md`):

- Schema `gestao.users.auth_user_id uuid UNIQUE` + `password` nullable
- Backend middleware JWT via `supabase.auth.getUser(jwt)` + session fallback
- Frontend cliente Supabase `persistSession:false` + custom fetch override
- `authStore.ts` manual em localStorage com refresh agendado
- `authService.ts` GoTrue REST direto
- `/reset-password` route + `consumeAuthCallbackHash()` pré-React
- ADR-001 documentado em `docs/adrs/0001-auth-unification.md`
- Test `tests/auth-jwt.test.ts` (4 cenários do middleware)

### Drift provável: `dap-operacao`

ADR-001 explicitamente diz "Backend (ambos portais)", "Frontend (ambos
portais)". Operacao quase certamente tem commits análogos. **Precisa
confirmar com `git -C C:/THALES/DAP4/dap-operacao log --oneline | head`**
e comparar com `19fe2d9`.

### Mitigação sugerida (antes da Task 3.7 e/ou Task 7)

Pra cada repo com drift, fazer **subtree pull** atualizando `apps/<portal>`
no monorepo:

```bash
cd C:/THALES/DAP4/dap4-portals

# Adicionar remotes legacy se ainda não tiver
git remote add legacy-gestao C:/THALES/DAP4/dap-gestao
git remote add legacy-operacao C:/THALES/DAP4/dap-operacao
git fetch legacy-gestao
git fetch legacy-operacao

# Pull subtree (squash ou no-squash conforme preferência — bootstrap usou no-squash)
git subtree pull --prefix=apps/gestao legacy-gestao master
git subtree pull --prefix=apps/operacao legacy-operacao master
```

**Risco:** se a Task 3.4 (`@dap/auth`) começar antes desse pull, o trabalho
de Auth no monorepo conflita com o que já tá nos standalone. **Decisão
forte:** fazer o subtree pull ANTES de qualquer Task da Fase 3 que toque
em código de auth — idealmente como **Task 3.0 (nova)** inserida agora.

## Status atual do monorepo

Inalterado desde 2026-05-06 07:57. 9 commits no main, push OK. 8 workspace
projects (`@dap/config`, `@dap/aios`, `@dap/operacao`, `@dap/gestao`,
`@dap/tools`, `@dap/types`, `@dap/ui` + root). `pnpm install` clean.
`pnpm --filter @dap/operacao build` GREEN.

TaskList:
```
#1-#16: completed (Fases 0+1+2)
#17 Task 3.1 @dap/types — pending (PRÓXIMO depois do drift fix)
#18 Task 3.2 @dap/ui — pending
#19-#35: pending (Fases 3-8)
```

## O que ainda não foi tentado (Fases 3-8 inalteradas)

- **Task 3.0 (NOVA — proposta)** — subtree pull dos drifts (gestao
  confirmado, operacao a confirmar, aios+tools a verificar)
- **Fase 3 (8 tasks)** — packages compartilhados (`@dap/types`, `@dap/ui`,
  `@dap/db`, `@dap/auth`, `@dap/agents`, `@dap/kommo`, refactor consumers,
  despedaçar tools)
- **Fase 4 (2)** — aios libSQL → Postgres
- **Fase 5 (2)** — Passport+session → Supabase Auth em operacao+gestao —
  **ATENÇÃO**: parte disso já foi feito nos standalone (ADR-001 Fase 3),
  então essa fase precisa ser repensada como "absorver e padronizar"
  em vez de "implementar do zero"
- **Fase 6 (3)** — GH Actions CI + deploy workflows
- **Fase 7 (3)** — README archive + `gh repo archive` 3 repos + memory/Obsidian
- **Fase 8 (1)** — smoke E2E + tag `v1.0.0-monorepo`

## Decisões tomadas (recap do bootstrap + novas)

- Monorepo único pnpm workspace, 1 repo GitHub novo, archived 3 legacy
- pnpm scripts puros (sem Turborepo até virar gargalo)
- `apps/aios/packages/{types,ui}` serão promovidos via `git mv` em 3.1/3.2
- `autodiag-copilot/` extraído pra `C:\THALES\autodiag-copilot\` (orfão,
  precisa decidir casa longo prazo)
- **NOVA**: ADR-001 Auth Unification já entregue nos standalone — Fase 5
  do plano monorepo precisa ser repensada (absorver, não reimplementar)
- **NOVA**: Inserir Task 3.0 (subtree pull dos drifts) antes da Fase 3

## Bloqueios & perguntas abertas

- **🟠 DRIFT confirmado em dap-gestao, provável em dap-operacao** — fazer
  subtree pull antes de mexer em qualquer auth no monorepo
- **🚨 SECURITY (carry-over):** `C:\THALES\autodiag-copilot\.env.local` tem
  secrets reais Supabase parados há 20 dias. Rotacionar.
- **Onde mora autodiag-copilot longo prazo?** (carry-over) Repo próprio?
  Parte de DAP AI? DAP Project? Descontinuado? Decisão antes de Task 7.
- **Fase 5 do plano monorepo precisa repensar** — boa parte do trabalho
  já tá nos standalone. Renomear pra "Auth integration: absorber Fase 3
  do ADR-001 + padronizar via `@dap/auth` package"?
- **Plano original Tasks 3.1/3.2 vs realidade** (carry-over) — promover
  existing `apps/aios/packages/{types,ui}` em vez de criar do zero
- **`pnpm.overrides` em `apps/aios/package.json`** (carry-over) — hoist
  pra root quando cleanup
- **dap-operacao auth-jwt test deferred** — mock de `supabase.auth.getUser`
  exigia stub GoTrue. Reabrir junto com `@dap/auth` package

## Próximo passo exato

**Inserir e executar Task 3.0 (NOVA): subtree pull dos drifts.**

Antes de tocar em qualquer outra coisa:

1. Confirmar drifts:
   ```bash
   cd C:/THALES/DAP4/dap-aios && git log --oneline 7734617..HEAD | head -20
   cd C:/THALES/DAP4/dap-operacao && git log --oneline 19fe2d9..HEAD | head -20
   cd C:/THALES/DAP4/dap-gestao && git log --oneline c976c11..HEAD | head -20
   cd C:/THALES/DAP4/dap-tools && git log --oneline 91c8b77..HEAD | head -20
   ```

2. Pra cada drift confirmado, subtree pull:
   ```bash
   cd C:/THALES/DAP4/dap4-portals
   git remote add legacy-<portal> C:/THALES/DAP4/dap-<portal>
   git fetch legacy-<portal>
   git subtree pull --prefix=apps/<portal> legacy-<portal> <branch>
   git push
   ```

3. Build sanity:
   ```bash
   pnpm install
   pnpm --filter @dap/operacao build
   pnpm --filter @dap/gestao build
   pnpm -r test
   ```

4. **Atualizar plano fonte** (`docs/superpowers/plans/2026-05-06-dap4-monorepo-migration.md`):
   - Inserir Task 3.0 (subtree pull) como concluída
   - Repensar Fase 5 pra "absorver ADR-001"
   - Ajustar Tasks 3.1/3.2 pra "promover existing"

5. **Só então dispatch Task 3.1** (`@dap/types`):
   ```bash
   cd C:/THALES/DAP4/dap4-portals
   ls apps/aios/packages/types/src/
   cat apps/aios/packages/types/src/index.ts
   ```
   Decidir: `git mv apps/aios/packages/types packages/types` + adicionar
   Lead/User/Tenant/Kommo schemas se faltarem, com TDD.

## Setup / comandos úteis

```bash
# Entrar
cd C:/THALES/DAP4/dap4-portals

# Workspace state
pnpm ls -r --depth -1

# Build
pnpm --filter @dap/operacao build
pnpm --filter @dap/gestao build

# Dev (portas)
pnpm dev:aios       # 5050
pnpm dev:operacao   # 5051
pnpm dev:gestao     # 5052

# Test
pnpm -r test
```

**Plano fonte:** `C:\THALES\DAP4\docs\superpowers\plans\2026-05-06-dap4-monorepo-migration.md`

**Handoff irmão (drift detail do gestao):**
`handoff-2026-05-07-1127-dap-gestao-supabase-auth-fase3-done.md`

**Memory atualizar (Task 7.3, ainda pendente):**
- `project_dap_portal_architecture.md` — monorepo único + paths novos
- Nova: `project_autodiag_copilot.md` — extraído pra C:\THALES\
- Atualizar `project_dap_tools_real.md` — apps/+autodiag/+DAP4.0 nunca foram repo
- Nova/atualizar: `project_dap4_auth_unification.md` — ADR-001 Fase 3 done
  nos standalone, monorepo precisa absorver
