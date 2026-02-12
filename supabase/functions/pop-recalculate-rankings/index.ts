import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Path of Pleasure - Nightly Rankings Recalculation
 *
 * This Edge Function recalculates the global popularity rankings for all
 * Path of Pleasure cards based on accumulated player votes and Elo matchups.
 *
 * Schedule: Run nightly via cron (recommended: 3 AM UTC)
 *   - Supabase Dashboard → Edge Functions → pop-recalculate-rankings → Schedule
 *   - Cron expression: 0 3 * * *
 *
 * Or call manually:
 *   curl -X POST https://<project>.supabase.co/functions/v1/pop-recalculate-rankings \
 *     -H "Authorization: Bearer <service_role_key>"
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
