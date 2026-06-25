---
type: handoff
date: 2026-06-18
time: 02:46
project: DAP 4.0 (consolidação Supabase)
topic: Consolidar 4 bancos Supabase fragmentados num único System of Record (AIOS)
tags: [handoff, claudin]
---

# Handoff — Consolidação dos 4 bancos Supabase no AIOS

## Contexto
O ecossistema DAP tinha **4 projetos Supabase fragmentados** (DOCTOR PRIME, DAP AIOS, DAP TOOLS, DAP4.0) com modelagem duplicada da mesma coisa (`ordens_servico`/`clientes`/`veiculos` em vários), dado espalhado e buracos de segurança. A sessão começou querendo estruturar 2 unidades de negócio (RAFAEL/COO e FRANCISCO/CFO) mas pivotou pra **arrumar a fundação primeiro**: definir a stack, consolidar os 4 bancos num único System of Record e preparar a execução sem quebrar a produção viva (Anna/Kommo/webhooks). Resultado: topologia limpa decidida e migrations escritas. **Nada foi aplicado em produção** — tudo é design + migrations testáveis em branch. RAFAEL/FRANCISCO ficaram parados de propósito (construir depois da casa limpa).

## O que funcionou (com evidência)
- **Auditoria dos 4 projetos** via Supabase MCP — evidência: `docs/audit/2026-06-17-saneamento-supabase.md` (148 lints no PRIME parseados, schemas comparados).
- **pgvector habilitado no AIOS** — evidência: `apply_migration` `success:true` + `SELECT` confirmou `vector 0.8.0` no schema `extensions`. **Única coisa aplicada em produção nesta sessão** (decisão #3, GO explícito do Thales).
- **3 agentes paralelos** (investigação + modelagem) — evidência: `docs/audit/gravadores-prime.md`, `docs/migrations/proposta-crm.sql`, `proposta-autodiag-catalogo.sql`, `impacto-uuid.md`.
- **Migrations definitivas escritas** (000–012) em `docs/migrations/`, todas coerentes com as decisões.
- **Hybrid RAG** modelado: `knowledge_chunks` com `embedding vector(1024)` (HNSW) + `content_tsv` (full-text PT, GIN) + função `autodiag.search_knowledge()` com RRF (`012`).

## O que NÃO funcionou (e por quê)
- **Pausar o TOOLS via MCP** — falhou: `"Project is not free-tier. Please downgrade it to free-tier first."` TOOLS é Pro; pausar exige downgrade pra free antes, e o MCP não expõe delete. → **Delete tem que ser no painel.**
- **`list_tables verbose` / `get_advisors` do PRIME** estouraram o limite de token do MCP → output salvo em arquivo, parseado via PowerShell (`ConvertFrom-Json`). Workaround, não bug.
- **Premissa inicial errada (minha):** pintei `customers.id text` como gambiarra. O agente provou que é **nanoid consistente** (`newId()` do Drizzle, `packages/types/src/ids.ts`). → Decisão de migrar pra uuid foi **REVERTIDA** (mantém nanoid).

## O que ainda não foi tentado
- **Testar a sequência `001→010→011→012` numa branch do AIOS** (create_branch → apply → smoke → merge). É o próximo passo, aguarda GO.
- **Repontar as integrações vivas** do PRIME pro AIOS (Fase 4 do plano) — descoberto que é só trocar `.env` da VPS (ref não está hardcoded).
- **Atualizar o código** (gateway/agents, ~50 pontos de escrita) pros schemas/nomes novos (decisão 1a, modelo limpo).

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `docs/decisions/ADR-0001-database-stack.md` | Completo | Decisão de stack + topologia (5+ schemas) + regra lead/cliente |
| `docs/audit/2026-06-17-saneamento-supabase.md` | Completo | Dossiê de segurança priorizado dos 4 |
| `docs/audit/gravadores-prime.md` | Completo | Quem escreve no PRIME + mecanismo de repasse (agente) |
| `docs/plans/PLANO-consolidacao-aios.md` | Completo | Plano faseado 0–6, decisões, achados |
| `docs/migrations/000-backup.md` | Completo | Comandos de backup dos 4 (rodar antes de tudo) |
| `docs/migrations/001-fundacao-schemas-indices.sql` | Completo | 5 schemas + 17 índices FK no core |
| `docs/migrations/010-schema-crm.sql` | Completo | aquisicao + posvenda + conversas (8 tabelas, nanoid) |
| `docs/migrations/011-schema-conhecimento.sql` | Completo | autodiag + catalogo (11 tabelas) + hybrid no knowledge_chunks |
| `docs/migrations/012-rag-hybrid-search.sql` | Completo | função `search_knowledge` RRF |
| `docs/migrations/impacto-uuid.md` | Arquivado | análise da migração uuid — NÃO executar (revertida) |
| `docs/migrations/proposta-crm.sql` / `proposta-autodiag-catalogo.sql` | Superado | propostas em uuid; substituídas por 010/011 |
| AIOS Supabase (`hlhfqnhsvwxodtwdkkhf`) | Aplicado | só `CREATE EXTENSION vector` (migration `enable_pgvector_extension`) |

## Decisões tomadas
- **Stack = Supabase/Postgres sempre** (nunca SQLite como SoT) — razão: multi-acesso, RLS, dashboard, join cross-domínio, orquestração AIOS.
- **AIOS (`hlhfqnhsvwxodtwdkkhf`) = System of Record único** — razão: SP/sa-east-1 (LGPD+latência), modelo ERP pronto (DRE, permanência por etapa), é onde o Thales trabalha.
- **Topologia por schemas:** `core` (operação+estoque) · `fin` (DRE) · `autodiag` (+tenant) · `catalogo` (+tenant) · `aquisicao` (leads) · `posvenda` (clientes) · `conversas` (corpus Anna).
- **Manter nanoid, NÃO migrar uuid** — não é gambiarra, é padrão consistente; migrar seria difícil (50 FKs, ponteiros polimórficos `events`) por ganho marginal.
- **3 CRMs separados** — regra: cliente = JÁ fez serviço; lead = NÃO fez; graduação na 1ª OS aprovada.
- **RAG híbrido** (pgvector semântico + tsvector PT lexical, fundidos por RRF) — crítico p/ códigos curtos (DTC, part number).
- **Embedding 1024 dims** (denominador comum OpenAI-3-large-truncado/Voyage/BGE-M3) — recomendado começar com OpenAI 3-large@1024 (já tem key), interface desacoplada.
- **DAP4.0** aposenta, só autodiag migra. **PRIME** elimina migrando o ouro (leads/clientes/conversas → `conversas`+`aquisicao`+`posvenda`); resto morre (36 MB, sem motivo de volume). **TOOLS** extraído, derrubar.

## Bloqueios & perguntas abertas
- **Modelo de embedding**: 1024 assumido — confirmar OpenAI 3-large@1024 (sugerido) vs Voyage-3.5 vs reusar 1536 do dap4.
- **`tenant_id` sem tabela `tenants`** (decisão #4 aberta) — integridade via app/RLS ou criar `tenants`?
- **Confirmar `.env` real da VPS** — saber onde a produção aponta HOJE (pré-requisito do cutover Fase 4).
- **2 ações do Thales (independentes):** (1) 🔴 rotacionar chaves expostas em `autodiag-copilot/.env.local` (service_role/openai/anthropic) + checar `.gitignore`; (2) backup + deletar TOOLS no painel.

## Próximo passo exato
**Criar uma branch do AIOS (`hlhfqnhsvwxodtwdkkhf`) e aplicar a sequência `001 → 010 → 011 → 012` nela.** Depois: smoke test (inserir uns chunks com tenant de teste, rodar `autodiag.search_knowledge` com um termo tipo `'P0301 falha partida a frio'`, `EXPLAIN ANALYZE` pra confirmar uso dos índices HNSW + GIN, conferir as 17 FK-indexes e os 5 schemas criados). Validar, e **só então** decidir merge. Aguarda GO do Thales (toca infra, ainda que em branch isolada).

## Setup / comandos úteis
- Projetos: AIOS `hlhfqnhsvwxodtwdkkhf` (fica) · PRIME `acuufrgoyjwzlyhopaus` · TOOLS `mtrmtkvhgrzhwhhfffhj` · DAP4.0 `cpzgtfblywexqglqkgbt`.
- Docs da sessão: `C:\THALES\DAP4.0\docs\` (decisions/audit/plans/migrations).
- App dona do schema do AIOS = `dap-aios` (Drizzle, `packages/types`). `dap4` e `autodiag-copilot` apontam pra outros projetos.
- Vault Obsidian **migrado pra `C:\THALES\PITOS\`** (era OneDrive\...\CHAIRMAN\PITOS). CLAUDE.md do hub atualizado nesta sessão. Handoffs de DAP 4.0 em `C:\THALES\PITOS\03 - PROJETOS\DAP 4.0\Status\`.
