import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/wire_models.dart';
import '../../../core/providers/wire_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import 'wire_chat_screen.dart';
import 'wire_create_group_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// WIRE HOME SCREEN - WhatsApp-Style Messaging Hub
/// ════════════════════════════════════════════════════════════════════════════

class WireHomeScreen extends ConsumerStatefulWidget {
  const WireHomeScreen({super.key});

  @override
  ConsumerState<WireHomeScreen> createState() => _WireHomeScreenState();
}

class _WireHomeScreenState extends ConsumerState<WireHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wireState = ref.watch(wireProvider);

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, wireState),
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllChatsTab(context, wireState),
                  _buildGroupsTab(context, wireState),
                  _buildArchivedTab(context, wireState),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context, WireState wireState) => Container(
        padding: const EdgeInsets.all(VesparaSpacing.md),
        child: Column(
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE WIRE',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (wireState.totalUnreadCount > 0)
                        Text(
                          '${wireState.totalUnreadCount} unread messages',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: VesparaColors.glow,
                                  ),
                        ),
                    ],
                  ),
                ),
                // Search toggle
                IconButton(
                  onPressed: () {
                    setState(() => _isSearching = !_isSearching);
                    if (!_isSearching) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  },
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: VesparaColors.primary,
                  ),
                ),
                // More options
                PopupMenuButton<String>(
                  icon:
                      const Icon(Icons.more_vert, color: VesparaColors.primary),
                  color: VesparaColors.surface,
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'new_group',
                      child: Row(
                        children: [
                          Icon(Icons.group_add, size: 20),
                          SizedBox(width: 12),
                          Text('New Group'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'starred',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 20),
                          SizedBox(width: 12),
                          Text('Starred Messages'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 20),
                          SizedBox(width: 12),
                          Text('Settings'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Search bar
            if (_isSearching) ...[
              const SizedBox(height: VesparaSpacing.sm),
              TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: VesparaColors.primary),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: const TextStyle(color: VesparaColors.secondary),
                  prefixIcon:
                      const Icon(Icons.search, color: VesparaColors.secondary),
                  filled: true,
                  fillColor: VesparaColors.surface,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(VesparaBorderRadius.button),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              ),
            ],
          ],
        ),
      );

  Widget _buildTabBar(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: VesparaSpacing.md),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: VesparaColors.glow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: VesparaColors.primary,
          unselectedLabelColor: VesparaColors.secondary,
          labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1,
              ),
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'GROUPS'),
            Tab(text: 'ARCHIVED'),
          ],
        ),
      );

  Widget _buildAllChatsTab(BuildContext context, WireState wireState) {
    final conversations =
        wireState.activeConversations.where(_matchesSearch).toList();

    if (wireState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversations.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.chat_bubble_outline,
        title: 'No conversations yet',
        subtitle: 'Start chatting with your connections',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(wireProvider.notifier).loadConversations(),
      color: VesparaColors.glow,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: VesparaSpacing.sm),
        itemCount: conversations.length,
        itemBuilder: (context, index) =>
            _buildConversationTile(context, conversations[index]),
      ),
    );
  }

  Widget _buildGroupsTab(BuildContext context, WireState wireState) {
    final groups = wireState.groupConversations.where(_matchesSearch).toList();

    if (groups.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.group,
        title: 'No groups yet',
        subtitle: 'Create a group to chat with multiple connections',
        actionLabel: 'Create Group',
        onAction: () => _navigateToCreateGroup(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: VesparaSpacing.sm),
      itemCount: groups.length,
      itemBuilder: (context, index) =>
          _buildConversationTile(context, groups[index]),
    );
  }

  Widget _buildArchivedTab(BuildContext context, WireState wireState) {
    final archived = wireState.archivedConversations;

    if (archived.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.archive_outlined,
        title: 'No archived chats',
        subtitle: 'Archived chats will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: VesparaSpacing.sm),
      itemCount: archived.length,
      itemBuilder: (context, index) =>
          _buildConversationTile(context, archived[index], isArchived: true),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    WireConversation conversation, {
    bool isArchived = false,
  }) =>
      Dismissible(
        key: Key(conversation.id),
        background: _buildSwipeBackground(
          color: VesparaColors.success,
          icon: Icons.archive,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeBackground(
          color: VesparaColors.tagsYellow,
          icon: Icons.push_pin,
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Archive/Unarchive
            if (isArchived) {
              await ref
                  .read(wireProvider.notifier)
                  .unarchiveConversation(conversation.id);
            } else {
              await ref
                  .read(wireProvider.notifier)
                  .archiveConversation(conversation.id);
            }
            VesparaHaptics.mediumTap();
            return false; // Don't actually dismiss
          } else {
            // Pin/Unpin
            await ref.read(wireProvider.notifier).togglePin(conversation.id);
            VesparaHaptics.lightTap();
            return false;
          }
        },
        child: GestureDetector(
          onTap: () => _openConversation(context, conversation),
          onLongPress: () => _showConversationOptions(context, conversation),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VesparaSpacing.md,
              vertical: VesparaSpacing.sm,
            ),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(conversation),
                const SizedBox(width: VesparaSpacing.md),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (conversation.isPinned) ...[
                                  const Icon(
                                    Icons.push_pin,
                                    size: 14,
                                    color: VesparaColors.glow,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    conversation.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight:
                                              conversation.unreadCount > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTime(conversation.lastMessageAt),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: conversation.unreadCount > 0
                                      ? VesparaColors.glow
                                      : VesparaColors.secondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Last message and unread count
                      Row(
                        children: [
                          // Message type icon
                          if (conversation.lastMessageType != null &&
                              conversation.lastMessageType != MessageType.text)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                _getMessageTypeIcon(
                                    conversation.lastMessageType!),
                                size: 16,
                                color: VesparaColors.secondary,
                              ),
                            ),

                          // Last message preview
                          Expanded(
                            child: Row(
                              children: [
                                // Show sender name in groups
                                if (conversation.isGroup &&
                                    conversation.lastMessageSenderName !=
                                        null) ...[
                                  Text(
                                    '${conversation.lastMessageSenderName}: ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: VesparaColors.glow,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    conversation.lastMessage ??
                                        'No messages yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: conversation.unreadCount > 0
                                              ? VesparaColors.primary
                                              : VesparaColors.secondary,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Muted icon
                          if (conversation.isMuted)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.volume_off,
                                size: 16,
                                color: VesparaColors.secondary,
                              ),
                            ),

                          // Unread badge
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: VesparaColors.glow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount > 99
                                    ? '99+'
                                    : conversation.unreadCount.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: VesparaColors.background,
                                      fontWeight: FontWeight.bold,
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
        ),
      );

  Widget _buildAvatar(WireConversation conversation) => Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VesparaColors.surface,
              border: Border.all(
                color: conversation.isGroup
                    ? VesparaColors.glow.withOpacity(0.5)
                    : VesparaColors.border,
                width: 2,
              ),
            ),
            child: conversation.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      conversation.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildAvatarPlaceholder(conversation),
                    ),
                  )
                : _buildAvatarPlaceholder(conversation),
          ),

          // Group indicator
          if (conversation.isGroup)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: VesparaColors.glow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VesparaColors.background,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    conversation.participantCount.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.background,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _buildAvatarPlaceholder(WireConversation conversation) => Center(
        child: Icon(
          conversation.isGroup ? Icons.group : Icons.person,
          color: VesparaColors.secondary,
          size: 28,
        ),
      );

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) =>
      Container(
        color: color.withOpacity(0.2),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(icon, color: color),
      );

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(VesparaSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: VesparaColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: VesparaColors.secondary, size: 48),
              ),
              const SizedBox(height: VesparaSpacing.lg),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: VesparaSpacing.sm),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: VesparaSpacing.lg),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildFAB(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // New group button
          FloatingActionButton.small(
            heroTag: 'group',
            backgroundColor: VesparaColors.surface,
            onPressed: () => _navigateToCreateGroup(context),
            child: const Icon(Icons.group_add, color: VesparaColors.glow),
          ),
          const SizedBox(height: 12),
          // New chat button
          FloatingActionButton(
            heroTag: 'chat',
            backgroundColor: VesparaColors.glow,
            onPressed: () => _showNewChatSheet(context),
            child: const Icon(Icons.chat, color: VesparaColors.background),
          ),
        ],
      );

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  bool _matchesSearch(WireConversation c) {
    if (_searchQuery.isEmpty) return true;
    return c.displayName.toLowerCase().contains(_searchQuery) ||
        (c.lastMessage?.toLowerCase().contains(_searchQuery) ?? false);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_group':
        _navigateToCreateGroup(context);
        break;
      case 'starred':
        // TODO: Navigate to starred messages
        break;
      case 'settings':
        // TODO: Navigate to settings
        break;
    }
  }

  void _openConversation(BuildContext context, WireConversation conversation) {
    VesparaHaptics.lightTap();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WireChatScreen(conversation: conversation),
      ),
    );
  }

  void _navigateToCreateGroup(BuildContext context) {
    VesparaHaptics.mediumTap();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WireCreateGroupScreen(),
      ),
    );
  }

  void _showNewChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(VesparaSpacing.lg),
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
            const SizedBox(height: VesparaSpacing.lg),
            Text(
              'New Chat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: VesparaSpacing.lg),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add, color: VesparaColors.glow),
              ),
              title: const Text('New Group'),
              subtitle: const Text('Create a group with multiple connections'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreateGroup(context);
              },
            ),
            const Divider(color: VesparaColors.border),
            const SizedBox(height: VesparaSpacing.sm),
            Text(
              'Select a connection to start chatting',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: VesparaSpacing.md),
            // TODO: Show list of connections from roster
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Connections will appear here',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConversationOptions(
      BuildContext context, WireConversation conversation) {
    VesparaHaptics.mediumTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(VesparaSpacing.lg),
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
            const SizedBox(height: VesparaSpacing.lg),

            // Conversation header
            Row(
              children: [
                _buildAvatar(conversation),
                const SizedBox(width: VesparaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (conversation.isGroup)
                        Text(
                          '${conversation.participantCount} participants',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: VesparaSpacing.lg),
            const Divider(color: VesparaColors.border),

            // Options
            ListTile(
              leading: Icon(
                conversation.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin,
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
              leading:
                  const Icon(Icons.archive, color: VesparaColors.secondary),
              title: const Text('Archive Chat'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(wireProvider.notifier)
                    .archiveConversation(conversation.id);
              },
            ),
            if (conversation.isGroup)
              ListTile(
                leading:
                    const Icon(Icons.exit_to_app, color: VesparaColors.tagsRed),
                title: const Text('Leave Group'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _confirmLeaveGroup(context);
                  if (confirmed) {
                    ref.read(wireProvider.notifier).leaveGroup(conversation.id);
                  }
                },
              ),

            const SizedBox(height: VesparaSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmLeaveGroup(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: VesparaColors.surface,
          title: const Text('Leave Group?'),
          content: const Text(
              'You will no longer receive messages from this group.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.tagsRed,
              ),
              child: const Text('Leave'),
            ),
          ],
        ),
      ) ??
      false;

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String _formatTime(DateTime? dateTime) {
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
      return '${dateTime.month}/${dateTime.day}/${dateTime.year.toString().substring(2)}';
    }
  }

  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.image:
        return Icons.photo;
      case MessageType.video:
        return Icons.videocam;
      case MessageType.voice:
        return Icons.mic;
      case MessageType.audio:
        return Icons.audiotrack;
      case MessageType.file:
        return Icons.attach_file;
      case MessageType.gif:
        return Icons.gif;
      case MessageType.location:
        return Icons.location_on;
      case MessageType.contact:
        return Icons.person;
      case MessageType.poll:
        return Icons.poll;
      default:
        return Icons.chat;
    }
  }
}
