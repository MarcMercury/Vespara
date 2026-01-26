import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// ICE BREAKERS GAME PROVIDER
/// "Kill awkward silence without jumping into heavy intimacy"
/// TAG Rating: 40mph / PG-13 / Quickie (15 min)
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Card types for Ice Breakers
enum IceCardType {
  standard,
  wild,
  timed,
  escalation;

  static IceCardType fromString(String value) {
    switch (value) {
      case 'wild':
        return IceCardType.wild;
      case 'timed':
        return IceCardType.timed;
      case 'escalation':
        return IceCardType.escalation;
      default:
        return IceCardType.standard;
    }
  }
}

/// Target type for card prompts
enum TargetType {
  single,
  pair,
  everyone;

  static TargetType fromString(String value) {
    switch (value) {
      case 'pair':
        return TargetType.pair;
      case 'everyone':
        return TargetType.everyone;
      default:
        return TargetType.single;
    }
  }
}

/// Category of the card
enum CardCategory {
  conversation,
  action,
  reveal,
  physical,
  creative;

  static CardCategory fromString(String value) {
    switch (value) {
      case 'action':
        return CardCategory.action;
      case 'reveal':
        return CardCategory.reveal;
      case 'physical':
        return CardCategory.physical;
      case 'creative':
        return CardCategory.creative;
      default:
        return CardCategory.conversation;
    }
  }

  String get emoji {
    switch (this) {
      case CardCategory.conversation:
        return '💬';
      case CardCategory.action:
        return '🎯';
      case CardCategory.reveal:
        return '👀';
      case CardCategory.physical:
        return '🤝';
      case CardCategory.creative:
        return '🎨';
    }
  }
}

/// Game mode
enum IceGameMode {
  couple,
  group;
}

/// A player in the game
class IcePlayer {
  const IcePlayer({
    required this.name,
    this.turnsPlayed = 0,
    this.cardsSkipped = 0,
  });
  final String name;
  final int turnsPlayed;
  final int cardsSkipped;

  IcePlayer copyWith({
    String? name,
    int? turnsPlayed,
    int? cardsSkipped,
  }) =>
      IcePlayer(
        name: name ?? this.name,
        turnsPlayed: turnsPlayed ?? this.turnsPlayed,
        cardsSkipped: cardsSkipped ?? this.cardsSkipped,
      );
}

/// An ice breaker card
class IceCard {
  const IceCard({
    required this.id,
    required this.prompt,
    required this.cardType,
    this.timerSeconds,
    required this.targetType,
    required this.category,
    required this.intensity,
    required this.deckPosition,
  });

  factory IceCard.fromJson(Map<String, dynamic> json) => IceCard(
        id: json['id'] as String,
        prompt: json['prompt'] as String,
        cardType: IceCardType.fromString(json['card_type'] as String),
        timerSeconds: json['timer_seconds'] as int?,
        targetType: TargetType.fromString(json['target_type'] as String),
        category: CardCategory.fromString(json['category'] as String),
        intensity: json['intensity'] as int? ?? 1,
        deckPosition: json['deck_position'] as int? ?? 0,
      );
  final String id;
  final String prompt;
  final IceCardType cardType;
  final int? timerSeconds;
  final TargetType targetType;
  final CardCategory category;
  final int intensity;
  final int deckPosition;

  bool get hasTimer => timerSeconds != null && timerSeconds! > 0;
  bool get isWild => cardType == IceCardType.wild;
  bool get isEscalation => cardType == IceCardType.escalation;
}

/// Game phase enum
enum IceGamePhase {
  discovery, // Looking at game in arcade
  lobby, // Setting up players
  countdown, // 3-2-1 countdown
  playing, // Active gameplay
  cardReveal, // Card is being shown
  timer, // Timed action in progress
  results, // Game over
  escalation, // Upsell prompt
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME STATE
// ═══════════════════════════════════════════════════════════════════════════

class IceBreakersState {
  const IceBreakersState({
    this.phase = IceGamePhase.discovery,
    this.gameMode = IceGameMode.group,
    this.players = const [],
    this.currentPlayerIndex = 0,
    this.deck = const [],
    this.currentCardIndex = 0,
    this.completedCards = const [],
    this.skippedCards = const [],
    this.timerSecondsRemaining = 0,
    this.isCardRevealed = false,
    this.gameStartTime = 0,
    this.isLoading = false,
    this.isDemoMode = false,
    this.sessionId,
    this.error,
  });
  final IceGamePhase phase;
  final IceGameMode gameMode;
  final List<IcePlayer> players;
  final int currentPlayerIndex;
  final List<IceCard> deck;
  final int currentCardIndex;
  final List<IceCard> completedCards;
  final List<IceCard> skippedCards;
  final int timerSecondsRemaining;
  final bool isCardRevealed;
  final int gameStartTime; // Unix timestamp
  final bool isLoading;
  final bool isDemoMode;
  final String? sessionId;
  final String? error;

  /// Get current card
  IceCard? get currentCard {
    if (deck.isEmpty || currentCardIndex >= deck.length) return null;
    return deck[currentCardIndex];
  }

  /// Get current player
  IcePlayer? get currentPlayer {
    if (players.isEmpty) return null;
    return players[currentPlayerIndex % players.length];
  }

  /// Get next player (for pair cards)
  IcePlayer? get nextPlayer {
    if (players.length < 2) return null;
    return players[(currentPlayerIndex + 1) % players.length];
  }

  /// Check if game is over (15 min or 20 cards)
  bool get isGameOver {
    if (currentCardIndex >= deck.length) return true;
    if (currentCardIndex >= 20) return true;
    // Check 15 minute limit
    final elapsed = DateTime.now().millisecondsSinceEpoch - gameStartTime;
    return elapsed >= 15 * 60 * 1000; // 15 minutes in ms
  }

  /// Total cards played
  int get totalCardsPlayed => completedCards.length + skippedCards.length;

  /// Game duration in seconds
  int get gameDurationSeconds {
    if (gameStartTime == 0) return 0;
    return ((DateTime.now().millisecondsSinceEpoch - gameStartTime) / 1000)
        .round();
  }

  IceBreakersState copyWith({
    IceGamePhase? phase,
    IceGameMode? gameMode,
    List<IcePlayer>? players,
    int? currentPlayerIndex,
    List<IceCard>? deck,
    int? currentCardIndex,
    List<IceCard>? completedCards,
    List<IceCard>? skippedCards,
    int? timerSecondsRemaining,
    bool? isCardRevealed,
    int? gameStartTime,
    bool? isLoading,
    bool? isDemoMode,
    String? sessionId,
    String? error,
  }) =>
      IceBreakersState(
        phase: phase ?? this.phase,
        gameMode: gameMode ?? this.gameMode,
        players: players ?? this.players,
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
        deck: deck ?? this.deck,
        currentCardIndex: currentCardIndex ?? this.currentCardIndex,
        completedCards: completedCards ?? this.completedCards,
        skippedCards: skippedCards ?? this.skippedCards,
        timerSecondsRemaining:
            timerSecondsRemaining ?? this.timerSecondsRemaining,
        isCardRevealed: isCardRevealed ?? this.isCardRevealed,
        gameStartTime: gameStartTime ?? this.gameStartTime,
        isLoading: isLoading ?? this.isLoading,
        isDemoMode: isDemoMode ?? this.isDemoMode,
        sessionId: sessionId ?? this.sessionId,
        error: error,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class IceBreakersNotifier extends StateNotifier<IceBreakersState> {
  IceBreakersNotifier() : super(const IceBreakersState());

  // ═══════════════════════════════════════════════════════════════════════════
  // LOBBY PHASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enter lobby phase
  void enterLobby() {
    state = state.copyWith(
      phase: IceGamePhase.lobby,
      players: [],
      gameMode: IceGameMode.group,
    );
  }

  /// Set game mode (couple vs group)
  void setGameMode(IceGameMode mode) {
    state = state.copyWith(gameMode: mode);

    // For couple mode, auto-add two players
    if (mode == IceGameMode.couple && state.players.isEmpty) {
      state = state.copyWith(
        players: [
          const IcePlayer(name: 'Player 1'),
          const IcePlayer(name: 'Player 2'),
        ],
      );
    }
  }

  /// Add a player
  void addPlayer(String name) {
    if (name.trim().isEmpty) return;
    if (state.players.length >= 12) return; // Max 12 players

    final newPlayer = IcePlayer(name: name.trim());
    state = state.copyWith(
      players: [...state.players, newPlayer],
    );
  }

  /// Remove a player
  void removePlayer(int index) {
    if (index < 0 || index >= state.players.length) return;

    final newPlayers = List<IcePlayer>.from(state.players);
    newPlayers.removeAt(index);
    state = state.copyWith(players: newPlayers);
  }

  /// Update player name
  void updatePlayerName(int index, String name) {
    if (index < 0 || index >= state.players.length) return;
    if (name.trim().isEmpty) return;

    final newPlayers = List<IcePlayer>.from(state.players);
    newPlayers[index] = newPlayers[index].copyWith(name: name.trim());
    state = state.copyWith(players: newPlayers);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME START
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start the game (fetch deck and begin countdown)
  Future<void> startGame() async {
    if (state.players.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      // Try to fetch deck from database
      final supabase = Supabase.instance.client;
      final response = await supabase.rpc(
        'get_ice_breaker_deck',
        params: {
          'p_limit': 25,
        },
      );

      final List<IceCard> deck =
          (response as List).map((json) => IceCard.fromJson(json)).toList();

      if (deck.isEmpty) {
        throw Exception('No cards returned');
      }

      // Create session
      final session = await supabase
          .from('ice_breaker_sessions')
          .insert({
            'host_user_id': supabase.auth.currentUser?.id,
            'player_names': state.players.map((p) => p.name).toList(),
            'game_mode':
                state.gameMode == IceGameMode.couple ? 'couple' : 'group',
          })
          .select()
          .single();

      state = state.copyWith(
        deck: deck,
        sessionId: session['id'],
        isDemoMode: false,
        isLoading: false,
        phase: IceGamePhase.countdown,
      );
    } catch (e) {
      // Fall back to demo mode
      final demoDeck = _generateDemoDeck();
      state = state.copyWith(
        deck: demoDeck,
        isDemoMode: true,
        isLoading: false,
        phase: IceGamePhase.countdown,
      );
    }
  }

  /// Start playing after countdown
  void beginPlaying() {
    state = state.copyWith(
      phase: IceGamePhase.playing,
      currentCardIndex: 0,
      currentPlayerIndex: 0,
      completedCards: [],
      skippedCards: [],
      isCardRevealed: false,
      gameStartTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAMEPLAY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reveal the current card (flip animation trigger)
  void revealCard() {
    final card = state.currentCard;
    if (card == null) return;

    state = state.copyWith(
      isCardRevealed: true,
      phase: card.hasTimer ? IceGamePhase.timer : IceGamePhase.cardReveal,
      timerSecondsRemaining: card.timerSeconds ?? 0,
    );
  }

  /// Tick the timer (called every second)
  void tickTimer() {
    if (state.timerSecondsRemaining > 0) {
      state = state.copyWith(
        timerSecondsRemaining: state.timerSecondsRemaining - 1,
      );
    }
  }

  /// Complete current card (swipe right)
  void completeCard() {
    final card = state.currentCard;
    if (card == null) return;

    // Update player stats
    final players = List<IcePlayer>.from(state.players);
    if (players.isNotEmpty) {
      final idx = state.currentPlayerIndex % players.length;
      players[idx] = players[idx].copyWith(
        turnsPlayed: players[idx].turnsPlayed + 1,
      );
    }

    // Update card stats in database (fire and forget)
    _updateCardStats(card.id, true);

    // Check for escalation card or game over
    if (card.isEscalation) {
      state = state.copyWith(
        phase: IceGamePhase.escalation,
        completedCards: [...state.completedCards, card],
        players: players,
      );
      return;
    }

    // Move to next card
    final nextIndex = state.currentCardIndex + 1;
    final nextPlayerIndex =
        (state.currentPlayerIndex + 1) % state.players.length;

    // Check if game is over
    if (nextIndex >= state.deck.length || nextIndex >= 20) {
      _endGame();
      return;
    }

    state = state.copyWith(
      completedCards: [...state.completedCards, card],
      currentCardIndex: nextIndex,
      currentPlayerIndex: nextPlayerIndex,
      isCardRevealed: false,
      phase: IceGamePhase.playing,
      timerSecondsRemaining: 0,
      players: players,
    );
  }

  /// Skip current card (swipe left)
  void skipCard() {
    final card = state.currentCard;
    if (card == null) return;

    // Update player stats
    final players = List<IcePlayer>.from(state.players);
    if (players.isNotEmpty) {
      final idx = state.currentPlayerIndex % players.length;
      players[idx] = players[idx].copyWith(
        turnsPlayed: players[idx].turnsPlayed + 1,
        cardsSkipped: players[idx].cardsSkipped + 1,
      );
    }

    // Update card stats in database
    _updateCardStats(card.id, false);

    // Move to next card
    final nextIndex = state.currentCardIndex + 1;
    final nextPlayerIndex =
        (state.currentPlayerIndex + 1) % state.players.length;

    // Check if game is over
    if (nextIndex >= state.deck.length || nextIndex >= 20) {
      _endGame();
      return;
    }

    state = state.copyWith(
      skippedCards: [...state.skippedCards, card],
      currentCardIndex: nextIndex,
      currentPlayerIndex: nextPlayerIndex,
      isCardRevealed: false,
      phase: IceGamePhase.playing,
      timerSecondsRemaining: 0,
      players: players,
    );
  }

  /// End the game
  Future<void> _endGame() async {
    state = state.copyWith(phase: IceGamePhase.results);

    // Save session to database
    if (state.sessionId != null && !state.isDemoMode) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('ice_breaker_sessions').update({
          'cards_played': state.completedCards.length,
          'cards_skipped': state.skippedCards.length,
          'total_time_seconds': state.gameDurationSeconds,
          'completed_at': DateTime.now().toIso8601String(),
        }).eq('id', state.sessionId!);
      } catch (e) {
        // Ignore errors
      }
    }
  }

  /// Escalate to another game
  Future<void> escalateTo(String gameName) async {
    if (state.sessionId != null && !state.isDemoMode) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('ice_breaker_sessions').update({
          'escalated_to': gameName,
          'completed_at': DateTime.now().toIso8601String(),
        }).eq('id', state.sessionId!);
      } catch (e) {
        // Ignore errors
      }
    }

    state = state.copyWith(phase: IceGamePhase.results);
  }

  /// Reset to initial state
  void reset() {
    state = const IceBreakersState();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _updateCardStats(String cardId, bool completed) async {
    if (state.isDemoMode) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.rpc(
        'update_ice_breaker_card_stats',
        params: {
          'p_card_id': cardId,
          'p_was_completed': completed,
        },
      );
    } catch (e) {
      // Ignore errors
    }
  }

  /// Generate demo deck when database is unavailable
  List<IceCard> _generateDemoDeck() {
    final random = Random();

    // 50 demo prompts (matching database seed)
    final standardPrompts = [
      "What's the most spontaneous thing you've ever done on a first date?",
      'Describe your ideal Sunday morning with someone special.',
      "What's a secret talent you have that would surprise everyone here?",
      'If you could have dinner with any celebrity, who would make the most interesting date?',
      'What song would play if you had a personal entrance theme?',
      "What's the most embarrassing song on your playlist that you secretly love?",
      'Describe your dating life using only a movie title.',
      "What's a compliment you've received that you'll never forget?",
      'If you could wake up tomorrow with one new skill, what would it be?',
      "What's your go-to karaoke song?",
      "What's a deal-breaker for you on a date that others might find petty?",
      "What's the bravest thing you've ever done in the name of love or attraction?",
      'Describe your worst date ever—without naming names.',
      "What's a red flag that you've learned to spot immediately?",
      "What's your love language, and how do you like to receive it?",
      "What's the cheesiest pickup line that would actually work on you?",
      'What fictional character do you have an embarrassing crush on?',
      "What's something you pretend to like on dates but secretly hate?",
      "What's the most romantic thing you've ever done for someone?",
      "What's a guilty pleasure you'd be embarrassed to admit on a first date?",
      'Give a genuine compliment to the person on your left.',
      'Show everyone your most recent selfie—no deleting allowed.',
      "Do your best impression of someone in this room. We'll guess who.",
      'Show the last meme you sent to someone.',
      'Demonstrate your signature dance move.',
      "Show us your best 'flirty face' on command.",
      // ACTION cards
      'ACTION: Perform your most realistic orgasm right now.',
      'ACTION: Demonstrate your favorite sexual position by posing in it right now.',
      // Explicit questions
      "What's the most adventurous sex act you've ever tried?",
      "What's the most intimate thing you've ever shared with a partner?",
      "What's the biggest sex-related lie you've ever told?",
      "What's the most spontaneous sex you've ever had?",
      "What's the most embarrassing sex-related story you've shared with someone?",
      "What's the biggest turn-on for you?",
      "What's the most intense orgasm you've ever had?",
      "What's the most unusual place you've ever had sex?",
      "What's the biggest sex-related fantasy you've ever had?",
      "What's the most memorable sex-related dream you've ever had?",
      "What's your favorite BDSM role (dom, sub, switch)?",
      "What's the most extreme BDSM experience you've ever had?",
      "What's the most intense pain you've ever experienced during sex?",
      "What's the most creative way you've ever used bondage?",
      "What's the most intense sensory experience during sex?",
      "What's the most extreme fetish you've ever explored?",
      "What's the most intense breathplay experience you've ever had?",
      "What's the most intense sensory deprivation experience during sex?",
      "What's the most intense impact play experience you've ever had?",
      "What's the most intense rope bondage experience you've ever had?",
      "What's the most intimate thing you've ever shared with a stranger?",
      "What's the most intense emotional connection you've felt with someone?",
      "What's the most unusual thing you've done to get someone to agree to sex?",
      "What's the most creative way you've ever seduced someone?",
      "What's the most intense moment of vulnerability with someone?",
      "What's the most unusual thing you've done to escape a sex-related situation?",
      "What's the most intense moment of intimacy with someone?",
      "What's the most unusual thing you've done to build intimacy?",
      "What's the most intense moment of trust with someone?",
      "What's the most unusual thing you've done to build trust?",
      "What's your favorite sex position?",
      "What's the most intense sex-related fantasy you've ever had?",
      "What's the most unusual sex-related fantasy you've ever had?",
      "What's the most intense sex-related dream you've ever had?",
      "What's the most memorable sex-related experience you've ever had?",
      "What's the most intense sex-related experience with a stranger?",
      "What's the most unusual sex-related experience you've ever had?",
      "What's the most intense sex-related experience with a partner?",
      "What's the most unusual sex-related experience with a partner?",
      "What's the most intense sex-related experience with a group?",
      "What's the most intimate conversation you've had with a partner?",
      "What's the most intense conflict with a partner?",
      "What's the most unusual way you've communicated with a partner?",
      "What's the most intense moment of intimacy with a partner?",
      "What's the most unusual way you've built intimacy with a partner?",
      "What's the most intense moment of trust with a partner?",
      "What's the most unusual way you've built trust with a partner?",
      "What's the most intense moment of vulnerability with a partner?",
      "What's the most unusual way you've shared vulnerability with a partner?",
      "What's the most intense emotional connection with a partner?",
      "What's the most intense sex experience in a public place?",
      "What's the most unusual sex experience in a public place?",
      "What's the most intense sex experience in a private setting?",
      "What's the most unusual sex experience in a private setting?",
      "What's your favorite BDSM toy or prop?",
      "What's the most unusual BDSM experience you've ever had?",
      "What's the most intense BDSM scene you've participated in?",
      "What's the most unusual BDSM scene you've participated in?",
      "What's the most intense BDSM experience with a partner?",
      "What's the most unusual BDSM experience with a partner?",
      "What's the most intense BDSM experience with a group?",
      "What's the most unusual BDSM experience with a group?",
      "What's the most intimate conversation about sex with a partner?",
      "What's the most intense conflict about sex with a partner?",
      "What's the most unusual way you've communicated about sex?",
      "What's your favorite sex-related fantasy?",
      "What's the most intimate conversation about relationships?",
      "What's the most intense emotional connection about relationships?",
    ];

    final timedPrompts = [
      ('Let the group scroll through your Spotify for 30 seconds.', 30),
      ('Make eye contact with someone for 10 seconds without laughing.', 10),
      ('Give a 30-second pep talk to the person across from you.', 30),
      ('You have 60 seconds to tell us your life story. Go!', 60),
      ('In 30 seconds, give everyone here a unique nickname.', 30),
      ('You have 20 seconds to make the person on your right laugh.', 20),
      ('Describe your type in exactly 3 words. You have 10 seconds.', 10),
      (
        'Pass your phone to the right. They have 30 seconds to find an embarrassing photo.',
        30
      ),
      (
        "Hold another player's hand and stare them in the eye for 15 seconds without laughing.",
        15
      ),
    ];

    final wildPrompts = [
      'Everyone point to the person most likely to start a cult.',
      'Everyone share the last lie they told.',
      'Everyone make eye contact with someone. First to laugh does a dare.',
      'Everyone reveal their celebrity hall pass.',
      'Everyone point to who here gives the best hugs.',
      'Everyone share the weirdest thing in their fridge right now.',
      "Everyone point to who they'd trust to plan their surprise party.",
      'Everyone share their most-used emoji. Explain why.',
      'Everyone point to who here is secretly the biggest flirt.',
      "Everyone share one thing they're grateful for today.",
      'On the count of three, everyone point to the person they most want to kiss in the group. No cheating!',
      'On the count of 3, everyone put their hands on the part of their body they love being sexually touched the most.',
    ];

    // Shuffle standard and timed prompts
    final allStandard = [...standardPrompts];
    allStandard.shuffle(random);

    final allTimed = [...timedPrompts];
    allTimed.shuffle(random);

    final allWild = [...wildPrompts];
    allWild.shuffle(random);

    // Build deck with wild cards every 5 positions
    final deck = <IceCard>[];
    int stdIdx = 0;
    int timedIdx = 0;
    int wildIdx = 0;

    for (int pos = 1; pos <= 25; pos++) {
      if (pos % 5 == 0 && wildIdx < allWild.length) {
        // Wild card
        deck.add(
          IceCard(
            id: 'demo-wild-$wildIdx',
            prompt: allWild[wildIdx],
            cardType: IceCardType.wild,
            targetType: TargetType.everyone,
            category: CardCategory.action,
            intensity: 2,
            deckPosition: pos,
          ),
        );
        wildIdx++;
      } else if (timedIdx < allTimed.length && random.nextBool()) {
        // Timed card
        deck.add(
          IceCard(
            id: 'demo-timed-$timedIdx',
            prompt: allTimed[timedIdx].$1,
            cardType: IceCardType.timed,
            timerSeconds: allTimed[timedIdx].$2,
            targetType: random.nextBool() ? TargetType.single : TargetType.pair,
            category: CardCategory.action,
            intensity: 2,
            deckPosition: pos,
          ),
        );
        timedIdx++;
      } else if (stdIdx < allStandard.length) {
        // Standard card
        deck.add(
          IceCard(
            id: 'demo-std-$stdIdx',
            prompt: allStandard[stdIdx],
            cardType: IceCardType.standard,
            targetType: TargetType.single,
            category:
                pos % 3 == 0 ? CardCategory.reveal : CardCategory.conversation,
            intensity: 1 + (pos % 3),
            deckPosition: pos,
          ),
        );
        stdIdx++;
      }
    }

    // Add escalation card at the end
    deck.add(
      const IceCard(
        id: 'demo-escalation',
        prompt: 'The ice is broken. Ready to turn up the heat? 🔥',
        cardType: IceCardType.escalation,
        targetType: TargetType.everyone,
        category: CardCategory.action,
        intensity: 3,
        deckPosition: 26,
      ),
    );

    return deck;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final iceBreakersProvider =
    StateNotifierProvider<IceBreakersNotifier, IceBreakersState>(
        (ref) => IceBreakersNotifier());
