-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 070: Fix Profiles RLS Infinite Recursion
-- 
-- Resolves PostgreSQL error 42P17: infinite recursion detected in policy
-- for relation "profiles"
--
-- Root cause: Migrations 064 and 066 created SELECT/UPDATE policies on
-- the profiles table that contain subqueries selecting FROM profiles.
-- When PostgreSQL evaluates RLS policies, the subquery triggers the same
-- policies again, creating infinite recursion.
--
-- Fix: Use SECURITY DEFINER helper functions that bypass RLS to check
-- membership_status and is_admin, then reference those in the policies.
-- ═══════════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════════════
-- 1. CREATE SECURITY DEFINER HELPER FUNCTIONS (bypass RLS for lookups)
-- ════════════════════════════════════════════════════════════════════════════

-- Drop existing functions first (parameter name mismatch prevents CREATE OR REPLACE)
DROP FUNCTION IF EXISTS public.is_approved_member(UUID);
DROP FUNCTION IF EXISTS public.is_admin_user(UUID);

-- Check if user is an approved member
CREATE FUNCTION public.is_approved_member(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id
    AND membership_status = 'approved'
  );
$$;

-- Check if user is an admin
CREATE FUNCTION public.is_admin_user(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id
    AND is_admin = TRUE
  );
$$;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. DROP RECURSIVE POLICIES
-- ════════════════════════════════════════════════════════════════════════════

-- From migration 064
DROP POLICY IF EXISTS "Members can view profiles" ON public.profiles;

-- From migration 053 (superseded)
DROP POLICY IF EXISTS "profiles_authenticated_select" ON public.profiles;

-- From migration 066
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;

-- From migration 048 (may still exist)
DROP POLICY IF EXISTS "Users can view discoverable profiles" ON public.profiles;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. RECREATE NON-RECURSIVE POLICIES
-- ════════════════════════════════════════════════════════════════════════════

-- SELECT: Users can always see their own profile. Approved members can see
-- other approved profiles. Admins can see all.
CREATE POLICY "profiles_select_policy" ON public.profiles
  FOR SELECT TO authenticated
  USING (
    auth.uid() = id
    OR public.is_admin_user(auth.uid())
    OR (
      public.is_approved_member(auth.uid())
      AND membership_status = 'approved'
    )
  );

-- UPDATE: Owner can update their own profile. Admins can update any profile.
-- (Re-drop and recreate to consolidate with admin update)
DROP POLICY IF EXISTS "profiles_owner_update" ON public.profiles;
CREATE POLICY "profiles_owner_update" ON public.profiles
  FOR UPDATE TO authenticated
  USING (
    id = auth.uid()
    OR public.is_admin_user(auth.uid())
  )
  WITH CHECK (
    id = auth.uid()
    OR public.is_admin_user(auth.uid())
  );
