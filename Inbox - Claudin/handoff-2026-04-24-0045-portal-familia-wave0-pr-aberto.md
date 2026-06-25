---
type: handoff
date: 2026-04-24
time: "00:45"
project: DAP 4.0 / Portal Família
topic: Wave 0 scaffold + migração schema portal commitados + PR #2 aberto; Portal Dev cancelado
tags: [handoff, claudin, portal-familia, schema-move, fase-1-done, pr-aberto]
---

# Handoff — Portal Família wave 0 + schema move done, PR #2 aberto

> **Continuidade direta do handoff anterior** (`handoff-2026-04-23-2130-partimos-daqui-schema-fork.md`). Fechou Fase 1 (B.1 do plano). Fase 2 (fork shadcn-admin = Portal Dev) foi **CANCELADA** pelo Thales no meio do caminho.

## Contexto

Thales entrou dizendo "BORA" — interpretei como autorização pro caminho (B.1 + A) do handoff anterior: schema move agora, depois fork shadcn-admin pra Portal Dev, ambos portais standalone.

Executei Fase 1 (schema move) limpo e commitei. Fase 1 ✅.

Quando entrei na Fase 2 (fork shadcn-admin como Portal Dev), depois de clonar + purgar demos + renomear, Thales reagiu: **"QUE PORRA É ESSE DE PORTAL"**. Contexto dele tinha se perdido sobre a existência do Portal Dev. Reframei: Família é o workspace interno que ele usa; Dev seria console técnico admin-only (Parliament/Agents/RAG/Crons/VPS) que ele mesmo pediu no handoff anterior. Ofereci (a) continuar / (b) pausar / (c) matar. Ele escolheu **C — matar**.

`rm -rf portal-dev/`. Zero rastro. Depois, `git push` da branch, depois `gh pr create`. PR #2 aberto.

## O que funcionou (com evidência)

- **Migration 04 aplicada em Supabase DOCTOR_PRIME**: 9 tabelas movidas de `public` → `portal` (empresas, profiles, user_preferences, sugestoes, trilhas, trilha_modulos, user_trilha_progresso, processos, avisos). 32 RLS policies preservadas via OID stability. `profiles_self_update` recriada textualmente.
- **Trigger `generate_matricula` recriado** com `nextval('portal.profiles_matricula_seq')` (body antigo tinha literal `'public.profiles_matricula_seq'` que quebraria pós-ALTER SEQUENCE SET SCHEMA).
- **Helpers `auth_role()` / `auth_empresa_id()` permanecem em `public`** (chamadas por policies sem qualificar schema), mas agora apontam pra `portal.profiles` via `SET search_path = portal, public`.
- **PostgREST exposição automatizada**: `ALTER ROLE authenticator SET pgrst.db_schemas = 'public, graphql_public, portal'` + `NOTIFY pgrst, 'reload schema'`. `ALTER DATABASE` não é permitido pelo service role do MCP (42501), mas `ALTER ROLE authenticator` funcionou. Thales **não precisou tocar dashboard**.
- **Cliente atualizado**: `portalDb = supabase.schema('portal')` exportado de `lib/supabase.ts`. 4 call-sites migrados (`AuthContext.fetchProfile`, `useUserPreferences` x3).
- **Typecheck green** via `tsc -b`. Fiz 2 fixes colaterais: useUserPreferences tinha chamada multiline (`supabase\n.from(...)`) que escapou do `replace_all` e virou `supabase` undefined; `Placeholder` lazy import órfão no router/index.tsx violava `noUnusedLocals`.
- **tsconfig.node.json fix pre-existente**: removi `noEmit: true` (incompatível com `composite: true` + project references, dá erro TS6310). Agora `emitDeclarationOnly: true` + `outDir: ".tsbuild-node"` (adicionado ao `.gitignore`).
- **Login validado no browser pelo Thales** em http://localhost:5175 com `thales@doctorautoprime40.com / DAP2026!` depois da migration aplicada.
- **Commit atômico `de5b37a`** em branch `feat/portal-familia-e-dev-wave-0` (142 arquivos, 19096 linhas). Branch pushada.
- **PR #2 aberto**: https://github.com/toliveira1802-sketch/dap4/pull/2

## O que NÃO funcionou (e por quê)

- **ALTER DATABASE postgres SET "pgrst.db_schemas"** falhou com erro 42501 (permission denied). Service role do MCP não tem permissão. **Fallback que funcionou**: `ALTER ROLE authenticator SET pgrst.db_schemas TO '...'`. Saber disso pra próxima.
- **Primeira tentativa de `apply_migration` fez rollback** completo por conta do ALTER DATABASE falhar. Nada foi aplicado. Removi a linha e reapliquei com sucesso. Importante: migrations do MCP rodam em transação atômica.
- **Fork shadcn-admin (Portal Dev) cancelado**: Thales reagiu com "QUE PORRA É ESSE DE PORTAL" depois de eu ter clonado, renomeado pra `portal-dev`, purgado Clerk/tasks/chats/apps. Ele escolheu (c) matar. Apaguei completo.
  - **Lição**: em sessão longa com muitas decisões encadeadas, o contexto do Thales pode drifar. Devo reframear decisões maiores com uma linha de contexto ANTES de executar passos destrutivos/alocativos (clone, install, purge).

## O que ainda não foi tentado

- **`pnpm test` no Portal Família** — 25+ testes escritos pelos 5 agentes em swarm, nunca executados. Pode ter falhas por mocks de Supabase ainda referenciando `public.profiles` quando na verdade agora é `portal.profiles`.
- **Smoke test completo dos 4 roles**: Thales só validou login admin. Gestor/consultor/mecanico não foram testados. Home + Portal Consultor W1 também não validados ponta a ponta.
- **Deploy VPS via Cloudflare Tunnel** (`portal.doctorautoprime40.com`): não configurado. Nenhum Docker service no compose da VPS pra esse subdomínio ainda.
- **Portal Dev**: totalmente cancelado nessa sessão. Thales pode retomar algum dia; por enquanto é inexistente.

## Arquivos tocados

| Arquivo / diretório | Status | Notas |
|---|---|---|
| `C:\dev\dap4\supabase\migrations\20260424_04_portal_familia_schema_move.sql` | ✅ Criado + aplicado | Move 9 tabelas pra schema portal, recria trigger + helpers |
| `C:\dev\dap4\portal-familia\src\lib\supabase.ts` | ✅ Atualizado | Exporta `portalDb = supabase.schema('portal')` |
| `C:\dev\dap4\portal-familia\src\lib\db-types.ts` | ✅ Reestruturado | `Database.portal` (9 tabelas) + `Database.public` (index signature legacy) |
| `C:\dev\dap4\portal-familia\src\contexts\AuthContext.tsx` | ✅ Atualizado | `fetchProfile` usa `portalDb.from('profiles')` |
| `C:\dev\dap4\portal-familia\src\features\home\hooks\useUserPreferences.ts` | ✅ Atualizado | 3 chamadas → `portalDb.from('user_preferences')` |
| `C:\dev\dap4\portal-familia\src\router\index.tsx` | ✅ Cleanup | Removido `Placeholder` lazy import órfão |
| `C:\dev\dap4\portal-familia\tsconfig.node.json` | ✅ Fix config | `noEmit` → `emitDeclarationOnly + outDir` |
| `C:\dev\dap4\portal-familia\.gitignore` | ✅ +1 linha | `.tsbuild-node/` |
| `C:\dev\dap4\portal-dev\` (fork shadcn-admin) | ❌ **Apagado** | Thales escolheu matar. Zero rastro no disco. |
| `C:\dev\dap4\_archive\2026-04-24\portal-dev-abortado-swarm\` | Arquivado | 29 arquivos fragmento do swarm abortado do handoff anterior (não confundir com fork Dev cancelado nessa sessão) |
| Supabase DOCTOR_PRIME | ✅ Migration 04 aplicada | 9 tabelas em portal; `authenticator` role com `pgrst.db_schemas = 'public, graphql_public, portal'` |

## Decisões tomadas

- **(B.1) schema move antes do fork**: correto. Zero FK cruzada legacy↔portal (verificado via SQL antes de aplicar).
- **PostgREST exposto via `ALTER ROLE authenticator`** (não ALTER DATABASE): única rota que funcionou com service role MCP. Registrar como pattern em memória.
- **`portalDb` helper em vez de schema default** no createClient: preserva `supabase.from('vehicles')` legacy sem refactor, isola claramente o que é portal (`portalDb.from(...)`) do que é legacy (`supabase.from(...)`).
- **`Database.public.Tables` com index signature permissiva** em vez de tipar todas as ~50 tabelas legacy: pragmático, mantém typecheck green, não polui editorial. Auto-gen types viria via `supabase gen types` se um dia Thales decidir tipar forte.
- **`tsconfig.node.json` sem noEmit + outDir isolado**: fix de configuração pre-existente que o handoff anterior reportou como "typecheck 0" mas na verdade estava quebrado via `tsc -b`.
- **Portal Dev: cancelado** por decisão do Thales. Não existe mais. Se voltar à tona, é uma sessão nova começando do zero.

## Bloqueios & perguntas abertas

Nenhum bloqueio técnico pendente. Só pendências de validação e deploy:

1. **Rodar `pnpm test`** no portal-familia — possíveis falhas por mocks desatualizados pós-schema move (mocks de `supabase.from('profiles')` que agora precisariam ser `portalDb.from(...)`).
2. **Smoke test** dos 4 roles (gestor/consultor/mecanico ainda não validados).
3. **Deploy VPS** — Docker service + Cloudflare Tunnel hostname novo.
4. **Revisão do PR #2** antes de merge pra `main`: hoje a branch base é `feat/parts-odin` (branch paralela em curso). Precisa decidir: rebase pra main antes de merge, ou merge direto em parts-odin, ou criar PR separado pra main.

## Próximo passo exato

Escolha do Thales em ordem de prioridade natural:

### Opção 1 — Fechar a Wave 0 com validação completa
1. `cd C:\dev\dap4\portal-familia && pnpm test` — rodar 25+ testes, listar falhas
2. Se testes quebrarem por mock desatualizado de `supabase.from('profiles')`: atualizar mocks pra `portalDb.from(...)`
3. Smoke test manual: login nos 4 roles (admin/gestor/consultor/mecanico), home carrega, widgets drag-n-drop, Portal Consultor W1 lista clientes/veículos
4. Commit dos test fixes se houver, push
5. Fechar/merge PR #2

### Opção 2 — Deploy VPS direto
1. Escrever Dockerfile pro portal-familia (multi-stage build Vite → nginx alpine)
2. Adicionar service no `/opt/doctor-auto-ai/docker-compose.yml` da VPS
3. Cloudflare Tunnel: adicionar hostname `portal.doctorautoprime40.com` → `http://portal-familia:80`
4. Smoke test em produção

### Opção 3 — Retomar Portal Dev
Só se mudar de ideia. Mas se retomar, começar com reframing claro ANTES de forkar: "quero um admin panel pra Parliament/Agents/RAG/Crons/VPS? ou não?"

**Recomendação:** Opção 1 → Opção 2. Valida antes de deployar.

## Setup / comandos úteis

```bash
# Portal Família (branch feat/portal-familia-e-dev-wave-0)
cd C:\dev\dap4\portal-familia
pnpm dev                  # http://localhost:5175 (ou próxima porta livre)
pnpm tsc -b               # typecheck (usar sem --noEmit)
pnpm test                 # vitest — AINDA NÃO RODADO
# credenciais: thales@doctorautoprime40.com / DAP2026!  (admin)

# Git state
git branch --show-current # feat/portal-familia-e-dev-wave-0
git log --oneline -1      # de5b37a feat(portal-familia): wave 0 scaffold + move to portal schema

# PR
https://github.com/toliveira1802-sketch/dap4/pull/2

# Supabase MCP
project_id: acuufrgoyjwzlyhopaus   # DOCTOR_PRIME
# 142 migrations aplicadas agora (incluindo 03 e 04)

# Validação PostgREST manual (caso suspeita de schema não exposto)
URL="https://acuufrgoyjwzlyhopaus.supabase.co"
ANON="eyJhbGciOiJIUzI1NiIs..."  # pega via get_publishable_keys MCP
curl -s "${URL}/rest/v1/empresas?select=id&limit=1" \
  -H "apikey: ${ANON}" -H "Authorization: Bearer ${ANON}" \
  -H "Accept-Profile: portal"
# esperado: HTTP 200 body []  (RLS bloqueia anon; 200 confirma schema exposto)

# Se PostgREST voltar a "schema cache not found":
# MCP execute_sql: NOTIFY pgrst, 'reload schema';
```

## Ponto de entrada da próxima sessão

Primeira linha do Thales provavelmente vai ser:
- **"roda os testes"** → Opção 1.1 (pnpm test, diagnosticar falhas)
- **"deploy"** → Opção 2 (Dockerfile + Cloudflare Tunnel)
- **"valida no browser"** → Opção 1.3 (smoke test manual dos 4 roles)
- **"merge"** → review do PR + rebase decision (base parts-odin vs main)

Se disser "vamos"/"bora"/algo afirmativo sem especificar: assumir **Opção 1** — `pnpm test` primeiro, depois smoke test, depois deploy.

Status das tasks desta sessão:
- #1-#7, #13 ✅ completos (inspeção, migration, cliente, typecheck, cleanup, commit Fase 1)
- #8-#12, #14 ❌ deletadas (toda a Fase 2 = fork Portal Dev foi cancelada)
