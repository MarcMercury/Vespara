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
    this.timerSeconds = 60,
    this.timerRemaining = 60,
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
    // Only allow 2 or 3 actors
    final validCount = count == 3 ? 3 : 2;
    state = state.copyWith(
      playerCount: validCount,
      scores: List.filled(validCount, 0),
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
    // Use appropriate position list based on player count
    final positionList = state.playerCount == 3 ? _threePersonPositions : _twoPersonPositions;
    
    // Pick a random position we haven't used yet
    final available = positionList.where(
      (p) => !_usedPositions.any((used) => used.id == p.id)
    ).toList();
    
    // If we've used all, reset
    if (available.isEmpty) {
      _usedPositions.clear();
    }
    
    final positions = available.isNotEmpty ? available : positionList;
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
  // POSITION DATA - Image-only positions from 2 People and 3 People folders
  // ─────────────────────────────────────────────────────────────────────────
  
  // 2 PEOPLE POSITIONS (28 images)
  static const List<DramaPosition> _twoPersonPositions = [
    DramaPosition(id: '2p1', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172305.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p2', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172312.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p3', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172317.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p4', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172323.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p5', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172328.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p6', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172333.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p7', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172339.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p8', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172344.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p9', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172348.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p10', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172400.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p11', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172410.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p12', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172423.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p13', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172437.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p14', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172444.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p15', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172449.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p16', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172458.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p17', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172503.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p18', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172508.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p19', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172514.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p20', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172521.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p21', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172526.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p22', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172537.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p23', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172545.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p24', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172552.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p25', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172600.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p26', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172605.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p27', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172620.png', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: '2p28', name: '', imageUrl: 'assets/images/drama_sutra/2 People/Screenshot 2026-01-22 172631.png', difficulty: 2, intensity: PositionIntensity.romantic),
  ];
  
  // 3 PEOPLE POSITIONS (12 images)
  static const List<DramaPosition> _threePersonPositions = [
    DramaPosition(id: '3p1', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172734.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p2', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172754.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p3', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172806.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p4', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172817.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p5', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172829.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p6', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172840.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p7', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172851.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p8', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172904.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p9', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172913.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p10', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172930.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p11', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172940.png', difficulty: 3, intensity: PositionIntensity.intimate),
    DramaPosition(id: '3p12', name: '', imageUrl: 'assets/images/drama_sutra/3 people/Screenshot 2026-01-22 172950.png', difficulty: 3, intensity: PositionIntensity.intimate),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final dramaSutraProvider = StateNotifierProvider<DramaSutraNotifier, DramaSutraState>(
  (ref) => DramaSutraNotifier(),
);
