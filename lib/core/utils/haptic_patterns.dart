import 'package:flutter/services.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// HAPTIC PATTERNS - Standardized Haptic Feedback for TAG Games
/// ════════════════════════════════════════════════════════════════════════════
///
/// Provides consistent haptic feedback patterns across all TAG games.
/// Use these instead of calling HapticFeedback directly for consistency.

class TagHaptics {
  TagHaptics._(); // Prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION & SELECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light tap - for selections, toggles, minor interactions
  /// Use for: Selecting options, toggling switches, tapping list items
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Standard button press feedback
  /// Use for: Primary buttons, navigation actions
  static Future<void> buttonPress() async {
    await HapticFeedback.lightImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Card flip or reveal
  /// Use for: Revealing cards, flipping tiles, showing hidden content
  static Future<void> cardFlip() async {
    await HapticFeedback.lightImpact();
  }

  /// Card swipe action
  /// Use for: Swiping cards left/right, dismissing items
  static Future<void> cardSwipe() async {
    await HapticFeedback.mediumImpact();
  }

  /// Wheel spin tick (called repeatedly during spin)
  /// Use for: Wheel crossing segment boundaries
  static Future<void> wheelTick() async {
    await HapticFeedback.selectionClick();
  }

  /// Wheel spin complete
  /// Use for: When wheel stops on final selection
  static Future<void> wheelStop() async {
    await HapticFeedback.heavyImpact();
  }

  /// Timer tick (for countdowns)
  /// Use for: Final countdown seconds (3, 2, 1...)
  static Future<void> timerTick() async {
    await HapticFeedback.selectionClick();
  }

  /// Timer complete
  /// Use for: When timer reaches zero
  static Future<void> timerComplete() async {
    await HapticFeedback.heavyImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME STATE CHANGES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Game start
  /// Use for: Starting a new game, entering gameplay
  static Future<void> gameStart() async {
    await HapticFeedback.heavyImpact();
  }

  /// Game end
  /// Use for: Game over, showing results
  static Future<void> gameEnd() async {
    await HapticFeedback.heavyImpact();
  }

  /// Round complete
  /// Use for: Finishing a round, moving to next phase
  static Future<void> roundComplete() async {
    await HapticFeedback.mediumImpact();
  }

  /// Phase transition
  /// Use for: Moving between game phases (lobby → playing, etc.)
  static Future<void> phaseTransition() async {
    await HapticFeedback.mediumImpact();
  }

  /// Player turn start
  /// Use for: When it becomes a player's turn
  static Future<void> turnStart() async {
    await HapticFeedback.mediumImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALERTS & SIGNALS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Signal change (Flash & Freeze)
  /// Use for: Red/Green/Yellow light changes
  static Future<void> signalChange() async {
    await HapticFeedback.heavyImpact();
  }

  /// Photo captured
  /// Use for: Camera shutter moment
  static Future<void> photoCapture() async {
    await HapticFeedback.lightImpact();
  }

  /// Warning/Alert
  /// Use for: Time running out, approaching limit
  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
  }

  /// Error occurred
  /// Use for: Invalid action, error state
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUCCESS & REWARDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Success/Correct answer
  /// Use for: Correct answers, successful actions
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Achievement unlocked
  /// Use for: Unlocking achievements, earning badges
  static Future<void> achievement() async {
    await HapticFeedback.heavyImpact();
  }

  /// Score increase
  /// Use for: Points added, score updated
  static Future<void> scoreUp() async {
    await HapticFeedback.lightImpact();
  }

  /// Win/Victory
  /// Use for: Winning the game, first place
  static Future<void> victory() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MULTIPLAYER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Player joined
  /// Use for: New player joins the room
  static Future<void> playerJoined() async {
    await HapticFeedback.lightImpact();
  }

  /// Player left
  /// Use for: Player leaves the room
  static Future<void> playerLeft() async {
    await HapticFeedback.lightImpact();
  }

  /// Room created
  /// Use for: Successfully creating a game room
  static Future<void> roomCreated() async {
    await HapticFeedback.mediumImpact();
  }

  /// Room joined
  /// Use for: Successfully joining a game room
  static Future<void> roomJoined() async {
    await HapticFeedback.mediumImpact();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTENSITY PRESETS (for games that need custom intensity)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light impact - subtle feedback
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - standard feedback
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - strong feedback
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Vibrate - long vibration (use sparingly)
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}

/// Extension to add haptic feedback to common widget events
extension HapticExtension on Function {
  /// Wrap a callback with haptic feedback
  Function withHaptic(Future<void> Function() haptic) {
    return () async {
      await haptic();
      this();
    };
  }
}
