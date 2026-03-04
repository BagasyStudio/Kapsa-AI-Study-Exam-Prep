import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LLAMA_MODEL = "meta/meta-llama-3-8b-instruct";

// ── Constants ─────────────────────────────────────────────────────
const CARDS_PER_CHUNK = 20;       // sweet spot for Llama 8B JSON reliability
const CHARS_PER_CARD = 150;       // ~1 card per 150 chars of source
const MAX_TOTAL_CARDS = 200;
const MIN_TOTAL_CARDS = 10;
const MAX_CONCURRENT = 5;         // parallel Replicate calls
const CHUNK_SIZE = 3000;          // chars per chunk sent to AI
const MAX_TOKENS_PER_BATCH = 4096;

// ── Input validation helpers ──────────────────────────────────────
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isValidUUID(value: unknown): value is string {
  return typeof value === "string" && UUID_REGEX.test(value);
}

function sanitizeErrorMessage(error: unknown): string {
  console.error("ai-generate-flashcards internal error:", error);
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
    },
    body: JSON.stringify({
      input: {
        prompt: buildLlamaPrompt(systemPrompt, prompt),
        max_tokens: maxTokens,
      },
    }),
  });

  if (!createRes.ok) {
    const errBody = await createRes.text();
    throw new Error(`AI service unavailable (${createRes.status}): ${errBody.substring(0, 200)}`);
  }

  const prediction = await createRes.json();
  let result = prediction;
  let attempts = 0;
  while (result.status !== "succeeded" && result.status !== "failed" && attempts < 120) {
    await new Promise((resolve) => setTimeout(resolve, 1000));
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

// ── Batch generation with concurrency control ─────────────────────
async function generateBatch(
  apiKey: string,
  chunk: string,
  cardsToGenerate: number,
  courseTitle: string,
  detectedLang: string,
  topic?: string,
): Promise<any[]> {
  const systemPrompt = `You are a flashcard generator for the course "${courseTitle}".

CRITICAL LANGUAGE RULE: The course material is in ${detectedLang}. You MUST generate ALL flashcard content (topic, question_before, keyword, question_after, and answer) in ${detectedLang}. Do NOT translate to English. Keep the same language as the source material.

Generate exactly ${cardsToGenerate} flashcards in JSON format. Each flashcard must have:
- topic: The specific topic/category
- question_before: The first part of the question before the key term
- keyword: The key term/concept that should be highlighted (1-3 words)
- question_after: The rest of the question after the keyword (can be empty string)
- answer: A clear, concise answer (1-3 sentences)

The question format should read naturally: question_before + keyword + question_after forms the full question.

Example (if material is in Spanish):
{"topic":"Estructura Celular","question_before":"¿Cuál es la función principal de la ","keyword":"mitocondria","question_after":"?","answer":"Generar la mayor parte de la energía química necesaria para las reacciones bioquímicas de la célula mediante la producción de ATP."}

Example (if material is in English):
{"topic":"Cell Structure","question_before":"What is the primary function of the ","keyword":"mitochondria","question_after":"?","answer":"Generate most of the chemical energy needed to power the cell's biochemical reactions through ATP production."}

For math/science flashcards, use LaTeX notation in answers: $...$ for inline math.

IMPORTANT: Output ONLY a valid JSON array. No markdown, no explanation, just the JSON array.${topic ? `\nFocus on the topic: ${topic}` : ""}`;

  const prompt = `Based on this course material, generate ${cardsToGenerate} flashcards in the SAME LANGUAGE as the material:\n\n${chunk}\n\nOutput the JSON array now:`;

  const aiResponse = await callReplicate(apiKey, prompt, systemPrompt, MAX_TOKENS_PER_BATCH);

  try {
    return parseJsonArray(aiResponse);
  } catch {
    // Retry once with stricter prompt
    console.warn("Batch parse failed, retrying...");
    const retryPrompt = `Generate exactly ${cardsToGenerate} flashcards as a JSON array. Output ONLY the array starting with [ and ending with ]. No text before or after.\n\nMaterial:\n${chunk.substring(0, 2000)}\n\nJSON array:`;
    const retryResponse = await callReplicate(apiKey, retryPrompt, systemPrompt, MAX_TOKENS_PER_BATCH);
    return parseJsonArray(retryResponse);
  }
}

async function runWithConcurrency<T>(
  tasks: (() => Promise<T>)[],
  maxConcurrent: number,
): Promise<PromiseSettledResult<T>[]> {
  const results: PromiseSettledResult<T>[] = new Array(tasks.length);
  let nextIndex = 0;

  async function worker() {
    while (nextIndex < tasks.length) {
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
    // Each chunk gets proportional cards based on its content size
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
        count: Math.min(count, CARDS_PER_CHUNK), // cap per-batch
      });
      cardsAssigned += chunkCards[chunkCards.length - 1].count;

      // If we need more cards from this chunk than CARDS_PER_CHUNK,
      // split into sub-batches
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
      throw new Error("Failed to generate flashcards. Please try again.");
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

    console.log(`Done: ${allCards.length} flashcards in deck ${deck.id}`);

    return new Response(JSON.stringify({ ...deck, card_count: allCards.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const message = error instanceof Error && (
      error.message.includes("unavailable") ||
      error.message.includes("timed out") ||
      error.message.includes("failed. Please") ||
      error.message.includes("Failed to generate") ||
      error.message.includes("Failed to create")
    ) ? error.message : sanitizeErrorMessage(error);

    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
