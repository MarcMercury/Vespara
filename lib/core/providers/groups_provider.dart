import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/group.dart';
import '../domain/models/match.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GROUPS PROVIDER
/// State management for Vespara Groups (Social Circles)
/// Handles: Group CRUD, Invitations, Memberships, Notifications
/// ════════════════════════════════════════════════════════════════════════════

// Maximum groups per user
const int maxGroupsPerUser = 10;

/// State class for groups
class GroupsState {
  const GroupsState({
    this.groups = const [],
    this.pendingInvitations = const [],
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });
  final List<VesparaGroup> groups;
  final List<GroupInvitation> pendingInvitations;
  final List<VesparaNotification> notifications;
  final bool isLoading;
  final String? error;

  GroupsState copyWith({
    List<VesparaGroup>? groups,
    List<GroupInvitation>? pendingInvitations,
    List<VesparaNotification>? notifications,
    bool? isLoading,
    String? error,
  }) =>
      GroupsState(
        groups: groups ?? this.groups,
        pendingInvitations: pendingInvitations ?? this.pendingInvitations,
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  int get groupCount => groups.length;
  bool get canCreateGroup => groupCount < maxGroupsPerUser;
  int get remainingSlots => maxGroupsPerUser - groupCount;

  List<VesparaGroup> get createdGroups =>
      groups.where((g) => g.isCreator).toList();

  List<VesparaGroup> get joinedGroups =>
      groups.where((g) => !g.isCreator).toList();

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  int get pendingInvitationCount => pendingInvitations.length;
}

/// Groups state notifier
class GroupsNotifier extends StateNotifier<GroupsState> {
  GroupsNotifier({SupabaseClient? supabase})
      : _supabase = supabase,
        super(const GroupsState()) {
    _initialize();
  }
  final SupabaseClient? _supabase;

  void _initialize() {
    // Load initial data
    loadGroups();
    loadPendingInvitations();
    loadNotifications();

    // Subscribe to realtime updates
    _subscribeToUpdates();
  }

  void _subscribeToUpdates() {
    final userId = _supabase?.auth.currentUser?.id;
    if (userId == null || _supabase == null) return;

    // Subscribe to group changes
    _supabase
        .from('group_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          loadGroups();
        });

    // Subscribe to invitation changes
    _supabase
        .from('group_invitations')
        .stream(primaryKey: ['id'])
        .eq('invitee_id', userId)
        .listen((data) {
          loadPendingInvitations();
        });

    // Subscribe to notifications
    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          loadNotifications();
        });
  }

  /// Load user's groups
  Future<void> loadGroups() async {
    if (_supabase == null) {
      // Use mock data for demo
      _loadMockGroups();
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response = await _supabase
          .from('user_groups_summary')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final groups = (response as List)
          .map((json) => VesparaGroup.fromJson(json))
          .toList();

      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _loadMockGroups() {
    // Generate mock groups for demo
    state = state.copyWith(
      groups: _mockGroups,
      isLoading: false,
    );
  }

  /// Load pending invitations for current user
  Future<void> loadPendingInvitations() async {
    if (_supabase == null) {
      state = state.copyWith(pendingInvitations: _mockInvitations);
      return;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('pending_group_invitations')
          .select()
          .eq('invitee_id', userId)
          .order('created_at', ascending: false);

      final invitations = (response as List)
          .map((json) => GroupInvitation.fromJson(json))
          .toList();

      state = state.copyWith(pendingInvitations: invitations);
    } catch (e) {
      // Silently fail for invitations
    }
  }

  /// Load notifications
  Future<void> loadNotifications() async {
    if (_supabase == null) {
      state = state.copyWith(notifications: _mockNotifications);
      return;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final notifications = (response as List)
          .map((json) => VesparaNotification.fromJson(json))
          .toList();

      state = state.copyWith(notifications: notifications);
    } catch (e) {
      // Silently fail
    }
  }

  /// Create a new group
  Future<VesparaGroup?> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    if (!state.canCreateGroup) {
      state = state.copyWith(error: 'Maximum group limit reached (10)');
      return null;
    }

    if (_supabase == null) {
      // Mock creation
      final newGroup = VesparaGroup(
        id: 'group-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        creatorId: 'current-user',
        conversationId: 'conv-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        currentUserRole: GroupRole.creator,
        currentUserJoinedAt: DateTime.now(),
      );
      state = state.copyWith(groups: [newGroup, ...state.groups]);
      return newGroup;
    }

    state = state.copyWith(isLoading: true);

    try {
      final response = await _supabase.rpc(
        'create_vespara_group',
        params: {
          'p_name': name,
          'p_description': description,
          'p_avatar_url': avatarUrl,
        },
      );

      final groupId = response as String;
      await loadGroups();

      return state.groups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Send invitation to a user
  Future<bool> sendInvitation({
    required String groupId,
    required String inviteeId,
    String? message,
  }) async {
    // Verify caller is group creator
    final group = state.groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Group not found'),
    );

    if (!group.isCreator) {
      state =
          state.copyWith(error: 'Only the group creator can send invitations');
      return false;
    }

    if (_supabase == null) {
      // Mock - just return success
      return true;
    }

    try {
      await _supabase.rpc(
        'send_group_invitation',
        params: {
          'p_group_id': groupId,
          'p_invitee_id': inviteeId,
          'p_message': message,
        },
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Accept an invitation
  Future<bool> acceptInvitation(String invitationId) async {
    if (!state.canCreateGroup) {
      state = state.copyWith(error: 'Maximum group limit reached (10)');
      return false;
    }

    if (_supabase == null) {
      // Mock acceptance
      final invitation = state.pendingInvitations.firstWhere(
        (i) => i.id == invitationId,
        orElse: () => throw Exception('Invitation not found'),
      );

      // Remove from pending
      final newInvitations =
          state.pendingInvitations.where((i) => i.id != invitationId).toList();

      // Add mock group
      final newGroup = VesparaGroup(
        id: invitation.groupId,
        name: invitation.groupName ?? 'New Group',
        description: invitation.groupDescription,
        avatarUrl: invitation.groupAvatar,
        creatorId: invitation.inviterId,
        createdAt: DateTime.now(),
        memberCount: (invitation.memberCount ?? 1) + 1,
        currentUserRole: GroupRole.member,
        currentUserJoinedAt: DateTime.now(),
      );

      state = state.copyWith(
        groups: [newGroup, ...state.groups],
        pendingInvitations: newInvitations,
      );
      return true;
    }

    try {
      await _supabase.rpc(
        'accept_group_invitation',
        params: {'p_invitation_id': invitationId},
      );

      await loadGroups();
      await loadPendingInvitations();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Decline an invitation
  Future<bool> declineInvitation(String invitationId) async {
    if (_supabase == null) {
      // Mock decline
      final newInvitations =
          state.pendingInvitations.where((i) => i.id != invitationId).toList();
      state = state.copyWith(pendingInvitations: newInvitations);
      return true;
    }

    try {
      await _supabase.rpc(
        'decline_group_invitation',
        params: {'p_invitation_id': invitationId},
      );

      await loadPendingInvitations();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    final group = state.groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Group not found'),
    );

    if (_supabase == null) {
      // Mock leave
      final newGroups = state.groups.where((g) => g.id != groupId).toList();
      state = state.copyWith(groups: newGroups);
      return true;
    }

    try {
      await _supabase.rpc(
        'leave_vespara_group',
        params: {'p_group_id': groupId},
      );

      await loadGroups();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a group (creator only)
  Future<bool> deleteGroup(String groupId) async {
    final group = state.groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Group not found'),
    );

    if (!group.isCreator) {
      state =
          state.copyWith(error: 'Only the group creator can delete the group');
      return false;
    }

    if (_supabase == null) {
      // Mock delete
      final newGroups = state.groups.where((g) => g.id != groupId).toList();
      state = state.copyWith(groups: newGroups);
      return true;
    }

    try {
      await _supabase.rpc(
        'delete_vespara_group',
        params: {'p_group_id': groupId},
      );

      await loadGroups();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Get members of a group
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    if (_supabase == null) {
      // Return mock members
      return _mockMembers.where((m) => m.groupId == groupId).toList();
    }

    try {
      final response = await _supabase
          .from('group_members')
          .select('''
            *,
            profiles:user_id (display_name, avatar_url)
          ''')
          .eq('group_id', groupId)
          .eq('status', 'active')
          .order('joined_at');

      return (response as List)
          .map((json) => GroupMember.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get users available to invite (from matches)
  List<Match> getInvitableUsers(String groupId) {
    // TODO: Get matches from database
    // For now return empty list until real data is available
    return [];
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    if (_supabase == null) {
      final newNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return VesparaNotification(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            message: n.message,
            data: n.data,
            actionUrl: n.actionUrl,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: newNotifications);
      return;
    }

    try {
      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String()
      }).eq('id', notificationId);

      await loadNotifications();
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ════════════════════════════════════════════════════════════════════════════

/// Main groups state provider
final groupsProvider =
    StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  SupabaseClient? supabase;
  try {
    supabase = Supabase.instance.client;
  } catch (_) {
    // Supabase not initialized, use mock data
  }
  return GroupsNotifier(supabase: supabase);
});

/// Provider for a specific group
final groupProvider = Provider.family<VesparaGroup?, String>((ref, groupId) {
  final state = ref.watch(groupsProvider);
  try {
    return state.groups.firstWhere((g) => g.id == groupId);
  } catch (_) {
    return null;
  }
});

/// Provider for pending invitations count
final pendingInvitationsCountProvider =
    Provider<int>((ref) => ref.watch(groupsProvider).pendingInvitationCount);

/// Provider for unread notifications count
final unreadNotificationsCountProvider =
    Provider<int>((ref) => ref.watch(groupsProvider).unreadNotificationCount);

/// Provider to check if user can create more groups
final canCreateGroupProvider =
    Provider<bool>((ref) => ref.watch(groupsProvider).canCreateGroup);

// ════════════════════════════════════════════════════════════════════════════
// MOCK DATA FOR DEMO
// ════════════════════════════════════════════════════════════════════════════

final List<VesparaGroup> _mockGroups = [
  VesparaGroup(
    id: 'group-1',
    name: 'Wine Wednesday Crew',
    description: 'Weekly wine tasting adventures',
    creatorId: 'current-user',
    conversationId: 'conv-group-1',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    memberCount: 5,
    memberAvatars: const [
      'https://i.pravatar.cc/150?img=1',
      'https://i.pravatar.cc/150?img=2',
      'https://i.pravatar.cc/150?img=3',
    ],
    currentUserRole: GroupRole.creator,
    currentUserJoinedAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
  VesparaGroup(
    id: 'group-2',
    name: 'Hiking Enthusiasts',
    description: 'Weekend trail explorers',
    creatorId: 'user-other',
    conversationId: 'conv-group-2',
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
    memberCount: 8,
    memberAvatars: const [
      'https://i.pravatar.cc/150?img=4',
      'https://i.pravatar.cc/150?img=5',
      'https://i.pravatar.cc/150?img=6',
    ],
    currentUserRole: GroupRole.member,
    currentUserJoinedAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
];

final List<GroupInvitation> _mockInvitations = [
  GroupInvitation(
    id: 'inv-1',
    groupId: 'group-pending-1',
    inviterId: 'user-alex',
    inviteeId: 'current-user',
    expiresAt: DateTime.now().add(const Duration(days: 5)),
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    groupName: 'Book Club Elite',
    groupDescription: 'Monthly book discussions with cocktails',
    inviterName: 'Alex Morgan',
    inviterAvatar: 'https://i.pravatar.cc/150?img=10',
    memberCount: 6,
  ),
];

final List<VesparaNotification> _mockNotifications = [
  VesparaNotification(
    id: 'notif-1',
    userId: 'current-user',
    type: 'group_invitation',
    title: 'Group Invitation',
    message: 'Alex Morgan invited you to join Book Club Elite',
    data: const {
      'invitation_id': 'inv-1',
      'group_id': 'group-pending-1',
      'group_name': 'Book Club Elite',
      'inviter_id': 'user-alex',
    },
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

final List<GroupMember> _mockMembers = [
  GroupMember(
    id: 'member-1',
    groupId: 'group-1',
    userId: 'current-user',
    role: GroupRole.creator,
    joinedAt: DateTime.now().subtract(const Duration(days: 30)),
    userName: 'You',
    userAvatar: 'https://i.pravatar.cc/150?img=1',
  ),
  GroupMember(
    id: 'member-2',
    groupId: 'group-1',
    userId: 'user-2',
    joinedAt: DateTime.now().subtract(const Duration(days: 25)),
    userName: 'Sarah Chen',
    userAvatar: 'https://i.pravatar.cc/150?img=2',
  ),
  GroupMember(
    id: 'member-3',
    groupId: 'group-1',
    userId: 'user-3',
    joinedAt: DateTime.now().subtract(const Duration(days: 20)),
    userName: 'Marcus Lee',
    userAvatar: 'https://i.pravatar.cc/150?img=3',
  ),
];
