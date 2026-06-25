---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-operacao/README]]"
tags:
  - dap40
  - deploy
  - runbook
  - vps
  - ops
---

# Deploy & Runbook

## Topologia atual (pós-Postgres, 2026-05-05)

```
[GitHub: toliveira1802-sketch/dap-operacao @ master bf31214]
                    │
                    │ git pull (manual)
                    ▼
[VPS Hostinger 76.13.170.42]
  /opt/dap-operacao/
  ├─ git checkout master
  ├─ npm ci → node_modules/
  ├─ npm run build → dist/index.cjs + dist/public/
  └─ .env (perm 600, root) — aponta DATABASE_URL pro Postgres remoto
                    │
                    │ Service: dap-operacao.service (systemd)
                    │ Listen: 0.0.0.0:5001
                    ▼
[cloudflared.service (systemd, mesmo VPS)]                    [Supabase DOCTOR PRIME]
                    │                                          db.acuufrgoyjwzlyhopaus.supabase.co:5432
                    │ tunnel "dap4" (token-based)                          │
                    ▼                                                       │
[Cloudflare Edge]                          drizzle (postgres-js) ◄─────────┤  schema oficina (13 tabelas)
  └─ operacao.doctorautoprime40.com           connect-pg-simple ◄──────────┤  schema public (sessions)
                    │
                    │ HTTPS auto, TLS edge, DDoS protection
                    ▼
                  [Browser]
```

> **Nota histórica:** até 2026-05-05 o data plane era SQLite local (`/opt/dap-operacao/oficina.db`). Migrado pra Postgres Supabase remoto pra unificar com `gestao` + ler dados de P1 (`public.parliament_*`, leads). Ver [[08-postgres-migration]].

## Secrets & environment

`.env` em `/opt/dap-operacao/.env` (chmod 600, dono root):

```bash
# Postgres Supabase (DOCTOR PRIME, schema oficina). Use direct connection
# (port 5432) ou pooler (aws-0-us-west-2:6543). Não inclua sslmode=require
# no URL — server seta { ssl: { rejectUnauthorized: false } } no Pool e
# sslmode no URL sobrepõe esse setting.
DATABASE_URL=postgres://postgres:<password>@db.acuufrgoyjwzlyhopaus.supabase.co:5432/postgres?search_path=oficina,public

# Express session (connect-pg-simple no schema public.session)
SESSION_SECRET=<64 hex chars — openssl rand -hex 32>

# Bootstrap admin (apenas primeiro boot — remover depois)
BOOTSTRAP_ADMIN_PASSWORD=<mín. 12 chars>

PORT=5001
NODE_ENV=production

# Optional pool sizing
# DATABASE_POOL_MAX=10  # postgres-js (drizzle / app data)
# SESSION_POOL_MAX=5    # node-postgres (connect-pg-simple)
```

Senha admin atual (rotacionar após primeiro acesso): `isDMNt2e32KYz4pBNVlQ`

## systemd unit

`/etc/systemd/system/dap-operacao.service`:

```ini
[Unit]
Description=DAP Operacao (P0) - portal consultor
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/dap-operacao
EnvironmentFile=/opt/dap-operacao/.env
ExecStart=/usr/bin/node /opt/dap-operacao/dist/index.cjs
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dap-operacao
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

## Comandos operacionais

### Status / saúde
```bash
ssh root@76.13.170.42 'systemctl status dap-operacao'
ssh root@76.13.170.42 'systemctl is-active dap-operacao'
ssh root@76.13.170.42 'journalctl -u dap-operacao -n 50 --no-pager'
ssh root@76.13.170.42 'journalctl -u dap-operacao -f'         # logs ao vivo
ssh root@76.13.170.42 'ss -tlnp | grep 5001'                  # confere binding
```

### Deploy de uma nova versão
```bash
# Local: garantir push
git push origin master

# VPS:
ssh root@76.13.170.42 'cd /opt/dap-operacao &&
  git pull origin master &&
  npm ci &&
  npm run build &&
  systemctl restart dap-operacao &&
  sleep 2 &&
  systemctl is-active dap-operacao'
```

One-liner pra script:
```bash
ssh root@76.13.170.42 'cd /opt/dap-operacao && git pull && npm ci && npm run build && systemctl restart dap-operacao'
```

### Smoke test pós-deploy
```bash
COOKIE=$(mktemp)
curl -s -c "$COOKIE" -X POST https://operacao.doctorautoprime40.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"<senha>"}' \
  -w "\nlogin -> %{http_code}\n"
curl -s -b "$COOKIE" https://operacao.doctorautoprime40.com/api/auth/me -w "\nme -> %{http_code}\n"
curl -s -b "$COOKIE" https://operacao.doctorautoprime40.com/api/stats -w "\nstats -> %{http_code}\n"
rm -f "$COOKIE"
```

### Rollback
```bash
ssh root@76.13.170.42 'cd /opt/dap-operacao &&
  git log --oneline -10                  # ver commits
  git checkout <hash-anterior> &&
  npm run build &&
  systemctl restart dap-operacao'
```

### Backup do DB

Postgres Supabase tem **PITR built-in** (point-in-time recovery, retention 7 dias no plano padrão). Pra backup manual:

```bash
# Dump completo do schema oficina
ssh root@76.13.170.42 'PGPASSWORD=<password> pg_dump \
  -h db.acuufrgoyjwzlyhopaus.supabase.co -p 5432 -U postgres \
  -d postgres -n oficina --no-owner --no-acl \
  -f /opt/dap-operacao/oficina_$(date +%Y%m%d-%H%M%S).sql'
```

Backups SQLite legados (pré-migração 2026-05-05) ficam em `/opt/dap-operacao/oficina.db.bak.*` — preservados como rede de segurança e parecem rollback rápido.

### Restore

Postgres Supabase: PITR via dashboard (Settings → Database → Backups → Restore to point in time).

Manual via SQL dump:
```bash
ssh root@76.13.170.42 'PGPASSWORD=<password> psql \
  -h db.acuufrgoyjwzlyhopaus.supabase.co -p 5432 -U postgres \
  -d postgres -f /opt/dap-operacao/oficina_<TIMESTAMP>.sql'
```

Rollback da app (sem mexer no DB) pra commit anterior:
```bash
ssh root@76.13.170.42 'cd /opt/dap-operacao &&
  git log --oneline -10 &&
  git checkout <hash-anterior> &&
  npm ci && npm run build &&
  systemctl restart dap-operacao'
```

**Rollback completo da migração Postgres → SQLite (cenário catastrófico):**
```bash
ssh root@76.13.170.42 'cd /opt/dap-operacao &&
  git checkout a830d79 &&
  cp .env.bak.20260505-192201 .env &&
  npm ci && npm run build &&
  systemctl restart dap-operacao'
```
Volta pro `oficina.db` SQLite intacto. < 1min.

## Cloudflare Tunnel

Tunnel gerenciado **token-based** (config remoto via dashboard, não config.yml local):
- Tunnel name: `dap4`
- Token vive em `/etc/cloudflared/.env` (chmod 600)
- Service: `cloudflared.service` (active, autorenew via `cloudflared-update.timer`)

### Adicionar/editar hostname
1. `dash.cloudflare.com` → Zero Trust → Networks → Tunnels
2. Click **dap4** → aba **Public Hostname**
3. **Add a public hostname**:
   - Subdomain + Domain
   - Type: HTTP (Cloudflare termina TLS no edge)
   - URL: `localhost:<port>`

### Logs do cloudflared
```bash
ssh root@76.13.170.42 'journalctl -u cloudflared -n 30 --no-pager'
```

## Migrations DB

Schema vive em `shared/schema.ts` (drizzle pg-core). Drizzle-kit gera SQL em `migrations-pg/`.

```bash
# Gerar nova migration a partir do schema TS:
set -a && source .env && set +a
npx drizzle-kit generate --config=drizzle.config.ts

# Aplicar a migration via Supabase MCP (recomendado, idempotente)
# OU via psql direto contra prod (com cuidado):
PGPASSWORD=<password> psql \
  -h db.acuufrgoyjwzlyhopaus.supabase.co -p 5432 -U postgres \
  -d postgres -f migrations-pg/<arquivo>.sql
```

Migrations SQLite legadas (pré-2026-05-05) ficam em `migrations/` como histórico.

> **Sempre fazer backup (pg_dump) ou tirar PITR snapshot antes** de rodar migration em produção.

## Troubleshooting

### Login retorna 200 mas requests subsequentes retornam 500 com `SELF_SIGNED_CERT_IN_CHAIN`
**Sintoma**: login OK, qualquer endpoint depois falha 500.
**Causa**: `connect-pg-simple` (node-postgres) rejeita cert chain do Supabase (assinado por AWS-RDS CA, não no truststore default do Node).
**Fix**: garantir `ssl: { rejectUnauthorized: false }` no Pool em `server/routes/index.ts` E **não** ter `sslmode=require` no `DATABASE_URL`. Já corrigido em commit `cde12ae`.

### Login retorna 200 mas sessão não persiste (401 no /me)
**Sintoma**: `POST /api/auth/login` → 200, mas `GET /api/auth/me` subsequente → 401.
**Causa**: cookie `secure: true` sendo dropado porque Express não confia no proxy.
**Fix**: confirmar `app.set("trust proxy", 1)` em `server/index.ts`. Já presente desde commit `54e99b2`.

### Service não sobe após deploy
1. `journalctl -u dap-operacao -n 50` — ler erro
2. Causa comum: faltou `npm run build` antes de restart, ou `.env` com chave faltando
3. Em produção, falta de users + falta de `BOOTSTRAP_ADMIN_PASSWORD` recusa o boot (proteção intencional)

### Browser mostra `Cannot set properties of undefined (setting 'Children')`
**Sintoma**: tela em branco no portal, console com erro acima.
**Causa**: dep cíclica entre vendor chunks no manualChunks do Vite — React fica `undefined` quando outro chunk tenta acessar.
**Fix**: usar `manualChunks` em formato objeto (não função). Já corrigido em commit `bf31214`.

### CSP bloqueia `static.cloudflareinsights.com`
**Causa**: Cloudflare Web Analytics injeta beacon.min.js automaticamente. CSP `script-src 'self'` bloqueia.
**Fix**: adicionar `https://static.cloudflareinsights.com` no `script-src` em `server/index.ts`. Já corrigido em commit `bf31214`.

### Memória crescendo
1. `systemctl show -p MemoryCurrent dap-operacao`
2. Sessions agora ficam em Postgres (`public.session`), memorystore foi removido — vazamento é improvável.
3. Se passar de ~200MB sustentado, verificar leak no app code (ex: cache global crescendo sem TTL).

### Cloudflare 502
1. Confirmar `dap-operacao.service` ativo e listening em 5001
2. Confirmar `cloudflared.service` ativo
3. Ver logs do cloudflared

### CSP bloqueando algum recurso novo
- CSP em `server/index.ts` (production branch). Editar diretivas e fazer rebuild.
- Em dev, CSP está **off** — não dá pra reproduzir o problema localmente sem `NODE_ENV=production`.

## Métricas de referência (estado atual)

| Métrica                       | Valor                          |
| ----------------------------- | ------------------------------ |
| Uptime intencionado           | ~24/7 (single VPS)             |
| RAM em idle                   | ~30 MB                         |
| Build time                    | ~13s (vite) + ~3s (esbuild)    |
| Cold-start até "serving on…"  | ~1s                            |
| Bundle entry (gzip)           | 26 KB                          |
| Requests autenticados testados | login, me, vehicles, customers, service-orders, stats, appointments, mechanics, users (todos 200) |

## Roadmap operacional

- [ ] Backup automático diário do `oficina.db` → S3 ou rsync pra outro host
- [ ] Healthcheck endpoint `GET /api/health` (zero-side-effect, sem auth)
- [ ] Cloudflare Cache Rules: `/assets/*` com hash → `cache-control: public, max-age=31536000, immutable`
- [ ] Logrotate dos uploads (limpar attachments de OSs deletadas há >90 dias)
- [ ] Migrar sessions pra Redis quando virar multi-instance
