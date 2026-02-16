import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const LLAMA_VERSION = "5a6809ca6288247d06daf6365557e5e429063f32a21146b2a807c682652136b8";
const LLAMA_TEMPLATE = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n{system_prompt}<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n";

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

/**
 * Detect the primary language of a text sample.
 */
function detectLanguageHint(text: string): string {
  if (!text || text.length < 20) return "English";
  
  const sample = text.substring(0, 500).toLowerCase();
  
  const spanishWords = ["que", "los", "las", "del", "una", "con", "por", "para", "como", "m\u00e1s", "esta", "pero", "sobre", "entre", "cuando", "tambi\u00e9n", "puede", "tiene", "desde", "todo", "seg\u00fan", "donde", "despu\u00e9s", "porque", "cada", "hacer", "sin", "ser", "este", "as\u00ed"];
  const spanishChars = /[\u00e1\u00e9\u00ed\u00f3\u00fa\u00f1\u00bf\u00a1]/;
  
  const portugueseWords = ["n\u00e3o", "uma", "com", "s\u00e3o", "mais", "para", "como", "est\u00e1", "pode", "isso", "pelo", "muito", "tamb\u00e9m", "onde", "quando", "ainda", "ent\u00e3o", "sobre", "depois"];
  const portugueseChars = /[\u00e3\u00f5\u00e7]/;
  
  const frenchWords = ["les", "des", "une", "que", "dans", "pour", "avec", "sur", "sont", "pas", "plus", "mais", "comme", "cette", "tout", "\u00eatre", "fait", "aussi", "nous", "m\u00eame"];
  const frenchChars = /[\u00e0\u00e2\u00ea\u00eb\u00ee\u00ef\u00f4\u00f9\u00fb\u00fc\u00ff\u00e7\u0153\u00e6]/;
  
  const germanWords = ["und", "die", "der", "das", "ist", "ein", "eine", "mit", "auf", "f\u00fcr", "nicht", "auch", "sich", "von", "sind", "werden", "hat", "wird", "dass", "oder"];
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

    const body = await req.json();
    const { action } = body;

    if (action === "generate") {
      const { courseId, count = 5 } = body;

      const { data: course } = await supabase
        .from("courses")
        .select("title, subtitle")
        .eq("id", courseId)
        .single();

      const { data: materials } = await supabase
        .from("course_materials")
        .select("title, content, type")
        .eq("course_id", courseId)
        .not("content", "is", null)
        .limit(5);

      let materialContent = "Generate general knowledge questions for the course.";
      if (materials && materials.length > 0) {
        materialContent = materials
          .map((m: any) => `--- ${m.title} ---\n${(m.content || "").substring(0, 2000)}`)
          .join("\n\n");
      }

      // Detect language from materials
      const allContent = materials?.map((m: any) => m.content || "").join(" ") || "";
      const detectedLang = detectLanguageHint(allContent);

      const systemPrompt = `You are a quiz generator for "${course?.title || "Study Course"}".

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
        const jsonMatch = aiResponse.match(/\[[\s\S]*\]/);
        questions = JSON.parse(jsonMatch ? jsonMatch[0] : aiResponse);
      } catch {
        throw new Error("Failed to parse quiz questions from AI response");
      }

      // Create test
      const { data: test } = await supabase
        .from("tests")
        .insert({
          course_id: courseId,
          user_id: user.id,
          title: `${course?.title || "Quiz"} - Quiz`,
          total_count: questions.length,
        })
        .select()
        .single();

      // Insert questions
      const questionRows = questions.map((q: any, i: number) => ({
        test_id: test.id,
        question_number: i + 1,
        question: q.question,
        correct_answer: q.correct_answer,
      }));

      const { data: savedQuestions } = await supabase
        .from("test_questions")
        .insert(questionRows)
        .select();

      return new Response(JSON.stringify({ test, questions: savedQuestions }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    } else if (action === "evaluate") {
      const { testId, answers } = body;

      // Fetch test and questions
      const { data: test } = await supabase
        .from("tests")
        .select("*, courses(title)")
        .eq("id", testId)
        .single();

      const { data: questions } = await supabase
        .from("test_questions")
        .select()
        .eq("test_id", testId)
        .order("question_number", { ascending: true });

      // Detect language from questions for AI insights
      const questionsText = (questions || []).map((q: any) => q.question).join(" ");
      const detectedLang = detectLanguageHint(questionsText);

      // Evaluate each answer
      let correctCount = 0;
      const evaluatedQuestions: any[] = [];

      for (const q of (questions || [])) {
        const userAnswer = answers.find((a: any) => a.questionId === q.id)?.answer || "";

        // Simple comparison (case-insensitive, trimmed)
        const isCorrect = userAnswer.trim().toLowerCase() === q.correct_answer.trim().toLowerCase() ||
          q.correct_answer.toLowerCase().includes(userAnswer.trim().toLowerCase());

        if (isCorrect) correctCount++;

        evaluatedQuestions.push({
          ...q,
          user_answer: userAnswer,
          is_correct: isCorrect,
        });
      }

      // Generate AI insights for wrong answers
      const wrongQuestions = evaluatedQuestions.filter((q) => !q.is_correct);

      if (wrongQuestions.length > 0) {
        const insightPrompt = wrongQuestions.map((q) =>
          `Question: ${q.question}\nStudent Answer: ${q.user_answer}\nCorrect Answer: ${q.correct_answer}`
        ).join("\n\n");

        const sysPrompt = `You are a study tutor. For each wrong answer below, provide a brief (1-2 sentences) educational insight explaining why the student's answer was wrong and helping them remember the correct answer. Use analogies or mnemonics when helpful.

CRITICAL: Respond in ${detectedLang}. The questions and answers are in ${detectedLang}, so your insights must also be in ${detectedLang}.

IMPORTANT: Output ONLY a valid JSON array of strings, one insight per wrong answer. No markdown.`;

        try {
          const aiResponse = await callReplicate(replicateKey, insightPrompt, sysPrompt, 1024);
          const jsonMatch = aiResponse.match(/\[[\s\S]*\]/);
          const insights = JSON.parse(jsonMatch ? jsonMatch[0] : aiResponse);
          wrongQuestions.forEach((q, i) => {
            q.ai_insight = insights[i] || (detectedLang === "Spanish" ? "Revisa este tema para mejorar tu comprensi\u00f3n." : "Review this topic for better understanding.");
          });
        } catch {
          wrongQuestions.forEach((q) => {
            q.ai_insight = detectedLang === "Spanish" ? "Revisa este tema para mejorar tu comprensi\u00f3n." : "Review this topic for better understanding.";
          });
        }
      }

      // Set insights for correct answers
      evaluatedQuestions.filter((q) => q.is_correct).forEach((q) => {
        q.ai_insight = detectedLang === "Spanish" ? "\u00a1Correcto! Buen trabajo." : "Correct! Great job on this one.";
      });

      const totalQ = questions?.length || 1;
      const score = correctCount / totalQ;
      const grade = calculateGrade(score);

      // Generate motivational text in detected language
      let motivationText = "";
      if (detectedLang === "Spanish") {
        if (score >= 0.9) motivationText = "\u00a1Trabajo excepcional! Dominaste este material.";
        else if (score >= 0.7) motivationText = "\u00a1Muy bien! Enfocate en las \u00e1reas que fallaste para mejorar a\u00fan m\u00e1s.";
        else if (score >= 0.5) motivationText = "\u00a1Buen comienzo! Repas\u00e1 los temas que fallaste e intent\u00e1 de nuevo.";
        else motivationText = "\u00a1Segu\u00ed estudiando! Revis\u00e1 los materiales y practic\u00e1 m\u00e1s.";
      } else if (detectedLang === "Portuguese") {
        if (score >= 0.9) motivationText = "Trabalho excelente! Voc\u00ea dominou este material.";
        else if (score >= 0.7) motivationText = "\u00d3timo esfor\u00e7o! Foque nas \u00e1reas que errou para melhorar ainda mais.";
        else if (score >= 0.5) motivationText = "Bom come\u00e7o! Revise os t\u00f3picos e tente novamente.";
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
        .eq("id", testId);

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
    console.error("ai-generate-quiz error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
