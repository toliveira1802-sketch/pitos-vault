---
title: QA — DAP 4.0 frontend validation
date: 2026-04-19
session: claude-opus-4-7-1m
bundle: index-DnEazAWO.js
url: https://dap.doctorautoprime40.com
status: pending
owner: Thales
duration_estimate: 20min
tags: [dap4, qa, frontend, sessao-2026-04-19]
---

# QA · DAP 4.0 frontend validation

Roteiro de testes da sessão 2026-04-19 — 9 telas reformuladas + 4 redirects.

**Bundle no ar:** `index-DnEazAWO.js`
**URL:** https://dap.doctorautoprime40.com
**Duração estimada:** 20 min

## Como usar este doc

- Marque `[x]` em cada item que passou
- Se algo vier diferente do esperado, anote na seção "Red flags" no fim
- `⚠️` = gap conhecido, NÃO é bug — é aguardando backend/humano
- Ao final, registre impressão geral em "Notas do Thales"

---

## 1. Smoke de navegação (30 s)

URL base: `https://dap.doctorautoprime40.com`

- [ ] Sidebar carrega com 3 grupos
  - [ ] Overview: Pulse · Operação · Leads (3 itens)
  - [ ] Intelligence: Sophia Hub · Parliament · Vault · Cérebro (4 itens)
  - [ ] Operations: WhatsApp · Logs (2 itens)
- [ ] Logo "DAP 4.0 · Command Center" visível no topo
- [ ] Redirects das rotas antigas funcionam:
  - [ ] `/agents` → `/parliament`
  - [ ] `/ai-lab` → `/parliament`
  - [ ] `/ingestion` → `/rag?mode=ingest`
  - [ ] `/whatsapp-meta` → `/whatsapp?channel=meta`
- [ ] Sidebar colapsa/expande (botão Collapse inferior)

## 2. Pulse (`/dashboard`) · 1 min

Nova home — radar macro do stack.

- [ ] 4 KPI cards no topo mostram números reais:
  - [ ] Conversas em andamento ≈ 13
  - [ ] Novos leads hoje = 0
  - [ ] Taxa de conversão = 0.00% (com caption "0 OS / 5.911 leads")
  - [ ] Agentes ativos = 5 / 5 online
- [ ] Seção "Quem está ativo" com 5 cards de agentes:
  - [ ] 0613-B, Ana, Kimi, Thales, Insights — todos com dot colorido
  - [ ] Ana mostra contador de ações (~12) e horário da última
- [ ] Classificação de leads (bar horizontal): Hot 3 · Warm 4 · Cold 2 · Não classificados 5.902
- [ ] Alerta amarelo "5.902 leads sem classificação"
- [ ] Feed "Atividade recente" com eventos da Ana (Lead classificado → DUVIDA/OUTRO)

## 3. Leads · 2 min

Tabela paginada + bloco Kommo.

- [ ] Bloco **KOMMO · CRM central** no topo:
  - [ ] 2 cards de marca (Bosch vermelho, Prime dourado) — ambos "nenhum" ⚠️
  - [ ] 4 cards de canal (WhatsApp, Facebook, Instagram, TikTok) — todos "nenhum" ⚠️
  - [ ] Alerta amarelo "Integração Kommo ainda não mapeia marca nem canal"
- [ ] Clicar num card ativa filtro visual (border acende)
- [ ] "limpar filtros" aparece quando algum ativo
- [ ] Tabela abaixo com 100 leads:
  - [ ] Colunas: Nome+telefone, Veículo, Fonte, Classificação, Score, Última Atividade
  - [ ] Classificação "frio" em quase todos
  - [ ] Clicar numa linha navega pra `/whatsapp?phone=...`
- [ ] Filtros de status (Todos / Novos / Ativos / Hot / Vacuum / Stale / Won / Lost) funcionam

## 4. Cérebro (`/rag`) · 5 min · **TESTE MAIS IMPORTANTE**

Biblioteca viva (RAG + ingestão consolidados).

- [ ] Header "Cérebro — Biblioteca viva do DAP 4.0"
- [ ] Stats no header: `0 docs · 7 coleções · 0/7 saudáveis`
- [ ] Layout 3 colunas:
  - [ ] Esquerda: Coleções agrupadas STUDY (4) + OPS (3), todas com dot vermelho
  - [ ] Centro: 3 tabs (Explorar · Alimentar · Histórico)
  - [ ] Direita: ContextPanel com stats globais
- [ ] Abre direto em modo **Alimentar** (auto-detect porque vazio)
- [ ] Clicar numa coleção à esquerda:
  - [ ] ContextPanel direito atualiza com nome + type + 0 docs
  - [ ] Botão "Ingerir nesta coleção" aparece
- [ ] Hover numa coleção mostra botão "+"
- [ ] **Teste real de ingestão:**
  - [ ] Modo Alimentar → fonte Arquivo
  - [ ] Arrastar 1 PDF pequeno (<5MB) pro drop zone
  - [ ] Clicar "Ingerir 1 arquivo"
  - [ ] Esperar progresso → ver "Ingerido" verde ✅ OU "Falhou" vermelho 🔴
  - [ ] Se OK: ver contador da coleção ir de 0 → N
  - [ ] Se erro: anotar o erro na seção Red flags
- [ ] Modo Explorar → query "BMW" → sempre retorna `[]` até ter conteúdo
- [ ] Modo Histórico → lista 20 ingestões passadas do vault Obsidian

## 5. Operação (`/command-center`) · 2 min

Pipeline comercial live.

- [ ] Header "Operação — Pipeline comercial ao vivo · Bosch & Prime"
- [ ] Badge LIVE verde (socket.io conectado)
- [ ] Toggle Ambas / Bosch / Prime
- [ ] Tab "Dashboard":
  - [ ] KPIs: Temperatura, Na fila, Resp. média, Conversão
  - [ ] Pipeline funnel (Novo → Esperando → Em Atendimento → Qualificado → OS Gerada)
  - [ ] Lista "Fila vazia" ou leads em espera
  - [ ] Before/After IA × Manual
- [ ] Tab "Conversas" → inbox live (pode estar vazio)
- [ ] Clicar num lead abre context card lateral

## 6. WhatsApp (`/whatsapp`) · 2 min

Inbox Kommo + Meta com toggle.

- [ ] Header "WhatsApp — Inbox multi-canal"
- [ ] Toggle Kommo / Meta / Ambos no header direito
- [ ] **Kommo:** inbox normal (conversas ou vazio)
- [ ] **Meta:** tela "Meta Cloud API não configurado" com explicação ⚠️
- [ ] **Ambos:** volta ao inbox normal (Meta virá quando backend)
- [ ] Trocar entre as 3 opções sem quebra
- [ ] ConnectionPill verde (Live) ou amarelo (Reconnecting)

## 7. Parliament · 1 min

Sala do Conselho C-Level.

- [ ] Header "Parliament — Sala do Conselho C-Level"
- [ ] Botões "Tópicos" e "Abrir tópico"
- [ ] Orbital visual:
  - [ ] 0613-B no centro com pulse rings
  - [ ] 8 diretores em órbita (Anna CMO, Cláudio CTO, Chico CFO, Bianca CSO, João COO, Stitch CDO, Llama CGO, Túlio MEC)
- [ ] Painel direito mostra "Sala do Conselho" + alerta "Backend Parliament não montado" ⚠️
- [ ] **Clicar num diretor** (ex: Anna):
  - [ ] Drawer direito acende com cor da persona
  - [ ] Header com ícone + nome + role
  - [ ] 3 tabs: Subagentes · Crons · Skills
  - [ ] Subagentes/Crons: "Aguardando backend" ⚠️
  - [ ] Skills: lista hardcoded (campanhas, copy, audiência, branding)
  - [ ] Botão "Testar" ao lado de cada skill
- [ ] Clicar "Testar" numa skill:
  - [ ] Modal abre com textarea de prompt
  - [ ] Digitar "hi" + Rodar → erro amarelo "Backend de teste de skill ainda não está ligado" ⚠️
  - [ ] Fechar modal (X)
- [ ] Botão "desselecionar" no header do orbital → volta pro empty state

## 8. Vault (`/knowledge`) · 2 min

Second brain + Obsidian.

- [ ] Header "Vault — Obsidian + Pitoco Loco"
- [ ] 4 tabs visíveis: **Chat** · Vault · Daily Note · Search (não tem mais Collections)
- [ ] Tab **Chat** (Pitoco Loco):
  - [ ] Input de mensagem
  - [ ] Digitar "resumo dos projetos DAP"
  - [ ] Aguardar resposta — deve responder consultando Obsidian
- [ ] Tab **Vault** → navegar estrutura de pastas do PITOS
- [ ] Tab **Daily Note** → nota do dia atual
- [ ] Tab **Search** → busca semântica

## 9. Sophia Hub · 1 min · **vai falhar o chat**

Cockpit do 0613-B.

- [ ] Header "Sophia Hub — Cockpit ao vivo do 0613-B"
- [ ] Layout 3 colunas:
  - [ ] VoiceRail esquerda: 5 vozes (0613-B, Ana, Kimi, Thales, Insights) com dots
  - [ ] RAG coleções listadas (todas count 0)
  - [ ] Centro: chat 0613-B com mensagem inicial
  - [ ] Direita: Ações rápidas + Parliament (0 tópicos)
- [ ] **Digitar no chat → erro Anthropic 401** ⚠️ (esperado até rotar key)
- [ ] Clicar Quick Action "Status" → retorna info do stack (não usa Anthropic)
- [ ] Clicar Quick Action "Revisar RAG" → resultado OK ou erro
- [ ] Contador "Ações registradas: 239" no canto direito

## 10. Logs · 1 min

Timeline de eventos.

- [ ] Header "Logs — Atividade do sistema e trilha de auditoria"
- [ ] Botão "Atualizar"
- [ ] Filtros:
  - [ ] Nível: Todos / info / warn / error (com contadores)
  - [ ] Agente: All / Ana / Kimi / 0613-B / Thales / Insights / System
- [ ] Feed com eventos reais OU vazio honesto (sem mock)
- [ ] Clicar numa linha expande detalhes
- [ ] Filtros combinam (nível + agente ao mesmo tempo)

---

## 🚩 Red flags — anote aqui o que apareceu de diferente

### Erros inesperados

<!-- Formato sugerido:
[TELA] <descrição curta>
Console: <copy do erro>
Screenshot: <url/path>
-->

-
-
-

### Comportamentos estranhos (não quebra, mas parece errado)

-
-

---

## Notas do Thales

<!-- Impressão geral, o que gostou, o que não gostou, prioridade de próximos passos -->

-
-
-

---

## Tarefas abertas (dependem de humano)

Pra contexto — o que eu sei que depende de você antes da próxima sessão:

- **[#21]** Kommo webhook → popular `brand_id` + `source_name` no Supabase → acende cards Kommo em Leads
- **[#22]** Parliament backend (schema + rotas directors/subagents/crons/skills) → acende tabs do Parliament
- **[#23]** Meta Cloud API setup manual → libera linha 2 WhatsApp (Ana Prime solo)
- **[#24]** Rotar `ANTHROPIC_API_KEY` (401) → destrava chat Sophia Hub
- **[#25]** Ingerir conteúdo em `ops_*` (pricing / procedures / support) → Ana ganha contexto
- **[#26]** Ana persistir classification em `crm_leads` → 5.902 leads saem do "frio"

---

## Referências

- Handoff desta sessão: pendente (gerar com `/handoff` depois do teste)
- Bundle atual: `index-DnEazAWO.js` (validar em `grep index- /opt/doctor-auto-ai/dashboard/dist/index.html` na VPS)
- Rollback: `git log feat/kommo-prod-rc1` e `git reset --hard <hash>` + redeploy
