-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                  MIGRATION 053: FIX RLS INFINITE RECURSION                 ║
-- ║           Resolves circular policy references in conversations            ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
--
-- Issues Fixed:
-- 1. Infinite recursion in conversation_participants RLS policy
-- 2. Infinite recursion in conversations RLS policy  
-- 3. Profiles table visible to anonymous users (security fix)
--
-- Date: 2026-02-03

-- ════════════════════════════════════════════════════════════════════════════
-- 1. FIX PROFILES RLS - REQUIRE AUTHENTICATION
-- ════════════════════════════════════════════════════════════════════════════

-- Drop overly permissive policies
DROP POLICY IF EXISTS "Anyone can view profiles" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "profiles_public_read" ON public.profiles;

-- Create secure policies: only authenticated users can view profiles
CREATE POLICY "profiles_authenticated_select" ON public.profiles
    FOR SELECT TO authenticated
    USING (true);

-- Users can only update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "profiles_owner_update" ON public.profiles
    FOR UPDATE TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Users can insert their own profile (on signup)
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "profiles_owner_insert" ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK (id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 2. FIX CONVERSATION_PARTICIPANTS RLS - BREAK RECURSION
-- ════════════════════════════════════════════════════════════════════════════

-- Drop the recursive policy
DROP POLICY IF EXISTS "conversation_participants_select" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_update" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_delete" ON public.conversation_participants;

-- Simple non-recursive policy: users can see their own participation records
CREATE POLICY "cp_select_own" ON public.conversation_participants
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Users can see other participants if they are in the same conversation
-- This uses a security definer function to avoid recursion
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

-- Policy for viewing other participants (via function)
CREATE POLICY "cp_select_same_conversation" ON public.conversation_participants
    FOR SELECT TO authenticated
    USING (public.user_is_conversation_participant(conversation_id));

-- Insert: users can add themselves or be added by conversation creator
CREATE POLICY "cp_insert_self" ON public.conversation_participants
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Update: users can only update their own participation
CREATE POLICY "cp_update_own" ON public.conversation_participants
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

-- Delete: users can remove themselves from conversations
CREATE POLICY "cp_delete_own" ON public.conversation_participants
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 3. FIX CONVERSATIONS RLS - BREAK RECURSION
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "conversations_select" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update" ON public.conversations;
DROP POLICY IF EXISTS "conversations_delete" ON public.conversations;
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;

-- Direct conversations: user_id column check (no join needed)
CREATE POLICY "conv_select_own" ON public.conversations
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Group conversations: check via security definer function
CREATE POLICY "conv_select_participant" ON public.conversations
    FOR SELECT TO authenticated
    USING (public.user_is_conversation_participant(id));

-- Insert: users can create their own conversations
CREATE POLICY "conv_insert_own" ON public.conversations
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Update: users can update their own conversations
CREATE POLICY "conv_update_own" ON public.conversations
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 4. FIX MESSAGES RLS - ENSURE NO RECURSION
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;
DROP POLICY IF EXISTS "messages_delete" ON public.messages;

-- Users can view messages in conversations they participate in
CREATE POLICY "msg_select_participant" ON public.messages
    FOR SELECT TO authenticated
    USING (public.user_is_conversation_participant(conversation_id));

-- Users can send messages to conversations they're in
CREATE POLICY "msg_insert_participant" ON public.messages
    FOR INSERT TO authenticated
    WITH CHECK (
        sender_id = auth.uid() 
        AND public.user_is_conversation_participant(conversation_id)
    );

-- Users can update their own messages (edit)
CREATE POLICY "msg_update_own" ON public.messages
    FOR UPDATE TO authenticated
    USING (sender_id = auth.uid());

-- Users can delete their own messages
CREATE POLICY "msg_delete_own" ON public.messages
    FOR DELETE TO authenticated
    USING (sender_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 5. FIX MATCHES RLS - AUTHENTICATED ONLY
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "matches_select" ON public.matches;
DROP POLICY IF EXISTS "Users can view their matches" ON public.matches;

CREATE POLICY "matches_select_own" ON public.matches
    FOR SELECT TO authenticated
    USING (user_a_id = auth.uid() OR user_b_id = auth.uid());

-- ════════════════════════════════════════════════════════════════════════════
-- 6. VERIFY RLS IS ENABLED ON ALL SENSITIVE TABLES
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- ════════════════════════════════════════════════════════════════════════════
-- 7. CREATE INDEX FOR PERFORMANCE ON PARTICIPANT LOOKUPS
-- ════════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_cp_user_conv 
    ON public.conversation_participants(user_id, conversation_id);

CREATE INDEX IF NOT EXISTS idx_cp_conv_user 
    ON public.conversation_participants(conversation_id, user_id);

-- ════════════════════════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════════════════════════

COMMENT ON FUNCTION public.user_is_conversation_participant IS 
    'Security definer function to check conversation membership without RLS recursion';
