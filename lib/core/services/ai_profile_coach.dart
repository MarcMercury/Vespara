import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';
import 'background_pregeneration_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// AI PROFILE COACH - One-Tap Bio Improvement
/// ════════════════════════════════════════════════════════════════════════════
///
/// Zero effort for users:
/// - Tap "Improve" → instantly see 3 options
/// - Tap an option → it's applied
/// - No forms, no typing, no thinking required

class AIProfileCoach {
  AIProfileCoach._();
  static AIProfileCoach? _instance;
  static AIProfileCoach get instance => _instance ??= AIProfileCoach._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService.instance;
  final BackgroundPregenerationService _pregen =
      BackgroundPregenerationService.instance;

  // Cache generated content for instant display
  final Map<String, List<String>> _bioOptionsCache = {};
  final Map<String, List<String>> _promptAnswersCache = {};

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // BIO IMPROVEMENT - One Tap, Three Options
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get 3 improved bio options instantly
  /// Returns cached options if available, generates if not
  Future<List<BioOption>> getImprovedBios() async {
    // Check cache first for instant display
    if (_bioOptionsCache.containsKey(_userId)) {
      return _bioOptionsCache[_userId]!
          .map(
            (bio) => BioOption(
              text: bio,
              style: _detectStyle(bio),
            ),
          )
          .toList();
    }

    // Get current bio for context
    final currentBio = await _getCurrentBio();
    final profile = await _getProfileContext();

    // Generate 3 different styles
    final styles = ['witty', 'sincere', 'adventurous'];
    final options = <BioOption>[];

    for (final style in styles) {
      // Try pregenerated content first
      final pregen = _pregen.getBioSuggestions(style);
      if (pregen.isNotEmpty) {
        options.add(
          BioOption(
            text: _personalize(pregen.first, profile),
            style: style,
          ),
        );
        continue;
      }

      // Generate fresh
      final result = await _aiService.generateBio(
        userContext: _buildBioContext(currentBio, profile),
        style: style,
      );

      result.fold(
        onSuccess: (bio) {
          options.add(BioOption(text: bio, style: style));
        },
        onFailure: (_) {
          // Skip this style if generation fails
        },
      );
    }

    // Cache for next time
    if (options.isNotEmpty) {
      _bioOptionsCache[_userId ?? ''] = options.map((o) => o.text).toList();
    }

    return options;
  }

  /// Apply selected bio with one tap
  Future<bool> applyBio(String newBio) async {
    if (_userId == null) return false;

    try {
      await _supabase
          .from('profiles')
          .update({'bio': newBio}).eq('id', _userId!);

      // Clear cache so next improvement is fresh
      _bioOptionsCache.remove(_userId);

      return true;
    } catch (e) {
      debugPrint('AIProfileCoach: Failed to apply bio - $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMPT ANSWERS - Instant Suggestions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get 3 answers for a profile prompt (e.g., "I'm looking for...")
  Future<List<String>> getPromptAnswers(String prompt) async {
    final cacheKey = '${_userId}_$prompt';

    // Check cache
    if (_promptAnswersCache.containsKey(cacheKey)) {
      return _promptAnswersCache[cacheKey]!;
    }

    final profile = await _getProfileContext();

    final result = await _aiService.chat(
      systemPrompt:
          '''Generate 3 short, authentic answers for a dating profile prompt.
Each answer should be:
- Different in tone (witty, sincere, playful)
- Under 100 characters
- Genuine and engaging
Return one per line, no numbering.''',
      prompt: '''Prompt: "$prompt"
User context: ${profile['display_name']}, ${profile['age']}, interests: ${profile['interest_tags']}
Generate 3 answers:''',
      maxTokens: 200,
    );

    return result.fold(
      onSuccess: (response) {
        final answers = response.content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .take(3)
            .toList();

        _promptAnswersCache[cacheKey] = answers;
        return answers;
      },
      onFailure: (_) => <String>[],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTO TIPS - Non-Intrusive Suggestions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get photo improvement tip (shown subtly, not blocking)
  Future<String?> getPhotoTip() async {
    final profile = await _getProfileContext();
    final photos = profile['photos'] as List? ?? [];

    if (photos.isEmpty) {
      return 'Add your first photo to start matching!';
    }

    if (photos.length == 1) {
      return 'Profiles with 3+ photos get 2x more matches';
    }

    if (photos.length < 4) {
      return 'Add a photo showing your hobby or passion';
    }

    // Could add AI photo analysis here in future
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTEREST SUGGESTIONS - One Tap to Add
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get suggested interests based on profile and popular trends
  Future<List<String>> getSuggestedInterests() async {
    final profile = await _getProfileContext();
    final currentInterests = List<String>.from(profile['interest_tags'] ?? []);

    try {
      // Get popular interests
      final popular = await _supabase.rpc(
        'get_popular_interests',
        params: {
          'p_limit': 20,
        },
      ).catchError((_) => <dynamic>[]);

      // Filter out ones user already has
      final suggestions = (popular as List)
          .map((i) => i.toString())
          .where((i) => !currentInterests.contains(i))
          .take(6)
          .toList();

      return suggestions;
    } catch (e) {
      return [];
    }
  }

  /// Add interest with one tap
  Future<bool> addInterest(String interest) async {
    if (_userId == null) return false;

    try {
      final profile = await _getProfileContext();
      final interests = List<String>.from(profile['interest_tags'] ?? []);

      if (!interests.contains(interest)) {
        interests.add(interest);

        await _supabase
            .from('profiles')
            .update({'interest_tags': interests}).eq('id', _userId!);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> _getCurrentBio() async {
    if (_userId == null) return null;

    final profile = await _supabase
        .from('profiles')
        .select('bio')
        .eq('id', _userId!)
        .maybeSingle();

    return profile?['bio'] as String?;
  }

  Future<Map<String, dynamic>> _getProfileContext() async {
    if (_userId == null) return {};

    final profile = await _supabase
        .from('profiles')
        .select('display_name, age, interest_tags, occupation, education')
        .eq('id', _userId!)
        .maybeSingle();

    return profile ?? {};
  }

  String _buildBioContext(String? currentBio, Map<String, dynamic> profile) {
    final parts = <String>[];

    if (profile['display_name'] != null) {
      parts.add('Name: ${profile['display_name']}');
    }
    if (profile['age'] != null) {
      parts.add('Age: ${profile['age']}');
    }
    if (profile['occupation'] != null) {
      parts.add('Job: ${profile['occupation']}');
    }
    if (profile['interest_tags'] != null) {
      parts.add('Interests: ${(profile['interest_tags'] as List).join(', ')}');
    }
    if (currentBio != null && currentBio.isNotEmpty) {
      parts.add('Current bio: $currentBio');
    }

    return parts.join('\n');
  }

  String _personalize(String template, Map<String, dynamic> profile) {
    // Replace placeholders with actual values
    var result = template;

    if (profile['occupation'] != null) {
      result = result.replaceAll('[job]', profile['occupation']);
      result = result.replaceAll('[occupation]', profile['occupation']);
    }

    if (profile['interest_tags'] != null) {
      final interests = profile['interest_tags'] as List;
      if (interests.isNotEmpty) {
        result = result.replaceAll('[interest]', interests.first.toString());
        result = result.replaceAll('[hobby]', interests.first.toString());
      }
    }

    return result;
  }

  String _detectStyle(String bio) {
    final lower = bio.toLowerCase();
    if (lower.contains('!') || lower.contains('😂') || lower.contains('lol')) {
      return 'witty';
    }
    if (lower.contains('love') ||
        lower.contains('genuine') ||
        lower.contains('looking for')) {
      return 'sincere';
    }
    return 'adventurous';
  }

  /// Clear caches (call when user updates profile manually)
  void clearCaches() {
    _bioOptionsCache.clear();
    _promptAnswersCache.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class BioOption {
  BioOption({required this.text, required this.style});
  final String text;
  final String style;

  String get styleEmoji {
    switch (style) {
      case 'witty':
        return '😄';
      case 'sincere':
        return '💝';
      case 'adventurous':
        return '🌟';
      default:
        return '✨';
    }
  }

  String get styleLabel {
    switch (style) {
      case 'witty':
        return 'Fun & Witty';
      case 'sincere':
        return 'Warm & Sincere';
      case 'adventurous':
        return 'Bold & Adventurous';
      default:
        return 'Creative';
    }
  }
}
