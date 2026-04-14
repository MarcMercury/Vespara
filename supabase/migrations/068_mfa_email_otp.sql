-- Migration 068: Add email OTP as an alternative MFA method
-- Adds mfa_method column to profiles and creates mfa_email_codes table

-- Track which MFA method each user chose
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS mfa_method TEXT DEFAULT 'totp' CHECK (mfa_method IN ('totp', 'email'));

-- Table to store temporary email OTP codes
CREATE TABLE IF NOT EXISTS public.mfa_email_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_mfa_email_codes_user_id ON public.mfa_email_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_mfa_email_codes_expires ON public.mfa_email_codes(expires_at);

-- Cleanup old codes automatically (keep only last 24 hours)
CREATE OR REPLACE FUNCTION public.cleanup_expired_mfa_codes()
RETURNS void AS $$
BEGIN
  DELETE FROM public.mfa_email_codes WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS policies
ALTER TABLE public.mfa_email_codes ENABLE ROW LEVEL SECURITY;

-- Users can only see their own codes (but in practice, the edge function uses service role)
CREATE POLICY "Users can view own mfa codes" ON public.mfa_email_codes
  FOR SELECT USING (auth.uid() = user_id);

-- Only service role can insert/update (edge function)
CREATE POLICY "Service role manages mfa codes" ON public.mfa_email_codes
  FOR ALL USING (auth.role() = 'service_role');

-- Track last email OTP verification time for session validation
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS mfa_email_verified_at TIMESTAMPTZ;
