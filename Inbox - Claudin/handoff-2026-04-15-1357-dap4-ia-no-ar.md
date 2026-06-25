---
type: handoff
date: 2026-04-15
time: 13:57
project: DAP4.0-ecossistema
topic: Meta-spec re-escopada pra "IA no ar" (Parliament DAP, Phase 1). Descoberta de mapa real dos agents em andamento. Zero código, zero spec escrito.
tags: [handoff, claudin, dap4, parliament, sennin-protocol]
---

# Handoff — DAP 4.0 "IA no ar" (meta-spec Phase 1)

## Contexto

Sessão retomada via `/resume-handoff` do handoff de 10:07 (kickoff ecossistema 12 unidades, Sennin F0 Discovery). Durante esta sessão, o escopo da meta-spec foi **re-fatiado três vezes** pelo Thales até chegar num alvo preciso.

**Escopo inicial (errado):** "DAP4.0-ecossistema" = meta-spec de holding com 12 unidades + Foundation layer técnica pra 12 subdomains + 12 sites + bridge vault↔site. Comecei brainstorming por aí.

**Correção 1 (Thales):** "Claude Chat tava fazendo mesma coisa" — reconheci que invadi o domínio do Terminal 2 perguntando tom/arquitetura de marca (competência do Chat, não minha). Reposicionei: minha meta-spec é TÉCNICA/arquitetural, Chat entrega brand/voice/manifesto/copy, eu consumo.

**Correção 2 (Thales):** "Chairman/CEO e diretores vão ser pra qualquer projeto... o site agora eu seguiria como DAP40 só falando do ecossistema... o resto, atualmente estamos criando ferramentas internas e validando." Três camadas separadas reconhecidas: Chairman OS (multi-projeto, fora do escopo DAP), Site público DAP40 (quando CTO+CMO alinharem), Ferramenta interna dap4 (operação real, onde estamos hoje).

**Correção 3 (Thales):** "Preciso das IA no ar e depois vemos isso, até pqe isso é o CTO com CMO." Site público sai do F0 também. Meta-spec DAP 4.0 = **botar IA no ar**. F0 concreto = Phase 1 Parliament operante + agente CSO qualificando leads reais via WhatsApp.

## O que funcionou (com evidência)

- **4 agentes Discovery paralelos rodaram em background** — 3 de 4 entregaram valor real:
  - Explore vault PITOS: inventariou 835 linhas de notas estratégicas em `DAP 4.0/Notas/`, listou as 12 unidades com status, identificou gaps (manifesto, organograma, KPIs por unidade, roadmap datado — tudo ausente no vault). Relatório íntegro preservado no contexto.
  - Benchmark holdings premium: 10 marcas analisadas (AMG, Alpina, Porsche Classic, Bentley Mulliner, Pagani, Pfaff Auto, Singer, Pininfarina, Brabus, RUF). Pfaff Canada identificado como clone estrutural mais próximo. 3 padrões recorrentes: divisão Heritage, clube proprietários recorrente, conteúdo editorial próprio. 3 riscos de imitação: não fingir heritage falso, não coachbuilding one-off sem capital, não expansão lateral pré-matura.
  - Foundation architect: 10 decisões arquiteturais fechadas com razão (Turborepo, Astro+Next, @dap/ui próprio, Qdrant, Sophia gateway, Supabase cross-unit, Vercel+VPS split, SigNoz+PostHog+Sentry). Timeline 16 semanas em 4 fases. **Depois ficou obsoleto porque escopo foi re-fatiado pra "IA no ar"**, mas razões e trade-offs servem de referência técnica.

- **Descoberta do estado real do dap4** (após redisparar agente 1 com path correto): monorepo flat operante, dashboard React 18 + 16 páginas, gateway Express 5 + Meta WhatsApp Cloud API live + Socket.IO, agents FastAPI + 5 agentes legados (`agents/agents/ana.py etc.`) + Parliament novo (`agents/parliament/` com 13 C-Levels).

- **Mapa REAL dos agents identificado** (fim da sessão, via leitura direta de `agents/parliament/clevel_registry.py`): 13 C-Levels do Parliament DAP com especificação formal: Sophia CEO (AGENT live), Anna CSO Sales (AGENT live), Francisco CFO / Pitoco CPO / Zoraide CCO (SKILL prompt pronto, Phase 1), Bianca CMO + 7 outros (SKILL stub, Phase 2 deferido). Missões literais e prompts em `parliament/prompts/*.yaml`.

## O que NÃO funcionou (e por quê)

- **Pulei direto pra perguntas de brand/tom no brainstorming (perguntas 1 e 2)** — invadi o escopo do Chat. Thales interrompeu: "o claude chat tava fazendo mesma coisa... por isso tinha pedido pra separar". Descartei as 2 perguntas, repus escopo. Lição dura: **a divisão dos 2 terminais formalizada no handoff anterior é sagrada**. Brand/voz/manifesto = Chat SEMPRE. Minha meta-spec só referencia, nunca decide.

- **Agente 1 Discovery (Explore dap4) falhou duas vezes:**
  - Primeira tentativa: explorou `C:\DoctorAuto\` (projeto legado completamente diferente), não `C:\dev\dap4`. Relatório inválido descartado.
  - Segunda tentativa com path explícito: agente respondeu sem executar — só perguntou "o que você quer que eu faça?" sem explorar nada. Redisparo também falhou.
  - Solução: fiz eu mesmo via Read/Bash direto. Mais rápido que redisparar pela terceira vez.

- **Operei com docs defasados sobre os agents** — FEATURE_MAP.md (07/04) e CLAUDE.md listam Ana/Kimi/Sofia/Thales/Insights como agents do DAP. Mas isso é LEGADO (`agents/agents/`). O atual é Parliament (`agents/parliament/`) com 13 C-Levels nomeados Anna/Francisco/Pitoco/Zoraide/Bianca/etc. Quando Thales mencionou "CSO" eu ofereci 3 interpretações possíveis (Ana antiga, Bianca, agente novo) — todas erradas. Nenhuma das 3 era Anna (com 2 N's = CSO Sales do Parliament atual). Thales respondeu: "calma, Ana de um projeto antigo, Bianca é do atual, e esse novo veio de onde?" Só aí parei de presumir e li o código.

- **Confusão arquitetural Parliament DAP vs Chairman OS** — eu afirmei na recomendação "Parliament extrai pro Chairman OS" baseado no handoff 14/04. Mas o Parliament no dap4 atual (Anna CSO DAP, Francisco CFO DAP, Zoraide CCO DAP) é **específico da holding Doctor Auto Prime**, não é o mesmo Parliament multi-projeto que vai virar Chairman OS. Mais uma vez operei com mental model velho. No fim da sessão sinalizei a confusão e pedi confirmação — Thales não respondeu ainda.

- **Não escrevi nenhum spec ainda.** Brainstorming terminou pergunta 1 (timing refactor = Strangler), pergunta 2 (subdomains = só prime+performance, depois descartada), pergunta 3 (Parliament fora = confirmado mas re-escopado), pergunta 4 (IA no ar = A/B/C aberta, Thales pediu CSO qualificando leads). Gate F1 do Sennin NÃO honrado. Tentei seguir pra `writing-plans` sem spec, Thales disse "stop" — com razão.

## O que ainda não foi tentado

- **Ler todos os prompts YAML do Parliament** (`agents/parliament/prompts/anna.yaml`, `francisco.yaml`, `pitoco.yaml`, `zoraide.yaml`, `sophia_synthesis.yaml`) pra entender missão/personalidade de cada um antes de decidir qual ativar no F0.
- **Ler `agents/parliament/quorum_rules.py`, `session_manager.py`, `synthesis.py`, `archiver.py`** pra entender o fluxo atual do Parliament (topic → voices → quorum → synthesis).
- **Verificar estado real do Meta WhatsApp provisioning** — handoff 09/04 pedia setup manual Meta Business + deploy VPS Phase 1. Não sei se isso avançou desde então.
- **Checar `.env` atual vs `.env.example`** — saber quais credenciais Meta já estão preenchidas.
- **Escrever spec de "DAP IA no Ar — Phase 1"** focado em: Anna AGENT live qualificando leads WhatsApp + Francisco/Pitoco/Zoraide SKILL ativos no Parliament + critérios de sucesso mensuráveis.
- **Rascunho do plan** (só após spec aprovado).

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\handoff-2026-04-15-1357-dap4-ia-no-ar.md` | Este handoff | Escrito agora |
| `C:\dev\dap4\.superpowers\brainstorm\951-1776268207\content\brand-architecture.html` | Criado e descartado | Pergunta 2 do brainstorming que invadia escopo do Chat. Mantido no dir mas não usar como referência futura. |
| `C:\dev\dap4\.superpowers\brainstorm\951-1776268207\content\waiting.html` | Criado | Screen de transição quando voltei pro terminal. |

Nenhum arquivo do código fonte foi editado. Nenhum spec escrito ainda. Servidor companion expirou por inatividade (exit 0) — precisa ser reiniciado se próxima sessão quiser visual.

## Decisões tomadas

- **Meta-spec DAP 4.0 = "IA no ar" (Parliament Phase 1 operante)**, NÃO holding completa nem Foundation Turborepo nem site público. Razão: Thales priorizou operação real antes de estrutura. Site público e refactor Turborepo ficam pra quando CTO+CMO (no board do Parliament) alinharem — fora do escopo agora.

- **Três camadas separadas arquiteturalmente:** (1) Chairman OS pessoal multi-projeto — fora do dap4, spec própria futura. (2) Site público DAP40 — fora do F0, decisão CTO+CMO do Board depois. (3) Ferramenta interna dap4 — evolui incrementalmente via Strangler, é onde mora Parliament. Razão: misturar camadas quebra clareza e escopo.

- **Brand/voz/manifesto = Terminal 2 (Chat), nunca minha decisão.** Razão: divisão dos 2 terminais estabelecida no handoff anterior. Eu consumo, nunca produzo esse tipo de conteúdo.

- **Refactor dap4 → Turborepo = Strangler pattern (6 semanas), não big bang nem greenfield.** Razão: dap4 tem 8+ meses investidos, Meta WhatsApp live, CI verde. Quebrar pra refactor é auto-sabotagem. **Mas decisão agora é moot porque refactor saiu do F0 — fica pra F1/F2 quando site público entrar em jogo.**

- **Gate F1 do Sennin honrado** — NÃO invocar `writing-plans` sem spec escrito primeiro. Thales disse "stop" quando sugeri pular, concordou com rota A (spec primeiro). Próxima sessão: spec primeiro, aprovação, aí plan.

## Bloqueios & perguntas abertas

- **Confirmar "Parliament DAP ≠ Chairman OS"** — perguntei a Thales explicitamente no fim da sessão, não teve resposta ainda. Se Parliament DAP é dos diretores da holding Doctor Auto Prime (Anna CSO Sales DAP qualificando leads DAP), então ele fica dentro do dap4 e é parte da meta-spec. Se Parliament DAP é o mesmo Chairman OS multi-projeto só instanciado pra DAP, então é outra arquitetura. Alta confiança que é o primeiro, mas preciso confirmação explícita.

- **"CSO qualificando leads" = Anna (não Bianca)** — alta probabilidade mas Thales não confirmou literalmente. Missão da Anna em `clevel_registry.py:31-32` é literal: "Todo lead vira conversa, toda conversa vira orçamento, todo orçamento vira OS — no tempo certo." Bianca é CMO Marketing, não qualifica leads. Quando ele disse "Bianca é do atual" provavelmente se referiu ao Parliament atual como bloco, não especificamente Bianca.

- **Pergunta A/B/C do "IA no ar" ficou aberta** — A: Anna solo qualificando 80% inbound; B: Anna + Kimi loop fechado com contexto; C: Anna + Kimi + Sophia multi-agente. Minha recomendação foi A (Sennin: 1 agente live > 100 stub). Mas com descoberta do Parliament Phase 1 atual (Anna AGENT + Francisco/Pitoco/Zoraide SKILL), a opção real pode ser **A'**: Anna AGENT live qualificando + Francisco/Pitoco/Zoraide SKILL acessíveis via Sophia orquestração quando necessário.

- **Estado real do provisioning Meta WhatsApp** — desconhecido. Handoff 09/04 deixou a bola no manual Thales: criar Business Portfolio, pegar tokens, deploy VPS, registrar webhook. Se isso já aconteceu, Phase 1 trava em código/prompt. Se não aconteceu, trava em ação humana do Thales.

## Próximo passo exato

1. **Thales confirma** (bloqueante): (a) Parliament DAP é dos diretores da holding Doctor Auto Prime, fica dentro do dap4, separado do Chairman OS multi-projeto futuro; (b) "CSO qualificando leads" = **Anna** (Phase 1 AGENT já em `agents/parliament/voices.py` + prompt futuro — ainda não tem `anna.yaml` em `parliament/prompts/`, só sophia/francisco/pitoco/zoraide).

2. **Ler código real do Parliament antes de mais decisões:**
   - `C:\dev\dap4\agents\parliament\voices.py` (completo, já iniciei leitura)
   - `C:\dev\dap4\agents\parliament\quorum_rules.py`
   - `C:\dev\dap4\agents\parliament\session_manager.py`
   - `C:\dev\dap4\agents\parliament\synthesis.py`
   - `C:\dev\dap4\agents\parliament\prompts\*.yaml`

3. **Escrever spec** em `C:\dev\dap4\docs\superpowers\specs\2026-04-15-dap4-ia-no-ar-phase1.md` com seções:
   - Objetivo F0 (Anna AGENT live + Francisco/Pitoco/Zoraide SKILL + Sophia orquestra)
   - Gap analysis (o que falta pra Anna sair de spec pra produção)
   - Meta WhatsApp provisioning (passos de humano pro Thales)
   - Fluxo de qualificação de lead (conversação → classificação → handoff humano ou próxima ação)
   - Critério de sucesso mensurável (ex: 80% dos leads qualificados sem intervenção no primeiro turno por 2 semanas consecutivas)
   - Métricas de observabilidade (latência, taxa de handoff, erros de LLM)
   - Riscos e mitigação (LLM alucina, Meta rate limit, janela 24h, webhook duplicado)

4. **Self-review do spec**, apresentar a Thales, aguardar aprovação explícita.

5. **Só após aprovação:** invocar `superpowers:writing-plans` pra plan detalhado task-by-task.

## Setup / comandos úteis

- Vault Obsidian: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\`
- Código dap4: `C:\dev\dap4\`
- Sennin Protocol: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Sistemas\sennin-protocol.md`
- Parliament registry: `C:\dev\dap4\agents\parliament\clevel_registry.py` (13 C-Levels, lines 28-58)
- Parliament prompts: `C:\dev\dap4\agents\parliament\prompts\` (sophia_synthesis.yaml, francisco.yaml, pitoco.yaml, zoraide.yaml — **falta anna.yaml**)
- Meta WhatsApp setup guide: `C:\dev\dap4\META_SETUP_GUIDE.md` (10 passos, handoff 09/04)
- CLAUDE.md do dap4 (pode estar defasado — diz "5 agentes" mas Parliament tem 13): `C:\dev\dap4\CLAUDE.md`
- FEATURE_MAP.md (**defasado, 07/04** — lista agents legados Ana/Kimi/Sofia, não Parliament): `C:\dev\dap4\FEATURE_MAP.md`
- Para retomar direto: `/resume-handoff` (ou `/resume-handoff dap4-ia-no-ar`)
- Se precisar do visual companion: rodar `bash scripts/start-server.sh --project-dir /c/dev/dap4` de dentro do dir da skill brainstorming. Sessão anterior em `C:\dev\dap4\.superpowers\brainstorm\951-1776268207\` (expirou).
