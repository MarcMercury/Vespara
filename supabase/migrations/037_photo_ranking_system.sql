-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 037: Photo Ranking System
-- Crowdsourced photo rankings with AI recommendations
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE 1: Profile Photos (up to 5 per user)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS profile_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  position INT CHECK (position BETWEEN 1 AND 5),
  is_primary BOOLEAN DEFAULT FALSE,
  
  -- Versioning: When photo is replaced, increment version and reset rankings
  version INT DEFAULT 1,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, position)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE 2: Photo Rankings (one user ranks another's photos)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS photo_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ranker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  ranked_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Store rankings as array of photo_ids in ranked order (1st = best)
  ranked_photo_ids UUID[] NOT NULL,
  
  -- Track photo versions at time of ranking
  photo_versions JSONB NOT NULL DEFAULT '{}',
  
  -- Validity flag - set to false when photos change
  is_valid BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(ranker_id, ranked_user_id)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE 3: Aggregated Scores (materialized for performance)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS photo_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_id UUID REFERENCES profile_photos(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  photo_version INT NOT NULL DEFAULT 1,
  
  -- Aggregated metrics
  average_rank FLOAT DEFAULT 3.0,
  total_rankings INT DEFAULT 0,
  rank_distribution JSONB DEFAULT '{"1":0,"2":0,"3":0,"4":0,"5":0}',
  
  -- AI recommendation
  ai_recommended_position INT,
  confidence_score FLOAT DEFAULT 0,
  
  -- Minimum threshold
  has_enough_data BOOLEAN DEFAULT FALSE,
  
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(photo_id, photo_version)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTION: Ensure only one primary photo per user
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION ensure_single_primary()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_primary = TRUE THEN
    UPDATE profile_photos
    SET is_primary = FALSE
    WHERE user_id = NEW.user_id
      AND id != NEW.id
      AND is_primary = TRUE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS single_primary_trigger ON profile_photos;
CREATE TRIGGER single_primary_trigger
BEFORE INSERT OR UPDATE ON profile_photos
FOR EACH ROW
WHEN (NEW.is_primary = TRUE)
EXECUTE FUNCTION ensure_single_primary();

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTION: Handle photo changes (replacement)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION handle_photo_change()
RETURNS TRIGGER AS $$
BEGIN
  -- If photo_url changed, this is a replacement
  IF OLD.photo_url IS DISTINCT FROM NEW.photo_url THEN
    -- Increment version
    NEW.version := COALESCE(OLD.version, 1) + 1;
    NEW.updated_at := NOW();
    
    -- Invalidate rankings that included the old version
    UPDATE photo_rankings
    SET is_valid = FALSE,
        updated_at = NOW()
    WHERE ranked_user_id = NEW.user_id
      AND OLD.id = ANY(ranked_photo_ids);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS photo_change_trigger ON profile_photos;
CREATE TRIGGER photo_change_trigger
BEFORE UPDATE ON profile_photos
FOR EACH ROW
EXECUTE FUNCTION handle_photo_change();

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTION: Handle photo deletion
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION handle_photo_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Invalidate any rankings that included this photo
  UPDATE photo_rankings
  SET is_valid = FALSE,
      ranked_photo_ids = array_remove(ranked_photo_ids, OLD.id),
      updated_at = NOW()
  WHERE OLD.id = ANY(ranked_photo_ids);
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS photo_delete_trigger ON profile_photos;
CREATE TRIGGER photo_delete_trigger
BEFORE DELETE ON profile_photos
FOR EACH ROW
EXECUTE FUNCTION handle_photo_delete();

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTION: Recalculate scores when ranking is submitted
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION recalculate_photo_scores()
RETURNS TRIGGER AS $$
DECLARE
  photo_uuid UUID;
  pos INT;
  photo_rec RECORD;
  ranking_count INT;
  avg_rank FLOAT;
BEGIN
  -- Only process valid rankings
  IF NOT NEW.is_valid THEN
    RETURN NEW;
  END IF;
  
  -- For each photo in the ranking, update its score
  IF NEW.ranked_photo_ids IS NOT NULL AND array_length(NEW.ranked_photo_ids, 1) > 0 THEN
    FOR pos IN 1..array_length(NEW.ranked_photo_ids, 1) LOOP
      photo_uuid := NEW.ranked_photo_ids[pos];
      
      -- Get current photo info
      SELECT id, user_id, version INTO photo_rec 
      FROM profile_photos 
      WHERE id = photo_uuid;
      
      IF FOUND THEN
        -- Calculate stats for this photo
        SELECT 
          COUNT(*),
          AVG(array_position(pr.ranked_photo_ids, photo_uuid))
        INTO ranking_count, avg_rank
        FROM photo_rankings pr
        WHERE pr.is_valid = TRUE
          AND photo_uuid = ANY(pr.ranked_photo_ids);
        
        -- Upsert score
        INSERT INTO photo_scores (photo_id, user_id, photo_version, average_rank, total_rankings, has_enough_data, updated_at)
        VALUES (
          photo_uuid, 
          photo_rec.user_id, 
          photo_rec.version, 
          COALESCE(avg_rank, 3.0),
          COALESCE(ranking_count, 0),
          COALESCE(ranking_count, 0) >= 5,
          NOW()
        )
        ON CONFLICT (photo_id, photo_version) 
        DO UPDATE SET 
          average_rank = COALESCE(avg_rank, 3.0),
          total_rankings = COALESCE(ranking_count, 0),
          has_enough_data = COALESCE(ranking_count, 0) >= 5,
          updated_at = NOW();
      END IF;
    END LOOP;
    
    -- Update AI recommendations for ranked user
    PERFORM update_ai_recommendations(NEW.ranked_user_id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ranking_submitted_trigger ON photo_rankings;
CREATE TRIGGER ranking_submitted_trigger
AFTER INSERT OR UPDATE ON photo_rankings
FOR EACH ROW
EXECUTE FUNCTION recalculate_photo_scores();

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTION: Update AI recommendations for a user
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_ai_recommendations(target_user_id UUID)
RETURNS VOID AS $$
DECLARE
  photo_rec RECORD;
  rec_position INT := 1;
BEGIN
  -- Update each photo's recommended position based on average rank
  FOR photo_rec IN (
    SELECT ps.photo_id, ps.average_rank, ps.total_rankings, ps.photo_version
    FROM photo_scores ps
    JOIN profile_photos pp ON pp.id = ps.photo_id AND pp.version = ps.photo_version
    WHERE pp.user_id = target_user_id
      AND ps.has_enough_data = TRUE
    ORDER BY ps.average_rank ASC
  ) LOOP
    UPDATE photo_scores
    SET 
      ai_recommended_position = rec_position,
      confidence_score = LEAST(1.0, photo_rec.total_rankings::float / 50.0),
      updated_at = NOW()
    WHERE photo_id = photo_rec.photo_id
      AND photo_version = photo_rec.photo_version;
    
    rec_position := rec_position + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTION: Check ranking rate limit (20 per day)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION check_ranking_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  recent_count INT;
BEGIN
  SELECT COUNT(*) INTO recent_count
  FROM photo_rankings
  WHERE ranker_id = NEW.ranker_id
    AND created_at > NOW() - INTERVAL '24 hours';
  
  IF recent_count >= 100 THEN
    RAISE EXCEPTION 'Rate limit exceeded: max 100 rankings per day';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ranking_rate_limit_trigger ON photo_rankings;
CREATE TRIGGER ranking_rate_limit_trigger
BEFORE INSERT ON photo_rankings
FOR EACH ROW
EXECUTE FUNCTION check_ranking_rate_limit();

-- ═══════════════════════════════════════════════════════════════════════════
-- STORAGE BUCKET for profile photos
-- ═══════════════════════════════════════════════════════════════════════════
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-photos', 
  'profile-photos', 
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- ═══════════════════════════════════════════════════════════════════════════
-- STORAGE POLICIES
-- ═══════════════════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "Users upload own photos" ON storage.objects;
CREATE POLICY "Users upload own photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "Anyone views photos" ON storage.objects;
CREATE POLICY "Anyone views photos" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-photos');

DROP POLICY IF EXISTS "Users delete own photos" ON storage.objects;
CREATE POLICY "Users delete own photos" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "Users update own photos" ON storage.objects;
CREATE POLICY "Users update own photos" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES for profile_photos
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View all photos" ON profile_photos;
CREATE POLICY "View all photos" ON profile_photos 
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Insert own photos" ON profile_photos;
CREATE POLICY "Insert own photos" ON profile_photos 
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Update own photos" ON profile_photos;
CREATE POLICY "Update own photos" ON profile_photos 
FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Delete own photos" ON profile_photos;
CREATE POLICY "Delete own photos" ON profile_photos 
FOR DELETE USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES for photo_rankings
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE photo_rankings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View own rankings given" ON photo_rankings;
CREATE POLICY "View own rankings given" ON photo_rankings 
FOR SELECT USING (auth.uid() = ranker_id);

DROP POLICY IF EXISTS "Submit rankings for others" ON photo_rankings;
CREATE POLICY "Submit rankings for others" ON photo_rankings 
FOR INSERT WITH CHECK (auth.uid() = ranker_id AND auth.uid() != ranked_user_id);

DROP POLICY IF EXISTS "Update own rankings" ON photo_rankings;
CREATE POLICY "Update own rankings" ON photo_rankings 
FOR UPDATE USING (auth.uid() = ranker_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES for photo_scores
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE photo_scores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View own scores" ON photo_scores;
CREATE POLICY "View own scores" ON photo_scores 
FOR SELECT USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- INDEXES for performance
-- ═══════════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_photos_user_position ON profile_photos(user_id, position);
CREATE INDEX IF NOT EXISTS idx_photos_user_primary ON profile_photos(user_id) WHERE is_primary = TRUE;
CREATE INDEX IF NOT EXISTS idx_rankings_ranked_user ON photo_rankings(ranked_user_id) WHERE is_valid = TRUE;
CREATE INDEX IF NOT EXISTS idx_rankings_ranker ON photo_rankings(ranker_id);
CREATE INDEX IF NOT EXISTS idx_scores_user ON photo_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_scores_photo ON photo_scores(photo_id);
