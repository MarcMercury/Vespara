import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DYNAMIC GAME GENERATION - AI Creates Prompts That Know You
/// ════════════════════════════════════════════════════════════════════════════
///
/// The magic: Game prompts that feel personally written for each couple
/// - Learns from conversation history
/// - Understands couple's dynamic (playful, deep, flirty...)
/// - References inside jokes and shared interests
/// - Gets better the more they play
///
/// User perception: "How does this game know us so well?"

class DynamicGameGenerator {
  static DynamicGameGenerator? _instance;
  static DynamicGameGenerator get instance =>
      _instance ??= DynamicGameGenerator._();

  DynamicGameGenerator._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService.instance;
  final Random _random = Random();

  // Cache generated prompts per couple
  final Map<String, List<DynamicPrompt>> _promptCache = {};
  final Duration _cacheExpiry = const Duration(hours: 4);
  final Map<String, DateTime> _cacheTimestamps = {};

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATE PERSONALIZED PROMPTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate prompts tailored to this specific couple
  Future<List<DynamicPrompt>> generatePromptsForCouple({
    required String matchId,
    required GameType gameType,
    required int count,
    int? heatLevel,
  }) async {
    final cacheKey = '$matchId:${gameType.name}:${heatLevel ?? 'any'}';

    // Check cache
    if (_isCacheValid(cacheKey) && _promptCache[cacheKey]!.length >= count) {
      return _promptCache[cacheKey]!.take(count).toList();
    }

    // Gather couple context
    final context = await _gatherCoupleContext(matchId);
    if (context == null) {
      return _getFallbackPrompts(gameType, count, heatLevel);
    }

    // Generate personalized prompts
    final prompts = await _generateWithAI(
      gameType: gameType,
      context: context,
      count: count + 3, // Generate extra for variety
      heatLevel: heatLevel,
    );

    _cachePrompts(cacheKey, prompts);
    return prompts.take(count).toList();
  }

  /// Get a single prompt that references something specific
  Future<DynamicPrompt?> generateContextualPrompt({
    required String matchId,
    required GameType gameType,
    required String specificContext,
    int? heatLevel,
  }) async {
    final context = await _gatherCoupleContext(matchId);

    final result = await _aiService.chat(
      systemPrompt: _getSystemPrompt(gameType, heatLevel),
      prompt: '''Create ONE game prompt that specifically references: "$specificContext"

Couple context:
${context?.summary ?? 'New couple, keep it general but warm'}

The prompt should feel personally crafted for them.
Just the prompt text, nothing else.''',
      maxTokens: 100,
    );

    return result.fold(
      onSuccess: (response) => DynamicPrompt(
        text: response.content.trim(),
        gameType: gameType,
        heatLevel: heatLevel ?? 2,
        isPersonalized: true,
        basedOn: specificContext,
      ),
      onFailure: (_) => null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPLE CONTEXT GATHERING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<CoupleContext?> _gatherCoupleContext(String matchId) async {
    if (_userId == null) return null;

    try {
      // Get match and profiles
      final match = await _supabase
          .from('matches')
          .select('''
            id, created_at,
            user1:profiles!matches_user1_id_fkey(id, display_name, interests, bio),
            user2:profiles!matches_user2_id_fkey(id, display_name, interests, bio)
          ''')
          .eq('id', matchId)
          .maybeSingle();

      if (match == null) return null;

      final isUser1 = match['user1']['id'] == _userId;
      final myProfile = isUser1 ? match['user1'] : match['user2'];
      final theirProfile = isUser1 ? match['user2'] : match['user1'];

      // Get recent messages for context
      final messages = await _supabase
          .from('messages')
          .select('content, sender_id, created_at')
          .eq('match_id', matchId)
          .order('created_at', ascending: false)
          .limit(30);

      // Extract conversation themes
      final conversationThemes = _extractThemes(messages as List);

      // Get game history for this couple
      List gameHistory = [];
      try {
        gameHistory = await _supabase
            .from('couple_game_history')
            .select('game_type, prompt_text, reaction')
            .eq('match_id', matchId)
            .order('played_at', ascending: false)
            .limit(20);
      } catch (_) {
        // Table might not exist
      }

      // Find shared interests
      final myInterests = (myProfile['interests'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toSet() ??
          {};
      final theirInterests = (theirProfile['interests'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toSet() ??
          {};
      final sharedInterests = myInterests.intersection(theirInterests).toList();

      // Detect relationship dynamic
      final dynamic = _detectDynamic(messages as List);

      return CoupleContext(
        matchId: matchId,
        myName: myProfile['display_name'] ?? 'You',
        theirName: theirProfile['display_name'] ?? 'Them',
        sharedInterests: sharedInterests,
        conversationThemes: conversationThemes,
        favoritePrompts: _extractFavorites(gameHistory),
        dislikedPrompts: _extractDislikes(gameHistory),
        relationshipDynamic: dynamic,
        messageCount: (messages as List).length,
        daysTogether: DateTime.now()
            .difference(DateTime.parse(match['created_at']))
            .inDays,
      );
    } catch (e) {
      debugPrint('DynamicGameGen: Failed to gather context - $e');
      return null;
    }
  }

  List<String> _extractThemes(List messages) {
    final allText = messages
        .map((m) => (m['content'] ?? '').toString().toLowerCase())
        .join(' ');

    final themes = <String>[];

    // Travel mentions
    if (allText.contains('travel') ||
        allText.contains('trip') ||
        allText.contains('vacation')) {
      themes.add('travel');
    }

    // Food mentions
    if (allText.contains('food') ||
        allText.contains('restaurant') ||
        allText.contains('cook') ||
        allText.contains('dinner')) {
      themes.add('food');
    }

    // Music mentions
    if (allText.contains('music') ||
        allText.contains('concert') ||
        allText.contains('song')) {
      themes.add('music');
    }

    // Movies/shows
    if (allText.contains('movie') ||
        allText.contains('show') ||
        allText.contains('netflix') ||
        allText.contains('watch')) {
      themes.add('entertainment');
    }

    // Future plans
    if (allText.contains('someday') ||
        allText.contains('future') ||
        allText.contains('want to') ||
        allText.contains('would love')) {
      themes.add('dreams');
    }

    // Past experiences
    if (allText.contains('remember when') ||
        allText.contains('that time') ||
        allText.contains('once I')) {
      themes.add('memories');
    }

    return themes;
  }

  RelationshipDynamic _detectDynamic(List messages) {
    final allText = messages
        .map((m) => (m['content'] ?? '').toString().toLowerCase())
        .join(' ');

    // Count indicators
    int playfulScore = 0;
    int deepScore = 0;
    int flirtyScore = 0;

    // Playful indicators
    if (allText.contains('lol') || allText.contains('haha')) playfulScore += 2;
    if (allText.contains('😂') || allText.contains('🤣')) playfulScore += 2;
    if (allText.contains('joke') || allText.contains('funny')) playfulScore += 1;

    // Deep indicators
    if (allText.contains('feel') || allText.contains('think about')) deepScore += 2;
    if (allText.contains('believe') || allText.contains('value')) deepScore += 2;
    if (allText.contains('life') || allText.contains('meaning')) deepScore += 1;

    // Flirty indicators
    if (allText.contains('😏') || allText.contains('😘')) flirtyScore += 2;
    if (allText.contains('cute') || allText.contains('hot')) flirtyScore += 2;
    if (allText.contains('miss you') || allText.contains('can\'t wait')) flirtyScore += 1;

    if (playfulScore > deepScore && playfulScore > flirtyScore) {
      return RelationshipDynamic.playful;
    }
    if (deepScore > playfulScore && deepScore > flirtyScore) {
      return RelationshipDynamic.deep;
    }
    if (flirtyScore > playfulScore && flirtyScore > deepScore) {
      return RelationshipDynamic.flirty;
    }

    return RelationshipDynamic.balanced;
  }

  List<String> _extractFavorites(List gameHistory) {
    return gameHistory
        .where((g) => g['reaction'] == 'loved' || g['reaction'] == 'liked')
        .map((g) => g['prompt_text'] as String)
        .take(5)
        .toList();
  }

  List<String> _extractDislikes(List gameHistory) {
    return gameHistory
        .where((g) => g['reaction'] == 'skipped' || g['reaction'] == 'disliked')
        .map((g) => g['prompt_text'] as String)
        .take(5)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<DynamicPrompt>> _generateWithAI({
    required GameType gameType,
    required CoupleContext context,
    required int count,
    int? heatLevel,
  }) async {
    final result = await _aiService.chat(
      systemPrompt: _getSystemPrompt(gameType, heatLevel),
      prompt: '''Generate $count personalized game prompts for this couple:

THEIR CONTEXT:
- Names: ${context.myName} & ${context.theirName}
- Shared interests: ${context.sharedInterests.join(', ')}
- Conversation themes: ${context.conversationThemes.join(', ')}
- Relationship vibe: ${context.relationshipDynamic.name}
- Days together: ${context.daysTogether}
${context.favoritePrompts.isNotEmpty ? '- They loved prompts like: ${context.favoritePrompts.take(2).join('; ')}' : ''}
${context.dislikedPrompts.isNotEmpty ? '- Avoid topics like: ${context.dislikedPrompts.take(2).join('; ')}' : ''}

Make prompts that feel like they were written specifically for THIS couple.
Reference their interests and themes naturally.
One prompt per line, no numbering.''',
      maxTokens: 400,
    );

    return result.fold(
      onSuccess: (response) => _parsePrompts(response.content, gameType, heatLevel),
      onFailure: (_) => _getFallbackPrompts(gameType, count, heatLevel),
    );
  }

  String _getSystemPrompt(GameType gameType, int? heatLevel) {
    final heat = heatLevel ?? 2;

    switch (gameType) {
      case GameType.truthOrDare:
        return '''You create personalized Truth or Dare prompts for couples.
Heat level: $heat/5 (${_heatDescription(heat)})
Keep each prompt under 100 characters.
Make them feel personally crafted, not generic.''';

      case GameType.wouldYouRather:
        return '''You create personalized Would You Rather questions for couples.
Heat level: $heat/5 (${_heatDescription(heat)})
Both options should be genuinely interesting.
Keep each under 120 characters total.''';

      case GameType.neverHaveIEver:
        return '''You create personalized Never Have I Ever statements for couples.
Heat level: $heat/5 (${_heatDescription(heat)})
Mix revelations about past and hypotheticals.
Keep each under 80 characters.''';

      case GameType.iceBreakers:
        return '''You create personalized icebreaker questions for couples.
Keep them engaging and conversation-starting.
Each should reveal something interesting.
Keep each under 100 characters.''';

      case GameType.deepQuestions:
        return '''You create personalized deep questions for couples.
Focus on values, dreams, fears, and meaningful topics.
Make them thought-provoking but not heavy.
Keep each under 120 characters.''';

      case GameType.flirtyQuestions:
        return '''You create personalized flirty questions for couples.
Heat level: $heat/5 (${_heatDescription(heat)})
Playful, teasing, builds anticipation.
Keep each under 100 characters.''';
    }
  }

  String _heatDescription(int level) {
    switch (level) {
      case 1:
        return 'Very mild, first-date appropriate';
      case 2:
        return 'Playful, slightly flirty';
      case 3:
        return 'Moderately spicy, clearly romantic';
      case 4:
        return 'Hot, intimate territory';
      case 5:
        return 'Very hot, explicit allowed';
      default:
        return 'Playful and fun';
    }
  }

  List<DynamicPrompt> _parsePrompts(
    String response,
    GameType gameType,
    int? heatLevel,
  ) {
    return response
        .split('\n')
        .where((line) => line.trim().length > 10)
        .map((line) => DynamicPrompt(
              text: line.trim(),
              gameType: gameType,
              heatLevel: heatLevel ?? 2,
              isPersonalized: true,
            ))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FALLBACKS
  // ═══════════════════════════════════════════════════════════════════════════

  List<DynamicPrompt> _getFallbackPrompts(
    GameType gameType,
    int count,
    int? heatLevel,
  ) {
    final prompts = _getGenericPrompts(gameType, heatLevel ?? 2);
    prompts.shuffle(_random);
    return prompts.take(count).toList();
  }

  List<DynamicPrompt> _getGenericPrompts(GameType gameType, int heatLevel) {
    switch (gameType) {
      case GameType.truthOrDare:
        return [
          DynamicPrompt(text: "What's something you've never told anyone?", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "Dare: Send a voice message saying what you like about me", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "What was your first impression of me?", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "Dare: Share a childhood photo", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "What's your biggest dating pet peeve?", gameType: gameType, heatLevel: heatLevel),
        ];
      case GameType.wouldYouRather:
        return [
          DynamicPrompt(text: "Would you rather have a fancy dinner or a cozy night in?", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "Would you rather travel the world or build a dream home?", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "Would you rather know my thoughts or feel my emotions?", gameType: gameType, heatLevel: heatLevel),
        ];
      case GameType.neverHaveIEver:
        return [
          DynamicPrompt(text: "Never have I ever had a secret crush on a friend", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "Never have I ever been on a blind date", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "Never have I ever said 'I love you' first", gameType: gameType, heatLevel: heatLevel),
        ];
      case GameType.iceBreakers:
        return [
          DynamicPrompt(text: "What's something that always makes you smile?", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "If you could master any skill instantly, what would it be?", gameType: gameType, heatLevel: heatLevel),
        ];
      case GameType.deepQuestions:
        return [
          DynamicPrompt(text: "What's a belief you held that completely changed?", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "What does your ideal life look like in 10 years?", gameType: gameType, heatLevel: heatLevel),
        ];
      case GameType.flirtyQuestions:
        return [
          DynamicPrompt(text: "What's something about me that you find attractive?", gameType: gameType, heatLevel: heatLevel),
          DynamicPrompt(text: "What would your ideal date with me look like?", gameType: gameType, heatLevel: heatLevel),
        ];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isCacheValid(String key) {
    if (!_promptCache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  void _cachePrompts(String key, List<DynamicPrompt> prompts) {
    _promptCache[key] = prompts;
    _cacheTimestamps[key] = DateTime.now();
  }

  void clearCache() {
    _promptCache.clear();
    _cacheTimestamps.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum GameType {
  truthOrDare,
  wouldYouRather,
  neverHaveIEver,
  iceBreakers,
  deepQuestions,
  flirtyQuestions,
}

enum RelationshipDynamic {
  playful,
  deep,
  flirty,
  balanced,
}

class DynamicPrompt {
  final String text;
  final GameType gameType;
  final int heatLevel;
  final bool isPersonalized;
  final String? basedOn;

  DynamicPrompt({
    required this.text,
    required this.gameType,
    required this.heatLevel,
    this.isPersonalized = false,
    this.basedOn,
  });
}

class CoupleContext {
  final String matchId;
  final String myName;
  final String theirName;
  final List<String> sharedInterests;
  final List<String> conversationThemes;
  final List<String> favoritePrompts;
  final List<String> dislikedPrompts;
  final RelationshipDynamic relationshipDynamic;
  final int messageCount;
  final int daysTogether;

  CoupleContext({
    required this.matchId,
    required this.myName,
    required this.theirName,
    required this.sharedInterests,
    required this.conversationThemes,
    required this.favoritePrompts,
    required this.dislikedPrompts,
    required this.relationshipDynamic,
    required this.messageCount,
    required this.daysTogether,
  });

  String get summary {
    final parts = <String>[];

    if (sharedInterests.isNotEmpty) {
      parts.add('Shared interests: ${sharedInterests.take(3).join(', ')}');
    }
    if (conversationThemes.isNotEmpty) {
      parts.add('They talk about: ${conversationThemes.join(', ')}');
    }
    parts.add('Vibe: ${relationshipDynamic.name}');
    parts.add('$messageCount messages over $daysTogether days');

    return parts.join('. ');
  }
}
