-- ============================================
-- VESPARA DATABASE SCHEMA
-- Run this in Supabase SQL Editor
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- 1. USER PROFILES
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    phone TEXT,
    date_of_birth DATE,
    gender TEXT,
    looking_for TEXT[], -- Array of preferences
    location_city TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    is_verified BOOLEAN DEFAULT FALSE,
    vouch_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- 2. ROSTER MATCHES (CRM)
-- ============================================
CREATE TYPE match_pipeline AS ENUM ('incoming', 'bench', 'active', 'legacy');
CREATE TYPE match_source AS ENUM ('tinder', 'hinge', 'bumble', 'irl', 'instagram', 'other');

CREATE TABLE IF NOT EXISTS public.roster_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    nickname TEXT,
    avatar_url TEXT,
    source match_source DEFAULT 'other',
    source_username TEXT,
    pipeline match_pipeline DEFAULT 'incoming',
    momentum_score DOUBLE PRECISION DEFAULT 0.5, -- 0.0 to 1.0
    notes TEXT,
    interests TEXT[],
    last_contact_date TIMESTAMPTZ,
    next_action TEXT,
    is_archived BOOLEAN DEFAULT FALSE,
    archived_at TIMESTAMPTZ,
    archive_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.roster_matches ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own matches" ON public.roster_matches
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own matches" ON public.roster_matches
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own matches" ON public.roster_matches
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own matches" ON public.roster_matches
    FOR DELETE USING (auth.uid() = user_id);

-- Index for faster queries
CREATE INDEX idx_roster_matches_user_pipeline ON public.roster_matches(user_id, pipeline);
CREATE INDEX idx_roster_matches_momentum ON public.roster_matches(user_id, momentum_score DESC);

-- ============================================
-- 3. CONVERSATIONS (The Wire)
-- ============================================
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_id UUID NOT NULL REFERENCES public.roster_matches(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_by UUID, -- user_id or match_id conceptually
    unread_count INTEGER DEFAULT 0,
    momentum_score DOUBLE PRECISION DEFAULT 0.5,
    is_stale BOOLEAN DEFAULT FALSE,
    stale_since TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own conversations" ON public.conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own conversations" ON public.conversations
    FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_conversations_user_momentum ON public.conversations(user_id, momentum_score DESC);
CREATE INDEX idx_conversations_stale ON public.conversations(user_id, is_stale) WHERE is_stale = TRUE;

-- ============================================
-- 4. MESSAGES
-- ============================================
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL, -- user_id
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    is_ai_generated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own messages" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversations c 
            WHERE c.id = conversation_id AND c.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own messages" ON public.messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.conversations c 
            WHERE c.id = conversation_id AND c.user_id = auth.uid()
        )
    );

CREATE INDEX idx_messages_conversation ON public.messages(conversation_id, created_at DESC);

-- ============================================
-- 5. TAGS GAMES (Ludus)
-- ============================================
CREATE TYPE tags_category AS ENUM ('icebreaker', 'spicy', 'deep', 'fantasy', 'challenge');
CREATE TYPE consent_level AS ENUM ('green', 'yellow', 'red');

CREATE TABLE IF NOT EXISTS public.tags_games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    category tags_category NOT NULL,
    min_consent_level consent_level DEFAULT 'green',
    prompts JSONB NOT NULL, -- Array of game prompts
    is_premium BOOLEAN DEFAULT FALSE,
    play_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5B. GAME CARDS (Pleasure Deck)
-- ============================================
CREATE TABLE IF NOT EXISTS public.game_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content TEXT NOT NULL,
    level consent_level NOT NULL DEFAULT 'green',
    is_truth BOOLEAN NOT NULL DEFAULT true,
    intensity INTEGER CHECK (intensity BETWEEN 1 AND 5) DEFAULT 1,
    category tags_category DEFAULT 'icebreaker',
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_game_cards_level ON public.game_cards(level);
CREATE INDEX idx_game_cards_intensity ON public.game_cards(intensity);

-- ============================================
-- 6. GAME SESSIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.game_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID NOT NULL REFERENCES public.tags_games(id) ON DELETE CASCADE,
    host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_id UUID REFERENCES public.roster_matches(id) ON DELETE SET NULL,
    consent_level consent_level NOT NULL,
    current_prompt_index INTEGER DEFAULT 0,
    responses JSONB DEFAULT '[]'::jsonb,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own game sessions" ON public.game_sessions
    FOR SELECT USING (auth.uid() = host_id);

CREATE POLICY "Users can manage own game sessions" ON public.game_sessions
    FOR ALL USING (auth.uid() = host_id);

-- ============================================
-- 7. VOUCH CHAIN
-- ============================================
CREATE TABLE IF NOT EXISTS public.vouches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    voucher_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    vouchee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT,
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(voucher_id, vouchee_id)
);

-- Enable RLS
ALTER TABLE public.vouches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view vouches involving them" ON public.vouches
    FOR SELECT USING (auth.uid() = voucher_id OR auth.uid() = vouchee_id);

CREATE POLICY "Users can create vouches" ON public.vouches
    FOR INSERT WITH CHECK (auth.uid() = voucher_id);

-- ============================================
-- 8. VOUCH LINKS
-- ============================================
CREATE TABLE IF NOT EXISTS public.vouch_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used_by UUID REFERENCES public.profiles(id),
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.vouch_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own vouch links" ON public.vouch_links
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own vouch links" ON public.vouch_links
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 9. USER ANALYTICS (The Mirror)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    total_matches INTEGER DEFAULT 0,
    active_conversations INTEGER DEFAULT 0,
    dates_scheduled INTEGER DEFAULT 0,
    ghost_rate DOUBLE PRECISION DEFAULT 0,
    flake_rate DOUBLE PRECISION DEFAULT 0,
    swipe_ratio DOUBLE PRECISION DEFAULT 50,
    response_rate DOUBLE PRECISION DEFAULT 50,
    messages_sent INTEGER DEFAULT 0,
    messages_received INTEGER DEFAULT 0,
    first_messages_sent INTEGER DEFAULT 0,
    conversations_started INTEGER DEFAULT 0,
    weekly_activity DOUBLE PRECISION[] DEFAULT ARRAY[0,0,0,0,0,0,0]::DOUBLE PRECISION[],
    peak_activity_time TEXT DEFAULT '8pm - 10pm',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own analytics" ON public.user_analytics
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own analytics" ON public.user_analytics
    FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- 10. STRATEGIST ADVICE LOG
-- ============================================
CREATE TABLE IF NOT EXISTS public.strategist_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_id UUID REFERENCES public.roster_matches(id) ON DELETE SET NULL,
    query TEXT NOT NULL,
    response TEXT NOT NULL,
    model TEXT DEFAULT 'gpt-4-turbo',
    tokens_used INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.strategist_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own strategist logs" ON public.strategist_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own strategist logs" ON public.strategist_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 11. SHREDDER ARCHIVE (Ghost Protocol)
-- ============================================
CREATE TABLE IF NOT EXISTS public.shredder_archive (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_name TEXT NOT NULL,
    match_source TEXT,
    closure_message TEXT,
    message_sent BOOLEAN DEFAULT FALSE,
    tone TEXT DEFAULT 'kind',
    shredded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.shredder_archive ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own shredder archive" ON public.shredder_archive
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert to shredder archive" ON public.shredder_archive
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 12. USER SETTINGS
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Notifications
    notify_new_messages BOOLEAN DEFAULT TRUE,
    notify_new_matches BOOLEAN DEFAULT TRUE,
    notify_strategist_insights BOOLEAN DEFAULT FALSE,
    notify_stale_alerts BOOLEAN DEFAULT TRUE,
    -- Privacy
    location_sharing TEXT DEFAULT 'while_using', -- 'always', 'while_using', 'never'
    profile_hidden BOOLEAN DEFAULT FALSE,
    -- Appearance
    text_size TEXT DEFAULT 'medium', -- 'small', 'medium', 'large'
    -- Data
    last_cache_clear TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own settings" ON public.user_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own settings" ON public.user_settings
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 13. BLOCKED USERS
-- ============================================
CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, blocked_user_id)
);

-- Enable RLS
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own blocks" ON public.blocked_users
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own blocks" ON public.blocked_users
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 14. TONIGHT MODE LOCATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.tonight_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    venue_name TEXT,
    venue_type TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.tonight_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view active locations" ON public.tonight_locations
    FOR SELECT USING (is_active = TRUE AND expires_at > NOW());

CREATE POLICY "Users can manage own locations" ON public.tonight_locations
    FOR ALL USING (auth.uid() = user_id);

-- Spatial index for location queries (if PostGIS enabled)
-- CREATE INDEX idx_tonight_locations_geo ON public.tonight_locations USING GIST (ST_MakePoint(lng, lat));

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_roster_matches_updated_at
    BEFORE UPDATE ON public.roster_matches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name)
    VALUES (NEW.id, NEW.email, SPLIT_PART(NEW.email, '@', 1));
    
    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id);
    
    INSERT INTO public.user_analytics (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Mark conversation as stale (>3 days no activity)
CREATE OR REPLACE FUNCTION mark_stale_conversations()
RETURNS void AS $$
BEGIN
    UPDATE public.conversations
    SET is_stale = TRUE, stale_since = NOW()
    WHERE last_message_at < NOW() - INTERVAL '3 days'
    AND is_stale = FALSE;
END;
$$ LANGUAGE plpgsql;

-- Update vouch count on profile
CREATE OR REPLACE FUNCTION update_vouch_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.profiles
        SET vouch_count = vouch_count + 1
        WHERE id = NEW.vouchee_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.profiles
        SET vouch_count = vouch_count - 1
        WHERE id = OLD.vouchee_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_vouch_count_trigger
    AFTER INSERT OR DELETE ON public.vouches
    FOR EACH ROW EXECUTE FUNCTION update_vouch_count();

-- ============================================
-- SEED DATA: TAGS GAMES
-- ============================================
INSERT INTO public.tags_games (title, description, category, min_consent_level, prompts) VALUES
('First Date Icebreakers', 'Perfect for breaking the tension on a first date', 'icebreaker', 'green', 
 '[{"prompt": "What''s the most spontaneous thing you''ve ever done?", "type": "question"},
   {"prompt": "If you could have dinner with anyone, dead or alive, who would it be?", "type": "question"},
   {"prompt": "What''s your guilty pleasure TV show?", "type": "question"},
   {"prompt": "What''s the worst date you''ve ever been on? (Make it funny)", "type": "question"},
   {"prompt": "If you won the lottery tomorrow, what''s the first thing you''d do?", "type": "question"}]'::jsonb),

('Truth or Dare Lite', 'Classic game with a modern twist', 'icebreaker', 'green',
 '[{"prompt": "Truth: What''s the most embarrassing song on your playlist?", "type": "truth"},
   {"prompt": "Dare: Send the last photo in your camera roll (SFW only!)", "type": "dare"},
   {"prompt": "Truth: What''s your biggest pet peeve in dating?", "type": "truth"},
   {"prompt": "Dare: Do your best celebrity impression", "type": "dare"},
   {"prompt": "Truth: What''s something you''ve never told anyone on a first date?", "type": "truth"}]'::jsonb),

('Getting Deeper', 'For when you want to move past small talk', 'deep', 'green',
 '[{"prompt": "What''s a belief you held strongly that you''ve since changed?", "type": "question"},
   {"prompt": "What does your ideal relationship look like?", "type": "question"},
   {"prompt": "What''s something you''re working on improving about yourself?", "type": "question"},
   {"prompt": "What''s the most valuable lesson a past relationship taught you?", "type": "question"},
   {"prompt": "What makes you feel most alive?", "type": "question"}]'::jsonb),

('Spicy Questions', 'Turn up the heat (with consent)', 'spicy', 'yellow',
 '[{"prompt": "What''s your love language and how do you like it expressed?", "type": "question"},
   {"prompt": "What''s a romantic fantasy you''ve never acted on?", "type": "question"},
   {"prompt": "What''s the most romantic thing someone could do for you?", "type": "question"},
   {"prompt": "Physical touch: what''s your favorite non-sexual form?", "type": "question"},
   {"prompt": "What''s a dealbreaker for you in the bedroom?", "type": "question"}]'::jsonb),

('Fantasy Scenarios', 'Explore hypotheticals together', 'fantasy', 'yellow',
 '[{"prompt": "We just won an all-expenses-paid trip anywhere. Where are we going?", "type": "scenario"},
   {"prompt": "It''s a lazy Sunday with no obligations. Describe our perfect day.", "type": "scenario"},
   {"prompt": "We''re starting a business together. What is it?", "type": "scenario"},
   {"prompt": "You can plan any date, money is no object. What do we do?", "type": "scenario"},
   {"prompt": "We have to survive a zombie apocalypse together. What''s our strategy?", "type": "scenario"}]'::jsonb),

('Couples Challenge', 'Fun challenges to do together', 'challenge', 'green',
 '[{"prompt": "Challenge: Describe each other in 3 words", "type": "challenge"},
   {"prompt": "Challenge: Guess each other''s coffee/drink order", "type": "challenge"},
   {"prompt": "Challenge: Rock paper scissors - loser buys next round", "type": "challenge"},
   {"prompt": "Challenge: Staring contest. First to laugh loses.", "type": "challenge"},
   {"prompt": "Challenge: Each share one thing you''ve noticed about the other tonight", "type": "challenge"}]'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================
-- SEED DATA: GAME CARDS (Pleasure Deck)
-- ============================================
INSERT INTO public.game_cards (content, level, is_truth, intensity, category) VALUES
-- GREEN LEVEL (Social & Flirtatious) - Intensity 1-2
('What''s the most romantic gesture someone has ever done for you?', 'green', true, 1, 'icebreaker'),
('What song makes you think of romance?', 'green', true, 1, 'icebreaker'),
('Describe your perfect first kiss scenario', 'green', true, 1, 'icebreaker'),
('What''s your biggest turn-off on a first date?', 'green', true, 2, 'icebreaker'),
('What physical feature do you notice first in someone?', 'green', true, 2, 'icebreaker'),
('Give your best genuine compliment', 'green', false, 1, 'icebreaker'),
('Hold eye contact for 30 seconds without laughing', 'green', false, 1, 'icebreaker'),
('Show your most attractive selfie angle', 'green', false, 2, 'icebreaker'),
('Do your best "come hither" look', 'green', false, 2, 'icebreaker'),
('Whisper something flirty in their ear', 'green', false, 2, 'icebreaker'),

-- YELLOW LEVEL (Sensual & Suggestive) - Intensity 2-4
('What''s a romantic fantasy you''ve never shared?', 'yellow', true, 2, 'spicy'),
('Describe the best kiss you''ve ever had', 'yellow', true, 2, 'spicy'),
('What''s your favorite place to be touched (non-explicit)?', 'yellow', true, 3, 'spicy'),
('What outfit makes you feel most confident and sexy?', 'yellow', true, 3, 'spicy'),
('What''s the boldest thing you''ve done to get someone''s attention?', 'yellow', true, 3, 'spicy'),
('Give them a 10-second shoulder massage', 'yellow', false, 2, 'spicy'),
('Trace a heart on their palm with your finger', 'yellow', false, 3, 'spicy'),
('Feed them a bite of something', 'yellow', false, 3, 'spicy'),
('Slow dance together for one song', 'yellow', false, 3, 'spicy'),
('Kiss them on the cheek with genuine affection', 'yellow', false, 4, 'spicy'),

-- RED LEVEL (Erotic & Explicit) - Intensity 4-5
('Describe your biggest fantasy in detail', 'red', true, 4, 'fantasy'),
('What''s the most adventurous thing on your bedroom bucket list?', 'red', true, 4, 'fantasy'),
('Rate from 1-10: passion vs tenderness - what do you prefer?', 'red', true, 4, 'fantasy'),
('What words do you want to hear in an intimate moment?', 'red', true, 5, 'fantasy'),
('Describe your ideal scenario for later tonight', 'red', true, 5, 'fantasy'),
('Give a sensual neck kiss for 5 seconds', 'red', false, 4, 'fantasy'),
('Whisper your biggest desire into their ear', 'red', false, 4, 'fantasy'),
('Guide their hand to where you want to be touched (clothed)', 'red', false, 5, 'fantasy'),
('Kiss like you mean it for 30 seconds', 'red', false, 5, 'fantasy'),
('Describe exactly what you want to do together later', 'red', false, 5, 'fantasy')
ON CONFLICT DO NOTHING;

-- ============================================
-- STORED FUNCTIONS
-- ============================================

-- Generate Vouch Link Function
CREATE OR REPLACE FUNCTION generate_vouch_link(user_id UUID)
RETURNS TEXT AS $$
DECLARE
    link_code TEXT;
    full_link TEXT;
BEGIN
    -- Generate a unique code
    link_code := encode(gen_random_bytes(12), 'base64');
    link_code := replace(replace(replace(link_code, '+', 'X'), '/', 'Y'), '=', '');
    
    -- Insert the vouch link
    INSERT INTO public.vouch_links (user_id, code, expires_at)
    VALUES (user_id, link_code, NOW() + INTERVAL '7 days');
    
    -- Return the full link
    full_link := 'https://vespara.co/vouch/' || link_code;
    RETURN full_link;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Focus Batch Function (AI-curated matches for The Scope)
CREATE OR REPLACE FUNCTION get_focus_batch(p_user_id UUID, batch_size INTEGER DEFAULT 5)
RETURNS SETOF roster_matches AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.roster_matches
    WHERE user_id = p_user_id
      AND is_archived = false
      AND pipeline NOT IN ('on_way_out', 'legacy')
    ORDER BY 
        momentum_score DESC,
        last_contact_date DESC NULLS LAST
    LIMIT batch_size;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate Momentum Score Function
CREATE OR REPLACE FUNCTION calculate_momentum_score(match_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    match_record RECORD;
    score DECIMAL := 0;
    days_since_interaction INTEGER;
    message_count INTEGER;
BEGIN
    SELECT * INTO match_record FROM public.roster_matches WHERE id = match_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Base score from interaction recency
    days_since_interaction := EXTRACT(DAY FROM (NOW() - COALESCE(match_record.last_contact_date, match_record.created_at)));
    
    IF days_since_interaction <= 1 THEN
        score := 100;
    ELSIF days_since_interaction <= 3 THEN
        score := 80;
    ELSIF days_since_interaction <= 7 THEN
        score := 60;
    ELSIF days_since_interaction <= 14 THEN
        score := 40;
    ELSE
        score := 20;
    END IF;
    
    -- Boost for active conversation
    SELECT COUNT(*) INTO message_count 
    FROM public.messages m
    JOIN public.conversations c ON m.conversation_id = c.id
    WHERE c.match_id = match_id
    AND m.created_at > NOW() - INTERVAL '7 days';
    
    score := score + LEAST(message_count * 2, 20);
    
    -- Apply momentum multiplier
    score := score * GREATEST(match_record.momentum_score, 0.1);
    
    RETURN LEAST(score, 100);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update momentum scores trigger
CREATE OR REPLACE FUNCTION update_match_momentum()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.roster_matches
    SET momentum_score = calculate_momentum_score(NEW.match_id),
        last_contact_date = NOW()
    WHERE id = NEW.match_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Get Stale Matches Function (for The Shredder)
CREATE OR REPLACE FUNCTION get_stale_matches(p_user_id UUID, days_threshold INTEGER DEFAULT 30)
RETURNS SETOF roster_matches AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.roster_matches
    WHERE user_id = p_user_id
      AND is_archived = false
      AND (
      AND (last_contact_date IS NULL 
          OR last_contact_date < NOW() - (days_threshold || ' days')::INTERVAL
      )
    ORDER BY last_contact_date ASC NULLS FIRST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Tonight Mode Nearby Users Function
CREATE OR REPLACE FUNCTION get_nearby_users(
    p_user_id UUID,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE(
    user_id UUID,
    display_name TEXT,
    distance_km DOUBLE PRECISION,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tl.user_id,
        p.display_name,
        -- Haversine formula for distance calculation
        (6371 * acos(
            cos(radians(p_latitude)) * cos(radians(tl.lat)) *
            cos(radians(tl.lng) - radians(p_longitude)) +
            sin(radians(p_latitude)) * sin(radians(tl.lat))
        )) AS distance_km,
        tl.created_at
    FROM public.tonight_locations tl
    JOIN public.profiles p ON tl.user_id = p.id
    WHERE tl.is_active = true
      AND tl.user_id != p_user_id
      AND tl.expires_at > NOW()
      AND (6371 * acos(
            cos(radians(p_latitude)) * cos(radians(tl.lat)) *
            cos(radians(tl.lng) - radians(p_longitude)) +
            sin(radians(p_latitude)) * sin(radians(tl.lat))
        )) <= p_radius_km
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
