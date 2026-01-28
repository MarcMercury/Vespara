import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// MATCH INSIGHTS - AI-Powered Compatibility at a Glance
/// ════════════════════════════════════════════════════════════════════════════
///
/// Zero effort for users:
/// - Match card shows instant insight ("You both love hiking! 🥾")
/// - Profile view shows detailed compatibility breakdown
/// - No clicks needed - insights are always visible

class MatchInsightsService {
  MatchInsightsService._();
  static MatchInsightsService? _instance;
  static MatchInsightsService get instance =>
      _instance ??= MatchInsightsService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService.instance;

  // Cache insights per user for instant display
  final Map<String, MatchInsight> _insightsCache = {};
  final Duration _cacheExpiry = const Duration(hours: 24);
  final Map<String, DateTime> _cacheTimestamps = {};

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK INSIGHT - For Match Cards
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get a single-line insight for a match card display
  /// This is instant - uses local comparison first, AI if needed
  Future<String> getQuickInsight(Map<String, dynamic> otherProfile) async {
    final otherUserId = otherProfile['id'] as String?;
    if (otherUserId == null) return '';

    // Check cache
    final cached = _getCachedInsight(otherUserId);
    if (cached != null) return cached.quickInsight;

    // Generate locally for speed
    final myProfile = await _getMyProfile();
    if (myProfile == null) return '';

    final insight = _generateLocalInsight(myProfile, otherProfile);

    // Cache it
    _cacheInsight(
      otherUserId,
      MatchInsight(
        quickInsight: insight.quickInsight,
        compatibility: insight.compatibility,
        sharedInterests: insight.sharedInterests,
        uniqueTraits: insight.uniqueTraits,
      ),
    );

    return insight.quickInsight;
  }

  /// Get quick insight synchronously if cached, or empty string
  String getQuickInsightSync(String otherUserId) {
    final cached = _getCachedInsight(otherUserId);
    return cached?.quickInsight ?? '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DETAILED INSIGHT - For Profile View
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get full insight breakdown for a profile view
  Future<MatchInsight> getDetailedInsight(String otherUserId) async {
    // Check cache
    final cached = _getCachedInsight(otherUserId);
    if (cached != null && cached.aiInsight != null) return cached;

    // Get both profiles
    final profiles = await _getBothProfiles(otherUserId);
    if (profiles == null) return MatchInsight.empty();

    final myProfile = profiles['my_profile']!;
    final otherProfile = profiles['other_profile']!;

    // Get local insights first (fast)
    final localInsight = _generateLocalInsight(myProfile, otherProfile);

    // Enhance with AI for deeper insight
    final aiInsight = await _generateAIInsight(myProfile, otherProfile);

    final fullInsight = MatchInsight(
      quickInsight: localInsight.quickInsight,
      compatibility: localInsight.compatibility,
      sharedInterests: localInsight.sharedInterests,
      uniqueTraits: localInsight.uniqueTraits,
      aiInsight: aiInsight,
      conversationTopics: await _suggestTopics(myProfile, otherProfile),
    );

    _cacheInsight(otherUserId, fullInsight);
    return fullInsight;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCAL GENERATION - Instant, No AI Needed
  // ═══════════════════════════════════════════════════════════════════════════

  LocalInsight _generateLocalInsight(
    Map<String, dynamic> myProfile,
    Map<String, dynamic> otherProfile,
  ) {
    final myInterests = (myProfile['interests'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toSet() ??
        {};
    final theirInterests = (otherProfile['interests'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toSet() ??
        {};

    // Find shared interests
    final shared = myInterests.intersection(theirInterests).toList();

    // Find unique things about them
    final unique = theirInterests.difference(myInterests).take(3).toList();

    // Calculate basic compatibility
    double compatibility = 0.5; // Base

    // Shared interests boost
    if (shared.isNotEmpty) {
      compatibility += 0.1 * shared.length.clamp(0, 3);
    }

    // Generate quick insight
    String quickInsight;
    if (shared.isNotEmpty) {
      quickInsight = _formatSharedInsight(shared.first);
    } else if (unique.isNotEmpty) {
      quickInsight = _formatUniqueInsight(unique.first, otherProfile);
    } else {
      quickInsight = _getGenericInsight(otherProfile);
    }

    return LocalInsight(
      quickInsight: quickInsight,
      compatibility: compatibility.clamp(0.0, 1.0),
      sharedInterests: shared,
      uniqueTraits: unique,
    );
  }

  String _formatSharedInsight(String interest) {
    final formatted = _capitalize(interest);
    final emoji = _getInterestEmoji(interest);

    // Randomize format slightly
    final formats = [
      'You both love $formatted! $emoji',
      '$formatted fans unite! $emoji',
      'A match made in $formatted! $emoji',
      'You share a passion for $formatted $emoji',
    ];

    return formats[DateTime.now().millisecond % formats.length];
  }

  String _formatUniqueInsight(String trait, Map<String, dynamic> profile) {
    final name = profile['display_name'] ?? 'They';
    final formatted = _capitalize(trait);
    final emoji = _getInterestEmoji(trait);

    return '$name is into $formatted $emoji - ask about it!';
  }

  String _getGenericInsight(Map<String, dynamic> profile) {
    final occupation = profile['occupation'];
    final name = profile['display_name'] ?? 'They';

    if (occupation != null) {
      return '$name works in $occupation 💼';
    }

    return 'New match! Start a conversation 💬';
  }

  String _getInterestEmoji(String interest) {
    final emojiMap = {
      'travel': '✈️',
      'hiking': '🥾',
      'cooking': '👨‍🍳',
      'music': '🎵',
      'movies': '🎬',
      'reading': '📚',
      'fitness': '💪',
      'yoga': '🧘',
      'gaming': '🎮',
      'photography': '📷',
      'art': '🎨',
      'dancing': '💃',
      'food': '🍕',
      'coffee': '☕',
      'wine': '🍷',
      'dogs': '🐕',
      'cats': '🐱',
      'nature': '🌿',
      'beach': '🏖️',
      'sports': '⚽',
      'running': '🏃',
      'swimming': '🏊',
      'skiing': '⛷️',
      'camping': '🏕️',
      'adventure': '🗺️',
    };

    for (final entry in emojiMap.entries) {
      if (interest.contains(entry.key)) {
        return entry.value;
      }
    }
    return '✨';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI ENHANCEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> _generateAIInsight(
    Map<String, dynamic> myProfile,
    Map<String, dynamic> otherProfile,
  ) async {
    final result = await _aiService.chat(
      systemPrompt: '''Analyze these two dating profiles and write a brief, 
insightful compatibility observation. Be specific about what makes them a good match.
Focus on personality traits, lifestyle, or values alignment.
Keep it to 1-2 sentences, warm and encouraging.''',
      prompt: '''Profile 1:
${_buildProfileContext(myProfile)}

Profile 2:
${_buildProfileContext(otherProfile)}

Compatibility insight:''',
      maxTokens: 100,
    );

    return result.when(
      success: (response) => response.content.trim(),
      failure: (_) => null,
    );
  }

  Future<List<String>> _suggestTopics(
    Map<String, dynamic> myProfile,
    Map<String, dynamic> otherProfile,
  ) async {
    final result = await _aiService.chat(
      systemPrompt: '''Suggest 3 conversation topics based on these profiles.
Each should be specific and actionable.
Keep each under 50 characters. One per line, no numbering.''',
      prompt:
          '''Profile 1 interests: ${(myProfile['interests'] as List?)?.join(', ') ?? 'not listed'}
Profile 2 interests: ${(otherProfile['interests'] as List?)?.join(', ') ?? 'not listed'}

3 conversation topics:''',
      maxTokens: 100,
    );

    return result.when(
      success: (response) => response.content
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(3)
          .toList(),
      failure: (_) => [],
    );
  }

  String _buildProfileContext(Map<String, dynamic> profile) {
    final parts = <String>[];

    if (profile['bio'] != null) {
      parts.add('Bio: ${profile['bio']}');
    }
    if (profile['interests'] != null) {
      parts.add('Interests: ${(profile['interests'] as List).join(', ')}');
    }
    if (profile['occupation'] != null) {
      parts.add('Job: ${profile['occupation']}');
    }
    if (profile['looking_for'] != null) {
      parts.add('Looking for: ${profile['looking_for']}');
    }

    return parts.isNotEmpty ? parts.join('\n') : 'No profile details';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH PREFETCH - For Discovery Feed
  // ═══════════════════════════════════════════════════════════════════════════

  /// Prefetch insights for multiple profiles at once
  Future<void> prefetchInsights(List<Map<String, dynamic>> profiles) async {
    final myProfile = await _getMyProfile();
    if (myProfile == null) return;

    for (final profile in profiles) {
      final userId = profile['id'] as String?;
      if (userId == null) continue;
      if (_getCachedInsight(userId) != null) continue;

      final insight = _generateLocalInsight(myProfile, profile);
      _cacheInsight(
        userId,
        MatchInsight(
          quickInsight: insight.quickInsight,
          compatibility: insight.compatibility,
          sharedInterests: insight.sharedInterests,
          uniqueTraits: insight.uniqueTraits,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _getMyProfile() async {
    if (_userId == null) return null;

    try {
      return await _supabase
          .from('profiles')
          .select('id, display_name, bio, interests, occupation, looking_for')
          .eq('id', _userId!)
          .maybeSingle();
    } catch (e) {
      debugPrint('MatchInsights: Failed to get my profile - $e');
      return null;
    }
  }

  Future<Map<String, Map<String, dynamic>>?> _getBothProfiles(
    String otherUserId,
  ) async {
    final myProfile = await _getMyProfile();
    if (myProfile == null) return null;

    try {
      final otherProfile = await _supabase
          .from('profiles')
          .select(
              'id, display_name, bio, interests, occupation, looking_for, photos',)
          .eq('id', otherUserId)
          .maybeSingle();

      if (otherProfile == null) return null;

      return {
        'my_profile': myProfile,
        'other_profile': otherProfile,
      };
    } catch (e) {
      debugPrint('MatchInsights: Failed to get other profile - $e');
      return null;
    }
  }

  MatchInsight? _getCachedInsight(String userId) {
    if (!_insightsCache.containsKey(userId)) return null;

    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _insightsCache.remove(userId);
      _cacheTimestamps.remove(userId);
      return null;
    }

    return _insightsCache[userId];
  }

  void _cacheInsight(String userId, MatchInsight insight) {
    _insightsCache[userId] = insight;
    _cacheTimestamps[userId] = DateTime.now();
  }

  void clearCache() {
    _insightsCache.clear();
    _cacheTimestamps.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class MatchInsight {
  MatchInsight({
    required this.quickInsight,
    required this.compatibility,
    required this.sharedInterests,
    required this.uniqueTraits,
    this.aiInsight,
    this.conversationTopics = const [],
  });

  factory MatchInsight.empty() => MatchInsight(
        quickInsight: '',
        compatibility: 0.5,
        sharedInterests: [],
        uniqueTraits: [],
      );
  final String quickInsight;
  final double compatibility;
  final List<String> sharedInterests;
  final List<String> uniqueTraits;
  final String? aiInsight;
  final List<String> conversationTopics;

  bool get hasSharedInterests => sharedInterests.isNotEmpty;
  bool get hasAIInsight => aiInsight != null && aiInsight!.isNotEmpty;

  String get compatibilityLabel {
    if (compatibility >= 0.8) return 'Great match!';
    if (compatibility >= 0.6) return 'Good potential';
    if (compatibility >= 0.4) return 'Worth exploring';
    return 'New connection';
  }

  String get compatibilityEmoji {
    if (compatibility >= 0.8) return '🔥';
    if (compatibility >= 0.6) return '⭐';
    if (compatibility >= 0.4) return '✨';
    return '💫';
  }
}

class LocalInsight {
  LocalInsight({
    required this.quickInsight,
    required this.compatibility,
    required this.sharedInterests,
    required this.uniqueTraits,
  });
  final String quickInsight;
  final double compatibility;
  final List<String> sharedInterests;
  final List<String> uniqueTraits;
}
