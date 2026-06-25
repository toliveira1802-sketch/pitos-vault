---
type: handoff
date: 2026-04-24
time: 13:15
project: dap4 · portal-familia
topic: Portal Consultor morre; absorve UI do oficina-pro via merge no portal-familia. Foundation pronta (schema/services), falta UI port.
tags: [handoff, claudin, dap4, portal-familia, oficina-pro]
---

# Handoff — Portal Consultor → absorve oficina-pro (foundation ✅, UI pendente)

## Contexto

Portal Família DAP 4.0 (`C:\dev\dap4\portal-familia\`) está em Wave 1 com Portal Consultor (indicadores + pendencias + globalSearch real, PR #20 merged). Thales decidiu **matar o Portal Consultor** e **absorver o sistema oficina-pro** (standalone em `c:\Users\docto\OneDrive\Área de Trabalho\oficina-pro\`, branch `feat/os-detail` com OS detail maduro + Kanban Pátio + Financeiro + Agenda + Customer Wizard + Users-mgmt).

Decisão do Thales nesta sessão: **"segue/tudo/portal absorve/morte"** = porta o estado atual (uncommitted WIP) do oficina-pro, absorve tudo (não só consultor), portal-familia absorve users-management, oficina-pro morre definitivo (não paralelo).

**Descoberta crítica que mudou o plano:** o Supabase DOCTOR PRIME (`acuufrgoyjwzlyhopaus`) **já tem** todo o schema de OS em português com dados em produção (48 ordens_servico, 27 clients, 25 vehicles, 10 workflow_etapas, 5 colaboradores, 3 mecânicos, 8 kommo_channels). Portal Família Wave 1 já consome. Então o port **não é criar schema novo**, é **estender o existente** com campos que faltam e aproveitar a base legada. Preserva dados, preserva trabalho do Kommo/CRM.

Foundation da migração foi construída e comitada. UI port (3000+ linhas, 10 cards OS + 8 pages) ficou pendente pra próxima sessão.

## O que funcionou (com evidência)

- **Migration aplicada em prod** — `mcp__claude_ai_Supabase__apply_migration` retornou `{"success":true}`. Confirmado via SELECT no `information_schema.columns`: 44 colunas/tabelas novas verificadas.
- **Storage bucket criado** — `storage.buckets` row id=`os-anexos`, 50MB limit, private, policies de read/insert/update/delete em `storage.objects` pra authenticated users no bucket.
- **Typecheck verde** — `pnpm tsc --noEmit` zero erros após migrar services novos pra `legacyDb` client (sem generics) e atualizar fixtures dos tests existentes.
- **Commit limpo** — `053334b` em `feat/oficina-pro-merge`, 17 arquivos, +2106 linhas.
- **Branch criado corretamente** — `feat/oficina-pro-merge` partindo de `master` (status atualizado com origin).

## O que NÃO funcionou (e por quê)

- **Primeira tentativa de mutations nos services** — TypeScript retornou `never` em todos os `.insert({...})` e `.update({...})` das tabelas legacy (ordens_servico, clients, vehicles, os_anexos, etc). Causa: `db-types.ts` em `src/lib/` é **hand-maintained** cobrindo só as 9 tabelas do schema `portal` (profiles, empresas, sugestoes, trilhas). As ~17 tabelas legacy do DOCTOR PRIME têm só `[key: string]: UntypedTable` index signature, que o supabase-js v2 não resolve direito em `.insert()`. **Fix aplicado:** criei `legacyDb` em `src/lib/supabase.ts` — novo client com `createClient()` sem Database generic. Todos os services novos usam `import { legacyDb as supabase }`. Services existentes (Wave 1) também migrados pro mesmo pattern.
- **`supabase gen types` não foi usado** — tentei via `mcp__claude_ai_Supabase__generate_typescript_types`, mas o output (100k+ chars) excedeu o limit do tool e seria inviável manter sincronizado. Fica como tech debt: em sessão futura, adicionar script `pnpm db:types:pull` que roda esse gen e salva em `src/lib/db-types-generated.ts` separado do hand-written.
- **Fixtures dos tests quebraram após types.ts extension** — 3 erros em `__tests__/ClientesList.test.tsx` e `OSDetail.test.tsx` porque os fixtures não tinham `notes/tier` (Cliente), `mecanico_id/consultor_id/service_type/diagnosis/final_cost/advance_payment/updated_at` (OrdemServico), `cost/complexity` (OSItem). Fix direto: adicionei os campos com valor `null` / default nos fixtures.

## O que ainda não foi tentado

- **Port UI do oficina-pro** — 10 OS cards (`oficina-pro/client/src/components/os/` = os-header + os-status-pipeline + os-items-card + os-diagnostic-card + os-attachments-card + os-history-card + os-checklist-card + os-quick-actions + os-info-cards + os-constants), customer-detail-drawer (273 linhas), customer-workflow-wizard (525 linhas).
- **Port das 8 pages** — agenda.tsx (90), customers.tsx (343), dashboard.tsx (129), financeiro.tsx (68), orders.tsx (234), patio.tsx Kanban (88), service-order-detail.tsx (136), users-management.tsx (123).
- **Adaptação wouter→react-router** — oficina-pro usa `wouter/use-hash-location` + `useRoute`; portal-familia usa `react-router-dom` + `createBrowserRouter` + `useParams`. Import swap em cada page.
- **Adaptação auth passport→Supabase** — oficina-pro tem `@/lib/auth` com passport session + `useAuth()`; portal-familia tem `@/contexts/AuthContext`. Conceitualmente compatíveis, mas shape diferente.
- **Adaptação Express fetch→supabase-js** — pages do oficina-pro fazem `fetch('/api/service-orders/...')` + `apiRequest('PATCH', ...)`; precisa substituir por chamadas aos services já criados (`getOSFullBundle`, `updateOSStatus`, etc).
- **Rotas no portal-familia** — `src/router/index.tsx` já tem `OSList`/`OSDetail`/`ClientesList`/`AgendaView` do Wave 1. Precisa SUBSTITUIR o conteúdo desses arquivos (ou renomear/deletar), e ADICIONAR rotas novas: `/consultor/patio`, `/consultor/financeiro`, `/admin/users`.
- **Sidebar integration** — `src/components/Sidebar.tsx` do portal-familia precisa entradas novas (Pátio, Financeiro, Admin/Users) com RoleGate.
- **Smoke test** — Playwright/Vitest não rodei nesta sessão. CI do GitHub não disparado (branch local ainda não pushed).
- **Deploy VPS** — `infra/deploy.sh` não rodado. Cloudflare Tunnel `portal.doctorautoprime40.com` ainda aponta pro Wave 1.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `portal-familia/docs/MIGRATION_OFICINA_PRO.md` | ✅ Completo | Plano completo, schema mapping, fases, critério de pronto. Fonte de verdade pra retomar. |
| `supabase/migrations/20260424_07_oficina_pro_merge.sql` | ✅ Completo · aplicado em prod | ALTER em 6 tabelas + DROP/CREATE `os_anexos` (UUID) + CREATE `os_checklists` + `os_payments` + RLS helper `current_empresa_id()` + policies. |
| `portal-familia/src/features/consultor/types.ts` | ✅ Completo | +ClienteTier, notes/tier em Cliente; color/vin em Veiculo; OSStatusCanon (11 status); mecanico_id/consultor_id/service_type/diagnosis/final_cost/advance_payment/updated_at em OrdemServico; OSItemTipo/Complexidade/Status; OSAnexo/OSChecklist/OSPayment; Mecanico/MecanicoNivel; Colaborador/ColaboradorCargo; OSDetailFullBundle. |
| `portal-familia/src/features/consultor/workflow.ts` | ✅ Completo | STATUS_META (11 status com cor/ordem/terminal/legado), PIPELINE_STATUSES, TRANSITIONS, ROLE_POWERS (admin/gestor/consultor/mecanico/recepcao), `allowedTransitions()`, `statusLabel()`, `statusColor()`, `isTerminal()`. |
| `portal-familia/src/features/consultor/services/osItemsService.ts` | ✅ Completo | listItens, createItem, updateItem, deleteItem, computeTotais (agregado de itens por tipo, margem). |
| `portal-familia/src/features/consultor/services/osHistoricoService.ts` | ✅ Completo | listHistorico, createHistorico, registerStatusChange helper. |
| `portal-familia/src/features/consultor/services/osAnexosService.ts` | ✅ Completo | listAnexos, uploadAnexo (Storage + DB row + rollback), getSignedUrl (1h TTL), deleteAnexo. detectTipo por mime. |
| `portal-familia/src/features/consultor/services/osChecklistsService.ts` | ✅ Completo | getChecklist, upsertChecklist (1:1 com OS). |
| `portal-familia/src/features/consultor/services/osPaymentsService.ts` | ✅ Completo | listPayments, createPayment, updatePayment, markAsPaid, summarizePayments (agregado), listPaymentsGlobal (financeiro). |
| `portal-familia/src/features/consultor/services/mecanicosService.ts` | ✅ Completo | listMecanicos (por empresa/ativo/nivel), getMecanicoById. |
| `portal-familia/src/features/consultor/services/osService.ts` | ✅ Completo · estendido | +getOSFullBundle (10 paralelos com fallback p/ best-effort em kommo/mecanico/consultor), +createOS, +updateOS, +updateOSStatus (valida transição via role + registra histórico). |
| `portal-familia/src/features/consultor/services/clientesService.ts` | ✅ Completo · estendido | +createCliente, +updateCliente. |
| `portal-familia/src/features/consultor/services/veiculosService.ts` | ✅ Completo · estendido | +createVeiculo (upper+trim placa), +updateVeiculo, +color/vin no mapping. |
| `portal-familia/src/features/consultor/services/index.ts` | ✅ Completo | Barrel re-exportando todos os services. |
| `portal-familia/src/lib/supabase.ts` | ✅ Completo · estendido | +legacyDb client (sem Database generic) pras tabelas DOCTOR PRIME legacy. Motivo documentado no comentário JSDoc. |
| `portal-familia/src/pages/consultor/__tests__/ClientesList.test.tsx` | ✅ Atualizado | Fixture fakeCliente agora inclui notes/tier. |
| `portal-familia/src/pages/consultor/__tests__/OSDetail.test.tsx` | ✅ Atualizado | Fixtures de OrdemServico e OSItem incluem campos novos. |
| `portal-familia/src/features/consultor/components/*` (10+ cards novos) | ❌ Não iniciado | Port do oficina-pro: OsHeader, OsStatusPipeline, OsItemsCard, OsDiagnosticCard, OsAttachmentsCard, OsHistoryCard, OsChecklistCard, OsQuickActions, OsInfoCards (5 variantes), customer-detail-drawer, customer-workflow-wizard. |
| `portal-familia/src/pages/consultor/OSList.tsx` | ⚠️ Wave 1 ativo | Precisa SUBSTITUIR pela versão oficina-pro (`orders.tsx` 234 linhas adapted). |
| `portal-familia/src/pages/consultor/OSDetail.tsx` | ⚠️ Wave 1 ativo | Precisa SUBSTITUIR pela versão oficina-pro (`service-order-detail.tsx` 136 linhas + 10 cards). |
| `portal-familia/src/pages/consultor/ClientesList.tsx` | ⚠️ Wave 1 ativo | Precisa SUBSTITUIR por `customers.tsx` 343 linhas + workflow wizard + drawer. |
| `portal-familia/src/pages/consultor/AgendaView.tsx` | ⚠️ Wave 1 ativo | Precisa SUBSTITUIR por `agenda.tsx` 90 linhas. |
| `portal-familia/src/pages/consultor/PatioKanban.tsx` | ❌ Não existe | Criar com base em `patio.tsx` 88 linhas + workflow_etapas join. |
| `portal-familia/src/pages/consultor/Financeiro.tsx` | ❌ Não existe | Criar com base em `financeiro.tsx` 68 linhas usando `listPaymentsGlobal` do osPaymentsService. |
| `portal-familia/src/pages/admin/UsersManagement.tsx` | ❌ Não existe | Nova rota `/admin/users`, só role=admin. Base: `users-management.tsx` 123 linhas. |
| `portal-familia/src/router/index.tsx` | ⚠️ Sem mudanças | Precisa rota /consultor/patio, /consultor/financeiro, /admin/users. |
| `portal-familia/src/components/Sidebar.tsx` | ⚠️ Sem mudanças | Precisa entradas novas com RoleGate. |

## Decisões tomadas

- **Extend existing schema em vez de criar novo** — razão: Supabase DOCTOR PRIME já tem `ordens_servico` + 40 tabelas com dados reais em produção (48 OS, 27 clientes, 497 kommo_messages). Criar schema paralelo duplicaria dados e desperdiçaria o investimento do Kommo/CRM.
- **Manter feature path `src/features/consultor/` em vez de renomear pra `src/features/os/`** — razão: Wave 1 do consultor já tem 15+ imports cross-project; renomear exigiria refactor em cascata por ganho zero. Expansão incremental dentro do nome existente é mais barata.
- **Drop+Recreate em `os_anexos`** — razão: tabela tinha 0 rows e schema quebrado (id integer vs ordens_servico.id uuid). Safe. Alternativa ALTER seria rename+migrate, overkill pra 0 rows.
- **legacyDb client separado sem Database generic** — razão: db-types.ts é hand-maintained com comentário explícito "tipar legacy poluiria o arquivo". Estender pras ~17 tabelas legacy adicionais dobraria manutenção sem valor (inserts já usam shapes explícitos dos services). Fix cirúrgico resolve typecheck sem refactor do pattern existente.
- **Criar helper `current_empresa_id()` via SECURITY DEFINER** — razão: RLS policies precisam comparar `empresa_id` da row com empresa do user logado; lookup em colaboradores via auth_user_id. SECURITY DEFINER pra bypass RLS recursivo no próprio lookup.
- **Storage bucket private com signed URLs (1h)** — razão: anexos de OS podem conter fotos de defeitos, placas, documentos pessoais. Público seria vazamento. 1h TTL balanceia UX (carrega rápido) com segurança (link compartilhado expira).
- **updateOSStatus valida transição por role** — razão: consultor não pode pular pra "em_execucao" (é função do mecânico); mecânico não pode "entregar" (é consultor/recepção). Validação na UI via `allowedTransitions()`, fallback RLS no backend.
- **oficina-pro morre definitivo (não paralelo)** — decisão do Thales ("morte"). Não há migração de dados porque oficina-pro rodava em SQLite local apenas de teste.
- **Tudo do oficina-pro absorve** (não só consultor) — decisão do Thales ("tudo"). Absorve Dashboard, Customers, Orders, OS Detail, Agenda, Pátio Kanban, Financeiro, Users-mgmt.

## Bloqueios & perguntas abertas

- **Escolha de caminho pro UI port pendente.** Último turno propus 3 opções:
  - **(A)** Dispatch agent dap-dev em background pra fazer o port completo
  - **(B)** Eu porto OS List + OS Detail primeiro (40% do valor)
  - **(C)** Pausa aqui, retoma em nova sessão
  Thales respondeu com `/handoff` em vez de escolher. Na próxima sessão, escolher A/B/C antes de qualquer código.
- **`numero_os` sequencial** — `ordens_servico.numero_os` hoje é text nullable sem geração automática. Port do `formatOsNumber(id)` helper do oficina-pro usa id int (não tem no uuid). Tech debt: criar função Postgres `next_os_number(empresa_id)` + trigger BEFORE INSERT. Por ora, UI pode usar placeholder ou deixar vazio.
- **Test coverage dos novos services** — zero. Foundation commitada sem testes pros 6 services novos + mutations. Tech debt a pagar na próxima sessão (com Vitest + mocks do supabase).
- **Migration não tem DOWN** — sem rollback script. Aceitável porque ALTER ADD COLUMN é idempotente via `IF NOT EXISTS` e novas tabelas têm `IF NOT EXISTS`. Mas `DROP TABLE os_anexos CASCADE` foi destrutivo (0 rows mitigou).
- **Wave 1 consultor ainda ativo em prod** — deploy atual (`portal.doctorautoprime40.com`) roda Wave 1. Substituição só acontece depois do UI port + deploy. Janela de risco: se alguém usar Wave 1 nesse meio-tempo, dados de OS ficam na base e serão lidos pela nova UI (compatível, mas UX diferente).

## Próximo passo exato

**Sessão retomada abre `C:\dev\dap4`**, checa `git status` (deve estar clean em `feat/oficina-pro-merge`), e faz PUSH do commit atual pra origin (`git push -u origin feat/oficina-pro-merge`) pra backup antes de mais mudanças.

Depois: **Thales escolhe A/B/C** (dispatch agent / port manual eu / pausa). Se B (manual), começar por:

```
1. Abrir oficina-pro/client/src/components/os/os-constants.tsx (147 linhas)
   → copiar pra portal-familia/src/features/consultor/components/os/os-constants.tsx
   → adaptar: importar STATUS_META de @/features/consultor/workflow
2. Abrir os-header.tsx (79 linhas)
   → copiar, adaptar imports (wouter → react-router-dom), trocar tipos p/ OrdemServico do @/features/consultor/types
3. Repetir pros 8 cards restantes, um por um
4. Copiar service-order-detail.tsx (136 linhas) pro portal-familia/src/pages/consultor/OSDetail.tsx
   → substituir fetch('/api/service-orders/:id/full') por getOSFullBundle() do osService
   → substituir useRoute() por useParams()
5. pnpm tsc --noEmit + pnpm vitest run → tudo verde
6. Commit "feat(portal-familia): port OS detail + 10 cards do oficina-pro"
```

Fonte de verdade pro passo-a-passo: `portal-familia/docs/MIGRATION_OFICINA_PRO.md` seção "Fases de execução".

## Setup / comandos úteis

```bash
# Working dir
cd C:\dev\dap4

# Branch atual
git branch --show-current   # → feat/oficina-pro-merge

# Status das tabelas novas
# (verificação via MCP Supabase, projeto cpzgtfblywexqglqkgbt=DAP4.0 / acuufrgoyjwzlyhopaus=DOCTOR PRIME)
# Portal-familia conecta em DOCTOR PRIME (.env.local)

# Typecheck
cd portal-familia && pnpm tsc --noEmit

# Tests (não rodados nesta sessão)
pnpm vitest run

# Build
pnpm build

# oficina-pro source (read-only daqui pra frente)
cd /c/Users/docto/OneDrive/Área de Trabalho/oficina-pro
# branch feat/os-detail tem WIP uncommitted — serve como source of truth do port

# Deploy (não rodado)
cd /c/dev/dap4/infra && ./deploy.sh
```

## Arquivos de referência

- **Plano completo:** `C:\dev\dap4\portal-familia\docs\MIGRATION_OFICINA_PRO.md`
- **Migration SQL:** `C:\dev\dap4\supabase\migrations\20260424_07_oficina_pro_merge.sql`
- **Commit:** `053334b` — `feat(portal-familia): foundation pra absorver oficina-pro — migration + services + workflow`
- **Source oficina-pro:** `c:\Users\docto\OneDrive\Área de Trabalho\oficina-pro\client\src\`
