---
title: Inventário DAP 4.0 — triagem pós 4 resets arquiteturais
date: 2026-04-23
autor: Claudin
escopo: C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\DAP 4.0\
metodo: Glob + ls + head (sem Read em arquivo inteiro)
letras: C=CANON, H=HIST, D=DUP, L=LIXO, ?=olho humano
---

# 01 — Inventário DAP 4.0

Total de itens classificados: 45 arquivos + 9 pastas. Vault é pequeno e bem cuidado — não é um dump. 4 resets deixaram trilha curta porque o Thales já vinha arquivando com `status: superseded` no frontmatter e usando `_archive/`.

**Veredicto geral:**
- Canon vivo: `Frameworks Operacionais/` + `_triagem-2026-04-23/` + `Notas/001`, `002`, `003`, `005`, `014` + `Documentos/rag-seed/` + `Specs/2026-04-18-dap-prime-v1-*`.
- Hist congelado: ciclo WhatsApp-Kommo (006→009), `011` briefing Antigravity, `010` log de sessão, `_archive/013`, Specs Chairman OS (substituído pelo Sennin Protocol em PITOS/Sistemas).
- Dup: `guardrails-ana-v0-rascunho.md` (root) duplica `Frameworks Operacionais/anna-guardrails.md`.
- Lixo: nenhum. Pastas vazias (`Apresentacoes/`, `Rodada 0/`) devem ser **deletadas**.
- ?: `004` copilot elétrico (conceito vivo ou dormente?), `012` divisão de trabalho (operacional datado).

---

## Raiz `DAP 4.0/`

| path | tamanho | letra | descrição |
|---|---|---|---|
| `guardrails-ana-v0-rascunho.md` | 15.9 KB | **D** | Rascunho guardrails Ana, 2026-04-19, `status: rascunho — AGUARDANDO RÍSCOS DO THALES`. Substituído por `Frameworks Operacionais/anna-guardrails.md` (v1.0, 2026-04-19, 31 KB). Arquivar/deletar. |
| `Apresentacoes/` | vazia | **L** | Pasta vazia desde 2026-04-10. Deletar. |
| `Rodada 0/` | vazia | **L** | Pasta vazia desde 2026-04-15. Deletar. |

---

## `_triagem-2026-04-23/` — triagem atual (CANON ativo)

Fonte de verdade do processo de limpeza em curso. Todos CANON até a triagem fechar.

| path | tamanho | letra | descrição |
|---|---|---|---|
| `03-dicionario-canonico.md` | 11.4 KB | **C** | Um nome por coisa: Parliament, Sophia, Anna/Ana, CRM Duplo. Regra oficial do vocabulário DAP 4.0. |
| `04-cemiterio.md` | 12.3 KB | **C** | Lista formal do que morreu em cada reset (Exército IA, Athena, Sophia Hub Vercel, main.py LangGraph). Fonte histórica canônica. |
| `05-mapa-fontes-verdade.md` | 8.1 KB | **C** | Mapa de onde ler / onde NÃO confiar. Este inventário (01) é o complemento físico dele. |
| `06-aproveitaveis-sophia-hub.md` | 27.2 KB | **C** | Peças reutilizáveis do Sophia Hub morto (snippets + veredicto). Triagem técnica. |
| `07-plano-arquivamento-manus.md` | 9.4 KB | **C** | Plano de mover auditorias Manus 2026-03-18 para Business Intelligence. Operação pendente. |
| `13-migration-notas.md` | 8.3 KB | **C** | Decisões de design da migration dos 4 crons (Vigilante/Analista/Reativador/Relatório). |
| `13-migration-supabase.sql` | 17.1 KB | **C** | SQL canônico das 4 tabelas dos crons. Pendente de `apply_migration`. |
| `14-caddy-host-dir.md` | 9.9 KB | **C** | Análise da pendência Caddyfile host=dir pós-cutover 23/04. |
| `15-rag-ops-ingestao.md` | 15.3 KB | **C** | Plano de desbloqueio do RAG `ops_*` vazio em prod. |

---

## `Notas/` — doc-vivo + histórico datado

Numeração 001–014. Modelo misto: notas estratégicas vivas + planos táticos com `status: superseded` explícito. Bem organizado.

| path | tamanho | letra | descrição |
|---|---|---|---|
| `Notas/001-dap40-master-todo.md` | 12.2 KB | **C** | Master TODO, `#ativo #referencia`. Doc vivo canônico. |
| `Notas/002-dap40-rota-estrategica.md` | 9.6 KB | **C** | Rota R$300k→R$700k, `#ativo`. Canon. |
| `Notas/003-dap40-dores-e-legado.md` | 10.8 KB | **C** | Dores + estrutura interna + legado, `#ativo`. Canon. |
| `Notas/004-dap-copilot-diagnostico-eletrico.md` | 2.9 KB | **?** | `#conceito #prioridade-alta` mas sem update desde 2026-04-10. Olho humano: reativar ou mover pra cemitério. |
| `Notas/005-dap-calendario-anual-mkt.md` | 4.4 KB | **C** | Calendário marketing, `#ativo`. Canon. |
| `Notas/006-dap-whatsapp-golive-playbook.md` | 5.6 KB | **H** | `status: superseded` por 008. Hist. |
| `Notas/007-dap-whatsapp-golive-plan.md` | 25.2 KB | **H** | `status: superseded` por 009. Hist. |
| `Notas/008-dap-whatsapp-kommo-playbook.md` | 4.0 KB | **C** | `status: ready-to-execute`. Caminho atual (Kommo). Canon. |
| `Notas/009-dap-campanha-claude-desktop-v0-roadmap.md` | 9.1 KB | **C** | Roadmap campanha lead-gen premium. Vivo. |
| `Notas/009-dap-whatsapp-kommo-plan.md` | 30.0 KB | **C** | Plano WhatsApp×Kommo `ready-to-execute`. Canon. |
| `Notas/010-dap-sessao-2026-04-13-whatsapp-kommo.md` | 4.6 KB | **H** | `status: shipped`. Log de sessão congelado. |
| `Notas/011-dap-antigravity-briefing.md` | 9.4 KB | **H** | `status: ready-to-send` (2026-04-13). Handoff de janela, datado. Hist. |
| `Notas/012-dap-divisao-trabalho-proximos-passos.md` | 4.3 KB | **?** | `status: active` mas é divisão de janelas (Claude aqui × Antigravity lá) de 2026-04-13. Provavelmente histórico mas rotulado active. |
| `Notas/014-dap40-roadmap-30d-sistema-pessoal.md` | 13.9 KB | **C** | Roadmap 30d `status: draft`, janela 2026-04-15 → 2026-05-15 (ativa hoje 2026-04-23). Canon. |
| `Notas/_archive/013-dap40-benchmark-lancamentos.md` | 23.8 KB | **H** | `type: research`, já no `_archive/`. Hist correto. |

Nota: falta `013` na sequência viva (foi arquivado). Numeração coerente.

---

## `Frameworks Operacionais/` — fonte de verdade dos frameworks (CANON)

Pasta nova (2026-04-23) consolidando os frameworks vigentes.

| path | tamanho | letra | descrição |
|---|---|---|---|
| `Frameworks Operacionais/anna-guardrails.md` | 31.3 KB | **C** | v1.0 Anna guardrails, 2026-04-19 `status: draft`. Canon (substitui rascunho na raiz). |
| `Frameworks Operacionais/crm-duplo-v1.md` | 13.4 KB | **C** | CRM Duplo v1 `status: vigente`, 2026-04-23. Recém-oficializado. Canon. |
| `Frameworks Operacionais/framework-leads-novos.md` | 4.4 KB | **C** | Framework lead scoring `status: vigente`, 2026-04. Canon. |
| `Frameworks Operacionais/DAP_Framework_Leads_Novos.pdf` | 40.0 KB | **C** | PDF fonte do framework acima. Manter junto. |

---

## `Specs/` — design + implementation plans

Formato consistente (design spec + companion plan). Tudo datado.

| path | tamanho | letra | descrição |
|---|---|---|---|
| `Specs/2026-04-14-chairman-os-design.md` | 12.6 KB | **H** | Design Chairman OS Fase 0, `status: design-approved` 2026-04-14. Substituído pelo Sennin Protocol (PITOS/Sistemas). Hist. |
| `Specs/2026-04-14-chairman-os-fase0.1-plan.md` | 27.8 KB | **H** | Plan companion do acima. Hist (já executado: `/manha`, `/noite` existem como skills). |
| `Specs/2026-04-18-dap-prime-v1-design.md` | 14.2 KB | **C** | Design DAP Prime V1 `status: draft — aguardando aprovação`. Base do trabalho atual. Canon. |
| `Specs/2026-04-18-dap-prime-v1-plan.md` | 67.1 KB | **C** | Plan companion DAP Prime V1. Canon (guia Parliament 13 diretores em execução). |

---

## `Documentos/rag-seed/` — seed knowledge base 4 marcas (CANON)

5 arquivos por marca × 4 marcas (BMW, Audi, Mercedes, VW) = 20 arquivos .md de ~2-3 KB cada. Todos datados 2026-04-14, prontos pra ingestão (ver triagem 15).

| path | tamanho | letra | descrição |
|---|---|---|---|
| `Documentos/rag-seed/README.md` | 4.7 KB | **C** | Index RAG Seed 2026-04-14, `tags: [rag-seed, ingestion-ready]`. Canon. |
| `Documentos/rag-seed/bmw/` | 5 arquivos, ~11 KB | **C** | 01-revisao-por-km, 02-problemas-comuns, 03-ecu-tcu-remap, 04-pecas, 05-faq-cliente. Seed BMW. |
| `Documentos/rag-seed/audi/` | 5 arquivos, ~12 KB | **C** | Mesmo template 01-05 para Audi. |
| `Documentos/rag-seed/mercedes/` | 5 arquivos, ~12 KB | **C** | Mesmo template 01-05 para Mercedes. |
| `Documentos/rag-seed/vw/` | 5 arquivos, ~12 KB | **C** | Mesmo template 01-05 para VW. |

Classificação em bloco: 20 arquivos filhos — todos CANON, ingestion-ready, bloqueados pelo desbloqueio RAG ops descrito em `15-rag-ops-ingestao.md`.

---

## `pacotes-externos/`

| path | tamanho | letra | descrição |
|---|---|---|---|
| `pacotes-externos/agente-orquestrador-v0.md` | 13.4 KB | **H** | Referência externa 2026-04-19, `status: referência — extrair ideias, não adotar literal`. Origem Downloads. Hist (extraiu o que servia — Parliament + Sophia já abraçaram). |

---

## Resumo por classificação

| letra | qtd | ação sugerida |
|---|---|---|
| **C** CANON | 38 (inclui 20 filhos rag-seed) | Manter, são fonte viva. |
| **H** HIST | 7 | Mover pra `_archive/` ou subpasta `historico/`. Já têm `status: superseded` ou `shipped`. |
| **D** DUP | 1 | `guardrails-ana-v0-rascunho.md` na raiz → deletar (substituído em Frameworks Operacionais). |
| **L** LIXO | 2 pastas | `Apresentacoes/` e `Rodada 0/` vazias há semanas. Deletar. |
| **?** olho humano | 2 | `Notas/004` (copilot elétrico — conceito vivo?) e `Notas/012` (divisão de trabalho datada). |

---

## Observações estruturais

1. **Vault já é disciplinado.** Frontmatter `status: superseded`/`supersedes`/`shipped`/`ready-to-execute`/`vigente` funciona como telemetria — o Thales não precisa adivinhar. Manter essa convenção.
2. **`_archive/` em Notas existe e é usado** (só tem 013 hoje). Mover os 7 HIST pra lá fecha o ciclo.
3. **Numeração 001–014 está quase contígua** (falta 013, arquivado). Próxima nota deve ser 015.
4. **Separação Notas vs Specs vs Frameworks é clara:**
   - Notas = docs vivos + logs de sessão + playbooks táticos.
   - Specs = design + implementation plans datados.
   - Frameworks Operacionais = fonte de verdade dos frameworks vigentes (nova, 2026-04-23).
5. **Sem lixo de verdade.** Zero arquivos órfãos de nomes como `untitled.md`, `cópia de X`, `teste.md`. Thales não gera entropia — ele congela trilhas com frontmatter. Continue assim.

---

## Ações recomendadas (sequência mínima)

1. Deletar `guardrails-ana-v0-rascunho.md` (raiz) — duplicata.
2. Deletar pastas vazias `Apresentacoes/` e `Rodada 0/`.
3. Mover pra `Notas/_archive/`:
   - `006-dap-whatsapp-golive-playbook.md`
   - `007-dap-whatsapp-golive-plan.md`
   - `010-dap-sessao-2026-04-13-whatsapp-kommo.md`
   - `011-dap-antigravity-briefing.md`
4. Criar `Specs/_archive/` e mover:
   - `2026-04-14-chairman-os-design.md`
   - `2026-04-14-chairman-os-fase0.1-plan.md`
5. Decisão humana em `Notas/004` e `Notas/012` — promover pra CANON ou arquivar.
6. Ler `pacotes-externos/agente-orquestrador-v0.md` uma última vez para extrair aprendizado residual, depois mover pra `_archive/` também.

Fim do inventário. Próximo passo do pipeline triagem: aplicar ações 1–6 acima ou partir pra doc `02`.
