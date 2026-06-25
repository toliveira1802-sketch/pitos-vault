---
title: Status — Sessão 2026-05-05 (Walter + Chapapiuro deploy)
date: 2026-05-05
type: status-snapshot
session_duration: ~6h
status: 3 entregas em prod, 1 milestone (Chapapiuro live)
notion_mirror: https://www.notion.so/3576d9495c7781deaefeedd411b33821
tags: [status, dap4, walter, chapapiuro, parliament, deploy]
---

# Status — Sessão 2026-05-05

**Data:** 2026-05-05 · **Sessão:** ~6h trabalho denso · **Status:** ✅ 3 entregas em prod, 1 milestone (Chapapiuro live)

> Mirror Notion: https://www.notion.so/3576d9495c7781deaefeedd411b33821 (sub-page de DAP40 - ECOSSISTEMA). Memória persistente em `~/.claude/.../memory/project_walter_cko.md` + `project_chapapiuro_personal_agent.md`.

---

## TL;DR

Dia começou perguntando "como demando o NotebookLM via agentes". Termina com:

1. **Walter (CKO) ativo no Parliament** — voz no quórum de 5 tipos de tópico. Antes era SKILL deferred sem prompt_file (falhava com "skill prompt não definido"); agora responde Sonnet 4.6 via `walter.yaml`.
2. **Framework world-class de prompt agentes** — 4400 palavras, 11 fontes (Anthropic, OpenAI, Lilian Weng, LangGraph, CrewAI, ReAct, Reflexion, Generative Agents, Andrew Ng, OpenAI Agents SDK). Fonte canônica de design de agentes DAP.
3. **Chapapiuro DEPLOYED em produção** — VPS Hostinger, 4 containers saudáveis, WhatsApp `5511917001822` pareado, smoke E2E funcional (Thales mandou "oi" → Sonnet 4.6 respondeu "Thales. O que precisa?").

A teia tem hoje 3 nós ligados: **Thales ↔ Chapapiuro ↔ Claude Sonnet 4.6**. Falta plugar Sophia (gateway obrigatório do spec) e o resto do conselho atrás dela.

---

## Walter (CKO) — ativado no Parliament

**Commit:** `b5ac40d` em `feat/anna-shadow-mode` (DAP4)

**Arquivos:**
- `agents/parliament/prompts/walter.yaml` (novo)
- `agents/parliament/clevel_registry.py` (Walter SKILL ativo + comentário deferred ajustado)
- `agents/parliament/tests/test_clevel_registry.py` (Walter incluído em `test_phase1_skills_have_prompt_file`)

**Persona Walter:** acadêmico-pragmático, citação obrigatória, 4 frases curtas, 5 análises por tópico (estado conhecimento DAP, risco de decidir sem evidência, fontes externas, RAG asset potential, knowledge gaps).

**Quóruns destravados:** `campaign`, `pricing`, `unit_activation`, `nps_alert`, `reactivation` (5 tipos de tópico no Parliament agora têm voz CKO).

**Validação direta:** 12 c-levels mantidos, `prompt_file="walter.yaml"`, formatação tenant vars OK, walter em 5 quorum_rules. Suite pytest completa esbarra em config path `agents/pytest.ini` — não tocada.

**Pendências Phase 2 Walter:**
- RAG dedicado (consultar ChromaDB nas votações)
- Indexar `estrutura-prompt-agentes.md` no ChromaDB (chunks `geral_*`)
- Wire Walter como gate de ingestão de conhecimento

---

## Framework canônico de prompt de agentes

**Path:** `PITOS/DAP 4.0/Frameworks Operacionais/estrutura-prompt-agentes.md`

**Conteúdo:** TL;DR + 8 seções (Identidade, Missão, Tools, Memória, Loop de decisão, Multi-agente, Output, Guardrails) + Aplicação prática DAP4 + Anti-patterns + Próximos passos + 11 fontes.

**Aplicação direta no DAP4:**
- Tabela síntese — Anna (CRO), Walter (CKO), Sophia (CEO) com missões, tools, memória, loop, multi-agent, guardrails
- Decision tree — workflow vs agent
- Schema YAML pra contratos A2A entre agentes
- 5 anti-patterns destilados (chatbot generalista, prompt-stuffing, falta de role separation, tool com contrato vago, pular workflow)

**Decisões pro Thales (seção 'Próximos passos' do framework):**
1. Formalizar contratos A2A Sophia↔Anna/Walter/Kimi em YAML
2. Schema canônico ChromaDB collections-per-tenant
3. Observability stack (OpenTelemetry → Supabase `agent_traces`)
4. Reflexion pipeline pra Anna
5. Decisão Anna v2 vs v3
6. Walter como gate de conhecimento

---

## Chapapiuro — agente pessoal LIVE

**Spec canônico:** `PITOS/Sistemas/chapapiuro-design-v1.md` (12 seções, schemas SQL, 6 decisões em aberto §11)

**Reframe importante:** Chapapiuro NÃO é CSO Strategy (apesar do mapeamento Sala do Conselho Dify arquivada em 23/04). É **agente pessoal único do Thales** — equivale ao "0613-B / Presidência externa" mencionado no `clevel_registry.py`. Cuida tanto da vida profissional (DAP) quanto pessoal (família, saúde, ideias).

### 7 decisões fechadas

| # | Decisão |
|---|---|
| 1 | Pergunta P/P no início, com tempo Reflexion reduz perguntas |
| 2 | **Sophia gateway obrigatório** — toda demanda Thales→Chapapiuro→Sophia→C-level→`demand_ledger`→Chapapiuro→Thales |
| 3 | 4 tiers urgência (T0/T1/T2/T3) — Sophia classifica |
| 4 | Memória + RAG **isolados fisicamente** pessoal vs profissional |
| 5 | Tom informal, primeira pessoa, sem hedge, humor seco |
| 6 | Proativo (briefing manhã/noite, alertas, lembretes) — sempre via Sophia |
| 7 | Multi-canal: WhatsApp + Telegram + Obsidian + Email |

### Stack em produção (VPS 76.13.170.42)

| Componente | Status |
|---|---|
| `/opt/chapapiuro/` | ✅ deployed |
| 4 containers (postgres + redis + evolution + server) | ✅ saudáveis |
| Network isolada `chapapiuro_internal` + bridge `doctor-auto-ai_internal` | ✅ |
| Rota pública `https://chapapiuro.doctorautoprime40.com` | ✅ Cloudflare → Caddy → server |
| WhatsApp pareado `5511917001822` (Evolution Baileys, instância `chapapiuro`) | ✅ |
| Allow-list Thales `5511967291822` (mode closed) | ✅ |
| Postgres migrations (3 tabelas: `agent_allow_list`, `conversation_messages`, `reminders`) | ✅ |
| Webhook MESSAGES_UPSERT em `/webhook/chapapiuro` | ✅ |
| LLM Claude Sonnet 4.6 | ✅ |
| **Smoke E2E** (Thales "oi" → "Thales. O que precisa?", 1972/12 tokens) | ✅ |

### Pendências Chapapiuro

1. Wire Chapapiuro ↔ Sophia (HTTP gateway DAP4) — endpoint `/sophia/intake`
2. Schema `demand_ledger` + `chapapiuro_reflections`
3. Telegram + Obsidian + Email canais
4. Reflexion pipeline (cron semanal)
5. Tiers urgência (regras Sophia T0/T1/T2/T3)
6. Briefing matinal/noturno automatizado
7. Memória pessoal vs profissional ISOLADA fisicamente (hoje `conversation_messages` é unificado)

### Decisões em aberto (§11 do spec)

- Número WhatsApp dedicado vs misto (hoje compartilha `5511917001822` que era da Anna shadow)
- Hard cap LLM mensal por tier
- Política LGPD aplicada a si
- Cripto em rest pra dados pessoais
- Modo férias (pausa proatividade)
- Renomear repo (não é mais só WhatsApp)

---

## Incidentes & lições

### 🔴 Vazamento de 5 secrets DAP — rotacionados

**Causa:** `docker inspect <container> --format "{{range .Config.Env}}{{println .}}{{end}}"` em containers prod expôs 5 secrets em texto puro na thread:

1. ANTHROPIC_API_KEY
2. OPENAI_API_KEY
3. KOMMO_WEBHOOK_SECRET
4. SUPABASE_ANON_KEY
5. Cloudflare Tunnel token

**Resolução:** Thales rotacionou todos. DAP4 prod recreated (gateway/caddy/agents) + `systemctl restart cloudflared`. Smoke `dap.*` e `portal.*` continuam 200.

**Lição registrada em memória:** `~/.claude/.../memory/feedback_docker_inspect_env_leak.md` — nunca usar `--format .Config.Env` em prod. Inspeção tem que ser cirúrgica (filtros específicos, nunca env). `systemctl status` também vaza args com `--token` em texto puro — usar `systemctl show -p ActiveState` quando só quer estado.

### Cloudflare Tunnel rota — `caddy:80` errado, `localhost:80` certo

**Causa:** instrução minha errada — pedi pra cadastrar URL `caddy:80` no dashboard CF. Cloudflared roda no host (systemd), fora da network Docker, não resolve hostnames Docker. Rotas `dap.*` e `portal.*` apontam pra `localhost:80` (correto).

**Detectado:** POST externo retornou 502 enquanto interno funcionava. Corrigido editando rota no dashboard Cloudflare.

### NotebookLM CLI auth — Google revoga sessão headless

Playwright headless do `notebooklm-py` é detectado pelo Google em ~10min, sessão é revogada. Pivotamos pra WebFetch direto pra a research do framework. **NotebookLM CLI só serve pra ações curtas** — operações longas (deep research, audio, video) morrem no meio. Chrome DevTools MCP também é bloqueado pelo OAuth Google.

### Caddy reload via admin endpoint — bloqueado por `admin off`

**Causa:** `admin off` no Caddyfile (segurança) impede reload via API.

**Solução:** force-recreate via compose (`docker compose -f infra/docker-compose.prod.yml up -d --force-recreate --no-deps caddy`). ~5s downtime aceitável.

---

## Próximo passo exato (próxima sessão)

**Wire Chapapiuro ↔ Sophia.**

1. No `C:\dev\dap4\gateway\src\routes\` criar `sophia-intake.routes.ts` com `POST /sophia/intake` recebendo `{intent, channel, raw_input, source_agent}` e retornando `{output, classified_to, demand_id}`.
2. Sophia (`agents/agents/sofia.py`) precisa de método `classify_and_dispatch(demand)`: lê demand → infere context (personal|professional|mixed) com Haiku → escolhe diretor (ou council) → executa → registra em `demand_ledger`.
3. Schema `demand_ledger`: criar migration em `supabase/migrations/` (Supabase DOCTOR_PRIME — manter na fonte canônica).
4. No `/opt/chapapiuro/core/llm.js` substituir chamada Anthropic direta por chamada HTTP a `https://dap.doctorautoprime40.com/api/sophia/intake`.

**Decisão pendente antes de codar:** schema `demand_ledger` no Supabase DOCTOR_PRIME (recomendado — Sophia consulta histórico) ou no Postgres do Chapapiuro (mais isolado, menos cross-system).

---

## Comandos úteis (operacional Chapapiuro)

```bash
# SSH VPS (Windows PowerShell)
ssh -i C:\Users\docto\.ssh\id_ed25519 root@76.13.170.42

# Logs em tempo real
docker compose -f /opt/chapapiuro/docker-compose.yml logs server -f --tail=20

# Mensagens da conversa
docker compose -f /opt/chapapiuro/docker-compose.yml exec postgres \
  psql -U evolution -d evolution -c \
  "SELECT role, LEFT(content, 80), created_at FROM app.conversation_messages ORDER BY created_at DESC LIMIT 10;"

# Status pareamento
set -a; source /opt/chapapiuro/.env; set +a
EVO_IP=$(docker inspect chapapiuro-evolution --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
curl -sS "http://${EVO_IP}:8080/instance/connectionState/chapapiuro" -H "apikey: ${EVOLUTION_API_KEY}"

# QR fresh (caso WhatsApp deslogue)
curl -sS "http://${EVO_IP}:8080/instance/connect/chapapiuro" -H "apikey: ${EVOLUTION_API_KEY}" > /tmp/qr.json

# Reload Caddy DAP4 (force-recreate, NÃO restart)
cd /opt/doctor-auto-ai && docker compose -f infra/docker-compose.prod.yml up -d --force-recreate --no-deps caddy
```

**Proibições aprendidas:**
- ❌ `docker inspect --format ".Config.Env"` em prod (vaza secrets)
- ❌ `docker compose restart caddy` pra recarregar env (não funciona)
- ❌ Cloudflare Tunnel apontar pra hostname Docker (cloudflared no host não resolve)
- ❌ NotebookLM CLI pra operações >10min (sessão Google revoga)

---

## Documentos relacionados

- [DAP 4.0 — Ecosystem Map](https://www.notion.so/34b6d9495c778175b1dafa86608e6ae8) (Notion parent)
- [Chapapiuro — Chief of Staff Pessoal](https://www.notion.so/3566d9495c7781f48ee0c9a4ed1161b8) — página antiga (status 2026-05-04, MVP local, antes do deploy VPS de hoje)
- Spec canônico: `PITOS/Sistemas/chapapiuro-design-v1.md`
- Framework: `PITOS/DAP 4.0/Frameworks Operacionais/estrutura-prompt-agentes.md`
- Handoff sessão: `PITOS/Inbox - Claudin/handoff-2026-05-05-1745-chapapiuro-walter-deploy.md`

---

*Snapshot canônico — quando Chapapiuro completar Wire Sophia, próximo Status documenta a teia fechada.*
