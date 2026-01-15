import 'package:equatable/equatable.dart';

/// Conversation/Message model for The Wire
class Conversation extends Equatable {
  final String id;
  final String matchId;
  final String matchName;
  final String? matchAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final double momentumScore;
  final bool isStale;
  final DateTime createdAt;
  
  const Conversation({
    required this.id,
    required this.matchId,
    required this.matchName,
    this.matchAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.momentumScore = 0.0,
    this.isStale = false,
    required this.createdAt,
  });
  
  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Handle joined roster_matches data
    final matchData = json['roster_matches'] as Map<String, dynamic>?;
    
    return Conversation(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      matchName: matchData?['name'] as String? ?? json['match_name'] as String? ?? 'Unknown',
      matchAvatarUrl: matchData?['avatar_url'] as String? ?? json['match_avatar_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      momentumScore: (json['momentum_score'] as num?)?.toDouble() ?? 0.0,
      isStale: json['is_stale'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'match_name': matchName,
      'match_avatar_url': matchAvatarUrl,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'momentum_score': momentumScore,
      'is_stale': isStale,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  Conversation copyWith({
    String? id,
    String? matchId,
    String? matchName,
    String? matchAvatarUrl,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    double? momentumScore,
    bool? isStale,
    DateTime? createdAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      matchName: matchName ?? this.matchName,
      matchAvatarUrl: matchAvatarUrl ?? this.matchAvatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      momentumScore: momentumScore ?? this.momentumScore,
      isStale: isStale ?? this.isStale,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    matchId,
    matchName,
    matchAvatarUrl,
    lastMessage,
    lastMessageAt,
    unreadCount,
    momentumScore,
    isStale,
    createdAt,
  ];
}

/// Individual message model
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final String? aiSuggestion;
  
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.aiSuggestion,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      aiSuggestion: json['ai_suggestion'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
      'is_read': isRead,
      'ai_suggestion': aiSuggestion,
    };
  }
  
  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    sentAt,
    isRead,
    aiSuggestion,
  ];
}
