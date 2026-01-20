-- ════════════════════════════════════════════════════════════════════════════
-- TAG GAMES - Compound Indexes for Performance Optimization
-- Migration 022: Add missing compound indexes across all TAG games
-- ════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- DOWN TO CLOWN (DTC) INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

-- Compound index for heat level filtering with active check
CREATE INDEX IF NOT EXISTS idx_dtc_prompts_heat_active 
ON dtc_prompts(heat_level, is_active);

-- Compound index for category + heat filtering
CREATE INDEX IF NOT EXISTS idx_dtc_prompts_category_heat 
ON dtc_prompts(category, heat_level, is_active);

-- Compound index for difficulty filtering
CREATE INDEX IF NOT EXISTS idx_dtc_prompts_difficulty_heat 
ON dtc_prompts(difficulty, heat_level, is_active);

-- ═══════════════════════════════════════════════════════════════════════════
-- ICE BREAKERS INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

-- Compound index for intensity filtering with active check
CREATE INDEX IF NOT EXISTS idx_ice_breaker_cards_intensity_active 
ON ice_breaker_cards(intensity, is_active) 
WHERE is_active = true;

-- Compound index for card type + intensity
CREATE INDEX IF NOT EXISTS idx_ice_breaker_cards_type_intensity 
ON ice_breaker_cards(card_type, intensity, is_active);

-- ═══════════════════════════════════════════════════════════════════════════
-- VELVET ROPE (SHARE OR DARE) INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

-- Compound index for type + heat level filtering (most common query)
CREATE INDEX IF NOT EXISTS idx_velvet_rope_type_heat 
ON velvet_rope_cards(type, heat_level);

-- Compound index for category + heat level
CREATE INDEX IF NOT EXISTS idx_velvet_rope_category_heat 
ON velvet_rope_cards(category, heat_level);

-- ═══════════════════════════════════════════════════════════════════════════
-- PATH OF PLEASURE (POP) INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

-- Compound index for active cards sorted by popularity
CREATE INDEX IF NOT EXISTS idx_pop_cards_active_rank 
ON pop_cards(is_active, global_rank DESC) 
WHERE is_active = true;

-- Compound index for heat level + popularity
CREATE INDEX IF NOT EXISTS idx_pop_cards_heat_popularity 
ON pop_cards(heat_level, popularity_score DESC, is_active);

-- Session room code lookup (frequently queried)
CREATE INDEX IF NOT EXISTS idx_pop_sessions_room_active 
ON pop_sessions(room_code, state) 
WHERE state IN ('lobby', 'ranking', 'reveal');

-- Player lookups by session
CREATE INDEX IF NOT EXISTS idx_pop_players_session 
ON pop_players(session_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- LANE OF LUST INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

-- Compound index for desire level filtering
CREATE INDEX IF NOT EXISTS idx_lane_cards_desire 
ON tag_lane_cards(desire_index);

-- Compound index for category + desire
CREATE INDEX IF NOT EXISTS idx_lane_cards_category_desire 
ON tag_lane_cards(category, desire_index);

-- Session room code lookup
CREATE INDEX IF NOT EXISTS idx_lane_sessions_room_state 
ON tag_lane_sessions(room_code, state) 
WHERE state IN ('lobby', 'dealing', 'playing');

-- Player lookups by session
CREATE INDEX IF NOT EXISTS idx_lane_players_session 
ON tag_lane_players(session_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- DRAMA-SUTRA INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

-- Session room code lookup
CREATE INDEX IF NOT EXISTS idx_drama_sessions_room_state 
ON tag_drama_sessions(room_code, state);

-- Player lookups by session
CREATE INDEX IF NOT EXISTS idx_drama_players_session 
ON tag_drama_players(session_id);

-- Round ratings lookup (for leaderboard queries)
CREATE INDEX IF NOT EXISTS idx_drama_ratings_session_round 
ON tag_drama_round_ratings(session_id, round_number);

-- ═══════════════════════════════════════════════════════════════════════════
-- CROSS-GAME ANALYTICS INDEXES (Preparation for future analytics table)
-- ═══════════════════════════════════════════════════════════════════════════

-- Note: These will be used when tag_analytics table is created

-- Prepare for user activity queries across all games
-- (Commented out until tag_analytics table exists)
-- CREATE INDEX IF NOT EXISTS idx_tag_analytics_user_game 
-- ON tag_analytics(user_id, game_type, created_at DESC);

-- CREATE INDEX IF NOT EXISTS idx_tag_analytics_event_type 
-- ON tag_analytics(event_type, game_type, created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- GRANT PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Indexes don't require explicit grants as they work transparently with table access

-- ═══════════════════════════════════════════════════════════════════════════
-- ANALYZE TABLES FOR QUERY PLANNER
-- ═══════════════════════════════════════════════════════════════════════════

-- Refresh statistics for query planner optimization
ANALYZE dtc_prompts;
ANALYZE ice_breaker_cards;
ANALYZE velvet_rope_cards;
ANALYZE pop_cards;
ANALYZE pop_sessions;
ANALYZE pop_players;
ANALYZE tag_lane_cards;
ANALYZE tag_lane_sessions;
ANALYZE tag_lane_players;
ANALYZE tag_drama_scene_cards;
ANALYZE tag_drama_sessions;
ANALYZE tag_drama_players;
ANALYZE tag_drama_round_ratings;
