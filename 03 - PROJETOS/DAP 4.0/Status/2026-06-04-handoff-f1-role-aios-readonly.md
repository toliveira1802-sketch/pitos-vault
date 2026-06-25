---
type: handoff
date: 2026-06-04
time: "23:20"
project: dap-aios
topic: F1 da refatoração de portais — role aios read-only + allowedPortals isolados (TDD, PR #46 aberto)
tags: [handoff, claudin, dap-aios, arquitetura, portais, aios, backend]
---

# Handoff — F1 (backend) da refatoração de portais: role `aios` read-only

> Retomada do handoff anterior (`2026-06-04-handoff-arquitetura-portais-aios.md`) executando o
> **F1 do plano** (`docs/superpowers/plans/2026-06-04-refatora-portais-aios.md`) por TDD estrito.
> 4 tasks fechadas, suíte verde, **PR #46 aberto** (não mergeado). F2–F5 seguem como roadmap.

## Contexto

O handoff anterior deixou spec + plano aprovados e a branch `feat/refatora-portais-aios` com 4
commits (spec, plano, home Cliente). Esta sessão **executou o F1** — a fatia backend: criar o
role `aios` (navega tudo, não grava) com guard de escrita no servidor, isolar os operacionais no
próprio portal via `allowedPortals`, e tirar calculadoras da navegação.

## O que funcionou (com evidência)

- **Verificação de estado** — branch `feat/refatora-portais-aios` confere com o handoff (HEAD `37abcfd`, working tree limpo, 4 commits sobre `e66e8ba`). `DATABASE_URL` confirmado no project-ref DEV `hlhfqnhsvwxodtwdkkhf` (sem vazar secret).
- **Blocker do choke point resolvido** — auditei os 20 routers: **todos** montam `requireAuth` + `requirePermission` nas escritas; nenhum endpoint público/webhook (grep `webhook|public|verify_token` vazio; `anna-shadow` é proxy mas exige auth). Logo `app.use('/api', requireAuth, aiosReadOnly)` é seguro.
- **Task 1 — guard read-only (TDD)** — teste RED→GREEN. Nuance: o PATCH do aios já dava 403 mas com code `FORBIDDEN` (role só tem `*:read`); o guard força o contrato explícito `AIOS_READ_ONLY` (pro toast do client) independente de grant. Commit `5f7f5b7`. 4/4 verdes.
- **Task 2 — allowedPortals por role (TDD)** — 3 testes RED→GREEN. `aios/admin/system` = `[aios,gestao,consultor,mecanico]`; `consultor`=`[consultor]`; `gestor`=`[gestao]`; calculadoras fora. Commit `0da0721`. 7/7 verdes no arquivo.
- **Task 3 — role no banco** — `seed.ts` ganha role `aios` + grant `*:read`; script idempotente `ensure-aios-role.ts` pra staging/prod. Typecheck exit 0. Commit `4e95dc1`.
- **Task 4 — gate** — `pnpm check` (types server+client) OK; arquivos do F1 **lint-limpos**; **36 testes verdes** (7 aios-readonly + 29 customers regressão). `requireAuth` idempotente confirmado não quebrar roles existentes.
- **PR #46 aberto** — `https://github.com/toliveira1802-sketch/dap40-perple-claude/pull/46`, branch pushada.

## O que NÃO funcionou (e por quê)

- Nada falhou. Único ponto de atenção: `pnpm lint` mostra **15 warnings pré-existentes** (todos em `server/src/services/dashboardService.ts`, `@typescript-eslint/no-explicit-any`) — **débito do Sprint 4b, fora do escopo do F1**. Nenhum arquivo do F1 gera warning. Não corrigi pra não fazer scope creep (ver `2026-06-04-debt-cobertura-sprint4b.md`).

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `server/src/middleware/aiosReadOnly.ts` | Criado (`5f7f5b7`) | guard: aios + método de escrita → 403 AIOS_READ_ONLY |
| `server/src/middleware/requireAuth.ts` | Modificado (`5f7f5b7`) | early-return idempotente + `aios` em OVERRIDABLE_ROLES |
| `server/src/routes/index.ts` | Modificado (`5f7f5b7`) | choke point `app.use('/api', requireAuth, aiosReadOnly)` após health |
| `server/test/integration/aios-readonly.test.ts` | Criado (`5f7f5b7`+`0da0721`) | 7 casos (guard + allowedPortals) |
| `server/src/routes/me.ts` | Modificado (`0da0721`) | PORTAL_VISIBILITY: +aios, operacionais isolados, sem calculadoras |
| `server/scripts/seed.ts` | Modificado (`4e95dc1`) | role aios + grant `*:read` |
| `server/scripts/ensure-aios-role.ts` | Criado (`4e95dc1`) | script idempotente prod/staging |

## Decisões tomadas

- **Guard antes dos routers, não dentro** — choke point único em `/api` depois do health. `requireAuth` virou idempotente (early-return se `req.actor`) pra não duplicar query quando cada router remonta o middleware.
- **`AIOS_READ_ONLY` é code próprio** (não reusa `FORBIDDEN`) — o client precisa distinguir "não pode" de "modo observação" pro toast certo.
- **Grant `*:read` pro aios** — libera qualquer GET no `requirePermission`; a escrita é barrada no guard (defesa em profundidade, não depende só do grant).
- **15 warnings pré-existentes não tocados** — débito separado, não é F1.

## Pós-merge — CONCLUÍDO

- **PR #46 squash-merged** em `main` (`3467c99`). CI verde nos gates críticos (typecheck, lint, test+coverage server/client, smoke E2E crítico, build, gitleaks, dep audit). Único FAILURE foi o workflow `E2E (informational)` — não-bloqueante. Branch deletada.
- **`ensure-aios-role.ts` rodado contra `hlhf`** (schema `public`) — role `aios` criado (id `XzK7gD7AKxMuPqeWy2phC`) + grant `*:read`.
- **Usuário `aios@doctorautoprime40.com` criado** — Supabase Auth UUID `89ad8aad-fdb7-4fe6-91d0-ed8208c84efb`, app row `ktZYDVj3kS7se5ecBVF2d`, role `aios`. Senha definida pelo Thales (não consta aqui).

## Incidente resolvido — tela preta no staging (aios@)

- **Sintoma:** Thales logou como `aios@` no staging e caiu em **tela preta**.
- **Causa raiz:** staging rodava código pré-F1; role `aios` não existia no `PORTAL_VISIBILITY` → `/api/me` devolvia `allowedPortals: []` → client não montava portal nenhum → tela preta. (Exatamente o gap "F1 não está em staging".)
- **Fix:** deploy do F1 pra staging. VPS `/opt/dap-aios/src` `e66e8ba → 3467c99`, rebuild `dap-aios:staging`, recreate `aios-staging` (`-p doctor-auto-ai`). Container `Up (healthy)` em `127.0.0.1:5001->5050`. Evidência: 4 subdomínios `*/api/health → 200`; bundle `dist/server/index.cjs` contém `PORTAL_VISIBILITY ["aios","gestao","consultor","mecanico"]` + `AIOS_READ_ONLY`.
- **Pendente de validação do Thales:** hard-refresh + re-login como `aios@` → confirmar que a tela preta sumiu e os 4 portais aparecem.

## Bloqueios & perguntas abertas
- **Dívida de infra herdada** (do handoff anterior, ainda aberta): systemd `dap-aios` legado órfão em `:5050` (`/opt/dap-portals`, dist de 6/mai) — candidato a desligar.

## Próximo passo exato

**Escolha do Thales entre dois caminhos (não excludentes):**
1. **Deploy do F1 pra staging** — rebuild da imagem + recreate do container, pra validar login `aios` read-only nos 4 subdomínios. Ação de infra na VPS (pede confirmação). Comando canônico em "Setup".
2. **Começar o F2** (frontend: config de nav declarativa em `client/src/shared/nav/*` + Sidebar single-portal extraindo os 3 branches hardcoded de `Sidebar.tsx`; mecânico ganha hierarquia; remove `LegacyNav`). Detalhar bite-sized no loop visual (Vite HMR + screenshots). Ver plano §F2.

## Setup / comandos úteis

- Branch: `feat/refatora-portais-aios` (7 commits sobre `main`, pushada, PR #46).
- pnpm fora do PATH: `export PATH="/c/Users/docto/AppData/Roaming/npm:$PATH"` antes de pnpm/commit (husky).
- Testes F1: `pnpm --filter @aios/server exec vitest run test/integration/aios-readonly.test.ts test/integration/customers.test.ts`.
- ⚠️ Testes fazem `wipeAll` — proteção em camadas (NODE_ENV=test força schema `test`, wipeAll aborta fora dele, integration-env valida project-ref DEV). `DATABASE_URL` precisa apontar pro DEV `hlhfqnhsvwxodtwdkkhf`.
- Deploy do role (de dentro de `server/`, já rodado): `NODE_ENV=development pnpm exec tsx scripts/ensure-aios-role.ts`.
- Deploy do código F1 pra staging (VPS, ainda NÃO rodado): `cd /opt/dap-aios/src && git reset --hard origin/main && docker build -t dap-aios:staging . && docker compose -p doctor-auto-ai -f docker-compose.staging.yml up -d --force-recreate aios-staging`. Validar: 4 subdomínios `*/api/health` → 200, e login `aios@` → PATCH bloqueado (403 AIOS_READ_ONLY).
