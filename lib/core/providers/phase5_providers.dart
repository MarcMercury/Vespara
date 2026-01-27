// ════════════════════════════════════════════════════════════════════════════
// PHASE 5: SEAMLESS INTEGRATION - Providers
// ════════════════════════════════════════════════════════════════════════════
//
// Everything wired together invisibly. AI enhances without announcing itself.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai/ambient_intelligence.dart';
import '../services/ai/dynamic_game_generator.dart';
import '../services/ai/predictive_matching_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Dynamic game generator - creates personalized prompts
final dynamicGameGeneratorProvider =
    Provider<DynamicGameGenerator>((ref) => DynamicGameGenerator.instance);

/// Predictive matching engine - learns from successful couples
final predictiveMatchingEngineProvider = Provider<PredictiveMatchingEngine>(
    (ref) => PredictiveMatchingEngine.instance,);

/// Ambient intelligence - app simplifies itself over time
final ambientIntelligenceProvider =
    Provider<AmbientIntelligence>((ref) => AmbientIntelligence.instance);

// ═══════════════════════════════════════════════════════════════════════════
// DYNAMIC GAME GENERATION
// ═══════════════════════════════════════════════════════════════════════════

/// Get personalized prompts for a couple
final personalizedPromptsProvider =
    FutureProvider.family<List<DynamicPrompt>, PersonalizedPromptRequest>(
        (ref, request) async {
  final generator = ref.read(dynamicGameGeneratorProvider);

  return generator.generatePromptsForCouple(
    matchId: request.matchId,
    gameType: request.gameType,
    heatLevel: request.heatLevel,
    count: request.count,
  );
});

/// Request class for personalized prompts
class PersonalizedPromptRequest {
  PersonalizedPromptRequest({
    required this.matchId,
    required this.gameType,
    this.heatLevel = 2,
    this.count = 10,
  });
  final String matchId;
  final String gameType;
  final int heatLevel;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is PersonalizedPromptRequest &&
      matchId == other.matchId &&
      gameType == other.gameType &&
      heatLevel == other.heatLevel &&
      count == other.count;

  @override
  int get hashCode => Object.hash(matchId, gameType, heatLevel, count);
}

/// Single contextual prompt for current moment
final contextualPromptProvider =
    FutureProvider.family<DynamicPrompt, ContextualPromptRequest>(
        (ref, request) async {
  final generator = ref.read(dynamicGameGeneratorProvider);

  return generator.generateContextualPrompt(
    matchId: request.matchId,
    gameType: request.gameType,
    conversationContext: request.conversationContext,
    timeOfDay: request.timeOfDay ?? _getTimeOfDay(),
    mood: request.mood,
  );
});

class ContextualPromptRequest {
  ContextualPromptRequest({
    required this.matchId,
    required this.gameType,
    this.conversationContext,
    this.timeOfDay,
    this.mood,
  });
  final String matchId;
  final String gameType;
  final String? conversationContext;
  final String? timeOfDay;
  final String? mood;

  @override
  bool operator ==(Object other) =>
      other is ContextualPromptRequest &&
      matchId == other.matchId &&
      gameType == other.gameType;

  @override
  int get hashCode => Object.hash(matchId, gameType);
}

String _getTimeOfDay() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  if (hour < 21) return 'evening';
  return 'night';
}

// ═══════════════════════════════════════════════════════════════════════════
// PREDICTIVE MATCHING
// ═══════════════════════════════════════════════════════════════════════════

/// Predict compatibility between two users
final compatibilityPredictionProvider =
    FutureProvider.family<MatchPrediction, CompatibilityRequest>(
        (ref, request) async {
  final engine = ref.read(predictiveMatchingEngineProvider);

  return engine.predictCompatibility(
    userId: request.userId,
    potentialMatchId: request.potentialMatchId,
  );
});

class CompatibilityRequest {
  CompatibilityRequest({
    required this.userId,
    required this.potentialMatchId,
  });
  final String userId;
  final String potentialMatchId;

  @override
  bool operator ==(Object other) =>
      other is CompatibilityRequest &&
      userId == other.userId &&
      potentialMatchId == other.potentialMatchId;

  @override
  int get hashCode => Object.hash(userId, potentialMatchId);
}

/// Get ranked matches for a user
final rankedMatchesProvider =
    FutureProvider.family<List<RankedMatch>, String>((ref, userId) async {
  final engine = ref.read(predictiveMatchingEngineProvider);
  return engine.rankPotentialMatches(userId);
});

// ═══════════════════════════════════════════════════════════════════════════
// AMBIENT INTELLIGENCE
// ═══════════════════════════════════════════════════════════════════════════

/// Feature visibility for a user
final featureVisibilityProvider =
    FutureProvider.family<FeatureVisibility, FeatureVisibilityRequest>(
        (ref, request) async {
  final ambient = ref.read(ambientIntelligenceProvider);

  return ambient.getFeatureVisibility(
    userId: request.userId,
    featureId: request.featureId,
  );
});

class FeatureVisibilityRequest {
  FeatureVisibilityRequest({
    required this.userId,
    required this.featureId,
  });
  final String userId;
  final String featureId;

  @override
  bool operator ==(Object other) =>
      other is FeatureVisibilityRequest &&
      userId == other.userId &&
      featureId == other.featureId;

  @override
  int get hashCode => Object.hash(userId, featureId);
}

/// Smart defaults for a user
final smartDefaultProvider =
    FutureProvider.family<dynamic, SmartDefaultRequest>((ref, request) async {
  final ambient = ref.read(ambientIntelligenceProvider);

  return ambient.getSmartDefault(
    userId: request.userId,
    key: request.key,
    defaultValue: request.defaultValue,
  );
});

class SmartDefaultRequest {
  SmartDefaultRequest({
    required this.userId,
    required this.key,
    this.defaultValue,
  });
  final String userId;
  final String key;
  final dynamic defaultValue;

  @override
  bool operator ==(Object other) =>
      other is SmartDefaultRequest &&
      userId == other.userId &&
      key == other.key;

  @override
  int get hashCode => Object.hash(userId, key);
}

/// Contextual suggestions for a user
final contextualSuggestionsProvider =
    FutureProvider.family<List<ContextualSuggestion>, SuggestionsRequest>(
        (ref, request) async {
  final ambient = ref.read(ambientIntelligenceProvider);

  return ambient.getSuggestions(
    userId: request.userId,
    currentScreen: request.currentScreen,
    context: request.context,
  );
});

class SuggestionsRequest {
  SuggestionsRequest({
    required this.userId,
    required this.currentScreen,
    this.context,
  });
  final String userId;
  final String currentScreen;
  final Map<String, dynamic>? context;

  @override
  bool operator ==(Object other) =>
      other is SuggestionsRequest &&
      userId == other.userId &&
      currentScreen == other.currentScreen;

  @override
  int get hashCode => Object.hash(userId, currentScreen);
}

/// Personalized quick actions for home screen
final quickActionsProvider =
    FutureProvider.family<List<QuickAction>, String>((ref, userId) async {
  final ambient = ref.read(ambientIntelligenceProvider);
  return ambient.getPersonalizedQuickActions(userId);
});

// ═══════════════════════════════════════════════════════════════════════════
// TRACK USAGE (fire and forget)
// ═══════════════════════════════════════════════════════════════════════════

/// State notifier for tracking usage
class UsageTracker extends StateNotifier<void> {
  UsageTracker(this._ambient) : super(null);
  final AmbientIntelligence _ambient;

  /// Track feature usage - call this everywhere
  void track(String userId, String featureId,
      {Map<String, dynamic>? metadata,}) {
    // Fire and forget
    _ambient.trackUsage(userId, featureId, metadata: metadata);
  }

  /// Track match outcome - for learning
  void trackMatchOutcome(String matchId, String outcome,
      {Map<String, dynamic>? signals,}) {
    // Fire and forget
    PredictiveMatchingEngine.instance.recordMatchOutcome(
      matchId: matchId,
      outcome: outcome,
      signals: signals ?? {},
    );
  }

  /// Track prompt reaction
  void trackPromptReaction(String matchId, String promptId, String reaction) {
    // Fire and forget - improve prompts over time
    DynamicGameGenerator.instance.recordPromptReaction(
      matchId: matchId,
      promptId: promptId,
      reaction: reaction,
    );
  }
}

final usageTrackerProvider = StateNotifierProvider<UsageTracker, void>(
    (ref) => UsageTracker(ref.read(ambientIntelligenceProvider)),);

// ═══════════════════════════════════════════════════════════════════════════
// CONVENIENCE EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Extension for easy tracking in any widget
extension UsageTrackingRef on WidgetRef {
  void trackUsage(String userId, String featureId,
      {Map<String, dynamic>? metadata,}) {
    read(usageTrackerProvider.notifier)
        .track(userId, featureId, metadata: metadata);
  }

  void trackPromptReaction(String matchId, String promptId, String reaction) {
    read(usageTrackerProvider.notifier)
        .trackPromptReaction(matchId, promptId, reaction);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSED PROVIDERS (High-level convenience)
// ═══════════════════════════════════════════════════════════════════════════

/// Everything needed for the discover screen
final discoverIntelligenceProvider =
    FutureProvider.family<DiscoverIntelligence, String>((ref, userId) async {
  final matches = await ref.watch(rankedMatchesProvider(userId).future);
  final suggestions = await ref.watch(
    contextualSuggestionsProvider(
      SuggestionsRequest(userId: userId, currentScreen: 'discover'),
    ).future,
  );
  final quickActions = await ref.watch(quickActionsProvider(userId).future);

  return DiscoverIntelligence(
    rankedMatches: matches,
    suggestions: suggestions,
    quickActions: quickActions,
  );
});

class DiscoverIntelligence {
  DiscoverIntelligence({
    required this.rankedMatches,
    required this.suggestions,
    required this.quickActions,
  });
  final List<RankedMatch> rankedMatches;
  final List<ContextualSuggestion> suggestions;
  final List<QuickAction> quickActions;
}

/// Everything needed for a game session
final gameIntelligenceProvider =
    FutureProvider.family<GameIntelligence, GameIntelligenceRequest>(
        (ref, request) async {
  final prompts = await ref.watch(
    personalizedPromptsProvider(
      PersonalizedPromptRequest(
        matchId: request.matchId,
        gameType: request.gameType,
        heatLevel: request.heatLevel,
      ),
    ).future,
  );

  final visibility = await ref.watch(
    featureVisibilityProvider(
      FeatureVisibilityRequest(
          userId: request.userId, featureId: 'game_${request.gameType}',),
    ).future,
  );

  return GameIntelligence(
    personalizedPrompts: prompts,
    featureVisibility: visibility,
  );
});

class GameIntelligenceRequest {
  GameIntelligenceRequest({
    required this.userId,
    required this.matchId,
    required this.gameType,
    this.heatLevel = 2,
  });
  final String userId;
  final String matchId;
  final String gameType;
  final int heatLevel;

  @override
  bool operator ==(Object other) =>
      other is GameIntelligenceRequest &&
      userId == other.userId &&
      matchId == other.matchId &&
      gameType == other.gameType &&
      heatLevel == other.heatLevel;

  @override
  int get hashCode => Object.hash(userId, matchId, gameType, heatLevel);
}

class GameIntelligence {
  GameIntelligence({
    required this.personalizedPrompts,
    required this.featureVisibility,
  });
  final List<DynamicPrompt> personalizedPrompts;
  final FeatureVisibility featureVisibility;
}
