import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/ludus_repository.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// VELVET ROPE - The Spicy Truth or Dare
/// Provider & State Management
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum CardType { truth, dare }

enum HeatLevel { pg, pg13, r, x }

extension HeatLevelExtension on HeatLevel {
  String get dbValue {
    switch (this) {
      case HeatLevel.pg: return 'PG';
      case HeatLevel.pg13: return 'PG-13';
      case HeatLevel.r: return 'R';
      case HeatLevel.x: return 'X';
    }
  }
  
  String get displayName {
    switch (this) {
      case HeatLevel.pg: return '🟢 Social';
      case HeatLevel.pg13: return '🟡 Sensual';
      case HeatLevel.r: return '🔴 Explicit';
      case HeatLevel.x: return '⚫ Extreme';
    }
  }
  
  Color get color {
    switch (this) {
      case HeatLevel.pg: return Colors.green;
      case HeatLevel.pg13: return Colors.orange;
      case HeatLevel.r: return const Color(0xFFDC143C);
      case HeatLevel.x: return Colors.black;
    }
  }
}

enum VelvetCategory { icebreaker, physical, deep, kinky }

enum VelvetPhase {
  lobby,        // Setting up players and heat level
  spinning,     // Wheel is spinning
  selecting,    // Player choosing Truth or Dare
  revealing,    // Card flip animation
  reading,      // Player reads/performs the prompt
  results,      // Game over stats
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class VelvetRopeCard {
  final String id;
  final CardType type;
  final String text;
  final HeatLevel heatLevel;
  final VelvetCategory category;
  
  const VelvetRopeCard({
    required this.id,
    required this.type,
    required this.text,
    required this.heatLevel,
    required this.category,
  });
  
  /// Ethereal Blue for Truth, Burning Crimson for Dare
  Color get typeColor => type == CardType.truth
      ? const Color(0xFF4A9EFF)   // Ethereal Blue
      : const Color(0xFFDC143C);   // Burning Crimson
  
  String get typeEmoji => type == CardType.truth ? '🔮' : '🔥';
  
  factory VelvetRopeCard.fromJson(Map<String, dynamic> json) {
    return VelvetRopeCard(
      id: json['id'] as String,
      type: json['type'] == 'truth' ? CardType.truth : CardType.dare,
      text: json['text'] as String,
      heatLevel: _parseHeatLevel(json['heat_level'] as String),
      category: _parseCategory(json['category'] as String),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type == CardType.truth ? 'truth' : 'dare',
    'text': text,
    'heat_level': heatLevel.dbValue,
    'category': category.name,
  };
  
  static HeatLevel _parseHeatLevel(String value) {
    switch (value) {
      case 'PG': return HeatLevel.pg;
      case 'PG-13': return HeatLevel.pg13;
      case 'R': return HeatLevel.r;
      case 'X': return HeatLevel.x;
      default: return HeatLevel.pg;
    }
  }
  
  static VelvetCategory _parseCategory(String value) {
    switch (value) {
      case 'icebreaker': return VelvetCategory.icebreaker;
      case 'physical': return VelvetCategory.physical;
      case 'deep': return VelvetCategory.deep;
      case 'kinky': return VelvetCategory.kinky;
      default: return VelvetCategory.icebreaker;
    }
  }
}

class VelvetPlayer {
  final String name;
  final Color color;
  int truthsCompleted;
  int daresCompleted;
  int skips;
  
  VelvetPlayer({
    required this.name,
    required this.color,
    this.truthsCompleted = 0,
    this.daresCompleted = 0,
    this.skips = 0,
  });
  
  int get totalCompleted => truthsCompleted + daresCompleted;
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════

class VelvetRopeState {
  final VelvetPhase phase;
  final List<VelvetPlayer> players;
  final int selectedPlayerIndex;
  final CardType? selectedType;
  final VelvetRopeCard? currentCard;
  final List<VelvetRopeCard> truthDeck;
  final List<VelvetRopeCard> dareDeck;
  final int truthIndex;
  final int dareIndex;
  final HeatLevel heatLevel;
  final int totalSpins;
  final bool isLoading;
  final bool isDemoMode;
  final String? sessionId;
  final DateTime? startTime;
  
  const VelvetRopeState({
    this.phase = VelvetPhase.lobby,
    this.players = const [],
    this.selectedPlayerIndex = -1,
    this.selectedType,
    this.currentCard,
    this.truthDeck = const [],
    this.dareDeck = const [],
    this.truthIndex = 0,
    this.dareIndex = 0,
    this.heatLevel = HeatLevel.pg,
    this.totalSpins = 0,
    this.isLoading = false,
    this.isDemoMode = true,
    this.sessionId,
    this.startTime,
  });
  
  VelvetPlayer? get selectedPlayer => 
      selectedPlayerIndex >= 0 && selectedPlayerIndex < players.length
          ? players[selectedPlayerIndex]
          : null;
  
  int get totalTruths => players.fold(0, (sum, p) => sum + p.truthsCompleted);
  int get totalDares => players.fold(0, (sum, p) => sum + p.daresCompleted);
  int get totalSkips => players.fold(0, (sum, p) => sum + p.skips);
  
  VelvetRopeState copyWith({
    VelvetPhase? phase,
    List<VelvetPlayer>? players,
    int? selectedPlayerIndex,
    CardType? selectedType,
    VelvetRopeCard? currentCard,
    List<VelvetRopeCard>? truthDeck,
    List<VelvetRopeCard>? dareDeck,
    int? truthIndex,
    int? dareIndex,
    HeatLevel? heatLevel,
    int? totalSpins,
    bool? isLoading,
    bool? isDemoMode,
    String? sessionId,
    DateTime? startTime,
  }) {
    return VelvetRopeState(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      selectedPlayerIndex: selectedPlayerIndex ?? this.selectedPlayerIndex,
      selectedType: selectedType ?? this.selectedType,
      currentCard: currentCard ?? this.currentCard,
      truthDeck: truthDeck ?? this.truthDeck,
      dareDeck: dareDeck ?? this.dareDeck,
      truthIndex: truthIndex ?? this.truthIndex,
      dareIndex: dareIndex ?? this.dareIndex,
      heatLevel: heatLevel ?? this.heatLevel,
      totalSpins: totalSpins ?? this.totalSpins,
      isLoading: isLoading ?? this.isLoading,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class VelvetRopeNotifier extends StateNotifier<VelvetRopeState> {
  final LudusRepository _repository;
  
  VelvetRopeNotifier(this._repository) : super(const VelvetRopeState());
  
  // Player colors for the wheel
  static const _playerColors = [
    Color(0xFF4A9EFF), // Ethereal Blue
    Color(0xFFDC143C), // Crimson
    Color(0xFF9B59B6), // Purple
    Color(0xFF2ECC71), // Emerald
    Color(0xFFF39C12), // Gold
    Color(0xFF1ABC9C), // Teal
    Color(0xFFE74C3C), // Red
    Color(0xFF3498DB), // Sky Blue
  ];
  
  void addPlayer(String name) {
    if (name.trim().isEmpty || state.players.length >= 8) return;
    
    final color = _playerColors[state.players.length % _playerColors.length];
    final player = VelvetPlayer(name: name.trim(), color: color);
    
    state = state.copyWith(
      players: [...state.players, player],
    );
  }
  
  void removePlayer(int index) {
    if (index < 0 || index >= state.players.length) return;
    
    final updated = [...state.players];
    updated.removeAt(index);
    state = state.copyWith(players: updated);
  }
  
  void setHeatLevel(HeatLevel level) {
    state = state.copyWith(heatLevel: level);
  }
  
  Future<void> startGame() async {
    if (state.players.length < 2) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      // Fetch cards from database
      final cards = await _repository.getVelvetRopeCards(state.heatLevel.dbValue);
      
      if (cards.isNotEmpty) {
        final truths = cards.where((c) => c.type == CardType.truth).toList()..shuffle();
        final dares = cards.where((c) => c.type == CardType.dare).toList()..shuffle();
        
        state = state.copyWith(
          phase: VelvetPhase.spinning,
          truthDeck: truths,
          dareDeck: dares,
          isDemoMode: false,
          isLoading: false,
          startTime: DateTime.now(),
        );
      } else {
        // Fallback to demo mode
        _loadDemoCards();
      }
    } catch (e) {
      // Fallback to demo mode
      _loadDemoCards();
    }
  }
  
  void _loadDemoCards() {
    final demoCards = _getDemoCards(state.heatLevel);
    final truths = demoCards.where((c) => c.type == CardType.truth).toList()..shuffle();
    final dares = demoCards.where((c) => c.type == CardType.dare).toList()..shuffle();
    
    state = state.copyWith(
      phase: VelvetPhase.spinning,
      truthDeck: truths,
      dareDeck: dares,
      isDemoMode: true,
      isLoading: false,
      startTime: DateTime.now(),
    );
  }
  
  void spinComplete(int playerIndex) {
    state = state.copyWith(
      phase: VelvetPhase.selecting,
      selectedPlayerIndex: playerIndex,
      totalSpins: state.totalSpins + 1,
    );
  }
  
  void selectType(CardType type) {
    // Get next card from appropriate deck
    VelvetRopeCard? card;
    int newIndex;
    
    if (type == CardType.truth) {
      if (state.truthDeck.isEmpty) return;
      newIndex = state.truthIndex % state.truthDeck.length;
      card = state.truthDeck[newIndex];
      state = state.copyWith(
        selectedType: type,
        currentCard: card,
        truthIndex: newIndex + 1,
        phase: VelvetPhase.revealing,
      );
    } else {
      if (state.dareDeck.isEmpty) return;
      newIndex = state.dareIndex % state.dareDeck.length;
      card = state.dareDeck[newIndex];
      state = state.copyWith(
        selectedType: type,
        currentCard: card,
        dareIndex: newIndex + 1,
        phase: VelvetPhase.revealing,
      );
    }
  }
  
  void cardRevealed() {
    state = state.copyWith(phase: VelvetPhase.reading);
  }
  
  void completeCard() {
    if (state.selectedPlayer == null || state.currentCard == null) return;
    
    final players = [...state.players];
    final player = players[state.selectedPlayerIndex];
    
    if (state.currentCard!.type == CardType.truth) {
      player.truthsCompleted++;
    } else {
      player.daresCompleted++;
    }
    
    state = state.copyWith(
      players: players,
      phase: VelvetPhase.spinning,
      selectedPlayerIndex: -1,
      selectedType: null,
      currentCard: null,
    );
  }
  
  void skipCard() {
    if (state.selectedPlayer == null) return;
    
    final players = [...state.players];
    players[state.selectedPlayerIndex].skips++;
    
    state = state.copyWith(
      players: players,
      phase: VelvetPhase.spinning,
      selectedPlayerIndex: -1,
      selectedType: null,
      currentCard: null,
    );
  }
  
  void endGame() {
    state = state.copyWith(phase: VelvetPhase.results);
  }
  
  void reset() {
    state = const VelvetRopeState();
  }
  
  void backToLobby() {
    state = state.copyWith(
      phase: VelvetPhase.lobby,
      selectedPlayerIndex: -1,
      selectedType: null,
      currentCard: null,
      totalSpins: 0,
    );
    
    // Reset player stats
    for (final player in state.players) {
      player.truthsCompleted = 0;
      player.daresCompleted = 0;
      player.skips = 0;
    }
  }
  
  // ═════════════════════════════════════════════════════════════════════════
  // DEMO MODE CARDS
  // ═════════════════════════════════════════════════════════════════════════
  
  List<VelvetRopeCard> _getDemoCards(HeatLevel maxHeat) {
    final cards = <VelvetRopeCard>[];
    final random = Random();
    
    // PG cards (always included)
    cards.addAll([
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'What is the most embarrassing thing in your search history right now?', heatLevel: HeatLevel.pg, category: VelvetCategory.icebreaker),
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'What\'s your most irrational fear that you\'ve never told anyone?', heatLevel: HeatLevel.pg, category: VelvetCategory.icebreaker),
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'If you could read anyone\'s mind in this room for 60 seconds, whose would it be?', heatLevel: HeatLevel.pg, category: VelvetCategory.icebreaker),
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'What song do you secretly listen to that would ruin your reputation?', heatLevel: HeatLevel.pg, category: VelvetCategory.icebreaker),
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'What\'s the pettiest reason you stopped talking to someone?', heatLevel: HeatLevel.pg, category: VelvetCategory.icebreaker),
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Let the group DM your crush only using emojis.', heatLevel: HeatLevel.pg, category: VelvetCategory.icebreaker),
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Talk with a fake accent for the next 2 rounds.', heatLevel: HeatLevel.pg, category: VelvetCategory.icebreaker),
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Show the last 5 photos in your camera roll. No deleting.', heatLevel: HeatLevel.pg, category: VelvetCategory.icebreaker),
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Do your best impression of someone in this room until they guess who.', heatLevel: HeatLevel.pg, category: VelvetCategory.icebreaker),
      VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Do a fashion show walk across the room like you\'re on a runway.', heatLevel: HeatLevel.pg, category: VelvetCategory.physical),
    ]);
    
    if (maxHeat.index >= HeatLevel.pg13.index) {
      cards.addAll([
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'Describe your favorite way to be touched using only 3 adjectives.', heatLevel: HeatLevel.pg13, category: VelvetCategory.deep),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'What is a "vanilla" act that turns you on more than it should?', heatLevel: HeatLevel.pg13, category: VelvetCategory.deep),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'Rate every person in this room on a scale of 1-10. Be honest.', heatLevel: HeatLevel.pg13, category: VelvetCategory.icebreaker),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'What\'s the most attractive thing about the person to your left?', heatLevel: HeatLevel.pg13, category: VelvetCategory.icebreaker),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Give the person to your left a neck massage for 60 seconds. No talking.', heatLevel: HeatLevel.pg13, category: VelvetCategory.physical),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Make prolonged eye contact with someone for 60 seconds without laughing.', heatLevel: HeatLevel.pg13, category: VelvetCategory.physical),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Slow dance with someone in the room for the duration of one song.', heatLevel: HeatLevel.pg13, category: VelvetCategory.physical),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Give your best "bedroom eyes" to everyone in the room, one by one.', heatLevel: HeatLevel.pg13, category: VelvetCategory.physical),
      ]);
    }
    
    if (maxHeat.index >= HeatLevel.r.index) {
      cards.addAll([
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'What is the best intimate experience you\'ve ever had? Details.', heatLevel: HeatLevel.r, category: VelvetCategory.kinky),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.truth, text: 'If you could have a no-consequences night with anyone here, who and why?', heatLevel: HeatLevel.r, category: VelvetCategory.deep),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Blindfold yourself and guess who is touching your neck.', heatLevel: HeatLevel.r, category: VelvetCategory.physical),
        VelvetRopeCard(id: '${random.nextInt(99999)}', type: CardType.dare, text: 'Sit on the lap of the person the wheel spins to next (if consenting).', heatLevel: HeatLevel.r, category: VelvetCategory.physical),
      ]);
    }
    
    return cards;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final velvetRopeProvider = StateNotifierProvider<VelvetRopeNotifier, VelvetRopeState>((ref) {
  final repository = ref.watch(ludusRepositoryProvider);
  return VelvetRopeNotifier(repository);
});
