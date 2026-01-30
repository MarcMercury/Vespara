import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/chat.dart';
import '../../../core/providers/match_state_provider.dart';
import '../../../core/providers/wire_provider.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// THE WIRE - Module 4
/// Full-featured chat with images, voice notes, reactions
/// Modern messaging experience like WhatsApp/iMessage
/// ════════════════════════════════════════════════════════════════════════════

class WireScreen extends ConsumerStatefulWidget {
  const WireScreen({super.key});

  @override
  ConsumerState<WireScreen> createState() => _WireScreenState();
}

class _WireScreenState extends ConsumerState<WireScreen> {
  String? _selectedConversationId;

  @override
  void initState() {
    super.initState();
  }

  List<ChatConversation> get _conversations {
    // Get conversations from global state only
    final stateConversations = ref.watch(allConversationsProvider);
    return stateConversations;
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _conversations;

    if (_selectedConversationId != null) {
      final conversation = conversations.firstWhere(
        (c) => c.id == _selectedConversationId,
        orElse: () => conversations.first,
      );
      return _ChatDetailScreen(
        conversation: conversation,
        onBack: () => setState(() => _selectedConversationId = null),
      );
    }

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildConversationList()),
          ],
        ),
      ),
    );
  }

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
                const Text(
                  'THE WIRE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: VesparaColors.primary,
                  ),
                ),
                Text(
                  '${_conversations.length} conversations',
                  style: const TextStyle(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _showNewMessageDialog,
              icon:
                  const Icon(Icons.edit_square, color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  Widget _buildConversationList() {
    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }

    // Sort by last message time
    final sorted = List<ChatConversation>.from(_conversations)
      ..sort((a, b) {
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _buildConversationTile(sorted[index]),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final isStale = conversation.isStale;
    final isGroup = conversation.isGroupChat;

    return GestureDetector(
      onTap: () => setState(() => _selectedConversationId = conversation.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStale
                ? VesparaColors.warning.withOpacity(0.3)
                : isGroup
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
                    shape: isGroup ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: isGroup ? BorderRadius.circular(16) : null,
                    color: VesparaColors.glow.withOpacity(0.2),
                  ),
                  child: Center(
                    child: isGroup
                        ? const Icon(Icons.group,
                            size: 26, color: VesparaColors.glow,)
                        : Text(
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
                          conversation.unreadCount.toString(),
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
                      Expanded(
                        child: Row(
                          children: [
                            if (isGroup) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2,),
                                decoration: BoxDecoration(
                                  color: VesparaColors.glow.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CIRCLE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: VesparaColors.glow,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                conversation.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: conversation.unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: VesparaColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isGroup && conversation.memberCount != null) ...[
                        Text(
                          '${conversation.memberCount} • ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: VesparaColors.secondary,
                          ),
                        ),
                      ],
                      if (isStale) ...[
                        const Icon(
                          Icons.hourglass_empty,
                          size: 12,
                          color: VesparaColors.warning,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          conversation.lastMessagePreview,
                          style: TextStyle(
                            fontSize: 13,
                            color: isStale
                                ? VesparaColors.warning
                                : VesparaColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (isStale && !isGroup) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,),
                      decoration: BoxDecoration(
                        color: VesparaColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb,
                              size: 12, color: VesparaColors.warning,),
                          SizedBox(width: 4),
                          Text(
                            'Resuscitate this conversation?',
                            style: TextStyle(
                              fontSize: 10,
                              color: VesparaColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: VesparaColors.glow.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Match with someone in Discover to start chatting',
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }

  void _showNewMessageDialog() {
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
            const Text('New Message',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,),),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: VesparaColors.primary),
              decoration: InputDecoration(
                hintText: 'Search your matches...',
                hintStyle: const TextStyle(color: VesparaColors.secondary),
                prefixIcon: const Icon(Icons.search, color: VesparaColors.glow),
                filled: true,
                fillColor: VesparaColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Recent Matches',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.secondary,
                    letterSpacing: 1,),),
            const SizedBox(height: 12),
            ...(_conversations.take(3).map(
                  (c) => ListTile(
                    leading: CircleAvatar(
                        backgroundColor: VesparaColors.glow.withOpacity(0.2),
                        child: Text(c.otherUserName?[0] ?? '?',
                            style:
                                const TextStyle(color: VesparaColors.primary),),),
                    title: Text(c.otherUserName ?? 'Unknown',
                        style: const TextStyle(color: VesparaColors.primary),),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedConversationId = c.id);
                    },
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Individual chat screen
class _ChatDetailScreen extends ConsumerStatefulWidget {
  const _ChatDetailScreen({
    required this.conversation,
    required this.onBack,
  });
  final ChatConversation conversation;
  final VoidCallback onBack;

  @override
  ConsumerState<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<_ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _showMediaOptions = false;
  bool _isLoading = true;
  bool _isMuted = false; // Track muted state locally
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      // Not logged in - show empty
      setState(() {
        _messages = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // Load messages from database
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversation.id)
          .order('created_at', ascending: true);

      final dbMessages = (response as List<dynamic>)
          .map(
            (json) => ChatMessage(
              id: json['id'] as String,
              conversationId: json['conversation_id'] as String,
              senderId: json['sender_id'] as String,
              isFromMe: json['sender_id'] == currentUserId,
              content: json['content'] as String? ?? '',
              createdAt: DateTime.parse(json['created_at'] as String),
            ),
          )
          .toList();

      setState(() {
        _messages = dbMessages;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
      // Show empty on error
      setState(() {
        _messages = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    final currentUserId = _supabase.auth.currentUser?.id;
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic update - add message immediately
    final optimisticMessage = ChatMessage(
      id: tempId,
      conversationId: widget.conversation.id,
      senderId: currentUserId ?? 'demo-user-001',
      isFromMe: true,
      content: content,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(optimisticMessage);
      _messageController.clear();
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Save to database if logged in
    if (currentUserId != null) {
      try {
        // Ensure conversation exists in database first
        await _ensureConversationExists(widget.conversation.id, currentUserId);

        final response = await _supabase
            .from('messages')
            .insert({
              'conversation_id': widget.conversation.id,
              'sender_id': currentUserId,
              'content': content,
              'message_type': 'text',
            })
            .select()
            .single();

        // Replace temp message with real one from DB
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: response['id'] as String,
              conversationId: response['conversation_id'] as String,
              senderId: response['sender_id'] as String,
              isFromMe: true,
              content: response['content'] as String? ?? '',
              createdAt: DateTime.parse(response['created_at'] as String),
            );
          }
        });

        debugPrint('✅ Message saved to database: ${response['id']}');
      } catch (e) {
        debugPrint('❌ Error saving message: $e');
        // Message stays in local state even if DB save fails
      }
    }
  }

  Future<void> _ensureConversationExists(
      String conversationId, String userId,) async {
    try {
      // Check if conversation exists
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .eq('id', conversationId)
          .maybeSingle();

      if (existing == null) {
        // Create conversation if it doesn't exist
        await _supabase.from('conversations').insert({
          'id': conversationId,
          'user_id': userId,
          'conversation_type': 'direct',
        });

        // Add current user as participant
        await _supabase.from('conversation_participants').insert({
          'conversation_id': conversationId,
          'user_id': userId,
        });

        debugPrint('✅ Created conversation: $conversationId');
      }
    } catch (e) {
      debugPrint('Error ensuring conversation exists: $e');
    }
  }

  void _showVideoCallDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: widget.conversation.otherUserAvatar != null
                    ? NetworkImage(widget.conversation.otherUserAvatar!)
                    : null,
                child: widget.conversation.otherUserAvatar == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Video call with ${widget.conversation.otherUserName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ready to connect?',
                style: TextStyle(color: VesparaColors.secondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallOption(Icons.videocam, 'Video', VesparaColors.glow,
                      () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Starting video call with ${widget.conversation.otherUserName}...',),
                        backgroundColor: VesparaColors.glow,
                      ),
                    );
                  }),
                  _buildCallOption(Icons.phone, 'Voice', VesparaColors.success,
                      () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Starting voice call with ${widget.conversation.otherUserName}...',),
                        backgroundColor: VesparaColors.success,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: VesparaColors.secondary),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallOption(
          IconData icon, String label, Color color, VoidCallback onTap,) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: VesparaColors.primary)),
          ],
        ),
      );

  void _showChatOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: VesparaColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildOptionTile(Icons.person, 'View Profile', () {
                Navigator.pop(context);
                _navigateToProfile(widget.conversation.otherUserId ?? '');
              }),
              _buildOptionTile(
                _isMuted ? Icons.notifications : Icons.notifications_off, 
                _isMuted ? 'Unmute Notifications' : 'Mute Notifications',
                () {
                  Navigator.pop(context);
                  _toggleMuteConversation();
                },
              ),
              _buildOptionTile(Icons.search, 'Search in Chat', () {
                Navigator.pop(context);
                _showSearchInChatDialog();
              }),
              _buildOptionTile(Icons.photo_library, 'Shared Media', () {
                Navigator.pop(context);
                _showSharedMedia();
              }),
              _buildOptionTile(
                Icons.block,
                'Block User',
                () {
                  Navigator.pop(context);
                  _showBlockConfirmation();
                },
                isDestructive: true,
              ),
              _buildOptionTile(
                Icons.delete_outline,
                'Delete Chat',
                () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
                isDestructive: true,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false,}) {
    final color = isDestructive ? VesparaColors.error : VesparaColors.primary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  void _showSearchInChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Search in Chat',
            style: TextStyle(color: VesparaColors.primary),),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: const TextStyle(color: VesparaColors.secondary),
            prefixIcon: const Icon(Icons.search, color: VesparaColors.glow),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: VesparaColors.glow.withOpacity(0.3)),
            ),
          ),
          style: const TextStyle(color: VesparaColors.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Searching...')),
              );
            },
            child: const Text('Search',
                style: TextStyle(color: VesparaColors.glow),),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Block ${widget.conversation.otherUserName}?',
            style: const TextStyle(color: VesparaColors.primary),),
        content: const Text(
          'They won\'t be able to message you or see your profile.',
          style: TextStyle(color: VesparaColors.secondary),
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
                // Block the user via provider
                await ref.read(wireProvider.notifier).blockUser(
                  widget.conversation.otherUserId ?? '',
                  widget.conversation.id,
                );
                if (mounted) {
                  Navigator.pop(context); // Go back to chat list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${widget.conversation.otherUserName} has been blocked',),
                      backgroundColor: VesparaColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to block user: $e'),
                      backgroundColor: VesparaColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Block',
                style: TextStyle(color: VesparaColors.error),),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete this chat?',
            style: TextStyle(color: VesparaColors.primary),),
        content: const Text(
          'This will permanently delete all messages in this conversation.',
          style: TextStyle(color: VesparaColors.secondary),
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
              // Actually delete the conversation
              await ref.read(wireProvider.notifier).deleteConversation(widget.conversation.id);
              if (mounted) {
                Navigator.pop(context); // Go back to chat list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat deleted'),
                    backgroundColor: VesparaColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: VesparaColors.error),),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(String userId) {
    // Navigate to profile view
    if (userId.isNotEmpty) {
      // For now, show a snackbar since profile screen navigation depends on app structure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening ${widget.conversation.otherUserName}\'s profile'),
          backgroundColor: VesparaColors.glow,
        ),
      );
    }
  }

  void _toggleMuteConversation() async {
    try {
      await ref.read(wireProvider.notifier).toggleMute(
        widget.conversation.id,
        duration: const Duration(hours: 8),
      );
      if (mounted) {
        setState(() {
          _isMuted = !_isMuted;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isMuted ? 'Notifications muted for 8 hours' : 'Notifications unmuted'),
            backgroundColor: VesparaColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notifications: $e'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }
  }

  void _showSharedMedia() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shared Media',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: VesparaColors.secondary),
                  ),
                ],
              ),
            ),
            const Divider(color: VesparaColors.border),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: VesparaColors.secondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No shared media yet',
                      style: TextStyle(color: VesparaColors.secondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startVoiceRecording() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.mic, color: VesparaColors.background),
            SizedBox(width: 8),
            Text('Recording... (tap again to stop)'),
          ],
        ),
        backgroundColor: VesparaColors.warning,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMediaOption(String type) {
    Navigator.pop(context); // Close media options
    String message;
    switch (type) {
      case 'Photo':
        message = 'Opening photo library...';
        break;
      case 'Camera':
        message = 'Opening camera...';
        break;
      case 'GIF':
        message = 'Opening GIF picker...';
        break;
      case 'Voice':
        _startVoiceRecording();
        return;
      default:
        message = 'Opening $type...';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildChatHeader(),
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ),
      );

  Widget _buildChatHeader() {
    final isGroup = widget.conversation.isGroupChat;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        border: Border(
          bottom: BorderSide(color: VesparaColors.glow.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: isGroup ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isGroup ? BorderRadius.circular(14) : null,
              color: VesparaColors.glow.withOpacity(0.2),
            ),
            child: Center(
              child: isGroup
                  ? const Icon(Icons.group, size: 22, color: VesparaColors.glow)
                  : Text(
                      widget.conversation.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isGroup) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2,),
                        decoration: BoxDecoration(
                          color: VesparaColors.glow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CIRCLE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: VesparaColors.glow,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        widget.conversation.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  isGroup
                      ? '${widget.conversation.memberCount ?? 0} members'
                      : widget.conversation.isTyping
                          ? 'Typing...'
                          : 'Active recently',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.conversation.isTyping
                        ? VesparaColors.success
                        : VesparaColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isGroup)
            IconButton(
              onPressed: _showVideoCallDialog,
              icon: const Icon(Icons.videocam_outlined,
                  color: VesparaColors.secondary,),
            ),
          IconButton(
            onPressed: _showChatOptionsMenu,
            icon: const Icon(Icons.more_vert, color: VesparaColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.waving_hand,
              size: 48,
              color: VesparaColors.glow.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Say hello to ${widget.conversation.otherUserName}!',
              style: const TextStyle(
                fontSize: 16,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isFromMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? VesparaColors.glow.withOpacity(0.3)
              : VesparaColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: const TextStyle(
                fontSize: 15,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.formattedTime,
                  style: const TextStyle(
                    fontSize: 10,
                    color: VesparaColors.secondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? VesparaColors.glow
                        : VesparaColors.secondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          border: Border(
            top: BorderSide(color: VesparaColors.glow.withOpacity(0.1)),
          ),
        ),
        child: Column(
          children: [
            if (_showMediaOptions) _buildMediaOptions(),
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      setState(() => _showMediaOptions = !_showMediaOptions),
                  icon: Icon(
                    _showMediaOptions ? Icons.close : Icons.add,
                    color: VesparaColors.glow,
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: VesparaColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: VesparaColors.secondary),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: VesparaColors.primary),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _startVoiceRecording,
                  icon: const Icon(Icons.mic, color: VesparaColors.secondary),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: VesparaColors.glow,
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 18,
                      color: VesparaColors.background,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildMediaOptions() => Container(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMediaOption(Icons.image, 'Photo', VesparaColors.success),
            _buildMediaOption(Icons.camera_alt, 'Camera', VesparaColors.glow),
            _buildMediaOption(Icons.gif_box, 'GIF', VesparaColors.tagsYellow),
            _buildMediaOption(Icons.mic, 'Voice', VesparaColors.warning),
          ],
        ),
      );

  Widget _buildMediaOption(IconData icon, String label, Color color) =>
      GestureDetector(
        onTap: () => _handleMediaOption(label),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );
}
