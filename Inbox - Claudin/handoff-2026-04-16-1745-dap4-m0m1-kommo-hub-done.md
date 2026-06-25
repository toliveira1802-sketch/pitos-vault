---
type: handoff
date: 2026-04-16
time: 17:45
project: DAP4.0
topic: Phase 1a Kommo Hub — M0 + M1 done, ready for M2
tags: [handoff, claudin, dap4, phase1a, kommo, m0, m1, done]
---

# Handoff — Phase 1a Kommo Hub: M0+M1 concluídos, branch pronta pra M2

## Contexto

Continuação do handoff 2026-04-16-1709. Thales aprovou Rota B (executar plano). Sessão executou M0 (skeleton fixtures) + M1 (migrations + test harness) via skill `superpowers:executing-plans`. Não foi usado `/ccg:execute` (não existe nessa máquina) — substituído pelo skill equivalente.

**Branch:** `feat/kommo-hub-phase1a` (off `rodada-0-foundation`, 7 commits à frente).

## O que funcionou (com evidência)

- **M0 fixture skeletons** — evidência: `agents/tests/fixtures/kommo/{chats_v2_message_added,crm_v4_leads_add,chats_v2_outgoing_response}.json.example` + README com capture/redaction steps. Test `test_fixtures_valid.py` valida shape estrutural (4 tests green via pytest 9.0.3).
- **docs/kommo-api-shapes.md** — evidência: field map completo Chats v2 + CRM v4, outbound/inbound, routing implications, rate limits, 5 gotchas documentados.
- **Cherry-pick base migration** — evidência: commit `dd6c041` (kommo_conversations + kommo_messages) cherry-picked limpo de `feat/whatsapp-kommo` para `feat/kommo-hub-phase1a` → `aeff694`.
- **Vitest setup no gateway** — evidência: `gateway/package.json` + `vitest.config.ts` + scripts `test/test:watch/test:ui`. Devdeps: vitest, @vitest/ui, pg-mem, supertest, @types/supertest. `npm install` succeed (43 added, 0 vuln).
- **M1 schema migrations** — evidência: 4 arquivos criados (supabase/ + gateway/ mirrors):
  - `20260416_01_anna_kommo_schema.sql` → anna_inbox, anna_conversations, kommo_channels, crm_leads ALTER, RLS, LISTEN/NOTIFY trigger, seed Bosch+Prime
  - `20260416_02_kommo_tables_extend.sql` → tenant_id/brand_id/kommo_pipeline_id em kommo_conversations + kommo_messages, RLS
- **10 vitest tests green** — evidência: estrutura de todas as tabelas, colunas, seeds, ADD COLUMN idempotency, RLS statements present, LISTEN/NOTIFY trigger present. `npm test` passa em ~1.5s.
- **7 commits limpos na branch** — evidência: `git log rodada-0-foundation..HEAD` mostra split semântico (M0 fixtures → cherry-pick → vitest → M1 schema → M1 test → env → plan doc).

## O que NÃO funcionou (e por quê)

- **RLS runtime enforcement test** — falhou porque: pg-mem não implementa RLS. Estratégia atual: verifica que os `CREATE POLICY` statements estão no SQL source (3 testes específicos pra isso), e deixa enforcement real pra integration test com Postgres de verdade no M2 (testcontainers ou staging Supabase).
- **Idempotent test full re-run** — falhou porque: pg-mem tem bug conhecido re-parseando `CREATE TABLE IF NOT EXISTS` com CHECK IN() clauses (não acontece em Postgres real — IF NOT EXISTS short-circuita antes do CHECK parser). Escopo reduzido pra ADD COLUMN IF NOT EXISTS + CREATE INDEX IF NOT EXISTS (onde idempotência importa em prod).
- **3 deltas do plano vs realidade do repo** — falharam porque:
  1. Plano referenciava table `leads`, tabela real é `crm_leads` (de `dashboard-git/supabase/migrations/20260325_ai_system_tables.sql`). **Adaptado:** ALTER targets agora `public.crm_leads`.
  2. Plano usava `kommo_message_id UUID references kommo_messages(id)`, mas `kommo_messages.id` é BIGSERIAL. **Adaptado:** FKs agora BIGINT.
  3. Plano mandava modificar `20260413_01_kommo_tables.sql` in-place — mas essa migration já foi aplicada em Supabase prod (via MCP `apply_migration`). Modificar in-place criaria drift silencioso. **Adaptado:** criada migration incremental `20260416_02_kommo_tables_extend.sql` que ALTER TABLE adiciona as colunas — funciona tanto em prod (novas colunas adicionadas) quanto em fresh DB (aplicação sequencial).

## O que ainda não foi tentado

- **`supabase db push`** contra staging — gate oficial do M1, mas requer Supabase CLI + staging project config. Não tentado nessa sessão (fora de escopo mecânico). Prioridade alta pro Thales ou próxima sessão M2.
- **Prime pipeline_id real** — ainda `0` placeholder no seed. Requer Thales (blocker humano #7).
- **Rodar migration contra DB real com RLS e testar cross-tenant block de verdade** — deferido pro M2 quando `kommo-webhook.routes.ts` precisar de fixtures reais.
- **M2 (gateway kommo.service.ts + webhook)** — próximo milestone. Não iniciado por escopo.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `agents/tests/fixtures/kommo/chats_v2_message_added.json.example` | Criado | Placeholder com keys required marcadas |
| `agents/tests/fixtures/kommo/crm_v4_leads_add.json.example` | Criado | Placeholder + custom_fields TODO |
| `agents/tests/fixtures/kommo/chats_v2_outgoing_response.json.example` | Criado | Placeholder resposta outbound |
| `agents/tests/fixtures/kommo/README.md` | Criado | Capture steps + redaction checklist + gotchas |
| `agents/tests/test_fixtures_valid.py` | Criado | 4 tests; strict mode ativa quando .example→.json |
| `docs/kommo-api-shapes.md` | Criado | Field map Chats v2 + CRM v4 + outbound + quirks |
| `gateway/migrations/20260413_01_kommo_tables.sql` | Cherry-picked | De feat/whatsapp-kommo (dd6c041 → aeff694) |
| `gateway/migrations/20260416_01_anna_tables.sql` | Criado | Mirror local de supabase/20260416_01 |
| `gateway/migrations/20260416_02_kommo_tables_extend.sql` | Criado | Mirror local de supabase/20260416_02 |
| `supabase/migrations/20260416_01_anna_kommo_schema.sql` | Criado | Schema core Anna + kommo_channels + RLS |
| `supabase/migrations/20260416_02_kommo_tables_extend.sql` | Criado | Extend kommo_conversations/messages |
| `gateway/package.json` | Modificado | +vitest, @vitest/ui, pg-mem, supertest, @types/supertest + scripts test |
| `gateway/package-lock.json` | Modificado | Lock do npm install |
| `gateway/vitest.config.ts` | Criado | Config node env, 15s timeout, v8 coverage |
| `gateway/tests/migrations.test.ts` | Criado | 10 tests structural + RLS presence |
| `.env.example` | Modificado | +KOMMO_CHATS_CHANNEL_SECRET, THALES_USER_ID, INTEGRATION_ID, ACCOUNT_ID |
| `.claude/plan/dap4-phase1a-kommo-hub.md` | Commitado | Plano execução salvo no repo pra contexto de M2+ |

## Decisões tomadas

- **pg-mem em vez de testcontainers** — razão: RLS não testável em pg-mem mesmo, mas structural integrity (colunas, seeds, idempotência additiva) cobre 80% do valor com 1/10 do custo. testcontainers no M2 quando tiver integration tests de verdade (webhook + DB).
- **`anna_status` column em `crm_leads`** — razão: plano usava `status='handoff_pending'` mas crm_leads não tem coluna `status` (só `classification` e `funnel_stage`). Adicionada coluna explícita `anna_status` com CHECK (active/handoff_pending/stalled/closed) pra diferenciar do Kommo status_id e do classification.
- **Migration incremental vs in-place** — razão: `20260413_01_kommo_tables.sql` já aplicada em Supabase prod; modificar in-place geraria drift. Criada `20260416_02` ALTER-only.
- **BIGINT em vez de UUID pra FKs** — razão: `kommo_messages.id` é BIGSERIAL (Phase 0 decision), mantida consistência.
- **Fixtures em modo skeleton (.json.example)** — razão: Thales bloqueadores humanos (1-6) pendentes; real payloads serão capturados após ele registrar Kommo Chats channel. Skeleton + docs desbloqueiam M1 paralelo.

## Bloqueios & perguntas abertas

### Bloqueios humanos (Thales) — ordem:

1. **KOMMO_TOKEN + KOMMO_DOMAIN + KOMMO_CHATS_CHANNEL_SECRET + KOMMO_THALES_USER_ID** no VPS `.env` — pendente
2. **Registrar canal Chats** (`POST /api/v2/origin/custom/{scope_id}`) — pendente
3. **Capturar payloads reais** (dispara WA pro +551138240025 Bosch) → promover `.example` → `.json` — pendente
4. **Prime pipeline_id real** → update seed em `20260416_01` ou inserir dinâmico — pendente
5. **`supabase db push`** contra staging/prod DOCTOR PRIME pra aplicar as 2 migrations novas — pendente
6. **RTBM documents** (`agents/config/rtbm/dap_prime.md` + `bosch.md`) — bloqueia só M6, não urgente

### Perguntas abertas (baixa prioridade):

- `.superpowers/brainstorm/` e `agents/uv.lock` untracked — não commitados. Se são importantes, decidir na próxima sessão.
- `dashboard-git` submodule está `-dirty` (apontando pra commit não-comitado em submodule). Não tocado — não relacionado ao Phase 1a mas precisa resolver em paralelo.

## Próximo passo exato

**Opção A — Thales desbloquear humano (recomendado):**

1. Gerar tokens Kommo no portal (KOMMO_TOKEN + KOMMO_DOMAIN + KOMMO_CHATS_CHANNEL_SECRET + KOMMO_THALES_USER_ID) e colocar no `.env` do VPS + `.env` local.
2. Registrar canal Chats custom via `POST /api/v2/origin/custom/{scope_id}` (pega scope_id returnado).
3. Disparar WA teste pro +551138240025 (Bosch). Quando chegar webhook, capturar payload (ngrok ou webhook.site) e mandar pro Claudin.
4. Rodar `supabase db push` contra staging pra validar que as 2 migrations novas aplicam limpo.

**Opção B — Claudin executar M2 (paralelo, parcialmente bloqueado):**

```bash
cd C:\dev\dap4
# Branch já existe: feat/kommo-hub-phase1a (não criar de novo)
git branch --show-current   # confirm feat/kommo-hub-phase1a
npm test --prefix gateway   # confirm 10 green
```

Invocar `superpowers:executing-plans` com argumento focado em **M2 only** (gateway kommo.service.ts + kommo-webhook.routes.ts + config/kommo-pipelines). M2 pode começar sem credencial real usando mocks, mas o Gate M2 (replay fixture via curl) precisa fixtures reais → depende de Thales fazer Opção A item 3.

Recomendação: **Opção A primeiro** (desbloqueia M2 gate e valida M1 em prod). M2 pode arrancar em paralelo escrevendo código mas não fecha gate sem payload real.

## Setup / comandos úteis

```bash
# Verificar estado
cd C:\dev\dap4
git log --oneline rodada-0-foundation..HEAD   # 7 commits esperados
git branch --show-current                      # feat/kommo-hub-phase1a

# Rodar testes M0 (pytest)
cd agents && .venv/Scripts/python.exe -m pytest tests/test_fixtures_valid.py -v
# Esperado: 4 passed

# Rodar testes M1 (vitest)
cd gateway && npm test
# Esperado: 10 passed

# Ver migrations novas
ls supabase/migrations/
ls gateway/migrations/

# Aplicar contra Supabase staging (quando tiver CLI + project)
supabase db push --project-ref <STAGING_REF>

# Memória atualizada
cat C:/Users/docto/.claude/projects/C--Users-docto/memory/project_dap4_phase1a_ia_no_ar.md
```
