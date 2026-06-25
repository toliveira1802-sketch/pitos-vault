---
type: handoff
date: 2026-04-25
time: 01:16
project: dap-tools
topic: GSD instalado + codebase map de dap-tools commitado; pronto pro /gsd-new-project
tags: [handoff, claudin, gsd, dap-tools]
---

# Handoff — GSD instalado + codebase map de dap-tools

## Contexto

Sessão começou com instalação do `get-shit-done-cc` (npx) — sistema de meta-prompting / spec-driven development pra Claude Code. Instala 81 skills `/gsd-*`, agents, hooks, e um SDK CLI (`gsd-sdk`) que orquestra o workflow.

Depois disso, a tentativa foi rodar `/gsd-code-review-fix` mas o comando exige um projeto GSD inicializado (`.planning/` directory) e nenhum dos 12 projetos em `C:\dev\` tinha. Thales escolheu inicializar o GSD em `C:\dev\dap-tools` (o monorepo do ecossistema DAP — portal AIOS, supabase migrations, apps Vite/React, dois backends Express, autodiag-copilot).

Como `dap-tools` é brownfield (já tinha código + git), o workflow recomendou rodar `/gsd-map-codebase` antes do `/gsd-new-project`. Sessão terminou com os 7 docs de mapeamento commitados em `dap-tools` e roadmap pronto pra começar requirements + roadmap na próxima sessão.

## O que funcionou (com evidência)

- **Install do get-shit-done-cc** — `npx get-shit-done-cc@latest` instalou 81 skills + agents + 9 hooks. Confirmado: `gsd-sdk --version` → `gsd-sdk v0.1.0` em `C:\Users\docto\AppData\Roaming\npm\gsd-sdk.cmd`. Skills `/gsd-*` aparecem na lista do Skill tool.
- **SDK build retry manual** — install original do npx falhou no build do SDK (`✗ GSD SDK install failed`). Resolvi rodando `cd <npm-cache>/sdk && npm install && npm run build && npm install -g .` manualmente. Build OK em ~15s.
- **Codebase map sequencial in-context** — depois dos agents falharem (ver abaixo), escrevi STACK.md, INTEGRATIONS.md e ARCHITECTURE.md direto. Usei templates em `~/.claude/get-shit-done/templates/codebase/`.
- **Aproveitamento do trabalho dos agents falhos** — apesar de retornarem "Prompt is too long", os 4 background agents tinham escrito conteúdo substancial antes de falhar: STRUCTURE.md (302 linhas), CONVENTIONS.md (374), TESTING.md (252), CONCERNS.md (324). Verifiquei conteúdo, todo coerente, mantive.
- **INTEGRATIONS.md auto-melhorado** — escrevi versão de 115 linhas, depois algum agent/hook delayed reescreveu pra 169 linhas com referências file:line muito mais profundas (OpenAI nas Edge Functions, pipelines Bosch=12704980, Perplexity Computer host, AutoDiag schema completo). Mantive a versão melhor.
- **Commit limpo** — `gsd-sdk query commit "docs: map existing codebase" .planning/codebase/*.md` produziu commit `14984ae` em `C:\dev\dap-tools` (branch master). Secret scan rodou clean (sem `sk-`, `eyJ`, `AKIA`, etc.).
- **Total mapeado** — 1.678 linhas, 7 docs, todos >100 linhas, todos com file paths reais.

## O que NÃO funcionou (e por quê)

- **Spawn de 4 mappers em paralelo via `Agent(general-purpose, run_in_background=true)`** — TODOS os 4 falharam com `result: "Prompt is too long"`. Causa: o system prompt do `general-purpose` no harness atual é gigante (carrega N tools/MCP) e somado às minhas instruções estourou o context. Ironia: 3 dos 4 conseguiram escrever os docs antes de falhar na mensagem final de retorno.
- **`subagent_type="gsd-codebase-mapper"`** — falhou com `Agent type 'gsd-codebase-mapper' not found`. Os 17 agents `gsd-*` estão presentes como arquivos em `~/.claude/agents/*.md` mas o harness Claude Code v1 deste setup NÃO registra eles automaticamente como subagent_types. Lista de agents válidos é fixa: a11y-architect, architect, code-reviewer, etc. — sem `gsd-*`.
- **`/gsd-code-review-fix`** sem argumento — abortou em `gsd-sdk query init.phase-op ""` → `{"error": "phase required for init phase-op"}`. E `dap-tools` (e nenhum dos 12 projetos em `C:\dev\`) tinha `.planning/` ainda. Inicialização tinha que vir antes.
- **Read em arquivo vazio** retornou warning de offset out-of-range. Trick: deletar e recriar é mais limpo que tentar Read+Write em arquivo de 0 bytes.

## O que ainda não foi tentado

- **Subagent types alternativos com Write tool** (`doc-updater`, `code-simplifier`, `refactor-cleaner`, `a11y-architect`) — todos têm system prompt menor que `general-purpose`. Provavelmente cabem. Útil pra próxima vez que precisar paralelizar trabalho de mapeamento/escrita.
- **Registrar agents `gsd-*` no harness** — investigar como o Claude Code v1 descobre subagents. Talvez exija namespacing tipo `gsd:codebase-mapper` ou config explícita em `~/.claude/settings.json`. Checar `agent-sdk-dev:agent-sdk-verifier-py` como referência (tem namespace).
- **`/gsd-new-project`** — interrompido no Step 2 (brownfield offer) quando Thales escolheu mapear primeiro. Precisa retomar do Step 3 (questioning) na próxima.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\dev\dap-tools\.planning\codebase\STACK.md` | Completo | 126 linhas, escrita minha |
| `C:\dev\dap-tools\.planning\codebase\INTEGRATIONS.md` | Completo | 169 linhas, versão refinada (não a minha original) |
| `C:\dev\dap-tools\.planning\codebase\ARCHITECTURE.md` | Completo | 131 linhas, escrita minha |
| `C:\dev\dap-tools\.planning\codebase\STRUCTURE.md` | Completo | 302 linhas, agent background |
| `C:\dev\dap-tools\.planning\codebase\CONVENTIONS.md` | Completo | 374 linhas, agent background |
| `C:\dev\dap-tools\.planning\codebase\TESTING.md` | Completo | 252 linhas, agent background |
| `C:\dev\dap-tools\.planning\codebase\CONCERNS.md` | Completo | 324 linhas — destaca RLS holes graves |
| `C:\Users\docto\AppData\Roaming\npm\gsd-sdk*` | Instalado | binário global v0.1.0 |
| `~/.claude/skills/` (81 GSD skills) | Instalado | via npx, persistente |
| `~/.claude/agents/gsd-*.md` (17 files) | Instalado mas inerte | harness não registra como subagent_type |

## Decisões tomadas

- **Inicializar GSD em `dap-tools`, não em `dap4`** — Thales escolheu. Razão presumida: `dap-tools` é o monorepo "guarda-chuva" da nova arquitetura DAP4.0 (portal AIOS + supabase migrations + apps consolidados). `dap4` é o codebase legado do gateway/agents que já tem outro ciclo de vida.
- **Sequential mapping in-context após falha dos paralelos** — o workflow `map-codebase.md` documenta esse fallback explicitamente (`<step name="sequential_mapping">`). Validado.
- **Manter docs dos agents falhos** — depois de inspecionar, conteúdo deles era de qualidade superior (mais file:line refs, mais profundidade) que o que eu escreveria do zero rapidamente. Aproveitar > reescrever.
- **Modelo haiku pros mappers** — gsd-sdk init retornou `mapper_model: "haiku"`. Mantido.
- **Não commitei o `.planning/PROJECT.md`** — não existe ainda. Vai ser criado pelo `/gsd-new-project` na próxima sessão.

## Bloqueios & perguntas abertas

- **Como rodar GSD agents `gsd-*` neste harness?** Próxima sessão que precise spawn paralelo vai bater no mesmo problema. Workaround: ou usar subagent types pequenos com Write (doc-updater, etc.) ou aceitar sequential in-context.
- **`apps/backend` vs `backend/` precisa ser endereçado no roadmap** — dois Express services com responsabilidades sobrepostas. CONCERNS.md flaga, mas decisão de consolidação ainda é Thales-call.
- **`autodiag-copilot/` tem seu próprio `.git`** — está dentro do repo `dap-tools` mas com history independente. Pull/push do parent não pega isso. Decidir: vendor stable, submodule, ou extrair.
- **RLS policies permissivas** — README admite, CONCERNS.md detalha (HIGH severity). Provável fase 1 ou 2 do roadmap GSD.

## Próximo passo exato

Em sessão nova com `/clear`:

1. `cd C:\dev\dap-tools`
2. Invocar `/gsd-new-project`
3. O workflow vai detectar que `.planning/codebase/` já existe (graças ao commit `14984ae`) e pular o brownfield offer.
4. Step 3 (Deep Questioning) abre com "What do you want to build?" — resposta deve cobrir: meta do dap-tools como guarda-chuva DAP4.0, prioridade de fechar gaps de RLS / consolidar backends, próximas integrações (Anthropic, WhatsApp, Z-API).
5. Continuar até roadmap aprovado.

## Setup / comandos úteis

```bash
# Verificar GSD SDK
gsd-sdk --version
# → gsd-sdk v0.1.0

# Status do projeto GSD em dap-tools
cd /c/dev/dap-tools && gsd-sdk query init.new-project | head -20

# Re-rodar codebase map (se quiser refresh)
cd /c/dev/dap-tools && /gsd-map-codebase

# Ler resumo dos concerns sem inflar context
head -60 /c/dev/dap-tools/.planning/codebase/CONCERNS.md

# Lista os 81 GSD slash commands
ls ~/.claude/skills/ | grep ^gsd-
```
