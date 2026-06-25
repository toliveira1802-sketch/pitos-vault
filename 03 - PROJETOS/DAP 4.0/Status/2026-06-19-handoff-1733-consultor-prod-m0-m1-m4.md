---
type: handoff
date: 2026-06-19
time: 17:33
project: DAP 4.0 — dap-aios (portal Consultor)
topic: Roadmap Consultor→prod travado; M0/M1/M4 fechados; M2 (staging) bloqueado em 2 segredos do Thales
tags: [handoff, claudin, dap-aios, consultor, producao, roadmap, rag]
---

# Handoff — Consultor → produção: ROADMAP + M0/M1/M4 done, M2 aguardando

## Contexto

Sessão começou retomando o handoff mestre de 2026-06-18 (consolidação Supabase + RAG nativo).
Primeiro fechamos a frente RAG pendente (estava no working tree, não commitada). Depois o Thales
pediu um **roadmap de arquitetura até subir o Consultor pra VPS e operar**. Definimos o processo,
travamos o escopo, e começamos a executar em paralelo (3 tracks). Alvo do milestone, decidido pelo
Thales: **portal Consultor operável em produção com dado real (OS, quotes, clientes, agenda)**,
cadência **staging-first rígida**. Anna e RAG ficam fora deste milestone.

Repo: `C:\THALES\DAP4.0\dap-aios` (monorepo pnpm). Branch de trabalho: **`feat/anna-aios-event-webhook`**.
**Nada foi pushado** — 8 commits locais. Banco prod = Supabase **hlhf** (`hlhfqnhsvwxodtwdkkhf`).

## O que funcionou (com evidência)

- **RAG: motor híbrido nativo commitado** — `e15829f`. Estava no working tree do handoff mestre; gates verdes, 9 testes. (knowledge.ts + leads enriquecido + rota /query nativa.)
- **RAG: ingestor de Markdown do vault** — `09884b8` + `0e4af83`. Lê pasta do PITOS, chunk por heading, embed 3-large@1024, dedup idempotente por sha256, CLI `pnpm rag:ingest`. **15 testes verdes**; dry-run offline provado: pasta `Status/` (28 .md) → **282 chunks**. Falta só `OPENAI_API_KEY` + senha DB pra rodar de verdade (gravar).
- **ROADMAP gravado** — `C:\THALES\PITOS\03 - PROJETOS\DAP 4.0\Status\2026-06-19-ROADMAP-consultor-prod.md` (ADR D1–D5 + delta + M0–M7 com gates). Memória `roadmap-consultor-prod.md` criada.
- **Inventário Fase 1 (3 agentes Explore, read-only)** — confirmou: núcleo do Consultor (Clientes, Veículos, OS completa, Pátio, Agenda, KPIs, Pendências, Inbox ao vivo) é **REAL e sólido**; auth real bem construída (choke point cobre todas as rotas /api). Gaps reais: segurança (boot-guard, role-override), ambiente (sem Supabase prod), infra (sem docker-compose.prod), RLS núcleo enabled-sem-policy, sem UI de criar quote.
- **M1 — Hardening de auth P0 (done)** — commits `1320a80` (boot-guard client: stub impossível em prod sem `VITE_SUPABASE_*`), `38cbd33` (hard-block role-override em `NODE_ENV=production`), `b50a98d` (`SUPABASE_JWT_SECRET` no .env.example), `eece6dc` (canário CI contra vazamento de service-role no bundle), `142a5b8` (plano). Gates: tsc 0 erros, eslint 0 warnings, **client 58/58, server unit 84/84**.
- **M4 — RLS do núcleo versionado (done)** — `cf5bccf`. Migration `server/migrations/0008_rls_core_consultor_baseline.sql` idempotente, garante ENABLE RLS + REVOKE anon/authenticated nas 31 tabelas geridas em qualquer env fresh. Modelo documentado: "RLS = rede de segurança; autz na app via requirePermission" (sem policies per-row — JWT sem role claim, server usa rolbypassrls). Journal idx 8. Gates: tsc 0, unit 84/84.
- **M2 — Supabase STAGING provisionado** — projeto **DAP AIOS STAGING** (`zguwacncaifditqyjshf`, sa-east-1, ACTIVE_HEALTHY, US$10/mês). URL `https://zguwacncaifditqyjshf.supabase.co`. anon (legacy JWT) e publishable key já captados via MCP.

## O que NÃO funcionou (e por quê)

- **Testes de INTEGRAÇÃO não rodam** — `password authentication failed for user "postgres"` / `ECIRCUITBREAKER` no pooler do **hlhf**. Confirmado **preexistente** (falhava antes das mudanças do M1, via stash) e bateu nos 3 contextos (M1, M4, meu dry-run do RAG). Causa provável: senha do DB no `.env` local desatualizada OU circuit-breaker do pooler por tentativas repetidas. Lógica nova coberta por unit; integração fica cega até resolver.
- **`SendMessage` pra continuar agente async não está disponível** — o ToolSearch não acha. Por isso, quando o 1º agente do M1 parou num plano (em vez de implementar), tive que disparar um agente NOVO pra executar o plano salvo, não continuar o mesmo.
- **1º agente do M1 entrou em modo planning** (superpowers) em vez de implementar direto — produziu plano bom mas parou pedindo modo de execução. Resolvido com 2º agente executando o plano.

## O que ainda não foi tentado

- Rodar `pnpm db:push` + `db:seed` contra o staging novo (M2) — **bloqueado** na senha do DB.
- Resetar a senha do DB do hlhf / confirmar cooldown do pooler pra destravar testes de integração.
- M3 (criar quote na UI + esconder os 6 stubs) — depende de staging pra validar.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `server/src/services/rag/knowledge.ts` | Completo | RAG nativo (commit e15829f) |
| `server/src/services/rag/ingest-md.ts` | Completo | Ingestor MD (09884b8, dry-run offline 0e4af83) |
| `server/scripts/ingest-vault.ts` | Completo | CLI `pnpm rag:ingest` |
| `server/test/unit/rag-ingest-md.test.ts` | Completo | 15 testes verdes |
| `client/src/lib/supabase.ts` | Completo | M1 boot-guard de prod (1320a80) |
| `server/src/middleware/requireAuth.ts` | Completo | M1 hard-block role-override (38cbd33) |
| `server/test/integration/requireAuth.test.ts` | Completo (não roda) | +3 testes; bloqueado por pooler |
| `server/test/unit/auth-env-guard.test.ts` | Completo | M1 canário service-role (eece6dc) |
| `server/migrations/0008_rls_core_consultor_baseline.sql` | Completo | M4 RLS baseline (cf5bccf) |
| `.env.example` | Completo | SUPABASE_JWT_SECRET documentado |
| `PITOS/.../Status/2026-06-19-ROADMAP-consultor-prod.md` | Completo | Roadmap M0–M7 |
| `~/.claude/.../memory/roadmap-consultor-prod.md` | Completo | Memória das decisões |

## Decisões tomadas

- **D1 — `hlhf` vira PROD; cria-se Supabase NOVO só pra staging** (feito: `zguwacncaifditqyjshf`). Razão: hlhf já tem o negócio real (418 clientes, 659 OS); promover é zero-migração/zero-risco; staging novo para de mutar dado real (hoje `db:push` de staging bate no hlhf).
- **D2 — criação de quote (proposta) no portal ENTRA no escopo** (M3). Hoje só converte; falta UI.
- **D3 — 6 telas vazias ESCONDIDAS do nav em prod** (Leads-edit, Aprovações, Conversas, 4 sub-dashboards). Construir depois.
- **D4 — imagem promovida staging→prod + migrations versionadas** (fim do `db:push` direto no banco em prod).
- **D5 — staging-first rígido.**
- **M4: sem policies per-row** — só ENABLE+REVOKE versionado + modelo documentado. Razão: server usa rolbypassrls, JWT sem role claim → policy per-row seria peso morto.
- **Paralelização via agentes dap-dev em background** + commits por path explícito (nunca `git add -A`) pra não cruzar frentes no mesmo working tree.

## Bloqueios & perguntas abertas

- **M2 bloqueado em 2 segredos do Thales** (dashboard do projeto STAGING `zguwacncaifditqyjshf`): (1) senha do DB → Session pooler connection string; (2) `service_role` key.
- **Pooler do hlhf com auth falhando** (circuit-breaker) — resolver pra destravar testes de integração; relevante porque hlhf vira PROD.
- **Push da branch `feat/anna-aios-event-webhook`** pendente de ok do Thales (8 commits à frente local).
- **Token CF de escrita** revogado no hardening anterior — necessário no M6 (ingress prod).

## Próximo passo exato

**Fechar o M2.** Quando o Thales colar os 2 segredos do dashboard do `DAP AIOS STAGING`
(`zguwacncaifditqyjshf`): montar o `.env` de staging (template pronto no chat: URL + anon/publishable
já preenchidos, faltam DATABASE_URL com senha + service_role), então — **apontando DATABASE_URL pro
staging, NUNCA pro hlhf** — rodar `pnpm db:push` (schema do zero) → `pnpm db:seed` (dado sintético) →
confirmar via MCP `list_tables` (project_id `zguwacncaifditqyjshf`) que customers/vehicles/
service_orders/quotes/appointments nasceram. Isso fecha M2 e libera M3 (criar quote na UI + esconder
os 6 stubs, validado no staging novo).

## Setup / comandos úteis

```powershell
# Gates (pnpm fora do PATH do bash — usar .cmd ou PowerShell)
Set-Location C:\THALES\DAP4.0\dap-aios\server
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\vitest.cmd run test/unit
# git commit (husky usa pnpm de C:\Users\docto\AppData\Roaming\npm)
$env:PATH = "C:\Users\docto\AppData\Roaming\npm;$env:PATH"

# M2 (quando tiver a senha) — CUIDADO: DATABASE_URL tem que ser o STAGING
# Supabase STAGING: zguwacncaifditqyjshf · PROD: hlhfqnhsvwxodtwdkkhf
```
