import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/group.dart';
import '../../../core/providers/groups_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'group_detail_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GROUP INVITATIONS SCREEN
/// View and respond to pending group invitations
/// ════════════════════════════════════════════════════════════════════════════

class GroupInvitationsScreen extends ConsumerWidget {
  const GroupInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupsProvider);
    final pendingInvitations = groupsState.pendingInvitations;

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: pendingInvitations.isEmpty
                  ? _buildEmptyState()
                  : _buildInvitationsList(pendingInvitations, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            const Expanded(
              child: Text(
                'Circle Invitations',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 48,
                  color: VesparaColors.glow.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Pending Invitations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'When someone invites you to join their circle, it will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInvitationsList(
    List<GroupInvitation> invitations,
    WidgetRef ref,
  ) =>
      ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invitations.length,
        itemBuilder: (context, index) => _InvitationCard(
          invitation: invitations[index],
          onAccept: () => _handleAccept(context, ref, invitations[index]),
          onDecline: () => _handleDecline(context, ref, invitations[index]),
        ),
      );

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    GroupInvitation invitation,
  ) async {
    HapticFeedback.mediumImpact();

    // Check if user can join more groups
    final canJoin = ref.read(canCreateGroupProvider);
    if (!canJoin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You\'ve reached the maximum of $maxGroupsPerUser circles. Leave one to join another.',
          ),
          backgroundColor: VesparaColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(groupsProvider.notifier).acceptInvitation(
          invitation.id,
        );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You joined ${invitation.groupName}!'),
            backgroundColor: VesparaColors.success,
          ),
        );
        // Navigate to the group
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(groupId: invitation.groupId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join group'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDecline(
    BuildContext context,
    WidgetRef ref,
    GroupInvitation invitation,
  ) async {
    HapticFeedback.lightImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: const Text(
          'Decline Invitation?',
          style: TextStyle(color: VesparaColors.primary),
        ),
        content: Text(
          'Are you sure you want to decline the invitation to ${invitation.groupName}?',
          style: const TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: VesparaColors.secondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Decline',
              style: TextStyle(color: VesparaColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(groupsProvider.notifier).declineInvitation(invitation.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            backgroundColor: VesparaColors.secondary,
          ),
        );
      }
    }
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  });
  final GroupInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with group info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Group avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: invitation.groupAvatar != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              invitation.groupAvatar!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.group,
                            size: 28, color: VesparaColors.glow),
                  ),
                  const SizedBox(width: 16),
                  // Group name and inviter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invitation.groupName ?? 'Unknown Group',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Inviter avatar
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: VesparaColors.glow.withOpacity(0.3),
                              ),
                              child: invitation.inviterAvatar != null
                                  ? ClipOval(
                                      child: Image.network(
                                        invitation.inviterAvatar!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 12,
                                      color: VesparaColors.glow,
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Invited by ${invitation.inviterName ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: VesparaColors.secondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Expiry notice
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: VesparaColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: VesparaColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getExpiryText(invitation.expiresAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: VesparaColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Decline button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: VesparaColors.secondary,
                        side: const BorderSide(color: VesparaColors.inactive),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Accept button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VesparaColors.glow,
                        foregroundColor: VesparaColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Join Circle',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _getExpiryText(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.isNegative) {
      return 'Expired';
    } else if (diff.inHours < 1) {
      return 'Expires in ${diff.inMinutes} minutes';
    } else if (diff.inHours < 24) {
      return 'Expires in ${diff.inHours} hours';
    } else {
      return 'Expires in ${diff.inDays} days';
    }
  }
}
