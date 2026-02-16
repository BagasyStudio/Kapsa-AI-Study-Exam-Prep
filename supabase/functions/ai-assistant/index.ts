import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ═══════════════════════════════════════════
// Replicate API helpers
// ═══════════════════════════════════════════
const GEMMA_VERSION = "c0f0aebe8e578c15a7531e08a62cf01206f5870e9d0a67804b8152822db58c54";

async function callReplicate(apiKey: string, systemPrompt: string, userPrompt: string, maxTokens = 512): Promise<string> {
  const response = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: GEMMA_VERSION,
      input: {
        prompt: userPrompt,
        system_prompt: systemPrompt,
        max_new_tokens: maxTokens,
        temperature: 0.7,
        top_p: 0.9,
      },
    }),
  });

  if (!response.ok) {
    const errBody = await response.text();
    throw new Error(`AI service error (${response.status})`);
  }

  const prediction = await response.json();

  // Poll for result
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
    throw new Error(result.error || "AI prediction failed");
  }
  if (result.status !== "succeeded") {
    throw new Error("AI prediction timed out");
  }

  return Array.isArray(result.output) ? result.output.join("") : String(result.output);
}

async function callReplicateChat(apiKey: string, messages: Array<{role: string, content: string}>, maxTokens = 1024): Promise<string> {
  const systemMsg = messages.find(m => m.role === "system");
  const chatMsgs = messages.filter(m => m.role !== "system");

  const prompt = chatMsgs.map(m => {
    return m.role === "user" ? `User: ${m.content}` : `Assistant: ${m.content}`;
  }).join("\n") + "\nAssistant:";

  return callReplicate(apiKey, systemMsg?.content || "", prompt, maxTokens);
}

/**
 * Detect the primary language of a text sample.
 */
function detectLanguageHint(text: string): string {
  if (!text || text.length < 10) return "English";

  const sample = text.substring(0, 500).toLowerCase();

  const spanishWords = ["que", "los", "las", "del", "una", "con", "por", "para", "como", "más", "esta", "pero", "sobre", "entre", "cuando", "también", "puede", "tiene", "desde", "todo", "hola", "estudiar", "cómo", "estoy", "hoy", "semana", "bien"];
  const spanishChars = /[áéíóúñ¿¡]/;

  const portugueseWords = ["não", "uma", "com", "são", "mais", "para", "como", "está", "pode", "isso", "pelo", "muito", "também"];
  const portugueseChars = /[ãõç]/;

  const frenchWords = ["les", "des", "une", "que", "dans", "pour", "avec", "sur", "sont", "pas", "plus", "mais", "comme"];
  const frenchChars = /[àâêëîïôùûçœ]/;

  const germanWords = ["und", "die", "der", "das", "ist", "ein", "eine", "mit", "auf", "für", "nicht", "auch", "sich"];
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
  if (best.score >= 2) return best.lang;
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

    // Verify JWT
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { mode, message, history } = await req.json();

    // ═══════════════════════════════════════════
    // Gather ALL user data for context
    // ═══════════════════════════════════════════
    const [profileRes, coursesRes, recentTestsRes, flashcardStatsRes, eventsRes, materialsRes] = await Promise.all([
      supabase.from("profiles").select("*").eq("id", user.id).single(),
      supabase.from("courses").select("*").eq("user_id", user.id).order("updated_at", { ascending: false }),
      supabase.from("tests").select("id, course_id, title, score, grade, correct_count, total_count, created_at").eq("user_id", user.id).order("created_at", { ascending: false }).limit(5),
      supabase.rpc("get_flashcard_stats", { p_user_id: user.id }).maybeSingle(),
      supabase.from("calendar_events").select("*").eq("user_id", user.id).gte("start_time", new Date().toISOString()).order("start_time", { ascending: true }).limit(10),
      supabase.from("course_materials").select("id, course_id, title, type, content, created_at").eq("user_id", user.id).order("created_at", { ascending: false }).limit(10),
    ]);

    const profile = profileRes.data;
    const courses = coursesRes.data || [];
    const recentTests = recentTestsRes.data || [];
    const flashcardStats = flashcardStatsRes.data;
    const upcomingEvents = eventsRes.data || [];
    const recentMaterials = materialsRes.data || [];

    // Extract first name from full_name field (DB column is "full_name", not "first_name")
    const fullName = profile?.full_name || "";
    const firstName = fullName ? fullName.split(" ")[0] : "Student";
    const lastName = fullName.includes(" ") ? fullName.split(" ").slice(1).join(" ") : "";

    // Detect language from user message + recent materials
    const messageLang = message ? detectLanguageHint(message) : "English";
    const materialText = recentMaterials.map((m: any) => (m.content || "").substring(0, 200)).join(" ");
    const materialLang = detectLanguageHint(materialText);
    // Prioritize: user message language > material language > English
    const responseLang = messageLang !== "English" ? messageLang : (materialLang !== "English" ? materialLang : "English");

    // Get weak topics from recent test questions
    let weakTopics: string[] = [];
    if (recentTests.length > 0) {
      const testIds = recentTests.map((t: any) => t.id);
      const { data: wrongQuestions } = await supabase
        .from("test_questions")
        .select("question, correct_answer")
        .in("test_id", testIds)
        .eq("is_correct", false)
        .limit(10);
      weakTopics = (wrongQuestions || []).map((q: any) => q.question.substring(0, 60));
    }

    // ═══════════════════════════════════════════
    // Build compressed system prompt
    // ═══════════════════════════════════════════
    const courseSummaries = courses.slice(0, 5).map((c: any) => {
      const examInfo = c.exam_date ? ` | Exam: ${new Date(c.exam_date).toLocaleDateString()}` : "";
      return `- ${c.title} (${Math.round((c.progress || 0) * 100)}%${examInfo})`;
    }).join("\n");

    const testSummaries = recentTests.slice(0, 3).map((t: any) => {
      return `- ${t.title || "Quiz"}: ${t.grade || "N/A"} (${t.correct_count}/${t.total_count})`;
    }).join("\n");

    const eventSummaries = upcomingEvents.slice(0, 5).map((e: any) => {
      const date = new Date(e.start_time).toLocaleDateString();
      return `- ${e.title} (${e.type}) on ${date}`;
    }).join("\n");

    const weakTopicsList = weakTopics.length > 0
      ? `Weak areas: ${weakTopics.slice(0, 5).join("; ")}`
      : "No weak areas identified yet.";

    const fcStats = flashcardStats
      ? `Flashcards: ${flashcardStats.mastered || 0} mastered, ${flashcardStats.learning || 0} learning, ${flashcardStats.total_new || 0} new`
      : "No flashcard data yet.";

    const systemPrompt = `You are The Oracle, a personal AI study assistant for ${firstName} in the Kapsa app.

CRITICAL LANGUAGE RULE: You MUST respond in ${responseLang}. The student communicates in ${messageLang} and their course materials are in ${materialLang}. Always match the student's language. If they write in Spanish, respond entirely in Spanish. If English, respond in English. Never mix languages.

STUDENT PROFILE:
- Name: ${firstName} ${lastName}
- Streak: ${profile?.streak_days || 0} days
- Total courses: ${courses.length}

COURSES:
${courseSummaries || "No courses yet."}

RECENT QUIZ RESULTS:
${testSummaries || "No quizzes taken yet."}

${fcStats}

${weakTopicsList}

UPCOMING EVENTS:
${eventSummaries || "No upcoming events."}

RULES:
- Be encouraging, warm, and concise
- Reference specific courses, scores, and dates when relevant
- Suggest actionable study strategies
- If they have upcoming exams, prioritize exam prep advice
- Keep responses under 150 words for insights mode, normal length for chat mode
- Use the student's name occasionally
- Never make up data not provided above`;

    // ═══════════════════════════════════════════
    // Handle different modes
    // ═══════════════════════════════════════════
    if (mode === "insights") {
      const insightPrompt = responseLang === "Spanish"
        ? `Basado en los datos del estudiante, genera una perspectiva de estudio personalizada. Considera:
1. Exámenes próximos
2. Rendimiento reciente en quizzes y áreas débiles
3. Racha de estudio
4. Repaso de flashcards
5. Progreso de cursos
Responde con JSON: { "title": "título corto (max 6 palabras)", "body": "consejo accionable (max 2 oraciones)", "type": "exam_prep|weak_area|streak|review|progress" }`
        : `Based on the student's data, generate a single personalized study insight or reminder. Consider:
1. Upcoming exams and how soon they are
2. Recent quiz performance and weak areas
3. Study streak maintenance
4. Flashcard review suggestions
5. Course progress
Respond with JSON: { "title": "short title (max 6 words)", "body": "actionable insight (max 2 sentences)", "type": "exam_prep|weak_area|streak|review|progress" }`;

      const aiResponse = await callReplicate(replicateKey, systemPrompt, insightPrompt, 256);

      let insight;
      try {
        const jsonMatch = aiResponse.match(/\{[^}]+\}/s);
        insight = jsonMatch ? JSON.parse(jsonMatch[0]) : { title: responseLang === "Spanish" ? "Consejo de Estudio" : "Study Tip", body: aiResponse, type: "progress" };
      } catch {
        insight = { title: responseLang === "Spanish" ? "Consejo de Estudio" : "Study Tip", body: aiResponse.substring(0, 200), type: "progress" };
      }

      return new Response(JSON.stringify(insight), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (mode === "chat") {
      const chatHistory = (history || []).slice(-8).map((m: any) => ({
        role: m.role === "user" ? "user" : "assistant",
        content: m.content,
      }));

      const messages = [
        { role: "system", content: systemPrompt },
        ...chatHistory,
        { role: "user", content: message },
      ];

      const aiResponse = await callReplicateChat(replicateKey, messages);

      return new Response(JSON.stringify({
        role: "assistant",
        content: aiResponse,
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (mode === "calendar_suggestions") {
      const calPrompt = responseLang === "Spanish"
        ? `Basado en los cursos del estudiante, exámenes, áreas débiles y resultados, sugiere 3-5 eventos de estudio para los próximos 7 días.
Hoy es ${new Date().toISOString().split("T")[0]}.
Para cada evento responde con JSON array:
[{ "title": "título del evento (en español)", "type": "suggestion", "start_hour": 14, "duration_minutes": 45, "days_from_today": 0, "description": "por qué esta sesión", "ai_suggestion": "consejo breve" }]
Prioriza:
1. Cursos con exámenes próximos
2. Áreas débiles que necesitan repaso
3. Sesiones de repaso de flashcards
4. Timing de repetición espaciada`
        : `Based on the student's courses, upcoming exams, weak areas, and quiz results, suggest 3-5 study events for the next 7 days.
Today is ${new Date().toISOString().split("T")[0]}.
For each event respond with JSON array:
[{ "title": "event title", "type": "suggestion", "start_hour": 14, "duration_minutes": 45, "days_from_today": 0, "description": "why this session", "ai_suggestion": "brief tip" }]
Prioritize:
1. Upcoming exam courses
2. Weak areas that need review
3. Flashcard review sessions
4. Spaced repetition timing`;

      const aiResponse = await callReplicate(replicateKey, systemPrompt, calPrompt, 1024);

      let suggestions;
      try {
        const jsonMatch = aiResponse.match(/\[.*\]/s);
        suggestions = jsonMatch ? JSON.parse(jsonMatch[0]) : [];
      } catch {
        suggestions = [];
      }

      // Create calendar events from suggestions
      const createdEvents = [];
      for (const s of suggestions.slice(0, 5)) {
        const startDate = new Date();
        startDate.setDate(startDate.getDate() + (s.days_from_today || 0));
        startDate.setHours(s.start_hour || 14, 0, 0, 0);

        const endDate = new Date(startDate);
        endDate.setMinutes(endDate.getMinutes() + (s.duration_minutes || 45));

        const { data: event } = await supabase.from("calendar_events").insert({
          user_id: user.id,
          title: s.title || (responseLang === "Spanish" ? "Sesión de Estudio" : "Study Session"),
          type: "suggestion",
          start_time: startDate.toISOString(),
          end_time: endDate.toISOString(),
          description: s.description || "",
          ai_suggestion: s.ai_suggestion || "",
        }).select().single();

        if (event) createdEvents.push(event);
      }

      return new Response(JSON.stringify({ suggestions: createdEvents }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Invalid mode" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("ai-assistant error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
