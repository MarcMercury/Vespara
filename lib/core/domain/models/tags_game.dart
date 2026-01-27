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
  shareOrDare, // Share or Dare - Truth or Dare evolved
  pathOfPleasure, // Comparative ranking game
  laneOfLust, // Timeline/Shit Happens style game with desire index
  dramaSutra, // Kama Sutra meets Improv Comedy
  flashFreeze, // Flash & Freeze - Red Light Green Light adult edition
  diceBreakers, // Dice Breakers - Naughty dice rolling game
}

extension GameCategoryExtension on GameCategory {
  String get displayName {
    switch (this) {
      case GameCategory.downToClown:
        return 'Down to Clown';
      case GameCategory.icebreakers:
        return 'Ice Breakers';
      case GameCategory.shareOrDare:
        return 'Share or Dare';
      case GameCategory.pathOfPleasure:
        return 'Path of Pleasure';
      case GameCategory.laneOfLust:
        return 'Lane of Lust';
      case GameCategory.dramaSutra:
        return 'Drama-Sutra';
      case GameCategory.flashFreeze:
        return 'Flash & Freeze';
      case GameCategory.diceBreakers:
        return 'Dice Breakers';
    }
  }

  String get description {
    switch (this) {
      case GameCategory.downToClown:
        return 'Heads Up-style guessing game with spicy vocab.';
      case GameCategory.icebreakers:
        return 'Light conversation starters for new connections.';
      case GameCategory.shareOrDare:
        return 'Spin the wheel, share a secret or prove your courage.';
      case GameCategory.pathOfPleasure:
        return 'Family Feud-style ranking game of desires.';
      case GameCategory.laneOfLust:
        return 'Timeline-style game ranking desires by intensity.';
      case GameCategory.dramaSutra:
        return 'Strike a pose! Director describes, group performs.';
      case GameCategory.flashFreeze:
        return 'Red Light, Green Light evolved. Exposure requires endurance.';
      case GameCategory.diceBreakers:
        return 'Roll the dice and let fate decide what happens next.';
    }
  }

  ConsentLevel get minimumConsentLevel {
    switch (this) {
      case GameCategory.icebreakers:
      case GameCategory.downToClown:
        return ConsentLevel.green;
      case GameCategory.shareOrDare:
      case GameCategory.pathOfPleasure:
      case GameCategory.laneOfLust:
        return ConsentLevel.green; // Can scale to any level
      case GameCategory.flashFreeze:
        return ConsentLevel.yellow;
      case GameCategory.dramaSutra:
        return ConsentLevel.red;
      case GameCategory.diceBreakers:
        return ConsentLevel.yellow; // Can scale to RED with 3 dice
    }
  }

  int get minPlayers {
    switch (this) {
      case GameCategory.downToClown:
      case GameCategory.icebreakers:
      case GameCategory.shareOrDare:
      case GameCategory.pathOfPleasure:
      case GameCategory.laneOfLust:
      case GameCategory.dramaSutra:
        return 2;
      case GameCategory.flashFreeze:
        return 3; // Need at least 1 Signal + 2 players
      case GameCategory.diceBreakers:
        return 2;
    }
  }

  int get maxPlayers {
    switch (this) {
      case GameCategory.downToClown:
      case GameCategory.icebreakers:
      case GameCategory.shareOrDare:
      case GameCategory.pathOfPleasure:
      case GameCategory.laneOfLust:
      case GameCategory.dramaSutra:
      case GameCategory.flashFreeze:
        return 8;
      case GameCategory.diceBreakers:
        return 10;
    }
  }

  /// Velocity Meter (0-100 mph) - "How fast might this get you going?"
  int get velocityMph {
    switch (this) {
      case GameCategory.icebreakers:
        return 25; // Warm up
      case GameCategory.downToClown:
        return 30; // Light cruising
      case GameCategory.shareOrDare:
        return 50; // Picking up speed
      case GameCategory.pathOfPleasure:
        return 55; // Highway speed
      case GameCategory.laneOfLust:
        return 60; // Fast lane
      case GameCategory.flashFreeze:
        return 75; // Racing
      case GameCategory.dramaSutra:
        return 80; // Full speed
      case GameCategory.diceBreakers:
        return 99; // Redline
    }
  }

  String get velocityLabel {
    return '$velocityMph mph';
  }

  /// Heat Rating (PG-XXX) - "What kind of action might you see?"
  String get heatRating {
    switch (this) {
      case GameCategory.icebreakers:
        return 'PG-13'; // Conversation starters
      case GameCategory.downToClown:
        return 'PG-13'; // Fun challenges
      case GameCategory.shareOrDare:
        return 'PG-13-X'; // Ranges from mild to wild
      case GameCategory.pathOfPleasure:
        return 'PG-13'; // Light touching, kissing
      case GameCategory.laneOfLust:
        return 'R'; // Risqué, passionate
      case GameCategory.flashFreeze:
        return 'X'; // Explicit, adventurous
      case GameCategory.dramaSutra:
        return 'X'; // Uninhibited, wild
      case GameCategory.diceBreakers:
        return 'XXX'; // Fast, direct, risqué
    }
  }

  /// Duration - "How long will you be playing?"
  String get durationLabel {
    switch (this) {
      case GameCategory.icebreakers:
      case GameCategory.downToClown:
      case GameCategory.flashFreeze:
      case GameCategory.dramaSutra:
        return 'Quickie'; // 5-10 min
      case GameCategory.shareOrDare:
      case GameCategory.pathOfPleasure:
      case GameCategory.laneOfLust:
      case GameCategory.diceBreakers:
        return 'Foreplay'; // 10-20 min
    }
  }

  String get durationTime {
    switch (durationLabel) {
      case 'Quickie':
        return '5-15 min';
      case 'Foreplay':
        return '20-45 min';
      case 'Full Session':
        return '60+ min';
      default:
        return '';
    }
  }
}

/// TAGS Game Model
class TagsGame extends Equatable {
  const TagsGame({
    required this.id,
    required this.category,
    required this.title,
    this.description,
    this.minPlayers = 2,
    this.maxPlayers = 10,
    this.currentConsentLevel = ConsentLevel.green,
    this.participantIds = const [],
    this.createdAt,
    this.isActive = true,
    this.gameState,
  });

  factory TagsGame.fromJson(Map<String, dynamic> json) => TagsGame(
        id: json['id'] as String,
        category: GameCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => GameCategory.downToClown,
        ),
        title: json['title'] as String,
        description: json['description'] as String?,
        minPlayers: json['min_players'] as int? ?? 2,
        maxPlayers: json['max_players'] as int? ?? 10,
        currentConsentLevel: ConsentLevel.values.firstWhere(
          (e) => e.name == json['consent_level'],
          orElse: () => ConsentLevel.green,
        ),
        participantIds: List<String>.from(json['participant_ids'] ?? []),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
        gameState: json['game_state'] as Map<String, dynamic>?,
      );
  final String id;
  final GameCategory category;
  final String title;
  final String? description;
  final int minPlayers;
  final int maxPlayers;
  final ConsentLevel currentConsentLevel;
  final List<String> participantIds;
  final DateTime? createdAt;
  final bool isActive;
  final Map<String, dynamic>? gameState;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'title': title,
        'description': description,
        'min_players': minPlayers,
        'max_players': maxPlayers,
        'consent_level': currentConsentLevel.name,
        'participant_ids': participantIds,
        'created_at': createdAt?.toIso8601String(),
        'is_active': isActive,
        'game_state': gameState,
      };

  TagsGame copyWith({
    String? id,
    GameCategory? category,
    String? title,
    String? description,
    int? minPlayers,
    int? maxPlayers,
    ConsentLevel? currentConsentLevel,
    List<String>? participantIds,
    DateTime? createdAt,
    bool? isActive,
    Map<String, dynamic>? gameState,
  }) =>
      TagsGame(
        id: id ?? this.id,
        category: category ?? this.category,
        title: title ?? this.title,
        description: description ?? this.description,
        minPlayers: minPlayers ?? this.minPlayers,
        maxPlayers: maxPlayers ?? this.maxPlayers,
        currentConsentLevel: currentConsentLevel ?? this.currentConsentLevel,
        participantIds: participantIds ?? this.participantIds,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
        gameState: gameState ?? this.gameState,
      );

  @override
  List<Object?> get props => [
        id,
        category,
        title,
        description,
        minPlayers,
        maxPlayers,
        currentConsentLevel,
        participantIds,
        createdAt,
        isActive,
        gameState,
      ];
}

/// Game Card for Truth or Dare / Pleasure Deck
class GameCard extends Equatable {
  // 1-5

  const GameCard({
    required this.id,
    required this.content,
    required this.level,
    required this.isTruth,
    required this.intensity,
  });

  factory GameCard.fromJson(Map<String, dynamic> json) => GameCard(
        id: json['id'] as String,
        content: json['content'] as String,
        level: ConsentLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => ConsentLevel.green,
        ),
        isTruth: json['is_truth'] as bool,
        intensity: json['intensity'] as int? ?? 1,
      );
  final String id;
  final String content;
  final ConsentLevel level;
  final bool isTruth;
  final int intensity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'level': level.name,
        'is_truth': isTruth,
        'intensity': intensity,
      };

  @override
  List<Object?> get props => [id, content, level, isTruth, intensity];
}
