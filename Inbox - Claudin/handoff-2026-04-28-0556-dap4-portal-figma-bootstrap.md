---
type: handoff
date: 2026-04-28
time: 05:56
project: dap-portal-aios
topic: Bootstrap PORTAL DAP4.0 no Figma — board lido, arquitetura mapeada (10 módulos single-app subdomain-aware), Stitch falhou auth, pivot pra Figma, Visão Geral capturada como ponto de partida
tags: [handoff, claudin, dap-portal-aios, figma, dap-4-0, brand]
---

# Handoff — Bootstrap PORTAL DAP4.0 no Figma

## Contexto

Sessão de continuação direta do handoff `2026-04-28-0257-dap4-portal-spike-brand-rollout.md` (Visão Geral aprovada em HTML standalone com brand DAP 4.0 — Apex × Chassis). Objetivo desta sessão: **mover a régua do spike pra um espaço de design formal** onde Thales possa "ver tema a tela".

A sessão começou com Thales colando a lista de subdomínios do ecossistema (`dev/gestao/consultor/mecanico/clientes/aios/facilities.doctorautoprime40.com`), depois mandou um board do Figma (`figma.com/board/Sa2LB7UuRX6BHS48oUPqeU`) com **dois diagramas críticos** que destravaram a arquitetura do spike:

1. **Mapa de subdomínios** — `dev.` como root apontando pros 6 outros subdomínios (gestao/consultor/mecanico/clientes/aios/facilities).
2. **Estrutura interna do `PORTAL DAP4.0`** — 10 módulos top-level: HOME (Dashboard Visão Geral), GESTAO, CONSULTOR (sic), MECANICO, CLIENTES, AIOS, TOOLS, PROCESSOS, PROCEDIMENTOS, DOCS/TEMPLATES.

Minha leitura: **single SPA, subdomain-aware** — `PORTAL DAP4.0` é UMA app com 10 módulos; cada subdomínio é um deep-link de papel que abre direto no módulo daquele role com sidebar/RBAC filtrados. Thales confirmou parte: `facilities` = portal de ferramentas. As outras 3 perguntas (naming, `dev.` launcher vs staging, subrotas, facilities físicas vs digitais) ficaram abertas.

A pedido do Thales ("CONSEGUIMOS COMEÇAR A COLOCAR ESTE PROJETO NO STITCH? PQE AI JA VEMOS TEMA A TELA"), tentei criar projeto no Stitch MCP. Falhou com erro de auth. Pivotamos pra Figma direto (opção B). Resultado: arquivo Figma novo criado com a Visão Geral aprovada importada como pixel-perfect reference frame, pronto pra construir o design system formal por cima.

## O que funcionou (com evidência)

- **Resume do handoff anterior** — evidência: `/resume-handoff` carregou `handoff-2026-04-28-0257-dap4-portal-spike-brand-rollout.md` em uma tacada; estado preservado, próximo passo claro.
- **Leitura do board Figma** — evidência: `mcp__plugin_figma_figma__get_figjam` retornou XML estruturado dos 2 diagramas (subdomínios + 10 módulos) + screenshot inline. Mapa decodificado em 1 chamada.
- **Auth Figma MCP via `/plugin`** — evidência: Thales rodou `/plugin`, retornou "Authentication successful. Connected to plugin:figma:figma". Plans descobertos via `whoami`: `thales oliveira's team` (`team::1601351602264137877`) e `thalao` (`team::1614273624048963804`).
- **Brand guidelines DAP 4.0 lido** — evidência: 296 linhas em `C:\dev\dap-portal-aios-spike\_prompts\brand-guidelines-dap-4-0.md` carregadas. Paleta (ink #141414 / paper #F4F0E8 / red #D8272A com proporção 70/25/5), tipografia (Space Grotesk + Inter + JetBrains Mono + Caveat), 5 direções (Apex/Combustion/Chassis/Night Circuit/Grand Tourer), checklist de publicação confirmados.
- **Servidor python `http.server :8765` ainda vivo** — evidência: `curl localhost:8765/_preview/home-visao-geral.html` → HTTP 200. Continuou rodando desde o handoff anterior.
- **Captura HTML→Figma da Visão Geral aprovada** — evidência: `generate_figma_design` em modo `newFile` + plan `team::1601351602264137877` + capture ID `c656d425-85d1-4bd5-93d3-0dc19cf610ec`; script tag injetado em `home-visao-geral.html`; Chrome MCP abriu `localhost:8765/_preview/home-visao-geral.html#figmacapture=...&figmaendpoint=...&figmadelay=1500`; primeiro poll após 5s retornou status `completed`. Arquivo Figma criado: **https://www.figma.com/design/S9kIkeueS2VeSnyWVqDidV** (fileKey `S9kIkeueS2VeSnyWVqDidV`).
- **Tool schemas carregados via ToolSearch** — evidência: `get_figjam`, `whoami`, `create_new_file`, `generate_figma_design`, `navigate_page`, `new_page`, `wait_for`, `list_pages` todos invocados com sucesso.

## O que NÃO funcionou (e por quê)

- **Stitch MCP `list_projects`** — falhou porque: `Incompatible auth server: does not support dynamic client registration`. O MCP server do Stitch não suporta DCR pra OAuth dinâmico. Não tem tool de auth explícita (`mcp__stitch__authenticate` não existe — só Figma, Slack, HubSpot etc. têm). Plugin precisa ser reconfigurado/reinstalado pra ter Google login funcional. **Não pivotei pra Stitch retry — fui pra Figma direto** (Thales escolheu B explicitamente).
- **Path drift do brand guidelines** — falhou porque: handoff anterior listou `frontend/_prompts/brand-guidelines-dap-4-0.md`, mas o arquivo real está em `_prompts/brand-guidelines-dap-4-0.md` (root do spike, não dentro de frontend). Glob recovered. Verificar próximas refs.
- **Stitch design system aceita só fonts pré-definidas** — falhou porque: schema do `create_design_system` tem enum fechado pros enum `headlineFont`/`bodyFont`/`labelFont`. SPACE_GROTESK + INTER + JETBRAINS_MONO existem ✓, mas Caveat (anotação manuscrita decorativa) NÃO está na enum. Solução planejada (não executada): mencionar Caveat só no `designMd` markdown, deixar fonte funcional via overrides. Caveat é só decorativo (1 ocorrência por composição) — perdível em rough draft. Stitch não foi usado de qualquer jeito, ponto irrelevante por enquanto.

## O que ainda não foi tentado

- **Construir design system formal no Figma** via `use_figma`: variáveis de cor (ink/paper/red/paper-2/graphite/muted), text styles (H1-H4 Space Grotesk + Body Inter + Mono JetBrains UPPER 0.1em tracking), e componentes core (Card border 1.5px ink + offset shadow 8px 8px 0; Button ink/paper sem radius; Badge mono UPPER ink/paper; Input border 1.25px; Sidebar nav-item dark `#0A0A0A`). Skill `figma:figma-use` carregada e schema `use_figma` disponível via ToolSearch.
- **Refazer Visão Geral com components do DS** — a captura é raw frames. Recomendação da tool: usar como pixel-perfect reference, depois rebuild com instances do design system pra ficar exportável via Code Connect.
- **Gerar Chat tela nova** via `use_figma` (3 colunas, mensagens log de terminal, Anna AIOS embarcada no contexto right) — prompt já existe em `_prompts/operacao-chat-colab-claude-design.md` (449 linhas).
- **Capturar/gerar** as outras 8 telas: Pipeline, Mecanico (OS atribuída), Clientes (família portal), Gestao (Faturamento/Produtividade/Previsão), AIOS (Sala do Conselho), Tools (Playbook/Kit Performance), Processos, Procedimentos, Docs/Templates.
- **Atualizar `idea.md`** com a confirmação do board: PORTAL DAP4.0 inteiro (10 módulos), single-app subdomain-aware, naming a confirmar.
- **Responder as 3 perguntas abertas remanescentes**:
  1. `PORTAL DAP4.0` (board) == `dap-portal-aios` (spike repo) ou nomes diferentes?
  2. `dev.` é launcher admin (Thales acessa todos 10 módulos numa sidebar full) ou staging do código?
  3. Subrotas de cada módulo (rascunhei árvore CONSULTOR/GESTAO/MECANICO/CLIENTES/AIOS/TOOLS/PROCESSOS — falta confirmar).
- **Sub-pergunta facilities** — Thales disse "É O PORTAL DE FERRAMENTAS" mas ambíguo: (a) ferramentas físicas da oficina (scanner Bosch, ICOM BMW, dyno, lift — gestão de ativos), (b) ferramentas digitais (Playbook, Kit Performance, Catálogo, calculadoras DTC), ou (c) ambas. Aguardando refinamento.
- **Decisão dos 4 caminhos propostos** — Thales pediu handoff antes de escolher 1/2/3/4 (ver "Próximo passo").

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `frontend/_preview/home-visao-geral.html` | Modificado | Adicionado `<script src="https://mcp.figma.com/mcp/html-to-design/capture.js" async></script>` no `<head>` (linha 7). Tool recomenda manter pra re-captura via toolbar. Remover só se Thales pedir. Não commitado ainda. |

**Não tocado em código além disso.** Sessão foi de descoberta/decisão/captura, não implementação nova no spike.

## Decisões tomadas

- **Pivot Stitch → Figma** — razão: Thales escolheu opção B explicitamente após eu listar 3 caminhos (A=reconectar Stitch, B=Figma direto, C=ficar em HTML local). Figma já autenticado, `generate_figma_design` é o equivalente direto do "ver tela a tela" e ainda exporta via Code Connect pro spike. Stitch ficaria bloqueado pelo erro DCR e exigiria troubleshooting extra fora do escopo da sessão.
- **Plan key = `thales oliveira's team` (`team::1601351602264137877`)** — razão: 2 plans (`thales oliveira's team` e `thalao`); escolhi o primeiro por nome mais descritivo + ordem na resposta. Não pedi confirmação (CLAUDE.md: "não pergunto o óbvio"). Reversível trocando plan na próxima criação de arquivo.
- **Captura em modo `newFile` (vs existingFile)** — razão: nenhum arquivo Figma do projeto existia ainda. `newFile` cria + faz primeira captura. Subsequentes precisam usar `existingFile` + `fileKey: S9kIkeueS2VeSnyWVqDidV`.
- **Manter capture script no HTML** — razão: tool explicitamente recomenda manter (`Leave the capture script in the HTML unless the user explicitly asks you to remove it`). Permite re-captura via toolbar do browser sem precisar regerar capture ID.
- **Single-app subdomain-aware como leitura do board** — razão: o Diagrama 2 mostra `PORTAL DAP4.0` (singular) com 10 módulos como filhos diretos, não 6 portais separados. Faz sentido com a sidebar que já tinha sido desenhada na Visão Geral. RBAC + subdomain routing decidem o que cada papel vê. Aguardando Thales confirmar.

## Bloqueios & perguntas abertas

- **Caminho 1/2/3/4 não escolhido** — Thales pediu handoff antes de responder. Recomendação: opção 4 (combo design system mínimo + 1ª tela nova). Detalhes nas opções abaixo:
  1. Construir DS completo (variáveis + text styles + ~5 componentes), refazer Visão Geral com instances. Custo ~5-8 min.
  2. Capturar mais telas existentes — pouco a capturar (só Visão Geral está pronta no spike; outras são placeholder/auth-protected).
  3. Gerar tela nova (Chat) direto via prompt `use_figma`, sem DS formal. Mais rápido visualmente, menos consistente.
  4. **(Recomendado)** DS mínimo (paleta + text styles + Card/Button/Badge) + gerar Chat com tokens já criados. ~10 min pra base reutilizável + 1ª tela nova.
- **3 perguntas estruturais** ainda em aberto (naming PORTAL DAP4.0 vs dap-portal-aios, dev. = launcher ou staging, subrotas de módulos).
- **Sub-pergunta facilities** (físicas / digitais / ambas).
- **`idea.md` aprovação + 4 bloqueantes** do handoff anterior continuam pendentes (nome projeto, renomear spike pra `C:\dev\dap-portal-aios` canônico, granularidade GSD, modelos GSD).
- **Onde está hospedado `aios.doctorautoprime40.com`?** Ainda sem resposta — bloqueia phase de deploy no roadmap.

## Próximo passo exato

Quando retomar:

1. **Abrir o Figma novo:** `https://www.figma.com/design/S9kIkeueS2VeSnyWVqDidV` — Thales confirma se a captura ficou aceitável visualmente como ponto de partida.
2. **Thales escolhe caminho 1/2/3/4** (default sugerido: 4).
3. **Se 4 (combo DS mínimo + Chat):**
   - Carregar schemas adicionais via ToolSearch: `mcp__plugin_figma_figma__use_figma`, `mcp__plugin_figma_figma__get_metadata`, `mcp__plugin_figma_figma__get_screenshot`, `mcp__plugin_figma_figma__search_design_system`.
   - Spawn 1ª chamada `use_figma` (com `skillNames: "figma-use"` + `fileKey: S9kIkeueS2VeSnyWVqDidV`) pra criar Variable Collection "DAP 4.0 — Tokens" com modes Light/Dark e variáveis: `color/ink`, `color/paper`, `color/red`, `color/paper-2`, `color/graphite`, `color/muted`. Scopes: `["FRAME_FILL", "SHAPE_FILL", "STROKE"]` pra colors.
   - 2ª chamada: text styles (H1-H4 Space Grotesk 600/500, Body-MD Inter 400, Body-LG Inter 500, Mono-Eyebrow JetBrains Mono 400 UPPER tracking 0.1em, Mono-Data JetBrains Mono 500). `await figma.loadFontAsync()` pra cada combo família/peso.
   - 3ª chamada: 3 componentes core — Card (frame ink border 1.5px + offset shadow 8px 8px 0 + paper bg + radius 0), Button (3 variants: primary ink/paper, secondary border ink, critical red), Badge (mono UPPER ink/paper padding 3px 7px). Auto-layout em todos. Retornar IDs.
   - 4ª chamada: Chat screen — auto-layout horizontal 3 colunas (320 / flex / 320), brand DAP 4.0 estrito conforme `_prompts/operacao-chat-colab-claude-design.md`, mensagens estilo log de terminal (não bolha), Anna AIOS classification badge no contexto direito, composer marcado `[READ-ONLY · ENVIO EM BREVE]`. Validar com `screenshot()`.
4. **Em paralelo (não bloqueante):** atualizar `idea.md` com a leitura confirmada do board (PORTAL DAP4.0 inteiro, single-app, 10 módulos) + responder as 4 perguntas abertas conforme decisão final.

**Alternativa A (caminho 1):** começa pelo DS completo, refaz Visão Geral com instances. Mais rigoroso, mais tempo.

**Alternativa B (caminho 3):** pula DS, gera Chat só com prompt narrativo. Mais rápido, menos durável.

## Setup / comandos úteis

```bash
# Spike
cd /c/dev/dap-portal-aios-spike
git branch --show-current   # esperado: feat/home-colab
git status                   # esperado: 1 arquivo modificado (home-visao-geral.html com script tag)

# Servidor local (vivo no fim da sessão)
curl -sS -o /dev/null -w "%{http_code}\n" http://localhost:8765/_preview/home-visao-geral.html
# Se cair: cd frontend && python -m http.server 8765 &
```

**Figma:**
- Arquivo do projeto: https://www.figma.com/design/S9kIkeueS2VeSnyWVqDidV
- fileKey: `S9kIkeueS2VeSnyWVqDidV`
- Plan key (Thales): `team::1601351602264137877` (`thales oliveira's team`)
- Plan alternativo: `team::1614273624048963804` (`thalao`)
- Próximas capturas: `outputMode: 'existingFile'` + `fileKey: 'S9kIkeueS2VeSnyWVqDidV'`. NUNCA reusar capture ID.

**Auth state nesta sessão (pode persistir ou não):**
- Figma MCP: ✅ autenticado via `/plugin` nesta sessão
- Stitch MCP: ❌ erro DCR — não conseguimos auth nesta sessão
- Chrome DevTools MCP: ✅ funcional, com tab aberta em `home-visao-geral.html#figmacapture=...`

**Memórias relevantes na conversa:**
- `feedback_branch_drift_paralela.md` — checar branch antes de commit (no spike)
- `reference_dap4_design_system.md` — design system DAP 4.0 v1.0 oficial
- `feedback_supabase_getsession_hang.md` — afeta `home.html` real quando integrar `requireAuth`
- Path do brand guidelines: `_prompts/brand-guidelines-dap-4-0.md` (root do spike, NÃO `frontend/_prompts/`)

**Board Figma de arquitetura (referência canônica):**
- URL: https://www.figma.com/board/Sa2LB7UuRX6BHS48oUPqeU
- Dois diagramas:
  - Subdomínios: `dev.` → 6 outros (gestao/consultor/mecanico/clientes/aios/facilities)
  - PORTAL DAP4.0: 10 módulos top-level
