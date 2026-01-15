// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                    VESPARA BACKGROUND JOB PROCESSOR                        ║
// ║              Async processing for embeddings, feeds, cleanup               ║
// ╚═══════════════════════════════════════════════════════════════════════════╝
//
// PHASE 6: Scalability - Moves expensive operations off the hot path
// 
// Job Types:
// - generate_matches: Calculate daily AI match recommendations
// - update_embeddings: Generate/update user profile embeddings
// - cleanup_stale: Clean up old data (rate limits, old matches)
// - calculate_stats: Daily analytics aggregation
//
// Trigger: Called by pg_cron every minute, or manually via HTTP

import "https://esm.sh/@supabase/functions-js@2.4.1";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// OpenAI for embeddings
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

interface BackgroundJob {
  job_id: string;
  job_type: string;
  target_user_id: string | null;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Create Supabase client with service role for admin access
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get the next pending job
    const { data: jobs, error: jobError } = await supabase
      .rpc("process_next_background_job");

    if (jobError) {
      console.error("Error fetching job:", jobError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch job", details: jobError.message }),
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

    // Mark job as completed or failed
    await supabase.rpc("complete_background_job", {
      p_job_id: job.job_id,
      p_success: success,
      p_error: errorMessage,
    });

    return new Response(
      JSON.stringify({
        job_id: job.job_id,
        job_type: job.job_type,
        success,
        error: errorMessage,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// JOB PROCESSORS
// ═══════════════════════════════════════════════════════════════════════════

async function processGenerateMatches(
  supabase: ReturnType<typeof createClient>,
  userId: string | null
): Promise<boolean> {
  if (!userId) {
    console.error("generate_matches requires target_user_id");
    return false;
  }

  // Call the database function to generate matches
  const { data, error } = await supabase.rpc("generate_daily_matches", {
    target_user_id: userId,
    match_limit: 20,
  });

  if (error) {
    console.error("Failed to generate matches:", error);
    return false;
  }

  console.log(`Generated ${data} matches for user ${userId}`);
  return true;
}

async function processUpdateEmbeddings(
  supabase: ReturnType<typeof createClient>,
  userId: string | null
): Promise<boolean> {
  if (!userId) {
    console.error("update_embeddings requires target_user_id");
    return false;
  }

  // Get user profile data to embed
  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("display_name, bio, looking_for, interests")
    .eq("id", userId)
    .single();

  if (profileError || !profile) {
    console.error("Failed to fetch profile:", profileError);
    return false;
  }

  // Create text to embed
  const textToEmbed = [
    profile.display_name,
    profile.bio,
    Array.isArray(profile.looking_for) ? profile.looking_for.join(", ") : "",
    Array.isArray(profile.interests) ? profile.interests.join(", ") : "",
  ].filter(Boolean).join(". ");

  if (!textToEmbed || textToEmbed.length < 10) {
    console.log("Insufficient profile data for embedding");
    return true; // Not an error, just nothing to embed
  }

  // Call OpenAI to generate embedding
  const embedding = await generateEmbedding(textToEmbed);
  if (!embedding) {
    return false;
  }

  // Update profile with embedding
  const { error: updateError } = await supabase
    .from("profiles")
    .update({
      embedding: embedding,
      embedding_updated_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (updateError) {
    console.error("Failed to update embedding:", updateError);
    return false;
  }

  console.log(`Updated embedding for user ${userId}`);
  return true;
}

async function generateEmbedding(text: string): Promise<number[] | null> {
  if (!OPENAI_API_KEY) {
    console.error("OPENAI_API_KEY not set");
    return null;
  }

  try {
    const response = await fetch("https://api.openai.com/v1/embeddings", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "text-embedding-ada-002",
        input: text,
      }),
    });

    if (!response.ok) {
      console.error("OpenAI API error:", await response.text());
      return null;
    }

    const data = await response.json();
    return data.data[0].embedding;
  } catch (e) {
    console.error("Failed to generate embedding:", e);
    return null;
  }
}

async function processCleanupStale(
  supabase: ReturnType<typeof createClient>
): Promise<boolean> {
  // Clean up rate limits older than 24 hours
  const { data: rateLimitCount } = await supabase.rpc("cleanup_rate_limits");
  console.log(`Cleaned up ${rateLimitCount ?? 0} rate limit records`);

  // Clean up old daily matches (keep 7 days)
  const { error: matchError } = await supabase
    .from("daily_matches")
    .delete()
    .lt("calculated_at", new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split("T")[0]);

  if (matchError) {
    console.error("Failed to cleanup old matches:", matchError);
  }

  // Clean up completed background jobs older than 7 days
  const { error: jobError } = await supabase
    .from("background_jobs")
    .delete()
    .eq("status", "completed")
    .lt("completed_at", new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString());

  if (jobError) {
    console.error("Failed to cleanup old jobs:", jobError);
  }

  return true;
}

async function processCalculateStats(
  supabase: ReturnType<typeof createClient>
): Promise<boolean> {
  const { error } = await supabase.rpc("calculate_daily_stats");
  
  if (error) {
    console.error("Failed to calculate stats:", error);
    return false;
  }

  console.log("Daily stats calculated successfully");
  return true;
}
