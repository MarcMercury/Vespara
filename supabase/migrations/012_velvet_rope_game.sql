-- ════════════════════════════════════════════════════════════════════════════
-- VELVET ROPE - The Spicy Truth or Dare
-- TAG Engine Signature Game
-- "Celestial Luxury" - Deep Obsidian, Ethereal Blue, Burning Crimson
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. VELVET ROPE CARDS TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.velvet_rope_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL CHECK (type IN ('truth', 'dare')),
    text TEXT NOT NULL,
    heat_level TEXT NOT NULL CHECK (heat_level IN ('PG', 'PG-13', 'R', 'X')),
    category TEXT NOT NULL CHECK (category IN ('icebreaker', 'physical', 'deep', 'kinky')),
    play_count INTEGER DEFAULT 0,
    skip_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for filtering by heat level (most common query)
CREATE INDEX IF NOT EXISTS idx_velvet_rope_heat ON public.velvet_rope_cards(heat_level);
CREATE INDEX IF NOT EXISTS idx_velvet_rope_type ON public.velvet_rope_cards(type);

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. VELVET ROPE SESSIONS TABLE (Analytics)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.velvet_rope_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    player_count INTEGER NOT NULL DEFAULT 2,
    heat_level TEXT NOT NULL DEFAULT 'PG',
    truths_completed INTEGER DEFAULT 0,
    dares_completed INTEGER DEFAULT 0,
    truths_skipped INTEGER DEFAULT 0,
    dares_skipped INTEGER DEFAULT 0,
    total_spins INTEGER DEFAULT 0,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER
);

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.velvet_rope_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.velvet_rope_sessions ENABLE ROW LEVEL SECURITY;

-- Cards are readable by all authenticated users
CREATE POLICY "velvet_rope_cards_select" ON public.velvet_rope_cards
    FOR SELECT TO authenticated USING (true);

-- Sessions are readable/writable by the host
CREATE POLICY "velvet_rope_sessions_insert" ON public.velvet_rope_sessions
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = host_user_id OR host_user_id IS NULL);

CREATE POLICY "velvet_rope_sessions_select" ON public.velvet_rope_sessions
    FOR SELECT TO authenticated USING (auth.uid() = host_user_id OR host_user_id IS NULL);

CREATE POLICY "velvet_rope_sessions_update" ON public.velvet_rope_sessions
    FOR UPDATE TO authenticated USING (auth.uid() = host_user_id OR host_user_id IS NULL);

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. HELPER FUNCTION: Get Shuffled Deck by Heat Level
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_velvet_rope_deck(
    p_max_heat TEXT DEFAULT 'PG',
    p_limit INTEGER DEFAULT 50
)
RETURNS SETOF public.velvet_rope_cards
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    heat_levels TEXT[];
BEGIN
    -- Build array of allowed heat levels based on max
    CASE p_max_heat
        WHEN 'PG' THEN heat_levels := ARRAY['PG'];
        WHEN 'PG-13' THEN heat_levels := ARRAY['PG', 'PG-13'];
        WHEN 'R' THEN heat_levels := ARRAY['PG', 'PG-13', 'R'];
        WHEN 'X' THEN heat_levels := ARRAY['PG', 'PG-13', 'R', 'X'];
        ELSE heat_levels := ARRAY['PG'];
    END CASE;

    RETURN QUERY
    SELECT *
    FROM public.velvet_rope_cards
    WHERE heat_level = ANY(heat_levels)
    ORDER BY RANDOM()
    LIMIT p_limit;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. SEED DATA - THE "SPICY" DATABASE
-- ═══════════════════════════════════════════════════════════════════════════

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ 🟢 GREEN / PG - Social & Flirtatious (Icebreakers)                      │
-- └─────────────────────────────────────────────────────────────────────────┘

INSERT INTO public.velvet_rope_cards (type, text, heat_level, category) VALUES
-- Truths
('truth', 'What is the most embarrassing thing in your search history right now?', 'PG', 'icebreaker'),
('truth', 'What''s your most irrational fear that you''ve never told anyone?', 'PG', 'icebreaker'),
('truth', 'If you could read anyone''s mind in this room for 60 seconds, whose would it be?', 'PG', 'icebreaker'),
('truth', 'What''s a compliment you want but never receive?', 'PG', 'deep'),
('truth', 'What song do you secretly listen to that would ruin your reputation?', 'PG', 'icebreaker'),
('truth', 'What''s the pettiest reason you stopped talking to someone?', 'PG', 'icebreaker'),
('truth', 'If your romantic history was a movie genre, what would it be?', 'PG', 'icebreaker'),
('truth', 'What''s a red flag you''ve ignored because the person was hot?', 'PG', 'deep'),
('truth', 'What celebrity would you absolutely not be able to act cool around?', 'PG', 'icebreaker'),
('truth', 'What''s the most unhinged thing you''ve done for a crush?', 'PG', 'icebreaker'),

-- Dares
('dare', 'Let the group DM your crush only using emojis.', 'PG', 'icebreaker'),
('dare', 'Talk with a fake accent for the next 2 rounds.', 'PG', 'icebreaker'),
('dare', 'Show the last 5 photos in your camera roll. No deleting.', 'PG', 'icebreaker'),
('dare', 'Let someone go through your Spotify/music history and judge you.', 'PG', 'icebreaker'),
('dare', 'Do your best impression of someone in this room until they guess who.', 'PG', 'icebreaker'),
('dare', 'Post a story asking "who wants to hang out tonight" and don''t explain.', 'PG', 'icebreaker'),
('dare', 'Text your ex "hey" and show the response when it comes.', 'PG', 'icebreaker'),
('dare', 'Let the group pick your profile photo for the next 24 hours.', 'PG', 'icebreaker'),
('dare', 'Give a dramatic reading of your last text conversation out loud.', 'PG', 'icebreaker'),
('dare', 'Do a fashion show walk across the room like you''re on a runway.', 'PG', 'physical'),

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ 🟡 YELLOW / PG-13 - Sensual & Suggestive                                │
-- └─────────────────────────────────────────────────────────────────────────┘

-- Truths
('truth', 'Describe your favorite way to be touched using only 3 adjectives.', 'PG-13', 'deep'),
('truth', 'What is a "vanilla" act that turns you on more than it should?', 'PG-13', 'deep'),
('truth', 'What''s the most attractive thing someone has ever done for you?', 'PG-13', 'deep'),
('truth', 'Describe your type without describing anyone in this room.', 'PG-13', 'icebreaker'),
('truth', 'What''s a fantasy you''re embarrassed to admit you have?', 'PG-13', 'deep'),
('truth', 'What''s the most romantic thing you''ve ever done for someone?', 'PG-13', 'deep'),
('truth', 'Rate every person in this room on a scale of 1-10. Be honest.', 'PG-13', 'icebreaker'),
('truth', 'What''s the longest you''ve gone without kissing someone and how did it end?', 'PG-13', 'deep'),
('truth', 'What physical feature do you get complimented on most?', 'PG-13', 'icebreaker'),
('truth', 'What''s your biggest turn-on that most people would find surprising?', 'PG-13', 'deep'),
('truth', 'Have you ever had a dream about someone in this room? Describe it.', 'PG-13', 'deep'),
('truth', 'What''s the most attractive thing about the person to your left?', 'PG-13', 'icebreaker'),

-- Dares
('dare', 'Give the person to your left a neck massage for 60 seconds. No talking.', 'PG-13', 'physical'),
('dare', 'Whisper something flirty into someone''s ear. They choose if they share it.', 'PG-13', 'physical'),
('dare', 'Let someone draw a heart anywhere on your body with their finger.', 'PG-13', 'physical'),
('dare', 'Make prolonged eye contact with someone for 60 seconds without laughing.', 'PG-13', 'physical'),
('dare', 'Slow dance with someone in the room for the duration of one song.', 'PG-13', 'physical'),
('dare', 'Let someone feed you something blindfolded. Trust them.', 'PG-13', 'physical'),
('dare', 'Give your best "bedroom eyes" to everyone in the room, one by one.', 'PG-13', 'physical'),
('dare', 'Describe in detail how you would seduce someone in this room.', 'PG-13', 'deep'),
('dare', 'Let someone brush or play with your hair for 2 minutes.', 'PG-13', 'physical'),
('dare', 'Send a voice note to someone confessing attraction. It can be a joke... or not.', 'PG-13', 'icebreaker'),
('dare', 'Put on a blindfold and identify 3 people by touch alone.', 'PG-13', 'physical'),
('dare', 'Let the group pose you and one other person for a "romantic movie poster."', 'PG-13', 'physical'),

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ 🔴 RED / R - Explicit & Erotic                                          │
-- └─────────────────────────────────────────────────────────────────────────┘

-- Truths
('truth', 'Detailed description: What is the best sexual experience you''ve ever had?', 'R', 'kinky'),
('truth', 'What''s your most unconventional turn-on that you''ve acted on?', 'R', 'kinky'),
('truth', 'Describe your ultimate fantasy scenario in vivid detail.', 'R', 'kinky'),
('truth', 'What''s something you''ve always wanted to try but haven''t found the right partner for?', 'R', 'kinky'),
('truth', 'What''s the kinkiest thing you''ve ever done? Spare no details.', 'R', 'kinky'),
('truth', 'If you could have a no-consequences night with anyone here, who and why?', 'R', 'deep'),
('truth', 'What''s your safe word and why did you choose it?', 'R', 'kinky'),
('truth', 'Describe a time you surprised yourself with how adventurous you were.', 'R', 'kinky'),
('truth', 'What''s a boundary you never thought you''d cross but did?', 'R', 'deep'),
('truth', 'Rate your own performance in bed on a scale of 1-10 and justify it.', 'R', 'kinky'),

-- Dares
('dare', 'Blindfold yourself and guess who is touching your neck.', 'R', 'physical'),
('dare', 'Sit on the lap of the person the wheel spins to next (if consenting).', 'R', 'physical'),
('dare', 'Remove one item of clothing and explain why you chose that one.', 'R', 'physical'),
('dare', 'Give someone a 2-minute massage wherever they request.', 'R', 'physical'),
('dare', 'Demonstrate your best move on a pillow. Make it convincing.', 'R', 'kinky'),
('dare', 'Let someone whisper a command in your ear. You must do it.', 'R', 'kinky'),
('dare', 'Trade one piece of clothing with someone of your choosing.', 'R', 'physical'),
('dare', 'Let someone leave a hickey on you in a visible location.', 'R', 'physical'),
('dare', 'Recreate the most sensual scene from a movie with someone willing.', 'R', 'kinky'),
('dare', 'Describe what you would do if you had 10 minutes alone with someone here.', 'R', 'kinky'),

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ ⚫ BLACK / X - Extreme (Affirmative Consent Required)                   │
-- └─────────────────────────────────────────────────────────────────────────┘

-- Truths
('truth', 'What is your absolute darkest fantasy that you''ve never told anyone?', 'X', 'kinky'),
('truth', 'Describe in explicit detail your ideal scenario with someone in this room.', 'X', 'kinky'),
('truth', 'What taboo have you broken that you don''t regret?', 'X', 'kinky'),
('truth', 'Rate everyone here on who you''d most want to... and describe why.', 'X', 'kinky'),
('truth', 'What''s the most explicit message you''ve ever sent? Read it aloud.', 'X', 'kinky'),

-- Dares
('dare', '[CONSENT CHECK] Remove clothing of someone else''s choosing - if they agree.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] 7 minutes in another room with someone willing.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Kiss someone passionately for 30 seconds.', 'X', 'physical'),
('dare', '[CONSENT CHECK] Let the group direct a scene between you and a partner.', 'X', 'kinky'),
('dare', '[CONSENT CHECK] Demonstrate your signature move on a willing participant.', 'X', 'kinky');

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. GRANT PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════════════

GRANT SELECT ON public.velvet_rope_cards TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.velvet_rope_sessions TO authenticated;
GRANT EXECUTE ON FUNCTION get_velvet_rope_deck TO authenticated;

-- Allow anon for demo mode
GRANT SELECT ON public.velvet_rope_cards TO anon;
GRANT EXECUTE ON FUNCTION get_velvet_rope_deck TO anon;
