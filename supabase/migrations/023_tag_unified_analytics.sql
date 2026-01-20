-- ════════════════════════════════════════════════════════════════════════════
-- MIGRATION 023: TAG UNIFIED ANALYTICS
-- ════════════════════════════════════════════════════════════════════════════
-- Creates a unified analytics table for all TAG games, enabling cross-game
-- insights, engagement tracking, and personalized recommendations.
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- GAME SESSIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Unified tracking of all game sessions across all TAG games

CREATE TABLE IF NOT EXISTS tag_game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Session identification
    session_code VARCHAR(8) UNIQUE,
    
    -- Game type (normalized across all games)
    game_type VARCHAR(50) NOT NULL CHECK (game_type IN (
        'down_to_clown',
        'ice_breakers', 
        'velvet_rope',
        'path_of_pleasure',
        'lane_of_lust',
        'drama_sutra',
        'flash_freeze'
    )),
    
    -- Host information
    host_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    host_device_id VARCHAR(100),
    
    -- Session configuration
    player_count INTEGER NOT NULL DEFAULT 0,
    content_rating VARCHAR(10) NOT NULL DEFAULT 'pg' CHECK (content_rating IN ('pg', 'pg13', 'r', 'x', 'xxx')),
    is_demo_mode BOOLEAN NOT NULL DEFAULT false,
    is_multiplayer BOOLEAN NOT NULL DEFAULT false,
    
    -- Game settings (JSONB for game-specific settings)
    game_settings JSONB DEFAULT '{}',
    
    -- Session lifecycle
    status VARCHAR(20) NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'active', 'paused', 'completed', 'abandoned')),
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Session metrics
    total_rounds INTEGER DEFAULT 0,
    total_cards_shown INTEGER DEFAULT 0,
    total_skips INTEGER DEFAULT 0,
    total_completions INTEGER DEFAULT 0
);

-- ═══════════════════════════════════════════════════════════════════════════
-- GAME EVENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Fine-grained event tracking for analytics and engagement insights

CREATE TABLE IF NOT EXISTS tag_game_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Link to session
    session_id UUID NOT NULL REFERENCES tag_game_sessions(id) ON DELETE CASCADE,
    
    -- Event identification
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN (
        -- Lifecycle events
        'game_start',
        'game_pause',
        'game_resume',
        'game_end',
        
        -- Player events
        'player_join',
        'player_leave',
        'player_turn',
        
        -- Card/Content events
        'card_shown',
        'card_completed',
        'card_skipped',
        'card_rated',
        
        -- Special events
        'round_complete',
        'achievement_unlocked',
        'photo_captured',
        'timer_expired',
        
        -- Multiplayer events
        'room_created',
        'room_joined',
        'sync_state'
    )),
    
    -- Event context
    player_index INTEGER,
    card_id UUID,
    card_type VARCHAR(50),
    
    -- Event data (JSONB for flexible data storage)
    event_data JSONB DEFAULT '{}',
    
    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- CARD ENGAGEMENT TABLE  
-- ═══════════════════════════════════════════════════════════════════════════
-- Track engagement metrics per card/prompt for content optimization

CREATE TABLE IF NOT EXISTS tag_card_engagement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Card identification (references various card tables)
    card_table VARCHAR(50) NOT NULL,
    card_id UUID NOT NULL,
    
    -- Aggregated metrics
    times_shown INTEGER NOT NULL DEFAULT 0,
    times_completed INTEGER NOT NULL DEFAULT 0,
    times_skipped INTEGER NOT NULL DEFAULT 0,
    
    -- Rating aggregation (1-5 star)
    total_ratings INTEGER NOT NULL DEFAULT 0,
    rating_sum INTEGER NOT NULL DEFAULT 0,
    
    -- Computed average (updated via trigger)
    average_rating DECIMAL(3, 2) GENERATED ALWAYS AS (
        CASE WHEN total_ratings > 0 
            THEN rating_sum::DECIMAL / total_ratings 
            ELSE 0 
        END
    ) STORED,
    
    -- Completion rate (updated via trigger)
    completion_rate DECIMAL(5, 4) GENERATED ALWAYS AS (
        CASE WHEN times_shown > 0 
            THEN times_completed::DECIMAL / times_shown 
            ELSE 0 
        END
    ) STORED,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Unique constraint
    UNIQUE (card_table, card_id)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- USER GAME STATS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Per-user statistics across all games

CREATE TABLE IF NOT EXISTS tag_user_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Per-game stats (JSONB for flexibility)
    games_played JSONB NOT NULL DEFAULT '{
        "down_to_clown": 0,
        "ice_breakers": 0,
        "velvet_rope": 0,
        "path_of_pleasure": 0,
        "lane_of_lust": 0,
        "drama_sutra": 0,
        "flash_freeze": 0
    }',
    
    -- Aggregate stats
    total_games_played INTEGER NOT NULL DEFAULT 0,
    total_play_time_seconds INTEGER NOT NULL DEFAULT 0,
    total_cards_completed INTEGER NOT NULL DEFAULT 0,
    total_cards_skipped INTEGER NOT NULL DEFAULT 0,
    
    -- Preferences (learned from behavior)
    preferred_content_rating VARCHAR(10) DEFAULT 'pg13',
    favorite_game_type VARCHAR(50),
    
    -- Achievements (JSONB array of achievement IDs)
    achievements JSONB NOT NULL DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Unique per user
    UNIQUE (user_id)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- INDEXES FOR ANALYTICS QUERIES
-- ═══════════════════════════════════════════════════════════════════════════

-- Session queries
CREATE INDEX IF NOT EXISTS idx_tag_sessions_game_type ON tag_game_sessions(game_type);
CREATE INDEX IF NOT EXISTS idx_tag_sessions_status ON tag_game_sessions(status);
CREATE INDEX IF NOT EXISTS idx_tag_sessions_host ON tag_game_sessions(host_user_id);
CREATE INDEX IF NOT EXISTS idx_tag_sessions_created ON tag_game_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tag_sessions_rating ON tag_game_sessions(content_rating);

-- Event queries
CREATE INDEX IF NOT EXISTS idx_tag_events_session ON tag_game_events(session_id);
CREATE INDEX IF NOT EXISTS idx_tag_events_type ON tag_game_events(event_type);
CREATE INDEX IF NOT EXISTS idx_tag_events_created ON tag_game_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tag_events_session_type ON tag_game_events(session_id, event_type);

-- Card engagement queries
CREATE INDEX IF NOT EXISTS idx_tag_engagement_card ON tag_card_engagement(card_table, card_id);
CREATE INDEX IF NOT EXISTS idx_tag_engagement_rating ON tag_card_engagement(average_rating DESC);
CREATE INDEX IF NOT EXISTS idx_tag_engagement_completion ON tag_card_engagement(completion_rate DESC);

-- User stats queries
CREATE INDEX IF NOT EXISTS idx_tag_user_stats_user ON tag_user_stats(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- UPDATE TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Auto-update timestamps
CREATE OR REPLACE FUNCTION update_tag_analytics_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_tag_sessions_updated
    BEFORE UPDATE ON tag_game_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_analytics_timestamp();

CREATE TRIGGER trigger_tag_engagement_updated
    BEFORE UPDATE ON tag_card_engagement
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_analytics_timestamp();

CREATE TRIGGER trigger_tag_user_stats_updated
    BEFORE UPDATE ON tag_user_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_analytics_timestamp();

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Track card engagement (upsert)
CREATE OR REPLACE FUNCTION track_card_engagement(
    p_card_table VARCHAR(50),
    p_card_id UUID,
    p_was_completed BOOLEAN,
    p_rating INTEGER DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    INSERT INTO tag_card_engagement (card_table, card_id, times_shown, times_completed, times_skipped, total_ratings, rating_sum)
    VALUES (
        p_card_table,
        p_card_id,
        1,
        CASE WHEN p_was_completed THEN 1 ELSE 0 END,
        CASE WHEN NOT p_was_completed THEN 1 ELSE 0 END,
        CASE WHEN p_rating IS NOT NULL THEN 1 ELSE 0 END,
        COALESCE(p_rating, 0)
    )
    ON CONFLICT (card_table, card_id) DO UPDATE SET
        times_shown = tag_card_engagement.times_shown + 1,
        times_completed = tag_card_engagement.times_completed + (CASE WHEN p_was_completed THEN 1 ELSE 0 END),
        times_skipped = tag_card_engagement.times_skipped + (CASE WHEN NOT p_was_completed THEN 1 ELSE 0 END),
        total_ratings = tag_card_engagement.total_ratings + (CASE WHEN p_rating IS NOT NULL THEN 1 ELSE 0 END),
        rating_sum = tag_card_engagement.rating_sum + COALESCE(p_rating, 0);
END;
$$ LANGUAGE plpgsql;

-- Update user stats after game
CREATE OR REPLACE FUNCTION update_user_game_stats(
    p_user_id UUID,
    p_game_type VARCHAR(50),
    p_play_time_seconds INTEGER,
    p_cards_completed INTEGER,
    p_cards_skipped INTEGER
)
RETURNS void AS $$
DECLARE
    v_games_played JSONB;
BEGIN
    -- Insert or update user stats
    INSERT INTO tag_user_stats (user_id, total_games_played, total_play_time_seconds, total_cards_completed, total_cards_skipped)
    VALUES (p_user_id, 1, p_play_time_seconds, p_cards_completed, p_cards_skipped)
    ON CONFLICT (user_id) DO UPDATE SET
        total_games_played = tag_user_stats.total_games_played + 1,
        total_play_time_seconds = tag_user_stats.total_play_time_seconds + p_play_time_seconds,
        total_cards_completed = tag_user_stats.total_cards_completed + p_cards_completed,
        total_cards_skipped = tag_user_stats.total_cards_skipped + p_cards_skipped,
        games_played = jsonb_set(
            tag_user_stats.games_played,
            ARRAY[p_game_type],
            to_jsonb(COALESCE((tag_user_stats.games_played->>p_game_type)::INTEGER, 0) + 1)
        );
END;
$$ LANGUAGE plpgsql;

-- Get popular cards for a game type
CREATE OR REPLACE FUNCTION get_popular_cards(
    p_card_table VARCHAR(50),
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    card_id UUID,
    times_shown INTEGER,
    completion_rate DECIMAL,
    average_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.card_id,
        e.times_shown,
        e.completion_rate,
        e.average_rating
    FROM tag_card_engagement e
    WHERE e.card_table = p_card_table
        AND e.times_shown >= 5  -- Minimum sample size
    ORDER BY e.completion_rate DESC, e.average_rating DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE tag_game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_game_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_card_engagement ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_user_stats ENABLE ROW LEVEL SECURITY;

-- Sessions: Host can manage, all authenticated can view
CREATE POLICY "Sessions viewable by authenticated users"
    ON tag_game_sessions FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Sessions manageable by host"
    ON tag_game_sessions FOR ALL
    TO authenticated
    USING (host_user_id = auth.uid());

-- Events: Viewable within session
CREATE POLICY "Events viewable by session participants"
    ON tag_game_events FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Events insertable by authenticated"
    ON tag_game_events FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Engagement: Public read, system write
CREATE POLICY "Engagement publicly readable"
    ON tag_card_engagement FOR SELECT
    TO authenticated
    USING (true);

-- User stats: Own stats only
CREATE POLICY "Users can view own stats"
    ON tag_user_stats FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Users can update own stats"
    ON tag_user_stats FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- ANALYTICS VIEWS
-- ═══════════════════════════════════════════════════════════════════════════

-- Daily game stats
CREATE OR REPLACE VIEW tag_daily_stats AS
SELECT 
    DATE(created_at) as date,
    game_type,
    COUNT(*) as sessions_count,
    SUM(player_count) as total_players,
    AVG(player_count)::DECIMAL(4,2) as avg_players,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
    AVG(EXTRACT(EPOCH FROM (ended_at - started_at)))::INTEGER as avg_duration_seconds
FROM tag_game_sessions
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at), game_type
ORDER BY date DESC, game_type;

-- Popular content ratings by game
CREATE OR REPLACE VIEW tag_rating_popularity AS
SELECT 
    game_type,
    content_rating,
    COUNT(*) as session_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY game_type), 2) as percentage
FROM tag_game_sessions
GROUP BY game_type, content_rating
ORDER BY game_type, session_count DESC;

COMMENT ON TABLE tag_game_sessions IS 'Unified tracking of all TAG game sessions';
COMMENT ON TABLE tag_game_events IS 'Fine-grained event tracking for analytics';
COMMENT ON TABLE tag_card_engagement IS 'Per-card engagement metrics for content optimization';
COMMENT ON TABLE tag_user_stats IS 'Per-user aggregated statistics across all TAG games';
