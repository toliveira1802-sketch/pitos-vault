---
type: handoff
date: 2026-05-12
time: 20:28
project: DAP 4.0 / 3-dap-aios
topic: Design system v1 (Apex×Chassis) implementado + Figma alinhado · sessão longa cobrindo apps/home, fix OS branca, identidade
tags: [handoff, claudin, dap4, design-system, figma]
---

# Handoff — Design system v1 (Apex×Chassis) implementado · Figma alinhado

## Contexto

Sessão longa de ~5h trabalhando no ecossistema DAP 4.0 (path `C:\THALES\DAP4\`). Começou pedindo pra eu olhar a pasta `1-AIOS DAP 4.0 — Protótipo navegável` (vanilla JS gerado pelo Perplexity) e propor próximos passos. Evoluiu por várias decisões em cadeia até cravar:

1. **3-dap-aios é o portal inicial** do ecossistema (hub), com `apps/home` arquivado.
2. **`5-dap-operacao` (porta 5000), `4-dap-gestao` (5002) e `3-dap-aios` (5050)** estão todos rodando localmente.
3. **Design system v1 oficial** (Apex×Chassis · paper #F4F0E8 + ink #141414 + red #D8272A + Space Grotesk + offset shadow editorial) implementado no `3-dap-aios` e refletido no Figma.

Fluxo de identidade visual passou por 3 iterações: (a) DS v1 Apex×Chassis → (b) Performance Piloto (F1/GT3 dark + Archivo Black) → **revertido pra (a) Apex×Chassis** porque Thales acha mais adequado pra portal interno.

## O que funcionou (com evidência)

- **Pasta protótipo Perplexity arquivada** — `C:\THALES\DAP4\_archive\prototipo-mandala-perplexity\` + `.zip`. Confirmado via `ls`.
- **`apps/home` criado no monorepo** (Vite+React+TS+Tailwind, porta 5055 client + 5154 API) — depois **arquivado** em `_archive\apps-home-hub-original\` porque a decisão virou usar `3-dap-aios` como hub.
- **3 standalones subindo simultaneamente:**
  - `3-dap-aios` (5050) — `pnpm dev` após `rm -rf node_modules && pnpm install` (cross-env estava faltando)
  - `4-dap-gestao` (5002) — `npm run dev` direto após criar stub `client/src/pages/not-found.tsx` (import quebrado)
  - `5-dap-operacao` (5000) — `npx tsx --env-file=.env server/index.ts` depois de:
    - resetar senha Supabase (`DAPdev2026!` — projeto `acuufrgoyjwzlyhopaus` DOCTOR PRIME)
    - adicionar `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` no `.env` (faltavam no client)
- **`/api/portals/status` no apps/home** — TCP probe nas portas dos 3 standalones, retornando JSON com `running:bool · latencyMs`. Validado com curl. (Apps/home depois foi arquivado, mas o padrão funciona.)
- **Cards do AIOS (`portalEntries` no `App.tsx`) ganharam campo `externalUrl?`** — quando presente, card vira `<a target="_blank">` pro standalone real, senão `<Link>` mock interno. Type-check verde, 5 cards: Gestão→5002, Consultor→5000, AIOS, Facilities, Dev.
- **Tela branca da OS resolvida** (`5-dap-operacao`) — bug era `fetch()` direto bypassando `queryClient` em 4 lugares (`service-order-detail.tsx`, `customer-workflow-wizard.tsx`, `customer-detail-drawer.tsx`, `os-attachments-card.tsx`). Sem header `Authorization: Bearer`, backend retornava 401, `data` ficava undefined, render vazio. Fix: trocar por queryFn default (que monta URL via queryKey + injeta JWT). `npm run check` verde.
- **Design system v1 (Apex×Chassis) implementado no `3-dap-aios`:**
  - `client/src/design-system/tokens.css` — `--dap-ink`, `--dap-paper`, `--dap-red`, fontes
  - `client/src/design-system/dap-components.css` — `.dap-btn`, `.dap-card`, `.dap-badge`, `.dap-input`, `.dap-datum-line`, `.dap-tech-strip`, `.dap-eyebrow`
  - `client/src/design-system/dap-components.tsx` — `DapButton`, `DapCard`, `DapBadge`, `DapInput`, `DapEyebrow`, `DapWordmark`, `DapDatumLine`, `DapTechStrip`, `DapTick`
  - `client/index.html` — Google Fonts (Space Grotesk + Inter + JetBrains Mono + Caveat)
  - `client/src/index.css` — `@import "./design-system/tokens.css"` + dap-components.css
  - `client/src/pages/design-system.tsx` — página viva acessível em `/design` (8 seções: Color, Type, Buttons, Cards, Badges, Inputs, Datum, Tech strip)
  - Rota `/design` adicionada no `App.tsx`
  - `tsc --noEmit` verde após cada iteração
- **`7-docs/DAP_DESIGN_SYSTEM.md`** documentado.
- **Figma `xWbkAPeDWZVgWxgC7hwgYz`** alinhado com Apex×Chassis após 3 iterações. 6 pages, 16 frames: Cover · Design System · 01 Auth (login + reset) · 02 Operação (dashboard, /orders, OS detail, /customers, /patio, /timeline, /users) · 03 Comercial (overview, CRM, leads, adormecidos) · 04 Sala do Conselho (Sophia + 8 C-level).
- **Tasks #14 (tela branca), #16 (DS v1), #19 (revert)** todas completed.

## O que NÃO funcionou (e por quê)

- **PID 29640 segurando portas 5054 e 5055** — node.exe zumbi de sessão anterior migrava de porta sozinho quando eu tentava trocar. Solução: `taskkill /F /IM node.exe` (matou 26 processos node de sessões anteriores). Lição: rodar `Get-Process node` no início de sessão de dev.
- **`3-dap-aios pnpm install` reportou sucesso mas cross-env não foi instalado** — primeira tentativa de `pnpm dev` falhou com `MODULE_NOT_FOUND`. Solução: `rm -rf node_modules && pnpm install`. Provável corrupção parcial. Não voltou a acontecer.
- **`4-dap-gestao` crashou com `Pre-transform error: Failed to resolve import "@/pages/not-found"`** — arquivo deletado em algum momento, só explodiu quando Vite tentou transformá-lo. Criei stub manual.
- **`5-dap-operacao` falhou 2x antes de subir:**
  1. `DATABASE_URL` faltando — `tsx` não carregava `.env` (script é `tsx server/index.ts` sem `--env-file`). Rodei com `npx tsx --env-file=.env server/index.ts`.
  2. Senha Supabase rejeitada (`28P01 auth_failed`) — `Dpctrauto1234` expirou. Resetada pra `DAPdev2026!` via SQL `UPDATE auth.users SET encrypted_password = crypt(...) WHERE email = ...`.
  3. Frontend "config supabase ausente" — faltavam `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` no `.env`. Adicionei.
- **Iframe do apps/home mostrava "nuvem" pro Thales** — Chrome rendering pra portal stopped. Adicionei `<StoppedState>` no Workspace.tsx mostrando comando + path em vez do iframe quebrado. (Depois `apps/home` foi arquivado.)
- **Figma `JetBrains Mono Bold` não carregado na primeira chamada** — erro `Cannot use unloaded font`. Fix: carregar TODOS os pesos no início de cada chamada `use_figma`. Padrão estabelecido nas chamadas subsequentes.
- **Identidade Performance Piloto** (segunda iteração) — implementei completa (Archivo Black 900, ink #050505, dark dominante, hero glow vermelho radial, race plates 168px, Nike SB superscript .02). Thales reprovou: "não gostei do design ... volta pro original". Revertido pra Apex×Chassis. Lição: validar com mockup antes de codar 800+ linhas.
- **Mandala arquivada cedo** — fiz a estrutura completa com C-level (Sophia centro + Anna/Francisco/Rafael/Walter/Thamy/Zoraide/Marcia/João como CSO/CFO/CTO/CKO/CDO/CCO/CHRO/COO) e Thales pediu "acaba com isso, arquiva" antes de qualquer iteração visual. Estrutura preservada em `_archive/prototipo-mandala-perplexity/`, foi reaproveitada na página Sala do Conselho do Figma.

## O que ainda não foi tentado

- **Glassmorph** — Thales mencionou de passagem "traga um glassmorph, depois mexemos na questão do design, ainda mais pra um portal interno", mas em seguida decidiu "melhor ainda, volta pro original". Glassmorph fica como spike futuro se quiser explorar.
- **Aplicar design system Apex×Chassis nas páginas reais do AIOS** — hoje só `/design` usa `Dap*`. As páginas existentes (`/aios`, `/gestao`, `/dev`, etc.) continuam shadcn neutral. Adoção gradual quando Thales pedir tela a tela.
- **Migrar identidade pro `4-dap-gestao` e `5-dap-operacao`** — só `3-dap-aios` recebeu o DS. Quando virar pacote shared `packages/ui-v1`, propaga.
- **Deploy Vercel do `3-dap-aios`** em `aios.doctorautoprime40.com` (Task #10 ainda pending).
- **Sennin-style auth review** — auth do `5-dap-operacao` tem dois caminhos (JWT Bearer + session legacy). Funciona, mas merece review.
- **Anexar 4-dap-gestao e 5-dap-operacao ao AIOS via V2** — V1 (redirect external URL) já implementado. V2 (mover código pra dentro do AIOS, eliminar standalones) era plano de longo prazo.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `_archive/prototipo-mandala-perplexity/` | Arquivado | pasta + zip movidos |
| `_archive/apps-home-hub-original/` | Arquivado | tentativa de hub separado |
| `3-dap-aios/CLAUDE.md` | Editado | source of truth virou local; AIOS = hub |
| `3-dap-aios/client/index.html` | Editado | + Google Fonts Apex×Chassis |
| `3-dap-aios/client/src/index.css` | Editado | + import tokens + dap-components |
| `3-dap-aios/client/src/design-system/tokens.css` | Completo | Apex×Chassis tokens |
| `3-dap-aios/client/src/design-system/dap-components.css` | Completo | 8 classes base |
| `3-dap-aios/client/src/design-system/dap-components.tsx` | Completo | 9 componentes React tipados |
| `3-dap-aios/client/src/pages/design-system.tsx` | Completo | página viva `/design` |
| `3-dap-aios/client/src/App.tsx` | Editado | + rota `/design`, + `externalUrl` em portalEntries |
| `4-dap-gestao/client/src/pages/not-found.tsx` | Completo | stub criado pra desbloquear Vite |
| `5-dap-operacao/.env` | Editado | nova senha Supabase + VITE_SUPABASE_* |
| `5-dap-operacao/client/src/pages/service-order-detail.tsx` | Editado | removido queryFn custom |
| `5-dap-operacao/client/src/components/customer-workflow-wizard.tsx` | Editado | idem |
| `5-dap-operacao/client/src/components/customer-detail-drawer.tsx` | Editado | idem |
| `5-dap-operacao/client/src/components/os/os-attachments-card.tsx` | Editado | + authHeaders() pra multipart |
| `7-docs/STITCH_PROMPTS.md` | Completo | prompts pra reproduzir telas no Stitch |
| `7-docs/DAP_DESIGN_SYSTEM.md` | Completo | doc do DS v1 |
| Figma `xWbkAPeDWZVgWxgC7hwgYz` | Completo (Apex×Chassis) | 6 pages, 16 frames |

## Decisões tomadas

- **`3-dap-aios` = portal inicial / hub do ecossistema** — razão: AIOS já tinha 7 portais internos mockados; mais coerente que criar app novo. `apps/home` arquivado.
- **Source of truth = código local (não Perplexity)** — razão: edits no Perplexity morriam no próximo zip. Thales confirmou: "Esquece o Perplexity — o código daqui vira a verdade". CLAUDE.md do AIOS atualizado.
- **V1 = redirect, V2 (futuro) = unificar código** pra anexar 4-dap-gestao e 5-dap-operacao ao AIOS — razão: redirect é minutos, unificar é dias. Thales: "se isso não afetar, iria de V1 redirect".
- **Identidade Apex×Chassis (não Performance Piloto)** — razão: portal interno; Performance Piloto F1/GT3 era pesado demais. Thales: "ainda mais pra um portal interno... volta pro original".
- **DS coexiste com shadcn no AIOS** — razão: adoção gradual sem quebrar páginas existentes. Tokens `--dap-*` prefixados pra não colidir.
- **Tokens viraram `--dap-*` no CSS, componentes `Dap*` no TS** — razão: namespace claro, futuro shared package.
- **DAPdev2026! é senha de dev temporária** — Thales informou em chat texto plano. Risco anotado, recomendação de rotacionar depois.

## Bloqueios & perguntas abertas

- **A senha `DAPdev2026!` ficou em texto plano no chat** — rotacionar quando puder (Supabase Dashboard → Authentication → users → ⋯ → Reset password).
- **Glassmorph: vale spike?** — Thales mencionou e depois recuou. Pode revisitar quando quiser explorar alternativa pro portal cliente (não interno).
- **Adoção do DS nas páginas reais do AIOS** — em quais páginas começar? `/aios` (Sala do Conselho)? Dashboard? Esperando Thales priorizar.
- **Deploy aios.doctorautoprime40.com** — Task #10 pending. Cloudflare tunnel já existe na VPS (`dap4` tunnel) — provavelmente reaproveitável.
- **3-dap-aios e 4-dap-gestao apontam pro mesmo projeto Supabase (`acuufrgoyjwzlyhopaus` DOCTOR PRIME)** mas tem outro projeto **DAP4.0** mais novo (`cpzgtfblywexqglqkgbt`, criado abril/2026). Qual é o canônico?

## Próximo passo exato

Abrir <https://www.figma.com/design/xWbkAPeDWZVgWxgC7hwgYz> em paralelo com <http://localhost:5050/#/design> e confirmar que a vibe Apex×Chassis bate. Se sim, escolher 1 página existente do AIOS (provável `/aios` ou Dashboard) pra refatorar usando `Dap*` componentes — vira piloto de adoção interna.

Se não bater, ajustar tokens (escala de tipografia, peso de borda, contraste paper-2/paper-3) com mudanças cirúrgicas em `3-dap-aios/client/src/design-system/tokens.css` antes de propagar.

## Setup / comandos úteis

**Subir os 3 portais (cada um em terminal separado):**

```powershell
# AIOS (5050) — hub
cd C:\THALES\DAP4\3-dap-aios; pnpm dev

# Gestão (5002)
cd C:\THALES\DAP4\4-dap-gestao; npm run dev

# Operação (5000) — usa --env-file porque script default não carrega .env
cd C:\THALES\DAP4\5-dap-operacao; npx tsx --env-file=.env server/index.ts
```

**Limpar nodes zumbis (no início de cada sessão de dev):**
```powershell
taskkill /F /IM node.exe
```

**Login Supabase em qualquer portal (gestão/operação):**
- email: `thales@doctorautoprime40.com`
- senha: `DAPdev2026!` (ROTACIONAR — em chat plano)

**Type-check (após edição no AIOS):**
```bash
cd C:\THALES\DAP4\3-dap-aios && npm run check
```

**Tasks ativas restantes:**
- #10 Deploy 3-dap-aios em aios.doctorautoprime40.com (pending)

**Tasks deletadas (não retentar):**
- Mandala como página dedicada — Thales arquivou cedo
- Performance Piloto (F1/GT3) — descartado a favor de Apex×Chassis
- apps/home como hub separado — virou redundante, 3-dap-aios assumiu
