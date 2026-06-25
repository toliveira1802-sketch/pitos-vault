---
type: handoff
date: 2026-06-25
project: DAP AI (motor de diretores)
topic: A (smoke E2E) + D (conector Chapapiuro) validados AO VIVO; 3 bugs reais corrigidos
tags: [handoff, claudin, dap-ai, chapapiuro]
---

# Handoff — DAP AI: A + D ao vivo, conector Chapapiuro provado

## Resumo executivo
Continuação da rodada da Fatia 1. Rodamos **A (smoke E2E da DAP AI)** e **D (conector
Chapapiuro→DAP AI)** em paralelo e **validamos os dois AO VIVO** com Claude real. A Bianca
(CMO) respondeu na voz dela, com o contexto do negócio puxado do DNA (`CONTEXTO.md`). Três
bugs reais — invisíveis nos testes unitários — apareceram só rodando ao vivo e já estão
corrigidos. Falta só a **sessão WhatsApp** (QR do Baileys) pra fechar o caminho completo do Zap.

## O que foi validado ao vivo
- **A:** `POST /api/agent/ask` → Sophia roteia → DNA da Bianca → Claude (Agent SDK) → reply.
  HTTP 200, ~12s. Resposta real e ancorada (R$300k→R$700k, 45% capacidade, lead+conversão).
- **D:** o conector `dap-ai` do Chapapiuro chamou a DAP AI viva e recebeu `{ ok:true,
  target:'dap-ai', text:'…' }`. Elo Chapapiuro↔DAP AI provado (sem a sessão WhatsApp ainda).

## 3 bugs reais corrigidos (só apareceram ao vivo)
1. **Boot quebrava com `.env`** — campos URL opcionais (`SUPABASE_DB_URL`/`RAG_BASE_URL`)
   chegam como `""` do `.env`, e `z.string().url().optional()` rejeita `""` (só aceita
   `undefined`). Fix: normalizar `""`→`undefined` no `parseEnv`. → `dap-ai 85829ca`.
2. **Porta 5060 é "bad port" do padrão Fetch (é SIP)** — `fetch` do Node/browser **recusa**
   conexão nela ("bad port"); só o `curl` funcionava (ignora a blocklist). Qualquer cliente
   real quebraria. **DAP AI movida pra 5070.** → `dap-ai f882f42`.
3. **Timeout do conector 8s < ~12s do LLM** — `ECOSYSTEM_TIMEOUT_MS` (8s) abortava a chamada
   de diretor. Conector `dap-ai` agora usa default próprio de **60s** (latência de LLM). →
   `chapapiuro 54a62c5`.

## Commits
- **dap-ai (`master`):** `85829ca` (empty env), `f882f42` (porta 5070). 23/23 testes verde.
- **chapapiuro (`feat/fase1-nucleo-vivo`):** `6ed9860` (conector dap-ai + headers no postJson),
  `54a62c5` (timeout 60s), merge `fe65710`. 57/57 testes verde. **Branch tem remote `origin` —
  NÃO foi feito push (aguarda OK do Thales).**

## Como rodar / config pra fechar o WhatsApp
1. **DAP AI:** `cd C:\THALES\DAP4.0\dap-ai && corepack pnpm dev` → sobe em **http://localhost:5070**.
   `.env` já tem `ANTHROPIC_API_KEY` (colada pelo Thales) + `DAP_AI_SERVICE_TOKEN` (gerado).
2. **Chapapiuro:** no `.env` dele adicionar:
   - `DAPAI_BASE_URL=http://localhost:5070`
   - `DAPAI_SERVICE_TOKEN=<o mesmo DAP_AI_SERVICE_TOKEN do .env da dap-ai>`
   (o conector só registra se URL **e** token existirem.)
3. Subir o Chapapiuro (`corepack pnpm dev`), escanear o QR do WhatsApp (Baileys), e mandar
   "Bianca, …" no Zap. O Claude do Chapapiuro escolhe o alvo `dap-ai` via `acionar_ecossistema`.

## Próximo passo sugerido (ordem ajustada)
**A → D → [WhatsApp ao vivo] → B → C → E.** O WhatsApp furou a fila: dá valor/feedback real
antes de trocar fakes por substrato. Só depois:
- **B.** Substrato real do AIOS (RAG HTTP + memória/event log no Supabase).
- **C.** Google Drive (artefatos). **E.** 2º diretor + Sophia multi-diretor.

## Riscos / pendências
- **Sessão WhatsApp não conectada** (precisa do QR/telefone do Thales).
- **Push do branch do Chapapiuro** pendente de OK (tem remote).
- DAP AI ainda usa **fakes** pra RAG/data/memória (Fase A) — só o artefato é real (filesystem).
- Token de serviço é dev; rotacionar/cofre quando for pra VPS.
