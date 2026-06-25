---
type: handoff
date: 2026-05-30
time: 06:45
project: DAP4 / dap-aios
topic: Limpeza r13, fixes do Portal Consultor, KPIs reais, e Calendário Editorial (Marketing)
tags: [handoff, claudin, dap-aios, gestao, consultor, marketing]
---

# Handoff — dap-aios: Consultor fixes + Marketing Calendário

## Contexto
Trabalho no **dap-aios** (`C:\THALES\DAP4.0\dap-aios`) — plataforma modular de portais (Consultor,
Gestão, Mecânico, AIOS) sobre Postgres/Supabase. Sessão começou consolidando o worktree legado
`r13`, passou por uma varredura crítica do **Portal Consultor** (16 telas), corrigiu os bugs
transversais, e terminou construindo a 1ª fatia vertical de **Marketing** (Calendário Editorial)
ponta-a-ponta. App roda em `pnpm dev` → `http://localhost:5050` (auth Supabase real).

Branch ativo: `feat/ai-sprint4b-anna-shadow-ui` — **tudo pushado pro origin** (`+0 -0`).
Repo: `toliveira1802-sketch/dap40-perple-claude`.

## O que funcionou (com evidência)
- **Unificação/limpeza r13** — worktree era do próprio dap-aios, 0 commits exclusivos. Arquivado em `arquivo/` (bundle git), worktree removido, 5 branches mortas podadas. Evidência: `git worktree list` só mostra o principal.
- **Tela preta corrigida (401 de sessão expirada)** — `RequireAuth` agora detecta 401 no `/api/me` → desloga + redirect pro login. Evidência: reload com storage vazio cai em `/#/login` (antes ficava preto).
- **Datas dinâmicas** (Meu DAP, Agenda, DashboardKpisRow) — eram travadas em `2026-05-26`. Evidência: header mostra "Agendamentos do Dia (30/05/2026)".
- **Dashboard KPIs reais** — consultor não tinha `dashboards:read` → endpoint 403 → "??". Concedido (seed + banco vivo). Evidência na tela: Veículos no Pátio **3**, Faturamento **R$ 1.980**, Entregas **1**.
- **Calendário Editorial (Marketing)** — schema `content_items` + migration `0002` + CRUD API `/api/marketing/calendar` + UI mensal com chips por canal e modal create/edit/delete. Evidência: 6 peças reais renderizando em mai/jun 2026 (prints em `docs/review/consultor-prints/_marketing-calendario*.png`).
- **Scripts ops** — `create-user.ts` (Auth+app user) e `grant-permission.ts` (grant idempotente). Ambos rodaram com sucesso.

## O que NÃO funcionou (e por quê)
- **Husky pre-commit via git-bash** — falha `pnpm: command not found` (exit 127). `pnpm` não está no PATH do git-bash NEM do PowerShell padrão. **Solução:** commitar pelo PowerShell prependando `$env:PATH = "C:\Users\docto\AppData\Roaming\npm;" + $env:PATH` (onde vive `pnpm.cmd`).
- **`git worktree remove dap-aios-r13`** — "Directory not empty" (sobrou node_modules). Worktree desregistrou mesmo assim; a pasta órfã foi removida com `rm -rf` depois.
- **`localStorage.clear()` + hash-navigate NÃO desloga** — a sessão Supabase fica em memória. Pra forçar logout no Playwright: `await supabase.auth.signOut()` + clear + **navegar pra URL sem hash** (full reload).
- **`goto` pra mesma URL (só hash) não recarrega** — React Query mantém erro cacheado. Pra refetch real: navegar pra `http://localhost:5050/` (base) e voltar.
- **set-anna-password.ts** — tinha senha hardcoded (`Senha-Teste-1234!`) aplicada na conta real da Anna. **Deletado, NÃO commitado.** ⚠️ Se essa senha foi aplicada, rotacionar a senha da Anna no Supabase.

## O que ainda não foi tentado
- **Meu DAP personalizado por consultor** — escopar KPIs/OS/faturamento pelo `req.actor.actorId` via `serviceOrders.assignedAdvisorId` + `quotes.createdById`. Caminho mapeado, não implementado.
- **Portal Gestão completo (12 módulos)** — spec lido em `PITOS/.../PORTAL GESTAO/`. Só 2 de 12 construídos (Operações, Comercial). Próximo natural: 00 Dashboard Home.
- **Campanhas (Marketing)** — integração Google Ads + Meta + WhatsApp. Build futuro.

## Arquivos tocados (principais)

| Arquivo | Status | Notas |
|---------|--------|-------|
| `client/src/auth/RequireAuth.tsx` | Completo | Fix do 401/tela preta |
| `client/src/lib/date.ts` | Completo | Novo — `todayISO()` |
| `client/src/modules/consultor/pages/MeuDapPage.tsx` | Completo | Data dinâmica |
| `client/src/modules/consultor/pages/AgendaPage.tsx` | Completo | Data dinâmica + removida maquiagem demo (+12/+11) |
| `client/src/modules/consultor/components/DashboardKpisRow.tsx` | Completo | Data dinâmica (KPIs já eram wired) |
| `server/scripts/seed.ts` | Completo | +consultor `dashboards:read`, +gestor `marketing:manage` |
| `server/scripts/create-user.ts` · `grant-permission.ts` | Completo | Ops tooling novo |
| `packages/types/src/schema/marketing.ts` | Completo | Novo — `content_items` + zod |
| `server/src/services/contentCalendarService.ts` | Completo | Novo — CRUD |
| `server/src/routes/marketing.ts` | Completo | Novo — `/api/marketing/calendar` |
| `client/src/modules/gestao/marketing/hooks.ts` | Completo | Novo — React Query |
| `client/src/modules/gestao/marketing/pages/MarketingCalendarPage.tsx` | Completo | Calendário mensal CRUD |
| `docs/sessions/2026-05-30-*.md` | Completo | Review, TODO, soltar-operacao |

## Decisões tomadas
- **r13 → arquivo, não merge** (Thales) — não tinha nada novo, virou bundle em `arquivo/`.
- **Operação é read-model do Consultor** (Thales) — sem dado do Consultor, Gestão não mostra nada. A torneira é o Consultor.
- **Consultor de teste** criado: `consultor.teste@doctorautoprime.com` / `Teste@DAP2026` (role consultor).
- **Marketing = domínio novo a construir**, não "conectar" (não há backend). 1ª fatia: Calendário Editorial.
- **Meu DAP personalizado:** sem mexer em agendamentos (sem campo consultor) nem na meta agora — decisão do Thales.

## Bloqueios & perguntas abertas
- ⚠️ **Veículos Órfãos (módulo 07 Gestão) CONFLITA com invariante R16.5** (nunca veículo órfão). Decidir: cliente genérico/seguradora OU relaxar invariante.
- **Login admin dev:** `toliveira1802@gmail.com` / `12345678`. Walter (gestor) tem `supabaseUserId` null → só via role override.
- **Mocks ainda na tela:** badge "6" do sino (`pendenciasMock`), Tarefas/Pendências do Meu DAP (hardcoded), mock customers na Agenda. Dados de teste sujos no banco (asdfs/asdfg/"vw golf").
- **Melhoria infra:** `requireAuth` chama `supabase.auth.getUser()` por request (round-trip) — risco de latência. Validar JWT local seria melhor.

## Próximo passo exato
Construir o **módulo 00 Dashboard Home do Portal Gestão** (spec em `PITOS/03 - Projetos/DAP 4.0/DOCTOR AUTO PRIME/PORTAL GESTAO/00_Dashboard_Home.md`): hub roteador com 7 cards coloridos (KPI + ícone lucide + CTA ArrowRight por módulo), rota `/gestao` ou `/gestao/home`. Reusar KPIs que já existem (Operação via `useOperacaoDashboard`, Comercial via `useResumo`). Seguir o padrão visual dark dos dashboards existentes.

## Setup / comandos úteis
- App: `pnpm dev` → http://localhost:5050 (dev server provavelmente ainda rodando em background).
- **Commit:** sempre via PowerShell com `$env:PATH = "C:\Users\docto\AppData\Roaming\npm;" + $env:PATH` (senão Husky quebra com pnpm-not-found).
- Typecheck: `pnpm --filter @aios/client check` / `--filter @aios/server check`.
- Nova tabela: editar `packages/types/src/schema/*.ts` → `pnpm db:push` (gera migration + aplica).
- Conceder permissão no banco vivo (sem reseed): `cd server; npx tsx scripts/grant-permission.ts <role> <resource> <action>`.
- TODO consolidado: `dap-aios/docs/sessions/2026-05-30-TODO.md`.
