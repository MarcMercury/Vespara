import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';

/// ════════════════════════════════════════════════════════════════════════════
/// PATH OF PLEASURE - The Compatibility Engine
/// Provider & State Management
/// Real-time multiplayer card sorting game
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum GamePhase {
  idle,        // Not in a game
  lobby,       // Waiting for players
  sorting,     // Players ranking cards
  reveal,      // Showing results
  discussion,  // Timer for conversation
  finished,    // Game complete
}

enum CardCategory { vanilla, spicy, edgy }

extension CardCategoryExtension on CardCategory {
  String get displayName {
    switch (this) {
      case CardCategory.vanilla: return '🌸 Vanilla';
      case CardCategory.spicy: return '🌶️ Spicy';
      case CardCategory.edgy: return '🔥 Edgy';
    }
  }
  
  Color get color {
    switch (this) {
      case CardCategory.vanilla: return const Color(0xFFE8B4D8); // Soft pink
      case CardCategory.spicy: return const Color(0xFFFF6B35);   // Orange
      case CardCategory.edgy: return const Color(0xFFDC143C);     // Crimson
    }
  }
  
  int get roundNumber {
    switch (this) {
      case CardCategory.vanilla: return 1;
      case CardCategory.spicy: return 2;
      case CardCategory.edgy: return 3;
    }
  }
}

enum RankZone {
  craving,  // Top - "I need this constantly"
  open,     // Middle - "I'd try it / I like it"
  limit,    // Bottom - "Hard Pass / Never"
}

extension RankZoneExtension on RankZone {
  String get label {
    switch (this) {
      case RankZone.craving: return 'CRAVING';
      case RankZone.open: return 'OPEN';
      case RankZone.limit: return 'LIMIT';
    }
  }
  
  Color get color {
    switch (this) {
      case RankZone.craving: return const Color(0xFFFFD700); // Gold
      case RankZone.open: return const Color(0xFF9B59B6);    // Purple
      case RankZone.limit: return const Color(0xFF2C2C2C);   // Dark grey
    }
  }
  
  String get emoji {
    switch (this) {
      case RankZone.craving: return '🔥';
      case RankZone.open: return '💜';
      case RankZone.limit: return '🚫';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class PopCard {
  final String id;
  final String text;
  final CardCategory category;
  final String? subcategory;
  final int heatLevel;
  
  const PopCard({
    required this.id,
    required this.text,
    required this.category,
    this.subcategory,
    this.heatLevel = 1,
  });
  
  factory PopCard.fromJson(Map<String, dynamic> json) {
    return PopCard(
      id: json['id'] as String,
      text: json['text'] as String,
      category: _parseCategory(json['category'] as String),
      subcategory: json['subcategory'] as String?,
      heatLevel: json['heat_level'] as int? ?? 1,
    );
  }
  
  static CardCategory _parseCategory(String value) {
    switch (value.toLowerCase()) {
      case 'spicy': return CardCategory.spicy;
      case 'edgy': return CardCategory.edgy;
      default: return CardCategory.vanilla;
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
  bool isLockedIn;
  
  PopPlayer({
    required this.id,
    required this.oduserId,
    required this.displayName,
    this.avatarUrl,
    required this.avatarColor,
    this.isHost = false,
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
      isLockedIn: json['is_locked_in'] as bool? ?? false,
    );
  }
  
  static Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFF4A9EFF);
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}

class CardRanking {
  final String cardId;
  int position; // 0 = Craving (top), 4 = Limit (bottom)
  
  CardRanking({
    required this.cardId,
    required this.position,
  });
  
  RankZone get zone {
    if (position <= 1) return RankZone.craving;
    if (position >= 3) return RankZone.limit;
    return RankZone.open;
  }
}

class CardResult {
  final PopCard card;
  final bool isGoldenMatch;  // All players ranked in top 2
  final bool isFrictionPoint; // Delta >= 3 between players
  final int maxDelta;
  final Map<String, int> playerRankings; // playerId -> position
  
  const CardResult({
    required this.card,
    required this.isGoldenMatch,
    required this.isFrictionPoint,
    required this.maxDelta,
    required this.playerRankings,
  });
  
  factory CardResult.fromJson(Map<String, dynamic> json, PopCard card) {
    final rankings = (json['rankings_json'] as Map<String, dynamic>?) ?? {};
    return CardResult(
      card: card,
      isGoldenMatch: json['is_golden_match'] as bool? ?? false,
      isFrictionPoint: json['is_friction_point'] as bool? ?? false,
      maxDelta: json['max_delta'] as int? ?? 0,
      playerRankings: rankings.map((k, v) => MapEntry(k, v as int)),
    );
  }
}

class CompatibilityResult {
  final int matchPercent;
  final int goldenMatches;
  final int frictionPoints;
  final String sweetSpot;
  final String differOn;
  
  const CompatibilityResult({
    required this.matchPercent,
    required this.goldenMatches,
    required this.frictionPoints,
    required this.sweetSpot,
    required this.differOn,
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
  final String? currentPlayerId; // This device's player ID
  final bool isHost;
  
  // Round data
  final int currentRound;
  final int totalRounds;
  final List<PopCard> currentCards;
  final List<CardRanking> myRankings; // This player's rankings
  
  // Results
  final List<CardResult> roundResults;
  final CompatibilityResult? finalResult;
  
  // Timing
  final DateTime? phaseStartedAt;
  final DateTime? discussionEndsAt;
  final int discussionSecondsRemaining;
  
  // UI State
  final bool isLoading;
  final String? error;
  final bool isDemoMode;
  
  const PathOfPleasureState({
    this.phase = GamePhase.idle,
    this.sessionId,
    this.roomCode,
    this.players = const [],
    this.currentPlayerId,
    this.isHost = false,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.currentCards = const [],
    this.myRankings = const [],
    this.roundResults = const [],
    this.finalResult,
    this.phaseStartedAt,
    this.discussionEndsAt,
    this.discussionSecondsRemaining = 30,
    this.isLoading = false,
    this.error,
    this.isDemoMode = false,
  });
  
  PopPlayer? get me => currentPlayerId == null 
      ? null 
      : players.where((p) => p.id == currentPlayerId).firstOrNull;
  
  bool get allPlayersLocked => players.every((p) => p.isLockedIn);
  
  int get lockedCount => players.where((p) => p.isLockedIn).length;
  
  CardCategory get currentCategory {
    switch (currentRound) {
      case 1: return CardCategory.vanilla;
      case 2: return CardCategory.spicy;
      case 3: return CardCategory.edgy;
      default: return CardCategory.vanilla;
    }
  }
  
  PathOfPleasureState copyWith({
    GamePhase? phase,
    String? sessionId,
    String? roomCode,
    List<PopPlayer>? players,
    String? currentPlayerId,
    bool? isHost,
    int? currentRound,
    int? totalRounds,
    List<PopCard>? currentCards,
    List<CardRanking>? myRankings,
    List<CardResult>? roundResults,
    CompatibilityResult? finalResult,
    DateTime? phaseStartedAt,
    DateTime? discussionEndsAt,
    int? discussionSecondsRemaining,
    bool? isLoading,
    String? error,
    bool? isDemoMode,
  }) {
    return PathOfPleasureState(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      roomCode: roomCode ?? this.roomCode,
      players: players ?? this.players,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      isHost: isHost ?? this.isHost,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      currentCards: currentCards ?? this.currentCards,
      myRankings: myRankings ?? this.myRankings,
      roundResults: roundResults ?? this.roundResults,
      finalResult: finalResult ?? this.finalResult,
      phaseStartedAt: phaseStartedAt ?? this.phaseStartedAt,
      discussionEndsAt: discussionEndsAt ?? this.discussionEndsAt,
      discussionSecondsRemaining: discussionSecondsRemaining ?? this.discussionSecondsRemaining,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class PathOfPleasureNotifier extends StateNotifier<PathOfPleasureState> {
  Timer? _discussionTimer;
  
  PathOfPleasureNotifier() : super(const PathOfPleasureState());
  
  // Player colors for avatars
  static const _playerColors = [
    Color(0xFF4A9EFF), // Blue
    Color(0xFFDC143C), // Crimson
    Color(0xFF9B59B6), // Purple
    Color(0xFF2ECC71), // Emerald
    Color(0xFFF39C12), // Gold
    Color(0xFF1ABC9C), // Teal
    Color(0xFFE74C3C), // Red
    Color(0xFF3498DB), // Sky Blue
  ];
  
  // ═════════════════════════════════════════════════════════════════════════
  // LOBBY ACTIONS
  // ═════════════════════════════════════════════════════════════════════════
  
  /// Host creates a new game session
  Future<void> hostGame(String hostName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Generate room code
      final roomCode = _generateRoomCode();
      final hostId = 'host_${DateTime.now().millisecondsSinceEpoch}';
      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create host player
      final hostPlayer = PopPlayer(
        id: playerId,
        oduserId: hostId,
        displayName: hostName,
        avatarColor: _playerColors[0],
        isHost: true,
        isLockedIn: false,
      );
      
      // In real app, create session in Supabase here
      // For demo, we use local state
      
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
      // In real app, fetch session from Supabase by room code
      // For demo, simulate joining
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      final existingPlayers = [...state.players];
      
      final newPlayer = PopPlayer(
        id: playerId,
        oduserId: 'user_$playerId',
        displayName: playerName,
        avatarColor: _playerColors[existingPlayers.length % _playerColors.length],
        isHost: false,
        isLockedIn: false,
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
  
  /// Add local player (for Pass & Play mode)
  void addLocalPlayer(String name) {
    if (name.trim().isEmpty || state.players.length >= 8) return;
    
    final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}_${state.players.length}';
    final newPlayer = PopPlayer(
      id: playerId,
      oduserId: 'local_$playerId',
      displayName: name.trim(),
      avatarColor: _playerColors[state.players.length % _playerColors.length],
      isHost: false,
      isLockedIn: false,
    );
    
    state = state.copyWith(players: [...state.players, newPlayer]);
  }
  
  void removePlayer(int index) {
    if (index < 0 || index >= state.players.length) return;
    if (state.players[index].isHost) return; // Can't remove host
    
    final players = [...state.players];
    players.removeAt(index);
    state = state.copyWith(players: players);
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
  
  /// Host starts the game - deals cards for round 1
  Future<void> dealCards() async {
    if (!state.isHost || state.players.length < 2) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      // Get cards for current round
      final cards = _getDemoCards(state.currentCategory);
      
      // Initialize rankings with random positions
      final rankings = cards.asMap().entries.map((e) => 
        CardRanking(cardId: e.value.id, position: e.key)
      ).toList();
      
      // Reset all players to not locked in
      final players = state.players.map((p) {
        p.isLockedIn = false;
        return p;
      }).toList();
      
      state = state.copyWith(
        phase: GamePhase.sorting,
        currentCards: cards,
        myRankings: rankings,
        players: players,
        phaseStartedAt: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  /// Update card ranking during sorting
  void updateRanking(String cardId, int newPosition) {
    final rankings = [...state.myRankings];
    final cardIndex = rankings.indexWhere((r) => r.cardId == cardId);
    
    if (cardIndex == -1) return;
    
    // Swap positions
    final currentPosition = rankings[cardIndex].position;
    final swapIndex = rankings.indexWhere((r) => r.position == newPosition);
    
    if (swapIndex != -1) {
      rankings[swapIndex].position = currentPosition;
    }
    rankings[cardIndex].position = newPosition;
    
    state = state.copyWith(myRankings: rankings);
  }
  
  /// Reorder cards via drag and drop
  void reorderCards(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    
    final rankings = [...state.myRankings];
    rankings.sort((a, b) => a.position.compareTo(b.position));
    
    final item = rankings.removeAt(oldIndex);
    rankings.insert(newIndex, item);
    
    // Update positions
    for (int i = 0; i < rankings.length; i++) {
      rankings[i].position = i;
    }
    
    state = state.copyWith(myRankings: rankings);
  }
  
  /// Player locks in their rankings
  void lockIn() {
    final players = state.players.map((p) {
      if (p.id == state.currentPlayerId) {
        p.isLockedIn = true;
      }
      return p;
    }).toList();
    
    state = state.copyWith(players: players);
    
    // In demo mode, simulate other players locking in
    if (state.isDemoMode && state.players.length > 1) {
      _simulateOtherPlayersLockIn();
    }
    
    // Check if all locked
    if (state.allPlayersLocked) {
      _revealResults();
    }
  }
  
  void _simulateOtherPlayersLockIn() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      final players = state.players.map((p) {
        p.isLockedIn = true;
        return p;
      }).toList();
      
      state = state.copyWith(players: players);
      
      if (state.allPlayersLocked) {
        _revealResults();
      }
    });
  }
  
  void _revealResults() {
    // Calculate results for each card
    final results = _calculateRoundResults();
    
    state = state.copyWith(
      phase: GamePhase.reveal,
      roundResults: [...state.roundResults, ...results],
    );
    
    // After a brief reveal, start discussion timer
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _startDiscussionPhase();
    });
  }
  
  List<CardResult> _calculateRoundResults() {
    final results = <CardResult>[];
    
    for (final card in state.currentCards) {
      final ranking = state.myRankings.firstWhere(
        (r) => r.cardId == card.id,
        orElse: () => CardRanking(cardId: card.id, position: 2),
      );
      
      // In demo mode, generate random rankings for other players
      final playerRankings = <String, int>{};
      for (final player in state.players) {
        if (player.id == state.currentPlayerId) {
          playerRankings[player.id] = ranking.position;
        } else {
          // Simulate other player's ranking
          playerRankings[player.id] = Random().nextInt(5);
        }
      }
      
      // Calculate matches/friction
      final positions = playerRankings.values.toList();
      final maxDelta = positions.length > 1 
          ? positions.reduce((a, b) => a > b ? a : b) - positions.reduce((a, b) => a < b ? a : b)
          : 0;
      
      final allInTop2 = positions.every((p) => p <= 1);
      final hasFriction = maxDelta >= 3;
      
      results.add(CardResult(
        card: card,
        isGoldenMatch: allInTop2,
        isFrictionPoint: hasFriction,
        maxDelta: maxDelta,
        playerRankings: playerRankings,
      ));
    }
    
    return results;
  }
  
  void _startDiscussionPhase() {
    final endsAt = DateTime.now().add(const Duration(seconds: 30));
    
    state = state.copyWith(
      phase: GamePhase.discussion,
      discussionEndsAt: endsAt,
      discussionSecondsRemaining: 30,
    );
    
    _discussionTimer?.cancel();
    _discussionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final remaining = state.discussionSecondsRemaining - 1;
      
      if (remaining <= 0) {
        timer.cancel();
        _endDiscussion();
      } else {
        state = state.copyWith(discussionSecondsRemaining: remaining);
      }
    });
  }
  
  /// Skip discussion early (host only)
  void skipDiscussion() {
    if (!state.isHost) return;
    _discussionTimer?.cancel();
    _endDiscussion();
  }
  
  void _endDiscussion() {
    if (state.currentRound >= state.totalRounds) {
      _endGame();
    } else {
      _startNextRound();
    }
  }
  
  void _startNextRound() {
    // Reset for next round
    final nextRound = state.currentRound + 1;
    final players = state.players.map((p) {
      p.isLockedIn = false;
      return p;
    }).toList();
    
    final cards = _getDemoCards(
      nextRound == 2 ? CardCategory.spicy : CardCategory.edgy
    );
    
    final rankings = cards.asMap().entries.map((e) => 
      CardRanking(cardId: e.value.id, position: e.key)
    ).toList();
    
    state = state.copyWith(
      phase: GamePhase.sorting,
      currentRound: nextRound,
      currentCards: cards,
      myRankings: rankings,
      players: players,
      phaseStartedAt: DateTime.now(),
    );
  }
  
  void _endGame() {
    // Calculate final compatibility
    final allResults = state.roundResults;
    final goldenMatches = allResults.where((r) => r.isGoldenMatch).length;
    final frictionPoints = allResults.where((r) => r.isFrictionPoint).length;
    final total = allResults.length;
    
    final matchPercent = total > 0 
        ? ((total - frictionPoints) / total * 100).round()
        : 0;
    
    final finalResult = CompatibilityResult(
      matchPercent: matchPercent,
      goldenMatches: goldenMatches,
      frictionPoints: frictionPoints,
      sweetSpot: 'Intimacy & Touch',
      differOn: 'Public Risk',
    );
    
    state = state.copyWith(
      phase: GamePhase.finished,
      finalResult: finalResult,
    );
  }
  
  /// Play again with same players
  void playAgain() {
    final players = state.players.map((p) {
      p.isLockedIn = false;
      return p;
    }).toList();
    
    state = state.copyWith(
      phase: GamePhase.lobby,
      currentRound: 1,
      currentCards: [],
      myRankings: [],
      roundResults: [],
      finalResult: null,
      players: players,
    );
  }
  
  /// Exit to main menu
  void exitGame() {
    _discussionTimer?.cancel();
    state = const PathOfPleasureState();
  }
  
  @override
  void dispose() {
    _discussionTimer?.cancel();
    super.dispose();
  }
  
  // ═════════════════════════════════════════════════════════════════════════
  // DEMO MODE CARDS
  // ═════════════════════════════════════════════════════════════════════════
  
  List<PopCard> _getDemoCards(CardCategory category) {
    final random = Random();
    final id = () => 'card_${random.nextInt(99999)}';
    
    switch (category) {
      case CardCategory.vanilla:
        return [
          PopCard(id: id(), text: 'Morning sex before getting out of bed', category: category, subcategory: 'intimacy'),
          PopCard(id: id(), text: 'Cuddling on the couch watching movies', category: category, subcategory: 'intimacy'),
          PopCard(id: id(), text: 'Long, slow kisses', category: category, subcategory: 'intimacy'),
          PopCard(id: id(), text: 'Holding hands in public', category: category, subcategory: 'public'),
          PopCard(id: id(), text: 'Showering together', category: category, subcategory: 'intimacy'),
        ];
      
      case CardCategory.spicy:
        return [
          PopCard(id: id(), text: 'Blindfolds during intimacy', category: category, subcategory: 'sensory', heatLevel: 2),
          PopCard(id: id(), text: 'Dirty talk', category: category, subcategory: 'verbal', heatLevel: 2),
          PopCard(id: id(), text: 'Almost getting caught', category: category, subcategory: 'risk', heatLevel: 3),
          PopCard(id: id(), text: 'Giving commands in the bedroom', category: category, subcategory: 'power', heatLevel: 2),
          PopCard(id: id(), text: 'Leaving marks that others might see', category: category, subcategory: 'marking', heatLevel: 3),
        ];
      
      case CardCategory.edgy:
        return [
          PopCard(id: id(), text: 'Full roleplay with costumes', category: category, subcategory: 'roleplay', heatLevel: 3),
          PopCard(id: id(), text: 'Dominant/submissive dynamics', category: category, subcategory: 'power', heatLevel: 4),
          PopCard(id: id(), text: 'Using toys together', category: category, subcategory: 'toys', heatLevel: 3),
          PopCard(id: id(), text: 'Anal play (any level)', category: category, subcategory: 'anal', heatLevel: 4),
          PopCard(id: id(), text: 'Semi-public spaces (car, balcony)', category: category, subcategory: 'risk', heatLevel: 4),
        ];
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final pathOfPleasureProvider = StateNotifierProvider<PathOfPleasureNotifier, PathOfPleasureState>((ref) {
  return PathOfPleasureNotifier();
});
