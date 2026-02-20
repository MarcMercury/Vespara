// Supabase Edge Function: Strategist AI
// Handles OpenAI requests for connection advice

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
const MAX_CONTEXT_LENGTH = 1000;
const MAX_QUESTION_LENGTH = 500;
const MAX_HISTORY_LENGTH = 2000;

interface StrategistRequest {
  matchName: string;
  matchContext: string;
  userQuestion: string;
  conversationHistory?: string;
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

    const body: StrategistRequest = await req.json();
    const { matchName, matchContext, userQuestion, conversationHistory } = body;

    // Validate
    if (!matchName || typeof matchName !== "string") {
      return new Response(
        JSON.stringify({ error: "matchName is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    if (!userQuestion || typeof userQuestion !== "string") {
      return new Response(
        JSON.stringify({ error: "userQuestion is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Sanitize
    const safeName = matchName.slice(0, MAX_NAME_LENGTH).replace(/[<>"'`]/g, "");
    const safeContext = (matchContext || "").slice(0, MAX_CONTEXT_LENGTH).replace(/[<>"'`]/g, "");
    const safeQuestion = userQuestion.slice(0, MAX_QUESTION_LENGTH).replace(/[<>"'`]/g, "");
    const safeHistory = conversationHistory ? conversationHistory.slice(0, MAX_HISTORY_LENGTH).replace(/[<>"'`]/g, "") : undefined;

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) {
      console.error("OPENAI_API_KEY not set");
      return new Response(
        JSON.stringify({ error: "Server misconfigured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const systemPrompt = `You are "The Strategist" - an elite connection advisor within Kult, a premium community app. You provide sharp, actionable advice with wit and sophistication.

Your personality:
- Confident but not arrogant
- Witty with occasional dry humor
- Direct and actionable (no fluff)
- Emotionally intelligent
- Never judgmental about modern connection culture

Guidelines:
- Keep responses concise (2-3 paragraphs max)
- Always provide specific, actionable next steps
- Reference the match's context when relevant
- Use sophisticated vocabulary but stay accessible
- End with a memorable one-liner when appropriate`;

    const userPrompt = `Match: ${safeName}
Context: ${safeContext}
${safeHistory ? `Recent conversation:\n${safeHistory}\n` : ""}
User's question: ${safeQuestion}

Provide strategic advice.`;

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
        temperature: 0.8,
        max_tokens: 500,
      }),
    });

    const openaiData = await openaiResponse.json();

    if (!openaiResponse.ok) {
      console.error("OpenAI API error:", openaiData.error?.message);
      return new Response(
        JSON.stringify({ error: "Failed to generate advice" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const advice = openaiData.choices[0]?.message?.content || "Unable to generate advice.";
    const tokensUsed = openaiData.usage?.total_tokens || 0;

    // Log to database (non-blocking, don't fail if log fails)
    try {
      await supabase.from("strategist_logs").insert({
        user_id: user.id,
        query: safeQuestion,
        response: advice,
        tokens_used: tokensUsed,
      });
    } catch (logError) {
      console.error("Failed to log strategist usage:", logError);
    }

    return new Response(
      JSON.stringify({ advice, tokensUsed }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Strategist error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
