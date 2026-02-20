// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                     KULT BACKGROUND JOB PROCESSOR                           ║
// ║              Async processing for embeddings, feeds, cleanup               ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import "https://esm.sh/@supabase/functions-js@2.4.1";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const ALLOWED_ORIGINS = [
  "https://kult.vercel.app",
  "https://www.kult.app",
  "http://localhost:3000",
];

function getCorsHeaders(req: Request) {
  const origin = req.headers.get("Origin") || "";
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-cron-secret",
  };
}

interface BackgroundJob {
  job_id: string;
  job_type: string;
  target_user_id: string | null;
}

Deno.serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Authenticate: require cron secret or valid auth header
    const cronSecret = req.headers.get("x-cron-secret");
    const authHeader = req.headers.get("Authorization");
    const expectedSecret = Deno.env.get("CRON_SECRET");

    if (!cronSecret && !authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (cronSecret && expectedSecret && cronSecret !== expectedSecret) {
      return new Response(
        JSON.stringify({ error: "Invalid cron secret" }),
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

    const { data: jobs, error: jobError } = await supabase
      .rpc("process_next_background_job");

    if (jobError) {
      console.error("Error fetching job:", jobError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch job" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!jobs || jobs.length === 0) {
      return new Response(
        JSON.stringify({ message: "No pending jobs" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const job = jobs[0] as BackgroundJob;
    console.log(`Processing job: ${job.job_type} for user: ${job.target_user_id}`);

    let success = false;
    let errorMessage: string | null = null;

    try {
      switch (job.job_type) {
        case "generate_matches":
          success = await processGenerateMatches(supabase, job.target_user_id);
          break;
        case "update_embeddings":
          success = await processUpdateEmbeddings(supabase, job.target_user_id);
          break;
        case "cleanup_stale":
          success = await processCleanupStale(supabase);
          break;
        case "calculate_stats":
          success = await processCalculateStats(supabase);
          break;
        default:
          errorMessage = `Unknown job type: ${job.job_type}`;
          console.error(errorMessage);
      }
    } catch (e) {
      errorMessage = e instanceof Error ? e.message : "Unknown error";
      console.error(`Job failed: ${errorMessage}`);
    }

    await supabase.rpc("complete_background_job", {
      p_job_id: job.job_id,
      p_success: success,
      p_error: errorMessage,
    });

    return new Response(
      JSON.stringify({ job_id: job.job_id, job_type: job.job_type, success, error: errorMessage }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    const corsHeaders = getCorsHeaders(req);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

async function processGenerateMatches(supabase: ReturnType<typeof createClient>, userId: string | null): Promise<boolean> {
  if (!userId) { console.error("generate_matches requires target_user_id"); return false; }
  const { data, error } = await supabase.rpc("generate_daily_matches", { target_user_id: userId, match_limit: 20 });
  if (error) { console.error("Failed to generate matches:", error); return false; }
  console.log(`Generated ${data} matches for user ${userId}`);
  return true;
}

async function processUpdateEmbeddings(supabase: ReturnType<typeof createClient>, userId: string | null): Promise<boolean> {
  if (!userId) { console.error("update_embeddings requires target_user_id"); return false; }
  const { data: profile, error: profileError } = await supabase.from("profiles").select("display_name, bio, looking_for, interests").eq("id", userId).single();
  if (profileError || !profile) { console.error("Failed to fetch profile:", profileError); return false; }
  const textToEmbed = [profile.display_name, profile.bio, Array.isArray(profile.looking_for) ? profile.looking_for.join(", ") : "", Array.isArray(profile.interests) ? profile.interests.join(", ") : ""].filter(Boolean).join(". ");
  if (!textToEmbed || textToEmbed.length < 10) { return true; }
  const embedding = await generateEmbedding(textToEmbed);
  if (!embedding) { return false; }
  const { error: updateError } = await supabase.from("profiles").update({ embedding, embedding_updated_at: new Date().toISOString() }).eq("id", userId);
  if (updateError) { console.error("Failed to update embedding:", updateError); return false; }
  return true;
}

async function generateEmbedding(text: string): Promise<number[] | null> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) { console.error("OPENAI_API_KEY not set"); return null; }
  try {
    const response = await fetch("https://api.openai.com/v1/embeddings", {
      method: "POST",
      headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "text-embedding-3-small", input: text }),
    });
    if (!response.ok) { console.error("OpenAI API error:", response.status); return null; }
    const data = await response.json();
    return data.data[0].embedding;
  } catch (e) { console.error("Failed to generate embedding:", e); return null; }
}

async function processCleanupStale(supabase: ReturnType<typeof createClient>): Promise<boolean> {
  let allSucceeded = true;
  const { error: rlError } = await supabase.rpc("cleanup_rate_limits");
  if (rlError) { console.error("Failed to cleanup rate limits:", rlError); allSucceeded = false; }
  const { error: matchError } = await supabase.from("daily_matches").delete().lt("calculated_at", new Date(Date.now() - 7*24*60*60*1000).toISOString().split("T")[0]);
  if (matchError) { console.error("Failed to cleanup old matches:", matchError); allSucceeded = false; }
  const { error: jobError } = await supabase.from("background_jobs").delete().eq("status", "completed").lt("completed_at", new Date(Date.now() - 7*24*60*60*1000).toISOString());
  if (jobError) { console.error("Failed to cleanup old jobs:", jobError); allSucceeded = false; }
  return allSucceeded;
}

async function processCalculateStats(supabase: ReturnType<typeof createClient>): Promise<boolean> {
  const { error } = await supabase.rpc("calculate_daily_stats");
  if (error) { console.error("Failed to calculate stats:", error); return false; }
  console.log("Daily stats calculated successfully");
  return true;
}
