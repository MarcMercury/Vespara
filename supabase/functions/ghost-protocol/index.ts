// Supabase Edge Function: Ghost Protocol
// Generates polite closure messages using OpenAI

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

const VALID_TONES = ["kind", "honest", "brief"] as const;
const MAX_NAME_LENGTH = 50;
const MAX_CONTEXT_LENGTH = 500;

interface GhostRequest {
  matchName: string;
  tone: typeof VALID_TONES[number];
  duration: number;
  context?: string;
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

    const body: GhostRequest = await req.json();
    const { matchName, tone, duration, context } = body;

    // Validate inputs
    if (!matchName || typeof matchName !== "string") {
      return new Response(
        JSON.stringify({ error: "matchName is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!VALID_TONES.includes(tone)) {
      return new Response(
        JSON.stringify({ error: "tone must be one of: kind, honest, brief" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (typeof duration !== "number" || duration < 0 || duration > 3650) {
      return new Response(
        JSON.stringify({ error: "duration must be a number between 0 and 3650" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Sanitize inputs
    const safeName = matchName.slice(0, MAX_NAME_LENGTH).replace(/[<>"'`]/g, "");
    const safeContext = context ? context.slice(0, MAX_CONTEXT_LENGTH).replace(/[<>"'`]/g, "") : undefined;

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) {
      console.error("OPENAI_API_KEY not set");
      return new Response(
        JSON.stringify({ error: "Server misconfigured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const toneInstructions = {
      kind: "Be warm, appreciative, and wish them well. Focus on positive memories.",
      honest: "Be direct but respectful. Acknowledge the situation honestly without being harsh.",
      brief: "Keep it short and simple. One or two sentences maximum. No fluff.",
    };

    const systemPrompt = `You are helping someone end a connection gracefully. Generate a closure message that is respectful and mature.

Tone: ${toneInstructions[tone]}

Guidelines:
- Never be mean or hurtful
- Don't overly explain or make excuses
- Keep it genuine, not robotic
- No clichés like "it's not you, it's me"
- Match the formality to how long they've been talking`;

    const userPrompt = `Write a closure message for someone named "${safeName}".
We haven't spoken in ${duration} days.
${safeContext ? `Context: ${safeContext}` : ""}

Generate a single message to gracefully end this connection.`;

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
        temperature: 0.7,
        max_tokens: 200,
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

    const message = openaiData.choices[0]?.message?.content || "Unable to generate message.";

    return new Response(
      JSON.stringify({ message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Ghost protocol error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
