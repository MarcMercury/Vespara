import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PREFETCH SERVICE - Smart Data Preloading
/// ════════════════════════════════════════════════════════════════════════════
///
/// Invisibly preloads data users are likely to need next, making the app
/// feel instant. No user interaction required - it just works.

class PrefetchService {
  static PrefetchService? _instance;
  static PrefetchService get instance => _instance ??= PrefetchService._();

  PrefetchService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Caches
  final Map<String, _CachedData> _profileCache = {};
  final Map<String, _CachedData> _matchCache = {};
  final Map<String, _CachedData> _gameContentCache = {};
  final Map<String, _CachedData> _conversationCache = {};

  // Cache settings
  final Duration _profileExpiry = const Duration(minutes: 15);
  final Duration _matchExpiry = const Duration(minutes: 5);
  final Duration _gameContentExpiry = const Duration(hours: 1);
  final Duration _conversationExpiry = const Duration(minutes: 2);

  // Prefetch queue
  final List<_PrefetchTask> _queue = [];
  bool _isProcessing = false;
  Timer? _idleTimer;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE PREFETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Prefetch profiles user is likely to view
  Future<void> prefetchNearbyProfiles({
    required String userId,
    int count = 10,
  }) async {
    _enqueue(_PrefetchTask(
      id: 'nearby_profiles_$userId',
      priority: PrefetchPriority.high,
      execute: () async {
        // Get user's next likely matches
        final response = await _supabase
            .from('profiles')
            .select('id, display_name, photos, bio, age')
            .neq('id', userId)
            .limit(count);

        for (final profile in response as List) {
          final id = profile['id'] as String;
          _profileCache[id] = _CachedData(
            data: profile,
            expiresAt: DateTime.now().add(_profileExpiry),
          );
        }

        debugPrint('PrefetchService: Cached ${(response as List).length} profiles');
      },
    ));
  }

  /// Prefetch a specific profile (called when user hovers/approaches)
  Future<void> prefetchProfile(String profileId) async {
    if (_profileCache.containsKey(profileId)) return;

    _enqueue(_PrefetchTask(
      id: 'profile_$profileId',
      priority: PrefetchPriority.high,
      execute: () async {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', profileId)
            .maybeSingle();

        if (response != null) {
          _profileCache[profileId] = _CachedData(
            data: response,
            expiresAt: DateTime.now().add(_profileExpiry),
          );
        }
      },
    ));
  }

  /// Get cached profile or fetch if not available
  Future<Map<String, dynamic>?> getProfile(String profileId) async {
    final cached = _profileCache[profileId];
    if (cached != null && !cached.isExpired) {
      return cached.data as Map<String, dynamic>;
    }

    // Fetch and cache
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', profileId)
        .maybeSingle();

    if (response != null) {
      _profileCache[profileId] = _CachedData(
        data: response,
        expiresAt: DateTime.now().add(_profileExpiry),
      );
    }

    return response;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATCH PREFETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Prefetch user's matches and recent conversations
  Future<void> prefetchMatches(String userId) async {
    _enqueue(_PrefetchTask(
      id: 'matches_$userId',
      priority: PrefetchPriority.high,
      execute: () async {
        final response = await _supabase
            .from('matches')
            .select('''
              id,
              user1_id,
              user2_id,
              matched_at,
              user1:profiles!matches_user1_id_fkey(id, display_name, photos),
              user2:profiles!matches_user2_id_fkey(id, display_name, photos)
            ''')
            .or('user1_id.eq.$userId,user2_id.eq.$userId')
            .order('matched_at', ascending: false)
            .limit(20);

        _matchCache[userId] = _CachedData(
          data: response,
          expiresAt: DateTime.now().add(_matchExpiry),
        );

        debugPrint('PrefetchService: Cached ${(response as List).length} matches');
      },
    ));
  }

  /// Get cached matches
  List<Map<String, dynamic>>? getCachedMatches(String userId) {
    final cached = _matchCache[userId];
    if (cached != null && !cached.isExpired) {
      return List<Map<String, dynamic>>.from(cached.data as List);
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME CONTENT PREFETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Prefetch game cards for all heat levels
  Future<void> prefetchGameContent({
    required String gameType,
    List<String>? heatLevels,
  }) async {
    final levels = heatLevels ?? ['PG', 'PG-13', 'R', 'X'];

    for (final level in levels) {
      final cacheKey = '${gameType}_$level';
      if (_gameContentCache.containsKey(cacheKey)) continue;

      _enqueue(_PrefetchTask(
        id: 'game_$cacheKey',
        priority: PrefetchPriority.medium,
        execute: () async {
          final tableName = _getGameTable(gameType);
          if (tableName == null) return;

          final response = await _supabase
              .from(tableName)
              .select()
              .eq('heat_level', level)
              .limit(50);

          _gameContentCache[cacheKey] = _CachedData(
            data: response,
            expiresAt: DateTime.now().add(_gameContentExpiry),
          );

          debugPrint('PrefetchService: Cached ${(response as List).length} $gameType cards ($level)');
        },
      ));
    }
  }

  /// Get cached game content
  List<Map<String, dynamic>>? getCachedGameContent(String gameType, String heatLevel) {
    final cacheKey = '${gameType}_$heatLevel';
    final cached = _gameContentCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return List<Map<String, dynamic>>.from(cached.data as List);
    }
    return null;
  }

  /// Prefetch all TAG games content
  Future<void> prefetchAllGames() async {
    final gameTypes = [
      'down_to_clown',
      'ice_breakers',
      'share_or_dare',
      'path_of_pleasure',
      'lane_of_lust',
      'drama_sutra',
    ];

    for (final game in gameTypes) {
      await prefetchGameContent(gameType: game);
    }
  }

  String? _getGameTable(String gameType) {
    switch (gameType) {
      case 'down_to_clown':
        return 'dtc_prompts';
      case 'ice_breakers':
        return 'ice_breaker_questions';
      case 'share_or_dare':
        return 'share_or_dare_cards';
      case 'path_of_pleasure':
        return 'pop_prompts';
      case 'lane_of_lust':
        return 'lol_cards';
      case 'drama_sutra':
        return 'drama_sutra_prompts';
      default:
        return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATION PREFETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Prefetch recent messages for a conversation
  Future<void> prefetchConversation(String matchId) async {
    _enqueue(_PrefetchTask(
      id: 'conversation_$matchId',
      priority: PrefetchPriority.high,
      execute: () async {
        final response = await _supabase
            .from('messages')
            .select()
            .eq('match_id', matchId)
            .order('created_at', ascending: false)
            .limit(50);

        _conversationCache[matchId] = _CachedData(
          data: response,
          expiresAt: DateTime.now().add(_conversationExpiry),
        );
      },
    ));
  }

  /// Get cached conversation
  List<Map<String, dynamic>>? getCachedConversation(String matchId) {
    final cached = _conversationCache[matchId];
    if (cached != null && !cached.isExpired) {
      return List<Map<String, dynamic>>.from(cached.data as List);
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTIVE PREFETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Called when user opens app - prefetch likely next actions
  Future<void> onAppOpen(String userId) async {
    debugPrint('PrefetchService: App opened, starting predictive prefetch');

    // Prefetch in priority order
    await prefetchMatches(userId);
    await prefetchNearbyProfiles(userId: userId);
    await prefetchAllGames();
  }

  /// Called when user views a match - prefetch conversation and profile
  Future<void> onMatchViewed(String matchId, String otherUserId) async {
    await prefetchConversation(matchId);
    await prefetchProfile(otherUserId);
  }

  /// Called when user enters games section
  Future<void> onGamesEntered() async {
    await prefetchAllGames();
  }

  /// Called when user starts a specific game
  Future<void> onGameStarted(String gameType, String heatLevel) async {
    await prefetchGameContent(gameType: gameType, heatLevels: [heatLevel]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUEUE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  void _enqueue(_PrefetchTask task) {
    // Remove duplicate tasks
    _queue.removeWhere((t) => t.id == task.id);
    _queue.add(task);

    // Sort by priority
    _queue.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);

      try {
        await task.execute();
      } catch (e) {
        debugPrint('PrefetchService: Task ${task.id} failed - $e');
      }

      // Small delay to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _isProcessing = false;
  }

  /// Process low-priority tasks during idle time
  void onIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 2), () {
      _processQueue();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Clear all caches
  void clearAll() {
    _profileCache.clear();
    _matchCache.clear();
    _gameContentCache.clear();
    _conversationCache.clear();
    debugPrint('PrefetchService: All caches cleared');
  }

  /// Clear expired entries
  void cleanup() {
    final now = DateTime.now();

    _profileCache.removeWhere((_, v) => v.expiresAt.isBefore(now));
    _matchCache.removeWhere((_, v) => v.expiresAt.isBefore(now));
    _gameContentCache.removeWhere((_, v) => v.expiresAt.isBefore(now));
    _conversationCache.removeWhere((_, v) => v.expiresAt.isBefore(now));

    debugPrint('PrefetchService: Expired entries cleaned up');
  }

  /// Get cache statistics
  Map<String, int> get stats => {
        'profiles': _profileCache.length,
        'matches': _matchCache.length,
        'gameContent': _gameContentCache.length,
        'conversations': _conversationCache.length,
        'pendingTasks': _queue.length,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

class _CachedData {
  final dynamic data;
  final DateTime expiresAt;

  _CachedData({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class _PrefetchTask {
  final String id;
  final PrefetchPriority priority;
  final Future<void> Function() execute;

  _PrefetchTask({
    required this.id,
    required this.priority,
    required this.execute,
  });
}

enum PrefetchPriority {
  high,
  medium,
  low,
}
