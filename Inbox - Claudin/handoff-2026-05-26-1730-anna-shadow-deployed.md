---
type: handoff
date: 2026-05-26
time: 17:30
project: DAP4 + dap-aios
topic: Anna Shadow Learning Loop — deploy completo, UI carregando, validação pendente
tags: [handoff, claudin, dap4, anna-shadow, sprint-4, deployed]
supersedes: handoff-2026-05-26-1500-anna-shadow-deploy.md
---

# Handoff — Anna Shadow Learning Loop (DEPLOYED, validação browser pendente)

## Contexto

Sessão retomada via `handoff-2026-05-26-1500-anna-shadow-deploy.md`. Aquele handoff dizia "backend LIVE, UI vazia, hipótese = PR #26 ausente". A hipótese estava ERRADA (PR #26 já estava em HEAD `9513ce9` no master, gateway com proxy deployado). O bloqueador real era **agents container em restart loop** mascarando todas as chamadas downstream — sintoma idêntico de "UI vazia" porque fetch falhava silencioso.

Após resolver agents + 4 outros bugs em cascata (TLS cert, Caddy hostname, asset MIME, user provision), a cadeia inteira está validada end-to-end. Falta só o Thales fazer hard refresh no browser e validar a UI renderiza com 1 card de smoke pra fechar Sprint 4.

## O que funcionou (com evidência verificada na VPS 76.13.170.42)

### 1. Agents container — root cause encontrado e resolvido

- **Sintoma**: `doctor-auto-ai-agents-1` em restart loop com `RestartCount=504`, log `Exception: {"error":"KeyError('_type')"} (trace ID: 0)` em `chroma_client.initialize_collections()`.
- **Root cause**: mismatch chromadb client/server. `agents/requirements.txt` tinha `chromadb>=1.0.0,<2.0.0` (instalou **1.5.9**), server pinado em **0.6.3** via docker-compose.override. API quebra entre majors.
- **Fix**: editado `requirements.txt` pra `chromadb==0.6.3` (backup `.bak-pre-pin-<ts>`), `docker compose build --no-cache agents` (353s), `up -d --force-recreate --no-deps agents`.
- **Verificação**: container `Up healthy`, log `Application startup complete`, 7 collections inicializadas (`ops_*`, `study_*`), scheduler started com 4 jobs, `pip show chromadb` → 0.6.3.

### 2. PR #26 (gateway shadow proxy) já estava mergeado

- `gh pr view 26` → `state: MERGED, mergedAt: 2026-05-26T05:05:49Z`, commit `9513ce9` ("feat(gateway): proxy /api/anna/shadow/* → Python anna_shadow endpoints (#26)").
- HEAD VPS = HEAD origin/master = `9513ce9`. Arquivo `gateway/src/routes/anna-shadow.routes.ts` presente em source E `/app/dist/routes/anna-shadow.routes.js` no container compilado.

### 3. TLS handshake_failure no domínio antigo

- `staging.aios.doctorautoprime40.com` (2 níveis de wildcard) NÃO coberto pelo cert SSL Universal grátis do Cloudflare (cobre só `*.doctorautoprime40.com`, 1 nível).
- **Fix**: Thales criou novo public hostname `aios.doctorautoprime40.com` no Cloudflare Tunnel (service `http://localhost:80` → routeia via Caddy), antigo `staging.aios.*` deletado.
- **Verificação**: `openssl s_client -connect aios.doctorautoprime40.com:443` → CONNECTED, `subject=CN=doctorautoprime40.com`.

### 4. Caddy host renomeado + rewrite pra assets

- Caddyfile: `staging.aios.doctorautoprime40.com` → `aios.doctorautoprime40.com` (sed em todos os refs, backup `.bak-pre-aios-rename-<ts>`).
- Restart `dap4-caddy` (admin off, reload via API não funciona).
- Adicionado bloco rewrite pra resolver assets com path relativo em sub-rotas:
  ```
  handle @aios_staging {
      @nested_assets path_regexp nested ^/[^/]+/[^/]+/(assets/.*)$
      rewrite @nested_assets /{re.nested.1}
      reverse_proxy aios-staging:5050
  }
  ```
- **Verificação**: `curl /aios/anna/assets/index-Dzjdk_m2.js` → HTTP 200, MIME `text/javascript`, 959KB. CSS idem.

### 5. Provisão de user em `public.users` (causa do tela preta pós-login)

- **Sintoma**: console mostrou `/api/me` → 403 (2x) após login.
- **Root cause**: backend dap-aios busca user em `public.users` por `supabase_user_id`, não encontra → Forbidden. `auth.users` tem 5 users (Thales, Anna, Roniela, João, Pedro), `public.users` tinha só 1 seed (`test@aios.local` com `supabase_user_id=null`).
- **Fix**: INSERT pro Thales como Admin:
  ```
  id: 93f35ac303be454fa32cf
  email: toliveira1802@gmail.com
  name: Thales Oliveira
  role_id: hXjSTppyA72nhtxVKQAvY (Admin)
  supabase_user_id: d803e35e-4c4c-4380-860a-e6fe1ddc3a8a
  active: true
  ```
- **Não verificado ainda**: Thales precisa hard refresh e confirmar `/api/me` retorna 200 + UI renderiza.

### 6. Smoke observation criada na fila

- `POST /api/anna/shadow/simulate` via gateway dap4 → HTTP 200, criou observation `19cd66e1-2af1-4825-922a-eccdcaa8ebe4` em `anna_shadow_observations`.
- Conteúdo: `lead_msg="smoke test 26-may: oi, queria saber preço de revisão BMW 320i 2020"`, `anna_response` aplicou guardrail `price_gate` ("Pra te passar um valor honesto a gente precisa ver o carro...").
- `GET /api/anna/shadow/pending` → 1 item retornado.

## O que NÃO funcionou (e por quê)

- **Hipótese inicial do handoff anterior errada**: assumi que UI vazia = PR #26 ausente. Era agents-down. Lição: **verificar `docker ps` antes de hipotetizar sobre rota/proxy** — restart loop não aparece em "stack OK" e mascara tudo downstream.
- **TLS curl loopback ambíguo**: o teste inicial da VPS pro `staging.aios.*` deu handshake_failure. Eu descartei como "limitação do curl da VPS" e segui. Erro: era o problema real (cert cobertura). **Lição**: TLS error do curl loopback vale como evidência de cert/CF, não só de rede local.
- **Caddy reload via admin API falhou** porque `admin off` no Caddyfile. Solução: `docker restart dap4-caddy`. Tech debt: vale considerar habilitar admin com bind em localhost only.
- **Login do Thales mostrou 400 no `/auth/v1/token`** (provavelmente uma tentativa com senha errada antes do sucesso, ou refresh failed). Não bloqueia mas vale observar se reaparecer.

## Cadeia validada end-to-end

| Camada | Status | Como validei |
|--------|--------|--------------|
| Python agents `/agent/anna/shadow/pending` | ✅ 200 | curl Bearer via docker exec |
| Gateway dap4 `/api/anna/shadow/*` (PR #26 proxy) | ✅ 200 | curl Bearer via curl container na network |
| Smoke `POST /simulate` | ✅ 200 | observation `19cd66e1-...` criada |
| dap-aios server `/api/anna/shadow/*` (PR #38) | ✅ rota existe | curl localhost:5001 → 401 (esperado) |
| TLS `aios.doctorautoprime40.com:443` | ✅ válido | openssl s_client |
| HTML `/aios/anna/shadow` | ✅ HTTP 200, 527 bytes | curl |
| Assets JS/CSS via Caddy rewrite | ✅ MIME corretos | curl, ambos paths |
| Login Supabase Auth | ✅ user logado | auth.users.last_sign_in_at atualizou |
| `/api/me` pós-INSERT | ⏳ pendente Thales | hard refresh + DevTools |
| UI renderiza com smoke card | ⏳ pendente Thales | visual |

## Decisões tomadas

- **Pinned chromadb=0.6.3 (versão exata, sem range)** — memory `feedback_chromadb_pin_client_server` registra padrão. Pinar só server (feito antes) é insuficiente; cliente Python tem que casar.
- **Hostname `aios.doctorautoprime40.com` (não `aios-staging`)** — só existe 1 ambiente vivo, separação preventiva é teatro. Memory `feedback_no_premature_staging_split`.
- **Caddy rewrite como workaround pra paths relativos do Vite** — quick fix de 5 linhas. Tech debt: PR no dap-aios mudando `base: '/'` é o fix definitivo, fila esse depois.
- **INSERT manual em public.users só pro Thales** — fix imediato pra desbloquear. Outros 4 users (Anna, Roniela, João, Pedro) terão mesmo 403 quando logarem. Tech debt: trigger Supabase `on_auth_user_created` que auto-provisiona com role default.
- **CSP do app permanece `script-src 'self'` (Cloudflare beacon bloqueado)** — cosmético, não impede funcionalidade. Fix futuro: desabilitar CF Web Analytics OU adicionar `https://static.cloudflareinsights.com` no CSP.

## Bloqueios & perguntas abertas

- **Único bloqueio remanescente**: Thales precisa hard refresh no browser e confirmar que UI renderiza. Se renderizar → Sprint 4 fechado. Se ainda quebrar → DevTools + logs aios-staging.
- **Smoke real WhatsApp pendente**: precisa mandar 1 msg pro número Anna (+5511917001822) pra validar fluxo Kommo→webhook→worker→shadow→observation. Memory anterior: `anna_inbox.last_inbox_event` era 12 dias atrás (sem tráfego real recente).
- **API_SECRET vazado em chat anterior** (3ª ocorrência, memory `feedback_secrets_no_chat`) — rotacionar essa semana.
- **PRs DAP4 abertas aguardando merge**: #22 Sprint1 (Langfuse + citations + eval), #23 Sprint2 (model bump + ingest CLI + PITOS seed), #24 Sprint3 (Walter research agent). Tests verde, mergear em qualquer ordem.

## Arquivos tocados nesta sessão (na VPS)

| Arquivo | Mudança | Backup |
|---------|---------|--------|
| `/opt/doctor-auto-ai/agents/requirements.txt` | `chromadb==0.6.3` | `.bak-pre-pin-<ts>` |
| `/opt/doctor-auto-ai/infra/Caddyfile` | host rename + rewrite assets | `.bak-pre-aios-rename-<ts>`, `.bak-pre-rewrite-<ts>` |
| Supabase `public.users` (DAP AIOS) | INSERT Thales Admin | row id `93f35ac303be454fa32cf` |
| Cloudflare Tunnel public hostnames | `staging.aios.*` deletado, `aios.*` criado | n/a (dashboard) |

## Memórias atualizadas no claude memory system

- `feedback_chromadb_pin_client_server.md` (novo) — pinar client E server na mesma versão exata
- `feedback_no_premature_staging_split.md` (novo) — sem split prod/staging em hostname com 1 ambiente

## Próximo passo exato

### 1. Thales: hard refresh + validar UI

```
1. Abrir https://aios.doctorautoprime40.com/aios/anna/shadow
2. Ctrl+Shift+F5
3. Se pedir login: toliveira1802@gmail.com + senha
4. Verificar:
   - Shell renderiza (sidebar, topbar)
   - Página Anna Shadow carrega
   - 1 card aparece: "smoke test 26-may: oi, queria saber preço de revisão BMW 320i 2020"
   - 3 botões inline: Aprovar / Editar+Aprovar / Rejeitar
5. Se vazio ou erro: F12 → Network/Console → reportar
```

### 2. Validar ações inline

Clicar **Aprovar** no card de smoke → confirmar:
- Observation muda status pra `approved` em Supabase
- Chunk aparece em `ops_conversas_aprovadas` (RAG via ChromaDB)

```sql
-- via Supabase MCP em DOCTOR PRIME (acuufrgoyjwzlyhopaus)
SELECT id, status, approved_text, approved_by, approved_at, rag_document_id
FROM anna_shadow_observations
WHERE id = '19cd66e1-2af1-4825-922a-eccdcaa8ebe4';
```

### 3. Smoke real WhatsApp (se Meta+Kommo ligados)

Mandar 1 msg pro WhatsApp Anna (+5511917001822). Confirmar observation aparece via worker hook auto-shadow:

```sql
SELECT id, brand_id, lead_msg, status, created_at
FROM anna_shadow_observations
ORDER BY created_at DESC LIMIT 5;
```

### 4. Tech debt fila (não urgente, mas registrado)

- PR no dap-aios mudando Vite `base: '/'` → elimina Caddy rewrite hack
- Trigger Supabase `on_auth_user_created` → auto-provision `public.users`
- CSP atualizar OU desabilitar CF Web Analytics
- Rotacionar API_SECRET (3ª vez vazado em chat)
- Mergear PRs #22 #23 #24 do dap4
- Patches locais VPS (Bearer auth, Caddyfile, compose) virarem PRs

## Setup / comandos úteis

```bash
# SSH
ssh root@76.13.170.42

# Estado containers DAP4
docker ps --format "table {{.Names}}\t{{.Status}}"
# Esperado: dap4-caddy, doctor-auto-ai-{gateway,agents,chromadb}-1, aios-staging

# Test endpoint shadow (Bearer required)
docker run --rm --network doctor-auto-ai_default curlimages/curl:8.10.1 \
  -sS -H "Authorization: Bearer $API_SECRET" \
  "http://gateway:3001/api/anna/shadow/pending?limit=3"

# Agents logs
docker logs doctor-auto-ai-agents-1 --tail 50

# aios-staging logs
docker logs aios-staging --tail 50

# Caddy reload (admin off — usar restart)
docker restart dap4-caddy

# Supabase DAP AIOS (auth + public.users)
# Project ID: hlhfqnhsvwxodtwdkkhf

# Supabase DOCTOR PRIME (anna_shadow_observations)
# Project ID: acuufrgoyjwzlyhopaus

# URLs
https://aios.doctorautoprime40.com           # raiz dap-aios
https://aios.doctorautoprime40.com/aios/anna/shadow   # Anna Shadow UI
```

---

**Status Sprint 4**: 99% completo. Falta só validação visual do Thales no browser.
**PRs mergeadas no Sprint 4**: #25 (backend Anna Shadow), #26 (gateway proxy), #38 (dap-aios UI).
**PRs em aberto pendentes** (Sprints 1-3): #22, #23, #24.
