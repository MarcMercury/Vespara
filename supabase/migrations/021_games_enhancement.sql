-- ════════════════════════════════════════════════════════════════════════════
-- GAMES ENHANCEMENT MIGRATION
-- 1. Velvet Rope X-Rating: Dramatically more explicit consensual acts
-- 2. Drama Sutra: Complete redesign as Director/Actors position game
-- Migration 021
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 1: VELVET ROPE - ENHANCED X-RATED CONTENT
-- These are for consenting adults only - explicit, multi-person, creative
-- ═══════════════════════════════════════════════════════════════════════════

-- Remove existing X-rated cards (they're too tame)
DELETE FROM public.velvet_rope_cards WHERE heat_level = 'X';

-- Insert dramatically more explicit X-rated content
INSERT INTO public.velvet_rope_cards (type, text, heat_level, category) VALUES

-- ═══════════════════════════════════════════════════════════════════════════
-- X-RATED TRUTHS - Explicit, Multi-Person, No Holds Barred
-- ═══════════════════════════════════════════════════════════════════════════

('truth', '[CONSENT CHECK] Describe in explicit detail your most memorable threesome experience - or your fantasy of one. Positions, who did what, the whole story.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] What sexual act have you fantasized about involving everyone in this room simultaneously? Be specific about roles.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] Rank everyone here by who you think would be best at oral. Explain your reasoning in detail.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] Describe the dirtiest group sex scenario you''ve either participated in or desperately want to. Spare no details.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] What''s your favorite position when there are 3 or more people involved? Demonstrate with your hands if needed.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] Have you ever been the center of a train? If not, describe exactly how you''d want it to happen.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] Describe in explicit detail what you''d do if you could have any two people in this room right now.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] What''s the most people you''ve been intimate with at once? Describe the logistics.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] If this turned into an orgy right now, who would you want doing what to you? Be graphic.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] Describe your ultimate gang bang fantasy - are you giving, receiving, or both?', 'X', 'kinky'),
('truth', '[CONSENT CHECK] What sexual act are you best at? Give a detailed explanation of your technique.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] Have you ever been spit-roasted? If not, would you want to be? Describe your ideal scenario.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] What''s the filthiest thing you''ve ever said during sex? Repeat it now, in context.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] Describe in detail your perfect MFM or FMF threesome scenario with people in this room.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] What''s a specific sex act you want to try tonight with multiple partners if everyone consents?', 'X', 'kinky'),
('truth', '[CONSENT CHECK] If you could direct everyone here in a porn scene, what would happen? Assign roles.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] Describe your most explicit fantasy involving being shared between multiple partners.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] What''s your honest review of the last person you went down on? Technique, taste, sounds - all of it.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] Have you ever been in a daisy chain? Describe it or describe how you''d want one to work.', 'X', 'kinky'),
('truth', '[CONSENT CHECK] What position makes you cum the hardest and why? Be explicit.', 'X', 'kinky'),

-- ═══════════════════════════════════════════════════════════════════════════
-- X-RATED DARES - Physical, Multi-Person, Explicit Acts
-- All require enthusiastic consent from all participants
-- ═══════════════════════════════════════════════════════════════════════════

('dare', '[CONSENT CHECK] With 2 willing partners: demonstrate your favorite threesome position. Clothes can stay on but positioning must be accurate.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Choose 2 people. One blindfolded receiving, one watching while you demonstrate your oral technique on their neck/ears.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] With consent from all: orchestrate a 60-second makeout involving at least 3 people including yourself.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Strip completely for the group. Let them look for 30 seconds. Own it.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Demonstrate on a willing participant exactly how you like to be touched. Guide their hands. Be specific.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Choose 2 willing participants and position them in your favorite threesome arrangement. Coach them into it.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Give simultaneous lap dances to 2 people at once. Make it memorable.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] With a willing partner, demonstrate your signature move that always gets them off. Clothes optional.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Let the group body paint something explicit on you. Minimal clothing required.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Recreate a porn scene of the group''s choosing with willing participants. Commitment required.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] 10 minutes alone with TWO willing people of your choice. Report back on what happened.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] With 2+ consenting partners, form a human pretzel of your collective choosing. Hold for 60 seconds.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Perform a striptease. Everyone gets to remove one piece of your clothing.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Let 2 people take turns kissing you passionately. Rate them out of 10 out loud.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Demonstrate on willing volunteers how you''d arrange a 4-person pile. Get everyone in position.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Body shots off of 2 different willing people. You pick where on each.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] With consent: enact a slave/master dynamic with a willing partner for the next 3 rounds.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Let 2 willing people undress you simultaneously while you describe what you want done to you.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Make out with one person while a second person kisses your neck. 90 seconds minimum.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] The group picks 2 people. You must be the filling in that sandwich for a full song.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Perform an explicit lap dance, ending with you in the lap of a second person of your choice.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] With 2 consenting partners, demonstrate ''the Eiffel Tower'' position. Clothed is fine, positioning must be right.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Lead a guided touch session - direct 2 people on exactly how to touch you. Narrate it.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Let willing participants write their dirtiest wish on your body. You must attempt to fulfill one.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Create and star in a 2-minute ''scene'' with 2 willing partners. The group directs.', 'X', 'kinky');


-- ═══════════════════════════════════════════════════════════════════════════
-- PART 2: DRAMA SUTRA - COMPLETE REDESIGN
-- New Gameplay: Director + 2-4 Actors
-- Director sees position card, must direct actors WITHOUT naming body parts
-- Spectators rate accuracy 1-5
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop old scenarios table (we don't need dramatic genres anymore)
DROP TABLE IF EXISTS tag_drama_round_scores CASCADE;
DROP TABLE IF EXISTS tag_drama_players CASCADE;
DROP TABLE IF EXISTS tag_drama_sessions CASCADE;
DROP TABLE IF EXISTS tag_drama_scenarios CASCADE;
DROP TABLE IF EXISTS tag_drama_sutra_positions CASCADE;

-- Drop old types
DROP TYPE IF EXISTS drama_genre CASCADE;
DROP TYPE IF EXISTS drama_intensity CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- NEW ENUMS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TYPE position_category AS ENUM (
  'Classic',           -- Well-known positions
  'Kama Sutra',        -- From the actual text
  'Acrobatic',         -- Requires flexibility/strength
  'Group',             -- 3+ people
  'Urban Dictionary',  -- Internet-famous creative names
  'Tantric'            -- Slow, spiritual, connected
);

CREATE TYPE actor_count AS ENUM ('2', '3', '4');

-- ─────────────────────────────────────────────────────────────────────────────
-- SCENE CARDS TABLE
-- Each card has a position name, stick figure description, and category
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tag_drama_scene_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  position_name TEXT NOT NULL,
  description TEXT NOT NULL, -- Textual description of the stick figure (for accessibility/AI generation)
  stick_figure_svg TEXT, -- SVG markup for the stick figure drawing
  category position_category NOT NULL,
  actors_required actor_count NOT NULL DEFAULT '2',
  difficulty INT NOT NULL CHECK (difficulty >= 1 AND difficulty <= 5),
  spice_level INT NOT NULL CHECK (spice_level >= 1 AND spice_level <= 5), -- 1=mild, 5=explicit
  is_kama_sutra_original BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_scene_cards_category ON tag_drama_scene_cards(category);
CREATE INDEX idx_scene_cards_actors ON tag_drama_scene_cards(actors_required);
CREATE INDEX idx_scene_cards_difficulty ON tag_drama_scene_cards(difficulty);

-- ─────────────────────────────────────────────────────────────────────────────
-- SESSIONS TABLE
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tag_drama_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code TEXT NOT NULL UNIQUE,
  host_id UUID NOT NULL,
  state TEXT NOT NULL DEFAULT 'lobby' CHECK (state IN ('lobby', 'directing', 'posing', 'rating', 'results', 'game_over')),
  current_round INT NOT NULL DEFAULT 0,
  max_rounds INT NOT NULL DEFAULT 8,
  current_card_id UUID REFERENCES tag_drama_scene_cards(id),
  current_director_index INT NOT NULL DEFAULT 0,
  timer_seconds INT NOT NULL DEFAULT 90, -- Time for director to get actors in position
  max_spice_level INT NOT NULL DEFAULT 3, -- Configurable spice limit
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- PLAYERS TABLE
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tag_drama_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES tag_drama_sessions(id) ON DELETE CASCADE,
  user_id UUID,
  display_name TEXT NOT NULL,
  avatar_color TEXT NOT NULL DEFAULT '#FF6B6B',
  is_host BOOLEAN NOT NULL DEFAULT FALSE,
  total_score DECIMAL(5,1) NOT NULL DEFAULT 0, -- Accumulated accuracy ratings as director
  rounds_as_director INT NOT NULL DEFAULT 0,
  rounds_as_actor INT NOT NULL DEFAULT 0,
  player_order INT NOT NULL DEFAULT 0, -- For determining director rotation
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(session_id, display_name)
);

CREATE INDEX idx_drama_players_session ON tag_drama_players(session_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROUND RATINGS TABLE
-- Each spectator rates the accuracy 1-5 after actors pose
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tag_drama_round_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES tag_drama_sessions(id) ON DELETE CASCADE,
  round_number INT NOT NULL,
  card_id UUID NOT NULL REFERENCES tag_drama_scene_cards(id),
  director_id UUID NOT NULL REFERENCES tag_drama_players(id),
  actor_ids UUID[] NOT NULL, -- Array of actor player IDs
  rater_id UUID NOT NULL REFERENCES tag_drama_players(id),
  accuracy_rating INT NOT NULL CHECK (accuracy_rating >= 1 AND accuracy_rating <= 5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(session_id, round_number, rater_id) -- One rating per spectator per round
);

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPER FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

-- Generate room code
CREATE OR REPLACE FUNCTION generate_drama_room_code()
RETURNS TEXT AS $$
DECLARE
  words TEXT[] := ARRAY['POSE', 'FLEX', 'BEND', 'ARCH', 'HOLD', 'SHOW', 'MOVE', 'LIFT', 'WRAP', 'TWIST'];
  code TEXT;
  attempts INT := 0;
BEGIN
  LOOP
    code := words[1 + floor(random() * array_length(words, 1))::int] || 
            lpad(floor(random() * 100)::text, 2, '0');
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

-- Get random scene card based on settings
CREATE OR REPLACE FUNCTION get_random_scene_card(
  p_max_spice INT DEFAULT 3,
  p_actors actor_count DEFAULT NULL,
  p_max_difficulty INT DEFAULT 5
)
RETURNS UUID AS $$
BEGIN
  IF p_actors IS NULL THEN
    RETURN (
      SELECT id FROM tag_drama_scene_cards 
      WHERE spice_level <= p_max_spice 
        AND difficulty <= p_max_difficulty
      ORDER BY random() 
      LIMIT 1
    );
  ELSE
    RETURN (
      SELECT id FROM tag_drama_scene_cards 
      WHERE spice_level <= p_max_spice 
        AND actors_required = p_actors
        AND difficulty <= p_max_difficulty
      ORDER BY random() 
      LIMIT 1
    );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Calculate round average rating
CREATE OR REPLACE FUNCTION get_round_average_rating(p_session_id UUID, p_round INT)
RETURNS DECIMAL(3,2) AS $$
BEGIN
  RETURN (
    SELECT COALESCE(AVG(accuracy_rating), 0)
    FROM tag_drama_round_ratings
    WHERE session_id = p_session_id AND round_number = p_round
  );
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────────────────────────────────────
-- RLS POLICIES
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE tag_drama_scene_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_drama_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_drama_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_drama_round_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Scene cards readable by all" ON tag_drama_scene_cards
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Sessions viewable by participants" ON tag_drama_sessions
  FOR SELECT TO authenticated USING (
    host_id = auth.uid() OR
    EXISTS (SELECT 1 FROM tag_drama_players WHERE session_id = id AND user_id = auth.uid())
  );

CREATE POLICY "Sessions manageable by host" ON tag_drama_sessions
  FOR INSERT TO authenticated WITH CHECK (host_id = auth.uid());

CREATE POLICY "Sessions updatable by host" ON tag_drama_sessions
  FOR UPDATE TO authenticated USING (host_id = auth.uid());

CREATE POLICY "Players can view session players" ON tag_drama_players
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Players can manage own record" ON tag_drama_players
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Players can update own record" ON tag_drama_players
  FOR UPDATE TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Ratings viewable by all" ON tag_drama_round_ratings
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can insert own ratings" ON tag_drama_round_ratings
  FOR INSERT TO authenticated WITH CHECK (true);

-- Allow anon for demo mode
CREATE POLICY "Scene cards readable by anon" ON tag_drama_scene_cards
  FOR SELECT TO anon USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- REALTIME
-- ─────────────────────────────────────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE tag_drama_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE tag_drama_players;
ALTER PUBLICATION supabase_realtime ADD TABLE tag_drama_round_ratings;

-- ═══════════════════════════════════════════════════════════════════════════
-- SEED DATA: SCENE CARDS
-- Mix of classic, Kama Sutra, urban dictionary, and creative positions
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO tag_drama_scene_cards (position_name, description, category, actors_required, difficulty, spice_level, is_kama_sutra_original) VALUES

-- ═══════════════════════════════════════════════════════════════════════════
-- CLASSIC POSITIONS (Well-known, 2 actors)
-- ═══════════════════════════════════════════════════════════════════════════

('Missionary', 'Person A lies flat on back. Person B lies on top facing down, aligned face-to-face.', 'Classic', '2', 1, 2, FALSE),
('Doggy Style', 'Person A on hands and knees. Person B kneels behind them.', 'Classic', '2', 1, 3, FALSE),
('Cowgirl', 'Person A lies flat on back. Person B sits upright straddling their hips, facing their face.', 'Classic', '2', 1, 3, FALSE),
('Reverse Cowgirl', 'Person A lies flat on back. Person B sits straddling their hips, facing their feet.', 'Classic', '2', 2, 3, FALSE),
('Spooning', 'Both people lie on their sides. Person B is behind Person A, curved like nested spoons.', 'Classic', '2', 1, 2, FALSE),
('69', 'Both people lie head-to-toe. Each person''s face is at the other''s pelvis, forming the number 69.', 'Classic', '2', 2, 4, FALSE),
('Standing', 'Both people stand facing each other. Person A lifts one leg, Person B supports it.', 'Classic', '2', 3, 3, FALSE),
('Sideways', 'Both people lie on their sides facing each other, legs intertwined at the pelvis.', 'Classic', '2', 2, 2, FALSE),
('Lazy Dog', 'Person A lies flat on stomach. Person B lies on top of their back.', 'Classic', '2', 1, 3, FALSE),
('The Seated', 'Person A sits on edge of surface. Person B stands or kneels in front between their legs.', 'Classic', '2', 2, 3, FALSE),

-- ═══════════════════════════════════════════════════════════════════════════
-- KAMA SUTRA ORIGINALS (2 actors)
-- ═══════════════════════════════════════════════════════════════════════════

('The Lotus', 'Person A sits cross-legged. Person B sits in their lap facing them, legs wrapped around their waist.', 'Kama Sutra', '2', 2, 2, TRUE),
('The Splitting Bamboo', 'Person A lies on back. One leg raised to Person B''s shoulder, other leg flat.', 'Kama Sutra', '2', 3, 3, TRUE),
('The Suspended Congress', 'Person A stands against wall. Person B''s legs wrapped around Person A''s waist, supported.', 'Kama Sutra', '2', 4, 4, TRUE),
('The Padlock', 'Person A sits on edge. Person B wraps both legs tightly around Person A''s waist, locked at ankles.', 'Kama Sutra', '2', 2, 3, TRUE),
('The Glowing Triangle', 'Person A kneels. Person B lies back with hips elevated on Person A''s thighs.', 'Kama Sutra', '2', 2, 3, TRUE),
('The Spider', 'Both lean back on hands, facing each other, legs interlocked forming an X at pelvises.', 'Kama Sutra', '2', 3, 3, TRUE),
('The Rowing Boat', 'Both sit facing each other, legs over each other''s thighs, holding hands, rocking.', 'Kama Sutra', '2', 2, 2, TRUE),
('The Yawning', 'Person A lies on back with both legs raised straight up. Person B kneels facing them.', 'Kama Sutra', '2', 3, 3, TRUE),
('The Tigress', 'Person A on all fours. Person B behind but reaching around to hold Person A''s shoulders.', 'Kama Sutra', '2', 2, 3, TRUE),
('The Churning', 'Person A lies on back. Person B sits on top and rotates their hips in circles.', 'Kama Sutra', '2', 2, 3, TRUE),
('The Milk and Water', 'Person A sits with legs straight. Person B sits in lap facing same direction, legs outside.', 'Kama Sutra', '2', 2, 2, TRUE),
('The Erotic V', 'Person A lies on back. Legs raised high and spread in a V. Person B kneels at the opening.', 'Kama Sutra', '2', 3, 4, TRUE),

-- ═══════════════════════════════════════════════════════════════════════════
-- URBAN DICTIONARY / CREATIVE (2 actors)
-- ═══════════════════════════════════════════════════════════════════════════

('The Wheelbarrow', 'Person A on hands only. Person B holds Person A''s legs up from behind like pushing a wheelbarrow.', 'Urban Dictionary', '2', 4, 4, FALSE),
('The Pretzel', 'Person A lies on side with top leg raised. Person B straddles bottom leg, facing Person A.', 'Urban Dictionary', '2', 3, 3, FALSE),
('The Helicopter', 'Person A lies on back. Person B on top, rotating 360 degrees while maintaining position.', 'Urban Dictionary', '2', 5, 4, FALSE),
('The Piledriver', 'Person A on back, legs over their own head, hips elevated high. Person B standing over them.', 'Urban Dictionary', '2', 5, 5, FALSE),
('The London Bridge', 'Person A in a backbend/bridge. Person B stands between their raised hips.', 'Urban Dictionary', '2', 4, 4, FALSE),
('The Face Off', 'Both people sit in each other''s laps, facing each other, arms wrapped around.', 'Urban Dictionary', '2', 2, 2, FALSE),
('The Lazy Susan', 'Person A lies on back. Person B on top, slowly spinning 360 degrees on their pivot point.', 'Urban Dictionary', '2', 4, 4, FALSE),
('The Crab Walk', 'Both people in crab position (face up, on hands and feet), moving toward each other.', 'Urban Dictionary', '2', 4, 3, FALSE),
('The Butter Churner', 'Person A on back with legs over head, hips straight up. Person B squats over top.', 'Urban Dictionary', '2', 5, 5, FALSE),
('The Amazon', 'Reverse of missionary - Person A on back, Person B on top but reversed so they face A''s feet.', 'Urban Dictionary', '2', 3, 4, FALSE),
('The Flatiron', 'Person A lies flat on stomach with pillow under hips. Person B lies on top from behind.', 'Urban Dictionary', '2', 2, 3, FALSE),
('The Seashell', 'Person A on back, knees pulled to chest. Person B leans over, pushing knees further.', 'Urban Dictionary', '2', 3, 4, FALSE),

-- ═══════════════════════════════════════════════════════════════════════════
-- GROUP POSITIONS (3+ actors)
-- ═══════════════════════════════════════════════════════════════════════════

('The Eiffel Tower', 'Person A on all fours in middle. Person B behind them. Person C in front. B and C high-five over A.', 'Group', '3', 2, 5, FALSE),
('The Spit Roast', 'Person A on all fours in middle. Person B at one end. Person C at other end. Facing inward.', 'Group', '3', 2, 5, FALSE),
('The Lucky Pierre', 'Three people in a line. Middle person (Pierre) faces person in front while person behind is behind them.', 'Group', '3', 3, 5, FALSE),
('The Daisy Chain', 'Three people in a circle, each person''s head at the next person''s pelvis forming a triangle.', 'Group', '3', 3, 5, FALSE),
('The Sandwich', 'Person A in middle. Person B in front facing them. Person C behind. A is the filling.', 'Group', '3', 2, 4, FALSE),
('The Train', 'Three people in a line, all facing the same direction, front to back.', 'Group', '3', 2, 5, FALSE),
('The Menage Stack', 'Three people stacked - Person A on bottom, B in middle, C on top. All aligned.', 'Group', '3', 3, 5, FALSE),
('The Triangle', 'Three people each connected to two others in a triangular formation, all facing center.', 'Group', '3', 3, 4, FALSE),
('The Throne Room', 'Person A seated like royalty. Person B kneeling at their front. Person C kneeling at their feet.', 'Group', '3', 2, 4, FALSE),
('The Human Centipede', 'Three people in a line, each on hands and knees, connected front-to-back.', 'Group', '3', 2, 4, FALSE),

-- 4-Person positions
('The Double Decker', 'Two pairs stacked. Bottom pair in missionary. Top pair in missionary on top of them.', 'Group', '4', 3, 5, FALSE),
('The Square Dance', 'Four people in a square, each connected to the person in front of them.', 'Group', '4', 4, 5, FALSE),
('The Four Corners', 'Four people, one in center on back. Other three at head, left, and right.', 'Group', '4', 3, 5, FALSE),
('The Orgy Circle', 'Four people in a circle, alternating face-up and face-down, forming a connected ring.', 'Group', '4', 4, 5, FALSE),
('The Plus Sign', 'Four people arranged in a + shape, heads meeting in center, bodies extending outward.', 'Group', '4', 3, 4, FALSE),

-- ═══════════════════════════════════════════════════════════════════════════
-- ACROBATIC (Requires strength/flexibility, 2 actors)
-- ═══════════════════════════════════════════════════════════════════════════

('The Stand and Carry', 'Person A wraps around Person B who is standing. B supports A entirely off the ground.', 'Acrobatic', '2', 4, 4, FALSE),
('The Shoulder Holder', 'Person A''s shoulders on ground, hips in air. Person B holds A''s hips up from standing.', 'Acrobatic', '2', 5, 5, FALSE),
('The Flying Dutchman', 'Person A horizontal in air, supported by Person B who is standing underneath.', 'Acrobatic', '2', 5, 4, FALSE),
('The Dancer', 'Person A stands on one leg, other leg raised to Person B''s shoulder. B stands facing.', 'Acrobatic', '2', 4, 3, FALSE),
('The Suspended Lotus', 'Lotus position but Person B is entirely lifted off the ground by Person A.', 'Acrobatic', '2', 5, 4, FALSE),
('The Headstand', 'Person A in a headstand. Person B stands facing, holding A''s legs for support.', 'Acrobatic', '2', 5, 4, FALSE),
('The Bridge of Sighs', 'Person A in gymnast bridge. Person B standing between their arched body.', 'Acrobatic', '2', 4, 4, FALSE),
('The Valedictorian', 'Person A does splits in the air. Person B holds them there by the waist.', 'Acrobatic', '2', 5, 4, FALSE),

-- ═══════════════════════════════════════════════════════════════════════════
-- TANTRIC (Slow, connected, spiritual)
-- ═══════════════════════════════════════════════════════════════════════════

('Yab-Yum', 'Person A sits cross-legged. Person B sits in lap facing them, foreheads touching.', 'Tantric', '2', 1, 2, TRUE),
('The Embrace', 'Both seated, facing each other, legs wrapped around each other, in a close embrace.', 'Tantric', '2', 1, 1, FALSE),
('The Soul Gaze', 'Both kneeling facing each other, hands on each other''s hearts, foreheads touching.', 'Tantric', '2', 1, 1, FALSE),
('Synchronized Breathing', 'Spooning position, both breathing in perfect sync, bodies aligned.', 'Tantric', '2', 1, 1, FALSE),
('The Melting Hug', 'Standing, Person A behind Person B, completely wrapped around them, slow swaying.', 'Tantric', '2', 1, 1, FALSE);

-- ═══════════════════════════════════════════════════════════════════════════
-- GRANTS
-- ═══════════════════════════════════════════════════════════════════════════

GRANT SELECT ON tag_drama_scene_cards TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE ON tag_drama_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON tag_drama_players TO authenticated;
GRANT SELECT, INSERT ON tag_drama_round_ratings TO authenticated;
GRANT EXECUTE ON FUNCTION generate_drama_room_code TO authenticated;
GRANT EXECUTE ON FUNCTION get_random_scene_card TO authenticated;
GRANT EXECUTE ON FUNCTION get_round_average_rating TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════════════════════

COMMENT ON TABLE tag_drama_scene_cards IS 'Scene cards with sexual position names and stick figure descriptions. Director must describe without naming body parts.';
COMMENT ON TABLE tag_drama_sessions IS 'Active Drama Sutra game sessions';
COMMENT ON TABLE tag_drama_players IS 'Players in sessions - track director/actor rotations and scores';
COMMENT ON TABLE tag_drama_round_ratings IS 'Per-round accuracy ratings from spectators (1-5)';
COMMENT ON COLUMN tag_drama_scene_cards.description IS 'Textual description of stick figure for accessibility and potential AI image generation';
COMMENT ON COLUMN tag_drama_scene_cards.stick_figure_svg IS 'Optional SVG markup for rendering stick figure illustration';
