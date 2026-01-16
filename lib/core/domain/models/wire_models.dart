import 'package:equatable/equatable.dart';

// ============================================================================
// WIRE MESSAGING MODELS - WhatsApp-style Group Chat Support
// ============================================================================

/// Conversation type - Direct 1:1 or Group
enum ConversationType { direct, group }

/// Message type - All the types of content that can be sent
enum MessageType {
  text,
  image,
  video,
  voice,
  audio,
  file,
  gif,
  sticker,
  location,
  contact,
  poll,
  system,
}

/// Message delivery/read status
enum MessageStatus { sending, sent, delivered, read, failed }

/// Participant role in group conversations
enum ParticipantRole { admin, member }

// ============================================================================
// ENHANCED CONVERSATION MODEL
// ============================================================================

class WireConversation extends Equatable {
  final String id;
  final ConversationType type;
  
  // For direct conversations
  final String? matchId;
  final String? matchName;
  final String? matchAvatarUrl;
  
  // For group conversations
  final String? groupName;
  final String? groupDescription;
  final String? groupAvatarUrl;
  final String? groupCreatedBy;
  final int participantCount;
  
  // Last message info
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;
  final MessageType? lastMessageType;
  
  // Read/unread state
  final int unreadCount;
  final String? lastReadMessageId;
  final DateTime? lastReadAt;
  
  // Conversation state
  final bool isMuted;
  final DateTime? mutedUntil;
  final bool isPinned;
  final int pinOrder;
  final bool isArchived;
  final DateTime? archivedAt;
  
  // Typing indicator
  final List<TypingUser> typingUsers;
  
  // Group settings
  final bool onlyAdminsCanSend;
  final bool onlyAdminsCanEditInfo;
  final bool allowMemberInvite;
  final int? disappearingMessagesSeconds;
  
  // For Roster integration (momentum scoring)
  final double momentumScore;
  final bool isStale;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const WireConversation({
    required this.id,
    this.type = ConversationType.direct,
    this.matchId,
    this.matchName,
    this.matchAvatarUrl,
    this.groupName,
    this.groupDescription,
    this.groupAvatarUrl,
    this.groupCreatedBy,
    this.participantCount = 2,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    this.lastMessageType,
    this.unreadCount = 0,
    this.lastReadMessageId,
    this.lastReadAt,
    this.isMuted = false,
    this.mutedUntil,
    this.isPinned = false,
    this.pinOrder = 0,
    this.isArchived = false,
    this.archivedAt,
    this.typingUsers = const [],
    this.onlyAdminsCanSend = false,
    this.onlyAdminsCanEditInfo = false,
    this.allowMemberInvite = true,
    this.disappearingMessagesSeconds,
    this.momentumScore = 0.0,
    this.isStale = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Get display name - either match name or group name
  String get displayName => type == ConversationType.group 
      ? groupName ?? 'Unnamed Group'
      : matchName ?? 'Unknown';
  
  /// Get avatar URL
  String? get avatarUrl => type == ConversationType.group 
      ? groupAvatarUrl 
      : matchAvatarUrl;
  
  /// Check if this is a group conversation
  bool get isGroup => type == ConversationType.group;
  
  factory WireConversation.fromJson(Map<String, dynamic> json) {
    // Handle joined data structures
    final matchData = json['roster_matches'] as Map<String, dynamic>?;
    final participantsData = json['conversation_participants'] as List<dynamic>?;
    
    return WireConversation(
      id: json['id'] as String,
      type: json['conversation_type'] == 'group' 
          ? ConversationType.group 
          : ConversationType.direct,
      matchId: json['match_id'] as String?,
      matchName: matchData?['name'] as String? ?? json['match_name'] as String?,
      matchAvatarUrl: matchData?['avatar_url'] as String? ?? json['match_avatar_url'] as String?,
      groupName: json['group_name'] as String?,
      groupDescription: json['group_description'] as String?,
      groupAvatarUrl: json['group_avatar_url'] as String?,
      groupCreatedBy: json['group_created_by'] as String?,
      participantCount: json['participant_count'] as int? ?? 2,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      lastMessageSenderName: json['last_message_sender_name'] as String?,
      lastMessageType: _parseMessageType(json['last_message_type'] as String?),
      unreadCount: json['unread_count'] as int? ?? 0,
      lastReadMessageId: json['last_read_message_id'] as String?,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
      isMuted: json['is_muted'] as bool? ?? false,
      mutedUntil: json['muted_until'] != null
          ? DateTime.parse(json['muted_until'] as String)
          : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      pinOrder: json['pin_order'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      typingUsers: [], // Populated via realtime subscription
      onlyAdminsCanSend: json['only_admins_can_send'] as bool? ?? false,
      onlyAdminsCanEditInfo: json['only_admins_can_edit_info'] as bool? ?? false,
      allowMemberInvite: json['allow_member_invite'] as bool? ?? true,
      disappearingMessagesSeconds: json['disappearing_messages_seconds'] as int?,
      momentumScore: (json['momentum_score'] as num?)?.toDouble() ?? 0.0,
      isStale: json['is_stale'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_type': type == ConversationType.group ? 'group' : 'direct',
      'match_id': matchId,
      'match_name': matchName,
      'match_avatar_url': matchAvatarUrl,
      'group_name': groupName,
      'group_description': groupDescription,
      'group_avatar_url': groupAvatarUrl,
      'group_created_by': groupCreatedBy,
      'participant_count': participantCount,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'is_muted': isMuted,
      'muted_until': mutedUntil?.toIso8601String(),
      'is_pinned': isPinned,
      'pin_order': pinOrder,
      'is_archived': isArchived,
      'archived_at': archivedAt?.toIso8601String(),
      'only_admins_can_send': onlyAdminsCanSend,
      'only_admins_can_edit_info': onlyAdminsCanEditInfo,
      'allow_member_invite': allowMemberInvite,
      'disappearing_messages_seconds': disappearingMessagesSeconds,
      'momentum_score': momentumScore,
      'is_stale': isStale,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  WireConversation copyWith({
    String? id,
    ConversationType? type,
    String? matchId,
    String? matchName,
    String? matchAvatarUrl,
    String? groupName,
    String? groupDescription,
    String? groupAvatarUrl,
    String? groupCreatedBy,
    int? participantCount,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    MessageType? lastMessageType,
    int? unreadCount,
    String? lastReadMessageId,
    DateTime? lastReadAt,
    bool? isMuted,
    DateTime? mutedUntil,
    bool? isPinned,
    int? pinOrder,
    bool? isArchived,
    DateTime? archivedAt,
    List<TypingUser>? typingUsers,
    bool? onlyAdminsCanSend,
    bool? onlyAdminsCanEditInfo,
    bool? allowMemberInvite,
    int? disappearingMessagesSeconds,
    double? momentumScore,
    bool? isStale,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WireConversation(
      id: id ?? this.id,
      type: type ?? this.type,
      matchId: matchId ?? this.matchId,
      matchName: matchName ?? this.matchName,
      matchAvatarUrl: matchAvatarUrl ?? this.matchAvatarUrl,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      groupCreatedBy: groupCreatedBy ?? this.groupCreatedBy,
      participantCount: participantCount ?? this.participantCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSenderName: lastMessageSenderName ?? this.lastMessageSenderName,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCount: unreadCount ?? this.unreadCount,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      isPinned: isPinned ?? this.isPinned,
      pinOrder: pinOrder ?? this.pinOrder,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      typingUsers: typingUsers ?? this.typingUsers,
      onlyAdminsCanSend: onlyAdminsCanSend ?? this.onlyAdminsCanSend,
      onlyAdminsCanEditInfo: onlyAdminsCanEditInfo ?? this.onlyAdminsCanEditInfo,
      allowMemberInvite: allowMemberInvite ?? this.allowMemberInvite,
      disappearingMessagesSeconds: disappearingMessagesSeconds ?? this.disappearingMessagesSeconds,
      momentumScore: momentumScore ?? this.momentumScore,
      isStale: isStale ?? this.isStale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, type, matchId, matchName, groupName, participantCount,
    lastMessage, lastMessageAt, unreadCount, isMuted, isPinned,
    isArchived, momentumScore, isStale, updatedAt,
  ];
}

// ============================================================================
// WIRE MESSAGE MODEL
// ============================================================================

class WireMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? content;
  final MessageType type;
  final MessageStatus status;
  
  // Media attachments
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final String? mediaFilename;
  final int? mediaFilesizeBytes;
  final String? mediaMimeType;
  final int? mediaWidth;
  final int? mediaHeight;
  final int? mediaDurationSeconds;
  final List<double>? mediaWaveform; // For voice messages
  
  // Reply/forward
  final String? replyToId;
  final String? replyPreview;
  final String? replySenderName;
  final String? forwardedFromId;
  final int forwardCount;
  
  // Location
  final double? locationLat;
  final double? locationLng;
  final String? locationName;
  final String? locationAddress;
  
  // Contact sharing
  final String? sharedContactId;
  final String? sharedContactName;
  final String? sharedContactPhone;
  
  // Poll
  final String? pollQuestion;
  final List<PollOption>? pollOptions;
  final bool pollAllowsMultiple;
  final DateTime? pollEndsAt;
  
  // Reactions
  final List<MessageReaction> reactions;
  final int reactionCount;
  
  // Delivery/read receipts
  final DateTime? deliveredAt;
  final List<Receipt> deliveredTo;
  final List<Receipt> readBy;
  
  // Edit/delete state
  final bool isEdited;
  final DateTime? editedAt;
  final String? originalContent;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool deletedForEveryone;
  
  // Star/pin
  final List<String> starredBy;
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;
  
  // Auto-delete
  final DateTime? expiresAt;
  
  // Metadata
  final String? clientMessageId;
  final Map<String, dynamic> metadata;
  
  final DateTime createdAt;
  
  const WireMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaFilename,
    this.mediaFilesizeBytes,
    this.mediaMimeType,
    this.mediaWidth,
    this.mediaHeight,
    this.mediaDurationSeconds,
    this.mediaWaveform,
    this.replyToId,
    this.replyPreview,
    this.replySenderName,
    this.forwardedFromId,
    this.forwardCount = 0,
    this.locationLat,
    this.locationLng,
    this.locationName,
    this.locationAddress,
    this.sharedContactId,
    this.sharedContactName,
    this.sharedContactPhone,
    this.pollQuestion,
    this.pollOptions,
    this.pollAllowsMultiple = false,
    this.pollEndsAt,
    this.reactions = const [],
    this.reactionCount = 0,
    this.deliveredAt,
    this.deliveredTo = const [],
    this.readBy = const [],
    this.isEdited = false,
    this.editedAt,
    this.originalContent,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedForEveryone = false,
    this.starredBy = const [],
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
    this.expiresAt,
    this.clientMessageId,
    this.metadata = const {},
    required this.createdAt,
  });
  
  /// Check if message is from current user
  bool isFromMe(String currentUserId) => senderId == currentUserId;
  
  /// Check if message has been read by everyone
  bool get isReadByAll => status == MessageStatus.read;
  
  /// Get a preview text for this message
  String get previewText {
    if (isDeleted) return 'This message was deleted';
    switch (type) {
      case MessageType.text:
        return content ?? '';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📎 ${mediaFilename ?? 'File'}';
      case MessageType.gif:
        return 'GIF';
      case MessageType.sticker:
        return 'Sticker';
      case MessageType.location:
        return '📍 ${locationName ?? 'Location'}';
      case MessageType.contact:
        return '👤 ${sharedContactName ?? 'Contact'}';
      case MessageType.poll:
        return '📊 ${pollQuestion ?? 'Poll'}';
      case MessageType.system:
        return content ?? '';
    }
  }
  
  factory WireMessage.fromJson(Map<String, dynamic> json) {
    // Parse sender data if joined
    final senderData = json['profiles'] as Map<String, dynamic>?;
    
    return WireMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: senderData?['display_name'] as String? ?? json['sender_name'] as String?,
      senderAvatarUrl: senderData?['avatar_url'] as String? ?? json['sender_avatar_url'] as String?,
      content: json['content'] as String?,
      type: _parseMessageType(json['message_type'] as String?) ?? MessageType.text,
      status: _parseMessageStatus(json['status'] as String?),
      mediaUrl: json['media_url'] as String?,
      mediaThumbnailUrl: json['media_thumbnail_url'] as String?,
      mediaFilename: json['media_filename'] as String?,
      mediaFilesizeBytes: json['media_filesize_bytes'] as int?,
      mediaMimeType: json['media_mime_type'] as String?,
      mediaWidth: json['media_width'] as int?,
      mediaHeight: json['media_height'] as int?,
      mediaDurationSeconds: json['media_duration_seconds'] as int?,
      mediaWaveform: (json['media_waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      replyToId: json['reply_to_id'] as String?,
      replyPreview: json['reply_preview'] as String?,
      replySenderName: json['reply_sender_name'] as String?,
      forwardedFromId: json['forwarded_from_id'] as String?,
      forwardCount: json['forward_count'] as int? ?? 0,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      locationAddress: json['location_address'] as String?,
      sharedContactId: json['shared_contact_id'] as String?,
      sharedContactName: json['shared_contact_name'] as String?,
      sharedContactPhone: json['shared_contact_phone'] as String?,
      pollQuestion: json['poll_question'] as String?,
      pollOptions: (json['poll_options'] as List<dynamic>?)
          ?.map((e) => PollOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      pollAllowsMultiple: json['poll_allows_multiple'] as bool? ?? false,
      pollEndsAt: json['poll_ends_at'] != null
          ? DateTime.parse(json['poll_ends_at'] as String)
          : null,
      reactions: (json['reactions'] as List<dynamic>?)
          ?.map((e) => MessageReaction.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      reactionCount: json['reaction_count'] as int? ?? 0,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      deliveredTo: (json['delivered_to'] as List<dynamic>?)
          ?.map((e) => Receipt.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      readBy: (json['read_by'] as List<dynamic>?)
          ?.map((e) => Receipt.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      originalContent: json['original_content'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      deletedForEveryone: json['deleted_for_everyone'] as bool? ?? false,
      starredBy: (json['starred_by'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      isPinned: json['is_pinned'] as bool? ?? false,
      pinnedAt: json['pinned_at'] != null
          ? DateTime.parse(json['pinned_at'] as String)
          : null,
      pinnedBy: json['pinned_by'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      clientMessageId: json['client_message_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': type.name,
      'status': status.name,
      'media_url': mediaUrl,
      'media_thumbnail_url': mediaThumbnailUrl,
      'media_filename': mediaFilename,
      'media_filesize_bytes': mediaFilesizeBytes,
      'media_mime_type': mediaMimeType,
      'media_width': mediaWidth,
      'media_height': mediaHeight,
      'media_duration_seconds': mediaDurationSeconds,
      'media_waveform': mediaWaveform,
      'reply_to_id': replyToId,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'location_name': locationName,
      'location_address': locationAddress,
      'shared_contact_id': sharedContactId,
      'shared_contact_name': sharedContactName,
      'shared_contact_phone': sharedContactPhone,
      'poll_question': pollQuestion,
      'poll_options': pollOptions?.map((e) => e.toJson()).toList(),
      'poll_allows_multiple': pollAllowsMultiple,
      'poll_ends_at': pollEndsAt?.toIso8601String(),
      'client_message_id': clientMessageId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  WireMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? content,
    MessageType? type,
    MessageStatus? status,
    String? mediaUrl,
    List<MessageReaction>? reactions,
    bool? isEdited,
    bool? isDeleted,
    List<String>? starredBy,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return WireMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl,
      mediaFilename: mediaFilename,
      mediaFilesizeBytes: mediaFilesizeBytes,
      mediaMimeType: mediaMimeType,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      mediaDurationSeconds: mediaDurationSeconds,
      mediaWaveform: mediaWaveform,
      replyToId: replyToId,
      replyPreview: replyPreview,
      replySenderName: replySenderName,
      forwardedFromId: forwardedFromId,
      forwardCount: forwardCount,
      locationLat: locationLat,
      locationLng: locationLng,
      locationName: locationName,
      locationAddress: locationAddress,
      sharedContactId: sharedContactId,
      sharedContactName: sharedContactName,
      sharedContactPhone: sharedContactPhone,
      pollQuestion: pollQuestion,
      pollOptions: pollOptions,
      pollAllowsMultiple: pollAllowsMultiple,
      pollEndsAt: pollEndsAt,
      reactions: reactions ?? this.reactions,
      reactionCount: reactionCount,
      deliveredAt: deliveredAt,
      deliveredTo: deliveredTo,
      readBy: readBy,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt,
      originalContent: originalContent,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt,
      deletedForEveryone: deletedForEveryone,
      starredBy: starredBy ?? this.starredBy,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt,
      pinnedBy: pinnedBy,
      expiresAt: expiresAt,
      clientMessageId: clientMessageId,
      metadata: metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, conversationId, senderId, content, type, status,
    isEdited, isDeleted, reactions, starredBy, isPinned, createdAt,
  ];
}

// ============================================================================
// PARTICIPANT MODEL
// ============================================================================

class ConversationParticipant extends Equatable {
  final String id;
  final String conversationId;
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final ParticipantRole role;
  final bool canSendMessages;
  final bool canAddMembers;
  final DateTime joinedAt;
  final String? addedBy;
  final DateTime? leftAt;
  final String? removedBy;
  final bool isActive;
  final DateTime? lastReadAt;
  final String? lastReadMessageId;
  final int unreadCount;
  final bool isMuted;
  final DateTime? mutedUntil;
  final String? nickname;
  
  const ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.role = ParticipantRole.member,
    this.canSendMessages = true,
    this.canAddMembers = false,
    required this.joinedAt,
    this.addedBy,
    this.leftAt,
    this.removedBy,
    this.isActive = true,
    this.lastReadAt,
    this.lastReadMessageId,
    this.unreadCount = 0,
    this.isMuted = false,
    this.mutedUntil,
    this.nickname,
  });
  
  bool get isAdmin => role == ParticipantRole.admin;
  
  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    
    return ConversationParticipant(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      displayName: profileData?['display_name'] as String? ?? json['display_name'] as String?,
      avatarUrl: profileData?['avatar_url'] as String? ?? json['avatar_url'] as String?,
      role: json['role'] == 'admin' ? ParticipantRole.admin : ParticipantRole.member,
      canSendMessages: json['can_send_messages'] as bool? ?? true,
      canAddMembers: json['can_add_members'] as bool? ?? false,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      addedBy: json['added_by'] as String?,
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at'] as String) : null,
      removedBy: json['removed_by'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastReadAt: json['last_read_at'] != null 
          ? DateTime.parse(json['last_read_at'] as String) 
          : null,
      lastReadMessageId: json['last_read_message_id'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      isMuted: json['is_muted'] as bool? ?? false,
      mutedUntil: json['muted_until'] != null 
          ? DateTime.parse(json['muted_until'] as String) 
          : null,
      nickname: json['nickname'] as String?,
    );
  }
  
  @override
  List<Object?> get props => [
    id, conversationId, userId, role, isActive, unreadCount,
  ];
}

// ============================================================================
// SUPPORTING MODELS
// ============================================================================

class TypingUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime startedAt;
  
  const TypingUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.startedAt,
  });
}

class MessageReaction {
  final String emoji;
  final List<String> userIds;
  
  const MessageReaction({
    required this.emoji,
    required this.userIds,
  });
  
  int get count => userIds.length;
  
  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      userIds: (json['user_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'user_ids': userIds,
  };
}

class Receipt {
  final String userId;
  final DateTime timestamp;
  
  const Receipt({
    required this.userId,
    required this.timestamp,
  });
  
  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      userId: json['user_id'] as String,
      timestamp: DateTime.parse(json['at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'at': timestamp.toIso8601String(),
  };
}

class PollOption {
  final String id;
  final String text;
  final List<String> votes;
  
  const PollOption({
    required this.id,
    required this.text,
    this.votes = const [],
  });
  
  int get voteCount => votes.length;
  
  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      text: json['text'] as String,
      votes: (json['votes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'votes': votes,
  };
}

class MediaAttachment {
  final String id;
  final String messageId;
  final String type;
  final String url;
  final String? thumbnailUrl;
  final String? filename;
  final int? filesizeBytes;
  final String? mimeType;
  final int? width;
  final int? height;
  final int? durationSeconds;
  final List<double>? waveform;
  final int sortOrder;
  
  const MediaAttachment({
    required this.id,
    required this.messageId,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.filename,
    this.filesizeBytes,
    this.mimeType,
    this.width,
    this.height,
    this.durationSeconds,
    this.waveform,
    this.sortOrder = 0,
  });
  
  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      type: json['attachment_type'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      filename: json['filename'] as String?,
      filesizeBytes: json['filesize_bytes'] as int?,
      mimeType: json['mime_type'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      durationSeconds: json['duration_seconds'] as int?,
      waveform: (json['waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

MessageType? _parseMessageType(String? type) {
  if (type == null) return null;
  switch (type.toLowerCase()) {
    case 'text': return MessageType.text;
    case 'image': return MessageType.image;
    case 'video': return MessageType.video;
    case 'voice': return MessageType.voice;
    case 'audio': return MessageType.audio;
    case 'file': return MessageType.file;
    case 'gif': return MessageType.gif;
    case 'sticker': return MessageType.sticker;
    case 'location': return MessageType.location;
    case 'contact': return MessageType.contact;
    case 'poll': return MessageType.poll;
    case 'system': return MessageType.system;
    default: return MessageType.text;
  }
}

MessageStatus _parseMessageStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'sending': return MessageStatus.sending;
    case 'sent': return MessageStatus.sent;
    case 'delivered': return MessageStatus.delivered;
    case 'read': return MessageStatus.read;
    case 'failed': return MessageStatus.failed;
    default: return MessageStatus.sent;
  }
}
