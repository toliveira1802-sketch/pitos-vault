---
type: handoff-bridge
date: 2026-05-19
time: "04:30"
project: dap-aios
topic: Bridge handoff pra claude.ai — tela de detalhe da OS no portal Consultor com itens + ações
tags: [handoff, claudin, dap-aios, os-detail, consultor, bridge]
---

# Bridge handoff — Gerar spec da tela de detalhe da OS (portal Consultor)

> **Pra quem é isso:** Thales vai abrir o claude.ai no browser, colar este doc + as **telas/mockups que ele já tem da página**, e pedir pro Claude (web) gerar um prompt completo de spec pra rodar no Claude Code local depois.

## Contexto rápido (zero suposição)

- **Projeto:** Doctor Auto AIOS — plataforma operacional da oficina premium Doctor Auto Prime
- **Repo local:** `C:\THALES\DAP4.0\dap-aios`
- **Stack:** pnpm monorepo · React 18 + Wouter (hash routing) · Express 5 + TypeScript · SQLite local (better-sqlite3) · Drizzle ORM · Supabase Auth real · TanStack Query · Tailwind · Lucide React · Playwright local
- **Paleta DAP:** dark (canvas/ink-900) + acento vermelho `#E24B4A` (paper-* pra textos)
- **Branch atual:** `feat/r15-role-switcher-polish` (R15 mergeada na main em sessão recente, PR #4 ainda aberta com bug de role-override pendente)
- **Idioma:** comentários e UI em PT-BR; código, nomes de variável e rotas em inglês

## Estado das rodadas (resumo de 1 linha cada)

- **R9** entregou Portal Mecânico — Pátio Kanban técnico + OS Detail em `/mecanico/os/:id` (status técnico + diagnóstico + checklist + transições)
- **R10** Supabase Auth real + role-switcher dev pra admin simular outras roles
- **R11/R11.1** Wizard Nova OS (3 passos: cliente → veículo → detalhes) + ficha cliente
- **R12** commercial_status no schema + máquina comercial + 4 telas (OS abertas / Pátio Kanban comercial / Dashboard Operação / Histórico)
- **R13** Refator Sidebar do Portal Consultor (caminho A — sidebar por-portal) + 5 stubs "Em breve" + Nova OS modal global
- **R14** Dashboard visual do Consultor (4 KPIs + 4 áreas → stubs + mapa pátio v10) + sino topbar
- **R15** Polish role-switcher + pill flutuante `RoleOverrideBadge`

## O que funciona hoje no Portal Consultor

```
/consultor              → Meu DAP (stub <EmBreve>)
/consultor/dashboard    → Dashboard visual (R14)
/consultor/inbox        → Chat / atendimento
/consultor/leads        → Funil de leads
/consultor/clientes     → CRM + ficha cliente (3 abas, edit modals)
/consultor/propostas    → Quotes + convert→OS + margin inline
/consultor/os           → Lista de OS abertas (filtros + paginação + busca)
/consultor/patio        → Kanban comercial 8 etapas (commercial_status)
/consultor/historico    → OS encerradas
```

Modal "Nova OS" é global (`useNewOsModal()` hook desde R13) e dispara wizard 3 passos. Ao concluir, **navega pra `/mecanico/os/:id`** (rota do OS Detail do Mecânico).

## O QUE FALTA (a coisa que o Thales quer)

**Anna (consultor real) consegue abrir OS pelo wizard**, mas **não tem uma tela própria de detalhe da OS dentro do portal Consultor**. Hoje:

- Clica numa OS na lista `/consultor/os` ou no kanban `/consultor/patio` → cai em `/mecanico/os/:id` (visão do mecânico — diagnóstico técnico, checklist, máquina de estados técnica)
- **Sem visão comercial da OS** com itens (peças/mão de obra), valores, margem, status comercial, próximas ações, histórico de transições, observações ao cliente

A última tela do fluxo que Thales tem mockup é justamente essa: **`/consultor/os/:id`** — detalhe da OS na ótica do **consultor**, não do mecânico.

### O que essa tela provavelmente precisa mostrar (a confirmar pelas telas do Thales)

- Cabeçalho: código OS · cliente · veículo · status técnico + status comercial + prioridade
- **Itens da OS** (peças, mão de obra, descontos) — hoje só `quote_items` na tabela `quotes`. Service order não tem items próprios. **Pergunta de spec:** items vêm da quote vinculada (`quoteId`) ou OS sem quote tem items diretos? Provavelmente novo schema `service_order_items` ou reuso de `quote_items`.
- Valor total · margem (calculator R7 — `marginCalculator` já existe)
- Histórico de mudanças (event log existe — `events` table)
- Ações: trocar status comercial · adicionar item · gerar quote · imprimir · enviar pro cliente
- Observações internas vs observações ao cliente

### Schema relevante hoje

- `service_orders` (R9 + R12) — tem `status` técnico + `commercialStatus` comercial + `quoteId` opcional + `customerId` + `vehicleId` + `assignedAdvisorId` + `assignedMechanicId` + `complaint` + `diagnosisNotes` + `checklist` (JSON) + `notes`
- `quotes` + `quote_items` — quote items são `{kind: 'part'|'labor', description, qty, unitCents, totalCents, sortIndex}`. Total da quote = soma dos items
- `events` — log universal (`{actor, entityType, entityId, action, payload}`)

### Pendência aberta crítica

- **Bug R15:** role-override ativo não está fazendo backend respeitar a role (hipótese: `requireAuth` em modo Supabase ignora `x-aios-role-override`). Não bloqueia esta rodada porque Anna entra como **consultor real** (não via override) — login direto com `anna@doctorautoprime.com` funcionando agora.
- **Seed permission gap:** SQLite local tem patch manual pra `users:read` + `service_orders:write` no consultor (faltava no seed.ts). Quando rodar `pnpm db:seed`, regride. Spec da próxima rodada pode incluir fix permanente no seed.

## Restrições gerais (manter sempre)

- **Não** mexer em backend desnecessariamente — preferir endpoint novo a refator de existente
- **Não** quebrar Pátio R12, Dashboard R14, Wizard Nova OS R11
- **Não** mexer em Portal Mecânico (`/mecanico/*` é território da R9)
- **Não** introduzir biblioteca de form/state grande — Tailwind + React state local + TanStack Query basta
- Manter paleta DAP existente (dark + accent vermelho)
- Dinheiro sempre em **centavos integer** (zero float)
- IDs com nanoid em todas as tabelas
- Hash routing no client (`/#/consultor/...`)
- Permissões granulares no server via `requirePermission(resource, action)`

## O que pedir pro claude.ai (web) gerar

Cole este doc + suas screenshots/mockups da página, e peça algo como:

> "Com base nessas telas e no contexto acima, gera um prompt de spec completo pra eu rodar no Claude Code (CLI local) implementar a rota `/consultor/os/:id` no Doctor Auto AIOS. Spec deve incluir: passo 0 inventário obrigatório, decisões já tomadas (não reabrir), escopo técnico em passos numerados, arquivos esperados (criados/alterados), restrições, critérios de aceite, sugestão de commit, formato de handoff final. Padrão idêntico aos handoffs R13/R14/R15 que já existem no repo."

Claude.ai vai gerar a spec lendo as telas + esse contexto + extraindo o que precisa virar API nova vs UI nova.

## Próximos passos esperados (depois que claude.ai gerar a spec)

1. Thales cola a spec resultante no Claude Code (sessão local no repo)
2. Claude Code inventaria (sempre passo 0 antes de codar) e reporta
3. Thales aprova ou ajusta
4. Implementação + handoff R16 (ou R15.1 dependendo do nome)

---

**Arquivos de referência no repo (pra claude.ai NÃO precisa abrir — só pra Thales colar trechos se faltar contexto):**

- Stack/decisões: `CLAUDE.md` na raiz
- Handoff anterior mais completo: `handoff-aios-rodada14-dashboard-consultor.md`
- Briefing universal: `handoff-proxima-sessao.md`
- OS Detail do Mecânico (referência de UI da OS): `client/src/modules/mecanico/pages/OsDetailPage.tsx`
- Schema service_orders: `packages/types/src/schema/service-orders.ts`
- Schema quotes/items: `packages/types/src/schema/consultor.ts`
- Modal Wizard Nova OS: `client/src/modules/consultor/components/NewServiceOrderModal.tsx`
