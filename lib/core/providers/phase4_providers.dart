import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/date_planner_service.dart';
import '../services/message_coach_service.dart';
import '../services/relationship_progress_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PHASE 4: PROACTIVE PARTNER - Providers
/// ════════════════════════════════════════════════════════════════════════════
///
/// Active AI assistance that users can control:
/// - Date planning with instant suggestions
/// - Real-time message coaching (toggleable)
/// - Relationship progress tracking

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Date Planner - Instant date suggestions
final datePlannerProvider = Provider<DatePlannerService>((ref) {
  return DatePlannerService.instance;
});

/// Message Coach - Real-time suggestions
final messageCoachProvider = Provider<MessageCoachService>((ref) {
  return MessageCoachService.instance;
});

/// Relationship Progress - Auto-tracked milestones
final relationshipProgressProvider = Provider<RelationshipProgressService>((ref) {
  return RelationshipProgressService.instance;
});

// ═══════════════════════════════════════════════════════════════════════════
// ASYNC DATA PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Get date ideas for a match
final dateIdeasProvider = FutureProvider.family<List<DateIdea>, String>((ref, matchId) async {
  final service = ref.watch(datePlannerProvider);
  return service.getDateIdeas(matchId);
});

/// Get date ideas by vibe
final dateIdeasByVibeProvider = FutureProvider.family<List<DateIdea>, DateVibeRequest>((ref, request) async {
  final service = ref.watch(datePlannerProvider);
  return service.getDateIdeasByVibe(
    matchId: request.matchId,
    vibe: request.vibe,
  );
});

/// Get relationship progress for a match
final matchProgressProvider = FutureProvider.family<RelationshipProgress, String>((ref, matchId) async {
  final service = ref.watch(relationshipProgressProvider);
  return service.getProgress(matchId);
});

/// Get just the stage (lighter weight)
final matchStageProvider = FutureProvider.family<RelationshipStage, String>((ref, matchId) async {
  final service = ref.watch(relationshipProgressProvider);
  return service.getStage(matchId);
});

/// Get suggested next step
final nextStepProvider = FutureProvider.family<NextStep?, String>((ref, matchId) async {
  final service = ref.watch(relationshipProgressProvider);
  return service.getNextStep(matchId);
});

// ═══════════════════════════════════════════════════════════════════════════
// STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Message coach enabled state (user toggle)
final messageCoachEnabledProvider = StateProvider<bool>((ref) {
  final coach = ref.watch(messageCoachProvider);
  return coach.isEnabled;
});

/// Current message analysis
final messageAnalysisProvider = StateProvider<MessageAnalysis?>((ref) {
  return null;
});

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIERS
// ═══════════════════════════════════════════════════════════════════════════

/// Manages date planning state
class DatePlannerNotifier extends StateNotifier<DatePlannerState> {
  final DatePlannerService _service;

  DatePlannerNotifier(this._service) : super(const DatePlannerState());

  Future<void> loadIdeas(String matchId) async {
    state = state.copyWith(isLoading: true, matchId: matchId);

    final ideas = await _service.getDateIdeas(matchId);

    state = state.copyWith(
      isLoading: false,
      ideas: ideas,
    );
  }

  Future<void> loadByVibe(String matchId, DateVibe vibe) async {
    state = state.copyWith(isLoading: true, selectedVibe: vibe);

    final ideas = await _service.getDateIdeasByVibe(
      matchId: matchId,
      vibe: vibe,
    );

    state = state.copyWith(
      isLoading: false,
      ideas: ideas,
    );
  }

  void selectIdea(DateIdea idea) {
    state = state.copyWith(selectedIdea: idea);
  }

  String getShareMessage() {
    if (state.selectedIdea == null) return '';
    return _service.getShareMessage(state.selectedIdea!);
  }

  Future<void> saveIdea(String matchId) async {
    if (state.selectedIdea == null) return;
    await _service.saveDateIdea(
      matchId: matchId,
      idea: state.selectedIdea!,
    );
    state = state.copyWith(saved: true);
  }

  void reset() {
    state = const DatePlannerState();
  }
}

class DatePlannerState {
  final bool isLoading;
  final String? matchId;
  final DateVibe? selectedVibe;
  final List<DateIdea> ideas;
  final DateIdea? selectedIdea;
  final bool saved;

  const DatePlannerState({
    this.isLoading = false,
    this.matchId,
    this.selectedVibe,
    this.ideas = const [],
    this.selectedIdea,
    this.saved = false,
  });

  DatePlannerState copyWith({
    bool? isLoading,
    String? matchId,
    DateVibe? selectedVibe,
    List<DateIdea>? ideas,
    DateIdea? selectedIdea,
    bool? saved,
  }) {
    return DatePlannerState(
      isLoading: isLoading ?? this.isLoading,
      matchId: matchId ?? this.matchId,
      selectedVibe: selectedVibe ?? this.selectedVibe,
      ideas: ideas ?? this.ideas,
      selectedIdea: selectedIdea ?? this.selectedIdea,
      saved: saved ?? this.saved,
    );
  }
}

final datePlannerStateProvider = StateNotifierProvider<DatePlannerNotifier, DatePlannerState>((ref) {
  return DatePlannerNotifier(ref.watch(datePlannerProvider));
});

/// Manages message coaching state
class MessageCoachNotifier extends StateNotifier<MessageCoachState> {
  final MessageCoachService _service;

  MessageCoachNotifier(this._service) : super(const MessageCoachState());

  void toggleEnabled() {
    _service.isEnabled = !_service.isEnabled;
    state = state.copyWith(isEnabled: _service.isEnabled);
  }

  void analyzeMessage(String text) {
    _service.analyzeWhileTyping(text, (analysis) {
      state = state.copyWith(currentAnalysis: analysis);
    });
  }

  void clearAnalysis() {
    state = state.copyWith(currentAnalysis: null);
  }

  List<String> getEmojiSuggestions(String text) {
    return _service.getEmojiSuggestions(text);
  }

  List<String> getQuickResponses(String receivedMessage) {
    return _service.getQuickResponses(receivedMessage);
  }
}

class MessageCoachState {
  final bool isEnabled;
  final MessageAnalysis? currentAnalysis;

  const MessageCoachState({
    this.isEnabled = true,
    this.currentAnalysis,
  });

  MessageCoachState copyWith({
    bool? isEnabled,
    MessageAnalysis? currentAnalysis,
  }) {
    return MessageCoachState(
      isEnabled: isEnabled ?? this.isEnabled,
      currentAnalysis: currentAnalysis,
    );
  }
}

final messageCoachStateProvider = StateNotifierProvider<MessageCoachNotifier, MessageCoachState>((ref) {
  return MessageCoachNotifier(ref.watch(messageCoachProvider));
});

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class DateVibeRequest {
  final String matchId;
  final DateVibe vibe;

  DateVibeRequest({required this.matchId, required this.vibe});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateVibeRequest &&
          matchId == other.matchId &&
          vibe == other.vibe;

  @override
  int get hashCode => matchId.hashCode ^ vibe.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════════
// INITIALIZATION
// ═══════════════════════════════════════════════════════════════════════════

/// Initialize all Phase 4 services
Future<void> initializePhase4Services() async {
  // Services are lazy singletons
  DatePlannerService.instance;
  MessageCoachService.instance;
  RelationshipProgressService.instance;
}

/// Get all categories for quick date picker
List<DateCategory> getDateCategories() {
  return DatePlannerService.instance.getCategories();
}
