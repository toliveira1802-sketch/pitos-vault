---
type: handoff
date: 2026-05-25
time: 02:30
project: dap-aios
topic: Split CLAUDE.md + ARCHITECTURE.md, verificação R13/VPS/Supabase, recomendação de hospedagem
tags: [handoff, claudin, dap-aios, arquitetura, r13, vps, supabase, cloudflare, vercel]
---

# Handoff — DAP AIOS: split docs, audit infra, recomendação de hospedagem

## Contexto

Sessão começou com pedido de parecer do estado do `dap-aios` (branch `feat/marketing-scaffold`). A partir daí evoluiu pra:

1. **Reescrita do CLAUDE.md** — Thales decidiu split em 2 arquivos: `CLAUDE.md` enxuto (operacional do dia-a-dia) + `ARCHITECTURE.md` (visão aspiracional consultada sob demanda).
2. **Verificação do R13** (migração SQLite→Postgres pausada) — alguns números da memória estavam desatualizados.
3. **Audit completo da infra existente** — VPS Hostinger, Cloudflare Tunnel, projetos Supabase.
4. **Recomendação de hospedagem** pra dev e prod do AIOS — onde rodar o que.

Resultado central: o caminho de hospedagem world-class é **Vercel (front) + VPS Hostinger container (back) + Supabase DAP AIOS sa-east-1 (db) + Cloudflare Tunnel existente**. Pra destravar isso, R13 precisa ser puxado (hoje tá pausado aguardando driver de negócio, mas o Supabase já tá pago e provisionado ocioso).

## O que funcionou (com evidência)

- **Split CLAUDE.md → CLAUDE.md (259 linhas) + ARCHITECTURE.md (815 linhas)** — commit `2df7e24` no `feat/marketing-scaffold`. Pre-commit (Husky + lint-staged + gitleaks + prettier) passou. CLAUDE.md preserva literal as invariantes R16.5/R11.1 e tem tabela honesta de estado atual dos portais (Consultor maduro, Gestão construindo, Cliente zerado).
- **SSH na VPS Hostinger** (`76.13.170.42`, srv1303948) funcionou — uptime 19 dias, load 1.35, 9% disco. 8 containers up:
  - DAP4 P1: `dap4-gateway` (:3001) + `dap4-agents` (:8000) + `dap4-chromadb` (:8000) + `dap4-caddy` (:80/:443) — todos healthy 8 dias
  - Chapapiuro: `chapapiuro-server` (:3000) + `chapapiuro-evolution` (:8080, Evolution API WhatsApp) + `chapapiuro-postgres` (:5432) + `chapapiuro-redis` (:6379) — todos 2 sem
- **Cloudflare Tunnel `DAP4`** ativo via systemd desde 2026-05-06 (ID `df082b0d-aa0b-4dd8-8274-c5f2ed61e561`). Hoje só roteia `chapapiuro.doctorautoprime40.com` → `chapapiuro-server:3000`. Histórico: dashboard legacy aposentado 2026-04-24, portal-familia arquivado 2026-05-16.
- **MCP Supabase** listou 4 projetos: DAP TOOLS (us-east-2, 2025-11-05), DOCTOR PRIME (us-west-2, 2026-01-13), DAP4.0 (us-east-1, 2026-04-14, 25 tabelas com Parliament/Sennin já populado), **DAP AIOS (sa-east-1 São Paulo, 2026-05-17, 0 tabelas)**.

## O que NÃO funcionou (e por quê)

- **Memória `project-r13-paused` (6 dias atrás) estava parcialmente errada:**
  - Claim: branch `feat/r13-c1-postgres-dev` existe local+remote — **falso**: não existe (nem local nem remote). Só `feat/r13-sidebar-consultor` (R13 antiga renumerada antes da reorg).
  - Claim: 82 ocorrências de `sqliteTable`/`integer({mode:})` em 7 schemas — **incorreto**: hoje são **27 ocorrências em 8 arquivos** (`core, consultor, service-orders, service-order-items, calculators, agents, events, rag`).
  - Claim: Supabase DEV decidido mas sem provision — **incorreto**: o projeto DAP AIOS JÁ existe em sa-east-1 (Postgres 17), provisionado em 2026-05-17 (1 dia antes do R13 ser pausado). `.env` local já tem URL + anon + service_role keys apontando pra ele. Banco zerado, esperando migration baseline.
- **Não consegui ler o `config.yml` do Cloudflare Tunnel** — tunnel é token-based (configurado via dashboard), sem config local. Deduzi ingress pelo Caddyfile.

## O que ainda não foi tentado

- Atualizar a memória `project_r13_paused.md` com os números corretos (27 ocorrências, projeto Supabase já provisionado, branch antiga não existe). Thales pediu pra fazer, faltou executar antes do handoff.
- Decidir destino dos 3 untracked: `docs/architecture/consultor-comercial/` (4 PNGs de mockup), `docs/contexto/portal_dap_plan (1).md`, `docs/marketing-dashboard/` (parece um projeto inteiro com client/server/shared/drizzle — possível template de referência).
- Push da branch `feat/marketing-scaffold` (tá 1 commit à frente da origin, regra de autonomia não permite push sem aprovação explícita).
- Rotacionar service_role keys do Supabase DAP AIOS que apareceram em pipe durante a inspeção do `.env` (gitignored, não vazaram em git, mas histórico de terminal local existe).
- Desenhar a rodada R13 com checklist atualizado (Thales perguntou se queria fazer isso, sessão encerrou antes).

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `CLAUDE.md` | Completo (commitado `2df7e24`) | 1154 → 259 linhas. Operacional enxuto. |
| `ARCHITECTURE.md` | Completo (commitado `2df7e24`) | Novo, 815 linhas. Visão completa: portais, calculadoras, tools, agentes, histórico R2→R35.5. |
| `docs/architecture/consultor-comercial/` | Não tocado (untracked) | 4 PNGs: chat_v1_desktop, crm-duplo-interno, home-v2, pipeline. Aguardando decisão. |
| `docs/contexto/portal_dap_plan (1).md` | Não tocado (untracked) | Aguardando decisão. |
| `docs/marketing-dashboard/` | Não tocado (untracked) | Projeto inteiro (client/server/shared/drizzle). Parece template/referência. |
| `~/.claude/projects/.../memory/project_r13_paused.md` | Desatualizado | Pendente atualização. |

## Decisões tomadas

- **Split CLAUDE.md** (sobre atualizar incremental ou reescrever do zero) — razão: o doc atual misturava arquitetura aspiracional (Sophia, agentes com LLM, tools reais, Facilities) com realidade do código. Split separa o que Claude precisa toda sessão (CLAUDE.md) do que consulta sob demanda (ARCHITECTURE.md). Resultado: CLAUDE.md 23% do tamanho original, ARCHITECTURE.md preserva 100% da visão.
- **Remover Facilities dos portais** — razão: Thales já tinha removido manualmente em edit anterior do CLAUDE.md, ARCHITECTURE.md reflete a nova realidade (5 portais: Consultor, Mecânico, Cliente, Gestão, AIOS).
- **Recomendar Vercel (não Cloudflare Pages) pro frontend** — razão: DevEx superior pra React/Vite, Speed Insights nativo, integração com Vercel AI SDK que vai virar útil quando agentes virarem real. Cloudflare Pages é tecnicamente bom mas inferior em DevEx pra esse stack.
- **Recomendar VPS Hostinger (não Render/Railway/Fly) pro backend** — razão: infra já paga, montada, com Docker+Caddy+Tunnel funcionando. Custo marginal zero. Backend Express persistente não casa com Vercel Functions (cold start, timeouts).
- **Recomendar Supabase DAP AIOS sa-east-1 (não Turso/Neon)** — razão: já provisionado, latência SP, Auth nativa resolve stub `requireAuth`, RLS resolve `requirePermission`, Storage pra evidências, Realtime pra Inbox. Turso seria mais barato mas perde Auth/Storage/Realtime = reinventa 3 camadas.

## Bloqueios & perguntas abertas

- **Decisão R13:** puxar agora pra destravar staging cloud com banco real, ou segurar até driver de negócio aparecer? Meu voto: puxar agora (Supabase pago ocioso + Vercel staging sem banco real é inútil + Auth real destrava Portal Cliente). Thales não respondeu antes do pedido de handoff.
- **3 untracked em docs/** — o que fazer com cada um? Especialmente `docs/marketing-dashboard/` que parece projeto inteiro dropado lá.
- **Push da branch `feat/marketing-scaffold`** — ok pra subir o commit do split?
- **Caddy só expõe chapapiuro hoje** — containers `dap4-*` (gateway, agents, chromadb) tão rodando mas não acessíveis externamente. É intencional (uso interno) ou tem rota a recriar?
- **Multi-domínio por portal** (`consultor.aios.doctorautoprime40.com`, `gestao.aios.*`, etc) — vale planejar agora ou depois?

## Próximo passo exato

**Atualizar a memória `~/.claude/projects/C--THALES-DAP4-0-dap-aios/memory/project_r13_paused.md`** com os 3 correções confirmadas nesta sessão:

1. Branch `feat/r13-c1-postgres-dev` NÃO existe (memória dizia que sim). Só `feat/r13-sidebar-consultor` (R13 antiga, não a do Postgres).
2. Refator dos schemas: **27 ocorrências em 8 arquivos** (memória dizia 82 em 7).
3. **Supabase DAP AIOS já provisionado** em sa-east-1 (`hlhfqnhsvwxodtwdkkhf`), Postgres 17, 0 tabelas, esperando migration baseline. `.env` local na raiz do `dap-aios` já tem URL + anon + service_role apontando pra ele. Repo correto: `toliveira1802-sketch/dap40-perple-claude` (privado).

Depois disso, decidir com Thales se puxa R13 ou segue construindo Marketing.

## Setup / comandos úteis

```bash
# Verificar R13 schemas (do diretório dap-aios)
cd C:/THALES/DAP4.0/dap-aios
grep -rn "sqliteTable\|integer({ ?mode" packages/types/src/schema/ | wc -l

# SSH VPS pra inspecionar containers
ssh root@76.13.170.42 "docker ps; systemctl status cloudflared"

# Listar projetos Supabase via MCP (no Claude Code)
mcp__claude_ai_Supabase__list_projects

# Branch atual
git status  # feat/marketing-scaffold, 1 commit à frente
```

**Vault path (este arquivo):** `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Inbox - Claudin\handoff-2026-05-25-0230-dap-aios-claude-split-hospedagem.md`

**Projetos Supabase relevantes:**
- DAP AIOS (destino R13): `hlhfqnhsvwxodtwdkkhf` (sa-east-1)
- DAP4.0 (P1 legacy produção): `cpzgtfblywexqglqkgbt` (us-east-1, 25 tabelas)
