import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LLAMA_MODEL = "meta/meta-llama-3-8b-instruct";

// ── Constants ─────────────────────────────────────────────────────
const QUESTIONS_PER_CHUNK = 10;    // reliable JSON output per batch
const CHARS_PER_QUESTION = 300;    // ~1 question per 300 chars of source
const MAX_TOTAL_QUESTIONS = 30;
const MIN_TOTAL_QUESTIONS = 3;
const MAX_CONCURRENT = 4;
const CHUNK_SIZE = 5000;           // chars per chunk sent to AI
const POLL_INTERVAL_MS = 500;
const MAX_POLL_ATTEMPTS = 50;
const GLOBAL_DEADLINE_MS = 50_000; // 50s (10s buffer before Supabase kills at 60s)

// ── Global deadline tracking ─────────────────────────────────────
let globalStart = 0;
function isDeadlineClose(): boolean {
  return Date.now() - globalStart > GLOBAL_DEADLINE_MS;
}

// ── Input validation helpers ──────────────────────────────────────
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isValidUUID(value: unknown): value is string {
  return typeof value === "string" && UUID_REGEX.test(value);
}

function sanitizeErrorMessage(error: unknown): string {
  console.error("ai-generate-quiz internal error:", error);
  return "An internal error occurred. Please try again.";
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
  throw new Error("No valid JSON array found");
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
    if (status === 422) throw new Error(`HTTP 422: ${errBody.substring(0, 50)}`);
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

// ── Batch quiz generation ────────────────────────────────────────
async function generateQuizBatch(
  apiKey: string,
  chunk: string,
  questionsToGenerate: number,
  courseTitle: string,
  detectedLang: string,
): Promise<any[]> {
  const scaledTokens = Math.min(4096, Math.max(1024, questionsToGenerate * 350));

  const systemPrompt = `You are a quiz generator for "${courseTitle}".

CRITICAL LANGUAGE RULE: The course material is in ${detectedLang}. You MUST generate ALL quiz content (questions and correct_answer) in ${detectedLang}. Do NOT translate to English. Keep the same language as the source material.

Generate exactly ${questionsToGenerate} quiz questions in JSON format. Each question must have:
- question: The full question text (in ${detectedLang})
- correct_answer: The correct answer, concise 1-2 sentences max (in ${detectedLang})

Make questions that test understanding, not just memorization.
Vary difficulty: mix easy, medium, and hard questions.

For math/science questions, use LaTeX notation: $...$ for inline math, $$...$$ for display math.

IMPORTANT: Output ONLY a valid JSON array. No markdown, no explanation.`;

  const prompt = `Based on this course material, generate ${questionsToGenerate} quiz questions in the SAME LANGUAGE as the material:\n\n${chunk}\n\nOutput the JSON array now:`;

  const aiResponse = await callReplicate(apiKey, prompt, systemPrompt, scaledTokens);

  return parseJsonArray(aiResponse);
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
      const idx = nextIndex++;
      if (isDeadlineClose()) {
        results[idx] = { status: "rejected", reason: new Error("Request timeout: AI processing took too long. Please try again.") };
        continue;
      }
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

    const body = await req.json();
    const { action } = body;

    // ═══════════════════════════════════════════
    // ACTION: GENERATE QUIZ (batch-parallel)
    // ═══════════════════════════════════════════
    if (action === "generate") {
      const { courseId, count: rawCount, isPracticeExam } = body;

      if (!isValidUUID(courseId)) {
        return new Response(JSON.stringify({ error: "Invalid course ID" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // ── Ownership check ────────────────────────────────────────
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

      // ── Fetch ALL materials (no limit) ─────────────────────────
      const { data: materials } = await supabase
        .from("course_materials")
        .select("title, content, type")
        .eq("course_id", courseId)
        .eq("user_id", user.id)
        .not("content", "is", null);

      const validMaterials = (materials || []).filter(
        (m: any) => m.content && m.content.trim().length > 0,
      );

      if (validMaterials.length === 0) {
        return new Response(JSON.stringify({
          error: "This course has no materials yet. Upload PDFs, notes, or audio first, then generate a quiz.",
        }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // ── Build full content and auto-calculate count ────────────
      const fullContent = validMaterials
        .map((m: any) => `--- ${m.title} ---\n${m.content}`)
        .join("\n\n");

      const totalContentLength = fullContent.length;
      const autoCount = Math.min(
        MAX_TOTAL_QUESTIONS,
        Math.max(MIN_TOTAL_QUESTIONS, Math.round(totalContentLength / CHARS_PER_QUESTION)),
      );

      // Use client count if provided, otherwise auto-calculate
      const totalQuestions = rawCount
        ? Math.min(MAX_TOTAL_QUESTIONS, Math.max(1, Math.floor(rawCount)))
        : autoCount;

      console.log(`Content: ${totalContentLength} chars -> generating ${totalQuestions} questions (auto=${autoCount})`);

      const detectedLang = detectLanguageHint(fullContent);

      // ── Split content into chunks ──────────────────────────────
      const chunks = splitIntoChunks(fullContent, CHUNK_SIZE);
      console.log(`Split into ${chunks.length} chunks`);

      // ── Distribute questions across chunks ─────────────────────
      const totalChunkChars = chunks.reduce((sum, c) => sum + c.length, 0);
      const chunkQuestions: { chunk: string; count: number }[] = [];
      let questionsAssigned = 0;

      for (let i = 0; i < chunks.length; i++) {
        const isLast = i === chunks.length - 1;
        const proportion = chunks[i].length / totalChunkChars;
        const count = isLast
          ? totalQuestions - questionsAssigned
          : Math.max(1, Math.round(totalQuestions * proportion));

        if (count <= 0) continue;

        chunkQuestions.push({
          chunk: chunks[i],
          count: Math.min(count, QUESTIONS_PER_CHUNK),
        });
        questionsAssigned += chunkQuestions[chunkQuestions.length - 1].count;

        // Sub-batches if needed
        let remaining = count - QUESTIONS_PER_CHUNK;
        while (remaining > 0) {
          const batchCount = Math.min(remaining, QUESTIONS_PER_CHUNK);
          chunkQuestions.push({ chunk: chunks[i], count: batchCount });
          remaining -= batchCount;
        }
      }

      console.log(`Planned ${chunkQuestions.length} batch(es): ${chunkQuestions.map(c => c.count).join(", ")} questions`);

      // ── Generate all batches in parallel ───────────────────────
      const tasks = chunkQuestions.map(({ chunk, count }) => () =>
        generateQuizBatch(replicateKey, chunk, count, course.title, detectedLang)
      );

      const batchResults = await runWithConcurrency(tasks, MAX_CONCURRENT);

      let allQuestions: any[] = [];
      let failedBatches = 0;

      for (const result of batchResults) {
        if (result.status === "fulfilled") {
          allQuestions.push(...result.value);
        } else {
          failedBatches++;
          console.warn("Quiz batch failed:", result.reason?.message || result.reason);
        }
      }

      if (allQuestions.length === 0) {
        const firstError = batchResults.find(r => r.status === "rejected") as PromiseRejectedResult | undefined;
        const reason = firstError?.reason?.message || "unknown";
        console.error(`All ${chunkQuestions.length} batches failed. First error: ${reason}`);
        throw new Error(reason);
      }

      if (failedBatches > 0) {
        console.warn(`${failedBatches}/${chunkQuestions.length} batches failed, got ${allQuestions.length} questions`);
      }

      // ── Trim to exact requested count ─────────────────────────
      if (allQuestions.length > totalQuestions) {
        console.log(`Trimming ${allQuestions.length} questions down to ${totalQuestions}`);
        allQuestions = allQuestions.slice(0, totalQuestions);
      }

      // ── Create test ────────────────────────────────────────────
      const { data: test } = await supabase
        .from("tests")
        .insert({
          course_id: courseId,
          user_id: user.id,
          title: isPracticeExam
            ? `${course.title || "Exam"} - Practice Exam`
            : `${course.title || "Quiz"} - Quiz`,
          total_count: allQuestions.length,
          is_practice_exam: isPracticeExam === true,
          status: 'in_progress',
        })
        .select()
        .single();

      // ── Insert questions (sanitize AI output) ──────────────────
      const questionRows = allQuestions.map((q: any, i: number) => ({
        test_id: test.id,
        question_number: i + 1,
        question: typeof q.question === "string" ? q.question.substring(0, 1000) : "",
        correct_answer: typeof q.correct_answer === "string" ? q.correct_answer.substring(0, 2000) : "",
      }));

      // Insert in batches of 500
      let savedQuestions: any[] = [];
      for (let i = 0; i < questionRows.length; i += 500) {
        const batch = questionRows.slice(i, i + 500);
        const { data, error: insertError } = await supabase
          .from("test_questions")
          .insert(batch)
          .select();
        if (insertError) {
          console.error(`Insert batch ${i / 500} failed:`, insertError);
        }
        if (data) savedQuestions.push(...data);
      }

      const elapsed = Date.now() - globalStart;
      console.log(`Done: ${allQuestions.length} questions in test ${test.id} (${elapsed}ms)`);

      return new Response(JSON.stringify({ test, questions: savedQuestions }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    // ═══════════════════════════════════════════
    // ACTION: EVALUATE ANSWERS
    // ═══════════════════════════════════════════
    } else if (action === "evaluate") {
      const { testId, answers } = body;

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

      for (const a of answers) {
        if (!a || !isValidUUID(a.questionId) || typeof a.answer !== "string") {
          return new Response(JSON.stringify({ error: "Invalid answer format" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
      }

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

      const { data: questions } = await supabase
        .from("test_questions")
        .select()
        .eq("test_id", testId)
        .order("question_number", { ascending: true });

      const questionsText = (questions || []).map((q: any) => q.question).join(" ");
      const detectedLang = detectLanguageHint(questionsText);

      const allQA = (questions || []).map((q: any, i: number) => {
        const userAnswer = answers.find((a: any) => a.questionId === q.id)?.answer || "";
        const sanitizedAnswer = userAnswer.substring(0, 2000);
        return `Q${i + 1}: ${q.question}\nCorrect Answer: ${q.correct_answer}\nStudent Answer: ${sanitizedAnswer}`;
      }).join("\n\n");

      const scaledEvalTokens = Math.min(4096, Math.max(1024, (questions || []).length * 350));

      const evalSystemPrompt = `You are a fair and encouraging study tutor evaluating a student's quiz answers.

CRITICAL: Respond in ${detectedLang}.

For each question, evaluate if the student's answer demonstrates understanding of the concept, even if the wording differs from the correct answer. Be lenient -- if the student shows they understand the key concept, mark it as correct.

For each question, provide:
- is_correct: true/false (true if the student demonstrates understanding)
- ai_insight: A brief 1-2 sentence insight in ${detectedLang}. For correct answers, praise briefly. For wrong answers, explain why it's wrong and help them remember the correct answer.

IMPORTANT: Output ONLY a valid JSON array with objects like: [{"is_correct": true, "ai_insight": "..."}]
One object per question, in order. No markdown, no explanation outside the JSON.`;

      const evalPrompt = `Evaluate these ${(questions || []).length} student answers:\n\n${allQA}\n\nOutput the JSON array now:`;

      let evaluatedQuestions: any[] = [];
      let correctCount = 0;

      try {
        const aiEvalResponse = await callReplicate(replicateKey, evalPrompt, evalSystemPrompt, scaledEvalTokens);
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
                ? (detectedLang === "Spanish" ? "Correcto! Buen trabajo." : "Correct! Great job.")
                : (detectedLang === "Spanish" ? "Revisa este tema." : "Review this topic.")),
          });
        }
      } catch (evalError) {
        console.error("AI evaluation failed, falling back to simple comparison:", evalError);
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
              ? (detectedLang === "Spanish" ? "Correcto! Buen trabajo." : "Correct! Great job.")
              : (detectedLang === "Spanish" ? "Revisa este tema para mejorar tu comprension." : "Review this topic for better understanding."),
          });
        }
      }

      const totalQ = questions?.length || 1;
      const score = correctCount / totalQ;
      const grade = calculateGrade(score);

      let motivationText = "";
      if (detectedLang === "Spanish") {
        if (score >= 0.9) motivationText = "Trabajo excepcional! Dominaste este material.";
        else if (score >= 0.7) motivationText = "Muy bien! Enfocate en las areas que fallaste para mejorar aun mas.";
        else if (score >= 0.5) motivationText = "Buen comienzo! Repasa los temas que fallaste e intenta de nuevo.";
        else motivationText = "Segui estudiando! Revisa los materiales y practica mas.";
      } else if (detectedLang === "Portuguese") {
        if (score >= 0.9) motivationText = "Trabalho excelente! Voce dominou este material.";
        else if (score >= 0.7) motivationText = "Otimo esforco! Foque nas areas que errou para melhorar ainda mais.";
        else if (score >= 0.5) motivationText = "Bom comeco! Revise os topicos e tente novamente.";
        else motivationText = "Continue estudando! Revise os materiais e pratique mais.";
      } else {
        if (score >= 0.9) motivationText = "Outstanding work! You've mastered this material.";
        else if (score >= 0.7) motivationText = "Great effort! Focus on the areas you missed to improve even more.";
        else if (score >= 0.5) motivationText = "Good start! Review the missed topics and try again.";
        else motivationText = "Keep studying! Review the materials and practice more.";
      }

      await supabase
        .from("tests")
        .update({
          score,
          grade,
          correct_count: correctCount,
          motivation_text: motivationText,
          status: 'completed',
        })
        .eq("id", testId)
        .eq("user_id", user.id);

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
        status: 'completed',
      };

      const elapsed = Date.now() - globalStart;
      console.log(`Evaluate done: ${correctCount}/${totalQ} correct, grade ${grade} (${elapsed}ms)`);

      return new Response(JSON.stringify({ test: updatedTest, questions: evaluatedQuestions }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    // ═══════════════════════════════════════════
    // ACTION: EXPLAIN MISTAKES (Feature 2)
    // ═══════════════════════════════════════════
    } else if (action === "explain_mistakes") {
      const { testId } = body;

      if (!isValidUUID(testId)) {
        return new Response(JSON.stringify({ error: "Invalid test ID" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // ── Ownership check ────────────────────────────────────────
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

      // Fetch only wrong answers
      const { data: wrongQuestions } = await supabase
        .from("test_questions")
        .select()
        .eq("test_id", testId)
        .eq("is_correct", false)
        .order("question_number", { ascending: true });

      if (!wrongQuestions || wrongQuestions.length === 0) {
        return new Response(JSON.stringify({
          explanation: "You got everything right! No mistakes to explain.",
          weakTopics: [],
          studyTips: [],
        }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const questionsText = wrongQuestions.map((q: any) => q.question).join(" ");
      const detectedLang = detectLanguageHint(questionsText);

      // Build consolidated mistakes context
      const mistakesContext = wrongQuestions.map((q: any, i: number) =>
        `Mistake ${i + 1}:\n  Question: ${q.question}\n  Student answered: ${q.user_answer || "(no answer)"}\n  Correct answer: ${q.correct_answer}\n  Brief insight: ${q.ai_insight || "N/A"}`
      ).join("\n\n");

      const courseName = test.courses?.title || "this course";

      const scaledExplainTokens = Math.min(4096, Math.max(1024, wrongQuestions.length * 350));

      const systemPrompt = `You are an expert study tutor helping a student understand their mistakes on a quiz about "${courseName}".

CRITICAL: Respond entirely in ${detectedLang}.

Analyze ALL the student's mistakes together and provide:
1. A consolidated explanation of what went wrong, identifying patterns of misunderstanding
2. The weak topics they need to review
3. Specific, actionable study tips

Output a JSON object with this exact format:
{
  "explanation": "A detailed 3-5 paragraph analysis in ${detectedLang} explaining the patterns of mistakes, what concepts the student is confused about, and how the correct answers relate to each other. Use markdown formatting (bold, bullet points) for clarity.",
  "weakTopics": ["Topic 1", "Topic 2", "Topic 3"],
  "studyTips": ["Specific tip 1", "Specific tip 2", "Specific tip 3", "Specific tip 4"]
}

IMPORTANT: Output ONLY the JSON object. No markdown code blocks, no explanation outside JSON.`;

      const prompt = `The student got ${wrongQuestions.length} out of ${test.total_count} questions wrong. Here are their mistakes:\n\n${mistakesContext}\n\nAnalyze these mistakes and output the JSON:`;

      const aiResponse = await callReplicate(replicateKey, prompt, systemPrompt, scaledExplainTokens);

      // Parse JSON object (not array)
      let result;
      try {
        const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
        const jsonStr = jsonMatch ? jsonMatch[0] : aiResponse.trim();
        result = JSON.parse(jsonStr);
      } catch {
        // Sanitize and retry
        let sanitized = aiResponse
          .replace(/,\s*}/g, "}")
          .replace(/,\s*\]/g, "]")
          .replace(/'/g, '"');
        const jsonMatch = sanitized.match(/\{[\s\S]*\}/);
        const jsonStr = jsonMatch ? jsonMatch[0] : sanitized.trim();
        try {
          result = JSON.parse(jsonStr);
        } catch {
          // Fallback: return raw text as explanation
          result = {
            explanation: aiResponse.substring(0, 3000),
            weakTopics: [],
            studyTips: [],
          };
        }
      }

      const elapsed = Date.now() - globalStart;
      console.log(`Explain mistakes done: ${wrongQuestions.length} mistakes analyzed (${elapsed}ms)`);

      return new Response(JSON.stringify({
        explanation: typeof result.explanation === "string" ? result.explanation : "",
        weakTopics: Array.isArray(result.weakTopics) ? result.weakTopics.map((t: any) => String(t).substring(0, 100)) : [],
        studyTips: Array.isArray(result.studyTips) ? result.studyTips.map((t: any) => String(t).substring(0, 300)) : [],
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Invalid action" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const elapsed = Date.now() - globalStart;
    const message = error instanceof Error && (
      error.message.includes("unavailable") ||
      error.message.includes("timed out") ||
      error.message.includes("failed. Please") ||
      error.message.includes("Failed to generate") ||
      error.message.includes("timeout") ||
      error.message.includes("Global deadline") ||
      error.message.startsWith("HTTP ")
    ) ? error.message : sanitizeErrorMessage(error);

    console.error(`Quiz function error after ${elapsed}ms:`, message);

    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
