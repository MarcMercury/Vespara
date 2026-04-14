-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 066: Admin Portal — User Management & Token Tracking
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. PROFILE COLUMNS FOR ADMIN MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS disabled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS disabled_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS login_count INTEGER DEFAULT 0;

-- Index for admin queries
CREATE INDEX IF NOT EXISTS idx_profiles_is_admin ON public.profiles(is_admin) WHERE is_admin = TRUE;
CREATE INDEX IF NOT EXISTS idx_profiles_is_disabled ON public.profiles(is_disabled) WHERE is_disabled = TRUE;
CREATE INDEX IF NOT EXISTS idx_profiles_last_login ON public.profiles(last_login_at DESC NULLS LAST);

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. TOKEN USAGE TRACKING
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.token_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  service TEXT NOT NULL CHECK (service IN ('openai', 'gemini', 'stream_chat', 'cloudinary', 'resend', 'other')),
  operation TEXT NOT NULL,          -- e.g. 'generate_bio', 'deep_bio', 'chat_completion', 'nudge'
  tokens_input INTEGER DEFAULT 0,
  tokens_output INTEGER DEFAULT 0,
  tokens_total INTEGER GENERATED ALWAYS AS (tokens_input + tokens_output) STORED,
  cost_cents NUMERIC(10,4) DEFAULT 0,
  model TEXT,                       -- e.g. 'gpt-4-turbo-preview', 'gemini-pro'
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.token_usage ENABLE ROW LEVEL SECURITY;

-- Admins can see all token usage; users see their own
CREATE POLICY "Admins can view all token usage"
  ON public.token_usage FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

CREATE POLICY "Users can view own token usage"
  ON public.token_usage FOR SELECT
  USING (auth.uid() = user_id);

-- Only service role inserts token usage (from edge functions)
CREATE POLICY "Service role inserts token usage"
  ON public.token_usage FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

-- Indexes for admin dashboard queries
CREATE INDEX IF NOT EXISTS idx_token_usage_user_id ON public.token_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_token_usage_service ON public.token_usage(service);
CREATE INDEX IF NOT EXISTS idx_token_usage_created_at ON public.token_usage(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_token_usage_user_service ON public.token_usage(user_id, service, created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. ADMIN HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Check if caller is admin
CREATE OR REPLACE FUNCTION public.is_admin(uid UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = uid AND is_admin = TRUE
  );
$$;

-- Get user token usage summary
CREATE OR REPLACE FUNCTION public.admin_get_token_summary(target_user_id UUID)
RETURNS TABLE (
  service TEXT,
  total_tokens BIGINT,
  total_cost NUMERIC,
  request_count BIGINT,
  last_used TIMESTAMPTZ
)
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT
    tu.service,
    SUM(tu.tokens_total)::BIGINT AS total_tokens,
    SUM(tu.cost_cents) AS total_cost,
    COUNT(*)::BIGINT AS request_count,
    MAX(tu.created_at) AS last_used
  FROM public.token_usage tu
  WHERE tu.user_id = target_user_id
  GROUP BY tu.service;
$$;

-- Admin user list view with aggregated info
CREATE OR REPLACE FUNCTION public.admin_list_users(
  p_search TEXT DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_disabled BOOLEAN DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  email TEXT,
  display_name TEXT,
  avatar_url TEXT,
  membership_status TEXT,
  is_disabled BOOLEAN,
  is_admin BOOLEAN,
  last_login_at TIMESTAMPTZ,
  login_count INTEGER,
  created_at TIMESTAMPTZ,
  mfa_enrolled BOOLEAN,
  total_tokens BIGINT,
  total_cost NUMERIC
)
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT
    p.id,
    p.email,
    p.display_name,
    p.avatar_url,
    p.membership_status,
    COALESCE(p.is_disabled, FALSE),
    COALESCE(p.is_admin, FALSE),
    p.last_login_at,
    COALESCE(p.login_count, 0),
    p.created_at,
    COALESCE(p.mfa_enrolled, FALSE),
    COALESCE(SUM(tu.tokens_total), 0)::BIGINT,
    COALESCE(SUM(tu.cost_cents), 0)
  FROM public.profiles p
  LEFT JOIN public.token_usage tu ON tu.user_id = p.id
  WHERE
    (p_search IS NULL OR p.display_name ILIKE '%' || p_search || '%' OR p.email ILIKE '%' || p_search || '%')
    AND (p_status IS NULL OR p.membership_status = p_status)
    AND (p_disabled IS NULL OR COALESCE(p.is_disabled, FALSE) = p_disabled)
  GROUP BY p.id, p.email, p.display_name, p.avatar_url, p.membership_status,
           p.is_disabled, p.is_admin, p.last_login_at, p.login_count, p.created_at, p.mfa_enrolled
  ORDER BY p.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. UPDATE LAST LOGIN TRIGGER
-- ═══════════════════════════════════════════════════════════════════════════

-- Function to track login events (called from edge function or client)
CREATE OR REPLACE FUNCTION public.track_user_login(uid UUID)
RETURNS VOID
LANGUAGE PLPGSQL
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
  SET
    last_login_at = NOW(),
    login_count = COALESCE(login_count, 0) + 1,
    updated_at = NOW()
  WHERE id = uid;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. ADMIN-ONLY RLS POLICIES FOR PROFILES (admin can see all)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = TRUE
    )
  );

CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = TRUE
    )
  );

-- Admins can view all audit logs
CREATE POLICY "Admins can view all audit logs"
  ON public.audit_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = TRUE
    )
  );

-- Admins can view all sessions
CREATE POLICY "Admins can view all user sessions"
  ON public.user_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = TRUE
    )
  );
