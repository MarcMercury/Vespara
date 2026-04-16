import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ADMIN_USER_IDS = (Deno.env.get("ADMIN_USER_IDS") || "").split(",").map((id) => id.trim()).filter(Boolean);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), { status: 401, headers: corsHeaders });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: corsHeaders });
    }

    // Check admin access
    if (!ADMIN_USER_IDS.includes(user.id)) {
      // Also check profile.is_admin flag
      const { data: profile } = await supabase
        .from("profiles")
        .select("is_admin")
        .eq("id", user.id)
        .single();

      if (!profile?.is_admin) {
        return new Response(JSON.stringify({ error: "Forbidden: admin only" }), { status: 403, headers: corsHeaders });
      }
    }

    const { member_id, action } = await req.json();

    if (!member_id || !action) {
      return new Response(JSON.stringify({ error: "Missing member_id or action" }), { status: 400, headers: corsHeaders });
    }

    if (!["approve", "reject", "suspend"].includes(action)) {
      return new Response(JSON.stringify({ error: "Invalid action" }), { status: 400, headers: corsHeaders });
    }

    const statusMap: Record<string, string> = {
      approve: "approved",
      reject: "rejected",
      suspend: "suspended",
    };

    const newStatus = statusMap[action];

    // Update membership status
    const { error: updateError } = await supabase
      .from("profiles")
      .update({
        membership_status: newStatus,
        updated_at: new Date().toISOString(),
      })
      .eq("id", member_id);

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), { status: 500, headers: corsHeaders });
    }

    // Log the action
    await supabase.from("audit_log").insert({
      user_id: user.id,
      action: `admin:${action}_member`,
      details: { member_id, new_status: newStatus },
    });

    // Send notification email if approved
    if (action === "approve") {
      const { data: memberProfile } = await supabase
        .from("profiles")
        .select("display_name")
        .eq("id", member_id)
        .single();

      const { data: memberAuth } = await supabase.auth.admin.getUserById(member_id);

      if (memberAuth?.user?.email) {
        // Call send-email function
        await supabase.functions.invoke("send-email", {
          body: {
            type: "member_approved",
            to: memberAuth.user.email,
            data: { display_name: memberProfile?.display_name || "Member" },
          },
        });
      }
    }

    return new Response(
      JSON.stringify({ success: true, member_id, status: newStatus }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("admin-approve-member error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), { status: 500, headers: corsHeaders });
  }
});
