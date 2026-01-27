import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/ludus_repository.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SHARE OR DARE - Spin the Wheel, Pick Your Poison
/// Provider & State Management
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS & TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum CardType { share, dare }

enum HeatLevel { pg, pg13, r, x }

extension HeatLevelExtension on HeatLevel {
  String get dbValue {
    switch (this) {
      case HeatLevel.pg:
        return 'PG';
      case HeatLevel.pg13:
        return 'PG-13';
      case HeatLevel.r:
        return 'R';
      case HeatLevel.x:
        return 'X';
    }
  }

  String get displayName {
    switch (this) {
      case HeatLevel.pg:
        return '🟢 Social';
      case HeatLevel.pg13:
        return '🟡 Sensual';
      case HeatLevel.r:
        return '🔴 Explicit';
      case HeatLevel.x:
        return '⚫ Extreme';
    }
  }

  Color get color {
    switch (this) {
      case HeatLevel.pg:
        return Colors.green;
      case HeatLevel.pg13:
        return Colors.orange;
      case HeatLevel.r:
        return const Color(0xFFDC143C);
      case HeatLevel.x:
        return Colors.black;
    }
  }
}

enum ShareOrDareCategory { icebreaker, physical, deep, kinky }

enum ShareOrDarePhase {
  lobby, // Setting up players and heat level
  spinning, // Wheel is spinning
  selecting, // Player choosing Share or Dare
  revealing, // Card flip animation
  reading, // Player reads/performs the prompt
  results, // Game over stats
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class ShareOrDareCard {
  const ShareOrDareCard({
    required this.id,
    required this.type,
    required this.text,
    required this.heatLevel,
    required this.category,
  });

  factory ShareOrDareCard.fromJson(Map<String, dynamic> json) =>
      ShareOrDareCard(
        id: json['id'] as String,
        type: json['type'] == 'share' ? CardType.share : CardType.dare,
        text: json['text'] as String,
        heatLevel: _parseHeatLevel(json['heat_level'] as String),
        category: _parseCategory(json['category'] as String),
      );
  final String id;
  final CardType type;
  final String text;
  final HeatLevel heatLevel;
  final ShareOrDareCategory category;

  /// Ethereal Blue for Share, Burning Crimson for Dare
  Color get typeColor => type == CardType.share
      ? const Color(0xFF4A9EFF) // Ethereal Blue
      : const Color(0xFFDC143C); // Burning Crimson

  String get typeEmoji => type == CardType.share ? '🔮' : '🔥';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type == CardType.share ? 'share' : 'dare',
        'text': text,
        'heat_level': heatLevel.dbValue,
        'category': category.name,
      };

  static HeatLevel _parseHeatLevel(String value) {
    switch (value) {
      case 'PG':
        return HeatLevel.pg;
      case 'PG-13':
        return HeatLevel.pg13;
      case 'R':
        return HeatLevel.r;
      case 'X':
        return HeatLevel.x;
      default:
        return HeatLevel.pg;
    }
  }

  static ShareOrDareCategory _parseCategory(String value) {
    switch (value) {
      case 'icebreaker':
        return ShareOrDareCategory.icebreaker;
      case 'physical':
        return ShareOrDareCategory.physical;
      case 'deep':
        return ShareOrDareCategory.deep;
      case 'kinky':
        return ShareOrDareCategory.kinky;
      default:
        return ShareOrDareCategory.icebreaker;
    }
  }
}

class ShareOrDarePlayer {
  ShareOrDarePlayer({
    required this.name,
    required this.color,
    this.sharesCompleted = 0,
    this.daresCompleted = 0,
    this.skips = 0,
  });
  final String name;
  final Color color;
  int sharesCompleted;
  int daresCompleted;
  int skips;

  int get totalCompleted => sharesCompleted + daresCompleted;
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════

class ShareOrDareState {
  const ShareOrDareState({
    this.phase = ShareOrDarePhase.lobby,
    this.players = const [],
    this.selectedPlayerIndex = -1,
    this.selectedType,
    this.currentCard,
    this.shareDeck = const [],
    this.dareDeck = const [],
    this.shareIndex = 0,
    this.dareIndex = 0,
    this.heatLevel = HeatLevel.pg,
    this.totalSpins = 0,
    this.isLoading = false,
    this.isDemoMode = true,
    this.sessionId,
    this.startTime,
  });
  final ShareOrDarePhase phase;
  final List<ShareOrDarePlayer> players;
  final int selectedPlayerIndex;
  final CardType? selectedType;
  final ShareOrDareCard? currentCard;
  final List<ShareOrDareCard> shareDeck;
  final List<ShareOrDareCard> dareDeck;
  final int shareIndex;
  final int dareIndex;
  final HeatLevel heatLevel;
  final int totalSpins;
  final bool isLoading;
  final bool isDemoMode;
  final String? sessionId;
  final DateTime? startTime;

  ShareOrDarePlayer? get selectedPlayer =>
      selectedPlayerIndex >= 0 && selectedPlayerIndex < players.length
          ? players[selectedPlayerIndex]
          : null;

  int get totalShares => players.fold(0, (sum, p) => sum + p.sharesCompleted);
  int get totalDares => players.fold(0, (sum, p) => sum + p.daresCompleted);
  int get totalSkips => players.fold(0, (sum, p) => sum + p.skips);

  ShareOrDareState copyWith({
    ShareOrDarePhase? phase,
    List<ShareOrDarePlayer>? players,
    int? selectedPlayerIndex,
    CardType? selectedType,
    ShareOrDareCard? currentCard,
    List<ShareOrDareCard>? shareDeck,
    List<ShareOrDareCard>? dareDeck,
    int? shareIndex,
    int? dareIndex,
    HeatLevel? heatLevel,
    int? totalSpins,
    bool? isLoading,
    bool? isDemoMode,
    String? sessionId,
    DateTime? startTime,
  }) =>
      ShareOrDareState(
        phase: phase ?? this.phase,
        players: players ?? this.players,
        selectedPlayerIndex: selectedPlayerIndex ?? this.selectedPlayerIndex,
        selectedType: selectedType ?? this.selectedType,
        currentCard: currentCard ?? this.currentCard,
        shareDeck: shareDeck ?? this.shareDeck,
        dareDeck: dareDeck ?? this.dareDeck,
        shareIndex: shareIndex ?? this.shareIndex,
        dareIndex: dareIndex ?? this.dareIndex,
        heatLevel: heatLevel ?? this.heatLevel,
        totalSpins: totalSpins ?? this.totalSpins,
        isLoading: isLoading ?? this.isLoading,
        isDemoMode: isDemoMode ?? this.isDemoMode,
        sessionId: sessionId ?? this.sessionId,
        startTime: startTime ?? this.startTime,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class ShareOrDareNotifier extends StateNotifier<ShareOrDareState> {
  ShareOrDareNotifier(this._repository) : super(const ShareOrDareState());
  final LudusRepository _repository;

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
    final player = ShareOrDarePlayer(name: name.trim(), color: color);

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
      final cards =
          await _repository.getShareOrDareCards(state.heatLevel.dbValue);

      if (cards.isNotEmpty) {
        final shares = cards.where((c) => c.type == CardType.share).toList()
          ..shuffle();
        final dares = cards.where((c) => c.type == CardType.dare).toList()
          ..shuffle();

        state = state.copyWith(
          phase: ShareOrDarePhase.spinning,
          shareDeck: shares,
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
    final shares = demoCards.where((c) => c.type == CardType.share).toList()
      ..shuffle();
    final dares = demoCards.where((c) => c.type == CardType.dare).toList()
      ..shuffle();

    state = state.copyWith(
      phase: ShareOrDarePhase.spinning,
      shareDeck: shares,
      dareDeck: dares,
      isDemoMode: true,
      isLoading: false,
      startTime: DateTime.now(),
    );
  }

  void spinComplete(int playerIndex) {
    state = state.copyWith(
      phase: ShareOrDarePhase.selecting,
      selectedPlayerIndex: playerIndex,
      totalSpins: state.totalSpins + 1,
    );
  }

  void selectType(CardType type) {
    // Get next card from appropriate deck
    ShareOrDareCard? card;
    int newIndex;

    if (type == CardType.share) {
      // If deck empty, try to reload demo cards first
      if (state.shareDeck.isEmpty) {
        _loadDemoCards();
        if (state.shareDeck.isEmpty) return;
      }
      newIndex = state.shareIndex % state.shareDeck.length;
      card = state.shareDeck[newIndex];
      state = state.copyWith(
        selectedType: type,
        currentCard: card,
        shareIndex: newIndex + 1,
        phase: ShareOrDarePhase.revealing,
      );
    } else {
      // If deck empty, try to reload demo cards first
      if (state.dareDeck.isEmpty) {
        _loadDemoCards();
        if (state.dareDeck.isEmpty) return;
      }
      newIndex = state.dareIndex % state.dareDeck.length;
      card = state.dareDeck[newIndex];
      state = state.copyWith(
        selectedType: type,
        currentCard: card,
        dareIndex: newIndex + 1,
        phase: ShareOrDarePhase.revealing,
      );
    }
  }

  void cardRevealed() {
    state = state.copyWith(phase: ShareOrDarePhase.reading);
  }

  void completeCard() {
    if (state.selectedPlayer == null || state.currentCard == null) return;

    final players = [...state.players];
    final player = players[state.selectedPlayerIndex];

    if (state.currentCard!.type == CardType.share) {
      player.sharesCompleted++;
    } else {
      player.daresCompleted++;
    }

    state = state.copyWith(
      players: players,
      phase: ShareOrDarePhase.spinning,
      selectedPlayerIndex: -1,
    );
  }

  void skipCard() {
    if (state.selectedPlayer == null) return;

    final players = [...state.players];
    players[state.selectedPlayerIndex].skips++;

    state = state.copyWith(
      players: players,
      phase: ShareOrDarePhase.spinning,
      selectedPlayerIndex: -1,
    );
  }

  void endGame() {
    state = state.copyWith(phase: ShareOrDarePhase.results);
  }

  void reset() {
    state = const ShareOrDareState();
  }

  void backToLobby() {
    state = state.copyWith(
      phase: ShareOrDarePhase.lobby,
      selectedPlayerIndex: -1,
      totalSpins: 0,
    );

    // Reset player stats
    for (final player in state.players) {
      player.sharesCompleted = 0;
      player.daresCompleted = 0;
      player.skips = 0;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DEMO MODE CARDS
  // ═════════════════════════════════════════════════════════════════════════

  List<ShareOrDareCard> _getDemoCards(HeatLevel maxHeat) {
    final cards = <ShareOrDareCard>[];
    final random = Random();

    // PG cards (always included)
    cards.addAll([
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.share,
          text:
              'Share the most embarrassing thing in your search history right now.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.icebreaker,),
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.share,
          text:
              'Share your most irrational fear that you\'ve never told anyone.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.icebreaker,),
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.share,
          text: 'Share a secret talent that nobody in this room knows about.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.icebreaker,),
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.share,
          text:
              'Share a guilty pleasure song that would absolutely ruin your reputation.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.icebreaker,),
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.share,
          text: 'Share the pettiest reason you stopped talking to someone.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.icebreaker,),
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.dare,
          text: 'Let the group DM your crush only using emojis.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.icebreaker,),
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.dare,
          text: 'Talk with a fake accent for the next 2 rounds.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.icebreaker,),
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.dare,
          text: 'Show the last 5 photos in your camera roll. No deleting.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.icebreaker,),
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.dare,
          text:
              'Do your best impression of someone in this room until they guess who.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.icebreaker,),
      ShareOrDareCard(
          id: '${random.nextInt(99999)}',
          type: CardType.dare,
          text:
              'Do a fashion show walk across the room like you\'re on a runway.',
          heatLevel: HeatLevel.pg,
          category: ShareOrDareCategory.physical,),
    ]);

    if (maxHeat.index >= HeatLevel.pg13.index) {
      cards.addAll([
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'Share your favorite way to be touched—describe it in 3 adjectives.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'Share a "vanilla" act that secretly turns you on more than it should.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'Share your honest rating of everyone in this room on a scale of 1-10.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.icebreaker,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'Share the most attractive thing about the person to your left.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.icebreaker,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Give the person to your left a neck massage for 60 seconds. No talking.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Make prolonged eye contact with someone for 30 seconds without laughing.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text: 'Slow dance with someone in the room for half a song.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Give your best "bedroom eyes" to everyone in the room, one by one.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Without kissing them, gently press your lips to another player and hold for 15 seconds.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text: 'Massage the inner thigh of another player for 20 seconds.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text: 'Caress the chest of another player very gently.',
            heatLevel: HeatLevel.pg13,
            category: ShareOrDareCategory.physical,),
      ]);
    }

    if (maxHeat.index >= HeatLevel.r.index) {
      cards.addAll([
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'Share the best intimate experience you\'ve ever had—in vivid detail.',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'Share who you\'d choose for a no-consequences night here—and why them.',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text: 'Blindfold yourself and guess who is kissing your neck.',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Sit on the lap of the person the wheel spins to next (if consenting).',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text: 'Motorboat a female in the group.',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text: 'Select 2 players and direct them in a make out scene.',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Crawl under the table (or just crawl) and choose a player to massage the crotch of.',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text: 'Lick the armpit of another player.',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text: '3 Way French Kiss with 2 other players.',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Without penetrating or grabbing - place your hands down the pants and under the underwear of another player.',
            heatLevel: HeatLevel.r,
            category:
                ShareOrDareCategory.physical,), // New explicit SHARE questions
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most adventurous sex act you\'ve ever tried?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intimate thing you\'ve ever shared with a partner?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the biggest sex-related lie you\'ve ever told?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most spontaneous sex you\'ve ever had?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most embarrassing sex-related story you\'ve shared with someone?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the biggest turn-on for you?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most intense orgasm you\'ve ever had?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most unusual place you\'ve ever had sex?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the biggest sex-related fantasy you\'ve ever had?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most memorable sex-related dream you\'ve ever had?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s your favorite BDSM role (dom, sub, switch)?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most creative way you\'ve ever seduced someone?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intimate thing you\'ve ever shared with a stranger?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense emotional connection you\'ve felt with someone?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s your favorite sex position?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most memorable sex-related experience you\'ve ever had?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intimate conversation with a partner about sex?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most intense moment of trust with a partner?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most intense vulnerability with a partner?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense emotional connection with a partner?',
            heatLevel: HeatLevel.r,
            category: ShareOrDareCategory.deep,),
      ]);
    }

    // X-rated (extreme) questions
    if (maxHeat.index >= HeatLevel.x.index) {
      cards.addAll([
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most extreme BDSM experience you\'ve ever had?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense pain you\'ve experienced during sex?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most creative way you\'ve ever used bondage?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most intense sensory experience during sex?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most extreme fetish you\'ve ever explored?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense breathplay experience you\'ve ever had?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense sensory deprivation experience during sex?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense impact play experience you\'ve ever had?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense rope bondage experience you\'ve ever had?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense sex-related experience with a stranger?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense sex-related experience with a group?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most intense sex experience in a public place?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s your favorite BDSM toy or prop?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most intense BDSM scene you\'ve participated in?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most intense BDSM experience with a partner?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most intense BDSM experience with a group?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text: 'What\'s the most intense BDSM experience with a stranger?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.share,
            text:
                'What\'s the most unusual thing you\'ve done to get someone to agree to sex?',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        // ═══════════════════════════════════════════════════════════════════════════
        // EXTREME DARE CHALLENGES - Group Play
        // ═══════════════════════════════════════════════════════════════════════════
        // "Give" Dares - You perform on others
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Strip Tease: Slowly do a strip tease for the group (must get down to underwear). Group chooses the song.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Lap Dance: Give a lap dance to 2 people at the same time. Group chooses the song.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text: 'Massage: Give a massage to 2 other players at once.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Blindfolded Kiss: Blindfold 2 other players and give them each a 1-minute kiss.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Threeway Kiss: Give a 1-minute tongue kiss to 2 other players at the same time.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Finger Play: Give 2 other players a 1-minute finger play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Threeway 69: Pick 2 people and figure out a 696 or 969 position together.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Feet Play: Give 2 other players a 1-minute feet play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Cuddle: Cuddle with 2 other players for 1 minute, arms and legs wrapped around them.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Nipple Play: Give 2 other players a 1-minute nipple play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Anal Play: Give 2 other players a 1-minute anal play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Oral Play: Give 2 other players a 1-minute oral play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Sensual Lick: Sensually lick anywhere on another player\'s body of your choosing.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        // "Receive" Dares - Others perform on you
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Strip Tease: Choose 2 people to give you a strip tease, one item at a time.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Lap Dance: Choose 2 people to give you a lap dance at the same time. Group chooses the song.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Massage: Choose 2 people to give you a 1-minute massage, focusing on your neck and shoulders.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Blindfolded Kiss: Choose 2 people to give you a 1-minute blindfolded kiss.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Threeway Kiss: Choose 2 people to give you a 1-minute tongue kiss at the same time.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Finger Play: Choose 2 people to give you a 1-minute finger play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Threeway 69: Choose 2 people and engage in a 696 or 969 position with them.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Feet Play: Choose 2 people to give you a 1-minute feet play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Cuddle: Choose 2 people to cuddle with you for 1 minute, arms and legs wrapped around you.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.physical,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Nipple Play: Choose 2 people to give you a 1-minute nipple play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Anal Play: Choose 2 people to give you a 1-minute anal play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Oral Play: Choose 2 people to give you a 1-minute oral play session.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Sensual Lick: Choose 2 people to sensually lick anywhere on your body.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
        ShareOrDareCard(
            id: '${random.nextInt(99999)}',
            type: CardType.dare,
            text:
                'Sensual Squeeze: Choose 2 people to give you a 1-minute sensual squeeze, focusing on your breasts and ass.',
            heatLevel: HeatLevel.x,
            category: ShareOrDareCategory.kinky,),
      ]);
    }

    return cards;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final shareOrDareProvider =
    StateNotifierProvider<ShareOrDareNotifier, ShareOrDareState>((ref) {
  final repository = ref.watch(ludusRepositoryProvider);
  return ShareOrDareNotifier(repository);
});
