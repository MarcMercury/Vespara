-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 035: FIX WIRE MESSAGING PERMISSIONS
-- Makes message insertion work for authenticated users
-- ═══════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════
-- 1. SIMPLIFY MESSAGES RLS - Allow any authenticated user to insert
-- ════════════════════════════════════════════════════════════════════════════

-- Drop overly complex policies
DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;

-- Simple SELECT: Users can read messages they sent or that are in their conversations
CREATE POLICY "messages_select_simple" ON public.messages
    FOR SELECT USING (
        sender_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = messages.conversation_id
            AND cp.user_id = auth.uid()
        )
    );

-- Simple INSERT: Any authenticated user can insert messages where they are the sender
CREATE POLICY "messages_insert_simple" ON public.messages
    FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Simple UPDATE: Users can update their own messages
CREATE POLICY "messages_update_simple" ON public.messages
    FOR UPDATE USING (sender_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 2. SIMPLIFY CONVERSATIONS RLS - Allow creation
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "conversations_select" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update" ON public.conversations;
DROP POLICY IF EXISTS "conversations_select_simple" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert_simple" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update_simple" ON public.conversations;

-- SELECT: User can see conversations they own or participate in
CREATE POLICY "conversations_select_simple" ON public.conversations
    FOR SELECT USING (
        user_id = auth.uid() OR
        group_created_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = id
            AND cp.user_id = auth.uid()
        )
    );

-- INSERT: Any authenticated user can create a conversation
CREATE POLICY "conversations_insert_simple" ON public.conversations
    FOR INSERT WITH CHECK (user_id = auth.uid() OR group_created_by = auth.uid());

-- UPDATE: Owner can update
CREATE POLICY "conversations_update_simple" ON public.conversations
    FOR UPDATE USING (user_id = auth.uid() OR group_created_by = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 3. SIMPLIFY CONVERSATION_PARTICIPANTS RLS
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "conversation_participants_select" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_update" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_select_simple" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert_simple" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_update_simple" ON public.conversation_participants;

-- SELECT: See your own participation or co-participants
CREATE POLICY "conversation_participants_select_simple" ON public.conversation_participants
    FOR SELECT USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp2
            WHERE cp2.conversation_id = conversation_participants.conversation_id
            AND cp2.user_id = auth.uid()
        )
    );

-- INSERT: Can add yourself or others to conversations you created
CREATE POLICY "conversation_participants_insert_simple" ON public.conversation_participants
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = conversation_id
            AND (c.user_id = auth.uid() OR c.group_created_by = auth.uid())
        )
    );

-- UPDATE: Can update your own participation
CREATE POLICY "conversation_participants_update_simple" ON public.conversation_participants
    FOR UPDATE USING (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 4. ENSURE ALL TABLES HAVE RLS ENABLED
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

-- ════════════════════════════════════════════════════════════════════════════
-- 5. GRANT PERMISSIONS
-- ════════════════════════════════════════════════════════════════════════════

GRANT ALL ON public.messages TO authenticated;
GRANT ALL ON public.conversations TO authenticated;
GRANT ALL ON public.conversation_participants TO authenticated;

-- Reload schema
NOTIFY pgrst, 'reload schema';
