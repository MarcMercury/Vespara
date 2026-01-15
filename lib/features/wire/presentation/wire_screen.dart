import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/domain/models/conversation.dart';
import '../../../core/services/openai_service.dart';

/// The Wire Screen - Messaging Hub
/// Conversations sorted by Momentum Score with Conversation Resuscitator
class WireScreen extends ConsumerStatefulWidget {
  const WireScreen({super.key});

  @override
  ConsumerState<WireScreen> createState() => _WireScreenState();
}

class _WireScreenState extends ConsumerState<WireScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _generatedResuscitator;
  bool _isGeneratingResuscitator = false;
  Conversation? _selectedConversation;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final staleConversations = ref.watch(staleConversationsProvider);
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, staleConversations.length),
            
            // Tab bar
            _buildTabBar(context),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All conversations
                  _buildConversationList(context, conversations),
                  
                  // Stale conversations (need resuscitation)
                  _buildStaleList(context, staleConversations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, int staleCount) {
    return Padding(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              VesparaHaptics.lightTap();
              context.go('/home');
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VesparaColors.border),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: VesparaColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE WIRE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Sorted by Momentum',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Stale indicator
          if (staleCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: VesparaColors.tagsYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: VesparaColors.tagsYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$staleCount',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: VesparaColors.tagsYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: VesparaColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar(BuildContext context) {
    return Container(
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
          Tab(text: 'ALL CHATS'),
          Tab(text: 'NEEDS ATTENTION'),
        ],
      ),
    );
  }
  
  Widget _buildConversationList(
    BuildContext context,
    AsyncValue<List<Conversation>> conversations,
  ) {
    return conversations.when(
      data: (list) {
        if (list.isEmpty) {
          return _buildEmptyState(context);
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(VesparaSpacing.md),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return _buildConversationTile(context, list[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
  
  Widget _buildStaleList(BuildContext context, List<Conversation> stale) {
    if (stale.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: VesparaColors.tagsGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: VesparaColors.tagsGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: VesparaSpacing.lg),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: VesparaSpacing.sm),
            Text(
              'No stale conversations need your attention',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      itemCount: stale.length,
      itemBuilder: (context, index) {
        return _buildStaleConversationTile(context, stale[index]);
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: VesparaColors.secondary,
              size: 48,
            ),
          ),
          const SizedBox(height: VesparaSpacing.lg),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: VesparaSpacing.sm),
          Text(
            'Start connecting with your matches',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildConversationTile(BuildContext context, Conversation convo) {
    return GestureDetector(
      onTap: () {
        VesparaHaptics.lightTap();
        _openConversation(context, convo);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: VesparaSpacing.sm),
        padding: const EdgeInsets.all(VesparaSpacing.md),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
          border: Border.all(color: VesparaColors.border),
        ),
        child: Row(
          children: [
            // Avatar with momentum ring
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VesparaColors.background,
                    border: Border.all(
                      color: _getMomentumColor(convo.momentumScore),
                      width: 2,
                    ),
                  ),
                  child: convo.matchAvatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            convo.matchAvatarUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: VesparaColors.secondary,
                          size: 28,
                        ),
                ),
                // Unread badge
                if (convo.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: VesparaColors.glow,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: VesparaColors.surface,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          convo.unreadCount > 9 ? '9+' : convo.unreadCount.toString(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: VesparaColors.background,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: VesparaSpacing.md),
            
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
                          convo.matchName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: convo.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(convo.lastMessageAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          convo.lastMessage ?? 'No messages yet',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: convo.unreadCount > 0
                                ? VesparaColors.primary
                                : VesparaColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Momentum indicator
                      _buildMomentumBadge(context, convo.momentumScore),
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
  
  Widget _buildStaleConversationTile(BuildContext context, Conversation convo) {
    return Container(
      margin: const EdgeInsets.only(bottom: VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
        border: Border.all(
          color: VesparaColors.tagsYellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Conversation info
          GestureDetector(
            onTap: () {
              VesparaHaptics.lightTap();
              _openConversation(context, convo);
            },
            child: Padding(
              padding: const EdgeInsets.all(VesparaSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VesparaColors.background,
                      border: Border.all(
                        color: VesparaColors.tagsYellow.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: VesparaColors.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: VesparaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              convo.matchName,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: VesparaColors.tagsYellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'STALE',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: VesparaColors.tagsYellow,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last message: ${_formatTime(convo.lastMessageAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Divider
          const Divider(color: VesparaColors.border, height: 1),
          
          // Resuscitator button
          GestureDetector(
            onTap: () => _showResuscitator(context, convo),
            child: Container(
              padding: const EdgeInsets.all(VesparaSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    color: VesparaColors.glow,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CONVERSATION RESUSCITATOR',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: VesparaColors.glow,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
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
  
  Widget _buildMomentumBadge(BuildContext context, double score) {
    final color = _getMomentumColor(score);
    final label = score > 0.7 ? 'HOT' : (score > 0.4 ? 'WARM' : 'COLD');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getMomentumColor(double score) {
    if (score > 0.7) return VesparaColors.tagsGreen;
    if (score > 0.4) return VesparaColors.tagsYellow;
    return VesparaColors.tagsRed;
  }
  
  String _formatTime(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
  
  void _openConversation(BuildContext context, Conversation convo) {
    // Navigate to conversation detail
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ConversationSheet(conversation: convo),
    );
  }
  
  void _showResuscitator(BuildContext context, Conversation convo) {
    VesparaHaptics.mediumTap();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ResuscitatorSheet(
        conversation: convo,
        onGenerate: (message) {
          // Copy to clipboard or send
        },
      ),
    );
  }
}

/// Conversation Detail Sheet
class _ConversationSheet extends StatelessWidget {
  final Conversation conversation;
  
  const _ConversationSheet({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: VesparaColors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VesparaBorderRadius.tile),
        ),
      ),
      child: Column(
        children: [
          // Handle and header
          Container(
            padding: const EdgeInsets.all(VesparaSpacing.md),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(VesparaBorderRadius.tile),
              ),
            ),
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
                const SizedBox(height: VesparaSpacing.md),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.background,
                        border: Border.all(
                          color: VesparaColors.glow.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: VesparaColors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: VesparaSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.matchName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Momentum: ${(conversation.momentumScore * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Messages placeholder
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: VesparaColors.inactive,
                    size: 48,
                  ),
                  const SizedBox(height: VesparaSpacing.md),
                  Text(
                    'Messages will appear here',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(VesparaSpacing.md),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              border: Border(
                top: BorderSide(color: VesparaColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: VesparaColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: VesparaColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.send,
                      color: VesparaColors.background,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Conversation Resuscitator Sheet
class _ResuscitatorSheet extends StatefulWidget {
  final Conversation conversation;
  final Function(String) onGenerate;
  
  const _ResuscitatorSheet({
    required this.conversation,
    required this.onGenerate,
  });

  @override
  State<_ResuscitatorSheet> createState() => _ResuscitatorSheetState();
}

class _ResuscitatorSheetState extends State<_ResuscitatorSheet> {
  String? _generatedMessage;
  bool _isLoading = false;
  
  Future<void> _generateResuscitator() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final message = await OpenAIService.generateResuscitator(
        matchName: widget.conversation.matchName,
        lastMessages: widget.conversation.lastMessage ?? '',
        matchInterests: '', // Would come from match profile
      );
      
      setState(() {
        _generatedMessage = message;
      });
    } catch (e) {
      setState(() {
        _generatedMessage = 'Unable to generate message. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VesparaBorderRadius.tile),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VesparaColors.inactive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_fix_high,
                  color: VesparaColors.glow,
                  size: 24,
                ),
              ),
              const SizedBox(width: VesparaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONVERSATION RESUSCITATOR',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'AI-powered message to revive the chat',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Target conversation
          Container(
            padding: const EdgeInsets.all(VesparaSpacing.md),
            decoration: BoxDecoration(
              color: VesparaColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: VesparaColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.conversation.matchName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  'Last: ${_formatDaysAgo(widget.conversation.lastMessageAt)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: VesparaColors.tagsYellow,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Generated message or generate button
          if (_generatedMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(VesparaSpacing.md),
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VesparaColors.glow.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUGGESTED MESSAGE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: VesparaColors.glow,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: VesparaSpacing.sm),
                  Text(
                    _generatedMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: VesparaColors.primary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VesparaSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generateResuscitator,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('REGENERATE'),
                  ),
                ),
                const SizedBox(width: VesparaSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onGenerate(_generatedMessage!);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('USE THIS'),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateResuscitator,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VesparaColors.background,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isLoading ? 'GENERATING...' : 'GENERATE OPENER',
                ),
              ),
            ),
          ],
          
          const SizedBox(height: VesparaSpacing.lg),
        ],
      ),
    );
  }
  
  String _formatDaysAgo(DateTime? date) {
    if (date == null) return 'Never';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }
}
