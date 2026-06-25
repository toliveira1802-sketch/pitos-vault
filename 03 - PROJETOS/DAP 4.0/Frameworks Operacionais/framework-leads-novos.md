---
title: Framework de Classificação e Aquecimento de Leads Novos
status: vigente
data: 2026-04
fonte: DAP_Framework_Leads_Novos.pdf (nesta pasta)
complementa: modelo RFM (clientes antigos)
---

# Framework de Leads Novos — DAP Prime

Documento operacional que define **como classificar, pontuar e aquecer leads que nunca passaram pela oficina**. Complementar ao RFM (que cobre retenção de clientes).

PDF completo em: `./DAP_Framework_Leads_Novos.pdf`

## Núcleo

- **5 eixos** de classificação com pesos: Perfil do Veículo (25%) · Urgência (25%) · Engajamento (20%) · Origem (20%) · Fit Geográfico (10%)
- **Score 0–100** → 4 tiers: QUENTE (75–100) · MORNO (45–74) · FRIO (20–44) · DESCARTÁVEL (0–19)
- **Fluxo de aquecimento por tier** (0-15 min → 60 dias)
- **Regras de subida/descida entre tiers** baseadas em engajamento
- **KPIs semanais** (conversão QUENTE >50%, MORNO >20%, tempo resposta <15min/<2h)

## Onde isso entra no DAP 4.0

### Schema `crm_leads` — colunas novas necessárias

```sql
ALTER TABLE public.crm_leads
  ADD COLUMN vehicle_profile   TEXT CHECK (vehicle_profile IN
                               ('premium_alto','premium','entrada_premium','alemao_popular','fora_foco')),
  ADD COLUMN urgency_level     TEXT CHECK (urgency_level IN
                               ('critica','alta','media','baixa','especulativa')),
  ADD COLUMN engagement_level  TEXT CHECK (engagement_level IN
                               ('alto','medio_alto','medio','baixo','nulo')),
  ADD COLUMN origin_type       TEXT CHECK (origin_type IN
                               ('indicacao_vip','indicacao_bronze','google','gmn',
                                'instagram_organico','instagram_ads','wa_frio','desconhecido')),
  ADD COLUMN geo_fit           TEXT CHECK (geo_fit IN ('5km','15km','30km','30plus')),
  ADD COLUMN lead_score        INT  CHECK (lead_score BETWEEN 0 AND 100),
  ADD COLUMN lead_tier         TEXT CHECK (lead_tier IN
                               ('quente','morno','frio','descartavel')),
  ADD COLUMN scored_at         TIMESTAMPTZ;
```

### Responsabilidade da Anna

A cada turno de conversa, Anna deve:

1. Extrair sinais da mensagem do lead (marca/modelo/ano, dor, pressa, região)
2. Classificar os 5 eixos
3. Computar `lead_score` = soma ponderada
4. Determinar `lead_tier` pelo corte
5. Persistir em `crm_leads` + label/stage no Kommo
6. Se tier mudou → trigger de follow-up apropriado (consultor em 15 min pro QUENTE, etc.)

### Pipeline Kommo

Os 4 tiers viram **stages** do pipeline Bosch (e Prime quando Thales confirmar `pipeline_id`). Possível layout:

```
Inbox → Triagem Anna → QUENTE / MORNO / FRIO / DESCARTÁVEL
                        │
                        ├─ QUENTE: consultor liga 15min
                        ├─ MORNO: orçamento estimado 2h
                        ├─ FRIO: Salesbot nutrição 30d
                        └─ DESCARTÁVEL: lista passiva
```

### Tabela de pontos (cola rápida)

**Perfil do Veículo:** Porsche/AMG/M/RS=25 · BMW 3/5 Audi A4/A6 Merc C/E=20 · A3 X1 Tiguan T-Cross=15 · Polo Golf Virtus Nivus=10 · outros=5

**Urgência:** carro parado/luz/não liga=25 · semana que vem/viagem=20 · revisão preventiva=15 · cotando sem prazo=10 · curioso=5

**Engajamento:** <1h+foto+prazo=20 · mesmo dia+perguntas=15 · <48h curtas=10 · >48h ou só visualizou=5 · ignorou=0

**Origem:** indicação VIP/Prata=20 · indicação Bronze=16 · Google=14 · GMN=12 · IG orgânico=8 · IG ads=6 · WA frio=4 · desconhecida=2

**Fit Geográfico:** <5km=10 · 5-15km=7 · 15-30km=4 · >30km=2

## Tasks afetadas no master-todo

- **#31** (adicionar `score` em `crm_leads` + tool Anna) — agora tem **algoritmo exato**, não é mais hipótese
- **#32** (atualizar RTBM com personas Manus) — usar em conjunto: personas dizem *quem*, este framework diz *quanto priorizar*
- **Novo:** migration `20260420_01_crm_leads_scoring.sql` com as 7 colunas acima
- **Novo:** tool `compute_lead_score` em Anna (Python função pura testável)

## Complementaridade RFM

- **Leads novos** (este doc): sinais indiretos, scoring no primeiro contato, aquecimento
- **Clientes antigos** (RFM): Recência + Frequência + Monetário, tiers VIP/Prata/Bronze

Quando lead agenda e **comparece** ao diagnóstico → sai do pipeline de leads e entra no cadastro de clientes (transição crítica a codificar).
