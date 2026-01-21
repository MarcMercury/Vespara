import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/group.dart';
import '../../../core/providers/groups_provider.dart';
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
          const Center(child: CircularProgressIndicator(color: VesparaColors.glow))
        else if (groupsState.groups.isEmpty)
          _buildEmptyState(context)
        else
          _buildGroupsList(context, ref, groupsState.groups),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, GroupsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'MY CIRCLES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: VesparaColors.glow,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.groupCount}/$maxGroupsPerUser',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: VesparaColors.glow,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Invitations button with badge
              if (state.pendingInvitationCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildInvitationsButton(context, state.pendingInvitationCount),
                ),
              // Create group button
              if (state.canCreateGroup)
                GestureDetector(
                  onTap: () => _showCreateGroup(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [VesparaColors.glow, VesparaColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: VesparaColors.background, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'CREATE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.background,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsButton(BuildContext context, int count) {
    return GestureDetector(
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
            Icon(Icons.mail_outline, color: VesparaColors.warning, size: 20),
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: VesparaColors.warning,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
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
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: VesparaColors.glow.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_add_outlined,
              size: 48,
              color: VesparaColors.glow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create Your First Circle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gather your favorite people into private groups with shared chat',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showCreateGroup(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [VesparaColors.glow, VesparaColors.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, color: VesparaColors.background),
                  const SizedBox(width: 8),
                  Text(
                    'Create Circle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(BuildContext context, WidgetRef ref, List<VesparaGroup> groups) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < groups.length - 1 ? 12 : 0),
            child: _GroupCard(group: groups[index]),
          );
        },
      ),
    );
  }

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
  final VesparaGroup group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
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
          boxShadow: group.isCreator ? [
            BoxShadow(
              color: VesparaColors.glow.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ] : null,
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
                      : Icon(
                          Icons.group,
                          color: VesparaColors.glow,
                          size: 24,
                        ),
                ),
                const Spacer(),
                if (group.isCreator)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            // Member count
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: VesparaColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  group.memberCountLabel,
                  style: TextStyle(
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
                    for (int i = 0; i < group.memberAvatars.take(4).length; i++)
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
                              errorBuilder: (_, __, ___) => Container(
                                color: VesparaColors.glow.withOpacity(0.3),
                                child: Icon(
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
                              style: TextStyle(
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
}
