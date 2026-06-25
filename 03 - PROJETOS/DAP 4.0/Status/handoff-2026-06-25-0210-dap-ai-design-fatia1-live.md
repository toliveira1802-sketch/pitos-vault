---
type: handoff
date: 2026-06-25
time: 02:10
project: DAP AI (motor de diretores)
topic: Design da DAP AI + Fatia 1 (engine + Bianca) + A/D validados ao vivo
tags: [handoff, claudin, dap-ai, chapapiuro]
---

# Handoff — DAP AI: do zero ao loop Chapapiuro↔DAP AI provado

## Contexto
A unidade **DAP AI** era greenfield. Numa sessão: brainstorm → spec → plano → implementação
TDD → review → merge → validação ao vivo. A DAP AI é um **motor de diretores**: cada
"diretor" é uma cadeira C-level (Sophia/CEO, Bianca/CMO, Francisco/CFO, …) cujo **DNA**
(persona/mandato) vive em git (`C:\THALES\ECOSSISTEMA-DAP40\<area>\<cadeira>\CONTEXTO.md`) e
cujo **estado** (memória/eventos/artefatos) viverá no Supabase do AIOS. Um **engine único na
VPS**, alcançável pelo **WhatsApp 24h** via Chapapiuro→Sophia; Claude Desktop é janela
opcional. LLM = Claude. Fatia 1 = esqueleto + Bianca de ponta a ponta, **Fase A (read-only
externo)**. Esta sessão entregou a Fatia 1 E provou o elo Chapapiuro↔DAP AI ao vivo.

## O que funcionou (com evidência)
- **Fatia 1 completa (dap-ai)** — evidência: 23/23 testes verde, cobertura 96.5%, typecheck limpo.
- **Smoke E2E (A)** — evidência: `POST /api/agent/ask` → HTTP 200 em ~12s; a Bianca respondeu
  na voz dela com contexto do DNA (R$300k→R$700k, 45% capacidade).
- **Conector Chapapiuro→DAP AI (D)** — evidência: conector real chamou a DAP AI viva e
  recebeu `{ ok:true, target:'dap-ai', text:'…gargalo de lead+conversão…' }`. 57/57 testes verde.
- **Review final (opus):** APPROVE WITH MINOR; achados de segurança corrigidos.

## O que NÃO funcionou (e por quê) — CRÍTICO, não retentar
- **Dispatch de subagentes caiu 2×** (connection closed mid-response) → pivotei pra execução
  **inline** pras tasks de transcrição mecânica. Mais confiável neste ambiente.
- **`npm` (1º implementer)** gerou `package-lock.json` cruft + bumpou zod pra 4 (quebra
  `required_error`). Padrão correto: **pnpm via corepack** (`corepack pnpm <cmd>`) + **zod 3**.
- **pnpm 11 bloqueia build scripts** → precisa `allowBuilds: esbuild: true` no `pnpm-workspace.yaml`.
- **Boot quebrava com `.env`**: URL opcional vazia (`""`) é rejeitada por `z.url().optional()`.
  Fix: normalizar `""`→`undefined` no parseEnv.
- **Porta 5060 NÃO serve** — é SIP, está na blocklist de "bad ports" do padrão Fetch; o
  `fetch` do Node/browser **recusa** ("bad port"). Só o `curl` funcionava (engana). **→ 5070.**
- **Timeout 8s do ecossistema < ~12s do LLM** → abortava a chamada do diretor. Conector
  `dap-ai` usa **60s** próprio.

## O que ainda não foi tentado
- **Sessão WhatsApp ao vivo** (Baileys QR) — caminho completo Zap→Bianca. Precisa do telefone do Thales.
- Substrato real (Supabase/RAG/Drive) — ainda fakes. Sophia multi-diretor. 2º diretor. Fase B.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `dap-ai/docs/superpowers/specs/2026-06-21-dap-ai-runtime-design.md` | Completo | spec aprovada |
| `dap-ai/docs/superpowers/plans/2026-06-21-dap-ai-fatia1-engine-bianca.md` | Completo | plano 9 tasks |
| `dap-ai/src/**` (config,dna,tools,engine,sophia,http,index) | Completo | Fatia 1, 23/23 verde |
| `dap-ai/.env` | Completo | key colada + token + PORT=5070 (gitignored) |
| `chapapiuro/src/ecosystem/connectors/dapai.ts` | Completo | conector + bearer, 60s |
| `chapapiuro/src/ecosystem/{http,build}.ts` + `config/env.ts` | Completo | headers no postJson, registro, env |
| `chapapiuro/.env` | Completo | DAPAI_BASE_URL=:5070 + token (gitignored) |

## Decisões tomadas
- **Diretor = unidade central** (C-suite real do ECOSSISTEMA-DAP40), não agentes soltos.
- **Um engine na VPS + WhatsApp 24h**; Desktop opcional. DNA git / estado Supabase (híbrido).
- **Stack:** TS + Claude Agent SDK (padrão Chapapiuro), pnpm via corepack, zod 3.
- **Porta 5070** (5060 é bad-port). **Conector dap-ai com timeout 60s** (latência LLM).
- **Ordem ajustada:** WhatsApp ao vivo fura a fila antes de B/C (valor/feedback real primeiro).

## Bloqueios & perguntas abertas
- WhatsApp depende do QR/telefone do Thales.
- Branch do Chapapiuro (`feat/fase1-nucleo-vivo`) tem remote `origin` — **push pendente de OK**.
- Token de serviço é dev — rotacionar/cofre antes da VPS.

## Próximo passo exato
Subir os dois e conectar o WhatsApp:
```
# terminal 1
cd C:\THALES\DAP4.0\dap-ai  && corepack pnpm dev    # DAP AI em http://localhost:5070
# terminal 2
cd C:\THALES\chapapiuro     && corepack pnpm dev    # escanear o QR do WhatsApp
```
Depois mandar no Zap: "Bianca, qual o gargalo de marketing hoje?" e confirmar a resposta dela.
Se OK, próximo é **B (substrato real do AIOS: RAG HTTP + memória/eventos no Supabase)**.

## Setup / comandos úteis
- **Sempre `corepack pnpm`** (pnpm não está no PATH). `npm` = NÃO.
- Qualidade dap-ai: `corepack pnpm test` · `test:cov` · `typecheck`. Chapapiuro idem.
- DAP_AI_SERVICE_TOKEN (dev) é o mesmo nos dois `.env`. DAP AI no `:5070` (não 5060).
- Handoffs anteriores desta rodada: `2026-06-24-handoff-dap-ai-fatia1.md`, `2026-06-25-handoff-dap-ai-A-D-live.md` (mesma pasta).
