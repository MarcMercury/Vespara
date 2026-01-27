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

/// Current user provider
final currentUserProvider =
    Provider<User?>((ref) => _supabase.auth.currentUser);

/// User profile provider - fetches real profile from Supabase
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  print('[userProfileProvider] Current user: ${user?.id ?? "null"}');

  if (user == null) {
    // Not logged in - return null
    print('[userProfileProvider] No user, returning null');
    return null;
  }

  try {
    print('[userProfileProvider] Fetching profile for user: ${user.id}');
    final response =
        await _supabase.from('profiles').select().eq('id', user.id).single();
    print('[userProfileProvider] Got response: ${response.keys.toList()}');
    print('[userProfileProvider] display_name: ${response['display_name']}');
    print(
        '[userProfileProvider] city: ${response['city']}, state: ${response['state']}',);
    return UserProfile.fromJson(response);
  } catch (e) {
    // Log error and return null
    print('[userProfileProvider] Error fetching profile: $e');
    return null;
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
    print('[nearbyMatchesProvider] Error: $e');
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
    print('[focusBatchProvider] Error: $e');
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
    print('[rosterMatchesProvider] Error: $e');
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
    print('[conversationsProvider] Error: $e');
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
    print('[gameCardsProvider] Error: $e');
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
    print('[vouchLinkProvider] Error: $e');
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
    print('[vouchesProvider] Error: $e');
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
    print('[userAnalyticsProvider] Error: $e');
    return null;
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
