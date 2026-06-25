---
type: handoff
date: 2026-06-12
time: 23:07
project: DAP 4.0 (dap4 + dap-aios)
topic: Sync de doc da VPS commitado + discussão de arquitetura sobre integrar dap4 e dap-aios
tags: [handoff, claudin, arquitetura, vps, integracao]
---

# Handoff — Integração dap4 ↔ dap-aios + fechamento do sync de doc da VPS

## Contexto

Sessão continuou a rodada de hardening da VPS (auditoria + unificação de composes + observabilidade, tudo concluído em 11/06). Nesta sessão fechamos o **item 2 da fila** — sincronizar a doc do repo `dap4` com a realidade da VPS pós-hardening — e commitamos. No fim, o Thales levantou a questão arquitetural de fundo: **`dap4` e `dap-aios` deveriam trabalhar juntos**, e hoje não trabalham. Esse é o tema que abre a próxima rodada.

O hub `C:\THALES\DAP4.0` agrupa dois repos distintos:
- **`dap-aios/`** — plataforma operacional (portais Consultor/Gestão/Mecânico, CRM, OS, quotes, clientes, veículos). Banco Supabase **hlhf**. É a fonte de verdade documentada (event log obrigatório). Serve os 5 portais públicos via container `aios-staging`.
- **`dap4/`** — sistema multi-agente RAG (Anna vendas/WhatsApp, Kimi, 0613-B, Thales, Insights) + ChromaDB. Banco Supabase **acuufr**. É o backend de IA/RAG + webhook Meta WhatsApp. NÃO serve os portais.

## O que funcionou (com evidência)

- **Sync de doc do repo dap4 commitado** — evidência: commit `bb9fbd8` no master local, 2 arquivos (`CLAUDE.md` + `infra/README.md`), `git diff --stat` = 40 inserções / 12 deleções. Só doc; nenhuma mudança de código tocada.
  - `CLAUDE.md`: nova seção "Production (VPS)" separando local de prod — fonte de verdade `docker-compose.unified.yml`, sem container dashboard/cloudflared (cloudflared é systemd), portais servidos por `aios-staging`, chromadb 0.6.3 em 127.0.0.1, observabilidade em /opt/monitoring.
  - `infra/README.md`: aviso de topologia atual no topo; `deploy.sh` e `Caddyfile` flagados como stale ("do not run as-is"); nota "monitoring NOT here" corrigida (existe desde 11/06).
- **Memória atualizada** — `vps-cloudflare-audit.md` marca o drift repo↔VPS como RESOLVIDO (commit bb9fbd8); `MEMORY.md` reflete hardening concluído.
- **Vault localizado** — confirmado nesta linha de sessões que o vault PITOS migrou de OneDrive pra `C:\THALES\PITOS\` (memória `vault-pitos-moved.md`). Handoffs DAP em `03 - PROJETOS/DAP 4.0/Status/`; handoffs gerais em `Inbox - Claudin/`.

## O que NÃO funcionou (e por quê)

- **Push do master dap4** — NÃO feito de propósito: master local divergiu do origin (7 commits à frente / 2 atrás) e push pra branch principal exige ok explícito do Thales (regra do hub). Precisa pull/rebase antes pra resolver a divergência.

## Discussão de arquitetura — MINHA OPINIÃO (núcleo da próxima rodada)

**Pergunta do Thales:** "o correto era os 2 trabalharem juntos... qual sua opinião?"

**Resposta curta:** Sim, devem trabalhar juntos — mas **NÃO fundindo os repos**. O modelo certo é **unificar os DADOS e o EVENT LOG, mantendo os dois codebases separados**.

**Diagnóstico do problema real (split-brain):**
- A própria arquitetura documentada do AIOS diz: *"Banco AIOS é fonte de verdade. Kommo, WhatsApp, Instagram são canais/integrações, não verdade. Event log é obrigatório."* E: *"Frontend → Backend → Tool/Integration → Event log."*
- Sob essa visão, **os agentes do dap4 são `tools`/integrações do AIOS**. A Anna, quando capta/qualifica um lead pelo WhatsApp, deveria escrever no banco AIOS (hlhf), gerar evento `lead_created`, e o portal Consultor enxergar na hora.
- Hoje NÃO é assim: o dap4 vive no banco **acuufr** e o AIOS no **hlhf**. Um lead que a Anna capta nasce num banco; o Consultor lê outro. São **duas fontes de verdade pra a mesma entidade** (customers/leads/conversations). Isso é o split-brain.
- A memória `dap-aios-owns-aios-schema` já registra a direção certa: "DDL do hlhf só pelo Drizzle do dap-aios; dap4 só consome". E já existe trilha de "Anna shadow" + "gateway shadow proxy" — ou seja, já estavam costurando a Anna do dap4 no fluxo do AIOS em modo shadow.

**Recomendação (fronteira de integração):**
1. **AIOS = system of record.** Um banco (hlhf), um event log. Tudo que é verdade de negócio (cliente, veículo, lead, conversa, quote, OS) vive lá. Invariante cliente-veículo (R16.5) já blinda isso.
2. **dap4 = camada de cognição.** Os agentes (Anna et al.) e o RAG/ChromaDB ficam no dap4 — esse é o domínio legítimo dele. ChromaDB NÃO precisa ir pro AIOS.
3. **Conexão via API + event log, nunca DB compartilhado nem merge de repo.** A Anna lê/escreve estado de cliente/lead **através da API do AIOS** (que valida, aplica RLS, emite evento). dap4 deixa de ser dono de estado de negócio.
4. **Promover o "shadow" pra canônico:** o que a Anna toca passa a persistir no banco AIOS. Mata a duplicação acuufr↔hlhf pra entidades de negócio.

**Por que não fundir os repos:** stacks incompatíveis (pnpm/Drizzle/Postgres-TS vs FastAPI/Python/Chroma); fundir vira monolito e perde a separação limpa. **Por que não deixar 100% separado (hoje):** split-brain de dados, dois Supabase pra mesma entidade, reconciliação eterna. **O meio é o certo:** repos separados, dados unificados.

> ⚠️ Isto é uma OPINIÃO/recomendação discutida, NÃO uma decisão aprovada nem implementada. Próxima rodada deve começar validando essa direção com o Thales antes de qualquer código.

## O que ainda não foi tentado

- Mapear concretamente QUAIS entidades o dap4 (Anna) escreve hoje em acuufr que já existem como tabela-núcleo no AIOS (hlhf) — o inventário do split-brain.
- Revisar o estado real da spec "Anna shadow" / "gateway shadow proxy" (branches `feat/ai-sprint4b-anna-shadow-ui` no aios e `feat/ai-sprint4b-gateway-shadow-proxy` no dap4) pra ver quanto da costura já existe.
- Desenhar o contrato de API AIOS que o dap4 consumiria (endpoints de lead/conversa/cliente + emissão de evento).

## Arquivos tocados

| Arquivo | Status | Notas |
|---------|--------|-------|
| `dap4/CLAUDE.md` | Completo | Seção Production (VPS) reescrita; commit bb9fbd8 |
| `dap4/infra/README.md` | Completo | Topologia atual + flags de stale; commit bb9fbd8 |
| `~/.claude/.../memory/vps-cloudflare-audit.md` | Completo | Drift marcado resolvido |
| `~/.claude/.../memory/MEMORY.md` | Completo | Linha do audit atualizada + vault-pitos-moved adicionado |
| `~/.claude/.../memory/vault-pitos-moved.md` | Completo | Novo — registra mudança do vault pra C:\THALES\PITOS |
| `C:\THALES\PITOS\...\Status\2026-06-11-handoff-vps-cloudflare-hardening.md` | Completo | Handoff da auditoria arquivado |

## Decisões tomadas

- **Sync de doc commitado mas NÃO pushado** — razão: push pra master precisa de ok do Thales + resolver divergência com origin.
- **Não tocar nas mudanças não commitadas do dap4** — razão: working tree tem um refactor grande de outra frente (sophia/0613b nos agents, rotas antigravity) que não é desta sessão; ficou intacto.
- **Gravar handoff no vault novo** (`C:\THALES\PITOS\Inbox - Claudin\`) e não no path OneDrive do comando — razão: confirmado nesta sessão que o OneDrive está morto (pasta CHAIRMAN vazia); vault vivo é C:\THALES\PITOS.

## Bloqueios & perguntas abertas

- **Direção de integração dap4↔aios precisa de aprovação do Thales** antes de virar plano de implementação.
- **Push do master dap4** pendente de ok + rebase (7 à frente / 2 atrás do origin).
- **Decisão chapapiuro-*** — 4 containers do stack Evolution antigo ainda rodam na VPS sem subdomínio; manter ou parar?
- **Token CF novo (escrita)** necessário pra expor Grafana em metrics.* + confirmar revogação do `cfut_…` antigo.
- **Working tree do dap4 sujo** — refactor de outra frente não commitado; decidir o que fazer com ele.

## Próximo passo exato

Validar com o Thales a recomendação de arquitetura: **manter repos separados, unificar dados+event log, dap4 escreve no banco AIOS via API (não via DB próprio acuufr)**. Se aprovado: começar pelo INVENTÁRIO do split-brain — listar quais entidades a Anna (dap4) grava hoje em `acuufr` que colidem com tabelas-núcleo do AIOS em `hlhf` (customers, leads, conversations, messages). Esse mapa é o input do plano de migração. Antes de mexer, ler o estado das branches shadow (`feat/ai-sprint4b-anna-shadow-ui` em dap-aios, `feat/ai-sprint4b-gateway-shadow-proxy` em dap4).

## Setup / comandos úteis

```powershell
# Push do master dap4 (quando aprovado) — resolver divergência primeiro
git -C C:\THALES\DAP4.0\dap4 pull --rebase origin master   # cuidado: working tree sujo
git -C C:\THALES\DAP4.0\dap4 push origin master

# Grafana via túnel SSH (sem exposição pública)
ssh -i ~/.ssh/id_ed25519 -L 3000:localhost:3000 root@76.13.170.42
# http://localhost:3000 · user admin · senha em /opt/monitoring/.env
```
