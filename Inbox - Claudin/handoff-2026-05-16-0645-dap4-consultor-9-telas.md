---
type: handoff
date: 2026-05-16
time: 06:45
project: DAP 4.0 — frontend 3 portais
topic: Foundation + Portal Consultor completo (11 telas, 2 commits)
tags: [handoff, claudin, dap4, frontend, apex-console]
---

# Handoff — DAP 4.0 frontend: Foundation Apex + Portal Consultor (11 telas)

## Contexto

Construção do frontend do ecossistema DAP 4.0 em **monorepo único** com 3 portais (`/consultor/*`, `/gestao/*`, `/aios/*`) coexistindo num único Vite app. Stack: Vite 5 + React 18 + TS + Tailwind + shadcn (utilitários) + Supabase + TanStack Query + React Router v6 + React Hook Form + Zod + Recharts.

Trabalho no fork `toliveira1802-sketch/table-to-code-magic` (protótipo Lovable que veio com schema Supabase pronto e algumas páginas legadas que foram descartadas). NÃO mexer no `5-dap-operacao/` legacy de produção.

Design system **Apex Console** (próprio) — dark editorial enterprise / control-room. Estende o DS canônico DAP v1 que era light editorial — agora numa direção dark. Tipografia Space Grotesk + Inter + JetBrains Mono · sem border-radius · bordas thin 1px · sem glassmorphism. Paleta única pros 3 portais: cyan/teal como accent principal (`#22D3EE`), vermelho `#EF4444` SÓ pra danger/alert/SLA, ouro `#C8A96E` SÓ pra VIP semantic.

Sessão entregou **foundation completa + portal Consultor com 11 telas implementadas** (de 11 totais).

## O que funcionou (com evidência)

- **Foundation publicada** — commit `4dc6a13` pushado em `origin/feat/3-portals-dark-apex`. Inclui tokens.css + apex.css + apex.tsx (componentes ApexCard/Button/Badge/Eyebrow/Kpi/TechStrip/Tabs/Wordmark/Rail/Input/Dot/Section), shell unificado (Sidebar 244px + Topbar 56px + PortalShell + portal.config.tsx canônico), Landing, e 3 telas de referência (Consultor Dashboard, Pátio kanban 8 col, AIOS Visão Geral).
- **9 telas Consultor implementadas** — commit `e6e0c33` (local, **não pushado ainda**). Nova OS · Agenda · CRM · Cadastro Cliente · OS Lista · OS Histórico · Linha do Tempo (Gantt CSS custom) · Relatórios · Institucional.
- **Mock data tipado** — `src/portals/consultor/_data/os-mock.ts` centraliza status OS + arrays OS_LISTA/OS_HISTORICO compartilhados entre Lista/Histórico/Gantt. Tipado contra schema Supabase (`ordens_servico`, `clientes`, `veiculos`, etc).
- **Build limpo** — `tsc --noEmit` exit 0 em todos os commits. `vite build` exit 0 (CSS 95kb gzip 16kb · JS 670kb gzip 187kb).
- **28 rotas no ar** — todas respondem HTTP 200 em `http://localhost:8081` (smoke testado).
- **Paleta unificada** — cyan/teal substituiu vermelho como accent principal, vermelho preservado semanticamente. Coerência visual entre os 3 portais verificada.
- **Gantt sem dependência externa** — custom CSS Grid + algoritmo greedy de stacking de barras. Performante, leve, 100% Apex.

## O que NÃO funcionou (e por quê)

- **`@import` depois de `@tailwind` no index.css** — falhou com warning Vite "@import must precede all other statements". Corrigido movendo os 2 imports do design-system para o topo do arquivo antes dos `@tailwind base/components/utilities`.
- **Git commit inicial bloqueou** — `fatal: unable to auto-detect email address`. Git nunca foi configurado nesta máquina. Regra global do Thales proíbe alterar git config. Resolvido com escolha (rota C) do Thales: `git config user.email/name` **local-only** no repo (`git config` sem `--global`).
- **Identidade git agora vazada por repo** — só este repo tem identity setada. Outros repos da máquina seguem sem. Não é problema do projeto.
- **`accent: "red"` no portal.config.tsx** — TS type era `"red" | "gold" | "ink"`. Quando swappei a paleta, troquei o type pra `"cyan" | "ink"` e renomeei 3 ocorrências.
- **Avisos LF→CRLF** — recorrentes em todo `git add`. É autocrlf padrão Windows · não bloqueante, sem efeito funcional.

## O que ainda não foi tentado

- **Plugar Supabase real** — todas as 12 telas (3 ref + 9 consultor) usam mock inline ou via `_data/os-mock.ts`. O schema Supabase já existe no repo (`supabase/migrations/`) e o client está configurado (`src/integrations/supabase/client.ts`), mas nada usa ainda.
- **Auth produção** — `AuthContext.tsx` está em `TEST_MODE = true` bypassando login. Reabilitar Supabase Auth + RLS é prerequisito de produção.
- **Drag-and-drop no Pátio** — cards são read-only. dnd-kit já está como candidato natural.
- **Code splitting** — bundle JS 670kb (187kb gzip). Lazy-load por portal corta isso pela metade.
- **Storybook** — DS Apex Console ainda sem catálogo navegável.
- **Implementação Portal Gestão (9 telas)** — todas placeholder.
- **Implementação Portal AIOS restante (6 telas)** — 1 implementada (Visão Geral), 6 placeholder.
- **Push do commit `e6e0c33`** — Thales não autorizou ainda; branch local 1 commit à frente do remote.
- **Aprovação visual do Thales das 9 telas novas** — ele recebeu o commit mas não confirmou se inspecionou no browser.

## Arquivos tocados

### Commit foundation (4dc6a13) — 21 arquivos · +3783 / -457

| Arquivo | Status | Notas |
|---|---|---|
| `index.html` | Completo | Dark mode no `<html class="dark">`, título DAP, preload Google Fonts |
| `tailwind.config.ts` | Completo | Tokens `apex.*`, fontes, sombras, animação `apex-pulse` |
| `src/index.css` | Completo | Imports DS antes do `@tailwind` |
| `src/App.tsx` | Completo | Roteamento /consultor/*, /gestao/*, /aios/*, / |
| `src/pages/NotFound.tsx` | Completo | 404 reskinned Apex |
| `src/design-system/tokens.css` | Completo | Paleta unificada |
| `src/design-system/apex.css` | Completo | Classes `.apex-*` utilitárias |
| `src/design-system/apex.tsx` | Completo | Componentes React tipados |
| `src/shell/portal.config.tsx` | Completo | Fonte canônica das 3 sidebars |
| `src/shell/Sidebar.tsx` | Completo | Sidebar fixa 244px com nav recursivo |
| `src/shell/Topbar.tsx` | Completo | Topbar 56px com breadcrumb + portal switcher |
| `src/shell/PortalShell.tsx` | Completo | Composição |
| `src/portals/Landing.tsx` | Completo | Selector 3 portal launch cards |
| `src/portals/_shared/Placeholder.tsx` | Completo | Placeholder genérico |
| `src/portals/consultor/Dashboard.tsx` | Completo | KPIs + buckets + agenda + follow-ups + atividade |
| `src/portals/consultor/Patio.tsx` | Completo | Kanban 8 colunas |
| `src/portals/consultor/index.tsx` | Completo | Routes |
| `src/portals/gestao/index.tsx` | Completo | Routes (todas placeholder) |
| `src/portals/aios/index.tsx` | Completo | Routes |
| `src/portals/aios/VisaoGeral.tsx` | Completo | Control-room: portais + decisões + Sophia + launchers |
| `package-lock.json` | Atualizado | Sem novas deps |

### Commit Consultor (e6e0c33) — 11 arquivos · +5067 / -100

| Arquivo | Status | Notas |
|---|---|---|
| `src/portals/consultor/NovaOS.tsx` | Completo | Form 5 blocos numerados, sticky summary, busca cliente/veículo, catálogo |
| `src/portals/consultor/Agenda.tsx` | Completo | Grid semanal 5 dias × slots 30min + view dia |
| `src/portals/consultor/CRM.tsx` | Completo | 3-col com 6 tabs |
| `src/portals/consultor/CadastroCliente.tsx` | Completo | Form progressivo, sub-form veículos, import pré-cadastro |
| `src/portals/consultor/OSLista.tsx` | Completo | Fila viva com chips de status + filtros |
| `src/portals/consultor/OSHistorico.tsx` | Completo | Consulta retroativa, stars feedback, motivo recusa |
| `src/portals/consultor/LinhaTempo.tsx` | Completo | Gantt custom CSS Grid, swimlanes consultor/elevador |
| `src/portals/consultor/Relatorios.tsx` | Completo | 4 KPIs + 9 relatórios + agendados |
| `src/portals/consultor/Institucional.tsx` | Completo | Hero + 8 etapas do fluxo + atalhos + time |
| `src/portals/consultor/_data/os-mock.ts` | Completo | Mock data tipado, status enum, OS_LISTA, OS_HISTORICO |
| `src/portals/consultor/index.tsx` | Completo | Routes atualizadas (substituiu Placeholders) |

## Decisões tomadas

- **Estender DS DAP com direção "Apex Console" (dark)** ao invés de criar paleta separada ou substituir o DS canônico — razão: o doc oficial DAP_DESIGN_SYSTEM.md já menciona "Apex" como slot natural pra "produto · dashboards · UI denso", e mantém coerência editorial com `Chassis` (light institucional).
- **Monorepo único, 3 sub-apps roteados por prefix** — razão: mesma casca, mesma fonte de verdade, sidebar muda por config. Pode separar em repos depois se justificar. Reduz fragmentação.
- **Trabalhar no fork `table-to-code-magic`**, não no `5-dap-operacao` legacy — razão: stack moderna Vite+Supabase, sem dívida técnica. Legacy fica em produção sem interferência.
- **Cyan/teal `#22D3EE` como accent principal** (substituindo vermelho institucional), preservando vermelho `#EF4444` pra danger semantic e ouro `#C8A96E` pra VIP semantic — razão: Thales reorientou o spec na 4ª iteração; manter vermelho universal pra alert respeita semântica de UX (Linear/Vercel/GitHub seguem mesmo padrão).
- **Mocks inline tipados contra schema Supabase**, não Supabase real ainda — razão: aprovação visual primeiro, swap pra queries reais depois (linha por linha, sem rework).
- **Não tocar no 5-dap-operacao legacy** — explícito da CLAUDE.md global.
- **Git identity local-only** (rota C) — razão: regra global proíbe `--global`. Identity local permite cumprir ordem de commit/push sem violar a regra global.
- **Gantt sem dependência externa** — CSS Grid + algoritmo greedy de stacking — razão: dnd-kit não é necessário pra read-only nesta fase, evita adicionar ~30kb desnecessários.
- **Mock data centralizado em `_data/os-mock.ts`** — razão: 3 telas (Lista, Histórico, Gantt) compartilham os mesmos dados. Quando plugar Supabase, é um único arquivo pra trocar.

## Bloqueios & perguntas abertas

- **Push do commit `e6e0c33` pendente** — Thales pediu commit (opção "1"), não mencionou push. Branch local 1 commit à frente. Decidir se sobe agora ou junto com próxima leva.
- **Aprovação visual das 9 telas** — Thales não confirmou que abriu no browser e validou. Continuar pra Gestão ou AIOS antes de validar pode gerar retrabalho se ele pedir ajuste visual.
- **Próxima fase** — opção A: Gestão (9 telas executivas, padrão diferente do Consultor, mais Recharts) · opção B: AIOS restante (6 telas estratégicas, padrão control-room) · opção C: outra prioridade.
- **`workflow_etapas` (tabela Supabase) parece duplicar status OS** — confirmar se é usada em produção ou se devemos hardcoded as 8 etapas em código. Atualmente assumimos hardcoded (`OS_STATUS` em `_data/os-mock.ts`).

## Próximo passo exato

**Decisão pendente do Thales antes de continuar:**
1. Push do `e6e0c33` em `origin/feat/3-portals-dark-apex` (`git push` simples, sem `-u` porque já está tracked)
2. Próxima fase a executar — Gestão ou AIOS restante

**Se Thales escolher Gestão:** começar criando 2 componentes novos antes das telas — `ApexChartCard` (wrapper Recharts dark) e `ApexStat` (KPI executivo mais editorial que `ApexKpi` do Consultor). Depois construir Visão Geral + Dashboard primeiro (mais usadas), depois as 4 áreas (Operações, Vendas&CRM, Financeiro, Marketing), depois Relatórios + Configurações + Institucional.

**Se Thales escolher AIOS restante:** começar por `/aios/aios` (Sophia central + diretores) e `/aios/sophia` (chat / sinais). Depois Facilities (launcher) e Dev (técnico). Padronizar 1 layout reaproveitável pra "AIOS · módulos" (Gestão/Consultor/Mecânico/Cliente são variantes do mesmo template).

## Setup / comandos úteis

```bash
# Path de trabalho:
cd C:/THALES/DAP4/_ref/table-to-code-magic

# Branch atual:
git branch --show-current   # feat/3-portals-dark-apex

# Dev server (já rodando em background ID b5pox7xqd da sessão atual):
npm run dev    # http://localhost:8081

# Validações antes de commit:
./node_modules/.bin/tsc --noEmit
npm run build

# Push pendente:
git push origin feat/3-portals-dark-apex

# PR sugerido pelo GitHub:
# https://github.com/toliveira1802-sketch/table-to-code-magic/pull/new/feat/3-portals-dark-apex
```

**Memórias relevantes em `~/.claude/projects/C--THALES-DAP4/memory/`:**
- `project_3portals_dark_apex.md` — decisão arquitetural A/A/A/A
- `reference_table_to_code_magic_repo.md` — repo target

**NÃO confundir:**
- P0 `C:/THALES/DAP4/` é o **ecossistema novo** (hub de portais standalone), do qual `_ref/table-to-code-magic/` é o fork de trabalho atual
- P1 `C:/dev/dap4` é o **legacy de produção VPS** — não tocar
