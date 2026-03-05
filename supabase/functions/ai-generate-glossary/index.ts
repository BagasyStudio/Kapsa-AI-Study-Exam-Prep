import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LLAMA_MODEL = "meta/meta-llama-3-8b-instruct";
const CHUNK_SIZE = 5000;
const MAX_CONCURRENT = 4;
const MAX_TOKENS_PER_BATCH = 4096;
const TERMS_PER_CHUNK = 15;
const POLL_INTERVAL_MS = 500;
const MAX_POLL_ATTEMPTS = 180;
const GLOBAL_DEADLINE_MS = 130_000;

let globalStart = 0;
function isDeadlineClose(): boolean {
  return Date.now() - globalStart > GLOBAL_DEADLINE_MS;
}

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function isValidUUID(value: unknown): value is string {
  return typeof value === "string" && UUID_REGEX.test(value);
}

function sanitizeErrorMessage(error: unknown): string {
  console.error("ai-generate-glossary internal error:", error);
  return "An internal error occurred. Please try again.";
}

function buildLlamaPrompt(systemPrompt: string, userPrompt: string): string {
  return `<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n${systemPrompt}<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n${userPrompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n`;
}

async function callReplicate(apiKey: string, prompt: string, systemPrompt: string, maxTokens = 2048): Promise<string> {
  const createRes = await fetch(`https://api.replicate.com/v1/models/${LLAMA_MODEL}/predictions`, {
    method: "POST",
    headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json", "Prefer": "wait=60" },
    body: JSON.stringify({ input: { prompt: buildLlamaPrompt(systemPrompt, prompt), max_tokens: maxTokens } }),
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
    if (isDeadlineClose()) throw new Error("Global deadline approaching, aborting poll");
    await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    const pollRes = await fetch(result.urls.get, { headers: { "Authorization": `Bearer ${apiKey}` } });
    if (!pollRes.ok) throw new Error("AI service unavailable during polling");
    result = await pollRes.json();
    attempts++;
  }
  if (result.status === "failed") throw new Error("AI processing failed. Please try again.");
  if (result.status !== "succeeded") throw new Error("AI processing timed out. Please try again.");
  return Array.isArray(result.output) ? result.output.join("") : String(result.output);
}

function detectLanguageHint(text: string): string {
  if (!text || text.length < 20) return "English";
  const sample = text.substring(0, 500).toLowerCase();
  const spanishWords = ["que", "los", "las", "del", "una", "con", "por", "para", "como", "más"];
  const spanishChars = /[áéíóúñ¿¡]/;
  const words = sample.split(/\s+/);
  let esCount = 0;
  for (const w of words) { if (spanishWords.includes(w)) esCount++; }
  if (spanishChars.test(sample)) esCount += 3;
  if (esCount >= 3) return "Spanish";
  return "English";
}

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
    if (chunk.length <= chunkSize) result.push(chunk);
    else for (let i = 0; i < chunk.length; i += chunkSize) result.push(chunk.substring(i, i + chunkSize));
  }
  return result;
}

async function runWithConcurrency<T>(tasks: (() => Promise<T>)[], max: number): Promise<PromiseSettledResult<T>[]> {
  const results: PromiseSettledResult<T>[] = new Array(tasks.length);
  let nextIndex = 0;
  async function worker() {
    while (nextIndex < tasks.length) {
      if (isDeadlineClose()) {
        const idx = nextIndex++;
        results[idx] = { status: "rejected", reason: new Error("Global deadline approaching, skipping task") };
        continue;
      }
      const idx = nextIndex++;
      try { results[idx] = { status: "fulfilled", value: await tasks[idx]() }; }
      catch (reason: any) { results[idx] = { status: "rejected", reason }; }
    }
  }
  await Promise.all(Array.from({ length: Math.min(max, tasks.length) }, () => worker()));
  return results;
}

function parseJsonArray(raw: string): any[] {
  const jsonMatch = raw.match(/\[[\s\S]*\]/);
  const jsonStr = jsonMatch ? jsonMatch[0] : raw.trim();
  try {
    const parsed = JSON.parse(jsonStr);
    if (Array.isArray(parsed) && parsed.length > 0) return parsed;
  } catch {}
  let sanitized = jsonStr.replace(/,\s*}/g, "}").replace(/,\s*\]/g, "]").replace(/'/g, '"').replace(/\n/g, "\\n");
  const parsed = JSON.parse(sanitized);
  if (Array.isArray(parsed) && parsed.length > 0) return parsed;
  throw new Error("No valid JSON array found");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  globalStart = Date.now();

  const replicateKey = Deno.env.get("REPLICATE_API_KEY");
  if (!replicateKey) {
    return new Response(JSON.stringify({ error: "AI service not configured" }), {
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

    const { courseId } = await req.json();
    if (!isValidUUID(courseId)) {
      return new Response(JSON.stringify({ error: "Invalid course ID" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: course } = await supabase.from("courses").select("id, title")
      .eq("id", courseId).eq("user_id", user.id).single();
    if (!course) {
      return new Response(JSON.stringify({ error: "Course not found" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: materials } = await supabase.from("course_materials")
      .select("id, title, content").eq("course_id", courseId).eq("user_id", user.id)
      .not("content", "is", null);

    const valid = (materials || []).filter((m: any) => m.content?.trim().length > 0);
    if (valid.length === 0) {
      return new Response(JSON.stringify({ error: "No materials found. Upload content first." }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const fullContent = valid.map((m: any) => `--- ${m.title} ---\n${m.content}`).join("\n\n");
    const lang = detectLanguageHint(fullContent);
    const chunks = splitIntoChunks(fullContent, CHUNK_SIZE);

    console.log(`Glossary: ${fullContent.length} chars, ${chunks.length} chunks, lang=${lang}`);

    const systemPrompt = `You are a study term extractor for the course "${course.title}".

CRITICAL: Respond entirely in ${lang}.

Extract ${TERMS_PER_CHUNK} key terms/concepts from the material. For each term provide:
- "term": The term or concept name (1-4 words)
- "definition": A clear, student-friendly definition (1-3 sentences)
- "related_terms": Array of 0-3 related terms from the same material

Output ONLY a valid JSON array. No markdown, no explanation.`;

    const tasks = chunks.map((chunk) => async () => {
      const prompt = `Extract key terms from this material:\n\n${chunk}\n\nJSON array:`;
      const response = await callReplicate(replicateKey, prompt, systemPrompt, MAX_TOKENS_PER_BATCH);
      return parseJsonArray(response);
    });

    const results = await runWithConcurrency(tasks, MAX_CONCURRENT);
    const allTerms: any[] = [];
    for (const r of results) {
      if (r.status === "fulfilled") allTerms.push(...r.value);
    }

    if (allTerms.length === 0) {
      const firstError = results.find(r => r.status === "rejected") as PromiseRejectedResult | undefined;
      const reason = firstError?.reason?.message || "unknown";
      console.error(`All glossary batches failed. First error: ${reason}`);
      throw new Error(reason);
    }

    // Deduplicate (case-insensitive, keep longer definitions)
    const termMap = new Map<string, any>();
    for (const t of allTerms) {
      if (!t.term || typeof t.term !== "string") continue;
      const key = t.term.trim().toLowerCase();
      const existing = termMap.get(key);
      if (!existing || (t.definition?.length || 0) > (existing.definition?.length || 0)) {
        termMap.set(key, t);
      }
    }

    const uniqueTerms = Array.from(termMap.values());
    console.log(`Extracted ${allTerms.length} terms, ${uniqueTerms.length} unique`);

    // Upsert into DB
    const rows = uniqueTerms.map((t: any) => ({
      course_id: courseId,
      user_id: user.id,
      term: typeof t.term === "string" ? t.term.trim().substring(0, 200) : "",
      definition: typeof t.definition === "string" ? t.definition.substring(0, 1000) : "",
      related_terms: Array.isArray(t.related_terms) ? t.related_terms.map((r: any) => String(r).substring(0, 100)) : [],
    }));

    // Delete existing terms for this course/user, then insert fresh
    await supabase.from("glossary_terms").delete()
      .eq("course_id", courseId).eq("user_id", user.id);

    for (let i = 0; i < rows.length; i += 500) {
      const batch = rows.slice(i, i + 500);
      const { error } = await supabase.from("glossary_terms").insert(batch);
      if (error) console.error(`Glossary insert batch failed:`, error);
    }

    // Return all terms
    const { data: saved } = await supabase.from("glossary_terms").select()
      .eq("course_id", courseId).eq("user_id", user.id)
      .order("term", { ascending: true });

    const elapsed = Date.now() - globalStart;
    console.log(`Glossary generation completed in ${elapsed}ms`);

    return new Response(JSON.stringify({ terms: saved, count: saved?.length || 0 }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const elapsed = Date.now() - globalStart;
    console.error(`Glossary generation failed after ${elapsed}ms`);
    const message = error instanceof Error && (
      error.message.includes("unavailable") || error.message.includes("timed out") ||
      error.message.includes("failed. Please") || error.message.includes("Failed to extract") ||
      error.message.includes("Global deadline") || error.message.startsWith("HTTP ")
    ) ? error.message : sanitizeErrorMessage(error);
    return new Response(JSON.stringify({ error: message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
