# Plano de Arquivamento — Manus AI Audits (2026-03-18)

**Origem:** `C:\Users\docto\Downloads\Evaluate These Documents\`
**Destino base:** `C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Business Intelligence\Manus-Audits-2026-03-18\`
**Data triagem:** 2026-04-23
**Nota:** pasta contém mix de outputs Manus (valor histórico) + código operacional DAP4 (frontend+backend já em `C:\dev\dap4`) + zips. Este plano trata APENAS dos artefatos Manus. Arquivos de código/.tsx/.ts/.py/.js/.mjs/test/package.json/vercel.json/schema.ts/index.html/index.css são deduplicatas de `C:\dev\dap4` — DELETAR (não arquivar).

## Estrutura destino proposta

```
Manus-Audits-2026-03-18/
├── 01-relatorios/          # MDs executivos
├── 02-charts/              # PNGs 01–11 análise leads
├── 03-planilhas/           # xlsx campanha + análise
├── 04-diagramas/           # .mmd + .png arquiteturais
├── 05-pdfs/                # analíticos PDF
└── 06-findings-notas/      # MDs de progresso/notas brutas
```

## 1. Relatórios executivos (ALTO valor — ARQUIVAR)

| Arquivo origem | Destino | Valor | Ação |
|---|---|---|---|
| `Relatório Definitivo_ Ecossistema Doctor Auto Prime & Sophia Hub.md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `Relatório de Avaliação Complementar_ Sophia Hub.md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `Relatório de Avaliação_ Ecossistema Doctor Auto Prime.md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `Análise Estratégica do CRM — Doctor Auto.md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `Arquitetura do Ecossistema IA_ RAG, CRM, Bots e LLMs.md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `BLUEPRINT_IA_MAE.md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `Roadmap de Criação_ Doctor Auto Prime & Sophia Hub.md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `Roadmap de Criação_ Doctor Auto Prime (Estratégia CRM Duplo).md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `Roadmap de Criação_ Sistema Doctor Auto Prime (Operação Própria).md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `Integração Estratégica_ Ahrefs API + Cohere AI.md` | `01-relatorios/` | MÉDIO | ARQUIVAR |
| `Resumo das Capacidades da API Cohere v2.md` | `01-relatorios/` | MÉDIO | ARQUIVAR |
| `conceito_crm_duplo.md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `mapeamento_estado_atual.md` | `01-relatorios/` | ALTO | ARQUIVAR |
| `📦ExércitodeIAs-DoctorPrime2026.md` | `01-relatorios/` | MÉDIO | ARQUIVAR |
| `ecosystem_research.md` | `01-relatorios/` | BAIXO | ARQUIVAR |

## 2. Charts PNG análise leads (ALTO — ARQUIVAR)

| Arquivo | Destino | Valor |
|---|---|---|
| `01_pipeline_dist.png` | `02-charts/` | ALTO |
| `02_funil_conversao.png` | `02-charts/` | ALTO |
| `04_inatividade.png` | `02-charts/` | ALTO |
| `06_evolucao_mensal.png` | `02-charts/` | ALTO |
| `07_heatmap_dia_hora.png` | `02-charts/` | ALTO |
| `08_qualidade_telefone.png` | `02-charts/` | ALTO |
| `09_ticket_distribuicao.png` | `02-charts/` | ALTO |
| `10_personas.png` | `02-charts/` | ALTO |
| `11_gargalos.png` | `02-charts/` | ALTO |

## 3. Planilhas (MÉDIO/ALTO — ARQUIVAR; possível conflito com framework novo)

| Arquivo | Destino | Valor | Nota |
|---|---|---|---|
| `CAMPANHA_REATIVACAO_AQUECIDA.xlsx` | `03-planilhas/` | ALTO | 389 KB — listas Manus |
| `CAMPANHA_REATIVACAO_COMPLETA.xlsx` | `03-planilhas/` | ALTO | 347 KB |
| `REATIVACAO_DOCTOR_AUTO_PRIME_BOSCH.xlsx` | `03-planilhas/` | MÉDIO | 16 KB — sobreposição c/ `framework-leads-novos` já canônico |
| `REATIVACAO_REAL_DOCTOR_AUTO.xlsx` | `03-planilhas/` | ALTO | 264 KB |
| `analiseaprofundada.xlsx` | `03-planilhas/` | ALTO | planilha fonte dos charts |

## 4. Diagramas arquiteturais (.mmd + .png) — ARQUIVAR

| Par | Destino | Valor |
|---|---|---|
| `evolucao_arquitetural.{mmd,png}` | `04-diagramas/` | ALTO |
| `sophia_hub_arch.{mmd,png}` | `04-diagramas/` | ALTO |
| `crm_duplo_arch.{mmd,png}` | `04-diagramas/` | ALTO |
| `fluxo_lead_lifecycle.{mmd,png}` | `04-diagramas/` | ALTO |
| `roadmap_crm_duplo_gantt.{mmd,png}` | `04-diagramas/` | MÉDIO |
| `roadmap_deps.{mmd,png}` | `04-diagramas/` | MÉDIO |
| `roadmap_gantt.{mmd,png}` | `04-diagramas/` | MÉDIO |
| `roadmap_sistema_gantt.{mmd,png}` | `04-diagramas/` | MÉDIO |
| `status_sistema.{mmd,png}` | `04-diagramas/` | MÉDIO |

## 5. PDFs analíticos — ARQUIVAR

| Arquivo | Destino | Valor |
|---|---|---|
| `doctor_auto_plano_mestre.pdf` | `05-pdfs/` | ALTO |
| `test-report.pdf` | `05-pdfs/` | BAIXO (relatório de teste automático) |

## 6. Findings e notas de progresso (MÉDIO — ARQUIVAR)

| Arquivo | Destino | Valor |
|---|---|---|
| `chart_findings.md` | `06-findings-notas/` | MÉDIO |
| `enrichment-progress.md` | `06-findings-notas/` | MÉDIO |
| `lead_analysis_findings.md` | `06-findings-notas/` | ALTO |
| `pdf_findings.md` | `06-findings-notas/` | MÉDIO |
| `pdf-report-findings.md` | `06-findings-notas/` | MÉDIO |
| `progress-notas.md`/`progress-notes.md` | `06-findings-notas/` | BAIXO |
| `todo.md` | `06-findings-notas/` | BAIXO |
| `ideas.md` | `06-findings-notas/` | MÉDIO |
| `webhook_integration_guide.md` | `06-findings-notas/` | MÉDIO |
| `cohere_demo_output.txt` | `06-findings-notas/` | BAIXO |
| `README.md` | `06-findings-notas/` | BAIXO |

## 7. DELETAR (código duplicado de `C:\dev\dap4` + zips redundantes)

Não arquivar. Já existe em produção/git. Motivo: ruído operacional sem valor histórico único.

- Todos os `.tsx` (Agent*, App, Campaign*, Config*, Crm*, Dashboard*, Enrichment*, Financial, Home, Intelligence, Kpi, Leads, Melhorias, Patio, Personas, Prompts, Sales, Sistema, UnitFilter, Weekly)
- Todos os `.ts` (auth/dashboard/enrichment/extended/pdfReport/prompts-rag/sidebar/unitFilter/webhook*/webhook-agent-sync.test.ts; db*, env, index, routers*, schema, storage, useDashboard, useUnitFilter, webhook, pdfReport, mockData)
- Todos os `.py` Manus (analyze_leads, campanha_*, cohere_demo, crm_bot, enrich_leads, gerar_lista_reativacao, import_enriched_leads, kommo_*, llm_orchestrator, main, pescar_ids, rag_engine)
- Todos os `.js/.mjs` (ana.js, _utils.js, reativador.js, relatorio.js, seed-db.mjs, seed-extended.mjs)
- `package.json`, `vercel.json`, `index.html`, `index.css`
- `webdev-preview-1773947508.png` (screenshot de preview, descartável)
- `.env.example` (secret-adjacent, descartar)
- **Zips:** `ComotestareusaraAPICoherecomumscript.zip`, `exercito-ias-COMPLETO(1).zip`, `sophia-hub(2).zip` — DELETAR se o conteúdo já foi extraído; caso contrário mover para `_archive/2026-04-23-zips-manus/` para inspeção posterior.

## Comandos prontos (executar depois — NÃO rodar agora)

### PowerShell — criar estrutura e mover por robocopy

```powershell
$src = "C:\Users\docto\Downloads\Evaluate These Documents"
$dst = "C:\Users\docto\OneDrive\Documentos\CHAIRMAN\PITOS\Business Intelligence\Manus-Audits-2026-03-18"

# 1. criar estrutura
"01-relatorios","02-charts","03-planilhas","04-diagramas","05-pdfs","06-findings-notas" | ForEach-Object {
  New-Item -ItemType Directory -Force -Path "$dst\$_" | Out-Null
}

# 2. relatórios
robocopy $src "$dst\01-relatorios" "Relatório*.md" "Análise Estratégica*.md" "Arquitetura do Ecossistema*.md" "BLUEPRINT_IA_MAE.md" "Roadmap de Criação*.md" "Integração Estratégica*.md" "Resumo das Capacidades*.md" "conceito_crm_duplo.md" "mapeamento_estado_atual.md" "📦ExércitodeIAs-DoctorPrime2026.md" "ecosystem_research.md" /MOV

# 3. charts
robocopy $src "$dst\02-charts" "01_pipeline_dist.png" "02_funil_conversao.png" "04_inatividade.png" "06_evolucao_mensal.png" "07_heatmap_dia_hora.png" "08_qualidade_telefone.png" "09_ticket_distribuicao.png" "10_personas.png" "11_gargalos.png" /MOV

# 4. planilhas
robocopy $src "$dst\03-planilhas" "CAMPANHA_REATIVACAO_*.xlsx" "REATIVACAO_*.xlsx" "analiseaprofundada.xlsx" /MOV

# 5. diagramas
robocopy $src "$dst\04-diagramas" "evolucao_arquitetural.*" "sophia_hub_arch.*" "crm_duplo_arch.*" "fluxo_lead_lifecycle.*" "roadmap_*.mmd" "roadmap_*.png" "status_sistema.*" /MOV

# 6. pdfs
robocopy $src "$dst\05-pdfs" "doctor_auto_plano_mestre.pdf" "test-report.pdf" /MOV

# 7. findings
robocopy $src "$dst\06-findings-notas" "chart_findings.md" "enrichment-progress.md" "lead_analysis_findings.md" "pdf_findings.md" "pdf-report-findings.md" "progress-notes.md" "todo.md" "ideas.md" "webhook_integration_guide.md" "cohere_demo_output.txt" "README.md" /MOV
```

### Depois de confirmar arquivo, deletar resto (DESTRUTIVO — revisar antes)

```powershell
# código duplicado de dap4 + zips + preview + .env.example
Remove-Item "$src\*.tsx","$src\*.ts","$src\*.py","$src\*.js","$src\*.mjs","$src\*.mts" -Force
Remove-Item "$src\package.json","$src\vercel.json","$src\index.html","$src\index.css","$src\.env.example" -Force
Remove-Item "$src\webdev-preview-*.png" -Force
# zips — mover pra _archive (inspecionar antes de deletar)
Move-Item "$src\*.zip" "C:\Users\docto\_archive\2026-04-23-zips-manus\" -Force
```

## Resumo

- **ARQUIVAR:** 15 relatórios + 9 charts + 5 planilhas + 9 pares diagrama (.mmd+.png) + 2 PDFs + 11 notas = ~60 artefatos com valor histórico real
- **DELETAR:** ~70 arquivos de código (duplicatas de `C:\dev\dap4`) + 1 preview PNG + 1 .env.example
- **MOVER PRA `_archive/`:** 3 zips (inspecionar antes de descartar)
- **NÃO EXECUTAR NADA AGORA** — plano pronto para cópia manual após revisão do Thales
