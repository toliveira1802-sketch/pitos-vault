---
tags: [template, prompt, stitch, dap4, c-level]
created: 2026-04-10
type: design-prompt
target: Stitch (CDO)
---

# Briefing: Sala do Conselho — C-Level Room (DAP4.0)

Preciso de uma interface visual para o painel de controle do DAP4.0 (Doctor Auto Prime). O conceito é uma "Sala do Conselho" — a visão do cérebro estratégico da empresa.

## Conceito central

Um cérebro (Sophia, a CEO/Orquestradora) no centro da tela, pulsando com um glow suave violeta. Ao redor dela, dispostos em círculo orbital, ficam os 8 diretores do C-Level. Cada um conectado ao cérebro central por linhas que acendem quando o diretor está ativo.

## Os diretores

- **Anna** (CMO) — Marketing, campanhas, copy, audiência
- **Cláudio** (CTO) — Tecnologia, APIs, integrações, fluxos
- **Chico** (CFO) — Financeiro, ROI, orçamento, dados Supabase
- **Bianca** (CSO) — Estratégia, crescimento, reativação de leads
- **João** (COO) — Operações, oficina, estoque, mecânicos
- **Stitch** (CDO) — Design, criativos, identidade visual, mídia
- **Llama** (CGO) — Pesquisa de mercado, concorrência, tendências
- **Túlio** (MEC) — Mecânico Copilot, diagnóstico, procedimentos, segurança automotiva

## Comportamento visual

- **Sophia (centro):** ícone de cérebro dentro de um orbe circular com pulse animation — glow cíclico violeta (#a78bfa), 2 anéis concêntricos pulsando em tempos diferentes
- **Cada diretor:** card com ícone, nome, título (sigla), e indicador de status (standby = cinza, active = cor do diretor)
- **Linhas SVG** conectando cada diretor ao centro — tracejadas quando standby, sólidas e luminosas quando active
- **Hover num diretor:** a linha dele acende, o card ganha glow na cor dele, e aparecem tags com os skills dele
- **Cores distintas:** Anna=rosa, Cláudio=índigo, Chico=âmbar, Bianca=ciano, João=azul, Stitch=esmeralda, Llama=amarelo, Túlio=laranja

## Contexto de design

- Dark-first (fundo #09090b a #0f0f12)
- Tipografia Inter, tracking negativo, editorial
- Glass-morphism sutil nos cards (backdrop-blur, bordas semi-transparentes)
- Referências: Linear, Vercel, Apple — sofisticação, não template
- Não é dashboard operacional — é visualização estratégica, quase cinematográfica
- Depois vai integrar com a seção "Second Brain" do sistema

## Dados técnicos

- Stack: React 18 + Tailwind CSS + Framer Motion
- Componente standalone (`CLevelRoom.jsx`), importável em qualquer página
- Data-driven: array de diretores, fácil adicionar novos
- Não precisa de funcionalidade real — é mock visual pra validar o conceito

## O que NÃO quero

- Parecer template de admin
- Grid genérico de cards
- Cores pastéis ou design flat sem profundidade
- Excesso de informação — é clean, é poder visual
