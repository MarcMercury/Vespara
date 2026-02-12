import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';
import 'user_dna_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DEEP CONNECTION ENGINE - Psychology-Driven Compatibility Scoring
/// ════════════════════════════════════════════════════════════════════════════
///
/// Upgrades the PredictiveMatchingEngine with multi-dimensional scoring:
///
/// OLD approach: Count shared interests + simple keyword matching
///   → "You both like hiking" (cool, but shallow)
///
/// NEW approach: Score across 8 psychological dimensions
///   → Attachment compatibility (secure + anxious = workable, avoidant + anxious = trouble)
///   → Communication harmony (jokester + deep_diver = complementary spark)
///   → Intimacy alignment (power dynamics, heat level, experience gap)
///   → Social energy fit (introvert + extrovert tension/balance)
///   → Lifestyle rhythm (scheduling, availability, bandwidth overlap)
///   → Intention alignment (are they seeking the same thing?)
///   → Values resonance (hard limits alignment, boundaries compatibility)
///   → Growth potential (how much they could learn/experience together)
///
/// Each dimension produces a score AND a human-readable insight.

class DeepConnectionEngine {
  DeepConnectionEngine._();
  static DeepConnectionEngine? _instance;
  static DeepConnectionEngine get instance =>
      _instance ??= DeepConnectionEngine._();

  final AIService _aiService = AIService.instance;
  final UserDNAService _dnaService = UserDNAService.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // DEEP COMPATIBILITY SCORING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Score compatibility across all psychological dimensions.
  /// Returns both a score and rich human-readable insights.
  Future<DeepCompatibility> scoreCompatibility({
    required String userId1,
    required String userId2,
  }) async {
    final dna1 = await _dnaService.buildUserDNA(userId: userId1);
    final dna2 = await _dnaService.buildUserDNA(userId: userId2);

    if (dna1 == null || dna2 == null) {
      return DeepCompatibility.unknown();
    }

    // Score all dimensions
    final dimensions = <CompatibilityDimension>[
      _scoreAttachmentCompatibility(dna1, dna2),
      _scoreCommunicationHarmony(dna1, dna2),
      _scoreIntimacyAlignment(dna1, dna2),
      _scoreSocialEnergyFit(dna1, dna2),
      _scoreLifestyleRhythm(dna1, dna2),
      _scoreIntentionAlignment(dna1, dna2),
      _scoreValuesResonance(dna1, dna2),
      _scoreGrowthPotential(dna1, dna2),
    ];

    // Calculate weighted overall score
    final overallScore = _calculateWeightedScore(dimensions);

    // Generate chemistry prediction
    final chemistryType = _predictChemistryType(dna1, dna2, dimensions);

    // Build the "why you'd click" narrative
    final narrative = _buildConnectionNarrative(dna1, dna2, dimensions);

    // Generate conversation starter suggestions
    final conversationAngles = _suggestConversationAngles(dna1, dna2, dimensions);

    return DeepCompatibility(
      overallScore: overallScore,
      dimensions: dimensions,
      chemistryType: chemistryType,
      narrative: narrative,
      conversationAngles: conversationAngles,
      topStrengths: _getTopStrengths(dimensions),
      potentialFrictions: _getPotentialFrictions(dimensions),
    );
  }

  /// Rank multiple candidates with deep scoring
  Future<List<DeepRankedMatch>> rankCandidates({
    required String userId,
    required List<String> candidateIds,
    int topN = 20,
  }) async {
    final rankings = <DeepRankedMatch>[];

    for (final candidateId in candidateIds) {
      final compatibility = await scoreCompatibility(
        userId1: userId,
        userId2: candidateId,
      );

      rankings.add(DeepRankedMatch(
        candidateId: candidateId,
        compatibility: compatibility,
      ));
    }

    // Sort by overall score
    rankings.sort(
        (a, b) => b.compatibility.overallScore.compareTo(a.compatibility.overallScore));

    return rankings.take(topN).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIMENSION SCORERS
  // ═══════════════════════════════════════════════════════════════════════════

  CompatibilityDimension _scoreAttachmentCompatibility(UserDNA a, UserDNA b) {
    double score = 0.5;
    String insight = '';

    final combo = '${a.attachmentStyle}_${b.attachmentStyle}';

    // Attachment theory compatibility matrix
    switch (combo) {
      case 'secure_secure':
        score = 0.95;
        insight = 'Both emotionally grounded — this is the gold standard for stable connection';
        break;
      case 'secure_anxious':
      case 'anxious_secure':
        score = 0.75;
        insight = 'The secure partner can help the anxious partner feel safe — growth potential here';
        break;
      case 'secure_avoidant':
      case 'avoidant_secure':
        score = 0.70;
        insight = 'Secure can gently draw out the avoidant — requires patience but can work beautifully';
        break;
      case 'anxious_avoidant':
      case 'avoidant_anxious':
        score = 0.30;
        insight = 'Classic push-pull dynamic — exciting but often painful. Proceed with self-awareness';
        break;
      case 'anxious_anxious':
        score = 0.50;
        insight = 'Intense mutual connection but may amplify insecurities. Communication is key';
        break;
      case 'avoidant_avoidant':
        score = 0.40;
        insight = 'Both value independence — might struggle to deepen unless consciously choosing vulnerability';
        break;
      default:
        score = 0.5;
        insight = 'Not enough data to assess emotional compatibility yet';
    }

    return CompatibilityDimension(
      name: 'Emotional Wiring',
      score: score,
      weight: 0.18,
      insight: insight,
      icon: '🧠',
    );
  }

  CompatibilityDimension _scoreCommunicationHarmony(UserDNA a, UserDNA b) {
    double score = 0.5;
    String insight = '';

    final combo = '${a.communicationArchetype}_${b.communicationArchetype}';

    // Communication compatibility — some combos create magic
    final perfectComplementary = {
      'jokester_deep_diver', 'deep_diver_jokester', // Humor + depth
      'storyteller_curious_explorer', 'curious_explorer_storyteller', // Stories + questions
      'rapid_fire_rapid_fire', // High energy match
    };

    final goodMatch = {
      'jokester_jokester', // Comedy duo
      'deep_diver_deep_diver', // Philosophy corner
      'storyteller_storyteller', // Never-ending conversation
      'slow_burner_deep_diver', 'deep_diver_slow_burner', // Patient depth
      'curious_explorer_deep_diver', 'deep_diver_curious_explorer',
    };

    final tensionCombo = {
      'rapid_fire_slow_burner', 'slow_burner_rapid_fire', // Pacing mismatch
      'jokester_slow_burner', 'slow_burner_jokester', // Energy mismatch
    };

    if (perfectComplementary.contains(combo)) {
      score = 0.9;
      insight = 'Your communication styles create spark — ${_humanizeArchetype(a.communicationArchetype)} + ${_humanizeArchetype(b.communicationArchetype)} is conversation gold';
    } else if (goodMatch.contains(combo)) {
      score = 0.75;
      insight = 'Similar communication wavelength — conversations should flow naturally';
    } else if (tensionCombo.contains(combo)) {
      score = 0.4;
      insight = 'Different communication pacing — one of you writes novels, the other sends rapid-fire texts. Can work with awareness';
    } else if (a.communicationArchetype == b.communicationArchetype) {
      score = 0.7;
      insight = 'Matching communication style — you\'ll "get" each other instantly';
    } else {
      score = 0.55;
      insight = 'Different but compatible communication styles — brings variety to conversations';
    }

    return CompatibilityDimension(
      name: 'Conversation Chemistry',
      score: score,
      weight: 0.15,
      insight: insight,
      icon: '💬',
    );
  }

  CompatibilityDimension _scoreIntimacyAlignment(UserDNA a, UserDNA b) {
    double score = 0.5;
    String insight = '';

    // Heat level compatibility
    final heatOrder = {'mild': 1, 'medium': 2, 'hot': 3, 'nuclear': 4};
    final heatA = heatOrder[a.heatLevel] ?? 2;
    final heatB = heatOrder[b.heatLevel] ?? 2;
    final heatDiff = (heatA - heatB).abs();

    if (heatDiff == 0) {
      score += 0.3;
    } else if (heatDiff == 1) {
      score += 0.2;
    } else if (heatDiff >= 3) {
      score -= 0.15;
    }

    // Power dynamic compatibility
    final hasDomA = a.traits.any((t) => t.contains('Dominant'));
    final hasSubA = a.traits.any((t) => t.contains('Submissive'));
    final hasSwitchA = a.traits.any((t) => t.contains('Switch'));
    final hasDomB = b.traits.any((t) => t.contains('Dominant'));
    final hasSubB = b.traits.any((t) => t.contains('Submissive'));
    final hasSwitchB = b.traits.any((t) => t.contains('Switch'));

    // D/s complementary pairing = high score
    if ((hasDomA && hasSubB) || (hasSubA && hasDomB)) {
      score += 0.25;
    }
    // Switch + anything = flexible = good
    if (hasSwitchA || hasSwitchB) {
      score += 0.15;
    }
    // Both dominant without switch = tension
    if (hasDomA && hasDomB && !hasSwitchA && !hasSwitchB) {
      score -= 0.1;
    }

    // Intimacy blueprint compatibility
    if (a.intimacyBlueprint == b.intimacyBlueprint) {
      score += 0.15;
    }

    // Experience level gap
    final expA = a.traits.any((t) => t.contains('Very Experienced') || t.contains('Experienced'))
        ? 'experienced'
        : a.traits.any((t) => t.contains('Beginner') || t.contains('Curious'))
            ? 'beginner'
            : 'moderate';
    final expB = b.traits.any((t) => t.contains('Very Experienced') || t.contains('Experienced'))
        ? 'experienced'
        : b.traits.any((t) => t.contains('Beginner') || t.contains('Curious'))
            ? 'beginner'
            : 'moderate';

    // Teacher + student dynamic can be great
    if ((expA == 'experienced' && expB == 'beginner') ||
        (expA == 'beginner' && expB == 'experienced')) {
      if (a.traits.any((t) => t.contains('Teach')) || b.traits.any((t) => t.contains('Teach'))) {
        score += 0.1;
      }
    }

    // Hard limits compatibility — any of A's desires in B's hard limits = problem
    final aDesireTraits = a.traits.map((t) => t.toLowerCase()).toSet();
    final bLimits = b.hardLimits.map((l) => l.toLowerCase()).toSet();
    final aLimits = a.hardLimits.map((l) => l.toLowerCase()).toSet();
    final bDesireTraits = b.traits.map((t) => t.toLowerCase()).toSet();

    // Check for deal-breaking conflicts
    bool hasConflict = false;
    for (final limit in [...bLimits, ...aLimits]) {
      if (limit.contains('pain') && 
          (aDesireTraits.contains('rough') || bDesireTraits.contains('rough') ||
           aDesireTraits.contains('impact play') || bDesireTraits.contains('impact play'))) {
        hasConflict = true;
      }
    }
    if (hasConflict) score -= 0.15;

    score = score.clamp(0.0, 1.0);

    // Generate insight
    if (score >= 0.8) {
      insight = 'Strong intimacy alignment — you\'re on the same wavelength about desire and boundaries';
    } else if (score >= 0.6) {
      insight = heatDiff <= 1
          ? 'Compatible heat levels with room to explore together'
          : 'Some heat level difference — but boundaries and communication can bridge it';
    } else if (score >= 0.4) {
      insight = 'Different intimacy preferences — could be exciting or frustrating depending on communication';
    } else {
      insight = 'Significant intimacy mismatch — honest early conversations are essential here';
    }

    return CompatibilityDimension(
      name: 'Intimacy Alignment',
      score: score,
      weight: 0.18,
      insight: insight,
      icon: '🔥',
    );
  }

  CompatibilityDimension _scoreSocialEnergyFit(UserDNA a, UserDNA b) {
    double score = 0.5;
    String insight = '';

    final energyA = a.socialEnergyProfile;
    final energyB = b.socialEnergyProfile;

    // Same energy = easy
    if (energyA == energyB) {
      score = 0.85;
      insight = 'Matched social energy — you\'ll naturally want the same things on a Friday night';
    }
    // Balanced + anything = flexible
    else if (energyA == 'balanced_ambivert' || energyB == 'balanced_ambivert') {
      score = 0.7;
      insight = 'One of you is adaptable — can shift between quiet nights and social events';
    }
    // High energy + selective introvert = classic tension
    else if ((energyA == 'high_energy_social' && energyB.contains('introvert')) ||
             (energyB == 'high_energy_social' && energyA.contains('introvert'))) {
      score = 0.35;
      insight = 'Major social energy gap — one wants the party, the other wants the couch. Works only with explicit compromise';
    }
    // Moderate differences
    else {
      score = 0.55;
      insight = 'Different social appetites — could balance each other or create friction';
    }

    return CompatibilityDimension(
      name: 'Social Energy',
      score: score,
      weight: 0.10,
      insight: insight,
      icon: '⚡',
    );
  }

  CompatibilityDimension _scoreLifestyleRhythm(UserDNA a, UserDNA b) {
    double score = 0.5;
    String insight = '';

    // Availability overlap
    final sharedAvail = a.availability
        .toSet()
        .intersection(b.availability.toSet());
    final availOverlap = (a.availability.isEmpty || b.availability.isEmpty)
        ? 0.5 // Unknown
        : sharedAvail.length /
            max(1, a.availability.toSet().union(b.availability.toSet()).length);
    score = 0.3 + (availOverlap * 0.3);

    // Scheduling style compatibility
    if (a.schedulingStyle == b.schedulingStyle) {
      score += 0.1;
    } else if ((a.schedulingStyle == 'spontaneous' && b.schedulingStyle == 'advance_planning') ||
               (a.schedulingStyle == 'advance_planning' && b.schedulingStyle == 'spontaneous')) {
      score -= 0.05; // Minor tension
    }

    // Bandwidth compatibility
    final bandwidthDiff = (a.bandwidth - b.bandwidth).abs();
    if (bandwidthDiff < 0.2) {
      score += 0.1;
    } else if (bandwidthDiff > 0.5) {
      score -= 0.1;
    }

    // Location proximity (same city = bonus)
    if (a.city != null && b.city != null && a.city == b.city) {
      score += 0.1;
    }

    score = score.clamp(0.0, 1.0);

    if (score >= 0.7) {
      insight = 'Your schedules and lifestyles sync well — actually meeting up should be easy';
    } else if (score >= 0.5) {
      insight = 'Some logistics overlap — you can make it work with a little planning';
    } else {
      insight = 'Different life rhythms — connecting will require intentional effort';
    }

    return CompatibilityDimension(
      name: 'Lifestyle Rhythm',
      score: score,
      weight: 0.12,
      insight: insight,
      icon: '🕐',
    );
  }

  CompatibilityDimension _scoreIntentionAlignment(UserDNA a, UserDNA b) {
    double score = 0.5;
    String insight = '';

    final seekingA = a.seeking.map((s) => s.toLowerCase()).toSet();
    final seekingB = b.seeking.map((s) => s.toLowerCase()).toSet();

    final shared = seekingA.intersection(seekingB);
    final total = seekingA.union(seekingB);

    if (shared.isEmpty && total.isNotEmpty) {
      score = 0.2;
      insight = 'Looking for fundamentally different things — proceed with clear expectations';
    } else if (shared.length == total.length) {
      score = 0.95;
      insight = 'Looking for exactly the same things — rare alignment';
    } else if (shared.isNotEmpty) {
      score = 0.5 + (shared.length / total.length * 0.4);
      insight = 'Some overlap in what you\'re seeking — enough common ground to explore';
    }

    // Relationship status compatibility
    final statusA = a.relationshipStatus.map((s) => s.toLowerCase()).toSet();
    final statusB = b.relationshipStatus.map((s) => s.toLowerCase()).toSet();
    if (statusA.isNotEmpty && statusB.isNotEmpty) {
      // Both single or both non-monogamous = boost
      final bothSingle = statusA.contains('single') && statusB.contains('single');
      final bothOpen = (statusA.any((s) => s.contains('open') || s.contains('poly')) &&
                        statusB.any((s) => s.contains('open') || s.contains('poly')));
      if (bothSingle || bothOpen) score += 0.05;
    }

    score = score.clamp(0.0, 1.0);

    return CompatibilityDimension(
      name: 'Intention Match',
      score: score,
      weight: 0.15,
      insight: insight,
      icon: '🎯',
    );
  }

  CompatibilityDimension _scoreValuesResonance(UserDNA a, UserDNA b) {
    double score = 0.5;

    // Hard limits alignment (shared limits = shared values)
    final limitsA = a.hardLimits.map((l) => l.toLowerCase()).toSet();
    final limitsB = b.hardLimits.map((l) => l.toLowerCase()).toSet();
    final sharedLimits = limitsA.intersection(limitsB);

    if (limitsA.isNotEmpty && limitsB.isNotEmpty) {
      final overlapRatio = sharedLimits.length /
          max(1, limitsA.union(limitsB).length);
      score += overlapRatio * 0.25;
    }

    // Discretion level alignment
    if (a.discretionLevel == b.discretionLevel) {
      score += 0.1;
    } else if ((a.discretionLevel == 'very_discreet' && b.discretionLevel == 'open') ||
               (a.discretionLevel == 'open' && b.discretionLevel == 'very_discreet')) {
      score -= 0.15; // Major values clash
    }

    // Risk tolerance alignment
    final riskDiff = (a.riskTolerance - b.riskTolerance).abs();
    if (riskDiff < 0.2) {
      score += 0.1;
    } else if (riskDiff > 0.4) {
      score -= 0.1;
    }

    score = score.clamp(0.0, 1.0);

    String insight;
    if (score >= 0.7) {
      insight = 'Aligned on boundaries and values — a strong foundation for trust';
    } else if (score >= 0.5) {
      insight = 'Compatible core values with some differences in boundaries — discuss early';
    } else {
      insight = 'Different approaches to boundaries and privacy — requires careful navigation';
    }

    return CompatibilityDimension(
      name: 'Values & Boundaries',
      score: score,
      weight: 0.07,
      insight: insight,
      icon: '🛡️',
    );
  }

  CompatibilityDimension _scoreGrowthPotential(UserDNA a, UserDNA b) {
    double score = 0.5;

    // Different interests = learning opportunities
    final interestsA = a.interests.map((i) => i.toLowerCase()).toSet();
    final interestsB = b.interests.map((i) => i.toLowerCase()).toSet();
    final uniqueA = interestsA.difference(interestsB);
    final uniqueB = interestsB.difference(interestsA);
    final uniqueTotal = uniqueA.length + uniqueB.length;

    if (uniqueTotal >= 4) {
      score += 0.15; // Lots to teach each other
    }

    // Complementary communication styles = growth
    if (a.communicationArchetype != b.communicationArchetype) {
      score += 0.1;
    }

    // Experience gap that can be bridged
    final isTeacherStudent = (a.traits.any((t) => t.contains('Experienced')) &&
            b.traits.any((t) => t.contains('Beginner'))) ||
        (b.traits.any((t) => t.contains('Experienced')) &&
            a.traits.any((t) => t.contains('Beginner')));
    if (isTeacherStudent) {
      score += 0.15;
    }

    // Different social energy = broadens horizon
    if (a.socialEnergyProfile != b.socialEnergyProfile) {
      score += 0.05;
    }

    score = score.clamp(0.0, 1.0);

    String insight;
    if (score >= 0.7) {
      insight = 'High growth potential — you\'d expand each other\'s worlds through new interests and perspectives';
    } else if (score >= 0.5) {
      insight = 'Moderate growth potential — some new things to discover together';
    } else {
      insight = 'Similar worlds — comfort zone match, less exploratory';
    }

    return CompatibilityDimension(
      name: 'Growth Potential',
      score: score,
      weight: 0.05,
      insight: insight,
      icon: '🌱',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNTHESIS
  // ═══════════════════════════════════════════════════════════════════════════

  double _calculateWeightedScore(List<CompatibilityDimension> dimensions) {
    double totalWeight = 0;
    double weightedSum = 0;

    for (final dim in dimensions) {
      weightedSum += dim.score * dim.weight;
      totalWeight += dim.weight;
    }

    return totalWeight > 0 ? (weightedSum / totalWeight).clamp(0.0, 1.0) : 0.5;
  }

  String _predictChemistryType(
    UserDNA a,
    UserDNA b,
    List<CompatibilityDimension> dimensions,
  ) {
    final intimacy = dimensions.firstWhere((d) => d.name == 'Intimacy Alignment',
        orElse: () => CompatibilityDimension(name: '', score: 0.5, weight: 0, insight: '', icon: ''));
    final conversation = dimensions.firstWhere((d) => d.name == 'Conversation Chemistry',
        orElse: () => CompatibilityDimension(name: '', score: 0.5, weight: 0, insight: '', icon: ''));
    final emotional = dimensions.firstWhere((d) => d.name == 'Emotional Wiring',
        orElse: () => CompatibilityDimension(name: '', score: 0.5, weight: 0, insight: '', icon: ''));

    if (intimacy.score > 0.8 && conversation.score > 0.7) return 'Electric Connection';
    if (emotional.score > 0.8 && conversation.score > 0.7) return 'Soul Connection';
    if (intimacy.score > 0.7 && emotional.score < 0.5) return 'Physical Chemistry';
    if (conversation.score > 0.8 && emotional.score > 0.6) return 'Intellectual Spark';
    if (emotional.score > 0.7 && intimacy.score < 0.5) return 'Emotional Anchor';
    return 'Worth Exploring';
  }

  String _buildConnectionNarrative(
    UserDNA a,
    UserDNA b,
    List<CompatibilityDimension> dimensions,
  ) {
    final sorted = List.of(dimensions)..sort((x, y) => y.score.compareTo(x.score));
    final strongest = sorted.first;
    final secondStrong = sorted.length > 1 ? sorted[1] : null;

    final parts = <String>[];
    parts.add('Strongest connection point: ${strongest.name} (${(strongest.score * 100).toInt()}%)');
    parts.add(strongest.insight);

    if (secondStrong != null && secondStrong.score > 0.6) {
      parts.add('Also strong in ${secondStrong.name}: ${secondStrong.insight}');
    }

    // Find friction points
    final weakest = sorted.last;
    if (weakest.score < 0.4) {
      parts.add('Watch out for: ${weakest.name} — ${weakest.insight}');
    }

    return parts.join('\n');
  }

  List<String> _suggestConversationAngles(
    UserDNA a,
    UserDNA b,
    List<CompatibilityDimension> dimensions,
  ) {
    final angles = <String>[];

    // Shared interests
    final sharedInterests = a.interests
        .map((i) => i.toLowerCase())
        .toSet()
        .intersection(b.interests.map((i) => i.toLowerCase()).toSet());
    for (final interest in sharedInterests.take(2)) {
      angles.add('You both love $interest — great opener territory');
    }

    // Complementary traits
    if (a.communicationArchetype == 'jokester' &&
        b.communicationArchetype == 'deep_diver') {
      angles.add('Open with humor to hook them, then go deep — they\'ll love the shift');
    }

    // Shared seeking
    final sharedSeeking = a.seeking
        .map((s) => s.toLowerCase())
        .toSet()
        .intersection(b.seeking.map((s) => s.toLowerCase()).toSet());
    if (sharedSeeking.isNotEmpty) {
      angles.add('Both looking for ${sharedSeeking.first} — directness will be appreciated');
    }

    if (angles.isEmpty) {
      angles.add('Lead with genuine curiosity about something specific in their profile');
    }

    return angles.take(3).toList();
  }

  List<String> _getTopStrengths(List<CompatibilityDimension> dimensions) {
    return dimensions
        .where((d) => d.score >= 0.7)
        .map((d) => '${d.icon} ${d.name}: ${d.insight}')
        .take(3)
        .toList();
  }

  List<String> _getPotentialFrictions(List<CompatibilityDimension> dimensions) {
    return dimensions
        .where((d) => d.score < 0.4)
        .map((d) => '${d.icon} ${d.name}: ${d.insight}')
        .take(2)
        .toList();
  }

  String _humanizeArchetype(String archetype) {
    switch (archetype) {
      case 'jokester': return 'the witty one';
      case 'deep_diver': return 'the deep thinker';
      case 'storyteller': return 'the storyteller';
      case 'rapid_fire': return 'the energizer';
      case 'curious_explorer': return 'the curious soul';
      case 'slow_burner': return 'the slow burn';
      default: return archetype.replaceAll('_', ' ');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI-ENHANCED INSIGHTS (Optional, for premium/detailed view)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a rich AI narrative about why two people might click.
  /// Used for the detailed match insight view.
  Future<String?> generateConnectionStory({
    required String userId1,
    required String userId2,
  }) async {
    final pairContext = await _dnaService.buildPairContext(
      userId1: userId1,
      userId2: userId2,
    );

    final result = await _aiService.chat(
      systemPrompt: '''You are a relationship psychologist for Vespara, an exclusive adult social app.

Write a 3-4 sentence insight about why these two people might click — or might not.
Be specific to their profiles. Don't be generic. Be warm but honest.
If they're a great match, explain the specific chemistry.
If they're a challenging match, explain what would need to work for them to connect.
Don't use names — say "you" and "they".''',
      prompt: pairContext,
      model: AIModel.gpt4oMini,
      temperature: 0.75,
      maxTokens: 200,
    );

    return result.fold(
      onSuccess: (response) => response.content.trim(),
      onFailure: (_) => null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class CompatibilityDimension {
  CompatibilityDimension({
    required this.name,
    required this.score,
    required this.weight,
    required this.insight,
    required this.icon,
  });

  final String name;
  final double score; // 0-1
  final double weight; // Weight in overall calculation
  final String insight; // Human-readable explanation
  final String icon;

  String get scoreLabel {
    if (score >= 0.8) return 'Strong';
    if (score >= 0.6) return 'Good';
    if (score >= 0.4) return 'Moderate';
    return 'Low';
  }
}

class DeepCompatibility {
  DeepCompatibility({
    required this.overallScore,
    required this.dimensions,
    required this.chemistryType,
    required this.narrative,
    required this.conversationAngles,
    required this.topStrengths,
    required this.potentialFrictions,
  });

  factory DeepCompatibility.unknown() => DeepCompatibility(
        overallScore: 0.5,
        dimensions: [],
        chemistryType: 'Unknown',
        narrative: 'Not enough data to analyze compatibility yet.',
        conversationAngles: ['Start with something you both enjoy — interests are a great opener'],
        topStrengths: [],
        potentialFrictions: [],
      );

  final double overallScore;
  final List<CompatibilityDimension> dimensions;
  final String chemistryType;
  final String narrative;
  final List<String> conversationAngles;
  final List<String> topStrengths;
  final List<String> potentialFrictions;

  String get overallLabel {
    if (overallScore >= 0.8) return 'Exceptional Match';
    if (overallScore >= 0.65) return 'Strong Compatibility';
    if (overallScore >= 0.5) return 'Good Potential';
    if (overallScore >= 0.35) return 'Worth Exploring';
    return 'Different Worlds';
  }

  String get overallEmoji {
    if (overallScore >= 0.8) return '🔥';
    if (overallScore >= 0.65) return '⭐';
    if (overallScore >= 0.5) return '✨';
    if (overallScore >= 0.35) return '💫';
    return '🤔';
  }
}

class DeepRankedMatch {
  DeepRankedMatch({
    required this.candidateId,
    required this.compatibility,
  });

  final String candidateId;
  final DeepCompatibility compatibility;
}
