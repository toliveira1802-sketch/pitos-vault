---
title: "Sophia — CEO do grupo (orquestradora)"
status: "🟡 mock/spec (orquestração atual via 0613-B)"
unidade: "DAP AI / orquestração"
modelo: "Claude Sonnet"
relacionado: "[[00-roster]] · [[estrutura-prompt-agentes]] · [[0613-B]] · [[Anna]] · [[Walter]]"
tags: [dap-ai, agente, orquestracao, sophia]
---

# Sophia — CEO do grupo

> ⚠️ Canon 2026-06-04: **Sophia ≠ 0613-B**. Sophia é a CEO/orquestradora do **negócio**;
> [[0613-B]] é o agente **pessoal do Thales**. Distintas.

## Papel
CEO do grupo e **orquestradora (supervisor)**. Recebe pedido do Thales, planeja, despacha
workers especializados, sintetiza e responde.

## Stack
- **Modelo:** Claude Sonnet.
- **Canal:** hub interno (portal AIOS `/sophia`, dashboard).
- **Tools:** `dispatch_agent`, `query_supabase`, `read_kommo_funnel`, `compose_council`.

## Loop
**Plan-Execute + Orchestrator-Workers** (custo alto, justificado só em tarefa aberta/longa —
ex: "faz audit completo do funil da semana").

## Multi-agent
**Supervisor** no padrão LangGraph ("supervisor é o agente cujas tools são outros agentes").
Workers: [[Anna]], [[Walter]], [[Kimi]], [[Insights]] — cada um com system prompt, tools e memória próprios.
Escala pra hierarchical quando o nº de agentes passar de ~7.

## Guardrails críticos
- Só responde ao Thales se **≥2 workers convergirem** em fato crítico.
- Contratos A2A formais (YAML versionado) entre Sophia↔{Anna, Walter, Kimi, Insights} — pendência de implementação.

## Onde vive
- **Hoje:** a função de orquestração + presidência do Parliament vive no **[[0613-B]]**
  (`dap4` `agents/agents/personal_0613b.py`); `sofia.py` é **shim com `DeprecationWarning`**.
- **Alvo:** `dap-aios` portal AIOS (Home/Agente hoje em mock).

## Roadmap
Implementação própria separando orquestração de **negócio** (Sophia) da **pessoal** (0613-B) ·
contratos A2A em `dap-aios/contracts/` · observability stack (tracing → `agent_traces`) · dashboard `/sophia`.
