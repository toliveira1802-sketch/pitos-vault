-- Applied: 2026-05-05
-- Project: DOCTOR PRIME (acuufrgoyjwzlyhopaus)
-- Reason: exec_sql() and execute_readonly_query() are SECURITY DEFINER functions
--         and were granted EXECUTE to anon + authenticated. This is RCE/data leak
--         via Supabase API. Lock to service_role only.

REVOKE EXECUTE ON FUNCTION public.exec_sql(sql_query text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.execute_readonly_query(query_text text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.exec_sql(sql_query text) TO service_role;
GRANT EXECUTE ON FUNCTION public.execute_readonly_query(query_text text) TO service_role;

-- Verified: pg_proc.proacl = {postgres=X/postgres,service_role=X/postgres}
