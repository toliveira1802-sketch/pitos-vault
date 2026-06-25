# DAP 4.0 — Campanha Claude Desktop · v0 + Roadmap v1→v4

> **Data:** 2026-04-13
> **Owner:** Thales
> **Executor:** Claude Desktop (com MCPs: Obsidian/PITOS, Supabase, ClickUp, Ahrefs, Gmail, Notion, Webflow)
> **Alvo de negócio:** destravar o gargalo #1 da DAP Prime — geração de lead qualificado de dono de alemão premium (BMW, Audi, Mercedes, VW) para encher os 9 elevadores ociosos (45% → 85%) e levar o faturamento de ~R$300k/mês → R$700k/mês.

---

## Princípios da campanha

1. **Um ativo, dois mercados.** Todo conteúdo produzido serve leitor final (lead) e produto interno (DAP Ensina / RAG). Zero retrabalho.
2. **RAG-first.** Nada é publicado sem antes virar memória do ecossistema (ChromaDB + vault PITOS).
3. **Claude Desktop como editor-chefe.** Thales dirige, Desktop executa: pesquisa, estrutura, gera, revisa, publica, mede.
4. **Dark-first, editorial, premium.** Se parece template, reprova. Referência: Linear, Stripe, Apple.
5. **Cada versão é entregável.** v0 ship essa semana. v1–v4 não são promessas — são estados com critério de saída explícito.

---

## v0 — Campanha "Alemão Premium Merece Diagnóstico Premium"

**Prazo:** 7 dias corridos a partir do dia 0.
**Escopo:** lançar UMA campanha vertical e funcional ponta-a-ponta, manual, sem automação, sem SaaS. Validar mensagem, funil e conversão.

### Tese central
Dono de BMW/Audi/Mercedes/VW em São Paulo **não quer mecânico** — quer **engenheiro de confiança**. A campanha vende diagnóstico (não reparo), entregando autoridade técnica visível antes da primeira visita.

### Produto de entrada (isca)
**"Checklist de Diagnóstico Premium — 27 pontos que a concessionária não olha"**
- PDF editorial (dark, tipografia editorial, zero cara de template)
- Assinado "Thales — Chairman, Doctor Auto Prime"
- Gated por WhatsApp (linha Prime)

### Funil v0 (manual)

```
Ahrefs (pesquisa) → Conteúdo (3 peças) → Tráfego orgânico + 1 ad teste
    → Landing (isca PDF) → WhatsApp Prime → Qualificação humana (Thales/Ana)
    → Agendamento diagnóstico (R$0 ou R$simbólico) → OS
```

### Entregáveis v0 (checklist)

| # | Entregável | Tool no Claude Desktop |
|---|------------|------------------------|
| 1 | Keyword research: top 30 termos "problema + modelo + SP" | Ahrefs MCP (`keywords-explorer-*`) |
| 2 | Análise dos 5 concorrentes orgânicos | Ahrefs (`site-explorer-*`) |
| 3 | Copy da landing + 3 artigos pilar | Claude Desktop + vault RAG |
| 4 | PDF "27 pontos" em design editorial | Claude Desktop + design brief |
| 5 | 5 posts Instagram (carrossel + reel script) | Claude Desktop |
| 6 | Script de qualificação WhatsApp (Ana) | Claude Desktop + playbook 008 |
| 7 | Publicação no vault PITOS (`Campanhas/v0/`) | Obsidian integration |
| 8 | Task tree no ClickUp espelhando o checklist | ClickUp MCP |
| 9 | Baseline de métricas registrado | Notion/vault |

### Critério de saída v0 (gate para v1)
- ≥ 50 downloads da isca
- ≥ 10 conversas qualificadas no WhatsApp Prime
- ≥ 3 diagnósticos agendados e realizados
- 1 OS fechada rastreada à campanha
- Post-mortem escrito no vault (`Campanhas/v0/post-mortem.md`)

**Se não bater → iterar v0, não avançar.** Não existe v1 em cima de v0 que não validou.

---

## v1 — Sistematização (semanas 2–4)

**Tese:** transformar o que funcionou no v0 em máquina repetível.

### Mudanças vs v0
- **Calendário editorial** de 90 dias ancorado no `005-dap-calendario-anual-mkt.md`
- **3 campanhas paralelas** (uma por vertical: BMW, Audi/VW, Mercedes) com a mesma estrutura v0 replicada
- **Dashboard semanal** no Notion/Supabase: leads, CAC, conversão por etapa, ROI por vertical
- **Claude Desktop vira rotineiro**: sessão fixa 2x/semana (segunda: planning; sexta: review)
- **Biblioteca de prompts** no vault (`Prompts/campanha/`) versionada

### Entregáveis novos
- SOP "Como rodar uma campanha DAP v1" (markdown no vault, vira skill futura)
- Template de landing replicável (Webflow MCP)
- Template de PDF editorial replicável
- Kommo sincronizando leads automaticamente (via playbook 008)

### Critério de saída v1 (gate para v2)
- 3 campanhas rodando simultaneamente sem colapsar operação
- ≥ 30 diagnósticos/mês atribuíveis a campanhas
- CAC por vertical conhecido e aceitável
- Ocupação de elevador sobe de 45% → ≥ 60%

---

## v2 — Amplificação + DAP Studio (mês 2–3)

**Tese:** somar mídia paga + conteúdo em vídeo sem perder o padrão editorial.

### Mudanças vs v1
- **Ads pagos** (Meta + Google) nos criativos que performaram orgânico
- **DAP Studio ativa**: 1 vídeo/semana (YouTube + reels), roteirizado pelo Claude Desktop, gravado por Thales
- **Retargeting** dos que baixaram isca mas não agendaram
- **Segmentação por modelo + ano** (ex: "BMW F30 2012–2018: os 4 defeitos que matam o motor N20")
- **Brand Radar / SOV** começam a ser rastreados (Ahrefs)

### Entregáveis novos
- Pixel + conversões server-side configuradas
- Biblioteca de 12 criativos vencedores
- Canal YouTube com 8+ vídeos técnicos
- Relatório SOV mensal: DAP vs concorrentes

### Critério de saída v2 (gate para v3)
- ROAS ≥ 3x em ads pagos
- 5k+ inscritos YouTube OU 50k+ views/mês
- Share of Voice DAP > qualquer concorrente independente de SP em "oficina BMW / Audi / Mercedes SP"
- Ocupação de elevador ≥ 75%

---

## v3 — Automação + Agentes (mês 3–5)

**Tese:** Claude Desktop deixa de executar manualmente. Agentes DAP AI (Ana, Sophia, Insights) assumem operação. Desktop vira supervisor + estrategista.

### Mudanças vs v2
- **Ana (comercial)** qualifica 100% dos leads no WhatsApp sem humano no first-touch
- **Sophia (orquestradora)** roda planning semanal sozinha e entrega briefing pro Thales
- **Insights** gera relatório semanal com hipóteses, não só números
- **RAG do ecossistema** alimenta todas as respostas — nenhum agente inventa
- **Ciclo de campanha** de ideia→publicação cai de 7 dias → 48h
- **DAP Ensina** começa a empacotar o conteúdo campanha como produto pago (Hotmart)

### Entregáveis novos
- SLA de resposta WhatsApp < 2min 24/7
- Skill `/dap-campanha` no Claude Code (1 comando = nova campanha estruturada)
- 1º minicurso Hotmart lançado reaproveitando artigos v0–v2
- Dashboards em tempo real no DAP4.0 frontend

### Critério de saída v3 (gate para v4)
- Operação roda 2 semanas sem Thales tocar
- Receita campanha ≥ R$200k/mês atribuível
- DAP Ensina com primeira receita recorrente
- Ocupação elevador ≥ 85%

---

## v4 — Ecossistema (mês 5+)

**Tese:** a campanha não é mais "marketing da Prime". É o motor de distribuição de 12 unidades. Uma peça de conteúdo abastece simultaneamente Prime, Performance, Project, Ensina, Consultoria.

### Mudanças vs v3
- **Conteúdo modular por unidade**: mesma matéria-prima, 5 ângulos de distribuição
- **Copilot elétrico** (nota `004`) vira produto público — diagnóstico assistido por IA aberto a outras oficinas (SaaS DAP AI)
- **Brand autoridade**: Thales como voz de referência em alemão premium BR (palestras, parcerias, imprensa)
- **Meta R$700k** atingida e estabilizada; próximo patamar é escala geográfica OU verticalização (DAP Performance Stage 3 premium)

### Entregáveis novos
- DAP AI SaaS com ≥ 10 oficinas parceiras pagantes
- Playbook "DAP Way" documentado e vendável (licenciamento)
- Brand Radar: DAP top 3 em menções AI-search pro nicho alemão BR

### Critério de saída v4
- R$700k/mês estabilizado por 3 meses consecutivos
- Receita não-Prime ≥ 25% do total (Performance + Ensina + SaaS + Consultoria)
- Ecossistema documentado suficientemente para Thales tirar 30 dias sem operação travar

---

## Como o Claude Desktop executa isso

### Setup mínimo exigido
- MCP Obsidian apontando pra `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS`
- MCP Ahrefs autenticado
- MCP Supabase com projeto DAP4.0
- MCP ClickUp (coworkin) autenticado
- Acesso ao CLAUDE.md global (padrão world-class) carregado em cada sessão

### Rituais com Desktop
| Ritual | Frequência | Duração | Output |
|--------|-----------|---------|--------|
| Planning semanal | Seg 8h | 30min | Backlog da semana no ClickUp + nota no vault |
| Execução assíncrona | Diário | — | Peças de conteúdo, copys, pesquisas |
| Review + métricas | Sex 17h | 30min | Relatório no Notion + decisões gravadas |
| Post-mortem de versão | Fim de cada v | 1h | Doc `post-mortem-vN.md` no vault |

### Regra de ouro
Nenhum artefato sai pro público sem passar por: **(1) gerado pelo Desktop → (2) revisado pelo Thales → (3) arquivado no vault → (4) indexado no RAG.**

---

## Próximos passos imediatos (hoje)

1. Thales aprova ou ajusta este doc.
2. Rodar v0 entregável #1 (Ahrefs keyword research) — próxima sessão Claude Desktop.
3. Criar pasta `DAP 4.0/Campanhas/v0/` no vault com template de post-mortem em branco.
4. Criar lista "Campanha v0" no ClickUp com os 9 entregáveis.

---

*Versão 1.0 deste roadmap. Revisar ao fim de cada ciclo v. Documento vivo.*
