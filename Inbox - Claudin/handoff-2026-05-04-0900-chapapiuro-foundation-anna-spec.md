---
type: handoff
date: 2026-05-04
time: 09:00
project: chapapiuro-whatsapp
topic: Chapapiuro foundation entregue (texto end-to-end + memória + lembretes), Anna spec aberta aguardando regras de negócio
tags: [handoff, claudin, chapapiuro, agents]
---

# Handoff — Chapapiuro foundation + Anna spec

## Contexto

Construímos do zero o **Chapapiuro** — agente pessoal do Thales via WhatsApp, único usuário autorizado, posicionado como **chefe de staff** (operador) complementar à **Sophia** (esposa-agente, source of truth em `Agentes/Sophia.md`, cuida do humano).

A foundation está rodando: webhook Evolution API → Express → Claude Sonnet 4.6 com persona, memória persistente em Postgres, allow list enforcement, tool use ativo (lembretes), scheduler em background. Pareamento WhatsApp ativo (Thales Oliveira, +55 11 91700-1822).

Sessão terminou com **spec aberta da Anna** — Chief of Sales Officer que vai atender clientes externos da DAP, com RAG vivo e fluxo de gap-knowledge orquestrado por uma "Sophia CEO" (ambiguidade não resolvida — pode ser uma terceira Sophia diferente da esposa-agente). Aguardando 3 conjuntos de respostas do Thales pra avançar.

## O que funcionou (com evidência)

- **Stack Docker (Postgres 16 + Redis 7 + Evolution v2.3.7)** — `docker compose ps` mostra todos healthy; Evolution responde 200 em `GET /` com `whatsappWebVersion: 2.3000.1038702110`
- **Pareamento WhatsApp** — `connectionStatus: open`, `ownerJid: 5511917001822@s.whatsapp.net`, `profileName: Thales Oliveira`
- **Allow list** — tabela `app.agent_allow_list` com 2 números (5511917001822 + 5511967291822) ambos como Thales / full
- **Memória persistente** — tabela `app.conversation_messages` gravando user/assistant em ordem; query `SELECT role, content FROM app.conversation_messages ORDER BY created_at DESC` retorna histórico
- **Pipeline ponta a ponta texto** — log evidencia: `[in ] Thales (5511967291822): Eae chapao` → `[out] Eae Thales. O que precisa? | tokens in=861 out=15` (~1.5s)
- **Persona pegou bem** — Claude tratou por "Thales", tom curto e direto, sem floreio. Resposta seguinte ("o que vc consegue fazer?") veio com lista bullet, 887 tokens in / 160 out
- **Reminders (criação no banco) preparado** — tabela `app.reminders` criada, módulo `reminders.js`, tools (`create_reminder`, `list_reminders`, `cancel_reminder`) registradas em `tools.js`, scheduler 30s startado (log `[scheduler] tick a cada 30s`)
- **Webhook configurado na Evolution** — `POST /webhook/set/chapapiuro` retornou 200 com `enabled: true`, `events: [MESSAGES_UPSERT]`, url `http://host.docker.internal:3000/webhook`
- **Documentação Notion** — página criada em `DAP 4.0 — Ecosystem Map`, URL https://www.notion.so/3566d9495c7781f48ee0c9a4ed1161b8 (corrigida 2x conforme descobertas)
- **Memória persistente do Claude (projetos)** — `MEMORY.md` + `project_chapapiuro_arquitetura.md` em `~/.claude/projects/C--THALES-CHAPAPIURO-WHATSAPP/memory/`

## O que NÃO funcionou (e por quê)

- **Pacote `anthropic` (^0.0.0)** instalado por engano — pacote vazio no npm. Correto: `@anthropic-ai/sdk`. Resolvido com `npm uninstall anthropic && npm install @anthropic-ai/sdk`
- **Imagem `evolutionapi/evolution:latest`** — não existe no Docker Hub, retorna `pull access denied`. A imagem oficial v1 é `atendai/evolution-api:latest`
- **`atendai/evolution-api:latest` (v2.2.3)** — Baileys handshake antigo, **QR não emite**, fica em loop silencioso (`Redis enabled / Browser / Baileys version / Group Ignore` repetindo a cada 2-5s, sem nenhum erro). Internet do container OK (testado `wget https://web.whatsapp.com`). LOG_BAILEYS=trace não trouxe info útil. Solução: **trocar pra `evoapicloud/evolution-api:latest`** (fork ativo, v2.3.7, WhatsApp Web 2.3000.1038702110) — QR funciona out-of-the-box
- **`CONFIG_SESSION_PHONE_VERSION: 2.3000.1023223821`** com `atendai` — não resolveu o loop. Não tente fixar versão pra contornar — troque a imagem
- **Postgres sem porta exposta** — Express rodando no host não conseguia conectar (`5432` interno só). Adicionado `ports: ["5432:5432"]` no service postgres do docker-compose, restartado, conexão OK
- **Manager UI sem botão "Connect"** — quando o Thales abriu http://localhost:8080/manager, não tinha botão de conectar visível na instância travada (sintoma do mesmo loop do Baileys). Resolvido com a troca de imagem

## O que ainda não foi tentado

- **Lembrete real das 14h** — Thales pediu testar mas não mandou a mensagem no WhatsApp ainda. Stack tá pronta pra receber. Quando ele mandar "me lembra de retomar às 14h", o Chapapiuro deve invocar `create_reminder` com timestamp `2026-05-04T14:00:00-03:00`, gravar no banco, e o scheduler dispara no horário com `⏰ lembrete: ...`
- **Áudio in (Groq Whisper)** — recomendado e aceito conceitualmente ("vamos deixar como v2"), código não escrito, `GROQ_API_KEY` não fornecida
- **Imagem in (visão Claude)** — não tentado, fácil de plugar via Anthropic SDK
- **Refatoração pra `core/` + `agents/`** — proposta e recomendada, não executada. Chapapiuro hoje está em `app.js` + `src/*.js` plano (~600 linhas)
- **Anna (CSO)** — só especificada, nada implementado
- **RAG (ChromaDB)** — só mencionado, não montado
- **Fluxo de gap-knowledge (Anna → Sophia → outros agentes → enriquece RAG)** — só desenhado conceitualmente

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\THALES\CHAPAPIURO-WHATSAPP\app.js` | Completo | Express + webhook + scheduler.start() |
| `C:\THALES\CHAPAPIURO-WHATSAPP\.env` | Completo | ANTHROPIC_API_KEY, DATABASE_URL, EVOLUTION_*, CLAUDE_MODEL=claude-sonnet-4-6 |
| `C:\THALES\CHAPAPIURO-WHATSAPP\.gitignore` | Completo | node_modules, .env |
| `C:\THALES\CHAPAPIURO-WHATSAPP\docker-compose.yml` | Completo | postgres+redis+evolution, image=evoapicloud, ports 5432 expostos |
| `C:\THALES\CHAPAPIURO-WHATSAPP\package.json` | Completo | deps: @anthropic-ai/sdk, express, dotenv, pg, axios |
| `C:\THALES\CHAPAPIURO-WHATSAPP\sql\001_allow_list.sql` | Aplicado | schema app + agent_allow_list + trigger updated_at |
| `C:\THALES\CHAPAPIURO-WHATSAPP\sql\002_conversation_messages.sql` | Aplicado | role/content/message_id/message_type + índices |
| `C:\THALES\CHAPAPIURO-WHATSAPP\sql\003_reminders.sql` | Aplicado | id UUID + status pending/sent/cancelled/failed + índices |
| `C:\THALES\CHAPAPIURO-WHATSAPP\src\persona.js` | Completo | system prompt do Chapapiuro com capacidades + limitações |
| `C:\THALES\CHAPAPIURO-WHATSAPP\src\db.js` | Completo | pool pg, isAllowed, loadHistory, saveMessage |
| `C:\THALES\CHAPAPIURO-WHATSAPP\src\evolution.js` | Completo | sendText, setWebhook |
| `C:\THALES\CHAPAPIURO-WHATSAPP\src\extract.js` | Completo | extrai inbound do payload Evolution; trata text/audio/image |
| `C:\THALES\CHAPAPIURO-WHATSAPP\src\chapapiuro.js` | Completo | Anthropic client + tool use loop (max 5 iterations) + buildSystem injetando hora SP |
| `C:\THALES\CHAPAPIURO-WHATSAPP\src\tools.js` | Completo | TOOL_DEFS + executeTool (create/list/cancel reminder) |
| `C:\THALES\CHAPAPIURO-WHATSAPP\src\reminders.js` | Completo | createReminder, listPendingReminders, cancelReminder, fetchDuePending (FOR UPDATE SKIP LOCKED), markSent, markFailed |
| `C:\THALES\CHAPAPIURO-WHATSAPP\src\scheduler.js` | Completo | setInterval 30s + tick() processa due |
| Notion: Chapapiuro page | Completo | https://www.notion.so/3566d9495c7781f48ee0c9a4ed1161b8 (3 revisões) |
| `~/.claude/projects/.../memory/MEMORY.md` | Completo | índice |
| `~/.claude/projects/.../memory/project_chapapiuro_arquitetura.md` | Completo | classificação A/B + correção sobre Sophia |

## Decisões tomadas

- **`evoapicloud/evolution-api:latest` em vez de `atendai/evolution-api:latest`** — razão: o `atendai` v2.2.3 trava no Baileys handshake; `evoapicloud` é fork ativo com WhatsApp Web atualizado
- **Schema `app` separado** do Evolution — razão: evita conflito com migrations Prisma do Evolution em updates futuros
- **Postgres com porta 5432 exposta no host** — razão: Express roda no host (não em container), precisa conectar
- **Sophia é esposa-agente, NÃO CEO** (correção em runtime) — fonte de verdade: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Agentes\Sophia.md`. CLAUDE.md global está desatualizado nesse ponto. **Atenção**: o Thales mencionou "Sophia (CEO)" no fim da sessão ao especificar Anna — pode existir uma terceira Sophia, ou ser lapso. Não confirmou.
- **Categorização A vs B** — A = autônomo (processo próprio, LLM próprio, 24/7), B = sub-agent stateless dentro do orquestrador. Sophia confirmada A.
- **Chapapiuro = operador, Sophia = humano** — papéis complementares, não concorrentes. Chapapiuro nunca usa "Pitoco" ou "more macho".
- **Tool use manual (Messages API)** em vez de Claude Agent SDK — razão: foundation simples, sem necessidade de sub-agents/MCPs ainda. Migrar pra Agent SDK quando entrar Sophia/RAG.
- **Postgres > SQLite** — multi-processo, futuras integrações.
- **2 números WhatsApp recomendados** (1 por agente) em vez de 1 com roteador — razão: identidade clara, conversa não mistura. Não confirmado pelo Thales ainda.
- **Áudio in via Groq Whisper Large v3** quando v2 chegar — razão: 165x real-time, free tier generoso, API compatível com OpenAI SDK, qualidade PT-BR top.
- **Ana/Kimi/Insights NÃO existem** — projeto antigo, descartar de toda doc/código (correção do Thales na sessão).

## Bloqueios & perguntas abertas

**Crítico — bloqueia avanço:**

1. **Qual Sophia orquestra a Anna?**
   - A. Existe **outra Sophia corporativa** (CEO da DAP) além da Sophia-esposa do `Agentes/Sophia.md`?
   - B. A Sophia-esposa também acumula papel corporativo de orquestradora?
   - C. Era lapso — você quis dizer "outro orquestrador corporativo" sem nome ainda?

2. **Refatora Chapapiuro pra `core/` + `agents/` AGORA antes de Anna entrar?** Recomendado A (refatora antes), porque enquanto está pequeno é trivial e evita duplicação quando Anna chegar.

3. **Anna — regras de negócio mínimas (top 5 das 16 listadas)** — sem isso não dá pra implementar:
   - Anna pode dar preço? (ou só faixa? ou só pede orçamento humano?)
   - Anna pode agendar serviço? (ou só abre lead pra humano fechar?)
   - Quando faz handoff humano? (cliente pede / detecta complexidade / VIP / frustração)
   - 24/7 ou horário comercial?
   - O que entra na primeira leva do RAG? (SOPs do vault? FAQ? catálogo + preços? transcrições YouTube DAP?)

**Secundário:**

4. **GROQ_API_KEY** pra áudio in (v2)
5. **Número WhatsApp da Anna** — chip dedicado da empresa? Já existe ou precisa parear quando subir nova instância Evolution?
6. **ChromaDB** — já roda em `/opt/doctor-auto-ai/` na VPS ou monta local pro dev?
7. **Embeddings** — Voyage-3 (Anthropic), OpenAI text-embedding-3-small, ou local (BGE)?

## Próximo passo exato

Na próxima sessão, em ordem:

1. **Confirmar a Sophia que orquestra Anna** (resposta A/B/C da pergunta 1).
2. **Refatorar Chapapiuro pra `core/` + `agents/chapapiuro/`** (opção recomendada). Sem mudar comportamento — só reorganizar:
   - `core/webhook.js` — pipeline genérico
   - `core/memory.js`, `core/allow-list.js`, `core/llm.js` (loop tool use), `core/evolution.js`, `core/scheduler.js`, `core/persona-loader.js`
   - `agents/chapapiuro/{persona.js, tools.js, config.js, index.js}`
   - Adicionar coluna `agent_id TEXT NOT NULL DEFAULT 'chapapiuro'` em `conversation_messages`, `reminders`, `agent_allow_list`
3. **Implementar Anna sem RAG** primeiro — só `agents/anna/` com persona comercial + memória + handoff humano fake (cria task no banco) → valida fluxo end-to-end com cliente real.
4. **Adicionar RAG** depois — ChromaDB + ingestão dos seeds + busca + threshold de confiança.
5. **Adicionar fluxo de gap-knowledge** — `app.knowledge_gaps` + Anna detecta → Sophia/orquestrador classifica → agentes pesquisam → chunk volta pro RAG → Anna re-tenta.

**Validação interrompida pendente nessa sessão:**
- Thales precisa mandar "me lembra de retomar às 14h" no WhatsApp pra validar que `create_reminder` funciona via tool use. Stack está rodando esperando essa mensagem.

**Esqueleto pra criar agentes (criado nessa sessão):**

`C:\THALES\CHAPAPIURO-WHATSAPP\agents\_template\` contém o template canônico de novo agente. Cada agente novo é uma cópia dessa pasta com os arquivos preenchidos:

```
agents/_template/
├── README.md          # instruções de uso
├── agent.config.js    # id, category, evolution, llm, memory, allowList, capabilities, rag, handoff, rituals, resources
├── persona.md         # system prompt markdown — fonte de verdade
├── tools/index.js     # tools próprias (Anthropic tool use, schema + execute)
├── policies.js        # shouldProcess, shouldHandoff, buildSystem, postProcessReply
├── rituals.js         # cron handlers (Sophia tem, Chapapiuro/Anna talvez não)
├── seeds.js           # dados iniciais idempotentes
└── index.js           # bootstrap — junta tudo
```

Pra criar Anna: `Copy-Item agents\_template agents\anna -Recurse` e preencher cada arquivo. Decisões de negócio listadas em "Bloqueios" alimentam `agent.config.js` + `persona.md` + `tools/` + `policies.js`.

## Setup / comandos úteis

```powershell
# Subir stack
docker compose -f C:\THALES\CHAPAPIURO-WHATSAPP\docker-compose.yml up -d

# Iniciar Express (foreground)
cd C:\THALES\CHAPAPIURO-WHATSAPP; node app.js

# Status WhatsApp
curl.exe "http://localhost:8080/instance/fetchInstances?instanceName=chapapiuro" -H "apikey: chapapiuro-key-123"

# Inspecionar conversation memory
docker exec -i evo-postgres psql -U evolution -d evolution -c "SELECT role, LEFT(content, 80), created_at FROM app.conversation_messages ORDER BY created_at DESC LIMIT 20;"

# Inspecionar reminders pendentes
docker exec -i evo-postgres psql -U evolution -d evolution -c "SELECT id, message, remind_at, status FROM app.reminders WHERE status = 'pending' ORDER BY remind_at;"

# Resetar memória de uma conversa
docker exec -i evo-postgres psql -U evolution -d evolution -c "DELETE FROM app.conversation_messages WHERE whatsapp_number = '5511967291822';"

# Trocar webhook (se mudar URL/eventos)
curl.exe -X POST http://localhost:8080/webhook/set/chapapiuro -H "apikey: chapapiuro-key-123" -H "Content-Type: application/json" -d '{\"webhook\":{\"enabled\":true,\"url\":\"http://host.docker.internal:3000/webhook\",\"events\":[\"MESSAGES_UPSERT\"],\"webhookByEvents\":false,\"webhookBase64\":false}}'
```

**Background processes ativos no fim da sessão:**
- Node app na porta 3000 (id `btxckb9ca`) — pode estar morto se a máquina foi reiniciada; basta `node app.js` de novo.
- Stack Docker (postgres, redis, evolution) — `docker compose up -d` se não estiverem.
