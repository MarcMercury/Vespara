import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/user_profile.dart';
import '../domain/models/roster_match.dart';
import '../domain/models/conversation.dart';
import '../domain/models/analytics.dart';
import '../domain/models/tags_game.dart';
import '../data/mock_data_provider.dart';

/// Global Supabase client accessor for providers
SupabaseClient get _supabase => Supabase.instance.client;

/// Demo mode flag - set to true to use mock data
final demoModeProvider = StateProvider<bool>((ref) => true);

// ═══════════════════════════════════════════════════════════════════════════
// AUTH PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Stream of authentication state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return _supabase.auth.onAuthStateChange;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return _supabase.auth.currentUser;
});

/// User profile provider
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    return MockDataProvider.currentUserProfile;
  }
  
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  try {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return UserProfile.fromJson(response);
  } catch (e) {
    return MockDataProvider.currentUserProfile;
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// STRATEGIST PROVIDERS (Tile 1)
// ═══════════════════════════════════════════════════════════════════════════

/// Tonight Mode toggle state
final tonightModeProvider = StateProvider<bool>((ref) => false);

/// Optimization score provider
final optimizationScoreProvider = FutureProvider<double>((ref) async {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    return MockDataProvider.userAnalytics.optimizationScore;
  }
  final analytics = await ref.watch(userAnalyticsProvider.future);
  return analytics?.optimizationScore ?? 0.0;
});

/// Nearby matches provider (uses geolocation when Tonight Mode is ON)
final nearbyMatchesProvider = FutureProvider<List<RosterMatch>>((ref) async {
  final isTonightMode = ref.watch(tonightModeProvider);
  if (!isTonightMode) return [];
  
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    return MockDataProvider.nearbyMatches;
  }
  
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
    return MockDataProvider.nearbyMatches;
  }
});

/// Strategic advice for the Strategist
final strategicAdviceProvider = FutureProvider<String>((ref) async {
  return MockDataProvider.randomAdvice;
});

// ═══════════════════════════════════════════════════════════════════════════
// SCOPE PROVIDERS (Tile 2)
// ═══════════════════════════════════════════════════════════════════════════

/// Focus batch provider - curated 5 matches using pgvector
final focusBatchProvider = FutureProvider<List<RosterMatch>>((ref) async {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    return MockDataProvider.focusBatch;
  }
  
  final user = ref.watch(currentUserProvider);
  if (user == null) return MockDataProvider.focusBatch;
  
  try {
    final response = await _supabase
        .rpc('get_focus_batch', params: {
          'user_id': user.id,
          'batch_size': 5,
        });
    return (response as List)
        .map((json) => RosterMatch.fromJson(json))
        .toList();
  } catch (e) {
    return MockDataProvider.focusBatch;
  }
});

/// Current profile index in the focus batch
final currentFocusIndexProvider = StateProvider<int>((ref) => 0);

// ═══════════════════════════════════════════════════════════════════════════
// ROSTER PROVIDERS (Tile 3)
// ═══════════════════════════════════════════════════════════════════════════

/// All roster matches provider
final rosterMatchesProvider = FutureProvider<List<RosterMatch>>((ref) async {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    return MockDataProvider.rosterMatches;
  }
  
  final user = ref.watch(currentUserProvider);
  if (user == null) return MockDataProvider.rosterMatches;
  
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
    return MockDataProvider.rosterMatches;
  }
});

/// Matches grouped by pipeline stage
final pipelineMatchesProvider = Provider<Map<PipelineStage, List<RosterMatch>>>((ref) {
  final matches = ref.watch(rosterMatchesProvider).valueOrNull ?? MockDataProvider.rosterMatches;
  
  return {
    PipelineStage.incoming: matches.where((m) => m.stage == PipelineStage.incoming).toList(),
    PipelineStage.bench: matches.where((m) => m.stage == PipelineStage.bench).toList(),
    PipelineStage.activeRotation: matches.where((m) => m.stage == PipelineStage.activeRotation).toList(),
    PipelineStage.legacy: matches.where((m) => m.stage == PipelineStage.legacy).toList(),
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// WIRE PROVIDERS (Tile 4)
// ═══════════════════════════════════════════════════════════════════════════

/// Conversations sorted by momentum score
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    return MockDataProvider.conversations;
  }
  
  final user = ref.watch(currentUserProvider);
  if (user == null) return MockDataProvider.conversations;
  
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
    return MockDataProvider.conversations;
  }
});

/// Stale conversations that need resuscitation
final staleConversationsProvider = Provider<List<Conversation>>((ref) {
  final conversations = ref.watch(conversationsProvider).valueOrNull ?? MockDataProvider.staleConversations;
  return conversations.where((c) => c.isStale).toList();
});

// ═══════════════════════════════════════════════════════════════════════════
// SHREDDER PROVIDERS (Tile 5)
// ═══════════════════════════════════════════════════════════════════════════

/// Stale matches count for The Shredder
final staleMatchesCountProvider = Provider<int>((ref) {
  final matches = ref.watch(rosterMatchesProvider).valueOrNull ?? MockDataProvider.rosterMatches;
  return matches.where((m) => m.isStale).length;
});

/// Stale matches for Ghost Protocol
final staleMatchesProvider = Provider<List<RosterMatch>>((ref) {
  final matches = ref.watch(rosterMatchesProvider).valueOrNull ?? MockDataProvider.rosterMatches;
  return matches.where((m) => m.isStale).toList();
});

// ═══════════════════════════════════════════════════════════════════════════
// LUDUS/TAGS PROVIDERS (Tile 6)
// ═══════════════════════════════════════════════════════════════════════════

/// Current consent level for TAGS (string version)
final consentLevelProvider = StateProvider<String>((ref) => 'green');

/// Current consent level for TAGS (enum version)
final tagsConsentLevelProvider = StateProvider<ConsentLevel>((ref) {
  return ConsentLevel.green;
});

/// Available games based on consent level
final availableGamesProvider = Provider<List<GameCategory>>((ref) {
  final consentLevel = ref.watch(tagsConsentLevelProvider);
  return MockDataProvider.getGamesForConsentLevel(consentLevel);
});

/// Filtered games based on consent level (for repository)
final filteredGamesProvider = FutureProvider<List<GameCategory>>((ref) async {
  final consentLevel = ref.watch(tagsConsentLevelProvider);
  return MockDataProvider.getGamesForConsentLevel(consentLevel);
});

/// Active game session
final activeGameProvider = StateProvider<TagsGame?>((ref) => null);

/// Game cards for current session (Truth or Dare / Pleasure Deck)
final gameCardsProvider = FutureProvider<List<GameCard>>((ref) async {
  final consentLevel = ref.watch(tagsConsentLevelProvider);
  return MockDataProvider.getCardsForLevel(consentLevel);
});

// ═══════════════════════════════════════════════════════════════════════════
// CORE PROVIDERS (Tile 7)
// ═══════════════════════════════════════════════════════════════════════════

/// User's trust score and verifications
final trustScoreProvider = Provider<double>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?.trustScore ?? MockDataProvider.currentUserProfile.trustScore;
});

/// Vouch chain link generator
final vouchLinkProvider = FutureProvider<String>((ref) async {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    return MockDataProvider.vouchLink;
  }
  
  final user = ref.watch(currentUserProvider);
  if (user == null) return MockDataProvider.vouchLink;
  
  try {
    final response = await _supabase
        .rpc('generate_vouch_link', params: {'user_id': user.id});
    return response as String? ?? MockDataProvider.vouchLink;
  } catch (e) {
    return MockDataProvider.vouchLink;
  }
});

/// Vouches list
final vouchesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return MockDataProvider.vouches;
});

// ═══════════════════════════════════════════════════════════════════════════
// MIRROR PROVIDERS (Tile 8)
// ═══════════════════════════════════════════════════════════════════════════

/// User analytics provider
final userAnalyticsProvider = FutureProvider<UserAnalytics?>((ref) async {
  final isDemoMode = ref.watch(demoModeProvider);
  if (isDemoMode) {
    return MockDataProvider.userAnalytics;
  }
  
  final user = ref.watch(currentUserProvider);
  if (user == null) return MockDataProvider.userAnalytics;
  
  try {
    final response = await _supabase
        .from('user_analytics')
        .select()
        .eq('user_id', user.id)
        .single();
    return UserAnalytics.fromJson(response);
  } catch (e) {
    return MockDataProvider.userAnalytics;
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// UI STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Current selected tile index
final selectedTileProvider = StateProvider<int?>((ref) => null);

/// Loading state for tiles
final tileLoadingProvider = StateProvider<Map<int, bool>>((ref) {
  return {};
});

extension IterableExtension<T> on Iterable<T> {
  int get count => length;
}
