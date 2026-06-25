---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-operacao/README]]"
tags:
  - dap40
  - ui
  - frontend
  - paginas
---

# UI — Páginas, componentes, navegação

## Sidebar (`client/src/components/app-sidebar.tsx`)

Duas seções, role-aware:

```
┌─────────────────────────┐
│  ⚙️  DAP Operação       │
├─────────────────────────┤
│  Dashboard              │  todos
│  Linha do Tempo         │  todos
│  Clientes               │  todos
│  Ordens de Serviço      │  todos
│  Pátio Kanban           │  todos
│  Agenda                 │  todos
│  Financeiro             │  admin only
│                         │
│  COMERCIAL · ✨ AI      │
│  Avaliação CRM          │  admin
│  Leads pra Ligar        │  admin, recepcao
│  Clientes Adormecidos   │  admin, recepcao
├─────────────────────────┤
│  Thales — admin         │
│  Sair                   │
└─────────────────────────┘
```

## Páginas (`client/src/pages/`)

### Operação (eager — bundled na entry)

| Arquivo                       | Rota                  | O que faz                                                              |
| ----------------------------- | --------------------- | ---------------------------------------------------------------------- |
| `login.tsx`                   | (sem layout)          | Form login → POST `/api/auth/login`                                    |
| `dashboard.tsx`               | `/`                   | KPIs do dia + gráficos (Recharts)                                      |
| `customers.tsx`               | `/customers`          | Lista + busca + drawer de detalhe + wizard de criação                  |
| `orders.tsx`                  | `/orders`             | Lista de OS com filtros por status                                     |
| `service-order-detail.tsx`    | `/orders/:id`         | OS completa com 8 cards (header + diagnóstico + items + checklist…)   |
| `users-management.tsx`        | `/users`              | CRUD de usuários (admin)                                               |
| `not-found.tsx`               | (fallback)            | 404 amigável                                                           |

### Operação (lazy — code-split)

| Arquivo                       | Rota                  | O que faz                                                              |
| ----------------------------- | --------------------- | ---------------------------------------------------------------------- |
| `agenda.tsx`                  | `/agenda`             | Calendar view (react-day-picker) + lista de appointments               |
| `patio.tsx`                   | `/patio`              | Kanban 5 colunas (diagnóstico → entregue), drag implícito via PATCH    |
| `financeiro.tsx`              | `/financeiro`         | Faturamento mês, métodos, ticket médio, recebíveis                     |
| `timeline.tsx`                | `/timeline`           | **Gantt CSS-grid** das OSs ativas. Janela ±3/±7/±14 dias, barra sólida realizada + tracejada de previsão (heurística por etapa). |

### Comercial AI (lazy — todas WIP editorial)

| Arquivo                            | Rota                          | O que faz (planejado)                                            |
| ---------------------------------- | ----------------------------- | ---------------------------------------------------------------- |
| `comercial/index.tsx`              | `/comercial`                  | Overview com 3 cards de entrada                                  |
| `comercial/crm.tsx`                | `/comercial/crm`              | Avaliação CRM: score 0–100 por consultor, completude, follow-up, conversão |
| `comercial/leads.tsx`              | `/comercial/leads`            | Top 20 leads do dia ranqueados, roteiro IA, janela ideal, call+log |
| `comercial/adormecidos.tsx`        | `/comercial/adormecidos`      | Carteira inativa >180d, segmentada por valor potencial, mensagem IA, disparo WhatsApp |

> Comercial está em **WIP editorial honesto** — nenhuma página simula dados. Cada uma lista o que vai entregar e o que precisa ser conectado.

### Portais (lazy — preview AIos)

| Arquivo                          | Rota                          | O que faz                                              |
| -------------------------------- | ----------------------------- | ------------------------------------------------------ |
| `portais/index.tsx`              | `/portais`                    | Overview da arquitetura AIos (preview navegável)      |
| `portais/aios.tsx`               | `/portais/aios`               | Mandala Sophia + 12 diretores                          |
| `portais/sophia.tsx`             | `/portais/sophia`             | Sala do conselho                                       |
| `portais/director.tsx`           | `/portais/diretores/:slug`    | Página de cada diretor                                 |
| `portais/gestao.tsx`             | `/portais/gestao`             | Áreas de gestão                                        |
| `portais/area.tsx`               | `/portais/gestao/:slug`       | Área específica                                        |
| `portais/facilities.tsx`         | `/portais/facilities`         | Launcher de facilities                                 |
| `portais/dev.tsx`                | `/portais/dev`                | Entrada dev/sistemas                                   |

## Componentes especiais (`client/src/components/`)

### Root
- `app-sidebar.tsx` — Sidebar role-aware com seções
- `customer-detail-drawer.tsx` — Drawer (vaul) com detalhe completo do cliente
- `customer-workflow-wizard.tsx` — Wizard multi-step pra criação cliente+veículo+OS num fluxo só

### OS (`components/os/*`)
8 cards modulares usados em `service-order-detail.tsx`:
- `os-header.tsx` — Cabeçalho com nº OS, cliente, veículo, ações rápidas
- `os-status-pipeline.tsx` — Visual do fluxo de status (8 etapas, atual destacada)
- `os-quick-actions.tsx` — Botões rápidos (mudar status, gerar PDF, etc)
- `os-info-cards.tsx` — Cards informativos (custo estimado, custo final, sinal)
- `os-diagnostic-card.tsx` — Diagnóstico técnico
- `os-items-card.tsx` — Linhas (peças/serviços/mão de obra) com aprovação inline
- `os-checklist-card.tsx` — Checklist de entrada (capa de banco, KM, danos)
- `os-attachments-card.tsx` — Upload + grid de fotos/vídeos
- `os-history-card.tsx` — Timeline de comments + status changes
- `os-constants.tsx` — Constantes compartilhadas (cores, labels)

### UI primitives (`components/ui/*`)
shadcn standard: button, badge, card, input, label, dialog, dropdown-menu, popover, select, sheet, table, tabs, toast, etc. ~30 arquivos. Não documentar individualmente — Radix-backed, comportamento padrão.

## Hooks (`client/src/hooks/`)

- `use-mobile.tsx` — `useIsMobile(): boolean` via matchMedia
- `use-toast.ts` — Toast queue (shadcn pattern)

## Lib (`client/src/lib/`)

- `auth.tsx` — `<AuthProvider>` + `useAuth()` hook. Wrap React Query call em `/api/auth/me` + `login()`/`logout()` mutations
- `queryClient.ts` — TanStack Query client + `apiRequest(method, url, body)` helper
- `money.ts` — `formatCentsBRL`, `parseBrlInput` (BR-comma money inputs)
- `utils.ts` — `cn()` (clsx + tailwind-merge)

## Roteamento (`client/src/App.tsx`)

```tsx
<Router hook={useHashLocation}>
  <Sidebar />
  <main>
    <Suspense fallback={<Loader2 />}>
      <Switch>
        <Route path="/" component={DashboardPage} />
        <Route path="/timeline" component={TimelinePage} />
        <Route path="/customers" component={CustomersPage} />
        <Route path="/orders" component={OrdersPage} />
        <Route path="/orders/:id" component={ServiceOrderDetailPage} />
        <Route path="/users" component={UsersManagementPage} />
        <Route path="/agenda" component={AgendaPage} />
        <Route path="/patio" component={PatioPage} />
        <Route path="/financeiro" component={FinanceiroPage} />
        <Route path="/portais" component={PortaisOverviewPage} />
        <Route path="/portais/aios" component={PortaisAiosPage} />
        <Route path="/portais/sophia" component={PortaisSophiaPage} />
        <Route path="/portais/gestao" component={PortaisGestaoPage} />
        <Route path="/portais/gestao/:slug">{(p) => <PortaisAreaPage slug={p.slug} />}</Route>
        <Route path="/portais/facilities" component={PortaisFacilitiesPage} />
        <Route path="/portais/dev" component={PortaisDevPage} />
        <Route path="/portais/diretores/:slug">{(p) => <PortaisDirectorPage slug={p.slug} />}</Route>
        <Route path="/comercial" component={ComercialOverviewPage} />
        <Route path="/comercial/crm" component={ComercialCrmPage} />
        <Route path="/comercial/leads" component={ComercialLeadsPage} />
        <Route path="/comercial/adormecidos" component={ComercialAdormecidosPage} />
        <Route component={NotFound} />
      </Switch>
    </Suspense>
  </main>
</Router>
```

Total: **22 rotas**.

## Design tokens

Tailwind 3 + shadcn variables (HSL custom properties). Suporte dark/light via `next-themes`. Atualmente usa tema padrão shadcn — não personalizado pra cinematográfico premium ainda (próximo passo de design seguindo CLAUDE.md).
