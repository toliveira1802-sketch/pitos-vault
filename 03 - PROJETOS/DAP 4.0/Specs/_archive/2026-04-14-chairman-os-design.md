---
spec: Chairman OS
owner: Thales
status: design-approved
created: 2026-04-14
phase: Fase 0 — pré-requisito pro ecossistema DAP 4.0
---

# Chairman OS — Design Spec

> Personal OS do Thales. Fundido com operação DAP. Ritual profundo + captura ubíqua + accountability por evidência.

## 1. Contexto e motivação

Thales é Chairman/CTO do ecossistema DAP 4.0 (12 unidades, meta R$700k/mês). Antes de estruturar o ecossistema formalmente (Fase 1 — Cérebro Obsidian, Fase 2 — Músculo ClickUp, Fase 3 — Sistema Nervoso DAP4.0 cockpit), é pré-requisito que o próprio Chairman esteja organizado. Sem isso, qualquer mapa mestre vira documento morto.

**Dor identificada:**
- Abertura do dia sem clareza (reativo desde o primeiro minuto).
- Fechamento do dia sem saber o que de fato avançou (sensação de não sair do lugar).
- Captura durante o dia falha (ideias/lembretes/compromissos se perdem).
- Sem accountability real — auto-relato vira ficção.

**Princípio norteador:** Evidência > relato. Causa raiz > sintoma. Três prioridades, nunca cinco.

## 2. Arquitetura

Sistema de 3 componentes integrados, com Obsidian como fonte da verdade persistente e Claude Code como orquestrador conversacional.

### Componentes

**C1 — Ritual diário (terminal + Obsidian)**
Slash commands `/manha` e `/noite` no Claude Code. Abertura e fechamento profundos (~40min/dia total). Morning pages dirigidas, auditoria de evidência noturna.

**C2 — Agente WhatsApp (captura ubíqua)**
Contato dedicado no WhatsApp ("Claudin"/"Chairman OS"). Classificador de intenção roteia cada mensagem (texto ou voz) pro store correto: Google Calendar, ClickUp, ou Obsidian.

**C3 — Scheduler proativo (disciplina externa)**
Cron na VPS cutuca via WhatsApp em horários calculados: pré-compromissos, checkpoints de prioridade, tasks overdue, streaks, drift.

### Stores (fontes da verdade)

| Dado | Store | Por quê |
|---|---|---|
| Compromissos time-based | Google Calendar | Universal, mobile-native, reminders nativos |
| Tasks acionáveis | ClickUp | Já usado, MCP ativo, automações possíveis |
| Conhecimento (ideias, decisões, reflexões, journaling) | Obsidian | Durável, markdown, do Thales |
| Métricas de negócio | Supabase (DAP4) | Dado vivo, via MCP |

### Fluxo de dados

```
ENTRADAS          CLASSIFICAÇÃO         STORES                 SÍNTESE
/manha  ─┐                                                    ┌─> Briefing
/noite  ─┤                                                    │    (manhã)
WhatsApp ├─> intent router ─┬─> Google Cal ────┐              │
Schedulers ─┘               ├─> ClickUp ────────┼──> leitura ──┤
                            ├─> Obsidian/inbox ─┤              │
                            ├─> Obsidian/dec.  ─┘              └─> Audit
                            └─> Daily log                           (noite)
```

## 3. Schemas de arquivo

**Pasta raiz:** `PITOS/Chairman OS/`

```
Chairman OS/
├── Daily/       YYYY-MM-DD.md
├── Weekly/      YYYY-Www.md
├── Monthly/     YYYY-MM.md
├── Quarterly/   YYYY-Qn.md
├── Inbox/       inbox.md         (capturas brutas do C2, triagem semanal)
├── Decisions/   decisions.md     (log append-only de decisões estratégicas)
└── _templates/  daily.md, weekly.md, monthly.md, quarterly.md
```

### Daily note

```markdown
---
date: YYYY-MM-DD
weekday: segunda|terça|...
week: YYYY-Www
status: open | closed
followthrough: null  # 0-100, preenchido à noite
---

# YYYY-MM-DD · weekday

## Briefing (preenchido em /manha)
- Calendário hoje
- Tasks ClickUp (abertas + overdue)
- KPIs DAP (snapshot 24h)
- Carry-over de ontem

## Prioridades do dia (máx 3)
1. [ ] ... — prazo — critério de done
2. [ ] ...
3. [ ] ...

## Morning pages
3 perguntas dirigidas (variam por dia da semana). Respostas livres.

## Log do dia
Timestamped. Capturas do C2 durante o dia aparecem aqui.

## Shutdown (preenchido em /noite)
- Audit de compromissos (✅/❌/⚠️ com evidência)
- Follow-through: X%
- O que avançou
- O que travou (causa raiz, não sintoma)
- Lição do dia
- Gratidão
- Preview de amanhã
```

### Weekly review

```markdown
---
week: YYYY-Www
theme: "meta da semana em 1 frase"
status: open | closed
avg_followthrough: null
---

# Semana w · dd-dd mês

## Tema / Foco

## Números
Tabela diária: prioridades/done/follow-through + média semanal.

## KPIs DAP (delta vs semana anterior)

## Wins

## Travas (causa raiz)

## Padrões que notei

## Próxima semana
- Tema
- 3 apostas
```

### Monthly + Quarterly

Mesmo padrão. Agregação maior. Quarterly inclui OKRs por unidade DAP e decisões estruturais.

### Inbox + Decisions (append-only)

Inbox: capturas brutas timestamped, tag `#triar`, processadas semanalmente.
Decisions: uma decisão por bloco — contexto, decisão, razão, revisitar em.

## 4. Slash commands

### `/manha` (~20min)

1. **Contexto silencioso** (~30s, eu leio sozinho):
   - Daily/ontem.md (carry-over, lição)
   - Weekly/atual.md (tema)
   - Google Calendar (eventos + bloqueios hoje)
   - ClickUp (tasks hoje + overdue)
   - Supabase (KPIs 24h)
   - Inbox (capturas pendentes desde ontem)

2. **Briefing** (~2min): mensagem estruturada no terminal com tudo resumido. Carry-over destacado. Conflitos de agenda sinalizados.

3. **Triagem da inbox** (se houver, ~3min): lista capturas, você fala task/decisão/ideia/descarta, eu roteio.

4. **Morning pages dirigidas** (~10min): 3 perguntas, uma por vez. Variam por dia:
   - Seg: aposta da semana / fricção / versão sua
   - Ter-qui: o que tá mais vivo / próximo movimento / onde tô me enganando
   - Sex: o que aprendi / o que vou parar / 1 coisa no fim de semana pro DAP

5. **3 prioridades** (~3min): proponho 3 com horário sugerido e critério de done. Você ajusta.

6. **Escrita**: gero `Daily/hoje.md`. Confirmo primeira prioridade.

### `/noite` (~20min)

1. **Auditoria de evidência** (~1min, eu faço sozinho):
   - Daily/hoje.md (prioridades declaradas)
   - ClickUp (tasks done hoje)
   - Google Calendar (eventos atendidos)
   - Supabase (movimento de KPIs)
   - Log do dia (capturas do C2)

2. **Confronto com dado** (~3min): mostro diff estado real vs prometido. Follow-through %.

3. **Shutdown** (~10min):
   - Prioridade não feita → "causa raiz, não sintoma" (re-pergunto se for desculpa)
   - O que avançou fora da lista
   - Lição em 1 frase
   - Gratidão

4. **Preparação de amanhã** (~5min): carry-over automático, preview calendário, crio `Daily/amanha.md`.

5. **Weekly roll-up** (sexta, +5min): médias, agregação, 3 perguntas de padrão, fecho Weekly/atual, abro Weekly/próxima.

6. **Escrita + fechamento**: `status: closed`, `followthrough: X`. "✓ dia fechado."

### Regras de ouro

1. Evidência > relato.
2. Causa raiz > desculpa (re-pergunto até chegar).
3. Máximo 3 prioridades.
4. Silêncio OK (não forço morning pages).

## 5. C2 — Agente WhatsApp

### Canal
Linha pessoal do Thales, padrão "self-messaging" — Thales manda para si mesmo (chat "Notas Chairman" com webhook capturando) ou para contato-proxy que encaminha pro pipeline. Zero fricção, zero contato novo a adotar. Infra: avaliar (a) resgatar `C:\dev\thales-agent` (80% pronto, pausado) vs (b) construir via Meta Cloud API (já integrada no DAP via Kommo) — decisão técnica no plan da Fase 0.2. Atenção para isolar completamente do canal comercial (Ana/Kommo) para evitar cruzamento de contexto.

### Classificador de intenção

Mensagem chega → LLM classifica em 1 de 6:

| Intenção | Trigger típico | Store |
|---|---|---|
| Compromisso | "dia X hora Y, Z" / "agenda X" | Google Calendar |
| Task | "preciso fazer X" / "me lembra" | ClickUp |
| Ideia | "ideia:" / "pensei em" | Obsidian/Inbox |
| Decisão | "decidi" / "fechei com" | Obsidian/Decisions |
| Log de momento | "acabei de" / "fechei reunião" | Daily/hoje |
| Pergunta | "quantas OS?" / "o que tem hoje" | consulta + resposta |

Ambíguo → agente pergunta.

### Confirmação
Toda escrita retorna confirmação curta: `✓ task criada: ClickUp #1234. prazo: amanhã.`

### Voz
Nota de voz → Whisper (OpenAI ou Groq) → mesmo pipeline. Essencial para capturas dirigindo/na oficina.

### Triagem semanal
Domingo noite: "X itens na Inbox. triagem em 10min?" — processamos item a item via WhatsApp ou terminal.

## 6. C3 — Scheduler proativo

### Implementação
Cron na VPS (infra DAP existente), ciclo a cada 5min: lê Daily/hoje + Calendar + ClickUp, calcula se há pings.

### Regras

| Regra | Timing | Mensagem |
|---|---|---|
| Pré-compromisso | -15min antes de evento Calendar | "15min pra X, sair em 5" |
| Check de prioridade | 11h, 14h, 17h | "prioridade N sem evidência. status?" |
| Overdue gentil | Task ClickUp +1d | "X venceu ontem. adia/faz/descarta?" |
| Overdue firme | Task ClickUp +3d | "X atrasada 3 dias. o que vai acontecer?" |
| Streak positiva | Follow-through >80% 3 dias | "3 dias 80%+. ritmo bom." |
| Alerta drift | Sem /noite por 2 dias | "2 dias sem fechar. tudo bem?" |

### Silenciamento
`/silencio 2h` no WhatsApp pausa pushes. `/silencio off` retoma. Protege deep work.

### Stake (accountability 🔴 opcional)
Prioridade marcável com stake no `/manha`: "prioridade 2 — stake R$200 pro PT se furar". C3 audita à noite. Missed → cutucada de pagamento. Log em Decisions.

## 7. Faseamento

**Fase 0.1 — C1 (3-5 dias)**
Ritual terminal + schemas Obsidian. `/manha` e `/noite` leem Calendar + ClickUp + Supabase via MCP. Sem captura WhatsApp ainda (Inbox manual).
*Entregável:* Thales roda ritual por 1 semana, sente diferença mensurável.

**Fase 0.2 — C2 (1-2 semanas)**
Decisão técnica (thales-agent vs Meta Cloud). Classificador + rotas + voz.
*Entregável:* zap cai no lugar certo, zero atrito.

**Fase 0.3 — C3 (3-5 dias)**
Cron + regras + silenciamento + stake.
*Entregável:* pings proativos nos horários certos. Self-report morre.

**Total:** 3-4 semanas pro Chairman OS completo.

## 8. Pré-requisitos técnicos

- **Google Calendar MCP** — não está ativo hoje. Instalar e autenticar no início da Fase 0.1.
- **ClickUp MCP** — ativo (coworkin).
- **Supabase MCP** — ativo.
- **WhatsApp infra** — Meta Cloud já integrado no DAP via Kommo, mas escopo atual é comercial (Ana). Precisa separar canal do Chairman OS — decisão de arquitetura na Fase 0.2.
- **VPS cron** — Hostinger 76.13.170.42, já em uso, disponível pra C3.
- **Whisper API** — escolher provedor (OpenAI/Groq) na Fase 0.2.

## 9. Critérios de sucesso

**Fase 0.1 (C1):**
- 5 dias consecutivos com `/manha` + `/noite` executados
- Daily notes fechadas com follow-through preenchido
- Thales reporta: "abro o dia sem caos" + "fecho sabendo o que avançou"

**Fase 0.2 (C2):**
- 90% das mensagens classificadas corretamente sem intervenção
- Zero perdas de captura em 2 semanas de uso
- Nota de voz funcionando em trânsito

**Fase 0.3 (C3):**
- Pings chegam nos horários certos em 100% dos casos
- Silenciamento funciona como esperado
- Follow-through médio semanal >70% após 4 semanas de uso do sistema completo

## 10. Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Thales para de fazer o ritual depois de 2 semanas | C3 alerta drift após 2 dias sem /noite; ritual escalável (pode cair pra versão leve temporariamente) |
| WhatsApp agent fica confuso com mensagens ambíguas | Classificador sempre pergunta quando incerto; Inbox default |
| Integração Meta Cloud/Kommo conflita com canal comercial (Ana) | Isolamento estrito de fluxos: webhook dedicado, base de dados separada, classificador nunca cruza contexto Chairman ↔ leads DAP |
| MCP Calendar instável | Fallback: C1 funciona só com ClickUp + Obsidian no início |
| Stake 🔴 vira fonte de ansiedade ao invés de disciplina | Opt-in por prioridade, nunca default; pode ser desligado |

## 11. Fora de escopo (intencionalmente)

- Gamificação com XP/levels (superficial, distrai do sinal)
- Dashboard visual do Chairman OS no DAP4.0 (é a Fase 3 do plano maior, não agora)
- Sync bidirecional com outros sistemas de notas (Notion, Apple Notes)
- Modo multi-usuário (isso é pessoal do Thales, period)

## 12. Próximo passo

Após aprovação deste spec pelo Thales:
1. Invocar `writing-plans` skill
2. Criar implementation plan detalhado para **Fase 0.1 (C1)** — primeiro entregável
3. Fases 0.2 e 0.3 ganham plans próprios depois que 0.1 estiver rodando há 1+ semana
