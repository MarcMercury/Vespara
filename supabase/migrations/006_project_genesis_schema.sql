-- ═══════════════════════════════════════════════════════════════════════════
-- KULT MIGRATION 006: Schema Updates for Project Genesis Seeding
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- This migration adds columns required for the comprehensive seeding script
-- Tables that already exist are skipped gracefully
--
-- Run: supabase db push
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- ADD MISSING COLUMNS TO PROFILES
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'first_name') THEN
        ALTER TABLE public.profiles ADD COLUMN first_name TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'last_name') THEN
        ALTER TABLE public.profiles ADD COLUMN last_name TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'age') THEN
        ALTER TABLE public.profiles ADD COLUMN age INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'photos') THEN
        ALTER TABLE public.profiles ADD COLUMN photos TEXT[] DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'vibe_tags') THEN
        ALTER TABLE public.profiles ADD COLUMN vibe_tags TEXT[] DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'bandwidth') THEN
        ALTER TABLE public.profiles ADD COLUMN bandwidth INTEGER DEFAULT 50;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'vouch_score') THEN
        ALTER TABLE public.profiles ADD COLUMN vouch_score INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'latitude') THEN
        ALTER TABLE public.profiles ADD COLUMN latitude DOUBLE PRECISION;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'longitude') THEN
        ALTER TABLE public.profiles ADD COLUMN longitude DOUBLE PRECISION;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'current_status') THEN
        ALTER TABLE public.profiles ADD COLUMN current_status TEXT DEFAULT 'active';
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- ADD MISSING COLUMN TO ROSTER_MATCHES
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'roster_matches' AND column_name = 'match_user_id') THEN
        ALTER TABLE public.roster_matches ADD COLUMN match_user_id UUID;
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- ADD COLUMNS TO MESSAGES TABLE (if they don't exist)
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
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
-- CREATE LUDUS_CARDS TABLE (if not exists)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.ludus_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES public.ludus_games(id) ON DELETE CASCADE,
    consent_level TEXT NOT NULL CHECK (consent_level IN ('green', 'yellow', 'red')),
    card_type TEXT NOT NULL,
    content TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ludus_cards_game ON public.ludus_cards(game_id);
CREATE INDEX IF NOT EXISTS idx_ludus_cards_level ON public.ludus_cards(consent_level);

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENTS TABLE already exists - just add indexes
-- ═══════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_events_host_id ON public.events(host_id);
CREATE INDEX IF NOT EXISTS idx_events_event_date ON public.events(event_date);

-- ═══════════════════════════════════════════════════════════════════════════
-- CREATE EVENT_ATTENDEES TABLE (if not exists)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.event_attendees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_event_attendees_event ON public.event_attendees(event_id);
CREATE INDEX IF NOT EXISTS idx_event_attendees_user ON public.event_attendees(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- USER_ANALYTICS - ensure index exists
-- ═══════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_user_analytics_user ON public.user_analytics(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- DISABLE RLS FOR SEEDING
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roster_matches DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.events DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ludus_games DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ludus_cards DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_analytics DISABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'event_attendees') THEN
        ALTER TABLE public.event_attendees DISABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- DONE
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
    RAISE NOTICE 'Migration 006 complete!';
END $$;
