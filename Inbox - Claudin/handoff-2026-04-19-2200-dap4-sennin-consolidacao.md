---
title: Handoff — DAP4 sennin-consolidacao + kill-switch
date: 2026-04-19
time: 22:00
session: claude-opus-4-7-1m
bundle: index-Xy-QUG1r.js
url: https://dap.doctorautoprime40.com
branch: feat/kommo-prod-rc1
next_step: decidir guardrails Ana OU pipeline_id Prime + cron Davi
tags: [dap4, handoff, sennin-protocol, kill-switch]
---

# Handoff — 2026-04-19 22:00 (sessão consolidação UI + Sennin alignment)

Sessão de ~3h. Começou retomando `handoff-2026-04-19-1800-sessao-completa.md` com foco em design/funcionalidades. Fechou com UI inteira reformulada, Sennin Protocol espelhado no código, IAs em kill-switch.

**Bundle no ar:** `index-Xy-QUG1r.js` / Parliament `HfMdNPq_` / RagExplorer `5ygAMEFB`

---

## ✅ Entregues

### Telas reformuladas (10)

| Antes | Depois | Resumo |
|---|---|---|
| `/dashboard` | **Pulse** | KPIs reais, grid "Quem está ativo", breakdown classificação honesto (5.902/5.911 sem classif), feed live |
| `/command-center` | **Operação** | Rename — separa papel macro×operacional |
| `/leads` | `/leads` + **bloco Kommo** | 2 marcas (Bosch/Prime) × 4 canais (WA/FB/IG/TikTok) clicáveis + alerta integração pendente |
| `/agents` | **merged em /parliament** | redirect automático |
| `/ai-lab` | **merged em /parliament** | redirect; skill testing virou modal dentro do drawer do diretor |
| `/sophia` | `/sophia` | VoiceRail alinhada (Sophia = 0613-B) |
| `/parliament` | **C-Level hub** | Orbital 12 diretores Sennin + drawer com MCPs + 3 tabs (Subagentes/Crons/Skills) |
| `/knowledge` | **Vault** | Tab Collections removida (duplicava Cérebro) |
| `/rag` | **Cérebro** | Layout 3 colunas; ingestion absorvida; auto-default Alimentar quando vazio |
| `/ingestion` | **absorvido em /rag** | redirect `/ingestion` → `/rag?mode=ingest` |
| `/whatsapp` | + ChannelToggle Kommo/Meta/Ambos | |
| `/whatsapp-meta` | redirect | `/whatsapp?channel=meta` |
| `/logs` | PT-BR + sem mock fallback | Honesto vazio |

### Sennin Protocol alinhado (Fase 1+2)

- **Centro:** Sophia (0613-B) como External Presidency
- **12 diretores em órbita** com nomes, cargos, skills e MCPs do protocol:
  - Anna CSO Sales · Bianca CMO Marketing · Francisco CFO Finance · Marta CGO Growth · Rafael COO Operations · Claudio CTO Technology · Thamy CDO Design · Zoraide CCO Customer · Walter CKO Knowledge+Data · Pitoco CPO Product · Marcia CHRO People · Chapapiuro CSO Strategy
- **Hierarquia subagente → diretor:**
  - Ana (WhatsApp) ⇢ Anna CSO Sales
  - Kimi (CRM) ⇢ Rafael COO
  - Insights ⇢ Walter CKO
- Polish visual: drawer mostra MCPs em chips coloridos (ex: Rafael → ClickUp/Slack/Gmail/Google Calendar/GitHub)

### Bugs resolvidos

1. **Command Center quebrado** — `Object.values(null)` em LeadPipeline por null-vs-undefined no `useApi`. Fix defensivo no componente.
2. **Leads tabela vazia** — API `/dashboard/leads` retornava `{leads: [...]}` envelope; frontend esperava array direto. Normalização do shape + colunas alinhadas com DataTable (que passa só `row`).
3. **Agents invisível** — `h-full` em container sem altura definida colapsava SVG em zero. Trocado por `min(78vh, 760px)`.
4. **Anthropic key 401** — chave rotada **NOVA:** `sk-ant-api03-wp8Fll...Q-9VkY6gAA`. Descoberto que `docker compose restart` NÃO recarrega env_file — precisa `up -d --force-recreate`. Memory salva: `feedback_docker_env_reload.md`.
5. **Ingestão PDF falhando (dois bugs encadeados):**
   - Gateway não forwardava `Authorization: Bearer ${API_SECRET}` em `/ingest/file` (FastAPI HTTPBearer rejeitava com 401). Patch no `gateway/src/routes/ingest.routes.ts` e no `/app/dist/routes/ingest.routes.js` direto (container não tem tsc).
   - Frontend só mandava `file` + `collection`; Python exigia `title`, `source_type`, `target_rag`, `target_collection`. Fix em `FileDropIngest` (deriva `target_rag` do prefixo `ops_|study_`).
   - **Validado:** 1 doc ingerido em `ops_pricing_guidelines` (chunk_count: 1).
   - Memory salva: `feedback_gateway_python_auth.md`.

### Sidebar final (8 itens, 4 grupos)

```
DAP 4.0 · Command Center
├── OVERVIEW     Pulse · Operação · Leads
├── INTELLIGENCE Sophia Hub · Parliament · Vault · Cérebro
└── OPERATIONS   WhatsApp · Logs
```

Removidos: Agents, AI Lab, Ingestion, WhatsApp Meta (4 itens).

---

## 🛑 Estado atual — KILL SWITCH ATIVO

Thales ordenou ("Ana não pode passar preço, quero todas IA desligadas até liberar") em 2026-04-19 ~21:30. Estado:

- `python-agents` container: **Stopped**
- `.env.production` tem `AI_AUTOREPLY_ENABLED=false` (marcação permanente)
- Gateway/Caddy/ChromaDB/Dashboard frontend: rodando
- Cron Davi Gatuno: ainda ativo (scrape Kommo sem LLM — pendente decisão do Thales)

### O que NÃO funciona enquanto kill switch ativo

- Chat do Sophia Hub (0613-B speak)
- Chat do Vault (Pitoco Loco)
- Ana responder no WhatsApp Kommo
- Classificação automática de leads pela Ana
- Ingestão RAG via UI (endpoint Python desligado)
- Parliament: modal "Testar skill" retorna erro gracioso
- Pulse: "Agentes ativos: 0 / 5 online"

### Pra religar (1 comando)

```bash
ssh -i ~/.ssh/id_ed25519 root@76.13.170.42 '
  cd /opt/doctor-auto-ai
  sed -i "s/^AI_AUTOREPLY_ENABLED=.*/AI_AUTOREPLY_ENABLED=true/" .env.production
  docker compose -f docker-compose.prod.yml up -d --force-recreate python-agents
'
```

---

## 🔑 Credenciais sensíveis mencionadas nesta sessão

**Rotar em breve (expostas em chat):**
- `ANTHROPIC_API_KEY` nova: `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`
- `API_SECRET` do gateway (injetado pelo Caddy): `0aabd41eb717260aee1cced3f102ae709728761106e48616251fc8d9316dc5b0`

**Já conhecidos:**
- Pipeline Kommo Bosch: `12704980`
- Pipeline Kommo Prime: **pendente — Thales vai passar**

---

## 📋 Tasks abertas

### Humano
- **#27** — Religar IAs quando autorizar (decisão)
- **#25** — Ingestão RAG ops_* (bloqueada por #27)
- **#23** — Meta Cloud API setup (1-2h no Meta Business)
- **[novo]** Guardrails Ana — preencher template que será montado na retomada
- **[novo]** Decisão cron Davi Gatuno (mata ou mantém?)
- **[novo]** Pipeline_id Prime (me passar o número)
- **[opcional]** Rotar novamente `ANTHROPIC_API_KEY` (ficou no chat desta sessão)
- **[opcional]** Configurar SSH/PAT GitHub local pra push do branch

### Backend (próximas sessões)
- **#26** — Ana persistir `classification` em `crm_leads` após cada turno (~2h). Depende de guardrails pra saber quando marcar "escalated".
- **#21** — Kommo webhook popular `brand_id` + `source_name` (~2h). Depende do pipeline_id Prime.
- **#22** — Parliament backend completo: schema Supabase (directors/subagents/crons/skills) + rotas gateway + seed usando `DIRECTORS` do `CLevelRoom.jsx` (~4h).

### Bloqueada
- #13 (merge /agents em /parliament) — FEITO frontend, só backend do Parliament pendente (#22)

---

## 📝 Arquivos alterados (branch `feat/kommo-prod-rc1`)

### Dashboard frontend
```
dashboard/src/components/Layout.jsx           sidebar nav + logo "DAP 4.0"
dashboard/src/components/CLevelRoom.jsx       REESCRITO — 12 diretores Sennin
dashboard/src/components/leads/LeadPipeline.jsx  guard null
dashboard/src/pages/Dashboard.jsx             REESCRITO — Pulse com KPIs reais
dashboard/src/pages/Leads.jsx                 bloco Kommo + normalização
dashboard/src/pages/LeadCommandCenter.jsx     rename Operação
dashboard/src/pages/SophiaHub.jsx             nomenclatura Sophia
dashboard/src/pages/Parliament.jsx            REESCRITO — C-Level hub
dashboard/src/pages/RagExplorer.jsx           REESCRITO — Cérebro (3 colunas)
dashboard/src/pages/SecondBrain.jsx           Vault (tab Collections removida)
dashboard/src/pages/WhatsappKommo.jsx         ChannelToggle + MetaNotConfigured
dashboard/src/pages/Logs.jsx                  PT-BR + sem mock
dashboard/src/lib/api.js                      parliament.testSkill + fix ingestFile form
dashboard/src/main.jsx                        rotas + redirects
```

### Gateway
```
gateway/src/routes/ingest.routes.ts           Authorization Bearer pro Python em /file e /text
```

### VPS (patches diretos em prod)
```
/opt/doctor-auto-ai/.env.production           ANTHROPIC_API_KEY rotada + AI_AUTOREPLY_ENABLED=false
/opt/doctor-auto-ai/dashboard/dist/*          bundle Xy-QUG1r sincronizado
/app/dist/routes/ingest.routes.js (gateway)   patched (tsc não existe no container)
```

**Commits locais não pushados** (auth GitHub pendente). Branch `feat/kommo-prod-rc1`.

---

## 🧠 Memórias novas (Claude)

- `memory/feedback_docker_env_reload.md` — `restart` não recarrega env_file, usar `up -d --force-recreate`
- `memory/feedback_gateway_python_auth.md` — gateway→python sempre precisa Bearer (HTTPBearer FastAPI)

---

## 🎯 Próximo passo exato (retomada)

Thales disse "já voltamos". Quando voltar, **3 caminhos possíveis** em ordem de recomendação:

### 1. **Template de guardrails da Ana** (30 min do Thales)
Destrava religar IAs com segurança. Cláudio monta o doc com campos:
- O que Ana PODE falar (serviços, marcas, benefícios, agenda)
- O que NÃO PODE (preço é a 1ª confirmada; faltam outras)
- Quando escala (pedido de desconto? reclamação? fora de expediente?)
- Tom (formal/casual, emojis, assinatura)
- Respostas canônicas (primeira msg, fora de horário)

Serve de fundação pra #26 (persistir classification) + system prompt quando religar.

### 2. **Decisões rápidas (5 min cada)**
- Pipeline_id Prime no Kommo → destrava #21
- Mata cron Davi Gatuno? → consistente com kill switch
- Sim/não pra religar IAs agora?

### 3. **Outra sessão maior**
- #23 Meta setup (1-2h sozinho)
- #22 Parliament backend (4h comigo)

---

## 📊 Métricas da sessão

- 9 tarefas completadas, 6 tasks novas de backend abertas
- ~15 deploys incrementais
- 2 bugs críticos (ingestão PDF) resolvidos
- 1 kill switch ativado
- 0 leads novos entraram (sessão fim de sábado à noite)

---

## 🔗 Referências

- QA test checklist: `PITOS/Inbox - Claudin/qa-2026-04-19-dap4-frontend-validation.md`
- Sennin Protocol: `PITOS/Sistemas/sennin-protocol.md`
- Handoff anterior: `PITOS/Inbox - Claudin/handoff-2026-04-19-1800-sessao-completa.md`
- Meta setup: `C:/dev/dap4/META_SETUP_GUIDE.md`

---

**Retomada:** `/resume-handoff` — carrega este doc automaticamente.
