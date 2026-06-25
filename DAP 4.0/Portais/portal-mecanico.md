---
tipo: doc-vivo
projeto: DAP4 / dap-aios
atualizado: 2026-06-05
fonte: extraído do código (branch main)
tags: [dap4, portais, mecanico]
---

# Portal Mecânico

> Voltar ao [[00-estado-dos-portais|índice]]. **8 live · 0 gap funcional** — o portal mais maduro.
> Foco no chão de oficina: kanban de OS + detalhe técnico.

| Rota | Feature | Status | Fonte de dados | Nota |
|------|---------|--------|----------------|------|
| `/mecanico/patio` | Kanban de OS por status | 🟢 live | `/api/service-orders` | Refetch 15s; 7 colunas (opened→ready) + gaveta Finalizadas |
| `/mecanico/patio` | Cards com cliente/veículo/mecânico/tempo | 🟢 live | mesma query com joins | Dados reais via Drizzle |
| `/mecanico/os/:id` | Detalhe da OS (header KPIs) | 🟢 live | `/api/service-orders/:id` | Estado, mecânico, veículo, previsão, proposta origem |
| `/mecanico/os/:id` | Editor de diagnóstico | 🟢 live | `PATCH …/:id/diagnosis` | Inline com debounce |
| `/mecanico/os/:id` | Checklist de inspeção | 🟢 live | `PATCH …/:id/checklist` | Schema `Checklist` tipado |
| `/mecanico/os/:id` | Transições de status | 🟢 live | `PATCH …/:id/status` | `validNext[]` vem do servidor (state machine no backend) |
| `/mecanico/os/:id` | Atribuição de mecânico | 🟢 live | `PATCH …/:id/assign`, `/api/service-orders/mechanics` | Lista de mecânicos do tenant |
| `/mecanico/os/:id` | Estimativa de entrega (calc inline) | 🟢 live | `POST /api/calculators/delivery_estimate/run` | Pré-popula do status atual; histórico dos últimos 5 runs |

**Gaps:** sem drag-and-drop no kanban do mecânico (mudança de status é pelo detalhe da OS);
sem filtro por mecânico na UI do kanban. Nenhum gap de integração — tudo live.
