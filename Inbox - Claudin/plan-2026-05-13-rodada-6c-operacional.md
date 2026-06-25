---
type: implementation-plan
date: 2026-05-13
project: DAP 4.0 / 5-dap-operacao (Portal Consultor)
rodada: 6c (Operacional — Dashboard, Pátio, Agenda, Linha do Tempo)
depends_on: PR Rodada 6a + PR Rodada 6b mergeadas em master
branch_to_create: feat/consultor-rodada-6c-operacional
---

# Rodada 6c — Operacional Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar as 4 páginas operacionais (Dashboard, Pátio, Agenda, Linha do Tempo) em uma identidade visual unificada do consultor, consumindo as foundations das Rodadas 6a + 6b. Dashboard deixa de ser placeholder e vira central de operação do dia. Pátio ganha colunas alinhadas com `MAIN_STATUS_FLOW`. Agenda passa de lista cronológica pra grade horária. Linha do Tempo (já existe Gantt v1) ganha filtros + padronização de header. Zero novo endpoint backend obrigatório (1 opcional sinalizado).

**Architecture:** Refator client-side em 4 páginas. Reuso integral dos primitives 6a (`PageHeader`, `FilterBar`, `EmptyState`, `SectionHeader`, `TierBadge`) + STATUS_META existente em `os-constants.tsx`. Consultas via TanStack Query (queryKey URL-segmentável, sem queryFn custom — regra do projeto). Money em integer cents via `formatCentsBRL`. Filtragem in-memory (datasets do consultor são pequenos por org).

**Tech Stack:** React + TypeScript + Tailwind + shadcn/ui · TanStack Query v5 · Wouter · Lucide React · sem teste client (regra do projeto — só `tsc --noEmit`)

---

## Pre-flight

- [ ] **PR Rodada 6a mergeada em master.** Confirma com `gh pr list --state merged --search "Rodada 6a"`. Se não mergeado, **PARE**.
- [ ] **PR Rodada 6b mergeada em master.** Confirma com `gh pr list --state merged --search "Rodada 6b"`. Se não mergeado, **PARE**.
- [ ] **Confirma primitives 6a presentes:**
  ```bash
  ls C:/THALES/DAP4/5-dap-operacao/client/src/design-system/
  # Espera: page-header.tsx tier-badge.tsx empty-state.tsx section-header.tsx filter-bar.tsx index.ts
  ```
  Se algum faltar, 6a não foi mergeada — **PARE**.
- [ ] **Branch nova from master:**
  ```bash
  cd C:/THALES/DAP4/5-dap-operacao
  git fetch origin
  git checkout master && git pull
  git checkout -b feat/consultor-rodada-6c-operacional
  ```
- [ ] **Sanity tsc inicial (linha de base):**
  ```bash
  npx tsc --noEmit --pretty false; echo "exit=$?"
  ```
  Expected: exit 0. Se já vier vermelho, **PARE** e abre issue.

---

## File Structure

**Pages (refatoradas, NÃO recriadas):**
- `client/src/pages/dashboard.tsx` — refator completo (passa de KPIs estáticos pra central operacional)
- `client/src/pages/patio.tsx` — refator visual (colunas alinhadas com `MAIN_STATUS_FLOW`, cards reformatados)
- `client/src/pages/agenda.tsx` — refator estrutural (lista → grade horária)
- `client/src/pages/timeline.tsx` — refinamento (header padronizado + FilterBar; mantém Gantt existente)

**Helpers novos (frontend, isolados):**
- `client/src/lib/date-helpers.ts` (NEW) — `todayISO()`, `formatDatePtBR(date)`, `isToday(iso)`, `daysSince(iso)`, `addDays(date, n)`. Justificativa: as 4 páginas precisam dessas utilidades, melhor extrair que duplicar.

**Constantes:**
- `client/src/pages/agenda.tsx` — constante local `AGENDA_HOURS = Array.from({length:12},(_,i)=>i+8)` (08h-19h). Não vira shared porque não há consumidor externo.

**Backend (zero obrigatório). Opcional sinalizado:**
- `server/routes/stats.ts` — sugestão de aumentar payload com `todayAppointmentsCount` + `pendingFollowupsTodayCount` + `inYardCount` agregados (1 round-trip vs 3). **Não bloqueia a 6c**, é refinamento pra 6d.

---

## Task 1: date-helpers util

**Files:**
- Create: `client/src/lib/date-helpers.ts`

- [ ] **Step 1: Cria helpers**

```ts
// Helpers de data pt-BR. ISO date strings (yyyy-mm-dd) são o formato canônico
// usado em customers.createdAt, serviceOrders.createdAt, appointments.date.
// Mantém locale fixo pra consistência operacional.

export function todayISO(): string {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

export function formatDatePtBR(input: string | Date | null | undefined): string {
  if (!input) return "—";
  const d = typeof input === "string" ? new Date(input.length === 10 ? `${input}T12:00` : input) : input;
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("pt-BR", { day: "2-digit", month: "long", year: "numeric" });
}

export function formatDateShortPtBR(input: string | Date | null | undefined): string {
  if (!input) return "—";
  const d = typeof input === "string" ? new Date(input.length === 10 ? `${input}T12:00` : input) : input;
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("pt-BR", { day: "2-digit", month: "short" });
}

export function isToday(iso: string | null | undefined): boolean {
  if (!iso) return false;
  return iso.slice(0, 10) === todayISO();
}

export function isThisMonth(iso: string | null | undefined): boolean {
  if (!iso) return false;
  const today = new Date();
  const target = new Date(iso.length === 10 ? `${iso}T12:00` : iso);
  if (Number.isNaN(target.getTime())) return false;
  return (
    target.getFullYear() === today.getFullYear() &&
    target.getMonth() === today.getMonth()
  );
}

export function daysSince(iso: string | null | undefined): number {
  if (!iso) return 0;
  const start = new Date(iso).getTime();
  if (!Number.isFinite(start)) return 0;
  return Math.max(0, Math.floor((Date.now() - start) / (24 * 60 * 60 * 1000)));
}

export function addDays(base: Date, n: number): Date {
  const d = new Date(base);
  d.setDate(d.getDate() + n);
  return d;
}

export function isoDateOf(d: Date): string {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}
```

- [ ] **Step 2: tsc check**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add client/src/lib/date-helpers.ts
git commit -m "feat(client): date-helpers util for operational pages (todayISO, isToday, daysSince, addDays)"
```

---

## Task 2: Dashboard — header + KPIs operacionais

**Files:**
- Modify: `client/src/pages/dashboard.tsx` (rewrite total — preserva nome do componente `DashboardPage` default export)

- [ ] **Step 1: Substitui página inteira**

```tsx
import { useMemo } from "react";
import { Link } from "wouter";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Plus, Car, CalendarClock, DollarSign, Truck, AlertTriangle,
  PackageSearch, ClipboardCheck, LayoutGrid, Calendar as CalendarIcon,
  Users, ListChecks, GanttChartSquare,
} from "lucide-react";
import {
  PageHeader, SectionHeader, EmptyState,
} from "@/design-system";
import { STATUS_META, osNumber } from "@/components/os/os-constants";
import { formatCentsBRL } from "@/lib/money";
import { formatDatePtBR, isToday, isThisMonth } from "@/lib/date-helpers";
import type { ServiceOrder, Appointment, Payment } from "@shared/schema";

const IN_YARD_STATUSES = new Set(["aprovado", "em_execucao", "aguardando_peca", "pronto"]);

interface StatsResponse {
  totalOrders: number;
  totalCustomers: number;
  totalVehicles: number;
  statusCounts: Record<string, number>;
  totalRevenue: number;
  recentOrders: ServiceOrder[];
}

export default function DashboardPage() {
  const today = useMemo(() => new Date(), []);

  const { data: stats, isLoading: statsLoading } = useQuery<StatsResponse>({
    queryKey: ["/api/stats"],
  });
  const { data: orders = [], isLoading: ordersLoading } = useQuery<ServiceOrder[]>({
    queryKey: ["/api/service-orders"],
  });
  const { data: appointments = [], isLoading: apptsLoading } = useQuery<Appointment[]>({
    queryKey: ["/api/appointments"],
  });
  const { data: payments = [] } = useQuery<Payment[]>({
    queryKey: ["/api/payments"],
  });

  const isLoading = statsLoading || ordersLoading || apptsLoading;

  const veiculosNoPatio = orders.filter((o) => IN_YARD_STATUSES.has(o.status)).length;
  const agendamentosHoje = appointments.filter((a) => isToday(a.date)).length;
  const faturamentoMes = payments
    .filter((p) => p.status === "pago" && isThisMonth(p.createdAt ?? null))
    .reduce((sum, p) => sum + (p.amount ?? 0), 0);
  const entregasMes = orders.filter(
    (o) => o.status === "entregue" && isThisMonth(o.updatedAt ?? o.createdAt),
  ).length;

  const aguardandoAprovacao = orders.filter((o) => o.status === "aguardando_aprovacao");
  const aguardandoPeca = orders.filter((o) => o.status === "aguardando_peca");

  const kpis = [
    { label: "No pátio", value: veiculosNoPatio, icon: Car, hint: "OS aprovadas, em execução, aguardando peça ou prontas" },
    { label: "Hoje na agenda", value: agendamentosHoje, icon: CalendarClock, hint: formatDatePtBR(today) },
    { label: "Faturamento do mês", value: formatCentsBRL(faturamentoMes), icon: DollarSign, hint: "Pagamentos pagos no mês corrente" },
    { label: "Entregas no mês", value: entregasMes, icon: Truck, hint: "OS marcadas como entregues no mês" },
  ];

  const shortcuts = [
    { href: "/consultor/patio", label: "Pátio", icon: LayoutGrid, count: veiculosNoPatio, hint: "carros em andamento" },
    { href: "/consultor/agenda", label: "Agenda", icon: CalendarIcon, count: agendamentosHoje, hint: "compromissos hoje" },
    { href: "/consultor/cadastros/clientes", label: "Clientes", icon: Users, count: stats?.totalCustomers ?? 0, hint: "no CRM" },
    { href: "/consultor/cadastros/os", label: "Lista de OS", icon: ListChecks, count: stats?.totalOrders ?? 0, hint: "OS no histórico" },
    { href: "/consultor/linha-do-tempo", label: "Linha do Tempo", icon: GanttChartSquare, count: undefined, hint: "produção" },
  ];

  if (isLoading) {
    return (
      <div className="container mx-auto p-6 space-y-6">
        <PageHeader
          eyebrow="DAP · OPERAÇÃO · DASHBOARD"
          title="Dashboard"
          subtitle={`Visão geral do dia · ${formatDatePtBR(today)}`}
        />
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <Card key={i}><CardContent className="pt-6"><Skeleton className="h-20 w-full" /></CardContent></Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      <PageHeader
        eyebrow="DAP · OPERAÇÃO · DASHBOARD"
        title="Dashboard"
        subtitle={`Visão geral do dia · ${formatDatePtBR(today)}`}
        actions={
          <Link href="/consultor/cadastros/os/nova">
            <Button data-testid="button-nova-os">
              <Plus className="w-4 h-4 mr-1" />Nova OS
            </Button>
          </Link>
        }
      />

      {/* KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {kpis.map((kpi) => (
          <Card key={kpi.label} className="border-card-border" data-testid={`kpi-${kpi.label.toLowerCase().replace(/\s+/g, "-")}`}>
            <CardContent className="pt-5 pb-4 px-5">
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <p className="text-[10px] font-mono uppercase tracking-[0.16em] text-muted-foreground">
                    {kpi.label}
                  </p>
                  <p className="text-2xl font-bold mt-1 tabular-nums">{kpi.value}</p>
                  <p className="text-[11px] text-muted-foreground mt-1 truncate">{kpi.hint}</p>
                </div>
                <kpi.icon className="w-7 h-7 text-muted-foreground/60 shrink-0" />
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Pendências do dia */}
      <section className="space-y-3">
        <SectionHeader
          icon={<AlertTriangle className="w-3.5 h-3.5" />}
          label="Pendências do dia"
          count={aguardandoAprovacao.length + aguardandoPeca.length}
        />
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <PendenciaCard
            label="Aguardando aprovação"
            icon={<ClipboardCheck className="w-4 h-4 text-amber-500" />}
            orders={aguardandoAprovacao}
            empty="Nenhuma OS aguardando aprovação."
            badgeClass="bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 border-amber-200 dark:border-amber-900/50"
          />
          <PendenciaCard
            label="Aguardando peça"
            icon={<PackageSearch className="w-4 h-4 text-orange-500" />}
            orders={aguardandoPeca}
            empty="Nenhuma OS aguardando peça."
            badgeClass="bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400 border-orange-200 dark:border-orange-900/50"
          />
        </div>
        <p className="text-[11px] text-muted-foreground">
          Followups do pós-venda do dia precisam de endpoint dedicado (sugestão Rodada 6d:
          <code className="mx-1 font-mono">GET /api/post-sale-followups?scheduledDate=today</code>).
          Por ora, vê em Detalhe da OS &gt; Pós-venda.
        </p>
      </section>

      {/* Atalhos operacionais */}
      <section className="space-y-3">
        <SectionHeader label="Atalhos operacionais" />
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
          {shortcuts.map((s) => (
            <Link key={s.href} href={s.href}>
              <a className="block group" data-testid={`shortcut-${s.label.toLowerCase().replace(/\s+/g, "-")}`}>
                <Card className="border-card-border transition hover:border-primary/40 hover:shadow-sm cursor-pointer h-full">
                  <CardContent className="p-4 flex flex-col items-center text-center gap-2">
                    <s.icon className="w-7 h-7 text-muted-foreground group-hover:text-primary transition" />
                    <p className="text-sm font-medium leading-tight">{s.label}</p>
                    {typeof s.count === "number" && (
                      <p className="text-[11px] text-muted-foreground tabular-nums">
                        <span className="font-semibold">{s.count}</span> {s.hint}
                      </p>
                    )}
                  </CardContent>
                </Card>
              </a>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}

function PendenciaCard({
  label, icon, orders, empty, badgeClass,
}: {
  label: string;
  icon: React.ReactNode;
  orders: ServiceOrder[];
  empty: string;
  badgeClass: string;
}) {
  return (
    <Card className="border-card-border">
      <CardContent className="p-4 space-y-3">
        <div className="flex items-center gap-2">
          {icon}
          <p className="text-sm font-medium">{label}</p>
          <span className={`ml-auto inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-mono uppercase tracking-[0.12em] border ${badgeClass}`}>
            {orders.length}
          </span>
        </div>
        {orders.length === 0 ? (
          <EmptyState title={empty} />
        ) : (
          <ul className="space-y-1.5 max-h-64 overflow-y-auto">
            {orders.slice(0, 8).map((o) => {
              const meta = STATUS_META[o.status];
              return (
                <li key={o.id}>
                  <Link href={`/consultor/cadastros/os/${o.id}`}>
                    <a className="flex items-center gap-2 px-2 py-1.5 rounded-md hover:bg-muted/50 transition">
                      <span className="text-xs font-mono text-muted-foreground tabular-nums">{osNumber(o.id)}</span>
                      <span className="text-xs truncate flex-1">{o.description}</span>
                      <span className={`shrink-0 inline-flex items-center px-1.5 py-0.5 rounded text-[9px] font-mono uppercase ${meta?.chip ?? ""}`}>
                        {meta?.label ?? o.status}
                      </span>
                    </a>
                  </Link>
                </li>
              );
            })}
            {orders.length > 8 && (
              <li className="text-[11px] text-muted-foreground text-center pt-1">
                +{orders.length - 8} mais
              </li>
            )}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}
```

> **Nota sobre `Payment` import:** se `Payment` não for exportado de `@shared/schema`, troca pra `import type { ServiceOrder, Appointment } from "@shared/schema"; type Payment = { status: string; amount: number; createdAt?: string | null };` — datasets de pagamento são pequenos, tipo light vale.

- [ ] **Step 2: tsc check**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0. Se reclamar de `Payment`, aplica o fallback do step 1.

- [ ] **Step 3: Smoke local**

```bash
npm run dev
```

Manual:
- Abre `http://localhost:5000/consultor` (login admin antes)
- Header: eyebrow "DAP · OPERAÇÃO · DASHBOARD" + título "Dashboard" + subtitle data hoje em pt-BR + botão "+ Nova OS" no canto direito
- 4 KPIs renderizam com valores plausíveis (não zero universal — confere com dados reais do org)
- Pendências: 2 cards lado a lado, com badge contagem + lista de OS clicável
- Atalhos: 5 cards em grid, hover destaca, click navega
- Click em "Nova OS" → vai pra `/consultor/cadastros/os/nova`

- [ ] **Step 4: Commit**

```bash
git add client/src/pages/dashboard.tsx
git commit -m "feat(consultor): dashboard refactor — KPIs operacionais + pendências do dia + atalhos"
```

---

## Task 3: Pátio — header padronizado + FilterBar

**Files:**
- Modify: `client/src/pages/patio.tsx` (refator visual completo, mantém kanban)

- [ ] **Step 1: Substitui página inteira**

```tsx
import { useMemo, useState } from "react";
import { Link } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { Plus, ChevronRight } from "lucide-react";
import { PageHeader, FilterBar, EmptyState } from "@/design-system";
import { STATUS_META, MAIN_STATUS_FLOW, osNumber } from "@/components/os/os-constants";
import { formatCentsBRL } from "@/lib/money";
import { daysSince } from "@/lib/date-helpers";
import type { ServiceOrder, Customer, Vehicle, User } from "@shared/schema";

// Pátio mostra apenas OS ativas — entregue/cancelado vão pro Histórico.
const PATIO_FLOW = MAIN_STATUS_FLOW.filter(
  (s) => s !== "entregue" && s !== "cancelado",
);

export default function PatioPage() {
  const { toast } = useToast();
  const [search, setSearch] = useState("");
  const [consultantFilter, setConsultantFilter] = useState<string>("all");
  const [statusFilter, setStatusFilter] = useState<string>("all");

  const { data: orders = [] } = useQuery<ServiceOrder[]>({ queryKey: ["/api/service-orders"] });
  const { data: customers = [] } = useQuery<Customer[]>({ queryKey: ["/api/customers"] });
  const { data: vehicles = [] } = useQuery<Vehicle[]>({ queryKey: ["/api/vehicles"] });
  const { data: users = [] } = useQuery<User[]>({ queryKey: ["/api/users"] });

  const updateStatus = useMutation({
    mutationFn: async ({ id, status }: { id: number; status: string }) => {
      const res = await apiRequest("PATCH", `/api/service-orders/${id}`, { status });
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/service-orders"] });
      queryClient.invalidateQueries({ queryKey: ["/api/stats"] });
      toast({ title: "Status atualizado" });
    },
  });

  const customerById = useMemo(() => new Map(customers.map((c) => [c.id, c])), [customers]);
  const vehicleById = useMemo(() => new Map(vehicles.map((v) => [v.id, v])), [vehicles]);
  const userById = useMemo(() => new Map(users.map((u) => [u.id, u])), [users]);

  const consultants = useMemo(
    () => users.filter((u) => u.role === "consultor" || u.role === "admin"),
    [users],
  );

  const filtered = useMemo(() => {
    return orders.filter((o) => {
      if (!PATIO_FLOW.includes(o.status as any)) return false;
      if (statusFilter !== "all" && o.status !== statusFilter) return false;
      // Consultor pode estar em createdBy ou um campo dedicado — adapta no recon real.
      if (consultantFilter !== "all" && String((o as any).consultantId ?? "") !== consultantFilter) return false;
      if (search) {
        const q = search.toLowerCase();
        const customer = customerById.get(o.customerId);
        const vehicle = vehicleById.get(o.vehicleId);
        const haystack = [
          osNumber(o.id),
          o.description,
          customer?.name,
          vehicle?.plate,
          vehicle?.brand,
          vehicle?.model,
        ]
          .filter(Boolean)
          .join(" ")
          .toLowerCase();
        if (!haystack.includes(q)) return false;
      }
      return true;
    });
  }, [orders, statusFilter, consultantFilter, search, customerById, vehicleById]);

  const hasActiveFilters = search !== "" || consultantFilter !== "all" || statusFilter !== "all";
  const clearFilters = () => {
    setSearch("");
    setConsultantFilter("all");
    setStatusFilter("all");
  };

  const nextStatus = (current: string) => {
    const idx = PATIO_FLOW.indexOf(current as any);
    return idx >= 0 && idx < PATIO_FLOW.length - 1 ? PATIO_FLOW[idx + 1] : null;
  };

  return (
    <div className="container mx-auto p-6 space-y-6">
      <PageHeader
        eyebrow="DAP · OPERAÇÃO · PÁTIO"
        title="Pátio"
        subtitle={`${filtered.length} ${filtered.length === 1 ? "OS ativa" : "OS ativas"}`}
        actions={
          <Link href="/consultor/cadastros/os/nova">
            <Button data-testid="button-nova-os">
              <Plus className="w-4 h-4 mr-1" />Nova OS
            </Button>
          </Link>
        }
      />

      <FilterBar
        search={{ value: search, onChange: setSearch, placeholder: "Buscar OS, placa, cliente…" }}
        hasActiveFilters={hasActiveFilters}
        onClear={clearFilters}
      >
        <Select value={consultantFilter} onValueChange={setConsultantFilter}>
          <SelectTrigger className="w-[180px]" data-testid="filter-consultor">
            <SelectValue placeholder="Consultor" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos consultores</SelectItem>
            {consultants.map((u) => (
              <SelectItem key={u.id} value={String(u.id)}>{u.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-[180px]" data-testid="filter-status">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos status</SelectItem>
            {PATIO_FLOW.map((s) => (
              <SelectItem key={s} value={s}>{STATUS_META[s].label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </FilterBar>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3">
        {PATIO_FLOW.map((statusKey) => {
          const meta = STATUS_META[statusKey];
          const colOrders = filtered.filter((o) => o.status === statusKey);
          return (
            <div key={statusKey} className="space-y-2 min-w-0" data-testid={`column-${statusKey}`}>
              <div className="flex items-center gap-2 pb-2 border-b border-border/40">
                <span className={`w-2 h-2 rounded-full ${meta.dot}`} />
                <span className="text-[11px] font-semibold uppercase tracking-[0.12em] text-muted-foreground truncate">
                  {meta.label}
                </span>
                <span className="ml-auto text-[10px] font-mono text-muted-foreground tabular-nums">
                  {colOrders.length}
                </span>
              </div>
              {colOrders.length === 0 ? (
                <EmptyState title="—" className="py-6 text-[11px]" />
              ) : (
                colOrders.map((o) => {
                  const customer = customerById.get(o.customerId);
                  const vehicle = vehicleById.get(o.vehicleId);
                  const responsibleId = (o as any).mechanicId ?? (o as any).consultantId;
                  const responsible = responsibleId ? userById.get(responsibleId) : undefined;
                  const next = nextStatus(o.status);
                  const days = daysSince(o.createdAt);
                  return (
                    <Card key={o.id} className="border-card-border hover:border-primary/30 transition" data-testid={`patio-card-${o.id}`}>
                      <CardContent className="p-3 space-y-1.5">
                        <div className="flex items-center justify-between gap-2">
                          <Link href={`/consultor/cadastros/os/${o.id}`}>
                            <a className="text-xs font-mono font-bold text-primary hover:underline">
                              {osNumber(o.id)}
                            </a>
                          </Link>
                          {o.estimatedCost != null && (
                            <span className="text-[10px] text-muted-foreground tabular-nums">
                              {formatCentsBRL(o.estimatedCost)}
                            </span>
                          )}
                        </div>
                        {vehicle && (
                          <p className="text-xs font-mono uppercase tracking-wider truncate" data-testid={`patio-plate-${o.id}`}>
                            {vehicle.plate}
                          </p>
                        )}
                        {vehicle && (
                          <p className="text-xs text-muted-foreground truncate">
                            {vehicle.brand} {vehicle.model}
                          </p>
                        )}
                        {customer && (
                          <p className="text-xs truncate">{customer.name}</p>
                        )}
                        {responsible && (
                          <p className="text-[10px] text-muted-foreground truncate">
                            Resp.: {responsible.name}
                          </p>
                        )}
                        <p className="text-[10px] text-muted-foreground">
                          Há {days} {days === 1 ? "dia" : "dias"} no pátio
                        </p>
                        {next && (
                          <Button
                            size="sm"
                            variant="outline"
                            className="w-full h-7 text-[11px] mt-1"
                            onClick={() => updateStatus.mutate({ id: o.id, status: next })}
                            disabled={updateStatus.isPending}
                            data-testid={`patio-advance-${o.id}`}
                          >
                            <ChevronRight className="w-3 h-3 mr-1" />
                            {STATUS_META[next].label}
                          </Button>
                        )}
                      </CardContent>
                    </Card>
                  );
                })
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

> **Nota sobre `consultantId` / `mechanicId`:** o cast `(o as any).consultantId` é proposital — schema atual pode não ter esse campo. Se `serviceOrders` tem só `mechanicId`, deixe o filtro de consultor fechado por enquanto e abre issue pra Rodada 7. Se schema já tem `assignedConsultantId` ou similar, troca o cast pelo nome real após `tsc` apontar.

- [ ] **Step 2: tsc check**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 3: Smoke local**

Manual:
- Abre `/consultor/patio`
- Header padronizado com eyebrow, título, subtitle "X OS ativas", botão Nova OS
- FilterBar com search + 2 selects + botão Limpar quando ativo
- 6 colunas visíveis (em viewport ≥ xl): diagnostico, aguardando_aprovacao, aprovado, em_execucao, aguardando_peca, pronto
- Cards mostram: número OS (clicável), placa (mono uppercase), veículo, cliente, responsável, dias no pátio, botão avançar status
- Click no número OS → navega pra detalhe
- Click em "Avançar" → toast aparece, card pula coluna

- [ ] **Step 4: Commit**

```bash
git add client/src/pages/patio.tsx
git commit -m "feat(consultor): patio refactor — PageHeader + FilterBar + 6 colunas alinhadas com MAIN_STATUS_FLOW"
```

---

## Task 4: Agenda — grade horária + header padronizado

**Files:**
- Modify: `client/src/pages/agenda.tsx` (rewrite — lista vira grade horária)

- [ ] **Step 1: Substitui página inteira**

```tsx
import { useMemo, useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/hooks/use-toast";
import {
  Plus, ChevronLeft, ChevronRight, Trash2, Clock,
} from "lucide-react";
import { PageHeader, EmptyState } from "@/design-system";
import { formatDatePtBR, todayISO, addDays, isoDateOf } from "@/lib/date-helpers";
import type { Appointment, Customer, Mechanic } from "@shared/schema";

// Slots de 1h, 08h-19h. Configurável no futuro via settings da org.
const SLOT_HOURS: number[] = Array.from({ length: 12 }, (_, i) => i + 8); // 8..19

const STATUS_CHIP: Record<string, string> = {
  agendado: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
  confirmado: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
  cancelado: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  concluido: "bg-gray-100 text-gray-700 dark:bg-gray-800/50 dark:text-gray-400",
};

export default function AgendaPage() {
  const { toast } = useToast();
  const [selectedDate, setSelectedDate] = useState<string>(todayISO());
  const [slotPrefill, setSlotPrefill] = useState<{ time: string } | null>(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [openDetail, setOpenDetail] = useState<Appointment | null>(null);
  const [form, setForm] = useState({
    customerId: "",
    mechanicId: "",
    date: todayISO(),
    time: "",
    reason: "",
  });

  const { data: appointments = [] } = useQuery<Appointment[]>({
    queryKey: ["/api/appointments"],
  });
  const { data: customers = [] } = useQuery<Customer[]>({
    queryKey: ["/api/customers"],
  });
  const { data: mechanics = [] } = useQuery<Mechanic[]>({
    queryKey: ["/api/mechanics"],
  });

  const customerById = useMemo(() => new Map(customers.map((c) => [c.id, c])), [customers]);
  const mechanicById = useMemo(() => new Map(mechanics.map((m) => [m.id, m])), [mechanics]);

  const dayAppointments = useMemo(
    () => appointments.filter((a) => a.date === selectedDate),
    [appointments, selectedDate],
  );

  // Map "HH" -> appointments. Tolera "HH:mm" e "HH:mm:ss".
  const byHour = useMemo(() => {
    const m = new Map<number, Appointment[]>();
    for (const a of dayAppointments) {
      const hourStr = (a.time ?? "").slice(0, 2);
      const h = Number(hourStr);
      if (!Number.isFinite(h)) continue;
      const list = m.get(h) ?? [];
      list.push(a);
      m.set(h, list);
    }
    return m;
  }, [dayAppointments]);

  const createMutation = useMutation({
    mutationFn: async (data: any) => {
      const res = await apiRequest("POST", "/api/appointments", data);
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/appointments"] });
      setOpenDialog(false);
      setSlotPrefill(null);
      setForm({ customerId: "", mechanicId: "", date: selectedDate, time: "", reason: "" });
      toast({ title: "Agendamento criado" });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiRequest("DELETE", `/api/appointments/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/appointments"] });
      setOpenDetail(null);
      toast({ title: "Agendamento removido" });
    },
  });

  const goPrev = () => setSelectedDate(isoDateOf(addDays(new Date(selectedDate + "T12:00"), -1)));
  const goNext = () => setSelectedDate(isoDateOf(addDays(new Date(selectedDate + "T12:00"), 1)));
  const goToday = () => setSelectedDate(todayISO());

  const handleSlotClick = (hour: number) => {
    const time = `${String(hour).padStart(2, "0")}:00`;
    setSlotPrefill({ time });
    setForm((f) => ({ ...f, date: selectedDate, time }));
    setOpenDialog(true);
  };

  return (
    <div className="container mx-auto p-6 space-y-6">
      <PageHeader
        eyebrow="DAP · OPERAÇÃO · AGENDA"
        title="Agenda"
        subtitle={formatDatePtBR(new Date(selectedDate + "T12:00"))}
        actions={
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1 border border-border/60 rounded-md bg-card">
              <Button variant="ghost" size="icon" className="h-8 w-8" onClick={goPrev} data-testid="agenda-prev">
                <ChevronLeft className="w-4 h-4" />
              </Button>
              <Input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="border-0 h-8 w-[140px] text-xs"
                data-testid="agenda-date-input"
              />
              <Button variant="ghost" size="icon" className="h-8 w-8" onClick={goNext} data-testid="agenda-next">
                <ChevronRight className="w-4 h-4" />
              </Button>
            </div>
            <Button variant="outline" size="sm" onClick={goToday} data-testid="agenda-today">Hoje</Button>
            <Dialog open={openDialog} onOpenChange={(o) => { setOpenDialog(o); if (!o) setSlotPrefill(null); }}>
              <DialogTrigger asChild>
                <Button size="sm" data-testid="button-novo-agendamento">
                  <Plus className="w-4 h-4 mr-1" />Novo agendamento
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>
                    Novo agendamento {slotPrefill ? `· ${slotPrefill.time}` : ""}
                  </DialogTitle>
                </DialogHeader>
                <form
                  onSubmit={(e) => {
                    e.preventDefault();
                    createMutation.mutate({
                      customerId: Number(form.customerId),
                      mechanicId: form.mechanicId ? Number(form.mechanicId) : null,
                      date: form.date,
                      time: form.time,
                      reason: form.reason,
                    });
                  }}
                  className="space-y-3"
                >
                  <Select value={form.customerId} onValueChange={(v) => setForm({ ...form, customerId: v })}>
                    <SelectTrigger><SelectValue placeholder="Cliente *" /></SelectTrigger>
                    <SelectContent>
                      {customers.map((c) => (
                        <SelectItem key={c.id} value={String(c.id)}>{c.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Select value={form.mechanicId} onValueChange={(v) => setForm({ ...form, mechanicId: v })}>
                    <SelectTrigger><SelectValue placeholder="Mecânico" /></SelectTrigger>
                    <SelectContent>
                      {mechanics.map((m) => (
                        <SelectItem key={m.id} value={String(m.id)}>{m.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <div className="grid grid-cols-2 gap-3">
                    <Input
                      type="date"
                      value={form.date}
                      onChange={(e) => setForm({ ...form, date: e.target.value })}
                      required
                    />
                    <Input
                      type="time"
                      value={form.time}
                      onChange={(e) => setForm({ ...form, time: e.target.value })}
                      required
                    />
                  </div>
                  <Textarea
                    placeholder="Motivo da visita"
                    value={form.reason}
                    onChange={(e) => setForm({ ...form, reason: e.target.value })}
                    rows={2}
                  />
                  <Button type="submit" className="w-full" disabled={createMutation.isPending}>
                    Agendar
                  </Button>
                </form>
              </DialogContent>
            </Dialog>
          </div>
        }
      />

      <Card className="border-card-border">
        <CardContent className="p-0">
          <div className="divide-y divide-border/40">
            {SLOT_HOURS.map((h) => {
              const list = byHour.get(h) ?? [];
              const slotLabel = `${String(h).padStart(2, "0")}:00`;
              return (
                <div key={h} className="flex min-h-[64px]" data-testid={`slot-${slotLabel}`}>
                  <div className="w-20 shrink-0 border-r border-border/40 px-3 py-2 flex items-start gap-1.5">
                    <Clock className="w-3 h-3 text-muted-foreground/60 mt-0.5" />
                    <span className="text-xs font-mono tabular-nums text-muted-foreground">
                      {slotLabel}
                    </span>
                  </div>
                  <div className="flex-1 p-2">
                    {list.length === 0 ? (
                      <button
                        type="button"
                        onClick={() => handleSlotClick(h)}
                        className="w-full h-full min-h-[48px] rounded-md border border-dashed border-border/40 text-[11px] text-muted-foreground/60 hover:bg-muted/30 hover:border-primary/40 hover:text-primary transition flex items-center justify-center"
                        data-testid={`slot-empty-${slotLabel}`}
                      >
                        + Adicionar agendamento
                      </button>
                    ) : (
                      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
                        {list.map((a) => {
                          const customer = customerById.get(a.customerId);
                          const mechanic = a.mechanicId ? mechanicById.get(a.mechanicId) : undefined;
                          return (
                            <button
                              key={a.id}
                              type="button"
                              onClick={() => setOpenDetail(a)}
                              className="text-left p-2.5 rounded-md border border-card-border bg-card hover:border-primary/40 transition space-y-1"
                              data-testid={`slot-appointment-${a.id}`}
                            >
                              <div className="flex items-center justify-between gap-2">
                                <span className="text-xs font-medium truncate">
                                  {customer?.name ?? "—"}
                                </span>
                                <span className={`shrink-0 text-[9px] font-mono uppercase tracking-[0.1em] px-1.5 py-0.5 rounded ${STATUS_CHIP[a.status ?? "agendado"] ?? ""}`}>
                                  {a.status ?? "agendado"}
                                </span>
                              </div>
                              <p className="text-[11px] text-muted-foreground truncate">
                                {a.reason ?? "Sem motivo"}
                              </p>
                              {mechanic && (
                                <p className="text-[10px] text-muted-foreground truncate">
                                  Mec.: {mechanic.name}
                                </p>
                              )}
                            </button>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
          {dayAppointments.length === 0 && (
            <div className="border-t border-border/40">
              <EmptyState
                title="Sem agendamentos pra esse dia"
                description="Clique em um horário acima pra criar."
              />
            </div>
          )}
        </CardContent>
      </Card>

      {/* Detail dialog */}
      <Dialog open={openDetail !== null} onOpenChange={(o) => !o && setOpenDetail(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Agendamento</DialogTitle>
          </DialogHeader>
          {openDetail && (
            <div className="space-y-3">
              <div>
                <p className="text-[10px] font-mono uppercase tracking-wide text-muted-foreground">Cliente</p>
                <p className="text-sm font-medium">{customerById.get(openDetail.customerId)?.name ?? "—"}</p>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-[10px] font-mono uppercase tracking-wide text-muted-foreground">Data</p>
                  <p className="text-sm">{formatDatePtBR(new Date(openDetail.date + "T12:00"))}</p>
                </div>
                <div>
                  <p className="text-[10px] font-mono uppercase tracking-wide text-muted-foreground">Horário</p>
                  <p className="text-sm font-mono">{openDetail.time}</p>
                </div>
              </div>
              {openDetail.mechanicId && (
                <div>
                  <p className="text-[10px] font-mono uppercase tracking-wide text-muted-foreground">Mecânico</p>
                  <p className="text-sm">{mechanicById.get(openDetail.mechanicId)?.name ?? "—"}</p>
                </div>
              )}
              <div>
                <p className="text-[10px] font-mono uppercase tracking-wide text-muted-foreground">Motivo</p>
                <p className="text-sm">{openDetail.reason ?? "—"}</p>
              </div>
              <div className="flex items-center justify-end gap-2 pt-3 border-t border-border/40">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => deleteMutation.mutate(openDetail.id)}
                  disabled={deleteMutation.isPending}
                  className="text-destructive"
                  data-testid="agenda-delete"
                >
                  <Trash2 className="w-3.5 h-3.5 mr-1" />Cancelar
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
```

> **Nota sobre `Mechanic` import:** se o tipo não for exportado de `@shared/schema`, use `type Mechanic = { id: number; name: string };` localmente — só usamos id+name.

- [ ] **Step 2: tsc check**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 3: Smoke local**

Manual:
- Abre `/consultor/agenda`
- Header padronizado com data atual em pt-BR + nav prev/next + datepicker + botão Hoje + botão "Novo agendamento"
- Grid com 12 slots (08h-19h) em coluna vertical
- Slots vazios: linha tracejada com "+ Adicionar agendamento", click abre dialog pré-preenchido com horário
- Slots ocupados: cards com cliente + chip status + motivo + mecânico
- Click em slot ocupado: abre dialog de detalhes com botão Cancelar
- Navegação prev/next muda dia, datepicker pula direto, Hoje volta pra hoje

- [ ] **Step 4: Commit**

```bash
git add client/src/pages/agenda.tsx
git commit -m "feat(consultor): agenda refactor — grade horária 08h-19h + nav de dia + detail dialog"
```

---

## Task 5: Linha do Tempo — header padronizado + FilterBar

**Files:**
- Modify: `client/src/pages/timeline.tsx` (mantém Gantt v1 existente, troca header + adiciona FilterBar e mais janelas)

> **IMPORTANTE:** o arquivo `timeline.tsx` JÁ TEM Gantt v1 funcional (300 linhas, com janela ±3/7/14d, forecast por etapa). NÃO recriar. Refator pontual:
> 1. Substitui o `<header>` ad-hoc por `<PageHeader>` + actions com janelas (Hoje, 7 dias, 30 dias)
> 2. Adiciona `<FilterBar>` acima do Gantt com search (placa/cliente/OS) + select status + select consultor
> 3. Container externo: `container mx-auto p-6 space-y-6` (padronização)

- [ ] **Step 1: Modificar topo do arquivo (imports)**

Adicionar imports:

```ts
import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { GanttChartSquare, Info } from "lucide-react";

import type { ServiceOrder, Customer, Vehicle, User } from "@shared/schema";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { PageHeader, FilterBar, EmptyState } from "@/design-system";
import { STATUS_META as OS_STATUS_META, MAIN_STATUS_FLOW } from "@/components/os/os-constants";
```

> **Nota:** preservar `STATUS_META` local (com `estimatedHours`) — Gantt usa pra forecast. Pra evitar collision, importa `OS_STATUS_META` aliased só pra reusar no select de filtro de status.

- [ ] **Step 2: Adicionar state pros filtros (logo após `const [windowDays, setWindowDays] = useState<number>(7);`)**

```ts
const [search, setSearch] = useState("");
const [statusFilter, setStatusFilter] = useState<string>("all");
const [consultantFilter, setConsultantFilter] = useState<string>("all");

const { data: users = [] } = useQuery<User[]>({ queryKey: ["/api/users"] });
const consultants = useMemo(
  () => users.filter((u) => u.role === "consultor" || u.role === "admin"),
  [users],
);
```

- [ ] **Step 3: Aplica filtros no array `rows`**

Trocar o `.filter((o) => o.status !== "entregue" && o.status !== "cancelado")` por:

```ts
return orders
  .filter((o) => o.status !== "entregue" && o.status !== "cancelado")
  .filter((o) => {
    if (statusFilter !== "all" && o.status !== statusFilter) return false;
    if (consultantFilter !== "all" && String((o as any).consultantId ?? "") !== consultantFilter) return false;
    if (search) {
      const q = search.toLowerCase();
      const customer = customers.find((c) => c.id === o.customerId);
      const vehicle = vehicles.find((v) => v.id === o.vehicleId);
      const haystack = [
        `OS-${String(o.id).padStart(5, "0")}`,
        o.description,
        customer?.name,
        vehicle?.plate,
        vehicle?.brand,
        vehicle?.model,
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();
      if (!haystack.includes(q)) return false;
    }
    return true;
  })
  .map(/* mantém o map existente */)
```

- [ ] **Step 4: Trocar container raiz e header**

Substituir o bloco `<div className="mx-auto flex w-full max-w-[1440px] ...">` por:

```tsx
return (
  <div className="container mx-auto p-6 space-y-6">
    <PageHeader
      eyebrow="DAP · OPERAÇÃO · LINHA DO TEMPO"
      title="Linha do Tempo"
      subtitle="Carros em andamento posicionados no tempo. Sólido = realizado · tracejado = previsão."
      actions={
        <div className="flex items-center gap-1.5">
          {[
            { label: "Hoje", value: 1 },
            { label: "7 dias", value: 7 },
            { label: "30 dias", value: 30 },
          ].map((w) => (
            <Button
              key={w.value}
              variant={windowDays === w.value ? "default" : "outline"}
              size="sm"
              onClick={() => setWindowDays(w.value)}
              data-testid={`window-${w.value}`}
            >
              {w.label}
            </Button>
          ))}
        </div>
      }
    />

    <FilterBar
      search={{ value: search, onChange: setSearch, placeholder: "Buscar OS, placa, cliente…" }}
      hasActiveFilters={search !== "" || statusFilter !== "all" || consultantFilter !== "all"}
      onClear={() => { setSearch(""); setStatusFilter("all"); setConsultantFilter("all"); }}
    >
      <Select value={statusFilter} onValueChange={setStatusFilter}>
        <SelectTrigger className="w-[180px]" data-testid="filter-status">
          <SelectValue placeholder="Status" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">Todos status</SelectItem>
          {MAIN_STATUS_FLOW.filter((s) => s !== "entregue" && s !== "cancelado").map((s) => (
            <SelectItem key={s} value={s}>{OS_STATUS_META[s].label}</SelectItem>
          ))}
        </SelectContent>
      </Select>
      <Select value={consultantFilter} onValueChange={setConsultantFilter}>
        <SelectTrigger className="w-[180px]" data-testid="filter-consultor">
          <SelectValue placeholder="Consultor" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">Todos consultores</SelectItem>
          {consultants.map((u) => (
            <SelectItem key={u.id} value={String(u.id)}>{u.name}</SelectItem>
          ))}
        </SelectContent>
      </Select>
    </FilterBar>

    {/* ... resto do conteúdo Gantt mantido igual:
         legend, gantt grid, footnote ... */}
  </div>
);
```

> **Importante:** deletar o `<header>` ad-hoc atual (linhas ~136-168 do arquivo original) que tinha o ícone GanttChartSquare + título inline. O novo `PageHeader` substitui. **Manter** o resto: legend, time header, rows, footnote.

> **Estado vazio com filtros ativos:** quando `rows.length === 0`, mostrar `EmptyState` com texto "Nenhuma OS corresponde aos filtros." se algum filtro estiver ativo, ou texto original "Nenhum carro ativo no pátio." se sem filtros.

- [ ] **Step 5: tsc check**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 6: Smoke local**

Manual:
- Abre `/consultor/linha-do-tempo`
- Header padronizado: eyebrow, título, subtitle + 3 botões (Hoje/7d/30d) selecionáveis
- FilterBar: search + status + consultor + Limpar
- Aplicar filtro de status → Gantt mostra só rows correspondentes
- Aplicar search "ABC" (placa parcial) → filtra
- Limpar → restore tudo
- Sem rows com filtro ativo → EmptyState com mensagem específica

- [ ] **Step 7: Commit**

```bash
git add client/src/pages/timeline.tsx
git commit -m "feat(consultor): timeline header padronizado + FilterBar (search/status/consultor) + janelas Hoje/7d/30d"
```

---

## Task 6: Final verification

- [ ] **Step 1: Full tsc**

```bash
cd C:/THALES/DAP4/5-dap-operacao
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 2: Backend tests still green**

```bash
npx vitest run
```

Expected: zero regressão (6c não toca backend).

- [ ] **Step 3: Smoke E2E manual**

```bash
npm run dev
```

Walkthrough completo:
1. Login admin
2. Dashboard `/consultor` — 4 KPIs + 2 pendência cards + 5 atalhos
3. Click atalho "Pátio" → `/consultor/patio` com 6 colunas + filtros
4. Click numa OS no card → vai pro detalhe (rota Rodada 6b)
5. Voltar, click "Agenda" no atalho → `/consultor/agenda` com grade horária do dia
6. Navegar +1 dia, voltar Hoje
7. Click slot vazio → dialog pré-preenchido
8. Voltar, click "Linha do Tempo" → `/consultor/linha-do-tempo` com Gantt + filtros
9. Aplicar filtro status "em_execucao" → barras filtradas
10. Click "+ Nova OS" no header de qualquer página → `/consultor/cadastros/os/nova`

- [ ] **Step 4: Push branch**

```bash
git push -u origin feat/consultor-rodada-6c-operacional
```

- [ ] **Step 5: Abrir PR**

```bash
gh pr create --base master \
  --title "Rodada 6c — Operacional: Dashboard + Pátio + Agenda + Linha do Tempo padronizados" \
  --body "$(cat <<'EOF'
## Summary

Refator das 4 páginas operacionais do Portal Consultor para identidade visual unificada (Apex × Chassis), consumindo as foundations das Rodadas 6a + 6b.

### Mudanças por página

- **Dashboard** (`pages/dashboard.tsx`) — refator total: 4 KPIs operacionais (pátio / hoje / faturamento mês / entregas mês) + bloco Pendências (aguardando aprovação + aguardando peça) + 5 atalhos clicáveis. Header com data atual pt-BR e CTA Nova OS.
- **Pátio** (`pages/patio.tsx`) — kanban com 6 colunas alinhadas com `MAIN_STATUS_FLOW` (sem entregue/cancelado), cards com placa em mono uppercase + responsável + dias no pátio. FilterBar com search + status + consultor.
- **Agenda** (`pages/agenda.tsx`) — vira grade horária 08h-19h. Slot vazio = botão criar. Slot ocupado = card cliente clicável → detail dialog. Navegação prev/next/Hoje + datepicker.
- **Linha do Tempo** (`pages/timeline.tsx`) — Gantt v1 existente preservado. Header padronizado + FilterBar + 3 janelas (Hoje/7d/30d).

### Novo helper

- `client/src/lib/date-helpers.ts` — `todayISO`, `formatDatePtBR`, `isToday`, `isThisMonth`, `daysSince`, `addDays`, `isoDateOf`. Reuso em 4 páginas.

### Backend

Zero novo endpoint. Sugestão pra Rodada 6d: `GET /api/post-sale-followups?scheduledDate=today` pra Dashboard renderizar followups pendentes do dia (hoje aparece nota inline avisando).

## Test plan

- [ ] tsc verde
- [ ] Backend vitest sem regressão
- [ ] Dashboard: KPIs com valores reais, pendências clicáveis, atalhos navegam
- [ ] Pátio: 6 colunas, busca filtra, avançar status funciona
- [ ] Agenda: slot vazio cria, slot ocupado abre detail, nav de dia OK
- [ ] Linha do Tempo: filtros aplicam, janela alterna, Gantt continua íntegro

EOF
)"
```

---

## Self-review checklist (run before declaring complete)

- [ ] 4 páginas refatoradas (dashboard, patio, agenda, timeline) com PageHeader idêntico em estrutura
- [ ] Container `container mx-auto p-6 space-y-6` consistente nas 4
- [ ] STATUS_META reusado em pátio + dashboard pendências (sem reinventar cores)
- [ ] FilterBar primitive usado em pátio + timeline
- [ ] EmptyState primitive usado em agenda + dashboard pendências + timeline (filtro vazio)
- [ ] SectionHeader usado no dashboard (Pendências, Atalhos)
- [ ] date-helpers util criado e consumido
- [ ] Wouter `Link` mantido pra navegação (sem `window.location`)
- [ ] `useQuery` com queryKey URL-segmentável (sem queryFn custom)
- [ ] Money via `formatCentsBRL` (cents)
- [ ] Sem cookie / localStorage adicionado
- [ ] tsc verde no final
- [ ] Smoke manual nas 4 páginas + walkthrough completo

## Não escopo (fica pra 6d ou depois)

- Endpoint `GET /api/post-sale-followups?scheduledDate=today` consolidado (pra Dashboard mostrar followups do dia) → 6d
- Endpoint `GET /api/dashboard/today-summary` agregando KPIs em 1 round-trip → otimização 6d
- Endpoint `GET /api/timeline/gantt?period=...` com payload já filtrado/agregado → otimização 6d
- Drag-and-drop entre colunas no Pátio → 7
- Drag-and-drop entre slots na Agenda → 7
- Visualização semanal na Agenda (hoje só dia) → 7
- Gantt v2 com segmentação por etapa real (telemetry) → 7+
- Filtro de cliente/placa avulso na Linha do Tempo (já cabe no search) — não fazer
- Notificações em tempo real (websocket) → 8+

## Riscos conhecidos

1. **`timeline.tsx` JÁ tem Gantt v1 funcional** (não é placeholder como esperava o brief) — recon revelou 300 linhas com state, forecast por etapa, marcadores de "agora", janelas ±3/7/14d. O plano respeita isso e faz refator pontual (só header + FilterBar + ajusta janelas pra `Hoje/7d/30d`). Risco: durante o refator, mexer demais e quebrar o forecast existente. **Mitigação:** Task 5 lista exatamente quais blocos trocar; Steps 1-3 são adições e Step 4 substitui só `<header>` + container raiz.

2. **Schema pode não ter `consultantId` em `serviceOrders`** — o filtro de "consultor" no Pátio e Linha do Tempo assume esse campo. Recon de `shared/schema.ts:344+` mostra `appointments` com `mechanicId` mas não foi confirmado em `serviceOrders`. Mitigação: cast `(o as any).consultantId` permite tsc passar; se schema não tem o campo, filtro fica fechado e abre issue pra Rodada 7. **Não bloqueia merge.**

3. **`Payment` / `Mechanic` types podem não estar exportados de `@shared/schema`** — Dashboard e Agenda importam ambos. Mitigação: notas inline em cada Step indicam fallback (tipo light local) se tsc reclamar.

4. **`payments.createdAt` pode não existir** — fallback usa `o.createdAt` mas `payments` schema precisa ser confirmado. Se faltar, `faturamentoMes` cai pro filtro `p.status === "pago"` somando tudo (sem corte mensal). Mitigação: warning inline + ajuste rápido.

5. **`a.time` pode vir em formatos variados** (`"14:00"`, `"14:00:00"`, ISO completo) — Agenda agrupa por `a.time.slice(0, 2)`. Tolera os 3 formatos comuns mas se o backend gravar `null` ou string vazia, o slot é ignorado (correto — não tem como exibir sem hora).

6. **Volume de OS no Pátio + Linha do Tempo** — filtragem in-memory funciona até ~500 OS abertas. Acima disso, Gantt fica lento (paint cost). Org piloto tem 9 elevadores e ~50 OS/mês ativas, então confortável por enquanto. Sugestão pra 6d/7: paginação no `/api/service-orders` e filtros server-side.

7. **Rota `/consultor/cadastros/os/nova` precisa existir** — confirmada no recon de `App.tsx:76`. Se 6b mexeu nela e quebrou, o CTA Nova OS leva pra 404. Validar no smoke local.
