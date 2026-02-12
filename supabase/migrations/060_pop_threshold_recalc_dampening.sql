-- ════════════════════════════════════════════════════════════════════════════
-- PATH OF PLEASURE - THRESHOLD-BASED RECALCULATION & RANK DAMPENING
-- ════════════════════════════════════════════════════════════════════════════
--
-- PROBLEM: Old system recalculated on a nightly schedule, meaning a single
-- player could cause cards to jump from rank 99 to rank 3 after one game.
--
-- FIX:
--   1. Recalculation only triggers after enough NEW votes accumulate
--      (configurable threshold, default = 50 new votes since last recalc)
--   2. Cards can only move ±MAX_RANK_SHIFT positions per recalc cycle
--      (default = 3) so rankings drift gradually, not teleport
--   3. Cards need a minimum vote count before their rank departs from seed
--      (default = 10 total votes on a card before it can be re-ranked)
--   4. No more cron dependency — the submit-votes RPC auto-triggers recalc
--      when the threshold is crossed
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 1: Recalculation state tracker
-- Tracks how many NEW votes have come in since the last recalculation
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_recalc_state (
  id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1), -- singleton row
  votes_since_last_recalc INTEGER DEFAULT 0,
  last_recalc_at TIMESTAMPTZ,
  last_recalc_result JSONB,
  -- Tuning knobs
  recalc_vote_threshold INTEGER DEFAULT 50,   -- recalc after this many new votes
  max_rank_shift INTEGER DEFAULT 3,           -- max positions a card can move per cycle
  min_votes_to_rerank INTEGER DEFAULT 10,     -- card needs this many total votes before rank moves
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed the singleton row
INSERT INTO pop_recalc_state (id, votes_since_last_recalc, last_recalc_at)
VALUES (1, 0, NOW())
ON CONFLICT (id) DO NOTHING;

ALTER TABLE pop_recalc_state ENABLE ROW LEVEL SECURITY;

-- Anyone can read config (cards display rank_change in UI)
CREATE POLICY "pop_recalc_state_read" ON pop_recalc_state
  FOR SELECT USING (true);

-- Only service_role can modify
CREATE POLICY "pop_recalc_state_update" ON pop_recalc_state
  FOR UPDATE USING (auth.role() = 'service_role');

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 2: Replace recalculate_pop_global_rankings with dampened version
-- ═══════════════════════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS recalculate_pop_global_rankings();

CREATE OR REPLACE FUNCTION recalculate_pop_global_rankings()
RETURNS JSONB AS $$
DECLARE
  v_period TEXT;
  v_card RECORD;
  v_ideal_rank INTEGER := 0;  -- where data says the card SHOULD be
  v_new_rank INTEGER;          -- clamped rank after dampening
  v_total_cards INTEGER := 0;
  v_total_votes_processed BIGINT := 0;
  v_matchup RECORD;
  v_matchup_entry JSONB;
  v_less_kinky_id UUID;
  v_more_kinky_id UUID;
  v_max_shift INTEGER;
  v_min_votes INTEGER;
  v_result JSONB;
BEGIN
  v_period := to_char(NOW(), 'IYYY-"W"IW');

  -- Read tuning knobs
  SELECT max_rank_shift, min_votes_to_rerank
  INTO v_max_shift, v_min_votes
  FROM pop_recalc_state WHERE id = 1;

  -- Defaults if row is missing
  v_max_shift := COALESCE(v_max_shift, 3);
  v_min_votes := COALESCE(v_min_votes, 10);

  -- ── Part A: Process Elo matchups from pop_elo_matchups ──
  FOR v_matchup IN (
    SELECT id, matchups
    FROM pop_elo_matchups
    WHERE created_at > NOW() - interval '30 days'
    ORDER BY created_at ASC
  ) LOOP
    IF v_matchup.matchups IS NOT NULL AND jsonb_array_length(v_matchup.matchups) > 0 THEN
      FOR v_matchup_entry IN SELECT * FROM jsonb_array_elements(v_matchup.matchups)
      LOOP
        v_less_kinky_id := (v_matchup_entry->>'less_kinky_id')::UUID;
        v_more_kinky_id := (v_matchup_entry->>'more_kinky_id')::UUID;

        UPDATE pop_cards
        SET vote_sum = COALESCE(vote_sum, 0) + 1,
            total_votes = COALESCE(total_votes, 0) + 1
        WHERE id = v_more_kinky_id;
      END LOOP;
    END IF;
  END LOOP;

  -- ── Part B: Compute ideal ranks (where data says cards should go) ──
  -- We iterate cards sorted by their average vote position (lower = more popular)
  -- but we only MOVE cards that have enough votes, and we clamp the movement
  FOR v_card IN (
    SELECT
      c.id,
      c.total_votes as votes,
      c.global_rank as old_rank,
      CASE
        WHEN c.total_votes > 0 THEN
          100 - ((c.vote_sum::decimal / c.total_votes::decimal - 1) / 9 * 100)
        ELSE 50
      END as new_score
    FROM pop_cards c
    WHERE c.is_active = true
    ORDER BY
      CASE WHEN c.total_votes > 0 THEN c.vote_sum::decimal / c.total_votes::decimal ELSE 999 END ASC
  ) LOOP
    v_ideal_rank := v_ideal_rank + 1;
    v_total_cards := v_total_cards + 1;
    v_total_votes_processed := v_total_votes_processed + COALESCE(v_card.votes, 0);

    -- ── Dampening logic ──
    IF COALESCE(v_card.votes, 0) < v_min_votes THEN
      -- Not enough data yet — keep existing rank, don't move at all
      v_new_rank := COALESCE(v_card.old_rank, v_ideal_rank);
    ELSE
      -- Enough votes: clamp movement to ±max_shift per cycle
      v_new_rank := COALESCE(v_card.old_rank, v_ideal_rank);

      IF v_ideal_rank < v_new_rank THEN
        -- Card wants to move UP (lower rank number = more popular)
        v_new_rank := GREATEST(v_ideal_rank, v_new_rank - v_max_shift);
      ELSIF v_ideal_rank > v_new_rank THEN
        -- Card wants to move DOWN
        v_new_rank := LEAST(v_ideal_rank, v_new_rank + v_max_shift);
      END IF;
      -- If ideal == current, no change
    END IF;

    UPDATE pop_cards
    SET
      global_rank = v_new_rank,
      popularity_score = GREATEST(0, LEAST(100, v_card.new_score)),
      rank_change = COALESCE(v_card.old_rank, v_new_rank) - v_new_rank,
      last_ranked_at = NOW()
    WHERE id = v_card.id;

    -- Store history snapshot
    INSERT INTO pop_rank_history (card_id, rank_position, popularity_score, total_votes_snapshot, period)
    VALUES (v_card.id, v_new_rank, GREATEST(0, LEAST(100, v_card.new_score)), COALESCE(v_card.votes, 0), v_period)
    ON CONFLICT DO NOTHING;
  END LOOP;

  -- Reset the vote counter
  UPDATE pop_recalc_state
  SET votes_since_last_recalc = 0,
      last_recalc_at = NOW(),
      last_recalc_result = jsonb_build_object(
        'cards_ranked', v_total_cards,
        'total_votes_in_system', v_total_votes_processed,
        'max_shift_applied', v_max_shift,
        'min_votes_required', v_min_votes
      )
  WHERE id = 1;

  v_result := jsonb_build_object(
    'success', true,
    'period', v_period,
    'cards_ranked', v_total_cards,
    'total_votes_in_system', v_total_votes_processed,
    'max_shift_per_card', v_max_shift,
    'min_votes_to_move', v_min_votes,
    'ranked_at', NOW()
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION recalculate_pop_global_rankings TO service_role;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 3: Replace pop_submit_round_votes to auto-trigger recalc at threshold
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
  v_votes_pending INTEGER;
  v_threshold INTEGER;
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
      false,
      0
    );

    -- Update card vote totals
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

  -- ── Increment pending vote counter and check threshold ──
  UPDATE pop_recalc_state
  SET votes_since_last_recalc = votes_since_last_recalc + v_count
  WHERE id = 1;

  SELECT votes_since_last_recalc, recalc_vote_threshold
  INTO v_votes_pending, v_threshold
  FROM pop_recalc_state WHERE id = 1;

  -- Auto-trigger recalculation when threshold is crossed
  IF v_votes_pending >= v_threshold THEN
    PERFORM recalculate_pop_global_rankings();
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- STEP 4: Admin helper to adjust tuning knobs without migrations
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION pop_update_recalc_config(
  p_vote_threshold INTEGER DEFAULT NULL,
  p_max_rank_shift INTEGER DEFAULT NULL,
  p_min_votes_to_rerank INTEGER DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  UPDATE pop_recalc_state
  SET
    recalc_vote_threshold = COALESCE(p_vote_threshold, recalc_vote_threshold),
    max_rank_shift = COALESCE(p_max_rank_shift, max_rank_shift),
    min_votes_to_rerank = COALESCE(p_min_votes_to_rerank, min_votes_to_rerank)
  WHERE id = 1;

  SELECT jsonb_build_object(
    'recalc_vote_threshold', recalc_vote_threshold,
    'max_rank_shift', max_rank_shift,
    'min_votes_to_rerank', min_votes_to_rerank,
    'votes_since_last_recalc', votes_since_last_recalc,
    'last_recalc_at', last_recalc_at
  ) INTO v_result
  FROM pop_recalc_state WHERE id = 1;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION pop_update_recalc_config TO service_role;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
