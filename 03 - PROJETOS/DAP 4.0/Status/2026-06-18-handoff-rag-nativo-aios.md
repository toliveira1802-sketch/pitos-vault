---
type: handoff
date: 2026-06-18
project: DAP 4.0 (dap-aios — RAG nativo)
topic: Pipeline de RAG híbrido nativo no SoR (substitui proxy ChromaDB)
tags: [handoff, claudin, aios, dap-aios, rag, pgvector]
---

# Handoff — RAG nativo (embed/ingest/search híbrido) no dap-aios

## Resumo executivo
Construí o pipeline de RAG **nativo** no dap-aios, sobre `autodiag.knowledge_chunks`
(pgvector HNSW + tsvector PT, fundidos por RRF na função `autodiag.search_knowledge` já em prod).
Substitui o proxy ChromaDB do dap4. Embedding OpenAI `text-embedding-3-large @ 1024` (ADR-0002),
via `fetch` (sem adicionar SDK). Wirado nas rotas **opt-in** (`USE_AIOS_RAG`, default off).
Tudo passa: ESLint 0, tsc (server) 0, 9/9 testes unitários.

## O que funcionou (com evidência)
- **`server/src/services/rag/knowledge.ts`**:
  - `embedTexts()` — OpenAI 3-large@1024, batches de 256, ordena por index, fail-fast sem key.
  - `chunkText()` — sentence-aware (~2000 chars / overlap 200), normaliza whitespace.
  - `ingestKnowledge()` — embedda + insere em `autodiag.knowledge_chunks` (raw `sql` qualificado; `content_tsv` é gerado pelo banco).
  - `searchKnowledge()` — embedda a query + chama `autodiag.search_knowledge` (RRF híbrido).
  - `isAiosRagEnabled()` + `DEFAULT_KNOWLEDGE_TENANT`.
- **Rotas** (`server/src/routes/rag.ts`, opt-in via `USE_AIOS_RAG`):
  - `POST /api/rag/query` — branch nativo (`engine:'aios'`) com prioridade sobre o proxy dap4.
  - `POST /api/rag/knowledge` — ingestão nativa de texto (chunk → embed → insert).
- **Teste** `server/test/unit/rag-knowledge.test.ts` (9 casos): chunker, literal pgvector, embed (mock fetch — model/dimensions/ordem/erro HTTP/fail-fast). **9/9 verde.**
- **Gates:** ESLint 0 warnings, `tsc -p server` EXIT=0, vitest EXIT=0.
- **`.env.example`** documentado: `USE_AIOS_RAG`, `OPENAI_API_KEY`.

## Decisões
- **Sem SDK OpenAI** — REST via `fetch` global (Node 18+). Menos dependência, menos superfície.
- **`autodiag.knowledge_chunks` via `sql` cru qualificado** (não é tabela Drizzle; vive no schema autodiag). Qualificação `autodiag.`/`extensions.` resolve independente do search_path (importa em testes).
- **Opt-in** — nada muda em runtime até `USE_AIOS_RAG=true`; o proxy dap4 segue como fallback.

## O que NÃO foi feito (próximos passos)
1. **Backfill do corpus** (#4b/4a): ingerir o conhecimento do Thales (vault Obsidian/SOPs) e/ou
   re-embeddar o ChromaDB legado (1536→1024) via `POST /api/rag/knowledge` ou um script de ingestão.
   Precisa `OPENAI_API_KEY` no `.env` do dap-aios.
2. **Teste de integração** contra `autodiag` live (pulado — precisa DB + key; o schema de teste é mirror de public, não tem autodiag).
3. **Virar a flag** `USE_AIOS_RAG=true` após backfill + validação; depois aposentar o proxy dap4.
4. **Referência** (4c): copiar 5 DTCs / 15 marcas / 78 modelos do DAP4.0 pro `autodiag.*` (trivial, sem embedding).

## Arquivos
| Arquivo | Mudança |
|---|---|
| `server/src/services/rag/knowledge.ts` (novo) | embed/chunk/ingest/search híbrido nativo |
| `server/src/routes/rag.ts` | branch nativo no /query + POST /knowledge (opt-in) |
| `server/test/unit/rag-knowledge.test.ts` (novo) | 9 testes unitários |
| `.env.example` | USE_AIOS_RAG + OPENAI_API_KEY |
