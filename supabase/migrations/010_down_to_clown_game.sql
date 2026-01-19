-- ═══════════════════════════════════════════════════════════════════════════
-- DOWN TO CLOWN - Database Schema
-- TAG Game: Heads Up-style guessing game with sex-positive vocabulary
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- PROMPT DECKS TABLE
-- Stores all the prompts/cards for guessing games
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dtc_prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'naughty_list', -- deck category
    difficulty INTEGER NOT NULL DEFAULT 2 CHECK (difficulty BETWEEN 1 AND 5),
    -- 1 = vanilla/mainstream, 2 = flirty, 3 = suggestive, 4 = explicit, 5 = very explicit
    heat_level TEXT NOT NULL DEFAULT 'PG-13' CHECK (heat_level IN ('PG', 'PG-13', 'R', 'X', 'XXX')),
    tags TEXT[] DEFAULT '{}', -- searchable tags like 'kink', 'pop-culture', 'dating', etc.
    times_shown INTEGER DEFAULT 0,
    times_correct INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- ═══════════════════════════════════════════════════════════════════════════
-- GAME SESSIONS TABLE
-- Track individual game rounds for analytics and resumability
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dtc_game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    deck_category TEXT NOT NULL DEFAULT 'naughty_list',
    heat_filter TEXT DEFAULT 'all', -- 'all', 'mild', 'spicy', 'xxx'
    round_duration INTEGER DEFAULT 60, -- seconds
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    prompts_shown UUID[] DEFAULT '{}', -- order of prompts shown this session
    correct_prompts UUID[] DEFAULT '{}',
    passed_prompts UUID[] DEFAULT '{}',
    total_correct INTEGER DEFAULT 0,
    total_passed INTEGER DEFAULT 0,
    high_score_beat BOOLEAN DEFAULT false,
    device_type TEXT, -- 'mobile', 'tablet', 'desktop'
    used_motion_controls BOOLEAN DEFAULT true
);

-- ═══════════════════════════════════════════════════════════════════════════
-- USER STATS TABLE
-- Aggregate stats per user for leaderboards and progression
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dtc_user_stats (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    total_games_played INTEGER DEFAULT 0,
    total_correct INTEGER DEFAULT 0,
    total_passed INTEGER DEFAULT 0,
    high_score INTEGER DEFAULT 0,
    average_score DECIMAL(5,2) DEFAULT 0,
    favorite_deck TEXT DEFAULT 'naughty_list',
    last_played_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    streak_days INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0
);

-- ═══════════════════════════════════════════════════════════════════════════
-- SHUFFLED DECK CACHE TABLE
-- Pre-shuffled decks per user session for consistency
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dtc_shuffled_decks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES dtc_game_sessions(id) ON DELETE CASCADE,
    deck_category TEXT NOT NULL,
    shuffled_prompt_ids UUID[] NOT NULL,
    current_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours'
);

-- ═══════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_dtc_prompts_category ON dtc_prompts(category);
CREATE INDEX IF NOT EXISTS idx_dtc_prompts_heat ON dtc_prompts(heat_level);
CREATE INDEX IF NOT EXISTS idx_dtc_prompts_active ON dtc_prompts(is_active);
CREATE INDEX IF NOT EXISTS idx_dtc_sessions_user ON dtc_game_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_dtc_sessions_date ON dtc_game_sessions(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_dtc_shuffled_user ON dtc_shuffled_decks(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE dtc_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE dtc_game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE dtc_user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE dtc_shuffled_decks ENABLE ROW LEVEL SECURITY;

-- Prompts are readable by all authenticated users
CREATE POLICY "Prompts are viewable by authenticated users"
    ON dtc_prompts FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Sessions belong to the user who created them
CREATE POLICY "Users can manage their own game sessions"
    ON dtc_game_sessions FOR ALL
    TO authenticated
    USING (auth.uid() = user_id);

-- Stats belong to the user
CREATE POLICY "Users can manage their own stats"
    ON dtc_user_stats FOR ALL
    TO authenticated
    USING (auth.uid() = user_id);

-- Shuffled decks belong to the user
CREATE POLICY "Users can manage their own shuffled decks"
    ON dtc_shuffled_decks FOR ALL
    TO authenticated
    USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Function to get a freshly shuffled deck for a user
CREATE OR REPLACE FUNCTION get_shuffled_deck(
    p_category TEXT DEFAULT 'naughty_list',
    p_heat_filter TEXT DEFAULT 'all'
)
RETURNS UUID[] AS $$
DECLARE
    shuffled_ids UUID[];
BEGIN
    -- Get all active prompts matching criteria, randomly ordered
    SELECT ARRAY_AGG(id ORDER BY random())
    INTO shuffled_ids
    FROM dtc_prompts
    WHERE category = p_category
      AND is_active = true
      AND (
          p_heat_filter = 'all'
          OR (p_heat_filter = 'mild' AND heat_level IN ('PG', 'PG-13'))
          OR (p_heat_filter = 'spicy' AND heat_level IN ('R', 'X'))
          OR (p_heat_filter = 'xxx' AND heat_level = 'XXX')
      );
    
    RETURN shuffled_ids;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update prompt stats after a game
CREATE OR REPLACE FUNCTION update_prompt_stats(
    p_prompt_id UUID,
    p_was_correct BOOLEAN
)
RETURNS void AS $$
BEGIN
    UPDATE dtc_prompts
    SET 
        times_shown = times_shown + 1,
        times_correct = times_correct + CASE WHEN p_was_correct THEN 1 ELSE 0 END
    WHERE id = p_prompt_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user stats after a game
CREATE OR REPLACE FUNCTION update_user_game_stats(
    p_user_id UUID,
    p_correct INTEGER,
    p_passed INTEGER
)
RETURNS void AS $$
DECLARE
    current_high INTEGER;
    new_total_games INTEGER;
    new_total_correct INTEGER;
BEGIN
    -- Get current high score
    SELECT high_score, total_games_played, total_correct
    INTO current_high, new_total_games, new_total_correct
    FROM dtc_user_stats
    WHERE user_id = p_user_id;
    
    -- Insert or update stats
    INSERT INTO dtc_user_stats (user_id, total_games_played, total_correct, total_passed, high_score, last_played_at)
    VALUES (p_user_id, 1, p_correct, p_passed, p_correct, NOW())
    ON CONFLICT (user_id) DO UPDATE SET
        total_games_played = dtc_user_stats.total_games_played + 1,
        total_correct = dtc_user_stats.total_correct + p_correct,
        total_passed = dtc_user_stats.total_passed + p_passed,
        high_score = GREATEST(dtc_user_stats.high_score, p_correct),
        average_score = (dtc_user_stats.total_correct + p_correct)::DECIMAL / (dtc_user_stats.total_games_played + 1),
        last_played_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- SEED DATA: THE NAUGHTY LIST (100 PROMPTS)
-- Categories: standard, pop-culture, explicit
-- ═══════════════════════════════════════════════════════════════════════════

-- STANDARD SEXUAL / DATING (PG-13 to R)
INSERT INTO dtc_prompts (prompt, category, difficulty, heat_level, tags) VALUES
-- Original 50
('Flirting with intent', 'naughty_list', 2, 'PG-13', ARRAY['dating', 'flirty']),
('Bedroom eyes', 'naughty_list', 1, 'PG-13', ARRAY['flirty', 'body-language']),
('Late-night "you up?" text', 'naughty_list', 2, 'PG-13', ARRAY['dating', 'texting']),
('Thirst trap', 'naughty_list', 2, 'PG-13', ARRAY['social-media', 'flirty']),
('Accidental moan', 'naughty_list', 3, 'R', ARRAY['awkward', 'sounds']),
('Situationship', 'naughty_list', 2, 'PG-13', ARRAY['dating', 'modern']),
('Friends with benefits', 'naughty_list', 2, 'PG-13', ARRAY['dating', 'arrangement']),
('Morning-after confidence', 'naughty_list', 3, 'R', ARRAY['hookup', 'vibes']),
('"I shouldn''t be into this"', 'naughty_list', 3, 'R', ARRAY['kink', 'discovery']),
('Sexual tension', 'naughty_list', 2, 'PG-13', ARRAY['chemistry', 'vibes']),
('Safe word', 'naughty_list', 3, 'R', ARRAY['kink', 'bdsm', 'consent']),
('Aftercare', 'naughty_list', 3, 'R', ARRAY['kink', 'bdsm', 'care']),
('Praise kink', 'naughty_list', 3, 'R', ARRAY['kink', 'psychology']),
('Power bottom', 'naughty_list', 3, 'R', ARRAY['kink', 'dynamics']),
('Brat energy', 'naughty_list', 2, 'PG-13', ARRAY['kink', 'attitude']),
('Switch vibes', 'naughty_list', 3, 'R', ARRAY['kink', 'dynamics']),
('Soft dom', 'naughty_list', 3, 'R', ARRAY['kink', 'bdsm']),
('Hard limit', 'naughty_list', 3, 'R', ARRAY['kink', 'bdsm', 'consent']),
('Consent check', 'naughty_list', 2, 'PG-13', ARRAY['consent', 'communication']),
('Negotiation kink', 'naughty_list', 3, 'R', ARRAY['kink', 'bdsm']),
('Rope bunny', 'naughty_list', 4, 'X', ARRAY['kink', 'bondage']),
('Impact play', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm']),
('Service top', 'naughty_list', 3, 'R', ARRAY['kink', 'dynamics']),
('Exhibitionist', 'naughty_list', 3, 'R', ARRAY['kink', 'public']),
('Voyeur', 'naughty_list', 3, 'R', ARRAY['kink', 'watching']),
('Pet play', 'naughty_list', 4, 'X', ARRAY['kink', 'roleplay']),
('Collar moment', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm']),
('Dungeon etiquette', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm', 'community']),
('Orgasm control', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm']),
('Edge play', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm']),
('CNC (consensual, not chaotic)', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm', 'consent']),
('Mommy issues (the fun kind)', 'naughty_list', 3, 'R', ARRAY['kink', 'dynamics']),
('Daddy energy', 'naughty_list', 3, 'R', ARRAY['kink', 'dynamics']),
('Protocol scene', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm']),
('Subspace', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm', 'psychology']),
('Top drop', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm', 'psychology']),
('Marks with meaning', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm']),
('Public but subtle', 'naughty_list', 3, 'R', ARRAY['kink', 'public']),
('Scene negotiation', 'naughty_list', 3, 'R', ARRAY['kink', 'bdsm', 'consent']),
('"Use me" energy', 'naughty_list', 4, 'X', ARRAY['kink', 'submission']),
('Kink math', 'naughty_list', 3, 'R', ARRAY['kink', 'funny']),
('Group chat consent', 'naughty_list', 3, 'R', ARRAY['poly', 'communication']),
('Poly calendar nightmare', 'naughty_list', 2, 'PG-13', ARRAY['poly', 'funny']),
('Compersion high', 'naughty_list', 3, 'R', ARRAY['poly', 'emotions']),
('Afterparty cuddle puddle', 'naughty_list', 3, 'R', ARRAY['group', 'intimacy']),
('Everyone''s watching (they aren''t)', 'naughty_list', 2, 'PG-13', ARRAY['anxiety', 'funny']),
('Sex-positive panic', 'naughty_list', 2, 'PG-13', ARRAY['funny', 'awkward']),
('Too many safeties', 'naughty_list', 2, 'PG-13', ARRAY['kink', 'funny']),
('Emotional aftercare spiral', 'naughty_list', 3, 'R', ARRAY['kink', 'emotions']),
('"That escalated consensually"', 'naughty_list', 3, 'R', ARRAY['consent', 'funny']),

-- NEW 50 PROMPTS: POP CULTURE SEXUAL
('Netflix and actually chill', 'naughty_list', 1, 'PG', ARRAY['pop-culture', 'dating']),
('Fifty Shades energy', 'naughty_list', 3, 'R', ARRAY['pop-culture', 'kink']),
('WAP confidence', 'naughty_list', 3, 'R', ARRAY['pop-culture', 'music']),
('Hot girl summer', 'naughty_list', 2, 'PG-13', ARRAY['pop-culture', 'vibes']),
('Bridgerton tension', 'naughty_list', 2, 'PG-13', ARRAY['pop-culture', 'tv']),
('Spicy BookTok', 'naughty_list', 2, 'PG-13', ARRAY['pop-culture', 'books']),
('Body count anxiety', 'naughty_list', 2, 'PG-13', ARRAY['dating', 'modern']),
('Dating app fatigue', 'naughty_list', 1, 'PG', ARRAY['dating', 'modern']),
('Ghosted after good sex', 'naughty_list', 3, 'R', ARRAY['dating', 'modern']),
('The talking stage', 'naughty_list', 1, 'PG', ARRAY['dating', 'modern']),
('Sending nudes responsibly', 'naughty_list', 3, 'R', ARRAY['sexting', 'consent']),
('Dick pic energy (unwanted)', 'naughty_list', 3, 'R', ARRAY['sexting', 'cringe']),
('Read receipts anxiety', 'naughty_list', 1, 'PG', ARRAY['texting', 'dating']),
('Rizz master', 'naughty_list', 2, 'PG-13', ARRAY['slang', 'flirty']),
('No cap, just vibes', 'naughty_list', 1, 'PG', ARRAY['slang', 'modern']),
('Main character syndrome', 'naughty_list', 1, 'PG', ARRAY['psychology', 'funny']),
('Toxic trait bragging', 'naughty_list', 2, 'PG-13', ARRAY['dating', 'funny']),
('Love bombing', 'naughty_list', 2, 'PG-13', ARRAY['dating', 'red-flags']),
('Breadcrumbing', 'naughty_list', 2, 'PG-13', ARRAY['dating', 'manipulation']),
('Benching', 'naughty_list', 2, 'PG-13', ARRAY['dating', 'manipulation']),

-- EXPLICIT KINK VOCABULARY
('Shibari suspension', 'naughty_list', 5, 'XXX', ARRAY['kink', 'bondage', 'advanced']),
('Fire play', 'naughty_list', 5, 'XXX', ARRAY['kink', 'edge-play']),
('Wax dripping', 'naughty_list', 4, 'X', ARRAY['kink', 'sensation']),
('Sensory deprivation', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm']),
('Electrostim', 'naughty_list', 5, 'XXX', ARRAY['kink', 'sensation']),
('Double penetration', 'naughty_list', 5, 'XXX', ARRAY['explicit', 'act']),
('Pegging', 'naughty_list', 4, 'X', ARRAY['kink', 'act']),
('Cuckolding', 'naughty_list', 4, 'X', ARRAY['kink', 'dynamics']),
('Findom', 'naughty_list', 4, 'X', ARRAY['kink', 'financial']),
('Breeding kink', 'naughty_list', 5, 'XXX', ARRAY['kink', 'fantasy']),
('Humiliation play', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm']),
('Degradation kink', 'naughty_list', 5, 'XXX', ARRAY['kink', 'bdsm']),
('Free use fantasy', 'naughty_list', 5, 'XXX', ARRAY['kink', 'fantasy']),
('Predicament bondage', 'naughty_list', 5, 'XXX', ARRAY['kink', 'bondage']),
('Forced orgasm', 'naughty_list', 5, 'XXX', ARRAY['kink', 'bdsm']),
('Ruined orgasm', 'naughty_list', 4, 'X', ARRAY['kink', 'bdsm']),
('Multiple orgasms', 'naughty_list', 4, 'X', ARRAY['pleasure', 'goal']),
('Squirting', 'naughty_list', 4, 'X', ARRAY['pleasure', 'act']),
('Deep throat', 'naughty_list', 4, 'X', ARRAY['act', 'oral']),
('Face sitting', 'naughty_list', 4, 'X', ARRAY['act', 'position']),

-- RELATIONSHIP & INTIMACY
('Tantric breathing', 'naughty_list', 3, 'R', ARRAY['intimacy', 'spiritual']),
('Karezza practice', 'naughty_list', 3, 'R', ARRAY['intimacy', 'technique']),
('Edging together', 'naughty_list', 4, 'X', ARRAY['intimacy', 'technique']),
('Simultaneous orgasm', 'naughty_list', 4, 'X', ARRAY['intimacy', 'goal']),
('Morning wood appreciation', 'naughty_list', 3, 'R', ARRAY['intimacy', 'funny']),
('Quickie in public', 'naughty_list', 4, 'X', ARRAY['public', 'thrill']),
('Mile high club', 'naughty_list', 4, 'X', ARRAY['public', 'bucket-list']),
('Sex on the beach (not the drink)', 'naughty_list', 4, 'X', ARRAY['public', 'bucket-list']),
('Shower sex (overrated?)', 'naughty_list', 3, 'R', ARRAY['location', 'funny']),
('Car sex cramped but worth it', 'naughty_list', 3, 'R', ARRAY['location', 'funny']);

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_shuffled_deck TO authenticated;
GRANT EXECUTE ON FUNCTION update_prompt_stats TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_game_stats TO authenticated;
