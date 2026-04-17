-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║         MIGRATION 074: FIX CHAT RLS INFINITE RECURSION                    ║
-- ║                                                                           ║
-- ║   Root cause: Migrations 008 and 035 created self-referencing RLS         ║
-- ║   policies on conversation_participants. Migration 063 added correct      ║
-- ║   SECURITY DEFINER-based policies but never dropped the old ones due      ║
-- ║   to policy name mismatches. The stale self-referencing policies cause    ║
-- ║   PostgreSQL error 42P17 "infinite recursion detected in policy",         ║
-- ║   preventing all chat queries from executing.                             ║
-- ║                                                                           ║
-- ║   This migration drops ALL stale policies and ensures only the clean      ║
-- ║   SECURITY DEFINER-based policies from migration 063 remain.             ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════════════════
-- 1. DROP STALE CONVERSATION_PARTICIPANTS POLICIES
--    These self-reference conversation_participants causing infinite recursion.
--    Migration 063's cp_select/cp_insert/cp_update/cp_delete cover all cases.
-- ════════════════════════════════════════════════════════════════════════════

-- From migration 008 (never dropped due to name mismatch)
DROP POLICY IF EXISTS "Users can view their own participations" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can view participants in their conversations" ON public.conversation_participants;
DROP POLICY IF EXISTS "Admins can manage participants" ON public.conversation_participants;

-- From migration 035 (never dropped by 063 due to name mismatch)
DROP POLICY IF EXISTS "conversation_participants_select_simple" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert_simple" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_update_simple" ON public.conversation_participants;

-- From migration 034 (may or may not still exist)
DROP POLICY IF EXISTS "conversation_participants_select" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_update" ON public.conversation_participants;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. DROP STALE CONVERSATIONS POLICIES
--    conversations_select_simple references conversation_participants,
--    which triggers the recursive policies above.
--    Migration 063's conv_select/conv_insert/conv_update/conv_delete remain.
-- ════════════════════════════════════════════════════════════════════════════

-- From migration 035 (never dropped by 063)
DROP POLICY IF EXISTS "conversations_select_simple" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert_simple" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update_simple" ON public.conversations;

-- From migration 034 (may or may not still exist)
DROP POLICY IF EXISTS "conversations_select" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update" ON public.conversations;

-- From migration 001 (may or may not still exist)
DROP POLICY IF EXISTS "Users can view own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can manage own conversations" ON public.conversations;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. FIX MESSAGES POLICIES
--    messages_select_simple and the 008 policy both reference
--    conversation_participants, triggering indirect recursion.
--    Replace with a clean policy using can_access_conversation().
-- ════════════════════════════════════════════════════════════════════════════

-- From migration 008 (survived through 034/035 due to name mismatch)
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages to their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;

-- From migration 035
DROP POLICY IF EXISTS "messages_select_simple" ON public.messages;
DROP POLICY IF EXISTS "messages_insert_simple" ON public.messages;
DROP POLICY IF EXISTS "messages_update_simple" ON public.messages;

-- From migration 034 (may or may not still exist)
DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;

-- Create clean messages policies using SECURITY DEFINER helper
CREATE POLICY "msg_select" ON public.messages
    FOR SELECT TO authenticated
    USING (
        sender_id = auth.uid()
        OR public.can_access_conversation(conversation_id)
    );

CREATE POLICY "msg_insert" ON public.messages
    FOR INSERT TO authenticated
    WITH CHECK (sender_id = auth.uid());

CREATE POLICY "msg_update" ON public.messages
    FOR UPDATE TO authenticated
    USING (sender_id = auth.uid());

CREATE POLICY "msg_delete" ON public.messages
    FOR DELETE TO authenticated
    USING (sender_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 4. ENSURE MIGRATION 063 POLICIES EXIST
--    Idempotent re-creation in case 063 was never applied.
-- ════════════════════════════════════════════════════════════════════════════

-- Ensure helper functions exist
CREATE OR REPLACE FUNCTION public.is_conversation_owner(conv_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.conversations c
    WHERE c.id = conv_id
      AND (c.user_id = auth.uid() OR c.group_created_by = auth.uid())
  );
$$;

CREATE OR REPLACE FUNCTION public.can_access_conversation(conv_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.conversations c
    WHERE c.id = conv_id
      AND (
        c.user_id = auth.uid()
        OR c.group_created_by = auth.uid()
        OR EXISTS (
          SELECT 1
          FROM public.conversation_participants cp
          WHERE cp.conversation_id = conv_id
            AND cp.user_id = auth.uid()
            AND COALESCE(cp.is_active, TRUE) = TRUE
        )
      )
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_conversation_owner(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_access_conversation(UUID) TO authenticated;

-- Ensure conversations policies exist (idempotent - will no-op if already present)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'conversations' AND policyname = 'conv_select'
    ) THEN
        EXECUTE 'CREATE POLICY "conv_select" ON public.conversations
            FOR SELECT TO authenticated
            USING (public.can_access_conversation(id))';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'conversations' AND policyname = 'conv_insert'
    ) THEN
        EXECUTE 'CREATE POLICY "conv_insert" ON public.conversations
            FOR INSERT TO authenticated
            WITH CHECK (
                auth.uid() IS NOT NULL
                AND (user_id = auth.uid() OR group_created_by = auth.uid())
            )';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'conversations' AND policyname = 'conv_update'
    ) THEN
        EXECUTE 'CREATE POLICY "conv_update" ON public.conversations
            FOR UPDATE TO authenticated
            USING (user_id = auth.uid() OR group_created_by = auth.uid())
            WITH CHECK (user_id = auth.uid() OR group_created_by = auth.uid())';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'conversations' AND policyname = 'conv_delete'
    ) THEN
        EXECUTE 'CREATE POLICY "conv_delete" ON public.conversations
            FOR DELETE TO authenticated
            USING (user_id = auth.uid() OR group_created_by = auth.uid())';
    END IF;
END $$;

-- Ensure conversation_participants policies exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'conversation_participants' AND policyname = 'cp_select'
    ) THEN
        EXECUTE 'CREATE POLICY "cp_select" ON public.conversation_participants
            FOR SELECT TO authenticated
            USING (public.can_access_conversation(conversation_id))';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'conversation_participants' AND policyname = 'cp_insert'
    ) THEN
        EXECUTE 'CREATE POLICY "cp_insert" ON public.conversation_participants
            FOR INSERT TO authenticated
            WITH CHECK (
                auth.uid() IS NOT NULL
                AND (
                    user_id = auth.uid()
                    OR public.is_conversation_owner(conversation_id)
                )
            )';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'conversation_participants' AND policyname = 'cp_update'
    ) THEN
        EXECUTE 'CREATE POLICY "cp_update" ON public.conversation_participants
            FOR UPDATE TO authenticated
            USING (
                user_id = auth.uid()
                OR public.is_conversation_owner(conversation_id)
            )
            WITH CHECK (
                user_id = auth.uid()
                OR public.is_conversation_owner(conversation_id)
            )';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'conversation_participants' AND policyname = 'cp_delete'
    ) THEN
        EXECUTE 'CREATE POLICY "cp_delete" ON public.conversation_participants
            FOR DELETE TO authenticated
            USING (
                user_id = auth.uid()
                OR public.is_conversation_owner(conversation_id)
            )';
    END IF;
END $$;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
