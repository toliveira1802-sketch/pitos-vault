---
type: analysis
date: 2026-04-18
project: DAP4.0
topic: Merge forensics feat/kommo-prod-rc1 (a201387) pré-deploy
tags: [analysis, merge, dap4, kommo, pre-deploy]
---

# Merge Forensics — `a201387` (feat/kommo-prod-rc1)

**Parents:** `196a7b7` (feat/kommo-hub-phase1a · 15 audit fixes) × `210e6e7` (feat/whatsapp-kommo · CRM sync)
**Resultado do merge:** 19 arquivos tocados, +2626/-490 linhas
**Inspetor:** Claude (git forensics, 2026-04-17)

---

## 1. Resumo executivo

- **Verdict: GO com 1 gate operacional** — nenhum dos 15 audit fixes do Phase 1a foi perdido, modificado ou enfraquecido pelo merge. Diffs byte-idênticos em **todos** os arquivos de segurança/ops (kommo-webhook, kommo_chat, ana, rtbm_loader, tenant, anna-inbox.adapters, anna-result-handler, anna-inbox.worker, handoff-ttl.worker, 4 migrations).
- **0 riscos HIGH · 2 riscos MED · 2 riscos LOW.** O único risco que pode morder em produção é **dual-ingress**: legacy `/api/webhook/kommo/:secret` e novo `/api/kommo/webhook` (Hub HMAC) ficam ativos simultaneamente se ambos estiverem configurados na Kommo.
- **Top ação imediata pré-deploy:** decidir qual ingress é canônico na Kommo e **remover a outra URL do painel Kommo** (não o código — manter o código como fallback é ok). Recomendação: Hub é canônico; legacy só se Phase 1a vier com `USE_KOMMO_HUB=false`.
- **Conflitos resolvidos:** 5 arquivos (env.ts, index.ts, main.jsx, Agents.jsx, Layout.jsx). Todos resolveram por **união não-destrutiva** — Phase 1a env vars + whatsapp legacy vars coexistem; roteamento `/whatsapp` aponta pro novo `WhatsappKommo` com fallback `/whatsapp-meta` para o componente antigo.
- **Migrations limpas:** 4 migrations canônicas em `supabase/migrations/` (01/02/03 de 20260416 + 01 de 20260417). `gateway/migrations/` contém apenas `20260413_01_kommo_tables.sql` (Phase 0), **sem drift duplicado**.

---

## 2. Arquivos com resolução de conflito

| file | parent hub delta | parent whatsapp delta | merge result | notes |
|---|---|---|---|---|
| `gateway/src/config/env.ts` | +kommoChatsChannelSecret, +useKommoHub, +kommoDefaultBrand, +kommoChannelsRefreshMs, +kommoIntegrationSecret | +kommoWebhookSecret, +kommoExpectedSubdomain, +anaAutoreply | **União** — ambos os blocos presentes. Legacy URL-secret auth + novo HMAC secrets coexistem. | Dois caminhos de auth viáveis (risco MED abaixo). |
| `gateway/src/index.ts` | +raw-body capture pra HMAC, +Kommo Hub mount com YAML fallback + channel refresher, +Anna inbox worker, +handoff-TTL worker | +kommoSendRoutes import + mount `/api/kommo` authed, +`express.urlencoded` global pra legacy webhook | **União limpa** — raw-body JSON capture só em `/api/kommo/webhook` (path-scoped, antes do urlencoded global). kommoSendRoutes mount fica em `/api/kommo/conversations \| /messages \| /send \| ...`; Hub sobe em `/api/kommo/webhook`. Sub-paths disjuntos. | Ordem correta: express.json path-scoped (123,133) → urlencoded global (143) → Hub mount (263) → kommoSendRoutes com auth (368). |
| `agents/main.py` | — (sem delta) | `ThalesAgent()` sem args, drop RAGRetriever init | **Accept whatsapp** — bug fix preservado. | `c64a809 fix(agents): ThalesAgent() takes no args` carregou pro merge. Phase 1a não tocava este arquivo. |
| `dashboard/src/components/Layout.jsx` | +Parliament, +Scale icons, /command-center nav | (sem delta relativo ao merge-base) | **Accept hub (superset)** — todos os itens Phase 1a mantidos. | Diff vs 196a7b7 = vazio. |
| `dashboard/src/main.jsx` | `/command-center` route | `/whatsapp` → `WhatsappKommo` | **União** — `/whatsapp` → `WhatsappKommo` (novo), `/whatsapp-meta` → `WhatsApp` (legacy), `/command-center` → `LeadCommandCenter`. | Lazy import de `WhatsappKommo` adicionado. |
| `dashboard/src/pages/Agents.jsx` | (rename Sophia → 0613-B comments) | rewrite completo pra Sala do Conselho + CLevelRoom | **Accept whatsapp rewrite + patch label** — comentário "Sophia (CEO)" → "0613-B (External Presidency)" pra consistência com rename Phase 1a. | 457 linhas de diff (rewrite real). |
| `dashboard/src/components/CLevelRoom.jsx` | criado com label "0613-B · External Presidency" | criado com label "Sophia" | **Accept whatsapp + patch label** — mesmo rename. | Arquivo só existe no merge (união). |
| `dashboard/src/lib/api.js` | — | +`kommo` helper (status/conversations/messages/send/import/...) | **Accept whatsapp** — puramente aditivo. | Nenhum conflito semântico. |
| `gateway/src/services/realtime.ts` | — | +`kommoChatId?`, +`classification?` em `MessageEvent`; id/from/to viraram opcionais | **Accept whatsapp** | Widening de tipo — **compatível** com todos os callers antigos. Ver risco LOW abaixo. |

---

## 3. Verificação dos 15 audit fixes

Diff feito via `diff <(git show 196a7b7:<file>) <(git show a201387:<file>)`. Output vazio = byte-idêntico.

| # | commit | audit fix | status | evidência |
|---|---|---|---|---|
| 1 | 242deab | Pydantic regex `^[a-z0-9_]{1,64}$` em `KommoChatRequest.brand_id` | **PRESERVED** | `agents/api/routes/kommo_chat.py:55` — `Field(pattern=r"^[a-z0-9_]{1,64}$")` (diff vazio vs 196a7b7) |
| 2 | 242deab | `max_length=4096` em message + `ge=1` em kommo_lead_id | **PRESERVED** | `agents/api/routes/kommo_chat.py:56-57` |
| 3 | 242deab | `.dockerignore` exclui `scripts/playground-anna*` + `scripts/serve-playground.py` | **PRESERVED** | `agents/.dockerignore:3-5` (diff vazio) |
| 4 | 3252fbc | `system_prompt_override` per-call em `AnaAgent.process()` | **PRESERVED** | `agents/api/routes/kommo_chat.py:107` passa override; `agents/agents/ana.py` diff vazio vs 196a7b7 |
| 5 | 3252fbc | `pipelineFor(channelStore, brand_id)` helper em kommo-pipelines.ts | **PRESERVED** | `gateway/src/routes/kommo-webhook.routes.ts` importa de `../config/kommo-pipelines.js` (diff vazio) |
| 6 | 3252fbc | `Path.resolve()` + `is_relative_to` em `RtbmLoader` | **PRESERVED** | `agents/services/rtbm_loader.py:54-58` — `base.resolve()`, `path.resolve()`, path escape raise (diff vazio) |
| 7 | 3252fbc | Mesmo guard em `parliament/tenant.py` | **PRESERVED** | `agents/parliament/tenant.py:28-30` (diff vazio) |
| 8 | f491c96 | RLS NULL guards com `current_setting('app.current_tenant', true) IS NOT NULL AND <> ''` | **PRESERVED** | `supabase/migrations/20260416_01_anna_kommo_schema.sql:123-133` em 3 policies (anna_inbox, anna_conversations, kommo_channels) |
| 9 | f491c96 | Migrations wrap em `BEGIN`/`COMMIT` transacional | **PRESERVED** | 01 (L15+L173), 02 (L11+L51), 03 (L16+L28), 04 (L16+L67). Todas as 4. |
| 10 | f491c96 | Diretório canônico `supabase/migrations/` (sem mirror em gateway) | **PRESERVED** | `supabase/migrations/` tem os 4 files Phase 1a; `gateway/migrations/` só tem `20260413_01_kommo_tables.sql` (Phase 0, pré-Hub). Sem drift. |
| 11 | 723d21a | `sendKommoMessage` throws (sem fallback silencioso pra note) | **PRESERVED** | `gateway/src/routes/webhook.routes.ts:315-321` — `throw new Error("Kommo Talk API rejected send... message NOT delivered")` (merge adicionou só urlencoded parsing acima) |
| 12 | 723d21a | `replyDelivered: boolean` contract em `anna-result-handler` | **PRESERVED** | `gateway/src/services/anna-result-handler.ts:128` type, `:161` set, `:221` check, `:242` return (diff vazio vs 196a7b7) |
| 13 | 723d21a | Zod `AnnaHttpResponseSchema.safeParse` em adapter | **PRESERVED** | `gateway/src/workers/anna-inbox.adapters.ts:112` schema, `:144` safeParse (diff vazio) |
| 14 | e3b87b3 | `startHandoffTtlWorker` wired em `gateway/src/index.ts` | **PRESERVED** | `gateway/src/index.ts:33` import, `:337` start — inalterado pelo merge |
| 15 | e3b87b3 | Atomic claim via `rpc_anna_inbox_claim_next` (SECURITY DEFINER, FOR UPDATE SKIP LOCKED) | **PRESERVED** | `gateway/src/workers/anna-inbox.adapters.ts:52` `client.rpc("rpc_anna_inbox_claim_next")` + `supabase/migrations/20260417_01_anna_claim_rpc.sql` |

**Bonus preservado (replay defense do commit 3252fbc):** `createReplayCache` + TTL LRU em `kommo-webhook.routes.ts:148-180` (diff vazio). Nenhum fix caiu no merge.

---

## 4. Novos riscos introduzidos pelo merge

### MED-1 · Dual-ingress Kommo webhook

**File:** `gateway/src/routes/webhook.routes.ts:286` + `gateway/src/routes/kommo-webhook.routes.ts:203`
**Issue:** Depois do merge existem **dois** endpoints válidos pra Kommo postar:
- Legacy: `POST /api/webhook/kommo/:secret` — autentica via URL-secret + subdomain check, persiste em `kommo_conversations`/`kommo_messages`, chama `/agent/ana/classify`.
- Hub (Phase 1a): `POST /api/kommo/webhook` — autentica via HMAC-SHA1 no header `x-signature`, enfileira em `anna_inbox` para worker processar.

Se a config Kommo apontar pra ambos (ou se algum cliente ainda tiver a URL legacy), o mesmo evento WhatsApp dispara **duas pipelines**: classify-only no legacy + Anna chat no Hub. Resultado: dupla persistência em tabelas distintas, possível resposta automática dupla se `anaAutoreply=true`.
**Mitigação:** removível via config do painel Kommo, não precisa deploy. Decidir qual é canônico antes do go-live. `USE_KOMMO_HUB=true` + remover URL legacy do Kommo = caminho limpo.

### MED-2 · urlencoded global limit 10mb antes das auth'd routes

**File:** `gateway/src/index.ts:143`
**Issue:** Merge adicionou `app.use(express.urlencoded({ extended: true, limit: "10mb" }))` **global** (pra legacy webhook parsear `leads[update][0][id]=123`). Isso aplica a **todas** as rotas downstream incluindo `/api/kommo/send`, `/api/leads`, `/api/dashboard`. 10mb de body urlencoded é bem mais permissivo que os típicos 100kb — potencial DoS vector via body inflation em endpoints authed que não esperam urlencoded.
**Mitigação:** reduzir pra `limit: "1mb"` OU escopar só em `app.use("/api/webhook", express.urlencoded(...), webhookRoutes)`. Não bloqueia deploy; tratar em hotfix.

### LOW-1 · `MessageEvent` widening pode mascarar bugs de serialização

**File:** `gateway/src/services/realtime.ts:95-98`
**Issue:** `id`, `from`, `to` viraram opcionais em `MessageEvent`. TypeScript não vai mais reclamar se um caller esquecer de populá-los. É compat, mas reduz safety-net.
**Mitigação:** opcional — adicionar Zod no boundary de `emitMessage` se dor aparecer.

### LOW-2 · `/api/kommo` auth middleware cobre `/status` do kommo-send mas não `/webhook` do Hub

**File:** `gateway/src/index.ts:368` vs `:263`
**Issue:** `app.use("/api/kommo", authMiddleware, kommoSendRoutes)` vem **depois** do Hub mount (que é unauth + HMAC). Isso é correto — Express seleciona o primeiro match. Mas o Hub precisa estar mounted **antes** da linha 368. **Verificado:** Hub mount na linha 263, kommoSend na 368 — ordem correta.
**Mitigação:** nenhuma. Registrar como "verified" no runbook.

---

## 5. Route collision analysis

| path | handler | auth | corpo esperado | ordem no index.ts |
|---|---|---|---|---|
| `POST /api/webhook/kommo/:secret` | `webhook.routes.ts` legacy | URL-secret + subdomain | urlencoded (bracket keys) | L224, sem auth middleware (secret inline) |
| `POST /api/kommo/webhook` | `kommo-webhook.routes.ts` Hub | HMAC-SHA1 header | JSON (raw body captured) | L263, **gated por `config.useKommoHub`** |
| `GET /api/kommo/conversations` | `kommo-send.routes.ts` | authMiddleware | — | L368 |
| `GET /api/kommo/messages` | `kommo-send.routes.ts` | authMiddleware | — | L368 |
| `POST /api/kommo/send` | `kommo-send.routes.ts` | authMiddleware | JSON | L368 |
| `POST /api/kommo/messages/read` | `kommo-send.routes.ts` | authMiddleware | JSON | L368 |
| `GET /api/kommo/status` | `kommo-send.routes.ts` | authMiddleware | — | L368 |
| `GET /api/kommo/by-phone/:phone` | `kommo-send.routes.ts` | authMiddleware | — | L368 |
| `POST /api/kommo/import` | `kommo-send.routes.ts` | authMiddleware | JSON | L368 |
| `GET /api/kommo/conversations/:id/lead` | `kommo-send.routes.ts` | authMiddleware | — | L368 |

**Veredicto:** **Zero collision.** O Hub router só expõe `/webhook`; kommoSendRoutes expõe `/conversations`, `/messages`, `/send`, `/status`, `/by-phone`, `/import`. Sub-paths disjuntos. Express resolve na ordem — Hub fica antes (L263) e com early return; kommoSendRoutes no L368 com `authMiddleware` cobre o resto. Se `USE_KOMMO_HUB=false`, o path `/api/kommo/webhook` cai no 404 antes de chegar no kommoSendRoutes (que não define `/webhook`), o que é o comportamento correto.

---

## 6. Migration directory state

**Esperado:** `supabase/migrations/` contém 01/02/03 do 20260416 + 01 do 20260417, SEM mirrors em `gateway/migrations/`.

```
C:\dev\dap4\supabase\migrations\
  20260416_01_anna_kommo_schema.sql        ✓ BEGIN/COMMIT L15/L173, RLS NULL guards L123-133
  20260416_02_kommo_tables_extend.sql      ✓ BEGIN/COMMIT L11/L51
  20260416_03_fix_pipeline_seeds.sql       ✓ BEGIN/COMMIT L16/L28
  20260417_01_anna_claim_rpc.sql           ✓ BEGIN/COMMIT L16/L67, SECURITY DEFINER RPC

C:\dev\dap4\gateway\migrations\
  20260413_01_kommo_tables.sql             ✓ Phase 0 pré-Hub (esperado, byte-idêntico entre branches)
```

**Sem drift.** Phase 1a canonicalizou `supabase/migrations/` como o único diretório de verdade; o mirror em `gateway/migrations/` foi removido em `f491c96` e **não voltou** pelo merge. Dev-only test migration em `gateway/tests/migrations.test.ts` valida estrutura — não é DDL produtivo.

---

## 7. Recomendação final

### ✅ Deploy-ready — condicionado a 1 gate operacional

**Antes de acionar deploy em `76.13.170.42`:**

1. **[GATE] Decidir canonical ingress na Kommo:** só uma URL deve estar configurada no painel Kommo por número/pipeline. Recomendação: **novo Hub** (`/api/kommo/webhook` com HMAC), retirar URL legacy do painel. Manter código legacy como cold fallback é aceitável.
2. **[CONFIG] Confirmar env vars no `.env` da VPS:**
   - `USE_KOMMO_HUB=true`
   - `KOMMO_CHATS_CHANNEL_SECRET=<da Chats v2 channel config>`
   - `KOMMO_INTEGRATION_SECRET=<da Integração Chats v2>`
   - `KOMMO_DEFAULT_BRAND=dap_prime` (ou `dap_bosch`)
   - Opcional: `KOMMO_CHATS_CHANNEL_SECRET_OLD=<>` durante janela de rotação 24h
   - `ANA_AUTOREPLY=false` até Thales liberar (Phase 1a spec pede classify-only no rollout)
3. **[SMOKE]** Rodar `gateway/scripts/smoke-kommo-gate.ts` (Phase 1a test) pós-deploy — valida HMAC + enqueue + pg_notify em ambiente real.
4. **[OBSERV]** Confirmar `/metrics` expondo `kommo_hmac_failures_total` e `anna_inbox_pending` (scrape authenticated em prod).

### 🔧 Hotfixes recomendados pós-deploy (não bloqueantes)

- Reduzir limite global do `express.urlencoded` de 10mb → 1mb, ou escopar só em `/api/webhook` (MED-2).
- Adicionar health check específico pro Hub: `/api/kommo/webhook` GET → 405 (não 404) pra facilitar probe.
- Consolidar o legacy webhook + Hub num só caminho depois que 7 dias de tráfego real provarem o Hub em produção.

### ❌ Não deployar se

- Qualquer um dos 15 audit fixes tiver divergência com base Phase 1a (**já validado: nenhum divergiu**).
- `USE_KOMMO_HUB=true` sem `KOMMO_CHATS_CHANNEL_SECRET` (boot do gateway lança `throw` — fail closed, ok).
- Migration `20260417_01_anna_claim_rpc.sql` não aplicada antes de subir worker (runbook Phase 1a §M10 já cobre).

---

**Hash forense:** merge `a201387`, confirmado idêntico em disco a `git show a201387` em `c:\dev\dap4` @ 2026-04-17 21:27:36-03:00.
