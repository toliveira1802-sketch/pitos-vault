# RAG Ops — Plano de Ingestão (desbloqueio do gargalo)

**Data:** 2026-04-23
**Autor:** Claudin
**Escopo:** desbloquear `ops_* vazio em prod` documentado na memória. Análise + plano, sem executar.
**Fontes mapeadas:** `C:\dev\dap4\agents\rag\*`, `C:\dev\dap4\agents\ingestion\*`, `C:\dev\dap4\dashboard-git\scripts\seed_operational_rag.py`, `PITOS\DAP 4.0\Documentos\rag-seed\`, `PITOS\DAP 4.0\Frameworks Operacionais\`, `PITOS\Business Intelligence\Kommo Analysis 2026-03\`.

---

## 0. Diagnóstico do gargalo

O código do Parliament/Anna já está correto: `agents/rag/chroma_client.py` declara as collections canônicas, `ingestion/pipeline.py` faz chunk → embed → Chroma → registry Supabase, `agents/ana.py:_retrieve_context()` busca de `self.rag_collections` (definido em `config/prompts/ana.yaml`). O problema é **dados**, não código.

Existe um seed legado em `C:\dev\dap4\dashboard-git\scripts\seed_operational_rag.py` (131 linhas, prosa inline) que:

- Cita unidades inexistentes ("matriz", "Garage 347", "rede Bosch Car Service").
- Fixa preços que **contradizem o guardrail** da Anna (`NAO FORNECA VALORES` — `anna-guardrails.md`).
- Ignora as **20 notas canônicas** em `rag-seed/` (4 marcas × 5 tópicos).
- Não é tenant-aware (mistura Prime e Bosch).
- Roda uma vez e esquece — sem deduplicação, sem re-ingest incremental, sem registry.

**Decisão:** aposentar o seed legado, criar pipeline proprio que consome o vault + Kommo + frameworks.

---

## 1. Collections `ops_*` canônicas

Código atual declara três (`chroma_client.py`) e o Parliament usa uma quarta (`parliament/models.py:95`). Proposta:

| Collection | Propósito | Fonte primária | Consumidores |
|---|---|---|---|
| `ops_client_support` | FAQ, tom, política de atendimento, diferenciais, horário, garantia | `rag-seed/*/bmw-05-faq-cliente.md` (e equivalentes), `anna-guardrails.md` §1-3, `crm-duplo-v1.md` | Anna, Sofia |
| `ops_service_procedures` | Cronograma revisão/km, problemas comuns, SOPs de bancada, checklist OS | `rag-seed/*/01-revisao-por-km.md`, `*/02-problemas-comuns.md`, `PITOS/AutoDiag Copilot/` | Anna, Parliament (OPS), Sophia |
| `ops_pricing_guidelines` | Diretrizes de **política** comercial (NÃO tabela de preços) — faixas, gate, desconto, orçamento duplo | `anna-guardrails.md` §2 (gate de preço), `framework-leads-novos.md` (tiers) | Anna (gate), Parliament (FIN) |
| `ops_fichas_tecnicas` (NOVA) | Fichas por modelo: tolerâncias, fluidos, TSB, motor codes | `rag-seed/*/02-problemas-comuns.md`, `*/03-ecu-tcu-remap.md`, `*/04-pecas-originais-vs-paralelas.md` | Parliament (OPS), Sophia diagnóstico |
| `ops_remap_manuals` (NOVA) | Remap ECU/TCU Stage 1/2/3, dinamômetro, motor por motor | `rag-seed/*/03-ecu-tcu-remap.md` (4 arquivos) | Anna (DAP Performance), Parliament |
| `ops_personas_leads` (NOVA) | 9 personas do Manus, framework scoring 5 eixos, playbook por tier | `framework-leads-novos.md`, `Kommo Analysis 2026-03/lead_analysis_findings.md`, `10_personas.png` contexto | Anna (classify), Insights |
| `ops_historico_clientes` (NOVA) | OS passadas, padrões de retorno, RFM, reativação | Supabase `crm_leads`+`os` (query programática), `REATIVACAO_*.xlsx` | Anna (followup), Insights |
| `ops_resolutions` (EXISTE) | Decisões do Parliament C-Level (archivadas) | `parliament/archiver.py` grava automático | Parliament self-reference |

**Justificativa de separação:** retrieval por collection é barato e dá foco. Anna usa `ops_client_support + ops_service_procedures + ops_personas_leads` para conversa; Sophia usa `ops_service_procedures + ops_fichas_tecnicas` para diagnóstico; Parliament OPS usa `ops_service_procedures + ops_resolutions`. Se misturar tudo numa collection só, recall cai por contaminação de domínio.

---

## 2. Fontes por collection (paths absolutos)

```
ops_client_support
├── PITOS/DAP 4.0/Frameworks Operacionais/anna-guardrails.md (§1, §3, §5-7)
├── PITOS/DAP 4.0/Frameworks Operacionais/crm-duplo-v1.md
├── PITOS/DAP 4.0/Documentos/rag-seed/{bmw,audi,mercedes,vw}/*-05-faq-cliente.md
└── PITOS/DAP 4.0/Notas/003-dap40-dores-e-legado.md (contexto de marca)

ops_service_procedures
├── PITOS/DAP 4.0/Documentos/rag-seed/{bmw,audi,mercedes,vw}/*-01-revisao-por-km.md
├── PITOS/DAP 4.0/Documentos/rag-seed/{bmw,audi,mercedes,vw}/*-02-problemas-comuns.md
├── PITOS/AutoDiag Copilot/specs/** (se houver SOP redigido)
└── PITOS/DAP 4.0/Notas/004-dap-copilot-diagnostico-eletrico.md

ops_pricing_guidelines
├── PITOS/DAP 4.0/Frameworks Operacionais/anna-guardrails.md (§2 Gate de Preço — canônico)
└── PITOS/DAP 4.0/Frameworks Operacionais/framework-leads-novos.md (política por tier)

ops_fichas_tecnicas
├── PITOS/DAP 4.0/Documentos/rag-seed/{bmw,audi,mercedes,vw}/*-02-problemas-comuns.md
└── PITOS/DAP 4.0/Documentos/rag-seed/{bmw,audi,mercedes,vw}/*-04-pecas-originais-vs-paralelas.md

ops_remap_manuals
└── PITOS/DAP 4.0/Documentos/rag-seed/{bmw,audi,mercedes,vw}/*-03-ecu-tcu-remap.md

ops_personas_leads
├── PITOS/DAP 4.0/Frameworks Operacionais/framework-leads-novos.md
├── PITOS/DAP 4.0/Frameworks Operacionais/DAP_Framework_Leads_Novos.pdf (extrair via pdfplumber)
└── PITOS/Business Intelligence/Kommo Analysis 2026-03/lead_analysis_findings.md
    └── ... /mapeamento_estado_atual.md, conceito_crm_duplo.md

ops_historico_clientes
├── Supabase query: crm_leads + os (JOIN por telefone, últimos 12 meses, PII redacted)
└── PITOS/Business Intelligence/Kommo Analysis 2026-03/analiseaprofundada.xlsx
```

---

## 3. Pipeline de ingestão

Reusa `IngestionPipeline` existente (`agents/ingestion/pipeline.py:18`). Embedder já é `text-embedding-3-small` @ 1536d (`config/settings.py:28`), chunker é char-based 512/64 (`config/settings.py:36`). Manter por enquanto — trocar para semantic chunking é Fase 2.

```
[vault .md] → frontmatter_parser → chunker(512,64) → embed_batch(OpenAI) → chroma.add_documents → supabase.document_registry
[vault .pdf] → pdfplumber → chunker → ... (mesmo fluxo)
[vault .xlsx] → pandas.read_excel → row-to-text template → ... (mesmo fluxo)
[Supabase] → SQL query → row-to-text template → chunker → ... (mesmo fluxo)
```

**Melhorias necessárias no pipeline atual (pequenas):**

1. Adicionar `source_path` + `source_hash` (SHA-256) nos `metadatas` de cada chunk — pré-requisito pro re-ingest incremental.
2. `ingest_from_vault_file(path, target_collection, tenant_id)` como novo método — faz frontmatter parse, metadata enrichment, upsert com `ids = f"{sha_prefix}_{chunk_idx}"` pra idempotência.
3. Chunker: respeitar headings `##` markdown antes de cair em char boundary (ganho de recall grande em docs editoriais).

---

## 4. Estratégia multi-tenant

**Decisão: metadata `tenant_id` numa collection única por tipo.** Não `ops_prime_sops` + `ops_bosch_sops`.

Razão técnica: ChromaDB `where` clause é O(1) em metadata indexado; duplicar collection triplica overhead (Prime+Bosch+global) e quebra retrieval cross-tenant quando Sophia precisa comparar. Padrão já usado no Parliament via `tenant.py`.

Convenção de metadata (todo chunk carrega):

```python
{
  "doc_id": uuid,
  "chunk_index": int,
  "title": str,
  "source_type": "vault_md|vault_pdf|vault_xlsx|supabase|kommo",
  "source_path": str,           # absolute, relative to vault root
  "source_hash": sha256_hex,
  "tenant_id": "prime|bosch|global",   # global = doutrina compartilhada
  "brand": "bmw|audi|mercedes|vw|all",
  "topic": "revisao|problemas|remap|pecas|faq|guardrail|persona|pricing",
  "vigencia": isodate,          # para expirar docs antigos
  "ingested_at": isotimestamp
}
```

Query pela Anna (Bosch): `where={"tenant_id": {"$in": ["bosch", "global"]}}`. O retriever atual (`rag/retriever.py:42`) já aceita `where`, só precisa propagar o tenant do contexto da conversa.

---

## 5. Frequência de re-ingestão

Três camadas:

| Fonte | Tipo | Cadência | Trigger |
|---|---|---|---|
| `rag-seed/*.md`, `Frameworks Operacionais/*.md` | Doutrina | On-demand + hash check diário | cron 03:00 UTC, `vault-sync.sh` já puxa do GitHub |
| Supabase `crm_leads` + `os` | Estado operacional | Diário (snapshot D-1) | cron 04:00 UTC, query últimos 30d + delta desde `ingested_at` |
| Kommo notes / mensagens | Log conversacional | Não ingerir na ops_* (muito ruído). Semanal em `study_business_insights` consolidado | cron semanal domingo 05:00 UTC |

**Hash check:** antes de re-ingerir, computa SHA-256 do arquivo, busca no `document_registry` Supabase por `source_path`. Se hash igual → skip. Se diferente → delete chunks antigos (`where source_hash=old_hash`) + ingest novo. Idempotente.

---

## 6. Script de bootstrap (pseudocódigo do primeiro run)

Arquivo proposto: `C:\dev\dap4\agents\scripts\bootstrap_rag_ops.py`. Aposenta o `dashboard-git/scripts/seed_operational_rag.py` legado.

```python
# pseudo
VAULT_ROOT = Path("/root/thales-vault/PITOS")   # na VPS via vault-sync
INGEST_MAP = {
    "ops_client_support": {
        "tenant": "global",
        "files": [
            ("DAP 4.0/Frameworks Operacionais/anna-guardrails.md", "guardrail"),
            ("DAP 4.0/Frameworks Operacionais/crm-duplo-v1.md", "crm_policy"),
            *[(f"DAP 4.0/Documentos/rag-seed/{b}/{b}-05-faq-cliente.md", "faq")
              for b in ["bmw","audi","mercedes","vw"]],
        ],
    },
    "ops_service_procedures": {
        "tenant": "global",
        "files": [
            *[(f"DAP 4.0/Documentos/rag-seed/{b}/{b}-0{i}-{t}.md", t)
              for b in ["bmw","audi","mercedes","vw"]
              for i,t in [(1,"revisao-por-km"),(2,"problemas-comuns")]],
            ("DAP 4.0/Notas/004-dap-copilot-diagnostico-eletrico.md", "diagnostico"),
        ],
    },
    "ops_pricing_guidelines": {
        "tenant": "global",
        "files": [
            ("DAP 4.0/Frameworks Operacionais/anna-guardrails.md#gate-de-preco", "gate"),
            ("DAP 4.0/Frameworks Operacionais/framework-leads-novos.md", "tier_policy"),
        ],
    },
    "ops_fichas_tecnicas": {...},
    "ops_remap_manuals": {...},
    "ops_personas_leads": {...},
}

async def bootstrap():
    chroma = ChromaManager()
    chroma.initialize_collections()           # cria as 6 novas também
    pipeline = IngestionPipeline(chroma)
    report = []
    for collection, spec in INGEST_MAP.items():
        for rel_path, topic in spec["files"]:
            path = VAULT_ROOT / rel_path
            text, fm = parse_markdown_with_frontmatter(path)
            brand = fm.get("brand", "all")
            sha = sha256(path.read_bytes())
            if already_ingested(path, sha): continue
            result = await pipeline.ingest_text(
                text=text,
                title=fm.get("title", path.stem),
                source_type="vault_md",
                target_collection=collection,
                target_rag="operational",
                metadata={
                    "tenant_id": spec["tenant"], "brand": brand,
                    "topic": topic, "source_path": str(rel_path),
                    "source_hash": sha, "vigencia": fm.get("data"),
                },
            )
            report.append(result)
    ingest_supabase_rfm(chroma, pipeline)      # ops_historico_clientes
    print_counts(chroma)
```

Execução: `docker compose exec agents python -m scripts.bootstrap_rag_ops` (on VPS).

---

## 7. Smoke tests pós-ingestão

Criar `agents/tests/test_rag_ops_smoke.py` — não mocka, bate no Chroma real do dev. Cada teste espera `score ≥ 0.55` e fonte correta no top-3.

```python
SMOKE_QUERIES = [
    # (query, expected_collection, expected_source_contains, min_score)
    ("Como faço revisão de BMW 320i aos 40 mil km?",
     "ops_service_procedures", "bmw-01-revisao-por-km", 0.55),
    ("Stage 1 em Audi RS3 dá quanto de ganho?",
     "ops_remap_manuals", "audi-03-ecu-tcu-remap", 0.55),
    ("Cliente pediu desconto, o que eu faço?",
     "ops_pricing_guidelines", "framework-leads-novos OR anna-guardrails", 0.50),
    ("Mercedes C180 vazando óleo, o que investigar?",
     "ops_fichas_tecnicas", "mercedes-02-problemas-comuns", 0.55),
    ("Cliente é de Mogi, vale atender?",
     "ops_personas_leads", "framework-leads-novos", 0.50),
    ("Qual o tom da Anna quando cliente pede preço direto?",
     "ops_client_support", "anna-guardrails", 0.60),
]
```

Rodar: `pytest agents/tests/test_rag_ops_smoke.py -v`. Gate de go-live: 6/6 passando.

---

## 8. Métricas de saúde

Adicionar endpoint `GET /rag/ops/health` (extend `api/routes/rag.py`) que retorna:

```json
{
  "collections": [
    {"name":"ops_client_support","count":47,"tenants":["global"],"last_ingest":"..."},
    ...
  ],
  "document_registry_total": 312,
  "oldest_doc_days": 9,
  "smoke_tests": {"passed": 6, "failed": 0, "last_run": "..."},
  "embedding_budget_last_7d_usd": 0.42
}
```

Sophia Hub (`/sophia`) consome e renderiza card de saúde do RAG.

**Custo estimado do bootstrap inicial:** 20 notas seed (~3k chars cada) + 3 frameworks (~15k cada) + Supabase snapshot (~500 linhas × 200 chars) = ~180k tokens de input. `text-embedding-3-small` @ $0.02/1M tokens → **$0.004** por bootstrap completo. Irrelevante. Cron diário mantém <$0.10/mês.

---

## 9. Ordem de execução recomendada

1. **Criar branch** `feat/rag-ops-bootstrap` em `C:\dev\dap4`.
2. **Estender `chroma_client.py`:** adicionar `ops_fichas_tecnicas`, `ops_remap_manuals`, `ops_personas_leads`, `ops_historico_clientes` ao `OPERATIONAL_COLLECTIONS`.
3. **Estender pipeline:** `ingest_from_vault_file()` com frontmatter + hash + tenant.
4. **Aposentar** `dashboard-git/scripts/seed_operational_rag.py` (mover para `_archive/` com nota).
5. **Criar** `agents/scripts/bootstrap_rag_ops.py` conforme §6.
6. **Criar** smoke tests `test_rag_ops_smoke.py` (§7). Roda RED antes do bootstrap.
7. **Rodar bootstrap** em dev, verificar counts + smoke GREEN.
8. **Ampliar `ana.yaml`** em `config/prompts/` para incluir as 3 novas collections relevantes a ela (`ops_personas_leads` principalmente).
9. **Cron VPS:** adicionar `rag_ops_reingest.sh` (03:00 UTC + 04:00 UTC).
10. **Endpoint health** + card Sophia Hub.
11. **Deploy prod.** Kill-switch Anna continua off até smoke tests + 1 ciclo de cron passarem. Depois reabre.

---

## 10. Decisões em aberto (precisam do Thales)

- **Separar Prime vs Bosch em `ops_pricing_guidelines`?** Política de desconto pode divergir. Recomendação: `tenant_id=global` no gate (que não menciona valor) + `tenant_id=prime/bosch` em notas separadas com política real. Decidir ao criar as notas.
- **Semantic chunker agora ou depois?** Char-based 512/64 quebra headings do vault. Ganho de recall com `RecursiveCharacterTextSplitter` + separators markdown é alto. Custo: +1 dia. Recomendação: incluir já no bootstrap.
- **Re-embed quando trocar modelo?** `text-embedding-3-small` vs `-large` (3072d). Large dá +3-5pp de recall mas 2x custo e dimensões maiores. Recomendação: ficar em small; reavaliar quando passar de 10k docs.
- **PII em `ops_historico_clientes`:** redação de telefone/nome antes de embed? Recomendação: **sim** — hash do telefone como ID, nome removido, vehicle+diagnóstico+outcome preservados.

---

## Fim.
