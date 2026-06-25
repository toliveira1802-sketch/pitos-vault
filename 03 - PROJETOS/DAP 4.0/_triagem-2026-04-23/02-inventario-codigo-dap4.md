# Inventário de código — DAP4.0 monorepo
**Gerado:** 2026-04-23
**Branch atual:** `feat/parts-odin` (último commit `dac5375`, Odin Parts recognition)
**Escopo:** `C:\dev\dap4` — cutover RC1→prod 23/04

Legenda: ATIVO (em prod 23/04) · PAUSED (código existe, não ativado) · EXP (WIP/branch) · MORTO (detrito) · ? (precisa olho humano)

---

## 1. Árvore por módulo

### Root (C:\dev\dap4)
- **CLAUDE.md / FEATURE_MAP.md / META_SETUP_GUIDE.md** — [ATIVO] docs canônicos do repo
- **CHECKPOINT.md** — [?] snapshot 16/04, pode estar defasado pós-cutover
- **HANDOFF.md** — [?] handoff 09/04, provavelmente obsoleto
- **Makefile** — [ATIVO] `make dev/prod/prod-tunnel/logs/down/clean/restart`
- **docker-compose.yml / docker-compose.dev.yml** — [ATIVO] 5 serviços (chromadb, agents, gateway, dashboard, cloudflared)
- **.env / .env.example** — [ATIVO] secrets prod
- **.superpowers/** — [EXP] brainstorm dir, não commitado (aparece em `git status` untracked)
- **.claude/plan/** — [?] planos locais
- **dashboard-git/** — **[MORTO]** submodule órfão (git status: "modified content, untracked"). Contém `docker-compose.prod.yml` velho com `evolution-db` e `rag-service` standalone — infraestrutura substituída pela stack unificada. Último commit local `5f318d7` (RLS parliament), divergente do monorepo. **Candidato imediato a archive.**

### agents/ (FastAPI / Python 3.12) — backend canônico
- **main.py / conftest.py / pyproject.toml / pytest.ini** — [ATIVO]
- **agents/** (subpacote) — 5 agentes + shim
  - `ana.py` (340L) — [ATIVO] canônico, Anna sales/WhatsApp
  - `personal_0613b.py` (489L) — [ATIVO] canônico, agente pessoal + presidente externo Parliament
  - `sofia.py` (421L) — [MORTO-mas-retido] DeprecationWarning shim, remoção agendada "Rodada 1" pós-rename. Mantém log_sofia_action. **Candidato a archive após verificar callers**
  - `kimi.py` (449L) — [ATIVO] CRM agent
  - `thales.py` (390L) — [ATIVO] strategy/Obsidian
  - `insights.py` (504L) — [ATIVO] analytics
  - `base.py` / `status_parser.py` / `agent_bus.py` (0L!) — `agent_bus.py` vazio, [MORTO] resíduo
- **api/routes/** — 13 routes: agent_0613b, chat, health, ingest, insights, kimi, kommo_chat, kommo_sync, orchestrate, parliament, parts, rag, thales — [ATIVO]
- **parliament/** — [ATIVO] C-Level Hub completo: `directors.py`, `clevel_registry.py`, `voices.py`, `quorum_rules.py`, `synthesis.py`, `session_manager.py`, `archiver.py`, `tenant.py` + 13 tests green (13 directors seeded, migration 20260419_01 aplicada)
  - `parliament/prompts/` — 5 YAMLs (anna, francisco, pitoco, zoraide, president_synthesis)
  - `parliament/config/tenants/` — multi-tenant DAP
- **services/** — [ATIVO] llm_router, classifier, intent_classifier, scheduler, supabase_client, kommo_scraper, blog_generator, anna_guardrails (v1 novo), parliament_guards, parts_analyzer/repo/service (Odin novo), rtbm_loader
- **ingestion/** — [ATIVO] pipeline, chunker, PDF/audio/video/image/web/perplexity/kimi/crm loaders
- **rag/** — [ATIVO] chroma_client (8 collections study_*/ops_*), embeddings (text-embedding-3-small), retriever. **ops_* vazio em prod** (cf. memória 2026-04-19).
- **config/** — settings.py (Pydantic), prompts/, references/, rtbm/ — [ATIVO]
- **db/migrations/** — só 1 migration (`20260416_add_agent_name_to_sofia_actions.sql`) — [?] parte foi pra `supabase/migrations/` no root
- **scripts/** — [EXP] playground-anna.{py,html}, playground-anna-lite.py, serve-playground.py — scratch local, não rodam em prod. **Candidato a `scripts/_archive/` ou `.gitignore`**
- **tests/** — [ATIVO] 17+ testes incluindo test_personal_0613b, test_sofia_characterization (cobertura do shim), test_anna_chat_flow_smoke, test_parts_analyzer
- **SecondBrain/obsidian-sync/** — [ATIVO] volume Obsidian Second Brain (montado em Docker)
- **uploads/** — [ATIVO] volume runtime
- **__pycache__/ / .venv/** — [ATIVO] local-only, já no .gitignore

### gateway/ (Express 5 / TypeScript) — proxy + Socket.IO
- **src/index.ts** — [ATIVO] registra 20 routers
- **src/routes/** (20 arquivos):
  - ATIVOS 23/04: `chat`, `agent-0613b`, `insights`, `ingest`, `dashboard`, `webhook` (legacy), `rag`, `meta`, `meta-webhook`, `obsidian`, `kommo-sync`, `kommo-send`, `kommo-webhook`, `kimi`, `leads`, `parliament`, `parts`, `metrics`, `admin-anna`
  - `sofia.routes.ts` — [MORTO-mas-retido] espelha o shim Python, remover junto com sofia.py
  - `openclaw.routes.ts` — [?] OpenSquad/OpenClaw "in progress" no CLAUDE.md, squad absorção incompleta. Verificar se Thales ainda quer.
- **src/services/** — [ATIVO] pythonBridge (com Bearer auth obrigatório — cf. memória feedback), kommo.service, kommo-store.service, meta-whatsapp/messages/media services, realtime (Socket.IO), escalation, anna-result-handler, supabase, logger, auth, dailyNote
- **src/workers/** — [ATIVO] anna-inbox.worker + adapters, handoff-ttl.worker
- **src/repos/** — [ATIVO] anna-conversations.repo, anna-inbox.repo
- **src/middleware/ / stores/ / observability/ / config/** — [ATIVO]
- **migrations/** — [?] separado de `supabase/migrations/` root; checar duplicação
- **tests/ + vitest.config.ts** — [ATIVO]

### dashboard/ (React 18 / Vite 6 / Tailwind) — frontend
- **src/pages/** (13 páginas):
  - ATIVO: `Dashboard.jsx`, `SophiaHub.jsx` (cockpit 0613-B, 19/04), `Parliament.jsx`, `LeadCommandCenter.jsx`, `Leads.jsx`, `Agents.jsx`, `WhatsApp.jsx`, `WhatsappKommo.jsx`, `Ingestion.jsx`, `RagExplorer.jsx`, `SecondBrain.jsx`, `Logs.jsx`, `AILab.jsx`
  - `parts/` — [EXP] 7 telas Odin Parts (branch `feat/parts-odin`, ainda não em master): PartsHome, PartsScan, PartsResults, PartsHistory, PartsInventory, PartsDashboard, PartsAlerts
- **src/components/** — [ATIVO] Layout, PageHeader, MetricCard, DataTable, StatusBadge, EmptyState, CLevelRoom, LeadPipelineChart, TemplatePicker + subpastas `leads/` (8 comp), `parliament/` (7 comp)
- **src/lib/api.js** — [ATIVO] cliente com `personal0613b` canônico + alias `sofia` deprecated
- **src/hooks/** — `useApi.js`, `useRealtime.js` — [ATIVO]
- **src/test/setup.js + vitest.config.js** — [ATIVO]
- **nginx.conf.template / docker-entrypoint.d/** — [ATIVO] build de produção serve via nginx:80
- **~~dashboard/agents/~~** — **CLEANUP JÁ FEITO**. O CLAUDE.md ainda menciona o DEPRECATED.md mas a pasta não existe mais no working tree. Atualizar CLAUDE.md (ver dívida #4).

### Infra & tooling
- **supabase/migrations/** — [ATIVO] 7 migrations (Apr 16–23): anna_kommo_schema, kommo_tables_extend, fix_pipeline_seeds, anna_claim_rpc, parliament_clevel, parts_recognition_schema, crm_leads_framework_scoring
- **ops/** — [ATIVO] runbooks + deploy scripts: CLOUDFLARE_TUNNEL.md, GO_LIVE_RUNBOOK.md, HOSTINGER_PROVISION.md, OPS_RUNBOOK.md, deploy-kommo-rc1.sh, deploy.sh, env.production.template
- **docs/superpowers/{decisions,plans,specs,checkpoints,previews}/** — [ATIVO] ADRs (inclui 2026-04-16-0613b-external-presidency)
- **docs/runbooks/kommo-hub-rollout.md** — [ATIVO]
- **docs/kommo-api-shapes.md** — [ATIVO]
- **skills/** — [?] OpenSquad integration "in progress" no CLAUDE.md, complementa `squads/` (que não existe mais?) — precisa validação
- **tools/kommo-scraper/** — [EXP] TS scraper standalone (pnpm, esbuild, tsx) — uso pontual, não integrado ao fluxo prod
- **.github/workflows/ci.yml** — [ATIVO] CI: pytest backend, tsc gateway, test+build dashboard

---

## 2. Candidatos a `_archive/`

Priorizados por ROI da limpeza:

| # | Path | Tipo | Motivo |
|---|------|------|--------|
| 1 | `dashboard-git/` | dir inteira, ~6 MB + submodule | **Stale fork completo** — docker-compose.prod.yml antigo com `evolution-db` e `rag-service` separados; última evolução divergente (`5f318d7`). Polui `git status` toda hora ("modified content, untracked content"). Corta ruído visual e confusão mental. |
| 2 | `agents/agents/sofia.py` + `gateway/src/routes/sofia.routes.ts` + `test_sofia_characterization.py` + shim `log_sofia_action` no supabase_client | trio | Já marcado "Removal scheduled for Rodada 1". 0613-B absorveu tudo. Confirmar que nada em prod ainda chama `SofiaAgent` (grep já mostra shim só para callers legacy). |
| 3 | `agents/agents/agent_bus.py` | arquivo vazio (0 bytes) | Resíduo de abordagem abandonada. Deletar. |
| 4 | `agents/scripts/playground-anna*.{py,html}` + `serve-playground.py` | 4 arquivos | Playground local do Anna RTBM, não roda em prod. Ou move para `_archive/playground-anna/` ou adiciona ao `.gitignore` se ainda for usado localmente. |
| 5 | `CHECKPOINT.md` (16/04) + `HANDOFF.md` (09/04) | 2 MDs raiz | Pré-cutover. Mover para `docs/superpowers/checkpoints/`. |
| 6 | `gateway/src/routes/openclaw.routes.ts` + `skills/` root + menção a `squads/` no CLAUDE.md | módulo inteiro | OpenSquad absorção declarada "in progress" desde abril. Se Thales não pretende continuar, cortar. Senão, promover de "in progress" pra milestone clara. |
| 7 | `tools/kommo-scraper/` | dir com node_modules pesado | Utilitário isolado. Se ainda útil, manter; senão arquivar. **Rodar `rm -rf node_modules` no mínimo**. |
| 8 | `agents/db/migrations/` (1 arquivo) vs `supabase/migrations/` (7 arquivos) | duplicação | Consolidar em `supabase/migrations/` (fonte canônica) ou documentar a diferença. |

---

## 3. Dívidas técnicas detectadas

| # | Path | Problema | Severidade |
|---|------|----------|:---:|
| 1 | `dashboard-git/` submodule divergente | `git status` suja toda sessão com "modified content, untracked content". Bloqueia cleanliness checks e assusta auditor. | **ALTA** |
| 2 | `agents/agents/sofia.py` (421L) vivo | Shim DeprecationWarning em produção + `log_sofia_action` híbrido. Quanto mais tempo vive, mais código depende sem querer. | **ALTA** |
| 3 | `agents/db/migrations/` vs `supabase/migrations/` dois diretórios | Risco de migration rodar no lugar errado / dessync schema. | **ALTA** |
| 4 | `CLAUDE.md` linhas 9-13 falam de `dashboard/agents/DEPRECATED.md` que não existe mais | Doc mente. Onboarding novo agente se perde. | MÉDIA |
| 5 | `gateway/migrations/` coexistindo com `supabase/migrations/` | Mesmo problema de #3 em outro serviço. Verificar propósito. | MÉDIA |
| 6 | `agents/agents/agent_bus.py` (0 bytes) | Arquivo fantasma commitado. Sinal de resíduo. | BAIXA |
| 7 | `agents/scripts/playground-anna*` | Artefatos de iteração local commitados. Se sensíveis (keys hardcoded?), risco. Checar. | MÉDIA |
| 8 | `openclaw.routes.ts` + `skills/` + `squads/` (fantasma) | Feature "in progress" há semanas. Thales decide: matar ou priorizar. | MÉDIA |
| 9 | `ops_*` ChromaDB collections vazias em prod | Gargalo conhecido (memória 2026-04-19 `project_anna_workflow.md`). RAG operacional não foi populado no cutover. | **ALTA** |
| 10 | Branches locais `feat/anna-phase1a`, `feat/kommo-hub-phase1a`, `feat/parliament-thales-infra-fixes`, `rodada-0-foundation`, `feat/0613-b-rename` não mergeados nem remoted | Risco de perda de trabalho + confusão de "qual branch é verdade". Auditar e ou fechar PR ou deletar. | MÉDIA |

---

## 4. Pendências do cutover 23/04

| Item (memória) | Evidência no código | Status |
|---|---|---|
| **Caddyfile host=dir (pendência)** | `dashboard-git/Caddyfile` usa `reverse_proxy gateway:3001` (literal hostname Docker, host=dir style). **No entanto, este Caddyfile está em `dashboard-git/`, o fork órfão.** Não achei Caddyfile no working tree canônico (`/c/dev/dap4/`). | **CONFIRMADO PENDENTE** — Caddy de prod provavelmente vive só na VPS `/opt/doctor-auto-ai/`. Sincronizar para dentro do repo ou documentar onde mora. |
| **Anna paused** | `agents/agents/ana.py` (340L) existe + código `services/anna_guardrails.py` acabou de ser adicionado (commit `ae4bf16` "Anna guardrails v1"). Toggle via `parliament_subagents.active` (commit `5179f75` "kommo-chat honors parliament_subagents.active for ana"). | **CONFIRMADO** — código ATIVO, mas desativada via flag operacional no Supabase (`parliament_subagents.active=false`). Não é código morto, é feature toggle. |
| **RAG ops vazio em prod** | `agents/rag/chroma_client.py` define `ALL_COLLECTIONS = STUDY_COLLECTIONS + OPERATIONAL_COLLECTIONS`. Ingestors existem (`ingestion/crm_loader.py`, `ingestion/web_scraper.py`, etc.) mas não há cron/script dedicado a popular `ops_*`. | **CONFIRMADO PENDENTE** — falta pipeline de ingestion rodando para operacional. Cf. arquivo `15-rag-ops-ingestao.md` já presente nesta pasta de triagem. |
| **Parliament 13 directors no ar em DOCTOR_PRIME** | `agents/parliament/` completo, migration `20260419_01_parliament_clevel.sql`, seed `be2eb0c`, 13 tests verdes. | **OK** — deploy confirmado. |
| **Stack nova rodando** | `docker-compose.yml` v canônica (5 serviços), `ops/deploy.sh` + `deploy-kommo-rc1.sh` rodaram no cutover. | **OK** |
| **Phase 1a Anna solo WhatsApp** | `meta.routes.ts` + `meta-webhook.routes.ts` + `meta-whatsapp.service.ts` + `callPython("/agent/ana/chat")`. | **CÓDIGO PRONTO** — aguardando setup humano Meta Business (mencionado na memória). |

---

**Fim.** 396 linhas no total.
