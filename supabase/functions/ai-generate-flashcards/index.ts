import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LLAMA_MODEL = "meta/meta-llama-3-8b-instruct";

// ── Constants ─────────────────────────────────────────────────────
const CARDS_PER_CHUNK = 15;       // reduced for faster generation
const CHARS_PER_CARD = 200;       // ~1 card per 200 chars of source
const MAX_TOTAL_CARDS = 80;       // cap to avoid too many batches
const MIN_TOTAL_CARDS = 5;
const MAX_CONCURRENT = 4;         // parallel Replicate calls
const CHUNK_SIZE = 5000;          // larger chunks = fewer batches
const POLL_INTERVAL_MS = 500;     // poll every 500ms instead of 1000ms
const MAX_POLL_ATTEMPTS = 180;    // 180 * 500ms = 90 seconds max per call
const GLOBAL_DEADLINE_MS = 130_000; // 130s — return before Supabase kills us at ~150s

// ── Input validation helpers ──────────────────────────────────────
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isValidUUID(value: unknown): value is string {
  return typeof value === "string" && UUID_REGEX.test(value);
}

function sanitizeErrorMessage(error: unknown): string {
  console.error("ai-generate-flashcards internal error:", error);
  return "An internal error occurred. Please try again.";
}

// ── Global deadline tracking ─────────────────────────────────────
let globalStart = 0;

function isDeadlineClose(): boolean {
  return Date.now() - globalStart > GLOBAL_DEADLINE_MS;
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
      "Prefer": "wait=60",  // Replicate max is 60s
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
    if (isDeadlineClose()) throw new Error("Global deadline approaching, aborting poll");
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

  if (result.status === "failed") {
    throw new Error("AI processing failed. Please try again.");
  }
  if (result.status !== "succeeded") {
    throw new Error("AI processing timed out. Please try again.");
  }

  return Array.isArray(result.output) ? result.output.join("") : String(result.output);
}

// ── JSON parsing with sanitization ────────────────────────────────
function parseJsonArray(raw: string): any[] {
  const jsonMatch = raw.match(/\[[\s\S]*\]/);
  const jsonStr = jsonMatch ? jsonMatch[0] : raw.trim();

  try {
    const parsed = JSON.parse(jsonStr);
    if (Array.isArray(parsed) && parsed.length > 0) return parsed;
  } catch {
    // Continue to sanitization
  }

  let sanitized = jsonStr
    .replace(/,\s*}/g, "}")
    .replace(/,\s*\]/g, "]")
    .replace(/'/g, '"')
    .replace(/\n/g, "\\n")
    .replace(/\t/g, "\\t");

  const parsed = JSON.parse(sanitized);
  if (Array.isArray(parsed) && parsed.length > 0) return parsed;
  throw new Error("No valid flashcard array found");
}

// ── Language detection ────────────────────────────────────────────
function detectLanguageHint(text: string): string {
  if (!text || text.length < 20) return "English";

  const sample = text.substring(0, 500).toLowerCase();

  const spanishWords = ["que", "los", "las", "del", "una", "con", "por", "para", "como", "más", "esta", "pero", "sobre", "entre", "cuando", "también", "puede", "tiene", "desde", "todo", "según", "donde", "después", "porque", "cada", "hacer", "sin", "ser", "este", "así"];
  const spanishChars = /[áéíóúñ¿¡]/;
  const portugueseWords = ["não", "uma", "com", "são", "mais", "para", "como", "está", "pode", "isso", "pelo", "muito", "também", "onde", "quando", "ainda", "então", "sobre", "depois"];
  const portugueseChars = /[ãõç]/;
  const frenchWords = ["les", "des", "une", "que", "dans", "pour", "avec", "sur", "sont", "pas", "plus", "mais", "comme", "cette", "tout", "être", "fait", "aussi", "nous", "même"];
  const frenchChars = /[àâêëîïôùûüÿçœæ]/;
  const germanWords = ["und", "die", "der", "das", "ist", "ein", "eine", "mit", "auf", "für", "nicht", "auch", "sich", "von", "sind", "werden", "hat", "wird", "dass", "oder"];
  const germanChars = /[äöüß]/;

  const words = sample.split(/\s+/);
  let esCount = 0, ptCount = 0, frCount = 0, deCount = 0;

  for (const w of words) {
    if (spanishWords.includes(w)) esCount++;
    if (portugueseWords.includes(w)) ptCount++;
    if (frenchWords.includes(w)) frCount++;
    if (germanWords.includes(w)) deCount++;
  }

  if (spanishChars.test(sample)) esCount += 3;
  if (portugueseChars.test(sample)) ptCount += 3;
  if (frenchChars.test(sample)) frCount += 3;
  if (germanChars.test(sample)) deCount += 3;

  const scores = [
    { lang: "Spanish", score: esCount },
    { lang: "Portuguese", score: ptCount },
    { lang: "French", score: frCount },
    { lang: "German", score: deCount },
  ];

  const best = scores.sort((a, b) => b.score - a.score)[0];
  if (best.score >= 3) return best.lang;
  return "English";
}

// ── Content chunking ─────────────────────────────────────────────
function splitIntoChunks(text: string, chunkSize: number): string[] {
  const chunks: string[] = [];
  // Try to split at paragraph boundaries
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

  // If any chunk is still too large, hard-split it
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

// ── Batch generation ─────────────────────────────────────────────
async function generateBatch(
  apiKey: string,
  chunk: string,
  cardsToGenerate: number,
  courseTitle: string,
  detectedLang: string,
  topic?: string,
): Promise<any[]> {
  // Scale max_tokens proportionally: ~250 tokens per card
  const scaledTokens = Math.min(4096, Math.max(1024, cardsToGenerate * 250));

  const systemPrompt = `You are a flashcard generator for the course "${courseTitle}".

CRITICAL LANGUAGE RULE: The course material is in ${detectedLang}. You MUST generate ALL flashcard content (topic, question_before, keyword, question_after, and answer) in ${detectedLang}. Do NOT translate to English. Keep the same language as the source material.

Generate exactly ${cardsToGenerate} flashcards in JSON format. Each flashcard must have:
- topic: The specific topic/category
- question_before: The first part of the question before the key term
- keyword: A key SUBJECT term from the question (1-3 words). This is the topic being ASKED ABOUT, NOT the answer. It is shown highlighted in the question.
- question_after: The rest of the question after the keyword (can be empty string)
- answer: A clear, concise answer (1-3 sentences). The answer MUST be DIFFERENT from the keyword. The answer is HIDDEN until the user flips the card.

CRITICAL: The keyword is a SUBJECT TERM visible in the question. The answer is SEPARATE and HIDDEN. NEVER put the answer in the keyword field.

The question format reads: question_before + keyword + question_after = full question shown to the user.

Example (if material is in Spanish):
{"topic":"Estructura Celular","question_before":"¿Cuál es la función principal de la ","keyword":"mitocondria","question_after":" en la célula?","answer":"Generar ATP mediante la respiración celular, proporcionando energía para las reacciones bioquímicas."}

Example (if material is in English):
{"topic":"Cell Structure","question_before":"What is the primary function of the ","keyword":"mitochondria","question_after":" in cells?","answer":"Generate ATP through cellular respiration, providing energy for biochemical reactions."}

For math/science flashcards, use LaTeX notation in answers: $...$ for inline math.

IMPORTANT: Output ONLY a valid JSON array. No markdown, no explanation, just the JSON array.${topic ? `\nFocus on the topic: ${topic}` : ""}`;

  const prompt = `Based on this course material, generate ${cardsToGenerate} flashcards in the SAME LANGUAGE as the material:\n\n${chunk}\n\nOutput the JSON array now:`;

  const aiResponse = await callReplicate(apiKey, prompt, systemPrompt, scaledTokens);

  // Single attempt parse — no retry (retries double execution time)
  return parseJsonArray(aiResponse);
}

async function runWithConcurrency<T>(
  tasks: (() => Promise<T>)[],
  maxConcurrent: number,
): Promise<PromiseSettledResult<T>[]> {
  const results: PromiseSettledResult<T>[] = new Array(tasks.length);
  let nextIndex = 0;

  async function worker() {
    while (nextIndex < tasks.length) {
      if (isDeadlineClose()) {
        // Mark remaining as rejected
        const idx = nextIndex++;
        results[idx] = { status: "rejected", reason: new Error("Global deadline") };
        continue;
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

  const workers = Array.from(
    { length: Math.min(maxConcurrent, tasks.length) },
    () => worker(),
  );
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
    console.error("REPLICATE_API_KEY is not set in Supabase secrets");
    return new Response(JSON.stringify({ error: "Server configuration error: AI service not configured" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { courseId, count: rawCount, materialId, topic } = await req.json();

    // ── Input validation ──────────────────────────────────────────
    if (!isValidUUID(courseId)) {
      return new Response(JSON.stringify({ error: "Invalid course ID" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (materialId !== undefined && !isValidUUID(materialId)) {
      return new Response(JSON.stringify({ error: "Invalid material ID" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const sanitizedTopic = typeof topic === "string" ? topic.trim().substring(0, 200) : undefined;

    // ── Ownership check ───────────────────────────────────────────
    const { data: course, error: courseError } = await supabase
      .from("courses")
      .select("id, title, subtitle")
      .eq("id", courseId)
      .eq("user_id", user.id)
      .single();

    if (courseError || !course) {
      return new Response(JSON.stringify({ error: "Course not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Fetch ALL materials (no limit) ────────────────────────────
    let materialsQuery = supabase
      .from("course_materials")
      .select("title, content, type")
      .eq("course_id", courseId)
      .eq("user_id", user.id)
      .not("content", "is", null);

    if (materialId) {
      materialsQuery = materialsQuery.eq("id", materialId);
    }

    const { data: materials } = await materialsQuery;

    const validMaterials = (materials || []).filter(
      (m: any) => m.content && m.content.trim().length > 0,
    );

    if (validMaterials.length === 0) {
      return new Response(JSON.stringify({
        error: "This course has no materials yet. Upload PDFs, notes, or audio first, then generate flashcards.",
      }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Build full content and auto-calculate count ───────────────
    const fullContent = validMaterials
      .map((m: any) => `--- ${m.title} ---\n${m.content}`)
      .join("\n\n");

    const totalContentLength = fullContent.length;
    const autoCount = Math.min(
      MAX_TOTAL_CARDS,
      Math.max(MIN_TOTAL_CARDS, Math.round(totalContentLength / CHARS_PER_CARD)),
    );

    // Use client count if provided, otherwise auto-calculate
    const totalCards = rawCount
      ? Math.min(MAX_TOTAL_CARDS, Math.max(1, Math.floor(rawCount)))
      : autoCount;

    console.log(`Content: ${totalContentLength} chars → generating ${totalCards} flashcards (auto=${autoCount})`);

    // Detect language from full content
    const detectedLang = detectLanguageHint(fullContent);

    // ── Split content into chunks ─────────────────────────────────
    const chunks = splitIntoChunks(fullContent, CHUNK_SIZE);
    console.log(`Split into ${chunks.length} chunks`);

    // ── Distribute cards across chunks ────────────────────────────
    const totalChunkChars = chunks.reduce((sum, c) => sum + c.length, 0);
    const chunkCards: { chunk: string; count: number }[] = [];
    let cardsAssigned = 0;

    for (let i = 0; i < chunks.length; i++) {
      const isLast = i === chunks.length - 1;
      const proportion = chunks[i].length / totalChunkChars;
      const count = isLast
        ? totalCards - cardsAssigned
        : Math.max(1, Math.round(totalCards * proportion));

      if (count <= 0) continue;

      chunkCards.push({
        chunk: chunks[i],
        count: Math.min(count, CARDS_PER_CHUNK),
      });
      cardsAssigned += chunkCards[chunkCards.length - 1].count;

      // Sub-batches for large counts
      let remaining = count - CARDS_PER_CHUNK;
      while (remaining > 0) {
        const batchCount = Math.min(remaining, CARDS_PER_CHUNK);
        chunkCards.push({ chunk: chunks[i], count: batchCount });
        remaining -= batchCount;
      }
    }

    console.log(`Planned ${chunkCards.length} batch(es): ${chunkCards.map(c => c.count).join(", ")} cards`);

    // ── Generate all batches in parallel ──────────────────────────
    const tasks = chunkCards.map(({ chunk, count }) => () =>
      generateBatch(replicateKey, chunk, count, course.title, detectedLang, sanitizedTopic)
    );

    const batchResults = await runWithConcurrency(tasks, MAX_CONCURRENT);

    // Collect all successful cards
    const allCards: any[] = [];
    let failedBatches = 0;

    for (const result of batchResults) {
      if (result.status === "fulfilled") {
        allCards.push(...result.value);
      } else {
        failedBatches++;
        console.warn("Batch failed:", result.reason?.message || result.reason);
      }
    }

    if (allCards.length === 0) {
      const firstError = batchResults.find(r => r.status === "rejected") as PromiseRejectedResult | undefined;
      const reason = firstError?.reason?.message || "unknown";
      console.error(`All ${chunkCards.length} batches failed. First error: ${reason}`);
      throw new Error(reason);
    }

    if (failedBatches > 0) {
      console.warn(`${failedBatches}/${chunkCards.length} batches failed, got ${allCards.length} cards`);
    }

    // ── Create deck ───────────────────────────────────────────────
    const { data: deck, error: deckError } = await supabase
      .from("flashcard_decks")
      .insert({
        course_id: courseId,
        user_id: user.id,
        title: sanitizedTopic || course.title || "Study Deck",
        card_count: allCards.length,
      })
      .select()
      .single();

    if (deckError || !deck) {
      console.error("Failed to create deck:", deckError);
      throw new Error("Failed to create flashcard deck. Please try again.");
    }

    // ── Insert cards (sanitize AI output) ─────────────────────────
    const cardRows = allCards.map((c: any) => ({
      deck_id: deck.id,
      topic: typeof c.topic === "string" ? c.topic.substring(0, 200) : "General",
      question_before: typeof c.question_before === "string" ? c.question_before.substring(0, 500) : "",
      keyword: typeof c.keyword === "string" ? c.keyword.substring(0, 100) : "",
      question_after: typeof c.question_after === "string" ? c.question_after.substring(0, 500) : "",
      answer: typeof c.answer === "string" ? c.answer.substring(0, 2000) : "",
    }));

    // Supabase insert in batches of 500 (API limit)
    for (let i = 0; i < cardRows.length; i += 500) {
      const batch = cardRows.slice(i, i + 500);
      const { error: insertError } = await supabase.from("flashcards").insert(batch);
      if (insertError) {
        console.error(`Insert batch ${i / 500} failed:`, insertError);
      }
    }

    const elapsed = ((Date.now() - globalStart) / 1000).toFixed(1);
    console.log(`Done: ${allCards.length} flashcards in deck ${deck.id} (${elapsed}s)`);

    return new Response(JSON.stringify({ ...deck, card_count: allCards.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const elapsed = ((Date.now() - globalStart) / 1000).toFixed(1);
    console.error(`Failed after ${elapsed}s:`, error);

    const message = error instanceof Error && (
      error.message.includes("unavailable") ||
      error.message.includes("timed out") ||
      error.message.includes("failed. Please") ||
      error.message.includes("Failed to generate") ||
      error.message.includes("Failed to create") ||
      error.message.startsWith("HTTP ")
    ) ? error.message : sanitizeErrorMessage(error);

    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
