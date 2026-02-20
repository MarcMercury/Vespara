import "https://deno.land/x/xhr@0.3.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
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
const MAX_TAG_LENGTH = 50;
const MAX_TAGS = 20;

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Require auth
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

    const { firstName, tags } = await req.json();

    if (!firstName || typeof firstName !== "string" || !tags || !Array.isArray(tags) || tags.length === 0) {
      return new Response(
        JSON.stringify({ error: "firstName (string) and tags (non-empty array) are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Sanitize inputs
    const safeName = firstName.slice(0, MAX_NAME_LENGTH).replace(/[<>"'`]/g, "");
    const safeTags = tags
      .slice(0, MAX_TAGS)
      .map((t: unknown) => (typeof t === "string" ? t.slice(0, MAX_TAG_LENGTH).replace(/[<>"'`]/g, "") : ""))
      .filter(Boolean);

    if (safeTags.length === 0) {
      return new Response(
        JSON.stringify({ error: "At least one valid tag is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const openAiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openAiKey) {
      console.error("OPENAI_API_KEY not configured");
      return new Response(
        JSON.stringify({ bio: `Hey, I'm ${safeName}. ${formatTagsBio(safeTags)}` }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const systemPrompt = `You are a creative bio writer for a high-end social networking app. Be concise and authentic. Write a 2-sentence bio under 150 characters. No hashtags, emojis, or bullet points.`;

    const userPrompt = `Write a compelling 2-sentence bio for a user named "${safeName}" whose personality tags are: ${safeTags.join(", ")}. Embody the tags without mentioning them directly. Keep it warm, confident, and slightly playful.`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openAiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4-turbo-preview",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        max_tokens: 100,
        temperature: 0.8,
      }),
    });

    if (!response.ok) {
      console.error("OpenAI API error:", response.status);
      return new Response(
        JSON.stringify({ bio: `Hey, I'm ${safeName}. ${formatTagsBio(safeTags)}` }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const data = await response.json();
    const bio = data.choices?.[0]?.message?.content?.trim() ||
      `Hey, I'm ${safeName}. ${formatTagsBio(safeTags)}`;

    return new Response(
      JSON.stringify({ bio }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error generating bio:", error);
    return new Response(
      JSON.stringify({ error: "Failed to generate bio" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

function formatTagsBio(tags: string[]): string {
  const vibes = tags.slice(0, 3).join(", ");
  const phrases = [
    `Into ${vibes.toLowerCase()} and always down for something new.`,
    `${vibes} enthusiast looking to connect with interesting people.`,
    `Living life through ${vibes.toLowerCase()}.`,
    `Finding joy in ${vibes.toLowerCase()} and good company.`,
  ];
  return phrases[Math.floor(Math.random() * phrases.length)];
}
