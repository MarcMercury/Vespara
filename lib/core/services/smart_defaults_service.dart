import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'engagement_analytics_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SMART DEFAULTS SERVICE - Invisible Intelligence
/// ════════════════════════════════════════════════════════════════════════════
///
/// Automatically selects optimal defaults based on learned behavior:
/// - Game heat levels based on history
/// - Best times to message based on match activity
/// - Profile field suggestions based on patterns
///
/// Users feel like "the app just gets me" - no effort required.

class SmartDefaultsService {
  static SmartDefaultsService? _instance;
  static SmartDefaultsService get instance => _instance ??= SmartDefaultsService._();

  SmartDefaultsService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final EngagementAnalyticsService _analytics = EngagementAnalyticsService.instance;

  // Cached defaults (refreshed periodically)
  Map<String, String> _heatLevelDefaults = {};
  List<int> _activeHours = [];
  Map<String, dynamic> _userPatterns = {};
  DateTime? _lastRefresh;

  final Duration _refreshInterval = const Duration(minutes: 30);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // HEAT LEVEL DEFAULTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get suggested heat level for a game based on user history
  Future<String> getSuggestedHeatLevel(String gameType) async {
    await _ensureRefreshed();

    // Check cached defaults
    if (_heatLevelDefaults.containsKey(gameType)) {
      return _heatLevelDefaults[gameType]!;
    }

    // Fallback to database query
    if (_userId != null) {
      try {
        final result = await _supabase.rpc('get_user_preferred_heat', params: {
          'p_user_id': _userId,
          'p_game_type': gameType,
        });
        
        if (result != null) {
          _heatLevelDefaults[gameType] = result as String;
          return result;
        }
      } catch (e) {
        debugPrint('SmartDefaults: Failed to get heat level - $e');
      }
    }

    // Default based on game type
    return _getDefaultHeatForGame(gameType);
  }

  /// Get heat level for a couple based on relationship stage
  Future<String> getSuggestedHeatForCouple({
    required String matchId,
    required String gameType,
  }) async {
    if (_userId == null) return 'PG';

    try {
      // Get relationship metrics
      final metrics = await _getRelationshipMetrics(matchId);
      
      // Determine appropriate heat based on relationship stage
      if (metrics['message_count'] < 10) {
        return 'PG'; // Just getting to know each other
      } else if (metrics['message_count'] < 50) {
        return 'PG-13'; // Building comfort
      } else if (metrics['days_matched'] > 7 && metrics['message_count'] > 100) {
        return 'R'; // Established connection
      }
      
      // Fall back to user's general preference
      return getSuggestedHeatLevel(gameType);
    } catch (e) {
      debugPrint('SmartDefaults: Failed to get couple heat - $e');
      return 'PG';
    }
  }

  Future<Map<String, dynamic>> _getRelationshipMetrics(String matchId) async {
    final response = await _supabase
        .from('matches')
        .select('matched_at')
        .eq('id', matchId)
        .maybeSingle();

    final messageCount = await _supabase
        .from('messages')
        .select('id')
        .eq('match_id', matchId)
        .count();

    final matchedAt = response?['matched_at'] != null 
        ? DateTime.parse(response!['matched_at'])
        : DateTime.now();

    return {
      'message_count': messageCount.count,
      'days_matched': DateTime.now().difference(matchedAt).inDays,
    };
  }

  String _getDefaultHeatForGame(String gameType) {
    // Conservative defaults for new users
    switch (gameType) {
      case 'down_to_clown':
        return 'PG-13';
      case 'ice_breakers':
        return 'PG';
      case 'velvet_rope':
        return 'PG-13';
      case 'path_of_pleasure':
        return 'PG-13';
      case 'lane_of_lust':
        return 'R';
      case 'drama_sutra':
        return 'R';
      default:
        return 'PG';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE TIMING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get best time to message a specific match
  Future<MessageTimingSuggestion> getBestMessageTime(String matchId) async {
    try {
      // Get match's activity patterns
      final matchActivity = await _getMatchActivityPatterns(matchId);
      
      // Get user's own patterns
      await _ensureRefreshed();
      
      // Find overlapping active hours
      final overlappingHours = _findOverlappingHours(
        _activeHours,
        matchActivity['active_hours'] ?? [],
      );

      if (overlappingHours.isEmpty) {
        // No overlap - suggest match's most active time
        final bestHour = matchActivity['best_hour'] ?? 19; // Default to 7 PM
        return MessageTimingSuggestion(
          suggestedHour: bestHour,
          confidence: 0.5,
          reason: 'Based on their activity',
        );
      }

      // Prefer evening hours if available
      final preferredHour = overlappingHours.firstWhere(
        (h) => h >= 17 && h <= 22,
        orElse: () => overlappingHours.first,
      );

      return MessageTimingSuggestion(
        suggestedHour: preferredHour,
        confidence: 0.8,
        reason: 'When you\'re both usually active',
      );
    } catch (e) {
      debugPrint('SmartDefaults: Failed to get message time - $e');
      return MessageTimingSuggestion(
        suggestedHour: 19,
        confidence: 0.3,
        reason: 'Evening is usually good',
      );
    }
  }

  /// Check if now is a good time to message
  Future<bool> isGoodTimeToMessage(String matchId) async {
    final suggestion = await getBestMessageTime(matchId);
    final currentHour = DateTime.now().hour;
    
    // Within 2 hours of suggested time
    return (currentHour - suggestion.suggestedHour).abs() <= 2;
  }

  Future<Map<String, dynamic>> _getMatchActivityPatterns(String matchId) async {
    // Get the other user's ID
    final match = await _supabase
        .from('matches')
        .select('user1_id, user2_id')
        .eq('id', matchId)
        .maybeSingle();

    if (match == null) return {};

    final otherUserId = match['user1_id'] == _userId 
        ? match['user2_id'] 
        : match['user1_id'];

    // Get their preferences
    final prefs = await _supabase
        .from('ai_user_preferences')
        .select('active_hours')
        .eq('user_id', otherUserId)
        .maybeSingle();

    if (prefs == null) return {};

    final hours = List<int>.from(prefs['active_hours'] ?? []);
    return {
      'active_hours': hours,
      'best_hour': hours.isNotEmpty ? hours.first : 19,
    };
  }

  List<int> _findOverlappingHours(List<int> hours1, List<int> hours2) {
    return hours1.where((h) => hours2.contains(h)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get suggested interests based on similar users
  Future<List<String>> getSuggestedInterests() async {
    if (_userId == null) return [];

    try {
      // Get popular interests from users with similar demographics
      final response = await _supabase.rpc('get_popular_interests', params: {
        'p_limit': 10,
      }).catchError((_) => <dynamic>[]);

      return List<String>.from(response ?? []);
    } catch (e) {
      debugPrint('SmartDefaults: Failed to get interests - $e');
      return [];
    }
  }

  /// Get profile completion suggestions
  Future<List<ProfileSuggestion>> getProfileSuggestions() async {
    if (_userId == null) return [];

    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', _userId!)
          .maybeSingle();

      if (profile == null) return [];

      final suggestions = <ProfileSuggestion>[];

      // Check for missing/weak fields
      if ((profile['bio'] as String?)?.isEmpty ?? true) {
        suggestions.add(ProfileSuggestion(
          field: 'bio',
          message: 'Add a bio to get 3x more matches',
          priority: 1,
        ));
      } else if ((profile['bio'] as String).length < 50) {
        suggestions.add(ProfileSuggestion(
          field: 'bio',
          message: 'Profiles with longer bios get more messages',
          priority: 2,
        ));
      }

      final photos = profile['photos'] as List? ?? [];
      if (photos.isEmpty) {
        suggestions.add(ProfileSuggestion(
          field: 'photos',
          message: 'Add photos to start matching',
          priority: 1,
        ));
      } else if (photos.length < 3) {
        suggestions.add(ProfileSuggestion(
          field: 'photos',
          message: 'Profiles with 3+ photos get 2x more likes',
          priority: 2,
        ));
      }

      if ((profile['interests'] as List?)?.isEmpty ?? true) {
        suggestions.add(ProfileSuggestion(
          field: 'interests',
          message: 'Add interests to find better matches',
          priority: 2,
        ));
      }

      return suggestions..sort((a, b) => a.priority.compareTo(b.priority));
    } catch (e) {
      debugPrint('SmartDefaults: Failed to get suggestions - $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Suggest a game based on relationship stage and history
  Future<GameSuggestion> suggestGame({
    required String matchId,
    List<String>? recentlyPlayed,
  }) async {
    final metrics = await _getRelationshipMetrics(matchId);
    final played = recentlyPlayed ?? [];

    // Early stage - focus on getting to know each other
    if (metrics['message_count'] < 20) {
      if (!played.contains('ice_breakers')) {
        return GameSuggestion(
          gameType: 'ice_breakers',
          reason: 'Great for getting to know each other',
          suggestedHeat: 'PG',
        );
      }
      return GameSuggestion(
        gameType: 'down_to_clown',
        reason: 'Fun and lighthearted',
        suggestedHeat: 'PG',
      );
    }

    // Building connection
    if (metrics['message_count'] < 100) {
      if (!played.contains('velvet_rope')) {
        return GameSuggestion(
          gameType: 'velvet_rope',
          reason: 'Share or Dare to learn more',
          suggestedHeat: 'PG-13',
        );
      }
      return GameSuggestion(
        gameType: 'path_of_pleasure',
        reason: 'Build deeper connection',
        suggestedHeat: 'PG-13',
      );
    }

    // Established relationship
    final suggestedHeat = await getSuggestedHeatForCouple(
      matchId: matchId,
      gameType: 'drama_sutra',
    );

    if (!played.contains('drama_sutra')) {
      return GameSuggestion(
        gameType: 'drama_sutra',
        reason: 'For couples ready to explore',
        suggestedHeat: suggestedHeat,
      );
    }

    return GameSuggestion(
      gameType: 'lane_of_lust',
      reason: 'Turn up the heat',
      suggestedHeat: suggestedHeat,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFRESH
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _ensureRefreshed() async {
    if (_lastRefresh != null && 
        DateTime.now().difference(_lastRefresh!) < _refreshInterval) {
      return;
    }

    await refresh();
  }

  /// Refresh cached defaults from database
  Future<void> refresh() async {
    if (_userId == null) return;

    try {
      // Get user preferences
      final prefs = await _supabase
          .from('ai_user_preferences')
          .select()
          .eq('user_id', _userId!)
          .maybeSingle();

      if (prefs != null) {
        _activeHours = List<int>.from(prefs['active_hours'] ?? []);
        _heatLevelDefaults = Map<String, String>.from(
          prefs['preferred_heat_levels'] ?? {},
        );
        _userPatterns = prefs;
      }

      _lastRefresh = DateTime.now();
      debugPrint('SmartDefaults: Refreshed user defaults');
    } catch (e) {
      debugPrint('SmartDefaults: Refresh failed - $e');
    }
  }

  /// Clear cached data
  void clear() {
    _heatLevelDefaults.clear();
    _activeHours.clear();
    _userPatterns.clear();
    _lastRefresh = null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class MessageTimingSuggestion {
  final int suggestedHour;
  final double confidence;
  final String reason;

  MessageTimingSuggestion({
    required this.suggestedHour,
    required this.confidence,
    required this.reason,
  });

  String get formattedTime {
    final hour = suggestedHour % 12 == 0 ? 12 : suggestedHour % 12;
    final period = suggestedHour >= 12 ? 'PM' : 'AM';
    return '$hour $period';
  }
}

class ProfileSuggestion {
  final String field;
  final String message;
  final int priority;

  ProfileSuggestion({
    required this.field,
    required this.message,
    required this.priority,
  });
}

class GameSuggestion {
  final String gameType;
  final String reason;
  final String suggestedHeat;

  GameSuggestion({
    required this.gameType,
    required this.reason,
    required this.suggestedHeat,
  });
}
