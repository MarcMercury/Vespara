import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_profile_coach.dart';
import '../services/instant_conversation_starters.dart';
import '../services/match_insights_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PHASE 3: VISIBLE MAGIC - Providers
/// ════════════════════════════════════════════════════════════════════════════
///
/// These providers give users visible AI help with ZERO extra effort:
/// - Profile coaching with one-tap bio improvements
/// - Instant conversation starters when chat opens
/// - Match insights visible on every card

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// AI Profile Coach - Instant bio improvements
final aiProfileCoachProvider =
    Provider<AIProfileCoach>((ref) => AIProfileCoach.instance);

/// Conversation Starters - Ready when chat opens
final conversationStartersProvider = Provider<InstantConversationStarters>(
    (ref) => InstantConversationStarters.instance,);

/// Match Insights - Compatibility at a glance
final matchInsightsProvider =
    Provider<MatchInsightsService>((ref) => MatchInsightsService.instance);

// ═══════════════════════════════════════════════════════════════════════════
// ASYNC PROVIDERS - For specific data
// ═══════════════════════════════════════════════════════════════════════════

/// Get bio improvement options for current bio
final bioOptionsProvider =
    FutureProvider.family<List<BioOption>, String>((ref, currentBio) async {
  final coach = ref.watch(aiProfileCoachProvider);
  return coach.getImprovedBios(currentBio);
});

/// Get conversation starters for a match
final startersForMatchProvider =
    FutureProvider.family<List<ConversationStarter>, String>(
        (ref, matchId) async {
  final service = ref.watch(conversationStartersProvider);
  return service.getStarters(matchId);
});

/// Get first message starters (more personalized for first contact)
final firstMessageStartersProvider =
    FutureProvider.family<List<ConversationStarter>, String>(
        (ref, matchId) async {
  final service = ref.watch(conversationStartersProvider);
  return service.getFirstMessageStarters(matchId);
});

/// Get revival starters for dying conversations
final revivalStartersProvider =
    FutureProvider.family<List<ConversationStarter>, String>(
        (ref, matchId) async {
  final service = ref.watch(conversationStartersProvider);
  return service.getRevivalStarters(matchId);
});

/// Get quick insight for a profile (sync from cache)
final quickInsightProvider =
    Provider.family<String, String>((ref, otherUserId) {
  final service = ref.watch(matchInsightsProvider);
  return service.getQuickInsightSync(otherUserId);
});

/// Get detailed insight for a profile
final detailedInsightProvider =
    FutureProvider.family<MatchInsight, String>((ref, otherUserId) async {
  final service = ref.watch(matchInsightsProvider);
  return service.getDetailedInsight(otherUserId);
});

// ═══════════════════════════════════════════════════════════════════════════
// STATE NOTIFIERS - For UI State
// ═══════════════════════════════════════════════════════════════════════════

/// Manages bio editing state with AI assistance
class BioEditorNotifier extends StateNotifier<BioEditorState> {
  BioEditorNotifier(this._coach) : super(const BioEditorState());
  final AIProfileCoach _coach;

  Future<void> loadOptions(String currentBio) async {
    state = state.copyWith(isLoading: true, originalBio: currentBio);

    final options = await _coach.getImprovedBios(currentBio);

    state = state.copyWith(
      isLoading: false,
      options: options,
      showOptions: true,
    );
  }

  void selectOption(BioOption option) {
    state = state.copyWith(
      selectedBio: option.text,
      showOptions: false,
    );
  }

  Future<void> applySelection() async {
    if (state.selectedBio != null) {
      await _coach.applyBio(state.selectedBio!);
      state = state.copyWith(applied: true);
    }
  }

  void reset() {
    state = const BioEditorState();
  }
}

class BioEditorState {
  const BioEditorState({
    this.isLoading = false,
    this.showOptions = false,
    this.originalBio,
    this.options = const [],
    this.selectedBio,
    this.applied = false,
  });
  final bool isLoading;
  final bool showOptions;
  final String? originalBio;
  final List<BioOption> options;
  final String? selectedBio;
  final bool applied;

  BioEditorState copyWith({
    bool? isLoading,
    bool? showOptions,
    String? originalBio,
    List<BioOption>? options,
    String? selectedBio,
    bool? applied,
  }) =>
      BioEditorState(
        isLoading: isLoading ?? this.isLoading,
        showOptions: showOptions ?? this.showOptions,
        originalBio: originalBio ?? this.originalBio,
        options: options ?? this.options,
        selectedBio: selectedBio ?? this.selectedBio,
        applied: applied ?? this.applied,
      );
}

final bioEditorProvider =
    StateNotifierProvider<BioEditorNotifier, BioEditorState>(
        (ref) => BioEditorNotifier(ref.watch(aiProfileCoachProvider)),);

/// Manages conversation starter state for a chat
class StarterChipsNotifier extends StateNotifier<StarterChipsState> {
  StarterChipsNotifier(this._service) : super(const StarterChipsState());
  final InstantConversationStarters _service;

  Future<void> loadStarters(String matchId,
      {bool isFirstMessage = true,}) async {
    state = state.copyWith(isLoading: true, matchId: matchId);

    final starters = isFirstMessage
        ? await _service.getFirstMessageStarters(matchId)
        : await _service.getStarters(matchId);

    state = state.copyWith(
      isLoading: false,
      starters: starters,
      isVisible: starters.isNotEmpty,
    );
  }

  void hide() {
    state = state.copyWith(isVisible: false);
  }

  void clearForMatch(String matchId) {
    _service.clearCache(matchId);
    state = const StarterChipsState();
  }
}

class StarterChipsState {
  const StarterChipsState({
    this.isLoading = false,
    this.isVisible = true,
    this.matchId,
    this.starters = const [],
  });
  final bool isLoading;
  final bool isVisible;
  final String? matchId;
  final List<ConversationStarter> starters;

  StarterChipsState copyWith({
    bool? isLoading,
    bool? isVisible,
    String? matchId,
    List<ConversationStarter>? starters,
  }) =>
      StarterChipsState(
        isLoading: isLoading ?? this.isLoading,
        isVisible: isVisible ?? this.isVisible,
        matchId: matchId ?? this.matchId,
        starters: starters ?? this.starters,
      );
}

final starterChipsProvider =
    StateNotifierProvider<StarterChipsNotifier, StarterChipsState>(
        (ref) => StarterChipsNotifier(ref.watch(conversationStartersProvider)),);

// ═══════════════════════════════════════════════════════════════════════════
// PREFETCH HELPER
// ═══════════════════════════════════════════════════════════════════════════

/// Prefetch insights for discovery feed profiles
final insightPrefetchProvider =
    FutureProvider.family<void, List<Map<String, dynamic>>>(
        (ref, profiles) async {
  final service = ref.watch(matchInsightsProvider);
  await service.prefetchInsights(profiles);
});

// ═══════════════════════════════════════════════════════════════════════════
// INITIALIZATION
// ═══════════════════════════════════════════════════════════════════════════

/// Initialize all Phase 3 services
Future<void> initializePhase3Services() async {
  // Services are lazy singletons, just access them to ensure they exist
  AIProfileCoach.instance;
  InstantConversationStarters.instance;
  MatchInsightsService.instance;
}
