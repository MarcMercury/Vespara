import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/env.dart';
import '../utils/result.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GEMINI SERVICE - Google Gemini AI Integration
/// ════════════════════════════════════════════════════════════════════════════
///
/// Gemini AI service with:
/// - Rate limiting to prevent cost explosion
/// - Response caching for repeated queries
/// - Token counting and budget management
/// - Multiple model support (Gemini 2.0 Flash, Pro, etc.)
/// - Fallback strategies

class GeminiService {
  GeminiService._();
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService._();

  // Model instances (lazy-initialized)
  GenerativeModel? _flashModel;
  GenerativeModel? _proModel;

  // Rate limiting
  final _rateLimiter = _GeminiRateLimiter(
    maxRequests: 60,
    window: const Duration(minutes: 1),
  );

  // Caching
  final Map<String, _CachedGeminiResponse> _cache = {};
  final Duration _cacheExpiry = const Duration(minutes: 30);

  // Token tracking
  int _totalTokensUsed = 0;
  int _tokenBudget = 100000; // Daily budget

  int get totalTokensUsed => _totalTokensUsed;
  int get remainingBudget => _tokenBudget - _totalTokensUsed;

  // ═══════════════════════════════════════════════════════════════════════════
  // MODEL ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  GenerativeModel _getModel(GeminiModel model) {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isEmpty) {
      throw AppError.validation(
        message: 'Gemini API key not configured.',
      );
    }

    switch (model) {
      case GeminiModel.flash:
        return _flashModel ??= GenerativeModel(
          model: model.id,
          apiKey: apiKey,
        );
      case GeminiModel.pro:
        return _proModel ??= GenerativeModel(
          model: model.id,
          apiKey: apiKey,
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT COMPLETION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send a prompt to Gemini and get a response
  Future<Result<GeminiResponse>> chat({
    required String prompt,
    String? systemPrompt,
    GeminiModel model = GeminiModel.flash,
    double temperature = 0.7,
    int? maxTokens,
    bool useCache = true,
    List<GeminiMessage>? conversationHistory,
  }) async {
    // Check rate limit
    if (!_rateLimiter.allowRequest()) {
      return Failure(
        AppError.rateLimited(
          message: 'Gemini request rate limit exceeded. Please wait.',
        ),
      );
    }

    // Check token budget
    if (remainingBudget <= 0) {
      return const Failure(
        AppError(
          message: 'Daily Gemini token budget exceeded.',
          type: ErrorType.rateLimited,
        ),
      );
    }

    // Check cache
    final cacheKey = _generateCacheKey(prompt, systemPrompt, model);
    if (useCache) {
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        debugPrint('GeminiService: Cache hit for prompt');
        return Success(cached);
      }
    }

    try {
      final genModel = _getModel(model);

      // Build content with optional system instruction and conversation history
      final contents = <Content>[];

      if (conversationHistory != null) {
        for (final msg in conversationHistory) {
          contents.add(Content(
            msg.role == GeminiRole.user ? 'user' : 'model',
            [TextPart(msg.content)],
          ));
        }
      }

      contents.add(Content('user', [TextPart(
        systemPrompt != null ? '$systemPrompt\n\n$prompt' : prompt,
      )]));

      final generationConfig = GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxTokens,
      );

      final result = await genModel.generateContent(
        contents,
        generationConfig: generationConfig,
      );

      final text = result.text ?? '';
      final tokenCount = text.length ~/ 4; // Approximate token count

      final response = GeminiResponse(
        content: text,
        promptTokens: prompt.length ~/ 4,
        completionTokens: tokenCount,
        totalTokens: (prompt.length ~/ 4) + tokenCount,
        finishReason: result.candidates.firstOrNull?.finishReason?.name,
      );

      // Track tokens
      _totalTokensUsed += response.totalTokens;

      // Cache successful response
      if (useCache) {
        _addToCache(cacheKey, response);
      }

      return Success(response);
    } catch (e, stack) {
      debugPrint('GeminiService error: $e\n$stack');
      return Failure(_transformError(e));
    }
  }

  /// Stream a Gemini response
  Stream<Result<String>> chatStream({
    required String prompt,
    String? systemPrompt,
    GeminiModel model = GeminiModel.flash,
    double temperature = 0.7,
  }) async* {
    if (!_rateLimiter.allowRequest()) {
      yield Failure(AppError.rateLimited());
      return;
    }

    try {
      final genModel = _getModel(model);
      final content = Content('user', [TextPart(
        systemPrompt != null ? '$systemPrompt\n\n$prompt' : prompt,
      )]);

      final generationConfig = GenerationConfig(temperature: temperature);

      final stream = genModel.generateContentStream(
        [content],
        generationConfig: generationConfig,
      );

      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          yield Success(text);
        }
      }
    } catch (e) {
      yield Failure(_transformError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIALIZED METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a bio/description
  Future<Result<String>> generateBio({
    required String userContext,
    required String style,
  }) async {
    final result = await chat(
      systemPrompt:
          '''You are a creative writer helping users craft engaging bios.
Style: $style
Keep it concise (2-3 sentences max), authentic, and engaging.
Don't use clichés or overused phrases.''',
      prompt: 'Create a bio based on: $userContext',
      maxTokens: 150,
    );

    return result.map((r) => r.content);
  }

  /// Generate conversation starters
  Future<Result<List<String>>> generateIceBreakers({
    required String profile1Context,
    required String profile2Context,
    int count = 3,
  }) async {
    final result = await chat(
      systemPrompt:
          '''You are a dating coach helping create genuine conversation starters.
Generate unique, thoughtful openers based on shared interests or profile details.
Avoid generic pickup lines. Be creative and authentic.
Return exactly $count options, one per line.''',
      prompt: '''
Person 1: $profile1Context
Person 2: $profile2Context

Generate $count conversation starters.''',
      maxTokens: 200,
    );

    return result.map(
      (r) => r.content
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^\d+[\.\)]\s*'), '').trim())
          .take(count)
          .toList(),
    );
  }

  /// Analyze message sentiment/toxicity
  Future<Result<GeminiMessageAnalysis>> analyzeMessage({
    required String message,
  }) async {
    final result = await chat(
      systemPrompt: '''Analyze the following message for:
1. Sentiment (positive/neutral/negative)
2. Toxicity score (0-1)
3. Flags (inappropriate, spam, harassment, none)

Respond in JSON format only:
{"sentiment": "...", "toxicity": 0.0, "flags": ["..."]}''',
      prompt: message,
      maxTokens: 100,
      temperature: 0.1,
    );

    return result.map((r) {
      try {
        // Extract JSON from response (Gemini may wrap in markdown)
        var content = r.content.trim();
        if (content.startsWith('```')) {
          content = content
              .replaceAll(RegExp(r'^```\w*\n?'), '')
              .replaceAll(RegExp(r'\n?```$'), '');
        }
        final json = Map<String, dynamic>.from(
          _parseJson(content) ?? {},
        );
        return GeminiMessageAnalysis(
          sentiment: json['sentiment'] as String? ?? 'neutral',
          toxicity: (json['toxicity'] as num?)?.toDouble() ?? 0.0,
          flags: List<String>.from(json['flags'] ?? []),
        );
      } catch (e) {
        return GeminiMessageAnalysis(
          sentiment: 'neutral',
          toxicity: 0.0,
          flags: [],
        );
      }
    });
  }

  /// Generate game content (prompts, questions)
  Future<Result<String>> generateGameContent({
    required String gameType,
    required String contentRating,
    required String context,
  }) async {
    final result = await chat(
      systemPrompt: '''You are creating content for adult party games.
Game: $gameType
Rating: $contentRating
Keep content appropriate for the rating level.
Be creative, fun, and engaging.''',
      prompt: context,
      maxTokens: 200,
    );

    return result.map((r) => r.content);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL
  // ═══════════════════════════════════════════════════════════════════════════

  dynamic _parseJson(String text) {
    try {
      final start = text.indexOf('{');
      if (start == -1) return null;
      // Find matching closing brace
      int depth = 0;
      for (int i = start; i < text.length; i++) {
        if (text[i] == '{') depth++;
        if (text[i] == '}') depth--;
        if (depth == 0) {
          return jsonDecode(text.substring(start, i + 1));
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _generateCacheKey(
      String prompt, String? systemPrompt, GeminiModel model) {
    final combined = '${model.id}|${systemPrompt ?? ''}|$prompt';
    return combined.hashCode.toString();
  }

  GeminiResponse? _getFromCache(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    if (DateTime.now().isAfter(cached.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return cached.response;
  }

  void _addToCache(String key, GeminiResponse response) {
    _cache[key] = _CachedGeminiResponse(
      response: response,
      expiresAt: DateTime.now().add(_cacheExpiry),
    );

    // Limit cache size
    if (_cache.length > 100) {
      final oldest = _cache.entries.first.key;
      _cache.remove(oldest);
    }
  }

  AppError _transformError(dynamic error) {
    if (error is AppError) return error;

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return AppError.timeout(originalError: error);
    }

    if (errorString.contains('socket') || errorString.contains('network')) {
      return AppError.network(originalError: error);
    }

    if (errorString.contains('api key') ||
        errorString.contains('unauthorized') ||
        errorString.contains('permission')) {
      return AppError.authentication(message: 'Invalid Gemini API key');
    }

    if (errorString.contains('quota') ||
        errorString.contains('rate') ||
        errorString.contains('limit')) {
      return AppError.rateLimited(message: 'Gemini rate limit exceeded');
    }

    return AppError.server(
      message: 'Gemini request failed: ${error.toString()}',
      originalError: error,
    );
  }

  /// Reset token usage (call daily)
  void resetTokenUsage() {
    _totalTokensUsed = 0;
    debugPrint('GeminiService: Token usage reset');
  }

  /// Set token budget
  void setTokenBudget(int budget) {
    _tokenBudget = budget;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    debugPrint('GeminiService: Cache cleared');
  }

  /// Dispose model instances
  void dispose() {
    _flashModel = null;
    _proModel = null;
    _cache.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RATE LIMITER
// ═══════════════════════════════════════════════════════════════════════════

class _GeminiRateLimiter {
  _GeminiRateLimiter({
    required this.maxRequests,
    required this.window,
  });
  final int maxRequests;
  final Duration window;
  final List<DateTime> _requests = [];

  bool allowRequest() {
    final now = DateTime.now();
    final windowStart = now.subtract(window);
    _requests.removeWhere((time) => time.isBefore(windowStart));

    if (_requests.length >= maxRequests) return false;

    _requests.add(now);
    return true;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum GeminiModel {
  flash('gemini-2.0-flash', 'Gemini 2.0 Flash'),
  pro('gemini-2.0-pro', 'Gemini 2.0 Pro');

  final String id;
  final String displayName;

  const GeminiModel(this.id, this.displayName);
}

enum GeminiRole {
  user,
  model,
}

class GeminiMessage {
  const GeminiMessage({required this.role, required this.content});
  final GeminiRole role;
  final String content;
}

class GeminiResponse {
  GeminiResponse({
    required this.content,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.finishReason,
  });

  final String content;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final String? finishReason;
}

class GeminiMessageAnalysis {
  GeminiMessageAnalysis({
    required this.sentiment,
    required this.toxicity,
    required this.flags,
  });
  final String sentiment;
  final double toxicity;
  final List<String> flags;

  bool get isAppropriate => toxicity < 0.5 && !flags.contains('inappropriate');
  bool get isSpam => flags.contains('spam');
  bool get isHarassment => flags.contains('harassment');
}

class _CachedGeminiResponse {
  _CachedGeminiResponse({required this.response, required this.expiresAt});
  final GeminiResponse response;
  final DateTime expiresAt;
}
