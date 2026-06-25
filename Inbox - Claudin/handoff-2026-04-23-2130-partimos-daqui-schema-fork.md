---
type: handoff
date: 2026-04-23
time: "21:30"
project: DAP 4.0 / Portal Família + Portal DAP Dev
topic: Ponto de partida — decisão de schema Supabase + fork shadcn-admin antes de qualquer código novo
tags: [handoff, claudin, portal-familia, portal-dev, schema, fork, decision-point]
---

# Handoff — PARTIMOS DAQUI: schema + fork

> **Este é o handoff de CONTINUIDADE imediata.** Substitui a direção do handoff anterior (`handoff-2026-04-23-2119-portal-dap-fork-decision.md`) adicionando uma camada: **antes do fork, decidir a arquitetura do database**. A próxima sessão retoma a partir de **2 decisões encadeadas abertas**, não 1.

## Contexto

Portal Família DAP 4.0 está live em dev (typecheck OK, migration aplicada, seed aplicado, login funcionando após fix de `auth.identities`). 136 arquivos escritos por 5 agentes paralelos, zero conflito cross-agent de tipo. Thales confirmou que consegue logar.

Em seguida, Thales pediu **Portal DAP Dev** (console técnico admin-only pra Parliament/Agents/RAG/Crons/VPS). Comecei spawn de 7 agentes pra construir do zero, mas Thales pivotou:

> "não conseguimos pegar um portal pronto, refatorar e implantar?"

Razão válida. Matei o swarm, propus fork do **`satnaing/shadcn-admin`** (Vite + React + shadcn + TanStack — nossa stack exata).

**Logo depois**, Thales levantou preocupação maior:

> "onde tá a database?" → "acha o ideal?"

Resposta honesta: **não é ideal**. Portal Família foi aplicado direto no schema `public` do Supabase DOCTOR_PRIME, junto com as 56+ tabelas existentes (dashboard, agents, Parliament, Odin Parts, Kommo). Blast radius grande, 2 conceitos de "user" coexistindo (`profiles` vs `colaboradores`), nomes genéricos sem prefixo, 141 migrations misturadas, zero isolamento de billing/backup.

Apresentei 3 arquiteturas (2 projects separados, mesmo project + schema separado `portal`, manter como está) e minha recomendação: **schema separado `portal` no mesmo DOCTOR_PRIME**. Pedi pro Thales escolher B.1 (migrar agora, antes do fork), B.2 (fork primeiro, migra depois) ou C.1 (aceita débito).

Thales respondeu `/handoff PARTIMOS DAI` — quer gravar e retomar exatamente aqui. **Sem resposta A/B/C ainda.**

## O que funcionou (com evidência)

- **Portal Família dev server UP** — `http://localhost:5174/` funcionando, login OK pros 4 profiles (admin/gestor/consultor/mecanico).
- **Typecheck 0 erro** cross-agent em 136 arquivos.
- **Reconciliação manual do conflito CommandK** — Zustand store restaurado, TopBar atualizado, rotas faltantes adicionadas.
- **Fix da auth `Database error querying schema`** — `auth.identities` vazio era a causa raiz; criando 1 row por user resolveu.
- **Swarm D0 abortado limpo** — 7 agentes matados via `TaskStop`, tasks deletadas.
- **Handoff #1 da sessão gravado** — `handoff-2026-04-23-2119-portal-dap-fork-decision.md` captura todo o Portal Família + Notion.

## O que NÃO funcionou (e por quê)

- **Decisão arquitetural de database foi tomada sem questionamento inicial** — apliquei migration `portal_familia_schema` direto no schema `public` do DOCTOR_PRIME junto com as 56 tabelas existentes. Não é ideal: blast radius grande, nomes sem prefix `portal_`, coabitação com `colaboradores`/`customer_profiles`/etc. Thales pegou isso ao perguntar "ACHA O IDEAL?". **Resposta honesta: não. Débito técnico de 1ª classe já instalado.**
- **Publicação Notion #2/#3/#4** continua bloqueada pelo Cloudflare WAF. Não tentado nesta etapa (Thales pivotou pra outras frentes).
- **Construir Portal DAP Dev do zero** foi decisão errada (abortada pelo Thales). Razão: admin panel é território resolvido por templates OSS world-class.

## O que ainda não foi tentado

- **Migrar tabelas do Portal Família pra schema `portal` no Supabase** — `ALTER TABLE public.profiles SET SCHEMA portal` (x9). Requer também ajustar helpers RLS (`auth_role()` precisa `portal.profiles`), supabase-js calls (`supabase.schema('portal').from(...)`), e seed re-aplicado em `portal.*`.
- **Fork `satnaing/shadcn-admin`** em `C:\dev\dap4\portal-shell-base/`.
- **Trocar auth Clerk → Supabase** no fork (provavelmente 1-2 arquivos).
- **Republicar Notion #2/#3/#4** com payloads menores (ou via `update-page` em chunks).
- **Smoke test funcional completo Portal Família** — Thales confirmou login, mas não validamos home/consultor/roleGate ainda.

## Arquivos tocados

| Arquivo / diretório | Status | Notas |
|---|---|---|
| `C:\dev\dap4\portal-familia\` (136 arquivos) | **Funcional** | Typecheck OK, dev UP, login OK |
| `C:\dev\dap4\supabase\migrations\20260424_03_portal_familia_schema.sql` | **Aplicado em `public`** | ⚠️ Débito: deveria estar em schema `portal` |
| `C:\dev\dap4\supabase\seed\portal_familia_seed.sql` | **Aplicado** | Idem — dados em `public` |
| Supabase DOCTOR_PRIME — 9 tabelas novas em `public` | **Vivas** | `empresas`, `profiles`, `user_preferences`, `sugestoes`, `trilhas`, `trilha_modulos`, `user_trilha_progresso`, `processos`, `avisos` |
| Supabase DOCTOR_PRIME — `auth.users` + `auth.identities` | 4 users/identities criados | UUIDs `22222222-...-00000000000[1-4]`, senha `DAP2026!` |
| `C:\dev\dap4\portal-dev\` (fragmentos) | **Abortado** | Apagar antes de forkar shadcn-admin |
| `C:\Users\docto\.claude\projects\C--WINDOWS-System32\memory\project_portal_familia.md` | Criado | |
| `C:\Users\docto\.claude\projects\C--WINDOWS-System32\memory\project_portal_dev.md` | Criado | ⚠️ Precisa update marcando pivot pra fork |
| Notion — página DAP 4.0 Ecosystem Map | Publicada | https://www.notion.so/34b6d9495c778175b1dafa86608e6ae8 |

## Decisões tomadas

- **Portal Família foi greenfield TypeScript novo** — correto.
- **Swarm paralelo de 5 agentes com claims disjuntos** — funcionou excelentemente. 136 arquivos, 0 erro cross-agent.
- **Auth Supabase + identity rows explícitos via SQL** — funciona mas é pegadinha; Admin API seria mais limpa em prod.
- **Abortar construção do Portal DAP Dev do zero** — correto após pivô do Thales.
- **Recomendação do fork = `satnaing/shadcn-admin`** — mesma stack exata, MIT, pages polidas.
- **Recomendação de schema = opção (B) `portal` no mesmo DOCTOR_PRIME** — compromisso inteligente: custo zero, isolamento lógico forte. Pendente resposta do Thales.

## Bloqueios & perguntas abertas

**2 decisões encadeadas pendentes, nesta ordem:**

### Decisão 1: Database schema
- **(B.1)** Migrar Portal Família pra schema `portal` **AGORA**, antes do fork (custo: 1 sessão focada, ~20 arquivos tocados)
- **(B.2)** Fork primeiro, migrar schema depois (débito fica mais tempo; risco: fork em cima de fundação errada)
- **(C.1)** Aceita débito atual (tabelas ficam em `public`), segue em frente
- **(A)** Supabase project totalmente separado (+US$25/mês, mais puro, mais trabalho)

### Decisão 2: Estratégia do fork shadcn-admin
- **(A)** Fork e migrar **ambos** os portais (Família + Dev) pra base nova — consistência total
- **(B)** Fork só pro Portal Dev, mantém Família como está
- **(C)** Validar demo no browser antes — https://shadcn-admin.netlify.app

**Pendências secundárias:**
- Notion WAF bloqueando 3 publicações — estratégia de payload menor ou chunks.
- Fragmentos do `portal-dev/` do swarm abortado — apagar antes de forkar.
- Deploy VPS `portal.doctorautoprime40.com` via Cloudflare Tunnel — não configurado.
- Testes (`pnpm test`) — 25+ testes escritos pelos agentes, ainda não executados.
- Commit inicial + push pro GitHub.

## Próximo passo exato

**Thales responde as 2 decisões encadeadas (schema + fork). Sequência recomendada:**

### Se (B.1 + A) — caminho ideal world-class:

1. Criar migration `20260424_04_portal_familia_schema_move.sql`:
   - `CREATE SCHEMA IF NOT EXISTS portal;`
   - `GRANT USAGE ON SCHEMA portal TO authenticated, service_role;`
   - 9× `ALTER TABLE public.<tabela> SET SCHEMA portal;`
   - Recriar helpers `auth_role()` / `auth_empresa_id()` apontando pra `portal.profiles`
   - Ajustar todas RLS policies pra referenciar `portal.profiles`
2. Atualizar `portal-familia/src/lib/supabase.ts` pra usar `supabase.schema('portal')` onde aplicável OU typar `Database` com schema `portal`
3. Atualizar ~6 services do Portal Consultor pra consumir schema certo
4. Rodar `pnpm tsc --noEmit` → validar
5. Rodar `pnpm dev` → testar login + home
6. `git clone https://github.com/satnaing/shadcn-admin C:\dev\dap4\portal-shell-base` (temporário)
7. Trocar auth Clerk → Supabase no fork
8. Apontar pra schema `portal`
9. Remover páginas que não servem (Apps, Chats)
10. Renomear `portal-shell-base/` → `portal-dev/` (substituindo fragmentos)
11. Adicionar rotas Parliament/Agents/RAG/Crons/VPS gated `role='admin'`
12. Migrar código do Portal Consultor W1 pra base do fork (opção A = ambos os portais na mesma base)
13. Commit inicial + push: branch `feat/portal-familia-e-dev-wave-0`
14. Deploy VPS (Cloudflare Tunnel + Docker service)

### Se (B.2 + B) — caminho mais curto, débito fica:

1. Clonar shadcn-admin direto em `portal-dev/`
2. Trocar auth Clerk → Supabase (schema `public` por enquanto)
3. Adicionar features Portal Dev
4. Commit + deploy
5. Voltar pra migrar schema `portal` DEPOIS — **muito provável que vire tech debt permanente**

### Se (C.1) — aceita débito, segue rápido:

1. Pula migração de schema
2. Vai direto pra fork + construção
3. Aceita coabitação `public.profiles` com 56 tabelas legadas

## Setup / comandos úteis

```bash
# Portal Família (atual, funcionando)
cd C:\dev\dap4\portal-familia
pnpm dev                  # http://localhost:5174
pnpm tsc --noEmit         # exit 0 validado
# credenciais: thales@doctorautoprime40.com / DAP2026!  (admin)

# Fork alvo
https://github.com/satnaing/shadcn-admin          # repo
https://shadcn-admin.netlify.app                   # demo live (qualquer email/senha)

# Supabase MCP
project_id: acuufrgoyjwzlyhopaus   # DOCTOR_PRIME
# 141 migrations já aplicadas; próxima seria 20260424_04_*

# Comandos pra migração schema `portal` (preview — NÃO rodar sem confirmar)
# (B.1) preview SQL:
#   CREATE SCHEMA IF NOT EXISTS portal;
#   ALTER TABLE public.profiles SET SCHEMA portal;
#   -- (x9 tabelas)
#   DROP FUNCTION auth_role();
#   CREATE FUNCTION auth_role() RETURNS TEXT
#     LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = portal, public
#     AS $$ SELECT role FROM portal.profiles WHERE id = auth.uid() $$;
```

## Ponto de entrada da próxima sessão

Primeira linha do Thales provavelmente vai ser: **"B.1 e A"** OU **"C.1 e B"** OU **"quero ver demo antes"**.

Se disser só um dos dois (ex: "B.1"), perguntar qual variante de fork (A/B/C).

Se disser "vamos"/"bora"/qualquer coisa afirmativa sem especificar: assumir **(B.1 + A)** — caminho world-class, o que a memória `user_profile` + CLAUDE.md indicam que Thales escolheria se parasse pra pensar.

Status das tasks:
- Portal Família (#5-#10) ✅ completo
- Portal DAP Dev (#11-#17) ❌ deletadas (pivô pro fork)
- Notion #2/#3/#4 ⏸️ WAF bloqueando
