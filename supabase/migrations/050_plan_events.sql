-- ═══════════════════════════════════════════════════════════════════════════
-- PLANNER EVENTS TABLE
-- Stores user-created events for THE PLAN module
-- ═══════════════════════════════════════════════════════════════════════════

-- Create plan_events table
CREATE TABLE IF NOT EXISTS plan_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    notes TEXT,
    location TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,  -- Nullable to match Dart model
    certainty TEXT NOT NULL DEFAULT 'tentative' CHECK (certainty IN ('tentative', 'likely', 'locked', 'exploring', 'wishful')),
    connections JSONB DEFAULT '[]'::jsonb,
    is_from_experience BOOLEAN DEFAULT FALSE,
    experience_host_name TEXT,
    is_hosting BOOLEAN DEFAULT FALSE,
    is_cancelled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_plan_events_user_id ON plan_events(user_id);
CREATE INDEX IF NOT EXISTS idx_plan_events_start_time ON plan_events(start_time);
CREATE INDEX IF NOT EXISTS idx_plan_events_user_start ON plan_events(user_id, start_time);

-- Enable RLS
ALTER TABLE plan_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can read their own events
CREATE POLICY "Users can read own events"
    ON plan_events FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create their own events
CREATE POLICY "Users can create own events"
    ON plan_events FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own events
CREATE POLICY "Users can update own events"
    ON plan_events FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own events
CREATE POLICY "Users can delete own events"
    ON plan_events FOR DELETE
    USING (auth.uid() = user_id);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_plan_events_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER plan_events_updated_at
    BEFORE UPDATE ON plan_events
    FOR EACH ROW
    EXECUTE FUNCTION update_plan_events_updated_at();

-- Grant permissions
GRANT ALL ON plan_events TO authenticated;
GRANT SELECT ON plan_events TO anon;
