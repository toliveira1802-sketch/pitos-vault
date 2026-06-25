---
type: handoff-mestre
date: 2026-06-18
project: DAP 4.0 (consolidação Supabase + AIOS write-owner + RAG nativo)
topic: Sessão completa — consolidar bancos no AIOS, mover AutoDiag, write-owner B, RAG híbrido nativo
tags: [handoff, mestre, claudin, aios, dap-aios, supabase, rag, retomada]
---

# HANDOFF MESTRE — Sessão de Consolidação AIOS (2026-06-18)

> **Ponto único de retomada.** Esta sessão foi longa e tocou produção várias vezes (sempre
> validado). Lê este arquivo pra ter o estado completo. Handoffs parciais da sessão (mesma data)
> detalham cada fatia: `go-branch-smoke`, `autodiag-lift-shift`, `cutover-consolidacao`,
> `write-owner-B-leads-enriquecido`, `rag-nativo-aios`.

---

## 0. Mapa rápido (o que está vivo agora)

- **SoR = Supabase DAP AIOS** `hlhfqnhsvwxodtwdkkhf` (sa-east-1). Produção do consultor intacta
  (customers 418 · vehicles 546 · service_orders 659 · events 1616 — inalterados o tempo todo).
- **Consolidação aplicada em prod.** Topologia final por schemas (abaixo).
- **Write-owner = dap-aios** (`C:\THALES\DAP4.0\dap-aios`). dap4 (`C:\dev\dap4`) vira feeder.
- **RAG nativo híbrido construído** (opt-in `USE_AIOS_RAG`), corpus ainda vazio.
- **AutoDiag Copilot** movido pro AIOS (schema `ferramentas`); faltam 3 valores de `.env` do Thales.

---

## 1. Migrations aplicadas no AIOS prod (em ordem, todas success)

| # | Nome | O que fez |
|---|------|-----------|
| — | `enable_pgvector_extension` | (sessão anterior) pgvector no schema extensions |
| 0000–0005 | `ferramentas_*` | **AutoDiag Copilot** lift-and-shift: schema `ferramentas` (6 tabelas, RLS, uuidv7, trigger auth.users, 10 profiles backfill) |
| 002 | `reconcile_drift_content_appointments` | registrou content_items+appointments no migration history (eram drift Drizzle) |
| 001 | `fundacao_schemas_indices` | 5 schemas + 18 FK-indexes no core |
| 010 | `schema_crm` | aquisicao/posvenda/conversas (depois reconciliado) |
| 011 | `schema_conhecimento` | autodiag + catalogo (11 tabelas) + knowledge_chunks hybrid |
| 012 | `rag_hybrid_search` | função search_knowledge (RRF) |
| 013 | `reconcile_leads_into_public` | **Reconciliação B**: dropou aquisicao.leads + conversas.conversations/messages; enriqueceu public.leads (+20 cols) + criou public.lead_interacoes; repontou 4 FKs pro public |
| 014 | `knowledge_to_conhecimento_schema_domain` | moveu knowledge_chunks + search_knowledge `autodiag`→`conhecimento`; +coluna `domain` + filtro |

> SQLs salvos em `C:\THALES\DAP4.0\docs\migrations\` (000–014 + CUTOVER-runbook.md).
> Os mesmos estão no migration history do Supabase (apply_migration).

## 2. Topologia final do AIOS (schemas)

- **public** (core, dap-aios): customers · vehicles · **leads (ENRIQUECIDO)** · **lead_interacoes (novo)** ·
  conversations · messages · quotes/quote_items · service_orders/items · appointments · events ·
  users/roles/permissions · agentes/agente_demandas · calculators/calculator_runs · content_items ·
  rag_documentos/rag_chunks · finance (suppliers/purchase_orders/invoices/bills/dre_*) · **ferramentas drift OK**
- **ferramentas** (AutoDiag Copilot, per-user SaaS): profiles · vehicles · diagnostics · diagnostic_dtcs · dtc_dictionary · sync_log
- **conhecimento** (RAG geral): **knowledge_chunks** (pgvector 1024 + tsvector PT + `domain`) + função `search_knowledge`
- **autodiag** (técnico): dtc_dictionary · diagnostics · vehicle_makes · vehicle_models
- **catalogo** (peças): parts · part_equivalents · compatible_vehicles · price_records · price_sources · inventory
- **posvenda** (pós-venda): recurrences · promotions · promotion_targets (FKs → public.leads/customers)
- **conversas** (Anna shadow): anna_observations (FKs → public.leads/conversations)

## 3. Decisões (com razão)

- **ADR-0001** stack = Supabase/Postgres; AIOS = SoR único.
- **ADR-0002** embedding = OpenAI `text-embedding-3-large @ 1024` (denominador-comum, já tem key, troca = re-embed sem mudar schema). RAG **híbrido** (semântico HNSW + lexical GIN PT, RRF).
- **Write-owner = dap-aios (B)** — mapa (`docs/plans/MAPA-write-points-e-rag.md`) provou que dap-aios já é o dono (46 pts event-sourced); dap4 é legado-feeder.
- **Leads ficam no public, enriquecidos** (NÃO movidos pra aquisicao) — preserva fiação (quotes↔leads, conversations↔leads, services, UI, testes). `aquisicao` schema dropado.
- **RAG geral em schema `conhecimento`** (não autodiag), com `domain` (comercial/empresa/tecnico). Corpus é comercial-primeiro (métodos de venda + sobre a empresa), técnico vem depois.
- **AutoDiag = lift-and-shift** (schema `ferramentas` intacto), NÃO re-plataformado — preserva o modelo SaaS-ready per-user pro spin-out futuro.

## 4. Código alterado (dap-aios) — typecheck/eslint/test VERDE

| Arquivo | Mudança |
|---|---|
| `packages/types/src/schema/consultor.ts` | leads +20 colunas (utm/scoring/anna/meta) + tabela `leadInteracoes` + relations + Zod + types |
| `server/src/services/rag/knowledge.ts` (novo) | RAG nativo: embedTexts (3-large@1024 via fetch) · chunkText · ingestKnowledge · searchKnowledge (domain filter) · flags |
| `server/src/routes/rag.ts` | branch nativo no /query (engine:'aios') + POST /knowledge (ingestão) — opt-in USE_AIOS_RAG, com domain |
| `server/test/unit/rag-knowledge.test.ts` (novo) | 9 testes (chunker, vetor, embed mock) — verdes |
| `.env.example` | USE_AIOS_RAG + OPENAI_API_KEY documentados |

> Gates rodados via PowerShell (pnpm não está no PATH do bash; usar `node_modules\.bin\tsc.cmd`,
> `eslint.cmd`, `server\node_modules\.bin\vitest.cmd`). NÃO commitado ainda — working tree.

## 5. PRÓXIMOS PASSOS (priorizados)

1. **[próximo combinado] Ingestor `.md` — Fase 1 do RAG.** Lê pasta do `C:\THALES\PITOS`, chunk por
   heading, embed (3-large@1024), grava em `conhecimento.knowledge_chunks` com `domain`,
   idempotente (dedup sha256). Rodável por comando com `OPENAI_API_KEY` no `.env` do dap-aios.
   → Thales vai popular o vault com métodos de venda + conhecimento da empresa.
2. **Backfill + virar `USE_AIOS_RAG=true`** após validar busca com corpus real; aposentar proxy dap4.
3. **Fase 2/3 ingestão:** PDF texto (`pdf-parse`); planilhas → roteador (DTC/peças → tabelas estruturadas; prosa → RAG).
4. **Services (#2 incremental):** popular os campos novos de leads (utm/scoring/anna_status) + gravar lead_interacoes — dirigido pela feature de scoring da Anna (schema já pronto).
5. **Hardening:** RLS nos schemas novos (conhecimento/autodiag/catalogo/posvenda/conversas — hoje sem policy); atualizar "32 tabelas" no dap-aios CLAUDE.md.
6. **Commit** das mudanças do dap-aios (working tree) com conventional commits.

## 6. PENDÊNCIAS DO THALES (ações manuais)

- 🔴 **AutoDiag `.env.local`** (`C:\THALES\DAP4.0\autodiag-copilot\.env.local`) — JÁ repontado pro AIOS
  (URL+anon+service_role+DATABASE_URL corrigidos pra session pooler `aws-1-sa-east-1:5432`).
  Validar com `pnpm dev`. (Resolvido na sessão; conferir se conecta.)
- **Backup + deletar projeto TOOLS** (`mtrmtkvhgrzhwhhfffhj`) no painel Supabase.
- **Popular o vault** com `.md` de métodos de venda + sobre a empresa (pra rodar o ingestor Fase 1).
- (Opcional) rotacionar OpenAI/Anthropic keys do autodiag — precaução, não urgente.

## 7. Refs

- Migrations/decisões/plano: `C:\THALES\DAP4.0\docs\` (migrations/ · decisions/ · plans/).
- Projetos Supabase: AIOS `hlhfqnhsvwxodtwdkkhf` (fica) · PRIME `acuufrgoyjwzlyhopaus` · TOOLS `mtrmtkvhgrzhwhhfffhj` (derrubar) · DAP4.0 `cpzgtfblywexqglqkgbt` (aposentar; autodiag já saiu).
- Memórias atualizadas: `aios-drift-migration-history`, `autodiag-movido-aios`, `stack-banco-supabase`.
