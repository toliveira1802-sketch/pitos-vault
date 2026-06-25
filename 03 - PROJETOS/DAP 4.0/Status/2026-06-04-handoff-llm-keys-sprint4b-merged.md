---
title: Handoff — Chaves LLM religadas · KEY-INVENTORY · catálogo de agentes · Sprint 4b mergeado (deploy pendente)
date: 2026-06-04
status: handoff (retomada)
scope: prod LLM keys, PR #41 required check, KEY-INVENTORY fix, catálogo de agentes, Sprint 4b merge na main (deploy VPS pendente)
relacionado: "[[2026-06-04-handoff-merge40-camadaA-rotacao-chaves]] · [[2026-06-04-debt-cobertura-sprint4b]] · [[00-roster]]"
---

# Handoff — 2026-06-04 (sessão 2) · LLM keys + Sprint 4b mergeado

> Continuação de `2026-06-04-handoff-merge40-camadaA-rotacao-chaves`. Esta sessão fechou as
> pendências #1, #2, #3, #5 do handoff anterior e **mergeou o Sprint 4b na main (#42)** —
> mas o **deploy em prod foi deliberadamente adiado** pra janela dedicada (auth+migration+cross-repo, ~05:30 BRT).

## 1. Resumo executivo

5 frentes:
1. **🔴→✅ Chaves LLM repostas** — Anthropic + OpenAI novas no `/opt/doctor-auto-ai/.env`; agentes `dap4` saíram de DOWN (401) → operacionais. Produção religada.
2. **✅ PR #41 mergeado** (`bbef591`) + `Test client + coverage` virou required check. Bug do runbook (rollback) corrigido no caminho.
3. **✅ KEY-INVENTORY.md corrigido** — #8 (`hlhf` service_role) tinha locais do stack `dap4` que na real são `acuufrgo`; movidos pra #9. `hlhf` anon/service_role marcados rotacionados.
4. **✅ Catálogo de agentes** — criado `Ecossistema/DAP-AI/Agentes/` (roster + 15 notas). Canon de nomes cravado.
5. **✅→⏸️ Sprint 4b (#42) mergeado na main** (`d44f564`), **deploy VPS pendente** (próxima rodada).

## 2. O que foi executado

### 2.1 Chaves LLM (prod religada)
- Backup `/opt/doctor-auto-ai/.env.bak-pre-llm-2026-06-04`. Atualizadas L2 `ANTHROPIC_API_KEY` + L15 `OPENAI_API_KEY`.
- `compose up -d --force-recreate agents gateway`. Smoke: `/v1/models` Anthropic 200 + OpenAI 200; startup limpo (8 coleções RAG, scheduler 4 jobs, zero 401).
- ⚠️ As chaves passaram pelo chat — se quiser zero rastro, rotacionar de novo num momento tranquilo (estão funcionando).

### 2.2 PR #41 (Camada A)
- Mergeado `--admin` squash → `bbef591`. `Test client + coverage` adicionado aos required checks (9 contexts).
- Codex P2 válido no `RUNBOOK-DEPLOY.md`: backup da imagem vinha **depois** do `docker build` → rollback quebrado. Corrigido (backup antes do build, com guard `image inspect` pro 1º deploy).

### 2.3 KEY-INVENTORY.md
- `_secrets/KEY-INVENTORY.md`: #8 `hlhf` service_role — removidos locais do `dap4` (`/opt/doctor-auto-ai/.env`+prod, `dap4/.env`, `dap4/agents/.env`) que são `acuufrgo` → movidos pra #9. #7/#8 marcados rotacionados 2026-06-04. Nota de auditoria reescrita com mapeamento dos 2 projetos + incidente revertido.

### 2.4 Catálogo de agentes
- `Ecossistema/DAP-AI/Agentes/`: `00-roster.md` + 15 notas. **Canon Thales:** Anna (não Ana) · 0613-B (nº pessoal Thales) ≠ Sophia (CEO grupo) · Kimi/Insights a renomear.
- 7 notas fundamentadas (Anna, Sophia, 0613-B, Walter, Kimi, Insights, Thales-agente) + 8 stubs spec. README DAP-AI linkado. Memória `dap-agentes-canon` salva.

### 2.5 Sprint 4b — PR #42 (mergeado, deploy pendente)
- Branch `feat/ai-sprint4b-anna-shadow-ui` (27 commits) reintegrada com main via **merge** (squash final torna histórico irrelevante).
- **Decisões Thales:** deploy da branch inteira · gestão default → `/gestao/dashboard` (hub novo) · gate de cobertura baixado 65→62 (débito, ver [[2026-06-04-debt-cobertura-sprint4b]]).
- **Conflito** `portals.ts` resolvido (`/gestao/dashboard`) + `portals.test.ts` atualizado.
- **Fix de CI:** `ci.yml` não criava o schema `test` isolado que a branch exige → adicionado step `Mirror public → test schema`. Sem ele, guard `wipeAll` abortava (proteção contra truncar o banco do app).
- **5 lint errors** corrigidos (imports não-usados + assertion).
- **3 findings Codex resolvidos pré-merge** (commit `ffab3d5`):
  - **P1 `env.ts`**: `import.meta.url` vazio no bundle CJS → crash no startup. Fix CJS-safe (`typeof __dirname`).
  - **P1 `pendencias.ts`**: rota sem `requirePermission` → qualquer role lia OS/quotes. Add `requirePermission('service_orders','read')`.
  - **P2 `appointmentService`**: atomicidade chegou→OS — flagado como débito (fix = transação).
- Mergeado `--admin` squash → **`d44f564`**. CI: 9/9 bloqueantes verdes (`E2E Playwright` flake não-required).

## 3. Arquivos criados/alterados (sessão)

**dap-aios (na main via #41/#42):** `docs/RUNBOOK-DEPLOY.md` (fix rollback) · `.github/workflows/ci.yml` (step test-schema) · `client/src/auth/portals.{ts,test.ts}` · `server/src/env.ts` · `server/src/routes/pendencias.ts` · `server/src/services/appointmentService.ts` · `server/vitest.config.ts` (gate 62) · +124 arquivos do Sprint 4b (consultor/gestão/marketing/anna-shadow).

**Vault:** `Ecossistema/DAP-AI/Agentes/*` (16 notas) · `Ecossistema/DAP-AI/README.md` · `_secrets/KEY-INVENTORY.md` · `Status/2026-06-04-debt-cobertura-sprint4b.md`.

**VPS:** `/opt/doctor-auto-ai/.env` (chaves LLM novas) + backup.

## 4. Commits / PRs
- **PR #41** MERGED → `bbef591`. **PR #42** MERGED → `d44f564` (squash, 27 commits Sprint 4b).
- main: `d44f564` (Sprint 4b) → `bbef591` (#41) → `6cc30b6` (#40).

## 5. 🚀 PRÓXIMA RODADA — Deploy do Sprint 4b em prod (sessão dedicada)

> **main está à frente da VPS.** O Sprint 4b está em `d44f564` mas NÃO foi deployado.
> Migrations **aditivas** (CREATE TABLE `appointments` + `content_items` + FKs/índices) — rollback = drop das 2 tabelas.

**Sequência (seguir [[RUNBOOK-DEPLOY]]):**
1. **Snapshot do Supabase `hlhf`** (pré-migration).
2. VPS `dap-aios`: `cd /opt/dap-aios/src && git fetch && git reset --hard origin/main` → backup imagem (`docker tag dap-aios:staging dap-aios:staging-bak-$(date +%F)`) → `docker build -t dap-aios:staging .` → `cd /opt/doctor-auto-ai && docker compose up -d --force-recreate aios-staging`.
3. **Migrations:** `cd /opt/dap-aios/src && pnpm db:push` → verificar `appointments` + `content_items` criadas no `hlhf`.
4. **Smoke dap-aios:** 4 subdomínios 200 + **login** (mudou: validação JWT HMAC local — testar de verdade) + abrir gestão (deve cair em `/gestao/dashboard`) + criar appointment teste.
5. **Co-deploy `dap4` (cross-repo, obrigatório):** mergear `feat/ai-sprint4b-gateway-shadow-proxy` (`728cc30`, proxy `/api/anna/shadow/*`) → rebuild gateway/agents → validar endpoint. **Sem isso a fila de curadoria Anna bate 404.**
6. **Smoke cross-repo:** abrir `/aios/anna/shadow` e confirmar que a fila carrega (dap-aios → gateway dap4 → Python anna_shadow).

**Riscos do deploy:** mudança de auth toca login (smoke valida) · 124 arquivos numa tacada · warning benigno `import.meta`/cjs no build (não crasha — guard `typeof __dirname`).

## 6. Pendências (fora o deploy)
1. **Deploy Sprint 4b** (§5) — prioridade.
2. **Débito de teste Sprint 4b** ([[2026-06-04-debt-cobertura-sprint4b]]): cobrir dashboardService etc → voltar gate pra 65; transação no `updateAppointment`.
3. **Chaves LLM** — rotacionar de novo se quiser zero rastro do chat.
4. **Rotações restantes** (KEY-INVENTORY): service_role `acuufrgo` (#9, derruba dap4 — janela controlada), Postgres pwd, CF tunnel #26, sessions #22-25, senha Kommo #19. Depois deletar `KEYS.md`.
5. **Canon de agentes:** nome novo de Kimi/Insights; consolidar Walter vs Thales-agente.
6. **Limpar backups na VPS:** `.env.bak-pre-llm-*`, imagens `staging-bak-*`.

## 7. Coordenadas
- Repos: `C:\THALES\DAP4.0\dap-aios` (portais, `hlhf`) · `C:\THALES\DAP4.0\dap4` (dashboard IA, `acuufrgo`).
- VPS `root@76.13.170.42`: `aios-staging` (Caddy `:80`, 4 subdomínios) · stack `dap4` = `doctor-auto-ai-{agents,gateway,chromadb}`. Repo VPS portais: `/opt/dap-aios/src`. Compose: `/opt/doctor-auto-ai/docker-compose.yml`.
- Origin: `github.com/toliveira1802-sketch/dap40-perple-claude`. main @ `d44f564`.
- pnpm gotcha (Git Bash): `export PATH="/c/Users/docto/AppData/Roaming/npm:$PATH"` antes de pnpm/commit.

## 8. Paralelizável / subagentes
- Débito de teste (§6.2): 1 subagente por service (dashboardService, contentCalendarService, dap4Client).
- Sequencial/cuidado: deploy Sprint 4b, rotação `acuufrgo`, qualquer infra prod.
