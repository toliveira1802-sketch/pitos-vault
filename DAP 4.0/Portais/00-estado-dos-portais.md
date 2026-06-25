---
tipo: doc-vivo
projeto: DAP4 / dap-aios
atualizado: 2026-06-05
fonte: extraído do código (branch main, commit 8b2f7ac)
tags: [dap4, portais, dap-aios, estado, roadmap]
---

# Estado dos Portais — DAP4 (dap-aios)

> Doc vivo. Estado **extraído do código real** do dap-aios (não de memória) em 2026-06-05.
> Legenda: 🟢 **live** (endpoint real + dados) · 🟡 **WIP** (parcial/condicional) ·
> ⚪ **mock** (hardcoded, sem backend) · 🔵 **stub** (placeholder "em breve").

Detalhe de cada portal: [[portal-consultor]] · [[portal-gestao]] · [[portal-mecanico]] ·
[[aios-sala-conselho]] · [[calculadoras-e-cliente]]. Roadmap: [[roadmap-portais]].

## Matriz de maturidade

| Portal | 🟢 Live | 🟡 WIP | ⚪ Mock | 🔵 Stub | Total | Leitura |
|--------|:---:|:---:|:---:|:---:|:---:|--------|
| **Mecânico** | 8 | 0 | 0 | 0 | 8 | Mais maduro — 100% live |
| **Consultor** | 12 | 2 | 0 | 5 | 19 | Núcleo operacional sólido; dashboard-detalhe e CRM pendentes |
| **AIOS / Conselho** | 7 | 3 | 0 | 0 | 10 | Estrutural live; execução de agente é canned (falta LLM real) |
| **Calculadoras** | 5 | 0 | 1 | 0 | 6 | Motores locais puros, funcionais |
| **Gestão** | 3+1 parcial | 0 | 3 | 2 | 9 | Comercial/Operação reais; Financeiro e Marketing-Ads mock |
| **Cliente** | 1 | 0 | 3 | 0 | 4 | Shell mobile mock (exemplo) |

## O que está realmente de pé hoje

- **Operação de oficina ponta a ponta** (Consultor + Mecânico): OS, Pátio, Clientes, Agenda,
  Inbox, Leads, Propostas, diagnóstico, checklist, state machine de status, atribuição de
  mecânico, estimativa de entrega — tudo **live** contra Postgres.
- **Gestão Comercial e Operação**: dashboards executivos reais (funil, consultores, propostas,
  canais, perdas, forecast, ranking) lendo `service_orders`/`leads`.
- **Calendário Editorial** (Marketing): único módulo de marketing com CRUD real.
- **AIOS estrutural**: mandala de agentes, demandas, RAG knowledge, Anna Shadow — live
  (execução LLM e P1 condicionais a flags).
- **Calculadoras**: pricing, margin, capacity, delivery — motores puros com audit log.

## Os 6 gaps que mais limitam hoje

1. **Dados reais no AIOS** — o banco AIOS está quase vazio; a operação real (48 OS, 5.911 leads)
   ainda vive no DOCTOR PRIME. Sem migrar, Pátio/Financeiro/Leads do AIOS ficam sem carga.
   *(É a alavanca que destrava vários portais de uma vez.)*
2. **Financeiro (Gestão)** — tela executiva completa (DRE, fluxo, contas) 100% mock; falta schema
   Postgres + endpoints.
3. **Marketing Ads** — backend Windsor **pronto** (fatia 1 mergeada hoje), mas front ainda lê mock
   e falta `USE_WINDSOR=true` + `WINDSOR_API_KEY` em prod. Gap puro de integração front→back.
4. **LLM real nos agentes AIOS** — execução de diretor retorna *canned response* (previsto p/ "Rodada 10").
5. **Dashboard-detalhe do Consultor** — 4 sub-páginas (operacional/financeiro/produtividade/agenda) são stubs.
6. **Upload de fotos/vídeo na OS** — dropzone é placeholder, sem endpoint.

## Provisionamento (nota operacional)

O acesso aos portais exige usuário em `public.users` do AIOS ligado a um `role`. Em 2026-06-05 a
tabela estava **vazia** → todo endpoint dava 403. Thales provisionado como `admin`. Consultores/
mecânicos reais ainda **não** provisionados (só o Thales).
