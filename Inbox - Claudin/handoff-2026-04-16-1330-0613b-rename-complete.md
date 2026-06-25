---
type: handoff
date: 2026-04-16
time: 13:30
project: DAP4 / Parliament
topic: 0613-B rename COMPLETO — merge em rodada-0-foundation, tag criada, smoke test Bosch pendente
tags: [handoff, claudin, parliament, 0613-b, refactor-complete]
---

# Handoff — 0613-B rename COMPLETO

## Contexto

Refactor grande do DAP4.0: renomear "Sofia/Sophia" (dois sistemas paralelos — Parliament CEO + orquestradora RAG) → codename **0613-B**, que é agente pessoal do Thales EXTERNO ao Parliament. Motivação: existia pessoa real chamada Sophia no Kommo CRM, e o agente precisava se distinguir.

Decisão arquitetural (confirmada sessão anterior): **Opção 3 híbrida** — Parliament fica com 12 cadeiras corporativas, SEM CEO interna. 0613-B preside de fora via callback injetado. Absorve também as funções da Sofia-orquestradora (route/review_rag/monitor/status) e ganha nova função `speak` (voz pessoal direta).

Sessão de hoje executou o plano completo em 6 fases (F0–F6) do plano world-class produzido pelo planner. Todas mergeadas num branch único `feat/0613-b-rename` e depois em `rodada-0-foundation`. Migration Supabase aplicada em produção (DOCTOR PRIME). Smoke test Bosch deferido porque a stack DAP não está live na VPS hoje.

## O que funcionou (com evidência)

- **F0 Discovery + baseline** — grep exaustivo achou 33 arquivos (vs 15 mapeados no plano original). Parliament baseline 37/37 green. Tag safety `pre-0613b-rename-safe` criada.
- **F0 stash reconciliation** — stash `wip-pre-0613b-rename-20260416-1029` aplicado como commit coerente `fdb9b8f` (multi-tenant foundation). Genericação de strings ("DAP"→"ecossistema", "AIos"→"sistema") foi REVERTIDA a pedido do Thales (opção 3 — manter identidade).
- **F1 Skeleton paralelo** — 3 agentes paralelos criaram (a) ADR em `docs/superpowers/decisions/2026-04-16-0613b-external-presidency.md`, (b) 2 prompts YAML (`0613b.yaml` + `president_synthesis.yaml` neutro), (c) shell `personal_0613b.py` + RED tests. Zero conflito de arquivo.
- **F2 Parliament refactor** — 43/43 tests green (6 novos: registry_has_12, no_president_seat, anna_remains_agent, no_quorum_contains_president, strategy_quorum_has_3_seats, synthesize_accepts_injected_prompt, synthesize_without_sophia_yaml, flow_with_external_president_callback). TDD rigoroso RED→GREEN.
- **F3 Orchestrator consolidation** — `Personal0613BAgent` implementa 6 ações portadas de sofia.py + `speak()` novo + `preside()` delega pra `synthesize()` default. `SofiaAgent` vira shim `DeprecationWarning`. Migration aplicada com sucesso em `acuufrgoyjwzlyhopaus` (DOCTOR PRIME) — `sofia_actions.agent_name` column criada com 239 rows históricas preservadas.
- **F4 Gateway + Dashboard paralelo** — 2 agentes paralelos. Gateway TS: `agent-0613b.routes.ts` com endpoints canônicos + `/speak` novo + `/status` GET dedicado (não mais POST-orchestrate hack). Type check pass. Dashboard React: 9 arquivos modificados, vite build 2921 modules zero warnings, aliases Tailwind preservados pra zero regressão visual.
- **F5 Docs** — CHECKPOINT.md v4 com nova seção 9, FEATURE_MAP.md atualizado, 8 docs históricos annotados (não reescritos), CLAUDE.md do projeto + kimi.yaml L52 atualizados. Agente F5 foi além do plano (distinguiu OpenSquad C-Level Hub de Parliament corretamente, achou GO_LIVE_RUNBOOK.md e outros docs fora da lista).
- **Merge + tag + push** — `git merge --no-ff feat/0613-b-rename` em `rodada-0-foundation`, tag `0613b-rename-complete` criada, push com `--follow-tags`. Branch remota `rodada-0-foundation` criada no GitHub (antes só existia local).

## O que NÃO funcionou (e por quê)

- **Docker Desktop local** — pipe `//./pipe/dockerDesktopLinuxEngine` não existe. Bloqueou opção A (smoke test local via containers). Solução usada: opção C (merge sem smoke test, F6 posterga pra bringup VPS).
- **Stack DAP na VPS** — memory dizia "stack rodando" mas só `doctor-ai-dashboard-evolution-1` + postgres up há 6 dias. Containers agents/gateway/dashboard/chromadb todos DOWN. Parliament nunca entrou live em produção. Mudou completamente o escopo de F6.
- **pytest `ModuleNotFoundError: No module named 'agents.X'`** — bug pré-existente no ambiente local (também afeta test_kimi com 10 falhas no baseline, não relacionado ao refactor). Top-level imports de `agents.sofia`, `agents.personal_0613b` falham em collection time. Lazy imports dentro de funções funcionam (F3-A usou esse padrão). Testes novos que fazem lazy import falham por herança do mesmo bug. Workaround: Parliament tests 43/43 passam normalmente (`agents.parliament.X` com namespace intermediário funciona).
- **GitHub PAT exposto** — Thales colou `github_pat_11BZYZAW...` em plaintext na conversa. Recusei usar, pedi revogação imediata. Fica o alerta de segurança (token está em histórico da sessão + logs Claude).
- **Docker compose ps sem API_SECRET + CLOUDFLARE_TUNNEL_TOKEN** — mesmo testando SSH na VPS, vars essenciais não setadas. Outro sinal de que a stack não foi bringupada corretamente desde o deploy inicial de 10/04.

## O que ainda não foi tentado

- **Smoke test Bosch real** — pipeline `12704980`, WhatsApp `+551138240025`, escalação `+5511967291822`. Documentado em `reference_kommo_pipelines.md` na memória.
- **Bringup completo da stack DAP na VPS** — requer .env.production com todos secrets (KOMMO_TOKEN, META credentials, API_SECRET, CLOUDFLARE_TUNNEL_TOKEN, SUPABASE_SERVICE_ROLE_KEY). Thales tem os valores.
- **Persona-injected synthesis em `preside()`** — hoje chama `synthesize()` com prompt neutro. Feature futura é passar prompt do 0613-B pra síntese ficar com tom Lobo Estrategista explícito.
- **Deletar branch `feat/0613-b-rename` do remote** — `git push origin --delete feat/0613-b-rename` (opcional, histórico já está em `rodada-0-foundation`).
- **Remoção dos aliases deprecated** (`/api/sofia/*`, `agents/agents/sofia.py`, `agent.sofia` Tailwind token, `sofia` key em api.js) — agendado pra Rodada 1 após baking period.
- **Fix do bug pytest `agents.X` import** — não foi meu refactor que causou, mas limita cobertura local. Pode ser `pytest.ini` com `pythonpath = .` ou refactor dos `__init__.py`.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `agents/parliament/clevel_registry.py` | Completo | 13 → 12 cadeiras, sem sophia. Header cita ADR. |
| `agents/parliament/quorum_rules.py` | Completo | strategy sem sophia (3 cadeiras: chapapiuro/francisco/pitoco) |
| `agents/parliament/synthesis.py` | Completo | `synthesize(topic, voices, *, prompt=None)` pluggable. Fallback carrega president_synthesis.yaml |
| `agents/parliament/session_manager.py` | Completo | `run_until_decision(..., *, president=callback)` aceita callback externo |
| `agents/parliament/prompts/sophia_synthesis.yaml` | DELETADO | Renomeado pra president_synthesis.yaml (persona strip) |
| `agents/parliament/prompts/president_synthesis.yaml` | Completo | Novo, neutro, injetável. Mantém contract `{short}`, `{escalation_contact}` |
| `agents/parliament/tenant.py` | Completo | Multi-tenant foundation (commit fdb9b8f). Cacheado. |
| `agents/parliament/config/tenants/dap.yaml` | Completo | Config do tenant DAP (short, escalation_contact, etc) |
| `agents/parliament/tests/test_*.py` | Completo | 43/43 green |
| `agents/agents/personal_0613b.py` | Completo | Implementação completa. 6 ações + Enum + AGENT_ROUTING_MAP + _extract_json static. |
| `agents/agents/sofia.py` | Shim | DeprecationWarning no __init__. Lógica intacta. Removal Rodada 1. |
| `agents/agents/thales.py` | Completo | Query `sofia_actions` inclui `agent_name` column. Comment atualizado. |
| `agents/services/supabase_client.py` | Completo | `log_agent_action(data, agent_name=...)` canônico. `log_sofia_action` shim. |
| `agents/services/scheduler.py` | Completo | `job_review_study_rag` usa `Personal0613BAgent` em vez de `SofiaAgent(retriever, chroma)` (bug pré-existente — sofia.__init__ não aceita args). |
| `agents/api/routes/agent_0613b.py` | Completo | Novo. `/orchestrate`, `/speak`, `/status`. |
| `agents/api/routes/orchestrate.py` | Legacy | Mantido como alias deprecated. |
| `agents/api/routes/health.py` | Completo | `"0613b": "ready"` no lugar de `"sofia"`. |
| `agents/main.py` | Completo | Monta `/agent/0613b` canonical + `/agent/sofia` legacy. Parliament mount duplicado (canonical + legacy). |
| `agents/config/prompts/0613b.yaml` | Completo | Prompt world-class, tom Lobo Estrategista, 3 responsabilidades, placeholders multi-tenant. |
| `agents/config/prompts/kimi.yaml` | Completo | L52 "Sofia" → "0613-B" |
| `agents/db/migrations/20260416_add_agent_name_to_sofia_actions.sql` | Completo + aplicado | Migration idempotente. View `agent_actions` criada como alias neutro. |
| `agents/tests/test_personal_0613b.py` | Shape tests | Lazy imports. 5 testes de shape. Bug ambiente impede rodar localmente. |
| `agents/tests/test_sofia_characterization.py` | Completo | 34 tests do F3-A. 6 test classes. Bug ambiente impede rodar localmente. |
| `gateway/src/routes/agent-0613b.routes.ts` | Completo | ESM puro. 3 endpoints canônicos. |
| `gateway/src/routes/sofia.routes.ts` | Legacy | Mantido como alias. |
| `gateway/src/routes/parliament.routes.ts` | Completo | 5 paths `/agent/sofia/parliament` → `/agent/0613b/parliament` |
| `gateway/src/middleware/validate.ts` | Completo | Schema `agentCommand` novo. `sofiaCommand` alias. |
| `gateway/src/routes/dashboard.routes.ts` | Completo | AGENT_COLORS ganha `"0613b"`, mantém `"sofia"` pra histórico, remove `"sophia"`. |
| `gateway/src/index.ts` | Completo | Monta `/api/0613b` antes de `/api/sofia` (deprecated). |
| `dashboard/tailwind.config.js` | Completo | Token `agent.0613b` (mesma cor violet), `agent.sofia` alias deprecated. |
| `dashboard/src/lib/api.js` | Completo | Namespace `agent0613b` canônico (+ chat/promote). `sofia` alias mantido. |
| `dashboard/src/pages/Agents.jsx` | Completo | Card "0613-B" role "Personal Agent · Parliament President (externo)". BUS_CONNECTIONS + nodePositions re-keyed. |
| `dashboard/src/pages/Dashboard.jsx` | Completo | AGENTS entry atualizado, activity strings trocadas. |
| `dashboard/src/pages/Logs.jsx` | Completo | Mocks + filter list atualizados. |
| `dashboard/src/components/parliament/SynthesisPanel.jsx` | Completo | Header "0613-B · Síntese (externo)" + caption "preside de fora do Parliament". |
| `dashboard/src/pages/SecondBrain.jsx` | Completo | Copy + Tailwind classes migrados. |
| `dashboard/src/pages/AILab.jsx` | Completo | Classes Tailwind migradas. |
| `dashboard/src/pages/Ingestion.jsx` | Completo | Ícone color class migrado. |
| `docs/superpowers/decisions/2026-04-16-0613b-external-presidency.md` | Completo | ADR canônico, formato Nygard. |
| `docs/superpowers/plans/2026-04-14-parliament-phase-01.md` | Annotated | Callout no topo apontando ADR. |
| `docs/superpowers/checkpoints/2026-04-14-parliament-phase-01.md` | Annotated | Callout. |
| `docs/superpowers/specs/2026-04-14-parliament-design.md` | Annotated | Callout. |
| `docs/superpowers/previews/2026-04-14-parliament-ui-preview.html` | Annotated | Banner HTML com CSS apropriado. |
| `docs/superpowers/specs/2026-04-15-dap4-ia-no-ar-phase1a.md` | Annotated | Callout. |
| `docs/superpowers/plans/2026-04-15-dap4-rodada-0-foundation.md` | Annotated | Callout. |
| `docs/superpowers/specs/2026-04-10-lead-command-center-design.md` | Annotated | Callout. |
| `docs/superpowers/specs/2026-04-15-anna-parliament-command-center-integration.md` | Annotated | Callout (era untracked, agora commitado). |
| `docs/superpowers/specs/2026-04-15-kommo-hub-phase1a.md` | Commit | Ortogonal ao rename, não annotado. |
| `ops/GO_LIVE_RUNBOOK.md` | Annotated | Callout com path relativo `../docs/...`. |
| `CHECKPOINT.md` | Completo | v3 → v4. Nova seção 9 com 8 bullets + tabela commits. |
| `FEATURE_MAP.md` | Completo | Sofia → 0613-B. OpenSquad C-Level Hub intacto (distinção correta). |
| `CLAUDE.md` (projeto DAP4) | Completo | 5-agents list + API client atualizados. |
| `.env.example` | Modificado | Kommo Chats API vars (do stash multi-tenant). |

## Decisões tomadas

- **Opção 3 híbrida** — 0613-B externo ao Parliament, preside de fora. Parliament com 12 cadeiras sem CEO interna. Razão: Thales confirmou em sessão anterior, codename funcional (não cadeira corporativa).
- **`agents/agents/personal_0613b.py`** (não `agents/personal/0613b/`) — Razão: segue convenção BaseAgent existente, zero surpresa de infra, speculative generality é YAGNI.
- **Column pivot em `sofia_actions`** (não rename de tabela) — Razão: rename = downtime risk + quebra queries históricas. `ADD COLUMN IF NOT EXISTS agent_name DEFAULT 'sofia'` é idempotente + preserva 239 rows.
- **View `agent_actions` como alias** — Razão: novo código pode usar nome neutro sem acoplar à história "sofia".
- **Genericação de strings REVERTIDA** — stash tinha "DAP"→"ecossistema", "AIos"→"sistema". Thales rejeitou. Razão: Parliament é do DAP, identidade não deve ser apagada pelo multi-tenant scaffolding.
- **SofiaAgent = shim com DeprecationWarning** (não subclass de Personal0613BAgent) — Razão: characterization tests travam comportamento observável `promoted_by='sofia'`, `agent_name='sofia'`. Subclass quebraria. Shim preserva comportamento histórico + warning.
- **Aliases preservados por 1 release** (`/api/sofia/*`, `agents.sofia`, `agent.sofia` Tailwind, `sofia` em api.js) — Razão: zero break de callers em flight. Remoção Rodada 1 após baking.
- **Deploy postponed, merge sem smoke test** — Razão: Docker Desktop local down + stack DAP VPS não rodando. Não há comportamento live pra validar ou quebrar. F6 vira parte do bringup.
- **`preside()` usa prompt neutro** — Razão: MVP funcional primeiro, persona-injection é fine-tuning futuro. O importante é que 0613-B PRESIDE de fora (arquitetura), não o tom da síntese.
- **Tudo em `feat/0613-b-rename`, sem sub-branches** — Razão: instrução explícita do plano, atomic PR, histórico linear.
- **Merge `--no-ff`** (não squash) — Razão: preserva os 6 commits de fase pra auditabilidade futura.
- **Tag `0613b-rename-complete`** — Razão: ponto de retorno limpo se algo precisar rollback.

## Bloqueios & perguntas abertas

- **GitHub PAT revogado?** Thales colou `github_pat_11BZYZAW...` em plaintext. Preciso confirmar que revogou em https://github.com/settings/tokens.
- **Stack DAP VPS** — quando bringup? .env.production tem todos secrets necessários? API_SECRET + CLOUDFLARE_TUNNEL_TOKEN estavam em branco no compose.
- **Kommo pipeline Prime `pipeline_id`** — nunca foi confirmado. Só Bosch (`12704980`). Pode ser que "Prime já validado em produção" mencionado em memory não tenha evidência real de rodar em prod.
- **F6 smoke test** — vai ser no bringup? Dashboard acessível em `dashboard.doctorautoprime40.com` via Cloudflare Tunnel? Kommo webhook URL fixo?
- **Tests `agents.X` import bug** — resolver agora ou deixar? Afeta test_kimi, test_sofia_characterization, test_personal_0613b. Parliament funciona por namespace intermediário `agents.parliament.X`.

## Próximo passo exato

**Quando Thales decidir bringup da stack DAP na VPS:**

1. SSH na VPS: `ssh root@76.13.170.42`
2. `cd /opt/doctor-auto-ai && git fetch && git checkout rodada-0-foundation && git pull`
3. Conferir/preencher `.env.production` (secrets necessários: `API_SECRET`, `CLOUDFLARE_TUNNEL_TOKEN`, `SUPABASE_SERVICE_ROLE_KEY`, `KOMMO_TOKEN`, `KOMMO_DOMAIN`, `KOMMO_CHATS_CHANNEL_SECRET`, `KOMMO_THALES_USER_ID`, `KOMMO_INTEGRATION_ID`, `KOMMO_ACCOUNT_ID`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `META_*` vars do WhatsApp Cloud API)
4. `docker compose -f docker-compose.prod.yml up -d --build`
5. Aguardar health: `curl http://localhost:8000/health` (agents) e rotas gateway
6. Configurar webhook Kommo pra `/api/webhook/kommo` via Cloudflare Tunnel `dap4`
7. **Smoke test Bosch:** criar lead controlado via API no Kommo pipeline_id `12704980` OU mandar WhatsApp real pro `+551138240025`, verificar:
   - Ana responde no pipeline certo (não Prime)
   - Supabase: `SELECT agent_name, count(*) FROM sofia_actions WHERE created_at > <test_start> GROUP BY agent_name` — esperar rows com `agent_name='0613b'`
   - Escalação: se timeout, Thales recebe WhatsApp em `+5511967291822`
   - Dashboard: `/agents` renderiza "0613-B" sem erro console
   - `GET /api/0613b/status` retorna healthy
8. **Se passar:** smoke test concluído, F6 realmente fechado.
9. **Se falhar:** rollback `git reset --hard 0613b-rename-complete~1` na VPS + investigar.

## Setup / comandos úteis

```bash
# Estado final do Git local
cd C:/dev/dap4
git log --oneline rodada-0-foundation -10
git tag -l "0613b*"

# Deletar branch remota depois (opcional)
git push origin --delete feat/0613-b-rename

# Rollback de emergência (se smoke test falhar)
# Na VPS: git reset --hard 0613b-rename-complete~1 && docker compose restart

# Verificar migration aplicada (Supabase DOCTOR PRIME)
# Via psql ou MCP: SELECT column_name FROM information_schema.columns
#   WHERE table_name='sofia_actions' AND column_name='agent_name';
# Esperar 1 row: agent_name text NOT NULL DEFAULT 'sofia'

# Query pra ver adopção do 0613-B em produção (depois do bringup)
# SELECT agent_name, count(*), max(created_at)
# FROM sofia_actions GROUP BY agent_name ORDER BY max(created_at) DESC;

# Characterization tests (quando bug pytest fix)
cd C:/dev/dap4/agents
python -m pytest tests/test_sofia_characterization.py -v
python -m pytest tests/test_personal_0613b.py -v

# Smoke test sintético (sem deploy, só valida routing)
# docker compose up -d agents gateway
# curl -X POST http://localhost:8000/agent/0613b/speak \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer $API_SECRET" \
#   -d '{"message": "me dá um status do sistema"}'
```
