-- ============================================
-- Add onboarding profile columns
-- These columns support the enhanced onboarding flow
-- ============================================

-- Age verification
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS age_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS age_verified_at TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS age_verification_method TEXT;

-- Location (separate fields)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS state TEXT;

-- Identity
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pronouns TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS orientation TEXT[];

-- Make gender an array to support multiple identities
ALTER TABLE public.profiles DROP COLUMN IF EXISTS gender;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS gender TEXT[];

-- Relationship
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS relationship_status TEXT[];
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS seeking TEXT[];
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS partner_involvement TEXT;

-- Availability
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS availability_general TEXT[];
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS scheduling_style TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS hosting_status TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS discretion_level TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS travel_radius INTEGER;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS party_availability TEXT[];

-- Onboarding tracking
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_step INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;
