# Migration 13 — Decisões de Design
**Data:** 2026-04-23
**Arquivo SQL:** `13-migration-supabase.sql`

---

## Convenções aplicadas

- `id bigserial PRIMARY KEY` — consistente com o padrão DAP4. Não usar UUID aleatório; se precisar de PK distribuída no futuro, migrar para UUIDv7.
- `timestamptz` em todos os campos de tempo — sem exceção. O schema Drizzle original usava `timestamp` (sem tz), que é anti-pattern em Postgres multi-região.
- `text` para strings — sem `varchar(n)` sem motivo. Postgres armazena `text` e `varchar` idêntico internamente; o `CHECK` de enum é mais expressivo que um tipo enumerado de banco quando os valores ainda podem evoluir.
- `snake_case` em todos os identificadores — sem aspas, sem camelCase.
- `tenant_id text NOT NULL` em todas as tabelas exceto `briefing_executivo` (que tem campo + default `'all'` para consolidado).

---

## Decisões por tabela

### campaigns
- `funil` como `CHECK` em vez de tipo ENUM: os funis podem crescer sem `ALTER TYPE`.
- `mensagem_base` nullable: campanhas sem template fixo (ex: war_room) definem mensagem por trigger externo.
- `total_leads / agendados / respostas / conversoes` como counters desnormalizados — atualizados pelo Analista. Alternativa seria calcular por JOIN com lago_leads/agendamentos, mas a leitura frequente pelo dashboard justifica o custo de manutenção.
- **Revisão necessária:** se campaigns precisar de FK para lago_leads (associar leads individuais a campanhas), criar tabela `campaign_leads` com `campaign_id + lago_lead_id` — não modelado agora por YAGNI.

### lago_leads
- `kommo_lead_id` é FK lógica, não constraint hard. Kommo é sistema externo; um DELETE em cascata quebraria o histórico de reativação.
- `temperatura` inclui `'descartavel'` além dos 3 do schema Drizzle original — alinhado com o Framework de Scoring (4 tiers: 76-100 quente, 51-75 morno, 26-50 frio, 0-25 descartavel).
- Índice parcial `idx_lago_leads_reativacao` exclui `descartavel` — o Reativador nunca toca descartáveis, então o índice é mais seletivo.
- `attack_count` é counter simples; o Reativador deve incrementar via `UPDATE lago_leads SET attack_count = attack_count + 1` — nunca subquery (race condition com concurrent workers).
- **Revisão necessária:** se um lead Kommo pode ter múltiplos registros no lago (ex: reentrou), a UNIQUE em `kommo_lead_id` foi propositalmente omitida. Adicionar se quiser unicidade: `ADD CONSTRAINT lago_leads_kommo_uq UNIQUE (tenant_id, kommo_lead_id)`.

### ana_conversas
- `messages jsonb` como array append-only: estrutura `[{role, content, ts}]`. Não normalizar em tabela separada — o volume de mensagens por lead é limitado (< 50 turnos típicos) e o acesso é sempre "pegue toda a conversa de um lead".
- Índice GIN em `messages`: opcional hoje, útil quando RAG precisar buscar por conteúdo de conversa. Tem custo de write amplification; remover se write throughput for problema.
- `lead_id` nullable: permite registrar conversas de leads ainda não mapeados internamente (só têm `lead_nome`).
- Sem `updated_at`: tabela append-only por design. A Anna nunca edita mensagens passadas.

### logs_crons
- Totalmente imutável: nenhum `updated_at`, sem triggers de update. Audit log não deve ser mutável.
- `payload jsonb` nullable: runs simples podem não ter contexto relevante para guardar.
- `error text` nullable: NULL quando `status = 'ok'`. CHECK de consistência omitido intencionalmente para não complicar inserts parciais — o cron deve garantir.
- Índice parcial em `status IN ('erro', 'partial')`: monitoramento de falhas é o caso de uso principal de leitura nessa tabela.

### qualificacoes_lead
- Tabela de histórico imutável — nunca UPDATE, sempre INSERT novo. Isso permite rastrear evolução da qualificação de um lead ao longo do tempo.
- `nota 0-100` com `classificacao A/B/C`: A = fechar hoje (score alto + urgência alta), B = nutrir, C = mover para lago. O Analista decide.
- `requer_revisao_humana bool DEFAULT false`: flag para o Sophia Hub mostrar itens que precisam de atenção manual (ticket alto, situação ambígua, veículo exótico).
- `modelo_usado text NOT NULL`: rastreabilidade de qual LLM gerou a qualificação — importante para auditoria de custo e qualidade.
- `funil` nullable: Analista pode não saber o funil ideal; campo preenchido quando há certeza.
- **Revisão necessária:** se quiser sempre ter a qualificação mais recente de um lead sem `ORDER BY`, criar uma view materializada ou uma tabela `qualificacao_atual_lead` com UPSERT.

### agendamentos_tasks
- `kommo_task_id` nullable até confirmação via webhook do Kommo — o Vigilante cria a task localmente, Kommo responde com o ID real.
- `status` inclui `no_show`: crítico para o negócio (medir taxa de no-show é um dos KPIs principais do DAP4).
- `data_hora timestamptz NOT NULL`: agendamento sem hora é inválido operacionalmente.
- Índice parcial em `data_hora WHERE status = 'confirmado'`: o Vigilante só precisa dos confirmados para enviar lembretes — índice muito seletivo.
- **Revisão necessária:** se um agendamento pode ter múltiplos serviços, criar `agendamento_servicos` (1:N). Hoje é `servico text` (campo livre).

### briefing_executivo
- `UNIQUE (periodo, tenant_id)`: garante idempotência — o cron pode rodar novamente sem duplicar (usar `INSERT ... ON CONFLICT DO UPDATE`).
- `tenant_id DEFAULT 'all'`: briefing consolidado é o padrão; Thales pode querer separação Prime/Bosch no futuro sem quebrar a query.
- Sem `updated_at`: o cron faz upsert pelo período, não precisa rastrear mudança temporal além do `created_at` do INSERT original.
- `telegram_short text NOT NULL`: forçado NOT NULL para garantir que o cron sempre produz a versão curta — evita bug silencioso onde o Telegram não recebe nada.
- **Revisão necessária:** `score_dia` hoje é calculado pelo cron. Se quiser auditoria do cálculo, adicionar `score_breakdown jsonb`.

---

## Índices — resumo das escolhas

| Tabela | Índice-chave | Justificativa |
|---|---|---|
| campaigns | `(tenant_id, status)` | Filtro principal do dashboard |
| lago_leads | `(tenant_id, score DESC)` | Ordenação do Reativador |
| lago_leads | parcial excluindo descartavel | Reativador ignora descartáveis |
| ana_conversas | GIN em messages | Busca futura por RAG |
| logs_crons | parcial em erro/partial | Monitoramento de falhas |
| qualificacoes_lead | `(tenant_id, requer_revisao_humana)` parcial | Cockpit Sophia |
| agendamentos_tasks | `(data_hora)` WHERE confirmado | Lembretes do Vigilante |

---

## Foreign keys — posição deliberada

Nenhuma FK hard para sistemas externos (Kommo). Todas as referências a `kommo_lead_id` são lógicas. Isso evita:
- Falhas de insert quando o lead ainda não foi sincronizado
- Cascades indesejados se o sync Kommo reinicializar tabelas

FK internas (ex: `lago_leads.id → ana_conversas.lead_id`) também foram mantidas como lógicas para permitir que a Anna registre conversas de leads ainda não catalogados no lago.

---

## RLS — próximos passos

As policies atuais (`USING (true)`) permitem acesso total ao service role do Supabase. Para refinar:

1. Criar role `dap_app` com acesso restrito por tenant:
   ```sql
   CREATE POLICY campaigns_tenant_isolation ON campaigns
     USING (tenant_id = current_setting('app.tenant_id', true));
   ```
2. Aplicar a mesma policy em todas as 7 tabelas.
3. O gateway Python deve setar `SET LOCAL app.tenant_id = 'prime'` no início de cada transaction.

Isso garante isolamento multi-tenant sem depender de filtro na aplicação.

---

## Pontos que precisam revisão humana antes de ir para prod

- [ ] Confirmar se `lago_leads.kommo_lead_id` deve ter UNIQUE por tenant (depende se um lead Kommo pode reentrar no lago)
- [ ] Confirmar nomes de tenant: `'prime'` e `'bosch'` ou `'DOCTOR_PRIME'` e `'BOSCH'` — deve ser consistente com `config/tenants/dap.yaml`
- [ ] `briefing_executivo.tenant_id DEFAULT 'all'` — OK se Thales quer consolidado. Mudar para `NOT NULL` sem default se quiser forçar separação.
- [ ] Decidir se `ana_conversas` deve ter FK hard para `lago_leads(id)` ou permanecer lógica
- [ ] Score breakdown em `briefing_executivo` — adicionar `score_breakdown jsonb` se quiser auditoria do cálculo de `score_dia`
