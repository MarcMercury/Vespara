import 'package:equatable/equatable.dart';

/// Consent level for TAGS games
enum ConsentLevel {
  /// 🟢 GREEN - Social & Flirtatious (No nudity, conversation focused)
  green,
  
  /// 🟡 YELLOW - Sensual & Suggestive (Light touch, opt-in arousal)
  yellow,
  
  /// 🔴 RED - Erotic & Explicit (Nudity allowed, pre-consented)
  red,
}

extension ConsentLevelExtension on ConsentLevel {
  String get displayName {
    switch (this) {
      case ConsentLevel.green:
        return 'Social';
      case ConsentLevel.yellow:
        return 'Sensual';
      case ConsentLevel.red:
        return 'Erotic';
    }
  }
  
  String get description {
    switch (this) {
      case ConsentLevel.green:
        return 'Flirtatious & playful. No nudity required.';
      case ConsentLevel.yellow:
        return 'Sensual & suggestive. Light touch, opt-in.';
      case ConsentLevel.red:
        return 'Erotic & explicit. Pre-consented environment.';
    }
  }
  
  String get emoji {
    switch (this) {
      case ConsentLevel.green:
        return '🟢';
      case ConsentLevel.yellow:
        return '🟡';
      case ConsentLevel.red:
        return '🔴';
    }
  }
  
  int get value {
    switch (this) {
      case ConsentLevel.green:
        return 0;
      case ConsentLevel.yellow:
        return 1;
      case ConsentLevel.red:
        return 2;
    }
  }
}

/// TAGS Game Category
enum GameCategory {
  downToClown, // Heads Up-style guessing game
  icebreakers, // Ice Breakers conversation starters
  velvetRope, // Velvet Rope - Truth or Dare evolved
  pathOfPleasure, // Comparative ranking game
  laneOfLust, // Timeline/Shit Happens style game with desire index
  dramaSutra, // Kama Sutra meets Improv Comedy
  flashFreeze, // Flash & Freeze - Red Light Green Light adult edition
}

extension GameCategoryExtension on GameCategory {
  String get displayName {
    switch (this) {
      case GameCategory.downToClown:
        return 'Down to Clown';
      case GameCategory.icebreakers:
        return 'Ice Breakers';
      case GameCategory.velvetRope:
        return 'Velvet Rope';
      case GameCategory.pathOfPleasure:
        return 'Path of Pleasure';
      case GameCategory.laneOfLust:
        return 'Lane of Lust';
      case GameCategory.dramaSutra:
        return 'Drama-Sutra';
      case GameCategory.flashFreeze:
        return 'Flash & Freeze';
    }
  }
  
  String get description {
    switch (this) {
      case GameCategory.downToClown:
        return 'Heads Up-style guessing game with kink vocab.';
      case GameCategory.icebreakers:
        return 'Light conversation starters for new connections.';
      case GameCategory.velvetRope:
        return 'Truth or Dare evolved. Consent-tiered card deck.';
      case GameCategory.pathOfPleasure:
        return 'Comparative ranking game of desires.';
      case GameCategory.laneOfLust:
        return 'Timeline-style game ranking desires by intensity.';
      case GameCategory.dramaSutra:
        return 'Kama Sutra positions with dramatic scenarios.';
      case GameCategory.flashFreeze:
        return 'Red Light, Green Light evolved. Exposure requires endurance.';
    }
  }
  
  ConsentLevel get minimumConsentLevel {
    switch (this) {
      case GameCategory.icebreakers:
      case GameCategory.downToClown:
        return ConsentLevel.green;
      case GameCategory.velvetRope:
      case GameCategory.pathOfPleasure:
      case GameCategory.laneOfLust:
        return ConsentLevel.green; // Can scale to any level
      case GameCategory.flashFreeze:
        return ConsentLevel.yellow;
      case GameCategory.dramaSutra:
        return ConsentLevel.red;
    }
  }
  
  int get minPlayers {
    switch (this) {
      case GameCategory.downToClown:
      case GameCategory.icebreakers:
      case GameCategory.velvetRope:
      case GameCategory.pathOfPleasure:
      case GameCategory.laneOfLust:
      case GameCategory.dramaSutra:
        return 2;
      case GameCategory.flashFreeze:
        return 3; // Need at least 1 Signal + 2 players
    }
  }
  
  int get maxPlayers {
    switch (this) {
      case GameCategory.downToClown:
      case GameCategory.icebreakers:
      case GameCategory.velvetRope:
      case GameCategory.pathOfPleasure:
      case GameCategory.laneOfLust:
      case GameCategory.dramaSutra:
      case GameCategory.flashFreeze:
        return 8;
    }
  }
}

/// TAGS Game Model
class TagsGame extends Equatable {
  final String id;
  final GameCategory category;
  final String title;
  final String? description;
  final ConsentLevel currentConsentLevel;
  final List<String> participantIds;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, dynamic>? gameState;
  
  const TagsGame({
    required this.id,
    required this.category,
    required this.title,
    this.description,
    required this.currentConsentLevel,
    required this.participantIds,
    required this.createdAt,
    this.isActive = true,
    this.gameState,
  });
  
  factory TagsGame.fromJson(Map<String, dynamic> json) {
    return TagsGame(
      id: json['id'] as String,
      category: GameCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GameCategory.truthOrDare,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      currentConsentLevel: ConsentLevel.values.firstWhere(
        (e) => e.name == json['consent_level'],
        orElse: () => ConsentLevel.green,
      ),
      participantIds: List<String>.from(json['participant_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      gameState: json['game_state'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'description': description,
      'consent_level': currentConsentLevel.name,
      'participant_ids': participantIds,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'game_state': gameState,
    };
  }
  
  TagsGame copyWith({
    String? id,
    GameCategory? category,
    String? title,
    String? description,
    ConsentLevel? currentConsentLevel,
    List<String>? participantIds,
    DateTime? createdAt,
    bool? isActive,
    Map<String, dynamic>? gameState,
  }) {
    return TagsGame(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      currentConsentLevel: currentConsentLevel ?? this.currentConsentLevel,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      gameState: gameState ?? this.gameState,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    category,
    title,
    description,
    currentConsentLevel,
    participantIds,
    createdAt,
    isActive,
    gameState,
  ];
}

/// Game Card for Truth or Dare / Pleasure Deck
class GameCard extends Equatable {
  final String id;
  final String content;
  final ConsentLevel level;
  final bool isTruth;
  final int intensity; // 1-5
  
  const GameCard({
    required this.id,
    required this.content,
    required this.level,
    required this.isTruth,
    required this.intensity,
  });
  
  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] as String,
      content: json['content'] as String,
      level: ConsentLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => ConsentLevel.green,
      ),
      isTruth: json['is_truth'] as bool,
      intensity: json['intensity'] as int? ?? 1,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'level': level.name,
      'is_truth': isTruth,
      'intensity': intensity,
    };
  }
  
  @override
  List<Object?> get props => [id, content, level, isTruth, intensity];
}
