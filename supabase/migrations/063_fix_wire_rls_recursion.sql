-- Fix wire messaging RLS recursion for conversations and conversation_participants
-- Addresses Postgres 42P17 "infinite recursion detected in policy"

-- Safe helper: owner check with row_security disabled to avoid policy recursion.
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

-- Safe helper: unified access check with row_security disabled.
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

-- Drop all known chat policies that may recurse.
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
DROP POLICY IF EXISTS "conv_select_group_creator" ON public.conversations;
DROP POLICY IF EXISTS "conv_insert_own" ON public.conversations;
DROP POLICY IF EXISTS "conv_insert" ON public.conversations;
DROP POLICY IF EXISTS "conv_update_own" ON public.conversations;
DROP POLICY IF EXISTS "conv_update" ON public.conversations;
DROP POLICY IF EXISTS "conv_delete" ON public.conversations;

DROP POLICY IF EXISTS "conversation_participants_select" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_update" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_delete" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_select_own" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_select_same_conversation" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_select_same_conv" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_insert_self" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_insert" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_update_own" ON public.conversation_participants;
DROP POLICY IF EXISTS "cp_delete_own" ON public.conversation_participants;

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

-- Conversations policies
CREATE POLICY "conv_select" ON public.conversations
  FOR SELECT TO authenticated
  USING (public.can_access_conversation(id));

CREATE POLICY "conv_insert" ON public.conversations
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (user_id = auth.uid() OR group_created_by = auth.uid())
  );

CREATE POLICY "conv_update" ON public.conversations
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid() OR group_created_by = auth.uid())
  WITH CHECK (user_id = auth.uid() OR group_created_by = auth.uid());

CREATE POLICY "conv_delete" ON public.conversations
  FOR DELETE TO authenticated
  USING (user_id = auth.uid() OR group_created_by = auth.uid());

-- Conversation participants policies
CREATE POLICY "cp_select" ON public.conversation_participants
  FOR SELECT TO authenticated
  USING (public.can_access_conversation(conversation_id));

CREATE POLICY "cp_insert" ON public.conversation_participants
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
      user_id = auth.uid()
      OR public.is_conversation_owner(conversation_id)
    )
  );

CREATE POLICY "cp_update" ON public.conversation_participants
  FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_conversation_owner(conversation_id)
  )
  WITH CHECK (
    user_id = auth.uid()
    OR public.is_conversation_owner(conversation_id)
  );

CREATE POLICY "cp_delete" ON public.conversation_participants
  FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_conversation_owner(conversation_id)
  );
