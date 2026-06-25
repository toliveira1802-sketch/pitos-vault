---
type: handoff
date: 2026-05-01
time: 16:30
project: dap-operacao
topic: Auditoria oficina-pro vs dap-aios + rebrand para DAP Operação
tags: [handoff, claudin, dap-operacao, dap-aios, rebrand]
---

# Handoff — DAP Operação (ex-oficina-pro)

## Contexto

Thales mostrou pasta `oficina-pro` em OneDrive Desktop e perguntou se valia fundir com `dap-aios` (em `C:\dev\dap-aios`). Era preciso (1) auditar/comparar as duas stacks e (2) rodar no browser pra confirmar maturidade. Depois da auditoria, decidiu padronizar naming pro ecossistema DAP — mas FORA de `C:\dev`. Sessão terminou com a pasta renomeada, repo GitHub renomeado, rebrand visual completo, commit + push.

A peça é candidata a ser o **portal de operação** do DAP — sistema interno de gestão de oficina (CRM, OS, kanban de pátio, agenda, financeiro). Domínio futuro: `operacao.doctorautoprime40.com`.

## O que funcionou (com evidência)

- **Auditoria comparativa oficina-pro vs dap-aios** — agent code-explorer rodou e produziu tabela de diff. Evidência: oficina-pro tem 12 tabelas + 51 endpoints + 9 telas reais; dap-aios tem 1 tabela stub + 0 endpoints + tudo mockup inline em App.tsx. Sentença: oficina-pro é o pai, dap-aios é doador de UI.
- **Dev server local** — `npm run dev` levantou Express+Vite em `http://localhost:5000`, HTTP 200, "serving on port 5000".
- **Login funcional** — admin/admin123 (3 usuários seed: admin/tecnico/recepcao com senhas `<role>123`, hardcoded em `server/routes.ts:90-95`).
- **Telas validadas via Playwright** — Dashboard (8 OS, 4 clientes, 4 veículos, contadores por status), Pátio Kanban (5 colunas drag-friendly), Lista de Ordens (tier do cliente, status colorido), OS Detail (#3 Audi A4 com veículo + cliente + financeiro + diagnóstico + mover-status + tempo no pátio "8d 1h").
- **Rename da pasta** — Funcionou após matar processos tsx/esbuild + retry loop com 2s de backoff (OneDrive Sync segurava transitoriamente). Renomeado de primeira no retry #1.
- **Rename do repo no GitHub** — `gh repo rename dap-operacao` ok. URL agora `github.com/toliveira1802-sketch/dap-operacao`.
- **Update do remote local** — `git remote set-url origin <new-url>`, `git ls-remote` confirmou conectividade.
- **Rebrand visual** — Title HTML + meta + sidebar logo + login header + tagline. Validado via Playwright reabrindo browser pós-edit (Vite HMR pegou).
- **Commit + push** — `2d0f8b3 chore: rebrand OficinaPro → DAP Operação` em `feat/os-detail`. Push pra origin OK.

## O que NÃO funcionou (e por quê)

- **`Rename-Item` direto na pasta** — Falhou com "está em uso". Causa: processos `tsx` + `esbuild` derivados do `npm run dev` ficam vivos depois que `TaskStop` mata o pai. Tive que matar PID 21196 (tsx loader) + 26692 (preflight) + 15224 (esbuild) explicitamente via `Stop-Process -Id`.
- **Segundo rename após matar processos** — Ainda falhou. Causa: OneDrive Sync engine segurando lock transitório. Fix: retry loop com `Start-Sleep -Seconds 2`. Resolveu no #1.
- **`WebFetch` em `http://localhost:5000`** — Erro "Invalid URL". WebFetch não aceita localhost sem hostname público. Workaround: usar `curl 127.0.0.1` direto via Bash.
- **`node -e "require('better-sqlite3')"`** — `MODULE_NOT_FOUND`. Causa: oficina-pro usa `@libsql/client`, não `better-sqlite3`. Para inspecionar SQLite na linha de comando precisa: `node --input-type=module -e "import {createClient} from '@libsql/client'..."`.

## O que ainda não foi tentado

- **Trazer UI de portais do dap-aios** — A estrutura de portais (Gestao/Consultor/Mecanico/Cliente/AIOS) + sidebar com 12 diretores Sennin existe em `dap-aios/client/src/App.tsx:537-1031` como mockup. Plano original: copiar pra rota `/portais` de dap-operacao depois do rebrand fechado.
- **Provisionar subdomínio `operacao.doctorautoprime40.com`** — Cloudflare DNS + tunnel + reverse proxy ainda não tocados. Cloudflare Tunnel `dap4` na VPS já existe mas precisa adicionar hostname + ingress.
- **Decidir merge de `feat/os-detail` → master** — Branch tem fluxo completo de OS (wizard, drawer, detalhe world-class) + agora o rebrand. Não foi mergeada.
- **Migração de `oficina.db` SQLite local → Supabase Postgres** — Hoje roda em SQLite file-based. Para integrar com Parliament/Sennin no futuro precisaria mesmo Postgres do DAP4 (schema `DOCTOR_PRIME` ou novo `OPERACAO`).
- **Auth integrada ao Parliament** — Hoje session+passport+bcrypt local. Se virar módulo do DAP4 depois, integrar com auth do gateway.
- **Limpar dap-aios** — Após confirmar fusão, considerar arquivar `C:\dev\dap-aios` ou marcar como deprecated. Memory dela continua presente.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\Users\docto\OneDrive\Área de Trabalho\oficina-pro\` (pasta) | Renomeada → `dap-operacao` | Subpasta órfã interna `oficina-pro/` (74KB stub git) deletada |
| `package.json` | Completo | `name: rest-express → dap-operacao` |
| `client/index.html` | Completo | Title + meta description |
| `client/src/components/app-sidebar.tsx:45` | Completo | Logo "OficinaPro" → "DAP Operação" |
| `client/src/pages/login.tsx:35-36` | Completo | Header + tagline ("Oficina + CRM") |
| Repo GitHub | Renomeado | `oficina-pro → dap-operacao` (redirect ativo no GitHub) |
| Remote local `origin` | Atualizado | Nova URL configurada |
| Branch `feat/os-detail` | 1 commit ahead pushed | Commit `2d0f8b3` |

## Decisões tomadas

- **Pai da fusão = oficina-pro** — razão: 12 tabelas vs 1 stub, 51 endpoints vs 0, 9 telas reais vs 0, auth+upload+PDF funcionais. dap-aios é wireframe interativo por design (CLAUDE.md dele diz "frontend-first prototype").
- **Localização: OneDrive Desktop, NÃO em `C:\dev`** — escolha explícita do Thales. OneDrive sync foi gargalo no rename mas não é bloqueador.
- **Naming: `DAP Operação`** — alinha com ecossistema DAP. Subdomínio futuro `operacao.doctorautoprime40.com`.
- **Standalone, não módulo de DAP4** — Thales escolheu opção (B). Roda separado com subdomínio próprio. Schema/auth não compartilhados com Parliament neste momento.
- **Não criar README nem CLAUDE.md** — regra: não gerar docs sem pedido explícito. Repositório segue sem.
- **Não mergear feat/os-detail** — manter em feature branch até decisão futura.

## Bloqueios & perguntas abertas

- **Branch `feat/os-detail` em aberto** — mergear pra master quando? Tem 7 commits do flow de OS + 1 do rebrand. Risco de drift se ficar muito tempo aberta.
- **Subdomínio `operacao.doctorautoprime40.com` não existe** — precisa decisão sobre onde hospedar (VPS Hostinger 76.13.170.42 igual DAP4? ou Vercel/Railway separado?).
- **Conflito naming "Sophia"** — em dap-aios é página/rota UI; em DAP4 é agente Parliament. Se trouxer estrutura de portais do dap-aios, decidir se mantém o nome Sophia ou renomeia.
- **Source-of-truth do dap-aios** — memory diz "não editar local exceto CLAUDE.md, cada zip Perplexity = checkpoint". Trazer código do dap-aios pra dap-operacao quebra esse contrato. Validar com Thales antes.
- **Senhas seed hardcoded** — `admin123/tecnico123/recepcao123` em `server/routes.ts`. Aceitável pra dev local; precisa rotacionar antes de subir prod.

## Próximo passo exato

**Quando voltar:** decidir entre dois caminhos:

1. **Caminho fácil (1-2h):** trazer UI de portais do dap-aios (`App.tsx:537-1031`) como rota `/portais` em dap-operacao. Não toca schema, não toca backend. Frontend-only. Já valida que o rebrand "ficou" e dá UI de navegação multi-portal.

2. **Caminho deploy (4-8h):** subir `dap-operacao` em produção com subdomínio `operacao.doctorautoprime40.com`. Provisionar CF DNS + tunnel + ingress + build pipeline. SQLite local pode continuar (file `oficina.db`) ou migrar pra Supabase Postgres com schema próprio.

**Recomendação:** caminho 1 primeiro. É reversível, mostra progresso visível, e não exige decisões de infra.

## Setup / comandos úteis

```powershell
# Path do projeto
cd "C:\Users\docto\OneDrive\Área de Trabalho\dap-operacao"

# Dev server (porta 5000)
npm run dev

# Credenciais demo
admin / admin123
tecnico / tecnico123
recepcao / recepcao123

# Inspecionar SQLite (via libsql client)
node --input-type=module -e "import {createClient} from '@libsql/client';const c=createClient({url:'file:./oficina.db'});const t=await c.execute(\"SELECT name FROM sqlite_master WHERE type='table'\");console.log(t.rows.map(r=>r.name));"

# Build prod
npm run build  # → dist/index.cjs
npm start      # NODE_ENV=production node dist/index.cjs
```

**Repo:** `github.com/toliveira1802-sketch/dap-operacao`
**Branch ativa:** `feat/os-detail` (já pushed, sincronizada)
**Último commit:** `2d0f8b3 chore: rebrand OficinaPro → DAP Operação`
