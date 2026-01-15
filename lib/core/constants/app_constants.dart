/// Clean Architecture Constants
/// Defines application-wide constant values
class AppConstants {
  AppConstants._();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PAGINATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Focus Batch size for The Scope (curated matches)
  static const int focusBatchSize = 5;
  
  /// Roster page size
  static const int rosterPageSize = 20;
  
  /// Wire (messaging) page size
  static const int wirePageSize = 50;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TIMEOUTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// API request timeout
  static const Duration apiTimeout = Duration(seconds: 30);
  
  /// Realtime subscription timeout
  static const Duration realtimeTimeout = Duration(seconds: 60);
  
  /// Cache expiration
  static const Duration cacheExpiration = Duration(hours: 1);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TAGS GAME SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Default consent level
  static const int defaultConsentLevel = 0; // Green
  
  /// Maximum players for multiplayer games
  static const int maxGamePlayers = 8;
  
  /// Minimum players for multiplayer games
  static const int minGamePlayers = 2;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ROSTER PIPELINE STAGES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<String> pipelineStages = [
    'Incoming',
    'The Bench',
    'Active Rotation',
    'Legacy',
  ];
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Duration quickAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // OPENAI
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String openaiModel = 'gpt-4-turbo-preview';
  static const int maxTokens = 500;
}
