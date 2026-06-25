---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-operacao/README]]"
tags:
  - dap40
  - schema
  - db
---

# Schema (Postgres + Drizzle)

13 tabelas no schema **`oficina`** do projeto Supabase **DOCTOR PRIME** (`acuufrgoyjwzlyhopaus`, us-west-2, Postgres 17). Multi-tenant por `organization_id` em todas. FK constraints sempre on (default Postgres). RLS habilitado em todas as tabelas (server usa Postgres role direto, não passa por PostgREST → RLS é defense-in-depth).

> **Nota histórica:** até 2026-05-05 o schema era SQLite local (`oficina.db` na VPS). A migração SQLite → Postgres preservou tipos 1:1 (SERIAL ids, INTEGER cents, BOOLEAN flags, TEXT timestamps ISO). Ver [[08-postgres-migration]] pra detalhes da troca de stack.

## Coabitação no mesmo Postgres

```
DOCTOR PRIME (Supabase project acuufrgoyjwzlyhopaus, Postgres 17)
├── public/      P1 legacy (parliament_*, anna/kommo, leads, ordens_servico)
├── oficina/     dap-operacao (este portal — 13 tabelas)
├── gestao/      dap-gestao (executivo — 5 tabelas)
└── ferramentas/ dap-tools (diagnóstico — 6 tabelas)
```

Sessions (express-session via connect-pg-simple) ficam em `public.session` — tabela compartilhada pelo SO entre os portais (cada um isolado pela secret do cookie).

## Diagrama de relações

```
organizations (1) ──┬── users
                    ├── customers ─── vehicles (cliente:N veículos)
                    ├── mechanics
                    ├── service_orders ─┬── service_items (linhas)
                    │                   ├── service_order_comments (histórico)
                    │                   ├── service_order_attachments (fotos/vídeos)
                    │                   ├── checklists (entrada do veículo)
                    │                   ├── telemetry (mudanças de status)
                    │                   └── payments (faturamento)
                    └── appointments
```

OS é o coração: tem cliente, veículo, técnico, consultor, status atual + 6 sub-entidades (items, comments, attachments, checklist, telemetry, payments).

## Tabelas

### `organizations`
Tenant root. Default seed: `id=1, slug="dap-prime", name="DAP Prime"`.

| Campo       | Tipo     | Notas                  |
| ----------- | -------- | ---------------------- |
| id          | int PK   | auto-increment         |
| slug        | text UQ  | usado no login         |
| name        | text     |                        |
| created_at  | text     | ISO string             |

### `users`
| Campo            | Tipo    | Notas                                        |
| ---------------- | ------- | -------------------------------------------- |
| id               | int PK  |                                              |
| organization_id  | int FK  | cascade delete                               |
| username         | text    | unique por org                               |
| password         | text    | bcrypt hash (10 rounds)                      |
| name             | text    |                                              |
| role             | text    | `admin` \| `tecnico` \| `recepcao` (default) |

### `customers`
Tier do cliente (`bronze` → `prata` → `ouro` → `platina`) é o gancho pro segmentation comercial.

| Campo            | Tipo    | Notas                                       |
| ---------------- | ------- | ------------------------------------------- |
| id               | int PK  |                                             |
| organization_id  | int FK  |                                             |
| name             | text    |                                             |
| email            | text    | nullable                                    |
| phone            | text    | obrigatório (canal principal)               |
| cpf              | text    | nullable, indexed                           |
| notes            | text    | observações livres                          |
| tier             | text    | bronze \| prata \| ouro \| platina          |

### `vehicles`
| Campo            | Tipo    | Notas                                |
| ---------------- | ------- | ------------------------------------ |
| id               | int PK  |                                      |
| organization_id  | int FK  |                                      |
| customer_id      | int FK  | restrict (cliente não some com OS)   |
| plate            | text    |                                      |
| brand            | text    |                                      |
| model            | text    |                                      |
| year             | int     | nullable                             |
| color            | text    | nullable                             |
| vin              | text    | nullable (chassi)                    |
| km               | int     | nullable                             |

### `mechanics`
| Campo            | Tipo    | Notas                                                          |
| ---------------- | ------- | -------------------------------------------------------------- |
| id               | int PK  |                                                                |
| organization_id  | int FK  |                                                                |
| name             | text    |                                                                |
| specialty        | text    | nullable (motor, suspensão, elétrica, ECU…)                    |
| level            | text    | `junior` \| `pleno` (default) \| `senior` \| `especialista`    |
| phone            | text    | nullable                                                       |
| active           | int     | bool 0/1                                                       |

### `service_orders` ⭐ (entidade central)

| Campo               | Tipo    | Notas                                              |
| ------------------- | ------- | -------------------------------------------------- |
| id                  | int PK  | exibido como `OS-00001` via `formatOsNumber()`     |
| organization_id     | int FK  |                                                    |
| customer_id         | int FK  | restrict                                           |
| vehicle_id          | int FK  | restrict                                           |
| technician_id       | int FK? | nullable, set null on delete                       |
| consultant_id       | int FK? | nullable, set null on delete                       |
| status              | text    | (ver flow abaixo)                                  |
| reason              | text    | o que o cliente relatou                            |
| service_type        | text    | revisao \| remap \| diagnostico \| etc            |
| description         | text    | obrigatório                                        |
| diagnosis           | text    | preenchido depois do diag                          |
| diagnostic_notes    | text    |                                                    |
| estimated_cost      | int     | **cents**                                          |
| final_cost          | int     | **cents**                                          |
| advance_payment     | int     | **cents**                                          |
| created_at          | text    | ISO                                                |
| updated_at          | text    | ISO                                                |

#### Status flow (8 estados)

```
diagnostico ─── aguardando_aprovacao ─── aprovado ─── em_execucao ─┬─── pronto ─── entregue
                                                                    │
                                                                    └─── aguardando_peca (loop possível)

cancelado é terminal (saída de qualquer estado)
```

Pátio Kanban mostra 5 colunas: `diagnostico`, `em_execucao`, `aguardando_peca`, `pronto`, `entregue`.
Timeline Gantt usa duração heurística por etapa pra previsão (8h, 12h, 4h, 24h, 48h, 4h).

### `service_items` (linhas da OS)
| Campo            | Tipo    | Notas                                                  |
| ---------------- | ------- | ------------------------------------------------------ |
| id               | int PK  |                                                        |
| organization_id  | int FK  |                                                        |
| service_order_id | int FK  | cascade                                                |
| description      | text    |                                                        |
| quantity         | int     | default 1                                              |
| unit_price       | int     | **cents**                                              |
| cost             | int     | nullable, **cents** (custo interno pra calcular margem)|
| type             | text    | `servico` \| `peca` \| `mao_de_obra`                   |
| complexity       | text    | `baixo` \| `medio` (default) \| `alto`                 |
| status           | text    | `pendente` \| `aprovado` \| `recusado`                 |

### `service_order_comments`
Histórico de observações + mudanças de status.

| Campo            | Tipo    | Notas                                            |
| ---------------- | ------- | ------------------------------------------------ |
| id               | int PK  |                                                  |
| organization_id  | int FK  |                                                  |
| service_order_id | int FK  | cascade                                          |
| user_id          | int FK? | set null se user for deletado (preserva histórico) |
| text             | text    |                                                  |
| category         | text    | `observacao` (default) \| `status_change` \| `system` |
| created_at       | text    | ISO                                              |

### `service_order_attachments` (fotos/vídeos)
| Campo            | Tipo    | Notas                                       |
| ---------------- | ------- | ------------------------------------------- |
| id               | int PK  |                                             |
| organization_id  | int FK  |                                             |
| service_order_id | int FK  | cascade                                     |
| kind             | text    | `image` \| `video`                          |
| filename         | text    | nome no disco                               |
| url              | text    | `/uploads/<filename>`                       |
| size_bytes       | int     | nullable                                    |
| uploaded_by      | int FK? | set null                                    |
| created_at       | text    | ISO                                         |

### `appointments` (Agenda)
| Campo            | Tipo    | Notas                                       |
| ---------------- | ------- | ------------------------------------------- |
| id               | int PK  |                                             |
| organization_id  | int FK  |                                             |
| customer_id      | int FK  | cascade                                     |
| vehicle_id       | int FK? | set null                                    |
| mechanic_id      | int FK? | set null                                    |
| date             | text    | `YYYY-MM-DD`                                |
| time             | text    | `HH:MM`                                     |
| reason           | text    |                                             |
| status           | text    | default `agendado`                          |
| notes            | text    |                                             |

### `checklists` (entrada do veículo)
Preenchido pela recepção quando o carro entra. Bool flags pra proteções, KM/combustível/danos.

| Campo            | Tipo    | Notas                                              |
| ---------------- | ------- | -------------------------------------------------- |
| id               | int PK  |                                                    |
| organization_id  | int FK  |                                                    |
| service_order_id | int FK  | cascade                                            |
| mechanic_id      | int FK? |                                                    |
| seat_cover       | int     | bool 0/1 (capa de banco aplicada)                  |
| steering_cover   | int     | bool 0/1 (capa de volante)                         |
| floor_mat        | int     | bool 0/1 (tapete protetor)                         |
| fender_protector | int     | bool 0/1 (protetor de paralama)                    |
| entry_km         | int     | KM no momento da entrada                           |
| fuel_level       | text    | nullable (livre, ex: "1/4", "Reserva")             |
| damages          | text    | descrição livre de danos pré-existentes            |
| notes            | text    |                                                    |
| created_at       | text    |                                                    |

### `telemetry` (auditoria de status)
Linha por mudança de status. Base pra Timeline Gantt v2.

| Campo            | Tipo    | Notas                                       |
| ---------------- | ------- | ------------------------------------------- |
| id               | int PK  |                                             |
| organization_id  | int FK  |                                             |
| service_order_id | int FK  | cascade                                     |
| previous_status  | text    | nullable (primeira entrada não tem)         |
| new_status       | text    |                                             |
| changed_by       | int FK? | set null                                    |
| created_at       | text    | ISO                                         |

### `payments` (faturamento)
| Campo            | Tipo    | Notas                                       |
| ---------------- | ------- | ------------------------------------------- |
| id               | int PK  |                                             |
| organization_id  | int FK  |                                             |
| service_order_id | int FK  | cascade                                     |
| amount           | int     | **cents**                                   |
| method           | text    | livre (`pix`, `cartao_credito`, etc)        |
| status           | text    | default `pendente`                          |
| paid_at          | text    | ISO, nullable                               |
| notes            | text    |                                             |

## Helpers (`shared/schema.ts`)

```ts
formatOsNumber(id: number): string         // 42 → "OS-00042"
toCents(brl: string | number): number      // "1.234,56" → 123456
fromCents(cents: number): number           // 123456 → 1234.56
formatCentsBRL(cents: number): string      // 123456 → "R$ 1.234,56"
```

## Migrations

- Pasta `migrations/` (drizzle-kit output)
- Aplicar: `npm run db:push -- --force`
- Estado atual: `0000_dapper_toad.sql` (schema inicial completo)

## Indexação

Todas as tabelas têm `idx_<tabela>_organization_id`. Tabelas FK têm índices secundários no FK (ex: `idx_service_orders_customer_id`). Permite queries multi-tenant sem table scan.
