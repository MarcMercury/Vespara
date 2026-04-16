import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../constants/app_constants.dart';

/// OpenAI Service for Strategist and Ghost Protocol features
/// Now routes through server-side edge functions to protect API keys
class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';

  // ── Rate Limiting ──────────────────────────────────────────────────────
  static final List<DateTime> _requestTimestamps = [];
  static const int _maxRequestsPerMinute = 30;

  static bool _checkRateLimit() {
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));
    _requestTimestamps.removeWhere((t) => t.isBefore(windowStart));
    if (_requestTimestamps.length >= _maxRequestsPerMinute) return false;
    _requestTimestamps.add(now);
    return true;
  }

  // ── Response Caching ───────────────────────────────────────────────────
  static final Map<String, _CachedResult> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 15);

  static String? _getFromCache(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    return entry.value;
  }

  static void _addToCache(String key, String value) {
    _cache[key] = _CachedResult(value, DateTime.now().add(_cacheTtl));
    if (_cache.length > 50) _cache.remove(_cache.keys.first);
  }

  /// Generate a polite closure message for Ghost Protocol
  static Future<String> generateClosureMessage({
    required String matchName,
    required String conversationContext,
    String? reason,
  }) async {
    final prompt = '''
You are helping someone end a dating conversation politely but firmly. 
Generate a respectful, mature closure message that:
- Acknowledges the connection
- Is honest but kind
- Provides closure without being harsh
- Does not leave room for negotiation

Match name: $matchName
Conversation context: $conversationContext
${reason != null ? 'Reason for ending: $reason' : ''}

Generate ONLY the message text, no quotes or explanation.
''';

    return _chat(prompt, action: 'closure_message');
  }

  /// Generate conversation resuscitator prompt
  static Future<String> generateResuscitator({
    required String matchName,
    required String lastMessages,
    required String matchInterests,
  }) async {
    final prompt = '''
You are helping revive a stale dating conversation. 
Generate an engaging message that:
- References something from previous conversation
- Introduces a fresh topic or question
- Is playful and inviting
- Doesn't sound desperate

Match name: $matchName
Last messages: $lastMessages
Match interests: $matchInterests

Generate ONLY the message text, no quotes or explanation.
''';

    return _chat(prompt, action: 'resuscitate');
  }

  /// Generate strategic advice for The Strategist
  static Future<String> generateStrategicAdvice({
    required double optimizationScore,
    required int activeMatches,
    required int staleMatches,
    required double responseRate,
  }) async {
    final prompt = '''
You are a dating strategist providing actionable advice.
Based on these metrics, provide ONE specific, actionable tip:

Optimization Score: $optimizationScore%
Active Matches: $activeMatches
Stale Matches: $staleMatches
Response Rate: ${(responseRate * 100).toStringAsFixed(1)}%

Keep it under 50 words. Be direct and practical.
''';

    return _chat(prompt, action: 'strategic_advice');
  }

  /// Generate Ghost Protocol closure message
  static Future<String> generateGhostProtocol({
    required String matchName,
    required String tone,
    required int duration,
  }) async {
    final toneDescriptions = {
      'kind':
          'Be warm, appreciative, and wish them well. Focus on positive memories.',
      'honest':
          'Be direct but respectful. Acknowledge the situation honestly without being harsh.',
      'brief':
          'Keep it short and simple. One or two sentences maximum. No fluff.',
    };

    final prompt = '''
Write a closure message for $matchName.
We haven't spoken in $duration days.

Tone: ${toneDescriptions[tone] ?? toneDescriptions['kind']}

Guidelines:
- Never be mean or hurtful
- Don't overly explain or make excuses
- Keep it genuine, not robotic
- No clichés like "it's not you, it's me"

Generate ONLY the message text, no quotes or explanation.
''';

    return _chat(prompt, action: 'closure_message');
  }

  /// Generate Truth or Dare prompts for TAGS
  static Future<List<String>> generateGamePrompts({
    required String consentLevel,
    required bool isTruth,
    required int count,
  }) async {
    final type = isTruth ? 'truth questions' : 'dares';
    final prompt = '''
Generate $count ${consentLevel.toUpperCase()} level $type for an adult party game.

Consent levels:
- GREEN: Flirty but PG-13, no physical contact required
- YELLOW: Suggestive, light touch allowed, clothing stays on
- RED: Explicit, for consenting adults only

Current level: $consentLevel

Return as a JSON array of strings. Example: ["prompt 1", "prompt 2"]
''';

    final response = await _chat(prompt, action: 'game_content');
    try {
      final List<dynamic> parsed = jsonDecode(response);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      return [response];
    }
  }

  /// Core chat completion method — routes through edge function proxy
  static Future<String> _chat(String prompt, {String action = 'strategic_advice'}) async {
    if (!_checkRateLimit()) {
      throw Exception('Rate limit exceeded. Please wait a moment.');
    }

    // Check cache
    final cacheKey = '${action}_${prompt.hashCode}';
    final cached = _getFromCache(cacheKey);
    if (cached != null) return cached;

    // Route through Supabase edge function proxy (secure)
    if (Env.supabaseUrl.isNotEmpty) {
      try {
        final response = await Supabase.instance.client.functions.invoke(
          'ai-proxy',
          body: {
            'action': action,
            'prompt': prompt,
          },
        );

        if (response.status == 200) {
          final content = response.data['content']?.toString().trim() ?? '';
          _addToCache(cacheKey, content);
          return content;
        }
        throw Exception('AI proxy error: ${response.status}');
      } catch (e) {
        // Fall through to direct call as fallback
        if (Env.openaiApiKey.isEmpty) rethrow;
      }
    }

    // Fallback: direct call (local dev only)
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Env.openaiApiKey}',
      },
      body: jsonEncode({
        'model': AppConstants.openaiModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a sophisticated dating and relationship advisor. Be direct, mature, and helpful.',
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': AppConstants.maxTokens,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'].toString().trim();
      _addToCache(cacheKey, content);
      return content;
    } else {
      throw Exception('OpenAI API Error: ${response.statusCode}');
    }
  }
}

class _CachedResult {
  _CachedResult(this.value, this.expiresAt);
  final String value;
  final DateTime expiresAt;
}
