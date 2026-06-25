# DAP4 Cutover — Phase 0 Supabase Audit

**Date:** 2026-05-05
**Author:** Phase 0 audit subagent (read-only)
**Scope:** Inventory the 3 Supabase projects in org `aldpajllerexnbfqrrgb`, identify P1 (legacy production), capture schema/RLS/indexes/functions for future migration planning. **No data modified.**

---

## TL;DR

- **P1 = `DOCTOR PRIME` (`acuufrgoyjwzlyhopaus`)**, us-west-2, created 2026-01-13.
- 59 tables, **29,635 live rows**, 86 RLS policies, 144 indexes, ~50 user PL/pgSQL routines + pgvector.
- The other two projects:
  - **DAP4.0** (`cpzgtfblywexqglqkgbt`): newer (2026-04-14) Parliament+OS playground, 25 tables, 275 rows. Looks like a rebuild attempt — Parliament tables present but `parliament_voices=0`, `parliament_topics=0`. Anna tables absent. **Not P1.**
  - **DAP TOOLS** (`mtrmtkvhgrzhwhhfffhj`): used by `dap-tools` repo, 28 tables, 1,714 rows. Different domain model (`leads`, `clientes`, `conversas`, `mensagens`, `agentes`, `agente_workflows`). **Not P1.** Has 4 RLS-disabled tables (Supabase advisory level=critical).

## Project identification reasoning

DOCTOR PRIME is P1 because every memory anchor lines up:

| Memory anchor | Evidence in DOCTOR PRIME |
|---|---|
| "5,911 leads" | `crm_leads.rows = 5911` exact match |
| Parliament 13 directors | `parliament_directors.rows = 13` |
| Anna in production | `anna_inbox=141`, `anna_conversations=5`, dedicated RLS `tenant_isolation` policies, `rpc_anna_inbox_claim_next()` SKIP LOCKED dispatcher, `anna_inbox_notify` trigger |
| Sofia agent ledger | `sofia_actions=239` |
| Kommo sync | `kommo_messages=497`, `kommo_conversations=115`, `kommo_channels=2` (Bosch + Prime) |
| Manus enrichment audit (5,192 leads) | `crm_leads_externo=17887` (canonical lake, includes Manus + others) |
| Webhook activity | `webhook_logs=3979` |
| Multi-tenant Bosch+Prime | `tenant_id` defaults `'dap_prime'` baked into anna/kommo/crm tables; `kommo_pipeline_id` differentiates |

## Files produced

```
PITOS/Backups/dap4-cutover-2026-05-05/supabase/
├── AUDIT-REPORT.md                       (this file)
├── DOCTOR_PRIME-tables.json              full table list with rls_enabled + rows + comments
├── DOCTOR_PRIME-rowcounts.json           pg_stat_user_tables sorted desc
├── DOCTOR_PRIME-schema-full.json         columns analysis (678 columns total, 4×200 page raw in transcript)
├── DOCTOR_PRIME-rls-policies.json        86 policies bucketed by pattern
├── DOCTOR_PRIME-indexes.json             144 indexes summarized per table
├── DOCTOR_PRIME-functions.json           ~50 PL/pgSQL + pgvector listing
├── DAP_TOOLS-tables.json
├── DAP_TOOLS-rowcounts.json
├── DAP4-tables.json
└── DAP4-rowcounts.json
```

## Top 10 P1 tables by live row count

| # | Table | Rows |
|---|-------|------|
| 1 | `crm_leads_externo` | 17,887 |
| 2 | `crm_leads` | 5,911 |
| 3 | `webhook_logs` | 3,979 |
| 4 | `kommo_messages` | 497 |
| 5 | `sofia_actions` | 239 |
| 6 | `anna_inbox` | 141 |
| 7 | `parts_price_sources` | 138 |
| 8 | `compatible_vehicles` | 117 |
| 9 | `kommo_conversations` | 115 |
| 10 | `part_equivalents` | 81 |

## RLS posture (P1)

5 distinct policy families:

1. **`anon_open_legacy`** — open-read/write to **anon** on 14 oficina tables (`clients`, `vehicles`, `ordens_servico`, `colaboradores`, `companies`, etc.). **CRITICAL SECURITY ISSUE for Phase 1**: anon key can read/write everything including `colaboradores.password_hash`. Pre-Cutover requirement: confirm anon key not exposed publicly + plan to lock these down before opening dap-operacao to traffic.
2. **`service_role_only`** — properly locked (ai_*, crm_leads_externo, customer_profiles, enrichment_queue, mecanico_feedback, rag_documents, scrape_checkpoints, sofia_actions).
3. **`tenant_isolation`** — `current_setting('app.current_tenant', true)` (anna_*, kommo_*).
4. **`current_empresa_id()`** — JWT-claim multi-tenant (os_anexos, os_checklists, os_payments).
5. **`auth.uid()` owner** — parts_inventory, parts_price_alerts, parts_search_history.
6. **anon insert-only** — campaign_leads (acceptable for landing page).

## Custom PL/pgSQL functions of interest

- **Auth (legacy bcrypt path)**: `verify_staff_login`, `change_staff_password`, `fn_trocar_senha`, `hash_password`, `criar_usuario_staff` (overloaded), `handle_new_user`, `is_admin`, `auth_empresa_id`, `auth_role`. Direct input to Task #5 (auth decision).
- **Anna pipeline**: `anna_inbox_notify` (NOTIFY trigger), `rpc_anna_inbox_claim_next` (SKIP LOCKED claim).
- **OS triggers**: `before_insert_os`, `after_insert_os`, `fn_06_os_valor_final`, `fn_07_os_itens_calculos/soma_aprovados`, `fn_auto_pendencia_os`, `gerar_numero_os`, `generate_os_number`, `registrar_historico_os`, `registrar_movimentacao_patio`, `ensure_os_token`.
- **RAG**: `match_documentos`, `buscar_diagnosticos_similares` (pgvector).
- **Auto-RLS**: `rls_auto_enable` event trigger — explains why every new table comes up RLS-on (good).
- **Generic SQL**: `exec_sql` (returns void), `execute_readonly_query` (returns jsonb). **VERIFY GRANTS** — must be locked to service_role only.

## Things that look risky or surprising

1. **RLS theatre on legacy oficina tables**: 14 tables have `qual=true, roles={public}` policies on SELECT/INSERT/UPDATE — RLS is technically enabled, effectively wide open to anon. `colaboradores.password_hash` is exposed. **Pre-cutover blocker** for any portal that uses anon key.
2. **`exec_sql` and `execute_readonly_query` functions exist** — high-impact if grants leak to authenticated/anon. Verify with `SELECT proacl FROM pg_proc WHERE proname IN (...)` in Phase 1.
3. **Legacy quoted PK names** (`"04_CLIENTS_pkey"`, `"06_OS_pkey"`, etc.) on 12 tables — schema reflection tools (drizzle-introspect, prisma db pull, supabase gen types) may need `--quoted-identifiers` or post-process. Plan rename in Phase 2.
4. **Two parallel auth systems coexist**:
   - Legacy: `colaboradores.password_hash` + `verify_staff_login()` bcrypt RPC.
   - Supabase Auth: `handle_new_user()` trigger + `auth.uid()` owner RLS on parts_*.
   The dap-operacao migration must choose one (Task #5). Hybrid is acceptable short-term but adds coupling.
5. **`crm_leads_externo` (17,887 rows)** is 3x larger than `crm_leads` (5,911) — confirm whether this is the canonical lake (Manus + scraped + imports) or duplicate. Migration plan must NOT lose this.
6. **Pgvector installed** (halfvec/sparsevec/hnsw/ivfflat). RAG schema migration target needs pgvector enabled too.
7. **DAP4.0 project (cpzgtfblywexqglqkgbt)** has Parliament + os/diagnostics tables but **0 voices, 0 topics, 0 decisions** despite 13 directors + 56 skills + 64 director_skills. Looks like an abandoned/staging Parliament rebuild. Decide: keep, archive, or delete after cutover.
8. **DAP TOOLS** has 4 RLS-disabled tables (Supabase critical advisory): `agente_skills`, `rag_estudos_documentos`, `rag_estudos_chunks`, `rag_ingestao_fila`. Out of P1 scope but worth fixing.

## Recommendation for next Phase 0 step

Before Task #1 closes fully, also capture:
- `pg_settings` snapshot for DOCTOR PRIME (`SELECT name, setting FROM pg_settings WHERE name IN ('shared_buffers','max_connections','statement_timeout', ...)`).
- `pg_extension` list (confirm pgvector, pg_cron if any, pg_net if any).
- Storage buckets list (memory mentions `os-anexos` bucket).
- Foreign keys (`information_schema.table_constraints` WHERE constraint_type='FOREIGN KEY') — needed for Task #4 schema migration.

These should run as **Phase 0b** before Phase 1 cutover work begins.
