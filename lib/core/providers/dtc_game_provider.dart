import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DOWN TO CLOWN - Game Provider
/// Handles game state, shuffling, persistence, and analytics
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class DtcPrompt {
  const DtcPrompt({
    required this.id,
    required this.prompt,
    required this.category,
    required this.difficulty,
    required this.heatLevel,
    required this.tags,
  });

  factory DtcPrompt.fromJson(Map<String, dynamic> json) => DtcPrompt(
        id: json['id'] as String,
        prompt: json['prompt'] as String,
        category: json['category'] as String? ?? 'naughty_list',
        difficulty: json['difficulty'] as int? ?? 2,
        heatLevel: json['heat_level'] as String? ?? 'PG-13',
        tags: List<String>.from(json['tags'] ?? []),
      );
  final String id;
  final String prompt;
  final String category;
  final int difficulty;
  final String heatLevel;
  final List<String> tags;
}

class DtcGameSession {
  const DtcGameSession({
    required this.id,
    this.deckCategory,
    required this.heatFilter,
    required this.roundDuration,
    required this.startedAt,
    this.endedAt,
    required this.promptsShown,
    required this.correctPrompts,
    required this.passedPrompts,
    required this.totalCorrect,
    required this.totalPassed,
  });
  final String id;
  final String? deckCategory;
  final String heatFilter;
  final int roundDuration;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<String> promptsShown;
  final List<String> correctPrompts;
  final List<String> passedPrompts;
  final int totalCorrect;
  final int totalPassed;
}

class DtcUserStats {
  const DtcUserStats({
    this.totalGamesPlayed = 0,
    this.totalCorrect = 0,
    this.totalPassed = 0,
    this.highScore = 0,
    this.averageScore = 0,
    this.lastPlayedAt,
    this.streakDays = 0,
    this.longestStreak = 0,
  });

  factory DtcUserStats.fromJson(Map<String, dynamic> json) => DtcUserStats(
        totalGamesPlayed: json['total_games_played'] as int? ?? 0,
        totalCorrect: json['total_correct'] as int? ?? 0,
        totalPassed: json['total_passed'] as int? ?? 0,
        highScore: json['high_score'] as int? ?? 0,
        averageScore: (json['average_score'] as num?)?.toDouble() ?? 0,
        lastPlayedAt: json['last_played_at'] != null
            ? DateTime.parse(json['last_played_at'])
            : null,
        streakDays: json['streak_days'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
      );
  final int totalGamesPlayed;
  final int totalCorrect;
  final int totalPassed;
  final int highScore;
  final double averageScore;
  final DateTime? lastPlayedAt;
  final int streakDays;
  final int longestStreak;
}

/// Heat filter options
enum HeatFilter {
  all('all', 'All Levels', 'Everything from PG to XXX'),
  mild('mild', 'Mild 🌸', 'PG and PG-13 only'),
  spicy('spicy', 'Spicy 🌶️', 'R and X rated'),
  xxx('xxx', 'XXX 🔥', 'Maximum heat');

  final String value;
  final String label;
  final String description;

  const HeatFilter(this.value, this.label, this.description);
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME STATE
// ═══════════════════════════════════════════════════════════════════════════

class DtcGameState {
  const DtcGameState({
    this.allPrompts = const [],
    this.shuffledDeck = const [],
    this.currentIndex = 0,
    this.correctPrompts = const [],
    this.passedPrompts = const [],
    this.userStats,
    this.currentSessionId,
    this.heatFilter = HeatFilter.all,
    this.isLoading = false,
    this.error,
    this.isDemoMode = false,
  });
  final List<DtcPrompt> allPrompts;
  final List<DtcPrompt> shuffledDeck;
  final int currentIndex;
  final List<DtcPrompt> correctPrompts;
  final List<DtcPrompt> passedPrompts;
  final DtcUserStats? userStats;
  final String? currentSessionId;
  final HeatFilter heatFilter;
  final bool isLoading;
  final String? error;
  final bool isDemoMode;

  DtcPrompt? get currentPrompt =>
      currentIndex < shuffledDeck.length ? shuffledDeck[currentIndex] : null;

  bool get hasMorePrompts => currentIndex < shuffledDeck.length;

  int get totalShown => correctPrompts.length + passedPrompts.length;

  DtcGameState copyWith({
    List<DtcPrompt>? allPrompts,
    List<DtcPrompt>? shuffledDeck,
    int? currentIndex,
    List<DtcPrompt>? correctPrompts,
    List<DtcPrompt>? passedPrompts,
    DtcUserStats? userStats,
    String? currentSessionId,
    HeatFilter? heatFilter,
    bool? isLoading,
    String? error,
    bool? isDemoMode,
  }) =>
      DtcGameState(
        allPrompts: allPrompts ?? this.allPrompts,
        shuffledDeck: shuffledDeck ?? this.shuffledDeck,
        currentIndex: currentIndex ?? this.currentIndex,
        correctPrompts: correctPrompts ?? this.correctPrompts,
        passedPrompts: passedPrompts ?? this.passedPrompts,
        userStats: userStats ?? this.userStats,
        currentSessionId: currentSessionId ?? this.currentSessionId,
        heatFilter: heatFilter ?? this.heatFilter,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isDemoMode: isDemoMode ?? this.isDemoMode,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

class DtcGameNotifier extends StateNotifier<DtcGameState> {
  DtcGameNotifier() : super(const DtcGameState()) {
    _initialize();
  }

  final _supabase = Supabase.instance.client;
  final _random = Random();

  /// Initialize - load prompts and user stats
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Add timeout to prevent infinite loading
      await Future.any([
        _loadPromptsAndStats(),
        Future.delayed(const Duration(seconds: 5), () {
          throw TimeoutException('Database connection timed out');
        }),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Fall back to demo mode with hardcoded prompts
      _loadDemoPrompts();
      state = state.copyWith(
        isLoading: false,
        isDemoMode: true,
        error: 'Using offline mode',
      );
    }
  }

  /// Load prompts and user stats from database
  Future<void> _loadPromptsAndStats() async {
    await _loadPrompts();
    await _loadUserStats();
  }

  /// Load prompts from database
  Future<void> _loadPrompts() async {
    final response =
        await _supabase.from('dtc_prompts').select().eq('is_active', true);

    final prompts =
        (response as List).map((json) => DtcPrompt.fromJson(json)).toList();

    state = state.copyWith(allPrompts: prompts);
  }

  /// Load demo prompts (fallback)
  void _loadDemoPrompts() {
    final prompts = _demoPrompts
        .asMap()
        .entries
        .map(
          (entry) => DtcPrompt(
            id: 'demo-${entry.key}',
            prompt: entry.value['prompt'] as String,
            category: 'naughty_list',
            difficulty: entry.value['difficulty'] as int,
            heatLevel: entry.value['heat'] as String,
            tags: [],
          ),
        )
        .toList();

    state = state.copyWith(allPrompts: prompts);
  }

  /// Load user stats from database
  Future<void> _loadUserStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _supabase
        .from('dtc_user_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      state = state.copyWith(userStats: DtcUserStats.fromJson(response));
    }
  }

  /// Set heat filter and reshuffle
  void setHeatFilter(HeatFilter filter) {
    state = state.copyWith(heatFilter: filter);
  }

  /// Start a new game - shuffle deck and create session
  Future<void> startNewGame() async {
    // Filter prompts by heat level
    var filteredPrompts = state.allPrompts;

    switch (state.heatFilter) {
      case HeatFilter.mild:
        filteredPrompts = filteredPrompts
            .where((p) => ['PG', 'PG-13'].contains(p.heatLevel))
            .toList();
        break;
      case HeatFilter.spicy:
        filteredPrompts = filteredPrompts
            .where((p) => ['R', 'X'].contains(p.heatLevel))
            .toList();
        break;
      case HeatFilter.xxx:
        filteredPrompts =
            filteredPrompts.where((p) => p.heatLevel == 'XXX').toList();
        break;
      case HeatFilter.all:
        // Keep all
        break;
    }

    // Shuffle using Fisher-Yates algorithm for true randomness
    final shuffled = List<DtcPrompt>.from(filteredPrompts);
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }

    // Create session in database
    String? sessionId;
    if (!state.isDemoMode) {
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          final response = await _supabase
              .from('dtc_game_sessions')
              .insert({
                'user_id': userId,
                'deck_category': 'naughty_list',
                'heat_filter': state.heatFilter.value,
                'round_duration': 60,
              })
              .select()
              .single();
          sessionId = response['id'];
        }
      } catch (e) {
        // Continue without session tracking
      }
    }

    state = state.copyWith(
      shuffledDeck: shuffled,
      currentIndex: 0,
      correctPrompts: [],
      passedPrompts: [],
      currentSessionId: sessionId,
    );
  }

  /// Mark current prompt as correct
  void markCorrect() {
    final current = state.currentPrompt;
    if (current == null) return;

    // Update prompt stats in database
    _updatePromptStats(current.id, true);

    state = state.copyWith(
      correctPrompts: [...state.correctPrompts, current],
      currentIndex: state.currentIndex + 1,
    );

    // Reshuffle if we run out
    _checkReshuffle();
  }

  /// Mark current prompt as passed
  void markPassed() {
    final current = state.currentPrompt;
    if (current == null) return;

    // Update prompt stats in database
    _updatePromptStats(current.id, false);

    state = state.copyWith(
      passedPrompts: [...state.passedPrompts, current],
      currentIndex: state.currentIndex + 1,
    );

    // Reshuffle if we run out
    _checkReshuffle();
  }

  /// Check if we need to reshuffle
  void _checkReshuffle() {
    if (state.currentIndex >= state.shuffledDeck.length) {
      // Reshuffle the deck
      final shuffled = List<DtcPrompt>.from(state.shuffledDeck);
      for (int i = shuffled.length - 1; i > 0; i--) {
        final j = _random.nextInt(i + 1);
        final temp = shuffled[i];
        shuffled[i] = shuffled[j];
        shuffled[j] = temp;
      }
      state = state.copyWith(
        shuffledDeck: shuffled,
        currentIndex: 0,
      );
    }
  }

  /// Update prompt stats in database
  Future<void> _updatePromptStats(String promptId, bool wasCorrect) async {
    if (state.isDemoMode || promptId.startsWith('demo-')) return;

    try {
      await _supabase.rpc(
        'update_prompt_stats',
        params: {
          'p_prompt_id': promptId,
          'p_was_correct': wasCorrect,
        },
      );
    } catch (e) {
      // Silent fail for stats
    }
  }

  /// End the current game and save results
  Future<void> endGame() async {
    final correctCount = state.correctPrompts.length;
    final passedCount = state.passedPrompts.length;

    if (state.isDemoMode) {
      // Just update local state for demo mode
      final newHighScore = state.userStats?.highScore ?? 0;
      state = state.copyWith(
        userStats: DtcUserStats(
          totalGamesPlayed: (state.userStats?.totalGamesPlayed ?? 0) + 1,
          totalCorrect: (state.userStats?.totalCorrect ?? 0) + correctCount,
          totalPassed: (state.userStats?.totalPassed ?? 0) + passedCount,
          highScore: correctCount > newHighScore ? correctCount : newHighScore,
          lastPlayedAt: DateTime.now(),
        ),
      );
      return;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Update session
      if (state.currentSessionId != null) {
        await _supabase.from('dtc_game_sessions').update({
          'ended_at': DateTime.now().toIso8601String(),
          'correct_prompts': state.correctPrompts.map((p) => p.id).toList(),
          'passed_prompts': state.passedPrompts.map((p) => p.id).toList(),
          'total_correct': correctCount,
          'total_passed': passedCount,
        }).eq('id', state.currentSessionId!);
      }

      // Update user stats
      await _supabase.rpc(
        'update_user_game_stats',
        params: {
          'p_user_id': userId,
          'p_correct': correctCount,
          'p_passed': passedCount,
        },
      );

      // Reload stats
      await _loadUserStats();
    } catch (e) {
      // Silent fail
    }
  }

  /// Get personalized result message
  String getResultMessage() {
    final count = state.correctPrompts.length;
    final highScore = state.userStats?.highScore ?? 0;

    if (count > highScore && highScore > 0) {
      return '🎉 NEW HIGH SCORE! You beat $highScore!';
    }

    if (count >= 20) return 'Absolute legend. You know your stuff. 🔥';
    if (count >= 15) return 'Impressive! You\'re fluent in filth. 😈';
    if (count >= 10) return 'Solid performance. Getting warmed up! 🌶️';
    if (count >= 5) return 'Not bad! Keep exploring. 😏';
    if (count >= 1) return 'Baby steps into the naughty list. 🌙';
    return 'Maybe try the Mild filter first? 😅';
  }

  /// Reset for a new game
  void reset() {
    state = state.copyWith(
      currentIndex: 0,
      correctPrompts: [],
      passedPrompts: [],
    );
  }
}

// Provider
final dtcGameProvider = StateNotifierProvider<DtcGameNotifier, DtcGameState>(
    (ref) => DtcGameNotifier());

// ═══════════════════════════════════════════════════════════════════════════
// DOWN TO CLOWN PROMPTS
// ═══════════════════════════════════════════════════════════════════════════

const List<Map<String, dynamic>> _demoPrompts = [
  {'prompt': 'Threesome', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Deep Throat', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Strap-On', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Body Count', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Safe Word', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Praise Kink', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Tit Fucking', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Roleplay', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Hitachi Wand', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Morning Wood', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Dry Humping', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Glory Hole', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sybian', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Face Sitting', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Cuckold', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Strip Poker', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Motorboating', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Anal Beads', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Butt Plug', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Voyeurism', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Size Queen', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Flogger', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Aftercare', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Double-Sided Dildo', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Thirst Trap', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Reverse Cowgirl', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Missionary', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Doggy Style', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Orgy', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Cock Ring', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Blindfold', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Fleshlight', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Nipple Clamps', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Handcuffs', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Rope (Shibari)', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Body Paint', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Lube Shooter', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'The Wheelbarrow', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Tea Bagging', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Rimming (Rim Job)', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Pearl Necklace', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Cream Pie', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'The Amazon', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Standing Carry', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Spooning', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Pegging', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Edging', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Foot Fetish', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Impact Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Exhibitionism', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Findom', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Age Play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Wax Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Breath Play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Breeding Kink', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'CNC', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sado-Masochism', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Spanking', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Free Use', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Daddy Dom', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Brat Tamer', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Sensory Deprivation', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Golden Shower', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Netflix and Chill', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'DTF', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Gluck Gluck 9000', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Raw Dogging', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Whiskey Dick', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Blue Balls', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Camel Toe', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Moose Knuckle', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Walk of Shame', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Eskimo Brothers', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Pillow Princess', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Starfish', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Cockblock', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Ghosting', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Fuckboy', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Gold Digger', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'One Night Stand', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Friends with Benefits', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Gang Bang', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Swingers Party', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Lap Dance', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Post-Nut Clarity', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Hall Pass', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Public Sex', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Car Sex', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Shower Sex', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Phone Sex', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Sexting', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'The G-Spot', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Mile High Club', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Scissoring', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Chastity Cage', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Feather Tickler', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Glass Dildo', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Prostate Massager', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Ball Gag', 'difficulty': 3, 'heat': 'R'},
  {'prompt': '69', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Cowgirl', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Lotus Position', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'The Pretzel', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Helicopter', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Blow Job', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Hand Job', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Foot Job', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Cum Shot', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Money Shot', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Facial', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Swallow', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Spit or Swallow', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Gag Reflex', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Sloppy Seconds', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Third Base', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'V-Card', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Popping the Cherry', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Kegels', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Ben Wa Balls', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Love Egg', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Bullet Vibe', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Rabbit Vibe', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Speculum', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Enema', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Massage Oil', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Aphrodisiac', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Whipped Cream', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Ice Cube', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Collar & Leash', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Paddle', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Whip', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Riding Crop', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Spreader Bar', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sex Swing', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Dungeon', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Unicorn', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Bull', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Hotwife', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Polyamory', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Open Relationship', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Affair', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Mistress', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Birthday Suit', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Commando', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Streaking', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Flashing', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Mooning', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Boner', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Viagra', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Condom', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Pull Out Method', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Period Sex', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Kitchen Counter', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Washing Machine', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Sounding', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Prince Albert', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Queening', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Snowballing', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Donkey Punch', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Bukkake', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Squirt', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Gimp Suit', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Ball Stretcher', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sex Doll', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'OnlyFans', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Sugar Baby', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Sugar Daddy', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Catfishing', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Situationship', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Skinny Dipping', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Taint', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Clitoris', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Just the Tip', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Quickie', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Booty Call', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Side Chick', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'WAP', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Switch', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Vanilla', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Hard Limits', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Subspace', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Electro Play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Medical Play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Pet Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Furry', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Suspension', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Hogtie', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Spread Eagle', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Violet Wand', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Figging', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Dirty Talk', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Cock Worship', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Femdom', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Sissy Hypno', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Gooning', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Hate Fucking', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Make-up Sex', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Tantric Sex', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Orgasm', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Foreplay', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Throat Goat', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Rusty Trombone', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Spanish Fly', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Torment', 'difficulty': 3, 'heat': 'R'},
  // ═══════════════════════════════════════════════════════════════════════════
  // EXPANDED EXPLICIT CLUES - 130+ New Terms
  // ═══════════════════════════════════════════════════════════════════════════
  {'prompt': 'Anal Fisting', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Anal Sex', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'BDSM', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Bondage', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Breathplay', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'CBT', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Cunnilingus', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'DDLG', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Dildo', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Dominance', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Electrosex', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Fantasy', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Fisting', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'G-String', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Harness', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Kink', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Leather Bondage', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'LGBTQ+', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Libido', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Masturbation', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Prostate Massage', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Rope Bondage', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Sadism', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Safe Sex', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Sex Toy', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Shibari', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Submission', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Tribadism', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Vibrator', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Whipping', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Afterglow', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Arousal', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Ball Fondling', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Begging', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Body Worship', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Bootlicker', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Bottoming', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Breast Play', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Clothed Sex', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Consent Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Corset', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Cross-Dressing', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Cuckolding', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Cum Eating', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'D/s Relationship', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Denial', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Discipline', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Dominant', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Eager Beaver', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Edge Play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Erection', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Erogenous Zone', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Erotic Massage', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Erotophilia', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Face Fucking', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Felching', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Femme Fatale', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Fetish', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Fingering', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Fire Play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Flogger', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Fornication', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Frottage', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Full Swap', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Gagging', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Gender Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Genital Worship', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Glory Hole', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Good Girl', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Groping', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Hair Pulling', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Head Pushing', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Hickey', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'High Protocol', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Hook-up', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Horny', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Humiliation', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Ice Play', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Intimacy', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Inverted Position', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Jilling Off', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Kegel Exercises', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Kinbaku', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Kinky Sex', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Knife Play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Labia', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Latex Fetish', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Little Space', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Lust', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Making Love', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Making Out', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Manscaping', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Masochism', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Milking', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Mind Control', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Mischievous', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Mommy Dom', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Mutual Masturbation', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Naked Cuddling', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Naughty', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Neck Biting', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Nipple Play', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'No Strings Attached', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Objectification', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Oil Wrestling', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'One-Off', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Oral Fixation', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Orgasm Control', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Orgasm Denial', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Orgy', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Outcall', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Over-the-Knee', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Pansexual', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Passion', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Pearl', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Penetration', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Penis Pump', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Phone Bone', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Photo Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Pinching', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Play Party', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Plug Training', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Pounding', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Power Bottom', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Power Exchange', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Pre-Cum', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Primal Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Prostate Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Punishment', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Pussy Worship', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Quiver', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Ravishment', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Rear Entry', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Red Room', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Restraints', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Riding', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Rimjob', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Role Reversal', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Rough Sex', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Ruined Orgasm', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Safeword', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Scat Play', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Scene', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Scratching', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Seduction', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Self-Bondage', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sensory Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Sensual Touch', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Service Top', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Sex Club', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sex Dungeon', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sex Game', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Sex Machine', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sex Positive', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Sexual Appetite', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Sexual Tension', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Shaming', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Sharing Partner', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Shower Play', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Simultaneous Orgasm', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Single Tail', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Skin Hunger', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Slave', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Sleeping Naked', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Slow Burn', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Slutty', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Soft Swap', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Solo Play', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Sounding', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Spitroast', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Striptease', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Submissive', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Suction Cup', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Swinger', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Taboo', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Tantalize', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Tease', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Temperature Play', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Thigh Highs', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Thirsty', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Tickle Torture', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Tie and Tease', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Top', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Topping from the Bottom', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Total Power Exchange', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Trampling', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Twink', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Undressing', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Vaginal Sex', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Vampire Gloves', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Verbal Abuse', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Vulva', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Water Sports', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Wet Dream', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Wet Spot', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Worship', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Wrestling', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Yiffing', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Zipper', 'difficulty': 3, 'heat': 'R'},
];
