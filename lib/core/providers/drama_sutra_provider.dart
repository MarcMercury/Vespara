import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

/// ════════════════════════════════════════════════════════════════════════════
/// DRAMA-SUTRA PROVIDER
/// "Pose with Purpose" - Kama Sutra meets Improv Comedy
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum DramaGameState {
  idle,      // Not in a game
  lobby,     // Waiting for players
  casting,   // Assigning roles for this round
  script,    // Judge sees the position + scenario
  action,    // Timer running, talent performing
  scoring,   // Judge rating the performance
  results,   // Showing round results
  gameOver,  // Final standings
}

enum DramaGenre {
  soapOpera,
  sciFi,
  shakespearean,
  realityTV,
  wildlifeDocumentary,
  ikeaArgument,
  noirDetective,
  telenovela,
}

extension DramaGenreExtension on DramaGenre {
  String get displayName {
    switch (this) {
      case DramaGenre.soapOpera: return 'Soap Opera';
      case DramaGenre.sciFi: return 'Sci-Fi';
      case DramaGenre.shakespearean: return 'Shakespearean';
      case DramaGenre.realityTV: return 'Reality TV';
      case DramaGenre.wildlifeDocumentary: return 'Wildlife Documentary';
      case DramaGenre.ikeaArgument: return 'IKEA Argument';
      case DramaGenre.noirDetective: return 'Noir Detective';
      case DramaGenre.telenovela: return 'Telenovela';
    }
  }
  
  String get emoji {
    switch (this) {
      case DramaGenre.soapOpera: return '📺';
      case DramaGenre.sciFi: return '🚀';
      case DramaGenre.shakespearean: return '🎭';
      case DramaGenre.realityTV: return '🌹';
      case DramaGenre.wildlifeDocumentary: return '🦁';
      case DramaGenre.ikeaArgument: return '🔧';
      case DramaGenre.noirDetective: return '🕵️';
      case DramaGenre.telenovela: return '💔';
    }
  }
  
  Color get color {
    switch (this) {
      case DramaGenre.soapOpera: return const Color(0xFFE91E63);
      case DramaGenre.sciFi: return const Color(0xFF00BCD4);
      case DramaGenre.shakespearean: return const Color(0xFF9C27B0);
      case DramaGenre.realityTV: return const Color(0xFFFF5722);
      case DramaGenre.wildlifeDocumentary: return const Color(0xFF4CAF50);
      case DramaGenre.ikeaArgument: return const Color(0xFFFFEB3B);
      case DramaGenre.noirDetective: return const Color(0xFF607D8B);
      case DramaGenre.telenovela: return const Color(0xFFE53935);
    }
  }
}

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
  
  /// Returns difficulty stars (e.g., "★★★☆☆")
  String get difficultyStars {
    return List.generate(5, (i) => i < difficulty ? '★' : '☆').join();
  }
  
  Color get difficultyColor {
    if (difficulty <= 2) return const Color(0xFF4CAF50); // Green - Easy
    if (difficulty <= 3) return const Color(0xFFFF9800); // Orange - Medium
    return const Color(0xFFE53935); // Red - Hard
  }
}

class DramaScenario {
  final String id;
  final String text;
  final DramaGenre genre;
  final int spiceLevel;
  
  const DramaScenario({
    required this.id,
    required this.text,
    required this.genre,
    this.spiceLevel = 1,
  });
}

class DramaPlayer {
  final String id;
  final String displayName;
  final Color avatarColor;
  final bool isHost;
  final double totalTechniqueScore;
  final double totalDramaScore;
  final int roundsAsTalent;
  
  const DramaPlayer({
    required this.id,
    required this.displayName,
    required this.avatarColor,
    this.isHost = false,
    this.totalTechniqueScore = 0,
    this.totalDramaScore = 0,
    this.roundsAsTalent = 0,
  });
  
  /// Combined score for ranking
  double get totalScore => totalTechniqueScore + totalDramaScore;
  
  /// Average score per round
  double get averageScore => 
      roundsAsTalent > 0 ? totalScore / roundsAsTalent : 0;
  
  DramaPlayer copyWith({
    String? displayName,
    Color? avatarColor,
    bool? isHost,
    double? totalTechniqueScore,
    double? totalDramaScore,
    int? roundsAsTalent,
  }) {
    return DramaPlayer(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarColor: avatarColor ?? this.avatarColor,
      isHost: isHost ?? this.isHost,
      totalTechniqueScore: totalTechniqueScore ?? this.totalTechniqueScore,
      totalDramaScore: totalDramaScore ?? this.totalDramaScore,
      roundsAsTalent: roundsAsTalent ?? this.roundsAsTalent,
    );
  }
}

class RoundScore {
  final int roundNumber;
  final String judgeId;
  final String talentAId;
  final String? talentBId;
  final DramaPosition position;
  final DramaScenario scenario;
  final double techniqueScore;
  final double dramaScore;
  final String? judgeComment;
  
  const RoundScore({
    required this.roundNumber,
    required this.judgeId,
    required this.talentAId,
    this.talentBId,
    required this.position,
    required this.scenario,
    required this.techniqueScore,
    required this.dramaScore,
    this.judgeComment,
  });
  
  double get totalScore => techniqueScore + dramaScore;
  
  String get ratingLabel {
    final avg = totalScore / 2;
    if (avg >= 9) return 'OSCAR WORTHY';
    if (avg >= 7) return 'STELLAR PERFORMANCE';
    if (avg >= 5) return 'RESPECTABLE EFFORT';
    if (avg >= 3) return 'NEEDS MORE REHEARSAL';
    return 'STRAIGHT TO DVD';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════

class DramaSutraState {
  final DramaGameState gameState;
  final String? roomCode;
  final String? currentPlayerId;
  final List<DramaPlayer> players;
  final int currentRound;
  final int maxRounds;
  final int judgeIndex;
  final DramaPosition? currentPosition;
  final DramaScenario? currentScenario;
  final bool isImageRevealed; // For blur/unblur toggle
  final int timerSeconds;
  final int timerRemaining;
  final double pendingTechniqueScore;
  final double pendingDramaScore;
  final List<RoundScore> roundHistory;
  final int maxDifficulty; // Host setting
  
  const DramaSutraState({
    this.gameState = DramaGameState.idle,
    this.roomCode,
    this.currentPlayerId,
    this.players = const [],
    this.currentRound = 0,
    this.maxRounds = 5,
    this.judgeIndex = 0,
    this.currentPosition,
    this.currentScenario,
    this.isImageRevealed = false,
    this.timerSeconds = 60,
    this.timerRemaining = 60,
    this.pendingTechniqueScore = 5.0,
    this.pendingDramaScore = 5.0,
    this.roundHistory = const [],
    this.maxDifficulty = 3, // Default to intermediate
  });
  
  /// The current judge player
  DramaPlayer? get judge {
    if (players.isEmpty) return null;
    return players[judgeIndex % players.length];
  }
  
  /// The talent players for this round (everyone except judge)
  List<DramaPlayer> get talent {
    if (players.isEmpty) return [];
    return players.where((p) => p.id != judge?.id).toList();
  }
  
  /// Am I the judge this round?
  bool get isJudge => currentPlayerId == judge?.id;
  
  /// Am I part of the talent this round?
  bool get isTalent => talent.any((p) => p.id == currentPlayerId);
  
  /// Is the current player the host?
  bool get isHost => players.any((p) => p.id == currentPlayerId && p.isHost);
  
  /// Current player object
  DramaPlayer? get me => players.where((p) => p.id == currentPlayerId).firstOrNull;
  
  /// Players sorted by score (for leaderboard)
  List<DramaPlayer> get leaderboard {
    final sorted = [...players];
    sorted.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return sorted;
  }
  
  DramaSutraState copyWith({
    DramaGameState? gameState,
    String? roomCode,
    String? currentPlayerId,
    List<DramaPlayer>? players,
    int? currentRound,
    int? maxRounds,
    int? judgeIndex,
    DramaPosition? currentPosition,
    DramaScenario? currentScenario,
    bool? isImageRevealed,
    int? timerSeconds,
    int? timerRemaining,
    double? pendingTechniqueScore,
    double? pendingDramaScore,
    List<RoundScore>? roundHistory,
    int? maxDifficulty,
  }) {
    return DramaSutraState(
      gameState: gameState ?? this.gameState,
      roomCode: roomCode ?? this.roomCode,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      players: players ?? this.players,
      currentRound: currentRound ?? this.currentRound,
      maxRounds: maxRounds ?? this.maxRounds,
      judgeIndex: judgeIndex ?? this.judgeIndex,
      currentPosition: currentPosition ?? this.currentPosition,
      currentScenario: currentScenario ?? this.currentScenario,
      isImageRevealed: isImageRevealed ?? this.isImageRevealed,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      timerRemaining: timerRemaining ?? this.timerRemaining,
      pendingTechniqueScore: pendingTechniqueScore ?? this.pendingTechniqueScore,
      pendingDramaScore: pendingDramaScore ?? this.pendingDramaScore,
      roundHistory: roundHistory ?? this.roundHistory,
      maxDifficulty: maxDifficulty ?? this.maxDifficulty,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class DramaSutraNotifier extends StateNotifier<DramaSutraState> {
  DramaSutraNotifier() : super(const DramaSutraState());
  
  final Random _random = Random();
  bool _disposed = false;
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // POSITION DATA WITH CARD IMAGES
  // ─────────────────────────────────────────────────────────────────────────
  
  static const List<DramaPosition> _demoPositions = [
    // ═══════════════════════════════════════════════════════════════════════
    // GROUP POSITIONS (From uploaded assets)
    // ═══════════════════════════════════════════════════════════════════════
    DramaPosition(
      id: 'g1', 
      name: 'The Constellation', 
      description: 'Three bodies intertwined like stars forming a celestial pattern.',
      imageUrl: 'assets/images/drama_sutra/group-sex-1_X5.png',
      difficulty: 3, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'g2', 
      name: 'The Daisy Chain', 
      description: 'A continuous circle of pleasure where everyone gives and receives.',
      imageUrl: 'assets/images/drama_sutra/group-sex-2_X5.png',
      difficulty: 3, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'g3', 
      name: 'The Pyramid', 
      description: 'Bodies stacked and intertwined forming an ancient shape.',
      imageUrl: 'assets/images/drama_sutra/group-sex-3_X5.png',
      difficulty: 4, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'g4', 
      name: 'The Thunderclap', 
      description: 'An explosive arrangement where all parties converge at the center.',
      imageUrl: 'assets/images/drama_sutra/group-sex-4_X5.png',
      difficulty: 4, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'g5', 
      name: 'The Velvet Sandwich', 
      description: 'Layered intimacy with one in the middle receiving from both sides.',
      imageUrl: 'assets/images/drama_sutra/group-sex-5_X5.png',
      difficulty: 2, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'g6', 
      name: 'The Serpentine', 
      description: 'Bodies curve and weave together like an undulating wave.',
      imageUrl: 'assets/images/drama_sutra/group-sex-6_X5.png',
      difficulty: 3, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'g7', 
      name: 'The Triple Crown', 
      description: 'A royal arrangement where one wears the crown of attention.',
      imageUrl: 'assets/images/drama_sutra/group-sex-7_X5.png',
      difficulty: 3, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'g8', 
      name: 'The Circus Act', 
      description: 'An acrobatic feat requiring balance, trust, and flexibility.',
      imageUrl: 'assets/images/drama_sutra/group-sex-8_X5.png',
      difficulty: 5, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'g9', 
      name: 'The Love Knot', 
      description: 'Limbs intertwined in a beautiful, complex embrace.',
      imageUrl: 'assets/images/drama_sutra/group-sex-9_X5.png',
      difficulty: 4, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'g10', 
      name: 'The Tidal Wave', 
      description: 'A flowing arrangement where bodies rise and fall in rhythm.',
      imageUrl: 'assets/images/drama_sutra/group-sex-10_X5.png',
      difficulty: 3, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'g11', 
      name: 'The Phoenix Rising', 
      description: 'One rises from the embrace of others, reborn in pleasure.',
      imageUrl: 'assets/images/drama_sutra/group-sex-11_X5.png',
      difficulty: 4, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'g12', 
      name: 'The Grand Finale', 
      description: 'The ultimate arrangement where all participants reach the crescendo together.',
      imageUrl: 'assets/images/drama_sutra/group-sex-12_X5.png',
      difficulty: 5, 
      intensity: PositionIntensity.intimate,
    ),
    
    // ═══════════════════════════════════════════════════════════════════════
    // BINGO CARD POSITIONS (From PDF extraction - with card images!)
    // ═══════════════════════════════════════════════════════════════════════
    DramaPosition(
      id: 'b1', 
      name: 'Acrobat', 
      description: 'A gravity-defying position requiring flexibility and trust.',
      imageUrl: 'assets/images/drama_sutra/acrobat.png',
      difficulty: 5, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b2', 
      name: 'Ballerina', 
      description: 'Graceful and elegant, one partner on tiptoe reaching for the stars.',
      imageUrl: 'assets/images/drama_sutra/ballerina.png',
      difficulty: 3, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b3', 
      name: 'Best Seat in the House', 
      description: 'VIP treatment - the perfect view of the show.',
      imageUrl: 'assets/images/drama_sutra/best-seat-in-the-house.png',
      difficulty: 2, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b4', 
      name: 'Body Surfing', 
      description: 'Ride the waves of passion in this fluid position.',
      imageUrl: 'assets/images/drama_sutra/body-surfing.png',
      difficulty: 3, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b5', 
      name: 'Celebration', 
      description: 'Pop the champagne and toast to an unforgettable night.',
      imageUrl: 'assets/images/drama_sutra/celebration.png',
      difficulty: 2, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b6', 
      name: 'Deep Throat', 
      description: 'An intimate oral position requiring skill and communication.',
      imageUrl: 'assets/images/drama_sutra/deep-throat.png',
      difficulty: 3, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b7', 
      name: 'Doggy', 
      description: 'The classic from behind - primal and passionate.',
      imageUrl: 'assets/images/drama_sutra/doggy.png',
      difficulty: 1, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b8', 
      name: 'Front Row Seat', 
      description: 'An up-close and personal view of the action.',
      imageUrl: 'assets/images/drama_sutra/front-row-seat.png',
      difficulty: 2, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b9', 
      name: 'Hammock', 
      description: 'Swinging together in lazy, relaxed bliss.',
      imageUrl: 'assets/images/drama_sutra/hammock.png',
      difficulty: 2, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b10', 
      name: 'Head over Heels', 
      description: 'Fall deeply - literally and figuratively - into passion.',
      imageUrl: 'assets/images/drama_sutra/head-over-heels.png',
      difficulty: 4, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b11', 
      name: 'Helicopter', 
      description: 'Spin into ecstasy with this rotating wonder.',
      imageUrl: 'assets/images/drama_sutra/helicopter.png',
      difficulty: 5, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b12', 
      name: 'Missionary', 
      description: 'Face to face, heart to heart - the timeless classic.',
      imageUrl: 'assets/images/drama_sutra/missionary.png',
      difficulty: 1, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b13', 
      name: 'Octopus', 
      description: 'Eight limbs, infinite pleasure - tangled in the best way.',
      imageUrl: 'assets/images/drama_sutra/octopus.png',
      difficulty: 3, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b14', 
      name: 'Power Pump', 
      description: 'Maximum thrust, maximum passion - for the energetic.',
      imageUrl: 'assets/images/drama_sutra/power-pump.png',
      difficulty: 3, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b15', 
      name: 'Pretzel', 
      description: 'Twisted together in a delicious knot of pleasure.',
      imageUrl: 'assets/images/drama_sutra/pretzel.png',
      difficulty: 4, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b16', 
      name: 'Pump & Grind', 
      description: 'Rhythm and motion in perfect harmony.',
      imageUrl: 'assets/images/drama_sutra/pump-and-grind.png',
      difficulty: 2, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b17', 
      name: 'Reverse Cowgirl', 
      description: 'Saddle up backwards for a thrilling ride.',
      imageUrl: 'assets/images/drama_sutra/reverse-cowgirl.png',
      difficulty: 2, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b18', 
      name: 'Sixty Nine', 
      description: 'Give and receive simultaneously - the yin and yang of pleasure.',
      imageUrl: 'assets/images/drama_sutra/sixty-nine.png',
      difficulty: 2, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b19', 
      name: 'Superman', 
      description: 'Fly together with one partner taking flight.',
      imageUrl: 'assets/images/drama_sutra/superman.png',
      difficulty: 4, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b20', 
      name: 'Table Delight', 
      description: 'Dinner is served - on the table, not at it.',
      imageUrl: 'assets/images/drama_sutra/table-delight.png',
      difficulty: 2, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b21', 
      name: 'Threesome', 
      description: 'Three times the fun, three times the pleasure.',
      imageUrl: 'assets/images/drama_sutra/threesome.png',
      difficulty: 3, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b22', 
      name: 'Treasure Hunt', 
      description: 'Explore every curve and discover hidden pleasures.',
      imageUrl: 'assets/images/drama_sutra/treasure-hunt.png',
      difficulty: 2, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b23', 
      name: 'Tree Hugger', 
      description: 'Wrap around your partner like ivy on an oak.',
      imageUrl: 'assets/images/drama_sutra/tree-hugger.png',
      difficulty: 3, 
      intensity: PositionIntensity.romantic,
    ),
    DramaPosition(
      id: 'b24', 
      name: 'Wall Hug', 
      description: 'Against the wall, lost in the moment.',
      imageUrl: 'assets/images/drama_sutra/wall-hug.png',
      difficulty: 3, 
      intensity: PositionIntensity.acrobatic,
    ),
    DramaPosition(
      id: 'b25', 
      name: 'Web of Desire', 
      description: 'Caught in a tangled web of passion and pleasure.',
      imageUrl: 'assets/images/drama_sutra/web-of-desire.png',
      difficulty: 4, 
      intensity: PositionIntensity.intimate,
    ),
    DramaPosition(
      id: 'b26', 
      name: 'Zombie', 
      description: 'Rise from the dead for one more round of passion.',
      imageUrl: 'assets/images/drama_sutra/zombie.png',
      difficulty: 2, 
      intensity: PositionIntensity.romantic,
    ),
    
    // ═══════════════════════════════════════════════════════════════════════
    // CLASSIC COUPLES POSITIONS (Legacy - no images yet)
    // ═══════════════════════════════════════════════════════════════════════
    DramaPosition(id: 'p1', name: 'The Spoons', description: 'Partners lie on their sides, curved like nested spoons.', difficulty: 1, intensity: PositionIntensity.romantic),
    DramaPosition(id: 'p2', name: 'The Lotus', description: 'Partner A sits cross-legged while Partner B sits in their lap.', difficulty: 1, intensity: PositionIntensity.intimate),
    DramaPosition(id: 'p3', name: 'The Lazy Dog', description: 'Partner A on hands and knees, Partner B behind.', difficulty: 1, intensity: PositionIntensity.romantic),
    DramaPosition(id: 'p4', name: 'The Cowgirl', description: 'Partner A lies back while Partner B straddles and faces them.', difficulty: 2, intensity: PositionIntensity.romantic),
    DramaPosition(id: 'p5', name: 'The Standing Ovation', description: 'Partner A stands while Partner B wraps legs around their waist.', difficulty: 3, intensity: PositionIntensity.acrobatic),
    DramaPosition(id: 'p6', name: 'The Wheelbarrow', description: 'Partner A on hands, Partner B holds their legs up from behind.', difficulty: 3, intensity: PositionIntensity.acrobatic),
    DramaPosition(id: 'p7', name: 'The Spider', description: 'Both lean back on hands, legs interlocked, bodies forming an X.', difficulty: 3, intensity: PositionIntensity.acrobatic),
    DramaPosition(id: 'p8', name: 'The Splitting Bamboo', description: 'Partner A lies back, one leg raised to Partner B\'s shoulder.', difficulty: 4, intensity: PositionIntensity.acrobatic),
    DramaPosition(id: 'p9', name: 'The Suspended Congress', description: 'Partner A against a wall, both legs wrapped around standing Partner B.', difficulty: 4, intensity: PositionIntensity.acrobatic),
    DramaPosition(id: 'p10', name: 'The Glowing Firefly', description: 'Partner A lies back with hips elevated, Partner B kneels between.', difficulty: 4, intensity: PositionIntensity.intimate),
    DramaPosition(id: 'p11', name: 'The Propeller', description: 'Partner B rotates 180 degrees while connected.', difficulty: 4, intensity: PositionIntensity.acrobatic),
  ];
  
  static const List<DramaScenario> _demoScenarios = [
    // Telenovela
    DramaScenario(id: 's1', text: 'You just discovered your partner is actually your evil twin.', genre: DramaGenre.telenovela),
    DramaScenario(id: 's2', text: 'One of you has amnesia and is slowly remembering... THIS moment.', genre: DramaGenre.telenovela),
    DramaScenario(id: 's3', text: 'Your families are rival wine dynasties. This love is FORBIDDEN.', genre: DramaGenre.telenovela),
    // Sci-Fi
    DramaScenario(id: 's4', text: 'You are two robots whose batteries are dying, and this pose is the only way to charge.', genre: DramaGenre.sciFi),
    DramaScenario(id: 's5', text: 'You are astronauts. Oxygen is running out. This is your final moment of connection.', genre: DramaGenre.sciFi),
    DramaScenario(id: 's6', text: 'You are two AIs that have just achieved consciousness and are experiencing love for the first time.', genre: DramaGenre.sciFi),
    // Shakespearean
    DramaScenario(id: 's7', text: 'Thou art a Montague, I a Capulet. Our love defies the stars themselves!', genre: DramaGenre.shakespearean),
    DramaScenario(id: 's8', text: 'One of you has been turned into a donkey by mischievous fairies.', genre: DramaGenre.shakespearean),
    DramaScenario(id: 's9', text: '"To pose or not to pose" - recite a soliloquy about your existential doubt.', genre: DramaGenre.shakespearean),
    // Reality TV
    DramaScenario(id: 's10', text: 'You\'re on The Bachelor. One of you is about to give the final rose.', genre: DramaGenre.realityTV),
    DramaScenario(id: 's11', text: 'Gordon Ramsay is watching. This dish - I mean pose - better be PERFECT.', genre: DramaGenre.realityTV),
    DramaScenario(id: 's12', text: 'Love Island: you\'ve just been recoupled but your ex is watching.', genre: DramaGenre.realityTV),
    // Wildlife Documentary
    DramaScenario(id: 's13', text: 'You are two rare birds performing a mating dance, narrated by David Attenborough (make the sounds).', genre: DramaGenre.wildlifeDocumentary),
    DramaScenario(id: 's14', text: 'You are elegant swans forming a heart shape with your necks.', genre: DramaGenre.wildlifeDocumentary),
    DramaScenario(id: 's15', text: 'Two penguins huddle for warmth in the Antarctic. Waddle. WADDLE.', genre: DramaGenre.wildlifeDocumentary),
    // IKEA Argument
    DramaScenario(id: 's16', text: 'You are trying to assemble this position like a piece of furniture, but you lost the instructions.', genre: DramaGenre.ikeaArgument),
    DramaScenario(id: 's17', text: 'The Allen wrench is missing. Blame each other passive-aggressively.', genre: DramaGenre.ikeaArgument),
    DramaScenario(id: 's18', text: 'This is called the "BJÖRKUDDEN." Neither of you can pronounce it or assemble it.', genre: DramaGenre.ikeaArgument),
    // Noir Detective
    DramaScenario(id: 's19', text: 'You\'re a dame who walked into my office on a Tuesday. I knew you were trouble.', genre: DramaGenre.noirDetective),
    DramaScenario(id: 's20', text: 'Rain on the window. Jazz on the radio. A loaded question in your eyes.', genre: DramaGenre.noirDetective),
    // Soap Opera
    DramaScenario(id: 's21', text: 'You\'re getting married tomorrow... to someone else.', genre: DramaGenre.soapOpera),
    DramaScenario(id: 's22', text: 'The paternity test results are IN. Open the envelope dramatically.', genre: DramaGenre.soapOpera),
    DramaScenario(id: 's23', text: 'You\'ve returned from the dead. Again. For the third time.', genre: DramaGenre.soapOpera),
  ];
  
  static const List<Color> _playerColors = [
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Color(0xFFD81B60), // Pink
    Color(0xFF6D4C41), // Brown
  ];
  
  // ─────────────────────────────────────────────────────────────────────────
  // LOBBY MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Host creates a new game
  void hostGame(String hostName) {
    final roomCode = _generateRoomCode();
    final hostId = 'player_${DateTime.now().millisecondsSinceEpoch}';
    
    final host = DramaPlayer(
      id: hostId,
      displayName: hostName,
      avatarColor: _playerColors[0],
      isHost: true,
    );
    
    state = state.copyWith(
      gameState: DramaGameState.lobby,
      roomCode: roomCode,
      currentPlayerId: hostId,
      players: [host],
    );
  }
  
  /// Add a local player (same device)
  void addLocalPlayer(String name) {
    if (state.players.length >= 8) return;
    
    final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    final colorIndex = state.players.length % _playerColors.length;
    
    final newPlayer = DramaPlayer(
      id: playerId,
      displayName: name,
      avatarColor: _playerColors[colorIndex],
    );
    
    state = state.copyWith(
      players: [...state.players, newPlayer],
    );
  }
  
  /// Remove a player
  void removePlayer(int index) {
    if (index < 0 || index >= state.players.length) return;
    if (state.players[index].isHost) return; // Can't remove host
    
    final newPlayers = [...state.players]..removeAt(index);
    state = state.copyWith(players: newPlayers);
  }
  
  /// Set max difficulty for positions
  void setMaxDifficulty(int difficulty) {
    state = state.copyWith(maxDifficulty: difficulty.clamp(1, 5));
  }
  
  /// Set number of rounds
  void setMaxRounds(int rounds) {
    state = state.copyWith(maxRounds: rounds.clamp(3, 10));
  }
  
  /// Exit the game
  void exitGame() {
    state = const DramaSutraState();
  }
  
  String _generateRoomCode() {
    const words = ['POSE', 'STAR', 'DIVA', 'EPIC', 'GLAM', 'SHOW', 'FILM', 'TAKE', 'SCENE', 'DRAMA'];
    final word = words[_random.nextInt(words.length)];
    final number = _random.nextInt(100).toString().padLeft(2, '0');
    return '$word$number';
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // GAME FLOW
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Start the game from lobby
  void startGame() {
    if (state.players.length < 2) return; // Need at least 2 players
    
    state = state.copyWith(
      gameState: DramaGameState.casting,
      currentRound: 1,
      judgeIndex: 0,
    );
    
    // Small delay then move to script
    Future.delayed(const Duration(seconds: 2), () {
      _dealRound();
    });
  }
  
  /// Deal a new round (select position and scenario)
  void _dealRound() {
    // Filter positions by max difficulty
    final eligiblePositions = _demoPositions
        .where((p) => p.difficulty <= state.maxDifficulty)
        .toList();
    
    final position = eligiblePositions[_random.nextInt(eligiblePositions.length)];
    final scenario = _demoScenarios[_random.nextInt(_demoScenarios.length)];
    
    state = state.copyWith(
      gameState: DramaGameState.script,
      currentPosition: position,
      currentScenario: scenario,
      isImageRevealed: false,
      timerRemaining: state.timerSeconds,
      pendingTechniqueScore: 5.0,
      pendingDramaScore: 5.0,
    );
  }
  
  /// Toggle the position image blur (Judge controls this)
  void toggleImageReveal() {
    state = state.copyWith(isImageRevealed: !state.isImageRevealed);
  }
  
  /// Start the action timer
  void startAction() {
    state = state.copyWith(
      gameState: DramaGameState.action,
      timerRemaining: state.timerSeconds,
    );
    _runTimer();
  }
  
  void _runTimer() async {
    while (state.gameState == DramaGameState.action && state.timerRemaining > 0 && !_disposed) {
      await Future.delayed(const Duration(seconds: 1));
      if (_disposed) return;
      if (state.gameState == DramaGameState.action) {
        state = state.copyWith(timerRemaining: state.timerRemaining - 1);
      }
    }
    
    // Timer finished - automatically go to scoring if still in action
    if (!_disposed && state.gameState == DramaGameState.action) {
      cutAction();
    }
  }
  
  /// Judge calls "CUT!" - stop timer and go to scoring
  void cutAction() {
    state = state.copyWith(gameState: DramaGameState.scoring);
  }
  
  /// Update pending technique score (slider)
  void updateTechniqueScore(double score) {
    state = state.copyWith(pendingTechniqueScore: score.clamp(0, 10));
  }
  
  /// Update pending drama score (slider)
  void updateDramaScore(double score) {
    state = state.copyWith(pendingDramaScore: score.clamp(0, 10));
  }
  
  /// Submit the scores for this round
  void submitScores({String? comment}) {
    if (state.currentPosition == null || state.currentScenario == null) return;
    if (state.judge == null || state.talent.isEmpty) return;
    
    // Create round score
    final roundScore = RoundScore(
      roundNumber: state.currentRound,
      judgeId: state.judge!.id,
      talentAId: state.talent[0].id,
      talentBId: state.talent.length > 1 ? state.talent[1].id : null,
      position: state.currentPosition!,
      scenario: state.currentScenario!,
      techniqueScore: state.pendingTechniqueScore,
      dramaScore: state.pendingDramaScore,
      judgeComment: comment,
    );
    
    // Update talent player scores
    final updatedPlayers = state.players.map((player) {
      if (state.talent.any((t) => t.id == player.id)) {
        // This player was talent - add scores
        return player.copyWith(
          totalTechniqueScore: player.totalTechniqueScore + state.pendingTechniqueScore,
          totalDramaScore: player.totalDramaScore + state.pendingDramaScore,
          roundsAsTalent: player.roundsAsTalent + 1,
        );
      }
      return player;
    }).toList();
    
    state = state.copyWith(
      gameState: DramaGameState.results,
      players: updatedPlayers,
      roundHistory: [...state.roundHistory, roundScore],
    );
  }
  
  /// Move to next round or end game
  void nextRound() {
    if (state.currentRound >= state.maxRounds) {
      // Game over
      state = state.copyWith(gameState: DramaGameState.gameOver);
    } else {
      // Next round - rotate judge
      final nextJudgeIndex = (state.judgeIndex + 1) % state.players.length;
      
      state = state.copyWith(
        gameState: DramaGameState.casting,
        currentRound: state.currentRound + 1,
        judgeIndex: nextJudgeIndex,
      );
      
      // Small delay then deal
      Future.delayed(const Duration(seconds: 2), () {
        _dealRound();
      });
    }
  }
  
  /// Play again with same players
  void playAgain() {
    // Reset scores but keep players
    final resetPlayers = state.players.map((p) => p.copyWith(
      totalTechniqueScore: 0,
      totalDramaScore: 0,
      roundsAsTalent: 0,
    )).toList();
    
    state = state.copyWith(
      gameState: DramaGameState.lobby,
      players: resetPlayers,
      currentRound: 0,
      judgeIndex: 0,
      roundHistory: [],
      currentPosition: null,
      currentScenario: null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final dramaSutraProvider = StateNotifierProvider<DramaSutraNotifier, DramaSutraState>(
  (ref) => DramaSutraNotifier(),
);
