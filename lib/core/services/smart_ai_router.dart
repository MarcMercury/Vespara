import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../utils/result.dart';
import 'ai_service.dart';
import 'gemini_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SMART AI ROUTER - Cost-Optimized AI Service Selection
/// ════════════════════════════════════════════════════════════════════════════
///
/// Routes AI requests to the cheapest capable provider:
/// - Gemini Flash (free tier) → games, ice breakers, bios, message analysis
/// - OpenAI gpt-4o-mini (via proxy) → strategist, ghost protocol, photo analysis
///
/// Falls back automatically if primary provider fails.

class SmartAIRouter {
  SmartAIRouter._();
  static SmartAIRouter? _instance;
  static SmartAIRouter get instance => _instance ??= SmartAIRouter._();

  bool get _geminiAvailable => Env.geminiApiKey.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTING: Use Gemini (free) first, OpenAI as fallback
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate game content — routes to Gemini (free), falls back to OpenAI
  Future<Result<String>> generateGameContent({
    required String gameType,
    required String contentRating,
    required String context,
  }) async {
    if (_geminiAvailable) {
      try {
        final result = await GeminiService.instance.generateGameContent(
          gameType: gameType,
          contentRating: contentRating,
          context: context,
        );
        if (result is Success) return result;
      } catch (e) {
        debugPrint('SmartAIRouter: Gemini failed for game content, falling back to OpenAI');
      }
    }

    return AIService.instance.generateGameContent(
      gameType: gameType,
      contentRating: contentRating,
      context: context,
    );
  }

  /// Generate ice breakers — routes to Gemini (free), falls back to OpenAI
  Future<Result<List<String>>> generateIceBreakers({
    required String profile1Context,
    required String profile2Context,
    int count = 3,
  }) async {
    if (_geminiAvailable) {
      try {
        final result = await GeminiService.instance.generateIceBreakers(
          profile1Context: profile1Context,
          profile2Context: profile2Context,
          count: count,
        );
        if (result is Success) return result;
      } catch (e) {
        debugPrint('SmartAIRouter: Gemini failed for ice breakers, falling back to OpenAI');
      }
    }

    return AIService.instance.generateIceBreakers(
      profile1Context: profile1Context,
      profile2Context: profile2Context,
      count: count,
    );
  }

  /// Generate bio — routes to Gemini (free), falls back to OpenAI
  Future<Result<String>> generateBio({
    required String userContext,
    required String style,
  }) async {
    if (_geminiAvailable) {
      try {
        final result = await GeminiService.instance.generateBio(
          userContext: userContext,
          style: style,
        );
        if (result is Success) return result;
      } catch (e) {
        debugPrint('SmartAIRouter: Gemini failed for bio, falling back to OpenAI');
      }
    }

    return AIService.instance.generateBio(
      userContext: userContext,
      style: style,
    );
  }

  /// Analyze message — routes to Gemini (free), falls back to OpenAI
  Future<Result<MessageAnalysis>> analyzeMessage({
    required String message,
  }) async {
    if (_geminiAvailable) {
      try {
        final geminiResult = await GeminiService.instance.analyzeMessage(
          message: message,
        );
        // Convert GeminiMessageAnalysis to MessageAnalysis
        return geminiResult.map((r) => MessageAnalysis(
          sentiment: r.sentiment,
          toxicity: r.toxicity,
          flags: r.flags,
        ));
      } catch (e) {
        debugPrint('SmartAIRouter: Gemini failed for analysis, falling back to OpenAI');
      }
    }

    return AIService.instance.analyzeMessage(message: message);
  }

  /// Generate match compatibility blurb — Gemini-only (cheap, delightful feature)
  Future<Result<String>> generateCompatibilityBlurb({
    required String user1Traits,
    required String user2Traits,
  }) async {
    if (_geminiAvailable) {
      final result = await GeminiService.instance.chat(
        systemPrompt:
            'You are a witty matchmaker. Write a short, fun 1-sentence compatibility blurb about why two people might click. Be playful and specific. No generic statements.',
        prompt: 'Person A: $user1Traits\nPerson B: $user2Traits\nWrite a compatibility blurb.',
        maxTokens: 80,
        temperature: 0.9,
      );
      return result.map((r) => r.content);
    }

    return AIService.instance.chat(
      systemPrompt:
          'Write a short, fun 1-sentence compatibility blurb about why two people might click.',
      prompt: 'Person A: $user1Traits\nPerson B: $user2Traits',
      maxTokens: 80,
    ).then((r) => r.map((resp) => resp.content));
  }
}
