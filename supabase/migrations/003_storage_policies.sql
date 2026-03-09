-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                      VESPARA STORAGE CONFIGURATION                        ║
-- ║                     Avatar Storage Bucket & Policies                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════════════
-- AVATARS STORAGE BUCKET
-- ═══════════════════════════════════════════════════════════════════════════

-- Create the avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,  -- Public bucket for avatar URLs
  5242880,  -- 5MB max file size
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- ═══════════════════════════════════════════════════════════════════════════
-- STORAGE POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

-- Policy: Users can upload their own avatars
-- Path pattern: {user_id}/{filename}
CREATE POLICY "Users can upload their own avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can update their own avatars
CREATE POLICY "Users can update their own avatars"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete their own avatars
CREATE POLICY "Users can delete their own avatars"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Anyone can view avatars (public bucket)
CREATE POLICY "Avatars are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- ═══════════════════════════════════════════════════════════════════════════
-- PROFILE PHOTO UPDATE TRIGGER
-- ═══════════════════════════════════════════════════════════════════════════

-- Function: Automatically set avatar_url from first photo in photos array
CREATE OR REPLACE FUNCTION public.sync_avatar_from_photos()
RETURNS TRIGGER AS $$
BEGIN
  -- If photos array has items and avatar_url is not set, use first photo
  IF NEW.photos IS NOT NULL AND array_length(NEW.photos, 1) > 0 THEN
    IF NEW.avatar_url IS NULL OR NEW.avatar_url = '' THEN
      NEW.avatar_url := NEW.photos[1];
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Run on profile insert/update
DROP TRIGGER IF EXISTS sync_avatar_trigger ON public.profiles;
CREATE TRIGGER sync_avatar_trigger
  BEFORE INSERT OR UPDATE OF photos ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION sync_avatar_from_photos();

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER: Get public URL for avatar
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.get_avatar_url(user_id UUID)
RETURNS TEXT AS $$
DECLARE
  avatar TEXT;
BEGIN
  SELECT avatar_url INTO avatar
  FROM public.profiles
  WHERE id = user_id;
  
  RETURN avatar;
END;
$$ LANGUAGE plpgsql STABLE;
