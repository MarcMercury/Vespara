import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { rateLimitOrNull } from "../_shared/rate_limit.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FROM_EMAIL = Deno.env.get("FROM_EMAIL") || "noreply@vespara.co";

interface EmailPayload {
  type:
    | "invite"
    | "security_alert"
    | "password_reset_confirm"
    | "member_approved"
    | "weekly_digest";
  to: string;
  data?: Record<string, unknown>;
}

const TEMPLATES: Record<
  string,
  (data: Record<string, unknown>) => { subject: string; html: string }
> = {
  invite: (data) => ({
    subject: "You've been invited to Vespara",
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 600px; margin: 0 auto; background: #0A0A0F; color: #E8E0F0; padding: 40px;">
        <h1 style="color: #C8A2FF; font-size: 28px; text-align: center;">Welcome to Vespara</h1>
        <p style="font-size: 16px; line-height: 1.6;">
          ${data.inviter_name || "A member"} has invited you to join Vespara — a private, members-only community.
        </p>
        <div style="text-align: center; margin: 32px 0;">
          <a href="${data.invite_url || "https://www.vespara.co/join"}" 
             style="background: linear-gradient(135deg, #C8A2FF, #FF6B9D); color: #0A0A0F; padding: 14px 40px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px; display: inline-block;">
            Accept Invitation
          </a>
        </div>
        <p style="color: #8B7FA8; font-size: 13px; text-align: center;">
          This invite expires in 7 days. Invite code: <code>${data.invite_code || ""}</code>
        </p>
      </div>
    `,
  }),

  security_alert: (data) => ({
    subject: "Security Alert — New Login to Vespara",
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 600px; margin: 0 auto; background: #0A0A0F; color: #E8E0F0; padding: 40px;">
        <h1 style="color: #FF6B6B; font-size: 24px;">🔒 New Login Detected</h1>
        <p style="font-size: 16px; line-height: 1.6;">
          A new login to your Vespara account was detected:
        </p>
        <div style="background: #1A1A2E; padding: 20px; border-radius: 12px; margin: 20px 0;">
          <p style="margin: 8px 0;"><strong>Device:</strong> ${data.device || "Unknown"}</p>
          <p style="margin: 8px 0;"><strong>Location:</strong> ${data.location || "Unknown"}</p>
          <p style="margin: 8px 0;"><strong>Time:</strong> ${data.timestamp || new Date().toISOString()}</p>
          <p style="margin: 8px 0;"><strong>IP:</strong> ${data.ip || "Unknown"}</p>
        </div>
        <p style="font-size: 14px; color: #8B7FA8;">
          If this wasn't you, reset your password immediately and contact support.
        </p>
      </div>
    `,
  }),

  password_reset_confirm: (data) => ({
    subject: "Password Reset Successful — Vespara",
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 600px; margin: 0 auto; background: #0A0A0F; color: #E8E0F0; padding: 40px;">
        <h1 style="color: #4ECDC4; font-size: 24px;">✓ Password Changed</h1>
        <p style="font-size: 16px; line-height: 1.6;">
          Your Vespara password was successfully changed on ${data.timestamp || new Date().toISOString()}.
        </p>
        <p style="font-size: 14px; color: #8B7FA8;">
          If you didn't make this change, contact support immediately.
        </p>
      </div>
    `,
  }),

  member_approved: (data) => ({
    subject: "Welcome to Vespara — You're In!",
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 600px; margin: 0 auto; background: #0A0A0F; color: #E8E0F0; padding: 40px;">
        <h1 style="color: #C8A2FF; font-size: 28px; text-align: center;">You're Approved! 🎉</h1>
        <p style="font-size: 16px; line-height: 1.6; text-align: center;">
          Your membership has been approved. You now have full access to Vespara.
        </p>
        <div style="text-align: center; margin: 32px 0;">
          <a href="https://www.vespara.co" 
             style="background: linear-gradient(135deg, #C8A2FF, #FF6B9D); color: #0A0A0F; padding: 14px 40px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px; display: inline-block;">
            Open Vespara
          </a>
        </div>
      </div>
    `,
  }),

  weekly_digest: (data) => ({
    subject: "Your Weekly Vespara Update",
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 600px; margin: 0 auto; background: #0A0A0F; color: #E8E0F0; padding: 40px;">
        <h1 style="color: #C8A2FF; font-size: 24px;">Weekly Digest</h1>
        <div style="background: #1A1A2E; padding: 20px; border-radius: 12px; margin: 20px 0;">
          <p style="margin: 8px 0;">📨 <strong>${data.new_messages || 0}</strong> new messages</p>
          <p style="margin: 8px 0;">👥 <strong>${data.new_members || 0}</strong> new members this week</p>
          <p style="margin: 8px 0;">🎮 <strong>${data.games_played || 0}</strong> games played</p>
        </div>
        <div style="text-align: center; margin: 24px 0;">
          <a href="https://www.vespara.co" 
             style="background: #C8A2FF; color: #0A0A0F; padding: 12px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; display: inline-block;">
            Open Vespara
          </a>
        </div>
        <p style="color: #8B7FA8; font-size: 12px; text-align: center;">
          <a href="${data.unsubscribe_url || "#"}" style="color: #8B7FA8;">Unsubscribe</a>
        </p>
      </div>
    `,
  }),
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Content-Type, Authorization, apikey, x-client-info",
};

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    // Verify JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
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
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Rate limit: 3 emails per minute per user
    const limited = rateLimitOrNull(user.id, 3, 60_000, corsHeaders);
    if (limited) return limited;

    const payload: EmailPayload = await req.json();

    if (!payload.type || !payload.to) {
      return new Response(
        JSON.stringify({ error: "Missing type or to field" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const templateFn = TEMPLATES[payload.type];
    if (!templateFn) {
      return new Response(
        JSON.stringify({ error: `Unknown email type: ${payload.type}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { subject, html } = templateFn(payload.data || {});

    // Send via Resend API
    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to: payload.to,
        subject,
        html,
      }),
    });

    const resendResult = await resendResponse.json();

    if (!resendResponse.ok) {
      console.error("Resend API error:", resendResult);
      return new Response(
        JSON.stringify({ error: "Failed to send email", details: resendResult }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Log to audit_log
    await supabase.from("audit_log").insert({
      user_id: user.id,
      action: `email_sent:${payload.type}`,
      details: { to: payload.to, resend_id: resendResult.id },
    });

    return new Response(
      JSON.stringify({ success: true, id: resendResult.id }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("send-email error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
