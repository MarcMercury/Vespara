-- ═══════════════════════════════════════════════════════════════════════════
-- VESPARA PROJECT GENESIS: Master Seed File
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- CLEANUP COMMAND (Run this to wipe all test data):
-- DELETE FROM profiles WHERE last_name LIKE '%X';
-- DELETE FROM roster_matches WHERE id IN (SELECT id FROM roster_matches rm JOIN profiles p ON rm.match_user_id = p.id WHERE p.last_name LIKE '%X');
-- DELETE FROM messages WHERE sender_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X') OR receiver_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
-- DELETE FROM events WHERE created_by IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
-- DELETE FROM ludus_games WHERE id LIKE '%_v1';
--
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 3: TAGS GAME CONTENT (Tile 6)
-- ═══════════════════════════════════════════════════════════════════════════

-- Clear existing game content
DELETE FROM ludus_games WHERE id IN ('pleasure_deck_v1', 'path_pleasure_v1', 'truth_or_dare_v1', 'intimacy_builder_v1');
DELETE FROM ludus_cards WHERE game_id IN ('pleasure_deck_v1', 'path_pleasure_v1', 'truth_or_dare_v1', 'intimacy_builder_v1');

-- Insert: The Pleasure Deck
INSERT INTO ludus_games (id, name, description, category, min_consent_level, max_players, estimated_duration, cover_image, is_active)
VALUES (
  'pleasure_deck_v1',
  'The Pleasure Deck',
  'A sensual card game exploring desires, boundaries, and intimate connection. Draw cards, answer honestly, and discover new dimensions of pleasure together.',
  'sensual',
  'green',
  2,
  45,
  'https://images.unsplash.com/photo-1529543544277-750e2ea87789?w=400',
  true
);

-- Insert: Path of Pleasure
INSERT INTO ludus_games (id, name, description, category, min_consent_level, max_players, estimated_duration, cover_image, is_active)
VALUES (
  'path_pleasure_v1',
  'Path of Pleasure',
  'Rank intimate acts from mild to wild. Discover where your boundaries align and where they diverge. Perfect for exploring compatibility.',
  'ranking',
  'yellow',
  2,
  30,
  'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400',
  true
);

-- Insert: Truth or Dare (Elevated)
INSERT INTO ludus_games (id, name, description, category, min_consent_level, max_players, estimated_duration, cover_image, is_active)
VALUES (
  'truth_or_dare_v1',
  'Truth or Dare: Elevated',
  'The classic game, refined for adults. Deeper truths, bolder dares, absolute consent.',
  'interactive',
  'green',
  4,
  60,
  'https://images.unsplash.com/photo-1511988617509-a57c8a288659?w=400',
  true
);

-- Insert: Intimacy Builder
INSERT INTO ludus_games (id, name, description, category, min_consent_level, max_players, estimated_duration, cover_image, is_active)
VALUES (
  'intimacy_builder_v1',
  'Intimacy Builder',
  '36 questions scientifically designed to accelerate emotional intimacy. Based on Dr. Arthur Aron''s research.',
  'connection',
  'green',
  2,
  90,
  'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=400',
  true
);

-- ═══════════════════════════════════════════════════════════════════════════
-- PLEASURE DECK CARDS (30 Cards: 10 Green, 10 Yellow, 10 Red)
-- ═══════════════════════════════════════════════════════════════════════════

-- GREEN CARDS (Safe, Conversational)
INSERT INTO ludus_cards (game_id, consent_level, card_type, content, sort_order) VALUES
('pleasure_deck_v1', 'green', 'prompt', 'What is your favorite non-sexual sensation? Describe it in detail.', 1),
('pleasure_deck_v1', 'green', 'prompt', 'What song instantly puts you in a romantic mood?', 2),
('pleasure_deck_v1', 'green', 'prompt', 'Describe your ideal lazy Sunday morning with a partner.', 3),
('pleasure_deck_v1', 'green', 'prompt', 'What compliment do you secretly wish you received more often?', 4),
('pleasure_deck_v1', 'green', 'prompt', 'What''s the most romantic gesture you''ve ever witnessed?', 5),
('pleasure_deck_v1', 'green', 'prompt', 'If you could relive one perfect kiss from your life, which would it be?', 6),
('pleasure_deck_v1', 'green', 'prompt', 'What scent immediately makes you think of intimacy?', 7),
('pleasure_deck_v1', 'green', 'prompt', 'Describe a time when someone''s voice alone gave you chills.', 8),
('pleasure_deck_v1', 'green', 'prompt', 'What''s one thing you find attractive that most people might not?', 9),
('pleasure_deck_v1', 'green', 'prompt', 'What does "feeling safe" with a partner look like to you?', 10),

-- YELLOW CARDS (Suggestive, Boundary-Testing)
('pleasure_deck_v1', 'yellow', 'prompt', 'Describe a time you felt incredibly turned on but couldn''t do anything about it.', 11),
('pleasure_deck_v1', 'yellow', 'prompt', 'What''s your most unexpected erogenous zone?', 12),
('pleasure_deck_v1', 'yellow', 'prompt', 'Have you ever had a dream about someone you shouldn''t have? Describe the feeling.', 13),
('pleasure_deck_v1', 'yellow', 'prompt', 'What''s something you''ve always wanted to try but never asked for?', 14),
('pleasure_deck_v1', 'yellow', 'prompt', 'Describe the perfect build-up to intimacy. What creates anticipation for you?', 15),
('pleasure_deck_v1', 'yellow', 'prompt', 'What''s the boldest thing you''ve done to get someone''s attention?', 16),
('pleasure_deck_v1', 'yellow', 'prompt', 'If you could design the perfect date night that ends in the bedroom, what happens first?', 17),
('pleasure_deck_v1', 'yellow', 'prompt', 'What words or phrases instantly shift your mood from casual to charged?', 18),
('pleasure_deck_v1', 'yellow', 'prompt', 'Describe a fantasy you''ve never told anyone about.', 19),
('pleasure_deck_v1', 'yellow', 'prompt', 'What''s the difference between "hot" and "intimate" to you?', 20),

-- RED CARDS (Explicit, Action-Oriented)
('pleasure_deck_v1', 'red', 'action', 'Blindfold your partner and trace a path on their body using only your fingertips. Let them guess where you''ll go next.', 21),
('pleasure_deck_v1', 'red', 'action', 'Whisper your deepest desire directly into your partner''s ear. Don''t break eye contact after.', 22),
('pleasure_deck_v1', 'red', 'action', 'Take turns being in complete control for exactly 2 minutes each. The other must comply with any request.', 23),
('pleasure_deck_v1', 'red', 'action', 'Kiss your partner somewhere you''ve never kissed them before. Explain why you chose that spot.', 24),
('pleasure_deck_v1', 'red', 'action', 'Describe exactly what you want to do to your partner right now. Be specific. Then do it.', 25),
('pleasure_deck_v1', 'red', 'action', 'Use only your lips to communicate what you want for the next 60 seconds. No words allowed.', 26),
('pleasure_deck_v1', 'red', 'action', 'Choose one item from this room to incorporate into the next 5 minutes. Get creative.', 27),
('pleasure_deck_v1', 'red', 'action', 'Take a photo of this moment (for your eyes only). Describe why you''ll remember it.', 28),
('pleasure_deck_v1', 'red', 'action', 'Role reversal: For the next round, you are them and they are you. Match their energy exactly.', 29),
('pleasure_deck_v1', 'red', 'action', 'The safeword is "pause." Use it or don''t. But know it''s there. Now, surprise each other.', 30);

-- ═══════════════════════════════════════════════════════════════════════════
-- PATH OF PLEASURE: Ranking Items
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO ludus_cards (game_id, consent_level, card_type, content, sort_order) VALUES
('path_pleasure_v1', 'yellow', 'ranking', 'Holding Hands in Public', 1),
('path_pleasure_v1', 'yellow', 'ranking', 'Public Kissing', 2),
('path_pleasure_v1', 'yellow', 'ranking', 'Neck Biting', 3),
('path_pleasure_v1', 'yellow', 'ranking', 'Sensory Deprivation', 4),
('path_pleasure_v1', 'yellow', 'ranking', 'Dirty Talk', 5),
('path_pleasure_v1', 'yellow', 'ranking', 'Role Playing', 6),
('path_pleasure_v1', 'yellow', 'ranking', 'Light Bondage', 7),
('path_pleasure_v1', 'yellow', 'ranking', 'Exhibition/Voyeurism', 8),
('path_pleasure_v1', 'yellow', 'ranking', 'Power Exchange', 9),
('path_pleasure_v1', 'yellow', 'ranking', 'Group Dynamics', 10),
('path_pleasure_v1', 'yellow', 'ranking', 'Tantric Practices', 11),
('path_pleasure_v1', 'yellow', 'ranking', 'Location Adventures', 12);

-- ═══════════════════════════════════════════════════════════════════════════
-- TRUTH OR DARE: ELEVATED
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO ludus_cards (game_id, consent_level, card_type, content, sort_order) VALUES
-- Truths (Green)
('truth_or_dare_v1', 'green', 'truth', 'What''s the most embarrassing thing you''ve Googled about relationships?', 1),
('truth_or_dare_v1', 'green', 'truth', 'Have you ever faked being busy to avoid someone you were dating?', 2),
('truth_or_dare_v1', 'green', 'truth', 'What''s your biggest relationship dealbreaker that might surprise people?', 3),
('truth_or_dare_v1', 'green', 'truth', 'Who in this room would you trust with your phone for 24 hours?', 4),
('truth_or_dare_v1', 'green', 'truth', 'What''s the wildest thing on your bucket list?', 5),
-- Dares (Green)
('truth_or_dare_v1', 'green', 'dare', 'Send a voice note to someone here saying something you''ve always meant to tell them.', 6),
('truth_or_dare_v1', 'green', 'dare', 'Let the group compose a message on your dating app and send it.', 7),
('truth_or_dare_v1', 'green', 'dare', 'Do your best impression of someone in this room. We guess who.', 8),
('truth_or_dare_v1', 'green', 'dare', 'Share the last photo you took and explain the context.', 9),
('truth_or_dare_v1', 'green', 'dare', 'Make direct eye contact with one person for 60 seconds. No talking.', 10),
-- Truths (Yellow)
('truth_or_dare_v1', 'yellow', 'truth', 'What''s the most spontaneous romantic thing you''ve ever done?', 11),
('truth_or_dare_v1', 'yellow', 'truth', 'Describe your type in excruciating detail.', 12),
('truth_or_dare_v1', 'yellow', 'truth', 'What''s something you pretend not to like but secretly love?', 13),
-- Dares (Yellow)
('truth_or_dare_v1', 'yellow', 'dare', 'Give someone in this room a 30-second massage. They choose where.', 14),
('truth_or_dare_v1', 'yellow', 'dare', 'Demonstrate your go-to flirting technique on someone here.', 15);

-- ═══════════════════════════════════════════════════════════════════════════
-- INTIMACY BUILDER: 36 Questions
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO ludus_cards (game_id, consent_level, card_type, content, sort_order) VALUES
-- Set 1: Getting to Know You
('intimacy_builder_v1', 'green', 'prompt', 'Given the choice of anyone in the world, whom would you want as a dinner guest?', 1),
('intimacy_builder_v1', 'green', 'prompt', 'Would you like to be famous? In what way?', 2),
('intimacy_builder_v1', 'green', 'prompt', 'Before making a phone call, do you ever rehearse what you''re going to say? Why?', 3),
('intimacy_builder_v1', 'green', 'prompt', 'What would constitute a "perfect" day for you?', 4),
('intimacy_builder_v1', 'green', 'prompt', 'When did you last sing to yourself? To someone else?', 5),
('intimacy_builder_v1', 'green', 'prompt', 'If you were able to live to the age of 90 and retain either the mind or body of a 30-year-old for the last 60 years, which would you want?', 6),
('intimacy_builder_v1', 'green', 'prompt', 'Do you have a secret hunch about how you will die?', 7),
('intimacy_builder_v1', 'green', 'prompt', 'Name three things you and your partner appear to have in common.', 8),
('intimacy_builder_v1', 'green', 'prompt', 'For what in your life do you feel most grateful?', 9),
('intimacy_builder_v1', 'green', 'prompt', 'If you could change anything about the way you were raised, what would it be?', 10),
('intimacy_builder_v1', 'green', 'prompt', 'Take four minutes and tell your partner your life story in as much detail as possible.', 11),
('intimacy_builder_v1', 'green', 'prompt', 'If you could wake up tomorrow having gained any one quality or ability, what would it be?', 12),
-- Set 2: Going Deeper
('intimacy_builder_v1', 'green', 'prompt', 'If a crystal ball could tell you the truth about yourself, your life, the future, or anything else, what would you want to know?', 13),
('intimacy_builder_v1', 'green', 'prompt', 'Is there something that you''ve dreamed of doing for a long time? Why haven''t you done it?', 14),
('intimacy_builder_v1', 'green', 'prompt', 'What is the greatest accomplishment of your life?', 15),
('intimacy_builder_v1', 'green', 'prompt', 'What do you value most in a friendship?', 16),
('intimacy_builder_v1', 'green', 'prompt', 'What is your most treasured memory?', 17),
('intimacy_builder_v1', 'green', 'prompt', 'What is your most terrible memory?', 18),
('intimacy_builder_v1', 'green', 'prompt', 'If you knew that in one year you would die suddenly, would you change anything about the way you are now living? Why?', 19),
('intimacy_builder_v1', 'green', 'prompt', 'What does friendship mean to you?', 20),
('intimacy_builder_v1', 'green', 'prompt', 'What roles do love and affection play in your life?', 21),
('intimacy_builder_v1', 'green', 'prompt', 'Alternate sharing something you consider a positive characteristic of your partner. Share a total of five items.', 22),
('intimacy_builder_v1', 'green', 'prompt', 'How close and warm is your family? Do you feel your childhood was happier than most other people''s?', 23),
('intimacy_builder_v1', 'green', 'prompt', 'How do you feel about your relationship with your mother?', 24),
-- Set 3: Deep Connection
('intimacy_builder_v1', 'green', 'prompt', 'Make three true "we" statements each. For instance, "We are both in this room feeling..."', 25),
('intimacy_builder_v1', 'green', 'prompt', 'Complete this sentence: "I wish I had someone with whom I could share..."', 26),
('intimacy_builder_v1', 'green', 'prompt', 'If you were going to become a close friend with your partner, please share what would be important for them to know.', 27),
('intimacy_builder_v1', 'green', 'prompt', 'Tell your partner what you like about them; be very honest, saying things that you might not say to someone you''ve just met.', 28),
('intimacy_builder_v1', 'green', 'prompt', 'Share with your partner an embarrassing moment in your life.', 29),
('intimacy_builder_v1', 'green', 'prompt', 'When did you last cry in front of another person? By yourself?', 30),
('intimacy_builder_v1', 'green', 'prompt', 'Tell your partner something that you like about them already.', 31),
('intimacy_builder_v1', 'green', 'prompt', 'What, if anything, is too serious to be joked about?', 32),
('intimacy_builder_v1', 'green', 'prompt', 'If you were to die this evening with no opportunity to communicate with anyone, what would you most regret not having told someone? Why haven''t you told them yet?', 33),
('intimacy_builder_v1', 'green', 'prompt', 'Your house, containing everything you own, catches fire. After saving your loved ones and pets, you have time to safely make a final dash to save any one item. What would it be? Why?', 34),
('intimacy_builder_v1', 'green', 'prompt', 'Of all the people in your family, whose death would you find most disturbing? Why?', 35),
('intimacy_builder_v1', 'green', 'prompt', 'Share a personal problem and ask your partner''s advice on how they might handle it. Also, ask your partner to reflect back to you how you seem to be feeling about the problem you have chosen.', 36);

-- ═══════════════════════════════════════════════════════════════════════════
-- VERIFICATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Verify game content was inserted
DO $$
BEGIN
  RAISE NOTICE 'Games inserted: %', (SELECT COUNT(*) FROM ludus_games WHERE id LIKE '%_v1');
  RAISE NOTICE 'Cards inserted: %', (SELECT COUNT(*) FROM ludus_cards WHERE game_id LIKE '%_v1');
END $$;
