---
title: Sennin Protocol — Operating System do Thales
owner: Thales
status: v1-draft
created: 2026-04-15
updated: 2026-04-15
tags: [sistema, protocolo, dap4, claude-code, c-level]
---

# Sennin Protocol

Sistema operacional pessoal e profissional do Thales rodando sobre Claude Code + ECC + C-Level v2.
Base: muscle memory (protocolo fixo) > catálogo (browsing).
Padrão: world-class, inegociável.

---

## 1. Arquitetura em 4 camadas

```
┌──────────────────────────────────────────────────────────┐
│  CAMADA 1 — BASELINE META (sempre ligado, invisível)     │
│  token · autohealing · learning · memory                  │
├──────────────────────────────────────────────────────────┤
│  CAMADA 2 — SLASH COMMANDS (ação direta, muscle memory)  │
│  /pessoal-* · /manha · /noite · /plan · /hm-* · /super*  │
├──────────────────────────────────────────────────────────┤
│  CAMADA 3 — C-LEVEL v2 (Sophia + 12 diretores)           │
│  Estratégia, análise, decisão contextual                  │
├──────────────────────────────────────────────────────────┤
│  CAMADA 4 — TOOLS (built-in + MCPs lazy-loaded)          │
│  Invocadas pelos diretores conforme tema                  │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Baseline Meta (responsabilidade do Claude, sempre ligado)

### 2.1 Economia de token
- `strategic-compact` em pontos naturais (fim de fase)
- `search-first` antes de escrever qualquer coisa
- `Explore` agent para buscas amplas (queima contexto dele, não o do usuário)
- `iterative-retrieval` — refinar, não despejar
- `token-budget-advisor` antes de resposta longa

### 2.2 Autohealing
- `systematic-debugging` em toda falha (sem tentativa cega)
- `verification-before-completion` antes de afirmar "feito"
- `build-fix` / `hm-fix` ciclando até passar
- `agent-introspection-debugging` quando subagente falha

### 2.3 Aprendizado contínuo
- `continuous-learning-v2` (instincts com confidence score) — hook observando
- `learn-eval` ao fim de tarefa → extrai padrão reutilizável
- `promote` move instinct validado de projeto → global

### 2.4 Memória
- `MEMORY.md` + `memory/*.md` (user / feedback / project / reference)
- Regra: **antes de recomendar, verificar se memória bate com realidade atual**

**Ativação técnica:** 3 hooks em `~/.claude/settings.json`
1. `SessionStart` → carrega memória + ativa token advisor
2. `PostToolUse (Edit/Write)` → dispara verification
3. `Stop` → `learn-eval` extrai padrão da sessão

---

## 3. Slash Commands

### 3.1 Pessoal

**v0 — já existe**
- `/manha` — ritual abertura (briefing + triagem + morning pages + 3 prioridades)
- `/noite` — ritual fechamento (audit + shutdown + prep amanhã)

**v1 — core cotidiano (construir primeiro)**
- `/pessoal-agenda` — consulta agenda no vault
- `/pessoal-foco` — 3 prioridades do dia (pull rápido, sem ritual completo)
- `/pessoal-inbox` — triagem Gmail + ClickUp + Obsidian `Inbox - Claudin/`
- `/pessoal-write-obsidian` — escreve/atualiza nota no vault (path + template + frontmatter auto)

**v2 — reflexão**
- `/pessoal-reflexao` — dispara `developmental-coach` com contexto de hoje
- `/pessoal-semana` — revisão semanal (sextas)
- `/pessoal-trimestre` — checkpoint OKRs

**v3 — operação de vida**
- `/pessoal-habitos` — tracker (treino, sono, leitura)
- `/pessoal-financas` — snapshot financeiro pessoal
- `/pessoal-leitura` — fila + notas
- `/pessoal-journal` — journal livre no vault

### 3.2 Trabalho — Ciclo F0 → F4

```
F0 Discovery   → /superpowers:brainstorming · writing-plans · /playground
F1 Plan Opus   → /plan  [GATE obrigatório]
F2 Exec        → subagent-driven · executing-plans · worktrees · spawn-paralelo · /playground
F3 Validação   → /hm-engineer · /hm-designer · /hm-qa · /hm-fix · verification
F4 Deploy      → /hm-deploy
```

**Recursos transversais (qualquer fase):**
- Spawn paralelo: `superpowers:dispatching-parallel-agents` · `subagent-driven` · `claude-devfleet` · `team-builder`
- Regra: 2+ tarefas independentes → default paralelo
- Playground: validar conceito antes de comitar

### 3.3 Ciclo reduzido por tipo de trabalho

| Tipo | Fluxo |
|---|---|
| Nova feature / projeto | F0 → F1 → F2 → F3 → F4 |
| Bug fix pequeno | `systematic-debugging` + F3 |
| Refactor | F1 + F3 |
| Tech debt | F0 + F2 + F3 |

---

## 4. Checkpoint automático entre fases

Cada transição de fase dispara 4 ações:

1. **Git checkpoint** — `git add -A && git commit -m "checkpoint: F<N> → F<N+1>"` (nunca main)
2. **Snapshot de memória** — `~/.claude/sennin/checkpoints/<projeto>/F<N>.json` (decisões, artefatos, próximo passo)
3. **Log Obsidian** — linha em `PITOS/DAP 4.0/log-fases.md` com timestamp + resumo
4. **Gate de aprovação** — Claude para, mostra delta, segue só após "ok"

**Detecção:** hook `PostToolUse` observa invocação de skill de fase posterior. Skill fora de ordem → bloqueia e avisa.

---

## 5. C-Level v2 — 12 Diretores

Sophia = único agente. Diretores = skills com prompts especializados + acesso a MCPs e skills específicas.

| Diretor | Cargo | Área | Skills | MCPs |
|---|---|---|---|---|
| **Anna** | CSO | Sales | lead-intelligence · investor-outreach · social-graph-ranker · connections-optimizer | Clay · HubSpot · Close · ClickUp |
| **Bianca** | CMO | Marketing | brand-voice · seo · content-engine · crosspost · article-writing · x-api | Ahrefs · Similarweb · Webflow · Bitly · Windsor.ai · Gamma |
| **Francisco** | CFO | Finance | finance-billing-ops · customer-billing-ops · ecc-tools-cost-audit · investor-materials | Supabase (reports) |
| **Marta** | CGO | Growth | market-research · connections-optimizer · social-graph-ranker · lead-intelligence · seo | Ahrefs · Similarweb · Firecrawl · x-api |
| **Rafael** | COO | Operations | automation-audit-ops · project-flow-ops · workspace-surface-audit · terminal-ops · unified-notifications-ops · github-ops | ClickUp · Slack · Gmail · Google Calendar · GitHub |
| **Claudio** | CTO | Technology | backend-patterns · frontend-patterns · database-migrations · deployment-patterns · docker-patterns · mcp-server-patterns · api-design · **security-review · security-scan · security-bounty-hunter** | Supabase · Vercel · GitHub · Context7 · Chrome DevTools · Playwright |
| **Thamy** | CDO | Design | frontend-design · liquid-glass-design · figma-implement-design · figma-generate-design · figma-generate-library · ui-demo · frontend-slides | Figma · Stitch · Excalidraw |
| **Zoraide** | CCO | Customer | messages-ops · email-ops · customer-billing-ops | Gmail · Slack · Close · HubSpot |
| **Walter** | CKO | Knowledge + Data | knowledge-ops · deep-research · research-ops · exa-search · iterative-retrieval · huggingface-* · clickhouse-io · postgres-patterns | Notion · NotebookLM · Hugging Face · Firecrawl · Supabase |
| **Pitoco** | CPO | Product | product-capability · prp-prd · prp-plan · api-design · e2e-testing · ai-regression-testing | Playwright · Miro · Figma |
| **Marcia** | CHRO | People | developmental-coach · content-engine (interno) | Notion · ClickUp · Slack |
| **Chapapiuro** | CSO | Strategy | blueprint · council · market-research · investor-materials · deep-research | Notion · Miro · Firecrawl |

**Nota sobre CSOs:** Anna = Sales, Chapapiuro = Strategy. Sempre citar com cargo pra não confundir.

**Como Sophia roteia:**
- Tema técnico/código → Claudio
- Tema UX/UI → Thamy
- Tema estratégia/decisão macro → Chapapiuro (chama council se ambíguo)
- Tema receita/leads → Anna / Marta
- Tema pessoas/cultura → Marcia
- Tema conhecimento/pesquisa → Walter

---

## 6. Tools

### 6.1 Built-in (sempre disponíveis)
Read · Write · Edit · Bash · Grep · Glob · TaskCreate/Update · Agent · WebFetch · ScheduleWakeup

Não precisam de atenção consciente. Claude usa conforme necessário.

### 6.2 MCPs — lazy-load + C-Level routing

**Princípio:** nenhum MCP é desligado. Todos continuam via ToolSearch (deferred). Quando Sophia roteia pra um diretor, aquele diretor invoca os MCPs da sua coluna na tabela acima.

**Benefício:** economia de contexto global (cada MCP hot custa tokens de sistema). Alocação contextual = ruído mínimo, acesso total.

---

## 7. Roadmap

### Implementação — ordem sugerida

- [x] **0.** Auditoria de uso real (30d) — `usage_audit.json` gerado
- [ ] **1.** Escrever este doc mestre (em andamento)
- [ ] **2.** Criar stubs dos slash commands personal v1 (`/pessoal-agenda`, `/pessoal-foco`, `/pessoal-inbox`, `/pessoal-write-obsidian`)
- [ ] **3.** Configurar 3 hooks meta (`SessionStart`, `PostToolUse`, `Stop`)
- [ ] **4.** Implementar checkpoint automático entre fases F0→F4 (hook + lógica de git/memória/Obsidian/gate)
- [ ] **5.** Atualizar prompts de cada diretor com mapping skills+MCPs da tabela (C-Level v2 já existe, só re-tunar)
- [ ] **6.** Dashboard próprio (web local) substituindo ECC dashboard — só após viver com v1 por 1 semana
- [ ] **7.** Roadmap pessoal v2 (reflexão)
- [ ] **8.** Roadmap pessoal v3 (operação de vida)

### Métrica de sucesso

Após 2 semanas rodando o protocolo, medir:
- Redução de tokens por sessão (baseline: audit atual)
- % de skills do catálogo usadas (hoje ~7%)
- Tempo entre "abrir projeto" e "primeiro commit"
- Nº de checkpoints por sessão
- Qualidade dos instincts gerados (confidence média)

---

## 8. Regras invioláveis

1. Nunca shippar trabalho mediano
2. Nunca pular segurança
3. Nunca deixar testes pra depois
4. Nunca construir pro passado
5. Na dúvida, escolher a opção que um time world-class escolheria
6. Skills acima override default Claude, mas **instruções do Thales override tudo**
7. Antes de recomendar de memória, verificar realidade atual
8. Nenhum MCP desligado — todos lazy-loaded
9. Gate entre fases é obrigatório, não negociável
10. Ciclo sempre: Discovery → Plan → Exec → Validação → Deploy

---

**Fim do protocolo v1.**
Próxima revisão: após 2 semanas de uso real.
