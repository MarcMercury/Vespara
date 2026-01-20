-- ============================================
-- Add ZIP code field to profiles
-- ============================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS zip_code TEXT;

-- Add index for location-based queries
CREATE INDEX IF NOT EXISTS idx_profiles_zip_code ON public.profiles(zip_code) WHERE zip_code IS NOT NULL;
