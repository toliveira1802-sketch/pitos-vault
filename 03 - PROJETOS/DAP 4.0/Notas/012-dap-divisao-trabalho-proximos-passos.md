---
title: Divisão de trabalho — Claude aqui × Antigravity lá
date: 2026-04-13
status: active
tags: [dap4, operacao, workflow, proximos-passos]
---

# Divisão de trabalho — Thales + Claude ↔ Antigravity

Thales opera estratégia + decisões aqui com Claude. Antigravity executa dev + seeding em paralelo, seguindo o briefing `011-dap-antigravity-briefing.md`. Esta nota é o mapa de como os dois fluxos se encontram.

## O que rola aqui (sessão Thales + Claude)

### Estratégia + decisões de alto impacto

- Rota estratégica DAP 4.0 (revisar `002-dap40-rota-estrategica.md` com olhar atualizado) — R$300k → R$700k, priorizar alavancas, validar sequência de unidades
- Playbook Doctor Auto Prime: positioning premium, defensibilidade vs concorrentes, preço como sinal de qualidade
- Arquitetura das próximas fases: DAP AI (SaaS), DAP Ensina (Hotmart), DAP Studio (conteúdo), DAP Social (Instagram + YouTube + blog)
- Decidir quando migrar WhatsApp pra Meta direto (libera outbound real pelo portal, desacopla do Kommo)

### Produto + design

- Code review de PRs que o Antigravity abre — padrão Linear / Stripe / Vercel. Nada mediano shippa.
- Design direction de cada página WIP **antes** de Antigravity atacar (evita retrabalho)
- Identidade visual + voz da marca consolidada pras 12 unidades — referências, guideline, dark-first, tipografia editorial
- Revisar UX de fluxos críticos: atendimento WhatsApp, classificação de lead, resposta manual, histórico

### Conteúdo + RAG

- Extrair conhecimento do Thales (diagnóstico elétrico, alemães premium, SOPs operacionais) → notas Obsidian estruturadas → ingestão no RAG → produto externo (YouTube scripts, Hotmart minicurso, blog posts)
- Roteiros + scripts + calendário MKT (evoluir `005-dap-calendario-anual-mkt.md`)
- Transformar nota `004-dap-copilot-diagnostico-eletrico.md` em base de treinamento da Ana

### Operação + iteração

- Monitorar o que entra no portal — leads classificados, padrões que a Ana identifica, falsos positivos/negativos
- Iterar o prompt do `intent_classifier` conforme conversas reais revelarem limites
- Responder clientes-chave quando pedir julgamento humano
- Decidir quando ativar outbound automático (hoje classify-only) — precisa de confiança na Ana primeiro

## O que rola lá (Antigravity + Claude dentro dele)

Ver `011-dap-antigravity-briefing.md`. Resumo das prioridades:

- **P0:** fechar WhatsApp — merge branch, login Supabase, outbound via Salesbot, socket auth
- **P1:** povoar dados reais — RAG knowledge base, seed leads do Kommo, classificar retroativo
- **P2:** ativar páginas WIP uma por vez — Digital Brain, Sofia Hub, Blog Generator, Agent Fleet, Skill Builder, Communications, Ingestion
- **P3:** tech debt — SSH dap4, HMAC webhook, rotacionar keys, cleanup

## Cadência + pontos de contato

- **Antigravity reporta status** por task: commit/PR + screenshot + 1 parágrafo
- **Thales revisa com Claude aqui** antes de aprovar merge em master
- **Decisões arquiteturais** (escolher lib, quebrar contrato, mudar schema) → Antigravity pede aqui, Thales + Claude definem, manda de volta
- **Tech debt nova descoberta** por Antigravity → vira entrada neste arquivo ou no 010, prioridade atribuída por Thales

## Quando Thales me chama aqui

- "Revisa PR X do Antigravity" → code review no padrão world-class
- "Bora pensar a rota do DAP [unidade]" → brainstorming estruturado
- "Extrai esse conhecimento pro RAG" → vira notas Obsidian + plano de ingestão
- "Design da página X" → wireframe + referências + spec
- "Cliente escreveu isso, o que fazemos?" → análise + resposta pronta
- "Antigravity tá perdido em Y" → analiso o contexto, devolvo direção clara pra ele

## Primeira escolha

Qual das frentes abaixo abrir primeiro na dupla Thales + Claude enquanto Antigravity roda os P0 do briefing? (marca uma)

- [ ] **Rota estratégica DAP 4.0 rev** — revisar 002 com lente atual
- [ ] **Knowledge base RAG** — extrair SOPs + diagnósticos da cabeça do Thales
- [ ] **Design direction Digital Brain** — spec antes de Antigravity atacar
- [ ] **Positioning + voz de marca** — guideline consolidado pros 12 unidades
- [ ] **Iterar prompt Ana** — ver conversas reais que chegarem e afinar classificação
- [ ] **Outro:** _____
