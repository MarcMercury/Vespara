import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// RELATIONSHIP PROGRESS TRACKER - Auto Milestones & Next Steps
/// ════════════════════════════════════════════════════════════════════════════
///
/// Automatically tracks relationship progression:
/// - Message count, duration, response times
/// - Key milestones (first message, first date, etc.)
/// - AI suggests natural next steps
///
/// Zero effort - everything is auto-detected

class RelationshipProgressService {
  static RelationshipProgressService? _instance;
  static RelationshipProgressService get instance =>
      _instance ??= RelationshipProgressService._();

  RelationshipProgressService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AIService _aiService = AIService.instance;

  // Cache progress per match
  final Map<String, RelationshipProgress> _progressCache = {};
  final Duration _cacheExpiry = const Duration(minutes: 30);
  final Map<String, DateTime> _cacheTimestamps = {};

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // GET PROGRESS - Auto-calculated
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get relationship progress for a match
  Future<RelationshipProgress> getProgress(String matchId) async {
    // Check cache
    if (_isCacheValid(matchId)) {
      return _progressCache[matchId]!;
    }

    final stats = await _fetchMatchStats(matchId);
    final milestones = await _fetchMilestones(matchId);
    final stage = _calculateStage(stats, milestones);
    final nextStep = await _suggestNextStep(stage, stats, milestones);

    final progress = RelationshipProgress(
      matchId: matchId,
      stage: stage,
      stats: stats,
      milestones: milestones,
      suggestedNextStep: nextStep,
    );

    _cacheProgress(matchId, progress);
    return progress;
  }

  /// Get just the stage (for quick display)
  Future<RelationshipStage> getStage(String matchId) async {
    final progress = await getProgress(matchId);
    return progress.stage;
  }

  /// Get suggested next step
  Future<NextStep?> getNextStep(String matchId) async {
    final progress = await getProgress(matchId);
    return progress.suggestedNextStep;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH STATS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<MatchStats> _fetchMatchStats(String matchId) async {
    if (_userId == null) return MatchStats.empty();

    try {
      // Get match creation date
      final match = await _supabase
          .from('matches')
          .select('created_at, user1_id, user2_id')
          .eq('id', matchId)
          .maybeSingle();

      if (match == null) return MatchStats.empty();

      final matchedAt = DateTime.parse(match['created_at'] as String);
      final isUser1 = match['user1_id'] == _userId;
      final otherId = isUser1 ? match['user2_id'] : match['user1_id'];

      // Get message stats
      final messagesResult = await _supabase
          .from('messages')
          .select('id, sender_id, created_at')
          .eq('match_id', matchId)
          .order('created_at');

      final messages = messagesResult as List;
      final totalMessages = messages.length;
      final myMessages = messages.where((m) => m['sender_id'] == _userId).length;
      final theirMessages = totalMessages - myMessages;

      // Calculate average response time
      Duration? avgResponseTime;
      if (messages.length > 1) {
        final responseTimes = <Duration>[];
        for (int i = 1; i < messages.length; i++) {
          final prev = messages[i - 1];
          final curr = messages[i];
          if (prev['sender_id'] != curr['sender_id']) {
            final diff = DateTime.parse(curr['created_at'])
                .difference(DateTime.parse(prev['created_at']));
            if (diff.inHours < 24) {
              responseTimes.add(diff);
            }
          }
        }
        if (responseTimes.isNotEmpty) {
          final totalMinutes = responseTimes.fold<int>(
            0,
            (sum, d) => sum + d.inMinutes,
          );
          avgResponseTime = Duration(minutes: totalMinutes ~/ responseTimes.length);
        }
      }

      // Last message date
      DateTime? lastMessageAt;
      if (messages.isNotEmpty) {
        lastMessageAt = DateTime.parse(messages.last['created_at'] as String);
      }

      // Days since match
      final daysSinceMatch = DateTime.now().difference(matchedAt).inDays;

      return MatchStats(
        matchedAt: matchedAt,
        totalMessages: totalMessages,
        myMessages: myMessages,
        theirMessages: theirMessages,
        daysSinceMatch: daysSinceMatch,
        averageResponseTime: avgResponseTime,
        lastMessageAt: lastMessageAt,
      );
    } catch (e) {
      debugPrint('ProgressTracker: Failed to fetch stats - $e');
      return MatchStats.empty();
    }
  }

  Future<List<Milestone>> _fetchMilestones(String matchId) async {
    if (_userId == null) return [];

    final milestones = <Milestone>[];

    try {
      // Matched milestone (always exists)
      final match = await _supabase
          .from('matches')
          .select('created_at')
          .eq('id', matchId)
          .maybeSingle();

      if (match != null) {
        milestones.add(Milestone(
          type: MilestoneType.matched,
          achievedAt: DateTime.parse(match['created_at']),
          title: 'Matched! 💕',
        ));
      }

      // First message
      final firstMessage = await _supabase
          .from('messages')
          .select('created_at, sender_id')
          .eq('match_id', matchId)
          .order('created_at')
          .limit(1)
          .maybeSingle();

      if (firstMessage != null) {
        final wasMe = firstMessage['sender_id'] == _userId;
        milestones.add(Milestone(
          type: MilestoneType.firstMessage,
          achievedAt: DateTime.parse(firstMessage['created_at']),
          title: wasMe ? 'You broke the ice! 🧊' : 'They messaged first! 💬',
        ));
      }

      // Reached 50 messages
      final messageCount = await _supabase
          .from('messages')
          .select()
          .eq('match_id', matchId)
          .count(CountOption.exact);

      if ((messageCount.count ?? 0) >= 50) {
        milestones.add(Milestone(
          type: MilestoneType.deepConversation,
          achievedAt: DateTime.now(),
          title: 'Deep in conversation! 🗣️',
        ));
      }

      // Check for phone/date mentions
      final recentMessages = await _supabase
          .from('messages')
          .select('content')
          .eq('match_id', matchId)
          .order('created_at', ascending: false)
          .limit(50);

      final allText = (recentMessages as List)
          .map((m) => (m['content'] ?? '').toString().toLowerCase())
          .join(' ');

      if (allText.contains('phone') ||
          allText.contains('call') ||
          allText.contains('number')) {
        milestones.add(Milestone(
          type: MilestoneType.phoneMentioned,
          achievedAt: DateTime.now(),
          title: 'Phone call discussed! 📱',
        ));
      }

      if (allText.contains('date') ||
          allText.contains('meet up') ||
          allText.contains('get together') ||
          allText.contains('grab a drink') ||
          allText.contains('grab coffee')) {
        milestones.add(Milestone(
          type: MilestoneType.dateMentioned,
          achievedAt: DateTime.now(),
          title: 'Date discussed! 🎉',
        ));
      }

      // Check for planned dates
      try {
        final plannedDates = await _supabase
            .from('match_dates')
            .select('created_at, status')
            .eq('match_id', matchId);

        for (final date in plannedDates) {
          if (date['status'] == 'planned') {
            milestones.add(Milestone(
              type: MilestoneType.datePlanned,
              achievedAt: DateTime.parse(date['created_at']),
              title: 'Date planned! 📅',
            ));
          }
          if (date['status'] == 'completed') {
            milestones.add(Milestone(
              type: MilestoneType.dateCompleted,
              achievedAt: DateTime.parse(date['created_at']),
              title: 'Date happened! 🌟',
            ));
          }
        }
      } catch (_) {
        // Table might not exist
      }

      // Sort by date
      milestones.sort((a, b) => a.achievedAt.compareTo(b.achievedAt));
      return milestones;
    } catch (e) {
      debugPrint('ProgressTracker: Failed to fetch milestones - $e');
      return milestones;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CALCULATE STAGE
  // ═══════════════════════════════════════════════════════════════════════════

  RelationshipStage _calculateStage(MatchStats stats, List<Milestone> milestones) {
    // Check milestones first (most reliable)
    final hasDated = milestones.any((m) =>
        m.type == MilestoneType.dateCompleted);
    final hasPlannedDate = milestones.any((m) =>
        m.type == MilestoneType.datePlanned);
    final hasDateMentioned = milestones.any((m) =>
        m.type == MilestoneType.dateMentioned);
    final hasPhoneMentioned = milestones.any((m) =>
        m.type == MilestoneType.phoneMentioned);

    if (hasDated) return RelationshipStage.dating;
    if (hasPlannedDate) return RelationshipStage.planningDate;
    if (hasDateMentioned || hasPhoneMentioned) return RelationshipStage.escalating;

    // Fallback to message count
    if (stats.totalMessages >= 100) return RelationshipStage.deepConnection;
    if (stats.totalMessages >= 50) return RelationshipStage.gettingToKnow;
    if (stats.totalMessages >= 10) return RelationshipStage.earlyConversation;
    if (stats.totalMessages >= 1) return RelationshipStage.iceBreaking;

    return RelationshipStage.justMatched;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUGGEST NEXT STEP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<NextStep?> _suggestNextStep(
    RelationshipStage stage,
    MatchStats stats,
    List<Milestone> milestones,
  ) async {
    // Instant suggestions based on stage
    switch (stage) {
      case RelationshipStage.justMatched:
        return NextStep(
          action: 'Send the first message',
          emoji: '💬',
          reason: "Don't leave them waiting!",
          urgency: NextStepUrgency.high,
        );

      case RelationshipStage.iceBreaking:
        if (stats.theirMessages == 0) {
          return NextStep(
            action: 'Give them time to respond',
            emoji: '⏳',
            reason: 'They might be busy',
            urgency: NextStepUrgency.low,
          );
        }
        return NextStep(
          action: 'Ask about their interests',
          emoji: '🎯',
          reason: 'Find common ground',
          urgency: NextStepUrgency.medium,
        );

      case RelationshipStage.earlyConversation:
        return NextStep(
          action: 'Share something personal',
          emoji: '💭',
          reason: 'Deepen the connection',
          urgency: NextStepUrgency.medium,
        );

      case RelationshipStage.gettingToKnow:
        if (stats.daysSinceMatch > 7) {
          return NextStep(
            action: 'Suggest a phone call',
            emoji: '📱',
            reason: "You've been chatting for a while!",
            urgency: NextStepUrgency.high,
          );
        }
        return NextStep(
          action: 'Ask what they\'re up to this weekend',
          emoji: '📅',
          reason: 'Start hinting at meeting up',
          urgency: NextStepUrgency.medium,
        );

      case RelationshipStage.deepConnection:
        return NextStep(
          action: 'Plan a date!',
          emoji: '🎉',
          reason: 'Time to meet in person',
          urgency: NextStepUrgency.high,
        );

      case RelationshipStage.escalating:
        return NextStep(
          action: 'Lock in the plans',
          emoji: '📍',
          reason: 'Pick a specific time and place',
          urgency: NextStepUrgency.high,
        );

      case RelationshipStage.planningDate:
        return NextStep(
          action: 'Confirm the details',
          emoji: '✅',
          reason: 'Make sure you\'re both on the same page',
          urgency: NextStepUrgency.medium,
        );

      case RelationshipStage.dating:
        return NextStep(
          action: 'Plan another date!',
          emoji: '💕',
          reason: 'Keep the momentum going',
          urgency: NextStepUrgency.medium,
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECORD EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record a milestone manually (for events we can't auto-detect)
  Future<void> recordMilestone({
    required String matchId,
    required MilestoneType type,
    String? notes,
  }) async {
    if (_userId == null) return;

    try {
      await _supabase.from('relationship_milestones').insert({
        'match_id': matchId,
        'user_id': _userId,
        'type': type.name,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Invalidate cache
      _progressCache.remove(matchId);
    } catch (e) {
      debugPrint('ProgressTracker: Failed to record milestone - $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI INSIGHTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get AI-generated relationship summary
  Future<String?> getRelationshipSummary(String matchId) async {
    final progress = await getProgress(matchId);

    final result = await _aiService.chat(
      systemPrompt: '''Generate a brief, encouraging summary of this relationship's progress.
Keep it under 100 characters. Be warm and positive.''',
      prompt: '''Stats:
- Matched ${progress.stats.daysSinceMatch} days ago
- ${progress.stats.totalMessages} messages exchanged
- Current stage: ${progress.stage.name}
- Milestones: ${progress.milestones.map((m) => m.type.name).join(', ')}

Summary:''',
      maxTokens: 50,
    );

    return result.fold(
      onSuccess: (response) => response.content.trim(),
      onFailure: (_) => null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isCacheValid(String matchId) {
    if (!_progressCache.containsKey(matchId)) return false;
    final timestamp = _cacheTimestamps[matchId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  void _cacheProgress(String matchId, RelationshipProgress progress) {
    _progressCache[matchId] = progress;
    _cacheTimestamps[matchId] = DateTime.now();
  }

  void clearCache(String? matchId) {
    if (matchId != null) {
      _progressCache.remove(matchId);
      _cacheTimestamps.remove(matchId);
    } else {
      _progressCache.clear();
      _cacheTimestamps.clear();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum RelationshipStage {
  justMatched,
  iceBreaking,
  earlyConversation,
  gettingToKnow,
  deepConnection,
  escalating,
  planningDate,
  dating,
}

extension RelationshipStageExtension on RelationshipStage {
  String get label {
    switch (this) {
      case RelationshipStage.justMatched:
        return 'Just Matched';
      case RelationshipStage.iceBreaking:
        return 'Breaking the Ice';
      case RelationshipStage.earlyConversation:
        return 'Getting Started';
      case RelationshipStage.gettingToKnow:
        return 'Getting to Know Each Other';
      case RelationshipStage.deepConnection:
        return 'Deep Connection';
      case RelationshipStage.escalating:
        return 'Taking it Further';
      case RelationshipStage.planningDate:
        return 'Planning a Date';
      case RelationshipStage.dating:
        return 'Dating!';
    }
  }

  String get emoji {
    switch (this) {
      case RelationshipStage.justMatched:
        return '✨';
      case RelationshipStage.iceBreaking:
        return '🧊';
      case RelationshipStage.earlyConversation:
        return '💬';
      case RelationshipStage.gettingToKnow:
        return '🌱';
      case RelationshipStage.deepConnection:
        return '💫';
      case RelationshipStage.escalating:
        return '🚀';
      case RelationshipStage.planningDate:
        return '📅';
      case RelationshipStage.dating:
        return '💕';
    }
  }

  double get progressPercent {
    switch (this) {
      case RelationshipStage.justMatched:
        return 0.1;
      case RelationshipStage.iceBreaking:
        return 0.2;
      case RelationshipStage.earlyConversation:
        return 0.35;
      case RelationshipStage.gettingToKnow:
        return 0.5;
      case RelationshipStage.deepConnection:
        return 0.65;
      case RelationshipStage.escalating:
        return 0.8;
      case RelationshipStage.planningDate:
        return 0.9;
      case RelationshipStage.dating:
        return 1.0;
    }
  }
}

enum MilestoneType {
  matched,
  firstMessage,
  deepConversation,
  phoneMentioned,
  phoneCall,
  dateMentioned,
  datePlanned,
  dateCompleted,
  exclusive,
}

class Milestone {
  final MilestoneType type;
  final DateTime achievedAt;
  final String title;

  Milestone({
    required this.type,
    required this.achievedAt,
    required this.title,
  });
}

class MatchStats {
  final DateTime matchedAt;
  final int totalMessages;
  final int myMessages;
  final int theirMessages;
  final int daysSinceMatch;
  final Duration? averageResponseTime;
  final DateTime? lastMessageAt;

  MatchStats({
    required this.matchedAt,
    required this.totalMessages,
    required this.myMessages,
    required this.theirMessages,
    required this.daysSinceMatch,
    this.averageResponseTime,
    this.lastMessageAt,
  });

  factory MatchStats.empty() => MatchStats(
        matchedAt: DateTime.now(),
        totalMessages: 0,
        myMessages: 0,
        theirMessages: 0,
        daysSinceMatch: 0,
      );

  double get conversationBalance {
    if (totalMessages == 0) return 0.5;
    return myMessages / totalMessages;
  }

  bool get isBalanced => conversationBalance > 0.35 && conversationBalance < 0.65;

  String get balanceLabel {
    if (totalMessages < 5) return 'Just getting started';
    if (isBalanced) return 'Great balance! 💚';
    if (conversationBalance > 0.65) return 'You\'re doing most of the talking';
    return 'They\'re doing most of the talking';
  }
}

enum NextStepUrgency {
  low,
  medium,
  high,
}

class NextStep {
  final String action;
  final String emoji;
  final String reason;
  final NextStepUrgency urgency;

  NextStep({
    required this.action,
    required this.emoji,
    required this.reason,
    required this.urgency,
  });
}

class RelationshipProgress {
  final String matchId;
  final RelationshipStage stage;
  final MatchStats stats;
  final List<Milestone> milestones;
  final NextStep? suggestedNextStep;

  RelationshipProgress({
    required this.matchId,
    required this.stage,
    required this.stats,
    required this.milestones,
    this.suggestedNextStep,
  });
}
