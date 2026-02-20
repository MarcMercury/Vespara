-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                KULT EVENTS SYSTEM REBUILD                                  ║
-- ║  Migration 058: Complete events infrastructure                            ║
-- ║  - vespara_events table (legacy name; replaces reliance on group_events)  ║
-- ║  - vespara_event_rsvps table (legacy name)                                ║
-- ║  - event_cohosts table                                                    ║
-- ║  - event_invitations table                                                ║
-- ║  - Storage policies for event photos                                      ║
-- ║  - RLS policies for all tables                                            ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. KULT EVENTS TABLE (legacy object: vespara_events)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.vespara_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Event details
    title TEXT NOT NULL,
    description TEXT,
    title_style TEXT DEFAULT 'classic',
    cover_image_url TEXT,
    cover_theme TEXT,
    cover_effect TEXT,
    
    -- Date & time
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    has_date_poll BOOLEAN DEFAULT FALSE,
    
    -- Location
    venue_name TEXT,
    venue_address TEXT,
    venue_lat DOUBLE PRECISION,
    venue_lng DOUBLE PRECISION,
    is_virtual BOOLEAN DEFAULT FALSE,
    virtual_link TEXT,
    
    -- Capacity & cost
    max_spots INTEGER,
    cost_per_person DECIMAL(10,2),
    cost_currency TEXT DEFAULT 'USD',
    
    -- RSVP settings
    going_emoji TEXT DEFAULT '🙌',
    maybe_emoji TEXT DEFAULT '🤔',
    cant_go_emoji TEXT DEFAULT '🥀',
    requires_approval BOOLEAN DEFAULT FALSE,
    collect_guest_info BOOLEAN DEFAULT FALSE,
    send_reminders BOOLEAN DEFAULT TRUE,
    reminder_hours_before INTEGER DEFAULT 24,
    rsvp_deadline TIMESTAMPTZ,
    
    -- Visibility & privacy
    visibility TEXT DEFAULT 'private', -- 'private', 'public', 'open_invite'
    content_rating TEXT DEFAULT 'PG',   -- 'PG', 'flirty', 'spicy', 'explicit'
    age_restriction INTEGER DEFAULT 18,
    
    -- Links (stored as JSONB array)
    links JSONB DEFAULT '[]'::jsonb,
    
    -- Status
    is_draft BOOLEAN DEFAULT FALSE,
    is_cancelled BOOLEAN DEFAULT FALSE,
    cancelled_at TIMESTAMPTZ,
    
    -- Host info overrides
    host_nickname TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_vespara_events_host 
    ON public.vespara_events(host_id);
CREATE INDEX IF NOT EXISTS idx_vespara_events_start_time 
    ON public.vespara_events(start_time);
CREATE INDEX IF NOT EXISTS idx_vespara_events_visibility 
    ON public.vespara_events(visibility) WHERE visibility = 'public';
CREATE INDEX IF NOT EXISTS idx_vespara_events_draft 
    ON public.vespara_events(is_draft) WHERE is_draft = true;

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_vespara_event_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_vespara_events_timestamp ON public.vespara_events;
CREATE TRIGGER update_vespara_events_timestamp
    BEFORE UPDATE ON public.vespara_events
    FOR EACH ROW
    EXECUTE FUNCTION update_vespara_event_timestamp();

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. EVENT CO-HOSTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.event_cohosts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.vespara_events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending',  -- 'pending', 'accepted', 'declined'
    can_edit BOOLEAN DEFAULT TRUE,
    can_invite BOOLEAN DEFAULT TRUE,
    can_manage_rsvps BOOLEAN DEFAULT TRUE,
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_event_cohosts_event ON public.event_cohosts(event_id);
CREATE INDEX IF NOT EXISTS idx_event_cohosts_user ON public.event_cohosts(user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. KULT EVENT RSVPS TABLE (legacy object: vespara_event_rsvps)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.vespara_event_rsvps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.vespara_events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'invited', -- 'invited', 'going', 'maybe', 'cant_go', 'waitlisted'
    response_message TEXT,
    guest_info JSONB,
    added_to_calendar BOOLEAN DEFAULT FALSE,
    invited_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_vespara_event_rsvps_event 
    ON public.vespara_event_rsvps(event_id);
CREATE INDEX IF NOT EXISTS idx_vespara_event_rsvps_user 
    ON public.vespara_event_rsvps(user_id);
CREATE INDEX IF NOT EXISTS idx_vespara_event_rsvps_status 
    ON public.vespara_event_rsvps(event_id, status);

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. EVENT INVITATIONS TABLE (shareable invite links)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.event_invitation_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES public.vespara_events(id) ON DELETE CASCADE,
    invite_code TEXT NOT NULL UNIQUE DEFAULT substr(md5(random()::text), 1, 12),
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    max_uses INTEGER,            -- NULL = unlimited
    uses_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_event_invitation_links_code 
    ON public.event_invitation_links(invite_code);
CREATE INDEX IF NOT EXISTS idx_event_invitation_links_event 
    ON public.event_invitation_links(event_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. ROW LEVEL SECURITY - Kult events (vespara_events)
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.vespara_events ENABLE ROW LEVEL SECURITY;

-- Public events visible to all, private events visible to host/cohosts/invitees
DROP POLICY IF EXISTS "vespara_events_select" ON public.vespara_events;
CREATE POLICY "vespara_events_select" ON public.vespara_events
    FOR SELECT USING (
        visibility = 'public'
        OR host_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.event_cohosts 
            WHERE event_id = id AND user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.vespara_event_rsvps 
            WHERE event_id = id AND user_id = auth.uid()
        )
    );

-- Host can insert
DROP POLICY IF EXISTS "vespara_events_insert" ON public.vespara_events;
CREATE POLICY "vespara_events_insert" ON public.vespara_events
    FOR INSERT WITH CHECK (auth.uid() = host_id);

-- Host and accepted cohosts can update
DROP POLICY IF EXISTS "vespara_events_update" ON public.vespara_events;
CREATE POLICY "vespara_events_update" ON public.vespara_events
    FOR UPDATE USING (
        auth.uid() = host_id
        OR EXISTS (
            SELECT 1 FROM public.event_cohosts 
            WHERE event_id = id 
            AND user_id = auth.uid() 
            AND status = 'accepted'
            AND can_edit = true
        )
    );

-- Only host can delete
DROP POLICY IF EXISTS "vespara_events_delete" ON public.vespara_events;
CREATE POLICY "vespara_events_delete" ON public.vespara_events
    FOR DELETE USING (auth.uid() = host_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. ROW LEVEL SECURITY - event_cohosts
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.event_cohosts ENABLE ROW LEVEL SECURITY;

-- Cohosts can see their own invitations + host sees all for their events
DROP POLICY IF EXISTS "event_cohosts_select" ON public.event_cohosts;
CREATE POLICY "event_cohosts_select" ON public.event_cohosts
    FOR SELECT USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND host_id = auth.uid()
        )
    );

-- Host can add cohosts
DROP POLICY IF EXISTS "event_cohosts_insert" ON public.event_cohosts;
CREATE POLICY "event_cohosts_insert" ON public.event_cohosts
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND host_id = auth.uid()
        )
    );

-- Cohosts can update their own status (accept/decline)
DROP POLICY IF EXISTS "event_cohosts_update" ON public.event_cohosts;
CREATE POLICY "event_cohosts_update" ON public.event_cohosts
    FOR UPDATE USING (user_id = auth.uid());

-- Host can remove cohosts
DROP POLICY IF EXISTS "event_cohosts_delete" ON public.event_cohosts;
CREATE POLICY "event_cohosts_delete" ON public.event_cohosts
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND host_id = auth.uid()
        )
    );

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. ROW LEVEL SECURITY - Kult event RSVPs (vespara_event_rsvps)
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.vespara_event_rsvps ENABLE ROW LEVEL SECURITY;

-- Users can see RSVPs for events they can access
DROP POLICY IF EXISTS "vespara_event_rsvps_select" ON public.vespara_event_rsvps;
CREATE POLICY "vespara_event_rsvps_select" ON public.vespara_event_rsvps
    FOR SELECT USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND (
                host_id = auth.uid()
                OR visibility = 'public'
            )
        )
        OR EXISTS (
            SELECT 1 FROM public.event_cohosts 
            WHERE event_id = vespara_event_rsvps.event_id 
            AND user_id = auth.uid() 
            AND status = 'accepted'
        )
    );

-- Host/cohosts can insert RSVPs (send invites); users can RSVP themselves
DROP POLICY IF EXISTS "vespara_event_rsvps_insert" ON public.vespara_event_rsvps;
CREATE POLICY "vespara_event_rsvps_insert" ON public.vespara_event_rsvps
    FOR INSERT WITH CHECK (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND host_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.event_cohosts 
            WHERE event_id = vespara_event_rsvps.event_id 
            AND user_id = auth.uid() 
            AND status = 'accepted'
            AND can_invite = true
        )
    );

-- Users can update their own RSVP
DROP POLICY IF EXISTS "vespara_event_rsvps_update" ON public.vespara_event_rsvps;
CREATE POLICY "vespara_event_rsvps_update" ON public.vespara_event_rsvps
    FOR UPDATE USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND host_id = auth.uid()
        )
    );

-- Host can delete RSVPs
DROP POLICY IF EXISTS "vespara_event_rsvps_delete" ON public.vespara_event_rsvps;
CREATE POLICY "vespara_event_rsvps_delete" ON public.vespara_event_rsvps
    FOR DELETE USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND host_id = auth.uid()
        )
    );

-- ═══════════════════════════════════════════════════════════════════════════
-- 8. ROW LEVEL SECURITY - event_invitation_links
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.event_invitation_links ENABLE ROW LEVEL SECURITY;

-- Anyone can read active links (needed for invite acceptance)
DROP POLICY IF EXISTS "event_invitation_links_select" ON public.event_invitation_links;
CREATE POLICY "event_invitation_links_select" ON public.event_invitation_links
    FOR SELECT USING (is_active = true);

-- Host/cohosts can create invite links
DROP POLICY IF EXISTS "event_invitation_links_insert" ON public.event_invitation_links;
CREATE POLICY "event_invitation_links_insert" ON public.event_invitation_links
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND host_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM public.event_cohosts 
            WHERE event_id = event_invitation_links.event_id 
            AND user_id = auth.uid() 
            AND status = 'accepted'
            AND can_invite = true
        )
    );

-- Host can manage links
DROP POLICY IF EXISTS "event_invitation_links_update" ON public.event_invitation_links;
CREATE POLICY "event_invitation_links_update" ON public.event_invitation_links
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND host_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "event_invitation_links_delete" ON public.event_invitation_links;
CREATE POLICY "event_invitation_links_delete" ON public.event_invitation_links
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.vespara_events 
            WHERE id = event_id AND host_id = auth.uid()
        )
    );

-- ═══════════════════════════════════════════════════════════════════════════
-- 9. STORAGE POLICIES FOR EVENT PHOTOS
-- ═══════════════════════════════════════════════════════════════════════════

-- Fix: The photos bucket path for events is 'events/{userId}/{filename}'
-- Current policy only checks folder[1] == auth.uid(), but for 'events/userId/file'
-- folder[1] is 'events', not the userId. Need a separate policy for events subfolder.

DROP POLICY IF EXISTS "Users can upload event photos" ON storage.objects;
CREATE POLICY "Users can upload event photos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'photos' AND
    (storage.foldername(name))[1] = 'events' AND
    auth.uid()::text = (storage.foldername(name))[2]
);

DROP POLICY IF EXISTS "Users can update event photos" ON storage.objects;
CREATE POLICY "Users can update event photos"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'photos' AND
    (storage.foldername(name))[1] = 'events' AND
    auth.uid()::text = (storage.foldername(name))[2]
);

DROP POLICY IF EXISTS "Users can delete event photos" ON storage.objects;
CREATE POLICY "Users can delete event photos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'photos' AND
    (storage.foldername(name))[1] = 'events' AND
    auth.uid()::text = (storage.foldername(name))[2]
);

-- ═══════════════════════════════════════════════════════════════════════════
-- 10. HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Function to accept an invite via invite code
CREATE OR REPLACE FUNCTION public.accept_event_invite(p_invite_code TEXT)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
    v_link_id UUID;
    v_max_uses INTEGER;
    v_uses INTEGER;
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Find the invitation link
    SELECT id, event_id, max_uses, uses_count 
    INTO v_link_id, v_event_id, v_max_uses, v_uses
    FROM public.event_invitation_links
    WHERE invite_code = p_invite_code 
    AND is_active = true
    AND (expires_at IS NULL OR expires_at > NOW());

    IF v_event_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired invite code';
    END IF;

    -- Check max uses
    IF v_max_uses IS NOT NULL AND v_uses >= v_max_uses THEN
        RAISE EXCEPTION 'This invite link has reached its maximum uses';
    END IF;

    -- Create RSVP record (or update if exists)
    INSERT INTO public.vespara_event_rsvps (event_id, user_id, status, invited_by)
    VALUES (v_event_id, v_user_id, 'invited', NULL)
    ON CONFLICT (event_id, user_id) DO NOTHING;

    -- Increment uses count
    UPDATE public.event_invitation_links 
    SET uses_count = uses_count + 1 
    WHERE id = v_link_id;

    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get event RSVP summary
CREATE OR REPLACE FUNCTION public.get_event_rsvp_summary(p_event_id UUID)
RETURNS TABLE (
    total_invited BIGINT,
    total_going BIGINT,
    total_maybe BIGINT,
    total_cant_go BIGINT,
    total_waitlisted BIGINT,
    spots_remaining INTEGER
) AS $$
DECLARE
    v_max_spots INTEGER;
    v_going BIGINT;
BEGIN
    SELECT max_spots INTO v_max_spots FROM public.vespara_events WHERE id = p_event_id;
    SELECT COUNT(*) INTO v_going FROM public.vespara_event_rsvps WHERE event_id = p_event_id AND status = 'going';
    
    RETURN QUERY
    SELECT 
        COUNT(*) FILTER (WHERE status = 'invited'),
        COUNT(*) FILTER (WHERE status = 'going'),
        COUNT(*) FILTER (WHERE status = 'maybe'),
        COUNT(*) FILTER (WHERE status = 'cant_go'),
        COUNT(*) FILTER (WHERE status = 'waitlisted'),
        CASE WHEN v_max_spots IS NULL THEN NULL ELSE v_max_spots - v_going::INTEGER END
    FROM public.vespara_event_rsvps
    WHERE event_id = p_event_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- 11. GRANTS
-- ═══════════════════════════════════════════════════════════════════════════

GRANT ALL ON public.vespara_events TO authenticated;
GRANT ALL ON public.event_cohosts TO authenticated;
GRANT ALL ON public.vespara_event_rsvps TO authenticated;
GRANT ALL ON public.event_invitation_links TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_event_invite(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_event_rsvp_summary(UUID) TO authenticated;
