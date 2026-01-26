import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// ENGAGEMENT ANALYTICS SERVICE - Learn What Works
/// ════════════════════════════════════════════════════════════════════════════
///
/// Silently tracks user engagement patterns to learn:
/// - Which game prompts get best responses
/// - What times users are most active
/// - Conversation patterns that lead to dates
/// - Game completion rates by content type
///
/// All data is used to improve the experience - no user action required.

class EngagementAnalyticsService {
  EngagementAnalyticsService._();
  static EngagementAnalyticsService? _instance;
  static EngagementAnalyticsService get instance =>
      _instance ??= EngagementAnalyticsService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Batch events for efficiency
  final List<AnalyticsEvent> _eventQueue = [];
  Timer? _flushTimer;
  final int _batchSize = 20;
  final Duration _flushInterval = const Duration(seconds: 30);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track when a game session starts
  void trackGameStart({
    required String gameType,
    required String heatLevel,
    required int playerCount,
    String? sessionId,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'game_start',
        properties: {
          'game_type': gameType,
          'heat_level': heatLevel,
          'player_count': playerCount,
          'session_id': sessionId,
        },
      ),
    );
  }

  /// Track when a game session ends
  void trackGameEnd({
    required String gameType,
    required String sessionId,
    required int roundsPlayed,
    required Duration duration,
    required bool completed,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'game_end',
        properties: {
          'game_type': gameType,
          'session_id': sessionId,
          'rounds_played': roundsPlayed,
          'duration_seconds': duration.inSeconds,
          'completed': completed,
        },
      ),
    );
  }

  /// Track individual prompt/card engagement
  void trackPromptEngagement({
    required String gameType,
    required String promptId,
    required String heatLevel,
    required PromptAction action,
    Duration? timeSpent,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'prompt_engagement',
        properties: {
          'game_type': gameType,
          'prompt_id': promptId,
          'heat_level': heatLevel,
          'action': action.name,
          'time_spent_seconds': timeSpent?.inSeconds,
        },
      ),
    );
  }

  /// Track heat level selection
  void trackHeatSelection({
    required String gameType,
    required String selectedHeat,
    String? previousHeat,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'heat_selection',
        properties: {
          'game_type': gameType,
          'selected_heat': selectedHeat,
          'previous_heat': previousHeat,
          'changed': previousHeat != null && previousHeat != selectedHeat,
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATION ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track message sent
  void trackMessageSent({
    required String matchId,
    required int messageLength,
    required bool isFirstMessage,
    bool? hasEmoji,
    bool? hasQuestion,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'message_sent',
        properties: {
          'match_id': matchId,
          'message_length': messageLength,
          'is_first_message': isFirstMessage,
          'has_emoji': hasEmoji,
          'has_question': hasQuestion,
        },
      ),
    );
  }

  /// Track message received/read
  void trackMessageRead({
    required String matchId,
    required Duration timeToRead,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'message_read',
        properties: {
          'match_id': matchId,
          'time_to_read_seconds': timeToRead.inSeconds,
        },
      ),
    );
  }

  /// Track conversation milestone
  void trackConversationMilestone({
    required String matchId,
    required ConversationMilestone milestone,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'conversation_milestone',
        properties: {
          'match_id': matchId,
          'milestone': milestone.name,
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATCHING ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track profile view
  void trackProfileView({
    required String viewedProfileId,
    required Duration viewDuration,
    required int photosViewed,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'profile_view',
        properties: {
          'viewed_profile_id': viewedProfileId,
          'view_duration_seconds': viewDuration.inSeconds,
          'photos_viewed': photosViewed,
        },
      ),
    );
  }

  /// Track swipe action
  void trackSwipe({
    required String profileId,
    required SwipeAction action,
    required Duration decisionTime,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'swipe',
        properties: {
          'profile_id': profileId,
          'action': action.name,
          'decision_time_seconds': decisionTime.inSeconds,
        },
      ),
    );
  }

  /// Track match
  void trackMatch({
    required String matchId,
    required String matchedUserId,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'match',
        properties: {
          'match_id': matchId,
          'matched_user_id': matchedUserId,
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SESSION ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track app session start
  void trackSessionStart() {
    _enqueue(
      AnalyticsEvent(
        type: 'session_start',
        properties: {
          'hour_of_day': DateTime.now().hour,
          'day_of_week': DateTime.now().weekday,
        },
      ),
    );
  }

  /// Track app session end
  void trackSessionEnd({required Duration sessionDuration}) {
    _enqueue(
      AnalyticsEvent(
        type: 'session_end',
        properties: {
          'duration_seconds': sessionDuration.inSeconds,
        },
      ),
    );

    // Flush immediately on session end
    _flush();
  }

  /// Track screen view
  void trackScreenView({
    required String screenName,
    Map<String, dynamic>? properties,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'screen_view',
        properties: {
          'screen_name': screenName,
          ...?properties,
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEATURE USAGE ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track feature used
  void trackFeatureUsed({
    required String feature,
    Map<String, dynamic>? properties,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'feature_used',
        properties: {
          'feature': feature,
          ...?properties,
        },
      ),
    );
  }

  /// Track AI feature used (for Phase 2+)
  void trackAIFeatureUsed({
    required String feature,
    required bool accepted,
    Duration? generationTime,
  }) {
    _enqueue(
      AnalyticsEvent(
        type: 'ai_feature_used',
        properties: {
          'feature': feature,
          'accepted': accepted,
          'generation_time_ms': generationTime?.inMilliseconds,
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA RETRIEVAL (for ML/learning)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user's active hours (for smart notifications)
  Future<List<int>> getUserActiveHours() async {
    if (_userId == null) return [];

    try {
      final response = await _supabase
          .from('engagement_events')
          .select('properties')
          .eq('user_id', _userId!)
          .eq('event_type', 'session_start')
          .order('created_at', ascending: false)
          .limit(100);

      final hours = <int, int>{};
      for (final row in response as List) {
        final props = row['properties'] as Map<String, dynamic>?;
        final hour = props?['hour_of_day'] as int?;
        if (hour != null) {
          hours[hour] = (hours[hour] ?? 0) + 1;
        }
      }

      // Return top 3 most active hours
      final sorted = hours.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(3).map((e) => e.key).toList();
    } catch (e) {
      debugPrint('EngagementAnalytics: Failed to get active hours - $e');
      return [];
    }
  }

  /// Get user's preferred heat levels by game
  Future<Map<String, String>> getPreferredHeatLevels() async {
    if (_userId == null) return {};

    try {
      final response = await _supabase
          .from('engagement_events')
          .select('properties')
          .eq('user_id', _userId!)
          .eq('event_type', 'heat_selection')
          .order('created_at', ascending: false)
          .limit(50);

      final preferences = <String, Map<String, int>>{};

      for (final row in response as List) {
        final props = row['properties'] as Map<String, dynamic>?;
        final game = props?['game_type'] as String?;
        final heat = props?['selected_heat'] as String?;

        if (game != null && heat != null) {
          preferences[game] ??= {};
          preferences[game]![heat] = (preferences[game]![heat] ?? 0) + 1;
        }
      }

      // Return most common heat level for each game
      return preferences.map((game, heats) {
        final sorted = heats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return MapEntry(game, sorted.first.key);
      });
    } catch (e) {
      debugPrint('EngagementAnalytics: Failed to get heat preferences - $e');
      return {};
    }
  }

  /// Get prompt effectiveness scores
  Future<Map<String, double>> getPromptScores(String gameType) async {
    try {
      final response = await _supabase
          .from('engagement_events')
          .select('properties')
          .eq('event_type', 'prompt_engagement')
          .order('created_at', ascending: false)
          .limit(500);

      final scores = <String, List<double>>{};

      for (final row in response as List) {
        final props = row['properties'] as Map<String, dynamic>?;
        if (props?['game_type'] != gameType) continue;

        final promptId = props?['prompt_id'] as String?;
        final action = props?['action'] as String?;

        if (promptId != null && action != null) {
          scores[promptId] ??= [];
          scores[promptId]!.add(_actionToScore(action));
        }
      }

      // Return average score per prompt
      return scores.map((id, scoreList) {
        final avg = scoreList.reduce((a, b) => a + b) / scoreList.length;
        return MapEntry(id, avg);
      });
    } catch (e) {
      debugPrint('EngagementAnalytics: Failed to get prompt scores - $e');
      return {};
    }
  }

  double _actionToScore(String action) {
    switch (action) {
      case 'completed':
        return 1.0;
      case 'laughed':
        return 0.9;
      case 'liked':
        return 0.8;
      case 'skipped':
        return 0.3;
      case 'reported':
        return 0.0;
      default:
        return 0.5;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT QUEUE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  void _enqueue(AnalyticsEvent event) {
    if (_userId == null) return;

    _eventQueue.add(
      event.copyWith(
        userId: _userId,
        timestamp: DateTime.now(),
      ),
    );

    // Start flush timer if not running
    _flushTimer ??= Timer.periodic(_flushInterval, (_) => _flush());

    // Flush if batch size reached
    if (_eventQueue.length >= _batchSize) {
      _flush();
    }
  }

  Future<void> _flush() async {
    if (_eventQueue.isEmpty) return;

    final events = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    try {
      await _supabase.from('engagement_events').insert(
            events
                .map(
                  (e) => {
                    'user_id': e.userId,
                    'event_type': e.type,
                    'properties': e.properties,
                    'created_at': e.timestamp?.toIso8601String(),
                  },
                )
                .toList(),
          );

      debugPrint('EngagementAnalytics: Flushed ${events.length} events');
    } catch (e) {
      // Re-queue on failure
      _eventQueue.addAll(events);
      debugPrint('EngagementAnalytics: Flush failed, re-queued - $e');
    }
  }

  /// Force flush (call on app close)
  Future<void> forceFlush() async {
    _flushTimer?.cancel();
    await _flush();
  }

  void dispose() {
    _flushTimer?.cancel();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class AnalyticsEvent {
  AnalyticsEvent({
    required this.type,
    required this.properties,
    this.userId,
    this.timestamp,
  });
  final String type;
  final Map<String, dynamic> properties;
  final String? userId;
  final DateTime? timestamp;

  AnalyticsEvent copyWith({
    String? type,
    Map<String, dynamic>? properties,
    String? userId,
    DateTime? timestamp,
  }) =>
      AnalyticsEvent(
        type: type ?? this.type,
        properties: properties ?? this.properties,
        userId: userId ?? this.userId,
        timestamp: timestamp ?? this.timestamp,
      );
}

enum PromptAction {
  shown,
  skipped,
  completed,
  liked,
  laughed,
  reported,
}

enum SwipeAction {
  like,
  pass,
  superLike,
}

enum ConversationMilestone {
  firstMessage,
  tenMessages,
  fiftyMessages,
  hundredMessages,
  exchangedPhotos,
  exchangedNumbers,
  scheduledDate,
}
