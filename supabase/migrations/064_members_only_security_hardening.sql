-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 064: Members-Only Security Hardening
-- Converts platform from public dating app to members-only private community
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. MEMBER STATUS & INVITE SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

-- Add membership status to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS membership_status TEXT DEFAULT 'pending'
    CHECK (membership_status IN ('pending', 'approved', 'suspended', 'banned')),
  ADD COLUMN IF NOT EXISTS invited_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS approved_by UUID,
  ADD COLUMN IF NOT EXISTS mfa_enrolled BOOLEAN DEFAULT FALSE;

-- Invite codes table
CREATE TABLE IF NOT EXISTS public.invite_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  used_by UUID REFERENCES auth.users(id),
  max_uses INTEGER DEFAULT 1,
  use_count INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE public.invite_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own invite codes"
  ON public.invite_codes FOR SELECT
  USING (auth.uid() = created_by);

CREATE POLICY "Users can create invite codes"
  ON public.invite_codes FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Only allow approved members to view other profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Members can view profiles"
  ON public.profiles FOR SELECT
  USING (
    auth.uid() = id
    OR (
      EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.membership_status = 'approved'
      )
      AND membership_status = 'approved'
    )
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. AUDIT LOG - Track sensitive operations
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  metadata JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Only service role can write audit logs
CREATE POLICY "Service role manages audit logs"
  ON public.audit_log FOR ALL
  USING (auth.role() = 'service_role');

-- Users can view their own audit trail
CREATE POLICY "Users can view own audit log"
  ON public.audit_log FOR SELECT
  USING (auth.uid() = user_id);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON public.audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON public.audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON public.audit_log(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. SESSION / DEVICE TRACKING
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_info TEXT,
  ip_address INET,
  user_agent TEXT,
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sessions"
  ON public.user_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can revoke own sessions"
  ON public.user_sessions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. RATE LIMITING TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  identifier TEXT NOT NULL, -- user_id or IP
  action TEXT NOT NULL,
  window_start TIMESTAMPTZ DEFAULT NOW(),
  request_count INTEGER DEFAULT 1,
  UNIQUE(identifier, action, window_start)
);

ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;

-- Only service role manages rate limits
CREATE POLICY "Service role manages rate limits"
  ON public.rate_limits FOR ALL
  USING (auth.role() = 'service_role');

-- Auto-cleanup old rate limit entries
CREATE INDEX IF NOT EXISTS idx_rate_limits_window ON public.rate_limits(window_start);

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. MAKE STORAGE PRIVATE BY DEFAULT
-- ═══════════════════════════════════════════════════════════════════════════

-- Revoke public avatar access - only authenticated members can view
DROP POLICY IF EXISTS "Avatars are publicly accessible" ON storage.objects;
CREATE POLICY "Authenticated members can view avatars"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
  );

-- Chat attachments bucket (private, signed URLs only)
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-attachments', 'chat-attachments', FALSE)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can upload chat attachments"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'chat-attachments'
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Authenticated users can view chat attachments"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'chat-attachments'
    AND auth.role() = 'authenticated'
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. HELPER FUNCTION: Check membership
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.is_approved_member(uid UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = uid AND membership_status = 'approved'
  );
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. DATA EXPORT / DELETE SUPPORT (GDPR)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.data_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  request_type TEXT NOT NULL CHECK (request_type IN ('export', 'delete')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.data_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own data requests"
  ON public.data_requests FOR ALL
  USING (auth.uid() = user_id);
