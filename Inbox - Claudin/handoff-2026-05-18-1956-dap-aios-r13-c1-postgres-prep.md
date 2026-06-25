---
type: handoff
date: 2026-05-18
time: 19:56
project: dap-aios
topic: R13 c1 — PR #1 mergeada, branch R13 aberta, aguardando secrets DEV pra refactor SQLite→Postgres
tags: [handoff, claudin, dap-aios, r13, postgres, supabase]
---

# Handoff — R13 c1 prep · SQLite → Postgres em DEV

## Contexto

Sessão no `dap-aios` (`C:\THALES\DAP4.0\dap-aios`). Começou confirmando R12 (Etapa 2 Consultor — commercial_status + 4 telas: lista OS abertas, pátio kanban, histórico, dashboard operação). 124 testes server verdes, 5 commits temáticos, handoff de 426 linhas.

Repo do projeto não existia ainda no GitHub. Criamos `toliveira1802-sketch/dap40-perple-claude` (privado), pushamos `main` + 6 branches (R11.1 + 5 fases R12), abrimos PR #1, mergeamos via `--merge` (preserva 9 commits) e abrimos `feat/r13-c1-postgres-dev` a partir de main atualizada.

A sessão fechou no **BLOCO 2 do R13 c1 não iniciado** — aguardando Thales colar os 6 secrets DEV do `r13-secrets-locais.txt` no chat (DEV Supabase já provisionado). R13 c1 é o primeiro de 7 commits do R13 e substitui SQLite local por Postgres do Supabase em DEV. Spec inteira está em `prompts/` (não persistida no repo).

## O que funcionou (com evidência)

- **R12 verificação completa** — `git log main..HEAD` mostrou 9 commits ahead (4 R11.1 + 5 R12), 79 arquivos, +9114/-252; handoff `handoff-aios-rodada12-etapa2-consultor.md` com 14 seções, 426 linhas, presente no commit `ab0afea`.
- **Repo + PR #1** — `gh repo create dap40-perple-claude --private` ok; push main + branches ok; PR #1 (`mergeable=MERGEABLE, mergeStateStatus=CLEAN`) aberto e mergeado.
- **Merge preservando histórico** — `gh pr merge 1 --merge` produziu merge commit `1613a14`; 9 commits originais intactos em main, hashes preservados (essenciais pros handoffs R11.1+R12 que os referenciam).
- **Branch R13 aberta** — `git checkout -b feat/r13-c1-postgres-dev` a partir de main em `1613a14`; working tree limpo; validações final 3/3.
- **Servidor dev rodou** — `pnpm dev` subiu `:5050` (background process `bdiaeqsy7`); curl `/api/me` retornou 401 (Supabase enabled server-side) mas client em modo stub porque `envDir` aponta pra `..` que não tem `.env`.
- **TaskList R13 c1** — 12 tasks criados pra rastrear o commit (#1 completed = merge+branch; #2-12 pending).

## O que NÃO funcionou (e por quê)

- **Mensagem do commit `7607569` (gitignore) ficou enganosa** — Eu li `git diff main..HEAD -- .gitignore` (que mostrava mudanças R11.1 _já committed_ em `ab0afea`: remoção de `2-dap4-portals/`+`FORNECEDORES.zip`, adição de `_archive/`+`test-results/`+`playwright-report/`) e `grep` no working tree (que tinha +6 linhas R13 unstaged), misturei as duas leituras e concluí erradamente que `r13-secrets-locais.txt` e `*.tar.gz` já estavam em main. Sugeri mensagem "cleanup pos-arquivamento — _archive + playwright-report" pro Thales, mas o **diff real do commit `7607569` só contém as 6 linhas R13** (secrets + tar.gz). A mensagem **original do Thales** ("reforca gitignore com secrets-locais e tar.gz pra R13") estava correta. Commit já em main via merge `1613a14` — não foi amendado, dívida cosmética.
- **TaskCreate/TaskUpdate eram deferred tools** — Primeiro spawn falhou; tive que rodar `ToolSearch` antes pra carregar schemas. Custou 2 round-trips. Sequência correta: `ToolSearch select:TaskCreate` → `TaskCreate(...)`.
- **Image fornecida (PEDRO TAVERA, porta 5173) não era do dap-aios** — Print era do projeto `dap-operacao` (outro repo, P0 ecossistema). Confundi user inicialmente; ele clarificou que era só referência visual (opção B), não pra mexer no dap-operacao.

## O que ainda não foi tentado

- **Refactor SQLite → Postgres (BLOCO 2 do R13 c1)** — 11 etapas mapeadas no TaskList (#2-#12). Maior delta vs spec original do Thales: schema **não é PG-compatível**. 7 arquivos em `packages/types/src/schema/*.ts` usam `sqliteTable` + `integer({mode:'boolean'/'timestamp_ms'})` em 82 ocorrências. Padrão de refactor aprovado em bloco: `sqliteTable→pgTable`, `integer mode:boolean → boolean()`, `integer mode:timestamp_ms → timestamp({withTimezone:true, mode:'date'})`.
- **Criação do `.env` na raiz** com 6 secrets DEV — depende de Thales colar.
- **Apagar 7 migrations 0000-0006 SQLite e regenerar baseline Postgres** via `pnpm db:generate`.
- **Adaptar `db-helpers.ts`** — hoje usa `sqlite.exec("DELETE FROM ...")` direto. Trocar por `TRUNCATE ... RESTART IDENTITY CASCADE` via `db.execute(sql\`...\`)`.
- **Test setup com Postgres + transaction rollback** — opção A do spec (Supabase DEV com schema dedicado). 124 tests precisam continuar verdes (≥120 aceitável com justificativa).
- **Frontend mudanças seguindo referência dap-operacao** — Thales disse "vamos seguir o claude, ele está fazendo o prompt" (outra IA externa). Aguardando prompt.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `.gitignore` | Completo | Commit `7607569` (+6 linhas R13). Mensagem "cleanup pos-arquivamento — _archive + playwright-report" não bate com diff real (só toca em r13-secrets + tar.gz). Já em main via merge `1613a14` |
| Nenhum outro | — | Sessão foi de orquestração (PR, branch, repo) + análise pré-R13. Sem mudanças funcionais |

## Decisões tomadas

- **Repo GitHub privado** — `dap40-perple-claude`. Razão: código de negócio sensível. Pode flipar pra público depois com `gh repo edit --visibility public --accept-visibility-change-consequences`.
- **`gh pr merge 1 --merge` (sem squash)** — Razão: handoffs R11.1 e R12 referenciam hashes individuais (`a5931b8`, `b45057e`, `3db8c43`, etc). Squash quebraria rastreabilidade.
- **`git pull --ff-only origin main`** — Razão: explicita fast-forward esperado; falha alto se main divergir entre fetch e pull (zero ambiguidade rebase/merge).
- **Aprovar 7 schemas em bloco** (sem ver diff de 1 antes) — Razão: padrão de conversão é mecânico (3 transformações tipadas). Pular preview economiza um round-trip; risco baixo porque drizzle-kit valida no `generate`.
- **R13 c1 ≠ spec literal em 5 pontos** — divergências (#1 path do client, #2 7 migrations em vez de 6, #3 schema precisa refactor amplo, #4 vitest.config no server/, #5 db-helpers usa sqlite.exec) reportadas ao Thales antes da execução. Todas aprovadas conforme proposta.
- **Imagem "PEDRO TAVERA" tratada como referência visual (opção B)** — Razão: print de outro projeto (`dap-operacao` :5173); user confirmou que era pra dap-aios usar como inspiração de UI, não pra mexer no dap-operacao.
- **Não amendar commit `7607569`** — Razão: já em main via merge. Reescrever main é destrutivo. Mensagem imprecisa é dívida cosmética aceitável.

## Bloqueios & perguntas abertas

- **Bloqueio principal:** Thales precisa colar os 6 secrets DEV no próximo turno (`DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`, `ADMIN_USER_UID`, `ADMIN_EMAIL`). R13 c1 não avança sem isso.
- **Aberta:** Drizzle vai aceitar todas as transformações sem ajuste? Possível surgir caso de `numeric(precision, scale)` ou `text[]` array que não foi mapeado no padrão aprovado. Se surgir, parar e perguntar.
- **Aberta:** Test setup vai precisar de schema `public_test` no Supabase DEV ou DB dedicado? Decisão pragmática do spec: A (Supabase DEV com schema test + transaction rollback). Se Supabase cair durante testes, eles caem junto — aceitável nessa rodada.
- **Aberta:** Frontend redesign baseado no dap-operacao — qual prompt o "Claude externo" vai entregar? Sem prazo claro.
- **Risco contido:** Connection string DEV deve usar **Session Pooler porta 5432** (não Transaction porta 6543). Drizzle precisa de prepared statements. Spec já explícito sobre isso, vou validar antes de `db:push`.

## Próximo passo exato

Quando Thales colar BLOCO 2 + secrets DEV no chat:

1. **Verificar gitignore** — `Get-Content C:\THALES\DAP4.0\dap-aios\.gitignore | Select-String "^\.env|tar\.gz|secrets-locais"` — esperado 5+ linhas (`.env` + `.env.local` + `.env.*.local` + `*.tar.gz` + `r13-secrets-locais.txt`).
2. **Receber 6 secrets DEV** + criar `C:\THALES\DAP4.0\dap-aios\.env` na raiz do projeto (não em parent — `envDir` do Vite aponta pra `..` mas `dotenv` do server carrega `../../.env` relativo ao server/src; vou verificar qual é o path real ao criar).
3. **Confirmar `git status`** — `.env` deve NÃO aparecer como untracked (gitignore bloqueia).
4. **Marcar task #2 (Setup deps) como `in_progress`** e rodar `pnpm remove better-sqlite3 @types/better-sqlite3` + `pnpm add pg` + `pnpm add -D @types/pg`. Confirmar `drizzle-orm` >= 0.30.
5. Seguir tasks #3 → #12 do TaskList nesta ordem: schema refactor → client.ts → drizzle.config → migrate.ts + db-helpers → seed.ts → test setup → scripts/package.json + .env.example → apagar 7 migrations → db:generate → db:push → db:seed → pnpm test (≥120/124) → pnpm check + build → smoke E2E (login + wizard + filtros + kanban + dashboard) → commit.
6. **Commit final**: `feat(db): migrar SQLite -> Postgres (Supabase DEV) + nova baseline migrations`. Anotar na mensagem: total de tests passou, schemas alterados, nome da migration gerada.
7. **Relatório pro Thales antes do commit 2 do R13**: `git show --stat HEAD`, output pnpm test, mudanças de bundle, warnings em db:push/test, tests ajustados + razão, tempo total.

## Setup / comandos úteis

```powershell
# Pasta de trabalho
cd C:\THALES\DAP4.0\dap-aios

# Estado git atual (na próxima sessão deve estar idêntico)
git branch --show-current   # → feat/r13-c1-postgres-dev
git log --oneline -3        # → 1613a14 merge, 7607569 gitignore, ab0afea R12 e2e

# Reabrir dev server (se necessário)
pnpm dev   # http://localhost:5050

# Repo + PR
# https://github.com/toliveira1802-sketch/dap40-perple-claude
# PR #1 já mergeada
```

**Decisões fixas do R13 c1 (não reabrir):**
- Postgres = Supabase cloud, não Docker local
- Session Pooler porta 5432 (não Transaction 6543)
- Migrations 0000-0006 antigas serão apagadas; nova baseline única gerada
- Admin via `ADMIN_USER_UID` lido do env, não hardcoded
- Tests usam Supabase DEV com transaction rollback
- 2 projects Supabase já criados pelo Thales: `dap-aios-dev` e `dap-aios-prod` (PROD entra no commit 5)
- Confirm Email = OFF, Magic Link = OFF, sem SMTP nessa rodada
- Auto Confirm = ON pro admin DEV e PROD (UUIDs já anotados)
