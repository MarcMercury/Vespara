import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PREDICTIVE MATCHING ENGINE - Learns What Makes Couples Click
/// ════════════════════════════════════════════════════════════════════════════
///
/// The magic: Better matches without users knowing why
/// - Learns from successful couples (high engagement, dates, exclusivity)
/// - Weighs factors users don't explicitly state
/// - Explains compatibility in human terms
///
/// User perception: "These matches are SO much better than other apps"

class PredictiveMatchingEngine {
  PredictiveMatchingEngine._();
  static PredictiveMatchingEngine? _instance;
  static PredictiveMatchingEngine get instance =>
      _instance ??= PredictiveMatchingEngine._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService.instance;
  final Random _random = Random();

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // SCORE POTENTIAL MATCHES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Score a potential match - higher is better
  Future<MatchPrediction> predictCompatibility({
    required Map<String, dynamic> myProfile,
    required Map<String, dynamic> theirProfile,
  }) async {
    // Gather signals
    final signals = await _gatherSignals(myProfile, theirProfile);

    // Calculate base score from explicit factors
    final double baseScore = _calculateBaseScore(signals);

    // Apply learned weights from successful couples
    final learnedBoost = await _applyLearnedWeights(signals);

    // Calculate final score
    final double finalScore = (baseScore + learnedBoost).clamp(0.0, 1.0);

    // Generate human-readable explanation
    final explanation = _generateExplanation(signals, finalScore);

    return MatchPrediction(
      score: finalScore,
      signals: signals,
      explanation: explanation,
      topReasons: _getTopReasons(signals),
      hiddenFactors: _getHiddenFactors(signals),
    );
  }

  /// Rank a list of potential matches
  Future<List<RankedMatch>> rankPotentialMatches({
    required Map<String, dynamic> myProfile,
    required List<Map<String, dynamic>> candidates,
  }) async {
    final rankings = <RankedMatch>[];

    for (final candidate in candidates) {
      final prediction = await predictCompatibility(
        myProfile: myProfile,
        theirProfile: candidate,
      );

      rankings.add(
        RankedMatch(
          profile: candidate,
          prediction: prediction,
        ),
      );
    }

    // Sort by score, highest first
    rankings.sort((a, b) => b.prediction.score.compareTo(a.prediction.score));

    return rankings;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNAL GATHERING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<CompatibilitySignals> _gatherSignals(
    Map<String, dynamic> myProfile,
    Map<String, dynamic> theirProfile,
  ) async {
    // Extract interests
    final myInterests = (myProfile['interests'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toSet() ??
        {};
    final theirInterests = (theirProfile['interests'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toSet() ??
        {};

    final sharedInterests = myInterests.intersection(theirInterests);
    final complementaryInterests =
        _findComplementary(myInterests, theirInterests);

    // Communication style signals
    final myBio = (myProfile['bio'] ?? '').toString();
    final theirBio = (theirProfile['bio'] ?? '').toString();
    final communicationMatch = _analyzeCommunicationMatch(myBio, theirBio);

    // Activity level signals
    final activityMatch = await _analyzeActivityMatch(
      myProfile['id'] as String?,
      theirProfile['id'] as String?,
    );

    // Lifestyle signals
    final lifestyleMatch = _analyzeLifestyle(myProfile, theirProfile);

    // Hidden signals (things users don't explicitly say)
    final hiddenSignals = await _detectHiddenSignals(myProfile, theirProfile);

    return CompatibilitySignals(
      sharedInterestCount: sharedInterests.length,
      sharedInterests: sharedInterests.toList(),
      complementaryInterests: complementaryInterests,
      communicationStyleMatch: communicationMatch,
      activityLevelMatch: activityMatch,
      lifestyleMatch: lifestyleMatch,
      hiddenSignals: hiddenSignals,
    );
  }

  List<String> _findComplementary(Set<String> set1, Set<String> set2) {
    final complementary = <String>[];

    // Complementary pairs that work well together
    final pairs = {
      'cooking': ['eating', 'food', 'restaurants'],
      'photography': ['travel', 'nature', 'art'],
      'music': ['concerts', 'dancing', 'festivals'],
      'fitness': ['hiking', 'yoga', 'sports'],
      'reading': ['writing', 'movies', 'philosophy'],
      'introvert': ['extrovert'], // Opposites attract sometimes
      'adventure': ['planning', 'spontaneous'],
    };

    for (final interest in set1) {
      for (final entry in pairs.entries) {
        if (interest.contains(entry.key)) {
          for (final complement in entry.value) {
            if (set2.any((i) => i.contains(complement))) {
              complementary.add('$interest + $complement');
            }
          }
        }
      }
    }

    return complementary;
  }

  double _analyzeCommunicationMatch(String bio1, String bio2) {
    // Analyze writing style similarity
    double score = 0.5;

    // Similar length preference
    final len1 = bio1.length;
    final len2 = bio2.length;
    final lengthRatio =
        len1 > 0 && len2 > 0 ? (len1 < len2 ? len1 / len2 : len2 / len1) : 0.5;
    score += (lengthRatio - 0.5) * 0.2;

    // Emoji usage
    final emoji1 = _hasEmojis(bio1);
    final emoji2 = _hasEmojis(bio2);
    if (emoji1 == emoji2) score += 0.1;

    // Humor indicators
    final humor1 = _hasHumor(bio1);
    final humor2 = _hasHumor(bio2);
    if (humor1 && humor2) score += 0.15;

    // Depth/seriousness
    final deep1 = _isDeep(bio1);
    final deep2 = _isDeep(bio2);
    if (deep1 == deep2) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  bool _hasEmojis(String text) =>
      RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(text);

  bool _hasHumor(String text) {
    final lower = text.toLowerCase();
    return lower.contains('lol') ||
        lower.contains('haha') ||
        lower.contains('😂') ||
        lower.contains('funny') ||
        lower.contains('sarcasm') ||
        lower.contains('joke');
  }

  bool _isDeep(String text) {
    final lower = text.toLowerCase();
    return lower.contains('value') ||
        lower.contains('believe') ||
        lower.contains('passion') ||
        lower.contains('meaningful') ||
        lower.contains('authentic') ||
        lower.contains('growth');
  }

  Future<double> _analyzeActivityMatch(String? userId1, String? userId2) async {
    if (userId1 == null || userId2 == null) return 0.5;

    try {
      // Get activity patterns for both users
      final patterns1 = await _getActivityPatterns(userId1);
      final patterns2 = await _getActivityPatterns(userId2);

      if (patterns1 == null || patterns2 == null) return 0.5;

      // Compare active hours overlap
      final hoursOverlap = _calculateOverlap(
        patterns1['active_hours'] as List?,
        patterns2['active_hours'] as List?,
      );

      // Compare response frequency
      final freq1 = patterns1['messages_per_day'] as double? ?? 5;
      final freq2 = patterns2['messages_per_day'] as double? ?? 5;
      final freqRatio = freq1 > freq2 ? freq2 / freq1 : freq1 / freq2;

      return (hoursOverlap * 0.6 + freqRatio * 0.4).clamp(0.0, 1.0);
    } catch (e) {
      return 0.5;
    }
  }

  Future<Map<String, dynamic>?> _getActivityPatterns(String userId) async {
    try {
      return await _supabase
          .from('ai_user_preferences')
          .select('active_hours, messages_per_day')
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  double _calculateOverlap(List? hours1, List? hours2) {
    if (hours1 == null || hours2 == null) return 0.5;

    final set1 = hours1.map((h) => h as int).toSet();
    final set2 = hours2.map((h) => h as int).toSet();

    final overlap = set1.intersection(set2).length;
    final total = set1.union(set2).length;

    return total > 0 ? overlap / total : 0.5;
  }

  double _analyzeLifestyle(
    Map<String, dynamic> profile1,
    Map<String, dynamic> profile2,
  ) {
    double score = 0.5;

    // Location proximity (if available)
    final loc1 = profile1['location'] ?? profile1['zip_code'];
    final loc2 = profile2['location'] ?? profile2['zip_code'];
    if (loc1 != null && loc2 != null && loc1 == loc2) {
      score += 0.2;
    }

    // Looking for same thing
    final looking1 = profile1['looking_for']?.toString().toLowerCase();
    final looking2 = profile2['looking_for']?.toString().toLowerCase();
    if (looking1 != null && looking2 != null) {
      if (looking1 == looking2) {
        score += 0.3;
      } else if (_areCompatibleGoals(looking1, looking2)) {
        score += 0.15;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  bool _areCompatibleGoals(String goal1, String goal2) {
    final casual = ['casual', 'fun', 'friends'];
    final serious = ['relationship', 'serious', 'long-term', 'marriage'];

    final isCasual1 = casual.any((c) => goal1.contains(c));
    final isCasual2 = casual.any((c) => goal2.contains(c));
    final isSerious1 = serious.any((s) => goal1.contains(s));
    final isSerious2 = serious.any((s) => goal2.contains(s));

    // Compatible if both casual or both serious
    return (isCasual1 && isCasual2) || (isSerious1 && isSerious2);
  }

  Future<List<HiddenSignal>> _detectHiddenSignals(
    Map<String, dynamic> profile1,
    Map<String, dynamic> profile2,
  ) async {
    final signals = <HiddenSignal>[];

    // Detect attachment style compatibility
    final attachment1 = _inferAttachmentStyle(profile1);
    final attachment2 = _inferAttachmentStyle(profile2);
    if (_areAttachmentStylesCompatible(attachment1, attachment2)) {
      signals.add(
        HiddenSignal(
          factor: 'attachment_compatibility',
          strength: 0.15,
          description: 'Compatible emotional styles',
        ),
      );
    }

    // Detect ambition level match
    final ambition1 = _inferAmbitionLevel(profile1);
    final ambition2 = _inferAmbitionLevel(profile2);
    if ((ambition1 - ambition2).abs() < 2) {
      signals.add(
        HiddenSignal(
          factor: 'ambition_match',
          strength: 0.1,
          description: 'Similar drive levels',
        ),
      );
    }

    // Detect social energy match
    final social1 = _inferSocialEnergy(profile1);
    final social2 = _inferSocialEnergy(profile2);
    if ((social1 - social2).abs() < 2) {
      signals.add(
        HiddenSignal(
          factor: 'social_energy_match',
          strength: 0.1,
          description: 'Compatible social energy',
        ),
      );
    }

    return signals;
  }

  String _inferAttachmentStyle(Map<String, dynamic> profile) {
    final bio = (profile['bio'] ?? '').toString().toLowerCase();

    if (bio.contains('independent') ||
        bio.contains('space') ||
        bio.contains('freedom')) {
      return 'avoidant';
    }
    if (bio.contains('close') ||
        bio.contains('together') ||
        bio.contains('partner')) {
      return 'secure';
    }
    if (bio.contains('honest') ||
        bio.contains('trust') ||
        bio.contains('open')) {
      return 'secure';
    }

    return 'unknown';
  }

  bool _areAttachmentStylesCompatible(String style1, String style2) {
    if (style1 == 'secure' || style2 == 'secure') return true;
    if (style1 == style2) return true;
    return false;
  }

  int _inferAmbitionLevel(Map<String, dynamic> profile) {
    final bio = (profile['bio'] ?? '').toString().toLowerCase();
    final occupation = (profile['occupation'] ?? '').toString().toLowerCase();

    int level = 3; // Default middle

    if (bio.contains('entrepreneur') ||
        bio.contains('founder') ||
        bio.contains('ceo') ||
        occupation.contains('founder')) {
      level = 5;
    } else if (bio.contains('career') ||
        bio.contains('ambitious') ||
        bio.contains('driven')) {
      level = 4;
    } else if (bio.contains('chill') ||
        bio.contains('relaxed') ||
        bio.contains('easy-going')) {
      level = 2;
    }

    return level;
  }

  int _inferSocialEnergy(Map<String, dynamic> profile) {
    final bio = (profile['bio'] ?? '').toString().toLowerCase();
    final interests = (profile['interests'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        [];

    int level = 3;

    if (bio.contains('introvert') ||
        bio.contains('homebody') ||
        interests.contains('reading') ||
        interests.contains('gaming')) {
      level = 2;
    } else if (bio.contains('extrovert') ||
        bio.contains('social') ||
        bio.contains('party') ||
        interests.contains('clubbing') ||
        interests.contains('networking')) {
      level = 5;
    }

    return level;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCORE CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  double _calculateBaseScore(CompatibilitySignals signals) {
    double score = 0.3; // Base score

    // Shared interests (max +0.25)
    score += (signals.sharedInterestCount * 0.05).clamp(0.0, 0.25);

    // Complementary interests (max +0.1)
    score += (signals.complementaryInterests.length * 0.05).clamp(0.0, 0.1);

    // Communication match (max +0.15)
    score += signals.communicationStyleMatch * 0.15;

    // Activity level (max +0.1)
    score += signals.activityLevelMatch * 0.1;

    // Lifestyle (max +0.1)
    score += signals.lifestyleMatch * 0.1;

    return score.clamp(0.0, 1.0);
  }

  Future<double> _applyLearnedWeights(CompatibilitySignals signals) async {
    double boost = 0.0;

    // Add boost from hidden signals
    for (final signal in signals.hiddenSignals) {
      boost += signal.strength;
    }

    // Get learned weights from successful matches (if available)
    try {
      final weights = await _supabase
          .from('ai_matching_weights')
          .select('factor, weight')
          .limit(10);

      for (final w in weights) {
        final factor = w['factor'] as String;
        final weight = w['weight'] as double;

        if (factor == 'shared_interests' && signals.sharedInterestCount > 2) {
          boost += weight;
        }
        if (factor == 'communication' &&
            signals.communicationStyleMatch > 0.7) {
          boost += weight;
        }
        // Add more learned factors as data accumulates
      }
    } catch (_) {
      // Weights table might not exist yet
    }

    return boost;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPLANATION GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  String _generateExplanation(CompatibilitySignals signals, double score) {
    if (score >= 0.8) {
      if (signals.sharedInterestCount >= 3) {
        return 'You two have so much in common!';
      }
      return 'Strong compatibility across the board';
    }

    if (score >= 0.6) {
      if (signals.complementaryInterests.isNotEmpty) {
        return 'Great balance - you\'ll teach each other new things';
      }
      return 'Good potential for connection';
    }

    if (score >= 0.4) {
      return 'Worth exploring - sometimes opposites attract!';
    }

    return 'New connection to discover';
  }

  List<String> _getTopReasons(CompatibilitySignals signals) {
    final reasons = <String>[];

    if (signals.sharedInterests.isNotEmpty) {
      reasons.add('You both love ${signals.sharedInterests.first}');
    }

    if (signals.communicationStyleMatch > 0.7) {
      reasons.add('Similar communication styles');
    }

    if (signals.complementaryInterests.isNotEmpty) {
      reasons.add('Complementary interests');
    }

    if (signals.activityLevelMatch > 0.7) {
      reasons.add('Similar activity patterns');
    }

    return reasons.take(3).toList();
  }

  List<String> _getHiddenFactors(CompatibilitySignals signals) =>
      signals.hiddenSignals.map((s) => s.description).toList();

  // ═══════════════════════════════════════════════════════════════════════════
  // LEARN FROM SUCCESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record a successful match outcome to improve future predictions
  Future<void> recordMatchOutcome({
    required String matchId,
    required MatchOutcome outcome,
  }) async {
    if (_userId == null) return;

    try {
      await _supabase.from('match_outcomes').insert({
        'match_id': matchId,
        'outcome': outcome.name,
        'recorded_at': DateTime.now().toIso8601String(),
      });

      // Trigger weight recalculation (async, don't await)
      _updateLearnedWeights(matchId, outcome);
    } catch (e) {
      debugPrint('PredictiveMatching: Failed to record outcome - $e');
    }
  }

  Future<void> _updateLearnedWeights(
      String matchId, MatchOutcome outcome,) async {
    // This would be a background job in production
    // For now, just log the intent
    debugPrint(
        'Would update weights for match $matchId with outcome ${outcome.name}',);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class MatchPrediction {
  MatchPrediction({
    required this.score,
    required this.signals,
    required this.explanation,
    required this.topReasons,
    required this.hiddenFactors,
  });
  final double score;
  final CompatibilitySignals signals;
  final String explanation;
  final List<String> topReasons;
  final List<String> hiddenFactors;

  String get scoreLabel {
    if (score >= 0.8) return 'Great Match!';
    if (score >= 0.6) return 'Good Match';
    if (score >= 0.4) return 'Worth Exploring';
    return 'New Connection';
  }

  String get scoreEmoji {
    if (score >= 0.8) return '🔥';
    if (score >= 0.6) return '⭐';
    if (score >= 0.4) return '✨';
    return '💫';
  }
}

class CompatibilitySignals {
  CompatibilitySignals({
    required this.sharedInterestCount,
    required this.sharedInterests,
    required this.complementaryInterests,
    required this.communicationStyleMatch,
    required this.activityLevelMatch,
    required this.lifestyleMatch,
    required this.hiddenSignals,
  });
  final int sharedInterestCount;
  final List<String> sharedInterests;
  final List<String> complementaryInterests;
  final double communicationStyleMatch;
  final double activityLevelMatch;
  final double lifestyleMatch;
  final List<HiddenSignal> hiddenSignals;
}

class HiddenSignal {
  HiddenSignal({
    required this.factor,
    required this.strength,
    required this.description,
  });
  final String factor;
  final double strength;
  final String description;
}

class RankedMatch {
  RankedMatch({
    required this.profile,
    required this.prediction,
  });
  final Map<String, dynamic> profile;
  final MatchPrediction prediction;
}

enum MatchOutcome {
  noEngagement, // Matched but never messaged
  shortConversation, // <10 messages
  longConversation, // 10+ messages
  datePlanned, // Mentioned meeting up
  dateCompleted, // Actually met
  relationship, // Became exclusive
}
