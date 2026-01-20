-- ════════════════════════════════════════════════════════════════════════════
-- MIGRATION 024: TAG CROSS-GAME ACHIEVEMENTS
-- ════════════════════════════════════════════════════════════════════════════
-- Implements a unified achievement system across all TAG games.
-- Achievements reward players for milestones, creativity, and engagement.
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- ACHIEVEMENT DEFINITIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Master list of all possible achievements

CREATE TABLE IF NOT EXISTS tag_achievements (
    id VARCHAR(50) PRIMARY KEY,
    
    -- Display information
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(50) NOT NULL DEFAULT 'trophy',
    
    -- Categorization
    category VARCHAR(30) NOT NULL CHECK (category IN (
        'milestone',      -- Games played, cards completed
        'explorer',       -- Try different games/modes
        'social',         -- Multiplayer achievements
        'spicy',          -- Content rating progression
        'specialist',     -- Master specific games
        'streak',         -- Consecutive actions
        'rare',           -- Hard to get achievements
        'seasonal'        -- Time-limited achievements
    )),
    
    -- Rarity/points
    rarity VARCHAR(20) NOT NULL DEFAULT 'common' CHECK (rarity IN (
        'common',         -- Easy to unlock (50+ players have it)
        'uncommon',       -- Moderate effort (20-50%)
        'rare',           -- Significant effort (5-20%)
        'epic',           -- Major milestone (1-5%)
        'legendary'       -- Elite status (<1%)
    )),
    points INTEGER NOT NULL DEFAULT 10,
    
    -- Requirements (JSONB for flexible criteria)
    -- Examples:
    -- {"games_played": 10}
    -- {"game_type": "drama_sutra", "games_played": 5}
    -- {"cards_completed": 100}
    -- {"content_rating": "x", "games_played": 1}
    -- {"unique_games": 5}
    -- {"streak_days": 7}
    requirements JSONB NOT NULL DEFAULT '{}',
    
    -- Game association (null = cross-game)
    game_type VARCHAR(50) CHECK (game_type IS NULL OR game_type IN (
        'down_to_clown',
        'ice_breakers',
        'velvet_rope',
        'path_of_pleasure',
        'lane_of_lust',
        'drama_sutra',
        'flash_freeze'
    )),
    
    -- Visibility
    is_hidden BOOLEAN NOT NULL DEFAULT false,  -- Hidden until unlocked
    is_active BOOLEAN NOT NULL DEFAULT true,   -- Can be earned
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- USER ACHIEVEMENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Tracks which users have unlocked which achievements

CREATE TABLE IF NOT EXISTS tag_user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id VARCHAR(50) NOT NULL REFERENCES tag_achievements(id) ON DELETE CASCADE,
    
    -- Context of unlock
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    unlocked_in_session UUID REFERENCES tag_game_sessions(id) ON DELETE SET NULL,
    unlocked_in_game VARCHAR(50),
    
    -- Progress snapshot at unlock
    progress_snapshot JSONB DEFAULT '{}',
    
    -- Has user seen the unlock notification?
    is_seen BOOLEAN NOT NULL DEFAULT false,
    
    -- Unique per user per achievement
    UNIQUE(user_id, achievement_id)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- ACHIEVEMENT PROGRESS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Tracks progress toward achievements (for progressive achievements)

CREATE TABLE IF NOT EXISTS tag_achievement_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id VARCHAR(50) NOT NULL REFERENCES tag_achievements(id) ON DELETE CASCADE,
    
    -- Current progress value
    current_value INTEGER NOT NULL DEFAULT 0,
    target_value INTEGER NOT NULL,
    
    -- Last update
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Unique per user per achievement
    UNIQUE(user_id, achievement_id)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- SEED ACHIEVEMENTS
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO tag_achievements (id, name, description, icon, category, rarity, points, requirements, game_type, is_hidden) VALUES

-- ═══════════════════════════════════════════════════════════════════════════
-- MILESTONE ACHIEVEMENTS
-- ═══════════════════════════════════════════════════════════════════════════
('first_game', 'First Timer', 'Play your first TAG game', 'play_arrow', 'milestone', 'common', 10, '{"games_played": 1}', NULL, false),
('games_10', 'Getting Started', 'Play 10 TAG games', 'trending_up', 'milestone', 'common', 25, '{"games_played": 10}', NULL, false),
('games_50', 'Regular Player', 'Play 50 TAG games', 'star', 'milestone', 'uncommon', 50, '{"games_played": 50}', NULL, false),
('games_100', 'Century Club', 'Play 100 TAG games', 'military_tech', 'milestone', 'rare', 100, '{"games_played": 100}', NULL, false),
('games_500', 'TAG Veteran', 'Play 500 TAG games', 'workspace_premium', 'milestone', 'epic', 250, '{"games_played": 500}', NULL, false),
('games_1000', 'TAG Legend', 'Play 1000 TAG games', 'diamond', 'milestone', 'legendary', 500, '{"games_played": 1000}', NULL, true),

('cards_100', 'Card Collector', 'Complete 100 cards/prompts', 'style', 'milestone', 'common', 25, '{"cards_completed": 100}', NULL, false),
('cards_500', 'Card Enthusiast', 'Complete 500 cards/prompts', 'collections', 'milestone', 'uncommon', 75, '{"cards_completed": 500}', NULL, false),
('cards_1000', 'Card Master', 'Complete 1000 cards/prompts', 'auto_awesome', 'milestone', 'rare', 150, '{"cards_completed": 1000}', NULL, false),

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPLORER ACHIEVEMENTS
-- ═══════════════════════════════════════════════════════════════════════════
('explorer_3', 'Curious Mind', 'Try 3 different TAG games', 'explore', 'explorer', 'common', 20, '{"unique_games": 3}', NULL, false),
('explorer_5', 'Game Hopper', 'Try 5 different TAG games', 'travel_explore', 'explorer', 'uncommon', 40, '{"unique_games": 5}', NULL, false),
('explorer_7', 'Full Collection', 'Play all 7 TAG games', 'emoji_events', 'explorer', 'rare', 100, '{"unique_games": 7}', NULL, false),

('try_dtc', 'Clown Around', 'Play your first Down to Clown game', 'sentiment_very_satisfied', 'explorer', 'common', 10, '{"games_played": 1}', 'down_to_clown', false),
('try_icebreakers', 'Ice Breaker', 'Play your first Ice Breakers game', 'ac_unit', 'explorer', 'common', 10, '{"games_played": 1}', 'ice_breakers', false),
('try_velvet', 'VIP Access', 'Play your first Velvet Rope game', 'local_bar', 'explorer', 'common', 10, '{"games_played": 1}', 'velvet_rope', false),
('try_pop', 'Pleasure Seeker', 'Play your first Path of Pleasure game', 'route', 'explorer', 'common', 10, '{"games_played": 1}', 'path_of_pleasure', false),
('try_lol', 'Lane Lover', 'Play your first Lane of Lust game', 'local_fire_department', 'explorer', 'common', 10, '{"games_played": 1}', 'lane_of_lust', false),
('try_drama', 'Drama Queen', 'Play your first Drama-Sutra game', 'theater_comedy', 'explorer', 'common', 10, '{"games_played": 1}', 'drama_sutra', false),
('try_flash', 'Freeze Frame', 'Play your first Flash & Freeze game', 'camera', 'explorer', 'common', 10, '{"games_played": 1}', 'flash_freeze', false),

-- ═══════════════════════════════════════════════════════════════════════════
-- SPICY ACHIEVEMENTS (Content Rating)
-- ═══════════════════════════════════════════════════════════════════════════
('spicy_pg13', 'Getting Warmer', 'Play a game at PG-13 level', 'thermostat', 'spicy', 'common', 15, '{"content_rating": "pg13", "games_played": 1}', NULL, false),
('spicy_r', 'Turning Up Heat', 'Play a game at R level', 'whatshot', 'spicy', 'uncommon', 25, '{"content_rating": "r", "games_played": 1}', NULL, false),
('spicy_x', 'Feeling Spicy', 'Play a game at X level', 'local_fire_department', 'spicy', 'rare', 40, '{"content_rating": "x", "games_played": 1}', NULL, true),
('spicy_xxx', 'Maximum Heat', 'Play a game at XXX level', 'whatshot', 'spicy', 'epic', 75, '{"content_rating": "xxx", "games_played": 1}', NULL, true),

('heat_master', 'Heat Master', 'Play 10 games at R or higher', 'outdoor_grill', 'spicy', 'rare', 60, '{"content_rating_min": "r", "games_played": 10}', NULL, true),

-- ═══════════════════════════════════════════════════════════════════════════
-- SPECIALIST ACHIEVEMENTS (Per-Game Mastery)
-- ═══════════════════════════════════════════════════════════════════════════
('dtc_10', 'Class Clown', 'Play 10 Down to Clown games', 'mood', 'specialist', 'uncommon', 30, '{"games_played": 10}', 'down_to_clown', false),
('dtc_50', 'Clown Prince', 'Play 50 Down to Clown games', 'face', 'specialist', 'rare', 75, '{"games_played": 50}', 'down_to_clown', false),
('dtc_master', 'Master Clown', 'Play 100 Down to Clown games', 'sentiment_very_satisfied', 'specialist', 'epic', 150, '{"games_played": 100}', 'down_to_clown', true),

('icebreakers_10', 'Cool Cat', 'Play 10 Ice Breakers games', 'ac_unit', 'specialist', 'uncommon', 30, '{"games_played": 10}', 'ice_breakers', false),
('icebreakers_50', 'Frost King', 'Play 50 Ice Breakers games', 'severe_cold', 'specialist', 'rare', 75, '{"games_played": 50}', 'ice_breakers', false),

('velvet_10', 'Velvet Regular', 'Play 10 Velvet Rope games', 'nightlife', 'specialist', 'uncommon', 30, '{"games_played": 10}', 'velvet_rope', false),
('velvet_50', 'VIP Member', 'Play 50 Velvet Rope games', 'verified', 'specialist', 'rare', 75, '{"games_played": 50}', 'velvet_rope', false),

('pop_10', 'Path Walker', 'Play 10 Path of Pleasure games', 'hiking', 'specialist', 'uncommon', 30, '{"games_played": 10}', 'path_of_pleasure', false),
('pop_50', 'Pleasure Pro', 'Play 50 Path of Pleasure games', 'directions_run', 'specialist', 'rare', 75, '{"games_played": 50}', 'path_of_pleasure', false),

('lol_10', 'Lane Runner', 'Play 10 Lane of Lust games', 'directions', 'specialist', 'uncommon', 30, '{"games_played": 10}', 'lane_of_lust', false),
('lol_50', 'Lust Legend', 'Play 50 Lane of Lust games', 'local_fire_department', 'specialist', 'rare', 75, '{"games_played": 50}', 'lane_of_lust', false),

('drama_10', 'Drama Student', 'Play 10 Drama-Sutra games', 'school', 'specialist', 'uncommon', 30, '{"games_played": 10}', 'drama_sutra', false),
('drama_50', 'Method Actor', 'Play 50 Drama-Sutra games', 'theater_comedy', 'specialist', 'rare', 75, '{"games_played": 50}', 'drama_sutra', false),

('flash_10', 'Quick Freeze', 'Play 10 Flash & Freeze games', 'flash_on', 'specialist', 'uncommon', 30, '{"games_played": 10}', 'flash_freeze', false),
('flash_50', 'Freeze Master', 'Play 50 Flash & Freeze games', 'camera_roll', 'specialist', 'rare', 75, '{"games_played": 50}', 'flash_freeze', false),

-- ═══════════════════════════════════════════════════════════════════════════
-- SOCIAL ACHIEVEMENTS
-- ═══════════════════════════════════════════════════════════════════════════
('party_4', 'Small Gathering', 'Play a game with 4+ players', 'groups', 'social', 'common', 15, '{"min_players": 4, "games_played": 1}', NULL, false),
('party_6', 'Party Mode', 'Play a game with 6+ players', 'celebration', 'social', 'uncommon', 30, '{"min_players": 6, "games_played": 1}', NULL, false),
('party_8', 'Full House', 'Play a game with maximum (8) players', 'diversity_3', 'social', 'rare', 50, '{"min_players": 8, "games_played": 1}', NULL, false),

('host_10', 'Party Planner', 'Host 10 games', 'event', 'social', 'uncommon', 35, '{"games_hosted": 10}', NULL, false),
('host_50', 'Event Organizer', 'Host 50 games', 'celebration', 'social', 'rare', 80, '{"games_hosted": 50}', NULL, false),

-- ═══════════════════════════════════════════════════════════════════════════
-- STREAK ACHIEVEMENTS
-- ═══════════════════════════════════════════════════════════════════════════
('streak_3', 'Three-peat', 'Play 3 days in a row', 'looks_3', 'streak', 'common', 20, '{"streak_days": 3}', NULL, false),
('streak_7', 'Weekly Warrior', 'Play 7 days in a row', 'date_range', 'streak', 'uncommon', 50, '{"streak_days": 7}', NULL, false),
('streak_14', 'Fortnight Fighter', 'Play 14 days in a row', 'calendar_month', 'streak', 'rare', 100, '{"streak_days": 14}', NULL, false),
('streak_30', 'Monthly Master', 'Play 30 days in a row', 'event_available', 'streak', 'epic', 200, '{"streak_days": 30}', NULL, true),

('no_skip_10', 'Committed Player', 'Complete 10 cards without skipping', 'thumb_up', 'streak', 'common', 20, '{"no_skip_streak": 10}', NULL, false),
('no_skip_25', 'All In', 'Complete 25 cards without skipping', 'verified', 'streak', 'uncommon', 45, '{"no_skip_streak": 25}', NULL, false),
('no_skip_50', 'No Hesitation', 'Complete 50 cards without skipping', 'military_tech', 'streak', 'rare', 90, '{"no_skip_streak": 50}', NULL, false),

-- ═══════════════════════════════════════════════════════════════════════════
-- RARE / SPECIAL ACHIEVEMENTS
-- ═══════════════════════════════════════════════════════════════════════════
('night_owl', 'Night Owl', 'Play a game after midnight', 'nights_stay', 'rare', 'uncommon', 25, '{"time_after": "00:00", "time_before": "04:00"}', NULL, true),
('early_bird', 'Early Bird', 'Play a game before 6 AM', 'wb_twilight', 'rare', 'uncommon', 25, '{"time_after": "04:00", "time_before": "06:00"}', NULL, true),
('marathon', 'Marathon Session', 'Play for over 2 hours in one session', 'timer', 'rare', 'rare', 60, '{"session_minutes": 120}', NULL, true),
('speed_demon', 'Speed Demon', 'Complete a game in under 5 minutes', 'speed', 'rare', 'rare', 50, '{"session_minutes_max": 5, "cards_completed_min": 10}', NULL, true),

('perfectionist', 'Perfectionist', 'Finish a game with 100% completion (no skips)', 'workspace_premium', 'rare', 'rare', 75, '{"completion_rate": 100}', NULL, false),
('comeback', 'Comeback Kid', 'Return after 30+ days away', 'update', 'rare', 'uncommon', 35, '{"days_away": 30}', NULL, true),

('flash_photographer', 'Flash Photographer', 'Capture 50 freeze photos', 'photo_library', 'rare', 'rare', 80, '{"photos_captured": 50}', 'flash_freeze', false),
('drama_awards', 'Award Winner', 'Get 5-star accuracy ratings 10 times', 'emoji_events', 'rare', 'rare', 80, '{"five_star_ratings": 10}', 'drama_sutra', false);

-- ═══════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_tag_achievements_category ON tag_achievements(category);
CREATE INDEX IF NOT EXISTS idx_tag_achievements_game ON tag_achievements(game_type);
CREATE INDEX IF NOT EXISTS idx_tag_achievements_rarity ON tag_achievements(rarity);
CREATE INDEX IF NOT EXISTS idx_tag_achievements_active ON tag_achievements(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_tag_user_achievements_user ON tag_user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_tag_user_achievements_achievement ON tag_user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_tag_user_achievements_unseen ON tag_user_achievements(user_id, is_seen) WHERE is_seen = false;
CREATE INDEX IF NOT EXISTS idx_tag_user_achievements_unlocked ON tag_user_achievements(unlocked_at DESC);

CREATE INDEX IF NOT EXISTS idx_tag_achievement_progress_user ON tag_achievement_progress(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Check and unlock achievement for user
CREATE OR REPLACE FUNCTION check_and_unlock_achievement(
    p_user_id UUID,
    p_achievement_id VARCHAR(50),
    p_session_id UUID DEFAULT NULL,
    p_game_type VARCHAR(50) DEFAULT NULL,
    p_progress_snapshot JSONB DEFAULT '{}'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_already_unlocked BOOLEAN;
BEGIN
    -- Check if already unlocked
    SELECT EXISTS(
        SELECT 1 FROM tag_user_achievements 
        WHERE user_id = p_user_id AND achievement_id = p_achievement_id
    ) INTO v_already_unlocked;
    
    IF v_already_unlocked THEN
        RETURN false;
    END IF;
    
    -- Check if achievement exists and is active
    IF NOT EXISTS(
        SELECT 1 FROM tag_achievements 
        WHERE id = p_achievement_id AND is_active = true
    ) THEN
        RETURN false;
    END IF;
    
    -- Unlock the achievement
    INSERT INTO tag_user_achievements (
        user_id, 
        achievement_id, 
        unlocked_in_session, 
        unlocked_in_game,
        progress_snapshot
    )
    VALUES (
        p_user_id, 
        p_achievement_id, 
        p_session_id, 
        p_game_type,
        p_progress_snapshot
    );
    
    -- Update user stats achievements array
    UPDATE tag_user_stats
    SET achievements = achievements || to_jsonb(p_achievement_id)
    WHERE user_id = p_user_id;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Get user's achievement points
CREATE OR REPLACE FUNCTION get_user_achievement_points(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_points INTEGER;
BEGIN
    SELECT COALESCE(SUM(a.points), 0)
    INTO v_points
    FROM tag_user_achievements ua
    JOIN tag_achievements a ON ua.achievement_id = a.id
    WHERE ua.user_id = p_user_id;
    
    RETURN v_points;
END;
$$ LANGUAGE plpgsql;

-- Get unseen achievements for user
CREATE OR REPLACE FUNCTION get_unseen_achievements(p_user_id UUID)
RETURNS TABLE (
    achievement_id VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    icon VARCHAR(50),
    category VARCHAR(30),
    rarity VARCHAR(20),
    points INTEGER,
    unlocked_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        a.description,
        a.icon,
        a.category,
        a.rarity,
        a.points,
        ua.unlocked_at
    FROM tag_user_achievements ua
    JOIN tag_achievements a ON ua.achievement_id = a.id
    WHERE ua.user_id = p_user_id
        AND ua.is_seen = false
    ORDER BY ua.unlocked_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Mark achievements as seen
CREATE OR REPLACE FUNCTION mark_achievements_seen(p_user_id UUID, p_achievement_ids VARCHAR(50)[])
RETURNS void AS $$
BEGIN
    UPDATE tag_user_achievements
    SET is_seen = true
    WHERE user_id = p_user_id
        AND achievement_id = ANY(p_achievement_ids);
END;
$$ LANGUAGE plpgsql;

-- Update achievement progress
CREATE OR REPLACE FUNCTION update_achievement_progress(
    p_user_id UUID,
    p_achievement_id VARCHAR(50),
    p_increment INTEGER DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current INTEGER;
    v_target INTEGER;
    v_new_value INTEGER;
BEGIN
    -- Get or create progress record
    INSERT INTO tag_achievement_progress (user_id, achievement_id, current_value, target_value)
    SELECT 
        p_user_id,
        p_achievement_id,
        0,
        COALESCE(
            (SELECT (requirements->>'games_played')::INTEGER FROM tag_achievements WHERE id = p_achievement_id),
            (SELECT (requirements->>'cards_completed')::INTEGER FROM tag_achievements WHERE id = p_achievement_id),
            10
        )
    ON CONFLICT (user_id, achievement_id) DO NOTHING;
    
    -- Update progress
    UPDATE tag_achievement_progress
    SET 
        current_value = current_value + p_increment,
        updated_at = now()
    WHERE user_id = p_user_id AND achievement_id = p_achievement_id
    RETURNING current_value, target_value INTO v_new_value, v_target;
    
    -- Check if complete
    RETURN v_new_value >= v_target;
END;
$$ LANGUAGE plpgsql;

-- Get user's achievement summary
CREATE OR REPLACE FUNCTION get_achievement_summary(p_user_id UUID)
RETURNS TABLE (
    total_unlocked INTEGER,
    total_available INTEGER,
    total_points INTEGER,
    unlocked_by_category JSONB,
    unlocked_by_rarity JSONB,
    recent_unlocks JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM tag_user_achievements WHERE user_id = p_user_id),
        (SELECT COUNT(*)::INTEGER FROM tag_achievements WHERE is_active = true),
        get_user_achievement_points(p_user_id),
        (
            SELECT jsonb_object_agg(category, count)
            FROM (
                SELECT a.category, COUNT(*)::INTEGER as count
                FROM tag_user_achievements ua
                JOIN tag_achievements a ON ua.achievement_id = a.id
                WHERE ua.user_id = p_user_id
                GROUP BY a.category
            ) sub
        ),
        (
            SELECT jsonb_object_agg(rarity, count)
            FROM (
                SELECT a.rarity, COUNT(*)::INTEGER as count
                FROM tag_user_achievements ua
                JOIN tag_achievements a ON ua.achievement_id = a.id
                WHERE ua.user_id = p_user_id
                GROUP BY a.rarity
            ) sub
        ),
        (
            SELECT jsonb_agg(row_to_json(sub))
            FROM (
                SELECT a.id, a.name, a.icon, a.rarity, ua.unlocked_at
                FROM tag_user_achievements ua
                JOIN tag_achievements a ON ua.achievement_id = a.id
                WHERE ua.user_id = p_user_id
                ORDER BY ua.unlocked_at DESC
                LIMIT 5
            ) sub
        );
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE tag_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_achievement_progress ENABLE ROW LEVEL SECURITY;

-- Achievements are publicly readable
CREATE POLICY "Achievements publicly readable"
    ON tag_achievements FOR SELECT
    TO authenticated
    USING (is_active = true AND (is_hidden = false OR id IN (
        SELECT achievement_id FROM tag_user_achievements WHERE user_id = auth.uid()
    )));

-- User achievements: own only
CREATE POLICY "Users can view own achievements"
    ON tag_user_achievements FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Progress: own only
CREATE POLICY "Users can view own progress"
    ON tag_achievement_progress FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Users can update own progress"
    ON tag_achievement_progress FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════════════════════

COMMENT ON TABLE tag_achievements IS 'Master list of all TAG game achievements';
COMMENT ON TABLE tag_user_achievements IS 'User unlocked achievements with context';
COMMENT ON TABLE tag_achievement_progress IS 'Progress tracking for progressive achievements';
COMMENT ON FUNCTION check_and_unlock_achievement IS 'Safely unlock an achievement for a user';
COMMENT ON FUNCTION get_achievement_summary IS 'Get comprehensive achievement stats for a user';
