-- ============================================
-- MIGRATION 046: Complete User Settings
-- Adds all missing settings columns for full functionality
-- ============================================

-- Add missing notification columns
ALTER TABLE public.user_settings
ADD COLUMN IF NOT EXISTS notify_date_reminders BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS notify_ai_insights BOOLEAN DEFAULT FALSE;

-- Add missing privacy columns
ALTER TABLE public.user_settings
ADD COLUMN IF NOT EXISTS show_online_status BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS read_receipts BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS profile_visible BOOLEAN DEFAULT TRUE;

-- Add account status columns
ALTER TABLE public.user_settings
ADD COLUMN IF NOT EXISTS is_paused BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS paused_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS pause_reason TEXT;

-- Add calendar sync columns
ALTER TABLE public.user_settings
ADD COLUMN IF NOT EXISTS google_calendar_connected BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS google_calendar_token TEXT,
ADD COLUMN IF NOT EXISTS apple_calendar_connected BOOLEAN DEFAULT FALSE;

-- Add relationship type preferences (stored as array)
ALTER TABLE public.user_settings
ADD COLUMN IF NOT EXISTS relationship_types TEXT[] DEFAULT ARRAY['Long-term', 'Casual', 'Friendship'];

-- Add phone column if not exists
ALTER TABLE public.user_settings
ADD COLUMN IF NOT EXISTS phone TEXT;

-- Add subscription info
ALTER TABLE public.user_settings
ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ;

-- Add comments for documentation
COMMENT ON COLUMN public.user_settings.notify_date_reminders IS 'Enable notifications for upcoming dates';
COMMENT ON COLUMN public.user_settings.notify_ai_insights IS 'Enable AI-generated insight notifications';
COMMENT ON COLUMN public.user_settings.show_online_status IS 'Show online status to other users';
COMMENT ON COLUMN public.user_settings.read_receipts IS 'Show read receipts in messages';
COMMENT ON COLUMN public.user_settings.profile_visible IS 'Profile visible in discovery';
COMMENT ON COLUMN public.user_settings.is_paused IS 'Account is paused - hidden from discovery';
COMMENT ON COLUMN public.user_settings.relationship_types IS 'Preferred relationship types for matching';
COMMENT ON COLUMN public.user_settings.subscription_tier IS 'free, plus, or premium';

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_user_settings_pause 
ON public.user_settings (user_id, is_paused);

CREATE INDEX IF NOT EXISTS idx_user_settings_visibility 
ON public.user_settings (user_id, profile_visible, is_paused);
