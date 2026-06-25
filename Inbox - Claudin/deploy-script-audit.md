---
type: audit
date: 2026-04-18
project: DAP4.0
topic: Security audit ops/deploy-kommo-rc1.sh pré-deploy
tags: [audit, deploy, security, ops, dap4]
---

# Security + reliability audit — `ops/deploy-kommo-rc1.sh`

**Script:** `C:\dev\dap4\ops\deploy-kommo-rc1.sh` (303 LoC, bash)
**Target:** VPS `76.13.170.42`, `/opt/doctor-auto-ai/`, Caddy stack, Supabase project `acuufrgoyjwzlyhopaus` (5911 leads)
**Reviewed commit state:** current working copy at audit time (2026-04-18)
**Runbook cross-ref:** `C:\dev\dap4\ops\GO_LIVE_RUNBOOK.md` Phases 9–12

---

## 1. Resumo executivo

**Verdict: RUN WITH CAVEATS — não é BLOCK, mas três ajustes recomendados antes de apertar.**

O script é defensivo na maioria dos lugares certos: `set -euo pipefail`, `ON_ERROR_STOP=1` no psql, `confirm()` antes de destrutivo, snapshot do SHA anterior pra rollback, migrations já vêm wrapped em `BEGIN/COMMIT` e são idempotentes (`IF NOT EXISTS`, `ON CONFLICT`). Preflight cobre os 6 env vars Kommo, o gate do backup Supabase é interativo, e smoke isola HMAC rejection + worker boot.

O que me preocupa, em ordem de impacto:

1. **`SERVICES_TO_REBUILD` default inclui serviço que não existe (`python-agents`)** — o compose tem `agents`, não `python-agents`. `docker compose build python-agents` vai falhar com `no such service`. **Isto bloqueia Phase 3 na primeira execução** a menos que `DAP4_SERVICES` seja sobrescrito. HIGH.
2. **Backup Supabase é gate humano, não verificado.** O script só pergunta "backup recente?"; confia no Y. 5911 leads em risco com um prompt de 1 linha. Recomendo adicionar check via API/CLI (`supabase db backups list` ou query em `pg_stat_wal_receiver` via psql) pra não depender de autodeclaração. MEDIUM.
3. **`git reset --hard` em Phase 3 joga fora qualquer commit local que ainda não esteja em `origin/${TARGET_BRANCH}`.** Stash cobre working tree, mas não cobre commits locais que o root fez direto na VPS (acontece em hotfixes). Risco real dado o histórico de "toca na VPS às 3am". MEDIUM.

Os demais findings são MEDIUM/LOW/portabilidade. Nenhum CRITICAL. Script pode rodar desde que o operador (a) exporte `DAP4_SERVICES="gateway agents"`, (b) confirme backup com evidência, e (c) confirme `git status` limpo na VPS antes.

---

## 2. Findings table

| Sev | Location | Description | Suggested fix |
|---|---|---|---|
| HIGH | L34 | `SERVICES_TO_REBUILD="${DAP4_SERVICES:-gateway python-agents agents}"` lista `python-agents`, que não existe no `docker-compose.yml`. Serviço real é `agents`. `dc build python-agents` retorna `no such service` e aborta Phase 3. | Trocar default para `"gateway agents"`, ou validar no preflight que cada serviço em `SERVICES_TO_REBUILD` aparece em `dc config --services`. |
| HIGH | L199–212 | `git fetch + checkout + reset --hard` descarta commits locais não-pushed silenciosamente. Stash (L208) só cobre working tree dirty; não commits ahead de `origin/HEAD`. Num host onde root edita direto (hotfix às 3am), perde-se trabalho sem aviso. | Antes do `reset --hard`, rodar `git rev-list --count ${REMOTE}/${TARGET_BRANCH}..HEAD` — se > 0, avisar quantos commits vão ser descartados e pedir `confirm`. Opcionalmente criar tag `pre-deploy-YYYYMMDD-HHMMSS` antes do reset. |
| MED | L126–142 | Backup Supabase é declarativo (prompt "Is backup <1h old? y/N"). Nenhuma verificação real. 5911 leads dependem de o operador não digitar "y" no automático. | Chamar `supabase backups list --project-ref acuufrgoyjwzlyhopaus --json` (ou `pg_stat_wal_receiver` via psql) e exigir que o último backup tenha `< 60min`. Fallback continua sendo o confirm humano, mas com evidência. |
| MED | L169 | Cada migration é aplicada em psql separado. Se `_02` falhar, `_01` já fez commit — estado parcial aplicado. Idempotência das migrations protege re-run, mas a doc diz "transactional" e não é (é per-file). | Documentar claramente que rollback parcial = Supabase PITR restore, não automático. Ou envolver as 4 migrations num único `psql -1 -f combined.sql` (single-transaction) se Supabase aceitar schema + ALTER + seed junto. |
| MED | L243 | Smoke do `/api/health` usa `wget` dentro do container. Se a imagem do gateway não tiver `wget` (alpine com BusyBox tem, Debian slim pode não ter), retorna erro e loop falha 24 vezes antes de abortar (2min esperando). | Usar `curl` como fallback ou `node -e "fetch(...)"` (já comprovado no runbook Phase 5). Matar o loop no primeiro erro de execução (não de HTTP). |
| MED | L256–266 | Probe HMAC aceita `401`, `403` OR `404` (com warn). Se USE_KOMMO_HUB está `false`, retorna 404 e o script considera OK sem testar HMAC de fato. Possível falso-verde: se a rota montar mas HMAC estiver desligado por bug, o script não pega. | Só aceitar 401. Se 404, falhar o smoke phase e pedir que operador ative USE_KOMMO_HUB antes do próximo run. |
| MED | L270 | Verificação de worker boot usa `grep -qi "handoff.*ttl.*worker.*start"` em 200 linhas de log. Se o gateway foi reiniciado há mais de 200 linhas de log atrás, o match falha mesmo com worker ativo. Flaky. | Aumentar `--tail 2000`, ou melhor: verificar um endpoint/metric (ex: `kommo_worker_uptime_seconds` via `/metrics`). |
| MED | L60 | `container()` resolve nome via `grep -E "(^|-)$1(-|$)"`. Se há dois containers com substring comum (ex: `gateway-canary` + `gateway`), pega o primeiro do `head -1` — pode ser o errado. | Ancorar com `--filter "name=^${name}$"` ou exigir match exato. |
| MED | L10 | Uso docs mostra `export SUPABASE_DB_URL="postgresql://postgres:PASSWORD@..."` em shell. Variável vaza no histórico do bash do root (`.bash_history`) e em `ps` durante execução. | Exigir `.pgpass` (chmod 600) ou ler de `${ENV_FILE}` (que já é 600). Ou `read -sp "DB URL: "` antes da phase de migrations. |
| MED | L208 | `git stash push -u -m "pre-rc1-deploy-..."` empilha silenciosamente. Nenhum log indica ao operador que precisa dar `git stash pop` depois se for rollback. | Logar explicitamente o stash name + instrução de pop no rollback section. |
| LOW | L211 | `git checkout "${TARGET_BRANCH}"` sem `--` separator; se alguém setar `DAP4_TARGET_BRANCH=-f` via env injection, vira flag. Baixo risco (root controla env), mas é higiene. | `git checkout -- "${TARGET_BRANCH}"` ou `git switch "${TARGET_BRANCH}"`. |
| LOW | L41 | `-h/--help` faz `sed -n '2,20p' "$0"` — não imprime as flags reais nem exemplos completos. Usuário que roda `--help` não vê `PHASE`, `ASSUME_YES`, `DAP4_SERVICES`, `SUPABASE_DB_URL` required. | Expandir bloco de comentário ou implementar `usage()` com todas variáveis de config. |
| LOW | L176 | Query `rls_check` usa `qual LIKE '%current_setting%IS NOT NULL%'`. Fragilidade: se RLS policy usar sintaxe equivalente mas texto diferente (`COALESCE(current_setting(...), '') <> ''`), falso-negativo e o warn dispara sem motivo. | Escrever probe funcional: tentar SELECT sem `app.current_tenant` setado e validar que retorna 0 rows. |
| LOW | L53 | `ASSUME_YES=1` bypassa TODOS os confirms, inclusive o backup Supabase. Uma flag pra skip gate de 5911 leads. | Separar: `ASSUME_YES` cobre operacionais; `SKIP_BACKUP_GATE` explícito e destacado pra backup. |
| LOW | L104 | `grep -E "^${v}=" | cut -d= -f2- | tr -d '"' | tr -d "'" | tr -d '[:space:]'` — parsing frágil de .env. Valores com `=` são OK (cut -f2-), mas valores com whitespace interno (raro) viram ruído. Comentários inline (`KEY=val # note`) não são strip. | Usar `set -a; source "${ENV_FILE}"; set +a` em subshell, ou ler via `env -i bash -c '...'`. |
| LOW | L60 | `container gateway` scan de docker compose a cada call — um por smoke phase é OK, mas se usado em loop, pode ser lento. Não é gargalo real aqui. | Cache em variável. |

---

## 3. Cross-phase risks

- **Ordering / atomicity de `--phase=all`:** executa preflight → migrations → code → smoke (L284-287). Se migrations aplica schema e code falha no build, ficamos com schema novo + código antigo. **Não é regressão quebrada** porque migrations são aditivas (IF NOT EXISTS) e `USE_KOMMO_HUB` default false protege, mas ficamos num estado não testado. Mitigação: rodar phases separadas em produção.
- **Secrets em logs:** `set -x` não é ativado, bom. `psql` com connection string no CLI **aparece em `ps auxww`** durante a execução (visível a qualquer user com `/proc`). Mitigar via `.pgpass` ou `PGPASSWORD` env isolado. O `SUPABASE_DB_URL` exportado também pode vazar em core dumps. MEDIUM.
- **SSH interruption mid-script:** script não usa `trap EXIT` ou `nohup`. Se a sessão SSH cair durante Phase 2 (migrations), estado pode ser: _01_ e _02_ aplicados, _03_ abortado mid-commit (Postgres roll-back interno cuida), mas _04_ não rodou. Re-run cobre (idempotência), desde que operador saiba. Recomendação: rodar dentro de `tmux` ou `screen`. Não é fix no script, é fix no procedimento.
- **Re-run safety:** migrations OK (idempotentes). Code phase OK (reset --hard é idempotente por definição). Smoke OK. **Preflight backup gate repetido é chato** — operador pode bater "y" no piloto automático depois da 3ª tentativa. Humano falha aqui; script não.
- **Rollback lever (USE_KOMMO_HUB=false):** confirmado no script footer. Bom. Hard rollback manual (checkout + rebuild) também documentado. Ambos fora-de-banda, OK.
- **Phase ordering se rodadas isoladas:** rodar `--phase=code` sem migrations primeiro **não falha sintaticamente** mas quebra runtime (código espera tabelas que não existem). Script não previne. Documentação do `--help` deve dizer "phases em ordem".

---

## 4. Portability notes

- `set -euo pipefail` — OK.
- `shopt -s inherit_errexit` — bashism, mas guarda com `|| true`, OK.
- `trap ERR / EXIT` — **ausente.** Recomendado adicionar `trap 'die "unexpected error at line $LINENO"' ERR` pra mensagem mais clara em falha inesperada.
- **GNU-only flags detectados:**
  - L83: `df -m --output=avail` — `--output` é GNU coreutils. Ubuntu OK, Alpine BusyBox NÃO. VPS roda Ubuntu, OK.
  - L104: `grep -E` — POSIX, OK.
  - L176: `psql -At` — psql-only, OK.
  - `printf '\033[33m...\033[0m'` — ANSI escapes, OK em terminais Unix, **não** em redirect pra arquivo sem `-t` check. Log fica com lixo se rodado sob `tee output.log`.
- **Bash-only:** `[[ ]]`, arrays `required_kommo=(...)`, `=~` regex — todo bash 4+. Ubuntu 24.04 tem bash 5.x, OK.
- **`docker compose` (v2):** confirma via `docker compose version` no preflight. Bom.
- **`read -rp`:** bash-only, OK.

---

## 5. Nice-to-haves (não bloqueadores)

- Adicionar `--dry-run` flag que imprime o que faria sem tocar.
- Log estruturado JSON opcional (para grepar depois).
- Gravar um ID de deploy (`DEPLOY_ID=$(uuidgen)`) e propagar como tag em `docker build --label deploy_id=...` pra audit trail.
- Imprimir no final: SHA antigo, SHA novo, timestamp, duração de cada phase, link pro commit no GitHub.
- Após smoke OK, opcionalmente rodar `curl -fsS https://doctorautoprime40.com/api/health` externamente (via Caddy) como verificação E2E de tunnel.
- Verificar Caddy + chromadb **antes** de tocar no gateway/agents. Script checa "`dc ps`" geral mas não exige que esses dois específicos estejam `Up (healthy)`. Se Caddy está down, deploy passa mas tráfego externo não chega.
- Adicionar métrica `kommo_brand_resolve_fallback_total` baseline no fim do smoke (garantir = 0 pré-tráfego real).
- Testar RPC `rpc_anna_inbox_claim_next` chamando com role simulada, não só verificando `pg_proc` (L181). Função existe ≠ função funciona.

---

## 6. Pre-run sign-off checklist

Antes de apertar `./ops/deploy-kommo-rc1.sh --phase=all` na VPS, confirmar:

### Hard blockers (resolver ou BLOCK)

- [ ] `DAP4_SERVICES="gateway agents"` exportado OU o default no script editado pra remover `python-agents` (finding HIGH L34).
- [ ] `git -C /opt/doctor-auto-ai status` limpo (nenhum commit ahead de `origin/feat/kommo-prod-rc1`; nenhum stash pendente que importa).
- [ ] Backup Supabase manual tirado nas últimas 60min — verificado via Dashboard → Backups (print/screenshot salvo no vault).
- [ ] `feat/kommo-prod-rc1` no remote = SHA esperado da auditoria de código (verificar com `git log --oneline -1 origin/feat/kommo-prod-rc1` local vs VPS).

### Soft gates (verificar)

- [ ] Rodar DENTRO de `tmux` ou `screen` na VPS (SSH pode cair).
- [ ] `SUPABASE_DB_URL` **não** vai pro `.bash_history` — exportar com `HISTCONTROL=ignorespace` + `  export ...` (leading space) ou usar `.pgpass`.
- [ ] Confirmar `.env.production` tem 6/6 Kommo vars + `USE_KOMMO_HUB=false` pro primeiro deploy (safe default, vira `true` depois do smoke passar).
- [ ] Confirmar que Caddy (`doctor-auto-ai-caddy-1`) e chromadb estão `Up (healthy)` antes de iniciar. Se algum estiver down, abortar: preflight não pega.
- [ ] Rodar primeiro `--phase=preflight` isolado, revisar output, depois `--phase=migrations`, depois `--phase=code`, depois `--phase=smoke`. **Não usar `--phase=all` no primeiro deploy.**
- [ ] Ter aberto em outra janela: `docker compose logs -f gateway | grep -iE "kommo|anna_inbox|error"` pra watch em tempo real.
- [ ] Tel do rollback na cabeça: `sed -i 's/^USE_KOMMO_HUB=true/USE_KOMMO_HUB=false/' .env.production && docker compose restart gateway`.

### Post-run validation

- [ ] Contagem `anna_inbox` pre-/post-deploy idêntica (nenhum insert espúrio durante deploy).
- [ ] `kommo_hmac_failures_total = 0` no `/metrics` logo após smoke.
- [ ] External curl: `curl -fsS https://api.dap.doctorautoprime40.com/api/health` = `{"status":"ok"}`.
- [ ] Commit da pré-deploy checklist + link pra este audit no ClickUp / vault.

---

## Apêndice A — Evidência de config referenciada

- `docker-compose.yml` linhas 2/16/38: services declarados são `chromadb`, `agents`, `gateway` (+ caddy em outro arquivo/override). **Confirmado: `python-agents` não existe** — finding HIGH L34 é real.
- Migrations em `/c/dev/dap4/supabase/migrations/`: 4 arquivos presentes, todos começam com `BEGIN;` e terminam com `COMMIT;`, usam `IF NOT EXISTS` e `DROP POLICY IF EXISTS ... CREATE POLICY ...`. Idempotência confirmada.
- `.env.example` existe em `/c/dev/dap4/` — referência pra montar `.env.production`, não usada pelo script.

---

**Auditor:** Claude (Opus 4.7)
**Escopo:** script + runbook cruzado, sem executar.
**Próximos passos recomendados:** aplicar fix HIGH L34, rodar `--phase=preflight` em dry-run contra staging ou off-hours, publicar este doc no vault antes do deploy.
