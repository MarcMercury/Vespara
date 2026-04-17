-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║         MIGRATION 077: FIX MESSAGE INSERT TRIGGER - match_id ERROR        ║
-- ║                                                                           ║
-- ║   Error: record "new" has no field "match_id" (42703) on messages INSERT  ║
-- ║                                                                           ║
-- ║   The update_match_momentum() function references NEW.match_id, which     ║
-- ║   is valid on roster_matches but not on messages. If this function was    ║
-- ║   attached as a trigger on messages (either manually or via an older      ║
-- ║   migration state), it breaks message sending.                            ║
-- ║                                                                           ║
-- ║   Fix: Drop all known rogue triggers on messages, then recreate only      ║
-- ║   the valid triggers.                                                     ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════════════════
-- 1. DROP ALL TRIGGERS ON MESSAGES TO CLEAN SLATE
-- ════════════════════════════════════════════════════════════════════════════

-- Drop the known valid triggers (will re-create below)
DROP TRIGGER IF EXISTS on_message_insert ON public.messages;
DROP TRIGGER IF EXISTS update_relationship_metrics_on_message ON public.messages;

-- Drop any rogue triggers that may have been added manually
DROP TRIGGER IF EXISTS update_match_momentum ON public.messages;
DROP TRIGGER IF EXISTS update_match_momentum_trigger ON public.messages;
DROP TRIGGER IF EXISTS on_new_message ON public.messages;
DROP TRIGGER IF EXISTS after_message_insert ON public.messages;
DROP TRIGGER IF EXISTS handle_new_message ON public.messages;
DROP TRIGGER IF EXISTS message_insert_trigger ON public.messages;
DROP TRIGGER IF EXISTS update_conversation_on_message ON public.messages;

-- Catch-all: drop ALL remaining triggers on messages via dynamic SQL
DO $$
DECLARE
    trig RECORD;
BEGIN
    FOR trig IN
        SELECT tgname
        FROM pg_trigger
        WHERE tgrelid = 'public.messages'::regclass
          AND NOT tgisinternal
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.messages', trig.tgname);
    END LOOP;
END $$;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. RECREATE THE VALID update_conversation_last_message TRIGGER
--    This updates the conversation's last_message fields on new messages.
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET
        last_message = CASE
            WHEN NEW.message_type = 'text' THEN LEFT(NEW.content, 200)
            WHEN NEW.message_type = 'image' THEN '📷 Photo'
            WHEN NEW.message_type = 'video' THEN '🎬 Video'
            WHEN NEW.message_type = 'voice' THEN '🎤 Voice note'
            WHEN NEW.message_type = 'audio' THEN '🎵 Audio'
            WHEN NEW.message_type = 'file' THEN '📎 File'
            WHEN NEW.message_type = 'gif' THEN 'GIF'
            WHEN NEW.message_type = 'location' THEN '📍 Location'
            WHEN NEW.message_type = 'contact' THEN '👤 Contact'
            WHEN NEW.message_type = 'poll' THEN '📊 Poll'
            WHEN NEW.message_type = 'system' THEN NEW.content
            ELSE NEW.content
        END,
        last_message_at = NEW.created_at,
        last_message_sender_id = NEW.sender_id,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;

    -- Increment unread count for other participants
    UPDATE public.conversation_participants
    SET unread_count = COALESCE(unread_count, 0) + 1
    WHERE conversation_id = NEW.conversation_id
      AND user_id != NEW.sender_id
      AND COALESCE(is_active, TRUE) = TRUE;

    -- Add to media gallery if applicable
    IF NEW.message_type IN ('image', 'video', 'audio', 'voice', 'file')
       AND NEW.media_url IS NOT NULL THEN
        INSERT INTO public.conversation_media (
            conversation_id, message_id, sender_id,
            media_type, media_url, thumbnail_url,
            filename, filesize_bytes
        ) VALUES (
            NEW.conversation_id, NEW.id, NEW.sender_id,
            NEW.message_type, NEW.media_url, NEW.media_thumbnail_url,
            NEW.media_filename, NEW.media_filesize_bytes
        )
        ON CONFLICT DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_message_insert
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.update_conversation_last_message();

-- ════════════════════════════════════════════════════════════════════════════
-- 3. RECREATE THE VALID relationship_metrics TRIGGER (from migration 026)
--    This looks up match_id from conversations table (not from NEW).
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.trigger_update_relationship_metrics()
RETURNS TRIGGER AS $$
DECLARE
    v_match_id UUID;
BEGIN
    SELECT c.match_id INTO v_match_id
    FROM public.conversations c
    WHERE c.id = NEW.conversation_id;

    IF v_match_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'relationship_metrics'
    ) THEN
        PERFORM public.update_relationship_metrics(v_match_id);
    END IF;
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Don't fail message insert if metrics update fails
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'public' AND table_name = 'relationship_metrics') THEN
        CREATE TRIGGER update_relationship_metrics_on_message
            AFTER INSERT ON public.messages
            FOR EACH ROW EXECUTE FUNCTION public.trigger_update_relationship_metrics();
    END IF;
END $$;

-- ════════════════════════════════════════════════════════════════════════════
-- 4. RELOAD SCHEMA
-- ════════════════════════════════════════════════════════════════════════════

NOTIFY pgrst, 'reload schema';
