---
type: handoff
date: 2026-06-04
time: "16:22"
project: dap-aios
topic: Deploy Sprint 4b + fix compose + usuários teste + spec/plano da refatoração de portais (role aios) + home Cliente de exemplo
tags: [handoff, claudin, dap-aios, arquitetura, portais]
---

# Handoff — Arquitetura dos portais (role AIOS) + entregas de deploy/usuários

> Sessão longa e multi-frente. Começou retomando o estado anterior (limpeza pós-merge),
> passou por deploy + infra + usuários, e terminou numa frente nova de **brainstorming →
> spec → plano** pra refatorar a arquitetura dos portais, mais uma **home do Cliente de
> exemplo**. Nada da refatoração foi executado ainda — só desenhado e planejado.

## Contexto

O `dap-aios` serve 1 app (React+Wouter hash routing, Express) em todos os subdomínios, com
o portal fixado por hostname. Hoje a navegação tem **3 paradigmas brigando** (ConsultorNav,
GestaoNav hierárquicos + LegacyNav multi-portal). O Thales quer **refatorar a arquitetura
visual/de navegação**: unificar num modelo hierárquico, criar um role **`aios`** que navega
TODOS os portais mas é **read-only** (não grava no banco), isolar os operacionais no próprio
portal, e **matar Calculadoras** da nav (vira embutida no futuro). Também validou uma **home
do Cliente** (mobile-first, bottom-tab) a partir de um print.

## O que funcionou (com evidência)

- **Limpeza pós-merge** — branches `feat/consultor-sprint4b-test-debt`, `feat/gestao-portal`, `fix/db-ssl-pooler`, `feat/consultor-subdomain-routing` deletadas (local+remoto onde aplicável); worktree `dap-aios-gestao` removido. Evidência: `git worktree list` e `git branch` limpos; main em `93ae1a8`.
- **Deploy Sprint 4b → staging** — VPS `/opt/dap-aios/src` `d44f564 → 93ae1a8`, rebuild da imagem `dap-aios:staging`, recreate do container. Evidência: 4 subdomínios (`aios/consultor/mecanico/gestao.doctorautoprime40.com/api/health`) → **HTTP 200**, uptime ~29s (container novo).
- **Fix do `docker-compose.staging.yml`** — PR **#45** squash-merged em `main` (`e66e8ba`). `expose` → `ports: 127.0.0.1:5001:5050` (sem isso o cloudflared não alcança o container; bind loopback é hardening P1 do review). Evidência: container roda `127.0.0.1:5001->5050`, `ss` confirma loopback, 4 subdomínios 200. Override temporário removido da VPS.
- **3 usuários de teste** criados no banco `hlhf` (schema `public`): `consultor.teste@` (consultor), `gestao.teste@` (gestor), `mecanico.teste@` (mecanico), senha `12345678`. Evidência: login **E2E em produção** validado (Supabase Auth → JWT → `/api/me` retornou role + allowedPortals corretos pros 3).
- **Mapa da arquitetura atual** (Excalidraw) — 6 portais × telas reais + dívidas. Aprovado como base.
- **Spec da refatoração** — `docs/superpowers/specs/2026-06-04-arquitetura-portais-design.md`, design aprovado pelo Thales ("CONFIRMADO").
- **Plano de implementação** — `docs/superpowers/plans/2026-06-04-refatora-portais-aios.md`. F1 (backend) 100% executável com TDD + código real; F2–F5 como roadmap.
- **Home do Cliente de exemplo** — renderizada no app real. Evidência: screenshot em `localhost:5050/#/cliente` (logado como consultor.teste) bate com o mock do Thales; typecheck + lint verdes. Topbar removida a pedido dele.

## O que NÃO funcionou (e por quê)

- **Playground HTML de design system** (skill `playground`) — Thales rejeitou: "não é esse o portal e não dá pra fazer nada". Era um preview genérico de tokens, não os portais reais. **Lição:** ele quer ver/editar o PORTAL REAL ou um diagrama editável, não um mock HTML de tokens. Pivotou pro Excalidraw (aprovado).
- **Screenshot do Chrome DevTools saiu preto** na 1ª tentativa — timing de paint (DOM renderizado no a11y tree, mas pixel não pintado). Resolvido com `navigate reload` + `new_page` + `wait_for` antes do screenshot.
- **`docker compose -f staging.yml up aios-staging` "no such service"** inicialmente — o serviço não está no compose do dap4 (`/opt/doctor-auto-ai`); vive em `/opt/dap-aios/src/docker-compose.staging.yml` e roda com `-p doctor-auto-ai`. Topologia divergia do que os handoffs diziam (ver dívidas).

## O que ainda não foi tentado

- **Executar o F1** do plano (guard read-only + allowedPortals + role aios no banco). Deixado pra sessão fresh (sessão já longa; testes rodam contra Supabase remoto, lento + risco wipeAll).
- **F2–F5** (frontend: nav declarativa, Sidebar unificada, modo AIOS multi-seção, remover calc, mecânico hierárquico) — roadmap, não detalhado.
- **Loop visual no Vite** das telas existentes (era o pedido original do Thales: ver portal real + falar alterações ao vivo). Só a home do Cliente passou por isso.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `docker-compose.staging.yml` | Completo (merged main #45) | `ports: 127.0.0.1:5001:5050` + header reescrito |
| `client/src/modules/cliente/components/ClienteShell.tsx` | Completo (commit local) | shell mobile, bottom-tab, sem topbar |
| `client/src/modules/cliente/pages/ClienteHomePage.tsx` | Completo (commit local) | home mock fiel ao print |
| `client/src/App.tsx` | Completo (commit local) | rota `/cliente` |
| `docs/superpowers/specs/2026-06-04-arquitetura-portais-design.md` | Completo (commit local) | spec aprovado |
| `docs/superpowers/plans/2026-06-04-refatora-portais-aios.md` | Completo (commit local) | F1 executável + roadmap |
| `server/src/middleware/aiosReadOnly.ts` | **Não iniciado** | criar no F1 (código pronto no plano) |
| `server/src/middleware/requireAuth.ts` | Não iniciado | F1: idempotência + 'aios' em OVERRIDABLE_ROLES |
| `server/src/routes/index.ts` | Não iniciado | F1: choke point `app.use('/api', requireAuth, aiosReadOnly)` |
| `server/src/routes/me.ts` | Não iniciado | F1: PORTAL_VISIBILITY ajustado |

## Decisões tomadas

- **AIOS = role próprio `aios`** (não o admin redefinido) — admin continua super-user que escreve tudo; aios é observação pura. Razão: Thales quer inspecionar sem risco e agir quando quer.
- **Read-only via guard no servidor** (choke point `/api`, bloqueia POST/PUT/PATCH/DELETE → 403 `AIOS_READ_ONLY`) — não confia no front. Botões ficam clicáveis; toast no client.
- **Calculadoras fora da nav agora** (código dorme, rotas resolvem por URL direta) — embutir nos portais é futuro.
- **Cliente = shell próprio** (bottom-tab, mobile-first) — não usa a Sidebar; não entra em `PORTAL_ROUTES` até virar portal de verdade.
- **`admin` vê tudo com escrita** (mesmas seções do AIOS, mas read-write).
- **Sidebar AIOS colapsável na ordem fixa** 1.AIOS · 2.Gestão · 3.Consultor · 4.Mecânico · 5.Cliente.
- **Bind `127.0.0.1:5001`** no compose (não `0.0.0.0`) — hardening P1 do review automático.
- **Handoff em `Status/`** (não `Inbox - Claudin/`) — segue o CLAUDE.md do projeto pra rodadas DAP 4.0, apesar do template do /handoff apontar pro Inbox.

## Bloqueios & perguntas abertas

- **Dívida de infra (não-documentada antes):** `aios.*` NÃO passa pelo dap4-caddy (Caddyfile só roteia `portal.*`/`dap.*`); os 4 subdomínios entram via **cloudflared → `localhost:5001` → container**. Existe um **systemd `dap-aios` legado** servindo `:5050` de um `dist` de 6/mai (`/opt/dap-portals`) — órfão, candidato a desligar. O `docker-compose.staging.yml` do repo agora reflete a realidade (merged).
- **Pós-merge do F1:** rodar `ensure-aios-role.ts` no banco `hlhf` + criar usuário `aios@doctorautoprime40.com` (senha forte, não `12345678`).
- **Risco do choke point:** assume que toda rota `/api` (exceto health) exige auth — conferir se algum router é público (webhook) antes do merge do F1.

## Próximo passo exato

**Executar o F1 do plano** (`docs/superpowers/plans/2026-06-04-refatora-portais-aios.md`), começando pela **Task 1, Step 1**: criar `server/test/integration/aios-readonly.test.ts` (código já está no plano), rodar e ver falhar, depois criar `aiosReadOnly.ts` + idempotência no `requireAuth` + choke point no `registerRoutes`. Tudo na branch `feat/refatora-portais-aios` (já existente, **NÃO pushada**). ⚠️ Conferir `DATABASE_URL` aponta pro schema `test` antes de rodar testes (wipeAll).

## Setup / comandos úteis

- Branch: `feat/refatora-portais-aios` (4 commits locais, em cima de `main`/`e66e8ba`, **não pushada**).
- Dev server rodando em `localhost:5050` (pode ter sido encerrado ao fechar a sessão; `pnpm dev` na raiz pra subir).
- pnpm fora do PATH: `export PATH="/c/Users/docto/AppData/Roaming/npm:$PATH"` antes de pnpm/commit (husky).
- Excalidraw: dois diagramas gerados nesta sessão (mapa atual + modelo-alvo) — viraram a base do spec.
- VPS deploy canônico agora: `cd /opt/dap-aios/src && git reset --hard origin/main && docker build -t dap-aios:staging . && docker compose -p doctor-auto-ai -f docker-compose.staging.yml up -d --force-recreate aios-staging`.
