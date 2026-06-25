---
type: handoff
date: 2026-06-24
project: DAP AI (motor de diretores)
topic: Design da DAP AI + Fatia 1 (engine + Bianca, Fase A) implementada e mergeada
tags: [handoff, claudin, dap-ai]
---

# Handoff — DAP AI: design travado + Fatia 1 no `master`

## Resumo executivo
A unidade **DAP AI** saiu do greenfield. Numa sessão só: brainstorm → spec → plano →
implementação TDD por subagentes/inline → review final (opus) → merge. A **Fatia 1**
(esqueleto + diretora **Bianca/CMO** de ponta a ponta, **Fase A read-only externo**) está
no `master` do repo `dap-ai`, verde (22/22 testes, cobertura 96.5%, typecheck limpo),
revisada e com os 3 achados de segurança já corrigidos.

## Decisões de arquitetura (travadas nesta sessão)
- **Diretor = unidade central** — a C-suite real de `C:\THALES\ECOSSISTEMA-DAP40\`
  (Sophia/CEO + Bianca/CMO + Francisco/CFO + Anna/CSO + …). Não "agentes funcionais" soltos.
- **"Bate-bola Desktop↔VPS" resolvido:** vira **um engine só na VPS**, alcançável pelo
  **WhatsApp 24h** (Chapapiuro→Sophia). Claude Desktop fica como **janela opcional** (MCP remoto).
- **Definição híbrida:** DNA (persona/mandato) = `CONTEXTO.md` em git; **estado**
  (memória/eventos/artefatos) = Supabase do AIOS. Editar a pasta = editar o agente.
- **Artefatos no Google Drive** (link de volta no Zap). **LLM = Claude.**
- **Onde vive:** projeto próprio `dap-ai/` (motor) + substrato do AIOS (verdade).
- Spec completa: `dap-ai/docs/superpowers/specs/2026-06-21-dap-ai-runtime-design.md`.

## O que foi implementado (Fatia 1)
Engine de diretores, Fase A, com fronteira read/write blindada:
`HTTP POST /api/agent/ask {message}→{reply}` (auth bearer) → **Sophia** (`routeToDirector`
por nome/área) → **Brain** (Claude Agent SDK, runner injetável) → **tools**: RAG/data/memory
(fakes read-only), artefato (filesystem), evento (in-memory). DNA carregado de
`ECOSSISTEMA-DAP40/MARKETING/mkt-cmo/CONTEXTO.md`.

## Arquivos (todos novos, em `C:\THALES\DAP4.0\dap-ai`)
- `src/config/env.ts` (Zod, fail-fast) · `src/dna/{types,parse,load,roster}.ts`
- `src/tools/{ports,fakes,artifact-fs}.ts` · `src/engine/{brain,sdk-runner}.ts`
- `src/sophia/route.ts` · `src/http/app.ts` · `src/logger.ts` · `src/index.ts`
- `tests/**` (8 specs) · `package.json`/`tsconfig.json`/`vitest.config.ts`/`pnpm-workspace.yaml`/`.env.example`/`README.md`

## Endpoint
`POST /api/agent/ask` — body `{ message: string }` → 200 `{ reply: string }`;
401 sem `Authorization: Bearer <DAP_AI_SERVICE_TOKEN>`; 400 message vazia/ausente.

## Como rodar local
```bash
cd C:\THALES\DAP4.0\dap-ai
corepack enable pnpm && corepack pnpm install
cp .env.example .env   # ANTHROPIC_API_KEY, DAP_AI_SERVICE_TOKEN, ECOSSISTEMA_DIR
corepack pnpm dev      # http://127.0.0.1:5060
# smoke:
curl -s -X POST http://127.0.0.1:5060/api/agent/ask -H 'content-type: application/json' \
  -H "authorization: Bearer $DAP_AI_SERVICE_TOKEN" -d '{"message":"Bianca, resuma seu mandato em 3 linhas"}'
```

## Testes / checks executados
- `corepack pnpm test` → **22/22 passing** (8 arquivos).
- `corepack pnpm test:cov` → **96.5% linhas** (IO real é `/* v8 ignore */` e excluído).
- `corepack pnpm typecheck` → **limpo**. Review final (opus): **APPROVE WITH MINOR**.

## Commits (no `master`, merge `d6334f2`)
`1ea51b3` scaffold · `b7f5f6e` fix pnpm/zod3 · `3d81640` dna parse · `cc8888c` dna load ·
`da898b9` tools ports/fakes · `5e6b8f8` engine brain · `0521aff` sophia route ·
`ae0619f` http · `0390079` artifact-fs · `11cfbd7` sdk-runner/boot ·
`fecc26b` fix segurança (path traversal + bearer timing-safe + fail-fast).

## Notas de ambiente (importante)
- **pnpm via corepack** (não tem pnpm no PATH; usar `corepack pnpm <cmd>`). `npm` gera
  cruft — não usar. `pnpm-workspace.yaml` tem `allowBuilds: esbuild: true` (gate do pnpm 11).
- **zod 3** (intencional; o env.ts usa `required_error`, API que o zod 4 quebrou).
- Repo **sem remote** (só local). `noUncheckedIndexedAccess` ligado.

## Riscos / pendências
- **Smoke E2E real não rodado** (falta `ANTHROPIC_API_KEY` do Thales) — é o único pedaço
  validado só por typecheck. **Próximo passo A.**
- **Adiado (YAGNI, não no boot Fase A):** adaptadores reais Drive/Supabase/RAG, Sophia
  multi-diretor, porta MCP do Desktop, caminho comercial, Fase B (write externo).
- Sem backup offsite (sem remote) — criar repo GitHub quando quiser.

## Próxima rodada — ordem acordada: A → D → B → C → E
- **A. Smoke E2E** com a key real (destrava tudo).
- **D. Plugar o Chapapiuro** no `/api/agent/ask` (contrato que ele já chama) → falar com a
  Bianca pelo WhatsApp de verdade, mesmo com fakes. Feedback real mais rápido.
- **B. Substrato real do AIOS** — RAG HTTP + memória/event log no Supabase.
- **C. Google Drive** — artefatos saem do filesystem pro Drive (service account).
- **E. Segundo diretor (Francisco/CFO ou Anna/CSO) + Sophia multi-diretor com síntese.**

## O que paraleliza
Cada fatia é uma vertical independente → mesma esteira (spec curta → plano → TDD por
subagentes). B (Supabase) e C (Drive) são adaptadores atrás de ports já existentes — dá pra
tocar em paralelo. **Nota:** o canal de dispatch de subagentes caiu 2× nesta sessão; execução
inline foi mais confiável pra transcrição mecânica — considerar inline pras fatias pequenas.
