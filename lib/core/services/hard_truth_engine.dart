import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';
import 'user_dna_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// HARD TRUTH ENGINE - Psychologically Deep Self-Assessment
/// ════════════════════════════════════════════════════════════════════════════
///
/// Replaces the shallow metric-threshold approach ("ghost rate > 50 → you're
/// a ghoster") with a nuanced AI analysis that considers the FULL picture:
///
/// - What they say they want vs. how they actually behave
/// - Patterns they can't see in themselves
/// - Contradiction detection (seeking "deep connection" but ghosts 60%+)
/// - Empathetic but unflinching honesty
/// - Actionable growth recommendations, not just roasts
///
/// The goal: Users should feel like a brutally honest friend who knows them
/// deeply just gave them real talk — not like they read a fortune cookie.

class HardTruthEngine {
  HardTruthEngine._();
  static HardTruthEngine? _instance;
  static HardTruthEngine get instance => _instance ??= HardTruthEngine._();

  final AIService _aiService = AIService.instance;
  final UserDNAService _dnaService = UserDNAService.instance;

  // Cache assessments to avoid regenerating frivolously
  final Map<String, HardTruthAssessment> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiry = const Duration(hours: 6);

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATE FULL ASSESSMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a complete Hard Truth assessment.
  /// This powers the Mirror's "TRUTH" tab.
  Future<HardTruthAssessment?> generateAssessment({
    String? userId,
    bool forceRefresh = false,
  }) async {
    final dna = await _dnaService.buildUserDNA(userId: userId);
    if (dna == null) return null;

    // Check cache
    if (!forceRefresh && _cache.containsKey(dna.userId)) {
      final ts = _cacheTimestamps[dna.userId];
      if (ts != null && DateTime.now().difference(ts) < _cacheExpiry) {
        return _cache[dna.userId];
      }
    }

    // If new user with minimal data, return a partial assessment
    if (dna.isNewUser && !dna.hasBehaviorData) {
      return _generateNewUserAssessment(dna);
    }

    // Generate the full assessment via AI
    final assessment = await _generateAIAssessment(dna);

    if (assessment != null) {
      _cache[dna.userId] = assessment;
      _cacheTimestamps[dna.userId] = DateTime.now();
    }

    return assessment;
  }

  /// Full AI-powered assessment using the complete DNA
  Future<HardTruthAssessment?> _generateAIAssessment(UserDNA dna) async {
    // Step 1: Detect contradictions locally (fast, no API call)
    final contradictions = _detectContradictions(dna);

    // Step 2: Build the AI analysis prompt with full context
    final contextBrief = dna.toContextBrief();

    final systemPrompt = '''You are "The Mirror" — the brutally honest AI dating coach inside Vespara, an exclusive adult social app.

YOUR PERSONALITY:
- Brutally honest but never cruel — like a therapist who moonlights as a stand-up comedian
- You see patterns people miss in themselves
- You're empathetic but unflinching — you care, so you don't sugarcoat
- Use "you" directly — this is personal
- Speak conversationally, not clinically
- Dark humor is fine, meanness is not
- Be specific to THIS person — no generic advice

YOUR TASK: Analyze this person's dating profile AND behavior data to generate a deep, personalized assessment.

DETECTED CONTRADICTIONS IN THEIR PROFILE:
${contradictions.isEmpty ? 'None detected — they seem consistent' : contradictions.map((c) => '- ${c.description}').join('\n')}

OUTPUT FORMAT (valid JSON):
{
  "personality_archetype": "A 2-3 word archetype name (e.g., 'The Selective Romantic', 'The Charming Avoidant')",
  "personality_summary": "3-4 sentences: Who they really are in the dating world. Be specific to their unique combination of traits, behavior, and psychology.",
  "dating_style": "2-3 word dating style (e.g., 'Slow Burn Seducer', 'Connection Collector')",
  "dating_style_description": "2-3 sentences explaining their dating pattern honestly.",
  "blind_spots": ["3-4 things they probably don't realize about their own dating behavior. Be specific and insightful."],
  "strengths": ["3-4 genuine dating strengths based on their profile and behavior. Not flattery — real strengths."],
  "growth_edges": ["3-4 specific, actionable things they could improve. Not generic — tailored to their exact patterns."],
  "contradiction_insights": ["1-3 insights about any contradictions between what they say they want and how they behave. Empty array if none."],
  "brutal_truth_oneliner": "One devastating, specific, memorable sentence that sums up their biggest dating pattern. Should feel like getting called out by someone who KNOWS you.",
  "optimization_advice": "2-3 sentences of the single most impactful thing they could change right now to improve their dating life.",
  "compatibility_prediction": "1-2 sentences about what kind of person they'll likely click with (and why), based on their psychological profile."
}''';

    final result = await _aiService.chat(
      systemPrompt: systemPrompt,
      prompt: '''Analyze this user's complete dating DNA:

$contextBrief

Generate a deeply personalized Hard Truth assessment. Remember: this should feel like only THIS person could receive this specific feedback.''',
      model: AIModel.gpt4o,
      temperature: 0.75,
      maxTokens: 1200,
    );

    return result.fold(
      onSuccess: (response) {
        try {
          // Parse JSON response
          final jsonStr = _extractJson(response.content);
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;

          return HardTruthAssessment(
            personalityArchetype: json['personality_archetype'] as String? ?? 'The Mystery',
            personalitySummary: json['personality_summary'] as String? ?? '',
            datingStyle: json['dating_style'] as String? ?? 'Undefined',
            datingStyleDescription: json['dating_style_description'] as String? ?? '',
            blindSpots: List<String>.from(json['blind_spots'] ?? []),
            strengths: List<String>.from(json['strengths'] ?? []),
            growthEdges: List<String>.from(json['growth_edges'] ?? []),
            contradictionInsights: List<String>.from(json['contradiction_insights'] ?? []),
            brutalTruthOneLiner: json['brutal_truth_oneliner'] as String? ?? '',
            optimizationAdvice: json['optimization_advice'] as String? ?? '',
            compatibilityPrediction: json['compatibility_prediction'] as String? ?? '',
            detectedContradictions: contradictions,
            // Computed scores
            overallScore: _computeOverallScore(dna),
            consistencyScore: _computeConsistencyScore(dna, contradictions),
            effortScore: _computeEffortScore(dna),
            selfAwarenessIndicator: contradictions.isEmpty ? 'high' : 'developing',
            generatedAt: DateTime.now(),
            tokensUsed: response.totalTokens,
          );
        } catch (e) {
          debugPrint('HardTruth: Failed to parse AI response - $e');
          return _generateFallbackAssessment(dna, contradictions);
        }
      },
      onFailure: (_) => _generateFallbackAssessment(dna, contradictions),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTRADICTION DETECTION - The Insight Engine
  // ═══════════════════════════════════════════════════════════════════════════

  /// Detect contradictions between stated desires and actual behavior.
  /// This is the killer feature — people rarely see their own inconsistencies.
  List<ProfileContradiction> _detectContradictions(UserDNA dna) {
    final contradictions = <ProfileContradiction>[];

    // Wants deep connection but ghosts frequently
    if (dna.seeking.any((s) => s.contains('relationship') || s.contains('partner')) &&
        dna.ghostRate > 0.3) {
      contradictions.add(ProfileContradiction(
        category: 'behavior_vs_desire',
        description: 'Seeks deep connections but ghosts ${(dna.ghostRate * 100).toInt()}% of matches',
        severity: dna.ghostRate > 0.5 ? 'high' : 'medium',
        insight: 'You say you want something real, but your disappearing act suggests commitment ambivalence.',
      ));
    }

    // High bandwidth claimed but low response rate
    if (dna.bandwidth > 0.7 && dna.responseRate < 0.3 && dna.hasBehaviorData) {
      contradictions.add(ProfileContradiction(
        category: 'availability_gap',
        description: 'Claims high bandwidth (${(dna.bandwidth * 100).toInt()}%) but responds to only ${(dna.responseRate * 100).toInt()}% of messages',
        severity: 'medium',
        insight: 'Your availability and your actual engagement don\'t match. Either lower expectations or show up more.',
      ));
    }

    // Seeks casual but has secure attachment signals
    if (dna.seeking.every((s) => s.contains('casual') || s.contains('fwb') || s.contains('play')) &&
        dna.attachmentStyle == 'secure' &&
        dna.traits.any((t) => t.contains('Romantic') || t.contains('Intimate'))) {
      contradictions.add(ProfileContradiction(
        category: 'desire_conflict',
        description: 'Profile says casual-only but personality screams relationship-ready',
        severity: 'low',
        insight: 'Nothing wrong with casual — but your trait selections suggest you might want more than you\'re admitting.',
      ));
    }

    // Claims experienced but very limited matches/messages
    if (dna.traits.any((t) => t.contains('Very Experienced') || t.contains('Can Teach')) &&
        dna.hasBehaviorData &&
        dna.totalMatches < 5 &&
        dna.messagesSent < 10) {
      contradictions.add(ProfileContradiction(
        category: 'experience_gap',
        description: 'Selected "experienced" traits but minimal app engagement',
        severity: 'low',
        insight: 'Experience is great — but it doesn\'t help if you\'re not putting yourself out there on the platform.',
      ));
    }

    // High discretion + high heat → interesting tension
    if (dna.discretionLevel == 'very_discreet' &&
        (dna.heatLevel == 'nuclear' || dna.heatLevel == 'hot')) {
      contradictions.add(ProfileContradiction(
        category: 'interesting_tension',
        description: 'Maximum discretion paired with high heat level',
        severity: 'observation',
        insight: 'You want it intense but invisible. That\'s fine — but know that extreme discretion can limit your options. The best connections require some vulnerability.',
      ));
    }

    // Messages sent >> received (or vice versa) imbalance
    if (dna.hasBehaviorData && dna.messagesSent > 0) {
      final ratio = dna.messagesReceived / dna.messagesSent;
      if (ratio < 0.3) {
        contradictions.add(ProfileContradiction(
          category: 'engagement_imbalance',
          description: 'Sends ${dna.messagesSent} messages but only receives ${dna.messagesReceived}',
          severity: 'medium',
          insight: 'You\'re putting in effort but not getting returns. This might be a profile issue, a targeting issue, or a conversation style issue.',
        ));
      } else if (ratio > 3 && dna.responseRate < 0.4) {
        contradictions.add(ProfileContradiction(
          category: 'engagement_imbalance',
          description: 'Gets lots of messages but rarely responds',
          severity: 'medium',
          insight: 'People are interested in you, but you\'re not engaging. Being selective is fine — being avoidant isn\'t.',
        ));
      }
    }

    // Lots of matches but no dates scheduled
    if (dna.totalMatches > 15 && dna.datesScheduled == 0 && dna.hasBehaviorData) {
      contradictions.add(ProfileContradiction(
        category: 'conversion_gap',
        description: '${dna.totalMatches} matches, 0 dates scheduled',
        severity: 'high',
        insight: 'You can get matches but can\'t (or won\'t) move things offline. Are you actually looking to meet people, or is the validation enough?',
      ));
    }

    // Selectively Social + Low bandwidth but many availabilities listed
    if (dna.socialEnergyProfile == 'selective_introvert' &&
        dna.availability.length >= 5) {
      contradictions.add(ProfileContradiction(
        category: 'energy_mismatch',
        description: 'Introverted energy but listed ${dna.availability.length} availabilities',
        severity: 'observation',
        insight: 'You\'re casting a wide availability net for someone who recharges alone. That\'s ambitious — or maybe you\'re overcommitting before you\'ve even matched.',
      ));
    }

    return contradictions;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCORE COMPUTATION
  // ═══════════════════════════════════════════════════════════════════════════

  double _computeOverallScore(UserDNA dna) {
    if (!dna.hasBehaviorData) return -1; // Not enough data
    
    double score = 50;
    
    // Profile quality (0-20 points)
    score += dna.profileCompleteness * 20;
    
    // Engagement quality (0-20 points)
    score += (1 - dna.ghostRate) * 10;
    score += dna.responseRate * 10;

    // Conversion ability (0-10 points)
    if (dna.totalMatches > 0) {
      final conversionRate = dna.datesScheduled / dna.totalMatches;
      score += conversionRate * 10;
    }

    return score.clamp(0, 100);
  }

  double _computeConsistencyScore(UserDNA dna, List<ProfileContradiction> contradictions) {
    double score = 100;
    for (final c in contradictions) {
      switch (c.severity) {
        case 'high':
          score -= 20;
          break;
        case 'medium':
          score -= 12;
          break;
        case 'low':
          score -= 5;
          break;
        default:
          score -= 2;
      }
    }
    return score.clamp(0, 100);
  }

  double _computeEffortScore(UserDNA dna) {
    double score = 0;
    
    // Profile setup effort
    score += dna.profileCompleteness * 30;
    
    // Photo effort
    if (dna.photoCount >= 4) score += 15;
    else if (dna.photoCount >= 2) score += 10;
    else if (dna.photoCount >= 1) score += 5;
    
    // Active engagement
    if (dna.initiatesConversations) score += 10;
    if (dna.messagesSent > 20) score += 10;
    if (dna.datesScheduled > 0) score += 15;
    if (dna.responseRate > 0.6) score += 10;
    
    // Intention clarity
    score += dna.intentionClarity * 10;
    
    return score.clamp(0, 100);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEW USER ASSESSMENT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<HardTruthAssessment> _generateNewUserAssessment(UserDNA dna) async {
    final contradictions = _detectContradictions(dna);

    // For new users, generate a profile-only assessment (no behavior data)
    final systemPrompt = '''You are "The Mirror" — Kult's brutally honest AI connection coach.

This user is NEW — they have minimal behavior data. Analyze their PROFILE SETUP only.

Focus on:
- What their trait/preference selections reveal about them psychologically
- Red flags or strengths in how they've set up their profile
- What kind of person their profile will attract (vs. who they say they want)
- Profile optimization insights

Be honest but encouraging — they just joined. No behavior to critique yet.

OUTPUT FORMAT (valid JSON):
{
  "personality_archetype": "2-3 word archetype from profile alone",
  "personality_summary": "2-3 sentences based on profile setup patterns",
  "dating_style": "Predicted 2-3 word dating style",
  "dating_style_description": "2 sentences predicting their likely pattern",
  "strengths": ["2-3 profile setup strengths"],
  "growth_edges": ["2-3 profile improvement suggestions"],
  "brutal_truth_oneliner": "One observation about what their profile reveals",
  "optimization_advice": "The single most impactful profile change they could make",
  "compatibility_prediction": "Who they'll likely attract based on profile"
}''';

    final result = await _aiService.chat(
      systemPrompt: systemPrompt,
      prompt: '''New user profile DNA:\n\n${dna.toContextBrief()}''',
      model: AIModel.gpt4oMini,
      temperature: 0.75,
      maxTokens: 800,
    );

    return result.fold(
      onSuccess: (response) {
        try {
          final json = jsonDecode(_extractJson(response.content)) as Map<String, dynamic>;
          return HardTruthAssessment(
            personalityArchetype: json['personality_archetype'] as String? ?? 'The Newcomer',
            personalitySummary: json['personality_summary'] as String? ?? '',
            datingStyle: json['dating_style'] as String? ?? 'To Be Determined',
            datingStyleDescription: json['dating_style_description'] as String? ?? '',
            blindSpots: [],
            strengths: List<String>.from(json['strengths'] ?? []),
            growthEdges: List<String>.from(json['growth_edges'] ?? []),
            contradictionInsights: [],
            brutalTruthOneLiner: json['brutal_truth_oneliner'] as String? ?? '',
            optimizationAdvice: json['optimization_advice'] as String? ?? '',
            compatibilityPrediction: json['compatibility_prediction'] as String? ?? '',
            detectedContradictions: contradictions,
            overallScore: -1,
            consistencyScore: _computeConsistencyScore(dna, contradictions),
            effortScore: _computeEffortScore(dna),
            selfAwarenessIndicator: 'new_user',
            generatedAt: DateTime.now(),
            tokensUsed: response.totalTokens,
            isNewUser: true,
          );
        } catch (e) {
          return _generateFallbackAssessment(dna, contradictions);
        }
      },
      onFailure: (_) => _generateFallbackAssessment(dna, contradictions),
    );
  }

  HardTruthAssessment _generateFallbackAssessment(
    UserDNA dna,
    List<ProfileContradiction> contradictions,
  ) {
    return HardTruthAssessment(
      personalityArchetype: _inferArchetype(dna),
      personalitySummary: _buildLocalSummary(dna),
      datingStyle: _inferDatingStyle(dna),
      datingStyleDescription: _buildStyleDescription(dna),
      blindSpots: _inferBlindSpots(dna),
      strengths: _inferStrengths(dna),
      growthEdges: _inferGrowthEdges(dna),
      contradictionInsights: contradictions.map((c) => c.insight).toList(),
      brutalTruthOneLiner: _buildBrutalOneLiner(dna),
      optimizationAdvice: _buildOptimizationAdvice(dna),
      compatibilityPrediction: '',
      detectedContradictions: contradictions,
      overallScore: _computeOverallScore(dna),
      consistencyScore: _computeConsistencyScore(dna, contradictions),
      effortScore: _computeEffortScore(dna),
      selfAwarenessIndicator: 'unknown',
      generatedAt: DateTime.now(),
      tokensUsed: 0,
      isFallback: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCAL INFERENCE (Fallback when AI unavailable)
  // ═══════════════════════════════════════════════════════════════════════════

  String _inferArchetype(UserDNA dna) {
    if (dna.ghostRate > 0.5 && dna.totalMatches > 10) return 'The Phantom';
    if (dna.responseRate > 0.8 && dna.datesScheduled > 0) return 'The Follow-Through';
    if (dna.totalMatches > 20 && dna.datesScheduled == 0) return 'The Collector';
    if (dna.attachmentStyle == 'avoidant' && dna.riskTolerance > 0.6) return 'The Thrill Seeker';
    if (dna.attachmentStyle == 'secure' && dna.intentionClarity > 0.7) return 'The Intentional One';
    if (dna.communicationArchetype == 'deep_diver') return 'The Deep Connector';
    if (dna.communicationArchetype == 'jokester') return 'The Charmer';
    return 'The Explorer';
  }

  String _buildLocalSummary(UserDNA dna) {
    final parts = <String>[];
    parts.add('Your profile paints a picture of a ${dna.socialEnergyProfile.replaceAll("_", " ")} with ${dna.attachmentStyle} attachment tendencies.');
    if (dna.hasBehaviorData) {
      parts.add('Your behavior data shows a ${(dna.responseRate * 100).toInt()}% response rate and ${(dna.ghostRate * 100).toInt()}% ghost rate.');
    }
    parts.add('Your communication archetype is "${dna.communicationArchetype.replaceAll("_", " ")}".');
    return parts.join(' ');
  }

  String _inferDatingStyle(UserDNA dna) {
    if (dna.lifestyleTemperature == 'fire') return 'Fast & Intense';
    if (dna.lifestyleTemperature == 'ice') return 'Methodical & Selective';
    if (dna.socialEnergyProfile == 'high_energy_social') return 'Social Butterfly';
    if (dna.attachmentStyle == 'avoidant') return 'Independent Explorer';
    return 'Balanced Connector';
  }

  String _buildStyleDescription(UserDNA dna) {
    return 'Based on your ${dna.lifestyleTemperature} lifestyle temperature and ${dna.socialEnergyProfile.replaceAll("_", " ")} energy, you tend toward ${dna.intimacyBlueprint.replaceAll("_", " ")} connections.';
  }

  List<String> _inferBlindSpots(UserDNA dna) {
    final spots = <String>[];
    if (dna.ghostRate > 0.3) spots.add('Your ghost rate is higher than you probably realize');
    if (dna.photoCount < 3) spots.add('Your photo count may be limiting your match quality');
    if (dna.profileCompleteness < 0.6) spots.add('An incomplete profile signals low effort to potential matches');
    if (dna.bandwidth < 0.3 && dna.seeking.length > 2) spots.add('Wanting a lot while offering limited bandwidth can frustrate matches');
    return spots;
  }

  List<String> _inferStrengths(UserDNA dna) {
    final strengths = <String>[];
    if (dna.intentionClarity > 0.7) strengths.add('Clear about what you want — refreshing');
    if (dna.responseRate > 0.7) strengths.add('Responsive communicator — people feel valued');
    if (dna.profileCompleteness > 0.8) strengths.add('Complete profile shows investment');
    if (dna.hardLimits.isNotEmpty) strengths.add('Defined boundaries — sign of self-awareness');
    if (strengths.isEmpty) strengths.add('Still building your track record — keep going');
    return strengths;
  }

  List<String> _inferGrowthEdges(UserDNA dna) {
    final edges = <String>[];
    if (dna.ghostRate > 0.3) edges.add('Use Ghost Protocol to close conversations with grace');
    if (dna.photoCount < 3) edges.add('Add more photos — variety shows different sides of you');
    if (dna.messagesSent > 0 && dna.datesScheduled == 0) edges.add('Practice moving conversations toward meeting up');
    if (dna.responseRate < 0.4) edges.add('Respond to more messages — even a polite decline builds reputation');
    return edges;
  }

  String _buildBrutalOneLiner(UserDNA dna) {
    if (dna.ghostRate > 0.5) return 'You collect matches like Pokémon cards and then forget they exist.';
    if (dna.totalMatches > 20 && dna.datesScheduled == 0) return 'You\'re great at matching and terrible at actually meeting people.';
    if (dna.responseRate < 0.2 && dna.hasBehaviorData) return 'Your inbox is a graveyard of unanswered "hey" messages.';
    if (dna.profileCompleteness < 0.4) return 'Your profile is basically a "closed for business" sign.';
    return 'You\'re still writing your story. Make it a good one.';
  }

  String _buildOptimizationAdvice(UserDNA dna) {
    if (dna.ghostRate > 0.4) return 'The single biggest thing you can do: stop ghosting. Use Ghost Protocol to close conversations respectfully. Your reputation precedes you.';
    if (dna.photoCount < 2) return 'Add more photos. A profile with one photo instantly reads as "not serious" or "something to hide."';
    if (dna.profileCompleteness < 0.5) return 'Finish your profile. Every empty field is a reason for someone to swipe left.';
    if (dna.totalMatches > 10 && dna.datesScheduled == 0) return 'Start suggesting meetups by message 10. The app is a bridge, not the destination.';
    return 'Keep your profile fresh, respond promptly, and don\'t be afraid to make the first move.';
  }

  /// Extract JSON from a potentially wrapped AI response
  String _extractJson(String content) {
    // Try to find JSON in the response
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      return content.substring(jsonStart, jsonEnd + 1);
    }
    return content;
  }

  /// Invalidate cache (call after profile update or new behavior data)
  void invalidateCache({String? userId}) {
    if (userId != null) {
      _cache.remove(userId);
      _cacheTimestamps.remove(userId);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class HardTruthAssessment {
  HardTruthAssessment({
    required this.personalityArchetype,
    required this.personalitySummary,
    required this.datingStyle,
    required this.datingStyleDescription,
    required this.blindSpots,
    required this.strengths,
    required this.growthEdges,
    required this.contradictionInsights,
    required this.brutalTruthOneLiner,
    required this.optimizationAdvice,
    required this.compatibilityPrediction,
    required this.detectedContradictions,
    required this.overallScore,
    required this.consistencyScore,
    required this.effortScore,
    required this.selfAwarenessIndicator,
    required this.generatedAt,
    required this.tokensUsed,
    this.isNewUser = false,
    this.isFallback = false,
  });

  // AI-generated insights
  final String personalityArchetype;
  final String personalitySummary;
  final String datingStyle;
  final String datingStyleDescription;
  final List<String> blindSpots;
  final List<String> strengths;
  final List<String> growthEdges;
  final List<String> contradictionInsights;
  final String brutalTruthOneLiner;
  final String optimizationAdvice;
  final String compatibilityPrediction;

  // Structural analysis
  final List<ProfileContradiction> detectedContradictions;

  // Computed scores
  final double overallScore; // -1 means not enough data
  final double consistencyScore; // How consistent desires vs behavior
  final double effortScore; // How much effort they're putting in
  final String selfAwarenessIndicator;

  // Meta
  final DateTime generatedAt;
  final int tokensUsed;
  final bool isNewUser;
  final bool isFallback;

  bool get hasEnoughData => overallScore >= 0;
}

class ProfileContradiction {
  ProfileContradiction({
    required this.category,
    required this.description,
    required this.severity,
    required this.insight,
  });

  final String category;
  final String description;
  final String severity; // high, medium, low, observation
  final String insight;
}
