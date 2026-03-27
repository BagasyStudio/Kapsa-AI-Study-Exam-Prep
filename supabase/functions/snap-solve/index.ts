import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { checkAndRecordUsage } from "../_shared/usage.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Llama 3.2 Vision 11B — ~$0.008/run (54x cheaper than Gemma 3 27B)
const VISION_MODEL_VERSION = "d4e81fc1472556464f1ee5cea4de177b2fe95a6eaadb5f63335df1ba654597af";

// ── Input validation helpers ──────────────────────────────────────
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isValidUUID(value: unknown): value is string {
  return typeof value === "string" && UUID_REGEX.test(value);
}

function isValidUrl(value: unknown): value is string {
  if (typeof value !== "string") return false;
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:";
  } catch {
    return false;
  }
}

function sanitizeErrorMessage(error: unknown): string {
  console.error("snap-solve internal error:", error);
  return "An internal error occurred while solving. Please try again.";
}

// ── Language detection ────────────────────────────────────────────
function detectLanguageFromPrompt(): string {
  // The vision model will auto-detect language from the image content.
  // We instruct it to respond in the same language as the problem.
  return "Detect the language of the problem in the image and respond ENTIRELY in that same language. If the problem is in Spanish, respond in Spanish. If in English, respond in English. If in Portuguese, respond in Portuguese. Match the language exactly.";
}

// ── JSON parsing with sanitization ───────────────────────────────
function parseJsonObject(raw: string): any {
  // Extract JSON object from the response
  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  const jsonStr = jsonMatch ? jsonMatch[0] : raw.trim();

  try {
    return JSON.parse(jsonStr);
  } catch {
    // Continue to sanitization
  }

  // Sanitize common LLM JSON issues
  let sanitized = jsonStr
    .replace(/,\s*}/g, "}")        // trailing comma before }
    .replace(/,\s*\]/g, "]")       // trailing comma before ]
    .replace(/'/g, '"')            // single quotes → double quotes
    .replace(/\n/g, "\\n")         // unescaped newlines in strings
    .replace(/\t/g, "\\t");        // unescaped tabs

  return JSON.parse(sanitized);
}

// ── Deadline protection — Supabase kills at 60s ─────────────────
const HARD_DEADLINE_MS = 50_000; // 50s (10s buffer)
const MAX_POLL_ATTEMPTS = 50;
let REQUEST_START = 0;

function isDeadlineClose(): boolean {
  return Date.now() - REQUEST_START > HARD_DEADLINE_MS;
}

// ── AI solve function ────────────────────────────────────────────
async function solveWithVisionModel(apiKey: string, imageUrl: string): Promise<any> {
  const langInstruction = detectLanguageFromPrompt();

  const prompt = `You are an expert tutor that solves academic problems step by step.

${langInstruction}

Look at the image carefully. It contains an academic problem (math, physics, chemistry, biology, or other subject).

Your task:
1. Identify the problem in the image
2. Determine the subject area
3. Solve it step by step with clear explanations
4. Provide the final answer

You MUST respond with ONLY a valid JSON object in this exact format (no markdown, no extra text):
{
  "problem": "The problem as written/shown in the image",
  "subject": "Mathematics|Physics|Chemistry|Biology|Other",
  "steps": [
    {
      "step": 1,
      "title": "Short step title",
      "content": "Detailed explanation of this step",
      "formula": "Mathematical formula if applicable, or null"
    }
  ],
  "final_answer": "The final answer clearly stated",
  "explanation": "Brief summary of the solution approach (1-2 sentences)"
}

Important rules:
- Include 2-6 steps depending on complexity
- Each step should be clear and educational
- Use LaTeX notation for all formulas. Wrap inline math in single $ delimiters (e.g., $x^2$) and display math in double $$ delimiters (e.g., $$\\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}$$). Always use LaTeX commands like \\frac, \\sqrt, \\sum, \\int, etc.
- The "formula" field should be null if no formula is needed for that step
- Keep explanations concise but thorough
- Respond ONLY with the JSON object, nothing else`;

  const createRes = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: VISION_MODEL_VERSION,
      input: {
        image: imageUrl,
        prompt: prompt,
        max_new_tokens: 4096,
        temperature: 0.3,
      },
    }),
  });

  if (!createRes.ok) {
    const errBody = await createRes.text();
    console.error("Vision model API error:", createRes.status, errBody);
    throw new Error(`AI solver unavailable (${createRes.status}): ${errBody.substring(0, 200)}`);
  }

  const prediction = await createRes.json();
  let result = prediction;
  let attempts = 0;
  while (result.status !== "succeeded" && result.status !== "failed" && attempts < MAX_POLL_ATTEMPTS) {
    if (isDeadlineClose()) {
      throw new Error("Request timeout: AI processing took too long. Please try again.");
    }
    await new Promise((resolve) => setTimeout(resolve, 1500));
    const pollRes = await fetch(result.urls.get, {
      headers: { "Authorization": `Bearer ${apiKey}` },
    });
    if (!pollRes.ok) {
      const pollErr = await pollRes.text();
      console.error("Polling error:", pollRes.status, pollErr);
      throw new Error(`AI service unavailable during polling (${pollRes.status}): ${pollErr.substring(0, 200)}`);
    }
    result = await pollRes.json();
    attempts++;
  }

  if (result.status === "failed") {
    const failMsg = result.error || "Unknown prediction error";
    console.error("Vision prediction failed:", failMsg);
    throw new Error(`Problem solving failed: ${String(failMsg).substring(0, 200)}`);
  }

  if (result.status !== "succeeded") {
    throw new Error(`Problem solving timed out after ${attempts} attempts (status: ${result.status})`);
  }

  const output = Array.isArray(result.output) ? result.output.join("") : String(result.output);

  if (!output || output.trim().length === 0) {
    throw new Error("Could not analyze the image. Please try again with a clearer photo.");
  }

  // Parse the JSON solution
  let solution;
  try {
    solution = parseJsonObject(output);
  } catch (parseError) {
    console.error("JSON parse failed, raw output:", output.substring(0, 500));

    // Retry with stricter prompt
    const retryRes = await retryWithStricterPrompt(apiKey, imageUrl);
    solution = parseJsonObject(retryRes);
  }

  // Validate required fields
  if (!solution.problem || !solution.steps || !Array.isArray(solution.steps) || solution.steps.length === 0) {
    throw new Error("Could not generate a valid solution. Please try again.");
  }

  // Ensure all steps have required fields
  solution.steps = solution.steps.map((s: any, i: number) => ({
    step: s.step || i + 1,
    title: s.title || `Step ${i + 1}`,
    content: s.content || "",
    formula: s.formula || null,
  }));

  return {
    problem: String(solution.problem || ""),
    subject: String(solution.subject || "Other"),
    steps: solution.steps,
    final_answer: String(solution.final_answer || solution.finalAnswer || ""),
    explanation: String(solution.explanation || ""),
  };
}

// ── Retry with stricter prompt ───────────────────────────────────
async function retryWithStricterPrompt(apiKey: string, imageUrl: string): Promise<string> {
  console.log("Retrying with stricter prompt...");

  const prompt = `Look at this image. It contains a problem. Solve it and respond with ONLY a JSON object. No markdown. No backticks. Just pure JSON.

Format:
{"problem":"...","subject":"...","steps":[{"step":1,"title":"...","content":"...","formula":null}],"final_answer":"...","explanation":"..."}`;

  const createRes = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: VISION_MODEL_VERSION,
      input: {
        image: imageUrl,
        prompt: prompt,
        max_new_tokens: 4096,
        temperature: 0.1,
      },
    }),
  });

  if (!createRes.ok) {
    const errBody = await createRes.text();
    console.error("Vision retry API error:", createRes.status, errBody);
    throw new Error(`AI solver unavailable on retry (${createRes.status}): ${errBody.substring(0, 200)}`);
  }

  const prediction = await createRes.json();
  let result = prediction;
  let attempts = 0;
  while (result.status !== "succeeded" && result.status !== "failed" && attempts < MAX_POLL_ATTEMPTS) {
    if (isDeadlineClose()) {
      throw new Error("Request timeout: AI processing took too long. Please try again.");
    }
    await new Promise((resolve) => setTimeout(resolve, 1500));
    const pollRes = await fetch(result.urls.get, {
      headers: { "Authorization": `Bearer ${apiKey}` },
    });
    if (!pollRes.ok) {
      const pollErr = await pollRes.text();
      console.error("Retry polling error:", pollRes.status, pollErr);
      throw new Error(`AI service unavailable during retry polling (${pollRes.status}): ${pollErr.substring(0, 200)}`);
    }
    result = await pollRes.json();
    attempts++;
  }

  if (result.status !== "succeeded") {
    const failMsg = result.error || result.status || "unknown";
    throw new Error(`Could not solve after retry (status: ${failMsg}). Please try again.`);
  }

  return Array.isArray(result.output) ? result.output.join("") : String(result.output);
}

// ── Main handler ──────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  REQUEST_START = Date.now();

  // Early check: is the AI service configured?
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
    const usage = await checkAndRecordUsage(supabase, user.id, "snap_solve");
    if (!usage.allowed) {
      return new Response(JSON.stringify({ error: usage.reason }), {
        status: 429,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { imageUrl, courseId } = await req.json();

    // ── Input validation ──────────────────────────────────────────
    if (!isValidUrl(imageUrl)) {
      return new Response(JSON.stringify({ error: "Invalid image URL" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (courseId !== undefined && courseId !== null && !isValidUUID(courseId)) {
      return new Response(JSON.stringify({ error: "Invalid course ID" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Solve the problem ─────────────────────────────────────────
    const solution = await solveWithVisionModel(replicateKey, imageUrl);

    // ── Save to database ──────────────────────────────────────────
    const insertData: any = {
      user_id: user.id,
      image_url: imageUrl,
      problem_text: solution.problem.substring(0, 2000),
      subject: solution.subject.substring(0, 100),
      solution: solution,
    };

    if (courseId) {
      // Verify course ownership
      const { data: course } = await supabase
        .from("courses")
        .select("id")
        .eq("id", courseId)
        .eq("user_id", user.id)
        .single();

      if (course) {
        insertData.course_id = courseId;
      }
    }

    const { data: saved, error: insertError } = await supabase
      .from("snap_solutions")
      .insert(insertData)
      .select()
      .single();

    if (insertError) {
      console.error("Insert error:", insertError);
      // Still return the solution even if save fails
      return new Response(JSON.stringify({
        ...solution,
        id: null,
        saved: false,
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({
      id: saved.id,
      problem: solution.problem,
      subject: solution.subject,
      steps: solution.steps,
      final_answer: solution.final_answer,
      explanation: solution.explanation,
      image_url: imageUrl,
      created_at: saved.created_at,
      saved: true,
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const message = error instanceof Error && (
      error.message.includes("unavailable") ||
      error.message.includes("timed out") ||
      error.message.includes("failed") ||
      error.message.includes("Could not") ||
      error.message.includes("retry")
    ) ? error.message : sanitizeErrorMessage(error);

    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
