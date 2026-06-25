---
type: handoff
date: 2026-04-16
time: 17:09
project: DAP4.0
topic: Plano de execução Phase 1a Kommo Hub aprovado e salvo
tags: [handoff, claudin, dap4, phase1a, kommo, anna]
---

# Handoff — Phase 1a Kommo Hub: plano aprovado, pronto pra executar

## Contexto

Sessão do `/multi-plan` pra planejar Phase 1a "Anna no ar" via Kommo Hub. Anna é AGENT que qualifica leads no WhatsApp 24/7, escala pro Thales (+55 11 96729-1822) quando não sabe, sincroniza Supabase/Kommo, com smoke test inicial no pipeline Bosch (12704980) antes de ligar pro Prime.

Sessão substitui o plano Meta Cloud direto (descartado em 2026-04-15) — Kommo vira hub multi-canal (WA+FB+IG já conectados). Produto da sessão: **plano de execução completo** em `C:\dev\dap4\.claude\plan\dap4-phase1a-kommo-hub.md` pronto pra `/ccg:execute`.

Wrapper `~/.claude/bin/codeagent-wrapper` não existe nessa máquina, então rodei multi-perspectiva via subagents paralelos (`architect` + `planner`) em vez de Codex+Gemini.

## O que funcionou (com evidência)

- **Retrieval de contexto** — evidência: Read direto de `docs/superpowers/specs/2026-04-15-kommo-hub-phase1a.md` (269 linhas) + `git log feat/whatsapp-kommo feat/anna-phase1a` revelou que ~50% do Kommo Hub já tá implementado.
- **Subagent architect** — evidência: devolveu análise opinativa de 1200 palavras identificando 6 gaps críticos do spec (multi-pipeline, branch strategy, LISTEN/NOTIFY + Supabase pooler, handoff TTL, per-lead cost cap, HMAC secret rotation).
- **Subagent planner** — evidência: devolveu step plan de 1500 palavras com 48 arquivos mapeados, 8 milestones M0-M7, 16 riscos, 4 gates de rollout.
- **Síntese** — evidência: plano gravado em `.claude/plan/dap4-phase1a-kommo-hub.md` combinando ambas perspectivas; 5 decisões abertas apresentadas ao Thales em linguagem simples.
- **Aprovação das 5 decisões pelo Thales** — todas as recomendações mantidas, plano atualizado marcando decisões como travadas.
- **Memória atualizada** — evidência: `project_dap4_phase1a_ia_no_ar.md` agora reflete status 2026-04-16 + referencia o arquivo do plano.

## O que NÃO funcionou (e por quê)

- **Subagent `Explore` inicial** — falhou porque: retornou alucinação tipo "você disse pra não usar tools, respondo só texto" sem nenhuma instrução prévia minha que corresponda. Resíduo de contexto de outra sessão/agent vazou no prompt do subagent. Solução: fiz exploração direta com Glob/Grep/Read em paralelo em vez de delegar.
- **Wrapper `codeagent-wrapper`** — falhou porque: `/multi-plan` depende de `~/.claude/bin/codeagent-wrapper` que não existe localmente. Não instalável sem setup de API keys Codex/Gemini. Rodeei com subagents `architect` + `planner` nativos.
- **Leitura de `kommo-webhook.routes.ts` existente** — falhou porque: não existe nessa branch ainda. Webhook atual deve estar embutido em `webhook.routes.ts` genérico ou nunca foi extraído — não investiguei mais fundo porque o plano vai criar o arquivo novo.

## O que ainda não foi tentado

- Invocar `/ccg:execute` — o próximo passo óbvio. Recomendação: dividir em 5 sessões por grupo de milestones pra não estourar contexto:
  1. M0 + M1 (fixtures + migrations) ~6h
  2. M2 (gateway kommo.service + webhook) ~7h
  3. M3 (worker + Anna 2-stage) ~9h
  4. M4 + M5 (escalação + observability) ~10h
  5. M6 + M7 (RTBM + smoke Bosch) ~6h + 48h observação
- Instalar `codeagent-wrapper` pra multi-model real (Codex+Gemini) nas próximas features — bloqueado até Thales decidir se quer gastar em mais um canal de LLM.
- Confirmar com curl real os shapes Kommo Chats v2 + CRM v4 — bloqueado pelos env vars (M0 humano).

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\dev\dap4\.claude\plan\dap4-phase1a-kommo-hub.md` | Completo | Plano de execução completo, 48 arquivos mapeados, decisões travadas |
| `C:\Users\docto\.claude\projects\C--Users-docto\memory\project_dap4_phase1a_ia_no_ar.md` | Atualizado | Status 2026-04-16 + referência ao plano + 5 decisões Thales |
| `C:\dev\dap4\.claude\` | Criado | Diretório novo no repo (antes não existia) |

Nenhum código do projeto foi tocado — sessão foi 100% planning.

## Decisões tomadas

- **Nova branch `feat/kommo-hub-phase1a` off `rodada-0-foundation` + cherry-pick** — razão: ambas branches existentes (`feat/anna-phase1a` 16 commits + `feat/whatsapp-kommo` 21 commits) divergiram com assumptions incompatíveis (Meta direct vs Kommo hub); rebase é mais arriscado que harvest seletivo.
- **2-stage inference (Haiku 4.5 classifica + Sonnet 4.5 responde)** — razão: ~60% corte de custo, gate de escalação mais confiável (keywords de crise detectadas antes do Sonnet), `intent_classifier.py` em feat/whatsapp-kommo já meio pronto (só swap gpt-4o-mini → Haiku).
- **`kommo_channels` DB table + YAML fallback** — razão: multi-tenant Chairman OS futuro precisa de routing hot-editable sem redeploy; YAML fica como belt-and-suspenders.
- **Meta fallback codepath gated 30 dias pós go-live** — razão: se Kommo WhatsApp provider banir o número ou API cair, flag `USE_KOMMO_HUB=false` volta pra Meta direto em 5min. Deletar só após 30 dias de estabilidade Kommo.
- **DAP Performance mesmo `tenant_id='dap_prime'`** — razão: mesma entidade legal Thales, diferenciação via `brand_id` é suficiente; `tenant_id` reservado pra separação legal/billing (futuro SaaS externo).
- **Handoff TTL explícito** (spec gap) — razão: `handoff_pending` sem TTL é bug factory. Travei: 30min → Anna ping; 4h → cortesia Thales; 24h → auto-close `stalled`.
- **Per-lead cost cap** (spec gap) — razão: troll pode loop-baitar Anna em 500 turns. Travei: 40 turns + 80k tokens/lead/24h.

## Bloqueios & perguntas abertas

### Bloqueios humanos (Thales) — ordem:

1. **KOMMO_TOKEN + KOMMO_DOMAIN** no VPS `.env` (curl `/api/v4/account` retornar 200)
2. **KOMMO_CHATS_CHANNEL_SECRET** (HMAC-SHA1 secret do Kommo Chats)
3. **KOMMO_THALES_USER_ID** (numérico, via `GET /api/v4/users`)
4. **Kommo Chats channel registration** (`/api/v2/origin/custom/{scope_id}`) — sem isso, outbound `sendMessage` não funciona
5. **Subdomain confirmation** (`doctorautoprime.kommo.com`?)
6. **Curl-shape fixtures** (fogo teste WA no Bosch +551138240025, captura payload)
7. **Prime pipeline_id + custom field IDs** (Bosch=12704980 já confirmado, Prime TBD)
8. **RTBM document** (`agents/config/rtbm/dap_prime.md` + `bosch.md`) — bloqueia só M6
9. **VPS deploy window** (30min pra M7)

### Perguntas abertas (baixa prioridade):
- Nenhuma — todas as 5 perguntas de design foram travadas pelo Thales.

## Próximo passo exato

Thales tem duas rotas paralelas:

**Rota A — Thales desbloquear humano (M0 blockers):**
1. Entrar no Kommo portal, gerar/copiar `KOMMO_TOKEN` (long-lived v4, scope crm) + `KOMMO_DOMAIN` + `KOMMO_CHATS_CHANNEL_SECRET` + `KOMMO_THALES_USER_ID` pro `.env` do `C:\dev\dap4`.
2. Registrar canal Chats custom (`POST /api/v2/origin/custom/{scope_id}`).
3. Avisar Claudin.

**Rota B — Claudin executar o plano (paralelo):**

```bash
cd C:\dev\dap4
/ccg:execute .claude/plan/dap4-phase1a-kommo-hub.md
```

Primeira sessão de execução deve focar **M0 + M1 só** (fixtures + migrations) — não precisam dos env vars ainda, usam fixtures mock. Grupos seguintes precisam credencial real.

## Setup / comandos úteis

```bash
# Ver branches Anna/Kommo
cd C:\dev\dap4
git branch -a | grep -E "anna|kommo|rodada"

# Ver plano
cat .claude/plan/dap4-phase1a-kommo-hub.md

# Ver specs de referência
ls docs/superpowers/specs/2026-04-15-*
ls docs/superpowers/specs/_archive/

# Memória
cat C:/Users/docto/.claude/projects/C--Users-docto/memory/project_dap4_phase1a_ia_no_ar.md
cat C:/Users/docto/.claude/projects/C--Users-docto/memory/reference_kommo_pipelines.md

# Quando for executar
cd C:\dev\dap4
git checkout rodada-0-foundation
git pull
git checkout -b feat/kommo-hub-phase1a
/ccg:execute .claude/plan/dap4-phase1a-kommo-hub.md
```
