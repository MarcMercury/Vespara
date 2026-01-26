import 'package:equatable/equatable.dart';

/// Match between two users
class Match extends Equatable {
  const Match({
    required this.id,
    required this.matchedUserId,
    this.matchedUserName,
    this.matchedUserAvatar,
    this.matchedUserAge,
    required this.matchedAt,
    this.compatibilityScore = 0.5,
    this.isSuperMatch = false,
    this.conversationId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.priority = MatchPriority.new_,
    this.notes,
    this.isArchived = false,
    this.sharedInterests = const [],
    this.suggestedTopics = const [],
    this.suggestedDateIdeas = const [],
  });

  factory Match.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Determine which user fields to use (we're always user_a or user_b)
    final isUserA = json['user_a_id'] == currentUserId;
    final otherUserId = isUserA ? json['user_b_id'] : json['user_a_id'];
    final priority =
        isUserA ? json['user_a_priority'] : json['user_b_priority'];
    final notes = isUserA ? json['user_a_notes'] : json['user_b_notes'];
    final isArchived =
        isUserA ? json['user_a_archived'] : json['user_b_archived'];

    // Get other user's profile if included
    final otherProfile = json['other_profile'] as Map<String, dynamic>?;

    return Match(
      id: json['id'] as String,
      matchedUserId: otherUserId as String,
      matchedUserName: otherProfile?['display_name'] as String?,
      matchedUserAvatar:
          (otherProfile?['photos'] as List?)?.firstOrNull as String?,
      matchedUserAge: otherProfile?['age'] as int?,
      matchedAt: DateTime.parse(json['matched_at'] as String),
      compatibilityScore:
          (json['compatibility_score'] as num?)?.toDouble() ?? 0.5,
      isSuperMatch: json['is_super_match'] as bool? ?? false,
      conversationId: json['conversation_id'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      priority: MatchPriority.fromString(priority as String?),
      notes: notes as String?,
      isArchived: isArchived as bool? ?? false,
      sharedInterests: List<String>.from(json['shared_interests'] ?? []),
      suggestedTopics: List<String>.from(json['suggested_topics'] ?? []),
      suggestedDateIdeas: List<String>.from(json['suggested_date_ideas'] ?? []),
    );
  }
  final String id;
  final String matchedUserId; // The other person
  final String? matchedUserName;
  final String? matchedUserAvatar;
  final int? matchedUserAge;
  final DateTime matchedAt;
  final double compatibilityScore;
  final bool isSuperMatch;

  // Conversation info
  final String? conversationId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  // Nest (Roster) priority
  final MatchPriority priority;
  final String? notes;
  final bool isArchived;

  // AI context
  final List<String> sharedInterests;
  final List<String> suggestedTopics;
  final List<String> suggestedDateIdeas;

  Match copyWith({
    MatchPriority? priority,
    String? notes,
    bool? isArchived,
  }) =>
      Match(
        id: id,
        matchedUserId: matchedUserId,
        matchedUserName: matchedUserName,
        matchedUserAvatar: matchedUserAvatar,
        matchedUserAge: matchedUserAge,
        matchedAt: matchedAt,
        compatibilityScore: compatibilityScore,
        isSuperMatch: isSuperMatch,
        conversationId: conversationId,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
        priority: priority ?? this.priority,
        notes: notes ?? this.notes,
        isArchived: isArchived ?? this.isArchived,
        sharedInterests: sharedInterests,
        suggestedTopics: suggestedTopics,
        suggestedDateIdeas: suggestedDateIdeas,
      );

  /// Days since last message
  int get daysSinceLastMessage {
    if (lastMessageAt == null) return 999;
    return DateTime.now().difference(lastMessageAt!).inDays;
  }

  /// Is conversation going cold
  bool get isGoingCold => daysSinceLastMessage > 3;

  /// Compatibility as percentage
  int get compatibilityPercent => (compatibilityScore * 100).round();

  @override
  List<Object?> get props => [id, matchedUserId, priority, isArchived];
}

/// Nest priority levels
enum MatchPriority {
  new_, // Just matched
  priority, // Priority - actively pursuing
  inWaiting, // In Waiting - pending their response / slow burn
  onWayOut, // On the way out - fading
  legacy; // Legacy - past connections

  static MatchPriority fromString(String? value) {
    switch (value) {
      case 'priority':
        return MatchPriority.priority;
      case 'inWaiting':
        return MatchPriority.inWaiting;
      case 'onWayOut':
        return MatchPriority.onWayOut;
      case 'legacy':
        return MatchPriority.legacy;
      default:
        return MatchPriority.new_;
    }
  }

  String get value {
    switch (this) {
      case MatchPriority.new_:
        return 'new';
      case MatchPriority.priority:
        return 'priority';
      case MatchPriority.inWaiting:
        return 'inWaiting';
      case MatchPriority.onWayOut:
        return 'onWayOut';
      case MatchPriority.legacy:
        return 'legacy';
    }
  }

  String get label {
    switch (this) {
      case MatchPriority.new_:
        return 'New';
      case MatchPriority.priority:
        return 'Priority';
      case MatchPriority.inWaiting:
        return 'In Waiting';
      case MatchPriority.onWayOut:
        return 'On the Way Out';
      case MatchPriority.legacy:
        return 'Legacy';
    }
  }

  String get emoji {
    switch (this) {
      case MatchPriority.new_:
        return '✨';
      case MatchPriority.priority:
        return '🔥';
      case MatchPriority.inWaiting:
        return '⏳';
      case MatchPriority.onWayOut:
        return '🌅';
      case MatchPriority.legacy:
        return '📚';
    }
  }
}
