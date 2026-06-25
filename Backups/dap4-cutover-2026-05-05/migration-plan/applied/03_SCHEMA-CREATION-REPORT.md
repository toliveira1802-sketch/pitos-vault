# Schema Creation Report — `oficina`

**Date:** 2026-05-05
**Source of truth:** `migration-plan/schema-postgres.ts` (Drizzle pg-core, 13 tables, 10 enums)
**DDL file:** `migration-plan/applied/03_create_oficina_schema.sql`

---

## Targets

| Role     | Project ref            | Region    | Notes |
|----------|------------------------|-----------|-------|
| PROD     | `acuufrgoyjwzlyhopaus` | us-west-2 | DOCTOR PRIME — production home of dap-operacao. `public` schema untouched. |
| SANDBOX  | `cpzgtfblywexqglqkgbt` | us-east-1 | DAP4.0 abandoned project — used for the 117 vitest E2E tests. |

---

## Verification counts (identical across both projects)

| Object               | Expected | DOCTOR PRIME | DAP4.0 | Match |
|----------------------|----------|--------------|--------|-------|
| schemas (`oficina`)  | 1        | 1            | 1      | yes   |
| tables               | 13       | 13           | 13     | yes   |
| enum types           | 10       | 10           | 10     | yes   |
| indexes (PK + non-PK)| 46       | 46           | 46     | yes   |
| RLS policies         | 13       | 13           | 13     | yes   |

> Index count = 13 PK + 32 non-PK btree + 1 unique on `organizations.slug` = 46.
> One `service_role_all` policy per table = 13.

---

## Tables (13)

`organizations`, `users`, `customers`, `vehicles`, `mechanics`, `service_orders`, `service_items`, `service_order_comments`, `service_order_attachments`, `appointments`, `checklists`, `telemetry`, `payments`.

Cross-checked alphabetical lists from both projects — identical.

## Enums (10)

`mechanic_level`, `service_order_status`, `service_item_type`, `service_item_complexity`, `service_item_status`, `customer_tier`, `appointment_status`, `comment_category`, `payment_status`, `user_role`.

## RLS

All 13 tables: `ENABLE ROW LEVEL SECURITY` + one `service_role_all` policy (`FOR ALL TO service_role USING (true) WITH CHECK (true)`).

No grants to `anon` or `authenticated`. Only `service_role` has `USAGE` on schema and `ALL` on tables/sequences.

## Discrepancies

**None.** PROD and SANDBOX are byte-for-byte equivalent at the schema/enum/index/policy level.

---

## Migration chunks (11 per project, 22 total)

All chunks applied successfully on first attempt — zero failures, zero retries.

| # | Name | Contents |
|---|------|----------|
| 1 | `oficina_schema_v1_chunk_1_schema_enums` | `CREATE SCHEMA` + 10 enum types |
| 2 | `oficina_schema_v1_chunk_2_root_tables` | organizations, users, customers, vehicles, mechanics |
| 3 | `oficina_schema_v1_chunk_3_service_orders_items` | service_orders, service_items |
| 4 | `oficina_schema_v1_chunk_4_so_children_appts` | service_order_comments, service_order_attachments, appointments |
| 5 | `oficina_schema_v1_chunk_5_checklists_telemetry_payments` | checklists, telemetry, payments |
| 6 | `oficina_schema_v1_chunk_6_indexes_part_1` | indexes for users → service_items |
| 7 | `oficina_schema_v1_chunk_7_indexes_part_2` | indexes for so_comments → payments |
| 8 | `oficina_schema_v1_chunk_8_rls_enable` | `ALTER TABLE … ENABLE ROW LEVEL SECURITY` × 13 |
| 9 | `oficina_schema_v1_chunk_9_policies_part_1` | service_role policies for 7 tables |
| 10 | `oficina_schema_v1_chunk_10_policies_part_2` | service_role policies for 6 tables |
| 11 | `oficina_schema_v1_chunk_11_grants` | `GRANT USAGE/ALL/SEQUENCES … TO service_role` |

All chunks under 2 KB to respect Cloudflare WAF limits.

---

## Production protection

DOCTOR PRIME `public` schema not touched. Pre-existing policies in `public` remain in place. The new `oficina` schema is fully isolated.

---

## Connection strings (for `dap-operacao` `.env`)

Replace `<password>` with the Postgres password from each project's database settings (Supabase dashboard → Project Settings → Database → Connection string). Use the **pooler** URL for serverless / short-lived connections:

```
# PROD (DOCTOR PRIME)
DATABASE_URL=postgresql://postgres.acuufrgoyjwzlyhopaus:<password>@aws-0-us-west-2.pooler.supabase.com:6543/postgres?schema=oficina

# SANDBOX (DAP4.0 — for vitest)
DATABASE_URL=postgresql://postgres.cpzgtfblywexqglqkgbt:<password>@aws-0-us-east-1.pooler.supabase.com:6543/postgres?schema=oficina
```

Direct connection (port 5432) is also available at `db.<project_ref>.supabase.co` if pooler is not desired.

For Drizzle, set the schema via `pgSchema("oficina")` in the schema file — the `?schema=oficina` query param is informational; PostgreSQL search_path / explicit schema-qualified queries do the real work.
