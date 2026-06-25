---
title: Handoff — Deploy Sprint 4b em prod · hotfix P1 Anna shadow · estrutura Recepção Anna
date: 2026-06-04
status: handoff (rodada concluída)
scope: deploy Sprint 4b (dap-aios) em prod · co-deploy dap4 (já estava feito) · hotfix /edit-/approve 500 · doc Recepção Anna + descrição Anna CSO Sales · reconciliação roadmap CRM Duplo
relacionado: "[[2026-06-04-handoff-llm-keys-sprint4b-merged]] · [[Recepcao-Anna]] · [[Anna-CSO-Sales]]"
---

# Handoff — 2026-06-04 (sessão 3) · Deploy Sprint 4b + hotfix Anna + Recepção

> Continuação de `2026-06-04-handoff-llm-keys-sprint4b-merged`. Esta sessão **executou o
> deploy do Sprint 4b em prod** (pendência #1 daquele handoff), corrigiu um **P1 que o
> deploy revelou** na curadoria da Anna, e **estruturou a "recepção Anna"** a pedido do Thales.

## 1. Resumo executivo

1. **✅ Sprint 4b em prod** — dap-aios `6cc30b6 → d44f564` na VPS. 6 passos do RUNBOOK verdes, validados pelo Thales (login real, gestão `/gestao/dashboard`, appointment gravado + evento).
2. **✅ Co-deploy dap4 já estava feito** — o gateway shadow proxy (`anna-shadow.routes`) foi mergeado/deployado em 26/05 (PR #26). O passo do handoff anterior estava com info stale. Nada a fazer além de verificar.
3. **🔴→✅ P1 corrigido** — `/agent/anna/shadow/:id/{approve,edit}` retornava 500 (ChromaDB rejeita metadata `None`). Fix mergeado (PR #27 → `e0756bd`), agents rebuildado, **verificado E2E em prod (200)**.
4. **✅ Estrutura Recepção Anna** — doc de arquitetura ([[Recepcao-Anna]]) + descrição executiva da Anna como CSO Sales ([[Anna-CSO-Sales]]).
5. **⚠️ Achados que precisam de decisão** — RLS desabilitado no `hlhf` (crítico), learning loop meia-ligado, gap de toolchain no host da VPS.

## 2. Deploy Sprint 4b (dap-aios) — passos executados

Seguiu [[RUNBOOK-DEPLOY]]:
1. **Pré-migration:** `hlhf` (`hlhfqnhsvwxodtwdkkhf`) — as tabelas `appointments` + `content_items` **já existiam** (push local anterior, dev compartilha banco prod). Estrutura confirmada batendo com o schema Drizzle. Migration = no-op.
2. **VPS:** `git reset --hard origin/main` (`d44f564`) → backup `dap-aios:staging-bak-2026-06-04` → `docker build` → `compose up -d --force-recreate aios-staging`. Container **healthy**, sem crash de `import.meta` (fix CJS-safe ok).
3. **Migrations:** `pnpm db:push` **falhou no host** — `/opt/dap-aios/src` não tem `node_modules` (build é dentro do Docker; `drizzle-kit`/`tsx` são devDeps). **Não instalei toolchain de dev em prod.** Verifiquei via SQL que o schema (tabelas + colunas + FKs + índices) está 100% aplicado → migration considerada feita por aplicação anterior. Débito cosmético: journals `__drizzle_migrations` (public/drizzle/test) vazios.
4. **Smoke (Thales):** login real ✅ · gestão cai em `/gestao/dashboard` ✅ · appointment criado ✅ (evento `appointment_created` confirmado no `hlhf`, cadeia customer→vehicle→appointment).
5. **Co-deploy dap4:** master = `9513ce9` (squash do PR #26) já continha o gateway shadow proxy; container gateway já tinha `dist/routes/anna-shadow.routes.js`. **Nada a mergear.**
6. **Smoke cross-repo (Thales):** `/aios/anna/shadow` carregou a fila (veio cliente). Cadeia `dap-aios → gateway dap4 → Python anna_shadow` fechada.

## 3. Hotfix P1 — Anna shadow approve/edit (ChromaDB None metadata)

- **Sintoma:** `POST /api/anna/shadow/:id/edit` → gateway 500 (Python 5xx).
- **Causa raiz:** `_ingest_pair_into_rag` (agents/api/routes/anna_shadow.py) montava metadata pro ChromaDB com valores `None` (`kommo_lead_id`/`anna_intent`/`anna_confidence` quando lead não-Kommo; `approved_at` **sempre** None no momento do ingest). ChromaDB só aceita str/int/float/bool → `ValueError`.
- **Natureza:** bug **pré-existente do dap4** (desde 26/05). O deploy de hoje só **revelou** — deu a UI que finalmente exercita approve/edit. Nunca tinha funcionado em prod.
- **Fix:** filtra chaves `None` do dict (dict comprehension `if v is not None`) + teste de regressão `test_metadata_drops_none_values`.
- **Verificação:** 11/11 pytest verde (container agents VPS) + **E2E em prod: `/approve` na obs `19cd66e1…` (smoke-test de 26/05) retornou 200** e ingeriu no RAG. 500 eliminado.
- **Deploy:** PR #27 squash → `master e0756bd` → VPS `/opt/doctor-auto-ai` `reset --hard origin/master` → backup `doctor-auto-ai-agents:bak-2026-06-04` → `docker compose build agents` (nohup, resiliente a SSH drop) → `up -d --force-recreate agents`. Healthy, fix confirmado no código rodando.

## 4. Estrutura Recepção Anna (a pedido do Thales)

Dois docs novos no vault (`Ecossistema/DAP-AI/Agentes/`):
- **[[Recepcao-Anna]]** — arquitetura da camada de intake. Núcleo: Anna vive em **dois planos** — **AIOS = configuração** (persona/skills/subagentes/knowledge/guardrails) e **Consultor = operação** (classifica + demanda). Recepção channel-agnostic (canais = fontes, banco = verdade) → pronta pro Kommo-out futuro. O "demandar" usa a tabela **`agente_demandas`** (existe no banco, **sem código que use ainda**).
- **[[Anna-CSO-Sales]]** — descrição executiva da Anna como CSO Sales (Diretora de Vendas, worker da Sophia), na mandala AIOS. Voz, classificação (tier/score), guardrails, escalação, CRM Duplo, stack, memória, loop.

> Canon: grafia **Anna** (código roda como `Ana`, renomear). Título evoluiu CRO digital → **CSO Sales**.
> ⚠️ Colisão de sigla na mandala: Anna = "CSO **Sales**" e Chapapiuro = "CSO **Strategy**" — ambos "CSO". Decidir desambiguação (ex.: CSO vs CStO).

## 5. Reconciliação — Roadmap CRM Duplo (Manus, mar/2026)

Thales colou um roadmap antigo (Manus AI, 18/mar). **~metade já foi feita por outra arquitetura, e uma premissa central está invertida:**
- ❌ **Stale:** "descontinuar Python (`main.py`), focar 100% Node/Vercel" — **invertido**: o backend canônico HOJE É Python FastAPI (`agents/`). Deploy é VPS + Cloudflare Tunnel + Docker, não Vercel. "Ana"→"Anna". Kommo central → em questionamento (Kommo-out).
- ✅ **Ouro (ainda válido, net-new):** **CRM Duplo** — CRM Interno (ops ativa, Anna) + CRM Externo (lago de leads, scored) + **o Bote / IA Pescadora** (cron 2x/semana que reativa leads frios cruzando com campanhas e os devolve pro Interno). Encaixa direto na Recepção Anna (já incorporado em [[Anna-CSO-Sales]] §"Onde ela atua"). **O Bote não existe ainda** — candidato a spec.
- 🟡 **Parcial:** Sprints 3–5 (gestão oficina, aprovação digital, financeiro) — muito já existe no dap-aios (OS, pátio kanban, agenda, quotes, DRE).

## 6. Arquivos / commits / coordenadas

- **dap4:** `agents/api/routes/anna_shadow.py` (fix) + `agents/tests/test_anna_shadow.py` (regressão). PR #27 → `master e0756bd`. Branch `fix/anna-shadow-ingest-none-metadata` (deletada). Repo `github.com/toliveira1802-sketch/dap4`, branch de prod = **`master`**.
- **Vault:** `Ecossistema/DAP-AI/Agentes/Recepcao-Anna.md` + `Anna-CSO-Sales.md` (novos) · `Anna.md` (backlink).
- **VPS `root@76.13.170.42`:** dap-aios em `/opt/dap-aios/src` (`d44f564`), container `aios-staging`. dap4 em `/opt/doctor-auto-ai` (`e0756bd`), containers `doctor-auto-ai-{agents,gateway,chromadb}-1`. Backups: `dap-aios:staging-bak-2026-06-04`, `doctor-auto-ai-agents:bak-2026-06-04`.
- Supabase: portais=`hlhf` (`hlhfqnhsvwxodtwdkkhf`), dap4=`acuufrgo` (`acuufrgoyjwzlyhopaus`).

## 7. Pendências / próxima rodada

1. **🔴 RLS desabilitado no `hlhf`** — advisor Supabase marca crítico: 32 tabelas (incl. `customers`/`users`/`vehicles`) com RLS off → anon key lê/escreve tudo. Contradiz docs ("RLS em 19 tabelas"). App não quebra (server bypassa via pooler `postgres`), mas exposição é real. **Decidir religar RLS com policies** (não auto-aplicar — ligar sem policy trava tudo).
2. **Learning loop meia-ligado** — `ops_conversas_aprovadas` (onde a curadoria grava) **não está na retrieval da Anna** (`ana.yaml rag_collections`). Curar hoje não realimenta a Anna em prod. Decidir ligar com salvaguarda anti-parroting (exemplo = referência, não template).
3. **ADR Kommo-out** — sair do Kommo → Meta omnichannel (WA/IG/FB direto) + CRM nativo no portal. Mapear paridade de função + migração de leads. Arquitetura já suporta.
4. **Spec do Bote / IA Pescadora** — reativação do lago de leads (do roadmap CRM Duplo). Não existe ainda.
5. **Wiring da Recepção** (specs pequenos independentes): (a) config-as-data da Anna no AIOS, (b) `classificar → lead` + `demandar → agente_demandas`, (c) fila de demandas no Consultor.
6. **Débito de teste Sprint 4b** (do handoff anterior, segue aberto): cobrir dashboardService etc → gate 62→65; transação no `updateAppointment`.
7. **db:push no host VPS** — instalar toolchain ou rodar migrations via container/local. Hoje schema aplicado, mas o caminho oficial do RUNBOOK não funciona no host.
8. **Limpar backups VPS:** `dap-aios:staging-bak-pre-anon-rebuild`, `staging-bak-2026-06-04`, `doctor-auto-ai-agents:bak-2026-06-04`.

## 8. Paralelizável / subagentes

- Specs independentes da Recepção (§7.5) — 1 subagente por spec.
- Débito de teste (§7.6) — 1 subagente por service.
- Sequencial/cuidado: religar RLS (§7.1), qualquer infra prod, migração de leads do Kommo-out.
