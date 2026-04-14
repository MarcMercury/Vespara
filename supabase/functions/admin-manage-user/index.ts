import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Content-Type, Authorization, apikey, x-client-info",
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

async function verifyAdmin(
  supabase: ReturnType<typeof createClient>,
  token: string
) {
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(token);
  if (error || !user) return null;

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .single();

  if (!profile?.is_admin) return null;
  return user;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing authorization" }, 401);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const token = authHeader.replace("Bearer ", "");
    const admin = await verifyAdmin(supabase, token);

    if (!admin) {
      return jsonResponse({ error: "Forbidden: admin only" }, 403);
    }

    const body = await req.json();
    const { action, user_id } = body;

    if (!action || !user_id) {
      return jsonResponse({ error: "Missing action or user_id" }, 400);
    }

    // ═══════════════════════════════════════════════════════════════
    // ACTION: disable_user
    // ═══════════════════════════════════════════════════════════════
    if (action === "disable_user") {
      // Update profile
      const { error: profileErr } = await supabase
        .from("profiles")
        .update({
          is_disabled: true,
          disabled_at: new Date().toISOString(),
          disabled_by: admin.id,
          membership_status: "suspended",
          updated_at: new Date().toISOString(),
        })
        .eq("id", user_id);

      if (profileErr) {
        return jsonResponse({ error: profileErr.message }, 500);
      }

      // Ban user in Supabase Auth (prevents new sign-ins)
      const { error: banErr } = await supabase.auth.admin.updateUserById(
        user_id,
        { ban_duration: "876000h" } // ~100 years
      );

      if (banErr) {
        console.error("Failed to ban auth user:", banErr);
      }

      // Audit log
      await supabase.from("audit_log").insert({
        user_id: admin.id,
        action: "admin:disable_user",
        resource_type: "user",
        resource_id: user_id,
        metadata: { target_user_id: user_id },
      });

      return jsonResponse({ success: true, action: "disabled" });
    }

    // ═══════════════════════════════════════════════════════════════
    // ACTION: enable_user
    // ═══════════════════════════════════════════════════════════════
    if (action === "enable_user") {
      const { error: profileErr } = await supabase
        .from("profiles")
        .update({
          is_disabled: false,
          disabled_at: null,
          disabled_by: null,
          membership_status: "approved",
          updated_at: new Date().toISOString(),
        })
        .eq("id", user_id);

      if (profileErr) {
        return jsonResponse({ error: profileErr.message }, 500);
      }

      // Unban in Supabase Auth
      const { error: unbanErr } = await supabase.auth.admin.updateUserById(
        user_id,
        { ban_duration: "none" }
      );

      if (unbanErr) {
        console.error("Failed to unban auth user:", unbanErr);
      }

      await supabase.from("audit_log").insert({
        user_id: admin.id,
        action: "admin:enable_user",
        resource_type: "user",
        resource_id: user_id,
        metadata: { target_user_id: user_id },
      });

      return jsonResponse({ success: true, action: "enabled" });
    }

    // ═══════════════════════════════════════════════════════════════
    // ACTION: reset_password
    // ═══════════════════════════════════════════════════════════════
    if (action === "reset_password") {
      // Get user email from auth
      const { data: authUser, error: fetchErr } =
        await supabase.auth.admin.getUserById(user_id);

      if (fetchErr || !authUser?.user?.email) {
        return jsonResponse({ error: "User not found or no email" }, 404);
      }

      // Generate a password reset link
      const { data: linkData, error: linkErr } =
        await supabase.auth.admin.generateLink({
          type: "recovery",
          email: authUser.user.email,
        });

      if (linkErr) {
        return jsonResponse({ error: linkErr.message }, 500);
      }

      // Send reset email via send-email function
      try {
        await supabase.functions.invoke("send-email", {
          body: {
            type: "password_reset",
            to: authUser.user.email,
            data: {
              display_name:
                authUser.user.user_metadata?.display_name || "Member",
              reset_link: linkData?.properties?.action_link || "",
            },
          },
        });
      } catch (emailErr) {
        console.error("Failed to send reset email:", emailErr);
        // Don't fail the whole request; link was still generated
      }

      await supabase.from("audit_log").insert({
        user_id: admin.id,
        action: "admin:reset_password",
        resource_type: "user",
        resource_id: user_id,
        metadata: {
          target_user_id: user_id,
          email: authUser.user.email,
        },
      });

      return jsonResponse({
        success: true,
        action: "password_reset_sent",
        email: authUser.user.email,
      });
    }

    // ═══════════════════════════════════════════════════════════════
    // ACTION: get_user_detail
    // ═══════════════════════════════════════════════════════════════
    if (action === "get_user_detail") {
      // Profile data
      const { data: profile, error: profileErr } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", user_id)
        .single();

      if (profileErr) {
        return jsonResponse({ error: profileErr.message }, 500);
      }

      // Auth data (email, last sign in, etc.)
      const { data: authUser } = await supabase.auth.admin.getUserById(
        user_id
      );

      // Token usage summary
      const { data: tokenUsage } = await supabase
        .from("token_usage")
        .select("service, tokens_total, cost_cents, operation, created_at")
        .eq("user_id", user_id)
        .order("created_at", { ascending: false })
        .limit(50);

      // Token summary by service
      const { data: tokenSummary } = await supabase.rpc(
        "admin_get_token_summary",
        { target_user_id: user_id }
      );

      // Recent audit log
      const { data: auditLog } = await supabase
        .from("audit_log")
        .select("*")
        .eq("resource_id", user_id)
        .order("created_at", { ascending: false })
        .limit(20);

      // Active sessions
      const { data: sessions } = await supabase
        .from("user_sessions")
        .select("*")
        .eq("user_id", user_id)
        .eq("is_active", true)
        .order("last_active_at", { ascending: false });

      return jsonResponse({
        success: true,
        user: {
          ...profile,
          auth_email: authUser?.user?.email,
          auth_last_sign_in: authUser?.user?.last_sign_in_at,
          auth_created_at: authUser?.user?.created_at,
          auth_confirmed_at: authUser?.user?.confirmed_at,
          is_banned: !!authUser?.user?.banned_until,
        },
        token_usage: tokenUsage || [],
        token_summary: tokenSummary || [],
        audit_log: auditLog || [],
        sessions: sessions || [],
      });
    }

    // ═══════════════════════════════════════════════════════════════
    // ACTION: list_users
    // ═══════════════════════════════════════════════════════════════
    if (action === "list_users") {
      const { search, status, disabled, limit, offset } = body;

      const { data: users, error: listErr } = await supabase.rpc(
        "admin_list_users",
        {
          p_search: search || null,
          p_status: status || null,
          p_disabled: disabled ?? null,
          p_limit: limit || 50,
          p_offset: offset || 0,
        }
      );

      if (listErr) {
        return jsonResponse({ error: listErr.message }, 500);
      }

      return jsonResponse({ success: true, users: users || [] });
    }

    return jsonResponse({ error: `Unknown action: ${action}` }, 400);
  } catch (err) {
    console.error("admin-manage-user error:", err);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
