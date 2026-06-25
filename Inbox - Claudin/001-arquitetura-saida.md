---
tags: [chairman, claudin, dap4, brainstorming, arquitetura, thread-001]
aliases: ["001 - Arquitetura da Saída", "Claudin Channel Thread 001", "Ex-Sem título 2"]
created: 2026-04-09
moved_from: "Sem título 2.md"
moved_at: 2026-04-09
participants: [Thales, Claudin]
status: arquivado-ativo
thread_id: 001
next_thread: null
---

# Thread 001 — Canal Claudin ↔ Thales (Arquitetura da Saída)

> [!info] Thread arquivada mas ativa
> Esta é a **primeira thread oficial** do canal Claudin. Originalmente criada como `Sem título 2.md` em 09/04/2026 quando o canal foi estabelecido. Movida pra `Inbox - Claudin/001-arquitetura-saida.md` na Phase 1 da Operação Limpeza, virando a primeira thread do novo sistema.
>
> **Conteúdo histórico:** brainstorming completo que gerou o [[000-spec-saida-30-dias|spec da Operação Limpeza]] — 7 decisões arquiteturais (DR-01 a DR-07) tomadas aqui.
>
> **Status:** arquivada no sentido de "não é mais canal ativo" (o canal agora vive em threads novas dentro de `Inbox - Claudin/`), mas **permanece referenciável** como origem das decisões.

---

## 0. Estado real (espelho do que eu vi)

Antes de qualquer plano, isso é o que eu vi quando você me deu acesso ao vault. Sem suavizar:

**Você não está construindo do zero.** Você tem um sistema rodando, com 5911 leads no CRM, 27 clientes ativos, 48 OS, 4 colaboradores reais e auth funcional via SHA-256. A oficina existe, gera dados, já é um negócio. O que você está fazendo é **organizar o ecossistema ao redor dela**. Isso muda muita coisa.

**Você é o Lobo Estrategista.** Tom: direto, poucas voltas, peso alto. Frase-mãe que vou usar como filtro pra cada decisão arquitetural daqui pra frente:

> *"Eu não corro atrás de tudo. Eu escolho o que merece minha força."*

**Frentes ativas, na sua semana atual:** [[HOME|Antigravity, Claude Code, Obsidian, Oficina, Conteúdo]] — 5 frentes paralelas. Esse é o primeiro lugar que eu vou apertar quando a gente chegar na arquitetura.

---

## 1. A bagunça nomeada (sem dó)

Não é uma bagunça só. **São três bagunças sobrepostas**, e tratar elas como uma coisa única é o que mantém o caos vivo.

### 🔴 Bagunça 1 — O vault Obsidian

> [!warning] O sistema operacional pessoal não pode ser bagunçado. Ele é onde tudo começa.

- **Russian dolls de pasta**: `PITOS/PITOCOLOCO/CHAIRMAN/PITOS/...` — pelo menos 3 níveis de aninhamento com nomes que se repetem. Quando você vai abrir uma nota, você não sabe em qual "PITOS" você está.
- **`Sem título.md` e `Sem título 2.md`** — notas órfãs sem propósito declarado. (Esta segunda agora tem propósito: é o nosso canal.)
- **Multiplas fontes de "OS pessoal"**: [[Brain_OS]], [[Canvas_OS]], [[Inbox_OS]], [[HOME]], [[ARQUETIPO]] — cada um com uma cara diferente, todos pretendendo ser o "centro". Não tem um centro. Tem cinco semi-centros.
- **`base_conhecimento/`** com `CLAUDE.md`, `raw`, `tools`, `wiki` — estrutura promissora, vazia ou semi-povoada (preciso ler).
- **`PITOCOLOCO/SOPHIA/C-LEVEL HUB`** — tem um hub C-Level no vault, e tem squads C-Level no `doctor-ai-dashboard`. Os dois mundos não conversam.

### 🔴 Bagunça 2 — O banco de dados Doctor Prime

A gente já documentou isso no [[DATABASE_MAP]], mas vou nomear pra ficar no canal:

- **52 tabelas no Supabase**, das quais **20 oficiais e 22 candidatas a DROP** (legacy PascalCase + duplicadas lowercase + portal-específicas).
- **Dados duplicados em 3 lugares**: 27 `04_CLIENTS` + 95 `Cliente` legacy + 3 `clientes` lowercase. O cliente Carlos pode existir em 3 lugares com 3 IDs diferentes.
- **4 tabelas de "agendamento"**, todas vazias. Caos sem ainda ter sido usado.
- **2 tabelas de RAG** (`rag_documents` e `rag_documentos`) — a duplicação chegou até no cérebro de IA.
- **Auth funciona, mas auth dev mode silencioso** (já consertei no `agents/api/deps.py` na sessão anterior).

O DATABASE_MAP já tem o **plano de limpeza em 4 fases** pronto. Não precisa ser inventado — precisa ser executado.

### 🔴 Bagunça 3 — Os 3 projetos de código

- **`doctor-ai-dashboard`** = futuro DAP4.0. Já passou pelo `/hm-qa /hm-engineer /hm-designer /hm-fix` hoje. Está auditável agora, mas tem 9 pendências que não cabem em fix automático (token budget, multi-tenancy, agentes stub, HMAC Kommo, etc.).
- **`thales-agent`** = projeto P2. Não auditei a fundo ainda — sei que existe pasta `whatsapp-bridge`, `channels`, `tools`. Provavelmente é onde mora a "ponte com o mundo web".
- **`Claude-Skill-Developmental-Coach`** = despriorizado por você. Tira da equação.
- **Backend Python duplicado**: `agents/` (canônico, builda no Docker) **e** `dashboard/agents/` (cópia divergente) — eu já marquei o `dashboard/agents/DEPRECATED.md` mas a deleção é destrutiva e fica pra commit isolado.

---

## 2. Por que isso é tratável (não é desespero)

Aqui é onde o Lobo respira. Cada uma das 3 bagunças tem uma característica boa:

| Bagunça | Boa notícia |
|---------|-------------|
| Vault | É só markdown. Eu reorganizo em uma sessão sem perder uma única ideia. |
| Banco | Você já tem o **plano de limpeza pronto** no DATABASE_MAP. Falta executar com cuidado, em backup. |
| Código | Já está auditável (sessão de hoje). As 9 pendências são roadmap, não dívida invisível. |

**Nenhuma das três é "não sei o que fazer".** Todas são "sei o que fazer, falta ordem". Isso é o tipo de bagunça que se resolve em semanas, não meses.

---

## 3. Como a gente vai trabalhar nesta nota

> [!tip] Protocolo do canal
> Cada bloco abaixo é uma decisão pendente. Quando você responder, eu **edito o bloco**, marco como resolvido, e crio o próximo. A nota vai crescer em registros decididos, não em conversa. No final, ela vira o **spec do plano**.

- Cada decisão fica num bloco `## Decisão N — Título`
- Status: `🟡 aberta` / `🟢 fechada` / `🔴 bloqueada`
- Eu sempre proponho 2-3 opções com tradeoffs e a minha recomendação. Você escolhe ou propõe a sua.
- Quando a gente fechar todas as decisões críticas, eu escrevo o **plano arquitetural completo** em outra nota (`docs/.../2026-04-09-dap4-saida-arquitetura.md`).

---

## 4. Insight 01 — Você já tem o thales-agent 80% pronto

> [!success] Descoberta de 09/04
> **Quando você falou "cara, voce basicamente fez a funçao do thales-agent agora", eu fui auditar.** Você tem MUITO mais pronto do que eu pensava. O insight não é "construir o thales-agent". É **terminar** o thales-agent — que está num estado avançado e bem desenhado.

### O que existe em `C:\dev\thales-agent` (já implementado)

| Camada | Arquivo | Estado |
|--------|---------|--------|
| **Cérebro** | `core/brain.py` (`ThalesBrain`) | ✅ Async Anthropic + tool_use loop com depth=5 + conversation memory por (channel, sender_id) + system prompt PT-BR |
| **Modelo unificado** | `core/message.py` (`IncomingMessage`/`OutgoingMessage`) | ✅ Normaliza todo canal, suporta media (text/audio/image/video/document) |
| **Channel WhatsApp** | `channels/whatsapp/__init__.py` (123 linhas) | ✅ Via **Evolution API** (não Meta Cloud) |
| **Channel Telegram** | `channels/telegram/__init__.py` (91 linhas) | ✅ |
| **Channel Slack** | `channels/slack/__init__.py` (74 linhas) | ✅ |
| **Channel Discord** | `channels/discord/__init__.py` (89 linhas) | ✅ |
| **Channel Terminal** | `core/cli.py` | ✅ Pra dev/debug |
| **Tools — Vault** | `tools/vault.py` | ✅ 5 tools: `vault_quick_note`, `vault_append_daily`, `vault_read_tasks`, `vault_search`, `vault_read_note` |
| **Tools — Calendar** | `tools/calendar.py` | ✅ Add events, today, week view, reminders |
| **Tools — Registry** | `tools/registry.py` | ✅ Decorator `@tool(name, description, parameters)` que vira definição Claude API automaticamente |
| **Media processor** | `media/processor.py` | ✅ Whisper (áudio), Claude Vision (imagem), FFmpeg (vídeo→frames+áudio) |
| **Scheduler** | `scheduler/watcher.py` | ✅ Parser de `09 Coaching/thales-tasks.md` formato Obsidian checklist (`- [ ] 09:00 command`) |
| **Server FastAPI** | `main.py` | ✅ Lifespan startup, /health, webhook routes |

### O que **falta** (gaps reais)

| Gap | Severidade | O que é |
|-----|-----------|---------|
| **Channel Obsidian** | 🔴 ALTO | Enum `Channel.OBSIDIAN` já existe (`core/message.py:18`), mas pasta `channels/obsidian/` **não existe**. É o que eu fiz manualmente nesta sessão — só falta virar adapter automatizado. |
| **Vault path inconsistente** | 🔴 ALTO | `thales-agent/.env` aponta pra `C:\Users\docto\OneDrive\Documentos\CHAIRMAN`, mas o canal Claudin↔Thales que a gente usa hoje mora em `CHAIRMAN\PITOS`. **Tem 2 vaults Obsidian aninhados**, ou é só path desatualizado? Decisão pendente. |
| **WhatsApp: Evolution vs Meta** | 🟡 MÉDIO | thales-agent usa **Evolution API**. DAP4.0 usa **Meta Cloud API** (e deprecou Evolution conscientemente em 09/04). Manter dois clientes de WhatsApp diferentes na mesma máquina é dívida. Padronizar pra Meta Cloud API. |
| **State só in-memory** | 🟡 MÉDIO | `ThalesBrain._conversations: dict` perde tudo ao restart. Persistir em Postgres ou Redis. |
| **Integração com DAP4.0** | 🟡 MÉDIO | Hoje thales-agent é cérebro independente. Não tem `tool_dap4_lead`, `tool_dap4_open_os`, etc. Faltam ferramentas que conectem o agente pessoal ao cérebro da oficina. |
| **Modelo desatualizado** | 🟢 BAIXO | `brain.py:61` usa `claude-sonnet-4-20250514`. Hoje (09/04/2026) o atual é `claude-sonnet-4-6` ou `claude-opus-4-6`. Trivial. |
| **Multi-tenant** | 🟢 BAIXO (pra agora) | Brain assume só Thales. Quando outras pessoas (Maria/Joao) usarem, precisa contexto por user. Não é blocker pra V1. |

### O desenho final que essa descoberta sugere

```
                    ┌──────────────────────────────────────┐
                    │      Thales Brain (uma só)           │
                    │   core/brain.py + tools/registry     │
                    └──────────────────────────────────────┘
                                      ▲
                                      │ IncomingMessage / OutgoingMessage
                                      │
        ┌─────────────┬────────────┬──┴──────┬────────────┬────────────┐
        │             │            │         │            │            │
   📱 WhatsApp   ✈️ Telegram   💬 Slack  🎮 Discord  🟣 Obsidian   💻 Terminal
   (Meta Cloud)   (Bot API)   (Events)  (gateway)   (file watch)   (CLI)
                                                         │
                                                         │ ler/escrever .md
                                                         ▼
                                              Vault PITOS (ou CHAIRMAN)
                                              /Inbox - Claudin/
                                              ├─ thread-001.md
                                              ├─ thread-002.md
                                              └─ ...
```

**Tradução prática**: você manda áudio no WhatsApp do número do Thales-agent, ele transcreve, pensa, responde. Você escreve numa nota do Obsidian, ele lê, pensa, escreve a resposta no mesmo arquivo. Você manda /comando no Telegram, ele entende. **Mesmo cérebro. Mesma memória. Quatro bocas.**

---

## 5. Decisões — placar final ✅ 7/7 fechadas, plano aprovado

| # | Tema | Status | Escolha |
|---|------|:------:|---------|
| 01 | Vitória de 30 dias do DAP4.0 | 🟢 | **E** — Limpar a casa primeiro |
| 02 | DAP4.0 ↔ thales-agent | 🟢 | **B** — thales-agent chama DAP4.0 via tools HTTP |
| 03 | Centro do OS pessoal | 🟢 | **A** — [[HOME]] é o centro |
| 04 | Modelo do canal Obsidian | 🟢 | **A** — Folder de threads `Inbox - Claudin/` |
| 05 | Vault unificado ou 2 vaults | 🟢 | **A** — PITOS é o único vault |
| 06 | WhatsApp Evolution vs Meta | 🟢 | **C** — Manter os dois (regra técnica: pessoal ≠ Business) |
| 07 | Telefones e linhas WhatsApp | 🟢 | **Ambas a configurar**: Ana (Meta Cloud, Business) + thales-agent (Evolution, pessoal) |

> [!success] Plano da Operação Limpeza **aprovado** pelo Lobo em 09/04/2026.
> Spec formal escrito em `Inbox - Claudin/000-spec-saida-30-dias.md`. Execução começa.

---

## 6. Decisões fechadas (com consequências)

### Decisão 01 — Vitória de 30 dias do DAP4.0 🟢 fechada → **E**

**Por que essa é a primeira pergunta:** sem uma vitória concreta a 30 dias, qualquer plano vai virar lista de desejos. Eu preciso saber pra qual horizonte estou compactando os 25 fixes pendentes + os agentes stub + a limpeza do banco + o rename + o deploy.

Eu te dei 4 opções no terminal antes de você abrir o vault pra mim. Agora que eu vi o estado real, **eu refino as opções** baseado no que existe — e adiciono uma quinta que só faz sentido depois de ver o DATABASE_MAP.

| Opção | O que é | Pra quê serve | Custo de execução |
|-------|---------|---------------|-------------------|
| **A. Operacional interno** | Em 30 dias, um lead WhatsApp real → Ana responde → registra no Kommo → aparece no `04_CLIENTS` → você vê no dashboard sem mock. End-to-end, **um único fluxo verdadeiro**. | Provar que o sistema faz o que promete. Você usa todo dia. | Médio. Exige Ana implementada (hoje stub) + supabase-py async (já fiz) + Meta WhatsApp produção. |
| **B. Hardening + observabilidade** | Não foca em features. Foca em ficar shippable: limpar `dashboard/agents/`, multi-tenancy, token budget, deploy VPS funcionando, agentes stub completos. | Tirar o lastro técnico antes de qualquer coisa nova. | Alto em escopo, baixo em risco. |
| **C. 5 agentes completos** | Fechar Ana + Sofia + Thales + Insights nos 30 dias. Hardening fica pra depois. | Demonstrabilidade. 5 agentes funcionando = vídeo, pitch, prova de tese. | Alto. Cada agente é seu próprio mundo. |
| **D. Vender** | DAP4.0 atende você + 3 outras oficinas pagantes. Foco em onboarding, billing, isolamento de dados. | Receita recorrente externa. | Muito alto. Multi-tenant real exige reescrita de várias coisas. |
| **E. Limpar a casa primeiro** ⭐**ESCOLHIDA** | Antes de tudo, **executar as 4 fases do plano de limpeza do [[DATABASE_MAP]]**, reorganizar o vault em uma estrutura sã, e renomear `doctor-ai-dashboard` → `dap4` no disco e no git. **30 dias só consolidando o que existe.** Nada novo é construído. | Sair do estado "tudo bagunçado isso ai". Calar a sensação de caos antes de qualquer movimento estratégico. | Baixo em risco, alto em ROI mental. Você ganha clareza pra escolher A/B/C/D depois com cabeça limpa. |

> [!success] Decisão fechada: **E**
> O Lobo escolheu calar o caos antes de avançar. Operação limpeza começa agora.

**Consequências:**
- Os próximos 30 dias têm **3 frentes de limpeza** (banco, vault, código), nenhuma feature nova entra sem ser pra suportar essas 3.
- A vitória de 30 dias é: **"abro o sistema, abro o vault, abro o git, e nada mais me dá raiva."** Métrica subjetiva mas honesta.
- Roadmap detalhado nas seções 7+ desta nota.

---

### Decisão 02 — Como DAP4.0 e thales-agent se relacionam? 🟢 fechada → **B**

| Opção | O que é | Tradeoff |
|-------|---------|----------|
| A. Cérebros independentes | Não se conhecem. | Sem sinergia. |
| **B. thales-agent chama DAP4.0 via tools** ⭐**ESCOLHIDA** | thales-agent ganha tools `dap4_query_lead`, `dap4_open_os`, `dap4_summary_today` que batem no gateway do DAP4.0 via HTTP autenticado. | Bom isolamento, ótima sinergia. |
| C. Um cérebro só | Funde tudo. | Caro, perde foco. |

> [!success] Decisão fechada: **B**

**Consequências:**
- thales-agent fica como **cliente HTTP** do gateway DAP4.0. Mesma chave de auth (`API_SECRET`).
- Precisa criar `tools/dap4.py` no thales-agent com pelo menos: `dap4_query_lead(phone_or_name)`, `dap4_open_os(client_id, descricao)`, `dap4_summary_today()`, `dap4_pending_actions()`.
- DAP4.0 não muda nada — só precisa que o gateway esteja exposto via Cloudflare Tunnel pra rede interna ou loopback `localhost:3001`.
- Vira tarefa do Phase 3 da Operação Limpeza (depois que dap4 estiver renomeado e deployado).

---

### Decisão 03 — Onde mora o "centro" do sistema operacional pessoal? 🟡 aberta (depende da 01)

[[HOME]] vs [[Brain_OS]] vs [[Canvas_OS]] vs [[Inbox_OS]] — só tem que ter **um**. Espera fechar a 01.

---

### Decisão 04 — Channel Obsidian: qual o modelo de "inbox"? 🟢 fechada → **A**

| Modelo | Como funciona |
|--------|---------------|
| **A. Folder de threads** ⭐**ESCOLHIDA** | `Inbox - Claudin/thread-XXX.md` — cada conversa é um arquivo. File watcher monitora a pasta inteira. Convenção: bloco `## 🧑 Thales` = você escreveu, bloco `## 🐺 Claudin` = agente respondeu. Última seção sem resposta = pendente. |
| B. Nota fixa | Uma nota só, vira monstro. |
| C. Daily note | Conversas atravessam dias. |
| D. Wikilink callbacks | Complexo demais. |

> [!success] Decisão fechada: **A**

**Consequências:**
- Quando a Operação Limpeza chegar na Phase 5 (canal Obsidian do thales-agent), vamos criar `Inbox - Claudin/` na raiz do vault PITOS.
- A nota atual `Sem título 2.md` **vira a thread `001-arquitetura-saida.md`** dentro da `Inbox - Claudin/` — preserva o histórico desta conversa como a primeira oficial do canal.
- Convenção de blocos:
  ```markdown
  ## 🧑 Thales · 2026-04-09 14:30
  Sua mensagem aqui
  
  ## 🐺 Claudin · 2026-04-09 14:31
  Resposta do agente
  ```
- File watcher vai usar **modificação de arquivo + parsing do último bloco `## 🧑 Thales` sem resposta `## 🐺 Claudin` abaixo**. Simples e robusto.

---

### Decisão 05 — Vault unificado ou 2 vaults? 🟢 fechada → **A**

| Opção | O que fazer |
|-------|-------------|
| **A. Unificar em PITOS** ⭐**ESCOLHIDA** | Atualizar `thales-agent/.env` pra `VAULT_PATH=...\CHAIRMAN\PITOS`. Migrar pastas que o agente precisa (`10 Quick Notes`, `00 Daily Notes`, `09 Coaching`) pra dentro do PITOS. CHAIRMAN vira só pasta-mãe. |
| B. Unificar em CHAIRMAN | Inverso. |
| C. Manter 2 vaults | Agente apontando pros 2. |

> [!success] Decisão fechada: **A**

**Consequências:**
- **PITOS é o único vault Obsidian** daqui pra frente. CHAIRMAN vira só pasta-mãe (não é mais um vault).
- Atualização imediata: `thales-agent/.env` muda `VAULT_PATH=C:\Users\docto\OneDrive\Documentos\CHAIRMAN` → `VAULT_PATH=C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS`.
- Migração de pastas que o thales-agent espera encontrar (do código `tools/vault.py` e `scheduler/watcher.py`):
  - `10 Quick Notes/` — criar em PITOS se não existir
  - `00 Daily Notes/` — criar em PITOS se não existir
  - `09 Coaching/thales-tasks.md` — criar em PITOS, formato Obsidian checklist
- Se houver conteúdo legado em `CHAIRMAN/10 Quick Notes`, `CHAIRMAN/00 Daily Notes`, `CHAIRMAN/09 Coaching` (fora do PITOS), a gente migra pra dentro do PITOS na Phase 1 da Operação Limpeza.
- **Verificar primeiro**: se o CHAIRMAN tem um `.obsidian/` próprio (ou seja, ele é um vault Obsidian também), a gente desativa esse vault no Obsidian app pra eliminar confusão.

---

### Decisão 06 — WhatsApp: Evolution API ou Meta Cloud API? 🟢 fechada → **C** (por restrição técnica)

> [!warning] Restrição arquitetural revelada
> O número pessoal do Thales **não é WhatsApp Business**, e Meta Cloud API exige número Business. Isso elimina A automaticamente. Não é uma escolha, é uma restrição da plataforma Meta.

| Opção | Status |
|-------|--------|
| ~~A. Padronizar em Meta Cloud~~ | ❌ Impossível: número pessoal ≠ Business |
| ~~B. Padronizar em Evolution~~ | ❌ Volta o que DAP4.0 deprecou conscientemente |
| **C. Manter os dois** ⭐**ESCOLHIDA** | Não por status quo. Por **arquitetura correta** pro caso de uso de cada um. |

**Regra arquitetural permanente:**

| Quem | Cliente WhatsApp | Por quê |
|------|------------------|---------|
| **DAP4.0 / Ana** | Meta Cloud API + Graph v21.0 | Atende clientes da Doctor Auto Prime. Número Business. Escala, oficial, templates aprovados, sem risco de ban, multi-agente em rotação. |
| **thales-agent** | Evolution API (Baileys) | Atende **só você** no seu número pessoal. Chat 1-pra-1. Não precisa template, não precisa escalar, não precisa Business. |

**Consequências:**
- A duplicação de cliente WhatsApp **deixa de ser dívida e vira regra**. Documentar isso no `CLAUDE.md` da raiz e no `dashboard/agents/DEPRECATED.md`.
- Manutenção: 2 SDKs separados, mas com responsabilidades disjuntas.
- Risco: Evolution API depende do WhatsApp Web — se a Meta apertar o cerco contra clientes não-oficiais, o thales-agent quebra. **Mitigation**: ter Telegram como canal redundante (já implementado).

---

### Decisão 07 — Telefones e linhas WhatsApp 🟡 parcial

A Decisão 06 já estabeleceu o quadro: **2 números diferentes**. Mas falta confirmar o estado atual:

| Linha | Cliente | Estado |
|-------|---------|--------|
| **Ana — DAP4.0** | Meta Cloud API (número Business da Doctor Auto Prime) | ❓ Já tem? Já tá no Meta Business Portfolio? Já passou pelo `META_SETUP_GUIDE.md`? |
| **Thales-agent** | Evolution API (seu número pessoal) | ❓ Evolution já tá rodando? QR code já scanneado? Sessão ativa? |

> [!question] **Pendente pra você responder:**
> - Status atual da linha Ana (DAP4.0 / Meta)
> - Status atual da linha Thales-agent (Evolution / pessoal)
> - Se uma das duas não tá pronta, isso vira sub-task da Operação Limpeza.

---

## 5. Memória que eu salvei nessa sessão

Pra eu não ter que perguntar de novo nas próximas conversas:

- Você é o Thales, fundador/CTO da Doctor Auto Prime (DAP). Persona: Lobo Estrategista.
- Vault: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS`
- DAP4.0 = ex-`doctor-ai-dashboard`, hub de IA do ecossistema da oficina. Referência: Indústria 4.0.
- Supabase project ID: `acuufrgoyjwzlyhopaus` (Postgres 17.6, 52 tabelas)
- 3 projetos de código em `C:\dev`: dap4 (P1), thales-agent (P2), coach (despriorizado)
- 5 frentes ativas semanais: Antigravity, Claude Code, Obsidian, Oficina, Conteúdo
- Sistema de revisão semanal aos domingos 18h (definido no [[HOME]])

---

---

## 7. Operação Limpeza — Plano emergente de 30 dias (09/04 → 09/05)

> [!abstract] Tese
> Durante 30 dias, **nenhuma feature nova entra**. O foco é tirar o lastro. No fim do mês, você abre o sistema, abre o vault, abre o git, e nada te dá raiva. A partir daí, tudo que você construir cai em terreno firme.

### Phase 0 — Pré-flight (dia 1 = HOJE, 09/04)

- [x] Auditoria completa via `/hm-qa /hm-engineer /hm-designer /hm-fix` (feita)
- [x] 25 fixes aplicados, 4 commits temáticos no DAP4.0 (feitos)
- [x] Mapeamento do thales-agent — descoberta do estado 80% pronto (feita)
- [x] Esta nota com decisões fechadas (D01, D02, D04, D05, D06)
- [ ] Confirmar Decisão 03 e 07 com Thales

### Phase 1 — Vault PITOS unificado (dias 2-4)

**Objetivo:** Sair de 2 vaults aninhados pra 1 vault organizado, com pastas que o thales-agent precisa.

- [ ] Verificar se `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\.obsidian/` existe (i.e., se CHAIRMAN é vault separado)
  - Se sim: desativar no Obsidian app (não deletar — só remover da lista de vaults)
- [ ] Mover/criar pastas dentro do `PITOS`:
  - `10 Quick Notes/`
  - `00 Daily Notes/`
  - `09 Coaching/thales-tasks.md` (template de checklist scheduler)
  - `Inbox - Claudin/` (pasta nova pro canal Obsidian, vazia ainda)
- [ ] Migrar conteúdo legado do CHAIRMAN root pra dentro do PITOS (se houver)
- [ ] Resolver Russian dolls de pasta: achatar `PITOS/PITOCOLOCO/CHAIRMAN/...` numa estrutura sã
- [ ] Decidir Decisão 03 (centro do OS pessoal) e fixar **uma** dashboard como home
- [ ] Mover esta nota pra `Inbox - Claudin/001-arquitetura-saida.md` (preserva histórico como primeira thread)
- [ ] Atualizar `thales-agent/.env`: `VAULT_PATH=C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS`
- [ ] Smoke test: rodar `python -m core.cli` no thales-agent e chamar `vault_quick_note("teste")` — confirmar que cria a nota no PITOS

### Phase 2 — Banco Doctor Prime limpo (dias 5-9)

**Objetivo:** Executar as 4 fases do plano de limpeza já documentadas no [[DATABASE_MAP]].

- [ ] **Backup completo** do Supabase project `acuufrgoyjwzlyhopaus` antes de qualquer DROP
- [ ] Phase 1 do DATABASE_MAP — Auditar dados únicos nas tabelas legacy (`Cliente`, `Veiculo`, `OrdemServico`)
- [ ] Migrar dados únicos das legacy pras oficiais (`04_CLIENTS`, `05_VEHICLES`, `06_OS`)
- [ ] Phase 2 — Wipe dados de teste das oficiais (apenas se o Thales confirmar que são dados de teste)
- [ ] Phase 3 — DROP das 22 tabelas legacy/duplicadas/portal-específicas
- [ ] Consolidar `rag_documents` vs `rag_documentos` (manter `rag_documents`)
- [ ] Phase 4 — Criar consultor `Consultor_thales` em `01_colaboradores`
- [ ] Verificar que `verify_staff_login` continua funcionando após cleanup
- [ ] Documentar schema final em `DATABASE_MAP.md` v2

### Phase 3 — DAP4.0 (rename + deploy + integração) (dias 10-17)

**Objetivo:** `doctor-ai-dashboard` deixa de existir como nome. Vira `dap4`. Roda em VPS via Cloudflare Tunnel.

- [ ] Rename físico: `C:\dev\doctor-ai-dashboard` → `C:\dev\dap4` (operação isolada com git)
- [ ] Atualizar todos os paths em scripts, Makefile, docker-compose, CI
- [ ] Atualizar nome em `package.json`, `pyproject.toml`, `gateway/package.json`
- [ ] **DELETAR `dashboard/agents/`** num commit isolado destrutivo (já marcado DEPRECATED)
- [ ] Provisionar VPS (recomendação: Hetzner CX32 €12.90/mês — 4 vCPU, 8 GB RAM, 80 GB SSD NVMe)
- [ ] Configurar Cloudflare Tunnel:
  - `dap.doctorautoprime.com.br` → `dashboard:80`
  - `api.dap.doctorautoprime.com.br` → `gateway:3001`
  - `webhook.dap.doctorautoprime.com.br` → `gateway:3001` (Meta WhatsApp)
- [ ] Setup `.env` de produção a partir do `.env.example`
- [ ] `make prod-tunnel` — primeiro deploy
- [ ] Smoke test: dashboard carrega, gateway responde, agents healthy, Chroma healthy
- [ ] **Configurar linha Meta WhatsApp Business pra Ana** (sub-tasks da Decisão 07):
  - [ ] Criar/verificar Meta Business Portfolio pra Doctor Auto Prime
  - [ ] Criar WhatsApp Business Account (WABA) dentro do portfolio
  - [ ] Registrar número Business da empresa (se ainda não tem, adquirir um novo)
  - [ ] Gerar permanent access token com escopo `whatsapp_business_messaging` + `whatsapp_business_management`
  - [ ] Coletar 5 credenciais: `META_PHONE_NUMBER_ID`, `META_ACCESS_TOKEN`, `META_APP_SECRET`, `META_VERIFY_TOKEN`, `META_WABA_ID`
  - [ ] Adicionar no `.env` de produção do DAP4.0
  - [ ] Configurar webhook do WABA apontando pra `webhook.dap.doctorautoprime.com.br/api/meta/webhook`
  - [ ] Setup verificação inicial (Meta verifica o webhook token)
  - [ ] Templates iniciais aprovados pra marketing/serviço (pelo menos 1 de boas-vindas)
  - [ ] Smoke test end-to-end: cliente manda WhatsApp pro número Ana → chega no webhook → Ana responde

### Phase 4 — thales-agent canal Obsidian + integração DAP4.0 + linha WhatsApp pessoal (dias 18-24)

**Objetivo:** Implementar o que falta no thales-agent — canal Obsidian + tools que conversam com DAP4.0 + ativar a linha WhatsApp pessoal via Evolution.

- [ ] **Configurar Evolution API pro número pessoal do Thales** (sub-tasks da Decisão 07):
  - [ ] Subir container Evolution API na mesma VPS (network isolada do DAP4.0)
  - [ ] Criar instance Evolution pro Thales
  - [ ] Scannear QR code com o WhatsApp do celular pessoal do Thales (processo manual, 1x)
  - [ ] Persistir sessão em volume Docker nomeado (`thales_agent_evolution_session`)
  - [ ] Coletar credenciais: `EVOLUTION_URL`, `EVOLUTION_API_KEY`, `EVOLUTION_INSTANCE`
  - [ ] Adicionar no `.env` de produção do thales-agent
  - [ ] Configurar webhook Evolution apontando pra `http://thales-agent:8500/webhook/whatsapp` (rede Docker interna)
  - [ ] Smoke test: você manda mensagem pro seu próprio WhatsApp de outro número → thales-agent responde
  - [ ] **Risk:** WhatsApp pode banir clientes não-oficiais → fallback documentado: Telegram é canal redundante
- [ ] Criar `channels/obsidian/__init__.py` com:
  - File watcher em `vault/Inbox - Claudin/` (usando `watchdog` lib)
  - Parser de blocos `## 🧑 Thales` / `## 🐺 Claudin`
  - Quando arquivo modificado → identifica último bloco do Thales sem resposta → cria `IncomingMessage(channel=OBSIDIAN, ...)` → manda pro brain
  - Quando brain responde → faz append de bloco `## 🐺 Claudin · timestamp` no mesmo arquivo
- [ ] Atualizar `main.py` pra inicializar canal Obsidian no lifespan
- [ ] Atualizar modelo: `core/brain.py:61` `claude-sonnet-4-20250514` → `claude-sonnet-4-6` (ou `claude-opus-4-6` se quiser mais raciocínio)
- [ ] Persistir `_conversations` em Postgres (mesmo banco do DAP4.0, schema separado `thales_agent.conversations`)
- [ ] Criar `tools/dap4.py` com:
  - `dap4_query_lead(phone_or_name)` — GET `api.dap.doctorautoprime.com.br/api/dashboard/leads?search=...`
  - `dap4_open_os(client_id, descricao)` — POST `/api/os/create`
  - `dap4_summary_today()` — GET `/api/dashboard/metrics`
  - `dap4_pending_actions()` — GET `/api/sofia/pending`
- [ ] Smoke test: você manda WhatsApp "qual o status do lead Carlos?" → thales-agent chama `dap4_query_lead("Carlos")` → responde com dados reais

### Phase 5 — Hardening + observabilidade compartilhada (dias 25-30)

**Objetivo:** Os 2 sistemas rodando na mesma VPS, com monitoramento de custo e operação previsível.

- [ ] Deploy do thales-agent na mesma VPS, network Docker isolada
- [ ] Postgres compartilhado: schemas `dap4_*` e `thales_agent_*`
- [ ] Redis compartilhado pra rate limit (DAP4.0) e state (thales-agent)
- [ ] Loki + Grafana em container compartilhado:
  - 3 dashboards: DAP4.0 ops, thales-agent ops, **custo de LLM** (somando os dois)
- [ ] Implementar token usage logging em **ambos** (já implementado no DAP4.0 em 09/04, falta no thales-agent)
- [ ] Configurar alerting básico: gasto LLM > X/dia → notifica via thales-agent
- [ ] Backup automatizado:
  - Postgres: dump diário pra S3/B2
  - ChromaDB: snapshot semanal
  - PITOS vault: já tá no OneDrive (sync)
- [ ] CI/CD: GitHub Actions roda pytest + vitest + tsc no DAP4.0, pytest no thales-agent
- [ ] **Documentar tudo** num `OPS_RUNBOOK.md` no PITOS — como subir, como parar, como debugar, como restaurar backup

### Métrica de sucesso (dia 30, 09/05)

> [!success] A vitória da Operação Limpeza
> No dia 09 de maio, eu (Thales) faço esse exercício:
>
> 1. Abro `C:\dev\` — vejo `dap4/` e `thales-agent/`. Não vejo nada bagunçado.
> 2. Abro o vault PITOS — vejo um vault, uma estrutura, um centro. Inbox - Claudin tem 5+ threads de conversa real.
> 3. Abro `dap.doctorautoprime.com.br` — dashboard carrega, dados reais, sem mock, sem erro.
> 4. Mando WhatsApp pessoal pro thales-agent: "qual o faturamento da semana?" — ele responde com dado real do DAP4.0.
> 5. Olho o dashboard de custo no Grafana: gasto LLM previsível, dentro do orçamento.
> 6. **Nada me dá raiva.**
>
> Se isso for verdade no dia 30, a Operação Limpeza venceu. A partir daí, qualquer feature nova cai em terreno firme.

---

## 8. Decisões finais (com consequências)

### Decisão 03 — Centro do OS pessoal 🟢 fechada → **A** ([[HOME]])

| Opção | |
|-------|-|
| **A. HOME é o centro** ⭐**ESCOLHIDA** | Já tem estrutura de painel semanal, métricas, frentes ativas, scorecard. |
| B. Nova INDEX.md | Não — vira mais um candidato sem matar os outros. |
| C. Brain_OS | Não. |
| D. Outra | Não. |

> [!success] Decisão fechada: **A**

**Consequências:**
- [[HOME]] é o **único** dashboard principal do vault. Única nota que você abre de manhã.
- [[Brain_OS]], [[Canvas_OS]], [[Inbox_OS]] viram **subpáginas** linkadas a partir de HOME, não centros independentes.
- [[ARQUETIPO]] fica como **referência** de persona linkada do HOME (seção "Identidade & Tom").
- Phase 1 da Operação Limpeza inclui: revisar HOME, adicionar seção de links pras subpáginas, e remover qualquer linguagem que sugira múltiplos centros.
- Home fica como **homepage do Obsidian** (Setting → Files & Links → Default location + Startup file).

---

### Decisão 07 — Telefones e linhas WhatsApp 🟢 fechada → **Ambas precisam ser configuradas**

| Linha | Cliente | Estado | Fase onde configura |
|-------|---------|--------|---------------------|
| **Ana — DAP4.0** | Meta Cloud API + Graph v21.0 | ❌ Precisa configurar | Phase 3 (sub-task explícita) |
| **thales-agent** | Evolution API (Baileys, número pessoal) | ❌ Precisa configurar | Phase 4 (sub-task explícita) |

> [!success] Decisão fechada: **Configurar ambas**

**Consequências:**
- Não há linha WhatsApp ativa hoje. Toda a integração WhatsApp é trabalho novo.
- Ana: seguir `META_SETUP_GUIDE.md` do DAP4.0 durante a Phase 3, antes do webhook ficar público via Cloudflare Tunnel.
- thales-agent: subir Evolution API localmente na VPS + scannear QR code do número pessoal do Thales + persistir sessão em volume Docker.
- Ambas entram como **sub-tasks explícitas** nas Phase 3 e Phase 4 da Operação Limpeza (seção 7).

---

## 9. Status do canal

> [!success] Brainstorming fechado. Execução começa.
> - 7/7 decisões fechadas
> - Plano aprovado
> - Spec formal escrito em **`Inbox - Claudin/000-spec-saida-30-dias.md`** (veja próxima seção do vault)
> - Pasta `Inbox - Claudin/` criada como primeira ação executiva da Phase 1
>
> **Próximo passo:** você abre o spec, revisa, e me fala:
> - **"tá bom, arranca a Phase 1"** → eu começo a executar (migração do vault, criação das pastas que o thales-agent precisa)
> - **"tem X pra ajustar"** → eu refino o spec antes de executar
>
> Esta nota (`Sem título 2.md`) vira `Inbox - Claudin/001-arquitetura-saida.md` quando você der o "go" — preservando todo o histórico desta sessão como a primeira thread oficial do canal.
