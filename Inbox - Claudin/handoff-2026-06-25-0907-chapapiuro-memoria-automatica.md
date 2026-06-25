---
type: handoff
date: 2026-06-25
time: 09:07
project: Chapapiuro (agente pessoal WhatsApp)
topic: Agente posto no ar 24/7 + memória automática (capturar/lembrar/auditar) + backup do vault
tags: [handoff, claudin]
---

# Handoff — Chapapiuro: deploy 24/7 + memória automática

## Contexto

Chapapiuro é o agente pessoal do Thales no WhatsApp (número secundário **5511917001822**;
dono que fala com ele = **5511967291822**). Stack: Claude Agent SDK + Baileys (socket WhatsApp
direto), TypeScript/Node 24, roda em Docker na VPS `76.13.170.42` em `/opt/chapapiuro-wa`
(container `chapapiuro`, `restart: unless-stopped`). Repo: `toliveira1802-sketch/chapapiuro`.

A sessão começou com "fazer o agente pessoal funcionar" (estava quebrado), terminou com ele
**no ar 24/7** e com a **memória automática** (Fase A) implementada, deployada e provada E2E.
Código mergeado em `master` (`87dd026`). 100 testes verdes, typecheck 0.

## O que funcionou (com evidência)

- **Fix do loop 401** (`planReconnect`, commit `3b6b892`) — 401 loggedOut agora é sempre
  terminal (idle), não martela mais o WhatsApp a cada 60s. Evidência: 6 testes unitários + o
  agente conecta estável (`WA conectado` nos logs sem loop).
- **Resolução `@lid`→número** (commit `bb62aa0`) — o WhatsApp entrega remetente como `@lid`
  (privacidade); o gateway resolve via `sock.signalRepository.lidMapping.getPNForLID()` + tira
  sufixo de device. Evidência: mensagem do dono passa na allowlist e o Claude responde (E2E).
- **Deploy 24/7 na VPS** — Baileys substituiu o stack Evolution antigo (cutover). Evidência:
  `WA conectado`, container `Up`, responde com o PC do Thales desligado.
- **Memória automática (Fase A)** — após responder, extrai fatos duráveis (Haiku) → grava em
  `memory.json` → lembra via recall → espelha em `Chapapiuro.md`. Tools de chat
  `listar_fatos`/`esquecer_fato`. Evidência E2E real: Thales mandou msg, o agente capturou
  sozinho **"o Thales prefere treinar de manhã"**, escreveu o espelho, o cron empurrou pro
  GitHub (commit `memoria 09:10`).
- **Espelho → Obsidian** — `chapapiuro-memoria` (repo privado) entrou como **submódulo** no
  vault via plugin `agentic-git-sync`. Evidência: `C:\THALES\PITOS\chapapiuro-memoria\Chapapiuro.md`
  populou com o fato aprendido.
- **Backup inicial do vault** → repo privado `pitos-vault` (519 arquivos pushados via `gh` token,
  contornando o ENAMETOOLONG do plugin). Evidência: `gh api repos/.../pitos-vault/contents`
  lista todas as pastas.

## O que NÃO funcionou (e por quê)

- **Plugin `agentic-git-sync` no backup do vault inteiro** — falhou com `spawn ENAMETOOLONG`.
  Motivo: o plugin passa a lista de TODOS os ~519–796 caminhos de arquivo como argumentos pro
  `git`, estourando o limite de linha de comando do Windows (~32KB). Contornei o **inicial** com
  `git add -A` (não lista arquivos). Os incrementais do plugin (poucos arquivos) devem passar.
- **Token do GitHub App sem acesso ao `pitos-vault`** — push do plugin/token deu
  `Repository not found` (App escopado a repos selecionados; o repo novo não entrou). Por isso
  empurrei o inicial com a credencial `gh`. **Pendência:** liberar o App pro `pitos-vault`.
- **Sessão WA antiga estava morta** (401, `registered:false`) — re-pareada via QR; sessão
  copiada do local pra VPS (resumiu sem reparear, device 15).
- **`/root/thales-vault` da VPS é cópia velha/abandonada** (último commit 2026-04-14) — NÃO é o
  vault vivo (`C:\THALES\PITOS`). Não usar como ponte.

## O que ainda não foi tentado

- **Áudio (Whisper)** — Thales manda áudio, transcreve e responde. (Fase própria.)
- **RAG do vault** — o agente LER as notas do Obsidian pra responder (ChromaDB/embeddings). (Fase B.)
- **Proativo / lembretes** — o agente iniciar conversa, agendar, cutucar. (Fase C.)
- **Conector DAP-AI vivo na VPS** — hoje off (URL `localhost` não resolve no container; precisa
  expor o motor numa URL alcançável pela rede Docker).
- **Submódulo aninhado** — `chapapiuro-memoria` caiu na raiz do vault; mover o "path" do plugin
  pra `Agentes/Chapapiuro` se quiser aninhado (cosmético).
- **`.git` aninhado em `PITOCOLOCO/LIXO/Chair/`** — virou gitlink no backup (conteúdo não
  capturado); limpar depois se importar (é LIXO).

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `src/wa/reconnect.ts` | Completo | `planReconnect` puro (fix 401), testado |
| `src/wa/jid.ts` | Completo | `isLid`/`stripDevice` (resolução @lid), testado |
| `src/wa/gateway.ts` | Completo | usa planReconnect + resolveSenderJid |
| `src/memory/store.ts` | Completo | +`list()`/`forget()` com rollback; invariante documentada |
| `src/brain/extractor.ts` | Completo | `extractFacts` (Haiku), tolerante |
| `src/memory/vault-mirror.ts` | Completo | `writeMirror` idempotente (sem timestamp) |
| `src/brain/tools/memory.ts` | Completo | tools `listar_fatos`/`esquecer_fato` |
| `src/brain/agent.ts` | Completo | `Brain.capture` pós-turno + tools no runner |
| `src/index.ts` | Completo | dispara `capture` fire-and-forget pós-send |
| `src/config/env.ts` | Completo | +`VAULT_MIRROR_PATH` |
| `docker-compose.yml` | Completo | volume `/opt/chapapiuro-memoria:/vault` + env |
| `docs/superpowers/specs/2026-06-25-chapapiuro-memoria-automatica-design.md` | Completo | spec aprovado |
| `docs/superpowers/plans/2026-06-25-chapapiuro-memoria-automatica.md` | Completo | plano 6 tasks TDD |

## Decisões tomadas

- **Baileys substitui Evolution** — os dois usavam o mesmo número (1 socket por device, brigavam).
  Baileys é o futuro (testado, Agent SDK, ops simples); Evolution era protótipo. Histórico Postgres
  descartado (escolha do Thales). Containers Evolution parados.
- **Storage da memória = `memory.json`** (não Supabase) — corpus pessoal pequeno, KISS; interface
  limpa pra trocar depois. (Nota: contraria a regra geral "banco = Supabase sempre", mas é memória
  pessoal, não dado de negócio DAP.)
- **Espelho sem timestamp** (desvio consciente do spec §4.4) — o timestamp gerava commit a cada
  turno; git history do repo já cobre "quando". Removido → byte-idempotente → cron só commita em
  mudança real.
- **Captura silenciosa + espelho só-leitura** — fato vale na hora; correção por chat ("esquece que X").
- **Ponte Obsidian via repo dedicado + submódulo** — vault principal vai pro `pitos-vault`;
  `chapapiuro-memoria` é submódulo. Vault inteiro no GitHub (privado) foi escolha do Thales.
- **Deploy key SSH** (read-write) pro `chapapiuro-memoria` na VPS — em vez de PAT amplo.

## Bloqueios & perguntas abertas

- **Liberar o GitHub App pro `pitos-vault`** (pendência ativa do Thales) — senão os syncs
  incrementais do plugin continuam dando `Repository not found`. GitHub → Settings → Applications
  → Installed GitHub Apps → (app do agentic-git-sync) → Configure → Repository access → add
  `pitos-vault` (ou "All repositories").
- O plugin `agentic-git-sync` é frágil com vault grande (ENAMETOOLONG no full-sync). Incrementais
  devem passar, mas se um sync grande reaparecer, o limite volta. Avaliar se vale manter o plugin
  pro vault todo ou só pro submódulo da memória.
- Token de GitHub App apareceu no remote durante o debug (expira ~1h, baixo risco) — regenerar
  se quiser zerar.

## Próximo passo exato

**Thales:** liberar o acesso do GitHub App ao `pitos-vault` (caminho acima) e confirmar que o
plugin parou de dar erro de sync. Depois disso, o backup do vault fica automático.

**Próxima sessão de dev (quando o Thales escolher):** atacar UMA das fases seguintes do Chapapiuro,
cada uma com brainstorm→spec→plano→TDD próprios: **áudio (Whisper)**, **conector DAP-AI vivo na VPS**,
ou **proativo/lembretes**. Recomendação anterior: áudio (muda o uso diário) ou DAP-AI (destrava o
acionamento do ecossistema).

## Setup / comandos úteis

- Logs ao vivo do agente: `ssh root@76.13.170.42 'cd /opt/chapapiuro-wa && docker compose logs -f'`
- Ver memória crua: `ssh root@76.13.170.42 'cat /opt/chapapiuro-wa/data/wa-session/...'` (sessão) /
  `cat /opt/chapapiuro-memoria/Chapapiuro.md` (espelho)
- Testes locais: `corepack pnpm exec vitest run` (pnpm NÃO está no PATH — usar `corepack pnpm`)
- Repos: `chapapiuro` (código, master=`87dd026`), `chapapiuro-memoria` (espelho/submódulo),
  `pitos-vault` (backup do vault). Deploy key na VPS: `~/.ssh/chapapiuro-memoria_deploy`.
- Cron do espelho na VPS: `/root/chapapiuro-memoria-sync.sh` (5min).
