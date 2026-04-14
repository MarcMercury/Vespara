-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 067: Enhanced Photo Gallery + Notification Preferences
-- Adds: unlimited photos, view tracking, time-sensitive photos, AI edits,
--        push notification settings, and community engagement features
-- ═══════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────
-- 1. ENHANCED PROFILE PHOTOS — Support up to 30 photos per user
-- ───────────────────────────────────────────────────────────────────────────

-- Drop the position constraint so users can have more than 5 photos
ALTER TABLE profile_photos 
  DROP CONSTRAINT IF EXISTS profile_photos_position_check;

-- Allow up to 30 positions  
ALTER TABLE profile_photos 
  ADD CONSTRAINT profile_photos_position_check 
  CHECK (position >= 1 AND position <= 30);

-- Add new columns for enhanced photo features
ALTER TABLE profile_photos
  ADD COLUMN IF NOT EXISTS caption text,
  ADD COLUMN IF NOT EXISTS is_private boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_time_sensitive boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS view_limit integer,
  ADD COLUMN IF NOT EXISTS view_count integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS ai_enhanced boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS ai_edit_type text,
  ADD COLUMN IF NOT EXISTS original_url text,
  ADD COLUMN IF NOT EXISTS cloudinary_public_id text,
  ADD COLUMN IF NOT EXISTS width integer,
  ADD COLUMN IF NOT EXISTS height integer,
  ADD COLUMN IF NOT EXISTS file_size_bytes bigint,
  ADD COLUMN IF NOT EXISTS blur_hash text,
  ADD COLUMN IF NOT EXISTS tags text[] DEFAULT '{}';

-- Index for time-sensitive photo expiry checks
CREATE INDEX IF NOT EXISTS idx_profile_photos_expires_at 
  ON profile_photos (expires_at) 
  WHERE expires_at IS NOT NULL AND is_time_sensitive = true;

-- Index for private photos
CREATE INDEX IF NOT EXISTS idx_profile_photos_private 
  ON profile_photos (user_id, is_private) 
  WHERE is_private = true;

-- ───────────────────────────────────────────────────────────────────────────
-- 2. PHOTO VIEW TRACKING — Track who viewed which photo and when
-- ───────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS photo_views (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_id uuid NOT NULL REFERENCES profile_photos(id) ON DELETE CASCADE,
  viewer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  viewed_at timestamptz DEFAULT now(),
  view_duration_seconds integer
);

-- One view per user per photo per day (immutable date extraction)
CREATE OR REPLACE FUNCTION public.utc_date(ts timestamptz)
RETURNS date
LANGUAGE sql
IMMUTABLE
AS $$ SELECT (ts AT TIME ZONE 'UTC')::date; $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_photo_views_unique_daily
  ON photo_views (photo_id, viewer_id, public.utc_date(viewed_at));

CREATE INDEX IF NOT EXISTS idx_photo_views_photo ON photo_views(photo_id);
CREATE INDEX IF NOT EXISTS idx_photo_views_viewer ON photo_views(viewer_id);

-- RLS for photo_views
ALTER TABLE photo_views ENABLE ROW LEVEL SECURITY;

-- Users can insert their own view records
CREATE POLICY "Users can log photo views" ON photo_views
  FOR INSERT WITH CHECK (auth.uid() = viewer_id);

-- Photo owners can see who viewed their photos  
CREATE POLICY "Photo owners can see views" ON photo_views
  FOR SELECT USING (
    photo_id IN (
      SELECT id FROM profile_photos WHERE user_id = auth.uid()
    ) OR viewer_id = auth.uid()
  );

-- ───────────────────────────────────────────────────────────────────────────
-- 3. AI PHOTO EDITS — Track AI transformations applied to photos
-- ───────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS photo_ai_edits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_id uuid NOT NULL REFERENCES profile_photos(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  edit_type text NOT NULL, -- 'enhance', 'retouch', 'background', 'artistic', 'crop_smart'
  edit_params jsonb DEFAULT '{}',
  original_url text NOT NULL,
  result_url text,
  status text DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

ALTER TABLE photo_ai_edits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own AI edits" ON photo_ai_edits
  FOR ALL USING (auth.uid() = user_id);

-- ───────────────────────────────────────────────────────────────────────────
-- 4. ENHANCED NOTIFICATION PREFERENCES
-- ───────────────────────────────────────────────────────────────────────────

ALTER TABLE user_settings
  ADD COLUMN IF NOT EXISTS notify_photo_views boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_photo_expiring boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_new_events boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_group_activity boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_game_invites boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_travel_overlaps boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS notify_community_updates boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS notify_weekly_digest boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS quiet_hours_start time,
  ADD COLUMN IF NOT EXISTS quiet_hours_end time,
  ADD COLUMN IF NOT EXISTS push_enabled boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS email_enabled boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS sms_enabled boolean DEFAULT false;

-- ───────────────────────────────────────────────────────────────────────────
-- 5. NOTIFICATION LOG — In-app notification history
-- ───────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL, -- 'message', 'photo_view', 'event', 'game_invite', 'travel', 'system'
  title text NOT NULL,
  body text,
  data jsonb DEFAULT '{}',
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  read_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id) WHERE is_read = false;

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- ───────────────────────────────────────────────────────────────────────────
-- 6. HELPER FUNCTIONS
-- ───────────────────────────────────────────────────────────────────────────

-- Function to increment photo view count and check limits
CREATE OR REPLACE FUNCTION record_photo_view(
  p_photo_id uuid,
  p_viewer_id uuid
) RETURNS boolean AS $$
DECLARE
  v_photo profile_photos%ROWTYPE;
BEGIN
  SELECT * INTO v_photo FROM profile_photos WHERE id = p_photo_id;
  
  IF NOT FOUND THEN RETURN false; END IF;
  
  -- Check if photo is expired
  IF v_photo.is_time_sensitive AND v_photo.expires_at IS NOT NULL 
     AND v_photo.expires_at < now() THEN
    RETURN false;
  END IF;
  
  -- Check view limit
  IF v_photo.view_limit IS NOT NULL AND v_photo.view_count >= v_photo.view_limit THEN
    RETURN false;
  END IF;
  
  -- Don't count owner viewing their own photo
  IF v_photo.user_id = p_viewer_id THEN RETURN true; END IF;
  
  -- Record the view
  INSERT INTO photo_views (photo_id, viewer_id)
  VALUES (p_photo_id, p_viewer_id)
  ON CONFLICT (photo_id, viewer_id, (viewed_at::date)) DO NOTHING;
  
  -- Increment view count
  UPDATE profile_photos SET view_count = view_count + 1 WHERE id = p_photo_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up expired time-sensitive photos
CREATE OR REPLACE FUNCTION cleanup_expired_photos() RETURNS void AS $$
BEGIN
  -- Mark expired photos as private (soft delete)
  UPDATE profile_photos 
  SET is_private = true 
  WHERE is_time_sensitive = true 
    AND expires_at IS NOT NULL 
    AND expires_at < now()
    AND is_private = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ───────────────────────────────────────────────────────────────────────────
-- 7. UPDATE PROFILE_PHOTOS RLS for enhanced access
-- ───────────────────────────────────────────────────────────────────────────

-- Allow viewing non-private, non-expired photos
DROP POLICY IF EXISTS "Anyone can view photos" ON profile_photos;
CREATE POLICY "View accessible photos" ON profile_photos
  FOR SELECT USING (
    user_id = auth.uid() 
    OR (
      is_private = false 
      AND (
        is_time_sensitive = false 
        OR expires_at IS NULL 
        OR expires_at > now()
      )
      AND (
        view_limit IS NULL 
        OR view_count < view_limit
      )
    )
  );
