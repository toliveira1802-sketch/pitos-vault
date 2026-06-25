# Untracked Files Inventory — C:\dev\dap4

Snapshot date: 2026-05-05
Branch at snapshot: `feat/anna-shadow-mode`

## Source files captured (no secrets) — copied to `untracked-anna-shadow/`

In-flight work for Anna shadow mode (not yet committed):

- `gateway/src/routes/anna-drafts.routes.ts` (8.2 KB)
- `gateway/src/services/anna-config.service.ts` (2.7 KB)
- `gateway/src/services/anna-drafts.service.ts` (6.8 KB)
- `supabase/migrations/20260506_01_anna_drafts.sql` (6.3 KB)

These represent uncommitted feature work on the shadow-mode branch. Also see `working-tree-diff.patch` for modifications to:
- `gateway/src/index.ts`
- `gateway/src/routes/meta-webhook.routes.ts`
- `gateway/src/services/realtime.ts`

## Untracked binary / test artifacts (NOT captured)

Skipped intentionally:
- `dashboard/dev-projects-preview.png` (preview, regeneratable)
- `dashboard/screenshots/` (test screenshots dir)

## Env files inventory (NOT captured — contain secrets)

Files present in working tree with credentials. **Names listed for restore reference only — contents NOT included.**

### Root-level
- `.env` (production secrets — Supabase keys, OpenAI, Anthropic, Kommo, Meta WABA tokens)
- `.env.example` (tracked in git, also copied to `untracked-anna-shadow/root.env.example` for convenience)

### Sub-projects
- `portal-familia/.env.example` (tracked)
- `portal-familia/.env.local` (untracked — local Supabase URL/keys for portal)
- `tools/kommo-scraper/.env` (untracked — Kommo API token)
- `tools/kommo-scraper/.env.example` (tracked)
- `infra/.env.production.example` (tracked)

### Archived (already snapshot in `_archive/`)
- `.local/backups/2026-04-24/.env.example`
- `_archive/2026-04-23/codigo-dup-downloads/.env.example`
- `_archive/2026-04-23/dashboard-git/.env.example`
- `_archive/2026-04-24/portal-dev-abortado-swarm/.env.example`

## docker-compose files (all tracked in git — included in bundle)

- `docker-compose.yml`
- `docker-compose.dev.yml`
- `infra/docker-compose.prod.yml`

## Restore notes for secrets

Real `.env` files live ONLY on:
1. The legacy VPS (`76.13.170.42:/opt/doctor-auto-ai/`) — see `vps/` snapshot folder
2. Thales' working tree at `C:\dev\dap4\.env` (not snapshotted here)

To rotate or restore secrets, pull from VPS or recreate via `.env.example` templates inside the bundle.
