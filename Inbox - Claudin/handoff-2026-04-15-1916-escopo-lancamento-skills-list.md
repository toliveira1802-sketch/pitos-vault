---
type: handoff
date: 2026-04-15
time: 19:16
project: DAP4.0-launch-planning
topic: Handoff-incremento ao 18:49 — Thales fixou que próxima sessão começa com "definir escopo do lançamento DAP 4.0" antes de tudo, e pediu lista persistida de todos skills úteis. Inventário de ~50 skills organizado por categoria.
tags: [handoff, claudin, dap4, launch, skills-inventory]
---

# Handoff — Escopo lançamento DAP 4.0 + inventário de skills

## Contexto

Handoff-incremento de 27 minutos depois do `handoff-2026-04-15-1849-dap4-pivot-kommo-hub.md` (leia aquele primeiro — toda base técnica do Phase 1a está lá). Aqui fica só o que foi decidido **depois** do 18:49.

Thales pediu explicitamente dois pontos antes de fechar o dia:

1. **Na próxima sessão, antes de qualquer outra coisa**, definir o escopo do **lançamento do DAP 4.0** — o que tem que estar público no dia zero. Não começar nem spec Kommo nem código novo antes disso.
2. Lista persistida dos **skills** disponíveis pra ele consultar quando for pensar o escopo de lançamento (e em outras sessões).

O objetivo operacional desta sessão foi responder os dois e persistir pra não perder.

## O que funcionou (com evidência)

- **Passo 0 gravado no handoff 18:49** — editei o handoff anterior adicionando seção "ANTES DE TUDO na próxima sessão (ordem obrigatória)" marcando Passo 0 como congelar escopo de lançamento DAP 4.0 antes de puxar Kommo API ou escrever spec. Evidência: `Edit` retornou sucesso; handoff anterior agora abre com esse passo antes das credenciais Kommo.

- **Inventário de skills entregue em 9 categorias** — filtrado pros ~50 mais aplicáveis a Thales (dos ~150+ totais disponíveis na sessão). Categorias:
  1. Planejamento & estratégia (brainstorming, writing-plans, blueprint, prp-*, council)
  2. DAP / Chairman OS (manha, noite, handoff, hm-*, dap-*, developmental-coach)
  3. Execução & qualidade (tdd-workflow, verification-loop, code-review, security-review, simplify)
  4. Research & dados (deep-research, market-research, exa-search, firecrawl, docs/context7)
  5. Conteúdo & marca (brand-voice, article-writing, content-engine, crosspost, x-api, seo)
  6. Design (frontend-design, liquid-glass-design, figma-*, playground)
  7. Integrações específicas (claude-api, claude-devfleet, mcp-server-patterns, e2e-testing, ui-demo, gan-*)
  8. Negócio / AIos backend (lead-intelligence, customer-billing-ops, email-ops, messages-ops, chief-of-staff, carrier/customs/energy/inventory/logistics/production/quality/returns-ops)
  9. Meta (configure-ecc, skill-creator, skill-stocktake, skill-health, prompt-optimizer)

## O que NÃO funcionou (e por quê)

- **Lista de skills foi mostrada no chat mas NÃO persistida como arquivo próprio** — ficou só no fluxo da conversa e agora neste handoff. Se Thales quiser consultar rápido fora de sessão, precisa abrir este handoff ou o anterior. Próxima sessão pode materializar em `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Sistemas\skills-inventory.md` como doc vivo.

- **Não defini o escopo do lançamento DAP 4.0 nesta sessão** — por desenho: Thales explicitamente pediu "vamos definir na próxima sessão". Não force brainstorming agora que já está tarde e o foco era encerrar. Risco: retomar amanhã sem pauta clara pode dispersar — mitigação: Passo 0 do handoff 18:49 já define o formato da saída ("1 página DAP 4.0 Launch Scope com escopo congelado").

## O que ainda não foi tentado

- **Materializar `skills-inventory.md` no vault PITOS** em `Sistemas/` — doc vivo com as 9 categorias acima, cada skill com 1 linha de descrição e cenário de uso. Serviria como "menu" que Thales consulta antes de pedir algo e Claudin também consulta pra não esquecer o que tem disponível.

- **Invocar skill `brainstorming`** na próxima sessão pra executar o Passo 0 (escopo de lançamento) — é o caminho certo pra forçar exploração antes de converger. Evita o mesmo erro da sessão das 10:07 onde pulei pra writing-plans sem spec.

- **Skill `council` (4 vozes) pra decisão do escopo DAP 4.0** — se depois do brainstorming ficar ambíguo o que entra no dia zero vs o que fica pra v1.1, council pode desempatar com perspectivas de go-to-market / técnica / segurança / custo.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\handoff-2026-04-15-1849-dap4-pivot-kommo-hub.md` | Editado | Adicionada seção "Passo 0 — Definir escopo do lançamento DAP 4.0" antes de Passo 1 (credenciais Kommo). |
| `C:\Users\docto\.claude\projects\C--Users-docto\memory\project_dap4_phase1a_ia_no_ar.md` | Atualizado (na sessão anterior) | Já reflete pivô Kommo. Pode precisar nova atualização na próxima sessão após escopo de lançamento definir se Phase 1a-Kommo é parte do lançamento ou só etapa interna. |
| Lista de skills | Entregue em chat | Ainda não materializada em arquivo. Backlog. |

Código (Phase 1a/Kommo/etc): **zero mudanças nesta sessão-incremento.** Branch `feat/anna-phase1a` inalterada desde o commit afefa4c (playground). Worktree `C:/dev/dap4-anna-phase1a` limpo.

## Decisões tomadas

- **Próxima sessão começa com brainstorming de escopo de lançamento DAP 4.0, não com código Kommo** — razão (Thales, literal): "vamos definir na proxima sessao antes de tudo, o que entregar pro lançamento da DAP 40". Qualquer código novo antes dessa definição corre risco de ser jogado fora ou de priorizar o errado. Passo 0 é gate hard.

- **Lista de skills inclui domínios operacionais AIos (carrier/customs/energy/inventory/logistics/production/quality/returns)** — razão: embora fora do escopo DAP automotivo hoje, são skills do AIos que podem ser ativados quando Parliament/Chairman OS ganhar 2º cliente fora de automotivo. Útil ter no radar pra arquiteturar multi-tenant desde já.

- **Skills que omiti da lista** — utilitários de build (`build-fix`, `cpp-build`, `flutter-build`, `go-build`, `rust-build`, `kotlin-build`, `dart-flutter-patterns`, etc.), reviewers por linguagem redundantes com `code-review` genérico, e shims legacy (`tdd`, `docs`, `e2e`, `orchestrate`, `prompt-optimize` etc. que apontam pra skills modernos). Razão: Thales é CTO-dirigente, não implementador. Lista foca no que ele invocaria, não no que Claudin usa por baixo.

## Bloqueios & perguntas abertas

- **Nenhum bloqueio novo.** Bloqueios herdados do handoff 18:49:
  - KOMMO_TOKEN + KOMMO_DOMAIN pendentes
  - RTBM do Thales pendente
  - Phase 1a-Kommo spec ainda não escrito

- **Pergunta aberta pra próxima sessão:** "DAP 4.0 lançamento" = **lançamento público** do produto/marca/ecossistema (anúncio mercado, site público, presença digital), ou = **lançamento interno operacional** (Anna no ar + dashboard operando + leads classificados)? Definição dessa distinção no início do Passo 0 determina 90% das escolhas subsequentes.

## Próximo passo exato

**Na próxima sessão, abrir com:**

1. **Ler este handoff + o 18:49** (via `/resume-handoff` — por padrão pega o mais recente, que é este).
2. **Invocar `superpowers:brainstorming`** com o input: "DAP 4.0 launch scope — o que tem que estar pronto no dia do lançamento (público ou interno, primeiro definir), quais features, quais canais ativos, qual data-alvo, qual nível de Anna (lê/responde/qualifica), qual visual mínimo dashboard, qual comunicação mercado."
3. **Saída do brainstorming deve ser:** documento de 1 página em `C:\dev\dap4\docs\superpowers\specs\2026-04-XX-dap4-launch-scope.md` com escopo congelado (features dentro / features fora) + data-alvo + critérios de "launch-ready".
4. **Só depois:** decidir se Phase 1a-Kommo faz parte do lançamento ou é etapa preparatória. Então (se for parte) puxar credenciais Kommo + escrever spec Kommo Hub.

## Setup / comandos úteis

- **Para retomar:** `/resume-handoff` (sem argumento, pega este que é o mais recente)
- **Skills consultáveis na próxima sessão** (bloco abaixo replicado pro Thales ter no próprio handoff sem depender do chat):

### Planejamento & estratégia
`brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `blueprint`, `prp-prd`, `prp-plan`, `council`, `agent-sort`

### DAP / Chairman OS
`manha`, `noite`, `handoff`, `resume-handoff`, `hm-init`, `hm-engineer`, `hm-designer`, `hm-qa`, `hm-fix`, `hm-deploy`, `hm-skill-creator`, `dap-content`, `dap-dev`, `dap-reviewer`, `developmental-coach`, `sennin-protocol` (referência no vault PITOS/Sistemas)

### Execução & qualidade
`tdd-workflow`, `verification-loop`, `code-review`, `security-review`, `simplify`, `refactor-clean`

### Research & dados
`deep-research`, `market-research`, `exa-search`, `firecrawl`, `docs` (context7)

### Conteúdo & marca
`brand-voice`, `article-writing`, `content-engine`, `crosspost`, `x-api`, `seo`

### Design
`frontend-design`, `liquid-glass-design`, `figma-create-design-system-rules`, `figma-code-connect`, `figma-generate-design`, `figma-implement-design`, `figma-generate-library`, `figma-use`, `playground`

### Integrações específicas
`claude-api`, `claude-devfleet`, `mcp-server-patterns`, `e2e-testing`, `ui-demo`, `gan-generator`, `gan-evaluator`, `gan-planner`

### Negócio / AIos backend
`lead-intelligence`, `customer-billing-ops`, `finance-billing-ops`, `email-ops`, `messages-ops`, `chief-of-staff`, `carrier-relationship-management`, `customs-trade-compliance`, `energy-procurement`, `inventory-demand-planning`, `logistics-exception-management`, `production-scheduling`, `quality-nonconformance`, `returns-reverse-logistics`

### Meta
`configure-ecc`, `skill-creator`, `skill-stocktake`, `skill-health`, `prompt-optimizer`

**Total na lista curada:** ~60 skills. Universo completo: ~150+ (inclui reviewers por linguagem, build resolvers, shims legacy, MCPs de terceiros).
