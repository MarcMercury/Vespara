-- ============================================
-- VESPARA DATING APP - FULL SCHEMA OVERHAUL
-- Migration 007: Transform into real dating platform
-- ============================================

-- ============================================
-- 1. ENHANCED PROFILES - For Discovery
-- ============================================

-- Add dating-specific fields to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS 
    headline TEXT,
    height_cm INTEGER,
    body_type TEXT,
    education TEXT,
    occupation TEXT,
    company TEXT,
    drinking TEXT, -- 'never', 'socially', 'regularly'
    smoking TEXT,  -- 'never', 'socially', 'regularly'
    cannabis TEXT, -- 'never', 'socially', 'regularly'
    relationship_type TEXT[], -- 'monogamy', 'ethicalNonMonogamy', 'polyamory', 'casual', 'exploring'
    kinks TEXT[], -- User-defined kink list
    boundaries TEXT[], -- Hard nos
    love_languages TEXT[], -- 'words', 'touch', 'gifts', 'acts', 'time'
    communication_style TEXT, -- 'texter', 'caller', 'inPerson'
    photos TEXT[], -- Array of photo URLs
    prompts JSONB DEFAULT '[]'::jsonb, -- Dating prompts and answers
    is_discoverable BOOLEAN DEFAULT TRUE,
    discovery_last_active TIMESTAMPTZ DEFAULT NOW(),
    profile_completeness INTEGER DEFAULT 0, -- 0-100
    -- Search preferences
    pref_age_min INTEGER DEFAULT 18,
    pref_age_max INTEGER DEFAULT 99,
    pref_distance_km INTEGER DEFAULT 50,
    pref_genders TEXT[] DEFAULT ARRAY['any']::TEXT[],
    pref_relationship_types TEXT[] DEFAULT ARRAY['any']::TEXT[],
    pref_body_types TEXT[] DEFAULT ARRAY['any']::TEXT[];

-- Index for discovery queries
CREATE INDEX IF NOT EXISTS idx_profiles_discoverable 
    ON public.profiles(is_discoverable, discovery_last_active DESC) 
    WHERE is_discoverable = TRUE;

CREATE INDEX IF NOT EXISTS idx_profiles_location 
    ON public.profiles(location_lat, location_lng) 
    WHERE location_lat IS NOT NULL;

-- ============================================
-- 2. DISCOVERY CARDS - Swipe Queue
-- ============================================

CREATE TABLE IF NOT EXISTS public.discovery_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    viewer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    compatibility_score DOUBLE PRECISION DEFAULT 0.5, -- AI-calculated
    is_strict_match BOOLEAN DEFAULT TRUE, -- Matches preferences exactly
    is_wildcard BOOLEAN DEFAULT FALSE, -- AI suggested outside preferences
    wildcard_reason TEXT, -- Why AI thinks they might work
    is_viewed BOOLEAN DEFAULT FALSE,
    viewed_at TIMESTAMPTZ,
    is_swiped BOOLEAN DEFAULT FALSE,
    swipe_direction TEXT, -- 'left', 'right', 'super'
    swiped_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(viewer_id, profile_id)
);

ALTER TABLE public.discovery_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own discovery cards" ON public.discovery_cards
    FOR SELECT USING (auth.uid() = viewer_id);

CREATE POLICY "Users can update own discovery cards" ON public.discovery_cards
    FOR UPDATE USING (auth.uid() = viewer_id);

CREATE INDEX idx_discovery_pending ON public.discovery_cards(viewer_id, is_swiped, expires_at) 
    WHERE is_swiped = FALSE;

-- ============================================
-- 3. SWIPES & MATCHES
-- ============================================

CREATE TABLE IF NOT EXISTS public.swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    swiped_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    direction TEXT NOT NULL, -- 'left', 'right', 'super'
    is_from_strict BOOLEAN DEFAULT TRUE,
    is_from_wildcard BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(swiper_id, swiped_id)
);

ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own swipes" ON public.swipes
    FOR ALL USING (auth.uid() = swiper_id);

CREATE INDEX idx_swipes_matching ON public.swipes(swiped_id, direction) 
    WHERE direction IN ('right', 'super');

-- Matches table - created when both swipe right
CREATE TABLE IF NOT EXISTS public.matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    matched_at TIMESTAMPTZ DEFAULT NOW(),
    compatibility_score DOUBLE PRECISION DEFAULT 0.5,
    is_super_match BOOLEAN DEFAULT FALSE, -- At least one super liked
    first_message_by UUID, -- Who messaged first
    first_message_at TIMESTAMPTZ,
    conversation_id UUID, -- Link to conversation when created
    -- Nest (Roster) fields
    user_a_priority TEXT DEFAULT 'new', -- 'priority', 'inWaiting', 'onWayOut', 'legacy'
    user_b_priority TEXT DEFAULT 'new',
    user_a_notes TEXT,
    user_b_notes TEXT,
    user_a_archived BOOLEAN DEFAULT FALSE,
    user_b_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_a_id, user_b_id)
);

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own matches" ON public.matches
    FOR SELECT USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

CREATE POLICY "Users can update own match settings" ON public.matches
    FOR UPDATE USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

-- ============================================
-- 4. ENHANCED CONVERSATIONS (The Wire)
-- ============================================

-- Update conversations to link to matches
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS 
    match_link_id UUID REFERENCES public.matches(id),
    typing_indicator UUID, -- Who is currently typing
    typing_started_at TIMESTAMPTZ;

-- Enhanced messages for modern chat
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS
    message_type TEXT DEFAULT 'text', -- 'text', 'image', 'voice', 'gif', 'reaction', 'system'
    media_url TEXT,
    media_thumbnail_url TEXT,
    media_duration_seconds INTEGER, -- For voice notes
    reply_to_id UUID REFERENCES public.messages(id),
    reactions JSONB DEFAULT '[]'::jsonb, -- [{emoji: '❤️', user_id: 'xxx'}]
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ;

-- ============================================
-- 5. THE PLANNER - Calendar Integration
-- ============================================

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_id UUID REFERENCES public.matches(id) ON DELETE SET NULL,
    -- Event details
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    is_all_day BOOLEAN DEFAULT FALSE,
    -- Calendar sync
    external_calendar_id TEXT, -- Google/iCal event ID
    external_calendar_source TEXT, -- 'google', 'apple', 'manual'
    -- AI features
    ai_conflict_detected BOOLEAN DEFAULT FALSE,
    ai_conflict_reason TEXT, -- "You mentioned hiking with Sarah on this day"
    ai_suggestions JSONB, -- Date ideas based on shared interests
    -- Status
    status TEXT DEFAULT 'tentative', -- 'tentative', 'confirmed', 'cancelled'
    reminder_minutes INTEGER[] DEFAULT ARRAY[60, 1440]::INTEGER[], -- 1hr and 1day before
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own events" ON public.calendar_events
    FOR ALL USING (auth.uid() = user_id);

CREATE INDEX idx_calendar_events_time ON public.calendar_events(user_id, start_time);

-- Store analyzed conversation topics for conflict detection
CREATE TABLE IF NOT EXISTS public.conversation_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    topic TEXT NOT NULL, -- 'restaurant:Italian Place', 'activity:hiking', 'date:Saturday'
    mentioned_at TIMESTAMPTZ NOT NULL,
    mentioned_date DATE, -- If a specific date was mentioned
    context TEXT, -- The message snippet
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_conversation_topics_date ON public.conversation_topics(mentioned_date) 
    WHERE mentioned_date IS NOT NULL;

-- ============================================
-- 6. GROUP STUFF - Events & Parties
-- ============================================

CREATE TABLE IF NOT EXISTS public.group_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Event details
    title TEXT NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    event_type TEXT DEFAULT 'social', -- 'social', 'party', 'game_night', 'adventure', 'intimate'
    -- Location
    venue_name TEXT,
    venue_address TEXT,
    venue_lat DOUBLE PRECISION,
    venue_lng DOUBLE PRECISION,
    is_virtual BOOLEAN DEFAULT FALSE,
    virtual_link TEXT,
    -- Timing
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    -- Capacity
    max_attendees INTEGER,
    current_attendees INTEGER DEFAULT 0,
    -- Privacy
    is_private BOOLEAN DEFAULT TRUE, -- Invite only
    invite_code TEXT UNIQUE, -- For sharing
    requires_approval BOOLEAN DEFAULT FALSE,
    -- Age/Content rating
    age_restriction INTEGER DEFAULT 18,
    content_rating TEXT DEFAULT 'social', -- 'social', 'flirty', 'intimate', 'explicit'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.group_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view events they're invited to or hosting" ON public.group_events
    FOR SELECT USING (
        auth.uid() = host_id OR 
        EXISTS (SELECT 1 FROM public.event_invites WHERE event_id = id AND user_id = auth.uid())
    );

CREATE POLICY "Users can manage own events" ON public.group_events
    FOR ALL USING (auth.uid() = host_id);

-- Event invitations
CREATE TABLE IF NOT EXISTS public.event_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES public.group_events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    invited_by UUID NOT NULL REFERENCES public.profiles(id),
    status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'maybe'
    response_message TEXT,
    added_to_calendar BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    UNIQUE(event_id, user_id)
);

ALTER TABLE public.event_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own invites" ON public.event_invites
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = invited_by);

CREATE POLICY "Users can respond to own invites" ON public.event_invites
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Hosts can manage invites" ON public.event_invites
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.group_events WHERE id = event_id AND host_id = auth.uid())
    );

-- ============================================
-- 7. SHREDDER - AI Move-On Recommendations
-- ============================================

-- Add AI analysis fields to shredder
ALTER TABLE public.shredder_archive ADD COLUMN IF NOT EXISTS
    match_id UUID REFERENCES public.matches(id),
    ai_recommendation BOOLEAN DEFAULT FALSE, -- Was this AI recommended
    ai_reasoning TEXT, -- Why AI thinks you should move on
    ai_confidence DOUBLE PRECISION, -- 0-1 confidence score
    days_since_contact INTEGER,
    message_sentiment_avg DOUBLE PRECISION, -- Overall sentiment analysis
    reciprocation_ratio DOUBLE PRECISION, -- How balanced the conversation was
    shred_method TEXT DEFAULT 'archive'; -- 'archive', 'block', 'ghost_protocol'

-- AI shred suggestions (pre-shredder queue)
CREATE TABLE IF NOT EXISTS public.shred_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    reason_code TEXT NOT NULL, -- 'no_response', 'low_effort', 'incompatible', 'ghosted'
    reason_detail TEXT,
    confidence_score DOUBLE PRECISION NOT NULL,
    days_inactive INTEGER,
    suggestion_action TEXT DEFAULT 'archive', -- 'archive', 'send_hail_mary', 'ghost_protocol'
    is_dismissed BOOLEAN DEFAULT FALSE,
    is_actioned BOOLEAN DEFAULT FALSE,
    actioned_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.shred_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own suggestions" ON public.shred_suggestions
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 8. TAG (Trusted Adult Games) - Directory
-- ============================================

-- Game categories and types
CREATE TABLE IF NOT EXISTS public.tag_game_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT, -- Icon name or emoji
    sort_order INTEGER DEFAULT 0,
    min_consent_level consent_level DEFAULT 'green'
);

-- Insert base categories
INSERT INTO public.tag_game_categories (name, description, icon, sort_order, min_consent_level) VALUES
    ('Icebreakers', 'Perfect for first dates and new connections', '🎯', 1, 'green'),
    ('Get to Know', 'Deeper questions to build connection', '💭', 2, 'green'),
    ('Flirty Fun', 'Playful games to turn up the heat', '🔥', 3, 'yellow'),
    ('Truth or Dare', 'Classic with an adult twist', '🎲', 4, 'yellow'),
    ('Couples Games', 'For established connections', '💕', 5, 'yellow'),
    ('Group Games', 'Party games for multiple players', '🎉', 6, 'yellow'),
    ('Intimacy Builders', 'For those ready to go deeper', '🌙', 7, 'red'),
    ('Fantasy Exploration', 'Explore desires together', '✨', 8, 'red')
ON CONFLICT (name) DO NOTHING;

-- Enhanced games table
ALTER TABLE public.tags_games ADD COLUMN IF NOT EXISTS
    category_id UUID REFERENCES public.tag_game_categories(id),
    min_players INTEGER DEFAULT 2,
    max_players INTEGER DEFAULT 2,
    estimated_duration_minutes INTEGER DEFAULT 15,
    player_mode TEXT DEFAULT 'shared', -- 'shared' (1 phone), 'individual' (everyone on their own phone)
    requires_account BOOLEAN DEFAULT FALSE,
    thumbnail_url TEXT,
    featured BOOLEAN DEFAULT FALSE,
    rating_avg DOUBLE PRECISION DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    times_played INTEGER DEFAULT 0;

-- Game ratings/reviews
CREATE TABLE IF NOT EXISTS public.game_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    game_id UUID NOT NULL REFERENCES public.tags_games(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    review TEXT,
    played_with_count INTEGER, -- How many people
    would_play_again BOOLEAN,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, game_id)
);

-- ============================================
-- 9. AI CONTEXT - The Glue
-- ============================================

-- Store AI-analyzed relationship context
CREATE TABLE IF NOT EXISTS public.relationship_context (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    -- Analyzed data
    shared_interests TEXT[],
    conversation_topics TEXT[],
    communication_patterns JSONB, -- {avg_response_time, message_length_ratio, emoji_usage}
    sentiment_over_time JSONB, -- [{date, sentiment_score}]
    compatibility_factors JSONB, -- What makes them compatible
    warning_signs JSONB, -- Red flags detected
    suggested_date_ideas TEXT[],
    suggested_topics TEXT[],
    last_analyzed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, match_id)
);

ALTER TABLE public.relationship_context ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own context" ON public.relationship_context
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================
-- 10. ANALYTICS ENHANCEMENTS (Mirror)
-- ============================================

ALTER TABLE public.user_analytics ADD COLUMN IF NOT EXISTS
    -- Discovery analytics
    profiles_viewed INTEGER DEFAULT 0,
    swipes_left INTEGER DEFAULT 0,
    swipes_right INTEGER DEFAULT 0,
    swipes_super INTEGER DEFAULT 0,
    match_rate DOUBLE PRECISION DEFAULT 0, -- % of right swipes that match
    -- Quality metrics (brutal honesty)
    avg_match_quality DOUBLE PRECISION DEFAULT 0, -- Based on their engagement
    avg_conversation_depth DOUBLE PRECISION DEFAULT 0, -- How deep do convos get
    first_message_quality_score DOUBLE PRECISION DEFAULT 0,
    -- Behavioral insights
    most_active_time TEXT,
    avg_response_time_minutes INTEGER,
    conversation_starter_rate DOUBLE PRECISION DEFAULT 0, -- % of convos you start
    date_conversion_rate DOUBLE PRECISION DEFAULT 0, -- % of matches that become dates
    -- AI insights
    ai_personality_summary TEXT,
    ai_dating_style TEXT,
    ai_improvement_tips TEXT[];

-- ============================================
-- FUNCTIONS: Match Creation
-- ============================================

CREATE OR REPLACE FUNCTION check_for_match()
RETURNS TRIGGER AS $$
DECLARE
    mutual_swipe RECORD;
    new_match_id UUID;
BEGIN
    -- Only check on right/super swipes
    IF NEW.direction NOT IN ('right', 'super') THEN
        RETURN NEW;
    END IF;
    
    -- Check if the other person already swiped right on us
    SELECT * INTO mutual_swipe FROM public.swipes 
    WHERE swiper_id = NEW.swiped_id 
    AND swiped_id = NEW.swiper_id 
    AND direction IN ('right', 'super');
    
    IF FOUND THEN
        -- Create a match!
        INSERT INTO public.matches (
            user_a_id, 
            user_b_id, 
            is_super_match,
            compatibility_score
        ) VALUES (
            LEAST(NEW.swiper_id, NEW.swiped_id),
            GREATEST(NEW.swiper_id, NEW.swiped_id),
            (NEW.direction = 'super' OR mutual_swipe.direction = 'super'),
            0.75 -- Default, will be calculated by AI
        )
        ON CONFLICT (user_a_id, user_b_id) DO NOTHING
        RETURNING id INTO new_match_id;
        
        -- Create conversation for the match
        IF new_match_id IS NOT NULL THEN
            INSERT INTO public.conversations (user_id, match_id, match_link_id)
            VALUES (NEW.swiper_id, NULL, new_match_id);
            
            INSERT INTO public.conversations (user_id, match_id, match_link_id)
            VALUES (NEW.swiped_id, NULL, new_match_id);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS check_match_on_swipe ON public.swipes;
CREATE TRIGGER check_match_on_swipe
    AFTER INSERT ON public.swipes
    FOR EACH ROW EXECUTE FUNCTION check_for_match();

-- ============================================
-- FUNCTION: Generate Discovery Cards
-- ============================================

CREATE OR REPLACE FUNCTION generate_discovery_cards(target_user_id UUID, card_count INTEGER DEFAULT 20)
RETURNS INTEGER AS $$
DECLARE
    cards_created INTEGER := 0;
    target_profile RECORD;
    candidate RECORD;
BEGIN
    -- Get target user's preferences
    SELECT * INTO target_profile FROM public.profiles WHERE id = target_user_id;
    
    -- Generate strict match cards
    FOR candidate IN 
        SELECT p.*, 
            -- Simple compatibility calculation
            CASE 
                WHEN p.relationship_type && target_profile.pref_relationship_types THEN 0.2
                ELSE 0
            END +
            CASE
                WHEN p.gender = ANY(target_profile.pref_genders) OR 'any' = ANY(target_profile.pref_genders) THEN 0.3
                ELSE 0
            END AS base_score
        FROM public.profiles p
        WHERE p.id != target_user_id
        AND p.is_discoverable = TRUE
        AND p.id NOT IN (SELECT swiped_id FROM public.swipes WHERE swiper_id = target_user_id)
        AND p.id NOT IN (SELECT profile_id FROM public.discovery_cards WHERE viewer_id = target_user_id AND is_swiped = FALSE)
        AND p.id NOT IN (SELECT blocked_user_id FROM public.blocked_users WHERE user_id = target_user_id)
        ORDER BY p.discovery_last_active DESC
        LIMIT card_count
    LOOP
        INSERT INTO public.discovery_cards (
            viewer_id,
            profile_id,
            compatibility_score,
            is_strict_match,
            is_wildcard
        ) VALUES (
            target_user_id,
            candidate.id,
            candidate.base_score + random() * 0.5,
            TRUE,
            FALSE
        )
        ON CONFLICT (viewer_id, profile_id) DO NOTHING;
        
        cards_created := cards_created + 1;
    END LOOP;
    
    RETURN cards_created;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_matches_users ON public.matches(user_a_id, user_b_id);
CREATE INDEX IF NOT EXISTS idx_matches_priority_a ON public.matches(user_a_id, user_a_priority) WHERE NOT user_a_archived;
CREATE INDEX IF NOT EXISTS idx_matches_priority_b ON public.matches(user_b_id, user_b_priority) WHERE NOT user_b_archived;
CREATE INDEX IF NOT EXISTS idx_calendar_events_match ON public.calendar_events(match_id);
CREATE INDEX IF NOT EXISTS idx_group_events_upcoming ON public.group_events(start_time) WHERE start_time > NOW();

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
