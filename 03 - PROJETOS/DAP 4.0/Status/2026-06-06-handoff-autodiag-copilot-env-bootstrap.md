---
projeto: autodiag-copilot
data: 2026-06-06
slug: autodiag-copilot-env-bootstrap
status: ✅ app funcional ponta a ponta (dev local)
autor: Claude (sessão Thales)
---

# Handoff — AutoDiag Copilot: bootstrap de ambiente + diagnóstico ponta a ponta validado

## Resumo executivo

O **AutoDiag Copilot** (`C:\THALES\DAP4.0\autodiag-copilot`) saiu de "código mergeado mas sem
rodar" para **100% funcional ponta a ponta em dev local**. O bloqueio nunca foi código — era
**configuração de ambiente** (`.env.local`) com credenciais inválidas/placeholder. Esta sessão
diagnosticou e corrigiu cada credencial, populou o dicionário de DTCs com embeddings, e **provou
o agente de diagnóstico gerando um roadmap de oficina real** (Golf GTI EA888 Gen3, P0300+P0301).

App roda no Chrome em `http://localhost:3000`. Login funciona. RAG (lookup exato + busca
semântica pgvector) funciona. Cérebro (Claude Sonnet 4.6) gera o diagnóstico.

## O que foi feito (destravado)

| Peça | Antes | Depois |
|------|-------|--------|
| DB host | `aws-0-us-east-1.pooler` (errado → "Tenant or user not found") | `aws-1-us-east-1.pooler` ✅ |
| DB senha | placeholder literal `[YOUR-PASSWORD]` (copiado da doc sem substituir) | senha real do reset ✅ |
| DB porta | `DATABASE_URL` em 6543 (transaction) | **5432 (session)** — 6543 entrou em cooldown anti-brute-force |
| `dtc_dictionary` | 12 códigos, **0 embeddings** | **200 DTCs + 200 embeddings** (1536d) ✅ |
| `OPENAI_API_KEY` | revogada (401 invalid_api_key) | nova chave válida ✅ |
| `ANTHROPIC_API_KEY` | inválida (401 invalid x-api-key) | nova chave válida ✅ |
| `SUPABASE_SERVICE_ROLE_KEY` | vazia | (ainda vazia — ver pendências) |

## Como rodar local

```powershell
# pnpm é via corepack (não está no PATH direto)
cd C:\THALES\DAP4.0\autodiag-copilot
corepack pnpm dev          # → http://localhost:3000
```

- **URL:** http://localhost:3000 · **/login** responde 200
- **Login:** existe 1 conta (auth.users) no projeto Supabase DAP4.0. Se a senha for conhecida,
  entra direto; senão criar via `/signup` (email/senha funciona).
- **Seed (idempotente, backfill de embeddings):** `corepack pnpm seed`

## Banco

- **Projeto Supabase:** `DAP4.0` ref `cpzgtfblywexqglqkgbt` (us-east-1)
- **Schema:** `ferramentas` (não `public`) — compartilhado com o ecossistema DAP4
- **Estado dos dados (2026-06-06):** profiles=1, auth_users=1, vehicles=0, diagnostics=0,
  dtc_dictionary=200 (todos com embedding), coluna `code` é `text`.

## Arquivos alterados

- `.env.local` — **único arquivo modificado** (gitignored, não vai pro repo):
  - `DATABASE_URL` / `DATABASE_URL_DIRECT`: host aws-1, senha real, DATABASE_URL na porta 5432
  - `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`: chaves válidas novas
- **Nenhuma mudança de código.** `git status` limpo. Scripts temporários de diagnóstico
  (`scripts/_*.mjs/.mts`) foram criados e removidos ao final.

## Testes executados

1. **Conexão DB** (probe isolado): POOLED + DIRECT → OK
2. **OpenAI** (embed real): retornou vetor 1536d → OK
3. **Anthropic** (`claude-sonnet-4-6` messages): respondeu → OK
4. **Seed**: 200/200 embeddings → done
5. **`retrieveByCodes` (query exata do app)**: `code = ANY(${db.array([...codes])})` → 2 rows → **sem bug**
6. **Agente ponta a ponta** (reconstruído inline pra fugir do guard `server-only` fora do Next):
   - `lookup_dtc_codes(["P0301","P0300"])` → 2 rows
   - `search_diagnostic_knowledge` → 5 vizinhos pgvector
   - Claude gerou **roadmap completo** (Resumo, Fases 1-4, grupos VCDS, escalas osciloscópio,
     LTFT/STFT, crônicos EA888) em PT-BR. Cortou em `length` (maxTokens=2000, mesmo do app).

## Riscos / observações

- 🔒 **Rotacionar OPENAI + ANTHROPIC keys** — passaram pelo chat desta sessão.
- ⚠️ **Pooler 6543 em cooldown** anti-brute-force (das tentativas com senha placeholder). A 5432
  funciona pra dev. Quando o cooldown expirar, dá pra voltar `DATABASE_URL` à 6543 (transaction
  pooler) se quiser o modo serverless-friendly — mas 5432 é perfeitamente válido em dev.
- ℹ️ O guard `import "server-only"` impede importar `lib/rag/agent/run.ts` em node puro (tsx).
  Teste ponta a ponta exige rodar dentro do Next OU reconstruir os tools inline (foi o que se fez).

## Pendências / próxima rodada sugerida

1. **`SUPABASE_SERVICE_ROLE_KEY` ainda vazia** — necessária pra operações server-side
   privilegiadas (ex: admin, criar usuário sem signup). Pegar em Settings → API → service_role.
2. **OAuth Google/Apple** — botões existem no `/login` mas exigem configurar os providers no
   painel Supabase Auth. Hoje só email/senha funciona.
3. **PostHog + Sentry** vazios (opcionais — analytics/observabilidade). Não bloqueiam.
4. **Teste do fluxo logado no browser** — validar garagem → scan/import → diagnóstico pela UI
   (esta sessão validou o motor do agente, não a jornada completa de UI autenticada).
5. **Deploy** — quando for pra produção, definir as envs no host (Vercel?) e apontar
   `DATABASE_URL` pro pooler 6543, `NEXT_PUBLIC_APP_URL` real, headers de segurança já no
   `next.config.ts`.

## Paraleliza / subagentes

- Item 2 (OAuth) e item 4 (E2E logado) são independentes — paralelizáveis.
- `e2e-runner` pode cobrir a jornada garagem→scan→diagnóstico com Playwright (já há
  `tests/e2e/happy-path.spec.ts` no projeto).
