-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 033: FIX CREATE GROUP FUNCTION
-- Drop any old function variants and recreate the correct version
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop all possible function signatures to clean up
DROP FUNCTION IF EXISTS public.create_vespara_group(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_vespara_group(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_vespara_group(TEXT);

-- Recreate the correct function with user_id in conversations
CREATE OR REPLACE FUNCTION public.create_vespara_group(
    p_name TEXT,
    p_description TEXT DEFAULT NULL,
    p_avatar_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_group_id UUID;
    v_conversation_id UUID;
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated to create a group';
    END IF;
    
    -- Check if user can create more groups
    IF NOT public.can_user_join_group(v_user_id) THEN
        RAISE EXCEPTION 'User has reached maximum group limit (10)';
    END IF;
    
    -- Create the Wire conversation for group chat
    -- Include user_id which is required by the conversations table
    INSERT INTO public.conversations (
        user_id,
        conversation_type,
        group_name,
        group_description,
        group_avatar_url,
        group_created_by,
        participant_count,
        only_admins_can_send,
        allow_member_invite
    ) VALUES (
        v_user_id,
        'group',
        p_name,
        p_description,
        p_avatar_url,
        v_user_id,
        1,
        FALSE,
        FALSE
    )
    RETURNING id INTO v_conversation_id;
    
    -- Create the group
    INSERT INTO public.vespara_groups (
        name,
        description,
        avatar_url,
        creator_id,
        conversation_id
    ) VALUES (
        p_name,
        p_description,
        p_avatar_url,
        v_user_id,
        v_conversation_id
    )
    RETURNING id INTO v_group_id;
    
    -- Add creator as first member
    INSERT INTO public.group_members (
        group_id,
        user_id,
        status,
        role
    ) VALUES (
        v_group_id,
        v_user_id,
        'active',
        'creator'
    );
    
    -- Add creator as conversation participant (if conversation_participants table exists)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'conversation_participants') THEN
        INSERT INTO public.conversation_participants (
            conversation_id,
            user_id,
            is_admin
        ) VALUES (
            v_conversation_id,
            v_user_id,
            TRUE
        )
        ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN v_group_id;
END;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.create_vespara_group(TEXT, TEXT, TEXT) TO authenticated;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
