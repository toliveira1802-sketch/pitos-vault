---
title: Handoff — Portais por subdomínio + consolidação vault
date: 2026-06-04
status: handoff (retomada)
scope: sessão de subdomínios, consolidação do vault, inventário de chaves
relacionado: "[[00-TODOS-THALES]] · [[00-MAPA-ECOSSISTEMA]] · [[000-CANON]]"
---

# Handoff — 2026-06-04 · Portais por subdomínio

## 1. Resumo executivo

Sessão longa, três frentes entregues:
1. **Vault consolidado** — duplicata de sync resolvida, árvore do ecossistema criada (mapa de domínios, 12 unidades, 4 portais, canon v1.1, template de unidade).
2. **Segurança** — 29 segredos mapeados em `Infra/_secrets/KEY-INVENTORY.md` (achado: `KEYS.md` com chaves live no OneDrive/git).
3. **3 portais no ar por subdomínio** — `consultor.*`, `mecanico.*`, `gestao.*` (→ módulo AIOS) servindo do `aios-staging`.

Arquitetura travada (opção A): `doctorautoprime40.com` = institucional (futuro); cada subdomínio fixa um portal do **mesmo app** `dap-aios` (1 banco, 1 login, event log central). `aios.*` = hub; `ai.*` (futuro) = dashboard dap4.

## 2. Estado atual (o que está no ar)

| Subdomínio | Aponta | Status |
|---|---|---|
| `consultor.doctorautoprime40.com` | aios-staging /consultor | ✅ 200 |
| `mecanico.doctorautoprime40.com` | aios-staging /mecanico/patio | ✅ 200 |
| `gestao.doctorautoprime40.com` | aios-staging /gestao/comercial | ✅ 200 |
| `aios.doctorautoprime40.com` | hub completo | ✅ intacto |
| app DAP Gestão `:5003` | (órfão de subdomínio) | 🟡 roda, sem DNS |

**Infra:** tunnel `dap4` ingress v30; DNS CNAMEs consultor/mecanico proxied; Caddy `/opt/doctor-auto-ai/infra/Caddyfile` com handles consultor/mecanico/gestao → `aios-staging:5050`. Backups: imagem `dap-aios:staging-bak-2026-06-04`, `Caddyfile.bak-2026-06-04`, vault em `C:\THALES\DAP4.0\_backups\`.

**Git:** PR **#40** (routing) verde, aguardando review do Thales (branch protection). VPS `/opt/dap-aios/src` = `origin/main` (0da664f) + 2 arquivos de routing drift (limpa com reset após merge do #40).

## 3. Próximos passos (ordem sugerida)

1. **[Thales] Revogar CF token** + **rotacionar chaves** (ver [[00-TODOS-THALES]]).
2. **[Thales] Aprovar/mergear PR #40** → Claude faz `git reset --hard origin/main` na VPS (limpa drift, no-op funcional).
3. **Deploy dos 30 commits** (ver §4) — quando o Thales decidir.
4. **gestao :5003** — aposentar ou novo subdomínio (decisão Thales).
5. **Descritivos das unidades** (§5, paralelo).
6. **Camada A lacunas + Camada B** (Fundação).

## 4. Plano — deploy da branch de 30 commits

**Branch:** `feat/ai-sprint4b-anna-shadow-ui` (121 arquivos, +16299/-4020).
**Conteúdo:** cancelar OS, cadastro de cliente, gestão dashboard (`/gestao/dashboard`), marketing content calendar, mudanças de auth (validação JWT local HMAC, fail-closed), appointments.

**Migrations (RISCO BAIXO — confirmado):** 2 migrations **puramente aditivas**:
- `0001_…` → `CREATE TABLE appointments` (+ FKs restrict customer/vehicle + índices).
- `0002_…` → `CREATE TABLE content_items` (+ FK users + índices).
- **Nenhum ALTER/DROP em tabela existente, nenhuma mudança de dado.** Reversível (drop das 2 tabelas novas se preciso).

**Riscos reais:** o código (auth fail-closed pode afetar login; UI nova). Mitigado pelo CI (test+coverage + smoke E2E) e pelo backup de imagem.

**Plano de execução:**
1. **Abrir PR** `feat/ai-sprint4b-anna-shadow-ui` → main. Deixar o CI rodar (typecheck/lint/test/smoke/gitleaks). *(não-destrutivo)*
2. **Revisar** o diff + o resultado do CI. Resolver qualquer check vermelho.
3. **Conflito esperado com #40:** a branch usa `/gestao/dashboard`; o #40 usa `/gestao/comercial`. Ordem: mergear **#40 primeiro**, depois rebasear esta branch (mantém `/gestao/dashboard` — a página dashboard vem junto). Ou incluir o routing nesta branch e fechar o #40.
4. **Backup do banco** antes do merge (snapshot Supabase DAP AIOS).
5. **Merge** → main.
6. **Deploy VPS:** `cd /opt/dap-aios/src && git fetch && git reset --hard origin/main && docker build -t dap-aios:staging . && cd /opt/doctor-auto-ai && docker compose up -d --force-recreate aios-staging`.
7. **Rodar migrations** contra o Supabase de prod (drizzle migrate ou `pnpm db:push` conforme o runbook do projeto) — as 2 tabelas novas.
8. **Smoke:** healthcheck + login + abrir consultor/gestao/mecanico + criar um appointment de teste.
9. **Rollback se quebrar:** `docker tag dap-aios:staging-bak-… dap-aios:staging` + recreate; migrations são drop-safe.

> Fazer em **sessão dedicada**, com o Claude conduzindo passo a passo e o Thales disponível pra o gate de merge + decisão de migration.

## 5. O que rodar em PARALELO e com SUBAGENTES

**Frentes independentes (sem estado compartilhado → paralelizáveis):**

| Frente | Paraleliza? | Subagente? | Como |
|---|---|---|---|
| **Descritivos das 12 unidades** (`Ecossistema/*/README.md`) | ✅ total | ✅ **1 subagente por unidade** | Cada subagente preenche oferta/mercado/RAG a partir de notas + código existente; Thales valida/ajusta. Frente clássica de fan-out. |
| **Camada A — lacunas** (vitest no client no CI, coverage threshold, runbook de deploy) | ⚠️ parcial | ✅ 1 subagente | Mudanças no `dap-aios` (CI yml + config). Sequencial entre si, mas independente das outras frentes. |
| **Camada B — agent harness** (roster, hooks, quality gates, /nova-unidade) | ⚠️ parcial | ✅ subagentes por componente | Independente. Próprio plano. |
| **Provisionar colaboradores** | ✅ | ✅ 1 subagente | Após Thales dar nomes+emails. Cria users Supabase + role. |
| **Site institucional** (raiz) | ✅ total | ✅ frente própria | Projeto à parte, não bloqueia nada. |

**NÃO paralelizar / não-subagente-cego (sequencial, alto cuidado):**
- Deploy dos 30 commits (§4) — toca prod + migrations. Sequencial, Claude conduz.
- Qualquer mudança de infra prod (Caddy, tunnel, container) — uma de cada vez.
- Operações git em branch compartilhada (main).
- Rotação de chaves — Thales executa.

**Recomendação de orquestração:** enquanto o Thales rotaciona chaves + revisa o PR #40 (frente dele), o Claude pode rodar **em paralelo via subagentes**: (a) descritivos das 12 unidades, (b) Camada A lacunas. Fan-out de ~12 subagentes pra (a) + 1 pra (b). Convergir, Thales revisa.

## 6. Detalhes técnicos pra retomar (Claude)

- **Repos:** `C:\THALES\DAP4.0\dap-aios` (portais, git real) · `C:\THALES\DAP4.0\dap4` (dashboard IA).
- **VPS:** `root@76.13.170.42`. aios-staging publicado em `:5001`, servido via Caddy `:80`. Repo VPS: `/opt/dap-aios/src`. Compose: `/opt/doctor-auto-ai/docker-compose.yml`.
- **pnpm gotcha:** `export PATH="/c/Users/docto/AppData/Roaming/npm:$PATH"` antes de pnpm/commit (senão Husky falha).
- **Origin:** `github.com/toliveira1802-sketch/dap40-perple-claude`. Fluxo: feature branch → PR → squash em main → VPS reset+rebuild.
- **CI:** `.github/workflows/{ci,e2e,security}.yml`. Blocking: Smoke E2E (critical). "E2E Playwright" é informacional (flake no setup de DB).
- **CF:** zone `bab60229484c4807ba5f7fa0cace90ec`, account `6df6842c547c8b3f420e14789f500501`, tunnel `df082b0d-…`. (Token de hoje a revogar.)
- **Lixo no repo dap-aios** (untracked, ignorar/limpar): `.agents/`, `dap-aios.zip` (17MB), `Nova pasta.zip`.
