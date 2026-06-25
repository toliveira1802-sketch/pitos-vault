---
type: spec
date: 2026-04-17
project: DAP4.0
topic: Phase 1a prep swarm — commits semânticos + análise paralela (sem deploy)
tags: [spec, superpowers, dap4, phase1a, kommo, swarm, brainstorm]
status: approved-by-thales
---

# Spec — Swarm de preparação Phase 1a Kommo Hub

## Contexto

Sessão anterior (handoff `2026-04-17-2035`) fechou os 15 blockers do audit em `feat/kommo-hub-phase1a` com 103/103 vitest + 47/47 pytest + tsc clean. Deploy pra VPS descobriu divergência: prod está em `feat/whatsapp-kommo @ 210e6e7` com CRM sync/classify live, não em `feat/kommo-hub-phase1a`. Merge é obrigatório antes de deploy.

Thales decidiu: **não atacar o merge + deploy nesta sessão**. Maximizar trabalho paralelo independente do merge pra deixar a sessão de deploy focada (tu no volante, baixo risco).

## Objetivo

Preparar tudo que pode ser feito sem tocar na divergência real e sem deploy: commits limpos, análise de conflitos, handbook de tokens, drafts de RTBM, backlog curado de tech debt pós-deploy.

## Escopo — o que o swarm faz

### Fase 0 — Pré-commit (sequencial, sem subagent)

1. Adicionar `.superpowers/` ao `.gitignore` do repo `C:\dev\dap4`.
2. Editar `ops/GO_LIVE_RUNBOOK.md` (Fases 9–12):
   - Substituir `~/dap4/` por `/opt/doctor-auto-ai/` onde aplica
   - Adicionar nota: "stack usa Caddy como reverse proxy — `doctor-auto-ai-caddy-1`; não Cloudflare Tunnel direto pro gateway"
   - Adicionar: "user `dap4` não tem sudo NOPASSWD — usar `ssh root@76.13.170.42 -i ~/.ssh/id_ed25519` pra operações em `/opt/doctor-auto-ai/`"
3. Confirmar `git status` — esperar ~25 modificados + 4 new (`.dockerignore`, migration `20260417_01`, `.gitignore` update) + 3 deleted mirrors

### Fase 1 — Commits semânticos (sequencial, sem subagent)

Seis commits em `feat/kommo-hub-phase1a`, cada um com `git add <files> && git commit -m "<msg>"`. Após cada um: `git show --stat HEAD` pra validar agrupamento. Se qualquer commit falhar (hook reject, teste), pára tudo, reporta; `git reset --soft HEAD~N` reverte preservando working tree.

| # | Tipo | Arquivos | Mensagem |
|---|------|----------|----------|
| 1 | `fix(security)` | `agents/api/routes/kommo_chat.py`, `agents/services/rtbm_loader.py`, `agents/parliament/tenant.py` | constrain KommoChatRequest + block path traversal in rtbm/tenant loaders |
| 2 | `fix(multitenant)` | `agents/agents/ana.py`, `gateway/src/routes/kommo-webhook.routes.ts` | remove Ana singleton mutation + use pipelineFor in webhook |
| 3 | `fix(db)` | `supabase/migrations/20260416_01_*.sql`, `_02_*.sql`, `_03_*.sql`, `gateway/migrations/*` (deletes), `gateway/tests/migrations.test.ts` | RLS NULL guards + transactional migrations + idempotent seed |
| 4 | `fix(silent)` | `gateway/src/services/anna-result-handler.ts`, `gateway/src/workers/anna-inbox.adapters.ts`, `gateway/src/workers/anna-inbox.worker.ts`, `agents/parliament/archiver.py`, `agents/parliament/session_manager.py`, tests correspondentes | propagate delivery failure + archiver error checks + Zod Anna response |
| 5 | `fix(ops)` | `gateway/src/index.ts`, `supabase/migrations/20260417_01_anna_claim_rpc.sql`, `gateway/scripts/smoke-kommo-gate.ts`, `agents/.dockerignore`, `.gitignore` | wire handoff-TTL + atomic claim RPC + dockerignore playground + gitignore superpowers |
| 6 | `docs(runbook)` | `ops/GO_LIVE_RUNBOOK.md` | Phases 9–12 Kommo Hub + correct deploy paths + Caddy note |

Após commit #6: working tree limpo exceto `dashboard-git` submodule dirty (pré-existente, fora de scope). RTBM drafts só aparecem na Fase 2 (Agent 3) e ficam uncommitted de propósito.

### Fase 2 — Subagents paralelos (4 agents concurrent)

Todos `general-purpose`. Rodam simultâneos após Fase 1 (working tree estável). Cada output auto-contido — falha de um não aborta outros.

**Agent 1 — Branch Divergence Analyst**

- Task: `cd C:\dev\dap4`, `git fetch origin`, gerar 2 diff logs (`origin/feat/whatsapp-kommo..feat/kommo-hub-phase1a` e inverso), usar `git merge-tree` pra detectar conflitos reais, classificar risco por arquivo
- Risk tiers: **alto** (ambas branches mexem na mesma função/bloco), **médio** (mesma file áreas diferentes), **baixo** (files disjuntos)
- Output: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\analise-branches-whatsapp-vs-kommohub.md`
- Seções obrigatórias:
  - Commits exclusivos de cada branch (oneline)
  - Arquivos tocados por ambas (matriz)
  - Matriz de risco por arquivo
  - Recomendação de ordem dos conflitos a resolver (mais isolado primeiro)
  - Tests que provavelmente vão quebrar no merge
  - Flag: Phase 1a audit fixes cobrem ou não os arquivos da whatsapp-kommo

**Agent 2 — Kommo Tokens Handbook**

- Inputs: `ops/GO_LIVE_RUNBOOK.md` Fase 10, `agents/config/tenants/dap.yaml`, search por `KOMMO_` e `SUPABASE_` em `gateway/src/` e `agents/`
- Output: `Inbox - Claudin\kommo-tokens-handbook.md`
- Seções:
  - 6 envs Kommo: `KOMMO_TOKEN`, `KOMMO_DOMAIN`, `KOMMO_CHATS_CHANNEL_SECRET`, `KOMMO_INTEGRATION_SECRET`, `KOMMO_THALES_USER_ID`, `KOMMO_THALES_CHAT_ID` — cada uma com: o que é, onde gerar no portal Kommo (path de menus), formato esperado, impacto se errado/ausente
  - CLI Supabase pra backup point-in-time do proj `acuufrgoyjwzlyhopaus`, comando completo
  - Checklist pré-deploy estilo pré-voo

**Agent 3 — RTBM Drafter**

- Inputs recursivos:
  - `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\*.md`
  - `C:\dev\dap4\CLAUDE.md`
  - `C:\dev\dap4\agents\agents\ana.py` (system prompt)
  - `C:\dev\dap4\agents\config\tenants\dap.yaml`
- Outputs (NEW files, uncommitted):
  - `C:\dev\dap4\agents\config\rtbm\dap_prime.md`
  - `C:\dev\dap4\agents\config\rtbm\bosch.md`
- Estrutura de cada:
  1. Persona (quem é esse atendente, tom de voz)
  2. Produtos e serviços (o que a unidade faz)
  3. Casos comuns de entrada (leads chegando)
  4. Exemplos de resposta (Q&A em pares)
  5. FAQ técnica
  6. Handoff rules (quando escalar pro Thales)
- Regra: onde não encontrar material no vault/repo, escrever `<!-- TODO: Thales preencher com <prompt específico do que falta> -->`

**Agent 4 — Audit Backlog Curator**

- Input: as 10 tasks pós-deploy listadas no handoff (webhook timestamp, notify real, addTag additive, Anna mídia ignorada, rate limit Redis, asInt negativo, typingDelayMs BR, /metrics IP allowlist, rtbm loader asyncio, record_decision typing, dap.yaml env-inject)
- Output: `Inbox - Claudin\audit-tech-debt-backlog.md`
- Seções:
  - Tabela: task, severidade (HIGH/MED/LOW), esforço estimado (horas), depende de, categoria (observabilidade/resiliência/qualidade/segurança)
  - Agrupamento sugerido em Sprint A / B / C
  - Recomendação de ordem baseada em ROI (maior impacto, menor esforço primeiro)

## Não-escopo (boundaries duras)

- **Sem `git push`.** Commits ficam local em `feat/kommo-hub-phase1a`.
- **Sem deploy.** VPS 76.13.170.42 intocada. Zero SSH na Fase 2.
- **Sem migrations aplicadas.** Supabase prod/staging intocado.
- **Sem merge real.** Agent 1 só escreve relatório — não cria `feat/kommo-prod-rc1`, não mergeia.
- Vault PITOS é read-only pelo Agent 3. Outputs MD todos vão pra `Inbox - Claudin\`.
- `dashboard-git` submodule dirty fica como está (pré-existente, fora do scope desta sessão).

## Entregáveis finais

1. Branch `feat/kommo-hub-phase1a` com 6 commits novos em cima de `d235c60`. Working tree limpo exceto RTBM drafts novos.
2. `Inbox - Claudin\analise-branches-whatsapp-vs-kommohub.md`
3. `Inbox - Claudin\kommo-tokens-handbook.md`
4. `agents/config/rtbm/dap_prime.md` + `bosch.md` (uncommitted drafts, Thales revisa offline)
5. `Inbox - Claudin\audit-tech-debt-backlog.md`
6. Resumo final: o que foi feito + próximos passos do Thales (com foco no merge+deploy da próxima sessão)

## Erro & rollback

- **Pré-commit** falhar ao editar runbook: reverter arquivo via `git checkout -- ops/GO_LIVE_RUNBOOK.md`, reportar, abortar Fase 1.
- **Commit N** falhar (pre-commit hook, teste): parar, reportar qual commit falhou e por quê. `git reset --soft HEAD~N` preserva working tree pra debug.
- **Subagent N** falhar: os outros 3 seguem. Sessão reporta no final qual output ficou faltando.
- Nenhuma falha toca prod ou cria situação não-reversível.

## Validação final antes de reportar ao Thales

- [ ] `git log --oneline -7` mostra 6 novos commits no topo
- [ ] `git status` mostra só RTBM drafts (2 new files) + `dashboard-git` dirty
- [ ] Os 4 MDs de output existem em `Inbox - Claudin\`
- [ ] Resumo no final da sessão aponta próximo passo claro (merge strategy decision + deploy)
