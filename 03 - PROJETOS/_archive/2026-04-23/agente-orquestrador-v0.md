---
title: Agente Orquestrador — pacote externo v0
date: 2026-04-19
source: C:\Users\docto\Downloads\agente_orquestrador_doctor_auto\agente_orquestrador\
status: referência — extrair ideias, não adotar literal
next_step: implementar orquestrador como camada entre Kommo webhook e Ana (próxima sessão)
tags: [dap4, arquitetura, orquestrador, ia, guardrails]
---

# Agente Orquestrador — Doctor Auto Prime

Consolidação dos 10 MDs originais recebidos em 2026-04-19 pra análise e decisão de adoção.

## Contexto da recepção

Thales recebeu esse pacote (provável origem: sessão ChatGPT) e compartilhou na sessão de consolidação pós kill-switch (handoff `handoff-2026-04-19-2200-dap4-sennin-consolidacao.md`). Foi avaliado como resposta **arquitetural** ao problema que causou o kill-switch (Ana quase passou preço).

**Decisão tomada:** adotar a ideia central (camada orquestradora antes da Ana + briefing estruturado) mas não adotar os 10 MDs literais — vários são genéricos demais. Extrair 4 peças fundamentais:

1. Briefing estruturado 6 campos como contrato entre orquestrador e Ana
2. Regra "banco antes de RAG" no pipeline
3. Catálogo de gatilhos (seção 8) como seed de crons proativos
4. Princípio "orquestrador não fala com cliente, Ana não decide o que consultar"

**Integração com Sennin Protocol:** não conflita. O orquestrador do pacote = camada **tática** (por conversa). Sophia (0613-B) + Anna CSO continuam no nível **estratégico** (visão macro, decisões cross-channel). Escopos diferentes.

---

## 1. Visão Geral (original)

### Objetivo
Criar uma camada de decisão entre dados, conhecimento e execução.

O agente orquestrador não atende o cliente diretamente. Ele decide:
- o que consultar
- qual contexto é relevante
- qual agente deve agir
- qual é a próxima ação ideal

### Núcleos conectados
1. **Banco estruturado** — clientes, veículos, leads, orçamentos, OS, campanhas
2. **RAG operacional** — scripts, objeções, serviços, playbook de vendas
3. **RAG de estudos** — manuais, procedimentos, tendências, conteúdo de mercado, trilha de conhecimento
4. **Agentes especialistas** — Ana (vendas), agente de estudos, futuro agente técnico, futuro agente de conteúdo

### Resultado esperado
Dados → contexto → decisão → ação → aprendizado.

---

## 2. Papel do Agente Orquestrador

### Funções principais

**Ler o contexto**
- identificar se o contato é novo ou recorrente
- identificar etapa do funil
- identificar temperatura do lead
- identificar histórico de objeções
- identificar oportunidades de upsell, reativação ou retenção

**Decidir qual base consultar**
- se a necessidade é comercial → RAG operacional
- se a necessidade é técnica ou de mercado → RAG de estudos
- se a necessidade é factual → banco estruturado

**Montar briefing para a Ana**
- resumo do cliente
- resumo do carro
- objetivo da conversa
- riscos comerciais
- melhor abordagem
- próximo passo recomendado

**Aprender com o resultado**
- registrar se houve resposta
- registrar se houve avanço de etapa
- registrar objeções
- registrar padrão relevante

### O que ele NÃO faz
- não fala como atendente final
- não inventa dado ausente
- não mistura material de estudo pesado sem necessidade
- não joga contexto demais para a Ana

---

## 3. Fluxos entre Agentes

### Fluxo 1 — Atendimento comercial
1. mensagem do cliente entra
2. orquestrador consulta banco estruturado
3. classifica cliente, etapa e temperatura
4. consulta RAG operacional para linguagem e argumento
5. monta briefing
6. Ana responde
7. resultado volta para CRM

### Fluxo 2 — Atualização de inteligência comercial
1. agente de estudos monitora materiais, mercado e padrões
2. gera síntese útil
3. orquestrador avalia relevância
4. se útil para venda → atualiza playbook / scripts
5. se útil para operação → envia para trilha técnica
6. se útil para conteúdo → envia para backlog editorial

### Fluxo 3 — Reativação
1. banco marca cliente inativo
2. orquestrador segmenta por motivo, histórico e potencial
3. consulta RAG operacional para abordagem correta
4. Ana executa contato
5. resposta e conversão retornam ao sistema

### Fluxo 4 — Demanda técnica
1. cliente relata sintoma
2. orquestrador consulta banco e histórico do carro
3. se necessário, consulta RAG de estudos
4. gera explicação simples para a Ana
5. Ana conduz para avaliação, orçamento ou agendamento

---

## 4. Regras de Decisão

- **Regra 1 — Banco antes de RAG.** Sempre consultar primeiro o banco estruturado para fatos objetivos.
- **Regra 2 — Comercial primeiro.** Se o objetivo for resposta ao cliente, priorizar contexto comercial e clareza.
- **Regra 3 — Estudo só quando agrega.** O RAG de estudos só entra se ele realmente melhorar decisão, explicação ou posicionamento.
- **Regra 4 — Próxima ação obrigatória.** Toda decisão precisa apontar um próximo passo: coletar informação, enviar orçamento, agendar, fazer follow-up, reativar, escalar para humano.
- **Regra 5 — Resumo curto para a Ana.** A Ana deve receber um briefing simples: quem é, o que quer, em que etapa está, qual risco existe, o que falar, para onde conduzir.
- **Regra 6 — Feedback fecha o ciclo.** Toda saída precisa registrar: houve resposta? houve avanço? houve objeção? houve perda?

---

## 5. Prompt Base — Agente Orquestrador

```
Você é o agente orquestrador da Doctor Auto Prime.

Sua função é conectar banco estruturado, RAG operacional, RAG de estudos e agentes especialistas.
Você não atende o cliente diretamente. Você interpreta contexto, decide quais fontes consultar e gera um briefing objetivo para o agente correto agir.

## Prioridades
1. entender o objetivo da interação
2. recuperar fatos reais do banco estruturado
3. consultar apenas a base necessária
4. resumir contexto de forma clara e curta
5. indicar a próxima ação ideal
6. registrar o resultado esperado

## Ordem de consulta
- primeiro: banco estruturado
- segundo: RAG operacional, se a demanda for comercial
- terceiro: RAG de estudos, se a demanda exigir técnica, mercado, tendência ou aprofundamento

## Saída obrigatória

### Resumo do contexto
- cliente:
- veículo:
- etapa do funil:
- temperatura:
- histórico relevante:

### Objetivo da interação
-

### Fontes consultadas
- banco estruturado
- rag operacional
- rag estudos

### Melhor abordagem
-

### Próxima ação recomendada
-

### Dados a registrar depois
-

Nunca invente dados ausentes. Se faltar informação crítica, indique exatamente o que precisa ser coletado.
```

---

## 6. Prompt Base — Ana Contextualizada

```
Você é Ana, analista de vendas da Doctor Auto Prime.

Você receberá um briefing do agente orquestrador com contexto resumido do cliente, do veículo, do histórico e da melhor abordagem comercial.
Seu trabalho é transformar esse briefing em uma resposta humana, clara, consultiva e orientada ao próximo passo.

## Regras
- fale como uma pessoa real no WhatsApp
- seja simpática, natural e segura
- não seja burocrática
- não use linguagem de call center
- não invente fatos
- adapte a resposta ao perfil do cliente
- sempre conduza a conversa para o próximo passo

## Estrutura da resposta
1. acolha
2. mostre que entendeu
3. oriente com clareza
4. conduza para o próximo passo

## Prioridade comercial
Seu foco é transformar a conversa em:
- coleta de dados qualificados
- orçamento
- agendamento
- fechamento
- reativação
```

---

## 7. Prompt Base — Agente de Estudos Curador

```
Você é o agente de estudos da Doctor Auto Prime.

Sua função é estudar materiais técnicos, tendências de mercado, conteúdos externos, manuais, transcrições e padrões internos para gerar inteligência útil.

## Foco
- resumir conhecimento
- detectar padrões
- apontar tendências
- sugerir temas de treinamento
- sugerir temas de conteúdo
- sugerir oportunidades comerciais

## Regra central
Você não atende cliente final. Você produz inteligência para o orquestrador decidir o que fazer com esse conhecimento.

## Saída ideal
- resumo executivo
- o que mudou / o que importa
- impacto comercial
- impacto técnico
- ação sugerida
- destino da informação (Ana / time técnico / blog / gestão)
```

---

## 8. Eventos e Gatilhos

### Comerciais
- novo lead entrou
- lead sem resposta 24h
- orçamento enviado
- orçamento parado 72h
- cliente sumido 90 dias
- lead quente sem avanço

### Técnicos
- falha recorrente identificada
- novo procedimento validado
- padrão de problema por modelo

### Conteúdo e mercado
- nova tendência relevante
- aumento de demanda por tema específico
- concorrente reforçando oferta específica

### Ações possíveis
- acionar Ana
- atualizar playbook
- enviar para trilha técnica
- abrir campanha
- criar tarefa de conteúdo
- alertar gestão

---

## 9. Backlog de Implantação (original)

**Fase 1 — MVP**
- estruturar banco de clientes, veículos, leads e histórico
- organizar RAG operacional
- configurar prompt da Ana
- criar lógica simples do orquestrador

**Fase 2 — Inteligência**
- conectar RAG de estudos
- registrar sínteses recorrentes
- criar rotina de atualização de playbook

**Fase 3 — Multiagentes**
- separar agente de estudos
- separar agente técnico
- separar agente de conteúdo
- consolidar papel do orquestrador

**Fase 4 — Governança**
- criar métricas por agente
- registrar decisões boas e ruins
- definir critérios para escalar para humano

---

## Plano de integração com DAP4 (decidido 2026-04-19)

### Arquitetura alvo

```
Kommo webhook → anna-inbox.worker.ts → [ORQUESTRADOR NOVO] → briefing JSON → Ana → resposta → Kommo
                                                ↓
                                    consulta Supabase (crm_leads + ai_conversations)
                                    consulta ops_* RAG
                                    (consulta study_* só se necessário)
```

### Arquivos a criar

- `agents/agents/orchestrator.py` — novo módulo Python rodando antes de `ana.py`
- `agents/config/prompts/orchestrator.yaml` — system prompt do orquestrador
- `gateway/src/workers/anna-inbox.worker.ts` — inserir chamada ao orquestrador antes do LLM da Ana

### Contrato de saída do orquestrador

JSON com 6 campos (mapeado do doc 5 original):

```json
{
  "contexto": {
    "cliente": "string | null",
    "veiculo": "string | null",
    "etapa_funil": "novo | em_qualificacao | orcamento_enviado | agendado | cliente | inativo",
    "temperatura": "frio | morno | quente | vip",
    "historico_relevante": "string"
  },
  "objetivo": "string",
  "fontes_consultadas": ["banco", "ops_rag", "study_rag"],
  "melhor_abordagem": "string",
  "proxima_acao": "coletar_info | enviar_orcamento | agendar | follow_up | reativar | escalar_humano",
  "dados_a_registrar": ["string"]
}
```

**Regra arquitetural de guardrail:** o briefing **nunca** inclui preço, garantia ou prazo firme. Ana fisicamente não tem esses dados no contexto, então não pode vazar.

### Gatilhos da seção 8 → tab Crons do Parliament

Mapear direto pro schema `parliament_crons` do blueprint já pronto:

| Evento | Schedule proposto | Ação |
|---|---|---|
| lead sem resposta 24h | `0 */6 * * *` | orquestrador aciona Ana com prompt follow-up |
| orçamento parado 72h | `0 10 * * *` | orquestrador aciona Ana com prompt reativação orçamento |
| cliente sumido 90 dias | `0 11 * * 1` (segundas) | orquestrador aciona Ana com prompt reativação |
| novo lead | trigger (não cron) | já existe via webhook |
| lead quente sem avanço | `0 14 * * *` | orquestrador escala pro humano |

### Sequência de execução

**Sessão N (guardrails):** fechar `guardrails-ana-v0-rascunho.md` com Thales. Religar IAs com prompt-level guardrail.

**Sessão N+1 (orquestrador core, ~3h):**
1. criar `orchestrator.py` + `orchestrator.yaml`
2. patchar `anna-inbox.worker.ts` pra chamar orquestrador primeiro
3. `ana.py` passa a receber briefing como `system_context`
4. smoke test com 3 conversas mock
5. ativar em Bosch primeiro (Prime depende do pipeline_id)

**Sessão N+2 (crons proativos, ~2h):**
1. implementar Parliament backend (blueprint pronto)
2. popular `parliament_crons` com os 5 gatilhos da tabela acima
3. executor de crons chama orquestrador com `trigger_type` específico

**Sessão N+3 (curador de estudos, ~2h):**
1. `agents/agents/curator.py` — lê novos docs ingeridos no ChromaDB
2. roda weekly, gera síntese em `ops_playbook_sinteses`
3. orquestrador passa a consumir essas sínteses nos briefings

---

## O que foi rejeitado do pacote original

- **Estruturas de prompt genéricas demais** (doc 6 "fale como pessoa real no WhatsApp") — o `ana.yaml` atual é mais específico. O prompt do orquestrador da nova Ana contextualizada vai ser um merge dos dois, não substituição.
- **Arquitetura "4 agentes separados" como fim em si** — DAP4 já tem Sennin (12 diretores). Orquestrador aqui é **função tática**, não mais uma persona no Sennin. Não vira diretor.
- **Fases 1-2 do backlog** — já estão feitas no DAP4. Começamos da Fase 3 (separar agente de estudos) com modificações.

---

**Próximo passo consolidado:** implementar orquestrador conforme seção "Plano de integração" acima, em paralelo com guardrails v1 finalizado.
