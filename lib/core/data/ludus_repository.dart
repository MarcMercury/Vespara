import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/tags_game.dart';
import '../providers/share_or_dare_provider.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// LUDUS REPOSITORY
/// Handles all TAGS game engine operations
/// ════════════════════════════════════════════════════════════════════════════

/// Game model for database representation
class LudusGame {
  LudusGame({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.ratingLevel,
    this.minPlayers = 2,
    this.maxPlayers = 10,
    this.estimatedDuration = 30,
    required this.content,
    this.thumbnailUrl,
    this.isActive = true,
    this.playCount = 0,
    required this.createdAt,
  });

  factory LudusGame.fromJson(Map<String, dynamic> json) => LudusGame(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        category: json['category'] as String,
        ratingLevel: json['rating_level'] as String? ?? 'green',
        minPlayers: json['min_players'] as int? ?? 2,
        maxPlayers: json['max_players'] as int? ?? 10,
        estimatedDuration: json['estimated_duration'] as int? ?? 30,
        content: json['content'] as Map<String, dynamic>? ?? {},
        thumbnailUrl: json['thumbnail_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        playCount: json['play_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  final String id;
  final String title;
  final String? description;
  final String category;
  final String ratingLevel; // 'green', 'yellow', 'red'
  final int minPlayers;
  final int maxPlayers;
  final int estimatedDuration;
  final Map<String, dynamic> content;
  final String? thumbnailUrl;
  final bool isActive;
  final int playCount;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'rating_level': ratingLevel,
        'min_players': minPlayers,
        'max_players': maxPlayers,
        'estimated_duration': estimatedDuration,
        'content': content,
        'thumbnail_url': thumbnailUrl,
        'is_active': isActive,
        'play_count': playCount,
        'created_at': createdAt.toIso8601String(),
      };

  /// Convert rating level string to ConsentLevel enum
  ConsentLevel get consentLevel {
    switch (ratingLevel) {
      case 'red':
        return ConsentLevel.red;
      case 'yellow':
        return ConsentLevel.yellow;
      default:
        return ConsentLevel.green;
    }
  }
}

/// Game session model
class GameSession {
  GameSession({
    required this.id,
    required this.gameId,
    required this.hostId,
    required this.participants,
    required this.consentLevel,
    this.currentRound = 0,
    this.gameState = const {},
    this.isActive = true,
    required this.startedAt,
    this.endedAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
        id: json['id'] as String,
        gameId: json['game_id'] as String,
        hostId: json['host_id'] as String,
        participants: List<String>.from(json['participants'] ?? []),
        consentLevel: json['consent_level'] as String? ?? 'green',
        currentRound: json['current_round'] as int? ?? 0,
        gameState: json['game_state'] as Map<String, dynamic>? ?? {},
        isActive: json['is_active'] as bool? ?? true,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
      );
  final String id;
  final String gameId;
  final String hostId;
  final List<String> participants;
  final String consentLevel;
  final int currentRound;
  final Map<String, dynamic> gameState;
  final bool isActive;
  final DateTime startedAt;
  final DateTime? endedAt;
}

class LudusRepository {
  LudusRepository(this._supabase);
  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch games by consent rating level
  /// KEY RULE: If user selects "Yellow", return Green + Yellow, but EXCLUDE Red
  Future<List<LudusGame>> fetchGamesByRating(String consentLevel) async {
    try {
      // Use the database function for proper filtering
      final response = await _supabase.rpc(
        'get_games_by_consent',
        params: {
          'p_consent_level': consentLevel,
        },
      );

      return (response as List)
          .map((json) => LudusGame.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback to manual filtering
      final response =
          await _supabase.from('ludus_games').select().eq('is_active', true);

      final games =
          (response as List).map((json) => LudusGame.fromJson(json)).toList();

      // Apply consent filtering logic
      return games.where((game) {
        switch (consentLevel) {
          case 'red':
            return true; // Red includes all
          case 'yellow':
            return game.ratingLevel == 'green' || game.ratingLevel == 'yellow';
          default:
            return game.ratingLevel == 'green';
        }
      }).toList();
    }
  }

  /// Fetch all games
  Future<List<LudusGame>> fetchAllGames() async {
    final response = await _supabase
        .from('ludus_games')
        .select()
        .eq('is_active', true)
        .order('play_count', ascending: false);

    return (response as List).map((json) => LudusGame.fromJson(json)).toList();
  }

  /// Get a single game by ID
  Future<LudusGame?> getGame(String gameId) async {
    final response = await _supabase
        .from('ludus_games')
        .select()
        .eq('id', gameId)
        .maybeSingle();

    if (response == null) return null;
    return LudusGame.fromJson(response);
  }

  /// Get games by category
  Future<List<LudusGame>> fetchGamesByCategory(String category) async {
    final response = await _supabase
        .from('ludus_games')
        .select()
        .eq('category', category)
        .eq('is_active', true);

    return (response as List).map((json) => LudusGame.fromJson(json)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME CARDS (Pleasure Deck)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch game cards filtered by consent level
  Future<List<GameCard>> fetchGameCards(String consentLevel) async {
    List<String> allowedLevels;

    switch (consentLevel) {
      case 'red':
        allowedLevels = ['green', 'yellow', 'red'];
        break;
      case 'yellow':
        allowedLevels = ['green', 'yellow'];
        break;
      default:
        allowedLevels = ['green'];
    }

    final response = await _supabase
        .from('game_cards')
        .select()
        .inFilter('level', allowedLevels)
        .order('intensity');

    return (response as List).map((json) => GameCard.fromJson(json)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME SESSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start a new game session
  Future<GameSession> startSession({
    required String gameId,
    required List<String> participants,
    required String consentLevel,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('game_sessions')
        .insert({
          'game_id': gameId,
          'host_id': _userId,
          'participants': participants,
          'consent_level': consentLevel,
          'is_active': true,
        })
        .select()
        .single();

    // Increment play count
    await _supabase.rpc('increment_play_count',
        params: {'game_id': gameId}).catchError((_) {
      // Fallback if function doesn't exist
      return null;
    });

    return GameSession.fromJson(response);
  }

  /// Get active session for current user
  Future<GameSession?> getActiveSession() async {
    if (_userId == null) return null;

    final response = await _supabase
        .from('game_sessions')
        .select()
        .eq('host_id', _userId!)
        .eq('is_active', true)
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return GameSession.fromJson(response);
  }

  /// Update game session state
  Future<void> updateSessionState(
      String sessionId, Map<String, dynamic> state) async {
    await _supabase.from('game_sessions').update({
      'game_state': state,
      'current_round': state['round'] ?? 0,
    }).eq('id', sessionId);
  }

  /// End a game session
  Future<void> endSession(String sessionId) async {
    await _supabase.from('game_sessions').update({
      'is_active': false,
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);
  }

  /// Stream active game session (for real-time multiplayer)
  Stream<GameSession?> watchSession(String sessionId) => _supabase
      .from('game_sessions')
      .stream(primaryKey: ['id'])
      .eq('id', sessionId)
      .map((data) => data.isNotEmpty ? GameSession.fromJson(data.first) : null);

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARE OR DARE (Share or Dare)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch Share or Dare cards filtered by heat level
  Future<List<ShareOrDareCard>> getShareOrDareCards(String maxHeat) async {
    try {
      final response = await _supabase.rpc(
        'get_share_or_dare_deck',
        params: {
          'p_max_heat': maxHeat,
          'p_limit': 50,
        },
      );

      return (response as List)
          .map((json) => ShareOrDareCard.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback to direct query
      try {
        List<String> allowedLevels;
        switch (maxHeat) {
          case 'X':
            allowedLevels = ['PG', 'PG-13', 'R', 'X'];
            break;
          case 'R':
            allowedLevels = ['PG', 'PG-13', 'R'];
            break;
          case 'PG-13':
            allowedLevels = ['PG', 'PG-13'];
            break;
          default:
            allowedLevels = ['PG'];
        }

        final response = await _supabase
            .from('share_or_dare_cards')
            .select()
            .inFilter('heat_level', allowedLevels)
            .limit(50);

        final cards = (response as List)
            .map((json) => ShareOrDareCard.fromJson(json))
            .toList();
        cards.shuffle();
        return cards;
      } catch (e) {
        return [];
      }
    }
  }
}

/// Provider for LudusRepository
final ludusRepositoryProvider = Provider<LudusRepository>(
    (ref) => LudusRepository(Supabase.instance.client));

/// Current consent level state
final consentLevelProvider = StateProvider<String>((ref) => 'green');

/// Games filtered by current consent level
final filteredGamesProvider = FutureProvider<List<LudusGame>>((ref) async {
  final consentLevel = ref.watch(consentLevelProvider);
  return ref.watch(ludusRepositoryProvider).fetchGamesByRating(consentLevel);
});

/// Game cards filtered by current consent level
final filteredGameCardsProvider = FutureProvider<List<GameCard>>((ref) async {
  final consentLevel = ref.watch(consentLevelProvider);
  return ref.watch(ludusRepositoryProvider).fetchGameCards(consentLevel);
});

/// Active game session
final activeGameSessionProvider = FutureProvider<GameSession?>(
    (ref) async => ref.watch(ludusRepositoryProvider).getActiveSession());
