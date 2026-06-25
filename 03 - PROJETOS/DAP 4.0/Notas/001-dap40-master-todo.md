# DAP 4.0 — Master To-Do (Versão R$700k)
**Data:** 2026-05-04
**Status:** #ativo #referencia
**Owner:** Thales
**Área:** Todas

> Documento reescrito em 2026-05-04 contra o baseline operacional real (500 leads/mês, 50 agendamentos = 10% conversão, permanência 7-10d).
> Versão anterior preservada via histórico OneDrive/git.
> Princípio: tarefa só fica na pilha ativa se mover **uma das 3 alavancas do R$700k**. Resto vai pra Park.

---

## 🎯 Meta — R$700k/mês

Hoje: **R$300k/mês** · 50 OS/mês · ticket médio R$6k · 9 elevadores a 45% de ocupação.

Falta: **R$400k/mês** (+133%).

### Baseline operacional (2026-05-04)

| KPI | Valor atual | Benchmark premium | Gap |
|---|---|---|---|
| Lead → agendamento | **10%** (500 → 50) | 25-35% | -2.5x a -3.5x |
| Permanência por OS | **7-10 dias** | 2-4 dias | -2x a -3x |
| Orçamento aberto > 7d | **não medido** | medir ou perder | dinheiro escondido |
| Ocupação dos elevadores | 45% | 80-90% | 2x de slack |
| OS/mês | 50 | meta 100-125 | 2x-2.5x |

### As 3 alavancas

1. **Conversão Ana** — 10% → 25% sozinho leva pra ~R$750k mantendo ticket.
2. **Permanência** — sem cair de 8d → 4d, conversão maior só vira fila e cliente desiste.
3. **Orçamento aberto** — bucket não medido onde dinheiro morre todo mês.

Tudo na sequência de ataque abaixo serve a uma dessas três. Resto é Park.

---

## 🔥 SEQUÊNCIA DE ATAQUE — 14 tarefas críticas

A ordem importa. Cada fase ou destrava informação pra próxima, ou remove o gargalo que faria a próxima virar fila.

### Fase 0 — Instrumentação (semana 1)
Não se mexe no que não mede. Sem isso, qualquer mudança é palpite.

- [ ] **0.1** Rodar 3 queries diagnósticas no Supabase do dap4
  - Funil Ana: das últimas 500 conversas, em que etapa morreram (chegou / qualificou / pediu orçamento / agendou / sumiu)
  - Permanência: distribuição (mediana, p50, p90) + breakdown por status (executando vs. esperando peça vs. esperando aprovação vs. ocioso)
  - Orçamentos: quantas propostas estão "open" há > 7 dias no Kommo, agrupadas por idade
- [ ] **0.2** Auditoria segurança HMAC em kommo-webhook + meta-webhook *(ex-#29)*
- [ ] **0.4** Widget "Top carros mais tempo parados + R$ comido" no dashboard consultor *(2026-05-25)*
  - Ranking de OS abertas há mais tempo + custo de oportunidade acumulado por veículo.
  - Fórmula (a definir): horas paradas × custo box + peças paradas + margem perdida × tempo.
  - Source: `service_orders.opened_at`, `service_order_items`, advisor capacity, `commercial_status` drift.
  - Por que aqui: ataca alavanca 2 (Permanência) DIRETO — sem visualizar não dá pra atacar. Pré-requisito da Fase 1.
- [ ] **0.3** Dashboard métricas DAP Dev — versão MVP: OS/mês, ticket médio, conversão lead→agendamento, permanência média, orçamentos > 7d

**Saída da fase:** painel ao vivo dos 3 KPIs. Próximas decisões deixam de ser palpite.

---

### Fase 1 — Atacar Conversão Ana (semana 2-3)
Maior ROI. 450 leads/mês somem entre Ana e agendamento. Cada 1% de conversão recuperada = R$30k/mês.

- [ ] **1.1** Script oficial do primeiro contato (WhatsApp + recepção) — copy
- [ ] **1.2** Ana — fluxo de qualificação automático (modelo, ano, sintoma, interesse) + handoff estruturado pro consultor
- [ ] **1.3** Field `score 0-100` em `crm_leads` + tool Anna `compute_score` baseado nas 9 personas Manus *(ex-#31)*
- [ ] **1.4** Ana — reativação automática 90d+ (3 toques escalonados)

**Saída da fase:** conversão alvo 15-25% (vs. 10% atual). Volume de agendamentos sobe sem mais lead.

---

### Fase 2 — Destravar Permanência (semana 3-5, em paralelo com Fase 1)
Sem isso, conversão maior vira fila e cliente desiste. **8 das 6 tarefas aqui não são código** — são SOP, decisão e política.

- [ ] **2.1** Mapear fluxo completo de uma OS — entrada → triagem → execução → revisão → entrega *(workshop com chão de fábrica)*
- [ ] **2.2** Definir tempo máximo por tipo de serviço (rápido/médio/lento) — política
- [ ] **2.3** Checklist de recebimento (20 itens) + checklist de entrega — documento
- [ ] **2.4** Regra: peça crítica → confirmar disponibilidade ANTES de receber o carro — política + integração com fornecedores
- [ ] **2.5** Kanban de OS no DAP Dev: entrada → triagem → execução → revisão → entrega → pós-venda
- [ ] **2.6** Caixa individual por carro no DAP Dev (custo real: peça + mão de obra + insumo + overhead)

**Saída da fase:** permanência alvo 4-5d (vs. 8-10d). Capacidade dos elevadores efetivamente dobra sem mais elevador.

---

### Fase 3 — Fechar Orçamento Aberto (semana 4-6)
Dinheiro escondido vira receita.

- [ ] **3.1** Copywriting técnico de orçamento (6 etapas) — proposta que fecha em vez de morrer
- [ ] **3.2** Ritual de pós-venda 48h · 7d · 30d *(via Kimi automatizado, não manual)* + reativação automática de orçamento sem decisão > 7d

**Saída da fase:** % de orçamento que fecha sobe. Bucket invisível vira receita.

---

### Fase 4 — Subir Ticket (semana 6-8)
Se Fases 1-3 destravarem, ticket vira otimização incremental, não condição de sobrevivência.

- [ ] **4.1** Implementar repricing tabela A/B/C

**Saída da fase:** ticket médio sobe (objetivo R$6k → R$7k+). Combinado com volume já destravado, R$700k vira realista em 12-16 semanas a partir do início da Fase 0.

---

## 🟪 PARK — não move R$700k em 90 dias

Tudo abaixo é interessante. Nada abaixo é crítico **agora**. Voltam à pilha quando a oficina estiver estável em R$500k+ ou quando o gargalo deles virar real.

### DAP Copilot (diagnóstico elétrico) — 7 itens
*Volta quando: oficina em R$500k+ estável.* Vira diferencial premium + base do produto SaaS.

### DAP Copilot Expansões (VCDS, OBD-II, câmera, som, dinamômetro, SaaS) — 8 itens
*Volta quando: 2027.* Hoje é cosplay de roadmap.

### DAP Ensina (Hotmart, minicurso, workshop, grade 6 produtos) — 7 itens
*Volta quando: oficina física estável em R$500k+.* Receita secundária em outro horizonte.

### Trilha Conhecimento 4 níveis + Plano Carreira 5 níveis — 11 itens
*Volta quando: dobrar headcount.* Hoje você não está escalando time — está sangrando funil.

### Parcerias (Box Detail, SofistiCar, Binho, AvantGarde, seguradoras, concessionárias, clubes BMW/Audi, influencer, B2B frota) — 11 itens
*Faça só as 2 com maior probabilidade de fechar essa semana se já houver conversa quente. Resto pausa.* ROI baixo por hora vs. consertar funil interno.

### Templates de campanha (Google headlines, Meta thumb/copy, Stories enquete, Reel estrutura, carrossel educativo, briefing social media) — 6 itens
*Volta quando: conversão Ana > 20%.* Mais lead com funil vazando = mais vazamento.

### Aquisição paga adicional (Google Display + Remarketing, YouTube TrueView, Lookalike 1%, Customer Match, QR Code oficina, Apify scrapper, Meta Lead Ads, landing remap, Apollo + Close cadência) — 9 itens
*Volta quando: Fase 0 + Fase 1 fechadas.* Igual ao bloco acima — não adianta encher funil furado.

### Legado / Expansão (organograma, manual liderança, expansão 2026-27, DAP Consultoria, DAP Mulher, site institucional, IP strategy, cultura) — 9 itens
*Volta quando: 2027+.* Outro horizonte.

### Ingerir Manus 5.192 leads no RAG (#28) + RTBM 9 personas (#32) + max_steps Anna (#30)
*#30 (max_steps) entra na Fase 1 se a Anna tiver loop infinito hoje. #28 e #32 ficam em park até funil saneado.*

### Campanha humana reativação 712 clientes (#33)
*Faça depois da Fase 1 — você quer que esses 712 caiam num funil que já converte, não no atual de 10%.*

### Parliament backend C-Level (spec + plan 2026-04-19)
*Plan pronto, mas não move R$700k. Park até oficina estável.*

### Mecânico ganha por hora (compensation model) — *2026-05-25*
*Modelo novo de remuneração: mecânico recebe por hora trabalhada (vs por OS / fixo). Implica:* `labor_entries` ganha `hourly_rate` por mecânico + calculadora pagamento mensal + clock in/out na OS + dashboard mecânico de horas/dia.
*Volta quando: oficina em R$500k+ estável e tiver capacidade pra rolar piloto sem quebrar pagamento.* Compensation model bem feito move retenção/produtividade no médio prazo, mas não move funil/permanência no curto.

---

## ✅ CONCLUÍDO

- [x] Diagnóstico operacional completo
- [x] Ecossistema 12 unidades mapeado
- [x] Plano de leads 17 formas em 7 grupos
- [x] Calendário anual de MKT 12 meses
- [x] Proposta Box Detail + SofistiCar
- [x] Proposta Binho + AvantGarde
- [x] Playbook de execução 90 dias
- [x] Conceito DAP Copilot documentado
- [x] Trilha de conhecimento 4 níveis (esboço)
- [x] Plano de carreira 5 níveis (esboço)
- [x] PPT Estratégia DAP 4.0
- [x] PPT Máquina de Leads (17 formas)
- [x] PPT Calendário MKT
- [x] PPT Organismo Vivo
- [x] Estrutura de pastas DAP 4.0 no notebook
- [x] Notas Obsidian organizadas
- [x] **Ana ativa no WhatsApp real — 500 leads/mês capturados** *(confirmado 2026-05-04)*
- [x] **dap-aios protótipo congelado em R4 (RBAC scaffolding, smoke 17/17)** *(2026-05-04)*

---

## 📁 Arquivos do Projeto

| Arquivo | Tipo | Local |
|---|---|---|
| DAP40_Estrategia.pptx | PPT | Apresentacoes\ |
| DAP40_Leads_Novos_Slides.pptx | PPT | Apresentacoes\ |
| DAP_Calendario_MKT.pptx | PPT | Apresentacoes\ |
| DAP_Organismo_Vivo.pptx | PPT | Apresentacoes\ |
| DAP_Playbook_Execucao.docx | DOCX | Documentos\ |
| DAP_Proposta_Esteticas.docx | DOCX | Documentos\ |
| DAP_Proposta_Escapamentos.docx | DOCX | Documentos\ |
| 002-dap40-rota-estrategica.md | Obsidian | Notas\ |
| 003-dap40-dores-e-legado.md | Obsidian | Notas\ |
| 004-dap-copilot-diagnostico-eletrico.md | Obsidian | Notas\ |
| 005-dap-calendario-anual-mkt.md | Obsidian | Notas\ |

---

## 🗂 Histórico de sessões

### 2026-05-25 — Staging V2 up + 2 features novas
- Portal Consultor V2 (dap-aios) acessível em https://staging-operacao.doctorautoprime40.com (Supabase Postgres + Auth + RLS, role app_aios_v2). 7 patches in-place no VPS source pra portar pra git.
- 2 features adicionadas: **0.4 Top carros parados + R$ comido** (instrumenta alavanca 2 — Permanência) e **Mecânico por hora** (compensation, vai pra Park).

### 2026-05-04 — Reescrita R$700k
Documento reescrito contra baseline 500/50/7-10d. 14 críticas em sequência de ataque, 62 itens em park comprimido. dap-aios congelado em R4.

### 2026-04-19 — Sessão Parliament backend + avaliação Manus
- Spec parliament: `docs/superpowers/specs/2026-04-19-parliament-clevel-backend-design.md`
- Plan parliament: `docs/superpowers/plans/2026-04-19-parliament-clevel-backend.md` (15 tasks TDD, ~5h) — **migrado para PARK**
- 6 tasks novas Manus (#28-#33) — distribuídas: #29 + #31 entraram na sequência crítica, #28/#30/#32/#33 foram pra park
- Decisões de descarte registradas em `/PITOS/Inbox - Claudin/manus-2026-03-archive/VEREDICTO-CLAUDIN.md`

---

*DAP 4.0 · Master To-Do · v R$700k · 2026-05-04*
*"Um é muito, mil é pouco."*
