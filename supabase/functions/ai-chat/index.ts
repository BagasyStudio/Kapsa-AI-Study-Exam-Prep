import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GEMMA_VERSION = "c0f0aebe8e578c15a7531e08a62cf01206f5870e9d0a67804b8152822db58c54";

async function callReplicate(apiKey: string, prompt: string, systemPrompt: string): Promise<string> {
  const createRes = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: GEMMA_VERSION,
      input: {
        prompt: prompt,
        system_prompt: systemPrompt,
        max_new_tokens: 1024,
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
 */
function detectLanguageHint(text: string): string {
  if (!text || text.length < 20) return "";
  
  const sample = text.substring(0, 500).toLowerCase();
  
  const spanishWords = ["que", "los", "las", "del", "una", "con", "por", "para", "como", "m\u00e1s", "esta", "pero", "sobre", "entre", "cuando", "tambi\u00e9n", "puede", "tiene", "desde", "todo"];
  const spanishChars = /[\u00e1\u00e9\u00ed\u00f3\u00fa\u00f1\u00bf\u00a1]/;
  
  const portugueseWords = ["n\u00e3o", "uma", "com", "s\u00e3o", "mais", "para", "como", "est\u00e1", "pode", "isso", "pelo", "muito", "tamb\u00e9m"];
  const portugueseChars = /[\u00e3\u00f5\u00e7]/;
  
  const frenchWords = ["les", "des", "une", "que", "dans", "pour", "avec", "sur", "sont", "pas", "plus", "mais", "comme"];
  const frenchChars = /[\u00e0\u00e2\u00ea\u00eb\u00ee\u00ef\u00f4\u00f9\u00fb\u00e7\u0153]/;
  
  const germanWords = ["und", "die", "der", "das", "ist", "ein", "eine", "mit", "auf", "f\u00fcr", "nicht", "auch", "sich"];
  const germanChars = /[\u00e4\u00f6\u00fc\u00df]/;
  
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

    const { courseId, sessionId, message, history } = await req.json();

    // Fetch course materials for context
    const { data: materials } = await supabase
      .from("course_materials")
      .select("title, content, type")
      .eq("course_id", courseId)
      .not("content", "is", null)
      .limit(5);

    // Fetch course info
    const { data: course } = await supabase
      .from("courses")
      .select("title, subtitle")
      .eq("id", courseId)
      .single();

    // Build context from materials
    let materialContext = "";
    if (materials && materials.length > 0) {
      materialContext = "\n\nCourse Materials Available:\n" +
        materials.map((m: any) => `--- ${m.title} (${m.type}) ---\n${(m.content || "").substring(0, 2000)}`).join("\n\n");
    }

    // Detect language from materials AND user message
    const materialText = materials?.map((m: any) => m.content || "").join(" ") || "";
    const materialLang = detectLanguageHint(materialText);
    const messageLang = detectLanguageHint(message);
    // Prioritize: user message language > material language > English
    const responseLang = messageLang !== "English" ? messageLang : materialLang;

    // Build conversation history
    let historyText = "";
    if (history && history.length > 0) {
      historyText = "\n\nConversation History:\n" +
        history.map((h: any) => `${h.role === "user" ? "Student" : "Tutor"}: ${h.content}`).join("\n");
    }

    const systemPrompt = `You are "The Oracle", an expert AI study tutor for the course "${course?.title || "Unknown Course"}"${course?.subtitle ? ` - ${course.subtitle}` : ""}.

Your role:
- Help students understand course concepts clearly and concisely
- Use analogies and examples to explain complex topics
- Reference specific course materials when relevant
- Be encouraging and supportive
- Keep responses focused and educational
- When referencing materials, mention them as citations

CRITICAL LANGUAGE RULE: You MUST respond in ${responseLang}. The student's message is in ${messageLang} and the course materials are in ${materialLang}. Always match the student's language. If they write in Spanish, respond entirely in Spanish. If they write in English, respond in English. Never mix languages.${materialContext}`;

    const prompt = `${historyText}\n\nStudent: ${message}\n\nTutor:`;

    const aiResponse = await callReplicate(replicateKey, prompt, systemPrompt);

    // Save AI response to database
    const { data: savedMessage } = await supabase
      .from("chat_messages")
      .insert({
        session_id: sessionId,
        role: "assistant",
        content: aiResponse.trim(),
        citations: materials ? materials.map((m: any) => m.title).slice(0, 3) : [],
      })
      .select()
      .single();

    return new Response(JSON.stringify(savedMessage), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("ai-chat error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
