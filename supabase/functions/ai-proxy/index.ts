// Supabase Edge Function: AI Proxy
// Centralizes all client-side AI calls through a secure server-side proxy
// Prevents API key exposure in browser JavaScript bundles

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ALLOWED_ORIGINS = [
  "https://vespara.vercel.app",
  "https://www.vespara.co",
  "http://localhost:3000",
];

function getCorsHeaders(req: Request) {
  const origin = req.headers.get("Origin") || "";
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

// ── Rate Limiting (per-user, in-memory) ──────────────────────────────────
const userRequestCounts = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT = 30; // requests per minute per user
const RATE_WINDOW_MS = 60_000;

function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const entry = userRequestCounts.get(userId);

  if (!entry || now > entry.resetAt) {
    userRequestCounts.set(userId, { count: 1, resetAt: now + RATE_WINDOW_MS });
    return true;
  }

  if (entry.count >= RATE_LIMIT) return false;
  entry.count++;
  return true;
}

// ── Allowed actions & their configs ──────────────────────────────────────
interface ActionConfig {
  systemPrompt: string;
  maxTokens: number;
  temperature: number;
  model: string;
}

const ACTION_CONFIGS: Record<string, ActionConfig> = {
  generate_bio: {
    systemPrompt: "You are a creative writer helping users craft engaging bios. Keep it concise (2-3 sentences max), authentic, and engaging. Don't use clichés.",
    maxTokens: 150,
    temperature: 0.8,
    model: "gpt-4o-mini",
  },
  ice_breakers: {
    systemPrompt: "You are a dating coach helping create genuine conversation starters. Generate unique, thoughtful openers based on shared interests. Avoid generic pickup lines. Return options one per line.",
    maxTokens: 200,
    temperature: 0.8,
    model: "gpt-4o-mini",
  },
  analyze_message: {
    systemPrompt: `Analyze the following message for:
1. Sentiment (positive/neutral/negative)
2. Toxicity score (0-1)
3. Flags (inappropriate, spam, harassment, none)
Respond in JSON format: {"sentiment": "...", "toxicity": 0.0, "flags": ["..."]}`,
    maxTokens: 100,
    temperature: 0.1,
    model: "gpt-4o-mini",
  },
  game_content: {
    systemPrompt: "You are creating content for adult party games. Be creative, fun, and engaging. Keep content appropriate for the specified rating level.",
    maxTokens: 200,
    temperature: 0.9,
    model: "gpt-4o-mini",
  },
  closure_message: {
    systemPrompt: "You are helping someone end a dating connection gracefully. Generate a closure message that is respectful and mature. Never be mean or hurtful. No clichés.",
    maxTokens: 200,
    temperature: 0.7,
    model: "gpt-4o-mini",
  },
  resuscitate: {
    systemPrompt: "You are a witty dating coach helping revive a stale conversation. Generate an opener that feels natural, not forced or desperate. Has a hook that invites a response. Keep to 1-2 sentences.",
    maxTokens: 100,
    temperature: 0.9,
    model: "gpt-4o-mini",
  },
  strategic_advice: {
    systemPrompt: "You are a dating strategist providing actionable advice. Be direct, mature, and helpful. Keep it under 50 words.",
    maxTokens: 150,
    temperature: 0.7,
    model: "gpt-4o-mini",
  },
  photo_analysis: {
    systemPrompt: "Analyze this dating profile photo and recommend improvements. Return JSON: {\"recommendations\": [\"enhance\", \"crop_smart\"], \"analysis\": \"brief description\"}",
    maxTokens: 200,
    temperature: 0.3,
    model: "gpt-4o-mini",
  },
  parse_itinerary: {
    systemPrompt: `You are a travel itinerary parser. Extract trip details from the provided itinerary text.
Return a JSON array of trip objects. Each trip should have these fields:
- "title": a short descriptive name for the trip (e.g. "Paris Getaway")
- "destination_city": the main city
- "destination_country": the country (use full name)
- "start_date": ISO date string (YYYY-MM-DD)
- "end_date": ISO date string (YYYY-MM-DD)
- "travel_type": one of "leisure", "business", "adventure", "event", "other"
- "accommodation": hotel/airbnb name if mentioned, or null
- "description": brief trip summary from the itinerary
- "notes": any important details like flight numbers, confirmation codes, etc.

If the itinerary contains multiple destinations/legs, create separate trip entries for each.
If dates are ambiguous, make your best estimate. If a year is not specified, assume the next occurrence of that date.
ONLY return valid JSON. No markdown, no explanation.`,
    maxTokens: 1500,
    temperature: 0.1,
    model: "gpt-4o-mini",
  },
};

const MAX_PROMPT_LENGTH = 10000; // Increased for itinerary uploads

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Auth ──────────────────────────────────────────────────────────────
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

    // ── Rate Limit ───────────────────────────────────────────────────────
    if (!checkRateLimit(user.id)) {
      return new Response(
        JSON.stringify({ error: "Rate limit exceeded. Please wait a moment." }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Parse Request ────────────────────────────────────────────────────
    const body = await req.json();
    const { action, prompt, systemPromptOverride } = body;

    if (!action || typeof action !== "string" || !ACTION_CONFIGS[action]) {
      return new Response(
        JSON.stringify({ error: `Invalid action. Allowed: ${Object.keys(ACTION_CONFIGS).join(", ")}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!prompt || typeof prompt !== "string") {
      return new Response(
        JSON.stringify({ error: "prompt is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const config = ACTION_CONFIGS[action];
    const safePrompt = prompt.slice(0, MAX_PROMPT_LENGTH).replace(/[<>`]/g, "");
    const finalSystemPrompt = systemPromptOverride
      ? (typeof systemPromptOverride === "string" ? systemPromptOverride.slice(0, 500) : config.systemPrompt)
      : config.systemPrompt;

    // ── Call OpenAI ──────────────────────────────────────────────────────
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) {
      return new Response(
        JSON.stringify({ error: "AI service not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: config.model,
        messages: [
          { role: "system", content: finalSystemPrompt },
          { role: "user", content: safePrompt },
        ],
        max_tokens: config.maxTokens,
        temperature: config.temperature,
      }),
    });

    const openaiData = await openaiResponse.json();

    if (!openaiResponse.ok) {
      console.error("OpenAI API error:", openaiData.error?.message);
      return new Response(
        JSON.stringify({ error: "AI request failed" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const content = openaiData.choices?.[0]?.message?.content?.trim() || "";
    const tokensUsed = openaiData.usage?.total_tokens || 0;

    // ── Log usage (non-blocking) ─────────────────────────────────────────
    try {
      await supabase.from("ai_usage_logs").insert({
        user_id: user.id,
        action,
        tokens_used: tokensUsed,
        model: config.model,
      });
    } catch (logError) {
      console.error("Failed to log AI usage:", logError);
    }

    return new Response(
      JSON.stringify({ content, tokensUsed, model: config.model }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("AI proxy error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
