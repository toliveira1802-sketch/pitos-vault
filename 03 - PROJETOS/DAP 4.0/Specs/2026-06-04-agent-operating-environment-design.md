---
title: Agent Operating Environment — DAP 4.0
date: 2026-06-04
version: 1.0
status: spec (aguardando review do Thales)
scope: elevar o ecossistema DAP 4.0 a world-class e dar o ambiente perfeito pros agentes operarem
owner: Thales Oliveira
relacionado: "[[000-CANON]] · [[00-MAPA-ECOSSISTEMA]]"
---

# Agent Operating Environment — DAP 4.0

## 1. Problema / contexto

O ecossistema DAP 4.0 hoje é forte mas desorganizado pra escala:

- Os portais operacionais vivem **todos num app só** (`dap-aios`) em
  `aios.doctorautoprime40.com`, separados por hash routing (`/#/consultor`).
- O **domínio raiz** (`doctorautoprime40.com`) aponta pro dashboard de IA (`dap4`),
  em vez de ser a vitrine institucional da marca.
- O **conhecimento** está fragmentado (duplicata de sync no Obsidian, canon
  desatualizado, descritivos de unidade inexistentes).
- A **engenharia** depende de rodar checks na mão — não há CI/CD que barre
  merge vermelho; o deploy do staging é manual.
- Os **agentes** operam sem papel cravado, sem portão de qualidade obrigatório,
  sem orquestração paralela formal.

Resultado: dá pra construir rápido, mas não dá pra construir rápido **com
qualidade garantida e em paralelo** — que é o que o crescimento do ecossistema
(12 unidades, múltiplos portais) exige.

## 2. Objetivo

Pegar o **projeto existente** e elevá-lo a **world-class**, montando o
**Agent Operating Environment**: o ambiente onde agentes (Claude Code,
subagentes, e os agentes IA do DAP) operam com papel claro, ferramenta certa,
portão de qualidade automático e memória — rápido, em paralelo, sem passar lixo.

Não é um projeto novo. É a fundação que unifica tudo: o mapa de domínios, a
árvore do Obsidian, os portais e a engenharia passam a viver dentro dela.

## 3. Arquitetura de domínios (aprovada)

`doctorautoprime40.com` vira **site institucional**; cada subdomínio encaminha
pra um portal/unidade. Mesmo app `dap-aios` (1 banco, 1 login, event log central)
servido por subdomínios que "fixam" qual portal abre — **opção A** (não são apps
separados).

```
🌐 doctorautoprime40.com ─────────── SITE INSTITUCIONAL            [FUTURO]
   (vitrine da marca, todas as unidades)

── PORTAIS OPERACIONAIS (app dap-aios, 1 banco, 1 login) ──
   consultor.doctorautoprime40.com → Portal Consultor             [AGORA ✅]
   gestao.doctorautoprime40.com    → Portal Gestão                [AGORA 🔧]
   mecanico.doctorautoprime40.com  → Portal Mecânico              [AGORA 🟡]
   cliente.doctorautoprime40.com   → Portal Cliente               [FUTURO]

── PLATAFORMA / IA ──
   aios.doctorautoprime40.com      → AIOS (orquestração / Sophia) [mantém]
   ai.doctorautoprime40.com        → Dashboard dap4 (RAG/agentes) [migra da raiz]

── UNIDADES DE NEGÓCIO (pasta+descritivo agora, site depois) ──   [FUTURO]
   performance.*  → DAP Performance (remap ECU)
   ensina.*       → DAP Ensina (Hotmart)
   consultoria.*  → DAP Consultoria (compra/venda)
   project.* · studio.* · social.* · mulher.* · estetica.* · funilaria.*
```

**Decisões travadas:**
- Dashboard `dap4` **sai da raiz** → `ai.doctorautoprime40.com`.
- `aios.*` **continua** como hub de orquestração, separado dos portais operacionais.
- Subdomínio só fixa o portal; **não** cria app/login separado.

## 4. As 3 camadas do Agent Operating Environment

```
C · CONHECIMENTO  — o que os agentes LEEM pra entender (por quê)
A · ENGENHARIA    — o terreno onde os agentes PISAM (prova de qualidade)
B · AGENTES       — as mãos que operam (papel, portão, paralelismo, memória)
```

Lógica: **C** diz o que construir e por quê; **A** garante que tudo é sólido;
**B** é a máquina que faz o trabalho em paralelo com controle. C/B são do hub
inteiro; A entra **uma codebase por vez — dap-aios primeiro**, dap4 depois.

### Camada C · Conhecimento (vault Obsidian PITOS)

1. **Consolidar a duplicata de sync** `DAP 4.0/` + `DAP 4.0 1/` → pasta canônica
   única `DAP 4.0/`. Migrar `DOCTOR AUTO PRIME/PORTAL GESTAO` pra estrutura nova.
   *Apagar a pasta órfã só com confirmação do Thales.*
2. **Árvore-mestra** no vault:
   ```
   03 - PROJETOS/DAP 4.0/
   ├── 000-CANON.md                 ← fonte de verdade (atualizar c/ domínios)
   ├── 00-MAPA-ECOSSISTEMA.md       ← NOVO · mapa de domínios + árvore + status
   ├── _triagem-2026-04-23/         ← dicionário canônico + cemitério (mantém)
   ├── Ecossistema/                 ← NOVO · 1 pasta por unidade (12)
   ├── Portais/                     ← NOVO · Consultor/Gestao/Mecanico/Cliente
   ├── Infra/                       ← NOVO · domínios, DNS, Caddy, tunnel, deploy
   ├── Specs/                       ← mantém (este doc)
   └── Status/                      ← mantém (status vivos por frente)
   ```
3. **Atualizar `000-CANON.md`** com a seção de arquitetura de domínios.
4. **Template de descritivo por unidade**: `o que é · status · subdomínio ·
   oferta · mercado interno/externo · RAG/conteúdo · próximos passos`. Toda
   unidade (agora ou futura) descrita no mesmo padrão.

Divisão de trabalho: `Ecossistema/` = frente **paralela** (pastas agora,
descritivos depois); `Portais/` = frente de **produção** (engenharia + roteamento).

### Camada A · Engenharia (dap-aios primeiro)

O dap-aios já exige `pnpm check · build · test · lint (0-warn) · test:e2e:smoke`
+ Husky/lint-staged/gitleaks. O trabalho é **auditar, fechar gaps, automatizar**:

1. **Travar a linha de base verde** — rodar todos os checks e confirmar que
   passam hoje. Vermelho = primeira correção.
2. **Coverage gate 80%** — `vitest coverage.thresholds` (lines/functions/branches);
   build falha abaixo.
3. **CI/CD verde-antes-de-merge** *(maior gap)* — GitHub Actions em cada PR:
   `install → typecheck → lint → test+coverage → build → e2e smoke`. Branch
   protection no `main`: não mergeia vermelho.
4. **Harness de deploy reproduzível** — transformar o deploy manual do staging
   em script/runbook versionado em `Infra/`: `build → tag → subir VPS → restart
   → healthcheck`. Idempotente e auditável.
5. **Guardrails de estrutura** — check de arquivo >800 linhas / função >50 no CI
   (warning).

Sequência: dap-aios recebe as 5; **dap4 entra depois** com a mesma auditoria
(dashboard/vitest + gateway/tsc + agents/pytest).

### Camada B · Agentes

1. **Roster com roteamento por codebase** — `typescript-reviewer` +
   `security-reviewer` no dap-aios; `python-reviewer` nos agents do dap4;
   `code-reviewer` geral; `planner`/`architect` antes de feature grande. Mapa
   cravado no CLAUDE.md.
2. **Quality gate obrigatório antes de commit** — Camada A verde **+**
   `code-reviewer` **+** `security-reviewer` quando toca auth/dados/deploy.
3. **Hooks Claude Code → tooling local** — `PostToolUse` (Write/Edit) →
   `pnpm prettier/eslint/tsc`; `Stop` → build verification.
4. **Orquestração paralela das frentes** — `Ecossistema/` paralelo (1 agente por
   unidade); `Portais/` sequencial com gate por PR.
5. **Skill `/nova-unidade`** — scaffold de pasta + descritivo no template da
   Camada C, com status e subdomínio.
6. **Operações seguras + handoff** — MCP (Supabase, ClickUp) wirado;
   SSH/deploy/destrutivo **sempre com confirmação**; handoff `handoff-<projeto>-rXX`
   como memória entre rodadas.

## 5. Escopo

**Dentro:**
- Camadas C e B no hub inteiro (`C:\THALES\DAP4.0`).
- Camada A no `dap-aios` (engenharia completa + CI/CD + deploy harness).
- Mapa de domínios formalizado; roteamento por subdomínio dos portais operacionais.

**Fora (futuro, próprios specs):**
- Construção do **site institucional** (raiz) — produto à parte.
- Camada A no `dap4` (segunda rodada).
- Sites públicos das unidades de negócio (só pasta+descritivo agora).
- Roteamento de subdomínio das unidades futuras (só no mapa).

## 6. Frentes de execução (paralelizáveis após a fundação)

| Frente | Tipo | Conteúdo |
|---|---|---|
| **Fundação** | serial, primeiro | Camada C (estrutura+canon) + Camada A baseline + Camada B roster/hooks |
| **Ecossistema** | paralelo | Descritivos das 12 unidades (1 agente por unidade) |
| **Portais (produção)** | serial c/ gate | Roteamento por subdomínio + engenharia dap-aios |

## 7. Riscos / pontos abertos

- **Auth cross-subdomínio**: o dap-aios não usa cookies (regra do projeto). Cada
  colaborador usa 1 portal → login por subdomínio é aceitável, mas validar o
  comportamento do token Supabase ao trocar de origem. *(resolver no spec de Portais)*
- **Migração do dap4 da raiz pra `ai.*`**: a raiz hoje responde 200; mover sem
  derrubar produção exige janela e teste. *(resolver no spec de Infra/deploy)*
- **Consolidação da duplicata Obsidian**: risco de perder conteúdo no merge das
  duas pastas — fazer com diff e confirmação, nunca apagar às cegas.
- **CI/CD secrets**: pipeline precisa de credenciais (Supabase, deploy) em GitHub
  Secrets — provisionar com cuidado, nunca hardcode.

## 8. Critério de sucesso

- Um agente novo consegue ler o canon + mapa e entender o ecossistema sem perguntar.
- Nenhum PR mergeia no dap-aios sem lint/types/test/coverage/build/e2e verdes.
- Colaboradores acessam seu portal por subdomínio dedicado.
- Criar uma unidade nova = 1 comando, sempre no padrão.
- Deploy do dap-aios = 1 runbook reproduzível, não passos manuais.
