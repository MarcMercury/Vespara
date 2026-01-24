import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

/// ════════════════════════════════════════════════════════════════════════════
/// LANE OF LUST - Timeline Style Desire Game
/// Provider & State Management
/// "Shit Happens" meets intimate scenarios
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum LaneGameState {
  idle,       // Not in a game
  lobby,      // Waiting for players
  dealing,    // Initial deal happening
  playing,    // Normal turn
  stealing,   // Steal chain active
  gameOver,   // Winner declared
}

enum LaneCardCategory { vanilla, kinky, romance, wild }

extension LaneCategoryExtension on LaneCardCategory {
  String get displayName {
    switch (this) {
      case LaneCardCategory.vanilla: return '🍦 Vanilla';
      case LaneCardCategory.kinky: return '⛓️ Kinky';
      case LaneCardCategory.romance: return '💕 Romance';
      case LaneCardCategory.wild: return '🔥 Wild';
    }
  }
  
  Color get color {
    switch (this) {
      case LaneCardCategory.vanilla: return const Color(0xFFE8B4D8);
      case LaneCardCategory.kinky: return const Color(0xFF9B59B6);
      case LaneCardCategory.romance: return const Color(0xFFFF6B9D);
      case LaneCardCategory.wild: return const Color(0xFFFF4500);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class LaneCard {
  final String id;
  final String text;
  final int desireIndex; // 1-100 (The "correct answer")
  final LaneCardCategory category;
  
  const LaneCard({
    required this.id,
    required this.text,
    required this.desireIndex,
    required this.category,
  });
  
  factory LaneCard.fromJson(Map<String, dynamic> json) {
    return LaneCard(
      id: json['id'] as String,
      text: json['text'] as String,
      desireIndex: json['desire_index'] as int,
      category: _parseCategory(json['category'] as String),
    );
  }
  
  static LaneCardCategory _parseCategory(String value) {
    switch (value.toLowerCase()) {
      case 'kinky': return LaneCardCategory.kinky;
      case 'romance': return LaneCardCategory.romance;
      case 'wild': return LaneCardCategory.wild;
      default: return LaneCardCategory.vanilla;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'desire_index': desireIndex,
    'category': category.name,
  };
  
  /// Color gradient based on desire index
  Color get indexColor {
    if (desireIndex <= 30) return const Color(0xFF87CEEB); // Light blue - mild
    if (desireIndex <= 50) return const Color(0xFFFFD700); // Gold - medium
    if (desireIndex <= 75) return const Color(0xFFFF8C00); // Orange - hot
    return const Color(0xFFDC143C); // Crimson - extreme
  }
}

class LanePlayer {
  final String id;
  final String oduserId;
  final String displayName;
  final Color avatarColor;
  final int playerOrder;
  final bool isHost;
  List<LaneCard> hand; // The player's "Lane" - sorted by desireIndex
  
  LanePlayer({
    required this.id,
    required this.oduserId,
    required this.displayName,
    required this.avatarColor,
    required this.playerOrder,
    this.isHost = false,
    List<LaneCard>? hand,
  }) : hand = hand ?? [];
  
  int get laneLength => hand.length;
  
  factory LanePlayer.fromJson(Map<String, dynamic> json) {
    final handJson = json['hand'] as List<dynamic>? ?? [];
    return LanePlayer(
      id: json['id'] as String,
      oduserId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      avatarColor: _parseColor(json['avatar_color'] as String?),
      playerOrder: json['player_order'] as int,
      isHost: json['is_host'] as bool? ?? false,
      hand: handJson.map((c) => LaneCard.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }
  
  static Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFF4A9EFF);
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
  
  /// Sort hand by desire index
  void sortHand() {
    hand.sort((a, b) => a.desireIndex.compareTo(b.desireIndex));
  }
  
  /// Check if a card placement is valid
  bool isValidPlacement(LaneCard card, int insertIndex) {
    // Get neighbors
    final leftIndex = insertIndex > 0 ? hand[insertIndex - 1].desireIndex : 0;
    final rightIndex = insertIndex < hand.length ? hand[insertIndex].desireIndex : 101;
    
    return card.desireIndex > leftIndex && card.desireIndex < rightIndex;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME STATE
// ═══════════════════════════════════════════════════════════════════════════

class LaneOfLustState {
  final LaneGameState gameState;
  final String? sessionId;
  final String? roomCode;
  final List<LanePlayer> players;
  final String? currentPlayerId; // This device's player ID
  final bool isHost;
  
  // Turn management
  final int currentPlayerIndex; // Whose turn it is
  final LaneCard? mysteryCard; // Card being placed
  final bool isRevealed; // Has the card been revealed?
  final int stealChainIndex; // Who's trying to steal (during STEALING phase)
  
  // Deck
  final List<LaneCard> deck; // Remaining cards
  final List<LaneCard> discarded; // Discarded cards
  
  // Game settings
  final int winTarget;
  final String? winnerId;
  
  // UI State
  final bool isLoading;
  final String? error;
  final bool isDemoMode;
  final PlacementResult? lastPlacementResult;
  
  const LaneOfLustState({
    this.gameState = LaneGameState.idle,
    this.sessionId,
    this.roomCode,
    this.players = const [],
    this.currentPlayerId,
    this.isHost = false,
    this.currentPlayerIndex = 0,
    this.mysteryCard,
    this.isRevealed = false,
    this.stealChainIndex = 0,
    this.deck = const [],
    this.discarded = const [],
    this.winTarget = 10,
    this.winnerId,
    this.isLoading = false,
    this.error,
    this.isDemoMode = false,
    this.lastPlacementResult,
  });
  
  LanePlayer? get me => currentPlayerId == null 
      ? null 
      : players.where((p) => p.id == currentPlayerId).firstOrNull;
  
  LanePlayer? get currentPlayer => players.isNotEmpty && currentPlayerIndex < players.length
      ? players[currentPlayerIndex]
      : null;
  
  LanePlayer? get stealingPlayer => gameState == LaneGameState.stealing && stealChainIndex < players.length
      ? players[stealChainIndex]
      : null;
  
  bool get isMyTurn {
    // In demo mode, it's always "your turn" since all players are on same device
    if (isDemoMode) return true;
    
    if (gameState == LaneGameState.stealing) {
      return stealingPlayer?.id == currentPlayerId;
    }
    return currentPlayer?.id == currentPlayerId;
  }
  
  LanePlayer? get winner => winnerId == null 
      ? null 
      : players.where((p) => p.id == winnerId).firstOrNull;
  
  LaneOfLustState copyWith({
    LaneGameState? gameState,
    String? sessionId,
    String? roomCode,
    List<LanePlayer>? players,
    String? currentPlayerId,
    bool? isHost,
    int? currentPlayerIndex,
    LaneCard? mysteryCard,
    bool? isRevealed,
    int? stealChainIndex,
    List<LaneCard>? deck,
    List<LaneCard>? discarded,
    int? winTarget,
    String? winnerId,
    bool? isLoading,
    String? error,
    bool? isDemoMode,
    PlacementResult? lastPlacementResult,
  }) {
    return LaneOfLustState(
      gameState: gameState ?? this.gameState,
      sessionId: sessionId ?? this.sessionId,
      roomCode: roomCode ?? this.roomCode,
      players: players ?? this.players,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      isHost: isHost ?? this.isHost,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      mysteryCard: mysteryCard ?? this.mysteryCard,
      isRevealed: isRevealed ?? this.isRevealed,
      stealChainIndex: stealChainIndex ?? this.stealChainIndex,
      deck: deck ?? this.deck,
      discarded: discarded ?? this.discarded,
      winTarget: winTarget ?? this.winTarget,
      winnerId: winnerId ?? this.winnerId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      lastPlacementResult: lastPlacementResult,
    );
  }
  
  LaneOfLustState clearMysteryCard() {
    return LaneOfLustState(
      gameState: gameState,
      sessionId: sessionId,
      roomCode: roomCode,
      players: players,
      currentPlayerId: currentPlayerId,
      isHost: isHost,
      currentPlayerIndex: currentPlayerIndex,
      mysteryCard: null,
      isRevealed: false,
      stealChainIndex: stealChainIndex,
      deck: deck,
      discarded: discarded,
      winTarget: winTarget,
      winnerId: winnerId,
      isLoading: isLoading,
      error: error,
      isDemoMode: isDemoMode,
      lastPlacementResult: lastPlacementResult,
    );
  }
}

class PlacementResult {
  final bool success;
  final LaneCard card;
  final int attemptedPosition;
  
  const PlacementResult({
    required this.success,
    required this.card,
    required this.attemptedPosition,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class LaneOfLustNotifier extends StateNotifier<LaneOfLustState> {
  LaneOfLustNotifier() : super(const LaneOfLustState());
  
  bool _disposed = false;
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
  
  static const _playerColors = [
    Color(0xFF4A9EFF), Color(0xFFDC143C), Color(0xFF9B59B6), Color(0xFF2ECC71),
    Color(0xFFF39C12), Color(0xFF1ABC9C), Color(0xFFE74C3C), Color(0xFF3498DB),
  ];
  
  // ═════════════════════════════════════════════════════════════════════════
  // LOBBY
  // ═════════════════════════════════════════════════════════════════════════
  
  Future<void> hostGame(String hostName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final roomCode = _generateRoomCode();
      final hostId = 'host_${DateTime.now().millisecondsSinceEpoch}';
      final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      
      final hostPlayer = LanePlayer(
        id: playerId,
        oduserId: hostId,
        displayName: hostName,
        avatarColor: _playerColors[0],
        playerOrder: 0,
        isHost: true,
      );
      
      state = state.copyWith(
        gameState: LaneGameState.lobby,
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
  
  void addLocalPlayer(String name) {
    if (name.trim().isEmpty || state.players.length >= 8) return;
    
    final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}_${state.players.length}';
    final newPlayer = LanePlayer(
      id: playerId,
      oduserId: 'local_$playerId',
      displayName: name.trim(),
      avatarColor: _playerColors[state.players.length % _playerColors.length],
      playerOrder: state.players.length,
      isHost: false,
    );
    
    state = state.copyWith(players: [...state.players, newPlayer]);
  }
  
  void removePlayer(int index) {
    if (index < 0 || index >= state.players.length) return;
    if (state.players[index].isHost) return;
    
    final players = [...state.players];
    players.removeAt(index);
    
    // Re-assign player orders
    for (int i = 0; i < players.length; i++) {
      players[i] = LanePlayer(
        id: players[i].id,
        oduserId: players[i].oduserId,
        displayName: players[i].displayName,
        avatarColor: players[i].avatarColor,
        playerOrder: i,
        isHost: players[i].isHost,
        hand: players[i].hand,
      );
    }
    
    state = state.copyWith(players: players);
  }
  
  String _generateRoomCode() {
    final words = ['LUST', 'HEAT', 'FIRE', 'BURN', 'WILD', 'VIBE', 'EDGE', 'DARE',
                   'RUSH', 'SILK', 'GLOW', 'PEAK', 'SYNC', 'BOND', 'FLUX', 'WANT'];
    final word = words[Random().nextInt(words.length)];
    final suffix = (Random().nextInt(90) + 10).toString();
    return '$word$suffix';
  }
  
  // ═════════════════════════════════════════════════════════════════════════
  // GAME START
  // ═════════════════════════════════════════════════════════════════════════
  
  Future<void> startGame() async {
    if (!state.isHost || state.players.length < 2) return;
    
    state = state.copyWith(gameState: LaneGameState.dealing, isLoading: true);
    
    try {
      // Generate shuffled deck
      final deck = _generateDemoDeck();
      deck.shuffle();
      
      final players = [...state.players];
      final deckList = [...deck];
      
      // Deal 3 cards to each player
      for (final player in players) {
        final dealt = <LaneCard>[];
        for (int i = 0; i < 3 && deckList.isNotEmpty; i++) {
          dealt.add(deckList.removeAt(0));
        }
        player.hand = dealt;
        player.sortHand();
      }
      
      // Short delay for dealing animation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Draw first mystery card
      final mysteryCard = deckList.isNotEmpty ? deckList.removeAt(0) : null;
      
      state = state.copyWith(
        gameState: LaneGameState.playing,
        players: players,
        deck: deckList,
        mysteryCard: mysteryCard,
        isRevealed: false,
        currentPlayerIndex: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  // ═════════════════════════════════════════════════════════════════════════
  // TURN MECHANICS
  // ═════════════════════════════════════════════════════════════════════════
  
  /// Player attempts to place the mystery card at a position
  void attemptPlacement(int insertIndex) {
    if (!state.isMyTurn || state.mysteryCard == null) return;
    
    final card = state.mysteryCard!;
    final players = [...state.players];
    
    // Find the active player (current or stealing)
    final activePlayerIndex = state.gameState == LaneGameState.stealing
        ? state.stealChainIndex
        : state.currentPlayerIndex;
    
    final player = players[activePlayerIndex];
    
    // Check if placement is valid
    final isValid = player.isValidPlacement(card, insertIndex);
    
    // Reveal the card
    state = state.copyWith(
      isRevealed: true,
      lastPlacementResult: PlacementResult(
        success: isValid,
        card: card,
        attemptedPosition: insertIndex,
      ),
    );
    
    // Process result after animation delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_disposed) return;
      
      if (isValid) {
        _handleSuccessfulPlacement(player, card, insertIndex);
      } else {
        _handleFailedPlacement(card);
      }
    });
  }
  
  void _handleSuccessfulPlacement(LanePlayer player, LaneCard card, int insertIndex) {
    final players = [...state.players];
    final playerIndex = players.indexWhere((p) => p.id == player.id);
    
    if (playerIndex == -1) return;
    
    // Add card to hand and sort
    players[playerIndex].hand.insert(insertIndex, card);
    
    // Check win condition
    if (players[playerIndex].laneLength >= state.winTarget) {
      state = state.copyWith(
        gameState: LaneGameState.gameOver,
        players: players,
        winnerId: player.id,
        lastPlacementResult: null,
      );
      return;
    }
    
    // Draw next card and advance turn
    final deck = [...state.deck];
    final mysteryCard = deck.isNotEmpty ? deck.removeAt(0) : null;
    
    // If no cards left, game over (most cards wins)
    if (mysteryCard == null) {
      final winner = players.reduce((a, b) => a.laneLength > b.laneLength ? a : b);
      state = state.copyWith(
        gameState: LaneGameState.gameOver,
        players: players,
        deck: deck,
        winnerId: winner.id,
        lastPlacementResult: null,
      );
      return;
    }
    
    final nextPlayerIndex = (state.currentPlayerIndex + 1) % players.length;
    
    state = state.copyWith(
      gameState: LaneGameState.playing,
      players: players,
      deck: deck,
      mysteryCard: mysteryCard,
      isRevealed: false,
      currentPlayerIndex: nextPlayerIndex,
      stealChainIndex: 0,
      lastPlacementResult: null,
    );
  }
  
  void _handleFailedPlacement(LaneCard card) {
    final players = state.players;
    
    // Start steal chain with next player
    int nextStealIndex = (state.gameState == LaneGameState.stealing)
        ? (state.stealChainIndex + 1) % players.length
        : (state.currentPlayerIndex + 1) % players.length;
    
    // Check if we've gone full circle (everyone failed)
    final originalPlayerIndex = state.currentPlayerIndex;
    if (nextStealIndex == originalPlayerIndex) {
      // Discard the card, move to next turn
      _discardAndNextTurn(card);
      return;
    }
    
    // Pass to next player for steal attempt
    state = state.copyWith(
      gameState: LaneGameState.stealing,
      stealChainIndex: nextStealIndex,
      isRevealed: false,
      lastPlacementResult: null,
    );
  }
  
  void _discardAndNextTurn(LaneCard card) {
    final deck = [...state.deck];
    final discarded = [...state.discarded, card];
    
    final mysteryCard = deck.isNotEmpty ? deck.removeAt(0) : null;
    
    if (mysteryCard == null) {
      // Game over - most cards wins
      final winner = state.players.reduce((a, b) => a.laneLength > b.laneLength ? a : b);
      state = state.copyWith(
        gameState: LaneGameState.gameOver,
        deck: deck,
        discarded: discarded,
        winnerId: winner.id,
        lastPlacementResult: null,
      );
      return;
    }
    
    final nextPlayerIndex = (state.currentPlayerIndex + 1) % state.players.length;
    
    state = state.copyWith(
      gameState: LaneGameState.playing,
      deck: deck,
      discarded: discarded,
      mysteryCard: mysteryCard,
      isRevealed: false,
      currentPlayerIndex: nextPlayerIndex,
      stealChainIndex: 0,
      lastPlacementResult: null,
    );
  }
  
  /// Skip steal attempt (pass to next player)
  void skipSteal() {
    if (state.gameState != LaneGameState.stealing) return;
    if (!state.isMyTurn) return;
    
    _handleFailedPlacement(state.mysteryCard!);
  }
  
  // ═════════════════════════════════════════════════════════════════════════
  // GAME CONTROL
  // ═════════════════════════════════════════════════════════════════════════
  
  void playAgain() {
    final players = state.players.map((p) => LanePlayer(
      id: p.id,
      oduserId: p.oduserId,
      displayName: p.displayName,
      avatarColor: p.avatarColor,
      playerOrder: p.playerOrder,
      isHost: p.isHost,
      hand: [],
    )).toList();
    
    state = state.copyWith(
      gameState: LaneGameState.lobby,
      players: players,
      currentPlayerIndex: 0,
      deck: [],
      discarded: [],
      winnerId: null,
      lastPlacementResult: null,
    );
  }
  
  void exitGame() {
    state = const LaneOfLustState();
  }
  
  // ═════════════════════════════════════════════════════════════════════════
  // DEMO DECK
  // ═════════════════════════════════════════════════════════════════════════
  
  List<LaneCard> _generateDemoDeck() {
    final random = Random();
    final id = () => 'card_${random.nextInt(99999)}';
    
    return [
      // Very Low (1-10) - Awkward/Non-sexual
      LaneCard(id: id(), text: 'A peck on the forehead from grandma', desireIndex: 1, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Getting a handshake instead of a hug', desireIndex: 2, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'A quick peck on the cheek', desireIndex: 3, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Brushing hands accidentally', desireIndex: 4, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Sitting next to your crush on the bus', desireIndex: 5, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'A wink from across the room', desireIndex: 6, category: LaneCardCategory.vanilla),
      
      // Low (7-15) - Innocent/Romantic
      LaneCard(id: id(), text: 'Holding hands in a movie theater', desireIndex: 7, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Sharing dessert at dinner', desireIndex: 8, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Playing footsie under the table', desireIndex: 9, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Dancing close at a wedding', desireIndex: 10, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'A long hug that lingers', desireIndex: 11, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Slow dancing in the living room', desireIndex: 12, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'A kiss on the neck', desireIndex: 13, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Receiving a flirty text at work', desireIndex: 14, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'A sensual back massage with oil', desireIndex: 15, category: LaneCardCategory.vanilla),
      
      // Medium-Low (16-25) - Flirty/Early Sexual
      LaneCard(id: id(), text: 'Making out in a parked car', desireIndex: 16, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Skinny dipping at night', desireIndex: 17, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'G-string', desireIndex: 18, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Morning sex that makes you late', desireIndex: 19, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'A night you will never forget', desireIndex: 20, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Shower sex', desireIndex: 21, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Dirty talk that actually works', desireIndex: 22, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Masturbation', desireIndex: 23, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Hand job', desireIndex: 24, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Cunnilingus', desireIndex: 25, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Vaginal sex', desireIndex: 26, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Hair pulling', desireIndex: 27, category: LaneCardCategory.vanilla),
      
      // Medium (28-42) - Standard Sexual
      LaneCard(id: id(), text: 'Blow job', desireIndex: 28, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Sex in a hotel room on vacation', desireIndex: 29, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Masturbation w/toys', desireIndex: 30, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Use Vibrator', desireIndex: 31, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Blow job + Swallow', desireIndex: 32, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Use Sex toy with Partner', desireIndex: 33, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Oral creampie', desireIndex: 34, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Squirting', desireIndex: 35, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Public teasing under the table', desireIndex: 36, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'A weekend getaway to a private cabin', desireIndex: 37, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Foot fetish', desireIndex: 38, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Dildo', desireIndex: 39, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Mile High Club membership', desireIndex: 40, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'All-night session with no interruptions', desireIndex: 41, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Face sitting', desireIndex: 42, category: LaneCardCategory.vanilla),
      
      // Medium-High (43-57) - Adventurous
      LaneCard(id: id(), text: 'Cock ring', desireIndex: 43, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Cum shot Facial', desireIndex: 44, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Blindfolded and at their mercy', desireIndex: 45, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Being dominated (the way you like)', desireIndex: 46, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Nipple clamps', desireIndex: 47, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Prostate massage', desireIndex: 48, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Being worshipped all evening', desireIndex: 49, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'A vacation where you barely leave the room', desireIndex: 50, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Submission', desireIndex: 51, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Voyeurism', desireIndex: 52, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Butt plug', desireIndex: 53, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Being tied up and teased for an hour', desireIndex: 54, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Licking asshole', desireIndex: 55, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Bondage', desireIndex: 56, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Dom/sub', desireIndex: 57, category: LaneCardCategory.vanilla),
      
      // High (58-72) - Kinky
      LaneCard(id: id(), text: 'Anal sex', desireIndex: 58, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Condom fetish - Eroticize condom use', desireIndex: 59, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Threesome', desireIndex: 60, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'FFM', desireIndex: 61, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'MMF', desireIndex: 62, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'MFM', desireIndex: 63, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Bear sex', desireIndex: 64, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'FMF', desireIndex: 65, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Tribadism', desireIndex: 66, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Strap-on - FF', desireIndex: 67, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Pegging', desireIndex: 68, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Shibari', desireIndex: 69, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Bondage spread', desireIndex: 70, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Flogger', desireIndex: 71, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Munch', desireIndex: 72, category: LaneCardCategory.vanilla),
      
      // Very High (73-87) - Very Kinky
      LaneCard(id: id(), text: 'Impact play', desireIndex: 73, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Whipping', desireIndex: 74, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Ball gag', desireIndex: 75, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Orgasm denial', desireIndex: 76, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'MFMF', desireIndex: 77, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Tantric Witchcraft', desireIndex: 78, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Attend a kink club', desireIndex: 79, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Double penetration', desireIndex: 80, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'A surprise threesome with consent', desireIndex: 81, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Pain play', desireIndex: 82, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'BDSM', desireIndex: 83, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Master/slave play', desireIndex: 84, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'DDLG - Role-play caregiver dynamics', desireIndex: 85, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Leather daddy', desireIndex: 86, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Pup play', desireIndex: 87, category: LaneCardCategory.vanilla),
      
      // Extreme (88-96) - Extreme Kink
      LaneCard(id: id(), text: 'Anal beads', desireIndex: 88, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Group sex', desireIndex: 89, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Butt plug gag', desireIndex: 90, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Sadomasochism', desireIndex: 91, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Gorean', desireIndex: 92, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Electrosex', desireIndex: 93, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Futa', desireIndex: 94, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'MMMMMMMMMMF', desireIndex: 95, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Cock and ball torture', desireIndex: 96, category: LaneCardCategory.vanilla),
      
      // Most Extreme (97-100)
      LaneCard(id: id(), text: 'Gang bang', desireIndex: 97, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Gay for pay', desireIndex: 98, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Enema play', desireIndex: 99, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Fisting', desireIndex: 100, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Anal fisting', desireIndex: 101, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Breathplay', desireIndex: 102, category: LaneCardCategory.vanilla),
      LaneCard(id: id(), text: 'Autoerotic asphyxiation', desireIndex: 103, category: LaneCardCategory.vanilla),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final laneOfLustProvider = StateNotifierProvider<LaneOfLustNotifier, LaneOfLustState>((ref) {
  return LaneOfLustNotifier();
});
