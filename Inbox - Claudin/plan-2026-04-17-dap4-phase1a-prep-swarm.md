# DAP4.0 Phase 1a Prep Swarm — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Converter os 24 arquivos dirty em `feat/kommo-hub-phase1a` em 6 commits semânticos, depois rodar 4 subagents paralelos pra preparar merge + deploy da próxima sessão, sem tocar em prod.

**Architecture:** 3 fases sequenciais. Fase 0 e 1 são operações git locais (sem subagent). Fase 2 spawna 4 `general-purpose` agents em paralelo via single-message multi-tool-call.

**Tech Stack:** Git (Windows, bash shell), repositório `C:\dev\dap4`, vault Obsidian em OneDrive, Task tool pra spawn paralelo.

---

## Scope & Boundaries (lock-in from spec)

- **Sem `git push`.** Tudo local.
- **Sem SSH VPS.** Zero toque em `76.13.170.42`.
- **Sem migrations aplicadas.** Supabase intocado.
- **Sem merge real.** Agent 1 produz relatório, não executa.
- Outputs de subagents vão pra `Inbox - Claudin\*.md` no vault.
- RTBM drafts ficam uncommitted no repo.

## File Structure

| Path | Ação | Responsabilidade |
|------|------|------------------|
| `C:\dev\dap4\.gitignore` | Modify | Adicionar `.superpowers/` |
| `C:\dev\dap4\ops\GO_LIVE_RUNBOOK.md` | Modify | Corrigir path + Caddy + sudo note |
| `C:\dev\dap4\agents\config\rtbm\dap_prime.md` | Create (Agent 3) | RTBM DAP Prime draft |
| `C:\dev\dap4\agents\config\rtbm\bosch.md` | Create (Agent 3) | RTBM Bosch draft |
| `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\analise-branches-whatsapp-vs-kommohub.md` | Create (Agent 1) | Relatório de conflitos |
| `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\kommo-tokens-handbook.md` | Create (Agent 2) | Handbook 6 envs + backup |
| `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\audit-tech-debt-backlog.md` | Create (Agent 4) | 10 tasks priorizadas |

---

## Fase 0 — Pré-commit prep

### Task 1: Verificar estado inicial do repo

- [ ] **Step 1: Confirmar working dir + branch**

```bash
cd C:\dev\dap4
git branch --show-current
git log --oneline -1
git status --short | head -40
```

Expected: branch `feat/kommo-hub-phase1a` @ `d235c60`, ~24 modificados + 3 new + 3 deleted.

Se branch diferente, parar e reportar — NÃO prosseguir.

### Task 2: Adicionar `.superpowers/` ao `.gitignore`

**Files:**
- Modify: `C:\dev\dap4\.gitignore`

- [ ] **Step 1: Ler `.gitignore` atual** (via Read tool)

- [ ] **Step 2: Verificar se `.superpowers` já está listado**

Se sim, pular Task 2.

- [ ] **Step 3: Adicionar entrada**

Edit append (ou na seção apropriada existente):
```
.superpowers/
```

- [ ] **Step 4: Validar via `git status`**

```bash
git status --short | grep -E '\.superpowers|\.gitignore'
```

Expected: `.superpowers/` não aparece mais como untracked; `.gitignore` aparece como M.

### Task 3: Atualizar runbook pro path real de prod

**Files:**
- Modify: `C:\dev\dap4\ops\GO_LIVE_RUNBOOK.md`

- [ ] **Step 1: Ler seções Fases 9–12 do runbook** (via Read tool, buscar "Phase 9" até fim ou "Phase 12")

- [ ] **Step 2: Fazer 3 edits via Edit tool**

Edit A — substituir referências a `~/dap4/` por `/opt/doctor-auto-ai/` onde referem path de deploy (manter `~/dap4/` se for contexto do user `dap4` dev checkout).

Edit B — adicionar nota após primeira menção de deploy path (em Fase 9):
```markdown
> **Nota infra real (abr 2026):** Stack rodando em `/opt/doctor-auto-ai/` (owner root). Reverse proxy é Caddy (`doctor-auto-ai-caddy-1`), não Cloudflare Tunnel direto pro gateway.
```

Edit C — adicionar nota operacional:
```markdown
> **SSH:** user `dap4` não tem sudo NOPASSWD. Para operações em `/opt/doctor-auto-ai/` usar `ssh root@76.13.170.42 -i ~/.ssh/id_ed25519`.
```

- [ ] **Step 3: Validar**

```bash
git diff --stat ops/GO_LIVE_RUNBOOK.md
```

Expected: runbook aparece modificado com delta pequeno (3 edits).

---

## Fase 1 — 6 Commits semânticos

**Regra geral:** após cada commit, rodar `git show --stat HEAD` pra validar agrupamento. Se falhar (hook reject, teste), parar; `git reset --soft HEAD~1` volta o último.

### Task 4: Commit #1 — fix(security)

**Files to stage:**
- `agents/api/routes/kommo_chat.py`
- `agents/services/rtbm_loader.py`
- `agents/parliament/tenant.py`

- [ ] **Step 1: Stage**

```bash
git add agents/api/routes/kommo_chat.py agents/services/rtbm_loader.py agents/parliament/tenant.py
git status --short
```

Expected: 3 files em staging (M), nada mais staged.

- [ ] **Step 2: Commit**

```bash
git commit -m "fix(security): constrain KommoChatRequest + block path traversal in rtbm/tenant loaders

- Pydantic regex ^[a-z0-9_]{1,64}\$ + max_length 4096 on KommoChatRequest
- path.resolve() guard + brand regex in rtbm_loader and parliament/tenant
- InvalidBrandError raised on malformed input

Audit fixes #1, #3, #13"
```

- [ ] **Step 3: Validar**

```bash
git show --stat HEAD
```

Expected: 3 files, ~50 lines changed total. `git status` clean para esses 3 files.

### Task 5: Commit #2 — fix(multitenant)

**Files to stage:**
- `agents/agents/ana.py`
- `gateway/src/routes/kommo-webhook.routes.ts`
- `gateway/tests/kommo-webhook.test.ts`

- [ ] **Step 1: Stage**

```bash
git add agents/agents/ana.py gateway/src/routes/kommo-webhook.routes.ts gateway/tests/kommo-webhook.test.ts
git status --short
```

Expected: 3 files em staging.

- [ ] **Step 2: Commit**

```bash
git commit -m "fix(multitenant): remove Ana singleton mutation + use pipelineFor in webhook

- Ana accepts system_prompt_override parameter (no global mutation)
- Kommo webhook resolves pipeline via pipelineFor(payload, channelStore)
- kommo_brand_resolve_fallback_total metric on brand resolution miss

Audit fix #2"
```

- [ ] **Step 3: Validar**

```bash
git show --stat HEAD
```

### Task 6: Commit #3 — fix(db)

**Files to stage:**
- `supabase/migrations/20260416_01_anna_kommo_schema.sql`
- `supabase/migrations/20260416_02_kommo_tables_extend.sql`
- `supabase/migrations/20260416_03_fix_pipeline_seeds.sql`
- `gateway/migrations/20260416_01_anna_tables.sql` (deleted)
- `gateway/migrations/20260416_02_kommo_tables_extend.sql` (deleted)
- `gateway/migrations/20260416_03_fix_pipeline_seeds.sql` (deleted)
- `gateway/tests/migrations.test.ts`

- [ ] **Step 1: Stage (inclui deletes)**

```bash
git add supabase/migrations/20260416_01_anna_kommo_schema.sql supabase/migrations/20260416_02_kommo_tables_extend.sql supabase/migrations/20260416_03_fix_pipeline_seeds.sql gateway/tests/migrations.test.ts
git add -u gateway/migrations/
git status --short
```

Expected: 3 M (supabase), 1 M (test), 3 D (gateway/migrations mirrors).

- [ ] **Step 2: Commit**

```bash
git commit -m "fix(db): RLS NULL guards + transactional migrations + idempotent seed

- Wrap migrations 01/02/03 in BEGIN/COMMIT
- RLS policies require current_setting('app.current_tenant', true) IS NOT NULL AND <> ''
- Migration 03 becomes unconditional UPDATE (idempotent, re-run safe)
- Delete gateway/migrations/ mirrors (drift-prone); canonical path is supabase/migrations/
- Tests: BEGIN/COMMIT guard + 5 NOT NULL guards

Audit fixes #5, #6, #7"
```

- [ ] **Step 3: Validar**

```bash
git show --stat HEAD
```

Expected: 7 files (3M supabase + 1M test + 3D gateway/migrations).

### Task 7: Commit #4 — fix(silent)

**Files to stage:**
- `gateway/src/services/anna-result-handler.ts`
- `gateway/src/workers/anna-inbox.adapters.ts`
- `gateway/src/workers/anna-inbox.worker.ts`
- `gateway/tests/anna-inbox-worker.test.ts`
- `gateway/tests/anna-result-handler.test.ts`
- `agents/parliament/archiver.py`
- `agents/parliament/session_manager.py`

- [ ] **Step 1: Stage**

```bash
git add gateway/src/services/anna-result-handler.ts gateway/src/workers/anna-inbox.adapters.ts gateway/src/workers/anna-inbox.worker.ts gateway/tests/anna-inbox-worker.test.ts gateway/tests/anna-result-handler.test.ts agents/parliament/archiver.py agents/parliament/session_manager.py
git status --short
```

Expected: 7 files staged.

- [ ] **Step 2: Commit**

```bash
git commit -m "fix(silent): propagate delivery failure + archiver errors + Zod Anna response

- handleAnnaResult returns {replyDelivered: boolean}
- Worker markDone only on success, markFailed+requeue otherwise
- recordAssistantTurn skipped if delivery failed (no history pollution)
- anna-inbox.adapters uses Zod safeParse on Anna HTTP response
- parliament/archiver: check .error on each execute() + ArchiveError propagation
- parliament/session_manager: asyncio.to_thread for archive (non-blocking) + RuntimeError replaces assert + empty quorum guard

Audit fixes #8, #12, #14"
```

- [ ] **Step 3: Validar**

```bash
git show --stat HEAD
```

### Task 8: Commit #5 — fix(ops)

**Files to stage:**
- `gateway/src/index.ts`
- `supabase/migrations/20260417_01_anna_claim_rpc.sql` (new)
- `gateway/scripts/smoke-kommo-gate.ts`
- `agents/.dockerignore` (new)
- `.gitignore` (modified in Task 2)

- [ ] **Step 1: Stage**

```bash
git add gateway/src/index.ts supabase/migrations/20260417_01_anna_claim_rpc.sql gateway/scripts/smoke-kommo-gate.ts agents/.dockerignore .gitignore
git status --short
```

Expected: 5 files staged (3 M + 2 new).

- [ ] **Step 2: Commit**

```bash
git commit -m "fix(ops): wire handoff-TTL + atomic claim RPC + dockerignore playground

- startHandoffTtlWorker wired in gateway/src/index.ts, gated by USE_KOMMO_HUB + KOMMO_THALES_USER_ID/CHAT_ID
- New migration: rpc_anna_inbox_claim_next() SECURITY DEFINER + FOR UPDATE SKIP LOCKED
- createInboxQueue now uses supabase.rpc() for atomic claim
- agents/.dockerignore excludes scripts/playground* + serve-playground.py (prevents API key leak to image)
- smoke-kommo-gate.ts seeds ChannelStore for multi-tenant smoke
- .gitignore: add .superpowers/ (local skill cache)

Audit fixes #4, #9, #10, #11, #15"
```

- [ ] **Step 3: Validar**

```bash
git show --stat HEAD
```

### Task 9: Commit #6 — docs(runbook)

**Files to stage:**
- `ops/GO_LIVE_RUNBOOK.md`

- [ ] **Step 1: Stage**

```bash
git add ops/GO_LIVE_RUNBOOK.md
git status --short
```

Expected: 1 file staged.

- [ ] **Step 2: Commit**

```bash
git commit -m "docs(runbook): Phases 9-12 Kommo Hub Phase 1a + correct deploy paths

- Add Phases 9 (migrations), 10 (Kommo env vars), 11 (register Chats v2 channel), 12 (smoke multi-tenant Bosch+Prime)
- Document rollback via USE_KOMMO_HUB=false
- Metrics to watch (replay_blocked, brand_resolve_fallback)
- Tech debt declared (addTag additive, media handling, timestamp validation)
- Correct paths: stack runs in /opt/doctor-auto-ai/ (Caddy reverse proxy)
- SSH op note: user dap4 has no sudo NOPASSWD"
```

- [ ] **Step 3: Validar estado final**

```bash
git log --oneline -7
git status --short
```

Expected:
- 6 novos commits no topo acima de `d235c60`
- `git status` mostra apenas `dashboard-git` dirty (pré-existente)

---

## Fase 2 — Subagents paralelos

**Crítico:** os 4 agents são spawnados em UMA ÚNICA mensagem com 4 chamadas Agent tool em paralelo. Working tree deve estar limpo (Fase 1 completa) antes.

### Task 10: Spawn paralelo dos 4 subagents

- [ ] **Step 1: Validar pré-condição**

```bash
cd C:\dev\dap4
git status --short
git log --oneline -1
```

Expected: working tree clean (só dashboard-git dirty) + HEAD em commit #6 (docs(runbook)).

Se não, parar — Fase 1 incompleta.

- [ ] **Step 2: Spawn 4 Agent tool calls em uma mensagem**

**Agent 1 — Branch Divergence Analyst** (`general-purpose`):
```
Tu é um git forensics engineer. Teu trabalho é mapear com precisão a divergência entre duas branches do repo C:\dev\dap4 e produzir um relatório que Thales possa usar pra decidir merge strategy.

Setup:
- cd C:\dev\dap4
- git fetch origin (precisa de rede)
- branches de interesse: origin/feat/whatsapp-kommo (prod atual) vs feat/kommo-hub-phase1a (local, recém-commitado)

Tasks:
1. git log --oneline origin/feat/whatsapp-kommo..feat/kommo-hub-phase1a → commits que kommo-hub tem e whatsapp não
2. git log --oneline feat/kommo-hub-phase1a..origin/feat/whatsapp-kommo → inverso
3. Identificar arquivos tocados por ambas: intersect das listas de `git diff --name-only origin/feat/whatsapp-kommo main` e `git diff --name-only feat/kommo-hub-phase1a main` (ou melhor, merge-base)
4. Pra cada arquivo na intersecção, usar `git merge-tree origin/feat/whatsapp-kommo feat/kommo-hub-phase1a` pra checar conflitos reais (conflito marker <<<<<<< no output)
5. Classificar risco por arquivo: ALTO (merge-tree reporta conflito), MÉDIO (ambas modificam mesmo file sem conflito), BAIXO (files disjuntos)
6. Checar se Phase 1a audit fixes cobrem arquivos da whatsapp-kommo (ex: kommo-webhook.routes.ts aparece em ambas?)

Output: C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\analise-branches-whatsapp-vs-kommohub.md

Frontmatter:
---
type: analysis
date: 2026-04-17
project: DAP4.0
topic: Branch divergence feat/whatsapp-kommo ↔ feat/kommo-hub-phase1a
tags: [analysis, merge-strategy, dap4, kommo]
---

Seções obrigatórias:
1. Resumo executivo (3 bullets: risco geral, n° de arquivos conflitantes, recomendação)
2. Commits exclusivos por branch (2 listas oneline)
3. Matriz de arquivos (tabela: arquivo | whatsapp-kommo toca | kommo-hub toca | risco)
4. Conflitos reais detectados (merge-tree output parcial se houver)
5. Ordem recomendada de resolução (mais isolado primeiro)
6. Tests que provavelmente quebram no merge
7. Flag crítica: fixes do audit cobrem whatsapp-kommo? (ex: se whatsapp-kommo tem sua própria versão de kommo-webhook.routes.ts, os fixes #2 precisam re-aplicar)

Não executa merge. Não modifica branches. Só lê e reporta.
```

**Agent 2 — Kommo Tokens Handbook** (`general-purpose`):
```
Tu é um technical writer + operations engineer. Teu trabalho é produzir um handbook passo-a-passo pro Thales gerar as 6 envs Kommo + fazer backup Supabase antes do deploy Phase 1a.

Setup:
- cd C:\dev\dap4
- Ler: ops/GO_LIVE_RUNBOOK.md (Fase 10 tem referência); agents/config/tenants/dap.yaml; qualquer .env.example
- Grep por KOMMO_ em gateway/src/ e agents/ pra mapear onde cada var é lida

Tasks:
1. Mapear 6 vars: KOMMO_TOKEN, KOMMO_DOMAIN, KOMMO_CHATS_CHANNEL_SECRET, KOMMO_INTEGRATION_SECRET, KOMMO_THALES_USER_ID, KOMMO_THALES_CHAT_ID
2. Pra cada: (a) o que é conceitualmente, (b) onde no portal Kommo (path de menus/settings), (c) formato esperado (ex: UUID, hex 64 char, account slug), (d) impacto se errado/ausente (gateway crashea? silently ignora? features off?)
3. Backup Supabase: projeto ID `acuufrgoyjwzlyhopaus` tem 5911 leads. Produzir comando CLI supabase pra point-in-time backup (ou pg_dump via URL direta — escolher o mais seguro/rápido)
4. Checklist pré-deploy estilo pré-voo (marcar tudo antes de aplicar migrations em prod)

Output: C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\kommo-tokens-handbook.md

Frontmatter:
---
type: handbook
date: 2026-04-17
project: DAP4.0
topic: Kommo tokens + Supabase backup pré-deploy Phase 1a
tags: [handbook, deploy, kommo, supabase, dap4]
---

Seções:
1. 6 envs Kommo — uma por heading, em ordem de criação no portal
2. Backup Supabase point-in-time — comando completo
3. Checklist pré-voo (markdown checkboxes, 10-15 itens)
4. Troubleshooting rápido (o que fazer se cada env der erro no boot)
```

**Agent 3 — RTBM Drafter** (`general-purpose`):
```
Tu é um brand voice + technical writer. Teu trabalho é produzir primeiros drafts de RTBM docs pra DAP Prime e Bosch, extraindo conteúdo do que já existe no vault do Thales + codebase, sem inventar.

Setup (leitura recursiva):
- C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\*.md (especialmente 001-master-todo, 002-rota-estrategica, 003-dores-legado)
- C:\dev\dap4\CLAUDE.md (ecossistema 12 unidades)
- C:\dev\dap4\agents\agents\ana.py (system prompt da Ana)
- C:\dev\dap4\agents\config\tenants\dap.yaml (tenant config)

Outputs (NEW files, NÃO commitar):
1. C:\dev\dap4\agents\config\rtbm\dap_prime.md
2. C:\dev\dap4\agents\config\rtbm\bosch.md

Cada arquivo segue ESTA estrutura exata:

# RTBM — [DAP Prime | Bosch]

## Persona
Quem é o atendente virtual desta marca. Tom de voz, estilo. 2-4 parágrafos.

## Produtos e serviços
Lista do que essa unidade vende/oferece. Bullets.

## Casos comuns de entrada
Leads chegando — tipos de pergunta/intenção. Bullets com exemplos literais ("Quanto custa um remap Stage 1?").

## Exemplos de resposta
Pares Q&A (5-8 pares) mostrando o tom certo.

## FAQ técnica
Perguntas que exigem conhecimento técnico específico — e a resposta curta.

## Handoff rules
Quando escalar pro Thales (humano). Bullets com condições objetivas (ex: "Orçamento acima de R$10k", "Cliente insistindo em desconto > 15%").

REGRAS:
- Onde encontrar material sólido no vault/repo, escrever o conteúdo real
- Onde NÃO encontrar, escrever: `<!-- TODO: Thales preencher com <descrição específica do que falta> -->`
- Nunca inventar dados técnicos (preços, prazos, stages específicos)
- DAP Prime: manutenção premium alemães (BMW/Audi/Mercedes/VW); Bosch: autorizada Bosch com mais abrangência
- Tom DAP Prime: editorial, sofisticado, "Lobo Estrategista" diluído; Bosch: técnico, direto, confiável

Depois de criar os 2 files, NÃO commitar. Reportar: caminhos criados + estatística de preenchimento (ex: "DAP Prime: 70% preenchido, 3 TODOs"; "Bosch: 50% preenchido, 7 TODOs").
```

**Agent 4 — Audit Backlog Curator** (`general-purpose`):
```
Tu é um engineering manager. Teu trabalho é pegar 10 tech debts do audit Phase 1a (tasks HIGH/MEDIUM não-bloqueadores) e organizar num backlog priorizado pra Thales decidir sprints futuras.

Input (10 tasks do handoff 2026-04-17-2035):
1. Webhook timestamp validation (H1 audit) — replay cache mitiga parcial, timestamp header full
2. notify() em vez de logger.info — disparar pg_notify real via Supabase Realtime (dap-reviewer H2)
3. addTag em kommo.service.ts é replace, não additive — perde tags pré-existentes (dap-reviewer H6)
4. Anna ignora mídia (foto/áudio/PDF) — markDone silencioso (dap-reviewer H4)
5. asInt aceita string com '-' no início (lead_id negativo passa) — dap-reviewer MED
6. typingDelayMs fixo em ms/char ignora cultura BR mensagens curtas
7. /metrics exposição via API_SECRET — sem IP allowlist pro Prometheus
8. RTBM loader sync ChromaDB bloqueia event loop (python-reviewer MED) — asyncio.to_thread em _retrieve_context
9. record_decision.supabase=None untyped — Optional[SupabaseClient]
10. Rate limit middleware in-memory unbounded (python-reviewer HIGH — migrar pra Redis em produção sustentada)
11. dap.yaml tenant config com métricas business plaintext (current_revenue, capacity) — LOW mas considerar env-injected

Tasks:
1. Pra cada, estimar: severidade (HIGH/MED/LOW), esforço (h), depende de (outra task?), categoria (observabilidade/resiliência/qualidade/segurança)
2. Agrupar em Sprint A, B, C sugeridas (3-4 tasks por sprint, max 1 semana cada)
3. Recomendar ordem de ataque com racional (ROI, bloqueios downstream, risco crescente)

Output: C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\audit-tech-debt-backlog.md

Frontmatter:
---
type: backlog
date: 2026-04-17
project: DAP4.0
topic: Tech debt pós-deploy Phase 1a Kommo Hub
tags: [backlog, tech-debt, dap4, sprints]
---

Seções:
1. Tabela mestre (task | sev | esforço h | categoria | depende de)
2. Sprint A — [nome temático] (tasks + racional)
3. Sprint B — [nome]
4. Sprint C — [nome]
5. Ordem recomendada (ranked list com 1-2 linhas de racional cada)
```

- [ ] **Step 3: Coletar resultados**

Esperar completion dos 4. Cada um retorna resumo + caminho do MD produzido.

- [ ] **Step 4: Validar entregáveis**

```bash
ls "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\" | grep -E "analise-branches|kommo-tokens-handbook|audit-tech-debt"
ls C:\dev\dap4\agents\config\rtbm\
```

Expected: 3 MDs novos no Inbox + 2 novos em rtbm/.

```bash
cd C:\dev\dap4
git status --short
```

Expected: 2 novos files untracked (`agents/config/rtbm/dap_prime.md`, `agents/config/rtbm/bosch.md`) + `dashboard-git` dirty (pré-existente). Nada mais.

---

## Task 11: Resumo final pro Thales

- [ ] **Step 1: Montar resumo ≤ 200 palavras**

Template:
```
## Swarm Phase 1a prep — completo

**Commits (branch feat/kommo-hub-phase1a):**
- 6 commits semânticos acima de d235c60
- Working tree limpo (exceto RTBM drafts + dashboard-git)

**Outputs no vault (Inbox - Claudin):**
- analise-branches-whatsapp-vs-kommohub.md — [recomendação headline]
- kommo-tokens-handbook.md — checklist pré-voo [N itens]
- audit-tech-debt-backlog.md — [N sprints sugeridas]

**Drafts uncommitted em dap4/agents/config/rtbm/:**
- dap_prime.md (X% preenchido, N TODOs)
- bosch.md (Y% preenchido, M TODOs)

**Próximo passo sugerido (sessão dedicada):**
1. Revisar analise-branches → decidir Opção B (merge) vs C (coexistir)
2. Gerar tokens Kommo + backup Supabase conforme handbook
3. Completar RTBM drafts offline
4. Criar feat/kommo-prod-rc1, mergear whatsapp-kommo, resolver conflitos
5. Deploy Fases 9-12 do runbook (path /opt/doctor-auto-ai/)
```

- [ ] **Step 2: Entregar ao Thales**

Inline na sessão, com os caminhos absolutos dos MDs pra ele abrir no Obsidian.

---

## Rollback / Erro handling

| Falha em... | Ação |
|-------------|------|
| Task 1 (branch errada) | Parar imediatamente, reportar branch atual vs esperada |
| Task 2/3 (edit runbook/gitignore) | `git checkout -- <arquivo>` reverte, reportar, abortar Fase 1 |
| Task 4-9 (commit) | `git reset --soft HEAD~1` volta o último (files voltam pra staging), investigar causa, NÃO prosseguir pro próximo commit sem resolver |
| Task 10 subagent N failed | Outros 3 seguem, reportar no resumo final qual output ficou ausente |
| Task 11 | N/A, é só report |

Nenhuma falha aqui toca prod ou cria situação não-reversível. Tudo é `feat/kommo-hub-phase1a` local.
