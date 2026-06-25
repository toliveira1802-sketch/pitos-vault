---
type: handoff
date: 2026-05-19
time: "04:00"
project: dap-aios
topic: R15 mergeada mas "não dá pra atuar como consultor" — investigar primeira coisa em R16
tags: [handoff, claudin, dap-aios, r15, role-switcher, bug, prioridade-alta]
---

# Handoff — Início da próxima sessão · Bug "não atua como consultor" pós-R15

## TL;DR

R15 entregou polish do role-switcher (dropdown custom + pill flutuante + in-memory only + hook centralizado). PR #4 aberta com base `main`. **Mas Thales reportou que ainda não consegue atuar como consultor.** Smoke real no browser não rodou durante a R15 — só smoke automatizado (pnpm check / test / build verdes).

**Primeira coisa da próxima sessão:** abrir o app no browser, reproduzir o bug, e seguir o checklist de hipóteses no handoff R15 (§8.1) antes de propor qualquer fix.

## Contexto da R15 (o que ficou no codebase)

Branch local + remote: `feat/r15-role-switcher-polish` · commit `d21fd64` · PR #4

Arquivos R15 (7):
- `client/src/shared/components/RoleOverrideBadge.tsx` (novo, pill flutuante `fixed top-3 right-3`)
- `client/src/auth/useRoleOverride.ts` (novo, hook agregador)
- `client/src/auth/roleOverride.ts` (refatorado — in-memory only, apagou sessionStorage)
- `client/src/auth/RoleSwitcher.tsx` (custom dropdown com Check + reset + loading)
- `client/src/shared/components/Layout.tsx` (removeu RoleOverrideBadge inline do header)
- `client/src/App.tsx` (monta RoleOverrideBadge global após AppRoutes)
- `e2e/role-switcher.spec.ts` (6 cenários, não rodou local sem env Supabase)

124/124 vitest verdes. Bundle gzip +733 bytes vs R14.

## Reclamação Thales (verbatim 2026-05-19)

> "ok... mas ainda nao da pra atuar como consultor... faz o handoff pra proxima seçao e adiciona esta reclamaçao."

## Hipóteses ordenadas (alta → baixa probabilidade)

1. **Backend ignora `x-aios-role-override` em modo Supabase Auth real**
   - `roleOverride.ts` deixa claro que validação real está em `requireAuth` no server. Comentário literal: "quem manda x-aios-role-override sem ser admin é ignorado pelo server".
   - Em modo stub (sem env Supabase), o header é respeitado livremente (visto nos testes R10/R11/R12: `role-override actor=u_admin admin→mecanico`).
   - Em modo Supabase Auth ativa (`.env` tem `SUPABASE_URL` + chaves) — **não confirmado** que o header role-override seja respeitado. Pode ser que só admin com JWT válido + lookup local consiga fazer override.
   - **Check:** `grep -rn "x-aios-role-override\|role-override\|roleOverride" server/src/` e ler.

2. **`useMe` cacheia com `staleTime: 30_000`** mesmo após `invalidateQueries`
   - `invalidateQueries` força refetch, mas se houver race entre refetch e re-render, sidebar pode permanecer legacy renderizada (até `me.roleKey` atualizar).
   - **Check:** browser DevTools → React Query devtools → `['me']` antes e depois do click.

3. **User logado do Thales não tem `realRoleKey = 'admin'` no banco**
   - Sem isso, dropdown nem aparece (Sidebar.tsx renderiza `<RoleSwitcher>` só pra admin).
   - **Check:** `SELECT id, email, role_key FROM users WHERE email = '<email do Thales>'`.

4. **`/api/me` retorna `allowedPortals` errado após override** → `RouteGuard` redireciona
   - Se backend respeita override mas devolve `allowedPortals = ['admin']` em vez de `['consultor']`, RouteGuard joga o user de volta pra `/admin` (que não existe) ou `/login`.
   - **Check:** Network tab → `/api/me` payload após click no consultor.

5. **Backend permite override mas páginas Consultor exigem permissão específica que admin não herda**
   - Ex: `/consultor/os` exige `service_orders:read`. Se admin não tem essa permissão direta (só via wildcard ou roles herdadas), `consultor` overrideado vira admin-real no check de permissão → 403.
   - **Check:** abrir uma página Consultor após troca, ver se loga ou retorna 403.

## Onde olhar primeiro (5 minutos)

```bash
# 1. Server middleware role-override
grep -rn "x-aios-role-override\|role.override\|roleOverride" server/src/

# 2. requireAuth lógica completa
cat server/src/middleware/requireAuth.ts   # ou wherever ele estiver

# 3. /api/me handler
cat server/src/routes/me.ts

# 4. Browser smoke
pnpm dev   # já está rodando provavelmente, :5050
# → login no browser → DevTools Network → click dropdown → consultor → observar /api/me payload
```

## O que NÃO fazer antes de inventariar

- Não refatorar `requireAuth` no server sem confirmar que ele é a raiz
- Não mexer no caminho A da R13 (sidebar nova) sem ter certeza que a lógica `me.roleKey === 'consultor'` é o problema
- Não reativar sessionStorage no `roleOverride.ts` "pra resolver" — refresh limpar é decisão explícita R15

## Estado git no início da próxima sessão

- `main` HEAD = `8a7218c` (Merge PR #3, R14)
- PR #4 (R15) ainda aberta, branch local `feat/r15-role-switcher-polish` em `d21fd64`
- Branches mergeadas (R13 + R14) deletadas local. Remote ainda existe pra `feat/r13-c1-postgres-dev` (pausado), `feat/r13-sidebar-consultor`, `feat/r14-dashboard-consultor`, e várias R11.1/R12 c1-c5 (limpeza pendente).
- `feat/r13-c1-postgres-dev` segue pausado (Postgres) — não mexer.

## Decisão sugerida pra próxima sessão

Antes de codar R16 (Dashboard Operacional real), atacar este bug primeiro. Pode virar:
- **R15.1** — bug fix do role-switcher, commit no mesmo branch ou novo `fix/r15-role-override-server`
- Ou rebobinar R15 inteira se a raiz for arquitetural (improvável)

Mas confirma com Thales antes de virar conserto grande — pode ser que só smoke manual + ajuste de 2 linhas no server resolva.

## Memórias relevantes (já salvas pra dap-aios)

- [[feedback-no-stack-change-without-driver]] — não mudar stack sem driver de negócio
- [[feedback-secrets-never-in-chat]] — `.env.local` + `process.env`, nunca chat
- [[project-r13-paused]] — Postgres pausado, branch parada
- [[project-r12-next]] — agora desatualizado, R12+R13+R14+R15 todos entregues
