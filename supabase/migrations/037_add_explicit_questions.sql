-- ════════════════════════════════════════════════════════════════════════════
-- MIGRATION 037: Add Explicit Questions to Ice Breakers and Velvet Rope
-- Adds new adult-oriented questions to both games
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- ICE BREAKERS - Add new questions (high intensity)
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO ice_breaker_cards (prompt, card_type, target_type, category, intensity) VALUES
-- Sexual Experience Questions
('What''s the most adventurous sex act you''ve ever tried?', 'standard', 'single', 'reveal', 4),
('What''s the most intimate thing you''ve ever shared with a partner?', 'standard', 'single', 'reveal', 3),
('What''s the biggest sex-related lie you''ve ever told?', 'standard', 'single', 'reveal', 4),
('What''s the most spontaneous sex you''ve ever had?', 'standard', 'single', 'reveal', 4),
('What''s the most embarrassing sex-related story you''ve ever shared with someone?', 'standard', 'single', 'reveal', 3),
('What''s the biggest turn-on for you?', 'standard', 'single', 'reveal', 3),
('What''s the most intense orgasm you''ve ever had?', 'standard', 'single', 'reveal', 5),
('What''s the most unusual place you''ve ever had sex?', 'standard', 'single', 'reveal', 4),
('What''s the biggest sex-related fantasy you''ve ever had?', 'standard', 'single', 'reveal', 4),
('What''s the most memorable sex-related dream you''ve ever had?', 'standard', 'single', 'reveal', 3),
('What''s your favorite sex position?', 'standard', 'single', 'reveal', 4),
('What''s your favorite BDSM role (dom, sub, switch)?', 'standard', 'single', 'reveal', 4),
('What''s the most extreme BDSM experience you''ve ever had?', 'standard', 'single', 'reveal', 5),
('What''s the most intense pain you''ve ever experienced during sex?', 'standard', 'single', 'reveal', 5),
('What''s the most creative way you''ve ever used bondage?', 'standard', 'single', 'reveal', 5),
('What''s the most intense sensory experience you''ve ever had during sex?', 'standard', 'single', 'reveal', 4),
('What''s the most extreme fetish you''ve ever explored?', 'standard', 'single', 'reveal', 5),
('What''s the most intense breathplay experience you''ve ever had?', 'standard', 'single', 'reveal', 5),
('What''s the most intense sensory deprivation experience you''ve ever had?', 'standard', 'single', 'reveal', 5),
('What''s the most intense impact play experience you''ve ever had?', 'standard', 'single', 'reveal', 5),
('What''s the most intense rope bondage experience you''ve ever had?', 'standard', 'single', 'reveal', 5),

-- Intimacy & Trust Questions
('What''s the most intimate thing you''ve ever shared with a stranger?', 'standard', 'single', 'reveal', 4),
('What''s the most intense emotional connection you''ve felt with someone?', 'standard', 'single', 'reveal', 3),
('What''s the most unusual thing you''ve done to get someone to agree to sex?', 'standard', 'single', 'reveal', 4),
('What''s the most creative way you''ve ever seduced someone?', 'standard', 'single', 'reveal', 4),
('What''s the most intense moment of vulnerability you''ve experienced with someone?', 'standard', 'single', 'reveal', 3),
('What''s the most unusual thing you''ve done to get out of a sex-related situation?', 'standard', 'single', 'reveal', 4),
('What''s the most intense moment of intimacy you''ve experienced with someone?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual thing you''ve done to build intimacy with someone?', 'standard', 'single', 'reveal', 3),
('What''s the most intense moment of trust you''ve experienced with someone?', 'standard', 'single', 'reveal', 3),
('What''s the most unusual thing you''ve done to build trust with someone?', 'standard', 'single', 'reveal', 3),

-- Fantasy Questions
('What''s the most intense sex-related fantasy you''ve ever had?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual sex-related fantasy you''ve ever had?', 'standard', 'single', 'reveal', 4),
('What''s the most intense sex-related dream you''ve ever had?', 'standard', 'single', 'reveal', 4),
('What''s the most memorable sex-related experience you''ve ever had?', 'standard', 'single', 'reveal', 4),
('What''s your favorite sex-related fantasy?', 'standard', 'single', 'reveal', 4),

-- Experience with Different Settings
('What''s the most intense sex-related experience with a stranger?', 'standard', 'single', 'reveal', 5),
('What''s the most unusual sex-related experience you''ve had?', 'standard', 'single', 'reveal', 4),
('What''s the most intense sex-related experience with a partner?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual sex-related experience with a partner?', 'standard', 'single', 'reveal', 4),
('What''s the most intense sex-related experience with a group?', 'standard', 'single', 'reveal', 5),
('What''s the most intense sex-related experience in a public place?', 'standard', 'single', 'reveal', 5),
('What''s the most unusual sex-related experience in a public place?', 'standard', 'single', 'reveal', 5),
('What''s the most intense sex-related experience with a stranger in a public place?', 'standard', 'single', 'reveal', 5),
('What''s the most intense sex-related experience with a partner in a public place?', 'standard', 'single', 'reveal', 5),
('What''s the most intense sex-related experience in a private setting?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual sex-related experience in a private setting?', 'standard', 'single', 'reveal', 4),
('What''s the most intense sex-related experience with a stranger in a private setting?', 'standard', 'single', 'reveal', 5),
('What''s the most unusual sex-related experience with a stranger in a private setting?', 'standard', 'single', 'reveal', 5),

-- BDSM Specific
('What''s your favorite BDSM toy or prop?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual BDSM experience you''ve ever had?', 'standard', 'single', 'reveal', 5),
('What''s the most intense BDSM scene you''ve ever participated in?', 'standard', 'single', 'reveal', 5),
('What''s the most unusual BDSM scene you''ve ever participated in?', 'standard', 'single', 'reveal', 5),
('What''s the most intense BDSM experience with a partner?', 'standard', 'single', 'reveal', 5),
('What''s the most unusual BDSM experience with a partner?', 'standard', 'single', 'reveal', 5),
('What''s the most intense BDSM experience with a group?', 'standard', 'single', 'reveal', 5),
('What''s the most unusual BDSM experience with a group?', 'standard', 'single', 'reveal', 5),
('What''s the most intense BDSM experience with a stranger?', 'standard', 'single', 'reveal', 5),

-- Partner Communication Questions
('What''s the most intimate conversation you''ve had with a partner?', 'standard', 'single', 'reveal', 3),
('What''s the most intense moment of conflict with a partner?', 'standard', 'single', 'reveal', 3),
('What''s the most unusual way you''ve communicated with a partner?', 'standard', 'single', 'reveal', 3),
('What''s the most intense moment of intimacy with a partner?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual way you''ve built intimacy with a partner?', 'standard', 'single', 'reveal', 3),
('What''s the most intense moment of trust with a partner?', 'standard', 'single', 'reveal', 3),
('What''s the most unusual way you''ve built trust with a partner?', 'standard', 'single', 'reveal', 3),
('What''s the most intense moment of vulnerability with a partner?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual way you''ve shared vulnerability with a partner?', 'standard', 'single', 'reveal', 3),
('What''s the most intense emotional connection with a partner?', 'standard', 'single', 'reveal', 4),

-- Sex & Relationship Communication
('What''s the most intimate conversation with a partner about sex?', 'standard', 'single', 'reveal', 4),
('What''s the most intense conflict with a partner about sex?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual way you''ve communicated about sex with a partner?', 'standard', 'single', 'reveal', 4),
('What''s the most intense moment of intimacy with a partner about sex?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual way you''ve built intimacy with a partner about sex?', 'standard', 'single', 'reveal', 4),
('What''s the most intense moment of trust with a partner about sex?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual way you''ve built trust with a partner about sex?', 'standard', 'single', 'reveal', 4),
('What''s the most intense vulnerability with a partner about sex?', 'standard', 'single', 'reveal', 4),
('What''s the most unusual way you''ve shared vulnerability with a partner about sex?', 'standard', 'single', 'reveal', 4),
('What''s the most intense emotional connection with a partner about sex?', 'standard', 'single', 'reveal', 4),

-- Relationship Communication
('What''s the most intimate conversation about relationships?', 'standard', 'single', 'reveal', 3),
('What''s the most intense conflict about relationships?', 'standard', 'single', 'reveal', 3),
('What''s the most unusual way you''ve communicated about relationships?', 'standard', 'single', 'reveal', 3),
('What''s the most intense intimacy about relationships?', 'standard', 'single', 'reveal', 3),
('What''s the most unusual way you''ve built intimacy about relationships?', 'standard', 'single', 'reveal', 3),
('What''s the most intense trust about relationships?', 'standard', 'single', 'reveal', 3),
('What''s the most unusual way you''ve built trust about relationships?', 'standard', 'single', 'reveal', 3),
('What''s the most intense vulnerability about relationships?', 'standard', 'single', 'reveal', 3),
('What''s the most unusual way you''ve shared vulnerability about relationships?', 'standard', 'single', 'reveal', 3),
('What''s the most intense emotional connection about relationships?', 'standard', 'single', 'reveal', 3);

-- ═══════════════════════════════════════════════════════════════════════════
-- VELVET ROPE (Share or Dare) - Add new SHARE questions
-- ═══════════════════════════════════════════════════════════════════════════

-- R-Rated Shares (Explicit)
INSERT INTO velvet_rope_cards (type, text, heat_level, category) VALUES
('share', 'What''s the most adventurous sex act you''ve ever tried?', 'R', 'kinky'),
('share', 'What''s the most intimate thing you''ve ever shared with a partner?', 'R', 'deep'),
('share', 'What''s the biggest sex-related lie you''ve ever told?', 'R', 'deep'),
('share', 'What''s the most spontaneous sex you''ve ever had?', 'R', 'kinky'),
('share', 'What''s the most embarrassing sex-related story you''ve ever shared?', 'R', 'deep'),
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
('share', 'What''s the most intense moment of vulnerability with someone?', 'R', 'deep'),
('share', 'What''s the most intense moment of trust with someone?', 'R', 'deep'),
('share', 'What''s the most memorable sex-related experience you''ve ever had?', 'R', 'kinky'),
('share', 'What''s your favorite sex-related fantasy?', 'R', 'kinky'),
('share', 'What''s the most intimate conversation with a partner about sex?', 'R', 'deep'),
('share', 'What''s the most intense emotional connection with a partner about sex?', 'R', 'deep'),

-- X-Rated Shares (Extreme)
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
('share', 'What''s the most intense sex-related experience in a public place?', 'X', 'kinky'),
('share', 'What''s the most intense sex-related experience with a stranger in a public place?', 'X', 'kinky'),
('share', 'What''s your favorite BDSM toy or prop?', 'X', 'kinky'),
('share', 'What''s the most intense BDSM scene you''ve ever participated in?', 'X', 'kinky'),
('share', 'What''s the most intense BDSM experience with a partner?', 'X', 'kinky'),
('share', 'What''s the most intense BDSM experience with a group?', 'X', 'kinky'),
('share', 'What''s the most intense BDSM experience with a stranger?', 'X', 'kinky');
