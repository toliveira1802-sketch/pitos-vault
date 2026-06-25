# Phase 1a Hardening — DOCTOR PRIME (acuufrgoyjwzlyhopaus)

**Aplicado:** 2026-05-05
**Escopo:** fechar 2 vetores críticos antes de cutover dap-operacao → Supabase

## 1. RCE / data leak via SECURITY DEFINER funcs

**Antes:**
- `public.exec_sql(text)` — SECURITY DEFINER, EXECUTE granted a `anon, authenticated, public, service_role`
- `public.execute_readonly_query(text)` — idem
- Qualquer um com a anon key (publicada no frontend) podia executar SQL arbitrário no servidor com privilégio do owner.

**Depois (`01_revoke_dangerous_funcs.sql`):**
```
exec_sql.proacl                = {postgres=X/postgres, service_role=X/postgres}
execute_readonly_query.proacl  = {postgres=X/postgres, service_role=X/postgres}
```

## 2. RLS theatre nas 14 tabelas oficina

**Antes:** 43 policies com `qual=true, roles={public}` em:
agendamentos, clients, colaboradores, companies, mecanicos, oficina_config,
ordens_servico, ordens_servico_historico, ordens_servico_itens, pecas_encontradas,
pendencias, recursos, recusas, vehicles.

Inclui `colaboradores.password_hash` legível por anon. RLS estava habilitado mas a policy era `true` pra `public` — RLS theatre.

**Depois (`02a_*` + `02b_*`):** 0 policies anon abertas restantes nessas 14 tabelas. RLS continua habilitado, então anon e authenticated não enxergam nada (verificado: `SET LOCAL ROLE anon; SELECT count(*) FROM colaboradores → 0`).

`service_role` (`rolbypassrls=true`) continua com acesso total — Anna, Sofia, Kommo sync e qualquer cliente usando service key seguem funcionando sem mudança.

## Quem pode quebrar

Se algum cliente em produção estava usando a **anon key** contra essas tabelas, vai parar de funcionar. Suspeitos:
1. Dashboard legacy de `C:\dev\dap4` — provável; mas Thales decidiu matar esse stack mesmo
2. Algum portal que apontou pra DOCTOR PRIME via anon — verificar `.env` da VPS e qualquer Vercel deploy

**Plano de mitigação:** se algo quebrar, rollback é trivial — basta recriar as policies do snapshot em `DOCTOR_PRIME-rls-policies.json`. Mas o caminho recomendado é apontar o cliente afetado pra service_role (server-side) ou criar policy adequada (auth.uid / current_empresa_id).

## Verificações finais

```sql
-- Confirma 0 policies abertas restantes
SELECT count(*) FROM pg_policies
WHERE schemaname='public'
  AND 'public' = ANY(roles)
  AND tablename IN (...14 tabelas...);
-- → 0 ✓

-- Confirma anon não enxerga
BEGIN; SET LOCAL ROLE anon;
SELECT count(*) FROM colaboradores; -- 0 ✓
ROLLBACK;
```

## Pendente da Fase 1a (não crítico)

- VPS: investigar `mysql.service` em :3306 e listeners `python3` em :9443/:9444 (origem desconhecida)
- DAP TOOLS project: 4 tabelas com RLS desabilitado (out of P1 scope, advisar Thales antes de mexer)
- Quoted legacy PK names (`"04_CLIENTS_pkey"`...) — cosmético, agendar pra Phase 2
