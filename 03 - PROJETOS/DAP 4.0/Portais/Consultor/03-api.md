---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-operacao/README]]"
tags:
  - dap40
  - api
  - endpoints
---

# API — `/api/*`

Total: **51 endpoints** em 16 módulos (`server/routes/*.ts`). Todas exceto `auth/login` e `auth/me` exigem sessão (`requireAuth`). Algumas (deletes/users management) exigem role admin.

## Convenções

- **Base URL prod**: `https://operacao.doctorautoprime40.com`
- **Auth**: cookie `connect.sid` (HttpOnly, Secure, SameSite=Lax, 24h)
- **Content-Type**: `application/json`
- **Money**: integer cents (`unit_price: 12345` = R$ 123,45)
- **Erros**:
  - `400` — Zod validation fail. Body: `{ message, issues: [{path, message}] }`
  - `401` — não autenticado. Body: `{ message: "Não autorizado" }`
  - `403` — role insuficiente. Body: `{ message: "Sem permissão" }`
  - `404` — recurso não existe (após hardening, inclui cross-tenant silencioso)
  - `500` — fallback. Body: `{ message }`

## Auth

| Método | Path                | Auth | Notas                                                                  |
| ------ | ------------------- | ---- | ---------------------------------------------------------------------- |
| POST   | `/api/auth/login`   | —    | Rate limit **5/min/IP**, `skipSuccessfulRequests: true`                |
| POST   | `/api/auth/logout`  | sess | Destroi sessão                                                         |
| GET    | `/api/auth/me`      | sess | Retorna `{ id, organizationId, username, name, role }` sem senha       |

```sh
# Login
curl -c jar -X POST https://operacao.doctorautoprime40.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"..."}'

# Identificado
curl -b jar https://operacao.doctorautoprime40.com/api/auth/me
```

## Customers

| Método | Path                              | Notas                                        |
| ------ | --------------------------------- | -------------------------------------------- |
| GET    | `/api/customers`                  | Lista do tenant atual                        |
| GET    | `/api/customers/:id`              |                                              |
| GET    | `/api/customers/:id/context`      | Cliente + veículos + OSs + agendamentos     |
| POST   | `/api/customers`                  |                                              |
| PATCH  | `/api/customers/:id`              | Partial update                               |
| DELETE | `/api/customers/:id`              | 404 se não existe (cross-tenant safe)        |

## Vehicles

| Método | Path                                  | Notas                                       |
| ------ | ------------------------------------- | ------------------------------------------- |
| GET    | `/api/vehicles`                       |                                             |
| GET    | `/api/vehicles/customer/:customerId`  | Veículos de um cliente                      |
| POST   | `/api/vehicles`                       |                                             |
| PATCH  | `/api/vehicles/:id`                   |                                             |
| DELETE | `/api/vehicles/:id`                   |                                             |

## Service Orders

| Método | Path                                       | Notas                                                |
| ------ | ------------------------------------------ | ---------------------------------------------------- |
| GET    | `/api/service-orders`                      |                                                      |
| GET    | `/api/service-orders/:id`                  |                                                      |
| GET    | `/api/service-orders/:id/full`             | OS + items + comments + attachments + checklist + telemetry + payments |
| POST   | `/api/service-orders`                      |                                                      |
| PATCH  | `/api/service-orders/:id`                  | Update geral (404 em unknown id após hardening)     |
| PATCH  | `/api/service-orders/:id/status`           | Mudança de status. Cria entrada em `telemetry` automaticamente |
| DELETE | `/api/service-orders/:id`                  |                                                      |
| GET    | `/api/service-orders/:id/pdf`              | PDF da OS (server-side render)                       |

### Sub-recursos da OS

| Método | Path                                              |
| ------ | ------------------------------------------------- |
| GET    | `/api/service-orders/:id/items`                   |
| POST   | `/api/service-orders/:id/items`                   |
| PATCH  | `/api/service-items/:id`                          |
| DELETE | `/api/service-items/:id`                          |
| GET    | `/api/service-orders/:id/comments`                |
| POST   | `/api/service-orders/:id/comments`                |
| GET    | `/api/service-orders/:id/attachments`             |
| DELETE | `/api/service-orders/attachments/:id`             |
| GET    | `/api/checklists/:serviceOrderId`                 |
| POST   | `/api/checklists`                                 |
| GET    | `/api/telemetry/:serviceOrderId`                  |

> **Observação**: upload de attachment é `POST /api/service-orders/:id/attachments` com `multipart/form-data` (campo `file`). Limite 15MB, MIME whitelist (`image/*` ou `video/mp4|webm`). Filename randomizado no disco.

## Mechanics

| Método | Path                       | Auth                                  |
| ------ | -------------------------- | ------------------------------------- |
| GET    | `/api/mechanics`           |                                       |
| POST   | `/api/mechanics`           |                                       |
| PATCH  | `/api/mechanics/:id`       |                                       |
| DELETE | `/api/mechanics/:id`       |                                       |

## Appointments (Agenda)

| Método | Path                          |
| ------ | ----------------------------- |
| GET    | `/api/appointments`           |
| POST   | `/api/appointments`           |
| PATCH  | `/api/appointments/:id`       |
| DELETE | `/api/appointments/:id`       |

## Payments (Financeiro)

| Método | Path                              | Notas                                        |
| ------ | --------------------------------- | -------------------------------------------- |
| GET    | `/api/payments`                   | Todos os pagamentos do tenant                |
| GET    | `/api/payments/:serviceOrderId`   | Pagamentos de uma OS específica              |
| POST   | `/api/payments`                   |                                              |
| PATCH  | `/api/payments/:id`               | 404 em unknown id (não retorna 200 vazio)    |

## Stats (Dashboard)

| Método | Path           | Notas                                                                |
| ------ | -------------- | -------------------------------------------------------------------- |
| GET    | `/api/stats`   | Agregados: OS por status, faturamento mês, top mecânicos, etc       |

## Users (admin only)

| Método | Path                  | Auth          |
| ------ | --------------------- | ------------- |
| GET    | `/api/users`          | requireAuth   |
| POST   | `/api/users`          | requireRole admin |
| DELETE | `/api/users/:id`      | requireRole admin |

> Apenas admin pode criar/deletar users. Senhas hasheadas com bcrypt (10 rounds) antes de gravar.

## Pattern de tenant safety

Toda query usa `req.session.organizationId` (extraído via `tenantId(req)`). Recursos que não pertencem ao tenant retornam **404** (não 403) — evita oracle de existência cross-tenant.

```ts
// Exemplo padrão (server/routes/*.ts):
const customer = await storage.getCustomer(id, tenantId(req));
if (!customer) return res.status(404).json({ message: "Não encontrado" });
```

## Validação (Zod)

Body de POST/PATCH valida com `insert<Entity>Schema` derivado de Drizzle:

```ts
const data = insertCustomerSchema.parse(req.body);
// ZodError → caught no error handler em server/index.ts → 400 com issues
```
