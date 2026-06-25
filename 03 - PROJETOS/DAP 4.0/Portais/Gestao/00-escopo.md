---
project: dap-gestao
status: scaffolding
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-operacao/README]]"
created: 2026-05-05
tags:
  - dap40
  - portal-gestao
  - p0
---

# DAP Gestão — Escopo executivo

## O que é

Portal **executivo** do ecossistema DAP. Não opera carro. Decide direção, alocação, prioridade. Vê o todo, não a OS individual.

## Audiência

| Persona             | Uso primário                                                       |
| ------------------- | ------------------------------------------------------------------ |
| Thales (chairman)   | Visão consolidada, OKRs, alocação de capital, decisões estratégicas |
| Diretor de unidade  | Performance da sua unidade vs metas, gargalos, ações corretivas    |
| CFO                 | DRE, fluxo de caixa, contas, projeções, margem por unidade         |
| Conselho            | Snapshot trimestral pra revisão de tese                            |

**NÃO é audiência:** consultor de oficina, técnico, recepção. Esses usam o dap-operacao.

## Diferença vs DAP Operação

| Eixo            | DAP Operação                              | DAP Gestão                                                     |
| --------------- | ----------------------------------------- | -------------------------------------------------------------- |
| Granularidade   | OS, cliente, agendamento individual       | Unidade, mês, trimestre, ano                                   |
| Tempo           | Hoje, esta semana                          | Mês corrente, ano, 5 anos                                     |
| Ações           | Mudar status, lançar item, agendar        | Aprovar budget, definir meta, decidir corte                   |
| Dados           | Lê/escreve no próprio SQLite local        | **Só lê** de múltiplas fontes (operação, P1, supabase, manual) |
| Frequência      | Continuamente durante o expediente        | Pontos do dia (manhã, fim de tarde) ou semanal                 |
| Decisão típica  | "Mudo OS-00042 pra aguardando_peca?"      | "Vou abrir DAP Mulher esse trimestre?"                         |

## Módulos (sidebar)

### 1. **Visão** (default landing)
   - Dashboard executivo: faturamento mês vs meta, OS abertas, NPS, conversão de orçamento
   - Heatmap de capacidade (9 elevadores × dia da semana)
   - Top 3 alertas do dia (gargalo, queda de KPI, decisão pendente)

### 2. **Unidades**
   - Cards das 12 unidades do ecossistema (status: ✅ operando | 🔧 estruturando | 🔮 futuro)
   - Drill-down por unidade: P&L, headcount, OKR, riscos, próximos marcos
   - Comparação cross-unidade (tabelona ranqueada)

### 3. **Financeiro consolidado**
   - DRE simplificado (receita, custo direto, margem bruta, despesas, lucro)
   - Fluxo de caixa (entradas/saídas projetadas 90 dias)
   - Contas a pagar / a receber (resumo, vencimentos)
   - Margem por unidade, por tipo de serviço, por consultor

### 4. **Pessoas**
   - Headcount por unidade
   - Custo total por pessoa (salário + encargos + bônus)
   - Capacidade vs demanda (OS/mecânico/mês)
   - Skills matrix (mecânicos × especialidades × níveis)

### 5. **Estratégia**
   - OKRs ativos (vincula unidade → objetivo → KR → progresso)
   - Decisões estratégicas (ADR-style, registro datado)
   - Pipeline de iniciativas (idea → planejado → em curso → entregue)
   - Roadmap de longo prazo (Q-by-Q)

### 6. **Comercial 360°** (agregado)
   - Funil consolidado (leads → orçamento → fechamento)
   - Taxa de conversão por canal (WhatsApp Bosch, WhatsApp Prime, indicação, walk-in)
   - LTV por tier (bronze/prata/ouro/platina)
   - Carteira ativa vs adormecida (%)

## Princípios arquiteturais

1. **Read-mostly** — Gestão *lê* dados; raramente escreve. Single source of truth fica no sistema operacional (Operação, Supabase, manual).
2. **Aggregator-pattern** — Cliente pra cada fonte (libsql remoto pro `oficina.db`, `@supabase/supabase-js` pro P1, fetcher manual pra planilhas).
3. **Cache agressivo** — Dados executivos não mudam minuto-a-minuto. TanStack Query staleTime de 5min pra views agregadas.
4. **Snapshot histórico** — Job diário grava snapshot dos KPIs pra trend lines (sem isso não dá pra ver "faturamento subiu este mês").
5. **Editorial dark-first** — Tipografia editorial, cinematográfico, sem template feel. Apple/Linear/Stripe references.
6. **Mesma stack do Operação** — Vite + Express 5 + TS + SQLite + Drizzle + shadcn/Radix. Familiaridade = velocidade.

## Stack

Idêntica ao dap-operacao com 2 adições:

- `@supabase/supabase-js` — pra ler do P1 (5911 leads, agentes IA)
- `node-cron` ou similar — pra job de snapshot diário

## Domínio futuro

`gestao.doctorautoprime40.com` (deploy mesmo padrão: VPS + Cloudflare Tunnel `dap4`).

## v0 (scaffold) — o que entra

- Login (mesmo padrão)
- Sidebar com 6 seções
- Dashboard executivo (placeholder editorial honesto)
- 5 sub-páginas (Unidades, Financeiro, Pessoas, Estratégia, Comercial 360°) — todas em WIP editorial
- Build verde, dev server rodando, sem mock data
- Testes setup (vitest)
- README, CLAUDE.md interno do projeto

## v1 (próxima) — o que NÃO entra agora

- Conexão real com SQLite remoto do Operação
- Conexão real com Supabase do P1
- Job de snapshot diário
- Gráficos com dados reais (Recharts)
- OKRs persistentes
- Auth multi-org (chairman pode trocar de tenant)

## Path local

`C:\THALES\DAP4\dap-gestao\`

Repo a criar: `toliveira1802-sketch/dap-gestao` (push depois do scaffold validar local).
