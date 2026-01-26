import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/conversation_health_monitor.dart';
import '../services/game_personalization_service.dart';
import '../services/gentle_nudge_system.dart';
import '../services/smart_defaults_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PHASE 2 PROVIDERS - Gentle Nudges
/// ════════════════════════════════════════════════════════════════════════════
///
/// Providers for Phase 2 AI features:
/// - Smart defaults (auto-select optimal settings)
/// - Conversation health monitoring
/// - Game personalization
/// - Gentle nudge system

// ═══════════════════════════════════════════════════════════════════════════
// SMART DEFAULTS
// ═══════════════════════════════════════════════════════════════════════════

/// Smart defaults service singleton
final smartDefaultsServiceProvider =
    Provider<SmartDefaultsService>((ref) => SmartDefaultsService.instance);

/// Suggested heat level for a game
final suggestedHeatLevelProvider =
    FutureProvider.family<String, String>((ref, gameType) async {
  final service = ref.watch(smartDefaultsServiceProvider);
  return service.getSuggestedHeatLevel(gameType);
});

/// Suggested heat level for a couple playing a game
final suggestedCoupleHeatProvider =
    FutureProvider.family<String, ({String matchId, String gameType})>(
        (ref, params) async {
  final service = ref.watch(smartDefaultsServiceProvider);
  return service.getSuggestedHeatForCouple(
    matchId: params.matchId,
    gameType: params.gameType,
  );
});

/// Best time to message a match
final bestMessageTimeProvider =
    FutureProvider.family<MessageTimingSuggestion, String>(
        (ref, matchId) async {
  final service = ref.watch(smartDefaultsServiceProvider);
  return service.getBestMessageTime(matchId);
});

/// Is now a good time to message?
final isGoodTimeToMessageProvider =
    FutureProvider.family<bool, String>((ref, matchId) async {
  final service = ref.watch(smartDefaultsServiceProvider);
  return service.isGoodTimeToMessage(matchId);
});

/// Profile improvement suggestions
final profileSuggestionsProvider =
    FutureProvider<List<ProfileSuggestion>>((ref) async {
  final service = ref.watch(smartDefaultsServiceProvider);
  return service.getProfileSuggestions();
});

/// Game suggestion for a match
final gameSuggestionProvider =
    FutureProvider.family<GameSuggestion, String>((ref, matchId) async {
  final service = ref.watch(smartDefaultsServiceProvider);
  return service.suggestGame(matchId: matchId);
});

// ═══════════════════════════════════════════════════════════════════════════
// CONVERSATION HEALTH
// ═══════════════════════════════════════════════════════════════════════════

/// Conversation health monitor singleton
final conversationHealthMonitorProvider = Provider<ConversationHealthMonitor>(
    (ref) => ConversationHealthMonitor.instance);

/// Health of a specific conversation
final conversationHealthProvider =
    FutureProvider.family<ConversationHealth, String>((ref, matchId) async {
  final monitor = ref.watch(conversationHealthMonitorProvider);
  return monitor.analyzeConversation(matchId);
});

/// Matches needing attention
final matchesNeedingAttentionProvider =
    FutureProvider<List<MatchNudge>>((ref) async {
  final monitor = ref.watch(conversationHealthMonitorProvider);
  return monitor.getMatchesNeedingAttention();
});

/// Conversation suggestions for a match
final conversationSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, matchId) async {
  final monitor = ref.watch(conversationHealthMonitorProvider);
  return monitor.getConversationSuggestions(matchId);
});

// ═══════════════════════════════════════════════════════════════════════════
// GAME PERSONALIZATION
// ═══════════════════════════════════════════════════════════════════════════

/// Game personalization service singleton
final gamePersonalizationServiceProvider = Provider<GamePersonalizationService>(
    (ref) => GamePersonalizationService.instance);

/// Get next personalized prompt
final personalizedPromptProvider = FutureProvider.family<
    PersonalizedPrompt?,
    ({
      String gameType,
      String heatLevel,
      String? coupleId
    })>((ref, params) async {
  final service = ref.watch(gamePersonalizationServiceProvider);
  return service.getNextPrompt(
    gameType: params.gameType,
    heatLevel: params.heatLevel,
    coupleId: params.coupleId,
  );
});

/// Intensity adjustment suggestion
final intensityAdjustmentProvider = Provider<IntensityAdjustment>((ref) {
  final service = ref.watch(gamePersonalizationServiceProvider);
  return service.getIntensityAdjustment();
});

/// Suggested heat change based on engagement
final suggestedHeatChangeProvider =
    Provider.family<String?, String>((ref, currentHeat) {
  final service = ref.watch(gamePersonalizationServiceProvider);
  return service.suggestHeatChange(currentHeat);
});

// ═══════════════════════════════════════════════════════════════════════════
// GENTLE NUDGES
// ═══════════════════════════════════════════════════════════════════════════

/// Gentle nudge system singleton
final gentleNudgeSystemProvider =
    Provider<GentleNudgeSystem>((ref) => GentleNudgeSystem.instance);

/// Stream of nudges
final nudgeStreamProvider = StreamProvider<Nudge>((ref) {
  final system = ref.watch(gentleNudgeSystemProvider);
  return system.nudgeStream;
});

/// Available nudges to show
final availableNudgesProvider = FutureProvider<List<Nudge>>((ref) async {
  final system = ref.watch(gentleNudgeSystemProvider);
  return system.checkForNudges();
});

/// Game suggestion nudge for a match
final gameSuggestionNudgeProvider =
    FutureProvider.family<Nudge?, String>((ref, matchId) async {
  final system = ref.watch(gentleNudgeSystemProvider);
  return system.getGameSuggestionNudge(matchId);
});

/// Whether nudges are enabled
final nudgesEnabledProvider = Provider<bool>((ref) {
  final system = ref.watch(gentleNudgeSystemProvider);
  return system.nudgesEnabled;
});

// ═══════════════════════════════════════════════════════════════════════════
// COMBINED INTELLIGENCE
// ═══════════════════════════════════════════════════════════════════════════

/// Complete match intelligence (combine multiple sources)
final matchIntelligenceProvider =
    FutureProvider.family<MatchIntelligence, String>((ref, matchId) async {
  final health = await ref.watch(conversationHealthProvider(matchId).future);
  final gameSuggestion =
      await ref.watch(gameSuggestionProvider(matchId).future);
  final messageTiming =
      await ref.watch(bestMessageTimeProvider(matchId).future);
  final isGoodTime =
      await ref.watch(isGoodTimeToMessageProvider(matchId).future);

  return MatchIntelligence(
    matchId: matchId,
    conversationHealth: health,
    suggestedGame: gameSuggestion,
    messageTiming: messageTiming,
    isGoodTimeToMessage: isGoodTime,
  );
});

/// Match intelligence data class
class MatchIntelligence {
  const MatchIntelligence({
    required this.matchId,
    required this.conversationHealth,
    required this.suggestedGame,
    required this.messageTiming,
    required this.isGoodTimeToMessage,
  });
  final String matchId;
  final ConversationHealth conversationHealth;
  final GameSuggestion suggestedGame;
  final MessageTimingSuggestion messageTiming;
  final bool isGoodTimeToMessage;

  bool get needsAttention => conversationHealth.needsAttention;
  bool get isHealthy =>
      conversationHealth.status == HealthStatus.healthy ||
      conversationHealth.status == HealthStatus.thriving;
}

// ═══════════════════════════════════════════════════════════════════════════
// INITIALIZATION
// ═══════════════════════════════════════════════════════════════════════════

/// Initialize Phase 2 services
void initializePhase2Services() {
  // Start nudge system
  // Services are lazy singletons, they initialize on first access
  SmartDefaultsService.instance.refresh();

  debugPrint('Phase 2 Services: Initialized');
}

/// Cleanup Phase 2 services
Future<void> cleanupPhase2Services() async {
  // Save pending game personalization data
  await GamePersonalizationService.instance.flushReactions();

  // Dispose nudge system
  GentleNudgeSystem.instance.dispose();
}

// Helper for debug print
void debugPrint(String message) {
  assert(() {
    print(message);
    return true;
  }());
}
