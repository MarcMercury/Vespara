import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../constants/app_constants.dart';

/// OpenAI Service for Strategist and Ghost Protocol features
class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';

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

    return _chat(prompt);
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

    return _chat(prompt);
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

    return _chat(prompt);
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

    return _chat(prompt);
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

    final response = await _chat(prompt);
    try {
      final List<dynamic> parsed = jsonDecode(response);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      return [response];
    }
  }

  /// Core chat completion method
  static Future<String> _chat(String prompt) async {
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
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception('OpenAI API Error: ${response.statusCode}');
    }
  }
}
