import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LLAMA_VERSION = "5a6809ca6288247d06daf6365557e5e429063f32a21146b2a807c682652136b8";
const LLAMA_TEMPLATE = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n{system_prompt}<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n";

// ── Constants ─────────────────────────────────────────────────────
const MAX_FLASHCARD_COUNT = 30;
const MIN_FLASHCARD_COUNT = 1;

// ── Input validation helpers ──────────────────────────────────────
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isValidUUID(value: unknown): value is string {
  return typeof value === "string" && UUID_REGEX.test(value);
}

function sanitizeErrorMessage(error: unknown): string {
  console.error("ai-generate-flashcards internal error:", error);
  return "An internal error occurred. Please try again.";
}

function clampCount(value: unknown): number {
  const num = typeof value === "number" ? value : 10;
  return Math.max(MIN_FLASHCARD_COUNT, Math.min(MAX_FLASHCARD_COUNT, Math.floor(num)));
}

// ── AI call ───────────────────────────────────────────────────────
async function callReplicate(apiKey: string, prompt: string, systemPrompt: string, maxTokens = 2048): Promise<string> {
  const createRes = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: LLAMA_VERSION,
      input: {
        prompt: prompt,
        system_prompt: systemPrompt,
        prompt_template: LLAMA_TEMPLATE,
        max_tokens: maxTokens,
        temperature: 0.7,
        top_p: 0.9,
      },
    }),
  });

  if (!createRes.ok) {
    throw new Error("AI service unavailable");
  }

  const prediction = await createRes.json();
  let result = prediction;
  let attempts = 0;
  while (result.status !== "succeeded" && result.status !== "failed" && attempts < 120) {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    const pollRes = await fetch(result.urls.get, {
      headers: { "Authorization": `Bearer ${apiKey}` },
    });
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

// ── Language detection ────────────────────────────────────────────
function detectLanguageHint(text: string): string {
  if (!text || text.length < 20) return "";

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

// ── Main handler ──────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
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
    const replicateKey = Deno.env.get("REPLICATE_API_KEY")!;
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

    const count = clampCount(rawCount);
    const sanitizedTopic = typeof topic === "string" ? topic.trim().substring(0, 200) : undefined;

    // ── Ownership check: verify course belongs to user ────────────
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

    // ── Fetch materials (scoped to user) ──────────────────────────
    let materialsQuery = supabase
      .from("course_materials")
      .select("title, content, type")
      .eq("course_id", courseId)
      .eq("user_id", user.id)
      .not("content", "is", null);

    if (materialId) {
      materialsQuery = materialsQuery.eq("id", materialId);
    }

    const { data: materials } = await materialsQuery.limit(5);

    let materialContent = "No materials available. Generate general study flashcards for the course.";
    if (materials && materials.length > 0) {
      materialContent = materials
        .map((m: any) => `--- ${m.title} ---\n${(m.content || "").substring(0, 3000)}`)
        .join("\n\n");
    }

    // Detect language
    const allContent = materials?.map((m: any) => m.content || "").join(" ") || "";
    const detectedLang = detectLanguageHint(allContent);

    const systemPrompt = `You are a flashcard generator for the course "${course.title}".

CRITICAL LANGUAGE RULE: The course material is in ${detectedLang}. You MUST generate ALL flashcard content (topic, question_before, keyword, question_after, and answer) in ${detectedLang}. Do NOT translate to English. Keep the same language as the source material.

Generate exactly ${count} flashcards in JSON format. Each flashcard must have:
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

IMPORTANT: Output ONLY a valid JSON array. No markdown, no explanation, just the JSON array.${sanitizedTopic ? `\nFocus on the topic: ${sanitizedTopic}` : ""}`;

    const prompt = `Based on this course material, generate ${count} flashcards in the SAME LANGUAGE as the material:\n\n${materialContent}\n\nOutput the JSON array now:`;

    const aiResponse = await callReplicate(replicateKey, prompt, systemPrompt);

    // Parse JSON from response
    let cards;
    try {
      const jsonMatch = aiResponse.match(/\[[\s\S]*\]/);
      cards = JSON.parse(jsonMatch ? jsonMatch[0] : aiResponse);
    } catch {
      throw new Error("Failed to generate flashcards. Please try again.");
    }

    // Create deck
    const { data: deck } = await supabase
      .from("flashcard_decks")
      .insert({
        course_id: courseId,
        user_id: user.id,
        title: sanitizedTopic || course.title || "Study Deck",
        card_count: cards.length,
      })
      .select()
      .single();

    // Insert cards (sanitize AI output fields)
    const cardRows = cards.map((c: any) => ({
      deck_id: deck.id,
      topic: typeof c.topic === "string" ? c.topic.substring(0, 200) : "General",
      question_before: typeof c.question_before === "string" ? c.question_before.substring(0, 500) : "",
      keyword: typeof c.keyword === "string" ? c.keyword.substring(0, 100) : "",
      question_after: typeof c.question_after === "string" ? c.question_after.substring(0, 500) : "",
      answer: typeof c.answer === "string" ? c.answer.substring(0, 2000) : "",
    }));

    await supabase.from("flashcards").insert(cardRows);

    return new Response(JSON.stringify(deck), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const message = error instanceof Error && (
      error.message.includes("unavailable") ||
      error.message.includes("timed out") ||
      error.message.includes("failed. Please") ||
      error.message.includes("Failed to generate")
    ) ? error.message : sanitizeErrorMessage(error);

    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
