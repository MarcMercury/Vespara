import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// MESSAGE COACH - Subtle Real-time Suggestions
/// ════════════════════════════════════════════════════════════════════════════
///
/// As user types, gentle suggestions appear:
/// - Tone analysis (too cold? too eager?)
/// - Alternative phrasings
/// - Emoji suggestions
///
/// NEVER blocks sending - just helpful hints
/// User can toggle on/off globally

class MessageCoachService {
  static MessageCoachService? _instance;
  static MessageCoachService get instance =>
      _instance ??= MessageCoachService._();

  MessageCoachService._();

  final AIService _aiService = AIService.instance;

  // Debounce timer for real-time analysis
  Timer? _debounceTimer;
  final Duration _debounceDelay = const Duration(milliseconds: 800);

  // Cache recent analyses to avoid redundant calls
  final Map<String, MessageAnalysis> _analysisCache = {};
  final int _maxCacheSize = 20;

  // User preference
  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;
  set isEnabled(bool value) => _isEnabled = value;

  // ═══════════════════════════════════════════════════════════════════════════
  // REAL-TIME ANALYSIS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyze message as user types (debounced)
  void analyzeWhileTyping(
    String text,
    void Function(MessageAnalysis?) onResult,
  ) {
    if (!_isEnabled || text.length < 10) {
      onResult(null);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () async {
      final analysis = await analyzeMessage(text);
      onResult(analysis);
    });
  }

  /// Full analysis of a message
  Future<MessageAnalysis?> analyzeMessage(String text) async {
    if (!_isEnabled) return null;
    if (text.length < 10) return null;

    // Check cache
    final cacheKey = text.toLowerCase().trim();
    if (_analysisCache.containsKey(cacheKey)) {
      return _analysisCache[cacheKey];
    }

    // Quick local checks first (instant feedback)
    final quickChecks = _performQuickChecks(text);
    if (quickChecks != null) {
      _cacheAnalysis(cacheKey, quickChecks);
      return quickChecks;
    }

    // AI analysis for nuanced feedback
    final analysis = await _performAIAnalysis(text);
    if (analysis != null) {
      _cacheAnalysis(cacheKey, analysis);
    }

    return analysis;
  }

  /// Cancel any pending analysis
  void cancelPending() {
    _debounceTimer?.cancel();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK LOCAL CHECKS (Instant)
  // ═══════════════════════════════════════════════════════════════════════════

  MessageAnalysis? _performQuickChecks(String text) {
    final checks = <CoachingTip>[];

    // Check for all caps (shouting)
    if (_isAllCaps(text) && text.length > 5) {
      checks.add(CoachingTip(
        type: TipType.warning,
        message: 'All caps can feel like shouting �',
        suggestion: text[0] + text.substring(1).toLowerCase(),
      ));
    }

    // Check for too many exclamation marks
    final exclamationCount = '!'.allMatches(text).length;
    if (exclamationCount > 2) {
      checks.add(CoachingTip(
        type: TipType.gentle,
        message: 'Easy on the exclamation marks 🤭',
      ));
    }

    // Check for overly short response
    if (text.length < 20 && !text.contains('?')) {
      checks.add(CoachingTip(
        type: TipType.suggestion,
        message: 'Maybe add a question to keep the intrigue going?',
      ));
    }

    // Check for double/triple texting (multiple question marks)
    if (text.contains('???') || text.contains('...?')) {
      checks.add(CoachingTip(
        type: TipType.gentle,
        message: 'One question mark is enough 😏',
        suggestion: text.replaceAll(RegExp(r'\?+'), '?'),
      ));
    }

    // Check for "k" or "ok" as full response
    final trimmed = text.trim().toLowerCase();
    if (trimmed == 'k' || trimmed == 'ok' || trimmed == 'kk') {
      checks.add(CoachingTip(
        type: TipType.warning,
        message: 'This might seem cold - add some warmth? 🥀',
        suggestion: 'Okay, sounds good!',
      ));
    }

    // Check for excessive emojis
    final emojiCount = _countEmojis(text);
    if (emojiCount > 5) {
      checks.add(CoachingTip(
        type: TipType.gentle,
        message: 'Less is more with emojis ✧',
      ));
    }

    if (checks.isEmpty) return null;

    return MessageAnalysis(
      originalText: text,
      tone: _detectBasicTone(text),
      tips: checks,
    );
  }

  bool _isAllCaps(String text) {
    final letters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    return letters.length > 3 && letters == letters.toUpperCase();
  }

  int _countEmojis(String text) {
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|'  // Emoticons
      r'[\u{1F300}-\u{1F5FF}]|'  // Symbols & Pictographs
      r'[\u{1F680}-\u{1F6FF}]|'  // Transport & Map
      r'[\u{2600}-\u{26FF}]|'    // Misc symbols
      r'[\u{2700}-\u{27BF}]',    // Dingbats
      unicode: true,
    );
    return emojiRegex.allMatches(text).length;
  }

  MessageTone _detectBasicTone(String text) {
    final lower = text.toLowerCase();

    if (_isAllCaps(text)) return MessageTone.intense;
    if (lower.contains('sorry') || lower.contains('my bad')) return MessageTone.apologetic;
    if (text.contains('!') && text.contains('?')) return MessageTone.enthusiastic;
    if (lower.contains('lol') || lower.contains('haha')) return MessageTone.playful;
    if (text.length < 10) return MessageTone.brief;

    return MessageTone.neutral;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI ANALYSIS (Deeper Insights)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<MessageAnalysis?> _performAIAnalysis(String text) async {
    final result = await _aiService.chat(
      systemPrompt: '''Analyze this dating app message for tone and effectiveness.
Return a JSON object with:
- tone: one of [warm, cold, playful, serious, nervous, confident, neutral]
- score: 1-10 (how likely to get positive response)
- tip: one short suggestion (under 50 chars) or null if message is good
- alternative: a better version if score < 7, else null

Be encouraging, not critical. Only suggest improvements if clearly needed.''',
      prompt: '''Message: "$text"

Analyze:''',
      maxTokens: 150,
    );

    return result.fold(
      onSuccess: (response) => _parseAIAnalysis(text, response.content),
      onFailure: (_) => null,
    );
  }

  MessageAnalysis? _parseAIAnalysis(String originalText, String response) {
    try {
      // Simple parsing (AI might not return perfect JSON)
      final tips = <CoachingTip>[];
      MessageTone tone = MessageTone.neutral;
      int score = 7;
      String? alternative;

      // Parse tone
      if (response.contains('warm')) tone = MessageTone.warm;
      else if (response.contains('cold')) tone = MessageTone.cold;
      else if (response.contains('playful')) tone = MessageTone.playful;
      else if (response.contains('nervous')) tone = MessageTone.nervous;
      else if (response.contains('confident')) tone = MessageTone.confident;

      // Parse score
      final scoreMatch = RegExp(r'"score"\s*:\s*(\d+)').firstMatch(response);
      if (scoreMatch != null) {
        score = int.tryParse(scoreMatch.group(1) ?? '7') ?? 7;
      }

      // Parse tip
      final tipMatch = RegExp(r'"tip"\s*:\s*"([^"]+)"').firstMatch(response);
      if (tipMatch != null && score < 8) {
        tips.add(CoachingTip(
          type: TipType.suggestion,
          message: tipMatch.group(1)!,
        ));
      }

      // Parse alternative
      final altMatch = RegExp(r'"alternative"\s*:\s*"([^"]+)"').firstMatch(response);
      if (altMatch != null && score < 7) {
        alternative = altMatch.group(1);
        tips.add(CoachingTip(
          type: TipType.suggestion,
          message: 'Try this instead?',
          suggestion: alternative,
        ));
      }

      // Don't show anything if message is good
      if (score >= 8 && tips.isEmpty) return null;

      return MessageAnalysis(
        originalText: originalText,
        tone: tone,
        score: score,
        tips: tips,
        suggestedRewrite: alternative,
      );
    } catch (e) {
      debugPrint('MessageCoach: Failed to parse AI response - $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK SUGGESTIONS (No Analysis Needed)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get emoji suggestions for a message
  List<String> getEmojiSuggestions(String text) {
    final lower = text.toLowerCase();
    final suggestions = <String>[];

    if (lower.contains('happy') || lower.contains('glad')) {
      suggestions.addAll(['😊', '🎉', '✨']);
    }
    if (lower.contains('sad') || lower.contains('miss')) {
      suggestions.addAll(['🥺', '💙', '🫂']);
    }
    if (lower.contains('laugh') || lower.contains('funny')) {
      suggestions.addAll(['😂', '🤣', '😆']);
    }
    if (lower.contains('love') || lower.contains('like')) {
      suggestions.addAll(['❤️', '😍', '💕']);
    }
    if (lower.contains('food') || lower.contains('eat') || lower.contains('dinner')) {
      suggestions.addAll(['🍕', '🍜', '😋']);
    }
    if (lower.contains('drink') || lower.contains('coffee') || lower.contains('bar')) {
      suggestions.addAll(['☕', '🍷', '🍻']);
    }

    return suggestions.take(3).toList();
  }

  /// Get quick response suggestions based on received message
  List<String> getQuickResponses(String receivedMessage) {
    final lower = receivedMessage.toLowerCase();

    // Question responses
    if (lower.contains('how are you') || lower.contains("how's it going")) {
      return [
        "I'm good! How about you?",
        "Pretty great actually! You?",
        "Living my best life 😎 You?",
      ];
    }

    if (lower.contains('what are you up to') || lower.contains('what are you doing')) {
      return [
        "Just relaxing, thinking about you 😊",
        "Nothing much, wishing I was hanging with you",
        "Procrastinating... the usual 😅",
      ];
    }

    if (lower.contains('lol') || lower.contains('haha')) {
      return [
        "😂",
        "Glad I could make you laugh!",
        "I try 😎",
      ];
    }

    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _cacheAnalysis(String key, MessageAnalysis analysis) {
    if (_analysisCache.length >= _maxCacheSize) {
      _analysisCache.remove(_analysisCache.keys.first);
    }
    _analysisCache[key] = analysis;
  }

  void clearCache() {
    _analysisCache.clear();
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum MessageTone {
  warm,
  cold,
  playful,
  serious,
  nervous,
  confident,
  enthusiastic,
  apologetic,
  brief,
  intense,
  neutral,
}

enum TipType {
  suggestion,  // Helpful idea
  gentle,      // Soft nudge
  warning,     // Might want to reconsider
}

class MessageAnalysis {
  final String originalText;
  final MessageTone tone;
  final int score;
  final List<CoachingTip> tips;
  final String? suggestedRewrite;

  MessageAnalysis({
    required this.originalText,
    required this.tone,
    this.score = 7,
    this.tips = const [],
    this.suggestedRewrite,
  });

  bool get hasIssues => tips.isNotEmpty;
  bool get needsWork => score < 6;
  bool get isGood => score >= 8;

  String get toneEmoji {
    switch (tone) {
      case MessageTone.warm:
        return '🌸';
      case MessageTone.cold:
        return '❄️';
      case MessageTone.playful:
        return '😜';
      case MessageTone.serious:
        return '🤔';
      case MessageTone.nervous:
        return '😅';
      case MessageTone.confident:
        return '😎';
      case MessageTone.enthusiastic:
        return '🎉';
      case MessageTone.apologetic:
        return '🥺';
      case MessageTone.brief:
        return '💬';
      case MessageTone.intense:
        return '🔥';
      case MessageTone.neutral:
        return '😊';
    }
  }

  String get toneLabel {
    switch (tone) {
      case MessageTone.warm:
        return 'Warm & friendly';
      case MessageTone.cold:
        return 'A bit cold';
      case MessageTone.playful:
        return 'Playful';
      case MessageTone.serious:
        return 'Serious';
      case MessageTone.nervous:
        return 'Seems nervous';
      case MessageTone.confident:
        return 'Confident';
      case MessageTone.enthusiastic:
        return 'Enthusiastic!';
      case MessageTone.apologetic:
        return 'Apologetic';
      case MessageTone.brief:
        return 'Brief';
      case MessageTone.intense:
        return 'Intense';
      case MessageTone.neutral:
        return 'Neutral';
    }
  }
}

class CoachingTip {
  final TipType type;
  final String message;
  final String? suggestion;

  CoachingTip({
    required this.type,
    required this.message,
    this.suggestion,
  });

  String get typeEmoji {
    switch (type) {
      case TipType.suggestion:
        return '💡';
      case TipType.gentle:
        return '🌸';
      case TipType.warning:
        return '⚠️';
    }
  }
}
