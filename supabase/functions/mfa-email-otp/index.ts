// Supabase Edge Function: Email OTP for 2FA
// Sends and verifies 6-digit email codes as an alternative to authenticator apps
//
// Deploy: supabase functions deploy mfa-email-otp
// POST /functions/v1/mfa-email-otp { action: "send" }
// POST /functions/v1/mfa-email-otp { action: "verify", code: "123456" }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FROM_EMAIL = Deno.env.get("FROM_EMAIL") || "noreply@vespara.co";

// OTP expires in 10 minutes
const OTP_EXPIRY_MINUTES = 10;
// Rate limit: max 5 sends per hour
const MAX_SENDS_PER_HOUR = 5;

function generateOtp(): string {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  return String(array[0] % 1000000).padStart(6, "0");
}

async function hashCode(code: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(code);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

function buildEmailHtml(code: string): string {
  return `
    <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 600px; margin: 0 auto; background: #0A0A0F; color: #E8E0F0; padding: 40px;">
      <h1 style="color: #C8A2FF; font-size: 24px; text-align: center;">Your Vespara Verification Code</h1>
      <div style="background: #1A1A2E; padding: 30px; border-radius: 12px; margin: 24px 0; text-align: center;">
        <p style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #D4A8FF; margin: 0;">${code}</p>
      </div>
      <p style="font-size: 14px; line-height: 1.6; text-align: center;">
        Enter this code in the Vespara app to verify your identity.
      </p>
      <p style="font-size: 13px; color: #8B7FA8; text-align: center;">
        This code expires in ${OTP_EXPIRY_MINUTES} minutes. If you didn't request this, you can safely ignore it.
      </p>
    </div>
  `;
}

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type, Authorization, apikey, x-client-info",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    // Verify JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { action, code } = await req.json();

    if (action === "send") {
      // Rate limit check
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
      const { count } = await supabase
        .from("mfa_email_codes")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user.id)
        .gte("created_at", oneHourAgo);

      if ((count ?? 0) >= MAX_SENDS_PER_HOUR) {
        return new Response(
          JSON.stringify({
            error: "Too many codes requested. Please wait before trying again.",
          }),
          {
            status: 429,
            headers: { "Content-Type": "application/json" },
          }
        );
      }

      // Invalidate any existing unused codes
      await supabase
        .from("mfa_email_codes")
        .delete()
        .eq("user_id", user.id)
        .eq("verified", false);

      // Generate and store OTP
      const otp = generateOtp();
      const otpHash = await hashCode(otp);
      const expiresAt = new Date(
        Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000
      ).toISOString();

      const { error: insertError } = await supabase
        .from("mfa_email_codes")
        .insert({
          user_id: user.id,
          code_hash: otpHash,
          expires_at: expiresAt,
        });

      if (insertError) {
        console.error("Failed to store OTP:", insertError);
        return new Response(
          JSON.stringify({ error: "Failed to generate code" }),
          {
            status: 500,
            headers: { "Content-Type": "application/json" },
          }
        );
      }

      // Send email via Resend
      const resendResponse = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: FROM_EMAIL,
          to: user.email,
          subject: "Your Vespara Verification Code",
          html: buildEmailHtml(otp),
        }),
      });

      if (!resendResponse.ok) {
        const err = await resendResponse.json();
        console.error("Resend API error:", err);
        return new Response(
          JSON.stringify({ error: "Failed to send email" }),
          {
            status: 502,
            headers: { "Content-Type": "application/json" },
          }
        );
      }

      // Log to audit_log
      await supabase.from("audit_log").insert({
        user_id: user.id,
        action: "mfa_email_otp_sent",
        details: { email: user.email },
      });

      return new Response(
        JSON.stringify({
          success: true,
          message: "Verification code sent to your email",
          expires_in_seconds: OTP_EXPIRY_MINUTES * 60,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    if (action === "verify") {
      if (!code || typeof code !== "string" || code.length !== 6) {
        return new Response(
          JSON.stringify({ error: "Invalid code format" }),
          {
            status: 400,
            headers: { "Content-Type": "application/json" },
          }
        );
      }

      const codeHash = await hashCode(code);

      // Find matching unexpired, unverified code
      const { data: otpRecord, error: lookupError } = await supabase
        .from("mfa_email_codes")
        .select("id, expires_at")
        .eq("user_id", user.id)
        .eq("code_hash", codeHash)
        .eq("verified", false)
        .gte("expires_at", new Date().toISOString())
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (lookupError || !otpRecord) {
        return new Response(
          JSON.stringify({ error: "Invalid or expired code" }),
          {
            status: 400,
            headers: { "Content-Type": "application/json" },
          }
        );
      }

      // Mark code as verified
      await supabase
        .from("mfa_email_codes")
        .update({ verified: true })
        .eq("id", otpRecord.id);

      // Update profile with MFA method and verification timestamp
      await supabase
        .from("profiles")
        .update({
          mfa_method: "email",
          mfa_enrolled: true,
          mfa_email_verified_at: new Date().toISOString(),
        })
        .eq("id", user.id);

      // Log verification
      await supabase.from("audit_log").insert({
        user_id: user.id,
        action: "mfa_email_otp_verified",
        details: { method: "email" },
      });

      return new Response(
        JSON.stringify({ success: true, verified: true }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({ error: "Invalid action. Use 'send' or 'verify'." }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("mfa-email-otp error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
