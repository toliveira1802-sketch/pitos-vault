---
type: handoff
date: 2026-04-17
time: 20:35
project: DAP4.0
topic: Phase 1a audit fixes completos + descoberta de divergência prod vs branch
tags: [handoff, claudin, dap4, phase1a, kommo, audit, fixes, prod-divergence, blocker]
---

# Handoff — Phase 1a Kommo Hub: 15 blockers do audit fechados, mas prod está em branch divergente

## Contexto

Thales pediu `/orchestrate AUDITAR ANTES DE DEPLOY`. Sessão executou:

1. **Audit paralelo** (6 reviewers: security, typescript, python, database, dap-reviewer world-class, silent-failure-hunter) em `feat/kommo-hub-phase1a`. Identificou **15 blockers** pre-deploy.
2. **Fixes sequenciais** dos 15 blockers em 4 blocos (Multi-tenant, Segurança, DB, Silent failures + Ops + Docs). Tudo TDD — tests verdes a cada passo. Final: 103/103 gateway vitest + 47/47 parliament pytest + tsc clean.
3. **Tentativa de deploy** descobriu VPS em estado inesperado. Branch em produção é `feat/whatsapp-kommo` (outra!), não `feat/kommo-hub-phase1a`. Sessão parou pra decidir merge strategy — Thales pediu handoff.

**Branch local:** `feat/kommo-hub-phase1a` com 24 arquivos alterados, **não commitado ainda**.

## O que funcionou (com evidência)

- **Audit paralelo 6 agents em branch local** — 6 outputs estruturados CRITICAL/HIGH/MEDIUM/LOW consolidados em 15 tasks rastreáveis (#1–#15) + task #16 ship gate.
- **Multi-tenant contamination fix (#1 + #2 + #3 + #13)** — evidência: `agents/agents/ana.py` aceita `system_prompt_override`; `agents/api/routes/kommo_chat.py` Pydantic regex `^[a-z0-9_]{1,64}$` + max_length 4096 + passa prompt como param (sem mutar singleton); `gateway/src/routes/kommo-webhook.routes.ts` usa `pipelineFor(payload, channelStore)` com métrica `kommo_brand_resolve_fallback_total`; `rtbm_loader.py` e `parliament/tenant.py` com regex + path.resolve() guard contra traversal.
- **Segurança rápida (#10 + #11)** — `agents/.dockerignore` exclui `scripts/playground*` + `serve-playground.py` (ANTHROPIC_API_KEY não vaza pro prod image); `createReplayCache` LRU+TTL 5min wrappa a webhook com métrica `kommo_replay_blocked_total`. Teste novo `replayed signed payload within TTL → 200 + deduped + no second insert + replay metric` passa.
- **DB hardening (#5 + #6 + #7)** — migrations 01/02/03 wrapped em `BEGIN/COMMIT`; RLS policies agora `current_setting('app.current_tenant', true) IS NOT NULL AND <> '' AND tenant_id = ...` (NULL bypass fechado nas 5 tabelas); migration 03 virou unconditional UPDATE (idempotente, re-run safe); test fixture redirecionada de `gateway/migrations/` (mirror) pra `supabase/migrations/` (canônico) — os 3 mirrors drift-prone deletados; novo teste valida `BEGIN/COMMIT` em todas + 5 NOT NULL guards.
- **Silent failures (#8 + #12 + #14)** — `handleAnnaResult` retorna `{replyDelivered: boolean}`; worker `markDone` só se entregou, senão `markFailed` (+requeue), `recordAssistantTurn` só se entregou (não polui histórico); `parliament/archiver.py` checka `.error` de cada execute() + wrapped em try/except + `ArchiveError` propagado; `session_manager.record_decision` usa `asyncio.to_thread(archive, ...)` (não bloqueia event loop) + `assert` virou `RuntimeError` + empty quorum guard; `anna-inbox.adapters.ts` Zod `AnnaHttpResponseSchema.safeParse` (sem mais blind cast).
- **Ops (#4 + #9 + #15)** — `startHandoffTtlWorker` wireado no `gateway/src/index.ts` dentro de `USE_KOMMO_HUB` gated por `KOMMO_THALES_USER_ID/CHAT_ID`; nova migration `supabase/migrations/20260417_01_anna_claim_rpc.sql` com RPC `rpc_anna_inbox_claim_next()` SECURITY DEFINER + FOR UPDATE SKIP LOCKED + grant só pro service_role, `createInboxQueue` chama `supabase.rpc()` agora; `ops/GO_LIVE_RUNBOOK.md` ganhou Fases 9–12 cobrindo Kommo Hub (migrations, env vars Kommo, registrar canal Chats v2, smoke multi-tenant Bosch+Prime, rollback via `USE_KOMMO_HUB=false`, métricas pra observar, tech debt declarado).
- **Tests finais** — `npm test --prefix gateway` = 103 passed (9 files); `python -m pytest parliament/tests/ tests/test_fixtures_valid.py` = 47 passed. `npx tsc --noEmit` exit 0.
- **SSH VPS restaurado** — key `dap4_ed25519` tinha passphrase esquecida. Solução: registrar `~/.ssh/id_ed25519.pub` (key principal Thales) no `authorized_keys` do user `dap4` via root. Confirmado: `ssh dap4@76.13.170.42 -i id_ed25519` funciona.

## O que NÃO funcionou (e por quê)

- **Deploy Phase 1a direto na VPS** — falhou porque: prod em `/opt/doctor-auto-ai/` está em branch `feat/whatsapp-kommo` (commit `210e6e7 fix(whatsapp): review blockers B1 + I4 + I5`), não em `feat/kommo-hub-phase1a`. As branches divergiram: whatsapp-kommo tem CRM read-only + classify LIVE; kommo-hub-phase1a nasceu off `rodada-0-foundation` com 1 migration cherry-picked da whatsapp-kommo. **Mergear é obrigatório antes de deploy** senão perde o CRM sync atual ou quebra o stack.
- **`~/dap4/` no VPS vs `/opt/doctor-auto-ai/`** — dois checkouts do mesmo repo no VPS. `~/dap4/` (user dap4) está em `master @ f17f819` (abr 9, antes de QUALQUER trabalho Kommo). `/opt/doctor-auto-ai/` (root) é o path canônico onde os containers realmente rodam. Runbook original assumia `~/dap4/` — **runbook está desatualizado pra esta realidade**.
- **Stack usa Caddy, não Cloudflare Tunnel direto pro gateway** — `doctor-auto-ai-caddy-1` é reverse proxy; runbook documenta Cloudflare Tunnel direto. Tech debt pra alinhar docs vs realidade.
- **sudo sem NOPASSWD pro user dap4** — pra inspecionar `/opt/doctor-auto-ai/` (owner root) precisa SSH como root com key id_ed25519 em vez de sudo. Contornamos, mas operacional ruim.

## O que ainda não foi tentado

- **Commit dos 24 arquivos local** — Thales quer revisar o diff antes. Estratégia proposta: 6 commits semânticos (multi-tenant / segurança / DB / silent failures / ops / runbook).
- **Push pra origin** — bloqueado no passo acima.
- **Comparar `feat/whatsapp-kommo` vs `feat/kommo-hub-phase1a`** — não rodado ainda. `git merge-base` no VPS iria responder se é merge trivial ou perigoso. Comando preparado mas Thales pausou.
- **Kommo tokens no `.env.production`** — status no VPS: `grep -c '^KOMMO\|^USE_KOMMO' .env.production` retornou output cortado. Provavelmente só 2 vars. Precisa adicionar 6+ (ver Fase 10 runbook).
- **Migrations Phase 1a em prod Supabase** — não aplicadas. `20260416_01_*`, `_02_*`, `_03_*`, `20260417_01_*` existem no repo mas não no Supabase staging/prod.
- **Registrar canal Chats v2 no Kommo** — não feito. Bloqueia smoke end-to-end.
- **Backup Supabase point-in-time** — não verificado se foi tirado recentemente. Obrigatório antes de aplicar migrations (5911 leads em risco).

## Arquivos tocados (local — `C:\dev\dap4\`, branch `feat/kommo-hub-phase1a`)

| Arquivo | Status | Notas |
|---------|--------|-------|
| `agents/agents/ana.py` | M | `system_prompt_override` param (+5/-2) |
| `agents/api/routes/kommo_chat.py` | M | Pydantic constraints + remove mutação singleton (+22/-11) |
| `agents/parliament/archiver.py` | M | `_check` + `ArchiveError` + try/except wrap (+67/-15) |
| `agents/parliament/session_manager.py` | M | asyncio.to_thread + empty quorum guard + assert→raise (+22/-6) |
| `agents/parliament/tenant.py` | M | Regex + path.resolve guard (+13/-1) |
| `agents/services/rtbm_loader.py` | M | Regex + path.resolve guard + InvalidBrandError (+14/-2) |
| `agents/.dockerignore` | ?? new | Exclude playground + .venv + tests + secrets |
| `gateway/src/index.ts` | M | Wire startHandoffTtlWorker + channelStore param (+22) |
| `gateway/src/routes/kommo-webhook.routes.ts` | M | pipelineFor + createReplayCache + replayCache check (+57/-10) |
| `gateway/src/services/anna-result-handler.ts` | M | AnnaResultOutcome + replyDelivered tracking (+75/-19) |
| `gateway/src/workers/anna-inbox.adapters.ts` | M | RPC rpc_anna_inbox_claim_next + Zod parse (+34/-40) |
| `gateway/src/workers/anna-inbox.worker.ts` | M | finishOrRetry logic + AnnaResultOutcome flow (+28/-10) |
| `gateway/scripts/smoke-kommo-gate.ts` | M | ChannelStore seed + channelStore dep (+14) |
| `gateway/tests/anna-inbox-worker.test.ts` | M | Delivery failure tests (+32/-5) |
| `gateway/tests/anna-result-handler.test.ts` | M | Update assertions pro replyDelivered contract (+11) |
| `gateway/tests/kommo-webhook.test.ts` | M | channelStore + replayCache + 2 novos testes (+89) |
| `gateway/tests/migrations.test.ts` | M | MIG_DIR_SUPABASE + NOT NULL guards test + BEGIN/COMMIT test (+42/-15) |
| `gateway/migrations/20260416_01_anna_tables.sql` | D | Mirror deletado |
| `gateway/migrations/20260416_02_kommo_tables_extend.sql` | D | Mirror deletado |
| `gateway/migrations/20260416_03_fix_pipeline_seeds.sql` | D | Mirror deletado |
| `supabase/migrations/20260416_01_anna_kommo_schema.sql` | M | BEGIN/COMMIT + RLS NOT NULL guards (+17/-10) |
| `supabase/migrations/20260416_02_kommo_tables_extend.sql` | M | BEGIN/COMMIT + RLS NOT NULL guards (+13/-9) |
| `supabase/migrations/20260416_03_fix_pipeline_seeds.sql` | M | Unconditional UPDATE idempotent (+11/-5) |
| `supabase/migrations/20260417_01_anna_claim_rpc.sql` | ?? new | Atomic claim RPC via FOR UPDATE SKIP LOCKED |
| `ops/GO_LIVE_RUNBOOK.md` | M | Fases 9–12 Kommo Hub (+237/-2) |
| `dashboard-git` | M | Submodule dirty — não tocado nesta sessão, pre-existente |

**Totais:** 24 modificados + 3 deleted + 3 new = **+845 / -365**.

## Decisões tomadas

- **Branch strategy:** não commitar ainda — Thales quer revisar diff primeiro, dividir em 6 commits semânticos (multi-tenant/segurança/DB/silent/ops/runbook).
- **Multi-tenant fix via override parameter** — em vez de `contextvars.ContextVar` ou outro mecanismo elaborado. Razão: minimalismo, cada chamada Kommo tem o prompt próprio e não polui singleton.
- **Path traversal defense in depth** — mesmo com Pydantic constraining o endpoint, os loaders (rtbm_loader, tenant) validam o input interno. Razão: outros callers podem existir no futuro; loader não deve assumir input seguro.
- **Replay cache in-process em vez de Redis** — Phase 1a aceita o gap de TTL pós-restart (DB dedup cobre). Razão: sem Redis hoje; adicionar dep pra isso em Phase 1a é overkill.
- **Migration 03 unconditional UPDATE em vez de ON CONFLICT upsert** — `kommo_channels` tem outros NOT NULL (pipeline_id, prompt_file) que o upsert não tem como preencher sem refeir o seed. Razão: idempotência via UPDATE direto, assumindo que 01 já seedou as linhas (testado).
- **Atomic claim via RPC SECURITY DEFINER** — em vez de advisory lock por hash de brand_id. Razão: FOR UPDATE SKIP LOCKED é o padrão Postgres pra filas; cross-instance safe sem contenção.
- **Runbook como append Fases 9–12** em vez de rewrite — preserva contexto histórico Meta/WhatsApp direto (que pode voltar a ser usado) e deixa Kommo Hub como aumento explícito.
- **SSH via `id_ed25519` registrada no user `dap4`** — em vez de recuperar passphrase da `dap4_ed25519`. Razão: Thales esqueceu passphrase, key inútil; plus: simplifica gestão (1 key pra tudo).
- **NÃO mexer na divergência whatsapp-kommo vs kommo-hub-phase1a agora** — decisão do Thales: pausa pra handoff antes de decidir merge strategy. Opções abertas: A (substituir), B (merge), C (coexistir). Preferência minha: B.

## Bloqueios & perguntas abertas

### Bloqueadores humanos (Thales) — ordem de execução:

1. **Decidir merge strategy** prod (`feat/whatsapp-kommo`) ↔ fixes (`feat/kommo-hub-phase1a`):
   - A) Substituir (arriscado — perde CRM sync live)
   - B) Merge → release branch `feat/kommo-prod-rc1` (**recomendado**)
   - C) Coexistir (complexo, divide DB state)
2. **Revisar diff local** e decidir commit strategy (1 commit gigante vs 6 semânticos — eu sugiro 6)
3. **Gerar tokens Kommo** (6 vars): `KOMMO_TOKEN`, `KOMMO_DOMAIN`, `KOMMO_CHATS_CHANNEL_SECRET`, `KOMMO_INTEGRATION_SECRET`, `KOMMO_THALES_USER_ID`, `KOMMO_THALES_CHAT_ID`
4. **Backup Supabase point-in-time** antes de aplicar migrations (proj `acuufrgoyjwzlyhopaus`, 5911 leads)
5. **Registrar canal Chats v2 no Kommo** (Fase 11 do runbook)
6. **RTBM docs reais** — `agents/config/rtbm/dap_prime.md` + `bosch.md` (conteúdo é do Thales)

### Perguntas abertas:

- **`dashboard-git` submódulo dirty** no `git status` — tem trabalho não-commitado lá? Ignorar ou limpar?
- **`.superpowers/` untracked** — `.gitignore` ou deletar?
- **Runbook assume `~/dap4/` mas prod usa `/opt/doctor-auto-ai/`** — atualizar runbook pra refletir realidade ou migrar prod pro `~/dap4/`?
- **Prod usa Caddy; runbook documenta Cloudflare Tunnel + nginx** — tech debt: alinhar.
- **`feat/whatsapp-kommo` tem todas as fixes do audit?** Improvável — fixes foram no kommo-hub-phase1a. Se merge for feito, os 15 fixes precisam aplicar depois do merge também.

## Próximo passo exato

**Opção recomendada (B — merge):**

1. Na sessão nova, rodar:
   ```powershell
   cd C:\dev\dap4
   git fetch origin
   git log --oneline origin/feat/whatsapp-kommo..feat/kommo-hub-phase1a 2>&1 | head -20
   git log --oneline feat/kommo-hub-phase1a..origin/feat/whatsapp-kommo 2>&1 | head -20
   ```
   Pra ver o que cada branch tem que a outra não tem.

2. Commitar os 15 fixes locais em 6 commits semânticos na própria `feat/kommo-hub-phase1a`:
   - `fix(security): constrain KommoChatRequest + block path traversal`
   - `fix(multitenant): remove singleton mutation + pipelineFor in webhook`
   - `fix(db): RLS NULL guards + transactional migrations + migration 03 upsert`
   - `fix(silent): propagate delivery failure + archiver error checks + Zod Anna response`
   - `fix(ops): wire handoff-TTL + atomic claim RPC + dockerignore playground`
   - `docs(runbook): Phases 9–12 for Kommo Hub Phase 1a`

3. Criar release branch `feat/kommo-prod-rc1`:
   ```powershell
   git checkout -b feat/kommo-prod-rc1 feat/kommo-hub-phase1a
   git merge origin/feat/whatsapp-kommo --no-ff -m "merge: whatsapp-kommo CRM sync into kommo-hub-phase1a"
   # resolver conflitos manualmente (provavelmente em kommo_conversations + kommo_messages migrations e routes)
   ```

4. Rodar tests completos no rc1 — 103+47 + testes da whatsapp-kommo (a descobrir).

5. Push + deploy conforme Fases 9–12 do runbook, com ajuste de path `/opt/doctor-auto-ai/` em vez de `~/dap4/`.

**Opção paralela enquanto decide:** Thales pode ir gerando os tokens Kommo no portal e pegando o backup Supabase — não bloqueiam o merge, só o deploy final.

## Setup / comandos úteis

```bash
# Estado local
cd C:\dev\dap4
git status
git log --oneline -10   # feat/kommo-hub-phase1a @ d235c60
git diff --stat         # +845 / -365 em 24 arquivos

# Tests verdes (sanity)
cd gateway && npm test              # 103 passed
cd ../agents && python -m pytest parliament/tests/ tests/test_fixtures_valid.py -q   # 47 passed

# SSH VPS (use key principal, dap4_ed25519 tem passphrase esquecida)
ssh dap4@76.13.170.42 -i C:\Users\docto\.ssh\id_ed25519    # user dap4
ssh root@76.13.170.42 -i C:\Users\docto\.ssh\id_ed25519    # root (pra /opt/doctor-auto-ai/)

# Estado prod atual
ssh root@76.13.170.42 -i C:\Users\docto\.ssh\id_ed25519 "cd /opt/doctor-auto-ai; git branch --show-current; git log --oneline -3"
# Retorna: feat/whatsapp-kommo @ 210e6e7

# Containers prod
ssh dap4@76.13.170.42 -i C:\Users\docto\.ssh\id_ed25519 "docker ps --format 'table {{.Names}}\t{{.Status}}'"
# doctor-auto-ai-{caddy,gateway,python-agents,chromadb} + dashboard-evolution (separate project)

# Tasks rastreadas (sessão)
# #1–#15 completed + #16 ship gate completed (local apenas; prod deploy ainda bloqueado)
```

## Tasks pendentes não no scope de blockers (pós-deploy)

Do audit, listado como HIGH/MEDIUM não-bloqueadores (devem virar issues separadas):

- Webhook timestamp validation (H1 do audit — replay cache mitiga parcial, timestamp header full)
- `notify()` em vez de só logger.info — disparar pg_notify real via Supabase Realtime (dap-reviewer H2)
- `addTag` em `kommo.service.ts` é replace, não additive — perde tags pré-existentes (dap-reviewer H6)
- Anna ignora mídia (foto/áudio/PDF) — markDone silencioso (dap-reviewer H4)
- `asInt` aceita string com `-` no início (lead_id negativo passa) — dap-reviewer MED
- `typingDelayMs` fixo em ms/char ignora cultura BR mensagens curtas
- `/metrics` exposição via API_SECRET — sem IP allowlist pro Prometheus
- RTBM loader sync ChromaDB bloqueia event loop (python-reviewer MED) — asyncio.to_thread em `_retrieve_context`
- `record_decision.supabase=None` untyped — Optional[SupabaseClient]
- Rate limit middleware in-memory unbounded (python-reviewer HIGH — migrar pra Redis em produção sustentada)
- `dap.yaml` tenant config com métricas business em plaintext (current_revenue, capacity) — LOW mas considerar env-injected
