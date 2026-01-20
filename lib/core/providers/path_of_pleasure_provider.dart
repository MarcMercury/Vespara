import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';

/// ════════════════════════════════════════════════════════════════════════════
/// PATH OF PLEASURE - FAMILY FEUD EDITION
/// Provider & State Management
/// "Survey Says..." - Rank scenarios by predicted popularity
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum GamePhase {
  idle,        // Not in a game
  lobby,       // Waiting for players
  ranking,     // Players ranking cards by popularity
  reveal,      // Showing correct order with animations
  roundScore,  // Show round scores
  leaderboard, // Final scores
  finished,    // Game complete
}

enum HeatLevel {
  mild,    // Vanilla only (1-2)
  spicy,   // Include spicy (1-3)
  sizzle,  // Everything (1-5)
}

extension HeatLevelExtension on HeatLevel {
  String get displayName {
    switch (this) {
      case HeatLevel.mild: return '🌸 Mild';
      case HeatLevel.spicy: return '🌶️ Spicy';
      case HeatLevel.sizzle: return '🔥 Sizzle';
    }
  }
  
  String get description {
    switch (this) {
      case HeatLevel.mild: return 'Sweet & innocent stuff';
      case HeatLevel.spicy: return 'Getting warmer...';
      case HeatLevel.sizzle: return 'No limits. Full send.';
    }
  }
  
  int get maxHeat {
    switch (this) {
      case HeatLevel.mild: return 2;
      case HeatLevel.spicy: return 4;
      case HeatLevel.sizzle: return 5;
    }
  }
  
  Color get color {
    switch (this) {
      case HeatLevel.mild: return const Color(0xFFE8B4D8);
      case HeatLevel.spicy: return const Color(0xFFFF6B35);
      case HeatLevel.sizzle: return const Color(0xFFDC143C);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class PopCard {
  final String id;
  final String text;
  final String category;
  final String? subcategory;
  final int heatLevel;
  final int globalRank;      // Actual popularity rank (1 = most popular)
  final double popularityScore; // 0-100 popularity
  final int rankChange;      // Week-over-week change (+5 = moved up 5 spots)
  
  const PopCard({
    required this.id,
    required this.text,
    required this.category,
    this.subcategory,
    this.heatLevel = 1,
    this.globalRank = 50,
    this.popularityScore = 50.0,
    this.rankChange = 0,
  });
  
  factory PopCard.fromJson(Map<String, dynamic> json) {
    return PopCard(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String? ?? 'vanilla',
      subcategory: json['subcategory'] as String?,
      heatLevel: json['heat_level'] as int? ?? 1,
      globalRank: json['global_rank'] as int? ?? 50,
      popularityScore: (json['popularity_score'] as num?)?.toDouble() ?? 50.0,
      rankChange: json['rank_change'] as int? ?? 0,
    );
  }
  
  /// Get trend emoji based on rank change
  String get trendEmoji {
    if (rankChange > 5) return '🔥';  // Hot
    if (rankChange > 0) return '📈';  // Rising
    if (rankChange < -5) return '📉'; // Falling fast
    if (rankChange < 0) return '⬇️';  // Declining
    return '➡️';                       // Stable
  }
  
  /// Get heat emoji
  String get heatEmoji {
    switch (heatLevel) {
      case 1: return '🌸';
      case 2: return '💜';
      case 3: return '🌶️';
      case 4: return '🔥';
      case 5: return '💀';
      default: return '💜';
    }
  }
}

class PopPlayer {
  final String id;
  final String oduserId;
  final String displayName;
  final String? avatarUrl;
  final Color avatarColor;
  final bool isHost;
  int score;
  int correctGuesses;
  int closeGuesses;
  int totalGuesses;
  int streak;
  int bestStreak;
  bool isLockedIn;
  
  PopPlayer({
    required this.id,
    required this.oduserId,
    required this.displayName,
    this.avatarUrl,
    required this.avatarColor,
    this.isHost = false,
    this.score = 0,
    this.correctGuesses = 0,
    this.closeGuesses = 0,
    this.totalGuesses = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.isLockedIn = false,
  });
  
  factory PopPlayer.fromJson(Map<String, dynamic> json) {
    return PopPlayer(
      id: json['id'] as String,
      oduserId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      avatarColor: _parseColor(json['avatar_color'] as String?),
      isHost: json['is_host'] as bool? ?? false,
      score: json['score'] as int? ?? 0,
      correctGuesses: json['correct_guesses'] as int? ?? 0,
      totalGuesses: json['total_guesses'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      isLockedIn: json['is_locked_in'] as bool? ?? false,
    );
  }
  
  static Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFF4A9EFF);
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
  
  /// Accuracy percentage
  double get accuracy => totalGuesses > 0 ? correctGuesses / totalGuesses * 100 : 0;
}

class RoundResult {
  final List<PopCard> correctOrder;  // Cards in correct popularity order
  final List<PopCard> playerOrder;   // Player's guessed order
  final int roundScore;
  final int correctCount;
  final int closeCount;
  final List<CardResult> cardResults;
  
  const RoundResult({
    required this.correctOrder,
    required this.playerOrder,
    required this.roundScore,
    required this.correctCount,
    required this.closeCount,
    required this.cardResults,
  });
}

class CardResult {
  final PopCard card;
  final int playerPosition;  // Where player ranked it (1-5)
  final int actualPosition;  // Where it actually is (1-5)
  final int pointsEarned;
  final bool isExact;
  final bool isClose;
  
  const CardResult({
    required this.card,
    required this.playerPosition,
    required this.actualPosition,
    required this.pointsEarned,
    required this.isExact,
    required this.isClose,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME STATE
// ═══════════════════════════════════════════════════════════════════════════

class PathOfPleasureState {
  final GamePhase phase;
  final String? sessionId;
  final String? roomCode;
  final List<PopPlayer> players;
  final String? currentPlayerId;
  final bool isHost;
  
  // Game settings
  final HeatLevel heatLevel;
  final int cardsPerRound;
  final int totalRounds;
  
  // Round data
  final int currentRound;
  final List<PopCard> roundCards;        // Cards to rank this round (shuffled)
  final List<PopCard> playerRanking;     // Player's current ranking
  final RoundResult? lastRoundResult;
  final List<RoundResult> allResults;
  
  // Timing
  final int timeRemaining;
  final int maxTime;
  
  // UI State
  final bool isLoading;
  final String? error;
  final bool isDemoMode;
  final int revealIndex;  // For animating reveal
  
  const PathOfPleasureState({
    this.phase = GamePhase.idle,
    this.sessionId,
    this.roomCode,
    this.players = const [],
    this.currentPlayerId,
    this.isHost = false,
    this.heatLevel = HeatLevel.spicy,
    this.cardsPerRound = 5,
    this.totalRounds = 3,
    this.currentRound = 1,
    this.roundCards = const [],
    this.playerRanking = const [],
    this.lastRoundResult,
    this.allResults = const [],
    this.timeRemaining = 60,
    this.maxTime = 60,
    this.isLoading = false,
    this.error,
    this.isDemoMode = false,
    this.revealIndex = -1,
  });
  
  PopPlayer? get me => currentPlayerId == null 
      ? null 
      : players.where((p) => p.id == currentPlayerId).firstOrNull;
  
  bool get allPlayersLocked => players.every((p) => p.isLockedIn);
  
  int get lockedCount => players.where((p) => p.isLockedIn).length;
  
  int get myTotalScore => me?.score ?? 0;
  
  /// Get sorted leaderboard
  List<PopPlayer> get leaderboard {
    final sorted = [...players];
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }
  
  PathOfPleasureState copyWith({
    GamePhase? phase,
    String? sessionId,
    String? roomCode,
    List<PopPlayer>? players,
    String? currentPlayerId,
    bool? isHost,
    HeatLevel? heatLevel,
    int? cardsPerRound,
    int? totalRounds,
    int? currentRound,
    List<PopCard>? roundCards,
    List<PopCard>? playerRanking,
    RoundResult? lastRoundResult,
    List<RoundResult>? allResults,
    int? timeRemaining,
    int? maxTime,
    bool? isLoading,
    String? error,
    bool? isDemoMode,
    int? revealIndex,
  }) {
    return PathOfPleasureState(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      roomCode: roomCode ?? this.roomCode,
      players: players ?? this.players,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      isHost: isHost ?? this.isHost,
      heatLevel: heatLevel ?? this.heatLevel,
      cardsPerRound: cardsPerRound ?? this.cardsPerRound,
      totalRounds: totalRounds ?? this.totalRounds,
      currentRound: currentRound ?? this.currentRound,
      roundCards: roundCards ?? this.roundCards,
      playerRanking: playerRanking ?? this.playerRanking,
      lastRoundResult: lastRoundResult ?? this.lastRoundResult,
      allResults: allResults ?? this.allResults,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      maxTime: maxTime ?? this.maxTime,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      revealIndex: revealIndex ?? this.revealIndex,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class PathOfPleasureNotifier extends StateNotifier<PathOfPleasureState> {
  Timer? _roundTimer;
  Timer? _revealTimer;
  bool _disposed = false;
  
  PathOfPleasureNotifier() : super(const PathOfPleasureState());
  
  @override
  void dispose() {
    _disposed = true;
    _roundTimer?.cancel();
    _revealTimer?.cancel();
    super.dispose();
  }
  
  // Player colors for avatars
  static const _playerColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFF4A9EFF), // Blue
    Color(0xFFDC143C), // Crimson
    Color(0xFF2ECC71), // Emerald
    Color(0xFF9B59B6), // Purple
    Color(0xFFF39C12), // Orange
    Color(0xFF1ABC9C), // Teal
    Color(0xFFE74C3C), // Red
  ];
  
  // ═════════════════════════════════════════════════════════════════════════
  // LOBBY ACTIONS
  // ═════════════════════════════════════════════════════════════════════════
  
  /// Host creates a new game session
  Future<void> hostGame(String hostName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final roomCode = _generateRoomCode();
      final hostId = 'host_${DateTime.now().millisecondsSinceEpoch}';
      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      
      final hostPlayer = PopPlayer(
        id: playerId,
        oduserId: hostId,
        displayName: hostName,
        avatarColor: _playerColors[0],
        isHost: true,
      );
      
      state = state.copyWith(
        phase: GamePhase.lobby,
        roomCode: roomCode,
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
        players: [hostPlayer],
        currentPlayerId: playerId,
        isHost: true,
        isLoading: false,
        isDemoMode: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  /// Guest joins an existing game
  Future<void> joinGame(String roomCode, String playerName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      final existingPlayers = [...state.players];
      
      final newPlayer = PopPlayer(
        id: playerId,
        oduserId: 'user_$playerId',
        displayName: playerName,
        avatarColor: _playerColors[existingPlayers.length % _playerColors.length],
      );
      
      existingPlayers.add(newPlayer);
      
      state = state.copyWith(
        phase: GamePhase.lobby,
        roomCode: roomCode.toUpperCase(),
        players: existingPlayers,
        currentPlayerId: playerId,
        isHost: false,
        isLoading: false,
        isDemoMode: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Room not found');
    }
  }
  
  /// Add local player (for pass & play mode)
  void addLocalPlayer(String name) {
    if (name.trim().isEmpty || state.players.length >= 8) return;
    
    final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}_${state.players.length}';
    final newPlayer = PopPlayer(
      id: playerId,
      oduserId: 'local_$playerId',
      displayName: name.trim(),
      avatarColor: _playerColors[state.players.length % _playerColors.length],
    );
    
    state = state.copyWith(players: [...state.players, newPlayer]);
  }
  
  void removePlayer(int index) {
    if (index < 0 || index >= state.players.length) return;
    if (state.players[index].isHost) return;
    
    final players = [...state.players];
    players.removeAt(index);
    state = state.copyWith(players: players);
  }
  
  /// Set heat level
  void setHeatLevel(HeatLevel level) {
    state = state.copyWith(heatLevel: level);
  }
  
  String _generateRoomCode() {
    final words = ['LUST', 'VIBE', 'AURA', 'GLOW', 'HEAT', 'FIRE', 'BURN', 'RUSH',
                   'PEAK', 'KISS', 'SILK', 'WILD', 'DARE', 'EDGE', 'SYNC', 'BOND'];
    final word = words[Random().nextInt(words.length)];
    final suffix = (Random().nextInt(90) + 10).toString();
    return '$word$suffix';
  }
  
  // ═════════════════════════════════════════════════════════════════════════
  // GAME FLOW
  // ═════════════════════════════════════════════════════════════════════════
  
  /// Start the game - deal first round
  Future<void> startGame() async {
    if (!state.isHost || state.players.isEmpty) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      // Get shuffled cards for this round
      final cards = _getShuffledCards();
      
      // Reset player states
      final players = state.players.map((p) {
        p.isLockedIn = false;
        p.score = 0;
        p.correctGuesses = 0;
        p.totalGuesses = 0;
        p.streak = 0;
        return p;
      }).toList();
      
      state = state.copyWith(
        phase: GamePhase.ranking,
        roundCards: cards,
        playerRanking: [...cards], // Start with shuffled order
        currentRound: 1,
        players: players,
        allResults: [],
        timeRemaining: state.maxTime,
        isLoading: false,
      );
      
      _startRoundTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  /// Reorder cards via drag and drop
  void reorderCards(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    
    final ranking = [...state.playerRanking];
    final item = ranking.removeAt(oldIndex);
    ranking.insert(newIndex, item);
    
    state = state.copyWith(playerRanking: ranking);
  }
  
  /// Move a card to a specific position
  void moveCard(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    
    final ranking = [...state.playerRanking];
    final item = ranking.removeAt(fromIndex);
    ranking.insert(toIndex, item);
    
    state = state.copyWith(playerRanking: ranking);
  }
  
  /// Lock in rankings and calculate score
  void lockIn() {
    _roundTimer?.cancel();
    
    // Calculate score
    final result = _calculateRoundScore();
    
    // Update player
    final players = state.players.map((p) {
      if (p.id == state.currentPlayerId) {
        p.isLockedIn = true;
        p.score += result.roundScore;
        p.correctGuesses += result.correctCount;
        p.closeGuesses += result.closeCount;
        p.totalGuesses += state.cardsPerRound;
        
        // Update streak
        if (result.correctCount >= 3) {
          p.streak++;
          if (p.streak > p.bestStreak) p.bestStreak = p.streak;
        } else {
          p.streak = 0;
        }
      }
      return p;
    }).toList();
    
    state = state.copyWith(
      players: players,
      lastRoundResult: result,
      allResults: [...state.allResults, result],
      phase: GamePhase.reveal,
      revealIndex: -1,
    );
    
    // Start reveal animation
    _animateReveal();
  }
  
  void _animateReveal() {
    int index = -1;
    _revealTimer?.cancel();
    
    _revealTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      
      index++;
      if (index >= state.cardsPerRound) {
        timer.cancel();
        // Show round score after reveal
        Future.delayed(const Duration(seconds: 1), () {
          if (_disposed) return;
          _showRoundScore();
        });
      } else {
        state = state.copyWith(revealIndex: index);
      }
    });
  }
  
  void _showRoundScore() {
    state = state.copyWith(phase: GamePhase.roundScore);
    
    // Auto-advance after a few seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (_disposed) return;
      
      if (state.currentRound >= state.totalRounds) {
        // End game
        state = state.copyWith(phase: GamePhase.leaderboard);
      } else {
        // Next round
        _startNextRound();
      }
    });
  }
  
  void skipToNextRound() {
    if (state.currentRound >= state.totalRounds) {
      state = state.copyWith(phase: GamePhase.leaderboard);
    } else {
      _startNextRound();
    }
  }
  
  void _startNextRound() {
    final nextRound = state.currentRound + 1;
    final cards = _getShuffledCards();
    
    final players = state.players.map((p) {
      p.isLockedIn = false;
      return p;
    }).toList();
    
    state = state.copyWith(
      phase: GamePhase.ranking,
      currentRound: nextRound,
      roundCards: cards,
      playerRanking: [...cards],
      players: players,
      timeRemaining: state.maxTime,
      revealIndex: -1,
    );
    
    _startRoundTimer();
  }
  
  void _startRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      
      final remaining = state.timeRemaining - 1;
      
      if (remaining <= 0) {
        timer.cancel();
        lockIn(); // Auto-submit when time runs out
      } else {
        state = state.copyWith(timeRemaining: remaining);
      }
    });
  }
  
  RoundResult _calculateRoundScore() {
    // Sort round cards by their actual global rank (lower = more popular)
    final correctOrder = [...state.roundCards];
    correctOrder.sort((a, b) => a.globalRank.compareTo(b.globalRank));
    
    final cardResults = <CardResult>[];
    int totalScore = 0;
    int correctCount = 0;
    int closeCount = 0;
    
    for (int i = 0; i < state.playerRanking.length; i++) {
      final playerCard = state.playerRanking[i];
      final playerPos = i + 1;
      
      // Find where this card actually belongs
      final actualPos = correctOrder.indexWhere((c) => c.id == playerCard.id) + 1;
      
      int points = 0;
      bool isExact = false;
      bool isClose = false;
      
      if (playerPos == actualPos) {
        // Exact match!
        points = 100;
        isExact = true;
        correctCount++;
      } else if ((playerPos - actualPos).abs() == 1) {
        // One off
        points = 50;
        isClose = true;
        closeCount++;
      } else if ((playerPos - actualPos).abs() == 2) {
        // Two off
        points = 25;
      }
      
      totalScore += points;
      
      cardResults.add(CardResult(
        card: playerCard,
        playerPosition: playerPos,
        actualPosition: actualPos,
        pointsEarned: points,
        isExact: isExact,
        isClose: isClose,
      ));
    }
    
    // Bonus for perfect round
    if (correctCount == state.cardsPerRound) {
      totalScore += 200;
    }
    
    return RoundResult(
      correctOrder: correctOrder,
      playerOrder: [...state.playerRanking],
      roundScore: totalScore,
      correctCount: correctCount,
      closeCount: closeCount,
      cardResults: cardResults,
    );
  }
  
  /// Get shuffled cards for a round (demo mode)
  List<PopCard> _getShuffledCards() {
    // Filter by heat level and shuffle
    final eligible = _demoCards
        .where((c) => c.heatLevel <= state.heatLevel.maxHeat)
        .toList();
    
    eligible.shuffle();
    
    return eligible.take(state.cardsPerRound).toList();
  }
  
  /// Reset game
  void reset() {
    _roundTimer?.cancel();
    _revealTimer?.cancel();
    state = const PathOfPleasureState();
  }
  
  /// Back to lobby
  void backToLobby() {
    _roundTimer?.cancel();
    _revealTimer?.cancel();
    
    final players = state.players.map((p) {
      p.score = 0;
      p.correctGuesses = 0;
      p.totalGuesses = 0;
      p.streak = 0;
      p.isLockedIn = false;
      return p;
    }).toList();
    
    state = state.copyWith(
      phase: GamePhase.lobby,
      currentRound: 1,
      roundCards: [],
      playerRanking: [],
      allResults: [],
      players: players,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final pathOfPleasureProvider = StateNotifierProvider<PathOfPleasureNotifier, PathOfPleasureState>(
  (ref) => PathOfPleasureNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════
// DEMO DATA - Cards with pre-set popularity rankings
// ═══════════════════════════════════════════════════════════════════════════

const List<PopCard> _demoCards = [
  // Vanilla - Most Popular (low globalRank = high popularity)
  PopCard(id: 'v1', text: 'Forehead kisses', category: 'vanilla', heatLevel: 1, globalRank: 3, popularityScore: 94.5, rankChange: 2),
  PopCard(id: 'v2', text: 'Holding hands while walking', category: 'vanilla', heatLevel: 1, globalRank: 5, popularityScore: 92.0, rankChange: 0),
  PopCard(id: 'v3', text: 'Falling asleep on their chest', category: 'vanilla', heatLevel: 1, globalRank: 6, popularityScore: 91.0, rankChange: 1),
  PopCard(id: 'v4', text: 'Hugging from behind', category: 'vanilla', heatLevel: 1, globalRank: 8, popularityScore: 89.0, rankChange: -2),
  PopCard(id: 'v5', text: 'Long, slow kisses', category: 'vanilla', heatLevel: 1, globalRank: 4, popularityScore: 93.0, rankChange: 3),
  PopCard(id: 'v6', text: 'Morning cuddles', category: 'vanilla', heatLevel: 1, globalRank: 2, popularityScore: 96.0, rankChange: 0),
  PopCard(id: 'v7', text: 'Slow dancing together', category: 'vanilla', heatLevel: 1, globalRank: 18, popularityScore: 78.0, rankChange: -1),
  PopCard(id: 'v8', text: 'Cooking together', category: 'vanilla', heatLevel: 1, globalRank: 12, popularityScore: 84.0, rankChange: 0),
  PopCard(id: 'v9', text: 'Stargazing', category: 'vanilla', heatLevel: 1, globalRank: 28, popularityScore: 68.0, rankChange: -3),
  PopCard(id: 'v10', text: 'Bubble bath together', category: 'vanilla', heatLevel: 2, globalRank: 22, popularityScore: 74.0, rankChange: 1),
  
  // Spicy - Medium popularity
  PopCard(id: 's1', text: 'Neck kisses that linger', category: 'spicy', heatLevel: 2, globalRank: 7, popularityScore: 90.0, rankChange: 5),
  PopCard(id: 's2', text: 'Being pinned against a wall', category: 'spicy', heatLevel: 3, globalRank: 15, popularityScore: 81.0, rankChange: 3),
  PopCard(id: 's3', text: 'Morning sex', category: 'spicy', heatLevel: 3, globalRank: 9, popularityScore: 88.0, rankChange: 0),
  PopCard(id: 's4', text: 'Hair pulling', category: 'spicy', heatLevel: 3, globalRank: 25, popularityScore: 71.0, rankChange: -2),
  PopCard(id: 's5', text: 'Receiving nudes', category: 'spicy', heatLevel: 3, globalRank: 32, popularityScore: 64.0, rankChange: 1),
  PopCard(id: 's6', text: 'Sending nudes', category: 'spicy', heatLevel: 3, globalRank: 35, popularityScore: 61.0, rankChange: -1),
  PopCard(id: 's7', text: 'Light spanking', category: 'spicy', heatLevel: 3, globalRank: 38, popularityScore: 58.0, rankChange: 2),
  PopCard(id: 's8', text: 'Blindfolded', category: 'spicy', heatLevel: 3, globalRank: 42, popularityScore: 54.0, rankChange: 0),
  PopCard(id: 's9', text: 'Dirty talk', category: 'spicy', heatLevel: 3, globalRank: 30, popularityScore: 66.0, rankChange: 4),
  PopCard(id: 's10', text: 'Strip tease', category: 'spicy', heatLevel: 3, globalRank: 45, popularityScore: 51.0, rankChange: -3),
  
  // Hot - Mixed popularity
  PopCard(id: 'h1', text: 'Oral (receiving)', category: 'edgy', heatLevel: 4, globalRank: 10, popularityScore: 87.0, rankChange: 2),
  PopCard(id: 'h2', text: 'Oral (giving)', category: 'edgy', heatLevel: 4, globalRank: 14, popularityScore: 82.0, rankChange: 0),
  PopCard(id: 'h3', text: 'Using vibrators together', category: 'edgy', heatLevel: 4, globalRank: 26, popularityScore: 70.0, rankChange: 1),
  PopCard(id: 'h4', text: '69 position', category: 'edgy', heatLevel: 4, globalRank: 48, popularityScore: 48.0, rankChange: -2),
  PopCard(id: 'h5', text: 'Sex in the shower', category: 'edgy', heatLevel: 4, globalRank: 16, popularityScore: 80.0, rankChange: 3),
  PopCard(id: 'h6', text: 'Rough sex', category: 'edgy', heatLevel: 4, globalRank: 33, popularityScore: 63.0, rankChange: 2),
  PopCard(id: 'h7', text: 'Role play', category: 'edgy', heatLevel: 4, globalRank: 40, popularityScore: 56.0, rankChange: -1),
  PopCard(id: 'h8', text: 'Tied up', category: 'edgy', heatLevel: 4, globalRank: 50, popularityScore: 46.0, rankChange: 0),
  
  // Explicit - Lower popularity (more niche)
  PopCard(id: 'e1', text: 'Light choking', category: 'edgy', heatLevel: 5, globalRank: 55, popularityScore: 41.0, rankChange: 4),
  PopCard(id: 'e2', text: 'Anal play (fingers)', category: 'edgy', heatLevel: 5, globalRank: 58, popularityScore: 38.0, rankChange: -1),
  PopCard(id: 'e3', text: 'Anal sex', category: 'edgy', heatLevel: 5, globalRank: 65, popularityScore: 31.0, rankChange: 0),
  PopCard(id: 'e4', text: 'Threesome fantasy', category: 'edgy', heatLevel: 5, globalRank: 52, popularityScore: 44.0, rankChange: 2),
  PopCard(id: 'e5', text: 'Actual threesome', category: 'edgy', heatLevel: 5, globalRank: 78, popularityScore: 18.0, rankChange: -3),
  PopCard(id: 'e6', text: 'Sex in public', category: 'edgy', heatLevel: 5, globalRank: 72, popularityScore: 24.0, rankChange: 1),
  PopCard(id: 'e7', text: 'Recording for private', category: 'edgy', heatLevel: 5, globalRank: 68, popularityScore: 28.0, rankChange: 0),
  PopCard(id: 'e8', text: 'Using plugs', category: 'edgy', heatLevel: 5, globalRank: 62, popularityScore: 34.0, rankChange: 2),
  PopCard(id: 'e9', text: 'Double penetration fantasy', category: 'edgy', heatLevel: 5, globalRank: 85, popularityScore: 11.0, rankChange: -2),
  PopCard(id: 'e10', text: 'Exhibitionism', category: 'edgy', heatLevel: 5, globalRank: 75, popularityScore: 21.0, rankChange: 1),
];
