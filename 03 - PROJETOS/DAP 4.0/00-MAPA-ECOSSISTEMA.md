---
title: DAP 4.0 — Mapa do Ecossistema
date: 2026-06-04
status: vigente
scope: mapa de domínios + árvore de unidades e portais
relacionado: "[[000-CANON]]"
---

# DAP 4.0 — Mapa do Ecossistema

> Capa de navegação. Detalhe canônico em [[000-CANON]]. Cada unidade/portal tem pasta própria.

## Arquitetura de domínios

`doctorautoprime40.com` = site institucional. Cada subdomínio encaminha pra um
portal/unidade. Portais operacionais = mesmo app `dap-aios` (1 banco, 1 login,
event log central); o subdomínio só fixa qual portal abre.

| Domínio | Aponta pra | Status |
|---|---|---|
| `doctorautoprime40.com` | Site institucional | 🔮 futuro |
| `consultor.doctorautoprime40.com` | Portal Consultor | ✅ agora |
| `gestao.doctorautoprime40.com` | Portal Gestão | 🔧 agora |
| `mecanico.doctorautoprime40.com` | Portal Mecânico | 🟡 agora |
| `cliente.doctorautoprime40.com` | Portal Cliente | 🔮 futuro |
| `aios.doctorautoprime40.com` | AIOS (orquestração/Sophia) | ✅ mantém |
| `ai.doctorautoprime40.com` | Dashboard dap4 (RAG/agentes) | 🔧 migrar da raiz |
| `performance.*` | DAP Performance | 🔮 futuro |
| `ensina.*` | DAP Ensina (Hotmart) | 🔮 futuro |
| `consultoria.*` | DAP Consultoria | 🔮 futuro |
| `project.* · studio.* · social.* · mulher.* · estetica.* · funilaria.*` | demais unidades | 🔮 futuro |

## Portais operacionais → Portais/

- Consultor · Gestao · Mecanico · Cliente

## Unidades de negócio → Ecossistema/

DAP-Prime · DAP-Performance · DAP-Project · DAP-AI · DAP-Dev · DAP-Studio ·
DAP-Social · DAP-Ensina · DAP-Consultoria · DAP-Mulher · DAP-Estetica · DAP-Funilaria

## Plataforma / IA

- **AIOS** (`aios.*`) — orquestração, Sophia, event log.
- **Dashboard dap4** (`ai.*`) — RAG, agentes (Ana, Kimi, Sophia, Thales, Insights).
