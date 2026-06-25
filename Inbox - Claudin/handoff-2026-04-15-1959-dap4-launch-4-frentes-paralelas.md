---
type: handoff
date: 2026-04-15
time: 19:59
project: DAP4.0-launch-planning
topic: 4 frentes paralelas executadas via subagents (launch scope + skills inventory + Kommo Hub spec + benchmark premium). Convergência cross-frente identificada. Aguardando Thales ler docs e responder 6 perguntas abertas de F1.
tags: [handoff, claudin, dap4, launch, parallel-agents, subagents]
---

# Handoff — 4 frentes paralelas DAP 4.0 launch

## Contexto

Sessão-teste pedida pelo Thales ("quero rodar 4 sessões, vamo ver se você é forte mesmo"). Saindo do handoff 19:16 (escopo lançamento + inventário skills pendente), plano `/plan opusplan` propôs 4 frentes paralelas em subagents isolados. Thales confirmou com "bora".

As 4 frentes foram escolhidas pra cobrir **decisão estratégica + materialização de backlog + design técnico + research de mercado** sem dependências críticas entre si, permitindo execução simultânea:

- **F1** — Brainstorming escopo de lançamento DAP 4.0 (Opus, decisão estratégica, entrega spec doc)
- **F2** — Materializar `skills-inventory.md` no vault PITOS/Sistemas (Sonnet, backlog do handoff 19:16)
- **F3** — Spec arquitetural Phase 1a Kommo Hub (Opus, architect agent)
- **F4** — Benchmark competitivo: como marcas automotivas premium lançam ecossistema (Sonnet, research)

Todas rodaram em paralelo numa única mensagem com 4 blocos Agent, sem worktree (nenhuma tocou código de produção, só docs/specs). Tempo total: ~4 min wall-clock (limitado pela F4 research que levou 4min10s).

## O que funcionou (com evidência)

- **F1 entregou decisão estratégica com postura** — spec em `C:\dev\dap4\docs\superpowers\specs\2026-04-15-dap4-launch-scope.md`. Recomendação híbrida sequenciada: soft-launch 2026-05-15 (interno, 30d de Anna+dashboard+3 OS-vitrine) → grand-launch 2026-06-02 (segunda, pós-Corpus Christi, início ciclo inverno SP). Trade-off explícito: +48 dias de atraso vs. proteção permanente de reputação em boca-a-boca BMW/Audi. 6 perguntas abertas, todas com recomendação.

- **F2 materializou doc vivo** — 62 skills em 9 categorias em `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Sistemas\skills-inventory.md`. Cada skill com 1 linha "o que faz" + 1 linha "quando invocar" ancorado em cenários DAP reais. Categoria 8 (AIos backend) marcada como aspiracional.

- **F3 entregou spec técnico denso** — `C:\dev\dap4\docs\superpowers\specs\2026-04-15-kommo-hub-phase1a.md` com 3 decisões-chave (Gateway único consumidor Kommo, Postgres LISTEN/NOTIFY vs Redis, escalação via Kommo nativo), fluxo end-to-end ASCII, 7 milestones (M0-M7), 8 riscos mapeados, 8 métricas launch-ready. Reaproveita 90% do branch `feat/anna-phase1a`.

- **F4 entregou 3 insights não-óbvios** — `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\Notas\013-dap40-benchmark-lancamentos.md`, 8 fontes (Singer, Brabus, BMW M, Porsche, RUF, Alpina, APR). Insights: (1) marcas premium anunciam posição, não produto; (2) flywheel engenharia→conteúdo→educação→IA não foi fechado por ninguém — gap é do DAP; (3) o palco define o posicionamento. Recomendação top: manifesto visual 90s cinematográficos 2-3 semanas antes de evento privado.

- **Convergência cross-frente identificada** — F4 valida F1 independentemente. "Soft-launch → grand-launch com evento privado" (F1) bate com "o palco define o posicionamento, RUF revela no The Quail" (F4). Duas frentes separadas chegaram em recomendações compatíveis sem se consultarem.

- **Paralelismo deu ganho real** — 4 tarefas simultâneas em ~4min vs. ~25-35min sequencial. Sessão-teste passou.

## O que NÃO funcionou (e por quê)

- **F3 architect agent não tinha Write/Edit/Bash** — subagent `architect` tem toolset restrito (só Read/Grep/Glob por design — é agent de design, não de implementação). Architect entregou o payload markdown inline no reporte e Claudin parent gravou o arquivo. Custo: ~1 tool call extra + atenção manual. **Correção pra próxima vez:** quando usar `architect` subagent pra gerar doc, ou (a) pedir pro architect só raciocinar + entregar no reporte desde o prompt; ou (b) usar `general-purpose` com prompt de architect em vez do subagent_type dedicado.

- **Nenhum subagent tinha handoff explícito do handoff anterior** — cada prompt foi self-contained com contexto embutido, mas nenhum leu `handoff-2026-04-15-1916-*` ou `handoff-2026-04-15-1849-*` diretamente. F3 foi o único instruído a ler a memória `project_dap4_phase1a_ia_no_ar.md` e o handoff 1849. F1/F2/F4 operaram com contexto que Claudin embutiu no prompt. Risco: se algum handoff tinha detalhe que Claudin não lembrou de embutir, a frente não teve acesso. Não aconteceu desta vez (comparando outputs com handoffs anteriores, coerentes), mas é ponto de atenção.

- **F1 não saiu de skill `brainstorming` literal** — o skill brainstorming é interativo (dialoga com usuário). Em subagent isolado, não há usuário pra dialogar. Subagent adaptou pra "brainstorming estruturado interno em 3 vozes (GTM, técnica, brand) → convergência + recomendação". Funcionou bem, mas não foi `superpowers:brainstorming` invocado. Se Thales quisesse o skill literal, precisaria rodar em sessão principal, não subagent.

- **Nenhuma das 4 frentes executou checagem cruzada entre outputs** — cada uma fechou sem saber das outras. Convergência entre F1 e F4 foi identificada por Claudin parent lendo os reportes, não pelos agents. Em outro contexto isso poderia ter gerado contradições se a Thales assumisse coerência automática.

## O que ainda não foi tentado

- **Thales ler e reagir aos 4 docs no Obsidian/VSCode** — toda a saída está em arquivo, nenhum foi aprovado ou refutado ainda. Risco: 4 docs densos pra ler de uma vez. Sugestão pra próxima sessão: ler F1 primeiro (decisão fundamental), F4 depois (valida/informa F1), F3 condicional à decisão de F1, F2 como referência.

- **Responder as 6 perguntas abertas de F1** — Project editorial vs operando, número único Anna, mídia paga +14d, open house, TTS, visibilidade Parliament. Bloqueio pra congelar escopo.

- **Sincronizar `project_dap4_phase1a_ia_no_ar.md` em memória** — a memória atual ainda reflete pré-pivô Kommo parcial. F3 spec é a fonte mais atualizada agora. Vale atualizar a memória próxima sessão.

- **Atualizar `project_dap4.md` e `project_parliament_chairman_os.md`** — com a decisão híbrida soft→grand (se Thales aprovar F1), essas memórias precisam refletir a data-alvo 2026-06-02.

- **Criar manifesto visual (F4 recomendação top)** — produção audiovisual de 90s. Não é trabalho de Claudin direto, mas pode ajudar com roteiro/storyboard usando skill `brand-voice` + `content-engine`.

- **M0 do F3 (spike credenciais Kommo)** — 2h humano + 2h Claudin pra mapear shape real Kommo Chats v2 via curl. Bloqueio: KOMMO_TOKEN ainda pendente.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\dev\dap4\docs\superpowers\specs\2026-04-15-dap4-launch-scope.md` | Criado (draft aguardando Thales) | F1. Spec de 1-2 páginas, decisão híbrida, 6 perguntas abertas com recomendação. |
| `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Sistemas\skills-inventory.md` | Criado (doc vivo) | F2. 62 skills, 9 categorias. Updated field = 2026-04-15. |
| `C:\dev\dap4\docs\superpowers\specs\2026-04-15-kommo-hub-phase1a.md` | Criado (draft condicional) | F3. Spec técnico. Condicional à decisão de F1. 7 milestones M0-M7. |
| `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\Notas\013-dap40-benchmark-lancamentos.md` | Criado (research concluído) | F4. 8 fontes, 3 insights, recomendação manifesto visual. |

Código (`C:\dev\dap4`): **zero mudanças.** Branch `feat/anna-phase1a` inalterada desde o commit afefa4c (playground). Worktree `C:/dev/dap4-anna-phase1a` limpo.

## Decisões tomadas

- **Executar 4 frentes em paralelo via subagents foreground, sem worktree** — razão: nenhuma frente tocava código de produção (só docs/specs), então isolamento de context via subagent foi suficiente. Worktree adicionaria fricção sem benefício.

- **F4 = benchmark research (não auditoria de codebase ou copy de lançamento)** — razão: research alimenta decisão de F1 sem depender dela; auditoria de codebase dependeria de saber se lançamento é interno ou público (decisão de F1); copy seria prematuro antes do escopo congelar. Benchmark foi o uso paralelo mais produtivo do slot.

- **F3 marcado como "draft condicional"** — razão: arquitetura Kommo Hub só faz sentido se decisão de F1 incluir Kommo no lançamento. Spec pronto reduz tempo-de-execução pós-decisão de 1-2 dias pra zero, e o trabalho não é jogado fora mesmo se F1 mover Kommo pra depois do lançamento.

- **F1 recomendou híbrido (C), não público puro (A) nem interno puro (B)** — razão do agent (resumindo): lançar só interno perde momentum de mercado; lançar só público com Anna ainda imatura queima reputação permanentemente. Híbrido sequenciado resolve os dois. Data 2026-06-02 foi escolhida por segunda-feira, pós-Corpus Christi, início de ciclo inverno premium.

- **Usei `general-purpose` pra F1/F2/F4 e `architect` só pra F3** — razão: F1 precisa executar skill `brainstorming` (adaptado), F2 é transcrição estruturada, F4 usa exa-search/WebSearch. Nenhum bate com subagent dedicado. F3 é design arquitetural puro → `architect` fit, mesmo sem Write tool.

- **Opus em F1 e F3, Sonnet em F2 e F4** — razão: F1 (decisão estratégica world-class) e F3 (design técnico com trade-offs reais) exigem Opus. F2 (materialização estruturada) e F4 (research + síntese) são bem cobertas por Sonnet com economia significativa.

## Bloqueios & perguntas abertas

### Bloqueios herdados (continuam válidos)
- [ ] KOMMO_TOKEN + KOMMO_DOMAIN + KOMMO_CHATS_CHANNEL_SECRET + KOMMO_THALES_USER_ID pendentes — bloqueia M0 do F3
- [ ] RTBM do Thales pendente — bloqueia M6 do F3
- [ ] Confirmação subdomínio Kommo `doctorautoprime.kommo.com`?

### Perguntas abertas novas (pro Thales responder antes de congelar escopo)
F1 tem 6 perguntas detalhadas no doc. Resumo:
1. DAP Project entra no dia zero como **unidade editorial-only** ou já operando builds?
2. Anna usa **número único dedicado** ou mantém linha DAP Prime atual?
3. **Mídia paga** entra na janela soft (+0d) ou só no grand (+17d)?
4. **Open house** no grand-launch: evento privado por convite ou aberto?
5. **TTS/voice Anna** entra no dia zero ou só texto?
6. **Parliament** fica visível publicamente no grand ou permanece interno?

### Pergunta meta (teste da sessão)
- **Thales aprovou o formato de 4 frentes paralelas?** Se sim, é padrão pra sessões futuras quando a pauta dá pra fatiar. Se não, ajustar (mais ou menos frentes, outra divisão, etc).

## Próximo passo exato

**Na próxima sessão, abrir com:**

1. **`/resume-handoff`** — carrega este handoff (mais recente).

2. **Thales lê os 4 docs em ordem recomendada** (pode ser fora de sessão, no Obsidian):
   - Primeiro: `C:\dev\dap4\docs\superpowers\specs\2026-04-15-dap4-launch-scope.md` (F1 — decisão fundamental)
   - Segundo: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\Notas\013-dap40-benchmark-lancamentos.md` (F4 — valida/informa F1)
   - Terceiro: `C:\dev\dap4\docs\superpowers\specs\2026-04-15-kommo-hub-phase1a.md` (F3 — condicional a F1)
   - Quarto (quando der): `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Sistemas\skills-inventory.md` (F2 — referência)

3. **Thales responde as 6 perguntas abertas de F1** diretamente no chat ou no próprio doc.

4. **Claudin congela F1** (marca `status: approved`, data definitiva, escopo fechado) e atualiza memórias relevantes (`project_dap4.md`, `project_dap4_phase1a_ia_no_ar.md`, `project_parliament_chairman_os.md`).

5. **Decisão de sequenciamento pós-F1:**
   - Se Kommo Hub entra no soft-launch → puxar credenciais Kommo e iniciar M0 do F3.
   - Se Kommo fica pra grand ou depois → priorizar preparação do manifesto visual (F4 recomendação top) + planejamento evento privado.

## Setup / comandos úteis

- **Retomar:** `/resume-handoff` (pega este por ser o mais recente)
- **Ler F1 via terminal:** `cat "C:\dev\dap4\docs\superpowers\specs\2026-04-15-dap4-launch-scope.md"` (ou abrir em VSCode)
- **Abrir todos no Obsidian:** o vault PITOS tem 3 dos 4 docs indexáveis (F2, F4). F1 e F3 estão em `C:\dev\dap4\docs\superpowers\specs\` — fora do vault, mas abríveis no VSCode paralelo.
- **Telemetria da sessão-teste:**
  - F1 Opus: 70k tokens, 2min
  - F2 Sonnet: 46k tokens, 1min30
  - F3 Opus: 72k tokens, 3min37
  - F4 Sonnet: 63k tokens, 4min11
  - Total: 251k tokens, ~4min wall-clock paralelo
