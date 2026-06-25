/**
 * Anna drafts routes — chairman approval queue for shadow mode.
 *
 * GET    /api/anna/drafts?status=&brand=          → list (default: pending_review)
 * GET    /api/anna/drafts/:id                     → fetch one
 * POST   /api/anna/drafts/:id/approve             → approve (optional text edit) + send
 * POST   /api/anna/drafts/:id/reject              → reject + reason
 * GET    /api/anna/drafts/_metrics                → approval rate, edit rate, etc
 *
 * All routes are authenticated (Bearer token via authMiddleware mounted at app level).
 */

import { Router, type Request, type Response } from "express";

import {
  createDraft,
  getDraft,
  listDrafts,
  markApproved,
  markSent,
  markSendFailed,
  rejectDraft,
  type AnnaDraftStatus,
} from "../services/anna-drafts.service.js";
import { sendTextMessage } from "../services/meta-whatsapp.service.js";
import { emitAnnaDraftSent, emitAnnaDraftRejected } from "../services/realtime.js";
import { logger } from "../services/logger.js";
import type { MetaBrandId } from "../config/meta-brands.js";

const router = Router();

// Express 5 typings widened req.params/req.query value types to include
// arrays (for wildcard patterns). Our routes always expect a single string,
// so normalize at the boundary.
const str = (v: unknown): string =>
  Array.isArray(v) ? String(v[0] ?? "") : String(v ?? "");
const strOrUndef = (v: unknown): string | undefined => {
  if (v == null) return undefined;
  const s = str(v);
  return s.length > 0 ? s : undefined;
};

const VALID_STATUSES: ReadonlySet<string> = new Set([
  "pending_review",
  "approved",
  "edited",
  "rejected",
  "sent",
  "send_failed",
  "expired",
  "all",
]);

router.get("/", async (req: Request, res: Response) => {
  try {
    const status = strOrUndef(req.query.status) ?? "pending_review";
    if (!VALID_STATUSES.has(status)) {
      res.status(400).json({ error: `invalid status: ${status}` });
      return;
    }
    const brandId = strOrUndef(req.query.brand);
    const limit = req.query.limit ? Math.min(Number(req.query.limit), 200) : undefined;

    const drafts = await listDrafts({
      status: status as AnnaDraftStatus | "all",
      brandId,
      limit,
    });
    res.json({ data: drafts });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "unknown";
    logger.error("anna-drafts.list route failed", { error: msg });
    res.status(500).json({ error: msg });
  }
});

router.get("/:id", async (req: Request, res: Response) => {
  try {
    const draft = await getDraft(str(req.params.id));
    if (!draft) {
      res.status(404).json({ error: "draft not found" });
      return;
    }
    res.json({ data: draft });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "unknown";
    res.status(500).json({ error: msg });
  }
});

router.post("/:id/approve", async (req: Request, res: Response) => {
  const id = str(req.params.id);
  const reviewerUserId = req.user?.id ?? null;
  const textOverride = (req.body?.textFinal as string | undefined)?.trim();

  try {
    // 1. Load + validate
    const draft = await getDraft(id);
    if (!draft) {
      res.status(404).json({ error: "draft not found" });
      return;
    }
    if (draft.status !== "pending_review") {
      res.status(409).json({ error: `draft is ${draft.status}, expected pending_review` });
      return;
    }

    const textFinal = textOverride && textOverride.length > 0 ? textOverride : draft.anna_text_original;
    const wasEdited = textFinal !== draft.anna_text_original;

    // 2. Mark approved (DB-level optimistic lock)
    const approved = await markApproved(id, {
      textFinal,
      wasEdited,
      reviewerUserId: typeof reviewerUserId === "number" ? reviewerUserId : null,
    });

    // 3. Send via Graph API
    let sentMessageId: string | null = null;
    try {
      const sendResult = await sendTextMessage(
        draft.client_phone,
        textFinal,
        draft.brand_id as MetaBrandId,
      );
      sentMessageId =
        (sendResult.messages as Array<{ id: string }> | undefined)?.[0]?.id ?? null;

      if (!sentMessageId) {
        throw new Error("Meta returned no message id");
      }

      await markSent(id, sentMessageId);
      emitAnnaDraftSent({
        draftId: id,
        brandId: draft.brand_id,
        sentMessageId,
        at: new Date().toISOString(),
      });

      res.json({
        data: {
          id,
          status: "sent",
          sentMessageId,
          wasEdited,
        },
      });
    } catch (sendErr) {
      const errMsg = sendErr instanceof Error ? sendErr.message : "send failed";
      await markSendFailed(id, errMsg);
      logger.error("anna-drafts.approve.send failed", { id, error: errMsg });
      res.status(502).json({
        error: "approved but send failed — draft marked send_failed",
        detail: errMsg,
      });
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : "unknown";
    logger.error("anna-drafts.approve route failed", { id, error: msg });
    res.status(500).json({ error: msg });
  }
});

router.post("/:id/reject", async (req: Request, res: Response) => {
  const id = str(req.params.id);
  const reason = (req.body?.reason as string | undefined)?.slice(0, 500) ?? null;
  const reviewerUserId = req.user?.id ?? null;

  try {
    const draft = await getDraft(id);
    if (!draft) {
      res.status(404).json({ error: "draft not found" });
      return;
    }
    if (draft.status !== "pending_review") {
      res.status(409).json({ error: `draft is ${draft.status}, expected pending_review` });
      return;
    }

    const rejected = await rejectDraft(
      id,
      reason,
      typeof reviewerUserId === "number" ? reviewerUserId : null,
    );

    emitAnnaDraftRejected({
      draftId: id,
      brandId: draft.brand_id,
      reason,
      at: new Date().toISOString(),
    });

    res.json({ data: { id: rejected.id, status: rejected.status, reason: rejected.reject_reason } });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "unknown";
    logger.error("anna-drafts.reject route failed", { id, error: msg });
    res.status(500).json({ error: msg });
  }
});

router.get("/_metrics/summary", async (req: Request, res: Response) => {
  try {
    const brandId = strOrUndef(req.query.brand);
    const allRecent = await listDrafts({ status: "all", brandId, limit: 200 });

    const total = allRecent.length;
    const approved = allRecent.filter((d) => d.status === "approved").length;
    const edited = allRecent.filter((d) => d.status === "edited").length;
    const rejected = allRecent.filter((d) => d.status === "rejected").length;
    const sent = allRecent.filter((d) => d.status === "sent").length;
    const expired = allRecent.filter((d) => d.status === "expired").length;
    const pending = allRecent.filter((d) => d.status === "pending_review").length;
    const sendFailed = allRecent.filter((d) => d.status === "send_failed").length;
    const reviewed = approved + edited + rejected;

    const approvalRate = reviewed > 0 ? approved / reviewed : null;
    const editRate = reviewed > 0 ? edited / reviewed : null;
    const rejectRate = reviewed > 0 ? rejected / reviewed : null;

    const decisions = allRecent
      .filter((d) => d.reviewed_at && d.created_at)
      .map((d) => new Date(d.reviewed_at!).getTime() - new Date(d.created_at).getTime());
    decisions.sort((a, b) => a - b);
    const medianTtdMs = decisions.length > 0 ? decisions[Math.floor(decisions.length / 2)] : null;

    res.json({
      data: {
        window: "last_200",
        total,
        pending,
        sent,
        sendFailed,
        expired,
        rates: {
          approval: approvalRate,
          edit: editRate,
          reject: rejectRate,
        },
        medianTimeToDecisionMs: medianTtdMs,
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "unknown";
    res.status(500).json({ error: msg });
  }
});

// Internal helper exposed for meta-webhook integration test scaffolding
// (not registered as HTTP route — exported only)
export const _internal = { createDraft };

export default router;
