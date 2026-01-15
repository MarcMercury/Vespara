import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/roster_match.dart';
import '../domain/models/conversation.dart';
import '../domain/models/analytics.dart';
import '../domain/models/tags_game.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AUTH PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Stream of authentication state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return supabase.auth.currentUser;
});

/// User profile provider
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final response = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();
  
  return UserProfile.fromJson(response);
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
  
  // In production, this would use actual geolocation
  final response = await supabase
      .from('roster_matches')
      .select()
      .eq('is_nearby', true)
      .limit(10);
  
  return (response as List)
      .map((json) => RosterMatch.fromJson(json))
      .toList();
});

// ═══════════════════════════════════════════════════════════════════════════
// SCOPE PROVIDERS (Tile 2)
// ═══════════════════════════════════════════════════════════════════════════

/// Focus batch provider - curated 5 matches using pgvector
final focusBatchProvider = FutureProvider<List<RosterMatch>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  // Uses pgvector for semantic matching
  final response = await supabase
      .rpc('get_focus_batch', params: {
        'user_id': user.id,
        'batch_size': 5,
      });
  
  return (response as List)
      .map((json) => RosterMatch.fromJson(json))
      .toList();
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
  
  final response = await supabase
      .from('roster_matches')
      .select()
      .eq('user_id', user.id)
      .order('momentum_score', ascending: false);
  
  return (response as List)
      .map((json) => RosterMatch.fromJson(json))
      .toList();
});

/// Matches grouped by pipeline stage
final pipelineMatchesProvider = Provider<Map<PipelineStage, List<RosterMatch>>>((ref) {
  final matches = ref.watch(rosterMatchesProvider).valueOrNull ?? [];
  
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
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final response = await supabase
      .from('conversations')
      .select()
      .eq('user_id', user.id)
      .order('momentum_score', ascending: false);
  
  return (response as List)
      .map((json) => Conversation.fromJson(json))
      .toList();
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
  return matches.where((m) => m.isStale).count;
});

/// Stale matches for Ghost Protocol
final staleMatchesProvider = Provider<List<RosterMatch>>((ref) {
  final matches = ref.watch(rosterMatchesProvider).valueOrNull ?? [];
  return matches.where((m) => m.isStale).toList();
});

// ═══════════════════════════════════════════════════════════════════════════
// LUDUS/TAGS PROVIDERS (Tile 6)
// ═══════════════════════════════════════════════════════════════════════════

/// Current consent level for TAGS
final tagsConsentLevelProvider = StateProvider<ConsentLevel>((ref) {
  return ConsentLevel.green;
});

/// Available games based on consent level
final availableGamesProvider = Provider<List<GameCategory>>((ref) {
  final consentLevel = ref.watch(tagsConsentLevelProvider);
  
  return GameCategory.values.where((game) {
    return game.minimumConsentLevel.value <= consentLevel.value;
  }).toList();
});

/// Active game session
final activeGameProvider = StateProvider<TagsGame?>((ref) => null);

/// Game cards for current session (Truth or Dare / Pleasure Deck)
final gameCardsProvider = FutureProvider<List<GameCard>>((ref) async {
  final consentLevel = ref.watch(tagsConsentLevelProvider);
  
  final response = await supabase
      .from('game_cards')
      .select()
      .eq('level', consentLevel.name)
      .order('intensity');
  
  return (response as List)
      .map((json) => GameCard.fromJson(json))
      .toList();
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
final vouchLinkProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return '';
  
  final response = await supabase
      .rpc('generate_vouch_link', params: {'user_id': user.id});
  
  return response as String? ?? '';
});

// ═══════════════════════════════════════════════════════════════════════════
// MIRROR PROVIDERS (Tile 8)
// ═══════════════════════════════════════════════════════════════════════════

/// User analytics provider
final userAnalyticsProvider = FutureProvider<UserAnalytics?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final response = await supabase
      .from('user_analytics')
      .select()
      .eq('user_id', user.id)
      .single();
  
  return UserAnalytics.fromJson(response);
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
