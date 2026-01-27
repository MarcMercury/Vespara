-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 044: DICE BREAKERS GAME
-- "Roll the dice, let fate decide"
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- Game Overview:
-- - Two modes: JUST DICE (anonymous) and NAME PLAYERS (turn-based)
-- - 2-dice mode: Body Die + Action Die
-- - 3-dice mode: Body Die + Action Die + RED Die (escalation)
-- 
-- Body Die (6-sided): Mouth, Chest, Neck, Ass, Back, Crotch
-- Action Die (6-sided): Kiss, Lick, Squeeze, Pinch, Caress, Suck
-- RED Die (4-sided diamond): X, XXX, THREESOME, ORGY
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 1: DICE BREAKERS GAME TYPE
-- ═══════════════════════════════════════════════════════════════════════════

-- Add dice_breakers to tag game types if using enum
DO $$
BEGIN
    -- Check if the type exists and add value if not present
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tag_game_type') THEN
        BEGIN
            ALTER TYPE tag_game_type ADD VALUE IF NOT EXISTS 'dice_breakers';
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END;
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 2: GAME SESSIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.tag_dice_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Game configuration
    game_mode TEXT NOT NULL CHECK (game_mode IN ('just_dice', 'name_players')),
    dice_count INTEGER NOT NULL CHECK (dice_count IN (2, 3)),
    
    -- Player names (for name_players mode)
    players TEXT[] DEFAULT '{}',
    current_player_index INTEGER DEFAULT 0,
    
    -- Session stats
    total_rolls INTEGER DEFAULT 0,
    
    -- Timestamps
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for user lookups
CREATE INDEX IF NOT EXISTS idx_dice_sessions_host 
ON tag_dice_sessions(host_user_id);

-- Index for active sessions
CREATE INDEX IF NOT EXISTS idx_dice_sessions_active 
ON tag_dice_sessions(ended_at) WHERE ended_at IS NULL;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 3: ROLL HISTORY TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.tag_dice_rolls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES tag_dice_sessions(id) ON DELETE CASCADE,
    
    -- Roll results
    body_result TEXT NOT NULL,
    action_result TEXT NOT NULL,
    red_result TEXT, -- NULL if 2-dice mode
    
    -- Player info (for name_players mode)
    roller_name TEXT,
    target_player TEXT,
    target_players TEXT[], -- For THREESOME/ORGY
    
    -- Timestamp
    rolled_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for session lookups
CREATE INDEX IF NOT EXISTS idx_dice_rolls_session 
ON tag_dice_rolls(session_id);

-- Index for analytics
CREATE INDEX IF NOT EXISTS idx_dice_rolls_results 
ON tag_dice_rolls(body_result, action_result);

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 4: ANALYTICS VIEW
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW tag_dice_analytics AS
SELECT 
    -- Popular body parts
    body_result,
    action_result,
    red_result,
    COUNT(*) as roll_count,
    COUNT(DISTINCT session_id) as unique_sessions
FROM tag_dice_rolls
GROUP BY body_result, action_result, red_result
ORDER BY roll_count DESC;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 5: ENABLE RLS
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE tag_dice_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_dice_rolls ENABLE ROW LEVEL SECURITY;

-- Sessions: Anyone can create/read their own sessions
CREATE POLICY "Users can manage their own dice sessions"
ON tag_dice_sessions
FOR ALL
USING (host_user_id = auth.uid() OR host_user_id IS NULL)
WITH CHECK (host_user_id = auth.uid() OR host_user_id IS NULL);

-- Rolls: Anyone can read rolls for sessions they can access
CREATE POLICY "Users can manage rolls for their sessions"
ON tag_dice_rolls
FOR ALL
USING (
    session_id IN (
        SELECT id FROM tag_dice_sessions 
        WHERE host_user_id = auth.uid() OR host_user_id IS NULL
    )
);

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 6: ADD TO LUDUS GAMES CATALOG
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO public.ludus_games (
    title, 
    description, 
    category, 
    rating_level, 
    min_players, 
    max_players, 
    estimated_duration,
    content,
    is_active
) 
SELECT
    'Dice Breakers',
    'Roll the dice and let fate decide what happens next. Choose between Just Dice for quick anonymous play, or Name Players for turn-based action with assigned partners.',
    'dice_breakers',
    'yellow',
    2,
    10,
    15,
    '{
        "modes": ["just_dice", "name_players"],
        "dice_options": [2, 3],
        "body_die": ["Mouth", "Chest", "Neck", "Ass", "Back", "Crotch"],
        "action_die": ["Kiss", "Lick", "Squeeze", "Pinch", "Caress", "Suck"],
        "red_die": ["X", "XXX", "THREESOME", "ORGY"],
        "tag_rating": {
            "velocity": 99,
            "heat": "XXX",
            "duration": "Foreplay"
        }
    }'::jsonb,
    true
WHERE NOT EXISTS (
    SELECT 1 FROM public.ludus_games WHERE title = 'Dice Breakers'
);

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 7: UPDATE GAME TYPE CHECK CONSTRAINT AND ADD ACHIEVEMENTS
-- ═══════════════════════════════════════════════════════════════════════════

-- First, drop and recreate the check constraint to include dice_breakers
ALTER TABLE tag_achievements DROP CONSTRAINT IF EXISTS tag_achievements_game_type_check;

ALTER TABLE tag_achievements ADD CONSTRAINT tag_achievements_game_type_check 
CHECK (game_type IS NULL OR game_type IN (
    'down_to_clown',
    'ice_breakers',
    'velvet_rope',
    'share_or_dare',
    'path_of_pleasure',
    'lane_of_lust',
    'drama_sutra',
    'flash_freeze',
    'dice_breakers'
));

-- Now add the achievements
INSERT INTO public.tag_achievements (id, name, description, icon, category, rarity, points, requirements, game_type, is_hidden)
VALUES 
    ('dice_first', 'Lucky Roller', 'Play your first Dice Breakers game', 'casino', 'explorer', 'common', 10, '{"games_played": 1}', 'dice_breakers', false),
    ('dice_10', 'Dice Devotee', 'Play 10 Dice Breakers games', 'casino', 'specialist', 'uncommon', 30, '{"games_played": 10}', 'dice_breakers', false),
    ('dice_50', 'Fate Master', 'Play 50 Dice Breakers games', 'stars', 'specialist', 'rare', 75, '{"games_played": 50}', 'dice_breakers', false),
    ('dice_red', 'Red Hot', 'Roll the RED die for the first time', 'whatshot', 'explorer', 'uncommon', 20, '{"red_die_rolls": 1}', 'dice_breakers', false),
    ('dice_orgy', 'Party Starter', 'Roll ORGY on the RED die', 'celebration', 'social', 'rare', 50, '{"orgy_rolls": 1}', 'dice_breakers', true)
ON CONFLICT (id) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════════════════════

COMMENT ON TABLE tag_dice_sessions IS 'Dice Breakers game sessions - tracks mode, players, and roll counts';
COMMENT ON TABLE tag_dice_rolls IS 'Individual dice roll history for Dice Breakers games';
COMMENT ON VIEW tag_dice_analytics IS 'Analytics view for popular dice combinations';
