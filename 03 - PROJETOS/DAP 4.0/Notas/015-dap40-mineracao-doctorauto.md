---
title: Mineração DoctorAuto — blueprint pro dap4-portals
date: 2026-05-09
type: mineracao
fonte: C:\THALES\DoctorAuto\ + C:\THALES\_archive\dap-tools-untracked-2026-05-06\apps\consultor\
destino: C:\THALES\DAP4\dap4-portals\
status: completo
tags: [dap40, dap4-portals, doctorauto, figma-make, consultor-archive, blueprint, mineracao]
---

# Mineração DoctorAuto — blueprint pro dap4-portals

> Análise estruturada de 2 protótipos órfãos de design-to-code (Figma Make + Gemini Antigravity) cruzados com o estado atual do monorepo `dap4-portals`. Objetivo: extrair valor informacional dos protótipos sem investir em tornar nenhum dos dois um produto. Output: roadmap acionável pro monorepo real.

---

## TL;DR (1 minuto)

**Os protótipos são blueprint, não base de código.** O `DoctorAuto` (Figma Make, ~70 pages, 3 stacks distintas em 3 meses) e o `consultor` archive (Gemini Antigravity, 14 pages) são **demos de produto evolutivos** com débito estrutural alto. **Zero linha de código produtivo deles deve ir pra produção** — mas o pensamento de produto contido neles é gold.

**O monorepo é o destino real:**
- `apps/operacao` é o vencedor disparado — **117 testes verdes, Postgres+RLS, auth híbrida ADR-001, deploy-ready**. Não tocar até virar canônico do consultor.
- `apps/aios` é frontend-first prototype declarado, ainda em SQLite (Phase 4 pendente).
- `apps/gestao` é shell + WipPanels — 9 pages, 5 tabelas no schema, zero feature operacional.
- `apps/aios-mandala` e `apps/tools` são HTML estático (referência, não produto).

**Decisão arquitetural recomendada (revisão ao plano monorepo):** **adicionar 5° app `apps/admin`** (não previsto no plano de 2026-05-06) pra abrigar o **portal do dono-da-plataforma** que o `dev/` do DoctorAuto pavimentou — DevSQL, DevTables, DevDatabase, DevUsers, DevPermissoes, DevExplorer (route map). É o equivalente DAP do Supabase Studio: ferramenta DBA + IAM + observability cross-tenant. Sem isso, o ecossistema vai depender do Supabase Studio externo pra operar — inaceitável a longo prazo.

**Top 5 features pra portar (priorizadas):**
1. **9 status canônicos de OS hex-colored** (Diagnóstico → Orçamento → Aguardando Aprovação → Aguardando Peça → Pronto p/ Iniciar → Em Execução → Pronto → Aguardando Retirada → Entregue) — adotar como enum no `@dap/db/schema/oficina.ts`.
2. **Pendências como entidade de primeira classe** (FIFO entre consultores, 4 estados) — tabela nova em `oficina`.
3. **Orçamento público ao cliente via link assinado** (`/cliente/orcamento/:osId`) — gancho consumer-facing pra reduzir tempo de permanência (gargalo declarado no CLAUDE.md).
4. **Confirmar Chegada → cria OS automaticamente em "Diagnóstico"** — elimina dupla digitação agendamento/pátio.
5. **DevSQL/DevTables/DevPerfilIA** no novo `apps/admin` — DBA console + editor de system prompts dos agentes Sophia/Anna/Walter.

**JAMAIS portar (lista negra):** `exec_sql()` PostgreSQL function, service_role JWT no client (28 arquivos do DoctorAuto + maioria do consultor archive), senhas plaintext (`123456`, `dev123`, `gestao123` em código-fonte), SHA-256 sem salt no edge function, `ProtectedRoute` confiando só em `localStorage`, `EmpresaToggle` com `window.location.reload()`, endpoints `/debug/*` em prod, `forgot-password` retornando token em texto puro.

**Veredicto consultor archive:** **arquivar definitivo (delete safe).** 100% overlap com DoctorAuto, todas as 14 pages têm equivalente já mapeado, zero feature única. O `_archive` tarball já foi criado em 2026-05-06, basta confirmar o flag de descarte e remover o dir.

**Veredicto DoctorAuto:** **arquivar como referência read-only.** Mover `C:\THALES\DoctorAuto\` → `C:\THALES\_archive\DoctorAuto-2026-05-09\`. Manter `src/imports/MAPA_*` + os 5 PDFs do worktree `sad-keller` como input pra próxima fase de mineração (RAG dos PDFs operacionais).

---

## A. Inventário consolidado — 117 pages mapeadas

> Cobertura: 32 admin/ + 12 gestao/ + 5 analytics/ + 12 dev/ + 18 top-level (DoctorAuto) + 14 consultor archive + 4 layouts + 48 shadcn ui.

### A.1 — DoctorAuto: distribuição por persona/portal

| Persona | DoctorAuto pages | Total | Destino sugerido no monorepo |
|---|---|---:|---|
| **Consultor (balcão)** | NovaOS, OSDetalhes, Agendamentos, OrdensServico, Clientes, ClienteDetalhe, AgendaMecanicos, Pendencias, Notifications, Checklists, Pátio Kanban, Dashboard, MecanicoView | 13 | `apps/operacao` |
| **Gestor/Sócio** | Gestao{Comercial,Dashboards,Financeiro,Fornecedores,Melhorias,Metas,Operacoes,OsUltimate,RH,Tecnologia,VeiculosOrfaos,VisaoGeral} + Analytics{Churn,Funil,LTV,NPS,ROI} + Admin{Financeiro,FluxoCaixa,Vendas,Comissoes,ContasPagar,ContasReceber,Despesas,Compras,NFe,Estoque,Produtividade,Relatorios,Operacional,Ajuda,Configuracoes,Avaliacoes,Reclamacoes,Sugestoes,IaQG,Integracoes,TrelloMigracao,Usuarios} | 39 | `apps/gestao` (decisão analítica) + parte em `apps/operacao` (CRUD financeiro lançamento) |
| **Dev/Plataforma** | Dev{API,Configuracoes,Dashboard,DashboardIA,Database,Documentacao,Explorer,Ferramentas,IAPortal,Logs,OutrasHub,PerfilIA,Permissoes,Processos,SQL,Tables,Users} | 17 | **`apps/admin` (NOVO, opção C ao plano)** |
| **Mecânico** | MecanicoView, StaffMecanico (guard) | 2 | `apps/aios/modules/mecanico` (já existe, expandir) |
| **Cliente** | (orçamento público) — não está nas pages do DoctorAuto, mas declarado nos MAPAS | 0 (declarado) | `apps/operacao` (rota pública sem auth) |
| **Auth/Público** | Login, DevLogin, StaffLogin, ForgotPassword, Landing, NotFound | 6 | `apps/operacao` (canonical) — descartar 2 logins redundantes |
| **Guards triviais** | Staff{Consultor,Gestao,Mecanico} + VisaoGeral (alias) | 4 | **descartar** (vira middleware) |

### A.2 — Top 10 pages do DoctorAuto com mais código real (gold value)

| # | Page | Linhas | Tabelas | Por que importa |
|---|---|---:|---|---|
| 1 | `AdminNovaOS.tsx` | 495 | `04_CLIENTS`, `05_VEHICLES`, `06_OS`, `07_OS_ITENS` | Wizard 4-step com debounce search + batch insert. **Peça mais densa do protótipo.** |
| 2 | `AdminIntegracoes.tsx` | 450 | mock | Painel Kommo/WhatsApp/Trello/OpenAI — UI valiosa, lógica zero |
| 3 | `AdminOSDetalhes.tsx` | 437 | `06_OS`, `07_OS_ITENS`, `08_OS_HISTORICO` | Timeline 9-status + CRUD itens + histórico |
| 4 | `AdminIaQG.tsx` | 436 | mock | "Quartel-General de IA" — score/temperatura de leads |
| 5 | `AdminTrelloMigracao.tsx` | 389 | mock | Wizard sync Trello bidirectional |
| 6 | `DevIAPortal.tsx` | 374 | mock | Chat playground 3 agentes (Sophia/Simone/Raena) |
| 7 | `DevPerfilIA.tsx` | 370 | state local | Editor system prompt + temperatura/topP por agente |
| 8 | `AdminAgendamentos.tsx` | 358 | `15_AGENDAMENTOS`, `97_RECUSAS` | **Único arquivo multi-tenant correto** (lê empresa_id) |
| 9 | `PatioKanban.tsx` | 325 | `06_OS`, `14_RECURSOS` | Kanban 11 colunas + mapa físico de recursos |
| 10 | `ForgotPassword.tsx` | 313 | edge fn | Flow 3-step de reset |

**Honorable mentions:** `DevSQL.tsx` (282) — único console SQL ad-hoc real do protótipo, gold pro novo `apps/admin`.

### A.3 — Layouts e componentes infra (DoctorAuto)

| Componente | Linhas | Veredicto |
|---|---:|---|
| `AdminLayout.tsx` | 191 | Extrair `<AppLayout role accent menuConfig />` parametrizando paleta vermelho/azul |
| `ConsultorLayout.tsx` | 173 | **Quase idêntico ao AdminLayout** — deduplicar |
| `DashboardLayout.tsx` | 194 | Tem import órfão `figma:asset/...png` — usar `Logo.tsx` em vez |
| `DevLayout.tsx` | 238 | Boa inspiração ("dev console" multicor + persona switcher no footer); paths inválidos/duplicados |
| `EmpresaToggle.tsx` | 143 | **Conceito sim, código não** (window.location.reload + IDs hardcoded) |
| `ProtectedRoute.tsx` | 61 | **NÃO portar** — auth client-side trust em localStorage |
| `Logo.tsx` | 24 | Trivial, copiar |
| `figma/ImageWithFallback.tsx` | 28 | Útil drop-in |
| `components/ui/*` (shadcn) | 48 arquivos | `@dap/ui` já tem versão própria — comparar antes de duplicar |

---

## B. Mapping table — DoctorAuto page → destino no monorepo

### B.1 — Para `apps/operacao` (consultor de balcão, atendimento)

| DoctorAuto page | Status atual em operacao | Ação |
|---|---|---|
| `Login.tsx` | `pages/login.tsx` existe | **Manter operacao** — Login do DoctorAuto é canônico mas operacao já tem auth híbrida ADR-001 implementada (vencedora) |
| `Dashboard.tsx` | `pages/dashboard.tsx` existe | Comparar features, se DoctorAuto tem KPIs únicos, portar |
| `PatioKanban.tsx` (325 linhas) | `pages/patio.tsx` existe | **Portar 9 status hex-colored + mapa de recursos físicos** |
| `AdminAgendamentos.tsx` (358 linhas) | `pages/agenda.tsx` existe | **Portar fluxo IA-loop de 4 tentativas pra cancelamento + tabela `97_RECUSAS`** |
| `AdminClientes.tsx` (115 linhas) | `pages/customers.tsx` existe | Comparar busca multi-campo `.or()` ilike |
| `AdminClienteDetalhe.tsx` (108 linhas) | falta | **Portar** (página 360° cliente: dados + veículos + 10 últimas OS) |
| `AdminOrdensServico.tsx` (122 linhas) | `pages/orders.tsx` existe | Comparar paginação + filtro 8 estados |
| `AdminOSDetalhes.tsx` (437 linhas) | `pages/service-order-detail.tsx` existe | **Portar timeline 9-status + histórico em `08_OS_HISTORICO`** |
| `AdminNovaOS.tsx` (495 linhas) | falta wizard explícito | **Portar wizard 4-step** (Cliente → Veículo → Serviço → Confirmação) |
| `AdminPendencias.tsx` (94 linhas) | falta | **Portar** + criar tabela `pendencias` no `oficina` schema |
| `AdminNotifications.tsx` (80 linhas) | falta | **Portar** (3 buckets: aguardando aprovação/orçamento/entrega) |
| `AdminChecklists.tsx` (74 linhas) | `checklists` table já existe em oficina | Wire UI |
| `MecanicoView.tsx` (121 linhas) | `apps/aios/modules/mecanico` tem | Cross-portal — manter no aios |
| `Cliente Orçamento Público` (declarado em MAPAS) | falta | **NOVO — implementar** (rota pública assinada `/cliente/orcamento/:osId`) |

### B.2 — Para `apps/gestao` (gestor/sócio, visão analítica)

| DoctorAuto page | Veredicto |
|---|---|
| `GestaoVisaoGeral.tsx` (97 linhas) | **Portar como home** — executive dashboard com 6 KPIs + 2 charts + 14d temporal |
| `GestaoOsUltimate.tsx` (146 linhas) | **Portar** — visão 360 OS com filtro por mecânico + ranking |
| `GestaoMelhorias.tsx` (95 linhas) | **Portar** — único exemplo de regras-como-código gerando recomendações (embrião Sophia) |
| `GestaoFinanceiro.tsx` (105 linhas) | **Portar** — KPIs mês + meta R$70k + projeção linear |
| `GestaoMetas.tsx` (78 linhas) | **Portar** — 4 progress bars (faturamento, OS, ticket, taxa entrega) |
| `GestaoOperacoes.tsx` (107 linhas) | **Portar** — pie + alertas de gargalo (>5 pendentes, >10 em execução) |
| `GestaoRH.tsx` (105 linhas) | **Portar** — performance mecânicos (positivos/negativos + Top 10) |
| `GestaoComercial.tsx` (129 linhas) | **Portar** — fila aprovação cadastros |
| `GestaoFornecedores.tsx` (89 linhas) | **Portar** — top 20 peças (proxy até cadastro real existir) |
| `GestaoVeiculosOrfaos.tsx` (129 linhas) | **Portar** — data quality (vincular veículo órfão a cliente) |
| `GestaoDashboards.tsx` (62 linhas) | **Portar** como `/` hub-grid de 8 módulos |
| `GestaoTecnologia.tsx` (60 linhas) | **descartar** — mock 100%, KPIs hardcoded |
| `Analytics{Churn,Funil,LTV,NPS,ROI}.tsx` (377 linhas total) | **Portar todos os 5** — ranking LTV é único, ROI tem histórico mensal, Funil tem 7 etapas, Churn tem motivos de recusa |
| `AdminFinanceiro/FluxoCaixa/Relatorios/Produtividade` | **Portar como views analíticas** (gestao = "visão", operacao = "ação") |
| `AdminVendas/Comissoes/ContasPagar/ContasReceber/Despesas/Compras/NFe/Estoque` | **Consolidar em 2-3 pages** — são 8 cópias do mesmo template com filtro de status diferente |

### B.3 — Para novo `apps/admin` (portal dono-da-plataforma)

> **Decisão arquitetural recomendada:** adicionar 5° app não previsto no plano monorepo. Justificativa abaixo.

| DoctorAuto page | Linhas | Por que importa |
|---|---:|---|
| `DevSQL.tsx` | 282 | **Console SQL ad-hoc** com sidebar tabelas + quick-queries + histórico + export CSV. Único arquivo dev/ funcional. **Substitui depender do Supabase Studio externo** |
| `DevTables.tsx` | 231 | DB browser — RPCs `list_tables`/`list_columns` + view paginado |
| `DevDatabase.tsx` | 491 | CRUD genérico de KV store (substituir por inspeção real de tabelas via @dap/db) |
| `DevUsers.tsx` | 124 | CRUD staff cross-tenant — IAM da plataforma |
| `DevPermissoes.tsx` | 152 | Matriz visual roles × permissões — RBAC management UI |
| `DevExplorer.tsx` | 186 | **Mapa de TODAS as rotas** categorizado — manifest visual do produto |
| `DevLogs.tsx` | 143 | Stub observability — substituir por embed Grafana/SigNoz |
| `DevProcessos.tsx` | 189 | Monitor processos servidor — embed Grafana ou descartar |
| `DevAPI.tsx` | 186 | Catálogo endpoints REST — usar Mintlify externo |
| `DevDocumentacao.tsx` | 116 | Hub links docs — descartar |
| `DevFerramentas.tsx` | 152 | Catálogo tools — descartar |
| `DevConfiguracoes.tsx` | 125 | Toggles config sistema — não levar (config vai em infra) |

### B.4 — Para `apps/aios` (chairman + IA orquestração)

| DoctorAuto page | Veredicto |
|---|---|
| `DevIAPortal.tsx` (374 linhas) | **Portar como /aios/playground** — chat sandbox multi-agente |
| `DevPerfilIA.tsx` (370 linhas) | **Portar como /aios/agentes/:slug/config** — editor system prompt + temperatura/topP/penalty (substituir prompts hardcoded por config persistida) |
| `DevDashboardIA.tsx` (39 linhas, placeholder) | **Implementar do zero** — métricas tokens/custo por empresa por agente |
| `DevOutrasHub.tsx` (39 linhas, placeholder) | **Implementar do zero** — webhooks Z-API/WhatsApp/OpenAI |
| `AdminIaQG.tsx` (436 linhas, mock) | **Portar UI** — score/temperatura leads (lógica via Sophia/Anna real) |
| `AdminTrelloMigracao.tsx` (389 linhas, mock) | **Descartar** — Trello é legado, não vai sync contínuo |
| `AdminIntegracoes.tsx` (450 linhas, mock) | **Refazer** — Kommo é a integração comercial real (já tem `@dap/kommo` package pronto, não consumido por nenhum app ainda) |

### B.5 — Descartar definitivo

- `Landing.tsx` — splash trivial
- `VisaoGeral.tsx` — alias 1-linha redundante
- `Staff{Consultor,Gestao,Mecanico}.tsx` — guards mortos (vira middleware)
- `DevLogin.tsx` — redundante com Login.tsx unificado
- `StaffLogin.tsx` — bug crítico (plaintext password compare)
- `AdminAjuda.tsx` — FAQ estático 8 itens hardcoded
- `Admin{Avaliacoes,Reclamacoes,Sugestoes}.tsx` — 3 cópias literais do mesmo arquivo
- `GestaoTecnologia.tsx` — mock 100%
- `consultor` archive (14 pages) — 100% overlap, zero feature única

---

## C. Gap analysis — `dap4-portals` atual vs DoctorAuto

### C.1 — `apps/operacao` (vencedor, mais maduro)

**Já tem:** 117 testes verdes, Postgres+RLS, auth híbrida ADR-001, 13 tabelas em `oficina`, 15 routers Express, lazy-loaded routes, Drizzle direto, deploy-ready (`master 1a74196`). Pages reais: dashboard, agenda, customers, orders, service-order-detail, patio, financeiro, timeline, users-management, login, reset-password.

**Não tem (gap vs DoctorAuto blueprint):**
1. **Wizard NovaOS de 4 steps** — operacao tem orders, mas não wizard
2. **Tabela `pendencias`** (FIFO entre consultores) — não existe
3. **Tabela `notifications`** (3 buckets de alertas) — não existe
4. **Tabela `checklists` instances** — checklists existe no schema, mas wire UI falta
5. **Cliente 360° page** — `customers.tsx` é lista, falta detail page com 10 últimas OS + total gasto
6. **Orçamento público assinado** (`/cliente/orcamento/:osId`) — rota pública sem auth
7. **9 status hex-colored canônico** — operacao tem status, mas falta padronizar com hex + label do DoctorAuto
8. **"Confirmar Chegada → cria OS"** — fluxo agendamento→OS automático
9. **PatioKanban com 11 colunas + mapa físico de recursos** (elevadores 1-9, boxes 1-5, rampa, dinamômetro, VCDS, remap) — operacao tem patio.tsx, comparar
10. **IA-loop de 4 tentativas** pra cancelamento (insistir motivo) — único do AdminAgendamentos
11. **Tabela `97_RECUSAS`** (auditoria/learning de cancelamentos) — não existe

**Código órfão a remover:** `apps/operacao/client/src/pages/portais/*` (10 arquivos espelhando o mockup chairman do aios — duplicação que vira lixo quando aios virar canônico).

### C.2 — `apps/gestao` (shell + WipPanels)

**Já tem:** 9 pages (`visao`, `unidades`, `financeiro`, `pessoas`, `estrategia`, `comercial-360`, `users-management`, `login`, `reset-password`), 5 tabelas em `gestao` schema (`organizations`, `users`, `kpiSnapshots`, `okrs`, `adrs`), auth híbrida via `@dap/auth`, 2 test files (raquítico).

**Não tem (gap massivo):**
1. **17 pages analíticas mapeadas no DoctorAuto** — todas WIP no gestao atual
2. **Tabelas finance** (DRE, transactions, accounts) — schema atual não cobre
3. **Tabelas HR** (headcount, salaries, performance individual) — não existe
4. **Recharts/charts integrados** — gestao não usa charts ainda
5. **Camada agregadora de KPIs** (4+ pages calculam faturamento total isoladamente — sinal claro de que precisa de view materializada / KPI service)

**Código órfão:** `pages/{visao,unidades,financeiro,pessoas,estrategia,comercial-360}.tsx` são WipPanel placeholders — substituir por implementações portadas do DoctorAuto.

**Inconsistência arquitetural:** gestao usa Supabase PostgREST (`createClient(...).from('users')`) em vez de Drizzle direto (operacao usa Drizzle). Comment no código diz "ADR pending" — **resolver: padronizar Drizzle.**

### C.3 — `apps/aios` (frontend-first prototype, ainda em SQLite)

**Já tem:** 16 pages em modules consultor + 5 em mecanico + 1 cliente + 8 chairman inline + 3 top-level. Backend com 12 routers. Schema SQLite com ~20 tabelas. RBAC source-of-truth (9 roles, 6 permissions). Mandala D3.js. Hash routing.

**Não tem:**
1. **Auth real** — só stub `x-stub-role` (todos users `id=1`)
2. **Postgres** — Phase 4 do plano de migração ainda não rodou
3. **Editor de system prompts** dos agentes — prompts ainda hardcoded
4. **Métricas de IA** — tokens/custo/latência por agente
5. **Webhooks integrados** Z-API/WhatsApp/OpenAI — package `@dap/kommo` pronto mas não consumido
6. **Portal cliente real** — `ClienteDashboard` é esqueleto

**Código órfão:** `apps/aios/handoff-*.html` (9 arquivos crescendo na raiz), pages chairman inline em App.tsx (1095 linhas).

### C.4 — `apps/admin` (NÃO EXISTE — recomendação de criar)

**Por quê adicionar:** o `dev/` do DoctorAuto pavimentou um portal de operação interna (DBA + IAM + observability cross-tenant) que **não cabe em nenhum dos 4 portais existentes**. Sem ele, o ecossistema vai depender do Supabase Studio externo + Grafana externo + scripts manuais — não é sustentável.

**Spec mínima:**
- DBA console (DevSQL com confirm destructive)
- DB browser (DevTables — listar tabelas + view paginado de rows)
- Staff IAM cross-tenant (DevUsers — criar/desativar com bcrypt forçado)
- RBAC management (DevPermissoes — matriz roles × permissions visual)
- Route map / sitemap (DevExplorer — manifest visual do produto inteiro)
- Logs/Processos (embeds Grafana/SigNoz)
- Edição system prompts agentes (DevPerfilIA — pode coexistir aqui ou só em aios)

**Auth:** restringido a role `owner` ou `system` do `@dap/aios-schema/rbac.ts`. **Nada que use service_role no client.** Tudo via RPCs com permissões granulares.

### C.5 — `apps/aios-mandala` e `apps/tools`

Ambos são HTML estático puro (referência/playbook/diagrama). Manter como está — não é feature gap.

---

## D. Schema consolidado — fonte única para `@dap/db`

> Tarefa 3.3 do plano monorepo (`Task 3.3 @dap/db`). Consolida: 13 tabelas de `oficina` (já em PG), 5 de `gestao` (já em PG), 16-31 do DoctorAuto (4 schemas conflitantes), 17 do consultor archive, 20 SQLite do aios.

### D.1 — `oficina` schema (canonical PG, expandir)

**Já existe (13):** `organizations`, `users`, `customers`, `vehicles`, `mechanics`, `serviceOrders`, `serviceItems`, `serviceOrderComments`, `serviceOrderAttachments`, `appointments`, `checklists`, `telemetry`, `payments`. RLS por `oficina.current_user_org_id()`.

**Adicionar (gap do DoctorAuto + consultor archive):**

| Tabela nova | Origem | Justificativa |
|---|---|---|
| `pendencias` | DoctorAuto `13_PENDENCIAS` | FIFO entre consultores, 4 estados (`pendente|feita|feita_ressalvas|nao_feita`) |
| `service_order_history` | DoctorAuto `08_OS_HISTORICO` | Log estruturado de mudanças de status na OS |
| `service_order_workflow_steps` | DoctorAuto `09_OS_WORKFLOW` | 9 status canônicos hex-colored como tabela referencial |
| `recursos` (físicos) | DoctorAuto `14_RECURSOS` | 18 recursos: elevadores 1-9, boxes 1-5, rampa, dinamômetro, VCDS, remap, vagas extras |
| `agendamentos_recusas` | DoctorAuto `97_RECUSAS` | Auditoria de cancelamentos com motivo (alimentar Sophia/learning) |
| `veiculos_orfaos` | DoctorAuto `veiculos_orfaos` | Data quality — veículos sem cliente vinculado |
| `mechanic_daily_feedback` | DoctorAuto + consultor archive | `performance_score`/`punctuality_score`/`quality_score` (1-5) por dia |
| `notifications` | DoctorAuto AdminNotifications | Auto-geradas de 3 buckets de OS |
| `catalogo_servicos` | DoctorAuto `98_SERVICOS` + consultor archive `CatalogoServico` | Catálogo de serviços por tipo + valor base + tempo estimado |
| `quote_public_tokens` | DoctorAuto orçamento público | Tokens assinados pra rota `/cliente/orcamento/:osId` |

**Padronizar enum `service_order_status`:** os 9 status hex-colored canônicos — Diagnóstico (#94a3b8), Orçamento (#fbbf24), Aguardando Aprovação (#f59e0b), Aguardando Peça (#a78bfa), Pronto p/ Iniciar (#60a5fa), Em Execução (#3b82f6), Pronto (#10b981), Aguardando Retirada (#06b6d4), Entregue (#22c55e). Cores definidas em `@dap/ui/tokens.css` — não hardcode em pages.

**Resolver conflito de nomenclatura:** DoctorAuto usa prefixo numérico (`00_companies`, `06_OS`), aios usa snake_case (`service_orders`), Drizzle usa camelCase (`serviceOrders`). **Decisão:** manter padrão `oficina.*` em snake_case PG + camelCase no Drizzle TS — descartar prefixos numéricos. **Migration de rename eventual.**

### D.2 — `gestao` schema (PG, expandir)

**Já existe (5):** `organizations`, `users`, `kpiSnapshots`, `okrs`, `adrs`.

**Adicionar:**

| Tabela | Origem | Justificativa |
|---|---|---|
| `metas_periodo` | DoctorAuto GestaoMetas | Metas por período (faturamento R$70k, 50 OS, ticket R$1500, taxa 90%) |
| `melhorias` | DoctorAuto GestaoMelhorias | Insights gerados por regras-como-código |
| `gestao_alerts` | DoctorAuto MAPAS | Alertas operacionais (gargalos, anomalias) |

**KPI service / view materializada:** o protótipo calcula faturamento total em 4+ pages isoladamente. **Criar view `gestao.v_kpis_oficina_mes_atual`** que agrega faturamento, ticket médio, OS por status, projeção, taxa entrega — todas pages consomem dessa view única.

### D.3 — `aios` schema (PG, MIGRAR de SQLite)

**Phase 4 do plano monorepo:** migrar `apps/aios/packages/aios-schema/src/schema/` (SQLite) → `packages/db/src/schema/aios.ts` (PG). Hoje o `aios.ts` PG é stub (só `conversations` + `messages`).

**20 tabelas a migrar:** `roles`, `permissions`, `role_permissions`, `users`, `events`, `customers`, `vehicles`, `leads`, `conversations`, `messages`, `quotes`, `quote_items`, `service_orders`, `mechanics`, `checklists`, `checklist_items`, `service_order_comments`, `service_order_attachments`, `service_order_parts`, `appointments`. **Cuidado:** muitas overlap com `oficina.*` (customers, vehicles, service_orders, mechanics, appointments, checklists). **Decidir:** ou consolidar em `oficina.*` único (preferível) ou manter `aios.*` como camada IA por cima.

**Adicionar (IA-specific):**

| Tabela | Justificativa |
|---|---|
| `agent_configs` | system_prompt + temperatura + top_p + penalties por agente (Sophia/Anna/Walter), versionado |
| `agent_runs` | Cada execução de agente — tokens, custo, latência, output |
| `agent_metrics` | Aggregations por agente/empresa/período |

### D.4 — `crm` schema (PG, novo dedicado)

**Hoje:** `packages/db/src/schema/crm.ts` tem `tenants`, `users`, `leads`. **Expandir:**

| Tabela | Origem | Justificativa |
|---|---|---|
| `kommo_tokens` | DoctorAuto `kommoTokens` | Tokens OAuth Kommo por empresa |
| `kommo_leads` | DoctorAuto `kommoLeads` | Cache de leads Kommo (60s TTL) |
| `lead_scores` | DoctorAuto `leadScores` | Score IA por lead |
| `lead_score_history` | DoctorAuto `leadScoreHistory` | Histórico de mudanças de score (auditoria) |
| `analise_promocoes` | DoctorAuto `97_ANALISE_PROMOCOES` | A/B test promoções |
| `promocoes` | DoctorAuto `promocoes` | Catálogo de promoções ativas |

`@dap/kommo` package já tem client/proxy/webhook prontos com tests — **wire-up no aios e operacao.**

---

## E. Top 20 features pra portar — ranked por valor × esforço

> Critério: dor real declarada no CLAUDE.md (R$700k/mês meta, 9 elevadores 45% capacidade, 50 OS/mês, gargalos lead/permanência/conversão) × custo de implementação × maturidade do blueprint.

### Tier 1 — Alta dor, baixo-médio esforço (próximas 4 sprints)

1. **9 status canônicos hex-colored de OS** — adotar como enum em `oficina.service_orders.status` + tokens em `@dap/ui`. Custo: 1 dia. Valor: padroniza a operação inteira.
2. **Tabela `pendencias` + page AdminPendencias portada** — FIFO entre consultores, 4 estados. Custo: 2 dias. Valor: resolve gargalo "quem fazia o quê".
3. **Wizard NovaOS 4-step** (Cliente → Veículo → Serviço → Confirmação) — debounce search clientes, criação inline, batch insert itens. Custo: 1 sprint. Valor: tempo de abertura OS cai pela metade.
4. **"Confirmar Chegada → cria OS automaticamente em Diagnóstico"** — fluxo agendamento→OS. Custo: 2 dias. Valor: elimina dupla digitação.
5. **AdminClienteDetalhe** (página 360° cliente) — dados + veículos + 10 últimas OS + total gasto. Custo: 2 dias. Valor: reduz fricção atendimento recorrente.
6. **PatioKanban com mapa de recursos físicos** (`14_RECURSOS`) — elevadores 1-9, boxes 1-5, etc. Custo: 1 sprint. Valor: visibilidade de capacidade real (gargalo "9 elevadores 45%").
7. **AdminAgendamentos com IA-loop de 4 tentativas pra cancelamento** + tabela `97_RECUSAS`. Custo: 1 sprint. Valor: alimenta Sophia/learning + reduz cancelamentos.

### Tier 2 — Alta dor, médio-alto esforço (próximo trimestre)

8. **Orçamento público assinado** (`/cliente/orcamento/:osId`) — rota pública sem auth, aprovação por item. Custo: 1 sprint. Valor: gargalo "conversão de orçamento" — gancho consumer-facing direto.
9. **Multi-tenant correto** (JWT claim `empresa_id` + RLS por empresa + `<TenantSwitcher>` no @dap/ui consumindo do JWT). Custo: 2 sprints. Valor: viabiliza Bosch + Prime + 347 sem reload destrutivo. **Substitui EmpresaToggle do DoctorAuto.**
10. **AdminNotifications** (3 buckets: aguardando aprovação/orçamento/entrega) + tabela `notifications`. Custo: 1 sprint. Valor: reduz tempo de permanência via lembretes proativos.
11. **GestaoVisaoGeral** (executive dashboard 6 KPIs + 14d temporal) + view `v_kpis_oficina_mes_atual`. Custo: 1 sprint. Valor: substitui planilha mental do Thales.
12. **GestaoFinanceiro + meta R$70k + projeção linear** — KPIs do mês. Custo: 1 sprint. Valor: tracking direto da meta R$700k/mês.
13. **AnalyticsLTV** (top 15 clientes por gasto) + recorrência. Custo: 3 dias. Valor: identificar carteira valiosa pra atendimento premium.
14. **AnalyticsChurn** (motivos de cancelamento agrupados) + GestaoMelhorias (insights heurísticos). Custo: 1 sprint. Valor: identifica vazamentos no funil.

### Tier 3 — Estratégico longo prazo (6 meses)

15. **`apps/admin` novo** com DevSQL + DevTables + DevUsers + DevPermissoes + DevExplorer. Custo: 2-3 sprints. Valor: independência do Supabase Studio + IAM cross-tenant correto.
16. **DevPerfilIA portado pra `apps/aios/agentes/:slug/config`** — editor system prompt + temperatura/topP por agente, versionado em `agent_configs`. Custo: 1 sprint. Valor: tunning de Sophia/Anna/Walter sem deploy.
17. **`@dap/kommo` wire-up no `apps/operacao`** — package pronto, ninguém consome. Custo: 1 sprint. Valor: integração comercial Kommo de primeira classe (oposto da migração Trello).
18. **GestaoVeiculosOrfaos + tabela `veiculos_orfaos`** — data quality. Custo: 3 dias. Valor: limpa base.
19. **GestaoRH** (performance mecânicos positivos/negativos) + tabela `mechanic_daily_feedback`. Custo: 1 sprint. Valor: gestão de equipe técnica baseada em dado.
20. **DevDashboardIA** (métricas tokens/custo por empresa por agente). Custo: 1 sprint. Valor: controle de custo IA conforme escala.

---

## F. JAMAIS portar — lista negra de antipatterns

> Tudo abaixo está no DoctorAuto e/ou consultor archive. **Nenhuma linha vai pro monorepo.** Documentar pra time saber e revisores rejeitarem.

### F.1 — Segurança crítica

| Antipattern | Onde está | Por que é veneno |
|---|---|---|
| **`exec_sql()` PostgreSQL function** | `supabase/migrations/20260318_exec_sql_function.sql` | SECURITY DEFINER + bloqueio regex frouxo. SQL injection trivial via service_role. **Backdoor total.** |
| **service_role JWT no client** | 28 arquivos do DoctorAuto + maioria consultor archive | Bypass total de RLS. Qualquer build prod expõe acesso completo ao DB. |
| **Senhas hardcoded em código-fonte** | Edge function `make-server-0092e077/index.tsx` linhas 53-86: `Dev_thales/dev123`, `Gestao_thales/gestao123`, `Consultor_thales/consultor123`, `Mecanico_thales/mecanico123` | Qualquer fork do repo expõe credenciais |
| **Senha padrão `123456` em texto plano** | DoctorAuto MAPAS + DevUsers.tsx + consultor archive | Datado e inseguro mesmo pra protótipo |
| **SHA-256 sem salt** pra hash de senha | Edge function | Inadequado pra prod — usar bcrypt (já existe RPC `verify_staff_login` com bcrypt no protótipo, mas StaffLogin compara plaintext em paralelo) |
| **`StaffLogin` compara senha plaintext** | DoctorAuto `pages/StaffLogin.tsx`: `senha_hash !== password` literal | Bug crítico convivendo com Login.tsx que usa bcrypt — escolher um caminho |
| **`/debug/users`, `/debug/reset-users`, `/debug/test-password` públicos sem auth** | Edge function | Vazam hashes + permitem reset arbitrário |
| **`forgot-password` retorna token em texto puro na response** | Edge function | Qualquer call autenticada sequestra recuperação |
| **`ProtectedRoute` confia em `localStorage`** | `components/ProtectedRoute.tsx` | XSS = takeover total. NÃO valida token contra Supabase. |

### F.2 — Arquitetura

| Antipattern | Por que é veneno |
|---|---|
| **`EmpresaToggle` com `window.location.reload()`** | Destrói estado de form/scroll/drafts. Inviável em produto consumer-facing. **Conceito sim, código não.** |
| **Multi-tenant filtrado client-side** | Doc do próprio DoctorAuto admite: *"O filtro no frontend é apenas UX. Para segurança real, você deve TAMBÉM adicionar RLS policies."* — RLS nunca foi aplicado |
| **Backend monolítico em Edge Function única** | `make-server-0092e077` (804 linhas, Hono+Deno+KV). Operacao já tem Express servers separados — manter |
| **KV store genérico no lugar de schema relacional** | `kv_store_0092e077 (key TEXT PK, value JSONB)` armazenando clientes/OS/etc. Sacrifica integridade referencial |
| **3 logins coexistindo** (Login + DevLogin + StaffLogin) | Manter um só (Login com cards de role) — descartar os outros 2 |
| **Endpoints `/auth/login` no client mas `/auth/login-dev`+`/auth/login-staff` no server** | Drift cliente×servidor sério — frontend não bate com backend em vários endpoints |
| **`AdminLayout` vs `ConsultorLayout`** quase idênticos com paleta diferente | Deduplicar via `<AppLayout role accent menuConfig />` parametrizado |
| **`figma:asset/...png` import órfão** | Asset Figma Make não-resolvível fora do runtime Figma. Substituir por path real em `/public/` |
| **`/utils/supabase/info` virtual import** | Provido pelo runtime Figma Make. Migrar pra `import.meta.env.VITE_SUPABASE_*` (já fizemos no stub atual) |
| **Filtros por `mecanico_nome` (string) em vez de FK `mecanico_id`** | Padrão recorrente no DoctorAuto. Frágil. Normalizar |
| **Pages-clones literais** (Avaliacoes/Reclamacoes/Sugestoes idênticos; Vendas/Comissões idênticos) | Consolidar em 1 page com dimensão `tipo` |
| **`AdminContasPagar` com filtro `eq aprovado`** | Errado semanticamente: "contas a pagar" deveria ser despesas com fornecedor, não OS aprovadas aguardando execução |

### F.3 — Convenções a abandonar

| Antipattern | Por que |
|---|---|
| **Prefixo numérico em nome de tabela** (`00_companies`, `06_OS`, `97_RECUSAS`) | Mistura UPPERCASE + snake_case. Padrão `oficina.service_orders` é mais limpo |
| **Stack drift** entre Lovable Cloud → MySQL+tRPC → Supabase em 3 meses | Documentar a decisão atual (Supabase + Drizzle + Express) e parar de oscilar |
| **Schema dual** `10_users` (legado) ↔ `01_colaboradores` (novo) coexistindo | Migrar pra um único — `users` em `oficina` + RLS por org |
| **8 IAs verticais nomeadas** (DoctorScan/AutoCall/PrimeChat/DataPrime/AgendaPro/AlertaMaster/PrecificaAI/QualityCheck) | Já abandonado pelo próprio protótipo — agora 3 agentes orquestrados (Sophia/Simone/Raena) → mapear pros agentes DAP reais (Sophia/Anna/Walter) |
| **Roles divergindo** entre 4/3/6 níveis em docs diferentes | RBAC canônico: `@dap/aios-schema/rbac.ts` (9 roles) — única fonte da verdade |

---

## G. Veredicto consultor archive

**Status:** `C:\THALES\_archive\dap-tools-untracked-2026-05-06\apps\consultor\` — Gemini Antigravity, 14 pages, 3.5k linhas, mock auth bypass, dev server roda em :5174 (mas tá parado agora).

**Cobertura cruzada com DoctorAuto:**
| consultor archive page | Equivalente DoctorAuto | Veredicto |
|---|---|---|
| `Login.tsx` | `Login.tsx` (DoctorAuto, mais maduro) | descartar |
| `Dashboard.tsx` | `Dashboard.tsx` | descartar |
| `Clientes.tsx` + `ClienteDetalhe.tsx` | `AdminClientes.tsx` + `AdminClienteDetalhe.tsx` | descartar |
| `OrdensServico.tsx` + `OsDetalhes.tsx` + `NovaOS.tsx` (655 linhas) | `AdminOrdensServico.tsx` + `AdminOSDetalhes.tsx` + `AdminNovaOS.tsx` | descartar (DoctorAuto NovaOS é menor mas idiomático Supabase) |
| `Agendamentos.tsx` | `AdminAgendamentos.tsx` (mais completo, multi-tenant) | descartar |
| `PatioKanban.tsx` | `PatioKanban.tsx` (DoctorAuto, com mapa de recursos) | descartar |
| `Mecanicos.tsx` | `MecanicoView.tsx` + GestaoRH | descartar |
| `MecanicoPortal.tsx` + `MecanicoFinalizados.tsx` | `MecanicoView.tsx` + aios/modules/mecanico | descartar |
| `GestaoDashboard.tsx` | `GestaoDashboards.tsx` | descartar |
| `VisaoGeral.tsx` | `Dashboard.tsx` | descartar |

**Conclusão:** **delete safe.** Zero feature única. Pode remover `C:\THALES\_archive\dap-tools-untracked-2026-05-06\apps\consultor\` (o tarball `.tgz` de safety já existe em `_archive` desde 2026-05-06, e o tar pode ser removido também depois desta nota).

---

## H. Próximos passos concretos

### H.1 — Esta semana (3 ações)

1. **Arquivar DoctorAuto como read-only.** Mover `C:\THALES\DoctorAuto\` → `C:\THALES\_archive\DoctorAuto-2026-05-09\`. Manter `src/imports/MAPA_*` + os 5 PDFs do worktree `sad-keller` como input pra próxima fase.
2. **Deletar consultor archive.** `C:\THALES\_archive\dap-tools-untracked-2026-05-06\apps\consultor\` + tarball `dap-tools-untracked-2026-05-06.tgz`.
3. **Atualizar plano monorepo** `C:\THALES\DAP4\docs\superpowers\plans\2026-05-06-dap4-monorepo-migration.md`:
   - Adicionar **Fase 9 — apps/admin** (5° app: opção C ao plano original)
   - Adicionar **Fase 10 — Schema Expansion** (Tier 1 das tabelas em D.1: pendencias, service_order_history, recursos, mechanic_daily_feedback, notifications, agendamentos_recusas, quote_public_tokens)
   - Atualizar Task 3.3 `@dap/db` com a lista de tabelas consolidada (D.1 + D.2 + D.3 + D.4)
   - Atualizar Task 3.5 `@dap/agents` com referência a `agent_configs`/`agent_runs`/`agent_metrics`

### H.2 — Próximo mês (4 sprints)

- **Sprint 1:** Tier 1 itens 1-4 (status hex, pendencias, wizard NovaOS, Confirmar Chegada → cria OS) em `apps/operacao`
- **Sprint 2:** Tier 1 itens 5-7 (ClienteDetalhe, PatioKanban com recursos, AdminAgendamentos com IA-loop)
- **Sprint 3:** Tier 2 item 8 (orçamento público assinado) + item 9 (multi-tenant correto via JWT)
- **Sprint 4:** Tier 2 itens 10-14 (notifications, GestaoVisaoGeral, GestaoFinanceiro, AnalyticsLTV, AnalyticsChurn) em `apps/gestao`

### H.3 — Próximo trimestre

- Tier 3 itens 15-20 — `apps/admin` novo + DevPerfilIA + Kommo wire-up + GestaoVeiculosOrfaos + GestaoRH + DevDashboardIA
- **Próxima mineração:** ler os 5 PDFs do worktree `sad-keller` (`Manual_Operacional_Completo`, `Processo_Vendas_Online_v2`, `Boas_Praticas_Patio`, etc) — alimentar `@dap/agents` RAG. Esses PDFs são a fonte original do que apareceu nos MAPAS.

---

## I. Apêndice — fonte da mineração

### I.1 — Agents executados em paralelo

| Agent | Cobertura | Output linhas |
|---|---|---:|
| `a0346b5def25cdfe7` | Inventory `admin/` (32 pages) | ~410 |
| `a9c433779b5a99813` | Inventory `gestao/+analytics/` (17 pages) | ~210 |
| `a41445310c7241b59` | Inventory `dev/+top-level` (30 pages) | ~330 |
| `a56f958a157f0e71f` | Infra/components/services/supabase | ~250 |
| `a10d425a489c69e60` | MAPAS + docs internos (10 MDs + CSV + 5 PDFs categorizados) | ~360 |
| `a40ac1312d03d7ae2` | dap4-portals current state (5 apps + 7 packages) | ~280 |

### I.2 — Arquivos de origem inventariados

**DoctorAuto (`C:\THALES\DoctorAuto\`):**
- 32 pages em `src/app/pages/admin/`
- 12 pages em `src/app/pages/gestao/`
- 5 pages em `src/app/pages/analytics/`
- 12 pages em `src/app/pages/dev/`
- 18 pages top-level em `src/app/pages/`
- 4 layouts em `src/app/components/`
- 48 shadcn components em `src/app/components/ui/`
- 1 services API (`src/app/services/api.ts`)
- 1 edge function (`supabase/functions/server/index.tsx` — 804 linhas)
- 1 migration SQL
- 10 MDs + 1 CSV em `src/imports/`
- 5 PDFs em `.claude/worktrees/sad-keller/`
- 4 MDs raiz (`CORRECOES_APLICADAS`, `EMPRESA_TOGGLE_GUIA`, `EXEMPLOS_INTEGRACAO`, `IMPLEMENTACAO_SEGMENTACAO_OFICINA`)

**Consultor archive (`C:\THALES\_archive\dap-tools-untracked-2026-05-06\apps\consultor\`):**
- 14 pages em `src/pages/`
- 2 layouts (`ConsultorLayout`, `MecanicoLayout`)
- 4 lib files (`authService`, `mockData`, `supabaseClient`, `utils`)

**dap4-portals (`C:\THALES\DAP4\dap4-portals\`):**
- `apps/aios/` (consultor + mecanico + cliente + chairman)
- `apps/aios-mandala/` (HTML estático D3.js)
- `apps/operacao/` (Vite+Express, 117 testes, master `1a74196`)
- `apps/gestao/` (shell + WipPanels)
- `apps/tools/` (HTML estático + playbooks + planilhas)
- `packages/{config,types,ui,db,auth,agents,kommo}` (7 packages)

### I.3 — Documentos relacionados no vault

- `001-dap40-master-todo.md` — TODO mestre (atualizar com Tier 1-3)
- `002-dap40-rota-estrategica.md` — rota estratégica
- `003-dap40-dores-e-legado.md` — dores que esta mineração endereça (lead/permanência/conversão)
- `005-dap-calendario-anual-mkt.md`
- `008-dap-whatsapp-kommo-playbook.md` — relacionado ao Kommo wire-up Tier 3
- `014-dap40-roadmap-30d-sistema-pessoal.md`
- Plano fonte: `C:\THALES\DAP4\docs\superpowers\plans\2026-05-06-dap4-monorepo-migration.md`
- Plano sequencial: `C:\THALES\DAP4\docs\superpowers\plans\2026-05-08-aios-crm-prod-rollout.md`

### I.4 — Memory updates pendentes

- **Atualizar** `project_dap_portal_architecture.md` (memory): refletir decisão `apps/admin` como 5° app
- **Criar** `feedback_doctor_auto_blueprint.md` (memory): user prefere mineração estruturada > fork + run direto, quando confronta protótipo design-to-code com codebase real
- **Atualizar** `project_dap_tools_real.md` (memory, já feito em 2026-05-06): reafirmar `apps/`/`autodiag/`/`DAP4.0/` nunca foram parte do repo
