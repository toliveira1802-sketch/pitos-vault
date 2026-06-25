# Snapshot pre-monorepo cutover — 2026-05-06

Bundles `git bundle create --all` dos 4 repos legacy DAP4 antes da consolidação em monorepo `dap4-portals`. Safety net pra Task 0.1 do plano `2026-05-06-dap4-monorepo-migration.md`.

## Bundles

| Repo | Branch (HEAD) | HEAD SHA | Bundle SHA-256 | Size |
|---|---|---|---|---|
| dap-aios | feat/aios-nucleo-consultor | 64c5dc9ca490ec1da0bb9c7e6cc371a53874be87 | 6e3ec6448e54297421968156b7b5a8d4a2d3507efadc178e763389318489e264 | 1.291.942 B |
| dap-operacao | master | bf31214d60f5fee547a75af7a996b208972e50db | 1da7fef3f9b1d5052420d4a35facf63b0b587dff8c6542204ff665e4d899c4be | 365.879 B |
| dap-gestao | master | 8fb25a740269fa2e4e661a816af9eea0269d03e0 | 71560818d0ad7f9be5ded1b8d3646f12115fff77f0a0d3846bb50eff8480b194 | 128.133 B |
| dap-tools | adc-DAp40 | e7473669e4a513704ecbcbc340adac8a95442e93 | 379ab1995e56d8426c7ebf4e970998602052bc56720fa6aa769f94a11a5b4a6f | 950.855 B |

Hash algorithm dos bundles: SHA-1 (git default). Hash do arquivo bundle: SHA-256.

## Refs preservadas

- **dap-aios** (9 refs): `feat/aios-nucleo-consultor`, `master`, `refactor/monorepo`, espelhos `origin/*`, tag `pre-monorepo`
- **dap-operacao** (7 refs): `master`, `feat/os-detail`, `feat/postgres-migration`, `origin/hardening/backend-pass1`
- **dap-gestao** (3 refs): `master` + espelho `origin/master`
- **dap-tools** (6 refs): `adc-DAp40`, `main`, `origin/adc-DAp40`, `origin/main`

## Verify

Cada bundle foi validado com `git bundle verify` na criação:
```
The bundle records a complete history.
The bundle is okay.
```

## Restore

Pra restaurar qualquer repo a partir do bundle:

```bash
# Clone direto
git clone "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Backups/monorepo-cutover-2026-05-06/<repo>.bundle" <dest>

# Ou unbundle dentro de um repo existente
git bundle unbundle "C:/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/Backups/monorepo-cutover-2026-05-06/<repo>.bundle"
```

## Verify hash

```powershell
Get-FileHash "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Backups\monorepo-cutover-2026-05-06\<repo>.bundle" -Algorithm SHA256
```
