import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_dna_service.dart';
import '../services/deep_bio_generator.dart';
import '../services/hard_truth_engine.dart';
import '../services/smart_trait_recommender.dart';
import '../services/deep_connection_engine.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DEEP AI PROVIDERS - Psychology-Driven Intelligence Layer
/// ════════════════════════════════════════════════════════════════════════════
///
/// These providers connect the deep AI services to the UI:
/// - UserDNA: The master psychological profile feeding everything
/// - DeepBioGenerator: Psychologically-informed bio creation
/// - HardTruthEngine: Real self-assessment, not metrics thresholds
/// - SmartTraitRecommender: Personalized trait/interest suggestions
/// - DeepConnectionEngine: Multi-dimensional compatibility scoring

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE SINGLETONS
// ═══════════════════════════════════════════════════════════════════════════

/// User DNA Service — the psychological profile intelligence layer
final userDNAServiceProvider =
    Provider<UserDNAService>((ref) => UserDNAService.instance);

/// Deep Bio Generator — psychologically-calibrated bios
final deepBioGeneratorProvider =
    Provider<DeepBioGenerator>((ref) => DeepBioGenerator.instance);

/// Hard Truth Engine — deep self-assessment with contradiction detection
final hardTruthEngineProvider =
    Provider<HardTruthEngine>((ref) => HardTruthEngine.instance);

/// Smart Trait Recommender — personalized trait/interest suggestions
final smartTraitRecommenderProvider =
    Provider<SmartTraitRecommender>((ref) => SmartTraitRecommender.instance);

/// Deep Connection Engine — multi-dimensional compatibility scoring
final deepConnectionEngineProvider =
    Provider<DeepConnectionEngine>((ref) => DeepConnectionEngine.instance);

// ═══════════════════════════════════════════════════════════════════════════
// ASYNC DATA PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Build the user's full psychological DNA
final userDNAProvider = FutureProvider<UserDNA?>((ref) async {
  final service = ref.watch(userDNAServiceProvider);
  return service.buildUserDNA();
});

/// Build DNA for a specific user (for match viewing)
final userDNAByIdProvider =
    FutureProvider.family<UserDNA?, String>((ref, userId) async {
  final service = ref.watch(userDNAServiceProvider);
  return service.buildUserDNA(userId: userId);
});

/// Generate deeply personalized bio options
final deepBioOptionsProvider =
    FutureProvider<List<BioGenResult>>((ref) async {
  final generator = ref.watch(deepBioGeneratorProvider);
  return generator.generateDeepBios();
});

/// Generate Hard Truth assessment
final hardTruthAssessmentProvider =
    FutureProvider<HardTruthAssessment?>((ref) async {
  final engine = ref.watch(hardTruthEngineProvider);
  return engine.generateAssessment();
});

/// Force refresh Hard Truth assessment
final hardTruthRefreshProvider =
    FutureProvider<HardTruthAssessment?>((ref) async {
  final engine = ref.watch(hardTruthEngineProvider);
  return engine.generateAssessment(forceRefresh: true);
});

/// Get smart trait recommendations
final traitRecommendationsProvider =
    FutureProvider<TraitRecommendations>((ref) async {
  final recommender = ref.watch(smartTraitRecommenderProvider);
  return recommender.getRecommendations();
});

/// Deep compatibility score between current user and a match
final deepCompatibilityProvider =
    FutureProvider.family<DeepCompatibility, String>(
        (ref, otherUserId) async {
  final engine = ref.watch(deepConnectionEngineProvider);
  final dnaService = ref.watch(userDNAServiceProvider);

  final myDna = await dnaService.buildUserDNA();
  if (myDna == null) return DeepCompatibility.unknown();

  return engine.scoreCompatibility(
    userId1: myDna.userId,
    userId2: otherUserId,
  );
});

/// AI-generated connection story for a match pair
final connectionStoryProvider =
    FutureProvider.family<String?, String>((ref, otherUserId) async {
  final engine = ref.watch(deepConnectionEngineProvider);
  final dnaService = ref.watch(userDNAServiceProvider);

  final myDna = await dnaService.buildUserDNA();
  if (myDna == null) return null;

  return engine.generateConnectionStory(
    userId1: myDna.userId,
    userId2: otherUserId,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// STATE NOTIFIERS
// ═══════════════════════════════════════════════════════════════════════════

/// Manages the Hard Truth assessment state with refresh capability
class HardTruthNotifier extends StateNotifier<HardTruthState> {
  HardTruthNotifier(this._engine) : super(const HardTruthState());
  final HardTruthEngine _engine;

  Future<void> loadAssessment() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final assessment = await _engine.generateAssessment();
      state = state.copyWith(
        isLoading: false,
        assessment: assessment,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to generate assessment: $e',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final assessment = await _engine.generateAssessment(forceRefresh: true);
      state = state.copyWith(
        isLoading: false,
        assessment: assessment,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh assessment: $e',
      );
    }
  }
}

class HardTruthState {
  const HardTruthState({
    this.assessment,
    this.isLoading = false,
    this.error,
  });

  final HardTruthAssessment? assessment;
  final bool isLoading;
  final String? error;

  HardTruthState copyWith({
    HardTruthAssessment? assessment,
    bool? isLoading,
    String? error,
  }) => HardTruthState(
        assessment: assessment ?? this.assessment,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final hardTruthNotifierProvider =
    StateNotifierProvider<HardTruthNotifier, HardTruthState>((ref) {
  final engine = ref.watch(hardTruthEngineProvider);
  return HardTruthNotifier(engine);
});

/// Manages deep bio editing state
class DeepBioNotifier extends StateNotifier<DeepBioState> {
  DeepBioNotifier(this._generator) : super(const DeepBioState());
  final DeepBioGenerator _generator;

  Future<void> generateOptions() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final options = await _generator.generateDeepBios();
      state = state.copyWith(
        isLoading: false,
        options: options,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to generate bio options: $e',
      );
    }
  }

  void selectBio(int index) {
    if (index >= 0 && index < state.options.length) {
      state = state.copyWith(selectedIndex: index);
    }
  }
}

class DeepBioState {
  const DeepBioState({
    this.options = const [],
    this.selectedIndex,
    this.isLoading = false,
    this.error,
  });

  final List<BioGenResult> options;
  final int? selectedIndex;
  final bool isLoading;
  final String? error;

  String? get selectedBio =>
      selectedIndex != null && selectedIndex! < options.length
          ? options[selectedIndex!].bio
          : null;

  DeepBioState copyWith({
    List<BioGenResult>? options,
    int? selectedIndex,
    bool? isLoading,
    String? error,
  }) => DeepBioState(
        options: options ?? this.options,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final deepBioNotifierProvider =
    StateNotifierProvider<DeepBioNotifier, DeepBioState>((ref) {
  final generator = ref.watch(deepBioGeneratorProvider);
  return DeepBioNotifier(generator);
});
