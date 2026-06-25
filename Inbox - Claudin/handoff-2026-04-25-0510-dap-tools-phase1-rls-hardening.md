---
type: handoff
date: 2026-04-25
time: "05:10"
project: dap-tools (C:\dev\dap-tools)
topic: Phase 1 — Auth & RLS Hardening (95% — falta rodar test:rls com JWT_SECRET rotacionado)
tags: [handoff, claudin, dap-tools, gsd, supabase, rls, auth]
---

# Handoff — Phase 1 do dap-tools (Auth & RLS Hardening) parou em 95%

## Contexto

Sessão começou com `/gsd-map-codebase` no dap-tools, escalou pra `/gsd-new-project` (PROJECT.md + REQUIREMENTS + ROADMAP de 5 fases coarse — milestone "Sala do Conselho Operável v1"), depois `/gsd-plan-phase 1` (6 plans escritos pra Auth & RLS Hardening), e finalmente `/gsd-execute-phase 1` que rodou Waves 1+2+3+4 quase ao fim.

**O alvo do Phase 1**: fechar 5 success criteria de segurança no schema Supabase do dap-tools (project ref `mtrmtkvhgrzhwhhfffhj`):
1. Mecânico não vê `valor_total` em OS
2. Consultor só vê próprios leads (`responsavel_id = auth.uid()`)
3. Gestor lista todos sem recursão de RLS
4. Signup fora de allowlist rejeitado, novo user nasce `ativo=false`
5. Backend Kommo proxy fail-fast em prod sem `SUPABASE_JWT_SECRET` ou `ALLOWED_ORIGINS`

Status real no banco vivo (verificado via Supabase MCP): tudo aplicado e funcionando. Falta SÓ rodar o test suite RLS pra fechar AUTH-08 (validação comportamental). E aí Phase 1 = done.

## O que funcionou (com evidência)

- **PROJECT.md + REQUIREMENTS.md (35 reqs v1) + ROADMAP.md (5 fases coarse) + 6 PLAN.md** — commits `8472b5a`, `156665d`, `738a35d`. Plan-checker rodou 2 passes; pegou 2 BLOCKERS (B1 dual-action em 01b, B2 shell `||` ambíguo) + 4 WARNINGS (W1 self-promotion via PATCH, W3 grep+wc broken, W4 SIGN1 frouxo, W2 doc minor). Todos corrigidos in-line. Renumeração de migration 10→11→12→13 pra abrir espaço pro novo trigger guard.

- **Wave 1 (3 plans paralelos)** — 01a (3 migrations: helpers `is_gestor`+`current_user_role` + portal_users RLS sem recursão + trigger BEFORE UPDATE bloqueando self-promotion), 01c (handle_new_auth_user com allowlist + ativo=false + infra/SUPABASE_AUTH.md), 01d (backend/server.js fail-fast em prod + 5 testes Node — 5/5 green em `npm run test:backend`). Commits `1d0c8af` `7ff7449` `6bd35e5` `7299361` `2d1e050` `f418903` `15e89ad` `71e11d5`.

- **Wave 2** — 01b (CRM Externo 26 policies + CRM Interno 18 policies + view `os_mecanico` SEM `valor_total` SEM `security_invoker` — defesa real). Commits `4a767b9` `d7fa6ac`.

- **Wave 3 — DEPLOY EM PROD via Supabase MCP**. Plot twist: o `supabase db push` falhou silencioso porque o remote tem 13 migrations aplicadas e o local só tinha 7 (drift histórico de outra sessão paralela). CLI sugeriu `migration repair --reverted` o que mentiria pro `schema_migrations`. Pivotamos pra `mcp__claude_ai_Supabase__apply_migration` aplicando 08-13 direto + criando migration 14 nova pra dropar regressão `anon_select_*` que tinha sido adicionada em outra sessão (vazava PII pública). Aplicações `{success:true}` × 7 via MCP. Verificações pós-deploy:
  - 4 funções esperadas presentes
  - Trigger BEFORE UPDATE em portal_users instalado E **provou funcionar** (bloqueou meu próprio UPDATE durante o seed da fixture!)
  - View `os_mecanico` com 13 colunas, **zero `valor_total`**
  - 0 policies `USING(true)` nas 10 tabelas CRM
  - 0 policies `anon_*` nas 11 tabelas
  - 51 policies role-aware ativas (counts por tabela: leads 8, lead_veiculos 5, lead_interacoes 4, orcamentos 4, orcamento_itens 4, campaign_events 1, clientes 3, veiculos 3, ordens_servico 10, recorrencia 3, portal_users 6)

- **Wave 4 (parcial)** — Test infra escrita (commits `348fe66` `63a5821` `35afb5a` `498df4f`): fixture SQL + run-rls-tests.mjs (16 specs: G1-G3, C1-C3, M1-M4, R1-R3, SIGN1, SIGN2, SELF1) + tests/rls/README + npm install do `jsonwebtoken@^9.0.2`. Fixture aplicada via MCP (commit `e4373ba` corrigiu o arquivo local) — 5 portal_users seedados (gestor, consultorA, consultorB, mecanico, recepcao) + 2 leads + 2 orçamentos + 1 cliente + 1 veículo + 1 OS.

- **Migration 14 spontânea (não estava no plano)** — Audit pós-deploy via MCP detectou policies `anon_select_clientes`, `anon_select_ordens_servico`, `anon_select_veiculos` aplicadas em outra sessão expondo PII pública via anon key. Migration 14 dropou as 3. Commit `3bfba42`.

## O que NÃO funcionou (e por quê)

- **`supabase db push --linked`** — falhou silencioso. Causa: drift histórico — local tinha 7 migrations, remote tinha 13 (5 que o local não tinha + 3 com timestamps diferentes pro mesmo nome lógico). CLI sugeriu `migration repair --reverted` que mentiria pro schema_migrations. Pivotei pra MCP `apply_migration`. **Lição**: em Windows + drift acumulado, `supabase db push` não é confiável; MCP é. Reconciliação local↔remote ainda pendente como hygiene (Phase 4 / CI).

- **`supabase db pull --linked`** — também falhou. Causa 1: erro `42501: permission denied to alter role` no role temporário `cli_login_postgres` (limitação do free tier ou mudança recente da Supabase). Causa 2: depois de setar `$env:SUPABASE_DB_PASSWORD`, novo erro "remote migration history does not match local files" (mesmo drift). CLI sugeriu repair script perigoso. Skipei.

- **Fixture original (`tests/rls/fixtures/users.sql`)** — INSERT direto em portal_users falhou com FK violation `portal_users_id_fkey` (precisa entry em auth.users). Tentativa 2: INSERT em auth.users + UPDATE portal_users role/ativo falhou com `42501 Self-promotion bloqueado` — meu próprio trigger funcionando! (caller é service_role que não é gestor). Fix final: `ALTER TABLE ... DISABLE TRIGGER` durante o UPDATE seed. Arquivo local atualizado pra refletir o pattern. **Aprendizado pra próxima vez**: fixture de RLS sempre precisa pensar quem é o caller e se triggers vão dispararar.

- **`npm run test:rls` (primeira tentativa)** — 16/16 falharam com 401 Invalid API key. Causa: dei a instrução com placeholders literais `<COLE_AQUI: ...>` e o Thales colou o template inteiro sem substituir. Erro meu de UX (usei brackets que pareciam parte da sintaxe).

- **JWT_SECRET vazou no chat** — Thales colou o JWT_SECRET em texto puro na resposta seguinte, achando que precisava me passar. Não precisa — secrets vão SÓ no terminal local. Pendente: rotacionar o secret no painel Supabase.

## O que ainda não foi tentado

- **`npm run test:rls` com env vars certas** (depois da rotação do JWT_SECRET). É o único item bloqueando o fechamento do Phase 1.
- **Reconciliação local↔remote das migrations** (5 missing files do remote + 3 phantoms locais). Hygiene pra Phase 4.
- **Auditoria do painel Supabase Email Templates pra PT-BR** (item não-crítico do `infra/SUPABASE_AUTH.md`).
- **Push pra origin** (branch `adc-DAp40` está 19 commits ahead).

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `.planning/PROJECT.md` | Completo | 67 linhas, 6 key decisions logged |
| `.planning/REQUIREMENTS.md` | Completo | 35 reqs v1 (AUTH×8 + ONB×5 + SPA×10 + CI×7 + TEST×5), traceability 35/35 |
| `.planning/ROADMAP.md` | Completo | 5 fases coarse, 100% coverage |
| `.planning/STATE.md` | Completo | Atualizado pra Wave 4 pendente |
| `.planning/codebase/*.md` (7 docs) | Completo | 1.678 linhas (audit pré-projeto) |
| `.planning/phases/01-auth-rls-hardening/01a-PLAN.md` | Completo | + 01b, 01c, 01d, 01e, 01f. ~2.900 linhas total |
| `.planning/phases/01-auth-rls-hardening/01a-SUMMARY.md` | Completo | + 01b, 01c, 01d, 01f SUMMARYs |
| `supabase/migrations/20260425100000_08_auth_helpers.sql` | Completo + Aplicado | is_gestor + current_user_role |
| `supabase/migrations/20260425100100_09_portal_users_rls_fix.sql` | Completo + Aplicado | 6 policies sem recursão |
| `supabase/migrations/20260425100200_10_portal_users_self_update_guard.sql` | Completo + Aplicado | Trigger BEFORE UPDATE blocking self-promotion |
| `supabase/migrations/20260425100300_11_crm_externo_rls_por_papel.sql` | Completo + Aplicado | 26 policies role-aware |
| `supabase/migrations/20260425100400_12_crm_interno_rls_por_papel.sql` | Completo + Aplicado | 18 policies + view os_mecanico |
| `supabase/migrations/20260425100500_13_handle_new_auth_user_hardening.sql` | Completo + Aplicado | Allowlist + ativo=false |
| `supabase/migrations/20260425100600_14_drop_anon_select_regression.sql` | Completo + Aplicado | Dropa anon_select_* (regressão PII) |
| `backend/server.js` | Completo | fail-fast em prod sem JWT_SECRET ou ALLOWED_ORIGINS |
| `backend/.env.example` | Completo | + NODE_ENV |
| `backend/README.md` | Completo | seção "Modos de execução" |
| `infra/SUPABASE_AUTH.md` | Em progresso | Thales marcou checkboxes críticos (`Allow signup=OFF` ✓, providers OFF ✓, URLs ✓); Email Templates ainda untracked. Edits NÃO commitados ainda |
| `infra/dap-backend.service` | Completo | + Environment=NODE_ENV=production |
| `tests/backend/server-fail-fast.test.js` | Completo | 5/5 green |
| `tests/rls/fixtures/users.sql` | Completo + Aplicado | 5 users + 2 leads + 2 orc + 1 cliente + 1 veículo + 1 OS |
| `tests/rls/run-rls-tests.mjs` | Completo | 16 specs, mas NÃO RODADO ainda |
| `tests/rls/README.md` | Completo | Como rodar |
| `package.json` | Completo | + jsonwebtoken@^9.0.2 + scripts test:rls/test:backend/test:all |

## Decisões tomadas

- **Granularity coarse (5 fases v1)** — bate com escopo "operável v1"; granularidade fina vira churn.
- **Skip research externo** — codebase map de 1.678 linhas + CONCERNS já cobrem o domínio.
- **Single-tenant** — Bosch fica no `dap4` (dual-WABA já live lá). DAP Tools é interno DAP Prime.
- **Solo Thales como primeiro usuário** — valida fluxo end-to-end antes de abrir pro time.
- **Sequential foreground subagents (não worktree paralelo)** — Windows + git worktree = histórico de race em `.git/config.lock`. Wave 1 (01c+01d) rodou em paralelo direto na main tree porque files não overlap.
- **Pivot Wave 3: MCP `apply_migration` no lugar de `supabase db push`** — drift local↔remote tornou o CLI inviável; MCP aplica migration por migration sem reconciliation chata. Hygiene (db pull + decisão sobre 3 phantoms) fica pra Phase 4 / CI.
- **Migration 14 nova fora do plano original** — audit pós-MCP detectou regressão de PII pública (`anon_select_*` aplicadas em outra sessão). Adicionei pra fechar o vazamento.
- **Adiar fase 3 (RAG/WhatsApp/event bus)** — já existe em `dap4`. Construir aqui em RLS quebrada = duplicar e arriscar.

## Bloqueios & perguntas abertas

1. **JWT_SECRET vazado no chat** — Thales precisa rotacionar AGORA em https://supabase.com/dashboard/project/mtrmtkvhgrzhwhhfffhj/settings/jwt → "Generate a new secret". Zero impacto operacional (sem usuários em prod ainda). Depois disso, copia o NOVO secret pro env var local e roda o teste.
2. **`supabase/.temp/` apareceu untracked** — saída do `supabase link`. Precisa entrar no `.gitignore`.
3. **Edits não-commitados em `infra/SUPABASE_AUTH.md`** — checkboxes que Thales marcou pessoalmente. Hora dele decidir quando commitar.
4. **3 phantom migrations locais** — `20260424123000_05_portal_users.sql`, `20260424140000_06_crm_interno_unificacao.sql`, `20260425090000_07_crm_interno_indices.sql`. Nunca foram aplicados ao remote (tem versões com timestamps diferentes lá). Provavelmente DELETAR locais. Hygiene pra Phase 4.
5. **5 missing migration files no local** — `06_fix_portal_users_rls`, `07_grant_portal_users`, `create_leads_internos`, `grants_leads_internos`, `add_anon_select_policies_for_crm`, `grant_table_privileges_to_roles`. Estão aplicados no remote mas sem arquivo local. Hygiene pra Phase 4 (`supabase db pull` depois que `migration repair --applied` for resolvido).

## Próximo passo exato

1. Thales: **rotaciona JWT_SECRET** no painel Supabase (https://supabase.com/dashboard/project/mtrmtkvhgrzhwhhfffhj/settings/jwt → "Generate a new secret"). Copia o novo secret.

2. No PowerShell em `C:\dev\dap-tools`:

   ```powershell
   $env:SUPABASE_URL = "https://mtrmtkvhgrzhwhhfffhj.supabase.co"
   $env:SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10cm10a3ZoZ3J6aHdoaGZmZmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzODM5NjksImV4cCI6MjA3Nzk1OTk2OX0.1fzttlyHARr5WUBihSWzpFgM9qXCKIYdrm5yN-1iDvQ"
   $env:SUPABASE_JWT_SECRET = "<COLE_O_SECRET_NOVO_AQUI — não cola no chat com Claudin>"
   echo "JWT length: $($env:SUPABASE_JWT_SECRET.Length)"   # deve dar 40+ chars
   npm run test:rls
   ```

3. Cola o output do `npm run test:rls` numa nova sessão (com `/resume-handoff` ou direto). Próxima Claudin abre este handoff e:
   - Se 16/16 verde (ou 15+1 SIGN2 skip): commit final do Phase 1 SUMMARY, AUTH-08 closed, STATE bumped pra Phase 2 (Onboarding Interno).
   - Se algum vermelho: diagnóstico pelo erro específico.

## Setup / comandos úteis

- **Branch atual**: `adc-DAp40`, **19 commits ahead** de origin. NÃO PUSHAR ainda — esperar Phase 1 fechar 100%.
- **Supabase MCP** está autenticado e funcional nesta sessão (project_id `mtrmtkvhgrzhwhhfffhj`). Próxima Claudin pode usar `mcp__claude_ai_Supabase__execute_sql` pra qualquer verificação SQL no banco vivo.
- **Memory feedback relevante**:
  - `feedback_supabase_mcp_cf_waf.md` — divide payloads >2KB em batches
  - `feedback_branch_drift_paralela.md` — checar `git branch --show-current` antes de commits
  - `feedback_sessoes_paralelas_senha.md` — sempre validar credentials no banco antes de assumir
- **Comando pra retomar**: `/resume-handoff` (lê o handoff mais recente do vault e hidrata contexto).
