-- ═══════════════════════════════════════════════════════════════════════════
-- VESPARA MIGRATION 006: Schema Updates for Project Genesis Seeding
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- This migration adds tables and columns required for the comprehensive
-- seeding script (PROJECT GENESIS)
--
-- Run: supabase db push
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- ADD MISSING COLUMNS TO PROFILES
-- ═══════════════════════════════════════════════════════════════════════════

-- Add first_name and last_name (for the "X" protocol)
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS first_name TEXT,
ADD COLUMN IF NOT EXISTS last_name TEXT,
ADD COLUMN IF NOT EXISTS age INTEGER,
ADD COLUMN IF NOT EXISTS photos TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS vibe_tags TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS bandwidth INTEGER DEFAULT 50 CHECK (bandwidth BETWEEN 0 AND 100),
ADD COLUMN IF NOT EXISTS vouch_score INTEGER DEFAULT 0 CHECK (vouch_score >= 0),
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS current_status TEXT DEFAULT 'active' CHECK (current_status IN ('active', 'tonight_mode', 'hidden'));

-- Update location columns to match seeding script
COMMENT ON COLUMN public.profiles.latitude IS 'User latitude for Tonight Mode proximity';
COMMENT ON COLUMN public.profiles.longitude IS 'User longitude for Tonight Mode proximity';
COMMENT ON COLUMN public.profiles.current_status IS 'active=visible, tonight_mode=beacon, hidden=invisible';

-- ═══════════════════════════════════════════════════════════════════════════
-- ADD MISSING COLUMN TO ROSTER_MATCHES
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.roster_matches
ADD COLUMN IF NOT EXISTS match_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE MESSAGES TABLE (Direct messaging, not conversation-based)
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop old constraint if exists to allow direct sender/receiver pattern
CREATE TABLE IF NOT EXISTS public.direct_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL,
    receiver_id UUID NOT NULL,
    content TEXT NOT NULL,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rename for compatibility if messages doesn't have sender_id
DO $$
BEGIN
    -- Add sender_id/receiver_id columns to messages if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sender_id') THEN
        ALTER TABLE public.messages ADD COLUMN sender_id UUID;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'receiver_id') THEN
        ALTER TABLE public.messages ADD COLUMN receiver_id UUID;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'read_at') THEN
        ALTER TABLE public.messages ADD COLUMN read_at TIMESTAMPTZ;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON public.messages(receiver_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE LUDUS_GAMES TABLE (For TAGS Engine)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.ludus_games (
    id TEXT PRIMARY KEY, -- e.g., 'pleasure_deck_v1'
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL, -- sensual, ranking, interactive, connection
    min_consent_level TEXT DEFAULT 'green' CHECK (min_consent_level IN ('green', 'yellow', 'red')),
    max_players INTEGER DEFAULT 2,
    estimated_duration INTEGER DEFAULT 30, -- minutes
    cover_image TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE LUDUS_CARDS TABLE (For game content)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.ludus_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id TEXT NOT NULL REFERENCES public.ludus_games(id) ON DELETE CASCADE,
    consent_level TEXT NOT NULL CHECK (consent_level IN ('green', 'yellow', 'red')),
    card_type TEXT NOT NULL, -- prompt, action, truth, dare, ranking
    content TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ludus_cards_game ON public.ludus_cards(game_id);
CREATE INDEX IF NOT EXISTS idx_ludus_cards_level ON public.ludus_cards(consent_level);

-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE EVENTS TABLE (For The Socialite)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_by UUID NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    location_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ,
    max_attendees INTEGER,
    is_private BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_created_by ON public.events(created_by);
CREATE INDEX IF NOT EXISTS idx_events_starts_at ON public.events(starts_at);

-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE EVENT_ATTENDEES TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.event_attendees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_event_attendees_event ON public.event_attendees(event_id);
CREATE INDEX IF NOT EXISTS idx_event_attendees_user ON public.event_attendees(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE USER_ANALYTICS TABLE (For The Mirror - Tile 8)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.user_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE,
    ghost_rate DOUBLE PRECISION DEFAULT 0.0,
    flake_rate DOUBLE PRECISION DEFAULT 0.0,
    swipe_ratio DOUBLE PRECISION DEFAULT 50.0,
    response_rate DOUBLE PRECISION DEFAULT 50.0,
    total_matches INTEGER DEFAULT 0,
    active_conversations INTEGER DEFAULT 0,
    dates_scheduled INTEGER DEFAULT 0,
    messages_sent INTEGER DEFAULT 0,
    messages_received INTEGER DEFAULT 0,
    first_messages_sent INTEGER DEFAULT 0,
    conversations_started INTEGER DEFAULT 0,
    weekly_activity DOUBLE PRECISION[] DEFAULT '{0,0,0,0,0,0,0}',
    peak_activity_time TEXT DEFAULT '8pm - 10pm',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_analytics_user ON public.user_analytics(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES FOR NEW TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Ludus Games (Public read, admin write)
ALTER TABLE public.ludus_games ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view active games" ON public.ludus_games
    FOR SELECT USING (is_active = true);

-- Ludus Cards (Public read)
ALTER TABLE public.ludus_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view cards" ON public.ludus_cards
    FOR SELECT USING (true);

-- Events (Creator can manage, others can view)
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view events" ON public.events
    FOR SELECT USING (true);
CREATE POLICY "Users can manage own events" ON public.events
    FOR ALL USING (auth.uid() = created_by);

-- Event Attendees
ALTER TABLE public.event_attendees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view event attendees" ON public.event_attendees
    FOR SELECT USING (true);
CREATE POLICY "Users can manage own attendance" ON public.event_attendees
    FOR ALL USING (auth.uid() = user_id);

-- User Analytics (Private to user)
ALTER TABLE public.user_analytics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own analytics" ON public.user_analytics
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own analytics" ON public.user_analytics
    FOR ALL USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- DISABLE RLS FOR SEEDING (Service role will bypass anyway)
-- ═══════════════════════════════════════════════════════════════════════════

-- For seeding with service role, RLS is bypassed.
-- These are just development conveniences:

ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roster_matches DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.events DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_attendees DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ludus_games DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ludus_cards DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_analytics DISABLE ROW LEVEL SECURITY;

-- Note: Re-enable RLS for production!
-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════════════════
-- VERIFICATION
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
    RAISE NOTICE 'Migration 006 complete!';
    RAISE NOTICE 'Tables ready for PROJECT GENESIS seeding:';
    RAISE NOTICE '  ✓ profiles (with first_name, last_name, vibe_tags, bandwidth, etc.)';
    RAISE NOTICE '  ✓ roster_matches (with match_user_id)';
    RAISE NOTICE '  ✓ messages (with sender_id, receiver_id)';
    RAISE NOTICE '  ✓ ludus_games (game definitions)';
    RAISE NOTICE '  ✓ ludus_cards (game content)';
    RAISE NOTICE '  ✓ events (for The Socialite)';
    RAISE NOTICE '  ✓ event_attendees (RSVPs)';
    RAISE NOTICE '  ✓ user_analytics (for The Mirror)';
END $$;
