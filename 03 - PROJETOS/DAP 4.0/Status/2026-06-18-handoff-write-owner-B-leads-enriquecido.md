---
type: handoff
date: 2026-06-18
project: DAP 4.0 (consolidação Supabase)
topic: Write-owner B (dap-aios) + fatia 1 — leads enriquecido no public
tags: [handoff, claudin, aios, dap-aios, drizzle, leads]
---

# Handoff — Write-owner B + leads enriquecido (reconciliação)

## Resumo executivo
Decidimos o **write-owner do AIOS = dap-aios (Opção B)**, baseado num mapa real dos write-points.
O mapa revelou que o dap-aios **já é** o dono da escrita (46 pontos, event-sourced) e que os
schemas `aquisicao.leads` + `conversas.conversations/messages` criados no cutover **duplicavam**
tabelas limpas e fiadas do `public`. Decisão **B (Thales)**: enriquecer `public.leads` no lugar,
dropar os duplicados, manter os schemas novos de verdade. Aplicado em prod + schema Drizzle
sincronizado + typecheck verde. **Aditivo, nada quebrou.**

## O que funcionou (com evidência)
- **Mapa dos write-points** (2 exploradores paralelos): `docs/plans/MAPA-write-points-e-rag.md`.
  dap-aios = 46 pts em `services/*` (event-sourced); dap4 = ~52 pts num modelo legado + ChromaDB.
  Ponte `annaEventStore.ts` já liga dap4→AIOS.
- **Decisão de embedding**: `ADR-0002` — OpenAI 3-large@1024 (RAG híbrido confirmado).
- **Reconciliação B (migration 013, prod):** guard (aborta se duplicado não-vazio) → repontou 4
  FKs (posvenda + anna_observations) pro `public.leads`/`public.conversations` → dropou
  `aquisicao.leads`/`lead_interacoes` (+schema aquisicao) e `conversas.conversations`/`messages` →
  enriqueceu `public.leads` (+20 colunas: utm_*, channel, campaign, scoring Anna, kommo, jsonb) →
  criou `public.lead_interacoes` (RLS on). Verificado: aquisicao sumiu, conversas só
  anna_observations, leads 37 colunas, FKs no public, posvenda/autodiag/catalogo intactos, 0 dados perdidos.
- **Schema Drizzle sincronizado** (`packages/types/src/schema/consultor.ts`): colunas novas em
  `leads` + tabela `leadInteracoes` + relations + Zod + types. **typecheck @aios/types + server: EXIT=0.**

## Decisões
- **Write-owner = dap-aios (B).** dap4 fica como feeder (Anna/Kommo/WhatsApp via annaEventStore) e
  terá o RAG (ChromaDB) substituído pelo `autodiag.knowledge_chunks` nativo.
- **leads/conversas ficam no public** (enriquecidos), NÃO movidos pra aquisicao/conversas — preserva
  fiação (quotes↔leads, conversations↔leads, services, UI, testes). `aquisicao` dropado.
- **Mantidos** (genuinamente novos): `posvenda.*`, `autodiag.*`, `catalogo.*`, `conversas.anna_observations`.

## Arquivos
| Arquivo | Mudança |
|---|---|
| `docs/migrations/013-reconcile-leads-into-public.sql` | migration de reconciliação (aplicada em prod) |
| `packages/types/src/schema/consultor.ts` (dap-aios) | leads +20 colunas, `leadInteracoes` table+relations+zod+types |
| `docs/plans/MAPA-write-points-e-rag.md` | mapa dos write-points + design do RAG nativo |
| `docs/decisions/ADR-0002-embedding-model.md` | embedding 3-large@1024 |

## Próximos passos
1. **RAG nativo (#4)** no dap-aios: `embed()` (3-large@1024) + `ingest()` → `autodiag.knowledge_chunks`
   + `searchKnowledge()` (RRF, já em prod) substituindo o proxy `dap4Client`. Backfill do ChromaDB + vault.
2. **Services (#2, incremental):** estender `leadService`/`annaEventStore` pra popular os campos novos
   (utm/scoring/anna_status) e gravar `lead_interacoes` — dirigido pela feature de scoring da Anna. (Schema já pronto.)
3. **Doc:** dap-aios CLAUDE.md diz "32 tabelas" — agora há +lead_interacoes e os schemas novos; atualizar contagem + RLS dos schemas novos (posvenda/autodiag/catalogo sem RLS ainda — hardening).
4. **RLS dos schemas novos** (posvenda/autodiag/catalogo) — migration dedicada (default-deny como o resto).

## Pendências independentes (do Thales)
- AutoDiag: `.env.local` já no AIOS; rodar `pnpm dev` e validar.
- Backup + deletar TOOLS no painel.
