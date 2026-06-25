---
type: handoff
date: 2026-05-05
time: 15:16
project: dap-operacao + DAP4 cutover
topic: Migração SQLite→Supabase Postgres + decommission C:\dev\dap4 — Fases 0+1a+1b fechadas, Fase 2 bloqueada em secret
tags: [handoff, claudin, dap4, cutover, supabase, dap-operacao, postgres-migration]
---

# Handoff — DAP4 Cutover (dap-operacao → Supabase, kill legacy)

## Contexto

Thales decidiu (sessão de 2026-05-05) migrar **dap-operacao** de SQLite local pra **Supabase Postgres** e decomissionar o stack legacy em **C:\dev\dap4** (P1, VPS 76.13.170.42, 27 tabelas, 5.911 leads, Anna ativa em shadow). Plano em 3 fases:

- **Fase 0** — Snapshots não-destrutivos (Supabase audit, VPS inventory, git bundle, schema migration plan, auth decision). ✅ FECHADA.
- **Fase 1a** — Hardening prod DOCTOR PRIME (RCE fix em `exec_sql`, RLS lockdown em 14 tabelas oficina, fechando exposição de `colaboradores.password_hash` ao anon). ✅ FECHADA.
- **Fase 1b** — dap-operacao Postgres-ready (driver swap libsql→postgres-js, schemas `oficina` + `oficina_test` em DOCTOR PRIME, 117 testes verdes, smoke test ok). ✅ FECHADA.
- **Fase 2** — Cutover real (migrar dados, repointar `operacao.doctorautoprime40.com`, desligar legacy, arquivar repo). 🔒 BLOQUEADA em secret.

Toda essa sessão é o trabalho técnico pra desbloquear a Fase 2. Decisão arquitetural-chave: **manter bcrypt + Express session** no dap-operacao (não migrar pra Supabase Auth) — zero rewrite dos 117 testes, RLS fica como defense-in-depth. Documentado em `auth-decision.md`.

## O que funcionou (com evidência)

- **Snapshots Fase 0 completos** — `PITOS/Backups/dap4-cutover-2026-05-05/` tem: 6 JSONs Supabase + AUDIT-REPORT (29.635 rows confirmados em DOCTOR PRIME), VPS-INVENTORY (5 containers healthy, ChromaDB 7 collections vazias, Anna em shadow `AI_AUTOREPLY_ENABLED=false`), git bundle 1.6MB / 43 refs / verify PASS, schema-postgres.ts validado, auth-decision.md
- **RCE fechado em prod** — `exec_sql(text)` e `execute_readonly_query(text)` agora só `service_role` (eram SECURITY DEFINER + EXECUTE pra anon → vetor RCE). Verificado: `pg_proc.proacl = {postgres,service_role}`
- **43 policies anon abertas dropadas** — em 14 tabelas oficina (clients, colaboradores, ordens_servico, etc). `BEGIN; SET LOCAL ROLE anon; SELECT count(*) FROM colaboradores → 0` ✓
- **Schema `oficina` em DOCTOR PRIME prod** — 13 tables, 10 enums, 32 indexes, 13 RLS policies (service_role only). Public schema legacy intacto.
- **Schema `oficina_test` em DOCTOR PRIME** — idêntico, suffix `_t` em indexes pra evitar collision, isolado de prod
- **117/117 testes verdes** contra Postgres 17 local (Docker `dap-test-pg` :5433) em 3 runs consecutivos
- **`npm run check` (tsc) green** em todo o repo (client + server + tests)
- **Smoke test passou** — `node --env-file=.env.test.local tsx server/index.ts` boota em :5051, `GET /api/auth/me` retorna 401 (correto, sem cookie)

## O que NÃO funcionou (e por quê)

- **Senha gerada pelo Thales pro DAP4.0 sandbox falhou auth** — `dOCTORAUTO3495@@@` rejeitada pelo servidor com `password authentication failed for user "postgres"`. Testou-se com URL-encoding correto (`%40%40%40`), pooler hostname certo (`aws-1-us-east-1`), formato `postgres://`. Hipóteses: senha digitada não bate com a Reset confirmada no dashboard, ou Reset não persistiu.
- **Senha do DOCTOR PRIME postgres role NÃO ESTÁ EM NENHUM ARQUIVO LOCAL** — busca exaustiva: VPS `/opt/doctor-auto-ai/.env*`, todos `.env*` em `C:\Users\docto`, `C:\dev\dap4`, `C:\THALES`. 8 arquivos referenciam DOCTOR PRIME mas só com `SUPABASE_URL` (REST API) — NUNCA `DATABASE_URL`/`POSTGRES_PASSWORD`/pooler URL. Os agentes Python (Anna/Sofia) usam supabase-py via REST. Postgres direct nunca foi configurado.
- **Drizzle `pgSchema("oficina")` ignora `search_path`** — emite SQL literal `"oficina"."organizations"` independente do search_path. Testes inicialmente quebraram porque helper rewrite oficina→oficina_test no migration SQL mas storage queries continuavam batendo `"oficina"."*"`. Fix: testes rodam em schema `oficina` mesmo (no Postgres local isolado é seguro), com advisory lock pg pra serializar 18 forks vitest racing em DROP+CREATE SCHEMA, e `fileParallelism: false`.
- **drizzle-zod `createInsertSchema` é estrito demais** — rejeita `1`/`0` como boolean (clientes legacy mandam 0/1). Fix: `coercedBool` preprocessor em `mechanic.active` e `checklist.{seatCover,steeringCover,floorMat,fenderProtector}`.
- **3 PowerShell tentativas de pegar senha falharam** — Thales mandou "OK"/"GO"/"VAI"/"tenta" mas `.env.test.local` nunca foi atualizado (mtime confirmou). Provavelmente comando não rodou ou ele deixou `<password>` literal.

## O que ainda não foi tentado

- **Reset da senha DOCTOR PRIME** — risco médio-baixo: pelo levantamento, NINGUÉM usa Postgres direct pro DOCTOR PRIME hoje (só REST via supabase-py + supabase-js). Reset deveria ser seguro, mas confirmar antes
- **Migração de dados Fase 2** — `crm_leads_externo` (17.887 rows, lake canônico) + tabelas oficina vivas. Não tocado
- **Re-aponta DNS** — `operacao.doctorautoprime40.com` continua pro deploy legacy
- **Smoke test em prod** — não rodado (depende do secret)
- **Push da branch + PR** — Thales pediu pra revisar antes
- **Investigação dos listeners VPS desconhecidos** — `mysql.service` :3306 e `python3` :9443/:9444 (origem unknown)

## Arquivos tocados

### Repo `C:\THALES\DAP4\dap-operacao` (branch `feat/postgres-migration`, 13 commits, NÃO pushada)

| Arquivo | Status | Notas |
|---|---|---|
| `shared/schema.ts` | Completo | Drizzle pg-core, `pgSchema("oficina")`, 13 tables, 10 enums; timestamps mantidos como `text` ISO-string pra preservar contrato das routes |
| `server/storage.ts` | Completo | libsql → postgres-js. PRAGMA removido. Class renomeada `PostgresStorage` |
| `server/routes/index.ts` | Completo | memorystore → connect-pg-simple, session em `public.session` com `createTableIfMissing:true` |
| `drizzle.config.ts` | Completo | `dialect:"postgresql"`, `schemaFilter:["oficina"]`, `out:"./migrations-pg"` (legacy `migrations/` preservado) |
| `package.json` + lock | Completo | +postgres@3.4.5, +pg@8.13.1, +connect-pg-simple@9.0.1, -libsql, -memorystore |
| `.env.example` | Completo | Pooler DOCTOR PRIME us-west-2 com placeholder `<password>` |
| `.env.test.local` | Em uso | Aponta pro Postgres local Docker `:5433` (gitignored) |
| `tests/helpers/db.ts` | Completo | Postgres TRUNCATE-based, advisory lock, assertNotProduction guard |
| `migrations-pg/0000_misty_eternity.sql` | Gerado | 220 linhas, 13 tables, FKs, indexes |
| `scripts/set-test-db-password.ps1` | Untracked | Helper criado pra Thales mas não foi usado |

### Backups & docs em `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Backups\dap4-cutover-2026-05-05\`

| Path | Status | Notas |
|---|---|---|
| `supabase/AUDIT-REPORT.md` + 6 JSONs | Completo | DOCTOR PRIME inventário canônico |
| `vps/VPS-INVENTORY.md` + chromadb tarball | Completo | Snapshot 2026-05-05 |
| `code/dap4-legacy-2026-05-05.bundle` | Completo | 1.6MB, 43 refs, verify PASS, restore: `git clone <bundle>` |
| `code/CODE-ARCHIVE-REPORT.md` + working-tree-diff.patch | Completo | HEAD `f28063b` em `feat/anna-shadow-mode` |
| `migration-plan/schema-postgres.ts` | Completo | Validado, fonte canônica do refactor |
| `migration-plan/migration-plan.md` | Completo | Riscos, dev effort, test stack |
| `migration-plan/auth-decision.md` | Completo | Manter bcrypt+session, rejeição fundamentada de Supabase Auth |
| `migration-plan/rollback-plan.md` | Completo | Plano de reversão |
| `migration-plan/applied/01_revoke_dangerous_funcs.sql` | Aplicado | RCE fix DOCTOR PRIME |
| `migration-plan/applied/02a_lockdown_oficina_rls_part1.sql` | Aplicado | RLS lockdown parte 1 |
| `migration-plan/applied/02b_lockdown_oficina_rls_part2.sql` | Aplicado | RLS lockdown parte 2 |
| `migration-plan/applied/03_create_oficina_schema.sql` | Aplicado | Schema oficina (DOCTOR PRIME + DAP4.0 sandbox abandonado) |
| `migration-plan/applied/HARDENING-REPORT.md` | Completo | Sumário das migrations 01+02 |
| `migration-plan/applied/03_SCHEMA-CREATION-REPORT.md` | Completo | Sumário schema oficina |

### Supabase DOCTOR PRIME (`acuufrgoyjwzlyhopaus`)

| Mudança | Status |
|---|---|
| `exec_sql` + `execute_readonly_query` granted only to service_role | ✓ |
| 43 policies anon `qual=true roles={public}` dropadas em 14 tabelas | ✓ |
| Schema `oficina` criado (13 tables, 10 enums, 32 indexes, 13 RLS) | ✓ |
| Schema `oficina_test` criado (idêntico, indexes _t suffix) | ✓ |
| Public schema legacy | Intacto |

### Docker

| Container | Status |
|---|---|
| `dap-test-pg` (postgres:17-alpine) em :5433 | Rodando |
| `evo-postgres` em :5432 (Evolution) | Não tocado |
| `evolution-api` em :8080 | Não tocado |

## Decisões tomadas

- **Manter bcrypt + Express session** (não migrar pra Supabase Auth) — razão: zero rewrite dos 117 testes, Supabase Auth não paga complexidade pra workload de 5 staff/org provisionado por admin. RLS fica como defense-in-depth, app-level filter via `tenantId(req)` permanece a barreira primária. Triggers pra reabrir: portal customer-facing self-signup, MFA staff (resolvível com TOTP local), 3ª org com users cross-org.
- **Pivot DAP4.0 sandbox → DOCTOR PRIME `oficina_test`** — DAP4.0 password gerada falhou autenticação 3x consecutivas. Schema isolado em DOCTOR PRIME é equivalente, sem risco em prod (helper só DROP+CREATE em `oficina_test`, nunca `oficina`).
- **Pivot DOCTOR PRIME → Postgres local Docker pra rodar testes** — senha DOCTOR PRIME ausente em todo disco. Postgres 17.9 local em :5433 é o mesmo motor de prod, sem latência us-west-2, sem custo de pooler. Trade-off: não testa pgvector/Supabase-specific, mas dap-operacao não usa nenhum dos dois.
- **Timestamps como `text` (ISO string), não `timestamptz`** — schema-postgres.ts inicialmente tinha `timestamp` mas isso quebrou 21 type-check errors em routes que passam `new Date().toISOString()`. Decisão: 1:1 contract preserve. Trade-off: perde benefícios de Postgres date arithmetic. Pode ser revisitado em Fase 3.
- **5 enums abertos como `text`** — schema-postgres.ts tinha pgEnum tight, mas expôs 2 latent bugs em produção (`role: "tecnico"` em vez de `"mecanico"`, `category: "edit"` não no enum). Mantido `text` pra não quebrar nada hoje, flagged pra CHECK constraint pass futuro.
- **Advisory lock + fileParallelism:false em testes** — 18 forks vitest paralelos racing em DROP SCHEMA. Lock simplifica e elimina flakiness sem custo significativo (suite roda em <1min).
- **Fechar exposição RLS antes do cutover** — `colaboradores.password_hash` exposto a anon era hard blocker. Fechado em Fase 1a antes de qualquer trabalho de dados.

## Bloqueios & perguntas abertas

1. **Senha role `postgres` do DOCTOR PRIME** — único gate da Fase 2. Não está em disco. Opções pro Thales:
   - Lembra a senha → cola em `.env.production.local` (não chat)
   - Reset no dashboard (verificar antes que ninguém usa Postgres direct — pelo levantamento, ninguém usa)
   - Alguma vault pessoal (1Password, KeyPass, Bitwarden)
2. **Cutover window** — Anna está em shadow (`AI_AUTOREPLY_ENABLED=false`), sem cliente afetado em tempo real. Mas `crm_leads_externo` (17.887 rows) é dado vivo do Manus + scrapes. Migração não pode perder.
3. **DNS `operacao.doctorautoprime40.com`** — atualmente aponta pra dap-operacao node service na VPS rodando em :5001 com SQLite. Cutover precisa: deploy nova versão (apontando pra Supabase), validar, repointar.
4. **VPS hygiene** — `mysql.service` em :3306 + `python3` listeners em :9443/:9444 (origem desconhecida). Investigar antes de wipe.
5. **DAP4.0 project Supabase abandonado** — 25 tabelas, 275 rows, Parliament zerado. Pode deletar pós-cutover (uma chamada Supabase MCP).
6. **Push da branch** — Thales pediu pra revisar antes. PR ainda não aberto.

## Próximo passo exato

Thales precisa **descobrir/resetar a senha do role `postgres` do projeto DOCTOR PRIME (`acuufrgoyjwzlyhopaus`) na Supabase**. Sem isso, Fase 2 não roda. Caminho recomendado (em ordem):

1. Verificar 1Password / vault pessoal por "DAP4" ou "DOCTOR PRIME" ou "Supabase postgres"
2. Se não achar: Supabase dashboard → projeto DOCTOR PRIME → Project Settings → Database → **Reset database password** (clicar Generate, copiar IMEDIATAMENTE)
3. Salvar a senha num vault pessoal **antes** de fechar a tela do dashboard
4. Editar `C:\THALES\DAP4\dap-operacao\.env.production.local` (criar) com:
   ```
   DATABASE_URL=postgres://postgres.acuufrgoyjwzlyhopaus:<senha_url_encoded>@aws-0-us-west-2.pooler.supabase.com:6543/postgres?sslmode=require&search_path=oficina,public
   ```
5. URL-encode a senha se tiver caracteres especiais (`@`→`%40`, `:`→`%3A`, `/`→`%2F`)
6. **Não colar a senha no chat** — só no arquivo

Depois do secret resolvido, próxima sessão pode:
- Spawnar agente pra rodar smoke test contra DOCTOR PRIME schema `oficina` real
- Aplicar migrations-pg lá
- Migrar dados (se houver) das tabelas oficina legacy → schema oficina
- Pushar branch + abrir PR
- Atacar Fase 2 propriamente (DNS, deploy, decommission VPS legacy, archive repo)

## Setup / comandos úteis

**Container Postgres de teste (segue rodando):**
```powershell
docker ps --filter name=dap-test-pg
# parar: docker stop dap-test-pg && docker rm dap-test-pg
```

**Rodar testes:**
```powershell
cd C:\THALES\DAP4\dap-operacao
node --env-file=.env.test.local node_modules/vitest/vitest.mjs run --reporter=verbose
```

**Smoke test local:**
```powershell
cd C:\THALES\DAP4\dap-operacao
PORT=5051 node --env-file=.env.test.local node_modules/.bin/tsx server/index.ts
```

**Verificar schemas em DOCTOR PRIME (via Supabase MCP, sem precisar de senha postgres):**
```
mcp__claude_ai_Supabase__execute_sql project_id=acuufrgoyjwzlyhopaus
SELECT table_schema, count(*) FROM information_schema.tables
WHERE table_schema IN ('oficina','oficina_test','public') GROUP BY 1;
```

**Rollback Fase 1a (RLS):** SQLs originais em `DOCTOR_PRIME-rls-policies.json`. Recriar policies abertas se algum cliente legacy quebrar.

**Restore C:\dev\dap4 a partir do bundle:**
```
git clone "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Backups\dap4-cutover-2026-05-05\code\dap4-legacy-2026-05-05.bundle" dap4-restored
```
