-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║         MIGRATION 075: FIX EVENTS RLS CROSS-TABLE RECURSION               ║
-- ║                                                                           ║
-- ║   Root cause: vespara_events SELECT policy checks vespara_event_rsvps,    ║
-- ║   and vespara_event_rsvps SELECT policy checks vespara_events.            ║
-- ║   This cross-reference causes PostgreSQL error 42P17.                     ║
-- ║                                                                           ║
-- ║   Fix: SECURITY DEFINER helper functions with row_security = off          ║
-- ║   to break the recursion cycle, same pattern as migration 063/074.        ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════════════════
-- 1. SECURITY DEFINER HELPER FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

-- Check if user can access an event (host, cohost, RSVP'd, or public)
CREATE OR REPLACE FUNCTION public.can_access_event(evt_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.vespara_events e
    WHERE e.id = evt_id
      AND (
        e.visibility = 'public'
        OR e.host_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM public.event_cohosts ec
          WHERE ec.event_id = evt_id AND ec.user_id = auth.uid()
        )
        OR EXISTS (
          SELECT 1 FROM public.vespara_event_rsvps r
          WHERE r.event_id = evt_id AND r.user_id = auth.uid()
        )
      )
  );
$$;

-- Check if user is event host
CREATE OR REPLACE FUNCTION public.is_event_host(evt_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.vespara_events e
    WHERE e.id = evt_id AND e.host_id = auth.uid()
  );
$$;

-- Check if user is an accepted cohost for an event
CREATE OR REPLACE FUNCTION public.is_event_cohost(evt_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.event_cohosts ec
    WHERE ec.event_id = evt_id
      AND ec.user_id = auth.uid()
      AND ec.status = 'accepted'
  );
$$;

GRANT EXECUTE ON FUNCTION public.can_access_event(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_event_host(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_event_cohost(UUID) TO authenticated;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. DROP ALL EXISTING EVENTS POLICIES
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "vespara_events_select" ON public.vespara_events;
DROP POLICY IF EXISTS "vespara_events_insert" ON public.vespara_events;
DROP POLICY IF EXISTS "vespara_events_update" ON public.vespara_events;
DROP POLICY IF EXISTS "vespara_events_delete" ON public.vespara_events;

DROP POLICY IF EXISTS "vespara_event_rsvps_select" ON public.vespara_event_rsvps;
DROP POLICY IF EXISTS "vespara_event_rsvps_insert" ON public.vespara_event_rsvps;
DROP POLICY IF EXISTS "vespara_event_rsvps_update" ON public.vespara_event_rsvps;
DROP POLICY IF EXISTS "vespara_event_rsvps_delete" ON public.vespara_event_rsvps;

DROP POLICY IF EXISTS "event_cohosts_select" ON public.event_cohosts;
DROP POLICY IF EXISTS "event_cohosts_insert" ON public.event_cohosts;
DROP POLICY IF EXISTS "event_cohosts_update" ON public.event_cohosts;
DROP POLICY IF EXISTS "event_cohosts_delete" ON public.event_cohosts;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. RECREATE VESPARA_EVENTS POLICIES (recursion-free)
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.vespara_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vespara_events_select" ON public.vespara_events
    FOR SELECT TO authenticated
    USING (public.can_access_event(id));

CREATE POLICY "vespara_events_insert" ON public.vespara_events
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = host_id);

CREATE POLICY "vespara_events_update" ON public.vespara_events
    FOR UPDATE TO authenticated
    USING (
        auth.uid() = host_id
        OR public.is_event_cohost(id)
    );

CREATE POLICY "vespara_events_delete" ON public.vespara_events
    FOR DELETE TO authenticated
    USING (auth.uid() = host_id);

-- ════════════════════════════════════════════════════════════════════════════
-- 4. RECREATE VESPARA_EVENT_RSVPS POLICIES (recursion-free)
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.vespara_event_rsvps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vespara_event_rsvps_select" ON public.vespara_event_rsvps
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid()
        OR public.is_event_host(event_id)
        OR public.is_event_cohost(event_id)
    );

CREATE POLICY "vespara_event_rsvps_insert" ON public.vespara_event_rsvps
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid()
        OR public.is_event_host(event_id)
        OR public.is_event_cohost(event_id)
    );

CREATE POLICY "vespara_event_rsvps_update" ON public.vespara_event_rsvps
    FOR UPDATE TO authenticated
    USING (
        user_id = auth.uid()
        OR public.is_event_host(event_id)
    );

CREATE POLICY "vespara_event_rsvps_delete" ON public.vespara_event_rsvps
    FOR DELETE TO authenticated
    USING (
        user_id = auth.uid()
        OR public.is_event_host(event_id)
    );

-- ════════════════════════════════════════════════════════════════════════════
-- 5. RECREATE EVENT_COHOSTS POLICIES (recursion-free)
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.event_cohosts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "event_cohosts_select" ON public.event_cohosts
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid()
        OR public.is_event_host(event_id)
    );

CREATE POLICY "event_cohosts_insert" ON public.event_cohosts
    FOR INSERT TO authenticated
    WITH CHECK (public.is_event_host(event_id));

CREATE POLICY "event_cohosts_update" ON public.event_cohosts
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "event_cohosts_delete" ON public.event_cohosts
    FOR DELETE TO authenticated
    USING (public.is_event_host(event_id));

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
