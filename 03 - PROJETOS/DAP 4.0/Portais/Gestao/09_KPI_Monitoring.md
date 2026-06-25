---
tags: [dap, ui, spec]
date: 2026-03-31
---
# 09 KPI Monitoring

> [!info] Objetivo do Módulo
> O "Master Control Room". É a tela onde a diretoria entende com clareza o fluxo da oficina atrelada ao fluxo de caixa, olhando de micro para macro.

## Requisitos de Interface Visual
- Header com Botão CTA Primário: "Exportar PDF" (Azul).
- **Semáforo de Macro KPIs:** 
  - Verde: 12 APROVADOS/NORMAIS.
  - Laranja: 5 ATENÇÃO/NOTIFICAÇÕES.
  - Vermelho: 2 EMERGÊNCIA.
- **Linhas Temáticas de Mini Cards de Indicadores (Muitos Dados em Layout Compacto):**
  - **Operacionais (Capacidade e Fluxo):** 4 KPIs pequenos + Gráfico duplo linha (Tendência Semanal). Inclui Ocupação do Pátio (78%), T.M Permanência (3,2 dias).
  - **Produtividade:** Homem/Hora Produtiva, Ordem Serv/Homem, Taxa Retrabalho (4,2%), Tempo Diagnóstico (45m).
  - **Qualidade:** NPS, Previsão (Desvio, etc).
  - **Financeiros:** T.M, Margem Bruta (42%), Evolução Mensal... e Box Grande com Gráfico dupla barra Mês a Mês.
  - **Comerciais/RH:** LTV/CAC, Conversão. Turnover, Treinamento.
- **Painel Vermelho de Ações Prioritárias:**
  - Checkboxes em vermelho/laranja ditando anomalias. Ex: "ATENÇÃO: Tempo de Resposta ao Cliente."
