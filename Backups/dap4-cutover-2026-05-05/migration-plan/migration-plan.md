# Migration Plan: dap-operacao SQLite -> Supabase Postgres
**Date:** 2026-05-05
**Branch:** feat/postgres-migration from master 1a74196

## 1. Tables Inventory (12 tables)

| Table |
|---|
| organizations |
| users |
| customers |
| vehicles |
| mechanics |
| service_orders |
| service_items |
| service_order_comments |
| service_order_attachments |
| appointments |
| checklists |
| telemetry |
| payments |

## 2. Key Conversions

- integer autoIncrement -> serial()
- text ISO date strings -> timestamp(withTimezone:true) -> JS Date on read
- integer 0/1 booleans (active, seat_cover etc) -> boolean
- text enum columns -> pgEnum (see schema-postgres.ts for full mapping)
- money integer cents -> integer, unchanged
- all FK onDelete semantics preserved 1:1

## 3. Per-Table Notes

organizations: created_at TEXT -> TIMESTAMPTZ. Drizzle returns JS Date. Code doing string ops breaks.
users: role TEXT -> userRoleEnum. Audit: SELECT DISTINCT role FROM users before ETL.
customers: tier TEXT -> customerTierEnum. NULL preserved.
mechanics: active INTEGER 0/1 -> BOOLEAN. ETL cast required. Check === 1 comparisons in app.
service_orders: created_at, updated_at -> TIMESTAMPTZ. status -> enum.
service_items: type, complexity, status -> pgEnums. Money unchanged.
service_order_comments: category -> enum. created_at -> TIMESTAMPTZ.
service_order_attachments: kind kept as text (open set). created_at -> TIMESTAMPTZ.
appointments: date, time kept as text (YYYY-MM-DD, HH:MM) to avoid tz risk. status -> enum.
checklists: seat_cover, steering_cover, floor_mat, fender_protector 0/1 -> BOOLEAN. created_at nullable.
telemetry: created_at -> TIMESTAMPTZ. Status fields kept as text.
payments: paid_at nullable TEXT -> TIMESTAMPTZ nullable. status -> enum.

## 4. Code Touchpoints

server/storage.ts:
  - Import: drizzle-orm/libsql -> drizzle-orm/postgres-js
  - Client: createClient -> postgres(SUPABASE_DB_URL)
  - Remove: PRAGMA foreign_keys = ON
  - sql<number> count(*) and .returning() work unchanged

shared/schema.ts:
  - Replace with schema-postgres.ts
  - Imports: drizzle-orm/sqlite-core -> drizzle-orm/pg-core

drizzle.config.ts:
  - dialect: sqlite -> postgresql
  - dbCredentials.url: process.env.SUPABASE_DB_URL

migrations/:
  - Delete SQLite files. drizzle-kit generate + migrate against Supabase.

package.json:
  - Add: postgres ^3.4.0
  - Remove: @libsql/client after rollback window

## 5. Test Strategy

Recommended: Supabase CLI local stack

Why not alternatives:
  testcontainers: Docker in CI, no Supabase-specific types
  pg-mem: does not support pgEnum -- fails immediately
  supabase start: full local Postgres matching production exactly

Setup: npm install -g supabase && supabase init && supabase start
  SUPABASE_DB_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres
  drizzle-kit migrate && npx vitest

## 6. Auth

Out of scope. bcrypt + Express session memorystore is DB-agnostic.
See auth-decision.md (future) for Supabase Auth adoption.

## 7. Multi-Tenant Strategy

Keep app-level WHERE organization_id filters (already on every query).
Add Postgres RLS as second layer for defense-in-depth.

RLS template (repeat per tenant table):
  ALTER TABLE <table> ENABLE ROW LEVEL SECURITY;
  CREATE POLICY tenant_isolation ON <table>
    USING (organization_id = current_setting(app.current_organization_id)::integer);

Note: Express service role bypasses RLS by default.
App-level WHERE is primary isolation. RLS is the safety net.

## 8. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Timestamp type change (text->Date) | HIGH | grep createdAt/updatedAt/paidAt in routes/ |
| Boolean coercion (0/1->false/true) | MEDIUM | grep === 1 on active/cover fields |
| pgEnum exhaustiveness | MEDIUM | SELECT DISTINCT on enum cols before ETL |
| Sequence gap after ETL | MEDIUM | setval(pg_get_serial_sequence) per table |
| Transaction semantics | LOW | add db.transaction() for multi-step ops |
| count(*) bigint | LOW | Number() cast already in storage.ts |

## 9. Dev Effort Estimate

| Task | Hours |
|---|---|
| schema-postgres.ts (done) | 0h |
| storage.ts driver swap | 1h |
| drizzle.config.ts | 0.25h |
| Generate + apply Postgres migration | 0.5h |
| ETL script (SQLite -> Postgres) | 3h |
| Fix timestamp/boolean in routes/ | 2h |
| Test suite update | 2h |
| Run 117 tests on local Supabase | 1h |
| Staging deploy + smoke | 1h |
| Total without RLS | ~11h |
| RLS hardening (separate pass) | +3h |