# Handoff — 2026-04-19 (sessão completa)

**Duração:** ~2h30min. Início com "limpe o lixo e leve projetos até onde der sem me perguntar". Fim com DAP4.0 no ar em `https://dap.doctorautoprime40.com`.

---

## ✅ No ar agora

```
https://dap.doctorautoprime40.com → 200 OK, <title>Doctor AI — Command Center</title>
https://webhook.doctorautoprime40.com → já existia (pro webhook Kommo)
https://APP.doctorautoprime40.com     → já existia
```

Rota `/sophia` (Sophia Hub cockpit 0613-B) acessível. VPS healthy: caddy + gateway + python-agents + chromadb + evolution (todos `Up`).

---

## Entregas da sessão

### 1. Cleanup
- Home: 35 .py + 3 HTML + 10 misc → `C:\Users\docto\_archive\2026-04-19\`
- `C:\dev\`: hermes-agent, backups, Claude-Skill-Developmental-Coach → `_archive\`
- Preservados: `parliament-playground.html`, `sophia-playground.html` (design refs)

### 2. Parliament — testes
Estado: 59/103 → **103/103** passando.

Root cause descoberto: ambiguidade entre pytest e Docker sobre o que é o package `agents`. Fix:
- Deletado `/c/dev/dap4/conftest.py` (root)
- Deletado `/c/dev/dap4/agents/__init__.py`
- Mantido `pythonpath=.` em `agents/pytest.ini`

Com isso `agents.X` resolve pra `/c/dev/dap4/agents/agents/X.py` nos testes, idêntico a como o Docker resolve com WORKDIR=/app.

### 3. Sophia Hub (Command Center IA)
Nova página `/sophia` no dashboard DAP4. Cockpit 3 colunas:
- **VoiceRail** — 5 vozes (0613-B, Ana, Kimi, Thales, Insights) com status live + RAG collections
- **Conversation** — chat direto com 0613-B via `/api/0613b/speak`
- **SideRail** — ações rápidas (`status`, `review_rag`, `preside`), tópicos Parliament abertos

Arquivo: `dashboard/src/pages/SophiaHub.jsx` (~400 LOC, bundle 11 KB / 4 KB gzip). Rota lazy em `main.jsx`, nav em `Layout.jsx` (ícone Brain, grupo "Intelligence").

### 4. Deploy prod — completo
- Dashboard dist rsyncado pra VPS (caddy monta direto)
- Backend novo: `personal_0613b.py` + `sofia.py` shim + `0613b.yaml` + `agent_0613b.py` route + `log_agent_action` em `supabase_client.py`
- `main.py` patched pra importar + montar `agent_0613b_route` em `/agent/0613b`
- Gateway: `validate.ts` ganhou `agentCommand` schema, `agent-0613b.routes.ts` ganhou `/orchestrate` canônico, `index.ts` patched pra mount `/api/0613b`
- ChromaDB pinado em `0.5.23` (latest quebrou healthcheck — sem python3/curl no container)
- Compose trocado de `docker-compose.yml` (dev) pra `docker-compose.prod.yml` (prod real com caddy)
- Symlink `.env → .env.production`

### 5. Bug Ana chat — caçado e fixado em prod
2 bugs stack-ados em `chat.py`:

1. `AnaAgent(retriever)` → `TypeError: takes 1 positional argument but 2 were given` (Ana lazy-initia retriever)
2. `result["message"]` → `KeyError` (Ana emite `"response"`, não `"message"`)

Fix deployed + testado em prod. Ana respondeu com persona consultiva legítima: *"Oi! Entendo que você está curioso sobre o preço da revisão do BMW 320i..."*

### 6. `doctor-auto-prime/` — salvo do risco
60k LOC monorepo (apps consultor/gestao/mecanico, packages config/db, supabase/) estava sem `.git`. Inicializado git + commit inicial com 51 arquivos (node_modules ignorado). Sem vazamento de secrets — só `.env.example` presente.

### 7. Cloudflare Tunnel — public hostname configurado via Claude for Chrome
`dap.doctorautoprime40.com` → `http://localhost:80` no tunnel `dap4`. DNS propagado automaticamente pela Cloudflare.

---

## Workflow da Anna (documentado nesta sessão)

**Trigger:** cliente WhatsApp → Evolution API → Kommo → webhook → gateway

**Pipeline:**
1. Gateway `POST /api/kommo/webhook` valida HMAC, enfileira em `anna-inbox`
2. Worker chama `/api/chat/message` do python agents
3. `AnaAgent._handle_chat`: RAG retrieval → classify_intent → LLM (gpt-4o-mini) → extract signals → return `{"response", "intent", "signals", "rag_used"}`
4. Ana termina resposta com tag opaca `[STATUS: continuing|qualified|escalated:<motivo>]`
5. Status parser extrai tag, strip do texto antes de enviar pro cliente
6. Gateway roteia: `continuing` → Kommo envia; `qualified`/`escalated` → cria task Kommo + broadcast Socket.IO

**Multi-tenant:** `pipelineFor(lead.pipeline_id)` mapeia pra `bosch.md` ou `dap_prime.md`. RTBM (Real-Time Business Model) sobrescreve prompt por tenant.

**Persistência:** `ai_conversations`, `ai_messages`, `crm_leads`, `sofia_actions` (com coluna `agent_name`), `webhook_logs`.

**TTL:** `handoff-ttl.worker.ts` devolve handoff pra Ana se humano não pegar em X minutos.

---

## Gargalos conhecidos (pra próxima sessão)

1. **RAG `ops_*` está vazio em prod** — todas as 7 collections operacionais com `count:0`. Ana responde sem contexto. Precisa ingerir: manuais Bosch/alemães, fichas técnicas, histórico de OS, tabela de preços.
2. **ANTHROPIC_API_KEY inválida** — bloqueia `/speak` do 0613-B (Ana não usa, ela vai direto no OpenAI). Rotar em `console.anthropic.com` e atualizar `/opt/doctor-auto-ai/.env.production`.
3. **Meta WhatsApp NÃO configurado** — zero `META_*` env vars. Só a via Kommo/Evolution tá ativa. Pra ativar a 2ª linha (Ana Prime solo + escalação pro +55 11 96729-1822): 10 passos do `META_SETUP_GUIDE.md`. Subdomínio `webhook.doctorautoprime40.com` já tá no tunnel, só falta credenciais.
4. **Escalação "escalated" só via Socket.IO** — se teu dashboard tá fechado, perde o sinal. Deveria mandar WhatsApp pro teu pessoal. Depende de Meta linha ativa.
5. **Prompt Anna é estático por tenant** — não aprende das conversas convertidas em OS. Feedback loop pra RTBM é evolução futura.

---

## Commits locais `feat/kommo-prod-rc1`

```
8bbffb0 fix(ana-chat): unblock /api/chat/message in prod
683e00e fix(agents): align pytest with Docker runtime — remove outer __init__ + root conftest
bfd5be9 feat(sophia-hub): cockpit ao vivo do 0613-B (Command Center IA)
4313f86 fix(agents): green test suite — correct agents.* import paths + test env defaults
21b796e fix(ops): deploy script — correct service list + guard ahead-commit loss
7bbd3ab ops(deploy): phased rc1 deploy script for /opt/doctor-auto-ai + Caddy
```

**Não pushados** — auth GitHub local não setup. VPS já foi atualizada via SCP/tar direto (rebuild das imagens docker), então o que tá no ar reflete todas as 4 commits novas. Push pro GitHub é limpeza administrativa da próxima sessão.

---

## Estado do `doctor-auto-prime/`
- ✅ Git init + commit inicial (`6a94ef7`)
- ⚠️ Sem remote configurado — adicionar GitHub remote na próxima se quiser backup
- ⚠️ `apps/consultor/` aparece como submodule modificado — pode ter git aninhado, investigar

---

## Credenciais sensíveis mencionadas nesta sessão

- **Cloudflare Service Token** `cfat_NNOV...` — inútil pra API management (é um Service Token de Access, não API Token). Deletar se não usa.
- Token do tunnel (systemd) — rodando 1 semana, saudável.
- ANTHROPIC_API_KEY — **precisa rotar** (atual retorna 401).

---

## Próximas sessões

Prioridade sugerida (maior impacto / menor risco primeiro):

1. **Rotar ANTHROPIC_API_KEY** — destrava 0613-B speak/route/preside
2. **Ingestão RAG ops_*** — Ana ganha contexto real (manuais alemães, preços, procedimentos)
3. **Meta WhatsApp linha 2** — Ana solo + escalação pro pessoal Thales
4. **Push GitHub** — sincronizar branch feat/kommo-prod-rc1 com origin
5. **Feedback loop Anna → RTBM** — primeira iteração de aprendizado por tenant

Comando pra retomar: `/resume-handoff`
