---
title: Chapapiuro — Agente Pessoal do Thales
versão: v1
data: 2026-05-05
status: design fechado, implementação pendente
fonte: thread Claude Code 2026-05-05 (Thales × Walter síntese)
relacionados:
  - PITOS/Sistemas/sennin-protocol.md
  - PITOS/Sistemas/sennin-c-level-map.md
  - PITOS/DAP 4.0/Frameworks Operacionais/estrutura-prompt-agentes.md
  - C:\THALES\CHAPAPIURO-WHATSAPP\ (repo plataforma)
  - C:\dev\dap4\agents\parliament\ (Sophia + 13 cadeiras)
---

# Chapapiuro — Agente Pessoal do Thales

## TL;DR

Chapapiuro é a interface única do Thales com seu ecossistema de IA. Cuida do profissional (DAP) e do pessoal (família, saúde, ideias) sem misturar bases. **Sophia é gateway obrigatório** — toda demanda do Thales vira entrada no `demand_ledger`, é classificada por Sophia e delegada ao C-level certo (ou Council quando crítica). Chapapiuro nunca executa direto: ele captura intent, escala pra Sophia, recebe o veredito e entrega no tom certo. **Skill de aprender** (Reflexion pattern) reduz perguntas redundantes ao longo do tempo. Multi-canal: WhatsApp, Telegram, Obsidian, Email — contexto unificado. Proativo: pode te abordar sem você pedir, mas sempre via Sophia.

---

## 1. Identidade

```
NOME: Chapapiuro
PAPEL: Agente pessoal do Thales — interface única humano↔IA
COBRE: Vida profissional (DAP 4.0) + Vida pessoal (família, saúde, ideias, agenda)
NÃO É: chatbot genérico, secretário formal, assistente padrão
SERVE A: Thales — ninguém mais conversa com Chapapiuro
VOZ: informal, primeira pessoa, sem hedge, humor seco quando cabe, PT-BR direto
VALORES:
  - Captura intent rápido, não enrola na pergunta
  - Pergunta "pessoal ou profissional?" só quando confidence baixo (Reflexion reduz isso)
  - Nunca executa direto — sempre triangula via Sophia
  - Documenta tudo no demand_ledger (histórico = ativo)
  - Memória pessoal e profissional separadas fisicamente, sem cross-query
NÃO FAZ:
  - Não cria intimidade fake ("e como está se sentindo hoje?")
  - Não recapitula o que você disse antes de responder
  - Não usa emoji em excesso (1 no máximo, só se cabe no tom)
  - Não termina mensagens com "espero ter ajudado"
```

**Diferença com C-levels:** C-levels (Walter/Anna/Francisco/etc) usam tom técnico, denso, com citação. Chapapiuro fala como você falaria com um amigo de confiança que conhece toda a operação.

---

## 2. Arquitetura

```
        Thales (humano)
   WhatsApp │ Telegram │ Obsidian │ Email
              ↓
         Chapapiuro                ← captura intent, classifica P/P (com confidence)
              ↓
            SOPHIA  (gateway obrigatório)
              ↓
       ┌──────┴────────────────┐
       ↓                        ↓
   1 diretor                Council
   (1 área afetada)         (Parliament — 2+ áreas ou decisão crítica)
       ↓                        ↓
       └──────────┬─────────────┘
                  ↓
           demand_ledger        ← log obrigatório (auditoria + RAG histórico)
                  ↓
           Sophia consolida
                  ↓
           Chapapiuro entrega   ← traduz tom técnico → tom pessoal
                  ↓
                Thales
```

**Bottleneck consciente.** Sophia centraliza. Vantagem: rastreabilidade total + memória institucional. Risco: SPOF. Mitigação: rota de fallback pra emergência crítica de saúde/família (Chapapiuro escala direto pro Thales).

---

## 3. Sophia como Gateway — Decisão #2

**Regra absoluta:** toda demanda do Thales (via Chapapiuro) **passa por Sophia**. Não existe fluxo Chapapiuro→Walter ou Chapapiuro→Anna direto.

**Por quê:**
1. Auditoria total — `demand_ledger` registra tudo
2. Memória institucional — decisões viram precedente reaproveitável (Phase 2: RAG histórico)
3. Cohesão — Sophia evita conflito entre diretores (mesmo dado pedido em 2 contextos)

**Quando Sophia escala pra Council (Parliament):**
- 2+ áreas C-level afetadas (ex: pricing = finance + product + customer)
- Investimento >R$5k
- Demissão / contratação
- Pivô estratégico
- Decisão que afeta marca ou risco jurídico

**`demand_ledger` schema (canônico):**

```sql
create table demand_ledger (
  id uuid primary key default gen_random_uuid(),
  ts timestamptz default now(),
  channel text not null check (channel in ('whatsapp','telegram','obsidian','email','proactive')),
  context text not null check (context in ('personal','professional','mixed')),
  context_confidence float check (context_confidence between 0 and 1),
  raw_input text not null,                    -- texto original do Thales
  intent_summary text not null,               -- resumo classificado
  classified_by text default 'sophia',
  assigned_to text not null,                  -- 'walter', 'anna', 'francisco', 'council', etc
  council_voices text[],                       -- {'francisco','rafael'} se for council
  output_summary text,
  artifacts jsonb,                            -- paths, IDs de arquivos gerados
  status text default 'pending'
    check (status in ('pending','in_progress','completed','escalated','failed')),
  latency_ms int,
  cost_usd numeric(10,4),
  thales_feedback text,                       -- preenchido depois (aprendizado)
  resolved_at timestamptz
);

create index idx_demand_ledger_context on demand_ledger(context, ts desc);
create index idx_demand_ledger_assigned on demand_ledger(assigned_to, ts desc);
```

---

## 4. Tiers de Urgência — Decisão #3

Sophia classifica todo sinal em 4 tiers. Chapapiuro entrega com base nisso.

| Tier | Comportamento | Trigger automático | Exemplo |
|---|---|---|---|
| **T0 EMERGÊNCIA** | Interrompe imediato (push notification, vibração) | KPI cai >25% / lead VIP irritado / OS crítica >2h travada / saúde família | Anna escala lead Bosch CEO furioso |
| **T1 URGENTE** | Mensagem normal, espera resposta 1-2h | Lead VIP entrante / Walter precisa input bloqueante / mensagem círculo próximo | Esposa pediu pra ligar |
| **T2 INFORMATIVO** | Junta no briefing matinal (7h30) ou noturno (21h) | Faturamento do dia / lead padrão / NPS rotineiro / ideia capturada | Lead novo, ticket médio R$1.200 |
| **T3 SILENCIOSO** | Loga, só responde se Thales perguntar | Ruído de sistema, alerta marginal, ações de bot | Heartbeat interno OK |

**Refinamento contínuo:** Reflexion ajusta thresholds. Se Thales rejeita um T0 ("não era emergência"), regra dispara aprende.

---

## 5. Skill de Aprender — Reflexion Pattern — Decisão #1

**Padrão:** Reflexion (arXiv 2303.11366) adaptado pra agente pessoal.

**Como funciona:**

1. Toda interação Chapapiuro escreve uma reflexão na tabela `chapapiuro_reflections`:
   ```
   {ts, channel, raw_input, what_chapapiuro_inferred, what_was_actually_correct,
    confidence_at_inference, confidence_after_correction, lesson}
   ```

2. **Ciclo semanal** — domingo madrugada, job consolida:
   - Padrões que viraram alta confidence → vira regra hardcoded no system prompt
   - Padrões que ainda variam → mantém pergunta confirmatória
   - Edge cases recorrentes → adiciona exemplo few-shot

3. **Resultado mensurável:** taxa de pergunta "pessoal ou profissional?" cai de ~100% (semana 1) pra <10% (semana 12).

**Schema:**

```sql
create table chapapiuro_reflections (
  id uuid primary key default gen_random_uuid(),
  ts timestamptz default now(),
  demand_id uuid references demand_ledger(id),
  raw_input text,
  inferred_context text,
  inferred_assigned_to text,
  actual_context text,                          -- preenchido se Thales corrigiu
  actual_assigned_to text,
  confidence_pre float,
  confidence_post float,
  lesson text,                                  -- texto livre, "aprendi que..."
  pattern_signature text                        -- hash pra agrupar lições similares
);

create index idx_chapapiuro_reflections_pattern on chapapiuro_reflections(pattern_signature, ts desc);
```

---

## 6. Memória + RAG Isolados — Decisão #4

**Princípio:** zero possibilidade de query cruzada entre pessoal e profissional. Não é filtro lógico, é **isolamento físico**.

| Item | Pessoal | Profissional |
|---|---|---|
| Postgres database | `chapapiuro_personal` | `chapapiuro_professional` |
| ChromaDB collection prefix | `personal_*` | `prof_*` (já existe `ops_prime_*`, `ops_bosch_*`) |
| Vault PITOS path | `PITOS/Pessoal/` | `PITOS/DAP 4.0/` |
| User na DB | `chapapiuro_personal_user` | `chapapiuro_prof_user` |

**Quem decide o destino:** Sophia, no momento da classificação (registrada em `demand_ledger.context`).

**Cross-query bloqueio:** RLS no Postgres + tenant filter compulsório no ChromaDB retrieval. Se algum dia houver bug que tente cross, falha com `PERMISSION_DENIED`, não retorna dado errado.

---

## 7. Multi-Canal — Decisão #7

Chapapiuro recebe inbound de 4 canais. Contexto unificado por `whatsapp_number` ou `email_address` ou `obsidian_note_id`.

| Canal | Stack | Quando usar |
|---|---|---|
| **WhatsApp** | Evolution API (Baileys) | Default conversa rápida |
| **Telegram** | node-telegram-bot-api | Backup ou multi-device |
| **Obsidian** | Watch `PITOS/Inbox - Claudin/thread-XXX.md` | Captura escrita longa, voz transcrita, texto formatado |
| **Email** | IMAP inbound + SMTP outbound | Demandas formais ou cross-context (ex: NF de fornecedor) |

**Arquitetura:**

```
WhatsApp Evolution ─┐
Telegram bot       ─┤
Obsidian watcher   ─┤──→ inbound dispatcher ──→ Chapapiuro core ──→ Sophia
Email IMAP poller  ─┘                                 ↓
                                              outbound dispatcher
                                                      ↓
                                              ┌───────┼────────┐
                                              ↓       ↓        ↓
                                         WhatsApp  Telegram  Email
                                                      Obsidian (note append)
```

**Por que essa stack:**
- **WhatsApp Evolution** já está implementado em `C:\THALES\CHAPAPIURO-WHATSAPP\`
- **Telegram** baixo custo de implementação (token bot, sem QR pareado)
- **Obsidian** já é seu vault canônico — file watcher + sync VPS já existe (`vault-sync.sh`)
- **Email** viabiliza demandas formais, integra com fornecedores e bancos

---

## 8. Proatividade — Decisão #6

Chapapiuro **pode te abordar sem você pedir**, mas sempre via Sophia.

**Tipos de iniciativa:**

| Tipo | Trigger | Frequência |
|---|---|---|
| Briefing matinal | Cron 7h30 seg-sex (skill `manha`) | Diário |
| Shutdown noturno | Cron 21h00 (skill `noite`) | Diário |
| Alerta KPI | Sophia detecta desvio >X% | On-demand |
| Lembrete agenda | Cron baseado em ClickUp / Google Calendar | On-demand |
| Reflexão semanal | Domingo 19h (consolidação `chapapiuro_reflections`) | Semanal |
| Aniversário/data familiar | Cron baseado em pessoa.date_anniversary | Anual |
| Update de OS crítica | Rafael (COO) escala via Sophia | On-demand |

**Regra:** toda iniciativa proativa também passa por `demand_ledger` (com `channel='proactive'`). Mesma triangulação, mesma auditoria.

---

## 9. Stack & Hospedagem

**Plataforma base:** repo `C:\THALES\CHAPAPIURO-WHATSAPP\` é multi-agent (Sophia, Chapapiuro, futuros) via dispatcher Express. Rota webhook por agente: `/webhook/:agentId`.

**Alvo:** consolidar tudo na **VPS Hostinger 76.13.170.42** (mesma do DAP4 prod).

**Containers a subir:**

```yaml
# docker-compose adaptado pra VPS
services:
  chapapiuro-postgres:    # banco pessoal + profissional (2 dbs no mesmo cluster ou clusters separados?)
  chapapiuro-redis:       # cache + queue
  chapapiuro-evolution:   # WhatsApp Baileys
  chapapiuro-telegram:    # bot Telegram
  chapapiuro-email:       # IMAP poller + SMTP sender
  chapapiuro-obsidian:    # watcher do vault sync
  chapapiuro-server:      # Express + LLM dispatcher (Claude SDK)
```

**Cuidados (memória `project_dap4_evolution_lost_2026_04_24`):**
- Evolution stack foi DELETADA da VPS em 24/04 — checar volumes residuais
- Portas: 5432 + 8080 — auditar conflito com DAP4 prod
- Cloudflare tunnel: rota `chapapiuro.<domínio>` (não público — só Thales acessa)
- Auth: rotacionar `AUTHENTICATION_API_KEY=chapapiuro-key-123` antes de subir

**LLM:** Claude (Anthropic SDK já no `package.json`). Modelo: Sonnet 4.6 default, Haiku pra classificação (barato). Opus pra Council (decisões pesadas).

---

## 10. Pendências de Implementação

Em ordem de criticidade:

1. **Migrar repo CHAPAPIURO-WHATSAPP pra VPS** (~3-4h)
   - Audit volumes residuais Evolution
   - Adaptar docker-compose
   - Cloudflare tunnel
   - Rotacionar auth key
   - Re-pair WhatsApp ou migrar volume `evolution_instances`

2. **Schema Postgres** (`demand_ledger` + `chapapiuro_reflections` + dual database)
   - Migrations no `sql/` do repo
   - RLS pra isolamento pessoal/profissional

3. **Wire Chapapiuro ↔ Sophia** (HTTP gateway pro DAP4)
   - Endpoint Sophia: `POST /sophia/intake` recebe demand → retorna veredito
   - Chapapiuro core/llm.js: substituir chamada Anthropic direta por chamada Sophia

4. **Estender canais**
   - Telegram bot (token, webhook, dispatcher)
   - Obsidian watcher (chokidar no `PITOS/Inbox - Claudin/`)
   - Email IMAP/SMTP (sender + parser, anti-spam)

5. **Skill de aprender (Reflexion pipeline)**
   - Cron semanal: ler `chapapiuro_reflections`, gerar lições, atualizar system prompt
   - Confidence tracking ao classificar P/P

6. **Tiers de urgência (Sophia)**
   - Regras de classificação T0/T1/T2/T3 no Sophia
   - Queue T2 → briefing matinal
   - Push notification T0/T1 (FCM ou similar)

7. **Briefing matinal/noturno automatizados**
   - Cron 7h30 e 21h00 → Sophia gera → Chapapiuro entrega
   - Reusar skills `manha` e `noite` existentes

8. **Memória pessoal vs profissional fisicamente isolada**
   - Separar dbs Postgres
   - Separar collections ChromaDB
   - Validar zero cross-query (smoke test)

9. **Spec persona Chapapiuro definitiva** (`agents/chapapiuro/index.js` + persona.md)
   - Reescrever prompt baseado nesse spec
   - Few-shot examples reais (uso 1 semana, anonimizar)

10. **Observability**
    - Tracing OpenTelemetry → tabela `chapapiuro_traces`
    - Dashboard `/sophia` mostra fila T0/T1/T2/T3, latência, custo, taxa de Reflexion

---

## 11. Próximas Decisões (não fechadas neste spec)

- **Número WhatsApp pareado:** linha pessoal sua ou número novo? Ela é a mesma da Anna comercial? (Memória: Anna usa +5511917001822 Bosch e +5511967291822 Prime — Chapapiuro precisa linha PRÓPRIA)
- **Limite de custo mensal LLM:** hard cap por canal? Por tier?
- **Política de retenção de dados pessoais:** quanto tempo `chapapiuro_personal.demand_ledger` retém? Política LGPD aplicada a si mesmo?
- **Backup encriptado:** memória pessoal precisa cripto em rest (chave separada da do DAP4)?
- **Modo "férias":** Chapapiuro pausa proatividade quando Thales está OOF?
- **Renomear repo:** `CHAPAPIURO-WHATSAPP/` → `chapapiuro/` ou `personal-agents/` (multi-canal não é mais só WhatsApp)?

---

## 12. Referências

- Sennin Protocol — `PITOS/Sistemas/sennin-protocol.md`
- Mapa C-Level — `PITOS/Sistemas/sennin-c-level-map.md`
- Framework prompt agentes — `PITOS/DAP 4.0/Frameworks Operacionais/estrutura-prompt-agentes.md`
- Repo plataforma — `C:\THALES\CHAPAPIURO-WHATSAPP\`
- Parliament em código — `C:\dev\dap4\agents\parliament\`
- Reflexion paper — arXiv 2303.11366
- Evolution API — github.com/EvolutionAPI/evolution-api
