-- ============================================================================
-- Migration 042: Fix handle_new_user trigger to prevent duplicate key errors
-- ============================================================================

-- Update the handle_new_user function to use ON CONFLICT DO NOTHING
-- This prevents errors when user already has profile/settings/analytics
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create profile if not exists
    INSERT INTO public.profiles (id, email, display_name)
    VALUES (NEW.id, NEW.email, SPLIT_PART(NEW.email, '@', 1))
    ON CONFLICT (id) DO NOTHING;
    
    -- Create user_settings if not exists
    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Create user_analytics if not exists
    INSERT INTO public.user_analytics (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the ensure_user_analytics function to be more robust
CREATE OR REPLACE FUNCTION public.ensure_user_analytics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_analytics (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
