import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/content_rating.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG ANALYTICS SERVICE
/// ════════════════════════════════════════════════════════════════════════════
///
/// Unified analytics tracking for all TAG games. Provides methods for:
/// - Session lifecycle tracking
/// - Event logging
/// - Card engagement tracking
/// - User statistics
///
/// This integrates with the unified analytics tables in migration 023.

class TagAnalyticsService {
  TagAnalyticsService(this._supabase);
  final SupabaseClient _supabase;

  // ═══════════════════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new game session and return the session ID
  Future<String?> createSession({
    required TagGameType gameType,
    required int playerCount,
    required ContentRating contentRating,
    bool isDemoMode = false,
    bool isMultiplayer = false,
    Map<String, dynamic>? gameSettings,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('tag_game_sessions')
          .insert({
            'game_type': gameType.dbValue,
            'host_user_id': userId,
            'player_count': playerCount,
            'content_rating': contentRating.dbValue,
            'is_demo_mode': isDemoMode,
            'is_multiplayer': isMultiplayer,
            'game_settings': gameSettings ?? {},
            'status': 'created',
          })
          .select('id')
          .single();

      return response['id'] as String?;
    } catch (e) {
      debugPrint('TagAnalytics: Failed to create session - $e');
      return null;
    }
  }

  /// Start a game session
  Future<void> startSession(String sessionId) async {
    try {
      await _supabase.from('tag_game_sessions').update({
        'status': 'active',
        'started_at': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);

      await trackEvent(
        sessionId: sessionId,
        eventType: TagEventType.gameStart,
      );
    } catch (e) {
      debugPrint('TagAnalytics: Failed to start session - $e');
    }
  }

  /// Pause a game session
  Future<void> pauseSession(String sessionId) async {
    try {
      await _supabase
          .from('tag_game_sessions')
          .update({'status': 'paused'}).eq('id', sessionId);

      await trackEvent(
        sessionId: sessionId,
        eventType: TagEventType.gamePause,
      );
    } catch (e) {
      debugPrint('TagAnalytics: Failed to pause session - $e');
    }
  }

  /// Resume a game session
  Future<void> resumeSession(String sessionId) async {
    try {
      await _supabase
          .from('tag_game_sessions')
          .update({'status': 'active'}).eq('id', sessionId);

      await trackEvent(
        sessionId: sessionId,
        eventType: TagEventType.gameResume,
      );
    } catch (e) {
      debugPrint('TagAnalytics: Failed to resume session - $e');
    }
  }

  /// End a game session
  Future<void> endSession({
    required String sessionId,
    required int totalRounds,
    required int totalCardsShown,
    required int totalSkips,
    required int totalCompletions,
  }) async {
    try {
      await _supabase.from('tag_game_sessions').update({
        'status': 'completed',
        'ended_at': DateTime.now().toIso8601String(),
        'total_rounds': totalRounds,
        'total_cards_shown': totalCardsShown,
        'total_skips': totalSkips,
        'total_completions': totalCompletions,
      }).eq('id', sessionId);

      await trackEvent(
        sessionId: sessionId,
        eventType: TagEventType.gameEnd,
        eventData: {
          'total_rounds': totalRounds,
          'total_cards_shown': totalCardsShown,
          'completion_rate':
              totalCardsShown > 0 ? (totalCompletions / totalCardsShown) : 0,
        },
      );
    } catch (e) {
      debugPrint('TagAnalytics: Failed to end session - $e');
    }
  }

  /// Mark session as abandoned
  Future<void> abandonSession(String sessionId) async {
    try {
      await _supabase.from('tag_game_sessions').update({
        'status': 'abandoned',
        'ended_at': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      debugPrint('TagAnalytics: Failed to abandon session - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track a game event
  Future<void> trackEvent({
    required String sessionId,
    required TagEventType eventType,
    int? playerIndex,
    String? cardId,
    String? cardType,
    Map<String, dynamic>? eventData,
  }) async {
    try {
      await _supabase.from('tag_game_events').insert({
        'session_id': sessionId,
        'event_type': eventType.dbValue,
        'player_index': playerIndex,
        'card_id': cardId,
        'card_type': cardType,
        'event_data': eventData ?? {},
      });
    } catch (e) {
      debugPrint('TagAnalytics: Failed to track event - $e');
    }
  }

  /// Track card shown
  Future<void> trackCardShown({
    required String sessionId,
    required String cardId,
    String? cardType,
    int? playerIndex,
  }) async {
    await trackEvent(
      sessionId: sessionId,
      eventType: TagEventType.cardShown,
      cardId: cardId,
      cardType: cardType,
      playerIndex: playerIndex,
    );
  }

  /// Track card completed
  Future<void> trackCardCompleted({
    required String sessionId,
    required String cardId,
    required String cardTable,
    String? cardType,
    int? playerIndex,
    int? rating,
  }) async {
    await trackEvent(
      sessionId: sessionId,
      eventType: TagEventType.cardCompleted,
      cardId: cardId,
      cardType: cardType,
      playerIndex: playerIndex,
      eventData: rating != null ? {'rating': rating} : null,
    );

    // Update card engagement
    await trackCardEngagement(
      cardTable: cardTable,
      cardId: cardId,
      wasCompleted: true,
      rating: rating,
    );
  }

  /// Track card skipped
  Future<void> trackCardSkipped({
    required String sessionId,
    required String cardId,
    required String cardTable,
    String? cardType,
    int? playerIndex,
  }) async {
    await trackEvent(
      sessionId: sessionId,
      eventType: TagEventType.cardSkipped,
      cardId: cardId,
      cardType: cardType,
      playerIndex: playerIndex,
    );

    // Update card engagement
    await trackCardEngagement(
      cardTable: cardTable,
      cardId: cardId,
      wasCompleted: false,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD ENGAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track card engagement (uses database function for upsert)
  Future<void> trackCardEngagement({
    required String cardTable,
    required String cardId,
    required bool wasCompleted,
    int? rating,
  }) async {
    try {
      await _supabase.rpc(
        'track_card_engagement',
        params: {
          'p_card_table': cardTable,
          'p_card_id': cardId,
          'p_was_completed': wasCompleted,
          'p_rating': rating,
        },
      );
    } catch (e) {
      debugPrint('TagAnalytics: Failed to track card engagement - $e');
    }
  }

  /// Get popular cards for a game
  Future<List<Map<String, dynamic>>> getPopularCards({
    required String cardTable,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_popular_cards',
        params: {
          'p_card_table': cardTable,
          'p_limit': limit,
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('TagAnalytics: Failed to get popular cards - $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER STATISTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update user stats after game
  Future<void> updateUserStats({
    required TagGameType gameType,
    required int playTimeSeconds,
    required int cardsCompleted,
    required int cardsSkipped,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc(
        'update_user_game_stats',
        params: {
          'p_user_id': userId,
          'p_game_type': gameType.dbValue,
          'p_play_time_seconds': playTimeSeconds,
          'p_cards_completed': cardsCompleted,
          'p_cards_skipped': cardsSkipped,
        },
      );
    } catch (e) {
      debugPrint('TagAnalytics: Failed to update user stats - $e');
    }
  }

  /// Get current user's stats
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('tag_user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('TagAnalytics: Failed to get user stats - $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get daily stats for a game type
  Future<List<Map<String, dynamic>>> getDailyStats({
    TagGameType? gameType,
    int days = 30,
  }) async {
    try {
      var query = _supabase.from('tag_daily_stats').select();

      if (gameType != null) {
        query = query.eq('game_type', gameType.dbValue);
      }

      final response = await query.limit(days);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('TagAnalytics: Failed to get daily stats - $e');
      return [];
    }
  }

  /// Get content rating popularity
  Future<List<Map<String, dynamic>>> getRatingPopularity({
    TagGameType? gameType,
  }) async {
    try {
      var query = _supabase.from('tag_rating_popularity').select();

      if (gameType != null) {
        query = query.eq('game_type', gameType.dbValue);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('TagAnalytics: Failed to get rating popularity - $e');
      return [];
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// Game types supported by the analytics system
enum TagGameType {
  downToClown('down_to_clown', 'Down to Clown'),
  iceBreakers('ice_breakers', 'Ice Breakers'),
  shareOrDare('share_or_dare', 'Share or Dare'),
  pathOfPleasure('path_of_pleasure', 'Path of Pleasure'),
  laneOfLust('lane_of_lust', 'Lane of Lust'),
  dramaSutra('drama_sutra', 'Drama-Sutra'),
  flashFreeze('flash_freeze', 'Flash & Freeze');

  final String dbValue;
  final String displayName;

  const TagGameType(this.dbValue, this.displayName);

  /// Get game type from database value
  static TagGameType? fromDbValue(String value) =>
      TagGameType.values.where((t) => t.dbValue == value).firstOrNull;
}

/// Event types for analytics tracking
enum TagEventType {
  // Lifecycle events
  gameStart('game_start'),
  gamePause('game_pause'),
  gameResume('game_resume'),
  gameEnd('game_end'),

  // Player events
  playerJoin('player_join'),
  playerLeave('player_leave'),
  playerTurn('player_turn'),

  // Card/Content events
  cardShown('card_shown'),
  cardCompleted('card_completed'),
  cardSkipped('card_skipped'),
  cardRated('card_rated'),

  // Special events
  roundComplete('round_complete'),
  achievementUnlocked('achievement_unlocked'),
  photoCaptured('photo_captured'),
  timerExpired('timer_expired'),

  // Multiplayer events
  roomCreated('room_created'),
  roomJoined('room_joined'),
  syncState('sync_state');

  final String dbValue;

  const TagEventType(this.dbValue);
}
