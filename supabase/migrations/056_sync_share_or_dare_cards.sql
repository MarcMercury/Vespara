-- ============================================================================
-- Migration 056: Sync Share or Dare Cards - Full Database Update
-- Ensures DB and Demo mode have identical content with proper ratings
-- ============================================================================

-- Clear existing cards first (before constraint changes)
TRUNCATE TABLE public.share_or_dare_cards;

-- Now drop the old constraint that may have wrong name
ALTER TABLE public.share_or_dare_cards DROP CONSTRAINT IF EXISTS velvet_rope_cards_type_check;
ALTER TABLE public.share_or_dare_cards DROP CONSTRAINT IF EXISTS share_or_dare_cards_type_check;

-- Re-add the type constraint with correct name  
ALTER TABLE public.share_or_dare_cards ADD CONSTRAINT share_or_dare_cards_type_check CHECK (type IN ('share', 'dare'));

-- ============================================================================
-- 🟢 PG (SOCIAL) - SHARES
-- ============================================================================
INSERT INTO public.share_or_dare_cards (type, text, heat_level, category) VALUES
('share', 'Share the most embarrassing thing in your search history right now.', 'PG', 'icebreaker'),
('share', 'Share your most irrational fear that you''ve never told anyone.', 'PG', 'icebreaker'),
('share', 'Share a secret talent that nobody in this room knows about.', 'PG', 'icebreaker'),
('share', 'Share a compliment you desperately want but never receive.', 'PG', 'deep'),
('share', 'Share a guilty pleasure song that would absolutely ruin your reputation.', 'PG', 'icebreaker'),
('share', 'Share the pettiest reason you stopped talking to someone.', 'PG', 'icebreaker'),
('share', 'Share what movie genre best describes your romantic history—and why.', 'PG', 'icebreaker'),
('share', 'Share a red flag you ignored because the person was just that attractive.', 'PG', 'deep'),
('share', 'Share a celebrity encounter that would make you completely lose your cool.', 'PG', 'icebreaker'),
('share', 'Share the most unhinged thing you''ve ever done for a crush.', 'PG', 'icebreaker');

-- ============================================================================
-- 🟢 PG (SOCIAL) - DARES
-- ============================================================================
INSERT INTO public.share_or_dare_cards (type, text, heat_level, category) VALUES
('dare', 'Let the group DM your crush only using emojis.', 'PG', 'icebreaker'),
('dare', 'Talk with a fake accent for the next 2 rounds.', 'PG', 'icebreaker'),
('dare', 'Show the last 5 photos in your camera roll. No deleting.', 'PG', 'icebreaker'),
('dare', 'Let someone go through your Spotify/music history and judge you.', 'PG', 'icebreaker'),
('dare', 'Do your best impression of someone in this room until they guess who.', 'PG', 'icebreaker'),
('dare', 'Post a story asking "who wants to hang out tonight" and don''t explain.', 'PG', 'icebreaker'),
('dare', 'Text your ex "hey" and show the response when it comes.', 'PG', 'icebreaker'),
('dare', 'Let the group pick your profile photo for the next 24 hours.', 'PG', 'icebreaker'),
('dare', 'Give a dramatic reading of your last text conversation out loud.', 'PG', 'icebreaker'),
('dare', 'Do a fashion show walk across the room like you''re on a runway.', 'PG', 'physical');

-- ============================================================================
-- 🟡 PG-13 (SENSUAL) - SHARES
-- ============================================================================
INSERT INTO public.share_or_dare_cards (type, text, heat_level, category) VALUES
('share', 'Share your favorite way to be touched—describe it in 3 adjectives.', 'PG-13', 'deep'),
('share', 'Share a "vanilla" act that secretly turns you on more than it should.', 'PG-13', 'deep'),
('share', 'Share the most attractive thing someone has ever done for you.', 'PG-13', 'deep'),
('share', 'Share your type without describing anyone in this room.', 'PG-13', 'icebreaker'),
('share', 'Share a fantasy you''re embarrassed to admit you have.', 'PG-13', 'deep'),
('share', 'Share the most romantic gesture you''ve ever made for someone.', 'PG-13', 'deep'),
('share', 'Share your honest rating of everyone in this room on a scale of 1-10.', 'PG-13', 'icebreaker'),
('share', 'Share the longest you''ve gone without kissing someone—and how that drought ended.', 'PG-13', 'deep'),
('share', 'Share which physical feature you get complimented on the most.', 'PG-13', 'icebreaker'),
('share', 'Share your biggest turn-on that would surprise most people.', 'PG-13', 'deep'),
('share', 'Share a dream you''ve had about someone in this room—spare no details.', 'PG-13', 'deep'),
('share', 'Share the most attractive thing about the person to your left.', 'PG-13', 'icebreaker');

-- ============================================================================
-- 🟡 PG-13 (SENSUAL) - DARES
-- ============================================================================
INSERT INTO public.share_or_dare_cards (type, text, heat_level, category) VALUES
('dare', 'Give the person to your left a neck massage for 60 seconds. No talking.', 'PG-13', 'physical'),
('dare', 'Whisper something flirty into someone''s ear. They choose if they share it.', 'PG-13', 'physical'),
('dare', 'Let someone draw a heart anywhere on your body with their finger.', 'PG-13', 'physical'),
('dare', 'Make prolonged eye contact with someone for 30 seconds without laughing.', 'PG-13', 'physical'),
('dare', 'Slow dance with someone in the room for half a song.', 'PG-13', 'physical'),
('dare', 'Let someone feed you something blindfolded. Trust them.', 'PG-13', 'physical'),
('dare', 'Give your best "bedroom eyes" to everyone in the room, one by one.', 'PG-13', 'physical'),
('dare', 'Describe in detail how you would seduce someone in this room.', 'PG-13', 'deep'),
('dare', 'Let someone brush or play with your hair for 2 minutes.', 'PG-13', 'physical'),
('dare', 'Send a voice note to someone confessing attraction. It can be a joke... or not.', 'PG-13', 'icebreaker'),
('dare', 'Put on a blindfold and identify 3 people by touch alone.', 'PG-13', 'physical'),
('dare', 'Let the group pose you and one other person for a "romantic movie poster."', 'PG-13', 'physical'),
('dare', 'Without kissing them, gently press your lips to another player and hold for 15 seconds.', 'PG-13', 'physical'),
('dare', 'Massage the inner thigh of another player for 20 seconds.', 'PG-13', 'physical'),
('dare', 'Caress the chest of another player very gently.', 'PG-13', 'physical');

-- ============================================================================
-- 🔴 R (EXPLICIT) - SHARES
-- ============================================================================
INSERT INTO public.share_or_dare_cards (type, text, heat_level, category) VALUES
('share', 'Share the best sexual experience you''ve ever had—in vivid detail.', 'R', 'kinky'),
('share', 'Share your most unconventional turn-on that you''ve actually acted on.', 'R', 'kinky'),
('share', 'Share your ultimate fantasy scenario—paint the picture vividly.', 'R', 'kinky'),
('share', 'Share something you''ve always wanted to try but haven''t found the right partner for.', 'R', 'kinky'),
('share', 'Share the kinkiest thing you''ve ever done—spare no details.', 'R', 'kinky'),
('share', 'Share who you''d choose for a no-consequences night here—and why them.', 'R', 'deep'),
('share', 'Share your safe word and the story behind why you chose it.', 'R', 'kinky'),
('share', 'Share a time you completely surprised yourself with how adventurous you were.', 'R', 'kinky'),
('share', 'Share a boundary you never thought you''d cross—but did anyway.', 'R', 'deep'),
('share', 'Share your honest self-rating in bed on a scale of 1-10—and justify it.', 'R', 'kinky'),
('share', 'What''s the most adventurous sex act you''ve ever tried?', 'R', 'kinky'),
('share', 'What''s the most intimate thing you''ve ever shared with a partner?', 'R', 'deep'),
('share', 'What''s the biggest sex-related lie you''ve ever told?', 'R', 'deep'),
('share', 'What''s the most spontaneous sex you''ve ever had?', 'R', 'kinky'),
('share', 'What''s the most embarrassing sex-related story you''ve shared with someone?', 'R', 'deep'),
('share', 'What''s the biggest turn-on for you?', 'R', 'kinky'),
('share', 'What''s the most intense orgasm you''ve ever had?', 'R', 'kinky'),
('share', 'What''s the most unusual place you''ve ever had sex?', 'R', 'kinky'),
('share', 'What''s the biggest sex-related fantasy you''ve ever had?', 'R', 'kinky'),
('share', 'What''s the most memorable sex-related dream you''ve ever had?', 'R', 'kinky'),
('share', 'What''s your favorite sex position?', 'R', 'kinky'),
('share', 'What''s your favorite BDSM role (dom, sub, switch)?', 'R', 'kinky'),
('share', 'What''s the most creative way you''ve ever seduced someone?', 'R', 'deep'),
('share', 'What''s the most intimate thing you''ve ever shared with a stranger?', 'R', 'deep'),
('share', 'What''s the most intense emotional connection you''ve felt with someone?', 'R', 'deep'),
('share', 'What''s the most memorable sex-related experience you''ve ever had?', 'R', 'kinky'),
('share', 'What''s the most intimate conversation with a partner about sex?', 'R', 'deep'),
('share', 'What''s the most intense moment of trust with a partner?', 'R', 'deep'),
('share', 'What''s the most intense vulnerability with a partner?', 'R', 'deep'),
('share', 'What''s the most intense emotional connection with a partner?', 'R', 'deep');

-- ============================================================================
-- 🔴 R (EXPLICIT) - DARES
-- ============================================================================
INSERT INTO public.share_or_dare_cards (type, text, heat_level, category) VALUES
('dare', 'Blindfold yourself and guess who is kissing your neck.', 'R', 'physical'),
('dare', 'Sit on the lap of the person the wheel spins to next (if consenting).', 'R', 'physical'),
('dare', 'Remove one item of clothing and explain why you chose that one.', 'R', 'physical'),
('dare', 'Give someone a 2-minute massage wherever they request.', 'R', 'physical'),
('dare', 'Demonstrate your best move on a pillow. Make it convincing.', 'R', 'kinky'),
('dare', 'Let someone whisper a command in your ear. You must do it.', 'R', 'kinky'),
('dare', 'Trade one piece of clothing with someone of your choosing.', 'R', 'physical'),
('dare', 'Let someone leave a hickey on you in a visible location.', 'R', 'physical'),
('dare', 'Recreate the most sensual scene from a movie with someone willing.', 'R', 'kinky'),
('dare', 'Describe what you would do if you had 10 minutes alone with someone here.', 'R', 'kinky'),
('dare', 'Motorboat a female in the group.', 'R', 'physical'),
('dare', 'Select 2 players and direct them in a make out scene.', 'R', 'physical'),
('dare', 'Crawl under the table (or just crawl) and choose a player to massage the crotch of.', 'R', 'physical'),
('dare', 'Lick the armpit of another player.', 'R', 'physical'),
('dare', '3 Way French Kiss with 2 other players.', 'R', 'physical'),
('dare', 'Without penetrating or grabbing - place your hands down the pants and under the underwear of another player.', 'R', 'physical');

-- ============================================================================
-- ⚫ X (EXTREME) - SHARES
-- ============================================================================
INSERT INTO public.share_or_dare_cards (type, text, heat_level, category) VALUES
('share', 'Share your absolute darkest fantasy—the one you''ve never told a soul.', 'X', 'kinky'),
('share', 'Share in explicit detail your ideal scenario with someone in this room.', 'X', 'kinky'),
('share', 'Share a taboo you''ve broken that you absolutely don''t regret.', 'X', 'kinky'),
('share', 'Share who in this room you''d most want to... and describe exactly why.', 'X', 'kinky'),
('share', 'Share the most explicit message you''ve ever sent—read it aloud now.', 'X', 'kinky'),
('share', 'What''s the most extreme BDSM experience you''ve ever had?', 'X', 'kinky'),
('share', 'What''s the most intense pain you''ve experienced during sex?', 'X', 'kinky'),
('share', 'What''s the most creative way you''ve ever used bondage?', 'X', 'kinky'),
('share', 'What''s the most intense sensory experience during sex?', 'X', 'kinky'),
('share', 'What''s the most extreme fetish you''ve ever explored?', 'X', 'kinky'),
('share', 'What''s the most intense breathplay experience you''ve ever had?', 'X', 'kinky'),
('share', 'What''s the most intense sensory deprivation experience during sex?', 'X', 'kinky'),
('share', 'What''s the most intense impact play experience you''ve ever had?', 'X', 'kinky'),
('share', 'What''s the most intense rope bondage experience you''ve ever had?', 'X', 'kinky'),
('share', 'What''s the most intense sex-related experience with a stranger?', 'X', 'kinky'),
('share', 'What''s the most intense sex-related experience with a group?', 'X', 'kinky'),
('share', 'What''s the most intense sex experience in a public place?', 'X', 'kinky'),
('share', 'What''s your favorite BDSM toy or prop?', 'X', 'kinky'),
('share', 'What''s the most intense BDSM scene you''ve participated in?', 'X', 'kinky'),
('share', 'What''s the most intense BDSM experience with a partner?', 'X', 'kinky'),
('share', 'What''s the most intense BDSM experience with a group?', 'X', 'kinky'),
('share', 'What''s the most intense BDSM experience with a stranger?', 'X', 'kinky'),
('share', 'What''s the most unusual thing you''ve done to get someone to agree to sex?', 'X', 'kinky');

-- ============================================================================
-- ⚫ X (EXTREME) - DARES (with user edits applied)
-- ============================================================================
INSERT INTO public.share_or_dare_cards (type, text, heat_level, category) VALUES
-- 1) Edited
('dare', 'Let 2 other players remove all your clothing.', 'X', 'kinky'),
-- 2) Edited
('dare', '3 minutes in another room naked with another player.', 'X', 'kinky'),
-- 3) Keep original
('dare', 'Kiss someone passionately for 30 seconds.', 'X', 'physical'),
-- 4) Edited
('dare', 'Let the group direct a sex scene between you and another player.', 'X', 'kinky'),
-- 5) Edited
('dare', 'Demonstrate your signature sex move/act on another player.', 'X', 'kinky'),
-- 6) Strip Tease
('dare', 'Strip Tease: Slowly do a strip tease for the group (must get down to underwear). Group chooses the song.', 'X', 'physical'),
-- 7) Lap Dance
('dare', 'Lap Dance: Give a lap dance to 2 people at the same time. Group chooses the song.', 'X', 'physical'),
-- 8) Edited - Body Massage
('dare', 'In your underwear only, give another player a body massage using only your body (no hands).', 'X', 'physical'),
-- 9) Blindfolded Kiss
('dare', 'Blindfolded Kiss: Blindfold 2 other players and give them each a 1-minute kiss.', 'X', 'kinky'),
-- 10) Threeway Kiss
('dare', 'Threeway Kiss: Give a 1-minute tongue kiss to 2 other players at the same time.', 'X', 'kinky'),
-- 11) Finger Play
('dare', 'Finger Play: Give 2 other players a 1-minute finger play session.', 'X', 'kinky'),
-- 12) Threeway 69
('dare', 'Threeway 69: Pick 2 people and figure out a 696 or 969 position together.', 'X', 'kinky'),
-- 13) Edited - Foot Play
('dare', 'Give one player an X-rated foot play session.', 'X', 'kinky'),
-- 14) Edited - Oral Play (single)
('dare', 'Oral Play: Give one player oral play for 1-2 minutes.', 'X', 'kinky'),
-- 15) Nipple Play
('dare', 'Nipple Play: Give 2 other players a 1-minute nipple play session.', 'X', 'kinky'),
-- 16) Anal Play
('dare', 'Anal Play: Give 2 other players a 1-minute anal play session.', 'X', 'kinky'),
-- 17) Edited - Oral Threesome
('dare', 'Oral Threesome: Pick 2 players and do an oral play train for 1-2 minutes.', 'X', 'kinky'),
-- 18) Sensual Lick
('dare', 'Sensual Lick: Sensually lick anywhere on another player''s body of your choosing.', 'X', 'kinky'),
-- 19) Strip Tease (receive)
('dare', 'Strip Tease: Choose 2 people to give you a strip tease, one item at a time.', 'X', 'physical'),
-- 20) Lap Dance (receive)
('dare', 'Lap Dance: Choose 2 people to give you a lap dance at the same time. Group chooses the song.', 'X', 'physical'),
-- 21) Edited - Strip Massage
('dare', 'Strip and let 2 players massage you however they want for 2 minutes.', 'X', 'physical'),
-- 22) Edited - Blindfold Make Out
('dare', 'Blindfold yourself, and let the group secretly choose 2 people to make out with you for 2 minutes.', 'X', 'kinky'),
-- 23) Threeway Kiss (receive)
('dare', 'Threeway Kiss: Choose 2 people to give you a 1-minute tongue kiss at the same time.', 'X', 'kinky'),
-- 24) Finger Play (receive)
('dare', 'Finger Play: Choose 2 people to give you a 1-minute finger play session.', 'X', 'kinky'),
-- 25) REMOVED - Threeway 69 (receive)
-- 26) Feet Play (receive)
('dare', 'Feet Play: Choose 2 people to give you a 1-minute feet play session.', 'X', 'kinky'),
-- 27) REMOVED - Cuddle (receive)
-- 28) Nipple Play (receive)
('dare', 'Nipple Play: Choose 2 people to give you a 1-minute nipple play session.', 'X', 'kinky'),
-- 29) Anal Play (receive)
('dare', 'Anal Play: Choose 2 people to give you a 1-minute anal play session.', 'X', 'kinky'),
-- 30) Oral Play (receive)
('dare', 'Oral Play: Choose 2 people to give you a 1-minute oral play session.', 'X', 'kinky'),
-- 31) Sensual Lick (receive)
('dare', 'Sensual Lick: Choose 2 people to sensually lick anywhere on your body.', 'X', 'kinky');
-- 32) REMOVED - Sensual Squeeze

-- ============================================================================
-- Grant permissions
-- ============================================================================
GRANT SELECT ON public.share_or_dare_cards TO authenticated;
GRANT SELECT ON public.share_or_dare_cards TO anon;

-- ============================================================================
-- Done! All Share or Dare cards are now synced with Demo mode
-- ============================================================================
