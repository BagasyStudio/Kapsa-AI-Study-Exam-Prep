import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LLAMA_MODEL = "meta/meta-llama-3-8b-instruct";

// ── Constants ─────────────────────────────────────────────────────
const CHUNK_SIZE = 5000;
const MAX_CONCURRENT = 4;
const MAX_TOKENS_PER_BATCH = 4096;
const POLL_INTERVAL_MS = 500;
const MAX_POLL_ATTEMPTS = 50;
const GLOBAL_DEADLINE_MS = 50_000; // 50s (10s buffer before Supabase kills at 60s)

// ── Global deadline tracking ─────────────────────────────────────
let globalStart = 0;
function isDeadlineClose(): boolean {
  return Date.now() - globalStart > GLOBAL_DEADLINE_MS;
}

// ── Input validation ──────────────────────────────────────────────
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isValidUUID(value: unknown): value is string {
  return typeof value === "string" && UUID_REGEX.test(value);
}

function sanitizeErrorMessage(error: unknown): string {
  console.error("ai-generate-summary internal error:", error);
  return "An internal error occurred. Please try again.";
}

// ── AI call ───────────────────────────────────────────────────────
function buildLlamaPrompt(systemPrompt: string, userPrompt: string): string {
  return `<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n${systemPrompt}<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n${userPrompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n`;
}

async function callReplicate(apiKey: string, prompt: string, systemPrompt: string, maxTokens = 2048): Promise<string> {
  const createRes = await fetch(`https://api.replicate.com/v1/models/${LLAMA_MODEL}/predictions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "Prefer": "wait=60",
    },
    body: JSON.stringify({
      input: {
        prompt: buildLlamaPrompt(systemPrompt, prompt),
        max_tokens: maxTokens,
      },
    }),
  });

  if (!createRes.ok) {
    const status = createRes.status;
    const errBody = await createRes.text();
    console.error(`Replicate HTTP ${status}: ${errBody.substring(0, 500)}`);
    if (status === 401) throw new Error("HTTP 401: API key invalid");
    if (status === 422) throw new Error("HTTP 422: model rejected");
    if (status === 429) throw new Error("HTTP 429: rate limited");
    throw new Error(`HTTP ${status}`);
  }

  let result = await createRes.json();

  // Prefer: wait returns completed result directly (no polling needed)
  if (result.status === "succeeded") {
    return Array.isArray(result.output) ? result.output.join("") : String(result.output);
  }
  if (result.status === "failed") {
    throw new Error("AI processing failed. Please try again.");
  }

  // Fallback: poll only if Prefer: wait didn't complete in time (rare)
  let attempts = 0;
  while (result.status !== "succeeded" && result.status !== "failed" && attempts < MAX_POLL_ATTEMPTS) {
    if (isDeadlineClose()) throw new Error("Request timeout: AI processing took too long. Please try again.");
    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
    const pollRes = await fetch(result.urls.get, {
      headers: { "Authorization": `Bearer ${apiKey}` },
    });
    if (!pollRes.ok) {
      const errBody = await pollRes.text();
      throw new Error(`AI service unavailable during polling (${pollRes.status}): ${errBody.substring(0, 200)}`);
    }
    result = await pollRes.json();
    attempts++;
  }

  if (result.status === "failed") throw new Error("AI processing failed. Please try again.");
  if (result.status !== "succeeded") throw new Error("AI processing timed out. Please try again.");

  return Array.isArray(result.output) ? result.output.join("") : String(result.output);
}

// ── Language detection ────────────────────────────────────────────
function detectLanguageHint(text: string): string {
  if (!text || text.length < 20) return "English";
  const sample = text.substring(0, 500).toLowerCase();
  const spanishWords = ["que", "los", "las", "del", "una", "con", "por", "para", "como", "más", "esta", "pero", "sobre"];
  const spanishChars = /[áéíóúñ¿¡]/;
  const words = sample.split(/\s+/);
  let esCount = 0;
  for (const w of words) { if (spanishWords.includes(w)) esCount++; }
  if (spanishChars.test(sample)) esCount += 3;
  if (esCount >= 3) return "Spanish";
  return "English";
}

// ── Content chunking ─────────────────────────────────────────────
function splitIntoChunks(text: string, chunkSize: number): string[] {
  const chunks: string[] = [];
  const paragraphs = text.split(/\n\n+/);
  let current = "";
  for (const para of paragraphs) {
    if (current.length + para.length + 2 > chunkSize && current.length > 0) {
      chunks.push(current.trim());
      current = "";
    }
    current += (current ? "\n\n" : "") + para;
  }
  if (current.trim()) chunks.push(current.trim());

  const result: string[] = [];
  for (const chunk of chunks) {
    if (chunk.length <= chunkSize) {
      result.push(chunk);
    } else {
      for (let i = 0; i < chunk.length; i += chunkSize) {
        result.push(chunk.substring(i, i + chunkSize));
      }
    }
  }
  return result;
}

// ── Concurrency control ──────────────────────────────────────────
async function runWithConcurrency<T>(
  tasks: (() => Promise<T>)[],
  maxConcurrent: number,
): Promise<PromiseSettledResult<T>[]> {
  const results: PromiseSettledResult<T>[] = new Array(tasks.length);
  let nextIndex = 0;
  async function worker() {
    while (nextIndex < tasks.length) {
      if (isDeadlineClose()) {
        // Skip remaining tasks if deadline is close
        break;
      }
      const idx = nextIndex++;
      try {
        const value = await tasks[idx]();
        results[idx] = { status: "fulfilled", value };
      } catch (reason: any) {
        results[idx] = { status: "rejected", reason };
      }
    }
  }
  const workers = Array.from({ length: Math.min(maxConcurrent, tasks.length) }, () => worker());
  await Promise.all(workers);
  return results;
}

// ── Main handler ──────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  globalStart = Date.now();

  const replicateKey = Deno.env.get("REPLICATE_API_KEY");
  if (!replicateKey) {
    return new Response(JSON.stringify({ error: "Server configuration error: AI service not configured" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No authorization header" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { courseId, materialId } = await req.json();

    if (!isValidUUID(courseId)) {
      return new Response(JSON.stringify({ error: "Invalid course ID" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Ownership check ────────────────────────────────────────
    const { data: course, error: courseError } = await supabase
      .from("courses")
      .select("id, title")
      .eq("id", courseId)
      .eq("user_id", user.id)
      .single();

    if (courseError || !course) {
      return new Response(JSON.stringify({ error: "Course not found" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Fetch materials ────────────────────────────────────────
    let materialsQuery = supabase
      .from("course_materials")
      .select("id, title, content, type")
      .eq("course_id", courseId)
      .eq("user_id", user.id)
      .not("content", "is", null);

    if (materialId && isValidUUID(materialId)) {
      materialsQuery = materialsQuery.eq("id", materialId);
    }

    const { data: materials } = await materialsQuery;
    const validMaterials = (materials || []).filter(
      (m: any) => m.content && m.content.trim().length > 0,
    );

    if (validMaterials.length === 0) {
      return new Response(JSON.stringify({
        error: "No materials with content found. Upload PDFs, notes, or audio first.",
      }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const fullContent = validMaterials
      .map((m: any) => `--- ${m.title} ---\n${m.content}`)
      .join("\n\n");

    const detectedLang = detectLanguageHint(fullContent);
    const summaryTitle = materialId
      ? validMaterials[0]?.title || course.title
      : `${course.title} - Summary`;

    console.log(`Summarizing ${fullContent.length} chars in ${detectedLang}`);

    // ── Chunk and generate partial summaries ──────────────────
    const chunks = splitIntoChunks(fullContent, CHUNK_SIZE);

    const systemPrompt = `You are an expert study summarizer. Generate concise, well-structured summaries for students.

CRITICAL: Respond entirely in ${detectedLang}.

Output a JSON object with:
- "summary": A comprehensive summary (3-6 paragraphs) using clear language
- "bulletPoints": An array of 5-10 key takeaway bullet points (strings)

IMPORTANT: Output ONLY the JSON object. No markdown code blocks, no extra text.`;

    if (chunks.length === 1) {
      // Single chunk — generate directly
      const prompt = `Summarize this study material:\n\n${chunks[0]}\n\nOutput the JSON:`;
      const aiResponse = await callReplicate(replicateKey, prompt, systemPrompt, MAX_TOKENS_PER_BATCH);

      const result = parseJsonObject(aiResponse);
      const summary = typeof result.summary === "string" ? result.summary : "";
      const bulletPoints = Array.isArray(result.bulletPoints) ? result.bulletPoints : [];

      const { data: saved } = await supabase.from("summaries").insert({
        course_id: courseId,
        material_id: materialId || null,
        user_id: user.id,
        title: summaryTitle,
        content: summary,
        bullet_points: bulletPoints,
        word_count: summary.split(/\s+/).length,
      }).select().single();

      const elapsed = Date.now() - globalStart;
      console.log(`Summary saved: ${saved.id}, ${summary.split(/\s+/).length} words, elapsed ${elapsed}ms`);

      return new Response(JSON.stringify(saved), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Multiple chunks — generate partial summaries in parallel, then merge
    const partialTasks = chunks.map((chunk, i) => () => {
      const partialPrompt = `Summarize this section (part ${i + 1} of ${chunks.length}):\n\n${chunk}\n\nOutput a brief summary paragraph:`;
      return callReplicate(replicateKey, partialPrompt,
        `You are a summarizer. Write a concise summary paragraph in ${detectedLang}. Output ONLY the summary text, no JSON.`,
        MAX_TOKENS_PER_BATCH);
    });

    const partialResults = await runWithConcurrency(partialTasks, MAX_CONCURRENT);
    const partialSummaries: string[] = [];

    for (const r of partialResults) {
      if (r.status === "fulfilled") partialSummaries.push(r.value);
    }

    if (partialSummaries.length === 0) {
      const firstError = partialResults.find(r => r.status === "rejected") as PromiseRejectedResult | undefined;
      const reason = firstError?.reason?.message || "unknown";
      console.error(`All summary batches failed. First error: ${reason}`);
      throw new Error(reason);
    }

    const phase1Elapsed = Date.now() - globalStart;
    console.log(`Phase 1 done: ${partialSummaries.length} partials in ${phase1Elapsed}ms`);

    let finalSummary: string;
    let finalBullets: string[];

    // If deadline is close after phase 1, skip the merge and use the longest partial
    if (isDeadlineClose()) {
      console.log("Deadline close after phase 1, skipping merge — using longest partial summary");
      const longest = partialSummaries.reduce((a, b) => a.length >= b.length ? a : b, "");
      finalSummary = longest;
      finalBullets = [];
    } else {
      // Merge partial summaries into final
      const mergePrompt = `Combine these partial summaries into one cohesive, well-structured summary with bullet points:\n\n${partialSummaries.join("\n\n---\n\n")}\n\nOutput the JSON:`;
      const mergeResponse = await callReplicate(replicateKey, mergePrompt, systemPrompt, MAX_TOKENS_PER_BATCH);

      const finalResult = parseJsonObject(mergeResponse);
      finalSummary = typeof finalResult.summary === "string" ? finalResult.summary : partialSummaries.join("\n\n");
      finalBullets = Array.isArray(finalResult.bulletPoints) ? finalResult.bulletPoints : [];
    }

    const { data: saved } = await supabase.from("summaries").insert({
      course_id: courseId,
      material_id: materialId || null,
      user_id: user.id,
      title: summaryTitle,
      content: finalSummary,
      bullet_points: finalBullets,
      word_count: finalSummary.split(/\s+/).length,
    }).select().single();

    const totalElapsed = Date.now() - globalStart;
    console.log(`Summary saved: ${saved.id}, ${finalSummary.split(/\s+/).length} words, elapsed ${totalElapsed}ms`);

    return new Response(JSON.stringify(saved), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const elapsed = Date.now() - globalStart;
    console.error(`ai-generate-summary failed after ${elapsed}ms`);

    const message = error instanceof Error && (
      error.message.includes("unavailable") ||
      error.message.includes("timed out") ||
      error.message.includes("failed. Please") ||
      error.message.includes("Failed to generate") ||
      error.message.includes("timeout") ||
      error.message.includes("Global deadline") ||
      error.message.startsWith("HTTP ")
    ) ? error.message : sanitizeErrorMessage(error);

    return new Response(JSON.stringify({ error: message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

function parseJsonObject(raw: string): any {
  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  const jsonStr = jsonMatch ? jsonMatch[0] : raw.trim();
  try {
    return JSON.parse(jsonStr);
  } catch {
    let sanitized = jsonStr
      .replace(/,\s*}/g, "}")
      .replace(/,\s*\]/g, "]")
      .replace(/'/g, '"');
    try {
      return JSON.parse(sanitized);
    } catch {
      return { summary: raw.substring(0, 5000), bulletPoints: [] };
    }
  }
}
