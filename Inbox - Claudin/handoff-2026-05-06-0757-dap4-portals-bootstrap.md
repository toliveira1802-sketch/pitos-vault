---
type: handoff
date: 2026-05-06
time: 07:57
project: dap4-portals (monorepo)
topic: Migração 4 portais DAP4 → monorepo único pnpm — Fases 0+1+2 fechadas (16/35 tasks)
tags: [handoff, claudin, dap4, monorepo, migration]
---

# Handoff — dap4-portals: Bootstrap + Subtree Merges concluídos

## Contexto

O Thales decidiu padronizar os 4 portais DAP4 (`dap-aios`, `dap-operacao`, `dap-gestao`, `dap-tools`) que viviam em repos separados sob `C:\THALES\DAP4\` em **um monorepo único pnpm workspace** chamado `dap4-portals`. Decisões travadas no início da sessão:

1. **1 repo único novo** (`toliveira1802-sketch/dap4-portals`), 3 repos legados serão archived
2. **Cutover Supabase primeiro** (descobri que operacao + gestao já fecharam — só aios libSQL→PG ficou pendente)
3. **pnpm scripts puros** (sem Turborepo até virar gargalo)

Plano completo de 8 fases / 35 tasks gravado em `C:\THALES\DAP4\docs\superpowers\plans\2026-05-06-dap4-monorepo-migration.md`. Execução via subagent-driven-development (skill superpowers).

Stack canônica do monorepo: pnpm 9 · Node 20 LTS · TS 5.6 · Express 5 · Drizzle ORM · Supabase Postgres único · Vite + React 18 · Wouter · Radix UI · Tailwind 3.4 · Vitest. Layout final: `apps/{aios,operacao,gestao,tools}` + `packages/{config,types,ui,db,auth,agents,kommo}`.

## O que funcionou (com evidência)

- **Fase 0 — Safety net** — 4 git bundles criados em `PITOS/Backups/monorepo-cutover-2026-05-06/` com SHA-256 manifest. Working trees limpos nos 4 repos legados (5 commits novos pushados no total: aios `7734617`, operacao `19fe2d9`, gestao `c976c11`, tools `91c8b77`).
- **Repo `dap4-portals` criado** — privado em `https://github.com/toliveira1802-sketch/dap4-portals`, descrição correta, vazio.
- **Fase 1 — Bootstrap** — pnpm workspace + `@dap/config` (tsconfig/eslint/tailwind/vitest base) + tsconfig raiz + prettier. 4 commits: `73072e7`, `6cc9d07`, `7ff7b21`, `8158dec`. `pnpm install` clean.
- **Fase 2 — Subtree merges** — 4 portais importados preservando histórico via `git subtree merge`: aios `d638139`, operacao `52dc898`, gestao `e9ade59`, tools `f0f6c9c`. File counts (tracked): aios=211, operacao=167, gestao=58, tools=158.
- **Task 2.5 — Workspace consolidation** — apps renomeados pra `@dap/*` scope, lockfiles internos removidos, single root `pnpm-lock.yaml`. Commit `5e2591e`. **8 workspace projects** rodando: root + @dap/config + @dap/aios + @dap/operacao + @dap/gestao + @dap/tools + @dap/types + @dap/ui.
- **Smoke build operacao** — `pnpm --filter @dap/operacao build` GREEN (Vite client + esbuild server bundle 1.2mb).
- **Cleanup colateral dap-tools** — descobri 230 arquivos untracked em 3 dirs (`apps/`, `autodiag-copilot/`, `DAP4.0/`). Triagem via subagent revelou: scaffold morto (`apps/`), produto real (`autodiag-copilot` extraído pra `C:\THALES\autodiag-copilot\`), wrapper natimorto (`DAP4.0/` deletado). Tarball safety em `C:\THALES\_archive\dap-tools-untracked-2026-05-06.tgz` (1.04MB).

## O que NÃO funcionou (e por quê)

- **Tar com path Windows `C:/...`** — falhou primeira vez com `tar (child): Cannot connect to C: resolve failed` — tar interpretou `C:` como hostname (rsync-style). Workaround: flag `--force-local`.
- **`corepack enable` global** — bloqueado por `EPERM` em `C:\Program Files\nodejs\yarnpkg` (precisa admin). Workaround: `corepack prepare pnpm@9.15.0 --activate` direto, packageManager field no package.json auto-shim.
- **Task 2.5 primeira tentativa BLOQUEADA** — `pnpm install` falhou com `ERR_PNPM_WORKSPACE_PKG_NOT_FOUND` para `@dap/types` e `@dap/ui` porque `apps/aios/packages/{types,ui,config}/` existem como packages legacy do workspace antigo do aios. `apps/aios/packages/config` colidia com root `packages/config`. Resolução: deletei `apps/aios/packages/config` (root é superset), adicionei `apps/aios/packages/*` ao workspace raiz.
- **Export key mismatch `@dap/config`** — legacy aios usava `"./tsconfig.base.json"`, root usa `"./tsconfig.base"`. Aios tsconfigs referenciam o legacy. Resolvido com alias adicionado em `packages/config/package.json` exports — preserva ambos working sem editar source files do aios.
- **Explore agent travou** — primeira tentativa de triagem dos 3 dirs untracked confundiu-se com constraint imaginário ("no tools allowed"). Redispatchado em general-purpose, funcionou.

## O que ainda não foi tentado

- **Fase 3 (8 tasks) — packages compartilhados:**
  - Task 3.1 (`@dap/types`) e 3.2 (`@dap/ui`) **vão promover** `apps/aios/packages/types` e `apps/aios/packages/ui` (via `git mv`) em vez de criar do zero — código já existe lá, melhor que duplicar
  - Task 3.3 (`@dap/db`) — Drizzle schema unificado (oficina/gestao/aios/crm) + getDb/getSupabase + RLS helpers
  - Task 3.4 (`@dap/auth`) — Supabase Auth wrapper + middleware + RBAC, com TDD
  - Task 3.5 (`@dap/agents`) — Anthropic SDK + Sophia/Anna/Walter wrappers
  - Task 3.6 (`@dap/kommo`) — portar `apps/tools/backend/server.js` (Express 4 JS) pra TS package
  - Task 3.7 — refactor operacao+gestao consumindo packages
  - Task 3.8 — despedaçar `apps/tools/` (subdirs `backend/`, `web/`, `operacao/`, `tools/`)
- **Fase 4 (2)** — aios libSQL → Postgres (apply schema + driver swap)
- **Fase 5 (2)** — Passport+session → Supabase Auth em operacao+gestao (⚠️ memory `feedback_supabase_lock_deep_bug` — getSession PKCE hang. Testar Chrome real, não só Playwright)
- **Fase 6 (3)** — GH Actions CI + deploy workflows
- **Fase 7 (3)** — README archive + `gh repo archive` 3 repos + memory/Obsidian update
- **Fase 8 (1)** — smoke E2E + tag `v1.0.0-monorepo`

## Arquivos tocados

| Arquivo / dir | Status | Notas |
|---|---|---|
| `C:\THALES\DAP4\dap4-portals\` | **Em progresso** | Fases 0-2 fechadas (9 commits no main, push OK) |
| `C:\THALES\DAP4\dap-aios\` | Completo (sunset pendente) | Branch `feat/aios-nucleo-consultor` HEAD `7734617`, push OK. Será archived na Task 7.2 |
| `C:\THALES\DAP4\dap-operacao\` | Completo (sunset pendente) | master HEAD `19fe2d9`, push OK. Será archived |
| `C:\THALES\DAP4\dap-gestao\` | Completo (sunset pendente) | master HEAD `c976c11`, push OK. Será archived |
| `C:\THALES\DAP4\dap-tools\` | Completo (sunset pendente) | adc-DAp40 HEAD `91c8b77`, push OK. apps/+autodiag/+DAP4.0 cleanados. Será archived |
| `C:\THALES\autodiag-copilot\` | **Extraído (orfão)** | Movido pra fora do dap-tools com `.git` próprio. Produto real (vanilla JS + Supabase + deploy.sh) — precisa decidir se vira repo independente ou parte de outro lugar |
| `C:\THALES\_archive\dap-tools-untracked-2026-05-06.tgz` | Safety net | 1.04MB tar dos 230 arquivos descartados |
| `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Backups\monorepo-cutover-2026-05-06\` | Safety net | 4 .bundle files + MANIFEST.md + dap-operacao-oficina.db.bak |
| `C:\THALES\DAP4\docs\superpowers\plans\2026-05-06-dap4-monorepo-migration.md` | Plano fonte | ~1500 linhas, 8 fases, 35 tasks. Plano vivo, atualizar quando decisões mudarem (Tasks 3.1/3.2 mudaram pra "promover" em vez de "criar") |

## Decisões tomadas

- **Monorepo único pnpm workspace** (nível 3 das 3 opções apresentadas) — razão: aios já era pnpm workspace, eliminar duplicação Radix/Drizzle/Tailwind, janela perfeita do cutover Supabase em curso, Sennin/Chairman OS pede agentes consistentes.
- **1 repo GitHub novo** (`dap4-portals`) em vez de reaproveitar dap-operacao — razão: clean state, archive dos 3 legacy preserva histórico via subtree, workflow simples de PR cross-portal.
- **Cutover primeiro, depois monorepo** — descoberta na execução que operacao+gestao **já fecharam Postgres** (commits `506d28d` + `8fb25a7`); só aios libSQL pendente (vira Fase 4 do plano).
- **pnpm scripts puros, sem Turborepo** — começa simples, Turborepo só se cache virar gargalo (memory feedback).
- **`apps/aios/packages/{types,ui}` ficam como workspace legacy temporário** — vão ser promovidos pra `packages/types` e `packages/ui` raiz nas Tasks 3.1/3.2 via `git mv` (preserva código real, evita duplicação).
- **Deletei `apps/aios/packages/config`** — root config é superset (eslint+vitest extras), zero perda.
- **`autodiag-copilot/` extraído pra `C:\THALES\autodiag-copilot\`** — é produto real próprio, não parte de dap-tools, precisa casa própria.
- **`apps/` e `DAP4.0/` deletados de dap-tools** — scaffolds mortos, zero valor, tar de safety se algum dia precisar.

## Bloqueios & perguntas abertas

- **🚨 SECURITY (sua ação):** `C:\THALES\autodiag-copilot\.env.local` tem **secrets reais (Supabase) sentado há 19 dias** num dir untracked (não vazou via git, mas tá no disco). Rotacionar quando puder.
- **Onde mora autodiag-copilot longo prazo?** Hoje: `C:\THALES\autodiag-copilot\`. Deveria virar repo próprio no GitHub? Parte de DAP AI? DAP Project? Projeto descontinuado? Precisa decidir antes de Task 7 (sunset).
- **`pnpm.overrides` em `apps/aios/package.json`** — pnpm warning ignorando porque não é root. Hoist pra root quando cleanup.
- **Plano original Tasks 3.1/3.2** descreviam criar `@dap/types` e `@dap/ui` do zero com Lead/User/Tenant/Kommo schemas + Button/Card/Dialog. Realidade: esses já existem em `apps/aios/packages/`. Próxima sessão precisa decidir: promover existing as-is + adicionar schemas faltantes, ou refatorar pra match plan exatamente?

## Próximo passo exato

**Iniciar Fase 3 dispatchando subagent pra Task 3.1 (`@dap/types`).**

Antes de dispatch, ler `C:\THALES\DAP4\dap4-portals\apps\aios\packages\types\src\index.ts` (e arquivos próximos) pra entender o que já existe lá. Decidir: promover via `git mv` (preserva histórico) + adicionar Lead/User/Tenant/Kommo schemas se faltam, ou refatorar.

Comando preparatório:
```bash
cd C:/THALES/DAP4/dap4-portals
ls apps/aios/packages/types/src/
cat apps/aios/packages/types/src/index.ts
```

Depois dispatch implementer pra Task 3.1 com escopo:
1. `git mv apps/aios/packages/types packages/types`
2. Atualizar `pnpm-workspace.yaml` (remover `apps/aios/packages/*` se virou redundante após move)
3. Reconciliar com plan original (adicionar Lead/User/Tenant/Kommo se ausentes, com TDD)
4. Atualizar todos imports em `apps/aios/client/` e `apps/aios/server/` (provavelmente nenhum muda — `@dap/types` continua resolvendo)
5. Commit + push

TaskList já tem Task #17 (`Task 3.1: Package @dap/types`) pending. Marcar in_progress quando começar.

## Setup / comandos úteis

```bash
# Entrar no monorepo
cd C:/THALES/DAP4/dap4-portals

# Ver workspace projects
pnpm ls -r --depth -1

# Build app específico
pnpm --filter @dap/operacao build

# Dev de cada app (portas reservadas)
pnpm dev:aios       # 5050
pnpm dev:operacao   # 5051
pnpm dev:gestao     # 5052

# Testar
pnpm -r test
pnpm --filter @dap/operacao test  # 117 testes verdes

# Estado git
git log --oneline | head -15
git remote -v
```

**TaskList pra retomar:**
```
#1-#16: completed (Fases 0+1+2)
#17 Task 3.1 @dap/types — pending (PRÓXIMO)
#18 Task 3.2 @dap/ui — pending
#19-#35: pending (Fases 3-8)
```

**Plano fonte:** `C:\THALES\DAP4\docs\superpowers\plans\2026-05-06-dap4-monorepo-migration.md`

**Memory atualizar (Task 7.3, ainda pendente):**
- `project_dap_portal_architecture.md` — refletir monorepo único + paths novos
- Nova entry: `project_autodiag_copilot.md` (extraído pra C:\THALES\)
- Atualizar `project_dap_tools_real.md` (estava errado — `apps/`/`autodiag/`/`DAP4.0/` nunca foram parte do repo)
