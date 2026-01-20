import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';
import 'prefetch_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// BACKGROUND PREGENERATION SERVICE
/// ════════════════════════════════════════════════════════════════════════════
///
/// Generates AI content during idle time so it's ready instantly when needed.
/// Runs silently in the background - users never wait for AI.

class BackgroundPregenerationService {
  static BackgroundPregenerationService? _instance;
  static BackgroundPregenerationService get instance =>
      _instance ??= BackgroundPregenerationService._();

  BackgroundPregenerationService._();

  final AIService _aiService = AIService.instance;
  final PrefetchService _prefetchService = PrefetchService.instance;

  // Pregenerated content caches
  final Map<String, List<String>> _iceBreakersCache = {};
  final Map<String, List<String>> _bioSuggestionsCache = {};
  final Map<String, List<String>> _conversationStartersCache = {};
  final Map<String, Map<String, dynamic>> _gameContentCache = {};

  // Generation state
  bool _isRunning = false;
  Timer? _idleTimer;
  Timer? _regenerationTimer;

  final Duration _idleThreshold = const Duration(seconds: 5);
  final Duration _regenerationInterval = const Duration(hours: 1);

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start background generation
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Initial generation
    _scheduleGeneration();

    // Periodic regeneration
    _regenerationTimer = Timer.periodic(_regenerationInterval, (_) {
      _scheduleGeneration();
    });

    debugPrint('BackgroundPregeneration: Started');
  }

  /// Stop background generation
  void stop() {
    _isRunning = false;
    _idleTimer?.cancel();
    _regenerationTimer?.cancel();
    debugPrint('BackgroundPregeneration: Stopped');
  }

  /// Called when user activity detected - pause generation
  void onUserActivity() {
    _idleTimer?.cancel();
  }

  /// Called when user goes idle - resume generation
  void onUserIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleThreshold, () {
      if (_isRunning) {
        _runGeneration();
      }
    });
  }

  void _scheduleGeneration() {
    // Wait for idle before generating
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleThreshold, () {
      if (_isRunning) {
        _runGeneration();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATION TASKS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _runGeneration() async {
    debugPrint('BackgroundPregeneration: Starting generation cycle');

    // Generate in priority order, with delays to avoid rate limits
    await _generateGenericIceBreakers();
    await Future.delayed(const Duration(milliseconds: 500));

    await _generateBioStarters();
    await Future.delayed(const Duration(milliseconds: 500));

    await _generateConversationTemplates();

    debugPrint('BackgroundPregeneration: Generation cycle complete');
  }

  /// Generate generic ice breakers for common scenarios
  Future<void> _generateGenericIceBreakers() async {
    final scenarios = [
      'first_date',
      'long_term',
      'casual',
      'adventurous',
      'intellectual',
    ];

    for (final scenario in scenarios) {
      if (_iceBreakersCache[scenario] != null &&
          _iceBreakersCache[scenario]!.length >= 5) {
        continue; // Already have enough
      }

      final result = await _aiService.chat(
        systemPrompt: '''Generate 5 unique conversation starters for a $scenario dating scenario.
Be creative, genuine, and engaging. Avoid clichés.
Return one starter per line, no numbering.''',
        prompt: 'Generate conversation starters for: $scenario',
        maxTokens: 200,
        useCache: false, // We want fresh content
      );

      result.fold(
        onSuccess: (response) {
          _iceBreakersCache[scenario] = response.content
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) => line.trim())
              .toList();
          debugPrint('BackgroundPregeneration: Generated ${_iceBreakersCache[scenario]!.length} ice breakers for $scenario');
        },
        onFailure: (error) {
          debugPrint('BackgroundPregeneration: Failed to generate ice breakers - $error');
        },
      );

      // Rate limit protection
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Generate bio improvement starters
  Future<void> _generateBioStarters() async {
    final styles = [
      'witty',
      'sincere',
      'adventurous',
      'intellectual',
      'playful',
    ];

    for (final style in styles) {
      if (_bioSuggestionsCache[style] != null &&
          _bioSuggestionsCache[style]!.length >= 3) {
        continue;
      }

      final result = await _aiService.chat(
        systemPrompt: '''Generate 3 bio template starters in a $style style.
These should be adaptable - the user will fill in specifics.
Use [brackets] for parts they should customize.
Keep each under 150 characters.
Return one per line.''',
        prompt: 'Generate $style bio starters',
        maxTokens: 200,
        useCache: false,
      );

      result.fold(
        onSuccess: (response) {
          _bioSuggestionsCache[style] = response.content
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) => line.trim())
              .toList();
          debugPrint('BackgroundPregeneration: Generated ${_bioSuggestionsCache[style]!.length} bio starters for $style');
        },
        onFailure: (error) {
          debugPrint('BackgroundPregeneration: Failed to generate bios - $error');
        },
      );

      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Generate conversation continuation templates
  Future<void> _generateConversationTemplates() async {
    final situations = [
      'conversation_dying',
      'after_long_pause',
      'want_to_meet',
      'shared_interest',
      'funny_moment',
    ];

    for (final situation in situations) {
      if (_conversationStartersCache[situation] != null &&
          _conversationStartersCache[situation]!.length >= 3) {
        continue;
      }

      final result = await _aiService.chat(
        systemPrompt: '''Generate 3 message templates for when: $situation
Be natural and casual. Use [brackets] for customizable parts.
Keep each under 100 characters.
Return one per line.''',
        prompt: 'Generate templates for: $situation',
        maxTokens: 150,
        useCache: false,
      );

      result.fold(
        onSuccess: (response) {
          _conversationStartersCache[situation] = response.content
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) => line.trim())
              .toList();
          debugPrint('BackgroundPregeneration: Generated ${_conversationStartersCache[situation]!.length} templates for $situation');
        },
        onFailure: (error) {
          debugPrint('BackgroundPregeneration: Failed to generate templates - $error');
        },
      );

      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT RETRIEVAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get a random ice breaker for a scenario
  String? getIceBreaker(String scenario) {
    final list = _iceBreakersCache[scenario];
    if (list == null || list.isEmpty) return null;

    final random = DateTime.now().millisecondsSinceEpoch % list.length;
    return list[random];
  }

  /// Get all ice breakers for a scenario
  List<String> getIceBreakers(String scenario) {
    return _iceBreakersCache[scenario] ?? [];
  }

  /// Get bio suggestions for a style
  List<String> getBioSuggestions(String style) {
    return _bioSuggestionsCache[style] ?? [];
  }

  /// Get conversation templates for a situation
  List<String> getConversationTemplates(String situation) {
    return _conversationStartersCache[situation] ?? [];
  }

  /// Check if content is available
  bool hasContent(ContentType type, String key) {
    switch (type) {
      case ContentType.iceBreaker:
        return (_iceBreakersCache[key]?.isNotEmpty ?? false);
      case ContentType.bio:
        return (_bioSuggestionsCache[key]?.isNotEmpty ?? false);
      case ContentType.conversation:
        return (_conversationStartersCache[key]?.isNotEmpty ?? false);
      case ContentType.game:
        return _gameContentCache.containsKey(key);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Clear all caches
  void clearAll() {
    _iceBreakersCache.clear();
    _bioSuggestionsCache.clear();
    _conversationStartersCache.clear();
    _gameContentCache.clear();
    debugPrint('BackgroundPregeneration: All caches cleared');
  }

  /// Get cache statistics
  Map<String, int> get stats => {
        'iceBreakers': _iceBreakersCache.values.fold(0, (sum, list) => sum + list.length),
        'bioSuggestions': _bioSuggestionsCache.values.fold(0, (sum, list) => sum + list.length),
        'conversationTemplates': _conversationStartersCache.values.fold(0, (sum, list) => sum + list.length),
        'gameContent': _gameContentCache.length,
      };
}

enum ContentType {
  iceBreaker,
  bio,
  conversation,
  game,
}
