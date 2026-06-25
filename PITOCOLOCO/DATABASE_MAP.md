---
tags: [database, supabase, doctor-prime, map, v2]
aliases: ["DB Map", "Schema Map"]
version: 2.0
generated_at: 2026-04-09
generated_by: Claudin (Phase 2 Operação Limpeza)
project_id: acuufrgoyjwzlyhopaus
postgres_version: "17.6"
predecessor: "[[DATABASE_MAP_v1_legacy_2026-01|DATABASE_MAP v1 (legacy)]]"
---

# DATABASE MAP — Doctor Prime v2

> [!success] v2.0 pós-limpeza
> Este mapa reflete o estado **pós-limpeza** do banco Doctor Prime após a Phase 2 da Operação Limpeza (09/04/2026). A v1 estava obsoleta — descrevia um estado com 52 tabelas e estruturas PascalCase que **não existiam mais**. A v2 é a fotografia real.
>
> **Mudanças principais desde a v1:**
> - 52 → 27 tabelas (12 dropadas na Phase 2, outras já tinham sido removidas antes)
> - Nomes canonicalizados: `04_CLIENTS` → `clients`, `05_VEHICLES` → `vehicles`, `06_OS` → `ordens_servico`, `01_colaboradores` → `colaboradores`, etc.
> - `verify_staff_login()` reescrita pra consultar apenas `colaboradores` (antes tentava 4 portais)
> - `rag_documentos` (schema PT-BR com vetor_emb inline) dropada — `rag_documents` é agora a única tabela de registry RAG

## Identidade

| Campo | Valor |
|-------|-------|
| Empresa | Doctor Auto Matriz |
| Empresa UUID | `a0000000-0000-0000-0000-000000000001` |
| Oficina | Doctor Auto Centro |
| Project ID | `acuufrgoyjwzlyhopaus` |
| Database host | `db.acuufrgoyjwzlyhopaus.supabase.co` |
| Postgres | 17.6.1.063 (us-west-2) |
| Total de tabelas | **27** (public schema) |

---

## Colaboradores (5 usuários ativos)

| Username | Nome | Cargo | Nível | Nota |
|----------|------|-------|:-----:|------|
| `Dev_thales` | Thales | Desenvolvedor | 1 | |
| `Gestao_thales` | Thales | Gestor | 2 | |
| `Consultor_maria` | Maria Silva | Consultora | 3 | |
| `Consultor_teste` | Thales Oliveira | Consultor | 3 | Migrado de `colaboradores_portal_consultor` em 09/04 |
| `Mecanico_joao` | João Souza | Mecânico | 4 | |

**Níveis de acesso:**
- 1 = Dev
- 2 = Gestão
- 3 = Consultor
- 4 = Mecânico
- 5 = Gestão+ (reservado, sem user ainda)

**Auth:** SHA-256 via `verify_staff_login(p_username, p_password)` — consulta `colaboradores`.

---

## Tabelas canônicas (27)

### Multi-tenant & Identidade

| Tabela | Rows | RLS | Função |
|--------|:--:|:--:|--------|
| `companies` | 1 | ✅ | Multi-tenant: empresas |
| `colaboradores` | 5 | ✅ | Staff (auth via SHA-256 + `verify_staff_login`) |
| `oficina_config` | 1 | ✅ | Config da oficina |

### Clientes & Veículos

| Tabela | Rows | RLS | Função |
|--------|:--:|:--:|--------|
| `clients` | 27 | ✅ | Clientes da oficina |
| `vehicles` | 25 | ✅ | Veículos dos clientes (FK → clients) |

### Ordens de Serviço

| Tabela | Rows | RLS | Função |
|--------|:--:|:--:|--------|
| `ordens_servico` | 48 | ✅ | OS principais |
| `ordens_servico_itens` | 0 | ✅ | Itens das OS (serviços/peças) |
| `ordens_servico_historico` | 0 | ✅ | Histórico de mudanças |
| `os_anexos` | 0 | ✅ | Anexos (fotos, docs) |

### Mecânica & Operação

| Tabela | Rows | RLS | Função |
|--------|:--:|:--:|--------|
| `mecanicos` | 3 | ✅ | Mecânicos da oficina |
| `mecanico_feedback` | 4 | ✅ | Feedback dos mecânicos |
| `pecas_encontradas` | 5 | ✅ | Peças localizadas (scraping) |
| `catalogo_servicos` | 3 | ✅ | Catálogo de serviços |
| `workflow_etapas` | 10 | ✅ | Etapas de workflow |
| `pendencias` | 0 | ✅ | Pendências operacionais |
| `recursos` | 0 | ✅ | Recursos/equipamentos |
| `agendamentos` | 0 | ✅ | Agendamentos |
| `recusas` | 0 | ✅ | Recusas de orçamentos |

### CRM (Kommo + externo)

| Tabela | Rows | RLS | Função |
|--------|:--:|:--:|--------|
| `crm_leads` | 5.911 | ✅ | Leads do CRM Kommo (primários) |
| `crm_leads_externo` | ~10.400+ | ✅ | Leads externos — **tabela viva, recebe dados em tempo real** (último registrado 14:02 de 09/04) |
| `webhook_logs` | 1.458 | ✅ | Logs de webhooks recebidos |

### IA / Sofia / RAG

| Tabela | Rows | RLS | Função |
|--------|:--:|:--:|--------|
| `ai_conversations` | 8 | ✅ | Threads de conversas |
| `ai_messages` | 50 | ✅ | Mensagens das conversas |
| `ai_agent_config` | 3 | ✅ | Config de agentes IA |
| `ai_api_keys` | 0 | ✅ | Chaves de API LLM (preparada, não populada) |
| `sofia_actions` | 193 | ✅ | Ações executadas pela Sofia |
| `rag_documents` | 20 | ✅ | Registry de docs do RAG (vetores vivem no ChromaDB, não aqui) |

### Totais

- **27 tabelas** (todas com RLS)
- **~18.300 rows totais** (maior parte em `crm_leads` + `crm_leads_externo` + `webhook_logs`)
- Nenhuma tabela legacy, nenhuma duplicada, nenhum PascalCase

---

## Functions importantes (user-defined, não pgvector)

### Auth
- **`verify_staff_login(p_username text, p_password text)`** — Login via SHA-256, consulta `colaboradores`. **Reescrita em 09/04** para não depender mais das tabelas portal dropadas.
- `change_staff_password(p_user_id uuid, p_new_password text)` — Troca senha
- `criar_usuario_staff(...)` — Cria novo colaborador (2 overloads)
- `hash_password(p_password text)` — Helper SHA-256

### Negócio
- `criar_cliente_com_veiculos(p_empresa_id, p_full_name, ...)` — Onboard cliente + veículos numa transação
- `fn_criar_veiculo(p_client_id, p_empresa_id, ...)` — Cria veículo
- `gerar_numero_os(p_empresa_id?)` — Gera numeração única de OS
- `fn_06_os_valor_final()` — Trigger: recalcula valor final
- `fn_07_os_itens_calculos()` — Trigger: calcula total dos itens
- `fn_07_os_itens_soma_aprovados()` — Trigger: soma só os aprovados
- `registrar_historico_os()` — Trigger: log de mudanças nas OS
- `aplicar_regras_automacao(p_ordem_servico_id uuid)` — Aplica automações

### IA
- `buscar_diagnosticos_similares(p_sintomas text, p_limite integer)` — Busca semântica nos diagnósticos
- `match_documentos(query_embedding, match_threshold, match_count)` — Matching RAG

### Kommo
- `get_active_kommo_config()` — Config ativa
- `log_kommo_sync(...)` — Log de sync
- `cleanup_old_kommo_logs()` — Manutenção
- `trigger_kommo_sync_os()` — Trigger sync

### Extensions (pgvector)
- 70+ functions de pgvector (halfvec, sparsevec, vector, hnsw, ivfflat) — não documentadas individualmente; são de extension

---

## Histórico de migrations (09/04/2026 — Phase 2)

Todas aplicadas via MCP `apply_migration` com sucesso:

1. `migrate_consultor_teste_to_colaboradores` — Migra Consultor_teste do portal pro colaboradores oficial
2. `drop_legacy_pascalcase_tables` — Drop Cliente, Veiculo, Mecanico, Colaborador, OrdemServico
3. `drop_legacy_portal_tables` — Drop 4 colaboradores_portal_*
4. `drop_legacy_rag_documentos` — Drop rag_documentos (schema PT-BR legacy)
5. `drop_unused_app_users_and_kv_store` — Drop app_users + kv_store_0092e077
6. `simplify_verify_staff_login_single_table` — Rewrite da function auth

---

## Backup (09/04/2026)

> [!note] Backup completo disponível
> Existe um backup full de todas as 24 tabelas com dados em `C:\dev\backups\doctor-prime-2026-04-09\`. Formato: JSON chunks via MCP, 13.16 MB total, validado com SHA256 e contagem de rows. Pode ser restaurado se necessário.
>
> Arquivos principais:
> - `tables/_small_medium_tables.json` — 21 tabelas pequenas/médias
> - `tables/webhook_logs.json` — 1458 rows
> - `tables/crm_leads_chunk_[1-6].json` — 5911 rows em 6 chunks
> - `tables/crm_leads_externo_chunk_[01-11].json` — 10405 rows em 11 chunks
> - `_manifest.json` — SHA256 + row counts + status OK
> - `_schema_columns.json` — schema completo (information_schema)
> - `_validate.py` — script re-executável de validação

---

## Próximos passos (Phase 3+ da Operação Limpeza)

- **Phase 3**: Rename `doctor-ai-dashboard` → `dap4` + deploy VPS + Cloudflare Tunnel + config linha Meta WhatsApp Ana
- **Phase 4**: thales-agent canal Obsidian + integração DAP4.0 via tools HTTP + config Evolution API linha pessoal
- **Phase 5**: Observabilidade compartilhada + backups automatizados + CI/CD

Ver [[000-spec-saida-30-dias|spec completo]] para detalhes.

---

**Versão:** 2.0
**Última atualização:** 2026-04-09 (Phase 2 completa)
**Próxima regeneração prevista:** após Phase 3 (quando houver mudanças no schema por causa do deploy + Meta integration)
