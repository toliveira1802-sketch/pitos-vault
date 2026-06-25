---
title: DAP 4.0 — CANON
date: 2026-06-04
version: 1.1
status: vigente
scope: fonte única de verdade operacional do DAP 4.0
owner: Thales Oliveira
---

# DAP 4.0 — CANON

> **Regra de ouro:** conflito entre qualquer documento, código, memória IA, ou doutrina com este arquivo → **este vence**. Atualização: renomeação ou mudança estrutural. Versão bump quando entidade viva nasce, renomeia ou morre.

Este arquivo é o único apontador inicial necessário pra entender o estado oficial do DAP 4.0. Todos os detalhes moram em documentos específicos, linkados abaixo.

---

## 1. Stack oficial (2026-04-23)

| Camada          | Tecnologia                                                             | Onde mora                                            |
| --------------- | ---------------------------------------------------------------------- | ---------------------------------------------------- |
| Infra           | VPS Hostinger `76.13.170.42`                                           | `/opt/doctor-auto-ai/`                               |
| TLS + proxy     | Caddy (HTTP only) atrás de Cloudflare Tunnel `dap4`                    | `Caddyfile` VPS, tunnel gerenciado via CF Zero Trust |
| Dashboard       | React 18 + Vite 6 + TypeScript                                         | `C:/dev/dap4/dashboard/`                             |
| Gateway         | Express 5 + TypeScript                                                 | `C:/dev/dap4/gateway/`                               |
| Agents          | FastAPI + Python 3.12                                                  | `C:/dev/dap4/agents/`                                |
| RAG             | ChromaDB (8 collections — `study_*` populadas, `ops_*` vazias em prod) | container na VPS                                     |
| DB              | Supabase (27 tabelas, 5911 leads)                                      | SaaS                                                 |
| CRM externo     | Kommo — Bosch pipeline `12704980`, Prime pendente                      | SaaS                                                 |
| Orquestração IA | **Parliament** (13 diretores C-Level Sennin v1)                        | `agents/parliament/`                                 |
| WhatsApp Anna   | Phase 1a — código ativo, toggle operacional **paused**                 | `agents/anna/`                                       |
| Cockpit UI      | `/sophia` (cockpit live do 0613-B)                                     | `dashboard/src/pages/SophiaHub.jsx`                  |
| Domínio         | `dap.doctorautoprime40.com` (público desde 19/04)                      | CF DNS                                               |

Domínios futuros (multi-tenant): subdomínio por tenant via `sites/*.caddy` (ver `_triagem-2026-04-23/14-caddy-host-dir.md`).

---

## Arquitetura de domínios (2026-06-04)

`doctorautoprime40.com` = **site institucional**. Cada subdomínio encaminha pra
um portal/unidade. Portais operacionais = mesmo app `dap-aios` (1 banco, 1 login,
event log central); subdomínio só fixa o portal. Detalhe e tabela completa em
[[00-MAPA-ECOSSISTEMA]].

Decisões travadas:
- Dashboard `dap4` sai da raiz → `ai.doctorautoprime40.com`.
- `aios.doctorautoprime40.com` mantém como hub de orquestração (Sophia).
- Subdomínio por portal **não** cria app/login separado (opção A).
- Institucional (raiz) e sites das unidades de negócio = futuro, specs próprios.

> Supersede a nota antiga "Domínios futuros (multi-tenant): subdomínio por tenant".

---

## 2. Dicionário canônico

Nomes oficiais, sinônimos banidos, escopo. **Um nome, uma coisa.**

→ **`_triagem-2026-04-23/03-dicionario-canonico.md`**

Resumo das 5 decisões desta versão (23/04):

- **Sophia** = diretora CEO Parliament + cockpit `/sophia`. `Sophia Hub Vercel` **não existe** (morreu).
- **Anna** ≠ **Ana**: Anna (2 letras) é CSO estratégica Parliament; Ana é bot Python tático WhatsApp. Mantido.
- **IA Mãe / Athena** — **banido**. Usar `Sophia` (presidência Parliament).
- **Parliament** é THE sistema de orquestração. `Exército de IAs` banido. `Sala do Conselho Dify` **morto** (doc movido pra `_archive/`).
- **CRM** sozinho é banido. Use `Kommo` (SaaS externo) ou `Supabase + crm_leads` (banco interno).

---

## 3. Cemitério

Projetos e conceitos mortos, com causa, data, substituto.

→ **`_triagem-2026-04-23/04-cemiterio.md`**

Decisões de enterro desta versão (23/04):

| Item | Status 23/04 | Ação executada |
|---|---|---|
| Exército de IAs | MORTO | artefatos em `Downloads/Evaluate These Documents/` arquivados em `Business Intelligence/Manus-Audits-2026-03-18/` |
| Athena IA Mãe | MORTO | BLUEPRINT_IA_MAE.md arquivado |
| Sophia Hub Vercel | MORTO | ana.js, zip, relatórios arquivados |
| Sala do Conselho Dify | MORTO | `PITOS/Sistemas/sala-do-conselho-dify-dap4.md` → `_archive/2026-04-23/` |
| Thales Agent | APOSENTADO | `C:/dev/thales-agent/` → `C:/dev/_archive/2026-04-23/` |
| Davi Gatuno | APOSENTADO | substituído por backfill-kommo + Anna inbox worker |
| `dashboard-git/` (detrito monorepo) | ARQUIVADO | `C:/dev/dap4/dashboard-git/` → `C:/dev/dap4/_archive/2026-04-23/` |
| chromadb:latest | TAG MORTA | **pendência:** pinar semver na VPS (ação humana) |

---

## 4. Mapa de fontes de verdade

Onde ler cada tipo de informação, onde NÃO confiar.

→ **`_triagem-2026-04-23/05-mapa-fontes-verdade.md`**

Resumo crítico:

- **Código de produção** → `C:/dev/dap4/` (git). Nada de "código canônico" em Downloads ou vault.
- **Doutrina/SOPs/frameworks** → `PITOS/DAP 4.0/Frameworks Operacionais/` e `PITOS/Sistemas/`.
- **Leads/operação** → Supabase (ledger). Kommo é UI.
- **Tasks/prazos** → ClickUp ("coworkin") via MCP.
- **Memória IA** → `~/.claude/projects/.../memory/` (auto-memória persistente).
- **Secrets** → VPS `.env` + `~/.ssh/`. **Vault é público via GitHub — zero secret.**
- **Métricas financeiras** → Supabase `os_*` + dashboards Sophia Hub.

---

## 5. Roadmap consolidado (1 página)

Substitui `001-master-todo`, `002-rota-estrategica`, `003-dores-e-legado` como **página de topo**. Os três continuam vivos como CANON detalhado — o CANON só sumariza.

### Meta
R$300k → **R$700k/mês**. 9 elevadores 45% ocupação → 100%. 50 OS/mês → 150+.

### Gargalos declarados
1. **Falta de lead qualificado** (topo do funil)
2. **Tempo de permanência do carro** (operação)
3. **Conversão de orçamento** (fechamento)

### Agora (em prod, 23/04/2026)
- Parliament 13 diretores rodando em `DOCTOR_PRIME`
- Dashboard público em `dap.doctorautoprime40.com`
- Anna Phase 1a **paused** (toggle, não código morto)
- Sophia cockpit ao vivo em `/sophia`

### Próximo (2 sprints, pendente de aprovação)
1. **Apply migration SQL** dos 4 crons → `_triagem-2026-04-23/13-migration-supabase.sql` (7 tabelas: campaigns, lago_leads, ana_conversas, logs_crons, qualificacoes_lead, agendamentos_tasks, briefing_executivo)
2. **Cron Vigilante** (5min, leads sem resposta) → spec em `09-spec-cron-vigilante.md`
3. **Cron Analista** (10min, qualificação em lote) → spec pendente de salvar
4. **Cron Reativador** (08h diário, ataque ao lago) → spec pendente de salvar
5. **Cron Relatório Executivo** (19h + 06h) → spec pendente de salvar
6. **Ingestão RAG `ops_*`** → plano em `15-rag-ops-ingestao.md`
7. **Caddy multi-host** via `sites/*.caddy` → plano em `14-caddy-host-dir.md`

### Médio prazo (≤90d)
- Ativar Anna Phase 1a (destravar toggle) após Sprint 1
- Implementar CRM Duplo v1 (lago_leads + Bote Pescadora) → framework em `Frameworks Operacionais/crm-duplo-v1.md`
- Confirmar pipeline Kommo Prime + onboarding multi-tenant via `config/tenants/dap.yaml`

### Não fazer (proibido pelo CANON)
- Reimplementar Sophia Hub em Vercel/serverless
- Criar agentes fora do Parliament
- Hardcodar IDs Kommo em código (usa `tenants/dap.yaml`)
- Seed RAG com valores monetários (contraria `anna-guardrails.md`)
- Editar `dashboard-git/` (arquivado)
- Usar `chromadb:latest` em compose

---

## 6. Pendências explícitas (humano)

Ações que este CANON **não executa** e precisam de mão humana:

- [ ] Pinar `chromadb:<semver>` no compose da VPS (descobrir versão rodando primeiro)
- [ ] Decidir destino de `Notas/004-dap-copilot-diagnostico-eletrico.md` (promover ou arquivar)
- [ ] Decidir destino de `Notas/012-dap-divisao-trabalho-proximos-passos.md` (promover ou arquivar)
- [ ] Confirmar pipeline Kommo Prime (bloqueador dos 4 crons em tenant Prime)
- [ ] Salvar specs 10/11/12 dos crons no vault (conteúdo existe, só não foi persistido)
- [ ] Aprovar e executar `13-migration-supabase.sql`
- [ ] Revisar 5 branches locais não mergeadas em `C:/dev/dap4/` (inventário 02)
- [ ] Destravar Anna Phase 1a após Sprint 1 validado

---

## 7. Estrutura do vault (pós-faxina 23/04)

```
PITOS/DAP 4.0/
├── 000-CANON.md                    ← este arquivo
├── _triagem-2026-04-23/            ← processo limpeza 23/04
├── _archive/2026-04-23/            ← detrito da faxina 23/04
├── Frameworks Operacionais/        ← frameworks vigentes (CANON)
│   ├── anna-guardrails.md
│   ├── crm-duplo-v1.md
│   └── framework-leads-novos.md
├── Notas/                          ← docs vivos numerados 001-014
│   └── _archive/                   ← notas superseded/shipped
├── Specs/                          ← design + implementation plans
│   └── _archive/                   ← specs superseded
├── Documentos/rag-seed/            ← 20 notas BMW/Audi/Mercedes/VW
└── pacotes-externos/               ← referências externas
```

---

## 8. Versionamento deste CANON

- **v1.0 (2026-04-23)** — primeira versão. Opção B da triagem pós 4 resets.
- Bump (v1.1) quando: nova entidade canônica, renomeação, nova morte, nova pendência crítica.
- Bump major (v2.0) quando: mudança de stack principal ou reset arquitetural.

Fim.
