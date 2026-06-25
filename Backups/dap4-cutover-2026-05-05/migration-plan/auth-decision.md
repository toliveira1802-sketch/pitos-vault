# dap-operacao Auth — Decisão arquitetural (cutover SQLite→Supabase Postgres)

**Decisão:** Opção A — Manter `bcrypt + Express session`, apenas trocar o driver pra Supabase Postgres.

## 3 razões mais fortes

1. **Zero rewrite de auth, zero churn de testes.** Os 18 arquivos de teste usam o cookie `connect.sid` via `request.agent(app)`. Opção B explodiria todos eles + 13 route files que leem `req.session.organizationId`. Opção A: troca driver `better-sqlite3` por `postgres`/`pg`, mantém coluna `users.password`, deploya.
2. **Supabase Auth não paga sua complexidade aqui.** É serviço JWT/identity otimizado pra B2C com self-signup. dap-operacao tem ~5 staff por org, provisionados por admin — exatamente o workload onde `auth.users` + RLS adiciona superfície operacional (custódia JWT, debug de policy, split de schema entre `auth.*` e `public.*`) sem retorno. RLS faz sentido quando o cliente fala direto com Postgres; aqui já há Express forçando `WHERE organization_id = ?` em toda query via `tenantId(req)`. Cinto + suspensório = ok; suspensório + suspensório = template-default.
3. **Surface futura (WhatsApp, mobile, AIOS) não precisa de Supabase Auth.** São fluxos server-to-server / agent-to-server com credenciais próprias (API keys, service tokens, OAuth Meta). Magic link / SSO, quando chegarem, são bolt-on de 2 dias na rota existente (`/api/auth/magic-link`). Não pagar imposto de migração hoje por feature talvez-um-dia. YAGNI.

## Estimativa de rewrite de testes

**Zero testes rewritten na Opção A.** Apenas troca de driver — `setupFreshDb()` helper muda, schema migra de `sqlite-core` pra `pg-core` em `shared/schema.ts`. O contrato de session/cookie que os testes usam não muda.

Comparação: Opção B forçaria rewrite em **todos os 18 arquivos de teste** (cada `request.agent(app).post("/api/auth/login")` vira Supabase JWT mint + `Authorization: Bearer`) + `auth.test.ts` (8 casos redesenhados) + `auth-rate-limit.test.ts` (limiter retargeted).

## Rejeição das outras opções

- **Opção B (Supabase Auth full):** Paga semana de migração + 18 rewrites de teste pra resolver problema (RLS, MFA, magic link) que você não tem hoje e pode adicionar incrementalmente.
- **Opção C (híbrido Supabase Auth + public.users):** Pior dos dois mundos — carrega lock-in do Supabase Auth + custódia JWT *e* mantém join app-level de role/org. Identidade tem que ter uma única fonte da verdade.

## Arquivos relevantes

- `C:\THALES\DAP4\dap-operacao\server\routes\auth.ts` — login/logout/me, sem mudança em A
- `C:\THALES\DAP4\dap-operacao\server\middleware\auth.ts` — session requireAuth/requireRole, sem mudança
- `C:\THALES\DAP4\dap-operacao\client\src\lib\auth.tsx` — cookie-based auth context, sem mudança
- `C:\THALES\DAP4\dap-operacao\shared\schema.ts` — porta `sqliteTable` → `pgTable`, `integer` PKs → `serial`, `text` timestamps → `timestamptz`
- `tests/auth.test.ts` e `tests/auth-rate-limit.test.ts` — sem mudança
- 17 route files usando `tenantId(req)` — sem mudança

## Migration steps na Opção A

1. Trocar `connect-sqlite3`/memorystore por `connect-pg-simple` (session table no mesmo Supabase Postgres, único pool).
2. Porta `shared/schema.ts` de `drizzle-orm/sqlite-core` pra `drizzle-orm/pg-core`. Money fica `integer` (cents). Timestamps `text` → `timestamp with time zone` (one-time data migration).
3. Trocar driver em `server/storage.ts` de better-sqlite3 pra `postgres`/`pg` + drizzle pg adapter. Comportamento preservado.
4. Adicionar pooler URL Supabase (Transaction mode, port 6543) ao `.env`. Direct connection (5432) só pra migrations.
5. Rodar 117 testes contra schema Supabase de teste (`pg_temp` ou schema dedicado `test_*` com truncate em `setupFreshDb()`).

## Quando reabrir essa decisão (gatilhos, não datas)

- Portal customer-facing com self-signup → reconsiderar Supabase Auth pra essa surface só, manter operacao em sessions.
- Compliance MFA staff → adicionar TOTP nas rotas existentes (speakeasy, ~1 dia) antes de migrar pra Supabase Auth.
- 3ª organização com users cross-org → revisitar RLS especificamente.
