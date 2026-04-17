-- ════════════════════════════════════════════════════════════════════════════
-- ENSURE CALENDAR EVENTS TABLE EXISTS
-- Migration 082: Idempotent guarantee that calendar_events table is present.
-- The table was originally defined in migration 009 but may not have been
-- applied to every environment. This migration is safe to run repeatedly.
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Create table (no-op if already exists from migration 009)
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    match_name TEXT,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    is_all_day BOOLEAN DEFAULT FALSE,
    external_calendar_id TEXT,
    external_calendar_source TEXT,
    ai_conflict_detected BOOLEAN DEFAULT FALSE,
    ai_conflict_reason TEXT,
    ai_suggestions TEXT[],
    status TEXT DEFAULT 'tentative',
    reminder_minutes INT[] DEFAULT ARRAY[60, 1440],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Indexes (IF NOT EXISTS — safe to re-run)
CREATE INDEX IF NOT EXISTS idx_calendar_events_user
    ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start
    ON public.calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date
    ON public.calendar_events(user_id, start_time);

-- 3. RLS
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- Drop-and-recreate policies so this migration is fully idempotent
DROP POLICY IF EXISTS "Users can view own calendar events" ON public.calendar_events;
CREATE POLICY "Users can view own calendar events" ON public.calendar_events
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own calendar events" ON public.calendar_events;
CREATE POLICY "Users can create own calendar events" ON public.calendar_events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own calendar events" ON public.calendar_events;
CREATE POLICY "Users can update own calendar events" ON public.calendar_events
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own calendar events" ON public.calendar_events;
CREATE POLICY "Users can delete own calendar events" ON public.calendar_events
    FOR DELETE USING (auth.uid() = user_id);

-- 4. Updated-at trigger
CREATE OR REPLACE FUNCTION public.update_calendar_event_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_calendar_events_updated_at ON public.calendar_events;
CREATE TRIGGER update_calendar_events_updated_at
    BEFORE UPDATE ON public.calendar_events
    FOR EACH ROW
    EXECUTE FUNCTION public.update_calendar_event_updated_at();

-- 5. Grant permissions
GRANT ALL ON public.calendar_events TO authenticated;
GRANT SELECT ON public.calendar_events TO anon;
