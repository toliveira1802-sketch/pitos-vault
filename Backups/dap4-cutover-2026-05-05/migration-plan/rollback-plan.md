# Rollback Plan: dap-operacao Postgres Cutover
**Date:** 2026-05-05

## Trigger Conditions

Roll back if any of the following occur within 24h of production cutover:
- 117 vitest tests not all green on Supabase local after migration
- Login fails (session store broken)
- OS creation produces 500 error
- Data visible in wrong tenant (RLS/WHERE bug)
- p95 response time doubles vs SQLite baseline

## Assets to Preserve

Before cutting to Postgres:
1. Keep oficina.db on disk (do not delete until stability confirmed >= 7 days)
2. Create branch: git checkout -b feat/postgres-migration
3. Tag the last SQLite-clean commit: git tag v1-sqlite-last
4. Export SQLite snapshot: cp oficina.db ../oficina-backup-20260505.db

## Rollback Steps

1. Stop the server process
   pm2 stop dap-operacao (or equivalent)

2. Checkout the SQLite branch
   git checkout main  (or v1-sqlite-last tag)

3. Restore env vars
   .env: DATABASE_URL=file:./oficina.db

4. Verify oficina.db exists and is intact
   sqlite3 oficina.db .tables

5. Restart server
   pm2 start dap-operacao

6. Smoke test: login, open OS list, check one OS detail

7. If data was written to Postgres during the cutover window:
   - Run reverse ETL: pg -> sqlite for any new rows created after cutover
   - This is manual and requires the pg connection string to still be valid
   - Priority tables: service_orders, payments, telemetry, service_order_comments

## Preventing Data Loss

The key risk is data created in Postgres that does not exist in SQLite.

Mitigation:
- Minimize the cutover window: do the switch at off-peak hours (Sunday night)
- If possible, put the app in read-only mode during ETL (disable writes)
- After cutover, wait 1h with monitoring before considering SQLite decommissioned

## Decision Gate

| Check | Pass | Fail Action |
|---|---|---|
| 117 vitest tests green on local Supabase | Continue | Fix before cutover |
| Staging smoke pass | Continue | Fix before cutover |
| Production login works | Continue | Rollback immediately |
| OS create works | Continue | Rollback immediately |
| 24h no errors in logs | Decommission SQLite | Investigate + rollback |

## Post-Rollback

- Document the failure mode in PITOS/Backups/dap4-cutover-2026-05-05/rollback-notes.md
- Triage the specific risk that triggered rollback
- Fix + retry cutover with updated migration-plan.md