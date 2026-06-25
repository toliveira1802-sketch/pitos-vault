---
tipo: doc-vivo
projeto: DAP4 / dap-aios
atualizado: 2026-06-05
fonte: extraído do código (branch main)
tags: [dap4, portais, consultor]
---

# Portal Consultor

> Voltar ao [[00-estado-dos-portais|índice]]. 12 live · 2 WIP · 5 stub (19 rotas).
> Núcleo operacional do consultor de serviço. É o portal mais usado no dia a dia.

| Rota | Feature | Status | Fonte de dados | Nota |
|------|---------|--------|----------------|------|
| `/consultor` | **Meu DAP** — meta comercial, agendamentos do dia, tarefas, pendências | 🟢 live | `/api/gestao/consultor/kpis`, `/api/agendamentos`, `/api/pendencias` | Toggle de tarefa só no estado local (sem persistência) |
| `/consultor/dashboard` | **Dashboard** — 4 KPIs + 4 áreas + mapa do pátio | 🟡 WIP | KPIs e PatioMap reais; grid de áreas estático | Hub visualmente completo, áreas clicáveis levam a stubs |
| `…/dashboard/operacional` | KPIs de pátio/OS | 🔵 stub | `<EmBreve>` | Rodada R15 |
| `…/dashboard/financeiro` | Faturamento vs meta | 🔵 stub | `<EmBreve>` | Rodada R16 |
| `…/dashboard/produtividade` | Ranking consultores/mecânicos | 🔵 stub | `<EmBreve>` | Rodada R17 |
| `…/dashboard/agenda` | Grade horária mecânicos | 🔵 stub | `<EmBreve>` | Rodada R18 |
| `/consultor/inbox` (+`/:id`) | **Inbox** multi-canal (WhatsApp/IG/email) | 🟢 live | `/api/conversations` (+ messages, mark-read) | Polling 10s; inbound ainda simulado por botão dev |
| `/consultor/conversas` | Histórico/busca de conversas | 🔵 stub | `<EmBreve>` | Separado do Inbox (histórico) |
| `/consultor/leads` | **Leads** — status, origem, veículo, score | 🟢 live | `/api/leads` | Sem filtros/busca na UI ainda |
| `/consultor/clientes` (+`/:id`) | **Clientes** — grid + ficha (veículos, OS, notas) | 🟢 live | `/api/customers`, `/api/vehicles`, `/api/service-orders` | Aba notas read-only; edição inline "próxima rodada" |
| `/consultor/propostas` | **Propostas** — itens, margem, converter em OS | 🟢 live | `/api/quotes`, `/api/quotes/:id/convert` | Conversão idempotente; painel de margem é calc local |
| `/consultor/aprovacoes` | Fluxo de aprovações | 🔵 stub | `<EmBreve>` | Fluxo a definir |
| `/consultor/agenda` | **Agenda** — calendário, agendamentos, cadastro inline | 🟢 live | `/api/agendamentos`, `/api/customers`, `/api/vehicles` | Totalmente integrado |
| `/consultor/os` | **OS abertas** — tabela paginada, filtros, tabs | 🟢 live | `/api/service-orders` (filtros em URL) | Paginação offset+limit |
| `/consultor/os/:id` | **Detalhe da OS** — status, itens, financeiro, checklist, timeline | 🟡 WIP | `/api/service-orders/:id` (+items, mutations) | Upload de fotos é placeholder (sem endpoint) |
| `/consultor/patio` | **Pátio Kanban** — 8 colunas drag-and-drop | 🟢 live | `/api/service-orders`, `/api/service-orders/:id/commercial-status` | `@dnd-kit`; validação client+server; revert em 409 |
| `/consultor/historico` | **Histórico de OS** — filtrado (entregue + trimestre) | 🟢 live | `/api/service-orders` (view=history) | Reusa 80% da lista |

**Gaps:** (1) 4 sub-páginas do dashboard são stubs (R15–R18); (2) upload de fotos/vídeo na OS;
(3) Conversas e Aprovações sem scaffolding de backend.

> Nota: existe **também** um mapa de pátio v2 (drag-drop de OS↔box, "Tirar do box") em
> `ConsultorDashboardPage` — entregue em 2026-06-05 (PRs #52/#53). Ver [[roadmap-portais]] p/ fatia 3.
