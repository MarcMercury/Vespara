-- ============================================
-- VESPARA ONBOARDING SCHEMA EXTENSION
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. EXTEND PROFILES TABLE
-- ============================================

-- Add onboarding fields
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS photos TEXT[] DEFAULT '{}' CHECK (array_length(photos, 1) <= 3 OR photos = '{}');
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS vibe_tags TEXT[] DEFAULT '{}'; -- ["art", "tech", "enm"]
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bandwidth_level INT DEFAULT 100 CHECK (bandwidth_level >= 0 AND bandwidth_level <= 100);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_complete BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_name TEXT;

-- ============================================
-- 2. VIBE TAGS REFERENCE TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.vibe_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    emoji TEXT,
    category TEXT NOT NULL, -- 'lifestyle', 'personality', 'relationship', 'interest'
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed vibe tags
INSERT INTO public.vibe_tags (name, emoji, category, display_order) VALUES
-- Lifestyle
('Night Owl', '🦉', 'lifestyle', 1),
('Early Bird', '🌅', 'lifestyle', 2),
('Foodie', '🍽️', 'lifestyle', 3),
('Gym Rat', '💪', 'lifestyle', 4),
('Homebody', '🏠', 'lifestyle', 5),
('Adventurer', '🧗', 'lifestyle', 6),
('Jet Setter', '✈️', 'lifestyle', 7),
('Minimalist', '✨', 'lifestyle', 8),

-- Personality
('Sapiosexual', '🧠', 'personality', 10),
('Ambivert', '🎭', 'personality', 11),
('Empath', '💫', 'personality', 12),
('High-Agency', '🚀', 'personality', 13),
('Old Soul', '🕯️', 'personality', 14),
('Free Spirit', '🦋', 'personality', 15),
('Type A', '📋', 'personality', 16),
('Creative', '🎨', 'personality', 17),

-- Relationship Style
('Poly-Curious', '💜', 'relationship', 20),
('ENM', '💕', 'relationship', 21),
('Monogamous', '❤️', 'relationship', 22),
('Kink-Positive', '🔥', 'relationship', 23),
('Demisexual', '🌸', 'relationship', 24),
('Relationship Anarchist', '⚡', 'relationship', 25),
('Looking for Serious', '💍', 'relationship', 26),
('Casual Only', '🍃', 'relationship', 27),

-- Interests
('Founder', '💼', 'interest', 30),
('Artist', '🖼️', 'interest', 31),
('Tech', '💻', 'interest', 32),
('Finance', '📈', 'interest', 33),
('Music', '🎵', 'interest', 34),
('Film', '🎬', 'interest', 35),
('Literature', '📚', 'interest', 36),
('Spirituality', '🧘', 'interest', 37)
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 3. STORAGE BUCKET POLICIES
-- ============================================

-- Note: Run these in Supabase Dashboard > Storage > Policies
-- Or via the Storage API

-- Create avatars bucket (run in Storage section)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);

-- ============================================
-- 4. HELPER FUNCTIONS
-- ============================================

-- Calculate age from birth_date
CREATE OR REPLACE FUNCTION calculate_age(birth_date DATE)
RETURNS INT AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(NOW(), birth_date));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Check if user is 18+
CREATE OR REPLACE FUNCTION is_adult(birth_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN calculate_age(birth_date) >= 18;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Get bandwidth label
CREATE OR REPLACE FUNCTION get_bandwidth_label(level INT)
RETURNS TEXT AS $$
BEGIN
    IF level <= 20 THEN
        RETURN 'Hibernating';
    ELSIF level <= 40 THEN
        RETURN 'Low-Key';
    ELSIF level <= 60 THEN
        RETURN 'Open';
    ELSIF level <= 80 THEN
        RETURN 'Active';
    ELSE
        RETURN 'Ravenous';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 5. UPDATE TRIGGER FOR ONBOARDING
-- ============================================

-- When onboarding completes, update analytics
CREATE OR REPLACE FUNCTION on_onboarding_complete()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.onboarding_complete = TRUE AND OLD.onboarding_complete = FALSE THEN
        UPDATE public.user_analytics
        SET updated_at = NOW()
        WHERE user_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_onboarding_complete
    AFTER UPDATE ON public.profiles
    FOR EACH ROW
    WHEN (NEW.onboarding_complete = TRUE AND OLD.onboarding_complete = FALSE)
    EXECUTE FUNCTION on_onboarding_complete();

-- ============================================
-- 6. RLS FOR VIBE TAGS
-- ============================================

ALTER TABLE public.vibe_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vibe tags are public" ON public.vibe_tags
    FOR SELECT USING (is_active = TRUE);

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT SELECT ON public.vibe_tags TO anon, authenticated;
GRANT EXECUTE ON FUNCTION calculate_age TO authenticated;
GRANT EXECUTE ON FUNCTION is_adult TO authenticated;
GRANT EXECUTE ON FUNCTION get_bandwidth_label TO authenticated;
