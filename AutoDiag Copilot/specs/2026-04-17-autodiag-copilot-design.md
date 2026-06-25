# AutoDiag Copilot — Design Spec

**Data:** 2026-04-17
**Autor:** Thales Oliveira (CTO) + Claude (Sennin Mode)
**Status:** Draft for review

---

## 1. Visão de produto

AutoDiag Copilot é um SaaS B2C que transforma a leitura crua de um scanner OBD-II em diagnóstico acionável. O usuário conecta o scanner, lê os DTCs, e o app:

1. Interpreta cada código contra um dicionário técnico (`dtc_dictionary`)
2. Enriquece com RAG sobre manuais Bosch, fichas OEM e SOPs do ecossistema DAP
3. Sugere causas mais prováveis, próximos passos diagnósticos e custo estimado de reparo
4. Funciona offline-first — leitura embaixo do carro sem Wi-Fi não pode quebrar

### Persona-alvo
- **Primária:** entusiasta automotivo dono de alemão premium (BMW/Audi/MB/VW) que faz manutenção própria ou quer ferramenta para entender o que o mecânico está dizendo.
- **Secundária:** mecânico solo (sem oficina formal) trabalhando em garagem própria.
- **Não atende (v1):** oficinas com múltiplos atendentes — vertical B2B fica para v2 sobre o mesmo core.

### Modelo
- **Single-user puro:** cada usuário é dono dos próprios veículos e diagnósticos. Sem accounts compartilhadas, sem invites, sem workspaces. Simplicidade é feature.
- **Plans:** `free` (até 3 veículos, 50 diagnósticos/mês, sem RAG avançado) → `pro` (ilimitado + RAG completo + export).

---

## 2. Modelagem de dados — Postgres + RLS via `auth.uid()`

### Princípios estruturais

- **IDs:** UUIDv7 (ordenado temporalmente — index B-tree feliz, melhor que UUIDv4)
- **Soft delete universal:** `deleted_at TIMESTAMPTZ` com RLS filtrando `IS NULL`
- **Audit:** `created_at`, `updated_at` em todas; `created_by` quando relevante
- **Sync fields:** `local_id` (UUID gerado offline pelo client), `synced_at`, `version` (Lamport-ish para LWW)
- **Isolamento:** RLS direto via `user_id = auth.uid()` — sem custom JWT claim, sem middleware extra

### Schema

```sql
-- 1. profiles (extende auth.users com metadata de produto)
CREATE TABLE profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       CITEXT UNIQUE NOT NULL,
  full_name   TEXT,
  avatar_url  TEXT,
  plan        TEXT NOT NULL DEFAULT 'free',  -- free|pro
  settings    JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ
);

-- 2. vehicles (carros do usuário)
CREATE TABLE vehicles (
  id            UUID PRIMARY KEY DEFAULT uuidv7(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vin           TEXT,                            -- chassi 17 chars
  license_plate TEXT,
  nickname      TEXT,                            -- "Meu BMW", "330i da garagem"
  make          TEXT NOT NULL,                   -- BMW, Audi, Mercedes
  model         TEXT NOT NULL,
  year          SMALLINT,
  engine_code   TEXT,                            -- N20, B47, M276
  fuel          TEXT,                            -- gas|diesel|hybrid|ev
  notes         TEXT,
  local_id      UUID,                            -- id gerado offline
  synced_at     TIMESTAMPTZ,
  version       BIGINT NOT NULL DEFAULT 1,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at    TIMESTAMPTZ
);
CREATE UNIQUE INDEX vehicles_vin_unique
  ON vehicles(user_id, vin) WHERE vin IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX vehicles_user_idx
  ON vehicles(user_id) WHERE deleted_at IS NULL;
CREATE INDEX vehicles_local_idx
  ON vehicles(user_id, local_id) WHERE local_id IS NOT NULL;

-- 3. diagnostics (sessões de leitura do scanner)
CREATE TABLE diagnostics (
  id           UUID PRIMARY KEY DEFAULT uuidv7(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vehicle_id   UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  scanned_at   TIMESTAMPTZ NOT NULL,
  scanner_id   TEXT,                            -- mac/serial do scanner
  protocol     TEXT,                            -- ISO15765, KWP2000, UDS
  mileage_km   INTEGER,
  status       TEXT NOT NULL DEFAULT 'open',    -- open|in_progress|resolved|archived
  summary      TEXT,                            -- síntese do usuário
  ai_summary   TEXT,                            -- síntese RAG/LLM
  raw_payload  JSONB NOT NULL,                  -- dump bruto: DTCs, freeze frames, live data
  local_id     UUID,
  synced_at    TIMESTAMPTZ,
  version      BIGINT NOT NULL DEFAULT 1,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at   TIMESTAMPTZ
);
CREATE INDEX diag_vehicle_idx
  ON diagnostics(vehicle_id, scanned_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX diag_user_status_idx
  ON diagnostics(user_id, status, scanned_at DESC) WHERE deleted_at IS NULL;

-- 4. diagnostic_dtcs (DTCs específicos lidos numa diagnostic — junction com contexto)
CREATE TABLE diagnostic_dtcs (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  diagnostic_id    UUID NOT NULL REFERENCES diagnostics(id) ON DELETE CASCADE,
  dtc_code         TEXT NOT NULL REFERENCES dtc_dictionary(code),
  module           TEXT,                       -- ECM, TCM, ABS, BCM
  status_byte      TEXT,                       -- pending|confirmed|stored|history
  freeze_frame     JSONB,                      -- snapshot dos sensores no momento
  occurrence_count INT NOT NULL DEFAULT 1,
  cleared_at       TIMESTAMPTZ
);
CREATE INDEX diag_dtc_diag_idx ON diagnostic_dtcs(diagnostic_id);
CREATE INDEX diag_dtc_user_idx ON diagnostic_dtcs(user_id);

-- 5. dtc_dictionary (catálogo GLOBAL — não tem user_id, não tem RLS)
CREATE TABLE dtc_dictionary (
  code              TEXT PRIMARY KEY,            -- P0420, U0100, B1234
  category          TEXT NOT NULL,               -- powertrain|chassis|body|network
  short_description TEXT NOT NULL,
  long_description  TEXT,
  symptoms          TEXT[],
  common_causes     TEXT[],
  diagnostic_steps  JSONB,                       -- estrutura passo-a-passo
  affected_systems  TEXT[],
  severity          TEXT,                        -- info|warning|critical
  oem_specific      JSONB,                       -- {bmw: "...", audi: "...", mb: "..."}
  embedding         vector(1536),                -- pgvector (text-embedding-3-small)
  source            TEXT,                        -- Bosch|SAE|OEM
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX dtc_emb_idx ON dtc_dictionary USING hnsw (embedding vector_cosine_ops);
CREATE INDEX dtc_cat_idx ON dtc_dictionary(category);

-- 6. sync_log (audit + reconciliação)
CREATE TABLE sync_log (
  id                  UUID PRIMARY KEY DEFAULT uuidv7(),
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity              TEXT NOT NULL,              -- vehicles|diagnostics|...
  entity_id           UUID NOT NULL,
  op                  TEXT NOT NULL,              -- create|update|delete
  payload             JSONB NOT NULL,
  client_ts           TIMESTAMPTZ NOT NULL,
  server_ts           TIMESTAMPTZ NOT NULL DEFAULT now(),
  conflict            BOOLEAN NOT NULL DEFAULT false,
  conflict_resolution JSONB
);
CREATE INDEX sync_log_user_ts ON sync_log(user_id, server_ts DESC);
```

### RLS Policy Pattern (aplicado em `profiles`, `vehicles`, `diagnostics`, `diagnostic_dtcs`, `sync_log`)

```sql
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_select ON vehicles FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY user_modify ON vehicles FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

`dtc_dictionary` tem RLS de leitura apenas (`USING (true)` sem WITH CHECK) — somente service_role escreve.

### Trigger: criar `profile` ao signup

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## 3. Arquitetura Offline-First Write Queue

### Princípios

1. **Local é fonte da verdade durante operação.** Usuário não espera nada — IndexedDB é o store primário no client.
2. **Server é fonte da verdade do estado consistente.** Conflitos resolvem no server quando a queue sobe.
3. **Optimistic UI sem flicker:** IndexedDB write → UI update síncrono → enqueue → background sync.
4. **CRDT-light:** Last-Write-Wins por field com Lamport timestamp. Append-only log para entidades com merge complexo (ex: notas em uma `diagnostic`).

### Stack offline

- **Dexie.js** sobre IndexedDB — queries decentes, transações sãs, observable
- **Service Worker** com Workbox — PWA, cache de assets, Background Sync API, offline fallback de rotas
- **TanStack Query** com `persistQueryClient` apontado ao IndexedDB — cache em memória + persistência
- **Supabase Realtime** no canal `user:{user_id}` para invalidação granular do query cache

### Fluxo de mutação

```
[UI action]
    │
    ▼
[mutate() — TanStack Query]
    │   onMutate → optimistic update no cache
    ▼
[writeQueue.enqueue({op, entity, payload, client_ts, local_id, version})]
    │   IndexedDB transaction (atomic)
    ▼
[Local store updated]  ──────►  UI repinta (sub-16ms)
    │
    ▼
[syncWorker triggered]  ◄── online + auth válido + queue não-vazia
    │
    ▼
[POST /api/sync/push — batch ≤ 100 ops]
    │   Edge Function Deno (Supabase)
    ▼
[server transação por user]
    │   ─→ JWT valida via auth.uid()
    │   ─→ aplica op se version >= last_known_version
    │   ─→ se conflito: rule per-entity (merge field-level | LWW | review-queue)
    │   ─→ retorna {accepted[], conflicts[], id_map: local_id→server_id}
    ▼
[client reconcilia]
    │   ─→ remove ops aceitas da queue
    │   ─→ atualiza FKs local_id → server_id (UUIDv7 mantém ordem temporal)
    │   ─→ marca synced_at
    │   ─→ se conflito: toast + tela /sync/review com diff
```

### Conflict resolution rules

| Cenário | Regra |
|---|---|
| Update em campos diferentes | Auto-merge field-level por timestamp |
| Update no mesmo field | LWW por `client_ts`; perdedor vai pra `review_queue` se valor não-trivial |
| Delete + Update | Delete vence; update perdido logado em `sync_log.conflict_resolution` |
| Create duplicado (mesmo VIN, dois devices offline) | UNIQUE constraint dispara merge: junta no registro mais antigo, append nas notas |

### Pull side

- **Realtime:** WebSocket no canal `user:{user_id}` para invalidação granular do TanStack Query cache (Supabase Realtime escuta `INSERT`/`UPDATE`/`DELETE` nas tabelas RLS-scoped do user)
- **Fallback poll:** `GET /api/sync/pull?since=<server_ts>` com cursor incremental
- **Cold start:** snapshot dos últimos 90 dias paginado ao login

### Failure modes & recovery

- **Queue corruption:** Dexie schema migrations versionadas; se schema_version mismatch, queue é exportada para audit e zerada (com confirmação UI)
- **Auth expiration durante sync:** silent refresh via Supabase, retry com backoff exponencial (1s, 2s, 4s, 8s, max 60s)
- **Server 5xx:** ops voltam pra queue, retry no próximo sync window (a cada 30s online)
- **Permanente conflict (>3 retries):** entry vai pra `dead_letter_queue` (IndexedDB) + UI alert

---

## 4. Stack final

| Camada | Tecnologia | Razão |
|---|---|---|
| Frontend framework | Next.js 15 (App Router) + React 19 + TypeScript | RSC, streaming, ecosystem maduro |
| Styling | Tailwind v4 + shadcn/ui + framer-motion | Velocidade + qualidade + customização |
| State | TanStack Query (server) + Zustand (UI local) | Separação clara, sem Redux boilerplate |
| Offline | Dexie.js + Workbox SW | API ergonômica + PWA battle-tested |
| Backend | Supabase (Postgres 16 + Auth + Storage + Realtime + Edge Functions Deno) | All-in-one, RLS first-class, sem ops |
| ORM | Drizzle | Schema-as-code, migrations no repo, type-safe |
| Vector store | pgvector (mesma DB) | Sem ChromaDB separado, suficiente até 1M vectors |
| Embeddings | OpenAI `text-embedding-3-small` (1536 dims) | Custo/qualidade ótimo |
| LLM | Claude Sonnet 4.6 via Vercel AI SDK | Streaming, tool use, qualidade técnica |
| Auth providers | Email + Google + Apple | B2C friction reduction |
| Hosting | Vercel (frontend) + Supabase Cloud (backend) | Zero ops, autoscale |
| Observability | Sentry + Posthog + Supabase Logs | Errors + product analytics + DB |
| CI/CD | GitHub Actions | Push-to-deploy via Vercel integration |
| Testes | Vitest (unit) + Playwright (e2e) + Testing Library (component) | TDD-friendly |

---

## 5. Estrutura de pastas

```
autodiag-copilot/
├── app/                          # Next.js App Router
│   ├── (auth)/                   # login, signup, callback
│   ├── (app)/                    # rotas autenticadas
│   │   ├── garage/               # listagem de veículos
│   │   ├── vehicles/[id]/        # detalhe + histórico de diagnósticos
│   │   ├── diagnostics/[id]/     # detalhe da leitura + análise RAG
│   │   ├── scan/                 # nova leitura (Web Bluetooth flow)
│   │   └── settings/             # plan, account, sync status
│   ├── api/
│   │   ├── sync/push/            # Edge Function: write queue ingest
│   │   ├── sync/pull/            # Edge Function: incremental pull
│   │   └── rag/query/            # Edge Function: DTC enrichment
│   ├── layout.tsx
│   └── page.tsx                  # landing
├── components/
│   ├── ui/                       # shadcn primitives
│   ├── garage/                   # vehicle cards, list
│   ├── diagnostics/              # DTC list, freeze frame viewer
│   ├── scan/                     # bluetooth picker, live data charts
│   └── shared/                   # nav, header, sync badge
├── lib/
│   ├── db/
│   │   ├── schema.ts             # Drizzle schema (single source of truth)
│   │   ├── migrations/           # versioned SQL
│   │   └── client.ts             # postgres client
│   ├── offline/
│   │   ├── dexie.ts              # IndexedDB schema
│   │   ├── write-queue.ts        # enqueue/dequeue/retry
│   │   ├── sync-engine.ts        # push/pull orchestration
│   │   └── conflict-resolver.ts  # rules per-entity
│   ├── auth/
│   │   ├── supabase.ts           # browser client
│   │   ├── server.ts             # server client (RSC/route handlers)
│   │   └── middleware.ts         # session refresh
│   ├── rag/
│   │   ├── embed.ts              # OpenAI embeddings
│   │   ├── retrieve.ts           # pgvector similarity search
│   │   └── prompt.ts             # Claude prompt assembly
│   └── utils/
├── docs/
│   └── superpowers/
│       └── specs/
├── supabase/
│   ├── migrations/               # versioned SQL synced from Drizzle
│   ├── seed.sql                  # dtc_dictionary initial seed
│   └── config.toml
├── tests/
│   ├── unit/                     # Vitest
│   ├── integration/              # Vitest + test DB
│   └── e2e/                      # Playwright
├── public/
├── drizzle.config.ts
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── package.json
└── README.md
```

---

## 6. Tracks paralelas — Sprint 1 (deadline: 5 dias úteis)

### 🎨 Track DESIGNER (`hm-designer`)
**Objetivo:** Design system Deep Ebony + Glassmorphism. Componentes base prontos para o Engineer plugar.

Entregáveis:
- Design tokens (`color`, `typography`, `space`, `radius`, `shadow`, `motion`) em CSS vars + Tailwind v4 config
- Componentes shadcn customizados: Button, Input, Card, Sheet, Dialog, DataTable, Toast, Tabs, Badge
- Hero da landing + login/signup screens
- Microinterações framer-motion (page transitions, list staggers, scan-in animation)
- Dark-first com light opcional. Tipografia: Geist Sans + JetBrains Mono.

### ⚙️ Track ENGINEER (`hm-engineer`)
**Objetivo:** Bootstrap funcional do core. Auth + DB + Sync engine ready.

Entregáveis:
- Bootstrap Next.js 15 + Supabase + Drizzle + Tailwind v4
- Schema Drizzle das 6 tabelas + migrations + seed do `dtc_dictionary` (top 200 códigos)
- RLS policies em todas tabelas user-scoped
- Auth flow: signup/login Email + Google + Apple, trigger de profile creation
- Sync engine: Dexie schema, write queue, push/pull endpoints, conflict resolver (LWW + duplicate VIN merge)
- API routes: `/api/sync/push`, `/api/sync/pull`, `/api/rag/query`
- Service Worker registrado, PWA manifest, offline fallback de rotas

### 🛡️ Track QA (`hm-qa`)
**Objetivo:** Testes que importam + security review.

Entregáveis:
- Setup Vitest + Playwright + Testing Library
- Testes RLS isolation: user A não vê dados de user B (CRÍTICO — multi-user non-leakage)
- Testes conflict resolution: cada caso da tabela em §3 com fixtures
- Testes write queue: enqueue/dequeue/retry/dead_letter
- Schemas Zod validando boundaries (API request/response)
- Security review do Auth flow + Edge Functions (OWASP Top 10)
- E2E happy path: signup → add vehicle → simulate scan → see DTC interpretation

---

## 7. Princípios não-negociáveis

1. **Single-user clean.** Nada de account/tenant/org. Se aparecer pressão por compartilhamento, vai pra v2 como camada acima.
2. **Offline real, não bolt-on.** IndexedDB é o store primário. Sync é background. Servidor é eventual consistency.
3. **RLS é a defesa, não código de aplicação.** Se um endpoint vaza dado de outro user, é bug de policy — não de business logic.
4. **Type-safe end-to-end.** Drizzle schema → tRPC ou Server Actions → React. Zero `any`.
5. **TDD nos pontos críticos.** Sync engine, RLS, conflict resolution. Não merge sem teste.
6. **PWA installable desde dia 1.** Service Worker + manifest + offline fallback antes do segundo commit de feature.
7. **Sem mock sem honestidade.** Mock só quando isolar dependência externa real (OpenAI, scanner BLE). Nunca mocar Supabase em integração.

---

## 8. O que ESTÁ fora de escopo (v1)

- Compartilhamento de account / multi-user / oficinas (v2)
- Native mobile app (PWA cobre 90% no iOS/Android)
- Conexão direta com OBD-II (v1 = paste do JSON do scanner ou simulator; Web Bluetooth flow vem depois)
- Marketplace de oficinas / agendamento (v3)
- Subscription/billing (v1 = single plan free, billing entra quando atingir 100 users)
- Notificações push (v2)
- Internacionalização (PT-BR only no v1)

---

## 9. Métricas de sucesso (90 dias pós-launch)

- 500 signups
- 30% activation (signup → primeira scan completa)
- 60% W4 retention de usuários ativados
- < 1s p95 sync latency em conexão 4G
- < 100ms p95 render do diagnostic detail (offline cache hit)
- Zero incidents de cross-user data leak

---

## 10. Próximos passos

1. ✅ Spec aprovado (este doc)
2. ⏳ Spawnar tracks `designer` / `engineer` / `qa` em paralelo via worktrees
3. ⏳ Daily review dos PRs de cada track antes de merge no main
4. ⏳ Demo interna ao final do sprint 1
