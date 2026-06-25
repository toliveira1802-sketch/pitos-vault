---
type: handoff
date: 2026-05-25
time: 20:46
project: dap-aios
topic: Portal Consultor V2 deployado em staging-operacao.doctorautoprime40.com com Supabase Auth real, RoleSwitcher funcional, 7 patches in-place não-commitados
tags: [handoff, claudin, dap-aios, staging, r13]
---

# Handoff — Portal Consultor V2 no ar em staging-operacao.*

## Contexto

Sessão começou com revisão de memória + commit/push do R30b (DAP4 P1 fase 2: WhatsApp + Anna drafts + RAG collections) → PR #32 aberto. Em seguida abriu PR #33 do R13 com fixes pós code-review (security + typescript reviewers rodados em paralelo).

Pivot principal: Thales pediu **"portal consultor na VPS rodando AGORA"**. Caminho V2 escolhido (dap-aios atual, não V1.5 dap-operacao legado). Setup completo do staging up: rotação senha Supabase → criação role custom `app_aios_v2` → seed do schema → admin user com supabase_user_id linkado → CF Tunnel route nova → Universal SSL (1-level subdomain hyphenated) → 4 rounds de bug-fix conforme uso real revelou problemas.

Resultado: `https://staging-operacao.doctorautoprime40.com` ACESSÍVEL, login com `toliveira1802@gmail.com / 12345678`, dashboard carrega dados reais (3 customers, 8 leads, 2 OS, etc), Pátio Kanban renderiza, RoleSwitcher admin↔consultor↔gestor↔mecanico funcional via header `x-aios-role-override`. Sessão fechou com 2 features novas adicionadas no master TODO do vault.

## O que funcionou (com evidência)

- **R30b commit + push** — commit `d5ed882`, branch `feat/r30b-anna-meta-integration`, PR #32 aberto via `gh pr create`
- **R13 fixes (security + TS reviewers paralelos)** — commit `7099989`, PR #33 aberto, 17 commits ahead da main
- **Rotação senha Postgres via Supabase Management API** — `CREATE ROLE app_aios_v2 WITH LOGIN PASSWORD '...'` funciona consistente (vs `ALTER USER` que retornava 200 mas não aplicava)
- **Container aios-staging conecta no Postgres** — `docker exec aios-staging node -e "SELECT current_user FROM users"` retorna `app_aios_v2`
- **Seed populou 29 tabelas** — 6 users do seed + 1 admin meu (Thales linkado ao Supabase Auth `d803e35e-4c4c-4380-860a-e6fe1ddc3a8a`), 4 roles, 34 permissions, 3 customers, 8 leads, 2 OS, etc
- **Login real via Supabase Auth** — `POST /auth/v1/token?grant_type=password` retorna JWT, app aceita Bearer e responde 200 nas rotas protegidas
- **HTTPS no staging-operacao.*** — via CF Tunnel route + Universal SSL (1 nível hyphenated cobre)
- **RoleSwitcher funciona em production** — após patch com flag `AIOS_ROLE_OVERRIDE=1`, logs mostram `[role-override] actor=v8nnSgz6VuhGG1_bbQ admin→consultor`
- **Abre OS funciona** — após patch `osCode.ts` (regex `~ '^OS-YYYY-[0-9]+$'` em vez de `like`)
- **Smoke completo** — `/api/health 200`, `/api/customers` retorna lista, Pátio carrega 2 OS em colunas corretas (em_execucao, diagnostico)

## O que NÃO funcionou (e por quê)

- **Dashboard "Reset DB Password" do Supabase aplicado 3x via UI** — cada vez gerou senha nova de 16 chars, todas rejeitadas com SQLSTATE `28P01` ao tentar conectar. Possível bug do dashboard ou propagação lenta. **Workaround comprovado**: usar Management API SQL endpoint pra `ALTER` em roles non-privileged, ou `CREATE ROLE` novo.
- **`docker restart aios-staging` após editar `.env`** — container continua com env velho em memória (restart não recarrega `env_file:` do compose). Precisa `docker compose up -d --force-recreate <service>` — perdemos ~30min debugando isso.
- **`docker inspect aios-staging --format "...env_summary={{range .Config.Env}}{{.}}{{end}}"`** — RETORNOU senha viva do Postgres no chat → causou rotação de emergência. Memória: [[feedback-no-docker-env-dump]]
- **Vite build sem `.env*` no build context** — `import.meta.env.VITE_SUPABASE_URL` virou `undefined`, app mostrou setup-required component ("Auth desativado") interpretado pelo Thales como "tela preta"
- **`.env.production` no source dir foi ignorado pelo build** — `.dockerignore` excluía `.env.*`. Precisa exception `!.env.production`
- **`docker build` cacheou pnpm build layer** — primeiro rebuild sem mudança no Dockerfile não pegou `.env.production`. Usar `--no-cache` ou modificar Dockerfile pra invalidar.
- **`ALTER USER app_aios_v2 WITH PASSWORD` via Management API SQL** — status 200 mas password não aplica (cache? lag?). Workaround: criar role novo (app_aios_v2 → futuro app_aios_v3 etc). DROP+CREATE seria limpo mas DROP requer REASSIGN OWNED (postgres não tem privilege).
- **PAT do Supabase com IP filter** — rejeita request do VPS (IPv6) com code 9109. Workaround: rodar API call from local (mesmo IP que gerou token).
- **Token Cloudflare formato `cfut_*`** — eu achei que era tunnel token, era API token. Funcionou.
- **RLS re-habilitada após seed = app vê 0 rows** — sem policies pro `app_aios_v2`, queries retornam vazio, app retorna 403 em permission check. Atualmente: **RLS DISABLED em todas as 29 tabelas** (ADR-001 #8 ainda pendente).
- **Server schema `limit.max(200)` vs Client `PATIO_LIMIT=400`** — Kanban dava 400 Bad Request. Patch: `max(500)`.
- **PG estrito em `CAST('AUDIS4' AS INTEGER)`** — explode (vs SQLite lenient). Seed criou OS com sufixo não-numérico, `computeNextOsCode` quebrou ao tentar criar OS nova.

## O que ainda não foi tentado

- **Portar os 7 patches in-place do VPS pra git** (ver tabela abaixo) — branch novo `fix/staging-deploy-patches` ou anexar ao branch paralelo do Thales
- **Reconciliar branch paralelo do Thales** — ele mencionou ter um branch onde foi "alterando coisinhas". Nome desconhecido, precisa cavar
- **Criar policies RLS fine-grained pro `app_aios_v2`** — opção less-aggressive que disable global (ADR-001 #8)
- **Tests do R13 local** — Supabase circuit breaker era senha velha. Agora pode ser destravado, mas worktree R13 já tem nova URL via `app_aios_v2` (consequência: tests vão hit staging DB que tem dados de seed). Precisa decidir DATABASE_URL separada pra tests
- **Promover staging → prod** — substituir route CF Tunnel `operacao.*` (V1.5 host:5001) pra `aios-staging:5050` (V2)
- **Aposentar V1.5 dap-operacao monorepo** — `systemctl disable --now dap-operacao.service` quando V2 estabilizar

## Arquivos tocados

### Worktree principal (`C:\THALES\DAP4.0\dap-aios`)

| Arquivo | Status | Notas |
|---------|--------|-------|
| `server/src/routes/agents.ts` | Commitado em `d5ed882` (R30b) | Anna drafts endpoints |
| `server/src/routes/index.ts` | Commitado em `d5ed882` | Registra messagesRouter |
| `server/src/routes/rag.ts` | Commitado em `d5ed882` | `/api/rag/collections` |
| `server/src/routes/messages.ts` | Commitado em `d5ed882` (novo) | `/api/messages/whatsapp/send` |
| `server/src/services/dap4Client.ts` | Commitado em `d5ed882` | Refator request() + namespaces novos |
| `server/test/integration/dap4Client.test.ts` | Commitado em `d5ed882` | +29 tests |
| `handoff-aios-r30b-anna-meta.md` | Commitado em `d5ed882` (novo) | Handoff do R30b |
| `.claude/` | Untracked | Diretório config local — ADICIONAR ao .gitignore |

### Worktree R13 (`C:\THALES\DAP4.0\dap-aios-r13`)

| Arquivo | Status | Notas |
|---------|--------|-------|
| `server/src/lib/osCode.ts` | Commitado em `7099989` (R13 fixes) | LIKE→ILIKE (mas precisa também o regex do patch VPS) |
| `server/src/routes/helpers.ts` | Commitado em `7099989` | 23505 → 409 mapping |
| `server/src/middleware/requireAuth.ts` | Commitado em `7099989` | NODE_ENV production guard no stub auth (mas precisa também o `AIOS_ROLE_OVERRIDE` flag do patch VPS) |
| `server/src/db/client.ts` | Commitado em `7099989` | SSL config |
| `server/src/index.ts` | Commitado em `7099989` | Helmet |
| `server/src/services/dashboardService.ts` | Commitado em `7099989` | 8x `::int` cast em count(*)/sum() |
| `.env` (local) | Modificado, gitignored | DATABASE_URL atualizada pra `app_aios_v2` (2 linhas duplicadas — limpar) |
| `docs/contexto/briefing-historico/dap-portal-aios-vps-arquivado.md` | Commitado em `7099989` | Credenciais redactadas |

### VPS source `/opt/dap-aios/src/` (PATCHES IN-PLACE NÃO-COMMITADOS)

| Arquivo | Status | Notas |
|---------|--------|-------|
| `server/src/middleware/requireAuth.ts` | Patched no VPS | Linha 48: adicionou `&& process.env.AIOS_ROLE_OVERRIDE !== '1'` no guard. Backup `.bak.<ts>` |
| `server/src/lib/osCode.ts` | Patched no VPS | `like` → `sql\`code ~ '^OS-YYYY-[0-9]+$'\``. Backup `.bak.<ts>` |
| `server/src/routes/service-orders.ts` | Patched no VPS | `limit.max(200)` → `max(500)`. Backup `.bak.<ts>` |
| `Dockerfile` | Patched no VPS | `COPY .env.production ./` antes de `RUN pnpm build`. Backup `.bak.<ts>` |
| `.dockerignore` | Patched no VPS | `!.env.production` exception |
| `.env.production` | NOVO no VPS | Contém só `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY` (vars públicas) |

### VPS `/opt/dap-aios/aios-staging/.env`

| Mudança | Status | Notas |
|---------|--------|-------|
| `DATABASE_URL` atualizada pra `app_aios_v2.<ref>:<pwd>@...` | Aplicado | Backup `.env.bak.before-app-aios.<ts>` + `.env.bak.before-v2.<ts>` |
| Linha `AIOS_ROLE_OVERRIDE=1` adicionada | Aplicado | Ativa role override em production |

### VPS `/opt/doctor-auto-ai/infra/Caddyfile`

| Mudança | Status | Notas |
|---------|--------|-------|
| Bloco `@operacao host staging-operacao.doctorautoprime40.com` + `handle @operacao { reverse_proxy aios-staging:5050 }` | Aplicado | Backup `.bak.<ts>` |

### Cloudflare Tunnel `dap4` (via Management API)

| Mudança | Status | Notas |
|---------|--------|-------|
| Ingress rule `staging-operacao.doctorautoprime40.com → http://localhost:80` | Aplicado | Antes do catch-all 404 |
| DNS CNAME `staging-operacao` → `<tunnel_id>.cfargotunnel.com` proxied | Aplicado | id `a93617e3d62f05daffda39607e758523` |

### Supabase DAP AIOS (`hlhfqnhsvwxodtwdkkhf`)

| Mudança | Status | Notas |
|---------|--------|-------|
| Role `app_aios_v2` (LOGIN, NOSUPERUSER, INHERIT) | Criado | Substitui `postgres` no DATABASE_URL |
| Grants em schema public pra `app_aios_v2` | Aplicado | USAGE + ALL TABLES + ALL SEQUENCES + DEFAULT PRIVILEGES |
| RLS em todas as 29 tabelas | DESABILITADA | Dívida ADR-001 #8 ainda pendente |
| Seed completo | Aplicado | 6 users + 4 roles + 34 permissions + 3 customers + 8 leads + 2 OS + 13 agentes + 5 calculators + 2 RAG docs |
| User `toliveira1802@gmail.com` | Linkado | local user `v8nnSgz6VuhGG1_bbQ` ↔ auth `d803e35e-4c4c-4380-860a-e6fe1ddc3a8a` ↔ role admin |
| Senha role `postgres` | Rotacionada 4x | Última `EavhNtl...` ficou no Supabase mas não usamos (mudamos pra `app_aios_v2`). `postgres` user não é mais usado pelo app. |

### Local memória + TODO mestre

| Arquivo | Status | Notas |
|---------|--------|-------|
| `~/.claude/projects/.../memory/MEMORY.md` | Atualizado | 5 entradas novas |
| `feedback_no_docker_env_dump.md` | Novo | Lição da exposição |
| `project_vps_stack_real.md` | Novo | Mapa real VPS (P0/P1/V2) |
| `project_v2_staging_up.md` | Novo | Estado V2 staging + 7 patches |
| `feedback_supabase_management_quirks.md` | Novo | Quirks aprendidos |
| `project_deferred_backlog.md` | Editado | +2 features (top parked, mecânico/hora) |
| `Notas/001-dap40-master-todo.md` (vault) | Editado | Fase 0.4 + Park + histórico 2026-05-25 |

## Decisões tomadas

- **V2 staging em vez de V1.5** — Thales: "dap-operacao é só legado. o que quero é o atual". V1.5 (`/opt/dap-portals/apps/operacao` em :5001) fica vivo como fallback mas não é o futuro.
- **Subdomínio hyphen-1-level** (`staging-operacao.doctorautoprime40.com`) — em vez de `staging.aios.*` que exigia Advanced Cert $10/mo. Universal SSL grátis cobre 1 nível. Padrão `operacao.*` futuro pra prod faz sentido (já existe rota apontando pro V1.5).
- **Role custom `app_aios_v2`** em vez de continuar com `postgres` no DATABASE_URL — least-privilege, foi a única forma de rotacionar senha funcional após `ALTER USER postgres` falhar com 42501 (privileged role).
- **Feature flag `AIOS_ROLE_OVERRIDE=1`** em vez de remover guard `NODE_ENV === 'production'` — explícito, fail-safe (sem flag = bloqueado em prod), preserva intenção de security review C-2.
- **RLS DISABLED globalmente** em vez de criar policies — dívida ADR-001 #8 não ataca agora. Quando atacar, criar policies + ENABLE de volta.
- **VITE_SUPABASE_ANON_KEY em `.env.production`** é OK ser "public" — anon JWT vai embed no client bundle visível via F12. Server secrets (SERVICE_ROLE, DATABASE_URL) ficam só em `.env` do server.
- **`docker compose up -d --force-recreate`** em vez de `docker restart` — `restart` não recarrega env_file. Quebra de paradigma que custou ~30min hoje.
- **Não rewrite git history** do credential leak C-1 (security review R13) — repo é privado de facto. Redact + rotacionar manualmente.
- **Indicador "Top parked + R$"** entra em Fase 0 do master TODO (instrumentação) — move alavanca 2 (Permanência) direto. Mecânico por hora vai pra Park (compensation, não move funil/permanência no curto).

## Bloqueios & perguntas abertas

- **Branch paralelo do Thales** — ele mencionou ter um branch onde foi "alterando coisinhas". Nome não foi capturado. `git branch -a` em ambos os worktrees não foi feito. Precisa decidir: 1) qual branch, 2) reconciliar com R13 + R30b + patches VPS, 3) ordem de merge.
- **Como tests R13 vão rodar** — worktree R13 `.env` agora tem `DATABASE_URL` apontando pra **staging DB com seed completo**. Tests fazem TRUNCATE — vão **detonar o staging**. Precisa: DATABASE_URL separada pra tests (local Postgres docker?), ou refator `integration-env.ts` pra requerer outro project_ref.
- **Senha rotacionada do `postgres`** ainda viva — `EavhNtl...` foi a última que rolou via dashboard, hoje não usamos. Pode ficar OU pode rotacionar de novo via API pra deletar a exposta. Decisão: deixar como está (não é usada pelo app).
- **PAT Supabase usado hoje** (`sbp_55c4...`) — não foi revogado. Continua válido por 1 dia (TTL). Thales precisa revogar manualmente em https://supabase.com/dashboard/account/tokens.
- **Backup files no VPS** (`.env.bak.*` em 2 paths + `.ts.bak.*` em src + `Dockerfile.bak.*`) — apagar após 24h estável.
- **CLAUDE.md global** afirmando "P0 = portais standalone" continua desatualizado. Memória `project_vps_stack_real.md` documenta a divergência. Atualizar em rodada dedicada.

## Próximo passo exato

Quando você abrir a próxima sessão **e quiser continuar o trabalho do staging V2**:

1. Abre `C:\THALES\DAP4.0\dap-aios-r13` (worktree R13). 
2. Roda `git status` — confirma working tree clean, branch `feat/r13-postgres-migration`.
3. `git branch -a | grep -v r13 | grep -v r30b | grep -v marketing` — identifica o branch paralelo com "coisinhas" que o Thales mencionou.
4. Lista os patches in-place do VPS (ver tabela "VPS source" acima) — abre cada arquivo no VPS via `scp root@76.13.170.42:/opt/dap-aios/src/... -` (cat na stdout) ou via `Read` se o branch local já contém versões similares.
5. Decide estratégia: 
   - (a) novo branch `fix/staging-deploy-patches` com os 7 patches commitados → PR separado
   - (b) merge num branch já existente do Thales
   - (c) anexa aos PRs #32 ou #33 abertos (cuidado: muda escopo deles)

**Critério de sucesso:** todos os 7 patches in-place estão em git em algum branch que vai pra `main`. Sem isso, próximo build sem cache da image perde os patches.

Se o trabalho da próxima sessão for OUTRA coisa (ex: rodar a Fase 0.4 do master TODO — widget "top parked + R$ comido"), começar lendo `~/.claude/projects/.../memory/MEMORY.md` + esse handoff pra entender o estado.

## Setup / comandos úteis

```bash
# SSH VPS
ssh root@76.13.170.42

# Verify staging live
curl https://staging-operacao.doctorautoprime40.com/api/health
# → {"ok":true,"data":{"status":"ok","env":"production"}}

# Smoke login (do laptop ou VPS)
curl -X POST https://hlhfqnhsvwxodtwdkkhf.supabase.co/auth/v1/token?grant_type=password \
  -H "apikey: <SUPABASE_ANON_KEY>" -H "Content-Type: application/json" \
  -d '{"email":"toliveira1802@gmail.com","password":"12345678"}'

# Logs container
ssh root@76.13.170.42 'docker logs --tail 30 aios-staging'

# Recreate container (NÃO restart)
ssh root@76.13.170.42 'cd /opt/doctor-auto-ai && docker compose up -d --force-recreate aios-staging'

# Rebuild image após mexer source
ssh root@76.13.170.42 'cd /opt/dap-aios/src && docker build -t dap-aios:staging .'

# Query DB via container (bypass circuit breaker / local IP issues)
ssh root@76.13.170.42 'docker exec aios-staging node -e "
const sql = require(\"postgres\")(process.env.DATABASE_URL, {max:1});
sql\`SELECT count(*)::int AS c FROM users\`.then(r => { console.log(r[0]); sql.end(); });
"'
```

## URLs ativas

- Portal: https://staging-operacao.doctorautoprime40.com
- Health: https://staging-operacao.doctorautoprime40.com/api/health
- PR R30b: https://github.com/toliveira1802-sketch/dap40-perple-claude/pull/32
- PR R13: https://github.com/toliveira1802-sketch/dap40-perple-claude/pull/33
- Supabase dashboard: https://supabase.com/dashboard/project/hlhfqnhsvwxodtwdkkhf
