# DATABASE MAP — Doctor Prime

**Project ID:** `acuufrgoyjwzlyhopaus`
**Database:** Postgres 17.6
**Total tables:** 52
**Date:** 2026-04-09

---

## Identidade

| Campo | Valor |
|-------|-------|
| Empresa | Doctor Auto Matriz |
| Empresa UUID | `a0000000-0000-0000-0000-000000000001` |
| CNPJ | 12.345.678/0001-90 |
| Slug | doctor-auto |
| Oficina | Doctor Auto Centro |
| Oficina UUID | `a0000000-0000-0000-0000-000000000001` |

---

## Colaboradores existentes

| ID | Username | Nome | Cargo | Nivel |
|----|----------|------|-------|-------|
| da6eb9eb... | Dev_thales | Thales | Desenvolvedor | 1 |
| 547c92ea... | Gestao_thales | Thales | Gestor | 2 |
| 9b645230... | Consultor_maria | Maria Silva | Consultora | 3 |
| f6cd882b... | Mecanico_joao | Joao Souza | Mecanico | 4 |

**Niveis de acesso:**
- 1 = Dev
- 2 = Gestao
- 3 = Consultor
- 4 = Mecanico
- 5 = Gestao+

---

## Nucleo oficial (numeradas, com RLS)

Estas sao as tabelas que o sistema usa em producao via `verify_staff_login` e os portals.

| Tabela | Linhas | Tamanho | Funcao |
|--------|--------|---------|--------|
| `00_companies` | 1 | 32 kB | Multi-tenant: empresas |
| `01_colaboradores` | 4 | 48 kB | Staff (login via SHA-256) |
| `04_CLIENTS` | 27 | 32 kB | Clientes da oficina |
| `05_VEHICLES` | 25 | 32 kB | Veiculos dos clientes |
| `06_OS` | 48 | 64 kB | Ordens de servico |
| `07_OS_ITENS` | 0 | 16 kB | Itens das OS (servicos/pecas) |
| `08_OS_HISTORICO` | 0 | 16 kB | Historico de mudancas das OS |
| `10_users` | 0 | 16 kB | Auth users (vazio) |
| `12_MECANICOS` | 3 | 32 kB | Mecanicos da oficina |
| `13_PENDENCIAS` | 0 | 16 kB | Pendencias operacionais |
| `14_RECURSOS` | 0 | 16 kB | Recursos/equipamentos |
| `15_AGENDAMENTOS` | 0 | 16 kB | Agendamentos de servicos |
| `97_RECUSAS` | 0 | 16 kB | Recusas de orcamentos |

---

## Legacy PascalCase (SEM RLS — risco)

Tabelas antigas, em PascalCase, sem RLS. **Candidatos a DROP** depois de migrar dados.

| Tabela | Linhas | Tamanho |
|--------|--------|---------|
| `Cliente` | 95 | 64 kB |
| `Veiculo` | 126 | 80 kB |
| `OrdemServico` | 146 | 88 kB |
| `Mecanico` | 1 | 32 kB |
| `Colaborador` | 1 | 32 kB |

**Total a migrar: 379 registros**

---

## Duplicadas lowercase

Mais uma camada de duplicacao. Praticamente vazias. **Drop seguro.**

| Tabela | Linhas |
|--------|--------|
| `clientes` | 3 |
| `clientes_oficina` | 50 |
| `veiculos` | 0 |
| `veiculos_orfaos` | 0 |
| `mecanicos` | 0 |
| `ordens_servico` | 0 |
| `ordens_servico_itens` | 0 |
| `os_ultimate` | 0 |

---

## Portal-especificas

Uma tabela por portal de colaborador. **Drop apos consolidar em `01_colaboradores`.**

| Tabela | Linhas |
|--------|--------|
| `colaboradores_portal_consultor` | 4 |
| `colaboradores_portal_dev` | 1 |
| `colaboradores_portal_gestao` | 5 |
| `colaboradores_portal_mecanico` | 13 |

**Total: 23 colaboradores espalhados**

---

## Agendamento (3 versoes diferentes)

Caos de agendamento — 4 tabelas, todas vazias. **Manter so `15_AGENDAMENTOS`.**

| Tabela | Linhas |
|--------|--------|
| `agendamento` | 0 |
| `clients_agenda` | 0 |
| `clients_selfcad` | 0 |
| `novos_cli_agenda` | 0 |

---

## CRM

| Tabela | Linhas | Tamanho |
|--------|--------|---------|
| `crm_leads` | 5911 | 3280 kB |
| `crm_leads_externo` | 9269 | 3328 kB |
| `webhook_logs` | 1458 | 848 kB |

---

## IA / Sofia (RAG + Agents)

| Tabela | Linhas | Funcao |
|--------|--------|--------|
| `ai_conversations` | 8 | Threads de conversas |
| `ai_messages` | 50 | Mensagens das conversas |
| `ai_agent_config` | 3 | Config de agentes IA |
| `ai_api_keys` | 0 | Chaves de API LLM |
| `sofia_actions` | 193 | Acoes executadas pela Sofia |
| `rag_documents` | 20 | Docs para RAG (oficial?) |
| `rag_documentos` | 18 | Docs para RAG (duplicada) |

**Acao:** Consolidar `rag_documents` vs `rag_documentos`.

---

## Outras

| Tabela | Linhas | Funcao |
|--------|--------|--------|
| `oficina_config` | 1 | Config da oficina (multi-tenant) |
| `catalogo_servicos` | 3 | Catalogo de servicos |
| `pecas_encontradas` | 5 | Pecas encontradas/scraping |
| `pendencias` | 4 | Pendencias gerais |
| `recursos` | 10 | Recursos/equipamentos |
| `mecanico_feedback` | 4 | Feedback dos mecanicos |
| `os_anexos` | 0 | Anexos das OS |
| `workflow_etapas` | 10 | Etapas de workflow |
| `kv_store_0092e077` | 0 | KV store generico |

---

## Funcoes RPC importantes

| Funcao | Tipo | Descricao |
|--------|------|-----------|
| `verify_staff_login(p_username, p_password)` | record | Auth via SHA-256, retorna user de `01_colaboradores` |
| `criar_usuario_staff(...)` | jsonb / uuid | Cria novo colaborador (2 versoes existem) |
| `change_staff_password(...)` | void | Troca senha do colaborador |

**Login flow:**
1. Frontend chama `verify_staff_login`
2. RPC compara `password_hash = sha256(p_password)` em `01_colaboradores`
3. Retorna `{ok, id, nome, cargo, username, nivelAcessoId, ativo, primeiroAcesso, empresa_id}`

---

## Resumo executivo

**Total tabelas:** 52
**Tabelas em uso (oficial):** 13 numeradas + 7 outras = **20 tabelas**
**Tabelas legacy/duplicadas:** **22 tabelas** (candidatas a DROP)
**Tabelas IA/CRM/Logs:** **10 tabelas**

**Dados criticos:**
- 27 clientes em `04_CLIENTS` + 95 em `Cliente` legacy = potencialmente 122 clientes para consolidar
- 25 veiculos em `05_VEHICLES` + 126 em `Veiculo` legacy = potencialmente 151 veiculos
- 48 OS em `06_OS` + 146 em `OrdemServico` legacy = potencialmente 194 OS

**Auth:** Funciona via SHA-256 em `01_colaboradores`. RPC `verify_staff_login` esta operacional.

---

## Plano de limpeza recomendado

### Fase 1 — Auditar dados legacy
```sql
-- Verificar se ha dados unicos nas legacy que nao estao nas oficiais
SELECT COUNT(*) FROM "Cliente" WHERE id NOT IN (SELECT id::text FROM "04_CLIENTS");
SELECT COUNT(*) FROM "Veiculo" WHERE id NOT IN (SELECT id::text FROM "05_VEHICLES");
SELECT COUNT(*) FROM "OrdemServico" WHERE id NOT IN (SELECT id::text FROM "06_OS");
```

### Fase 2 — Wipe dados de teste das oficiais
```sql
TRUNCATE "07_OS_ITENS", "08_OS_HISTORICO" CASCADE;
TRUNCATE "06_OS" CASCADE;
TRUNCATE "05_VEHICLES" CASCADE;
TRUNCATE "04_CLIENTS" CASCADE;
TRUNCATE "13_PENDENCIAS", "14_RECURSOS", "15_AGENDAMENTOS", "97_RECUSAS" CASCADE;
```

### Fase 3 — Drop legacy
```sql
DROP TABLE IF EXISTS "Cliente", "Veiculo", "OrdemServico", "Mecanico", "Colaborador" CASCADE;
DROP TABLE IF EXISTS clientes, clientes_oficina, veiculos, veiculos_orfaos, mecanicos CASCADE;
DROP TABLE IF EXISTS ordens_servico, ordens_servico_itens, os_ultimate CASCADE;
DROP TABLE IF EXISTS colaboradores_portal_consultor, colaboradores_portal_dev,
                     colaboradores_portal_gestao, colaboradores_portal_mecanico CASCADE;
DROP TABLE IF EXISTS agendamento, clients_agenda, clients_selfcad, novos_cli_agenda CASCADE;
DROP TABLE IF EXISTS rag_documentos CASCADE; -- manter rag_documents
```

### Fase 4 — Criar consultor novo
```sql
INSERT INTO "01_colaboradores" (
  empresa_id, username, nome, cargo, email,
  nivel_acesso_id, password_hash, ativo, primeiro_acesso
) VALUES (
  'a0000000-0000-0000-0000-000000000001',
  'Consultor_thales',
  'Thales Oliveira',
  'Consultor',
  'thales@doctorautoprime.com',
  3,
  encode(digest('SENHA_AQUI', 'sha256'), 'hex'),
  true,
  false
);
```

---

**Status:** Mapeamento completo. Aguardando confirmacao para executar limpeza.
