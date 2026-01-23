-- ============================================================================
-- Migration 038: Rename Velvet Rope to Share or Dare
-- Renames all velvet_rope tables, indexes, policies, and functions to share_or_dare
-- ============================================================================

-- ============================================================================
-- STEP 1: Rename Tables
-- ============================================================================

-- Rename velvet_rope_cards to share_or_dare_cards
ALTER TABLE IF EXISTS public.velvet_rope_cards RENAME TO share_or_dare_cards;

-- Rename velvet_rope_sessions to share_or_dare_sessions  
ALTER TABLE IF EXISTS public.velvet_rope_sessions RENAME TO share_or_dare_sessions;

-- ============================================================================
-- STEP 2: Rename Indexes
-- ============================================================================

-- Rename indexes on share_or_dare_cards
ALTER INDEX IF EXISTS idx_velvet_rope_heat RENAME TO idx_share_or_dare_heat;
ALTER INDEX IF EXISTS idx_velvet_rope_type RENAME TO idx_share_or_dare_type;

-- ============================================================================
-- STEP 3: Rename RLS Policies
-- ============================================================================

-- Drop old policies and create new ones for share_or_dare_cards
DROP POLICY IF EXISTS "velvet_rope_cards_select" ON public.share_or_dare_cards;
CREATE POLICY "share_or_dare_cards_select" ON public.share_or_dare_cards
  FOR SELECT TO authenticated USING (true);

-- Drop old policies and create new ones for share_or_dare_sessions
DROP POLICY IF EXISTS "velvet_rope_sessions_insert" ON public.share_or_dare_sessions;
DROP POLICY IF EXISTS "velvet_rope_sessions_select" ON public.share_or_dare_sessions;

CREATE POLICY "share_or_dare_sessions_insert" ON public.share_or_dare_sessions
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "share_or_dare_sessions_select" ON public.share_or_dare_sessions
  FOR SELECT TO authenticated USING (true);

-- ============================================================================
-- STEP 4: Rename or Recreate Functions
-- ============================================================================

-- Drop old function
DROP FUNCTION IF EXISTS get_velvet_rope_deck(TEXT, INT);

-- Create new function with new name
CREATE OR REPLACE FUNCTION get_share_or_dare_deck(
  p_max_heat TEXT DEFAULT 'PG',
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  type TEXT,
  text TEXT,
  heat_level TEXT,
  category TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  allowed_levels TEXT[];
BEGIN
  -- Determine allowed heat levels based on max
  CASE p_max_heat
    WHEN 'X' THEN allowed_levels := ARRAY['PG', 'PG-13', 'R', 'X'];
    WHEN 'R' THEN allowed_levels := ARRAY['PG', 'PG-13', 'R'];
    WHEN 'PG-13' THEN allowed_levels := ARRAY['PG', 'PG-13'];
    ELSE allowed_levels := ARRAY['PG'];
  END CASE;
  
  RETURN QUERY
  SELECT 
    c.id,
    c.type,
    c.text,
    c.heat_level,
    c.category
  FROM public.share_or_dare_cards c
  WHERE c.heat_level = ANY(allowed_levels)
  ORDER BY RANDOM()
  LIMIT p_limit;
END;
$$;

-- ============================================================================
-- STEP 5: Update TagGameType enum references in analytics
-- ============================================================================

-- Update game_stats JSONB default value
DO $$
BEGIN
  -- Update any existing analytics entries that reference velvet_rope
  UPDATE public.tag_unified_analytics
  SET game_stats = jsonb_set(
    game_stats - 'velvet_rope',
    '{share_or_dare}',
    COALESCE(game_stats->'velvet_rope', '0'::jsonb)
  )
  WHERE game_stats ? 'velvet_rope';
  
  -- Update any achievements referencing velvet_rope
  UPDATE public.tag_achievements
  SET game_type = 'share_or_dare'
  WHERE game_type = 'velvet_rope';
  
EXCEPTION WHEN OTHERS THEN
  -- Ignore errors if tables don't exist
  NULL;
END $$;

-- ============================================================================
-- STEP 6: Grant permissions
-- ============================================================================

GRANT SELECT ON public.share_or_dare_cards TO authenticated;
GRANT SELECT, INSERT ON public.share_or_dare_sessions TO authenticated;
GRANT EXECUTE ON FUNCTION get_share_or_dare_deck(TEXT, INT) TO authenticated;

-- ============================================================================
-- Done! Velvet Rope is now Share or Dare everywhere
-- ============================================================================
