---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-operacao/README]]"
date: 2026-05-05
tags:
  - dap40
  - migration
  - postgres
  - changelog
---

# Migração SQLite → Postgres (2026-05-05)

> Mudança de stack do data plane do dap-operacao: de SQLite local na VPS pra Postgres Supabase remoto, schema `oficina` no projeto **DOCTOR PRIME** (`acuufrgoyjwzlyhopaus`). Sessions também migraram (memorystore → connect-pg-simple no schema `public.session`). Todas as 13 tabelas portadas 1:1 com tipos preservados (SERIAL, INTEGER, BOOLEAN, TEXT pra timestamps).

## Por que migramos

1. **Single source of truth do ecossistema.** O Postgres DOCTOR PRIME já hospeda dados reais de produção do P1 (parliament_*, anna/kommo, leads, ordens_servico legacy, vehicles legacy). Manter o portal consultor em SQLite isolado significava ter um silo paralelo — dados de OS num lugar, leads do Kommo no outro, sem joins possíveis.
2. **Preparar Comercial AI v1.** O roadmap (Sprint 3) exige que o portal cruze leads do Kommo (P1) com OS abertas (Operação) pra computar score de CRM, fila de "leads pra ligar" e adormecidos. Cross-DB é caro; cross-schema é trivial.
3. **Convergência com dap-gestao.** O portal executivo (sibling) também ficou no schema `gestao` do mesmo Postgres. Sprint futuro: Gestão lê de `oficina.service_orders` JOIN `public.campaign_leads` num único Postgres, com `EXPLAIN`.
4. **Backup, monitoring, billing unificados.** PITR built-in do Supabase em vez de cron rsync caseiro do `oficina.db`.

## Decisão arquitetural pendente que mudou de rumo durante o dia

Inicialmente o plano foi colocar `oficina` no projeto **DAP4.0** (sandbox) pra "isolar blast radius". Após auditoria descobrimos que:

- DAP4.0 estava **vazio em produção** (sem dados reais).
- DOCTOR PRIME já tinha 25 tabelas em `public` com dados ativos do P1.
- "Isolamento de blast radius" virou teatro arquitetural sem propósito — schema isolation em Postgres já garante que migrations de `oficina` não tocam `public`.
- Cross-schema joins ficariam impossíveis em projetos separados (FDW ou app-level fetch).

**Resultado da auditoria:** Mover tudo (oficina + gestao) pra DOCTOR PRIME. DAP4.0 retirado pra sandbox. Hoje: `public/oficina/gestao/ferramentas` coexistem isolados por namespace, joinable por `JOIN`.

## O que mudou no código

### Server (`server/storage.ts`, `server/routes/index.ts`)

```diff
- import { drizzle } from "drizzle-orm/libsql";
- import { createClient } from "@libsql/client";
+ import { drizzle } from "drizzle-orm/postgres-js";
+ import postgres from "postgres";

- const client = createClient({ url: process.env.DATABASE_URL || "file:./oficina.db" });
+ const client = postgres(databaseUrl, { prepare: false, max: Number(process.env.DATABASE_POOL_MAX ?? 10) });

- await client.execute("PRAGMA foreign_keys = ON");  // SQLite-only
+ // Postgres FKs always on
```

```diff
- // memorystore — single-process, leaks long-running
- const MemoryStore = createMemoryStore(session);
- const sessionStore = new MemoryStore({ checkPeriod: 60 * 60 * 1000 });

+ // connect-pg-simple — Postgres-backed, multi-instance-ready
+ const sessionPool = new Pool({
+   connectionString: databaseUrl,
+   max: Number(process.env.SESSION_POOL_MAX ?? 5),
+   ssl: { rejectUnauthorized: false }, // see hotfix below
+ });
+ const sessionStore = new (connectPgSimple(session))({
+   pool: sessionPool,
+   tableName: "session",
+   schemaName: "public",
+   createTableIfMissing: true,
+   pruneSessionInterval: 60 * 60,
+ });
```

### Schema (`shared/schema.ts`)

Mantido 1:1 com SQLite original — só trocamos o builder do Drizzle:

```diff
- import { sqliteTable, integer, text } from "drizzle-orm/sqlite-core";
+ import { pgSchema, serial, integer, text, boolean } from "drizzle-orm/pg-core";

- export const organizations = sqliteTable("organizations", { ... });
+ export const oficina = pgSchema("oficina");
+ export const organizations = oficina.table("organizations", { ... });
```

Tipos preservados deliberadamente pra reduzir blast radius:
- `id` `SERIAL` (não BIGSERIAL) → continuity dos IDs JS-safe (< 2^53)
- `unit_price`, `final_cost` etc → `INTEGER` cents (não BIGINT) — futureproof até R$21M por valor
- Bool flags do checklist → `BOOLEAN` (era SMALLINT 0/1 no SQLite) — drizzle aceita ambos no insert
- Timestamps → `TEXT` ISO (não TIMESTAMPTZ) — evita re-escrever todos os call sites do app que fazem `new Date().toISOString()`

> **Follow-up phase 2:** migrar timestamps pra `TIMESTAMPTZ` quando o app estabilizar.

### Deps (`package.json`)

```diff
- "@libsql/client": "^0.17.2",
- "drizzle-orm": "^0.39.3",  → mantido (mesmo Drizzle, dialect pg-core)
+ "pg": "^8.13.1",
+ "@types/pg": "^8.11.10",
+ "postgres": "^3.4.5",
+ "connect-pg-simple": "^9.0.1",
+ "@types/connect-pg-simple": "^7.0.3",
- "memorystore": "^1.6.7"  → removido
```

### Build (`script/build.ts`)

esbuild allowlist atualizada pra incluir `pg`, `postgres`, `connect-pg-simple`. Tirou `@libsql/client`, `memorystore`.

### Tests (`tests/helpers/db.ts`)

- SQLite tmp-file → Postgres Docker local (`localhost:5433`, schema `oficina_test`)
- Cross-fork safety: advisory lock 91827364554 garante 1 fork roda DROP+CREATE+migrate
- SAFETY guard: hard-fail se `DATABASE_URL` apontar pra `acuufrgoyjwzlyhopaus` ou qualquer host `*.supabase.co/com` — testes nunca rodam contra prod

Vitest config: `fileParallelism: false` pra evitar interferência entre forks no mesmo schema.

## Hotfixes aplicados durante o deploy

### 1. `connect-pg-simple` SSL rejection
**Sintoma:** Login retornava 200 mas `/api/auth/me` subsequente retornava 500 com `SELF_SIGNED_CERT_IN_CHAIN`.

**Causa:** node-postgres (versão atual) trata `sslmode=require` no URL como `verify-full` — mas o cert chain do Supabase é assinado pela CA do AWS-RDS, que não está no truststore default do Node.

**Fix** (`server/routes/index.ts`):
```ts
const sessionPool = new Pool({
  connectionString: databaseUrl,
  ssl: { rejectUnauthorized: false }, // TLS sim, peer-verify não
});
```
+ remover `sslmode=require` do URL (senão sobrepõe o `ssl` do Pool config).

### 2. Vendor circular chunk
**Sintoma:** `vendor-react Uncaught TypeError: Cannot set properties of undefined (setting 'Children')` no browser.

**Causa:** `manualChunks` em formato função estava produzindo dep cíclica `vendor → vendor-react → vendor` (libs em `vendor` precisavam de `react-is`/`scheduler` que estavam em `vendor-react`).

**Fix** (`vite.config.ts`): troca pra formato objeto, declarando entry points explícitos:
```ts
manualChunks: {
  "vendor-react": ["react", "react-dom", "wouter"],
  "vendor-radix": ["@radix-ui/react-dialog", ...],
  "vendor-forms": ["react-hook-form", "@hookform/resolvers", "zod"],
  "vendor-tanstack": ["@tanstack/react-query"],
}
```

### 3. CSP block do Cloudflare beacon
**Sintoma:** `Loading the script 'https://static.cloudflareinsights.com/beacon.min.js' violates ... script-src 'self'`.

**Causa:** Cloudflare Web Analytics injeta automaticamente `beacon.min.js` quando feature está ativa. Nosso CSP `script-src 'self'` bloqueava.

**Fix** (`server/index.ts`):
```diff
- scriptSrc: ["'self'"],
+ scriptSrc: ["'self'", "https://static.cloudflareinsights.com"],
```

## Sequência operacional do deploy (cronologia)

1. ⬢ Apply migration `oficina_schema_init` no DOCTOR PRIME — 13 tabelas
2. ⬢ Reset password Postgres DOCTOR PRIME → `Dpctrauto1234` (temporária)
3. ⬢ Update `.env.example` apontando DOCTOR PRIME direct connection (port 5432)
4. ⬢ Merge `feat/postgres-migration` → `master` local
5. ⬢ Push `origin master` (commits `506d28d` merge + 10 commits da branch)
6. ⬢ SSH VPS — backup `oficina.db` SQLite + `.env` + commit hash anterior (rollback)
7. ⬢ `git pull` + `npm ci` + `npm run build` na VPS
8. ⬢ Atualizar `/opt/dap-operacao/.env` com `DATABASE_URL` Postgres
9. ⬢ `systemctl restart dap-operacao` — service vira pra Postgres
10. ⬢ Limpar `oficina.users` + `oficina.organizations` (boot anterior em dev tinha seedado 3 personas com senhas óbvias) → re-seedar via `BOOTSTRAP_ADMIN_PASSWORD` em `NODE_ENV=production`
11. ⬢ Push hotfix vendor+CSP (`bf31214`) → VPS pull + rebuild + restart
12. ⬢ Smoke público completo: 8 endpoints autenticados + bundle delivery — todos 200

## Backups na VPS pra rollback

```
/opt/dap-operacao/oficina.db.bak.20260505-192201          (SQLite anterior, intacto)
/opt/dap-operacao/.env.bak.20260505-192201                (env pré-Postgres)
/opt/dap-operacao/.git_pre_postgres_migration_20260505-192201  (commit a830d79)
```

**Rollback completo se algum dia precisar (< 1min):**
```bash
ssh root@76.13.170.42 'cd /opt/dap-operacao &&
  git checkout a830d79 &&
  cp .env.bak.20260505-192201 .env &&
  npm ci &&
  npm run build &&
  systemctl restart dap-operacao'
```
SQLite original retorna do disco, sem perder o último estado pré-migração.

## Validação pós-deploy

| Camada                                      | Resultado |
| ------------------------------------------- | --------- |
| `npm run check` (tsc)                       | ✅ zero erros |
| `npm test` Postgres local Docker            | ✅ 117/117 |
| Build prod                                  | ✅ 14 chunks, entry 216 KB / 59 KB gz |
| Service ativo                               | ✅ `dap-operacao.service` (PID 836516, port 5001) |
| Login + 8 endpoints autenticados (público)  | ✅ todos 200 |
| Set-Cookie correto                          | ✅ HttpOnly; Secure; SameSite=Lax |
| CSP sem violação                            | ✅ Cloudflare beacon permitido |

## Trade-off conhecido

**Latência por request**: SQLite local era ~0ms; Postgres remoto via direct connection (us-west-2) é ~80–120ms por roundtrip. Pra 99% das ações isso é imperceptível (humano consultor levou X segundos pra clicar). Para operações que fazem N queries (e.g. `/api/service-orders/:id/full` que carrega OS + items + comments + telemetry + payments), o impacto é multiplicado e justifica eventual cache local ou views materializadas.

**Pooler bloqueado**: o Supabase pooler (porta 6543, multiplexação de conexão) tinha cache da senha velha após reset; usamos direct (porta 5432) pra desbloquear. Trocar pra pooler quando cache atualizar (~5–10min após reset, propagação): apenas mudar `db.<ref>:5432` → `aws-0-us-west-2.pooler:6543` no `.env` da VPS.

## Próximos passos

- [ ] Trocar senha admin (UI ou SQL) e rotacionar `BOOTSTRAP_ADMIN_PASSWORD` da VPS
- [ ] Resetar senha Postgres pra senha forte e atualizar `.env` da VPS
- [ ] Migrar pra Supabase pooler (port 6543) quando cache atualizar
- [ ] Atualizar [[02-schema]] e [[05-deploy-runbook]] com a nova realidade Postgres
- [ ] Phase 2 schema: TEXT timestamps → TIMESTAMPTZ (impacta route handlers)
