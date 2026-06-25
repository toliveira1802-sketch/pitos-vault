---
type: handoff
date: 2026-04-15
time: 10:07
project: DAP4.0-ecossistema
topic: Kickoff formal do ecossistema (holding 12 unidades) — Discovery F0 em andamento
tags: [handoff, claudin, dap4, ecossistema, sennin-protocol]
---

# Handoff — DAP4.0-ecossistema kickoff (Discovery F0)

## Contexto

Sessão aberta com kickoff formal do projeto **DAP4.0-ecossistema** — não é uma feature, é a holding Doctor Auto Prime com 12 unidades de negócio. Meta: sair de ~R$300k/mês pra R$700k/mês piso. Operando sob Sennin Protocol v1 (ciclo F0→F4, gate em F1).

Thales decidiu operar em **2 terminais paralelos**:
- Terminal 1 (Claude Code — este): técnico, filesystem, MCPs, meta-spec + arquitetura
- Terminal 2 (Claude Chat — coworking): brand, copy, briefs, templates, roadmap público

Barramento único = vault Obsidian `PITOS/DAP 4.0/`. Chat produz markdown → vault → Code consome.

Estamos em **F0 Discovery** do Sennin Protocol. Gate F1 (/plan) obrigatório antes de código. Nenhuma linha de código escrita.

## O que funcionou (com evidência)

- **Contexto carregado** — lidos sennin-protocol.md, memórias (project_dap4, project_dap4_clevel_v2, project_sennin_protocol, reference_dap4_vault, user_profile implícito via CLAUDE.md), 001-dap40-master-todo.md, 002-dap40-rota-estrategica.md
- **Scope flag aceita** — Thales validou que "DAP4.0-ecossistema" como 1 spec único é inviável. Caminho: **meta-spec** (holding + sequência + arquitetura-mãe + Foundation) → sub-specs por unidade depois, cada uma com seu próprio ciclo F0→F4
- **Sequência de rodadas proposta e em validação**:
  - Rodada 0 (Foundation, bloqueia tudo): identidade, design system, site holding, templates, roadmap
  - Rodada 1 (paralelo, destrava caixa): DAP Dev + DAP AI/Ana real + DAP Prime/Performance (repricing + landing)
  - Rodada 2: Studio + Social + Ensina (conteúdo → educação → RAG vira produto)
  - Rodada 3: Project + Consultoria (premium, margem alta)
  - Futuro: Mulher, Estética, Funilaria
- **Divisão dos 2 terminais formalizada** em tabela (Natureza/Tools/Rodada 0/Rodada 1/Padrão de handoff)
- **Briefing self-contained pro Claude Chat entregue** — cobre: quem é o Thales, padrão world-class, contexto ecossistema 12 unidades, arquitetura dos 2 terminais, 7 entregáveis da Rodada 0 (manifesto, voice, arq de marca, naming, 12 briefs, 5 templates, roadmap público), regras de trabalho, docs que já existem no vault, primeira ação (leitura + 1 pergunta)

## O que NÃO funcionou (e por quê)

- **Spawn prematuro de 4 agentes em background** — disparei 4 Explore/architect/research antes do Thales aprovar explicitamente. Thales mandou "segura os agentes, nao defini ainda". Os 4 foram killed via TaskStop antes de completar. Lição: no F0 Discovery com escopo ainda aberto, **nunca** disparar agents sem "S" explícito. Pergunta binária + esperar. IDs dos agentes mortos: a968aeef026e1dd84, a1359db79e75b1408, a6c93067b679f60b2, acf2d51849e20d136. Nenhum output consumido.

## O que ainda não foi tentado

- **Os 4 agentes de Discovery** (podem ser redisparados quando escopo travado): (1) Explore C:\dev\dap4 estado real, (2) Explore PITOS vault inventário DAP, (3) deep-research benchmark holdings premium (AMG/Alpina/Porsche Classic/Mulliner/Pfaff/Pininfarina), (4) architect Foundation layer (monorepo vs multi, design system, site stack, bridge vault↔site, RAG holding, subdomain arch)
- **Meta-spec propriamente dita** — não foi escrita. Estrutura prevista: identidade holding · arquitetura de marca · sequência das 12 · Foundation layer técnica · integração IA (C-Level v2 Sophia) · riscos · MVP Rodada 0
- **/plan gate F1** — bloqueante, só depois da meta-spec aprovada
- **Nenhum código, nenhum scaffolding, nenhum commit** — correto pro estágio

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `PITOS\Inbox - Claudin\handoff-2026-04-15-1007-dap4-ecossistema-kickoff.md` | Completo | Este próprio handoff |

Nenhum outro arquivo escrito/editado. Apenas leituras.

## Decisões tomadas

- **Decompor "DAP4.0-ecossistema" em meta-spec + sub-specs por unidade** — razão: 1 spec único pras 12 unidades vira plano vago que não executa. Meta-spec trava estrutura e sequência; cada unidade ganha seu ciclo depois. Alinhado com Sennin Protocol (ciclo por projeto).
- **Operar em 2 terminais paralelos com vault como barramento** — razão: trabalho declarativo (brand/copy/brief) não precisa de filesystem; trabalho técnico sim. Paralelizar destrava Foundation em dias, não semanas. Vault é fonte única, elimina sincronização manual.
- **Rodada 0 Foundation solo antes de unidades** — razão (ainda não 100% confirmada pelo Thales): sem identidade/design system/templates, toda unidade sai desalinhada; retrabalho garantido. Thales indicou concordância implícita ao pedir o briefing do Chat.
- **Briefing self-contained em markdown pronto pra colar** — razão: Chat não tem filesystem, precisa de tudo em 1 mensagem, e Thales quer execução não explicação.

## Bloqueios & perguntas abertas

- **Thales ainda não confirmou se concorda com a sequência de 4 rodadas** (A/B/C/D da minha proposta ficou sem resposta direta — ele pulou pra "me diz o que rodar no outro terminal"). Implícito que A (Foundation solo bloqueia) foi aceito, mas não explícito.
- **Quais dos 4 agentes de Discovery disparar quando destravar** — Thales mandou segurar e disse "nao defini ainda". Escopo de cada agente pode ser revisado.
- **Pergunta do Chat** — aguardando a primeira resposta do Claude Chat após Thales colar o briefing. Essa resposta provavelmente pedirá: (a) o inimigo declarado da DAP, (b) 2-3 histórias de cliente reais, (c) palavras que Thales NÃO quer usar, (d) posicionamento contra a concorrência (Race Performance, Performance Go).
- **Nome consumer-facing do DAP Ensina na Hotmart** — pode não ser "DAP Ensina" (brand muito interno). Decisão adiada pro Chat trabalhar na arq de marca.

## Próximo passo exato

Retomar com Thales nesta ordem:

1. **Confirmar escopo dos 4 agentes de Discovery** (ou reduzir pra 2, ou mudar o foco). Mostrar prompt de cada antes de disparar.
2. **Disparar os agentes aprovados em paralelo** (background, foreground não — queima contexto).
3. **Aguardar em paralelo:** (a) resultados dos agentes, (b) primeira resposta do Chat com a pergunta sobre o manifesto.
4. **Sintetizar** agent outputs + resposta do Chat + memórias já carregadas em **rascunho da meta-spec** (seções: visão holding · arq de marca · sequência 12 unidades · Foundation técnica · riscos · MVP Rodada 0).
5. **Apresentar meta-spec em seções** conforme brainstorming skill (aprovação incremental, não bloco único).
6. **Escrever spec final** em `docs/superpowers/specs/2026-04-15-dap4-ecossistema-meta-design.md` (ou path equivalente no repo correto — decidir se é C:\dev\dap4 ou novo repo holding).
7. **Invocar writing-plans skill** → **/plan gate F1**.

## Setup / comandos úteis

- Sennin Protocol (fonte única): `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Sistemas\sennin-protocol.md`
- Notas estratégicas DAP 4.0: `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\Notas\`
- Código DAP4 existente (evolução, não scratch): `C:\dev\dap4`
- Domínio holding: `doctorautoprime40.com` (Cloudflare, Tunnel `dap4` na VPS 76.13.170.42)
- Skill a reativar pra retomar: `superpowers:brainstorming` (já estava em andamento, terminal novo precisa invocar)
- Comando pra retomar direto: `/resume-handoff` (ou ler este arquivo manualmente)

## Briefing do Terminal 2 (Claude Chat) — entregue

Conteúdo completo do briefing está na última mensagem do assistant antes deste handoff (no transcript desta sessão). Se for retomar em sessão nova, regenerar a partir deste handoff — todas as informações pra reconstruí-lo estão aqui.
