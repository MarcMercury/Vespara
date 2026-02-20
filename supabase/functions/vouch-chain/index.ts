// Supabase Edge Function: Vouch Chain Link Handler
// Handles vouch link generation and redemption

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

const MAX_CODE_LENGTH = 24;

function generateVouchCode(): string {
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  const array = new Uint8Array(12);
  crypto.getRandomValues(array);
  return Array.from(array, (byte) => chars[byte % chars.length]).join("");
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

    const url = new URL(req.url);
    const action = url.searchParams.get("action");

    if (action === "generate") {
      const code = generateVouchCode();
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7);

      const { data, error } = await supabase
        .from("vouch_links")
        .insert({
          user_id: user.id,
          code,
          expires_at: expiresAt.toISOString(),
        })
        .select()
        .single();

      if (error) throw error;

      const link = `https://kult.app/vouch/${code}`;

      return new Response(
        JSON.stringify({ link, code, expiresAt: expiresAt.toISOString() }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else if (action === "redeem") {
      const body = await req.json();
      const { code } = body;

      if (!code || typeof code !== "string") {
        return new Response(
          JSON.stringify({ error: "Missing vouch code" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Sanitize code - alphanumeric only
      const safeCode = code.slice(0, MAX_CODE_LENGTH).replace(/[^a-zA-Z0-9]/g, "");
      if (safeCode.length === 0) {
        return new Response(
          JSON.stringify({ error: "Invalid vouch code format" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { data: link, error: linkError } = await supabase
        .from("vouch_links")
        .select("*")
        .eq("code", safeCode)
        .is("used_by", null)
        .gt("expires_at", new Date().toISOString())
        .maybeSingle();

      if (linkError) throw linkError;

      if (!link) {
        return new Response(
          JSON.stringify({ error: "Invalid or expired vouch link" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      if (link.user_id === user.id) {
        return new Response(
          JSON.stringify({ error: "You cannot vouch for yourself" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { error: vouchError } = await supabase
        .from("vouches")
        .insert({
          voucher_id: user.id,
          vouchee_id: link.user_id,
          message: "Vouched via link",
        });

      if (vouchError) {
        if (vouchError.code === "23505") {
          return new Response(
            JSON.stringify({ error: "You have already vouched for this person" }),
            { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
        throw vouchError;
      }

      await supabase
        .from("vouch_links")
        .update({
          used_by: user.id,
          used_at: new Date().toISOString(),
        })
        .eq("id", link.id);

      return new Response(
        JSON.stringify({ success: true, message: "Vouch recorded successfully" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      return new Response(
        JSON.stringify({ error: "Invalid action. Use ?action=generate or ?action=redeem" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (error) {
    console.error("Vouch chain error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
