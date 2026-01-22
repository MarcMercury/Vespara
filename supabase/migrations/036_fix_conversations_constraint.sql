-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 036: FIX CONVERSATIONS MATCH_ID CONSTRAINT
-- Allow NULL match_id for group conversations
-- ═══════════════════════════════════════════════════════════════════════════

-- Make match_id nullable (group conversations don't have a match)
ALTER TABLE public.conversations ALTER COLUMN match_id DROP NOT NULL;

-- Also make user_id nullable if needed for group conversations
ALTER TABLE public.conversations ALTER COLUMN user_id DROP NOT NULL;

-- Reload schema
NOTIFY pgrst, 'reload schema';
