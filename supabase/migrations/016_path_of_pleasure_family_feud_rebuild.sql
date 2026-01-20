-- ════════════════════════════════════════════════════════════════════════════
-- PATH OF PLEASURE - FAMILY FEUD REBUILD
-- TAG Engine Phase 4 v2
-- "Survey Says..." meets intimate discovery
-- ════════════════════════════════════════════════════════════════════════════
-- 
-- GAME CONCEPT:
-- - Players are shown intimate scenarios (holding hands → explicit acts)
-- - They RANK them by PREDICTED POPULARITY (what do most people like?)
-- - Scoring is based on how well your rankings match GLOBAL popularity
-- - Global rankings update nightly based on all player votes
-- - Cards move up/down in popularity each week
--
-- Example: "Kissing in Public" might be #44 this week, #88 next week
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 1: Add popularity tracking columns to existing pop_cards table
-- ═══════════════════════════════════════════════════════════════════════════

-- Global popularity rank (1 = most popular, 100 = least)
ALTER TABLE pop_cards ADD COLUMN IF NOT EXISTS global_rank INTEGER DEFAULT 50;

-- Total votes received (for calculating popularity)
ALTER TABLE pop_cards ADD COLUMN IF NOT EXISTS total_votes INTEGER DEFAULT 0;

-- Sum of all position votes (lower = more popular)
-- Average = vote_sum / total_votes
ALTER TABLE pop_cards ADD COLUMN IF NOT EXISTS vote_sum BIGINT DEFAULT 0;

-- Popularity score (0-100, higher = more popular)
ALTER TABLE pop_cards ADD COLUMN IF NOT EXISTS popularity_score DECIMAL(5,2) DEFAULT 50.00;

-- Last time rankings were recalculated
ALTER TABLE pop_cards ADD COLUMN IF NOT EXISTS last_ranked_at TIMESTAMPTZ;

-- Week-over-week rank change for UI display
ALTER TABLE pop_cards ADD COLUMN IF NOT EXISTS rank_change INTEGER DEFAULT 0;

-- Index for popularity queries
CREATE INDEX IF NOT EXISTS idx_pop_cards_global_rank ON pop_cards(global_rank);
CREATE INDEX IF NOT EXISTS idx_pop_cards_popularity ON pop_cards(popularity_score DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 2: Create vote history table (for tracking individual votes)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES pop_cards(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  session_id UUID REFERENCES pop_sessions(id) ON DELETE SET NULL,
  -- Position player ranked this card (1 = top/most popular, 5 = bottom)
  vote_position INTEGER NOT NULL CHECK (vote_position BETWEEN 1 AND 10),
  -- Was this a correct guess? (matched global within threshold)
  was_correct BOOLEAN,
  -- Points earned for this vote
  points_earned INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pop_votes_card ON pop_votes(card_id);
CREATE INDEX IF NOT EXISTS idx_pop_votes_user ON pop_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_pop_votes_session ON pop_votes(session_id);
CREATE INDEX IF NOT EXISTS idx_pop_votes_created ON pop_votes(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 3: Create popularity history table (track changes over time)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_rank_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES pop_cards(id) ON DELETE CASCADE,
  rank_position INTEGER NOT NULL,
  popularity_score DECIMAL(5,2) NOT NULL,
  total_votes_snapshot INTEGER NOT NULL,
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Period identifier (e.g., '2026-W03' for week 3)
  period TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pop_rank_history_card ON pop_rank_history(card_id);
CREATE INDEX IF NOT EXISTS idx_pop_rank_history_period ON pop_rank_history(period);

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 4: Update pop_sessions for Family Feud mode
-- ═══════════════════════════════════════════════════════════════════════════

-- Add new columns for Family Feud style gameplay
ALTER TABLE pop_sessions ADD COLUMN IF NOT EXISTS game_mode TEXT DEFAULT 'family_feud'
  CHECK (game_mode IN ('family_feud', 'compatibility', 'speed_round'));

-- Cards shown in current round (5 cards to rank by popularity)
ALTER TABLE pop_sessions ADD COLUMN IF NOT EXISTS round_cards UUID[] DEFAULT '{}';

-- Team scores (for team mode)
ALTER TABLE pop_sessions ADD COLUMN IF NOT EXISTS team_scores JSONB DEFAULT '{}';

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 5: Update pop_players for scoring
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE pop_players ADD COLUMN IF NOT EXISTS score INTEGER DEFAULT 0;
ALTER TABLE pop_players ADD COLUMN IF NOT EXISTS correct_guesses INTEGER DEFAULT 0;
ALTER TABLE pop_players ADD COLUMN IF NOT EXISTS total_guesses INTEGER DEFAULT 0;
ALTER TABLE pop_players ADD COLUMN IF NOT EXISTS streak INTEGER DEFAULT 0;
ALTER TABLE pop_players ADD COLUMN IF NOT EXISTS best_streak INTEGER DEFAULT 0;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 6: Create round submissions table (player's rankings per round)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_round_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES pop_sessions(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES pop_players(id) ON DELETE CASCADE,
  round_number INTEGER NOT NULL,
  -- Player's ranking of cards (JSON array of card_ids in order)
  submitted_ranking UUID[] NOT NULL,
  -- Score for this round
  round_score INTEGER DEFAULT 0,
  -- Number of cards in correct position
  correct_positions INTEGER DEFAULT 0,
  -- Number of cards within 1 position
  close_positions INTEGER DEFAULT 0,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, player_id, round_number)
);

CREATE INDEX IF NOT EXISTS idx_pop_submissions_session ON pop_round_submissions(session_id);
CREATE INDEX IF NOT EXISTS idx_pop_submissions_player ON pop_round_submissions(player_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 7: Functions for game logic
-- ═══════════════════════════════════════════════════════════════════════════

-- Get 5 random cards for a round, weighted by heat level and activity
CREATE OR REPLACE FUNCTION get_pop_round_cards_v2(
  p_heat_level INTEGER DEFAULT 2,
  p_count INTEGER DEFAULT 5
)
RETURNS TABLE (
  id UUID,
  text TEXT,
  category TEXT,
  subcategory TEXT,
  heat_level INTEGER,
  global_rank INTEGER,
  popularity_score DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.text,
    c.category,
    c.subcategory,
    c.heat_level,
    c.global_rank,
    c.popularity_score
  FROM pop_cards c
  WHERE c.is_active = true
  AND c.heat_level <= p_heat_level
  ORDER BY random()
  LIMIT p_count;
END;
$$ LANGUAGE plpgsql;

-- Calculate score for a player's ranking vs global ranking
CREATE OR REPLACE FUNCTION calculate_pop_round_score(
  p_submitted_ranking UUID[],
  p_session_id UUID,
  p_player_id UUID,
  p_round_number INTEGER
)
RETURNS TABLE (
  total_score INTEGER,
  correct_count INTEGER,
  close_count INTEGER
) AS $$
DECLARE
  v_card_id UUID;
  v_player_position INTEGER;
  v_actual_rank INTEGER;
  v_score INTEGER := 0;
  v_correct INTEGER := 0;
  v_close INTEGER := 0;
  v_card_count INTEGER;
  v_sorted_cards UUID[];
  v_points INTEGER;
BEGIN
  v_card_count := array_length(p_submitted_ranking, 1);
  
  -- Get the actual order (sorted by global_rank)
  SELECT array_agg(c.id ORDER BY c.global_rank ASC)
  INTO v_sorted_cards
  FROM pop_cards c
  WHERE c.id = ANY(p_submitted_ranking);
  
  -- Compare player's ranking to actual
  FOR v_player_position IN 1..v_card_count LOOP
    v_card_id := p_submitted_ranking[v_player_position];
    
    -- Find actual position in sorted array
    FOR v_actual_rank IN 1..v_card_count LOOP
      IF v_sorted_cards[v_actual_rank] = v_card_id THEN
        EXIT;
      END IF;
    END LOOP;
    
    -- Scoring logic
    IF v_player_position = v_actual_rank THEN
      -- Exact match! 
      v_correct := v_correct + 1;
      v_points := 100;
      
      -- Record vote
      INSERT INTO pop_votes (card_id, user_id, session_id, vote_position, was_correct, points_earned)
      SELECT v_card_id, u.user_id, p_session_id, v_player_position, true, v_points
      FROM pop_players u WHERE u.id = p_player_id;
      
    ELSIF abs(v_player_position - v_actual_rank) = 1 THEN
      -- One off
      v_close := v_close + 1;
      v_points := 50;
      
      INSERT INTO pop_votes (card_id, user_id, session_id, vote_position, was_correct, points_earned)
      SELECT v_card_id, u.user_id, p_session_id, v_player_position, false, v_points
      FROM pop_players u WHERE u.id = p_player_id;
      
    ELSIF abs(v_player_position - v_actual_rank) = 2 THEN
      -- Two off
      v_points := 25;
      
      INSERT INTO pop_votes (card_id, user_id, session_id, vote_position, was_correct, points_earned)
      SELECT v_card_id, u.user_id, p_session_id, v_player_position, false, v_points
      FROM pop_players u WHERE u.id = p_player_id;
    ELSE
      v_points := 0;
      
      INSERT INTO pop_votes (card_id, user_id, session_id, vote_position, was_correct, points_earned)
      SELECT v_card_id, u.user_id, p_session_id, v_player_position, false, 0
      FROM pop_players u WHERE u.id = p_player_id;
    END IF;
    
    v_score := v_score + v_points;
    
    -- Update card vote totals (for nightly recalculation)
    UPDATE pop_cards 
    SET total_votes = total_votes + 1,
        vote_sum = vote_sum + v_player_position
    WHERE id = v_card_id;
    
  END LOOP;
  
  -- Store submission
  INSERT INTO pop_round_submissions (session_id, player_id, round_number, submitted_ranking, round_score, correct_positions, close_positions)
  VALUES (p_session_id, p_player_id, p_round_number, p_submitted_ranking, v_score, v_correct, v_close)
  ON CONFLICT (session_id, player_id, round_number) 
  DO UPDATE SET 
    submitted_ranking = p_submitted_ranking,
    round_score = v_score,
    correct_positions = v_correct,
    close_positions = v_close,
    submitted_at = NOW();
  
  -- Update player score
  UPDATE pop_players
  SET score = score + v_score,
      correct_guesses = correct_guesses + v_correct,
      total_guesses = total_guesses + v_card_count
  WHERE id = p_player_id;
  
  total_score := v_score;
  correct_count := v_correct;
  close_count := v_close;
  
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Nightly job: Recalculate global rankings based on all votes
CREATE OR REPLACE FUNCTION recalculate_pop_global_rankings()
RETURNS void AS $$
DECLARE
  v_period TEXT;
  v_card RECORD;
  v_rank INTEGER := 0;
  v_prev_score DECIMAL;
BEGIN
  v_period := to_char(NOW(), 'IYYY-"W"IW'); -- ISO week format
  
  -- Calculate new popularity scores
  -- Lower average vote position = more popular
  FOR v_card IN (
    SELECT 
      id,
      CASE 
        WHEN total_votes > 0 THEN 
          100 - ((vote_sum::decimal / total_votes::decimal - 1) / 4 * 100)
        ELSE 50 
      END as new_score,
      global_rank as old_rank
    FROM pop_cards
    WHERE is_active = true
    ORDER BY 
      CASE WHEN total_votes > 0 THEN vote_sum::decimal / total_votes::decimal ELSE 999 END ASC
  ) LOOP
    v_rank := v_rank + 1;
    
    -- Update card with new rank
    UPDATE pop_cards
    SET 
      global_rank = v_rank,
      popularity_score = v_card.new_score,
      rank_change = v_card.old_rank - v_rank,
      last_ranked_at = NOW()
    WHERE id = v_card.id;
    
    -- Store in history
    INSERT INTO pop_rank_history (card_id, rank_position, popularity_score, total_votes_snapshot, period)
    SELECT v_card.id, v_rank, v_card.new_score, total_votes, v_period
    FROM pop_cards WHERE id = v_card.id;
    
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 8: RLS Policies for new tables
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE pop_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pop_rank_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE pop_round_submissions ENABLE ROW LEVEL SECURITY;

-- Votes: Users can see their own, insert their own
CREATE POLICY "pop_votes_own_read" ON pop_votes
  FOR SELECT USING (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "pop_votes_insert" ON pop_votes
  FOR INSERT WITH CHECK (true); -- Controlled via functions

-- Rank history: Anyone can read (public data)
CREATE POLICY "pop_rank_history_read" ON pop_rank_history
  FOR SELECT USING (true);

-- Round submissions: Players in session can see
CREATE POLICY "pop_submissions_read" ON pop_round_submissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pop_players
      WHERE pop_players.session_id = pop_round_submissions.session_id
      AND pop_players.user_id = auth.uid()
    )
  );

CREATE POLICY "pop_submissions_insert" ON pop_round_submissions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM pop_players
      WHERE pop_players.id = pop_round_submissions.player_id
      AND pop_players.user_id = auth.uid()
    )
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 9: Add more diverse cards (full range from innocent to explicit)
-- ═══════════════════════════════════════════════════════════════════════════

-- More vanilla (innocent/sweet)
INSERT INTO pop_cards (text, category, subcategory, heat_level, global_rank) VALUES
('Holding hands while walking', 'vanilla', 'touch', 1, 5),
('Forehead kisses', 'vanilla', 'intimacy', 1, 3),
('Hugging from behind', 'vanilla', 'touch', 1, 8),
('Playing with each other''s hair', 'vanilla', 'touch', 1, 15),
('Falling asleep on their chest', 'vanilla', 'intimacy', 1, 6),
('Cooking together', 'vanilla', 'romance', 1, 12),
('Leaving surprise notes', 'vanilla', 'romance', 1, 22),
('Stargazing together', 'vanilla', 'romance', 1, 28),
('Sharing a blanket on the couch', 'vanilla', 'intimacy', 1, 10),
('First date butterflies', 'vanilla', 'romance', 1, 18)
ON CONFLICT DO NOTHING;

-- More spicy (suggestive/sensual)
INSERT INTO pop_cards (text, category, subcategory, heat_level, global_rank) VALUES
('Neck kisses that linger', 'spicy', 'intimacy', 2, 7),
('Leaving hickeys', 'spicy', 'marking', 2, 35),
('Making out in the car', 'spicy', 'public', 2, 25),
('Sending nudes', 'spicy', 'digital', 3, 42),
('Receiving nudes', 'spicy', 'digital', 3, 38),
('Strip teases', 'spicy', 'performance', 3, 48),
('Whispering dirty things in public', 'spicy', 'verbal', 3, 45),
('Light spanking', 'spicy', 'impact', 3, 40),
('Hair pulling', 'spicy', 'power', 3, 32),
('Being pinned against a wall', 'spicy', 'power', 3, 20)
ON CONFLICT DO NOTHING;

-- Edgy (explicit/kinky)
INSERT INTO pop_cards (text, category, subcategory, heat_level, global_rank) VALUES
('Oral sex (giving)', 'edgy', 'oral', 4, 14),
('Oral sex (receiving)', 'edgy', 'oral', 4, 9),
('69 position', 'edgy', 'oral', 4, 55),
('Sex in the shower', 'edgy', 'location', 4, 16),
('Morning quickie', 'edgy', 'timing', 4, 11),
('All night session', 'edgy', 'stamina', 4, 30),
('Choking (light/consensual)', 'edgy', 'breath', 5, 58),
('Anal play (fingers)', 'edgy', 'anal', 5, 62),
('Anal sex', 'edgy', 'anal', 5, 68),
('Rough sex', 'edgy', 'intensity', 5, 33),
('Bondage (tied up)', 'edgy', 'bondage', 5, 52),
('Threesome fantasy', 'edgy', 'group', 5, 72),
('Actual threesome', 'edgy', 'group', 5, 85),
('Role play scenarios', 'edgy', 'roleplay', 4, 47),
('Sex in public place', 'edgy', 'risk', 5, 75),
('Exhibitionism', 'edgy', 'voyeur', 5, 80),
('Voyeurism', 'edgy', 'voyeur', 5, 78),
('Using vibrators together', 'edgy', 'toys', 4, 26),
('Using plugs', 'edgy', 'toys', 5, 65),
('Double penetration fantasy', 'edgy', 'group', 5, 88)
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 10: Enable realtime for new tables
-- ═══════════════════════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE pop_votes;
ALTER PUBLICATION supabase_realtime ADD TABLE pop_round_submissions;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 11: Create view for leaderboard
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW pop_leaderboard AS
SELECT 
  p.user_id,
  pr.display_name,
  pr.avatar_url,
  SUM(p.score) as total_score,
  SUM(p.correct_guesses) as total_correct,
  SUM(p.total_guesses) as total_attempts,
  COUNT(DISTINCT p.session_id) as games_played,
  ROUND(SUM(p.correct_guesses)::decimal / NULLIF(SUM(p.total_guesses), 0) * 100, 1) as accuracy_percent
FROM pop_players p
JOIN profiles pr ON pr.user_id = p.user_id
GROUP BY p.user_id, pr.display_name, pr.avatar_url
ORDER BY total_score DESC;

-- Grant access
GRANT SELECT ON pop_leaderboard TO authenticated;

