import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';
import 'background_pregeneration_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// INSTANT CONVERSATION STARTERS - Tap to Send
/// ════════════════════════════════════════════════════════════════════════════
///
/// Zero effort for users:
/// - Open a chat → 3 personalized starters appear instantly
/// - Tap one → it's sent (or inserted for editing)
/// - No thinking about what to say

class InstantConversationStarters {
  static InstantConversationStarters? _instance;
  static InstantConversationStarters get instance =>
      _instance ??= InstantConversationStarters._();

  InstantConversationStarters._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService.instance;
  final BackgroundPregenerationService _pregen = BackgroundPregenerationService.instance;

  // Cache starters per match for instant display
  final Map<String, List<ConversationStarter>> _startersCache = {};
  final Duration _cacheExpiry = const Duration(hours: 2);
  final Map<String, DateTime> _cacheTimestamps = {};

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // GET STARTERS - Instant Display
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get 3 conversation starters for a match - instant if cached
  Future<List<ConversationStarter>> getStarters(String matchId) async {
    // Check cache
    if (_isCacheValid(matchId)) {
      return _startersCache[matchId]!;
    }

    // Get both profiles
    final match = await _getMatchProfiles(matchId);
    if (match == null) return _getFallbackStarters();

    final otherProfile = match['other_profile'] as Map<String, dynamic>;
    final myProfile = match['my_profile'] as Map<String, dynamic>;

    // Try pregenerated first for instant response
    final pregenStarters = _getPregenStarters(otherProfile);
    if (pregenStarters.isNotEmpty) {
      _cacheStarters(matchId, pregenStarters);
      return pregenStarters;
    }

    // Generate personalized starters
    final starters = await _generatePersonalizedStarters(myProfile, otherProfile);
    _cacheStarters(matchId, starters);

    return starters;
  }

  /// Get starters for first message (when chat is empty)
  Future<List<ConversationStarter>> getFirstMessageStarters(String matchId) async {
    final starters = await getStarters(matchId);

    // Mark as first message type
    return starters.map((s) => ConversationStarter(
      text: s.text,
      type: StarterType.firstMessage,
      reason: s.reason,
      basedOn: s.basedOn,
    )).toList();
  }

  /// Get starters to revive a dying conversation
  Future<List<ConversationStarter>> getRevivalStarters(String matchId) async {
    final match = await _getMatchProfiles(matchId);
    if (match == null) return _getGenericRevivalStarters();

    final otherProfile = match['other_profile'] as Map<String, dynamic>;

    final result = await _aiService.chat(
      systemPrompt: '''Generate 3 messages to naturally restart a conversation that's gone quiet.
Be casual, not desperate. Reference something from their profile if possible.
Keep each under 80 characters. One per line, no numbering.''',
      prompt: '''Their profile:
Name: ${otherProfile['display_name']}
Interests: ${(otherProfile['interests'] as List?)?.join(', ') ?? 'not listed'}

Generate 3 revival messages:''',
      maxTokens: 150,
    );

    return result.fold(
      onSuccess: (response) {
        return response.content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .take(3)
            .map((text) => ConversationStarter(
                  text: text.trim(),
                  type: StarterType.revival,
                  reason: 'Restart the conversation',
                ))
            .toList();
      },
      onFailure: (_) => _getGenericRevivalStarters(),
    );
  }

  /// Get follow-up starters based on conversation context
  Future<List<ConversationStarter>> getFollowUpStarters({
    required String matchId,
    required String lastMessage,
  }) async {
    final result = await _aiService.chat(
      systemPrompt: '''Generate 3 natural follow-up responses to continue this conversation.
Be engaging and ask questions when appropriate.
Keep each under 100 characters. One per line, no numbering.''',
      prompt: '''Last message received: "$lastMessage"

Generate 3 follow-up responses:''',
      maxTokens: 150,
    );

    return result.fold(
      onSuccess: (response) {
        return response.content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .take(3)
            .map((text) => ConversationStarter(
                  text: text.trim(),
                  type: StarterType.followUp,
                  reason: 'Continue the conversation',
                ))
            .toList();
      },
      onFailure: (_) => [],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SMART GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<ConversationStarter>> _generatePersonalizedStarters(
    Map<String, dynamic> myProfile,
    Map<String, dynamic> otherProfile,
  ) async {
    final sharedInterests = _findSharedInterests(
      myProfile['interests'] as List?,
      otherProfile['interests'] as List?,
    );

    final result = await _aiService.generateIceBreakers(
      profile1Context: _buildProfileContext(myProfile),
      profile2Context: _buildProfileContext(otherProfile),
      count: 3,
    );

    return result.fold(
      onSuccess: (iceBreakers) {
        return iceBreakers.asMap().entries.map((entry) {
          final index = entry.key;
          final text = entry.value;

          String? basedOn;
          String reason;

          if (index == 0 && sharedInterests.isNotEmpty) {
            basedOn = sharedInterests.first;
            reason = 'You both like ${sharedInterests.first}';
          } else if (index == 1) {
            reason = 'Based on their profile';
          } else {
            reason = 'Fun and engaging';
          }

          return ConversationStarter(
            text: text,
            type: StarterType.firstMessage,
            reason: reason,
            basedOn: basedOn,
          );
        }).toList();
      },
      onFailure: (_) => _getFallbackStarters(),
    );
  }

  List<ConversationStarter> _getPregenStarters(Map<String, dynamic> profile) {
    final starters = <ConversationStarter>[];

    // Check interests
    final interests = profile['interests'] as List?;
    if (interests != null && interests.isNotEmpty) {
      final interest = interests.first.toString().toLowerCase();

      // Map common interests to scenarios
      if (interest.contains('travel') || interest.contains('adventure')) {
        final pregen = _pregen.getIceBreaker('adventurous');
        if (pregen != null) {
          starters.add(ConversationStarter(
            text: pregen,
            type: StarterType.firstMessage,
            reason: 'You both seem adventurous',
            basedOn: interest,
          ));
        }
      }

      if (interest.contains('book') || interest.contains('read')) {
        final pregen = _pregen.getIceBreaker('intellectual');
        if (pregen != null) {
          starters.add(ConversationStarter(
            text: pregen,
            type: StarterType.firstMessage,
            reason: 'Based on shared interests',
            basedOn: interest,
          ));
        }
      }
    }

    // Add generic starters if needed
    if (starters.length < 3) {
      final casual = _pregen.getIceBreaker('casual');
      if (casual != null) {
        starters.add(ConversationStarter(
          text: casual,
          type: StarterType.firstMessage,
          reason: 'Great conversation starter',
        ));
      }
    }

    return starters.take(3).toList();
  }

  List<String> _findSharedInterests(List? list1, List? list2) {
    if (list1 == null || list2 == null) return [];

    final set1 = list1.map((e) => e.toString().toLowerCase()).toSet();
    final set2 = list2.map((e) => e.toString().toLowerCase()).toSet();

    return set1.intersection(set2).toList();
  }

  String _buildProfileContext(Map<String, dynamic> profile) {
    final parts = <String>[];

    if (profile['display_name'] != null) {
      parts.add('Name: ${profile['display_name']}');
    }
    if (profile['bio'] != null) {
      parts.add('Bio: ${profile['bio']}');
    }
    if (profile['interests'] != null) {
      parts.add('Interests: ${(profile['interests'] as List).join(', ')}');
    }
    if (profile['occupation'] != null) {
      parts.add('Job: ${profile['occupation']}');
    }

    return parts.join('\n');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FALLBACKS
  // ═══════════════════════════════════════════════════════════════════════════

  List<ConversationStarter> _getFallbackStarters() {
    return [
      ConversationStarter(
        text: "Hey! What's been the highlight of your week so far?",
        type: StarterType.firstMessage,
        reason: 'Great conversation starter',
      ),
      ConversationStarter(
        text: "Hi! I'm curious - what made you swipe right? 😊",
        type: StarterType.firstMessage,
        reason: 'Fun and engaging',
      ),
      ConversationStarter(
        text: "Hey! If you could be anywhere in the world right now, where would you go?",
        type: StarterType.firstMessage,
        reason: 'Opens up interesting conversation',
      ),
    ];
  }

  List<ConversationStarter> _getGenericRevivalStarters() {
    return [
      ConversationStarter(
        text: "Hey! How's your week been going?",
        type: StarterType.revival,
        reason: 'Casual check-in',
      ),
      ConversationStarter(
        text: "Just thought of you - what have you been up to?",
        type: StarterType.revival,
        reason: 'Warm and friendly',
      ),
      ConversationStarter(
        text: "Any fun plans for the weekend?",
        type: StarterType.revival,
        reason: 'Easy conversation starter',
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _getMatchProfiles(String matchId) async {
    if (_userId == null) return null;

    try {
      final match = await _supabase
          .from('matches')
          .select('''
            id,
            user1_id,
            user2_id,
            user1:profiles!matches_user1_id_fkey(id, display_name, bio, interests, occupation, photos),
            user2:profiles!matches_user2_id_fkey(id, display_name, bio, interests, occupation, photos)
          ''')
          .eq('id', matchId)
          .maybeSingle();

      if (match == null) return null;

      final isUser1 = match['user1_id'] == _userId;

      return {
        'my_profile': isUser1 ? match['user1'] : match['user2'],
        'other_profile': isUser1 ? match['user2'] : match['user1'],
      };
    } catch (e) {
      debugPrint('InstantStarters: Failed to get profiles - $e');
      return null;
    }
  }

  bool _isCacheValid(String matchId) {
    if (!_startersCache.containsKey(matchId)) return false;

    final timestamp = _cacheTimestamps[matchId];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  void _cacheStarters(String matchId, List<ConversationStarter> starters) {
    _startersCache[matchId] = starters;
    _cacheTimestamps[matchId] = DateTime.now();
  }

  /// Clear cache for a match (e.g., after they respond)
  void clearCache(String matchId) {
    _startersCache.remove(matchId);
    _cacheTimestamps.remove(matchId);
  }

  /// Clear all caches
  void clearAllCaches() {
    _startersCache.clear();
    _cacheTimestamps.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum StarterType {
  firstMessage,
  revival,
  followUp,
  topicChange,
}

class ConversationStarter {
  final String text;
  final StarterType type;
  final String? reason;
  final String? basedOn;

  ConversationStarter({
    required this.text,
    required this.type,
    this.reason,
    this.basedOn,
  });

  String get typeLabel {
    switch (type) {
      case StarterType.firstMessage:
        return 'Great opener';
      case StarterType.revival:
        return 'Restart the chat';
      case StarterType.followUp:
        return 'Keep it going';
      case StarterType.topicChange:
        return 'New topic';
    }
  }
}
