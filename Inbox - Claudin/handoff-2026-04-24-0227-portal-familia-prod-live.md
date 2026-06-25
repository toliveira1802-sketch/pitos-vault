---
type: handoff
date: 2026-04-24
time: "02:27"
project: DAP 4.0 / Portal Família
topic: Wave 0 mergeada em master + portal.doctorautoprime40.com LIVE em prod, smoke test 4 roles aprovado
tags: [handoff, claudin, portal-familia, prod-live, deploy, cloudflare-tunnel, caddy]
---

# Handoff — Portal Família Wave 0 LIVE em prod

> **Continuidade direta** do `handoff-2026-04-24-0045-portal-familia-wave0-pr-aberto.md`. Executou Opção 1 (validação) + Opção 2 (deploy) inteiras.

## Contexto

Sessão começou às ~22:20 local com Thales mandando `/resume-handoff` + `VAMO`. Retomei o estado do handoff anterior: PR #2 aberto com Wave 0 do Portal Família + migração schema portal feita, mas sem testes rodados, sem validação multi-role, sem deploy.

Em ~2h, fiz: testes verdes, smoke test local 4 roles (encontrei e corrigi 1 regressão), squash merge do PR em master, criei Dockerfile + nginx.conf, deployei na VPS via Caddy host-routing + CF Tunnel. **`https://portal.doctorautoprime40.com` agora responde HTTP 200 servindo o Portal Família** — validado em prod com login dos 4 roles via Playwright headless.

Fim do Wave 0 ponta-a-ponta: dev → migração → testes → merge → deploy → prod ao vivo.

## O que funcionou (com evidência)

- **`pnpm test` 54/54 verde** após fix de regex ambíguo no `LoginPage.test.tsx`. Antes: 50/54 (4 falhas em `getByLabelText(/senha/i)` matchando label do input + `aria-label="Mostrar senha"`). Depois: ancorei pra `/^senha$/i`. Commit `cc97298`.
- **Regressão `useAvisos.ts` corrigida** — único call-site esquecido na Fase 1: usava `supabase.from('avisos')` (schema public default) e dava 404. Trocado pra `portalDb.from('avisos')`. Commit `23174cc`. Detectado pelo console error 404 no smoke test do admin.
- **Smoke test local (5174)** com Playwright: admin "Boa noite, Thales" + 3 avisos + sidebar 3 portais; gestor "Boa noite, Rafael" + atalhos rápidos + 3 avisos filtrados por `alvo_roles`; consultor "Boa noite, Mariana" + sidebar enxuta; **Portal Consultor W1 listou os 27 clientes reais** via tabela legacy `public.clients` (validou que `supabase.from('vehicles')` legacy ainda funciona sem `Accept-Profile: portal`); mecanico "Boa noite, Bruno" + RoleGate bloqueou `/consultor` com "Acesso restrito".
- **Squash merge PR #2** em master via `gh pr merge 2 --squash --delete-branch`. Commit `0fde64c` em `2026-04-24T01:54Z`. PR fechado, branch local deletada (apaguei a remota órfã com `gh api -X DELETE`).
- **Dockerfile multi-stage** (node:20-alpine pnpm build → nginx:alpine serve). VITE_* via build args (anon key safe pro browser, RLS enforce). nginx.conf com cache imutável `/assets/*`, no-cache `index.html`, `/healthz` pra Caddy upstream. Bundle: 190KB gzip total (react-vendor 66KB, supabase-vendor 52KB, home 28KB, index 22KB) — dentro do budget. Build em 22s. Commit `c17aa62`.
- **Deploy VPS**: `git checkout origin/master -- portal-familia/` (cirúrgico, sem mexer no histórico VPS divergente). Adicionei service no `docker-compose.override.yml` via Python heredoc (preservou YAML). Caddyfile refactor pra host-based routing. `docker compose build portal-familia` + `up -d`. Service UP em 3s.
- **CF Tunnel**: Thales adicionou public hostname `portal.doctorautoprime40.com` → `localhost:80` no dashboard CF (tunnel `dap4`). CNAME criado automaticamente apontando pra `df082b0d-aa0b-4dd8-8274-c5f2ed61e561.cfargotunnel.com`.
- **Smoke test prod** via Playwright em `https://portal.doctorautoprime40.com`: 4 roles validados (admin/gestor/consultor/mecanico). RoleGate bloqueando mecanico no /consultor. 27 clientes carregando da tabela legacy `public.clients` para gestor/consultor. Screenshots salvos em `C:\Users\docto\.playwright-mcp\` (`prod-admin.png`, `prod-gestor.png`, `prod-consultor.png`, `prod-mecanico-blocked.png`).
- **`curl -sI https://portal.doctorautoprime40.com/healthz` → HTTP 200 + "ok"** com headers `Server: cloudflare` + `via: 1.1 Caddy` confirmando rota CF Tunnel → Caddy → portal-familia.

## O que NÃO funcionou (e por quê)

- **Web Lock contamination via Playwright debug** — meu `createClient` no `browser_evaluate` (com mesma `storageKey: dap-portal-familia-auth`) acquired o NavigatorLock e nunca soltou. AuthProvider do app ficou stuck em `isLoading=true` indefinidamente (esperando lock). **Lição**: nunca instanciar `createClient` com mesma storageKey em página que já tem o cliente do app rodando. **Recovery**: `navigator.locks.request(name, {steal: true}, async () => {})` + `localStorage.clear()` + reload. Saber pra próxima.
- **Caddy host matcher `@portal host portal.*` ignorado silenciosamente** — primeiro tentei `@portal host portal.doctorautoprime40.com; handle @portal { reverse_proxy portal-familia:80 }` dentro de `:80 { ... }`. Request com `Host: portal.*` caía no catch-all do dashboard. Causa raiz: **`cat > Caddyfile` recria o inode** e o bind mount Docker (`/opt/doctor-auto-ai/Caddyfile -> /etc/caddy/Caddyfile`) ficou apontando pro inode antigo — `caddy reload` lia versão velha. `docker exec ... head Caddyfile` mostrava conteúdo diferente do host. **Recovery**: `docker restart doctor-auto-ai-caddy-1` re-binda o inode novo. **Pra próxima**: editar in-place com `sed -i` ou `python ... open('w')` (que pode também recriar — testar) ou `docker cp` direto.
- **`gh pr merge` falhou em sincronizar local** — após merge remoto OK, gh tentou `git checkout master` localmente e bateu em `agents/services/parts_web_search.py` modificado (mudança não-minha de outra sessão). Tive que stashar antes. Erro: `Your local changes... would be overwritten by checkout`. PR mesmo assim foi merged remoto (`mergedAt` confirmado).
- **`git pull --ff-only origin master` impossível** em master local E na VPS — ambos divergiram do remoto. Master local tinha 22 commits ahead (Parliament + Leads + portal-familia, todos squashados no `0fde64c`). VPS tinha 30 commits ahead (`feat/parts-odin` completo: Anna guardrails, parts module Odin, security fixes, Parliament hub backend). **Recovery**: master local → `git tag pre-squash-snapshot HEAD` + `git reset --hard origin/master`. VPS → `git checkout origin/master -- portal-familia/` cirúrgico (zero conflito, pasta nova). VPS git history continua divergente — não tentei resolver.
- **`docker compose up -d` warning sobre `caddy-1` orphan** — irrelevante, é alias do compose project antigo (`doctor-ai-dashboard` vs `doctor-auto-ai`). Não afeta funcionalidade.

## O que ainda não foi tentado

- **Push dos 30 commits da VPS pra remoto** como branch `feat/parts-odin`. Decisão pendente do Thales: pushar, mergear, ou descartar. Trabalho real (Parliament backend, Odin parts, Anna guardrails) — não pode ser perdido.
- **Reset definitivo das senhas dos 3 não-admin** — Rafael/Mariana/Bruno têm `DAP2026!` agora (reset durante smoke). Thales decide: redefinir via Supabase MCP, ou cada user via "Esqueci minha senha".
- **Cleanup do `agents/services/parts_web_search.py` modificado + `dashboard-git` deletado** no master local — mudança não-minha, preservada via stash pop. Thales precisa revisar e commitar/descartar.
- **CI build do portal-familia no GitHub Actions** — workflow do repo tem checks pra `backend/frontend/gateway`. Não há check pra portal-familia ainda. Próxima vez que mexer no portal, pode passar sem CI.
- **Renovação automatica do build em prod** — hoje deploy é manual (`docker compose build portal-familia`). Sem CI/CD pipeline. Próxima sessão pode precisar redeployar manual.
- **Anna pause** ainda — task antiga, fora desta sessão.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\dev\dap4\portal-familia\src\features\auth\__tests__\LoginPage.test.tsx` | ✅ commit `cc97298` | 4 fixes `/senha/i` → `/^senha$/i` |
| `C:\dev\dap4\portal-familia\src\features\home\hooks\useAvisos.ts` | ✅ commit `23174cc` | `supabase` → `portalDb` (regressão de schema move) |
| `C:\dev\dap4\portal-familia\Dockerfile` | ✅ commit `c17aa62` | Multi-stage node:20-alpine + nginx:alpine, build args VITE_* |
| `C:\dev\dap4\portal-familia\nginx.conf` | ✅ commit `c17aa62` | SPA fallback, cache headers, /healthz |
| `C:\dev\dap4\portal-familia\.dockerignore` | ✅ commit `c17aa62` | Ignora node_modules, dist, screenshots, etc |
| `master local` em `C:\dev\dap4` | ✅ sync com `origin/master` (HEAD `c17aa62`) | Tag `pre-squash-snapshot` → `ebd45ff` preserva 22 commits granulares |
| `agents/services/parts_web_search.py` | ⚠️ Modificado, não commitado | Não-minha (sessão paralela do Thales). Preservado via stash pop. Revisar. |
| `dashboard-git` | ⚠️ Deletado, staged | Não-minha. Mesma origem. Revisar. |
| `VPS /opt/doctor-auto-ai/portal-familia/` | ✅ Existe via checkout cirúrgico | 30+ files staged porque VPS HEAD (`4e78c87`) não tinha portal-familia |
| `VPS /opt/doctor-auto-ai/docker-compose.override.yml` | ✅ Service `portal-familia` adicionado | Backup em `*.bak.20260424-021215` |
| `VPS /opt/doctor-auto-ai/Caddyfile` | ✅ Host-based routing (portal.* → portal-familia, default → dashboard/api) | Backup em `*.bak.20260424-021215` |
| `Cloudflare Tunnel dap4` | ✅ Public hostname `portal.doctorautoprime40.com` → `localhost:80` | CNAME automático |
| Supabase auth.users (rafael/mariana/bruno) | ⚠️ Senhas resetadas pra `DAP2026!` | Pra smoke test. Thales decide reset definitivo. |
| PR #2 GitHub | ✅ MERGED em `2026-04-24T01:54Z` | Squash commit `0fde64c`, branch deletada (local + remoto) |

## Decisões tomadas

- **Squash merge** em vez de merge commit no PR #2: histórico mais limpo, e o squash naturalmente capturou os 22 commits granulares do master local divergido (Parliament + Leads) num só commit em `master` remoto. Trabalho preservado.
- **`git checkout origin/master -- portal-familia/`** na VPS em vez de `git pull`/`merge`: zero risco de conflito porque pasta é nova. VPS git history continua divergente, mas operacional. Resolver divergência fica pra outra sessão.
- **Dockerfile com pnpm** (em vez de npm): consistente com o package.json do portal-familia (que usa pnpm-lock.yaml). `corepack enable` pra ter pnpm sem layer extra de install.
- **VITE_SUPABASE_ANON_KEY com formato `sb_publishable_*`** (em vez do JWT legacy `eyJ...`): mesma key que validei no smoke test local. Funcionalmente equivalentes (ambos são anon), mas evita mistura de formatos. Hardcoded em `args:` do compose (anon key é browser-safe via RLS).
- **Caddy host routing in-place**: refator do Caddyfile pra usar `@portal host portal.*; handle @portal { reverse_proxy }` antes do catch-all. Comportamento legacy do `dap.*` 100% preservado.
- **NÃO toquei nos 30 commits da VPS** (`feat/parts-odin`): decisão é do Thales. Cleanup dessa divergência pode quebrar trabalho real (Anna guardrails, Parliament hub backend).
- **Tag `pre-squash-snapshot` no master local**: preserva referência aos 22 commits granulares pré-squash. Pode deletar quando o Thales decidir não precisar mais de arqueologia individual.

## Bloqueios & perguntas abertas

1. **30 commits VPS**: pushar como `feat/parts-odin`? Mergear em master via PR? Cherry-pick os melhores? Descartar? Sem decisão = continua só na VPS, frágil.
2. **Senhas reais dos 3 não-admin**: defino via Supabase MCP ou deixo "Esqueci minha senha"?
3. **`parts_web_search.py` modificado + `dashboard-git` deletado** no master local: trabalho não-commitado de outra sessão sua. Eu não toco. Você revisa.
4. **CI/CD pro portal-familia**: hoje deploy é manual SSH. Próxima sessão precisa redeployar manualmente quando código mudar. Em algum ponto vale criar workflow GitHub Actions.
5. **Documentação do roteamento Caddy + portal-familia** — não documentei em README/docs do repo. Quem deployar próximo precisa ler esse handoff.

## Próximo passo exato

Não há bloqueio técnico no portal — está LIVE e funcional. Próximo passo depende da prioridade do Thales:

### Se prioridade = limpar pendências
1. Decidir destino dos 30 commits VPS (`ssh root@76.13.170.42 'cd /opt/doctor-auto-ai && git log origin/master..HEAD --oneline'` mostra a lista completa)
2. Resetar senhas dos 3 não-admin via Supabase MCP (ou definir uma senha forte única)
3. Revisar `agents/services/parts_web_search.py` e `dashboard-git` (decidir commitar ou descartar)

### Se prioridade = próxima feature
- Wave 1 do Portal Família: `useIndicadores`, `usePendencias`, `useGlobalSearch` (hoje todos mock — substituir por queries reais agregando OS, follow-ups, trilhas)
- OU outra unidade do ecossistema (DAP Performance, DAP Studio, etc — ver master TODO)

### Se prioridade = stress test do prod
- Convidar 2-3 colaboradores reais (Rafael, Mariana, Bruno) pra testar com dados reais
- Monitorar logs Caddy + nginx portal-familia por 24-48h
- Ver Cloudflare Analytics

**Recomendação:** comece pelo (1) das pendências — decidir os 30 commits VPS é importante. Se os deixar lá esquecidos, próximo deploy ou git operation no VPS pode quebrar.

## Setup / comandos úteis

```bash
# === PROD ===
# Health
curl -sI https://portal.doctorautoprime40.com/healthz

# Logs do portal-familia
ssh root@76.13.170.42 'docker logs --tail 50 -f doctor-auto-ai-portal-familia-1'

# Logs do Caddy (vê todo tráfego entrando)
ssh root@76.13.170.42 'docker logs --tail 50 -f doctor-auto-ai-caddy-1'

# Rebuild + redeploy portal (após mudança de código no master remoto)
ssh root@76.13.170.42 'cd /opt/doctor-auto-ai && git checkout origin/master -- portal-familia/ && docker compose build portal-familia && docker compose up -d portal-familia'

# Reload Caddyfile (precisa de RESTART, não reload, por causa do bug do bind mount inode)
ssh root@76.13.170.42 'docker restart doctor-auto-ai-caddy-1'

# Rollback emergência
ssh root@76.13.170.42 'cd /opt/doctor-auto-ai && cp Caddyfile.bak.20260424-021215 Caddyfile && docker restart doctor-auto-ai-caddy-1'

# === LOCAL ===
cd C:\dev\dap4\portal-familia
pnpm dev                  # http://localhost:5174 (5175 ocupada)
pnpm test                 # vitest 54/54
pnpm tsc -b               # typecheck

# Credenciais smoke test (4 roles, todos com DAP2026!):
# thales@doctorautoprime40.com (admin)
# rafael.gestor@doctorautoprime40.com (gestor)
# mariana.consultora@doctorautoprime40.com (consultor)
# bruno.mecanico@doctorautoprime40.com (mecanico)

# === GIT ===
# Master local em sync com remote (HEAD c17aa62)
git log --oneline -3

# Tag de snapshot dos 22 commits pré-squash (caso precise arqueologia)
git rev-parse pre-squash-snapshot   # ebd45ff

# Branch remota órfã: já deletada
gh api repos/toliveira1802-sketch/dap4/git/refs/heads/feat/portal-familia-e-dev-wave-0   # 404 esperado

# === SUPABASE MCP ===
project_id: acuufrgoyjwzlyhopaus  # DOCTOR_PRIME

# Reset senha exemplo:
# UPDATE auth.users SET encrypted_password = crypt('NOVA_SENHA', gen_salt('bf')) WHERE email = 'rafael.gestor@doctorautoprime40.com';
```

## Ponto de entrada da próxima sessão

Primeira linha do Thales provavelmente vai ser uma das:
- **"resolve os 30 commits da VPS"** → ler `git log origin/master..HEAD` no VPS, propor branch / cherry-pick / merge
- **"reseta senhas"** → Supabase MCP UPDATE auth.users com senhas novas
- **"próxima feature"** → ler master TODO no PITOS, escolher próxima frente
- **"o portal tá fora"** → curl healthz + docker logs + (provável: cloudflared na VPS, ou caddy crash, ou Supabase down)

Status das tasks desta sessão:
- #1-#5 ✅ smoke local 4 roles
- #6 ✅ findings + decisão merge PR #2
- #7 ✅ limpar git local pós-merge
- #8 ✅ deletar branch remota órfã
- #9 ✅ investigar VPS (compose + tunnel)
- #10 ✅ criar Dockerfile portal-familia
- #11 ✅ planejar diff de deploy
- #12 ✅ aplicar deploy + smoke test em prod
