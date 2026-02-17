import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LLAMA_VERSION = "5a6809ca6288247d06daf6365557e5e429063f32a21146b2a807c682652136b8";
const LLAMA_TEMPLATE = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n{system_prompt}<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n";

// ── Constants ─────────────────────────────────────────────────────
const MAX_QUIZ_COUNT = 20;
const MIN_QUIZ_COUNT = 1;

// ── Input validation helpers ──────────────────────────────────────
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isValidUUID(value: unknown): value is string {
  return typeof value === "string" && UUID_REGEX.test(value);
}

function sanitizeErrorMessage(error: unknown): string {
  console.error("ai-generate-quiz internal error:", error);
  return "An internal error occurred. Please try again.";
}

function clampCount(value: unknown, defaultVal: number): number {
  const num = typeof value === "number" ? value : defaultVal;
  return Math.max(MIN_QUIZ_COUNT, Math.min(MAX_QUIZ_COUNT, Math.floor(num)));
}

// ── JSON parsing with sanitization ────────────────────────────────
function parseJsonArray(raw: string): any[] {
  // Try direct parse first
  const jsonMatch = raw.match(/\[[\s\S]*\]/);
  const jsonStr = jsonMatch ? jsonMatch[0] : raw.trim();

  try {
    const parsed = JSON.parse(jsonStr);
    if (Array.isArray(parsed) && parsed.length > 0) return parsed;
  } catch {
    // Continue to sanitization
  }

  // Sanitize common LLM JSON issues
  let sanitized = jsonStr
    .replace(/,\s*}/g, "}")        // trailing comma before }
    .replace(/,\s*\]/g, "]")       // trailing comma before ]
    .replace(/'/g, '"')            // single quotes → double quotes
    .replace(/\n/g, "\\n")        // unescaped newlines in strings
    .replace(/\t/g, "\\t");       // unescaped tabs

  const parsed = JSON.parse(sanitized);
  if (Array.isArray(parsed) && parsed.length > 0) return parsed;
  throw new Error("No valid JSON array found");
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

// ── Grading ───────────────────────────────────────────────────────
function calculateGrade(score: number): string {
  if (score >= 0.97) return "A+";
  if (score >= 0.93) return "A";
  if (score >= 0.90) return "A-";
  if (score >= 0.87) return "B+";
  if (score >= 0.83) return "B";
  if (score >= 0.80) return "B-";
  if (score >= 0.77) return "C+";
  if (score >= 0.73) return "C";
  if (score >= 0.70) return "C-";
  if (score >= 0.67) return "D+";
  if (score >= 0.60) return "D";
  return "F";
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

    const body = await req.json();
    const { action } = body;

    // ═══════════════════════════════════════════
    // ACTION: GENERATE QUIZ
    // ═══════════════════════════════════════════
    if (action === "generate") {
      const { courseId, count: rawCount } = body;

      // ── Input validation ────────────────────────────────────────
      if (!isValidUUID(courseId)) {
        return new Response(JSON.stringify({ error: "Invalid course ID" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const count = clampCount(rawCount, 5);

      // ── Ownership check: verify course belongs to user ──────────
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

      // ── Fetch materials (scoped to user) ────────────────────────
      const { data: materials } = await supabase
        .from("course_materials")
        .select("title, content, type")
        .eq("course_id", courseId)
        .eq("user_id", user.id)
        .not("content", "is", null)
        .limit(5);

      let materialContent = "Generate general knowledge questions for the course.";
      if (materials && materials.length > 0) {
        materialContent = materials
          .map((m: any) => `--- ${m.title} ---\n${(m.content || "").substring(0, 2000)}`)
          .join("\n\n");
      }

      const allContent = materials?.map((m: any) => m.content || "").join(" ") || "";
      const detectedLang = detectLanguageHint(allContent);

      const systemPrompt = `You are a quiz generator for "${course.title}".

CRITICAL LANGUAGE RULE: The course material is in ${detectedLang}. You MUST generate ALL quiz content (questions and correct_answer) in ${detectedLang}. Do NOT translate to English. Keep the same language as the source material.

Generate exactly ${count} quiz questions in JSON format. Each question must have:
- question: The full question text (in ${detectedLang})
- correct_answer: The correct answer, concise 1-2 sentences max (in ${detectedLang})

Make questions that test understanding, not just memorization.
Vary difficulty: mix easy, medium, and hard questions.

IMPORTANT: Output ONLY a valid JSON array. No markdown, no explanation.`;

      const prompt = `Based on this course material, generate ${count} quiz questions in the SAME LANGUAGE as the material:\n\n${materialContent}\n\nOutput the JSON array now:`;

      const aiResponse = await callReplicate(replicateKey, prompt, systemPrompt);

      let questions;
      try {
        questions = parseJsonArray(aiResponse);
      } catch {
        // Retry once with a stricter prompt
        console.warn("First quiz parse attempt failed, retrying with stricter prompt...");
        const retryPrompt = `Generate exactly ${count} quiz questions as a JSON array. Output ONLY the JSON array starting with [ and ending with ]. No text before or after.\n\nMaterial:\n${materialContent.substring(0, 2000)}\n\nJSON array:`;
        const retryResponse = await callReplicate(replicateKey, retryPrompt, systemPrompt, 2048);
        try {
          questions = parseJsonArray(retryResponse);
        } catch {
          throw new Error("Failed to generate quiz. Please try again.");
        }
      }

      // Create test
      const { data: test } = await supabase
        .from("tests")
        .insert({
          course_id: courseId,
          user_id: user.id,
          title: `${course.title || "Quiz"} - Quiz`,
          total_count: questions.length,
        })
        .select()
        .single();

      // Insert questions (sanitize AI output)
      const questionRows = questions.map((q: any, i: number) => ({
        test_id: test.id,
        question_number: i + 1,
        question: typeof q.question === "string" ? q.question.substring(0, 1000) : "",
        correct_answer: typeof q.correct_answer === "string" ? q.correct_answer.substring(0, 2000) : "",
      }));

      const { data: savedQuestions } = await supabase
        .from("test_questions")
        .insert(questionRows)
        .select();

      return new Response(JSON.stringify({ test, questions: savedQuestions }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    // ═══════════════════════════════════════════
    // ACTION: EVALUATE ANSWERS
    // ═══════════════════════════════════════════
    } else if (action === "evaluate") {
      const { testId, answers } = body;

      // ── Input validation ────────────────────────────────────────
      if (!isValidUUID(testId)) {
        return new Response(JSON.stringify({ error: "Invalid test ID" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      if (!Array.isArray(answers) || answers.length === 0) {
        return new Response(JSON.stringify({ error: "Answers are required" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Validate each answer has required fields
      for (const a of answers) {
        if (!a || !isValidUUID(a.questionId) || typeof a.answer !== "string") {
          return new Response(JSON.stringify({ error: "Invalid answer format" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      }

      // ── Ownership check: verify test belongs to user ────────────
      const { data: test, error: testError } = await supabase
        .from("tests")
        .select("*, courses(title)")
        .eq("id", testId)
        .eq("user_id", user.id)
        .single();

      if (testError || !test) {
        return new Response(JSON.stringify({ error: "Test not found" }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Fetch questions (scoped via verified test)
      const { data: questions } = await supabase
        .from("test_questions")
        .select()
        .eq("test_id", testId)
        .order("question_number", { ascending: true });

      // Detect language
      const questionsText = (questions || []).map((q: any) => q.question).join(" ");
      const detectedLang = detectLanguageHint(questionsText);

      // Build AI evaluation prompt
      const allQA = (questions || []).map((q: any, i: number) => {
        const userAnswer = answers.find((a: any) => a.questionId === q.id)?.answer || "";
        // Truncate user answers to prevent abuse
        const sanitizedAnswer = userAnswer.substring(0, 2000);
        return `Q${i + 1}: ${q.question}\nCorrect Answer: ${q.correct_answer}\nStudent Answer: ${sanitizedAnswer}`;
      }).join("\n\n");

      const evalSystemPrompt = `You are a fair and encouraging study tutor evaluating a student's quiz answers.

CRITICAL: Respond in ${detectedLang}.

For each question, evaluate if the student's answer demonstrates understanding of the concept, even if the wording differs from the correct answer. Be lenient — if the student shows they understand the key concept, mark it as correct.

For each question, provide:
- is_correct: true/false (true if the student demonstrates understanding)
- ai_insight: A brief 1-2 sentence insight in ${detectedLang}. For correct answers, praise briefly. For wrong answers, explain why it's wrong and help them remember the correct answer.

IMPORTANT: Output ONLY a valid JSON array with objects like: [{"is_correct": true, "ai_insight": "..."}]
One object per question, in order. No markdown, no explanation outside the JSON.`;

      const evalPrompt = `Evaluate these ${(questions || []).length} student answers:\n\n${allQA}\n\nOutput the JSON array now:`;

      let evaluatedQuestions: any[] = [];
      let correctCount = 0;

      try {
        const aiEvalResponse = await callReplicate(replicateKey, evalPrompt, evalSystemPrompt, 2048);
        const evaluations = parseJsonArray(aiEvalResponse);

        for (let i = 0; i < (questions || []).length; i++) {
          const q = questions![i];
          const userAnswer = answers.find((a: any) => a.questionId === q.id)?.answer || "";
          const evalResult = evaluations[i] || { is_correct: false, ai_insight: "" };
          const isCorrect = evalResult.is_correct === true;

          if (isCorrect) correctCount++;

          evaluatedQuestions.push({
            ...q,
            user_answer: userAnswer.substring(0, 2000),
            is_correct: isCorrect,
            ai_insight: typeof evalResult.ai_insight === "string"
              ? evalResult.ai_insight.substring(0, 500)
              : (isCorrect
                ? (detectedLang === "Spanish" ? "¡Correcto! Buen trabajo." : "Correct! Great job.")
                : (detectedLang === "Spanish" ? "Revisa este tema." : "Review this topic.")),
          });
        }
      } catch (evalError) {
        console.error("AI evaluation failed, falling back to simple comparison:", evalError);
        // Fallback: simple string comparison
        for (const q of (questions || [])) {
          const userAnswer = answers.find((a: any) => a.questionId === q.id)?.answer || "";
          const isCorrect = userAnswer.trim().toLowerCase() === q.correct_answer.trim().toLowerCase() ||
            q.correct_answer.toLowerCase().includes(userAnswer.trim().toLowerCase());
          if (isCorrect) correctCount++;
          evaluatedQuestions.push({
            ...q,
            user_answer: userAnswer.substring(0, 2000),
            is_correct: isCorrect,
            ai_insight: isCorrect
              ? (detectedLang === "Spanish" ? "¡Correcto! Buen trabajo." : "Correct! Great job.")
              : (detectedLang === "Spanish" ? "Revisa este tema para mejorar tu comprensión." : "Review this topic for better understanding."),
          });
        }
      }

      const totalQ = questions?.length || 1;
      const score = correctCount / totalQ;
      const grade = calculateGrade(score);

      // Generate motivational text
      let motivationText = "";
      if (detectedLang === "Spanish") {
        if (score >= 0.9) motivationText = "¡Trabajo excepcional! Dominaste este material.";
        else if (score >= 0.7) motivationText = "¡Muy bien! Enfocate en las áreas que fallaste para mejorar aún más.";
        else if (score >= 0.5) motivationText = "¡Buen comienzo! Repasá los temas que fallaste e intentá de nuevo.";
        else motivationText = "¡Seguí estudiando! Revisá los materiales y practicá más.";
      } else if (detectedLang === "Portuguese") {
        if (score >= 0.9) motivationText = "Trabalho excelente! Você dominou este material.";
        else if (score >= 0.7) motivationText = "Ótimo esforço! Foque nas áreas que errou para melhorar ainda mais.";
        else if (score >= 0.5) motivationText = "Bom começo! Revise os tópicos e tente novamente.";
        else motivationText = "Continue estudando! Revise os materiais e pratique mais.";
      } else {
        if (score >= 0.9) motivationText = "Outstanding work! You've mastered this material.";
        else if (score >= 0.7) motivationText = "Great effort! Focus on the areas you missed to improve even more.";
        else if (score >= 0.5) motivationText = "Good start! Review the missed topics and try again.";
        else motivationText = "Keep studying! Review the materials and practice more.";
      }

      // Update test
      await supabase
        .from("tests")
        .update({
          score,
          grade,
          correct_count: correctCount,
          motivation_text: motivationText,
        })
        .eq("id", testId)
        .eq("user_id", user.id); // Double-check ownership on update

      // Update questions with answers and insights
      for (const q of evaluatedQuestions) {
        await supabase
          .from("test_questions")
          .update({
            user_answer: q.user_answer,
            is_correct: q.is_correct,
            ai_insight: q.ai_insight,
          })
          .eq("id", q.id);
      }

      const updatedTest = {
        ...test,
        score,
        grade,
        correct_count: correctCount,
        motivation_text: motivationText,
      };

      return new Response(JSON.stringify({ test: updatedTest, questions: evaluatedQuestions }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Invalid action" }), {
      status: 400,
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
