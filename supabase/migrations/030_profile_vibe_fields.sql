-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 030: PROFILE VIBE FIELDS
-- The Interview enhancement - heat level, hard limits, bandwidth, hook
-- ═══════════════════════════════════════════════════════════════════════════

-- Add hook field (140 character teaser like Twitter)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS hook TEXT;

-- Add heat level (mild, medium, hot, nuclear)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS heat_level TEXT DEFAULT 'medium';

-- Add hard limits (array of limit IDs)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS hard_limits TEXT[] DEFAULT '{}';

-- Add bandwidth (0-1 float, how much energy/availability for dating)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bandwidth DECIMAL(3,2) DEFAULT 0.5;

-- Add constraint for hook length
ALTER TABLE profiles ADD CONSTRAINT hook_length_check CHECK (char_length(hook) <= 140);

-- Add constraint for heat level values
ALTER TABLE profiles ADD CONSTRAINT heat_level_values_check 
  CHECK (heat_level IN ('mild', 'medium', 'hot', 'nuclear') OR heat_level IS NULL);

-- Add constraint for bandwidth range
ALTER TABLE profiles ADD CONSTRAINT bandwidth_range_check 
  CHECK (bandwidth >= 0 AND bandwidth <= 1);

-- Create index for heat level for matching
CREATE INDEX IF NOT EXISTS idx_profiles_heat_level ON profiles(heat_level);

-- Create index for bandwidth for "tonight mode" and active user matching
CREATE INDEX IF NOT EXISTS idx_profiles_bandwidth ON profiles(bandwidth);

-- Comment on new columns
COMMENT ON COLUMN profiles.hook IS '140-character profile teaser/tagline';
COMMENT ON COLUMN profiles.heat_level IS 'Intensity preference: mild, medium, hot, nuclear';
COMMENT ON COLUMN profiles.hard_limits IS 'Array of non-negotiable boundaries';
COMMENT ON COLUMN profiles.bandwidth IS 'Current availability/energy level 0-1';
