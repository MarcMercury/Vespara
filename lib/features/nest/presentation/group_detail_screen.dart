import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/group.dart';
import '../../../core/domain/models/match.dart';
import '../../../core/providers/groups_provider.dart';
import '../../../core/providers/match_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../wire/presentation/wire_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GROUP DETAIL SCREEN
/// View members, manage group (if creator), access group chat
/// ════════════════════════════════════════════════════════════════════════════

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  List<GroupMember> _members = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members =
        await ref.read(groupsProvider.notifier).getGroupMembers(widget.groupId);
    setState(() {
      _members = members;
      _isLoadingMembers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId));

    if (group == null) {
      return const Scaffold(
        backgroundColor: VesparaColors.background,
        body: Center(
          child: Text(
            'Group not found',
            style: TextStyle(color: VesparaColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(group),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupInfo(group),
                    const SizedBox(height: 24),
                    _buildQuickActions(group),
                    const SizedBox(height: 24),
                    _buildMembersSection(group),
                    if (group.isCreator) ...[
                      const SizedBox(height: 24),
                      _buildInviteSection(group),
                    ],
                    const SizedBox(height: 24),
                    _buildDangerZone(group),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(VesparaGroup group) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            Expanded(
              child: Text(
                group.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
            ),
            if (group.isCreator)
              IconButton(
                onPressed: () => _showEditGroup(group),
                icon: const Icon(Icons.edit_outlined,
                    color: VesparaColors.secondary,),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      );

  Widget _buildGroupInfo(VesparaGroup group) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VesparaColors.glow.withOpacity(0.2),
              VesparaColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // Group avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: VesparaColors.glow.withOpacity(0.5)),
              ),
              child: group.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(group.avatarUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.group,
                      size: 40, color: VesparaColors.glow,),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              group.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
            ),
            if (group.description != null) ...[
              const SizedBox(height: 8),
              Text(
                group.description!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  icon: Icons.people,
                  label: group.memberCountLabel,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: group.isCreator ? Icons.star : Icons.person,
                  label: group.isCreator ? 'Creator' : 'Member',
                  color: group.isCreator ? VesparaColors.warning : null,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    Color? color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? VesparaColors.glow).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? VesparaColors.glow),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color ?? VesparaColors.glow,
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickActions(VesparaGroup group) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Open Chat',
                color: VesparaColors.glow,
                onTap: () => _openGroupChat(group),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.calendar_today_outlined,
                label: 'Plan Event',
                color: VesparaColors.success,
                onTap: () => _planGroupEvent(group),
              ),
            ),
          ],
        ),
      );

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMembersSection(VesparaGroup group) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'MEMBERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: VesparaColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingMembers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: VesparaColors.glow),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _members.length,
              itemBuilder: (context, index) =>
                  _buildMemberTile(_members[index], group),
            ),
        ],
      );

  Widget _buildMemberTile(GroupMember member, VesparaGroup group) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: member.isCreator
              ? Border.all(color: VesparaColors.warning.withOpacity(0.5))
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VesparaColors.glow.withOpacity(0.2),
                border: member.isCreator
                    ? Border.all(color: VesparaColors.warning, width: 2)
                    : null,
              ),
              child: member.userAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        member.userAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, color: VesparaColors.glow),
                      ),
                    )
                  : const Icon(Icons.person, color: VesparaColors.glow),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.userName ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        ),
                      ),
                      if (member.isCreator) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: VesparaColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'CREATOR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Joined ${_formatDate(member.joinedAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            // Actions (for creator only, on non-creator members)
            if (group.isCreator && !member.isCreator)
              IconButton(
                onPressed: () => _showMemberActions(member),
                icon: const Icon(
                  Icons.more_vert,
                  color: VesparaColors.secondary,
                  size: 20,
                ),
              ),
          ],
        ),
      );

  Widget _buildInviteSection(VesparaGroup group) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INVITE MORE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: VesparaColors.secondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showInviteDialog(group),
                  icon: const Icon(Icons.add,
                      size: 18, color: VesparaColors.glow,),
                  label: const Text(
                    'Invite',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.glow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: VesparaColors.secondary, size: 18,),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Only you can invite new members to this group',
                    style: TextStyle(
                      fontSize: 13,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildDangerZone(VesparaGroup group) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.isCreator ? 'DANGER ZONE' : 'LEAVE GROUP',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: VesparaColors.error,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _confirmLeave(group),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VesparaColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: VesparaColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      group.isCreator ? Icons.delete_forever : Icons.logout,
                      color: VesparaColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.isCreator ? 'Delete Group' : 'Leave Group',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.error,
                            ),
                          ),
                          Text(
                            group.isCreator
                                ? 'This will remove all members and delete the chat'
                                : 'You will lose access to this group and its chat',
                            style: TextStyle(
                              fontSize: 12,
                              color: VesparaColors.error.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: VesparaColors.error,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  void _showEditGroup(VesparaGroup group) {
    // TODO: Implement edit group
  }

  void _openGroupChat(VesparaGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WireScreen()),
    );
  }

  void _planGroupEvent(VesparaGroup group) {
    // TODO: Navigate to event creation with group
  }

  void _showMemberActions(GroupMember member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VesparaColors.inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.person, color: VesparaColors.primary),
              title: const Text(
                'View Profile',
                style: TextStyle(color: VesparaColors.primary),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to member profile view
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening ${member.userName}\'s profile'),
                    backgroundColor: VesparaColors.glow,
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.remove_circle, color: VesparaColors.error),
              title: const Text(
                'Remove from Group',
                style: TextStyle(color: VesparaColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveMember(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(GroupMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: Text(
          'Remove ${member.userName}?',
          style: const TextStyle(color: VesparaColors.primary),
        ),
        content: const Text(
          'They will lose access to this group and its chat.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(groupsProvider.notifier).removeMember(
                  widget.groupId,
                  member.userId,
                );
                // Refresh members list
                _loadMembers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${member.userName} removed from group'),
                      backgroundColor: VesparaColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove member: $e'),
                      backgroundColor: VesparaColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(VesparaGroup group) {
    final matches = ref.read(matchStateProvider).matches;
    final existingMemberIds = _members.map((m) => m.userId).toSet();
    final invitableMatches = matches
        .where((m) => !existingMemberIds.contains(m.matchedUserId))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: VesparaColors.inactive,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Invite to ${group.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: invitableMatches.isEmpty
                  ? const Center(
                      child: Text(
                        'All your matches are already in this group',
                        style: TextStyle(color: VesparaColors.secondary),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: invitableMatches.length,
                      itemBuilder: (context, index) {
                        final match = invitableMatches[index];
                        return _InviteMatchTile(
                          match: match,
                          onInvite: () async {
                            final success = await ref
                                .read(groupsProvider.notifier)
                                .sendInvitation(
                                  groupId: group.id,
                                  inviteeId: match.matchedUserId,
                                );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Invitation sent to ${match.matchedUserName}!'
                                        : 'Failed to send invitation',
                                  ),
                                  backgroundColor: success
                                      ? VesparaColors.success
                                      : VesparaColors.error,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeave(VesparaGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: Text(
          group.isCreator ? 'Delete Group?' : 'Leave Group?',
          style: const TextStyle(color: VesparaColors.primary),
        ),
        content: Text(
          group.isCreator
              ? 'This will permanently delete the group and remove all members. This cannot be undone.'
              : 'You will lose access to this group and its chat history.',
          style: const TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await ref.read(groupsProvider.notifier).leaveGroup(group.id);
              if (mounted && success) {
                Navigator.pop(context); // Go back from detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      group.isCreator ? 'Group deleted' : 'You left the group',
                    ),
                    backgroundColor: VesparaColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.error,
            ),
            child: Text(group.isCreator ? 'Delete' : 'Leave'),
          ),
        ],
      ),
    );
  }
}

class _InviteMatchTile extends StatelessWidget {
  const _InviteMatchTile({
    required this.match,
    required this.onInvite,
  });
  final Match match;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VesparaColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VesparaColors.glow.withOpacity(0.2),
              ),
              child: match.matchedUserAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        match.matchedUserAvatar!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.person, color: VesparaColors.glow),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                match.matchedUserName ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: onInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.glow,
                foregroundColor: VesparaColors.background,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Invite'),
            ),
          ],
        ),
      );
}
