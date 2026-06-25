-- Applied: 2026-05-05
-- Project: DOCTOR PRIME (acuufrgoyjwzlyhopaus)
-- Part 2/2: ordens_servico_historico, ordens_servico_itens, pecas_encontradas,
--           pendencias, recursos, recusas, vehicles

DROP POLICY IF EXISTS "anon_read_08_OS_HISTORICO" ON public.ordens_servico_historico;
DROP POLICY IF EXISTS "anon_update_08_OS_HISTORICO" ON public.ordens_servico_historico;
DROP POLICY IF EXISTS "anon_write_08_OS_HISTORICO" ON public.ordens_servico_historico;
DROP POLICY IF EXISTS "anon_read_07_OS_ITENS" ON public.ordens_servico_itens;
DROP POLICY IF EXISTS "anon_update_07_OS_ITENS" ON public.ordens_servico_itens;
DROP POLICY IF EXISTS "anon_write_07_OS_ITENS" ON public.ordens_servico_itens;
DROP POLICY IF EXISTS "Acesso publico atualizar" ON public.pecas_encontradas;
DROP POLICY IF EXISTS "Acesso publico deletar" ON public.pecas_encontradas;
DROP POLICY IF EXISTS "Acesso publico inserir" ON public.pecas_encontradas;
DROP POLICY IF EXISTS "Acesso publico leitura" ON public.pecas_encontradas;
DROP POLICY IF EXISTS "anon_read_13_PENDENCIAS" ON public.pendencias;
DROP POLICY IF EXISTS "anon_update_13_PENDENCIAS" ON public.pendencias;
DROP POLICY IF EXISTS "anon_write_13_PENDENCIAS" ON public.pendencias;
DROP POLICY IF EXISTS "anon_read_14_RECURSOS" ON public.recursos;
DROP POLICY IF EXISTS "anon_update_14_RECURSOS" ON public.recursos;
DROP POLICY IF EXISTS "anon_write_14_RECURSOS" ON public.recursos;
DROP POLICY IF EXISTS "anon_read_97_RECUSAS" ON public.recusas;
DROP POLICY IF EXISTS "anon_update_97_RECUSAS" ON public.recusas;
DROP POLICY IF EXISTS "anon_write_97_RECUSAS" ON public.recusas;
DROP POLICY IF EXISTS "anon_read_05_VEHICLES" ON public.vehicles;
DROP POLICY IF EXISTS "anon_update_05_VEHICLES" ON public.vehicles;
DROP POLICY IF EXISTS "anon_write_05_VEHICLES" ON public.vehicles;
