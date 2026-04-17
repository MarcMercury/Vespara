-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║      MIGRATION 079: TRAVEL CROSSPATH NOTIFICATIONS                       ║
-- ║                                                                           ║
-- ║   When a travel plan is created or updated, automatically detect          ║
-- ║   overlapping trips with connections and notify both users about          ║
-- ║   the crosspath — WHO they'll cross paths with, WHEN, and WHERE.         ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════════════════
-- 1. CROSSPATH NOTIFICATION TABLE
--    Tracks which crosspath notifications have already been sent so we
--    don't spam users when trips are updated.
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS travel_crosspath_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_a_id UUID NOT NULL REFERENCES travel_plans(id) ON DELETE CASCADE,
    plan_b_id UUID NOT NULL REFERENCES travel_plans(id) ON DELETE CASCADE,
    user_a_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    overlap_start DATE NOT NULL,
    overlap_end DATE NOT NULL,
    destination_a TEXT NOT NULL,
    destination_b TEXT NOT NULL,
    is_same_city BOOLEAN DEFAULT false,
    distance_km DOUBLE PRECISION,
    notified_at TIMESTAMPTZ DEFAULT now(),
    
    -- Prevent duplicate notifications for the same pair of plans
    UNIQUE(plan_a_id, plan_b_id)
);

CREATE INDEX IF NOT EXISTS idx_crosspath_user_a ON travel_crosspath_notifications(user_a_id);
CREATE INDEX IF NOT EXISTS idx_crosspath_user_b ON travel_crosspath_notifications(user_b_id);
CREATE INDEX IF NOT EXISTS idx_crosspath_plans ON travel_crosspath_notifications(plan_a_id, plan_b_id);

ALTER TABLE travel_crosspath_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own crosspath notifications" ON travel_crosspath_notifications
    FOR SELECT USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);


-- ════════════════════════════════════════════════════════════════════════════
-- 2. CROSSPATH DETECTION FUNCTION
--    Called by the trigger after INSERT/UPDATE on travel_plans.
--    Finds all overlapping trips from connections and creates notifications.
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION notify_travel_crosspaths()
RETURNS TRIGGER AS $$
DECLARE
    overlap RECORD;
    my_name TEXT;
    their_name TEXT;
    overlap_days INT;
    location_text TEXT;
    distance DOUBLE PRECISION;
    same_city BOOLEAN;
BEGIN
    -- Skip if trip is cancelled or private
    IF NEW.is_cancelled THEN RETURN NEW; END IF;
    IF NEW.visibility = 'private' THEN RETURN NEW; END IF;

    -- Get the plan owner's name
    SELECT COALESCE(display_name, 'Someone') INTO my_name
    FROM public.profiles WHERE id = NEW.user_id;

    -- Find all overlapping trips from connections
    FOR overlap IN
        SELECT
            tp.id AS other_plan_id,
            tp.user_id AS other_user_id,
            tp.destination_city AS other_city,
            tp.destination_lat AS other_lat,
            tp.destination_lng AS other_lng,
            tp.start_date AS other_start,
            tp.end_date AS other_end,
            GREATEST(NEW.start_date, tp.start_date) AS ov_start,
            LEAST(NEW.end_date, tp.end_date) AS ov_end,
            LOWER(NEW.destination_city) = LOWER(tp.destination_city) AS is_same_city
        FROM travel_plans tp
        WHERE tp.user_id != NEW.user_id
          AND NOT tp.is_cancelled
          AND tp.visibility != 'private'
          -- Date overlap check
          AND tp.start_date <= NEW.end_date
          AND tp.end_date >= NEW.start_date
          -- Must be a connection
          AND EXISTS (
              SELECT 1 FROM roster_matches rm
              WHERE rm.pipeline = 'active'
              AND rm.is_archived = false
              AND ((rm.user_id = NEW.user_id AND rm.match_user_id = tp.user_id)
                OR (rm.match_user_id = NEW.user_id AND rm.user_id = tp.user_id))
          )
          -- Check user has travel overlap notifications enabled
          AND NOT EXISTS (
              SELECT 1 FROM user_settings us
              WHERE us.user_id = tp.user_id
              AND us.notify_travel_overlaps = false
          )
    LOOP
        -- Skip if we already sent a notification for this exact plan pair
        IF EXISTS (
            SELECT 1 FROM travel_crosspath_notifications
            WHERE (plan_a_id = NEW.id AND plan_b_id = overlap.other_plan_id)
               OR (plan_a_id = overlap.other_plan_id AND plan_b_id = NEW.id)
        ) THEN
            CONTINUE;
        END IF;

        -- Get other user's name
        SELECT COALESCE(display_name, 'Someone') INTO their_name
        FROM public.profiles WHERE id = overlap.other_user_id;

        -- Calculate overlap days
        overlap_days := (overlap.ov_end - overlap.ov_start) + 1;

        -- Calculate distance if coordinates available
        distance := NULL;
        same_city := overlap.is_same_city;
        IF NEW.destination_lat IS NOT NULL AND overlap.other_lat IS NOT NULL THEN
            distance := 6371 * acos(
                LEAST(1.0,
                    cos(radians(NEW.destination_lat)) * cos(radians(overlap.other_lat))
                    * cos(radians(overlap.other_lng) - radians(NEW.destination_lng))
                    + sin(radians(NEW.destination_lat)) * sin(radians(overlap.other_lat))
                )
            );
        END IF;

        -- Build location description
        IF same_city THEN
            location_text := NEW.destination_city;
        ELSE
            location_text := NEW.destination_city || ' & ' || overlap.other_city;
        END IF;

        -- Record the crosspath to prevent duplicates
        INSERT INTO travel_crosspath_notifications (
            plan_a_id, plan_b_id,
            user_a_id, user_b_id,
            overlap_start, overlap_end,
            destination_a, destination_b,
            is_same_city, distance_km
        ) VALUES (
            NEW.id, overlap.other_plan_id,
            NEW.user_id, overlap.other_user_id,
            overlap.ov_start, overlap.ov_end,
            NEW.destination_city, overlap.other_city,
            same_city, distance
        );

        -- ── Notify the trip creator (user A) ──
        INSERT INTO public.notifications (user_id, type, title, message, data, action_url)
        VALUES (
            NEW.user_id,
            'travel',
            'Crossing Paths with ' || their_name || '!',
            CASE
                WHEN same_city THEN
                    'You''ll both be in ' || NEW.destination_city
                    || ' from ' || TO_CHAR(overlap.ov_start, 'Mon DD')
                    || ' to ' || TO_CHAR(overlap.ov_end, 'Mon DD')
                    || ' (' || overlap_days || ' day' || CASE WHEN overlap_days > 1 THEN 's' ELSE '' END || ' overlap)'
                ELSE
                    their_name || ' will be in ' || overlap.other_city
                    || ' while you''re in ' || NEW.destination_city
                    || ' — ' || TO_CHAR(overlap.ov_start, 'Mon DD')
                    || ' to ' || TO_CHAR(overlap.ov_end, 'Mon DD')
                    || CASE WHEN distance IS NOT NULL THEN
                        ' (' || ROUND(distance::numeric) || ' km apart)'
                    ELSE '' END
            END,
            jsonb_build_object(
                'crosspath_type', CASE WHEN same_city THEN 'same_city' ELSE 'nearby' END,
                'overlap_start', overlap.ov_start,
                'overlap_end', overlap.ov_end,
                'overlap_days', overlap_days,
                'other_user_id', overlap.other_user_id,
                'other_user_name', their_name,
                'my_plan_id', NEW.id,
                'other_plan_id', overlap.other_plan_id,
                'my_destination', NEW.destination_city,
                'other_destination', overlap.other_city,
                'is_same_city', same_city,
                'distance_km', distance
            ),
            '/travel'
        );

        -- ── Notify the other user (user B) ──
        INSERT INTO public.notifications (user_id, type, title, message, data, action_url)
        VALUES (
            overlap.other_user_id,
            'travel',
            'Crossing Paths with ' || my_name || '!',
            CASE
                WHEN same_city THEN
                    my_name || ' will also be in ' || overlap.other_city
                    || ' from ' || TO_CHAR(overlap.ov_start, 'Mon DD')
                    || ' to ' || TO_CHAR(overlap.ov_end, 'Mon DD')
                    || ' (' || overlap_days || ' day' || CASE WHEN overlap_days > 1 THEN 's' ELSE '' END || ' overlap)'
                ELSE
                    my_name || ' will be in ' || NEW.destination_city
                    || ' while you''re in ' || overlap.other_city
                    || ' — ' || TO_CHAR(overlap.ov_start, 'Mon DD')
                    || ' to ' || TO_CHAR(overlap.ov_end, 'Mon DD')
                    || CASE WHEN distance IS NOT NULL THEN
                        ' (' || ROUND(distance::numeric) || ' km apart)'
                    ELSE '' END
            END,
            jsonb_build_object(
                'crosspath_type', CASE WHEN same_city THEN 'same_city' ELSE 'nearby' END,
                'overlap_start', overlap.ov_start,
                'overlap_end', overlap.ov_end,
                'overlap_days', overlap_days,
                'other_user_id', NEW.user_id,
                'other_user_name', my_name,
                'my_plan_id', overlap.other_plan_id,
                'other_plan_id', NEW.id,
                'my_destination', overlap.other_city,
                'other_destination', NEW.destination_city,
                'is_same_city', same_city,
                'distance_km', distance
            ),
            '/travel'
        );

    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ════════════════════════════════════════════════════════════════════════════
-- 3. TRIGGERS — Fire on plan creation and meaningful updates
-- ════════════════════════════════════════════════════════════════════════════

-- On INSERT: check for crosspaths immediately
DROP TRIGGER IF EXISTS travel_crosspath_on_insert ON travel_plans;
CREATE TRIGGER travel_crosspath_on_insert
    AFTER INSERT ON travel_plans
    FOR EACH ROW
    EXECUTE FUNCTION notify_travel_crosspaths();

-- On UPDATE: re-check only when dates or destination change
DROP TRIGGER IF EXISTS travel_crosspath_on_update ON travel_plans;
CREATE TRIGGER travel_crosspath_on_update
    AFTER UPDATE ON travel_plans
    FOR EACH ROW
    WHEN (
        OLD.destination_city IS DISTINCT FROM NEW.destination_city
        OR OLD.start_date IS DISTINCT FROM NEW.start_date
        OR OLD.end_date IS DISTINCT FROM NEW.end_date
        OR OLD.is_cancelled IS DISTINCT FROM NEW.is_cancelled
        OR OLD.visibility IS DISTINCT FROM NEW.visibility
    )
    EXECUTE FUNCTION notify_travel_crosspaths();


-- ════════════════════════════════════════════════════════════════════════════
-- 4. CLEANUP: Remove crosspath records when trips are cancelled
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION cleanup_cancelled_crosspaths()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_cancelled = true AND (OLD.is_cancelled IS DISTINCT FROM NEW.is_cancelled) THEN
        DELETE FROM travel_crosspath_notifications
        WHERE plan_a_id = NEW.id OR plan_b_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS travel_crosspath_cleanup ON travel_plans;
CREATE TRIGGER travel_crosspath_cleanup
    AFTER UPDATE ON travel_plans
    FOR EACH ROW
    WHEN (NEW.is_cancelled = true AND OLD.is_cancelled IS DISTINCT FROM NEW.is_cancelled)
    EXECUTE FUNCTION cleanup_cancelled_crosspaths();
