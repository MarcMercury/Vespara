-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║         MIGRATION 080: SECURITY HARDENING — RLS & VIEW FIXES             ║
-- ║                                                                           ║
-- ║   Fixes Supabase linter errors:                                           ║
-- ║   • policy_exists_rls_disabled — Policies exist but RLS not enabled       ║
-- ║   • rls_disabled_in_public — Public tables missing RLS                    ║
-- ║   • security_definer_view — Views using SECURITY DEFINER property         ║
-- ║                                                                           ║
-- ║   Migration 006 disabled RLS on several tables for seeding.               ║
-- ║   This migration re-enables RLS, enables it on tables that never had it,  ║
-- ║   adds appropriate policies, and fixes view security properties.          ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝


-- ════════════════════════════════════════════════════════════════════════════
-- PART 1: RE-ENABLE RLS ON TABLES DISABLED IN MIGRATION 006 FOR SEEDING
--         (These tables already have policies defined from earlier migrations)
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ludus_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roster_matches ENABLE ROW LEVEL SECURITY;


-- ════════════════════════════════════════════════════════════════════════════
-- PART 2: ENABLE RLS ON INTERNAL/ADMIN TABLES
--         No user-facing policies — only service_role can access these.
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.background_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_learning_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_matching_weights ENABLE ROW LEVEL SECURITY;


-- ════════════════════════════════════════════════════════════════════════════
-- PART 3: ENABLE RLS + ADD READ POLICIES ON CONTENT/REFERENCE TABLES
--         These contain game content and reference data — authenticated read.
-- ════════════════════════════════════════════════════════════════════════════

-- spatial_ref_sys (PostGIS reference data — safe to read)
ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read spatial references"
  ON public.spatial_ref_sys FOR SELECT
  USING (true);

-- Game content tables
ALTER TABLE public.game_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read game cards"
  ON public.game_cards FOR SELECT TO authenticated
  USING (true);

ALTER TABLE public.ludus_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read ludus cards"
  ON public.ludus_cards FOR SELECT TO authenticated
  USING (true);

ALTER TABLE public.tags_games ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read games"
  ON public.tags_games FOR SELECT TO authenticated
  USING (true);

ALTER TABLE public.tag_game_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read game categories"
  ON public.tag_game_categories FOR SELECT TO authenticated
  USING (true);

-- Link preview cache — shared, read by any authenticated user
ALTER TABLE public.link_previews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read link previews"
  ON public.link_previews FOR SELECT TO authenticated
  USING (true);
CREATE POLICY "Authenticated users can insert link previews"
  ON public.link_previews FOR INSERT TO authenticated
  WITH CHECK (true);


-- ════════════════════════════════════════════════════════════════════════════
-- PART 4: ENABLE RLS + ADD USER-SCOPED POLICIES
-- ════════════════════════════════════════════════════════════════════════════

-- conversation_topics: participants can read (uses SECURITY DEFINER helper)
ALTER TABLE public.conversation_topics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Conversation participants can read topics"
  ON public.conversation_topics FOR SELECT TO authenticated
  USING (public.user_is_conversation_participant(conversation_id));

-- game_ratings: users manage their own, everyone can read
ALTER TABLE public.game_ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read all game ratings"
  ON public.game_ratings FOR SELECT TO authenticated
  USING (true);
CREATE POLICY "Users can insert own game ratings"
  ON public.game_ratings FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own game ratings"
  ON public.game_ratings FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can delete own game ratings"
  ON public.game_ratings FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- user_compatibility_cache: users can view their own compatibility data
ALTER TABLE public.user_compatibility_cache ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own compatibility scores"
  ON public.user_compatibility_cache FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR other_user_id = auth.uid());

-- event_attendees (legacy table — 058 migrated to vespara_event_rsvps)
ALTER TABLE public.event_attendees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own event attendance"
  ON public.event_attendees FOR SELECT TO authenticated
  USING (user_id = auth.uid());
CREATE POLICY "Users can manage own event attendance"
  ON public.event_attendees FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own event attendance"
  ON public.event_attendees FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can delete own event attendance"
  ON public.event_attendees FOR DELETE TO authenticated
  USING (user_id = auth.uid());


-- ════════════════════════════════════════════════════════════════════════════
-- PART 5: ENABLE RLS ON MESSAGE PARTITION TABLES
--         Policies on the partitioned parent are inherited by partitions.
--         Uses SECURITY DEFINER helper to avoid RLS recursion.
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.messages_partitioned ENABLE ROW LEVEL SECURITY;

-- Enable on each partition individually (required by PostgreSQL)
DO $$
DECLARE
  partition_name TEXT;
BEGIN
  FOR partition_name IN
    SELECT c.relname
    FROM pg_inherits i
    JOIN pg_class c ON c.oid = i.inhrelid
    JOIN pg_class p ON p.oid = i.inhparent
    JOIN pg_namespace n ON n.oid = p.relnamespace
    WHERE p.relname = 'messages_partitioned' AND n.nspname = 'public'
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', partition_name);
  END LOOP;
END $$;

-- Policies on parent — inherited by all partitions
CREATE POLICY "Conversation members can read partitioned messages"
  ON public.messages_partitioned FOR SELECT TO authenticated
  USING (public.user_is_conversation_participant(conversation_id));

CREATE POLICY "Users can send partitioned messages"
  ON public.messages_partitioned FOR INSERT TO authenticated
  WITH CHECK (sender_id = auth.uid());


-- ════════════════════════════════════════════════════════════════════════════
-- PART 6: FIX SECURITY DEFINER VIEWS
--         Set security_invoker = true so RLS of underlying tables applies
--         to the querying user, not the view owner.
-- ════════════════════════════════════════════════════════════════════════════

ALTER VIEW public.connection_stats SET (security_invoker = true);
ALTER VIEW public.tag_rating_popularity SET (security_invoker = true);
ALTER VIEW public.pop_leaderboard SET (security_invoker = true);
ALTER VIEW public.user_groups_summary SET (security_invoker = true);
ALTER VIEW public.tag_daily_stats SET (security_invoker = true);
ALTER VIEW public.tag_dice_analytics SET (security_invoker = true);
ALTER VIEW public.ai_daily_costs SET (security_invoker = true);
ALTER VIEW public.pending_group_invitations SET (security_invoker = true);
