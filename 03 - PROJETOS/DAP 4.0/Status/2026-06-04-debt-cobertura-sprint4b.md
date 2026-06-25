---
title: "DÉBITO — cobertura de teste do Sprint 4b (gate 65→62)"
date: 2026-06-04
status: aberto
tipo: tech-debt
prioridade: média
relacionado: "[[2026-06-04-handoff-merge40-camadaA-rotacao-chaves]]"
---

# Débito — cobertura de teste Sprint 4b

## Contexto
O deploy do Sprint 4b (`dap-aios` PR #42, 27 commits) trouxe muitos services/routes
novos com pouca cobertura, derrubando a cobertura global de **65% → 62.1%** (stmts/lines).
Todos os 28 test files **passam**; só o gate de cobertura barrava.

**Decisão Thales (2026-06-04):** shippar com gate baixado pra **62** + este ticket de débito,
em vez de segurar o deploy escrevendo testes agora.

## O que foi feito
`server/vitest.config.ts`: `statements` e `lines` de 65 → **62** (branches 55, functions 65 mantidos).
Comentário de débito inline no arquivo.

## Dívida a pagar (subir de volta pra 65, meta 80/70/80/80)
Services/routes novos sub-testados que puxaram a cobertura (prioridade por impacto):
- `services/dashboardService.ts` (~55%, ~586 linhas) — **maior impacto isolado**
- `services/contentCalendarService.ts` (~11%)
- `services/dap4Client.ts` (novo, ~185 linhas — cliente do gateway shadow proxy)
- `routes/anna-shadow.ts` (~10%) · `routes/marketing.ts` · `routes/pendencias.ts`

Débito pré-existente (não desta branch, já era ~10%): `agentService`, `leadService`,
`ragService`, `conversationService`, routes `leads/quotes/conversations/rag/agents`.

## Débito adicional — atomicidade appointment→OS (Codex P2, PR #42)
`services/appointmentService.ts` (`updateAppointment`): quando o appointment vira
`chegou`, ele é atualizado e o evento registrado **antes** de `createServiceOrder`.
Se o guard de OS duplicada rejeitar (veículo já tem OS aberta), o appointment fica
`chegou` sem OS — estado inconsistente. **Fix:** envolver update + createServiceOrder
numa transação Drizzle. Marcado com comentário `⚠️ DÉBITO` no código.

## Critério de pronto
- [ ] Testes de integração cobrindo `dashboardService` → cobertura ≥65%
- [ ] Reverter `vitest.config.ts` thresholds stmts/lines pra 65
- [ ] CI `Test + coverage` verde com gate 65
- [ ] Transação em `updateAppointment` (atomicidade chegou→OS)
