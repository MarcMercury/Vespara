import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// HUGGING FACE SERVICE - Free AI Inference for Low-Value Tasks
/// ════════════════════════════════════════════════════════════════════════════
///
/// Uses HuggingFace Inference API for:
/// - Sentiment analysis (free, offloads from OpenAI)
/// - Toxicity/NSFW detection in messages and bios
/// - Zero-cost alternative for classification tasks

class HuggingFaceService {
  HuggingFaceService._();

  static const String _baseUrl = 'https://api-inference.huggingface.co/models';

  // Recommended models (free tier compatible)
  static const String _sentimentModel = 'cardiffnlp/twitter-roberta-base-sentiment-latest';
  static const String _toxicityModel = 'unitary/toxic-bert';

  /// Analyze sentiment of a text message
  /// Returns: positive, neutral, or negative
  static Future<SentimentResult?> analyzeSentiment(String text) async {
    final apiKey = Env.huggingfaceKey;
    if (apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_sentimentModel'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': text}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('HuggingFace sentiment error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      // Response format: [[{"label": "positive", "score": 0.95}, ...]]
      if (data is List && data.isNotEmpty && data[0] is List) {
        final results = data[0] as List;
        final sorted = List<Map<String, dynamic>>.from(results)
          ..sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

        final top = sorted.first;
        return SentimentResult(
          label: _normalizeSentimentLabel(top['label'] as String? ?? ''),
          score: (top['score'] as num?)?.toDouble() ?? 0.0,
          allScores: {
            for (final r in sorted)
              _normalizeSentimentLabel(r['label'] as String? ?? ''):
                  (r['score'] as num?)?.toDouble() ?? 0.0,
          },
        );
      }
      return null;
    } catch (e) {
      debugPrint('HuggingFace sentiment error: $e');
      return null;
    }
  }

  /// Check text for toxicity (harassment, hate, etc.)
  /// Returns a score from 0.0 (safe) to 1.0 (toxic)
  static Future<ToxicityResult?> checkToxicity(String text) async {
    final apiKey = Env.huggingfaceKey;
    if (apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_toxicityModel'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': text}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty && data[0] is List) {
        final results = data[0] as List;
        double toxicScore = 0.0;

        for (final r in results) {
          final label = (r['label'] as String? ?? '').toLowerCase();
          final score = (r['score'] as num?)?.toDouble() ?? 0.0;
          if (label == 'toxic' || label == 'LABEL_1') {
            toxicScore = score;
            break;
          }
        }

        return ToxicityResult(
          score: toxicScore,
          isToxic: toxicScore > 0.6,
          isWarning: toxicScore > 0.3 && toxicScore <= 0.6,
        );
      }
      return null;
    } catch (e) {
      debugPrint('HuggingFace toxicity error: $e');
      return null;
    }
  }

  /// Combined analysis: sentiment + toxicity in parallel
  static Future<TextAnalysisResult> analyzeText(String text) async {
    final results = await Future.wait([
      analyzeSentiment(text),
      checkToxicity(text),
    ]);

    return TextAnalysisResult(
      sentiment: results[0] as SentimentResult?,
      toxicity: results[1] as ToxicityResult?,
    );
  }

  static String _normalizeSentimentLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('positive') || lower == 'label_2') return 'positive';
    if (lower.contains('negative') || lower == 'label_0') return 'negative';
    return 'neutral';
  }
}

class SentimentResult {
  const SentimentResult({
    required this.label,
    required this.score,
    required this.allScores,
  });
  final String label; // positive, neutral, negative
  final double score; // confidence 0-1
  final Map<String, double> allScores;

  /// Emoji representation for UI
  String get emoji {
    switch (label) {
      case 'positive':
        return score > 0.8 ? '🔥' : '😊';
      case 'negative':
        return score > 0.8 ? '😬' : '😐';
      default:
        return '💬';
    }
  }
}

class ToxicityResult {
  const ToxicityResult({
    required this.score,
    required this.isToxic,
    required this.isWarning,
  });
  final double score;
  final bool isToxic;
  final bool isWarning;
}

class TextAnalysisResult {
  const TextAnalysisResult({this.sentiment, this.toxicity});
  final SentimentResult? sentiment;
  final ToxicityResult? toxicity;

  bool get isSafe => toxicity == null || !toxicity!.isToxic;
  String get moodEmoji => sentiment?.emoji ?? '💬';
}
