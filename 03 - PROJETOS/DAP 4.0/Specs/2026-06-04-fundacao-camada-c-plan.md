# Fundação · Camada C (Conhecimento) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidar o vault PITOS/DAP 4.0 numa estrutura canônica única e montar a árvore-mestra do ecossistema (mapa de domínios, pastas de unidade, template de descritivo, canon atualizado) — o conhecimento que os agentes leem primeiro.

**Architecture:** Trabalho de documentação/estrutura no vault Obsidian (git-sincronizado via `vault-sync`). Resolve a duplicata de sync do OneDrive consolidando em `DAP 4.0/` (nome limpo), migra conteúdo rico de `DAP 4.0 1/`, cria as novas pastas (`Ecossistema/`, `Portais/`, `Infra/`), e materializa o mapa + template. Todo passo é reversível via git; deleção só com confirmação do Thales.

**Tech Stack:** Markdown + Obsidian (wikilinks `[[...]]`), git, `git mv` pra preservar histórico.

**Caminho-base do vault:** `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\03 - PROJETOS`
(abaixo abreviado `…/03 - PROJETOS`)

---

## File Structure (alvo após consolidação)

```
03 - PROJETOS/DAP 4.0/                  ← pasta canônica única (nome limpo)
├── 000-CANON.md                        ← migrado de "DAP 4.0 1" + seção domínios
├── 00-MAPA-ECOSSISTEMA.md              ← NOVO (capa: mapa de domínios + árvore)
├── _UNIT-TEMPLATE.md                   ← NOVO (template de descritivo de unidade)
├── _triagem-2026-04-23/                ← migrado (dicionário canônico, cemitério…)
├── Documentos/                         ← migrado
├── Frameworks Operacionais/            ← migrado
├── Notas/                              ← migrado
├── Status/                             ← migrado
├── Specs/                              ← merge (este plano + spec + dap-prime-v1)
├── Ecossistema/                        ← NOVO · 1 pasta por unidade (12)
│   ├── DAP-Prime/  DAP-Performance/  DAP-Project/  DAP-AI/  DAP-Dev/
│   ├── DAP-Studio/  DAP-Social/  DAP-Ensina/  DAP-Consultoria/
│   └── DAP-Mulher/  DAP-Estetica/  DAP-Funilaria/
├── Portais/                            ← NOVO
│   ├── Consultor/    (← dap-operacao/*)
│   ├── Gestao/       (← dap-gestao/* + DOCTOR AUTO PRIME/PORTAL GESTAO/*)
│   ├── Mecanico/     (stub)
│   └── Cliente/      (stub)
└── Infra/                              ← NOVO (domínios, DNS, Caddy, deploy, KEYS quarentenado)
```

`DAP 4.0 1/` fica **vazia** ao final → deleção proposta ao Thales (Task 10).

---

### Task 1: Ponto de restauração (branch + backup commit)

**Files:**
- Git: repo do vault em `…/PITOS`

- [ ] **Step 1: Confirmar repo limpo e localização**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git status --short && git rev-parse --abbrev-ref HEAD
```
Expected: ver o branch atual e a lista de mudanças pendentes (o spec/plano novos aparecem como untracked). Anotar o branch atual.

- [ ] **Step 2: Criar branch de trabalho**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git checkout -b chore/dap40-camada-c-consolidacao
```
Expected: `Switched to a new branch 'chore/dap40-camada-c-consolidacao'`

- [ ] **Step 3: Commit de checkpoint do estado atual (spec + plano)**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git add "03 - PROJETOS/DAP 4.0/Specs/2026-06-04-agent-operating-environment-design.md" "03 - PROJETOS/DAP 4.0/Specs/2026-06-04-fundacao-camada-c-plan.md" && git commit -m "docs: spec + plano Camada C (Agent Operating Environment)"
```
Expected: commit criado. Este é o ponto de retorno seguro.

---

### Task 2: Migrar conteúdo rico de `DAP 4.0 1/` → `DAP 4.0/`

Mover diretórios que só existem na pasta de conflito. `git mv` preserva histórico. **Nenhum sobrescreve** arquivo existente em `DAP 4.0/` (são caminhos disjuntos exceto `Specs/`, tratado no Step 6).

**Files:**
- Move: `…/DAP 4.0 1/{000-CANON.md, _triagem-2026-04-23, Documentos, Frameworks Operacionais, Notas, Status}` → `…/DAP 4.0/`
- Merge: `…/DAP 4.0 1/Specs/*` → `…/DAP 4.0/Specs/`

- [ ] **Step 1: Mover 000-CANON.md e diretórios exclusivos**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS"
git mv "DAP 4.0 1/000-CANON.md"             "DAP 4.0/000-CANON.md"
git mv "DAP 4.0 1/_triagem-2026-04-23"      "DAP 4.0/_triagem-2026-04-23"
git mv "DAP 4.0 1/Documentos"               "DAP 4.0/Documentos"
git mv "DAP 4.0 1/Frameworks Operacionais"  "DAP 4.0/Frameworks Operacionais"
git mv "DAP 4.0 1/Notas"                    "DAP 4.0/Notas"
git mv "DAP 4.0 1/Status"                   "DAP 4.0/Status"
```
Expected: sem erro. (Se algum caminho não estava trackeado no git, usar `mv` simples no lugar de `git mv` pro item específico.)

- [ ] **Step 2: Mergear Specs (mover só os que faltam)**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS"
git mv "DAP 4.0 1/Specs/2026-04-18-dap-prime-v1-design.md" "DAP 4.0/Specs/2026-04-18-dap-prime-v1-design.md"
git mv "DAP 4.0 1/Specs/2026-04-18-dap-prime-v1-plan.md"   "DAP 4.0/Specs/2026-04-18-dap-prime-v1-plan.md"
[ -d "DAP 4.0 1/Specs/_archive" ] && git mv "DAP 4.0 1/Specs/_archive" "DAP 4.0/Specs/_archive"
```
Expected: specs do dap-prime agora em `DAP 4.0/Specs/` junto do spec/plano novos.

- [ ] **Step 3: Verificar**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS" && ls "DAP 4.0" && echo "--- restante em DAP 4.0 1 ---" && find "DAP 4.0 1" -type f | grep -v "dap-operacao\|dap-gestao" 
```
Expected: `DAP 4.0/` contém 000-CANON.md + diretórios migrados; em `DAP 4.0 1/` só sobra `dap-operacao/` e `dap-gestao/` (tratados na Task 4).

- [ ] **Step 4: Commit**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git add -A && git commit -m "chore: consolidar conteudo canonico DAP 4.0 1 -> DAP 4.0"
```

---

### Task 3: Criar o esqueleto de pastas novo

**Files:**
- Create dirs: `…/DAP 4.0/{Ecossistema, Portais/Consultor, Portais/Gestao, Portais/Mecanico, Portais/Cliente, Infra}`

- [ ] **Step 1: Criar diretórios**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS/DAP 4.0"
mkdir -p Ecossistema Portais/Consultor Portais/Gestao Portais/Mecanico Portais/Cliente Infra
```
Expected: sem saída (sucesso). Pastas vazias serão preenchidas nas próximas tasks (git só versiona quando tiverem arquivo).

---

### Task 4: Migrar conteúdo dos portais

**Files:**
- Move: `…/DAP 4.0 1/dap-operacao/*` → `…/DAP 4.0/Portais/Consultor/`
- Move: `…/DAP 4.0 1/dap-gestao/*` → `…/DAP 4.0/Portais/Gestao/`
- Move: `…/DAP 4.0/DOCTOR AUTO PRIME/PORTAL GESTAO/*` + `Doctor_Auto_Visao_Gestao.md` → `…/DAP 4.0/Portais/Gestao/`

- [ ] **Step 1: Consultor (← dap-operacao)**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS"
git mv "DAP 4.0 1/dap-operacao"/* "DAP 4.0/Portais/Consultor/" 2>/dev/null || mv "DAP 4.0 1/dap-operacao"/* "DAP 4.0/Portais/Consultor/"
rmdir "DAP 4.0 1/dap-operacao" 2>/dev/null
```
Expected: 9 arquivos (01-arquitetura … 08-postgres-migration, README) agora em `Portais/Consultor/`.

- [ ] **Step 2: Gestão (← dap-gestao + PORTAL GESTAO)**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS"
git mv "DAP 4.0 1/dap-gestao"/* "DAP 4.0/Portais/Gestao/" 2>/dev/null || mv "DAP 4.0 1/dap-gestao"/* "DAP 4.0/Portais/Gestao/"
rmdir "DAP 4.0 1/dap-gestao" 2>/dev/null
git mv "DAP 4.0/DOCTOR AUTO PRIME/PORTAL GESTAO"/* "DAP 4.0/Portais/Gestao/" 2>/dev/null || mv "DAP 4.0/DOCTOR AUTO PRIME/PORTAL GESTAO"/* "DAP 4.0/Portais/Gestao/"
git mv "DAP 4.0/DOCTOR AUTO PRIME/Doctor_Auto_Visao_Gestao.md" "DAP 4.0/Portais/Gestao/Doctor_Auto_Visao_Gestao.md" 2>/dev/null || mv "DAP 4.0/DOCTOR AUTO PRIME/Doctor_Auto_Visao_Gestao.md" "DAP 4.0/Portais/Gestao/"
```
Expected: `Portais/Gestao/` com os docs do dap-gestao (00-escopo, 01-arquitetura, 02-deploy-runbook, README) + os 11 docs numerados do PORTAL GESTAO + Doctor_Auto_Visao_Gestao.md.

- [ ] **Step 3: Verificar e commitar**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS" && echo "=Consultor=" && ls "DAP 4.0/Portais/Consultor" && echo "=Gestao=" && ls "DAP 4.0/Portais/Gestao"
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git add -A && git commit -m "chore: migrar docs de portais p/ DAP 4.0/Portais"
```
Expected: ambas as pastas populadas; commit criado.

---

### Task 5: Quarentenar `STACKS/KEYS.md` (segurança)

Segredo em vault git-sincronizado é risco. Tirar do caminho versionado.

**Files:**
- Source: `…/DAP 4.0/DOCTOR AUTO PRIME/STACKS/KEYS.md`
- Modify: `…/PITOS/.gitignore`

- [ ] **Step 1: Inspecionar se contém segredo real**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS" && head -30 "DAP 4.0/DOCTOR AUTO PRIME/STACKS/KEYS.md"
```
Expected: ver o conteúdo. Se contiver chaves/tokens reais → seguir Step 2. Se for só referência sem segredo → mover pra `Infra/` normalmente e pular Step 3.

- [ ] **Step 2: Mover pra Infra/ e remover do tracking git**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS"
mkdir -p "DAP 4.0/Infra/_secrets"
git mv "DAP 4.0/DOCTOR AUTO PRIME/STACKS/KEYS.md" "DAP 4.0/Infra/_secrets/KEYS.md" 2>/dev/null || mv "DAP 4.0/DOCTOR AUTO PRIME/STACKS/KEYS.md" "DAP 4.0/Infra/_secrets/KEYS.md"
```

- [ ] **Step 3: Adicionar ao .gitignore e remover do índice**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS"
echo "" >> .gitignore && echo "# Segredos DAP 4.0 (nunca versionar)" >> .gitignore && echo "03 - PROJETOS/DAP 4.0/Infra/_secrets/" >> .gitignore
git rm --cached "03 - PROJETOS/DAP 4.0/Infra/_secrets/KEYS.md" 2>/dev/null
```
Expected: KEYS.md fora do tracking git (continua no disco, mas não sincroniza pro GitHub).

> ⚠️ **NOTA AO THALES:** se essas chaves já estavam em commits anteriores no GitHub, elas estão expostas no histórico — **rotacionar os segredos** é o certo. Sinalizar na revisão.

- [ ] **Step 4: Limpar DOCTOR AUTO PRIME vazia e commitar**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS"
find "DAP 4.0/DOCTOR AUTO PRIME" -type f
```
Expected: vazio (todos os arquivos migrados). Se vazio:
```bash
rm -rf "DAP 4.0/DOCTOR AUTO PRIME"
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git add -A && git commit -m "chore: quarentenar KEYS.md + remover DOCTOR AUTO PRIME vazia"
```

---

### Task 6: Criar `00-MAPA-ECOSSISTEMA.md` (a capa)

**Files:**
- Create: `…/DAP 4.0/00-MAPA-ECOSSISTEMA.md`

- [ ] **Step 1: Escrever o arquivo com este conteúdo exato**

```markdown
---
title: DAP 4.0 — Mapa do Ecossistema
date: 2026-06-04
status: vigente
scope: mapa de domínios + árvore de unidades e portais
relacionado: "[[000-CANON]]"
---

# DAP 4.0 — Mapa do Ecossistema

> Capa de navegação. Detalhe canônico em [[000-CANON]]. Cada unidade/portal tem pasta própria.

## Arquitetura de domínios

`doctorautoprime40.com` = site institucional. Cada subdomínio encaminha pra um
portal/unidade. Portais operacionais = mesmo app `dap-aios` (1 banco, 1 login,
event log central); o subdomínio só fixa qual portal abre.

| Domínio | Aponta pra | Status |
|---|---|---|
| `doctorautoprime40.com` | Site institucional | 🔮 futuro |
| `consultor.doctorautoprime40.com` | Portal Consultor | ✅ agora |
| `gestao.doctorautoprime40.com` | Portal Gestão | 🔧 agora |
| `mecanico.doctorautoprime40.com` | Portal Mecânico | 🟡 agora |
| `cliente.doctorautoprime40.com` | Portal Cliente | 🔮 futuro |
| `aios.doctorautoprime40.com` | AIOS (orquestração/Sophia) | ✅ mantém |
| `ai.doctorautoprime40.com` | Dashboard dap4 (RAG/agentes) | 🔧 migrar da raiz |
| `performance.*` | DAP Performance | 🔮 futuro |
| `ensina.*` | DAP Ensina (Hotmart) | 🔮 futuro |
| `consultoria.*` | DAP Consultoria | 🔮 futuro |
| `project.* · studio.* · social.* · mulher.* · estetica.* · funilaria.*` | demais unidades | 🔮 futuro |

## Portais operacionais → [[Portais]]

- [[Consultor]] · [[Gestao]] · [[Mecanico]] · [[Cliente]]

## Unidades de negócio → Ecossistema/

DAP-Prime · DAP-Performance · DAP-Project · DAP-AI · DAP-Dev · DAP-Studio ·
DAP-Social · DAP-Ensina · DAP-Consultoria · DAP-Mulher · DAP-Estetica · DAP-Funilaria

## Plataforma / IA

- **AIOS** (`aios.*`) — orquestração, Sophia, event log.
- **Dashboard dap4** (`ai.*`) — RAG, agentes (Ana, Kimi, Sophia, Thales, Insights).
```

- [ ] **Step 2: Verificar e commitar**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && test -f "03 - PROJETOS/DAP 4.0/00-MAPA-ECOSSISTEMA.md" && git add "03 - PROJETOS/DAP 4.0/00-MAPA-ECOSSISTEMA.md" && git commit -m "docs: criar 00-MAPA-ECOSSISTEMA (mapa de dominios)"
```

---

### Task 7: Criar template de unidade + 12 pastas com stub

**Files:**
- Create: `…/DAP 4.0/_UNIT-TEMPLATE.md`
- Create: `…/DAP 4.0/Ecossistema/<Unidade>/README.md` (×12)

- [ ] **Step 1: Escrever o template com este conteúdo exato**

Arquivo `…/DAP 4.0/_UNIT-TEMPLATE.md`:
```markdown
---
title: "<NOME DA UNIDADE>"
status: "<🔮 futuro | 🔧 estruturando | ✅ operando>"
subdominio: "<slug>.doctorautoprime40.com"
relacionado: "[[00-MAPA-ECOSSISTEMA]]"
---

# <NOME DA UNIDADE>

## O que é
<uma frase: função da unidade no ecossistema>

## Status
<🔮 futuro | 🔧 estruturando | ✅ operando> — <contexto curto>

## Subdomínio
`<slug>.doctorautoprime40.com`

## Oferta
<produto/serviço que entrega>

## Mercado
- **Interno:** <como serve a operação DAP>
- **Externo:** <como vira produto/receita>

## RAG / Conteúdo
<o que essa unidade documenta que vira ativo de conteúdo (Hotmart, YouTube, blog)>

## Próximos passos
- [ ] <primeiro passo>
```

- [ ] **Step 2: Criar as 12 pastas com README a partir do template**

Para cada linha da tabela, criar `Ecossistema/<Pasta>/README.md` usando o template, preenchendo `título`, `status`, `subdomínio` e a frase de "O que é". Demais campos = `_a definir_` (preenchidos depois, na frente paralela do Ecossistema).

| Pasta | Título | Status | Subdomínio | O que é |
|---|---|---|---|---|
| DAP-Prime | DAP Prime | ✅ operando | prime | Manutenção premium de alemães (BMW, Audi, Mercedes, VW) |
| DAP-Performance | DAP Performance | ✅ operando | performance | Remap ECU/TCU, Stage 1/2/3, dinamômetro |
| DAP-Project | DAP Project | 🔧 estruturando | project | Builds especiais com storytelling |
| DAP-AI | DAP AI | 🔧 estruturando | (interno) | IA comercial + operacional + SaaS |
| DAP-Dev | DAP Dev | 🔧 estruturando | (interno) | Sistemas internos (codebase DAP4.0) |
| DAP-Studio | DAP Studio | 🔧 estruturando | studio | Produção de conteúdo e vídeos |
| DAP-Social | DAP Social | 🔧 estruturando | social | Instagram, YouTube, blog |
| DAP-Ensina | DAP Ensina | 🔧 estruturando | ensina | Cursos, workshops, Hotmart |
| DAP-Consultoria | DAP Consultoria | 🔧 estruturando | consultoria | Compra/venda de premium |
| DAP-Mulher | DAP Mulher | 🔮 futuro | mulher | Frente feminina premium |
| DAP-Estetica | DAP Estética | 🔮 futuro | estetica | Estética automotiva (via parceria) |
| DAP-Funilaria | DAP Funilaria | 🔮 futuro | funilaria | Funilaria e pintura |

Exemplo concreto — `Ecossistema/DAP-Performance/README.md`:
```markdown
---
title: "DAP Performance"
status: "✅ operando"
subdominio: "performance.doctorautoprime40.com"
relacionado: "[[00-MAPA-ECOSSISTEMA]]"
---

# DAP Performance

## O que é
Remap ECU/TCU, Stage 1/2/3, dinamômetro.

## Status
✅ operando — _detalhar_

## Subdomínio
`performance.doctorautoprime40.com`

## Oferta
_a definir_

## Mercado
- **Interno:** _a definir_
- **Externo:** _a definir_

## RAG / Conteúdo
_a definir_

## Próximos passos
- [ ] Escrever descritivo completo
```

(Unidades internas DAP-AI e DAP-Dev: subdomínio = `(interno)` — sem site público.)

- [ ] **Step 3: Verificar contagem e commitar**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS" && ls Ecossistema | wc -l && find Ecossistema -name README.md | wc -l
```
Expected: `12` pastas, `12` READMEs.
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git add -A && git commit -m "docs: template de unidade + 12 pastas de ecossistema (stub)"
```

---

### Task 8: Atualizar `000-CANON.md` com arquitetura de domínios

**Files:**
- Modify: `…/DAP 4.0/000-CANON.md`

- [ ] **Step 1: Ler o canon atual pra achar onde inserir**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS" && grep -n "^## " "DAP 4.0/000-CANON.md"
```
Expected: lista de seções. Inserir a nova seção logo após a seção 1 (Stack oficial), renumerando se necessário, OU como seção "1.5".

- [ ] **Step 2: Inserir a seção de domínios**

Adicionar ao `000-CANON.md` (após a tabela de stack oficial) este bloco:
```markdown
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
```

- [ ] **Step 3: Bump de versão no frontmatter**

No frontmatter do `000-CANON.md`, mudar `version: 1.0` → `version: 1.1` e `date:` → `2026-06-04`.

- [ ] **Step 4: Verificar e commitar**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS" && grep -n "Arquitetura de domínios" "DAP 4.0/000-CANON.md"
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git add "03 - PROJETOS/DAP 4.0/000-CANON.md" && git commit -m "docs: canon v1.1 — arquitetura de dominios"
```

---

### Task 9: Verificação final + proposta de deleção da órfã

**Files:**
- Inspect: `…/DAP 4.0 1/`

- [ ] **Step 1: Confirmar que `DAP 4.0 1/` está vazia**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS" && find "DAP 4.0 1" -type f 2>/dev/null
```
Expected: **nenhuma saída** (vazia). Se sobrou algo, migrar pro destino correto em `DAP 4.0/` antes de prosseguir.

- [ ] **Step 2: Validar a árvore final**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS" && find "DAP 4.0" -maxdepth 1 | sort
```
Expected: ver `000-CANON.md`, `00-MAPA-ECOSSISTEMA.md`, `_UNIT-TEMPLATE.md`, `_triagem-2026-04-23`, `Documentos`, `Ecossistema`, `Frameworks Operacionais`, `Infra`, `Notas`, `Portais`, `Specs`, `Status`.

- [ ] **Step 3: PARAR e confirmar com o Thales antes de deletar**

> 🛑 **GATE DE CONFIRMAÇÃO:** não deletar `DAP 4.0 1/` sem o ok explícito do Thales.
> Apresentar: "Pasta órfã `DAP 4.0 1/` confirmada vazia. Posso deletar?"
> Só após o "sim":
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS/03 - PROJETOS" && rm -rf "DAP 4.0 1"
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git add -A && git commit -m "chore: remover pasta orfa DAP 4.0 1 (consolidada)"
```

---

### Task 10: Merge da branch + sync

**Files:**
- Git: branch `chore/dap40-camada-c-consolidacao`

- [ ] **Step 1: Revisar o diff completo**

Run:
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git log --oneline <branch-original>..HEAD && git diff --stat <branch-original>...HEAD
```
Expected: ver todos os commits da Camada C e o resumo de arquivos. (Substituir `<branch-original>` pelo branch anotado na Task 1.)

- [ ] **Step 2: PARAR — confirmar merge com o Thales**

> 🛑 **GATE:** merge pro branch principal só com confirmação (regra de git do projeto).
> Após o "sim":
```bash
cd "/c/Users/docto/OneDrive/Documentos/CHAIRMAN/PITOS" && git checkout <branch-original> && git merge --no-ff chore/dap40-camada-c-consolidacao
```

- [ ] **Step 3: Confirmar que o `vault-sync` propaga**

O cron `vault-sync.sh` (VPS) sincroniza a cada 5min → `/root/thales-vault/` → GitHub. Nenhuma ação manual; verificar no próximo ciclo se o push saiu.

---

## Self-Review

**1. Spec coverage (Camada C do spec):**
- Consolidar duplicata → Tasks 2,4,5,9 ✅
- Árvore-mestra (Ecossistema/Portais/Infra) → Tasks 3,4,7 ✅
- 00-MAPA-ECOSSISTEMA → Task 6 ✅
- Atualizar 000-CANON com domínios → Task 8 ✅
- Template de descritivo de unidade → Task 7 ✅
- Migrar PORTAL GESTAO + dap-operacao → Task 4 ✅
- (Extra fora do spec, justificado) Quarentena de KEYS.md → Task 5 ✅ (risco de segurança encontrado no inventário)

**2. Placeholder scan:** Conteúdo completo fornecido pro mapa, template e seção do canon. As tabelas de unidades trazem todos os dados variáveis. Sem TBD/TODO de plano. ✅

**3. Type consistency:** Nomes de pasta consistentes entre tasks (`Ecossistema`, `Portais/{Consultor,Gestao,Mecanico,Cliente}`, `Infra`). Subdomínios consistentes entre Task 6 (mapa), Task 7 (template) e Task 8 (canon). ✅

**Gates de confirmação humana:** deleção (Task 9) e merge (Task 10) — ambos param e pedem ok ao Thales, conforme regras do projeto.
