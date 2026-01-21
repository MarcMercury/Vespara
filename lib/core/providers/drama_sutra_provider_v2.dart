import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:typed_data';

/// ════════════════════════════════════════════════════════════════════════════
/// DRAMA-SUTRA v2 - SIMPLIFIED
/// "Strike a Pose!" - Director describes, group poses, camera captures
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// GAME STATE - SIMPLIFIED
// ═══════════════════════════════════════════════════════════════════════════

enum DramaGameState {
  idle,      // Ready to start - hit ACTION
  action,    // 30 sec timer - Director describing, others posing
  review,    // Compare position vs captured photo, vote
  gameOver,  // Final scoreboard
}

// ═══════════════════════════════════════════════════════════════════════════
// SCORING - THUMBS SYSTEM
// ═══════════════════════════════════════════════════════════════════════════

enum ThumbsScore {
  doubleDown,  // 👎👎 = 0 points
  thumbDown,   // 👎 = 1 point
  thumbUp,     // 👍 = 2 points  
  doubleUp,    // 👍👍 = 3 points
}

extension ThumbsScoreExtension on ThumbsScore {
  String get emoji {
    switch (this) {
      case ThumbsScore.doubleDown: return '👎👎';
      case ThumbsScore.thumbDown: return '👎';
      case ThumbsScore.thumbUp: return '👍';
      case ThumbsScore.doubleUp: return '👍👍';
    }
  }
  
  String get label {
    switch (this) {
      case ThumbsScore.doubleDown: return 'EPIC FAIL';
      case ThumbsScore.thumbDown: return 'NOT QUITE';
      case ThumbsScore.thumbUp: return 'NAILED IT';
      case ThumbsScore.doubleUp: return 'PERFECTION!';
    }
  }
  
  int get points {
    switch (this) {
      case ThumbsScore.doubleDown: return 0;
      case ThumbsScore.thumbDown: return 1;
      case ThumbsScore.thumbUp: return 2;
      case ThumbsScore.doubleUp: return 3;
    }
  }
  
  Color get color {
    switch (this) {
      case ThumbsScore.doubleDown: return const Color(0xFFE53935);
      case ThumbsScore.thumbDown: return const Color(0xFFFF9800);
      case ThumbsScore.thumbUp: return const Color(0xFF4CAF50);
      case ThumbsScore.doubleUp: return const Color(0xFFFFD700);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POSITION INTENSITY
// ═══════════════════════════════════════════════════════════════════════════

enum PositionIntensity {
  romantic,
  acrobatic,
  intimate,
}

extension PositionIntensityExtension on PositionIntensity {
  String get displayName {
    switch (this) {
      case PositionIntensity.romantic: return 'Romantic';
      case PositionIntensity.acrobatic: return 'Acrobatic';
      case PositionIntensity.intimate: return 'Intimate';
    }
  }
  
  String get emoji {
    switch (this) {
      case PositionIntensity.romantic: return '💕';
      case PositionIntensity.acrobatic: return '🤸';
      case PositionIntensity.intimate: return '🌙';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class DramaPosition {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int difficulty; // 1-5
  final PositionIntensity intensity;
  
  const DramaPosition({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.difficulty,
    required this.intensity,
  });
  
  String get difficultyStars {
    return List.generate(5, (i) => i < difficulty ? '★' : '☆').join();
  }
  
  Color get difficultyColor {
    if (difficulty <= 2) return const Color(0xFF4CAF50);
    if (difficulty <= 3) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }
}

class RoundResult {
  final int roundNumber;
  final int directorIndex;
  final DramaPosition position;
  final Uint8List? capturedPhoto;
  final ThumbsScore? score;
  
  const RoundResult({
    required this.roundNumber,
    required this.directorIndex,
    required this.position,
    this.capturedPhoto,
    this.score,
  });
  
  RoundResult copyWith({
    Uint8List? capturedPhoto,
    ThumbsScore? score,
  }) {
    return RoundResult(
      roundNumber: roundNumber,
      directorIndex: directorIndex,
      position: position,
      capturedPhoto: capturedPhoto ?? this.capturedPhoto,
      score: score ?? this.score,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════

class DramaSutraState {
  final DramaGameState gameState;
  final int playerCount;           // How many players (for Director rotation)
  final int currentDirectorIndex;  // Whose turn to be Director
  final int currentRound;
  final int maxRounds;
  final DramaPosition? currentPosition;
  final int timerSeconds;
  final int timerRemaining;
  final Uint8List? capturedPhoto;  // Photo taken at timer end
  final List<RoundResult> roundHistory;
  final List<int> scores;          // Score per Director index
  
  const DramaSutraState({
    this.gameState = DramaGameState.idle,
    this.playerCount = 2,
    this.currentDirectorIndex = 0,
    this.currentRound = 0,
    this.maxRounds = 10,
    this.currentPosition,
    this.timerSeconds = 30,
    this.timerRemaining = 30,
    this.capturedPhoto,
    this.roundHistory = const [],
    this.scores = const [],
  });
  
  /// Director number for display (1-indexed)
  int get directorNumber => currentDirectorIndex + 1;
  
  /// Is game over?
  bool get isGameOver => currentRound >= maxRounds;
  
  /// Total score for current director
  int get currentDirectorScore {
    if (currentDirectorIndex >= scores.length) return 0;
    return scores[currentDirectorIndex];
  }
  
  /// Winner index (highest score)
  int get winnerIndex {
    if (scores.isEmpty) return 0;
    int maxScore = scores.reduce((a, b) => a > b ? a : b);
    return scores.indexOf(maxScore);
  }
  
  DramaSutraState copyWith({
    DramaGameState? gameState,
    int? playerCount,
    int? currentDirectorIndex,
    int? currentRound,
    int? maxRounds,
    DramaPosition? currentPosition,
    int? timerSeconds,
    int? timerRemaining,
    Uint8List? capturedPhoto,
    List<RoundResult>? roundHistory,
    List<int>? scores,
    bool clearPhoto = false,
  }) {
    return DramaSutraState(
      gameState: gameState ?? this.gameState,
      playerCount: playerCount ?? this.playerCount,
      currentDirectorIndex: currentDirectorIndex ?? this.currentDirectorIndex,
      currentRound: currentRound ?? this.currentRound,
      maxRounds: maxRounds ?? this.maxRounds,
      currentPosition: currentPosition ?? this.currentPosition,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      timerRemaining: timerRemaining ?? this.timerRemaining,
      capturedPhoto: clearPhoto ? null : (capturedPhoto ?? this.capturedPhoto),
      roundHistory: roundHistory ?? this.roundHistory,
      scores: scores ?? this.scores,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class DramaSutraNotifier extends StateNotifier<DramaSutraState> {
  DramaSutraNotifier() : super(const DramaSutraState());
  
  final Random _random = Random();
  final List<DramaPosition> _usedPositions = [];
  
  // ─────────────────────────────────────────────────────────────────────────
  // GAME SETUP
  // ─────────────────────────────────────────────────────────────────────────
  
  void setPlayerCount(int count) {
    state = state.copyWith(
      playerCount: count.clamp(2, 8),
      scores: List.filled(count.clamp(2, 8), 0),
    );
  }
  
  void setMaxRounds(int rounds) {
    state = state.copyWith(maxRounds: rounds.clamp(1, 20));
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // GAME FLOW
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Called when Director hits ACTION button
  void startAction() {
    // Pick a random position we haven't used yet
    final available = _allPositions.where(
      (p) => !_usedPositions.any((used) => used.id == p.id)
    ).toList();
    
    // If we've used all, reset
    if (available.isEmpty) {
      _usedPositions.clear();
    }
    
    final positions = available.isNotEmpty ? available : _allPositions;
    final position = positions[_random.nextInt(positions.length)];
    _usedPositions.add(position);
    
    state = state.copyWith(
      gameState: DramaGameState.action,
      currentPosition: position,
      timerRemaining: state.timerSeconds,
      currentRound: state.currentRound + 1,
      clearPhoto: true,
    );
  }
  
  /// Called every second by timer
  void tickTimer() {
    if (state.timerRemaining > 0) {
      state = state.copyWith(timerRemaining: state.timerRemaining - 1);
    }
  }
  
  /// Called when photo is captured (at timer = 0 or manual)
  void setPhoto(Uint8List photoData) {
    state = state.copyWith(
      capturedPhoto: photoData,
      gameState: DramaGameState.review,
    );
  }
  
  /// Called when timer hits 0 without photo (camera issue)
  void skipToReview() {
    state = state.copyWith(
      gameState: DramaGameState.review,
    );
  }
  
  /// Called when Director picks a thumbs score
  void submitScore(ThumbsScore score) {
    // Add to this director's score
    final newScores = [...state.scores];
    if (state.currentDirectorIndex < newScores.length) {
      newScores[state.currentDirectorIndex] += score.points;
    }
    
    // Record round result
    final result = RoundResult(
      roundNumber: state.currentRound,
      directorIndex: state.currentDirectorIndex,
      position: state.currentPosition!,
      capturedPhoto: state.capturedPhoto,
      score: score,
    );
    
    // Check if game over
    final isGameOver = state.currentRound >= state.maxRounds;
    
    // Rotate director for next round
    final nextDirectorIndex = (state.currentDirectorIndex + 1) % state.playerCount;
    
    state = state.copyWith(
      gameState: isGameOver ? DramaGameState.gameOver : DramaGameState.idle,
      currentDirectorIndex: nextDirectorIndex,
      roundHistory: [...state.roundHistory, result],
      scores: newScores,
      clearPhoto: true,
    );
  }
  
  /// Reset game to start
  void resetGame() {
    _usedPositions.clear();
    state = DramaSutraState(
      playerCount: state.playerCount,
      scores: List.filled(state.playerCount, 0),
    );
  }
  
  /// Exit completely
  void exitGame() {
    _usedPositions.clear();
    state = const DramaSutraState();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POSITION DATA - 38 SEXUAL POSITIONS (12 Group + 26 Bingo)
  // ─────────────────────────────────────────────────────────────────────────
  
  static const List<DramaPosition> _allPositions = [
    // GROUP POSITIONS (12)
    DramaPosition(
      id: 'g1', name: 'The Constellation',
      description: 'Three bodies intertwined like stars.',
      imageUrl: 'assets/images/drama_sutra/group-sex-1_X5.png',
      difficulty: 3, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'g2', name: 'The Daisy Chain',
      description: 'A continuous circle of pleasure.',
      imageUrl: 'assets/images/drama_sutra/group-sex-2_X5.png',
      difficulty: 3, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'g3', name: 'The Pyramid',
      description: 'Bodies stacked forming an ancient shape.',
      imageUrl: 'assets/images/drama_sutra/group-sex-3_X5.png',
      difficulty: 4, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'g4', name: 'The Thunderclap',
      description: 'All parties converge at the center.',
      imageUrl: 'assets/images/drama_sutra/group-sex-4_X5.png',
      difficulty: 4, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'g5', name: 'The Velvet Sandwich',
      description: 'One in the middle, surrounded.',
      imageUrl: 'assets/images/drama_sutra/group-sex-5_X5.png',
      difficulty: 2, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'g6', name: 'The Serpentine',
      description: 'Bodies curve like an undulating wave.',
      imageUrl: 'assets/images/drama_sutra/group-sex-6_X5.png',
      difficulty: 3, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'g7', name: 'The Triple Crown',
      description: 'A royal arrangement of attention.',
      imageUrl: 'assets/images/drama_sutra/group-sex-7_X5.png',
      difficulty: 3, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'g8', name: 'The Circus Act',
      description: 'Balance, trust, and flexibility required.',
      imageUrl: 'assets/images/drama_sutra/group-sex-8_X5.png',
      difficulty: 5, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'g9', name: 'The Love Knot',
      description: 'Limbs intertwined in complex embrace.',
      imageUrl: 'assets/images/drama_sutra/group-sex-9_X5.png',
      difficulty: 4, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'g10', name: 'The Tidal Wave',
      description: 'Bodies rise and fall in rhythm.',
      imageUrl: 'assets/images/drama_sutra/group-sex-10_X5.png',
      difficulty: 3, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'g11', name: 'The Phoenix Rising',
      description: 'One rises from the embrace of others.',
      imageUrl: 'assets/images/drama_sutra/group-sex-11_X5.png',
      difficulty: 4, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'g12', name: 'The Grand Finale',
      description: 'All reach the crescendo together.',
      imageUrl: 'assets/images/drama_sutra/group-sex-12_X5.png',
      difficulty: 5, intensity: PositionIntensity.intimate,
    ),
    
    // BINGO POSITIONS (26)
    DramaPosition(
      id: 'b1', name: 'Acrobat',
      description: 'Gravity-defying flexibility required.',
      imageUrl: 'assets/images/drama_sutra/acrobat.png',
      difficulty: 5, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b2', name: 'Ballerina',
      description: 'Graceful, one partner on tiptoe.',
      imageUrl: 'assets/images/drama_sutra/ballerina.png',
      difficulty: 3, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b3', name: 'Best Seat in the House',
      description: 'VIP treatment - perfect view.',
      imageUrl: 'assets/images/drama_sutra/best-seat-in-the-house.png',
      difficulty: 2, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b4', name: 'Body Surfing',
      description: 'Ride the waves of passion.',
      imageUrl: 'assets/images/drama_sutra/body-surfing.png',
      difficulty: 3, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b5', name: 'Celebration',
      description: 'Toast to an unforgettable night.',
      imageUrl: 'assets/images/drama_sutra/celebration.png',
      difficulty: 2, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b6', name: 'Deep Throat',
      description: 'Intimate oral position.',
      imageUrl: 'assets/images/drama_sutra/deep-throat.png',
      difficulty: 3, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b7', name: 'Doggy',
      description: 'Classic from behind.',
      imageUrl: 'assets/images/drama_sutra/doggy.png',
      difficulty: 1, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b8', name: 'Front Row Seat',
      description: 'Up-close view of the action.',
      imageUrl: 'assets/images/drama_sutra/front-row-seat.png',
      difficulty: 2, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b9', name: 'Hammock',
      description: 'Swinging in lazy bliss.',
      imageUrl: 'assets/images/drama_sutra/hammock.png',
      difficulty: 2, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b10', name: 'Head over Heels',
      description: 'Fall deeply into passion.',
      imageUrl: 'assets/images/drama_sutra/head-over-heels.png',
      difficulty: 4, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b11', name: 'Helicopter',
      description: 'Spin into ecstasy.',
      imageUrl: 'assets/images/drama_sutra/helicopter.png',
      difficulty: 5, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b12', name: 'Missionary',
      description: 'Face to face, heart to heart.',
      imageUrl: 'assets/images/drama_sutra/missionary.png',
      difficulty: 1, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b13', name: 'Octopus',
      description: 'Eight limbs, infinite pleasure.',
      imageUrl: 'assets/images/drama_sutra/octopus.png',
      difficulty: 3, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b14', name: 'Power Pump',
      description: 'Maximum thrust, maximum passion.',
      imageUrl: 'assets/images/drama_sutra/power-pump.png',
      difficulty: 3, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b15', name: 'Pretzel',
      description: 'Twisted together deliciously.',
      imageUrl: 'assets/images/drama_sutra/pretzel.png',
      difficulty: 4, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b16', name: 'Pump & Grind',
      description: 'Rhythm and motion in harmony.',
      imageUrl: 'assets/images/drama_sutra/pump-and-grind.png',
      difficulty: 2, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b17', name: 'Reverse Cowgirl',
      description: 'Saddle up backwards.',
      imageUrl: 'assets/images/drama_sutra/reverse-cowgirl.png',
      difficulty: 2, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b18', name: 'Sixty-Nine',
      description: 'Mutual pleasure, head to tail.',
      imageUrl: 'assets/images/drama_sutra/sixty-nine.png',
      difficulty: 2, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b19', name: 'Superman',
      description: 'Fly into pleasure.',
      imageUrl: 'assets/images/drama_sutra/superman.png',
      difficulty: 4, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b20', name: 'Table Delight',
      description: 'Dinner is served.',
      imageUrl: 'assets/images/drama_sutra/table-delight.png',
      difficulty: 2, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b21', name: 'Threesome',
      description: 'Three is company.',
      imageUrl: 'assets/images/drama_sutra/threesome.png',
      difficulty: 3, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b22', name: 'Treasure Hunt',
      description: 'X marks the spot.',
      imageUrl: 'assets/images/drama_sutra/treasure-hunt.png',
      difficulty: 2, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b23', name: 'Tree Hugger',
      description: 'Wrap around tight.',
      imageUrl: 'assets/images/drama_sutra/tree-hugger.png',
      difficulty: 3, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b24', name: 'Wall Hug',
      description: 'Against the wall passion.',
      imageUrl: 'assets/images/drama_sutra/wall-hug.png',
      difficulty: 3, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b25', name: 'Web of Desire',
      description: 'Tangled in the web.',
      imageUrl: 'assets/images/drama_sutra/web-of-desire.png',
      difficulty: 4, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b26', name: 'Zombie',
      description: 'The undead rise.',
      imageUrl: 'assets/images/drama_sutra/zombie.png',
      difficulty: 2, intensity: PositionIntensity.acrobatic,
    ),
    
    // CLASSIC COUPLE POSITIONS (11)
    DramaPosition(
      id: 'c1', name: 'Spoons',
      description: 'Side by side comfort.',
      difficulty: 1, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'c2', name: 'Face to Face',
      description: 'Eye contact connection.',
      difficulty: 1, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'c3', name: 'The Lotus',
      description: 'Seated embrace.',
      difficulty: 2, intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'c4', name: 'The Bridge',
      description: 'Arched for pleasure.',
      difficulty: 4, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'c5', name: 'The Throne',
      description: 'Royal seated pleasure.',
      difficulty: 2, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'c6', name: 'Standing Ovation',
      description: 'On your feet passion.',
      difficulty: 3, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'c7', name: 'The Cradle',
      description: 'Held in loving arms.',
      difficulty: 2, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'c8', name: 'The Arch',
      description: 'Bend back in ecstasy.',
      difficulty: 4, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'c9', name: 'Lazy Sunday',
      description: 'Relaxed sideways love.',
      difficulty: 1, intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'c10', name: 'The Wheelbarrow',
      description: 'Garden of delights.',
      difficulty: 5, intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'c11', name: 'Cowgirl',
      description: 'Ride into the sunset.',
      difficulty: 2, intensity: PositionIntensity.romantic,
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final dramaSutraV2Provider = StateNotifierProvider<DramaSutraNotifier, DramaSutraState>(
  (ref) => DramaSutraNotifier(),
);
