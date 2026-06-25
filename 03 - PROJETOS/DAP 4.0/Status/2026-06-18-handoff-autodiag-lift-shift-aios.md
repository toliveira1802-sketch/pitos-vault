---
type: handoff
date: 2026-06-18
project: DAP 4.0 (AutoDiag Copilot)
topic: Lift-and-shift do AutoDiag (schema ferramentas) do DAP4.0 pro AIOS
tags: [handoff, claudin, autodiag, aios, supabase]
---

# Handoff — AutoDiag Copilot movido pro AIOS (lift-and-shift)

## Resumo executivo
Movi o banco do **AutoDiag Copilot** do projeto Supabase **DAP4.0** (`cpzgtfblywexqglqkgbt`,
em aposentadoria) para o **AIOS** (`hlhfqnhsvwxodtwdkkhf` = SoR). Decisão do Thales: Opção A
(lift-and-shift), porque o intuito atual é **agente de diagnóstico interno da oficina** e o
futuro **SaaS** leva o schema `ferramentas` (per-user) junto — não vale re-plataformar agora
sobre o `autodiag` multi-tenant da consolidação. Os dois modelos coexistem no AIOS de propósito.

## O que funcionou (com evidência)
- **Sondagem de compatibilidade do AIOS** antes de aplicar: search_path já inclui `extensions`
  (bare `vector` resolve), `gen_random_uuid` e opclass `hnsw` ok, `citext` disponível, `ferramentas`
  inexistente. → migrations aplicam verbatim, sem editar arquivos do repo.
- **Migrations `0000–0005` reaplicadas no AIOS** (apply_migration, todas `success:true`).
- **Verificação pós:** schema `ferramentas` com 6 tabelas · 6 RLS forçada · 11 policies · 4 funções
  (uuidv7, touch_updated_at, handle_new_user, profiles_block_plan_change) · trigger em `auth.users` ·
  índice HNSW em `dtc_dictionary` · **10 profiles backfilled = 10 auth.users**. `public` (consultor) intocado.
- **`.env.local` repontado pro AIOS** (URL + anon key preenchidas).
- **CLAUDE.md do autodiag-copilot** atualizado (banco agora = AIOS).

## O que NÃO foi feito (proposital)
- Re-plataformar sobre o schema `autodiag` da consolidação — rejeitado (briga com o futuro SaaS por-usuário).
- Aplicar a consolidação `001–012` em produção — continua aguardando GO separado (ver `CUTOVER-runbook.md`).
- Rotação das chaves do DAP4.0 — moot (projeto vai morrer).

## Arquivos tocados
| Arquivo | Mudança |
|---|---|
| AIOS Supabase (`hlhfqnhsvwxodtwdkkhf`) | migrations 0000–0005 do `ferramentas` aplicadas (prod) |
| `autodiag-copilot/.env.local` | repontado pro AIOS (URL+anon ok; faltam 3 — ver abaixo) |
| `autodiag-copilot/CLAUDE.md` | nota de migração de banco DAP4.0→AIOS |

## Próximo passo exato (Thales)
Colar no `.env.local` (já repontado) 3 valores do painel do AIOS
(`https://supabase.com/dashboard/project/hlhfqnhsvwxodtwdkkhf`):
1. `SUPABASE_SERVICE_ROLE_KEY` (Settings → API → service_role)
2. `DATABASE_URL` (Settings → Database → Transaction pooler, porta 6543)
3. `DATABASE_URL_DIRECT` (Session pooler, porta 5432)
Depois: `pnpm dev` no autodiag-copilot e validar conexão + RAG. (Migrations já estão no AIOS,
não precisa `db:migrate`.) Opcional: rotacionar OpenAI/Anthropic (precaução, app-level).

## Pendências independentes
- Consolidação AIOS (`001–012`) aguardando GO de produção.
- Deletar TOOLS no painel (pós-backup).
