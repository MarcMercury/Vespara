-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                     KULT PHASE 6: SCALABILITY LAYER                        ║
-- ║        Production-Ready Infrastructure for 1,000,000+ Users                ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
--
-- This migration addresses the following scalability concerns:
-- 1. Connection Pooling (Supavisor configuration)
-- 2. HNSW Indexing for vector search (O(N) → O(log N))
-- 3. Geohash sharding for Tonight Mode realtime
-- 4. Messages table partitioning for 500M+ rows
-- 5. Pre-calculated daily matches for async feed generation
-- 6. Background job infrastructure

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 1: ENABLE REQUIRED EXTENSIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- pgvector for AI embeddings (if not already enabled)
CREATE EXTENSION IF NOT EXISTS vector;

-- pg_cron for background jobs (requires Supabase Pro plan)
-- Note: This is enabled via Supabase Dashboard, not SQL
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 2: VECTOR EMBEDDINGS & HNSW INDEX
-- For "The Scope" AI-powered matching at scale
-- ═══════════════════════════════════════════════════════════════════════════

-- Add embedding column to profiles for AI matching
-- Using 1536 dimensions (OpenAI text-embedding-ada-002)
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS embedding vector(1536),
    ADD COLUMN IF NOT EXISTS embedding_updated_at TIMESTAMPTZ;

-- HNSW Index: Changes vector search from O(N) to O(log N)
-- Critical for 1M users - brute force search would take seconds
-- m = 16 (connections per layer), ef_construction = 64 (build quality)
CREATE INDEX IF NOT EXISTS idx_profiles_embedding_hnsw 
    ON public.profiles 
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Index for finding profiles that need embedding updates
CREATE INDEX IF NOT EXISTS idx_profiles_embedding_stale 
    ON public.profiles (embedding_updated_at)
    WHERE embedding IS NULL OR embedding_updated_at < updated_at;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 3: GEOHASH SHARDING FOR TONIGHT MODE
-- Prevents DDoS-on-self from global realtime subscriptions
-- ═══════════════════════════════════════════════════════════════════════════

-- Add geohash columns for geographic sharding
-- Precision levels: 4 = ~39km, 5 = ~5km, 6 = ~1.2km
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS geohash_4 TEXT, -- City level (~39km cells)
    ADD COLUMN IF NOT EXISTS geohash_5 TEXT, -- Neighborhood level (~5km cells)
    ADD COLUMN IF NOT EXISTS geohash_6 TEXT; -- Block level (~1.2km cells)

-- Indexes for geohash-based queries
CREATE INDEX IF NOT EXISTS idx_profiles_geohash_4 ON public.profiles (geohash_4) WHERE current_status = 'tonight_mode';
CREATE INDEX IF NOT EXISTS idx_profiles_geohash_5 ON public.profiles (geohash_5) WHERE current_status = 'tonight_mode';
CREATE INDEX IF NOT EXISTS idx_profiles_geohash_6 ON public.profiles (geohash_6) WHERE current_status = 'tonight_mode';

-- Composite index for Tonight Mode queries
CREATE INDEX IF NOT EXISTS idx_profiles_tonight_mode_geo 
    ON public.profiles (geohash_5, current_status, last_active_at DESC)
    WHERE current_status = 'tonight_mode' AND is_visible = TRUE;

-- Function to calculate geohash from lat/lng
-- Uses base32 encoding for standard geohash format
CREATE OR REPLACE FUNCTION calculate_geohash(lat DOUBLE PRECISION, lng DOUBLE PRECISION, hash_precision INT DEFAULT 6)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    base32 TEXT := '0123456789bcdefghjkmnpqrstuvwxyz';
    lat_min DOUBLE PRECISION := -90.0;
    lat_max DOUBLE PRECISION := 90.0;
    lng_min DOUBLE PRECISION := -180.0;
    lng_max DOUBLE PRECISION := 180.0;
    mid DOUBLE PRECISION;
    bit INT := 0;
    ch INT := 0;
    geohash TEXT := '';
    is_lng BOOLEAN := TRUE;
BEGIN
    IF lat IS NULL OR lng IS NULL THEN
        RETURN NULL;
    END IF;
    
    WHILE length(geohash) < hash_precision LOOP
        IF is_lng THEN
            mid := (lng_min + lng_max) / 2;
            IF lng >= mid THEN
                ch := ch | (16 >> bit);
                lng_min := mid;
            ELSE
                lng_max := mid;
            END IF;
        ELSE
            mid := (lat_min + lat_max) / 2;
            IF lat >= mid THEN
                ch := ch | (16 >> bit);
                lat_min := mid;
            ELSE
                lat_max := mid;
            END IF;
        END IF;
        
        is_lng := NOT is_lng;
        bit := bit + 1;
        
        IF bit = 5 THEN
            geohash := geohash || substr(base32, ch + 1, 1);
            bit := 0;
            ch := 0;
        END IF;
    END LOOP;
    
    RETURN geohash;
END;
$$;

-- Trigger to auto-update geohashes when location changes
CREATE OR REPLACE FUNCTION update_profile_geohashes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    lat DOUBLE PRECISION;
    lng DOUBLE PRECISION;
BEGIN
    -- Extract lat/lng from geography point
    IF NEW.location IS NOT NULL THEN
        lat := ST_Y(NEW.location::geometry);
        lng := ST_X(NEW.location::geometry);
        
        NEW.geohash_4 := calculate_geohash(lat, lng, 4);
        NEW.geohash_5 := calculate_geohash(lat, lng, 5);
        NEW.geohash_6 := calculate_geohash(lat, lng, 6);
    ELSE
        NEW.geohash_4 := NULL;
        NEW.geohash_5 := NULL;
        NEW.geohash_6 := NULL;
    END IF;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_geohashes ON public.profiles;
CREATE TRIGGER trigger_update_geohashes
    BEFORE INSERT OR UPDATE OF location ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_geohashes();

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 4: PRE-CALCULATED DAILY MATCHES
-- Moves feed generation from realtime to async background jobs
-- ═══════════════════════════════════════════════════════════════════════════

-- Daily matches table - pre-calculated feed for each user
CREATE TABLE IF NOT EXISTS public.daily_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    similarity_score FLOAT NOT NULL,
    match_reasons JSONB DEFAULT '[]', -- Array of reasons: ["Similar interests", "Near you"]
    is_viewed BOOLEAN DEFAULT FALSE,
    is_liked BOOLEAN,
    calculated_at DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate matches per day
    CONSTRAINT unique_daily_match UNIQUE (user_id, match_user_id, calculated_at)
);

-- Indexes for fast feed retrieval
CREATE INDEX IF NOT EXISTS idx_daily_matches_user_date 
    ON public.daily_matches (user_id, calculated_at DESC, similarity_score DESC);
CREATE INDEX IF NOT EXISTS idx_daily_matches_unviewed 
    ON public.daily_matches (user_id, calculated_at, is_viewed) 
    WHERE is_viewed = FALSE;

-- RLS for daily matches
ALTER TABLE public.daily_matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own daily matches" ON public.daily_matches
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own daily matches" ON public.daily_matches
    FOR UPDATE USING (auth.uid() = user_id);

-- Function to generate daily matches for a user (called by background job)
CREATE OR REPLACE FUNCTION generate_daily_matches(target_user_id UUID, match_limit INT DEFAULT 20)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_embedding vector(1536);
    user_geohash TEXT;
    matches_generated INT := 0;
BEGIN
    -- Get user's embedding and location
    SELECT embedding, geohash_5 INTO user_embedding, user_geohash
    FROM public.profiles
    WHERE id = target_user_id;
    
    -- Skip if user has no embedding
    IF user_embedding IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Delete old matches (keep last 7 days)
    DELETE FROM public.daily_matches 
    WHERE user_id = target_user_id 
    AND calculated_at < CURRENT_DATE - INTERVAL '7 days';
    
    -- Generate new matches using vector similarity
    INSERT INTO public.daily_matches (user_id, match_user_id, similarity_score, match_reasons, calculated_at)
    SELECT 
        target_user_id,
        p.id,
        1 - (p.embedding <=> user_embedding) as similarity, -- Cosine similarity
        CASE 
            WHEN p.geohash_5 = user_geohash THEN '["High compatibility", "Nearby"]'::jsonb
            ELSE '["High compatibility"]'::jsonb
        END,
        CURRENT_DATE
    FROM public.profiles p
    WHERE p.id != target_user_id
    AND p.embedding IS NOT NULL
    AND p.is_visible = TRUE
    -- Exclude already matched users (in roster)
    AND NOT EXISTS (
        SELECT 1 FROM public.roster_matches rm 
        WHERE rm.user_id = target_user_id 
        AND rm.name = p.display_name -- Note: In production, use a proper match_profile_id column
    )
    -- Exclude today's already calculated matches
    AND NOT EXISTS (
        SELECT 1 FROM public.daily_matches dm
        WHERE dm.user_id = target_user_id
        AND dm.match_user_id = p.id
        AND dm.calculated_at = CURRENT_DATE
    )
    ORDER BY p.embedding <=> user_embedding -- Vector similarity ordering (uses HNSW index)
    LIMIT match_limit;
    
    GET DIAGNOSTICS matches_generated = ROW_COUNT;
    
    RETURN matches_generated;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 5: MESSAGES TABLE PARTITIONING
-- Essential for 500M+ messages at scale
-- ═══════════════════════════════════════════════════════════════════════════

-- Note: Partitioning existing tables requires data migration
-- This creates a partitioned version for new deployments
-- For existing deployments, use pg_partman extension

-- Create partitioned messages table (for fresh installs)
-- Partitioned by month for efficient querying and archival
CREATE TABLE IF NOT EXISTS public.messages_partitioned (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL,
    sender_id UUID NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    is_ai_generated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Create partitions for current and next 3 months
-- In production, use pg_partman to auto-create partitions
DO $$
DECLARE
    start_date DATE := date_trunc('month', CURRENT_DATE);
    partition_date DATE;
    partition_name TEXT;
    next_month DATE;
BEGIN
    FOR i IN 0..3 LOOP
        partition_date := start_date + (i || ' months')::interval;
        next_month := partition_date + '1 month'::interval;
        partition_name := 'messages_partitioned_' || to_char(partition_date, 'YYYY_MM');
        
        -- Check if partition exists before creating
        IF NOT EXISTS (
            SELECT 1 FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relname = partition_name AND n.nspname = 'public'
        ) THEN
            EXECUTE format(
                'CREATE TABLE IF NOT EXISTS public.%I PARTITION OF public.messages_partitioned
                FOR VALUES FROM (%L) TO (%L)',
                partition_name, partition_date, next_month
            );
        END IF;
    END LOOP;
END $$;

-- Index for fast message retrieval by conversation
CREATE INDEX IF NOT EXISTS idx_messages_partitioned_conversation 
    ON public.messages_partitioned (conversation_id, created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 6: BACKGROUND JOBS TABLE
-- Tracks async processing for feed generation, embeddings, etc.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.background_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type TEXT NOT NULL, -- 'generate_matches', 'update_embeddings', 'cleanup_stale'
    target_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed'
    priority INT DEFAULT 5, -- 1 = highest, 10 = lowest
    attempts INT DEFAULT 0,
    max_attempts INT DEFAULT 3,
    error_message TEXT,
    scheduled_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for job processing
CREATE INDEX IF NOT EXISTS idx_background_jobs_pending 
    ON public.background_jobs (status, priority, scheduled_at)
    WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_background_jobs_user 
    ON public.background_jobs (target_user_id, job_type);

-- Function to enqueue a background job
CREATE OR REPLACE FUNCTION enqueue_background_job(
    p_job_type TEXT,
    p_target_user_id UUID DEFAULT NULL,
    p_priority INT DEFAULT 5,
    p_scheduled_at TIMESTAMPTZ DEFAULT NOW()
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    job_id UUID;
BEGIN
    INSERT INTO public.background_jobs (job_type, target_user_id, priority, scheduled_at)
    VALUES (p_job_type, p_target_user_id, p_priority, p_scheduled_at)
    RETURNING id INTO job_id;
    
    RETURN job_id;
END;
$$;

-- Function to process next background job (called by Edge Function cron)
CREATE OR REPLACE FUNCTION process_next_background_job()
RETURNS TABLE (
    job_id UUID,
    job_type TEXT,
    target_user_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Claim the next pending job (with row-level locking to prevent duplicates)
    RETURN QUERY
    UPDATE public.background_jobs
    SET 
        status = 'running',
        started_at = NOW(),
        attempts = attempts + 1
    WHERE id = (
        SELECT id FROM public.background_jobs
        WHERE status = 'pending'
        AND scheduled_at <= NOW()
        AND attempts < max_attempts
        ORDER BY priority, scheduled_at
        LIMIT 1
        FOR UPDATE SKIP LOCKED
    )
    RETURNING 
        background_jobs.id,
        background_jobs.job_type,
        background_jobs.target_user_id;
END;
$$;

-- Function to mark job as completed
CREATE OR REPLACE FUNCTION complete_background_job(p_job_id UUID, p_success BOOLEAN, p_error TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.background_jobs
    SET 
        status = CASE WHEN p_success THEN 'completed' ELSE 'failed' END,
        completed_at = NOW(),
        error_message = p_error
    WHERE id = p_job_id;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 7: CONNECTION POOLING CONFIGURATION
-- Supavisor settings (configured via Supabase Dashboard)
-- ═══════════════════════════════════════════════════════════════════════════

-- Note: Connection pooling is configured in Supabase Dashboard:
-- 1. Go to Settings > Database > Connection Pooling
-- 2. Enable Supavisor (recommended over PgBouncer)
-- 3. Set Pool Mode: "Transaction" for most applications
-- 4. Set Pool Size: Start with 15, scale up to 100 based on load
-- 5. Use the pooler connection string in your app, not direct connection

-- Create a view to monitor connection usage
CREATE OR REPLACE VIEW public.connection_stats AS
SELECT 
    count(*) as total_connections,
    count(*) FILTER (WHERE state = 'active') as active_connections,
    count(*) FILTER (WHERE state = 'idle') as idle_connections,
    max(now() - query_start) as longest_running_query
FROM pg_stat_activity
WHERE datname = current_database();

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 8: RATE LIMITING & ABUSE PREVENTION
-- ═══════════════════════════════════════════════════════════════════════════

-- Table to track API rate limits
CREATE TABLE IF NOT EXISTS public.rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL, -- 'api_call', 'search', 'message', 'match_action'
    window_start TIMESTAMPTZ NOT NULL,
    request_count INT DEFAULT 1,
    
    CONSTRAINT unique_rate_limit UNIQUE (user_id, action_type, window_start)
);

-- Index for fast rate limit checks
CREATE INDEX IF NOT EXISTS idx_rate_limits_lookup 
    ON public.rate_limits (user_id, action_type, window_start DESC);

-- Function to check and increment rate limit
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_action_type TEXT,
    p_limit INT,
    p_window_minutes INT DEFAULT 60
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    current_window TIMESTAMPTZ;
    current_count INT;
BEGIN
    -- Calculate current window start (rounded to window size)
    current_window := date_trunc('hour', NOW()) + 
        (floor(extract(minute FROM NOW()) / p_window_minutes) * p_window_minutes || ' minutes')::interval;
    
    -- Upsert rate limit record
    INSERT INTO public.rate_limits (user_id, action_type, window_start, request_count)
    VALUES (p_user_id, p_action_type, current_window, 1)
    ON CONFLICT (user_id, action_type, window_start)
    DO UPDATE SET request_count = rate_limits.request_count + 1
    RETURNING request_count INTO current_count;
    
    -- Return TRUE if within limit, FALSE if exceeded
    RETURN current_count <= p_limit;
END;
$$;

-- Clean up old rate limit records (called by cron job)
CREATE OR REPLACE FUNCTION cleanup_rate_limits()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM public.rate_limits
    WHERE window_start < NOW() - INTERVAL '24 hours';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 9: ANALYTICS & MONITORING TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Aggregated daily stats (for dashboard, not real-time)
CREATE TABLE IF NOT EXISTS public.daily_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stat_date DATE NOT NULL UNIQUE,
    total_users INT DEFAULT 0,
    active_users INT DEFAULT 0, -- Users active in last 24h
    tonight_mode_users INT DEFAULT 0,
    new_signups INT DEFAULT 0,
    matches_created INT DEFAULT 0,
    messages_sent INT DEFAULT 0,
    games_played INT DEFAULT 0,
    calculated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to calculate daily stats (called by cron)
CREATE OR REPLACE FUNCTION calculate_daily_stats()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.daily_stats (
        stat_date,
        total_users,
        active_users,
        tonight_mode_users,
        new_signups,
        matches_created,
        messages_sent,
        games_played
    )
    SELECT 
        CURRENT_DATE,
        (SELECT count(*) FROM public.profiles),
        (SELECT count(*) FROM public.profiles WHERE last_active_at > NOW() - INTERVAL '24 hours'),
        (SELECT count(*) FROM public.profiles WHERE current_status = 'tonight_mode'),
        (SELECT count(*) FROM public.profiles WHERE created_at::date = CURRENT_DATE),
        (SELECT count(*) FROM public.roster_matches WHERE created_at::date = CURRENT_DATE),
        (SELECT count(*) FROM public.messages WHERE created_at::date = CURRENT_DATE),
        (SELECT count(*) FROM public.game_sessions WHERE created_at::date = CURRENT_DATE)
    ON CONFLICT (stat_date)
    DO UPDATE SET
        total_users = EXCLUDED.total_users,
        active_users = EXCLUDED.active_users,
        tonight_mode_users = EXCLUDED.tonight_mode_users,
        new_signups = EXCLUDED.new_signups,
        matches_created = EXCLUDED.matches_created,
        messages_sent = EXCLUDED.messages_sent,
        games_played = EXCLUDED.games_played,
        calculated_at = NOW();
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- PART 10: REALTIME CHANNEL MANAGEMENT
-- Enable realtime only on necessary tables with filters
-- ═══════════════════════════════════════════════════════════════════════════

-- Note: Configure in Supabase Dashboard under Database > Replication
-- Only enable realtime on:
-- 1. conversations (filtered by user_id)
-- 2. messages (filtered by conversation_id)
-- 3. game_sessions (filtered by participants)
--
-- DO NOT enable global realtime on profiles or roster_matches

-- Add publication for selective realtime (if not exists)
-- This is typically done via Dashboard, but here for reference
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.game_sessions;

COMMENT ON TABLE public.daily_matches IS 'Pre-calculated daily matches for async feed generation. Calculated by background job, not realtime.';
COMMENT ON TABLE public.background_jobs IS 'Queue for async processing: embedding generation, feed calculation, cleanup tasks.';
COMMENT ON TABLE public.rate_limits IS 'Rate limiting table to prevent API abuse. Cleaned up daily.';
COMMENT ON FUNCTION calculate_geohash IS 'Calculates geohash for geographic sharding. Used for Tonight Mode realtime channels.';
COMMENT ON FUNCTION generate_daily_matches IS 'Background job function to generate AI-powered match recommendations using vector similarity.';
