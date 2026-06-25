---
title: "00 · Roster de Agentes — DAP AI"
status: "🔧 estruturando — canon cravado 2026-06-04"
unidade: "DAP AI"
relacionado: "[[README]] · [[estrutura-prompt-agentes]] · [[anna-guardrails]] · [[2026-06-04-handoff-merge40-camadaA-rotacao-chaves]]"
tags: [dap-ai, agentes, roster, canon]
---

# Roster de Agentes — DAP AI

> Fonte única de verdade dos agentes de IA do ecossistema DAP. Reconcilia os **dois
> rosters historicamente conflitantes** (stack `dap4` em prod vs spec `dap-aios`) sob
> um canon de nomes decidido pelo Thales em 2026-06-04. Serve dev (implementação),
> conteúdo (DAP Social/Studio/Ensina) e RAG.

## Canon de nomes (decisão Thales · 2026-06-04)

1. **Anna** (dois "n") é a grafia canônica da agente de vendas/WhatsApp. O código `dap4`
   roda hoje como `Ana` (GPT-4o-mini) → **renomear `Ana → Anna`** em rodada futura.
2. **0613-B ≠ Sophia** — são **duas entidades distintas**:
   - **0613-B** = agente **pessoal do Thales**, roda no número pessoal dele.
   - **Sophia** = **CEO do grupo**, orquestradora do negócio.
3. **Kimi** e **Insights** têm **nome provisório** — serão renomeados (nome novo a definir).

## Dois planos de agentes

O ecossistema tem dois planos que coexistem e precisam convergir:

- **Plano em produção (`dap4`)** — multi-agente RAG rodando hoje na VPS. Agentes reais,
  models reais, mas naming legado (`Ana`, `Kimi`, `Insights`) e orquestração via `0613-B`.
- **Plano-alvo (`dap-aios`)** — visão de plataforma com **Sophia** (CEO) como supervisor e
  workers especializados por área. Hoje só Sophia + Anna têm stub; o resto é spec/mock.

## Roster canônico

| # | Agente | Papel | Unidade/área | Modelo | Canal | Status | Vive em |
|---|--------|-------|--------------|--------|-------|--------|---------|
| 1 | **Sophia** | CEO do grupo · orquestradora (supervisor) | DAP AI / orquestração | Claude Sonnet | Hub interno (`/sophia`, portal AIOS) | 🟡 mock/spec | `dap4` `personal_0613b.py` (função atual) · `dap-aios` AIOS portal (mock) |
| 2 | **0613-B** | Agente pessoal do Thales · presidente externo do Parliament | DAP AI / pessoal | Claude Sonnet | WhatsApp nº pessoal Thales | ✅ prod | `dap4` `agents/agents/personal_0613b.py` |
| 3 | **Anna** | CRO digital · primeira voz do funil WhatsApp, qualifica e converte | DAP AI / comercial | GPT-4o-mini | WhatsApp (Meta Cloud API) via Kommo | ✅ prod (como `Ana`) · 🟡 shadow UI `dap-aios` | `dap4` `agents/agents/` · `dap-aios` Anna shadow |
| 4 | **Walter** | CKO · curador de conhecimento, RAG autoridade, dados | DAP AI / conhecimento | a definir (Claude) | Interno (callable por agentes) | 🔵 spec | Frameworks Operacionais (autor) · sem código |
| 5 | **Kimi** ⚠️ | CRM · relacionamento e funil Kommo | DAP AI / CRM | Claude Sonnet | Kommo CRM | ✅ prod · ⚠️ a renomear | `dap4` `agents/agents/` |
| 6 | **Insights** ⚠️ | Analytics · inteligência de dados do funil | DAP AI / analytics | Claude | Interno (dashboard) | ✅ prod · ⚠️ a renomear | `dap4` `agents/agents/` |
| 7 | **Thales** (agente) | Estratégia · leitura/escrita no vault Obsidian | DAP AI / estratégia | Claude Sonnet | Obsidian vault | ✅ prod | `dap4` `agents/agents/` |
| 8 | Rafael | Operação | DAP AI / operação | a definir | a definir | 🔵 spec | `dap-aios` (planejado) |
| 9 | Francisco | Financeiro | DAP AI / financeiro | a definir | a definir | 🔵 spec | `dap-aios` (planejado) |
| 10 | Bianca | Marketing | DAP AI / marketing | a definir | a definir | 🔵 spec | `dap-aios` (planejado) |
| 11 | Zoraide | Pós-venda | DAP AI / pós-venda | a definir | a definir | 🔵 spec | `dap-aios` (planejado) |
| 12 | Claudio | Tech / segurança | DAP AI / tech | a definir | a definir | 🔵 spec | `dap-aios` (planejado) |
| 13 | Marcia | Pessoas | DAP AI / RH | a definir | a definir | 🔵 spec | `dap-aios` (planejado) |
| 14 | Pitoco | Produto | DAP AI / produto | a definir | a definir | 🔵 spec | `dap-aios` (planejado) |
| 15 | Thamy | Design | DAP AI / design | a definir | a definir | 🔵 spec | `dap-aios` (planejado) |

**Legenda de status:** ✅ prod (roda hoje) · 🟡 mock/shadow (stub parcial) · 🔵 spec (só papel definido, sem código).

## Pendências de canon (decisões abertas pro Thales)

- **Nome novo de Kimi e Insights** — definir.
- **Walter vs Thales (agente)** — ambos tocam conhecimento/estratégia. Walter (CKO) é spec;
  `Thales` (agente) roda em prod fazendo estratégia/Obsidian. Decidir se consolidam ou coexistem.
- **Sophia vs 0613-B na orquestração `dap4`** — hoje a orquestração + Parliament vivem no
  `0613-B` (`personal_0613b.py`); `sofia.py` é shim com `DeprecationWarning`. Quando Sophia (CEO)
  ganhar implementação própria, separar a orquestração de negócio (Sophia) da pessoal (0613-B).
- **Models e canais dos 8 workers spec** — a definir quando saírem do papel.

## Template por agente (nota individual)

Cada agente tem nota própria (`<Nome>.md`) com:

```
nome · papel · unidade/área · modelo · canal
RAG / coleções ChromaDB · status · onde vive no código
loop de decisão · multi-agent (supervisor/worker) · guardrails críticos · roadmap
```

Fundamentação dos campos: [[estrutura-prompt-agentes]] (identidade, tools, memória,
loop, guardrails) e [[anna-guardrails]] (guardrails operacionais da Anna).

## Notas individuais

- [[Sophia]] · [[0613-B]] · [[Anna]] · [[Walter]] · [[Kimi]] · [[Insights]] · [[Thales-agente]]
- Spec (stub): [[Rafael]] · [[Francisco]] · [[Bianca]] · [[Zoraide]] · [[Claudio]] · [[Marcia]] · [[Pitoco]] · [[Thamy]]
