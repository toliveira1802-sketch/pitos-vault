---
title: "Recepção Anna — arquitetura da camada de intake"
status: "🔧 estruturando (conceito · não é decisão de agora)"
unidade: "DAP AI / comercial + operação"
relacionado: "[[Anna]] · [[00-roster]] · [[anna-guardrails]] · [[Sophia]]"
tags: [dap-ai, arquitetura, recepcao, anna, consultor, aios]
data: 2026-06-04
---

# Recepção Anna — a camada de intake do ecossistema

> Documento de **estrutura**, não de implementação. Captura a visão do Thales pra
> a "recepção nova": como o lead entra, é classificado e vira demanda. Decisões de
> canal (ex.: sair do Kommo) são **futuras** e não condicionam esta arquitetura —
> ela é desenhada acima do canal de propósito.

## 1. Conceito

**Anna é a recepção do ecossistema.** Toda interação que chega de fora — não importa o
canal — passa por ela primeiro. Ela é a **primeira camada** do funil (já é o papel dela
no [[Anna|canon]]): recebe, entende, **classifica** e **demanda**. Não fecha, não decide
o sensível — isso é do consultor humano. Anna transforma ruído de canal em **sinal
estruturado no banco AIOS**.

```
Canais (WhatsApp · Instagram · Facebook · Kommo · walk-in)
        │
        ▼
   ┌─────────────┐   normaliza tudo em
   │   RECEPÇÃO  │   lead + conversa + classificação + demanda
   │    ANNA     │
   └─────────────┘
        │
        ├─► classifica  → grava sinais no lead (tier, score, perfil…)
        └─► demanda     → cria agente_demandas pro consultor agir
                              │
                              ▼
                       Portal Consultor (humano fecha)
                              │
                              ▼
                       Shadow loop (curadoria → Anna aprende)
```

## 2. Os dois planos da Anna

A divisão central. Anna existe em **dois portais com papéis opostos**:

| Plano | Portal | Papel | Quem mexe |
| ----- | ------ | ----- | --------- |
| **Configuração** | **AIOS** | O "estúdio" da Anna — define **quem ela é** | Thales |
| **Operação** | **Consultor** | O "chão de fábrica" — onde ela **trabalha** | Anna (autônoma) + consultor |

### 2.1 Plano de Configuração — Portal AIOS
Onde o Thales **monta a Anna**, sem tocar em código:
- **Persona / prompt** — voz, valores, identidade (hoje em `ana.yaml`).
- **Skills** — capacidades que ela pode acionar (qualificar, agendar, escalar, classificar…).
- **Subagentes** — agentes especializados que ela orquestra (ver §5).
- **Knowledge (RAG)** — quais coleções ela consulta (`ops_*`), tenant filter.
- **Guardrails** — os limites duros ([[anna-guardrails]]): sem preço, sem prazo, sem diagnóstico remoto.
- **Parâmetros de classificação** — pesos do score, limiares de tier, regras de escalação.

> O AIOS é o **painel de controle do cérebro**. Mudar a Anna = mudar config aqui, não deploy.

### 2.2 Plano de Operação — Portal Consultor
Onde a Anna **produz**. O consultor não configura a Anna aqui — ele **recebe o output dela**:
- A fila de **demandas** que ela gerou (priorizada).
- Os leads já **classificados** (tier/score visíveis).
- O contexto: resumo da conversa, sinais, motivo da escalação.

## 3. O que Anna faz na operação: **classificar + demandar**

### 3.1 Classificar (já definido — é a parte mais madura)
A cada turno relevante, Anna extrai sinais (do framework em `ana.yaml`):

| Dimensão | Valores |
| -------- | ------- |
| `vehicle_profile` | premium_alto · premium · entrada_premium · alemao_popular · fora_foco |
| `urgency_level` | critica · alta · media · baixa · especulativa |
| `engagement_level` | alto · medio_alto · medio · baixo · nulo |
| `origin_type` | indicacao_vip · indicacao_bronze · google · gmn · instagram_organico · instagram_ads · wa_frio · desconhecido |
| `geo_fit` | 5km · 15km · 30km · 30plus |
| `lead_score` | 0–100 (perfil 25% + urgência 25% + engajamento 20% + origem 20% + geo 10%) |
| `lead_tier` | quente (75+) · morno (45–74) · frio (20–44) · descartável (0–19) |

→ grava nos campos do `lead` no banco AIOS. **O consultor vê o lead já lido.**

### 3.2 Demandar (o substrato já existe, falta ligar)
"Demandar" = Anna cria uma **demanda de ação** pro consultor. O banco AIOS já tem a tabela
**`agente_demandas`** desenhada exatamente pra isso (hoje existe mas **não está usada por
código ainda** — é o trilho esperando o trem):

```
agente_demandas:
  agente_id     → quem gerou (Anna)
  origem_tipo   → 'lead' | 'conversa' | 'mensagem'
  origem_id     → id da origem
  titulo        → "Lead quente BMW — agendar diagnóstico"
  prioridade    → P0 | P1 | P2  (mapeia do tier/urgência)
  status        → pendente → em_andamento → finalizada
  input/output  → jsonb (contexto + resultado)
```

**Regra de tradução tier → demanda** (a definir nos detalhes, mas a forma é esta):
- `quente (75+)` + escalação imediata → demanda **P0** ("atender agora").
- `morno` → demanda **P1** (entrar na fila do dia).
- `frio` → **P2** ou nurture; `descartável` → sem demanda (só registra).

A **escalação** do `ana.yaml` (lead VIP, "vazando/fumaça/não liga", pede desconto, pede
Thales, sinistro/perícia) é o gatilho de demanda **P0 síncrona**.

## 4. Recepção channel-agnostic (a ponte pro futuro)

A recepção **não depende do canal**. WhatsApp, Instagram, Facebook, Kommo, walk-in são
**fontes** — Anna normaliza tudo em `lead + conversa + classificação + demanda` no banco AIOS,
que é a **fonte de verdade**. Consequência direta:

- Adicionar IG/FB = adicionar uma fonte na recepção (mesmo ecossistema Meta/Graph que o Whats já usa).
- **Sair do Kommo depois não quebra a recepção** — ela já vive acima do canal. O `kommo_lead_id`
  vira só mais um atributo de origem, opcional. (Ver discussão Kommo-out — decisão futura.)

## 5. Skills e subagentes da Anna (o que o Thales vai configurar no AIOS)

Modelo proposto — Anna como **orquestradora de recepção** sobre capacidades discretas:

- **Skills** (capacidades atômicas, acionáveis no turno):
  `classificar_lead` · `qualificar` · `agendar` (escala pro humano hoje) · `escalar` ·
  `buscar_conhecimento (RAG tenant)` · `criar_demanda`.
- **Subagentes** (especialistas que Anna delega — candidatos):
  - *Classificador* — só pontua/tiera (pode ser modelo barato/Haiku, alto volume).
  - *Qualificador* — conduz as perguntas que faltam pra fechar tier.
  - *Escalador* — monta o resumo pro consultor (tier, score, último turno verbatim).

> Hierarquia: Anna é worker do supervisor **[[Sophia]]**; os subagentes da Anna são camada
> abaixo dela. Loop atual **ReAct**, alvo **Reflexion** (depois de telemetria estável).

## 6. Fluxo end-to-end

```
1. Lead manda msg (qualquer canal) ───────────────► fonte normaliza pra conversa/lead
2. Anna lê + responde (dentro dos guardrails) ────► shadow grava observação
3. Anna classifica (tier/score/perfil) ───────────► sinais no lead
4. Anna cria demanda (agente_demandas) ───────────► fila priorizada no Consultor
5. Consultor age (fecha/agenda/negocia) ──────────► event log
6. Thales cura no shadow (AIOS) ───────────────────► Anna aprende (RAG)  [hoje meio-ligado]
```

## 7. O que já existe × o que falta

| Peça | Estado |
| ---- | ------ |
| Persona + classificação + guardrails (`ana.yaml`) | ✅ maduro |
| Shadow loop (capturar → curar → RAG) | 🟡 existe, **meia-ligado** (coleção aprovada não está na retrieval dela) |
| Tabela `agente_demandas` | 🟡 **existe no banco, sem código que use** |
| Classificar → gravar no lead | 🟡 framework definido, wiring a confirmar |
| Demandar → criar `agente_demandas` | ❌ não ligado |
| Painel de **config da Anna no AIOS** (skills/subagentes/knowledge) | ❌ não construído (hoje config = `ana.yaml` no repo) |
| Fila de demandas no **Consultor** | ❌ não construído (há Inbox/Leads; demanda é conceito novo) |
| IG + Facebook como fontes | ❌ futuro (Whats já é Meta direto) |

## 8. Decisões em aberto (não-agora)

1. **Kommo-out** — sair do Kommo e ir Meta-omnichannel (WA/IG/FB direto). Decisão futura;
   a recepção já é desenhada pra suportar. → ADR próprio.
2. **Modelo de skills/subagentes** — granularidade, quais subagentes, qual modelo por subagente.
3. **Config-as-data vs config-as-code** — o painel AIOS edita `ana.yaml` (ou sucessor em banco)?
   Mover a config pra banco é o que destrava o "configurar sem deploy".
4. **Ligar o learning loop** — adicionar `ops_conversas_aprovadas` à retrieval da Anna, com
   salvaguarda anti-parroting (o exemplo aprovado é referência, não template).
5. **Demanda × Inbox** — como a fila de demandas se relaciona com o Inbox/Leads que já existem
   no Consultor (mesma fila? camada acima?).

---

> **Próximo passo natural:** quando virar prioridade, abrir specs por peça —
> (a) config-as-data da Anna no AIOS, (b) wiring `classificar → lead` + `demandar → agente_demandas`,
> (c) fila de demandas no Consultor. Cada uma é um sprint pequeno e independente.
