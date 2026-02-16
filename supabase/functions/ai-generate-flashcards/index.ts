import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function callReplicate(apiKey: string, prompt: string, systemPrompt: string, maxTokens = 2048): Promise<string> {
  const createRes = await fetch("https://api.replicate.com/v1/models/meta/meta-llama-3-8b-instruct/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      input: {
        prompt: prompt,
        system_prompt: systemPrompt,
        max_tokens: maxTokens,
        temperature: 0.7,
        top_p: 0.9,
      },
    }),
  });

  if (!createRes.ok) {
    const errBody = await createRes.text();
    throw new Error(`Replicate API error ${createRes.status}: ${errBody}`);
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
    throw new Error(`Replicate prediction failed: ${result.error}`);
  }
  if (result.status !== "succeeded") {
    throw new Error("Replicate prediction timed out");
  }

  return Array.isArray(result.output) ? result.output.join("") : String(result.output);
}

/**
 * Detect the primary language of a text sample.
 * Returns a language hint string for the AI prompt.
 */
function detectLanguageHint(text: string): string {
  if (!text || text.length < 20) return "";
  
  // Sample the first 500 chars for detection
  const sample = text.substring(0, 500).toLowerCase();
  
  // Spanish indicators
  const spanishWords = ["que", "los", "las", "del", "una", "con", "por", "para", "como", "más", "esta", "pero", "sobre", "entre", "cuando", "también", "puede", "tiene", "desde", "todo", "según", "donde", "después", "porque", "cada", "hacer", "sin", "ser", "este", "así"];
  const spanishChars = /[áéíóúñ¿¡]/;
  
  // Portuguese indicators
  const portugueseWords = ["não", "uma", "com", "são", "mais", "para", "como", "está", "pode", "isso", "pelo", "muito", "também", "onde", "quando", "ainda", "então", "sobre", "depois"];
  const portugueseChars = /[ãõç]/;
  
  // French indicators
  const frenchWords = ["les", "des", "une", "que", "dans", "pour", "avec", "sur", "sont", "pas", "plus", "mais", "comme", "cette", "tout", "être", "fait", "aussi", "nous", "même"];
  const frenchChars = /[àâêëîïôùûüÿçœæ]/;
  
  // German indicators  
  const germanWords = ["und", "die", "der", "das", "ist", "ein", "eine", "mit", "auf", "für", "nicht", "auch", "sich", "von", "sind", "werden", "hat", "wird", "dass", "oder"];
  const germanChars = /[äöüß]/;
  
  // Count matches
  const words = sample.split(/\s+/);
  let esCount = 0, ptCount = 0, frCount = 0, deCount = 0;
  
  for (const w of words) {
    if (spanishWords.includes(w)) esCount++;
    if (portugueseWords.includes(w)) ptCount++;
    if (frenchWords.includes(w)) frCount++;
    if (germanWords.includes(w)) deCount++;
  }
  
  // Boost with character detection
  if (spanishChars.test(sample)) esCount += 3;
  if (portugueseChars.test(sample)) ptCount += 3;
  if (frenchChars.test(sample)) frCount += 3;
  if (germanChars.test(sample)) deCount += 3;
  
  const scores = [
    { lang: "Spanish", code: "es", score: esCount },
    { lang: "Portuguese", code: "pt", score: ptCount },
    { lang: "French", code: "fr", score: frCount },
    { lang: "German", code: "de", score: deCount },
  ];
  
  const best = scores.sort((a, b) => b.score - a.score)[0];
  
  // If strong signal for a non-English language
  if (best.score >= 3) {
    return best.lang;
  }
  
  // Default: assume English
  return "English";
}

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

    const { courseId, count = 10, materialId, topic } = await req.json();

    // Fetch course info
    const { data: course } = await supabase
      .from("courses")
      .select("title, subtitle")
      .eq("id", courseId)
      .single();

    // Fetch materials
    let materialsQuery = supabase
      .from("course_materials")
      .select("title, content, type")
      .eq("course_id", courseId)
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

    // Detect language from materials
    const allContent = materials?.map((m: any) => m.content || "").join(" ") || "";
    const detectedLang = detectLanguageHint(allContent);

    const systemPrompt = `You are a flashcard generator for the course "${course?.title || "Study Course"}".

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

IMPORTANT: Output ONLY a valid JSON array. No markdown, no explanation, just the JSON array.${topic ? `\nFocus on the topic: ${topic}` : ""}`;

    const prompt = `Based on this course material, generate ${count} flashcards in the SAME LANGUAGE as the material:\n\n${materialContent}\n\nOutput the JSON array now:`;

    const aiResponse = await callReplicate(replicateKey, prompt, systemPrompt);

    // Parse JSON from response
    let cards;
    try {
      const jsonMatch = aiResponse.match(/\[[\s\S]*\]/);
      cards = JSON.parse(jsonMatch ? jsonMatch[0] : aiResponse);
    } catch {
      throw new Error("Failed to parse flashcards from AI response");
    }

    // Create deck
    const { data: deck } = await supabase
      .from("flashcard_decks")
      .insert({
        course_id: courseId,
        user_id: user.id,
        title: topic || course?.title || "Study Deck",
        card_count: cards.length,
      })
      .select()
      .single();

    // Insert cards
    const cardRows = cards.map((c: any) => ({
      deck_id: deck.id,
      topic: c.topic || "General",
      question_before: c.question_before || "",
      keyword: c.keyword || "",
      question_after: c.question_after || "",
      answer: c.answer || "",
    }));

    await supabase.from("flashcards").insert(cardRows);

    return new Response(JSON.stringify(deck), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("ai-generate-flashcards error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
