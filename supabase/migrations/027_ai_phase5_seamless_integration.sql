-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 5: SEAMLESS INTEGRATION - Database Schema
-- ════════════════════════════════════════════════════════════════════════════
-- 
-- Tables for:
-- - Dynamic game generation (couple context, favorites)
-- - Predictive matching (signals, outcomes, learned weights)
-- - Ambient intelligence (usage patterns, personalization)
--
-- Design principle: Collect data invisibly, improve experience noticeably

-- Ensure uuid-ossp extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ═══════════════════════════════════════════════════════════════════════════
-- DYNAMIC GAME GENERATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Couple dynamics learned over time
CREATE TABLE IF NOT EXISTS couple_dynamics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  
  -- Learned dynamic
  dynamic_type TEXT DEFAULT 'balanced', -- playful, deep, flirty, balanced
  confidence DECIMAL(3,2) DEFAULT 0.5,
  
  -- Conversation themes detected
  themes TEXT[] DEFAULT '{}',
  
  -- Favorite prompt categories
  favorite_categories TEXT[] DEFAULT '{}',
  avoided_topics TEXT[] DEFAULT '{}',
  
  -- Stats
  games_played INT DEFAULT 0,
  prompts_loved INT DEFAULT 0,
  prompts_skipped INT DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(match_id)
);

-- Generated prompts history (for avoiding repeats)
CREATE TABLE IF NOT EXISTS generated_prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  
  game_type TEXT NOT NULL,
  prompt_text TEXT NOT NULL,
  heat_level INT DEFAULT 2,
  is_personalized BOOLEAN DEFAULT true,
  based_on TEXT, -- What this was personalized from
  
  -- User reaction
  reaction TEXT, -- loved, liked, skipped, disliked
  
  shown_at TIMESTAMPTZ DEFAULT NOW(),
  reacted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_generated_prompts_match 
  ON generated_prompts(match_id, game_type);
CREATE INDEX IF NOT EXISTS idx_generated_prompts_reaction 
  ON generated_prompts(match_id, reaction);

-- ═══════════════════════════════════════════════════════════════════════════
-- PREDICTIVE MATCHING
-- ═══════════════════════════════════════════════════════════════════════════

-- Match outcomes for learning
CREATE TABLE IF NOT EXISTS match_outcomes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  
  -- Outcome progression
  outcome TEXT NOT NULL, -- no_engagement, short_conversation, long_conversation, date_planned, date_completed, relationship
  
  -- Signals at time of match (for learning)
  signals_snapshot JSONB,
  
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(match_id, outcome)
);

CREATE INDEX IF NOT EXISTS idx_match_outcomes_outcome 
  ON match_outcomes(outcome);

-- Learned matching weights (updated by background job)
CREATE TABLE IF NOT EXISTS ai_matching_weights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  factor TEXT NOT NULL UNIQUE, -- shared_interests, communication_style, etc.
  weight DECIMAL(4,3) DEFAULT 0.1,
  
  -- Confidence in this weight
  sample_size INT DEFAULT 0,
  confidence DECIMAL(3,2) DEFAULT 0.5,
  
  -- When this weight was last recalculated
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  
  notes TEXT
);

-- Insert default weights
INSERT INTO ai_matching_weights (factor, weight, notes) VALUES
  ('shared_interests', 0.15, 'Boost for 3+ shared interests'),
  ('communication_style', 0.10, 'Similar writing style/length'),
  ('activity_overlap', 0.08, 'Similar active hours'),
  ('response_frequency', 0.07, 'Similar messaging pace'),
  ('attachment_compatibility', 0.12, 'Compatible emotional styles'),
  ('ambition_match', 0.08, 'Similar drive levels'),
  ('social_energy', 0.06, 'Intro/extro compatibility'),
  ('goal_alignment', 0.15, 'Looking for same thing')
ON CONFLICT (factor) DO NOTHING;

-- User compatibility signals cache
CREATE TABLE IF NOT EXISTS user_compatibility_cache (
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  other_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  score DECIMAL(4,3) NOT NULL,
  signals JSONB NOT NULL,
  explanation TEXT,
  top_reasons TEXT[],
  
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
  
  PRIMARY KEY (user_id, other_user_id)
);

CREATE INDEX IF NOT EXISTS idx_compatibility_cache_expiry 
  ON user_compatibility_cache(expires_at);

-- ═══════════════════════════════════════════════════════════════════════════
-- AMBIENT INTELLIGENCE
-- ═══════════════════════════════════════════════════════════════════════════

-- User usage patterns (aggregated)
CREATE TABLE IF NOT EXISTS user_patterns (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Feature usage counts
  feature_usage JSONB DEFAULT '{}',
  
  -- Last used timestamps
  last_used JSONB DEFAULT '{}',
  
  -- Learned preferences/defaults
  learned_defaults JSONB DEFAULT '{}',
  
  -- Activity stats
  days_active INT DEFAULT 0,
  last_active_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Preferred hours (for suggestions)
  active_hours INT[] DEFAULT '{}',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Raw usage events (for batch processing)
CREATE TABLE IF NOT EXISTS usage_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  feature_id TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB,
  
  -- Partitioning helper
  event_date DATE DEFAULT CURRENT_DATE
);

CREATE INDEX IF NOT EXISTS idx_usage_events_user_date 
  ON usage_events(user_id, event_date);
CREATE INDEX IF NOT EXISTS idx_usage_events_feature 
  ON usage_events(feature_id, timestamp);

-- UI personalization settings
CREATE TABLE IF NOT EXISTS ui_personalization (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Quick actions on home screen
  quick_actions TEXT[] DEFAULT '{"matches", "discover", "games", "messages"}',
  
  -- Tab order
  tab_order TEXT[] DEFAULT '{"home", "discover", "matches", "games", "profile"}',
  
  -- Hidden features
  hidden_features TEXT[] DEFAULT '{}',
  
  -- Minimized features
  minimized_features TEXT[] DEFAULT '{}',
  
  -- Theme/display preferences (learned)
  display_preferences JSONB DEFAULT '{}',
  
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- BACKGROUND JOBS TRACKING
-- ═══════════════════════════════════════════════════════════════════════════

-- Track AI learning jobs
CREATE TABLE IF NOT EXISTS ai_learning_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  job_type TEXT NOT NULL, -- weight_recalculation, pattern_aggregation, cache_refresh
  status TEXT DEFAULT 'pending', -- pending, running, completed, failed
  
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  
  records_processed INT DEFAULT 0,
  error_message TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_jobs_status 
  ON ai_learning_jobs(status, created_at);

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE couple_dynamics ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_outcomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE ui_personalization ENABLE ROW LEVEL SECURITY;

-- Users can read their own couple dynamics (through matches they're part of)
CREATE POLICY couple_dynamics_select ON couple_dynamics
  FOR SELECT USING (
    match_id IN (
      SELECT id FROM matches 
      WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
    )
  );

-- Users can read/write their own patterns
CREATE POLICY user_patterns_all ON user_patterns
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY usage_events_insert ON usage_events
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY usage_events_select ON usage_events
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY ui_personalization_all ON ui_personalization
  FOR ALL USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Function to update couple dynamics after game play
CREATE OR REPLACE FUNCTION update_couple_dynamics_on_game()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO couple_dynamics (match_id, games_played)
  VALUES (NEW.match_id, 1)
  ON CONFLICT (match_id) DO UPDATE SET
    games_played = couple_dynamics.games_played + 1,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to aggregate user patterns nightly
CREATE OR REPLACE FUNCTION aggregate_user_patterns()
RETURNS void AS $$
DECLARE
  user_record RECORD;
BEGIN
  FOR user_record IN 
    SELECT DISTINCT user_id FROM usage_events 
    WHERE event_date >= CURRENT_DATE - INTERVAL '1 day'
  LOOP
    -- Aggregate feature usage
    UPDATE user_patterns
    SET 
      feature_usage = (
        SELECT jsonb_object_agg(feature_id, cnt)
        FROM (
          SELECT feature_id, COUNT(*) as cnt
          FROM usage_events
          WHERE user_id = user_record.user_id
          GROUP BY feature_id
        ) sub
      ),
      days_active = days_active + 1,
      last_active_at = NOW(),
      updated_at = NOW()
    WHERE user_id = user_record.user_id;
    
    -- Insert if not exists
    INSERT INTO user_patterns (user_id, days_active)
    VALUES (user_record.user_id, 1)
    ON CONFLICT (user_id) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP OLD DATA (for partition maintenance)
-- ═══════════════════════════════════════════════════════════════════════════

-- Delete usage events older than 30 days
CREATE OR REPLACE FUNCTION cleanup_old_usage_events()
RETURNS void AS $$
BEGIN
  DELETE FROM usage_events
  WHERE event_date < CURRENT_DATE - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Delete expired compatibility cache
CREATE OR REPLACE FUNCTION cleanup_compatibility_cache()
RETURNS void AS $$
BEGIN
  DELETE FROM user_compatibility_cache
  WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;
