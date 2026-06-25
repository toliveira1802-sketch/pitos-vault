// schema-postgres.ts
// Drizzle ORM -- PostgreSQL (Supabase) equivalent of dap-operacao/shared/schema.ts
//
// Conversion map (SQLite -> Postgres):
//   integer().primaryKey({autoIncrement:true}) -> serial().primaryKey()
//   text() ISO date strings                    -> timestamp({withTimezone:true})
//   integer 0/1 booleans (active, seat_cover etc) -> boolean
//   text enum columns (closed domains)            -> pgEnum
//   Money columns (integer cents)                 -> integer, unchanged
//   All FK onDelete semantics preserved 1:1
//
// Required: npm install postgres
// drizzle.config.ts: change dialect sqlite->postgresql, update dbCredentials

import {
  pgTable, pgEnum, serial, integer, text, boolean,
  index, uniqueIndex, timestamp,
} from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

// ---- pgEnums ---------------------------------------------------------------
export const mechanicLevelEnum = pgEnum("mechanic_level", [
  "junior", "pleno", "senior", "especialista",
]);

export const serviceOrderStatusEnum = pgEnum("service_order_status", [
  "diagnostico", "aguardando_aprovacao", "aprovado", "em_execucao", "aguardando_peca", "pronto", "entregue", "cancelado",
]);

export const serviceItemTypeEnum = pgEnum("service_item_type", [
  "servico", "peca", "mao_de_obra",
]);

export const serviceItemComplexityEnum = pgEnum("service_item_complexity", [
  "baixo", "medio", "alto",
]);

export const serviceItemStatusEnum = pgEnum("service_item_status", [
  "pendente", "aprovado", "recusado",
]);

export const customerTierEnum = pgEnum("customer_tier", [
  "bronze", "prata", "ouro", "platina",
]);

export const appointmentStatusEnum = pgEnum("appointment_status", [
  "agendado", "confirmado", "cancelado", "concluido",
]);

export const commentCategoryEnum = pgEnum("comment_category", [
  "observacao", "status_change", "system",
]);

export const paymentStatusEnum = pgEnum("payment_status", [
  "pendente", "pago", "estornado",
]);

export const userRoleEnum = pgEnum("user_role", [
  "admin", "consultor", "recepcao", "mecanico",
]);

// ---- TS const arrays (kept for zod + UI) ----------------------------------

export const MECHANIC_LEVELS = ["junior", "pleno", "senior", "especialista"] as const;

export const SERVICE_ORDER_STATUSES = [
  "diagnostico", "aguardando_aprovacao", "aprovado", "em_execucao",
  "aguardando_peca", "pronto", "entregue", "cancelado",
] as const;
export type ServiceOrderStatus = (typeof SERVICE_ORDER_STATUSES)[number];

export const SERVICE_ITEM_TYPES = ["servico", "peca", "mao_de_obra"] as const;
export const SERVICE_ITEM_COMPLEXITIES = ["baixo", "medio", "alto"] as const;
export const SERVICE_ITEM_STATUSES = ["pendente", "aprovado", "recusado"] as const;

// ---- Organizations --------------------------------------------------------

export const organizations = pgTable("organizations", {
  id: serial("id").primaryKey(),
  slug: text("slug").notNull().unique(),
  name: text("name").notNull(),
  // SQLite stored ISO string -> real timestamptz. Drizzle returns JS Date on read.
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
});
export const insertOrganizationSchema = createInsertSchema(organizations).omit({ id: true });
export type InsertOrganization = z.infer<typeof insertOrganizationSchema>;
export type Organization = typeof organizations.$inferSelect;

// ---- Users ----------------------------------------------------------------

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id")
    .notNull().references(() => organizations.id, { onDelete: "cascade" }),
  username: text("username").notNull(),
  password: text("password").notNull(),
  name: text("name").notNull(),
  role: userRoleEnum("role").notNull().default("recepcao"),
}, (t) => ({
  orgUsernameUnique: uniqueIndex("idx_users_org_username").on(t.organizationId, t.username),
  orgIdx: index("idx_users_organization_id").on(t.organizationId),
}));
export const insertUserSchema = createInsertSchema(users).omit({ id: true });
export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof users.$inferSelect;

// ---- Customers ------------------------------------------------------------

export const customers = pgTable("customers", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id")
    .notNull().references(() => organizations.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  email: text("email"),
  phone: text("phone").notNull(),
  cpf: text("cpf"),
  notes: text("notes"),
  tier: customerTierEnum("tier").default("bronze"),
}, (t) => ({
  orgIdx: index("idx_customers_organization_id").on(t.organizationId),
  cpfIdx: index("idx_customers_cpf").on(t.cpf),
}));
export const insertCustomerSchema = createInsertSchema(customers).omit({ id: true });
export type InsertCustomer = z.infer<typeof insertCustomerSchema>;
export type Customer = typeof customers.$inferSelect;

// ---- Vehicles -------------------------------------------------------------

export const vehicles = pgTable("vehicles", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id")
    .notNull().references(() => organizations.id, { onDelete: "cascade" }),
  customerId: integer("customer_id")
    .notNull().references(() => customers.id, { onDelete: "cascade" }),
  plate: text("plate").notNull(),
  brand: text("brand").notNull(),
  model: text("model").notNull(),
  year: integer("year"),
  color: text("color"),
  vin: text("vin"),
  km: integer("km"),
}, (t) => ({
  orgIdx: index("idx_vehicles_organization_id").on(t.organizationId),
  customerIdx: index("idx_vehicles_customer_id").on(t.customerId),
}));
export const insertVehicleSchema = createInsertSchema(vehicles).omit({ id: true });
export type InsertVehicle = z.infer<typeof insertVehicleSchema>;
export type Vehicle = typeof vehicles.$inferSelect;

// ---- Mechanics ------------------------------------------------------------

export const mechanics = pgTable("mechanics", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id")
    .notNull().references(() => organizations.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  specialty: text("specialty"),
  level: mechanicLevelEnum("level").default("pleno"),
  phone: text("phone"),
  // SQLite 0/1 -> boolean. ETL: INSERT ... WHERE active=1 -> true, else false
  active: boolean("active").default(true),
}, (t) => ({
  orgIdx: index("idx_mechanics_organization_id").on(t.organizationId),
}));
export const insertMechanicSchema = createInsertSchema(mechanics).omit({ id: true });
export type InsertMechanic = z.infer<typeof insertMechanicSchema>;
export type Mechanic = typeof mechanics.$inferSelect;
// ---- Service Orders ------------------------------------------------------

export const serviceOrders = pgTable("service_orders", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id")
    .notNull().references(() => organizations.id, { onDelete: "cascade" }),
  customerId: integer("customer_id")
    .notNull().references(() => customers.id, { onDelete: "restrict" }),
  vehicleId: integer("vehicle_id")
    .notNull().references(() => vehicles.id, { onDelete: "restrict" }),
  technicianId: integer("technician_id").references(() => mechanics.id, { onDelete: "set null" }),
  consultantId: integer("consultant_id").references(() => users.id, { onDelete: "set null" }),
  status: serviceOrderStatusEnum("status").notNull().default("diagnostico"),
  reason: text("reason"),
  serviceType: text("service_type"),
  description: text("description").notNull(),
  diagnosis: text("diagnosis"),
  diagnosticNotes: text("diagnostic_notes"),
  estimatedCost: integer("estimated_cost"),
  finalCost: integer("final_cost"),
  advancePayment: integer("advance_payment"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
}, (t) => ({
  orgIdx: index("idx_service_orders_organization_id").on(t.organizationId),
  customerIdx: index("idx_service_orders_customer_id").on(t.customerId),
  vehicleIdx: index("idx_service_orders_vehicle_id").on(t.vehicleId),
  technicianIdx: index("idx_service_orders_technician_id").on(t.technicianId),
  consultantIdx: index("idx_service_orders_consultant_id").on(t.consultantId),
}));
export const insertServiceOrderSchema = createInsertSchema(serviceOrders).omit({ id: true });
export type InsertServiceOrder = z.infer<typeof insertServiceOrderSchema>;
export type ServiceOrder = typeof serviceOrders.$inferSelect;

// ---- Service Items --------------------------------------------------------

export const serviceItems = pgTable("service_items", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id")
    .notNull().references(() => organizations.id, { onDelete: "cascade" }),
  serviceOrderId: integer("service_order_id")
    .notNull().references(() => serviceOrders.id, { onDelete: "cascade" }),
  description: text("description").notNull(),
  quantity: integer("quantity").notNull().default(1),
  unitPrice: integer("unit_price").notNull().default(0),
  cost: integer("cost"),
  type: serviceItemTypeEnum("type").notNull().default("servico"),
  complexity: serviceItemComplexityEnum("complexity").default("medio"),
  status: serviceItemStatusEnum("status").notNull().default("pendente"),
}, (t) => ({
  orgIdx: index("idx_service_items_organization_id").on(t.organizationId),
  serviceOrderIdx: index("idx_service_items_service_order_id").on(t.serviceOrderId),
}));
export const insertServiceItemSchema = createInsertSchema(serviceItems).omit({ id: true });
export type InsertServiceItem = z.infer<typeof insertServiceItemSchema>;
export type ServiceItem = typeof serviceItems.$inferSelect;

// ---- Service Order Comments -----------------------------------------------

export const serviceOrderComments = pgTable("service_order_comments", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id")
    .notNull().references(() => organizations.id, { onDelete: "cascade" }),
  serviceOrderId: integer("service_order_id")
    .notNull().references(() => serviceOrders.id, { onDelete: "cascade" }),
  userId: integer("user_id").references(() => users.id, { onDelete: "set null" }),
  text: text("text").notNull(),
  category: commentCategoryEnum("category").default("observacao"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
}, (t) => ({
  orgIdx: index("idx_service_order_comments_organization_id").on(t.organizationId),
  serviceOrderIdx: index("idx_service_order_comments_service_order_id").on(t.serviceOrderId),
  userIdx: index("idx_service_order_comments_user_id").on(t.userId),
}));
export const insertServiceOrderCommentSchema = createInsertSchema(serviceOrderComments).omit({ id: true });
export type InsertServiceOrderComment = z.infer<typeof insertServiceOrderCommentSchema>;
export type ServiceOrderComment = typeof serviceOrderComments.$inferSelect;

// ---- Service Order Attachments --------------------------------------------

export const serviceOrderAttachments = pgTable("service_order_attachments", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id")
    .notNull().references(() => organizations.id, { onDelete: "cascade" }),
  serviceOrderId: integer("service_order_id")
    .notNull().references(() => serviceOrders.id, { onDelete: "cascade" }),
  kind: text("kind").notNull(),
  filename: text("filename").notNull(),
  url: text("url").notNull(),
  sizeBytes: integer("size_bytes"),
  uploadedBy: integer("uploaded_by").references(() => users.id, { onDelete: "set null" }),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
}, (t) => ({
  orgIdx: index("idx_service_order_attachments_organization_id").on(t.organizationId),
  serviceOrderIdx: index("idx_service_order_attachments_service_order_id").on(t.serviceOrderId),
  uploadedByIdx: index("idx_service_order_attachments_uploaded_by").on(t.uploadedBy),
}));
export const insertServiceOrderAttachmentSchema = createInsertSchema(serviceOrderAttachments).omit({ id: true });
export type InsertServiceOrderAttachment = z.infer<typeof insertServiceOrderAttachmentSchema>;
export type ServiceOrderAttachment = typeof serviceOrderAttachments.$inferSelect;
// ---- Appointments ---------------------------------------------------------

export const appointments = pgTable("appointments", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id").notNull().references(() => organizations.id, { onDelete: "cascade" }),
  customerId: integer("customer_id").notNull().references(() => customers.id, { onDelete: "cascade" }),
  vehicleId: integer("vehicle_id").references(() => vehicles.id, { onDelete: "set null" }),
  mechanicId: integer("mechanic_id").references(() => mechanics.id, { onDelete: "set null" }),
  date: text("date").notNull(),
  time: text("time").notNull(),
  reason: text("reason"),
  status: appointmentStatusEnum("status").default("agendado"),
  notes: text("notes"),
}, (t) => ({ orgIdx: index("idx_appointments_organization_id").on(t.organizationId), customerIdx: index("idx_appointments_customer_id").on(t.customerId), vehicleIdx: index("idx_appointments_vehicle_id").on(t.vehicleId), mechanicIdx: index("idx_appointments_mechanic_id").on(t.mechanicId) }));
export const insertAppointmentSchema = createInsertSchema(appointments).omit({ id: true });
export type InsertAppointment = z.infer<typeof insertAppointmentSchema>;
export type Appointment = typeof appointments.$inferSelect;

// ---- Checklists -----------------------------------------------------------

export const checklists = pgTable("checklists", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id").notNull().references(() => organizations.id, { onDelete: "cascade" }),
  serviceOrderId: integer("service_order_id").notNull().references(() => serviceOrders.id, { onDelete: "cascade" }),
  mechanicId: integer("mechanic_id").references(() => mechanics.id, { onDelete: "set null" }),
  seatCover: boolean("seat_cover").default(false),
  steeringCover: boolean("steering_cover").default(false),
  floorMat: boolean("floor_mat").default(false),
  fenderProtector: boolean("fender_protector").default(false),
  entryKm: integer("entry_km"),
  fuelLevel: text("fuel_level"),
  damages: text("damages"),
  notes: text("notes"),
  createdAt: timestamp("created_at", { withTimezone: true }),
}, (t) => ({ orgIdx: index("idx_checklists_organization_id").on(t.organizationId), serviceOrderIdx: index("idx_checklists_service_order_id").on(t.serviceOrderId), mechanicIdx: index("idx_checklists_mechanic_id").on(t.mechanicId) }));
export const insertChecklistSchema = createInsertSchema(checklists).omit({ id: true });
export type InsertChecklist = z.infer<typeof insertChecklistSchema>;
export type Checklist = typeof checklists.$inferSelect;

// ---- Telemetry ------------------------------------------------------------

export const telemetry = pgTable("telemetry", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id").notNull().references(() => organizations.id, { onDelete: "cascade" }),
  serviceOrderId: integer("service_order_id").notNull().references(() => serviceOrders.id, { onDelete: "cascade" }),
  previousStatus: text("previous_status"),
  newStatus: text("new_status").notNull(),
  changedBy: integer("changed_by").references(() => users.id, { onDelete: "set null" }),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
}, (t) => ({ orgIdx: index("idx_telemetry_organization_id").on(t.organizationId), serviceOrderIdx: index("idx_telemetry_service_order_id").on(t.serviceOrderId), changedByIdx: index("idx_telemetry_changed_by").on(t.changedBy) }));
export const insertTelemetrySchema = createInsertSchema(telemetry).omit({ id: true });
export type InsertTelemetry = z.infer<typeof insertTelemetrySchema>;
export type Telemetry = typeof telemetry.$inferSelect;

// ---- Payments -------------------------------------------------------------

export const payments = pgTable("payments", {
  id: serial("id").primaryKey(),
  organizationId: integer("organization_id").notNull().references(() => organizations.id, { onDelete: "cascade" }),
  serviceOrderId: integer("service_order_id").notNull().references(() => serviceOrders.id, { onDelete: "cascade" }),
  amount: integer("amount").notNull(),
  method: text("method").notNull(),
  status: paymentStatusEnum("status").default("pendente"),
  paidAt: timestamp("paid_at", { withTimezone: true }),
  notes: text("notes"),
}, (t) => ({ orgIdx: index("idx_payments_organization_id").on(t.organizationId), serviceOrderIdx: index("idx_payments_service_order_id").on(t.serviceOrderId) }));
export const insertPaymentSchema = createInsertSchema(payments).omit({ id: true });
export type InsertPayment = z.infer<typeof insertPaymentSchema>;
export type Payment = typeof payments.$inferSelect;

// ---- Helpers (pure TS -- identical to SQLite version) --------------------

export function formatOsNumber(id: number): string {
  return `OS-${String(id).padStart(5, "0")}`;
}

export function toCents(brl: string | number): number {
  if (typeof brl === "number") {
    if (!Number.isFinite(brl)) return 0;
    return Math.round(brl * 100);
  }
  if (typeof brl !== "string") return 0;
  const trimmed = brl.trim();
  if (trimmed === "") return 0;
  let s = trimmed.replace(/[^\d.,-]/g, "");
  const lastComma = s.lastIndexOf(",");
  const lastDot = s.lastIndexOf(".");
  if (lastComma > lastDot) {
    s = s.replace(/\./g, "").replace(",", ".");
  } else if (lastDot > lastComma) {
    s = s.replace(/,/g, "");
  } else {
    if (lastComma !== -1) s = s.replace(",", ".");
  }
  const n = Number(s);
  if (!Number.isFinite(n)) return 0;
  return Math.round(n * 100);
}

export function fromCents(cents: number | null | undefined): number {
  if (cents === null || cents === undefined || !Number.isFinite(cents)) return 0;
  return cents / 100;
}

export function formatCentsBRL(cents: number | null | undefined): string {
  if (cents === null || cents === undefined || !Number.isFinite(cents)) return "—";
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(cents / 100);
}
