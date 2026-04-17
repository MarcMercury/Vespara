import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/group.dart';
import '../../../core/domain/models/plan_event.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/domain/models/wire_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/groups_provider.dart';
import '../../../core/providers/plan_provider.dart';
import '../../../core/providers/wire_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/premium_effects.dart';
import '../../wire/presentation/wire_chat_screen.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'group_invitations_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// NEST SCREEN - Module 3
/// Community member directory & circles
/// ════════════════════════════════════════════════════════════════════════════

class NestScreen extends ConsumerStatefulWidget {
  const NestScreen({super.key});

  @override
  ConsumerState<NestScreen> createState() => _NestScreenState();
}

class _NestScreenState extends ConsumerState<NestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _glowController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: VesparaAnimatedBackground(
          enableParticles: true,
          particleCount: 12,
          auroraIntensity: 0.6,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStats(),
                _buildTabBar(),
                Expanded(
                  child: _buildTabBarView(),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            Column(
              children: [
                VesparaNeonText(
                  text: 'THE SANCTUM',
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: VesparaColors.primary,
                  ),
                  glowColor: const Color(0xFF4ECDC4),
                  glowRadius: 12,
                ),
                const SizedBox(height: 2),
                Text(
                  'Your community',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _showSearchDialog,
              icon: const Icon(Icons.search, color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  Widget _buildStats() {
    final membersAsync = ref.watch(allMembersProvider);
    final groupsState = ref.watch(groupsProvider);

    final memberCount = membersAsync.when(
      loading: () => 0,
      error: (_, __) => 0,
      data: (members) => members.length,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Members', memberCount.toString(), VesparaColors.primary),
          _buildStatDivider(),
          _buildStatItem(
              'Circles', groupsState.groupCount.toString(), VesparaColors.glow),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) => Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      );

  Widget _buildStatDivider() => Container(
        width: 1,
        height: 30,
        color: VesparaColors.glow.withOpacity(0.2),
      );

  Widget _buildTabBar() {
    final groupsState = ref.watch(groupsProvider);
    final membersAsync = ref.watch(allMembersProvider);

    final memberCount = membersAsync.when(
      loading: () => 0,
      error: (_, __) => 0,
      data: (members) => members.length,
    );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: TabBar(
        controller: _tabController,
        labelColor: VesparaColors.primary,
        unselectedLabelColor: VesparaColors.secondary,
        indicatorColor: VesparaColors.glow,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👥'),
                const SizedBox(width: 6),
                const Text('MEMBERS'),
                if (memberCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      memberCount.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭕'),
                const SizedBox(width: 6),
                const Text('CIRCLES'),
                if (groupsState.groupCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      groupsState.groupCount.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() => TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(),
          _buildCirclesTab(),
        ],
      );

  // ════════════════════════════════════════════════════════════════════════════
  // MEMBERS TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMembersTab() {
    final membersAsync = ref.watch(allMembersProvider);

    return membersAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: VesparaColors.glow)),
      error: (e, _) => Center(
        child: Text('Error loading members',
            style: TextStyle(color: VesparaColors.error)),
      ),
      data: (members) {
        final filtered = _searchQuery.isEmpty
            ? members
            : members
                .where((m) => (m.displayName ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
                .toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 48, color: VesparaColors.secondary),
                SizedBox(height: 16),
                Text('No members yet',
                    style:
                        TextStyle(fontSize: 16, color: VesparaColors.secondary)),
                SizedBox(height: 8),
                Text('Members will appear here once they join',
                    style:
                        TextStyle(fontSize: 13, color: VesparaColors.inactive)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) =>
              _buildMemberCard(filtered[index]),
        );
      },
    );
  }

  Widget _buildMemberCard(CommunityMember member) => AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) => GestureDetector(
          onTap: () => _showMemberDetails(member),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: VesparaColors.glow.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.glow.withOpacity(0.2),
                        border: Border.all(
                          color: VesparaColors.glow.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: member.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                member.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    (member.displayName ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: VesparaColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                (member.displayName ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: VesparaColors.primary,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Name and info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                member.displayName ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: VesparaColors.primary,
                                ),
                              ),
                              if (member.age != null) ...[
                                Text(
                                  ', ${member.age}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: VesparaColors.secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Community member',
                            style: TextStyle(
                              fontSize: 12,
                              color: VesparaColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPlanDateDialog(member),
                        icon: const Icon(Icons.event_available, size: 16),
                        label: const Text('Plan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VesparaColors.success,
                          side: const BorderSide(
                            color: VesparaColors.success,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openMessageWithMember(member),
                        icon: const Icon(Icons.chat_bubble, size: 16),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VesparaColors.glow,
                          foregroundColor: VesparaColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // CIRCLES TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildCirclesTab() {
    final groupsState = ref.watch(groupsProvider);

    if (groupsState.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: VesparaColors.glow));
    }

    return Column(
      children: [
        // Create Circle + Invitations header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your private circles',
                  style: TextStyle(
                    fontSize: 13,
                    color: VesparaColors.secondary.withOpacity(0.7),
                  ),
                ),
              ),
              if (groupsState.pendingInvitationCount > 0) ...[
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GroupInvitationsScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VesparaColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: VesparaColors.warning.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail_outline,
                            color: VesparaColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${groupsState.pendingInvitationCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: VesparaColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateGroupScreen()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VesparaColors.glow, VesparaColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add,
                          color: VesparaColors.background, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Create Circle',
                        style: TextStyle(
                          fontSize: 12,
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
        ),

        if (groupsState.groups.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_outlined,
                      size: 48, color: VesparaColors.secondary),
                  const SizedBox(height: 16),
                  const Text(
                    'No circles yet',
                    style:
                        TextStyle(fontSize: 16, color: VesparaColors.secondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a circle to group members\ninto your own private chats',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: VesparaColors.secondary.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupsState.groups.length,
              itemBuilder: (context, index) =>
                  _buildCircleListItem(groupsState.groups[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildCircleListItem(VesparaGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: group.isCreator
              ? VesparaColors.glow.withOpacity(0.3)
              : VesparaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        child:
                            Image.network(group.avatarUrl!, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.group,
                        color: VesparaColors.glow, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                          ),
                        ),
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
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatChip(
                            '${group.memberCount} members', VesparaColors.glow),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Chat button - always visible, opens the circle's group chat
              Expanded(
                child: GestureDetector(
                  onTap: () => _openCircleChat(group),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: VesparaColors.glow.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: VesparaColors.glow, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.glow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // View / Manage button
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            GroupDetailScreen(groupId: group.id)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: group.isCreator
                          ? const LinearGradient(
                              colors: [
                                VesparaColors.glow,
                                VesparaColors.secondary
                              ],
                            )
                          : null,
                      color: group.isCreator
                          ? null
                          : VesparaColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: group.isCreator
                          ? null
                          : Border.all(
                              color: VesparaColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          group.isCreator
                              ? Icons.settings
                              : Icons.visibility,
                          color: group.isCreator
                              ? VesparaColors.background
                              : VesparaColors.secondary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          group.isCreator ? 'Manage' : 'View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: group.isCreator
                                ? VesparaColors.background
                                : VesparaColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (group.isCreator) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDeleteGroup(group),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VesparaColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: VesparaColors.error.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: VesparaColors.error, size: 18),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _openCircleChat(VesparaGroup group) async {
    final navigator = Navigator.of(context);

    if (group.conversationId != null) {
      // Load conversations so we can find this one
      await ref.read(wireProvider.notifier).loadConversations();
      final wireState = ref.read(wireProvider);
      final conversation = wireState.conversations.cast<WireConversation?>().firstWhere(
        (c) => c!.id == group.conversationId,
        orElse: () => null,
      );

      if (conversation != null && mounted) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => WireChatScreen(conversation: conversation),
          ),
        );
        return;
      }
    }

    // Fallback: conversation not found or no conversationId
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Circle chat not available. Try opening from the circle details.'),
          backgroundColor: VesparaColors.error,
        ),
      );
    }
  }

  void _showMemberDetails(CommunityMember member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => _MemberProfileSheet(
        member: member,
        onMessage: () {
          Navigator.pop(context);
          _openMessageWithMember(member);
        },
        onPlan: () {
          Navigator.pop(context);
          _showPlanDateDialog(member);
        },
      ),
    );
  }

  Future<void> _openMessageWithMember(CommunityMember member) async {
    final navigator = Navigator.of(context);

    final conversationId = await ref
        .read(wireProvider.notifier)
        .getOrCreateDirectConversation(member.id);

    if (conversationId != null && mounted) {
      final wireState = ref.read(wireProvider);
      final conversation = wireState.conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => WireConversation(
          id: conversationId,
          matchId: member.id,
          matchName: member.displayName,
          matchAvatarUrl: member.avatarUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      navigator.push(
        MaterialPageRoute(
          builder: (context) => WireChatScreen(conversation: conversation),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open chat right now. Please try again.'),
          backgroundColor: VesparaColors.error,
        ),
      );
    }
  }

  void _showPlanDateDialog(CommunityMember member) {
    final recommendation = _recommendPlanSlot();
    final recommendationLabel = _formatPlanDateTime(recommendation.startTime);

    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: VesparaColors.secondary,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Plan with ${member.displayName}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VesparaColors.background.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VesparaColors.glow.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended shared time',
                    style: TextStyle(
                      color: VesparaColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendationLabel,
                    style: const TextStyle(
                      color: VesparaColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              recommendation.title,
              style: const TextStyle(
                color: VesparaColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _sendPlanInviteMessage(
                        member,
                        recommendation.startTime,
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VesparaColors.glow,
                      side: const BorderSide(color: VesparaColors.glow),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _savePlanRecommendation(member, recommendation);
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Save Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VesparaColors.success,
                      foregroundColor: VesparaColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  _PlanRecommendation _recommendPlanSlot() {
    final planState = ref.read(planProvider);
    final now = DateTime.now();
    final busyEvents =
        planState.allEvents.where((e) => !e.isCancelled).toList();

    final candidates = <_PlanRecommendation>[
      _PlanRecommendation(
        title: 'Tonight check-in',
        startTime: DateTime(now.year, now.month, now.day, 19),
      ),
      _PlanRecommendation(
        title: 'Midweek dinner',
        startTime: DateTime(now.year, now.month, now.day + 2, 19),
      ),
      _PlanRecommendation(
        title: 'Weekend hang',
        startTime: DateTime(now.year, now.month, now.day + 5, 14),
      ),
      _PlanRecommendation(
        title: 'Next-week meetup',
        startTime: DateTime(now.year, now.month, now.day + 7, 18),
      ),
    ];

    final firstOpen = candidates.firstWhere(
      (candidate) =>
          candidate.startTime.isAfter(now.add(const Duration(hours: 2))) &&
          !_hasPlanConflict(candidate.startTime, busyEvents),
      orElse: () => candidates.last,
    );

    return firstOpen;
  }

  bool _hasPlanConflict(DateTime startTime, List<PlanEvent> events) {
    final endTime = startTime.add(const Duration(hours: 2));
    for (final event in events) {
      final eventEnd =
          event.endTime ?? event.startTime.add(const Duration(hours: 2));
      final overlaps =
          event.startTime.isBefore(endTime) && eventEnd.isAfter(startTime);
      if (overlaps) return true;
    }
    return false;
  }

  String _formatPlanDateTime(DateTime dateTime) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day} at $hour12:$minute $period';
  }

  Future<void> _savePlanRecommendation(
    CommunityMember member,
    _PlanRecommendation recommendation,
  ) async {
    try {
      final connection = EventConnection(
        id: member.id,
        name: member.displayName ?? 'Unknown',
        avatarUrl: member.avatarUrl,
      );

      final event = PlanEvent(
        id: 'event-${DateTime.now().millisecondsSinceEpoch}',
        userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        title:
            '${recommendation.title} with ${member.displayName ?? 'Unknown'}',
        startTime: recommendation.startTime,
        endTime: recommendation.startTime.add(const Duration(hours: 2)),
        connections: [connection],
        certainty: EventCertainty.exploring,
        createdAt: DateTime.now(),
      );

      await ref.read(planProvider.notifier).createEvent(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plan saved for ${_formatPlanDateTime(recommendation.startTime)}',
            ),
            backgroundColor: VesparaColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save plan: $e'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendPlanInviteMessage(
      CommunityMember member, DateTime planTime) async {
    final conversationId = await ref
        .read(wireProvider.notifier)
        .getOrCreateDirectConversation(member.id);

    if (conversationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open conversation'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
      return;
    }

    final message =
        'Hey ${member.displayName}! Want to connect on ${_formatPlanDateTime(planTime)}?';
    final sent = await ref.read(wireProvider.notifier).sendMessage(
          conversationId: conversationId,
          content: message,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent != null
                ? 'Message sent to ${member.displayName}'
                : 'Failed to send message',
          ),
          backgroundColor:
              sent != null ? VesparaColors.success : VesparaColors.error,
        ),
      );
    }
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              autofocus: true,
              style: const TextStyle(color: VesparaColors.primary),
              decoration: InputDecoration(
                hintText: 'Search members...',
                hintStyle: const TextStyle(color: VesparaColors.secondary),
                prefixIcon: const Icon(Icons.search, color: VesparaColors.glow),
                filled: true,
                fillColor: VesparaColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (query) {
                Navigator.pop(context);
                setState(() => _searchQuery = query);
                _tabController.animateTo(0);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGroup(VesparaGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Circle?',
          style: TextStyle(color: VesparaColors.primary),
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This will remove all members and cannot be undone.',
          style: const TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(groupsProvider.notifier).deleteGroup(group.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Circle deleted'),
                      backgroundColor: VesparaColors.surface,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete circle'),
                      backgroundColor: VesparaColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: VesparaColors.error)),
          ),
        ],
      ),
    );
  }
}

class _PlanRecommendation {
  const _PlanRecommendation({
    required this.title,
    required this.startTime,
  });

  final String title;
  final DateTime startTime;
}

// ════════════════════════════════════════════════════════════════════════════
// MEMBER PROFILE SHEET
// ════════════════════════════════════════════════════════════════════════════

class _MemberProfileSheet extends ConsumerStatefulWidget {
  const _MemberProfileSheet({
    required this.member,
    required this.onMessage,
    required this.onPlan,
  });

  final CommunityMember member;
  final VoidCallback onMessage;
  final VoidCallback onPlan;

  @override
  ConsumerState<_MemberProfileSheet> createState() =>
      _MemberProfileSheetState();
}

class _MemberProfileSheetState extends ConsumerState<_MemberProfileSheet> {
  UserProfile? _profile;
  bool _isLoadingProfile = true;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.member.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _profile = UserProfile.fromJson(response);
          _isLoadingProfile = false;
        });
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VesparaColors.glow.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotoCarousel(),
                      const SizedBox(height: 20),
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 24),
                      if (_profile?.bio != null && _profile!.bio!.isNotEmpty)
                        _buildAboutSection(),
                      if (_profile?.vibeTags.isNotEmpty == true)
                        _buildTagsSection(
                            'Vibe', _profile!.vibeTags, VesparaColors.glow),
                      if (_profile?.interestTags.isNotEmpty == true)
                        _buildTagsSection('Interests', _profile!.interestTags,
                            VesparaColors.success),
                      SizedBox(
                          height:
                              MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPhotoCarousel() {
    final photos = _profile?.photos ?? [];
    final avatarUrl = widget.member.avatarUrl;
    final displayPhotos = photos.isNotEmpty
        ? photos
        : (avatarUrl != null ? [avatarUrl] : <String>[]);

    if (displayPhotos.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: VesparaColors.glow.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            (widget.member.displayName ?? '?')[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: VesparaColors.primary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 350,
            width: double.infinity,
            child: PageView.builder(
              itemCount: displayPhotos.length,
              onPageChanged: (index) =>
                  setState(() => _currentPhotoIndex = index),
              itemBuilder: (context, index) => Image.network(
                displayPhotos[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: VesparaColors.background,
                  child: const Icon(Icons.broken_image,
                      size: 48, color: VesparaColors.secondary),
                ),
              ),
            ),
          ),
        ),
        if (displayPhotos.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                displayPhotos.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _currentPhotoIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _currentPhotoIndex
                        ? VesparaColors.glow
                        : VesparaColors.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final name =
        _profile?.displayName ?? widget.member.displayName ?? 'Unknown';
    final age = _profile?.age ?? widget.member.age;
    final headline = _profile?.headline;
    final location = _profile?.city ?? _profile?.location;
    final isVerified = _profile?.isVerified ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.primary,
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      ', $age',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ],
                  if (isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified,
                        color: VesparaColors.glow, size: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (headline != null && headline.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 16,
              color: VesparaColors.secondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (location != null && location.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 14, color: VesparaColors.secondary),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 13,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() => Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onMessage,
              icon: const Icon(Icons.chat_bubble, size: 18),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.glow,
                foregroundColor: VesparaColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onPlan,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Plan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: VesparaColors.success,
                side: const BorderSide(color: VesparaColors.success),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildAboutSection() => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _profile!.bio!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildTagsSection(String title, List<String> tags, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(fontSize: 12, color: color),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
}
