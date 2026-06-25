---
type: implementation-plan
date: 2026-05-13
project: DAP 4.0 / 5-dap-operacao (Portal Consultor)
rodada: 6b (CRM + OS)
depends_on: PR Rodada 6a (foundations) mergeada em master
branch_to_create: feat/consultor-rodada-6b-crm-os
---

# Rodada 6b — CRM + OS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refatorar 5 páginas do Portal Consultor (Customers list, Customer detail, Orders list, OS detail) consumindo as foundations da Rodada 6a (DS primitives, stats endpoint, post-sale-followups CRUD). Adicionar 2 cards novos no detalhe da OS (Adiantamento + Pós-venda). Deletar 2 componentes legacy mortos (workflow wizard + drawer).

**Architecture:** Zero migration nesta rodada (6a já entregou tudo). Frontend-heavy. Refatora ficha do cliente em 7 sub-cards (Header, Fidelidade, Contato, Veículos, CRM-em-construção, Histórico OS com tabs, Timeline interações). Adiciona 2 modals (Adiantamento, Programar pós-venda) no detalhe da OS. Reusa primitives `PageHeader`, `TierBadge`, `EmptyState`, `SectionHeader`, `FilterBar` em todas as páginas listadas.

**Tech Stack:** React 18 + Vite · Tailwind + shadcn/ui · TanStack Query · Wouter · TypeScript strict

---

## Pre-flight

- [ ] **PR Rodada 6a mergeada em master.** Confirma:
  ```bash
  cd C:/THALES/DAP4/5-dap-operacao
  git fetch origin
  git log origin/master --oneline -10 | grep "Rodada 6a"
  ```
  Se não houver commit da 6a, **PARE** e mergeia primeiro.

- [ ] **Foundations existem em master.** Confirma:
  ```bash
  ls client/src/design-system/page-header.tsx \
     client/src/design-system/tier-badge.tsx \
     client/src/design-system/empty-state.tsx \
     client/src/design-system/section-header.tsx \
     client/src/design-system/filter-bar.tsx \
     server/routes/post-sale-followups.ts
  ```
  5 arquivos + route precisam existir. Se faltar algum, **PARE** e investiga.

- [ ] **Branch nova from master:**
  ```bash
  cd C:/THALES/DAP4/5-dap-operacao
  git checkout master && git pull
  git checkout -b feat/consultor-rodada-6b-crm-os
  ```

- [ ] **Smoke do tsc baseline antes de tocar nada:**
  ```bash
  npx tsc --noEmit --pretty false; echo "exit=$?"
  ```
  Expected: exit 0. Se != 0, **PARE** — master quebrada não é nosso problema agora.

---

## File Structure

**Pages (modificar):**
- `client/src/pages/customers.tsx` — refatora pra usar PageHeader + FilterBar + EmptyState + TierBadge + cliente desde
- `client/src/pages/customer-detail.tsx` — refatora GRANDE (7 sub-cards conforme spec)
- `client/src/pages/orders.tsx` — porta pra PageHeader + FilterBar + EmptyState
- `client/src/pages/service-order-detail.tsx` — adiciona 2 cards na coluna lateral + TODO comentário

**Components OS (criar):**
- `client/src/components/os/os-advance-payment-card.tsx` — NEW
- `client/src/components/os/os-post-sale-card.tsx` — NEW

**Components Customer (criar):**
- `client/src/components/customer/customer-header.tsx` — NEW (avatar + nome + tier + meta)
- `client/src/components/customer/customer-fidelidade-card.tsx` — NEW
- `client/src/components/customer/customer-contato-card.tsx` — NEW
- `client/src/components/customer/customer-veiculos-card.tsx` — NEW
- `client/src/components/customer/customer-crm-card.tsx` — NEW (em construção inline)
- `client/src/components/customer/customer-historico-os-card.tsx` — NEW (com tabs)
- `client/src/components/customer/customer-timeline-card.tsx` — NEW (post-sale-followups)

**Helpers (criar/modificar):**
- `client/src/lib/customer-tier.ts` — NEW (lógica de tier + progresso)
- `client/src/lib/format-date.ts` — NEW (helpers `formatDateBR`, `formatRelative`)

**Components (deletar):**
- `client/src/components/customer-workflow-wizard.tsx` — DELETE (dead code, sem imports)
- `client/src/components/customer-detail-drawer.tsx` — DELETE (dead code, sem imports)

**Backend (não toca):** Schema `category` em `service_order_comments` é text livre sem CHECK constraint — comporta `"adiantamento"` sem migration. Confirmado em `shared/schema.ts:294`.

---

## Task 1: Helper — formatDateBR + formatRelative

**Files:**
- Create: `client/src/lib/format-date.ts`

- [ ] **Step 1: Cria helpers**

```ts
// client/src/lib/format-date.ts
// Date formatting helpers — pt-BR. Aceita ISO strings (DB stores text).

/** "13/05/2026". Retorna "—" se input inválido. */
export function formatDateBR(input: string | null | undefined): string {
  if (!input) return "—";
  const d = new Date(input);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("pt-BR");
}

/** "13/05/2026 14:32". */
export function formatDateTimeBR(input: string | null | undefined): string {
  if (!input) return "—";
  const d = new Date(input);
  if (Number.isNaN(d.getTime())) return "—";
  return `${d.toLocaleDateString("pt-BR")} ${d.toLocaleTimeString("pt-BR", {
    hour: "2-digit",
    minute: "2-digit",
  })}`;
}

/** "há 3 dias", "há 2 meses", "ontem", "hoje". */
export function formatRelative(input: string | null | undefined): string {
  if (!input) return "—";
  const d = new Date(input);
  if (Number.isNaN(d.getTime())) return "—";
  const diffMs = Date.now() - d.getTime();
  const days = Math.floor(diffMs / (24 * 60 * 60 * 1000));
  if (days < 1) return "hoje";
  if (days === 1) return "ontem";
  if (days < 30) return `há ${days} dias`;
  const months = Math.floor(days / 30);
  if (months < 12) return `há ${months} ${months === 1 ? "mês" : "meses"}`;
  const years = Math.floor(days / 365);
  return `há ${years} ${years === 1 ? "ano" : "anos"}`;
}
```

- [ ] **Step 2: tsc check**

```bash
cd C:/THALES/DAP4/5-dap-operacao
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add client/src/lib/format-date.ts
git commit -m "feat(lib): add formatDateBR/formatDateTimeBR/formatRelative helpers"
```

---

## Task 2: Helper — customer-tier (lógica de tier + progresso)

**Files:**
- Create: `client/src/lib/customer-tier.ts`

- [ ] **Step 1: Cria helper**

```ts
// client/src/lib/customer-tier.ts
// Lógica de tier do cliente baseada no número de OS concluídas.
// bronze: <3 OS · prata: 3-9 · ouro: 10-24 · platina: 25+
//
// IMPORTANTE: este é o cálculo "esperado". O `customer.tier` salvo no DB
// é a fonte de verdade pra display (admin pode forçar). Esta função serve
// pro card de Fidelidade mostrar progresso até próximo nível.

import type { Tier } from "@/design-system";

export const TIER_THRESHOLDS: Record<Tier, { min: number; next: Tier | null; nextAt: number | null }> = {
  bronze: { min: 0, next: "prata", nextAt: 3 },
  prata: { min: 3, next: "ouro", nextAt: 10 },
  ouro: { min: 10, next: "platina", nextAt: 25 },
  platina: { min: 25, next: null, nextAt: null },
};

export function tierFromCompletedOrders(completed: number): Tier {
  if (completed >= 25) return "platina";
  if (completed >= 10) return "ouro";
  if (completed >= 3) return "prata";
  return "bronze";
}

export function tierProgressMessage(currentTier: Tier, completed: number): string {
  const meta = TIER_THRESHOLDS[currentTier];
  if (meta.next == null || meta.nextAt == null) {
    return "Nível máximo atingido";
  }
  const remaining = meta.nextAt - completed;
  if (remaining <= 0) {
    // Cliente já passou do limiar mas tier salvo no DB não atualizou — apenas
    // sinaliza. Não tenta atualizar o DB aqui (responsabilidade do backend).
    return `Pronto pra ${meta.next}`;
  }
  return `Faltam ${remaining} OS para virar ${meta.next}`;
}

/** 0..1 (proporção do progresso entre tier atual e próximo). */
export function tierProgressFraction(currentTier: Tier, completed: number): number {
  const meta = TIER_THRESHOLDS[currentTier];
  if (meta.next == null || meta.nextAt == null) return 1;
  const span = meta.nextAt - meta.min;
  if (span <= 0) return 1;
  const local = Math.max(0, completed - meta.min);
  return Math.min(1, local / span);
}
```

- [ ] **Step 2: tsc check + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
git add client/src/lib/customer-tier.ts
git commit -m "feat(lib): add customer tier thresholds + progress calculations"
```

---

## Task 3: Refactor `customers.tsx` — primitives + tier badge + cliente desde

**Files:**
- Modify: `client/src/pages/customers.tsx`

- [ ] **Step 1: Substitui o conteúdo inteiro do arquivo**

```tsx
// client/src/pages/customers.tsx
import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useLocation, Link } from "wouter";
import { apiRequest, queryClient } from "@/lib/queryClient";
import type { Customer, Vehicle } from "@shared/schema";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { useToast } from "@/hooks/use-toast";
import { Plus, Phone, Mail, Trash2, Edit, User, ChevronRight, Users } from "lucide-react";
import { useAuth } from "@/lib/auth";
import { PageHeader, FilterBar, EmptyState, TierBadge } from "@/design-system";
import { formatDateBR } from "@/lib/format-date";

/**
 * CRM dos clientes — visão card-based, leitura rápida.
 * Click no card → navega pra ficha (/consultor/cadastros/clientes/:id).
 * Botão + Cliente → /consultor/cadastros/clientes/novo.
 * Edit → /consultor/cadastros/clientes/:id/editar.
 * Delete continua inline AlertDialog.
 */
export default function CustomersPage() {
  const { user } = useAuth();
  const { toast } = useToast();
  const [, setLocation] = useLocation();
  const [search, setSearch] = useState("");
  const [deleteTarget, setDeleteTarget] = useState<Customer | null>(null);

  const { data: customers = [], isLoading } = useQuery<Customer[]>({
    queryKey: ["/api/customers"],
  });
  const { data: vehicles = [] } = useQuery<Vehicle[]>({
    queryKey: ["/api/vehicles"],
  });

  const vehiclesByCustomer = useMemo(() => {
    const map: Record<number, number> = {};
    for (const v of vehicles) map[v.customerId] = (map[v.customerId] || 0) + 1;
    return map;
  }, [vehicles]);

  const deleteMutation = useMutation({
    mutationFn: async (id: number) => {
      await apiRequest("DELETE", `/api/customers/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/customers"] });
      queryClient.invalidateQueries({ queryKey: ["/api/stats"] });
      toast({ title: "Cliente removido" });
    },
  });

  const filtered = customers.filter((c) => {
    const q = search.toLowerCase();
    return (
      c.name.toLowerCase().includes(q) ||
      c.phone.includes(search) ||
      (c.email?.toLowerCase().includes(q) ?? false) ||
      (c.cpf?.includes(search) ?? false)
    );
  });

  return (
    <div className="p-6 space-y-5">
      <PageHeader
        eyebrow="DAP · OPERAÇÃO · CRM"
        title="Clientes"
        subtitle={`${customers.length} cadastrados — clique num card pra abrir a ficha`}
        actions={
          <Link href="/consultor/cadastros/clientes/novo">
            <Button size="sm" data-testid="button-add-customer">
              <Plus className="w-4 h-4 mr-1" />
              Novo cliente
            </Button>
          </Link>
        }
      />

      <FilterBar
        search={{
          value: search,
          onChange: setSearch,
          placeholder: "Buscar por nome, telefone, e-mail ou CPF...",
        }}
        hasActiveFilters={search.length > 0}
        onClear={() => setSearch("")}
      />

      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {[...Array(6)].map((_, i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <Skeleton className="h-4 w-24 mb-2" />
                <Skeleton className="h-3 w-40" />
              </CardContent>
            </Card>
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={<Users />}
          title={search ? "Nenhum cliente bate com a busca" : "Nenhum cliente cadastrado"}
          description={
            search
              ? "Ajuste o termo de busca ou limpe o filtro."
              : "Cadastre o primeiro pra começar a populer o CRM."
          }
          action={
            !search ? (
              <Link href="/consultor/cadastros/clientes/novo">
                <Button>
                  <Plus className="w-4 h-4 mr-1" />
                  Novo cliente
                </Button>
              </Link>
            ) : undefined
          }
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {filtered.map((c) => (
            <CustomerCard
              key={c.id}
              customer={c}
              vehicleCount={vehiclesByCustomer[c.id] || 0}
              canDelete={user?.role === "admin"}
              onOpen={() => setLocation(`/consultor/cadastros/clientes/${c.id}`)}
              onDelete={() => setDeleteTarget(c)}
            />
          ))}
        </div>
      )}

      <AlertDialog open={!!deleteTarget} onOpenChange={(v) => !v && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Remover cliente?</AlertDialogTitle>
            <AlertDialogDescription>
              Essa ação não pode ser desfeita. O cliente{" "}
              <span className="font-medium text-foreground">{deleteTarget?.name}</span> será removido permanentemente.
              Veículos e ordens de serviço vinculados continuarão no sistema.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (deleteTarget) deleteMutation.mutate(deleteTarget.id);
                setDeleteTarget(null);
              }}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Remover
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}

interface CustomerCardProps {
  customer: Customer;
  vehicleCount: number;
  canDelete: boolean;
  onOpen: () => void;
  onDelete: () => void;
}

function CustomerCard({ customer, vehicleCount, canDelete, onOpen, onDelete }: CustomerCardProps) {
  return (
    <div
      role="button"
      tabIndex={0}
      onClick={onOpen}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          onOpen();
        }
      }}
      className="text-left cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 rounded-lg"
      data-testid={`card-customer-${customer.id}`}
    >
      <Card className="border-card-border hover:border-primary/40 hover:shadow-md transition-all h-full">
        <CardContent className="pt-4 pb-3 px-4">
          <div className="flex items-start justify-between gap-2">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-9 h-9 rounded-full bg-primary/10 text-primary flex items-center justify-center flex-shrink-0">
                <User className="w-4 h-4" />
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-2 min-w-0">
                  <p className="font-medium text-sm truncate">{customer.name}</p>
                  <TierBadge tier={customer.tier} compact />
                </div>
                {customer.cpf && (
                  <p className="text-[11px] text-muted-foreground">CPF {customer.cpf}</p>
                )}
              </div>
            </div>
            <div
              className="flex gap-0.5"
              onClick={(e) => e.stopPropagation()}
              onKeyDown={(e) => e.stopPropagation()}
            >
              <Link href={`/consultor/cadastros/clientes/${customer.id}/editar`}>
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-7 w-7"
                  data-testid={`button-edit-customer-${customer.id}`}
                  aria-label="Editar cliente"
                >
                  <Edit className="w-3.5 h-3.5" />
                </Button>
              </Link>
              {canDelete && (
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-7 w-7 text-destructive"
                  onClick={onDelete}
                  data-testid={`button-delete-customer-${customer.id}`}
                  aria-label="Excluir cliente"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </Button>
              )}
            </div>
          </div>
          <div className="mt-3 space-y-1">
            <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
              <Phone className="w-3 h-3" />
              {customer.phone}
            </div>
            {customer.email && (
              <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                <Mail className="w-3 h-3" />
                <span className="truncate">{customer.email}</span>
              </div>
            )}
          </div>
          <div className="mt-3 pt-3 border-t border-card-border flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Badge variant="secondary" className="text-[10px] bg-muted/60">
                {vehicleCount} veíc.
              </Badge>
              <span className="text-[10px] text-muted-foreground">
                Cliente desde {formatDateBR(customer.createdAt)}
              </span>
            </div>
            <span className="text-[11px] text-primary font-medium inline-flex items-center gap-0.5">
              Abrir ficha
              <ChevronRight className="w-3 h-3" />
            </span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
```

- [ ] **Step 2: tsc check**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 3: Smoke navegação manual** (não bloqueia commit, só registra)

```bash
npm run dev
```

Manual: abre `localhost:5000/#/consultor/cadastros/clientes`. Espera ver: PageHeader com eyebrow, FilterBar com search, cards mostram TierBadge inline e "Cliente desde DD/MM/YYYY".

- [ ] **Step 4: Commit**

```bash
git add client/src/pages/customers.tsx
git commit -m "feat(consultor): customers list — PageHeader + FilterBar + EmptyState + TierBadge + cliente desde"
```

---

## Task 4: Delete dead components (workflow wizard + drawer)

**Files:**
- Delete: `client/src/components/customer-workflow-wizard.tsx`
- Delete: `client/src/components/customer-detail-drawer.tsx`

- [ ] **Step 1: Confirma zero imports**

```bash
grep -rn "customer-workflow-wizard\|customer-detail-drawer\|CustomerWorkflowWizard\|CustomerDetailDrawer" \
  client/src server tests 2>&1 | grep -v "components/customer-workflow-wizard.tsx\|components/customer-detail-drawer.tsx"
```

Expected output: vazio (sem imports). Se algum match aparecer, **PARE** e investiga antes de deletar.

- [ ] **Step 2: Deleta arquivos**

```bash
rm client/src/components/customer-workflow-wizard.tsx
rm client/src/components/customer-detail-drawer.tsx
```

- [ ] **Step 3: tsc check**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add -A client/src/components/
git commit -m "chore(consultor): drop dead customer-workflow-wizard + customer-detail-drawer (no imports since Rodada 5)"
```

---

## Task 5: Customer detail — CustomerHeader sub-component

**Files:**
- Create: `client/src/components/customer/customer-header.tsx`

- [ ] **Step 1: Cria pasta + componente**

```bash
mkdir -p client/src/components/customer
```

```tsx
// client/src/components/customer/customer-header.tsx
import { Link } from "wouter";
import type { Customer } from "@shared/schema";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Edit, Plus } from "lucide-react";
import { TierBadge } from "@/design-system";
import { formatDateBR } from "@/lib/format-date";

interface CustomerHeaderProps {
  customer: Customer;
}

function initials(name: string): string {
  const parts = name.trim().split(/\s+/);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

export function CustomerHeader({ customer }: CustomerHeaderProps) {
  return (
    <header className="space-y-3">
      <Link
        href="/consultor/cadastros/clientes"
        className="inline-flex items-center gap-1 text-xs uppercase tracking-[0.14em] text-muted-foreground hover:text-foreground"
        data-testid="link-back-customers"
      >
        <ArrowLeft className="w-3 h-3" />
        Voltar pro CRM
      </Link>

      <div className="flex flex-wrap items-start justify-between gap-4 pb-4 border-b border-border/40">
        <div className="flex items-center gap-4 min-w-0">
          <div
            className="w-14 h-14 rounded-full bg-primary/10 text-primary flex items-center justify-center font-mono text-base font-semibold shrink-0"
            aria-hidden
          >
            {initials(customer.name)}
          </div>
          <div className="min-w-0 space-y-1">
            <p className="text-[10px] font-mono uppercase tracking-[0.18em] text-muted-foreground">
              DAP · OPERAÇÃO · CLIENTE
            </p>
            <div className="flex flex-wrap items-center gap-2">
              <h1 className="text-2xl font-semibold truncate" data-testid="text-customer-detail-title">
                {customer.name}
              </h1>
              <TierBadge tier={customer.tier} />
            </div>
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
              {customer.cpf && <span>CPF {customer.cpf}</span>}
              <span>Cliente desde {formatDateBR(customer.createdAt)}</span>
              {customer.origin && <span>Origem: {customer.origin}</span>}
            </div>
          </div>
        </div>

        <div className="flex gap-2 shrink-0">
          <Link href={`/consultor/cadastros/clientes/${customer.id}/editar`}>
            <Button variant="outline" size="sm" data-testid="button-edit-customer">
              <Edit className="w-3.5 h-3.5 mr-1" />
              Editar
            </Button>
          </Link>
          <Link href="/consultor/cadastros/os/nova">
            <Button size="sm" data-testid="button-new-os-from-customer">
              <Plus className="w-3.5 h-3.5 mr-1" />
              Nova OS
            </Button>
          </Link>
        </div>
      </div>
    </header>
  );
}
```

- [ ] **Step 2: tsc check + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
git add client/src/components/customer/customer-header.tsx
git commit -m "feat(consultor): CustomerHeader (avatar + nome + tier + meta + actions)"
```

---

## Task 6: Customer detail — Fidelidade card

**Files:**
- Create: `client/src/components/customer/customer-fidelidade-card.tsx`

- [ ] **Step 1: Cria componente**

```tsx
// client/src/components/customer/customer-fidelidade-card.tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Sparkles } from "lucide-react";
import type { Customer } from "@shared/schema";
import { TierBadge, type Tier } from "@/design-system";
import { formatCentsBRL } from "@/lib/money";
import {
  tierFromCompletedOrders,
  tierProgressMessage,
  tierProgressFraction,
} from "@/lib/customer-tier";

interface FidelidadeCardProps {
  customer: Customer;
  stats: {
    completedOrders: number;
    totalOrders: number;
    totalSpentCents: number;
  } | null | undefined;
}

export function CustomerFidelidadeCard({ customer, stats }: FidelidadeCardProps) {
  // Tier salvo no DB é fonte de display. Cálculo só serve pro progresso.
  const completed = stats?.completedOrders ?? 0;
  const computedTier = tierFromCompletedOrders(completed);
  const displayTier: Tier = (customer.tier as Tier) ?? computedTier;
  const progressMessage = tierProgressMessage(displayTier, completed);
  const progress = tierProgressFraction(displayTier, completed);

  return (
    <Card className="border-card-border">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
          <Sparkles className="w-4 h-4 text-muted-foreground" />
          Fidelidade
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-0 pb-4 space-y-3">
        <div className="flex items-center justify-between">
          <TierBadge tier={displayTier} className="text-xs px-3 py-1" />
          <p className="text-xs text-muted-foreground">{progressMessage}</p>
        </div>

        <div className="grid grid-cols-2 gap-3 pt-1">
          <Metric label="OS realizadas" value={String(stats?.totalOrders ?? 0)} />
          <Metric label="Total gasto" value={formatCentsBRL(stats?.totalSpentCents ?? 0)} mono />
        </div>

        <div className="space-y-1 pt-1">
          <div className="h-1.5 rounded-full bg-muted overflow-hidden">
            <div
              className="h-full bg-primary transition-[width] duration-500"
              style={{ width: `${Math.round(progress * 100)}%` }}
              aria-hidden
            />
          </div>
          <p className="text-[10px] uppercase tracking-[0.14em] text-muted-foreground/70 font-mono">
            Progresso de tier
          </p>
        </div>
      </CardContent>
    </Card>
  );
}

function Metric({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div>
      <p className="text-[10px] uppercase tracking-[0.14em] text-muted-foreground">{label}</p>
      <p className={`text-sm font-medium ${mono ? "font-mono" : ""}`}>{value}</p>
    </div>
  );
}
```

- [ ] **Step 2: tsc check + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
git add client/src/components/customer/customer-fidelidade-card.tsx
git commit -m "feat(consultor): CustomerFidelidadeCard (tier + OS count + total + progress bar)"
```

---

## Task 7: Customer detail — Contato card

**Files:**
- Create: `client/src/components/customer/customer-contato-card.tsx`

- [ ] **Step 1: Cria componente**

```tsx
// client/src/components/customer/customer-contato-card.tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Phone, Mail, MapPin, MessageCircle, FileText } from "lucide-react";
import type { Customer } from "@shared/schema";

interface ContatoCardProps {
  customer: Customer;
}

function digitsOnly(s: string | null | undefined): string {
  return (s ?? "").replace(/\D/g, "");
}

export function CustomerContatoCard({ customer }: ContatoCardProps) {
  const wa = digitsOnly(customer.phone);
  const waLink = wa.length >= 10 ? `https://wa.me/55${wa.replace(/^55/, "")}` : null;

  return (
    <Card className="border-card-border">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
          <Phone className="w-4 h-4 text-muted-foreground" />
          Contato
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-0 pb-4 space-y-2">
        <ContactRow
          icon={<Phone className="w-3.5 h-3.5" />}
          label="Telefone"
          value={customer.phone}
          href={`tel:${digitsOnly(customer.phone)}`}
        />
        {waLink && (
          <ContactRow
            icon={<MessageCircle className="w-3.5 h-3.5" />}
            label="WhatsApp"
            value={customer.phone}
            href={waLink}
            external
          />
        )}
        {customer.email && (
          <ContactRow
            icon={<Mail className="w-3.5 h-3.5" />}
            label="E-mail"
            value={customer.email}
            href={`mailto:${customer.email}`}
          />
        )}
        {customer.city && (
          <ContactRow
            icon={<MapPin className="w-3.5 h-3.5" />}
            label="Cidade"
            value={customer.city}
          />
        )}
        {customer.address && (
          <ContactRow
            icon={<MapPin className="w-3.5 h-3.5" />}
            label="Endereço"
            value={customer.address}
          />
        )}
        {customer.notes && (
          <div className="pt-2 mt-2 border-t border-card-border space-y-1">
            <div className="flex items-center gap-1.5 text-[10px] uppercase tracking-[0.14em] text-muted-foreground">
              <FileText className="w-3 h-3" />
              Observações
            </div>
            <p className="text-xs whitespace-pre-wrap">{customer.notes}</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

interface ContactRowProps {
  icon: React.ReactNode;
  label: string;
  value: string;
  href?: string;
  external?: boolean;
}

function ContactRow({ icon, label, value, href, external }: ContactRowProps) {
  const inner = (
    <div className="flex items-center justify-between text-xs">
      <span className="inline-flex items-center gap-1.5 text-muted-foreground">
        {icon}
        {label}
      </span>
      <span className="text-foreground truncate ml-2">{value}</span>
    </div>
  );
  if (!href) return inner;
  return (
    <a
      href={href}
      target={external ? "_blank" : undefined}
      rel={external ? "noreferrer" : undefined}
      className="block hover:bg-muted/40 rounded px-1 -mx-1 transition-colors"
    >
      {inner}
    </a>
  );
}
```

- [ ] **Step 2: tsc check + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
git add client/src/components/customer/customer-contato-card.tsx
git commit -m "feat(consultor): CustomerContatoCard (tel/whats/mail/city/address/notes)"
```

---

## Task 8: Customer detail — Veículos + CRM-em-construção cards

**Files:**
- Create: `client/src/components/customer/customer-veiculos-card.tsx`
- Create: `client/src/components/customer/customer-crm-card.tsx`

- [ ] **Step 1: Cria veiculos card**

```tsx
// client/src/components/customer/customer-veiculos-card.tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Car } from "lucide-react";
import type { Vehicle } from "@shared/schema";
import { EmptyState } from "@/design-system";

interface VeiculosCardProps {
  vehicles: Vehicle[];
}

export function CustomerVeiculosCard({ vehicles }: VeiculosCardProps) {
  return (
    <Card className="border-card-border">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
          <Car className="w-4 h-4 text-muted-foreground" />
          Veículos vinculados
          <span className="text-muted-foreground/60 font-mono text-xs">({vehicles.length})</span>
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-0 pb-4">
        {vehicles.length === 0 ? (
          <EmptyState
            icon={<Car />}
            title="Nenhum veículo vinculado"
            description="Cadastre um veículo na criação da OS ou em /consultor/cadastros/veiculos."
          />
        ) : (
          <div className="space-y-2">
            {vehicles.map((v, idx) => (
              <div
                key={v.id}
                className="flex items-center justify-between gap-3 rounded-md border border-card-border px-3 py-2"
                data-testid={`vehicle-row-${v.id}`}
              >
                <div className="min-w-0 space-y-0.5">
                  <div className="flex items-center gap-2 min-w-0">
                    <p className="text-sm font-medium truncate">
                      {v.brand} {v.model}
                    </p>
                    {idx === 0 && (
                      <Badge variant="secondary" className="text-[10px]">
                        Principal
                      </Badge>
                    )}
                  </div>
                  <div className="flex items-center gap-3 text-[11px] text-muted-foreground">
                    <span className="font-mono uppercase tracking-wider">{v.plate}</span>
                    {v.year != null && <span>{v.year}</span>}
                    {v.color && <span>{v.color}</span>}
                    {v.km != null && <span>{v.km.toLocaleString("pt-BR")} km</span>}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
```

- [ ] **Step 2: Cria CRM card (em construção inline)**

```tsx
// client/src/components/customer/customer-crm-card.tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Briefcase } from "lucide-react";

/**
 * Card de relacionamento CRM.
 *
 * Rodada 6c+: vai consumir colunas novas em customers (responsibleUserId,
 * lastInteractionAt, nextContactAt). Por enquanto reserva o espaço com um
 * placeholder discreto pra preservar a 2-coluna do layout.
 */
export function CustomerCRMCard() {
  return (
    <Card className="border-card-border border-dashed">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
          <Briefcase className="w-4 h-4 text-muted-foreground" />
          Relacionamento
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-0 pb-4 space-y-2">
        <p className="text-[10px] font-mono uppercase tracking-[0.18em] text-muted-foreground">
          Em construção · Rodada 6c
        </p>
        <p className="text-xs text-muted-foreground leading-relaxed">
          Aqui vai morar: responsável pela conta, última interação registrada,
          próximo contato programado. Schema chega na Rodada 6c.
        </p>
      </CardContent>
    </Card>
  );
}
```

- [ ] **Step 3: tsc check + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
git add client/src/components/customer/customer-veiculos-card.tsx \
       client/src/components/customer/customer-crm-card.tsx
git commit -m "feat(consultor): CustomerVeiculosCard + CustomerCRMCard (CRM card é placeholder pra 6c)"
```

---

## Task 9: Customer detail — Histórico OS card (com tabs + resumo)

**Files:**
- Create: `client/src/components/customer/customer-historico-os-card.tsx`

- [ ] **Step 1: Cria componente**

```tsx
// client/src/components/customer/customer-historico-os-card.tsx
import { useState, useMemo } from "react";
import { Link } from "wouter";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ClipboardList } from "lucide-react";
import type { ServiceOrder } from "@shared/schema";
import { STATUS_META, osNumber } from "@/components/os/os-constants";
import { formatCentsBRL } from "@/lib/money";
import { EmptyState } from "@/design-system";

type Filter = "all" | "open" | "completed" | "cancelled";

const OPEN_STATUSES = new Set([
  "diagnostico",
  "aguardando_aprovacao",
  "aprovado",
  "em_execucao",
  "aguardando_peca",
  "pronto",
]);

interface HistoricoOsCardProps {
  orders: ServiceOrder[];
  stats: {
    totalOrders: number;
    totalSpentCents: number;
    avgTicketCents: number;
  } | null | undefined;
}

export function CustomerHistoricoOsCard({ orders, stats }: HistoricoOsCardProps) {
  const [filter, setFilter] = useState<Filter>("all");

  const filtered = useMemo(() => {
    const sorted = [...orders].sort((a, b) => b.id - a.id);
    switch (filter) {
      case "open":
        return sorted.filter((o) => OPEN_STATUSES.has(o.status));
      case "completed":
        return sorted.filter((o) => o.status === "entregue");
      case "cancelled":
        return sorted.filter((o) => o.status === "cancelado");
      default:
        return sorted;
    }
  }, [orders, filter]);

  return (
    <Card className="border-card-border">
      <CardHeader className="pb-2 space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
            <ClipboardList className="w-4 h-4 text-muted-foreground" />
            Histórico de OS
          </CardTitle>
          {stats && (
            <p className="text-xs font-mono text-muted-foreground">
              {stats.totalOrders} OS · {formatCentsBRL(stats.totalSpentCents)} · ticket médio{" "}
              {formatCentsBRL(stats.avgTicketCents)}
            </p>
          )}
        </div>
        <Tabs value={filter} onValueChange={(v) => setFilter(v as Filter)}>
          <TabsList className="h-8">
            <TabsTrigger value="all" className="text-xs h-7">Todas</TabsTrigger>
            <TabsTrigger value="open" className="text-xs h-7">Abertas</TabsTrigger>
            <TabsTrigger value="completed" className="text-xs h-7">Concluídas</TabsTrigger>
            <TabsTrigger value="cancelled" className="text-xs h-7">Canceladas</TabsTrigger>
          </TabsList>
        </Tabs>
      </CardHeader>
      <CardContent className="pt-0 pb-4">
        {filtered.length === 0 ? (
          <EmptyState
            icon={<ClipboardList />}
            title={filter === "all" ? "Nenhuma OS registrada" : "Nenhuma OS neste filtro"}
            description={
              filter === "all"
                ? "Quando este cliente tiver uma OS, ela aparece aqui."
                : "Mude o filtro acima pra ver outras OS."
            }
          />
        ) : (
          <div className="space-y-2">
            {filtered.slice(0, 10).map((o) => {
              const status =
                STATUS_META[o.status as keyof typeof STATUS_META] ?? STATUS_META.diagnostico;
              return (
                <Link key={o.id} href={`/consultor/cadastros/os/${o.id}`}>
                  <div
                    className="rounded-md border border-card-border cursor-pointer hover:border-primary/40 hover:bg-muted/30 transition-colors py-3 px-3 flex items-center justify-between gap-3"
                    data-testid={`os-row-${o.id}`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <span className="text-xs font-mono font-bold text-muted-foreground whitespace-nowrap">
                        {osNumber(o.id)}
                      </span>
                      <p className="text-sm truncate">{o.description}</p>
                    </div>
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <Badge variant="outline" className={`text-[11px] border ${status.chip}`}>
                        {status.label}
                      </Badge>
                      {o.estimatedCost != null && (
                        <span className="text-xs font-mono text-muted-foreground">
                          {formatCentsBRL(o.estimatedCost)}
                        </span>
                      )}
                    </div>
                  </div>
                </Link>
              );
            })}
            {filtered.length > 10 && (
              <p className="text-xs text-muted-foreground text-center pt-2">
                Mostrando 10 de {filtered.length} OS.
              </p>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
```

- [ ] **Step 2: tsc check + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
git add client/src/components/customer/customer-historico-os-card.tsx
git commit -m "feat(consultor): CustomerHistoricoOsCard (resumo + tabs all/open/completed/cancelled)"
```

---

## Task 10: Customer detail — Timeline (post-sale-followups)

**Files:**
- Create: `client/src/components/customer/customer-timeline-card.tsx`

- [ ] **Step 1: Cria componente**

```tsx
// client/src/components/customer/customer-timeline-card.tsx
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { CalendarClock } from "lucide-react";
import type { PostSaleFollowup } from "@shared/schema";
import { EmptyState } from "@/design-system";
import { formatDateBR } from "@/lib/format-date";

const STATUS_META: Record<string, { label: string; className: string }> = {
  pendente: {
    label: "Pendente",
    className: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
  },
  concluido: {
    label: "Concluído",
    className: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
  },
  cancelado: {
    label: "Cancelado",
    className: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  },
};

interface TimelineCardProps {
  customerId: number;
}

export function CustomerTimelineCard({ customerId }: TimelineCardProps) {
  const { data = [], isLoading } = useQuery<PostSaleFollowup[]>({
    queryKey: ["/api/post-sale-followups", { customerId }],
    queryFn: undefined, // usa o default queryFn que monta URL com query params
  });

  // NOTA: queryClient default precisa saber serializar `{ customerId }` pra
  // querystring. Se não suporta object como segundo segmento, troca por:
  // queryKey: [`/api/post-sale-followups?customerId=${customerId}`]

  return (
    <Card className="border-card-border">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
          <CalendarClock className="w-4 h-4 text-muted-foreground" />
          Timeline · Interações
          <span className="text-muted-foreground/60 font-mono text-xs">({data.length})</span>
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-0 pb-4">
        {isLoading ? (
          <p className="text-xs text-muted-foreground text-center py-4">Carregando...</p>
        ) : data.length === 0 ? (
          <EmptyState
            icon={<CalendarClock />}
            title="Nenhuma interação registrada"
            description="Programe uma interação na próxima OS deste cliente."
          />
        ) : (
          <ol className="relative border-l border-border/40 pl-4 space-y-3 ml-2">
            {data.map((f) => {
              const meta = STATUS_META[f.status] ?? STATUS_META.pendente;
              return (
                <li key={f.id} className="space-y-0.5" data-testid={`followup-row-${f.id}`}>
                  <div className="absolute -left-[5px] mt-1.5 w-2.5 h-2.5 rounded-full bg-primary/60" aria-hidden />
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="text-xs font-mono text-muted-foreground">
                      {formatDateBR(f.scheduledDate)}
                    </p>
                    <Badge variant="outline" className={`text-[10px] ${meta.className}`}>
                      {meta.label}
                    </Badge>
                  </div>
                  <p className="text-sm">{f.description}</p>
                  {f.notes && (
                    <p className="text-[11px] text-muted-foreground italic">{f.notes}</p>
                  )}
                </li>
              );
            })}
          </ol>
        )}
      </CardContent>
    </Card>
  );
}
```

> **CRÍTICO antes do commit:** Verifica como o `queryClient` default monta URL com queryKey de 2 segmentos `["/api/post-sale-followups", { customerId }]`. Se o pattern do projeto NÃO suporta object como segmento (likely — cheque `client/src/lib/queryClient.ts`), substituir o `queryKey` por:
> ```ts
> queryKey: [`/api/post-sale-followups?customerId=${customerId}`],
> ```
> Aplicar o mesmo fix nos outros consumidores (Task 13).

- [ ] **Step 2: Verifica queryClient default**

```bash
grep -nE "queryFn|getQueryFn|join.*'/'|URLSearchParams" client/src/lib/queryClient.ts
```

Se vir `urlFromQueryKey` que ignora objects, troca pra string-only conforme nota acima ANTES de commitar.

- [ ] **Step 3: tsc check + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
git add client/src/components/customer/customer-timeline-card.tsx
git commit -m "feat(consultor): CustomerTimelineCard (post-sale-followups timeline)"
```

---

## Task 11: Refactor `customer-detail.tsx` — montar a ficha CRM completa

**Files:**
- Modify: `client/src/pages/customer-detail.tsx`

- [ ] **Step 1: Substitui o conteúdo inteiro**

```tsx
// client/src/pages/customer-detail.tsx
import { useQuery } from "@tanstack/react-query";
import { Link, useRoute } from "wouter";
import type { Customer, Vehicle, ServiceOrder } from "@shared/schema";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ArrowLeft } from "lucide-react";

import { CustomerHeader } from "@/components/customer/customer-header";
import { CustomerFidelidadeCard } from "@/components/customer/customer-fidelidade-card";
import { CustomerContatoCard } from "@/components/customer/customer-contato-card";
import { CustomerVeiculosCard } from "@/components/customer/customer-veiculos-card";
import { CustomerCRMCard } from "@/components/customer/customer-crm-card";
import { CustomerHistoricoOsCard } from "@/components/customer/customer-historico-os-card";
import { CustomerTimelineCard } from "@/components/customer/customer-timeline-card";

interface CustomerContext {
  customer: Customer;
  vehicles: Vehicle[];
  orders: ServiceOrder[];
}

interface CustomerStats {
  totalOrders: number;
  ongoingOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  totalSpentCents: number;
  avgTicketCents: number;
  firstOrderAt: string | null;
  lastOrderAt: string | null;
}

export default function CustomerDetailPage() {
  const [, params] = useRoute<{ id: string }>("/consultor/cadastros/clientes/:id");
  const id = params ? Number(params.id) : null;
  const enabled = id != null && !Number.isNaN(id);

  const { data, isLoading, isError } = useQuery<CustomerContext>({
    queryKey: ["/api/customers", id, "context"],
    enabled,
  });

  const { data: stats } = useQuery<CustomerStats>({
    queryKey: ["/api/customers", id, "stats"],
    enabled,
  });

  if (id == null || Number.isNaN(id)) {
    return (
      <div className="p-6">
        <p className="text-sm text-muted-foreground">ID de cliente inválido.</p>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="p-6 space-y-4 max-w-6xl mx-auto">
        <Skeleton className="h-6 w-40" />
        <Skeleton className="h-32 w-full" />
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <Skeleton className="h-48 w-full" />
          <Skeleton className="h-48 w-full" />
        </div>
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <div className="p-6 max-w-6xl mx-auto space-y-3">
        <Link
          href="/consultor/cadastros/clientes"
          className="inline-flex items-center gap-1 text-xs uppercase tracking-[0.14em] text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="w-3 h-3" />
          Voltar pro CRM
        </Link>
        <Card>
          <CardContent className="py-12 text-center text-muted-foreground">
            Cliente não encontrado.
          </CardContent>
        </Card>
      </div>
    );
  }

  const { customer, vehicles, orders } = data;

  return (
    <div className="mx-auto w-full max-w-6xl p-6 space-y-5">
      <CustomerHeader customer={customer} />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="space-y-5">
          <CustomerFidelidadeCard customer={customer} stats={stats} />
          <CustomerContatoCard customer={customer} />
        </div>
        <div className="space-y-5">
          <CustomerVeiculosCard vehicles={vehicles} />
          <CustomerCRMCard />
        </div>
      </div>

      <CustomerHistoricoOsCard orders={orders} stats={stats} />
      <CustomerTimelineCard customerId={customer.id} />
    </div>
  );
}
```

- [ ] **Step 2: tsc check**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

- [ ] **Step 3: Smoke manual**

```bash
npm run dev
```

Manual: abre `localhost:5000/#/consultor/cadastros/clientes/<id-real>`. Espera ver:
- Header com avatar (iniciais), nome, TierBadge, "Cliente desde", botões Editar/Nova OS
- Grid 2 colunas: Fidelidade + Contato à esquerda, Veículos + CRM à direita
- Card Histórico OS com tabs "Todas/Abertas/Concluídas/Canceladas" e linha de resumo
- Card Timeline com EmptyState se sem followups

DevTools Network: `GET /api/customers/<id>/stats` → 200 com shape correto.

- [ ] **Step 4: Commit**

```bash
git add client/src/pages/customer-detail.tsx
git commit -m "feat(consultor): customer-detail — ficha CRM completa em 7 sub-cards"
```

---

## Task 12: Refactor `orders.tsx` — primitives + EmptyState

**Files:**
- Modify: `client/src/pages/orders.tsx`

- [ ] **Step 1: Substitui o conteúdo inteiro**

```tsx
// client/src/pages/orders.tsx
import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link } from "wouter";
import type { ServiceOrder, Customer, Vehicle, ServiceOrderStatus } from "@shared/schema";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Plus, ChevronRight, ClipboardList } from "lucide-react";
import { STATUS_META, MAIN_STATUS_FLOW, osNumber } from "@/components/os/os-constants";
import { formatCentsBRL } from "@/lib/money";
import { PageHeader, FilterBar, EmptyState } from "@/design-system";

type StatusGroup = "open" | "closed";

const CLOSED_STATUSES: ServiceOrderStatus[] = ["entregue", "cancelado"];
const OPEN_STATUSES: ServiceOrderStatus[] = [
  "diagnostico",
  "aguardando_aprovacao",
  "aprovado",
  "em_execucao",
  "aguardando_peca",
  "pronto",
];

const HEADERS: Record<"open" | "closed" | "all", { eyebrow: string; title: string; subtitle: string }> = {
  open: {
    eyebrow: "DAP · OPERAÇÃO · OS",
    title: "Lista de OS",
    subtitle: "Ordens de serviço em aberto. Do diagnóstico até a entrega.",
  },
  closed: {
    eyebrow: "DAP · OPERAÇÃO · HISTÓRICO",
    title: "Histórico de OS",
    subtitle: "OS finalizadas e canceladas — registro do que já passou.",
  },
  all: {
    eyebrow: "DAP · OPERAÇÃO · OS",
    title: "Ordens de Serviço",
    subtitle: "Do diagnóstico à entrega. Clique em uma OS para abrir o detalhe.",
  },
};

export default function OrdersPage({ statusGroup }: { statusGroup?: StatusGroup }) {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  const { data: orders = [], isLoading } = useQuery<ServiceOrder[]>({ queryKey: ["/api/service-orders"] });
  const { data: customers = [] } = useQuery<Customer[]>({ queryKey: ["/api/customers"] });
  const { data: vehicles = [] } = useQuery<Vehicle[]>({ queryKey: ["/api/vehicles"] });

  const groupStatuses =
    statusGroup === "open" ? OPEN_STATUSES :
    statusGroup === "closed" ? CLOSED_STATUSES :
    null;
  const header = HEADERS[statusGroup ?? "all"];
  const detailRoot = statusGroup === undefined ? "/orders" : "/consultor/cadastros/os";

  const getCustomerName = (id: number) => customers.find((c) => c.id === id)?.name || "—";
  const getVehicleLabel = (id: number) => {
    const v = vehicles.find((v) => v.id === id);
    return v ? `${v.brand} ${v.model} (${v.plate})` : "—";
  };

  const availableStatuses = groupStatuses ?? MAIN_STATUS_FLOW;

  const filtered = orders
    .filter((o) => (groupStatuses ? groupStatuses.includes(o.status as ServiceOrderStatus) : true))
    .filter((o) => statusFilter === "all" || o.status === statusFilter)
    .filter((o) => {
      const customer = customers.find((c) => c.id === o.customerId);
      const vehicle = vehicles.find((v) => v.id === o.vehicleId);
      const q = search.toLowerCase();
      return (
        o.description.toLowerCase().includes(q) ||
        String(o.id).includes(search) ||
        (customer?.name.toLowerCase().includes(q) ?? false) ||
        (vehicle?.plate.toLowerCase().includes(q) ?? false)
      );
    })
    .sort((a, b) => b.id - a.id);

  const hasActiveFilters = search.length > 0 || statusFilter !== "all";

  return (
    <div className="p-6 space-y-4">
      <PageHeader
        eyebrow={header.eyebrow}
        title={header.title}
        subtitle={header.subtitle}
        actions={
          <Link href="/consultor/cadastros/os/nova">
            <Button size="sm" data-testid="button-add-order">
              <Plus className="w-4 h-4 mr-1" />
              Nova OS
            </Button>
          </Link>
        }
      />

      <FilterBar
        search={{
          value: search,
          onChange: setSearch,
          placeholder: "Buscar por cliente, placa, descrição ou # da OS...",
        }}
        hasActiveFilters={hasActiveFilters}
        onClear={() => {
          setSearch("");
          setStatusFilter("all");
        }}
      >
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-52" data-testid="select-status-filter">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos os Status</SelectItem>
            {availableStatuses.map((s) => (
              <SelectItem key={s} value={s}>{STATUS_META[s].label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </FilterBar>

      {isLoading ? (
        <div className="space-y-2">
          {[...Array(5)].map((_, i) => <Card key={i}><CardContent className="pt-6 h-16" /></Card>)}
        </div>
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={<ClipboardList />}
          title={hasActiveFilters ? "Nenhuma OS bate com os filtros" : "Nenhuma OS encontrada"}
          description={
            hasActiveFilters
              ? "Ajuste os filtros ou limpe pra ver tudo."
              : "Crie a primeira OS pra começar."
          }
          action={
            !hasActiveFilters ? (
              <Link href="/consultor/cadastros/os/nova">
                <Button>
                  <Plus className="w-4 h-4 mr-1" />
                  Nova OS
                </Button>
              </Link>
            ) : undefined
          }
        />
      ) : (
        <div className="space-y-2">
          {filtered.map((o) => {
            const status = STATUS_META[o.status as keyof typeof STATUS_META] ?? STATUS_META.diagnostico;
            return (
              <Link key={o.id} href={`${detailRoot}/${o.id}`}>
                <Card
                  className="border-card-border cursor-pointer hover:border-primary/40 hover:bg-muted/30 transition-colors"
                  data-testid={`card-order-${o.id}`}
                >
                  <CardContent className="py-3 px-4 flex items-center justify-between">
                    <div className="flex items-center gap-4 min-w-0">
                      <span className="text-xs font-mono font-bold text-muted-foreground whitespace-nowrap">
                        {osNumber(o.id)}
                      </span>
                      <div className="min-w-0">
                        <p className="text-sm font-medium truncate max-w-sm">{o.description}</p>
                        <p className="text-xs text-muted-foreground truncate">
                          {getCustomerName(o.customerId)} — {getVehicleLabel(o.vehicleId)}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <Badge variant="outline" className={`text-[11px] border ${status.chip}`}>
                        {status.label}
                      </Badge>
                      {o.estimatedCost != null && (
                        <span className="text-xs text-muted-foreground font-mono">{formatCentsBRL(o.estimatedCost)}</span>
                      )}
                      <ChevronRight className="w-4 h-4 text-muted-foreground" />
                    </div>
                  </CardContent>
                </Card>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: tsc check + smoke + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Smoke: `localhost:5000/#/consultor/cadastros/os` (open), `/historico/os` (closed), `/orders` (legacy/all). Os 3 modos têm que renderizar PageHeader correto e FilterBar funcional.

```bash
git add client/src/pages/orders.tsx
git commit -m "feat(consultor): orders list — PageHeader + FilterBar + EmptyState (3 modos preservados)"
```

---

## Task 13: OsAdvancePaymentCard — modal + PATCH adiantamento

**Files:**
- Create: `client/src/components/os/os-advance-payment-card.tsx`

- [ ] **Step 1: Cria componente com modal embutido**

```tsx
// client/src/components/os/os-advance-payment-card.tsx
import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import type { ServiceOrder, ServiceOrderComment } from "@shared/schema";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogTrigger,
} from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { DollarSign, Plus } from "lucide-react";
import { formatCentsBRL } from "@/lib/money";
import { parseBRLInput, centsToInputString } from "@/lib/money";
import { formatDateBR } from "@/lib/format-date";

const PAYMENT_METHODS = [
  { value: "dinheiro", label: "Dinheiro" },
  { value: "pix", label: "PIX" },
  { value: "cartao_credito", label: "Cartão Crédito" },
  { value: "cartao_debito", label: "Cartão Débito" },
  { value: "transferencia", label: "Transferência" },
  { value: "boleto", label: "Boleto" },
] as const;

interface AdvanceCardProps {
  order: ServiceOrder;
  comments: ServiceOrderComment[];
}

export function OsAdvancePaymentCard({ order, comments }: AdvanceCardProps) {
  const { toast } = useToast();
  const [open, setOpen] = useState(false);
  const [valueRaw, setValueRaw] = useState(centsToInputString(order.advancePayment));
  const [paidAt, setPaidAt] = useState(() => new Date().toISOString().slice(0, 10));
  const [method, setMethod] = useState<string>("pix");
  const [note, setNote] = useState("");

  const advanceComments = useMemo(
    () => comments.filter((c) => c.category === "adiantamento").sort((a, b) => b.id - a.id),
    [comments],
  );

  const mutation = useMutation({
    mutationFn: async () => {
      const cents = parseBRLInput(valueRaw);
      if (cents == null) throw new Error("Valor inválido");
      // Atualiza o campo struturado no order.
      await apiRequest("PATCH", `/api/service-orders/${order.id}`, {
        advancePayment: cents / 100, // server faz moneyToCents — passa como float reais
      });
      // Registra histórico no comments com category="adiantamento".
      const methodLabel = PAYMENT_METHODS.find((p) => p.value === method)?.label ?? method;
      const text = `Adiantamento ${formatCentsBRL(cents)} via ${methodLabel} em ${formatDateBR(paidAt)}${note ? ` · ${note}` : ""}`;
      await apiRequest("POST", `/api/service-orders/${order.id}/comments`, {
        text,
        category: "adiantamento",
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/service-orders", order.id, "full"] });
      queryClient.invalidateQueries({ queryKey: ["/api/service-orders"] });
      toast({ title: "Adiantamento registrado" });
      setOpen(false);
      setNote("");
    },
    onError: (err) => {
      toast({
        title: "Erro ao registrar",
        description: err instanceof Error ? err.message : undefined,
        variant: "destructive",
      });
    },
  });

  return (
    <Card className="border-card-border">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
          <DollarSign className="w-4 h-4 text-muted-foreground" />
          Adiantamento
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-0 pb-4 space-y-3">
        {order.advancePayment != null && order.advancePayment > 0 ? (
          <p className="text-lg font-semibold font-mono text-sky-600 dark:text-sky-400">
            {formatCentsBRL(order.advancePayment)}
          </p>
        ) : (
          <p className="text-xs text-muted-foreground italic">Sem adiantamento registrado</p>
        )}

        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button size="sm" variant="outline" className="w-full" data-testid="button-add-advance">
              <Plus className="w-3.5 h-3.5 mr-1" />
              Registrar adiantamento
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Registrar adiantamento</DialogTitle>
            </DialogHeader>
            <div className="space-y-3 py-2">
              <div>
                <Label htmlFor="adv-value">Valor</Label>
                <Input
                  id="adv-value"
                  value={valueRaw}
                  onChange={(e) => setValueRaw(e.target.value)}
                  placeholder="R$ 0,00"
                  data-testid="input-advance-value"
                />
              </div>
              <div>
                <Label htmlFor="adv-date">Data</Label>
                <Input
                  id="adv-date"
                  type="date"
                  value={paidAt}
                  onChange={(e) => setPaidAt(e.target.value)}
                />
              </div>
              <div>
                <Label htmlFor="adv-method">Forma de pagamento</Label>
                <Select value={method} onValueChange={setMethod}>
                  <SelectTrigger id="adv-method"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {PAYMENT_METHODS.map((p) => (
                      <SelectItem key={p.value} value={p.value}>{p.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="adv-note">Observação (opcional)</Label>
                <Textarea
                  id="adv-note"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  rows={2}
                />
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setOpen(false)}>Cancelar</Button>
              <Button
                onClick={() => mutation.mutate()}
                disabled={mutation.isPending || !valueRaw}
                data-testid="button-save-advance"
              >
                {mutation.isPending ? "Salvando..." : "Salvar"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {advanceComments.length > 0 && (
          <div className="pt-2 mt-2 border-t border-card-border space-y-1.5">
            <p className="text-[10px] font-mono uppercase tracking-[0.14em] text-muted-foreground">
              Histórico
            </p>
            {advanceComments.slice(0, 5).map((c) => (
              <div key={c.id} className="text-[11px] text-muted-foreground">
                <span className="font-mono">{formatDateBR(c.createdAt)}</span> — {c.text}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
```

> **NOTA crítica sobre `moneyToCents`:** revisar `server/routes/orders.ts:74-76` — `moneyToCents(body.advancePayment)`. Se aceita float reais e converte → passar `cents/100`. Se aceita já cents → passar `cents` direto. Confirma antes:
> ```bash
> grep -nE "moneyToCents" server/lib/*.ts server/routes/orders.ts | head -5
> grep -nB2 -A8 "function moneyToCents\|moneyToCents =" server
> ```
> Ajustar `cents / 100` se necessário pra match com o contrato do server.

- [ ] **Step 2: Verifica `moneyToCents` contrato**

```bash
grep -rn "moneyToCents" server 2>&1 | head -10
```

Se a função espera reais (number/string como "100,50"), o `cents/100` no PATCH está certo. Se espera já cents (integer), trocar pra `cents` direto. **Aplicar fix antes de commitar se necessário.**

- [ ] **Step 3: tsc check + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
git add client/src/components/os/os-advance-payment-card.tsx
git commit -m "feat(consultor): OsAdvancePaymentCard (PATCH order + log comment category=adiantamento)"
```

---

## Task 14: OsPostSaleCard — list + create + toggle status

**Files:**
- Create: `client/src/components/os/os-post-sale-card.tsx`

- [ ] **Step 1: Cria componente**

```tsx
// client/src/components/os/os-post-sale-card.tsx
import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { apiRequest, queryClient } from "@/lib/queryClient";
import type { PostSaleFollowup } from "@shared/schema";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogTrigger,
} from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { CalendarClock, Plus, CheckCircle2 } from "lucide-react";
import { formatDateBR } from "@/lib/format-date";

const STATUS_META: Record<string, { label: string; className: string }> = {
  pendente: {
    label: "Pendente",
    className: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
  },
  concluido: {
    label: "Concluído",
    className: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
  },
  cancelado: {
    label: "Cancelado",
    className: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  },
};

interface PostSaleCardProps {
  serviceOrderId: number;
  customerId: number;
}

export function OsPostSaleCard({ serviceOrderId, customerId }: PostSaleCardProps) {
  const { toast } = useToast();
  const [open, setOpen] = useState(false);
  const [scheduledDate, setScheduledDate] = useState(() =>
    new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
  );
  const [description, setDescription] = useState("");

  const queryKeyStr = `/api/post-sale-followups?serviceOrderId=${serviceOrderId}`;

  const { data = [], isLoading } = useQuery<PostSaleFollowup[]>({
    queryKey: [queryKeyStr],
  });

  const createMutation = useMutation({
    mutationFn: async () => {
      await apiRequest("POST", "/api/post-sale-followups", {
        serviceOrderId,
        customerId,
        scheduledDate,
        description,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [queryKeyStr] });
      queryClient.invalidateQueries({ queryKey: [`/api/post-sale-followups?customerId=${customerId}`] });
      toast({ title: "Pós-venda programada" });
      setOpen(false);
      setDescription("");
    },
    onError: () => toast({ title: "Erro ao programar", variant: "destructive" }),
  });

  const toggleMutation = useMutation({
    mutationFn: async ({ id, status }: { id: number; status: string }) => {
      await apiRequest("PATCH", `/api/post-sale-followups/${id}`, { status });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [queryKeyStr] });
      queryClient.invalidateQueries({ queryKey: [`/api/post-sale-followups?customerId=${customerId}`] });
    },
  });

  return (
    <Card className="border-card-border">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-semibold flex items-center gap-1.5">
          <CalendarClock className="w-4 h-4 text-muted-foreground" />
          Pós-venda
          <span className="text-muted-foreground/60 font-mono text-xs">({data.length})</span>
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-0 pb-4 space-y-3">
        {isLoading ? (
          <p className="text-xs text-muted-foreground">Carregando...</p>
        ) : data.length === 0 ? (
          <p className="text-xs text-muted-foreground italic">Nenhum acompanhamento programado</p>
        ) : (
          <div className="space-y-2">
            {data.map((f) => {
              const meta = STATUS_META[f.status] ?? STATUS_META.pendente;
              return (
                <div
                  key={f.id}
                  className="rounded-md border border-card-border px-3 py-2 space-y-1"
                  data-testid={`os-followup-${f.id}`}
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-[11px] font-mono text-muted-foreground">
                      {formatDateBR(f.scheduledDate)}
                    </span>
                    <Badge variant="outline" className={`text-[10px] ${meta.className}`}>
                      {meta.label}
                    </Badge>
                  </div>
                  <p className="text-xs">{f.description}</p>
                  {f.status === "pendente" && (
                    <Button
                      size="sm"
                      variant="ghost"
                      className="h-6 text-[11px] -ml-2 mt-1"
                      onClick={() => toggleMutation.mutate({ id: f.id, status: "concluido" })}
                      disabled={toggleMutation.isPending}
                    >
                      <CheckCircle2 className="w-3 h-3 mr-1" />
                      Marcar como concluído
                    </Button>
                  )}
                </div>
              );
            })}
          </div>
        )}

        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button size="sm" variant="outline" className="w-full" data-testid="button-add-followup">
              <Plus className="w-3.5 h-3.5 mr-1" />
              Programar pós-venda
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Programar acompanhamento</DialogTitle>
            </DialogHeader>
            <div className="space-y-3 py-2">
              <div>
                <Label htmlFor="ps-date">Data programada</Label>
                <Input
                  id="ps-date"
                  type="date"
                  value={scheduledDate}
                  onChange={(e) => setScheduledDate(e.target.value)}
                />
              </div>
              <div>
                <Label htmlFor="ps-desc">Descrição</Label>
                <Textarea
                  id="ps-desc"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Ex: confirmar satisfação 7 dias após entrega"
                  rows={3}
                />
              </div>
              {/* TODO Rodada 6c: select de responsibleUserId — bloqueado hoje
                  porque /api/users é admin-only. Servidor cai pra session.userId
                  como default no insert se não vier (vide tasks 6c). */}
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setOpen(false)}>Cancelar</Button>
              <Button
                onClick={() => createMutation.mutate()}
                disabled={createMutation.isPending || !description.trim()}
                data-testid="button-save-followup"
              >
                {createMutation.isPending ? "Salvando..." : "Salvar"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </CardContent>
    </Card>
  );
}
```

- [ ] **Step 2: tsc check + commit**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
git add client/src/components/os/os-post-sale-card.tsx
git commit -m "feat(consultor): OsPostSaleCard (list + create + toggle pendente→concluido)"
```

---

## Task 15: Wire cards novos em `service-order-detail.tsx`

**Files:**
- Modify: `client/src/pages/service-order-detail.tsx`

- [ ] **Step 1: Substitui o conteúdo inteiro**

```tsx
// client/src/pages/service-order-detail.tsx
//
// TODO Rodada 6c+: versões visuais distintas pra status="cancelado" e
// "entregue" — banner read-only no topo, ações de edição desabilitadas,
// stripe lateral muted. Hoje a página renderiza idêntica em todos os status.
//
import { useQuery, useMutation } from "@tanstack/react-query";
import { useRoute } from "wouter";
import { apiRequest, queryClient } from "@/lib/queryClient";
import type {
  ServiceOrder, Customer, Vehicle, ServiceItem, ServiceOrderComment,
  ServiceOrderAttachment, Checklist, Telemetry, Mechanic, ServiceOrderStatus,
} from "@shared/schema";
import { Loader2, AlertCircle } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

import OsHeader from "@/components/os/os-header";
import OsStatusPipeline from "@/components/os/os-status-pipeline";
import OsItemsCard from "@/components/os/os-items-card";
import OsDiagnosticCard from "@/components/os/os-diagnostic-card";
import OsAttachmentsCard from "@/components/os/os-attachments-card";
import OsHistoryCard from "@/components/os/os-history-card";
import OsChecklistCard from "@/components/os/os-checklist-card";
import OsQuickActions from "@/components/os/os-quick-actions";
import {
  OsVehicleCard, OsCustomerCard, OsFinancialCard, OsMechanicCard, OsYardTimeCard,
} from "@/components/os/os-info-cards";
import { OsAdvancePaymentCard } from "@/components/os/os-advance-payment-card";
import { OsPostSaleCard } from "@/components/os/os-post-sale-card";

type FullOs = {
  order: ServiceOrder;
  customer: Customer | null;
  vehicle: Vehicle | null;
  items: ServiceItem[];
  comments: ServiceOrderComment[];
  attachments: ServiceOrderAttachment[];
  checklist: Checklist | null;
  telemetry: Telemetry[];
  mechanic: Mechanic | null;
  consultant: { id: number; name: string; role: string } | null;
};

export default function ServiceOrderDetailPage() {
  // Component é montado por dois patterns de rota:
  // - /orders/:id (legacy, root-level)
  // - /consultor/cadastros/os/:id (Rodada 5)
  const [, paramsLegacy] = useRoute<{ id: string }>("/orders/:id");
  const [, paramsConsultor] = useRoute<{ id: string }>("/consultor/cadastros/os/:id");
  const params = paramsConsultor ?? paramsLegacy;
  const orderId = params ? Number(params.id) : NaN;
  const { toast } = useToast();

  const { data, isLoading, error } = useQuery<FullOs>({
    queryKey: ["/api/service-orders", orderId, "full"],
    enabled: !isNaN(orderId),
  });

  const statusMutation = useMutation({
    mutationFn: async (status: ServiceOrderStatus) => {
      const res = await apiRequest("PATCH", `/api/service-orders/${orderId}/status`, { status });
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/service-orders", orderId, "full"] });
      queryClient.invalidateQueries({ queryKey: ["/api/service-orders"] });
      queryClient.invalidateQueries({ queryKey: ["/api/stats"] });
      toast({ title: "Status atualizado" });
    },
    onError: () => toast({ title: "Erro ao mudar status", variant: "destructive" }),
  });

  if (isNaN(orderId)) {
    return (
      <div className="p-6 flex items-center gap-2 text-muted-foreground">
        <AlertCircle className="w-4 h-4" /> ID de OS inválido
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="p-12 flex items-center justify-center">
        <Loader2 className="w-5 h-5 animate-spin text-primary" />
      </div>
    );
  }

  if (!data || error) {
    return (
      <div className="p-6 flex items-center gap-2 text-muted-foreground">
        <AlertCircle className="w-4 h-4" /> OS não encontrada
      </div>
    );
  }

  const { order, customer, vehicle, items, comments, attachments, checklist, mechanic } = data;

  return (
    <div className="p-6 space-y-5 max-w-[1600px] mx-auto">
      <OsHeader
        order={order}
        customer={customer}
        onEdit={() => toast({ title: "Edit inline (em breve)" })}
        onLinkCustomer={() => {
          if (customer) navigator.clipboard.writeText(`${window.location.origin}/#/consultor/cadastros/os/${order.id}`);
          toast({ title: "Link copiado", description: "Cole pra compartilhar com o cliente" });
        }}
      />

      <OsStatusPipeline
        current={order.status as ServiceOrderStatus}
        onChange={(s) => statusMutation.mutate(s)}
        isPending={statusMutation.isPending}
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <div className="lg:col-span-2 space-y-5">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <OsVehicleCard vehicle={vehicle} />
            <OsCustomerCard
              customer={customer}
              onSeeProfile={() => {
                if (customer) {
                  window.location.hash = `#/consultor/cadastros/clientes/${customer.id}`;
                }
              }}
            />
          </div>

          <OsDiagnosticCard order={order} />
          <OsChecklistCard serviceOrderId={order.id} checklist={checklist} />
          <OsItemsCard serviceOrderId={order.id} items={items} />
          <OsAttachmentsCard serviceOrderId={order.id} attachments={attachments} />
          <OsHistoryCard serviceOrderId={order.id} comments={comments} />
        </div>

        <div className="space-y-5">
          <OsFinancialCard items={items} order={order} />
          <OsAdvancePaymentCard order={order} comments={comments} />
          <OsMechanicCard mechanic={mechanic} />
          <OsYardTimeCard createdAt={order.createdAt} />
          {customer && (
            <OsPostSaleCard serviceOrderId={order.id} customerId={customer.id} />
          )}
          <OsQuickActions
            customerId={customer?.id ?? null}
            onSeeCustomerProfile={() => {
              if (customer) {
                window.location.hash = `#/consultor/cadastros/clientes/${customer.id}`;
              }
            }}
          />
        </div>
      </div>
    </div>
  );
}
```

> Mudança lateral aproveitada: `OsCustomerCard.onSeeProfile` agora navega pra `/consultor/cadastros/clientes/{id}` ao invés do legacy `/customers`. `OsQuickActions` mesmo fix.

- [ ] **Step 2: tsc check**

```bash
npx tsc --noEmit --pretty false; echo "exit=$?"
```

- [ ] **Step 3: Smoke manual**

```bash
npm run dev
```

Manual: `localhost:5000/#/consultor/cadastros/os/<id-real>`. Espera ver:
- Coluna lateral com 5 cards: Financial, Advance, Mechanic, YardTime, PostSale
- Click "Registrar adiantamento" → modal abre, salva, valor aparece
- Click "Programar pós-venda" → modal abre, salva, item aparece na lista
- Toggle "Marcar como concluído" → muda badge

- [ ] **Step 4: Commit**

```bash
git add client/src/pages/service-order-detail.tsx
git commit -m "feat(consultor): wire OsAdvancePaymentCard + OsPostSaleCard + TODO status-distinct view"
```

---

## Task 16: Final verification

- [ ] **Step 1: Full tsc**

```bash
cd C:/THALES/DAP4/5-dap-operacao
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 2: Backend tests run** (sanity, não tocamos backend mas garantia)

```bash
npx vitest run
```

Expected: same pass count que master + 11 da 6a (zero novo nesta rodada).

- [ ] **Step 3: Smoke completo manual**

```bash
npm run dev
```

Roteiro:
1. Login como admin
2. `/consultor/cadastros/clientes` → cards com TierBadge + "Cliente desde", FilterBar funcional, EmptyState ao buscar nada-existe
3. Click num cliente → ficha CRM completa abre (7 cards visíveis)
4. Tabs do Histórico OS funcionam (Todas / Abertas / Concluídas / Canceladas)
5. Timeline mostra EmptyState ou followups reais
6. `/consultor/cadastros/os` → PageHeader correto, FilterBar com Select de status funcional, Limpar zera tudo
7. Click numa OS → detalhe abre, coluna lateral tem AdvanceCard e PostSaleCard
8. Registra um adiantamento → reflete no Financial (saldo devedor recalcula) + aparece no histórico do AdvanceCard
9. Programa um pós-venda → aparece na lista do PostSaleCard, toggle pra concluído funciona
10. Volta pra ficha do cliente → Timeline agora mostra o followup recém criado

- [ ] **Step 4: Push branch**

```bash
git push -u origin feat/consultor-rodada-6b-crm-os
```

- [ ] **Step 5: Abrir PR**

```bash
gh pr create --base master \
  --title "Rodada 6b — CRM + OS: ficha cliente completa + cards adiantamento/pós-venda" \
  --body "$(cat <<'EOF'
## Resumo

Refatora 5 páginas + adiciona 2 cards no detalhe da OS, consumindo as foundations da Rodada 6a.

### Páginas refatoradas
- `customers.tsx` — PageHeader + FilterBar + EmptyState + TierBadge inline + cliente desde
- `customer-detail.tsx` — ficha CRM completa em 7 sub-cards (Header, Fidelidade, Contato, Veículos, CRM-em-construção, Histórico OS com tabs, Timeline)
- `orders.tsx` — PageHeader + FilterBar + EmptyState (3 modos preservados)
- `service-order-detail.tsx` — wire OsAdvancePaymentCard + OsPostSaleCard

### Componentes novos
- 7 sub-cards de customer-detail
- 2 cards de OS detail (Adiantamento + Pós-venda)
- 2 helpers (`format-date.ts`, `customer-tier.ts`)

### Cleanup
- Deletados `customer-workflow-wizard.tsx` e `customer-detail-drawer.tsx` (dead code da Rodada 5)

### Backend
- Zero migration. `service_order_comments.category` é text livre, comporta `"adiantamento"`.

### Próxima rodada (6c)
- Status-distinct view (cancelado/entregue read-only)
- Schema de relacionamento (responsibleUserId, lastInteractionAt, nextContactAt)
- Dashboard refactor, Pátio refinement, Agenda, Linha do Tempo

### Test plan
- [ ] Smoke completo seguindo roteiro do plano
- [ ] tsc verde
- [ ] Vitest sem regressão
EOF
)"
```

---

## Self-review checklist (run before declaring complete)

- [ ] tsc verde no fim
- [ ] Vitest sem regressão (mesma contagem que pré-6b)
- [ ] `customers.tsx` mostra TierBadge + "Cliente desde" em cada card
- [ ] `customer-detail.tsx` renderiza 7 cards na ordem certa
- [ ] Tabs do histórico de OS filtram in-memory corretamente
- [ ] Timeline consome `/api/post-sale-followups?customerId={id}`
- [ ] AdvanceCard atualiza `serviceOrders.advancePayment` E loga comment category="adiantamento"
- [ ] PostSaleCard cria followup, toggle pendente→concluido funciona
- [ ] OsCustomerCard.onSeeProfile e OsQuickActions navegam pra `/consultor/cadastros/clientes/:id` (não mais legacy `/customers`)
- [ ] `customer-workflow-wizard.tsx` e `customer-detail-drawer.tsx` deletados
- [ ] CustomerCRMCard renderiza placeholder discreto (não fullpage ConstructionPlaceholder)
- [ ] TODO comment no topo de `service-order-detail.tsx` documentando status-distinct view
- [ ] Cada arquivo novo está abaixo de 400 linhas
- [ ] Smoke roteiro completo executado em browser real (Chrome, não Playwright)

## Não escopo (fica pra 6c)

- Versão read-only de OS cancelada/entregue (banner + ações desabilitadas)
- Schema novo de relacionamento (`responsibleUserId`, `lastInteractionAt`, `nextContactAt` em customers)
- Card CRM funcional (consome esse schema novo)
- Select de responsibleUserId no modal de pós-venda (depende de listar users sem ser admin)
- Dashboard refactor, Pátio refinement, Agenda, Linha do Tempo (Gantt)
- Coluna `isMain` em vehicles (hoje "principal" = primeiro da lista, ad-hoc)
- Edição inline de followups (hoje só cria + toggle status)

## Riscos conhecidos

1. **Contrato `moneyToCents` no PATCH de adiantamento** — `server/routes/orders.ts:74-76` chama `moneyToCents(body.advancePayment)` no insert. Se `moneyToCents` espera **reais** (string/float "100,50"), o `cents/100` no `OsAdvancePaymentCard` está correto. Se já espera **cents** (integer), trocar pra `cents` direto. **Verificar antes de commitar Task 13** com `grep -rn "moneyToCents" server`.

2. **`/api/users` é admin-only** — `server/routes/users.ts:20`. O modal de pós-venda na 6b NÃO inclui select de responsibleUser justamente por isso. Servidor pode cair pro `req.session.userId` como default se quisermos preencher automaticamente — vale validar no insert do CRUD criado na 6a. Se não cair, `responsibleUserId` fica `null` (schema permite, ON DELETE SET NULL). Documentar como TODO inline (já feito).

3. **queryKey com objeto vs string-only** — Plano Task 10 e 14 usam `[`/api/post-sale-followups?customerId=${id}`]` direto como string ao invés de `["/api/post-sale-followups", { customerId: id }]`. Isso evita a dúvida do queryClient default. **Confirmar em `client/src/lib/queryClient.ts`** se o pattern de string-only é o esperado — se sim, padrão consistente com o resto do projeto.

4. **`customer.tier` no DB pode estar null/undefined** — coluna tem default "bronze" mas registros legados podem ter null. `TierBadge` já trata via `isTier()` fallback pra "bronze". `tierFromCompletedOrders` é usado só pro progresso, não pro display.

5. **Layout 2-col em viewport médio** — `lg:grid-cols-2` quebra em telas <1024px. Em mobile vira 1 col. Testar em viewport ~768px pra garantir que cards de Veículos e CRM placeholder não ficam awkward.

6. **OsCustomerCard onSeeProfile mudança comportamental** — antes navegava pra `#/customers` (lista CRM). Agora navega direto pra ficha do cliente. É uma melhoria UX justa, mas é uma mudança lateral introduzida nesta rodada — registrar no PR body se o reviewer notar.

7. **`Tabs` shadcn primitive** — usado em `CustomerHistoricoOsCard`. Confirmar que `client/src/components/ui/tabs.tsx` existe (provavelmente sim, é shadcn padrão). Se não existir, instalar via `npx shadcn-ui@latest add tabs` ANTES da Task 9.

8. **Dialog primitive disponibilidade** — usado nas Tasks 13 e 14. Confirmado em `client/src/components/ui/dialog.tsx` (recon).
