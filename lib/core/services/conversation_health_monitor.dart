import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// CONVERSATION HEALTH MONITOR - Relationship Doctor
/// ════════════════════════════════════════════════════════════════════════════
///
/// Silently monitors conversation health and provides subtle nudges:
/// - Detects dying conversations → suggest topics
/// - Notices inactive matches → gentle reminders
/// - Identifies one-word patterns → coaching tips
///
/// All suggestions are optional - users can ignore them.

class ConversationHealthMonitor {
  ConversationHealthMonitor._();
  static ConversationHealthMonitor? _instance;
  static ConversationHealthMonitor get instance =>
      _instance ??= ConversationHealthMonitor._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Thresholds
  static const int _dyingConversationHours = 24;
  static const int _inactiveMatchDays = 3;
  static const int _minMessagesForAnalysis = 5;
  static const double _oneWordThreshold = 0.5; // 50% one-word responses

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATION HEALTH CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyze health of a specific conversation
  Future<ConversationHealth> analyzeConversation(String matchId) async {
    if (_userId == null) {
      return ConversationHealth.unknown();
    }

    try {
      // Get recent messages
      final messages = await _supabase
          .from('messages')
          .select('id, sender_id, content, created_at')
          .eq('match_id', matchId)
          .order('created_at', ascending: false)
          .limit(50);

      final messageList = messages as List;

      if (messageList.isEmpty) {
        return ConversationHealth(
          status: HealthStatus.notStarted,
          score: 0.0,
          insights: [ConversationInsight.noMessages],
          suggestions: ['Send the first message to break the ice!'],
        );
      }

      // Calculate metrics
      final metrics = _calculateMetrics(messageList);
      final issues = <ConversationInsight>[];
      final suggestions = <String>[];

      // Check for dying conversation
      if (metrics.hoursSinceLastMessage > _dyingConversationHours) {
        issues.add(ConversationInsight.dying);
        suggestions.add('It\'s been a while - send a quick hello!');
      }

      // Check message balance
      if (metrics.userMessageRatio < 0.3) {
        issues.add(ConversationInsight.oneSided);
        suggestions.add('Try asking an open-ended question');
      } else if (metrics.userMessageRatio > 0.7) {
        issues.add(ConversationInsight.overMessaging);
        suggestions.add('Give them a chance to respond');
      }

      // Check for one-word responses
      if (metrics.oneWordRatio > _oneWordThreshold) {
        issues.add(ConversationInsight.shortResponses);
        suggestions.add('Share something personal to deepen the conversation');
      }

      // Check response time patterns
      if (metrics.avgResponseTimeHours > 12) {
        issues.add(ConversationInsight.slowResponses);
      }

      // Calculate overall score
      double score = 1.0;
      score -= issues.length * 0.15;
      score = score.clamp(0.0, 1.0);

      HealthStatus status;
      if (score >= 0.8) {
        status = HealthStatus.thriving;
      } else if (score >= 0.6) {
        status = HealthStatus.healthy;
      } else if (score >= 0.4) {
        status = HealthStatus.needsAttention;
      } else {
        status = HealthStatus.critical;
      }

      return ConversationHealth(
        status: status,
        score: score,
        insights: issues,
        suggestions: suggestions,
        metrics: metrics,
      );
    } catch (e) {
      debugPrint('ConversationHealth: Analysis failed - $e');
      return ConversationHealth.unknown();
    }
  }

  ConversationMetrics _calculateMetrics(List<dynamic> messages) {
    if (messages.isEmpty) {
      return ConversationMetrics.empty();
    }

    int userMessages = 0;
    int oneWordMessages = 0;
    int totalWords = 0;
    final responseTimes = <Duration>[];

    DateTime? lastMessageTime;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final content = msg['content'] as String? ?? '';
      final senderId = msg['sender_id'] as String?;
      final createdAt = DateTime.parse(msg['created_at']);

      if (senderId == _userId) {
        userMessages++;
      }

      final words = content.trim().split(RegExp(r'\s+')).length;
      totalWords += words;
      if (words <= 1) oneWordMessages++;

      // Calculate response time
      if (i < messages.length - 1) {
        final prevMsg = messages[i + 1];
        final prevTime = DateTime.parse(prevMsg['created_at']);
        final prevSender = prevMsg['sender_id'];

        if (senderId != prevSender) {
          responseTimes.add(createdAt.difference(prevTime));
        }
      }

      if (i == 0) {
        lastMessageTime = createdAt;
      }
    }

    final avgResponseTime = responseTimes.isEmpty
        ? Duration.zero
        : Duration(
            milliseconds: responseTimes
                    .map((d) => d.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                responseTimes.length,
          );

    return ConversationMetrics(
      totalMessages: messages.length,
      userMessages: userMessages,
      userMessageRatio: messages.isEmpty ? 0.5 : userMessages / messages.length,
      oneWordRatio: messages.isEmpty ? 0.0 : oneWordMessages / messages.length,
      avgWordsPerMessage: messages.isEmpty ? 0.0 : totalWords / messages.length,
      avgResponseTimeHours: avgResponseTime.inMinutes / 60.0,
      hoursSinceLastMessage: lastMessageTime == null
          ? 0.0
          : DateTime.now().difference(lastMessageTime).inMinutes / 60.0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH ANALYSIS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all conversations needing attention
  Future<List<MatchNudge>> getMatchesNeedingAttention() async {
    if (_userId == null) return [];

    try {
      // Get all matches with last message time
      final matches = await _supabase
          .from('matches')
          .select('''
            id,
            user1_id,
            user2_id,
            matched_at,
            user1:profiles!matches_user1_id_fkey(id, display_name, photos),
            user2:profiles!matches_user2_id_fkey(id, display_name, photos)
          ''')
          .or('user1_id.eq.$_userId,user2_id.eq.$_userId')
          .order('matched_at', ascending: false);

      final nudges = <MatchNudge>[];

      for (final match in matches as List) {
        final matchId = match['id'] as String;

        // Get last message
        final lastMessage = await _supabase
            .from('messages')
            .select('created_at, sender_id')
            .eq('match_id', matchId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        final otherUser =
            match['user1_id'] == _userId ? match['user2'] : match['user1'];

        NudgeType? nudgeType;
        String? message;

        if (lastMessage == null) {
          // No messages - encourage first message
          final matchedAt = DateTime.parse(match['matched_at']);
          if (DateTime.now().difference(matchedAt).inHours > 24) {
            nudgeType = NudgeType.noFirstMessage;
            message = 'You matched ${_formatTimeAgo(matchedAt)} - say hi!';
          }
        } else {
          final lastMessageTime = DateTime.parse(lastMessage['created_at']);
          final hoursSince = DateTime.now().difference(lastMessageTime).inHours;
          final lastSender = lastMessage['sender_id'] as String;

          if (hoursSince > 72 && lastSender != _userId) {
            // They messaged, user didn't respond
            nudgeType = NudgeType.unansweredMessage;
            message = 'They\'re waiting for your reply';
          } else if (hoursSince > 72 && lastSender == _userId) {
            // User messaged, no response
            nudgeType = NudgeType.noResponse;
            message = 'Maybe try a different approach?';
          } else if (hoursSince > 48) {
            nudgeType = NudgeType.conversationDying;
            message = 'Keep the conversation going!';
          }
        }

        if (nudgeType != null) {
          nudges.add(
            MatchNudge(
              matchId: matchId,
              otherUserName: otherUser['display_name'] ?? 'Your match',
              otherUserPhoto: (otherUser['photos'] as List?)?.firstOrNull,
              nudgeType: nudgeType,
              message: message!,
            ),
          );
        }
      }

      return nudges;
    } catch (e) {
      debugPrint('ConversationHealth: Batch analysis failed - $e');
      return [];
    }
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'recently';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATION SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get contextual conversation suggestions
  Future<List<String>> getConversationSuggestions(String matchId) async {
    final health = await analyzeConversation(matchId);
    final suggestions = <String>[];

    // Based on insights, provide specific suggestions
    for (final insight in health.insights) {
      switch (insight) {
        case ConversationInsight.dying:
          suggestions.addAll([
            'What\'s been the highlight of your week?',
            'Saw something that reminded me of you...',
            'Any fun plans coming up?',
          ]);
          break;
        case ConversationInsight.shortResponses:
          suggestions.addAll([
            'Tell me more about [their interest]',
            'What got you into [their hobby]?',
            'I\'d love to hear the story behind...',
          ]);
          break;
        case ConversationInsight.oneSided:
          suggestions.addAll([
            'What do you think about...?',
            'I\'m curious, what\'s your take on...?',
            'Have you ever...?',
          ]);
          break;
        default:
          break;
      }
    }

    // Add generic suggestions if needed
    if (suggestions.isEmpty) {
      suggestions.addAll([
        'What\'s making you smile today?',
        'Any exciting plans for the weekend?',
        'What\'s something you\'re looking forward to?',
      ]);
    }

    return suggestions.take(3).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum HealthStatus {
  unknown,
  notStarted,
  critical,
  needsAttention,
  healthy,
  thriving,
}

enum ConversationInsight {
  noMessages,
  dying,
  oneSided,
  overMessaging,
  shortResponses,
  slowResponses,
}

enum NudgeType {
  noFirstMessage,
  conversationDying,
  unansweredMessage,
  noResponse,
  milestone,
}

class ConversationHealth {
  ConversationHealth({
    required this.status,
    required this.score,
    required this.insights,
    required this.suggestions,
    this.metrics,
  });

  factory ConversationHealth.unknown() => ConversationHealth(
        status: HealthStatus.unknown,
        score: 0.0,
        insights: [],
        suggestions: [],
      );
  final HealthStatus status;
  final double score;
  final List<ConversationInsight> insights;
  final List<String> suggestions;
  final ConversationMetrics? metrics;

  bool get needsAttention =>
      status == HealthStatus.critical || status == HealthStatus.needsAttention;
}

class ConversationMetrics {
  ConversationMetrics({
    required this.totalMessages,
    required this.userMessages,
    required this.userMessageRatio,
    required this.oneWordRatio,
    required this.avgWordsPerMessage,
    required this.avgResponseTimeHours,
    required this.hoursSinceLastMessage,
  });

  factory ConversationMetrics.empty() => ConversationMetrics(
        totalMessages: 0,
        userMessages: 0,
        userMessageRatio: 0.5,
        oneWordRatio: 0.0,
        avgWordsPerMessage: 0.0,
        avgResponseTimeHours: 0.0,
        hoursSinceLastMessage: 0.0,
      );
  final int totalMessages;
  final int userMessages;
  final double userMessageRatio;
  final double oneWordRatio;
  final double avgWordsPerMessage;
  final double avgResponseTimeHours;
  final double hoursSinceLastMessage;
}

class MatchNudge {
  MatchNudge({
    required this.matchId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.nudgeType,
    required this.message,
  });
  final String matchId;
  final String otherUserName;
  final String? otherUserPhoto;
  final NudgeType nudgeType;
  final String message;
}
