---
type: handoff
date: 2026-06-11
time: 01:21
project: Chapapiuro (agente pessoal WhatsApp)
topic: Fase 1 construída e deployada na VPS; pareamento WhatsApp não concluiu
tags: [handoff, claudin, chapapiuro, whatsapp, vps]
---

# Handoff — Chapapiuro Fase 1: build completo, falta parear o WhatsApp

## Contexto

Chapapiuro é o agente pessoal do Thales no WhatsApp (não as linhas comerciais Ana/Bosch/Prime).
Nesta sessão construímos a **Fase 1 inteira do zero** (brainstorm → spec → plano → implementação
subagent-driven com TDD → deploy), e tentamos **parear o WhatsApp**, sem sucesso.

Arquitetura Fase 1 (só consulta): harness sobre **Claude Agent SDK** (TS) + **Baileys** (WhatsApp
não-oficial) + roteamento de modelo Haiku/Opus + memória de longo prazo (JSON) + web search nativo
do Claude + allowlist de remetentes. Roda em **Docker na VPS Hostinger** (76.13.170.42), isolado.

Repo local: `C:\THALES\chapapiuro` (branch `feat/fase1-nucleo-vivo`, 25 commits, NÃO mergeado).
Deploy VPS: `/opt/chapapiuro-fase1` (container `chapapiuro`, projeto compose `chapapiuro-fase1`).

## O que funcionou (com evidência)

- **Fase 1 completa e testada** — evidência: 22 testes verdes (`pnpm test`), typecheck 0 erros,
  cobertura 89% (linhas). Revisão de spec + qualidade em cada task via subagentes.
- **Build Docker na VPS** — evidência: `docker compose up -d --build` → container `Built` + `Started`.
- **Boot do app na VPS** — evidência: logs `allowlist carregada (count=1)` + `Chapapiuro de pé`.
- **Conexão ao WhatsApp (modo QR)** — evidência: logs `connected to WA` + `WA aguardando pareamento`
  + QR renderizado, SEM 401, container `Up` estável (após o fix do loop).
- **Isolamento do stack antigo** — evidência: stack Evolution em `/opt/chapapiuro` (5 semanas)
  intacto; nosso app em dir/container separados.

## O que NÃO funcionou (e por quê)

- **Pareamento por QR via chat** — falhou porque: o QR expira em ~20s e o ciclo de
  relay (eu leio o QR do log via SSH → colo no chat → Thales escaneia) é mais lento que a janela.
  Várias tentativas, nenhuma pareou.
- **Pareamento por CÓDIGO de 8 dígitos** — falhou porque: BUG MEU. No erro 401 o processo saía,
  e o Docker (`restart: unless-stopped`) reiniciava **instantâneo**, gerando código novo a cada ~2s
  (`49JK`→`ENSM`→`VT5R`→`9BYN`...). Cada código novo matava o anterior, e o bombardeio
  **provavelmente fez o WhatsApp rate-limitar o número** (401 Connection Failure em cascata).
  CORRIGIDO em `d361536` (ver abaixo), mas não retestamos o código após o fix — voltamos pro QR.
- **QR após o fix** — falhou porque: ainda é o problema de latência do relay via chat
  (não é mais loop/401 — o container fica estável). Simplesmente não escaneou a tempo.

## O que ainda não foi tentado

- **Pareamento por CÓDIGO com o fix aplicado.** O bug do loop (causa provável do rate-limit) já
  está corrigido. O código de 8 dígitos vale ~minutos (sem a pressão de 20s do QR) e é trivial de
  relay por texto. **Esta é a aposta mais promissora pra retomar.** Basta re-setar `WA_PAIRING_NUMBER`
  no `.env` da VPS e subir.
- **Esperar o rate-limit esfriar de verdade** antes da próxima tentativa (deixamos o container
  PARADO no fim da sessão justamente pra isso).
- **Confirmar se 5511917001822 é um WhatsApp ativo/livre** num celular em mãos. Esse número estava
  amarrado ao stack Evolution antigo ("Thales Oliveira", status=close) — possível fator no 401.
  Um número secundário 100% livre pode parear mais limpo.
- **Trocar Baileys rc13 por versão estável** se persistir — é release candidate, frágil.

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `C:\THALES\chapapiuro\` (repo inteiro) | Fase 1 Completa | branch `feat/fase1-nucleo-vivo`, 22 testes verdes |
| `src/wa/gateway.ts` | Completo (precisa validar pareamento ao vivo) | Baileys: QR + código de pareamento + backoff anti-martelo |
| `src/brain/agent.ts` | Completo | harness Agent SDK + web search; runner real só validado por types |
| `src/index.ts`, `src/config/env.ts`, `src/memory/store.ts`, `src/brain/router.ts`, `src/wa/normalize.ts`, `src/wa/allowlist.ts` | Completos | testados |
| `Dockerfile`, `docker-compose.yml`, `pnpm-workspace.yaml` | Completos | node:24-slim, sharp build negado, env_file |
| `.env` (local e VPS) | Em progresso | `ANTHROPIC_API_KEY` está **DELETADA** (precisa nova); `OWNER_WA_JID` set; `WA_PAIRING_NUMBER` foi removido na volta pro QR |
| VPS `/opt/chapapiuro-fase1` | Deployado, container PARADO | rodar `docker compose up -d` pra retomar |

## Decisões tomadas

- **Deploy isolado, não substituir o stack Evolution antigo** — razão: tem 5 semanas e Postgres com
  dados; não destruir o que não construímos sem ok explícito.
- **Node 24-slim na imagem** — razão: pnpm 11 usa `node:sqlite`, ausente no Node 20.
- **Negar build do `sharp`** — razão: stub opcional do Baileys que exige Python/node-gyp; não usamos imagem na Fase 1.
- **Web search via ferramenta nativa do Claude** — razão: zero chave/serviço externo.
- **Allowlist formalizada** (dono + `ALLOWED_WA_JIDS`) — razão: hoje só o Thales, expansível por env depois.
- **Pausar com container PARADO** — razão: deixar o rate-limit do WhatsApp esfriar.

## Bloqueios & perguntas abertas

- **Chave Anthropic DELETADA** — sem nova chave em `console.anthropic.com → API Keys`, o WhatsApp
  conecta mas o cérebro não responde. Bloqueio pra ter o agente funcional de ponta a ponta.
- **Número-host 5511917001822 está livre/ativo?** Possível causa-raiz do 401, além do loop.
- **Branch não mergeada** — `feat/fase1-nucleo-vivo` precisa decidir merge/PR depois que parear.

## Próximo passo exato

1. Confirmar com o Thales que **5511917001822** (ou outro número secundário) é um WhatsApp ativo
   num celular em mãos.
2. Na VPS: `ssh root@76.13.170.42` → `cd /opt/chapapiuro-fase1` → adicionar
   `WA_PAIRING_NUMBER=5511917001822` no `.env` (volta pro modo CÓDIGO, que é o caminho não testado
   pós-fix) → `rm -rf data/wa-session` → `docker compose up -d --build`.
3. Esperar ~10s, pegar o código:
   `docker compose logs --no-log-prefix --since 1m | grep PAREAMENTO`.
4. Thales digita o código em: WhatsApp → Aparelhos conectados → Conectar um aparelho →
   "Conectar com número de telefone". O código vale minutos — sem pressa de QR.
5. Confirmar `WA conectado` nos logs. Depois: colocar a **nova chave Anthropic** no `.env`,
   `docker compose restart`, e testar mandando "bom dia" do número primário.

## Setup / comandos úteis

```bash
# SSH VPS
ssh -i ~/.ssh/id_ed25519 root@76.13.170.42

# pnpm local NÃO está no PATH do shell; prefixe:
export PATH="$PATH:/c/Users/docto/AppData/Roaming/npm"

# rodar local (sem pnpm): node carrega .env nativo
node --env-file-if-exists=.env --import tsx src/index.ts

# transferir código pra VPS (sem .env)
cd C:\THALES\chapapiuro
tar czf - --exclude=node_modules --exclude=data --exclude=coverage --exclude=.git --exclude=dist --exclude=.env . \
  | ssh -i ~/.ssh/id_ed25519 root@76.13.170.42 "tar xzf - -C /opt/chapapiuro-fase1"

# logs / QR limpo na VPS
cd /opt/chapapiuro-fase1
docker compose logs --no-log-prefix --tail 70 | grep -E '^[█▄▀ ]+$' | tail -33   # QR
docker compose logs --no-log-prefix --since 1m | grep PAREAMENTO                  # código
```

Memória relacionada: `~/.claude/projects/C--THALES/memory/chapapiuro-personal-agent.md`
(status detalhado) e `thales-prefere-acao.md` (feedback: avaliar/agir, não empurrar pergunta).
