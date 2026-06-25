# DAP4 Legacy Code Archive Report

**Snapshot date:** 2026-05-05
**Source:** `C:\dev\dap4`
**Operator:** Phase 0 cutover archive (read-only)

## HEAD State

| Field | Value |
|---|---|
| HEAD commit | `f28063bdfbdfdc538691f2484a6aba9fce4d9c24` |
| Short hash | `f28063b` |
| Subject | `fix(auth): implementa rota /reset-password (magic link de recovery)` |
| Active branch | `feat/anna-shadow-mode` |
| Upstream tracking | **none configured** (branch is local-only) |
| Working tree dirty? | **YES** — 3 modified, 6 untracked items |
| Stashes | none |

## Bundle

| Field | Value |
|---|---|
| Path | `code/dap4-legacy-2026-05-05.bundle` |
| Size | **1.6 MB** (compressed git pack) |
| `git bundle verify` | **PASS** — "is okay" + "complete history" |
| Refs included | **43 refs** (9 local branches + 28 remote-tracking + 6 tags + HEAD) |
| Hash algorithm | sha1 |
| Working tree size | 57 MB (excluding node_modules / .next / dist) |

## Branches

- **9 local branches** (incl. `master`, `feat/anna-shadow-mode` (HEAD), `feat/anna-phase1a`, `feat/oficina-pro-merge`, `feat/whatsapp-kommo`, `design/dap4-vitrine-fixes`, `feat/fase0-instrumentacao-700k`, `fix/splash-loop-consultor`, `rebase-attempt`)
- **28 remote-tracking branches** under `origin/`
- **6 tags**: `0613b-rename-complete`, `parliament-v0.1-phase-01-e2e-ok`, `plan-rodada-0-approved`, `pre-0613b-rename-safe`, `pre-rodada-0`, `pre-squash-snapshot`

## Remote

- **Origin:** `https://github.com/toliveira1802-sketch/dap4.git`

## Working Tree Artifacts (uncommitted)

### Modified (committed parents only — diff in `working-tree-diff.patch`)
- `gateway/src/index.ts`
- `gateway/src/routes/meta-webhook.routes.ts`
- `gateway/src/services/realtime.ts`

### Untracked source files (copied to `untracked-anna-shadow/`)
Anna shadow-mode in-flight work:
- `gateway/src/routes/anna-drafts.routes.ts`
- `gateway/src/services/anna-config.service.ts`
- `gateway/src/services/anna-drafts.service.ts`
- `supabase/migrations/20260506_01_anna_drafts.sql`

### Untracked artifacts skipped
- `dashboard/dev-projects-preview.png` (regeneratable)
- `dashboard/screenshots/` (test outputs)

### Secrets (NOT captured — see `UNTRACKED-FILES.md`)
- `.env`, `portal-familia/.env.local`, `tools/kommo-scraper/.env`

## Archive Contents (`code/` directory)

| File | Purpose |
|---|---|
| `dap4-legacy-2026-05-05.bundle` | Full git history (all branches, all tags) |
| `git-log-snapshot.txt` | Last 100 commits, oneline format |
| `working-tree-diff.patch` | 228-line uncommitted diff against HEAD |
| `UNTRACKED-FILES.md` | Inventory of untracked files + env files (names only) |
| `untracked-anna-shadow/` | Source-only copy of in-flight Anna shadow-mode files |
| `CODE-ARCHIVE-REPORT.md` | This file |

## Restore Instructions

### Clone from bundle (recovers full history + all branches)

```powershell
cd C:\dev
git clone "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Backups\dap4-cutover-2026-05-05\code\dap4-legacy-2026-05-05.bundle" dap4-restored
cd dap4-restored
git remote remove origin                    # bundle is the "origin" — reset
git remote add origin https://github.com/toliveira1802-sketch/dap4.git
git fetch origin                            # pull latest if GitHub repo still alive
git checkout feat/anna-shadow-mode          # recover HEAD branch
```

### Reapply uncommitted work

```powershell
# After clone, restore the Anna shadow-mode in-flight files:
Copy-Item -Recurse "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Backups\dap4-cutover-2026-05-05\code\untracked-anna-shadow\*" "C:\dev\dap4-restored\<dest>"

# Reapply modified-file diff:
git apply "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Backups\dap4-cutover-2026-05-05\code\working-tree-diff.patch"
```

### Restore secrets

`.env` files are NOT in this bundle. Recover from:
1. VPS snapshot: `vps/` directory in this same Backups folder
2. Recreate from `.env.example` templates (already inside bundle, also at `untracked-anna-shadow/root.env.example`)
3. Rotate any leaked credentials before reuse

## Verification Status

- [x] Bundle created
- [x] Bundle verified (`git bundle verify` → PASS)
- [x] All 9 local branches captured
- [x] All 6 tags captured
- [x] All 28 remote-tracking refs captured
- [x] HEAD commit hash recorded
- [x] Working tree diff captured
- [x] Untracked source files preserved
- [x] Secrets explicitly excluded with inventory
- [x] Repo state untouched (read-only operation)
