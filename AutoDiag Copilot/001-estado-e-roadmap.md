---
projeto: AutoDiag Copilot
tipo: estado-e-roadmap
status: doc vivo
atualizado: 2026-06-05
repo: C:/dev/autodiag-copilot
---

# AutoDiag Copilot — Estado & Roadmap

Doc vivo do estado do projeto. Volta pra [[000-index|Index]]. Arquitetura do motor em [[docs/2026-06-05-diagnostic-engine-build|Motor de Diagnóstico]].

## Onde estamos (06/2026)

Saiu da fase de **design** e entrou em **implementação**. O produto vertical-completo já existe ponta a ponta no working tree: landing → auth → garagem → scan (simulado, OBD real, import VCDS) → diagnóstico com agente IA → settings, tudo **offline-first** com sync. Suite **137/137 verde**, `tsc` limpo.

**Funciona ponta a ponta hoje** (local): cadastro/login → adiciona carro → roda scan (simulador, ou import de autoscan VCDS) → cai no diagnóstico → agente "Mestre Mecânico" monta o Roadmap de Oficina puxando dicionário + freeze-frame por ferramenta.

**Falta pra produção:** chaves de ambiente (Supabase service role, DATABASE_URL, ANTHROPIC, OPENAI), seed do `dtc_dictionary` com embeddings, deploy Vercel, e o teste de hardware do scanner físico (eaata).

> Nada commitado ainda — tudo no working tree. Primeiro commit/deploy é decisão do Thales.

## Estrutura do projeto

**Stack:** Next 15.1.6 (App Router) + React 19 · Tailwind v4 · Vercel AI SDK v4 + Anthropic (Sonnet 4.6) · OpenAI embeddings · Dexie/IndexedDB · Supabase/Postgres (schema `ferramentas`) + pgvector · Drizzle · pnpm-only.

### Camadas

| Camada | Onde | O quê |
|---|---|---|
| **Marketing** | `app/page.tsx`, `components/marketing/` | Landing (Hero, Nav) |
| **Auth** | `app/(auth)/`, `app/auth/callback/`, `components/auth/`, `lib/auth/` | Supabase SSR, login/signup/social, middleware |
| **Garagem** | `app/(app)/garage/`, `components/garage/` | Lista de carros, AddVehicleSheet, VehicleCard |
| **Veículo** | `app/(app)/vehicles/[id]/` | Specs, histórico de diagnósticos, soft-delete |
| **Scan** | `app/(app)/scan/` (+ `import/`, `ble-probe/`) | Simulador, OBD real (BLE), import VCDS, sonda BLE |
| **Diagnóstico** | `app/(app)/diagnostics/[id]/` | Detalhe DTC + chat streaming com o agente |
| **Settings** | `app/(app)/settings/` | Métricas Dexie, force sync, clear cache, export fila |
| **Agente/RAG** | `lib/rag/` (`agent/`, embed, retrieve, prompt, rate-limit) | Harness ReAct + 3 tools |
| **OBD/BLE** | `lib/obd/` | decode (puro), elm327, web-bluetooth, ble-inspect |
| **VCDS** | `lib/vcds/` | parser + normalize do autoscan |
| **Persistência scan** | `lib/diagnostics/` | persist compartilhado, freeze-frame por DTC |
| **Offline/Sync** | `lib/offline/` + `app/api/sync/{pull,push}` + `app/offline/` | Dexie, write-queue, sync-engine, conflict-resolver (LWW) |
| **API** | `app/api/` | `rag/query`, `sync/pull`, `sync/push` |
| **Schemas** | `lib/schemas/` | Zod, contrato único de fronteira |
| **DB** | `lib/db/schema.ts` + `supabase/migrations/0000–0005` | 6 tabelas, RLS, triggers |
| **UI kit** | `components/ui/` | Button, Card, Dialog, Sheet, Tabs, Toast, etc. |

### Dados — schema `ferramentas`

6 tabelas: `profiles`, `vehicles`, `diagnostics`, `diagnostic_dtcs`, `dtc_dictionary` (global), `sync_log`. IDs UUIDv7, soft-delete universal (`deleted_at`), colunas de sync (`local_id`, `synced_at`, `version`) p/ LWW. RLS por `auth.uid()` (defesa no Postgres, não na app). Migrations 0000–0005 (schema+extensões, tabelas, RLS, trigger de profile, proteção do plano, exposição PostgREST).

## Status por feature

| Feature | Status | Nota |
|---|---|---|
| Landing + Auth (Supabase SSR) | ✅ | login/signup/social/callback |
| Garagem + CRUD de veículo | ✅ | offline-first |
| Offline-first sync (Dexie + fila + LWW) | ✅ | pull/push + badge + service worker |
| Scan simulador (presets VAG) | ✅ | EA888, flaps, DSG, etc. |
| Diagnóstico + chat com agente | ✅ | streaming, roadmap 5 fases |
| Harness de agente (3 tools tipadas) | ✅ | lookup, semântico, freeze-frame |
| Transporte OBD-II BLE (ELM327) | ✅ código / ⏳ hardware | falta testar device real |
| Import VCDS/ODIS | ✅ | paste/upload → preview → grava |
| Sonda BLE (diagnóstico de conexão) | ✅ | rodar no eaata |
| Settings (métricas, sync, cache) | ✅ | — |
| Seed do `dtc_dictionary` + embeddings | ⏳ | `scripts/seed-dtc-dictionary.ts` existe; rodar |
| RAG sobre SOPs Bosch/OEM/DAP | 🔲 | hoje só dicionário; SOPs ainda não ingeridos |
| Billing/tiers (free/pro) | 🟡 | rate-limit tier-aware existe; sem Stripe |
| Deploy Vercel | 🔲 | faltam env keys |

Legenda: ✅ feito · 🟡 parcial · ⏳ pronto-falta-rodar · 🔲 não iniciado

## Próximas features (roadmap priorizado)

### Agora (desbloqueio)
1. **Teste de hardware do eaata** — rodar a [[docs/2026-06-05-diagnostic-engine-build|Sonda BLE]] no tablet; decidir BLE-GATT (fixar UUIDs) vs SPP clássico (seguir só VCDS).
2. **Env + seed + deploy** — preencher `.env.local`/Vercel, rodar `pnpm seed` (dicionário + embeddings), primeiro deploy de preview HTTPS.

### Curto prazo
3. **Descrições ricas do VCDS no prompt do agente** — passar o texto OEM da falha (mais rico que o dicionário genérico) pro agente.
4. **Ingestão de SOPs (RAG real)** — Bosch/OEM/DAP SOPs → embeddings → pgvector. Hoje o RAG só cobre o dicionário de DTC.
5. **Hybrid search (BM25 léxico + vetorial)** — essencial p/ números de peça e códigos de motor exatos.

### Médio prazo
6. **Billing (Stripe) + gate de tier** — free/pro já existe no rate-limit; falta cobrança.
7. **PWA polish** — install prompt, ícones, offline UX redonda.
8. **ELM327 BLE dedicado** (decisão de produto) — dongle simples desacoplado do eaata, se o live-scan portátil valer.

### V5 / depois
9. **Osciloscópio Web Serial** — leitura de forma de onda (Hantek) em Canvas. Adiado.
10. **IA local (Ollama/vLLM)** — rodar modelo local p/ privacidade/custo.
11. **Multi-user / oficinas** (v2 do design) · **i18n** · **mobile nativo**.

## Riscos & bloqueios abertos

- **eaata = incógnita BLE-GATT vs SPP** — bloqueia o live-scan do scanner físico até a sonda rodar.
- **RAG sem corpus** — sem seed do dicionário + ingestão de SOPs, a qualidade do agente é limitada ao conhecimento do modelo.
- **Web Bluetooth = só Chrome/Edge + HTTPS** — restringe o live-scan a esses navegadores em contexto seguro.

## Referências

- [[000-index|Index do projeto]]
- [[docs/2026-06-05-diagnostic-engine-build|Doc de arquitetura do motor]]
- [[specs/2026-04-17-autodiag-copilot-design|Design spec inicial]]
- [[../Inbox - Claudin/handoff-2026-06-05-1806-autodiag-agent-obd-vcds|Handoff 06/2026]]
- Repo: `C:/dev/autodiag-copilot` · Security review: `docs/security/2026-04-17-sprint-1-security-review.md`
