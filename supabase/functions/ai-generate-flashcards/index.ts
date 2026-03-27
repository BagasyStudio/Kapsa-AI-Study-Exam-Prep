import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { checkAndRecordUsage, checkIsPro } from "../_shared/usage.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LLAMA_MODEL = "meta/meta-llama-3-8b-instruct";

// ── Constants ─────────────────────────────────────────────────────
const CARDS_PER_CHUNK = 15;       // reduced for faster generation
const CHARS_PER_CARD = 200;       // ~1 card per 200 chars of source
const MAX_TOTAL_CARDS = 250;      // absolute max for paid plans
const FREE_MAX_CARDS = 30;        // hard cap for free users (server-side enforcement)
const MIN_TOTAL_CARDS = 5;
const MAX_CONCURRENT = 4;         // parallel Replicate calls
const CHUNK_SIZE = 5000;          // larger chunks = fewer batches
const POLL_INTERVAL_MS = 500;     // poll every 500ms instead of 1000ms
const MAX_POLL_ATTEMPTS = 90;     // 90 * 500ms = 45 seconds max per call
const GLOBAL_DEADLINE_MS = 50_000; // 50s — return before Supabase kills us at 60s

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

// ── Pexels banner image ──────────────────────────────────────────
async function fetchPexelsBanner(query: string): Promise<string | null> {
  const pexelsKey = Deno.env.get("PEXELS_API_KEY");
  if (!pexelsKey) {
    console.warn("PEXELS_API_KEY not set, skipping banner");
    return null;
  }

  try {
    const cleanQuery = query
      .replace(/[^a-zA-Z0-9\u00C0-\u024F\s]/g, "")
      .split(/\s+/)
      .filter((w: string) => w.length > 2)
      .slice(0, 3)
      .join(" ")
      .trim();

    if (!cleanQuery) return null;

    const url = `https://api.pexels.com/v1/search?query=${encodeURIComponent(cleanQuery)}&orientation=landscape&per_page=1`;
    const res = await fetch(url, {
      headers: { Authorization: pexelsKey },
    });

    if (!res.ok) {
      console.warn(`Pexels HTTP ${res.status}`);
      return null;
    }

    const data = await res.json();
    const photo = data?.photos?.[0];
    if (!photo) {
      console.warn(`Pexels: no results for "${cleanQuery}"`);
      return null;
    }

    return photo.src?.landscape || photo.src?.large || null;
  } catch (e) {
    console.warn("Pexels fetch failed:", e);
    return null;
  }
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

    // ── Usage enforcement ─────────────────────────────────────────
    const usage = await checkAndRecordUsage(supabase, user.id, "flashcards");
    if (!usage.allowed) {
      return new Response(JSON.stringify({ error: usage.reason }), {
        status: 429,
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

    // ── Check subscription status (server-side enforcement) ───────
    const isPro = await checkIsPro(supabase, user.id);
    const maxCards = isPro ? MAX_TOTAL_CARDS : FREE_MAX_CARDS;

    // ── Build full content and auto-calculate count ───────────────
    const fullContent = validMaterials
      .map((m: any) => `--- ${m.title} ---\n${m.content}`)
      .join("\n\n");

    const totalContentLength = fullContent.length;
    const autoCount = Math.min(
      maxCards,
      Math.max(MIN_TOTAL_CARDS, Math.round(totalContentLength / CHARS_PER_CARD)),
    );

    // Use client count if provided, otherwise auto-calculate — always capped by subscription
    const totalCards = rawCount
      ? Math.min(maxCards, Math.max(1, Math.floor(rawCount)))
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

      // Split into sub-batches of CARDS_PER_CHUNK each
      let remaining = count;
      while (remaining > 0) {
        const batchCount = Math.min(remaining, CARDS_PER_CHUNK);
        chunkCards.push({ chunk: chunks[i], count: batchCount });
        remaining -= batchCount;
      }
      cardsAssigned += count;
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

    // Cap to requested count — AI may generate more per batch than requested
    if (allCards.length > totalCards) {
      console.log(`Trimming ${allCards.length} → ${totalCards} cards (requested)`);
      allCards.length = totalCards;
    }

    // ── Group cards by topic for subdeck creation ──────────────────
    const sanitizedCards = allCards.map((c: any) => ({
      topic: typeof c.topic === "string" ? c.topic.trim().substring(0, 200) : "General",
      question_before: typeof c.question_before === "string" ? c.question_before.substring(0, 500) : "",
      keyword: typeof c.keyword === "string" ? c.keyword.substring(0, 100) : "",
      question_after: typeof c.question_after === "string" ? c.question_after.substring(0, 500) : "",
      answer: typeof c.answer === "string" ? c.answer.substring(0, 2000) : "",
    }));

    // Group by topic (case-insensitive comparison, preserve original casing)
    const topicGroups = new Map<string, { displayTitle: string; cards: typeof sanitizedCards }>();
    for (const card of sanitizedCards) {
      const key = card.topic.toLowerCase();
      if (!topicGroups.has(key)) {
        topicGroups.set(key, { displayTitle: card.topic, cards: [] });
      }
      topicGroups.get(key)!.cards.push(card);
    }

    // Merge tiny clusters (< 2 cards) into the largest group
    const sortedGroups = [...topicGroups.entries()].sort((a, b) => b[1].cards.length - a[1].cards.length);
    const largestKey = sortedGroups[0]?.[0];
    if (largestKey) {
      for (const [key, group] of sortedGroups) {
        if (key !== largestKey && group.cards.length < 2) {
          topicGroups.get(largestKey)!.cards.push(...group.cards);
          topicGroups.delete(key);
        }
      }
    }

    const uniqueTopics = [...topicGroups.values()];
    const shouldCreateSubdecks = uniqueTopics.length > 1 && sanitizedCards.length > 5;

    // Simple hash for gradient index
    const titleForGradient = sanitizedTopic || course.title || "Deck";
    let gradientHash = 0;
    for (let i = 0; i < titleForGradient.length; i++) {
      gradientHash = ((gradientHash << 5) - gradientHash + titleForGradient.charCodeAt(i)) & 0x7FFFFFFF;
    }
    const parentGradientIndex = gradientHash % 12;

    // ── Generate AI description + Pexels banner (parallel) ─────────
    let deckDescription = `Study collection for ${course.title}`;
    let bannerUrl: string | null = null;
    const bannerQuery = sanitizedTopic || course.title || "studying";

    if (!isDeadlineClose()) {
      const promises: [Promise<string | null>, Promise<string | null>] = [
        // AI description (only for subdecks)
        shouldCreateSubdecks
          ? (async () => {
              try {
                const topicNames = uniqueTopics.map(t => t.displayTitle).join(", ");
                const descSystemPrompt = `Write a brief 1-sentence description for a flashcard deck about "${course.title}" covering these topics: ${topicNames}. Write in ${detectedLang}. Output ONLY the description, no quotes, nothing else.`;
                const descResult = await callReplicate(replicateKey, "Generate description.", descSystemPrompt, 150);
                const cleaned = descResult.trim().replace(/^["']|["']$/g, "");
                return (cleaned.length > 10 && cleaned.length < 500) ? cleaned : null;
              } catch (e) {
                console.warn("Description generation failed:", e);
                return null;
              }
            })()
          : Promise.resolve(null),
        // Pexels banner
        fetchPexelsBanner(bannerQuery),
      ];

      const [descResult, pexelsResult] = await Promise.allSettled(promises);
      if (descResult.status === "fulfilled" && descResult.value) {
        deckDescription = descResult.value;
      }
      if (pexelsResult.status === "fulfilled" && pexelsResult.value) {
        bannerUrl = pexelsResult.value;
      }
    }

    if (!shouldCreateSubdecks) {
      // ── Single flat deck (backward compatible) ────────────────
      const { data: deck, error: deckError } = await supabase
        .from("flashcard_decks")
        .insert({
          course_id: courseId,
          user_id: user.id,
          title: sanitizedTopic || course.title || "Study Deck",
          card_count: sanitizedCards.length,
          description: deckDescription,
          cover_gradient_index: parentGradientIndex,
          banner_url: bannerUrl,
        })
        .select()
        .single();

      if (deckError || !deck) {
        console.error("Failed to create deck:", deckError);
        throw new Error("Failed to create flashcard deck. Please try again.");
      }

      const cardRows = sanitizedCards.map(c => ({ deck_id: deck.id, ...c }));
      for (let i = 0; i < cardRows.length; i += 500) {
        const batch = cardRows.slice(i, i + 500);
        const { error: insertError } = await supabase.from("flashcards").insert(batch);
        if (insertError) console.error(`Insert batch ${i / 500} failed:`, insertError);
      }

      const elapsed = ((Date.now() - globalStart) / 1000).toFixed(1);
      console.log(`Done (flat): ${sanitizedCards.length} flashcards in deck ${deck.id} (${elapsed}s)`);

      return new Response(JSON.stringify({ ...deck, card_count: sanitizedCards.length }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Create parent deck + child subdecks ──────────────────────
    const { data: parentDeck, error: parentError } = await supabase
      .from("flashcard_decks")
      .insert({
        course_id: courseId,
        user_id: user.id,
        title: sanitizedTopic || course.title || "Study Deck",
        card_count: sanitizedCards.length,
        parent_deck_id: null,
        description: deckDescription,
        cover_gradient_index: parentGradientIndex,
        banner_url: bannerUrl,
      })
      .select()
      .single();

    if (parentError || !parentDeck) {
      console.error("Failed to create parent deck:", parentError);
      throw new Error("Failed to create flashcard deck. Please try again.");
    }

    console.log(`Created parent deck ${parentDeck.id} with ${uniqueTopics.length} topics`);

    // Create child decks and insert their cards
    for (let i = 0; i < uniqueTopics.length; i++) {
      const group = uniqueTopics[i];
      const childGradientIndex = (parentGradientIndex + i + 1) % 12;

      const { data: childDeck, error: childError } = await supabase
        .from("flashcard_decks")
        .insert({
          course_id: courseId,
          user_id: user.id,
          title: group.displayTitle,
          card_count: group.cards.length,
          parent_deck_id: parentDeck.id,
          cover_gradient_index: childGradientIndex,
        })
        .select()
        .single();

      if (childError || !childDeck) {
        console.error(`Failed to create child deck "${group.displayTitle}":`, childError);
        continue; // Skip this topic, don't fail the whole generation
      }

      const cardRows = group.cards.map(c => ({ deck_id: childDeck.id, ...c }));
      for (let j = 0; j < cardRows.length; j += 500) {
        const batch = cardRows.slice(j, j + 500);
        const { error: insertError } = await supabase.from("flashcards").insert(batch);
        if (insertError) console.error(`Insert batch for "${group.displayTitle}" failed:`, insertError);
      }

      console.log(`  Child "${group.displayTitle}": ${group.cards.length} cards`);
    }

    const elapsed = ((Date.now() - globalStart) / 1000).toFixed(1);
    console.log(`Done (subdecks): ${sanitizedCards.length} flashcards across ${uniqueTopics.length} subdecks in ${elapsed}s`);

    return new Response(JSON.stringify({ ...parentDeck, card_count: sanitizedCards.length }), {
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
