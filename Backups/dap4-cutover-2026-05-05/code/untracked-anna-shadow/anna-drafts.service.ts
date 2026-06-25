/**
 * Anna drafts store — shadow mode approval queue.
 *
 * Used by:
 *   - meta-webhook.routes.ts → creates draft when brand mode === "shadow"
 *   - anna-drafts.routes.ts  → list / approve / reject
 *
 * Backed by `public.anna_drafts` (migration 20260506_01_anna_drafts).
 *
 * Service-role Supabase client bypasses RLS; tenant scope is enforced at
 * call sites (we always pass tenant_id explicitly).
 */

import { supabase } from "./supabase.js";
import { logger } from "./logger.js";

export type AnnaDraftStatus =
  | "pending_review"
  | "approved"
  | "edited"
  | "rejected"
  | "sent"
  | "send_failed"
  | "expired";

export interface AnnaDraft {
  id: string;
  tenant_id: string;
  brand_id: string;
  conversation_id: string;
  inbound_message_id: string | null;
  client_phone: string;
  client_name: string | null;
  anna_text_original: string;
  anna_intent: string | null;
  anna_signals: Record<string, unknown> | null;
  anna_model: string | null;
  anna_tokens_in: number | null;
  anna_tokens_out: number | null;
  status: AnnaDraftStatus;
  reviewer_user_id: number | null;
  text_final: string | null;
  reject_reason: string | null;
  reviewed_at: string | null;
  sent_at: string | null;
  sent_message_id: string | null;
  send_error: string | null;
  expires_at: string;
  created_at: string;
  updated_at: string;
}

export interface CreateDraftInput {
  tenantId?: string;
  brandId: string;
  conversationId: string;
  inboundMessageId?: string | null;
  clientPhone: string;
  clientName?: string | null;
  annaTextOriginal: string;
  annaIntent?: string | null;
  annaSignals?: Record<string, unknown> | null;
  annaModel?: string | null;
  annaTokensIn?: number | null;
  annaTokensOut?: number | null;
}

export interface ListDraftsFilter {
  status?: AnnaDraftStatus | "all";
  brandId?: string;
  tenantId?: string;
  limit?: number;
}

export async function createDraft(input: CreateDraftInput): Promise<AnnaDraft> {
  const row = {
    tenant_id: input.tenantId ?? "dap_prime",
    brand_id: input.brandId,
    conversation_id: input.conversationId,
    inbound_message_id: input.inboundMessageId ?? null,
    client_phone: input.clientPhone,
    client_name: input.clientName ?? null,
    anna_text_original: input.annaTextOriginal,
    anna_intent: input.annaIntent ?? null,
    anna_signals: input.annaSignals ?? null,
    anna_model: input.annaModel ?? null,
    anna_tokens_in: input.annaTokensIn ?? null,
    anna_tokens_out: input.annaTokensOut ?? null,
  };

  const { data, error } = await supabase
    .from("anna_drafts")
    .insert(row)
    .select("*")
    .single();

  if (error) {
    logger.error("anna-drafts.create failed", { error: error.message, brand: input.brandId });
    throw new Error(`anna-drafts.create: ${error.message}`);
  }
  return data as AnnaDraft;
}

export async function getDraft(id: string): Promise<AnnaDraft | null> {
  const { data, error } = await supabase
    .from("anna_drafts")
    .select("*")
    .eq("id", id)
    .maybeSingle();

  if (error) {
    logger.error("anna-drafts.get failed", { error: error.message, id });
    throw new Error(`anna-drafts.get: ${error.message}`);
  }
  return (data as AnnaDraft) ?? null;
}

export async function listDrafts(filter: ListDraftsFilter = {}): Promise<AnnaDraft[]> {
  const limit = Math.min(filter.limit ?? 50, 200);
  let query = supabase
    .from("anna_drafts")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(limit);

  if (filter.status && filter.status !== "all") {
    query = query.eq("status", filter.status);
  } else if (!filter.status) {
    query = query.eq("status", "pending_review");
  }
  if (filter.brandId) query = query.eq("brand_id", filter.brandId);
  if (filter.tenantId) query = query.eq("tenant_id", filter.tenantId);

  const { data, error } = await query;
  if (error) {
    logger.error("anna-drafts.list failed", { error: error.message });
    throw new Error(`anna-drafts.list: ${error.message}`);
  }
  return (data ?? []) as AnnaDraft[];
}

export interface ApproveInput {
  textFinal: string;
  wasEdited: boolean;
  reviewerUserId?: number | null;
}

export async function markApproved(id: string, input: ApproveInput): Promise<AnnaDraft> {
  const { data, error } = await supabase
    .from("anna_drafts")
    .update({
      status: input.wasEdited ? "edited" : "approved",
      text_final: input.textFinal,
      reviewer_user_id: input.reviewerUserId ?? null,
      reviewed_at: new Date().toISOString(),
    })
    .eq("id", id)
    .eq("status", "pending_review") // optimistic lock — only act on pending
    .select("*")
    .single();

  if (error) {
    logger.error("anna-drafts.markApproved failed", { error: error.message, id });
    throw new Error(`anna-drafts.markApproved: ${error.message}`);
  }
  return data as AnnaDraft;
}

export async function markSent(id: string, sentMessageId: string): Promise<void> {
  const { error } = await supabase
    .from("anna_drafts")
    .update({
      status: "sent",
      sent_at: new Date().toISOString(),
      sent_message_id: sentMessageId,
    })
    .eq("id", id);
  if (error) {
    logger.error("anna-drafts.markSent failed", { error: error.message, id });
    throw new Error(`anna-drafts.markSent: ${error.message}`);
  }
}

export async function markSendFailed(id: string, errorMessage: string): Promise<void> {
  const { error } = await supabase
    .from("anna_drafts")
    .update({
      status: "send_failed",
      send_error: errorMessage.slice(0, 500),
    })
    .eq("id", id);
  if (error) {
    logger.error("anna-drafts.markSendFailed failed", { error: error.message, id });
  }
}

export async function rejectDraft(
  id: string,
  reason: string | null,
  reviewerUserId?: number | null,
): Promise<AnnaDraft> {
  const { data, error } = await supabase
    .from("anna_drafts")
    .update({
      status: "rejected",
      reject_reason: reason,
      reviewer_user_id: reviewerUserId ?? null,
      reviewed_at: new Date().toISOString(),
    })
    .eq("id", id)
    .eq("status", "pending_review")
    .select("*")
    .single();

  if (error) {
    logger.error("anna-drafts.reject failed", { error: error.message, id });
    throw new Error(`anna-drafts.reject: ${error.message}`);
  }
  return data as AnnaDraft;
}

/**
 * Mark drafts past expires_at as expired. Idempotent — safe to call from
 * a scheduler every few minutes.
 */
export async function expireStaleDrafts(): Promise<number> {
  const { data, error } = await supabase
    .from("anna_drafts")
    .update({ status: "expired" })
    .eq("status", "pending_review")
    .lt("expires_at", new Date().toISOString())
    .select("id");

  if (error) {
    logger.error("anna-drafts.expireStale failed", { error: error.message });
    return 0;
  }
  return (data?.length as number) ?? 0;
}
