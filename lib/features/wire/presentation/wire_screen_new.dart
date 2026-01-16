import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/data/vespara_mock_data.dart';
import '../../../core/domain/models/chat.dart';

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
  late List<ChatConversation> _conversations;
  String? _selectedConversationId;

  @override
  void initState() {
    super.initState();
    _conversations = MockDataProvider.conversations;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedConversationId != null) {
      final conversation = _conversations.firstWhere(
        (c) => c.id == _selectedConversationId,
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

  Widget _buildHeader() {
    return Padding(
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
              Text(
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
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_square, color: VesparaColors.secondary),
          ),
        ],
      ),
    );
  }

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
      itemBuilder: (context, index) {
        return _buildConversationTile(sorted[index]);
      },
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final isStale = conversation.isStale;
    
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
                  child: Center(
                    child: Text(
                      conversation.otherUserName?[0].toUpperCase() ?? '?',
                      style: TextStyle(
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.glow,
                      ),
                      child: Center(
                        child: Text(
                          conversation.unreadCount.toString(),
                          style: TextStyle(
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
                      Text(
                        conversation.otherUserName ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: conversation.unreadCount > 0 
                              ? FontWeight.w700 
                              : FontWeight.w500,
                          color: VesparaColors.primary,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isStale) ...[
                        Icon(
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
                  if (isStale) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VesparaColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb, size: 12, color: VesparaColors.warning),
                          const SizedBox(width: 4),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: VesparaColors.glow.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Match with someone in Discover to start chatting',
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }
}

/// Individual chat screen
class _ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;
  final VoidCallback onBack;
  
  const _ChatDetailScreen({
    required this.conversation,
    required this.onBack,
  });

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> _messages;
  bool _showMediaOptions = false;

  @override
  void initState() {
    super.initState();
    _messages = MockDataProvider.getMessagesForConversation(widget.conversation.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        id: 'msg-${_messages.length + 1}',
        conversationId: widget.conversation.id,
        senderId: 'demo-user-001',
        isFromMe: true,
        content: _messageController.text.trim(),
        createdAt: DateTime.now(),
      ));
      _messageController.clear();
    });
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  }

  Widget _buildChatHeader() {
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
              shape: BoxShape.circle,
              color: VesparaColors.glow.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                widget.conversation.otherUserName?[0].toUpperCase() ?? '?',
                style: TextStyle(
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
                Text(
                  widget.conversation.otherUserName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,
                  ),
                ),
                Text(
                  widget.conversation.isTyping ? 'Typing...' : 'Active recently',
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam_outlined, color: VesparaColors.secondary),
          ),
          IconButton(
            onPressed: () {},
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
              style: TextStyle(
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
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
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
              style: TextStyle(
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
                  style: TextStyle(
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

  Widget _buildInputBar() {
    return Container(
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
                onPressed: () => setState(() => _showMediaOptions = !_showMediaOptions),
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
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: VesparaColors.secondary),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: VesparaColors.primary),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.mic, color: VesparaColors.secondary),
              ),
              IconButton(
                onPressed: _sendMessage,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VesparaColors.glow,
                  ),
                  child: Icon(
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
  }

  Widget _buildMediaOptions() {
    return Container(
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
  }

  Widget _buildMediaOption(IconData icon, String label, Color color) {
    return Column(
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
          style: TextStyle(
            fontSize: 11,
            color: VesparaColors.secondary,
          ),
        ),
      ],
    );
  }
}
