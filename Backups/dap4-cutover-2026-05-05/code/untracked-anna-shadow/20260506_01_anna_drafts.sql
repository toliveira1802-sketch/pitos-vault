-- Migration: 20260506_01_anna_drafts
-- Anna shadow mode — chairman approval queue antes do envio Meta WhatsApp.
-- Plug em gateway/src/routes/meta-webhook.routes.ts onde hoje envia direto.
--
-- Modos por brand:
--   shadow              → toda resposta da Anna vira draft pendente
--   copilot             → drafts só pra intents sensíveis (pricing/scheduling/objection)
--   autonomous_supervised → envia direto, mas registra trace pra dashboard
--   autonomous_full     → envia direto sem trace adicional (modo legacy)
--
-- Idempotente (IF NOT EXISTS / CREATE OR REPLACE / DO NOTHING).

BEGIN;

-- ============================================================================
-- 1. anna_drafts — fila de aprovação do chairman
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.anna_drafts (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           TEXT NOT NULL DEFAULT 'dap_prime',
  brand_id            TEXT NOT NULL,
  conversation_id     TEXT NOT NULL,           -- meta_conversations.id ou phone-derived
  inbound_message_id  TEXT,                    -- meta wa msg id que originou
  client_phone        TEXT NOT NULL,
  client_name         TEXT,

  -- Anna gerou
  anna_text_original  TEXT NOT NULL,
  anna_intent         TEXT,                    -- intent classificada (question/objection/...)
  anna_signals        JSONB,                   -- recommended_next, confidence, escalation_reason
  anna_model          TEXT,                    -- gpt-4o-mini etc
  anna_tokens_in      INT,
  anna_tokens_out     INT,

  -- Chairman intervém
  status              TEXT NOT NULL DEFAULT 'pending_review'
                      CHECK (status IN (
                        'pending_review',
                        'approved',
                        'edited',
                        'rejected',
                        'sent',
                        'send_failed',
                        'expired'
                      )),
  reviewer_user_id    BIGINT,
  text_final          TEXT,                    -- preenchido se approved/edited
  reject_reason       TEXT,                    -- preenchido se rejected
  reviewed_at         TIMESTAMPTZ,

  -- Envio
  sent_at             TIMESTAMPTZ,
  sent_message_id     TEXT,                    -- meta wa msg id retornado
  send_error          TEXT,

  -- Janela Meta de 24h pra responder; expira automático após
  expires_at          TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '24 hours'),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_anna_drafts_pending
  ON public.anna_drafts (created_at DESC)
  WHERE status = 'pending_review';

CREATE INDEX IF NOT EXISTS idx_anna_drafts_brand_status
  ON public.anna_drafts (brand_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_anna_drafts_conversation
  ON public.anna_drafts (conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_anna_drafts_expires
  ON public.anna_drafts (expires_at)
  WHERE status = 'pending_review';

-- updated_at touch trigger
CREATE OR REPLACE FUNCTION public.anna_drafts_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_anna_drafts_touch ON public.anna_drafts;
CREATE TRIGGER trg_anna_drafts_touch
  BEFORE UPDATE ON public.anna_drafts
  FOR EACH ROW EXECUTE FUNCTION public.anna_drafts_touch_updated_at();

-- LISTEN/NOTIFY pra dashboard receber draft novo em real-time
CREATE OR REPLACE FUNCTION public.anna_drafts_notify()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'pending_review' THEN
    PERFORM pg_notify(
      'anna_draft_new',
      json_build_object(
        'draftId', NEW.id,
        'brandId', NEW.brand_id,
        'tenantId', NEW.tenant_id,
        'clientPhone', NEW.client_phone,
        'clientName', NEW.client_name
      )::text
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_anna_drafts_notify ON public.anna_drafts;
CREATE TRIGGER trg_anna_drafts_notify
  AFTER INSERT ON public.anna_drafts
  FOR EACH ROW EXECUTE FUNCTION public.anna_drafts_notify();

-- ============================================================================
-- 2. anna_brand_config — modo de operação por brand
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.anna_brand_config (
  brand_id            TEXT PRIMARY KEY,
  mode                TEXT NOT NULL DEFAULT 'shadow'
                      CHECK (mode IN (
                        'shadow',
                        'copilot',
                        'autonomous_supervised',
                        'autonomous_full'
                      )),
  copilot_escalate    JSONB NOT NULL DEFAULT '["pricing","scheduling","objection"]'::jsonb,
  -- Em copilot, intents listados aqui SEMPRE viram draft. Outros vão direto.
  notes               TEXT,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.anna_brand_config (brand_id, mode, notes) VALUES
  ('dap_prime', 'shadow', 'R6 — primeira rodada Sombra'),
  ('dap_bosch', 'shadow', 'R6 — primeira rodada Sombra')
ON CONFLICT (brand_id) DO NOTHING;

-- ============================================================================
-- 3. RLS — tenant isolation (mesmo padrão do anna_kommo_schema)
-- ============================================================================
ALTER TABLE public.anna_drafts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation ON public.anna_drafts;
CREATE POLICY tenant_isolation ON public.anna_drafts
  USING (
    current_setting('app.current_tenant', true) IS NOT NULL
    AND current_setting('app.current_tenant', true) <> ''
    AND tenant_id = current_setting('app.current_tenant', true)
  );

-- anna_brand_config é global por config, não tenant-scoped (mas só admin escreve via service role)
ALTER TABLE public.anna_brand_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS read_all ON public.anna_brand_config;
CREATE POLICY read_all ON public.anna_brand_config FOR SELECT USING (true);

-- Service role bypasses RLS; backend keeps full read/write.

COMMIT;
