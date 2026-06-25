---
type: handoff
date: 2026-05-17
time: 14:27
project: dap-aios
topic: R10 — Auth Supabase real plug-and-play + Role Switcher dev + Portais por role + move OneDrive→DAP4.0
tags: [handoff, claudin, dap-aios, r10, auth, supabase, role-switcher]
---

# Handoff — DAP AIOS R10 (auth real + role switcher + filtro portais)

## Contexto

DAP AIOS é o portal chairman / orquestração do ecossistema (`C:\THALES\DAP4.0\dap-aios` — antes em OneDrive). Fullstack pnpm monorepo: client Vite+React, server Express+better-sqlite3+Drizzle, packages/types compartilhado.

Antes desta sessão: R9 entregue (Portal Mecânico MVP + Pátio Kanban + máquina de estados), commit base `5620a3a`. Auth era **stub** (toda request rodava como `system actor` admin), e tabelas `users`/`roles`/`permissions` existiam mas eram decorativas.

A sessão moveu o repo de OneDrive pra `C:\THALES\DAP4.0\dap-aios` (precaução pós-reversão silenciosa do OneDrive em R9), expôs e resolveu um bug pré-existente de tipos do drizzle-zod (primeiro fresh install verde end-to-end), e plumbou **auth real plug-and-play**: Supabase Auth via Bearer JWT no backend, AuthContext + LoginPage no frontend, com fallback automático pro stub quando env Supabase ausente. Bonus: role-switcher dev pra admin simular outras roles sem deslogar (server-side de verdade), sidebar colapsável, filtro de sidebar/rotas pela role efetiva via `/api/me.allowedPortals`.

## O que funcionou (com evidência)

- **Move OneDrive → C:\THALES\DAP4.0\dap-aios** — evidência: robocopy 2082 arquivos / 16 MB / 0 falhas; `git log` no destino bate com origem (commit `5620a3a`); fresh `pnpm install` resolveu 361 packages igual à origem.
- **Type-fix drizzle-zod (commit 156dc37)** — evidência: `pnpm check` 3 workspaces verde pela 1ª vez em fresh install (origem mascarava bug por path OneDrive Files-On-Demand).
- **Auth backend (commit e0bc7b6)** — evidência: 8 tests novos cobrindo stub + Supabase real (missing/malformed/invalid JWT, user não provisionado, inativo, happy path); `curl http://localhost:5050/api/leads` sem Bearer → `401 "missing Bearer token"`; com Bearer fake → `401 "invalid or expired token"`.
- **Projeto Supabase criado via MCP** — evidência: ID `hlhfqnhsvwxodtwdkkhf`, region sa-east-1, $10/mo, status ACTIVE/auth endpoint UP.
- **User Thales provisionado via REST signUp + MCP execute_sql auto-confirm** — evidência: `auth.users.email_confirmed_at` populado; SQLite `users.supabase_user_id = 'd803e35e-...'`, role admin preservada.
- **Auth E2E autenticado** — evidência: `POST /auth/v1/token?grant_type=password` retorna access_token; `GET /api/leads` com Bearer real → **HTTP 200, 8 leads retornados**.
- **Env wiring centralizado (commit 676d2a1)** — evidência: dotenv path `../../.env`, Vite `envDir: '..'`, server boota lendo SUPABASE_URL corretamente.
- **Role-switcher dev (commit 7ef58e1)** — evidência: 4 tests novos (override válido/inválido em stub + Supabase real); `GET /api/me` com `x-aios-role-override: mecanico` retorna `roleKey=mecanico, realRoleKey=admin, overrideActive=true`; header inválido `hacker` é ignorado retornando role real.
- **Filtro de portais por role (commit 4eb6192)** — evidência: `GET /api/me.allowedPortals` retorna lista correta por role (admin: 5 portais; mecanico: [mecanico]; consultor: [consultor, calculadoras]; gestor: [gestao, calculadoras, aios]); UI confirmada visualmente pelo user — sidebar encolhe ao trocar role, redirect funciona, badge "vendo como: X" aparece no header.
- **Sidebar colapsável com smart-expand** — evidência: confirmado visualmente pelo user; chevron rotaciona, estado persiste em localStorage, grupo da rota ativa sempre abre.
- **Login funcional E2E pelo browser** — evidência: user confirmou "entrou no portal consultor" após F5; sidebar mostra todos os portais como admin.
- **Smoke completo verde** — evidência: `pnpm check` 3 workspaces, `pnpm test` 63/63 em 2.7s, `pnpm build` vite 367kb + server 927kb, todos sem erros.

## O que NÃO funcionou (e por quê)

- **Investigação inicial do bug do tsc check** — falhou porque: gastei várias rodadas tentando culpar o path (`.` em DAP4.0), cache `.tsbuildinfo`, hoisting do pnpm, antes de descobrir que era apenas drizzle-zod 0.7.1 inferindo `text()` como `ZodType<Buffer>` em fresh install. Origem OneDrive mascarava por característica do path (provável Files-On-Demand / reparse points NTFS). **Lição**: na próxima vez que ver bug fantasma "passa aqui, falha lá" — testar `tsc` direto sem pnpm primeiro pra eliminar variáveis, e olhar o arquivo afetado em detalhe antes de caçar diferença ambiental.
- **pnpm install com `--prefer-offline`** — falhou porque: peguei cache stale e achei que era o problema; remover o flag e fazer fresh install reproduziu exatamente o mesmo erro. Não era cache, era código. **Lição**: `--prefer-offline` complica reprodução de bugs ambientais; usar instalação limpa quando investigando.
- **`node -e` com SQL inline via PowerShell** — falhou porque: PowerShell parsing comeu as vírgulas do template literal SQL, gerando `SyntaxError` ao invés de erro de SQL. Tive que criar arquivo `.tmp.mjs` separado e rodar `node script.mjs`. **Lição**: nunca passar SQL multi-line via `-e` no PS, sempre arquivo.
- **Edit em `server/src/routes/index.ts`** — falhou porque: o Edit reclamou "File has not been read yet" mesmo eu tendo lido via Bash. **Lição**: Bash cat/grep não conta como Read; sempre usar `Read` tool antes de `Edit`.
- **Background `pnpm dev` ficou retornando exit 127** — falhou porque: ao matar processos via `Stop-Process -Force` o pai pnpm retorna 127 (command not found), mas isso é cosmético — os filhos node morrem corretamente. **Lição**: ignorar exit code do pnpm parent quando matando dev server.
- **Sidebar mostrando todos os portais mesmo com role override** (problema reportado pelo user "mesmo que eu altere o role, a página continua a mesma") — falhou porque: implementei só o filtro server-side (chamadas retornam dados/erros diferentes) sem filtrar a UI. Corrigi adicionando `allowedPortals` no `/api/me` + filtro na sidebar + `RouteGuard` redirecionando rotas fora do escopo. **Lição**: quando o user pede "role switcher", a expectativa é a UX completa (sidebar encolhe, rotas redirecionam), não só o filtro server-side.

## O que ainda não foi tentado

- **Bundle optimization**: marcar `@supabase/supabase-js` como `external` no esbuild config do server. Bundle cresceu de 127kb pra 927kb. Em VPS não importa operacionalmente, mas é low-hanging fruit pra R11.
- **JWKS local pra validar JWT sem roundtrip ao Supabase** (50-200ms a menos por request). Pode usar `jose` library ou utility do supabase-js.
- **Onboarding UI** (`/admin/users` CRUD): hoje precisa criar user no dashboard Supabase + UPDATE SQL no SQLite local. Página dedicada removeria fricção pra demo com equipe real.
- **5 áreas de Gestão restantes COM dados reais** (Vendas & CRM, Operações, Equipe, Marketing, Financeiro). Material: leads.source, service_orders.status, service_orders.assigned_mechanic_id, quotes.totalCents, calculator outputs.
- **Portal Cliente MVP** (token assinado por OS no link, sem auth complexo).
- **UX upgrades do Mecânico** (dnd Kanban + autosave checklist) herdados da R9.
- **MFA / OAuth providers** (Google) — Supabase suporta mas postergado.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `packages/types/src/schema/{core,events,rag,agents,consultor,calculators,service-orders}.ts` | Completo | Trocou callbacks `(s) => s.X` por `z.string().X` em todos overrides. core.ts ganhou `supabaseUserId: text('supabase_user_id')` + unique index. |
| `server/migrations/0004_amusing_unus.sql` + `meta/0004_snapshot.json` | Completo | ADD COLUMN + UNIQUE INDEX. Aplicado em prod local. |
| `server/src/lib/supabase.ts` | Completo | Singleton com cache env-sig. getSupabaseClient + isSupabaseAuthEnabled. |
| `server/src/middleware/requireAuth.ts` | Completo | Refeito do zero: stub mode (sem env) + real mode (Bearer JWT → getUser → lookup local). AuthActor ganhou realRoleKey. applyRoleOverride dev-only. |
| `server/src/routes/me.ts` | Completo | GET /api/me retorna { actor + allowedPortals + user }. Mapa PORTAL_VISIBILITY inline. |
| `server/src/routes/index.ts` | Completo | Registra meRouter. |
| `server/src/index.ts` | Completo | dotenv path `../../.env` explícito. |
| `server/scripts/seed.ts` + `aios-sync.ts` + `test/setup/db-helpers.ts` | Completo | SYSTEM_ACTOR ganhou realRoleKey: 'system'. |
| `server/test/integration/requireAuth.test.ts` | Completo | 12 tests novos (8 auth + 4 override). Mock controlado de getSupabaseClient + getUser. |
| `client/src/lib/supabase.ts` | Completo | Singleton browser com persistSession localStorage. |
| `client/src/auth/{AuthContext,LoginPage,RequireAuth,RoleSwitcher,roleOverride,useMe,portals,RouteGuard}.tsx` | Completo | 8 arquivos novos do módulo auth. |
| `client/src/lib/api.ts` | Completo | Injeta Authorization + x-aios-role-override headers automaticamente. |
| `client/src/shared/components/Sidebar.tsx` | Completo | Filtro por allowedPortals + grupos colapsáveis com smart-expand + RoleSwitcher no footer. |
| `client/src/shared/components/Layout.tsx` | Completo | RoleOverrideBadge no header. |
| `client/src/main.tsx` | Completo | AuthProvider acima do QueryClient. |
| `client/src/App.tsx` | Completo | Rota /login + RequireAuth wrap + RouteGuard interno + RootRedirect substituindo ConsultorHome em `/`. |
| `client/vite.config.ts` | Completo | envDir aponta pra raiz. |
| `client/package.json` + `server/package.json` | Completo | @supabase/supabase-js novo. client ganhou @types/node explícito. |
| `.env.example` + `.env` | Completo | .env.example commitado, .env gitignored com URL + anon key do projeto Supabase real. |
| `handoff-aios-rodada10-auth-portais.{html,md}` | Completo | Handoff Perplexity nos 2 formatos commitados. |
| **`CLAUDE.md` (deletado) + `CLAUDE.md.md` (untracked)** | Quebrado herdado | Pendência herdada do OneDrive. Não toquei. Working tree continua sujo com isso. |
| **`2-dap4-portals/`** | Não iniciado | Workspace embutido legacy (May 16, estagnado). Candidato a remover. |
| **`FORNECEDORES.zip` 654 KB no root** | Não iniciado | Sem uso óbvio. Mover ou deletar. |

## Decisões tomadas

- **Supabase Auth only — SQLite continua source of truth dos dados** — razão: migrar pra Postgres exigiria reescrever queries Drizzle (modes timestamp_ms, better-sqlite3 sync vs pg async). Auth funciona como serviço standalone via JWT, zero dependência de migração de dados.
- **Bridge via `users.supabase_user_id`** — razão: schema local minimal (1 coluna), preserva todas as FKs locais (cada user mantém seu id), lookup O(1) via unique index.
- **Backward-compatible (stub ↔ real via env)** — razão: permite dev tranquilo sem subir auth backend; plug-and-play; zero risco em CI ou dev box novo.
- **Validação JWT via `supabase.auth.getUser` (roundtrip)** — razão: simplicidade pro MVP, robusto. JWKS local é otimização futura (R11+) sem impacto na UX.
- **AuthActor.realRoleKey separado de roleKey** — razão: permite código diferenciar "admin olhando como mecânico" de "realmente mecânico"; crítico pra UI mostrar switcher só pra admin real e pra audit log.
- **Role override server-side, não fake visual** — razão: server respeita header dev-only, `requirePermission` rejeita ação não autorizada; UX testando restrições reais. Em `NODE_ENV=production` o header é ignorado totalmente (zero risco prod).
- **Defesa em profundidade** — razão: UI filtra (UX), RouteGuard redireciona (rota direta no browser), requirePermission no server retorna 403 (defesa real). Burlar UI ainda recebe 403.
- **Form custom de login (não @supabase/auth-ui-react)** — razão: dark-luxury do AIOS; auth-ui-react destoa visualmente; 80 linhas de form custom dão controle total.
- **session=localStorage, role-override=sessionStorage** — razão: session persiste entre tabs/reloads (UX); role-override reseta ao fechar tab (guard rail pra não esquecer ativo).
- **PORTAL_VISIBILITY hardcoded no server** — razão: overengineering criar tabela `portal_grants` pra MVP; quando granularidade ficar insuficiente (ex: consultor admin vs consultor júnior), aí vira tabela.
- **Projeto Supabase NOVO dedicado (não reusar DAP4.0 existente ou DOCTOR PRIME)** — razão: isolation limpo, AIOS é produto separado, billing/permissões claros. $10/mo justificado.
- **Região sa-east-1 (São Paulo)** — razão: melhor latência pra equipe BR (vs us-east-1 que é onde está o DAP4.0 antigo).
- **Path canônico C:\THALES\DAP4.0\dap-aios (subpasta DAP4.0 nova, não dentro de DAP4)** — razão: user pediu explicitamente. Cria hub novo limpo. DAP4 antigo coexiste; quando vier dap-operacao/dap-tools/dap-gestao novos vão pra DAP4.0 também.
- **OneDrive original preservado intacto como safety net** — razão: pode arquivar depois quando confiança total no novo path; não editar lá pra evitar drift.

## Bloqueios & perguntas abertas

- **R11 não decidida** — user estava entre 4 opções (Gestão áreas restantes / Portal Cliente MVP / UX upgrades Mecânico / Onboarding UI). No final pediu uma área de Gestão específica primeiro mas interrompeu antes de escolher qual e pediu handoff. **Próxima sessão deve abrir perguntando isso.**
- **Senha do admin é temporária aleatória** (24 chars, mostrada uma vez no chat). Não foi salva em lugar nenhum. Se o Thales não anotou, vai precisar **Reset password** no dashboard Supabase.
- **2 áreas de Gestão sem dados** (Pós-venda, Facilities) — vão exigir schema novo antes de fazer sentido. Decidir prioridade vs as outras 5 que têm dados.
- **OneDrive antigo** — quando arquivar? Sugestão: após Thales operar 1 semana no novo path sem dor.
- **Bundle de 927kb** — aceitável? Otimização pra ~150kb via esbuild external é trivial em R11.
- **CLAUDE.md.md** (extensão dupla, untracked, 13 KB) — provável artefato de save duplo. Olhar conteúdo e decidir: deletar, renomear pra CLAUDE.md (substituindo o deletado), ou mover pra docs/.
- **Refresh token strategy** não testada explicitamente — JWT expira em 1h, supabase-js faz auto-refresh, mas vale observar comportamento em sessão longa.

## Próximo passo exato

**Abrir próxima sessão perguntando ao Thales qual feature da R11 ele quer primeiro**, com estas opções já mapeadas:

1. **R11 — Gestão (áreas restantes)** [recomendada]: 5 áreas com dados reais (Vendas & CRM, Operações, Equipe, Marketing, Financeiro). Criar endpoints de agregação + páginas com KPIs. Pós-venda e Facilities ficam stub.
2. **R11-alt — Portal Cliente MVP**: read-only + aprovar proposta, token assinado por OS no link.
3. **R11-alt — UX upgrades Mecânico + bundle optimization**: dnd Kanban + autosave checklist + @supabase external no esbuild.
4. **R11-alt — Onboarding UI** (`/admin/users`): CRUD de users no Supabase + SQLite local via MCP. Pré-requisito pra demo com equipe real.

Se Thales escolher (1) e disser "uma área específica primeiro", presets já investigados:
- **Vendas & CRM** — funil de leads (source → qualified → quote → won) + pipeline value
- **Operações** — KPIs de OS por status + throughput + tempo médio por estado
- **Equipe** — ranking de mecânicos por OS entregue + tempo médio + reabertura

## Setup / comandos úteis

```bash
# Novo path canônico
cd C:\THALES\DAP4.0\dap-aios

# Dev (server roda em background ainda dessa sessão; matar antes se ainda vivo)
pnpm dev   # localhost:5050

# Credenciais do admin (senha gerada via MCP, anotar em local seguro):
# Email: toliveira1802@gmail.com
# Senha: temporária 24 chars (não está em .env nem memória)
# Reset em: https://supabase.com/dashboard/project/hlhfqnhsvwxodtwdkkhf → Authentication → Users

# Supabase MCP útil pra próxima sessão:
# - mcp__claude_ai_Supabase__execute_sql project_id=hlhfqnhsvwxodtwdkkhf
# - mcp__claude_ai_Supabase__get_publishable_keys project_id=hlhfqnhsvwxodtwdkkhf

# Estado git
git log --oneline -8
# Esperado:
# bc63d69 docs: handoff R10 versão markdown (Perplexity)
# 6498e18 docs: handoff-aios-rodada10-auth-portais.html
# 4eb6192 feat(auth): filtrar sidebar + rotas pela role efetiva
# 7ef58e1 feat(auth): role-switcher dev + sidebar colapsável
# 676d2a1 chore(env): centraliza .env na raiz do repo
# e0bc7b6 feat(auth): Supabase Auth real com fallback stub agnostic
# 156dc37 fix(types): drizzle-zod callbacks → z.string()
# 5620a3a docs: handoff próxima sessão + suplemento Perplexity R8/R9 (base R9)

# Smoke rápido pra confirmar que ainda tá vivo
curl -s http://localhost:5050/api/health
# {"ok":true,"data":{"status":"ok","uptime":X,"env":"development"}}

# Smoke autenticado (precisa do JWT)
$tok = (Invoke-RestMethod -Uri "https://hlhfqnhsvwxodtwdkkhf.supabase.co/auth/v1/token?grant_type=password" `
  -Method Post `
  -Headers @{ "apikey" = $env:SUPABASE_ANON_KEY; "Content-Type" = "application/json" } `
  -Body (@{ email="toliveira1802@gmail.com"; password="..." } | ConvertTo-Json)).access_token
Invoke-RestMethod -Uri "http://localhost:5050/api/me" -Headers @{ "Authorization" = "Bearer $tok" }
```

**Pendência herdada do OneDrive (não tocar sem decisão):**
- `CLAUDE.md` deletado uncommitted (working tree dirty)
- `CLAUDE.md.md` 13 KB untracked
- `2-dap4-portals/` legacy embutido
- `FORNECEDORES.zip` 654 KB no root
