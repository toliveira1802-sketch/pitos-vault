---
type: handoff
date: 2026-05-07
time: 11:27
project: dap-gestao (standalone)
topic: ADR-001 Auth Unification Fase 3 — entregue end-to-end, working tree clean
tags: [handoff, claudin, dap-gestao, supabase-auth, adr-001]
---

# Handoff — dap-gestao: Supabase Auth Fase 3 entregue

## Contexto

`C:\THALES\DAP4\dap-gestao` é o portal executivo do ecossistema DAP4.0
(P0). Antes da sessão tinha bcrypt + express-session + memorystore, igual ao
dap-operacao. Thales decidiu unificar identidade dos 3 portais sob Supabase
Auth (DOCTOR PRIME, project `acuufrgoyjwzlyhopaus`), seguindo o padrão do
`portal-familia` no P1 — bypass total de `supabase.auth.*` no client +
GoTrue REST direto + custom fetch que sempre sobrescreve Authorization
(senão Navigator Lock bug, vide `feedback_supabase_lock_deep_bug`).

Decisão completa em `docs/adrs/0001-auth-unification.md` (markdown +
row em `gestao.adrs.id=1`). Status `accepted`. Outcome preenchido em
2026-05-06.

## O que funcionou (com evidência)

- **Schema** (commit `512088a`) — `gestao.users` ganhou
  `auth_user_id uuid NULL UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL`,
  `password` virou nullable. PK integer preservada (FK em outras tabelas
  intacta).
- **Backend JWT** (commit `de68af1`) — `server/middleware/auth.ts` valida
  JWT via `supabase.auth.getUser(jwt)` com **fallback pra session legacy**
  durante coexistência. Popula `req.user = { id, email, role,
  organizationId, authUserId }`. `requireRole` adota mesmo fallback.
  `routes/auth.ts /api/auth/me` prioriza JWT; `/api/auth/login` devolve
  `MIGRATED_TO_SUPABASE` pra contas que já trocaram. CSP `connect-src`
  liberou domínio Supabase.
- **Test backend** — `tests/auth-jwt.test.ts` cobre 4 caminhos do
  middleware (JWT ok, JWT inválido + session, JWT sem profile + session,
  ambos faltando).
- **Frontend client** (commit `de68af1`) — `lib/supabase.ts` com
  `persistSession:false` + `autoRefreshToken:false` + custom fetch que
  sempre sobrescreve Authorization quando há user token. `lib/authStore.ts`
  manual em localStorage (`STORAGE_KEY = 'dap-gestao-auth'`) com refresh
  agendado 60s antes de expirar e dedupe in-flight via Promise singleton.
  `features/auth/authService.ts` chama GoTrue REST direto (login, logout,
  recover, magic link, OAuth Google, updatePassword).
- **AuthProvider** (commit `de68af1`) — `lib/auth.tsx` lê `authStore`,
  busca profile em `/api/auth/me` (combina JWT + `gestao.users.role`).
  `queryClient.ts` injeta Authorization em `apiRequest` e `queryFn`.
- **Login UI** (commit `de68af1` + `43e8d45`) — email+senha, magic link,
  esqueci senha, botão Google atrás de flag `GOOGLE_OAUTH_ENABLED=false`
  (Thales decidiu v1 só email+senha+magic link).
- **Reset password flow** (commit `43e8d45`) — `lib/auth-hash.ts`
  `consumeAuthCallbackHash()` rodado em `main.tsx` ANTES do React montar:
  consome tokens do fragment GoTrue, salva em `authStore`, redireciona
  pra `/reset-password` se `type=recovery`. Resolve conflito de "two
  hashes" com `useHashLocation` do wouter. `pages/reset-password.tsx`
  formulário standalone que lê sessão direto do `authStore` (não do
  AuthProvider — durante recovery, profile pode não existir ainda).
  `App.tsx` renderiza Router fora do AppShell pra `/reset-password`
  funcionar sem profile autenticado.
- **SMTP custom Resend** ativo: `noreply@doctorautoprime40.com` com
  DKIM/SPF verificados, templates PT-BR DAP brand. Recepção admin via
  Cloudflare Email Routing → Gmail.
- **RLS** — 20 policies tenant-scoped em `oficina.*` + `gestao.*`. Helper
  `current_user_org_id()` SECURITY DEFINER per schema. Service_role ainda
  bypassa (backend não trocou pra anon+JWT — Fase deferred).
- **ADR Implementation outcome preenchido** (commit `64560a6`) — seção
  parcial 2026-05-06 marcando o entregue + listando deferred.

**Final: 5 commits sobre `c976c11` (estado quando subtree-merged no
dap4-portals), pushed pra master, working tree clean.**

## O que NÃO funcionou (e por quê)

- **Tentar usar `@supabase/ssr` no client** — descartado antes mesmo de
  começar; depende internamente de `supabase.auth.*` que tem o Navigator
  Lock bug (PKCE + autoRefreshToken hang). Padrão portal-familia evita
  totalmente.
- **Persistir session via supabase-js native** — Navigator Lock no PKCE
  flow trava em Chrome real (validado em 6 rounds no P1, commit `e93fcca`).
  Solução é `persistSession:false` + authStore manual.
- **OmiTtir custom fetch override do Authorization** — sem ele, supabase-js
  injeta o anon key e RLS bloqueia tudo. Fix copiado verbatim do P1.

## O que ainda não foi tentado (deferred)

- **Drop `bcryptjs` + `express-session` + `memorystore` deps + drop coluna
  `password`** — bloqueado até admin Thales validar login end-to-end nos 2
  portais (gestao + operacao). Fase 6 do épico.
- **Cookie domain `.doctorautoprime40.com`** pra SSO cross-subdomain — v2.
  Hoje cada portal tem seu localStorage scoped por subdomínio; usuário
  loga 1× por portal.
- **Google OAuth ativo** — código existe via `GOOGLE_OAUTH_ENABLED` flag.
  Ativar = trocar flag + criar OAuth Client no Google Cloud + ativar
  provider no Supabase Dashboard.
- **MFA TOTP** — opcional v1, obrigatório admin/cfo v2.
- **Backend service_role → anon+JWT** — RLS hoje só no app, não no banco.
- **Apple/Microsoft OAuth** — avaliar quando houver demanda.
- **Test auth-jwt no dap-operacao** — deferred porque mock de
  `supabase.auth.getUser` exigia stub de GoTrue.

## Arquivos tocados (commits 9c7af1b..64560a6)

| Arquivo | Status | Notas |
|---|---|---|
| `docs/adrs/0001-auth-unification.md` | Completo | Status accepted, outcome preenchido |
| `shared/schema.ts` | Completo | `authUserId` field + nullable password |
| `server/middleware/auth.ts` | Completo | JWT validation + session fallback |
| `server/routes/auth.ts` | Completo | `/api/auth/me` JWT-first; login devolve `MIGRATED_TO_SUPABASE` |
| `server/index.ts` | Completo | CSP connect-src libera Supabase |
| `tests/auth-jwt.test.ts` | Completo | 4 cenários do middleware |
| `client/src/lib/supabase.ts` | Completo | createClient com custom fetch |
| `client/src/lib/authStore.ts` | Completo | localStorage manual + refresh agendado |
| `client/src/lib/auth.tsx` | Completo | AuthProvider lê authStore + /api/auth/me |
| `client/src/lib/auth-hash.ts` | Completo | consumeAuthCallbackHash() pré-React |
| `client/src/lib/queryClient.ts` | Completo | Authorization injection |
| `client/src/features/auth/authService.ts` | Completo | GoTrue REST direto |
| `client/src/main.tsx` | Completo | Bootstrap auth-hash antes do Router |
| `client/src/App.tsx` | Completo | Router fora do AppShell pra /reset-password |
| `client/src/pages/login.tsx` | Completo | Email+senha+magic+recover, Google flag-off |
| `client/src/pages/reset-password.tsx` | Completo | Form standalone, lê authStore direto |
| `.env.example` | Completo | Vars Supabase documentadas |

## Decisões tomadas

- **Bypass total de `supabase.auth.*` no client** — herda padrão validado
  do `portal-familia` (P1). Custom fetch + authStore + GoTrue REST.
- **PK integer preservada em `gestao.users`** — trocar pra uuid arrastaria
  FK em N tabelas. `auth_user_id uuid UNIQUE` é o link real pra
  `auth.users`. ADR-001 chamou de "levemente impuro mas aceito".
- **`bcryptjs` + `express-session` ficam no package.json durante
  coexistência** — drop completo na Fase 6 quando admin validar.
- **Google OAuth desativado v1** — só email+senha+magic link no v1
  (Thales 2026-05-06).
- **Service_role mantém em backend pra Fase 3** — trocar pra anon+JWT é
  Fase 5+. RLS hoje protege na camada app.
- **Bootstrap `consumeAuthCallbackHash()` ANTES do React** — único jeito
  de evitar conflito de hash com `useHashLocation` do wouter.

## Bloqueios & perguntas abertas

- **⚠️ DRIFT vs monorepo dap4-portals** — quando o `dap4-portals` foi
  bootstrapado (2026-05-06 07:57) o subtree merge de `dap-gestao` pegou
  `master c976c11`. Toda a ADR-001 Fase 3 (commits `9c7af1b..64560a6`) é
  **5 commits ahead** disso. O monorepo precisa absorver esses commits
  antes da Task 7 (sunset). Provavelmente `dap-operacao` tem drift análogo
  (ADR-001 fala "Backend ambos portais", "Frontend ambos portais").
- **Validação end-to-end de login real** — Thales precisa logar pelo menos
  1× nos 2 portais com email+senha real antes de a gente dropar bcrypt.
  Sem isso, Fase 6 fica bloqueada indefinidamente.
- **dap-operacao auth-jwt test missing** — só dap-gestao tem test do
  middleware. Operacao ficou deferred por causa do stub GoTrue.

## Próximo passo exato

Esse projeto entrou em **modo standby**. O trabalho ativo agora é o
monorepo `dap4-portals` (handoff irmão de hoje). As 3 frentes que
poderiam reabrir esse repo standalone:

1. **Fase 6 (cleanup bcrypt)** — depois que admin validar login real, vir
   aqui dropar `bcryptjs`, `express-session`, `memorystore`, e a coluna
   `password`. Migration SQL + commit + push.
2. **Hotfix de produção** se algum bug do auth aparecer na operação real.
3. **Quando o monorepo fizer Task 7 (sunset)**, esse repo é archived no
   GitHub. Antes disso, as Fases que sobrarem migram pro `apps/gestao` do
   monorepo.

**Decisão pendente do Thales:** Fase 6 (drop bcrypt) acontece aqui no
standalone ou já dentro do monorepo? Faz sentido fazer no monorepo, pra
evitar drift maior. Se for assim, esse repo entra em **freeze** até o
sunset.

## Setup / comandos úteis

```sh
cd C:/THALES/DAP4/dap-gestao

# Estado atual
git log --oneline | head -10
# 64560a6 docs(adr): preencher seção Implementation outcome do ADR-001
# 43e8d45 feat(auth): /reset-password route + hash bootstrap + hide Google
# de68af1 feat(auth): Supabase Auth — JWT backend + browser GoTrue REST
# 512088a feat(schema): add authUserId field + nullable password
# 9c7af1b docs(adr): ADR-001 — unificar auth dos portais sob Supabase Auth

# Dev
npm run dev           # 5052

# Tests
npm test              # auth-jwt.test.ts entre os verdes

# ADR vivo
cat docs/adrs/0001-auth-unification.md
# E linha vinculada no banco:
# select * from gestao.adrs where id = 1;
```

**Memory candidata** (não escrever ainda — esperar Fase 6 fechar):
- `project_dap_gestao_auth_supabase.md` — Fase 3 ADR-001 entregue, drift
  vs monorepo, Fase 6 pendente.
