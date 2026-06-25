-- =============================================================================
-- 03_create_oficina_schema.sql
-- =============================================================================
-- Source of truth: schema-postgres.ts (Drizzle pg-core, 13 tables, 10 pgEnums)
-- Target schema  : oficina
-- Targets        :
--   PROD     acuufrgoyjwzlyhopaus (DOCTOR PRIME, us-west-2)
--   SANDBOX  cpzgtfblywexqglqkgbt (DAP4.0 test, us-east-1)
-- Convention     : service_role full access only (defense in depth).
--                  No grants to anon/authenticated. dap-operacao server-side
--                  uses service_role.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Schema
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS oficina;

-- -----------------------------------------------------------------------------
-- 2. Enums (10 total)
-- -----------------------------------------------------------------------------
CREATE TYPE oficina.mechanic_level AS ENUM ('junior','pleno','senior','especialista');
CREATE TYPE oficina.service_order_status AS ENUM ('diagnostico','aguardando_aprovacao','aprovado','em_execucao','aguardando_peca','pronto','entregue','cancelado');
CREATE TYPE oficina.service_item_type AS ENUM ('servico','peca','mao_de_obra');
CREATE TYPE oficina.service_item_complexity AS ENUM ('baixo','medio','alto');
CREATE TYPE oficina.service_item_status AS ENUM ('pendente','aprovado','recusado');
CREATE TYPE oficina.customer_tier AS ENUM ('bronze','prata','ouro','platina');
CREATE TYPE oficina.appointment_status AS ENUM ('agendado','confirmado','cancelado','concluido');
CREATE TYPE oficina.comment_category AS ENUM ('observacao','status_change','system');
CREATE TYPE oficina.payment_status AS ENUM ('pendente','pago','estornado');
CREATE TYPE oficina.user_role AS ENUM ('admin','consultor','recepcao','mecanico');

-- -----------------------------------------------------------------------------
-- 3. Tables (13 total) -- ordered by FK dependency
-- -----------------------------------------------------------------------------

-- 3.1 organizations (root)
CREATE TABLE oficina.organizations (
  id          serial PRIMARY KEY,
  slug        text NOT NULL UNIQUE,
  name        text NOT NULL,
  created_at  timestamptz NOT NULL
);

-- 3.2 users
CREATE TABLE oficina.users (
  id              serial PRIMARY KEY,
  organization_id integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  username        text NOT NULL,
  password        text NOT NULL,
  name            text NOT NULL,
  role            oficina.user_role NOT NULL DEFAULT 'recepcao'
);

-- 3.3 customers
CREATE TABLE oficina.customers (
  id              serial PRIMARY KEY,
  organization_id integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  name            text NOT NULL,
  email           text,
  phone           text NOT NULL,
  cpf             text,
  notes           text,
  tier            oficina.customer_tier DEFAULT 'bronze'
);

-- 3.4 vehicles
CREATE TABLE oficina.vehicles (
  id              serial PRIMARY KEY,
  organization_id integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  customer_id     integer NOT NULL REFERENCES oficina.customers(id) ON DELETE CASCADE,
  plate           text NOT NULL,
  brand           text NOT NULL,
  model           text NOT NULL,
  year            integer,
  color           text,
  vin             text,
  km              integer
);

-- 3.5 mechanics
CREATE TABLE oficina.mechanics (
  id              serial PRIMARY KEY,
  organization_id integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  name            text NOT NULL,
  specialty       text,
  level           oficina.mechanic_level DEFAULT 'pleno',
  phone           text,
  active          boolean DEFAULT true
);

-- 3.6 service_orders (depends on customers, vehicles, mechanics, users)
CREATE TABLE oficina.service_orders (
  id                serial PRIMARY KEY,
  organization_id   integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  customer_id       integer NOT NULL REFERENCES oficina.customers(id) ON DELETE RESTRICT,
  vehicle_id        integer NOT NULL REFERENCES oficina.vehicles(id)  ON DELETE RESTRICT,
  technician_id     integer REFERENCES oficina.mechanics(id) ON DELETE SET NULL,
  consultant_id     integer REFERENCES oficina.users(id)     ON DELETE SET NULL,
  status            oficina.service_order_status NOT NULL DEFAULT 'diagnostico',
  reason            text,
  service_type      text,
  description       text NOT NULL,
  diagnosis         text,
  diagnostic_notes  text,
  estimated_cost    integer,
  final_cost        integer,
  advance_payment   integer,
  created_at        timestamptz NOT NULL,
  updated_at        timestamptz NOT NULL
);

-- 3.7 service_items
CREATE TABLE oficina.service_items (
  id                serial PRIMARY KEY,
  organization_id   integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  service_order_id  integer NOT NULL REFERENCES oficina.service_orders(id) ON DELETE CASCADE,
  description       text NOT NULL,
  quantity          integer NOT NULL DEFAULT 1,
  unit_price        integer NOT NULL DEFAULT 0,
  cost              integer,
  type              oficina.service_item_type NOT NULL DEFAULT 'servico',
  complexity        oficina.service_item_complexity DEFAULT 'medio',
  status            oficina.service_item_status NOT NULL DEFAULT 'pendente'
);

-- 3.8 service_order_comments
CREATE TABLE oficina.service_order_comments (
  id                serial PRIMARY KEY,
  organization_id   integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  service_order_id  integer NOT NULL REFERENCES oficina.service_orders(id) ON DELETE CASCADE,
  user_id           integer REFERENCES oficina.users(id) ON DELETE SET NULL,
  text              text NOT NULL,
  category          oficina.comment_category DEFAULT 'observacao',
  created_at        timestamptz NOT NULL
);

-- 3.9 service_order_attachments
CREATE TABLE oficina.service_order_attachments (
  id                serial PRIMARY KEY,
  organization_id   integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  service_order_id  integer NOT NULL REFERENCES oficina.service_orders(id) ON DELETE CASCADE,
  kind              text NOT NULL,
  filename          text NOT NULL,
  url               text NOT NULL,
  size_bytes        integer,
  uploaded_by       integer REFERENCES oficina.users(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL
);

-- 3.10 appointments
CREATE TABLE oficina.appointments (
  id              serial PRIMARY KEY,
  organization_id integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  customer_id     integer NOT NULL REFERENCES oficina.customers(id)    ON DELETE CASCADE,
  vehicle_id      integer REFERENCES oficina.vehicles(id)  ON DELETE SET NULL,
  mechanic_id     integer REFERENCES oficina.mechanics(id) ON DELETE SET NULL,
  date            text NOT NULL,
  time            text NOT NULL,
  reason          text,
  status          oficina.appointment_status DEFAULT 'agendado',
  notes           text
);

-- 3.11 checklists
CREATE TABLE oficina.checklists (
  id                serial PRIMARY KEY,
  organization_id   integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  service_order_id  integer NOT NULL REFERENCES oficina.service_orders(id) ON DELETE CASCADE,
  mechanic_id       integer REFERENCES oficina.mechanics(id) ON DELETE SET NULL,
  seat_cover        boolean DEFAULT false,
  steering_cover    boolean DEFAULT false,
  floor_mat         boolean DEFAULT false,
  fender_protector  boolean DEFAULT false,
  entry_km          integer,
  fuel_level        text,
  damages           text,
  notes             text,
  created_at        timestamptz
);

-- 3.12 telemetry
CREATE TABLE oficina.telemetry (
  id                serial PRIMARY KEY,
  organization_id   integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  service_order_id  integer NOT NULL REFERENCES oficina.service_orders(id) ON DELETE CASCADE,
  previous_status   text,
  new_status        text NOT NULL,
  changed_by        integer REFERENCES oficina.users(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL
);

-- 3.13 payments
CREATE TABLE oficina.payments (
  id                serial PRIMARY KEY,
  organization_id   integer NOT NULL REFERENCES oficina.organizations(id) ON DELETE CASCADE,
  service_order_id  integer NOT NULL REFERENCES oficina.service_orders(id) ON DELETE CASCADE,
  amount            integer NOT NULL,
  method            text NOT NULL,
  status            oficina.payment_status DEFAULT 'pendente',
  paid_at           timestamptz,
  notes             text
);

-- -----------------------------------------------------------------------------
-- 4. Indexes (non-PK)
-- -----------------------------------------------------------------------------

-- users
CREATE UNIQUE INDEX idx_users_org_username ON oficina.users (organization_id, username);
CREATE INDEX idx_users_organization_id ON oficina.users (organization_id);

-- customers
CREATE INDEX idx_customers_organization_id ON oficina.customers (organization_id);
CREATE INDEX idx_customers_cpf ON oficina.customers (cpf);

-- vehicles
CREATE INDEX idx_vehicles_organization_id ON oficina.vehicles (organization_id);
CREATE INDEX idx_vehicles_customer_id ON oficina.vehicles (customer_id);

-- mechanics
CREATE INDEX idx_mechanics_organization_id ON oficina.mechanics (organization_id);

-- service_orders
CREATE INDEX idx_service_orders_organization_id ON oficina.service_orders (organization_id);
CREATE INDEX idx_service_orders_customer_id     ON oficina.service_orders (customer_id);
CREATE INDEX idx_service_orders_vehicle_id      ON oficina.service_orders (vehicle_id);
CREATE INDEX idx_service_orders_technician_id   ON oficina.service_orders (technician_id);
CREATE INDEX idx_service_orders_consultant_id   ON oficina.service_orders (consultant_id);

-- service_items
CREATE INDEX idx_service_items_organization_id  ON oficina.service_items (organization_id);
CREATE INDEX idx_service_items_service_order_id ON oficina.service_items (service_order_id);

-- service_order_comments
CREATE INDEX idx_service_order_comments_organization_id  ON oficina.service_order_comments (organization_id);
CREATE INDEX idx_service_order_comments_service_order_id ON oficina.service_order_comments (service_order_id);
CREATE INDEX idx_service_order_comments_user_id          ON oficina.service_order_comments (user_id);

-- service_order_attachments
CREATE INDEX idx_service_order_attachments_organization_id  ON oficina.service_order_attachments (organization_id);
CREATE INDEX idx_service_order_attachments_service_order_id ON oficina.service_order_attachments (service_order_id);
CREATE INDEX idx_service_order_attachments_uploaded_by      ON oficina.service_order_attachments (uploaded_by);

-- appointments
CREATE INDEX idx_appointments_organization_id ON oficina.appointments (organization_id);
CREATE INDEX idx_appointments_customer_id     ON oficina.appointments (customer_id);
CREATE INDEX idx_appointments_vehicle_id      ON oficina.appointments (vehicle_id);
CREATE INDEX idx_appointments_mechanic_id     ON oficina.appointments (mechanic_id);

-- checklists
CREATE INDEX idx_checklists_organization_id  ON oficina.checklists (organization_id);
CREATE INDEX idx_checklists_service_order_id ON oficina.checklists (service_order_id);
CREATE INDEX idx_checklists_mechanic_id      ON oficina.checklists (mechanic_id);

-- telemetry
CREATE INDEX idx_telemetry_organization_id  ON oficina.telemetry (organization_id);
CREATE INDEX idx_telemetry_service_order_id ON oficina.telemetry (service_order_id);
CREATE INDEX idx_telemetry_changed_by       ON oficina.telemetry (changed_by);

-- payments
CREATE INDEX idx_payments_organization_id  ON oficina.payments (organization_id);
CREATE INDEX idx_payments_service_order_id ON oficina.payments (service_order_id);

-- -----------------------------------------------------------------------------
-- 5. RLS enable + service_role policy (one per table)
-- -----------------------------------------------------------------------------
ALTER TABLE oficina.organizations            ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.users                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.customers                ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.vehicles                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.mechanics                ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.service_orders           ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.service_items            ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.service_order_comments   ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.service_order_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.appointments             ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.checklists               ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.telemetry                ENABLE ROW LEVEL SECURITY;
ALTER TABLE oficina.payments                 ENABLE ROW LEVEL SECURITY;

CREATE POLICY service_role_all ON oficina.organizations            FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.users                    FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.customers                FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.vehicles                 FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.mechanics                FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.service_orders           FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.service_items            FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.service_order_comments   FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.service_order_attachments FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.appointments             FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.checklists               FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.telemetry                FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_all ON oficina.payments                 FOR ALL TO service_role USING (true) WITH CHECK (true);

-- -----------------------------------------------------------------------------
-- 6. Grants (service_role only)
-- -----------------------------------------------------------------------------
GRANT USAGE ON SCHEMA oficina TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA oficina TO service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA oficina TO service_role;

-- =============================================================================
-- END
-- =============================================================================
