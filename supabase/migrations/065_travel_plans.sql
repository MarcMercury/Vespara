-- ════════════════════════════════════════════════════════════════════════════
-- TRAVEL PLANS — Trip sharing, overlap detection, and travel-based matching
-- ════════════════════════════════════════════════════════════════════════════

-- Travel plans table
CREATE TABLE IF NOT EXISTS travel_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Trip info
  title TEXT NOT NULL,
  description TEXT,
  destination_city TEXT NOT NULL,
  destination_country TEXT,
  destination_lat DOUBLE PRECISION,
  destination_lng DOUBLE PRECISION,
  
  -- Dates
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_flexible BOOLEAN DEFAULT false,
  flexible_days INT DEFAULT 0,       -- ± days flexibility
  
  -- Certainty (reuses your PlanEvent enum)
  certainty TEXT NOT NULL DEFAULT 'tentative'
    CHECK (certainty IN ('locked', 'likely', 'tentative', 'exploring', 'wishful')),
  
  -- Visibility
  visibility TEXT NOT NULL DEFAULT 'connections'
    CHECK (visibility IN ('private', 'connections', 'friends', 'public')),
  
  -- Travel type
  travel_type TEXT DEFAULT 'leisure'
    CHECK (travel_type IN ('leisure', 'business', 'adventure', 'relocation', 'event', 'other')),
  
  -- Optional details
  accommodation TEXT,                -- hotel name, airbnb, etc.
  notes TEXT,
  cover_image_url TEXT,
  
  -- AI features
  ai_suggestions TEXT[],             -- AI-generated activity suggestions
  ai_match_score DOUBLE PRECISION,   -- How well this trip matches with others
  
  -- Status
  is_cancelled BOOLEAN DEFAULT false,
  is_completed BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Travel companions (who's joining this trip)
CREATE TABLE IF NOT EXISTS travel_companions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  travel_plan_id UUID NOT NULL REFERENCES travel_plans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'invited'
    CHECK (status IN ('invited', 'confirmed', 'maybe', 'declined')),
  invited_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  
  UNIQUE(travel_plan_id, user_id)
);

-- Travel overlap notifications (cached for performance)
CREATE TABLE IF NOT EXISTS travel_overlaps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_a_id UUID NOT NULL REFERENCES travel_plans(id) ON DELETE CASCADE,
  plan_b_id UUID NOT NULL REFERENCES travel_plans(id) ON DELETE CASCADE,
  user_a_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  overlap_start DATE NOT NULL,
  overlap_end DATE NOT NULL,
  distance_km DOUBLE PRECISION,      -- Distance between destinations
  is_same_city BOOLEAN DEFAULT false,
  notified_a BOOLEAN DEFAULT false,
  notified_b BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  
  UNIQUE(plan_a_id, plan_b_id)
);

-- Indexes
CREATE INDEX idx_travel_plans_user ON travel_plans(user_id);
CREATE INDEX idx_travel_plans_dates ON travel_plans(start_date, end_date);
CREATE INDEX idx_travel_plans_destination ON travel_plans(destination_city);
CREATE INDEX idx_travel_plans_certainty ON travel_plans(certainty) WHERE NOT is_cancelled;
CREATE INDEX idx_travel_plans_location ON travel_plans(destination_lat, destination_lng)
  WHERE destination_lat IS NOT NULL;
CREATE INDEX idx_travel_companions_user ON travel_companions(user_id);
CREATE INDEX idx_travel_companions_plan ON travel_companions(travel_plan_id);
CREATE INDEX idx_travel_overlaps_users ON travel_overlaps(user_a_id, user_b_id);

-- RLS Policies
ALTER TABLE travel_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE travel_companions ENABLE ROW LEVEL SECURITY;
ALTER TABLE travel_overlaps ENABLE ROW LEVEL SECURITY;

-- Travel plans: owner full access
CREATE POLICY travel_plans_owner ON travel_plans
  FOR ALL USING (auth.uid() = user_id);

-- Travel plans: visible to connections based on visibility
CREATE POLICY travel_plans_visible ON travel_plans
  FOR SELECT USING (
    visibility = 'public'
    OR (visibility = 'connections' AND EXISTS (
      SELECT 1 FROM roster_matches rm
      WHERE rm.pipeline = 'active'
      AND rm.is_archived = false
      AND ((rm.user_id = auth.uid() AND rm.match_user_id = travel_plans.user_id)
        OR (rm.match_user_id = auth.uid() AND rm.user_id = travel_plans.user_id))
    ))
    OR auth.uid() = user_id
  );

-- Travel companions: visible to plan owner and companion
CREATE POLICY travel_companions_access ON travel_companions
  FOR ALL USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM travel_plans tp WHERE tp.id = travel_plan_id AND tp.user_id = auth.uid()
    )
  );

-- Travel overlaps: visible to both users
CREATE POLICY travel_overlaps_access ON travel_overlaps
  FOR SELECT USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

-- ════════════════════════════════════════════════════════════════════════════
-- FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

-- Find travel overlaps for a user
CREATE OR REPLACE FUNCTION find_travel_overlaps(p_user_id UUID)
RETURNS TABLE (
  plan_id UUID,
  plan_title TEXT,
  plan_destination TEXT,
  plan_start DATE,
  plan_end DATE,
  overlap_user_id UUID,
  overlap_user_name TEXT,
  overlap_user_avatar TEXT,
  overlap_plan_id UUID,
  overlap_plan_title TEXT,
  overlap_plan_destination TEXT,
  overlap_plan_start DATE,
  overlap_plan_end DATE,
  overlap_start DATE,
  overlap_end DATE,
  distance_km DOUBLE PRECISION,
  is_same_city BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    my.id AS plan_id,
    my.title AS plan_title,
    my.destination_city AS plan_destination,
    my.start_date AS plan_start,
    my.end_date AS plan_end,
    their.user_id AS overlap_user_id,
    p.display_name AS overlap_user_name,
    p.avatar_url AS overlap_user_avatar,
    their.id AS overlap_plan_id,
    their.title AS overlap_plan_title,
    their.destination_city AS overlap_plan_destination,
    their.start_date AS overlap_plan_start,
    their.end_date AS overlap_plan_end,
    GREATEST(my.start_date, their.start_date) AS overlap_start,
    LEAST(my.end_date, their.end_date) AS overlap_end,
    CASE
      WHEN my.destination_lat IS NOT NULL AND their.destination_lat IS NOT NULL THEN
        -- Haversine distance in km
        6371 * acos(
          LEAST(1.0, cos(radians(my.destination_lat)) * cos(radians(their.destination_lat))
          * cos(radians(their.destination_lng) - radians(my.destination_lng))
          + sin(radians(my.destination_lat)) * sin(radians(their.destination_lat)))
        )
      ELSE NULL
    END AS distance_km,
    LOWER(my.destination_city) = LOWER(their.destination_city) AS is_same_city
  FROM travel_plans my
  CROSS JOIN LATERAL (
    SELECT tp.*
    FROM travel_plans tp
    WHERE tp.user_id != p_user_id
      AND NOT tp.is_cancelled
      AND tp.visibility IN ('connections', 'friends', 'public')
      AND tp.start_date <= my.end_date
      AND tp.end_date >= my.start_date
      -- Only show connections
      AND EXISTS (
        SELECT 1 FROM roster_matches rm
        WHERE rm.pipeline = 'active'
        AND rm.is_archived = false
        AND ((rm.user_id = p_user_id AND rm.match_user_id = tp.user_id)
          OR (rm.match_user_id = p_user_id AND rm.user_id = tp.user_id))
      )
  ) their
  JOIN profiles p ON p.id = their.user_id
  WHERE my.user_id = p_user_id
    AND NOT my.is_cancelled
  ORDER BY GREATEST(my.start_date, their.start_date);
END;
$$;

-- Get upcoming trips for a user's connections
CREATE OR REPLACE FUNCTION get_connection_trips(
  p_user_id UUID,
  p_limit INT DEFAULT 20
)
RETURNS TABLE (
  plan_id UUID,
  user_id UUID,
  user_name TEXT,
  user_avatar TEXT,
  title TEXT,
  destination_city TEXT,
  destination_country TEXT,
  destination_lat DOUBLE PRECISION,
  destination_lng DOUBLE PRECISION,
  start_date DATE,
  end_date DATE,
  certainty TEXT,
  travel_type TEXT,
  cover_image_url TEXT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    tp.id AS plan_id,
    tp.user_id,
    p.display_name AS user_name,
    p.avatar_url AS user_avatar,
    tp.title,
    tp.destination_city,
    tp.destination_country,
    tp.destination_lat,
    tp.destination_lng,
    tp.start_date,
    tp.end_date,
    tp.certainty,
    tp.travel_type,
    tp.cover_image_url
  FROM travel_plans tp
  JOIN profiles p ON p.id = tp.user_id
  WHERE NOT tp.is_cancelled
    AND tp.end_date >= CURRENT_DATE
    AND tp.visibility IN ('connections', 'friends', 'public')
    AND EXISTS (
      SELECT 1 FROM roster_matches rm
      WHERE rm.pipeline = 'active'
      AND rm.is_archived = false
      AND ((rm.user_id = p_user_id AND rm.match_user_id = tp.user_id)
        OR (rm.match_user_id = p_user_id AND rm.user_id = tp.user_id))
    )
  ORDER BY tp.start_date ASC
  LIMIT p_limit;
END;
$$;

-- Updated_at trigger
CREATE OR REPLACE TRIGGER travel_plans_updated_at
  BEFORE UPDATE ON travel_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
