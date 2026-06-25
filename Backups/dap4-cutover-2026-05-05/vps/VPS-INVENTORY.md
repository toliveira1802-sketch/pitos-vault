# VPS Inventory — DAP4 Cutover Phase 0

**Host:** `76.13.170.42` (Hostinger, srv1303948)
**Snapshot taken:** 2026-05-05 ~14:58 UTC (~11:58 BRT)
**Mode:** Read-only inventory. Nothing stopped, restarted, or modified.
**Backup dir:** `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Backups\dap4-cutover-2026-05-05\vps\`

---

## 1. System health

| Metric | Value |
|---|---|
| Uptime | 57 days (load avg 0.96 / 0.88 / 0.91) |
| Disk `/` | 32G used / 387G total (9% — plenty of headroom) |
| RAM | 4.8G used / 31G total, 26G available |
| Swap | 984M / 4G |

No disk pressure. No memory pressure. Box is healthy.

---

## 2. Containers running

5 containers, all UP, 4 of 5 explicitly **healthy**:

| Container | Image | Uptime | Health | Internal port |
|---|---|---|---|---|
| `doctor-auto-ai-gateway-1` | `doctor-auto-ai-gateway` | 21h | healthy | 3001 |
| `dap4-agents` | `doctor-auto-ai-agents` | 10 days | healthy | 8000 |
| `dap4-chromadb` | `chromadb/chroma:0.5.23` | 11 days | healthy | 8000 |
| `dap4-portal-familia` | `doctor-auto-ai-portal-familia` | 10 days | (no probe) | 80 |
| `dap4-caddy` | `caddy:2-alpine` | 10 days | (no probe) | 80, 443 |

Compose project name: `doctor-auto-ai`. Compose file at `/opt/doctor-auto-ai/docker-compose.yml`.

> **Note:** `docker compose ps` emits a warning that `CLOUDFLARE_TUNNEL_TOKEN` is not set in the env (token lives in the systemd unit instead — by design, harmless).

---

## 3. Disk: docker volumes

| Volume | Size | Notes |
|---|---|---|
| `doctor-auto-ai_chroma_data` | **184K** | active chromadb data |
| `doctor-auto-ai_caddy_data` | 20K | TLS state |
| `doctor-auto-ai_caddy_config` | 12K | caddy config |
| `doctor-auto-ai_uploads_data` | 4K | empty |
| `dap4_brain` | 4K | empty (orphan from prior compose) |
| `dap4_uploads` | 4K | empty (orphan) |
| `dap4_chroma` | 4K | empty (orphan) |

Three `dap4_*` volumes are orphans, all empty (4K each = just dir metadata). No data at risk in them.

---

## 4. ChromaDB — collections + RAG state

7 collections registered, **all empty (0 embeddings each)**.

| Collection name | UUID | Embeddings |
|---|---|---|
| `study_car_manuals` | 05aa3aef-… | 0 |
| `study_industry_news` | cdb9df8f-… | 0 |
| `study_diagnostic_kb` | e49354a8-… | 0 |
| `study_business_insights` | 7a5df9d0-… | 0 |
| `ops_client_support` | f45135b5-… | 0 |
| `ops_service_procedures` | 9fd88ad4-… | 0 |
| `ops_pricing_guidelines` | e45d23ed-… | 0 |

> **Key finding:** memory said only `ops_*` was empty — actually **all 7 are empty**. RAG layer is fully unpopulated in prod. No data loss risk on cutover.

Disk path on container: `/chroma/chroma/` (sqlite + 3 segment dirs + 167K `chroma.sqlite3`). Host bind: `/var/lib/docker/volumes/doctor-auto-ai_chroma_data/_data`.

### Snapshot status

- Created on VPS: `/tmp/chromadb-snapshot-2026-05-05.tar.gz` — **7.4K**
- Downloaded locally: `vps/chromadb-snapshot-2026-05-05.tar.gz` (7.4K, verified)
- Contains the entire `_data` dir (sqlite + segment dirs).

---

## 5. Cloudflare Tunnel

- Service: `cloudflared.service` — **active** since 2026-05-04 15:15 UTC (23h uptime)
- Mode: token-based (no `/etc/cloudflared/config.yml`); ingress config pulled from CF dashboard
- 4 QUIC connections to GRU edge (gru02, gru11, gru13, gru19)
- Memory: 17.3M

Ingress (live in cloudflared logs, last reload 2026-05-05 13:13 UTC):

| Hostname | Origin |
|---|---|
| `webhook.doctorautoprime40.com` | localhost:80 |
| `app.doctorautoprime40.com` | localhost:80 |
| `dap.doctorautoprime40.com` | localhost:80 |
| `portal.doctorautoprime40.com` | localhost:80 |
| `aios.doctorautoprime40.com` | localhost:80 |
| `operacao.doctorautoprime40.com` | **localhost:5001** (added today) |

`operacao.*` was added today — points at the dap-operacao node service (P0 portal, see §7).

---

## 6. Anna activity (last hour)

**Anna IS active.** Gateway is enqueueing `anna_inbox` events, agents container is running RAG count probes against ChromaDB every ~10s.

Evidence:
- `anna_inbox enqueued` events at 14:41:38–14:41:40 (7 events) and 14:52:27 (3 events) — brand `dap_prime`
- ~14 `inbox event skipped (no text)` events same window — Kommo webhook sending non-text events (likely status/contact updates)
- Agents process polling all 7 chroma collections every ~10s and answering `200 OK` (RAG is wired, just empty)

> **However**: `.env` has `AI_AUTOREPLY_ENABLED=false`. Anna receives and processes WhatsApp/Kommo events but **does NOT auto-reply** in prod. This matches the known "Anna paused" state.

---

## 7. Surprise: dap-operacao is already on this VPS

Beyond the docker stack, there is a **systemd service** running:

```
dap-operacao.service — DAP Operacao (P0) - portal consultor
  Active since 2026-05-05 13:56 UTC (1h)
  /usr/bin/node /opt/dap-operacao/dist/index.cjs
  Listening on 0.0.0.0:5001
```

Express app, stats endpoint returns all-zeros (totalOrders 0, totalCustomers 0, etc.). Thales logged in as `admin` at 14:04 UTC today — confirmed alive. `operacao.doctorautoprime40.com` cloudflare ingress was added today to expose it.

This means the same VPS is now hosting **both** P1 (docker stack) and P0 (dap-operacao native node). Cutover plan must account for this.

---

## 8. Other services on the box

Running systemd services worth knowing about:

- `nginx.service` — listening 443 + 127.0.0.1:3080 (reverse proxy, role unclear without config inspection)
- `mysql.service` — listening 127.0.0.1:3306 + 33060 (legacy MySQL; not used by docker stack)
- `pm2-root.service` — running but `pm2 list` is empty (no managed processes)
- `fail2ban`, `chrony`, `unattended-upgrades` — standard hardening
- Two `python3` listeners on `:9443` and `:9444` — unidentified (worth checking before shutdown)

---

## 9. Filesystem `/opt/doctor-auto-ai/`

Active production tree, owned by `root`, last modified Apr 24 (initial deploy). Contains:

- `.env` (3236 bytes, 0700) + 2 backups (`.env.bak.1777910979`, `.env.bak.2026-04-24-sb_publishable`) + `.env.production`
- `agents/`, `gateway/`, `portal-familia/`, `dashboard/`, `dashboard-git/`
- `docker-compose.yml`, `docker-compose.dev.yml`
- `infra/`, `ops/`, `skills/`, `supabase/`, `tools/`
- Docs: `CHECKPOINT.md`, `CLAUDE.md`, `DAP_DESIGN_SYSTEM.md`, `FEATURE_MAP.md`, `HANDOFF.md`, `META_SETUP_GUIDE.md`
- `.git/` present — repo state preserved

`.env` non-secret keys captured in `env-non-secret.txt`:
- `AI_AUTOREPLY_ENABLED=false`
- `KOMMO_DEFAULT_BRAND=dap_prime`
- `KOMMO_DOMAIN=doctorautobosch.kommo.com` (Bosch tenant config — but default brand prime)
- `SUPABASE_URL=https://acuufrgoyjwzlyhopaus.supabase.co`
- `PUBLIC_DOMAIN=dap.doctorautoprime40.com`

---

## 10. Risky items for shutdown

| Item | Risk | Mitigation |
|---|---|---|
| Anna receiving Kommo webhooks | Webhooks will 5xx during downtime; Kommo retries finite | Pre-cutover: pause Kommo webhook OR accept message backlog |
| `operacao.doctorautoprime40.com` newly live | Active prod surface (Thales logging in same day) | Keep dap-operacao running OR migrate before cutover |
| MySQL on 3306 | Unknown what uses it (not docker stack); could be legacy data | Audit + dump before any wipe |
| `python3` on `:9443`/`:9444` | Unidentified processes | Check `ps aux | grep <pid>` before wipe |
| `nginx.service` | Active on 443; role unclear | Config grep needed (likely fronts something pre-Caddy) |
| `.env` only on disk | Secrets not version-controlled | Already covered — keep `.env` + 2 `.env.bak` files in cutover backup |
| ChromaDB volume | Tiny but real | **DONE** — 7.4K snapshot already saved locally |
| `.git/` in `/opt/doctor-auto-ai` | Repo state may be ahead of GitHub | Bundle before wipe (`git bundle create`) |

No CRITICAL blockers. The known data (ChromaDB) is already snapshotted. The two real surprises — `dap-operacao` already on the box and `mysql`/`python3:944x` of unknown ownership — should be inspected before any decommission.

---

## 11. Files in this snapshot

```
vps/
  VPS-INVENTORY.md                       (this file)
  docker-ps.txt
  docker-compose-ps.txt
  docker-volumes.txt
  df-h.txt
  free-h.txt
  uptime.txt
  systemd-running.txt
  opt-doctor-auto-ai-ls.txt
  env-non-secret.txt
  cloudflared-status.txt
  cloudflared-config.txt                 (NO_CONFIG_FILE — token-based)
  chromadb-data-path.txt
  chromadb-collections-api.txt           (v1 empty, v2 returns 7 IDs in agent logs)
  chromadb-heartbeat.txt
  chromadb-collections-detail.txt
  chromadb-counts.txt                    (key — proves all 7 collections empty)
  chromadb-sqlite-collections.txt        (sqlite3 binary missing in image, ignore)
  chroma-volume-mountpoint.txt
  volume-sizes.txt
  gateway-logs-1h.txt
  agents-logs-1h.txt
  extra-services.txt                     (dap-operacao + ports + pm2)
  snapshot-tar.txt
  chromadb-snapshot-2026-05-05.tar.gz    (7.4K, restorable)
```
