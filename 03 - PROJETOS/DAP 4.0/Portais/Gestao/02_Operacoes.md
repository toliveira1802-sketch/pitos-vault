---
tags: [dap, ui, spec]
date: 2026-03-31
---
# 02 Operacoes

> [!info] Objetivo do Módulo
> Fluxo operacional de OS, pendentes, execução e finalizadas. Gráficos de barra empilhados e acompanhamento diário do fosso da oficina.

## Requisitos de Interface Visual
- **4 KPIs Superiores (Bordas Grossas Coloridas):**
  - **Azul:** 48 TOTAL OS.
  - **Laranja:** 12 PENDENTES.
  - **Roxo:** 18 EM EXECUÇÃO.
  - **Verde:** 15 CONCLUÍDOS.
  - **Vermelho:** 3 CANCELADOS.
- **Gráfico Principal:** 
  - Título: "Distribuição por Status".
  - Gráfico de Barras vertical (barras grossas): Laranja (Pendente), Roxo (Em Execução), Verde (Concluído), Vermelho (Cancelado).
- **Alertas Operacionais (Rodapé):**
  - Box de aviso Laranja ("Atenção"): 12 OS aguardando processamento.
  - Box de Alerta Vermelho ("Alto Volume"): 18 OS em execução simultânea.
