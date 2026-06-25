---
title: DAP WhatsApp Go-Live Playbook (Prime) — SUPERSEDED
date: 2026-04-13
status: superseded
superseded_by: 008-dap-whatsapp-kommo-playbook.md
reason: Caminho Meta direto abandonado. Número já operante via Kommo — abordagem Kommo preserva histórico, zero downtime, reutiliza código existente.
owner: Thales
tags: [dap4, whatsapp, meta, go-live, playbook, superseded]
---

# DAP WhatsApp Go-Live — Linha Prime

Primeira ida a produção do WhatsApp do DAP4. Migra o número Prime do app WhatsApp Business pro Meta Cloud API, conecta ao portal DAP4 na VPS Hostinger, Thales atende clientes reais pelo dashboard.

## Escopo de hoje

- **Linha:** só Prime (Bosch fica pra outro dia)
- **Display Name:** `Doctor Auto`
- **Usuários do portal hoje:** só Thales (funcionária entra depois)
- **Ana:** modo classificação apenas (sem auto-reply)
- **Templates Meta:** pulados hoje (aprovação demora, aceitamos perder a janela de reengajamento fora das 24h)

## Arquitetura

```
Cliente WhatsApp
  ↓
Meta Cloud API
  ↓ webhook HTTPS
webhook.doctorautoprime40.com (Cloudflare Tunnel)
  ↓
gateway:3001 (HMAC verify → parse)
  ↓
agents:8000 (Ana — classifica, NÃO responde)
  ↓ persiste classificação no Supabase
gateway → socket.io → dashboard
  ↓
Thales responde manualmente no portal
  ↓
gateway.sendTextMessage() → Meta → cliente
```

## Comportamento da Ana (modo classificação)

Para cada mensagem recebida, Ana grava no DB:

| Campo | Valores |
|---|---|
| `temperature` | `frio` \| `morno` \| `quente` |
| `intent` | `orcamento` \| `duvida` \| `agendamento` \| `reclamacao` \| `outro` |

**Zero resposta automática.** Classificação aparece no dashboard como badge (cor por temperatura, ícone por intenção) na lista de conversas.

## Janela 24h da Meta

- Cliente escreveu nas últimas 24h → Thales responde livre.
- Fora da janela → só template aprovado consegue iniciar (pulado hoje).
- Impacto aceito: não reabrimos conversa fria no MVP. Templates entram depois.

## Caminho crítico (ordem de execução)

1. **Destravar SSH `dap4` na VPS** — diagnosticar `AuthorizedKeysFile` no sshd_config, garantir pubkey do laptop em `/home/dap4/.ssh/authorized_keys` com permissões corretas (700/600, owner dap4).
2. **Finalizar hardening Fase 1** — disable root login, confirmar ufw + fail2ban ativos.
3. **Submeter Display Name "Doctor Auto" no Meta cedo** (paralelo às tarefas de infra, aprovação pode demorar horas).
4. **Subir Cloudflare Tunnel (Fase 2)** — rotas:
   - `webhook.doctorautoprime40.com` → `gateway:3001`
   - `app.doctorautoprime40.com` → `dashboard:80`
5. **Remover número Prime do app WhatsApp Business** (downtime começa aqui — janela curta).
6. **Adicionar número Prime no Cloud API** — pegar `META_PHONE_NUMBER_ID` + `META_WABA_ID`.
7. **Gerar permanent System User token** — escopo `whatsapp_business_messaging` + `whatsapp_business_management` + `business_management`, expiração nunca. Salvar como `META_ACCESS_TOKEN`.
8. **Coletar `META_APP_SECRET`** (App Settings → Basic) e gerar `META_VERIFY_TOKEN` (`openssl rand -hex 16`).
9. **Ajustar Ana** — prompt de classificação only, campos estruturados (temperature, intent), persistir no Supabase.
10. **Ajustar gateway** — persistir classificação, emitir `classification:update` via socket.io.
11. **Ajustar dashboard** — badge temperatura (cor) + ícone intent na lista de conversas.
12. **Deploy stack na VPS** — `.env` completo, `docker compose up -d`.
13. **Registrar webhook no Meta** — Callback URL `https://webhook.doctorautoprime40.com/api/meta/webhook`, verify token loop deve passar.
14. **Subscribe field `messages`** no Meta → WhatsApp → Configuration.
15. **Smoke test end-to-end** — celular pessoal → número Prime → chega no dashboard → responde pelo dashboard → chega no celular.

## Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Display Name negado pela Meta | Submeter cedo; se negado, tentar variante ("Doctor Auto Prime"). |
| SSH `dap4` não destrava | Fallback: operar como root hoje, corrigir user depois (evitar se possível). |
| Aprovação Meta demora demais (>18h) | Rollback: recolocar número no app WhatsApp Business (reverte, perde histórico do dia). |
| Webhook signature mismatch | Checar `META_APP_SECRET` exato, Cloudflare Tunnel não reescreve body — raro. |
| Cliente manda mensagem durante a janela de migração | Aceito: downtime curto (~minutos) entre remover do app e registrar no Cloud API. |

## Credenciais a coletar

Todos salvos em `.env` da VPS:

- `META_PHONE_NUMBER_ID`
- `META_WABA_ID`
- `META_ACCESS_TOKEN` (permanent)
- `META_APP_SECRET`
- `META_VERIFY_TOKEN` (gerado localmente)
- `CLOUDFLARE_TUNNEL_TOKEN`

## Mudanças de código

- `agents/` — prompt Ana: classificação only, saída estruturada (temperature, intent).
- `gateway/` — persistir classificação, emitir `classification:update` via socket.io.
- `dashboard/` — UI badge temperatura (cor) + ícone intent na lista de conversas.

## Critério de sucesso

- [ ] Thales manda mensagem do celular pro número Prime e vê ela no portal em <2s.
- [ ] Conversa mostra badge de temperatura + ícone de intenção corretos.
- [ ] Thales responde pelo portal e a resposta chega no celular em <2s.
- [ ] `META_VERIFY_TOKEN` loop OK, webhook status `connected: true` em `/api/meta/status`.
- [ ] Tunnel Cloudflare `HEALTHY`.
- [ ] Root login SSH desabilitado na VPS.

## Próximo passo após este playbook

Invocar `writing-plans` pra transformar em plano de implementação detalhado (tasks executáveis por fase).
