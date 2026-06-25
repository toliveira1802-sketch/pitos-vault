---
type: handoff
date: 2026-06-05
time: 07:08
project: DAP4 / Anna
topic: Anna re-plataforma — Fatia 0 (persistência AIOS) MERGEADA + Fatia 1 (inline agentic) em PR
tags: [handoff, claudin, anna, dap4, dap-aios, fatia0, fatia1]
---

# Handoff — Anna Fatia 0 + Fatia 1

> Continua o handoff anterior `handoff-2026-06-05-0138-anna-omnichannel-fatia0.md`.
> NÃO há mais sessão paralela ativa (Thales confirmou). A WIP de ~24 arquivos no
> master local do dap4 é dele/legado — não tocar.

## Contexto

Re-plataforma da Anna (agente comercial WhatsApp) em `C:\THALES\DAP4.0\dap4` (P1).
Anna = boca única omnichannel (WA+IG+FB via Meta), Kommo morrendo, persistência no
portal AIOS (Supabase `hlhfqnhsvwxodtwdkkhf`). Zoraide e campanha = agentes de bastidor
que acionam a Anna (fatias futuras). Esta sessão entregou DUAS fatias inteiras:
Fatia 0 (persistência) e Fatia 1 (Anna agentic com qualify tool).

## O que funcionou (com evidência)

- **Fatia 0 — persistência AIOS — MERGEADA** — evidência: PR #28 squash-merged em
  `origin/master` (08:27 UTC), CI verde (backend+gateway+frontend SUCCESS), 179 testes.
  `AiosStore` (resolveContact/upsertConversation/appendMessage) + dual-write no
  meta-webhook.routes.ts.
- **Smoke ao vivo da Fatia 0** — evidência: teste one-off (deletado) exercitou o AiosStore
  real contra o AIOS com a service_role key — env+auth+escrita+idempotência (unique parcial
  bloqueou dup wamid → 1 msg). Cleanup confirmado (leak=0).
- **Validação MCP de shapes** — evidência: BEGIN/ROLLBACK inseriu lead+conversa+mensagem
  com as colunas exatas do AiosStore, aceitas pelo schema vivo, commit nada.
- **Fatia 1 — Anna inline agentic — PR #29** — evidência: 10 commits em
  `feat/anna-fatia1-agentic` (off origin/master), **agents 185 + gateway 181 verdes, tsc
  limpo**. compute_lead_score (função pura, 13 testes) + chat_with_tools (OpenAI+Anthropic)
  + tool qualificar_lead + loop _handle_chat_agentic + updateLeadSignals.
- **Reuse do venv** — evidência: rodar pytest do worktree com o venv do repo principal
  (`C:\THALES\DAP4.0\dap4\agents\.venv\Scripts\python.exe`) + cwd no worktree → 12 baseline
  + 185 testes passaram sem reinstalar requirements.

## O que NÃO funcionou (e por quê)

- **Premissa original da Fatia 0 (construir espinha Meta)** — INVALIDADA: webhook+brand+
  sender já existiam em prod (`meta-webhook.routes.ts`, `meta-brands.ts`). Gap real era só
  persistência. Spec corrigido após leitura do código.
- **`apply_migration` cru pelo dap4** — REJEITADO: dap-aios owna o schema via Drizzle; DDL
  cru causaria drift. Migração das colunas entrou pelo dap-aios (PR #49).
- **`upsert onConflict` em índice unique PARCIAL** — não casa no PostgREST. Trocado por
  insert + catch erro `23505` pra idempotência.
- **Thales "COLEI" a service key mas não tinha** — o `.env` seguia no placeholder; resolvido
  com comando `Read-Host -AsSecureString` + `WriteAllText` sem BOM (rodado por ele → len 219).
- **Subagente pôs `lead_scoring.py` em `agents/`** — lugar errado (é serviço); movido pra
  `services/` (ana.py importa serviços via `from services.X`).
- **Risco provider tool-result** — OpenAI usa `role:"tool"`, Anthropic usa `tool_result`
  block. Resolvido confirmando Anna=gpt-4o-mini (OpenAI) → formato OpenAI correto; comentado.

## O que ainda não foi tentado

- **E2E real via Meta** — bloqueado: conta/número Prime em business verification na Meta.
- **Fatia 1.5** (subagente mapeador do lago) — reusa compute_lead_score; não iniciada.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `gateway/src/services/aios-store.ts` | Completo (merged #28 + updateLeadSignals em #29) | core da persistência |
| `gateway/src/services/aios-supabase.ts` | Completo (#28) | client AIOS |
| `gateway/src/routes/meta-webhook.routes.ts` | Completo | dual-write + persiste qualification |
| `gateway/src/config/{env,validate}.ts` | Completo (#28) | env AIOS + guard prod |
| `agents/services/lead_scoring.py` | Completo (#29) | função pura 5 eixos |
| `agents/services/llm_router.py` | Completo (#29) | chat_with_tools (chat() legado intocado) |
| `agents/agents/ana_tools.py` | Completo (#29) | tool qualificar_lead |
| `agents/agents/ana.py` | Completo (#29) | _handle_chat_agentic + branch chat_agentic |
| `agents/api/routes/chat.py` + `models/conversation.py` | Completo (#29) | /chat agentic + ChatResponse |
| `.env` (dap4 + worktrees) | Completo | AIOS_SUPABASE_URL/SERVICE_KEY colados (gitignored) |
| Spec/plano Fatia 1 | Commitado no master LOCAL | docs/superpowers/{specs,plans}/2026-06-05-anna-fatia1-* |

## Decisões tomadas

- **Schema owned pelo dap-aios via Drizzle; dap4 zero DDL** — evita drift entre os 2 repos.
- **Persistência best-effort fire-and-forget** — nunca bloqueia ACK do webhook nem resposta.
- **Fatia 1 split: LLM classifica 5 eixos / função pura computa score** — determinismo + testável.
- **action=chat_agentic (novo) em vez de re-rotear chat** — backward-compat (pipeline antigo intocado).
- **tier→status_gate: quente+morno→qualified** — escala pro consultor.
- **Persistência Fatia 1 MVP: só score+lead_tier** — 5 eixos detalhados diferidos.
- **Commits de spec/plano path-scoped, sem push** — master local atrás do origin + WIP do Thales.

## Bloqueios & perguntas abertas

- **dap-aios (dono schema)**: faltam (a) 2 unique parciais do dedup TOCTOU Fatia 0
  [`conversations(channel,external_contact) WHERE status='open'`, `leads(phone) WHERE phone IS NOT NULL`];
  (b) coluna `leads.lead_tier text` (+ `scored_at`) da Fatia 1. + RLS hardening 32 tabelas.
- **Meta business verification** (Prime) — espera externa; trava o E2E real.
- **Merge dos PRs #28 (já merged) e #29** — #29 aguardando.
- **Master local atrasado** — precisa `git pull` no `C:\THALES\DAP4.0\dap4` (tem WIP do Thales).

## Próximo passo exato

Quando a coluna `leads.lead_tier` cair no dap-aios: mergear PR #29. Em paralelo, iniciar
**Fatia 1.5** (subagente mapeador do lago) — abrir brainstorm; ele reusa
`agents/services/lead_scoring.py::compute_lead_score` pra reclassificar a base e emitir
oportunidades como gatilhos (input da Fatia 2 porta proativa).

## Setup / comandos úteis

- Worktrees vivos: `C:\THALES\DAP4.0\dap4-wt-fatia1` (branch feat/anna-fatia1-agentic).
  (O `dap4-wt-anna-aios` da Fatia 0 já foi removido.)
- pytest no worktree via venv principal: de `<worktree>/agents`, rodar
  `& "C:\THALES\DAP4.0\dap4\agents\.venv\Scripts\python.exe" -m pytest tests/ -q`
- gateway: `cd <worktree>/gateway; npm ci --ignore-scripts` (Node 24 quebra nativos);
  testes `npx vitest run`; `npx tsc --noEmit`.
- Worktree de feature: branchar de `origin/master` (não do master local atrasado).
- Commits de docs no master: `git add -- <path>; git commit -- <path>` (path-scoped).
