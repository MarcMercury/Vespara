-- ============================================
-- MIGRATION 049: Complete Swipes and Matches RLS
-- ============================================
-- Ensures all necessary RLS policies exist for the matching system
-- ============================================

-- Allow users to read swipes where they are the swiper
-- (Already exists but adding IF NOT EXISTS for safety)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'swipes' 
        AND policyname = 'Users can manage own swipes'
    ) THEN
        CREATE POLICY "Users can manage own swipes" ON public.swipes
            FOR ALL USING (auth.uid() = swiper_id);
    END IF;
END $$;

-- Allow users to check if someone swiped on them (for match checking)
-- This is read-only - users can see if they were swiped on but can't modify
DROP POLICY IF EXISTS "Users can see swipes on them" ON public.swipes;
CREATE POLICY "Users can see swipes on them" ON public.swipes
    FOR SELECT USING (auth.uid() = swiped_id);

-- Ensure matches table allows INSERT from the trigger
-- The trigger runs as SECURITY DEFINER so this should work, but let's be safe
DROP POLICY IF EXISTS "System can create matches" ON public.matches;
CREATE POLICY "System can create matches" ON public.matches
    FOR INSERT WITH CHECK (true);

-- Add helpful comments
COMMENT ON POLICY "Users can manage own swipes" ON public.swipes 
    IS 'Users can create, read, update, delete their own swipes';
COMMENT ON POLICY "Users can see swipes on them" ON public.swipes 
    IS 'Users can see when others have swiped on them (read-only)';
