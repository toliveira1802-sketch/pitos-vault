---
tipo: doc-vivo
projeto: DAP4 / dap-aios
atualizado: 2026-06-05
fonte: extraído do código (branch main)
tags: [dap4, portais, aios, conselho, anna, rag]
---

# AIOS — Sala do Conselho

> Voltar ao [[00-estado-dos-portais|índice]]. 7 live · 3 WIP.
> Camada chairman: mandala de agentes, RAG knowledge, Anna Shadow.

| Rota | Feature | Status | Fonte de dados | Nota |
|------|---------|--------|----------------|------|
| `/aios` | Mandala dos agentes + painel Sprint 1 | 🟢 live | `/api/agentes` | Soft-lock visual p/ inativos |
| `/aios` | Contador "X/Y diretores ativos" | 🟢 live | derivado de `useAgentes()` | — |
| `/aios/sophia` | Página da Sophia | 🟡 WIP | `/api/agentes/sophia` + `…/executar` | Execução = **canned response** (LLM real "Rodada 10") |
| `/aios/diretores/:slug` | Página de agente genérica | 🟡 WIP | `/api/agentes/:slug` + `…/executar` | Inativos retornam `bloqueado:true`; resultado é canned |
| `/aios/diretores/:slug` | Histórico de demandas | 🟢 live | `agente_demandas` (refetch 15s) | — |
| `/aios/knowledge` | Documentos RAG indexados | 🟢 live | `/api/rag/documentos` | Lista real do banco |
| `/aios/knowledge` | Upload de arquivo (PDF/áudio/imagem/vídeo) | 🟡 condicional | `/api/rag/upload` → dap4 (`USE_DAP4_AI=true`) | Sem flag: registro mock, não vai ao ChromaDB |
| `/aios/knowledge` | Ingestão via Perplexity | 🟡 condicional | `/api/rag/perplexity` → dap4 | Stub quando flag off |
| `/aios/anna/shadow` | Fila de curadoria (observações) | 🟢 live (cond.) | `/api/anna/shadow/pending` → gateway P1 | Refresh 30s; **dual-write deployado 2026-06-05** |
| `/aios/anna/shadow` | Aprovar/Editar/Rejeitar observação | 🟢 live (cond.) | `…/approve\|edit\|reject` → P1 | Aprovação ingere em `ops_conversas_aprovadas` (Reflexion) |

**Arquitetura dual:** dados estruturais (agentes, demandas, docs) são live contra o banco local;
**execução LLM** e integração **P1** (ChromaDB, Anna Shadow) são condicionais a `USE_DAP4_AI=true`.

**Gaps:** (1) LLM real nos agentes (hoje canned, previsto "Rodada 10"); (2) RAG/Anna só funcionam
end-to-end com `USE_DAP4_AI=true`. A espinha Anna em prod (dap4 P1) está no ar; ver [[roadmap-portais]]
para a re-plataforma omnichannel.
