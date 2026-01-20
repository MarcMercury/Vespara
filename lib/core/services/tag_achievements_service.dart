import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tag_analytics_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG ACHIEVEMENTS SERVICE
/// ════════════════════════════════════════════════════════════════════════════
///
/// Cross-game achievement system for all TAG games.
/// Handles achievement checking, unlocking, progress tracking, and display.

class TagAchievementsService {
  final SupabaseClient _supabase;

  TagAchievementsService(this._supabase);

  // ═══════════════════════════════════════════════════════════════════════════
  // ACHIEVEMENT RETRIEVAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all available achievements
  Future<List<TagAchievement>> getAllAchievements() async {
    try {
      final response = await _supabase
          .from('tag_achievements')
          .select()
          .eq('is_active', true)
          .order('category')
          .order('points');

      return (response as List)
          .map((json) => TagAchievement.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Achievements: Failed to get all achievements - $e');
      return [];
    }
  }

  /// Get achievements for a specific game
  Future<List<TagAchievement>> getGameAchievements(TagGameType gameType) async {
    try {
      final response = await _supabase
          .from('tag_achievements')
          .select()
          .eq('is_active', true)
          .or('game_type.is.null,game_type.eq.${gameType.dbValue}')
          .order('points');

      return (response as List)
          .map((json) => TagAchievement.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Achievements: Failed to get game achievements - $e');
      return [];
    }
  }

  /// Get user's unlocked achievements
  Future<List<UnlockedAchievement>> getUserAchievements() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('tag_user_achievements')
          .select('*, achievement:tag_achievements(*)')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return (response as List)
          .map((json) => UnlockedAchievement.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Achievements: Failed to get user achievements - $e');
      return [];
    }
  }

  /// Get unseen achievement notifications
  Future<List<UnlockedAchievement>> getUnseenAchievements() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.rpc('get_unseen_achievements', params: {
        'p_user_id': userId,
      });

      return (response as List).map((json) => UnlockedAchievement(
        achievementId: json['achievement_id'],
        unlockedAt: DateTime.parse(json['unlocked_at']),
        isSeen: false,
        achievement: TagAchievement(
          id: json['achievement_id'],
          name: json['name'],
          description: json['description'],
          icon: json['icon'],
          category: AchievementCategory.fromString(json['category']),
          rarity: AchievementRarity.fromString(json['rarity']),
          points: json['points'],
        ),
      )).toList();
    } catch (e) {
      debugPrint('Achievements: Failed to get unseen achievements - $e');
      return [];
    }
  }

  /// Mark achievements as seen
  Future<void> markAchievementsSeen(List<String> achievementIds) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('mark_achievements_seen', params: {
        'p_user_id': userId,
        'p_achievement_ids': achievementIds,
      });
    } catch (e) {
      debugPrint('Achievements: Failed to mark seen - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACHIEVEMENT UNLOCKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Attempt to unlock an achievement
  Future<bool> unlockAchievement({
    required String achievementId,
    String? sessionId,
    TagGameType? gameType,
    Map<String, dynamic>? progressSnapshot,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase.rpc('check_and_unlock_achievement', params: {
        'p_user_id': userId,
        'p_achievement_id': achievementId,
        'p_session_id': sessionId,
        'p_game_type': gameType?.dbValue,
        'p_progress_snapshot': progressSnapshot ?? {},
      });

      return result == true;
    } catch (e) {
      debugPrint('Achievements: Failed to unlock $achievementId - $e');
      return false;
    }
  }

  /// Check and unlock multiple achievements based on game stats
  Future<List<String>> checkAchievements({
    required TagGameType gameType,
    required int gamesPlayed,
    required int cardsCompleted,
    required int cardsSkipped,
    required int playerCount,
    required String contentRating,
    required int sessionMinutes,
    String? sessionId,
  }) async {
    final unlockedIds = <String>[];
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return unlockedIds;

    // Get user stats for comprehensive checking
    final stats = await _getUserGameStats();
    final totalGamesPlayed = stats?['total_games_played'] ?? 0;
    final totalCardsCompleted = stats?['total_cards_completed'] ?? 0;
    final gamesPlayedByType = Map<String, int>.from(stats?['games_played'] ?? {});
    
    // Progress snapshot for context
    final snapshot = {
      'games_played': totalGamesPlayed,
      'cards_completed': totalCardsCompleted,
      'game_type': gameType.dbValue,
      'content_rating': contentRating,
      'player_count': playerCount,
    };

    // ═══════════════════════════════════════════════════════════════════════
    // MILESTONE ACHIEVEMENTS
    // ═══════════════════════════════════════════════════════════════════════
    
    // First game
    if (totalGamesPlayed == 1) {
      if (await unlockAchievement(achievementId: 'first_game', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('first_game');
      }
    }

    // Games played milestones
    final gameMilestones = {
      10: 'games_10',
      50: 'games_50',
      100: 'games_100',
      500: 'games_500',
      1000: 'games_1000',
    };
    
    for (final entry in gameMilestones.entries) {
      if (totalGamesPlayed >= entry.key) {
        if (await unlockAchievement(achievementId: entry.value, sessionId: sessionId, progressSnapshot: snapshot)) {
          unlockedIds.add(entry.value);
        }
      }
    }

    // Cards completed milestones
    final cardMilestones = {
      100: 'cards_100',
      500: 'cards_500',
      1000: 'cards_1000',
    };
    
    for (final entry in cardMilestones.entries) {
      if (totalCardsCompleted >= entry.key) {
        if (await unlockAchievement(achievementId: entry.value, sessionId: sessionId, progressSnapshot: snapshot)) {
          unlockedIds.add(entry.value);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EXPLORER ACHIEVEMENTS
    // ═══════════════════════════════════════════════════════════════════════
    
    // First time playing this game type
    final gameTypeAchievements = {
      TagGameType.downToClown: 'try_dtc',
      TagGameType.iceBreakers: 'try_icebreakers',
      TagGameType.velvetRope: 'try_velvet',
      TagGameType.pathOfPleasure: 'try_pop',
      TagGameType.laneOfLust: 'try_lol',
      TagGameType.dramaSutra: 'try_drama',
      TagGameType.flashFreeze: 'try_flash',
    };
    
    if (gameTypeAchievements.containsKey(gameType)) {
      if (await unlockAchievement(
        achievementId: gameTypeAchievements[gameType]!, 
        sessionId: sessionId,
        gameType: gameType,
        progressSnapshot: snapshot,
      )) {
        unlockedIds.add(gameTypeAchievements[gameType]!);
      }
    }

    // Unique games played
    final uniqueGames = gamesPlayedByType.entries.where((e) => e.value > 0).length;
    if (uniqueGames >= 3) {
      if (await unlockAchievement(achievementId: 'explorer_3', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('explorer_3');
      }
    }
    if (uniqueGames >= 5) {
      if (await unlockAchievement(achievementId: 'explorer_5', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('explorer_5');
      }
    }
    if (uniqueGames >= 7) {
      if (await unlockAchievement(achievementId: 'explorer_7', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('explorer_7');
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SPICY ACHIEVEMENTS
    // ═══════════════════════════════════════════════════════════════════════
    
    final spicyAchievements = {
      'pg13': 'spicy_pg13',
      'r': 'spicy_r',
      'x': 'spicy_x',
      'xxx': 'spicy_xxx',
    };
    
    if (spicyAchievements.containsKey(contentRating)) {
      if (await unlockAchievement(
        achievementId: spicyAchievements[contentRating]!, 
        sessionId: sessionId,
        progressSnapshot: snapshot,
      )) {
        unlockedIds.add(spicyAchievements[contentRating]!);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SPECIALIST ACHIEVEMENTS
    // ═══════════════════════════════════════════════════════════════════════
    
    final gameCount = gamesPlayedByType[gameType.dbValue] ?? 0;
    final specialistMilestones = _getSpecialistMilestones(gameType);
    
    for (final entry in specialistMilestones.entries) {
      if (gameCount >= entry.key) {
        if (await unlockAchievement(
          achievementId: entry.value, 
          sessionId: sessionId,
          gameType: gameType,
          progressSnapshot: snapshot,
        )) {
          unlockedIds.add(entry.value);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SOCIAL ACHIEVEMENTS
    // ═══════════════════════════════════════════════════════════════════════
    
    if (playerCount >= 4) {
      if (await unlockAchievement(achievementId: 'party_4', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('party_4');
      }
    }
    if (playerCount >= 6) {
      if (await unlockAchievement(achievementId: 'party_6', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('party_6');
      }
    }
    if (playerCount >= 8) {
      if (await unlockAchievement(achievementId: 'party_8', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('party_8');
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RARE ACHIEVEMENTS
    // ═══════════════════════════════════════════════════════════════════════
    
    // Perfect game (no skips)
    if (cardsSkipped == 0 && cardsCompleted >= 10) {
      if (await unlockAchievement(achievementId: 'perfectionist', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('perfectionist');
      }
    }

    // Marathon session
    if (sessionMinutes >= 120) {
      if (await unlockAchievement(achievementId: 'marathon', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('marathon');
      }
    }

    // Speed demon
    if (sessionMinutes <= 5 && cardsCompleted >= 10) {
      if (await unlockAchievement(achievementId: 'speed_demon', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('speed_demon');
      }
    }

    // Time-based achievements
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 4) {
      if (await unlockAchievement(achievementId: 'night_owl', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('night_owl');
      }
    }
    if (hour >= 4 && hour < 6) {
      if (await unlockAchievement(achievementId: 'early_bird', sessionId: sessionId, progressSnapshot: snapshot)) {
        unlockedIds.add('early_bird');
      }
    }

    return unlockedIds;
  }

  Map<int, String> _getSpecialistMilestones(TagGameType gameType) {
    return switch (gameType) {
      TagGameType.downToClown => {10: 'dtc_10', 50: 'dtc_50', 100: 'dtc_master'},
      TagGameType.iceBreakers => {10: 'icebreakers_10', 50: 'icebreakers_50'},
      TagGameType.velvetRope => {10: 'velvet_10', 50: 'velvet_50'},
      TagGameType.pathOfPleasure => {10: 'pop_10', 50: 'pop_50'},
      TagGameType.laneOfLust => {10: 'lol_10', 50: 'lol_50'},
      TagGameType.dramaSutra => {10: 'drama_10', 50: 'drama_50'},
      TagGameType.flashFreeze => {10: 'flash_10', 50: 'flash_50'},
    };
  }

  Future<Map<String, dynamic>?> _getUserGameStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('tag_user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACHIEVEMENT PROGRESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get progress for all progressive achievements
  Future<Map<String, AchievementProgress>> getProgress() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('tag_achievement_progress')
          .select()
          .eq('user_id', userId);

      final result = <String, AchievementProgress>{};
      for (final json in response) {
        result[json['achievement_id']] = AchievementProgress(
          achievementId: json['achievement_id'],
          currentValue: json['current_value'],
          targetValue: json['target_value'],
        );
      }
      return result;
    } catch (e) {
      debugPrint('Achievements: Failed to get progress - $e');
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACHIEVEMENT SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user's achievement summary/stats
  Future<AchievementSummary?> getSummary() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.rpc('get_achievement_summary', params: {
        'p_user_id': userId,
      });

      if (response == null || (response as List).isEmpty) return null;

      final data = response[0];
      return AchievementSummary(
        totalUnlocked: data['total_unlocked'] ?? 0,
        totalAvailable: data['total_available'] ?? 0,
        totalPoints: data['total_points'] ?? 0,
        unlockedByCategory: Map<String, int>.from(data['unlocked_by_category'] ?? {}),
        unlockedByRarity: Map<String, int>.from(data['unlocked_by_rarity'] ?? {}),
      );
    } catch (e) {
      debugPrint('Achievements: Failed to get summary - $e');
      return null;
    }
  }

  /// Get user's total achievement points
  Future<int> getPoints() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final result = await _supabase.rpc('get_user_achievement_points', params: {
        'p_user_id': userId,
      });

      return result as int? ?? 0;
    } catch (e) {
      debugPrint('Achievements: Failed to get points - $e');
      return 0;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Achievement definition
class TagAchievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int points;
  final Map<String, dynamic>? requirements;
  final TagGameType? gameType;
  final bool isHidden;

  TagAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.rarity,
    required this.points,
    this.requirements,
    this.gameType,
    this.isHidden = false,
  });

  factory TagAchievement.fromJson(Map<String, dynamic> json) {
    return TagAchievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'] ?? 'trophy',
      category: AchievementCategory.fromString(json['category']),
      rarity: AchievementRarity.fromString(json['rarity']),
      points: json['points'] ?? 10,
      requirements: json['requirements'],
      gameType: json['game_type'] != null
          ? TagGameType.fromDbValue(json['game_type'])
          : null,
      isHidden: json['is_hidden'] ?? false,
    );
  }

  /// Get Material icon for this achievement
  IconData get iconData {
    // Map icon string to IconData
    return switch (icon) {
      'play_arrow' => Icons.play_arrow,
      'trending_up' => Icons.trending_up,
      'star' => Icons.star,
      'military_tech' => Icons.military_tech,
      'workspace_premium' => Icons.workspace_premium,
      'diamond' => Icons.diamond,
      'style' => Icons.style,
      'collections' => Icons.collections,
      'auto_awesome' => Icons.auto_awesome,
      'explore' => Icons.explore,
      'travel_explore' => Icons.travel_explore,
      'emoji_events' => Icons.emoji_events,
      'sentiment_very_satisfied' => Icons.sentiment_very_satisfied,
      'ac_unit' => Icons.ac_unit,
      'local_bar' => Icons.local_bar,
      'route' => Icons.route,
      'local_fire_department' => Icons.local_fire_department,
      'theater_comedy' => Icons.theater_comedy,
      'camera' => Icons.camera,
      'thermostat' => Icons.thermostat,
      'whatshot' => Icons.whatshot,
      'outdoor_grill' => Icons.outdoor_grill,
      'mood' => Icons.mood,
      'face' => Icons.face,
      'nightlife' => Icons.nightlife,
      'verified' => Icons.verified,
      'hiking' => Icons.hiking,
      'directions' => Icons.directions,
      'school' => Icons.school,
      'flash_on' => Icons.flash_on,
      'groups' => Icons.groups,
      'celebration' => Icons.celebration,
      'diversity_3' => Icons.diversity_3,
      'event' => Icons.event,
      'looks_3' => Icons.looks_3,
      'date_range' => Icons.date_range,
      'calendar_month' => Icons.calendar_month,
      'event_available' => Icons.event_available,
      'thumb_up' => Icons.thumb_up,
      'nights_stay' => Icons.nights_stay,
      'wb_twilight' => Icons.wb_twilight,
      'timer' => Icons.timer,
      'speed' => Icons.speed,
      'update' => Icons.update,
      'photo_library' => Icons.photo_library,
      'camera_roll' => Icons.camera_roll,
      _ => Icons.emoji_events,
    };
  }

  /// Get color for this achievement's rarity
  Color get rarityColor => rarity.color;
}

/// User's unlocked achievement
class UnlockedAchievement {
  final String achievementId;
  final DateTime unlockedAt;
  final String? unlockedInSession;
  final String? unlockedInGame;
  final bool isSeen;
  final TagAchievement? achievement;

  UnlockedAchievement({
    required this.achievementId,
    required this.unlockedAt,
    this.unlockedInSession,
    this.unlockedInGame,
    this.isSeen = true,
    this.achievement,
  });

  factory UnlockedAchievement.fromJson(Map<String, dynamic> json) {
    return UnlockedAchievement(
      achievementId: json['achievement_id'],
      unlockedAt: DateTime.parse(json['unlocked_at']),
      unlockedInSession: json['unlocked_in_session'],
      unlockedInGame: json['unlocked_in_game'],
      isSeen: json['is_seen'] ?? true,
      achievement: json['achievement'] != null
          ? TagAchievement.fromJson(json['achievement'])
          : null,
    );
  }
}

/// Progress toward an achievement
class AchievementProgress {
  final String achievementId;
  final int currentValue;
  final int targetValue;

  AchievementProgress({
    required this.achievementId,
    required this.currentValue,
    required this.targetValue,
  });

  double get percentage => targetValue > 0 ? currentValue / targetValue : 0;
  bool get isComplete => currentValue >= targetValue;
}

/// User's achievement summary
class AchievementSummary {
  final int totalUnlocked;
  final int totalAvailable;
  final int totalPoints;
  final Map<String, int> unlockedByCategory;
  final Map<String, int> unlockedByRarity;

  AchievementSummary({
    required this.totalUnlocked,
    required this.totalAvailable,
    required this.totalPoints,
    required this.unlockedByCategory,
    required this.unlockedByRarity,
  });

  double get completionPercentage =>
      totalAvailable > 0 ? totalUnlocked / totalAvailable : 0;
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum AchievementCategory {
  milestone('milestone', 'Milestones'),
  explorer('explorer', 'Explorer'),
  social('social', 'Social'),
  spicy('spicy', 'Spicy'),
  specialist('specialist', 'Specialist'),
  streak('streak', 'Streaks'),
  rare('rare', 'Rare'),
  seasonal('seasonal', 'Seasonal');

  final String dbValue;
  final String displayName;

  const AchievementCategory(this.dbValue, this.displayName);

  static AchievementCategory fromString(String value) {
    return AchievementCategory.values.firstWhere(
      (c) => c.dbValue == value,
      orElse: () => AchievementCategory.milestone,
    );
  }
}

enum AchievementRarity {
  common('common', 'Common', Color(0xFF9E9E9E)),
  uncommon('uncommon', 'Uncommon', Color(0xFF4CAF50)),
  rare('rare', 'Rare', Color(0xFF2196F3)),
  epic('epic', 'Epic', Color(0xFF9C27B0)),
  legendary('legendary', 'Legendary', Color(0xFFFF9800));

  final String dbValue;
  final String displayName;
  final Color color;

  const AchievementRarity(this.dbValue, this.displayName, this.color);

  static AchievementRarity fromString(String value) {
    return AchievementRarity.values.firstWhere(
      (r) => r.dbValue == value,
      orElse: () => AchievementRarity.common,
    );
  }
}
