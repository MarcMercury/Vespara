import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../utils/result.dart';
import '../utils/retry.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// AI SERVICE - Unified LLM Integration
/// ════════════════════════════════════════════════════════════════════════════
///
/// Production-ready AI service with:
/// - Rate limiting to prevent cost explosion
/// - Response caching for repeated queries
/// - Token counting and budget management
/// - Streaming support for long responses
/// - Multiple model support (GPT-4, GPT-3.5, etc.)
/// - Fallback strategies

class AIService {
  AIService._();
  static AIService? _instance;
  static AIService get instance => _instance ??= AIService._();

  // Configuration
  final String _baseUrl = 'https://api.openai.com/v1';
  final Duration _timeout = const Duration(seconds: 60);

  // Rate limiting
  final _rateLimiter = RateLimiter(
    maxRequests: 60,
    window: const Duration(minutes: 1),
  );

  // Caching
  final Map<String, _CachedResponse> _cache = {};
  final Duration _cacheExpiry = const Duration(minutes: 30);

  // Token tracking
  int _totalTokensUsed = 0;
  int _tokenBudget = 100000; // Daily budget

  /// Total tokens used in this session
  int get totalTokensUsed => _totalTokensUsed;

  /// Remaining token budget
  int get remainingBudget => _tokenBudget - _totalTokensUsed;

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT COMPLETION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send a chat completion request
  Future<Result<AIResponse>> chat({
    required String prompt,
    String? systemPrompt,
    AIModel model = AIModel.gpt4oMini,
    double temperature = 0.7,
    int? maxTokens,
    bool useCache = true,
    List<AIMessage>? conversationHistory,
  }) async {
    // Check rate limit
    if (!_rateLimiter.allowRequest()) {
      return Failure(
        AppError.rateLimited(
          message: 'AI request rate limit exceeded. Please wait.',
        ),
      );
    }

    // Check token budget
    if (remainingBudget <= 0) {
      return const Failure(
        AppError(
          message: 'Daily AI token budget exceeded.',
          type: ErrorType.rateLimited,
        ),
      );
    }

    // Check cache
    final cacheKey = _generateCacheKey(prompt, systemPrompt, model);
    if (useCache) {
      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        debugPrint('AIService: Cache hit for prompt');
        return Success(cached);
      }
    }

    // Build messages
    final messages = <Map<String, String>>[];

    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (conversationHistory != null) {
      for (final msg in conversationHistory) {
        messages.add({'role': msg.role.value, 'content': msg.content});
      }
    }

    messages.add({'role': 'user', 'content': prompt});

    // Make request
    return withRetryResult(
      () => _makeRequest(
        endpoint: '/chat/completions',
        body: {
          'model': model.id,
          'messages': messages,
          'temperature': temperature,
          if (maxTokens != null) 'max_tokens': maxTokens,
        },
      ),
      errorTransformer: _transformError,
    ).then(
      (result) => result.map((json) {
        final response = AIResponse.fromJson(json);

        // Track tokens
        _totalTokensUsed += response.totalTokens;

        // Cache successful response
        if (useCache) {
          _addToCache(cacheKey, response);
        }

        return response;
      }),
    );
  }

  /// Stream a chat completion response
  Stream<Result<String>> chatStream({
    required String prompt,
    String? systemPrompt,
    AIModel model = AIModel.gpt4oMini,
    double temperature = 0.7,
  }) async* {
    // Check rate limit
    if (!_rateLimiter.allowRequest()) {
      yield Failure(AppError.rateLimited());
      return;
    }

    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/chat/completions'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Env.openAiApiKey}',
      });

      request.body = jsonEncode({
        'model': model.id,
        'messages': messages,
        'temperature': temperature,
        'stream': true,
      });

      final response = await http.Client().send(request);

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ') && !line.contains('[DONE]')) {
            try {
              final json = jsonDecode(line.substring(6));
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null) {
                yield Success(content);
              }
            } catch (e) {
              // Skip malformed chunks
            }
          }
        }
      }
    } catch (e, stack) {
      yield Failure(_transformError(e, stack));
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
  Future<Result<MessageAnalysis>> analyzeMessage({
    required String message,
  }) async {
    final result = await chat(
      systemPrompt: '''Analyze the following message for:
1. Sentiment (positive/neutral/negative)
2. Toxicity score (0-1)
3. Flags (inappropriate, spam, harassment, none)

Respond in JSON format:
{"sentiment": "...", "toxicity": 0.0, "flags": ["..."]}''',
      prompt: message,
      maxTokens: 100,
      temperature: 0.1,
    );

    return result.map((r) {
      try {
        final json = jsonDecode(r.content);
        return MessageAnalysis(
          sentiment: json['sentiment'] ?? 'neutral',
          toxicity: (json['toxicity'] as num?)?.toDouble() ?? 0.0,
          flags: List<String>.from(json['flags'] ?? []),
        );
      } catch (e) {
        return MessageAnalysis(
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

  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${Env.openAiApiKey}',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    // Handle specific error codes
    if (response.statusCode == 429) {
      throw AppError.rateLimited();
    }

    if (response.statusCode == 401) {
      throw AppError.authentication(message: 'Invalid API key');
    }

    throw AppError.server(
      message: 'AI request failed',
      statusCode: response.statusCode,
    );
  }

  String _generateCacheKey(String prompt, String? systemPrompt, AIModel model) {
    final combined = '${model.id}|${systemPrompt ?? ''}|$prompt';
    return combined.hashCode.toString();
  }

  AIResponse? _getFromCache(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    if (DateTime.now().isAfter(cached.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return cached.response;
  }

  void _addToCache(String key, AIResponse response) {
    _cache[key] = _CachedResponse(
      response: response,
      expiresAt: DateTime.now().add(_cacheExpiry),
    );

    // Limit cache size
    if (_cache.length > 100) {
      final oldest = _cache.entries.first.key;
      _cache.remove(oldest);
    }
  }

  AppError _transformError(dynamic error, StackTrace? stackTrace) {
    if (error is AppError) return error;

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return AppError.timeout(originalError: error);
    }

    if (errorString.contains('socket') || errorString.contains('network')) {
      return AppError.network(originalError: error, stackTrace: stackTrace);
    }

    return AppError.server(originalError: error);
  }

  /// Reset token usage (call daily)
  void resetTokenUsage() {
    _totalTokensUsed = 0;
    debugPrint('AIService: Token usage reset');
  }

  /// Set token budget
  void setTokenBudget(int budget) {
    _tokenBudget = budget;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    debugPrint('AIService: Cache cleared');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RATE LIMITER
// ═══════════════════════════════════════════════════════════════════════════

class RateLimiter {
  RateLimiter({
    required this.maxRequests,
    required this.window,
  });
  final int maxRequests;
  final Duration window;
  final List<DateTime> _requests = [];

  bool allowRequest() {
    final now = DateTime.now();
    final windowStart = now.subtract(window);

    // Remove old requests
    _requests.removeWhere((time) => time.isBefore(windowStart));

    if (_requests.length >= maxRequests) {
      return false;
    }

    _requests.add(now);
    return true;
  }

  int get remainingRequests =>
      (maxRequests - _requests.length).clamp(0, maxRequests);

  Duration? get timeUntilReset {
    if (_requests.isEmpty) return null;
    final oldest = _requests.first;
    final resetTime = oldest.add(window);
    final remaining = resetTime.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum AIModel {
  gpt4o('gpt-4o', 'GPT-4o', 5.00, 15.00),
  gpt4oMini('gpt-4o-mini', 'GPT-4o Mini', 0.15, 0.60),
  gpt4Turbo('gpt-4-turbo', 'GPT-4 Turbo', 10.00, 30.00),
  gpt35Turbo('gpt-3.5-turbo', 'GPT-3.5 Turbo', 0.50, 1.50);

  final String id;
  final String displayName;
  final double inputPricePer1M;
  final double outputPricePer1M;

  const AIModel(
      this.id, this.displayName, this.inputPricePer1M, this.outputPricePer1M);
}

enum AIRole {
  system('system'),
  user('user'),
  assistant('assistant');

  final String value;
  const AIRole(this.value);
}

class AIMessage {
  const AIMessage({required this.role, required this.content});
  final AIRole role;
  final String content;
}

class AIResponse {
  AIResponse({
    required this.content,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.finishReason,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    final choice = json['choices']?[0] ?? {};
    final usage = json['usage'] ?? {};

    return AIResponse(
      content: choice['message']?['content'] ?? '',
      promptTokens: usage['prompt_tokens'] ?? 0,
      completionTokens: usage['completion_tokens'] ?? 0,
      totalTokens: usage['total_tokens'] ?? 0,
      finishReason: choice['finish_reason'],
    );
  }
  final String content;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final String? finishReason;
}

class MessageAnalysis {
  MessageAnalysis({
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

class _CachedResponse {
  _CachedResponse({required this.response, required this.expiresAt});
  final AIResponse response;
  final DateTime expiresAt;
}
