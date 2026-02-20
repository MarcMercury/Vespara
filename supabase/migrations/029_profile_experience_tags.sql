-- ============================================
-- KULT PROFILE EXPERIENCE TAGS
-- Migration 029: Add interest_tags and desire_tags columns
-- ============================================

-- Add interest_tags column for user interests (hobbies, activities)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS interest_tags TEXT[] DEFAULT '{}';
COMMENT ON COLUMN public.profiles.interest_tags IS 'Array of user interests/hobbies selected during Build experience';

-- Add desire_tags column for user desires (what they''re looking for in experiences)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS desire_tags TEXT[] DEFAULT '{}';
COMMENT ON COLUMN public.profiles.desire_tags IS 'Array of user desires selected during Build experience';

-- Add indexes for efficient querying on these array columns
CREATE INDEX IF NOT EXISTS idx_profiles_interest_tags ON public.profiles USING GIN(interest_tags);
CREATE INDEX IF NOT EXISTS idx_profiles_desire_tags ON public.profiles USING GIN(desire_tags);

-- Grant permissions
GRANT ALL ON public.profiles TO authenticated;
