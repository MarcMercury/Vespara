-- Migration 073: Fix references to non-existent 'interests' column
-- The column was renamed to 'interest_tags' in migration 029 but some
-- database functions still reference the old name.

-- Fix get_popular_interests() to use correct column name
CREATE OR REPLACE FUNCTION get_popular_interests(p_limit INT DEFAULT 10)
RETURNS TABLE (interest TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT unnest(interest_tags) as interest
    FROM profiles
    WHERE interest_tags IS NOT NULL AND array_length(interest_tags, 1) > 0
    GROUP BY interest
    ORDER BY COUNT(*) DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;
