---
tags: [todo, dap4, kpis, lead-command-center]
created: 2026-04-10
status: pendente
context: Spec do Lead Command Center precisa dos KPIs reais da operação ANTES da IA
---

# TODO: KPIs "Before" (operação manual) — Lead Command Center

Preciso dos números reais da Doctor Auto Prime/Bosch **antes** da IA entrar. Esses dados alimentam o painel Before/After do Lead Command Center.

## Dados necessários

- [ ] Tempo médio de resposta no WhatsApp (antes da IA) — ex: "4 horas"
- [ ] Quantos leads/dia chegavam em média
- [ ] Taxa de conversão lead → OS (ordem de serviço) — ex: "12%"
- [ ] Quantos leads ficavam sem resposta / perdidos por mês
- [ ] Tempo médio entre primeiro contato e agendamento
- [ ] Quantas conversas um atendente conseguia fazer por dia

## Por linha (se diferente)

- [ ] Doctor Auto Bosch: números separados?
- [ ] Doctor Auto Prime: números separados?

## Onde usar

- Painel **Before/After** do Lead Command Center (DAP4.0 dashboard)
- Baseline fixa gravada no Supabase (tabela `kpi_baseline` ou similar)
- "Depois" é calculado em tempo real a partir de `meta_messages` + `crm_leads`

## Se não tiver números exatos

Posso usar benchmarks do setor automotivo premium como placeholder e você ajusta depois. Mas números reais > benchmarks sempre.
