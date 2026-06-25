---
title: Handoff — Débito §7.6 (cobertura dashboardService + transação updateAppointment)
date: 2026-06-04
status: concluído (não pushado — aguarda OK do Thales)
scope: dap-aios · Portal Consultor/Gestão · débito de teste do Sprint 4b (gate 62→65) + atomicidade do updateAppointment
branch: feat/consultor-sprint4b-test-debt
commits: 9592044 (test cobertura) · 7ce5777 (fix transação + gate)
relacionado: "[[2026-06-04-handoff-deploy-sprint4b-anna-hotfix-recepcao]]"
---

# Handoff — 2026-06-04 (sessão 4) · Débito de cobertura Sprint 4b §7.6

> Continuação do handoff `2026-06-04-handoff-deploy-sprint4b-anna-hotfix-recepcao`,
> pendência **§7.6** (única aberta dentro da fronteira "módulos Consultor existentes" —
> sem tocar em demanda/`agente_demandas`/recepção Anna, território de outra sessão).

## 1. Resumo executivo

1. **Cobertura `dashboardService`** — novo arquivo `dashboardService.comercial.test.ts` (20 testes,
   todos verdes) cobrindo as agregações comerciais sub-testadas que derrubaram o gate no Sprint 4b:
   `getResumoComercial` (completo: leads/taxas/receita/SLA/propostas), `getFunilComercial`,
   `getPerformanceConsultor`, `getPropostasAbertas`, `getCanaisOrigem`, `getMotivosPerda`,
   `getForecast` (week+month), `getAlertasComerciais` (5 tipos + ordenação).
2. **Atomicidade do `updateAppointment`** — resolvido o débito não-atômico (linha 218 do
   `appointmentService`): `update(appointment) + recordEvent + createServiceOrder` agora rodam
   numa **transação Drizzle**. Se a criação da OS falhar (ex.: guard `VEHICLE_HAS_OPEN_ORDER`),
   faz rollback e o appointment **não** fica 'chegou' sem OS. Teste de regressão verde.
3. **Gate de cobertura** — threshold `statements/lines` restaurado 62 → **65** em
   `server/vitest.config.ts`. **Run completo confirmado**: 343 testes verdes, cobertura global
   **67.32% stmts / 82.57% branch / 72.54% funcs / 67.32% lines** (~2.3% de headroom sobre o gate).

## 2. Arquivos alterados

**Cobertura (commit 1):**
- `server/test/integration/dashboardService.comercial.test.ts` (novo, 20 testes).

**Atomicidade + gate (commit 2):**
- `server/src/db/client.ts` — exporta `DbExecutor`/`AiosTx` (conexão raiz OU transação).
- `server/src/services/eventService.ts` — `recordEvent(input, executor = db)`.
- `server/src/lib/osCode.ts` — `computeNextOsCode(year, executor = db)` + `insertWithSequentialOsCode({ executor })`.
- `server/src/services/serviceOrderService.ts` — `createServiceOrder(actor, rawInput, executor = db)`,
  propaga executor pra todas as queries/insert/evento.
- `server/src/services/appointmentService.ts` — `updateAppointment` envolto em `db.transaction`.
- `server/test/integration/appointments.test.ts` — +1 teste de regressão (rollback §7.6).
- `server/vitest.config.ts` — threshold 62 → 65.

Padrão: **executor opcional backward-compatible** (default = `db` raiz). Zero impacto nos
callers existentes de `recordEvent`/`createServiceOrder`; só o `updateAppointment` passa o `tx`.

## 3. Decisões / nuances

- **Retry de código de OS dentro de tx**: um `INSERT` com unique-violation (23505) aborta a
  transação Postgres (25P02), então o retry do `insertWithSequentialOsCode` fica degradado
  *dentro* da tx do `updateAppointment`. Aceitável: o caso real (`VEHICLE_HAS_OPEN_ORDER`) é
  tratado atomicamente; uma colisão de código de OS (já "rara" por design) agora **falha-seguro**
  (rollback + 500, usuário re-tenta) em vez de deixar estado parcial. Líquido: melhor que antes.
- **`VEHICLE_HAS_OPEN_ORDER` → HTTP 500**: a rota PATCH de appointments não mapeia esse erro de
  domínio pra 409 (cai no `sendError` genérico → 500). Fora do escopo §7.6 (mapeamento de rota);
  candidato a polish futuro. A atomicidade — objetivo do §7.6 — está garantida.

## 4. Como rodar / verificar (dentro de `dap-aios/`)

```bash
# pnpm fora do PATH nesta máquina → usar caminho ou corepack
$env:PATH = "C:\Users\docto\AppData\Roaming\npm;$env:PATH"

pnpm --filter @aios/server test:db:setup    # (re)cria schema `test` no Supabase DEV (hlhf)
pnpm check                                   # typecheck — VERDE
pnpm lint                                    # 0 errors (15 warnings pré-existentes de `any`)
pnpm --filter @aios/server exec vitest run test/integration/dashboardService.comercial.test.ts  # 20/20
pnpm --filter @aios/server exec vitest run test/integration/appointments.test.ts                # 10/10
```

⚠️ **Ambiente de teste**: `.env` DATABASE_URL aponta pro Supabase DEV `hlhf` schema `test`
(search_path isolado; `wipeAll` trava em `current_schema='test'`). Suite completa contra o
remoto sa-east-1 leva **~80 min** (idle_timeout 2s derruba conexão a cada query → reconexão TLS
pro Brasil; ECONNRESET ocasional). CI roda contra Postgres local (rápido/confiável) — é o gate real.

## 5. Pendências / próxima rodada

1. **Push + PR** — branch `feat/consultor-sprint4b-test-debt` tem 2 commits, **NÃO pushado**
   (aguarda OK do Thales). CI (Postgres local) valida o gate 65 no PR.
2. (Backlog herdado §7 do handoff anterior — fora de escopo desta rodada): RLS no `hlhf`,
   learning loop Anna, ADR Kommo-out, Bote, wiring Recepção, db:push host VPS, limpar backups.

## 6. Paralelizável
- Nada crítico. Mapeamento `VEHICLE_HAS_OPEN_ORDER → 409` na rota é um spec pequeno independente.
