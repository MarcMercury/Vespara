-- ============================================
-- VESPARA CALENDAR EVENTS TABLE
-- Migration 009: Calendar events for The Planner
-- ============================================

-- ============================================
-- 1. CALENDAR EVENTS TABLE
-- ============================================

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
    external_calendar_source TEXT, -- 'google', 'apple', 'outlook'
    ai_conflict_detected BOOLEAN DEFAULT FALSE,
    ai_conflict_reason TEXT,
    ai_suggestions TEXT[],
    status TEXT DEFAULT 'tentative', -- 'tentative', 'confirmed', 'cancelled'
    reminder_minutes INT[] DEFAULT ARRAY[60, 1440],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_calendar_events_user 
    ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start 
    ON public.calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date 
    ON public.calendar_events(user_id, start_time);

-- ============================================
-- 2. ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- Users can view their own calendar events
CREATE POLICY "Users can view own calendar events" ON public.calendar_events
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own calendar events
CREATE POLICY "Users can create own calendar events" ON public.calendar_events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own calendar events
CREATE POLICY "Users can update own calendar events" ON public.calendar_events
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own calendar events
CREATE POLICY "Users can delete own calendar events" ON public.calendar_events
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 3. UPDATED_AT TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION update_calendar_event_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_calendar_events_updated_at
    BEFORE UPDATE ON public.calendar_events
    FOR EACH ROW
    EXECUTE FUNCTION update_calendar_event_updated_at();

-- ============================================
-- 4. ENHANCED EVENTS TABLE (Add missing columns)
-- ============================================

-- Add cost and visibility columns to events table
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS cost_per_person DECIMAL(10,2);
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS requires_approval BOOLEAN DEFAULT FALSE;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS collect_guest_info BOOLEAN DEFAULT FALSE;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS send_reminders BOOLEAN DEFAULT TRUE;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS cover_image_url TEXT;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS title_style TEXT DEFAULT 'classic';
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS end_time TIMESTAMPTZ;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS venue_address TEXT;
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS host_name TEXT;

-- ============================================
-- 5. EVENT RSVPS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.event_rsvps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'invited', -- 'invited', 'going', 'maybe', 'cant_go'
    user_name TEXT,
    user_avatar_url TEXT,
    response_message TEXT,
    added_to_calendar BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_event_rsvps_event ON public.event_rsvps(event_id);
CREATE INDEX IF NOT EXISTS idx_event_rsvps_user ON public.event_rsvps(user_id);
CREATE INDEX IF NOT EXISTS idx_event_rsvps_status ON public.event_rsvps(event_id, status);

ALTER TABLE public.event_rsvps ENABLE ROW LEVEL SECURITY;

-- Users can view RSVPs for events they can see
CREATE POLICY "Users can view event RSVPs" ON public.event_rsvps
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.events e 
            WHERE e.id = event_id 
            AND (e.host_id = auth.uid() OR e.is_private = false)
        )
    );

-- Users can manage their own RSVPs
CREATE POLICY "Users can manage own RSVPs" ON public.event_rsvps
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 6. GRANTS
-- ============================================

GRANT ALL ON public.calendar_events TO authenticated;
GRANT ALL ON public.event_rsvps TO authenticated;
