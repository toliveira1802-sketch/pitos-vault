---
title: Handoff — Parliament backend pronto, cutover RC1→prod pausado
date: 2026-04-22
time: 23:30
session: claude-opus-4-7-1m
branch: feat/kommo-prod-rc1 (local + origin)
prod_branch: feat/whatsapp-kommo (80 commits atrás)
next_step: executar runbook cutover RC1→prod em janela dedicada com Thales
tags: [dap4, handoff, parliament, cutover, runbook]
---

# Handoff — 2026-04-22 23:30 (Parliament backend completo, prod cutover pausado)

Sessão de ~3h executando o plano Parliament C-Level backend (#22) em TDD com agents paralelos. Backend pronto, testado, committado, pushado, migration aplicada no Supabase. **Cutover pra produção pausado** após descoberta de que `feat/whatsapp-kommo` (prod) está 80 commits atrás e a migração envolve mudanças arquiteturais (Caddy→Cloudflared, volumes renomeados, dashboard container novo) que precisam de runbook com supervisão.

**Bundle frontend no ar:** versão antiga (`<title>Doctor AI — Command Center`) — não tem Pulse, Parliament, Cérebro, Vault. Prod é pre-19/04.

---

## ✅ Entregues nesta sessão

### Parliament backend completo (18 commits em `feat/kommo-prod-rc1`)

| Commit | O que |
|---|---|
| `2361cf3` | docs spec Parliament C-Level backend |
| `a363057` | docs plan 15 tasks TDD |
| `810b87c` | migration schema 6 tabelas |
| `be2eb0c` | seed 13 diretores (Sennin Protocol) |
| `a8d7844` | seed subagents+crons+skills+junction |
| `26d6bba` | Pydantic models Director/Subagent/Cron/Skill |
| `de40dc1` | list_directors + get_director |
| `8de1c1b` | toggle_subagent + toggle_cron |
| `3a02643` | test_skill LLM role-play runner |
| `6254039` | guards subagent_paused + cron_paused |
| `9cef558` | GET /directors routes |
| `cf2ade6` | POST toggle routes |
| `467d8cf` | POST skill test route |
| `a4f9c97` | gateway forwarders (5 routes TS) |
| `5179f75` | Ana kommo_chat honra parliament_subagents.active |
| `20e154d` | fix security META_APP_SECRET fail-closed |
| `dccf449` | fix security legacy webhook timingSafeEqual |
| `cf00bb8` | fix security require META_APP_SECRET at startup |

**Tests:** 38 Python + 5 Vitest TypeScript, todos green. Coverage: `parliament.directors` 100% · `parliament_guards` 82%.

### Supabase migration aplicada (project DAP4.0 = `cpzgtfblywexqglqkgbt`)

Via MCP `apply_migration` + `execute_sql` (payload dividido por causa de CF block). 2 migrations gravadas:
- `parliament_clevel_01_schema` — 6 tabelas + 2 triggers
- `parliament_clevel_02_directors` — seeds

Counts finais (verificados):
```
directors: 13 · subagents: 3 · crons: 3 · skills: 56 · junction: 64 · ana_active: false
```

**Kill-switch migrou de envvar pra DB** (esperando código consumir).

### Push GitHub resolvido

`gh auth setup-git` configurou credential helper via GitHub CLI token (escopo `repo`). Push no `feat/kommo-prod-rc1` bem-sucedido, branch agora no origin com todos os 18 commits.

### Guardrails Anna draft

`PITOS/DAP 4.0/Frameworks Operacionais/anna-guardrails.md` (453 linhas). **3 pontos pedem decisão do Thales** (Agent C marcou):

1. **Seção 2.1 (preço)** — v1 binário recomendado (qualquer 2º pedido de preço = escala automática). Exceção controlada recalibra depois de 50+ conversas reais.
2. **Seção 7.8** — frase "Anna é humana?" com implicação LGPD/CONAR marcada como apêndice A2.
3. **Stage IDs Kommo Prime** — pipeline_id ainda pendente (bloqueia #21).

### Backup VPS completo

Salvo em `/root/backup-cutover-2026-04-22-0057/`:
- `.env.recovered` (18 envvars extraídas de docker inspect dos 4 containers rodando)
- `doctor-auto-ai-{python-agents,gateway,caddy,chromadb}-1.inspect.json` (full state)
- `env.python-agents.txt`, `env.gateway.txt`, `env.caddy.txt`

### Framework Leads Novos arquivado (sessão anterior + esta)

`PITOS/DAP 4.0/Frameworks Operacionais/` tem:
- `DAP_Framework_Leads_Novos.pdf` (8 páginas, scoring 5 eixos, 4 tiers)
- `framework-leads-novos.md` (SQL schema + impacto DAP 4.0)
- `anna-guardrails.md` (draft pra revisão)

---

## 🛑 Descoberta crítica (não sabíamos ontem)

**`feat/whatsapp-kommo` é 80 commits atrás de `feat/kommo-prod-rc1`.**

Merge-base = 210e6e7 = HEAD do whatsapp-kommo. Ou seja, kommo-prod-rc1 é superset fast-forward.

Produção hoje serve código PRE-19/04 sem:
- Parliament (nem deliberativo topics/voices, nem C-Level)
- Pulse, Cérebro, Vault, Sophia Hub (páginas novas)
- Sennin Protocol frontend
- Security hardening (Meta fail-open vulnerável)
- Framework Leads Novos infra

**Implicação:** Caminho 1 cirúrgico não existe. Única opção = promoção RC1 → produção completa (era o Caminho 2).

---

## 🛑 Cutover PAUSADO — 5 riscos que exigem runbook

### 1. Volumes docker renomeados (PERDA DE DADOS potencial)

| Volume | Nome atual | Nome no compose novo |
|---|---|---|
| ChromaDB | `doctor-auto-ai_chroma_data` | `dap4_chroma` |
| Uploads | `doctor-auto-ai_uploads_data` | `dap4_uploads` |
| SecondBrain | (não existe) | `dap4_brain` (novo) |

Se subir sem ajuste, ChromaDB inicia volume vazio. **Perde vetorização atual.**

**Mitigação:** modificar compose novo com `external: true, name: doctor-auto-ai_chroma_data` OU clonar volumes antes.

### 2. Cloudflare Tunnel — systemd vs container

- **Atual:** `cloudflared.service` systemd rodando desde 2026-04-11. Token capturado no handoff.
- **Compose novo:** container `cloudflared` com profile `prod` (só sobe com `--profile prod`).
- **Routing ingress** (subdomain → service) configurado no Cloudflare Zero Trust dashboard. Atualmente aponta `dap.doctorautoprime40.com` → **caddy container** (presumido) na porta interna.
- Compose novo espera routing tipo: `dap.X.com → dashboard:80`, `api.dap.X.com → gateway:3001`.

**Sem reconfigurar o ingress no dashboard Cloudflare, subir stack novo = 502 no público.**

### 3. Container `dashboard` novo (não existia)

Compose novo tem container `dashboard` (nginx servindo build estático + injetando `API_SECRET` via envsubst). Atualmente o frontend é servido via **caddy** com Caddyfile desconhecido (não está no git).

Sem dashboard container + sem caddy config, frontend não aparece.

### 4. `.env.production` vs `.env`

Compose novo usa `env_file: .env`. Atual usa `.env.production`. Nem `.env.production` nem `docker-compose.prod.yml` estão trackados no git — foram criados direto no VPS e **sumiram do disk** (containers continuam rodando de memória).

**Mitigação:** usar `.env.recovered` do backup como base + adicionar:
- `META_APP_SECRET=<pendente Meta setup>` ou placeholder fail-closed
- `CLOUDFLARE_TUNNEL_TOKEN=<token atual do systemd>`
- `PUBLIC_DOMAIN=dap.doctorautoprime40.com`

### 5. META_APP_SECRET ausente (CRITICAL acoplado)

Novo gateway tem startup assertion `PRODUCTION_REQUIRED_ENVS = ["API_SECRET", "META_APP_SECRET"]`. Sem a envvar, container crasha no startup (fail-closed intencional que EU implementei).

Opções:
- A) Placeholder `META_APP_SECRET=<any_non_empty>` (webhook Meta continua rejeitando 401, mas gateway sobe)
- B) Configurar Meta Business antes do cutover (~1h humano)

---

## 📋 Estado para a próxima sessão

### Local Windows (Thales workstation)

- `C:/dev/dap4` → worktree `feat/kommo-prod-rc1` @ `467d8cf` (branch pronto pra promoção)
- `C:/dev/dap4-whatsapp` → worktree `feat/whatsapp-kommo` @ `210e6e7` (branch antigo de prod)
- `C:/dev/dap4-anna-phase1a` → worktree `feat/anna-phase1a` (outro)

Local tem uncommitted dashboard/* changes em `C:/dev/dap4` — são parte do trabalho já commitado nas branches pushadas, podem ser stashed/discarded depois.

### VPS (76.13.170.42)

- Branch: `feat/whatsapp-kommo` @ `210e6e7` (restaurado, clean)
- Stashes guardados: `stash@{0}` (WIP uncommitted pre-parliament-deploy) — **NÃO DROPAR**, tem mudanças direto do VPS em sofia.py, main.py, deps.py, chat.py, supabase_client.py, docker-compose.yml
- Containers rodando há 3 dias (healthy): `python-agents` · `gateway` · `caddy` · `chromadb` (+ dashboard-evolution separado)
- Compose file atual (`docker-compose.prod.yml`) deletado do disk, containers vivem de memória
- Backup completo em `/root/backup-cutover-2026-04-22-0057/`
- Cloudflared systemd rodando com token capturado (no handoff)

### Supabase DB (DAP4.0 `cpzgtfblywexqglqkgbt`)

- Schema Parliament aplicado (6 tabelas + triggers + seeds completos)
- `parliament_subagents.ana.active = FALSE` (kill-switch no DB)
- Schema cache PostgREST já refreshed (NOTIFY pgrst enviado)

### Produção frontend

- `https://dap.doctorautoprime40.com` → 200 OK, versão antiga
- Sem leads entrando (Ana parada há dias)

---

## 🎯 Próximo passo exato — RUNBOOK CUTOVER

Próxima sessão com Thales presente (30-60 min janela). Thales precisa ter ao lado:
- Acesso ao Cloudflare Zero Trust dashboard (https://one.dash.cloudflare.com/)
- `.env.recovered` lido previamente (pode copiar de `/root/backup-cutover-2026-04-22-0057/`)
- Terminal SSH aberto no VPS

Claude faz:

### Fase 1 — Preparação (~10 min, ZERO downtime)

1. Montar `.env` novo juntando `.env.recovered` + novas vars (`META_APP_SECRET` placeholder, `CLOUDFLARE_TUNNEL_TOKEN`, `PUBLIC_DOMAIN`)
2. Editar `docker-compose.yml` do VPS pra:
   - Marcar volumes como `external: true, name: doctor-auto-ai_<antigo>` — preserva dados
   - Desativar container `cloudflared` (já roda em systemd) — comentar ou via profile
   - Manter ou remover dashboard container dependendo de como caddy serve frontend hoje
3. Inspecionar Caddyfile atual (`docker exec doctor-auto-ai-caddy-1 cat /etc/caddy/Caddyfile`) — decidir se mantém caddy ou migra pra nginx-dashboard
4. `docker build` das imagens novas (agents, gateway) SEM subir containers ainda

### Fase 2 — Cutover (~5-15 min, DOWNTIME pequeno)

5. Snapshot final: `docker ps > /root/pre-cutover.txt`; tag atual `docker tag <current-image> <image>:rollback`
6. `docker compose down` (stack antigo)
7. `docker compose up -d` (stack novo, services que são mantidos)
8. Smoke test em portas internas antes de aceitar tráfego externo

### Fase 3 — Validação (~10 min)

9. `curl https://dap.doctorautoprime40.com` → 200 + bundle novo (title "DAP 4.0 · Command Center" não "Doctor AI")
10. `curl https://dap.doctorautoprime40.com/api/parliament/directors` → **200 com 13 diretores** (objetivo principal)
11. Chat /api/chat/message (Ana paused, deve 503 com mensagem clara)
12. Pulse, Parliament UI, Cérebro, Vault acessíveis
13. Thales confirma via browser

### Fase 4 — Rollback condicional (se algo quebrar)

14. Se smoke test falhar: `docker compose down` + subir containers antigos via tags `:rollback` + restore volumes se necessário
15. Cloudflare ingress já estava apontando pro caddy — não mexer no dashboard Cloudflare até confirmação

### Pós-cutover — decisões destravadas

- Thales revisa `anna-guardrails.md` (3 pontos)
- Thales toggle `parliament_subagents.ana.active = TRUE` via UI /parliament
- Meta WhatsApp setup em janela separada
- Migration #31 `crm_leads` lead_score (Framework Leads)

---

## 🔑 Credenciais capturadas (rotar em breve, ficaram no chat)

- **Cloudflare Tunnel token** (systemd cloudflared): `eyJhIjoiNmRmNjg0MmM1NDdjOGIzZjQyMGUxNDc4OWY1MDA1MDEiLCJ0IjoiZGYwODJiMGQtYWEwYi00ZGQ4LTgyNzQtYzVmMmVkNjFlNTYxIiwicyI6Ill6RTFOalppT0RNdE1tRTFNUzAwTldFM0xUbGtNRGt0Wm1Jd1pUa3lNVFJrTnpjdyJ9`
- 18 envvars DAP-specific em `/root/backup-cutover-2026-04-22-0057/.env.recovered`

---

## 📋 Tasks abertas pós-cutover

### Humano (Thales)
- [ ] Aprovar `anna-guardrails.md` com decisões 2.1 + 7.8 + Kommo Prime pipeline_id
- [ ] Configurar Meta WhatsApp Business (#23)
- [ ] Pipeline_id Prime #21
- [ ] Decisão cron Davi Gatuno (matar ou manter?)
- [ ] Revisar stashes no VPS (`stash@{0}`: mudanças direto no VPS em sofia.py/main.py etc.) — decidir se incorporar ou descartar

### Backend (próxima sessão)
- [ ] **Runbook cutover RC1→prod** (acima, ~30 min janela)
- [ ] #31 — migration `20260423_crm_leads_scoring.sql` (colunas framework leads)
- [ ] #26 — Ana persistir `classification` + `lead_score` em `crm_leads`
- [ ] Task 15 do Parliament plan (smoke test VPS pós-cutover — parte dele já coberto pelo runbook)

### Polish
- [ ] Fix Marta/Anna/Chapapiuro role collision em `parliament_directors` (dois CSOs) — observação do agent Parliament migration
- [ ] Orphan skill `firecrawl` sem junction — decide se assign ou drop

---

## 📝 Arquivos criados/modificados nesta sessão

### Local Windows
```
(commits em feat/kommo-prod-rc1 — ver lista acima)
```

### Vault PITOS
```
PITOS/DAP 4.0/Frameworks Operacionais/
├── DAP_Framework_Leads_Novos.pdf
├── framework-leads-novos.md
└── anna-guardrails.md                          (novo — 453 linhas, draft)

PITOS/Inbox - Claudin/
└── handoff-2026-04-22-2330-dap4-parliament-rc1-cutover-pausado.md   (este)
```

### VPS
```
/root/backup-cutover-2026-04-22-0057/
├── .env.recovered
├── doctor-auto-ai-python-agents-1.inspect.json
├── doctor-auto-ai-gateway-1.inspect.json
├── doctor-auto-ai-caddy-1.inspect.json
├── doctor-auto-ai-chromadb-1.inspect.json
└── env.*.txt (individual env dumps)
```

### Supabase
```
Migrations aplicadas:
- parliament_clevel_01_schema
- parliament_clevel_02_directors

Via execute_sql (inline inserts, não gravadas como migrations):
- subagents seed (3 rows)
- crons seed (3 rows)
- skills seed (56 rows, 3 batches)
- director_skills junction seed (64 rows, 2 batches)
```

---

## 🧠 Memórias Claude salvas

- `project_parliament_backend.md` (criada 19/04, vigente)
- `project_manus_analise_kommo.md` (criada 19/04)
- `project_framework_leads_novos.md` (criada 19/04)

**Não criei memória nova da sessão 22/04** — essa info vive aqui no handoff.

---

## 🔗 Referências

- Spec Parliament: `C:/dev/dap4/docs/superpowers/specs/2026-04-19-parliament-clevel-backend-design.md`
- Plan Parliament: `C:/dev/dap4/docs/superpowers/plans/2026-04-19-parliament-clevel-backend.md`
- Handoff anterior: `PITOS/Inbox - Claudin/handoff-2026-04-19-2200-dap4-sennin-consolidacao.md`
- Master-todo: `PITOS/DAP 4.0/Notas/001-dap40-master-todo.md` (tasks #28-33 incluem trabalho desta sessão)
- Análise Manus Kommo: `PITOS/Business Intelligence/Kommo Analysis 2026-03/`

---

**Retomada:** `/resume-handoff` (carrega este doc automaticamente).

**Primeira ação da próxima sessão:** Thales confirma janela de 30-60min + acesso ao Cloudflare dashboard, então Claude inicia Fase 1 do runbook acima.
