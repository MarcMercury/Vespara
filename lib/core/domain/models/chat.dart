import 'package:equatable/equatable.dart';

/// Chat message for The Wire
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.isFromMe,
    this.type = MessageType.text,
    required this.content,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaDurationSeconds,
    this.replyToId,
    this.reactions = const [],
    this.isRead = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.isAiGenerated = false,
    required this.createdAt,
    this.editedAt,
  });

  factory ChatMessage.fromJson(
          Map<String, dynamic> json, String currentUserId) =>
      ChatMessage(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        isFromMe: json['sender_id'] == currentUserId,
        type: MessageType.fromString(json['message_type'] as String?),
        content: json['content'] as String? ?? '',
        mediaUrl: json['media_url'] as String?,
        mediaThumbnailUrl: json['media_thumbnail_url'] as String?,
        mediaDurationSeconds: json['media_duration_seconds'] as int?,
        replyToId: json['reply_to_id'] as String?,
        reactions: (json['reactions'] as List?)
                ?.map((r) => MessageReaction.fromJson(r))
                .toList() ??
            [],
        isRead: json['is_read'] as bool? ?? false,
        isEdited: json['is_edited'] as bool? ?? false,
        isDeleted: json['is_deleted'] as bool? ?? false,
        isAiGenerated: json['is_ai_generated'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        editedAt: json['edited_at'] != null
            ? DateTime.parse(json['edited_at'])
            : null,
      );
  final String id;
  final String conversationId;
  final String senderId;
  final bool isFromMe;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final int? mediaDurationSeconds; // For voice notes
  final String? replyToId;
  final List<MessageReaction> reactions;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final bool isAiGenerated;
  final DateTime createdAt;
  final DateTime? editedAt;

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'message_type': type.value,
        'content': content,
        'media_url': mediaUrl,
        'media_thumbnail_url': mediaThumbnailUrl,
        'media_duration_seconds': mediaDurationSeconds,
        'reply_to_id': replyToId,
        'is_ai_generated': isAiGenerated,
      };

  /// Formatted time for display
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${createdAt.month}/${createdAt.day}';
  }

  @override
  List<Object?> get props => [id, content, createdAt, isRead];
}

/// Message types
enum MessageType {
  text,
  image,
  voice,
  gif,
  reaction,
  system;

  static MessageType fromString(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'gif':
        return MessageType.gif;
      case 'reaction':
        return MessageType.reaction;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
      case MessageType.gif:
        return 'gif';
      case MessageType.reaction:
        return 'reaction';
      case MessageType.system:
        return 'system';
    }
  }
}

/// Message reaction
class MessageReaction extends Equatable {
  const MessageReaction({
    required this.emoji,
    required this.userId,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(
        emoji: json['emoji'] as String,
        userId: json['user_id'] as String,
      );
  final String emoji;
  final String userId;

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'user_id': userId,
      };

  @override
  List<Object?> get props => [emoji, userId];
}

/// Conversation thread
class ChatConversation extends Equatable {
  const ChatConversation({
    required this.id,
    required this.matchId,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageBy,
    this.unreadCount = 0,
    this.momentumScore = 0.5,
    this.isStale = false,
    this.staleSince,
    this.isTyping = false,
    this.isGroupChat = false,
    this.groupId,
    this.groupName,
    this.groupAvatar,
    this.memberCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final isGroup =
        json['conversation_type'] == 'group' || json['is_group_chat'] == true;
    return ChatConversation(
      id: json['id'] as String,
      matchId:
          json['match_link_id'] as String? ?? json['match_id'] as String? ?? '',
      otherUserId: json['other_user_id'] as String? ?? '',
      otherUserName: isGroup ? null : json['other_user_name'] as String?,
      otherUserAvatar: isGroup ? null : json['other_user_avatar'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      lastMessageBy: json['last_message_by'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      momentumScore: (json['momentum_score'] as num?)?.toDouble() ?? 0.5,
      isStale: json['is_stale'] as bool? ?? false,
      staleSince: json['stale_since'] != null
          ? DateTime.parse(json['stale_since'])
          : null,
      isTyping: json['typing_indicator'] != null,
      isGroupChat: isGroup,
      groupId: json['group_id'] as String?,
      groupName: json['group_name'] as String?,
      groupAvatar: json['group_avatar'] as String?,
      memberCount: json['member_count'] as int?,
    );
  }
  final String id;
  final String matchId;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageBy;
  final int unreadCount;
  final double momentumScore;
  final bool isStale;
  final DateTime? staleSince;
  final bool isTyping;

  /// Group chat fields
  final bool isGroupChat;
  final String? groupId;
  final String? groupName;
  final String? groupAvatar;
  final int? memberCount;

  /// Display name for the conversation
  String get displayName {
    if (isGroupChat) return groupName ?? 'Group Chat';
    return otherUserName ?? 'Unknown';
  }

  /// Display avatar for the conversation
  String? get displayAvatar {
    if (isGroupChat) return groupAvatar;
    return otherUserAvatar;
  }

  /// Days since last message
  int get daysSinceMessage {
    if (lastMessageAt == null) return 0;
    return DateTime.now().difference(lastMessageAt!).inDays;
  }

  /// Preview of last message (truncated)
  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';
    if (lastMessage!.length <= 50) return lastMessage!;
    return '${lastMessage!.substring(0, 47)}...';
  }

  @override
  List<Object?> get props =>
      [id, matchId, lastMessageAt, unreadCount, isGroupChat];
}
