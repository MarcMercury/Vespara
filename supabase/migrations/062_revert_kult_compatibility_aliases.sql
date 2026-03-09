-- Revert Kult compatibility aliases and wrappers
-- Keeps legacy Vespara objects as the canonical runtime interface.

DROP VIEW IF EXISTS public.kult_event_rsvps;
DROP VIEW IF EXISTS public.kult_events;
DROP VIEW IF EXISTS public.kult_groups;

DROP FUNCTION IF EXISTS public.create_kult_group(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.leave_kult_group(UUID);
DROP FUNCTION IF EXISTS public.delete_kult_group(UUID);
