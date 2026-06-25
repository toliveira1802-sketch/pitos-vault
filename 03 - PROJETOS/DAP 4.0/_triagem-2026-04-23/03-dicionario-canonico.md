---
title: Dicionário Canônico DAP 4.0 — Um Nome por Coisa
date: 2026-04-23
autor: Claudin (Sennin Protocol)
status: v1 — regra oficial
escopo: vocabulário DAP 4.0 (negócio + stack + agentes + dados)
fonte_verdade: este arquivo
override_prioridade: este arquivo > qualquer doc legado / código / conversa anterior
tags: [dicionario, nomenclatura, governanca, sennin, dap4]
---

# Dicionário Canônico DAP 4.0

Regra de ouro: **uma entidade = um nome oficial**. Tudo mais é sinônimo banido.
Se um doc antigo, um prompt ou um campo de código usa sinônimo banido, **migrar**. Se não der pra migrar agora, registrar em `_triagem-2026-04-23/dividas-nomenclatura.md`.

Fonte canônica do ecossistema: `PITOS/Sistemas/sennin-protocol.md` + `PITOS/Sistemas/sennin-c-level-map.md`.

---

## 1. Camada de agentes

### 1.1 Sophia

- **Nome oficial:** `Sophia`
- **O que é:** presidência simbólica/externa do Parliament. Router + orquestradora de topo. Modelo claude-sonnet-4-5-20250929 (codename interno: `0613-B`). Fala em nome do ecossistema quando o canal é externo (página `/sophia`, emails institucionais, voz de marca C-level).
- **O que NÃO é:** não é agente de WhatsApp, não atende lead, não é página, não é projeto Vercel, não é o app.
- **Onde mora:** `C:\dev\dap4\agents\parliament\sophia\` (prompt + runtime). UI de supervisão: `https://dap.doctorautoprime40.com/sophia` (Sophia Hub).
- **Sinônimos banidos:** "Athena", "IA Mãe", "0613-B" (codename só em docs técnicos internos), "Sophia orquestradora", "Sophia CEO".
- **Escalação legado:** ref `escalar_para_sophia` em código herdado = escalação pro Parliament (router), **não** pra uma pessoa. Renomear gradualmente pra `escalate_to_parliament`.

### 1.2 Sophia Hub

- **Nome oficial:** `Sophia Hub` (UI, não entidade)
- **O que é:** cockpit web em `/sophia` dentro do app DAP4 prod. 3 colunas, live, 11KB gzip, commit bfd5be9.
- **O que NÃO é:** não é projeto Vercel separado (morto), não é SaaS, não é agente.
- **Onde mora:** rota `/sophia` do dashboard em `C:\dev\dap4\dashboard\`. Servida via `dap.doctorautoprime40.com/sophia`.
- **Sinônimos banidos:** "Sophia Hub Vercel", "Hub da Sophia", "projeto Sophia Hub".

### 1.3 Anna

- **Nome oficial (agente Parliament):** `Anna`
- **Cargo:** CSO · Sales. 1 das 13 diretoras Parliament.
- **O que é:** diretora comercial no plano estratégico. Dona de guardrails, RTBM, scoring de lead, playbook de vendas.
- **Onde mora:** `C:\dev\dap4\agents\parliament\anna\`. Guardrails: `PITOS/DAP 4.0/Frameworks Operacionais/anna-guardrails.md`.
- **Sinônimos banidos:** "Ana CSO" (ambíguo com subagente), "Ana comercial", "IA vendedora", "agente de vendas".

### 1.4 Ana (WhatsApp)

- **Nome oficial (subagente operacional):** `Ana`
- **O que é:** bot Python que atende WhatsApp Cloud API (+5511917001822 Prime). Subagente operacional de Anna. Roda em FastAPI dentro do stack `/opt/doctor-auto-ai/`. Responde lead, classifica carro, escala pro +5511967291822 Thales.
- **O que NÃO é:** não decide estratégia, não é Anna, não fala em nome da marca fora do WhatsApp.
- **Onde mora:** `C:\dev\dap4\agents\ana\` + VPS `76.13.170.42`.
- **Sinônimos banidos:** "Anna WhatsApp", "Anna bot", "IA do zap", "agente WhatsApp", grafia `Anna` em código Python da camada operacional.
- **Regra de grafia:** **`Anna` = diretora Parliament. `Ana` = bot WhatsApp.** Duas letras, dois escopos. Migrar qualquer código que use `Anna` pro bot Python → `Ana`. Migrar qualquer doc que use `Ana` pra diretora → `Anna`.

### 1.5 Parliament

- **Nome oficial:** `Parliament`
- **O que é:** sistema multi-agente de 13 diretores Sennin rodando in-place em `C:\dev\dap4\agents\parliament\`. Orbital visual: `/parliament`. Presidência: Sophia. 2 CSOs: Anna (Sales) + Chapapiuro (Strategy). 11 demais: Bianca, Francisco, Marta, Rafael, Claudio, Thamy, Zoraide, Walter, Pitoco, Marcia.
- **O que NÃO é:** não é startup, não é SaaS, não é produto externo, não é "Exército de IAs" (nome banido), não é "Sala do Conselho Dify" (blueprint Dify alternativo, NÃO adotado em prod).
- **Onde mora:** `C:\dev\dap4\agents\parliament\`. Config multi-tenant: `config/tenants/dap.yaml`. 5 vozes com prompt real: Sophia/Anna AGENT, Francisco/Pitoco/Zoraide SKILL. 8 demais: stubs.
- **Sinônimos banidos:** "Exército de IAs", "Exército", "Sala do Conselho" (é outra coisa, ver 1.6), "time de IAs", "conselho de IAs", "15 IAs com emoji".

### 1.6 Sala do Conselho Dify

- **Nome oficial:** `Sala do Conselho Dify` (blueprint, não sistema ativo)
- **O que é:** blueprint alternativo de implementação do Parliament em Dify. Registrado em `PITOS/Sistemas/sala-do-conselho-dify-dap4.md` (2026-04-19). **Complementa**, não substitui, o Parliament in-code. Referência conceitual.
- **O que NÃO é:** não é sistema rodando, não é Parliament, não é adotado em prod.
- **Onde mora:** só no vault.
- **Sinônimos banidos:** usar "Sala do Conselho" sem o qualificador "Dify" quando o contexto for implementação ativa.

### 1.7 Kimi

- **Nome oficial:** `Kimi`
- **O que é:** subagente operacional de Rafael (COO). Faz sync CRM (Kommo ↔ Supabase). Bot Python.
- **Onde mora:** `C:\dev\dap4\agents\kimi\`.
- **Sinônimos banidos:** "bot CRM", "sync agent".

### 1.8 Insights

- **Nome oficial:** `Insights`
- **O que é:** subagente operacional de Walter (CKO). Faz analytics + relatórios RAG.
- **Onde mora:** `C:\dev\dap4\agents\insights\`.
- **Sinônimos banidos:** "agente analytics", "Sofia" (nome legado — era stub, foi descartado).

---

## 2. Camada de dados

### 2.1 Supabase

- **Nome oficial:** `Supabase`
- **O que é:** único banco transacional de verdade do DAP4.0. Postgres gerenciado. 27 tabelas, 5.911 leads. Fonte de verdade pra `crm_leads`, `llm_usage`, `anna_inbox` (sic — nome de tabela legado), RLS por tenant.
- **O que NÃO é:** não é CRM de usuário final, não é Kommo, não é "lago", não é data warehouse.
- **Onde mora:** acesso via MCP Supabase e env `SUPABASE_URL`/`SUPABASE_SERVICE_KEY`.
- **Sinônimos banidos:** "banco DAP", "DB interno", "Lago", "CRM interno" (ambíguo — ver 2.3).

### 2.2 Kommo

- **Nome oficial:** `Kommo`
- **O que é:** CRM SaaS externo (pipelines Bosch=12704980 + Prime). Sistema de registro comercial do atendimento. Fonte de verdade pra movimentação de stage, cards, mensagens WhatsApp.
- **O que NÃO é:** não é banco transacional do DAP4, não é fonte de verdade pra scoring (quem pontua é Anna/Ana), não é o sistema interno.
- **Onde mora:** `kommo.com` (SaaS). Token em `.env` DAP4. Webhook: `meta-webhook` → gateway Node.
- **Sinônimos banidos:** "CRM" sozinho (ambíguo), "CRM externo" (usar `Kommo` direto), "pipeline de venda" (impreciso).

### 2.3 Vocabulário CRM — resolvido

Quando Thales fala "CRM", pergunta-se: **qual camada?**

| Termo na conversa | Canônico | O que é |
|---|---|---|
| "CRM" (sem qualificador) | **proibido** | Ambíguo. Sempre qualificar. |
| "CRM externo" / "Kommo" | `Kommo` | SaaS externo, registro comercial |
| "CRM interno" / "Lago" | `Supabase` + `crm_leads` | Tabela + banco DAP4 |
| "Lago de dados" / "Data Lake" | **proibido** | DAP4 não tem lago. Tem Postgres (Supabase) + ChromaDB (RAG). |
| "Sistema interno" | `DAP4` ou nomear o componente | Sempre nomear: gateway, dashboard, agents, etc. |

### 2.4 ChromaDB

- **Nome oficial:** `ChromaDB`
- **O que é:** vector store do RAG DAP4. Coleções com prefixo `ops_*` (operacional) e `studies_*` (conhecimento). Hoje `ops_crm_insights` está **vazio em prod** (gargalo conhecido — task #28).
- **Onde mora:** container Docker em `/opt/doctor-auto-ai/chromadb/`.
- **Sinônimos banidos:** "vector DB", "RAG" (RAG é o sistema, não o banco).

### 2.5 RAG

- **Nome oficial:** `RAG`
- **O que é:** pipeline retrieval (ChromaDB) + augmentation (prompt assembly) + generation (LLM). Dois domínios: `ops_*` (scripts, objeções, playbooks, SOP — consumido por Ana/Anna) e `studies_*` (manuais técnicos, tendências — consumido por Walter/Insights).
- **O que NÃO é:** não é ChromaDB isolado, não é Supabase, não é fonte de verdade transacional.
- **Sinônimos banidos:** "base de conhecimento", "KB" (sem qualificador).

---

## 3. Camada de infra

### 3.1 Stack DAP4

- **Nome oficial:** `stack DAP4`
- **O que é:** conjunto rodando em VPS Hostinger `76.13.170.42`: Node gateway (Express 5/TS) + Python agents (FastAPI 3.12) + ChromaDB + Caddy reverse proxy + Cloudflare Tunnel `dap4`. Supabase é externo (gerenciado), Kommo é externo (SaaS).
- **Onde mora:** `/opt/doctor-auto-ai/` na VPS.
- **Sinônimos banidos:** "servidor", "backend" (ambíguo), "API" (ambíguo).

### 3.2 Gateway

- **Nome oficial:** `gateway`
- **O que é:** Node Express 5/TS. Recebe webhooks (Kommo, Meta), enfileira, chama Python agents com Bearer auth obrigatório, grava em Supabase.
- **Onde mora:** `C:\dev\dap4\gateway\` + `/opt/doctor-auto-ai/gateway/` na VPS.

### 3.3 Domínio

- **Nome oficial:** `dap.doctorautoprime40.com`
- **O que é:** host público do app DAP4. Rota-mãe: `/`. Rotas: `/sophia`, `/parliament`, `/leads`, `/agents`.

---

## 4. Camada de negócio

### 4.1 Ecossistema

- **Nome oficial:** `DAP 4.0` ou `ecossistema DAP 4.0`
- **O que é:** holding de 12 unidades de negócio (Prime, Performance, Project, AI, Dev, Studio, Social, Ensina, Consultoria, Mulher, Estética, Funilaria).
- **Sinônimos banidos:** "DAP" sozinho quando se refere ao ecossistema (ambíguo com Prime), "Doctor Auto" (nome antigo), "Doctor Auto Prime" (é 1 unidade, não o todo).

### 4.2 Doctor Auto Prime

- **Nome oficial:** `DAP Prime`
- **O que é:** unidade operacional de manutenção premium (alemães). A oficina física.
- **O que NÃO é:** não é o ecossistema.
- **Sinônimos banidos:** "Doctor Auto", "a oficina" (informal, ok só em conversa).

---

## 5. Legado cinza — migração gradual

| Aparece como | Canônico | Ação |
|---|---|---|
| `escalar_para_sophia` em código | `escalate_to_parliament` | Renomear em refactor; manter alias 30d |
| `Anna` em código Python do bot WhatsApp | `Ana` | Renomear ao encostar no arquivo |
| `Ana` em docs de diretora Parliament | `Anna` | Corrigir on-sight |
| "Sofia" (subagente analytics legado) | `Insights` | Descartado; se aparecer, remover |
| "Athena" / "IA Mãe" | `Sophia` | Descartado; remover citação |
| "Exército de IAs" | `Parliament` | Remover on-sight |
| "Sala do Conselho" (sem "Dify") em prod | `Parliament` | Qualificar com "Dify" se for blueprint |
| "CRM" sozinho | `Kommo` ou `Supabase/crm_leads` | Sempre qualificar |
| "Lago" / "Data Lake" | `Supabase` ou `ChromaDB` | Nunca usar "lago" no DAP4 |

---

## 6. Regra de uso

1. Em qualquer doc novo em `PITOS/DAP 4.0/`, `C:\dev\dap4\`, ou commit message — **só canônico**.
2. Em código: renomear ao encostar no arquivo (boyscout rule). Não abrir PR só pra renomear — fazer junto com mudança funcional.
3. Em conversa com Thales: se Thales usa sinônimo banido, responder com canônico e seguir. Sem sermão.
4. Ao criar nova entidade (agente, subagente, página, tabela, rota): escolher nome que **não colida** com nenhum acima. Se colidir, qualificar desde o dia 1.
5. Esse dicionário é vivo: se uma entidade muda de escopo, atualizar aqui primeiro, depois no resto.

---

*Dicionário Canônico DAP 4.0 · v1 · 2026-04-23*
*"Um nome, uma coisa. O resto é ruído."*
