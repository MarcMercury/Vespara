-- ═══════════════════════════════════════════════════════════════════════════
-- WIRE PERFORMANCE INDEXES
-- Adds missing indexes for conversation sorting and participant queries
-- ═══════════════════════════════════════════════════════════════════════════

-- Index for sorting conversations by last message time (newest first)
-- This is critical for the chat list to load quickly
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at 
    ON public.conversations(last_message_at DESC NULLS LAST);

-- Composite index for user's conversations sorted by activity
CREATE INDEX IF NOT EXISTS idx_participants_user_active
    ON public.conversation_participants(user_id, is_active)
    WHERE is_active = true;

-- Index for quick unread count queries per user
CREATE INDEX IF NOT EXISTS idx_participants_unread
    ON public.conversation_participants(user_id, unread_count)
    WHERE unread_count > 0;

-- Index for archived conversations lookup
CREATE INDEX IF NOT EXISTS idx_conversations_archived
    ON public.conversations(is_archived, last_message_at DESC)
    WHERE is_archived = true;

-- Index for pinned conversations
CREATE INDEX IF NOT EXISTS idx_conversations_pinned
    ON public.conversations(is_pinned, pin_order)
    WHERE is_pinned = true;

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMENT
-- ═══════════════════════════════════════════════════════════════════════════

COMMENT ON INDEX idx_conversations_last_message_at IS 
    'Enables fast sorting of conversations by most recent activity';
