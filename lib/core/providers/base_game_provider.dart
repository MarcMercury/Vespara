import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/content_rating.dart';
import '../utils/haptic_patterns.dart';
import '../utils/player_colors.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// BASE GAME PROVIDER - Abstract Foundation for TAG Games
/// ════════════════════════════════════════════════════════════════════════════
///
/// Provides common functionality for all TAG game state notifiers.
/// Extend this class to create game-specific providers with consistent behavior.

// ═══════════════════════════════════════════════════════════════════════════
// BASE PLAYER MODEL
// ═══════════════════════════════════════════════════════════════════════════

/// Base player model that all games can extend
class BasePlayer {
  BasePlayer({
    required this.id,
    required this.name,
    required this.color,
    required this.index,
    this.isActive = true,
    this.score = 0,
  });

  /// Create a player with auto-generated ID and color
  factory BasePlayer.create(String name, int index) => BasePlayer(
        id: '${DateTime.now().millisecondsSinceEpoch}_$index',
        name: name,
        color: PlayerColors.forIndex(index),
        index: index,
      );
  final String id;
  final String name;
  final Color color;
  final int index;
  bool isActive;
  int score;

  /// Get contrasting text color for this player's color
  Color get textColor => color.contrastingText;

  /// Get muted background color
  Color get backgroundColor => color.muted;

  BasePlayer copyWith({
    String? id,
    String? name,
    Color? color,
    int? index,
    bool? isActive,
    int? score,
  }) =>
      BasePlayer(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        index: index ?? this.index,
        isActive: isActive ?? this.isActive,
        score: score ?? this.score,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// BASE GAME STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Base state that all game states should include
abstract class BaseGameState<TPhase, TPlayer extends BasePlayer> {
  /// Current game phase
  TPhase get phase;

  /// List of players in the game
  List<TPlayer> get players;

  /// Currently selected player index (-1 if none)
  int get selectedPlayerIndex;

  /// Current content rating/heat level
  ContentRating get contentRating;

  /// Whether the game is loading data
  bool get isLoading;

  /// Whether running in demo mode (offline)
  bool get isDemoMode;

  /// Game session ID (for multiplayer/analytics)
  String? get sessionId;

  /// When the game started
  DateTime? get startTime;

  /// Get the currently selected player (null if none)
  TPlayer? get selectedPlayer =>
      selectedPlayerIndex >= 0 && selectedPlayerIndex < players.length
          ? players[selectedPlayerIndex]
          : null;

  /// Get total player count
  int get playerCount => players.length;

  /// Check if game has minimum players
  bool get hasMinimumPlayers => players.length >= 2;

  /// Check if game is at maximum players
  bool get isAtMaxPlayers => players.length >= 8;

  /// Get game duration so far
  Duration? get gameDuration =>
      startTime != null ? DateTime.now().difference(startTime!) : null;
}

// ═══════════════════════════════════════════════════════════════════════════
// BASE GAME NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

/// Abstract base notifier that provides common game functionality
abstract class BaseGameNotifier<TState extends BaseGameState>
    extends StateNotifier<TState> {
  BaseGameNotifier(super.state);

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum number of players allowed
  int get maxPlayers => 8;

  /// Minimum number of players required
  int get minPlayers => 2;

  /// Add a player to the game
  /// Override to customize player creation
  void addPlayer(String name) {
    if (name.trim().isEmpty) return;
    if (state.players.length >= maxPlayers) return;

    TagHaptics.selection();
    _addPlayerInternal(name.trim());
  }

  /// Internal method to add player - must be implemented by subclass
  void _addPlayerInternal(String name);

  /// Remove a player by index
  void removePlayer(int index) {
    if (index < 0 || index >= state.players.length) return;

    TagHaptics.selection();
    _removePlayerInternal(index);
  }

  /// Internal method to remove player - must be implemented by subclass
  void _removePlayerInternal(int index);

  /// Clear all players
  void clearPlayers() {
    _clearPlayersInternal();
  }

  /// Internal method to clear players - must be implemented by subclass
  void _clearPlayersInternal();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT RATING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Set the content rating/heat level
  void setContentRating(ContentRating rating) {
    TagHaptics.selection();
    _setContentRatingInternal(rating);
  }

  /// Internal method to set rating - must be implemented by subclass
  void _setContentRatingInternal(ContentRating rating);

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start the game
  Future<void> startGame() async {
    if (state.players.length < minPlayers) return;

    TagHaptics.gameStart();
    await _startGameInternal();
  }

  /// Internal method to start game - must be implemented by subclass
  Future<void> _startGameInternal();

  /// End the game
  void endGame() {
    TagHaptics.gameEnd();
    _endGameInternal();
  }

  /// Internal method to end game - must be implemented by subclass
  void _endGameInternal();

  /// Pause the game (if applicable)
  void pauseGame() {
    _pauseGameInternal();
  }

  /// Internal method to pause game - override if game supports pausing
  void _pauseGameInternal() {}

  /// Resume the game (if applicable)
  void resumeGame() {
    _resumeGameInternal();
  }

  /// Internal method to resume game - override if game supports pausing
  void _resumeGameInternal() {}

  /// Reset the game to initial state
  void reset() {
    _resetInternal();
  }

  /// Internal method to reset - must be implemented by subclass
  void _resetInternal();

  // ═══════════════════════════════════════════════════════════════════════════
  // DEMO MODE / FALLBACK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load demo/fallback cards when database is unavailable
  void loadDemoContent() {
    _loadDemoContentInternal();
  }

  /// Internal method to load demo content - must be implemented by subclass
  void _loadDemoContentInternal();

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Track a game event for analytics
  /// Override to implement actual analytics
  void trackEvent(String eventName, [Map<String, dynamic>? data]) {
    // Default implementation - can be overridden for actual analytics
    debugPrint('TAG Analytics: $eventName ${data ?? ''}');
  }

  /// Track game start
  void trackGameStart() {
    trackEvent('game_start', {
      'player_count': state.playerCount,
      'content_rating': state.contentRating.dbValue,
      'is_demo_mode': state.isDemoMode,
    });
  }

  /// Track game end
  void trackGameEnd() {
    trackEvent('game_end', {
      'player_count': state.playerCount,
      'duration_seconds': state.gameDuration?.inSeconds,
      'is_demo_mode': state.isDemoMode,
    });
  }

  /// Track card/prompt interaction
  void trackCardInteraction(String cardId, bool completed) {
    trackEvent('card_interaction', {
      'card_id': cardId,
      'completed': completed,
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MULTIPLAYER EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Mixin for multiplayer game functionality
mixin MultiplayerGameMixin<TState extends BaseGameState>
    on BaseGameNotifier<TState> {
  /// Room code for this game session
  String? get roomCode;

  /// Whether this player is the host
  bool get isHost;

  /// Create a new game room
  Future<String?> createRoom();

  /// Join an existing room
  Future<bool> joinRoom(String code);

  /// Leave the current room
  Future<void> leaveRoom();

  /// Sync state with other players
  Future<void> syncState();
}

/// Mixin for timed game functionality
mixin TimedGameMixin<TState extends BaseGameState> on BaseGameNotifier<TState> {
  /// Time remaining in current round/phase
  Duration get timeRemaining;

  /// Total time for current round/phase
  Duration get totalTime;

  /// Start the timer
  void startTimer();

  /// Pause the timer
  void pauseTimer();

  /// Reset the timer
  void resetTimer();

  /// Called when timer reaches zero
  void onTimerComplete();
}
