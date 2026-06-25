---
type: handoff
date: 2026-04-16
time: 05:13
project: DAP4 / Parliament
topic: Rename Sophia-agente para 0613-B + Anna nos 2 pipelines Kommo + smoke test Bosch
tags: [handoff, claudin, parliament, kommo, anna, 0613-b]
---

# Handoff — Sophia rename (0613-B) + Anna multi-pipeline + smoke test Bosch

## Contexto

3 frentes abertas nessa sessão, todas parte da ativação Phase 1a do DAP4.0:

1. **Rename da Sophia-agente** — existe pessoa real no Kommo chamada Sophia. O agente (CEO/Presidente do Parliament) precisa de nome novo. Thales escolheu o codename **0613-B** (é agente pessoal dele, não cadeira corporativa — codename faz sentido funcional).

2. **Anna cobrindo 2 pipelines no Kommo** — Doctor Auto Prime + Doctor Auto Bosch. Hoje o código `agents/agents/ana.py` não separa por pipeline. Precisa configurar filtro/routing.

3. **Smoke test no pipeline novo Bosch** — validar fluxo end-to-end (webhook → Anna → resposta) no pipeline Bosch recém-criado antes de liberar produção.

Sessão foi interrompida pra handoff antes de qualquer code change ou decisão arquitetural final.

## O que funcionou (com evidência)

- **Mapeamento do estado atual** — lido `agents/agents/ana.py` (304 linhas), `agents/config/settings.py`, `agents/parliament/clevel_registry.py`. Confirmado:
  - Sophia = AGENT type, CEO/Presidente Parliament (id=sophia)
  - Anna = AGENT type, CSO·Sales (id=anna)
  - 11 outras cadeiras = SKILL type (3 ativas: francisco/pitoco/zoraide; 8 deferidas)
  - Settings tem `kommo_token` e `kommo_domain` (singular — não separa Prime/Bosch ainda)
  - Anna.py não tem noção de pipeline, flag `pipeline` só aparece em `lead_data.metadata.pipeline` no follow-up
- **Excalidraw com 3 arquiteturas renderizado** — checkpoint ID `07e13fa398f8492daf`. Thales viu, não confirmou export ainda.

## O que NÃO funcionou (e por quê)

- **Escolha de nome humano** — propus Helena/Vera/Beatriz (top 3 por aderência ao padrão Parliament). Thales vetou todos e escolheu codename **0613-B** porque Sophia é agente PESSOAL dele, não cadeira corporativa. Lesson: agente pessoal ≠ cadeira do Parliament, não precisa seguir naming convention.
- **Comunicação ambígua inicial** — Thales disse "somente B" depois de lista numerada 1/2/3. Interpretei como letra B, ele reinterpretou como codename novo. Causou ida-e-volta.

## O que ainda não foi tentado

- Decisão entre as 3 arquiteturas (opções 1, 2, 3 do Excalidraw).
- Qualquer alteração de código (rename, multi-pipeline, smoke test).
- Export do Excalidraw pra vault ou URL compartilhável.
- Checagem de onde exatamente "Sophia" aparece no dashboard (`dashboard/src/components/parliament/SynthesisPanel.jsx`) e no gateway (`gateway/src/routes/dashboard.routes.ts`, `gateway/src/routes/webhook.routes.ts`).
- Verificar se o ID da pipeline Bosch nova está registrado em algum `.env` ou config.

## Arquivos tocados

Nenhum — só leitura.

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\dev\dap4\agents\agents\ana.py` | Lido (304 linhas) | Não tem filtro por pipeline. `lead_data.metadata.pipeline` existe em followup mas não afeta routing |
| `C:\dev\dap4\agents\config\settings.py` | Lido | `kommo_token` / `kommo_domain` singular. Pode precisar expandir pra multi-pipeline |
| `C:\dev\dap4\agents\parliament\clevel_registry.py` | Lido | Sophia registrada em linha 29 como `CLevelSpec("sophia", "Sophia", "CEO · Presidente", CLevelKind.AGENT, ...)` |

## Arquivos que provavelmente precisam mudar (quando rename for executado)

Descobertos via grep `sophia|Sophia|SOPHIA` em `C:\dev\dap4`:

- `agents/parliament/clevel_registry.py` — registro canônico
- `agents/parliament/synthesis.py` — lógica de síntese
- `agents/parliament/prompts/sophia_synthesis.yaml` — prompt (arquivo precisa rename também)
- `agents/parliament/quorum_rules.py`
- `agents/parliament/tests/test_clevel_registry.py`
- `dashboard/src/components/parliament/SynthesisPanel.jsx`
- `dashboard/src/pages/SecondBrain.jsx`
- `gateway/src/routes/dashboard.routes.ts`
- `gateway/src/routes/webhook.routes.ts`
- `CHECKPOINT.md`, `FEATURE_MAP.md`
- `docs/superpowers/specs/2026-04-15-anna-parliament-command-center-integration.md`
- `docs/superpowers/specs/_archive/2026-04-15-dap4-launch-scope.md`
- `docs/superpowers/previews/2026-04-14-parliament-ui-preview.html`
- `docs/superpowers/checkpoints/2026-04-14-parliament-phase-01.md`
- `docs/superpowers/plans/2026-04-14-parliament-phase-01.md`
- `docs/superpowers/specs/2026-04-14-parliament-design.md`

## Decisões tomadas

- **Nome novo = 0613-B** — codename. Razão: Sophia é agente pessoal do Thales (não cadeira corporativa do Parliament), então codename faz sentido funcional e marca distinção.
- **Arquitetura = Opção 3 (híbrido)** — confirmado pelo Thales no final da sessão. 0613-B = voz pessoal ACIMA do Parliament + preside de fora quando convocado. Parliament fica com 12 cadeiras humanas, SEM cadeira CEO interna. Codename = singular/pessoal, nomes humanos = coletivo/corporativo.
- **Anna = agente único, cobre os 2 pipelines** — não vai haver "Anna Prime" e "Anna Bosch" separadas. Uma Anna, dois pipelines.
- **Smoke test só no pipeline novo Bosch** — pipeline Prime já está validado; o risco está no novo.

## Bloqueios & perguntas abertas

- **Arquitetura: RESOLVIDA — Opção 3 (híbrido)**. ✅
- **Qual é o `pipeline_id` do Bosch novo no Kommo?** Não encontrado em settings/env. Thales precisa fornecer.
- **Mensagem/fluxo do smoke test** — minha sugestão original foi perdida no `/clear` inicial. Precisa ser redefinida na próxima sessão.
- **Export do Excalidraw** — perguntei se salva no vault PITOS ou exporta URL, sem resposta.

## Próximo passo exato

Executar Opção 3 em branch `feat/0613-b-rename`:

1. **Criar 0613-B como agente externo** — nova classe `agents/agents/personal_0613b.py` (ou similar), não entra no `clevel_registry.py`.
2. **Remover cadeira CEO do Parliament** — deletar `CLevelSpec("sophia", ...)` do `clevel_registry.py`. Parliament fica com 12 cadeiras (Anna + 11).
3. **Ajustar `synthesis.py` e `quorum_rules.py`** — hoje dependem de Sophia como presidente interno. Refactor pra aceitar "presidente externo" (0613-B chama Parliament e sintetiza as vozes retornadas).
4. **Rename/mover prompt** — `agents/parliament/prompts/sophia_synthesis.yaml` → mover pra escopo do 0613-B (fora do Parliament), ou refatorar.
5. **UI Parliament** — `dashboard/src/components/parliament/SynthesisPanel.jsx` + `SecondBrain.jsx`: remover cadeira "Sophia", adicionar indicador "presidido por 0613-B (externo)".
6. **Gateway routes** — `gateway/src/routes/dashboard.routes.ts` e `webhook.routes.ts`: trocar referências.
7. **Tests** — `agents/parliament/tests/test_clevel_registry.py`: remover asserts sobre Sophia, adicionar asserts sobre ausência de CEO interno.
8. **Docs** — atualizar todos os `.md` em `docs/superpowers/` + `CHECKPOINT.md` + `FEATURE_MAP.md`.

**Em paralelo (não bloqueia rename):**

9. Pedir ao Thales `pipeline_id` do Bosch novo.
10. Redesenhar smoke test flow (proposta: criar lead-teste com número controlado, disparar webhook Kommo manualmente, verificar Anna responde no pipeline certo).

**Ordem sugerida na próxima sessão:**
- Começar perguntando ao Thales pipeline_id Bosch (bloqueador pro smoke test)
- Enquanto espera, abrir branch e começar rename 0613-B (items 1-4)
- UI + docs (items 5-8) depois do core estar verde
- Smoke test como última validação

## Setup / comandos úteis

```bash
# Ver Sophia em todo o dap4
cd C:/dev/dap4
grep -rn "sophia\|Sophia\|SOPHIA" --include="*.py" --include="*.ts" --include="*.tsx" --include="*.jsx" --include="*.yaml" --include="*.md"

# Restaurar Excalidraw
# checkpoint ID: 07e13fa398f8492daf
# (via mcp__claude_ai_Excalidraw__read_checkpoint)

# Stack DAP4 na VPS
ssh root@76.13.170.42
cd /opt/doctor-auto-ai
docker compose ps
```
