-- ============================================================================
-- Migration 055: Fix Share or Dare Heat Level Selection
-- Cards should match the selected heat level, not include all lower levels
-- When users select X-rated, they expect X-rated content, not PG content
-- ============================================================================

-- ============================================================================
-- STEP 1: Update the get_share_or_dare_deck function
-- Now returns ONLY cards at the selected heat level
-- ============================================================================

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
BEGIN
  -- Return ONLY cards at the selected heat level
  -- This ensures X-rated games get X-rated content, not PG content
  RETURN QUERY
  SELECT 
    c.id,
    c.type,
    c.text,
    c.heat_level,
    c.category
  FROM public.share_or_dare_cards c
  WHERE c.heat_level = p_max_heat
  ORDER BY RANDOM()
  LIMIT p_limit;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_share_or_dare_deck(TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_share_or_dare_deck(TEXT, INT) TO anon;

-- ============================================================================
-- Done! Share or Dare now returns only cards matching the selected heat level
-- ============================================================================
