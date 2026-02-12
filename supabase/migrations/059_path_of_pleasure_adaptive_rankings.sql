-- ════════════════════════════════════════════════════════════════════════════
-- PATH OF PLEASURE - ADAPTIVE RANKINGS (Fix)
-- Connects the designed crowd-sourced ranking system end-to-end
-- ════════════════════════════════════════════════════════════════════════════
--
-- WHAT THIS FIXES:
-- 1. Creates the missing pop_elo_matchups table (client was inserting to it)
-- 2. Bootstraps initial global_rank values from hardcoded trueRank (1-200)
-- 3. Adds an RPC function the client can call to record votes + score
-- 4. Ensures recalculate_pop_global_rankings() is ready for cron/edge fn
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 1: Create the missing pop_elo_matchups table
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_elo_matchups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES pop_sessions(id) ON DELETE SET NULL,
  matchups JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pop_elo_matchups_session ON pop_elo_matchups(session_id);
CREATE INDEX IF NOT EXISTS idx_pop_elo_matchups_created ON pop_elo_matchups(created_at DESC);

ALTER TABLE pop_elo_matchups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pop_elo_matchups_insert" ON pop_elo_matchups
  FOR INSERT WITH CHECK (true);

CREATE POLICY "pop_elo_matchups_read" ON pop_elo_matchups
  FOR SELECT USING (true);

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 2: Bootstrap initial global_rank from seed data
-- Sets global_rank for all cards that still have default rank 50
-- Uses existing global_rank if it was set in seed INSERT, otherwise rownum
-- ═══════════════════════════════════════════════════════════════════════════

-- Assign sequential global_rank to all active cards that haven't been ranked
-- (Cards seeded in 016 already have non-50 global_rank values, leave those)
-- This ensures every card has a meaningful starting rank
DO $$
DECLARE
  v_rank INTEGER := 0;
  v_card RECORD;
BEGIN
  FOR v_card IN (
    SELECT id, global_rank
    FROM pop_cards
    WHERE is_active = true
    ORDER BY
      CASE WHEN global_rank IS NOT NULL AND global_rank != 50 THEN global_rank
           ELSE 9999
      END ASC,
      heat_level ASC,
      created_at ASC
  ) LOOP
    v_rank := v_rank + 1;
    UPDATE pop_cards SET global_rank = v_rank WHERE id = v_card.id;
  END LOOP;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 3: RPC function for client to submit a round and record votes
-- This is the bridge between client scoring and server-side vote tracking
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION pop_submit_round_votes(
  p_card_ids UUID[],
  p_submitted_positions INTEGER[],
  p_session_id UUID DEFAULT NULL
)
RETURNS TABLE (
  card_id UUID,
  submitted_position INTEGER,
  actual_global_rank INTEGER,
  delta INTEGER
) AS $$
DECLARE
  i INTEGER;
  v_card_id UUID;
  v_position INTEGER;
  v_count INTEGER;
BEGIN
  v_count := array_length(p_card_ids, 1);

  IF v_count IS NULL OR v_count != array_length(p_submitted_positions, 1) THEN
    RAISE EXCEPTION 'card_ids and submitted_positions must have the same length';
  END IF;

  FOR i IN 1..v_count LOOP
    v_card_id := p_card_ids[i];
    v_position := p_submitted_positions[i];

    -- Record vote in pop_votes
    INSERT INTO pop_votes (card_id, user_id, session_id, vote_position, was_correct, points_earned)
    VALUES (
      v_card_id,
      auth.uid(),
      p_session_id,
      v_position,
      false, -- will be updated below
      0
    );

    -- Update card vote totals for nightly recalculation
    UPDATE pop_cards
    SET total_votes = COALESCE(total_votes, 0) + 1,
        vote_sum = COALESCE(vote_sum, 0) + v_position
    WHERE id = v_card_id;

    -- Return the card's actual global rank so client can score
    RETURN QUERY
    SELECT
      v_card_id,
      v_position,
      COALESCE(c.global_rank, 50),
      abs(v_position - COALESCE(c.global_rank, 50))
    FROM pop_cards c
    WHERE c.id = v_card_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION pop_submit_round_votes TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 4: RPC to fetch active cards with current global rankings
-- Client calls this instead of using hardcoded list
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION pop_get_cards(
  p_count INTEGER DEFAULT 8,
  p_max_heat INTEGER DEFAULT 5
)
RETURNS TABLE (
  id UUID,
  text TEXT,
  category TEXT,
  subcategory TEXT,
  heat_level INTEGER,
  global_rank INTEGER,
  popularity_score DECIMAL,
  rank_change INTEGER,
  total_votes INTEGER
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
    c.popularity_score,
    c.rank_change,
    c.total_votes
  FROM pop_cards c
  WHERE c.is_active = true
    AND c.heat_level <= p_max_heat
  ORDER BY random()
  LIMIT p_count;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION pop_get_cards TO authenticated;
GRANT EXECUTE ON FUNCTION pop_get_cards TO anon;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 5: Improve recalculate_pop_global_rankings to also process Elo matchups
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop old function (returns void) so we can recreate with JSONB return type
DROP FUNCTION IF EXISTS recalculate_pop_global_rankings();

CREATE OR REPLACE FUNCTION recalculate_pop_global_rankings()
RETURNS JSONB AS $$
DECLARE
  v_period TEXT;
  v_card RECORD;
  v_rank INTEGER := 0;
  v_total_cards INTEGER := 0;
  v_total_votes_processed BIGINT := 0;
  v_matchup RECORD;
  v_matchup_entry JSONB;
  v_less_kinky_id UUID;
  v_more_kinky_id UUID;
  v_elo_k DECIMAL := 32; -- Elo K-factor
  v_elo_a DECIMAL;
  v_elo_b DECIMAL;
  v_expected_a DECIMAL;
  v_result JSONB;
BEGIN
  v_period := to_char(NOW(), 'IYYY-"W"IW');

  -- ── Part A: Process Elo matchups from pop_elo_matchups ──
  FOR v_matchup IN (
    SELECT id, matchups
    FROM pop_elo_matchups
    WHERE created_at > NOW() - interval '7 days'
    ORDER BY created_at ASC
  ) LOOP
    -- Each matchup row has an array of {less_kinky_id, more_kinky_id}
    IF v_matchup.matchups IS NOT NULL AND jsonb_array_length(v_matchup.matchups) > 0 THEN
      FOR v_matchup_entry IN SELECT * FROM jsonb_array_elements(v_matchup.matchups)
      LOOP
        v_less_kinky_id := (v_matchup_entry->>'less_kinky_id')::UUID;
        v_more_kinky_id := (v_matchup_entry->>'more_kinky_id')::UUID;

        -- Get current vote_sum as proxy Elo scores
        SELECT COALESCE(vote_sum, 0) INTO v_elo_a FROM pop_cards WHERE id = v_less_kinky_id;
        SELECT COALESCE(vote_sum, 0) INTO v_elo_b FROM pop_cards WHERE id = v_more_kinky_id;

        -- Elo: less_kinky wins (positioned lower = more vanilla = wins the vanilla side)
        -- This boosts vote_sum for more_kinky (making it rank lower in popularity = more hardcore)
        UPDATE pop_cards
        SET vote_sum = COALESCE(vote_sum, 0) + 1,
            total_votes = COALESCE(total_votes, 0) + 1
        WHERE id = v_more_kinky_id;
      END LOOP;
    END IF;
  END LOOP;

  -- ── Part B: Recalculate global rankings from accumulated votes ──
  FOR v_card IN (
    SELECT
      c.id,
      CASE
        WHEN c.total_votes > 0 THEN
          100 - ((c.vote_sum::decimal / c.total_votes::decimal - 1) / 9 * 100)
        ELSE 50
      END as new_score,
      c.global_rank as old_rank,
      c.total_votes as votes
    FROM pop_cards c
    WHERE c.is_active = true
    ORDER BY
      CASE WHEN c.total_votes > 0 THEN c.vote_sum::decimal / c.total_votes::decimal ELSE 999 END ASC
  ) LOOP
    v_rank := v_rank + 1;
    v_total_cards := v_total_cards + 1;
    v_total_votes_processed := v_total_votes_processed + COALESCE(v_card.votes, 0);

    UPDATE pop_cards
    SET
      global_rank = v_rank,
      popularity_score = GREATEST(0, LEAST(100, v_card.new_score)),
      rank_change = COALESCE(v_card.old_rank, v_rank) - v_rank,
      last_ranked_at = NOW()
    WHERE id = v_card.id;

    -- Store history snapshot
    INSERT INTO pop_rank_history (card_id, rank_position, popularity_score, total_votes_snapshot, period)
    SELECT v_card.id, v_rank, GREATEST(0, LEAST(100, v_card.new_score)), COALESCE(c.total_votes, 0), v_period
    FROM pop_cards c WHERE c.id = v_card.id
    ON CONFLICT DO NOTHING;
  END LOOP;

  v_result := jsonb_build_object(
    'success', true,
    'period', v_period,
    'cards_ranked', v_total_cards,
    'total_votes_in_system', v_total_votes_processed,
    'ranked_at', NOW()
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION recalculate_pop_global_rankings TO service_role;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 6: Enable realtime for new table
-- ═══════════════════════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE pop_elo_matchups;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
