# Mapa de Fontes de Verdade — DAP 4.0

**Data:** 2026-04-23
**Escopo:** onde ler, onde NÃO confiar, como sincronizar. Uma fonte canônica por tipo de informação. Tudo que contradizer a fonte canônica é cache velho até prova em contrário.

---

## Regra de ouro

> **1 tipo de info = 1 fonte canônica = 1 apontador.**
> Todas as outras cópias são derivadas, espelhadas ou arquivadas. Se duas fontes divergem, a canônica vence — a outra é reescrita ou deletada.

---

## 1. Código de produção

| | |
|---|---|
| **Canônica** | `C:\dev\dap4\` (monorepo) + VPS `/opt/doctor-auto-ai/` (deploy) |
| **Não confiar em** | `Downloads/Evaluate These Documents/*.tsx` (dump do Sophia Hub, snapshot descartável), snippets em notas PITOS, qualquer `.md` com bloco de código |
| **Sincronização** | git push → VPS pull → docker compose up. Nunca editar arquivo diretamente na VPS. Se editou na VPS, commit ou reverte antes do próximo deploy. |

Sub-módulos canônicos: `dashboard/` (React+Vite), `gateway/` (Express TS), `agents/` (FastAPI Python), `supabase/` (migrations), `skills/` (prompts dos diretores), `ops/` (infra scripts).

---

## 2. Specs, doutrina, SOPs

| | |
|---|---|
| **Canônica** | `PITOS/Sistemas/` (sennin-protocol.md, sala-do-conselho-dify-dap4.md, sennin-c-level-map.md, skills-inventory.md) + `PITOS/DAP 4.0/Specs/` (dap-prime-v1-design/plan, chairman-os-design) |
| **Não confiar em** | memos antigos em `Notas/` sem número prefixado, qualquer doc em `_archive/`, relatórios soltos do Manus em Downloads (são análise, não doutrina), `C:\dev\dap4\docs\` quando contradizer Sistemas/ |
| **Sincronização** | Obsidian vault → cron `vault-sync.sh` 5min → `/root/thales-vault/` → GitHub. Spec nova = cria em `Specs/` com data no nome, referencia em `Sistemas/` se virar doutrina. |

---

## 3. Decisões estratégicas (rota, metas, personas)

| | |
|---|---|
| **Canônica** | `PITOS/DAP 4.0/Notas/001-dap40-master-todo.md` (doc vivo) + `002-rota-estrategica.md` + `003-dores-e-legado.md` + `PITOS/DAP 4.0/Frameworks Operacionais/` (lead scoring oficial) |
| **Não confiar em** | apresentações PPT (são derivados de pitch), relatórios Manus (input, não decisão), CLAUDE.md (resumo estático, defasa), memória IA (reflexo, não fonte) |
| **Sincronização** | Decisão nova = edita 001-master-todo primeiro, espelha em memória IA via `/learn` ou note file. PPT regenera a partir das notas — nunca o contrário. |

---

## 4. Dados de leads/operação

| | |
|---|---|
| **Canônica** | **Supabase** (estado persistente, 27 tabelas, RLS) para leads/OS/tags; **Kommo CRM** (pipeline ID Bosch=12704980, Prime pendente) para conversas e estágio comercial |
| **Não confiar em** | Excels em Downloads (REATIVACAO_*.xlsx são fotografias do Manus, não estado atual), ChromaDB (`ops_*` vazio em prod — gargalo conhecido), dumps locais, screenshots |
| **Sincronização** | Kommo webhook → gateway queue → Supabase (RTBM multi-tenant). Supabase é o ledger; Kommo é a UI comercial. Conflito = Supabase vence, resync via MCP. |

---

## 5. Tasks e prazos

| | |
|---|---|
| **Canônica** | **ClickUp "coworkin"** (via MCP) para tarefas executáveis com prazo; `Notas/001-master-todo.md` para backlog estratégico não-datado |
| **Não confiar em** | TODO em código (`// TODO:`), bullets soltos em threads Claudin, tasks verbais sem ticket, emails |
| **Sincronização** | Thales cria no ClickUp direto; IA cria via MCP `clickup_create_task`. Task estratégica vira ticket ClickUp quando ganha prazo. Inverso não automático. |

---

## 6. Memória conversacional (IA)

| | |
|---|---|
| **Canônica** | `C:\Users\docto\.claude\projects\C--Users-docto\memory\MEMORY.md` + arquivos `project_*.md` / `feedback_*.md` / `reference_*.md` |
| **Não confiar em** | contexto de sessão único (efêmero), `CLAUDE.md` do projeto (é instrução, não fato), handoffs antigos em `Inbox - Claudin/` sem `resume-handoff` recente |
| **Sincronização** | `/learn` após sessão relevante, `/handoff` ao fechar, `/resume-handoff` ao abrir. Fato novo que contradiz memória = cria `feedback_*.md` OU edita o `project_*.md` correspondente. Nunca deixa os dois coexistirem. |

---

## 7. Credenciais/secrets

| | |
|---|---|
| **Canônica** | `C:\dev\dap4\.env` (local dev, **nunca commitado**) + VPS `/opt/doctor-auto-ai/.env` (prod) + `~/.ssh/id_ed25519` (SSH key VPS) |
| **Não confiar em** | qualquer `.env.example`, notas do vault (mesmo privado — vault sincroniza com GitHub), screenshots, histórico do shell, MEMORY.md |
| **Sincronização** | Secret novo = prod primeiro (VPS `.env` + `docker compose up -d --force-recreate --no-deps`), depois dev local. Rotação obrigatória se vazou em qualquer log, git, ou contexto IA. |

> **Nota:** vault PITOS espelha para GitHub via `vault-sync.sh`. Tratar vault como **público por default** para fins de secrets.

---

## 8. Métricas financeiras

| | |
|---|---|
| **Canônica** | Supabase (OS faturadas, ticket médio, conversão) + Kommo (pipeline value) — cruzamento via Sophia Hub `/sophia` |
| **Não confiar em** | relatórios Manus (recorte histórico), FinancialBreakdown.tsx isolado (componente UI, precisa dado vivo), planilhas manuais, R$300k/700k em docs (meta narrativa, não medição) |
| **Sincronização** | Métrica financeira nova = query Supabase primeiro, valida no Kommo se é pipeline, documenta em `Business Intelligence/` se vira relatório recorrente. Nunca copiar número de PPT. |

---

## Riscos de desalinhamento atual (2026-04-23)

1. **ChromaDB `ops_*` vazio em prod** — RAG operacional prometido em Sistemas/ mas não existe dado. Doutrina diz "use RAG", código não tem o que consultar. **Ação:** ingestão ou remover a promessa do design.
2. **Kommo Prime pipeline ID pendente** — só Bosch=12704980 confirmado; doc fala em "2 pipelines" mas apenas um rastreável. Qualquer automação Prime atual está cega.
3. **Caddyfile host=dir hardcoded** (feedback cutover 23/04) — config não parametriza; adicionar tenant exige edit manual contradizendo multi-tenant do Parliament.
4. **Downloads/Evaluate These Documents contém .tsx idênticos a `dashboard/src/`** — se alguém editar no Downloads pensando que é canônico, trabalho perdido. **Ação:** arquivar ou deletar o dump após triagem desta pasta.
5. **Anna paused** (MEMORY.md) vs **Phase 1a "IA no ar"** (project_dap4_phase1a) — dois estados verdadeiros em janelas temporais diferentes, memória não reconciliou. Fonte canônica hoje: `project_dap4_cutover_2026_04_23.md` (mais recente).
6. **CLAUDE.md descreve "9 elevadores/~50 OS/mês/R$300k"** — número vive em doc estático. Supabase tem o real. Divergência silenciosa cada mês.
7. **3 docs de roadmap em Downloads** (Roadmap CRM Duplo, Operação Própria, Sophia Hub) — nenhum é canônico. Canônico é `001-master-todo.md`. Os três devem ser lidos como input Manus e descartados ou mergeados.
8. **Vault sincroniza para GitHub público?** — verificar. Se sim, qualquer menção a `.env`, token Kommo, IDs Supabase em notas é vazamento.
9. **`C:\dev\dap4\docs\` vs `PITOS/Sistemas/`** — dois lugares para doutrina técnica. Regra: `dap4/docs/` é doc de código (README por módulo), `PITOS/Sistemas/` é doutrina de negócio/arquitetura. Qualquer overlap = mover para Sistemas e link de dap4/docs.
10. **Memória IA fragmentada em 28 arquivos** — alguns `project_*` cobrem o mesmo sistema em datas diferentes (project_dap4, _live, _cutover, _phase1a). Sem política de sunset, cresce linearmente. **Ação:** `project_*` datado → arquivar após 30 dias se superseded.

---

## Protocolo de escrita (enforcement)

Antes de gravar informação em qualquer lugar:

1. **Qual tipo?** (1-8 acima)
2. **Estou escrevendo na fonte canônica?** Se não, parar e redirecionar.
3. **Existe versão mais nova em outra fonte?** Se sim, reconciliar antes de escrever.
4. **Vai virar derivado (PPT, relatório, memo)?** Marcar explicitamente como derivado com link pra canônica.

Qualquer doc que viole isso entra em `_triagem-YYYY-MM-DD/` até ser reconciliado.
