---
parent: "[[03 - PROJETOS/DAP 4.0 1/dap-gestao/README]]"
tags:
  - dap40
  - deploy
  - runbook
  - gestao
  - vps
  - ops
---

# Deploy & Runbook — DAP Gestão

## Topologia

```
[GitHub: toliveira1802-sketch/dap-gestao @ master 8fb25a7]  (privado)
                    │
                    │ git pull (manual)
                    ▼
[VPS Hostinger 76.13.170.42]                          [Supabase DOCTOR PRIME]
  /opt/dap-gestao/                                    acuufrgoyjwzlyhopaus.supabase.co
  ├─ git checkout master                                          │
  ├─ npm ci → node_modules/                                       │
  ├─ npm run build → dist/index.cjs + dist/public/                │
  └─ .env (perm 600, root)                                        │
                    │                                              │
                    │  Service: dap-gestao.service (systemd)       │
                    │  Listen: 0.0.0.0:5003                        │
                    ▼                                              │
  @supabase/supabase-js ◄───── HTTPS REST + SUPABASE_SERVICE_ROLE_KEY
                    │
                    │  schema gestao
                    ▼
[cloudflared.service (tunnel "dap4")]
                    │
                    ▼
[Cloudflare Edge]
  └─ gestao.doctorautoprime40.com → localhost:5003 (HTTP)
                    │
                    │ HTTPS auto, TLS edge, DDoS protection
                    ▼
                  [Browser]
```

## Secrets & environment

`.env` em `/opt/dap-gestao/.env` (chmod 600, dono root):

```bash
# Supabase project (DOCTOR PRIME). Schema gestao isolado de public/oficina.
SUPABASE_URL=https://acuufrgoyjwzlyhopaus.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<JWT do service_role — bypass RLS>

# Express session (memorystore in-process)
SESSION_SECRET=<64 hex chars — openssl rand -hex 32>

# Bootstrap admin (apenas primeiro boot — remover depois)
BOOTSTRAP_ADMIN_PASSWORD=<mín. 12 chars>

PORT=5003
NODE_ENV=production
```

Senha admin atual (rotacionar após primeiro acesso): `XKluH75r71TIA1jCDIEo7H`

## systemd unit

`/etc/systemd/system/dap-gestao.service`:

```ini
[Unit]
Description=DAP Gestao (P0) - portal executivo
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/dap-gestao
EnvironmentFile=/opt/dap-gestao/.env
ExecStart=/usr/bin/node /opt/dap-gestao/dist/index.cjs
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dap-gestao
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

## Comandos operacionais

### Status / saúde
```bash
ssh root@76.13.170.42 'systemctl status dap-gestao'
ssh root@76.13.170.42 'systemctl is-active dap-gestao'
ssh root@76.13.170.42 'journalctl -u dap-gestao -n 50 --no-pager'
ssh root@76.13.170.42 'journalctl -u dap-gestao -f'         # logs ao vivo
ssh root@76.13.170.42 'ss -tlnp | grep 5003'                # confere binding
```

### Deploy de uma nova versão
```bash
# Local: garantir push
git push origin master

# VPS:
ssh root@76.13.170.42 'cd /opt/dap-gestao &&
  git pull origin master &&
  npm ci &&
  npm run build &&
  systemctl restart dap-gestao &&
  sleep 2 &&
  systemctl is-active dap-gestao'
```

One-liner:
```bash
ssh root@76.13.170.42 'cd /opt/dap-gestao && git pull && npm ci && npm run build && systemctl restart dap-gestao'
```

### Smoke test pós-deploy
```bash
COOKIE=$(mktemp)
curl -s -c "$COOKIE" -X POST https://gestao.doctorautoprime40.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"<senha>"}' \
  -w "\nlogin -> %{http_code}\n"
curl -s -b "$COOKIE" https://gestao.doctorautoprime40.com/api/auth/me \
  -w "\nme -> %{http_code}\n"
rm -f "$COOKIE"
```

### Rollback
```bash
ssh root@76.13.170.42 'cd /opt/dap-gestao &&
  git log --oneline -10 &&
  git checkout <hash-anterior> &&
  npm ci && npm run build &&
  systemctl restart dap-gestao'
```

### Backup do schema gestao

Postgres Supabase tem **PITR built-in**. Pra dump manual:
```bash
ssh root@76.13.170.42 'PGPASSWORD=<password> pg_dump \
  -h db.acuufrgoyjwzlyhopaus.supabase.co -p 5432 -U postgres \
  -d postgres -n gestao --no-owner --no-acl \
  -f /opt/dap-gestao/gestao_$(date +%Y%m%d-%H%M%S).sql'
```

## Cloudflare Tunnel

Mesmo tunnel `dap4` do dap-operacao. Hostname adicional:

```
gestao.doctorautoprime40.com  →  localhost:5003 (HTTP, edge termina TLS)
```

Configuração via dashboard (Zero Trust → Networks → Tunnels → dap4 → Public Hostname).

## Migrations DB

Schema vive em `gestao.*` no Postgres remoto. Migrations aplicadas via Supabase MCP `apply_migration` ou `psql` direto:

```bash
PGPASSWORD=<password> psql \
  -h db.acuufrgoyjwzlyhopaus.supabase.co -p 5432 -U postgres \
  -d postgres -f gestao_v1.sql
```

> **Sempre tirar PITR snapshot ou pg_dump antes** de rodar migration.

## Troubleshooting

### Service não sobe
1. `journalctl -u dap-gestao -n 50` — ler erro
2. Causa comum:
   - `SUPABASE_URL` ou `SUPABASE_SERVICE_ROLE_KEY` faltando ou inválida
   - Em produção, falta de users na `gestao.users` + falta de `BOOTSTRAP_ADMIN_PASSWORD` recusa o boot

### Login retorna 200 mas sessão não persiste (404 no /me em produção)
**Causa**: cookie `secure: true` sendo dropado porque Express não confia no proxy.
**Fix**: confirmar `app.set("trust proxy", 1)` em `server/index.ts`. Já presente desde scaffold.

### "Invalid schema: gestao" no client Supabase
**Causa**: schema `gestao` não exposto ao PostgREST.
**Fix**: rodar `ALTER ROLE authenticator SET pgrst.db_schemas TO 'public, gestao'` + `NOTIFY pgrst, 'reload schema'`. Já configurado em DOCTOR PRIME.

### Cloudflare 502
1. Confirmar `dap-gestao.service` ativo e listening em 5003
2. Confirmar `cloudflared.service` ativo
3. Confirmar hostname `gestao.doctorautoprime40.com` configurado no tunnel `dap4`

### Memória crescendo
1. `systemctl show -p MemoryCurrent dap-gestao`
2. Sessions in-memory (memorystore) com TTL 24h e sweep 60min — leak improvável
3. Se passar de ~150MB sustentado, investigar cache global no app code

## Métricas de referência (estado atual)

| Métrica                    | Valor                            |
| -------------------------- | -------------------------------- |
| Uptime intencionado        | ~24/7 (single VPS)               |
| RAM em idle                | ~30 MB                           |
| Build time                 | ~12s (vite) + ~3s (esbuild)      |
| Cold-start até "serving"   | ~2s                              |
| Bundle entry (gzip)        | ~12 KB                           |
| Latência por request DB    | 80–120ms (us-west-2 round trip)  |

## Roadmap operacional

- [ ] Trocar senha admin via UI no primeiro login
- [ ] Remover `BOOTSTRAP_ADMIN_PASSWORD` do `.env` da VPS após primeiro acesso
- [ ] Conectar com `oficina.*` (cross-schema) pra agregação de KPIs reais
- [ ] Ler `public.campaign_leads` (P1) pra funil consolidado
- [ ] Job `node-cron` de snapshot diário 6h da manhã (`gestao.kpi_snapshots`)
- [ ] UI real pra OKRs + ADRs (hoje WIP editorial honesto)
- [ ] Recharts com trend lines depois dos snapshots existirem
- [ ] Theme dark-first cinematográfico (CLAUDE.md target)
- [ ] Migrar sessions pra `connect-pg-simple` quando virar multi-instance
