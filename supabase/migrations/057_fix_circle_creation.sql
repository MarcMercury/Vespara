-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║              MIGRATION 057: FIX CIRCLE (GROUP) CREATION                   ║
-- ║   Resolves 400 on create_vespara_group, 500 on group_members query        ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
--
-- Issues Fixed:
-- 1. create_vespara_group RPC returns 400 (function/column mismatches)
-- 2. group_members SELECT returns 500 (recursive RLS policies)
-- 3. Missing helper functions (can_user_join_group, get_user_group_count)
-- 4. conversation_participants column inconsistencies
--
-- Date: 2026-02-12

-- ════════════════════════════════════════════════════════════════════════════
-- 1. ENSURE CONVERSATIONS TABLE SUPPORTS GROUPS
-- ════════════════════════════════════════════════════════════════════════════

-- Make match_id nullable (group conversations don't have a match)
ALTER TABLE public.conversations ALTER COLUMN match_id DROP NOT NULL;

-- Make user_id nullable (set by SECURITY DEFINER function)
ALTER TABLE public.conversations ALTER COLUMN user_id DROP NOT NULL;

-- Ensure group columns exist
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS conversation_type TEXT DEFAULT 'direct';
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS group_name TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS group_description TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS group_avatar_url TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS group_created_by UUID;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS participant_count INTEGER DEFAULT 2;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS only_admins_can_send BOOLEAN DEFAULT FALSE;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS allow_member_invite BOOLEAN DEFAULT TRUE;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. ENSURE CONVERSATION_PARTICIPANTS TABLE HAS CORRECT COLUMNS
-- ════════════════════════════════════════════════════════════════════════════

-- Add is_admin column if missing (newer schema uses this instead of role)
ALTER TABLE public.conversation_participants ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;
ALTER TABLE public.conversation_participants ADD COLUMN IF NOT EXISTS is_muted BOOLEAN DEFAULT FALSE;
ALTER TABLE public.conversation_participants ADD COLUMN IF NOT EXISTS last_read_at TIMESTAMPTZ;
ALTER TABLE public.conversation_participants ADD COLUMN IF NOT EXISTS joined_at TIMESTAMPTZ DEFAULT NOW();

-- ════════════════════════════════════════════════════════════════════════════
-- 3. ENSURE HELPER FUNCTIONS EXIST
-- ════════════════════════════════════════════════════════════════════════════

-- Count user's active groups
CREATE OR REPLACE FUNCTION public.get_user_group_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COUNT(*)::INTEGER
    FROM group_members
    WHERE user_id = p_user_id AND status = 'active';
$$;

-- Check if user can join/create another group
CREATE OR REPLACE FUNCTION public.can_user_join_group(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT public.get_user_group_count(p_user_id) < 10;
$$;

-- Conversation participant check (used by RLS)
CREATE OR REPLACE FUNCTION public.user_is_conversation_participant(conv_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM conversation_participants
        WHERE conversation_id = conv_id
        AND user_id = auth.uid()
    );
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- 4. FIX GROUP_MEMBERS RLS POLICIES (causes 500 errors)
-- ════════════════════════════════════════════════════════════════════════════

-- Drop ALL existing policies to start clean
DROP POLICY IF EXISTS "Users can view own memberships" ON public.group_members;
DROP POLICY IF EXISTS "Users can view group memberships" ON public.group_members;
DROP POLICY IF EXISTS "Users can leave groups" ON public.group_members;
DROP POLICY IF EXISTS "Creators can manage memberships" ON public.group_members;
DROP POLICY IF EXISTS "group_members_select_own" ON public.group_members;
DROP POLICY IF EXISTS "group_members_update_own" ON public.group_members;
DROP POLICY IF EXISTS "group_members_creator_all" ON public.group_members;
DROP POLICY IF EXISTS "group_members_insert" ON public.group_members;
DROP POLICY IF EXISTS "group_members_select" ON public.group_members;
DROP POLICY IF EXISTS "group_members_delete" ON public.group_members;

-- Enable RLS
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- Simple, non-recursive policies
-- Users can see their own memberships
CREATE POLICY "gm_select_own" ON public.group_members
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Helper function: check if user is member of a group (avoids recursion)
CREATE OR REPLACE FUNCTION public.user_is_group_member(gid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM group_members
        WHERE group_id = gid
        AND user_id = auth.uid()
        AND status = 'active'
    );
$$;

-- Users can see other members in their groups (via security definer function)
CREATE POLICY "gm_select_same_group" ON public.group_members
    FOR SELECT TO authenticated
    USING (public.user_is_group_member(group_id));

-- Users can update their own membership (leave)
CREATE POLICY "gm_update_own" ON public.group_members
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

-- Insert: allowed by SECURITY DEFINER functions (createGroup, acceptInvitation)
-- Also allow group creators to add members directly
CREATE POLICY "gm_insert" ON public.group_members
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.vespara_groups g
            WHERE g.id = group_id
            AND g.creator_id = auth.uid()
        )
    );

-- ════════════════════════════════════════════════════════════════════════════
-- 5. FIX VESPARA_GROUPS RLS POLICIES
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Creators can manage their groups" ON public.vespara_groups;
DROP POLICY IF EXISTS "Members can view their groups" ON public.vespara_groups;
DROP POLICY IF EXISTS "vg_select" ON public.vespara_groups;
DROP POLICY IF EXISTS "vg_insert" ON public.vespara_groups;
DROP POLICY IF EXISTS "vg_update" ON public.vespara_groups;
DROP POLICY IF EXISTS "vg_delete" ON public.vespara_groups;

ALTER TABLE public.vespara_groups ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can view active groups they belong to
CREATE POLICY "vg_select" ON public.vespara_groups
    FOR SELECT TO authenticated
    USING (
        creator_id = auth.uid() OR
        public.user_is_group_member(id)
    );

-- Authenticated users can create groups
CREATE POLICY "vg_insert" ON public.vespara_groups
    FOR INSERT TO authenticated
    WITH CHECK (creator_id = auth.uid());

-- Creators can update their groups
CREATE POLICY "vg_update" ON public.vespara_groups
    FOR UPDATE TO authenticated
    USING (creator_id = auth.uid());

-- Creators can delete their groups
CREATE POLICY "vg_delete" ON public.vespara_groups
    FOR DELETE TO authenticated
    USING (creator_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 6. RECREATE create_vespara_group FUNCTION (clean version)
-- ════════════════════════════════════════════════════════════════════════════

-- Drop ALL possible function signatures
DROP FUNCTION IF EXISTS public.create_vespara_group(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_vespara_group(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_vespara_group(TEXT);

CREATE OR REPLACE FUNCTION public.create_vespara_group(
    p_name TEXT,
    p_description TEXT DEFAULT NULL,
    p_avatar_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_group_id UUID;
    v_conversation_id UUID;
    v_user_id UUID;
BEGIN
    -- Get authenticated user
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated to create a group';
    END IF;

    -- Check group limit
    IF get_user_group_count(v_user_id) >= 10 THEN
        RAISE EXCEPTION 'User has reached maximum group limit (10)';
    END IF;

    -- Create the Wire conversation for group chat
    INSERT INTO conversations (
        user_id,
        conversation_type,
        group_name,
        group_description,
        group_avatar_url,
        group_created_by,
        participant_count,
        only_admins_can_send,
        allow_member_invite
    ) VALUES (
        v_user_id,
        'group',
        p_name,
        p_description,
        p_avatar_url,
        v_user_id,
        1,
        FALSE,
        FALSE
    )
    RETURNING id INTO v_conversation_id;

    -- Create the group record
    INSERT INTO vespara_groups (
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

    -- Add creator as first group member
    INSERT INTO group_members (
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
    INSERT INTO conversation_participants (
        conversation_id,
        user_id,
        is_admin,
        joined_at
    ) VALUES (
        v_conversation_id,
        v_user_id,
        TRUE,
        NOW()
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_group_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.create_vespara_group(TEXT, TEXT, TEXT) TO authenticated;

-- ════════════════════════════════════════════════════════════════════════════
-- 7. FIX CONVERSATIONS RLS FOR GROUP CREATION
-- ════════════════════════════════════════════════════════════════════════════

-- Drop old policies
DROP POLICY IF EXISTS "conversations_select" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update" ON public.conversations;
DROP POLICY IF EXISTS "conversations_delete" ON public.conversations;
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can manage own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can view own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "conv_select_own" ON public.conversations;
DROP POLICY IF EXISTS "conv_select_participant" ON public.conversations;
DROP POLICY IF EXISTS "conv_insert_own" ON public.conversations;
DROP POLICY IF EXISTS "conv_update_own" ON public.conversations;

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Direct conversations: user_id check
CREATE POLICY "conv_select_own" ON public.conversations
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Group conversations: via participant check
CREATE POLICY "conv_select_participant" ON public.conversations
    FOR SELECT TO authenticated
    USING (user_is_conversation_participant(id));

-- Group creator can see their group conversations
CREATE POLICY "conv_select_group_creator" ON public.conversations
    FOR SELECT TO authenticated
    USING (group_created_by = auth.uid());

-- Users can create conversations
CREATE POLICY "conv_insert" ON public.conversations
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() OR group_created_by = auth.uid());

-- Users can update their own conversations
CREATE POLICY "conv_update" ON public.conversations
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR group_created_by = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 8. FIX CONVERSATION_PARTICIPANTS RLS
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "conversation_participants_select" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_update" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_delete" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_select_own" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_select_same_conversation" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_insert_self" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_update_own" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_delete_own" ON public.conversation_participants;

ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

-- Users can see their own participation
CREATE POLICY "cp_select_own" ON public.conversation_participants
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Users can see other participants in same conversation
CREATE POLICY "cp_select_same_conv" ON public.conversation_participants
    FOR SELECT TO authenticated
    USING (user_is_conversation_participant(conversation_id));

-- Users can add themselves or be added by group creator
CREATE POLICY "cp_insert" ON public.conversation_participants
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM conversations c
            WHERE c.id = conversation_id
            AND c.group_created_by = auth.uid()
        )
    );

-- Users can update their own participation
CREATE POLICY "cp_update_own" ON public.conversation_participants
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

-- Users can remove themselves
CREATE POLICY "cp_delete_own" ON public.conversation_participants
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 9. RECREATE user_groups_summary VIEW
-- ════════════════════════════════════════════════════════════════════════════

-- Must drop first because column list changed from original view
DROP VIEW IF EXISTS public.user_groups_summary;

CREATE VIEW public.user_groups_summary AS
SELECT
    g.id,
    g.name,
    g.description,
    g.avatar_url,
    g.creator_id,
    g.conversation_id,
    g.is_active,
    g.created_at,
    g.updated_at,
    gm.user_id,
    gm.role,
    gm.joined_at,
    (SELECT COUNT(*) FROM public.group_members
     WHERE group_id = g.id AND status = 'active') AS member_count,
    (SELECT array_agg(p.avatar_url) FROM public.group_members m
     JOIN public.profiles p ON p.id = m.user_id
     WHERE m.group_id = g.id AND m.status = 'active' LIMIT 5) AS member_avatars
FROM public.vespara_groups g
JOIN public.group_members gm ON gm.group_id = g.id
WHERE g.is_active = TRUE AND gm.status = 'active';

-- ════════════════════════════════════════════════════════════════════════════
-- 10. GRANT PERMISSIONS
-- ════════════════════════════════════════════════════════════════════════════

GRANT ALL ON public.group_members TO authenticated;
GRANT ALL ON public.vespara_groups TO authenticated;
GRANT ALL ON public.group_invitations TO authenticated;
GRANT ALL ON public.conversations TO authenticated;
GRANT ALL ON public.conversation_participants TO authenticated;
GRANT ALL ON public.notifications TO authenticated;
GRANT ALL ON public.messages TO authenticated;
GRANT SELECT ON public.user_groups_summary TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_user_group_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_user_join_group(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_is_conversation_participant(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_is_group_member(UUID) TO authenticated;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
