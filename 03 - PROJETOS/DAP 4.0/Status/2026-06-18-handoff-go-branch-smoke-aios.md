---
type: handoff
date: 2026-06-18
project: DAP 4.0 (consolidação Supabase)
topic: GO branch — testar 001→012 em branch do AIOS, smoke, drift e cutover
tags: [handoff, claudin, aios, supabase, rag]
---

# Handoff — GO branch executado (smoke verde + drift descoberto)

## Resumo executivo
Executei o **"GO branch"** do handoff de consolidação: criei uma branch efêmera do AIOS,
apliquei `001 → 010 → 011 → 012`, rodei o smoke completo (estrutural + funcional RAG), **deu
verde em tudo**, e **derrubei a branch** (custo parado). Produção **intocada**. No caminho
descobri um **drift de migration history** que reescreve a estratégia de merge. Materializei a
correção em 2 arquivos novos. Cutover de produção **aguarda GO explícito** — não apliquei nada em prod.

## O que funcionou (com evidência)
- **Branch** `consolidacao-test` (`wporpdwecssmtgzehhcc`) criada a partir do AIOS (`hlhfqnhsvwxodtwdkkhf`), custo confirmado $0.01344/h.
- **001→012 aplicaram sem erro.** Smoke estrutural: 5 schemas · 18 FK-indexes · 8 tabelas CRM · 11 conhecimento · 27 FKs cross-schema (4→customers, 2→vehicles, 5→users) · função `search_knowledge` criada · 2 índices RAG.
- **Smoke funcional RAG verde:** inseri chunks de teste + 1003 sintéticos. `search_knowledge('sys_tenant','P0301 falha na partida a frio', emb, 5)` → `kc_test_a` com `semantic_rank=1 + lexical_rank=1` fundidos por RRF.
- **EXPLAIN ANALYZE confirma os índices:** semântico → `Index Scan using ix_knowledge_chunks_embedding` (HNSW); lexical → `Bitmap Index Scan on ix_knowledge_chunks_tsv` (GIN). Stemming PT ok (`part & fri & falh`).
- **Branch derrubada** após validar (`delete_branch success:true`).

## O que NÃO funcionou / achado crítico
- **DRIFT no migration history.** A branch nasceu com 29 tabelas em `public`, não as ~31 de prod.
  `public.content_items` e `public.appointments` existem em produção mas **não estão no migration
  history** (criadas via Drizzle push). Tive que recriar `content_items` na branch (andaime
  `branch_parity_content_items`) só pra a `001` rodar.
- **Consequência:** NÃO usar `merge_branch` do Supabase (carregaria o andaime pro history de prod
  e não resolve o `appointments`). O drift **não bloqueia o cutover** (tabelas já existem em prod),
  só bloqueia teste fiel em branch futura.

## Arquivos criados
| Arquivo | Conteúdo |
|---|---|
| `docs/migrations/002-reconcile-drift-content-appointments.sql` | Migration idempotente que registra content_items+appointments no history (no-op em prod, cria em branch). Estrutura espelha prod (PK/FK/índices/RLS lockdown). |
| `docs/migrations/CUTOVER-runbook.md` | Resultado do smoke + ordem de aplicação em prod + o que não fazer + pendências. |

## Próximo passo exato
**Cutover de produção** (seção 3 do CUTOVER-runbook.md), **só com GO**:
backup dos 4 → `002` (ou `supabase db pull`) → `001` → `010` → `011` → `012` → re-smoke contra prod.
Decisões ainda abertas (herdadas): confirmar embedding 1024 (OpenAI 3-large@1024), `tenant_id` sem
tabela `tenants`, repontar `.env` da VPS (Fase 4), atualizar ~50 pontos de escrita no código.

## Pendências do Thales (independentes)
- 🔴 Rotacionar chaves expostas em `autodiag-copilot/.env.local` + checar `.gitignore`.
- Backup + deletar TOOLS no painel.
