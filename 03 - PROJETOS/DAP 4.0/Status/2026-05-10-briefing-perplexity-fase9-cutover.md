# Briefing técnico — DAP4 monorepo, schema expansion + apps/admin (10/05/2026)

> Briefing externo para acompanhamento por IA externa (Perplexity).
> Self-contained, sem dependência de paths locais.

## Contexto

Sou founder/CTO da DAP 4.0 (Doctor Auto Prime), ecossistema automotivo brasileiro
especializado em alemães premium (BMW, Audi, Mercedes, VW). 12 unidades de negócio
em construção (oficina, gestão, IA comercial, conteúdo, etc.).

Estou liderando a migração de um monolítico legacy pra monorepo de 5 apps standalone.
Stack:
- pnpm monorepo, TypeScript end-to-end
- React 18 + Vite (clients), Express 5 (servers)
- PostgreSQL via Supabase, Drizzle ORM, RLS-based multi-tenancy
- 5 apps: `operacao` (consultor portal — live em prod), `gestao`, `aios`
  (chairman/IA), `admin` (5º, em build), tooling
- DB single Supabase project com 4 schemas: `oficina` (per-tenant ops),
  `gestao` (executive KPIs), `aios` (cross-tenant IA telemetry), `crm`
  (cross-portal pipeline)

## O que acabei de entregar (sessão 2026-05-10)

**Cutover Fase 9** — schema expansion em DOCTOR PRIME prod:

- 6 migrations aplicadas sequenciais (0004 → 0005 → 0006 → 0003 → 0007 → 0008 → 0009)
- 21 novas tabelas + 12 RLS policies + 4 CHECK constraints + ~58 indexes
- Foundation tables nos schemas `aios`/`crm` que não existiam em prod
- Bug latente fixado: `function_search_path_mutable` em `gestao.touch_updated_at`
- 1 nova foundation table cross-tenant: `oficina.platform_audit_log`

**Estado final:** 45 tables · 32 policies · 7 CHECKs · 76 FKs · ~153 indexes ·
**0 advisor warns nas nossas 4 schemas** (eram 1 antes do fix).

## Decisões arquiteturais críticas tomadas

### 1. Hand-written migrations FORA do Drizzle `_journal.json`

**Problema descoberto:** snapshots Drizzle (`meta/000{2,3}_snapshot.json`)
referenciavam tabelas (`aios.conversations`, `crm.tenants`, `crm.users`,
`crm.leads`) como existentes, mas nenhuma migration .sql as criava.
Em staging branch fresh isso passava porque migrations hand-written
pré-Drizzle (162 originais) rodaram parcialmente. Em prod, schemas
aios/crm sequer existiam — a migration que dependia dessas FKs quebraria.

**Decisão:** criei 5 migrations hand-written paralelas (0005, 0006, 0007,
0008) que ficam FORA do `_journal.json` Drizzle. `db:generate` continua
"No schema changes 😴" porque os snapshots já assumem o estado pós-apply.

**Quero validação:** qual o padrão da indústria pra resolver snapshot
drift Drizzle? Re-baseline via `drizzle-kit introspect` + force-push,
ou parallel hand-written como fiz?

### 2. RLS habilitada SEM pgPolicy em `oficina.platform_audit_log`

**Modelo de segurança:** tabela é audit log cross-tenant (DAP staff
actions: SQL console execution, force password reset, role change,
impersonation). Acesso só via `apps/admin/server` que usa `service_role`
connection (bypassa RLS) + middleware HTTP `requirePlatformOwner` (gate
por role IN ('owner', 'system') em `crm.users`).

Supabase advisor flagga `rls_enabled_no_policy` warn — marquei como expected.

**Quero validação:** esse pattern é defensável? Alternativa seria
pgPolicy chamando função `is_platform_owner_or_system()` que faz SELECT
em `crm.users` — defesa em profundidade extra, mas:
- Adiciona helper SECURITY DEFINER + risk de recursão se RLS de crm.users
  bater de volta
- Performance: cada SELECT no audit log dispara subquery extra
- Já temos middleware HTTP fazendo o mesmo check

### 3. `apps/admin` UI = inline-styles dark theme (não Tailwind/shadcn)

**Razão:** portal interno DAP staff (não cliente). Pattern visual mais
"Linear-internal / dense functional" que cinematic. Cinematic visuals
ficam pros portais cliente-facing (operacao/aios).

**Trade-off:** acelera entrega das 8 tasks pendentes em ~30%, mas custa
~1h refactor depois quando quisermos elevar a barra visual.

## O que vem agora (próximas 1-2 sessões)

8 tasks pra construir `apps/admin` (portal interno DBA console + IAM):

| Task | Descrição | Complexidade |
|------|-----------|--------------|
| 10.3 | SQL console (RPC whitelist substituindo `exec_sql` backdoor) | **CRÍTICO — segurança** |
| 10.4 | Tables browser (4 endpoints + UI tree) | Média |
| 10.5 | Staff management (bcrypt + invite token + force-reset) | Alta — auth |
| 10.6 | RBAC matrix read-only | Baixa |
| 10.7 | Route map (sitemap visual cross-app) | Baixa |
| 10.8 | AdminLayout + componentes compartilhados | Média |
| 10.9 | Login + reset (reuse operacao verbatim, ADR-001) | Baixa |
| 10.10 | E2E Playwright + smoke | Média |
| 10.11 | ADR-002 + README | Trivial |

**Estimativa total:** 10-15h.

## Red flags / pontos onde quero pesquisa externa

### A. Defense-in-depth pra DBA console interno

Task 10.3 (SQL console) é o mais delicado. **Substitui um antipattern
crítico do app legacy** (DoctorAuto): 28 arquivos lá expunham
`service_role` JWT no client. Mitigation atual planejada:

- RPC PostgreSQL `admin_execute_query` com `SECURITY DEFINER`
- Whitelist de comandos (SELECT/INSERT/UPDATE/DELETE/EXPLAIN/ANALYZE —
  banido DROP/TRUNCATE/CREATE/ALTER/GRANT/REVOKE)
- Audit log obrigatório por execução
- 30s query timeout
- Role guard validado pelo RPC (não só pelo client)
- DestructiveConfirm modal pra DELETE/UPDATE/INSERT regex match
- History em localStorage SEM gravar query result completo

**Pergunta:** o que mais a indústria adiciona em DBA consoles internos?
Padrões conhecidos (Postgres MCP-style, supabase-studio internals,
Retool internal admin)? Ataques possíveis que preciso mitigar
(prepared statement injection, RETURNING leak, EXPLAIN side-channel)?

### B. Cutover de migrations validadas em staging

Lição grande aprendida hoje: **caminho validado em staging branch fresh
NÃO transfere direto pra prod com estado pré-existente.** Tive que fazer
pre-flight checks completos (list_tables + execute_sql comparando
policies/checks por nome) antes de aplicar.

**Pergunta:** existe ferramenta/workflow estabelecido pra automatizar
esse pre-flight? Comparar schema esperado vs real e gerar plan
diferencial? (Suponho que `drizzle-kit introspect` + diff manual seja o
caminho — mas há algo mais elegante?)

### C. Recursão de RLS em policies cross-schema

Se eu adicionasse pgPolicy em `oficina.platform_audit_log` que chama
helper que faz SELECT em `crm.users`, e `crm.users` tem RLS própria,
posso bater em recursão (ou bloqueio silencioso por authenticated role).

**Pergunta:** padrão Supabase pra cross-schema RLS dependencies? Helper
functions com `SECURITY DEFINER` resolvem (e foi minha decisão pros
helpers `current_user_org_id`), mas multiplicam funções a manter.

---

## Status de pendências antigas (não atacadas hoje)

- 🚨 **Security:** rotacionar `.env.local` parado 25+ dias
- 🚨 **Security:** reset 2 senhas DOCTOR PRIME expostas em chat
- Postgres test DB local fora do ar (bloqueia 18 test files)
- Task 9.1 step 6 (ALTER `service_orders.status` text→enum + backfill)

Quer que eu detalhe alguma decisão? Ou prefere que eu pesquise patterns
específicos pra trazer pro Claude implementar amanhã?
