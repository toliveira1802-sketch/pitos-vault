---
type: handoff
date: 2026-05-05
time: 17:45
project: ecossistema DAP 4.0 / agentes
topic: Walter (CKO) ativado no Parliament + Chapapiuro deployed em produção (WhatsApp live)
tags: [handoff, claudin, chapapiuro, walter, parliament, dap4]
---

# Handoff — Walter ativado + Chapapiuro no ar

## Contexto

A sessão começou com pergunta arquitetural do Thales: "como você é demandado pelo NotebookLM via agentes? Temos fluxos pra criar". Evoluiu rapidamente pra design completo da teia do ecossistema, ativação concreta do Walter (CKO) no Parliament em código, e deploy E2E do Chapapiuro (agente pessoal único do Thales) na VPS de produção. Termina com Chapapiuro vivo, respondendo Thales via WhatsApp em produção.

A teia agora tem 3 nós ligados (**Thales ↔ Chapapiuro ↔ Claude Sonnet 4.6**) e 1 cadeira de C-level acordada (**Walter no Parliament**). Falta plugar Sophia (gateway obrigatório) e os outros 11 cadeiras + RAG isolado.

Lições críticas registradas em memória persistente: nunca usar `docker inspect --format .Config.Env` em prod (vaza todos os secrets), Cloudflare Tunnel rotas precisam apontar pra `localhost:80` no host (não pra hostname Docker), e `docker compose restart` não recarrega env_file.

## O que funcionou (com evidência)

- **Walter (CKO) ativado no Parliament** — commit `b5ac40d` em DAP4 branch `feat/anna-shadow-mode`. Validação direta: 12 c-levels mantidos no registry, walter SKILL com `prompt_file="walter.yaml"`, formatação com tenant vars OK, Walter já presente em 5 quorums (campaign, pricing, unit_activation, nps_alert, reactivation) — destrava esses 5 fluxos que antes falhavam com "skill prompt não definido".
- **Framework world-class de prompt agentes** — 4400 palavras, 11 fontes, denso, salvo em `PITOS/DAP 4.0/Frameworks Operacionais/estrutura-prompt-agentes.md`. Subagent dedicado fez WebFetch das fontes top (Anthropic, OpenAI, Lilian Weng, LangGraph, CrewAI, ReAct, Reflexion, Generative Agents, Andrew Ng, OpenAI Agents SDK).
- **Spec Chapapiuro v1 canônico** — `PITOS/Sistemas/chapapiuro-design-v1.md` (12 seções, schemas SQL, decisões em aberto). 7 decisões fechadas com Thales nesta sessão.
- **Chapapiuro DEPLOYED em prod** — 4 containers saudáveis em `/opt/chapapiuro/` (postgres+redis+evolution+server), Postgres 3 migrations aplicadas (`app.agent_allow_list`, `app.conversation_messages`, `app.reminders`), Evolution API v2.3.7 pareado com WhatsApp `5511917001822`, allow-list com Thales `5511967291822`.
- **Smoke E2E funcional** — Thales mandou "oi" do `5511967291822`, Chapapiuro respondeu "Thales. O que precisa?" via Claude Sonnet 4.6 (1972 in / 12 out tokens). Persona seca, sem hedge, alinhada com spec. Mensagens persistidas em `app.conversation_messages`.
- **Rota pública** — `https://chapapiuro.doctorautoprime40.com` via Cloudflare Tunnel → Caddy:80 → chapapiuro-server:3000 (rotas legacy `dap.*` e `portal.*` continuam intactas).
- **Networks Docker corretas** — `chapapiuro_chapapiuro_internal` (privada) + `doctor-auto-ai_internal` (bridge externa pra Caddy alcançar).
- **Caddy patch + reload** — Caddyfile com bloco `@chapapiuro` validado (`Valid configuration`) e aplicado via `docker compose -f infra/docker-compose.prod.yml up -d --force-recreate --no-deps caddy` (admin off bloqueia reload via API).
- **5 secrets DAP rotacionados** — Anthropic, OpenAI, Kommo webhook, Supabase anon, Cloudflare tunnel token. DAP4 prod (gateway/caddy/agents) recriado e cloudflared restartado pós-rotação. Smoke `dap.*` e `portal.*` continuam 200.

## O que NÃO funcionou (e por quê)

- **NotebookLM CLI auth via Playwright headless** — Google revoga sessão em ~10min por detecção de bot agressiva (cookies `SIDCC`, `__Secure-1PSIDCC` rotacionam só com browser real). Pivotamos pra WebFetch direto pra a research do framework. Lição: NotebookLM CLI é frágil pra workflows longos, só serve pra ações curtas.
- **Chrome DevTools MCP pra logar no NotebookLM** — Google bloqueia OAuth em qualquer Chrome com flags de automation. Mesmo com Chrome MCP visível, login é rejeitado. Irrecuperável sem conta dedicada de serviço (sem 2FA/Advanced Protection) num VM.
- **Cloudflare Tunnel rota chapapiuro com URL `caddy:80`** — cloudflared roda no host (systemd), fora da network Docker, não resolve hostnames Docker. Erro de instrução minha — pedi pro Thales cadastrar `caddy:80` quando deveria ter sido `localhost:80` (igual `dap.*` e `portal.*`). Detectado quando POST externo retornou 502 enquanto interno funcionava. Corrigido editando rota no dashboard CF.
- **`docker inspect --format .Config.Env`** em containers DAP4 prod — vazou 5 secrets em texto puro na thread (Anthropic, OpenAI, Kommo, Supabase anon, Cloudflare token). Erro meu ao incluir filtro `.Config.Env` quando só queria info de network. Lição salva em `feedback_docker_inspect_env_leak.md`.
- **`docker compose restart caddy`** após editar Caddyfile — não recarrega env_file nem config nova. Tem que ser `up -d --force-recreate --no-deps`. Já documentado em memória `feedback_docker_env_reload`.
- **Reload Caddy via admin endpoint** — `docker exec dap4-caddy caddy reload` falhou com "connection refused 2019" porque `admin off` no Caddyfile (segurança). Solução: force-recreate via compose. ~5s downtime aceitável.
- **Tests pytest do Parliament em sessão** — config path `from agents.parliament.X` vs rootdir `agents/pytest.ini` conflita. Validei via script Python direto (sys.path manipulation) ao invés de mexer no pytest config alheio.
- **F-string Python com escape de aspas duplas** — primeiro tentativa de gerar QR base64 → PNG quebrou com `SyntaxError: unexpected character after line continuation character`. Substituí por concatenação string normal.

## O que ainda não foi tentado

- **Wire Chapapiuro ↔ Sophia (gateway obrigatório do spec)** — atualmente Chapapiuro chama Anthropic direto. Spec requer triangulação via Sophia (HTTP gateway pro DAP4) com `demand_ledger` registrando tudo.
- **Schema `demand_ledger` + `chapapiuro_reflections`** — SQL definido no spec mas não aplicado.
- **Telegram, Obsidian e Email canais** — só WhatsApp ativo. Plataforma multi-agent já suporta (server.js detecta `/webhook/:agentId` por canal), só falta integrar.
- **Reflexion pipeline** — cron semanal lendo `chapapiuro_reflections` pra ajustar prompt.
- **Tiers urgência T0/T1/T2/T3** — Sophia classifica, mas Sophia ainda nem está no caminho.
- **Briefing matinal (7h30) e noturno (21h00)** — cron + skills `manha`/`noite` existentes.
- **Memória pessoal vs profissional ISOLADA fisicamente** — hoje `app.conversation_messages` é unificado. Decisão #4 do spec exige dual database (`chapapiuro_personal` vs `chapapiuro_professional`). Risco de vazamento.
- **Walter Phase 2 (RAG dedicado)** — Walter SKILL responde via prompt apenas. Não consulta ChromaDB ainda.
- **Indexar `estrutura-prompt-agentes.md` no ChromaDB** — chunks `geral_*` pra Walter citar em runtime.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\dev\dap4\agents\parliament\prompts\walter.yaml` | Completo (commit b5ac40d) | Persona CKO, 5 análises por tópico, tom acadêmico-pragmático |
| `C:\dev\dap4\agents\parliament\clevel_registry.py` | Completo (commit b5ac40d) | Walter agora SKILL ativo com prompt_file |
| `C:\dev\dap4\agents\parliament\tests\test_clevel_registry.py` | Completo (commit b5ac40d) | Walter incluído em `test_phase1_skills_have_prompt_file` |
| `PITOS/DAP 4.0/Frameworks Operacionais/estrutura-prompt-agentes.md` | Completo | 4400 palavras, 11 fontes, fonte canônica de design de agentes DAP |
| `PITOS/Sistemas/chapapiuro-design-v1.md` | Completo (v1 fechado) | 12 seções, schemas SQL, 6 decisões em aberto na §11 |
| `~/.claude/projects/.../memory/project_walter_cko.md` | Completo | Memória persistente — Walter CKO + casa Parliament |
| `~/.claude/projects/.../memory/project_chapapiuro_personal_agent.md` | Completo | Memória — Chapapiuro spec + estado deploy + pendências |
| `~/.claude/projects/.../memory/feedback_docker_inspect_env_leak.md` | Completo | Lição: nunca expor `.Config.Env` em prod |
| `~/.claude/projects/.../memory/MEMORY.md` | Atualizado | Index com 3 entradas novas |
| VPS `/opt/chapapiuro/Dockerfile` | Completo | Node 22-alpine, healthcheck `/health` |
| VPS `/opt/chapapiuro/docker-compose.yml` | Completo | 4 services, 2 networks, sem ports publicados |
| VPS `/opt/chapapiuro/.env` | Criado (root:root, 600) | Postgres pass + Evolution key gerados; Anthropic key colada pelo Thales |
| VPS `/opt/chapapiuro/docker-compose.yml.original-backup` | Backup | Compose original local Windows preservado |
| VPS `/opt/doctor-auto-ai/infra/Caddyfile` | Modificado | Bloco `@chapapiuro host chapapiuro.doctorautoprime40.com` adicionado |
| VPS `/opt/doctor-auto-ai/infra/Caddyfile.bak.20260505-193326` | Backup | Caddyfile pré-mudança |
| Cloudflare Tunnel DAP4 (dashboard) | Atualizado | Rota `chapapiuro.doctorautoprime40.com → http://localhost:80` |
| 5 secrets DAP4 | Rotacionados | Anthropic, OpenAI, Kommo, Supabase anon, CF token — todos atualizados em `/opt/doctor-auto-ai/.env` e `/etc/cloudflared/.env` |

## Decisões tomadas

- **Walter = CKO oficial** — papel: cura/aprova/direciona conhecimento (4 caminhos A/B/C/D: ChromaDB, Vault, Hotmart, Social). Razão: alinhado com Sennin Protocol e papel deferred já existente no Parliament.
- **Walter mora no Parliament em código DAP4 (NÃO Dify)** — Sala do Conselho Dify foi arquivada em 23/04 e substituída pelo Parliament em código. Razão: stack ativa não é Dify, e ativar Walter no Parliament já existente custa zero infra nova.
- **Chapapiuro = agente pessoal ÚNICO do Thales** — NÃO é CSO Strategy (apesar do mapeamento Sala do Conselho Dify arquivada). Equivale ao "0613-B / Presidência externa" mencionado no `clevel_registry.py`. Razão: clarificação do Thales nesta sessão.
- **Sophia é gateway OBRIGATÓRIO** — toda demanda Thales→Chapapiuro→Sophia→C-level→demand_ledger→Chapapiuro→Thales. Sem atalho. Razão: auditoria total + memória institucional + cohesão entre diretores.
- **4 tiers urgência T0/T1/T2/T3** — Sophia classifica, Reflexion ajusta thresholds. Razão: evitar bombardeio do Thales sem silenciar o que importa.
- **Memória + RAG isolados pessoal vs profissional** — bases físicas separadas (Postgres dual database + ChromaDB collection prefix `personal_*` vs `prof_*`). Razão: zero possibilidade de cross-query (segurança real, não filtro lógico).
- **Tom Chapapiuro: informal, primeira pessoa, sem hedge, humor seco** — diferente do tom técnico dos C-levels. Razão: ele fala com o Thales como amigo de confiança que conhece a operação.
- **Chapapiuro proativo** — pode abordar sem ser pedido (briefing manhã/noite, alertas, lembretes), sempre via Sophia.
- **Multi-canal: WhatsApp + Telegram + Obsidian + Email** — contexto unificado por número/email/note_id.
- **Skill de aprender (Reflexion pattern)** — pergunta P/P no início, com tempo confidence cresce e perguntas reduzem.
- **Stack de hospedagem: VPS Hostinger 76.13.170.42** — mesma do DAP4. Razão: 24/7 sem PC ligado, mesmo cluster, custo zero.
- **Cloudflare Tunnel rota → `localhost:80`** (não hostname Docker) — cloudflared roda no host, não na network Docker.

## Bloqueios & perguntas abertas

- **Schema do `demand_ledger`**: vai morar no Postgres do Chapapiuro (`/opt/chapapiuro/`) ou no Postgres do DAP4 (Supabase DOCTOR_PRIME)? Argumentos: Chapapiuro é privado e simples (Postgres local); DAP4 é canônico (Sophia já lê de lá). Decisão pendente.
- **Endpoint HTTP do gateway DAP4 pro Sophia receber demandas** — `/sophia/intake` ainda não existe. Schema: `{request_id, intent, channel, raw_input, tenant}` → `{output, classified_to, demand_id, citations}`.
- **Decisões em aberto na §11 do spec Chapapiuro**: número WhatsApp dedicado vs misto (hoje compartilha `5511917001822` que era da Anna shadow), hard cap LLM mensal por tier, política LGPD aplicada a si, cripto em rest pra dados pessoais, modo férias, renomear repo (não é mais só WhatsApp).
- **Anna em shadow mode** (`AI_AUTOREPLY_ENABLED=false`) — Phase 1a IA pausada, NÃO foi reativada nesta sessão. O número `5511917001822` agora está pareado como Chapapiuro Evolution; quando a Anna voltar, decidir se ela pega outro número ou se Chapapiuro/Anna co-existem nessa linha (impossível tecnicamente — número Baileys ≠ número Meta WABA simultâneo).
- **Walter Phase 2 (RAG)** — Walter responde só via prompt. Não consulta ChromaDB. Phase 2 do Parliament prevê isso.
- **Smoke E2E real do Walter no Parliament** — só validei via script Python direto. Suite completa pytest esbarra em config path. Precisa rodar do jeito que o time roda.

## Próximo passo exato

**Wire Chapapiuro ↔ Sophia.**

1. No `C:\dev\dap4\gateway\src\routes\` criar arquivo `sophia-intake.routes.ts` com endpoint `POST /sophia/intake` que recebe `{intent, channel, raw_input, source_agent}` e retorna `{output, classified_to, demand_id}`.
2. Sophia (já existe em `agents/agents/sofia.py`) precisa de método `classify_and_dispatch(demand)` que: lê demand → infere `context` (personal|professional|mixed) com Haiku → escolhe diretor (ou council) → executa → registra em `demand_ledger`.
3. Schema `demand_ledger`: criar migration em `supabase/migrations/` (Supabase DOCTOR_PRIME — manter na fonte canônica).
4. No `/opt/chapapiuro/core/llm.js` substituir chamada Anthropic direta por chamada HTTP a `https://dap.doctorautoprime40.com/api/sophia/intake`.

Antes de codar, decidir 1 coisa pendente: schema `demand_ledger` no Supabase DOCTOR_PRIME (recomendado — Sophia consulta histórico) ou no Postgres do Chapapiuro (mais isolado, menos cross-system).

## Setup / comandos úteis

```bash
# SSH na VPS (Windows PowerShell)
ssh -i C:\Users\docto\.ssh\id_ed25519 root@76.13.170.42

# Logs Chapapiuro em tempo real
docker compose -f /opt/chapapiuro/docker-compose.yml logs server -f --tail=20

# Ver mensagens da conversa Thales↔Chapapiuro
docker compose -f /opt/chapapiuro/docker-compose.yml exec postgres \
  psql -U evolution -d evolution -c \
  "SELECT role, LEFT(content, 80), created_at FROM app.conversation_messages ORDER BY created_at DESC LIMIT 10;"

# Status pareamento WhatsApp
set -a; source /opt/chapapiuro/.env; set +a
EVO_IP=$(docker inspect chapapiuro-evolution --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | head -1)
curl -sS "http://${EVO_IP}:8080/instance/connectionState/chapapiuro" -H "apikey: ${EVOLUTION_API_KEY}" | python3 -m json.tool

# Gerar QR fresh (caso WhatsApp deslogue)
curl -sS "http://${EVO_IP}:8080/instance/connect/chapapiuro" -H "apikey: ${EVOLUTION_API_KEY}" > /tmp/qr.json
python3 -c "import json,base64; d=json.load(open('/tmp/qr.json')); b=d.get('base64',''); b=b.split(',',1)[1] if b.startswith('data:') else b; open('/tmp/qr.png','wb').write(base64.b64decode(b))"
# Depois scp /tmp/qr.png pra ver

# Reload Caddy DAP4 (force-recreate, NÃO restart — restart não recarrega env)
cd /opt/doctor-auto-ai && docker compose -f infra/docker-compose.prod.yml up -d --force-recreate --no-deps caddy

# Cloudflare Tunnel: rotas SEMPRE apontam pra localhost:80, NUNCA hostname Docker
# Dashboard: https://one.dash.cloudflare.com/ → Networks → Tunnels → DAP4 → Public Hostnames

# NUNCA: docker inspect --format ".Config.Env"  ← vaza secrets
# Use:    docker inspect --format "{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}"
```

**Validações Walter (sem rodar pytest):**
```bash
cd /c/dev/dap4 && python -c "
import sys; sys.path.insert(0, '.')
from agents.parliament.clevel_registry import get_clevel
w = get_clevel('walter')
print(w.kind, w.prompt_file)  # SKILL walter.yaml
"
```
