-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║         MIGRATION 078: NOTIFICATION TRIGGERS FOR CORE FEATURES           ║
-- ║                                                                           ║
-- ║   Adds automatic notification creation for:                               ║
-- ║   1. New matches (mutual swipes) → notify both users                      ║
-- ║   2. New likes (right/super swipes) → notify the liked user               ║
-- ║   3. New messages → notify recipient                                      ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════════════════
-- 1. NOTIFY ON NEW MATCH
--    When a match is created, notify both users
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION notify_on_new_match()
RETURNS TRIGGER AS $$
DECLARE
    user_a_name TEXT;
    user_b_name TEXT;
BEGIN
    -- Get display names
    SELECT COALESCE(display_name, 'Someone') INTO user_a_name
    FROM public.profiles WHERE id = NEW.user_a_id;

    SELECT COALESCE(display_name, 'Someone') INTO user_b_name
    FROM public.profiles WHERE id = NEW.user_b_id;

    -- Notify user A
    INSERT INTO public.notifications (user_id, type, title, message, data, action_url)
    VALUES (
        NEW.user_a_id,
        'new_match',
        'New Match!',
        'You matched with ' || user_b_name || '! Start a conversation.',
        jsonb_build_object(
            'match_id', NEW.id,
            'matched_user_id', NEW.user_b_id,
            'matched_user_name', user_b_name,
            'is_super_match', NEW.is_super_match
        ),
        '/wire'
    );

    -- Notify user B
    INSERT INTO public.notifications (user_id, type, title, message, data, action_url)
    VALUES (
        NEW.user_b_id,
        'new_match',
        'New Match!',
        'You matched with ' || user_a_name || '! Start a conversation.',
        jsonb_build_object(
            'match_id', NEW.id,
            'matched_user_id', NEW.user_a_id,
            'matched_user_name', user_a_name,
            'is_super_match', NEW.is_super_match
        ),
        '/wire'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS notify_match_created ON public.matches;
CREATE TRIGGER notify_match_created
    AFTER INSERT ON public.matches
    FOR EACH ROW EXECUTE FUNCTION notify_on_new_match();


-- ════════════════════════════════════════════════════════════════════════════
-- 2. NOTIFY ON NEW LIKE (right/super swipe)
--    When someone likes you, create a notification (without revealing identity
--    to preserve the mutual-reveal mechanic — just say "Someone liked you")
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION notify_on_new_like()
RETURNS TRIGGER AS $$
BEGIN
    -- Only notify on right/super swipes
    IF NEW.direction NOT IN ('right', 'super') THEN
        RETURN NEW;
    END IF;

    -- Create notification for the liked user
    -- Note: We intentionally do NOT reveal who liked them to preserve the dating mechanic
    INSERT INTO public.notifications (user_id, type, title, message, data, action_url)
    VALUES (
        NEW.swiped_id,
        'new_like',
        CASE WHEN NEW.direction = 'super' THEN 'Someone Super Liked You!'
             ELSE 'Someone Likes You!'
        END,
        CASE WHEN NEW.direction = 'super' THEN 'A member is very interested in you. Keep swiping to find out who!'
             ELSE 'A member is interested in you. Keep swiping to find out who!'
        END,
        jsonb_build_object(
            'swipe_direction', NEW.direction,
            'is_super', NEW.direction = 'super'
        ),
        '/browse'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS notify_like_created ON public.swipes;
CREATE TRIGGER notify_like_created
    AFTER INSERT ON public.swipes
    FOR EACH ROW EXECUTE FUNCTION notify_on_new_like();


-- ════════════════════════════════════════════════════════════════════════════
-- 3. NOTIFY ON NEW MESSAGE
--    When a message is sent, notify the other participants in the conversation
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION notify_on_new_message()
RETURNS TRIGGER AS $$
DECLARE
    sender_name TEXT;
    conv_user RECORD;
    msg_preview TEXT;
BEGIN
    -- Get sender's display name
    SELECT COALESCE(display_name, 'Someone') INTO sender_name
    FROM public.profiles WHERE id = NEW.sender_id;

    -- Truncate message for preview
    msg_preview := LEFT(NEW.content, 100);
    IF LENGTH(NEW.content) > 100 THEN
        msg_preview := msg_preview || '...';
    END IF;

    -- Notify all other participants in this conversation
    FOR conv_user IN
        SELECT DISTINCT user_id
        FROM public.conversations
        WHERE (match_link_id = (
            SELECT match_link_id FROM public.conversations
            WHERE id = NEW.conversation_id
            LIMIT 1
        ) OR id = NEW.conversation_id)
        AND user_id != NEW.sender_id
    LOOP
        INSERT INTO public.notifications (user_id, type, title, message, data, action_url)
        VALUES (
            conv_user.user_id,
            'new_message',
            'New Message from ' || sender_name,
            msg_preview,
            jsonb_build_object(
                'conversation_id', NEW.conversation_id,
                'message_id', NEW.id,
                'sender_id', NEW.sender_id,
                'sender_name', sender_name
            ),
            '/wire'
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS notify_message_created ON public.messages;
CREATE TRIGGER notify_message_created
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION notify_on_new_message();


-- ════════════════════════════════════════════════════════════════════════════
-- 4. HELPER: Unread notification count function
--    Used by the app to display badge counts efficiently
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.notifications
        WHERE user_id = p_user_id
        AND is_read = FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ════════════════════════════════════════════════════════════════════════════
-- 5. INDEX for fast unread notification lookups
-- ════════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
    ON public.notifications (user_id, is_read)
    WHERE is_read = FALSE;

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
    ON public.notifications (user_id, created_at DESC);
