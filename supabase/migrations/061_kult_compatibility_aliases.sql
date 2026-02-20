-- ═══════════════════════════════════════════════════════════════════════════
-- KULT PHASE 2: COMPATIBILITY ALIASES (NON-BREAKING)
-- ═══════════════════════════════════════════════════════════════════════════
-- Purpose:
--   1) Add new kult_* aliases without renaming existing vespara_* objects.
--   2) Provide forward-compatible RPC names for group operations.
--
-- Safety:
--   - No existing table/function is dropped or renamed.
--   - Existing runtime paths remain unchanged.
--   - Views are read-only aliases and currently granted to service_role only.
--
-- Rollback:
--   DROP VIEW IF EXISTS public.kult_event_rsvps;
--   DROP VIEW IF EXISTS public.kult_events;
--   DROP VIEW IF EXISTS public.kult_groups;
--   DROP FUNCTION IF EXISTS public.create_kult_group(TEXT, TEXT, TEXT);
--   DROP FUNCTION IF EXISTS public.leave_kult_group(UUID);
--   DROP FUNCTION IF EXISTS public.delete_kult_group(UUID);

-- ═══════════════════════════════════════════════════════════════════════════
-- 1) TABLE/VIEW COMPATIBILITY LAYER
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW public.kult_groups AS
SELECT * FROM public.vespara_groups;

CREATE OR REPLACE VIEW public.kult_events AS
SELECT * FROM public.vespara_events;

CREATE OR REPLACE VIEW public.kult_event_rsvps AS
SELECT * FROM public.vespara_event_rsvps;

-- Conservative grants for alias views (expand after RLS validation).
GRANT SELECT ON public.kult_groups TO service_role;
GRANT SELECT ON public.kult_events TO service_role;
GRANT SELECT ON public.kult_event_rsvps TO service_role;

-- ═══════════════════════════════════════════════════════════════════════════
-- 2) RPC COMPATIBILITY WRAPPERS (GROUP OPERATIONS)
-- ═══════════════════════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS public.create_kult_group(TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION public.create_kult_group(
  p_name TEXT,
  p_description TEXT DEFAULT NULL,
  p_avatar_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.create_vespara_group(p_name, p_description, p_avatar_url);
END;
$$;

DROP FUNCTION IF EXISTS public.leave_kult_group(UUID);
CREATE OR REPLACE FUNCTION public.leave_kult_group(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.leave_vespara_group(p_group_id);
END;
$$;

DROP FUNCTION IF EXISTS public.delete_kult_group(UUID);
CREATE OR REPLACE FUNCTION public.delete_kult_group(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.delete_vespara_group(p_group_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_kult_group(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leave_kult_group(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_kult_group(UUID) TO authenticated;
