/**
 * Anna brand config — operational mode per brand_id.
 *
 * Backed by `public.anna_brand_config` (migration 20260506_01_anna_drafts).
 *
 * Cached in-memory for 60s to avoid hitting Supabase on every webhook hit.
 * Cache invalidates on writes (admin endpoint) — invalidate(brandId).
 */

import { supabase } from "./supabase.js";
import { logger } from "./logger.js";

export type AnnaMode =
  | "shadow"
  | "copilot"
  | "autonomous_supervised"
  | "autonomous_full";

export interface AnnaBrandConfig {
  brand_id: string;
  mode: AnnaMode;
  copilot_escalate: string[];
  notes: string | null;
  updated_at: string;
}

const DEFAULT_MODE: AnnaMode = "shadow";
const DEFAULT_ESCALATE = ["pricing", "scheduling", "objection"];
const CACHE_TTL_MS = 60_000;

interface CacheEntry {
  cfg: AnnaBrandConfig;
  fetchedAt: number;
}

const cache = new Map<string, CacheEntry>();

export async function getBrandConfig(brandId: string): Promise<AnnaBrandConfig> {
  const now = Date.now();
  const hit = cache.get(brandId);
  if (hit && now - hit.fetchedAt < CACHE_TTL_MS) {
    return hit.cfg;
  }

  const { data, error } = await supabase
    .from("anna_brand_config")
    .select("*")
    .eq("brand_id", brandId)
    .maybeSingle();

  if (error) {
    logger.warn("anna-config.get failed; using default shadow mode", {
      brandId,
      error: error.message,
    });
    return fallback(brandId);
  }

  const cfg: AnnaBrandConfig = data
    ? (data as AnnaBrandConfig)
    : fallback(brandId);

  cache.set(brandId, { cfg, fetchedAt: now });
  return cfg;
}

export async function getMode(brandId: string): Promise<AnnaMode> {
  return (await getBrandConfig(brandId)).mode;
}

/**
 * Decide whether an Anna response should become a draft based on mode + intent.
 *
 * shadow              → always draft
 * copilot             → draft only if intent in copilot_escalate
 * autonomous_supervised → never draft (sends direct, dashboard still observes)
 * autonomous_full     → never draft
 */
export async function shouldGoToDraft(
  brandId: string,
  intent: string | null | undefined,
): Promise<boolean> {
  const cfg = await getBrandConfig(brandId);
  if (cfg.mode === "shadow") return true;
  if (cfg.mode === "copilot") {
    if (!intent) return true; // unknown intent → safer to draft
    return cfg.copilot_escalate.includes(intent);
  }
  return false;
}

export function invalidateBrand(brandId: string): void {
  cache.delete(brandId);
}

export function invalidateAll(): void {
  cache.clear();
}

function fallback(brandId: string): AnnaBrandConfig {
  return {
    brand_id: brandId,
    mode: DEFAULT_MODE,
    copilot_escalate: DEFAULT_ESCALATE,
    notes: null,
    updated_at: new Date().toISOString(),
  };
}
