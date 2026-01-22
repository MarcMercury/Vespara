-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 031: FIX BANDWIDTH COLUMN TYPE
-- Fix conflict between migration 006 (INTEGER) and 030 (DECIMAL)
-- The bandwidth field should be a 0-1 float for energy/availability
-- ═══════════════════════════════════════════════════════════════════════════

-- First drop any constraints that might reference bandwidth
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS bandwidth_range_check;

-- Convert bandwidth from INTEGER to DECIMAL
-- If it was INTEGER (0-100), convert to 0-1 scale
-- If it was already DECIMAL, this will just ensure correct type
DO $$
BEGIN
    -- Check if bandwidth is INTEGER type
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'bandwidth' 
        AND data_type = 'integer'
    ) THEN
        -- Convert INTEGER bandwidth (0-100) to DECIMAL (0-1)
        ALTER TABLE profiles 
        ALTER COLUMN bandwidth TYPE DECIMAL(3,2) 
        USING (CASE 
            WHEN bandwidth IS NULL THEN 0.5
            WHEN bandwidth > 1 THEN bandwidth::DECIMAL / 100.0
            ELSE bandwidth::DECIMAL
        END);
        
        -- Set the default
        ALTER TABLE profiles ALTER COLUMN bandwidth SET DEFAULT 0.5;
        
        RAISE NOTICE 'Converted bandwidth from INTEGER to DECIMAL';
    ELSE
        RAISE NOTICE 'Bandwidth is already DECIMAL type';
    END IF;
END $$;

-- Re-add the constraint for bandwidth range
ALTER TABLE profiles ADD CONSTRAINT bandwidth_range_check 
  CHECK (bandwidth >= 0 AND bandwidth <= 1);

-- Update any null values to default
UPDATE profiles SET bandwidth = 0.5 WHERE bandwidth IS NULL;

COMMENT ON COLUMN profiles.bandwidth IS 'Current availability/energy level 0-1';
