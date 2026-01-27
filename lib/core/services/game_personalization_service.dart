import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GAME PERSONALIZATION SERVICE - Smart Game Content
/// ════════════════════════════════════════════════════════════════════════════
///
/// Makes games feel fresh and personal for each couple:
/// - Learns which prompts they enjoy
/// - Avoids repeating similar content
/// - Adjusts intensity based on engagement
/// - Remembers couple history across sessions

class GamePersonalizationService {
  GamePersonalizationService._();
  static GamePersonalizationService? _instance;
  static GamePersonalizationService get instance =>
      _instance ??= GamePersonalizationService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();

  // Session memory
  final Set<String> _shownPromptsThisSession = {};
  final Map<String, List<String>> _coupleHistory = {};
  final Map<String, double> _promptScores = {};

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSONALIZED PROMPT SELECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the next best prompt for a couple
  Future<PersonalizedPrompt?> getNextPrompt({
    required String gameType,
    required String heatLevel,
    String? coupleId,
    List<String>? excludeCategories,
  }) async {
    try {
      // Get available prompts
      final tableName = _getGameTable(gameType);
      if (tableName == null) return null;

      var query =
          _supabase.from(tableName).select().eq('heat_level', heatLevel);

      if (excludeCategories != null && excludeCategories.isNotEmpty) {
        for (final cat in excludeCategories) {
          query = query.neq('category', cat);
        }
      }

      final response = await query.limit(100);
      final prompts = response as List;

      if (prompts.isEmpty) return null;

      // Filter out recently shown prompts
      final available = prompts.where((p) {
        final id = p['id'].toString();
        return !_shownPromptsThisSession.contains(id);
      }).toList();

      // If all shown, reset session memory for this game
      final effectivePrompts = available.isEmpty ? prompts : available;

      // Score and select
      final scored = await _scorePrompts(effectivePrompts, gameType, coupleId);
      final selected = _selectWeighted(scored);

      if (selected == null) return null;

      // Mark as shown
      _shownPromptsThisSession.add(selected['id'].toString());
      _recordCoupleHistory(coupleId, selected['id'].toString());

      return PersonalizedPrompt(
        id: selected['id'].toString(),
        content: selected['prompt'] ??
            selected['content'] ??
            selected['question'] ??
            '',
        category: selected['category'] as String?,
        heatLevel: heatLevel,
        personalizedReason: _getPersonalizationReason(selected),
      );
    } catch (e) {
      debugPrint('GamePersonalization: Failed to get prompt - $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _scorePrompts(
    List<dynamic> prompts,
    String gameType,
    String? coupleId,
  ) async {
    // Load effectiveness scores
    await _loadPromptScores(gameType);

    // Load couple history
    final history = await _getCoupleHistory(coupleId);

    final scored = <Map<String, dynamic>>[];

    for (final prompt in prompts) {
      final id = prompt['id'].toString();

      // Base score from effectiveness
      double score = _promptScores[id] ?? 0.5;

      // Penalty for recently used with this couple
      if (history.contains(id)) {
        score *= 0.3; // 70% penalty
      }

      // Boost for variety (different category than recent)
      final category = prompt['category'] as String?;
      if (category != null && !_recentCategories.contains(category)) {
        score *= 1.2;
      }

      scored.add({
        ...prompt as Map<String, dynamic>,
        '_score': score,
      });
    }

    return scored;
  }

  final Set<String> _recentCategories = {};

  Map<String, dynamic>? _selectWeighted(List<Map<String, dynamic>> scored) {
    if (scored.isEmpty) return null;

    // Sort by score
    scored.sort(
        (a, b) => (b['_score'] as double).compareTo(a['_score'] as double),);

    // Weighted random from top 10
    final top = scored.take(10).toList();
    final totalScore =
        top.fold<double>(0, (sum, p) => sum + (p['_score'] as double));

    if (totalScore == 0) return top.first;

    double random = _random.nextDouble() * totalScore;
    for (final prompt in top) {
      random -= prompt['_score'] as double;
      if (random <= 0) {
        // Track category for variety
        final cat = prompt['category'] as String?;
        if (cat != null) {
          _recentCategories.add(cat);
          if (_recentCategories.length > 3) {
            _recentCategories.remove(_recentCategories.first);
          }
        }
        return prompt;
      }
    }

    return top.first;
  }

  Future<void> _loadPromptScores(String gameType) async {
    if (_promptScores.isNotEmpty) return;

    try {
      final response = await _supabase
          .from('prompt_effectiveness')
          .select('prompt_id, effectiveness_score')
          .eq('game_type', gameType);

      for (final row in response as List) {
        _promptScores[row['prompt_id'].toString()] =
            (row['effectiveness_score'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('GamePersonalization: Failed to load scores - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLE HISTORY
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<String>> _getCoupleHistory(String? coupleId) async {
    if (coupleId == null) return [];

    // Check cache
    if (_coupleHistory.containsKey(coupleId)) {
      return _coupleHistory[coupleId]!;
    }

    try {
      final response = await _supabase
          .from('couple_game_history')
          .select('prompt_ids')
          .eq('couple_id', coupleId)
          .maybeSingle();

      final history = List<String>.from(response?['prompt_ids'] ?? []);
      _coupleHistory[coupleId] = history;
      return history;
    } catch (e) {
      return [];
    }
  }

  void _recordCoupleHistory(String? coupleId, String promptId) {
    if (coupleId == null) return;

    _coupleHistory[coupleId] ??= [];
    _coupleHistory[coupleId]!.add(promptId);

    // Keep only last 100
    if (_coupleHistory[coupleId]!.length > 100) {
      _coupleHistory[coupleId] = _coupleHistory[coupleId]!.sublist(50);
    }
  }

  /// Save couple history to database (call at end of game session)
  Future<void> saveCoupleHistory(String coupleId) async {
    final history = _coupleHistory[coupleId];
    if (history == null || history.isEmpty) return;

    try {
      await _supabase.from('couple_game_history').upsert({
        'couple_id': coupleId,
        'prompt_ids': history.take(100).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('GamePersonalization: Failed to save history - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGAGEMENT FEEDBACK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record user reaction to a prompt
  void recordReaction({
    required String promptId,
    required String gameType,
    required PromptReaction reaction,
    Duration? timeSpent,
  }) {
    // Update local score immediately
    final currentScore = _promptScores[promptId] ?? 0.5;
    final delta = _reactionToDelta(reaction);
    _promptScores[promptId] = (currentScore + delta).clamp(0.0, 1.0);

    // Queue for batch update
    _pendingReactions.add(
      _ReactionRecord(
        promptId: promptId,
        gameType: gameType,
        reaction: reaction,
        timeSpent: timeSpent,
      ),
    );

    // Flush if batch is full
    if (_pendingReactions.length >= 10) {
      flushReactions();
    }
  }

  final List<_ReactionRecord> _pendingReactions = [];

  double _reactionToDelta(PromptReaction reaction) {
    switch (reaction) {
      case PromptReaction.loved:
        return 0.1;
      case PromptReaction.completed:
        return 0.05;
      case PromptReaction.skipped:
        return -0.05;
      case PromptReaction.disliked:
        return -0.1;
    }
  }

  /// Flush pending reactions to database
  Future<void> flushReactions() async {
    if (_pendingReactions.isEmpty) return;

    final reactions = List<_ReactionRecord>.from(_pendingReactions);
    _pendingReactions.clear();

    try {
      // Group by prompt for batch update
      final grouped = <String, List<_ReactionRecord>>{};
      for (final r in reactions) {
        grouped[r.promptId] ??= [];
        grouped[r.promptId]!.add(r);
      }

      // Update effectiveness scores
      for (final entry in grouped.entries) {
        final promptId = entry.key;
        final records = entry.value;

        final completedCount = records
            .where(
              (r) =>
                  r.reaction == PromptReaction.completed ||
                  r.reaction == PromptReaction.loved,
            )
            .length;
        final skippedCount = records
            .where(
              (r) =>
                  r.reaction == PromptReaction.skipped ||
                  r.reaction == PromptReaction.disliked,
            )
            .length;

        await _supabase.rpc(
          'update_prompt_effectiveness',
          params: {
            'p_prompt_id': promptId,
            'p_game_type': records.first.gameType,
            'p_completed': completedCount,
            'p_skipped': skippedCount,
          },
        ).catchError((_) => null);
      }
    } catch (e) {
      debugPrint('GamePersonalization: Failed to flush reactions - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTENSITY ADJUSTMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get suggested intensity adjustment based on session engagement
  IntensityAdjustment getIntensityAdjustment() {
    final recentReactions = _pendingReactions.takeLast(10).toList();

    if (recentReactions.length < 5) {
      return IntensityAdjustment.maintain;
    }

    final lovedCount = recentReactions
        .where(
          (r) => r.reaction == PromptReaction.loved,
        )
        .length;
    final skippedCount = recentReactions
        .where(
          (r) => r.reaction == PromptReaction.skipped,
        )
        .length;

    if (lovedCount > 6) {
      return IntensityAdjustment.increase;
    } else if (skippedCount > 6) {
      return IntensityAdjustment.decrease;
    }

    return IntensityAdjustment.maintain;
  }

  /// Suggest heat level change based on engagement
  String? suggestHeatChange(String currentHeat) {
    final adjustment = getIntensityAdjustment();

    final levels = ['PG', 'PG-13', 'R', 'X', 'XXX'];
    final currentIndex = levels.indexOf(currentHeat);

    if (currentIndex == -1) return null;

    switch (adjustment) {
      case IntensityAdjustment.increase:
        if (currentIndex < levels.length - 1) {
          return levels[currentIndex + 1];
        }
        break;
      case IntensityAdjustment.decrease:
        if (currentIndex > 0) {
          return levels[currentIndex - 1];
        }
        break;
      case IntensityAdjustment.maintain:
        break;
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

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

  String? _getPersonalizationReason(Map<String, dynamic> prompt) {
    final score = _promptScores[prompt['id'].toString()];
    if (score != null && score > 0.7) {
      return 'Popular with similar couples';
    }
    return null;
  }

  /// Clear session memory (call when starting new game session)
  void startNewSession() {
    _shownPromptsThisSession.clear();
    _recentCategories.clear();
    debugPrint('GamePersonalization: New session started');
  }

  /// Clear all caches
  void clear() {
    _shownPromptsThisSession.clear();
    _coupleHistory.clear();
    _promptScores.clear();
    _recentCategories.clear();
    _pendingReactions.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class PersonalizedPrompt {
  PersonalizedPrompt({
    required this.id,
    required this.content,
    this.category,
    required this.heatLevel,
    this.personalizedReason,
  });
  final String id;
  final String content;
  final String? category;
  final String heatLevel;
  final String? personalizedReason;
}

enum PromptReaction {
  loved,
  completed,
  skipped,
  disliked,
}

enum IntensityAdjustment {
  increase,
  maintain,
  decrease,
}

class _ReactionRecord {
  _ReactionRecord({
    required this.promptId,
    required this.gameType,
    required this.reaction,
    this.timeSpent,
  });
  final String promptId;
  final String gameType;
  final PromptReaction reaction;
  final Duration? timeSpent;
}
