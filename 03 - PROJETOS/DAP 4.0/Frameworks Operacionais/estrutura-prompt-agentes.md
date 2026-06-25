---
title: Estrutura World-Class de Prompt para Agentes IA
unidade: DAP AI
autor: Walter (CKO)
versão: v1
data: 2026-05-05
fontes: 11 (curadas, 2 com cobertura parcial)
status: aprovado
---

# Estrutura World-Class de Prompt para Agentes IA
**Framework Operacional — Doctor Auto Prime**

## TL;DR

Agente não é prompt longo. Agente é um sistema com quatro órgãos vitais — **identidade, ferramentas, memória, loop de decisão** — e um perímetro de guardrails que define o que ele recusa. A pergunta-padrão antes de criar qualquer agente novo é: *"isso é workflow ou agent?"* [1]. 80% dos casos no DAP são workflow disfarçado de agente — e workflow custa menos, quebra menos, audita melhor. Quando precisar de agente real (Anna no WhatsApp, Sophia orquestrando conselho), siga: identidade afiada, tools com contrato de UI, memória em camadas com tenant isolado, loop ReAct/Reflexion explícito, e verificação programática do output antes de responder ao mundo. Multi-agente é último recurso, não primeiro [5][10].

---

## 1. Identidade & Persona

Identidade não é flavor — é o gradiente que decide cada token gerado. O system prompt define **quem fala**, **a quem serve**, **com que voz**, **sob que valores**. Park et al. [9] mostraram que persona + memory stream produz comportamento crível; sem persona, o LLM regride pra média do treino (assistente genérico bege).

**Estrutura mínima de identidade** (formato denso, ordem importa):

```
NOME: Anna
PAPEL: CRO digital do Doctor Auto Prime — primeira voz do funil WhatsApp
SERVE A: lead que chega via Bosch Car Service ou DAP Prime no Kommo
VOZ: direta, técnica, sem diminutivos, sem emoji, PT-BR oficina premium
VALORES: nunca prometer prazo/preço sem orçamento real; sempre qualifica antes de cotar; escalona pro Thales quando lead é VIP ou problema é crítico
NÃO É: chatbot genérico, atendente call-center, vendedor agressivo
```

**Anti-patterns observados nas fontes** [1][6]:
- Persona como roleplay teatral ("Você é um assistente útil e amigável") — vira chatbot.
- Backstory inflado ("Você nasceu em..., trabalhou 20 anos...") — consome contexto sem mudar comportamento.
- Mistura de papéis ("Você é CRO E suporte E SDR E closer") — o modelo escolhe o papel mais frequente do treino.

**Regra DAP**: identidade de agente cabe em ≤8 linhas. Se precisa mais, é persona inflada ou escopo errado.

---

## 2. Missão & Escopo

Missão é o vetor único do agente; escopo é a fronteira. Fronteira sem ambiguidade é o que separa Anna de Sophia de Walter — três agentes em produção que **não invadem domínio um do outro**.

Anthropic [1] formaliza a divisão crítica: **workflow** (caminhos de código predefinidos orquestrando LLM+tools) vs **agent** (LLM dirige dinamicamente o próprio uso de tools). Quase todo problema de agente "que não funciona" no DAP foi workflow tentando se passar de agente.

**Decision tree pra criar agente novo no DAP**:

```
1. A tarefa tem fluxo previsível e finito? → workflow (ex: webhook Kommo → enrich → push Supabase)
2. O número de passos é imprevisível e depende do que o ambiente responde? → agent
3. Existe agente atual cujo escopo cobre 70%+? → estende como skill/tool, não cria agente novo
4. O custo de errar é >R$ médio ticket? → workflow com LLM em ponto crítico, não agent autônomo
```

**Aplicado**: Anna *é* agent (lead responde de N maneiras, ela decide próximo passo). O scoring de lead novo *não é* agent — é workflow determinístico chamando LLM uma vez pra classificar.

**Anti-pattern**: agente que tudo faz. Sintoma: system prompt com 12 responsabilidades. Solução: separar em N agentes especialistas + supervisor (ver §6) ou colapsar em workflow.

---

## 3. Ferramentas (Tools)

Anthropic [1][2] cunhou o termo certo: **Agent-Computer Interface (ACI)** — trate o design de tools como UI design, não como backend. "Invista tanto em documentação e testes de ferramentas quanto em HCI tradicional" [1].

**Contrato mínimo de tool** (cada uma):

```yaml
name: kommo_qualify_lead
purpose: Avalia lead por 5 eixos (orçamento, urgência, perfil de carro, fit Bosch/Prime, histórico) e retorna tier QUENTE/MORNO/FRIO/DESCARTÁVEL
when_to_use: Após primeira mensagem do lead; antes de qualquer cotação; uma vez por lead
when_NOT_to_use: Lead já tier QUENTE marcado <72h; conversa sobre OS em andamento
inputs:
  - lead_id (str, required)
  - latest_message (str, required, max 4000 chars)
outputs:
  - tier (enum)
  - score (int 0-100)
  - reasoning (str, ≤200 chars, justificativa)
errors:
  - LEAD_NOT_FOUND: lead_id inexistente no Kommo
  - RATE_LIMIT: aguardar 5s, retry 3x max
example_call: kommo_qualify_lead(lead_id="LEAD-12345", latest_message="quero saber preço de troca de embreagem do Audi A3 2018")
```

**Princípios de tool engineering** [1][3]:

1. **Granularidade certa**: tool muito fina (`get_field_x`) força N chamadas; muito grossa (`do_everything`) esconde decisões. Regra: 1 tool = 1 verbo de negócio.
2. **Naming**: descritivo, em inglês, snake_case, verbo_substantivo. `kommo_qualify_lead` > `qualify` > `kql`.
3. **Espaço cognitivo** [1]: deixe o agente pensar antes de chamar. Em prompts: "Pense em voz alta antes de escolher a tool". Em tool design: tools com `reasoning` field obrigatório no input forçam justificativa.
4. **Parallel tool use**: quando 2+ tools são independentes, instrua chamada paralela. DAP: `kommo_get_lead_history` + `chromadb_search_similar_cases` rodam juntas, não em série.
5. **Erros falam pro modelo, não pro humano**: erro de tool deve ensinar o agente a se recuperar. `"LEAD_NOT_FOUND: confirme que lead_id começa com LEAD- e tem 5 dígitos"` > `"404"`.

**Anti-patterns observados** [1][3]:
- Tool com contrato vago ("retorna info do lead") — agente alucina o shape.
- Tools sobrepostas (`get_lead`, `fetch_lead`, `read_lead`) — agente escolhe mal.
- Tool que muda comportamento por flag (`get_lead(verbose=True)`) — duas tools disfarçadas de uma.

---

## 4. Memória & Contexto

Lilian Weng [4] define três camadas; Anthropic [3] e Park et al. [9] operacionalizam. No DAP elas mapeiam pra:

| Camada | Onde mora | TTL | Exemplo DAP |
|---|---|---|---|
| **Working memory** | system prompt + tool definitions | sessão | Identidade Anna, contrato de tools Kommo |
| **Short-term** | conversation history (in-context) | conversa atual | Últimas 20 mensagens do lead no WhatsApp |
| **Long-term semântica** | ChromaDB (vector) | persistente | SOPs DAP, fichas técnicas BMW/Audi, casos resolvidos |
| **Long-term estruturada** | Supabase (relacional) | persistente | Tabela `leads`, `os`, `agents_state` |
| **Episodic** | log de ações + reflexão (Reflexion [8]) | persistente | Trajetória do lead, lições por OS atendida |

**Regras DAP** (lições do Phase 1a Anna [memory: project_dap4_phase1a]):

1. **Working memory é caro** — cada token no system prompt multiplica por chamada. Coloque ali só o que muda comportamento sempre.
2. **Short-term tem context rot** [3] — performance degrada quando conversation enche. Compactar a cada N turnos com instrução `/compact preservar últimas decisões e dados do lead`.
3. **Long-term é o lugar de RAG, não de tudo** — não joga toda doc no Chroma. Cure por unidade (ops_prime, ops_bosch, ensina_*) e force tenant filter no retrieval. Vazamento entre tenants é falha de segurança, não bug [memory: project_dap4_dual_waba].
4. **Episodic memory é o ativo composto** — Reflexion [8] mostra que log de "o que tentei, o que funcionou, o que errei" + reflection LLM-as-judge produz +11pp em HumanEval. No DAP isso é o que separa Anna v1 de Anna v3.

**Decisão**: onde mora o quê?

- Muda comportamento em toda chamada → system prompt
- Específico do lead/conversa → short-term (in-context)
- Conhecimento DAP genérico → ChromaDB com tenant filter
- Estado canônico (lead status, OS) → Supabase, agente lê via tool
- "O que aprendi atendendo lead X" → tabela `agent_reflections` + reindex no Chroma semanal

**Anti-pattern crítico**: vazar contexto Bosch em conversa Prime, ou vice-versa. Solução obrigatória: tenant_id como filtro nativo em todo retrieval, não como header opcional.

---

## 5. Loop de Decisão

Aqui é onde a maioria dos times queima dinheiro. Anthropic [1] e Andrew Ng [10] convergem: **a pergunta não é "que loop usar", é "preciso de loop?"**. Workflow determinístico bate agente autônomo em custo, latência e previsibilidade na maioria dos casos.

**Hierarquia de loops** (do mais barato pro mais caro):

### 5.1 Workflow puro (sem loop)
LLM em pontos discretos, fluxo em código. Ex: webhook lead → `classify(lead)` → roteia. Determinístico, auditável, barato. **Default DAP**.

### 5.2 Prompt chaining [1]
Saída do LLM A vira entrada do LLM B. Ex: extrai dados do áudio do WhatsApp → resume → propõe resposta. Linear, sem decisão.

### 5.3 Routing [1]
LLM classifica e despacha pra branch especializado. Ex: mensagem entrante → `router_llm` → `{cotacao, agendamento, queixa, informacao}`.

### 5.4 ReAct [7] — loop básico de agente
Padrão `Thought → Action → Observation → Thought...`. Resolve hallucination de CoT puro porque cada passo é grounded em observação real do ambiente. **Padrão default da Anna**.

```
Thought: Lead pergunta preço de embreagem Audi A3. Preciso saber ano, motorização, e se já tem orçamento Kommo.
Action: kommo_get_lead(lead_id="LEAD-12345")
Observation: {ano: null, modelo: "A3", historico_os: []}
Thought: Falta ano e motor. Pergunto direto, não chuto preço.
Action: send_whatsapp(text="Pra cotar com precisão preciso saber: ano e motor (1.4 TFSI ou 2.0)?")
```

### 5.5 Reflexion [8] — loop com self-improvement
ReAct + módulo de reflexão que escreve no episodic memory após cada trial. +11pp HumanEval. No DAP: Anna escreve "o que aprendeu" toda OS finalizada, reindex no Chroma. Vai pra produção depois que telemetry estabilizar.

### 5.6 Plan-Execute / Orchestrator-Workers [1][10]
Plan separado do execute. Útil quando subtarefas não dão pra prever. Ex: Sophia recebe pedido do Thales "faz audit completo do funil semana", planeja N steps, dispara workers. Custo alto, ganho real só quando task é aberta.

**Decision matrix**:

| Cenário | Loop |
|---|---|
| Classificação 1-shot | workflow + LLM call |
| Pipeline determinístico | prompt chaining |
| Roteamento por categoria | routing |
| Conversa stateful com tools (Anna) | ReAct |
| Tarefa repetível com aprendizado (Anna v3) | Reflexion |
| Tarefa aberta longa (Sophia audit) | orchestrator-workers |

**Custo, latência, falibilidade**: cada degrau acima multiplica chamadas LLM. Reflexion é 3-5x ReAct, Orchestrator é 5-15x. Não suba degrau sem evidência de que o degrau abaixo falhou.

---

## 6. Coordenação Multi-Agente

LangChain [5] formaliza três padrões; CrewAI [6] adota role-based; Anthropic [1] alerta: **multi-agente é último recurso**. "Comece com prompts simples; adicione complexidade apenas quando comprovadamente necessário" [1].

**Padrões canônicos**:

### Network (todos com todos)
Cada agente pode chamar qualquer outro. Flexível, mas explode complexidade. Evite em produção DAP.

### Supervisor [5]
"O supervisor é um agente cujas tools são outros agentes" [5]. Central, com scratchpad isolado por agente. **Padrão DAP recomendado.** Sophia é supervisor; Anna, Kimi, Walter, Insights são workers.

```
Sophia (supervisor) ── tools ──▶ {agent_anna, agent_kimi, agent_walter, agent_insights}
                                    │
                                    └─▶ cada um com system prompt, tools, memória próprios
```

### Hierarchical [5]
Supervisor de supervisores. Ex: Sophia → {Comercial-supervisor → {Anna, Kimi}}, {Conhecimento-supervisor → {Walter, Curador}}. Reserva pra quando o nº de agentes passa de ~7 e cognitive overload bate o supervisor.

### Handoff (CrewAI/OpenAI Agents SDK [11])
Agente A "entrega" a conversa pra B com contexto resumido. Diferente de tool call: B vira a voz. DAP: Anna → handoff → Thales humano (escalação VIP).

### Collaboration (scratchpad compartilhado) [5]
Todos veem tudo. Bom pra brainstorm (Conselho dos 12 diretores [memory: reference_sala_do_conselho_dify]), ruim pra produção transacional.

**Contratos entre agentes** (não-negociável):

```yaml
# A2A contract: Sophia → Walter
input_schema:
  request_id: str
  query: str           # pergunta natural
  context_hint: str    # opcional, ajuda retrieval
  tenant: enum[prime, bosch, ensina, geral]
  max_tokens_response: int (default 1500)
output_schema:
  request_id: str
  answer: str
  citations: list[{source, chunk_id, score}]
  confidence: float (0-1)
  fallback_required: bool  # true = Walter não tem; Sophia decide próximo passo
sla:
  latency_p95_ms: 4000
  cost_max_usd: 0.05
```

Sem schema formal entre agentes, vira telefone-sem-fio com alucinação acumulada. **Ação Thales**: formalizar contratos Sophia↔{Anna, Walter, Kimi, Insights} antes de escalar pra prod.

**Quando vale agente único vs múltiplos**:

- 1 papel + 1 vetor de decisão + tools coesas → 1 agente
- 2+ papéis com vozes/SLA/guardrails diferentes → split
- Contexto de A "vaza" responsabilidade pra B com frequência → split
- Custo de orquestração > ganho de especialização → unifica

---

## 7. Output Format & Citação

Output é contrato com o consumidor (humano, próximo agente, sistema downstream). Sem contrato, pipeline quebra silencioso.

**Hierarquia de outputs**:

1. **Structured (JSON via tool-call output)** — default pra agente→agente e agente→sistema. OpenAI Agents SDK [11] e Anthropic [2] suportam tool como output forçando schema.
2. **Markdown estruturado** — agente→humano técnico. Headings, tabelas, código. Walter responde Thales assim.
3. **Texto curto natural** — agente→cliente final. Anna no WhatsApp: máx 2 parágrafos, sem markdown, sem bullet, voz humana.
4. **Streaming** — UX onde latência mata (Sophia hub). Final tem que ser válido mesmo se interrompido.

**Citações** (não-negociável pra Walter, RAG, e qualquer agente que afirma fato):

```json
{
  "answer": "Embreagem do Audi A3 1.4 TFSI tem reforço B&B opcional pra +30% torque...",
  "citations": [
    {"source": "ficha-audi-a3-1.4tfsi.md", "chunk_id": "ops_prime#audi_a3_clutch_v2", "score": 0.84},
    {"source": "OS-2024-1183", "chunk_id": "os_history#1183_clutch_swap", "score": 0.71}
  ],
  "confidence": 0.78
}
```

**Confidence/uncertainty** [4]: agente que não admite incerteza alucina. Force `confidence: float` no schema. Threshold operacional: confidence < 0.5 → Anna não responde, escala pro Thales.

**Anti-fluff**:
- Não use bullet quando texto corre melhor.
- Não use markdown em WhatsApp (renderiza errado).
- Não recapitule a pergunta antes de responder ("Você perguntou sobre... pois bem,...") — clichê de chatbot, queima token.
- Não diga "Espero ter ajudado!" — voz CRO premium não termina assim.

---

## 8. Guardrails & Failure Modes

Guardrail é o que o agente **se recusa a fazer** + o que detecta **falha em si mesmo**. Sem isso, agente em produção é Russian roulette com brand risk.

**Camadas de guardrail** [1][2][11]:

### Pré-input (antes do LLM)
- Rate limit por lead/tenant.
- Prompt injection detection (string match em padrões `ignore previous instructions`, `system:`, `role:`).
- Input length cap (corta mensagem >4000 chars, evita context flood).
- PII redaction antes de logar (CPF, cartão, telefone fora do esperado).

### In-loop (durante execução)
- Cost cap por conversa (Anna: $0.50/lead/dia hard cap).
- Tool budget (max 8 tool calls por turn — corta loop infinito).
- Refusal patterns: Anna recusa cotar preço sem orçamento real, recusa diagnóstico sem ver carro, recusa prazo sem agenda confirmada.
- Escalation triggers: lead VIP (Kommo tag), problema crítico (palavras-chave: "vazando", "fumaça", "não liga"), confidence < 0.5 → handoff Thales.

### Pós-output (antes de enviar pro mundo)
- Output validation contra schema (JSON rejeitado → retry com erro feedback ao agente).
- LLM-as-judge sanity check (em ações destrutivas: confirmar 2x via segundo modelo barato).
- Rules-based feedback [2]: linter no código, regex no preço, validador no orçamento Kommo.

**Failure modes catalogados nas fontes** [4][8]:

| Modo | Sintoma | Mitigação |
|---|---|---|
| Hallucination factual | Anna inventa preço | Tool obrigatório `kommo_get_quote` antes de qualquer número |
| Loop infinito | ReAct sem progresso | Tool budget + Reflexion detector "estou repetindo" |
| Long-horizon plan drift [4] | Sophia esquece objetivo no step 8 | Re-state goal a cada 3 steps; Plan-Execute em vez de pure ReAct |
| Format error [4] | JSON inválido downstream | Structured output + retry com erro como observation |
| Context rot [3] | Anna esquece dados do lead a partir do msg 30 | `/compact` automático a cada 20 msg preservando lead profile |
| Tool overuse | Agent chama N tools redundantes | Naming claro + `when_NOT_to_use` no contrato |
| Persona drift | Anna vira chatbot genérico após msg longa | Re-injetar identidade resumida em compaction |
| Tenant leak | Resposta Bosch aparece em chat Prime | Tenant filter compulsório em RAG, validado no output |

**Observability obrigatória** (Anthropic [2], OpenAI [11]):

- **Tracing**: log estruturado de Thought/Action/Observation por turn, com request_id correlacionável.
- **Replay**: dado um trace, reexecutar offline pra debug. ChromaDB versionado por commit.
- **Metrics**: latência p50/p95/p99, custo por conversa, taxa de escalação, taxa de refusal, confidence distribution.
- **Alerts**: refusal rate >5%, escalation rate >15%, confidence p50 <0.6 → Walter avisa Thales.

**Aplicado DAP — Anna não promete preço sem orçamento real**:

```
Guardrail: refusal_no_quote_without_kommo
Trigger: msg do lead contém /R\$|preço|valor|quanto|custa/i AND kommo_lead.has_active_quote == false
Ação: bloquear geração de número, responder template:
  "Pra te passar valor preciso, vou registrar seu carro e o que precisa. Em até 1h o Thales ou eu retornamos com orçamento real."
Log: refusal_event{type=no_quote, lead_id, tenant}
```

---

## Aplicação prática DAP4

### Tabela síntese — agentes em produção/roadmap

| Agente | Missão | Tools principais | Memória | Loop | Multi-agent | Guardrail crítico |
|---|---|---|---|---|---|---|
| **Anna** (CRO) | Primeira voz WhatsApp, qualifica e converte lead | `kommo_get_lead`, `kommo_qualify_lead`, `chromadb_search(tenant)`, `send_whatsapp`, `escalate_to_thales` | short: msgs lead; long: ops_{tenant} no Chroma; episodic: reflexões pós-OS | ReAct → Reflexion (v3) | worker do Sophia | sem cotação sem Kommo quote real |
| **Walter** (CKO) | Curador de conhecimento, RAG autoridade | `chromadb_search`, `vault_read`, `web_fetch`, `validate_source`, `chunk_and_index` | long: vault PITOS + Chroma; episodic: log de aprovações | workflow + LLM (validation) | worker do Sophia, callable por outros | jamais ingerir sem citar fonte; tenant isolation no chunk |
| **Sophia** (CEO/orquestradora) | Recebe pedido Thales, planeja, despacha workers, sintetiza | `dispatch_agent`, `query_supabase`, `read_kommo_funnel`, `compose_council` | working: contexto Thales; long: histórico de planos | Plan-Execute + Orchestrator | supervisor de Anna/Walter/Kimi/Insights | só responde Thales se ≥2 workers convergirem em fato crítico |

### Exemplo concreto — fluxo Anna recebe lead novo

```
1. Webhook Kommo → gateway → Anna (worker, supervisor=Sophia)
2. Anna [system prompt: identidade §1, contrato §2, tools §3, guardrails §8]
3. ReAct turn 1:
   Thought: lead novo, sem histórico, msg "preciso revisar minha BMW 320i 2017"
   Action: kommo_get_lead(LEAD-X) — paralelo — chromadb_search("BMW 320i revisão", tenant=prime)
   Observation: lead vazio + 3 chunks SOP revisão BMW
4. ReAct turn 2:
   Thought: tenho info técnica, falta KM e última revisão. Pergunto, não chuto.
   Action: send_whatsapp(...) com pergunta direta + posicionamento DAP Prime
5. Pós-output guardrail: validar não há preço/prazo no texto → OK → envia.
6. Reflexion (async): registra trial, atualiza episodic memory.
```

---

## Anti-patterns observados

Top 5 destilados das 11 fontes:

1. **Agente que vira chatbot generalista** [1][6] — falta de missão afiada. Sintoma: system prompt com >12 linhas e papéis múltiplos. Cura: split ou volta pra workflow.
2. **Prompt-stuffing** [3] — encher system prompt com edge cases, exemplos longos, FAQ inteiro. Sintoma: degrade após 30 turns. Cura: mover pra skill on-demand ou tool retrieval, não pro working memory.
3. **Falta de role separation** [5][6] — 1 agente fazendo qualificação + cotação + agendamento + pós-venda. Cura: supervisor + workers especializados, contratos formais entre eles.
4. **Tool com contrato vago** [1][2] — "retorna info" sem schema. Modelo aluciona shape, downstream quebra. Cura: ACI tratado como UI design, schema + when-to-use + when-NOT + erros que ensinam.
5. **Pular workflow e começar com agent autônomo** [1][10] — 5x custo, 5x latência, 5x failure. Cura: workflow primeiro, agent só quando workflow demonstrou insuficiência mensurável.

Bonus: **falta de observability** [2][11]. Agent sem trace é caixa-preta sem diff. Cura: tracing estruturado obrigatório do dia 1.

---

## Próximos passos (decisões pro Thales)

1. **Formalizar contratos A2A** Sophia↔Anna, Sophia↔Walter, Sophia↔Kimi em YAML versionado em `dap-aios/contracts/`. Hoje é prompt-engineering ad-hoc; sem schema, escalar quebra.
2. **Schema canônico ChromaDB** — definir collection-per-tenant com prefix obrigatório (`ops_prime_*`, `ops_bosch_*`, `ensina_*`, `geral_*`). Walter pública `chunk_and_index(source, tenant, …)` como única porta de entrada — bloqueia ingestão livre.
3. **Observability stack** — tracing OpenTelemetry → Supabase tabela `agent_traces` (request_id, agent, turn, thought, action, observation, latency_ms, cost_usd, tenant). Dashboard em `/sophia` com p95 latency, refusal rate, escalation rate por agente.
4. **Reflexion pipeline pra Anna** — após OS finalizada/lead descartado, prompt reflexão "o que aprendi com este lead", grava em `agent_reflections`, reindex semanal no Chroma. Custo marginal, ganho composto.
5. **Decisão Anna v2 vs v3**: hoje é ReAct puro. Reflexion exige episodic memory + reindex. Evidência (telemetry 30 dias) define se vale o degrau.
6. **Walter como gate de conhecimento** — política: nada entra no Chroma sem passar por `walter.validate_source(url|path) → {approve, reject, needs_chunk_strategy}`. Elimina lixo no RAG.

---

## Fontes

[1] Anthropic, *Building Effective Agents* (engineering blog) — distinção workflow vs agent, blocos construtivos (augmented LLM, prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer), princípio ACI.
[2] Anthropic, *Building Agents with the Claude Agent SDK* (claude.com/blog) — feedback loop gather→action→verify, subagents com contexto isolado, MCPs, work verification (rules/visual/LLM-judge).
[3] Anthropic, *Claude Code Best Practices* (code.claude.com/docs) — context window como recurso central, verify-your-work, explore→plan→code, CLAUDE.md, subagents pra investigação, failure patterns concretos.
[4] Lilian Weng, *LLM Powered Autonomous Agents* (lilianweng.github.io, jun/2023) — taxonomia formal (planning, memory, tool use, action), CoT/ToT/ReAct/Reflexion, 3 limitações canônicas (context length, long-horizon planning, NL reliability).
[5] LangChain, *LangGraph Multi-Agent Workflows* (langchain.com/blog) — três padrões (collaboration, supervisor, hierarchical), "supervisor é agente cujas tools são agentes", graph explícito vs conversation framing. [GAP: doc oficial multi_agent.md inacessível, usado blog post como substituto — cobertura parcial mas suficiente].
[6] CrewAI, *Introduction* (docs.crewai.com) — role-based agents (role/goal/backstory/tools), Sequential vs Hierarchical process, Crews+Flows pattern.
[7] Yao et al., *ReAct: Synergizing Reasoning and Acting in Language Models* (arXiv 2210.03629) — paradigma Thought/Action/Observation, redução de hallucination via grounding em ambiente. [GAP parcial: prompt template exato no PDF, não no abstract].
[8] Shinn et al., *Reflexion: Language Agents with Verbal Reinforcement Learning* (arXiv 2303.11366) — Actor/Evaluator/Self-Reflection, episodic memory buffer, +11pp HumanEval, feedback verbal sem weight update.
[9] Park et al., *Generative Agents: Interactive Simulacra of Human Behavior* (arXiv 2304.03442) — memory stream + reflection + planning, persona como ativador de comportamento crível, ablation confirma cada pilar é crítico.
[10] Andrew Ng, *Agentic Design Patterns* (deeplearning.ai/the-batch) — quatro padrões (reflection, tool use, planning, multi-agent), insight central: GPT-3.5 em loop agêntico (95.1% HumanEval) > GPT-4 zero-shot (67%).
[11] OpenAI, *Agents SDK* (openai.github.io/openai-agents-python) — três primitivos (agents, handoffs, guardrails), Runner loop, tracing built-in, Python-first sem abstrações pesadas.
