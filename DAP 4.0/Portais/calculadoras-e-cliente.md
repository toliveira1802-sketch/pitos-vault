---
tipo: doc-vivo
projeto: DAP4 / dap-aios
atualizado: 2026-06-05
fonte: extraído do código (branch main)
tags: [dap4, portais, calculadoras, cliente]
---

# Calculadoras & Portal Cliente

> Voltar ao [[00-estado-dos-portais|índice]].

## Calculadoras — 5 live · 1 sem UI

Motores reutilizáveis, **lógica local pura** (funções com Zod I/O + audit log em `calculator_runs`).
Zero dependência externa.

| Rota | Feature | Status | Nota |
|------|---------|--------|------|
| `/calculadoras` | Home — grid de calculadoras | 🟢 live | `/api/calculators`; mostra versão, se tem UI |
| `/calculadoras/pricing` | Precificação | 🟢 live | `…/pricing/run` |
| `/calculadoras/margin` | Margem | 🟢 live | `…/margin/run` |
| `/calculadoras/capacity` | Capacidade | 🟢 live | preset: 9 elevadores, 4 mecânicos, 8h, 50 OS, 4h/OS |
| labor | Mão de obra | ⚪ API-only | sem playground dedicado |
| delivery_estimate | Estimativa de entrega | 🟢 live | sem página própria — consumido na OS do Mecânico |

## Portal Cliente — 1 live · 3 mock

Shell mobile-first (topbar + bottom-tab), **exemplo** a partir do mock do Thales (2026-06-04).

| Rota | Feature | Status | Nota |
|------|---------|--------|------|
| `/cliente` | Saudação com nome do usuário | 🟢 live | `useMe()` |
| `/cliente` | Atalhos (veículos/lembretes/promoções) | ⚪ mock | subtítulos fixos, botões não navegam |
| `/cliente` | Tiles de redes sociais | ⚪ mock | sem href real |
| `/cliente` | Destaque "OS Ultimate Demo" | ⚪ mock | botão sem ação |

**Gaps Cliente:** é só shell. Rotas filhas (meus veículos, OS do cliente, lembretes, promoções)
ainda não existem. Decisão pendente: o Portal Cliente é prioridade ou fica para depois da operação interna?
