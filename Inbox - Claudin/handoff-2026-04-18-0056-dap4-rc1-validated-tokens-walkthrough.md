---
type: handoff
date: 2026-04-18
time: 00:56
project: DAP4.0
topic: rc1 validada por swarm + 2 HIGH do deploy script fixados + walkthrough de tokens em andamento
tags: [handoff, claudin, dap4, phase1a, kommo, rc1, tokens, deploy-prep]
---

# Handoff — rc1 validada, deploy script corrigido, parou no meio do walkthrough de tokens Kommo

## Contexto

Sessão começou com `/resume-handoff` do handoff anterior (2026-04-17-2035) que dizia: 24 arquivos dirty em `feat/kommo-hub-phase1a`, 6 commits semânticos a fazer, merge whatsapp-kommo pendente, deploy prod bloqueado por divergência de branch.

Brainstorming + spec + plan elaborados (superpowers) pra um "swarm de preparação Phase 1a" — 3 fases: pré-commit, 6 commits, 4 subagents paralelos. Plano approved + committed no vault.

Execução começou, Task 1 (verificação de estado) descobriu que **o repo já avançou muito** desde o handoff anterior: outra sessão (ou Thales diretamente) já tinha feito os 6 commits semânticos E criado `feat/kommo-prod-rc1` com merge + deploy script. Plano ficou 80% obsoleto.

Thales optou por **Opção B: reformular pra validação pré-deploy**. Spawnados 4 subagents paralelos validando rc1. Resultados: tests + merge limpos; deploy script com 2 HIGH; RTBM vazio (BLOCK qualidade). Fixados os 2 HIGH (commit `21b796e`). Sessão parou no meio do walkthrough de geração dos 6 tokens Kommo — no Passo 1 (curl pra AMOJO_ID).

## O que funcionou (com evidência)

### Swarm de validação pré-deploy (4 agents paralelos, 1 mensagem)

- **Test Validator:** `gateway npm test` → 103/103 passed. `agents pytest parliament/tests/ tests/test_fixtures_valid.py` → 47/47 passed. `gateway npx tsc --noEmit` → exit 0. HEAD: `7bbd3ab`. Verdict: **DEPLOY-READY**.
- **Merge Forensics (a201387):** **15 audit fixes byte-idênticos preservados** (verificado via `git diff` entre `196a7b7` e `a201387` em 11 arquivos sensíveis). 5 conflitos resolvidos por união não-destrutiva (env.ts, index.ts, main.jsx, Agents.jsx, Layout.jsx). Zero route collision entre `/api/kommo/webhook` (L263, Hub HMAC) e `/api/kommo/*` (L368, authed). 0 HIGH, 2 MED. Relatório: `Inbox - Claudin\merge-forensics-kommo-prod-rc1.md`.
- **Deploy Script Audit:** 2 HIGH + 7 MED + 3 LOW. Relatório: `Inbox - Claudin\deploy-script-audit.md`.
- **RTBM Content Review:** `dap_prime.md` ~20% completo, `dap_bosch.md` ~25% completo, ambos BLOCK. Top 5 edits priorizados. Relatório: `Inbox - Claudin\rtbm-content-review.md`.

### Fix dos 2 HIGH do deploy script (commit `21b796e`)

- **L34:** `SERVICES_TO_REBUILD` default de `"gateway python-agents agents"` (com `python-agents` fantasma) → `"gateway agents"`. Antes: `dc build` abortaria Phase 3 com "no such service".
- **L199-212:** antes do `git reset --hard`, checa `git rev-list --count ${REMOTE}/${TARGET_BRANCH}..${TARGET_BRANCH}`. Se > 0: lista commits que seriam perdidos, cria tag `pre-deploy-recovery-YYYYMMDD-HHMMSS`, exige `confirm`. Recovery via `git reset --hard <tag>`.
- Validação: `bash -n` OK. Diff: +23/-1 em `ops/deploy-kommo-rc1.sh`.

### Mapeamento real dos tokens Kommo

`grep` nos arquivos `.env*` + `src/` revelou estado atual:

| # | Var | Status | Valor / Ação |
|---|-----|--------|--------------|
| 1 | `KOMMO_TOKEN` | ✅ tem | JWT no `.env:27` |
| 2 | `KOMMO_DOMAIN` | ✅ tem | `doctorautobosch.kommo.com` |
| 3 | `KOMMO_INTEGRATION_SECRET` | ✅ tem | `WPqghM9zfal...` (64 chars OAuth) |
| 4 | `KOMMO_CHATS_CHANNEL_SECRET` | ❌ **VAZIO** | precisa registrar custom channel via `amojo.kommo.com/v2/origin/custom` |
| 5 | `KOMMO_THALES_USER_ID` | ✅ tem | `8561711` |
| 6 | `KOMMO_THALES_CHAT_ID` | ❌ **ausente** | precisa descobrir (provavelmente via chat existente ou criar) |

Bonus: `KOMMO_INTEGRATION_ID=788fd119-d9c1-4aca-908d-21d085a259b5`, `KOMMO_ACCOUNT_ID=33504243`.

## O que NÃO funcionou (e por quê)

- **Plano original 80% obsoleto** — premissa do handoff anterior (24 dirty files + nenhum commit) já não refletia a realidade. Lição: `/resume-handoff` precisa ser pareado com verificação imediata de estado antes de gastar tokens brainstormando em cima.

## O que ainda não foi tentado

- **Push `feat/kommo-prod-rc1` pra origin** — local tem `21b796e`, origin não. Bloqueia deploy na VPS (`git fetch + reset --hard` não pega o que não tá no remote).
- **Gerar `KOMMO_CHATS_CHANNEL_SECRET`** — walkthrough começou mas parou no Passo 1 (curl pra AMOJO_ID).
- **Descobrir `KOMMO_THALES_CHAT_ID`** — Passo 3 do walkthrough (não iniciado).
- **Backup Supabase point-in-time** — Thales precisa fazer no dashboard antes de migrations (proj `acuufrgoyjwzlyhopaus`, 5911 leads).
- **RTBM preenchimento** — sessão interativa de ~45min com Thales pra preencher Persona/Produtos/Casos/Exemplos/FAQ/Handoff nos 2 arquivos. **Não bloqueia deploy técnico** (arquivos hot-loaded pelo rtbm_loader.py), mas **bloqueia go-live de qualidade** (USE_KOMMO_HUB=true).
- **Rotacionar senha Kommo em plain text** em `tools/kommo-scraper/.env:4` (`Doctorauto0609@@`). Gitignored (confirmado via `git ls-files`), mas senha em plain text em disco é má prática. Baixa urgência, alta facilidade.
- **Deploy na VPS em si** — `ops/deploy-kommo-rc1.sh --phase=preflight` primeiro, dentro de tmux, com logs em paralelo. Só depois dos tokens + backup.

## Arquivos tocados nesta sessão

| Arquivo | Ação | Notas |
|---------|------|-------|
| `C:\dev\dap4\ops\deploy-kommo-rc1.sh` | M → committed | +23/-1, commit `21b796e` na `feat/kommo-prod-rc1` |
| `Inbox - Claudin\spec-2026-04-17-dap4-phase1a-prep-swarm.md` | new | Spec do swarm original (agora obsoleto) |
| `Inbox - Claudin\plan-2026-04-17-dap4-phase1a-prep-swarm.md` | new | Plan do swarm original (obsoleto) |
| `Inbox - Claudin\merge-forensics-kommo-prod-rc1.md` | new | Análise byte-a-byte dos 15 audit fixes pós-merge |
| `Inbox - Claudin\deploy-script-audit.md` | new | 2 HIGH + 7 MED + 3 LOW do `deploy-kommo-rc1.sh` |
| `Inbox - Claudin\rtbm-content-review.md` | new | Review dap_prime.md + dap_bosch.md, ambos BLOCK |

Estado do repo `C:\dev\dap4`:
- Branch: `feat/kommo-prod-rc1`
- HEAD: `21b796e fix(ops): deploy script — correct service list + guard ahead-commit loss`
- `git status`: só `dashboard-git` submódulo dirty (pré-existente, fora de scope) + `.superpowers/` untracked (já no .gitignore da sessão anterior? Conferir)
- Commits novos que **não estão em origin:** só `21b796e`. `7bbd3ab` também não está em origin (veio de outra sessão e não foi pushed).

## Decisões tomadas

- **Não mexer no merge a201387** — review confirmou 15 fixes preservados byte-idênticos; tocar é só risco.
- **2 MED do merge ficam como gates operacionais, não code fix:**
  - Dual-ingress `/api/webhook/kommo/:secret` vs `/api/kommo/webhook` — decide no painel Kommo qual manter ativo (recomendação: só Hub).
  - `express.urlencoded` global com limit 10mb — avaliar depois do smoke; provavelmente OK em prod.
- **Deploy script foi o HIGH fixável aqui agora** — 2 edits cirúrgicos que não mudam arquitetura, só fecham bugs de execução.
- **RTBM não é blocker de deploy** — arquivos são hot-loaded por `rtbm_loader.py`. Deploy com `USE_KOMMO_HUB=false` é safe independente do RTBM. RTBM vira gate antes de flipar `USE_KOMMO_HUB=true`.
- **Ordem correta revisada:** push rc1 → tokens Kommo → backup Supabase → deploy (phases separadas, tmux) → RTBM session → flip USE_KOMMO_HUB=true.
- **Walkthrough de tokens interativo, não MD offline** — mais rápido pra desbloquear que produzir handbook de referência. 4 dos 6 já tavam prontos no `.env`; só faltam 2.

## Bloqueios & perguntas abertas

### Ação humana (Thales)
1. **Rodar Passo 1 do walkthrough** (comando curl pra AMOJO_ID) — ver seção "Próximo passo exato"
2. **Backup Supabase point-in-time** (dashboard Supabase, proj `acuufrgoyjwzlyhopaus`)

### Questões abertas
- **`KOMMO_TOKEN` ainda é válido?** JWT long-lived, mas sessão não testou. Se curl do Passo 1 retornar 401, renovar em Kommo → Integrations.
- **`KOMMO_THALES_CHAT_ID` como descobrir?** Runbook não tem um endpoint claro. Opções: (a) mandar WA pro número DAP que entra no Kommo → pegar `chat_id` do talks API, (b) criar manualmente via UI Kommo e pegar ID da URL. Precisa de testing real.
- **Push rc1 antes ou depois dos tokens?** Eu sugiro **antes** (`git push origin feat/kommo-prod-rc1`) porque remote não tem os commits. Mas tu disse "me ajuda com os tokens" — prioridade tua.
- **RTBM preenchimento síncrono comigo ou tu faz offline?** Review agent deixou top-5 edits priorizados. 45min juntos vs 2h sozinho.

### Tech debt declarado (fora de scope imediato)
- 10 tasks HIGH/MED pós-deploy do audit anterior (ainda valem): webhook timestamp, notify() real, addTag additive, Anna mídia, rate limit Redis, asInt negativo, typingDelayMs BR, /metrics IP allowlist, rtbm loader asyncio, record_decision typing, dap.yaml env-inject.
- `tools/kommo-scraper/.env:4` tem senha plain text. Gitignored mas rotacionar quando puder.

## Próximo passo exato

**Retomar walkthrough dos tokens. Passo 1:**

No terminal (PowerShell ou bash), com cwd em `C:\dev\dap4`:

```bash
curl -sS "https://doctorautobosch.kommo.com/api/v4/account" \
  -H "Authorization: Bearer $(grep ^KOMMO_TOKEN= C:/dev/dap4/.env | cut -d= -f2-)" \
  | jq .amojo_id
```

Se não tiver `jq`: tira o pipe final e procura `"amojo_id"` no JSON.

Esperado: UUID ou slug tipo `"abc123-xyz"`.

**Me cola o valor.** Se der 401, `KOMMO_TOKEN` expirou — renovar em Kommo → Integrações antes de seguir.

Depois de ter `AMOJO_ID`:

**Passo 2 — registrar custom channel (retorna `KOMMO_CHATS_CHANNEL_SECRET`):**

```bash
AMOJO_ID="<colado do passo 1>"
WEBHOOK_URL="https://webhook.dap.doctorautoprime40.com/api/kommo/webhook"

curl -sS -X POST "https://amojo.kommo.com/v2/origin/custom/${AMOJO_ID}" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $(grep ^KOMMO_TOKEN= C:/dev/dap4/.env | cut -d= -f2-)" \
  -d "{
    \"hook_api_version\":\"v2\",
    \"account_id\":\"${AMOJO_ID}\",
    \"title\":\"DAP Anna\",
    \"hook_url\":\"${WEBHOOK_URL}\"
  }"
```

Response traz `scope_id` (channel-level) E o Kommo provisiona um secret. **Cola a response inteira** — eu extraio `KOMMO_CHATS_CHANNEL_SECRET` e te digo onde colar no `.env.production`.

**Passo 3 — descobrir `KOMMO_THALES_CHAT_ID`:**

A descobrir. Opção A: manda WA do teu celular pro número DAP, aí: `curl -sS "https://doctorautobosch.kommo.com/api/v4/talks?limit=5" -H "Authorization: Bearer $KOMMO_TOKEN" | jq '.[] | select(.contact_id == 8561711).chat_id'`. Opção B: pesquisar docs Kommo se tem endpoint explícito de "my chat id".

## Setup / comandos úteis

```bash
# Estado local
cd C:\dev\dap4
git status                                 # só dashboard-git dirty
git log --oneline -3                       # HEAD = 21b796e (2 HIGH fix)

# Tests verdes (sanity)
cd gateway && npm test                     # 103 passed
cd ../agents && python -m pytest parliament/tests/ tests/test_fixtures_valid.py -q   # 47 passed
cd ../gateway && npx tsc --noEmit          # exit 0

# Push rc1 quando pronto
cd C:\dev\dap4
git push -u origin feat/kommo-prod-rc1

# Deploy na VPS (quando tokens + backup prontos)
# Entrar via: ssh root@76.13.170.42 -i ~/.ssh/id_ed25519
# Dentro de tmux:
cd /opt/doctor-auto-ai
git pull                                   # puxa o push da rc1
./ops/deploy-kommo-rc1.sh --phase=preflight    # primeiro isolado
# revisar output, depois:
./ops/deploy-kommo-rc1.sh --phase=migrations
./ops/deploy-kommo-rc1.sh --phase=code
./ops/deploy-kommo-rc1.sh --phase=smoke

# Rollback de emergência (se qualquer coisa quebrar)
sed -i 's/^USE_KOMMO_HUB=true/USE_KOMMO_HUB=false/' /opt/doctor-auto-ai/.env.production
docker compose -f /opt/doctor-auto-ai/docker-compose.yml restart gateway
```

## Memória/estado semântico (pra próxima sessão saber rapidão)

- Phase 1a Kommo Hub **code-ready**. Bloqueado por 2 tokens humanos (CHANNEL_SECRET + CHAT_ID) + backup Supabase + push remote + RTBM preenchimento.
- Todos os 15 audit fixes preservados no merge — deploy é seguro do ponto de vista de código.
- Deploy script corrigido nos 2 HIGH; MEDs ficam como observability/docs debt.
- Canonical ingress decidido no painel Kommo: **só Hub** (`/api/kommo/webhook`), retirar URL legacy `/api/webhook/kommo/:secret`.
- `USE_KOMMO_HUB=false` no primeiro deploy = postura correta. Flip pra `true` só depois de RTBM acceptable + smoke ok.
