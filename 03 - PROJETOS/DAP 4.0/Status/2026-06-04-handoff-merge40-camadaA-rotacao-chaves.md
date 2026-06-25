---
title: Handoff — Merge #40, gestão :5003 aposentado, Camada A (PR #41), rotação de chaves
date: 2026-06-04
status: handoff (retomada)
scope: merge routing, decommission órfão, CI client+coverage, incidente rotação Supabase, chaves LLM pendentes, catálogo de agentes
relacionado: "[[00-TODOS-THALES]] · [[00-MAPA-ECOSSISTEMA]] · [[000-CANON]] · [[2026-06-04-handoff-portais-subdominios]]"
---

# Handoff — 2026-06-04 · Merge #40 + Camada A + rotação de chaves

> Continuação do handoff `2026-06-04-handoff-portais-subdominios`. Aquele parou no "PR #40 aguardando review". Esta rodada fechou #40, aposentou o `:5003`, entregou a Camada A em PR, e tratou a rotação de chaves (com um incidente revertido).

## 1. Resumo executivo

Quatro frentes:
1. **PR #40 (routing por subdomínio) mergeado** → `main` em `6cc30b6`; VPS resetada e alinhada.
2. **App órfão DAP Gestão `:5003` aposentado** (movido pra `/opt/_retired/`, reversível).
3. **Camada A entregue em PR #41** — vitest no client + coverage gate + job no CI + runbook de deploy. Todos os checks bloqueantes verdes. **Aguardando merge do Thales.**
4. **Rotação de chaves** — LLM (Anthropic/OpenAI/Perplexity) deletadas pelo Thales (**reposição pendente**); Supabase `hlhf` (JWT secret) rotacionado → **portais rebuildados, login religado**. Houve um **engano revertido** (deploy de chave no projeto errado).

## 2. O que foi implementado / executado

### 2.1 PR #40 — subdomain routing
- CI real verde (`E2E Playwright` fail = flake informacional conhecido; `Smoke E2E critical` passou).
- Thread P2 do Codex era **obsoleta** (apontava `portals.test.ts` que não existia no head) → resolvida.
- **Squash-merge** via `gh pr merge 40 --squash --admin --delete-branch` (branch protection exigia review; Thales aprovou verbalmente) → `6cc30b6`.
- VPS `/opt/dap-aios/src`: `git fetch && git reset --hard origin/main` (`0da664f`→`6cc30b6`). Drift de routing (`RouteGuard.tsx`+`portals.ts`) era exatamente o #40 → no-op funcional, container intacto. 4 portais seguem 200.

### 2.2 gestão :5003 aposentado
- Era `node /opt/dap-gestao/dist/index.cjs`, processo **órfão** (PPID 1, sem pm2/systemd/cron, 21 dias up). Caddy `@gestao` já apontava pro `aios-staging:5050` (não recebia tráfego). Código pushado em `github.com/toliveira1802-sketch/dap-gestao`.
- Ação: `kill` (SIGTERM) + `mv /opt/dap-gestao → /opt/_retired/dap-gestao-retired-2026-06-04`. `.env` preservado. Reversível.

### 2.3 Camada A — PR #41 (branch `feat/ci-client-vitest-coverage`)
- **vitest no client**: `vitest` + `@vitest/coverage-v8` + `jsdom` (2.1.9, alinhado ao server).
- `client/vitest.config.ts`: coverage v8, escopo inicial `src/auth` (routing+role override), threshold **90/85/90/90**.
- **23 testes**: `portals.test.ts` (16) + `roleOverride.test.ts` (7). Cobertura 98/93/100/98. O teste de `portals.ts` trava o invariante que escapou no #40 (`gestao → /gestao/comercial`).
- CI: job **`Test client + coverage`** (paralelo ao server, sem Postgres), adicionado ao `needs` do Build.
- Scripts root: `test:client`, `test:client:cov`, `test:all`.
- `vitest.config.ts` no `tsconfig` include do client (typed-lint); `client/coverage/` no `.gitignore`.
- **Runbook de deploy**: `dap-aios/docs/RUNBOOK-DEPLOY.md` (merge gate → VPS reset+build → migrations → smoke → rollback).

### 2.4 Rotação de chaves
- **LLM:** Thales deletou Anthropic/OpenAI/Perplexity. Impacto: agentes `dap4` (Ana=OpenAI, Kimi/0613-B/Thales=Anthropic, +embeddings RAG=OpenAI) → **401, DOWN**. Perplexity sem impacto em prod (web search usa Tavily). **Reposição pendente.**
- **Kommo:** Thales confirmou **OK** (rotacionado).
- **Supabase `hlhf` (DAP AIOS):** JWT secret rotacionado (há ~semanas; iat nova `1779029191` vs antiga `1768262988`). `main` já tinha a anon nova commitada no `.env.production`, **mas a imagem `aios-staging` nunca foi rebuildada** → bundle no ar tinha anon morta → **login dos portais quebrado silenciosamente**.
  - **Fix:** rebuild `dap-aios:staging` (anon nova assada via `.env.production`) + `compose up -d --force-recreate aios-staging`. Verificado: bundle servido tem `iat:1779029191`; `/auth/v1/token` aceita a anon (400 em creds fake, não 401); 4 portais 200.
- **⚠️ Incidente revertido:** atualizei `/opt/doctor-auto-ai/.env` com as chaves `hlhf` — **errado**, o stack `dap4` usa o **2º projeto `acuufrgo`** (não `hlhf`). Gerou "Invalid API key" no gateway. **Revertido** do backup `.env.bak.pre-jwt-rotation-2026-06-04`; gateway/agents healthy, sem erro. **Sem dano.**

## 3. Descoberta crítica — 2 projetos Supabase
- **`hlhfqnhsvwxodtwdkkhf` (DAP AIOS)** → usado pelos **portais `dap-aios`** (`VITE_SUPABASE_URL=hlhf`). **Este foi rotacionado.**
- **`acuufrgoyjwzlyhopaus` (2º projeto)** → usado pelo **stack `dap4`** (gateway/agents: `SUPABASE_URL=acuufr`). **NÃO rotacionado.**
- ❗ **`KEY-INVENTORY.md` #8 está ERRADO**: diz que `hlhf` service_role vive em `/opt/doctor-auto-ai/.env`, mas na real é `acuufrgo`. **Corrigir.**

## 4. Arquivos criados/alterados

**Criados (dap-aios, branch `feat/ci-client-vitest-coverage`):**
- `client/vitest.config.ts` · `client/src/auth/portals.test.ts` · `client/src/auth/roleOverride.test.ts` · `docs/RUNBOOK-DEPLOY.md`

**Alterados:** `.github/workflows/ci.yml` · `client/package.json` · `client/tsconfig.json` · `package.json` · `pnpm-lock.yaml` · `.gitignore`

**VPS:** `/opt/dap-aios/src/.env.production` (anon nova, já = origin/main) · `dap-aios:staging` rebuildado · `/opt/_retired/dap-gestao-retired-2026-06-04` (movido).

**Backups na VPS (limpar depois):** `dap-aios:staging-bak-pre-anon-rebuild` (imagem) · `/opt/doctor-auto-ai/.env.bak.pre-jwt-rotation-2026-06-04` · `/opt/dap-aios/src/.env.production.bak-2026-06-04`.

## 5. Commits / PRs
- **PR #40** MERGED → `6cc30b6` (squash).
- **PR #41** OPEN — `feat/ci-client-vitest-coverage` → main. 2 commits: `test(client): add vitest + coverage gate…` + `docs: add deploy runbook`. CI bloqueante verde.

## 6. Testes / build
- `pnpm check` (3 workspaces) ✅ · `pnpm lint` (0 warn) ✅ · `pnpm test:client:cov` (23/23, 98% cov) ✅ · `pnpm build` ✅
- CI #41: `Test client + coverage` pass, todos bloqueantes pass; `E2E Playwright` fail (informacional).

## 7. Como rodar / smoke
- Dentro de `C:\THALES\DAP4.0\dap-aios`: `export PATH="/c/Users/docto/AppData/Roaming/npm:$PATH"` antes de pnpm/commit.
- Smoke portais: `for h in consultor mecanico gestao aios; do curl -so /dev/null -w "$h %{http_code}\n" https://$h.doctorautoprime40.com; done` → 4×200.

## 8. Pendências (ordem sugerida)
1. **🔴 [Thales] Mandar chaves LLM novas** (`sk-ant-...` + `sk-proj-...`) → Claude atualiza `/opt/doctor-auto-ai/.env` (L2 ANTHROPIC, L15 OPENAI) + `compose up -d --force-recreate agents gateway` + smoke. **Único corte de produção aberto.**
2. **[Thales] Mergear PR #41** + marcar `Test client + coverage` como **required check** na branch protection.
3. **[Claude] Corrigir `KEY-INVENTORY.md`** — #8 é `acuufrgo`, não `hlhf`; marcar `hlhf` anon/service_role como rotacionados ✅.
4. **Rotações restantes** (KEY-INVENTORY): Supabase service_role/Postgres dos projetos certos, CF tunnel #26, session secrets #22-25, senha Kommo #19. Depois **deletar `KEYS.md`** do OneDrive/git (fonte do vazamento).
5. **Catálogo de agentes** — não existe no vault. Criar `Ecossistema/DAP-AI/Agentes/` (1 nota/agente + `00-roster.md`) reconciliando os 2 rosters conflitantes (ver §10).
6. **Deploy dos 30 commits** (`feat/ai-sprint4b-anna-shadow-ui`) — sessão dedicada; rebase pós-#40 (conflito `/gestao/dashboard` vs `/gestao/comercial`).

## 9. Riscos
- Agentes `dap4` **DOWN** até chaves LLM novas (pendência #1).
- `.env.bak`/imagens de backup na VPS guardam chaves antigas (já mortas pras LLM; `acuufrgo` ainda vivas) — limpar.
- `/opt/dap-aios/src/.env.production` editado = igual ao origin/main (sem drift tracked); futuro `reset --hard` mantém anon nova (já no main). OK.

## 10. Catálogo de agentes — estado atual (pra próxima rodada)
**Não há catálogo no vault.** Info espalhada: código `dap4`, `dap-aios/ARCHITECTURE.md`, `Frameworks Operacionais/{anna-guardrails,estrutura-prompt-agentes}.md`. O spec `agent-operating-environment-design.md` (Camada B) é sobre **agentes de dev (Claude Code)**, não os de negócio.

**2 rosters conflitantes (precisam de canon — Ana vs Anna, 0613-B vs Sophia):**
- **`dap4` (prod, 🔴 down):** Ana (vendas/WA, GPT-4o-mini) · Kimi (CRM, Sonnet) · 0613-B (pessoal+orquestrador+Parliament, Sonnet) · Thales (estratégia/Obsidian, Sonnet) · Insights (analytics, Claude).
- **`dap-aios` (🟡 spec/mock, só Sophia+Anna têm stub):** Sophia (CEO/orquestra) · Anna (vendas) · Rafael (operação) · Francisco (financeiro) · Bianca (marketing) · Zoraide (pós-venda) · Claudio (tech/segurança) · Marcia (pessoas) · Walter (dados) · Pitoco (produto) · Thamy (design).

Template proposto por agente: `nome · papel · unidade · modelo · canal · RAG/coleções · status · onde vive no código · guardrails · roadmap`. Fonte única pra dev + conteúdo (DAP Social/Ensina/Studio) + RAG.

## 11. Paralelizável / subagentes
- **Catálogo de agentes** (§10): fan-out possível (1 subagente por agente) após cravar o canon de nomes.
- **Descritivos das 12 unidades** (`Ecossistema/*/README.md`): paralelo, 1 subagente/unidade (do handoff anterior, segue pendente).
- **Sequencial/cuidado:** chaves LLM, deploy 30 commits, qualquer infra prod.

## 12. Coordenadas
- Repos: `C:\THALES\DAP4.0\dap-aios` (portais, `hlhf`) · `C:\THALES\DAP4.0\dap4` (dashboard IA, `acuufrgo`).
- VPS `root@76.13.170.42`: `aios-staging` (`:5001`→`:5050`, Caddy `:80`); stack `dap4` = `doctor-auto-ai-{agents,gateway,chromadb}`. Repo VPS portais: `/opt/dap-aios/src`. Compose: `/opt/doctor-auto-ai/docker-compose.yml`.
- Origin: `github.com/toliveira1802-sketch/dap40-perple-claude`.
- pnpm gotcha: `export PATH="/c/Users/docto/AppData/Roaming/npm:$PATH"`.
