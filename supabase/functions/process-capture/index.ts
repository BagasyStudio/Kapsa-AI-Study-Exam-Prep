import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function runOCR(apiKey: string, imageUrl: string): Promise<string> {
  const createRes = await fetch("https://api.replicate.com/v1/models/google-deepmind/gemma-3-27b-it/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      input: {
        image: imageUrl,
        prompt: "Extract ALL text from this image. Preserve the original formatting, paragraphs, and structure. Return only the extracted text, nothing else. If the text is in a language other than English, keep it in the original language.",
        max_new_tokens: 4096,
        temperature: 0.1,
      },
    }),
  });

  if (!createRes.ok) {
    const errBody = await createRes.text();
    throw new Error(`OCR API error ${createRes.status}: ${errBody}`);
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
    throw new Error(`OCR failed: ${result.error}`);
  }

  if (result.status !== "succeeded") {
    throw new Error("OCR prediction timed out");
  }

  // Gemma 3 returns output as array of strings or a single string
  return Array.isArray(result.output) ? result.output.join("") : String(result.output);
}

async function runWhisper(apiKey: string, audioUrl: string): Promise<string> {
  const createRes = await fetch("https://api.replicate.com/v1/models/vaibhavs10/incredibly-fast-whisper/predictions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      input: {
        audio: audioUrl,
        task: "transcribe",
        batch_size: 64,
      },
    }),
  });

  if (!createRes.ok) {
    const errBody = await createRes.text();
    throw new Error(`Whisper API error ${createRes.status}: ${errBody}`);
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
    throw new Error(`Whisper transcription failed: ${result.error}`);
  }

  if (result.status !== "succeeded") {
    throw new Error("Whisper transcription timed out");
  }

  // Whisper returns { text: "...", chunks: [...] }
  if (typeof result.output === "object" && result.output !== null && result.output.text) {
    return result.output.text;
  }
  return typeof result.output === "string" ? result.output : String(result.output);
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

    const { courseId, type, fileUrl, title } = await req.json();

    let extractedText = "";
    let materialType = "notes";

    if (type === "ocr") {
      extractedText = await runOCR(replicateKey, fileUrl);
      materialType = "pdf";
    } else if (type === "whisper") {
      extractedText = await runWhisper(replicateKey, fileUrl);
      materialType = "audio";
    } else {
      throw new Error("Invalid type. Use 'ocr' or 'whisper'.");
    }

    // Save as course material
    const { data: material } = await supabase
      .from("course_materials")
      .insert({
        course_id: courseId,
        user_id: user.id,
        title: title || `${type === "ocr" ? "Scanned" : "Transcribed"} - ${new Date().toLocaleDateString()}`,
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
    console.error("process-capture error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});