---
title: DAP WhatsApp Go-Live Playbook (via Kommo)
date: 2026-04-13
status: ready-to-execute
supersedes: 006-dap-whatsapp-golive-playbook.md
owner: Thales
tags: [dap4, whatsapp, kommo, go-live, playbook]
---

# DAP WhatsApp Go-Live — via Kommo

Linha Prime já opera via Kommo hoje. Portal DAP4 consome o fluxo Kommo existente — zero mexida no Meta, zero downtime, histórico preservado via backfill.

## Escopo de hoje

- **Canal:** WhatsApp via Kommo (sem tocar no Meta)
- **Usuários portal:** só Thales hoje
- **Ana:** modo classificação only (sem auto-reply)
- **Histórico:** backfill completo do Kommo → Supabase → portal mostra conversas antigas e novas

## Arquitetura

```
Cliente WhatsApp
  ↓ (fluxo Kommo existente)
Kommo
  ↓ webhook (existente)
gateway: POST /api/webhook/kommo
  ↓ call agents: Ana classify-only
Supabase: kommo_messages + kommo_conversations (novas tabelas)
  ↓ socket.io
dashboard /whatsapp (nova ou adaptada)
  ↓ Thales responde manualmente
gateway: POST Kommo Talk API → Kommo → cliente
```

## O que já existe no código

- `gateway/src/routes/webhook.routes.ts` — handler Kommo completo (recebe, chama Ana, responde via Kommo, atualiza lead)
- `gateway/src/routes/kommo-sync.routes.ts` — scrape Kommo (backfill parcial?)
- `gateway/src/config/env.ts` — `KOMMO_TOKEN` + `KOMMO_DOMAIN`
- `dashboard/src/pages/Leads.jsx` — UI existente de leads
- `dashboard/src/pages/Logs.jsx` — UI de webhooks

## O que falta pra "operante"

1. **Persistir conversa** (hoje só loga em `webhook_logs`, sem thread de mensagens)
2. **Emit socket.io** pra dashboard atualizar em tempo real
3. **Dashboard /whatsapp** (ou adaptar `/leads`) com lista de conversas + visualização + composer de resposta manual
4. **Ana em classify-only** (remover auto-reply)
5. **Backfill** das conversas antigas do Kommo
6. **Registrar webhook público** no Kommo (se ainda não aponta pro gateway)

## Classificação da Ana

| Campo | Valores |
|---|---|
| `temperature` | `frio` \| `morno` \| `quente` |
| `intent` | `orcamento` \| `duvida` \| `agendamento` \| `reclamacao` \| `outro` |

Badges no dashboard: cor por temperatura, ícone por intenção.

## Caminho crítico

1. Novas tabelas Supabase: `kommo_conversations`, `kommo_messages`
2. Ajustar webhook Kommo pra persistir + emitir socket
3. Ajustar Ana pra classify-only
4. Criar página `/whatsapp` no dashboard (lista + composer)
5. Backfill script (Node) — paga leads + chats do Kommo via API
6. Deploy stack no VPS (root por hoje, dap4 SSH vira tech debt)
7. Expor gateway via tunnel existente (`webhook.doctorautoprime40.com` → gateway:3001)
8. Confirmar URL do webhook no Kommo aponta pra nosso gateway
9. Smoke test end-to-end

## Riscos

| Risco | Mitigação |
|---|---|
| Kommo já aponta webhook pra outro sistema | Fácil — basta atualizar URL no Kommo |
| Rate limit Kommo no backfill (~7 req/s) | Paginação + throttle, backfill roda em ~15-30min pra 5.9k leads |
| Auto-reply Ana sobrevive em produção | Feature flag `ANA_AUTOREPLY=false` + teste explícito |
| Webhook Kommo não assinado | Aceitar hoje, adicionar HMAC depois (tech debt) |

## Critério de sucesso

- [ ] Thales vê conversas antigas no portal (backfill OK)
- [ ] Cliente manda WhatsApp → aparece em <2s no portal
- [ ] Badge temperatura + ícone intent corretos
- [ ] Thales responde pelo portal → chega no cliente em <5s
- [ ] Ana não responde automaticamente
- [ ] Kommo continua funcionando normalmente do lado deles

## Tech debt registrada

- SSH `dap4` na VPS (bloqueio não diagnosticado, operamos como root hoje)
- Rotação de credenciais API (OpenAI, Anthropic, Google, DeepSeek, Perplexity, Kimi, Supabase service_role) — secrets estão em plaintext em `/opt/doctor-auto-ai/env_production_vps.txt` no VPS
- HMAC signature no webhook Kommo
- Disable root SSH login

## Próximo passo

Invocar `writing-plans` pra virar plano executável task-a-task.
