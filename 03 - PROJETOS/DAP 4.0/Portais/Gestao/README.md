---
project: dap-gestao
status: production
url: https://gestao.doctorautoprime40.com
repo: https://github.com/toliveira1802-sketch/dap-gestao
master: 8fb25a7
created: 2026-05-05
updated: 2026-05-05
tags:
  - dap40
  - portal-gestao
  - p0
---

# DAP Gestão — Portal Executivo

Portal **executivo** do ecossistema DAP. Não opera carro. Decide direção, alocação, prioridade. Sibling do [[03 - PROJETOS/DAP 4.0 1/dap-operacao/README|DAP Operação]] — mesma stack, audiência radicalmente diferente.

## Status atual

```
URL público:    https://gestao.doctorautoprime40.com
Path local:     C:\THALES\DAP4\dap-gestao\
Repo:           toliveira1802-sketch/dap-gestao  (privado) @ master 8fb25a7
VPS:            76.13.170.42  (mesmo VPS Hostinger do dap-operacao)
Service:        dap-gestao.service (systemd, port 5003)
Tunnel:         Cloudflare dap4 → gestao.doctorautoprime40.com
DB:             Postgres 17 / Supabase DOCTOR PRIME / schema `gestao` (5 tabelas)
                Acesso via @supabase/supabase-js + SUPABASE_SERVICE_ROLE_KEY (bypass RLS)
Login admin:    XKluH75r71TIA1jCDIEo7H  (rotacionar após primeiro uso)
```

## Mapa de docs

- [[00-escopo]] — Audiência, módulos, princípios arquiteturais, v0 vs v1
- [[03 - PROJETOS/DAP 4.0 1/dap-gestao/01-arquitetura]] — Stack, segurança, decisões técnicas
- [[02-deploy-runbook]] — VPS, systemd, Cloudflare, comandos operacionais

## Roles (4)

| Role        | Audiência                                                     |
| ----------- | ------------------------------------------------------------- |
| `admin`     | Administrador do portal (criação de users, config técnica)    |
| `chairman`  | Thales — visão consolidada, OKRs, decisões estratégicas       |
| `diretor`   | Diretor de unidade (Prime, Performance, etc) — sua unidade    |
| `cfo`       | Financeiro consolidado, DRE, fluxo de caixa, projeções        |

## Sidebar (6 módulos)

```
┌─────────────────────────┐
│  📊 DAP Gestão          │
├─────────────────────────┤
│  Visão                  │  todos
│  Unidades               │  todos
│  Financeiro Consolidado │  admin, chairman, cfo
│  Pessoas                │  admin, chairman, diretor
│  Estratégia             │  admin, chairman, diretor
│  Comercial 360°         │  todos
└─────────────────────────┘
```

## Demo seeds (dev only)

Em `NODE_ENV=development|test`, o boot cria 4 personas com senhas óbvias:

```
admin     / admin123      → role admin
chairman  / chairman123   → role chairman
diretor   / diretor123    → role diretor
cfo       / cfo123        → role cfo
```

Em **produção** (`NODE_ENV=production`), apenas 1 user `admin` é criado a partir de `BOOTSTRAP_ADMIN_PASSWORD` no `.env`. Senha atual em produção: `XKluH75r71TIA1jCDIEo7H` (rotacionar no primeiro acesso).

## Stack vs DAP Operação

Idêntica + **2 deps específicas pra Gestão**:
- `@supabase/supabase-js` — pra ler do P1 (5911 leads, agentes IA) [v1]
- `node-cron` + `@types/node-cron` — pra job de snapshot diário de KPIs [v1]

## Diferenças deliberadas vs Operação

1. **Schema mínimo no v0** — só `organizations` + `users`. Gestão **não escreve** OS, veículos, customers — esses dados vêm de fontes externas.
2. **Read-mostly architecture** — TanStack Query staleTime de 5min nas views agregadas (KPIs executivos não mudam minuto-a-minuto).
3. **Sem `@assets` alias** — não tem `attached_assets/` (Operação tem por motivo legacy).
4. **Sem cobertura mínima de testes** — superfície de negócio ainda é zero, threshold seria teatral.

## Páginas (8)

Todas em **WIP editorial honesto**: declaram o escopo, listam o que vão entregar, listam o que precisa ser conectado. Zero mock data.

| Arquivo                         | Rota              | O que faz                                                          |
| ------------------------------- | ----------------- | ------------------------------------------------------------------ |
| `pages/login.tsx`               | (sem layout)      | Login com org slug `dap-gestao` hardcoded                          |
| `pages/visao.tsx`               | `/`               | Overview dos 6 módulos + cards de entrada                          |
| `pages/unidades.tsx`            | `/unidades`       | 12 cards das unidades do ecossistema com status (operando/estruturando/futuro) |
| `pages/financeiro.tsx`          | `/financeiro`     | DRE consolidado, fluxo caixa, contas, margem por unidade           |
| `pages/pessoas.tsx`             | `/pessoas`        | Headcount, custo total, capacidade vs demanda, skills matrix       |
| `pages/estrategia.tsx`          | `/estrategia`     | OKRs, decisões (ADRs), pipeline iniciativas, roadmap Q-by-Q        |
| `pages/comercial-360.tsx`       | `/comercial-360`  | Funil consolidado, conversão por canal, LTV por tier               |
| `pages/not-found.tsx`           | (fallback)        | 404                                                                |

## Comandos

```bash
# Local dev (porta 5002)
cd C:\THALES\DAP4\dap-gestao
npm run dev

# Build prod
npm run build

# Migrations
npm run db:push -- --force

# Testes
npm run test
```

## Próximos passos (v1 — não entrou no scaffold)

- [ ] Conexão real com `oficina.db` do dap-operacao (libsql remoto) → KPIs reais
- [ ] Conexão real com Supabase do P1 → 5911 leads + telemetria de agentes
- [ ] Job `node-cron` de snapshot diário (tabela `kpi_snapshots`)
- [ ] OKR/ADR persistidos (schemas a modelar)
- [ ] Recharts com trend lines reais (depois dos snapshots)
- [ ] Theme dark-first cinematográfico (CLAUDE.md target)
- [ ] Multi-org auth (chairman troca de tenant — ex: ver Prime vs Performance)
- [ ] Deploy VPS (subdomínio `gestao.doctorautoprime40.com` no tunnel `dap4`, porta interna 5002)

## Tese arquitetural

**Aggregator-pattern**: Gestão **lê** dados; raramente escreve. Single source of truth fica nos sistemas operacionais (Operação SQLite, Supabase P1, manual). Vantagens:

1. Falha em Gestão **não derruba operação**.
2. Schema do Gestão é **derivado** — pode evoluir rápido sem migration de dado primário.
3. Snapshots históricos viram artefato de Gestão (ninguém precisa deles operacionalmente).
4. Quando vier multi-fonte (planilhas, ERPs externos), Gestão é o ponto natural de fan-in.
