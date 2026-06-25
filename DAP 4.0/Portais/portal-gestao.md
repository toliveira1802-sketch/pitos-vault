---
tipo: doc-vivo
projeto: DAP4 / dap-aios
atualizado: 2026-06-05
fonte: extraído do código (branch main)
tags: [dap4, portais, gestao, marketing]
---

# Portal Gestão (+ Marketing)

> Voltar ao [[00-estado-dos-portais|índice]]. 3 live (+1 parcial) · 3 mock · 2 stub.
> Visão executiva da operação. Comercial/Operação são reais; Financeiro e Marketing-Ads são mock.

| Rota | Feature | Status | Fonte de dados | Nota |
|------|---------|--------|----------------|------|
| `/gestao/dashboard` | Hub executivo — 7 cards temáticos | 🟡 parcial | Comercial e Operação reais; Financeiro/Tech/Melhorias/RH/Roadmap hardcoded | 5 cards com `live:false`, valores literais, pill "Em breve" |
| `/gestao/comercial` | Resumo, Funil, Consultores, Propostas, Canais, Perdas, Forecast, Alertas | 🟢 live | 8 endpoints `/api/gestao/comercial/*` | Backend completo; lê `service_orders`/`leads`; refetch 30–60s |
| `/gestao/operacao` | 4 KPIs, distribuições, ranking consultores/mecânicos | 🟢 live | `/api/gestao/operacao/dashboard` | Agrega server-side; filtro por consultor |
| `/gestao/financeiro` | Meta, DRE, fluxo de caixa, faturamento 6m, contas | ⚪ mock | `financeiro/data.ts` (hardcoded) | Sem schema financeiro no Postgres; PeriodPicker não reage |
| `/gestao/marketing` | Dashboard de ads — KPIs, split Google×Meta, top campanhas | ⚪ mock | `marketing/data.ts` | **Backend `/api/marketing/campaigns` existe** (Windsor), mas front lê mock |
| `/gestao/marketing/campanhas` | Tabela de campanhas com filtro por plataforma | ⚪ mock | `marketing/data.ts` | Filtro client-side; backend pronto, front desacoplado |
| `/gestao/marketing/calendario` | Calendário editorial — CRUD de conteúdo | 🟢 live | `/api/marketing/calendar` | **Único módulo de marketing real** (CRUD Postgres) |
| `/gestao/marketing/equipe` | Membros do time | 🔵 stub | `<EmBreve>` | — |
| `/gestao/marketing/atividade` | Feed de atividade | 🔵 stub | `<EmBreve>` | — |

## Marketing / Windsor — estado preciso (importante)

O backend de ads está **implementado e mergeado** (PR #54, 2026-06-05): `windsorClient.ts` +
`marketingAdsService.ts` (normalização, agregação por campanha, cache 10min, fallback mock) +
`GET /api/marketing/campaigns` e `/summary`, gated por flag `USE_WINDSOR`. O conector
**Google Ads já está conectado** na conta do Thales (2 contas DAP reais).

**Falta pra virar real:** (1) `USE_WINDSOR=true` + `WINDSOR_API_KEY` no `.env` de prod;
(2) trocar no front o `import CAMPAIGNS` por `useMarketingCampaigns()` (fatia 2); (3) conectar Meta
Ads (`facebook`) no Windsor; (4) configurar valor de conversão no Google Ads (ROAS hoje vem 0 numa conta).

**Gaps:** Financeiro (mock estrutural, precisa schema), Marketing-Ads (integração front→back), 5 cards do hub decorativos.
