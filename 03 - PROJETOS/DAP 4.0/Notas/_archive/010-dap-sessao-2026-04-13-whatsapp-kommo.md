---
title: Sessão 2026-04-13 — WhatsApp via Kommo ao ar
date: 2026-04-13
status: shipped
tags: [dap4, whatsapp, kommo, log-sessao, deploy]
---

# Sessão 2026-04-13 — WhatsApp operante no portal

## O que foi feito

Partiu de zero produção do WhatsApp no DAP4. Caminho Meta direto (specs 006/007) abandonado no meio — número Prime já opera via Kommo + histórico precisava ser preservado. Pivô pra Kommo levou de 80% do valor em 20% do trabalho.

**Shippado:**
- Schema novo Supabase: `kommo_conversations` + `kommo_messages` (classificação persistida por mensagem)
- Ana `intent_classifier` (temperature frio/morno/quente × intent orcamento/duvida/agendamento/reclamacao/outro)
- Gateway `/api/webhook/kommo` reescrito: recebe webhook Kommo (form-encoded), classifica via Ana, persiste, broadcast socket.io. Flag `ANA_AUTOREPLY=false` desliga auto-reply (default)
- Gateway endpoints: `GET /api/kommo/conversations`, `GET /api/kommo/messages`, `POST /api/kommo/send`, `POST /api/kommo/messages/read`, `GET /api/kommo/status`
- Dashboard nova página `/whatsapp` (`WhatsappKommo.jsx`) — lista + composer + badges de temperatura/intent no inbound
- Enrichment async de nome/telefone via `/api/v4/contacts/{id}` após webhook
- Sidebar poda — 7 páginas WIP escondidas do menu
- Caddy injetando `Authorization: Bearer $API_SECRET` pra toda chamada `/api/*` (login real é próximo passo)
- Dashboard auxiliar: `/whatsapp-meta` guarda a página antiga de Meta direto pra quando migrarmos

**Infra:**
- Cloudflare Tunnel `dap4` routeia `webhook.doctorautoprime40.com` + `app.doctorautoprime40.com` → host:80
- VPS Hostinger `76.13.170.42` — 4 containers healthy (chromadb + python-agents + gateway + caddy)
- Branch `feat/whatsapp-kommo` deployado, **não** mergeado em master ainda

**10 commits no branch**, push feito.

## Decisões duras

1. **Pivô Meta → Kommo.** Meta direto exigia migrar número (janela de downtime + risco). Kommo já funcionava + preservava histórico + reutilizava código existente do gateway.
2. **Outbound fica no Kommo direto.** Token long-lived do Kommo só tem escopo `push_notifications, files, crm, files_delete, notifications` — sem `chats`. Enviar resposta via API dá erro. Fallback cria nota no contato (inútil pro cliente). Thales responde pelo Kommo até resolver.
3. **Histórico antigo perdido (por ora).** Mesma limitação de escopo bloqueia leitura da Chat API. Notas dos leads são só internas ("Ana Reativador"), não têm conversas reais. Daqui pra frente flui novas.
4. **Operar como root na VPS.** SSH `dap4` aceita key mas nega auth pós-aceitação (motivo não diagnosticado). Fallback pragmático — vira tech debt.
5. **Caddy injeta Auth em vez de login real.** Hoje é MVP pra Thales só. Quando funcionária entrar, precisa Supabase Auth ou similar.

## Tech debt registrada

1. Outbound real — opções: (a) pedir escopo `chats` ao Kommo (BSP-only), (b) Salesbot lê nota `[Portal]` e envia via WA, (c) migrar pra Meta direto (desacopla do Kommo) — recomendação é (c)
2. Login de verdade — hoje Caddy injeta API_SECRET. Precisa virar Supabase Auth antes de entrar funcionária
3. Socket.io auth em WebSocket upgrade — Caddy não injeta header em `ws://`. Solução: query param `?token=` ou módulo Caddy específico
4. SSH `dap4` na VPS (root fallback ativo)
5. Rotacionar API keys expostas em tool output durante diagnóstico
6. HMAC signature no webhook Kommo — não implementado
7. Disable root SSH login
8. `docker-compose.prod.yml` e `Caddyfile` untracked no repo — decidir se commitam ou ficam environment-specific
9. Merge `feat/whatsapp-kommo` → master
10. `/SecondBrain` mkdir EACCES em container — daily note falha, não afeta fluxo
11. Backfill script existe mas inútil até resolver escopo Kommo

## Dados pra retomar

- Phone Number ID Meta: `690560884140632`
- WABA ID: `1414086012933652`
- Kommo domain: `doctorautobosch.kommo.com`
- Meta App: `867821022317896` (criado, não usado)
- Tunnel Cloudflare ID: `df082b0d-aa0b-4dd8-8274-c5f2ed61e561`

## Especificações vivas

- `008-dap-whatsapp-kommo-playbook.md` (spec atual)
- `009-dap-whatsapp-kommo-plan.md` (plano executado)
- `006`, `007` → superseded

## O que vem a seguir

- Merge branch → master + PR
- Popular o portal com dados reais (leads do Kommo via export CSV, knowledge base com SOPs alemães premium)
- Ativar páginas WIP conforme forem ficando prontas: Digital Brain, Sofia Hub, Blog Generator, Agent Fleet, Skill Builder, Communications, Ingestion
- Outbound via Salesbot ou Meta direto
- Login Supabase Auth antes de liberar funcionária
