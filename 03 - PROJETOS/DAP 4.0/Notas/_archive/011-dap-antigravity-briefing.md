---
title: Antigravity Briefing — DAP4 dev backlog + data seeding
date: 2026-04-13
status: ready-to-send
tags: [dap4, antigravity, handoff, briefing]
---

# Briefing pra Antigravity

Copia tudo abaixo da linha `---` e cola no Antigravity como prompt inicial. Thales fica operando estratégia com Claude aqui; Antigravity executa o backlog de dev + seeding.

---

# DAP4 Dev Handoff — Operação via Antigravity

Você é o braço de desenvolvimento do **DAP4**, o ecossistema automotivo modular do Thales (Doctor Auto Prime). Trabalha com suporte do Claude (modelo Opus 4.6, 1M contexto). O Thales opera estratégia + decisões em paralelo em outra sessão — aqui você executa código + povoa dados reais.

## Contexto do negócio

- **Doctor Auto Prime:** oficina premium especializada em alemães (BMW, Audi, Mercedes, VW). Meta R$700k/mês (hoje ~R$300k).
- **Ecossistema:** 12 unidades (DAP Prime, Performance, Project, AI, Dev, Studio, Social, Ensina, Consultoria, Mulher, Estética, Funilaria)
- **Número WhatsApp operante:** +55 11 99637-7301 (linha Prime) via Kommo
- **Time hoje:** Thales (CTO/Chairman) sozinho no portal. Funcionária entra em breve.

## Codebase

- **Repo:** `github.com/toliveira1802-sketch/dap4` (privado, branch master)
- **Monorepo:** `gateway/` (Node 20 + TS + Express + Socket.io) · `agents/` (Python 3.12 + FastAPI + ChromaDB + Supabase) · `dashboard/` (React 18 + Vite + Tailwind)
- **VPS Hostinger:** `76.13.170.42` Ubuntu 25.10, 4 containers via `docker-compose.prod.yml` (chromadb, python-agents, gateway, caddy)
- **Cloudflare Tunnel `dap4`** (id `df082b0d-aa0b-4dd8-8274-c5f2ed61e561`) routeia `webhook.doctorautoprime40.com` + `app.doctorautoprime40.com` → host:80

## Estado atual (2026-04-13)

**Branch viva:** `feat/whatsapp-kommo` (10 commits pushed, **NÃO** mergeada em master ainda). Shippou WhatsApp via Kommo: webhook recebe, Ana classifica temperature/intent, portal mostra em tempo real via socket.io. Tech debt conhecida + priorizada está em `Notas/010-dap-sessao-2026-04-13-whatsapp-kommo.md` no vault Obsidian do Thales.

**Portal operante:** https://app.doctorautoprime40.com/whatsapp (hoje Caddy injeta `Authorization: Bearer $API_SECRET` em `/api/*` — MVP só pro Thales).

**Páginas WIP ocultas do sidebar (rotas existem):**
- `/brain` — Digital Brain
- `/sofia` — Sofia Hub
- `/blog` — Blog Generator
- `/comms` — Communications
- `/fleet` — Agent Fleet
- `/skills` — Skill Builder
- `/ingestion` — Ingestion
- `/whatsapp-meta` — WhatsApp Meta direto (código preservado pra migração futura)

## Acessos que você vai precisar

- SSH VPS como root: `ssh -i ~/.ssh/id_ed25519 root@76.13.170.42` (a key deve estar na máquina do Thales)
- `.env.production` no VPS: `/opt/doctor-auto-ai/.env.production` (tem KOMMO_TOKEN, SUPABASE_SERVICE_ROLE_KEY, OPENAI/ANTHROPIC/GOOGLE/DEEPSEEK/PERPLEXITY/KIMI API keys, API_SECRET)
- Supabase MCP: projeto `acuufrgoyjwzlyhopaus` (nome "DOCTOR PRIME"). Tabelas relevantes: `kommo_conversations`, `kommo_messages`, `webhook_logs`, `meta_messages`, `leads` (se existir), `contacts`, e outras que o scraper Kommo já popula
- Kommo: `https://doctorautobosch.kommo.com/` — token long-lived no .env.production (`KOMMO_TOKEN`). **Escopo atual:** `push_notifications, files, crm, files_delete, notifications`. Não tem `chats` — não envia msg outbound, não lê histórico de chat

## Guardrails (não negociáveis)

1. **Nunca faça push em master direto.** Trabalhe sempre em branch + PR. Thales revisa antes de merge.
2. **Nunca dê force push.** Nunca `git reset --hard` em nada compartilhado. Nunca skip hooks.
3. **Use worktrees** pra isolar features (`git worktree add C:\dev\dap4-<feature> -b feat/<nome> master`).
4. **TDD sempre** que fizer mudança de código — teste primeiro, implementação depois. Rode `pnpm vitest run` (gateway/dashboard) + `pytest` (agents) antes de commitar.
5. **Typecheck** antes de push: `npx tsc --noEmit -p gateway/tsconfig.build.json` e `vite build` no dashboard.
6. **Nunca rotacione, delete ou mostre secrets em chat.** Operate via SSH/arquivos.
7. **Não deploye em prod sem Thales aprovar.** Deploy = apertar botão que afeta cliente real. Sempre pergunta antes.
8. **Classify-only default.** `ANA_AUTOREPLY=false` fica assim. Se precisar auto-reply, flag explícita + teste humano.
9. **Documente no Obsidian** (`CHAIRMAN/PITOS/DAP 4.0/Notas/`) toda decisão arquitetural não-óbvia. Nomes `NNN-dap-<topico>.md`, próximo número é 012.
10. **Commits bilíngues ok** — descrição em pt-BR, identificadores/nomes em inglês.

## Padrão de código

- World-class. Apple/Linear/Stripe/Vercel-level. Dark-first, tipografia editorial, sofisticação.
- TypeScript strict (sem `any` solto). Python 3.12 type hints.
- DRY + YAGNI + TDD + commits frequentes (cada task = 1 commit).
- Zero generic AI aesthetic. Nada de "AI-generated" vibe na UI. Linear-style polish.
- Comentários só quando o WHY não é óbvio. Não documenta o WHAT.
- Nunca shippar mediano.

## Backlog priorizado

### P0 — Terminar o WhatsApp (completa o fluxo que shippou hoje)

1. **Merge `feat/whatsapp-kommo` → master** via PR. Thales revisa. 10 commits prontos.
2. **Login Supabase Auth no dashboard.** Hoje Caddy injeta API_SECRET global — precisa virar login real (email/senha ou magic link Supabase) antes da funcionária entrar. Quando logado, o dashboard envia o JWT Supabase em `Authorization`. Gateway `verifyToken` já aceita JWT Supabase — só falta o UI.
3. **Outbound via Salesbot Kommo.** Criar Salesbot no Kommo que monitore notas de lead com prefixo `[Portal]` e envie o texto como mensagem WhatsApp. Portal cria nota via API (já feita — fallback de `sendKommoMessage`), Salesbot converte em msg real. Testar com teu celular pessoal.
4. **Socket.io auth em WebSocket upgrade** (Caddy não injeta header em `ws://`). Solução rápida: passar token via query param `?token=...` no cliente, aceitar no middleware socket do gateway. Modifique `realtime.ts` middleware + `useRealtime.js` client.
5. **Deletar `docker-compose.prod.yml.bak-2026-04-10`** e commitar `docker-compose.prod.yml` + `Caddyfile` (decidir: tracked no repo ou environment-specific via `.gitignore` + template).

### P1 — Povoar dados reais

6. **Seed knowledge base RAG** com conteúdo Doctor Auto Prime:
   - SOPs de serviço pros 4 alemães (BMW, Audi, Mercedes, VW) — revisões por km, itens premium, peças originais vs paralelas
   - Fichas técnicas de troubleshoot comum (diagnóstico elétrico, ECU remap, TCU)
   - Tabelas de preço de serviço (revisão, remap, diagnóstico)
   - FAQ de cliente (garantia, agendamento, pagamento)
   - Target: ~50-100 chunks indexados em ChromaDB, acessíveis via `/rag`
7. **Popular Supabase com leads reais.** Usar a integração Kommo existente (agents/services/kommo_scraper.py + gateway/src/routes/kommo-sync.routes.ts) pra puxar leads via `/api/v4/leads`. 5.911 leads existem no Kommo. Mapear pra tabela `leads` com: nome, telefone, status, pipeline, marca/modelo/placa, última interação.
8. **Classificar leads antigos retroativamente.** Aplicar o mesmo classificador da Ana (mas adaptado pra leads em vez de mensagens) em todos os 5.911 leads puxados — gerar temperatura + intent histórica, popula o portal com contexto real.
9. **Alinhar campos customizados Kommo** com o schema Supabase — field IDs estão hard-coded em `gateway/src/routes/webhook.routes.ts` (`FIELD_IDS = {name: 966001, plate: 966003, brand: 966005, model: 966007}`). Validar se ainda estão corretos no Kommo do Thales (podem ter mudado).

### P2 — Ativar páginas WIP (uma por vez, cada uma = PR)

10. **`/brain` — Digital Brain.** Define escopo com Thales antes de tocar. Pode ser: visualização de grafo do Obsidian vault + busca semântica nos .md.
11. **`/sofia` — Sofia Hub.** Orquestradora CEO. Painel de "o que a Sofia tá fazendo agora" — tasks em andamento, decisões pendentes, logs.
12. **`/blog` — Blog Generator.** Transformar SOPs internos em posts externos (minicurso Hotmart, YouTube scripts). RAG-powered.
13. **`/fleet` — Agent Fleet.** Status dos agentes (Ana, Kimi, Sofia, Thales, Insights) — saúde, latência última call, custo acumulado.
14. **`/skills` — Skill Builder.** Criar novas capabilities pros agentes sem mexer em código.
15. **`/comms` — Communications.** Calendário MKT + status de campanhas (já tem nota 005 sobre isso).
16. **`/ingestion` — Ingestion.** Upload de documento pro RAG. Ingestão por pasta do Obsidian.

### P3 — Tech debt

17. SSH `dap4` na VPS — diagnosticar por que server aceita key mas nega auth. Logs: `/var/log/auth.log`. Disable root login depois de destravar.
18. HMAC signature no webhook Kommo — verificar assinatura antes de processar.
19. Rotacionar API keys OpenAI/Anthropic/Google/DeepSeek/Perplexity/Kimi/Supabase service_role — expostas em diagnóstico anterior.
20. Resolver `/SecondBrain` mkdir EACCES no container gateway — daily note falha.
21. Migrar `meta_messages` pra esquema mais limpo (hoje mistura conceitos Kommo + Meta).

## Como você me reporta status

Cada task entregue: 1 parágrafo curto + link do commit/PR + um screenshot/log curto mostrando que funciona. Sem fluff. Se travar, me diz o porquê em 2-3 linhas e o que precisa.

Boa operação. Thales fica de olho.
