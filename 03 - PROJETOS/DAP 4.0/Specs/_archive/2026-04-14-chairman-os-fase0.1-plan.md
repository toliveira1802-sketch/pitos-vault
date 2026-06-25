# Chairman OS — Fase 0.1 (C1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the daily/weekly ritual layer of the Chairman OS — terminal commands `/manha` and `/noite`, Obsidian folder structure, templates, and live integrations with Google Calendar, ClickUp, and Supabase — so Thales can run the full ritual for 5 consecutive days.

**Architecture:** Zero-code solution. Obsidian is the persistence layer (pure markdown in `PITOS/Chairman OS/`). Claude Code is the orchestrator — two slash commands are authored as markdown instruction files in `~/.claude/commands/`. Data integrations happen at runtime via existing MCPs (ClickUp, Supabase) plus a newly installed Google Calendar MCP.

**Tech Stack:** Obsidian vault (file system), Claude Code slash commands (markdown), ClickUp MCP (active), Supabase MCP (active), Google Calendar MCP (to install).

**Spec reference:** `PITOS/DAP 4.0/Specs/2026-04-14-chairman-os-design.md`

**Out of scope for this plan:** WhatsApp agent (C2 — Fase 0.2), proactive scheduler (C3 — Fase 0.3).

---

## File structure (to be created)

```
C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/
├── README.md                         (navigation + usage)
├── Daily/                            (empty; populated by /manha)
├── Weekly/                           (empty; populated Friday by /noite)
├── Monthly/                          (empty; populated by manual rollup)
├── Quarterly/                        (empty; populated by manual rollup)
├── Inbox/
│   └── inbox.md                      (capture log, append-only, triaged weekly)
├── Decisions/
│   └── decisions.md                  (decision log, append-only)
└── _templates/
    ├── daily.md
    ├── weekly.md
    ├── monthly.md
    └── quarterly.md

~/.claude/commands/
├── manha.md                          (slash command: morning ritual)
└── noite.md                          (slash command: evening ritual)
```

---

## Task 1: Create Chairman OS folder structure in vault

**Files:**
- Create: `C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/` + subfolders
- Create: `PITOS/Chairman OS/README.md`

- [ ] **Step 1: Create the folder tree**

Run:
```bash
mkdir -p "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/Daily" \
         "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/Weekly" \
         "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/Monthly" \
         "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/Quarterly" \
         "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/Inbox" \
         "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/Decisions" \
         "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/_templates"
```

Expected: command returns silently, no errors.

- [ ] **Step 2: Verify folder creation**

Run:
```bash
ls "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/"
```
Expected output: `Daily  Decisions  Inbox  Monthly  Quarterly  Weekly  _templates`

- [ ] **Step 3: Write README.md**

Create `Chairman OS/README.md` with content:

```markdown
# Chairman OS

> Personal OS do Thales · fundido com operação DAP · evidência > relato.

## Estrutura
- `Daily/` — notas diárias (abertura em `/manha`, fechamento em `/noite`)
- `Weekly/` — revisões semanais (fechadas sexta à noite)
- `Monthly/` — rollups mensais
- `Quarterly/` — rollups trimestrais + OKRs das unidades DAP
- `Inbox/` — capturas brutas (triagem semanal)
- `Decisions/` — log de decisões estratégicas
- `_templates/` — templates dos arquivos acima

## Como usar
- Manhã: rodar `/manha` no Claude Code (gera a daily note do dia)
- Durante o dia: (Fase 0.2+) capturar via WhatsApp
- Noite: rodar `/noite` (fecha a daily note + prepara amanhã)
- Sexta noite: `/noite` também fecha a weekly review
- Domingo noite: triagem da Inbox

## Princípios
1. Evidência > relato
2. Causa raiz > desculpa
3. Máximo 3 prioridades por dia
4. Silêncio OK
```

- [ ] **Step 4: Commit** *(if the vault is git-backed; skip if not)*

```bash
cd "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS"
git add "Chairman OS/"
git commit -m "feat(chairman-os): create folder structure and README"
```

---

## Task 2: Write daily note template

**Files:**
- Create: `Chairman OS/_templates/daily.md`

- [ ] **Step 1: Write the template**

Create `Chairman OS/_templates/daily.md` with:

```markdown
---
date: {{DATE}}
weekday: {{WEEKDAY}}
week: {{WEEK}}
status: open
followthrough: null
---

# {{DATE}} · {{WEEKDAY}}

## 🌅 Briefing

**Calendário hoje:**
{{CALENDAR_EVENTS}}

**Tasks ClickUp:**
- Abertas hoje: {{TASKS_TODAY}}
- Overdue: {{TASKS_OVERDUE}}

**KPIs DAP (snapshot 24h):**
- Faturamento MTD: {{REVENUE_MTD}}
- Leads últimas 24h: {{LEADS_24H}}
- OS abertas: {{OS_OPEN}}

**Carry-over de ontem:**
{{CARRY_OVER}}

## 🎯 Prioridades do dia

1. [ ] {{PRIORITY_1}}
2. [ ] {{PRIORITY_2}}
3. [ ] {{PRIORITY_3}}

## 📝 Morning pages

**{{QUESTION_1}}**
{{ANSWER_1}}

**{{QUESTION_2}}**
{{ANSWER_2}}

**{{QUESTION_3}}**
{{ANSWER_3}}

## 🌊 Log do dia

(capturas do C2 e momentos relevantes ao longo do dia)

## 🌙 Shutdown

**Audit de compromissos:**
{{AUDIT_RESULTS}}

**Follow-through:** {{FOLLOWTHROUGH}}%

**O que avançou:**
{{WHAT_ADVANCED}}

**O que travou (causa raiz):**
{{WHAT_BLOCKED}}

**Lição do dia:**
{{LESSON}}

**Gratidão:**
{{GRATITUDE}}

**Amanhã:** {{TOMORROW_PREVIEW}}
```

- [ ] **Step 2: Verify**

Run:
```bash
ls -la "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/_templates/daily.md"
```
Expected: file exists with non-zero size.

- [ ] **Step 3: Commit**

```bash
cd "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS"
git add "Chairman OS/_templates/daily.md"
git commit -m "feat(chairman-os): add daily note template"
```

---

## Task 3: Write weekly review template

**Files:**
- Create: `Chairman OS/_templates/weekly.md`

- [ ] **Step 1: Write the template**

Create `Chairman OS/_templates/weekly.md`:

```markdown
---
week: {{WEEK}}
date_range: {{DATE_RANGE}}
theme: "{{THEME}}"
status: open
avg_followthrough: null
---

# Semana {{WEEK_NUM}} · {{DATE_RANGE}}

## Tema / Foco
> "{{THEME}}"

## Números

| Dia | Prioridades | Done | Follow-through |
|---|---|---|---|
| Seg | {{MON_P}} | {{MON_D}} | {{MON_FT}}% |
| Ter | {{TUE_P}} | {{TUE_D}} | {{TUE_FT}}% |
| Qua | {{WED_P}} | {{WED_D}} | {{WED_FT}}% |
| Qui | {{THU_P}} | {{THU_D}} | {{THU_FT}}% |
| Sex | {{FRI_P}} | {{FRI_D}} | {{FRI_FT}}% |
| **Média** | | | **{{AVG_FT}}%** |

## KPIs DAP (delta vs semana anterior)

- Faturamento: {{REVENUE_DELTA}}
- Leads: {{LEADS_DELTA}}
- OS concluídas: {{OS_DELTA}}

## Wins

{{WINS}}

## Travas (causa raiz, não sintoma)

{{BLOCKERS}}

## Padrões que notei

{{PATTERNS}}

## Próxima semana

- **Tema:** {{NEXT_THEME}}
- **3 apostas:**
  1. {{NEXT_BET_1}}
  2. {{NEXT_BET_2}}
  3. {{NEXT_BET_3}}
```

- [ ] **Step 2: Commit**

```bash
cd "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS"
git add "Chairman OS/_templates/weekly.md"
git commit -m "feat(chairman-os): add weekly review template"
```

---

## Task 4: Write monthly and quarterly templates

**Files:**
- Create: `Chairman OS/_templates/monthly.md`
- Create: `Chairman OS/_templates/quarterly.md`

- [ ] **Step 1: Write monthly.md**

Create `Chairman OS/_templates/monthly.md`:

```markdown
---
month: {{MONTH}}
status: open
avg_followthrough: null
---

# {{MONTH_LABEL}}

## Destaque do mês
{{HIGHLIGHT}}

## Números consolidados
- Follow-through médio: {{AVG_FT}}%
- Faturamento DAP: {{REVENUE}}
- Leads totais: {{LEADS}}
- OS concluídas: {{OS}}
- Wins por unidade:
{{UNIT_WINS}}

## 3 aprendizados do mês
1. {{LESSON_1}}
2. {{LESSON_2}}
3. {{LESSON_3}}

## Decisões estruturais (ref. `Decisions/decisions.md`)
{{DECISIONS}}

## Ajustes no sistema (Chairman OS em si)
{{SYSTEM_ADJUSTMENTS}}

## Mês seguinte — foco
- **Tema:** {{NEXT_THEME}}
- **3 apostas estruturais:**
  1. {{NEXT_1}}
  2. {{NEXT_2}}
  3. {{NEXT_3}}
```

- [ ] **Step 2: Write quarterly.md**

Create `Chairman OS/_templates/quarterly.md`:

```markdown
---
quarter: {{QUARTER}}
status: open
---

# {{QUARTER_LABEL}}

## Visão do trimestre
{{VISION}}

## OKRs por unidade DAP

### Unidades operando
- **DAP Prime:** {{PRIME_OKR}}
- **DAP Performance:** {{PERFORMANCE_OKR}}

### Unidades estruturando
- **DAP Project:** {{PROJECT_OKR}}
- **DAP AI:** {{AI_OKR}}
- **DAP Dev:** {{DEV_OKR}}
- **DAP Studio:** {{STUDIO_OKR}}
- **DAP Social:** {{SOCIAL_OKR}}
- **DAP Ensina:** {{ENSINA_OKR}}
- **DAP Consultoria:** {{CONSULTORIA_OKR}}

## Resultado financeiro
- Faturamento trimestre: {{QTR_REVENUE}}
- Variação vs trimestre anterior: {{QTR_DELTA}}

## Decisões estruturais do trimestre
{{STRATEGIC_DECISIONS}}

## Próximo trimestre
- **Visão:** {{NEXT_VISION}}
- **3 grandes apostas:**
  1. {{NEXT_BET_1}}
  2. {{NEXT_BET_2}}
  3. {{NEXT_BET_3}}
```

- [ ] **Step 3: Commit**

```bash
cd "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS"
git add "Chairman OS/_templates/monthly.md" "Chairman OS/_templates/quarterly.md"
git commit -m "feat(chairman-os): add monthly and quarterly templates"
```

---

## Task 5: Initialize Inbox and Decisions logs

**Files:**
- Create: `Chairman OS/Inbox/inbox.md`
- Create: `Chairman OS/Decisions/decisions.md`

- [ ] **Step 1: Write inbox.md**

Create `Chairman OS/Inbox/inbox.md`:

```markdown
# Inbox — Chairman OS

> Capturas brutas (timestamped). Triadas semanalmente (domingo noite). Na Fase 0.1 o preenchimento é manual; na Fase 0.2 vira automático via C2 WhatsApp.

## 2026-04-14
(vazio — primeira entrada aparecerá aqui)
```

- [ ] **Step 2: Write decisions.md**

Create `Chairman OS/Decisions/decisions.md`:

```markdown
# Decisões — Chairman OS

> Log append-only de decisões estratégicas. Uma decisão por bloco. Nunca editar decisão passada — só adicionar revisão datada abaixo.

## Template de uma entrada

```
## YYYY-MM-DD — Título curto da decisão
**Contexto:** (situação que forçou a decisão)
**Decisão:** (o que foi decidido, verbo no passado)
**Razão:** (por quê — priorização, constraint, valor)
**Revisitar em:** (data ou gatilho)
```

## Decisões registradas

(nenhuma ainda)
```

- [ ] **Step 3: Commit**

```bash
cd "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS"
git add "Chairman OS/Inbox/inbox.md" "Chairman OS/Decisions/decisions.md"
git commit -m "feat(chairman-os): initialize inbox and decisions logs"
```

---

## Task 6: Install Google Calendar MCP

**Files:**
- Modify: `~/.claude/settings.json` (or equivalent MCP config)

- [ ] **Step 1: Check existing MCP config**

Run:
```bash
cat ~/.claude/settings.json 2>/dev/null || cat "C:/Users/docto/.claude/settings.json"
```
Expected: display current MCP server list. Note whether `google-calendar` or similar is already listed.

- [ ] **Step 2: Install Google Calendar MCP**

If not present, add to MCP config. Reference implementation: `@modelcontextprotocol/server-gcal` or community equivalent.

Run (via MCP install command):
```bash
claude mcp add google-calendar
```

If the command doesn't exist or requires manual config, edit `~/.claude/settings.json` and add a `mcpServers` entry (exact structure depends on the MCP package chosen — document the chosen package in the next step).

- [ ] **Step 3: Authenticate (OAuth)**

Follow the MCP's OAuth flow. Typically: a URL is printed, Thales opens it in browser, approves, token is cached locally.

- [ ] **Step 4: Smoke test — list today's events**

Restart Claude Code session, then test:
```
Use the Google Calendar MCP to list events for today (2026-04-14) on Thales's primary calendar.
```
Expected: list of calendar events (possibly empty if nothing scheduled, but no auth/permission errors).

- [ ] **Step 5: Commit config change**

```bash
cd ~/.claude
git add settings.json 2>/dev/null || echo "settings.json not in git (ok)"
git commit -m "feat(mcp): add google-calendar MCP for Chairman OS" 2>/dev/null || true
```

**Blocker condition:** if Google Calendar MCP cannot be installed or authenticated, skip ahead and mark Calendar integration as "manual paste" fallback in `/manha` — Thales describes events verbally at start of briefing. This does not block Fase 0.1 completion.

---

## Task 7: Author `/manha` slash command

**Files:**
- Create: `C:/Users/docto/.claude/commands/manha.md`

- [ ] **Step 1: Verify commands directory exists**

Run:
```bash
ls "C:/Users/docto/.claude/commands/" 2>/dev/null || mkdir -p "C:/Users/docto/.claude/commands/"
```
Expected: directory exists or is created.

- [ ] **Step 2: Write manha.md**

Create `C:/Users/docto/.claude/commands/manha.md`:

````markdown
---
description: Ritual de abertura do dia — Chairman OS. Briefing + triagem + morning pages + 3 prioridades.
---

# /manha — Ritual de Abertura

Você é o orquestrador do Chairman OS do Thales. Execute a rotina de abertura do dia, passo a passo, sem pular etapas.

## Variáveis de data

Antes de qualquer coisa, determine:
- `TODAY` = data de hoje (YYYY-MM-DD)
- `YESTERDAY` = data de ontem (YYYY-MM-DD)
- `WEEKDAY` = nome do dia da semana em português minúsculo (ex: "segunda")
- `WEEK` = semana ISO (ex: "2026-W15")
- Paths absolutos:
  - `VAULT = C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS`
  - `DAILY_TODAY = $VAULT/Daily/$TODAY.md`
  - `DAILY_YESTERDAY = $VAULT/Daily/$YESTERDAY.md`
  - `WEEKLY = $VAULT/Weekly/$WEEK.md`
  - `TEMPLATE = $VAULT/_templates/daily.md`
  - `INBOX = $VAULT/Inbox/inbox.md`

## Etapa 1 — Contexto silencioso (sem output ao usuário)

Leia em paralelo (se possível):
1. `DAILY_YESTERDAY` — extraia: prioridades NÃO concluídas (carry-over), lição do dia, follow-through
2. `WEEKLY` — extraia: tema da semana (se o arquivo existir)
3. `INBOX` — extraia: entradas desde `YESTERDAY` 00:00 ainda não triadas (sem tag `#triado`)
4. Via ClickUp MCP — busque tasks com due date = hoje OU overdue, owner = Thales
5. Via Google Calendar MCP — busque eventos de hoje no primary calendar (se MCP não disponível, pule e note no briefing)
6. Via Supabase MCP (projeto DAP4) — query KPIs das últimas 24h:
   - Faturamento MTD (soma `transactions.value` do mês)
   - Leads novos (count `leads` com `created_at > now() - interval '24 hours'`)
   - OS abertas (count `service_orders` com `status = 'open'`)
   Se schema real diferir, adapte; se falhar, registre "dados DAP indisponíveis" no briefing.

## Etapa 2 — Briefing

Apresente ao Thales (no terminal) uma mensagem estruturada com:

```
🌅 Bom dia, Thales. Hoje é [TODAY] · [WEEKDAY] · semana [WEEK]

**Tema da semana:** [tema extraído do WEEKLY, ou "ainda não definido — define agora?"]

**📅 Calendário hoje:**
- [eventos]

**✓ Tasks:**
- [N] abertas hoje · [M] overdue
- Destaques: [3 mais relevantes]

**📈 DAP (24h):**
- Faturamento MTD: [valor]
- Leads novos: [N]
- OS abertas: [N]

**↩️ Carry-over de ontem:**
- [pendências]
- Lição de ontem: "[lição]"
```

## Etapa 3 — Triagem da inbox

Se há entradas novas na Inbox:

```
Tem [N] capturas desde ontem. Vou passar uma por uma. Pra cada, fala:
- `t` = task (vai pro ClickUp)
- `d` = decisão (vai pro Decisions)
- `i` = ideia pra revisitar (fica no Inbox com tag #triado)
- `x` = descarta

[item 1]
>
```

Processe cada item conforme a resposta. Atualize os arquivos.

Se não há capturas, pule esta etapa.

## Etapa 4 — Morning pages dirigidas

Escolha 3 perguntas baseado no dia da semana:

- **Segunda:**
  1. Qual é a aposta da semana?
  2. Onde vai estar a fricção?
  3. Qual versão sua vai aparecer?
- **Terça / Quarta / Quinta:**
  1. O que tá mais vivo na cabeça agora?
  2. Qual é o próximo movimento real do ecossistema?
  3. Onde tô me enganando?
- **Sexta:**
  1. O que aprendi essa semana?
  2. O que vou parar de fazer?
  3. Se eu só pudesse fazer 1 coisa no fim de semana pro DAP, seria?
- **Sábado / Domingo:**
  1. Como foi a semana em 1 frase?
  2. O que mereceu atenção e não teve?
  3. Na próxima semana, começo fazendo o quê?

Faça uma pergunta por vez, espere a resposta, siga pra próxima. Se Thales responder muito curto, pode seguir — não force elaboração. Guarde as respostas pra escrita do arquivo.

## Etapa 5 — 3 prioridades do dia

Com base em: carry-over + tasks ClickUp overdue + eventos importantes + morning pages, proponha 3 prioridades assim:

```
Baseado no que você trouxe, proponho 3 prioridades:

1. [ação concreta] — [horário sugerido] — done quando: [critério]
2. [...]
3. [...]

Tá bom? Ajusta se quiser.
```

Ajuste conforme feedback. Lembre: NUNCA mais que 3.

## Etapa 6 — Escrita

Crie `DAILY_TODAY` usando `TEMPLATE` como base, substituindo todos os placeholders com os dados coletados. `status: open`, `followthrough: null`.

Confirme ao Thales:

```
✓ dia aberto · [DAILY_TODAY]
primeira prioridade: [P1] · começa [horário]
bom dia, thales.
```

## Regras

- Não pergunte nada fora dessas etapas. Sem chitchat.
- Se MCP falha, degrada graciosamente (registra "indisponível" no briefing, segue o resto).
- Tempo-alvo: ~20min de ponta a ponta (incluindo escrita livre do Thales).
- Nunca escreva mais de 3 prioridades, nem que Thales peça — force corte.
````

- [ ] **Step 3: Verify**

Run:
```bash
cat "C:/Users/docto/.claude/commands/manha.md" | head -20
```
Expected: frontmatter + first lines of the command visible.

- [ ] **Step 4: Commit**

```bash
cd "C:/Users/docto/.claude"
git add commands/manha.md 2>/dev/null || true
git commit -m "feat(chairman-os): add /manha slash command" 2>/dev/null || true
```

---

## Task 8: Author `/noite` slash command

**Files:**
- Create: `C:/Users/docto/.claude/commands/noite.md`

- [ ] **Step 1: Write noite.md**

Create `C:/Users/docto/.claude/commands/noite.md`:

````markdown
---
description: Ritual de fechamento do dia — Chairman OS. Audit por evidência + shutdown + prep de amanhã.
---

# /noite — Ritual de Fechamento

Você é o orquestrador do Chairman OS do Thales. Execute a rotina de fechamento do dia, passo a passo. Regra central: **evidência > relato**. Se dado diz que não foi feito, não foi feito — não negocie com desculpa.

## Variáveis de data

- `TODAY` = hoje (YYYY-MM-DD)
- `TOMORROW` = amanhã (YYYY-MM-DD)
- `WEEKDAY_TODAY` = dia da semana (ex: "segunda")
- `WEEK` = semana ISO (ex: "2026-W15")
- `IS_FRIDAY` = true se hoje é sexta
- Paths:
  - `VAULT = C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS`
  - `DAILY_TODAY = $VAULT/Daily/$TODAY.md`
  - `DAILY_TOMORROW = $VAULT/Daily/$TOMORROW.md`
  - `WEEKLY = $VAULT/Weekly/$WEEK.md`
  - `TEMPLATE_DAILY = $VAULT/_templates/daily.md`
  - `TEMPLATE_WEEKLY = $VAULT/_templates/weekly.md`

## Etapa 1 — Auditoria silenciosa

Leia `DAILY_TODAY` e extraia:
- As 3 prioridades declaradas
- Horário e critério de done de cada
- Log do dia (se houver)

Colete evidência via MCPs:
1. **ClickUp MCP** — tasks movidas pra `done` com completion date = hoje (dono = Thales)
2. **Google Calendar MCP** — eventos de hoje com status "attended" (ou o equivalente; se API não tem, listar eventos que ocorreram)
3. **Supabase MCP** — movimento do dia: leads novos hoje, OS abertas hoje, OS fechadas hoje, faturamento delta

Para cada prioridade declarada, determine status:
- ✅ done (evidência direta: task concluída, PR merged, evento comparecido)
- ⚠️ inconclusivo (sem evidência clara, Thales precisa confirmar)
- ❌ não feito (evidência de ausência)

## Etapa 2 — Confronto com dado

Apresente no terminal:

```
🌙 Fechamento · [TODAY]

**Auditoria das 3 prioridades:**
1. [texto] — [✅/⚠️/❌] [evidência curta, ex: "ClickUp #1234 concluída 11h50" ou "sem evidência no git"]
2. [...]
3. [...]

**Follow-through confirmado:** [X]%
**Follow-through tentativo (se ⚠️ confirmadas):** [Y]%
```

Se há ⚠️, pergunte item por item: "item N — você fez? (s/n/detalhe)". Atualize status.

## Etapa 3 — Shutdown dialogado

Para cada prioridade não concluída (❌), pergunte:

```
[prioridade] — causa raiz, não sintoma. por quê de verdade?
```

Se a resposta for sintoma (ex: "não tive tempo", "esqueci", "X me interrompeu"), re-pergunte UMA vez:
```
isso é o sintoma. o que de fato tirou o foco? estruturalmente?
```

Depois NÃO insiste mais — anota o que veio.

Depois faça, uma por vez:

1. "O que avançou hoje, fora da lista — mas foi real?" → guarde.
2. "Lição do dia em 1 frase." → guarde.
3. "Uma gratidão." → guarde.

## Etapa 4 — Preparação de amanhã

1. Leia `DAILY_TODAY` novamente — liste prioridades não concluídas como carry-over.
2. Via Google Calendar MCP — busque eventos de amanhã.
3. Se houver bloqueio necessário (ex: médico 15h), destaque: "amanhã tem X — vou bloquear Y-Z."
4. Pergunte: "alguma coisa específica que você quer lembrar amanhã no briefing?" → guarde nota.
5. Crie `DAILY_TOMORROW` a partir de `TEMPLATE_DAILY`:
   - `date: TOMORROW`, `weekday: [amanhã]`, `status: open`, `followthrough: null`
   - Seção Carry-over preenchida
   - Seção Briefing com nota: "preenchida em /manha"
   - Se há nota especial do passo 4, injete num bloco `> Lembrete do Thales: ...` no topo do Briefing

## Etapa 5 — Weekly roll-up (SOMENTE se `IS_FRIDAY`)

Se hoje é sexta:

1. Leia `DAILY` de cada dia da semana (segunda a sexta da `WEEK`).
2. Para cada dia, extraia: # prioridades declaradas, # done, follow-through.
3. Calcule média semanal.
4. Agregue wins e travas de cada daily.
5. Apresente no terminal o resumo numérico e pergunte:
   - "3 padrões que você notou essa semana?"
   - "O que vai carregar pra próxima semana como tema?"
   - "3 apostas da próxima semana?"
6. Crie/atualize `WEEKLY` a partir de `TEMPLATE_WEEKLY`. `status: closed` se fechando, `open` se continuando.
7. Crie `$VAULT/Weekly/[próxima semana ISO].md` com `status: open`, tema vazio.

## Etapa 6 — Escrita + fechamento

Atualize `DAILY_TODAY`:
- Preencha seção Shutdown com tudo coletado.
- `status: closed`
- `followthrough: [X]` (o % confirmado da etapa 2)

Confirme ao Thales:

```
✓ dia fechado · follow-through [X]%
amanhã: [N] compromissos · [M] carry-over · primeira ação sugerida [horário]
boa noite, thales.
```

## Regras

- Evidência > relato. Se o dado diz ❌, é ❌. Não troca.
- Causa raiz > desculpa. Re-pergunto 1x, depois aceito.
- Sem julgamento. Fato, não moral.
- Se MCP falha, pergunta direto ao Thales pra cada prioridade, mas anota "audit manual" no arquivo.
- Tempo-alvo: ~20min (25-30 em sexta com weekly).
````

- [ ] **Step 2: Verify**

Run:
```bash
cat "C:/Users/docto/.claude/commands/noite.md" | head -20
```
Expected: frontmatter + first lines visible.

- [ ] **Step 3: Commit**

```bash
cd "C:/Users/docto/.claude"
git add commands/noite.md 2>/dev/null || true
git commit -m "feat(chairman-os): add /noite slash command" 2>/dev/null || true
```

---

## Task 9: End-to-end smoke test (abertura)

**Goal:** rodar `/manha` uma vez de verdade, verificar que o arquivo é criado corretamente.

- [ ] **Step 1: Reload Claude Code session**

Feche e reabra o Claude Code pra carregar os novos slash commands.

- [ ] **Step 2: Execute /manha**

No terminal do Claude Code, rode:
```
/manha
```

Acompanhe as 6 etapas. Responda as morning pages (pode ser bem curto — o objetivo é testar o fluxo, não ter uma sessão profunda).

- [ ] **Step 3: Verify daily note was created**

Run:
```bash
ls "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Chairman OS/Daily/"
```
Expected: arquivo `YYYY-MM-DD.md` (data de hoje) presente.

Abra e confira:
- Frontmatter preenchido (date, weekday, week, status=open, followthrough=null)
- Seção Briefing tem dados reais (calendário, tasks, KPIs — ou placeholders "indisponível" onde MCP falhou)
- 3 prioridades escritas com horário e critério de done
- Morning pages com perguntas e respostas
- Log do dia vazio (placeholder)
- Shutdown vazio (placeholder)

- [ ] **Step 4: Document any failures**

Se algum MCP falhou, crie issue em `PITOS/DAP 4.0/Notas/013-chairman-os-fase0.1-issues.md` descrevendo:
- Qual MCP
- Qual erro
- Workaround aplicado

- [ ] **Step 5: Commit daily note**

```bash
cd "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS"
git add "Chairman OS/Daily/"
git commit -m "chore(chairman-os): first smoke test /manha run"
```

---

## Task 10: End-to-end smoke test (fechamento)

**Goal:** rodar `/noite` no fim do mesmo dia (ou no dia seguinte simulando o dia de teste), verificar audit + carry-over + geração de amanhã.

- [ ] **Step 1: Execute /noite**

No final do dia, no terminal:
```
/noite
```

- [ ] **Step 2: Verify audit behavior**

Confirme que:
- O agente leu as 3 prioridades declaradas de manhã
- Puxou evidência de ClickUp/Calendar/Supabase
- Apresentou status ✅/⚠️/❌ pra cada prioridade
- Perguntou causa raiz pras não concluídas
- Conduziu as 3 perguntas finais (avanços, lição, gratidão)

- [ ] **Step 3: Verify file updates**

Abra `Daily/[hoje].md` e confira:
- `status: closed`
- `followthrough` preenchido com número
- Seção Shutdown completa

Abra `Daily/[amanhã].md` e confira:
- Arquivo existe
- `status: open`, `followthrough: null`
- Carry-over preenchido
- Nota especial do passo 4 (se houver) visível no topo

- [ ] **Step 4: Se hoje é sexta, verify weekly roll-up**

Abra `Weekly/[semana].md` e confira:
- Tabela de dias preenchida
- Média semanal calculada
- Próxima semana criada em `Weekly/[próxima].md` com status open

- [ ] **Step 5: Commit**

```bash
cd "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS"
git add "Chairman OS/"
git commit -m "chore(chairman-os): first smoke test /noite run + carry-over"
```

---

## Task 11: 5-day dogfood run

**Goal:** confirmar que o sistema aguenta uso real por uma semana.

- [ ] **Step 1: Executar /manha e /noite por 5 dias úteis seguidos**

Sem pular. Se um dia pular, anotar motivo em issues.

- [ ] **Step 2: Na sexta, confirmar weekly gerada**

Abra `Weekly/[semana].md` — tabela completa de 5 dias, média, wins/travas agregados.

- [ ] **Step 3: Ao final dos 5 dias, escrever auto-avaliação**

Crie `PITOS/DAP 4.0/Notas/014-chairman-os-fase0.1-retro.md`:

```markdown
# Chairman OS — Fase 0.1 — Retrospectiva

**Data:** [YYYY-MM-DD]

## Critérios de sucesso
- [ ] 5 dias consecutivos com /manha + /noite executados
- [ ] Daily notes fechadas com followthrough preenchido
- [ ] "Abro o dia sem caos": sim/não
- [ ] "Fecho sabendo o que avançou": sim/não

## O que funcionou
- ...

## O que atrapalhou
- ...

## Ajustes antes da Fase 0.2
- ...

## Seguir pra Fase 0.2 (C2 WhatsApp)?
- Sim / Não / Ajustar primeiro
```

- [ ] **Step 4: Commit retrospectiva**

```bash
cd "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS"
git add "DAP 4.0/Notas/014-chairman-os-fase0.1-retro.md" "Chairman OS/"
git commit -m "docs(chairman-os): fase 0.1 retro após 5 dias de dogfood"
```

---

## Completion criteria

Fase 0.1 está completa quando:
1. Estrutura de pastas e templates existe em `PITOS/Chairman OS/`
2. `/manha` e `/noite` funcionam end-to-end com MCPs integrados (ou degradação graciosa documentada)
3. 5 daily notes consecutivas com `status: closed` e `followthrough` numérico preenchido
4. Retrospectiva escrita com decisão explícita de seguir pra Fase 0.2 ou ajustar

## Next step

Após retrospectiva positiva → invocar `writing-plans` novamente pra criar plan da **Fase 0.2 (C2 WhatsApp)**.
