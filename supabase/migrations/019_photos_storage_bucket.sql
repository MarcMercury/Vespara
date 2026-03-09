-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                   VESPARA PHOTOS STORAGE CONFIGURATION                     ║
-- ║                    Photos Storage Bucket & Policies                        ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════════════
-- PHOTOS STORAGE BUCKET
-- ═══════════════════════════════════════════════════════════════════════════

-- Create the photos bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'photos',
  'photos',
  true,  -- Public bucket for photo URLs
  10485760,  -- 10MB max file size
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- ═══════════════════════════════════════════════════════════════════════════
-- STORAGE POLICIES FOR PHOTOS BUCKET
-- ═══════════════════════════════════════════════════════════════════════════

-- Policy: Users can upload their own photos
-- Path pattern: {user_id}/{filename}
DROP POLICY IF EXISTS "Users can upload their own photos" ON storage.objects;
CREATE POLICY "Users can upload their own photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can update their own photos
DROP POLICY IF EXISTS "Users can update their own photos" ON storage.objects;
CREATE POLICY "Users can update their own photos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete their own photos
DROP POLICY IF EXISTS "Users can delete their own photos" ON storage.objects;
CREATE POLICY "Users can delete their own photos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Anyone can view photos (public bucket)
DROP POLICY IF EXISTS "Photos are publicly accessible" ON storage.objects;
CREATE POLICY "Photos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'photos');
