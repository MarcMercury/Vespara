import 'package:equatable/equatable.dart';

/// Analytics data for The Mirror - Brutal Truth Edition
class UserAnalytics extends Equatable {
  const UserAnalytics({
    required this.userId,
    this.ghostRate = 0.0,
    this.flakeRate = 0.0,
    this.swipeRatio = 50.0,
    this.responseRate = 50.0,
    this.matchRate = 0.0,
    this.totalMatches = 0,
    this.activeConversations = 0,
    this.activeDays = 0,
    this.datesScheduled = 0,
    this.messagesSent = 0,
    this.messagesReceived = 0,
    this.firstMessagesSent = 0,
    this.conversationsStarted = 0,
    this.weeklyActivity = const [0, 0, 0, 0, 0, 0, 0],
    this.peakActivityTime = '8pm - 10pm',
    required this.lastUpdated,
    this.aiPersonalitySummary,
    this.aiDatingStyle,
    this.aiImprovementTips,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) => UserAnalytics(
        userId: json['user_id'] as String,
        ghostRate: (json['ghost_rate'] as num?)?.toDouble() ?? 0.0,
        flakeRate: (json['flake_rate'] as num?)?.toDouble() ?? 0.0,
        swipeRatio: (json['swipe_ratio'] as num?)?.toDouble() ?? 50.0,
        responseRate: (json['response_rate'] as num?)?.toDouble() ?? 50.0,
        totalMatches: json['total_matches'] as int? ?? 0,
        activeConversations: json['active_conversations'] as int? ?? 0,
        datesScheduled: json['dates_scheduled'] as int? ?? 0,
        messagesSent: json['messages_sent'] as int? ?? 0,
        messagesReceived: json['messages_received'] as int? ?? 0,
        firstMessagesSent: json['first_messages_sent'] as int? ?? 0,
        conversationsStarted: json['conversations_started'] as int? ?? 0,
        weeklyActivity: (json['weekly_activity'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [0, 0, 0, 0, 0, 0, 0],
        peakActivityTime: json['peak_activity_time'] as String? ?? '8pm - 10pm',
        lastUpdated: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );
  final String userId;
  final double ghostRate;
  final double flakeRate;
  final double swipeRatio;
  final double responseRate;
  final double matchRate;
  final int totalMatches;
  final int activeConversations;
  final int activeDays;
  final int datesScheduled;
  final int messagesSent;
  final int messagesReceived;
  final int firstMessagesSent;
  final int conversationsStarted;
  final List<double> weeklyActivity;
  final String peakActivityTime;
  final DateTime lastUpdated;

  // AI Brutal Truth fields
  final String? aiPersonalitySummary;
  final String? aiDatingStyle;
  final List<String>? aiImprovementTips;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'ghost_rate': ghostRate,
        'flake_rate': flakeRate,
        'swipe_ratio': swipeRatio,
        'response_rate': responseRate,
        'total_matches': totalMatches,
        'active_conversations': activeConversations,
        'dates_scheduled': datesScheduled,
        'messages_sent': messagesSent,
        'messages_received': messagesReceived,
        'first_messages_sent': firstMessagesSent,
        'conversations_started': conversationsStarted,
        'weekly_activity': weeklyActivity,
        'peak_activity_time': peakActivityTime,
        'updated_at': lastUpdated.toIso8601String(),
      };

  /// Get a "brutal truth" insight based on analytics
  String get brutalTruth {
    if (ghostRate > 50) {
      return 'You ghost more than Casper. Consider closing conversations properly.';
    }
    if (flakeRate > 50) {
      return 'Your flake rate is high. Your word should mean something.';
    }
    if (responseRate < 30) {
      return 'Low response rate. Are you even trying?';
    }
    return 'You\'re doing well. Keep the momentum.';
  }

  /// Get optimization score (0-100)
  double get optimizationScore {
    final score = (100 - ghostRate) * 0.25 +
        (100 - flakeRate) * 0.25 +
        responseRate * 0.25 +
        swipeRatio * 0.25;
    return score.clamp(0.0, 100.0);
  }

  /// Count of stale matches (calculated separately but stored for UI display)
  int get staleMatches => 0; // This is calculated from roster, not stored

  @override
  List<Object?> get props => [
        userId,
        ghostRate,
        flakeRate,
        swipeRatio,
        responseRate,
        totalMatches,
        activeConversations,
        datesScheduled,
        messagesSent,
        messagesReceived,
        firstMessagesSent,
        conversationsStarted,
        weeklyActivity,
        peakActivityTime,
        lastUpdated,
      ];
}
