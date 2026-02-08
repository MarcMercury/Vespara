import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/domain/models/wire_models.dart';
import '../../../core/providers/wire_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../widgets/wire_message_bubble.dart';
import 'wire_group_info_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// WIRE CHAT SCREEN - WhatsApp-Style Conversation
/// ════════════════════════════════════════════════════════════════════════════

class WireChatScreen extends ConsumerStatefulWidget {
  const WireChatScreen({
    super.key,
    required this.conversation,
  });
  final WireConversation conversation;

  @override
  ConsumerState<WireChatScreen> createState() => _WireChatScreenState();
}

class _WireChatScreenState extends ConsumerState<WireChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  bool _isTyping = false;
  bool _showAttachmentMenu = false;
  WireMessage? _replyingTo;
  bool _isRecordingVoice = false;
  bool _isLoadingMore = false;

  /// Cached notifier ref so we can call it safely in dispose()
  late final WireNotifier _wireNotifier;

  @override
  void initState() {
    super.initState();
    _wireNotifier = ref.read(wireProvider.notifier);

    // Open conversation in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wireNotifier.openConversation(widget.conversation.id);
    });

    // Listen for text changes
    _messageController.addListener(_onTextChanged);

    // Listen for scroll to load more messages
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _wireNotifier.closeConversation();
    _wireNotifier.stopTyping(widget.conversation.id);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() => _isTyping = hasText);

      if (hasText) {
        ref.read(wireProvider.notifier).startTyping(widget.conversation.id);
      } else {
        ref.read(wireProvider.notifier).stopTyping(widget.conversation.id);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;

    final messages =
        ref.read(wireProvider).messagesByConversation[widget.conversation.id];
    if (messages == null || messages.isEmpty) return;

    setState(() => _isLoadingMore = true);

    await ref.read(wireProvider.notifier).loadMessages(
          widget.conversation.id,
          before: messages.first.createdAt.toIso8601String(),
        );

    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final wireState = ref.watch(wireProvider);
    final messages =
        wireState.messagesByConversation[widget.conversation.id] ?? [];
    final participants =
        wireState.participantsByConversation[widget.conversation.id] ?? [];
    final typingUsers =
        wireState.typingByConversation[widget.conversation.id] ?? [];

    return Scaffold(
      backgroundColor: VesparaColors.background,
      appBar: _buildAppBar(context, participants, typingUsers),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(context)
                : _buildMessagesList(context, messages),
          ),

          // Reply preview
          if (_replyingTo != null) _buildReplyPreview(context),

          // Attachment menu
          if (_showAttachmentMenu) _buildAttachmentMenu(context),

          // Input area
          _buildInputArea(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    List<ConversationParticipant> participants,
    List<TypingUser> typingUsers,
  ) =>
      AppBar(
        backgroundColor: VesparaColors.surface,
        elevation: 0,
        leadingWidth: 40,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: widget.conversation.isGroup
              ? () => _openGroupInfo(context)
              : null,
          child: Row(
            children: [
              // Avatar
              _buildHeaderAvatar(),
              const SizedBox(width: 12),

              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conversation.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (typingUsers.isNotEmpty)
                      Text(
                        _getTypingText(typingUsers),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: VesparaColors.glow,
                              fontStyle: FontStyle.italic,
                            ),
                      )
                    else if (widget.conversation.isGroup)
                      Text(
                        '${participants.length} participants',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: VesparaColors.secondary,
                            ),
                      )
                    else
                      Text(
                        'tap for info',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: VesparaColors.secondary,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Video call
            },
            icon: const Icon(Icons.videocam, color: VesparaColors.primary),
          ),
          IconButton(
            onPressed: () {
              // TODO: Voice call
            },
            icon: const Icon(Icons.call, color: VesparaColors.primary),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: VesparaColors.primary),
            color: VesparaColors.surface,
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              if (widget.conversation.isGroup)
                const PopupMenuItem(
                  value: 'group_info',
                  child: Text('Group info'),
                ),
              const PopupMenuItem(
                value: 'search',
                child: Text('Search'),
              ),
              const PopupMenuItem(
                value: 'media',
                child: Text('Media, links, and docs'),
              ),
              PopupMenuItem(
                value: 'mute',
                child: Text(widget.conversation.isMuted ? 'Unmute' : 'Mute'),
              ),
              const PopupMenuItem(
                value: 'wallpaper',
                child: Text('Wallpaper'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear chat'),
              ),
            ],
          ),
        ],
      );

  Widget _buildHeaderAvatar() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VesparaColors.background,
          border: Border.all(
            color: widget.conversation.isGroup
                ? VesparaColors.glow.withOpacity(0.5)
                : VesparaColors.border,
            width: 2,
          ),
        ),
        child: widget.conversation.avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  widget.conversation.avatarUrl!,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                widget.conversation.isGroup ? Icons.group : Icons.person,
                color: VesparaColors.secondary,
                size: 20,
              ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: VesparaColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.conversation.isGroup
                    ? Icons.group
                    : Icons.chat_bubble_outline,
                color: VesparaColors.secondary,
                size: 48,
              ),
            ),
            const SizedBox(height: VesparaSpacing.lg),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: VesparaSpacing.sm),
            Text(
              widget.conversation.isGroup
                  ? 'Be the first to say something!'
                  : 'Say hi to start the conversation',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );

  Widget _buildMessagesList(BuildContext context, List<WireMessage> messages) =>
      ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        reverse: true,
        itemCount: messages.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isLoadingMore && index == messages.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final reversedIndex = messages.length - 1 - index;
          final message = messages[reversedIndex];
          final previousMessage =
              reversedIndex > 0 ? messages[reversedIndex - 1] : null;

          // Check if we need a date separator
          final showDateSeparator = previousMessage == null ||
              !_isSameDay(message.createdAt, previousMessage.createdAt);

          return Column(
            children: [
              if (showDateSeparator)
                _buildDateSeparator(context, message.createdAt),
              WireMessageBubble(
                message: message,
                isGroup: widget.conversation.isGroup,
                showSenderName: widget.conversation.isGroup &&
                    (previousMessage == null ||
                        previousMessage.senderId != message.senderId),
                onReply: () => _setReplyingTo(message),
                onReact: (emoji) => _addReaction(message, emoji),
                onDelete: () => _deleteMessage(message),
                onForward: () => _forwardMessage(message),
                onStar: () => _starMessage(message),
                onCopy: () => _copyMessage(message),
              ),
            ],
          );
        },
      );

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
    String text;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      text = 'Today';
    } else if (diff.inDays == 1) {
      text = 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      text = days[date.weekday - 1];
    } else {
      text = '${date.month}/${date.day}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: VesparaColors.secondary,
            ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          border: Border(
            top: BorderSide(color: VesparaColors.border),
            left: BorderSide(color: VesparaColors.glow, width: 4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Replying to ${_replyingTo!.senderName ?? 'message'}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: VesparaColors.glow,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _replyingTo!.previewText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: VesparaColors.secondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _replyingTo = null),
              icon: const Icon(Icons.close, size: 20),
              color: VesparaColors.secondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      );

  Widget _buildAttachmentMenu(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          border: Border(top: BorderSide(color: VesparaColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentOption(
              icon: Icons.photo_library,
              label: 'Gallery',
              color: VesparaColors.tagsPurple,
              onTap: () => _pickMedia(ImageSource.gallery),
            ),
            _buildAttachmentOption(
              icon: Icons.camera_alt,
              label: 'Camera',
              color: VesparaColors.tagsRed,
              onTap: () => _pickMedia(ImageSource.camera),
            ),
            _buildAttachmentOption(
              icon: Icons.insert_drive_file,
              label: 'Document',
              color: VesparaColors.tagsPurple,
              onTap: _pickDocument,
            ),
            _buildAttachmentOption(
              icon: Icons.location_on,
              label: 'Location',
              color: VesparaColors.success,
              onTap: _shareLocation,
            ),
            _buildAttachmentOption(
              icon: Icons.person,
              label: 'Contact',
              color: VesparaColors.tagsBlue,
              onTap: _shareContact,
            ),
            _buildAttachmentOption(
              icon: Icons.poll,
              label: 'Poll',
              color: VesparaColors.tagsYellow,
              onTap: _createPoll,
            ),
          ],
        ),
      );

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: () {
          VesparaHaptics.lightTap();
          setState(() => _showAttachmentMenu = false);
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
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

  Widget _buildInputArea(BuildContext context) => Container(
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          border: Border(top: BorderSide(color: VesparaColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Emoji/attachment button
            IconButton(
              onPressed: () {
                VesparaHaptics.lightTap();
                setState(() => _showAttachmentMenu = !_showAttachmentMenu);
              },
              icon: Icon(
                _showAttachmentMenu ? Icons.close : Icons.add,
                color: VesparaColors.secondary,
              ),
            ),

            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: VesparaColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Emoji button
                    IconButton(
                      onPressed: () {
                        // TODO: Show emoji picker
                      },
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: VesparaColors.secondary,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),

                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(color: VesparaColors.primary),
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: VesparaColors.secondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),

                    // Camera button
                    IconButton(
                      onPressed: () => _pickMedia(ImageSource.camera),
                      icon: const Icon(
                        Icons.camera_alt,
                        color: VesparaColors.secondary,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send/Voice button
            if (_isTyping) _buildSendButton() else _buildVoiceButton(),
          ],
        ),
      );

  Widget _buildSendButton() => GestureDetector(
        onTap: _sendTextMessage,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: VesparaColors.glow,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.send,
            color: VesparaColors.background,
            size: 22,
          ),
        ),
      );

  Widget _buildVoiceButton() => GestureDetector(
        onLongPressStart: (_) {
          VesparaHaptics.heavyTap();
          setState(() => _isRecordingVoice = true);
          // TODO: Start recording
        },
        onLongPressEnd: (_) {
          setState(() => _isRecordingVoice = false);
          // TODO: Stop recording and send
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                _isRecordingVoice ? VesparaColors.tagsRed : VesparaColors.glow,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mic,
            color: VesparaColors.background,
            size: 22,
          ),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  void _handleMenuAction(String action) {
    switch (action) {
      case 'group_info':
        _openGroupInfo(context);
        break;
      case 'search':
        // TODO: Implement search in chat
        break;
      case 'media':
        // TODO: Show media gallery
        break;
      case 'mute':
        ref.read(wireProvider.notifier).toggleMute(widget.conversation.id);
        break;
      case 'wallpaper':
        // TODO: Wallpaper settings
        break;
      case 'clear':
        _confirmClearChat();
        break;
    }
  }

  void _openGroupInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WireGroupInfoScreen(conversationId: widget.conversation.id),
      ),
    );
  }

  Future<void> _sendTextMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    VesparaHaptics.lightTap();
    _messageController.clear();

    await ref.read(wireProvider.notifier).sendMessage(
          conversationId: widget.conversation.id,
          content: content,
          replyToId: _replyingTo?.id,
        );

    setState(() => _replyingTo = null);

    // Scroll to bottom
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);

    if (file != null) {
      final bytes = await file.readAsBytes();
      final filename = file.name;
      await ref.read(wireProvider.notifier).sendMediaMessage(
            conversationId: widget.conversation.id,
            fileBytes: bytes,
            filename: filename,
            type: MessageType.image,
            replyToId: _replyingTo?.id,
          );

      setState(() => _replyingTo = null);
    }
  }

  Future<void> _pickDocument() async {
    // Document picking requires native platform support
    // On web, this feature is not available yet
    if (kIsWeb) return;
    
    // On mobile/desktop, would use file_picker but it has web compatibility issues
    // TODO: Implement with platform-specific code when needed
  }

  void _shareLocation() {
    // TODO: Implement location sharing
  }

  void _shareContact() {
    // TODO: Implement contact sharing
  }

  void _createPoll() {
    // TODO: Implement poll creation
  }

  void _setReplyingTo(WireMessage message) {
    VesparaHaptics.lightTap();
    setState(() => _replyingTo = message);
    _focusNode.requestFocus();
  }

  void _addReaction(WireMessage message, String emoji) {
    ref.read(wireProvider.notifier).addReaction(
          messageId: message.id,
          conversationId: widget.conversation.id,
          emoji: emoji,
        );
  }

  Future<void> _deleteMessage(WireMessage message) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: const Text('Delete message?'),
        content: const Text('Choose how to delete this message'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'me'),
            child: const Text('Delete for me'),
          ),
          if (message.senderId == ref.read(wireProvider.notifier).currentUserId)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'everyone'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.tagsRed,
              ),
              child: const Text('Delete for everyone'),
            ),
        ],
      ),
    );

    if (result != null) {
      ref.read(wireProvider.notifier).deleteMessage(
            messageId: message.id,
            conversationId: widget.conversation.id,
            forEveryone: result == 'everyone',
          );
    }
  }

  void _forwardMessage(WireMessage message) {
    // TODO: Show conversation picker for forwarding
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forward coming soon')),
    );
  }

  void _starMessage(WireMessage message) {
    ref.read(wireProvider.notifier).toggleStarMessage(
          message.id,
          widget.conversation.id,
        );
  }

  void _copyMessage(WireMessage message) {
    if (message.content != null) {
      Clipboard.setData(ClipboardData(text: message.content!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message copied'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: const Text('Clear chat?'),
        content: const Text('All messages will be deleted from your view.'),
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Clear chat messages
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String _getTypingText(List<TypingUser> users) {
    if (users.length == 1) {
      return '${users.first.name} is typing...';
    } else if (users.length == 2) {
      return '${users[0].name} and ${users[1].name} are typing...';
    } else {
      return '${users.length} people are typing...';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
