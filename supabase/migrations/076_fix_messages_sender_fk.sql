-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║         MIGRATION 075: FIX MESSAGES SENDER FK + CONVERSATION NAMES        ║
-- ║                                                                           ║
-- ║   Issue 1: messages.sender_id has no FK to profiles, causing PostgREST    ║
-- ║   PGRST200 error on `profiles:sender_id(display_name, avatar_url)`.       ║
-- ║   Migration 001 omitted the FK; migration 008 tried CREATE TABLE IF NOT   ║
-- ║   EXISTS with the FK but the table already existed so it was a no-op.     ║
-- ║                                                                           ║
-- ║   Issue 2: conversations table lacks match_name/match_avatar_url columns  ║
-- ║   for direct chats, so the UI shows "Unknown".                            ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════════════════
-- 1. ADD MISSING FK: messages.sender_id → profiles.id
-- ════════════════════════════════════════════════════════════════════════════

-- Drop if somehow exists (idempotent)
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;

-- Add the FK so PostgREST can resolve profiles:sender_id(...) joins
ALTER TABLE public.messages
    ADD CONSTRAINT messages_sender_id_fkey
    FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. ADD DISPLAY COLUMNS TO CONVERSATIONS FOR DIRECT CHATS
--    So the UI can show the other user's name/avatar without extra queries.
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS match_name TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS match_avatar_url TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS last_message_sender_id UUID;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS last_message_sender_name TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS last_message_type TEXT;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. BACKFILL match_name/match_avatar_url FOR EXISTING DIRECT CONVERSATIONS
--    Looks up the "other" user in the conversation via conversation_participants.
-- ════════════════════════════════════════════════════════════════════════════

UPDATE public.conversations c
SET
    match_name = p.display_name,
    match_avatar_url = p.avatar_url
FROM public.conversation_participants cp
JOIN public.profiles p ON p.id = cp.user_id
WHERE cp.conversation_id = c.id
  AND c.conversation_type = 'direct'
  AND c.match_id IS NOT NULL
  AND cp.user_id = c.match_id
  AND c.match_name IS NULL;

-- Also backfill where match_id equals the OTHER user (not the creator)
UPDATE public.conversations c
SET
    match_name = p.display_name,
    match_avatar_url = p.avatar_url
FROM public.profiles p
WHERE p.id = c.match_id
  AND c.conversation_type = 'direct'
  AND c.match_name IS NULL;

-- ════════════════════════════════════════════════════════════════════════════
-- 4. RELOAD POSTGREST SCHEMA CACHE
-- ════════════════════════════════════════════════════════════════════════════

NOTIFY pgrst, 'reload schema';
