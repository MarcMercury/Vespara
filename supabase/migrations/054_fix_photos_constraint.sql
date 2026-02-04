-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 054: FIX PHOTOS CONSTRAINT
-- Allow up to 6 photos instead of 3 to match onboarding UI
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop the old constraint that only allows 3 photos
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_photos_check;

-- Add new constraint allowing up to 6 photos
ALTER TABLE profiles ADD CONSTRAINT profiles_photos_check 
  CHECK (array_length(photos, 1) <= 6 OR photos = '{}' OR photos IS NULL);

COMMENT ON CONSTRAINT profiles_photos_check ON profiles IS 'Limit profile photos to maximum of 6';
