-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 051: Fix Photo Rankings Unique Constraint
-- Ensures the unique constraint on (ranker_id, ranked_user_id) exists
-- This is needed for upsert operations with on_conflict
-- ═══════════════════════════════════════════════════════════════════════════

-- First, ensure the table exists (in case migration 040 wasn't run)
CREATE TABLE IF NOT EXISTS photo_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ranker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  ranked_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  ranked_photo_ids UUID[] NOT NULL,
  photo_versions JSONB NOT NULL DEFAULT '{}',
  is_valid BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add the unique constraint if it doesn't exist
-- Use DO block to check if constraint exists first
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'photo_rankings_ranker_id_ranked_user_id_key'
    AND conrelid = 'photo_rankings'::regclass
  ) THEN
    ALTER TABLE photo_rankings 
    ADD CONSTRAINT photo_rankings_ranker_id_ranked_user_id_key 
    UNIQUE (ranker_id, ranked_user_id);
  END IF;
END $$;

-- Enable RLS if not already enabled
ALTER TABLE photo_rankings ENABLE ROW LEVEL SECURITY;

-- Drop and recreate policies to ensure they exist
DROP POLICY IF EXISTS "View own rankings given" ON photo_rankings;
CREATE POLICY "View own rankings given" ON photo_rankings 
  FOR SELECT USING (auth.uid() = ranker_id);

DROP POLICY IF EXISTS "Submit rankings for others" ON photo_rankings;
CREATE POLICY "Submit rankings for others" ON photo_rankings 
  FOR INSERT WITH CHECK (auth.uid() = ranker_id AND auth.uid() != ranked_user_id);

DROP POLICY IF EXISTS "Update own rankings" ON photo_rankings;
CREATE POLICY "Update own rankings" ON photo_rankings 
  FOR UPDATE USING (auth.uid() = ranker_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_rankings_ranked_user ON photo_rankings(ranked_user_id) WHERE is_valid = TRUE;
CREATE INDEX IF NOT EXISTS idx_rankings_ranker ON photo_rankings(ranker_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- Also fix the group_members table (500 error)
-- ═══════════════════════════════════════════════════════════════════════════

-- Ensure group_members has proper RLS policies
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Allow users to view groups they're a member of
DROP POLICY IF EXISTS "View own group memberships" ON group_members;
CREATE POLICY "View own group memberships" ON group_members
  FOR SELECT USING (auth.uid() = user_id);

-- Allow users to join groups (if the group allows it)
DROP POLICY IF EXISTS "Join groups" ON group_members;
CREATE POLICY "Join groups" ON group_members
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to leave groups
DROP POLICY IF EXISTS "Leave groups" ON group_members;
CREATE POLICY "Leave groups" ON group_members
  FOR DELETE USING (auth.uid() = user_id);

-- Allow users to update their membership (e.g., notification settings)
DROP POLICY IF EXISTS "Update own membership" ON group_members;
CREATE POLICY "Update own membership" ON group_members
  FOR UPDATE USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON photo_rankings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON group_members TO authenticated;
