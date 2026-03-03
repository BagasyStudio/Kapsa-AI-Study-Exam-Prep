import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const LLAMA_MODEL = "meta/meta-llama-3-8b-instruct";

function buildLlamaPrompt(systemPrompt: string, userPrompt: string): string {
  return `<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n${systemPrompt}<|eot_id|><|start_header_id|>user<|end_header_id|>\n\n${userPrompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n`;
}

async function callReplicate(
  apiKey: string,
  systemPrompt: string,
  userPrompt: string,
  maxTokens = 1024
): Promise<string> {
  const response = await fetch(`https://api.replicate.com/v1/models/${LLAMA_MODEL}/predictions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      input: {
        prompt: buildLlamaPrompt(systemPrompt, userPrompt),
      },
    }),
  });

  if (!response.ok) {
    throw new Error("AI service unavailable");
  }

  const prediction = await response.json();

  // Poll for result
  let result = prediction;
  let attempts = 0;
  while (
    result.status !== "succeeded" &&
    result.status !== "failed" &&
    attempts < 120
  ) {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    const pollRes = await fetch(result.urls.get, {
      headers: { Authorization: `Bearer ${apiKey}` },
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

  return Array.isArray(result.output)
    ? result.output.join("")
    : String(result.output);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const replicateApiToken = Deno.env.get("REPLICATE_API_KEY")!;

    // Verify user
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { materialId, courseId } = await req.json();
    if (!materialId || !courseId) {
      return new Response(
        JSON.stringify({ error: "materialId and courseId are required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Fetch material content
    const { data: material, error: materialError } = await adminClient
      .from("course_materials")
      .select("title, content, type")
      .eq("id", materialId)
      .single();

    if (materialError || !material) {
      return new Response(
        JSON.stringify({ error: "Material not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const content = material.content || "";
    if (content.length < 50) {
      return new Response(
        JSON.stringify({
          error: "Material content is too short for a summary",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 1: Generate summary using LLM
    const truncatedContent = content.substring(0, 8000);
    const systemPrompt =
      "You are a study assistant. Create a concise spoken-word summary. " +
      "The summary should be clear, engaging, and suitable for audio listening (2-3 minutes when read aloud). " +
      "Focus on key concepts, definitions, and important relationships. " +
      "Write it as natural speech, not bullet points. " +
      "Do NOT include any markdown formatting.";

    const userPrompt = `Material title: ${material.title}\n\nContent:\n${truncatedContent}\n\nSummary:`;

    let summaryText: string;
    try {
      summaryText = await callReplicate(
        replicateApiToken,
        systemPrompt,
        userPrompt,
        1024
      );
    } catch (llmError) {
      console.error("LLM error:", llmError);
      return new Response(
        JSON.stringify({ error: "Failed to generate summary" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!summaryText || summaryText.length < 20) {
      return new Response(
        JSON.stringify({ error: "Generated summary was too short" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Step 2: Generate TTS audio via Replicate
    const ttsResponse = await fetch(
      "https://api.replicate.com/v1/predictions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${replicateApiToken}`,
          "Content-Type": "application/json",
          Prefer: "wait",
        },
        body: JSON.stringify({
          version:
            "684bc3855b37866c0c65add2ff39c78f3dea3f4ff103a436465326e0f438d55e",
          input: {
            text: summaryText.substring(0, 3000),
            language: "en",
            speaker:
              "https://replicate.delivery/pbxt/Jt79w0xsT64R1JsiJ0LQZI8st4O0xxGnHHEFRM2kQ4jbEbvT/male.wav",
            cleanup_voice: false,
          },
        }),
      }
    );

    const ttsResult = await ttsResponse.json();
    if (ttsResult.error) {
      console.error("TTS error:", ttsResult.error);
      // Still save summary text even if TTS fails
      const { data: record, error: insertError } = await adminClient
        .from("audio_summaries")
        .insert({
          user_id: user.id,
          material_id: materialId,
          course_id: courseId,
          title: `Summary: ${material.title}`,
          audio_url: "",
          summary_text: summaryText,
          status: "text_only",
        })
        .select()
        .single();

      if (insertError) {
        return new Response(
          JSON.stringify({ error: "Failed to save summary" }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(JSON.stringify(record), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get audio URL from TTS result
    const audioOutputUrl = ttsResult.output;
    if (!audioOutputUrl) {
      // Fallback: text_only
      const { data: record } = await adminClient
        .from("audio_summaries")
        .insert({
          user_id: user.id,
          material_id: materialId,
          course_id: courseId,
          title: `Summary: ${material.title}`,
          audio_url: "",
          summary_text: summaryText,
          status: "text_only",
        })
        .select()
        .single();

      return new Response(JSON.stringify(record), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Step 3: Download audio and upload to Supabase Storage
    const audioResponse = await fetch(audioOutputUrl);
    const audioBlob = await audioResponse.arrayBuffer();
    const audioFileName = `audio-summaries/${user.id}/${materialId}-${Date.now()}.wav`;

    const { error: uploadError } = await adminClient.storage
      .from("user-uploads")
      .upload(audioFileName, audioBlob, {
        contentType: "audio/wav",
        upsert: true,
      });

    let finalAudioUrl = audioOutputUrl; // fallback to replicate URL
    if (!uploadError) {
      const {
        data: { publicUrl },
      } = adminClient.storage.from("user-uploads").getPublicUrl(audioFileName);
      finalAudioUrl = publicUrl;
    }

    // Estimate duration (~150 words per minute)
    const wordCount = summaryText.split(/\s+/).length;
    const estimatedDuration = Math.round((wordCount / 150) * 60);

    // Step 4: Insert record
    const { data: record, error: insertError } = await adminClient
      .from("audio_summaries")
      .insert({
        user_id: user.id,
        material_id: materialId,
        course_id: courseId,
        title: `Summary: ${material.title}`,
        audio_url: finalAudioUrl,
        duration_seconds: estimatedDuration,
        summary_text: summaryText,
        status: "ready",
      })
      .select()
      .single();

    if (insertError) {
      console.error("Insert error:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to save audio summary" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(JSON.stringify(record), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("generate-audio-summary error:", error);
    return new Response(
      JSON.stringify({ error: "An internal error occurred" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
