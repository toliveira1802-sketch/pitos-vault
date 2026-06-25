---
data: 2026-06-11
tipo: handoff
area: marketing
autor: Bianca (CMO)
slug: marketing-doctor-auto
---

# Handoff — Marketing DAP 4.0 (Doctor Auto + Bosch) · 11/jun/2026

> Primeira grande rodada de marketing como CMO do ecossistema. Projeto-fonte completo: `C:\THALES\ECOSSISTEMA-DAP40\MARKETING\mkt-cmo` (CONTEXTO.md = âncora viva; ROADMAP.md; RELATORIO).

## Resumo executivo
Reorganizamos o caixa nas 2 contas Google, abrimos e ligamos a frente Meta, construímos um dashboard ao vivo dos dois canais, desenhamos o caminho pro ROAS real (loop de OS) e estruturamos o lançamento da marca feminina "Delas". **Descoberta-raiz:** a operação otimiza pra clique/conversa de WhatsApp, não cliente fechado (`conversion_value=0`) — fechar esse loop é a prioridade estrutural nº1.

## O que foi implementado
- **Google Doctor auto** — realocação de caixa: Audi R$50→80, VW R$100→110, Serviços+Demais R$30→50; BMW e Mercedes →R$30 (espera 2027); Crônico R$50 mantido. Total ~R$360/dia.
- **Google Bosch** — problema era alcance, não verba: 5 campanhas reativadas (Honda/Jeep/Hyundai) + Serviços Março/26 R$40→60. WhatsApp do site (11) 3824-0025 confirmado vivo. Total ~R$207/dia.
- **Meta** — 2 campanhas ligadas: Remap PROMOÇÃO (id 120230629122810580, R$66/dia) + Remarketing 06/03 (id 120244334909010580, R$40/dia). Meta é o canal barato (conversa R$5–11 vs R$25–80 no Google).
- **Dashboard ao vivo** (artifact) Google+Meta com mapa de eficiência.
- **Specs** — rastreamento (3 fases), link de OS offline, atribuição de origem (agente IA pergunta "como chegou?"), landing de Remap.
- **Brief "Delas"** — braço feminino da Bosch.

## Contas / IDs / ferramentas
- Google: Doctor auto `196-313-9368` · Bosch `989-390-3449`. Meta: CA-DOCTOR `3349465285368338`.
- Conector Windsor.ai (google_ads + facebook): lê dados + pausa/ativa/orçamento. **Não** edita keyword nem criativo (UI).
- WhatsApp novo +55 11 91700-1822 vinculado ao Meta (Business).

## Riscos
- Tudo medido em "contato" (clique/conversa), não cliente. CPA = custo por contato, não lucro.
- Premium (Audi/BMW/Mercedes) CPA R$65–81 — só julgável com valor de OS.
- Anúncio Remap é carrossel→site em aprendizado limitado: NÃO converter pra click-to-WhatsApp (risco de derrubar o vencedor). Roteamento do número novo resolvido via landing separada (Caminho B).

## Pendências (com dono)
- **Loop de atribuição** (OS Fechada + GCLID + agente pergunta origem) → time AIOS.
- **Keywords Bosch** Honda/Jeep/Hyundai → colar a lista (Thales/Juan).
- **Landing de Remap** com WhatsApp +55 11 91700-1822 → dev/site.
- **"Delas"** → 3 decisões do Thales: nome, oferta de entrada, quem grava.
- **Checagem escala Bosch** → tarefa agendada 12/jun 9h.

## Próxima rodada sugerida
Decidir Delas · passar os 3 specs pro time AIOS · colar keywords · dev ajusta landing de Remap · ler resultado da checagem do dia 12 e ver as 2 Meta amadurecendo.
