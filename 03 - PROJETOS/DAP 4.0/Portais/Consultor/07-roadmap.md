---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-operacao/README]]"
tags:
  - dap40
  - roadmap
  - sprints
---

# Roadmap — DAP Operação

> Ordenado por **valor para o negócio**, não por dificuldade técnica. Cada sprint tem uma única tese: o que o portal precisa pra dar o próximo salto.

## Tese geral

O dap-operacao está **vivo em produção** mas hoje é blueprint, não diferencial. As próximas 6 sprints transformam ele em um sistema que o time da DAP usa porque é melhor que o legado, não porque é obrigatório. A trilha é:

1. **Estabilidade** — não pode cair, não pode perder dado
2. **UX premium** — visual digno do padrão Apple/Linear referenciado no CLAUDE.md
3. **Comercial AI v1** — o gancho real pra leads e adormecidos
4. **Timeline v2** — Gantt com dado real, não heurística
5. **WhatsApp** — fechamento do loop comercial
6. **Mobile/Field** — técnico opera do celular no boxe

---

## Sprint 1 — Estabilidade & segurança operacional (1 semana)

**Tese**: Antes de adicionar feature, garantir que o que existe não quebra.

### Entregas
- [ ] **Healthcheck endpoint** `GET /api/health` (zero side-effect, sem auth, retorna `{ status: "ok", uptime, version }`)
- [ ] **Backup automático diário** do `oficina.db` via cron na VPS → snapshot rotativo de 30 dias
- [ ] **Logrotate** dos uploads — limpar attachments de OSs deletadas há > 90 dias
- [ ] **Rotação da senha admin inicial** (`isDMNt2e32KYz4pBNVlQ`) + remoção do `BOOTSTRAP_ADMIN_PASSWORD` do `.env` da VPS após primeiro acesso
- [ ] **Cache headers Cloudflare** pra `/assets/*` com hash → `public, max-age=31536000, immutable` (50% economia de banda em retorno)
- [ ] **Suite de testes de invariantes** (Vitest property-based): as 7 invariantes do [[06-regras-negocio#Invariantes do sistema]] como testes que rodam no CI
- [ ] **Sentry ou erro-tracker leve** — capturar 5xx em produção (CSP-friendly: `connect-src` da Sentry adicionado)

### Critério de aceite
- VPS reinicia (kill -9 no node) e systemd recoloca em < 5s
- DB corrompe e backup do dia anterior restaura em < 2min
- Healthcheck retorna 200 e é monitorado por uptime-robot externo

---

## Sprint 2 — Design system premium (1-2 semanas)

**Tese**: O thales não aceita interface de template. Transformar de "shadcn default" pra "DAP Prime cinematográfico".

### Entregas
- [ ] **Theme dark-first** com paleta cinematográfica (preto profundo, accent platina/dourado pelo segmento premium alemão)
- [ ] **Tipografia editorial** — pair de display + sans (sugestão: Inter Display + Inter, ou GT Walsheim + IBM Plex Sans)
- [ ] **Tokens CSS custom properties** em `client/src/styles/tokens.css` (cores OKLCH, espaçamento clamp, motion easing)
- [ ] **Sidebar redesign** — colapse, hover states, active state com gradient sutil
- [ ] **Cards de OS premium** — depth via shadow + border + glass overlay, hierarchy clara
- [ ] **Empty states ilustrados** (não placeholder texto seco)
- [ ] **Microanimações** — page transitions, list reorder, status change celebration (framer-motion já no bundle)
- [ ] **Loading states** que não são spinner genérico

### Critério de aceite
- Screenshot lado-a-lado: hoje vs depois → não parece o mesmo produto
- Reviewer Apple/Linear-aficionado aprovaria
- Zero `bg-card` defaults sem intenção
- Lighthouse Accessibility ≥ 95

---

## Sprint 3 — Comercial AI v1 (2 semanas)

**Tese**: É o gancho que transforma o portal de "ferramenta de operação" em "ferramenta de crescimento". CLAUDE.md fala que gargalos são lead, conversão e tempo de permanência — Comercial AI ataca os 2 primeiros.

### Pré-requisitos
- LLM API key (Anthropic ou OpenAI) na `.env`
- Tabela `leads` no schema (nova entidade)
- Conexão com Kommo CRM (token já existe no env do P1, replicar)

### Entregas

#### Schema
- [ ] Tabela `leads` (id, organizationId, name, phone, email, source, brand_interest, value_estimate_cents, status, created_at, last_contacted_at, lost_reason, customer_id?)
- [ ] Tabela `lead_interactions` (id, lead_id, kind: call|whatsapp|email, outcome, notes, created_at)
- [ ] Sync de leads do Kommo → tabela local (job hourly)

#### Avaliação CRM (`/comercial/crm`)
- [ ] Score 0–100 por consultor (5 componentes ponderados — ver [[06-regras-negocio#R-CRM-2]])
- [ ] Tendência semanal (sparkline)
- [ ] 3 ações sugeridas pela IA (geração com contexto via Claude)

#### Leads pra Ligar (`/comercial/leads`)
- [ ] Job 7h calcula top 20
- [ ] Card por lead: foto WhatsApp, score, gancho sugerido, janela ideal
- [ ] Botão "ligar" abre `tel:` + log + outcome modal
- [ ] Aprendizado: outcome alimenta peso do score

#### Clientes Adormecidos (`/comercial/adormecidos`)
- [ ] Lista clientes sem OS > 180 dias, com receita potencial
- [ ] Geração de mensagem personalizada por IA (revisão obrigatória admin antes de envio)
- [ ] Tracking: aberto/respondido/agendado/fechado

### Critério de aceite
- Score CRM bate com cálculo manual em 3 amostras
- Top 20 leads do dia é defendido por dado, não palpite
- Mensagem de adormecido passa em "soa o thales falando"

---

## Sprint 4 — Timeline v2 (1 semana)

**Tese**: Hoje a Linha do Tempo usa heurística genérica. v2 usa dado real da própria oficina e vira ferramenta de gestão de gargalo.

### Entregas
- [ ] Endpoint agregado `GET /api/telemetry?status=active` (sem `:id`) — retorna telemetry de todas OSs ativas em 1 chamada
- [ ] Renderização de **barra realizada segmentada por etapa** (cores intercaladas mostrando onde demorou)
- [ ] **Heurística calibrada com histórico**: substitui as durações fixas (8h, 12h, 4h…) pela mediana das últimas 30 OSs entregues
- [ ] **Indicador de gargalo** — OS travada > X horas no mesmo status fica com borda vermelha pulsante (limites por status)
- [ ] **Drill-down**: click na barra abre modal com timeline detalhada da OS (status changes + comments)
- [ ] Filtro por consultor + por mecânico
- [ ] Export CSV do estado atual

### Critério de aceite
- Quando uma OS demora > 2× a mediana num status, fica visível
- Heurística atualiza diariamente (job)
- Performance: 50 OSs ativas renderizam em < 300ms

---

## Sprint 5 — WhatsApp Cloud API (2 semanas)

**Tese**: Fecha o loop comercial e operacional. CLAUDE.md fala "Meta Business — A configurar — WhatsApp Cloud API (2 linhas: Bosch + Prime)".

### Pré-requisitos
- Conta Meta Business + 2 linhas verificadas (Bosch + Prime)
- Templates de mensagem aprovados pela Meta (24h fora de janela só permite template)
- Webhook URL pública (já tem com Cloudflare Tunnel)

### Entregas
- [ ] Integração `@meta/whatsapp-cloud-api-sdk` (ou similar)
- [ ] Webhook receiver `POST /api/whatsapp/webhook` (verifica HMAC)
- [ ] **Confirmação de agendamento automática** — 24h antes do horário, dispara template
- [ ] **Notificação de status crítico** — OS muda pra `pronto`, dispara mensagem com link pra cliente confirmar entrega
- [ ] **Disparo de adormecidos** — fila aprovada vira batch via API (rate limit Meta)
- [ ] **Inbox unificada** — mensagens recebidas aparecem no portal por OS/cliente, com possibilidade de responder
- [ ] Atribuição de mensagem entrante a OS aberta automaticamente (match por `customer.phone`)

### Critério de aceite
- Cliente recebe lembrete e responde "confirmo" → appointment.status muda automaticamente
- Adormecido recebe template + mensagem custom da IA → tracking dispara
- 0 mensagens perdidas em 1 semana de testes

---

## Sprint 6 — Mobile / Field (técnico no boxe) (1 semana)

**Tese**: Hoje o portal é desktop-first. Técnico no boxe não tem desktop. Mobile-first nas 3 telas críticas pro técnico.

### Entregas
- [ ] **Página `/orders/:id` mobile-optimized** — bottom sheet modular pros 8 cards de OS
- [ ] **Câmera do celular direto pra attachments** — drag-and-drop substituído por `<input capture="environment">`
- [ ] **Voz pra texto no diagnóstico** — Web Speech API pra ditar diagnóstico (técnico de mão suja)
- [ ] **Pátio mobile** — colunas verticais ao invés de horizontais
- [ ] **PWA** — manifest.json + service worker pra instalar como app
- [ ] **Offline minimal** — última lista de OS atribuídas cacheada, possibilita visualização sem rede

### Critério de aceite
- Técnico abre OS, fotografa peça, salva, muda status — tudo do iPhone, sem desktop
- Lighthouse PWA ≥ 90
- Funciona em 4G fraco da oficina (testar com throttle)

---

## Backlog (não priorizado ainda)

- Multi-org real (Prime + Performance + Project com troca dropdown)
- Relatórios PDF agendados (DRE mensal pro chairman)
- Integração com Bosch SIS (catálogo de peças oficial)
- Cobrança recorrente via PIX recorrente (Banco Central)
- ChatGPT integrado em `/orders/:id` ("o que esse código de erro significa?")
- Audit log queryable em UI (página `/audit`)
- Versionamento do schema com auto-migration safety (drizzle migration check)
- Replicação SQLite → S3 (litestream)
- A11y pass completo (atalhos, ARIA, contrast WCAG AAA)
- Internacionalização (preparado pra português Portugal e espanhol)

---

## Princípios pra priorizar

1. **Negócio primeiro**: feature que move R$ (lead, conversão, ticket médio) ganha de feature que move conforto técnico.
2. **Estabilidade nunca espera**: bug em produção tem prioridade absoluta sobre roadmap.
3. **UX é restrição, não fase**: cada sprint sai com qualidade visual, não "depois a gente arruma".
4. **Reuso > novo**: se Comercial AI puder usar a mesma stack do Operação (mesmo Drizzle, mesma sidebar, mesmo padrão de WIP), reusa.
5. **Testar pra valer**: invariantes do [[06-regras-negocio]] viram testes property-based no CI.
6. **Transparência radical**: roadmap fica neste doc + Notion + GitHub Projects, atualizado a cada sprint.

---

## Métricas de sucesso (north-star)

| KPI                              | Hoje (estimativa) | 6 meses | 12 meses |
| -------------------------------- | ----------------- | ------- | -------- |
| Faturamento mês                  | ~R$ 300k          | R$ 500k | R$ 700k+ |
| OS/mês                           | ~50               | 80      | 120      |
| Capacidade elevadores            | 45%               | 70%     | 90%      |
| Tempo médio de permanência       | ? (medir)         | -20%    | -30%     |
| Conversão orçamento → OS         | ? (medir)         | +15pp   | +25pp    |
| Taxa de reativação adormecidos   | 0% (manual)       | 8%/mês  | 15%/mês  |
| NPS pós-entrega                  | ? (medir)         | 60+     | 75+      |
