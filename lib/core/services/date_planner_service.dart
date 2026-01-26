import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DATE PLANNING ASSISTANT - Zero Effort Date Ideas
/// ════════════════════════════════════════════════════════════════════════════
///
/// User taps "Plan a date" → instant personalized suggestions
/// No forms, no questions - AI uses existing profile data
/// One tap to share a date idea with match

class DatePlannerService {
  DatePlannerService._();
  static DatePlannerService? _instance;
  static DatePlannerService get instance =>
      _instance ??= DatePlannerService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService.instance;

  // Cache date ideas per match
  final Map<String, List<DateIdea>> _ideasCache = {};
  final Duration _cacheExpiry = const Duration(hours: 6);
  final Map<String, DateTime> _cacheTimestamps = {};

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // GET DATE IDEAS - Instant Suggestions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get 3 personalized date ideas for a match - instant if cached
  Future<List<DateIdea>> getDateIdeas(String matchId) async {
    // Check cache
    if (_isCacheValid(matchId)) {
      return _ideasCache[matchId]!;
    }

    // Get both profiles
    final match = await _getMatchData(matchId);
    if (match == null) return _getFallbackIdeas();

    final myProfile = match['my_profile'] as Map<String, dynamic>;
    final otherProfile = match['other_profile'] as Map<String, dynamic>;
    final previousDates = match['previous_dates'] as List? ?? [];

    // Generate personalized ideas
    final ideas = await _generateDateIdeas(
      myProfile: myProfile,
      otherProfile: otherProfile,
      previousDates: previousDates,
    );

    _cacheIdeas(matchId, ideas);
    return ideas;
  }

  /// Get ideas for a specific vibe/mood
  Future<List<DateIdea>> getDateIdeasByVibe({
    required String matchId,
    required DateVibe vibe,
  }) async {
    final match = await _getMatchData(matchId);
    if (match == null) return _getFallbackIdeas();

    final myProfile = match['my_profile'] as Map<String, dynamic>;
    final otherProfile = match['other_profile'] as Map<String, dynamic>;

    return _generateVibeIdeas(
      vibe: vibe,
      myProfile: myProfile,
      otherProfile: otherProfile,
    );
  }

  /// Quick date idea categories (no AI needed - instant)
  List<DateCategory> getCategories() => [
        DateCategory(
          id: 'adventure',
          name: 'Adventure',
          emoji: '🎢',
          description: 'Get the adrenaline pumping',
        ),
        DateCategory(
          id: 'chill',
          name: 'Chill',
          emoji: '☕',
          description: 'Low-key and relaxed',
        ),
        DateCategory(
          id: 'foodie',
          name: 'Foodie',
          emoji: '🍕',
          description: 'Great food, great vibes',
        ),
        DateCategory(
          id: 'creative',
          name: 'Creative',
          emoji: '🎨',
          description: 'Make something together',
        ),
        DateCategory(
          id: 'outdoors',
          name: 'Outdoors',
          emoji: '🌲',
          description: 'Fresh air and nature',
        ),
        DateCategory(
          id: 'nightlife',
          name: 'Nightlife',
          emoji: '🌃',
          description: 'After dark adventures',
        ),
      ];

  // ═══════════════════════════════════════════════════════════════════════════
  // AI GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<DateIdea>> _generateDateIdeas({
    required Map<String, dynamic> myProfile,
    required Map<String, dynamic> otherProfile,
    required List previousDates,
  }) async {
    final myInterests = (myProfile['interests'] as List?)?.join(', ') ?? '';
    final theirInterests =
        (otherProfile['interests'] as List?)?.join(', ') ?? '';
    final previousActivities = previousDates
        .map((d) => d['activity'] as String?)
        .where((a) => a != null)
        .join(', ');

    final result = await _aiService.chat(
      systemPrompt: '''Generate 3 unique date ideas based on these profiles.
For each idea, provide:
1. A catchy title (under 30 chars)
2. One sentence description (under 100 chars)
3. Category: adventure/chill/foodie/creative/outdoors/nightlife
4. Estimated cost: \$ (cheap), \$\$ (moderate), \$\$\$ (fancy)
5. Time of day: morning/afternoon/evening/night

Format each idea on separate lines as:
TITLE|DESCRIPTION|CATEGORY|COST|TIME

Be creative and specific. Avoid generic suggestions.''',
      prompt: '''Your interests: $myInterests
Their interests: $theirInterests
${previousActivities.isNotEmpty ? 'Previous dates: $previousActivities (avoid repeating)' : ''}

Generate 3 personalized date ideas:''',
      maxTokens: 300,
    );

    return result.fold(
      onSuccess: (response) => _parseIdeas(response.content),
      onFailure: (_) => _getFallbackIdeas(),
    );
  }

  Future<List<DateIdea>> _generateVibeIdeas({
    required DateVibe vibe,
    required Map<String, dynamic> myProfile,
    required Map<String, dynamic> otherProfile,
  }) async {
    final vibeDescription = _getVibeDescription(vibe);

    final result = await _aiService.chat(
      systemPrompt:
          '''Generate 3 date ideas matching this vibe: $vibeDescription
For each idea, provide:
TITLE|DESCRIPTION|CATEGORY|COST|TIME

Keep titles under 30 chars, descriptions under 100 chars.''',
      prompt: '''Generate 3 ${vibe.name} date ideas:''',
      maxTokens: 250,
    );

    return result.fold(
      onSuccess: (response) => _parseIdeas(response.content),
      onFailure: (_) => _getFallbackIdeas(),
    );
  }

  List<DateIdea> _parseIdeas(String response) {
    final ideas = <DateIdea>[];
    final lines = response.split('\n').where((l) => l.contains('|')).toList();

    for (final line in lines.take(3)) {
      final parts = line.split('|');
      if (parts.length >= 5) {
        ideas.add(
          DateIdea(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: parts[0].trim(),
            description: parts[1].trim(),
            category: _parseCategory(parts[2].trim()),
            cost: parts[3].trim(),
            timeOfDay: parts[4].trim(),
          ),
        );
      }
    }

    if (ideas.isEmpty) return _getFallbackIdeas();
    return ideas;
  }

  String _parseCategory(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('adventure')) return 'adventure';
    if (lower.contains('chill')) return 'chill';
    if (lower.contains('food')) return 'foodie';
    if (lower.contains('creative')) return 'creative';
    if (lower.contains('outdoor')) return 'outdoors';
    if (lower.contains('night')) return 'nightlife';
    return 'chill';
  }

  String _getVibeDescription(DateVibe vibe) {
    switch (vibe) {
      case DateVibe.romantic:
        return 'Intimate and romantic, perfect for connection';
      case DateVibe.fun:
        return 'Playful and exciting, lots of laughs';
      case DateVibe.casual:
        return 'Low-pressure and easy-going';
      case DateVibe.impressive:
        return 'Memorable and special, leave a lasting impression';
      case DateVibe.cheap:
        return 'Budget-friendly but still amazing';
      case DateVibe.quick:
        return 'Short and sweet, 1-2 hours max';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARE DATE IDEA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a message to share the date idea with match
  String getShareMessage(DateIdea idea) =>
      'Hey! I had an idea - want to ${idea.title.toLowerCase()}? 🎉';

  /// Generate a more detailed pitch
  Future<String> getDetailedPitch(DateIdea idea) async {
    final result = await _aiService.chat(
      systemPrompt:
          '''Write a casual, fun message inviting someone on this date.
Keep it under 100 characters. Be enthusiastic but not over the top.''',
      prompt: '''Date idea: ${idea.title} - ${idea.description}

Write an invite message:''',
      maxTokens: 50,
    );

    return result.fold(
      onSuccess: (response) => response.content.trim(),
      onFailure: (_) => getShareMessage(idea),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE & TRACK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save a date idea to match history
  Future<void> saveDateIdea({
    required String matchId,
    required DateIdea idea,
    String? notes,
  }) async {
    if (_userId == null) return;

    try {
      await _supabase.from('match_dates').insert({
        'match_id': matchId,
        'created_by': _userId,
        'title': idea.title,
        'description': idea.description,
        'category': idea.category,
        'status': 'suggested',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('DatePlanner: Failed to save idea - $e');
    }
  }

  /// Mark a date as completed
  Future<void> markDateCompleted({
    required String dateId,
    int? rating,
    String? review,
  }) async {
    try {
      await _supabase.from('match_dates').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'rating': rating,
        'review': review,
      }).eq('id', dateId);
    } catch (e) {
      debugPrint('DatePlanner: Failed to mark complete - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FALLBACKS
  // ═══════════════════════════════════════════════════════════════════════════

  List<DateIdea> _getFallbackIdeas() => [
        DateIdea(
          id: '1',
          title: 'Coffee & People Watching',
          description: 'Find a cozy café and make up stories about strangers',
          category: 'chill',
          cost: '\$',
          timeOfDay: 'afternoon',
        ),
        DateIdea(
          id: '2',
          title: 'Sunset Picnic',
          description: 'Grab takeout and find a spot with a view',
          category: 'outdoors',
          cost: '\$\$',
          timeOfDay: 'evening',
        ),
        DateIdea(
          id: '3',
          title: 'Arcade Throwback',
          description: 'Challenge each other to classic games',
          category: 'fun',
          cost: '\$',
          timeOfDay: 'evening',
        ),
      ];

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _getMatchData(String matchId) async {
    if (_userId == null) return null;

    try {
      final match = await _supabase.from('matches').select('''
            id,
            user1_id,
            user2_id,
            user1:profiles!matches_user1_id_fkey(id, display_name, interests, location),
            user2:profiles!matches_user2_id_fkey(id, display_name, interests, location)
          ''').eq('id', matchId).maybeSingle();

      if (match == null) return null;

      final isUser1 = match['user1_id'] == _userId;

      // Get previous dates if table exists
      List previousDates = [];
      try {
        previousDates = await _supabase
            .from('match_dates')
            .select('title, category, status')
            .eq('match_id', matchId)
            .eq('status', 'completed')
            .limit(5);
      } catch (_) {
        // Table might not exist yet
      }

      return {
        'my_profile': isUser1 ? match['user1'] : match['user2'],
        'other_profile': isUser1 ? match['user2'] : match['user1'],
        'previous_dates': previousDates,
      };
    } catch (e) {
      debugPrint('DatePlanner: Failed to get match data - $e');
      return null;
    }
  }

  bool _isCacheValid(String matchId) {
    if (!_ideasCache.containsKey(matchId)) return false;
    final timestamp = _cacheTimestamps[matchId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  void _cacheIdeas(String matchId, List<DateIdea> ideas) {
    _ideasCache[matchId] = ideas;
    _cacheTimestamps[matchId] = DateTime.now();
  }

  void clearCache(String? matchId) {
    if (matchId != null) {
      _ideasCache.remove(matchId);
      _cacheTimestamps.remove(matchId);
    } else {
      _ideasCache.clear();
      _cacheTimestamps.clear();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum DateVibe {
  romantic,
  fun,
  casual,
  impressive,
  cheap,
  quick,
}

class DateIdea {
  DateIdea({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.cost,
    required this.timeOfDay,
  });
  final String id;
  final String title;
  final String description;
  final String category;
  final String cost;
  final String timeOfDay;

  String get categoryEmoji {
    switch (category) {
      case 'adventure':
        return '🎢';
      case 'chill':
        return '☕';
      case 'foodie':
        return '🍕';
      case 'creative':
        return '🎨';
      case 'outdoors':
        return '🌲';
      case 'nightlife':
        return '🌃';
      default:
        return '✨';
    }
  }

  String get timeEmoji {
    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        return '🌅';
      case 'afternoon':
        return '☀️';
      case 'evening':
        return '🌆';
      case 'night':
        return '🌙';
      default:
        return '⏰';
    }
  }
}

class DateCategory {
  DateCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });
  final String id;
  final String name;
  final String emoji;
  final String description;
}
