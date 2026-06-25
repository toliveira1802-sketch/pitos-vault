---
title: AutoDiag Copilot — Deploy Plan (Sennin Mode)
date: 2026-04-18
project: autodiag-copilot
status: ready-to-execute
tags: [deploy, supabase, rag, multi-tenant, rasengan-app]
---

# 🐸 AutoDiag Copilot — Deploy Plan

> **Eternizado antes do ataque.** Este é o log de arquitetura da build Rasengan pronta pra decolar em produção.

## Estado pré-deploy

### ✅ O que já está forjado (código commitado localmente)

| Camada | Entregável | Arquivo |
|--------|-----------|---------|
| **Schema multi-tenant** | `tenants`, `users`, `clients`, `vehicles`, `diagnostics`, `dtc_dictionary`, `rate_limit_calls` + RLS, trigger atômico de signup, `knowledge_base` com pgvector, RPC `match_knowledge_base`, RPC `rpc_rate_limit_check`, RPC `_touch_updated_at` | `supabase_schema.sql` |
| **Seed** | Tenant "Doctor Auto Prime" (pro) + 5 DTCs base | `supabase_seed.sql` |
| **Auth** | Signup atômico (tab "Criar Oficina") + login + invite via `?invite=UUID` | `js/auth.js` + `index.html` |
| **Offline engine** | IndexedDB (`autodiag-db`, stores `sync_queue` + `meta`), debounce 800ms, backoff exponencial 2s→60s, event bus, online/offline listeners | `js/diagnostic.js` |
| **RAG pipeline** | `text-embedding-3-small` (1536 dims) + `match_knowledge_base` (cosine similarity, threshold 0.7, top-5) + injeção no system prompt do GPT-4o-mini | `supabase/functions/copilot/index.ts` |
| **Embed knowledge** | Edge function com rate limit + validação rígida (title 2..200, content 20..8000, metadata ≤4KB) | `supabase/functions/embed_knowledge/index.ts` |
| **Auto-populate KB** | `finalizeDiagnostic()` → salva no banco → embed na `knowledge_base` com source `'diagnostic'` | `js/diagnostic.js` hook |
| **Network UX** | Pill reativo (online/offline/syncing + N pendentes), click-to-sync | `js/network-status.js` + CSS |
| **Skeleton loaders** | Shimmer bubble no chat durante RAG+LLM | `js/chat.js` |
| **Knowledge UI** | Card no dashboard + modal de cadastro manual + lista com preview | `js/knowledge.js` + modal em `index.html` |

### ❌ Bloqueadores ativos (pra destravar deploy)

| Item | Status | Precisa de |
|------|--------|------------|
| `js/env.js` | VAZIO | `SUPABASE_URL` + `SUPABASE_ANON_KEY` |
| Supabase CLI local | Não instalado | `npm i -g supabase` |
| Link do projeto | Nunca linkado | `supabase link --project-ref <REF>` |
| Secrets das edge functions | Não setados | `OPENAI_API_KEY` + `ALLOWED_ORIGINS` |
| Schema aplicado no Supabase | Não aplicado | Colar `supabase_schema.sql` no SQL Editor |
| Edge functions deployadas | Não deployadas | `supabase functions deploy` |

## Sequência de deploy (rigorosa — dependências lineares)

### Fase 0 — Pré-flight (zero risco, destravável pelo Thales)

1. **Criar projeto Supabase** se ainda não existe:
   - Dashboard → New Project → região `sa-east-1` (São Paulo) → senha do DB no 1Password
   - Aguarda ~2min pro projeto subir
2. **Coletar 4 valores-chave** do Dashboard → Project Settings:
   - `Project URL` (vira `SUPABASE_URL`)
   - `anon / public` key (vira `SUPABASE_ANON_KEY`)
   - Project ref (último segmento da URL; ex: `xxxxxxxxxxxx.supabase.co` → `xxxxxxxxxxxx`)
   - `OPENAI_API_KEY` (pegar no dashboard da OpenAI)

### Fase 1 — Schema (banco)

**AÇÃO**: Dashboard → SQL Editor → New query → colar todo o conteúdo de `supabase_schema.sql` → **Run**.

**Validação esperada**:
- Tabelas criadas: `tenants`, `users`, `clients`, `vehicles`, `diagnostics`, `dtc_dictionary`, `rate_limit_calls`, `knowledge_base`
- Extensões: `uuid-ossp`, `vector`
- Functions: `auth.user_tenant_id`, `public.handle_new_user`, `public.rpc_rate_limit_check`, `public.match_knowledge_base`, `public._touch_updated_at`
- Triggers: `on_auth_user_created` em `auth.users`, `trg_kb_updated_at` em `public.knowledge_base`
- Índices: `idx_kb_embedding` (ivfflat), `idx_kb_tenant`, `idx_diagnostics_*`, etc.

**Teste de idempotência**: rodar o mesmo script uma 2ª vez. Não deve errar. Se errar, é bug.

### Fase 2 — Frontend local (smoke-test antes de ir pra cloud)

1. `cp js/env.example.js js/env.js`
2. Preencher `js/env.js`:
   ```js
   window.__ENV__ = {
     SUPABASE_URL: 'https://<PROJECT_REF>.supabase.co',
     SUPABASE_ANON_KEY: 'eyJ...',
     PROD: false,
     ALLOWED_ORIGINS: ['http://localhost:8000', 'https://autodiag.doctorautoprime.com']
   };
   ```
3. Servir estaticamente: `python -m http.server 8000` (ou `npx serve .`)
4. Abrir `http://localhost:8000`
5. **Tab "Criar Oficina"** → preencher → deve criar tenant + admin atomicamente via trigger
6. Verificar no Table Editor do Supabase: `tenants` tem 1 row nova, `users` tem 1 row nova com `role='admin'`

### Fase 3 — Edge Functions (CLI)

```bash
# 3.1 — Instalar CLI (uma vez)
npm install -g supabase

# 3.2 — Login via browser (uma vez)
supabase login

# 3.3 — Link com o projeto (uma vez, dentro da pasta autodiag-copilot)
supabase link --project-ref <PROJECT_REF>

# 3.4 — Setar secrets (uma vez)
supabase secrets set OPENAI_API_KEY='sk-proj-...'
supabase secrets set ALLOWED_ORIGINS='http://localhost:8000,https://autodiag.doctorautoprime.com'

# 3.5 — Deploy ambas functions (toda vez que mudar código TS)
supabase functions deploy copilot
supabase functions deploy embed_knowledge
```

**Validação esperada**:
- `supabase functions list` mostra `copilot` e `embed_knowledge` como ACTIVE.
- Dashboard → Edge Functions → `copilot` → Logs vazio (sem erro startup).

### Fase 4 — Validação end-to-end (real-world)

| # | Teste | Esperado |
|---|-------|----------|
| 1 | Login com conta criada na Fase 2 | Avatar com iniciais no topbar + Pill verde "Online" |
| 2 | Ir em `/diagnostic` → preencher Fase 0 (modelo + sintoma) | Autosave silencioso (DevTools → Application → IndexedDB → `autodiag-db` → `sync_queue`) |
| 3 | DevTools → Network → Offline | Pill fica **vermelho "Offline — N pendentes"**, continua salvando local |
| 4 | DevTools → Network → Online | Pill passa por **laranja "Sincronizando 1"** → volta pra verde "Online". `diagnostics` na tabela tem row nova. |
| 5 | Ir em `/chat` → mandar "P0300 — motor trepidando" | Skeleton shimmer aparece → resposta em markdown renderizada. Response JSON tem `rag_matches: []` (ainda sem KB). |
| 6 | `/dashboard` → "Nova Dica / Macete" → título + conteúdo | Modal fecha, dica aparece como primeiro item do card "Base de Conhecimento" |
| 7 | Voltar ao `/chat` com mesma pergunta P0300 | Response agora tem `rag_matches` populado, resposta cita "(Caso 1, XX% similaridade)" |
| 8 | Finalizar um diagnóstico na Fase 6 com decisão | Próxima visita ao dashboard mostra esse caso na "Base de Conhecimento" com ícone de estetoscópio (source=diagnostic) |

## Contratos críticos (o que não pode quebrar)

### Contrato 1 — RLS
Zero leak cross-tenant. Testar: criar 2 oficinas, cada uma vê apenas os próprios diagnósticos. Nunca ver knowledge_base da outra.

### Contrato 2 — Idempotência do sync
Mesmo `client_uuid` escrito N vezes = 1 row no banco. Testar: desligar rede no meio do preenchimento → reconectar → só 1 row em `diagnostics` com esse uuid.

### Contrato 3 — Degradação graciosa do RAG
Se `text-embedding-3-small` der 500/timeout, copilot degrada pra non-RAG sem quebrar. Logs mostram warn, não error 500 pro cliente.

### Contrato 4 — Rate limit
31 chamadas/min no copilot = 429. Testar via curl com bearer token.

## Riscos residuais conhecidos

1. **IVFFlat index com 0 rows** — Postgres aceita mas queries retornam empty. Tudo ok até primeira inserção de embedding.
2. **Email confirmation do Supabase** — se estiver ON (default), signup pede confirmação por email antes de logar. `handle_new_user` só roda no INSERT em `auth.users`, que ocorre antes do confirm email — então tenant + user são criados mesmo que o email não seja confirmado. Trade-off: tenants órfãos possíveis se o usuário não confirmar. Mitigação futura: cron job de limpeza.
3. **Cold-start das edge functions** — primeira chamada após idle pode levar ~2-3s. O skeleton mascara isso. Se for problema, considerar keep-warm via cron.
4. **OPENAI_API_KEY custo** — embedding por query (input do usuário) + embedding por knowledge save. `text-embedding-3-small` ≈ $0.02/1M tokens. Rate limit protege.

## Próximas ondas (pós-deploy inicial)

- **Dashboard real-time**: substituir mock data em `dashboard.js` por query Supabase
- **Convites via email**: gerar links `?invite=UUID` e enviar por Resend/SendGrid
- **SRI pinning**: gerar hashes reais pras CDNs (FontAwesome, Chart.js, Supabase SDK, DOMPurify, marked)
- **PWA**: service worker + manifest pra instalação offline no celular do mecânico
- **Export**: PDF do diagnóstico finalizado
- **Analytics**: Plausible ou PostHog pra entender uso real

---

**Assinado**: Jiraya Sennin, sob orientação do Chairman Thales Oliveira.
**Commit hash de referência**: `d2dcccd` (feat: AutoDiag Copilot) + build Sennin desta sessão (ainda não commitado).
