---
type: handoff
date: 2026-05-04
time: "08:30"
project: dap-tools
topic: Sessão refez do zero plataforma que JÁ existe em C:\dev\dap-tools (95% Phase 1). Trabalho redundante em C:\thales\dap-tools, push poluiu o repo GitHub. Próxima sessão: descartar e voltar.
tags: [handoff, claudin, dap-tools, redundancia, replanejar]
---

# Handoff — Construí dap-tools do zero sem saber que já existia. Reverter.

## Contexto

Thales pediu "um app de ferramentas pro dia a dia, no desktop, sobe pra database online". Brainstormei do zero (Superpowers brainstorming), gerei spec + plan world-class (PWA modular React+Supabase, módulo Fichas como prova de conceito do plugin model), comecei executar via subagent-driven-development.

**Erro fatal:** Não verifiquei memória/handoffs/`C:\dev\` antes de criar `C:\thales\dap-tools`. Quando o Thales no meio da execução falou "eu já tenho alguns apps", aí entendi que tinha refeito do zero algo que JÁ EXISTE.

**A realidade:** o repo de verdade é `C:\dev\dap-tools` (master branch + `adc-DAp40` 19 commits ahead). Tem 2 handoffs anteriores (25/04, mesmo nome de projeto):
- `handoff-2026-04-25-0116-dap-tools-gsd-init.md` — GSD instalado, 7 docs codebase mapeados (1.678 linhas)
- `handoff-2026-04-25-0510-dap-tools-phase1-rls-hardening.md` — Phase 1 (Auth & RLS Hardening) **95% completa**: 6 plans (~2.900 linhas), migrations 08-14 aplicadas em prod (Supabase project `mtrmtkvhgrzhwhhfffhj`), 51 policies role-aware, backend fail-fast, 16 testes RLS escritos. Falta SÓ rodar `npm run test:rls` com JWT_SECRET rotacionado.

**Os "apps" que o Thales mencionou** são as pastas que já estão dentro de `C:\dev\dap-tools`: `apps/`, `backend/`, `autodiag-copilot/` (com .git próprio), `operacao/`, `web/`, `tools/`, `supabase/`. Plataforma guarda-chuva DAP4.0. Padronizar e compilar = unificar essas peças sob um shell + auth + design system, não construir nova plataforma greenfield.

## O que funcionou (com evidência)

- **Spec + Plan world-class escritos** (independente do path estar errado, o conteúdo do design pode aproveitar):
  - `C:\thales\dap-tools\docs\superpowers\specs\2026-05-04-dap-tools-platform-design.md` (commit `ac97d00`) — 13 blocos: contexto, goals, arquitetura, stack, schema Supabase + RLS, plugin contract, módulo Fichas, UI direction (Linear-meets-DAP), deploy, roadmap sub-projetos, riscos.
  - `C:\thales\dap-tools\docs\superpowers\plans\2026-05-04-dap-tools-platform-plan.md` (commit `a24a9ab`) — 38 tasks em 6 phases, cada com TDD steps, código completo, commit messages, comandos PowerShell exatos.

- **Phase 0 do plano executou sem erro funcional.** Subagente entregou DONE_WITH_CONCERNS, todos os smoke tests passaram:
  - `pnpm dev` boota
  - `pnpm typecheck` zero erros
  - `pnpm lint` zero erros
  - `pnpm test` passa (cn.test.ts)
  - 5 commits limpos, branch pushed.

- **Skills do Superpowers (brainstorming, writing-plans, subagent-driven-development) seguidas direito.** Process funcionou — o que falhou foi o **input de contexto** (não cheguei a olhar memória/handoffs/`C:\dev\` antes).

## O que NÃO funcionou (e por quê)

- **Não verifiquei estado prévio antes de criar projeto novo.** Memory listava `dap-tools` indiretamente (via outras notes), e os handoffs de 25/04 estão no inbox sem que eu tivesse lido. Falha de processo no início do brainstorming. **Lição rígida:** antes de bootstrap de qualquer projeto novo, **sempre** rodar:
  - `Glob` em `C:\dev\` e `C:\thales\` por nome similar
  - `Glob` em `Inbox - Claudin/handoff-*<topic>*.md`
  - Ler memory MEMORY.md procurando o tópico

- **Repo `dap-tools` no GitHub já existia desde 24/04** com conteúdo legítimo (legacy `_data/`, `backend/`, `web/` no `main`). Subagente fez `gh repo create dap-tools` falhar (duplicate), pivot pra `git remote add origin` + push. **Resultado: a branch `feat/v0.1.0-platform-fichas` está no MESMO repo do trabalho real**, agora convive com `main` legacy + `adc-DAp40` (19 commits Phase 1) — três históricos não relacionados no mesmo repo. Bagunça pra resolver.

- **Push em `feat/v0.1.0-platform-fichas` pode confundir leitor do GitHub.** Quem chegar no repo agora vê 3 branches divergentes. Se mergeasse, sobrescreveria trabalho válido.

- **Subagente pegou Vite 8/React 19 inicialmente** e teve que downgrade pra Vite 5/React 18 (plan especificava React 18). Adaptação OK, mas indica que `pnpm create vite@latest` é instável pra repetir. Se fosse pra continuar nessa stack, o plan deveria pinar versão do `create vite`.

- **Node 24 quebrou bin shim do Supabase CLI npm wrapper.** Conhecido (memory: `feedback_native_modules_node24.md`). Phase 1 do plan novo nunca chegou a rodar `supabase init` — mas teria falhado.

## O que ainda não foi tentado

- **Ler `C:\dev\dap-tools\.planning\codebase\*.md`** — os 7 docs de mapeamento (STACK, INTEGRATIONS, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, CONCERNS, 1.678 linhas) descrevem o que já existe. Próxima sessão deve ler ANTES de qualquer ação.

- **Confrontar visão do plano novo (PWA + plugin model + Fichas) contra plano GSD existente (5 phases coarse, milestone "Sala do Conselho Operável v1").** Possíveis cenários:
  1. **Descartar plano novo, continuar GSD em curso** — fechar Phase 1 (rodar test:rls), seguir Phase 2.
  2. **Reaproveitar design do plano novo (UI direction, plugin model, design tokens)** como input pra Phase 2 ou 3 do GSD existente, se fizer sentido evoluir o que está em `apps/`.
  3. **Tratar plano novo como projeto separado** (em path diferente, nome diferente) — mas isso é exatamente o anti-padrão que causou esse problema.
  
  Recomendo cenário 1 com possível reaproveitamento parcial dos design tokens / spec de UI no futuro.

- **Decidir destino do repo GitHub `dap-tools`:**
  - (a) Apagar branch `feat/v0.1.0-platform-fichas` no GitHub — `git push origin --delete feat/v0.1.0-platform-fichas`. Limpa o estrago, preserva trabalho real.
  - (b) Renomear pra `experiments/replan-2026-05-04` antes de apagar — preserva pra referência.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\thales\dap-tools-replan-2026-05-04\` (renomeado em 04/05 às 08:35) | **Preservado como referência** | Repo paralelo com 7 commits + node_modules + scaffold Vite. Spec/plan world-class em `docs/superpowers/`. Branch local `feat/v0.1.0-platform-fichas` ainda existe mas sem upstream. |
| `C:\thales\dap-tools-replan-2026-05-04\docs\superpowers\specs\2026-05-04-dap-tools-platform-design.md` | Referência de design | Reaproveitar UI direction, plugin contract, design tokens em sessão futura |
| `C:\thales\dap-tools-replan-2026-05-04\docs\superpowers\plans\2026-05-04-dap-tools-platform-plan.md` | Referência de plano | Pode informar plan de phase futura no GSD existente |
| `GitHub origin/feat/v0.1.0-platform-fichas` | ✅ **Apagada em 04/05 08:35** | `git push origin --delete` rodado. Repo `dap-tools` no GitHub agora só tem branches legítimas. |
| `C:\dev\dap-tools\` | **Inalterado** ✅ | Não toquei. Branch `adc-DAp40` continua 19 commits ahead, último commit `35b457a` |

## Decisões tomadas

- **Brainstorming → spec → plan → execution** seguindo skills Superpowers — processo correto, falhou só por falta de contexto inicial.
- **PWA (não Tauri/Electron)** pra desktop com sync online — decisão sólida, deixa pra próxima sessão decidir se aplica.
- **Plugin model "shell + módulos plugáveis em `src/tools/<slug>/`"** — bom design, possivelmente útil pro `apps/` existente do `dap-tools` real.
- **Design tokens DAP** (ink/paper/red Porsche, Inter/JetBrains Mono/Archivo Black) — reaproveitar.
- **NÃO push pra GitHub o trabalho até confirmar com Thales** — fica como hygiene pra próxima sessão.

## Bloqueios & perguntas abertas

- **Qual a relação entre o "DAP Tools" que o Thales pediu hoje e o `dap-tools` (Sala do Conselho Operável) já em curso?** Mesmo nome ≠ mesma coisa. Possivelmente o Thales viu o nome e associou. Confirmar com ele:
  - Era pra continuar o GSD existente?
  - Era pra fazer algo paralelo (caixa de ferramentas pessoal acoplada à plataforma DAP)?
  - Era pra reescrever?

- **Os "apps" que o Thales mencionou** quando me cortou:
  - Provavelmente: `apps/` + `backend/` + `autodiag-copilot/` + `web/` + `operacao/` + `tools/` em `C:\dev\dap-tools`.
  - Mas pode também ser: planilhas Excel, HTMLs locais, ferramentas n8n etc. que ele tem soltas. **Próxima sessão: pedir lista bagunçada das fontes.**

- **Repo GitHub bagunçado** com 3 branches não-relacionadas (`main` legacy de 24/04, `adc-DAp40` Phase 1 GSD, `feat/v0.1.0-platform-fichas` da minha experimentação). Decidir limpeza.

- **Phase 1 do GSD existente: rodar `npm run test:rls`** ainda é o gargalo lá. JWT_SECRET precisa rotação no painel Supabase antes (vazou no chat de 25/04).

## Próximo passo exato

Em sessão nova com `/clear`:

1. **Ler ESTE handoff primeiro.**
2. **Ler `C:\dev\dap-tools\.planning\codebase\*.md`** (7 arquivos) e os 2 handoffs anteriores:
   - `handoff-2026-04-25-0116-dap-tools-gsd-init.md`
   - `handoff-2026-04-25-0510-dap-tools-phase1-rls-hardening.md`
3. **Confirmar com Thales:** "O `dap-tools` que você quer evoluir é `C:\dev\dap-tools` (Phase 1 GSD em 95%, branch `adc-DAp40`)? Ou é projeto novo separado?" — ele provavelmente já vai dizer "é o de C:\dev, esquece o C:\thales".
4. **Se confirmar `C:\dev\dap-tools`:**
   - `cd C:\dev\dap-tools`
   - Rodar `git branch --show-current` (deve estar em `adc-DAp40`)
   - Próximo trabalho real: rotacionar JWT_SECRET no painel Supabase, rodar `npm run test:rls` localmente, fechar AUTH-08 = Phase 1 done. Depois `/gsd-plan-phase 2`.
5. **Limpeza do estrago:**
   - `git push origin --delete feat/v0.1.0-platform-fichas` (ou renomear pra `experiments/...` antes — pergunte).
   - Decidir destino de `C:\thales\dap-tools\` (rmdir? mover docs `docs/superpowers/` pra `C:\dev\dap-tools\docs/experiments/replan-2026-05-04/` pra preservar referência?).

## Setup / comandos úteis

```powershell
# Ler handoffs anteriores antes de qualquer ação
cat "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\handoff-2026-04-25-0510-dap-tools-phase1-rls-hardening.md"
cat "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\handoff-2026-04-25-0116-dap-tools-gsd-init.md"

# Ler codebase map (1.678 linhas, 7 docs)
ls "C:\dev\dap-tools\.planning\codebase\"

# Verificar estado real do repo
cd C:\dev\dap-tools
git status
git branch -a
git log --oneline -10

# Limpeza do GitHub (depois de confirmar com Thales)
git push origin --delete feat/v0.1.0-platform-fichas

# Limpeza local (depois de confirmar)
# Move docs preservando, depois apaga o resto:
robocopy "C:\thales\dap-tools\docs\superpowers" "C:\dev\dap-tools\docs\experiments\replan-2026-05-04" /E /MOVE
rmdir "C:\thales\dap-tools" /S /Q
```

## Lição pra hooks futuros

**Antes de qualquer `mkdir` de projeto novo ou `git init` em path novo:**
1. `Glob` em `C:\dev\<nome-similar>*` e `C:\thales\<nome-similar>*`
2. `Glob` em `Inbox - Claudin\handoff-*<nome-similar>*.md`
3. Se houver match, PARAR e ler antes de continuar.

Vale criar hookify rule pra isso (`pre-mkdir-project-check`).
