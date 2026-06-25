---
project: dap-operacao
status: production
url: https://operacao.doctorautoprime40.com
repo: https://github.com/toliveira1802-sketch/dap-operacao
master: bf31214
created: 2026-05-05
updated: 2026-05-05
tags:
  - dap40
  - portal-consultor
  - p0
---

# DAP Operação — Portal Consultor

Portal consultor da DAP Prime: gestão de OS, agenda, pátio, financeiro, comercial AI. Single-process Express + SPA Vite, **Postgres remoto (Supabase DOCTOR PRIME, schema `oficina`)**, deploy VPS via Cloudflare Tunnel.

## Status atual

```
URL público:    https://operacao.doctorautoprime40.com
Repo:           toliveira1802-sketch/dap-operacao @ master bf31214
VPS:            76.13.170.42  (Hostinger, P0 isolado)
Service:        dap-operacao.service (systemd, port 5001)
Tunnel:         Cloudflare dap4 → operacao.doctorautoprime40.com
DB:             Postgres 17 / Supabase DOCTOR PRIME / schema `oficina` (13 tabelas)
                URL: postgres://postgres:***@db.acuufrgoyjwzlyhopaus.supabase.co:5432/postgres
                Sessions: public.session (connect-pg-simple, mesmo cluster)
Login admin:    isDMNt2e32KYz4pBNVlQ  (rotacionar após primeiro uso)
```

> **Histórico de migração:** 2026-05-05 migrado de SQLite local → Postgres Supabase. Ver [[08-postgres-migration]].

## Mapa de docs

- [[03 - PROJETOS/DAP 4.0 1/dap-operacao/01-arquitetura]] — Stack, segurança, decisões técnicas, performance
- [[02-schema]] — Entidades, relacionamentos, status flow das OS (Postgres `oficina`)
- [[03-api]] — Todos os endpoints `/api/*` com auth e rate limits
- [[04-ui-pages]] — Páginas, componentes, roteamento, sidebar
- [[05-deploy-runbook]] — VPS, systemd, Cloudflare, comandos operacionais
- [[06-regras-negocio]] — Regras de negócio por página + role
- [[07-roadmap]] — 6 sprints priorizados pelo valor pro negócio
- [[08-postgres-migration]] — Changelog da migração SQLite → Postgres (2026-05-05)

## Premissas que guiaram o portal

- **World-class antes de mais nada** — segurança, performance, UX são restrições de design, não fases.
- **Single-process intencional** — oficina é uma unidade física, não precisa de cluster. Sessions em Postgres compartilhado (`public.session`) já são multi-instance ready quando precisar; data plane em schema `oficina` no mesmo Postgres.
- **SPA + API mesma origem** — zero CORS, zero CSP relaxation, cookie httpOnly+Secure+SameSite=Lax.
- **P0 isolado de P1** — `/opt/dap-operacao/` não compartilha nada com `/opt/doctor-auto-ai/` (legacy). Falha em um não afeta o outro.

## Roles

| Role       | Acesso                                                            |
| ---------- | ----------------------------------------------------------------- |
| `admin`    | Tudo (Operação + Financeiro + Comercial AI + Users + Mechanics)   |
| `tecnico`  | Operação (OS, Pátio, Agenda, Clientes)                            |
| `recepcao` | Operação + Comercial (Leads, Adormecidos)                         |

## Tech debt rastreado

- [ ] Lazy-load `service-order-detail` e `users-management` (~30KB economia na entry)
- [ ] Substituir `memorystore` por Redis quando virar multi-instance (1 linha)
- [ ] Cache headers `public, max-age=31536000, immutable` no Cloudflare pros chunks com hash
- [ ] Implementar módulos Comercial AI reais (CRM score, leads queue, adormecidos)
- [ ] Timeline v2: ler telemetry pra segmentar barra realizada por etapa real
- [ ] Endpoint agregado `/api/telemetry` (sem `:id`) pra timeline não fazer N+1
