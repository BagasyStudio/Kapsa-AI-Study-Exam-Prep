import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const DEEPSEEK_OCR_VERSION = "cb3b474fbfc56b1664c8c7841550bccecbe7b74c30e45ce938ffca1180b4dff5";
const WHISPER_VERSION = "3ab86df6c8f54c11309d4d1f930ac292bad43ace52d10c80d87eb258b3c9f79c";

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
  // Never leak internal error details to the client
  console.error("process-capture internal error:", error);
  return "An internal error occurred while processing your request.";
}

// ── AI processing functions ───────────────────────────────────────
async function runOCR(apiKey: string, imageUrl: string): Promise<string> {
  const createRes = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: DEEPSEEK_OCR_VERSION,
      input: {
        image: imageUrl,
      },
    }),
  });

  if (!createRes.ok) {
    const errBody = await createRes.text();
    console.error("OCR API error:", createRes.status, errBody);
    throw new Error("OCR service unavailable. Please try again.");
  }

  const prediction = await createRes.json();
  let result = prediction;
  let attempts = 0;
  while (result.status !== "succeeded" && result.status !== "failed" && attempts < 120) {
    await new Promise((resolve) => setTimeout(resolve, 1500));
    const pollRes = await fetch(result.urls.get, {
      headers: { "Authorization": `Bearer ${apiKey}` },
    });
    result = await pollRes.json();
    attempts++;
  }

  if (result.status === "failed") {
    console.error("OCR prediction failed:", result.error);
    throw new Error("OCR processing failed. Please try again.");
  }

  if (result.status !== "succeeded") {
    throw new Error("OCR processing timed out. Please try again.");
  }

  // DeepSeek OCR returns markdown text
  const output = Array.isArray(result.output) ? result.output.join("") : String(result.output);

  if (!output || output.trim().length === 0) {
    throw new Error("No text found in the document. Make sure the PDF contains readable text.");
  }

  return output;
}

async function runWhisper(apiKey: string, audioUrl: string): Promise<string> {
  const createRes = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      version: WHISPER_VERSION,
      input: {
        audio: audioUrl,
        task: "transcribe",
        batch_size: 64,
      },
    }),
  });

  if (!createRes.ok) {
    throw new Error("Transcription service unavailable");
  }

  const prediction = await createRes.json();
  let result = prediction;
  let attempts = 0;
  while (result.status !== "succeeded" && result.status !== "failed" && attempts < 120) {
    await new Promise((resolve) => setTimeout(resolve, 2000));
    const pollRes = await fetch(result.urls.get, {
      headers: { "Authorization": `Bearer ${apiKey}` },
    });
    result = await pollRes.json();
    attempts++;
  }

  if (result.status === "failed") {
    throw new Error("Transcription failed. Please try again.");
  }

  if (result.status !== "succeeded") {
    throw new Error("Transcription timed out. Please try again.");
  }

  if (typeof result.output === "object" && result.output !== null && result.output.text) {
    return result.output.text;
  }
  return typeof result.output === "string" ? result.output : String(result.output);
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

    const { courseId, type, fileUrl, title } = await req.json();

    // ── Input validation ──────────────────────────────────────────
    if (!isValidUUID(courseId)) {
      return new Response(JSON.stringify({ error: "Invalid course ID" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (type !== "ocr" && type !== "whisper") {
      return new Response(JSON.stringify({ error: "Invalid type. Use 'ocr' or 'whisper'." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!isValidUrl(fileUrl)) {
      return new Response(JSON.stringify({ error: "Invalid file URL" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Ownership check: verify course belongs to user ────────────
    const { data: course, error: courseError } = await supabase
      .from("courses")
      .select("id")
      .eq("id", courseId)
      .eq("user_id", user.id)
      .single();

    if (courseError || !course) {
      return new Response(JSON.stringify({ error: "Course not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Process file ──────────────────────────────────────────────
    let extractedText = "";
    let materialType = "notes";

    if (type === "ocr") {
      extractedText = await runOCR(replicateKey, fileUrl);
      materialType = "pdf";
    } else {
      extractedText = await runWhisper(replicateKey, fileUrl);
      materialType = "audio";
    }

    // Sanitize title input
    const sanitizedTitle = typeof title === "string" && title.trim().length > 0
      ? title.trim().substring(0, 200)
      : `${type === "ocr" ? "Scanned" : "Transcribed"} - ${new Date().toLocaleDateString()}`;

    // Save as course material
    const { data: material } = await supabase
      .from("course_materials")
      .insert({
        course_id: courseId,
        user_id: user.id,
        title: sanitizedTitle,
        type: materialType,
        content: extractedText,
        file_url: fileUrl,
      })
      .select()
      .single();

    return new Response(JSON.stringify(material), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    // Known user-facing errors (thrown explicitly above)
    const message = error instanceof Error && (
      error.message.includes("unavailable") ||
      error.message.includes("timed out") ||
      error.message.includes("failed. Please")
    ) ? error.message : sanitizeErrorMessage(error);

    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
