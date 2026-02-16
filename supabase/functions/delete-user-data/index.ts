import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

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
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Use anon key + user's auth header to verify identity
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userId = user.id;
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Delete in correct order to respect foreign keys
    // 1. Chat messages (via session ids)
    const { data: sessions } = await adminClient
      .from("chat_sessions")
      .select("id")
      .eq("user_id", userId);
    const sessionIds = (sessions || []).map((s: any) => s.id);
    if (sessionIds.length > 0) {
      await adminClient.from("chat_messages").delete().in("session_id", sessionIds);
    }
    await adminClient.from("chat_sessions").delete().eq("user_id", userId);

    // 2. Flashcards (via deck ids)
    const { data: decks } = await adminClient
      .from("flashcard_decks")
      .select("id")
      .eq("user_id", userId);
    const deckIds = (decks || []).map((d: any) => d.id);
    if (deckIds.length > 0) {
      await adminClient.from("flashcards").delete().in("deck_id", deckIds);
    }
    await adminClient.from("flashcard_decks").delete().eq("user_id", userId);

    // 3. Test questions (via test ids)
    const { data: tests } = await adminClient
      .from("tests")
      .select("id")
      .eq("user_id", userId);
    const testIds = (tests || []).map((t: any) => t.id);
    if (testIds.length > 0) {
      await adminClient.from("test_questions").delete().in("test_id", testIds);
    }
    await adminClient.from("tests").delete().eq("user_id", userId);

    // 4. Course materials & courses
    await adminClient.from("course_materials").delete().eq("user_id", userId);
    await adminClient.from("courses").delete().eq("user_id", userId);

    // 5. Calendar events
    await adminClient.from("calendar_events").delete().eq("user_id", userId);

    // 6. Usage tracking
    await adminClient.from("usage_tracking").delete().eq("user_id", userId);

    // 7. Profile
    await adminClient.from("profiles").delete().eq("id", userId);

    // 8. Finally delete the auth user
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
    if (deleteError) {
      console.error("Failed to delete auth user:", deleteError);
      return new Response(JSON.stringify({ error: "Failed to delete auth user" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, message: "Account deleted successfully" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("delete-user-data error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});