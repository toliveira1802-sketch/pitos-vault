---
type: handoff
date: 2026-06-20
time: 10:04
project: DAP 4.0 (consolidação Supabase / verificação)
topic: Verificar estado vivo do AIOS pós-cutover (001→014) via Supabase MCP
tags: [handoff, claudin]
---

# Handoff — Verificação do AIOS pós-consolidação (retomada)

## Contexto
Sessão de retomada que descobriu que o handoff anterior (`2026-06-18-0246-consolidacao-aios.md`)
estava **STALE**. O "próximo passo" daquele handoff (criar branch, aplicar `001→012`, smoke) **já
foi feito e superado** — uma sessão rodou das ~03:00 às ~11:09 de 06-18 e nunca gerou handoff.

**Estado real (lido dos `.sql` e runbooks):** a consolidação dos 4 Supabase no AIOS
(`hlhfqnhsvwxodtwdkkhf` = System of Record) **já está APLICADA EM PRODUÇÃO** desde 2026-06-18:
sequência `002→001→010→011→012`, depois `013` e `014`. Fonte de verdade do estado:
`C:\THALES\DAP4.0\docs\migrations\CUTOVER-runbook.md` e `RUN-branch-test.md` (NÃO o handoff de 02:46).

## O que funcionou (com evidência)
- Reconstrução do estado real via timestamps de `docs/migrations/` + headers "APLICADA EM PROD" nos `.sql`.
- Servidor Supabase MCP alcançável (HTTP 401 = up). `.mcp.json` criado no root do projeto
  (`C:\THALES\DAP4.0\.mcp.json`), escopado `project_ref=hlhfqnhsvwxodtwdkkhf` + `read_only=true`.
- Skills `supabase` + `supabase-postgres-best-practices` instaladas em `.agents/skills/`.
- 2 memórias persistidas: `dap-consolidacao-aios-aplicada`, `dap-aios-env-db-password-stale`.

## O que NÃO funcionou (e por quê)
- **Smoke read-only via Node** (driver `postgres` do projeto): **senha rejeitada**
  (`password authentication failed for user "postgres"`). A `DATABASE_URL` do `dap-aios/.env`
  está bem-formada mas a senha está velha (provavelmente rotacionada). → usar MCP, não o .env.
- **Supabase MCP ainda não no ar** nesta sessão: precisa OAuth + reload. Por isso o reopen.

## Próximo passo exato
1. Confirmar que o Supabase MCP carregou (tools `mcp__supabase__*` disponíveis) — autorizar OAuth se pedir.
2. Rodar **smoke estrutural read-only** contra o AIOS (`hlhfqnhsvwxodtwdkkhf`) via `execute_sql`:
   - schemas existentes (esperado: `conhecimento` presente, `aquisicao` AUSENTE/dropado, +`autodiag·catalogo·posvenda·conversas`);
   - `conhecimento.knowledge_chunks` tem coluna `domain` + índices **HNSW** (embedding) e **GIN** (content_tsv);
   - função `conhecimento.search_knowledge` existe e `autodiag.search_knowledge` NÃO existe;
   - `public.leads` tem colunas novas do 013 (document/channel/anna_status/legacy_kommo_lead_id/vehicle_info/metadata) + `public.lead_interacoes` existe;
   - `conversas.conversations`/`messages` NÃO existem (dropados no 013);
   - counts do core intactos (customers≈418, vehicles≈546, service_orders≈659, events≈1616).
3. **Escrever handoff completo** do estado real (o cutover 03:00–11:09 de 06-18 nunca foi handoffado).
4. Só então decidir: Fase 4 (repontar PRIME→AIOS via .env da VPS) · confirmar modelo de embedding (1024) · popular corpus `conhecimento`.

## Bloqueios & pendências
- MCP em `read_only=true`: pra qualquer escrita (popular corpus, Fase 4) trocar pra `read_only=false` no `.mcp.json` COM GO do Thales.
- Senha do `dap-aios/.env` velha → app local não conecta; resolver quando for mexer em dev local.
- 2 ações do Thales (do handoff anterior, ainda abertas): rotacionar chaves expostas em `autodiag-copilot/.env.local`; backup + deletar projeto TOOLS no painel.

## Setup / comandos úteis
- AIOS `hlhfqnhsvwxodtwdkkhf` (fica) · PRIME `acuufrgoyjwzlyhopaus` · TOOLS `mtrmtkvhgrzhwhhfffhj` · DAP4.0 `cpzgtfblywexqglqkgbt`.
- Estado real da consolidação: `C:\THALES\DAP4.0\docs\migrations\` (CUTOVER-runbook.md, RUN-branch-test.md, 013/014).
- `.mcp.json` no root → reload da sessão carrega o servidor `supabase`.
