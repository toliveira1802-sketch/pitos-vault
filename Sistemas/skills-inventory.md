---
type: reference
topic: Skills Inventory DAP/Chairman OS
updated: 2026-04-15
tags: [skills, claudin, referencia]
---

# Skills Inventory — quando invocar o quê

Doc vivo. ~60 skills curados dos ~150+ totais instalados. Foco em skills que Thales (CTO-dirigente, não implementador) invocaria diretamente. Reviewers por linguagem, build resolvers e shims legacy ficam de fora — Claudin usa por baixo.

## Como ler
- **`/skill`** — 1 linha do que faz
  - *Quando invocar:* cenário concreto e aplicável à realidade DAP

---

## 1. Planejamento & estratégia

- **`/brainstorming`** — Gera ideias em volume, diverge antes de convergir
  - *Quando invocar:* antes de definir nome de produto, modelo de negócio, ângulo de conteúdo ou solução para um gargalo operacional

- **`/writing-plans`** — Produz plano estruturado de implementação antes de qualquer código
  - *Quando invocar:* início de qualquer feature nova no DAP4.0 ou Parliament que envolva mais de 2 arquivos

- **`/executing-plans`** — Executa plano em etapas verificáveis, com checkpoints
  - *Quando invocar:* quando o plano já existe e precisa ser materializado com rastreabilidade

- **`/subagent-driven-development`** — Orquestra múltiplos agentes paralelos numa tarefa complexa
  - *Quando invocar:* build de nova vertical do ecossistema DAP, refatoração de módulo crítico ou tarefa que exige mais de uma perspectiva simultânea

- **`/blueprint`** — Gera documento de arquitetura de sistema antes de implementar
  - *Quando invocar:* antes de criar um novo serviço, integração ou módulo no DAP4.0

- **`/prp-prd`** — Produz PRD (Product Requirements Document) formal
  - *Quando invocar:* antes de especificar uma nova feature para Anna, Kommo Hub ou qualquer módulo do Chairman OS

- **`/prp-plan`** — Transforma PRD em plano técnico detalhado
  - *Quando invocar:* logo depois do `/prp-prd`, para passar de "o quê" para "como"

- **`/council`** — Convoca múltiplas perspectivas analíticas sobre uma decisão
  - *Quando invocar:* decisão estratégica crítica — entrar numa vertical nova, contratar, pivô de produto, pricing do SaaS

- **`/agent-sort`** — Seleciona o agente ou skill certo para uma tarefa
  - *Quando invocar:* quando não sabe qual skill usar ou quer validar escolha antes de despachar

---

## 2. DAP / Chairman OS

- **`/manha`** — Ritual matinal: carrega contexto, prioriza o dia, ativa o Claudin
  - *Quando invocar:* início de toda sessão de trabalho

- **`/noite`** — Ritual noturno: fecha loops, registra decisões, prepara handoff
  - *Quando invocar:* fim de sessão ou antes de dormir

- **`/handoff`** — Gera documento de handoff para próxima sessão ou agente
  - *Quando invocar:* ao pausar trabalho em progresso — garante continuidade sem perda de contexto

- **`/resume-handoff`** — Retoma sessão a partir de handoff existente
  - *Quando invocar:* início de sessão com trabalho em andamento de sessão anterior

- **`/hm-init`** — Inicializa novo projeto com stack, estrutura e padrões world-class
  - *Quando invocar:* criação de qualquer novo projeto do ecossistema DAP (nova vertical, microserviço, SaaS)

- **`/hm-engineer`** — Valida código em todas as camadas: arquitetura, segurança, performance, qualidade
  - *Quando invocar:* após qualquer entrega técnica relevante antes de considerar pronto

- **`/hm-designer`** — Valida interface contra padrão de design world-class (Apple/Linear/Stripe)
  - *Quando invocar:* após construir qualquer tela nova do dashboard DAP4.0 ou portal externo

- **`/hm-qa`** — Testa tudo, encontra gaps, cobre fluxos críticos
  - *Quando invocar:* antes de deploy em produção de qualquer feature na VPS

- **`/hm-fix`** — Diagnostica e corrige bugs com rastreamento de causa raiz
  - *Quando invocar:* quando algo quebra em produção na VPS (76.13.170.42)

- **`/hm-deploy`** — Orquestra deploy seguro para produção
  - *Quando invocar:* ao promover build validado para a VPS via Cloudflare Tunnel

- **`/hm-skill-creator`** — Cria novos skills customizados para o ecossistema Thales
  - *Quando invocar:* quando perceber que um padrão de trabalho se repete e merece virar skill próprio

- **`/dap-content`** — Gera, estrutura e adapta conteúdo para o ecossistema DAP
  - *Quando invocar:* produção de posts, roteiros, copy de lançamento, materiais do DAP Ensina

- **`/dap-dev`** — Execução técnica focada no codebase DAP4.0
  - *Quando invocar:* qualquer tarefa de implementação em `C:\dev\dap4`

- **`/dap-reviewer`** — Review especializado no contexto do produto DAP
  - *Quando invocar:* antes de fechar qualquer PR no repositório DAP4.0

- **`/developmental-coach`** — Coaching de desenvolvimento para Thales ou membros do time
  - *Quando invocar:* reflexão sobre decisões de liderança, crescimento pessoal, estruturação de equipe

- **`sennin-protocol`** *(referência de vault, não skill clicável)* — OS do Thales em 4 camadas: princípios, ritmo, decisão, execução
  - *Fonte:* `PITOS/Sistemas/sennin-protocol.md` — leia antes de qualquer redesenho de rotina ou sistema de trabalho

---

## 3. Execução & qualidade

- **`/tdd-workflow`** — Guia ciclo Red-Green-Refactor com cobertura 80%+
  - *Quando invocar:* início de qualquer feature nova no backend do DAP4.0 ou Parliament

- **`/verification-loop`** — Loop de verificação iterativa até todos os critérios passarem
  - *Quando invocar:* quando uma implementação está "quase funcionando" e precisa de garantia antes do merge

- **`/code-review`** — Review geral de qualidade, padrões e boas práticas
  - *Quando invocar:* após qualquer bloco de código novo antes de considerar finalizado

- **`/security-review`** — Análise de vulnerabilidades, OWASP Top 10, exposição de dados
  - *Quando invocar:* antes de qualquer deploy que envolva autenticação, Supabase, WhatsApp API ou dados de leads

- **`/simplify`** — Revisa código buscando redundâncias, complexidade desnecessária e reúso
  - *Quando invocar:* depois de iterações rápidas que acumularam dívida técnica

- **`/refactor-clean`** — Remove código morto, reorganiza módulos, melhora coesão
  - *Quando invocar:* ao perceber que um módulo cresceu demais ou perdeu clareza de responsabilidade

---

## 4. Research & dados

- **`/deep-research`** — Pesquisa profunda e estruturada sobre um tema
  - *Quando invocar:* antes de entrar numa vertical nova do ecossistema DAP (ex: DAP Estética, DAP Funilaria) ou estudar concorrência

- **`/market-research`** — Análise de mercado, benchmarks, tendências
  - *Quando invocar:* ao validar hipótese de produto, definir pricing do SaaS DAP AI ou estruturar proposta comercial

- **`/exa-search`** — Busca web semântica de alta qualidade
  - *Quando invocar:* quando precisa de referências reais e atuais que o modelo não tem (ex: preço peças BMW 2025, regulação LGPD nova)

- **`/firecrawl`** — Scraping e extração estruturada de sites
  - *Quando invocar:* ao coletar dados de concorrentes, preços de peças ou informações de portais automotivos

- **`/docs`** *(context7)* — Documentação atualizada de bibliotecas, frameworks e APIs
  - *Quando invocar:* antes de usar Supabase, Kommo API, WhatsApp Cloud API, React, FastAPI — especialmente pra confirmar sintaxe e versão

---

## 5. Conteúdo & marca

- **`/brand-voice`** — Define e aplica a voz da marca DAP em qualquer formato
  - *Quando invocar:* ao criar copy de campanha, script de vídeo, email marketing ou qualquer peça de comunicação externa

- **`/article-writing`** — Produz artigos de alta qualidade editorial
  - *Quando invocar:* ao criar conteúdo para o blog DAP, materiais do DAP Ensina ou artigos de autoridade no segmento alemão

- **`/content-engine`** — Sistema de produção de conteúdo em série (RAG → múltiplos formatos)
  - *Quando invocar:* ao montar calendário de conteúdo ou transformar SOPs internos em produto externo (Hotmart, YouTube, blog)

- **`/crosspost`** — Adapta um conteúdo para múltiplos canais (Instagram, YouTube, LinkedIn)
  - *Quando invocar:* após produzir peça principal — maximiza alcance sem retrabalho

- **`/x-api`** — Integração com API do X/Twitter para automação ou publicação
  - *Quando invocar:* se DAP Social expandir para X como canal de distribuição

- **`/seo`** — Otimização para busca orgânica — estrutura, palavras-chave, metadados
  - *Quando invocar:* ao publicar conteúdo no blog DAP ou estruturar páginas de serviço do site `doctorautoprime40.com`

---

## 6. Design

- **`/frontend-design`** — Implementação de interfaces world-class (dark-first, editorial, cinematográfico)
  - *Quando invocar:* ao construir qualquer nova tela do dashboard DAP4.0 ou portal externo

- **`/liquid-glass-design`** — Design com efeitos de profundidade, vidro e materialidade premium
  - *Quando invocar:* quando a interface precisa de diferenciação visual máxima — ex: tela de apresentação para cliente ou portal do DAP Performance

- **`/figma-create-design-system-rules`** — Cria sistema de design com tokens, regras e componentes
  - *Quando invocar:* ao iniciar design system do DAP4.0 no Figma

- **`/figma-generate-design`** — Gera telas no Figma a partir de descrição
  - *Quando invocar:* ao prototipar rapidamente nova feature antes de implementar

- **`/figma-implement-design`** — Transforma design Figma em código front-end
  - *Quando invocar:* após aprovação de layout no Figma, para materializar em React/TSX

- **`/figma-generate-library`** — Gera biblioteca de componentes no Figma
  - *Quando invocar:* ao estruturar componentes reutilizáveis do Chairman OS UI

- **`/figma-code-connect`** — Conecta componentes Figma com componentes de código
  - *Quando invocar:* para manter sincronismo design↔código no DAP4.0

- **`/figma-use`** — Operações gerais no Figma via MCP
  - *Quando invocar:* leitura, navegação e manipulação de arquivos Figma existentes

- **`/playground`** — Ambiente de experimentação rápida de UI/UX sem afetar produção
  - *Quando invocar:* ao testar conceitos visuais novos antes de commitar direção de design

---

## 7. Integrações específicas

- **`/claude-api`** — Build e debug de apps usando a API da Anthropic com prompt caching
  - *Quando invocar:* ao desenvolver ou ajustar Anna, Parliament ou qualquer agente do Chairman OS que usa SDK Anthropic

- **`/claude-devfleet`** — Orquestra fleet de agentes Claude para tarefas paralelas
  - *Quando invocar:* quando uma tarefa grande pode ser paralelizada em múltiplos agentes simultâneos

- **`/mcp-server-patterns`** — Padrões para criar e integrar servidores MCP
  - *Quando invocar:* ao adicionar nova integração MCP ao Chairman OS (ex: Kommo, Meta Business)

- **`/e2e-testing`** — Testes end-to-end com Playwright para fluxos críticos
  - *Quando invocar:* antes de qualquer deploy que afete fluxo de lead → OS → faturamento

- **`/ui-demo`** — Gera demo interativa de UI para apresentação
  - *Quando invocar:* ao preparar demo do DAP4.0 para investidor, parceiro ou cliente enterprise

- **`/gan-generator`** — Geração de assets visuais via GAN
  - *Quando invocar:* ao precisar de imagens geradas para campanha ou material de marca DAP

- **`/gan-evaluator`** — Avalia qualidade de outputs gerados por IA
  - *Quando invocar:* ao validar assets de IA antes de publicar em material oficial DAP

- **`/gan-planner`** — Planeja pipeline de geração de assets visuais
  - *Quando invocar:* ao estruturar produção visual em série para DAP Studio

---

## 8. Negócio / AIos backend

> **[AIos backend — ativar quando Parliament ganhar 2º cliente]**
> Skills abaixo são operacionais enterprise. Irrelevantes para DAP interno hoje. Ficam documentadas para quando o Chairman OS virar produto SaaS com clientes reais.

- **`/lead-intelligence`** — Enriquecimento e scoring de leads com dados externos
  - *Quando ativar:* ao escalar base de 5.911 leads do Supabase com qualificação automática

- **`/customer-billing-ops`** — Gestão de cobrança e ciclo de vida do cliente
  - *Quando ativar:* ao lançar plano pago do DAP AI como SaaS

- **`/finance-billing-ops`** — Operações financeiras internas, conciliação, relatórios
  - *Quando ativar:* ao estruturar financeiro automatizado do DAP como holding

- **`/email-ops`** — Automação de operações de email (transacional, campanhas)
  - *Quando ativar:* ao montar esteira de nutrição de leads fria para DAP Prime

- **`/messages-ops`** — Automação de mensagens multicanal (WhatsApp, SMS, push)
  - *Quando ativar:* ao expandir Anna para canais além do WhatsApp atual

- **`/chief-of-staff`** — Agente de coordenação executiva e priorização de agenda
  - *Quando ativar:* ao formalizar Chairman OS como produto para outros founders/CTOs

- **`/carrier-relationship-management`** — Gestão de relacionamento com transportadoras
  - *Quando ativar:* se DAP expandir para logística de peças ou frota

- **`/customs-trade-compliance`** — Compliance de importação e regulatório
  - *Quando ativar:* se DAP importar peças diretamente da Europa/Ásia

- **`/energy-procurement`** — Gestão de compra de energia (industria/frota)
  - *Quando ativar:* ao escalar para múltiplas unidades físicas DAP

- **`/inventory-demand-planning`** — Planejamento de estoque e demanda
  - *Quando ativar:* ao integrar gestão de peças ao DAP4.0 (ERP de oficina)

- **`/logistics-exception-management`** — Gestão de exceções logísticas
  - *Quando ativar:* ao estruturar supply chain de peças premium

- **`/production-scheduling`** — Agendamento de produção/capacidade operacional
  - *Quando ativar:* ao automatizar agenda dos 9 elevadores via DAP4.0

- **`/quality-nonconformance`** — Gestão de não-conformidades e qualidade
  - *Quando ativar:* ao implementar ISO ou certificação de qualidade no DAP Prime

- **`/returns-reverse-logistics`** — Gestão de devoluções e logística reversa
  - *Quando ativar:* ao estruturar política de garantia e devolução de peças

---

## 9. Meta

- **`/configure-ecc`** — Configura o ambiente Claude Code (settings, hooks, permissões)
  - *Quando invocar:* ao ajustar comportamentos automáticos do Claudin, adicionar permissões ou configurar hooks

- **`/skill-creator`** — Cria novo skill customizado do zero
  - *Quando invocar:* ao identificar padrão de trabalho recorrente que vale virar skill (ex: `/dap-briefing`, `/lead-score`)

- **`/skill-stocktake`** — Auditoria do inventário de skills instalados
  - *Quando invocar:* mensalmente ou quando suspeitar que algum skill ficou obsoleto ou duplicado

- **`/skill-health`** — Verifica saúde e funcionamento dos skills instalados
  - *Quando invocar:* quando um skill retorna comportamento inesperado ou parece não funcionar

- **`/prompt-optimizer`** — Otimiza prompts para melhor performance e eficiência de tokens
  - *Quando invocar:* antes de publicar um prompt em produção (ex: system prompt da Anna, Parliament, Sophia)

---

## Skills omitidos (referência)

Buildresolvers (`/build-fix`, `/cpp-build`, etc.), reviewers por linguagem (`/python-review`, `/go-review`, etc.), shims legacy, MCPs de terceiros (Supabase, ClickUp, Gmail, Notion) — Claudin detecta contexto e usa automaticamente. Thales não precisa invocar manualmente.
