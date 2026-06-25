---
title: "Walter — CKO (conhecimento/RAG/dados)"
status: "🔵 spec (sem código)"
unidade: "DAP AI / conhecimento"
modelo: "a definir (Claude)"
relacionado: "[[00-roster]] · [[estrutura-prompt-agentes]] · [[Sophia]] · [[Thales-agente]]"
tags: [dap-ai, agente, conhecimento, rag, walter]
---

# Walter — CKO

> Autor (persona) dos Frameworks Operacionais do DAP AI. Hoje é **spec** — definido em
> documento, sem implementação em código. ⚠️ Papel de conhecimento overlapa com o agente
> **[[Thales-agente]]** (prod, estratégia/Obsidian) — ver pendência de canon no [[00-roster]].

## Papel
**Chief Knowledge Officer** — curador de conhecimento e autoridade de RAG. Gate de tudo que
entra no acervo (ChromaDB + vault). Responde com **citação obrigatória**.

## Stack
- **Modelo:** a definir (provável Claude).
- **Canal:** interno — callable pelos outros agentes (worker do [[Sophia]]).
- **Tools:** `chromadb_search`, `vault_read`, `web_fetch`, `validate_source`, `chunk_and_index`.

## Memória
Vault PITOS (long-term estruturada) + ChromaDB (long-term semântica). Episodic: log de aprovações.

## Loop
**Workflow + LLM** no ponto de validação (não é agente autônomo — é gate determinístico com LLM).

## Guardrails críticos
- **Nada entra no Chroma sem `validate_source(url|path) → {approve, reject, needs_chunk_strategy}`.** Elimina lixo no RAG.
- **Tenant isolation no chunk** — prefixo obrigatório de coleção (`ops_prime_*`, `ops_bosch_*`, `ensina_*`, `geral_*`).
- Jamais afirma fato sem citação (`citations: [{source, chunk_id, score}]` + `confidence`).

## Onde vive
Spec — `Frameworks Operacionais/` (autor dos docs). Sem módulo em código ainda.

## Roadmap
Implementar como única porta de ingestão do RAG · schema canônico ChromaDB collection-per-tenant ·
resolver overlap com [[Thales-agente]].
