import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/wire_provider.dart';
import '../../../core/domain/models/wire_models.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// WIRE GROUP INFO SCREEN - WhatsApp-Style Group Settings & Info
/// ════════════════════════════════════════════════════════════════════════════

class WireGroupInfoScreen extends ConsumerStatefulWidget {
  final String conversationId;
  
  const WireGroupInfoScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<WireGroupInfoScreen> createState() => _WireGroupInfoScreenState();
}

class _WireGroupInfoScreenState extends ConsumerState<WireGroupInfoScreen> {
  final _editNameController = TextEditingController();
  final _editDescriptionController = TextEditingController();
  
  bool _isEditingName = false;
  bool _isLoading = false;
  
  WireConversation? get _conversation {
    final conversations = ref.watch(wireProvider).conversations;
    return conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );
  }
  
  List<ConversationParticipant> get _participants {
    return ref.watch(activeParticipantsProvider);
  }
  
  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;
  
  bool get _isAdmin {
    return _participants.any(
      (p) => p.userId == _currentUserId && p.role == ParticipantRole.admin,
    );
  }

  @override
  void dispose() {
    _editNameController.dispose();
    _editDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WireConversation conversation;
    try {
      conversation = _conversation!;
    } catch (e) {
      return Scaffold(
        backgroundColor: VesparaColors.background,
        appBar: AppBar(
          backgroundColor: VesparaColors.surface,
          title: const Text('Group Info'),
        ),
        body: const Center(
          child: Text('Group not found', style: TextStyle(color: VesparaColors.secondary)),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(conversation),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildGroupHeader(conversation),
                _buildDescription(conversation),
                const SizedBox(height: 16),
                _buildMediaSection(),
                const SizedBox(height: 16),
                _buildParticipantsSection(),
                const SizedBox(height: 16),
                _buildSettingsSection(conversation),
                const SizedBox(height: 16),
                _buildDangerZone(conversation),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(WireConversation conversation) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: VesparaColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isAdmin)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _showEditDialog(conversation),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    VesparaColors.glow.withOpacity(0.3),
                    VesparaColors.background,
                  ],
                ),
              ),
              child: conversation.avatarUrl != null
                  ? Image.network(
                      conversation.avatarUrl!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        Icons.group,
                        size: 80,
                        color: VesparaColors.glow.withOpacity(0.5),
                      ),
                    ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    VesparaColors.background.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(WireConversation conversation) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Group name
          if (_isEditingName)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _editNameController,
                    autofocus: true,
                    style: const TextStyle(
                      color: VesparaColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: VesparaColors.glow),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: VesparaColors.glow, width: 2),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: VesparaColors.glow),
                  onPressed: _saveName,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: VesparaColors.secondary),
                  onPressed: () => setState(() => _isEditingName = false),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: _isAdmin ? () => _startEditingName(conversation) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    conversation.name,
                    style: const TextStyle(
                      color: VesparaColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: VesparaColors.secondary,
                    ),
                  ],
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Group created info
          Text(
            'Group · ${_participants.length} participants',
            style: TextStyle(
              color: VesparaColors.secondary,
              fontSize: 14,
            ),
          ),
          
          Text(
            'Created ${_formatDate(conversation.createdAt)}',
            style: TextStyle(
              color: VesparaColors.secondary.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(WireConversation conversation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  color: VesparaColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isAdmin)
                GestureDetector(
                  onTap: () => _showEditDescriptionDialog(conversation),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: VesparaColors.glow,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conversation.description ?? 'No description',
            style: TextStyle(
              color: conversation.description != null 
                  ? VesparaColors.primary 
                  : VesparaColors.secondary,
              fontSize: 14,
              fontStyle: conversation.description == null 
                  ? FontStyle.italic 
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.photo_library, color: VesparaColors.glow),
            ),
            title: const Text(
              'Media, Links, and Docs',
              style: TextStyle(color: VesparaColors.primary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '0',
                  style: TextStyle(color: VesparaColors.secondary),
                ),
                Icon(Icons.chevron_right, color: VesparaColors.secondary),
              ],
            ),
            onTap: () {
              VesparaHaptics.lightTap();
              // TODO: Navigate to media gallery
            },
          ),
          const Divider(height: 1, color: VesparaColors.border, indent: 72),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: VesparaColors.tagsYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, color: VesparaColors.tagsYellow),
            ),
            title: const Text(
              'Starred Messages',
              style: TextStyle(color: VesparaColors.primary),
            ),
            trailing: Icon(Icons.chevron_right, color: VesparaColors.secondary),
            onTap: () {
              VesparaHaptics.lightTap();
              // TODO: Navigate to starred messages
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    final participants = _participants;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${participants.length} Participants',
                  style: TextStyle(
                    color: VesparaColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isAdmin)
                  GestureDetector(
                    onTap: _showAddParticipantsSheet,
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 16,
                          color: VesparaColors.glow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: VesparaColors.glow,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Participant list
          ...participants.map((participant) => _buildParticipantTile(participant)),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(ConversationParticipant participant) {
    final isCurrentUser = participant.userId == _currentUserId;
    
    return ListTile(
      onLongPress: _isAdmin && !isCurrentUser 
          ? () => _showParticipantOptions(participant) 
          : null,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: VesparaColors.background,
        backgroundImage: participant.avatarUrl != null 
            ? NetworkImage(participant.avatarUrl!) 
            : null,
        child: participant.avatarUrl == null
            ? Text(
                (participant.displayName ?? 'U').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: VesparaColors.glow,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isCurrentUser 
                  ? 'You' 
                  : (participant.displayName ?? 'Unknown'),
              style: const TextStyle(
                color: VesparaColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (participant.role == ParticipantRole.admin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.glow,
                ),
              ),
            ),
        ],
      ),
      subtitle: participant.nickname != null
          ? Text(
              '~${participant.nickname}',
              style: TextStyle(
                color: VesparaColors.secondary,
                fontSize: 12,
              ),
            )
          : null,
    );
  }

  Widget _buildSettingsSection(WireConversation conversation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Mute notifications
          SwitchListTile(
            value: conversation.isMuted,
            onChanged: (value) => _toggleMute(),
            secondary: Icon(
              conversation.isMuted 
                  ? Icons.notifications_off 
                  : Icons.notifications,
              color: VesparaColors.secondary,
            ),
            title: const Text(
              'Mute Notifications',
              style: TextStyle(color: VesparaColors.primary),
            ),
            activeColor: VesparaColors.glow,
          ),
          const Divider(height: 1, color: VesparaColors.border, indent: 56),
          
          // Custom notifications
          ListTile(
            leading: Icon(Icons.music_note, color: VesparaColors.secondary),
            title: const Text(
              'Custom Notifications',
              style: TextStyle(color: VesparaColors.primary),
            ),
            trailing: Icon(Icons.chevron_right, color: VesparaColors.secondary),
            onTap: () {
              VesparaHaptics.lightTap();
              // TODO: Navigate to custom notifications
            },
          ),
          const Divider(height: 1, color: VesparaColors.border, indent: 56),
          
          // Disappearing messages
          ListTile(
            leading: Icon(Icons.timer, color: VesparaColors.secondary),
            title: const Text(
              'Disappearing Messages',
              style: TextStyle(color: VesparaColors.primary),
            ),
            subtitle: Text(
              'Off',
              style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: VesparaColors.secondary),
            onTap: () {
              VesparaHaptics.lightTap();
              // TODO: Show disappearing messages options
            },
          ),
          const Divider(height: 1, color: VesparaColors.border, indent: 56),
          
          // Group permissions (admin only)
          if (_isAdmin)
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: VesparaColors.secondary),
              title: const Text(
                'Group Permissions',
                style: TextStyle(color: VesparaColors.primary),
              ),
              trailing: Icon(Icons.chevron_right, color: VesparaColors.secondary),
              onTap: () {
                VesparaHaptics.lightTap();
                // TODO: Navigate to group permissions
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(WireConversation conversation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Report group
          ListTile(
            leading: Icon(Icons.flag_outlined, color: VesparaColors.tagsRed),
            title: Text(
              'Report Group',
              style: TextStyle(color: VesparaColors.tagsRed),
            ),
            onTap: () {
              VesparaHaptics.lightTap();
              _showReportDialog();
            },
          ),
          const Divider(height: 1, color: VesparaColors.border, indent: 56),
          
          // Leave group
          ListTile(
            leading: Icon(Icons.exit_to_app, color: VesparaColors.tagsRed),
            title: Text(
              'Leave Group',
              style: TextStyle(color: VesparaColors.tagsRed),
            ),
            onTap: () {
              VesparaHaptics.mediumTap();
              _showLeaveConfirmation();
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  void _startEditingName(WireConversation conversation) {
    _editNameController.text = conversation.name;
    setState(() => _isEditingName = true);
  }

  void _saveName() async {
    final newName = _editNameController.text.trim();
    if (newName.isEmpty) return;
    
    setState(() {
      _isEditingName = false;
      _isLoading = true;
    });
    
    try {
      // Update in database
      await Supabase.instance.client
          .from('conversations')
          .update({'name': newName})
          .eq('id', widget.conversationId);
      
      // Refresh data
      await ref.read(wireProvider.notifier).loadConversations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update name: $e'),
          backgroundColor: VesparaColors.tagsRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(WireConversation conversation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VesparaColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: VesparaColors.glow),
              ),
              title: const Text('Change Group Photo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Pick new photo
              },
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: VesparaColors.glow),
              ),
              title: const Text('Edit Group Name'),
              onTap: () {
                Navigator.pop(context);
                _startEditingName(conversation);
              },
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description, color: VesparaColors.glow),
              ),
              title: const Text('Edit Description'),
              onTap: () {
                Navigator.pop(context);
                _showEditDescriptionDialog(conversation);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditDescriptionDialog(WireConversation conversation) {
    _editDescriptionController.text = conversation.description ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: const Text(
          'Edit Description',
          style: TextStyle(color: VesparaColors.primary),
        ),
        content: TextField(
          controller: _editDescriptionController,
          maxLines: 3,
          style: const TextStyle(color: VesparaColors.primary),
          decoration: InputDecoration(
            hintText: 'Group description',
            hintStyle: TextStyle(color: VesparaColors.secondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final newDesc = _editDescriptionController.text.trim();
              
              await Supabase.instance.client
                  .from('conversations')
                  .update({'description': newDesc.isEmpty ? null : newDesc})
                  .eq('id', widget.conversationId);
              
              await ref.read(wireProvider.notifier).loadConversations();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.glow,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddParticipantsSheet() {
    VesparaHaptics.lightTap();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add participants coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showParticipantOptions(ConversationParticipant participant) {
    VesparaHaptics.mediumTap();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VesparaColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: VesparaColors.glow),
              title: Text(
                participant.role == ParticipantRole.admin
                    ? 'Remove Admin'
                    : 'Make Admin',
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(wireProvider.notifier).makeParticipantAdmin(
                  widget.conversationId,
                  participant.userId,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.remove_circle_outline, color: VesparaColors.tagsRed),
              title: Text(
                'Remove from Group',
                style: TextStyle(color: VesparaColors.tagsRed),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(wireProvider.notifier).removeParticipant(
                  widget.conversationId,
                  participant.userId,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _toggleMute() async {
    VesparaHaptics.lightTap();
    await ref.read(wireProvider.notifier).toggleMute(widget.conversationId);
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: const Text(
          'Report Group',
          style: TextStyle(color: VesparaColors.primary),
        ),
        content: const Text(
          'Are you sure you want to report this group for inappropriate content?',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.tagsRed,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: const Text(
          'Leave Group',
          style: TextStyle(color: VesparaColors.primary),
        ),
        content: const Text(
          'Are you sure you want to leave this group? You won\'t be able to see messages unless you\'re added back.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              if (_currentUserId != null) {
                await ref.read(wireProvider.notifier).removeParticipant(
                  widget.conversationId,
                  _currentUserId!,
                );
              }
              
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.tagsRed,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
