-- ============================================
-- MIGRATION 036: Add Discovery Settings to user_settings
-- Adds age range, distance, and show_me preferences
-- ============================================

-- Add new columns for discovery settings
ALTER TABLE public.user_settings
ADD COLUMN IF NOT EXISTS min_age INTEGER DEFAULT 21,
ADD COLUMN IF NOT EXISTS max_age INTEGER DEFAULT 55,
ADD COLUMN IF NOT EXISTS max_distance INTEGER DEFAULT 50,
ADD COLUMN IF NOT EXISTS show_me TEXT DEFAULT 'Everyone';

-- Add comment for documentation
COMMENT ON COLUMN public.user_settings.min_age IS 'Minimum age preference for discovery (18-65)';
COMMENT ON COLUMN public.user_settings.max_age IS 'Maximum age preference for discovery (18-65)';
COMMENT ON COLUMN public.user_settings.max_distance IS 'Maximum distance in miles for discovery (1-100)';
COMMENT ON COLUMN public.user_settings.show_me IS 'Gender preference for discovery: Women, Men, Everyone';

-- Create index for common queries
CREATE INDEX IF NOT EXISTS idx_user_settings_discovery 
ON public.user_settings (user_id, min_age, max_age, max_distance);
