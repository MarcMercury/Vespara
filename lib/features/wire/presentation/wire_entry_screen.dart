import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import '../../../core/providers/chat_backend_provider.dart';
import '../../../core/services/stream_chat_service.dart';
import '../../../core/theme/app_theme.dart';
import 'wire_home_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// WIRE ENTRY POINT - Routes to Stream Chat or native Supabase Wire
/// ════════════════════════════════════════════════════════════════════════════

class WireEntryScreen extends ConsumerWidget {
  const WireEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final backend = ref.watch(chatBackendProvider);

      if (backend == ChatBackend.stream) {
        return StreamChatWireScreen();
      }
    } catch (e) {
      debugPrint('Wire backend error: $e');
      // Stream Chat not configured — fall through to Supabase Wire
    }

    // Fallback: existing Supabase-powered Wire
    return const WireHomeScreen();
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// STREAM CHAT WIRE - Uses Stream Chat SDK widgets
/// WhatsApp-style channel list with group support
/// ════════════════════════════════════════════════════════════════════════════

class StreamChatWireScreen extends StatelessWidget {
  StreamChatWireScreen({super.key});

  final _client = StreamChatService.client;

  @override
  Widget build(BuildContext context) {
    return stream.StreamChat(
      client: _client,
      streamChatThemeData: _buildStreamTheme(context),
      child: Scaffold(
        backgroundColor: VesparaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: stream.StreamChannelListView(
                  controller: stream.StreamChannelListController(
                    client: _client,
                    filter: stream.Filter.in_(
                      'members',
                      [_client.state.currentUser?.id ?? ''],
                    ),
                    channelStateSort: const [
                      stream.SortOption('last_message_at',
                          direction: stream.SortOption.DESC),
                    ],
                    limit: 30,
                  ),
                  itemBuilder: (context, channels, index, defaultWidget) {
                    return defaultWidget;
                  },
                  onChannelTap: (channel) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => stream.StreamChat(
                          client: _client,
                          streamChatThemeData: _buildStreamTheme(context),
                          child: stream.StreamChannel(
                            channel: channel,
                            child: const StreamChatMessageScreen(),
                          ),
                        ),
                      ),
                    );
                  },
                  emptyBuilder: (context) => _buildEmptyState(context),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateOptions(context),
          backgroundColor: VesparaColors.glow,
          child: const Icon(Icons.chat, color: VesparaColors.background),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  Text(
                    'Encrypted messaging',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: VesparaColors.secondary,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search, color: VesparaColors.primary),
            ),
          ],
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: VesparaColors.secondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: VesparaColors.secondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a chat with a member or create a group',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VesparaColors.secondary.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      );

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: VesparaColors.glow),
              title: const Text('New Direct Message',
                  style: TextStyle(color: VesparaColors.primary)),
              subtitle: const Text('Message a member',
                  style: TextStyle(color: VesparaColors.secondary)),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Show member picker for direct message
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: VesparaColors.glow),
              title: const Text('Create Group',
                  style: TextStyle(color: VesparaColors.primary)),
              subtitle: const Text('Start a group conversation',
                  style: TextStyle(color: VesparaColors.secondary)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StreamCreateGroupScreen(client: _client),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  stream.StreamChatThemeData _buildStreamTheme(BuildContext context) {
    return stream.StreamChatThemeData(
      colorTheme: stream.StreamColorTheme.dark().copyWith(
            textHighEmphasis: VesparaColors.primary,
            textLowEmphasis: VesparaColors.secondary,
            accentPrimary: VesparaColors.glow,
          ),
      channelPreviewTheme: stream.StreamChannelPreviewThemeData(
        titleStyle: const TextStyle(
          color: VesparaColors.primary,
          fontWeight: FontWeight.w600,
        ),
        subtitleStyle: const TextStyle(
          color: VesparaColors.secondary,
          fontSize: 13,
        ),
        lastMessageAtStyle: TextStyle(
          color: VesparaColors.secondary.withOpacity(0.7),
          fontSize: 11,
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// STREAM CHAT MESSAGE SCREEN - Individual conversation view
/// ════════════════════════════════════════════════════════════════════════════

class StreamChatMessageScreen extends StatelessWidget {
  const StreamChatMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      appBar: const stream.StreamChannelHeader(),
      body: Column(
        children: [
          Expanded(
            child: stream.StreamMessageListView(
              messageBuilder: (context, details, messages, defaultWidget) {
                return defaultWidget;
              },
            ),
          ),
          const stream.StreamMessageInput(),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// STREAM CREATE GROUP SCREEN
/// ════════════════════════════════════════════════════════════════════════════

class StreamCreateGroupScreen extends StatefulWidget {
  final stream.StreamChatClient client;

  const StreamCreateGroupScreen({super.key, required this.client});

  @override
  State<StreamCreateGroupScreen> createState() =>
      _StreamCreateGroupScreenState();
}

class _StreamCreateGroupScreenState extends State<StreamCreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final channel = widget.client.channel(
        'messaging',
        extraData: {
          'name': name,
          'description': _descController.text.trim(),
          'members': [widget.client.state.currentUser?.id ?? ''],
        },
      );

      await channel.create();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$name" created'),
            backgroundColor: VesparaColors.surface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        appBar: AppBar(
          backgroundColor: VesparaColors.background,
          foregroundColor: VesparaColors.primary,
          title: const Text('Create Group'),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Group Name',
                style: TextStyle(
                  color: VesparaColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: VesparaColors.primary),
                decoration: InputDecoration(
                  hintText: 'Enter group name',
                  hintStyle: TextStyle(
                    color: VesparaColors.secondary.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: VesparaColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Description (optional)',
                style: TextStyle(
                  color: VesparaColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                style: const TextStyle(color: VesparaColors.primary),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "What's this group about?",
                  hintStyle: TextStyle(
                    color: VesparaColors.secondary.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: VesparaColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    foregroundColor: VesparaColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create Group',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
}
