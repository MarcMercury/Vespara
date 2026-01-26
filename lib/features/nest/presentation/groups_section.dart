import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/group.dart';
import '../../../core/providers/groups_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'group_invitations_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GROUPS SECTION - Part of Sanctum Screen
/// Displays user's groups with create/manage functionality
/// ════════════════════════════════════════════════════════════════════════════

class GroupsSection extends ConsumerWidget {
  const GroupsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref, groupsState),
        const SizedBox(height: 16),
        if (groupsState.isLoading)
          const Center(
              child: CircularProgressIndicator(color: VesparaColors.glow))
        else if (groupsState.groups.isEmpty)
          _buildEmptyState(context)
        else
          _buildGroupsList(context, ref, groupsState.groups),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, GroupsState state) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Invitations button with badge (if any)
            if (state.pendingInvitationCount > 0)
              _buildInvitationsButton(context, state.pendingInvitationCount)
            else
              const SizedBox.shrink(),
            // Create group button - always shown
            GestureDetector(
              onTap: () => _showCreateGroup(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [VesparaColors.glow, VesparaColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: VesparaColors.background, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Create Circle',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.background,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildInvitationsButton(BuildContext context, int count) =>
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroupInvitationsScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: VesparaColors.warning.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: VesparaColors.warning.withOpacity(0.5),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.mail_outline,
                  color: VesparaColors.warning, size: 20),
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: VesparaColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context) {
    // Empty state - just show nothing, Create Circle button is in the header
    return const SizedBox.shrink();
  }

  Widget _buildGroupsList(
          BuildContext context, WidgetRef ref, List<VesparaGroup> groups) =>
      SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: groups.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(right: index < groups.length - 1 ? 12 : 0),
            child: _GroupCard(group: groups[index]),
          ),
        ),
      );

  void _showCreateGroup(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
  }
}

/// Individual group card
class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});
  final VesparaGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => GroupDetailScreen(groupId: group.id)),
          );
        },
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: group.isCreator
                  ? VesparaColors.glow.withOpacity(0.5)
                  : VesparaColors.border,
            ),
            boxShadow: group.isCreator
                ? [
                    BoxShadow(
                      color: VesparaColors.glow.withOpacity(0.2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar / Icon
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: group.avatarUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              group.avatarUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.group,
                            color: VesparaColors.glow,
                            size: 24,
                          ),
                  ),
                  const Spacer(),
                  if (group.isCreator)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VesparaColors.glow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OWNER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.glow,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              // Name
              Text(
                group.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              // Member count
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 14,
                    color: VesparaColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    group.memberCountLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Member avatars
              if (group.memberAvatars.isNotEmpty)
                SizedBox(
                  height: 24,
                  child: Stack(
                    children: [
                      for (int i = 0;
                          i < group.memberAvatars.take(4).length;
                          i++)
                        Positioned(
                          left: i * 16.0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: VesparaColors.surface,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                group.memberAvatars[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: VesparaColors.glow.withOpacity(0.3),
                                  child: const Icon(
                                    Icons.person,
                                    size: 12,
                                    color: VesparaColors.glow,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (group.memberCount > 4)
                        Positioned(
                          left: 64,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: VesparaColors.glow.withOpacity(0.3),
                              border: Border.all(
                                color: VesparaColors.surface,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+${group.memberCount - 4}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: VesparaColors.glow,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}
