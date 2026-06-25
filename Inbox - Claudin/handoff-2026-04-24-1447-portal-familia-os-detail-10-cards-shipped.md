---
type: handoff
date: 2026-04-24
time: 14:47
project: dap4 · portal-familia
topic: OSDetail Wave 2 (10 cards oficina-pro) shipped no branch feat/oficina-pro-merge. Falta port das 6 pages + rotas + deploy.
tags: [handoff, claudin, dap4, portal-familia, oficina-pro, wave2]
---

# Handoff — OSDetail Wave 2 shipped (10 cards), falta port de 6 pages + rotas + deploy

## Contexto

Sessão retomada do handoff anterior (`handoff-2026-04-24-1315-portal-familia-oficina-pro-merge.md`) que havia entregue a **foundation** do merge oficina-pro → portal-familia (migration SQL + 6 services + workflow + legacyDb) no commit `053334b`, sem UI.

Thales disse "segue o que voce achar viavel". Escolhi opção B+ pragmática: push backup primeiro, depois port da coroa da feature (OSDetail com 10 cards), com **decisão de design crítica**: rebranded todo o visual dos cards do padrão shadcn genérico do oficina-pro pro design system DAP Identity v1.0 (paper/ink/red, font-display Archivo, font-mono JetBrains, § UPPERCASE headers editorial). Rationale: o Wave 1 OSDetail já estava com esse visual e o critério CLAUDE.md do Thales é explícito — "se parece template, reprovou". Shadcn 1:1 seria medíocre.

Commit novo: `f0ecfb6` — pushed em `origin/feat/oficina-pro-merge`.

## O que funcionou (com evidência)

- **Push da foundation** — `053334b` subiu pra origin como backup (branch passou a tracked)
- **10 cards portados** — 11 arquivos novos em `portal-familia/src/features/consultor/components/os/` (os-constants + 10 cards). Design 100% DAP: `bg-dap-paper`, `border-dap-rule`, `text-dap-ink`, `text-dap-red` accents, `font-mono text-[10px] uppercase tracking-[0.22em]` nos § headers, `font-display font-black tracking-[-0.04em]` nos display numbers
- **OSDetail Wave 2 substituiu Wave 1** — `src/pages/consultor/OSDetail.tsx` agora usa `useOSFull` (getOSFullBundle, 10 fetches paralelos) + `updateOSStatus` com `userRole/userLabel` do `AuthContext`. Wave 1 (read-only com Kommo section) foi substituído integralmente
- **Novo hook `useOSFull`** — adicionado em `hooks/useOS.ts` com `osKeys.full(id)`. Cards invalidam com `['consultor', 'os', id]` que é prefix → TanStack invalida tudo
- **Typecheck verde** — `pnpm tsc --noEmit` 0 erros após corrigir 3 issues: `tipoMeta` possibly undefined em OsHistoryCard (extraí `DEFAULT_TIPO_META` constante), `statusMeta` idem em OsItemsCard (extraí `DEFAULT_ITEM_STATUS_META`), e `Profile.full_name` → na real é `profile.nome`
- **Testes verdes — 75/75** — `pnpm vitest run`. Reescrevi `__tests__/OSDetail.test.tsx` (mocks `getOSFullBundle` + `useAuth`) e corrigi regressão em `__tests__/useClientes.test.ts` (foundation mudou `supabase` → `legacyDb` no clientesService mas o mock só tinha `supabase`; adicionei `legacyDb: { from: mockFrom }` no mock)
- **Build prod verde** — `pnpm build` em 3m 53s, OSDetail bundle 104kb / 32kb gzipped
- **Commit + push** — `f0ecfb6` em `feat/oficina-pro-merge`, 15 arquivos, +2163/-317

## O que NÃO funcionou (e por quê)

- **Nada quebrou nesta sessão.** Única coisa que valeu log foi o test `useClientes > carrega lista paginada de clientes` — timeout no `waitFor(isSuccess === true)` porque o mock era `supabase` mas o service já usava `legacyDb`. Fix 1 linha.
- **Tests dos 10 cards novos não foram escritos** — foundation tinha zero testes pros services novos (osItems/osAnexos/osHistorico/osChecklists/osPayments/mecanicos) e agora os cards também não têm. Tech debt acumulado — pagar antes do deploy prod real.

## O que ainda não foi tentado

- **Port das 6 pages restantes do oficina-pro:**
  - `orders.tsx` (234 linhas) → substitui `src/pages/consultor/OSList.tsx` Wave 1 (hoje tem filtros + status chips + tabela, precisa virar grid de OS cards estilo oficina-pro)
  - `customers.tsx` (343 linhas) → substitui `src/pages/consultor/ClientesList.tsx` Wave 1 + incorpora `customer-workflow-wizard.tsx` (525 linhas) + `customer-detail-drawer.tsx` (273 linhas)
  - `agenda.tsx` (90 linhas) → substitui `src/pages/consultor/AgendaView.tsx` Wave 1
  - `patio.tsx` (88 linhas, Kanban drag-drop) → **nova** rota `/consultor/patio`, nova page `PatioKanban.tsx`
  - `financeiro.tsx` (68 linhas) → **nova** rota `/consultor/financeiro`, nova page `Financeiro.tsx`, consome `listPaymentsGlobal` do osPaymentsService
  - `users-management.tsx` (123 linhas) → **nova** rota `/admin/users`, só role=admin, nova page `UsersManagement.tsx`
- **Rotas no router:** `src/router/index.tsx` precisa adicionar as 3 rotas novas (pátio, financeiro, admin/users)
- **Sidebar:** `src/components/Sidebar.tsx` precisa entradas novas (Pátio Kanban, Financeiro, Admin/Users) com `RoleGate` apropriado
- **Smoke test E2E** — Playwright/manual contra `localhost:5173` pra confirmar que o OSDetail carrega com OS real do DOCTOR_PRIME. Não rodei nesta sessão
- **Deploy VPS** — `infra/deploy.sh` não rodado. `portal.doctorautoprime40.com` ainda roda Wave 1. Aguardando port completo pra deploy atômico (ou deploy incremental só com OSDetail novo rodando em rota `/consultor/os/:id` — compatível com Wave 1 porque o route path não mudou)
- **numero_os sequencial** — ainda tech debt. Port usa `osNumber(numero_os, id)` que faz fallback pra `OS.{uuid-slice}` quando numero_os é null

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `portal-familia/src/features/consultor/components/os/os-constants.tsx` | ✅ Novo | STATUS_ICON + TIER_META + LEVEL_META + ITEM_*_LABEL + ITEM_STATUS_META (+ DEFAULT_ITEM_STATUS_META) + formatCurrency/formatYardTime/osNumber/normalizePhoneBR. Tokens DAP. |
| `portal-familia/src/features/consultor/components/os/OsHeader.tsx` | ✅ Novo | Header editorial: § ORDEM DE SERVIÇO, OS.<numero>, StatusBadge (reusa componente Wave1), tier chip, actions (voltar/copiar link/WhatsApp/etiqueta disabled/editar). |
| `portal-familia/src/features/consultor/components/os/OsStatusPipeline.tsx` | ✅ Novo | Chips horizontais com todos os 7 status + cancelado. `allowedTransitions(current, role)` filtra clicáveis. Ativo = ink solid. |
| `portal-familia/src/features/consultor/components/os/OsDiagnosticCard.tsx` | ✅ Novo | 3 campos editáveis (descrição/service_type/diagnosis). Save via updateOS(). Feedback inline. |
| `portal-familia/src/features/consultor/components/os/OsItemsCard.tsx` | ✅ Novo | CRUD de itens com dialog de criação (Textarea+Select+3 Inputs), rows com approve/reject/delete inline, cálculo de margem, subtotal por tipo. |
| `portal-familia/src/features/consultor/components/os/OsAttachmentsCard.tsx` | ✅ Novo | Dropzone + grid de thumbs com signed URLs lazy (1h TTL). Videos com <video> muted, PDFs com link target="_blank", images <img>. |
| `portal-familia/src/features/consultor/components/os/OsHistoryCard.tsx` | ✅ Novo | Form de observação + timeline com tipo badges (observacao/status_change/system). safeDistanceToNow. |
| `portal-familia/src/features/consultor/components/os/OsChecklistCard.tsx` | ✅ Novo | Expansível. 4 booleans + entry_km + fuel_level (select). upsertChecklist transparente. Damages textarea bonus. |
| `portal-familia/src/features/consultor/components/os/OsQuickActions.tsx` | ✅ Novo | 3 links laterais (pátio, cliente, OS list). ActionDisabled quando clienteId null. |
| `portal-familia/src/features/consultor/components/os/OsInfoCards.tsx` | ✅ Novo | 5 cards exportados: OsVehicleCard, OsCustomerCard, OsFinancialCard (pendente/aprovado/recusado + adiantamento + saldo devedor), OsMechanicCard, OsYardTimeCard. |
| `portal-familia/src/features/consultor/components/os/index.ts` | ✅ Novo | Barrel re-export dos 10 cards + os-constants. |
| `portal-familia/src/features/consultor/hooks/useOS.ts` | ✅ Modificado | +useOSFull() + osKeys.full(id). Mantém useOS (Wave 1) funcionando. |
| `portal-familia/src/pages/consultor/OSDetail.tsx` | ✅ Modificado | Wave 1 substituído por versão oficina-pro (10 cards, useOSFull, updateOSStatus com role). Layout 2-col (main + sidebar 340px). |
| `portal-familia/src/pages/consultor/__tests__/OSDetail.test.tsx` | ✅ Reescrito | 3 tests: render + empty state + empty mecânico. Mocks getOSFullBundle + useAuth. |
| `portal-familia/src/features/consultor/__tests__/useClientes.test.ts` | ✅ Fix regressão | Adicionado `legacyDb: { from: mockFrom }` no vi.mock('@/lib/supabase') porque o service foi migrado no commit 053334b. |

## Decisões tomadas

- **Port + rebrand pro design DAP v1.0, não shadcn 1:1** — razão: Wave 1 OSDetail já usava paper/ink/red/§UPPERCASE. Manter shadcn genérico quebraria continuidade e reprovaria pelo critério world-class do CLAUDE.md. Trade-off: levou mais tempo mas a qualidade visual é coerente com o resto do módulo consultor.
- **legacyDb em todo service novo** — razão: db-types.ts só tipa 9 tabelas do schema `portal`. legacyDb client (sem Database generic) já estava no supabase.ts da foundation, usei sem fricção.
- **osKeys.full(id) como extensão do osKeys, não substituto** — razão: Wave 1 `useOS` (getOSById) ainda existe e pode ser útil noutros lugares. Não quebrei nada ao adicionar.
- **Cards invalidam com `['consultor', 'os', id]` (prefix)** — razão: TanStack Query invalida por prefix. Isso invalida tanto a entrada `osKeys.detail(id)` quanto `osKeys.full(id)`. Padrão já usado pelos services, mantive consistente.
- **StatusBadge reusa do Wave 1** — razão: `features/consultor/components/StatusBadge.tsx` já tem variantes attention/active/review/done/cancel em ink/paper/red. Mas **atenção**: o STATUS_MAP dele só cobre `orcamento/aprovacao/aprovada/aguardando_peca/em_execucao/teste/finalizada/entregue/cancelada` — NÃO cobre `diagnostico/aguardando_aprovacao/aprovado/pronto`. Tech debt: ampliar STATUS_MAP em uma próxima sessão. Hoje funciona porque status "unknown" tem fallback visual decente.
- **Etiqueta PDF disabled** — razão: oficina-pro tinha `<a href="/api/service-orders/{id}/pdf">` que era rota Express. Portal-família não tem esse endpoint. Deixei o botão visível (preserve UX intent) mas disabled com title "em breve". Tech debt: criar edge function Supabase pra gerar PDF.
- **Edit button onEdit=no-op** — razão: oficina-pro tinha "Edit inline (em breve)" e não implementava. Deixei o botão com callback vazio. Tech debt: inline editor de numero_os/prioridade/previsão/valor_orcado.
- **OsAttachmentsCard gera signed URL por anexo, lazy, via useEffect** — razão: signed URLs duram 1h, gerar N URLs no load do bundle desperdiça roundtrips. Lazy por tile com cancellation flag resolve e é testável.
- **Wave 1 OSDetail Kommo section removida** — razão: oficina-pro não tem Kommo (é o diferencial do DAP/DOCTOR_PRIME). O bundle ainda retorna `kommoMessages` (getOSFullBundle ainda faz o fetch), mas a UI do oficina-pro nunca consumiu. Decisão provisória: deixar fora até Thales pedir de volta. Se pedir, é 30 linhas (reaproveitar do Wave 1).
- **Fix em useClientes.test é arrumar regressão, não scope creep** — razão: quebrou no 053334b (foundation), teria que arrumar de qualquer jeito pra CI verde. 1 linha.

## Bloqueios & perguntas abertas

- **Wave 1 consultor ainda ativo em prod** — `portal.doctorautoprime40.com` roda branch master (Wave 1). Nenhum usuário do time está usando ainda — Thales é o único. Janela de risco mínima. Deploy pode ser feito depois das 6 pages.
- **Decisão: deploy incremental (só OSDetail novo) ou atômico (OSDetail + 6 pages juntos)?** — Meu voto: atômico. Usuário que entrasse numa OSList Wave 1 e clicasse numa OS cairia no OSDetail Wave 2 que usa getOSFullBundle + 10 cards diferentes. Não quebra (o bundle retorna os dados certos), mas UX inconsistente. 6 pages pra portar é ~2-3h de trabalho focado.
- **`numero_os` sequencial** — tech debt herdada. Hoje cards usam `osNumber(numero_os ?? null, id)` que cai em `OS.{uuid-slice}`. Quando criar uma OS nova via `createOS` service, `numero_os` fica null (service não preenche). UI mostra fallback uuid. Fix: função Postgres `next_os_number(empresa_id)` + trigger BEFORE INSERT. 20min.
- **Zero testes unitários pros 6 services da foundation + 10 cards** — acumulando. Priorizar antes do deploy prod se o time crescer de 1→3+ usuários.
- **Etiqueta PDF + Edit inline da OS** — features degradadas (disabled/no-op). Não quebra nada mas tira pontos de completude.

## Próximo passo exato

**Sessão retomada abre `C:\dev\dap4`**, confirma `git status` clean em `feat/oficina-pro-merge`, e Thales decide:

- **(A)** port das 6 pages + rotas + sidebar numa tacada (2-3h), commit + deploy atômico. Recomendo.
- **(B)** port só de `orders.tsx` (OSList) primeiro pra validar o pattern de rebrand DAP em page scale, depois continuar. Mais cauteloso, mais sessões.
- **(C)** deploy incremental do OSDetail atual (aceitando UX mista), port das pages em sessões subsequentes.

Se (A), começar por:

```
1. Port orders.tsx → OSList.tsx (grid de OS cards DAP-style)
2. Port customers.tsx + customer-workflow-wizard + customer-detail-drawer → ClientesList.tsx + componentes
3. Port agenda.tsx → AgendaView.tsx
4. Criar PatioKanban.tsx (port de patio.tsx) — kanban drag-drop com workflow_etapas join
5. Criar Financeiro.tsx (port de financeiro.tsx) — listPaymentsGlobal
6. Criar UsersManagement.tsx (port de users-management.tsx) — rota /admin/users
7. router/index.tsx: +3 rotas novas
8. Sidebar.tsx: +3 entradas com RoleGate
9. pnpm tsc + pnpm vitest + pnpm build → verde
10. Commit "feat(portal-familia): port 6 pages oficina-pro (Wave 2 complete)"
11. infra/deploy.sh → validar em portal.doctorautoprime40.com
```

## Setup / comandos úteis

```bash
# Working dir
cd C:\dev\dap4

# Branch atual
git branch --show-current   # → feat/oficina-pro-merge

# Status
git log --oneline -3
# f0ecfb6 feat(portal-familia): port OS detail + 10 cards do oficina-pro (Wave 2)
# 053334b feat(portal-familia): foundation pra absorver oficina-pro
# 0940425 feat(portal-familia): wave 1 globalSearch real

# Validação
cd portal-familia
pnpm tsc --noEmit          # ✅ zero
pnpm vitest run            # ✅ 75/75
pnpm build                 # ✅ 3m53s

# Dev server
pnpm dev                   # → localhost:5173

# Source oficina-pro (read-only)
cd /c/Users/docto/OneDrive/Área\ de\ Trabalho/oficina-pro
# branch feat/os-detail tem as 8 pages + customer wizard pra portar

# Deploy
cd /c/dev/dap4/infra && ./deploy.sh
```

## Arquivos de referência

- **Plano completo da migração:** `C:\dev\dap4\portal-familia\docs\MIGRATION_OFICINA_PRO.md`
- **Migration SQL:** `C:\dev\dap4\supabase\migrations\20260424_07_oficina_pro_merge.sql`
- **Foundation commit:** `053334b` — migration + services + workflow + legacyDb
- **OSDetail Wave 2 commit:** `f0ecfb6` — 10 cards + OSDetail novo + fix tests
- **Source oficina-pro:** `c:\Users\docto\OneDrive\Área de Trabalho\oficina-pro\client\src\`
- **Handoff anterior:** `handoff-2026-04-24-1315-portal-familia-oficina-pro-merge.md`
