---
type: handoff
date: 2026-04-28
time: 02:57
project: dap-portal-aios
topic: Spike DAP 4.0 — brand rollout + prompts claude.ai/design + Visão Geral implementada com shell
tags: [handoff, claudin, dap-portal-aios, dap-4-0, brand, ui]
---

# Handoff — Spike DAP 4.0 (portal-aios) · brand rollout + Visão Geral

## Contexto

Sessão extensa montando o spike de redesign do `dap-portal-aios` (frontend que vive em `aios.doctorautoprime40.com`) sob a identidade visual canônica DAP 4.0 (Apex × Chassis) que o Thales documentou no brand guidelines. O portal interno é claro/profissional (paper-first), com sidebar dark, focado em telecom de oficina (pátio em tempo real, conversas, kanban de leads). Objetivo final: substituir o portal atual (azul corporativo + emoji + radius 10px legacy) por uma identidade que case com o ecossistema DAP 4.0 (ink #141414 / paper #F4F0E8 / red Porsche #D8272A, Space Grotesk + Inter + JetBrains Mono, offset shadow dura, brackets, etiquetas numeradas, motivos Apex/Chassis).

A sessão começou propondo prompts pra `claude.ai/design`, mas o Thales perguntou "ta, mas e as telas?" — então pivotamos: implementação direta no spike em vanilla HTML/CSS/JS, com Chrome DevTools MCP pra validar visualmente. Fluxo de iteração estabelecido: implemento no spike → screenshot → Thales itera por comando textual → recarrego.

Sessão trabalhada num **clone do repo principal** em `C:\dev\dap-portal-aios-spike` (fora do OneDrive pra evitar sync drift). Branch ativa: `feat/home-colab`. Origin remoto = mesmo do repo principal (`github.com/toliveira1802-sketch/dap-portal-aios.git`). NÃO foi feito push ainda — tudo local.

## O que funcionou (com evidência)

- **tokens.css remapeado pra DAP 4.0 sem refator das ~20 páginas existentes** — evidência: aliases legados (`--brand`, `--accent`, `--bg`, `--text`, `--r`, `--shadow`) apontam pros novos valores DAP 4.0; páginas com CSS inline próprio (login.html testada) repintaram automaticamente sem mudança no markup. Validado no `_brand-showcase.html`.
- **`base.css` componentes DAP 4.0** — evidência: `.card` com offset shadow 8px 8px 0 + border 1.5px ink + radius 0; `.btn` ink/paper sem radius; `.input` borda 1.25px ink; `.badge` ink/paper mono UPPER tracking 0.1em; `.table` zebra paper/paper-2 com header mono UPPER. Validado screenshot via Chrome MCP.
- **Login refeito 100% Apex × Chassis** — evidência: `http://localhost:8765/login.html` validado via Chrome MCP. Paper bg + crosshair grid sutil + box paper com border ink + offset shadow + eyebrow `[DAP·4.0] · ACESSO RESTRITO` + título Space Grotesk + tick mark separador + inputs paper border ink + botão ink/paper + build tag graphite/paper rodapé. Lógica auth Supabase intacta; mensagem de erro normalizada pra mono UPPER (`ERR · EMAIL OU SENHA INCORRETOS`).
- **Contatos refeito 100%** — evidência: arquivo escrito (auth-protected, validado via showcase com cards mockados). Avatar circular gradient azul/roxo substituído por slot quadrado 56x56 ink/paper mono UPPER (variante .parc invertida com border ink). Badges saturadas (azul/amarelo/marrom) viraram ink/paper mono UPPER + .quente em red + .frio ghost. Emoji 📞📍⏱️🏷️ removidos; meta agora em `Tel · (11) 91700-1822` mono UPPER label/value. Empty state com Caveat anotação rotacionada -3°.
- **Brand showcase consolidando paleta + componentes** — evidência: `http://localhost:8765/_brand-showcase.html` validado via Chrome MCP. Mostra paleta (paper, ink, red, paper-2, graphite, muted), tipografia (Space Grotesk, Inter, JetBrains Mono, Caveat), botões, badges, cards KPI com offset shadow, input com focus ink, tabela densa estilo dyno readout, cards de contato (lead+parc), empty state, build tag.
- **Visão Geral standalone com shell completo** — evidência: `http://localhost:8765/_preview/home-visao-geral.html` validado via Chrome MCP. Tela completa com sidebar dark (`#0A0A0A`) + topbar paper + main paper. Sidebar: brand `[DAP·4.0]` red + nav-groups (Operação > Visão geral active · Chat · Pipeline; Contatos > Leads · Diretório; Ferramentas > Playbook · Kit Performance · Painel financeiro [gestor]-locked; Geral > Catálogo) + user-block avatar SS Samuel Colab. Topbar: breadcrumb `[Operação] / Visão geral` + actions (sync dot + timestamp). Main: header strip (capacidade datum line 60% verde, em execução 7), filtros (consultor + search ⌘K + toggle só meus), bento grid 8 cards com hierarquia (Em execução span-2 com placas + mecânico, Agendados com fita vermelha rotacionada -6°), banner atrasados condicional com fita vertical vermelha, tabela recursos densa 15 linhas (1 atrasado com ponto vermelho), placeholder gestão tracejado, build tag rodapé. Live timer `atualizado há Xs` incrementa.
- **Preview consolidado `_preview.html`** — evidência: galeria visual sem auth com hero + stats + cards "shipped" (login screenshot, showcase screenshot, contatos placeholder, tokens) + cards "draft" (Visão Geral, Chat, Pipeline, Brand guidelines com links pros prompts) + roadmap M1 6-phases tabela densa + CTA pra `idea.md`.
- **idea.md rascunhado pra `/gsd-new-project --auto`** — evidência: `C:\dev\dap-portal-aios-spike\idea.md`, 179 linhas, 11 seções (nome, posicionamento, contexto, roles, estado atual, scope M1, restrições técnicas, deploy, multi-tenant Bosch/Prime, bloqueantes, próximos passos). Aguardando aprovação do Thales.
- **3 prompts world-class pra claude.ai/design** — evidência: `_prompts/home-colab-claude-design.md` (469 linhas), `_prompts/operacao-chat-colab-claude-design.md` (449 linhas), `_prompts/operacao-pipeline-colab-claude-design.md` (418 linhas). Todos com brand DAP 4.0 estrito, stack-aware (vanilla, sem Tailwind/shadcn), 8-11 perguntas estruturadas, 3 few-shots cada, fronteiras com diretores adjacentes. NÃO usados ainda — ficaram como referência alternativa caso queira iterar visual antes de implementar direto.
- **Brand guidelines salvo no spike** — evidência: `_prompts/brand-guidelines-dap-4-0.md`, 295 linhas, cópia integral do que Thales mandou. Referência canônica pros prompts.
- **Servidor Python http.server :8765 rodando** — evidência: PID em `/tmp/dap-spike-server.log`, respondeu HTTP 200 em login/home/chat/showcase/preview/visão-geral. Continua ativo no fim da sessão.
- **Chrome DevTools MCP usado pra validar cada screenshot** — evidência: 8+ screenshots em `_screenshots/` (login-after-tokens, login-dap40, login-dap40-v2, brand-showcase, brand-showcase-v2, visao-geral-v1, visao-geral-v2, visao-geral-shell, preview).

## O que NÃO funcionou (e por quê)

- **`/gsd-autonomous` invocado sem ROADMAP** — falhou porque: `gsd-sdk query init.milestone-op` retornou `roadmap_exists: false, project_exists: false, phase_count: 0`. O `.planning/` no spike só tem STATE.md herdado do clone (do projeto AIOS principal Sophia/Walter/Anna), não há PROJECT/REQUIREMENTS/ROADMAP. Workflow `autonomous.md` exige `/gsd-new-milestone` primeiro. Cancelado, voltou pro fluxo de prompts.
- **Primeiro prompt da Home assumiu paleta `OneDrive/dap4` (red Porsche + Archivo Black)** — falhou porque: confundi `dap4` (em `C:\dev\dap4`, dark command center) com `dap-portal-aios` (claro, brand azul corporativo no `tokens.css` original). O comentário linha 3 do `tokens.css` é explícito: *"Diferente do AIOS (dark command center)"*. Tive que reescrever o prompt com identidade do tokens legacy. Depois Thales mandou o brand guidelines DAP 4.0 oficial e reescrevi de novo (3ª iteração).
- **`navigate_page` no `home.html` retornou ERR_ABORTED** — falhou porque: home.html é auth-protected (`requireAuth()` redireciona pra login se sem session Supabase). Solução: criar `_brand-showcase.html` standalone sem auth + posteriormente `_preview/home-visao-geral.html` standalone com dados mockados. NÃO testado: como bypassar auth pra preview no contexto de produção (bypass via querystring? cookie de dev?).
- **Fita vermelha do "Agendados hoje" inicialmente saindo do card** — falhou porque: `transform: rotate(-3deg) translate(-12px, -2px)` em `::before` com `position: absolute` saiu do bounding box do `.bento-card`. Fix: adicionar `overflow: hidden + isolation: isolate` no `.bento-card.with-tape` e ajustar transform pra rotate(-6deg) com `top: 8px; left: -12px`. Validado v2.
- **Cache do browser Chrome MCP entre navigates** — falhou porque: depois de editar `login.html`, o reload mostrou versão velha. Solução: `navigate_page reload + ignoreCache: true`. Aplicado nas iterações seguintes.

## O que ainda não foi tentado

- **Replicar Visão Geral aprovada em `home.html` real** — falta integrar `requireAuth()` + `renderShell()` (não criar shell mockado novo) + conectar com Trello/Kommo via fetch pra substituir dados mockados. Esforço baixo (copy/paste com auth wrap).
- **Implementar Chat standalone** — prompt em `_prompts/operacao-chat-colab-claude-design.md` (449 linhas) tem todas as specs. Padrão é igual à Visão Geral — implementar direto, validar visual, depois integrar com Kommo+WhatsApp.
- **Implementar Pipeline standalone** — prompt em `_prompts/operacao-pipeline-colab-claude-design.md` (418 linhas). Kanban com tabs Bosch/Prime, drag & drop, classificação Anna AIOS embarcada nos cards.
- **Investigar deploy atual** — `aios.doctorautoprime40.com` resolve em Cloudflare e responde 200 OK; alguém já fez deploy. Pendente: descobrir hospedagem (Cloudflare Pages? Vercel? VPS Hostinger 76.13.170.42 — `/opt/doctor-auto-ai/`?), pipeline (push direto? GH Action? manual?), credenciais. Sem isso, não dá pra fechar deploy phase no roadmap.
- **GSD `/gsd-new-project --auto @idea.md`** — `idea.md` rascunhado e commitado, falta Thales aprovar/ajustar e responder os 4 bloqueantes (nome do projeto, renomear spike pra `C:\dev\dap-portal-aios`, granularidade GSD, modelos GSD).
- **Refatorar páginas legadas restantes** — `leads.html` (138 linhas inline, candidata a próximo prompt OU rebrand direto), `lead.html` (~300 linhas inline, detalhe único), `parlamento*.html` + `sala-do-conselho.html` (território AIOS, evolução paralela com Sophia/Walter — não tocar), `catalogo.html`/`financeiro.html`/`kit-performance.html`/`playbook.html` (fora escopo Operação atual).
- **Conectar Anna AIOS** ao card de lead (badge QUENTE/MORNO/FRIO + score + intenção) — backend está em paralelo com Perplexity em sessão dedicada, contrato `/aios/diretores/anna-cro-sales/parametros.md` pronto.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `frontend/css/tokens.css` | Completo | Remapeado pra DAP 4.0; aliases legados mantidos pra compat ~20 páginas. |
| `frontend/css/base.css` | Completo | Componentes (.card .btn .input .badge .table) atualizados pra DAP 4.0; h1-h4 em Space Grotesk; .eyebrow utilitário novo. |
| `frontend/login.html` | Completo | Refeito 100% Apex × Chassis. Lógica auth Supabase intacta. |
| `frontend/contatos.html` | Completo | Refeito 100%. Auth-protected — validar visual após login. |
| `frontend/index.html` | Completo (mínimo) | Title `DAP·4.0` (era 'DAP Operação'). Mantém redirect JS auth → home/login. |
| `frontend/_brand-showcase.html` | Completo | Página de validação DAP 4.0 sem auth, com paleta + tipografia + componentes + cards de contato + empty state. |
| `frontend/_preview.html` | Completo | Galeria visual consolidada do estado do projeto (shipped + draft + roadmap M1). |
| `frontend/_preview/home-visao-geral.html` | Completo | Standalone com shell mockado (sidebar dark + topbar). 689+281 linhas. **Aprovada pelo Thales: "porhora ok"**. |
| `frontend/_preview/login.png` | Completo | Screenshot pro preview consolidado. |
| `frontend/_preview/showcase.png` | Completo | Screenshot pro preview consolidado. |
| `frontend/home.html` | Não iniciado | A receber a Visão Geral aprovada com requireAuth + renderShell + fetch real. |
| `frontend/chat.html` | Não iniciado | Prompt pronto em `_prompts/operacao-chat-colab-claude-design.md`. |
| `frontend/pipeline.html` | Não iniciado | Prompt pronto em `_prompts/operacao-pipeline-colab-claude-design.md`. |
| `idea.md` | Em progresso | Rascunhado, aguarda aprovação Thales + 4 bloqueantes preenchidos. |
| `_prompts/brand-guidelines-dap-4-0.md` | Completo | Cópia integral do brand DAP 4.0 do Thales. |
| `_prompts/home-colab-claude-design.md` | Completo (não usado) | 469 linhas, alternativa caso queira iterar visual antes de implementar direto. |
| `_prompts/operacao-chat-colab-claude-design.md` | Completo (não usado) | 449 linhas. |
| `_prompts/operacao-pipeline-colab-claude-design.md` | Completo (não usado) | 418 linhas. |
| `.gitignore` | Completo | Ignora `_screenshots/` e `_ref-*.png|jpeg`. |
| `_screenshots/*` | Local apenas | 8+ PNGs validando cada iteração. Ignored. |

## Decisões tomadas

- **Spike vira repo canônico (escolha C de 3 opções)** — razão: OneDrive sincroniza durante git ops e build = drift garantido em time grande. `C:\dev\dap-portal-aios-spike` deve ser renomeado pra `C:\dev\dap-portal-aios` e abandonar o `OneDrive/.../dap-portal-aios`. **Pendente executar** — depende de aprovação Thales no idea.md.
- **Tokens legados mantidos no `tokens.css`, com aliases pra DAP 4.0** — razão: ~20 páginas usam `var(--brand)`, `var(--bg)`, `var(--accent)`. Trocar nomes quebraria todas. Manter nomes + remapear valores garantiu repaint automático sem refator.
- **Paper-first em todos os components, sidebar única dark** — razão: brand guidelines explicitamente "tema claro pros funcionários, dark só pro AIOS command center". Sidebar usa o `#0A0A0A` (dark mode DAP 4.0); todo o resto é paper.
- **Slot técnico quadrado ink/paper mono UPPER substitui avatar circular** — razão: Apex × Chassis é técnico, não social. Avatar circular com gradient é template default; slot 56x56 com iniciais mono UPPER mantém densidade e identidade.
- **Meta com `label · value` mono UPPER substitui emoji** — razão: brand guidelines proíbe emoji decorativo. Emoji 📞 vira `Tel`, 📍 vira `Stage`, ⏱️ vira `Last`, 🏷️ vira `Tipo` (todos em mono UPPER muted).
- **Caveat anotação rotacionada (-3° a -6°) em empty states + agendados fita** — razão: brand guidelines permite "1 ocorrência por composição" da anotação manuscrita. Aplicado em empty states ("aproveita pra organizar a oficina") + tira fita vermelha rotacionada -6° no card "Agendados hoje" (única segunda ocorrência discreta de vermelho na Visão Geral).
- **Implementar standalone primeiro, integrar shell+auth depois** — razão: pivot após pergunta do Thales "ta, mas e as telas?". Iteração visual sem auth é mais rápida; depois copia/replica no real. Visão Geral aprovada por hora confirma que padrão funciona.
- **Cancelar `/gsd-autonomous`, ficar no fluxo de implementação direta** — razão: spike não tem PROJECT/REQUIREMENTS/ROADMAP estruturado. GSD seria overhead sem benefício antes de definir scope. `idea.md` rascunhado pra reativar GSD quando Thales quiser formalizar.
- **3 prompts pra claude.ai/design escritos mas NÃO usados** — razão: Thales pivotou pra "implementar direto". Prompts ficaram como ref alternativa se quiser iterar visualmente antes de codar uma tela específica.
- **Live timer "atualizado há Xs" + ⌘K + toggle "Só meus" são mocks** — razão: validar UX/microinteração antes de conectar fetch real. Funcionam visualmente.

## Bloqueios & perguntas abertas

- **Onde está hospedado `aios.doctorautoprime40.com`?** Resolve em Cloudflare 200 OK. Cloudflare Pages? Vercel? VPS Hostinger `/opt/doctor-auto-ai/`? Outro? Sem isso, não fecho a phase de deploy no roadmap.
- **`idea.md` aprovado?** 4 bloqueantes pendentes:
  1. Nome do projeto: `DAP·4.0 — Portal Operação`?
  2. Renomear spike → `C:\dev\dap-portal-aios` canônico?
  3. Granularidade GSD: standard?
  4. Modelos GSD: balanced?
- **Estrutura final da sidebar** — o que mostrei no preview tá OK? Falta algum item? Algum grupo a mais (ex: AIOS pra gestão acessar Sala do Conselho)? Painel financeiro deve sumir totalmente da sidebar do colab ou aparecer locked como tá agora?
- **Leads** — refazer com prompt claude.ai/design dedicado OU rebrand direto seguindo padrão de contatos? Tem 138 linhas inline.
- **Como conectar Anna AIOS aos cards de lead/conversa?** Schema dela em `/aios/diretores/anna-cro-sales/parametros.md` (projeto paralelo). Backend `/api/diretores/anna/executar` está sendo construído por Perplexity em sessão dedicada — endpoint disponível pra consumir aqui? Ou ainda mock?
- **Multi-tenant Bosch/Prime no Pipeline** — como o backend retorna leads filtrados por tenant? Por pipeline_id no Kommo (`12704980` Bosch, Prime pendente confirmar)? Endpoint separado por tenant?
- **Telas dependentes de gestor (M2)** — Produtividade, Faturamento, Previsão. Quando entram? Precisa GSD com phases formais ou manda freeform?
- **Sessão paralela do Perplexity** — backend AIOS Sprint 1 (handoff em `.planning/handoffs/sessao-perplexity-backend-sprint1.md` no repo principal). Quando termina? Vai dar conflito de remote?

## Próximo passo exato

Quando retomar:

1. **`cd /c/dev/dap-portal-aios-spike`**
2. **`git branch --show-current`** — confirmar que está em `feat/home-colab` (memória `feedback_branch_drift_paralela.md` — sessões paralelas trocam HEAD sem aviso)
3. **Servidor python:** se não estiver rodando, `cd frontend && python -m http.server 8765 &`
4. **Chrome MCP / browser:** abrir `http://localhost:8765/_preview/home-visao-geral.html` pra ver o estado aprovado
5. **Implementar Chat standalone** seguindo o mesmo padrão da Visão Geral:
   - Criar `frontend/_preview/operacao-chat.html`
   - Copy do shell mockado da Visão Geral (sidebar + topbar)
   - Marcar `Chat` como active no nav-group Operação (em vez de Visão geral)
   - Conteúdo do main: 3 colunas (lista 320px / conversa flex / contexto 320px) conforme `_prompts/operacao-chat-colab-claude-design.md`
   - Mensagens em **linhas técnicas estilo log de terminal** (NÃO bolhas WhatsApp)
   - Coluna direita com etiqueta técnica preta `[LEAD KOMMO #12345]` + classificação Anna AIOS embarcada (badge QUENTE em mono UPPER ink/paper)
   - Composer com etiqueta `[READ-ONLY · ENVIO EM BREVE]` (V1 não envia)
   - Datum vermelho discreto: ponto 6px na lista quando não-respondida > 1h
   - Build tag rodapé
6. Validar via Chrome MCP screenshot
7. Iterar com Thales se não rolar de primeira

**Alternativa A:** se Thales quiser revisar antes de seguir Chat, pegar `idea.md`, responder os 4 bloqueantes, e eu rodo `/gsd-new-project --auto @idea.md` pra formalizar phases.

**Alternativa B:** se Thales quiser replicar Visão Geral em `home.html` real primeiro, mais rápido — copy/paste com `requireAuth()` + `renderShell()` no lugar do shell mockado HTML inline.

## Setup / comandos úteis

```bash
# Working dir do spike (não confundir com o original em OneDrive)
cd /c/dev/dap-portal-aios-spike

# Branch ativa
git branch --show-current   # esperado: feat/home-colab

# Servidor local
cd frontend && python -m http.server 8765 &
# Acessar: http://localhost:8765/_preview/home-visao-geral.html
# Acessar: http://localhost:8765/_preview.html  (galeria geral)
# Acessar: http://localhost:8765/_brand-showcase.html  (componentes)

# Push (NUNCA até Thales aprovar — origin = repo principal compartilhado)
# git push origin feat/home-colab

# Lista commits da sessão
git log --oneline feat/home-colab ^main

# Estado do GSD no spike
gsd-sdk query init.milestone-op
# (esperado: roadmap_exists: false; precisa /gsd-new-project --auto @idea.md primeiro)
```

**Memória relevantes na conversa:**
- `feedback_branch_drift_paralela.md` — checar branch antes de commit
- `reference_dap4_design_system.md` — design system DAP 4.0 v1.0 (paleta + Nike SB grid)
- `feedback_supabase_getsession_hang.md` — pode afetar `home.html` quando integrar `requireAuth`
- `project_dap4_dual_waba.md` — Bosch pipeline 12704980, Prime pendente confirmar

**11 commits da sessão** (mais recente primeiro):

```
7d6335d feat(visao-geral): integra shell mockado (sidebar dark + topbar)
e9def75 feat(visao-geral): implementação v2 standalone (sem auth, dados mockados)
b9f6eac feat(preview): página _preview.html consolidando estado atual do projeto
6328cb6 docs(planning): rascunho idea.md pra /gsd-new-project --auto
a62e726 feat(brand): rebrand contatos.html + index.html title pra DAP 4.0
5eae8c3 feat(brand): rebrand login.html pra DAP 4.0 (Apex × Chassis)
413d764 feat(brand): aplica DAP 4.0 (Apex × Chassis) em tokens.css + base.css
68f3992 feat(prompts): operação · chat + pipeline (colab) com identidade DAP 4.0
39472ac feat(brand): integra DAP 4.0 brand guidelines (Apex × Chassis) no prompt da Home
7af0ff5 fix(prompts): home colab usa identidade visual real do projeto
8ef0956 feat(prompts): home colab brief pra claude.ai/design (anti-template world-class)
```
