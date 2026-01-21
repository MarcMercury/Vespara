-- ============================================
-- VESPARA GROUPS - Social Circles Feature
-- Migration 028: User-created groups with invitations
-- ============================================

-- ============================================
-- 1. GROUPS TABLE
-- Core table for user-created groups
-- ============================================

CREATE TABLE IF NOT EXISTS public.vespara_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    avatar_url TEXT,
    creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Associated Wire conversation for group chat
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE SET NULL,
    -- Settings
    max_members INTEGER DEFAULT 50,
    is_active BOOLEAN DEFAULT TRUE,
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.vespara_groups ENABLE ROW LEVEL SECURITY;

-- Creators can manage their groups
CREATE POLICY "Creators can manage their groups" ON public.vespara_groups
    FOR ALL USING (auth.uid() = creator_id);

-- Members can view groups they belong to
CREATE POLICY "Members can view their groups" ON public.vespara_groups
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.group_members gm 
            WHERE gm.group_id = id 
            AND gm.user_id = auth.uid() 
            AND gm.status = 'active'
        )
    );

CREATE INDEX IF NOT EXISTS idx_groups_creator ON public.vespara_groups(creator_id);
CREATE INDEX IF NOT EXISTS idx_groups_active ON public.vespara_groups(is_active) WHERE is_active = TRUE;

-- ============================================
-- 2. GROUP MEMBERS TABLE
-- Tracks membership status
-- ============================================

CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.vespara_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Status: active, left, removed
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'left', 'removed')),
    -- Role: creator (only one per group), member
    role TEXT DEFAULT 'member' CHECK (role IN ('creator', 'member')),
    -- Timestamps
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    left_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- Users can view their own memberships
CREATE POLICY "Users can view own memberships" ON public.group_members
    FOR SELECT USING (auth.uid() = user_id);

-- Users can view memberships in their groups
CREATE POLICY "Users can view group memberships" ON public.group_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.group_members gm 
            WHERE gm.group_id = group_id 
            AND gm.user_id = auth.uid() 
            AND gm.status = 'active'
        )
    );

-- Users can update their own membership (leave)
CREATE POLICY "Users can leave groups" ON public.group_members
    FOR UPDATE USING (auth.uid() = user_id);

-- Creators can manage memberships (remove members)
CREATE POLICY "Creators can manage memberships" ON public.group_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.vespara_groups g 
            WHERE g.id = group_id 
            AND g.creator_id = auth.uid()
        )
    );

CREATE INDEX IF NOT EXISTS idx_group_members_group ON public.group_members(group_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_group_members_user ON public.group_members(user_id) WHERE status = 'active';

-- ============================================
-- 3. GROUP INVITATIONS TABLE
-- Tracks pending and responded invitations
-- ============================================

CREATE TABLE IF NOT EXISTS public.group_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.vespara_groups(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Status: pending, accepted, declined
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    -- Message from inviter (optional)
    message TEXT,
    -- Timestamps
    responded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Prevent duplicate pending invites
    UNIQUE(group_id, invitee_id, status) WHERE (status = 'pending')
);

ALTER TABLE public.group_invitations ENABLE ROW LEVEL SECURITY;

-- Inviters can view and manage their sent invitations
CREATE POLICY "Inviters can manage invitations" ON public.group_invitations
    FOR ALL USING (auth.uid() = inviter_id);

-- Invitees can view their received invitations
CREATE POLICY "Invitees can view invitations" ON public.group_invitations
    FOR SELECT USING (auth.uid() = invitee_id);

-- Invitees can respond to invitations
CREATE POLICY "Invitees can respond to invitations" ON public.group_invitations
    FOR UPDATE USING (auth.uid() = invitee_id AND status = 'pending');

CREATE INDEX IF NOT EXISTS idx_invitations_invitee ON public.group_invitations(invitee_id) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_invitations_group ON public.group_invitations(group_id) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_invitations_expires ON public.group_invitations(expires_at) WHERE status = 'pending';

-- ============================================
-- 4. FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to count user's active groups (created + joined)
CREATE OR REPLACE FUNCTION public.get_user_group_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    group_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO group_count
    FROM public.group_members
    WHERE user_id = p_user_id AND status = 'active';
    
    RETURN group_count;
END;
$$;

-- Function to check if user can create/join more groups (limit 10)
CREATE OR REPLACE FUNCTION public.can_user_join_group(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN public.get_user_group_count(p_user_id) < 10;
END;
$$;

-- Function to create a group with all related records
CREATE OR REPLACE FUNCTION public.create_vespara_group(
    p_name TEXT,
    p_description TEXT DEFAULT NULL,
    p_avatar_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_group_id UUID;
    v_conversation_id UUID;
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    -- Check if user can create more groups
    IF NOT public.can_user_join_group(v_user_id) THEN
        RAISE EXCEPTION 'User has reached maximum group limit (10)';
    END IF;
    
    -- Create the Wire conversation for group chat
    INSERT INTO public.conversations (
        conversation_type,
        group_name,
        group_description,
        group_avatar_url,
        group_created_by,
        participant_count,
        only_admins_can_send,
        allow_member_invite
    ) VALUES (
        'group',
        p_name,
        p_description,
        p_avatar_url,
        v_user_id,
        1,
        FALSE,
        FALSE -- Only creator can invite
    )
    RETURNING id INTO v_conversation_id;
    
    -- Create the group
    INSERT INTO public.vespara_groups (
        name,
        description,
        avatar_url,
        creator_id,
        conversation_id
    ) VALUES (
        p_name,
        p_description,
        p_avatar_url,
        v_user_id,
        v_conversation_id
    )
    RETURNING id INTO v_group_id;
    
    -- Add creator as first member
    INSERT INTO public.group_members (
        group_id,
        user_id,
        status,
        role
    ) VALUES (
        v_group_id,
        v_user_id,
        'active',
        'creator'
    );
    
    -- Add creator as conversation participant
    INSERT INTO public.conversation_participants (
        conversation_id,
        user_id,
        role,
        can_send_messages,
        can_add_members
    ) VALUES (
        v_conversation_id,
        v_user_id,
        'admin',
        TRUE,
        TRUE
    );
    
    RETURN v_group_id;
END;
$$;

-- Function to accept a group invitation
CREATE OR REPLACE FUNCTION public.accept_group_invitation(p_invitation_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_invitation RECORD;
    v_group RECORD;
BEGIN
    -- Get invitation details
    SELECT * INTO v_invitation
    FROM public.group_invitations
    WHERE id = p_invitation_id AND invitee_id = auth.uid() AND status = 'pending';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found or already responded';
    END IF;
    
    -- Check if invitation expired
    IF v_invitation.expires_at < NOW() THEN
        RAISE EXCEPTION 'Invitation has expired';
    END IF;
    
    -- Check if user can join more groups
    IF NOT public.can_user_join_group(auth.uid()) THEN
        RAISE EXCEPTION 'You have reached the maximum group limit (10)';
    END IF;
    
    -- Get group details
    SELECT * INTO v_group
    FROM public.vespara_groups
    WHERE id = v_invitation.group_id AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Group no longer exists';
    END IF;
    
    -- Update invitation status
    UPDATE public.group_invitations
    SET status = 'accepted', responded_at = NOW()
    WHERE id = p_invitation_id;
    
    -- Add user as group member
    INSERT INTO public.group_members (
        group_id,
        user_id,
        status,
        role
    ) VALUES (
        v_group.id,
        auth.uid(),
        'active',
        'member'
    )
    ON CONFLICT (group_id, user_id) 
    DO UPDATE SET status = 'active', joined_at = NOW(), left_at = NULL;
    
    -- Add user to Wire conversation
    INSERT INTO public.conversation_participants (
        conversation_id,
        user_id,
        role,
        can_send_messages,
        can_add_members
    ) VALUES (
        v_group.conversation_id,
        auth.uid(),
        'member',
        TRUE,
        FALSE
    )
    ON CONFLICT (conversation_id, user_id)
    DO UPDATE SET is_active = TRUE, left_at = NULL;
    
    -- Update participant count
    UPDATE public.conversations
    SET participant_count = participant_count + 1, updated_at = NOW()
    WHERE id = v_group.conversation_id;
    
    RETURN TRUE;
END;
$$;

-- Function to decline a group invitation
CREATE OR REPLACE FUNCTION public.decline_group_invitation(p_invitation_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.group_invitations
    SET status = 'declined', responded_at = NOW()
    WHERE id = p_invitation_id 
    AND invitee_id = auth.uid() 
    AND status = 'pending';
    
    RETURN FOUND;
END;
$$;

-- Function to leave a group
CREATE OR REPLACE FUNCTION public.leave_vespara_group(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_member RECORD;
    v_group RECORD;
BEGIN
    -- Get membership details
    SELECT * INTO v_member
    FROM public.group_members
    WHERE group_id = p_group_id AND user_id = auth.uid() AND status = 'active';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Not a member of this group';
    END IF;
    
    -- Get group details
    SELECT * INTO v_group
    FROM public.vespara_groups
    WHERE id = p_group_id;
    
    -- If creator leaves, disband the entire group
    IF v_member.role = 'creator' THEN
        -- Mark group as inactive
        UPDATE public.vespara_groups
        SET is_active = FALSE, updated_at = NOW()
        WHERE id = p_group_id;
        
        -- Mark all members as left
        UPDATE public.group_members
        SET status = 'left', left_at = NOW()
        WHERE group_id = p_group_id;
        
        -- Deactivate all conversation participants
        UPDATE public.conversation_participants
        SET is_active = FALSE, left_at = NOW()
        WHERE conversation_id = v_group.conversation_id;
        
        -- Archive the conversation
        UPDATE public.conversations
        SET is_archived = TRUE, archived_at = NOW()
        WHERE id = v_group.conversation_id;
    ELSE
        -- Regular member leaving
        UPDATE public.group_members
        SET status = 'left', left_at = NOW()
        WHERE group_id = p_group_id AND user_id = auth.uid();
        
        -- Remove from conversation
        UPDATE public.conversation_participants
        SET is_active = FALSE, left_at = NOW()
        WHERE conversation_id = v_group.conversation_id AND user_id = auth.uid();
        
        -- Update participant count
        UPDATE public.conversations
        SET participant_count = participant_count - 1, updated_at = NOW()
        WHERE id = v_group.conversation_id;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- Function to send a group invitation (creator only)
CREATE OR REPLACE FUNCTION public.send_group_invitation(
    p_group_id UUID,
    p_invitee_id UUID,
    p_message TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_group RECORD;
    v_invitation_id UUID;
    v_existing RECORD;
BEGIN
    -- Verify caller is the group creator
    SELECT * INTO v_group
    FROM public.vespara_groups
    WHERE id = p_group_id AND creator_id = auth.uid() AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Only the group creator can send invitations';
    END IF;
    
    -- Check if invitee is already a member
    IF EXISTS (
        SELECT 1 FROM public.group_members 
        WHERE group_id = p_group_id AND user_id = p_invitee_id AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'User is already a member of this group';
    END IF;
    
    -- Check if there's already a pending invitation
    SELECT * INTO v_existing
    FROM public.group_invitations
    WHERE group_id = p_group_id AND invitee_id = p_invitee_id AND status = 'pending';
    
    IF FOUND THEN
        RAISE EXCEPTION 'An invitation is already pending for this user';
    END IF;
    
    -- Check if invitee can join more groups
    IF NOT public.can_user_join_group(p_invitee_id) THEN
        RAISE EXCEPTION 'User has reached maximum group limit';
    END IF;
    
    -- Create the invitation
    INSERT INTO public.group_invitations (
        group_id,
        inviter_id,
        invitee_id,
        message
    ) VALUES (
        p_group_id,
        auth.uid(),
        p_invitee_id,
        p_message
    )
    RETURNING id INTO v_invitation_id;
    
    -- Create notification for invitee
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        message,
        data,
        action_url
    ) VALUES (
        p_invitee_id,
        'group_invitation',
        'Group Invitation',
        'You have been invited to join ' || v_group.name,
        jsonb_build_object(
            'invitation_id', v_invitation_id,
            'group_id', p_group_id,
            'group_name', v_group.name,
            'inviter_id', auth.uid()
        ),
        '/sanctum/groups/invitations'
    );
    
    RETURN v_invitation_id;
END;
$$;

-- ============================================
-- 5. NOTIFICATIONS TABLE (if not exists)
-- ============================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT,
    data JSONB,
    action_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);

-- ============================================
-- 6. REALTIME SUBSCRIPTIONS
-- ============================================

-- Enable realtime for groups
ALTER PUBLICATION supabase_realtime ADD TABLE public.vespara_groups;
ALTER PUBLICATION supabase_realtime ADD TABLE public.group_members;
ALTER PUBLICATION supabase_realtime ADD TABLE public.group_invitations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- ============================================
-- 7. UTILITY VIEWS
-- ============================================

-- View for user's groups with member count
CREATE OR REPLACE VIEW public.user_groups_summary AS
SELECT 
    g.id,
    g.name,
    g.description,
    g.avatar_url,
    g.creator_id,
    g.conversation_id,
    g.created_at,
    gm.user_id,
    gm.role,
    gm.joined_at,
    (SELECT COUNT(*) FROM public.group_members WHERE group_id = g.id AND status = 'active') as member_count,
    (SELECT array_agg(p.avatar_url) FROM public.group_members m 
     JOIN public.profiles p ON p.id = m.user_id 
     WHERE m.group_id = g.id AND m.status = 'active' LIMIT 5) as member_avatars
FROM public.vespara_groups g
JOIN public.group_members gm ON gm.group_id = g.id
WHERE g.is_active = TRUE AND gm.status = 'active';

-- View for pending invitations with group details
CREATE OR REPLACE VIEW public.pending_group_invitations AS
SELECT 
    i.id as invitation_id,
    i.group_id,
    i.inviter_id,
    i.invitee_id,
    i.message,
    i.expires_at,
    i.created_at,
    g.name as group_name,
    g.description as group_description,
    g.avatar_url as group_avatar,
    p.display_name as inviter_name,
    p.avatar_url as inviter_avatar,
    (SELECT COUNT(*) FROM public.group_members WHERE group_id = g.id AND status = 'active') as member_count
FROM public.group_invitations i
JOIN public.vespara_groups g ON g.id = i.group_id
JOIN public.profiles p ON p.id = i.inviter_id
WHERE i.status = 'pending' 
AND i.expires_at > NOW()
AND g.is_active = TRUE;

COMMENT ON TABLE public.vespara_groups IS 'User-created social circles for Sanctum module';
COMMENT ON TABLE public.group_members IS 'Membership tracking for vespara groups';
COMMENT ON TABLE public.group_invitations IS 'Invitation system for group membership';
