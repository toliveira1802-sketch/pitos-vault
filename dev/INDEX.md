---
tipo: hub
área: dev
atualizado: 2026-05-04
---

# 🛠️ Dev — todos os projetos em `C:\dev\`

Hub pra organizar a bagunça. Faxina projeto a projeto.
**Regra:** cada projeto tem 1 status: `ATIVO` · `LEGADO` · `ARQUIVAR` · `MERGEAR-EM-DAP4` · `?`.

---

## Foto atual (snapshot 2026-05-04)

| # | Projeto | Stack | Último commit | Commits/30d | Branch atual | Status |
|---|---|---|---|---|---|---|
| 1 | **dap4** | Node + Python + Docker | 55 min | **183** | `feat/fase0-instrumentacao-700k` | **ATIVO — oficial** |
| 2 | **dap-tools** | Node | 74 min | 80 | `adc-DAp40` | `?` |
| 3 | **dap-portal-aios-spike** | Node | 3 dias | 55 | `feat/chat-anna-v2-beta` | `?` (spike) |
| 4 | **dap-aios** | Node | 3 dias | 37 | `feat/aios-nucleo-consultor` | `?` |
| 5 | **dap-prime** | Node | 10 dias | 37 | `main` | `?` |
| 6 | **autodiag-copilot** | Node (pnpm) | 2 semanas | 15 | `master` | `?` |
| 7 | **doctor-auto-prime** | Node | 7 dias | 2 | `main` | provável **LEGADO** |
| 8 | **parliament-playground** | (vazio) | 3 semanas | 1 | `master` | provável **ARQUIVAR** |

> Também tem `_archive/`, `dap-portal-aios-spike.zip` (9MB) e `.claude/` em `C:\dev\`.

---

## A bagunça em 1 frase

Tem **5 projetos com nome `dap*` ativos ao mesmo tempo** + 1 `autodiag-copilot` cuja branch atual é `adc-DAp40` (sugere relação com DAP4). Provável que vários estejam tentando ser "a próxima geração" do mesmo produto.

---

## Perguntas-âncora (responde aqui, vamos limpar)

### `dap4` — o oficial?
Last commit: `fix(auth): implementa rota /reset-password (magic link de recovery)`.
- Tudo novo entra aqui? **(sim/não)**:
- Branch `feat/fase0-instrumentacao-700k` continua? **(sim/não)**:

### `dap-tools` — 80 commits/30d, branch `adc-DAp40`
"adc" parece ser AutoDiag Copilot. Last commit: `docs(02): UI design contract approved`.
- O que é isso? __
- Continua ativo independente, vira módulo do dap4, ou arquiva? __

### `dap-portal-aios-spike` — spike (foi pra valer?)
Last: `fix(alarmes): fix #9 auto-disable triggers only on erro_anthropic`.
- Foi promovido pro dap4 (já mergeado) ou ainda é vivo separado? __
- Tem o `.zip` ao lado também — pode apagar? __

### `dap-aios`
Branch `feat/aios-nucleo-consultor`. Núcleo consultor.
- Relação com `dap4` e `dap-portal-aios-spike`? __
- Status: __

### `dap-prime` — DAP Prime V1
README diz "# DAP Prime V1". Last: `docs: map existing codebase` (10 dias).
- É um repo separado do dap4 ou predecessor? __
- Status: __

### `autodiag-copilot`
README "# AutoDiag Copilot". Tem `CLAUDE.md`. pnpm enforced.
- Produto separado, módulo do dap4, ou se sobrepõe ao `dap-tools`? __
- Status: __

### `doctor-auto-prime`
README "# Doctor Auto Prime — Portais". Last commit fala de "cleanup consultor — drop orphan worktree". Só 2 commits/mês.
- Confirmar **LEGADO** e arquivar em `C:\dev\_archive\`? __

### `parliament-playground`
1 commit em 3 semanas. README "# Parliament Playground".
- Confirmar **ARQUIVAR**? __

---

## Plano de faxina (depois das respostas acima)

1. Marcar cada projeto com status final
2. Criar 1 nota por projeto **só pros ATIVO/MERGEAR** em `dev/<projeto>.md` (com objetivo, owner, próxima ação)
3. Mover **LEGADO/ARQUIVAR** pra `C:\dev\_archive\` ou apagar de vez (com backup git)
4. Atualizar este INDEX com a foto pós-faxina
5. Adicionar link aqui pra cada nota viva

---

## Notas de projeto (criadas conforme a faxina avança)

_(vazio — vamos preencher um por um)_

---

## Decisões registradas

- 2026-05-04 — INDEX criado pra organizar 8 projetos em `C:\dev\`.
