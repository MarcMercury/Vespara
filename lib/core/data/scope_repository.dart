import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SCOPE REPOSITORY
/// Handles "The Scope" discovery feed with AI-powered matching
/// 
/// PHASE 6: Scalability Architecture
/// - Uses pre-calculated daily_matches table instead of realtime vector search
/// - Feed is generated async by background jobs, not on-demand
/// - Reduces database CPU load from O(N) per request to O(1) read
/// ════════════════════════════════════════════════════════════════════════════

/// Match recommendation from the Scope feed
class ScopeMatch {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final double similarityScore;
  final List<String> matchReasons;
  final bool isViewed;
  final bool? isLiked;
  final DateTime calculatedAt;

  ScopeMatch({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.similarityScore,
    required this.matchReasons,
    required this.isViewed,
    this.isLiked,
    required this.calculatedAt,
  });

  factory ScopeMatch.fromJson(Map<String, dynamic> json) {
    final matchUser = json['match_user'] as Map<String, dynamic>?;
    final reasons = json['match_reasons'] as List<dynamic>?;
    
    return ScopeMatch(
      id: json['id'] as String,
      userId: json['match_user_id'] as String,
      displayName: matchUser?['display_name'] as String? ?? 'Unknown',
      avatarUrl: matchUser?['avatar_url'] as String?,
      bio: matchUser?['bio'] as String?,
      similarityScore: (json['similarity_score'] as num).toDouble(),
      matchReasons: reasons?.map((e) => e.toString()).toList() ?? [],
      isViewed: json['is_viewed'] as bool? ?? false,
      isLiked: json['is_liked'] as bool?,
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
    );
  }
}

class ScopeRepository {
  final SupabaseClient _supabase;

  ScopeRepository(this._supabase);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-CALCULATED FEED (PHASE 6 - Scalable)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get today's pre-calculated matches
  /// This reads from the daily_matches table populated by background jobs
  /// Much faster than realtime vector search at scale
  Future<List<ScopeMatch>> getTodayMatches({int limit = 20}) async {
    if (_userId == null) return [];

    final response = await _supabase
        .from('daily_matches')
        .select('''
          id,
          match_user_id,
          similarity_score,
          match_reasons,
          is_viewed,
          is_liked,
          calculated_at,
          match_user:profiles!match_user_id (
            display_name,
            avatar_url,
            bio
          )
        ''')
        .eq('user_id', _userId!)
        .eq('calculated_at', DateTime.now().toIso8601String().split('T')[0])
        .order('similarity_score', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ScopeMatch.fromJson(json))
        .toList();
  }

  /// Get unviewed matches (for badge count)
  Future<int> getUnviewedMatchCount() async {
    if (_userId == null) return 0;

    final response = await _supabase
        .from('daily_matches')
        .select('id')
        .eq('user_id', _userId!)
        .eq('calculated_at', DateTime.now().toIso8601String().split('T')[0])
        .eq('is_viewed', false);

    return (response as List).length;
  }

  /// Mark a match as viewed
  Future<void> markAsViewed(String matchId) async {
    await _supabase
        .from('daily_matches')
        .update({'is_viewed': true})
        .eq('id', matchId);
  }

  /// Like/pass on a match
  Future<void> setMatchDecision(String matchId, bool isLiked) async {
    await _supabase
        .from('daily_matches')
        .update({'is_liked': isLiked})
        .eq('id', matchId);
    
    // If liked, optionally create a roster entry
    if (isLiked) {
      await _createRosterEntryFromMatch(matchId);
    }
  }

  Future<void> _createRosterEntryFromMatch(String matchId) async {
    if (_userId == null) return;
    
    // Get the match details
    final match = await _supabase
        .from('daily_matches')
        .select('match_user_id, match_user:profiles!match_user_id(display_name, avatar_url)')
        .eq('id', matchId)
        .single();
    
    final matchUser = match['match_user'] as Map<String, dynamic>;
    
    // Create roster entry
    await _supabase.from('roster_matches').insert({
      'user_id': _userId,
      'name': matchUser['display_name'],
      'avatar_url': matchUser['avatar_url'],
      'source': 'other',
      'pipeline': 'incoming',
      'momentum_score': 0.8, // High initial score from Scope match
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MANUAL REFRESH (Triggers background job)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Request a feed refresh (queues a background job)
  /// Useful when user pulls-to-refresh
  Future<void> requestFeedRefresh() async {
    if (_userId == null) return;
    
    await _supabase.rpc('enqueue_background_job', params: {
      'p_job_type': 'generate_matches',
      'p_target_user_id': _userId,
      'p_priority': 1, // High priority for user-initiated refresh
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FALLBACK: REALTIME VECTOR SEARCH (For small user bases)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Direct vector similarity search (use only for <50k users)
  /// This is expensive at scale - prefer getTodayMatches()
  Future<List<ScopeMatch>> searchSimilarProfiles({
    int limit = 20,
    double minSimilarity = 0.7,
  }) async {
    if (_userId == null) return [];

    try {
      final response = await _supabase.rpc('search_similar_profiles', params: {
        'p_user_id': _userId,
        'p_limit': limit,
        'p_min_similarity': minSimilarity,
      });

      return (response as List).map((json) => ScopeMatch(
        id: json['id'] ?? '',
        userId: json['id'] ?? '',
        displayName: json['display_name'] ?? 'Unknown',
        avatarUrl: json['avatar_url'],
        bio: json['bio'],
        similarityScore: (json['similarity'] as num?)?.toDouble() ?? 0.0,
        matchReasons: ['AI Match'],
        isViewed: false,
        calculatedAt: DateTime.now(),
      )).toList();
    } catch (e) {
      // Function doesn't exist yet, return empty
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMBEDDING MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if user's embedding needs update
  Future<bool> needsEmbeddingUpdate() async {
    if (_userId == null) return false;

    final response = await _supabase
        .from('profiles')
        .select('embedding_updated_at, updated_at')
        .eq('id', _userId!)
        .single();

    final embeddingUpdated = response['embedding_updated_at'] != null
        ? DateTime.parse(response['embedding_updated_at'])
        : null;
    final profileUpdated = DateTime.parse(response['updated_at']);

    // Needs update if never embedded or profile changed after last embedding
    return embeddingUpdated == null || embeddingUpdated.isBefore(profileUpdated);
  }

  /// Request embedding update (queues background job)
  Future<void> requestEmbeddingUpdate() async {
    if (_userId == null) return;

    await _supabase.rpc('enqueue_background_job', params: {
      'p_job_type': 'update_embeddings',
      'p_target_user_id': _userId,
      'p_priority': 3,
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Scope Repository Provider
final scopeRepositoryProvider = Provider<ScopeRepository>((ref) {
  return ScopeRepository(Supabase.instance.client);
});

/// Today's matches provider (from pre-calculated feed)
final todayMatchesProvider = FutureProvider<List<ScopeMatch>>((ref) async {
  return ref.watch(scopeRepositoryProvider).getTodayMatches();
});

/// Unviewed match count provider (for badge)
final unviewedMatchCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(scopeRepositoryProvider).getUnviewedMatchCount();
});

/// Auto-refreshing matches provider
final scopeMatchesProvider = FutureProvider.autoDispose<List<ScopeMatch>>((ref) async {
  // Check if we need to refresh
  final repo = ref.watch(scopeRepositoryProvider);
  
  // Get today's pre-calculated matches
  final matches = await repo.getTodayMatches();
  
  // If no matches today, request a refresh
  if (matches.isEmpty) {
    await repo.requestFeedRefresh();
  }
  
  return matches;
});
