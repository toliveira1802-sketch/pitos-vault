---
type: handoff
date: 2026-06-05
time: 01:38
project: DAP4 / Anna
topic: Anna omnichannel re-plataforma — Fatia 0 (persistência AIOS), schema owned pelo dap-aios
tags: [handoff, claudin, anna, dap4, dap-aios]
---

# Handoff — Anna omnichannel re-plataforma, Fatia 0

> **Atenção: duas sessões Claude rodando em paralelo neste momento.** Esta sessão
> (brainstorm + spec) e outra sessão editando o repo `dap4` (agents/, routes, main.py).
> Este handoff amarra as duas. A migração de schema é da OUTRA sessão (dap-aios).

## Contexto

O Thales pediu "criar agentic AI WhatsApp comercial". Virou **evoluir a Anna** (não
reescrever) pra um agente comercial **omnichannel** (WhatsApp múltiplos números +
Instagram + Messenger, tudo via Meta Graph API), com Kommo morrendo e persistência
migrando pro portal **AIOS**.

Modelo de agentes travado:
- **Anna = boca única** — único agente que fala com o cliente, em todos os canais.
- **Zoraide = bastidor** — não fala com cliente; observa a base e **aciona a Anna** pra
  pós-venda/feedback. É produtor de gatilho.
- **Campanha = outro produtor de gatilho** (projeto separado). Todos passam pela porta
  proativa única da Anna (tabela `agente_demandas`, que já existe no AIOS).

**Achado que reescreveu o spec:** a espinha Meta (webhook + BrandRouter + sender) **já
existe e roda em prod** no dap4 — Kommo já está bypassado. O gap real é só
**persistência**: a Anna escreve em `meta_messages`/`ai_conversations` no Supabase do
gateway (DOCTOR PRIME), NÃO nas tabelas do AIOS — por isso o portal AIOS não enxerga as
conversas/leads da Anna. **Fatia 0 = repontar a persistência pras tabelas do AIOS**
(`conversations`/`messages`/`leads`), em dual-write.

## O que funcionou (com evidência)

- **Spec escrito, corrigido e commitado** — evidência: 2 commits no dap4 (`40227b5`
  inicial, `8d307db` corrigido pós-leitura do código), commits escopados só no arquivo
  do spec (`git commit -- <path>`), confirmado que a WIP da sessão paralela ficou intacta.
- **Inspeção do Supabase AIOS** (`hlhfqnhsvwxodtwdkkhf`) — evidência: `list_tables` +
  `execute_sql` retornaram o schema; tabelas `conversations`/`messages`/`leads`/
  `customers`/`vehicles` existem e encaixam.
- **Localização do P1** — evidência: `C:\dev\dap4` NÃO existe mais; P1 está em
  `C:\THALES\DAP4.0\dap4` (branch master, remote toliveira1802-sketch/dap4), Anna em
  `agents/agents/ana.py`.

## O que NÃO funcionou (e por quê)

- **Premissa original do spec (construir a espinha Meta)** — invalidada: o webhook
  `gateway/src/routes/meta-webhook.routes.ts` já faz tudo (dual-WABA, HMAC, brand
  resolve, chama Anna, responde, mídia). Reconstruir feriria DRY. Corrigido no spec.
- **`apply_migration` cru pelo dap4 pra criar as colunas** — REJEITADO (verdito da
  sessão paralela, endossado): o dap-aios owna o schema via Drizzle (`packages/types`);
  DDL cru do dap4 causaria drift no próximo `db:push`/introspect e os 2 repos brigam.
- **`git commit -- <path>` em arquivo novo** — falhou 1ª vez ("pathspec did not match"):
  arquivo untracked precisa `git add -- <path>` ANTES do commit escopado.

## O que ainda não foi tentado

- `AiosStore` (o único componente novo da Fatia 0) — **não iniciado**, bloqueado pela
  migração das colunas no dap-aios.
- Plano de implementação detalhado (writing-plans) — pausado até as colunas existirem.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `dap4/docs/superpowers/specs/2026-06-05-anna-espinha-meta-fatia0-design.md` | Completo (commitado) | spec da Fatia 0, já corrigido pós-código |
| `~/.claude/.../memory/project_anna_omnichannel_replatform.md` | Completo | memória do re-plataforma |
| `gateway/src/services/aios-store.ts` | Não iniciado | componente novo, espera colunas AIOS |

## Decisões tomadas

- **Anna boca única + Zoraide/campanha como gatilhos** — razão: 1 canal pro cliente,
  handoff entre agentes vira fila interna, não confunde o cliente.
- **Marca por canal (Decisão A)** — `phone_number_id` → `dap_prime`/`dap_bosch` →
  brandMode. Razão: Bosch e Prime têm preço/serviço/tom diferentes; unificar joga
  inteligência fora.
- **Schema owned pelo dap-aios via Drizzle (single source of truth), dap4 zero DDL** —
  razão: evita drift entre os 2 repos. É o ponto onde os dois lados se encontram.
- **Transição em dual-write** (legado + AIOS) antes de cortar o legado — razão: não
  perder o que o dashboard atual já consome.

## Bloqueios & perguntas abertas

- **BLOQUEIO PRINCIPAL:** migração Drizzle no **dap-aios** (sessão paralela). Sem as
  colunas, o `AiosStore` não pode ser codado.
- **Env do AIOS no gateway**: faltam `AIOS_SUPABASE_URL` + `AIOS_SUPABASE_SERVICE_KEY`
  (Thales provê; service key NÃO no chat — usar Read-Host -AsSecureString).
- **Cortar o legado** (`ai_conversations`/`meta_messages`): confirmar quem ainda lê antes.
- ⚠️ **RLS DESLIGADO nas 32 tabelas do AIOS** — dado de cliente exposto. Hardening entra
  pelo Drizzle do dap-aios (não DDL do dap4). Pendência P1.

## Contrato de migração (dap-aios executa, dap4 consome)

**`conversations`** adicionar: `brand` (text, NOT NULL, default `'dap_prime'`),
`external_contact` (text, null), `phone_number_id` (text, null) + índice
`(channel, external_contact, status)`.
**`messages`** adicionar: índice unique parcial `UNIQUE (external_id) WHERE external_id IS NOT NULL`.
**`leads`** adicionar: `brand` (text, NOT NULL, default `'dap_prime'`).
**Valores de `brand`**: exatamente `dap_prime` / `dap_bosch` (iguais ao `meta-brands.ts`).

## Próximo passo exato

1. **(dap-aios / sessão paralela)** Fazer a migração Drizzle com o contrato acima, PR
   próprio + teste, mergear. Avisar quando as colunas estiverem versionadas.
2. **(dap4 / esta linha)** Após o merge: criar worktree isolado do dap4, escrever
   `gateway/src/services/aios-store.ts` (+ `aios-supabase.ts` client) com TDD, fiar no
   `meta-webhook.routes.ts` em dual-write, smoke test contra Supabase AIOS de teste.

## ATUALIZAÇÃO — Fatia 0 implementada (PR #28 aberto)

A sessão dap4 executou o AiosStore em worktree isolado (`C:\THALES\DAP4.0\dap4-wt-anna-aios`,
branch `feat/anna-aios-store`). **PR #28**: https://github.com/toliveira1802-sketch/dap4/pull/28
- 8 commits, 179 testes verdes, tsc limpo, zero regressão na espinha Meta.
- `AiosStore` (resolveContact/upsertConversation/appendMessage) + dual-write fire-and-forget no
  meta-webhook.routes.ts + env guard em validate.ts. Review HIGH+MEDIUM corrigidos.

### >>> AÇÃO PRA SESSÃO dap-aios (dono do schema) <<<
Pro dedup do TOCTOU sair do inerte, faltam **2 unique parciais** (DDL, território dap-aios via Drizzle):
- `conversations (channel, external_contact) WHERE status = 'open'`
- `leads (phone) WHERE phone IS NOT NULL`
Sem elas o catch-23505 que o dap4 já tem é inofensivo mas inerte (cria duplicado sob corrida).
Também pendente do lado dap-aios: RLS hardening nas 32 tabelas (advisory crítico).

### Pendências pra fechar a Fatia 0 (Thales)
- Setar `AIOS_SUPABASE_URL` + `AIOS_SUPABASE_SERVICE_KEY` no `.env` do gateway (service key via
  Read-Host -AsSecureString, não no chat). Sem elas o boot em prod agora FALHA (guard proposital).
- Smoke real: 1 msg WhatsApp → conferir conversations+messages no AIOS hlhf.

## Setup / comandos úteis

- P1 (dap4): `C:\THALES\DAP4.0\dap4` — branch `master`. Conferir `git status` antes de
  qualquer commit (sessão paralela mexendo). Usar `git add -- <path>` + `git commit -- <path>`
  pra commit escopado sem varrer WIP alheia.
- Supabase AIOS: project_id `hlhfqnhsvwxodtwdkkhf` (DAP AIOS, sa-east-1).
- Spec canônico: `dap4/docs/superpowers/specs/2026-06-05-anna-espinha-meta-fatia0-design.md`.
