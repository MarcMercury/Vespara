import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// USER DNA SERVICE - Deep Psychological Profile Intelligence
/// ════════════════════════════════════════════════════════════════════════════
///
/// The brain behind every personalized AI interaction. Builds a rich
/// psychological model ("DNA") from ALL user signals — not just what they
/// explicitly say, but what their choices imply.
///
/// This feeds into: bio generation, hard truth, matching, trait suggestions,
/// nudges, game content, and conversation coaching.
///
/// Key insight: Users tell us FAR more than they realize through their
/// combination of selections. A "Dominant + Night Owl + Career-driven +
/// Hot heat level" paints a very different picture from "Submissive +
/// Early Riser + Chill + Mild." We should USE that.

class UserDNAService {
  UserDNAService._();
  static UserDNAService? _instance;
  static UserDNAService get instance => _instance ??= UserDNAService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService.instance;

  // Cache the DNA to avoid recomputing on every call
  final Map<String, UserDNA> _dnaCache = {};
  final Duration _cacheExpiry = const Duration(minutes: 60);
  final Map<String, DateTime> _cacheTimestamps = {};

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD USER DNA - The Master Profile
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build complete psychological DNA from all available signals.
  /// This is the foundation that powers every other AI function.
  Future<UserDNA?> buildUserDNA({String? userId, bool forceRefresh = false}) async {
    final uid = userId ?? _userId;
    if (uid == null) return null;

    // Check cache
    if (!forceRefresh && _dnaCache.containsKey(uid)) {
      final timestamp = _cacheTimestamps[uid];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _dnaCache[uid];
      }
    }

    try {
      // Gather ALL signals in parallel
      final results = await Future.wait([
        _getFullProfile(uid),
        _getBehaviorMetrics(uid),
        _getConversationPatterns(uid),
        _getGamePreferences(uid),
        _getMatchHistory(uid),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final behavior = results[1] as Map<String, dynamic>?;
      final conversationPatterns = results[2] as Map<String, dynamic>?;
      final gamePrefs = results[3] as Map<String, dynamic>?;
      final matchHistory = results[4] as Map<String, dynamic>?;

      if (profile == null) return null;

      // Derive deep psychological dimensions
      final dna = UserDNA(
        userId: uid,
        // Raw profile data
        displayName: profile['display_name'] as String? ?? '',
        age: _calculateAge(profile['birth_date'] as String?),
        gender: List<String>.from(profile['gender'] ?? []),
        orientation: List<String>.from(profile['orientation'] ?? []),
        pronouns: profile['pronouns'] as String?,
        occupation: profile['occupation'] as String?,
        headline: profile['headline'] as String?,
        city: profile['city'] as String?,
        state: profile['state'] as String?,

        // Relationship configuration
        relationshipStatus: List<String>.from(profile['relationship_status'] ?? []),
        seeking: List<String>.from(profile['seeking'] ?? []),
        partnerInvolvement: profile['partner_involvement'] as String?,

        // Selected traits and preferences
        traits: List<String>.from(profile['looking_for'] ?? []),
        heatLevel: profile['heat_level'] as String? ?? 'medium',
        hardLimits: List<String>.from(profile['hard_limits'] ?? []),

        // Logistics that reveal personality
        availability: List<String>.from(profile['availability_general'] ?? []),
        schedulingStyle: profile['scheduling_style'] as String?,
        hostingStatus: profile['hosting_status'] as String?,
        travelRadius: (profile['travel_radius'] as num?)?.toDouble() ?? 25,
        bandwidth: (profile['bandwidth'] as num?)?.toDouble() ?? 0.5,
        discretionLevel: profile['discretion_level'] as String?,

        // Current bio/hook
        currentBio: profile['bio'] as String?,
        currentHook: profile['hook'] as String?,

        // Interests
        interests: List<String>.from(profile['interest_tags'] ?? []),

        // Photos count (signals effort/confidence)
        photoCount: (profile['photos'] as List?)?.length ?? 0,

        // Derived psychological dimensions
        attachmentStyle: _deriveAttachmentStyle(profile, behavior),
        communicationArchetype: _deriveCommunicationArchetype(profile, conversationPatterns),
        socialEnergyProfile: _deriveSocialEnergy(profile),
        intimacyBlueprint: _deriveIntimacyBlueprint(profile),
        riskTolerance: _deriveRiskTolerance(profile),
        emotionalIntelligence: _deriveEmotionalIntelligence(behavior, conversationPatterns),
        intentionClarity: _deriveIntentionClarity(profile),
        lifestyleTemperature: _deriveLifestyleTemperature(profile),

        // Behavioral signals (from actual usage)
        ghostRate: (behavior?['ghost_rate'] as num?)?.toDouble() ?? 0,
        flakeRate: (behavior?['flake_rate'] as num?)?.toDouble() ?? 0,
        responseRate: (behavior?['response_rate'] as num?)?.toDouble() ?? 0.5,
        avgResponseTime: (behavior?['avg_response_time_minutes'] as num?)?.toDouble(),
        messagesSent: behavior?['messages_sent'] as int? ?? 0,
        messagesReceived: behavior?['messages_received'] as int? ?? 0,
        totalMatches: behavior?['total_matches'] as int? ?? 0,
        activeConversations: behavior?['active_conversations'] as int? ?? 0,
        datesScheduled: behavior?['dates_scheduled'] as int? ?? 0,

        // Conversation intelligence
        avgMessageLength: (conversationPatterns?['avg_message_length'] as num?)?.toDouble(),
        questionRatio: (conversationPatterns?['question_ratio'] as num?)?.toDouble(),
        emojiUsageRate: (conversationPatterns?['emoji_usage_rate'] as num?)?.toDouble(),
        initiatesConversations: conversationPatterns?['initiates_conversations'] as bool? ?? false,
        peakActivityHours: List<int>.from(conversationPatterns?['peak_hours'] ?? []),

        // Game preferences
        preferredGameTypes: List<String>.from(gamePrefs?['favorite_games'] ?? []),
        preferredHeatInGames: gamePrefs?['preferred_heat'] as String?,
        gameCompletionRate: (gamePrefs?['completion_rate'] as num?)?.toDouble(),

        // Match pattern intelligence
        typicalMatchTraits: List<String>.from(matchHistory?['common_match_traits'] ?? []),
        successfulMatchPatterns: List<String>.from(matchHistory?['success_patterns'] ?? []),
        swipeSelectivity: (matchHistory?['selectivity'] as num?)?.toDouble(),

        // Timestamps
        profileCreatedAt: profile['created_at'] != null
            ? DateTime.tryParse(profile['created_at'] as String)
            : null,
        lastActiveAt: profile['last_active'] != null
            ? DateTime.tryParse(profile['last_active'] as String)
            : null,
      );

      // Cache it
      _dnaCache[uid] = dna;
      _cacheTimestamps[uid] = DateTime.now();

      return dna;
    } catch (e, stack) {
      debugPrint('UserDNAService: Failed to build DNA - $e\n$stack');
      return null;
    }
  }

  /// Build a compact context string for LLM prompts.
  /// This is the "briefing document" that makes every AI response personalized.
  Future<String> buildContextBrief({String? userId}) async {
    final dna = await buildUserDNA(userId: userId);
    if (dna == null) return 'New user with limited profile data.';

    return dna.toContextBrief();
  }

  /// Build context brief for a match pair (for compatibility/conversation AI)
  Future<String> buildPairContext({
    required String userId1,
    required String userId2,
  }) async {
    final dna1 = await buildUserDNA(userId: userId1);
    final dna2 = await buildUserDNA(userId: userId2);

    if (dna1 == null || dna2 == null) return 'Insufficient profile data.';

    return '''
=== PERSON A: ${dna1.displayName} ===
${dna1.toContextBrief()}

=== PERSON B: ${dna2.displayName} ===
${dna2.toContextBrief()}

=== PAIR DYNAMICS ===
Shared interests: ${_findSharedItems(dna1.interests, dna2.interests).join(', ')}
Shared traits: ${_findSharedItems(dna1.traits, dna2.traits).join(', ')}
Heat compatibility: ${dna1.heatLevel} ↔ ${dna2.heatLevel}
Seeking overlap: ${_findSharedItems(dna1.seeking, dna2.seeking).join(', ')}
Schedule overlap: ${_assessScheduleOverlap(dna1, dna2)}
Communication style match: ${_assessCommunicationFit(dna1, dna2)}
Energy balance: ${dna1.socialEnergyProfile} ↔ ${dna2.socialEnergyProfile}
''';
  }

  List<String> _findSharedItems(List<String> list1, List<String> list2) {
    final set1 = list1.map((e) => e.toLowerCase()).toSet();
    final set2 = list2.map((e) => e.toLowerCase()).toSet();
    return set1.intersection(set2).toList();
  }

  String _assessScheduleOverlap(UserDNA dna1, UserDNA dna2) {
    final shared = _findSharedItems(dna1.availability, dna2.availability);
    if (shared.isEmpty) return 'Low overlap — may need intentional scheduling';
    if (shared.length >= 3) return 'High overlap — easy to connect';
    return 'Moderate overlap — some shared windows';
  }

  String _assessCommunicationFit(UserDNA dna1, UserDNA dna2) {
    if (dna1.communicationArchetype == dna2.communicationArchetype) {
      return 'Mirror match — ${dna1.communicationArchetype}';
    }
    // Complementary archetypes
    final complementary = {
      'storyteller': ['active_listener', 'deep_diver'],
      'jokester': ['appreciative_audience', 'banter_partner'],
      'deep_diver': ['storyteller', 'philosopher'],
      'rapid_fire': ['rapid_fire', 'jokester'],
      'slow_burner': ['deep_diver', 'storyteller'],
    };
    final c1 = complementary[dna1.communicationArchetype] ?? [];
    if (c1.contains(dna2.communicationArchetype)) {
      return 'Complementary — ${dna1.communicationArchetype} + ${dna2.communicationArchetype}';
    }
    return '${dna1.communicationArchetype} + ${dna2.communicationArchetype}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA FETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _getFullProfile(String userId) async {
    try {
      return await _supabase
          .from('profiles')
          .select('''
            id, display_name, bio, hook, headline, occupation, birth_date,
            gender, pronouns, orientation, relationship_status, seeking,
            partner_involvement, looking_for, heat_level, hard_limits,
            availability_general, scheduling_style, hosting_status,
            travel_radius, bandwidth, discretion_level, interests,
            photos, city, state, zip_code, created_at, last_active
          ''')
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('UserDNA: Failed to fetch profile - $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getBehaviorMetrics(String userId) async {
    try {
      return await _supabase
          .from('user_analytics')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getConversationPatterns(String userId) async {
    try {
      final prefs = await _supabase
          .from('ai_user_preferences')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (prefs == null) return null;

      return {
        'avg_message_length': prefs['avg_message_length'],
        'question_ratio': prefs['question_ratio'],
        'emoji_usage_rate': prefs['emoji_usage_rate'],
        'initiates_conversations': prefs['initiates_conversations'],
        'peak_hours': prefs['active_hours'],
        'conversation_style': prefs['conversation_style'],
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getGamePreferences(String userId) async {
    try {
      final prefs = await _supabase
          .from('ai_user_preferences')
          .select('favorite_games, preferred_heat_levels')
          .eq('user_id', userId)
          .maybeSingle();

      if (prefs == null) return null;

      return {
        'favorite_games': prefs['favorite_games'],
        'preferred_heat': prefs['preferred_heat_levels'],
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getMatchHistory(String userId) async {
    try {
      // Analyze patterns from past matches
      final matches = await _supabase
          .from('matches')
          .select('matched_user_id, status, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      if (matches == null || (matches as List).isEmpty) return null;

      return {
        'common_match_traits': <String>[],
        'success_patterns': <String>[],
        'selectivity': null,
      };
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PSYCHOLOGICAL DERIVATION ENGINE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Derive attachment style from profile signals + behavior
  String _deriveAttachmentStyle(
    Map<String, dynamic> profile,
    Map<String, dynamic>? behavior,
  ) {
    final traits = List<String>.from(profile['looking_for'] ?? []);
    final bio = (profile['bio'] ?? '').toString().toLowerCase();
    final seeking = List<String>.from(profile['seeking'] ?? []);
    final ghostRate = (behavior?['ghost_rate'] as num?)?.toDouble() ?? 0;
    final discretion = profile['discretion_level'] as String?;

    int secureScore = 0;
    int anxiousScore = 0;
    int avoidantScore = 0;

    // Trait-based signals
    if (traits.any((t) => t.contains('Romantic') || t.contains('Intimate'))) secureScore += 2;
    if (traits.any((t) => t.contains('Passionate') || t.contains('Intense'))) anxiousScore += 1;
    if (traits.any((t) => t.contains('Independent') || t.contains('Casual'))) avoidantScore += 1;
    if (traits.any((t) => t.contains('Gentle') || t.contains('Sensual'))) secureScore += 1;
    if (traits.any((t) => t.contains('Dominant'))) avoidantScore += 1;

    // Seeking-based signals
    if (seeking.contains('relationship') || seeking.contains('partnership')) secureScore += 2;
    if (seeking.contains('casual') || seeking.contains('fwb')) avoidantScore += 1;
    if (seeking.length >= 4) anxiousScore += 1; // Wants everything = anxious attachment

    // Bio keyword signals
    if (bio.contains('loyal') || bio.contains('committed')) secureScore += 1;
    if (bio.contains('space') || bio.contains('freedom') || bio.contains('no drama')) avoidantScore += 2;
    if (bio.contains('honest') || bio.contains('real') || bio.contains('genuine')) secureScore += 1;

    // Behavioral signals
    if (ghostRate > 40) avoidantScore += 3;
    if (ghostRate < 10 && (behavior?['response_rate'] as num? ?? 0) > 70) secureScore += 2;

    // Discretion level signals
    if (discretion == 'very_discreet') avoidantScore += 2;
    if (discretion == 'open') secureScore += 1;

    final maxScore = [secureScore, anxiousScore, avoidantScore].reduce((a, b) => a > b ? a : b);
    if (maxScore == secureScore) return 'secure';
    if (maxScore == anxiousScore) return 'anxious';
    return 'avoidant';
  }

  /// Derive communication archetype from how they write and interact
  String _deriveCommunicationArchetype(
    Map<String, dynamic> profile,
    Map<String, dynamic>? patterns,
  ) {
    final bio = (profile['bio'] ?? '').toString();
    final hook = (profile['hook'] ?? '').toString();
    final avgLen = (patterns?['avg_message_length'] as num?)?.toDouble() ?? 0;
    final questionRatio = (patterns?['question_ratio'] as num?)?.toDouble() ?? 0;
    final emojiRate = (patterns?['emoji_usage_rate'] as num?)?.toDouble() ?? 0;
    final traits = List<String>.from(profile['looking_for'] ?? []);

    // Analyze written content
    final bioLen = bio.length;
    final usesHumor = bio.toLowerCase().contains('sarcasm') ||
        bio.toLowerCase().contains('funny') ||
        bio.toLowerCase().contains('laugh') ||
        hook.contains('😂') || hook.contains('😏');
    final isDeep = bio.toLowerCase().contains('passion') ||
        bio.toLowerCase().contains('authentic') ||
        bio.toLowerCase().contains('soul') ||
        bio.toLowerCase().contains('meaning');
    final isPlayful = traits.any((t) =>
        t.contains('Mischievous') || t.contains('Playful') || t.contains('Witty'));

    if (usesHumor || (emojiRate > 0.3 && isPlayful)) return 'jokester';
    if (isDeep || (bioLen > 200 && questionRatio > 0.2)) return 'deep_diver';
    if (avgLen > 100 || bioLen > 250) return 'storyteller';
    if (avgLen > 0 && avgLen < 30 && emojiRate > 0.2) return 'rapid_fire';
    if (questionRatio > 0.3) return 'curious_explorer';
    return 'slow_burner';
  }

  /// Derive social energy profile
  String _deriveSocialEnergy(Map<String, dynamic> profile) {
    final traits = List<String>.from(profile['looking_for'] ?? []);
    final availability = List<String>.from(profile['availability_general'] ?? []);
    final bandwidth = (profile['bandwidth'] as num?)?.toDouble() ?? 0.5;
    final partyAvail = List<String>.from(profile['party_availability'] ?? []);

    int extrovertScore = 0;
    int introvertScore = 0;

    if (traits.any((t) => t.contains('Life of the Party') || t.contains('High Energy'))) extrovertScore += 3;
    if (traits.any((t) => t.contains('Homebody') || t.contains('Calm'))) introvertScore += 3;
    if (traits.any((t) => t.contains('Selectively Social'))) introvertScore += 1;
    if (availability.length >= 4) extrovertScore += 1;
    if (partyAvail.length >= 3) extrovertScore += 2;
    if (bandwidth > 0.7) extrovertScore += 1;
    if (bandwidth < 0.3) introvertScore += 2;

    if (extrovertScore > introvertScore + 2) return 'high_energy_social';
    if (introvertScore > extrovertScore + 2) return 'selective_introvert';
    if (extrovertScore > introvertScore) return 'social_butterfly';
    if (introvertScore > extrovertScore) return 'quality_over_quantity';
    return 'balanced_ambivert';
  }

  /// Derive intimacy blueprint from sexual/romantic preferences
  String _deriveIntimacyBlueprint(Map<String, dynamic> profile) {
    final traits = List<String>.from(profile['looking_for'] ?? []);
    final heatLevel = profile['heat_level'] as String? ?? 'medium';
    final hardLimits = List<String>.from(profile['hard_limits'] ?? []);

    final hasDominant = traits.any((t) => t.contains('Dominant'));
    final hasSubmissive = traits.any((t) => t.contains('Submissive'));
    final hasSwitch = traits.any((t) => t.contains('Switch'));
    final hasRough = traits.any((t) => t.contains('Rough'));
    final hasGentle = traits.any((t) => t.contains('Gentle'));
    final hasRoleplay = traits.any((t) => t.contains('Roleplay'));
    final hasExhibitionist = traits.any((t) => t.contains('Exhibitionist'));
    final hasVoyeur = traits.any((t) => t.contains('Voyeur'));
    final isBeginner = traits.any((t) => t.contains('Beginner') || t.contains('Curious'));
    final isExperienced = traits.any((t) => t.contains('Experienced'));

    if (heatLevel == 'mild' && hasGentle) return 'romantic_connection_first';
    if (heatLevel == 'nuclear' && (hasDominant || hasSubmissive)) return 'power_exchange_explorer';
    if (hasSwitch && isExperienced) return 'versatile_experienced';
    if (isBeginner) return 'curious_newcomer';
    if (hasRoleplay && hasExhibitionist) return 'performance_creative';
    if (hasRough && hasDominant) return 'intensity_seeker';
    if (hasGentle && !hasRough) return 'sensual_connection';
    if (hardLimits.length >= 5) return 'clear_boundaries_explorer';
    return 'open_and_adaptable';
  }

  /// Derive risk tolerance from choices
  double _deriveRiskTolerance(Map<String, dynamic> profile) {
    double score = 0.5;
    final heatLevel = profile['heat_level'] as String?;
    final discretion = profile['discretion_level'] as String?;
    final seeking = List<String>.from(profile['seeking'] ?? []);
    final hosting = profile['hosting_status'] as String?;
    final traits = List<String>.from(profile['looking_for'] ?? []);

    // Heat level
    if (heatLevel == 'nuclear') score += 0.2;
    if (heatLevel == 'hot') score += 0.1;
    if (heatLevel == 'mild') score -= 0.1;

    // Discretion (less discrete = higher risk tolerance)
    if (discretion == 'open') score += 0.1;
    if (discretion == 'very_discreet') score -= 0.15;

    // Seeking variety
    if (seeking.contains('group')) score += 0.1;
    if (seeking.length >= 3) score += 0.05;

    // Hosting (willing to host = higher risk tolerance)
    if (hosting == 'can_host') score += 0.05;

    // Traits
    if (traits.any((t) => t.contains('Exhibitionist'))) score += 0.1;
    if (traits.any((t) => t.contains('Voyeur'))) score += 0.05;

    return score.clamp(0.0, 1.0);
  }

  /// Derive emotional intelligence from behavior
  double _deriveEmotionalIntelligence(
    Map<String, dynamic>? behavior,
    Map<String, dynamic>? patterns,
  ) {
    if (behavior == null) return 0.5;
    double score = 0.5;

    final ghostRate = (behavior['ghost_rate'] as num?)?.toDouble() ?? 0;
    final responseRate = (behavior['response_rate'] as num?)?.toDouble() ?? 0.5;
    final questionRatio = (patterns?['question_ratio'] as num?)?.toDouble() ?? 0;

    // Low ghost rate = high EQ (can close things properly)
    if (ghostRate < 10) score += 0.15;
    if (ghostRate > 40) score -= 0.2;

    // High response rate = considers others
    if (responseRate > 0.8) score += 0.1;
    if (responseRate < 0.2) score -= 0.15;

    // Asks questions = genuinely curious about others
    if (questionRatio > 0.3) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Derive clarity of intention
  double _deriveIntentionClarity(Map<String, dynamic> profile) {
    double score = 0.3;
    final bio = (profile['bio'] ?? '').toString();
    final hook = (profile['hook'] ?? '').toString();
    final seeking = List<String>.from(profile['seeking'] ?? []);
    final hardLimits = List<String>.from(profile['hard_limits'] ?? []);

    // Has a clear bio
    if (bio.length > 50) score += 0.1;
    if (bio.length > 150) score += 0.1;

    // Has a hook
    if (hook.isNotEmpty) score += 0.1;

    // Clear about what they're seeking (not everything at once)
    if (seeking.length >= 1 && seeking.length <= 3) score += 0.15;

    // Has defined boundaries
    if (hardLimits.isNotEmpty) score += 0.15;
    if (hardLimits.length >= 3) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Temperature = how adventurous/wild vs settled/routine
  String _deriveLifestyleTemperature(Map<String, dynamic> profile) {
    final heat = profile['heat_level'] as String?;
    final scheduling = profile['scheduling_style'] as String?;
    final availability = List<String>.from(profile['availability_general'] ?? []);
    final partyAvail = List<String>.from(profile['party_availability'] ?? []);
    final traits = List<String>.from(profile['looking_for'] ?? []);

    int hotScore = 0;
    int coolScore = 0;

    if (heat == 'nuclear') hotScore += 3;
    if (heat == 'hot') hotScore += 2;
    if (heat == 'mild') coolScore += 2;
    if (scheduling == 'spontaneous' || scheduling == 'same_day') hotScore += 1;
    if (scheduling == 'advance_planning') coolScore += 1;
    if (availability.contains('spontaneous')) hotScore += 1;
    if (partyAvail.length >= 3) hotScore += 1;
    if (traits.any((t) => t.contains('High Energy'))) hotScore += 1;
    if (traits.any((t) => t.contains('Calm'))) coolScore += 1;

    if (hotScore > coolScore + 2) return 'fire';
    if (coolScore > hotScore + 2) return 'ice';
    if (hotScore > coolScore) return 'warm';
    if (coolScore > hotScore) return 'cool';
    return 'balanced';
  }

  int? _calculateAge(String? birthDate) {
    if (birthDate == null) return null;
    final dob = DateTime.tryParse(birthDate);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Invalidate cache when profile changes
  void invalidateCache({String? userId}) {
    final uid = userId ?? _userId;
    if (uid != null) {
      _dnaCache.remove(uid);
      _cacheTimestamps.remove(uid);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER DNA MODEL
// ═══════════════════════════════════════════════════════════════════════════

class UserDNA {
  UserDNA({
    required this.userId,
    required this.displayName,
    this.age,
    this.gender = const [],
    this.orientation = const [],
    this.pronouns,
    this.occupation,
    this.headline,
    this.city,
    this.state,
    this.relationshipStatus = const [],
    this.seeking = const [],
    this.partnerInvolvement,
    this.traits = const [],
    this.heatLevel = 'medium',
    this.hardLimits = const [],
    this.availability = const [],
    this.schedulingStyle,
    this.hostingStatus,
    this.travelRadius = 25,
    this.bandwidth = 0.5,
    this.discretionLevel,
    this.currentBio,
    this.currentHook,
    this.interests = const [],
    this.photoCount = 0,
    // Derived dimensions
    this.attachmentStyle = 'unknown',
    this.communicationArchetype = 'slow_burner',
    this.socialEnergyProfile = 'balanced_ambivert',
    this.intimacyBlueprint = 'open_and_adaptable',
    this.riskTolerance = 0.5,
    this.emotionalIntelligence = 0.5,
    this.intentionClarity = 0.5,
    this.lifestyleTemperature = 'balanced',
    // Behavioral signals
    this.ghostRate = 0,
    this.flakeRate = 0,
    this.responseRate = 0.5,
    this.avgResponseTime,
    this.messagesSent = 0,
    this.messagesReceived = 0,
    this.totalMatches = 0,
    this.activeConversations = 0,
    this.datesScheduled = 0,
    // Conversation intelligence
    this.avgMessageLength,
    this.questionRatio,
    this.emojiUsageRate,
    this.initiatesConversations = false,
    this.peakActivityHours = const [],
    // Game preferences
    this.preferredGameTypes = const [],
    this.preferredHeatInGames,
    this.gameCompletionRate,
    // Match intelligence
    this.typicalMatchTraits = const [],
    this.successfulMatchPatterns = const [],
    this.swipeSelectivity,
    // Timestamps
    this.profileCreatedAt,
    this.lastActiveAt,
  });

  // Identity
  final String userId;
  final String displayName;
  final int? age;
  final List<String> gender;
  final List<String> orientation;
  final String? pronouns;
  final String? occupation;
  final String? headline;
  final String? city;
  final String? state;

  // Relationship config
  final List<String> relationshipStatus;
  final List<String> seeking;
  final String? partnerInvolvement;

  // Preferences
  final List<String> traits;
  final String heatLevel;
  final List<String> hardLimits;

  // Logistics
  final List<String> availability;
  final String? schedulingStyle;
  final String? hostingStatus;
  final double travelRadius;
  final double bandwidth;
  final String? discretionLevel;

  // Content
  final String? currentBio;
  final String? currentHook;
  final List<String> interests;
  final int photoCount;

  // Derived psychological dimensions
  final String attachmentStyle;
  final String communicationArchetype;
  final String socialEnergyProfile;
  final String intimacyBlueprint;
  final double riskTolerance;
  final double emotionalIntelligence;
  final double intentionClarity;
  final String lifestyleTemperature;

  // Behavioral metrics
  final double ghostRate;
  final double flakeRate;
  final double responseRate;
  final double? avgResponseTime;
  final int messagesSent;
  final int messagesReceived;
  final int totalMatches;
  final int activeConversations;
  final int datesScheduled;

  // Conversation patterns
  final double? avgMessageLength;
  final double? questionRatio;
  final double? emojiUsageRate;
  final bool initiatesConversations;
  final List<int> peakActivityHours;

  // Game preferences
  final List<String> preferredGameTypes;
  final String? preferredHeatInGames;
  final double? gameCompletionRate;

  // Match intelligence
  final List<String> typicalMatchTraits;
  final List<String> successfulMatchPatterns;
  final double? swipeSelectivity;

  // Timestamps
  final DateTime? profileCreatedAt;
  final DateTime? lastActiveAt;

  /// Is this a new user with limited data?
  bool get isNewUser => messagesSent < 5 && totalMatches < 3;

  /// Has enough behavior data for meaningful analysis?
  bool get hasBehaviorData => messagesSent > 10 || totalMatches > 5;

  /// Profile completeness score (0-1)
  double get profileCompleteness {
    int filled = 0;
    int total = 10;
    if (displayName.isNotEmpty) filled++;
    if (currentBio != null && currentBio!.length > 20) filled++;
    if (currentHook != null && currentHook!.isNotEmpty) filled++;
    if (traits.length >= 3) filled++;
    if (interests.isNotEmpty) filled++;
    if (seeking.isNotEmpty) filled++;
    if (photoCount >= 2) filled++;
    if (hardLimits.isNotEmpty) filled++;
    if (occupation != null) filled++;
    if (headline != null) filled++;
    return filled / total;
  }

  /// Build a rich context brief for LLM prompts.
  /// This replaces the shallow "name + tags" approach.
  String toContextBrief() {
    final parts = <String>[];

    // Core identity
    parts.add('Name: $displayName');
    if (age != null) parts.add('Age: $age');
    if (gender.isNotEmpty) parts.add('Gender: ${gender.join(", ")}');
    if (orientation.isNotEmpty) parts.add('Orientation: ${orientation.join(", ")}');
    if (occupation != null) parts.add('Occupation: $occupation');
    if (city != null) parts.add('Location: $city${state != null ? ", $state" : ""}');

    // Relationship context
    if (relationshipStatus.isNotEmpty) {
      parts.add('Relationship status: ${relationshipStatus.join(", ")}');
    }
    if (seeking.isNotEmpty) parts.add('Seeking: ${seeking.join(", ")}');
    if (partnerInvolvement != null) parts.add('Partner involvement: $partnerInvolvement');

    // Personality dimensions
    parts.add('Selected personality traits: ${traits.join(", ")}');
    if (interests.isNotEmpty) parts.add('Interests: ${interests.join(", ")}');
    parts.add('Heat level: $heatLevel');
    if (hardLimits.isNotEmpty) parts.add('Hard limits: ${hardLimits.join(", ")}');

    // Derived psychology
    parts.add('Attachment style: $attachmentStyle');
    parts.add('Communication archetype: $communicationArchetype');
    parts.add('Social energy: $socialEnergyProfile');
    parts.add('Intimacy blueprint: $intimacyBlueprint');
    parts.add('Risk tolerance: ${(riskTolerance * 100).toInt()}%');
    parts.add('Lifestyle temperature: $lifestyleTemperature');

    // Logistics (personality signals)
    if (schedulingStyle != null) parts.add('Scheduling: $schedulingStyle');
    if (hostingStatus != null) parts.add('Hosting: $hostingStatus');
    parts.add('Travel radius: ${travelRadius.toInt()} miles');
    parts.add('Bandwidth: ${(bandwidth * 100).toInt()}%');

    // Behavior (if available)
    if (hasBehaviorData) {
      parts.add('\n--- Behavioral Data ---');
      parts.add('Ghost rate: ${(ghostRate * 100).toInt()}%');
      parts.add('Response rate: ${(responseRate * 100).toInt()}%');
      parts.add('Messages sent: $messagesSent, received: $messagesReceived');
      parts.add('Total matches: $totalMatches, active conversations: $activeConversations');
      parts.add('Dates scheduled: $datesScheduled');
      parts.add('Emotional intelligence estimate: ${(emotionalIntelligence * 100).toInt()}%');
      parts.add('Intention clarity: ${(intentionClarity * 100).toInt()}%');
      if (initiatesConversations) parts.add('Tends to initiate conversations');
    }

    // Current content (for improvement context)
    if (currentBio != null && currentBio!.isNotEmpty) {
      parts.add('\nCurrent bio: "$currentBio"');
    }
    if (currentHook != null && currentHook!.isNotEmpty) {
      parts.add('Current hook: "$currentHook"');
    }

    return parts.join('\n');
  }
}
