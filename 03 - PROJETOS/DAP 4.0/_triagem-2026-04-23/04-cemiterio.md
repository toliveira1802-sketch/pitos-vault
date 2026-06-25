---
title: Cemitério DAP — o que morreu, quando, por quê
date: 2026-04-23
status: triagem-v1
scope: 4 resets arquiteturais + projetos pausados/zumbis
fontes: git log C:\dev\dap4, PITOS/DAP 4.0, Downloads/Evaluate These Documents, MEMORY.md
---

# Cemitério DAP 4.0

Quatro resets arquiteturais deixaram detrito vivo. Este documento formaliza cada morte: nome, status (MORTO / PAUSED / ZUMBI), causa, data, onde ainda aparece no repo ou no vault, substituto atual.

**Legenda de status:**
- **MORTO** — descontinuado oficialmente, referências devem ser expurgadas
- **PAUSED** — não morreu, só congelou; pode voltar
- **ZUMBI** — código/doc vivo sem dono, corre risco de rodar em prod e bagunçar

---

## Linha do tempo dos 4 resets

```
FASE 1 (fev-mar/2026)  →  Exército de IAs (15 bots Flask + React, hardcoded)
FASE 2 (mar/2026)      →  Blueprint IA Mãe "Athena" (Ollama local + ChromaDB + FinOps)
FASE 3 (abr/2026 início) → Sophia Hub Vercel (ana.js + crons serverless + Supabase)
FASE 4 (abr 14/2026)   →  Parliament (13 diretores C-Level, multi-tenant, stack própria)
```

Commit-chave do corte final: `c07156d 2026-04-14 chore: remove OpenSquad system` + `905f570 2026-04-14 feat(dashboard): /agents vira Sala do Conselho C-level` + `1624109 2026-04-14 feat(parliament): C-level registry with 13 specs`.

---

## 1. Exército de IAs

- **Status:** MORTO
- **O que era:** 15 bots com emoji (Simone, Anna Laura, Vigilante, Reativador, Marketeiro, Competidor, Analista de Dados, Qualificador, Fiscal CRM, Organizador de Pátio, Estrategista de Iscas, Dedo Duro, Analista de Preço, Analista Técnico, Casanova). Stack Flask + React com dados hardcoded, cada IA sendo uma classe `IABase` com método `.executar()` retornando string literal.
- **Causa de morte:** arquitetura de brinquedo — 15 agentes estáticos, sem RAG, sem persistência real, sem estado. Não roda, não aprende, não escala.
- **Data:** substituição conceitual em mar/2026 (Blueprint IA Mãe). Morte técnica oficial 14/04/2026 com Parliament.
- **Referências vivas a expurgar:**
  - `C:\Users\docto\Downloads\Evaluate These Documents\📦ExércitodeIAs-DoctorPrime2026.md`
  - `C:\Users\docto\Downloads\Evaluate These Documents\exercito-ias-COMPLETO(1).zip`
  - `C:\Users\docto\Downloads\Evaluate These Documents\main.py` (classes IABase — confirmado NÃO é FastAPI+LangGraph)
  - `PITOS/DAP 4.0/Notas/001-dap40-master-todo.md` L271 ("15 IAs com emoji (conflita Sennin)")
- **Substituto:** Parliament (5 vozes iniciais → 13 diretores C-Level Sennin Protocol v1).

## 2. IA Mãe "Athena"

- **Status:** MORTO (conceito absorvido)
- **O que era:** Blueprint de uma IA-mãe que criaria, monitoraria e ajustaria agentes filhos. Stack: Claude Sonnet (cérebro), Ollama local (Llama 3.1 + Mistral), ChromaDB RAG, Supabase. Custo projetado R$175-225/mês. Fases A-E (KB → Athena → Dashboard → auto-criação → Kommo).
- **Causa de morte:** o papel foi absorvido pela Sophia (presidente do Parliament) → renomeada 0613-B em 16/04. A ideia de "mãe orquestradora" sobreviveu; o nome Athena, o worker Node.js `athena.js` dedicado, e a stack Ollama local foram descartados.
- **Data:** morte conceitual 14/04 (abertura do Parliament), sepultamento 16/04 com commit `8357f7b Merge feat/0613-b-rename: rename Sophia → 0613-B across the stack` e `b8ab0de refactor(parliament): remove Sophia seat, make presidency pluggable`.
- **Referências vivas a expurgar:**
  - `C:\Users\docto\Downloads\Evaluate These Documents\BLUEPRINT_IA_MAE.md`
  - `PITOS/DAP 4.0/Notas/001-dap40-master-todo.md` L272
  - Qualquer referência a `athena.js`, `ia_mae_decisoes`, `ia_knowledge_base` fora de contexto histórico
- **Substituto:** 0613-B (presidência plugável do Parliament) + Sophia Hub UI em `/sophia` no dap4.

## 3. Sophia Hub Vercel

- **Status:** MORTO
- **O que era:** linha paralela construída por terceiro (pacote Manus). `api/ana.js` (loop agêntico Claude Sonnet) + 5 crons serverless (Vigilante 5min, Analista 10min, Reativador 08:00, Lembretes 18:00, Relatório 19:00) rodando Vercel + Supabase + Kommo API v4 + Slack notifications.
- **Causa de morte:** conflita com o stack oficial (Node gateway + Python agents + FastAPI rodando na VPS Hostinger). Cron Vercel não tem estado compartilhado com o Parliament nem com o RAG ChromaDB. Duplicação de loop agêntico com Anna Phase 1a já em prod.
- **Data:** rejeição formal documentada em `PITOS/DAP 4.0/Notas/001-dap40-master-todo.md` L270 ("Sophia Hub Vercel/Node — outra arquitetura").
- **CUIDADO — colisão de nome:** `/sophia` no dap4 (criado commit `bfd5be9 2026-04-19 feat(sophia-hub): cockpit ao vivo do 0613-B`) é o **cockpit do Parliament**, NÃO o Sophia Hub Vercel morto. Nome reciclado intencionalmente.
- **Referências vivas a expurgar:**
  - `C:\Users\docto\Downloads\Evaluate These Documents\ana.js`
  - `C:\Users\docto\Downloads\Evaluate These Documents\sophia-hub(2).zip`
  - `C:\Users\docto\Downloads\Evaluate These Documents\sophia_hub_arch.mmd` / `.png`
  - Relatórios Manus em Downloads: `Relatório Definitivo_ Ecossistema Doctor Auto Prime & Sophia Hub.md`, `Relatório de Avaliação Complementar_ Sophia Hub.md`, `Roadmap de Criação_ Doctor Auto Prime & Sophia Hub.md`
- **Substituto:** Parliament + Anna agent (gateway → python-agents → gpt-4o-mini → Kommo) rodando na VPS.

## 4. OpenSquad

- **Status:** MORTO
- **O que era:** engine de orquestração de squads absorvida em 07/04 (commit `d146e49 feat: absorb OpenSquad orchestration engine`). Tinha `squads`, `orchestration`, `cfo-supabase-analytics`.
- **Causa de morte:** substituído pelo modelo Parliament (13 diretores, vozes, sínteses, vetos, multi-tenant). OpenSquad era herança de outro projeto que não se encaixou no Sennin Protocol.
- **Data:** removido 14/04/2026, commit `c07156d chore: remove OpenSquad system`.
- **Referências vivas a expurgar:** nenhuma no dap4 (removido). Só histórico git.
- **Substituto:** Parliament (`C:\dev\dap4\agents\parliament\*`).

## 5. Thales Agent

- **Status:** PAUSED
- **O que era:** agente pessoal multi-canal em `C:\dev\thales-agent`, 80% pronto em 09/04/2026. Stack: Python (main.py + channels/ + core/ + scheduler/ + tools/ + whatsapp-bridge/), Docker, pyproject.toml.
- **Causa de pausa:** falta canal Obsidian, padronização de vault path, persistência de state, integração DAP4.0. Prioridade desviou pro Parliament + Anna Phase 1a.
- **Data:** pausado 09/04/2026.
- **Referências vivas:**
  - `C:\dev\thales-agent\` (diretório inteiro intacto)
  - `MEMORY.md` → `project_thales_agent.md`
  - `PITOS/DAP 4.0/Notas/014-dap40-roadmap-30d-sistema-pessoal.md` L26 ("Thales Agent (P3) continua pausado")
  - `PITOS/DAP 4.0/Specs/2026-04-14-chairman-os-design.md` L269 (decisão técnica: thales-agent vs Meta Cloud)
- **Substituto:** nenhum ainda. Retomar só após Parliament 100% em prod.

## 6. Davi Gatuno

- **Status:** PAUSED
- **O que era:** extrator/scraper de 500 leads na VPS, aguardando escopo Kommo chats.
- **Causa de pausa:** escopo Kommo Chats v2 não confirmado. 500 leads salvos.
- **Data:** pausado abril/2026 (antes de 09/04 conforme MEMORY.md).
- **Referências vivas:** MEMORY.md → `project_davi_gatuno.md`. VPS em `/root/` (confirmar).
- **Substituto:** backfill-kommo + Anna inbox worker cobriram o caso de uso de importar conversas Kommo.

## 7. main.py FastAPI+LangGraph (suspeito)

- **Status:** FALSO POSITIVO — não existe
- **Verificação:** o `main.py` em `C:\Users\docto\Downloads\Evaluate These Documents\` é código Python do **Exército de IAs** (classes `IABase`, `Qualificador`, `FiscalCRM` com emojis e strings hardcoded). Não tem imports de FastAPI, LangGraph nem LangChain. `grep -r langgraph` em Downloads = 0 matches reais.
- **Ação:** apagar da memória. O "main.py FastAPI+LangGraph" provavelmente é falsa lembrança do `C:\dev\dap4\agents\main.py` (esse sim é FastAPI).
- **Substituto:** `C:\dev\dap4\agents\main.py` (FastAPI real, em prod) + Parliament voices async.

## 8. chromadb/chroma:latest

- **Status:** MORTO (tag)
- **O que era:** uso da tag `latest` no compose da VPS.
- **Causa de morte:** breaking changes silenciosos — path mudou pra `/data`, API v2, sem `python3`. Quebrou prod.
- **Data:** feedback registrado em MEMORY.md → `feedback_chromadb_latest_breaking.md`.
- **Referências vivas a expurgar:** qualquer `chromadb/chroma:latest` em `docker-compose*.yml`. Pinar `chromadb/chroma:<semver>`.
- **Substituto:** versão semver fixa. Validar qual está rodando em `/opt/doctor-auto-ai/` na VPS 76.13.170.42.

## 9. Sala do Conselho Dify

- **Status:** ZUMBI
- **O que é:** spec canônica `PITOS/Sistemas/sala-do-conselho-dify-dap4.md` (19/04/2026) descreve Sophia + 12 diretores como **skills Dify** — fluxo paralelo ao Parliament Python rodando no dap4.
- **Situação:** a versão Parliament (Python, `C:\dev\dap4\agents\parliament\`) venceu e está em prod (cutover 23/04 — `project_dap4_cutover_2026_04_23.md`). A versão Dify nunca foi implementada, mas o doc segue ativo e listado em MEMORY.md (`reference_sala_do_conselho_dify.md`) como "fonte canônica complementar".
- **Causa de status zumbi:** doc vivo com prompts, SQL, workflows detalhados. Se alguém ler isso sem contexto, pode tentar montar. Colisão clara: mesmo conceito, duas stacks diferentes.
- **Decisão pendente (Thales):** matar oficialmente a variante Dify ou mantê-la como plano B de orquestração visual? Enquanto não houver decisão, tratar como ZUMBI.
- **Referências vivas:**
  - `PITOS/Sistemas/sala-do-conselho-dify-dap4.md`
  - `MEMORY.md` → `reference_sala_do_conselho_dify.md`
- **Substituto de fato:** Parliament Python + `/sophia` hub no dap4.

## 10. Variantes menores / ruído

| Item | Status | Nota |
|------|--------|------|
| Cohere integration (scripts `cohere_demo.py`, Ahrefs+Cohere) | MORTO | Vendor lock-in, rejeitado no master-todo L273. Arquivos em Downloads. |
| CRM Duplo (`conceito_crm_duplo.md`, `crm_bot.py`) | MORTO | Pesquisa Fase 2. Não virou código no dap4. |
| Roadmap 10k oficinas SaaS | MORTO | Fora de escopo (master-todo L274). Foco DAP Prime primeiro. |
| Command Center standalone (`AgentIAPage.tsx`, `AgentRAGPage.tsx`, `LeadsManagement.tsx` em Downloads) | ZUMBI | Pacote Manus — componentes não integrados ao dap4/dashboard. Avaliar e descartar. |
| `doctor-ai-dashboard` (nome antigo do repo) | MORTO | Renomeado pra `dap4` em 09/04 (commit `a7a42df`). |
| Dashboard/gateway tree deprecated | MORTO | Removido 09/04 (commits `6aa57c2`, `a4f28b5` — 100 arquivos). |

---

## Ações de expurgo recomendadas

1. **Arquivar `C:\Users\docto\Downloads\Evaluate These Documents\`** em `_archive/2026-04-23-pacote-manus/` — está todo tratado por MEMORY.md → `project_manus_analise_kommo.md` (5.192 leads) mas os arquivos de **arquitetura** (ana.js, BLUEPRINT_IA_MAE.md, main.py, sophia-hub.zip, exercito-ias.zip) deveriam sair da pasta Downloads pra evitar que sejam lidos como canon.
2. **Decidir Dify** (Thales): matar `PITOS/Sistemas/sala-do-conselho-dify-dap4.md` ou marcar com banner "ARQUIVADO — substituído por Parliament Python, não implementar".
3. **Pinar chromadb** na VPS compose. Verificar agora antes do próximo restart.
4. **Thales Agent:** decidir no próximo ritual (manhã/noite) se retoma ou arquiva. 80% pronto parado é dívida.
5. **Davi Gatuno:** confirmar escopo Kommo Chats v2 ou aposentar — backfill-kommo já cobre.
6. **Apagar falso positivo "main.py FastAPI+LangGraph"** da narrativa interna. Não existe.

---

## Mapa de substituições (rápido)

| Morto | Substituto atual | Path |
|-------|------------------|------|
| Exército de IAs | Parliament (13 diretores) | `C:\dev\dap4\agents\parliament\` |
| Athena IA Mãe | 0613-B + Sophia Hub UI | `dashboard/src/pages/SophiaHub.jsx` |
| Sophia Hub Vercel | Anna + gateway + python-agents | `gateway/` + `agents/` VPS |
| OpenSquad | Parliament registry | `agents/parliament/registry.py` |
| CRM Bot Cohere | Anna (gpt-4o-mini) | `agents/anna/` |
| chromadb:latest | chromadb:\<semver> | `docker-compose.yml` VPS |

---

_Documento gerado em 2026-04-23 como parte da triagem pré-cutover consolidado. Próxima revisão: após decisão Thales sobre Dify e thales-agent._
