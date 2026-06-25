---
title: CRM Duplo + Bote IA — Framework Operacional
status: vigente (v1)
data: 2026-04-23
autor: Thales Oliveira
fonte_conceitual: conceito_crm_duplo.md (Downloads/Evaluate These Documents)
complementa: framework-leads-novos.md · anna-guardrails.md
aplicacao: DAP Prime + DAP Bosch (multi-tenant)
---

# CRM Duplo + Bote IA — Doutrina Operacional

Doutrina de como o Doctor Auto Prime separa leads vivos de leads adormecidos sem perder nenhum. Lead não é descartável porque não fechou hoje. Cliente não é perdido porque sumiu por 90 dias. Pipeline não é cemitério.

---

## 1. Princípio

**Três estados, não dois.**

| Estado | Significado | Onde mora |
|---|---|---|
| **Quente** | Está em negociação ativa, em serviço, ou em pós-venda recente. Ana opera. | Pipeline ativo (Kommo) |
| **Adormecido** | Tem carro, conhece a Doctor Auto, não fechou agora ou não fala há tempo. Pescadora opera. | Lago (Supabase `lago_leads`) |
| **Descartável** | Não tem fit (carro fora de foco, fora de geografia, spam, concorrente). Sai do sistema ativo. | Arquivo morto (`lago_leads` com `status='descartado'`) |

Regras:

- Lead adormecido **não polui** pipeline ativo, mas **continua sendo patrimônio**.
- Lead descartável **não some** — fica arquivado pra auditoria e BI, nunca é contactado de novo.
- Pipeline ativo só contém leads em que a próxima ação é humana/Ana em <72h.

**Corolário:** se um lead está no pipeline ativo há mais de 7 dias sem movimento, o sistema falhou — ou Ana perdeu ele, ou deveria ter migrado pro lago.

---

## 2. Arquitetura de Dados

### 2.1 Pipeline Ativo (Kommo)

Continua sendo fonte da verdade pra leads em negociação ativa. Stages conforme framework de lead scoring: `Inbox → Triagem → Quente/Morno/Frio/Descartável`. Todo lead que entra passa por Ana e recebe `lead_score` + `lead_tier` antes de qualquer coisa.

### 2.2 Lago (`lago_leads` — Supabase)

Tabela dedicada. Não é view, não é pipeline Kommo secundário. É o CRM externo.

```sql
CREATE TABLE public.lago_leads (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant             TEXT NOT NULL CHECK (tenant IN ('prime','bosch')),
  kommo_contact_id   BIGINT,
  kommo_lead_id      BIGINT,
  nome               TEXT NOT NULL,
  telefone           TEXT NOT NULL,
  email              TEXT,
  veiculo_marca      TEXT,
  veiculo_modelo     TEXT,
  veiculo_ano        INT,
  veiculo_placa      TEXT,
  km_ultima_visita   INT,

  -- origem no lago
  entrou_em          TIMESTAMPTZ NOT NULL DEFAULT now(),
  origem_pipeline    TEXT CHECK (origem_pipeline IN
                     ('novo_nao_fechou','cliente_inativo','campanha','indicacao','conteudo','import')),
  motivo_saida       TEXT, -- "preço", "não agora", "sumiu 7d", "pós-venda 30d", etc.

  -- estado no lago
  status             TEXT NOT NULL CHECK (status IN
                     ('dormindo','aquecendo','pescado','descartado')) DEFAULT 'dormindo',
  ultimo_contato     TIMESTAMPTZ,
  proxima_revisao    DATE,  -- calculada por km + data última visita + perfil do veículo
  score_reativacao   INT CHECK (score_reativacao BETWEEN 0 AND 100),

  -- histórico
  tentativas_bote    INT NOT NULL DEFAULT 0,
  ultima_tentativa   TIMESTAMPTZ,
  ultimo_trigger     TEXT, -- "revisao_vencendo", "ar_condicionado_verao", etc.
  tags               TEXT[] DEFAULT ARRAY[]::TEXT[],

  -- ressurreição
  voltou_pipeline_em TIMESTAMPTZ,
  motivo_ressurreicao TEXT,

  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_lago_tenant_status ON lago_leads(tenant, status);
CREATE INDEX idx_lago_proxima_revisao ON lago_leads(proxima_revisao) WHERE status = 'dormindo';
CREATE INDEX idx_lago_telefone ON lago_leads(telefone);
CREATE UNIQUE INDEX uq_lago_kommo_contact ON lago_leads(kommo_contact_id) WHERE kommo_contact_id IS NOT NULL;
```

Migration: `20260423_01_lago_leads.sql`.

### 2.3 Tabela de Auditoria (`lago_eventos`)

Toda migração entre estados é evento persistido. Sem isso não há métrica de ressurreição.

```sql
CREATE TABLE public.lago_eventos (
  id             BIGSERIAL PRIMARY KEY,
  lago_lead_id   UUID NOT NULL REFERENCES lago_leads(id) ON DELETE CASCADE,
  evento         TEXT NOT NULL CHECK (evento IN
                 ('entrou_lago','bote_tentou','bote_converteu','lead_respondeu',
                  'voltou_pipeline','esfriou','descartado','ressurreicao')),
  payload        JSONB,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## 3. Regras de Migração

### 3.1 Pipeline → Lago (esfriar)

Lead sai do pipeline ativo e entra no lago quando:

| Trigger | Status destino | Motivo |
|---|---|---|
| Sem resposta em 7 dias corridos | `dormindo` | `sumiu_7d` |
| Lead disse "não agora" / "depois" | `dormindo` | `nao_agora` |
| Orçamento enviado, sem resposta em 5 dias | `dormindo` | `orcamento_sem_resposta` |
| Perdido por preço explícito | `dormindo` | `preco` |
| Pós-venda +30 dias sem reengajar | `dormindo` | `pos_venda_30d` |
| Lead fora de foco (carro errado, fora de geo) | `descartado` | tier `DESCARTÁVEL` |
| Spam / concorrente / inválido | `descartado` | `nao_qualificado` |

Ana executa a migração **automaticamente**. Não depende de humano. Ação:

1. Lê regra no guardrails (anna-guardrails.md).
2. Chama `move_to_lago(kommo_lead_id, motivo)`.
3. Arquiva lead no Kommo (não deleta — mantém histórico).
4. Insere em `lago_leads` com `status='dormindo'` + `origem_pipeline` + `motivo_saida`.
5. Registra evento `entrou_lago`.

### 3.2 Lago → Pipeline (aquecer)

Lead volta ao pipeline ativo quando:

| Trigger | Ação |
|---|---|
| Pescadora enviou mensagem E lead respondeu positivo | Handoff pra Ana |
| Lead entrou em contato sozinho (WhatsApp, IG, site) | Deduplicação cria novo ou reativa |
| Revisão crítica vencida + cliente VIP histórico | Pescadora escala pra Ana proativo |
| Indicação: mesmo telefone aparece via indicador VIP | Handoff com contexto |

Ação:

1. Pescadora chama `promote_to_pipeline(lago_lead_id, contexto)`.
2. Cria lead novo no Kommo (pipeline correto por tenant) com tag `origem: lago`.
3. Atualiza `status='pescado'`, `voltou_pipeline_em=now()`, `motivo_ressurreicao`.
4. Ana recebe com RAG pré-carregado: histórico do veículo, motivo da saída anterior, tentativas do bote.
5. Registra evento `voltou_pipeline`.

### 3.3 Lago → Descartado

- Bote falhou 6x sem qualquer resposta (mesmo negativa).
- Lead pediu `/pare` ou respondeu "não quero mais".
- `status='descartado'`, `tags += ['opt_out']`, nunca mais é tocado pela Pescadora.
- Evento `descartado` com motivo.

---

## 4. O Bote (Pescadora)

### 4.1 Identidade

Agente IA autônomo. Não é Ana. Não responde chat em tempo real. Opera em lote, com persona própria — mais editorial, menos vendedora. "Pescadora" porque pesca leads prontos, não empurra leads frios pra conversão forçada.

### 4.2 Frequência

- **Segunda 09h00** — ciclo de reativação de semana (campanha sazonal + revisão vencendo + pós-venda).
- **Quinta 09h00** — ciclo de oportunidade (upsell + conteúdo educativo + indicação).
- **Cron diário 02h00** — recomputa `score_reativacao` e `proxima_revisao` pra toda a base (barato, lote).

Regra: Pescadora **nunca** dispara fora desses horários. Lead não pode sentir que é spam. Frequência por lead: máximo 1 mensagem a cada 14 dias.

### 4.3 Triggers (tipos de ataque)

Cada trigger tem função pura de elegibilidade. Pescadora roda os 6 em sequência, escolhe o de maior score por lead, dispara 1 mensagem.

| Trigger | Condição de elegibilidade | Peso base |
|---|---|---|
| **revisao_vencendo** | `proxima_revisao` está em ±15 dias + veículo em foco | 30 |
| **campanha_sazonal** | Campanha ativa + veículo compatível (ar-cond no verão, pneu na chuva) | 25 |
| **upsell_pos_servico** | Fez serviço X há 30-60 dias + Y é natural sequência | 20 |
| **reativacao_tempo** | `ultimo_contato` > 90 dias + cliente histórico (≥1 OS) | 15 |
| **indicacao_vip** | Cliente VIP no pipeline indicou pessoa no lago | 40 (override — topo) |
| **conteudo_educativo** | Lead frio nunca cliente + interesse demonstrado em categoria | 10 |

Score final do trigger = peso base + `score_reativacao` (0-100) / 2. Só dispara se final ≥ 40.

### 4.4 Responsabilidades

1. **Pescar**: rodar triggers, selecionar elegíveis, gerar mensagem via LLM com RAG de ficha técnica + persona.
2. **Enviar**: WhatsApp Cloud API (mesmas linhas da Ana) com header claro ("Dra. [nome] da Doctor Auto, tudo bem?").
3. **Escutar resposta (24h)**: se positiva → handoff Ana. Se neutra → update `score_reativacao`. Se negativa → próximo ciclo +30 dias ou opt-out.
4. **Registrar**: `tentativas_bote++`, `ultimo_trigger`, `ultima_tentativa`, evento `bote_tentou`.
5. **Não insistir**: após 6 tentativas sem engajamento, move pra `descartado`.

### 4.5 Guardrails

- Nunca promete preço.
- Nunca agenda direto — sempre passa pra Ana no handoff.
- Mensagem máx 3 linhas no primeiro toque.
- Nunca envia mais de 1 mensagem por lead por ciclo.
- Respeita opt-out imediato.
- Identifica-se como atendente humana no tom (não menciona IA).

---

## 5. Handoff IA ↔ IA

### 5.1 Pescadora → Anna (lead aqueceu)

Quando lead responde positivo (LLM classifica `intent: interessado | agendamento | duvida_tecnica`):

```json
{
  "action": "promote_to_pipeline",
  "lago_lead_id": "uuid",
  "contexto_anna": {
    "historico_resumo": "Cliente BMW 320i 2019, última OS 2025-08 (troca óleo), pescado via revisao_vencendo",
    "tentativas_previas": 2,
    "ultima_objecao": "preço",
    "trigger_que_converteu": "revisao_vencendo",
    "mensagem_lead": "Oi sim, quero sim marcar"
  }
}
```

Ana recebe, não repete boas-vindas, assume conversa no ponto. Tag Kommo `origem: pescadora`.

### 5.2 Anna → Lago (lead esfriou)

Ana decide migração via regra do §3.1. Payload simétrico:

```json
{
  "action": "move_to_lago",
  "kommo_lead_id": 12345,
  "motivo_saida": "sumiu_7d",
  "ultima_mensagem_em": "2026-04-16T14:20:00Z",
  "contexto_bote": {
    "ultima_objecao": "preço",
    "interesse_demonstrado": ["revisao", "troca_pastilha"],
    "veiculo_fichado": true
  }
}
```

Pescadora usa `contexto_bote` pra calibrar próximo trigger.

---

## 6. Métricas

KPIs semanais do framework. Revisados segunda 10h (após ciclo da Pescadora).

| Métrica | Alvo | Como medir |
|---|---|---|
| **Taxa de ressurreição** | ≥ 8% ao mês | `bote_converteu` / `dormindo` do início do mês |
| **Tempo médio no lago (até ressurreição)** | Mediana 21-45 dias | `voltou_pipeline_em - entrou_em` |
| **Eficácia por trigger** | `indicacao_vip` > 25%, `revisao_vencendo` > 15%, resto > 5% | `bote_converteu` / `bote_tentou` por trigger |
| **Taxa de opt-out** | < 2% | `descartado por opt_out` / `bote_tentou` |
| **Receita atribuída ao bote** | 15% da receita total em 6 meses | OS com `origem: pescadora` × ticket médio |
| **Saúde do pipeline** | 0 leads estagnados > 7 dias | Count `crm_leads` sem movimento >7d |

Todas as métricas populam o Sophia Hub em `/sophia` com card dedicado "Lago".

---

## 7. Integração com Lead Scoring

O framework de lead scoring (5 eixos, 0-100) opera no **pipeline ativo** (crm_leads). O CRM Duplo opera na **transição** e no **lago**. Pontes:

- `lead_score` ≥ 75 (QUENTE) **não migra** pro lago por regra temporal simples — só por decisão explícita (perdido por preço, pediu adiamento). Quentes têm proteção.
- `lead_score` entre 45-74 (MORNO) é o principal candidato ao lago — vai dormir após 7d sem resposta.
- `lead_score` < 45 (FRIO) migra direto ao fim do primeiro ciclo de nutrição (30 dias) sem conversão.
- `lead_tier = DESCARTÁVEL` → `status='descartado'` no lago (ou nunca entra lá, vai direto ao arquivo).
- `score_reativacao` no lago = recomputação do `lead_score` original + peso do tempo + peso do contexto do veículo (revisão próxima, serviço natural em sequência).

Quando lead é `pescado` e volta ao pipeline, Ana **recomputa** `lead_score` na primeira resposta — contexto mudou.

---

## 8. Implementação (fases)

1. **Fase 1 — Fundação (semana 1)**: migration `lago_leads` + `lago_eventos`, funções SQL `move_to_lago`, `promote_to_pipeline`, tool na Ana.
2. **Fase 2 — Backfill (semana 2)**: import dos 5.192 leads auditados pela Manus direto pro lago com `origem_pipeline='import'` + personas como tags.
3. **Fase 3 — Pescadora v0 (semana 3-4)**: agente Python no Parliament, 3 triggers primeiro (`revisao_vencendo`, `reativacao_tempo`, `campanha_sazonal`), cron seg/qui.
4. **Fase 4 — Métricas no Sophia Hub (semana 5)**: card "Lago" com os 6 KPIs.
5. **Fase 5 — Triggers completos + handoff IA↔IA formalizado (semana 6-8)**.

---

## 9. Glossário

- **Lago**: tabela `lago_leads`, fora do pipeline ativo.
- **Bote / Pescadora**: agente que opera o lago.
- **Pescar**: mover lead do lago pro pipeline ativo após sinal positivo.
- **Esfriar**: mover lead do pipeline pro lago por inatividade ou sinal negativo.
- **Ressurreição**: lead que estava no lago e virou cliente ou oportunidade paga.

---

**Doutrina.** Todo código, toda automação, toda decisão de arquitetura de leads a partir de 2026-04-23 obedece este framework. Conflito com implementação anterior → prevalece este documento.
