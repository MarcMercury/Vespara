import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Path of Pleasure - Manual Rankings Recalculation (Admin/Safety Valve)
 *
 * Rankings now auto-recalculate inside the database when enough votes
 * accumulate (threshold-based, not schedule-based). This Edge Function
 * exists as a MANUAL override for admins — e.g., after tuning config
 * or to force a recalc during testing.
 *
 * The recalculation applies dampening: each card can only shift ±3 ranks
 * per cycle to prevent wild jumps. Cards need ≥10 total votes before
 * their rank moves at all.
 *
 * Call manually:
 *   curl -X POST https://<project>.supabase.co/functions/v1/pop-recalculate-rankings \
 *     -H "Authorization: Bearer <service_role_key>"
 *
 * Adjust thresholds (no deploy needed):
 *   SELECT pop_update_recalc_config(
 *     p_vote_threshold := 100,    -- recalc after 100 new votes (default 50)
 *     p_max_rank_shift := 5,      -- allow ±5 rank movement per cycle (default 3)
 *     p_min_votes_to_rerank := 20 -- card needs 20 votes before moving (default 10)
 *   );
 */

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
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Use service_role key — this function modifies global card rankings
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Call the PL/pgSQL function that does the actual recalculation
    const { data, error } = await supabase.rpc(
      "recalculate_pop_global_rankings"
    );

    if (error) {
      console.error("Recalculation failed:", error);
      return new Response(
        JSON.stringify({
          success: false,
          error: error.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log("Rankings recalculated successfully:", data);

    return new Response(
      JSON.stringify({
        success: true,
        result: data,
        recalculated_at: new Date().toISOString(),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({
        success: false,
        error: err.message || "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
