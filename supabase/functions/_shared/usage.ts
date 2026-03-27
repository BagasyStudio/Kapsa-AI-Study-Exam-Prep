import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

/** Credit costs per feature (must match Flutter AppLimits.creditCost). */
const CREDIT_COST: Record<string, number> = {
  chat: 5,
  oracle: 5,
  snap_solve: 5,
  glossary: 10,
  flashcards: 15,
  quiz: 15,
  summary: 15,
  audio_summary: 15,
  whisper: 20,
  ocr: 20,
};

/** Free tier daily credit pool. */
const FREE_CREDITS_PER_DAY = 100;

/** Pro tier per-feature daily safety limits. */
const PRO_DAILY_LIMITS: Record<string, number> = {
  chat: 50,
  flashcards: 50,
  quiz: 30,
  ocr: 10,
  whisper: 20,
  oracle: 50,
  snap_solve: 30,
  audio_summary: 10,
  summary: 10,
  glossary: 10,
};

/**
 * Check if a user is Pro (includes pro_override for admin/testers).
 */
export async function checkIsPro(
  supabase: SupabaseClient,
  userId: string,
): Promise<boolean> {
  try {
    const { data: profile } = await supabase
      .from("profiles")
      .select("is_pro, pro_override")
      .eq("id", userId)
      .single();
    return profile?.is_pro === true || profile?.pro_override === true;
  } catch (_) {
    return false;
  }
}

/**
 * Check if a user can use a feature. Does NOT record usage —
 * call recordUsage() after the operation succeeds so failed
 * requests don't consume credits.
 *
 * Returns { allowed: true } or { allowed: false, reason: string }.
 */
export async function checkUsage(
  supabase: SupabaseClient,
  userId: string,
  feature: string,
): Promise<{ allowed: boolean; reason?: string }> {
  const isPro = await checkIsPro(supabase, userId);
  const today = new Date().toISOString().substring(0, 10);

  if (isPro) {
    const { data } = await supabase
      .from("usage_tracking")
      .select("id")
      .eq("user_id", userId)
      .eq("feature", feature)
      .eq("used_at", today);

    const used = (data as any[] | null)?.length ?? 0;
    const limit = PRO_DAILY_LIMITS[feature] ?? 10;

    if (used >= limit) {
      return { allowed: false, reason: `Daily safety limit reached (${limit}/${feature})` };
    }
  } else {
    const { data } = await supabase
      .from("usage_tracking")
      .select("feature")
      .eq("user_id", userId)
      .eq("used_at", today);

    let totalCredits = 0;
    for (const row of (data as any[] | null) ?? []) {
      totalCredits += CREDIT_COST[row.feature] ?? 3;
    }
    const cost = CREDIT_COST[feature] ?? 3;
    if (totalCredits + cost > FREE_CREDITS_PER_DAY) {
      return { allowed: false, reason: "Daily free credits exhausted" };
    }
  }

  return { allowed: true };
}

/**
 * Record a usage after a successful operation.
 */
export async function recordUsage(
  supabase: SupabaseClient,
  userId: string,
  feature: string,
): Promise<void> {
  await supabase.from("usage_tracking").insert({
    user_id: userId,
    feature,
  });
}

/**
 * Check usage AND record in one call (convenience for simple cases).
 * Only records if allowed. Use separate checkUsage + recordUsage
 * when you need to record only after the operation succeeds.
 */
export async function checkAndRecordUsage(
  supabase: SupabaseClient,
  userId: string,
  feature: string,
): Promise<{ allowed: boolean; reason?: string }> {
  const result = await checkUsage(supabase, userId, feature);
  if (result.allowed) {
    await recordUsage(supabase, userId, feature);
  }
  return result;
}
