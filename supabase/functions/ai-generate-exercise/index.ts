import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const LLAMA_MODEL = "meta/meta-llama-3-8b-instruct";
const POLL_INTERVAL_MS = 500;
const MAX_POLL_ATTEMPTS = 50;

// ── Deadline protection — Supabase kills at 60s ─────────────────
const HARD_DEADLINE_MS = 50_000; // 50s (10s buffer)
let REQUEST_START = 0;

function isDeadlineClose(): boolean {
  return Date.now() - REQUEST_START > HARD_DEADLINE_MS;
}

// ── Replicate API ────────────────────────────────────────────────
async function callReplicate(prompt: string, maxTokens = 2048): Promise<string> {
  const REPLICATE_API_TOKEN = Deno.env.get("REPLICATE_API_KEY");
  if (!REPLICATE_API_TOKEN) throw new Error("Missing REPLICATE_API_KEY");

  const createRes = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${REPLICATE_API_TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: LLAMA_MODEL,
      input: {
        prompt,
        max_tokens: maxTokens,
        temperature: 0.4,
        top_p: 0.9,
      },
    }),
  });

  if (!createRes.ok) {
    const err = await createRes.text();
    throw new Error(`Replicate create failed: ${err}`);
  }

  const prediction = await createRes.json();
  let url = `https://api.replicate.com/v1/predictions/${prediction.id}`;

  for (let i = 0; i < MAX_POLL_ATTEMPTS; i++) {
    if (isDeadlineClose()) {
      throw new Error("Request timeout: AI processing took too long. Please try again.");
    }
    await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    const pollRes = await fetch(url, {
      headers: { Authorization: `Bearer ${REPLICATE_API_TOKEN}` },
    });
    const data = await pollRes.json();

    if (data.status === "succeeded") {
      const output = Array.isArray(data.output)
        ? data.output.join("")
        : String(data.output ?? "");
      return output;
    }
    if (data.status === "failed" || data.status === "canceled") {
      throw new Error(`Replicate prediction ${data.status}: ${data.error}`);
    }
  }
  throw new Error("Replicate prediction timed out");
}

// ── JSON parser ──────────────────────────────────────────────────
function parseJson(raw: string): any {
  // Try to extract JSON object or array
  const objMatch = raw.match(/\{[\s\S]*\}/);
  const arrMatch = raw.match(/\[[\s\S]*\]/);
  const jsonStr = objMatch ? objMatch[0] : arrMatch ? arrMatch[0] : raw.trim();

  try {
    return JSON.parse(jsonStr);
  } catch {
    const sanitized = jsonStr
      .replace(/,\s*}/g, "}")
      .replace(/,\s*\]/g, "]")
      .replace(/'/g, '"')
      .replace(/\n/g, "\\n");
    return JSON.parse(sanitized);
  }
}

// ── Exercise generators ──────────────────────────────────────────

function fillGapsPrompt(content: string, count: number): string {
  return `You are a study exercise generator. Given this study material, create ${count} fill-in-the-blank sentences.

STUDY MATERIAL:
${content}

Return ONLY a JSON array. Each item must have:
- "sentence": the sentence with "___" replacing ONE key term
- "answer": the correct missing term
- "hint": a one-word hint

Example: [{"sentence":"The process of cell division is called ___","answer":"mitosis","hint":"division"}]

Return ONLY the JSON array, no other text.`;
}

function speedRoundPrompt(content: string): string {
  return `You are a study exercise generator. Given this study material, create 10 true/false statements.

STUDY MATERIAL:
${content}

Return ONLY a JSON array of 10 items. Each item must have:
- "statement": a clear factual statement about the material
- "isTrue": boolean (true or false)
- "explanation": brief explanation why it's true or false (1 sentence)

Make 5 true and 5 false, randomly ordered. Make false statements plausible but clearly wrong.

Return ONLY the JSON array, no other text.`;
}

function mistakeSpotterPrompt(content: string): string {
  return `You are a study exercise generator. Given this study material, create a paragraph with 4 deliberate factual errors mixed with correct information.

STUDY MATERIAL:
${content}

Return ONLY a JSON object with:
- "paragraph": array of 8-10 sentences about the topic. Exactly 4 must contain factual errors, the rest must be correct.
- "errors": array of objects with:
  - "sentenceIndex": index (0-based) of the sentence with the error
  - "correction": the corrected version of that sentence
  - "explanation": why it was wrong (1 sentence)

Return ONLY the JSON object, no other text.`;
}

function teachBotPrompt(content: string): string {
  return `You are a study exercise generator. Given this study material, create a "teach the bot" exercise.

STUDY MATERIAL:
${content}

Return ONLY a JSON object with:
- "topic": the specific topic/concept to explain (short phrase)
- "botQuestion": a confused student question like "I don't understand X, can you explain?"
- "keyPoints": array of 4-5 essential points that a good explanation should cover (short phrases)
- "followUpQuestions": array of 2-3 follow-up questions the bot would ask to test deeper understanding

Return ONLY the JSON object, no other text.`;
}

function compareContrastPrompt(content: string): string {
  return `You are a study exercise generator. Given this study material, create a compare & contrast exercise.

STUDY MATERIAL:
${content}

Find two concepts from the material that are commonly confused or closely related.

Return ONLY a JSON object with:
- "conceptA": name of first concept
- "conceptB": name of second concept
- "traits": array of 8 trait objects, each with:
  - "text": description of the trait
  - "belongsTo": "A", "B", or "both"

Return ONLY the JSON object, no other text.`;
}

function timelinePrompt(content: string): string {
  return `You are a study exercise generator. Given this study material, create a timeline/sequence ordering exercise.

STUDY MATERIAL:
${content}

Find a process, sequence, or chronological series from the material with 6-8 steps.

Return ONLY a JSON object with:
- "title": name of the process/sequence
- "steps": array of objects in CORRECT order, each with:
  - "id": unique string id
  - "text": description of this step (1-2 sentences)

Return ONLY the JSON object, no other text.`;
}

function caseStudyPrompt(content: string): string {
  return `You are a study exercise generator. Given this study material, create a mini case study exercise.

STUDY MATERIAL:
${content}

Create a realistic scenario that applies the concepts from the material.

Return ONLY a JSON object with:
- "scenario": 2-3 paragraph scenario description (realistic situation)
- "questions": array of 3 question objects, each with:
  - "question": the question text
  - "correctAnswer": the ideal answer (2-3 sentences)
  - "keyTerms": array of 2-3 key terms that should appear in a good answer

Return ONLY the JSON object, no other text.`;
}

function matchBlitzPrompt(content: string): string {
  return `You are a study exercise generator. Given this study material, create a matching exercise.

STUDY MATERIAL:
${content}

Return ONLY a JSON object with:
- "pairs": array of 6 pair objects, each with:
  - "id": unique string id
  - "concept": the term/concept name
  - "definition": its definition or description (1 sentence)

Return ONLY the JSON object, no other text.`;
}

function conceptMapPrompt(content: string): string {
  return `You are a study exercise generator. Given this study material, create a concept map exercise.

STUDY MATERIAL:
${content}

Create a concept map with nodes and connections. Some connections should be missing for the student to fill in.

Return ONLY a JSON object with:
- "centralConcept": the main topic
- "nodes": array of 6-8 concept objects, each with:
  - "id": unique string id
  - "label": concept name
- "connections": array of connection objects, each with:
  - "from": source node id
  - "to": target node id
  - "label": relationship label (e.g., "is part of", "causes", "produces")
  - "isHidden": boolean (true if student must fill this connection, false if shown)
At least 3-4 connections should have isHidden: true.

Return ONLY the JSON object, no other text.`;
}

// ── Main handler ─────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  REQUEST_START = Date.now();

  try {
    const authHeader = req.headers.get("Authorization");
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Auth check
    const supabase = createClient(supabaseUrl, supabaseKey);
    if (authHeader) {
      const token = authHeader.replace("Bearer ", "");
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);
      if (authError || !user) {
        return new Response(
          JSON.stringify({ error: "Unauthorized" }),
          { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    const body = await req.json();
    const { exerciseType, courseId, materialContent } = body;

    if (!exerciseType || !courseId) {
      return new Response(
        JSON.stringify({ error: "Missing exerciseType or courseId" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get course content if not provided
    let content = materialContent;
    if (!content) {
      // Fetch materials for this course
      const { data: materials } = await supabase
        .from("course_materials")
        .select("content, title")
        .eq("course_id", courseId)
        .limit(3);

      if (!materials || materials.length === 0) {
        return new Response(
          JSON.stringify({ error: "No materials found for this course" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      content = materials
        .map((m: any) => `## ${m.title}\n${(m.content || "").substring(0, 3000)}`)
        .join("\n\n");
    }

    // Truncate to prevent token overflow
    const maxContentLength = 6000;
    if (content.length > maxContentLength) {
      content = content.substring(0, maxContentLength);
    }

    // Generate prompt based on exercise type
    let prompt: string;
    switch (exerciseType) {
      case "fillGaps":
        prompt = fillGapsPrompt(content, body.count || 6);
        break;
      case "speedRound":
        prompt = speedRoundPrompt(content);
        break;
      case "mistakeSpotter":
        prompt = mistakeSpotterPrompt(content);
        break;
      case "teachBot":
        prompt = teachBotPrompt(content);
        break;
      case "compareContrast":
        prompt = compareContrastPrompt(content);
        break;
      case "timeline":
        prompt = timelinePrompt(content);
        break;
      case "caseStudy":
        prompt = caseStudyPrompt(content);
        break;
      case "matchBlitz":
        prompt = matchBlitzPrompt(content);
        break;
      case "conceptMap":
        prompt = conceptMapPrompt(content);
        break;
      default:
        return new Response(
          JSON.stringify({ error: `Unknown exercise type: ${exerciseType}` }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }

    console.log(`Generating ${exerciseType} exercise for course ${courseId}`);
    const raw = await callReplicate(prompt);
    const result = parseJson(raw);

    return new Response(
      JSON.stringify({ exercise: result, type: exerciseType }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("ai-generate-exercise error:", error);
    const message = error instanceof Error && (
      error.message.includes("timeout") ||
      error.message.includes("timed out") ||
      error.message.includes("unavailable") ||
      error.message.includes("failed")
    ) ? error.message : "Failed to generate exercise. Please try again.";
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
