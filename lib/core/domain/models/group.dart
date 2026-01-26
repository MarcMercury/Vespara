import 'package:equatable/equatable.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// VESPARA GROUPS DOMAIN MODELS
/// Social circles for Sanctum with integrated Wire chat
/// ════════════════════════════════════════════════════════════════════════════

/// Group member role
enum GroupRole {
  creator,
  member;

  static GroupRole fromString(String? value) {
    switch (value) {
      case 'creator':
        return GroupRole.creator;
      default:
        return GroupRole.member;
    }
  }

  String get value => name;

  String get displayName {
    switch (this) {
      case GroupRole.creator:
        return 'Creator';
      case GroupRole.member:
        return 'Member';
    }
  }
}

/// Group member status
enum GroupMemberStatus {
  active,
  left,
  removed;

  static GroupMemberStatus fromString(String? value) {
    switch (value) {
      case 'left':
        return GroupMemberStatus.left;
      case 'removed':
        return GroupMemberStatus.removed;
      default:
        return GroupMemberStatus.active;
    }
  }

  String get value => name;
}

/// Invitation status
enum InvitationStatus {
  pending,
  accepted,
  declined;

  static InvitationStatus fromString(String? value) {
    switch (value) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      default:
        return InvitationStatus.pending;
    }
  }

  String get value => name;
}

/// A Vespara Group (Social Circle)
class VesparaGroup extends Equatable {
  const VesparaGroup({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.creatorId,
    this.conversationId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.memberCount = 1,
    this.memberAvatars = const [],
    this.currentUserRole,
    this.currentUserJoinedAt,
  });

  factory VesparaGroup.fromJson(Map<String, dynamic> json) => VesparaGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        creatorId: json['creator_id'] as String,
        conversationId: json['conversation_id'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        memberCount: json['member_count'] as int? ?? 1,
        memberAvatars:
            (json['member_avatars'] as List?)?.whereType<String>().toList() ??
                [],
        currentUserRole: json['role'] != null
            ? GroupRole.fromString(json['role'] as String?)
            : null,
        currentUserJoinedAt: json['joined_at'] != null
            ? DateTime.parse(json['joined_at'] as String)
            : null,
      );
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String creatorId;
  final String? conversationId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed/joined fields
  final int memberCount;
  final List<String> memberAvatars;
  final GroupRole? currentUserRole;
  final DateTime? currentUserJoinedAt;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'avatar_url': avatarUrl,
      };

  bool get isCreator => currentUserRole == GroupRole.creator;

  String get memberCountLabel {
    if (memberCount == 1) return '1 member';
    return '$memberCount members';
  }

  VesparaGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    String? creatorId,
    String? conversationId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    List<String>? memberAvatars,
    GroupRole? currentUserRole,
    DateTime? currentUserJoinedAt,
  }) =>
      VesparaGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        creatorId: creatorId ?? this.creatorId,
        conversationId: conversationId ?? this.conversationId,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        memberCount: memberCount ?? this.memberCount,
        memberAvatars: memberAvatars ?? this.memberAvatars,
        currentUserRole: currentUserRole ?? this.currentUserRole,
        currentUserJoinedAt: currentUserJoinedAt ?? this.currentUserJoinedAt,
      );

  @override
  List<Object?> get props => [id, name, memberCount, isActive];
}

/// A member of a group
class GroupMember extends Equatable {
  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.status = GroupMemberStatus.active,
    this.role = GroupRole.member,
    required this.joinedAt,
    this.leftAt,
    this.userName,
    this.userAvatar,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      status: GroupMemberStatus.fromString(json['status'] as String?),
      role: GroupRole.fromString(json['role'] as String?),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] != null
          ? DateTime.parse(json['left_at'] as String)
          : null,
      userName:
          profile?['display_name'] as String? ?? json['user_name'] as String?,
      userAvatar:
          profile?['avatar_url'] as String? ?? json['user_avatar'] as String?,
    );
  }
  final String id;
  final String groupId;
  final String userId;
  final GroupMemberStatus status;
  final GroupRole role;
  final DateTime joinedAt;
  final DateTime? leftAt;

  // Joined profile data
  final String? userName;
  final String? userAvatar;

  bool get isCreator => role == GroupRole.creator;
  bool get isActive => status == GroupMemberStatus.active;

  @override
  List<Object?> get props => [id, groupId, userId, status, role];
}

/// An invitation to join a group
class GroupInvitation extends Equatable {
  const GroupInvitation({
    required this.id,
    required this.groupId,
    required this.inviterId,
    required this.inviteeId,
    this.status = InvitationStatus.pending,
    this.message,
    this.respondedAt,
    required this.expiresAt,
    required this.createdAt,
    this.groupName,
    this.groupDescription,
    this.groupAvatar,
    this.inviterName,
    this.inviterAvatar,
    this.memberCount,
  });

  factory GroupInvitation.fromJson(Map<String, dynamic> json) =>
      GroupInvitation(
        id: json['invitation_id'] as String? ?? json['id'] as String,
        groupId: json['group_id'] as String,
        inviterId: json['inviter_id'] as String,
        inviteeId: json['invitee_id'] as String,
        status: InvitationStatus.fromString(json['status'] as String?),
        message: json['message'] as String?,
        respondedAt: json['responded_at'] != null
            ? DateTime.parse(json['responded_at'] as String)
            : null,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        groupName: json['group_name'] as String?,
        groupDescription: json['group_description'] as String?,
        groupAvatar: json['group_avatar'] as String?,
        inviterName: json['inviter_name'] as String?,
        inviterAvatar: json['inviter_avatar'] as String?,
        memberCount: json['member_count'] as int?,
      );
  final String id;
  final String groupId;
  final String inviterId;
  final String inviteeId;
  final InvitationStatus status;
  final String? message;
  final DateTime? respondedAt;
  final DateTime expiresAt;
  final DateTime createdAt;

  // Joined data
  final String? groupName;
  final String? groupDescription;
  final String? groupAvatar;
  final String? inviterName;
  final String? inviterAvatar;
  final int? memberCount;

  bool get isPending => status == InvitationStatus.pending;
  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get canRespond => isPending && !isExpired;

  Duration get expiresIn => expiresAt.difference(DateTime.now());

  String get expiresInLabel {
    final diff = expiresIn;
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  @override
  List<Object?> get props => [id, groupId, inviteeId, status];
}

/// Notification model
class VesparaNotification extends Equatable {
  const VesparaNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.message,
    this.data,
    this.actionUrl,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory VesparaNotification.fromJson(Map<String, dynamic> json) =>
      VesparaNotification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String?,
        data: json['data'] as Map<String, dynamic>?,
        actionUrl: json['action_url'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? message;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isGroupInvitation => type == 'group_invitation';

  String? get invitationId => data?['invitation_id'] as String?;
  String? get groupId => data?['group_id'] as String?;
  String? get groupName => data?['group_name'] as String?;

  @override
  List<Object?> get props => [id, type, isRead];
}
