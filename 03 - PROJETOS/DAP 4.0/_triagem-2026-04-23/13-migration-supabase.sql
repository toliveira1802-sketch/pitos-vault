-- =============================================================================
-- DAP4.0 — Migration: Tabelas dos 4 Crons (Vigilante, Analista, Reativador, Relatório)
-- Criado em: 2026-04-23
-- Supabase / PostgreSQL puro — sem dependência de Drizzle
-- Convenção: snake_case, bigserial PK, timestamptz, tenant_id text
-- RLS: habilitado com policy "service role passa tudo" — refinar depois
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CAMPAIGNS
-- Campanhas de ataque por funil. Criadas pelo Analista, executadas pela Anna.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS campaigns (
    id            bigserial PRIMARY KEY,
    tenant_id     text        NOT NULL,                          -- 'prime' | 'bosch'
    name          text        NOT NULL,
    type          text        NOT NULL,                          -- ex: 'whatsapp_blast', 'reativacao', 'pos_venda'
    status        text        NOT NULL DEFAULT 'ativa'
                              CHECK (status IN ('ativa', 'pausada', 'finalizada')),
    funil         text        NOT NULL DEFAULT 'geral'
                              CHECK (funil IN ('isca', 'upsell', 'projeto', 'pos_venda', 'war_room', 'geral')),
    mensagem_base text,                                          -- template base; NULL = definido por trigger
    total_leads   integer     NOT NULL DEFAULT 0,
    agendados     integer     NOT NULL DEFAULT 0,
    respostas     integer     NOT NULL DEFAULT 0,
    conversoes    integer     NOT NULL DEFAULT 0,
    started_at    timestamptz,
    ended_at      timestamptz,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  campaigns              IS 'Campanhas de ataque comercial por funil e tenant';
COMMENT ON COLUMN campaigns.funil        IS 'isca=topo | upsell=ticket+ | projeto=build | pos_venda=NPS/fidelizacao | war_room=emergencial | geral=sem classificacao';
COMMENT ON COLUMN campaigns.total_leads  IS 'Total de leads elegíveis no momento da criação';

CREATE INDEX idx_campaigns_tenant_status   ON campaigns (tenant_id, status);
CREATE INDEX idx_campaigns_tenant_funil    ON campaigns (tenant_id, funil);
CREATE INDEX idx_campaigns_started_at      ON campaigns (started_at DESC) WHERE started_at IS NOT NULL;

ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
CREATE POLICY campaigns_service_all ON campaigns USING (true) WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 2. LAGO_LEADS
-- Leads frios/inativos fora do pipeline ativo. Alimentados pelo Vigilante.
-- Scoring 0-100 com 4 tiers: quente/morno/frio/descartavel.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lago_leads (
    id               bigserial PRIMARY KEY,
    tenant_id        text        NOT NULL,
    kommo_lead_id    bigint,                                     -- FK lógica — sem constraint hard (Kommo é externo)
    name             text        NOT NULL,
    phone            text,
    email            text,
    vehicle          text,
    temperatura      text        NOT NULL DEFAULT 'frio'
                                 CHECK (temperatura IN ('quente', 'morno', 'frio', 'descartavel')),
    score            integer     NOT NULL DEFAULT 0
                                 CHECK (score >= 0 AND score <= 100),
    reason           text,                                       -- justificativa do score (curta, 1 linha)
    source           text,                                       -- 'kommo' | 'whatsapp' | 'manual' | ...
    notes            text,
    last_attack_at   timestamptz,                                -- último contato/tentativa de reativação
    attack_count     integer     NOT NULL DEFAULT 0,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  lago_leads              IS 'Leads inativos com scoring 0-100 e 4 tiers de temperatura';
COMMENT ON COLUMN lago_leads.score        IS '0-100: quente=76-100, morno=51-75, frio=26-50, descartavel=0-25';
COMMENT ON COLUMN lago_leads.attack_count IS 'Número de vezes que o Reativador tentou contato';

CREATE INDEX idx_lago_leads_tenant_temp     ON lago_leads (tenant_id, temperatura);
CREATE INDEX idx_lago_leads_tenant_score    ON lago_leads (tenant_id, score DESC);
CREATE INDEX idx_lago_leads_kommo_id        ON lago_leads (kommo_lead_id) WHERE kommo_lead_id IS NOT NULL;
CREATE INDEX idx_lago_leads_last_attack     ON lago_leads (last_attack_at DESC) WHERE last_attack_at IS NOT NULL;
-- Índice parcial: candidatos ativos para reativação (exclui descartáveis)
CREATE INDEX idx_lago_leads_reativacao      ON lago_leads (tenant_id, score DESC)
    WHERE temperatura IN ('quente', 'morno', 'frio');

ALTER TABLE lago_leads ENABLE ROW LEVEL SECURITY;
CREATE POLICY lago_leads_service_all ON lago_leads USING (true) WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 3. ANA_CONVERSAS
-- Histórico de conversas da Anna com leads. Append-only por design.
-- Alimentada pelo gateway a cada turno. Token count para controle de custo.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ana_conversas (
    id           bigserial PRIMARY KEY,
    tenant_id    text        NOT NULL,
    lead_id      bigint,                                         -- referência interna (lago_leads.id ou leads.id)
    lead_nome    text        NOT NULL,
    messages     jsonb       NOT NULL DEFAULT '[]'::jsonb,       -- array de {role, content, ts}
    token_count  integer     NOT NULL DEFAULT 0,
    last_turn_at timestamptz NOT NULL DEFAULT now(),
    created_at   timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  ana_conversas             IS 'Histórico completo de conversas da Anna por lead';
COMMENT ON COLUMN ana_conversas.messages    IS 'Array JSONB: [{role: "user"|"assistant"|"system", content: text, ts: iso8601}]';
COMMENT ON COLUMN ana_conversas.token_count IS 'Total de tokens acumulados na conversa (para billing)';

CREATE INDEX idx_ana_conversas_tenant_lead   ON ana_conversas (tenant_id, lead_id);
CREATE INDEX idx_ana_conversas_last_turn     ON ana_conversas (last_turn_at DESC);
-- GIN no JSONB para buscas por conteúdo (opcional, mas útil para RAG futuro)
CREATE INDEX idx_ana_conversas_messages_gin  ON ana_conversas USING gin (messages);

ALTER TABLE ana_conversas ENABLE ROW LEVEL SECURITY;
CREATE POLICY ana_conversas_service_all ON ana_conversas USING (true) WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 4. LOGS_CRONS
-- Audit log de todas as execuções dos 4 crons. Imutável após INSERT.
-- Vigilante / Analista / Reativador / Relatorio — um registro por run.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS logs_crons (
    id             bigserial PRIMARY KEY,
    cron_name      text        NOT NULL
                               CHECK (cron_name IN ('vigilante', 'analista', 'reativador', 'relatorio')),
    tenant_id      text        NOT NULL,
    status         text        NOT NULL
                               CHECK (status IN ('ok', 'erro', 'partial')),
    items_scanned  integer     NOT NULL DEFAULT 0,
    items_acted    integer     NOT NULL DEFAULT 0,
    payload        jsonb,                                        -- contexto de entrada do run
    error          text,                                         -- NULL se status='ok'
    duration_ms    integer,                                      -- tempo de execução em ms
    executed_at    timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  logs_crons           IS 'Audit log imutável de cada execução dos 4 crons por tenant';
COMMENT ON COLUMN logs_crons.payload   IS 'Snapshot de entrada: leads processados, parâmetros, etc.';
COMMENT ON COLUMN logs_crons.error     IS 'Stack trace ou mensagem; NULL quando status=ok';

CREATE INDEX idx_logs_crons_tenant_name   ON logs_crons (tenant_id, cron_name);
CREATE INDEX idx_logs_crons_executed_at   ON logs_crons (executed_at DESC);
CREATE INDEX idx_logs_crons_status        ON logs_crons (cron_name, status) WHERE status IN ('erro', 'partial');

ALTER TABLE logs_crons ENABLE ROW LEVEL SECURITY;
CREATE POLICY logs_crons_service_all ON logs_crons USING (true) WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 5. QUALIFICACOES_LEAD
-- Qualificação estruturada gerada pelo Analista (IA). Uma por lead por ciclo.
-- Histórico mantido — não faz UPDATE, faz INSERT novo com timestamp.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS qualificacoes_lead (
    id                       bigserial PRIMARY KEY,
    tenant_id                text        NOT NULL,
    kommo_lead_id            bigint      NOT NULL,
    nota                     integer     NOT NULL
                                         CHECK (nota >= 0 AND nota <= 100),
    classificacao            text        NOT NULL
                                         CHECK (classificacao IN ('A', 'B', 'C')),
    funil                    text,                               -- funil sugerido pelo Analista
    urgencia                 text        NOT NULL
                                         CHECK (urgencia IN ('alta', 'media', 'baixa')),
    potencial_ticket         text        NOT NULL
                                         CHECK (potencial_ticket IN ('alto', 'medio', 'baixo')),
    justificativa            text        NOT NULL,               -- raciocínio da IA, 2-4 linhas
    modelo_usado             text        NOT NULL,               -- ex: 'gpt-4o-mini', 'claude-3-5-haiku'
    qualificado_em           timestamptz NOT NULL DEFAULT now(),
    requer_revisao_humana    boolean     NOT NULL DEFAULT false,
    created_at               timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  qualificacoes_lead                    IS 'Qualificação IA por lead — histórico imutável, nova linha por ciclo';
COMMENT ON COLUMN qualificacoes_lead.classificacao      IS 'A=fechar hoje | B=nutrir | C=lago';
COMMENT ON COLUMN qualificacoes_lead.requer_revisao_humana IS 'TRUE quando a IA detecta ambiguidade ou ticket alto';

CREATE INDEX idx_qual_tenant_kommo         ON qualificacoes_lead (tenant_id, kommo_lead_id);
CREATE INDEX idx_qual_tenant_class         ON qualificacoes_lead (tenant_id, classificacao);
CREATE INDEX idx_qual_revisao              ON qualificacoes_lead (tenant_id, requer_revisao_humana)
    WHERE requer_revisao_humana = true;
CREATE INDEX idx_qual_qualificado_em       ON qualificacoes_lead (qualificado_em DESC);

ALTER TABLE qualificacoes_lead ENABLE ROW LEVEL SECURITY;
CREATE POLICY qualificacoes_lead_service_all ON qualificacoes_lead USING (true) WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 6. AGENDAMENTOS_TASKS
-- Tasks de agendamento criadas/atualizadas pelo Vigilante no Kommo.
-- Rastreia o ciclo de vida da task: criada → confirmada → executada.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agendamentos_tasks (
    id              bigserial PRIMARY KEY,
    tenant_id       text        NOT NULL,
    kommo_lead_id   bigint      NOT NULL,
    kommo_task_id   bigint,                                      -- NULL até confirmação do Kommo
    acao            text        NOT NULL
                                CHECK (acao IN ('marcar', 'reagendar', 'cancelar', 'lembrete', 'ritual_entrega')),
    data_hora       timestamptz NOT NULL,
    unidade         text        NOT NULL
                                CHECK (unidade IN ('prime', 'bosch')),
    servico         text,
    responsavel     text,
    status          text        NOT NULL DEFAULT 'pendente'
                                CHECK (status IN ('pendente', 'confirmado', 'executado', 'cancelado', 'no_show')),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  agendamentos_tasks            IS 'Tasks de agendamento sincronizadas com Kommo pelo Vigilante';
COMMENT ON COLUMN agendamentos_tasks.acao       IS 'marcar=novo | reagendar=rescheduled | ritual_entrega=delivery flow';
COMMENT ON COLUMN agendamentos_tasks.kommo_task_id IS 'ID da task no Kommo; NULL enquanto pendente de confirmação';

CREATE INDEX idx_agend_tenant_status    ON agendamentos_tasks (tenant_id, status);
CREATE INDEX idx_agend_kommo_lead       ON agendamentos_tasks (kommo_lead_id);
CREATE INDEX idx_agend_data_hora        ON agendamentos_tasks (data_hora) WHERE status = 'confirmado';
CREATE INDEX idx_agend_kommo_task       ON agendamentos_tasks (kommo_task_id) WHERE kommo_task_id IS NOT NULL;

ALTER TABLE agendamentos_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY agendamentos_tasks_service_all ON agendamentos_tasks USING (true) WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 7. BRIEFING_EXECUTIVO
-- Relatório diário gerado pelo cron Relatório Executivo.
-- Um registro por dia por tenant. Sem tenant_id pois é consolidado (multi-tenant
-- no markdown_full). Revisitar se Bosch/Prime precisarem separação.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS briefing_executivo (
    id                    bigserial PRIMARY KEY,
    periodo               date        NOT NULL,                  -- data de referência do briefing
    tenant_id             text        NOT NULL DEFAULT 'all',   -- 'all' = consolidado, ou 'prime'/'bosch'
    score_dia             integer     NOT NULL DEFAULT 0
                                      CHECK (score_dia >= 0 AND score_dia <= 100),
    alavancas             jsonb,                                 -- [{titulo, descricao, impacto}]
    gargalos              jsonb,                                 -- [{titulo, descricao, severidade}]
    decisoes_pendentes    jsonb,                                 -- [{decisao, deadline, owner}]
    proximas_24h          jsonb,                                 -- [{acao, responsavel, prazo}]
    markdown_full         text        NOT NULL,                  -- briefing completo para UI / RAG
    telegram_short        text        NOT NULL,                  -- versão curta para Telegram (<1500 chars)
    created_at            timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT briefing_executivo_periodo_tenant_uq UNIQUE (periodo, tenant_id)
);

COMMENT ON TABLE  briefing_executivo              IS 'Relatório executivo diário gerado pelo cron Relatorio';
COMMENT ON COLUMN briefing_executivo.score_dia    IS 'Score 0-100 de saúde do dia (composto: leads, agendamentos, conversões)';
COMMENT ON COLUMN briefing_executivo.alavancas    IS 'Oportunidades identificadas no dia com impacto estimado';
COMMENT ON COLUMN briefing_executivo.gargalos     IS 'Problemas detectados com severidade alta/media/baixa';
COMMENT ON COLUMN briefing_executivo.telegram_short IS 'Resumo formatado para envio via Bot Telegram ao Thales';

CREATE INDEX idx_briefing_periodo      ON briefing_executivo (periodo DESC);
CREATE INDEX idx_briefing_tenant       ON briefing_executivo (tenant_id, periodo DESC);

ALTER TABLE briefing_executivo ENABLE ROW LEVEL SECURITY;
CREATE POLICY briefing_executivo_service_all ON briefing_executivo USING (true) WITH CHECK (true);


-- =============================================================================
-- TRIGGER: updated_at automático para tabelas com coluna updated_at
-- Reutilizável — cria a função uma vez, aplica via trigger.
-- =============================================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER campaigns_updated_at
    BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER lago_leads_updated_at
    BEFORE UPDATE ON lago_leads
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER agendamentos_tasks_updated_at
    BEFORE UPDATE ON agendamentos_tasks
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ana_conversas e logs_crons são append-only — sem trigger de updated_at.
-- qualificacoes_lead é append-only — sem trigger.
-- briefing_executivo: updated_at não existe intencionalmente (UNIQUE periodo+tenant basta).

-- =============================================================================
-- FIM DA MIGRATION
-- =============================================================================
