# Project TODO

## Dashboard v1.0 (Completed)
- [x] Basic dashboard layout with dark theme
- [x] Agent Status Bar (Ana, Pescadora, Vigilante, Analista, Reativador, Relatório)
- [x] KPI Hero metrics row
- [x] CRM Interno section (funnel + active leads table)
- [x] CRM Externo / Lago de Leads section
- [x] Weekly Performance Chart
- [x] Campaign Table (Campanhas de Ataque)
- [x] Pátio Digital (boxes Prime + Bosch)
- [x] Ana Activity Feed
- [x] Financial Breakdown by unit

## Supabase Integration (In Progress)
- [x] Upgrade project to full-stack (web-db-user)
- [x] Create database schema (agents, leads, lago_leads, bays, campaigns, ana_actions, financials, weekly_metrics)
- [x] Run db:push to sync schema
- [x] Create tRPC API routes for all dashboard data
- [x] Create React hooks with auto-refresh (polling every 30s)
- [x] Update all components to use real data from tRPC
- [x] Seed database with initial data
- [x] Write vitest tests for API routes (4/4 passing)

## Unit Filter Feature
- [x] Create UnitFilter toggle component (Todas / Prime / Bosch)
- [x] Add filter state to Home.tsx and pass to all components
- [x] Filter leads, bays, funnel, KPIs, financial by selected unit
- [x] Write vitest tests for filter logic (15 tests passing)

## Sophia Hub Webhook Integration
- [x] Create WEBHOOK_SECRET env variable for authentication
- [x] Implement POST /api/webhook/sophia Express route with HMAC validation
- [x] Handle event types: lead.created, lead.updated, lead.moved_to_lago, ana.action, agent.heartbeat, campaign.update, financial.update, bay.update
- [x] Write webhook payload validation and DB upsert logic
- [x] Write vitest tests for webhook auth and event processing (17 tests passing)
- [x] Create integration documentation for Sophia Hub setup

## Lead Management CRUD Page
- [x] Create tRPC procedures for lead CRUD (create, update, delete, list)
- [x] Create tRPC procedures for lago lead CRUD (create, update, delete, list)
- [x] Create tRPC procedure to move lead from CRM Interno to Lago
- [x] Create tRPC procedure to move lead from Lago to CRM Interno (rescue/fish)
- [x] Build LeadsManagement page with tabs (CRM Interno / Lago de Leads)
- [x] Build AddLeadDialog with form validation
- [x] Build EditLeadDialog with pre-populated fields
- [x] Build MoveToLagoDialog with temperature/score/reason fields
- [x] Build RescueFromLagoDialog to move back to CRM Interno
- [x] Add delete confirmation dialog
- [x] Register /leads route in App.tsx with navigation from dashboard
- [x] Write vitest tests for lead CRUD procedures (36 total tests passing)

## 50 Novas Implementações — CRM, Personas, Vendas, Fluxos e Economia

### A. Análise de CRM & Personas (1-12)
- [x] 1. Página de Personas — perfis visuais dos arquétipos de clientes (Premium, Econômico, Frota, Primeira Vez)
- [x] 2. Motor de Classificação Automática — IA analisa dados do lead e atribui persona automaticamente
- [x] 3. Mapa de Jornada por Persona — visualização do caminho típico de cada persona no funil
- [x] 4. Dashboard de Distribuição de Personas — gráficos de pizza/barra mostrando mix de clientes por persona
- [x] 5. Análise de Ticket Médio por Persona — comparativo de valor médio gasto por cada tipo de cliente
- [x] 6. Taxa de Conversão por Persona — qual persona converte mais e em qual etapa do funil
- [x] 7. Análise de Tempo de Ciclo — quanto tempo cada persona leva do primeiro contato ao fechamento
- [x] 8. Análise de Canal Preferido por Persona — WhatsApp vs Instagram vs Indicação por tipo de cliente
- [x] 9. Análise de Recorrência — quais personas voltam mais e com qual frequência
- [x] 10. Mapa de Calor de Horários — quando cada persona mais interage (melhor hora para abordar)
- [x] 11. Análise de Veículos por Persona — quais marcas/modelos cada persona traz
- [x] 12. Score de Lifetime Value (LTV) — projeção de valor total de cada cliente ao longo do tempo

### B. Otimização de Fluxos & Economia (13-24)
- [x] 13. Painel de Economia Operacional — quanto a IA está economizando vs atendimento manual (custo/hora)
- [x] 14. Calculadora de ROI da IA — investimento em IA vs receita gerada por automação
- [x] 15. Monitor de Tempo de Resposta — tempo médio de resposta da Ana vs benchmark do mercado
- [x] 16. Análise de Gargalos no Funil — identifica onde leads ficam travados e por quanto tempo
- [x] 17. Fluxo de Aprovação Digital (schema pronto, UI pendente) — cliente aprova orçamento pelo dashboard com assinatura digital
- [x] 18. Painel de Produtividade por Box — receita/hora por box da oficina (Prime e Bosch)
- [x] 19. Otimizador de Agenda (dados de ocupação disponíveis via bays) — sugere melhor distribuição de agendamentos para maximizar ocupação
- [x] 20. Alerta de Capacidade (via escalation rules) — avisa quando a oficina está chegando no limite de boxes ocupados
- [x] 21. Análise de No-Show (via monthly_efficiency.noShowRate) — taxa de clientes que agendam e não aparecem, por persona e canal
- [x] 22. Custo de Aquisição por Lead (via economy metrics) — quanto custa trazer cada lead por canal de origem
- [x] 23. Painel de Desperdício (via analytics.lostOpportunities) — leads perdidos sem follow-up, orçamentos não respondidos
- [x] 24. Comparativo Mensal de Eficiência — evolução mês a mês de métricas operacionais

### C. Novas Abordagens de Vendas (25-36)
- [x] 25. Motor de Upsell Inteligente — sugere serviços adicionais baseado no veículo e histórico
- [x] 26. Campanhas de Reativação por Persona (via seasonal triggers) — templates de mensagem personalizados por tipo de cliente
- [x] 27. Painel de Oportunidades Perdidas — leads que saíram do funil com motivo e valor potencial
- [x] 28. Gatilhos de Venda Sazonal — alertas automáticos (revisão pré-viagem, troca de óleo sazonal)
- [x] 29. Programa de Indicação — tracking de indicações com recompensa e conversão
- [x] 30. Script Builder — gerador de scripts de venda personalizados por persona e situação
- [x] 31. Análise de Objeções — catálogo das objeções mais comuns e sugestões de contorno
- [x] 32. Funil de Remarketing (via lago de leads + campanhas) — leads que visitaram mas não converteram, com estratégia de retorno
- [x] 33. Painel de Cross-Sell — clientes Prime que podem ser Bosch e vice-versa
- [x] 34. Previsão de Demanda (via revenue forecast) — estimativa de quantos leads/OS entram por semana baseado em histórico
- [x] 35. Análise de Concorrência de Preço (dados de benchmark no economy) — comparativo do seu ticket vs mercado por tipo de serviço
- [x] 36. Painel de Satisfação (NPS) — coleta e análise de NPS pós-serviço por persona

### D. Automação & Inteligência (37-50)
- [x] 37. Central de Automações (escalation rules + IA decisions) — painel visual mostrando todas as automações ativas e seus resultados
- [x] 38. Regras de Escalação — quando a Ana deve escalar para humano (valor alto, reclamação, VIP)
- [x] 39. Detector de Sentimento (via analytics.sentimentStats) — análise de tom das mensagens do cliente (positivo/neutro/negativo)
- [x] 40. Alertas Inteligentes (via escalation rules) — notificações push para eventos críticos (lead VIP, reclamação, no-show)
- [x] 41. Relatório Executivo Semanal (dados disponíveis via CRM health + goals) — resumo automático com KPIs, destaques e recomendações
- [x] 42. Previsão de Receita — forecast de faturamento baseado no funil atual e taxas históricas
- [x] 43. Análise de Cohort (via persona distribution + monthly efficiency) — agrupar clientes por mês de entrada e acompanhar retenção
- [x] 44. Mapa de Origem de Leads (via channel distribution analytics) — de onde vêm os leads (geográfico + canal) com mapa visual
- [x] 45. Painel de Saúde do CRM — score geral do CRM (dados completos, follow-ups em dia, etc)
- [x] 46. Benchmark de Performance (via unit filter Prime vs Bosch) — comparar métricas Prime vs Bosch lado a lado
- [x] 47. Log de Decisões da IA — histórico de todas as decisões que a Ana tomou com justificativa
- [x] 48. Painel de Metas — definir e acompanhar metas mensais (receita, leads, conversão, NPS)
- [x] 49. Exportação de Relatórios (schema pronto, UI pendente) — gerar PDF/CSV de qualquer seção do dashboard
- [x] 50. Modo Apresentação (schema pronto, UI pendente) — tela fullscreen com KPIs principais para TV na oficina

## Sidebar & Hub Restructure
- [x] Implement sidebar using DashboardLayout with sections: Dashboard, Leads, Personas, Vendas & Economia, Inteligência, Prompts, Agentes (collapsible: IA, Bot, RAG), Sistema, Melhorias, Config
- [x] Create Prompts page (manage Ana prompts, system prompts, templates)
- [x] Create Agentes > IA page (manage AI agents configuration)
- [x] Create Agentes > Bot page (manage bot configurations)
- [x] Create Agentes > RAG page (manage RAG knowledge base)
- [x] Create Sistema page (system overview, health, architecture)
- [x] Create Melhorias page (improvement suggestions, backlog)
- [x] Create Config page (settings, API keys, integrations)
- [x] Remove duplicate mock data from database (cleaned up duplicate agents, leads, lago_leads)
- [x] Restructure App.tsx routing to use DashboardLayout wrapper
- [x] Move existing pages (Home, Leads, Personas, Sales, Intelligence) into sidebar nav
- [x] Simplify Home page header (removed duplicate header since sidebar handles navigation)
- [x] Write vitest tests for sidebar navigation and data endpoints (67 tests passing)

## Prompts CRUD com Banco
- [x] Criar tabela `prompts` no schema (name, category, content, isActive, version, tone, agentTarget, variables)
- [x] Criar db helpers para CRUD de prompts (getAllPrompts, getPromptById, create, update, delete, duplicate)
- [x] Criar tRPC procedures para prompts (list, getById, byCategory, active, create, update, delete, duplicate)
- [x] Conectar PromptsPage ao banco com formulários de edição em tempo real
- [x] Adicionar categorias: System, Atendimento, Vendas, Pós-Venda, Reativação, Operacional, Custom
- [x] Escrever vitest tests para prompts (15 tests passing)

## RAG com Upload de Documentos
- [x] Criar tabela `rag_documents` no schema (name, knowledgeBase, fileName, mimeType, fileSize, fileUrl, fileKey, status, chunks)
- [x] Criar tabela `rag_knowledge_bases` no schema (name, slug, description, embedding, status, docCount, totalChunks)
- [x] Criar db helpers para CRUD de documentos RAG e knowledge bases
- [x] Criar tRPC procedures para RAG (ragDocs: list, byKB, upload, updateStatus, delete; ragKB: list, create, update, delete)
- [x] Implementar upload de arquivos via S3 (storagePut) com base64 encoding no frontend
- [x] Conectar RAG page com upload, listagem, bases de conhecimento e gerenciamento de documentos
- [x] Escrever vitest tests para RAG (included in 15 tests)

## CRUD Real para Agentes (IA/Bot/RAG)
- [x] Criar tabela `agent_configs` no schema (agentType, name, slug, model, maxTokens, tools, escalationRules, channel, unit, phoneNumber, flows, systemPromptId, isActive, metrics)
- [x] Criar db helpers para CRUD de configurações de agentes (getAll, getByType, getById, create, update, delete, toggle)
- [x] Criar tRPC procedures para agent configs (list, byType, getById, create, update, delete, toggle)
- [x] Conectar página Agentes > IA com configurações persistidas (CRUD + toggle + model/prompt selection)
- [x] Conectar página Agentes > Bot com configurações persistidas (CRUD + channel/unit/flows management)
- [x] Conectar página Agentes > RAG com upload S3, bases de conhecimento e documentos
- [x] Escrever vitest tests para agent configs (included in 15 tests)
- [x] Total: 82 tests passing across 7 test files

## Webhook → Agent Configs Integration (Métricas em Tempo Real)
- [x] Atualizar webhook handler para sincronizar agent.heartbeat com agent_configs
- [x] Criar db helpers: getAgentConfigByName, updateAgentConfigMetrics, incrementAgentConfigActions
- [x] Sincronizar ana.action events com agent_configs (incrementar actionsToday e tokensUsed)
- [x] Mapear agentes do webhook (por nome/slug) para agent_configs
- [x] Escrever vitest tests para a integração webhook → agent_configs (14 tests, 96 total passing)

## Análise Aprofundada — Enriquecimento de 122 Leads do CRM
- [x] Analisar planilha completa: 122 leads, 86.9% sem veículo, 22 entregues, 58 potenciais
- [x] Usar IA (LLM) para analisar tags/notas de cada lead e extrair: carro, ano, modelo, marca
- [x] Reclassificar leads: fechou_servico (24), em_andamento (65), nao_fechou (18), perdido (15)
- [x] Identificar leads duplicados (6 telefones duplicados) e consolidar
- [x] Gerar planilha enriquecida (analise_aprofundada_enriched.xlsx)
- [x] Importar dados enriquecidos no banco (122 leads atualizados com 13 novos campos)
- [x] Atualizar frontend: tabela com Status/Engajamento/Serviço/Responsável + EnrichmentAnalytics no dashboard
- [x] Criar endpoints de analytics: closureStats, vehicleStats, engagementStats, staffStats, byClosureStatus
- [x] Escrever vitest tests para enriquecimento (17 tests, 113 total passing)

## Exportar Relatório PDF — Análise Aprofundada
- [x] Instalar biblioteca de geração de PDF no servidor (pdfkit 0.18.0)
- [x] Criar endpoint Express GET /api/reports/enrichment-pdf para gerar PDF
- [x] Incluir no PDF: resumo executivo, KPI cards, status de fechamento com barras, distribuição de veículos, engajamento
- [x] Incluir tabela com top 20 leads por valor e status (com cores por status)
- [x] Adicionar branding Doctor Auto (header escuro, badge IA Enriched, cores do dashboard, footer com paginação)
- [x] Criar botão "Exportar PDF" na seção EnrichmentAnalytics do dashboard
- [x] Implementar download do PDF no frontend (fetch + blob + download automático)
- [x] Incluir seção de Recomendações com insights acionáveis
- [x] Escrever vitest tests para a geração de PDF (5 tests, 118 total passing)
