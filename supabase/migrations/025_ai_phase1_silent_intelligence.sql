-- ════════════════════════════════════════════════════════════════════════════
-- MIGRATION 025: AI PHASE 1 - SILENT INTELLIGENCE
-- ════════════════════════════════════════════════════════════════════════════
-- Creates tables for:
-- 1. Engagement event tracking (learn what works)
-- 2. User preference learning (smart defaults)
-- 3. Prompt effectiveness metrics (improve content)
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- ENGAGEMENT EVENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Central event store for all user interactions

CREATE TABLE IF NOT EXISTS engagement_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    properties JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX idx_engagement_events_user_id ON engagement_events(user_id);
CREATE INDEX idx_engagement_events_type ON engagement_events(event_type);
CREATE INDEX idx_engagement_events_created_at ON engagement_events(created_at DESC);
CREATE INDEX idx_engagement_events_user_type ON engagement_events(user_id, event_type);

-- Composite index for common queries
CREATE INDEX idx_engagement_events_user_type_time 
    ON engagement_events(user_id, event_type, created_at DESC);

-- GIN index for JSONB properties
CREATE INDEX idx_engagement_events_properties ON engagement_events USING GIN (properties);

-- ═══════════════════════════════════════════════════════════════════════════
-- AI USER PREFERENCES TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Learned preferences for each user (smart defaults)

CREATE TABLE IF NOT EXISTS ai_user_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Activity patterns
    active_hours INT[] DEFAULT '{}',
    active_days INT[] DEFAULT '{}',
    avg_session_duration_seconds INT DEFAULT 0,
    
    -- Game preferences (learned from usage)
    preferred_heat_levels JSONB DEFAULT '{}',
    -- Example: {"down_to_clown": "R", "velvet_rope": "PG-13"}
    
    favorite_games TEXT[] DEFAULT '{}',
    avg_game_duration_seconds INT DEFAULT 0,
    
    -- Conversation patterns
    avg_message_length INT DEFAULT 0,
    response_time_seconds INT DEFAULT 0,
    conversation_style TEXT DEFAULT 'balanced',
    -- 'brief', 'balanced', 'detailed'
    
    -- Matching patterns
    avg_decision_time_seconds INT DEFAULT 0,
    like_rate DECIMAL(5,4) DEFAULT 0.5,
    
    -- Learned interests (from conversations/games)
    learned_interests TEXT[] DEFAULT '{}',
    
    -- Metadata
    data_points_count INT DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- PROMPT EFFECTIVENESS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Track how well each prompt performs

CREATE TABLE IF NOT EXISTS prompt_effectiveness (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_type TEXT NOT NULL,
    prompt_id UUID NOT NULL,
    heat_level TEXT NOT NULL,
    
    -- Engagement metrics
    shown_count INT DEFAULT 0,
    completed_count INT DEFAULT 0,
    skipped_count INT DEFAULT 0,
    liked_count INT DEFAULT 0,
    laughed_count INT DEFAULT 0,
    
    -- Calculated score (0-1)
    effectiveness_score DECIMAL(5,4) DEFAULT 0.5,
    
    -- Time metrics
    avg_time_spent_seconds INT DEFAULT 0,
    
    -- Last calculation
    last_calculated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(game_type, prompt_id)
);

CREATE INDEX idx_prompt_effectiveness_game ON prompt_effectiveness(game_type);
CREATE INDEX idx_prompt_effectiveness_score ON prompt_effectiveness(effectiveness_score DESC);
CREATE INDEX idx_prompt_effectiveness_heat ON prompt_effectiveness(heat_level);

-- ═══════════════════════════════════════════════════════════════════════════
-- GAME SESSION ANALYTICS TABLE
-- ═══════════════════════════════════════════════════════════════════════════
-- Aggregated session data for learning

CREATE TABLE IF NOT EXISTS game_session_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID,
    game_type TEXT NOT NULL,
    heat_level TEXT NOT NULL,
    player_count INT NOT NULL,
    
    -- Session metrics
    rounds_played INT DEFAULT 0,
    duration_seconds INT DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    
    -- Engagement
    prompts_shown INT DEFAULT 0,
    prompts_completed INT DEFAULT 0,
    prompts_skipped INT DEFAULT 0,
    
    -- Timestamps
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_game_session_analytics_game ON game_session_analytics(game_type);
CREATE INDEX idx_game_session_analytics_heat ON game_session_analytics(heat_level);
CREATE INDEX idx_game_session_analytics_time ON game_session_analytics(started_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS: Update User Preferences
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_user_active_hours(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_hours INT[];
BEGIN
    -- Get most common active hours from recent sessions
    SELECT ARRAY_AGG(hour ORDER BY count DESC)
    INTO v_hours
    FROM (
        SELECT 
            (properties->>'hour_of_day')::INT as hour,
            COUNT(*) as count
        FROM engagement_events
        WHERE user_id = p_user_id
          AND event_type = 'session_start'
          AND created_at > NOW() - INTERVAL '30 days'
        GROUP BY (properties->>'hour_of_day')::INT
        ORDER BY count DESC
        LIMIT 5
    ) sub;
    
    UPDATE ai_user_preferences
    SET active_hours = COALESCE(v_hours, '{}'),
        last_updated = NOW()
    WHERE user_id = p_user_id;
    
    -- Insert if not exists
    IF NOT FOUND THEN
        INSERT INTO ai_user_preferences (user_id, active_hours)
        VALUES (p_user_id, COALESCE(v_hours, '{}'));
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS: Update Prompt Effectiveness
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION calculate_prompt_effectiveness(p_game_type TEXT)
RETURNS VOID AS $$
BEGIN
    -- Aggregate prompt engagement data
    INSERT INTO prompt_effectiveness (game_type, prompt_id, heat_level, 
        shown_count, completed_count, skipped_count, liked_count, laughed_count,
        effectiveness_score, last_calculated)
    SELECT 
        p_game_type,
        (properties->>'prompt_id')::UUID,
        properties->>'heat_level',
        COUNT(*) FILTER (WHERE properties->>'action' = 'shown'),
        COUNT(*) FILTER (WHERE properties->>'action' = 'completed'),
        COUNT(*) FILTER (WHERE properties->>'action' = 'skipped'),
        COUNT(*) FILTER (WHERE properties->>'action' = 'liked'),
        COUNT(*) FILTER (WHERE properties->>'action' = 'laughed'),
        -- Score calculation: weighted average of positive actions
        CASE 
            WHEN COUNT(*) = 0 THEN 0.5
            ELSE (
                (COUNT(*) FILTER (WHERE properties->>'action' = 'completed') * 1.0 +
                 COUNT(*) FILTER (WHERE properties->>'action' = 'laughed') * 0.9 +
                 COUNT(*) FILTER (WHERE properties->>'action' = 'liked') * 0.8 +
                 COUNT(*) FILTER (WHERE properties->>'action' = 'skipped') * 0.3) /
                NULLIF(COUNT(*), 0)
            )::DECIMAL(5,4)
        END,
        NOW()
    FROM engagement_events
    WHERE event_type = 'prompt_engagement'
      AND properties->>'game_type' = p_game_type
      AND created_at > NOW() - INTERVAL '90 days'
    GROUP BY (properties->>'prompt_id')::UUID, properties->>'heat_level'
    ON CONFLICT (game_type, prompt_id) DO UPDATE SET
        shown_count = EXCLUDED.shown_count,
        completed_count = EXCLUDED.completed_count,
        skipped_count = EXCLUDED.skipped_count,
        liked_count = EXCLUDED.liked_count,
        laughed_count = EXCLUDED.laughed_count,
        effectiveness_score = EXCLUDED.effectiveness_score,
        last_calculated = NOW();
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS: Get Best Prompts
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_best_prompts(
    p_game_type TEXT,
    p_heat_level TEXT,
    p_limit INT DEFAULT 20
)
RETURNS TABLE (
    prompt_id UUID,
    effectiveness_score DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT pe.prompt_id, pe.effectiveness_score
    FROM prompt_effectiveness pe
    WHERE pe.game_type = p_game_type
      AND pe.heat_level = p_heat_level
      AND pe.shown_count >= 5  -- Minimum samples
    ORDER BY pe.effectiveness_score DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS: Get User Preferred Heat
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_user_preferred_heat(
    p_user_id UUID,
    p_game_type TEXT
)
RETURNS TEXT AS $$
DECLARE
    v_heat TEXT;
BEGIN
    SELECT preferred_heat_levels->>p_game_type
    INTO v_heat
    FROM ai_user_preferences
    WHERE user_id = p_user_id;
    
    -- Default to PG if no preference
    RETURN COALESCE(v_heat, 'PG');
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE engagement_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompt_effectiveness ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_session_analytics ENABLE ROW LEVEL SECURITY;

-- Users can only insert their own events
CREATE POLICY "Users can insert own events"
    ON engagement_events FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can only read their own events
CREATE POLICY "Users can read own events"
    ON engagement_events FOR SELECT
    USING (auth.uid() = user_id);

-- Users can only access their own preferences
CREATE POLICY "Users can manage own preferences"
    ON ai_user_preferences FOR ALL
    USING (auth.uid() = user_id);

-- Prompt effectiveness is readable by all authenticated users
CREATE POLICY "Anyone can read prompt effectiveness"
    ON prompt_effectiveness FOR SELECT
    TO authenticated
    USING (true);

-- Game session analytics - users can insert, admins can read all
CREATE POLICY "Users can insert session analytics"
    ON game_session_analytics FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- ═══════════════════════════════════════════════════════════════════════════
-- DATA RETENTION: Auto-cleanup old events (keep 90 days)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION cleanup_old_engagement_events()
RETURNS VOID AS $$
BEGIN
    DELETE FROM engagement_events
    WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule this to run daily via pg_cron or external scheduler
-- SELECT cron.schedule('cleanup-engagement', '0 3 * * *', 'SELECT cleanup_old_engagement_events()');

-- ═══════════════════════════════════════════════════════════════════════════
-- GRANTS
-- ═══════════════════════════════════════════════════════════════════════════

GRANT SELECT, INSERT ON engagement_events TO authenticated;
GRANT SELECT, INSERT, UPDATE ON ai_user_preferences TO authenticated;
GRANT SELECT ON prompt_effectiveness TO authenticated;
GRANT SELECT, INSERT ON game_session_analytics TO authenticated;
