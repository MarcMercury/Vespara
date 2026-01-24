-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                   FIX PROFILE PHOTOS STORAGE BUCKET                        ║
-- ║                Ensure bucket exists with proper policies                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════════════
-- ENSURE PROFILE-PHOTOS BUCKET EXISTS
-- ═══════════════════════════════════════════════════════════════════════════

-- Create or update the profile-photos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-photos', 
  'profile-photos', 
  true,  -- Public bucket for photo URLs
  10485760,  -- 10MB max file size
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/jpg']
) ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/jpg'];

-- ═══════════════════════════════════════════════════════════════════════════
-- STORAGE POLICIES FOR PROFILE-PHOTOS BUCKET
-- Drop and recreate all policies to ensure clean state
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users upload own photos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone views photos" ON storage.objects;
DROP POLICY IF EXISTS "Users delete own photos" ON storage.objects;
DROP POLICY IF EXISTS "Users update own photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view all profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own profile photos" ON storage.objects;

-- Policy: Users can upload their own profile photos
-- Path pattern: {user_id}/{filename}
CREATE POLICY "Users can upload profile photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Anyone can view profile photos (public bucket)
CREATE POLICY "Users can view all profile photos" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-photos');

-- Policy: Users can delete their own profile photos
CREATE POLICY "Users can delete own profile photos" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can update their own profile photos
CREATE POLICY "Users can update own profile photos" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ═══════════════════════════════════════════════════════════════════════════
-- ENSURE profile_photos TABLE EXISTS WITH PROPER RLS
-- ═══════════════════════════════════════════════════════════════════════════

-- Create table if not exists (migration 040 should have created it)
CREATE TABLE IF NOT EXISTS profile_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  photo_url TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  position INTEGER NOT NULL CHECK (position >= 1 AND position <= 5),
  is_primary BOOLEAN DEFAULT false,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, position)
);

-- Enable RLS
ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;

-- Drop and recreate policies for clean state
DROP POLICY IF EXISTS "View all photos" ON profile_photos;
DROP POLICY IF EXISTS "Insert own photos" ON profile_photos;
DROP POLICY IF EXISTS "Update own photos" ON profile_photos;
DROP POLICY IF EXISTS "Delete own photos" ON profile_photos;

CREATE POLICY "View all photos" ON profile_photos 
FOR SELECT USING (true);

CREATE POLICY "Insert own photos" ON profile_photos 
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Update own photos" ON profile_photos 
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Delete own photos" ON profile_photos 
FOR DELETE USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- Create index for faster lookups
-- ═══════════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_profile_photos_user_id ON profile_photos(user_id);
CREATE INDEX IF NOT EXISTS idx_profile_photos_position ON profile_photos(user_id, position);
