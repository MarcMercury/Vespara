// Supabase Edge Function: Conversation Resuscitator
// Generates opener messages to revive stale conversations

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ALLOWED_ORIGINS = [
  "https://kult.vercel.app",
  "https://www.kult.app",
  "http://localhost:3000",
];

function getCorsHeaders(req: Request) {
  const origin = req.headers.get("Origin") || "";
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

const MAX_NAME_LENGTH = 50;
const MAX_MESSAGES_LENGTH = 1000;
const MAX_INTERESTS_LENGTH = 500;

interface ResuscitatorRequest {
  matchName: string;
  lastMessages: string;
  matchInterests?: string;
  daysSinceContact: number;
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !supabaseServiceKey) {
      console.error("Missing required environment variables");
      return new Response(
        JSON.stringify({ error: "Server misconfigured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body: ResuscitatorRequest = await req.json();
    const { matchName, lastMessages, matchInterests, daysSinceContact } = body;

    // Validate
    if (!matchName || typeof matchName !== "string") {
      return new Response(
        JSON.stringify({ error: "matchName is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (typeof daysSinceContact !== "number" || daysSinceContact < 0 || daysSinceContact > 3650) {
      return new Response(
        JSON.stringify({ error: "daysSinceContact must be between 0 and 3650" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Sanitize
    const safeName = matchName.slice(0, MAX_NAME_LENGTH).replace(/[<>"'`]/g, "");
    const safeMessages = (lastMessages || "None available").slice(0, MAX_MESSAGES_LENGTH).replace(/[<>"'`]/g, "");
    const safeInterests = matchInterests ? matchInterests.slice(0, MAX_INTERESTS_LENGTH).replace(/[<>"'`]/g, "") : "Unknown";

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) {
      console.error("OPENAI_API_KEY not set");
      return new Response(
        JSON.stringify({ error: "Server misconfigured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const systemPrompt = `You are a witty connection coach helping revive a stale conversation. Generate an opener that:
- Feels natural, not forced or desperate
- References something specific if context is provided
- Has a hook that invites a response
- Matches the energy of modern community chat apps
- Is confident without being arrogant

Keep it to 1-2 sentences. No emojis unless the context suggests they use them.`;

    const userPrompt = `Revive this conversation with "${safeName}".
Last messages: ${safeMessages}
Their interests: ${safeInterests}
Days since last contact: ${daysSinceContact}

Generate a single opener message to restart the conversation.`;

    const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4-turbo",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.9,
        max_tokens: 100,
      }),
    });

    const openaiData = await openaiResponse.json();

    if (!openaiResponse.ok) {
      console.error("OpenAI API error:", openaiData.error?.message);
      return new Response(
        JSON.stringify({ error: "Failed to generate message" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const message = openaiData.choices[0]?.message?.content || "Hey! Been a while - how have you been?";

    return new Response(
      JSON.stringify({ message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Resuscitator error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
