-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║    MIGRATION 081: FIX SECURITY DEFINER FUNCTIONS MISSING search_path     ║
-- ║                                                                           ║
-- ║    SECURITY DEFINER functions execute with the privileges of the          ║
-- ║    function owner. Without a pinned search_path, an attacker could        ║
-- ║    create objects in a schema that shadows public tables, tricking        ║
-- ║    the function into operating on attacker-controlled data.               ║
-- ║                                                                           ║
-- ║    Fix: ALTER FUNCTION ... SET search_path = public;                      ║
-- ║    Wrapped in exception handlers so missing functions don't block.        ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

DO $$
DECLARE
  _sql TEXT;
  _statements TEXT[] := ARRAY[
    -- 066_admin_portal.sql
    'ALTER FUNCTION public.is_admin(UUID) SET search_path = public',
    'ALTER FUNCTION public.admin_get_token_summary(UUID) SET search_path = public',
    'ALTER FUNCTION public.admin_list_users(TEXT, TEXT, BOOLEAN, INTEGER, INTEGER) SET search_path = public',
    'ALTER FUNCTION public.track_user_login(UUID) SET search_path = public',
    -- 078_notification_triggers.sql
    'ALTER FUNCTION public.notify_on_new_match() SET search_path = public',
    'ALTER FUNCTION public.notify_on_new_like() SET search_path = public',
    'ALTER FUNCTION public.notify_on_new_message() SET search_path = public',
    'ALTER FUNCTION public.get_unread_notification_count(UUID) SET search_path = public',
    -- 028_vespara_groups.sql
    'ALTER FUNCTION public.accept_group_invitation(UUID) SET search_path = public',
    'ALTER FUNCTION public.decline_group_invitation(UUID) SET search_path = public',
    'ALTER FUNCTION public.leave_vespara_group(UUID) SET search_path = public',
    'ALTER FUNCTION public.send_group_invitation(UUID, UUID, TEXT) SET search_path = public',
    'ALTER FUNCTION public.delete_vespara_group(UUID) SET search_path = public',
    -- 067_enhanced_photos_notifications.sql
    'ALTER FUNCTION public.record_photo_view(UUID, UUID) SET search_path = public',
    'ALTER FUNCTION public.cleanup_expired_photos() SET search_path = public',
    -- 068_mfa_email_otp.sql
    'ALTER FUNCTION public.cleanup_expired_mfa_codes() SET search_path = public',
    -- 005_scalability_1m_users.sql
    'ALTER FUNCTION public.generate_daily_matches(UUID, INT) SET search_path = public',
    -- 001_initial_schema.sql
    'ALTER FUNCTION public.get_nearby_users(UUID, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) SET search_path = public',
    -- 008_wire_group_chat.sql
    'ALTER FUNCTION public.create_group_conversation(UUID, TEXT, UUID[]) SET search_path = public',
    'ALTER FUNCTION public.add_group_participant(UUID, UUID, UUID) SET search_path = public',
    'ALTER FUNCTION public.update_conversation_last_message() SET search_path = public',
    'ALTER FUNCTION public.mark_messages_read(UUID, UUID, UUID) SET search_path = public',
    -- 079_travel_crosspath_notifications.sql
    'ALTER FUNCTION public.notify_travel_crosspaths() SET search_path = public',
    'ALTER FUNCTION public.cleanup_cancelled_crosspaths() SET search_path = public'
  ];
BEGIN
  FOREACH _sql IN ARRAY _statements LOOP
    BEGIN
      EXECUTE _sql;
    EXCEPTION WHEN undefined_function THEN
      RAISE NOTICE 'Skipping (function does not exist): %', _sql;
    END;
  END LOOP;
END
$$;
