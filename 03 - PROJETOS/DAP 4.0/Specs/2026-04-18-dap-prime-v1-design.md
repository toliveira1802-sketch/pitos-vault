---
projeto: DAP Prime V1
tipo: design spec
data: 2026-04-18
autor: Thales (brainstorming com Claude Code)
status: draft — aguardando aprovação
---

# DAP Prime V1 — Design Spec

## Contexto do ecossistema

**DAP 4.0** é a holding. Contém 12 unidades de negócio. Hoje, `C:\dev\dap4` é o codebase da holding — abriga **AI, RAG, CRM, integrações Kommo/WhatsApp** e toda a infra. Permanece operando como está.

**Doctor Auto Prime** é a unidade filha focada em **manutenção de alemães premium**. Este spec cobre a **V1 do sistema de gestão operacional** dessa unidade — separado do `dap4`, mas compartilhando infraestrutura.

## Escopo V1

**Dentro:**
1. Cadastro de **clientes**
2. Cadastro de **veículos** (obrigatoriamente vinculados a um cliente)
3. Criação e gestão de **ordens de serviço**
4. **Kanban do pátio** (6 colunas)
5. **Agendamentos** (com conversão 1-clique para OS)
6. Backend completo (Supabase)

**Fora (backlog V2+):**
- Portal do cliente, app do mecânico (telas dedicadas, gamificação)
- Orçamento digital, checklist visual com silhueta, fotos na OS
- Módulos financeiros (DRE, fluxo, metas, faturamento, contas a pagar)
- CRM avançado, campanhas, lead scoring com IA
- Integrações externas (Kommo, WhatsApp, OBD/VCDS, Google Reviews)
- Multi-tenant real (V1 atende só a Prime; multi-empresa em V2)
- 5 agentes IA (Sophia/Simone/Raena/Carlos/João) — ficam no DAP 4.0 holding

## Arquitetura

```
┌─────────────────────────────────────────────────┐
│  FRONTEND  (Vercel)                              │
│  React 18 + Vite 7 + TypeScript + Tailwind      │
│  shadcn/ui · Wouter (hash) · TanStack Query v5 │
│  Framer Motion · Lucide · Zod · @dnd-kit        │
└─────────────────────────────────────────────────┘
                   ↓  HTTPS + PostgREST
┌─────────────────────────────────────────────────┐
│  SUPABASE (compartilhado com DAP 4.0 holding)   │
│  ├─ schema  prime.*    → dados da Prime         │
│  ├─ schema  public.*   → holding (dap4 atual)   │
│  ├─ Auth nativa (email/senha)                   │
│  ├─ PostgREST (CRUD direto do front)            │
│  └─ RLS habilitada em todas as tabelas          │
└─────────────────────────────────────────────────┘
```

**Repo:** novo — `dap-prime` — separado de `dap4`.
**Deploy:** Vercel (front) + Supabase (back). Sem Docker, sem gateway, sem middleware Node.
**Auth:** Supabase Auth. V1 = role único (`consultor`/`admin` são a mesma coisa).
**ORM:** nenhum. `@supabase/supabase-js` direto. Schema em SQL puro (migrations versionadas).

## Stack

| Camada | Tecnologia | Razão |
|--------|-----------|-------|
| Frontend | React 18 + Vite 7 + TS | Mesmo do `dap4` — consistência no ecossistema |
| Styling | Tailwind v3 + shadcn/ui | Mesmo do `dap4` |
| Routing | Wouter (hash) | Deploy simples em qualquer host |
| Data fetching | TanStack Query v5 | Cache + revalidação + mutations |
| Validação | Zod | Client-side antes de submit |
| Drag-drop | @dnd-kit/core | Kanban acessível, sem dependência morta |
| Animation | Framer Motion | Transições Kanban + micro-interações |
| Icons | Lucide React | Padrão shadcn |
| Backend | Supabase Postgres + Auth + PostgREST | CRUDs triviais, sem middleware |
| Unit tests | Vitest | Padrão Vite |
| E2E | Playwright | Padrão do ecossistema |
| Deploy | Vercel (front) + Supabase managed | Zero infra custom |

## Schema (5 tabelas no schema `prime`)

```sql
create schema if not exists prime;

-- 1. CLIENTES
create table prime.clientes (
  id          uuid primary key default gen_random_uuid(),
  nome        text not null,
  cpf         text unique,
  telefone    text not null,
  email       text,
  endereco    text,
  cidade      text,
  estado      text,
  cep         text,
  observacoes text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 2. VEICULOS (FK cliente obrigatória: sem cliente não tem veículo)
create table prime.veiculos (
  id           uuid primary key default gen_random_uuid(),
  cliente_id   uuid not null references prime.clientes(id) on delete cascade,
  placa        text not null unique,
  marca        text not null,
  modelo       text not null,
  ano          int,
  cor          text,
  combustivel  text,
  km_atual     int,
  observacoes  text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- 3. STATUS KANBAN (enum)
create type prime.os_status as enum (
  'recepcao',
  'diagnostico',
  'aguardando_aprovacao',
  'em_execucao',
  'pronto',
  'entregue'
);

-- 4. ORDENS DE SERVIÇO
create table prime.ordens_servico (
  id           uuid primary key default gen_random_uuid(),
  numero_os    bigserial unique not null,
  veiculo_id   uuid not null references prime.veiculos(id) on delete restrict,
  cliente_id   uuid not null references prime.clientes(id) on delete restrict,
  status       prime.os_status not null default 'recepcao',
  motivo       text not null,
  diagnostico  text,
  valor_total  numeric(10,2) default 0,
  km_entrada   int,
  data_entrada timestamptz not null default now(),
  data_saida   timestamptz,
  observacoes  text,
  created_by   uuid references auth.users(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- 5. AGENDAMENTOS
create table prime.agendamentos (
  id          uuid primary key default gen_random_uuid(),
  cliente_id  uuid not null references prime.clientes(id) on delete cascade,
  veiculo_id  uuid not null references prime.veiculos(id) on delete cascade,
  data_hora   timestamptz not null,
  motivo      text not null,
  observacoes text,
  os_id       uuid references prime.ordens_servico(id),
  created_by  uuid references auth.users(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Índices
create index idx_veiculos_cliente     on prime.veiculos(cliente_id);
create index idx_os_veiculo           on prime.ordens_servico(veiculo_id);
create index idx_os_status            on prime.ordens_servico(status);
create index idx_os_data_entrada_desc on prime.ordens_servico(data_entrada desc);
create index idx_agend_data_hora      on prime.agendamentos(data_hora);
create index idx_agend_cliente        on prime.agendamentos(cliente_id);

-- Trigger updated_at (extension moddatetime do Supabase)
create extension if not exists moddatetime;
create trigger t_clientes_ua       before update on prime.clientes       for each row execute function moddatetime(updated_at);
create trigger t_veiculos_ua       before update on prime.veiculos       for each row execute function moddatetime(updated_at);
create trigger t_ordens_servico_ua before update on prime.ordens_servico for each row execute function moddatetime(updated_at);
create trigger t_agendamentos_ua   before update on prime.agendamentos   for each row execute function moddatetime(updated_at);

-- RLS — V1: role único, usuário autenticado tem acesso total
alter table prime.clientes        enable row level security;
alter table prime.veiculos        enable row level security;
alter table prime.ordens_servico  enable row level security;
alter table prime.agendamentos    enable row level security;

create policy "auth_all" on prime.clientes       for all using (auth.role() = 'authenticated');
create policy "auth_all" on prime.veiculos       for all using (auth.role() = 'authenticated');
create policy "auth_all" on prime.ordens_servico for all using (auth.role() = 'authenticated');
create policy "auth_all" on prime.agendamentos   for all using (auth.role() = 'authenticated');
```

**Decisões de schema:**
- `cliente_id` duplicado em `ordens_servico` (derivável via veículo) → evita JOIN em toda listagem.
- Status Kanban = enum Postgres com 6 valores. Adicionar coluna extra = 1 migration trivial no futuro.
- `agendamentos.os_id` nullable → quando preenchido, indica agendamento já convertido em OS.
- `bigserial` em `numero_os` → numeração sequencial humana independente do UUID.
- Sem `os_itens`, `os_historico`, `mecanicos`, `empresas`, `colaboradores`, `crm`, `faturamento` — V1 não precisa.
- RLS habilitada desde o início, policy única — prepara pra multi-role sem refactor.

## Páginas (13 rotas V1)

| Rota | Tela | Objetivo |
|------|------|----------|
| `/login` | Login Supabase | Autenticação |
| `/` | Dashboard | OS ativas, agendamentos do dia, atalhos |
| `/clientes` | Lista + busca | CRUD clientes |
| `/clientes/novo` | Form cadastro | Novo cliente |
| `/clientes/:id` | Detalhes | Veículos + histórico OS |
| `/veiculos/novo` | Form cadastro | Requer `cliente_id` |
| `/veiculos/:id` | Detalhes | Histórico OS do veículo |
| `/os` | Lista | Filtros por status/data/cliente |
| `/os/nova` | Form criação | Seleção de veículo existente |
| `/os/:id` | Detalhes OS | Edição + timeline |
| `/patio` | **Kanban** | 6 colunas drag-drop |
| `/agendamentos` | Calendário | Visão mensal/semanal |
| `/agendamentos/novo` | Form | Novo agendamento |

## Data flow — 5 fluxos críticos

**1. Cadastro cliente + veículo:**
```
Form cliente → insert prime.clientes
   → redirect /clientes/:id
     → botão "+ Veículo" → form com cliente_id pré-preenchido
       → insert prime.veiculos
```

**2. Nova OS (walk-in):**
```
Busca por placa na home
  → se existe: /os/nova?veiculo_id=X
  → se não: cadastra cliente → cadastra veículo → /os/nova?veiculo_id=X
    → insert prime.ordens_servico (status=recepcao)
      → card aparece na coluna Recepção do Kanban
```

**3. Nova OS (via agendamento):**
```
Dashboard mostra "agendados hoje"
  → card com botão "Converter em OS"
    → transaction: insert ordens_servico + update agendamentos set os_id = new_id
      → card no Kanban + agendamento marcado como convertido
```

**4. Kanban drag-drop:**
```
Drag card de "diagnostico" → "em_execucao"
  → update prime.ordens_servico set status = 'em_execucao'
  → optimistic UI (TanStack Query mutation), rollback em erro
  → quando soltar em "entregue": modal pede data_saida → confirma → atualiza
```

**5. Agendamento:**
```
Calendário → clique em slot → form (cliente, veículo, motivo)
  → insert prime.agendamentos
  → aparece no calendário + no Dashboard se for hoje
```

## Error handling

- **Client-side:** Zod valida antes de submit → erros inline no form.
- **Server-side:** constraints SQL (NOT NULL, UNIQUE, FK) são a fonte da verdade. Erros do PostgREST já chegam tipados ao front.
- **Feedback:** toast via `sonner` para sucesso/erro. TanStack Query `onError` centraliza.
- **Rollback:** mutations otimistas no Kanban revertem em falha.
- **Auth expirada:** Supabase client emite evento → redirect `/login` automático.
- **Logs de erro:** `console.error` + opcional Sentry (V2).

## Testing

**Unit (Vitest):** funções utilitárias (formatação placa, CPF, datas), validadores Zod, componentes isolados (CardCliente, CardOS, KanbanColumn).
**Meta:** 80% coverage em `src/lib/**` e `src/components/**`.

**E2E (Playwright):** 5 golden paths:
1. Login → redireciona ao dashboard
2. Cadastrar cliente → cadastrar veículo → aparece em `/clientes/:id`
3. Criar OS de walk-in → aparece em Recepção → mover até Entregue
4. Criar agendamento → converter em OS → ver no Kanban
5. Buscar veículo por placa → abrir detalhes → ver histórico OS

## Plano de execução (swarm) — input pra writing-plans

```
Agent 0 (gate sequencial):
  - Repo init: dap-prime, pnpm, Vite 7 + React 18 + TS + Tailwind + shadcn
  - .env.example, README mínimo
  - Migration 001_prime_schema.sql (todas as 5 tabelas + enum + triggers + RLS)
  - Seed mínimo (3 clientes + 5 veículos + 2 OS + 2 agendamentos)
  - Rotas base (layout, auth guard, Wouter)
  - Client Supabase configurado

Agent 1 (paralelo) — Clientes + Veículos:
  - /clientes, /clientes/novo, /clientes/:id
  - /veiculos/novo, /veiculos/:id
  - hooks: useClientes, useVeiculos
  - components: ClienteCard, VeiculoCard, ClienteForm, VeiculoForm
  - testes unit + 1 e2e (fluxo cadastro)

Agent 2 (paralelo) — OS + Kanban:
  - /os, /os/nova, /os/:id, /patio
  - hooks: useOrdensServico, useUpdateOsStatus
  - components: OsCard, KanbanBoard, KanbanColumn (dnd-kit)
  - testes unit + 2 e2e (criar OS, mover no Kanban)

Agent 3 (paralelo) — Agendamentos:
  - /agendamentos, /agendamentos/novo
  - hook: useAgendamentos, useConvertAgendamentoOs
  - components: CalendarView, AgendamentoForm, ConvertOsButton
  - testes unit + 1 e2e (criar agendamento → converter)

Agent 4 (gate sequencial):
  - Dashboard home (merge dos dados dos 3 agentes)
  - E2E suite completa Playwright
  - Polish UI (dark mode, loading states, empty states)
  - Deploy Vercel + smoke test em preview
  - README final + docs de deploy
```

**Coordenação:** Agent 0 trava o schema. Depois Agents 1-3 rodam em worktrees git separados. Agent 4 faz merge e finaliza.

## Métricas de sucesso V1

| Métrica | Target |
|---------|--------|
| Tempo de cadastro cliente+veículo | < 2 min |
| Kanban responsivo com 100 OS ativas | sem lag perceptível |
| Zero erros 500 em 1h de uso real | ✅ |
| 5 golden paths E2E verdes | ✅ |
| Coverage unit | ≥ 80% nos módulos críticos |
| Deploy funcional em produção | Vercel + Supabase end-to-end |

## Aberto pra V2

- Multi-empresa (`empresa_id` ou schema próprio por unidade).
- Integração Prime ↔ DAP40 holding (consumir Ana/Kimi/Sofia como API).
- Domínio próprio (ex: `prime.doctorautoprime.com.br`) com Cloudflare.
- Portal do cliente.
- App mecânico (mobile PWA).
- Orçamento digital com aprovação WhatsApp.
- Financeiro completo.
