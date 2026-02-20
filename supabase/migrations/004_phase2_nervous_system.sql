-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                     KULT PHASE 2: THE NERVOUS SYSTEM                      ║
-- ║              Schema Extensions, Enums, RLS & Helper Functions             ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 0: ENABLE POSTGIS EXTENSION
-- ═══════════════════════════════════════════════════════════════════════════
CREATE EXTENSION IF NOT EXISTS postgis;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 1: CUSTOM TYPES / ENUMS
-- ═══════════════════════════════════════════════════════════════════════════

-- User Status Enum (for Tonight Mode)
DO $$ BEGIN
    CREATE TYPE user_status AS ENUM ('active', 'tonight_mode', 'hibernating');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Match Pipeline Stage Enum
DO $$ BEGIN
    CREATE TYPE pipeline_stage AS ENUM ('incoming', 'bench', 'active', 'legacy', 'archived');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- TAGS Consent Level Enum
DO $$ BEGIN
    CREATE TYPE consent_level AS ENUM ('green', 'yellow', 'red');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 2: EXTEND PROFILES TABLE
-- ═══════════════════════════════════════════════════════════════════════════

-- Add Phase 2 columns to profiles
ALTER TABLE public.profiles 
    ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS vouch_score INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS ghost_rate FLOAT DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS current_status TEXT DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326),
    ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS tags_preferences JSONB DEFAULT '{"green": true, "yellow": false, "red": false}'::jsonb,
    ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ DEFAULT NOW();

-- Create index on location for geospatial queries
CREATE INDEX IF NOT EXISTS idx_profiles_location ON public.profiles USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles (current_status);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles (username);

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 3: EXTEND ROSTER_MATCHES TABLE
-- ═══════════════════════════════════════════════════════════════════════════

-- Add real-time sync columns
ALTER TABLE public.roster_matches
    ADD COLUMN IF NOT EXISTS pipeline_stage TEXT DEFAULT 'incoming',
    ADD COLUMN IF NOT EXISTS last_interaction TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS interaction_count INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS is_nearby BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS distance_km FLOAT;

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_roster_matches_user_stage 
    ON public.roster_matches (user_id, pipeline_stage);
CREATE INDEX IF NOT EXISTS idx_roster_matches_momentum 
    ON public.roster_matches (momentum_score DESC);
CREATE INDEX IF NOT EXISTS idx_roster_matches_last_interaction 
    ON public.roster_matches (last_interaction DESC NULLS LAST);

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 4: LUDUS GAMES TABLE (TAGS Engine)
-- ═══════════════════════════════════════════════════════════════════════════

-- Create ludus_games table for TAGS game definitions
CREATE TABLE IF NOT EXISTS public.ludus_games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL, -- 'pleasure_deck', 'path_of_pleasure', 'other_room', etc.
    rating_level TEXT NOT NULL DEFAULT 'green', -- 'green', 'yellow', 'red'
    min_players INT DEFAULT 2,
    max_players INT DEFAULT 10,
    estimated_duration INT DEFAULT 30, -- minutes
    content JSONB NOT NULL DEFAULT '{}', -- game-specific data, cards, prompts
    thumbnail_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    play_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ludus_games_rating ON public.ludus_games (rating_level);
CREATE INDEX IF NOT EXISTS idx_ludus_games_category ON public.ludus_games (category);

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 5: EVENTS TABLE (The Socialite)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date TIMESTAMPTZ NOT NULL,
    location_name TEXT,
    location_coords GEOGRAPHY(POINT, 4326),
    max_attendees INT DEFAULT 20,
    is_private BOOLEAN DEFAULT FALSE,
    invite_code TEXT UNIQUE,
    attendees UUID[] DEFAULT '{}',
    waitlist UUID[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    status TEXT DEFAULT 'upcoming', -- 'upcoming', 'active', 'completed', 'cancelled'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_host ON public.events (host_id);
CREATE INDEX IF NOT EXISTS idx_events_date ON public.events (event_date);
CREATE INDEX IF NOT EXISTS idx_events_status ON public.events (status);

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 6: GAME SESSIONS TABLE (Active TAGS Games)
-- ═══════════════════════════════════════════════════════════════════════════

-- First, drop the partially created table if it exists (from failed migration)
DROP TABLE IF EXISTS public.game_sessions CASCADE;

-- Now create the full table
CREATE TABLE public.game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES public.ludus_games(id) ON DELETE CASCADE,
    host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    participants UUID[] NOT NULL DEFAULT '{}',
    consent_level TEXT NOT NULL DEFAULT 'green',
    current_round INT DEFAULT 0,
    game_state JSONB DEFAULT '{}', -- current card, scores, etc.
    is_active BOOLEAN DEFAULT TRUE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_game_sessions_host ON public.game_sessions (host_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_active ON public.game_sessions (is_active);

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 7: ROW LEVEL SECURITY POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

-- Enable RLS on new tables
ALTER TABLE public.ludus_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;

-- Ludus Games: Anyone can read active games
CREATE POLICY "Anyone can read active games" ON public.ludus_games
    FOR SELECT USING (is_active = true);

-- Events: Host can manage, attendees can view
CREATE POLICY "Users can view events they're invited to" ON public.events
    FOR SELECT USING (
        host_id = auth.uid() OR 
        auth.uid() = ANY(attendees) OR
        is_private = false
    );

CREATE POLICY "Hosts can manage their events" ON public.events
    FOR ALL USING (host_id = auth.uid());

-- Game Sessions: Participants can view, host can manage
CREATE POLICY "Participants can view game sessions" ON public.game_sessions
    FOR SELECT USING (
        host_id = auth.uid() OR 
        auth.uid() = ANY(participants)
    );

CREATE POLICY "Hosts can manage game sessions" ON public.game_sessions
    FOR ALL USING (host_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 8: REAL-TIME SUBSCRIPTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Enable realtime for roster_matches
ALTER PUBLICATION supabase_realtime ADD TABLE public.roster_matches;

-- Enable realtime for conversations
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

-- Enable realtime for game_sessions
ALTER PUBLICATION supabase_realtime ADD TABLE public.game_sessions;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 9: DATABASE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Function: Update match pipeline stage with optimistic locking
CREATE OR REPLACE FUNCTION update_match_stage(
    p_match_id UUID,
    p_new_stage TEXT,
    p_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_success BOOLEAN := FALSE;
BEGIN
    UPDATE public.roster_matches
    SET 
        pipeline_stage = p_new_stage,
        stage = p_new_stage,
        last_interaction = NOW(),
        updated_at = NOW()
    WHERE id = p_match_id AND user_id = p_user_id;
    
    v_success := FOUND;
    RETURN v_success;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get games by consent level (includes lower levels)
CREATE OR REPLACE FUNCTION get_games_by_consent(
    p_consent_level TEXT
) RETURNS SETOF public.ludus_games AS $$
BEGIN
    IF p_consent_level = 'red' THEN
        -- Red includes all games
        RETURN QUERY SELECT * FROM public.ludus_games 
            WHERE is_active = true ORDER BY play_count DESC;
    ELSIF p_consent_level = 'yellow' THEN
        -- Yellow includes green and yellow
        RETURN QUERY SELECT * FROM public.ludus_games 
            WHERE is_active = true AND rating_level IN ('green', 'yellow')
            ORDER BY play_count DESC;
    ELSE
        -- Green only includes green
        RETURN QUERY SELECT * FROM public.ludus_games 
            WHERE is_active = true AND rating_level = 'green'
            ORDER BY play_count DESC;
    END IF;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function: Toggle Tonight Mode with location update
CREATE OR REPLACE FUNCTION toggle_tonight_mode(
    p_user_id UUID,
    p_enabled BOOLEAN,
    p_lat FLOAT DEFAULT NULL,
    p_lng FLOAT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
    IF p_enabled AND p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
        UPDATE public.profiles
        SET 
            current_status = 'tonight_mode',
            location = ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
            location_updated_at = NOW(),
            is_visible = true,
            last_active_at = NOW()
        WHERE id = p_user_id;
    ELSE
        UPDATE public.profiles
        SET 
            current_status = 'active',
            is_visible = true,
            last_active_at = NOW()
        WHERE id = p_user_id;
    END IF;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Calculate ghost rate for a user
CREATE OR REPLACE FUNCTION calculate_ghost_rate(p_user_id UUID)
RETURNS FLOAT AS $$
DECLARE
    total_matches INT;
    archived_matches INT;
    ghost_rate FLOAT;
BEGIN
    SELECT COUNT(*) INTO total_matches
    FROM public.roster_matches
    WHERE user_id = p_user_id;
    
    SELECT COUNT(*) INTO archived_matches
    FROM public.roster_matches
    WHERE user_id = p_user_id 
    AND (is_archived = true OR pipeline_stage = 'archived');
    
    IF total_matches = 0 THEN
        ghost_rate := 0.0;
    ELSE
        ghost_rate := (archived_matches::FLOAT / total_matches::FLOAT) * 100;
    END IF;
    
    -- Update user profile
    UPDATE public.profiles SET ghost_rate = ghost_rate WHERE id = p_user_id;
    
    RETURN ghost_rate;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 10: SEED LUDUS GAMES
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO public.ludus_games (title, description, category, rating_level, min_players, max_players, content) VALUES

-- Green Level Games
('Icebreakers', 'Light conversation starters for new connections', 'icebreakers', 'green', 2, 10, 
 '{"cards": ["What''s your ideal first date?", "Describe your perfect weekend", "What''s something most people don''t know about you?", "If you could travel anywhere tomorrow, where?", "What''s your love language?"]}'),

('Two Truths & A Lie', 'Classic party game with a flirty twist', 'party', 'green', 3, 10,
 '{"instructions": "Each player shares two truths and one lie. Others guess the lie."}'),

('Would You Rather', 'Playful hypotheticals that reveal preferences', 'party', 'green', 2, 20,
 '{"cards": ["Would you rather have a spontaneous partner or a planner?", "Would you rather text all day or have one long call?", "Would you rather have butterflies or comfort?"]}'),

-- Yellow Level Games  
('Pleasure Deck - Flirty', 'Truth or Dare cards for sensual exploration', 'pleasure_deck', 'yellow', 2, 6,
 '{"cards": [{"type": "truth", "prompt": "What''s your biggest turn-on?"}, {"type": "dare", "prompt": "Give a 30-second shoulder massage"}, {"type": "truth", "prompt": "Describe your ideal kiss"}, {"type": "dare", "prompt": "Whisper something seductive"}]}'),

('Path of Pleasure', 'Comparative ranking of desires', 'path_of_pleasure', 'yellow', 2, 4,
 '{"rounds": 5, "categories": ["touch", "conversation", "adventure", "intimacy"]}'),

('Sensory Dice', 'Roll for body parts and actions', 'sensory', 'yellow', 2, 2,
 '{"body_parts": ["neck", "hand", "back", "ear", "lips"], "actions": ["kiss", "massage", "whisper to", "caress", "breathe on"]}'),

-- Red Level Games
('Pleasure Deck - Explicit', 'Adult Truth or Dare for consenting partners', 'pleasure_deck', 'red', 2, 4,
 '{"cards": [{"type": "dare", "prompt": "Remove one article of clothing"}, {"type": "truth", "prompt": "Describe your wildest fantasy"}, {"type": "dare", "prompt": "Demonstrate your favorite technique"}]}'),

('The Other Room', 'Secret acts for the group to guess', 'other_room', 'red', 4, 10,
 '{"instructions": "Two players leave. Perform a secret intimate act. Return and others guess what happened.", "time_limit": 300}'),

('Kama Sutra Cards', 'Position exploration for intimate partners', 'kama_sutra', 'red', 2, 2,
 '{"positions": ["lotus", "cowgirl", "spooning", "standing", "missionary variations"], "difficulty": ["beginner", "intermediate", "advanced"]}')

ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 11: TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Trigger: Update ghost rate when match is archived
CREATE OR REPLACE FUNCTION on_match_archived()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_archived = true AND OLD.is_archived = false THEN
        PERFORM calculate_ghost_rate(NEW.user_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS match_archived_trigger ON public.roster_matches;
CREATE TRIGGER match_archived_trigger
    AFTER UPDATE OF is_archived ON public.roster_matches
    FOR EACH ROW
    EXECUTE FUNCTION on_match_archived();

-- Trigger: Update last_active_at on profile changes
CREATE OR REPLACE FUNCTION on_profile_activity()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_active_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profile_activity_trigger ON public.profiles;
CREATE TRIGGER profile_activity_trigger
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION on_profile_activity();
