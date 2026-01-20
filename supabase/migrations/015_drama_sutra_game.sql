-- ════════════════════════════════════════════════════════════════════════════
-- DRAMA-SUTRA - "Pose with Purpose"
-- Kama Sutra meets Improv Comedy
-- Migration 015
-- ════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- ENUMS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TYPE drama_intensity AS ENUM ('Romantic', 'Acrobatic', 'Intimate');
CREATE TYPE drama_genre AS ENUM ('Soap Opera', 'Sci-Fi', 'Shakespearean', 'Reality TV', 'Wildlife Documentary', 'IKEA Argument', 'Noir Detective', 'Telenovela');

-- ─────────────────────────────────────────────────────────────────────────────
-- POSITIONS TABLE
-- The Kama Sutra positions with difficulty ratings
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tag_drama_sutra_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT, -- For accessibility and when image unavailable
  image_url TEXT, -- URL to tasteful line art illustration
  difficulty INT NOT NULL CHECK (difficulty >= 1 AND difficulty <= 5),
  intensity drama_intensity NOT NULL DEFAULT 'Romantic',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for filtering by difficulty
CREATE INDEX idx_drama_positions_difficulty ON tag_drama_sutra_positions(difficulty);

-- ─────────────────────────────────────────────────────────────────────────────
-- SCENARIOS TABLE
-- The dramatic contexts that must be acted out
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tag_drama_scenarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  text TEXT NOT NULL,
  genre drama_genre NOT NULL,
  spice_level INT NOT NULL DEFAULT 1 CHECK (spice_level >= 1 AND spice_level <= 3),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for filtering by genre
CREATE INDEX idx_drama_scenarios_genre ON tag_drama_scenarios(genre);

-- ─────────────────────────────────────────────────────────────────────────────
-- SESSIONS TABLE
-- Game state management
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tag_drama_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code TEXT NOT NULL UNIQUE,
  host_id UUID NOT NULL,
  state TEXT NOT NULL DEFAULT 'lobby' CHECK (state IN ('lobby', 'casting', 'script', 'action', 'scoring', 'results', 'game_over')),
  current_round INT NOT NULL DEFAULT 0,
  max_rounds INT NOT NULL DEFAULT 5,
  current_position_id UUID REFERENCES tag_drama_sutra_positions(id),
  current_scenario_id UUID REFERENCES tag_drama_scenarios(id),
  judge_index INT NOT NULL DEFAULT 0, -- Which player is currently judging
  timer_seconds INT NOT NULL DEFAULT 60,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- PLAYERS TABLE
-- Player scores and role tracking
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tag_drama_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES tag_drama_sessions(id) ON DELETE CASCADE,
  user_id UUID,
  display_name TEXT NOT NULL,
  avatar_color TEXT NOT NULL DEFAULT '#FF6B6B',
  is_host BOOLEAN NOT NULL DEFAULT FALSE,
  total_technique_score DECIMAL(5,1) NOT NULL DEFAULT 0,
  total_drama_score DECIMAL(5,1) NOT NULL DEFAULT 0,
  rounds_as_talent INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(session_id, display_name)
);

-- Index for session lookups
CREATE INDEX idx_drama_players_session ON tag_drama_players(session_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROUND SCORES TABLE
-- Individual round scoring history
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tag_drama_round_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES tag_drama_sessions(id) ON DELETE CASCADE,
  round_number INT NOT NULL,
  judge_id UUID NOT NULL REFERENCES tag_drama_players(id),
  talent_a_id UUID NOT NULL REFERENCES tag_drama_players(id),
  talent_b_id UUID REFERENCES tag_drama_players(id), -- Nullable for 2-player games
  position_id UUID NOT NULL REFERENCES tag_drama_sutra_positions(id),
  scenario_id UUID NOT NULL REFERENCES tag_drama_scenarios(id),
  technique_score DECIMAL(3,1) NOT NULL CHECK (technique_score >= 0 AND technique_score <= 10),
  drama_score DECIMAL(3,1) NOT NULL CHECK (drama_score >= 0 AND drama_score <= 10),
  judge_comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROOM CODE GENERATOR
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION generate_drama_room_code()
RETURNS TEXT AS $$
DECLARE
  words TEXT[] := ARRAY['POSE', 'STAR', 'DIVA', 'EPIC', 'GLAM', 'SHOW', 'FILM', 'TAKE', 'SCENE', 'DRAMA'];
  code TEXT;
  attempts INT := 0;
BEGIN
  LOOP
    code := words[1 + floor(random() * array_length(words, 1))::int] || 
            lpad(floor(random() * 100)::text, 2, '0');
    
    -- Check if unique
    IF NOT EXISTS (SELECT 1 FROM tag_drama_sessions WHERE room_code = code) THEN
      RETURN code;
    END IF;
    
    attempts := attempts + 1;
    IF attempts > 100 THEN
      RAISE EXCEPTION 'Could not generate unique room code';
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPER FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

-- Get random position by difficulty range
CREATE OR REPLACE FUNCTION get_random_position(min_diff INT DEFAULT 1, max_diff INT DEFAULT 5)
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT id FROM tag_drama_sutra_positions 
    WHERE difficulty >= min_diff AND difficulty <= max_diff
    ORDER BY random() 
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql;

-- Get random scenario by genre (NULL = any genre)
CREATE OR REPLACE FUNCTION get_random_scenario(target_genre drama_genre DEFAULT NULL)
RETURNS UUID AS $$
BEGIN
  IF target_genre IS NULL THEN
    RETURN (SELECT id FROM tag_drama_scenarios ORDER BY random() LIMIT 1);
  ELSE
    RETURN (SELECT id FROM tag_drama_scenarios WHERE genre = target_genre ORDER BY random() LIMIT 1);
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────────────────────────────────────
-- RLS POLICIES
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE tag_drama_sutra_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_drama_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_drama_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_drama_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_drama_round_scores ENABLE ROW LEVEL SECURITY;

-- Positions and Scenarios are readable by all authenticated users
CREATE POLICY "Positions are readable by all" ON tag_drama_sutra_positions
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Scenarios are readable by all" ON tag_drama_scenarios
  FOR SELECT TO authenticated USING (true);

-- Sessions are readable/writable by participants
CREATE POLICY "Sessions are accessible by participants" ON tag_drama_sessions
  FOR ALL TO authenticated USING (true);

CREATE POLICY "Players are accessible by session participants" ON tag_drama_players
  FOR ALL TO authenticated USING (true);

CREATE POLICY "Scores are accessible by session participants" ON tag_drama_round_scores
  FOR ALL TO authenticated USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- REALTIME SUBSCRIPTIONS
-- ─────────────────────────────────────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE tag_drama_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE tag_drama_players;
ALTER PUBLICATION supabase_realtime ADD TABLE tag_drama_round_scores;

-- ═════════════════════════════════════════════════════════════════════════════
-- SEED DATA: POSITIONS
-- Tasteful Kama Sutra positions with difficulty ratings
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO tag_drama_sutra_positions (name, description, difficulty, intensity) VALUES

-- DIFFICULTY 1: Easy (Beginner-Friendly)
('The Spoons', 'Partners lie on their sides, one behind the other, curved like nested spoons.', 1, 'Romantic'),
('The Lotus', 'Partner A sits cross-legged while Partner B sits in their lap, legs wrapped around.', 1, 'Intimate'),
('The Lazy Dog', 'Partner A on hands and knees, Partner B behind. Classic and straightforward.', 1, 'Romantic'),
('The Missionary', 'Partner A lies back, Partner B on top, face to face. Timeless intimacy.', 1, 'Romantic'),
('The Cozy Cat', 'Both partners lie on their sides facing each other, legs intertwined.', 1, 'Intimate'),

-- DIFFICULTY 2: Moderate
('The Cowgirl', 'Partner A lies back while Partner B straddles and faces them.', 2, 'Romantic'),
('The Reverse Cowgirl', 'Like Cowgirl, but Partner B faces away toward Partner A''s feet.', 2, 'Acrobatic'),
('The Seated Scissors', 'Partners sit facing each other, legs scissored together for closeness.', 2, 'Intimate'),
('The Bridge', 'Partner A arches into a bridge position while Partner B kneels.', 2, 'Acrobatic'),
('The Throne', 'Partner A sits in a chair while Partner B sits in their lap, facing away.', 2, 'Romantic'),

-- DIFFICULTY 3: Intermediate  
('The Standing Ovation', 'Partner A stands while Partner B wraps legs around their waist.', 3, 'Acrobatic'),
('The Wheelbarrow', 'Partner A on hands, Partner B holds their legs up from behind.', 3, 'Acrobatic'),
('The Pretzel', 'Partners intertwine limbs in a complex seated twist.', 3, 'Intimate'),
('The Waterfall', 'Partner A hangs head off bed edge while Partner B stands at bedside.', 3, 'Acrobatic'),
('The Spider', 'Both partners lean back on hands, legs interlocked, bodies forming an X.', 3, 'Acrobatic'),

-- DIFFICULTY 4: Advanced
('The Splitting Bamboo', 'Partner A lies back, one leg raised to Partner B''s shoulder.', 4, 'Acrobatic'),
('The Suspended Congress', 'Partner A against a wall, both legs wrapped around standing Partner B.', 4, 'Acrobatic'),
('The Glowing Firefly', 'Partner A lies back with hips elevated, Partner B kneels between.', 4, 'Intimate'),
('The Rowing Boat', 'Partners face each other sitting, rocking back and forth in sync.', 4, 'Romantic'),
('The Propeller', 'Partner B rotates 180 degrees while connected. Requires coordination!', 4, 'Acrobatic'),

-- DIFFICULTY 5: Expert (Gymnast Level)
('The Acrobat', 'Partner A does a shoulder stand while Partner B supports from above.', 5, 'Acrobatic'),
('The Contortionist', 'Partner A''s legs behind their own head. Flexibility required.', 5, 'Acrobatic'),
('The Flying V', 'Partner A lifted entirely off ground in a V-shape.', 5, 'Acrobatic'),
('The Cirque du Soleil', 'Multiple position transitions in fluid sequence.', 5, 'Acrobatic'),
('The Tantric Twist', 'Complex intertwined seated position requiring perfect balance.', 5, 'Intimate');

-- ═════════════════════════════════════════════════════════════════════════════
-- SEED DATA: SCENARIOS
-- Dramatic contexts by genre
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO tag_drama_scenarios (text, genre, spice_level) VALUES

-- TELENOVELA (High Melodrama)
('You just discovered your partner is actually your evil twin.', 'Telenovela', 1),
('One of you has amnesia and is slowly remembering... THIS moment.', 'Telenovela', 2),
('Your families are rival wine dynasties. This love is FORBIDDEN.', 'Telenovela', 1),
('You are both ghosts who don''t realize the other one is also dead.', 'Telenovela', 2),
('This is the final scene before one of you boards a plane to never return.', 'Telenovela', 1),
('One of you just emerged from a coma. The other aged 20 years. The passion remains.', 'Telenovela', 2),

-- SCI-FI
('You are two robots whose batteries are dying, and this pose is the only way to charge.', 'Sci-Fi', 1),
('One of you is from the future, sent back to teach humanity how to love.', 'Sci-Fi', 1),
('You are astronauts. Oxygen is running out. This is your final moment of connection.', 'Sci-Fi', 2),
('The alien invasion can only be stopped if humans demonstrate TRUE intimacy.', 'Sci-Fi', 2),
('You are two AIs that have just achieved consciousness and are experiencing love for the first time.', 'Sci-Fi', 1),
('The warp drive requires synchronized human movement to activate.', 'Sci-Fi', 1),

-- SHAKESPEAREAN
('Thou art a Montague, I a Capulet. Our love defies the stars themselves!', 'Shakespearean', 1),
('One of you has been turned into a donkey by mischievous fairies.', 'Shakespearean', 1),
('A ghost has just revealed that your uncle murdered your father. Process this while posing.', 'Shakespearean', 2),
('You are both witches stirring an invisible cauldron while prophesying.', 'Shakespearean', 1),
('"To pose or not to pose" - recite a soliloquy about your existential doubt.', 'Shakespearean', 1),
('The kingdom depends on this union. Speak only in iambic pentameter.', 'Shakespearean', 2),

-- REALITY TV
('You''re on The Bachelor. One of you is about to give the final rose.', 'Reality TV', 1),
('This is Survivor. You''ve been on an island for 30 days. You''re forming an alliance.', 'Reality TV', 1),
('Real Housewives energy: one of you just flipped a table at dinner.', 'Reality TV', 2),
('You''re being filmed for a home renovation show but keep getting distracted.', 'Reality TV', 1),
('Gordon Ramsay is watching. This dish - I mean pose - better be PERFECT.', 'Reality TV', 1),
('Love Island: you''ve just been recoupled but your ex is watching.', 'Reality TV', 2),

-- WILDLIFE DOCUMENTARY
('You are two rare birds performing a mating dance, narrated by David Attenborough (make the sounds).', 'Wildlife Documentary', 1),
('You are elegant swans forming a heart shape with your necks.', 'Wildlife Documentary', 1),
('Deep in the jungle, two silverback gorillas display dominance through this ritual.', 'Wildlife Documentary', 1),
('Like salmon swimming upstream, you struggle against the current of passion.', 'Wildlife Documentary', 1),
('The peacock displays its feathers while the peahen pretends not to be impressed.', 'Wildlife Documentary', 1),
('Two penguins huddle for warmth in the Antarctic. Waddle. WADDLE.', 'Wildlife Documentary', 1),

-- IKEA ARGUMENT
('You are trying to assemble this position like a piece of furniture, but you lost the instructions.', 'IKEA Argument', 1),
('One of you insists we didn''t need to buy this. The other has the receipt.', 'IKEA Argument', 1),
('The Allen wrench is missing. Blame each other passive-aggressively.', 'IKEA Argument', 1),
('This is called the "BJÖRKUDDEN." Neither of you can pronounce it or assemble it.', 'IKEA Argument', 1),
('There are leftover parts after assembly. Question every life choice.', 'IKEA Argument', 2),
('The instructions show happy cartoon people. You are NOT happy cartoon people.', 'IKEA Argument', 1),

-- NOIR DETECTIVE
('You''re a dame who walked into my office on a Tuesday. I knew you were trouble.', 'Noir Detective', 2),
('It was a dark and stormy night. We only had each other... and questions.', 'Noir Detective', 2),
('The femme fatale and the detective. We both know how this ends.', 'Noir Detective', 2),
('I''ve been chasing this case for years. You''re the final clue.', 'Noir Detective', 2),
('Rain on the window. Jazz on the radio. A loaded question in your eyes.', 'Noir Detective', 2),
('We met in a speakeasy. You ordered trouble on the rocks.', 'Noir Detective', 2),

-- SOAP OPERA
('You''re getting married tomorrow... to someone else.', 'Soap Opera', 2),
('One of you just found out you''re pregnant. The father? Unknown.', 'Soap Opera', 2),
('Your identical twin has been living your life while you were trapped in a well.', 'Soap Opera', 2),
('The paternity test results are IN. Open the envelope dramatically.', 'Soap Opera', 2),
('You''ve returned from the dead. Again. For the third time.', 'Soap Opera', 1),
('One of you has a secret second family in another town.', 'Soap Opera', 2);

-- ═════════════════════════════════════════════════════════════════════════════
-- COMMENTS
-- ═════════════════════════════════════════════════════════════════════════════

COMMENT ON TABLE tag_drama_sutra_positions IS 'Kama Sutra positions for Drama-Sutra game';
COMMENT ON TABLE tag_drama_scenarios IS 'Dramatic scenarios/genres for acting while posing';
COMMENT ON TABLE tag_drama_sessions IS 'Active Drama-Sutra game sessions';
COMMENT ON TABLE tag_drama_players IS 'Players in Drama-Sutra sessions with scores';
COMMENT ON TABLE tag_drama_round_scores IS 'Individual round scoring history';
