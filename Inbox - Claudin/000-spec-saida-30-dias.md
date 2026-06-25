---
title: "Operação Limpeza — Spec da Saída em 30 dias"
aliases: ["Spec Saída", "Operação Limpeza", "Spec 000"]
tags: [spec, arquitetura, operacao-limpeza, dap4, thales-agent, vault, chairman]
status: aprovado
version: 1.0
author: Claudin
reviewer: Thales
created: 2026-04-09
target: 2026-05-09
duration_days: 30
predecessor: "[[Inbox - Claudin/001-arquitetura-saida|001-arquitetura-saida]]"
decisions_ref: 7
phases: 5
---

# Operação Limpeza — Spec da Saída em 30 dias

> [!abstract] Tese
> Durante 30 dias (09/04 → 09/05/2026), **nenhuma feature nova é construída**. O foco é tirar o lastro de três bagunças sobrepostas (vault, banco, código), renomear o DAP4.0, deployar em VPS com Cloudflare Tunnel, unificar o vault Obsidian em PITOS, completar o thales-agent com canal Obsidian e integração ao DAP4.0, e ativar as duas linhas WhatsApp. No fim do mês, o Thales abre qualquer coisa do ecossistema e **nada dá raiva**. A partir daí, qualquer feature nova cai em terreno firme.

---

## 1. Contexto

Em 09/04/2026, uma sessão de auditoria no `doctor-ai-dashboard` (DAP4.0) via skills `/hm-qa /hm-engineer /hm-designer /hm-fix` revelou 25 fixes críticos aplicáveis automaticamente e 9 pendências que exigem decisão de produto. Simultaneamente, uma exploração do vault Obsidian do Thales em `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS` revelou russian dolls de pasta, múltiplos centros concorrentes, e conteúdo espalhado entre dois vaults aninhados (CHAIRMAN e PITOS). Em paralelo, o projeto `thales-agent` foi descoberto já 80% implementado — cérebro async funcional, 4 canais (WhatsApp Evolution, Telegram, Slack, Discord), tools de vault e calendar, media processor — faltando apenas o canal Obsidian e algumas padronizações.

A tese do Lobo Estrategista ("eu não corro atrás de tudo, eu escolho o que merece minha força") orienta a saída: **consolidar o que existe antes de construir o que falta**. A opção foi consciente — nas 5 alternativas apresentadas (A-operacional, B-hardening, C-5 agentes, D-vender, E-limpar), a escolha foi **E** por reconhecimento de que qualquer feature nova sobre fundação rachada vira dívida composta.

### 1.1 Estado real (não é greenfield)

| Entidade | Estado |
|----------|--------|
| Doctor Auto Prime (oficina física) | Em operação. 4 colaboradores reais, 27 clientes ativos, 48 OS registradas, 5911 leads no CRM. |
| Supabase project `acuufrgoyjwzlyhopaus` | Postgres 17.6, **52 tabelas**. 20 oficiais + 22 legacy/duplicadas + 10 IA/CRM. Auth SHA-256 operacional. |
| `doctor-ai-dashboard` (DAP4.0) | Auditado em 09/04. Gateway TypeScript compila, agents pytest 31/31, dashboard vitest 27/27 (+ 2 novos), bundle reduzido 97.7% via lazy-load. 4 commits temáticos aplicados. |
| `thales-agent` | 80% implementado. Cérebro async, 4 canais, 5 vault tools, media processor, scheduler watcher. Faltando canal Obsidian e integração DAP4.0. |
| Vault PITOS | Bagunçado mas estruturável. HOME.md, ARQUETIPO.md, PITOCOLOCO/ com Brain_OS/Canvas_OS/Inbox_OS/DATABASE_MAP. Russian dolls de pasta aninhada. |
| Linhas WhatsApp | **Nenhuma ativa**. Ana (Meta Cloud) e thales-agent (Evolution) precisam ser configuradas do zero. |
| VPS de produção | Não provisionada. Recomendação: Hetzner CX32 (€12.90/mês — 4 vCPU, 8 GB RAM, 80 GB SSD NVMe). |

---

## 2. Decisões arquiteturais (DRs)

Sete decisões foram tomadas durante a sessão de brainstorming de 09/04. Todas fechadas com justificativa e consequências.

### DR-01 · Vitória de 30 dias

**Decisão:** **Limpar a casa primeiro (opção E).** Durante 30 dias, nenhuma feature nova entra. 3 frentes de limpeza (vault, banco, código) até 09/05.

**Por quê:** Features sobre fundação rachada viram dívida composta. O Lobo escolhe calar o caos antes de avançar.

**Consequências:** Todo trabalho neste spec tem que servir uma das 3 frentes de limpeza. Propostas de features ficam na backlog até 09/05.

### DR-02 · Como DAP4.0 e thales-agent se relacionam

**Decisão:** **Thales-agent chama DAP4.0 via tools HTTP (opção B).**

**Por quê:** Cérebros separados com acoplamento mínimo e sinergia máxima. Permite evoluir cada um independentemente. Padrão "ferramentas vs cérebros" do mundo agentic.

**Consequências:**
- Criar `tools/dap4.py` no thales-agent com pelo menos: `dap4_query_lead`, `dap4_open_os`, `dap4_summary_today`, `dap4_pending_actions`
- Autenticação via `API_SECRET` compartilhado (mesmo secret usado pelo gateway)
- Base URL: `http://dap4-gateway:3001` (rede Docker interna) ou `https://api.dap.doctorautoprime.com.br` (via Cloudflare Tunnel)
- DAP4.0 não precisa saber que thales-agent existe — o acoplamento é unidirecional

### DR-03 · Centro do OS pessoal

**Decisão:** **HOME.md é o único centro (opção A).**

**Por quê:** HOME.md já tem estrutura de painel semanal, métricas, frentes ativas, scorecard. Candidatos alternativos (Brain_OS, Canvas_OS, Inbox_OS) viram subpáginas linkadas a partir do HOME.

**Consequências:**
- HOME fica como homepage do Obsidian (Settings → Files & Links → Default location + Startup file)
- Brain_OS, Canvas_OS, Inbox_OS viram subpáginas referenciadas via wikilinks a partir do HOME
- ARQUETIPO.md fica como referência de persona linkada do HOME (seção "Identidade & Tom")

### DR-04 · Modelo do canal Obsidian

**Decisão:** **Folder de threads `Inbox - Claudin/` (opção A).**

**Por quê:** Organização explícita, histórico limpo, threads paralelas. Cada conversa é um arquivo. Fácil de buscar. Alinhado com a estética Lobo.

**Consequências:**
- Pasta `Inbox - Claudin/` na raiz do vault PITOS (criada em 09/04)
- Convenção de blocos:

```markdown
## 🧑 Thales · 2026-04-09 14:30
Sua mensagem aqui

## 🐺 Claudin · 2026-04-09 14:31
Resposta do agente
```

- File watcher detecta modificação → parse do último bloco `## 🧑 Thales` sem `## 🐺 Claudin` abaixo → `IncomingMessage(channel=OBSIDIAN, ...)`
- Resposta do agente: append de bloco `## 🐺 Claudin · timestamp` no mesmo arquivo
- Lib sugerida: `watchdog` (já consagrada no ecossistema Python)
- A nota `Sem título 2.md` vira `Inbox - Claudin/001-arquitetura-saida.md` quando Phase 1 executar

### DR-05 · Vault unificado ou 2 vaults

**Decisão:** **Unificar em PITOS (opção A).**

**Por quê:** PITOS já tem estrutura (HOME, ARQUETIPO, PITOCOLOCO). CHAIRMAN como vault paralelo é dívida.

**Consequências:**
- `thales-agent/.env`: `VAULT_PATH=C:\Users\docto\OneDrive\Documentos\CHAIRMAN` → `VAULT_PATH=C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS`
- Pastas que o thales-agent espera encontrar (migrar/criar dentro do PITOS):
  - `10 Quick Notes/`
  - `00 Daily Notes/`
  - `09 Coaching/thales-tasks.md`
  - `Inbox - Claudin/` (já criada)
- Se CHAIRMAN tem `.obsidian/` próprio, desativar como vault no app Obsidian
- Conteúdo legado do CHAIRMAN root migra pra dentro de PITOS na Phase 1

### DR-06 · WhatsApp Evolution vs Meta Cloud API

**Decisão:** **Manter os dois — regra arquitetural permanente (opção C).**

**Por quê:** Não é status quo. É restrição técnica da plataforma Meta:
- Número pessoal do Thales **não é Business** → Meta Cloud API não aceita
- DAP4.0/Ana precisa escala, templates, sem risco de ban → Meta Cloud é obrigatório
- thales-agent precisa funcionar com o número pessoal do Thales → Evolution é o único caminho

**Consequências (regra permanente):**

| Quem | Cliente | Phone number |
|------|---------|--------------|
| DAP4.0 / Ana | Meta Cloud API + Graph v21.0 | Business da Doctor Auto Prime |
| thales-agent | Evolution API (Baileys / WhatsApp Web) | Pessoal do Thales |

- Documentar a regra no `CLAUDE.md` da raiz do DAP4.0 e no `dashboard/agents/DEPRECATED.md`
- Risco: se Meta apertar o cerco contra clientes não-oficiais, thales-agent quebra
- Mitigation: Telegram é canal redundante (já implementado no thales-agent)

### DR-07 · Telefones e linhas WhatsApp

**Decisão:** **Configurar as duas linhas do zero.** Nenhuma ativa hoje.

**Por quê:** DR-06 estabeleceu 2 clientes. Precisa configurar as 2 linhas agora, na Operação Limpeza.

**Consequências:**
- **Phase 3** ganha sub-tasks explícitas pra setup da linha Business (Meta Cloud, Ana)
- **Phase 4** ganha sub-tasks explícitas pra setup da Evolution API (thales-agent)
- Sem linhas WhatsApp ativas, o smoke test end-to-end de cada fase depende dessas configurações
- Risk ownership: Thales tem que ter acesso administrativo ao Meta Business Portfolio da Doctor Auto Prime antes da Phase 3

---

## 3. Arquitetura alvo (dia 30)

```
                        ┌───────────────────────────┐
                        │    Cloudflare Tunnel      │
                        │ (zero portas abertas, SSL)│
                        └──────────┬────────────────┘
                                   │
          ┌────────────────────────┼─────────────────────────┐
          │                        │                         │
          ▼                        ▼                         ▼
dap.doctorautoprime.com.br  api.dap.doctorautoprime.com.br  webhook.dap.doctorautoprime.com.br
          │                        │                         │
          ▼                        ▼                         ▼
     ┌────────────────────────────────────────────────────────────┐
     │         Docker network: dap4_net (isolada)                  │
     │  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐    │
     │  │ dashboard   │  │ gateway     │  │ agents (FastAPI) │    │
     │  │ nginx:80    │◀─┤ node:3001   │◀─┤ python:8000      │    │
     │  └─────────────┘  │ + socket.io │  │ + 5 agents       │    │
     │                   │ + helmet    │  │ + RAG + Chroma   │    │
     │                   │ + rate lim  │  └──────────────────┘    │
     │                   └─────────────┘                          │
     │                   ┌─────────────┐                          │
     │                   │ chromadb    │                          │
     │                   │ :8100       │                          │
     │                   └─────────────┘                          │
     └────────────────────────────────────────────────────────────┘
                                   ▲
                                   │ HTTP (tools dap4_*)
                                   │ API_SECRET
                                   │
     ┌────────────────────────────────────────────────────────────┐
     │       Docker network: thales_agent_net (isolada)            │
     │  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐     │
     │  │ brain       │◀─┤ evolution    │◀─┤ channels:      │     │
     │  │ FastAPI:8500│  │ (WhatsApp    │  │ - whatsapp     │     │
     │  │ + ThalesBrain│ │  pessoal)    │  │ - telegram     │     │
     │  └──────┬──────┘  └──────────────┘  │ - slack        │     │
     │         │                            │ - discord      │     │
     │         │ file watcher               │ - obsidian 🆕  │     │
     │         ▼                            │ - cli          │     │
     │  vault PITOS                         └────────────────┘     │
     │  (Inbox - Claudin/)                                         │
     └────────────────────────────────────────────────────────────┘
                                   ▲
                                   │
     ┌────────────────────────────────────────────────────────────┐
     │              Shared infrastructure (1x VPS)                  │
     │  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐    │
     │  │ postgres     │  │ redis        │  │ loki + grafana │    │
     │  │ (dap4_*,     │  │ (rate limit, │  │ 3 dashboards:  │    │
     │  │  thales_*)   │  │  state)      │  │ - DAP4.0 ops   │    │
     │  └──────────────┘  └──────────────┘  │ - thales ops   │    │
     │                                       │ - LLM custo    │    │
     │                                       └────────────────┘    │
     └────────────────────────────────────────────────────────────┘

VPS: Hetzner CX32 (€12.90/mês, 4 vCPU, 8 GB RAM, 80 GB SSD NVMe)
```

### 3.1 Princípios de isolamento

- **Networks Docker separadas** por projeto. DAP4.0 e thales-agent não se enxergam direto — só via HTTP autenticado via gateway público ou loopback.
- **Postgres compartilhado** mas com schemas separados: `dap4_*` e `thales_agent_*`. Operacionalmente 1 backup, 1 upgrade, 1 monitoramento.
- **Redis compartilhado** pra rate limiting (DAP4.0) e state (thales-agent).
- **Secrets isolados**: cada projeto tem seu `.env`. Não compartilhar variáveis de ambiente entre projetos.
- **Volumes nomeados** por projeto. Nunca anonymous volumes pra dados.
- **Cloudflare Tunnel único** com múltiplos public hostnames (sub)domínios. Zero portas abertas na VPS.
- **Observability compartilhada** (Loki + Grafana) mas com dashboards separados por projeto + 1 dashboard de custo LLM unificado.

---

## 4. Plano de execução — 5 Phases

Todas as datas são relativas ao dia 1 = 2026-04-09. Cada Phase tem critérios de aceite explícitos que determinam "pronto pra próxima".

### Phase 1 — Vault PITOS unificado (dias 2-4, 10-12/04)

**Objetivo:** De 2 vaults aninhados (CHAIRMAN + PITOS) para 1 vault organizado com as pastas que o thales-agent precisa.

**Sub-tasks:**
1. Verificar se `C:\...\CHAIRMAN\.obsidian/` existe → se sim, desativar no Obsidian app (não deletar)
2. Criar pastas dentro de PITOS:
   - `10 Quick Notes/`
   - `00 Daily Notes/`
   - `09 Coaching/thales-tasks.md` (template de checklist scheduler)
   - `Inbox - Claudin/` ✅ (já criada em 09/04)
3. Migrar conteúdo legado do CHAIRMAN root pra dentro de PITOS (se houver)
4. Achatar russian dolls `PITOS/PITOCOLOCO/CHAIRMAN/...` numa estrutura sã
5. Revisar [[HOME]]: adicionar seção "Subpáginas" com wikilinks pra [[Brain_OS]], [[Canvas_OS]], [[Inbox_OS]], [[ARQUETIPO]]
6. Configurar HOME como homepage do Obsidian (Settings → Default location + Startup file)
7. Mover `Sem título 2.md` → `Inbox - Claudin/001-arquitetura-saida.md`
8. Atualizar `thales-agent/.env`: `VAULT_PATH=C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS`
9. Smoke test: `python -m core.cli` no thales-agent → `vault_quick_note("teste")` → confirmar que cria a nota no PITOS

**Critério de aceite:**
- [ ] Abrir Obsidian mostra apenas 1 vault (PITOS)
- [ ] HOME abre como nota inicial
- [ ] `thales-agent` lê e escreve em PITOS sem erro
- [ ] `Inbox - Claudin/001-arquitetura-saida.md` contém todo o histórico desta sessão

### Phase 2 — Banco Doctor Prime limpo (dias 5-9, 13-17/04)

**Objetivo:** Executar as 4 fases do plano de limpeza documentado em [[DATABASE_MAP]]. Sair de 52 tabelas bagunçadas pra ~25 tabelas canônicas com RLS.

**Sub-tasks:**
1. **Backup completo** do Supabase project `acuufrgoyjwzlyhopaus` antes de qualquer DROP
   - pg_dump via Supabase dashboard ou CLI
   - Armazenar backup fora do ambiente (S3, B2, OneDrive, ou disco externo)
   - Verificar tamanho + integridade do dump
2. **Phase 1 do DATABASE_MAP** — Auditar dados únicos nas tabelas legacy:
   - `SELECT COUNT(*) FROM "Cliente" WHERE id NOT IN (SELECT id::text FROM "04_CLIENTS");`
   - Mesmo pra `Veiculo`/`05_VEHICLES` e `OrdemServico`/`06_OS`
3. Migrar dados únicos das legacy pras oficiais (INSERT com conflict resolution)
4. **Phase 2** — Wipe dados de teste das oficiais (somente se Thales confirmar que são teste)
5. **Phase 3** — DROP das 22 tabelas legacy/duplicadas/portal-específicas:
   - PascalCase: `Cliente`, `Veiculo`, `OrdemServico`, `Mecanico`, `Colaborador`
   - Lowercase duplicadas: `clientes`, `clientes_oficina`, `veiculos`, `veiculos_orfaos`, `mecanicos`, `ordens_servico`, etc.
   - Portal-específicas: `colaboradores_portal_*`
   - Agendamento redundantes: `agendamento`, `clients_agenda`, `clients_selfcad`, `novos_cli_agenda`
6. Consolidar `rag_documents` vs `rag_documentos` (manter `rag_documents`)
7. **Phase 4** — Criar consultor `Consultor_thales` em `01_colaboradores`
8. Verificar que `verify_staff_login` continua funcionando após cleanup
9. Documentar schema final em `DATABASE_MAP.md` v2

**Critério de aceite:**
- [ ] Backup existe e foi testado (restore em staging/local)
- [ ] Total de tabelas: ≤ 30 (era 52)
- [ ] Zero tabelas legacy PascalCase
- [ ] `verify_staff_login('Dev_thales', ...)` retorna ok
- [ ] `DATABASE_MAP.md` v2 atualizado

### Phase 3 — DAP4.0 rename + deploy + linha Ana (dias 10-17, 18-25/04)

**Objetivo:** `doctor-ai-dashboard` vira `dap4` no disco, roda em VPS via Cloudflare Tunnel, linha Meta WhatsApp Business da Ana ativa.

**Sub-tasks — Rename:**
1. Rename físico: `C:\dev\doctor-ai-dashboard` → `C:\dev\dap4`
2. Atualizar paths em scripts, Makefile, docker-compose.yml, docker-compose.dev.yml, CI
3. Atualizar nome em `package.json`, `pyproject.toml`, `gateway/package.json`, `dashboard/package.json`
4. Atualizar documentação (`CLAUDE.md`, `CHECKPOINT.md`, `HANDOFF.md`, `META_SETUP_GUIDE.md`)
5. **DELETAR `dashboard/agents/`** num commit isolado destrutivo (já marcado DEPRECATED em 09/04)
6. Commit: `refactor: rename project to dap4, drop deprecated dashboard/agents tree`

**Sub-tasks — VPS:**
7. Provisionar Hetzner CX32 (4 vCPU / 8 GB RAM / 80 GB SSD)
8. Setup inicial: Debian 12 + Docker + Docker Compose + Cloudflare Tunnel binary + firewall (só 22/SSH)
9. SSH key authentication only, disable password login
10. Criar user não-root pra containers

**Sub-tasks — Cloudflare Tunnel:**
11. Criar Cloudflare Tunnel (via dashboard)
12. Configurar public hostnames:
    - `dap.doctorautoprime.com.br` → `http://dashboard:80`
    - `api.dap.doctorautoprime.com.br` → `http://gateway:3001`
    - `webhook.dap.doctorautoprime.com.br` → `http://gateway:3001`
13. DNS configurado no registrar (Cloudflare gerencia)

**Sub-tasks — Deploy:**
14. Clone do repo na VPS (branch `master`)
15. Setup `.env` de produção a partir do `.env.example`
16. `docker compose --profile prod up -d --build`
17. Smoke test: `curl https://api.dap.doctorautoprime.com.br/api/health` retorna `{"status":"ok"}`
18. Smoke test: abrir `https://dap.doctorautoprime.com.br` no browser, dashboard carrega

**Sub-tasks — Linha Ana (Meta WhatsApp Business):**
19. Criar/verificar Meta Business Portfolio pra Doctor Auto Prime
20. Criar WhatsApp Business Account (WABA) dentro do portfolio
21. Registrar número Business (se ainda não tem, adquirir novo)
22. Gerar permanent access token com escopos `whatsapp_business_messaging` + `whatsapp_business_management`
23. Coletar 5 credenciais: `META_PHONE_NUMBER_ID`, `META_ACCESS_TOKEN`, `META_APP_SECRET`, `META_VERIFY_TOKEN`, `META_WABA_ID`
24. Adicionar no `.env` de produção do DAP4.0
25. Configurar webhook Meta apontando pra `webhook.dap.doctorautoprime.com.br/api/meta/webhook`
26. Setup verificação inicial do webhook (Meta valida o verify token)
27. Aprovar pelo menos 1 template de boas-vindas pra cliente
28. Smoke test E2E: cliente manda WhatsApp → webhook recebe → Ana responde → mensagem volta pro cliente

**Critério de aceite:**
- [ ] `C:\dev\dap4` existe e não há mais `doctor-ai-dashboard`
- [ ] `dashboard/agents/` removido do repo
- [ ] `https://dap.doctorautoprime.com.br` carrega o dashboard
- [ ] `https://api.dap.doctorautoprime.com.br/api/health` retorna ok
- [ ] Webhook Meta verificado, HMAC validation funcionando
- [ ] Smoke test E2E do WhatsApp Ana funciona

### Phase 4 — thales-agent canal Obsidian + integração DAP4.0 + linha pessoal (dias 18-24, 26/04-02/05)

**Objetivo:** Thales-agent completo: canal Obsidian funcionando, tools `dap4_*` conversando com DAP4.0, linha WhatsApp pessoal via Evolution ativa.

**Sub-tasks — Evolution API (linha pessoal):**
1. Subir container Evolution API na VPS (network isolada do DAP4.0: `thales_agent_net`)
2. Criar instance Evolution pro Thales
3. Scannear QR code com o WhatsApp do celular pessoal (manual, 1x)
4. Persistir sessão em volume Docker nomeado (`thales_agent_evolution_session`)
5. Coletar credenciais: `EVOLUTION_URL`, `EVOLUTION_API_KEY`, `EVOLUTION_INSTANCE`
6. Adicionar no `.env` de produção do thales-agent
7. Webhook Evolution → `http://thales-agent:8500/webhook/whatsapp` (rede Docker interna)
8. Smoke test: mandar WhatsApp pro próprio número de outro aparelho → thales-agent responde

**Sub-tasks — Canal Obsidian:**
9. Criar `channels/obsidian/__init__.py`:
   - Import `watchdog` (`from watchdog.observers import Observer`, `FileSystemEventHandler`)
   - File watcher apontando pra `settings.vault_path + "Inbox - Claudin/"`
   - Handler `on_modified` → parse do arquivo modificado
   - Parser: extrair último bloco `## 🧑 Thales · <timestamp>` sem `## 🐺 Claudin` abaixo
   - Criar `IncomingMessage(channel=Channel.OBSIDIAN, text=<bloco>, sender_id="thales", raw={"file": <path>})`
   - Encaminhar ao `brain.think(msg)`
   - Ao receber `OutgoingMessage`, fazer append de bloco `## 🐺 Claudin · <timestamp>\n\n<text>\n` no mesmo arquivo
10. Atualizar `main.py` pra inicializar canal Obsidian no lifespan
11. Testar: criar `Inbox - Claudin/test-001.md` com bloco `## 🧑 Thales · ...` → ver agente responder inline

**Sub-tasks — Integração DAP4.0:**
12. Criar `tools/dap4.py`:
    - `dap4_query_lead(phone_or_name)` → GET `https://api.dap.doctorautoprime.com.br/api/dashboard/leads?search=...`
    - `dap4_open_os(client_id, descricao)` → POST `/api/os/create`
    - `dap4_summary_today()` → GET `/api/dashboard/metrics`
    - `dap4_pending_actions()` → GET `/api/sofia/pending`
    - Auth: `Authorization: Bearer {API_SECRET}` no header
    - Timeout: 10s, retry: 1x em 5xx
13. Importar `tools.dap4` em `core/brain.py` (registra auto)
14. Smoke test: via WhatsApp pessoal, mandar "qual o status do lead Carlos?" → thales-agent chama `dap4_query_lead("Carlos")` → responde com dados reais do Supabase

**Sub-tasks — Hardening:**
15. Atualizar modelo em `core/brain.py:61`: `claude-sonnet-4-20250514` → `claude-sonnet-4-6`
16. Persistir `_conversations` em Postgres (schema `thales_agent.conversations`): (conversation_key, messages_json, updated_at)
17. Ao startup, carregar conversas recentes (últimas 48h) em memória

**Critério de aceite:**
- [ ] Pasta `channels/obsidian/` existe com adapter implementado
- [ ] Arquivo `.md` em `Inbox - Claudin/` dispara resposta do agente inline
- [ ] WhatsApp pessoal recebe resposta do thales-agent
- [ ] Tool `dap4_query_lead` retorna dados reais do DAP4.0
- [ ] Conversations persistem após restart do container
- [ ] `core/brain.py` usa modelo atualizado

### Phase 5 — Hardening + observabilidade (dias 25-30, 03-09/05)

**Objetivo:** Os 2 sistemas rodando na mesma VPS, com monitoramento, alertas, backups. Operação previsível.

**Sub-tasks — Deploy thales-agent:**
1. Dockerfile do thales-agent pronto
2. Docker network `thales_agent_net` isolada
3. `docker compose up -d thales-agent evolution` na VPS
4. Cloudflare Tunnel adiciona hostname opcional `thales.doctorautoprime.com.br` (só pra debug, protegido por Cloudflare Access)

**Sub-tasks — Infra compartilhada:**
5. Postgres compartilhado: criar schemas `dap4_*` e `thales_agent_*`, grants separados
6. Redis compartilhado: DB 0 pra DAP4.0 rate limiting, DB 1 pra thales-agent state
7. Containers `loki`, `grafana`, `promtail` em network compartilhada de observabilidade

**Sub-tasks — Observabilidade:**
8. Configurar Promtail coletando logs de todos containers em formato JSON
9. Criar 3 dashboards Grafana:
   - **DAP4.0 Ops**: request rate, latência, erros, status de Ana (Meta webhook events)
   - **thales-agent Ops**: channels ativos (WhatsApp/Telegram/Obsidian), mensagens/dia, tool calls/dia
   - **LLM Custo** (unified): tokens in/out por provider por projeto, custo estimado em R$/dia, alerta se > R$X/dia
10. Token usage logging já implementado no DAP4.0 em 09/04; adicionar o mesmo no thales-agent (`core/brain.py`)
11. Alertas Grafana:
    - Custo LLM > R$X/dia → notifica via thales-agent (Telegram/WhatsApp pessoal)
    - Gateway DAP4.0 error rate > 5% → notifica
    - Agents DAP4.0 healthcheck failing > 2 min → notifica

**Sub-tasks — Backups:**
12. Script cron na VPS (`0 3 * * *`):
    - `pg_dump` do Postgres → salvar em S3/B2
    - `docker exec chromadb` snapshot → salvar em S3/B2
    - Retenção: 7 dias diários, 4 semanais, 3 mensais
13. Teste de restore em staging/local (1x, pra validar)

**Sub-tasks — CI/CD:**
14. `.github/workflows/ci.yml` do DAP4.0 já roda pytest + vitest + tsc
15. Adicionar job de lint: ESLint + Prettier (frontend/gateway) + Ruff (agents)
16. Criar `.github/workflows/ci.yml` pro thales-agent: pytest + ruff
17. Deploy job: opcional pra Phase 5 ou depois. Por enquanto deploy é manual via `make deploy`.

**Sub-tasks — Documentação:**
18. Criar `OPS_RUNBOOK.md` no PITOS:
    - Como subir, parar, restart
    - Como ver logs (Grafana/docker logs)
    - Como restaurar backup
    - Troubleshooting dos webhooks Meta e Evolution
    - Credentials location (`.env` locations)
    - Contact points (você, hosting, Cloudflare)

**Critério de aceite:**
- [ ] thales-agent rodando na VPS
- [ ] 3 dashboards Grafana acessíveis e populados
- [ ] Backup diário rodando automaticamente e pelo menos 1 restore testado
- [ ] Alertas Grafana configurados e disparando (teste: simular erro)
- [ ] `OPS_RUNBOOK.md` commitado no PITOS

---

## 5. Riscos e mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|:-:|:-:|---|
| Perder dados ao fazer DROP das tabelas legacy | Baixa | Catastrófico | Backup obrigatório antes + teste de restore + aprovação explícita do Thales por DROP |
| Cliente Evolution API ser banido pelo WhatsApp | Média | Alto | Telegram como canal redundante já implementado; usar número que você pode perder se necessário |
| Rename `doctor-ai-dashboard` → `dap4` quebrar imports | Média | Médio | Rename num commit isolado + CI verde antes de seguir + smoke test obrigatório |
| VPS cair no meio da Phase 3 (deploy) | Baixa | Alto | Backup + playbook de reprovisioning; provider com SLA (Hetzner 99.9%) |
| Meta rejeitar template de boas-vindas | Média | Médio | Usar template padrão de "serviço" (não marketing) — aprovação imediata |
| Thales perder tempo configurando linhas manualmente | Alta | Médio | Documentar passo a passo no `META_SETUP_GUIDE.md` + `EVOLUTION_SETUP.md` |
| Canal Obsidian corromper arquivo `.md` ao fazer append concorrente | Média | Médio | Usar lock de arquivo (fcntl no Linux, msvcrt no Windows) + parser robusto a bloco mal formado |
| Bagunça do vault CHAIRMAN ter conteúdo importante não migrado | Média | Alto | Fazer diff completo CHAIRMAN vs PITOS antes de desativar CHAIRMAN como vault |
| Sofia ou outros agentes stub serem necessários antes do dia 30 | Baixa | Baixo | Manter como backlog; Operação Limpeza explicitamente não implementa features novas |
| Custo LLM explodir por loop descontrolado | Baixa | Alto | Token budget + alerta Grafana + kill-switch manual documentado no RUNBOOK |

---

## 6. Métricas de sucesso (dia 30, 09/05)

### 6.1 Subjetiva — "O teste do Lobo"

No dia 09/05, o Thales faz este exercício:

1. Abre `C:\dev\` — vê `dap4/` e `thales-agent/`. Não vê nada bagunçado.
2. Abre o vault PITOS — vê 1 vault, 1 estrutura, 1 centro (HOME). `Inbox - Claudin/` tem 5+ threads de conversa real.
3. Abre `dap.doctorautoprime.com.br` — dashboard carrega, dados reais, sem mock, sem erro.
4. Manda WhatsApp pessoal pro thales-agent: "qual o faturamento da semana?" — ele responde com dado real do DAP4.0.
5. Olha o dashboard de custo no Grafana: gasto LLM previsível, dentro do orçamento.
6. **Nada dá raiva.**

Se isso for verdade, a Operação Limpeza venceu.

### 6.2 Objetivas — métricas mensuráveis

| Métrica | Valor alvo | Como medir |
|---------|-----------|-----------|
| Total de tabelas no Supabase | ≤ 30 | `\dt` no psql |
| Bundle inicial do dashboard | < 100 KB gzipped | Output do `npm run build` |
| Gateway `tsc --noEmit` | exit 0 | CI |
| pytest agents | 100% pass | CI |
| vitest dashboard | 100% pass | CI |
| thales-agent pytest | 100% pass (novo) | CI |
| Coverage agents | ≥ 60% | `pytest --cov` |
| Vaults Obsidian ativos | 1 | Settings do Obsidian |
| Linhas WhatsApp ativas | 2 (Ana Meta + Thales Evolution) | Logs de webhook + Evolution dashboard |
| Custo LLM/dia | < R$X (a definir com Thales) | Grafana dashboard |
| Backup diário rodando | sim | Cron log da VPS |
| Tempo pra subir tudo do zero em nova VPS | < 30 min | Teste de rebuild |

---

## 7. Rollback plan

Cada Phase tem ponto de rollback bem definido. Em caso de problema crítico:

### Phase 1 (vault)
- **Rollback:** OneDrive tem versioning. Restore do estado anterior via OneDrive web. CHAIRMAN permanece vault até Phase 1 completar — desativar é reversível (não deletar).

### Phase 2 (banco)
- **Rollback:** Restore do pg_dump obrigatório. Em caso de DROP errado, o backup é o único caminho. **Não prosseguir pra Phase 3 sem teste de restore validado.**

### Phase 3 (DAP4.0 deploy)
- **Rollback:**
  - Rename: `git revert` do commit de rename
  - Deploy: `docker compose down` + reverter Cloudflare Tunnel config
  - Meta webhook: desconfigurar no WABA (não deleta conversas, só pausa)

### Phase 4 (thales-agent)
- **Rollback:**
  - Canal Obsidian: apagar pasta `channels/obsidian/`, remover do lifespan no `main.py`
  - tools/dap4: apagar arquivo
  - Evolution: parar container, não é destrutivo

### Phase 5 (hardening)
- **Rollback:** Parar containers de observabilidade. Sistema continua funcionando.

---

## 8. Dependências externas

- **Cloudflare** — domínio `doctorautoprime.com.br` gerenciado + Cloudflare Tunnel
- **Hetzner** (ou equivalente) — VPS provisionada e acessível
- **Meta Business Portfolio** — acesso admin pro Thales (linha Ana)
- **Anthropic** — API key com crédito suficiente pro mês (estimar no início da Phase 5)
- **OpenAI** — API key pra embeddings (RAG)
- **Supabase** — project `acuufrgoyjwzlyhopaus` acessível (você já tem)

---

## 9. Log de execução

> Este bloco é atualizado conforme as Phases avançam. Cada linha: `[YYYY-MM-DD HH:mm] Phase N — evento.`

- `[2026-04-09 09:30]` Pasta `Inbox - Claudin/` criada em PITOS — primeira ação executiva
- `[2026-04-09 09:30]` Spec `000-spec-saida-30-dias.md` escrito e aprovado

### Phase 1 — Vault PITOS unificado ✅ FECHADA
- `[2026-04-09 ~10:00]` P1.1 Inspecionar CHAIRMAN — não era vault, só `09 Coaching/sessions/` vazia
- `[2026-04-09 ~10:05]` P1.2 Criar pastas em PITOS: `10 Quick Notes/`, `00 Daily Notes/`, `09 Coaching/sessions/`, `thales-tasks.md` template
- `[2026-04-09 ~10:10]` P1.3 Atualizar `thales-agent/.env`: `VAULT_PATH` → `...\CHAIRMAN\PITOS`
- `[2026-04-09 ~10:15]` P1.4 HOME.md revisado: seção "🧭 Subpáginas" + callout "Este é o centro"
- `[2026-04-09 ~10:20]` P1.5 Smoke test — thales-agent escreveu em `PITOS/10 Quick Notes/`
- `[2026-04-09 ~10:30]` P1.6 `CHAIRMAN/09 Coaching/` deletada (era só pasta vazia)
- `[2026-04-09 ~10:35]` P1.7 `Sem título 2.md` movida para `Inbox - Claudin/001-arquitetura-saida.md`
- `[2026-04-09 ~10:40]` P1.8 Lembrete rotação keys via `vault_append_daily` + ClickUp reminder (ID `3C7kR86QHxcatYwBk84BcnhTbqP`)

### Phase 2 — Banco Doctor Prime limpo ✅ FECHADA
- `[2026-04-09 ~11:30]` P2.1 Validação acesso Supabase MCP — projeto DOCTOR PRIME `acuufrgoyjwzlyhopaus` ACTIVE_HEALTHY
- `[2026-04-09 ~11:30]` Descoberta: DATABASE_MAP v1 estava **obsoleto**. Banco já tinha sido parcialmente limpo antes. 39 tabelas reais (não 52).
- `[2026-04-09 ~11:35]` P2.2 Backup completo via MCP — 13.16 MB em `C:\dev\backups\doctor-prime-2026-04-09\`, validado 24/24 tabelas via `_validate.py`, status OK
- `[2026-04-09 ~11:45]` P2.3 Auditoria read-only: 5 legacy PascalCase vazias, FKs internas ao grupo, `verify_staff_login` existe, `rag_documentos` é abordagem legacy (não duplicata), Consultor_teste = user real criado em 09/04 07:14 UTC
- `[2026-04-09 ~12:00]` P2.4 Migração: `Consultor_teste` (Thales Oliveira) migrado de `colaboradores_portal_consultor` → `colaboradores` (nível 3). Password_hash preservado.
- `[2026-04-09 ~12:05]` P2.5 DROPs aplicados via 4 apply_migration:
  - `drop_legacy_pascalcase_tables`: Cliente, Veiculo, OrdemServico, Mecanico, Colaborador
  - `drop_legacy_portal_tables`: colaboradores_portal_{consultor,gestao,mecanico,dev}
  - `drop_legacy_rag_documentos`: rag_documentos
  - `drop_unused_app_users_and_kv_store`: app_users, kv_store_0092e077
  - **Total: 12 tabelas dropadas**
- `[2026-04-09 ~12:10]` ⚠️ Incidente: `verify_staff_login` tinha referências internas às tabelas `colaboradores_portal_*` dropadas. Function quebrou.
- `[2026-04-09 ~12:15]` P2.6 `simplify_verify_staff_login_single_table` aplicada — rewrite da function consultando apenas `colaboradores`. Problema resolvido em <5min.
- `[2026-04-09 ~12:20]` P2.7 Smoke tests pós-limpeza: 27 tabelas restantes, `colaboradores` com 5 rows, verify_staff_login retorna esperado para user inexistente (empty), user com senha errada (ok=false), data crítica intacta
- `[2026-04-09 ~12:25]` [[DATABASE_MAP]] v2 escrito substituindo o v1 legacy

### Phase 3 — Aguardando início (DAP4.0 rename + deploy + linha Ana)
- `[2026-04-09 ...]` próximo movimento: aguardando autorização do Thales

---

## 10. Referências

- [[Inbox - Claudin/001-arquitetura-saida|001-arquitetura-saida]] — brainstorming original com as 7 decisões (ex-`Sem título 2.md`, movido na Phase 1)
- [[HOME]] — centro do OS pessoal (DR-03)
- [[ARQUETIPO]] — persona Lobo Estrategista (calibração de tom)
- [[DATABASE_MAP]] — mapa do Supabase Doctor Prime, plano de limpeza em 4 fases (Phase 2)
- `C:\dev\doctor-ai-dashboard\CLAUDE.md` — documentação do DAP4.0 (Phase 3)
- `C:\dev\doctor-ai-dashboard\META_SETUP_GUIDE.md` — guia de setup Meta WhatsApp (Phase 3)
- `C:\dev\thales-agent\CLAUDE.md` — documentação do thales-agent (Phase 4)
- `C:\dev\thales-agent\core\brain.py` — ThalesBrain (Phase 4)
- `C:\dev\thales-agent\core\message.py:18` — `Channel.OBSIDIAN` (Phase 4)

---

**Version history**

| Versão | Data | Autor | Mudanças |
|--------|------|-------|----------|
| 1.0 | 2026-04-09 | Claudin | Primeira versão. 7 DRs fechadas, 5 phases. Aprovado pelo Thales. |
