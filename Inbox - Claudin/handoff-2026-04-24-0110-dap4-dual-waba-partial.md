---
type: handoff
date: 2026-04-24
time: 01:10
project: DAP4 + portal-familia
topic: Dual-WABA (Bosch+Prime) metade feita + Design System v1.0 instalado + avaliação pasta Manus
tags: [handoff, claudin, dap4, portal-familia, dual-waba, design-system]
---

# Handoff — DAP4 Dual-WABA parcial + Design System v1.0 (portal-familia)

## Contexto

Sessão longa com 3 temas encadeados:

1. **Avaliação da pasta `Downloads/Evaluate These Documents/`** — Thales pediu review de ~120 arquivos (MDs estratégicos + código React/TS + Python scripts + Excel + PNGs) recebidos provavelmente de consultoria Manus. Conclusão: 80% duplicado do que já existe em produção (DAP4 + PITOS). Vale extrair 3 ativos (schema.ts denso, webhook HMAC de referência, conceito CRM Duplo/Pescadora). **RED FLAG crítico:** senha Supabase em texto puro em `package.json` linha 46 (`acuufrgoyjwzlyhopaus.supabase.co:5432` — rotacionar se for projeto dele).

2. **Meta dual-WABA (2 linhas WhatsApp: Bosch + Prime)** — Thales quer finalizar DAP4 com as 2 vias. Arquitetura travada: **2 WABAs em 2 Apps Meta separadas**, convenção env `META_<FIELD>_<BRAND_UPPER>` (ex: `META_PHONE_NUMBER_ID_DAP_BOSCH`). Brand IDs canônicos: `dap_prime` (default) e `dap_bosch`. Kommo pipelines confirmados: `dap_prime=12704980`, `dap_bosch=12717900`. Dados Bosch que ele forneceu: App ID `182798804924837`, número `+5511 3824-0025` (=`551138240025`). **Pendentes dele:** Phone Number IDs, App Secrets, Access Tokens das 2 Apps.

3. **Design System DAP 4.0 v1.0** — Thales colou o handoff completo do novo sistema de identidade (paleta preto `#050505` / off-white `#efeae0` / vermelho Porsche `#e10600`, fontes Archivo Black + JetBrains Mono + Inter, sistema Nike SB de 11 módulos). Instalei os tokens no portal-familia, refatorei LoginPage + PublicLayout + Splash. **PR #5 mergeado** — visível em master.

## O que funcionou (com evidência)

- **Avaliação da pasta Manus** — report produzido com keep/reference/trash por cluster; red flag de secret Supabase identificado e confirmado via Read direto do `package.json` linha 46.
- **Python Ana brand-aware** — `/agent/ana/chat` aceita `brand_id`, patcha system prompt via `RtbmLoader`, stampa metadata. **PR #6 aberto** (https://github.com/toliveira1802-sketch/dap4/pull/6). Evidência: `pytest api/tests/test_chat_brand_id.py` 5/5 green · `pytest tests/` 147/147 green · `pytest api/tests/` 17/17 green.
- **Design System v1.0 instalado em portal-familia** — PR #5 merged (commit c9f4b85). `DAP_DESIGN_SYSTEM.md` na raiz, `dap-identity.css` com tokens + utility classes, fontes Archivo carregadas no `index.html`. LoginPage + PublicLayout + Splash refatorados. Evidência: 54/54 vitest green + screenshot visual em `login-dap-v1-polished.png` (ticker superior pulsante, wordmark `DAP.4.0`, CTA vermelho, inputs editoriais bottom-border).
- **Dev-only `?preview=1`** — flag em `ProtectedRoute`/`PublicOnlyRoute` pra QA visual sem Supabase resolvido. Gated por `import.meta.env.DEV`.

## O que NÃO funcionou (e por quê)

- **Gateway side do dual-WABA** — cheguei a refatorar `meta-whatsapp.service.ts` (stateless por brand), criar `meta-brands.ts` + testes (22 tests green), atualizar `meta-webhook.routes.ts` (paths `/api/meta/webhook/:brand`), `meta.routes.ts`, `leads.store.ts`, `index.ts` health check. **Tudo perdido** — git reflog mostrou checkouts acidentais entre branches (`master` → `feat/parts-odin` → `master`) durante meus edits, que substituíram arquivos rastreados. Os untracked (`meta-brands.ts`, seu teste) também sumiram (provável `git clean` em algum ponto). Code voltou ao single-tenant.

- **AuthContext do portal-familia trava em `isLoading=true`** — `supabase.auth.getSession()` não resolve no meu ambiente local. Supabase responde (curl retorna 401 em 300ms), mas o promise dentro do AuthProvider fica pendente. **Pré-existente, não é do Design System refactor.** Pode afetar usuário real em prod.

- **Tentativa de typecheck no portal-familia** — `pnpm typecheck` falha com `TS6310: Referenced project 'tsconfig.node.json' may not disable emit`. Pre-existente, não do meu refactor. `pnpm test` + `pnpm build` funcionam normal.

- **3 edits de Edit em arquivos não-lidos** — esqueci de dar Read em `conversation.py` e um em `.claude/.../MEMORY.md` antes de Edit. Tool rejeitou. Corrigi com Read+Edit/Write. Fricção pura, não loss.

## O que ainda não foi tentado

- **Recriar o gateway dual-WABA em branch isolado** — todo o conteúdo está em contexto desta sessão (meta-brands.ts com 150 linhas + 14 testes, meta-whatsapp.service.ts refatorado com 400+ linhas, meta-webhook.routes.ts com /brand paths, meta.routes.ts com `line` param, meta-media.service.ts brand-aware, .env.example com dual envs). Próxima sessão pode recriar em ~30min com o material do contexto OU via `gh pr view 6` + cherry-pick da branch atual.
- **Investigar o AuthContext travado** — adicionar logs dentro do `useEffect` bootstrap, medir onde exatamente trava (antes/depois do `getSession`, dentro do `onAuthStateChange`). Pode ser subscription vazando ou profile fetch infinito.
- **AppShell/Sidebar/Home do portal-familia com identidade DAP** — próxima superfície da migração visual. Nike SB nos links de nav (`/01 CONSULTOR`, `/02 GESTÃO`…).

## Arquivos tocados

### DAP4 repo (`C:\dev\dap4`)

| Arquivo | Status | Notas |
|---------|--------|-------|
| `agents/models/conversation.py` | ✅ Completo — em `feat/ana-brand-id` (PR #6) | ChatRequest ganha `brand_id`/`client_name`/`client_phone` opcionais |
| `agents/api/routes/chat.py` | ✅ Completo — PR #6 | RTBM patch via RtbmLoader quando brand_id presente, metadata stamping, fail-closed 400/503 |
| `agents/api/tests/test_chat_brand_id.py` | ✅ Completo — PR #6 | 5 testes: no brand (no-op), com brand (inject+stamp), missing RTBM (503), invalid (400), {{RTBM}} substitution |
| `DAP_DESIGN_SYSTEM.md` (raiz) | ✅ Completo — em master via PR #5 | Fonte canônica do design v1.0 |
| `portal-familia/src/styles/dap-identity.css` | ✅ Completo — master | Tokens + 20 utility classes (h-display, mono-label, wordmark, module-card, stat, ticker, corner-marks, btn-primary-dap) |
| `portal-familia/src/styles/globals.css` | ✅ Completo — master | @import dap-identity.css + autofill override |
| `portal-familia/index.html` | ✅ Completo — master | Archivo 400-900 adicionado |
| `portal-familia/src/features/auth/LoginPage.tsx` | ✅ Completo — master | Redesign total: label §, wordmark DAP.4.0, inputs editoriais, CTA vermelho |
| `portal-familia/src/layouts/PublicLayout.tsx` | ✅ Completo — master | Ticker + footer editorial |
| `portal-familia/src/components/Splash.tsx` | ✅ Completo — master | DAP.4.0 + dot vermelho pulsante |
| `portal-familia/src/router/ProtectedRoute.tsx` | ✅ Completo — master | Dev-only `?preview=1` bypass em ambos guards |
| `gateway/src/services/meta-whatsapp.service.ts` | ❌ Perdido | Refatoração stateless por brand precisa ser refeita |
| `gateway/src/config/meta-brands.ts` | ❌ Perdido (nunca commitado) | 150 linhas + 14 testes — recriar |
| `gateway/src/routes/meta-webhook.routes.ts` | ❌ Perdido | Path-scoped `/:brand` + fallback `/` via reverse lookup |
| `gateway/src/routes/meta.routes.ts` | ❌ Perdido | `/send`, `/template`, `/status` com `line` param |
| `gateway/src/services/meta-media.service.ts` | ❌ Perdido | accessToken por brand |
| `gateway/src/stores/leads.store.ts` | ❌ Perdido | Normalize brand via meta-brands |
| `gateway/src/index.ts` | ❌ Perdido | Health check usando listConfiguredBrands |
| `.env.example` | ❌ Perdido | Docs duais dap_prime + dap_bosch |

## Decisões tomadas

- **2 WABAs em 2 Apps Meta** (não 1 App com 2 números) — confirmado pelo Thales. Implica `app_secret` diferente por brand → webhook precisa de path scoped `/api/meta/webhook/:brand` pra saber qual secret usar antes do HMAC.
- **Convenção env `META_<FIELD>_<BRAND_UPPER>`** — alinha com brand_id canônico. Legacy unsuffixed (`META_PHONE_NUMBER_ID`, etc) aceito só como fallback pro default brand (dap_prime) durante migração.
- **Ana `/agent/ana/chat` NÃO substituída por `/kommo-chat`** — mantida a rota legada, só adicionado `brand_id` opcional. `kommo-chat` tem contrato diferente (kommo_lead_id required). Mudar no gateway webhook depois seria quebrar muito.
- **Design System instalado non-destrutivo** — `dap-identity.css` separado de `tokens.css` (antigo shadcn/indigo/gold). Migração página-a-página, não big-bang. Tokens antigos convivem pro shadcn não quebrar.
- **PR dividido em 2 partes** — Python (PR #6 aberto) separado do gateway (pendente). Python sozinho é no-op enquanto gateway não passar `brand_id` — seguro pra merge.
- **Avaliação da pasta Manus = TRASH 80%** — só 3 ativos valem keep (schema.ts denso, webhook.ts HMAC reference, conceito CRM Duplo).

## Bloqueios & perguntas abertas

- **Credenciais Meta das 2 Apps pendentes** — Thales ainda precisa fornecer Phone Number IDs, App Secrets, Access Tokens (System User permanentes) das duas WABAs. Sem isso o gateway side não tem o que testar em smoke.
- **Supabase `acuufrgoyjwzlyhopaus.supabase.co`** — apareceu na pasta Manus (`package.json` linha 46 com senha em claro) E no `.env.local` do portal-familia. Se é o mesmo projeto, senha pode estar vazada. **Verificar e rotacionar se aplicável.**
- **AuthContext travado** — bloqueio pra QA visual de qualquer página autenticada. Pode afetar usuários reais em prod. Investigação não iniciada.
- **Typecheck portal-familia** — TS6310 em `tsconfig.node.json`. Fix é 1 linha, pendente.
- **Parte gateway do dual-WABA perdida** — decisão do Thales: recriar agora ou deixar pra quando tiver as credenciais Meta em mãos.

## Próximo passo exato

Abrir nova sessão e escolher **uma** de:

1. **Continuar dual-WABA (gateway side)** — recriar `gateway/src/config/meta-brands.ts` com TDD (14 testes de `resolveMetaConfigForBrand`, `resolveBrandFromPhoneNumberId`, `listConfiguredBrands`) em branch nova `feat/gateway-dual-waba` a partir de master. Conteúdo exato está nos arquivos desta sessão. Merge só quando Thales entregar os 2 pares de `META_PHONE_NUMBER_ID_DAP_*` + `META_APP_SECRET_DAP_*`.

2. **Investigar AuthContext travado** — abrir `portal-familia/src/contexts/AuthContext.tsx`, adicionar `console.log` em 4 pontos do `useEffect` bootstrap (antes do getSession, após, dentro do `loadSessionAndProfile`, no `setIsLoading(false)`), rodar `pnpm dev`, abrir `/home` no browser, ver no console onde parou.

3. **Continuar migração visual portal-familia** — refatorar `AppShell.tsx` + `Sidebar.tsx` + `TopBar.tsx` com identidade DAP (Nike SB nos nav links, wordmark no topo, mono labels). Preview via `?preview=1`.

Recomendação: começar com **#2 (AuthContext)** — 15min, bloqueio real que afeta prod. Depois #1 quando credenciais Meta chegarem.

## Setup / comandos úteis

```bash
# DAP4 agents tests
cd C:\dev\dap4\agents
python -m pytest api/tests/test_chat_brand_id.py -v    # 5 testes brand_id
python -m pytest tests/ --tb=short                     # 147 suite base
python -m pytest api/tests/ --tb=short                 # 17 api routes

# Portal-familia
cd C:\dev\dap4\portal-familia
pnpm dev                # :5174
pnpm test               # 54/54 green
# URL dev-only pra preview visual sem Supabase resolvido:
# http://localhost:5174/login?preview=1
# http://localhost:5174/home?preview=1

# Git state atual
cd C:\dev\dap4
git branch --show-current    # deve ser master
git log --oneline -3         # c9f4b85 (design system) top
gh pr view 6                 # PR dual-WABA Python aberto
```

**Branches relevantes:**
- `master` — limpo, contém PR #5 (Design System) mergeado
- `feat/ana-brand-id` — PR #6 aberto com Python dual-WABA
- `feat/meta-dual-waba` — existe local mas vazia, pode deletar: `git branch -D feat/meta-dual-waba`
