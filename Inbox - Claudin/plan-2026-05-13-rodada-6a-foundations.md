---
type: implementation-plan
date: 2026-05-13
project: DAP 4.0 / 5-dap-operacao (Portal Consultor)
rodada: 6a (Foundations)
depends_on: PR #3 mergeado em master (Rodada 5)
branch_to_create: feat/consultor-rodada-6a-foundations
---

# Rodada 6a — Foundations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar fundação de schema + endpoints + componentes compartilhados que a Rodada 6b (CRM+OS) e 6c (Operacional) vão consumir. Zero mudança de página nesta rodada — só foundation.

**Architecture:** 2 migrations Postgres (`oficina` schema), 2 endpoints novos (stats agregados + CRUD post-sale-followups), 5 design-system primitives (PageHeader, TierBadge, EmptyState, SectionHeader, FilterBar). Schema.ts updated, storage layer adds, vitest backend para endpoints novos.

**Tech Stack:** Drizzle ORM + Postgres (Supabase, schema `oficina`) · Express + TypeScript · React + Tailwind + shadcn/ui · Vitest (backend only)

---

## Pre-flight

- [ ] **PR #3 mergeado em master.** Confirma com `gh pr view 3 --json mergedAt`. Se não mergeado, **PARE** e mergeia primeiro.
- [ ] **Branch nova from master:**
  ```bash
  cd C:/THALES/DAP4/5-dap-operacao
  git fetch origin
  git checkout master && git pull
  git checkout -b feat/consultor-rodada-6a-foundations
  ```

---

## File Structure

**Migrations (novas):**
- `migrations-pg/0003_customer_crm_fields.sql` — created_at, address, city, origin em customers
- `migrations-pg/0004_post_sale_followups.sql` — tabela nova post_sale_followups

**Schema:**
- `shared/schema.ts` — adicionar coluna createdAt em customers + tabela postSaleFollowups + tipos

**Storage:**
- `server/storage.ts` — adicionar métodos: getCustomerStats, listPostSaleFollowups, createPostSaleFollowup, updatePostSaleFollowup, deletePostSaleFollowup

**Routes (novos endpoints, ZERO mudança em existentes):**
- `server/routes/customers.ts` — adicionar GET `/api/customers/:id/stats`
- `server/routes/post-sale-followups.ts` (NEW) — CRUD completo
- `server/routes/index.ts` — registrar novo route module

**Tests:**
- `tests/customers-stats.test.ts` (NEW) — cobertura do endpoint stats
- `tests/post-sale-followups.test.ts` (NEW) — cobertura CRUD

**Design system primitives (frontend, sem tocar página):**
- `client/src/design-system/page-header.tsx` (NEW)
- `client/src/design-system/tier-badge.tsx` (NEW)
- `client/src/design-system/empty-state.tsx` (NEW)
- `client/src/design-system/section-header.tsx` (NEW)
- `client/src/design-system/filter-bar.tsx` (NEW)
- `client/src/design-system/index.ts` (NEW ou append) — barrel export

---

## Task 1: Migration — customer CRM fields

**Files:**
- Create: `migrations-pg/0003_customer_crm_fields.sql`

- [ ] **Step 1: Escreve a migration**

```sql
-- Rodada 6a · Foundations
-- Adiciona campos CRM essenciais em customers: created_at (cliente desde),
-- address, city, origin (canal de aquisição). Preserva backfill: NULLs
-- ficam NULL exceto created_at, que recebe NOW() pra registros legados.

BEGIN;

ALTER TABLE oficina.customers
  ADD COLUMN created_at text,
  ADD COLUMN address text,
  ADD COLUMN city text,
  ADD COLUMN origin text;

-- Backfill created_at em registros existentes (clientes legados sem data).
UPDATE oficina.customers
SET created_at = NOW()::text
WHERE created_at IS NULL;

-- A partir de agora, INSERT precisa setar created_at. Fica NOT NULL.
ALTER TABLE oficina.customers
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN created_at SET DEFAULT NOW()::text;

CREATE INDEX IF NOT EXISTS idx_customers_created_at
  ON oficina.customers (created_at);

COMMIT;
```

- [ ] **Step 2: Aplica migration via Supabase MCP em pre-prod**

Use o MCP `apply_migration` (não `execute_sql`, é DDL). Em sessão Claude isolada — esta sessão pode usar o MCP direto se autorizada.

```
mcp__claude_ai_Supabase__apply_migration(
  project_id="<id-doctor-prime>",
  name="0003_customer_crm_fields",
  query="<conteúdo da migration acima>"
)
```

- [ ] **Step 3: Verifica colunas via SELECT na catalog**

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema='oficina' AND table_name='customers'
  AND column_name IN ('created_at','address','city','origin')
ORDER BY column_name;
```

Expected: 4 rows, todas presentes, `created_at` `is_nullable=NO`, demais YES.

- [ ] **Step 4: Commit**

```bash
git add migrations-pg/0003_customer_crm_fields.sql
git commit -m "feat(db): add customer CRM fields (created_at, address, city, origin)"
```

---

## Task 2: Migration — post_sale_followups table

**Files:**
- Create: `migrations-pg/0004_post_sale_followups.sql`

- [ ] **Step 1: Escreve a migration**

```sql
-- Rodada 6a · Foundations
-- Tabela de follow-ups de pós-venda. Cada OS pode ter N follow-ups
-- programados (pelo consultor) com data prevista, descrição, responsável,
-- status. Vinculada por service_order_id (cascade delete) e a uma user
-- como responsável (nullable, set null se user removido).

BEGIN;

CREATE TABLE IF NOT EXISTS oficina.post_sale_followups (
  id serial PRIMARY KEY,
  organization_id integer NOT NULL
    REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  service_order_id integer NOT NULL
    REFERENCES oficina.service_orders(id) ON DELETE CASCADE,
  customer_id integer NOT NULL
    REFERENCES oficina.customers(id) ON DELETE CASCADE,
  scheduled_date text NOT NULL,           -- ISO date string (yyyy-mm-dd ou ISO completo)
  description text NOT NULL,
  responsible_user_id integer
    REFERENCES oficina.users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'pendente', -- pendente | concluido | cancelado
  notes text,
  created_at text NOT NULL DEFAULT NOW()::text,
  updated_at text NOT NULL DEFAULT NOW()::text
);

CREATE INDEX idx_post_sale_followups_organization_id
  ON oficina.post_sale_followups (organization_id);
CREATE INDEX idx_post_sale_followups_service_order_id
  ON oficina.post_sale_followups (service_order_id);
CREATE INDEX idx_post_sale_followups_customer_id
  ON oficina.post_sale_followups (customer_id);
CREATE INDEX idx_post_sale_followups_scheduled_date
  ON oficina.post_sale_followups (scheduled_date);
CREATE INDEX idx_post_sale_followups_responsible_user_id
  ON oficina.post_sale_followups (responsible_user_id);

-- RLS — segue padrão das outras tabelas (idêntico ao do tenant_isolation 0002).
ALTER TABLE oficina.post_sale_followups ENABLE ROW LEVEL SECURITY;

CREATE POLICY post_sale_followups_tenant_isolation
  ON oficina.post_sale_followups
  USING (organization_id = (current_setting('app.organization_id', true))::int)
  WITH CHECK (organization_id = (current_setting('app.organization_id', true))::int);

COMMIT;
```

- [ ] **Step 2: Aplica via Supabase MCP**

```
mcp__claude_ai_Supabase__apply_migration(
  project_id="<id-doctor-prime>",
  name="0004_post_sale_followups",
  query="<conteúdo acima>"
)
```

- [ ] **Step 3: Verifica tabela + policy**

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema='oficina' AND table_name='post_sale_followups';

SELECT policyname FROM pg_policies
WHERE schemaname='oficina' AND tablename='post_sale_followups';
```

Expected: tabela presente, policy `post_sale_followups_tenant_isolation` presente.

- [ ] **Step 4: Commit**

```bash
git add migrations-pg/0004_post_sale_followups.sql
git commit -m "feat(db): add post_sale_followups table with RLS"
```

---

## Task 3: Update shared/schema.ts

**Files:**
- Modify: `shared/schema.ts:124-145` (customers table)
- Modify: `shared/schema.ts` (adicionar postSaleFollowups table no fim, antes de helpers)

- [ ] **Step 1: Adicionar `createdAt` na tabela customers**

Localizar o bloco `customers` e adicionar:

```ts
export const customers = oficina.table(
  "customers",
  {
    id: serial("id").primaryKey(),
    organizationId: integer("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    email: text("email"),
    phone: text("phone").notNull(),
    cpf: text("cpf"),
    notes: text("notes"),
    tier: text("tier").default("bronze"),
    createdAt: text("created_at").notNull(),       // ← NEW
    address: text("address"),                       // ← NEW
    city: text("city"),                             // ← NEW
    origin: text("origin"),                         // ← NEW (canal de aquisição)
  },
  (t) => ({
    orgIdx: index("idx_customers_organization_id").on(t.organizationId),
    cpfIdx: index("idx_customers_cpf").on(t.cpf),
    createdAtIdx: index("idx_customers_created_at").on(t.createdAt),
  }),
);
```

- [ ] **Step 2: Adicionar tabela `postSaleFollowups` antes da seção `// ---- Helpers`**

```ts
// ---- Post-sale followups -------------------------------------------------

export const POST_SALE_FOLLOWUP_STATUSES = ["pendente", "concluido", "cancelado"] as const;
export type PostSaleFollowupStatus = (typeof POST_SALE_FOLLOWUP_STATUSES)[number];

export const postSaleFollowups = oficina.table(
  "post_sale_followups",
  {
    id: serial("id").primaryKey(),
    organizationId: integer("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),
    serviceOrderId: integer("service_order_id")
      .notNull()
      .references(() => serviceOrders.id, { onDelete: "cascade" }),
    customerId: integer("customer_id")
      .notNull()
      .references(() => customers.id, { onDelete: "cascade" }),
    scheduledDate: text("scheduled_date").notNull(),
    description: text("description").notNull(),
    responsibleUserId: integer("responsible_user_id").references(() => users.id, {
      onDelete: "set null",
    }),
    status: text("status").notNull().default("pendente"),
    notes: text("notes"),
    createdAt: text("created_at").notNull(),
    updatedAt: text("updated_at").notNull(),
  },
  (t) => ({
    orgIdx: index("idx_post_sale_followups_organization_id").on(t.organizationId),
    serviceOrderIdx: index("idx_post_sale_followups_service_order_id").on(t.serviceOrderId),
    customerIdx: index("idx_post_sale_followups_customer_id").on(t.customerId),
    scheduledDateIdx: index("idx_post_sale_followups_scheduled_date").on(t.scheduledDate),
    responsibleUserIdx: index("idx_post_sale_followups_responsible_user_id").on(t.responsibleUserId),
  }),
);
export const insertPostSaleFollowupSchema = createInsertSchema(postSaleFollowups).omit({ id: true });
export type InsertPostSaleFollowup = z.infer<typeof insertPostSaleFollowupSchema>;
export type PostSaleFollowup = typeof postSaleFollowups.$inferSelect;
```

- [ ] **Step 3: Verificar tsc**

```bash
npx tsc --noEmit --pretty false
```

Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add shared/schema.ts
git commit -m "feat(schema): add customer CRM fields + postSaleFollowups types"
```

---

## Task 4: Storage layer — getCustomerStats

**Files:**
- Modify: `server/storage.ts` (adicionar método)

- [ ] **Step 1: Adicionar import + método**

Localizar bloco de métodos do customer (procurar por `getCustomersPage` ou `getCustomer`). Adicionar logo após `getCustomer`:

```ts
async getCustomerStats(customerId: number, orgId: number): Promise<{
  totalOrders: number;
  ongoingOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  totalSpentCents: number;
  avgTicketCents: number;
  firstOrderAt: string | null;
  lastOrderAt: string | null;
}> {
  const orders = await this.db
    .select({
      id: serviceOrders.id,
      status: serviceOrders.status,
      finalCost: serviceOrders.finalCost,
      estimatedCost: serviceOrders.estimatedCost,
      createdAt: serviceOrders.createdAt,
    })
    .from(serviceOrders)
    .where(and(
      eq(serviceOrders.customerId, customerId),
      eq(serviceOrders.organizationId, orgId),
    ));

  const ongoing = orders.filter((o) =>
    ["diagnostico","aguardando_aprovacao","aprovado","em_execucao","aguardando_peca","pronto"].includes(o.status)
  ).length;
  const completed = orders.filter((o) => o.status === "entregue").length;
  const cancelled = orders.filter((o) => o.status === "cancelado").length;

  // Total gasto = soma de finalCost (não estimated) das OS entregues.
  const totalSpentCents = orders
    .filter((o) => o.status === "entregue" && o.finalCost != null)
    .reduce((sum, o) => sum + (o.finalCost ?? 0), 0);

  const avgTicketCents = completed > 0 ? Math.round(totalSpentCents / completed) : 0;

  const sortedByDate = [...orders].sort((a, b) =>
    a.createdAt.localeCompare(b.createdAt)
  );
  const firstOrderAt = sortedByDate.length > 0 ? sortedByDate[0].createdAt : null;
  const lastOrderAt = sortedByDate.length > 0 ? sortedByDate[sortedByDate.length - 1].createdAt : null;

  return {
    totalOrders: orders.length,
    ongoingOrders: ongoing,
    completedOrders: completed,
    cancelledOrders: cancelled,
    totalSpentCents,
    avgTicketCents,
    firstOrderAt,
    lastOrderAt,
  };
}
```

- [ ] **Step 2: tsc check**

```bash
npx tsc --noEmit --pretty false
```

Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add server/storage.ts
git commit -m "feat(storage): add getCustomerStats with ongoing/completed/spent aggregates"
```

---

## Task 5: Endpoint GET /api/customers/:id/stats — TDD

**Files:**
- Create: `tests/customers-stats.test.ts`
- Modify: `server/routes/customers.ts` (adicionar handler ao final do `registerCustomerRoutes`)

- [ ] **Step 1: Escreve o teste primeiro**

```ts
// tests/customers-stats.test.ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createTestApp, seedTenant, authHeader, cleanup } from "./helpers";

describe("GET /api/customers/:id/stats", () => {
  let app: Awaited<ReturnType<typeof createTestApp>>;
  let token: string;
  let customerId: number;

  beforeAll(async () => {
    app = await createTestApp();
    const seeded = await seedTenant(app, {
      withCustomerAndOrders: [
        { status: "entregue", finalCost: 50000 },
        { status: "entregue", finalCost: 30000 },
        { status: "em_execucao", estimatedCost: 20000 },
        { status: "cancelado" },
      ],
    });
    token = await authHeader(seeded.user);
    customerId = seeded.customerId;
  });

  afterAll(() => cleanup(app));

  it("returns aggregates for customer with mixed status orders", async () => {
    const res = await app.request(`/api/customers/${customerId}/stats`, {
      headers: { Authorization: token },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.totalOrders).toBe(4);
    expect(body.completedOrders).toBe(2);
    expect(body.ongoingOrders).toBe(1);
    expect(body.cancelledOrders).toBe(1);
    expect(body.totalSpentCents).toBe(80000);
    expect(body.avgTicketCents).toBe(40000);
    expect(body.firstOrderAt).toBeTruthy();
    expect(body.lastOrderAt).toBeTruthy();
  });

  it("returns zeros for customer with no orders", async () => {
    const seeded = await seedTenant(app, { withCustomerAndOrders: [] });
    const t = await authHeader(seeded.user);
    const res = await app.request(`/api/customers/${seeded.customerId}/stats`, {
      headers: { Authorization: t },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.totalOrders).toBe(0);
    expect(body.completedOrders).toBe(0);
    expect(body.totalSpentCents).toBe(0);
    expect(body.avgTicketCents).toBe(0);
    expect(body.firstOrderAt).toBeNull();
    expect(body.lastOrderAt).toBeNull();
  });

  it("returns 404 for non-existent customer", async () => {
    const res = await app.request(`/api/customers/9999999/stats`, {
      headers: { Authorization: token },
    });
    expect(res.status).toBe(404);
  });

  it("returns 401 without auth", async () => {
    const res = await app.request(`/api/customers/${customerId}/stats`);
    expect(res.status).toBe(401);
  });
});
```

> **Nota:** os helpers `createTestApp`, `seedTenant`, `authHeader`, `cleanup` devem existir em `tests/helpers.ts`. Se não existirem ou se o shape do `seedTenant` for diferente, **PARE** e adapte o teste pro padrão real do projeto antes de prosseguir. Se o projeto usa supertest direto, troque `app.request` por `request(app).get(...)`.

- [ ] **Step 2: Roda o teste — espera FAIL**

```bash
npx vitest run tests/customers-stats.test.ts
```

Expected: FAIL (404 em todas as rotas porque endpoint não existe).

- [ ] **Step 3: Implementa o handler**

Em `server/routes/customers.ts`, adicionar logo após o `app.get("/api/customers/:id/context"...)`:

```ts
app.get("/api/customers/:id/stats", requireAuth, async (req: Request, res: Response) => {
  const id = Number(req.params.id);
  const org = tenantId(req);
  const customer = await storage.getCustomer(id, org);
  if (!customer) return res.status(404).json({ message: "Cliente não encontrado" });
  const stats = await storage.getCustomerStats(id, org);
  res.json(stats);
});
```

- [ ] **Step 4: Roda o teste — espera PASS**

```bash
npx vitest run tests/customers-stats.test.ts
```

Expected: PASS (4 testes verdes).

- [ ] **Step 5: Commit**

```bash
git add tests/customers-stats.test.ts server/routes/customers.ts
git commit -m "feat(api): GET /api/customers/:id/stats with ongoing/completed/spent aggregates"
```

---

## Task 6: Storage methods — postSaleFollowups CRUD

**Files:**
- Modify: `server/storage.ts`

- [ ] **Step 1: Adicionar import**

No bloco de imports, adicionar `postSaleFollowups` e `type PostSaleFollowup, type InsertPostSaleFollowup`.

- [ ] **Step 2: Adicionar métodos (no bloco apropriado, em ordem alfabética se houver)**

```ts
async listPostSaleFollowupsByOrder(orderId: number, orgId: number): Promise<PostSaleFollowup[]> {
  return this.db
    .select()
    .from(postSaleFollowups)
    .where(and(
      eq(postSaleFollowups.serviceOrderId, orderId),
      eq(postSaleFollowups.organizationId, orgId),
    ))
    .orderBy(desc(postSaleFollowups.scheduledDate));
}

async listPostSaleFollowupsByCustomer(customerId: number, orgId: number): Promise<PostSaleFollowup[]> {
  return this.db
    .select()
    .from(postSaleFollowups)
    .where(and(
      eq(postSaleFollowups.customerId, customerId),
      eq(postSaleFollowups.organizationId, orgId),
    ))
    .orderBy(desc(postSaleFollowups.scheduledDate));
}

async getPostSaleFollowup(id: number, orgId: number): Promise<PostSaleFollowup | undefined> {
  const rows = await this.db
    .select()
    .from(postSaleFollowups)
    .where(and(
      eq(postSaleFollowups.id, id),
      eq(postSaleFollowups.organizationId, orgId),
    ))
    .limit(1);
  return rows[0];
}

async createPostSaleFollowup(data: InsertPostSaleFollowup): Promise<PostSaleFollowup> {
  const now = new Date().toISOString();
  const [row] = await this.db
    .insert(postSaleFollowups)
    .values({ ...data, createdAt: now, updatedAt: now })
    .returning();
  return row;
}

async updatePostSaleFollowup(
  id: number,
  orgId: number,
  patch: Partial<InsertPostSaleFollowup>,
): Promise<PostSaleFollowup | undefined> {
  const [row] = await this.db
    .update(postSaleFollowups)
    .set({ ...patch, updatedAt: new Date().toISOString() })
    .where(and(
      eq(postSaleFollowups.id, id),
      eq(postSaleFollowups.organizationId, orgId),
    ))
    .returning();
  return row;
}

async deletePostSaleFollowup(id: number, orgId: number): Promise<boolean> {
  const rows = await this.db
    .delete(postSaleFollowups)
    .where(and(
      eq(postSaleFollowups.id, id),
      eq(postSaleFollowups.organizationId, orgId),
    ))
    .returning({ id: postSaleFollowups.id });
  return rows.length > 0;
}
```

- [ ] **Step 3: tsc check**

```bash
npx tsc --noEmit --pretty false
```

Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add server/storage.ts
git commit -m "feat(storage): postSaleFollowups CRUD methods (list/get/create/update/delete)"
```

---

## Task 7: Endpoints CRUD /api/post-sale-followups — TDD

**Files:**
- Create: `tests/post-sale-followups.test.ts`
- Create: `server/routes/post-sale-followups.ts`
- Modify: `server/routes/index.ts` (registrar)

- [ ] **Step 1: Escreve testes**

```ts
// tests/post-sale-followups.test.ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createTestApp, seedTenant, authHeader, cleanup } from "./helpers";

describe("Post-sale followups CRUD", () => {
  let app: Awaited<ReturnType<typeof createTestApp>>;
  let token: string;
  let orderId: number;
  let customerId: number;

  beforeAll(async () => {
    app = await createTestApp();
    const seeded = await seedTenant(app, {
      withCustomerAndOrders: [{ status: "entregue", finalCost: 100000 }],
    });
    token = await authHeader(seeded.user);
    orderId = seeded.orderIds[0];
    customerId = seeded.customerId;
  });

  afterAll(() => cleanup(app));

  it("creates a followup with required fields", async () => {
    const res = await app.request("/api/post-sale-followups", {
      method: "POST",
      headers: { Authorization: token, "Content-Type": "application/json" },
      body: JSON.stringify({
        serviceOrderId: orderId,
        customerId,
        scheduledDate: "2026-05-20",
        description: "Confirmar satisfação com a entrega",
      }),
    });
    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body.id).toBeTypeOf("number");
    expect(body.status).toBe("pendente");
    expect(body.scheduledDate).toBe("2026-05-20");
  });

  it("lists followups by service order", async () => {
    const res = await app.request(`/api/post-sale-followups?serviceOrderId=${orderId}`, {
      headers: { Authorization: token },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBeGreaterThanOrEqual(1);
  });

  it("lists followups by customer", async () => {
    const res = await app.request(`/api/post-sale-followups?customerId=${customerId}`, {
      headers: { Authorization: token },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBeGreaterThanOrEqual(1);
  });

  it("returns 400 when neither serviceOrderId nor customerId provided", async () => {
    const res = await app.request("/api/post-sale-followups", {
      headers: { Authorization: token },
    });
    expect(res.status).toBe(400);
  });

  it("updates status to concluido", async () => {
    const create = await app.request("/api/post-sale-followups", {
      method: "POST",
      headers: { Authorization: token, "Content-Type": "application/json" },
      body: JSON.stringify({
        serviceOrderId: orderId,
        customerId,
        scheduledDate: "2026-05-21",
        description: "Outro followup",
      }),
    });
    const created = await create.json();

    const res = await app.request(`/api/post-sale-followups/${created.id}`, {
      method: "PATCH",
      headers: { Authorization: token, "Content-Type": "application/json" },
      body: JSON.stringify({ status: "concluido", notes: "Cliente satisfeito" }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe("concluido");
    expect(body.notes).toBe("Cliente satisfeito");
  });

  it("deletes a followup", async () => {
    const create = await app.request("/api/post-sale-followups", {
      method: "POST",
      headers: { Authorization: token, "Content-Type": "application/json" },
      body: JSON.stringify({
        serviceOrderId: orderId,
        customerId,
        scheduledDate: "2026-05-22",
        description: "Pra deletar",
      }),
    });
    const created = await create.json();
    const res = await app.request(`/api/post-sale-followups/${created.id}`, {
      method: "DELETE",
      headers: { Authorization: token },
    });
    expect(res.status).toBe(200);
    const verify = await app.request(`/api/post-sale-followups/${created.id}`, {
      headers: { Authorization: token },
    });
    expect(verify.status).toBe(404);
  });

  it("returns 401 without auth", async () => {
    const res = await app.request(`/api/post-sale-followups?serviceOrderId=${orderId}`);
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 2: Roda — espera FAIL** (rota não existe)

```bash
npx vitest run tests/post-sale-followups.test.ts
```

- [ ] **Step 3: Cria `server/routes/post-sale-followups.ts`**

```ts
import type { Express, Request, Response } from "express";
import { storage } from "../storage";
import { insertPostSaleFollowupSchema } from "@shared/schema";
import { requireAuth, tenantId } from "../middleware/auth";

export function registerPostSaleFollowupRoutes(app: Express): void {
  // GET /api/post-sale-followups?serviceOrderId=X | ?customerId=Y
  app.get("/api/post-sale-followups", requireAuth, async (req: Request, res: Response) => {
    const org = tenantId(req);
    const orderId = req.query.serviceOrderId
      ? Number(req.query.serviceOrderId)
      : null;
    const customerId = req.query.customerId
      ? Number(req.query.customerId)
      : null;

    if (orderId == null && customerId == null) {
      return res.status(400).json({
        message: "Forneça serviceOrderId ou customerId como query param",
      });
    }

    const items = orderId != null
      ? await storage.listPostSaleFollowupsByOrder(orderId, org)
      : await storage.listPostSaleFollowupsByCustomer(customerId!, org);

    res.json(items);
  });

  app.get("/api/post-sale-followups/:id", requireAuth, async (req: Request, res: Response) => {
    const item = await storage.getPostSaleFollowup(Number(req.params.id), tenantId(req));
    if (!item) return res.status(404).json({ message: "Followup não encontrado" });
    res.json(item);
  });

  app.post("/api/post-sale-followups", requireAuth, async (req: Request, res: Response) => {
    const parsed = insertPostSaleFollowupSchema.parse({
      ...req.body,
      organizationId: tenantId(req),
    });
    const created = await storage.createPostSaleFollowup(parsed);
    res.status(201).json(created);
  });

  app.patch("/api/post-sale-followups/:id", requireAuth, async (req: Request, res: Response) => {
    const updated = await storage.updatePostSaleFollowup(
      Number(req.params.id),
      tenantId(req),
      req.body,
    );
    if (!updated) return res.status(404).json({ message: "Followup não encontrado" });
    res.json(updated);
  });

  app.delete("/api/post-sale-followups/:id", requireAuth, async (req: Request, res: Response) => {
    const ok = await storage.deletePostSaleFollowup(Number(req.params.id), tenantId(req));
    if (!ok) return res.status(404).json({ message: "Followup não encontrado" });
    res.json({ message: "ok" });
  });
}
```

- [ ] **Step 4: Registra em `server/routes/index.ts`**

```ts
import { registerPostSaleFollowupRoutes } from "./post-sale-followups";
// ...
registerPostSaleFollowupRoutes(app);
```

(Adicionar próximo às outras chamadas `register*Routes(app)`.)

- [ ] **Step 5: Roda — espera PASS**

```bash
npx vitest run tests/post-sale-followups.test.ts
```

Expected: 7 testes verdes.

- [ ] **Step 6: Commit**

```bash
git add server/routes/post-sale-followups.ts server/routes/index.ts tests/post-sale-followups.test.ts
git commit -m "feat(api): post-sale-followups CRUD endpoints with org scoping"
```

---

## Task 8: Frontend — PageHeader primitive

**Files:**
- Create: `client/src/design-system/page-header.tsx`

- [ ] **Step 1: Cria componente**

```tsx
import type { ReactNode } from "react";

interface PageHeaderProps {
  /** Eyebrow uppercase mono — ex: "DAP · OPERAÇÃO · CLIENTES" */
  eyebrow?: string;
  /** Título principal — h1, font-semibold */
  title: string;
  /** Subtítulo opcional — text-sm muted */
  subtitle?: string;
  /** Slot direita — geralmente CTAs */
  actions?: ReactNode;
  className?: string;
}

export function PageHeader({
  eyebrow,
  title,
  subtitle,
  actions,
  className,
}: PageHeaderProps) {
  return (
    <header
      className={`flex flex-wrap items-end justify-between gap-3 pb-4 border-b border-border/40 ${className ?? ""}`}
    >
      <div className="space-y-1 min-w-0">
        {eyebrow && (
          <p className="text-[10px] font-mono uppercase tracking-[0.18em] text-muted-foreground">
            {eyebrow}
          </p>
        )}
        <h1 className="text-2xl font-semibold leading-tight truncate">{title}</h1>
        {subtitle && (
          <p className="text-sm text-muted-foreground">{subtitle}</p>
        )}
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2 shrink-0">{actions}</div>}
    </header>
  );
}
```

- [ ] **Step 2: tsc check**

```bash
npx tsc --noEmit --pretty false
```

- [ ] **Step 3: Commit**

```bash
git add client/src/design-system/page-header.tsx
git commit -m "feat(ds): PageHeader primitive (eyebrow + title + subtitle + actions slot)"
```

---

## Task 9: Frontend — TierBadge primitive

**Files:**
- Create: `client/src/design-system/tier-badge.tsx`

- [ ] **Step 1: Cria componente**

```tsx
import type { HTMLAttributes } from "react";

export type Tier = "bronze" | "prata" | "ouro" | "platina";

const TIER_META: Record<Tier, { label: string; classes: string; icon: string }> = {
  bronze: {
    label: "Bronze",
    classes: "bg-amber-900/20 text-amber-700 border-amber-900/30",
    icon: "●",
  },
  prata: {
    label: "Prata",
    classes: "bg-slate-300/20 text-slate-300 border-slate-400/30",
    icon: "●",
  },
  ouro: {
    label: "Ouro",
    classes: "bg-yellow-400/20 text-yellow-300 border-yellow-400/30",
    icon: "●",
  },
  platina: {
    label: "Platina",
    classes: "bg-cyan-300/20 text-cyan-200 border-cyan-300/40",
    icon: "★",
  },
};

interface TierBadgeProps extends HTMLAttributes<HTMLSpanElement> {
  tier: Tier | string | null | undefined;
  /** Compacta — sem label, só ícone */
  compact?: boolean;
}

function isTier(t: unknown): t is Tier {
  return t === "bronze" || t === "prata" || t === "ouro" || t === "platina";
}

export function TierBadge({ tier, compact, className, ...rest }: TierBadgeProps) {
  const resolved: Tier = isTier(tier) ? tier : "bronze";
  const meta = TIER_META[resolved];
  return (
    <span
      className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-mono uppercase tracking-[0.12em] border ${meta.classes} ${className ?? ""}`}
      {...rest}
    >
      <span aria-hidden>{meta.icon}</span>
      {!compact && meta.label}
    </span>
  );
}
```

- [ ] **Step 2: tsc check**

- [ ] **Step 3: Commit**

```bash
git add client/src/design-system/tier-badge.tsx
git commit -m "feat(ds): TierBadge primitive (bronze/prata/ouro/platina)"
```

---

## Task 10: Frontend — EmptyState primitive

**Files:**
- Create: `client/src/design-system/empty-state.tsx`

- [ ] **Step 1: Cria componente**

```tsx
import type { ReactNode } from "react";

interface EmptyStateProps {
  /** Ícone Lucide ou outro elemento React */
  icon?: ReactNode;
  title: string;
  description?: string;
  /** CTA opcional */
  action?: ReactNode;
  className?: string;
}

export function EmptyState({ icon, title, description, action, className }: EmptyStateProps) {
  return (
    <div
      className={`flex flex-col items-center justify-center text-center py-12 px-6 space-y-3 ${className ?? ""}`}
    >
      {icon && <div className="text-muted-foreground/60 [&>svg]:w-10 [&>svg]:h-10">{icon}</div>}
      <div className="space-y-1">
        <p className="text-sm font-medium">{title}</p>
        {description && (
          <p className="text-xs text-muted-foreground max-w-sm">{description}</p>
        )}
      </div>
      {action && <div className="pt-2">{action}</div>}
    </div>
  );
}
```

- [ ] **Step 2: tsc check + commit**

```bash
git add client/src/design-system/empty-state.tsx
git commit -m "feat(ds): EmptyState primitive (icon + title + description + action)"
```

---

## Task 11: Frontend — SectionHeader primitive

**Files:**
- Create: `client/src/design-system/section-header.tsx`

- [ ] **Step 1: Cria componente**

```tsx
import type { ReactNode } from "react";

interface SectionHeaderProps {
  /** Ícone Lucide opcional, w-3.5 h-3.5 esperado */
  icon?: ReactNode;
  /** Label uppercase mono */
  label: string;
  /** Contagem opcional ao lado do label, ex: (12) */
  count?: number;
  /** Slot direita — filtros, link ver-mais, etc */
  right?: ReactNode;
  className?: string;
}

export function SectionHeader({ icon, label, count, right, className }: SectionHeaderProps) {
  return (
    <div
      className={`flex items-center justify-between gap-3 ${className ?? ""}`}
    >
      <h2 className="text-xs font-semibold uppercase tracking-[0.14em] text-muted-foreground flex items-center gap-2">
        {icon && <span className="shrink-0">{icon}</span>}
        <span>{label}</span>
        {typeof count === "number" && (
          <span className="text-muted-foreground/60 font-mono">({count})</span>
        )}
      </h2>
      {right && <div className="flex items-center gap-2">{right}</div>}
    </div>
  );
}
```

- [ ] **Step 2: tsc check + commit**

```bash
git add client/src/design-system/section-header.tsx
git commit -m "feat(ds): SectionHeader primitive (icon + label + count + right slot)"
```

---

## Task 12: Frontend — FilterBar primitive

**Files:**
- Create: `client/src/design-system/filter-bar.tsx`

- [ ] **Step 1: Cria componente**

```tsx
import type { ReactNode } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Search, X } from "lucide-react";

interface FilterBarProps {
  search?: {
    value: string;
    onChange: (next: string) => void;
    placeholder?: string;
  };
  /** Slots livres pra Selects e outros filtros */
  children?: ReactNode;
  /** Mostra botão "limpar" quando algum filtro está ativo */
  hasActiveFilters?: boolean;
  onClear?: () => void;
  className?: string;
}

export function FilterBar({
  search,
  children,
  hasActiveFilters,
  onClear,
  className,
}: FilterBarProps) {
  return (
    <div className={`flex flex-wrap items-center gap-2 ${className ?? ""}`}>
      {search && (
        <div className="relative flex-1 min-w-[220px]">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
          <Input
            value={search.value}
            onChange={(e) => search.onChange(e.target.value)}
            placeholder={search.placeholder ?? "Buscar..."}
            className="pl-8"
            data-testid="filterbar-search"
          />
        </div>
      )}
      {children}
      {hasActiveFilters && onClear && (
        <Button
          variant="ghost"
          size="sm"
          onClick={onClear}
          data-testid="filterbar-clear"
          className="text-xs"
        >
          <X className="w-3 h-3 mr-1" />
          Limpar
        </Button>
      )}
    </div>
  );
}
```

- [ ] **Step 2: tsc check + commit**

```bash
git add client/src/design-system/filter-bar.tsx
git commit -m "feat(ds): FilterBar primitive (search + slot + clear)"
```

---

## Task 13: Barrel export

**Files:**
- Create: `client/src/design-system/index.ts`

- [ ] **Step 1: Cria barrel**

```ts
// Apex × Chassis primitives + Rodada 6a additions.
export * from "./dap-components";
export * from "./dap-page-frame";
export { PageHeader } from "./page-header";
export { TierBadge, type Tier } from "./tier-badge";
export { EmptyState } from "./empty-state";
export { SectionHeader } from "./section-header";
export { FilterBar } from "./filter-bar";
```

> Se `index.ts` já existe, **append** as últimas 5 linhas.

- [ ] **Step 2: tsc check + commit**

```bash
git add client/src/design-system/index.ts
git commit -m "feat(ds): barrel export for Rodada 6a primitives"
```

---

## Task 14: Final verification

- [ ] **Step 1: Full tsc**

```bash
cd C:/THALES/DAP4/5-dap-operacao
npx tsc --noEmit --pretty false; echo "exit=$?"
```

Expected: exit 0.

- [ ] **Step 2: Backend tests run**

```bash
npx vitest run tests/customers-stats.test.ts tests/post-sale-followups.test.ts
```

Expected: 11 testes verdes (4 stats + 7 followups).

- [ ] **Step 3: Smoke local**

```bash
npm run dev
```

Manual:
- Login admin em `localhost:5000`
- Browser DevTools → Network: hit `GET /api/customers/<id-real>/stats` direto via console fetch (com Authorization header copiado de outra request) → espera 200 com shape correto
- `POST /api/post-sale-followups` com payload válido → espera 201

- [ ] **Step 4: Push branch**

```bash
git push -u origin feat/consultor-rodada-6a-foundations
```

- [ ] **Step 5: Abrir PR**

```bash
gh pr create --base master \
  --title "Rodada 6a — Foundations: customer CRM fields + post_sale_followups + 5 DS primitives" \
  --body "..."
```

PR body deve listar:
- 2 migrations aplicadas (com IDs)
- 1 endpoint stats
- 5 endpoints CRUD followups
- 5 design system primitives
- Test count + tsc status
- Próxima rodada (6b — Ficha CRM + OS Lista/Histórico + Detalhe OS com Adiantamento+Pós-venda)

---

## Self-review checklist (run before declaring complete)

- [ ] Todas as migrations aplicadas em pre-prod (não só locais)
- [ ] `customers` tem 4 colunas novas confirmadas via information_schema
- [ ] `post_sale_followups` table existe + RLS policy ativa
- [ ] Schema.ts tem `customers.createdAt` + `postSaleFollowups` table + types
- [ ] Storage tem 6 métodos novos (1 stats + 5 followups CRUD)
- [ ] 6 endpoints novos (1 stats + 5 followups)
- [ ] 5 primitives criados + barrel
- [ ] tsc verde
- [ ] 11 testes backend verdes
- [ ] Smoke local hit endpoints reais

## Não escopo (fica pra 6b/6c)

- Ficha CRM completa (consome stats endpoint) → 6b
- Card Adiantamento (consome `serviceOrders.advancePayment` que já existe) → 6b
- Card Pós-venda (consome endpoints novos) → 6b
- Lista/Histórico OS refinement → 6b
- Detalhe OS reorganização → 6b
- Dashboard refactor → 6c
- Pátio refinement → 6c
- Agenda refinement → 6c
- Linha do Tempo (Gantt) → 6c
- Customer.tier UI usage → 6b (consome TierBadge)

## Riscos conhecidos

1. **Helpers de teste podem não existir** — `tests/helpers.ts` precisa ter `createTestApp`, `seedTenant`, `authHeader`, `cleanup` com o shape esperado pelas Tasks 5 e 7. Se o pattern do projeto for diferente (ex: supertest direto), Task 5 e 7 precisam adaptação no Step 1 antes do TDD começar.
2. **Migration createdAt backfill** — `NOW()::text` em PG retorna timestamp completo (`2026-05-13 14:32:01.123456+00`), não ISO. Se UI espera ISO estrito, ajustar pra `to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')`. Verificar formato de outros createAt no DB antes de aplicar.
3. **RLS policy + Drizzle session var** — `current_setting('app.organization_id', true)` precisa ser SET pelo middleware antes de cada query. Confirmar que `0002_rls_tenant_isolation.sql` (já aplicado) configurou isso e que post_sale_followups segue o mesmo padrão.
