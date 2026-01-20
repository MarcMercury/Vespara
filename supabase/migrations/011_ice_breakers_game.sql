-- ════════════════════════════════════════════════════════════════════════════
-- ICE BREAKERS - The Gateway Game to Vespara
-- "Kill awkward silence without jumping into heavy intimacy"
-- TAG Rating: 40mph / PG-13 / Quickie (15 min)
-- ════════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════
-- ICE BREAKER CARDS TABLE
-- ════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS ice_breaker_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt TEXT NOT NULL,
    card_type TEXT NOT NULL DEFAULT 'standard' CHECK (card_type IN ('standard', 'wild', 'timed', 'escalation')),
    timer_seconds INTEGER DEFAULT NULL, -- NULL = no timer, otherwise countdown seconds
    target_type TEXT NOT NULL DEFAULT 'single' CHECK (target_type IN ('single', 'pair', 'everyone')),
    category TEXT NOT NULL DEFAULT 'conversation' CHECK (category IN ('conversation', 'action', 'reveal', 'physical', 'creative')),
    intensity INTEGER NOT NULL DEFAULT 1 CHECK (intensity >= 1 AND intensity <= 5),
    is_active BOOLEAN NOT NULL DEFAULT true,
    play_count INTEGER NOT NULL DEFAULT 0,
    skip_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ════════════════════════════════════════════════════════════════════════════
-- ICE BREAKER SESSIONS TABLE
-- ════════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS ice_breaker_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    player_names TEXT[] NOT NULL DEFAULT '{}',
    game_mode TEXT NOT NULL DEFAULT 'group' CHECK (game_mode IN ('couple', 'group')),
    cards_played INTEGER NOT NULL DEFAULT 0,
    cards_skipped INTEGER NOT NULL DEFAULT 0,
    total_time_seconds INTEGER NOT NULL DEFAULT 0,
    completed_at TIMESTAMPTZ,
    escalated_to TEXT, -- 'truth_or_dare', 'down_to_clown', etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ════════════════════════════════════════════════════════════════════════════
-- INDEXES FOR PERFORMANCE
-- ════════════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_ice_breaker_cards_type ON ice_breaker_cards(card_type);
CREATE INDEX IF NOT EXISTS idx_ice_breaker_cards_active ON ice_breaker_cards(is_active);
CREATE INDEX IF NOT EXISTS idx_ice_breaker_sessions_host ON ice_breaker_sessions(host_user_id);
CREATE INDEX IF NOT EXISTS idx_ice_breaker_sessions_created ON ice_breaker_sessions(created_at DESC);

-- ════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ════════════════════════════════════════════════════════════════════════════
ALTER TABLE ice_breaker_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE ice_breaker_sessions ENABLE ROW LEVEL SECURITY;

-- Anyone can read active cards
CREATE POLICY "Anyone can read active ice breaker cards"
ON ice_breaker_cards FOR SELECT
USING (is_active = true);

-- Users can manage their own sessions
CREATE POLICY "Users can create ice breaker sessions"
ON ice_breaker_sessions FOR INSERT
WITH CHECK (auth.uid() = host_user_id OR host_user_id IS NULL);

CREATE POLICY "Users can read their own sessions"
ON ice_breaker_sessions FOR SELECT
USING (auth.uid() = host_user_id OR host_user_id IS NULL);

CREATE POLICY "Users can update their own sessions"
ON ice_breaker_sessions FOR UPDATE
USING (auth.uid() = host_user_id OR host_user_id IS NULL);

-- ════════════════════════════════════════════════════════════════════════════
-- FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

-- Get shuffled deck with wild cards spaced every 5 positions
CREATE OR REPLACE FUNCTION get_ice_breaker_deck(p_limit INTEGER DEFAULT 25)
RETURNS TABLE (
    id UUID,
    prompt TEXT,
    card_type TEXT,
    timer_seconds INTEGER,
    target_type TEXT,
    category TEXT,
    intensity INTEGER,
    deck_position INTEGER
) AS $$
DECLARE
    standard_cards UUID[];
    wild_cards UUID[];
    result_deck UUID[] := '{}';
    std_idx INTEGER := 1;
    wild_idx INTEGER := 1;
    pos INTEGER := 1;
BEGIN
    -- Get shuffled standard cards
    SELECT ARRAY_AGG(c.id ORDER BY RANDOM()) INTO standard_cards
    FROM ice_breaker_cards c
    WHERE c.is_active = true AND c.card_type IN ('standard', 'timed');
    
    -- Get shuffled wild cards
    SELECT ARRAY_AGG(c.id ORDER BY RANDOM()) INTO wild_cards
    FROM ice_breaker_cards c
    WHERE c.is_active = true AND c.card_type = 'wild';
    
    -- Build deck with wild cards every 5 positions
    WHILE array_length(result_deck, 1) IS NULL OR array_length(result_deck, 1) < p_limit LOOP
        IF pos % 5 = 0 AND wild_idx <= COALESCE(array_length(wild_cards, 1), 0) THEN
            result_deck := result_deck || wild_cards[wild_idx];
            wild_idx := wild_idx + 1;
        ELSIF std_idx <= COALESCE(array_length(standard_cards, 1), 0) THEN
            result_deck := result_deck || standard_cards[std_idx];
            std_idx := std_idx + 1;
        ELSE
            EXIT; -- No more cards
        END IF;
        pos := pos + 1;
    END LOOP;
    
    -- Return the deck with positions
    RETURN QUERY
    SELECT 
        c.id,
        c.prompt,
        c.card_type,
        c.timer_seconds,
        c.target_type,
        c.category,
        c.intensity,
        ordinality::INTEGER as deck_position
    FROM UNNEST(result_deck) WITH ORDINALITY AS u(card_id, ordinality)
    JOIN ice_breaker_cards c ON c.id = u.card_id;
END;
$$ LANGUAGE plpgsql;

-- Update card statistics
CREATE OR REPLACE FUNCTION update_ice_breaker_card_stats(
    p_card_id UUID,
    p_was_completed BOOLEAN
)
RETURNS VOID AS $$
BEGIN
    IF p_was_completed THEN
        UPDATE ice_breaker_cards
        SET play_count = play_count + 1,
            updated_at = NOW()
        WHERE id = p_card_id;
    ELSE
        UPDATE ice_breaker_cards
        SET skip_count = skip_count + 1,
            updated_at = NOW()
        WHERE id = p_card_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ════════════════════════════════════════════════════════════════════════════
-- SEED DATA: 50 ICE BREAKER PROMPTS (PG-13)
-- Categories: conversation, action, reveal, physical, creative
-- ════════════════════════════════════════════════════════════════════════════

INSERT INTO ice_breaker_cards (prompt, card_type, timer_seconds, target_type, category, intensity) VALUES

-- ═══════════════════════════════════════════════════════════════════════════
-- STANDARD CARDS - CONVERSATION (Getting to know you)
-- ═══════════════════════════════════════════════════════════════════════════
('What''s the most spontaneous thing you''ve ever done on a first date?', 'standard', NULL, 'single', 'conversation', 1),
('Describe your ideal Sunday morning with someone special.', 'standard', NULL, 'single', 'conversation', 1),
('What''s a secret talent you have that would surprise everyone here?', 'standard', NULL, 'single', 'reveal', 1),
('If you could have dinner with any celebrity, who would make the most interesting date?', 'standard', NULL, 'single', 'conversation', 1),
('What song would play if you had a personal entrance theme?', 'standard', NULL, 'single', 'conversation', 1),
('What''s the most embarrassing song on your playlist that you secretly love?', 'standard', NULL, 'single', 'reveal', 2),
('Describe your dating life using only a movie title.', 'standard', NULL, 'single', 'creative', 2),
('What''s a compliment you''ve received that you''ll never forget?', 'standard', NULL, 'single', 'reveal', 1),
('If you could wake up tomorrow with one new skill, what would it be?', 'standard', NULL, 'single', 'conversation', 1),
('What''s your go-to karaoke song?', 'standard', NULL, 'single', 'conversation', 1),

-- ═══════════════════════════════════════════════════════════════════════════
-- STANDARD CARDS - REVEAL (Slightly more personal)
-- ═══════════════════════════════════════════════════════════════════════════
('What''s a deal-breaker for you on a date that others might find petty?', 'standard', NULL, 'single', 'reveal', 2),
('What''s the bravest thing you''ve ever done in the name of love or attraction?', 'standard', NULL, 'single', 'reveal', 2),
('Describe your worst date ever—without naming names.', 'standard', NULL, 'single', 'reveal', 2),
('What''s a red flag that you''ve learned to spot immediately?', 'standard', NULL, 'single', 'reveal', 2),
('What''s your love language, and how do you like to receive it?', 'standard', NULL, 'single', 'reveal', 2),
('What''s the cheesiest pickup line that would actually work on you?', 'standard', NULL, 'single', 'reveal', 2),
('What fictional character do you have an embarrassing crush on?', 'standard', NULL, 'single', 'reveal', 2),
('What''s something you pretend to like on dates but secretly hate?', 'standard', NULL, 'single', 'reveal', 2),
('What''s the most romantic thing you''ve ever done for someone?', 'standard', NULL, 'single', 'reveal', 2),
('What''s a guilty pleasure you''d be embarrassed to admit on a first date?', 'standard', NULL, 'single', 'reveal', 2),

-- ═══════════════════════════════════════════════════════════════════════════
-- STANDARD CARDS - ACTION (Light interaction)
-- ═══════════════════════════════════════════════════════════════════════════
('Give a genuine compliment to the person on your left.', 'standard', NULL, 'single', 'action', 2),
('Show everyone your most recent selfie—no deleting allowed.', 'standard', NULL, 'single', 'action', 2),
('Let the group scroll through your Spotify (or music app) for 30 seconds.', 'timed', 30, 'single', 'action', 2),
('Do your best impression of someone in this room. We''ll guess who.', 'standard', NULL, 'single', 'action', 2),
('Show the last meme you sent to someone.', 'standard', NULL, 'single', 'action', 2),
('Demonstrate your signature dance move.', 'standard', NULL, 'single', 'physical', 2),
('Make eye contact with someone for 10 seconds without laughing.', 'timed', 10, 'pair', 'physical', 3),
('Give a 30-second pep talk to the person across from you.', 'timed', 30, 'pair', 'action', 2),
('Let the group see your last 3 Google searches.', 'standard', NULL, 'single', 'action', 3),
('Show us your best "flirty face" on command.', 'standard', NULL, 'single', 'physical', 2),

-- ═══════════════════════════════════════════════════════════════════════════
-- TIMED CARDS (Creates tension)
-- ═══════════════════════════════════════════════════════════════════════════
('You have 60 seconds to tell us your life story. Go!', 'timed', 60, 'single', 'creative', 2),
('In 30 seconds, give everyone here a unique nickname.', 'timed', 30, 'single', 'creative', 2),
('You have 20 seconds to make the person on your right laugh.', 'timed', 20, 'pair', 'action', 2),
('Describe your type in exactly 3 words. You have 10 seconds.', 'timed', 10, 'single', 'reveal', 2),
('Pass your phone to the person on your right. They have 30 seconds to find the most embarrassing photo in your gallery.', 'timed', 30, 'pair', 'action', 3),

-- ═══════════════════════════════════════════════════════════════════════════
-- WILD CARDS (Affects everyone)
-- ═══════════════════════════════════════════════════════════════════════════
('Everyone point to the person most likely to start a cult.', 'wild', NULL, 'everyone', 'action', 2),
('Everyone share the last lie they told.', 'wild', NULL, 'everyone', 'reveal', 2),
('Everyone make eye contact with someone. First to laugh drinks/does a dare.', 'wild', NULL, 'everyone', 'physical', 2),
('Everyone reveal their celebrity hall pass.', 'wild', NULL, 'everyone', 'reveal', 2),
('Everyone point to who here gives the best hugs.', 'wild', NULL, 'everyone', 'action', 1),
('Everyone share the weirdest thing in their fridge right now.', 'wild', NULL, 'everyone', 'reveal', 1),
('Everyone point to who they''d trust to plan their surprise party.', 'wild', NULL, 'everyone', 'action', 1),
('Everyone share their most-used emoji. Explain why.', 'wild', NULL, 'everyone', 'reveal', 1),
('Everyone point to who here is secretly the biggest flirt.', 'wild', NULL, 'everyone', 'action', 2),
('Everyone share one thing they''re grateful for today.', 'wild', NULL, 'everyone', 'reveal', 1),
('Everyone close your eyes and point to the best-dressed person here.', 'wild', NULL, 'everyone', 'action', 1),
('Everyone share the last time they ugly-cried.', 'wild', NULL, 'everyone', 'reveal', 2),

-- ═══════════════════════════════════════════════════════════════════════════
-- ESCALATION CARDS (End of game upsell)
-- ═══════════════════════════════════════════════════════════════════════════
('The ice is broken. Ready to turn up the heat? 🔥', 'escalation', NULL, 'everyone', 'action', 3);

-- ════════════════════════════════════════════════════════════════════════════
-- GRANT PERMISSIONS
-- ════════════════════════════════════════════════════════════════════════════
GRANT SELECT ON ice_breaker_cards TO authenticated, anon;
GRANT ALL ON ice_breaker_sessions TO authenticated;
GRANT EXECUTE ON FUNCTION get_ice_breaker_deck TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_ice_breaker_card_stats TO authenticated;
