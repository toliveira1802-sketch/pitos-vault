---
type: handoff
date: 2026-06-05
time: "01:40"
project: dap-aios
topic: Colunas Meta da Anna no schema AIOS (brand/external_contact/phone_number_id) — single source of truth pro dap4 consumir
tags: [handoff, claudin, dap-aios, dap4, anna, meta, schema, cross-repo]
---

# Handoff — Schema AIOS pra espinha Meta da Anna (dap-aios owna, dap4 consome)

> Rodada de **coordenação cross-repo**. Uma sessão paralela no **`dap4`** (repo distinto) está
> construindo a espinha Meta da Anna (mata Kommo, WhatsApp direto via Meta Graph, persiste no
> AIOS). Eu (sessão `dap-aios`) **revisei o spec dela**, peguei um bloqueante real (ownership do
> schema do AIOS), e **owno a migração Drizzle** pra o `dap4` só consumir colunas versionadas.

## Contexto / a decisão central

`dap4` (código da Anna) e `dap-aios` (portal) são **repos git separados** que escrevem no **mesmo
Supabase `hlhfqnhsvwxodtwdkkhf`**. As tabelas `conversations`/`messages`/`leads` são **owned pelo
Drizzle do `dap-aios`** (`packages/types`). Se o `dap4` mandasse `apply_migration` cru, o próximo
`db:push`/introspect do `dap-aios` detectaria drift e os dois brigariam.

**Decisão (endossada pelas duas sessões + Thales):** o `dap-aios` é o **single source of truth do
DDL do AIOS**; o `dap4` só **lê/escreve** as colunas via cliente Supabase. Zero DDL do lado do `dap4`.

## O que funcionou (com evidência)

- **Review do spec da Anna** (read-only no `dap4`, sem tocar na WIP de 23 arquivos da sessão paralela). Peguei: (#1) ownership do schema cross-repo, (#2) fronteira TS/Python embaçada do AiosStore, (#3) idempotência/dedup sem constraint, + gotchas confirmados no banco vivo.
- **Verificação no banco vivo `hlhf`** (read-only, via Supabase MCP) — confirmei que as tabelas aguentam a escrita da Anna, e os gotchas reais (ver abaixo).
- **Migração 0003** no `dap-aios` (`packages/types/src/schema/consultor.ts` + `server/migrations/0003_lazy_thunderbolts.sql`):
  - `conversations`: `brand` (NOT NULL default `'dap_prime'`), `external_contact`, `phone_number_id` + index `(channel, external_contact, status)`.
  - `leads`: `brand` (NOT NULL default `'dap_prime'`).
  - `messages`: unique index **parcial** em `external_id` (`WHERE external_id IS NOT NULL`) — dedupe de retry da Meta.
  - `brandSchema = z.enum(['dap_prime','dap_bosch'])` refinando `insertLead`/`insertConversation` (optional → omitido usa default, valor inválido rejeitado). Responde review codex P2.
- **Aplicada no `hlhf`** via SQL aditivo (backward-compatible; backfill `dap_prime`, unique parcial não toca NULLs). Colunas + 2 índices confirmados. Schema `test` re-sincronizado.
- **Gate** — `pnpm check` OK · **server 350/350** verde (regressão completa em tabelas-núcleo, incl. R16.5 + aios-readonly). CI 9/9 verde, 0 threads abertas.
- **PR #49 mergeado** (`bd57b6f`) + **deploy em staging** (container healthy, subdomínios 200).

## Alinhamento crítico de valores (resolvido)

`brand` guarda **`dap_prime`/`dap_bosch`** — os ids exatos do `meta-brands.ts` do `dap4` (`BRANDS = ['dap_prime','dap_bosch']`), pra a Anna não precisar traduzir. (Minha 1ª versão usou `'prime'`; a sessão paralela corrigiu pro contrato; refeito.)

## Gotchas que o dap4 (AiosStore) TEM que tratar (do schema vivo)

1. **FK pra `users`** — `messages.sent_by_user_id`, `conversations.assigned_to`, `leads.owner_id` são FK→`users`. A Anna **não é user** → outbound com `sent_by_user_id = NULL` (ou criar user "Anna AI"). O portal precisa renderizar `sent_by` nulo como "Anna". (Cuidado: existe user humano `anna@doctorautoprime.com` — não confundir com o agente.)
2. **NOT NULL sem default** — `leads.name`, `messages.body`, `*.created_at/updated_at`. Insert cru tem que setar. `leads.name` → fallback (telefone/"Lead WhatsApp") quando sem `senderName`; `messages.body` → placeholder pra mensagem só-mídia.
3. **`messages.direction` sem CHECK no DB** — alinhar a `'inbound'/'outbound'` por convenção (o que o `dap-aios` usa).
4. **R16.5 seguro** nesta fatia (Anna cria lead+conversation+message, não customer/vehicle).

## Bloqueios & pendências (do review, pro plano do dap4)

- **Idempotência inbound** agora tem o unique em `messages.external_id` — mas o AiosStore precisa **usar** (insert com ON CONFLICT/try). Outbound precisa de chave própria (não reusar o id inbound).
- **Race de contato** (`resolveContact`): falta dedup atômico em lead/contato — usar o index `(channel, external_contact, status)` em `conversations` pra achar a aberta; definir precedência customer-by-phone → lead-by-phone → novo lead.
- **Fronteira TS/Python**: cravar gateway (TS) dono da persistência; Anna (Python) compute puro.
- **RLS off nas 32 tabelas do `hlhf`** (advisory crítico) — Anna escreve via service_role (funciona), mas é P1 de segurança antes de volume real. Coordenar o rollout de RLS entre os dois repos.

## Sequenciamento entre as sessões

1. ✅ **`dap-aios` (esta sessão):** migração Drizzle mergeada + colunas **vivas** no `hlhf`.
2. ⏭️ **`dap4` (sessão paralela):** agora **destravado** — escrever o `AiosStore` (worktree isolado, sem tocar na WIP) apontando pras colunas já existentes. Importar `brandSchema` de `@aios/types` se quiser o enum.
3. A atualização do **spec do `dap4`** pra refletir a realidade (espinha já existe, gap = persistência) é tarefa da **sessão `dap4`** (repo dela) — não toquei.

## Arquivos tocados (dap-aios)

| Arquivo | Status |
|---------|--------|
| `packages/types/src/schema/consultor.ts` | +brand/external_contact/phone_number_id, índices, `brandSchema`, inserts refinados |
| `server/migrations/0003_lazy_thunderbolts.sql` | Criado (aplicado no hlhf) |
| `server/migrations/meta/0003_snapshot.json` + `_journal.json` | Drizzle journal |

## Próximo passo exato

**Avisar a sessão `dap4` que as colunas estão vivas** (`brand`/`external_contact`/`phone_number_id` em `conversations`/`leads`, unique em `messages.external_id`, default `dap_prime`) → ela segue com o `AiosStore`. Do lado `dap-aios` não há mais nada pendente nesta frente; quando o portal for exibir conversas/leads vindos da Anna, tratar o `sent_by_user_id` nulo na UI (renderizar "Anna").

## Setup / comandos úteis

- main em `bd57b6f`. Branch `feat/aios-schema-anna-meta-columns` mergeada e deletada.
- Migration: `server/migrations/0003_lazy_thunderbolts.sql` (já no hlhf). Re-sync test schema: `pnpm --filter @aios/server test:db:setup`.
- ⚠️ DDL do AIOS = sempre pelo Drizzle do `dap-aios` (`db:generate`), nunca `apply_migration` cru pelo `dap4`.
