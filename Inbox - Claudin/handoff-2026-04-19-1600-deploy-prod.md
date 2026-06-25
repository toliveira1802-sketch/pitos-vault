# Handoff — 2026-04-19 16:00 — Deploy Prod

**Prompt:** "bora!" — após Thales autorizar colocar algo no ar.

---

## Estado atual (VPS `76.13.170.42`)

### ✅ Rodando e saudável
```
doctor-auto-ai-caddy-1          Up   (public :80)
doctor-auto-ai-gateway-1        Up   healthy
doctor-auto-ai-python-agents-1  Up   healthy
doctor-auto-ai-chromadb-1       Up   (pinned 0.5.23)
cloudflared systemd             Up   1 week
nginx (host)                    Up   (secondary, :3080)
```

### ✅ O que foi deployado

**Dashboard (Sophia Hub incluso):**
- `/opt/doctor-auto-ai/dashboard/dist/` — full build com `SophiaHub-Cd1mdZuw.js`
- Caddy mount direto do dist/ pro `/srv/dashboard` no container
- Backup: `/opt/doctor-auto-ai/dashboard/dist.bak-2026-04-19-1320/`

**Backend (agents python):**
- Novo: `agents/agents/personal_0613b.py` (agente canônico)
- Novo: `agents/agents/sofia.py` (shim deprecated)
- Novo: `agents/config/prompts/0613b.yaml` (persona)
- Novo: `agents/api/routes/agent_0613b.py` (rota /agent/0613b/*)
- Atualizado: `agents/services/supabase_client.py` (adiciona `log_agent_action`)
- Atualizado: `agents/api/deps.py` (lê settings via módulo pra suportar reload)
- Patched: `agents/main.py` (import + include_router de agent_0613b)

**Gateway (node):**
- Atualizado: `gateway/src/middleware/validate.ts` (adiciona `agentCommand` schema)
- Atualizado: `gateway/src/routes/agent-0613b.routes.ts` (`/orchestrate` canônico + `/command` alias)
- Patched: `gateway/src/index.ts` (import + mount `/api/0613b`)

**Infra:**
- Compose trocado de `docker-compose.yml` (dev) pra `docker-compose.prod.yml` (o que realmente funciona aqui, tem caddy + nomes `python-agents`)
- ChromaDB pinado em `0.5.23` — `:latest` não tem python3/curl pro healthcheck
- Symlink `.env -> .env.production` pra silenciar compose warnings

### ✅ Verificado em smoke test
- `http://127.0.0.1:80/` → dashboard "Doctor AI — Command Center"
- `http://127.0.0.1:80/api/health` → `{"status":"ok"}`
- `http://127.0.0.1:3001/api/0613b/status` → `{"status":"ok","agent":"0613b","collections":[...],"agents_available":["ana","kimi","thales","insights","0613b"]}`

---

## ❌ Bloqueadores pra "no ar público"

### 1. DNS + Cloudflare Tunnel (ação humana, manual)

Tunnel `dap4` está rodando (systemd, token-based, managed remotely). Precisa configurar **Public Hostname** no Cloudflare Zero Trust dashboard:

1. Acessar https://one.dash.cloudflare.com → Networks → Tunnels
2. Clicar em `dap4` → aba **Public Hostnames** → **Add a public hostname**
3. Preencher:
   - Subdomain: `dap`
   - Domain: `doctorautoprime40.com`
   - Service type: `HTTP`
   - URL: `localhost:80`
4. Salvar. Cloudflare cria o CNAME automaticamente. Propaga em segundos.

Alternativa (se quiser o domínio raiz): repetir com Subdomain vazio + Domain `doctorautoprime40.com`. Hoje está como "parked" na Hostinger, precisaria primeiro transferir DNS pra Cloudflare (nameservers).

**Não consegui fazer autonomamente** porque o VPS não tem `CLOUDFLARE_API_TOKEN` com DNS write permission — só o tunnel run token.

### 2. ANTHROPIC_API_KEY inválida (bloqueia chat)

`/api/0613b/speak` retorna:
```
anthropic.AuthenticationError: 401 - invalid x-api-key
```

Status/listagem funciona, mas qualquer chamada LLM (speak, route, monitor) falha. Precisa rotar `ANTHROPIC_API_KEY` em `/opt/doctor-auto-ai/.env.production` e restart do container:
```
cd /opt/doctor-auto-ai && docker compose -f docker-compose.prod.yml --env-file .env.production up -d --no-deps python-agents
```

### 3. Bug pré-existente no Ana chat (não bloqueia Sophia Hub)

`/api/chat/message`:
```
TypeError: AnaAgent.__init__() takes 1 positional argument but 2 were given
```
Chat route passa arg a mais pro constructor. Fix é 1-linha em `agents/api/routes/chat.py` mas não toquei — fora do escopo da sessão.

---

## Resumo: "está no ar?"

- **Interno (SSH):** SIM, stack saudável, Sophia Hub serve, /status funciona
- **Público (browser):** NÃO ainda — precisa dos 5 cliques no Cloudflare dashboard acima
- **Interativo (chat 0613-B):** NÃO ainda — precisa rotar ANTHROPIC_API_KEY

**Estimativa depois dos 2 passos manuais acima: `https://dap.doctorautoprime40.com` servindo Sophia Hub em ~5 minutos.**

---

## Commits locais (não pushados — auth GitHub não está setup)

Branch `feat/kommo-prod-rc1`:
- `4313f86` fix(agents): green test suite
- `bfd5be9` feat(sophia-hub): cockpit ao vivo do 0613-B

Essas commits foram REVERTIDAS parcialmente após descobrir que quebravam o container Docker (convenção `agents.X` vs `agents.agents.X` é incompatível entre pytest e Docker WORKDIR). Agora local + prod usam `agents.X` (consistente com Docker). Testes passam via remoção de `/c/dev/dap4/conftest.py` e `/c/dev/dap4/agents/__init__.py`.

Próxima sessão precisa recommitar as mudanças locais pra alinhar git com VPS.
