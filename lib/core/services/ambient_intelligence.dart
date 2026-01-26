import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// AMBIENT INTELLIGENCE - App That Learns and Simplifies Itself
/// ════════════════════════════════════════════════════════════════════════════
///
/// The magic: App feels simpler the more you use it
/// - Learns which features you actually use
/// - Surfaces the right thing at the right time
/// - Hides clutter you don't need
/// - Predicts what you want before you ask
///
/// User perception: "This app just gets me"

class AmbientIntelligence {
  AmbientIntelligence._();
  static AmbientIntelligence? _instance;
  static AmbientIntelligence get instance =>
      _instance ??= AmbientIntelligence._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Local cache of user patterns
  UserPatterns? _cachedPatterns;
  DateTime? _lastPatternRefresh;
  final Duration _patternRefreshInterval = const Duration(hours: 1);

  // Event buffer for batch syncing
  final List<UsageEvent> _eventBuffer = [];
  Timer? _syncTimer;
  final int _maxBufferSize = 50;

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // FEATURE VISIBILITY DECISIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Should this feature be prominently shown?
  Future<FeatureVisibility> getFeatureVisibility(String featureId) async {
    final patterns = await _getUserPatterns();
    if (patterns == null) return FeatureVisibility.normal;

    final usage = patterns.featureUsage[featureId] ?? 0;
    final lastUsed = patterns.lastUsed[featureId];
    final daysSinceUse =
        lastUsed != null ? DateTime.now().difference(lastUsed).inDays : 999;

    // Frequently used features stay prominent
    if (usage > 10 && daysSinceUse < 7) {
      return FeatureVisibility.prominent;
    }

    // Never used after 2 weeks = hide
    if (usage == 0 && patterns.daysActive > 14) {
      return FeatureVisibility.hidden;
    }

    // Rarely used = minimize
    if (usage < 3 && patterns.daysActive > 7) {
      return FeatureVisibility.minimized;
    }

    return FeatureVisibility.normal;
  }

  /// Get list of features to show/hide for this user
  Future<Map<String, FeatureVisibility>> getAllFeatureVisibility() async {
    final patterns = await _getUserPatterns();
    if (patterns == null) return {};

    final visibility = <String, FeatureVisibility>{};

    for (final featureId in _allFeatures) {
      visibility[featureId] = await getFeatureVisibility(featureId);
    }

    return visibility;
  }

  static const _allFeatures = [
    'games',
    'date_planner',
    'message_coach',
    'profile_coach',
    'conversation_starters',
    'match_insights',
    'calendar',
    'group_chat',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTEXTUAL SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// What should we suggest right now based on context?
  Future<List<ContextualSuggestion>> getSuggestions({
    String? currentScreen,
    String? currentMatchId,
    TimeOfDay? timeOfDay,
  }) async {
    final patterns = await _getUserPatterns();
    if (patterns == null) return [];

    final suggestions = <ContextualSuggestion>[];
    final hour = timeOfDay?.hour ?? DateTime.now().hour;

    // Evening suggestions
    if (hour >= 18 && hour <= 22) {
      if (patterns.featureUsage['games'] != null &&
          patterns.featureUsage['games']! > 3) {
        suggestions.add(
          ContextualSuggestion(
            type: SuggestionType.playGame,
            reason: 'Perfect time for a game',
            priority: 0.8,
          ),
        );
      }
    }

    // Weekend suggestions
    if (_isWeekend()) {
      if (patterns.featureUsage['date_planner'] != null) {
        suggestions.add(
          ContextualSuggestion(
            type: SuggestionType.planDate,
            reason: 'Weekend plans?',
            priority: 0.9,
          ),
        );
      }
    }

    // Match-specific suggestions
    if (currentMatchId != null) {
      final matchContext = await _getMatchContext(currentMatchId);

      if (matchContext != null) {
        // Haven't messaged in a while
        if (matchContext.daysSinceLastMessage > 2) {
          suggestions.add(
            ContextualSuggestion(
              type: SuggestionType.reachOut,
              reason: "Haven't talked in a bit",
              priority: 0.85,
              matchId: currentMatchId,
            ),
          );
        }

        // High engagement, suggest escalation
        if (matchContext.messageCount > 50 && !matchContext.hasPlannedDate) {
          suggestions.add(
            ContextualSuggestion(
              type: SuggestionType.suggestDate,
              reason: 'Time to meet up?',
              priority: 0.9,
              matchId: currentMatchId,
            ),
          );
        }
      }
    }

    // Sort by priority
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));

    return suggestions.take(3).toList();
  }

  bool _isWeekend() {
    final day = DateTime.now().weekday;
    return day == DateTime.saturday || day == DateTime.sunday;
  }

  Future<MatchContext?> _getMatchContext(String matchId) async {
    if (_userId == null) return null;

    try {
      // Get last message
      final lastMessage = await _supabase
          .from('messages')
          .select('created_at')
          .eq('match_id', matchId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Get message count
      final countResult = await _supabase
          .from('messages')
          .select()
          .eq('match_id', matchId)
          .count(CountOption.exact);

      // Check for planned dates
      bool hasPlannedDate = false;
      try {
        final dates = await _supabase
            .from('match_dates')
            .select('id')
            .eq('match_id', matchId)
            .limit(1);
        hasPlannedDate = (dates as List).isNotEmpty;
      } catch (_) {}

      final lastMessageAt = lastMessage != null
          ? DateTime.parse(lastMessage['created_at'])
          : null;

      return MatchContext(
        matchId: matchId,
        messageCount: countResult.count ?? 0,
        daysSinceLastMessage: lastMessageAt != null
            ? DateTime.now().difference(lastMessageAt).inDays
            : 999,
        hasPlannedDate: hasPlannedDate,
      );
    } catch (e) {
      debugPrint('AmbientIntel: Failed to get match context - $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SMART DEFAULTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get personalized default for a setting
  Future<T> getSmartDefault<T>(String settingKey, T fallback) async {
    final patterns = await _getUserPatterns();
    if (patterns == null) return fallback;

    // Check if user has a pattern for this setting
    final learned = patterns.learnedDefaults[settingKey];
    if (learned != null && learned is T) {
      return learned;
    }

    return fallback;
  }

  /// Common smart defaults
  Future<int> getPreferredHeatLevel() async =>
      getSmartDefault<int>('preferred_heat_level', 2);

  Future<String> getPreferredGameType() async =>
      getSmartDefault<String>('preferred_game_type', 'truthOrDare');

  Future<bool> getShouldShowMessageCoach() async {
    final patterns = await _getUserPatterns();
    if (patterns == null) return true;

    // If they've dismissed it 3+ times, don't show
    final dismissals = patterns.featureUsage['message_coach_dismissed'] ?? 0;
    return dismissals < 3;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI PERSONALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get personalized quick actions for home screen
  Future<List<QuickAction>> getPersonalizedQuickActions() async {
    final patterns = await _getUserPatterns();
    if (patterns == null) return _defaultQuickActions;

    final actions = <QuickAction>[];

    // Most used features become quick actions
    final sortedFeatures = patterns.featureUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedFeatures.take(4)) {
      final action = _featureToQuickAction(entry.key);
      if (action != null) {
        actions.add(action);
      }
    }

    // Fill remaining with defaults
    while (actions.length < 4) {
      final defaultAction = _defaultQuickActions[actions.length];
      if (!actions.any((a) => a.id == defaultAction.id)) {
        actions.add(defaultAction);
      }
    }

    return actions;
  }

  QuickAction? _featureToQuickAction(String featureId) {
    switch (featureId) {
      case 'games':
        return const QuickAction(id: 'games', label: 'Play', icon: '🎮');
      case 'date_planner':
        return const QuickAction(
            id: 'date_planner', label: 'Plan Date', icon: '📅');
      case 'conversation_starters':
        return const QuickAction(
            id: 'starters', label: 'Start Chat', icon: '💬');
      case 'profile_coach':
        return const QuickAction(id: 'profile', label: 'Profile', icon: '✨');
      default:
        return null;
    }
  }

  static const _defaultQuickActions = [
    QuickAction(id: 'matches', label: 'Matches', icon: '💕'),
    QuickAction(id: 'discover', label: 'Discover', icon: '🔍'),
    QuickAction(id: 'games', label: 'Play', icon: '🎮'),
    QuickAction(id: 'messages', label: 'Messages', icon: '💬'),
  ];

  /// Get tab order based on usage
  Future<List<String>> getPersonalizedTabOrder() async {
    final patterns = await _getUserPatterns();
    if (patterns == null) return _defaultTabOrder;

    final tabUsage = <String, int>{};

    for (final tab in _defaultTabOrder) {
      tabUsage[tab] = patterns.featureUsage['tab_$tab'] ?? 0;
    }

    final sorted = tabUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => e.key).toList();
  }

  static const _defaultTabOrder = [
    'home',
    'discover',
    'matches',
    'games',
    'profile'
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT TRACKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track a feature usage event
  void trackFeatureUsage(String featureId, {Map<String, dynamic>? metadata}) {
    _eventBuffer.add(
      UsageEvent(
        featureId: featureId,
        timestamp: DateTime.now(),
        metadata: metadata,
      ),
    );

    // Update local cache immediately
    _updateLocalPatterns(featureId);

    // Schedule sync if buffer is getting full
    if (_eventBuffer.length >= _maxBufferSize) {
      _syncEvents();
    } else {
      _scheduleSyncIfNeeded();
    }
  }

  /// Track setting change (to learn preferences)
  void trackSettingChange(String settingKey, dynamic value) {
    _eventBuffer.add(
      UsageEvent(
        featureId: 'setting_change',
        timestamp: DateTime.now(),
        metadata: {'key': settingKey, 'value': value},
      ),
    );

    // Update learned default immediately
    if (_cachedPatterns != null) {
      _cachedPatterns!.learnedDefaults[settingKey] = value;
    }

    _scheduleSyncIfNeeded();
  }

  /// Track feature dismissal
  void trackDismissal(String featureId) {
    trackFeatureUsage('${featureId}_dismissed');
  }

  void _updateLocalPatterns(String featureId) {
    if (_cachedPatterns == null) return;

    _cachedPatterns!.featureUsage[featureId] =
        (_cachedPatterns!.featureUsage[featureId] ?? 0) + 1;
    _cachedPatterns!.lastUsed[featureId] = DateTime.now();
  }

  void _scheduleSyncIfNeeded() {
    if (_syncTimer != null) return;

    _syncTimer = Timer(const Duration(minutes: 5), () {
      _syncEvents();
      _syncTimer = null;
    });
  }

  Future<void> _syncEvents() async {
    if (_eventBuffer.isEmpty || _userId == null) return;

    final eventsToSync = List<UsageEvent>.from(_eventBuffer);
    _eventBuffer.clear();

    try {
      // Batch insert events
      final rows = eventsToSync
          .map(
            (e) => {
              'user_id': _userId,
              'feature_id': e.featureId,
              'timestamp': e.timestamp.toIso8601String(),
              'metadata': e.metadata,
            },
          )
          .toList();

      await _supabase.from('usage_events').insert(rows);
    } catch (e) {
      debugPrint('AmbientIntel: Failed to sync events - $e');
      // Re-add failed events to buffer
      _eventBuffer.addAll(eventsToSync);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATTERN LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<UserPatterns?> _getUserPatterns() async {
    if (_userId == null) return null;

    // Return cached if fresh
    if (_cachedPatterns != null &&
        _lastPatternRefresh != null &&
        DateTime.now().difference(_lastPatternRefresh!) <
            _patternRefreshInterval) {
      return _cachedPatterns;
    }

    try {
      final data = await _supabase
          .from('user_patterns')
          .select()
          .eq('user_id', _userId!)
          .maybeSingle();

      if (data == null) {
        // Create default patterns for new user
        _cachedPatterns = UserPatterns(
          userId: _userId!,
          featureUsage: {},
          lastUsed: {},
          learnedDefaults: {},
          daysActive: 0,
        );
      } else {
        _cachedPatterns = UserPatterns.fromJson(data);
      }

      _lastPatternRefresh = DateTime.now();
      return _cachedPatterns;
    } catch (e) {
      debugPrint('AmbientIntel: Failed to load patterns - $e');
      return null;
    }
  }

  /// Force refresh patterns from server
  Future<void> refreshPatterns() async {
    _lastPatternRefresh = null;
    await _getUserPatterns();
  }

  /// Save current patterns to server
  Future<void> savePatterns() async {
    if (_cachedPatterns == null || _userId == null) return;

    try {
      await _supabase.from('user_patterns').upsert({
        'user_id': _userId,
        'feature_usage': _cachedPatterns!.featureUsage,
        'last_used': _cachedPatterns!.lastUsed.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
        'learned_defaults': _cachedPatterns!.learnedDefaults,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('AmbientIntel: Failed to save patterns - $e');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncEvents(); // Final sync
    savePatterns();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum FeatureVisibility {
  prominent, // Show prominently, maybe with animation
  normal, // Standard visibility
  minimized, // Show but smaller/collapsed
  hidden, // Don't show at all
}

enum SuggestionType {
  playGame,
  planDate,
  reachOut,
  suggestDate,
  improveProfile,
  checkMatches,
}

class ContextualSuggestion {
  ContextualSuggestion({
    required this.type,
    required this.reason,
    required this.priority,
    this.matchId,
  });
  final SuggestionType type;
  final String reason;
  final double priority;
  final String? matchId;

  String get actionLabel {
    switch (type) {
      case SuggestionType.playGame:
        return 'Play a Game';
      case SuggestionType.planDate:
        return 'Plan a Date';
      case SuggestionType.reachOut:
        return 'Say Hi';
      case SuggestionType.suggestDate:
        return 'Suggest Meeting';
      case SuggestionType.improveProfile:
        return 'Boost Profile';
      case SuggestionType.checkMatches:
        return 'See Matches';
    }
  }

  String get emoji {
    switch (type) {
      case SuggestionType.playGame:
        return '🎮';
      case SuggestionType.planDate:
        return '📅';
      case SuggestionType.reachOut:
        return '👋';
      case SuggestionType.suggestDate:
        return '☕';
      case SuggestionType.improveProfile:
        return '✨';
      case SuggestionType.checkMatches:
        return '💕';
    }
  }
}

class QuickAction {
  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
  });
  final String id;
  final String label;
  final String icon;
}

class TimeOfDay {
  TimeOfDay({required this.hour, required this.minute});
  final int hour;
  final int minute;
}

class MatchContext {
  MatchContext({
    required this.matchId,
    required this.messageCount,
    required this.daysSinceLastMessage,
    required this.hasPlannedDate,
  });
  final String matchId;
  final int messageCount;
  final int daysSinceLastMessage;
  final bool hasPlannedDate;
}

class UsageEvent {
  UsageEvent({
    required this.featureId,
    required this.timestamp,
    this.metadata,
  });
  final String featureId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}

class UserPatterns {
  UserPatterns({
    required this.userId,
    required this.featureUsage,
    required this.lastUsed,
    required this.learnedDefaults,
    required this.daysActive,
  });

  factory UserPatterns.fromJson(Map<String, dynamic> json) {
    final lastUsedMap = <String, DateTime>{};
    if (json['last_used'] != null) {
      (json['last_used'] as Map<String, dynamic>).forEach((key, value) {
        lastUsedMap[key] = DateTime.parse(value as String);
      });
    }

    return UserPatterns(
      userId: json['user_id'] as String,
      featureUsage: Map<String, int>.from(json['feature_usage'] ?? {}),
      lastUsed: lastUsedMap,
      learnedDefaults:
          Map<String, dynamic>.from(json['learned_defaults'] ?? {}),
      daysActive: json['days_active'] as int? ?? 0,
    );
  }
  final String userId;
  final Map<String, int> featureUsage;
  final Map<String, DateTime> lastUsed;
  final Map<String, dynamic> learnedDefaults;
  final int daysActive;
}
