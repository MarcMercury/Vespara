import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';
import 'user_dna_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SMART TRAIT RECOMMENDER - Psychologically Calibrated Suggestions
/// ════════════════════════════════════════════════════════════════════════════
///
/// Replaces the flat "popular interests" approach with intelligent suggestions:
///
/// Old: "Here are the most popular interests across all users"
///   → Everyone sees the same list → Everyone picks the same things → Homogeneous profiles
///
/// New: "Based on YOUR psychological profile, here's what we think you'd vibe with"
///   → Explains WHY each suggestion fits
///   → Considers what their match targets would respond to
///   → Suggests things that make them more discoverable to compatible people
///   → Identifies "gap" traits they might not have considered

class SmartTraitRecommender {
  SmartTraitRecommender._();
  static SmartTraitRecommender? _instance;
  static SmartTraitRecommender get instance =>
      _instance ??= SmartTraitRecommender._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService.instance;
  final UserDNAService _dnaService = UserDNAService.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAIT RECOMMENDATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get smart trait recommendations personalized to this user's DNA.
  /// Used in the Mirror's BUILD tab ("CHECK ME" section) and onboarding.
  Future<TraitRecommendations> getRecommendations({
    String? userId,
    int maxSuggestions = 8,
  }) async {
    final dna = await _dnaService.buildUserDNA(userId: userId);
    if (dna == null) return TraitRecommendations.empty();

    // Phase 1: Local intelligence (instant, no API call)
    final localRecs = _generateLocalRecommendations(dna);

    // Phase 2: AI-enhanced recommendations (deeper, requires API)
    final aiRecs = await _generateAIRecommendations(dna, localRecs);

    // Phase 3: Discovery recommendations (from match pool data)
    final discoveryRecs = await _generateDiscoveryRecommendations(dna);

    // Merge and deduplicate
    return TraitRecommendations(
      personalityTraits: aiRecs?.personalityTraits ?? localRecs.personalityTraits,
      interestSuggestions: aiRecs?.interestSuggestions ?? localRecs.interestSuggestions,
      discoveryTraits: discoveryRecs,
      gapAnalysis: aiRecs?.gapAnalysis ?? localRecs.gapAnalysis,
      profileStrategies: aiRecs?.profileStrategies ?? [],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCAL INTELLIGENCE - Instant Suggestions
  // ═══════════════════════════════════════════════════════════════════════════

  TraitRecommendations _generateLocalRecommendations(UserDNA dna) {
    final personalityRecs = <TraitSuggestion>[];
    final interestRecs = <TraitSuggestion>[];
    final gapAnalysis = <GapInsight>[];

    // ── Personality trait recommendations based on DNA ──

    // Communication enhancement suggestions
    if (dna.communicationArchetype == 'jokester' &&
        !dna.traits.any((t) => t.contains('Witty'))) {
      personalityRecs.add(TraitSuggestion(
        trait: 'Witty & Sharp',
        reason: 'Your communication style is naturally humorous — adding this trait helps like-minded people find you',
        confidence: 0.9,
        category: 'communication_match',
      ));
    }

    if (dna.communicationArchetype == 'deep_diver' &&
        !dna.traits.any((t) => t.contains('Intellectual'))) {
      personalityRecs.add(TraitSuggestion(
        trait: 'Intellectually Curious',
        reason: 'Deep divers attract best when potential matches know that depth is welcome here',
        confidence: 0.85,
        category: 'communication_match',
      ));
    }

    // Energy/social suggestions
    if (dna.socialEnergyProfile == 'high_energy_social' &&
        !dna.traits.any((t) => t.contains('Life of the Party'))) {
      personalityRecs.add(TraitSuggestion(
        trait: 'Life of the Party',
        reason: 'Your high social energy and activity patterns scream this — own it',
        confidence: 0.8,
        category: 'energy_match',
      ));
    }

    if (dna.socialEnergyProfile == 'selective_introvert' &&
        dna.traits.any((t) => t.contains('Life of the Party'))) {
      gapAnalysis.add(GapInsight(
        type: 'misalignment',
        observation: 'You selected "Life of the Party" but your behavior patterns suggest you\'re more selective social — consider swapping for "Selectively Social" for more authentic matches',
      ));
    }

    // Intimacy blueprint suggestions
    if (dna.intimacyBlueprint == 'power_exchange_explorer') {
      final hasDynamic = dna.traits.any((t) =>
          t.contains('Dominant') || t.contains('Submissive') || t.contains('Switch'));
      if (!hasDynamic) {
        personalityRecs.add(TraitSuggestion(
          trait: 'Switch',
          reason: 'Your heat level and preferences suggest power exchange interest — being explicit helps find compatible partners',
          confidence: 0.75,
          category: 'intimacy_match',
        ));
      }
    }

    if (dna.intimacyBlueprint == 'romantic_connection_first' &&
        !dna.traits.any((t) => t.contains('Romantic'))) {
      personalityRecs.add(TraitSuggestion(
        trait: 'Romantic',
        reason: 'Your mild heat level and connection-first approach align perfectly — signal it clearly',
        confidence: 0.85,
        category: 'intimacy_match',
      ));
    }

    // ── Interest suggestions based on complementary patterns ──

    // Map existing interests to complementary ones
    final complementaryMap = {
      'cooking': ['wine tasting', 'farmers markets', 'travel'],
      'hiking': ['camping', 'photography', 'yoga'],
      'music': ['concerts', 'vinyl collecting', 'dancing'],
      'travel': ['languages', 'photography', 'food & drink'],
      'reading': ['writing', 'bookstores', 'philosophy'],
      'fitness': ['nutrition', 'meditation', 'outdoor adventures'],
      'photography': ['art galleries', 'nature', 'visual storytelling'],
      'gaming': ['board games', 'escape rooms', 'movie nights'],
      'yoga': ['meditation', 'mindfulness', 'wellness'],
      'art': ['museums', 'creative projects', 'design'],
    };

    for (final interest in dna.interests) {
      final lower = interest.toLowerCase();
      for (final entry in complementaryMap.entries) {
        if (lower.contains(entry.key)) {
          for (final suggestion in entry.value) {
            if (!dna.interests.any((i) => i.toLowerCase().contains(suggestion))) {
              interestRecs.add(TraitSuggestion(
                trait: _capitalize(suggestion),
                reason: 'People who love ${_capitalize(entry.key)} often also enjoy this — and it makes you more discoverable',
                confidence: 0.7,
                category: 'complementary_interest',
              ));
            }
          }
        }
      }
    }

    // ── Gap analysis ──

    if (dna.interests.isEmpty) {
      gapAnalysis.add(GapInsight(
        type: 'missing',
        observation: 'No interests listed — your profile is invisible to people searching by shared interests. Even 3-5 interests dramatically improves discoverability.',
      ));
    } else if (dna.interests.length < 3) {
      gapAnalysis.add(GapInsight(
        type: 'thin',
        observation: 'Only ${dna.interests.length} interest${dna.interests.length == 1 ? "" : "s"} — profiles with 5+ interests get substantially more matches. You\'re leaving connections on the table.',
      ));
    }

    if (dna.traits.length < 5) {
      gapAnalysis.add(GapInsight(
        type: 'thin',
        observation: 'Only ${dna.traits.length} personality traits selected. More traits = richer matching = people who actually get you.',
      ));
    }

    // Deduplicate
    final seen = <String>{};
    personalityRecs.removeWhere((r) => !seen.add(r.trait));
    interestRecs.removeWhere((r) => !seen.add(r.trait));

    return TraitRecommendations(
      personalityTraits: personalityRecs.take(4).toList(),
      interestSuggestions: interestRecs.take(6).toList(),
      discoveryTraits: [],
      gapAnalysis: gapAnalysis,
      profileStrategies: [],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI-ENHANCED RECOMMENDATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<TraitRecommendations?> _generateAIRecommendations(
    UserDNA dna,
    TraitRecommendations localRecs,
  ) async {
    final contextBrief = dna.toContextBrief();

    final systemPrompt = '''You are a dating profile optimization expert for Vespara, an exclusive adult social app.

Your job: Suggest traits and interests that will help this specific person find MORE and BETTER matches.

STRATEGY:
1. Suggest traits that authentically reflect who they are (based on their full profile)
2. Suggest interests that complement their existing ones
3. Suggest "discovery" traits — things that would help them attract their ideal match
4. Identify gaps in their profile that hurt discoverability

AVAILABLE TRAIT CATEGORIES:
- Energy: Night Owl, Early Riser, High Energy, Calm & Centered, Selectively Social
- Social Style: Life of the Party, Homebody, Social Chameleon, One-on-One Preferred
- Vibe: Witty, Romantic, Mischievous, Passionate, Mysterious
- In The Bedroom: Dominant, Submissive, Switch, Roleplay, Rough, Gentle & Sensual, Bondage, Exhibitionist, Voyeur, Group, Oral Focused, Toy Friendly, Tantric, Sensory Play, Edge Play, Impact Play
- Turn Ons: Intelligence, Confidence, Humor, Ambition, Kindness, Assertiveness, Creativity, Voice, Hands, Eyes, Tattoos, Scent, Accents, Power
- Experience: Curious Beginner, Learning & Growing, Comfortable, Experienced, Very Experienced

Their current traits: ${dna.traits.join(', ')}
Their current interests: ${dna.interests.join(', ')}

OUTPUT FORMAT (valid JSON):
{
  "personality_traits": [
    {"trait": "exact trait name", "reason": "why this fits them specifically", "confidence": 0.8}
  ],
  "interest_suggestions": [
    {"trait": "interest name", "reason": "why this complements their profile", "confidence": 0.7}
  ],
  "profile_strategies": [
    "Strategic advice about their overall trait/interest combination"
  ]
}

Suggest 3-5 personality traits and 3-5 interests. Only suggest traits NOT already in their profile.''';

    final result = await _aiService.chat(
      systemPrompt: systemPrompt,
      prompt: '''Full user DNA:\n\n$contextBrief''',
      model: AIModel.gpt4oMini,
      temperature: 0.7,
      maxTokens: 600,
    );

    return result.fold(
      onSuccess: (response) {
        try {
          final json = jsonDecode(_extractJson(response.content)) as Map<String, dynamic>;

          return TraitRecommendations(
            personalityTraits: (json['personality_traits'] as List?)
                    ?.map((t) => TraitSuggestion(
                          trait: t['trait'] as String,
                          reason: t['reason'] as String,
                          confidence: (t['confidence'] as num?)?.toDouble() ?? 0.7,
                          category: 'ai_recommended',
                        ))
                    .toList() ??
                localRecs.personalityTraits,
            interestSuggestions: (json['interest_suggestions'] as List?)
                    ?.map((t) => TraitSuggestion(
                          trait: t['trait'] as String,
                          reason: t['reason'] as String,
                          confidence: (t['confidence'] as num?)?.toDouble() ?? 0.7,
                          category: 'ai_recommended',
                        ))
                    .toList() ??
                localRecs.interestSuggestions,
            discoveryTraits: [],
            gapAnalysis: localRecs.gapAnalysis,
            profileStrategies: List<String>.from(json['profile_strategies'] ?? []),
          );
        } catch (e) {
          debugPrint('SmartTraitRecommender: Failed to parse AI response - $e');
          return null;
        }
      },
      onFailure: (_) => null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCOVERY RECOMMENDATIONS - From Match Pool Data
  // ═══════════════════════════════════════════════════════════════════════════

  /// Suggest traits/interests that the user's ideal matches tend to have
  /// or look for. This increases discoverability to compatible people.
  Future<List<TraitSuggestion>> _generateDiscoveryRecommendations(
    UserDNA dna,
  ) async {
    final discoveries = <TraitSuggestion>[];

    try {
      // Find what traits people who match with similar profiles tend to have
      final popularTraits = await _supabase.rpc(
        'get_popular_interests',
        params: {'p_limit': 30},
      ).catchError((_) => <dynamic>[]);

      final currentInterests = dna.interests.map((i) => i.toLowerCase()).toSet();
      final currentTraits = dna.traits.map((t) => t.toLowerCase()).toSet();

      // Score each popular trait by relevance to this user's profile
      for (final item in (popularTraits as List)) {
        final trait = item.toString();
        final traitLower = trait.toLowerCase();

        if (currentInterests.contains(traitLower) ||
            currentTraits.contains(traitLower)) {
          continue; // Already has it
        }

        // Score relevance based on profile
        double relevance = 0;

        // Boost if it matches their energy
        if (dna.socialEnergyProfile.contains('social') &&
            _isSocialTrait(traitLower)) relevance += 0.3;
        if (dna.socialEnergyProfile.contains('introvert') &&
            _isIntrovertTrait(traitLower)) relevance += 0.3;

        // Boost if complementary to existing interests
        if (_isComplementary(traitLower, dna.interests)) relevance += 0.25;

        if (relevance > 0.2) {
          discoveries.add(TraitSuggestion(
            trait: _capitalize(trait),
            reason: 'Popular among profiles similar to yours — adding increases your visibility',
            confidence: relevance,
            category: 'discovery',
          ));
        }
      }

      discoveries.sort((a, b) => b.confidence.compareTo(a.confidence));
      return discoveries.take(4).toList();
    } catch (e) {
      return [];
    }
  }

  bool _isSocialTrait(String trait) {
    return trait.contains('party') || trait.contains('social') ||
        trait.contains('concert') || trait.contains('networking') ||
        trait.contains('dancing');
  }

  bool _isIntrovertTrait(String trait) {
    return trait.contains('reading') || trait.contains('homebody') ||
        trait.contains('writing') || trait.contains('meditation') ||
        trait.contains('art');
  }

  bool _isComplementary(String candidate, List<String> existing) {
    final pairs = {
      'cooking': ['wine', 'travel', 'food'],
      'fitness': ['yoga', 'hiking', 'nutrition'],
      'music': ['dancing', 'concert', 'festival'],
      'photography': ['travel', 'nature', 'art'],
    };
    
    for (final interest in existing) {
      for (final entry in pairs.entries) {
        if (interest.toLowerCase().contains(entry.key) &&
            entry.value.any((v) => candidate.contains(v))) {
          return true;
        }
      }
    }
    return false;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  String _extractJson(String content) {
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      return content.substring(jsonStart, jsonEnd + 1);
    }
    return content;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class TraitRecommendations {
  TraitRecommendations({
    required this.personalityTraits,
    required this.interestSuggestions,
    required this.discoveryTraits,
    required this.gapAnalysis,
    required this.profileStrategies,
  });

  factory TraitRecommendations.empty() => TraitRecommendations(
        personalityTraits: [],
        interestSuggestions: [],
        discoveryTraits: [],
        gapAnalysis: [],
        profileStrategies: [],
      );

  final List<TraitSuggestion> personalityTraits;
  final List<TraitSuggestion> interestSuggestions;
  final List<TraitSuggestion> discoveryTraits;
  final List<GapInsight> gapAnalysis;
  final List<String> profileStrategies;

  bool get isEmpty =>
      personalityTraits.isEmpty &&
      interestSuggestions.isEmpty &&
      discoveryTraits.isEmpty;

  List<TraitSuggestion> get allSuggestions => [
        ...personalityTraits,
        ...interestSuggestions,
        ...discoveryTraits,
      ];
}

class TraitSuggestion {
  TraitSuggestion({
    required this.trait,
    required this.reason,
    required this.confidence,
    required this.category,
  });

  final String trait;
  final String reason; // Personalized explanation of WHY
  final double confidence; // 0-1
  final String category; // communication_match, energy_match, etc.
}

class GapInsight {
  GapInsight({
    required this.type,
    required this.observation,
  });

  final String type; // missing, thin, misalignment
  final String observation;
}
