/// ════════════════════════════════════════════════════════════════════════════
/// SCALABILITY CONFIGURATION
/// Production settings for 1M+ users
/// 
/// PHASE 6: These settings optimize for scale vs. cost
/// ════════════════════════════════════════════════════════════════════════════

class ScaleConfig {
  ScaleConfig._();

  // ═══════════════════════════════════════════════════════════════════════════
  // FEED CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Use pre-calculated daily matches instead of realtime vector search
  /// Set to false for <50k users, true for 50k+ users
  static const bool usePreCalculatedFeed = true;
  
  /// Maximum matches to show per day
  static const int dailyMatchLimit = 20;
  
  /// Minimum similarity score for matches (0.0 - 1.0)
  static const double minSimilarityScore = 0.65;

  // ═══════════════════════════════════════════════════════════════════════════
  // TONIGHT MODE CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Use geohash sharding for realtime subscriptions
  /// Prevents global broadcast DDoS at scale
  static const bool useGeohashSharding = true;
  
  /// Geohash precision for Tonight Mode channels
  /// 4 = ~39km (city), 5 = ~5km (neighborhood), 6 = ~1.2km (block)
  static const int tonightModeGeohashPrecision = 5;
  
  /// Location update interval in seconds
  static const int locationUpdateIntervalSeconds = 30;
  
  /// Maximum nearby users to display
  static const int maxNearbyUsers = 50;

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP CONFIGURATION (Cost Optimization)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Show static radar UI instead of Google Maps on home screen
  /// Google Maps = $7/1000 loads = $200k/month at 1M users
  static const bool useStaticRadarInsteadOfMaps = true;
  
  /// Only load interactive map when user explicitly requests
  static const bool lazyLoadInteractiveMaps = true;
  
  /// Cache map tiles for offline use
  static const bool cacheMapTiles = true;

  // ═══════════════════════════════════════════════════════════════════════════
  // AI MODEL CONFIGURATION (Cost Optimization)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Model to use for simple tasks (Ghost Protocol, Resuscitator)
  /// gpt-4o-mini is 30x cheaper than gpt-4o
  static const String simpleTaskModel = 'gpt-4o-mini';
  
  /// Model to use for complex tasks (Strategist, advanced matching)
  static const String complexTaskModel = 'gpt-4o';
  
  /// Maximum tokens for simple responses
  static const int simpleMaxTokens = 150;
  
  /// Maximum tokens for complex responses
  static const int complexMaxTokens = 500;

  // ═══════════════════════════════════════════════════════════════════════════
  // REALTIME CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Tables that should have realtime enabled
  /// Keep this minimal to reduce server load
  static const List<String> realtimeTables = [
    'conversations',
    'messages',
    'game_sessions',
  ];
  
  /// Tables that should NOT have realtime (use polling instead)
  static const List<String> noRealtimeTables = [
    'profiles',
    'roster_matches',
    'daily_matches',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHING CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Cache duration for profile data (seconds)
  static const int profileCacheDuration = 300; // 5 minutes
  
  /// Cache duration for feed data (seconds)
  static const int feedCacheDuration = 3600; // 1 hour
  
  /// Cache duration for game definitions (seconds)
  static const int gameCacheDuration = 86400; // 24 hours

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND JOB CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// How often to process background jobs (minutes)
  static const int jobProcessingIntervalMinutes = 1;
  
  /// Maximum jobs to process per invocation
  static const int maxJobsPerInvocation = 10;
  
  /// Maximum retry attempts for failed jobs
  static const int maxJobRetries = 3;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTION POOLING NOTES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Connection pool settings (configured in Supabase Dashboard):
  /// 
  /// 1. Go to Settings > Database > Connection Pooling
  /// 2. Enable Supavisor (NOT PgBouncer)
  /// 3. Pool Mode: "Transaction" (recommended)
  /// 4. Pool Size: Start at 15, scale to 100 based on load
  /// 5. Use pooler connection string in production
  /// 
  /// Direct connections: ~100-500 max
  /// Pooled connections: 10,000+ concurrent users
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SCALING THRESHOLDS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// User count thresholds for scaling decisions
  static const int threshold_enablePooling = 1000;
  static const int threshold_enableGeohash = 10000;
  static const int threshold_enablePreCalculatedFeed = 50000;
  static const int threshold_enablePartitioning = 100000;
  static const int threshold_enableMultiRegion = 500000;
}
