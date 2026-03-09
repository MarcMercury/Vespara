import "https://deno.land/x/xhr@0.3.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * ════════════════════════════════════════════════════════════════════════════
 * DEEP BIO GENERATOR - Server-Side Bio Generation with Full Profile Context
 * ════════════════════════════════════════════════════════════════════════════
 *
 * Replaces the simple "name + tags" bio generator with one that uses the
 * ENTIRE profile context to create deeply personalized bios.
 *
 * Input: { style?: string }  (style = "natural" | "bold" | "contrast")
 * Uses the authenticated user's full profile from the database.
 *
 * Returns: { bio: string, style: string, voice_guide: string }
 */

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
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// VOICE CALIBRATION - Determines HOW the bio sounds
// ═══════════════════════════════════════════════════════════════════════════

interface UserProfile {
  display_name: string;
  bio?: string;
  hook?: string;
  headline?: string;
  occupation?: string;
  birth_date?: string;
  gender?: string[];
  orientation?: string[];
  relationship_status?: string[];
  seeking?: string[];
  looking_for?: string[]; // traits
  heat_level?: string;
  hard_limits?: string[];
  availability_general?: string[];
  scheduling_style?: string;
  hosting_status?: string;
  discretion_level?: string;
  travel_radius?: number;
  bandwidth?: number;
  interests?: string[];
  city?: string;
  state?: string;
}

function buildVoiceGuide(profile: UserProfile): string {
  const traits = profile.looking_for || [];
  const heat = profile.heat_level || "medium";
  const discretion = profile.discretion_level;
  const seeking = profile.seeking || [];

  const parts: string[] = [];

  // Communication archetype inference
  const isPlayful = traits.some(
    (t) =>
      t.includes("Witty") || t.includes("Mischievous") || t.includes("Playful")
  );
  const isCalm = traits.some(
    (t) => t.includes("Calm") || t.includes("Gentle")
  );
  const isDominant = traits.some((t) => t.includes("Dominant"));
  const isRomantic = traits.some((t) => t.includes("Romantic"));
  const isPassionate = traits.some((t) => t.includes("Passionate"));
  const isMysterious = traits.some((t) => t.includes("Mysterious"));

  if (isPlayful) {
    parts.push(
      "VOICE: Witty, irreverent, uses dry humor and playful sarcasm. Punchy sentences."
    );
  } else if (isCalm) {
    parts.push(
      "VOICE: Measured, calm, confident. Understated elegance. Less is more."
    );
  } else if (isDominant) {
    parts.push(
      "VOICE: Direct, confident, commanding. Knows what they want. No filler."
    );
  } else if (isRomantic) {
    parts.push("VOICE: Warm, evocative, poetic. Draws you in with imagery.");
  } else if (isMysterious) {
    parts.push(
      "VOICE: Enigmatic, alluring, says just enough to make you curious."
    );
  } else {
    parts.push(
      "VOICE: Balanced confidence. Approachable and authentic. Not trying too hard."
    );
  }

  // Heat calibration
  if (heat === "nuclear") {
    parts.push("HEAT: Bold, unapologetic, no pretense about desires.");
  } else if (heat === "hot") {
    parts.push("HEAT: Warm and suggestive, confident in desire.");
  } else if (heat === "mild") {
    parts.push("HEAT: Tasteful, connection-first. Romance over raunch.");
  } else {
    parts.push("HEAT: Balanced — neither cold nor overtly sexual.");
  }

  // Discretion
  if (discretion === "very_discreet") {
    parts.push(
      "DISCRETION: HIGH — elegant, subtle, nothing revealing. Think private club."
    );
  } else if (discretion === "discreet") {
    parts.push("DISCRETION: MODERATE — tasteful, intriguing, guarded.");
  }

  // Seeking context
  if (seeking.some((s) => s.includes("relationship") || s.includes("partner"))) {
    parts.push("EMOTIONAL VIBE: Open to depth, emotionally available.");
  } else if (seeking.every((s) => s.includes("casual") || s.includes("fwb"))) {
    parts.push(
      "EMOTIONAL VIBE: Light, fun, no-pressure energy."
    );
  }

  return parts.join("\n");
}

function buildContextBrief(profile: UserProfile): string {
  const parts: string[] = [];

  if (profile.display_name) parts.push(`Name: ${profile.display_name}`);
  if (profile.occupation) parts.push(`Occupation: ${profile.occupation}`);
  if (profile.city) {
    parts.push(
      `Location: ${profile.city}${profile.state ? ", " + profile.state : ""}`
    );
  }
  if (profile.gender?.length) parts.push(`Gender: ${profile.gender.join(", ")}`);
  if (profile.orientation?.length) {
    parts.push(`Orientation: ${profile.orientation.join(", ")}`);
  }
  if (profile.relationship_status?.length) {
    parts.push(`Relationship status: ${profile.relationship_status.join(", ")}`);
  }
  if (profile.seeking?.length) parts.push(`Seeking: ${profile.seeking.join(", ")}`);
  if (profile.looking_for?.length) {
    parts.push(`Personality traits: ${profile.looking_for.join(", ")}`);
  }
  if (profile.interests?.length) {
    parts.push(`Interests: ${profile.interests.join(", ")}`);
  }
  parts.push(`Heat level: ${profile.heat_level || "medium"}`);
  if (profile.hard_limits?.length) {
    parts.push(`Hard limits: ${profile.hard_limits.join(", ")}`);
  }
  if (profile.scheduling_style) {
    parts.push(`Scheduling: ${profile.scheduling_style}`);
  }
  if (profile.hosting_status) {
    parts.push(`Hosting: ${profile.hosting_status}`);
  }
  if (profile.bandwidth !== undefined) {
    parts.push(`Bandwidth: ${Math.round(profile.bandwidth * 100)}%`);
  }
  if (profile.bio) parts.push(`\nCurrent bio: "${profile.bio}"`);

  return parts.join("\n");
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const openAiKey = Deno.env.get("OPENAI_API_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Server misconfigured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get request params
    const body = await req.json().catch(() => ({}));
    const style = body.style || "natural";

    // Fetch FULL profile
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select(
        `display_name, bio, hook, headline, occupation, birth_date,
         gender, orientation, relationship_status, seeking,
         looking_for, heat_level, hard_limits,
         availability_general, scheduling_style, hosting_status,
         travel_radius, bandwidth, discretion_level, interests,
         city, state`
      )
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ error: "Profile not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Build deep context
    const voiceGuide = buildVoiceGuide(profile as UserProfile);
    const contextBrief = buildContextBrief(profile as UserProfile);

    if (!openAiKey) {
      // Fallback
      const name = profile.display_name || "Someone";
      return new Response(
        JSON.stringify({
          bio: `Hey, I'm ${name}. Still finding the right words — the real me shows up in conversation.`,
          style: "fallback",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const styleDescriptions: Record<string, string> = {
      natural:
        "Write in their most authentic voice. Natural, effortless, genuine.",
      bold: "Bolder, more provocative version. Confident and unapologetic.",
      contrast:
        "Unexpected angle — if they're funny, be sincere. If they're deep, be playful.",
    };

    const systemPrompt = `You are writing a dating profile bio for the app Vespara — an exclusive, sex-positive social networking platform for adults 21+.

YOUR VOICE CALIBRATION FOR THIS PERSON:
${voiceGuide}

STYLE: ${style} — ${styleDescriptions[style] || styleDescriptions.natural}

CRITICAL RULES:
- Write in FIRST PERSON as if you ARE this person
- 2-3 sentences, under 200 characters ideally (280 max)
- No hashtags, no emojis unless their vibe calls for it
- No clichés ("living my best life", "partner in crime", "love to laugh")
- Never list traits directly — EMBODY them through word choice and tone
- Must feel authentic to their specific personality, not generic
- Respect their heat level and discretion preferences
- The bio should make someone curious and want to know more`;

    const userPrompt = `Generate a ${style} bio for this user.

${contextBrief}

Remember: This bio should feel like it could ONLY have been written by this specific person.`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openAiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        max_tokens: 200,
        temperature: style === "bold" ? 0.9 : style === "contrast" ? 0.85 : 0.8,
      }),
    });

    if (!response.ok) {
      console.error("OpenAI API error:", response.status);
      const name = profile.display_name || "Someone";
      return new Response(
        JSON.stringify({
          bio: `Hey, I'm ${name}. Still crafting the perfect intro.`,
          style: "fallback",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const data = await response.json();
    let bio =
      data.choices?.[0]?.message?.content?.trim() ||
      `Hey, I'm ${profile.display_name}. The real me is better in person.`;

    // Clean up AI output
    bio = bio.replace(/^["']|["']$/g, ""); // Remove wrapping quotes
    bio = bio.replace(/^(Bio:|Here's.*?:|Option \d+:)\s*/i, ""); // Remove prefixes

    return new Response(
      JSON.stringify({ bio, style, voice_guide: voiceGuide }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error generating deep bio:", error);
    return new Response(
      JSON.stringify({ error: "Failed to generate bio" }),
      {
        status: 500,
        headers: {
          ...getCorsHeaders(req),
          "Content-Type": "application/json",
        },
      }
    );
  }
});
