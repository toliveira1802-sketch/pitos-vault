# VPS Inventory — `srv1303948.hstgr.cloud` (76.13.170.42)

**Host:** Hostinger KVM, Ubuntu, 31 GB RAM, 387 GB disk, no swap
**Uptime at audit:** 31d 14h (desde ~2026-03-09)
**Auditoria:** 2026-04-10 (durante Operação Limpeza, Phase 3)
**Autor:** Claudin, sob direção do Thales
**Status:** Mapeamento pré-consolidação. Decisões da auditoria anotadas inline.

---

## Resumo executivo

A VPS acumulou **~6 tentativas de deploy do DAP4.0**, **~4 tentativas do agente-thales**, **1 cluster openclaw inteiro** (9 agentes), **1 Evolution API** ativa (WhatsApp), **1 Davi Gatuno** operacional, e **1 Node gateway legacy** via systemd — tudo no mesmo host, sem coordenação. Esta auditoria mapeia cada item, marca **KEEP / KILL / INVESTIGATE**, e registra as mutações aplicadas em 2026-04-10.

---

## 1. Stacks Docker (5 projetos, 8 compose files)

| # | Path | Project | Service(s) | Estado (2026-04-10) | Decisão |
|---|---|---|---|---|---|
| 1 | `/opt/doctor-auto-ai/docker-compose.prod.yml` | `doctor-auto-ai` | caddy, gateway, python-agents, chromadb | python-agents **crashloop** (`restart_count=48`), gateway/caddy `Created` (nunca subiram), chromadb `Up 43m` | **KEEP** — é a stack alvo do DAP4.0. Precisa de fix ChromaDB. |
| 2 | `/root/doctor-ai/docker-compose.yml` | `doctor-ai` | dashboard, gateway, agents, chromadb | Dashboard/gateway/agents `Created`, chromadb `Up 43m (unhealthy)` | **KILL** — versão antiga duplicada |
| 3 | `/root/doctor-ai-dashboard/docker-compose.yml` | `doctor-ai-dashboard` | evolution-api, evolution-db (postgres) | Ambos `Up 43m` — **Evolution API WhatsApp ativo** na porta 8080 | **INVESTIGATE** — confirmar se o WhatsApp do DAP4.0 depende disso ou do Davi Gatuno/Kommo |
| 4 | `/opt/agente-thales/docker-compose.yml` | — | agente-thales | Build travado desde 2026-03-30 (processo buildx órfão) | **KILL** |
| 5 | `/root/backend-agente-thales/docker-compose.yml` | — | (duplicata do #4) | Não rodando | **KILL** |
| 6 | `/opt/whatsapp-thales/docker-compose.yml` | — | (outra duplicata thales) | Não rodando | **KILL** |
| 7 | `/opt/doctor-auto-ia/docker-compose.yml` | — | (cópia "IA" em vez de "AI") | Não rodando | **KILL** |
| 8 | `/opt/doctor-auto-ia-old/` | — | legacy "-old" | Não rodando | **KILL** |

### Notas técnicas da stack KEEP (`doctor-auto-ai`)

- **Python-agents crashloop root cause:** `KeyError: '_type'` em `chromadb/api/configuration.py:209` — mismatch entre client e server ChromaDB.
- **Client** (requirements.txt): `chromadb==0.5.23` (pinned)
- **Server** (docker-compose.prod.yml): `chromadb/chroma:latest` (**NÃO pinned** — pulled em 2026-04-09, provavelmente 1.x ou 0.6.x, formato incompatível com client 0.5.23)
- **Fix aplicado:** pin server → `chromadb/chroma:0.5.23` e wipe volume `chroma_data` (não há dado de app ainda — python-agents nunca subiu)
- **Caddy vs nginx:** Caddy no compose (portas 80/443) conflita com nginx do host (também em 80/443). **Decisão pendente**: qual dos dois termina TLS? Enquanto Caddy estiver `Created` e não `Up`, não há conflito real.

---

## 2. Processos fora do Docker

### 2.1 Systemd custom services

| Unit | Aponta pra | Estado | Decisão |
|---|---|---|---|
| `nginx.service` | `/etc/nginx/` (sites-enabled: webhook-davi) | Estava `failed` desde 2026-04-03 11:06 UTC. **Restaurado em 2026-04-10 03:55 UTC** | **KEEP** — SSL do webhook Davi Gatuno depende |
| `doctor-auto-prime.service` | `/usr/bin/node /opt/doctor-auto-prime/dist/index.js` | Rodando desde 2026-03-18 | **KILL** (legacy V3 Node+MySQL, conflita com DAP4.0) |
| `pm2-root.service` | PM2 daemon | Rodando | **KEEP** (daemon), mas remover apps órfãos |
| `fail2ban` | brute-force SSH | Rodando | **KEEP** |

### 2.2 PM2 apps

| Name | Script | CWD | Uptime | Decisão |
|---|---|---|---|---|
| `Minato` | `/root/.openclaw/workspace/agents/minato-dev/handler.js` | openclaw | Reiniciando constantemente (888+ restarts) | **KILL** |
| `tulio-proxy` | `/root/tulio-proxy/dist/server.js` | tulio-proxy | 8d up | **KILL** — outra encarnação thales-agent |

### 2.3 Openclaw cluster (`/root/.openclaw/workspace/agents/`)

9 agentes sub-dir: `donna-assistant`, `inactivity-watcher`, `minato-dev`, `minato-gemini`, `openclaw-skill-agent`, `persona-maker`, `rival-bot`, `simone-assistant`, `telegram-controller`

- `minato-dev/response.log` = **26 MB ativo** (continua escrevendo)
- Diretório `.openclaw/` com ~16 sub-pastas — é um framework inteiro
- **Decisão:** **KILL** todos via `pm2 delete`, arquivos ficam em `/root/.openclaw/` pra recuperação se necessário

### 2.4 Cron jobs root

| Cron | Comando | Estado | Decisão |
|---|---|---|---|
| `*/5 * * * *` | `/root/vault-sync.sh` (pull/push `thales-vault` no GitHub) | Running fine, log em `vault-sync.log` | **KEEP** — sync Obsidian vault PITOS |
| `0 * * * *` | `cd /root/agentes_pmo/davi_gatuno && python3 agente_davi_gatuno.py` | Running, cron ativo | **KEEP** — Davi Gatuno operacional |

### 2.5 Davi Gatuno (ativo, KEEP)

- **Path:** `/root/agentes_pmo/davi_gatuno/`
- **Processos:** `oauth_server.py` + `webhook_server.py` (porta 9444)
- **Nginx route:** `/etc/nginx/sites-available/webhook-davi` → SSL via Let's Encrypt `srv1303948.hstgr.cloud`
- **Status real:** **PAUSADO** aguardando scope `chats` do Kommo (conforme memory `project_davi_gatuno.md` 09/04)
- **Decisão:** **KEEP** infraestrutura; o trabalho de reclassificação é da fase seguinte.

---

## 3. Diretórios `/opt` e `/root` (FS)

| Path | Conteúdo | Decisão |
|---|---|---|
| `/opt/doctor-auto-ai/` | Stack DAP4.0 alvo | **KEEP** |
| `/opt/doctor-auto-ia/` | cópia "IA" (typo ou branch antigo) | **KILL FS** (após confirmar sem dado útil) |
| `/opt/doctor-auto-ia-old/` | legacy | **KILL FS** |
| `/opt/doctor-auto-prime/` | Node V3 + MySQL, rodando via systemd | **KILL FS** após stop do service |
| `/opt/agente-thales/` | thales-agent tentativa 1 | **KILL FS** |
| `/opt/whatsapp-thales/` | thales-agent tentativa 2 | **KILL FS** |
| `/opt/evolution/` | evolution legacy | **INVESTIGATE** antes |
| `/root/doctor-ai/` | DAP4.0 tentativa prévia | **KILL FS** |
| `/root/doctor-ai-dashboard/` | Evolution API compose ativo | **INVESTIGATE** (pode ter config WhatsApp em uso) |
| `/root/backend-agente-thales/` | thales-agent tentativa 3 | **KILL FS** |
| `/root/tulio-proxy/` | thales-agent tentativa 4 | **KILL FS** após PM2 delete |
| `/root/.openclaw/` | cluster de 9 agentes openclaw | **KILL FS** após PM2 delete (⚠️ 26MB log ativo) |
| `/root/agentes_pmo/davi_gatuno/` | Davi Gatuno | **KEEP** |
| `/root/thales-vault/` | Obsidian PITOS mirror (vault-sync cron) | **KEEP** |
| `/root/ai-systems/` | ??? | **INVESTIGATE** |

**Observação:** KILL FS é **2ª fase**, após confirmar que stop dos serviços não derrubou nada importante. Esta auditoria só para + desabilita.

---

## 4. Portas TCP em uso

| Port | Processo | Decisão |
|---|---|---|
| 22 | sshd | KEEP |
| 80, 443 | **nginx** (restaurado) — vai brigar com Caddy quando DAP4.0 subir | KEEP nginx, decidir TLS depois |
| 3000 | PM2 `tulio-proxy` | LIBERAR (kill) |
| 8080 | `doctor-ai-dashboard-evolution-1` (Evolution API WhatsApp) | INVESTIGATE antes |
| 9444 | `webhook_server.py` (Davi Gatuno) | KEEP |

---

## 5. Mutações aplicadas em 2026-04-10

- [x] `systemctl start nginx` — 03:55 UTC — nginx ativo, webhook Davi Gatuno restaurado
- [x] `systemctl stop + disable doctor-auto-prime.service` — 04:00 UTC — inactive, unit link removido
- [x] `pm2 delete Minato tulio-proxy` + `pm2 save --force` — 04:00 UTC — PM2 vazio, dump persistido
- [x] `docker compose -p doctor-auto-ai down` — 04:01 UTC — stack e redes limpas
- [x] Pin `chromadb/chroma:latest → 0.5.23` em `/opt/doctor-auto-ai/docker-compose.prod.yml` (backup `.bak-2026-04-10`)
- [x] `docker volume rm doctor-auto-ai_chroma_data` — volume stale removido
- [x] `docker compose up -d chromadb python-agents` — **seletivo**, sem caddy/gateway (caddy conflita com nginx 80/443)
- [x] Verificado: `python-agents Up (healthy)`, chromadb `Up`, healthcheck `/health 200 OK`, 7 collections criadas, Kimi + Thales + Scheduler (4 jobs) inicializados

### Resultado final (atualizado 10/04 final)

**Phase 1 (processos):**
Antes: python-agents crashloop, nginx down 6d, 2 PM2 apps órfãos, 1 systemd service legacy, build process travado 11d.
Depois: python-agents healthy, nginx up, PM2 vazio, doctor-auto-prime.service disabled, build process morto.

**Phase 2 (filesystem + docker):**
- 11 diretórios órfãos deletados (2.7 GB)
- 30 docker volumes órfãos removidos
- ~70 GB reclaimados (imagens 13.7 GB + build cache 56 GB + dirs 2.7 GB)
- Disco: 157 GB usado → ~87 GB usado (34% → ~22%)

**Estado final da VPS:**
- 5 containers rodando (gateway, python-agents, chromadb, evolution, evolution-db)
- 6 volumes (4 DAP4.0 + 2 Evolution)
- Swap 4 GB ativo (swappiness=10)
- Cloudflare Tunnel systemd service
- nginx (SSL webhook Davi + DAP4 reverse proxy 3080)
- Davi Gatuno (webhook 9444 + cron)
- vault-sync (cron 5min)

**Preservado:**
- `/opt/doctor-auto-ai/` (DAP4.0 stack ativa)
- `/root/doctor-ai-dashboard/` (Evolution API compose — migrar pra doctor-auto-ai depois)
- `/root/agentes_pmo/davi_gatuno/`
- `/root/thales-vault/`

---

## 6. Decisões pendentes (para depois da consolidação)

1. **TLS edge:** nginx (atual, Let's Encrypt manual) vs Caddy (no compose DAP4.0, auto-TLS). Uma escolha.
2. **Cloudflare Tunnel** (conforme `project_dap4.md`): quando ligar `doctorautoprime40.com` DNS → Cloudflare → Tunnel → container. Elimina nginx E Caddy como edge público.
3. **Evolution API (port 8080):** quem depende? DAP4.0 novo usa Meta Business API direto ou Evolution? Se Meta direto → **KILL** Evolution. Se Evolution → manter e versionar.
4. **Backup:** nenhuma estratégia atual. Proposta: Hostinger snapshot semanal + backup ChromaDB volume quando tiver dado real.
5. **Swap:** 0 B em 31 GB RAM. OOM mata sem aviso. Ativar 4-8 GB de swap file.
6. **`/opt/evolution/`, `/root/ai-systems/`:** nem sei o que são. Investigar antes de decidir.

---

## 7. Próximos passos

1. Executar mutações listadas em §5 (em curso em 2026-04-10)
2. Voltar às decisões pendentes em §6
3. Atualizar este inventário a cada passo com data/resultado
4. Quando limpo: criar snapshot Hostinger antes de qualquer deploy novo
