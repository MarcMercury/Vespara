import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

/// ════════════════════════════════════════════════════════════════════════════
/// DOWN TO CLOWN - Game Provider
/// Handles game state, shuffling, persistence, and analytics
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class DtcPrompt {
  final String id;
  final String prompt;
  final String category;
  final int difficulty;
  final String heatLevel;
  final List<String> tags;
  
  const DtcPrompt({
    required this.id,
    required this.prompt,
    required this.category,
    required this.difficulty,
    required this.heatLevel,
    required this.tags,
  });
  
  factory DtcPrompt.fromJson(Map<String, dynamic> json) {
    return DtcPrompt(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      category: json['category'] as String? ?? 'naughty_list',
      difficulty: json['difficulty'] as int? ?? 2,
      heatLevel: json['heat_level'] as String? ?? 'PG-13',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class DtcGameSession {
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
}

class DtcUserStats {
  final int totalGamesPlayed;
  final int totalCorrect;
  final int totalPassed;
  final int highScore;
  final double averageScore;
  final DateTime? lastPlayedAt;
  final int streakDays;
  final int longestStreak;
  
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
  
  factory DtcUserStats.fromJson(Map<String, dynamic> json) {
    return DtcUserStats(
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
  }
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
  }) {
    return DtcGameState(
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
      await _loadPrompts();
      await _loadUserStats();
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
  
  /// Load prompts from database
  Future<void> _loadPrompts() async {
    final response = await _supabase
        .from('dtc_prompts')
        .select()
        .eq('is_active', true);
    
    final prompts = (response as List)
        .map((json) => DtcPrompt.fromJson(json))
        .toList();
    
    state = state.copyWith(allPrompts: prompts);
  }
  
  /// Load demo prompts (fallback)
  void _loadDemoPrompts() {
    final prompts = _demoPrompts.asMap().entries.map((entry) => DtcPrompt(
      id: 'demo-${entry.key}',
      prompt: entry.value['prompt'] as String,
      category: 'naughty_list',
      difficulty: entry.value['difficulty'] as int,
      heatLevel: entry.value['heat'] as String,
      tags: [],
    )).toList();
    
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
        filteredPrompts = filteredPrompts
            .where((p) => p.heatLevel == 'XXX')
            .toList();
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
      await _supabase.rpc('update_prompt_stats', params: {
        'p_prompt_id': promptId,
        'p_was_correct': wasCorrect,
      });
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
        await _supabase
            .from('dtc_game_sessions')
            .update({
              'ended_at': DateTime.now().toIso8601String(),
              'correct_prompts': state.correctPrompts.map((p) => p.id).toList(),
              'passed_prompts': state.passedPrompts.map((p) => p.id).toList(),
              'total_correct': correctCount,
              'total_passed': passedCount,
            })
            .eq('id', state.currentSessionId!);
      }
      
      // Update user stats
      await _supabase.rpc('update_user_game_stats', params: {
        'p_user_id': userId,
        'p_correct': correctCount,
        'p_passed': passedCount,
      });
      
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
      currentSessionId: null,
    );
  }
}

// Provider
final dtcGameProvider = StateNotifierProvider<DtcGameNotifier, DtcGameState>((ref) {
  return DtcGameNotifier();
});

// ═══════════════════════════════════════════════════════════════════════════
// DEMO PROMPTS (100 prompts for offline/demo mode)
// ═══════════════════════════════════════════════════════════════════════════

const List<Map<String, dynamic>> _demoPrompts = [
  // STANDARD SEXUAL / DATING (50)
  {'prompt': 'Flirting with intent', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Bedroom eyes', 'difficulty': 1, 'heat': 'PG-13'},
  {'prompt': 'Late-night "you up?" text', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Thirst trap', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Accidental moan', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Situationship', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Friends with benefits', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Morning-after confidence', 'difficulty': 3, 'heat': 'R'},
  {'prompt': '"I shouldn\'t be into this"', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Sexual tension', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Safe word', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Aftercare', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Praise kink', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Power bottom', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Brat energy', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Switch vibes', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Soft dom', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Hard limit', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Consent check', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Negotiation kink', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Rope bunny', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Impact play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Service top', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Exhibitionist', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Voyeur', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Pet play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Collar moment', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Dungeon etiquette', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Orgasm control', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Edge play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'CNC (consensual, not chaotic)', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Mommy issues (the fun kind)', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Daddy energy', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Protocol scene', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Subspace', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Top drop', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Marks with meaning', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Public but subtle', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Scene negotiation', 'difficulty': 3, 'heat': 'R'},
  {'prompt': '"Use me" energy', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Kink math', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Group chat consent', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Poly calendar nightmare', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Compersion high', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Afterparty cuddle puddle', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Everyone\'s watching (they aren\'t)', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Sex-positive panic', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Too many safeties', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Emotional aftercare spiral', 'difficulty': 3, 'heat': 'R'},
  {'prompt': '"That escalated consensually"', 'difficulty': 3, 'heat': 'R'},
  
  // POP CULTURE SEXUAL (20)
  {'prompt': 'Netflix and actually chill', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Fifty Shades energy', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'WAP confidence', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Hot girl summer', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Bridgerton tension', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Spicy BookTok', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Body count anxiety', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Dating app fatigue', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Ghosted after good sex', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'The talking stage', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Sending nudes responsibly', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Dick pic energy (unwanted)', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Read receipts anxiety', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Rizz master', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'No cap, just vibes', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Main character syndrome', 'difficulty': 1, 'heat': 'PG'},
  {'prompt': 'Toxic trait bragging', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Love bombing', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Breadcrumbing', 'difficulty': 2, 'heat': 'PG-13'},
  {'prompt': 'Benching', 'difficulty': 2, 'heat': 'PG-13'},
  
  // EXPLICIT (20)
  {'prompt': 'Shibari suspension', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Fire play', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Wax dripping', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sensory deprivation', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Electrostim', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Double penetration', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Pegging', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Cuckolding', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Findom', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Breeding kink', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Humiliation play', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Degradation kink', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Free use fantasy', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Predicament bondage', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Forced orgasm', 'difficulty': 5, 'heat': 'XXX'},
  {'prompt': 'Ruined orgasm', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Multiple orgasms', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Squirting', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Deep throat', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Face sitting', 'difficulty': 4, 'heat': 'X'},
  
  // INTIMACY (10)
  {'prompt': 'Tantric breathing', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Karezza practice', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Edging together', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Simultaneous orgasm', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Morning wood appreciation', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Quickie in public', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Mile high club', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Sex on the beach (not the drink)', 'difficulty': 4, 'heat': 'X'},
  {'prompt': 'Shower sex (overrated?)', 'difficulty': 3, 'heat': 'R'},
  {'prompt': 'Car sex cramped but worth it', 'difficulty': 3, 'heat': 'R'},
];
