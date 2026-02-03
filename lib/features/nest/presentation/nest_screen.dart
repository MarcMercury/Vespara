import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/group.dart';
import '../../../core/domain/models/match.dart';
import '../../../core/domain/models/plan_event.dart';
import '../../../core/domain/models/profile_photo.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/domain/models/wire_models.dart';
import '../../../core/providers/events_provider.dart';
import '../../../core/providers/groups_provider.dart';
import '../../../core/providers/match_state_provider.dart';
import '../../../core/providers/plan_provider.dart';
import '../../../core/providers/wire_provider.dart';
import '../../../core/services/match_insights_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/photo_ranking_sheet.dart';
import '../../ludus/presentation/tags_screen.dart' show TagScreen;
import '../../planner/presentation/planner_screen.dart';
import '../../wire/presentation/wire_chat_screen.dart';
import '../../wire/presentation/wire_create_group_screen.dart';
import '../../wire/presentation/wire_screen.dart';
import 'group_detail_screen.dart';
import 'groups_section.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// NEST SCREEN (THE SANCTUM) - Module 2
/// CRM-style match management with AI-driven priorities
/// Now includes Wire Chats and Groups functionality
/// Tabs: Chats | New | Priority | In Waiting | Head to Shred | Groups
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

  final List<MatchPriority> _priorities = [
    MatchPriority.new_,
    MatchPriority.priority,
    MatchPriority.inWaiting,
    MatchPriority.onWayOut,
  ];

  @override
  void initState() {
    super.initState();
    // Chats tab + 4 priority tabs + Groups tab = 6 tabs
    _tabController = TabController(length: _priorities.length + 2, vsync: this);
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

  List<Match> _getMatchesForPriority(MatchPriority priority) {
    // Get matches from global state provider
    final state = ref.watch(matchStateProvider);
    return state.getMatchesByPriority(priority);
  }

  void _updateMatchPriority(Match match, MatchPriority newPriority) {
    // Use global state notifier
    ref
        .read(matchStateProvider.notifier)
        .updateMatchPriority(match.id, newPriority);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${match.matchedUserName} moved to ${newPriority.label}'),
        backgroundColor: VesparaColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const GroupsSection(),
                      const SizedBox(height: 16),
                      _buildStats(),
                      _buildTabBar(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: _buildTabBarView(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            const Column(
              children: [
                Text(
                  'THE SANCTUM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: VesparaColors.primary,
                  ),
                ),
                Text(
                  'Your connections, organized',
                  style: TextStyle(
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
    final matchState = ref.watch(matchStateProvider);
    final totalMatches = matchState.matches.where((m) => !m.isArchived).length;
    final priorityCount =
        matchState.getMatchesByPriority(MatchPriority.priority).length;
    final newCount = matchState.getMatchesByPriority(MatchPriority.new_).length;

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
              'Total', totalMatches.toString(), VesparaColors.primary,),
          _buildStatDivider(),
          _buildStatItem('New', newCount.toString(), VesparaColors.tagsYellow),
          _buildStatDivider(),
          _buildStatItem(
              'Priority', priorityCount.toString(), VesparaColors.success,),
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
    final wireState = ref.watch(wireProvider);
    final totalUnread = wireState.totalUnreadCount;
    final groupCount = wireState.groupConversations.length + groupsState.groupCount;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
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
          // Chats tab first (Wire individual chats)
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💬'),
                const SizedBox(width: 6),
                const Text('CHATS'),
                if (totalUnread > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      totalUnread.toString(),
                      style: const TextStyle(fontSize: 10, color: VesparaColors.background),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Priority tabs
          ..._priorities.map((p) {
            final count = _getMatchesForPriority(p).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.emoji),
                  const SizedBox(width: 6),
                  Text(p.label.toUpperCase()),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2,),
                      decoration: BoxDecoration(
                        color: VesparaColors.glow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          // Groups tab at the end (merged Wire Groups + Circles)
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👥'),
                const SizedBox(width: 6),
                const Text('GROUPS'),
                if (groupCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      groupCount.toString(),
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
          // Chats tab content (Wire individual chats)
          _buildChatsTab(),
          // Priority tabs content
          ..._priorities.map((priority) {
            final matches = _getMatchesForPriority(priority);

            if (matches.isEmpty) {
              return _buildEmptyColumn(priority);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) => _buildMatchCard(matches[index]),
            );
          }),
          // Groups tab content (merged Circles + Wire Groups)
          _buildGroupsTab(),
        ],
      );

  // ════════════════════════════════════════════════════════════════════════════
  // CHATS TAB - Wire individual conversations
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildChatsTab() {
    final wireState = ref.watch(wireProvider);
    final conversations = wireState.activeConversations
        .where((c) => !c.isGroup)
        .toList()
      ..sort((a, b) {
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

    if (wireState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VesparaColors.glow),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 48, color: VesparaColors.secondary),
            const SizedBox(height: 16),
            const Text(
              'No conversations yet',
              style: TextStyle(fontSize: 16, color: VesparaColors.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting with your connections',
              style: TextStyle(
                fontSize: 13,
                color: VesparaColors.secondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(wireProvider.notifier).loadConversations(),
      color: VesparaColors.glow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: conversations.length,
        itemBuilder: (context, index) =>
            _buildConversationTile(conversations[index]),
      ),
    );
  }

  Widget _buildConversationTile(WireConversation conversation) {
    return GestureDetector(
      onTap: () {
        VesparaHaptics.lightTap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WireChatScreen(conversation: conversation),
          ),
        );
      },
      onLongPress: () => _showConversationOptions(conversation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: conversation.unreadCount > 0
                ? VesparaColors.glow.withOpacity(0.3)
                : VesparaColors.glow.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VesparaColors.glow.withOpacity(0.2),
                  ),
                  child: conversation.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            conversation.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                conversation.displayName[0].toUpperCase(),
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
                            conversation.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                          ),
                        ),
                ),
                if (conversation.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.glow,
                      ),
                      child: Center(
                        child: Text(
                          conversation.unreadCount > 99
                              ? '99+'
                              : conversation.unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: VesparaColors.background,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (conversation.isPinned) ...[
                            const Icon(Icons.push_pin,
                                size: 14, color: VesparaColors.glow),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            conversation.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: VesparaColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatChatTime(conversation.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: conversation.unreadCount > 0
                              ? VesparaColors.glow
                              : VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: conversation.unreadCount > 0
                                ? VesparaColors.primary
                                : VesparaColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.isMuted)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.volume_off,
                              size: 16, color: VesparaColors.secondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConversationOptions(WireConversation conversation) {
    VesparaHaptics.mediumTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              leading: Icon(
                conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: VesparaColors.glow,
              ),
              title: Text(conversation.isPinned ? 'Unpin Chat' : 'Pin Chat'),
              onTap: () {
                Navigator.pop(context);
                ref.read(wireProvider.notifier).togglePin(conversation.id);
              },
            ),
            ListTile(
              leading: Icon(
                conversation.isMuted ? Icons.volume_up : Icons.volume_off,
                color: VesparaColors.tagsYellow,
              ),
              title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                Navigator.pop(context);
                ref.read(wireProvider.notifier).toggleMute(conversation.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: VesparaColors.secondary),
              title: const Text('Archive Chat'),
              onTap: () {
                Navigator.pop(context);
                ref.read(wireProvider.notifier).archiveConversation(conversation.id);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatChatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $ampm';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GROUPS TAB - Merged Circles + Wire Groups
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildGroupsTab() {
    final groupsState = ref.watch(groupsProvider);
    final wireState = ref.watch(wireProvider);
    final wireGroups = wireState.groupConversations;

    if (groupsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VesparaColors.glow),
      );
    }

    final hasContent = groupsState.groups.isNotEmpty || wireGroups.isNotEmpty;

    if (!hasContent) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined,
                size: 48, color: VesparaColors.secondary),
            const SizedBox(height: 16),
            const Text(
              'No groups yet',
              style: TextStyle(fontSize: 16, color: VesparaColors.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group to chat with multiple connections',
              style: TextStyle(
                fontSize: 13,
                color: VesparaColors.secondary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WireCreateGroupScreen()),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.glow,
                foregroundColor: VesparaColors.background,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Wire group chats first (active conversations)
        if (wireGroups.isNotEmpty) ...[
          _buildSectionHeader('Group Chats', wireGroups.length),
          const SizedBox(height: 12),
          ...wireGroups.map((group) => _buildWireGroupTile(group)),
          if (groupsState.groups.isNotEmpty) const SizedBox(height: 24),
        ],
        // Circles (connection groups)
        if (groupsState.groups.isNotEmpty) ...[
          _buildSectionHeader('Circles', groupsState.groups.length),
          const SizedBox(height: 12),
          ...groupsState.groups.map((group) => _buildCircleListItem(group)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) => Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: VesparaColors.glow,
              ),
            ),
          ),
        ],
      );

  Widget _buildWireGroupTile(WireConversation group) {
    return GestureDetector(
      onTap: () {
        VesparaHaptics.lightTap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WireChatScreen(conversation: group),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: group.unreadCount > 0
                ? VesparaColors.glow.withOpacity(0.3)
                : VesparaColors.glow.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Group avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: VesparaColors.glow.withOpacity(0.2),
                  ),
                  child: group.avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            group.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.group,
                                  size: 26, color: VesparaColors.glow),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.group,
                              size: 26, color: VesparaColors.glow),
                        ),
                ),
                // Participant count badge
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: VesparaColors.background,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      group.participantCount.toString(),
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
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          group.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: group.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: VesparaColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatChatTime(group.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: group.unreadCount > 0
                              ? VesparaColors.glow
                              : VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (group.lastMessageSenderName != null)
                        Text(
                          '${group.lastMessageSenderName}: ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: VesparaColors.glow,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          group.lastMessage ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: group.unreadCount > 0
                                ? VesparaColors.primary
                                : VesparaColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (group.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: VesparaColors.glow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            group.unreadCount > 99
                                ? '99+'
                                : group.unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: VesparaColors.background,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleListItem(VesparaGroup group) {
    // Calculate idle members (those who haven't communicated in 7+ days)
    // For now we'll use a placeholder since we need to track last_message_at per member
    const idleCount = 0; // TODO: Calculate from message activity

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
              // Avatar
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
                        color: VesparaColors.glow, size: 24,),
              ),
              const SizedBox(width: 12),

              // Name and stats
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
                                horizontal: 6, vertical: 2,),
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
                            '${group.memberCount} members', VesparaColors.glow,),
                        const SizedBox(width: 8),
                        if (idleCount > 0)
                          _buildStatChip(
                              '$idleCount idle', VesparaColors.warning,),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (group.isCreator) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showInviteWizard(group),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [VesparaColors.glow, VesparaColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add,
                              color: VesparaColors.background, size: 18,),
                          SizedBox(width: 6),
                          Text(
                            'Invite',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.background,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _confirmDeleteGroup(group),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: VesparaColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: VesparaColors.error.withOpacity(0.3),),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline,
                              color: VesparaColors.error, size: 18,),
                          SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(groupId: group.id),),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: VesparaColors.glow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: VesparaColors.glow.withOpacity(0.3),),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility,
                              color: VesparaColors.glow, size: 18,),
                          SizedBox(width: 6),
                          Text(
                            'View Circle',
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

  void _showInviteWizard(VesparaGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
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
                style: TextStyle(color: VesparaColors.secondary),),
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
                style: TextStyle(color: VesparaColors.error),),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Match match) => AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final isHot = match.priority == MatchPriority.priority;

          return GestureDetector(
            onTap: () => _showMatchDetails(match),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHot
                      ? VesparaColors.glow
                          .withOpacity(0.2 + _glowController.value * 0.2)
                      : VesparaColors.glow.withOpacity(0.1),
                ),
                boxShadow: isHot
                    ? [
                        BoxShadow(
                          color: VesparaColors.glow
                              .withOpacity(0.1 + _glowController.value * 0.1),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
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
                            color: match.isSuperMatch
                                ? VesparaColors.tagsYellow
                                : VesparaColors.glow.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            match.matchedUserName?[0].toUpperCase() ?? '?',
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
                                  match.matchedUserName ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: VesparaColors.primary,
                                  ),
                                ),
                                if (match.matchedUserAge != null) ...[
                                  Text(
                                    ', ${match.matchedUserAge}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: VesparaColors.secondary,
                                    ),
                                  ),
                                ],
                                if (match.isSuperMatch) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: VesparaColors.tagsYellow,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Compatibility
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCompatibilityColor(
                                            match.compatibilityScore,)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${match.compatibilityPercent}% match',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getCompatibilityColor(
                                          match.compatibilityScore,),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Last active
                                Text(
                                  match.lastMessage != null
                                      ? '${match.daysSinceLastMessage}d ago'
                                      : 'New match!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: match.isGoingCold
                                        ? VesparaColors.warning
                                        : VesparaColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Unread badge
                      if (match.unreadCount > 0)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: VesparaColors.glow,
                          ),
                          child: Center(
                            child: Text(
                              match.unreadCount.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: VesparaColors.background,
                              ),
                            ),
                          ),
                        ),

                      // Priority menu
                      PopupMenuButton<MatchPriority>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: VesparaColors.secondary,
                        ),
                        color: VesparaColors.surfaceElevated,
                        onSelected: (priority) =>
                            _updateMatchPriority(match, priority),
                        itemBuilder: (context) => _priorities
                            .map(
                              (p) => PopupMenuItem(
                                value: p,
                                child: Row(
                                  children: [
                                    Text(p.emoji),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Move to ${p.label}',
                                      style: const TextStyle(
                                        color: VesparaColors.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),

                  // Last message preview
                  if (match.lastMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: VesparaColors.background.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: VesparaColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              match.lastMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: VesparaColors.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // AI suggestions
                  if (match.suggestedTopics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: VesparaColors.tagsYellow,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            match.suggestedTopics.first,
                            style: TextStyle(
                              fontSize: 11,
                              color: VesparaColors.tagsYellow.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Shared interests
                  if (match.sharedInterests.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: match.sharedInterests
                          .map(
                            (interest) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: VesparaColors.glow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: VesparaColors.glow,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );

  void _showMatchDetails(Match match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => _MatchProfileSheet(
        match: match,
        onMessage: () => _openMessageWithMatch(match),
        onAskOut: () => _openPlannerWithMatch(match),
        onRankPhotos: () => _openPhotoRankingForMatch(match),
        onShredder: () => _moveToShredder(match),
        onUpdateNotes: (notes) => _updateMatchNotes(match, notes),
      ),
    );
  }

  /// Open Wire chat with this match
  Future<void> _openMessageWithMatch(Match match) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    
    final conversationId = await ref
        .read(wireProvider.notifier)
        .getOrCreateDirectConversation(match.matchedUserId);
    
    if (conversationId != null && mounted) {
      final wireState = ref.read(wireProvider);
      final conversation = wireState.conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => WireConversation(
          id: conversationId,
          matchId: match.matchedUserId,
          matchName: match.matchedUserName,
          matchAvatarUrl: match.matchedUserAvatar,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      navigator.push(
        MaterialPageRoute(
          builder: (context) => WireChatScreen(conversation: conversation),
        ),
      );
    }
  }

  /// Open Planner with match pre-selected for "Ask them out"
  void _openPlannerWithMatch(Match match) {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlannerScreen(
          preselectedMatchId: match.matchedUserId,
          preselectedMatchName: match.matchedUserName,
        ),
      ),
    );
  }

  /// Update notes for a match
  Future<void> _updateMatchNotes(Match match, String notes) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      // Determine which column to update based on which user we are
      final matchData = await Supabase.instance.client
          .from('matches')
          .select('user_a_id')
          .eq('id', match.id)
          .single();
      
      final isUserA = matchData['user_a_id'] == userId;
      final notesColumn = isUserA ? 'user_a_notes' : 'user_b_notes';
      
      await Supabase.instance.client
          .from('matches')
          .update({notesColumn: notes})
          .eq('id', match.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes saved'),
            backgroundColor: VesparaColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save notes'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: VesparaColors.secondary,
        ),
      );

  Widget _buildEmptyColumn(MatchPriority priority) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                priority.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'No ${priority.label} matches',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getEmptyMessage(priority),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
        ),
      );

  String _getEmptyMessage(MatchPriority priority) {
    switch (priority) {
      case MatchPriority.new_:
        return 'Keep swiping in Discover to find new connections!';
      case MatchPriority.priority:
        return 'Move promising matches here to focus your energy.';
      case MatchPriority.inWaiting:
        return 'Matches that need a bit more time go here.';
      case MatchPriority.onWayOut:
        return 'Connections fading? They\'ll appear here.';
      case MatchPriority.legacy:
        return ''; // Legacy tab hidden but case needed for exhaustive switch
    }
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 0.8) return VesparaColors.success;
    if (score >= 0.6) return VesparaColors.glow;
    if (score >= 0.4) return VesparaColors.warning;
    return VesparaColors.secondary;
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              autofocus: true,
              style: const TextStyle(color: VesparaColors.primary),
              decoration: InputDecoration(
                hintText: 'Search your roster...',
                hintStyle: const TextStyle(color: VesparaColors.secondary),
                prefixIcon: const Icon(Icons.search, color: VesparaColors.glow),
                filled: true,
                fillColor: VesparaColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,),
              ),
              onSubmitted: (query) {
                Navigator.pop(context);
                final matchState = ref.read(matchStateProvider);
                final results = matchState.matches
                    .where((m) =>
                        m.matchedUserName
                            ?.toLowerCase()
                            .contains(query.toLowerCase()) ??
                        false,)
                    .toList();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Found ${results.length} matches for "$query"'),
                    backgroundColor: VesparaColors.glow,),);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showPlanDateDialog(Match match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
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
                        borderRadius: BorderRadius.circular(2),),),),
            const SizedBox(height: 20),
            Text('Plan a Date with ${match.matchedUserName}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,),),
            const SizedBox(height: 20),
            ...[
              'Drinks Tonight',
              'Dinner This Week',
              'Weekend Adventure',
              'Something Special',
            ].map(
              (option) => ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: VesparaColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),),
                    child: const Icon(Icons.calendar_today,
                        color: VesparaColors.success, size: 20,),),
                title: Text(option,
                    style: const TextStyle(
                        color: VesparaColors.primary,
                        fontWeight: FontWeight.w500,),),
                trailing: const Icon(Icons.chevron_right,
                    color: VesparaColors.secondary,),
                onTap: () async {
                  Navigator.pop(context);
                  
                  // Calculate start time based on option
                  DateTime startTime;
                  switch (option) {
                    case 'Drinks Tonight':
                      startTime = DateTime.now().copyWith(hour: 19, minute: 0);
                      break;
                    case 'Dinner This Week':
                      startTime = DateTime.now().add(const Duration(days: 3)).copyWith(hour: 19, minute: 0);
                      break;
                    case 'Weekend Adventure':
                      // Find next Saturday
                      final today = DateTime.now();
                      final daysUntilSaturday = (DateTime.saturday - today.weekday) % 7;
                      startTime = today.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday)).copyWith(hour: 14, minute: 0);
                      break;
                    default:
                      startTime = DateTime.now().add(const Duration(days: 7)).copyWith(hour: 18, minute: 0);
                  }
                  
                  // Create the plan event
                  try {
                    final connection = EventConnection(
                      id: match.matchedUserId ?? match.id,
                      name: match.matchedUserName ?? 'Match',
                      avatarUrl: match.matchedUserAvatar,
                    );
                    
                    final event = PlanEvent(
                      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
                      userId: Supabase.instance.client.auth.currentUser?.id ?? '',
                      title: '$option with ${match.matchedUserName}',
                      startTime: startTime,
                      endTime: startTime.add(const Duration(hours: 2)),
                      connections: [connection],
                      certainty: EventCertainty.exploring,
                      createdAt: DateTime.now(),
                    );
                    
                    await ref.read(planProvider.notifier).createEvent(event);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          '"$option" scheduled with ${match.matchedUserName}!',),
                        backgroundColor: VesparaColors.success,
                        action: SnackBarAction(
                          label: 'View',
                          textColor: VesparaColors.background,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PlannerScreen(
                                  preselectedMatchId: match.matchedUserId,
                                  preselectedMatchName: match.matchedUserName,
                                ),
                              ),
                            );
                          },
                        ),
                      ),);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to schedule: $e'),
                        backgroundColor: VesparaColors.error,
                      ),);
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPlayTagDialog(Match match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
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
                        borderRadius: BorderRadius.circular(2),),),),
            const SizedBox(height: 20),
            Text('Play TAG with ${match.matchedUserName} 🎮',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,),),
            const SizedBox(height: 12),
            const Text('Choose a game to play together:',
                style: TextStyle(color: VesparaColors.secondary),),
            const SizedBox(height: 16),
            ...[
              '🧊 Icebreakers',
              '🃏 Truth or Dare',
              '🔥 Spicy Edition',
              '💜 Fantasy Exploration',
            ].map(
              (game) => ListTile(
                title: Text(game,
                    style: const TextStyle(
                        color: VesparaColors.primary,
                        fontWeight: FontWeight.w500,),),
                trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: VesparaColors.tagsYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),),
                    child: const Text('Play',
                        style: TextStyle(
                            color: VesparaColors.tagsYellow,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,),),),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to TAGs screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TagScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _moveToShredder(Match match) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.delete_sweep, color: VesparaColors.error),
          SizedBox(width: 8),
          Text('Move to Shredder?',
              style: TextStyle(color: VesparaColors.primary),),
        ],),
        content: Text(
            '${match.matchedUserName} will be flagged for review in The Shredder. You can always bring them back.',
            style: const TextStyle(color: VesparaColors.secondary),),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: VesparaColors.secondary),),),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _updateMatchPriority(match, MatchPriority.onWayOut);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('${match.matchedUserName} moved to Head to Shred'),
                  backgroundColor: VesparaColors.error,),);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: VesparaColors.error),
            child: const Text('Move', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatMatchDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
    return '${diff.inDays ~/ 30} months ago';
  }

  /// Show sheet to invite a match to an event
  void _showInviteToEventSheet(Match match) {
    final eventsState = ref.read(eventsProvider);
    // Filter for upcoming events (not in the past)
    final events = eventsState.allEvents.where((e) => !e.isPast).toList();

    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No upcoming events to invite to'),
          backgroundColor: VesparaColors.surface,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  color: VesparaColors.glow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Invite ${match.matchedUserName ?? "them"} to...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...events.take(5).map(
              (event) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: VesparaColors.glow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event, color: VesparaColors.glow),
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(
                    color: VesparaColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${event.dateLabel} • ${event.venueName ?? "TBD"}',
                  style: const TextStyle(
                    color: VesparaColors.secondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invited ${match.matchedUserName} to ${event.title}'),
                      backgroundColor: VesparaColors.success,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _openPhotoRankingForMatch(Match match) async {
    // Fetch the user's profile to get all their photos
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('photos')
          .eq('id', match.matchedUserId)
          .maybeSingle();

      final photoUrls = response != null 
          ? List<String>.from(response['photos'] ?? [])
          : <String>[];

      // Fall back to avatar if no photos array
      if (photoUrls.isEmpty && match.matchedUserAvatar != null) {
        photoUrls.add(match.matchedUserAvatar!);
      }

      if (photoUrls.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This user has no photos to rank'),
              backgroundColor: VesparaColors.surface,
            ),
          );
        }
        return;
      }

      // Convert to ProfilePhoto objects
      final photos = photoUrls.asMap().entries.map((entry) => ProfilePhoto.fromUrl(
        id: '${match.matchedUserId}_photo_${entry.key}',
        userId: match.matchedUserId,
        photoUrl: entry.value,
        position: entry.key + 1,
        isPrimary: entry.key == 0,
      )).toList();

      if (mounted) {
        PhotoRankingSheet.show(
          context,
          userId: match.matchedUserId,
          userName: match.matchedUserName ?? 'This person',
          photos: photos,
        );
      }
    } catch (e) {
      debugPrint('Error fetching photos for ranking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load photos'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MATCH PROFILE SHEET - Full profile popup with AI insights
// ════════════════════════════════════════════════════════════════════════════

class _MatchProfileSheet extends ConsumerStatefulWidget {
  const _MatchProfileSheet({
    required this.match,
    required this.onMessage,
    required this.onAskOut,
    required this.onRankPhotos,
    required this.onShredder,
    required this.onUpdateNotes,
  });

  final Match match;
  final VoidCallback onMessage;
  final VoidCallback onAskOut;
  final VoidCallback onRankPhotos;
  final VoidCallback onShredder;
  final void Function(String notes) onUpdateNotes;

  @override
  ConsumerState<_MatchProfileSheet> createState() => _MatchProfileSheetState();
}

class _MatchProfileSheetState extends ConsumerState<_MatchProfileSheet> {
  UserProfile? _profile;
  MatchInsight? _insight;
  bool _isLoadingProfile = true;
  bool _isLoadingInsight = true;
  late TextEditingController _notesController;
  bool _notesSaved = true;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.match.notes ?? '');
    _loadProfileAndInsight();
  }

  @override
  void dispose() {
    // Save notes on close if changed
    if (!_notesSaved && _notesController.text != widget.match.notes) {
      widget.onUpdateNotes(_notesController.text);
    }
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndInsight() async {
    // Load full profile from Supabase
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.match.matchedUserId)
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

    // Load AI insight
    try {
      final insight = await MatchInsightsService.instance
          .getDetailedInsight(widget.match.matchedUserId);
      if (mounted) {
        setState(() {
          _insight = insight;
          _isLoadingInsight = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading insight: $e');
      setState(() => _isLoadingInsight = false);
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
              // Handle
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

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo carousel
                      _buildPhotoCarousel(),
                      const SizedBox(height: 20),

                      // Name, age, headline
                      _buildProfileHeader(),
                      const SizedBox(height: 20),

                      // Quick Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 24),

                      // AI Compatibility Insight
                      _buildAIInsightSection(),
                      const SizedBox(height: 24),

                      // About section (bio)
                      if (_profile?.bio != null && _profile!.bio!.isNotEmpty)
                        _buildAboutSection(),

                      // Shared interests
                      if (widget.match.sharedInterests.isNotEmpty ||
                          _insight?.sharedInterests.isNotEmpty == true)
                        _buildSharedInterestsSection(),

                      // Vibe tags
                      if (_profile?.vibeTags.isNotEmpty == true)
                        _buildTagsSection('Vibe', _profile!.vibeTags, VesparaColors.glow),

                      // Interest tags  
                      if (_profile?.interestTags.isNotEmpty == true)
                        _buildTagsSection('Interests', _profile!.interestTags, VesparaColors.success),

                      // Notes section
                      _buildNotesSection(),
                      const SizedBox(height: 24),

                      // Danger zone
                      _buildDangerZone(),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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
    final avatarUrl = widget.match.matchedUserAvatar;

    // Use profile photos or fall back to avatar
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
            widget.match.matchedUserName?[0].toUpperCase() ?? '?',
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
        // Photo
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 350,
            width: double.infinity,
            child: PageView.builder(
              itemCount: displayPhotos.length,
              onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
              itemBuilder: (context, index) => Image.network(
                displayPhotos[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: VesparaColors.background,
                  child: const Icon(Icons.broken_image, size: 48, color: VesparaColors.secondary),
                ),
              ),
            ),
          ),
        ),

        // Dots indicator
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
    final name = _profile?.displayName ?? widget.match.matchedUserName ?? 'Unknown';
    final age = _profile?.age ?? widget.match.matchedUserAge;
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
                    const Icon(Icons.verified, color: VesparaColors.glow, size: 24),
                  ],
                ],
              ),
            ),
            // Compatibility badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: VesparaColors.glow, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.match.compatibilityPercent}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.glow,
                    ),
                  ),
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
              const Icon(Icons.location_on, size: 14, color: VesparaColors.secondary),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 13,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.schedule, size: 14, color: VesparaColors.secondary),
              const SizedBox(width: 4),
              Text(
                'Matched ${_formatMatchDate(widget.match.matchedAt)}',
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
              onPressed: widget.onAskOut,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Ask Out'),
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
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: widget.onRankPhotos,
              icon: const Icon(Icons.photo_library, color: Colors.amber),
              tooltip: 'Rank Photos',
            ),
          ),
        ],
      );

  Widget _buildAIInsightSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VesparaColors.glow.withOpacity(0.15),
            VesparaColors.glow.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: VesparaColors.glow, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Vespara Insight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,
                  ),
                ),
              ),
              if (_insight != null)
                Text(
                  _insight!.compatibilityEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingInsight)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: VesparaColors.glow),
                ),
                SizedBox(width: 12),
                Text(
                  'Analyzing compatibility...',
                  style: TextStyle(fontSize: 14, color: VesparaColors.secondary),
                ),
              ],
            )
          else if (_insight != null && _insight!.hasAIInsight)
            Text(
              _insight!.aiInsight!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: VesparaColors.primary,
              ),
            )
          else if (_insight != null && _insight!.quickInsight.isNotEmpty)
            Text(
              _insight!.quickInsight,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: VesparaColors.primary,
              ),
            )
          else
            Text(
              'Keep chatting to unlock deeper insights about your compatibility with ${widget.match.matchedUserName}!',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: VesparaColors.secondary.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          
          // Conversation starters
          if (_insight?.conversationTopics.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            const Text(
              'Try talking about:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _insight!.conversationTopics.take(3).map((topic) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: VesparaColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  topic,
                  style: const TextStyle(fontSize: 12, color: VesparaColors.primary),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

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

  Widget _buildSharedInterestsSection() {
    final interests = _insight?.sharedInterests.isNotEmpty == true
        ? _insight!.sharedInterests
        : widget.match.sharedInterests;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: VesparaColors.glow),
              const SizedBox(width: 8),
              const Text(
                'You both enjoy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
              ),
              child: Text(
                interest,
                style: const TextStyle(
                  fontSize: 13,
                  color: VesparaColors.glow,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(String title, List<String> tags, Color color) => Padding(
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
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      );

  Widget _buildNotesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Personal Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const Spacer(),
              if (!_notesSaved)
                TextButton.icon(
                  onPressed: () {
                    widget.onUpdateNotes(_notesController.text);
                    setState(() => _notesSaved = true);
                  },
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(
                    foregroundColor: VesparaColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VesparaColors.glow.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              onChanged: (_) => setState(() => _notesSaved = false),
              decoration: InputDecoration(
                hintText: 'Add personal notes about ${widget.match.matchedUserName}...',
                hintStyle: TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: VesparaColors.primary, height: 1.5),
            ),
          ),
        ],
      );

  Widget _buildDangerZone() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onShredder,
            icon: const Icon(Icons.delete_sweep, color: VesparaColors.error),
            label: const Text(
              'Send to Shredder',
              style: TextStyle(color: VesparaColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: VesparaColors.error.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );

  String _formatMatchDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
    return '${diff.inDays ~/ 30} months ago';
  }
}
