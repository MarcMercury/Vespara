-- ============================================
-- MIGRATION 048: Fix Discovery RLS Policies
-- ============================================
-- Problem: Users can only see their own profile due to RLS
-- Solution: Allow viewing discoverable profiles for discovery feature
-- ============================================

-- Add policy to allow users to view OTHER discoverable profiles
-- This enables the discovery/matching feature to work
CREATE POLICY "Users can view discoverable profiles" ON public.profiles
    FOR SELECT 
    USING (
        -- Users can always see their own profile
        auth.uid() = id 
        OR 
        -- Users can see OTHER profiles that are discoverable and have completed onboarding
        (is_discoverable = TRUE AND onboarding_complete = TRUE)
    );

-- Drop the old restrictive policy (it's now covered by the new one)
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;

-- Add helpful comment
COMMENT ON POLICY "Users can view discoverable profiles" ON public.profiles 
    IS 'Allows users to see their own profile OR any discoverable profile that has completed onboarding';
