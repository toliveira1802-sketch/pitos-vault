-- Applied: 2026-05-05
-- Project: DOCTOR PRIME (acuufrgoyjwzlyhopaus)
-- Reason: 14 oficina tables had `qual=true, roles={public}` policies — anon could
--         read/write everything including colaboradores.password_hash. service_role
--         bypasses RLS (rolbypassrls=true), so dropping these does not affect Anna,
--         agents, or any service_role client. Anon and authenticated lose access.
-- Part 1/2: agendamentos, clients, colaboradores, companies, mecanicos,
--           oficina_config, ordens_servico

DROP POLICY IF EXISTS "anon_read_15_AGENDAMENTOS" ON public.agendamentos;
DROP POLICY IF EXISTS "anon_update_15_AGENDAMENTOS" ON public.agendamentos;
DROP POLICY IF EXISTS "anon_write_15_AGENDAMENTOS" ON public.agendamentos;
DROP POLICY IF EXISTS "anon_read_04_CLIENTS" ON public.clients;
DROP POLICY IF EXISTS "anon_update_04_CLIENTS" ON public.clients;
DROP POLICY IF EXISTS "anon_write_04_CLIENTS" ON public.clients;
DROP POLICY IF EXISTS "anon_read_01_colaboradores" ON public.colaboradores;
DROP POLICY IF EXISTS "anon_update_01_colaboradores" ON public.colaboradores;
DROP POLICY IF EXISTS "anon_write_01_colaboradores" ON public.colaboradores;
DROP POLICY IF EXISTS "anon_read_00_companies" ON public.companies;
DROP POLICY IF EXISTS "anon_update_00_companies" ON public.companies;
DROP POLICY IF EXISTS "anon_write_00_companies" ON public.companies;
DROP POLICY IF EXISTS "anon_read_12_MECANICOS" ON public.mecanicos;
DROP POLICY IF EXISTS "anon_update_12_MECANICOS" ON public.mecanicos;
DROP POLICY IF EXISTS "anon_write_12_MECANICOS" ON public.mecanicos;
DROP POLICY IF EXISTS "anon_read_oficina_config" ON public.oficina_config;
DROP POLICY IF EXISTS "anon_update_oficina_config" ON public.oficina_config;
DROP POLICY IF EXISTS "anon_write_oficina_config" ON public.oficina_config;
DROP POLICY IF EXISTS "anon_read_06_OS" ON public.ordens_servico;
DROP POLICY IF EXISTS "anon_update_06_OS" ON public.ordens_servico;
DROP POLICY IF EXISTS "anon_write_06_OS" ON public.ordens_servico;
