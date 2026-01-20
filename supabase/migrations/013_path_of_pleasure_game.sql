-- ════════════════════════════════════════════════════════════════════════════
-- PATH OF PLEASURE - The Compatibility Engine
-- TAG Engine Phase 4
-- "Shit Happens" meets intimate discovery
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- CARD PROMPTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  text TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('vanilla', 'spicy', 'edgy')),
  subcategory TEXT, -- e.g., 'touch', 'roleplay', 'kink', 'public', 'power'
  heat_level INTEGER DEFAULT 1 CHECK (heat_level BETWEEN 1 AND 5),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for category-based queries
CREATE INDEX IF NOT EXISTS idx_pop_cards_category ON pop_cards(category);
CREATE INDEX IF NOT EXISTS idx_pop_cards_active ON pop_cards(is_active);

-- ═══════════════════════════════════════════════════════════════════════════
-- GAME SESSIONS TABLE (State Machine)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code TEXT NOT NULL UNIQUE,
  host_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  state TEXT NOT NULL DEFAULT 'LOBBY' CHECK (state IN ('LOBBY', 'SORTING', 'REVEAL', 'DISCUSSION', 'FINISHED')),
  current_round INTEGER DEFAULT 1,
  total_rounds INTEGER DEFAULT 3,
  -- Current round's cards (array of card IDs)
  current_cards UUID[] DEFAULT '{}',
  -- Timestamps for phase timing
  phase_started_at TIMESTAMPTZ,
  discussion_ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  finished_at TIMESTAMPTZ
);

-- Index for room code lookups
CREATE INDEX IF NOT EXISTS idx_pop_sessions_room_code ON pop_sessions(room_code);
CREATE INDEX IF NOT EXISTS idx_pop_sessions_state ON pop_sessions(state);
CREATE INDEX IF NOT EXISTS idx_pop_sessions_host ON pop_sessions(host_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- PLAYERS IN SESSION TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES pop_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  avatar_color TEXT DEFAULT '#4A9EFF',
  is_host BOOLEAN DEFAULT false,
  is_locked_in BOOLEAN DEFAULT false,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_pop_players_session ON pop_players(session_id);
CREATE INDEX IF NOT EXISTS idx_pop_players_user ON pop_players(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- PLAYER RANKINGS TABLE (Private until Reveal)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES pop_sessions(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES pop_players(id) ON DELETE CASCADE,
  card_id UUID NOT NULL REFERENCES pop_cards(id) ON DELETE CASCADE,
  round_number INTEGER NOT NULL,
  -- Ranking position: 0 = Craving (top), 4 = Limit (bottom)
  rank_position INTEGER NOT NULL CHECK (rank_position BETWEEN 0 AND 4),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, player_id, card_id, round_number)
);

CREATE INDEX IF NOT EXISTS idx_pop_rankings_session ON pop_rankings(session_id);
CREATE INDEX IF NOT EXISTS idx_pop_rankings_player ON pop_rankings(player_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- ROUND RESULTS TABLE (Calculated after reveal)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pop_round_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES pop_sessions(id) ON DELETE CASCADE,
  round_number INTEGER NOT NULL,
  card_id UUID NOT NULL REFERENCES pop_cards(id) ON DELETE CASCADE,
  card_text TEXT NOT NULL,
  -- Aggregated results
  is_golden_match BOOLEAN DEFAULT false,  -- All players in top 2
  is_friction_point BOOLEAN DEFAULT false, -- Delta >= 3 between any players
  max_delta INTEGER DEFAULT 0,
  rankings_json JSONB NOT NULL, -- {player_id: rank_position, ...}
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pop_round_results_session ON pop_round_results(session_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Generate unique room code (4 chars, memorable words)
CREATE OR REPLACE FUNCTION generate_pop_room_code()
RETURNS TEXT AS $$
DECLARE
  codes TEXT[] := ARRAY[
    'LUST', 'VIBE', 'AURA', 'GLOW', 'HEAT', 'FIRE', 'BURN', 'RUSH',
    'PEAK', 'KISS', 'SILK', 'MIST', 'WILD', 'DARE', 'EDGE', 'SYNC',
    'BOND', 'FLUX', 'WAVE', 'DEEP', 'PURE', 'FUSE', 'LINK', 'VOLT'
  ];
  base_code TEXT;
  final_code TEXT;
  suffix INTEGER;
BEGIN
  -- Pick a random word
  base_code := codes[1 + floor(random() * array_length(codes, 1))::int];
  
  -- Add 2-digit suffix for uniqueness
  suffix := floor(random() * 100)::int;
  final_code := base_code || lpad(suffix::text, 2, '0');
  
  -- Check if code exists in active sessions
  WHILE EXISTS (
    SELECT 1 FROM pop_sessions 
    WHERE room_code = final_code 
    AND state != 'FINISHED'
  ) LOOP
    suffix := floor(random() * 100)::int;
    base_code := codes[1 + floor(random() * array_length(codes, 1))::int];
    final_code := base_code || lpad(suffix::text, 2, '0');
  END LOOP;
  
  RETURN final_code;
END;
$$ LANGUAGE plpgsql;

-- Get cards for a specific round/category
CREATE OR REPLACE FUNCTION get_pop_round_cards(
  p_category TEXT,
  p_limit INTEGER DEFAULT 5
)
RETURNS SETOF pop_cards AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM pop_cards
  WHERE category = p_category
  AND is_active = true
  ORDER BY random()
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Calculate compatibility between players in a session
CREATE OR REPLACE FUNCTION calculate_pop_compatibility(p_session_id UUID)
RETURNS TABLE (
  overall_match_percent INTEGER,
  golden_matches INTEGER,
  friction_points INTEGER,
  sweet_spot TEXT,
  differ_on TEXT
) AS $$
DECLARE
  total_cards INTEGER;
  matches INTEGER := 0;
  frictions INTEGER := 0;
  sweet TEXT := 'Unknown';
  differ TEXT := 'Unknown';
BEGIN
  -- Count golden matches
  SELECT COUNT(*) INTO matches
  FROM pop_round_results
  WHERE session_id = p_session_id
  AND is_golden_match = true;
  
  -- Count friction points
  SELECT COUNT(*) INTO frictions
  FROM pop_round_results
  WHERE session_id = p_session_id
  AND is_friction_point = true;
  
  -- Total cards played
  SELECT COUNT(*) INTO total_cards
  FROM pop_round_results
  WHERE session_id = p_session_id;
  
  -- Calculate percentage (avoid division by zero)
  IF total_cards > 0 THEN
    overall_match_percent := ((total_cards - frictions)::float / total_cards * 100)::int;
  ELSE
    overall_match_percent := 0;
  END IF;
  
  golden_matches := matches;
  friction_points := frictions;
  
  -- Find sweet spot (most common subcategory in golden matches)
  SELECT COALESCE(c.subcategory, 'Intimacy') INTO sweet
  FROM pop_round_results rr
  JOIN pop_cards c ON c.id = rr.card_id
  WHERE rr.session_id = p_session_id
  AND rr.is_golden_match = true
  GROUP BY c.subcategory
  ORDER BY COUNT(*) DESC
  LIMIT 1;
  
  -- Find differ on (most common subcategory in friction points)
  SELECT COALESCE(c.subcategory, 'Adventure') INTO differ
  FROM pop_round_results rr
  JOIN pop_cards c ON c.id = rr.card_id
  WHERE rr.session_id = p_session_id
  AND rr.is_friction_point = true
  GROUP BY c.subcategory
  ORDER BY COUNT(*) DESC
  LIMIT 1;
  
  sweet_spot := sweet;
  differ_on := differ;
  
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE pop_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE pop_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pop_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE pop_rankings ENABLE ROW LEVEL SECURITY;
ALTER TABLE pop_round_results ENABLE ROW LEVEL SECURITY;

-- Cards: Anyone can read
CREATE POLICY "pop_cards_read" ON pop_cards
  FOR SELECT USING (true);

-- Sessions: Players can see sessions they're in
CREATE POLICY "pop_sessions_read" ON pop_sessions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pop_players
      WHERE session_id = pop_sessions.id
      AND user_id = auth.uid()
    )
    OR host_id = auth.uid()
  );

CREATE POLICY "pop_sessions_insert" ON pop_sessions
  FOR INSERT WITH CHECK (host_id = auth.uid());

CREATE POLICY "pop_sessions_update" ON pop_sessions
  FOR UPDATE USING (host_id = auth.uid());

-- Players: Can see other players in same session
CREATE POLICY "pop_players_read" ON pop_players
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pop_players p2
      WHERE p2.session_id = pop_players.session_id
      AND p2.user_id = auth.uid()
    )
  );

CREATE POLICY "pop_players_insert" ON pop_players
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "pop_players_update" ON pop_players
  FOR UPDATE USING (user_id = auth.uid());

-- Rankings: Only see own rankings until reveal phase
CREATE POLICY "pop_rankings_own" ON pop_rankings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM pop_players p
      WHERE p.id = pop_rankings.player_id
      AND p.user_id = auth.uid()
    )
  );

-- Round results: All players in session can see
CREATE POLICY "pop_round_results_read" ON pop_round_results
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pop_players
      WHERE session_id = pop_round_results.session_id
      AND user_id = auth.uid()
    )
  );

-- ═══════════════════════════════════════════════════════════════════════════
-- SEED DATA - CARD PROMPTS
-- ═══════════════════════════════════════════════════════════════════════════

-- VANILLA CATEGORY (Round 1 - Safe)
INSERT INTO pop_cards (text, category, subcategory, heat_level) VALUES
-- Touch & Intimacy
('Morning sex before getting out of bed', 'vanilla', 'intimacy', 1),
('Cuddling on the couch watching movies', 'vanilla', 'intimacy', 1),
('Long, slow kisses', 'vanilla', 'intimacy', 1),
('Holding hands in public', 'vanilla', 'public', 1),
('Back massages that lead nowhere', 'vanilla', 'touch', 1),
('Showering together', 'vanilla', 'intimacy', 2),
('Sleeping naked together', 'vanilla', 'intimacy', 1),
('Foreplay lasting 30+ minutes', 'vanilla', 'touch', 2),
('Dancing close at a party', 'vanilla', 'public', 1),
('Goodnight kisses every night', 'vanilla', 'intimacy', 1),
-- Romance
('Candlelit dinner at home', 'vanilla', 'romance', 1),
('Love notes hidden in pockets', 'vanilla', 'romance', 1),
('Breakfast in bed', 'vanilla', 'romance', 1),
('Slow dancing in the kitchen', 'vanilla', 'romance', 1),
('Weekend getaways with no plans', 'vanilla', 'adventure', 2);

-- SPICY CATEGORY (Round 2 - Sensual)
INSERT INTO pop_cards (text, category, subcategory, heat_level) VALUES
-- Sensory Play
('Blindfolds during intimacy', 'spicy', 'sensory', 2),
('Ice cubes on skin', 'spicy', 'sensory', 2),
('Feather teasing', 'spicy', 'sensory', 2),
('Silk scarves as restraints', 'spicy', 'bondage', 3),
('Massage with warming oils', 'spicy', 'touch', 2),
-- Public & Risk
('Public display of affection (heavy)', 'spicy', 'public', 2),
('Sexting throughout the workday', 'spicy', 'digital', 2),
('Almost getting caught', 'spicy', 'risk', 3),
('Leaving marks that others might see', 'spicy', 'marking', 3),
('Dirty talk', 'spicy', 'verbal', 2),
-- Roleplay Light
('Wearing lingerie / sexy underwear', 'spicy', 'dress', 2),
('Strip poker or strip games', 'spicy', 'games', 2),
('Giving commands in the bedroom', 'spicy', 'power', 2),
('Following commands in the bedroom', 'spicy', 'power', 2),
('Using a safe word', 'spicy', 'safety', 2);

-- EDGY CATEGORY (Round 3 - Kinky/Risk)
INSERT INTO pop_cards (text, category, subcategory, heat_level) VALUES
-- Power Dynamics
('Full roleplay with costumes', 'edgy', 'roleplay', 3),
('Dominant/submissive dynamics', 'edgy', 'power', 4),
('Handcuffs or proper restraints', 'edgy', 'bondage', 3),
('Being blindfolded AND restrained', 'edgy', 'sensory', 4),
('Punishment/reward systems', 'edgy', 'power', 4),
-- Exploration
('Using toys together', 'edgy', 'toys', 3),
('Mutual exploration of fantasies', 'edgy', 'communication', 3),
('Watching adult content together', 'edgy', 'digital', 3),
('Anal play (any level)', 'edgy', 'anal', 4),
('Body worship / devoted attention', 'edgy', 'worship', 3),
-- Location & Risk
('Hotel room hookups (own city)', 'edgy', 'location', 3),
('Semi-public spaces (car, balcony)', 'edgy', 'risk', 4),
('Mirror placement for viewing', 'edgy', 'voyeur', 3),
('Recording intimate moments (private)', 'edgy', 'digital', 4),
('Multiple rounds in one session', 'edgy', 'stamina', 3);

-- ═══════════════════════════════════════════════════════════════════════════
-- REALTIME SUBSCRIPTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Enable realtime for game tables
ALTER PUBLICATION supabase_realtime ADD TABLE pop_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE pop_players;
ALTER PUBLICATION supabase_realtime ADD TABLE pop_rankings;
ALTER PUBLICATION supabase_realtime ADD TABLE pop_round_results;
