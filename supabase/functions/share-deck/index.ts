import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function generateShareCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no I,O,0,1 to avoid confusion
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
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

    // Authenticate user
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

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const body = await req.json();
    const { action } = body;

    // ── SHARE: Generate a share code for a deck ──
    if (action === "share") {
      const { deckId } = body;
      if (!deckId) {
        return new Response(
          JSON.stringify({ error: "deckId is required" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Verify ownership
      const { data: deck, error: deckError } = await adminClient
        .from("flashcard_decks")
        .select("id, user_id, title, card_count")
        .eq("id", deckId)
        .single();

      if (deckError || !deck) {
        return new Response(
          JSON.stringify({ error: "Deck not found" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      if (deck.user_id !== user.id) {
        return new Response(
          JSON.stringify({ error: "You can only share your own decks" }),
          {
            status: 403,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Check if already shared
      const { data: existing } = await adminClient
        .from("shared_decks")
        .select("share_code")
        .eq("deck_id", deckId)
        .eq("user_id", user.id)
        .maybeSingle();

      if (existing) {
        return new Response(
          JSON.stringify({ shareCode: existing.share_code }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Generate unique code with retry
      let shareCode = "";
      let attempts = 0;
      while (attempts < 10) {
        shareCode = generateShareCode();
        const { data: conflict } = await adminClient
          .from("shared_decks")
          .select("id")
          .eq("share_code", shareCode)
          .maybeSingle();
        if (!conflict) break;
        attempts++;
      }

      if (attempts >= 10) {
        return new Response(
          JSON.stringify({ error: "Failed to generate unique code" }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Insert share record
      const { error: insertError } = await adminClient
        .from("shared_decks")
        .insert({
          deck_id: deckId,
          user_id: user.id,
          share_code: shareCode,
        });

      if (insertError) {
        console.error("Insert error:", insertError);
        return new Response(
          JSON.stringify({ error: "Failed to create share code" }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(JSON.stringify({ shareCode }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── IMPORT: Import a shared deck by code ──
    if (action === "import") {
      const { shareCode, courseId } = body;
      if (!shareCode || !courseId) {
        return new Response(
          JSON.stringify({
            error: "shareCode and courseId are required",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Look up share code
      const { data: share, error: shareError } = await adminClient
        .from("shared_decks")
        .select("deck_id, user_id")
        .eq("share_code", shareCode.toUpperCase())
        .maybeSingle();

      if (shareError || !share) {
        return new Response(
          JSON.stringify({ error: "Invalid share code" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Don't import own deck
      if (share.user_id === user.id) {
        return new Response(
          JSON.stringify({ error: "You cannot import your own deck" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Verify target course belongs to user
      const { data: course, error: courseError } = await adminClient
        .from("courses")
        .select("id")
        .eq("id", courseId)
        .eq("user_id", user.id)
        .maybeSingle();

      if (courseError || !course) {
        return new Response(
          JSON.stringify({ error: "Target course not found" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Get original deck
      const { data: originalDeck } = await adminClient
        .from("flashcard_decks")
        .select("title")
        .eq("id", share.deck_id)
        .single();

      if (!originalDeck) {
        return new Response(
          JSON.stringify({ error: "Original deck no longer exists" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Get original cards
      const { data: originalCards } = await adminClient
        .from("flashcards")
        .select("topic, question_before, keyword, question_after, answer, mastery, card_type, image_url, occlusion_data")
        .eq("deck_id", share.deck_id)
        .order("created_at", { ascending: true });

      if (!originalCards || originalCards.length === 0) {
        return new Response(
          JSON.stringify({ error: "No cards found in the shared deck" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Create new deck for importing user
      const { data: newDeck, error: newDeckError } = await adminClient
        .from("flashcard_decks")
        .insert({
          course_id: courseId,
          user_id: user.id,
          title: `${originalDeck.title} (imported)`,
          card_count: originalCards.length,
        })
        .select()
        .single();

      if (newDeckError || !newDeck) {
        console.error("New deck error:", newDeckError);
        return new Response(
          JSON.stringify({ error: "Failed to create deck" }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Create copies of all cards (SRS reset)
      const newCards = originalCards.map((card: any) => ({
        deck_id: newDeck.id,
        topic: card.topic || "",
        question_before: card.question_before || "",
        keyword: card.keyword || "",
        question_after: card.question_after || "",
        answer: card.answer || "",
        mastery: "new",
        card_type: card.card_type || "text",
        image_url: card.image_url || null,
        occlusion_data: card.occlusion_data || null,
        // SRS fields reset to defaults
        stability: 0,
        difficulty: 0,
        elapsed_days: 0,
        scheduled_days: 0,
        reps: 0,
        lapses: 0,
        srs_state: 0,
        due: new Date().toISOString(),
        last_review: null,
      }));

      const { error: cardsError } = await adminClient
        .from("flashcards")
        .insert(newCards);

      if (cardsError) {
        console.error("Cards insert error:", cardsError);
        // Clean up the empty deck
        await adminClient
          .from("flashcard_decks")
          .delete()
          .eq("id", newDeck.id);
        return new Response(
          JSON.stringify({ error: "Failed to import cards" }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(JSON.stringify(newDeck), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── LOOKUP: Preview a shared deck without importing ──
    if (action === "lookup") {
      const { shareCode } = body;
      if (!shareCode) {
        return new Response(
          JSON.stringify({ error: "shareCode is required" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const { data: share } = await adminClient
        .from("shared_decks")
        .select("deck_id")
        .eq("share_code", shareCode.toUpperCase())
        .maybeSingle();

      if (!share) {
        return new Response(
          JSON.stringify({ error: "Invalid share code" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const { data: deck } = await adminClient
        .from("flashcard_decks")
        .select("title, card_count")
        .eq("id", share.deck_id)
        .single();

      if (!deck) {
        return new Response(
          JSON.stringify({ error: "Deck no longer exists" }),
          {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      return new Response(
        JSON.stringify({ title: deck.title, cardCount: deck.card_count }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({ error: "Invalid action. Use: share, import, lookup" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("share-deck error:", error);
    return new Response(
      JSON.stringify({ error: "An internal error occurred" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
