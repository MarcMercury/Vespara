-- ════════════════════════════════════════════════════════════════════════════
-- MIGRATION 026: AI PHASE 2 - GENTLE NUDGES
-- ════════════════════════════════════════════════════════════════════════════
-- Creates tables for:
-- 1. Couple game history (avoid repeating prompts)
-- 2. Relationship metrics (stage tracking)
-- 3. Nudge tracking (what's been shown/dismissed)
-- 4. Helper functions for smart defaults
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- COUPLE GAME HISTORY
-- ═══════════════════════════════════════════════════════════════════════════
-- Tracks which prompts each couple has seen

CREATE TABLE IF NOT EXISTS couple_game_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id TEXT NOT NULL UNIQUE,
    -- couple_id is a composite: sorted user IDs joined with underscore
    
    -- Prompt history (last 100 per game)
    prompt_ids UUID[] DEFAULT '{}',
    
    -- Game preferences learned from play
    preferred_games TEXT[] DEFAULT '{}',
    preferred_heat_level TEXT DEFAULT 'PG',
    
    -- Session stats
    total_sessions INT DEFAULT 0,
    total_prompts_shown INT DEFAULT 0,
    avg_session_duration_seconds INT DEFAULT 0,
    
    -- Timestamps
    last_played_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_couple_game_history_couple ON couple_game_history(couple_id);
CREATE INDEX idx_couple_game_history_last_played ON couple_game_history(last_played_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- RELATIONSHIP METRICS
-- ═══════════════════════════════════════════════════════════════════════════
-- Aggregated metrics for each match (relationship stage)

CREATE TABLE IF NOT EXISTS relationship_metrics (
    match_id UUID PRIMARY KEY REFERENCES matches(id) ON DELETE CASCADE,
    
    -- Communication metrics
    total_messages INT DEFAULT 0,
    user1_messages INT DEFAULT 0,
    user2_messages INT DEFAULT 0,
    avg_message_length INT DEFAULT 0,
    avg_response_time_minutes INT DEFAULT 0,
    
    -- Engagement metrics
    last_message_at TIMESTAMPTZ,
    first_message_at TIMESTAMPTZ,
    consecutive_days_active INT DEFAULT 0,
    longest_gap_hours INT DEFAULT 0,
    
    -- Milestone tracking
    milestones_reached TEXT[] DEFAULT '{}',
    -- e.g., ['first_message', 'ten_messages', 'first_game', 'exchanged_numbers']
    
    -- Relationship stage (calculated)
    stage TEXT DEFAULT 'new',
    -- 'new', 'getting_to_know', 'building_connection', 'established', 'deep_connection'
    
    -- Health score (0-1)
    health_score DECIMAL(5,4) DEFAULT 0.5,
    
    -- Timestamps
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_relationship_metrics_stage ON relationship_metrics(stage);
CREATE INDEX idx_relationship_metrics_health ON relationship_metrics(health_score);
CREATE INDEX idx_relationship_metrics_last_message ON relationship_metrics(last_message_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- NUDGE HISTORY
-- ═══════════════════════════════════════════════════════════════════════════
-- Tracks nudges shown to users

CREATE TABLE IF NOT EXISTS nudge_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    nudge_type TEXT NOT NULL,
    nudge_id TEXT NOT NULL,
    context JSONB DEFAULT '{}',
    
    -- User action
    action TEXT DEFAULT 'shown',
    -- 'shown', 'clicked', 'dismissed', 'snoozed'
    
    shown_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_nudge_history_user ON nudge_history(user_id);
CREATE INDEX idx_nudge_history_type ON nudge_history(nudge_type);
CREATE INDEX idx_nudge_history_shown ON nudge_history(shown_at DESC);
CREATE UNIQUE INDEX idx_nudge_history_unique ON nudge_history(user_id, nudge_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS: Generate Couple ID
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION generate_couple_id(p_user1_id UUID, p_user2_id UUID)
RETURNS TEXT AS $$
BEGIN
    -- Sort IDs to ensure consistent couple_id regardless of order
    IF p_user1_id < p_user2_id THEN
        RETURN p_user1_id::TEXT || '_' || p_user2_id::TEXT;
    ELSE
        RETURN p_user2_id::TEXT || '_' || p_user1_id::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS: Update Relationship Metrics
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_relationship_metrics(p_match_id UUID)
RETURNS VOID AS $$
DECLARE
    v_message_stats RECORD;
    v_stage TEXT;
    v_health DECIMAL;
BEGIN
    -- Get message statistics
    SELECT 
        COUNT(*) as total_messages,
        COUNT(*) FILTER (WHERE sender_id = (SELECT user1_id FROM matches WHERE id = p_match_id)) as user1_messages,
        COUNT(*) FILTER (WHERE sender_id = (SELECT user2_id FROM matches WHERE id = p_match_id)) as user2_messages,
        AVG(LENGTH(content)) as avg_length,
        MIN(created_at) as first_message,
        MAX(created_at) as last_message
    INTO v_message_stats
    FROM messages
    WHERE match_id = p_match_id;
    
    -- Calculate stage based on messages
    IF v_message_stats.total_messages = 0 THEN
        v_stage := 'new';
    ELSIF v_message_stats.total_messages < 10 THEN
        v_stage := 'getting_to_know';
    ELSIF v_message_stats.total_messages < 50 THEN
        v_stage := 'building_connection';
    ELSIF v_message_stats.total_messages < 200 THEN
        v_stage := 'established';
    ELSE
        v_stage := 'deep_connection';
    END IF;
    
    -- Calculate health score
    -- Based on: balance, recency, engagement
    v_health := 0.5;
    
    -- Balance factor (0.3 to 0.7 is healthy)
    IF v_message_stats.total_messages > 0 THEN
        DECLARE
            v_ratio DECIMAL := v_message_stats.user1_messages::DECIMAL / v_message_stats.total_messages;
        BEGIN
            IF v_ratio BETWEEN 0.3 AND 0.7 THEN
                v_health := v_health + 0.2;
            ELSIF v_ratio BETWEEN 0.2 AND 0.8 THEN
                v_health := v_health + 0.1;
            END IF;
        END;
    END IF;
    
    -- Recency factor
    IF v_message_stats.last_message IS NOT NULL THEN
        IF v_message_stats.last_message > NOW() - INTERVAL '1 day' THEN
            v_health := v_health + 0.2;
        ELSIF v_message_stats.last_message > NOW() - INTERVAL '3 days' THEN
            v_health := v_health + 0.1;
        ELSIF v_message_stats.last_message < NOW() - INTERVAL '7 days' THEN
            v_health := v_health - 0.2;
        END IF;
    END IF;
    
    -- Clamp health
    v_health := GREATEST(0.0, LEAST(1.0, v_health));
    
    -- Upsert metrics
    INSERT INTO relationship_metrics (
        match_id,
        total_messages,
        user1_messages,
        user2_messages,
        avg_message_length,
        first_message_at,
        last_message_at,
        stage,
        health_score,
        updated_at
    ) VALUES (
        p_match_id,
        v_message_stats.total_messages,
        v_message_stats.user1_messages,
        v_message_stats.user2_messages,
        COALESCE(v_message_stats.avg_length, 0)::INT,
        v_message_stats.first_message,
        v_message_stats.last_message,
        v_stage,
        v_health,
        NOW()
    )
    ON CONFLICT (match_id) DO UPDATE SET
        total_messages = EXCLUDED.total_messages,
        user1_messages = EXCLUDED.user1_messages,
        user2_messages = EXCLUDED.user2_messages,
        avg_message_length = EXCLUDED.avg_message_length,
        first_message_at = EXCLUDED.first_message_at,
        last_message_at = EXCLUDED.last_message_at,
        stage = EXCLUDED.stage,
        health_score = EXCLUDED.health_score,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS: Get Relationship Stage
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_relationship_stage(p_match_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_stage TEXT;
BEGIN
    SELECT stage INTO v_stage
    FROM relationship_metrics
    WHERE match_id = p_match_id;
    
    RETURN COALESCE(v_stage, 'new');
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS: Update Prompt Effectiveness (for game personalization)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_prompt_effectiveness(
    p_prompt_id UUID,
    p_game_type TEXT,
    p_completed INT,
    p_skipped INT
)
RETURNS VOID AS $$
DECLARE
    v_current RECORD;
    v_new_score DECIMAL;
BEGIN
    -- Get current stats
    SELECT * INTO v_current
    FROM prompt_effectiveness
    WHERE prompt_id = p_prompt_id AND game_type = p_game_type;
    
    IF v_current IS NULL THEN
        -- Insert new record
        v_new_score := CASE 
            WHEN (p_completed + p_skipped) = 0 THEN 0.5
            ELSE (p_completed::DECIMAL / (p_completed + p_skipped))
        END;
        
        INSERT INTO prompt_effectiveness (
            game_type, prompt_id, heat_level,
            completed_count, skipped_count,
            effectiveness_score
        ) VALUES (
            p_game_type, p_prompt_id, 'PG',
            p_completed, p_skipped,
            v_new_score
        );
    ELSE
        -- Update existing
        v_new_score := CASE 
            WHEN (v_current.completed_count + p_completed + v_current.skipped_count + p_skipped) = 0 THEN 0.5
            ELSE ((v_current.completed_count + p_completed)::DECIMAL / 
                  (v_current.completed_count + p_completed + v_current.skipped_count + p_skipped))
        END;
        
        UPDATE prompt_effectiveness
        SET completed_count = v_current.completed_count + p_completed,
            skipped_count = v_current.skipped_count + p_skipped,
            effectiveness_score = v_new_score,
            last_calculated = NOW()
        WHERE prompt_id = p_prompt_id AND game_type = p_game_type;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS: Get Popular Interests
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_popular_interests(p_limit INT DEFAULT 10)
RETURNS TABLE (interest TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT unnest(interests) as interest
    FROM profiles
    WHERE interests IS NOT NULL AND array_length(interests, 1) > 0
    GROUP BY interest
    ORDER BY COUNT(*) DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- TRIGGER: Auto-update relationship metrics on message
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION trigger_update_relationship_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update metrics for this match
    PERFORM update_relationship_metrics(NEW.match_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Only create trigger if messages table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'messages') THEN
        DROP TRIGGER IF EXISTS update_relationship_metrics_on_message ON messages;
        CREATE TRIGGER update_relationship_metrics_on_message
            AFTER INSERT ON messages
            FOR EACH ROW
            EXECUTE FUNCTION trigger_update_relationship_metrics();
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE couple_game_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationship_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE nudge_history ENABLE ROW LEVEL SECURITY;

-- Couple game history - users in the couple can access
CREATE POLICY "Users can access own couple history"
    ON couple_game_history FOR ALL
    USING (
        couple_id LIKE auth.uid()::TEXT || '_%' OR
        couple_id LIKE '%_' || auth.uid()::TEXT
    );

-- Relationship metrics - users in the match can access
CREATE POLICY "Users can access own relationship metrics"
    ON relationship_metrics FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM matches m
            WHERE m.id = relationship_metrics.match_id
            AND (m.user_a_id = auth.uid() OR m.user_b_id = auth.uid())
        )
    );

-- Nudge history - users can only access their own
CREATE POLICY "Users can manage own nudge history"
    ON nudge_history FOR ALL
    USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- GRANTS
-- ═══════════════════════════════════════════════════════════════════════════

GRANT SELECT, INSERT, UPDATE ON couple_game_history TO authenticated;
GRANT SELECT ON relationship_metrics TO authenticated;
GRANT SELECT, INSERT, UPDATE ON nudge_history TO authenticated;
