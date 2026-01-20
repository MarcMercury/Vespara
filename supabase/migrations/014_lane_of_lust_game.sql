-- ════════════════════════════════════════════════════════════════════════════
-- LANE OF LUST - Timeline Style Desire Game
-- TAG Engine Phase 5
-- "Shit Happens" meets intimate scenarios
-- First to 10 cards wins!
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- CARD DECK TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS tag_lane_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  text TEXT NOT NULL,
  desire_index INTEGER NOT NULL CHECK (desire_index BETWEEN 1 AND 100),
  category TEXT NOT NULL CHECK (category IN ('vanilla', 'kinky', 'romance', 'wild')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tag_lane_cards_category ON tag_lane_cards(category);
CREATE INDEX IF NOT EXISTS idx_tag_lane_cards_desire ON tag_lane_cards(desire_index);
CREATE INDEX IF NOT EXISTS idx_tag_lane_cards_active ON tag_lane_cards(is_active);

-- ═══════════════════════════════════════════════════════════════════════════
-- GAME SESSIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS tag_lane_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code TEXT NOT NULL UNIQUE,
  host_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  state TEXT NOT NULL DEFAULT 'LOBBY' CHECK (state IN ('LOBBY', 'DEALING', 'PLAYING', 'STEALING', 'GAME_OVER')),
  -- Current game state
  current_player_index INTEGER DEFAULT 0,
  current_card_id UUID REFERENCES tag_lane_cards(id),
  steal_chain_index INTEGER DEFAULT 0, -- Who's trying to steal
  winner_id UUID REFERENCES auth.users(id),
  -- Deck management (cards not yet drawn)
  deck_cards UUID[] DEFAULT '{}',
  discarded_cards UUID[] DEFAULT '{}',
  -- Settings
  win_target INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  finished_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_tag_lane_sessions_room ON tag_lane_sessions(room_code);
CREATE INDEX IF NOT EXISTS idx_tag_lane_sessions_state ON tag_lane_sessions(state);
CREATE INDEX IF NOT EXISTS idx_tag_lane_sessions_host ON tag_lane_sessions(host_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- PLAYERS TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS tag_lane_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES tag_lane_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_color TEXT DEFAULT '#4A9EFF',
  player_order INTEGER NOT NULL, -- Turn order (0-based)
  -- The player's "Lane" - array of {card_id, desire_index, text}
  hand JSONB DEFAULT '[]'::jsonb,
  is_host BOOLEAN DEFAULT false,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, user_id),
  UNIQUE(session_id, player_order)
);

CREATE INDEX IF NOT EXISTS idx_tag_lane_players_session ON tag_lane_players(session_id);
CREATE INDEX IF NOT EXISTS idx_tag_lane_players_user ON tag_lane_players(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Generate room code
CREATE OR REPLACE FUNCTION generate_lane_room_code()
RETURNS TEXT AS $$
DECLARE
  codes TEXT[] := ARRAY[
    'LUST', 'HEAT', 'FIRE', 'BURN', 'WILD', 'VIBE', 'EDGE', 'DARE',
    'RUSH', 'SILK', 'GLOW', 'PEAK', 'SYNC', 'BOND', 'FLUX', 'WANT'
  ];
  base_code TEXT;
  final_code TEXT;
  suffix INTEGER;
BEGIN
  base_code := codes[1 + floor(random() * array_length(codes, 1))::int];
  suffix := floor(random() * 100)::int;
  final_code := base_code || lpad(suffix::text, 2, '0');
  
  WHILE EXISTS (
    SELECT 1 FROM tag_lane_sessions 
    WHERE room_code = final_code 
    AND state != 'GAME_OVER'
  ) LOOP
    suffix := floor(random() * 100)::int;
    base_code := codes[1 + floor(random() * array_length(codes, 1))::int];
    final_code := base_code || lpad(suffix::text, 2, '0');
  END LOOP;
  
  RETURN final_code;
END;
$$ LANGUAGE plpgsql;

-- Get shuffled deck for a new game
CREATE OR REPLACE FUNCTION get_lane_shuffled_deck()
RETURNS UUID[] AS $$
BEGIN
  RETURN ARRAY(
    SELECT id FROM tag_lane_cards
    WHERE is_active = true
    ORDER BY random()
  );
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE tag_lane_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_lane_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_lane_players ENABLE ROW LEVEL SECURITY;

-- Cards: Anyone can read
CREATE POLICY "tag_lane_cards_read" ON tag_lane_cards
  FOR SELECT USING (true);

-- Sessions: Players can see sessions they're in
CREATE POLICY "tag_lane_sessions_read" ON tag_lane_sessions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tag_lane_players
      WHERE session_id = tag_lane_sessions.id
      AND user_id = auth.uid()
    )
    OR host_id = auth.uid()
  );

CREATE POLICY "tag_lane_sessions_insert" ON tag_lane_sessions
  FOR INSERT WITH CHECK (host_id = auth.uid());

CREATE POLICY "tag_lane_sessions_update" ON tag_lane_sessions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM tag_lane_players
      WHERE session_id = tag_lane_sessions.id
      AND user_id = auth.uid()
    )
  );

-- Players: Can see other players in same session
CREATE POLICY "tag_lane_players_read" ON tag_lane_players
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM tag_lane_players p2
      WHERE p2.session_id = tag_lane_players.session_id
      AND p2.user_id = auth.uid()
    )
  );

CREATE POLICY "tag_lane_players_insert" ON tag_lane_players
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "tag_lane_players_update" ON tag_lane_players
  FOR UPDATE USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- REALTIME
-- ═══════════════════════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE tag_lane_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE tag_lane_players;

-- ═══════════════════════════════════════════════════════════════════════════
-- SEED DATA - 50+ CARDS WITH DESIRE INDEX
-- ═══════════════════════════════════════════════════════════════════════════

-- LOW DESIRE (1-30) - Vanilla/Mild
INSERT INTO tag_lane_cards (text, desire_index, category) VALUES
-- Disappointing / Negative
('Your partner forgets your birthday', 5, 'vanilla'),
('A goodnight text that just says "night"', 8, 'vanilla'),
('Getting a handshake instead of a hug goodbye', 3, 'vanilla'),
('Cuddling fully clothed on a hot day', 10, 'vanilla'),
('A peck on the forehead from your grandma', 2, 'vanilla'),
-- Sweet but mild
('A quick peck on the cheek', 12, 'vanilla'),
('Brushing hands "accidentally"', 15, 'vanilla'),
('Sitting next to your crush on the bus', 18, 'vanilla'),
('A 3-second hug', 14, 'vanilla'),
('Holding hands in a movie theater', 25, 'romance'),
('Getting a "you look nice today" compliment', 22, 'vanilla'),
('A wink from across the room', 20, 'vanilla'),
('Someone holding the door open for you', 7, 'vanilla'),
('A side hug', 11, 'vanilla'),
('Sharing dessert at dinner', 28, 'romance');

-- MEDIUM-LOW DESIRE (31-45)
INSERT INTO tag_lane_cards (text, desire_index, category) VALUES
('Dancing close at a wedding', 32, 'romance'),
('A long hug that lingers', 35, 'romance'),
('Slow dancing in the living room', 38, 'romance'),
('A kiss on the neck', 42, 'romance'),
('Cuddling while watching Netflix', 33, 'vanilla'),
('Playing footsie under the table', 37, 'romance'),
('Whispering something flirty in their ear', 44, 'romance'),
('A goodnight kiss that lasts a little too long', 40, 'romance'),
('Getting a handwritten love letter', 36, 'romance'),
('Matching underwear for date night', 43, 'romance');

-- MEDIUM DESIRE (46-60)
INSERT INTO tag_lane_cards (text, desire_index, category) VALUES
('A sensual back massage with oil', 48, 'romance'),
('Receiving a flirty text at work', 52, 'romance'),
('Making out in a parked car', 55, 'romance'),
('Shower sex (with the logistics actually working)', 58, 'wild'),
('Skinny dipping at night', 56, 'wild'),
('A lap dance at home', 54, 'kinky'),
('Your partner wearing something special for you', 50, 'romance'),
('Role-playing as strangers at a bar', 59, 'kinky'),
('Getting a hickey in a hidden spot', 53, 'wild'),
('Morning sex that makes you late', 57, 'wild');

-- MEDIUM-HIGH DESIRE (61-75)
INSERT INTO tag_lane_cards (text, desire_index, category) VALUES
('Sex in a hotel room on vacation', 62, 'wild'),
('Using a new toy together', 65, 'kinky'),
('Dirty talk that actually works', 68, 'kinky'),
('Blindfolded and at their mercy', 72, 'kinky'),
('Public teasing under the table', 70, 'wild'),
('A full body massage that leads to more', 64, 'romance'),
('Being woken up in the best way possible', 67, 'wild'),
('Sexting while at a boring event', 63, 'wild'),
('Strip poker that goes all the way', 71, 'wild'),
('A champagne-fueled hotel night', 66, 'romance');

-- HIGH DESIRE (76-90)
INSERT INTO tag_lane_cards (text, desire_index, category) VALUES
('A weekend getaway to a private cabin', 78, 'romance'),
('Being dominated (in the way you like)', 82, 'kinky'),
('Mile High Club membership', 85, 'wild'),
('A professional couples photoshoot (the private kind)', 80, 'kinky'),
('Sex in a semi-public place', 83, 'wild'),
('Being tied up and teased for an hour', 88, 'kinky'),
('A fantasy role-play fully executed', 86, 'kinky'),
('Spontaneous sex in an unexpected location', 79, 'wild'),
('An all-night session with no interruptions', 84, 'wild'),
('Your partner knowing exactly what you need', 77, 'romance');

-- EXTREME DESIRE (91-100)
INSERT INTO tag_lane_cards (text, desire_index, category) VALUES
('A surprise threesome with enthusiastic consent', 95, 'wild'),
('Your deepest fantasy fulfilled', 98, 'kinky'),
('Being worshipped for an entire evening', 92, 'kinky'),
('A vacation where you barely leave the room', 93, 'romance'),
('Multiple rounds with full recovery', 94, 'wild'),
('A surprise that exceeds all expectations', 96, 'wild'),
('Complete trust and total surrender', 97, 'kinky'),
('A night you will never, ever forget', 99, 'wild'),
('The best experience of your life (so far)', 100, 'wild'),
('Living out a scene from your favorite fantasy', 91, 'kinky');
