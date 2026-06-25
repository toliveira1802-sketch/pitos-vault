---
tipo: doc-vivo
projeto: DAP4 / dap-aios
atualizado: 2026-06-05
tags: [dap4, portais, roadmap]
---

# Roadmap dos Portais — o que vem por aí

> Voltar ao [[00-estado-dos-portais|índice]]. Priorizado por alavancagem.
> Derivado dos gaps reais (ver docs por portal) + specs conhecidos (Anna omnichannel, pátio v2).

## 🔑 Desbloqueador-mestre: NÃO é migração de banco — é faxina + import seletivo

A leitura ingênua era "migrar a operação DOCTOR PRIME → AIOS (60 tabelas)". A auditoria dos dados
(2026-06-05) mostrou que o ativo real é **muito menor** e a migração é cirúrgica, não monolítica.

**Dado duro (DOCTOR PRIME, medido):**
- `crm_leads` + `crm_leads_externo` = **24.266 linhas**, mas só **484 telefones únicos** e **0 emails**.
  ~40x de duplicação (scrape Kommo) + 5.233 linhas sem contato nenhum. O "banco de milhares de leads"
  é ilusão de duplicação.
- `ordens_servico` = 48 **cascas** (itens/pagamentos/checklist/histórico = 0), de **meses anteriores**. Histórico, não operação.
- `clients` 27 + `vehicles` 25 = base real, pequena.
- Peças: infra de scraping **começada e abandonada** (`parts_search_history`/`scrape_checkpoints` vazias).

**Veredito (auditoria 2026-06-05) — o caminho "migrar leads" foi DESCARTADO:**
1. **Leads legado → NÃO migra. Descartar.** Dos 484 telefones únicos, a tabela tratada (268) é
   **264 frios / 2 warm / 2 hot**, zero veículo estruturado, zero alemão premium, zero email, tudo de um
   **burst de 6 dias** (27/03–02/04). O ativo trabalhável são **~4 leads**. Não paga dedup/import/campanha.
2. **Clientes + Veículos (27 + 25) → ÚNICA coisa que migra.** Viram base de CRM para reativação futura.
3. **OS (48)** → não migra (cascas, meses anteriores); no máximo histórico vinculado ao cliente.
4. **Peças** → não migra agora; só com a feature foto + pesquisa online → estoque (esqueleto abandonado serve de base).

**Conclusão (reframe):** o "desbloqueador-mestre" era uma falácia — não há ativo de dados no passado.
A alavancagem real do gargalo "falta de lead" é a **Anna capturando lead novo, limpo e qualificado**
(em deploy), **não** migrar o legado. Do DOCTOR PRIME, só os **27 clientes/veículos** valem o trabalho.

## Próximas fatias por frente

### Anna / Omnichannel (em curso)
- ✅ Fatia 0 (dual-write AIOS) + Fatia 1 (qualify inline) — **deployados 2026-06-05**.
- ▶️ Próximo: boca única **WhatsApp + Instagram + Facebook**, Zoraide como gatilho de bastidor.
- Bloqueio externo: verificação Meta business (Prime). Workaround: test number dev mode.

### Pátio v2 (Consultor)
- ✅ Fatia 1 (schema) + Fatia 2 (atribuição OS↔box, drag-drop, "Tirar do box") — **mergeados 2026-06-05** (#52/#53).
- ▶️ **Fatia 3**: indicadores — mix real vs ideal 60/25/10/5 (rápido/médio/demorado/projeto) +
  ranking de produtividade por box + heatmap.

### Marketing (Gestão)
- ✅ Backend Windsor (Google Ads) — **mergeado 2026-06-05** (#54), atrás de `USE_WINDSOR`.
- ▶️ **Fatia 2**: trocar mock→endpoint no front (`useMarketingCampaigns`), Google-only, ROAS oculto.
- ▶️ Provisionar `WINDSOR_API_KEY` em prod + conectar Meta Ads + configurar valor de conversão.

### Financeiro (Gestão)
- ▶️ Modelar **schema financeiro no Postgres** + serviço + endpoints → trocar `financeiro/data.ts` por hooks.
  Hoje 100% mock. Depende parcialmente da migração da operação.

### AIOS / Agentes
- ▶️ **LLM real** na execução de diretor (hoje canned) — "Rodada 10".
- ▶️ RAG/Anna end-to-end com `USE_DAP4_AI=true` em prod (curadoria do vault pelo Walter antes de ingerir).

### Consultor — completar o dashboard
- ▶️ 4 sub-páginas (operacional/financeiro/produtividade/agenda) hoje stubs (R15–R18).
- ▶️ Upload real de fotos/vídeo na OS; Conversas e Aprovações.

### Mecânico
- ▶️ Drag-and-drop no kanban + filtro por mecânico (único polimento; portal já é 100% live).

### Portal Cliente
- ▶️ Decisão estratégica: priorizar agora ou depois da operação interna? Hoje é shell mock.

## Higiene / operação
- Provisionar **consultores e mecânicos reais** em `public.users` do AIOS (só o Thales tem acesso hoje).
- Definir `USE_WINDSOR` / `USE_DAP4_AI` / `WINDSOR_API_KEY` no ambiente de produção do dap-aios.
