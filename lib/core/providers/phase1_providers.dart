import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/background_pregeneration_service.dart';
import '../services/engagement_analytics_service.dart';
import '../services/prefetch_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PHASE 1 PROVIDERS - Silent Intelligence
/// ════════════════════════════════════════════════════════════════════════════
///
/// Providers for Phase 1 AI features:
/// - Smart prefetching
/// - Engagement analytics
/// - Background content pregeneration

// ═══════════════════════════════════════════════════════════════════════════
// PREFETCH SERVICE
// ═══════════════════════════════════════════════════════════════════════════

/// Prefetch service singleton
final prefetchServiceProvider =
    Provider<PrefetchService>((ref) => PrefetchService.instance);

/// Prefetch cache statistics
final prefetchStatsProvider = Provider<Map<String, int>>((ref) {
  final service = ref.watch(prefetchServiceProvider);
  return service.stats;
});

// ═══════════════════════════════════════════════════════════════════════════
// ENGAGEMENT ANALYTICS
// ═══════════════════════════════════════════════════════════════════════════

/// Engagement analytics service singleton
final engagementAnalyticsProvider = Provider<EngagementAnalyticsService>(
    (ref) => EngagementAnalyticsService.instance);

/// User's most active hours (learned from behavior)
final userActiveHoursProvider = FutureProvider<List<int>>((ref) async {
  final analytics = ref.watch(engagementAnalyticsProvider);
  return analytics.getUserActiveHours();
});

/// User's preferred heat levels by game (learned from behavior)
final userPreferredHeatLevelsProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final analytics = ref.watch(engagementAnalyticsProvider);
  return analytics.getPreferredHeatLevels();
});

/// Get user's preferred heat for a specific game
final preferredHeatForGameProvider =
    FutureProvider.family<String, String>((ref, gameType) async {
  final preferences = await ref.watch(userPreferredHeatLevelsProvider.future);
  return preferences[gameType] ??
      'PG'; // Default to PG if no preference learned
});

// ═══════════════════════════════════════════════════════════════════════════
// BACKGROUND PREGENERATION
// ═══════════════════════════════════════════════════════════════════════════

/// Background pregeneration service singleton
final backgroundPregenerationProvider =
    Provider<BackgroundPregenerationService>(
        (ref) => BackgroundPregenerationService.instance);

/// Pregenerated ice breakers for a scenario
final pregeneratedIceBreakersProvider =
    Provider.family<List<String>, String>((ref, scenario) {
  final service = ref.watch(backgroundPregenerationProvider);
  return service.getIceBreakers(scenario);
});

/// Pregenerated bio suggestions for a style
final pregeneratedBioSuggestionsProvider =
    Provider.family<List<String>, String>((ref, style) {
  final service = ref.watch(backgroundPregenerationProvider);
  return service.getBioSuggestions(style);
});

/// Pregenerated conversation templates for a situation
final pregeneratedConversationTemplatesProvider =
    Provider.family<List<String>, String>((ref, situation) {
  final service = ref.watch(backgroundPregenerationProvider);
  return service.getConversationTemplates(situation);
});

/// Check if pregenerated content is available
final hasPregenContentProvider =
    Provider.family<bool, (ContentType, String)>((ref, params) {
  final service = ref.watch(backgroundPregenerationProvider);
  return service.hasContent(params.$1, params.$2);
});

/// Background pregeneration statistics
final pregenerationStatsProvider = Provider<Map<String, int>>((ref) {
  final service = ref.watch(backgroundPregenerationProvider);
  return service.stats;
});

// ═══════════════════════════════════════════════════════════════════════════
// COMBINED INTELLIGENCE
// ═══════════════════════════════════════════════════════════════════════════

/// Smart game defaults based on learned preferences
final smartGameDefaultsProvider =
    FutureProvider.family<SmartGameDefaults, String>((ref, gameType) async {
  final preferredHeat =
      await ref.watch(preferredHeatForGameProvider(gameType).future);

  return SmartGameDefaults(
    gameType: gameType,
    suggestedHeatLevel: preferredHeat,
  );
});

/// Data class for smart game defaults
class SmartGameDefaults {
  const SmartGameDefaults({
    required this.gameType,
    required this.suggestedHeatLevel,
  });
  final String gameType;
  final String suggestedHeatLevel;
}

// ═══════════════════════════════════════════════════════════════════════════
// INITIALIZATION
// ═══════════════════════════════════════════════════════════════════════════

/// Initialize all Phase 1 services
/// Call this early in app startup
void initializePhase1Services(String userId) {
  // Start prefetching
  final prefetch = PrefetchService.instance;
  prefetch.onAppOpen(userId);

  // Start engagement tracking
  final analytics = EngagementAnalyticsService.instance;
  analytics.trackSessionStart();

  // Start background pregeneration
  final pregen = BackgroundPregenerationService.instance;
  pregen.start();
}

/// Cleanup Phase 1 services
/// Call this on app close
Future<void> cleanupPhase1Services() async {
  // Flush analytics
  final analytics = EngagementAnalyticsService.instance;
  await analytics.forceFlush();

  // Stop background generation
  final pregen = BackgroundPregenerationService.instance;
  pregen.stop();

  // Clear caches
  final prefetch = PrefetchService.instance;
  prefetch.clearAll();
}
