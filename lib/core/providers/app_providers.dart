import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/analytics.dart';
import '../domain/models/conversation.dart';
import '../domain/models/roster_match.dart';
import '../domain/models/tags_game.dart';
import '../domain/models/user_profile.dart';

/// Global Supabase client accessor for providers
SupabaseClient get _supabase => Supabase.instance.client;

// ═══════════════════════════════════════════════════════════════════════════
// AUTH PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Stream of authentication state changes
final authStateProvider =
    StreamProvider<AuthState>((ref) => _supabase.auth.onAuthStateChange);

/// Current user provider - MUST watch authStateProvider to react to changes
final currentUserProvider = Provider<User?>((ref) {
  // Watch the auth state stream so this provider rebuilds on auth changes
  ref.watch(authStateProvider);
  return _supabase.auth.currentUser;
});

/// User profile provider - fetches real profile from Supabase
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  debugPrint('[userProfileProvider] Current user: ${user?.id ?? "null"}');

  if (user == null) {
    // Not logged in - return null
    debugPrint('[userProfileProvider] No user, returning null');
    return null;
  }

  try {
    debugPrint('[userProfileProvider] Fetching profile for user: ${user.id}');
    final response =
        await _supabase.from('profiles').select().eq('id', user.id).single();
    debugPrint('[userProfileProvider] Got response: ${response.keys.toList()}');
    debugPrint('[userProfileProvider] display_name: ${response['display_name']}');
    debugPrint(
        '[userProfileProvider] city: ${response['city']}, state: ${response['state']}',);
    return UserProfile.fromJson(response);
  } catch (e) {
    // Log error and return null
    debugPrint('[userProfileProvider] Error fetching profile: $e');
    return null;
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// COMMUNITY MEMBERS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Simple member data for lists (invite sheets, member pickers, etc.)
class CommunityMember {
  const CommunityMember({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.age,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    final photos = json['photos'] as List?;
    final avatarUrl = (photos != null && photos.isNotEmpty)
        ? photos.first as String?
        : json['avatar_url'] as String?;
    return CommunityMember(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: avatarUrl,
      age: json['age'] as int?,
    );
  }

  final String id;
  final String? displayName;
  final String? avatarUrl;
  final int? age;
}

/// Provider that fetches all approved community members (excluding current user)
final allMembersProvider = FutureProvider<List<CommunityMember>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await _supabase
        .from('profiles')
        .select('id, display_name, avatar_url, photos, age')
        .eq('membership_status', 'approved')
        .neq('id', user.id)
        .order('display_name');

    return (response as List)
        .map((json) => CommunityMember.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('Error loading community members: $e');
    return [];
  }
});

/// Sanctum connection — a mutual match with profile info
class SanctumConnection {
  const SanctumConnection({
    required this.matchId,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.age,
    required this.matchedAt,
    this.compatibilityScore = 0.5,
    this.isSuperMatch = false,
    this.conversationId,
  });

  final String matchId;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final int? age;
  final DateTime matchedAt;
  final double compatibilityScore;
  final bool isSuperMatch;
  final String? conversationId;
}

/// Pending like — someone you liked but hasn't liked you back yet
class PendingLike {
  const PendingLike({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.age,
    required this.likedAt,
  });

  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final int? age;
  final DateTime likedAt;
}

/// Provider: Sanctum connections (mutual matches with profile details)
final sanctumConnectionsProvider =
    FutureProvider<List<SanctumConnection>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await _supabase
        .from('matches')
        .select('''
          id, matched_at, compatibility_score, is_super_match, conversation_id,
          user_a_id, user_b_id,
          user_a:profiles!matches_user_a_id_fkey(id, display_name, avatar_url, photos, age),
          user_b:profiles!matches_user_b_id_fkey(id, display_name, avatar_url, photos, age)
        ''')
        .or('user_a_id.eq.${user.id},user_b_id.eq.${user.id}')
        .order('matched_at', ascending: false);

    return (response as List).map((row) {
      final isUserA = row['user_a_id'] == user.id;
      final other =
          (isUserA ? row['user_b'] : row['user_a']) as Map<String, dynamic>;
      final photos = other['photos'] as List?;
      final avatarUrl = (photos != null && photos.isNotEmpty)
          ? photos.first as String?
          : other['avatar_url'] as String?;
      return SanctumConnection(
        matchId: row['id'] as String,
        userId: other['id'] as String,
        displayName: other['display_name'] as String?,
        avatarUrl: avatarUrl,
        age: other['age'] as int?,
        matchedAt: DateTime.parse(row['matched_at'] as String),
        compatibilityScore:
            (row['compatibility_score'] as num?)?.toDouble() ?? 0.5,
        isSuperMatch: row['is_super_match'] as bool? ?? false,
        conversationId: row['conversation_id'] as String?,
      );
    }).toList();
  } catch (e) {
    debugPrint('Error loading sanctum connections: $e');
    return [];
  }
});

/// Provider: Pending outbound likes (you liked them, no match yet)
final pendingLikesProvider =
    FutureProvider<List<PendingLike>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    // Get all profiles I swiped right/super on
    final swipesResponse = await _supabase
        .from('swipes')
        .select('swiped_id, created_at')
        .eq('swiper_id', user.id)
        .inFilter('direction', ['right', 'super'])
        .order('created_at', ascending: false);

    if ((swipesResponse as List).isEmpty) return [];

    final swipedIds =
        swipesResponse.map((s) => s['swiped_id'] as String).toList();
    final swipeTimestamps = {
      for (final s in swipesResponse)
        s['swiped_id'] as String: s['created_at'] as String,
    };

    // Get all my matches to exclude mutual ones
    final matchesResponse = await _supabase
        .from('matches')
        .select('user_a_id, user_b_id')
        .or('user_a_id.eq.${user.id},user_b_id.eq.${user.id}');

    final matchedIds = <String>{};
    for (final m in matchesResponse as List) {
      final otherId =
          m['user_a_id'] == user.id ? m['user_b_id'] : m['user_a_id'];
      matchedIds.add(otherId as String);
    }

    // Filter to only non-matched liked profiles
    final pendingIds =
        swipedIds.where((id) => !matchedIds.contains(id)).toList();
    if (pendingIds.isEmpty) return [];

    // Fetch profiles for pending likes
    final profilesResponse = await _supabase
        .from('profiles')
        .select('id, display_name, avatar_url, photos, age')
        .inFilter('id', pendingIds);

    final profileMap = <String, Map<String, dynamic>>{};
    for (final p in profilesResponse as List) {
      profileMap[p['id'] as String] = p as Map<String, dynamic>;
    }

    return pendingIds
        .where((id) => profileMap.containsKey(id))
        .map((id) {
      final p = profileMap[id]!;
      final photos = p['photos'] as List?;
      final avatarUrl = (photos != null && photos.isNotEmpty)
          ? photos.first as String?
          : p['avatar_url'] as String?;
      return PendingLike(
        userId: id,
        displayName: p['display_name'] as String?,
        avatarUrl: avatarUrl,
        age: p['age'] as int?,
        likedAt: DateTime.parse(swipeTimestamps[id]!),
      );
    }).toList();
  } catch (e) {
    debugPrint('Error loading pending likes: $e');
    return [];
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// STRATEGIST PROVIDERS (Tile 1)
// ═══════════════════════════════════════════════════════════════════════════

/// Tonight Mode toggle state
final tonightModeProvider = StateProvider<bool>((ref) => false);

/// Optimization score provider
final optimizationScoreProvider = FutureProvider<double>((ref) async {
  final analytics = await ref.watch(userAnalyticsProvider.future);
  return analytics?.optimizationScore ?? 0.0;
});

/// Nearby matches provider (uses geolocation when Tonight Mode is ON)
final nearbyMatchesProvider = FutureProvider<List<RosterMatch>>((ref) async {
  final isTonightMode = ref.watch(tonightModeProvider);
  if (!isTonightMode) return [];

  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await _supabase
        .from('roster_matches')
        .select()
        .eq('is_nearby', true)
        .limit(10);
    return (response as List)
        .map((json) => RosterMatch.fromJson(json))
        .toList();
  } catch (e) {
    debugPrint('[nearbyMatchesProvider] Error: $e');
    return [];
  }
});

/// Strategic advice for the Strategist - fetched from database or AI
final strategicAdviceProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    // Try to get AI-generated advice from the database
    final response = await _supabase
        .from('ai_advice')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response?['advice'] as String?;
  } catch (e) {
    return null;
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// SCOPE PROVIDERS (Tile 2)
// ═══════════════════════════════════════════════════════════════════════════

/// Focus batch provider - curated 5 matches using pgvector
final focusBatchProvider = FutureProvider<List<RosterMatch>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await _supabase.rpc(
      'get_focus_batch',
      params: {
        'user_id': user.id,
        'batch_size': 5,
      },
    );
    return (response as List)
        .map((json) => RosterMatch.fromJson(json))
        .toList();
  } catch (e) {
    debugPrint('[focusBatchProvider] Error: $e');
    return [];
  }
});

/// Current profile index in the focus batch
final currentFocusIndexProvider = StateProvider<int>((ref) => 0);

// ═══════════════════════════════════════════════════════════════════════════
// ROSTER PROVIDERS (Tile 3)
// ═══════════════════════════════════════════════════════════════════════════

/// All roster matches provider
final rosterMatchesProvider = FutureProvider<List<RosterMatch>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await _supabase
        .from('roster_matches')
        .select()
        .eq('user_id', user.id)
        .order('momentum_score', ascending: false);
    return (response as List)
        .map((json) => RosterMatch.fromJson(json))
        .toList();
  } catch (e) {
    debugPrint('[rosterMatchesProvider] Error: $e');
    return [];
  }
});

/// Matches grouped by pipeline stage
final pipelineMatchesProvider =
    Provider<Map<PipelineStage, List<RosterMatch>>>((ref) {
  final matches = ref.watch(rosterMatchesProvider).valueOrNull ?? [];

  return {
    PipelineStage.incoming:
        matches.where((m) => m.stage == PipelineStage.incoming).toList(),
    PipelineStage.bench:
        matches.where((m) => m.stage == PipelineStage.bench).toList(),
    PipelineStage.activeRotation:
        matches.where((m) => m.stage == PipelineStage.activeRotation).toList(),
    PipelineStage.legacy:
        matches.where((m) => m.stage == PipelineStage.legacy).toList(),
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// WIRE PROVIDERS (Tile 4)
// ═══════════════════════════════════════════════════════════════════════════

/// Conversations sorted by momentum score
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response = await _supabase
        .from('conversations')
        .select()
        .eq('user_id', user.id)
        .order('momentum_score', ascending: false);
    return (response as List)
        .map((json) => Conversation.fromJson(json))
        .toList();
  } catch (e) {
    debugPrint('[conversationsProvider] Error: $e');
    return [];
  }
});

/// Stale conversations that need resuscitation
final staleConversationsProvider = Provider<List<Conversation>>((ref) {
  final conversations = ref.watch(conversationsProvider).valueOrNull ?? [];
  return conversations.where((c) => c.isStale).toList();
});

// ═══════════════════════════════════════════════════════════════════════════
// SHREDDER PROVIDERS (Tile 5)
// ═══════════════════════════════════════════════════════════════════════════

/// Stale matches count for The Shredder
final staleMatchesCountProvider = Provider<int>((ref) {
  final matches = ref.watch(rosterMatchesProvider).valueOrNull ?? [];
  return matches.where((m) => m.isStale).length;
});

/// Stale matches for Ghost Protocol
final staleMatchesProvider = Provider<List<RosterMatch>>((ref) {
  final matches = ref.watch(rosterMatchesProvider).valueOrNull ?? [];
  return matches.where((m) => m.isStale).toList();
});

// ═══════════════════════════════════════════════════════════════════════════
// LUDUS/TAGS PROVIDERS (Tile 6)
// ═══════════════════════════════════════════════════════════════════════════

/// Current consent level for TAGS (string version)
final consentLevelProvider = StateProvider<String>((ref) => 'green');

/// Current consent level for TAGS (enum version)
final tagsConsentLevelProvider =
    StateProvider<ConsentLevel>((ref) => ConsentLevel.green);

/// Available games based on consent level - now returns all games that meet the consent level
final availableGamesProvider = Provider<List<GameCategory>>((ref) {
  final consentLevel = ref.watch(tagsConsentLevelProvider);
  return GameCategory.values
      .where((game) => game.minimumConsentLevel.value <= consentLevel.value)
      .toList();
});

/// Filtered games based on consent level (for repository)
final filteredGamesProvider = FutureProvider<List<GameCategory>>((ref) async {
  final consentLevel = ref.watch(tagsConsentLevelProvider);
  return GameCategory.values
      .where((game) => game.minimumConsentLevel.value <= consentLevel.value)
      .toList();
});

/// Active game session
final activeGameProvider = StateProvider<TagsGame?>((ref) => null);

/// Game cards for current session - fetched from database
final gameCardsProvider = FutureProvider<List<GameCard>>((ref) async {
  final consentLevel = ref.watch(tagsConsentLevelProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return [];

  try {
    final response = await _supabase
        .from('game_cards')
        .select()
        .lte('consent_level', consentLevel.value);
    return (response as List).map((json) => GameCard.fromJson(json)).toList();
  } catch (e) {
    debugPrint('[gameCardsProvider] Error: $e');
    return [];
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// CORE PROVIDERS (Tile 7)
// ═══════════════════════════════════════════════════════════════════════════

/// User's trust score and verifications
final trustScoreProvider = Provider<double>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?.trustScore ?? 0.0;
});

/// Vouch chain link generator
final vouchLinkProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final response = await _supabase
        .rpc('generate_vouch_link', params: {'user_id': user.id});
    return response as String?;
  } catch (e) {
    debugPrint('[vouchLinkProvider] Error: $e');
    return null;
  }
});

/// Vouches list - fetched from database
final vouchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  try {
    final response =
        await _supabase.from('vouches').select().eq('vouched_for_id', user.id);
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('[vouchesProvider] Error: $e');
    return [];
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// MIRROR PROVIDERS (Tile 8)
// ═══════════════════════════════════════════════════════════════════════════

/// User analytics provider
final userAnalyticsProvider = FutureProvider<UserAnalytics?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final response = await _supabase
        .from('user_analytics')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      // No analytics row exists yet - return null
      return null;
    }
    return UserAnalytics.fromJson(response);
  } catch (e) {
    debugPrint('[userAnalyticsProvider] Error: $e');
    return null;
  }
});

/// Live dashboard stats computed from actual data tables
class DashboardStats {
  const DashboardStats({
    this.members = 0,
    this.chats = 0,
    this.events = 0,
    this.activePercent = 0,
  });
  final int members;
  final int chats;
  final int events;
  final int activePercent;
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const DashboardStats();

  try {
    // Run all count queries in parallel
    final results = await Future.wait([
      // Members: count of approved members (excluding self)
      _supabase
          .from('profiles')
          .select('id')
          .eq('membership_status', 'approved')
          .neq('id', user.id)
          .count(CountOption.exact),
      // Chats: active conversations the user participates in
      _supabase
          .from('conversation_participants')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .count(CountOption.exact),
      // Events: events user is hosting or attending
      _supabase
          .from('vespara_event_rsvps')
          .select('id')
          .eq('user_id', user.id)
          .inFilter('status', ['going', 'maybe'])
          .count(CountOption.exact),
      // Matches: mutual matches for activity calculation
      _supabase
          .from('matches')
          .select('id')
          .or('user_a_id.eq.${user.id},user_b_id.eq.${user.id}')
          .count(CountOption.exact),
    ]);

    final membersCount = results[0].count;
    final chatsCount = results[1].count;
    final eventsCount = results[2].count;
    final matchesCount = results[3].count;

    // Activity: simple ratio of connections to members
    final activePercent = membersCount > 0
        ? ((matchesCount / membersCount) * 100).round().clamp(0, 100)
        : 0;

    return DashboardStats(
      members: membersCount,
      chats: chatsCount,
      events: eventsCount,
      activePercent: activePercent,
    );
  } catch (e) {
    debugPrint('[dashboardStatsProvider] Error: $e');
    return const DashboardStats();
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// UI STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Current selected tile index
final selectedTileProvider = StateProvider<int?>((ref) => null);

/// Loading state for tiles
final tileLoadingProvider = StateProvider<Map<int, bool>>((ref) => {});

extension IterableExtension<T> on Iterable<T> {
  int get count => length;
}
