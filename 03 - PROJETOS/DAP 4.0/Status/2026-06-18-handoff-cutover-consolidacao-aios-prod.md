---
type: handoff
date: 2026-06-18
project: DAP 4.0 (consolidação Supabase)
topic: Cutover da consolidação (001–012) aplicado em produção no AIOS
tags: [handoff, claudin, aios, supabase, cutover, rag]
---

# Handoff — Cutover da consolidação aplicado em PRODUÇÃO (AIOS)

## Resumo executivo
Com GO do Thales, apliquei a consolidação em **produção** no AIOS (`hlhfqnhsvwxodtwdkkhf` = SoR):
sequência `002 → 001 → 010 → 011 → 012`. **Dados vivos intactos** — migrations 100% aditivas
(criam schemas/tabelas/índices; não alteram nem apagam dado). Validação estrutural e funcional verde.
O AIOS agora tem a topologia por schemas desenhada + o RAG híbrido pronto pra popular.

## O que funcionou (com evidência)
- **Pré-voo:** confirmado que os 5 schemas novos não existiam, pgvector instalado, content_items/appointments presentes (002 = no-op).
- **002→012 aplicadas** (apply_migration, todas `success:true`).
- **Validação pós:** 5 schemas (autodiag·catalogo·aquisicao·posvenda·conversas) · 8 tabelas CRM · 11 conhecimento · 18 FK-indexes no core · função `autodiag.search_knowledge` · 2 índices RAG (HNSW embedding + GIN tsv).
- **Dados vivos idênticos ao pré-cutover:** customers 418 · vehicles 546 · service_orders 659 · events 1616 · service_order_items 654.
- **Função RAG executa contra prod** (chamada com corpus vazio → 0 linhas, sem erro; tipos resolvem).

## Notas de risco (mitigadas)
- Backup via pg_dump não é possível por MCP — mitigado pelo fato de as migrations serem estritamente aditivas e reversíveis (`DROP SCHEMA ... CASCADE` / `DROP INDEX`). Recomendado: confirmar PITR/backup automático ligado no AIOS.
- Índices do 001 em tabelas vivas (events 1616, etc.) — tabelas pequenas, lock sub-segundo, sem impacto perceptível nos webhooks.

## Estado do migration history do AIOS (agora)
`...`, `enable_pgvector_extension`, `0000_ferramentas...`→`0005_postgrest...` (autodiag-copilot),
`002_reconcile_drift...`, `001_fundacao...`, `010_schema_crm`, `011_schema_conhecimento`, `012_rag_hybrid_search`.
Drift de content_items/appointments **reconciliado** (002) — branches futuras nascem fiéis.

## Próximos passos (precisam de decisão/execução)
1. **Confirmar modelo de embedding** (1024 assumido — OpenAI 3-large@1024 sugerido). Coluna é `vector(1024)`; trocar = re-embeddar, sem mudar schema.
2. **Atualizar código** (gateway/agents do dap4, ~50 pontos de escrita) pros schemas/nomes novos. Hoje o código ainda escreve no modelo antigo.
3. **Repontar `.env` da VPS** (Fase 4) pro AIOS quando o código estiver adaptado — produção viva (Anna/Kommo/webhooks) ainda aponta pro stack legado.
4. **Popular o RAG**: migrar o ouro (DTCs, SOPs, conhecimento) pro `autodiag.knowledge_chunks` + gerar embeddings.
5. `tenant_id` sem tabela `tenants` — decidir integridade (app/RLS vs criar `tenants`).
6. **RLS** nas tabelas novas quando expostas ao client (hoje backend via service_role/pooler bypassa).

## Pendências independentes
- Backup + deletar TOOLS no painel.
- (AutoDiag) colar service_role + 2 DATABASE_URL do AIOS no `.env.local` e `pnpm dev` — ver handoff lift-shift.
