---
type: roadmap
project: dap4
window: 2026-04-15 → 2026-05-15 (30d)
status: draft
framing: sistema pessoal, sem monetização
author: Claudin (subagent #5)
---

# Roadmap 30d DAP 4.0 — Sistema Pessoal

## Tese

Em 30 dias o DAP 4.0 passa de "coleção de artefatos com Parliament shippable e Anna parcialmente codada" para **ferramenta pessoal que o Thales usa toda segunda-feira pra operar a oficina**. A sequência é: Anna no ar atendendo lead real via Kommo Hub (semana 1-2) → Command Center usável como cockpit diário do Thales (semana 3) → endurecer infra e dívida que passou a doer (semana 4). Não se toca em novo diretor, em extração Chairman OS, em expansão Sennin, em lançamento. Cada semana entrega uma capacidade concreta que o Thales não tinha na segunda — se no domingo ele não consegue descrever o ganho operacional em uma frase, a semana derrapou. Valor operacional dita prioridade; tudo que for vitrine (slide, demo, onboarding, polish de marketing) está fora.

## O que fica de fora (explícito)

- Nenhum trabalho voltado pra lançamento, marketing, venda, soft-launch, evento.
- Nenhum onboarding, billing, landing page, pricing page, growth loop.
- Nenhum diretor novo do Parliament (Bianca, Marta, Rafael, Claudio, Thamy, Walter, Marcia) até Anna fechar ciclo completo de produção com volume real.
- Nenhuma extração de Parliament/Chairman OS pra repo separado — fica in-place em `C:\dev\dap4\agents\parliament\` o mês inteiro.
- Nenhuma evolução de Sennin Protocol (baseline meta, hooks novos, C-Level v3). Sennin é OS pessoal e está servindo; não é o gargalo.
- Nenhum trabalho em DAP Performance, DAP Studio, DAP Social, DAP Ensina, DAP Consultoria — todas as unidades secundárias ficam paradas.
- Nenhum redesign geral de dashboard. Ajustes cirúrgicos só onde o Command Center exige.
- Nenhum refactor "estrutural" que não tenha trigger claro (ex: monorepo layout, migração de package manager).
- Thales Agent (P3) continua pausado.

## Semana 1 (15-21/abr) — Anna no ar em ambiente real

**Tema:** fechar o loop Kommo → Anna → lead → escalação, ponta-a-ponta, com 1 lead real de verdade.

- [ ] M0 do spec Kommo Hub: Thales cola `KOMMO_TOKEN`, `KOMMO_DOMAIN`, `KOMMO_CHATS_CHANNEL_SECRET`, `KOMMO_THALES_USER_ID` no `.env`. Claudin mapeia shape real com curl e commita fixtures em `agents/tests/fixtures/kommo/`. **Critério:** 3 payloads reais versionados (message::added, lead::add, lead::status_changed).
- [ ] M1 migrations Supabase: `anna_inbox`, `anna_conversations`, extensões em `leads` (tenant_id, kommo_lead_id, channel, is_german_premium, funnel_stage, last_anna_turn_at). **RLS por tenant_id ligada desde já.** Seed de 1 lead dummy. **Critério:** migração aplicada em prod (`acuufrgoyjwzlyhopaus`), rollback scriptado.
- [ ] M2 Gateway Kommo: `kommo.service.ts` (send/update/note/assign) com token bucket 7 req/s, `X-Request-Id` em todo write, sanitizer de logs pra `Bearer`. `kommo-webhook.routes.ts` com HMAC validate + enqueue em `anna_inbox` via `ON CONFLICT DO NOTHING`. **Critério:** vitest cobrindo happy path + HMAC inválido + duplicado + rate-limit throttle.
- [ ] M3 worker `anna-inbox`: `SELECT FOR UPDATE SKIP LOCKED`, NOTIFY-trigger + poll 5s fallback. Porta `handleAnnaResult` do meta-webhook pra `gateway/src/services/anna-result-handler.ts`. **Critério:** 3 cenários E2E verdes (continuing, qualified, escalated) com fixtures M0.
- [ ] Deploy staging na VPS em `/opt/doctor-auto-ai/` via compose. CNAME `webhook.dap.doctorautoprime40.com` apontado no Cloudflare.

**Saída da semana:** domingo 21/abr o Thales manda uma mensagem pro WhatsApp DAP Prime +5511917001822 e a Anna responde em <30s, classificando o carro, e escalando pro celular dele (+5511967291822) com gatilho de palavra-chave. Nada perdido na fila. 1 lead de verdade (amigo, colaborador, cliente recorrente) passou pelo loop completo.

## Semana 2 (22-28/abr) — Anna operando de verdade, com rede de segurança

**Tema:** fechar gaps que separam "funciona no smoke test" de "roda 24/7 sem o Thales olhar".

- [ ] M4 escalação full: `assignResponsible(thales_user_id)` + tag `escalated_anna` + nota + WhatsApp cortesia pro Thales via Kommo + Socket.IO emit `anna:escalated` pro dashboard. **Critério:** um escalated real dispara 3 notificações sincronizadas.
- [ ] M5 observability mínima: pino structured logs com `trace_id` propagado do webhook até egress. Prom-client com 5 métricas (`anna_first_response_seconds`, `anna_escalation_total{reason}`, `anna_confidence`, `kommo_api_errors_total`, `anna_inbox_lag_seconds`). Página `/admin/anna` no dashboard: timeline de turns + confidence sparkline + painel de escalações abertas.
- [ ] Guardrail pós-LLM: regex whitelist de termos proibidos (`R\$|\d+\s*dias?|garantia`) — match força escalated. Regex `\[STATUS:\]` obrigatória, 2 falhas consecutivas = escalated.
- [ ] Typing delay humanizado + cap diário de 150 msg/número pra mitigar ban-risk Kommo WhatsApp provider.
- [ ] M7 smoke produção: 10 leads reais em 24h rolando pela Anna. Reconciliação `anna_inbox` vs lista Kommo (zero mensagem perdida). Thales assina go-live operacional interno.
- [ ] Dívida cirúrgica: HMAC verification nos webhooks legados (Kommo v4 CRM), sanitizer de secrets no logger global, Zod validation nas POSTs `insights.routes.ts` + `ingest.routes.ts:/file` (pendência #3 do dap4.md).

**Saída da semana:** segunda 29/abr o Thales abre o celular, vê 3 escalações noturnas da Anna em Kommo com motivo anotado, e entra pronto. Anna rodou a noite inteira sem ele.

## Semana 3 (29/abr–5/mai) — Command Center usável como cockpit diário

**Tema:** transformar Lead Command Center (plano de 04/04, incompleto) em tela que o Thales abre toda manhã.

- [ ] Tasks 1-6 do plan `2026-04-10-lead-command-center.md`: api namespace `leads`, gateway `leads.store.ts` + `leads.routes.ts` (5 endpoints), `LineFilter`, `TemperatureGauge`, `LeadPipeline`, `WaitingQueue`, `BeforeAfter`. **Critério:** rota `/leads` serve dashboard com dados reais do Supabase (não stub).
- [ ] Integração Anna: `WaitingQueue` reflete `anna_inbox` em tempo real via Socket.IO. Card de escalação abre contexto Anna (últimos 5 turns + motivo) inline, sem sair da tela.
- [ ] Tasks 7-9: `LeadDashboard` + `LeadContextCard` + refactor `ConversationView` (ex-WhatsApp.jsx) + `LeadCommandCenter` page, route `/leads` no main.jsx, nav "Command Center" no Layout. Aposentar rota `/whatsapp`.
- [ ] Hardcoded baseline do `BeforeAfter` (before = `4h/8/12%/45/3dias`) → mover pra tabela Supabase `kpi_baseline` (tenant_id=dap_prime). Thales pode editar direto no Supabase Studio sem deploy.
- [ ] Substituir monograma "D" temporário por identidade visual real (pendência #9). Nada grande — logo + favicon.

**Saída da semana:** segunda 6/mai o Thales abre `/leads` às 8h e em 15 segundos sabe: quantos leads na fila, qual o mais frio/urgente, qual a conversão 24h vs 30d, onde Anna travou durante a noite. Substitui 3 abas do Kommo + planilha de controle.

## Semana 4 (6-12/mai) — Endurecer o que passou a doer

**Tema:** pagar dívida que a operação real de 2 semanas expôs. Thales não quer mais mexer em bug de infra antes de tomar café.

- [ ] **Testes gateway:** subir de 6 vitest pra 40+. Prioridade: HMAC handler Kommo, worker anna-inbox, result handler, rate limit. Meta: cobertura gateway ≥60% (pendência #7).
- [ ] **Testes agents:** endpoint Anna chat com TestClient FastAPI, parser `[STATUS:]`, classificador alemão premium (whitelist + confidence). Ana/Sofia/Thales/Insights stubs seguem sem teste — estão congelados.
- [ ] **RLS audit Supabase:** `leads`, `anna_conversations`, `anna_inbox`, `ordens_servico`, `clients`, `vehicles`, `colaboradores` — todas com policy por `tenant_id` + role. Rodar `mcp__Supabase__get_advisors` com type=security, fechar tudo que vier HIGH/CRITICAL.
- [ ] **ESLint + Prettier + Ruff configurados e plugados em PostToolUse hook** (pendência #8). Zero lint failure em master.
- [ ] **Deletar `dashboard/agents/`** num commit isolado destrutivo (pendência #1, arrastada desde 09/04).
- [ ] **Token budget global + kill-switch** (pendência #5): env `MONTHLY_LLM_BUDGET_USD`, contador em Supabase `llm_usage`, alerta 80%/100%, kill-switch que força Anna a responder "estou sobrecarregada, volto em instantes" e escala.
- [ ] Parliament: **não tocar**. Francisco/Pitoco/Zoraide seguem com prompts Phase 1 limitados. Decisão: endurecer só quando Anna gerar 20+ escalações que peçam deliberação real (isso é Phase 1b, fora da janela).

**Saída da semana:** 13/mai Thales tem sistema pessoal que roda sozinho, observável, com guardrail financeiro, dívida técnica em dia, zero warning ruidoso. Pronto pra não ser tocado por um mês se ele quiser focar em oficina/Performance/Project.

## Buffer (13-15/mai)

3 dias pra absorver atrasos, bugs que só aparecem em produção real, ou vida real da oficina (carro quebrado ocupando elevador da Anna, por assim dizer). Se a semana 4 fechar limpa, vira colchão pra dormir.

## Não-negociáveis por semana

- Todo commit com mensagem no padrão conventional (`feat:`, `fix:`, `refactor:`, ...), sem co-author robô.
- **Sem mock data** em nenhum endpoint ou página. `<EmptyState>` quando não tiver dado. Regra herdada da Operação Limpeza 09/04.
- **Multi-tenant discipline** não quebra: `tenant_id='dap_prime'` em toda tabela nova; zero hardcode de pipeline ID, custom field ID, nome "Doctor Auto" fora de config.
- **Sem segredo em log**: sanitizer regex `Bearer [\w-]+` → `Bearer ***` global, secret scan no CI.
- **Sem feature nova depois de quarta-feira de cada semana**: quinta e sexta são só teste, doc operacional (pro próprio Thales, não pra mercado), deploy.
- **Qualidade world-class**: `/hm-engineer` + `/hm-designer` antes de qualquer merge em master.

## Sequência estratégica (tese por trás)

1. **Anna primeiro.** Sennin — 1 agente live > 100 stubs. Anna é o único agente Parliament com prompt completo, spec fechado, código 80% pronto, credencial humana a 1 dia de ativar. Qualquer outra coisa empurrada pra frente dela é premature optimization: arquitetura sem tráfego real não vira conhecimento. Anna operando 1 semana gera mais sinal pro design do resto do Parliament do que 1 mês deliberando prompts no vácuo.
2. **Command Center depois da Anna, não antes.** Command Center sem Anna mostra dashboard morto — 5911 leads históricos e zero movimento ao vivo. Com Anna atendendo, o dashboard passa a ter "Waiting Queue" que muda sozinha, "Temperature" que reflete carga real, "Before/After" com depois-real, não depois-hardcoded. Isso é a diferença entre ferramenta usável e slide.
3. **Nenhum diretor novo em 30d.** Motivo tático: ativar Francisco/Pitoco/Zoraide sem dados reais de escalação Anna é recriar o erro de stubs. Motivo estratégico: Parliament deliberativo só faz sentido quando há decisões repetidas que pedem quórum. Sem volume, é teatro. Próximo diretor entra quando Anna tiver ≥20 escalações em 30d que mostrem padrão (preço recorrente → Francisco; fluxo de atendimento → Pitoco; reclamação recorrente → Zoraide).
4. **Sennin não se mexe.** Sennin Protocol v1 está servindo como OS pessoal; não é gargalo, não é alavanca. Reabrir Sennin agora é busca de novidade. Volta pra revisão só no ciclo 30-60d.
5. **Dívida na semana 4, não antes.** Pagar dívida sem operação real é pagar pro passado. A semana 4 resolve exatamente as dívidas que 2 semanas de Anna/Command Center tornaram concretas — nem uma a mais.

## Perguntas que o roadmap responde

- **Anna live em X semanas?** 2 semanas. Semana 1 fecha loop técnico e smoke. Semana 2 endurece pra 24/7 com observability e escalação completa.
- **Command Center quanto atrasa pra ficar usável?** 1 semana focada (semana 3), assumindo que semanas 1-2 entregaram fonte de dados viva. Plano existente cobre 9 tasks; com Anna alimentando, vira 5 dias úteis.
- **Parliament Phase 1 hardening?** Não esse mês. Francisco/Pitoco/Zoraide ficam como estão. Ganho marginal de endurecer sem dados < custo de não entregar Anna/Command Center.
- **Próximo diretor depois da Anna?** Nenhum em 30d. Decisão em 15/mai com base nos padrões de escalação reais. Candidato provável: Pitoco (CPO, fluxo de atendimento) se gargalo for UX de agendamento; Francisco (CFO) se for preço/orçamento.
- **Dívidas antes da próxima onda?** Priorizadas na semana 4 exatamente nessa ordem: (1) testes gateway+agents, (2) RLS Supabase completo, (3) token budget + kill-switch, (4) lint hooks, (5) deletar `dashboard/agents/`. Observability já entra na semana 2 porque sem ela Anna em prod é cego.

## Riscos de fricção

- **Semana 2 só cabe se M0 não derrapar.** Se Thales demorar >48h pra entregar `KOMMO_CHATS_CHANNEL_SECRET` + validar subdomínio, semana 1 invade semana 2 e tudo cascateia. Mitigação: M0 é bloqueio humano único; cobrar diariamente até 17/abr.
- **Kommo WhatsApp provider pode banir o número em volume moderado.** Typing delay + cap 150 msg/dia mitiga, mas risco é real. Contingência: Meta Cloud arquitetado (não implementado) como fallback de 1 semana extra se banir — isso empurra Command Center pra semana 4 e dívida pra ciclo 30-60d.
- **Command Center pode virar scope creep.** O plan de 04/04 tem 9 tasks; é tentador adicionar "só mais um gráfico". Regra dura: tudo que não serve a decisão diária do Thales (8h da manhã, 15 segundos de leitura) vira backlog, não entra na semana 3.

## Pergunta aberta pro Thales

Qual é o **único gesto operacional** que você quer fazer toda segunda de manhã no Command Center em 6/mai? Abrir `/leads`, olhar X, decidir Y. Se você responder em 1 frase, a semana 3 é trivial. Se responder em 3, a gente corta 2.
