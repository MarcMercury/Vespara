-- ============================================
-- VESPARA WIRE - WHATSAPP-STYLE GROUP MESSAGING
-- Migration 008: Full group chat, voice notes, file sharing
-- ============================================

-- ============================================
-- 1. ENHANCED CONVERSATIONS TABLE
-- Support both 1:1 and group conversations
-- ============================================

-- Drop old constraints if they exist
ALTER TABLE public.conversations DROP CONSTRAINT IF EXISTS conversations_match_id_fkey;

-- Recreate conversations table with group support
-- First, add new columns to existing table
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS conversation_type TEXT DEFAULT 'direct' CHECK (conversation_type IN ('direct', 'group'));
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS group_name TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS group_description TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS group_avatar_url TEXT;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS group_created_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS is_muted BOOLEAN DEFAULT FALSE;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS muted_until TIMESTAMPTZ;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS pin_order INTEGER DEFAULT 0;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS last_read_message_id UUID;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS participant_count INTEGER DEFAULT 2;
-- For group settings
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS only_admins_can_send BOOLEAN DEFAULT FALSE;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS only_admins_can_edit_info BOOLEAN DEFAULT FALSE;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS allow_member_invite BOOLEAN DEFAULT TRUE;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS disappearing_messages_seconds INTEGER; -- null = never, otherwise auto-delete
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================
-- 2. CONVERSATION PARTICIPANTS
-- For group membership management
-- ============================================

CREATE TABLE IF NOT EXISTS public.conversation_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- Role and permissions
    role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    can_send_messages BOOLEAN DEFAULT TRUE,
    can_add_members BOOLEAN DEFAULT FALSE,
    -- Status
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    added_by UUID REFERENCES public.profiles(id),
    left_at TIMESTAMPTZ,
    removed_by UUID REFERENCES public.profiles(id),
    is_active BOOLEAN DEFAULT TRUE,
    -- Read state
    last_read_at TIMESTAMPTZ,
    last_read_message_id UUID,
    unread_count INTEGER DEFAULT 0,
    -- Notifications
    is_muted BOOLEAN DEFAULT FALSE,
    muted_until TIMESTAMPTZ,
    custom_notification_sound TEXT,
    -- Metadata
    nickname TEXT, -- Custom nickname shown in this chat
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own participations" ON public.conversation_participants
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view participants in their conversations" ON public.conversation_participants
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp 
            WHERE cp.conversation_id = conversation_id AND cp.user_id = auth.uid() AND cp.is_active = TRUE
        )
    );

CREATE POLICY "Admins can manage participants" ON public.conversation_participants
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp 
            WHERE cp.conversation_id = conversation_id 
            AND cp.user_id = auth.uid() 
            AND cp.role = 'admin' 
            AND cp.is_active = TRUE
        )
    );

CREATE INDEX IF NOT EXISTS idx_participants_conversation ON public.conversation_participants(conversation_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_participants_user ON public.conversation_participants(user_id) WHERE is_active = TRUE;

-- ============================================
-- 3. ENHANCED MESSAGES TABLE
-- Voice notes, files, reactions, replies, etc.
-- ============================================

-- Ensure base messages table exists
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add enhanced message fields
-- Note: message_type might conflict with 007, so we add it without the CHECK constraint
-- The CHECK constraint was already added in 007
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text';
-- Media attachments
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_thumbnail_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_filename TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_filesize_bytes BIGINT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_mime_type TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_width INTEGER;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_height INTEGER;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_duration_seconds INTEGER; -- For audio/video
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_waveform JSONB; -- Audio waveform data for voice notes
-- Reply threading
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.messages(id);
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_preview TEXT; -- Cached preview of replied message
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reply_sender_name TEXT;
-- Forwarding
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS forwarded_from_id UUID REFERENCES public.messages(id);
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS forward_count INTEGER DEFAULT 0;
-- Location sharing
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS location_lat DOUBLE PRECISION;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS location_lng DOUBLE PRECISION;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS location_name TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS location_address TEXT;
-- Contact sharing
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS shared_contact_id UUID REFERENCES public.profiles(id);
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS shared_contact_name TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS shared_contact_phone TEXT;
-- Poll data
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS poll_question TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS poll_options JSONB; -- [{id: 'uuid', text: 'Option', votes: ['user_id1', 'user_id2']}]
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS poll_allows_multiple BOOLEAN DEFAULT FALSE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS poll_ends_at TIMESTAMPTZ;
-- Reactions
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '[]'::jsonb; -- [{emoji: '❤️', user_ids: ['uuid1', 'uuid2']}]
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS reaction_count INTEGER DEFAULT 0;
-- Status tracking
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'sent' CHECK (status IN ('sending', 'sent', 'delivered', 'read', 'failed'));
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS delivered_to JSONB DEFAULT '[]'::jsonb; -- [{user_id: 'uuid', at: 'timestamp'}]
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS read_by JSONB DEFAULT '[]'::jsonb; -- [{user_id: 'uuid', at: 'timestamp'}]
-- Editing/deletion
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT FALSE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS original_content TEXT; -- Store original if edited
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS deleted_for_everyone BOOLEAN DEFAULT FALSE;
-- Starring/pinning
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS starred_by JSONB DEFAULT '[]'::jsonb; -- user_ids who starred this
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS pinned_at TIMESTAMPTZ;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS pinned_by UUID REFERENCES public.profiles(id);
-- Auto-delete
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;
-- Metadata
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS client_message_id TEXT; -- For deduplication
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages in their conversations" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp 
            WHERE cp.conversation_id = conversation_id 
            AND cp.user_id = auth.uid() 
            AND cp.is_active = TRUE
        )
    );

CREATE POLICY "Users can send messages to their conversations" ON public.messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp 
            WHERE cp.conversation_id = conversation_id 
            AND cp.user_id = auth.uid() 
            AND cp.is_active = TRUE
            AND cp.can_send_messages = TRUE
        )
    );

CREATE POLICY "Users can update their own messages" ON public.messages
    FOR UPDATE USING (auth.uid() = sender_id);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_reply ON public.messages(reply_to_id) WHERE reply_to_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_messages_type ON public.messages(message_type) WHERE message_type != 'text';
CREATE INDEX IF NOT EXISTS idx_messages_starred ON public.messages(conversation_id) WHERE starred_by != '[]'::jsonb;
CREATE INDEX IF NOT EXISTS idx_messages_pinned ON public.messages(conversation_id, pinned_at DESC) WHERE is_pinned = TRUE;

-- ============================================
-- 4. MESSAGE READ RECEIPTS (Separate table for efficiency)
-- ============================================

CREATE TABLE IF NOT EXISTS public.message_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('delivered', 'read')),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(message_id, user_id, status)
);

ALTER TABLE public.message_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view receipts for messages in their conversations" ON public.message_receipts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.messages m 
            JOIN public.conversation_participants cp ON cp.conversation_id = m.conversation_id
            WHERE m.id = message_id AND cp.user_id = auth.uid() AND cp.is_active = TRUE
        )
    );

CREATE INDEX IF NOT EXISTS idx_receipts_message ON public.message_receipts(message_id);
CREATE INDEX IF NOT EXISTS idx_receipts_user ON public.message_receipts(user_id);

-- ============================================
-- 5. MEDIA ATTACHMENTS (For grouped media)
-- ============================================

CREATE TABLE IF NOT EXISTS public.message_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    attachment_type TEXT NOT NULL CHECK (
        attachment_type IN ('image', 'video', 'audio', 'voice', 'file', 'gif', 'sticker')
    ),
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    filename TEXT,
    filesize_bytes BIGINT,
    mime_type TEXT,
    width INTEGER,
    height INTEGER,
    duration_seconds INTEGER,
    waveform JSONB, -- For audio
    -- Upload status
    upload_status TEXT DEFAULT 'completed' CHECK (upload_status IN ('uploading', 'completed', 'failed')),
    upload_progress DOUBLE PRECISION DEFAULT 1.0,
    -- Encryption (for sensitive content)
    is_encrypted BOOLEAN DEFAULT FALSE,
    encryption_key TEXT,
    -- Order for multiple attachments
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.message_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view attachments in their conversations" ON public.message_attachments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.messages m 
            JOIN public.conversation_participants cp ON cp.conversation_id = m.conversation_id
            WHERE m.id = message_id AND cp.user_id = auth.uid() AND cp.is_active = TRUE
        )
    );

CREATE INDEX IF NOT EXISTS idx_attachments_message ON public.message_attachments(message_id);

-- ============================================
-- 6. TYPING INDICATORS (Realtime)
-- ============================================

CREATE TABLE IF NOT EXISTS public.typing_indicators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

ALTER TABLE public.typing_indicators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see typing in their conversations" ON public.typing_indicators
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp 
            WHERE cp.conversation_id = conversation_id AND cp.user_id = auth.uid() AND cp.is_active = TRUE
        )
    );

-- Auto-delete stale typing indicators (older than 10 seconds)
CREATE OR REPLACE FUNCTION cleanup_typing_indicators()
RETURNS void AS $$
BEGIN
    DELETE FROM public.typing_indicators WHERE started_at < NOW() - INTERVAL '10 seconds';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. STARRED MESSAGES (Personal favorites)
-- ============================================

CREATE TABLE IF NOT EXISTS public.starred_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    starred_at TIMESTAMPTZ DEFAULT NOW(),
    note TEXT, -- Optional personal note about why starred
    UNIQUE(user_id, message_id)
);

ALTER TABLE public.starred_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their starred messages" ON public.starred_messages
    FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_starred_user ON public.starred_messages(user_id, starred_at DESC);

-- ============================================
-- 8. MEDIA GALLERY (Quick access to shared media)
-- ============================================

CREATE TABLE IF NOT EXISTS public.conversation_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'audio', 'voice', 'file', 'link')),
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,
    filename TEXT,
    filesize_bytes BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.conversation_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view media in their conversations" ON public.conversation_media
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp 
            WHERE cp.conversation_id = conversation_id AND cp.user_id = auth.uid() AND cp.is_active = TRUE
        )
    );

CREATE INDEX IF NOT EXISTS idx_convo_media ON public.conversation_media(conversation_id, media_type, created_at DESC);

-- ============================================
-- 9. LINKS PREVIEW CACHE
-- ============================================

CREATE TABLE IF NOT EXISTS public.link_previews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    url TEXT NOT NULL UNIQUE,
    title TEXT,
    description TEXT,
    image_url TEXT,
    favicon_url TEXT,
    site_name TEXT,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days')
);

CREATE INDEX IF NOT EXISTS idx_link_previews_url ON public.link_previews(url);

-- ============================================
-- 10. GROUP INVITE LINKS
-- ============================================

CREATE TABLE IF NOT EXISTS public.group_invite_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    invite_code TEXT NOT NULL UNIQUE,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    expires_at TIMESTAMPTZ,
    max_uses INTEGER,
    use_count INTEGER DEFAULT 0,
    is_revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMPTZ,
    revoked_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.group_invite_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage invite links" ON public.group_invite_links
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp 
            WHERE cp.conversation_id = conversation_id 
            AND cp.user_id = auth.uid() 
            AND cp.role = 'admin' 
            AND cp.is_active = TRUE
        )
    );

CREATE INDEX IF NOT EXISTS idx_invite_links_code ON public.group_invite_links(invite_code) WHERE NOT is_revoked;

-- ============================================
-- FUNCTIONS: Create Group Conversation
-- ============================================

CREATE OR REPLACE FUNCTION create_group_conversation(
    p_creator_id UUID,
    p_group_name TEXT,
    p_participant_ids UUID[],
    p_group_avatar_url TEXT DEFAULT NULL,
    p_group_description TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_participant_id UUID;
BEGIN
    -- Create the conversation
    INSERT INTO public.conversations (
        user_id,
        conversation_type,
        group_name,
        group_description,
        group_avatar_url,
        group_created_by,
        participant_count
    ) VALUES (
        p_creator_id,
        'group',
        p_group_name,
        p_group_description,
        p_group_avatar_url,
        p_creator_id,
        array_length(p_participant_ids, 1) + 1
    )
    RETURNING id INTO v_conversation_id;
    
    -- Add creator as admin
    INSERT INTO public.conversation_participants (
        conversation_id,
        user_id,
        role,
        can_add_members,
        added_by
    ) VALUES (
        v_conversation_id,
        p_creator_id,
        'admin',
        TRUE,
        p_creator_id
    );
    
    -- Add other participants as members
    FOREACH v_participant_id IN ARRAY p_participant_ids
    LOOP
        IF v_participant_id != p_creator_id THEN
            INSERT INTO public.conversation_participants (
                conversation_id,
                user_id,
                role,
                added_by
            ) VALUES (
                v_conversation_id,
                v_participant_id,
                'member',
                p_creator_id
            );
        END IF;
    END LOOP;
    
    -- Create system message announcing group creation
    INSERT INTO public.messages (
        conversation_id,
        sender_id,
        message_type,
        content
    ) VALUES (
        v_conversation_id,
        p_creator_id,
        'system',
        'created the group "' || p_group_name || '"'
    );
    
    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Add Participant to Group
-- ============================================

CREATE OR REPLACE FUNCTION add_group_participant(
    p_conversation_id UUID,
    p_new_user_id UUID,
    p_added_by UUID
)
RETURNS void AS $$
BEGIN
    -- Verify the adder has permission
    IF NOT EXISTS (
        SELECT 1 FROM public.conversation_participants 
        WHERE conversation_id = p_conversation_id 
        AND user_id = p_added_by 
        AND is_active = TRUE
        AND (role = 'admin' OR can_add_members = TRUE)
    ) THEN
        RAISE EXCEPTION 'You do not have permission to add members';
    END IF;
    
    -- Add the participant
    INSERT INTO public.conversation_participants (
        conversation_id,
        user_id,
        added_by
    ) VALUES (
        p_conversation_id,
        p_new_user_id,
        p_added_by
    )
    ON CONFLICT (conversation_id, user_id) 
    DO UPDATE SET 
        is_active = TRUE, 
        left_at = NULL, 
        removed_by = NULL,
        joined_at = NOW();
    
    -- Update participant count
    UPDATE public.conversations 
    SET participant_count = (
        SELECT COUNT(*) FROM public.conversation_participants 
        WHERE conversation_id = p_conversation_id AND is_active = TRUE
    )
    WHERE id = p_conversation_id;
    
    -- Create system message
    INSERT INTO public.messages (
        conversation_id,
        sender_id,
        message_type,
        content
    ) VALUES (
        p_conversation_id,
        p_added_by,
        'system',
        'added ' || (SELECT display_name FROM public.profiles WHERE id = p_new_user_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Update Conversation Last Message
-- ============================================

CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Update conversation's last message info
    UPDATE public.conversations 
    SET 
        last_message = CASE 
            WHEN NEW.message_type = 'text' THEN NEW.content
            WHEN NEW.message_type = 'image' THEN '📷 Photo'
            WHEN NEW.message_type = 'video' THEN '🎥 Video'
            WHEN NEW.message_type = 'voice' THEN '🎤 Voice message'
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
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    -- Increment unread count for other participants
    UPDATE public.conversation_participants 
    SET unread_count = unread_count + 1
    WHERE conversation_id = NEW.conversation_id 
    AND user_id != NEW.sender_id
    AND is_active = TRUE;
    
    -- Add to media gallery if applicable
    IF NEW.message_type IN ('image', 'video', 'audio', 'voice', 'file') AND NEW.media_url IS NOT NULL THEN
        INSERT INTO public.conversation_media (
            conversation_id,
            message_id,
            sender_id,
            media_type,
            media_url,
            thumbnail_url,
            filename,
            filesize_bytes
        ) VALUES (
            NEW.conversation_id,
            NEW.id,
            NEW.sender_id,
            NEW.message_type,
            NEW.media_url,
            NEW.media_thumbnail_url,
            NEW.media_filename,
            NEW.media_filesize_bytes
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_insert ON public.messages;
CREATE TRIGGER on_message_insert
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION update_conversation_last_message();

-- ============================================
-- FUNCTION: Mark Messages as Read
-- ============================================

CREATE OR REPLACE FUNCTION mark_messages_read(
    p_conversation_id UUID,
    p_user_id UUID,
    p_up_to_message_id UUID DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    -- Update participant's read state
    UPDATE public.conversation_participants 
    SET 
        last_read_at = NOW(),
        last_read_message_id = COALESCE(p_up_to_message_id, (
            SELECT id FROM public.messages 
            WHERE conversation_id = p_conversation_id 
            ORDER BY created_at DESC LIMIT 1
        )),
        unread_count = 0
    WHERE conversation_id = p_conversation_id AND user_id = p_user_id;
    
    -- Add read receipts
    INSERT INTO public.message_receipts (message_id, user_id, status)
    SELECT m.id, p_user_id, 'read'
    FROM public.messages m
    WHERE m.conversation_id = p_conversation_id
    AND m.sender_id != p_user_id
    AND (p_up_to_message_id IS NULL OR m.created_at <= (
        SELECT created_at FROM public.messages WHERE id = p_up_to_message_id
    ))
    AND NOT EXISTS (
        SELECT 1 FROM public.message_receipts mr 
        WHERE mr.message_id = m.id AND mr.user_id = p_user_id AND mr.status = 'read'
    )
    ON CONFLICT (message_id, user_id, status) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- REALTIME: Enable for chat features
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.typing_indicators;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversation_participants;

-- ============================================
-- STORAGE: Buckets for chat media
-- ============================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'chat-media',
    'chat-media',
    FALSE,
    52428800, -- 50MB
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 
          'video/mp4', 'video/quicktime', 'video/webm',
          'audio/mpeg', 'audio/mp4', 'audio/ogg', 'audio/webm', 'audio/wav',
          'application/pdf', 'application/msword', 
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.ms-excel',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'text/plain', 'text/csv']
)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for chat media
CREATE POLICY "Users can upload chat media" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'chat-media' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view chat media in their conversations" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'chat-media' AND
        auth.uid() IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.user_id = auth.uid()
            AND cp.is_active = TRUE
            AND cp.conversation_id::text = (storage.foldername(name))[2]
        )
    );

-- ============================================
-- GRANTS
-- ============================================

GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
