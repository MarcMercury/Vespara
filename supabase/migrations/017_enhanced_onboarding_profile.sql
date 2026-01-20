-- ============================================
-- VESPARA ENHANCED ONBOARDING PROFILE
-- Migration 017: Exclusive Club Interview Experience
-- ============================================

-- ============================================
-- 1. AGE VERIFICATION (21+ for full access)
-- ============================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS age_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS age_verified_at TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS age_verification_method TEXT; -- 'birth_date', 'document', 'third_party'

-- Update is_adult function to require 21+
CREATE OR REPLACE FUNCTION is_adult_21(birth_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(NOW(), birth_date)) >= 21;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 2. RELATIONSHIP STATUS (Multi-Select)
-- ============================================

-- Primary relationship situation
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS relationship_status TEXT[]; 
-- Possible values:
-- 'single' - Flying solo
-- 'dating' - Casually dating (not exclusive)
-- 'partnered' - In a relationship (exclusive)
-- 'partnered_open' - In a relationship (open)
-- 'married' - Married (monogamous)
-- 'married_open' - Married (open/ENM)
-- 'divorced' - Divorced/Separated
-- 'widowed' - Widowed
-- 'poly_solo' - Solo polyamorous
-- 'poly_nested' - Nested polyamory (live-in partner)
-- 'poly_network' - Part of a polycule
-- 'situationship' - It's complicated
-- 'exploring' - Exploring/questioning
-- 'relationship_anarchist' - No labels

-- What they're here for
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS seeking TEXT[];
-- Possible values:
-- 'friends' - New friends
-- 'dates' - Casual dates
-- 'fwb' - Friends with benefits
-- 'ongoing' - Ongoing connection(s)
-- 'relationship' - Serious relationship
-- 'play_partners' - Play partners
-- 'third' - Looking for a third
-- 'couple' - Looking for couples
-- 'group' - Group experiences
-- 'events' - Social events/parties
-- 'networking' - Professional networking
-- 'exploring' - Just exploring

-- Partner involvement (for coupled/married folks)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS partner_involvement TEXT;
-- 'solo_only' - Partner not involved
-- 'sometimes' - Sometimes together
-- 'always_together' - Always together
-- 'parallel' - Parallel play
-- 'full_swap' - Full swap
-- 'soft_swap' - Soft swap only
-- 'watch' - Partner watches
-- 'na' - Not applicable

-- ============================================
-- 3. AVAILABILITY & LOGISTICS
-- ============================================

-- When are they available?
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS availability_general TEXT[];
-- 'weekday_days' - Weekday daytime
-- 'weekday_evenings' - Weekday evenings
-- 'weekday_nights' - Weekday late nights
-- 'weekend_days' - Weekend daytime
-- 'weekend_evenings' - Weekend evenings  
-- 'weekend_nights' - Weekend late nights
-- 'spontaneous' - Spontaneous (flex schedule)
-- 'planned_only' - Planned only (need advance notice)
-- 'travel_friendly' - Can travel/meet anywhere

-- How much notice do they need?
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS scheduling_style TEXT;
-- 'same_day' - Same day is fine
-- 'day_ahead' - Day ahead minimum
-- 'week_ahead' - Week ahead minimum
-- 'flexible' - Flexible either way

-- Hosting situation
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS hosting_status TEXT;
-- 'can_host' - Can host
-- 'sometimes_host' - Sometimes can host
-- 'cannot_host' - Cannot host
-- 'prefer_not' - Prefer not to host
-- 'hotel' - Hotel only
-- 'outdoors' - Adventurous locations

-- Privacy/Discretion level
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS discretion_level TEXT;
-- 'very_discreet' - Very discreet (no public acknowledgment)
-- 'discreet' - Discreet (keep it private)
-- 'casual' - Casual (don't advertise but not hiding)
-- 'open' - Open (everyone knows)

-- Travel radius (in miles)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS travel_radius INTEGER DEFAULT 25;

-- Party/Event availability
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS party_availability TEXT[];
-- 'house_parties' - Private house parties
-- 'club_events' - Club events
-- 'lifestyle_events' - Lifestyle events
-- 'hotel_takeovers' - Hotel takeovers
-- 'vacations' - Lifestyle vacations
-- 'dinner_parties' - Dinner parties
-- 'none' - Not interested in events

-- ============================================
-- 4. ENHANCED LOCATION
-- ============================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'USA';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS timezone TEXT;

-- ============================================
-- 5. GENDER & ORIENTATION (Inclusive)
-- ============================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS gender TEXT[];
-- 'man', 'woman', 'non_binary', 'trans_man', 'trans_woman', 
-- 'genderqueer', 'genderfluid', 'agender', 'two_spirit', 'other'

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pronouns TEXT;
-- 'he/him', 'she/her', 'they/them', 'he/they', 'she/they', 'any', 'ask'

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS orientation TEXT[];
-- 'straight', 'gay', 'lesbian', 'bisexual', 'pansexual', 'queer',
-- 'heteroflexible', 'homoflexible', 'asexual', 'demisexual', 'questioning'

-- ============================================
-- 6. ONBOARDING PROGRESS TRACKING
-- ============================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_step INTEGER DEFAULT 0;
-- 0: Not started
-- 1: Viewed intro animation
-- 2: Age verified
-- 3: Basic info complete
-- 4: Relationship status complete
-- 5: Availability complete
-- 6: Photos uploaded
-- 7: Traits selected
-- 8: Bio generated
-- 9: Complete

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_started_at TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;

-- ============================================
-- 7. HELPER FUNCTIONS FOR AI/MATCHING
-- ============================================

-- Calculate availability overlap between two users
CREATE OR REPLACE FUNCTION calculate_availability_overlap(
    user_a_id UUID,
    user_b_id UUID
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    user_a_avail TEXT[];
    user_b_avail TEXT[];
    overlap_count INTEGER := 0;
    total_slots INTEGER := 0;
BEGIN
    SELECT availability_general INTO user_a_avail FROM profiles WHERE id = user_a_id;
    SELECT availability_general INTO user_b_avail FROM profiles WHERE id = user_b_id;
    
    IF user_a_avail IS NULL OR user_b_avail IS NULL THEN
        RETURN 0.5; -- Default if not set
    END IF;
    
    -- Count overlapping availability slots
    SELECT COUNT(*) INTO overlap_count
    FROM unnest(user_a_avail) a
    JOIN unnest(user_b_avail) b ON a = b;
    
    total_slots := GREATEST(array_length(user_a_avail, 1), 1);
    
    RETURN LEAST(overlap_count::DOUBLE PRECISION / total_slots, 1.0);
END;
$$ LANGUAGE plpgsql;

-- Check if two users are logistically compatible
CREATE OR REPLACE FUNCTION are_logistically_compatible(
    user_a_id UUID,
    user_b_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    avail_overlap DOUBLE PRECISION;
    a_hosting TEXT;
    b_hosting TEXT;
BEGIN
    -- Check availability overlap
    avail_overlap := calculate_availability_overlap(user_a_id, user_b_id);
    IF avail_overlap < 0.2 THEN
        RETURN FALSE;
    END IF;
    
    -- Check hosting compatibility (at least one can host or both okay with alternatives)
    SELECT hosting_status INTO a_hosting FROM profiles WHERE id = user_a_id;
    SELECT hosting_status INTO b_hosting FROM profiles WHERE id = user_b_id;
    
    IF a_hosting = 'can_host' OR b_hosting = 'can_host' OR 
       a_hosting = 'sometimes_host' OR b_hosting = 'sometimes_host' OR
       a_hosting = 'hotel' OR b_hosting = 'hotel' THEN
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. INDEXES FOR EFFICIENT QUERIES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_profiles_age_verified 
    ON public.profiles(age_verified) 
    WHERE age_verified = TRUE;

CREATE INDEX IF NOT EXISTS idx_profiles_availability 
    ON public.profiles USING GIN(availability_general);

CREATE INDEX IF NOT EXISTS idx_profiles_relationship_status 
    ON public.profiles USING GIN(relationship_status);

CREATE INDEX IF NOT EXISTS idx_profiles_seeking 
    ON public.profiles USING GIN(seeking);

CREATE INDEX IF NOT EXISTS idx_profiles_location 
    ON public.profiles(city, state);

CREATE INDEX IF NOT EXISTS idx_profiles_onboarding 
    ON public.profiles(onboarding_complete, onboarding_step);

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION is_adult_21 TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_availability_overlap TO authenticated;
GRANT EXECUTE ON FUNCTION are_logistically_compatible TO authenticated;
