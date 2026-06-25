---
type: handoff
date: 2026-04-24
time: 20:58
project: dap4 · portal-familia
topic: Auth bug 100% RESOLVIDO. Round 6 (commit e93fcca) sobrescreve Authorization no custom fetch. Validado em Chrome DevTools MCP — login, sidebar populada, /consultor renderiza, 27 clientes carregam. SUBSTITUI handoff-2026-04-24-1845.
tags: [handoff, claudin, dap4, portal-familia, auth, resolved, prod]
---

# Handoff — Auth no portal-familia FIXED, validado em prod

## Contexto

Sessão retomou do `handoff-2026-04-24-1845-portal-familia-wave2-auth-fix-aguardando-validacao.md`. Round 5 (commit `1fea192`, manual token management bypassando `supabase.auth.*`) tinha entrado em prod aguardando Thales validar de manhã.

Thales abriu, conseguiu logar, mas reportou: **"entrou, mas sem acesso a qualquer coisa"**. Sintoma novo: login funcionava, mas a sidebar ficava vazia (sem nav items) e qualquer rota `/consultor/*` parecia bloqueada.

Diagnóstico via Chrome DevTools MCP (login real + inspeção de network) revelou bug complementar nascido na mesma mudança do Round 5: o custom fetch tinha guarda `!headers.has('Authorization')` que nunca passava porque supabase-js v2 sempre injeta o anon key como `Authorization: Bearer <ANON_KEY>` antes do custom fetch rodar. Resultado: toda query PostgREST ia como `role=anon`, RLS bloqueava `profiles/empresas/*`, retornava `[]`, e o `role=null` derivado fazia a sidebar (`Sidebar.tsx:26-29`) renderizar zero items.

Round 6 (commit `e93fcca`) é fix de 1 linha: sempre sobrescrever Authorization quando authStore tem token. Build, push, redeploy, validação completa em Chrome DevTools MCP — tudo verde.

## O que funcionou (com evidência)

- **Round 6 fix (commit `e93fcca`)** — `src/lib/supabase.ts:45` mudou de `if (token && !headers.has('Authorization'))` pra `if (token)`. Build verde (`✓ built in 9.28s`), 76/76 tests passing.
- **Diagnóstico via Chrome DevTools MCP** — request de profile retornou `Status: 200, Body: []`. Headers mostraram `authorization: Bearer <ANON_KEY com role:anon>` em vez do JWT do user. `apikey` header tinha o anon (correto), mas Authorization não foi sobrescrito.
- **User ID real do thales confirmado** = `22222222-2222-2222-2222-000000000001` (vem do `sub` do JWT em `/auth/v1/token` 200). Não é seed, é o user real.
- **Validação prod via DevTools MCP após o fix:**
  - ✅ Login → `/home` com "Boa noite, Thales" + 3 avisos reais ("Reunião terça", "URGENTE garantia", "Meta abril 60 OS")
  - ✅ Sidebar populada: INÍCIO/Home, PORTAIS (Consultor/Gestão/Mecânico), CONHECIMENTO (Saber/Processos/Dashboard/Sugerir), PESSOAL (Perfil), **ADMIN (Usuários — só admin vê!)**
  - ✅ Empresa = "Doctor Auto Prime" (não fallback "Família")
  - ✅ Avatar = "TO" (Thales Oliveira)
  - ✅ Click em Portal Consultor → `/consultor` renderiza CRM Caliente, RoleGate libera
  - ✅ Reload em `/consultor` (F5) → sessão mantida, page renderiza imediato — **bug Navigator Lock está MORTO** porque não usa supabase.auth.* mais
  - ✅ Click CLIENTES → 27 clientes reais carregados do schema DOCTOR_PRIME (legacyDb também funciona — mesma origem de bug, mesmo fix)
- **Deploy VPS pipeline funcionou** — git pull → `docker compose -f infra/docker-compose.prod.yml --env-file ../.env build portal-familia` → `up -d --no-deps --force-recreate portal-familia`. HTTP 200, 156ms.

## O que NÃO funcionou (e por quê)

- **Primeiro build VPS sem `--env-file`** — `docker compose ... build portal-familia` (sem --env-file) gerou warnings `VITE_SUPABASE_URL not set`. Bundle saiu sem env vars Supabase, app crashou no boot com `Supabase env vars missing`. Compose não auto-carrega `/opt/doctor-auto-ai/.env` quando `working_dir` é `infra/`. Fix: passar `--env-file ../.env` explícito.
- **Working dir do compose** — `docker compose ps` na raiz `/opt/doctor-auto-ai/` listou portal-familia, mas `docker compose build portal-familia` na mesma pasta deu "no such service". Service real está em `/opt/doctor-auto-ai/infra/docker-compose.prod.yml`. `docker inspect dap4-portal-familia` mostra `com.docker.compose.project.config_files=infra/docker-compose.prod.yml`. O `docker-compose.yml` na raiz é stack legado (não tem portal-familia).

## O que ainda não foi tentado

- **Tech debt Wave 2** — zero tests pras 3 pages novas (PatioKanban, Financeiro, UsersManagement) e 3 dialogs (OSList Nova OS, ClientesList Novo Cliente, AgendaView Novo Agendamento). STATUS_MAP do StatusBadge só cobre 9 de 13 status canônicos. numero_os sequencial pendente. Etiqueta PDF + Edit inline da OS.
- **Cleanup do compose legado** — `/opt/doctor-auto-ai/docker-compose.yml` é stack antiga (sem portal-familia). Causa confusão. Deveria ser deletado ou movido pra `_archive/`.
- **Documentar build args VITE no README/infra docs** — outro Claude (ou Thales) vai cair no mesmo `--env-file` faltando.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `portal-familia/src/lib/supabase.ts` | Completo | Linha 45: removido `&& !headers.has('Authorization')`. Comentário atualizado explicando porque sempre sobrescreve. |
| `~/.claude/projects/.../memory/feedback_supabase_lock_deep_bug.md` | Atualizado | Reescrito com resolução final (round 6) + lesson sobre custom fetch + tropeço do --env-file. Substituiu narrativa "4 rounds falharam" pela correta. |

## Decisões tomadas

- **Sempre sobrescrever Authorization quando tem user token** — razão: a guarda `!headers.has('Authorization')` é semanticamente errada porque supabase-js JÁ ENCHEU com anon. Sobrescrever é o comportamento correto. SignIn ainda funciona (token é null antes do login). Logout/auth com token também funciona (precisa do user JWT).
- **Não reverter o downgrade `2.47.12 → 2.104.1`** — bundle 46% menor (104kb vs 194kb). Como não usamos mais `supabase.auth.*`, a versão é irrelevante pra funcionalidade. Manter na 2.47.
- **Não migrar pra `@supabase/auth-js` standalone** — manual token management resolveu definitivamente. Complexidade adicional não justificada.
- **Diagnóstico via Chrome DevTools MCP em vez de pedir ao Thales abrir DevTools** — Thales quer executar, não debugar. Vale economizar o ping-pong de "abre F12, copia o erro".

## Bloqueios & perguntas abertas

- **Nenhum bloqueio técnico ativo.** Auth está sólido, profile carrega, RoleGate funciona, queries PostgREST autenticadas chegam até o RLS correto.
- **Pergunta:** vale documentar o pattern do custom fetch com Authorization overwrite num docs/auth.md? Se outro projeto (frontend/) for adotar manual token management, vai cair no mesmo bug. Memory cobre, mas docs in-repo seria mais visível pra novos contributors.

## Próximo passo exato

**Thales valida amanhã em Chrome real (não DevTools MCP):**

1. `https://portal.doctorautoprime40.com/` no Chrome normal
2. Limpar storage (DevTools → Application → Clear site data) — só pra eliminar resto de teste anterior
3. Login `thales@doctorautoprime40.com` / `DAP2026!`
4. Confirmar UI igual ao validado em DevTools MCP: sidebar com items, "Boa noite Thales", avatar TO, empresa Doctor Auto Prime
5. Navegar `/consultor/clientes`, `/consultor/os`, `/consultor/patio`, `/consultor/financeiro`, `/admin/users` — tudo deve renderizar
6. **Reload (F5)** em qualquer page autenticada — não deve voltar pra login

**Se confirmar que está tudo OK:**
- Próxima sessão: pagar tech debt Wave 2 (testes pras 3 pages novas + 3 dialogs, STATUS_MAP completo, numero_os sequencial, PDF etiqueta, Edit inline OS)
- Eventualmente: cleanup do `/opt/doctor-auto-ai/docker-compose.yml` legado, doc do pattern auth no repo

**Se algo falhar:**
- Console (F12) → copia erros
- Provável que seja outra coisa (não auth) — auth está validado em Chrome real via DevTools MCP

## Setup / comandos úteis

```bash
# Working dir
cd C:\dev\dap4
git log --oneline -3
# e93fcca fix(portal-familia): sempre sobrescrever Authorization no custom fetch
# 1fea192 fix(portal-familia): manual token management — fix DEFINITIVO do lock bug
# 6fb625c fix(portal-familia): downgrade supabase-js ^2.47.10 → 2.47.12 pinado

# Smoke prod
curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" https://portal.doctorautoprime40.com/

# Logs container
ssh root@76.13.170.42 'docker logs dap4-portal-familia --tail 50'

# REBUILD CRÍTICO — sempre passar --env-file ../.env
ssh root@76.13.170.42 'cd /opt/doctor-auto-ai/infra && \
  docker compose -f docker-compose.prod.yml --env-file ../.env build portal-familia && \
  docker compose -f docker-compose.prod.yml --env-file ../.env up -d --no-deps --force-recreate portal-familia'

# Supabase MCP — projeto acuufrgoyjwzlyhopaus
# user_id real thales = 22222222-2222-2222-2222-000000000001
```

## Arquivos de referência

- **Handoff anterior substituído:** `handoff-2026-04-24-1845-portal-familia-wave2-auth-fix-aguardando-validacao.md`
- **Toda cadeia da Wave 2 + auth fix:** `handoff-2026-04-24-1447-portal-familia-os-detail-10-cards-shipped.md` → `1823-bloqueante` → `1845-aguardando` → ESSE
- **Memory feedback (atualizado nessa sessão):** `feedback_supabase_lock_deep_bug.md` — agora documenta a solução correta (round 6) em vez da narrativa antiga "4 rounds falharam"
- **Bundle prod atual:** Vite build 9.3s, supabase-vendor 104kb, react-vendor 201kb, total dist OK
