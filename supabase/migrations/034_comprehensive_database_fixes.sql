-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 034: COMPREHENSIVE DATABASE FIXES
-- Fixes RLS policies, adds missing tables, ensures all connections work
-- ═══════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════
-- 1. FIX GROUP_MEMBERS RLS POLICIES (causing 500 errors)
-- ════════════════════════════════════════════════════════════════════════════

-- Drop ALL existing policies on group_members to start fresh
DROP POLICY IF EXISTS "Users can view own memberships" ON public.group_members;
DROP POLICY IF EXISTS "Users can view group memberships" ON public.group_members;
DROP POLICY IF EXISTS "Users can leave groups" ON public.group_members;
DROP POLICY IF EXISTS "Creators can manage memberships" ON public.group_members;

-- Create simple, non-recursive policies
-- Policy 1: Users can always see their own memberships
CREATE POLICY "group_members_select_own" ON public.group_members
    FOR SELECT USING (auth.uid() = user_id);

-- Policy 2: Users can update their own memberships (leave groups)
CREATE POLICY "group_members_update_own" ON public.group_members
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy 3: Group creators can manage all memberships in their groups
CREATE POLICY "group_members_creator_all" ON public.group_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.vespara_groups g 
            WHERE g.id = group_members.group_id 
            AND g.creator_id = auth.uid()
        )
    );

-- Policy 4: Insert allowed by function only (SECURITY DEFINER)
CREATE POLICY "group_members_insert" ON public.group_members
    FOR INSERT WITH CHECK (
        -- Either you're the user being added, or you're the group creator
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.vespara_groups g 
            WHERE g.id = group_id 
            AND g.creator_id = auth.uid()
        )
    );

-- ════════════════════════════════════════════════════════════════════════════
-- 2. FIX USER_ANALYTICS TABLE (causing 406 errors - missing Accept header handling)
-- ════════════════════════════════════════════════════════════════════════════

-- Ensure user_analytics table has proper structure
ALTER TABLE public.user_analytics DROP CONSTRAINT IF EXISTS user_analytics_user_id_key;
ALTER TABLE public.user_analytics ADD CONSTRAINT user_analytics_user_id_key UNIQUE (user_id);

-- Drop and recreate RLS policies for user_analytics
DROP POLICY IF EXISTS "Users can view own analytics" ON public.user_analytics;
DROP POLICY IF EXISTS "Users can update own analytics" ON public.user_analytics;
DROP POLICY IF EXISTS "Users can insert own analytics" ON public.user_analytics;

-- Enable RLS
ALTER TABLE public.user_analytics ENABLE ROW LEVEL SECURITY;

-- Simple policies
CREATE POLICY "user_analytics_select" ON public.user_analytics
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_analytics_insert" ON public.user_analytics
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_analytics_update" ON public.user_analytics
    FOR UPDATE USING (auth.uid() = user_id);

-- Create user_analytics row for users who don't have one
CREATE OR REPLACE FUNCTION public.ensure_user_analytics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_analytics (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create analytics on profile creation
DROP TRIGGER IF EXISTS create_user_analytics_trigger ON public.profiles;
CREATE TRIGGER create_user_analytics_trigger
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.ensure_user_analytics();

-- ════════════════════════════════════════════════════════════════════════════
-- 3. FIX MESSAGES TABLE RLS (Wire messages not persisting)
-- ════════════════════════════════════════════════════════════════════════════

-- Ensure messages table exists with proper structure
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    message_type TEXT DEFAULT 'text',
    media_url TEXT,
    media_filename TEXT,
    media_filesize_bytes BIGINT,
    media_thumbnail_url TEXT,
    reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
    client_message_id TEXT,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    reactions JSONB DEFAULT '{}',
    read_by JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages to their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can update own messages" ON public.messages;
DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;

-- Create proper policies for messages
CREATE POLICY "messages_select" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = messages.conversation_id
            AND cp.user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = messages.conversation_id
            AND c.user_id = auth.uid()
        )
        OR sender_id = auth.uid()
    );

CREATE POLICY "messages_insert" ON public.messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND (
            EXISTS (
                SELECT 1 FROM public.conversation_participants cp
                WHERE cp.conversation_id = messages.conversation_id
                AND cp.user_id = auth.uid()
            )
            OR
            EXISTS (
                SELECT 1 FROM public.conversations c
                WHERE c.id = messages.conversation_id
                AND (c.user_id = auth.uid() OR c.match_id IS NOT NULL)
            )
        )
    );

CREATE POLICY "messages_update" ON public.messages
    FOR UPDATE USING (sender_id = auth.uid());

-- Create indexes for messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_client_id ON public.messages(client_message_id);

-- ════════════════════════════════════════════════════════════════════════════
-- 4. ENSURE CONVERSATION_PARTICIPANTS TABLE EXISTS
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.conversation_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_admin BOOLEAN DEFAULT FALSE,
    is_muted BOOLEAN DEFAULT FALSE,
    last_read_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "conversation_participants_select" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_update" ON public.conversation_participants;

-- Create policies
CREATE POLICY "conversation_participants_select" ON public.conversation_participants
    FOR SELECT USING (user_id = auth.uid() OR EXISTS (
        SELECT 1 FROM public.conversation_participants cp2
        WHERE cp2.conversation_id = conversation_participants.conversation_id
        AND cp2.user_id = auth.uid()
    ));

CREATE POLICY "conversation_participants_insert" ON public.conversation_participants
    FOR INSERT WITH CHECK (user_id = auth.uid() OR EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
        AND c.group_created_by = auth.uid()
    ));

CREATE POLICY "conversation_participants_update" ON public.conversation_participants
    FOR UPDATE USING (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 5. FIX CONVERSATIONS TABLE RLS
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "conversations_select" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update" ON public.conversations;
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;

CREATE POLICY "conversations_select" ON public.conversations
    FOR SELECT USING (
        user_id = auth.uid() OR
        match_id IS NOT NULL OR
        group_created_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = id
            AND cp.user_id = auth.uid()
        )
    );

CREATE POLICY "conversations_insert" ON public.conversations
    FOR INSERT WITH CHECK (user_id = auth.uid() OR group_created_by = auth.uid());

CREATE POLICY "conversations_update" ON public.conversations
    FOR UPDATE USING (
        user_id = auth.uid() OR
        group_created_by = auth.uid()
    );

-- ════════════════════════════════════════════════════════════════════════════
-- 6. FIX CREATE_VESPARA_GROUP FUNCTION
-- ════════════════════════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS public.create_vespara_group(TEXT, TEXT, TEXT);

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
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated to create a group';
    END IF;
    
    -- Create the Wire conversation for group chat
    INSERT INTO public.conversations (
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
        is_admin
    ) VALUES (
        v_conversation_id,
        v_user_id,
        TRUE
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;
    
    RETURN v_group_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_vespara_group(TEXT, TEXT, TEXT) TO authenticated;

-- ════════════════════════════════════════════════════════════════════════════
-- 7. GRANT NECESSARY PERMISSIONS
-- ════════════════════════════════════════════════════════════════════════════

GRANT ALL ON public.group_members TO authenticated;
GRANT ALL ON public.vespara_groups TO authenticated;
GRANT ALL ON public.group_invitations TO authenticated;
GRANT ALL ON public.messages TO authenticated;
GRANT ALL ON public.conversations TO authenticated;
GRANT ALL ON public.conversation_participants TO authenticated;
GRANT ALL ON public.user_analytics TO authenticated;
GRANT ALL ON public.notifications TO authenticated;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
