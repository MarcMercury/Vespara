import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/wire_models.dart';
import '../../../core/utils/haptics.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// WIRE MESSAGE BUBBLE - WhatsApp-Style Message Display
/// ════════════════════════════════════════════════════════════════════════════

class WireMessageBubble extends ConsumerWidget {
  final WireMessage message;
  final bool isGroup;
  final bool showSenderName;
  final VoidCallback onReply;
  final Function(String emoji) onReact;
  final VoidCallback onDelete;
  final VoidCallback onForward;
  final VoidCallback onStar;
  final VoidCallback onCopy;
  
  const WireMessageBubble({
    super.key,
    required this.message,
    this.isGroup = false,
    this.showSenderName = false,
    required this.onReply,
    required this.onReact,
    required this.onDelete,
    required this.onForward,
    required this.onStar,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = message.senderId == currentUserId;
    final isStarred = message.starredBy.contains(currentUserId);
    
    // System messages are centered
    if (message.type == MessageType.system) {
      return _buildSystemMessage(context);
    }
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, isMe, isStarred),
      onDoubleTap: () {
        VesparaHaptics.lightTap();
        onReact('❤️');
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
          top: showSenderName ? 8 : 2,
          bottom: 2,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name for group chats
            if (showSenderName && !isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.senderName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getSenderColor(message.senderId),
                  ),
                ),
              ),
            
            // Message bubble
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar for others in groups
                if (!isMe && isGroup)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildSmallAvatar(),
                  ),
                
                // Bubble
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? VesparaColors.glow.withOpacity(0.15) : VesparaColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isMe 
                            ? VesparaColors.glow.withOpacity(0.3) 
                            : VesparaColors.border,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply preview
                          if (message.replyToId != null)
                            _buildReplyPreview(context),
                          
                          // Forwarded indicator
                          if (message.forwardedFromId != null)
                            _buildForwardedIndicator(context),
                          
                          // Message content
                          _buildContent(context, isMe),
                          
                          // Reactions
                          if (message.reactions.isNotEmpty)
                            _buildReactions(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: VesparaColors.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message.content ?? '',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: VesparaColors.secondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSmallAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VesparaColors.background,
      ),
      child: message.senderAvatarUrl != null
          ? ClipOval(
              child: Image.network(
                message.senderAvatarUrl!,
                fit: BoxFit.cover,
              ),
            )
          : Icon(
              Icons.person,
              color: VesparaColors.secondary,
              size: 16,
            ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: VesparaColors.background.withOpacity(0.5),
        border: Border(
          left: BorderSide(
            color: VesparaColors.glow,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replySenderName ?? 'Message',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: VesparaColors.glow,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyPreview ?? '...',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildForwardedIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forward,
            size: 12,
            color: VesparaColors.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            'Forwarded',
            style: TextStyle(
              fontSize: 11,
              color: VesparaColors.secondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMe) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextContent(context, isMe);
      case MessageType.image:
        return _buildImageContent(context, isMe);
      case MessageType.video:
        return _buildVideoContent(context, isMe);
      case MessageType.voice:
        return _buildVoiceContent(context, isMe);
      case MessageType.audio:
        return _buildAudioContent(context, isMe);
      case MessageType.file:
        return _buildFileContent(context, isMe);
      case MessageType.location:
        return _buildLocationContent(context, isMe);
      case MessageType.contact:
        return _buildContactContent(context, isMe);
      case MessageType.poll:
        return _buildPollContent(context, isMe);
      case MessageType.gif:
        return _buildGifContent(context, isMe);
      default:
        return _buildTextContent(context, isMe);
    }
  }

  Widget _buildTextContent(BuildContext context, bool isMe) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message text
          if (message.isDeleted)
            Text(
              '🚫 This message was deleted',
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              message.content ?? '',
              style: TextStyle(
                fontSize: 15,
                color: VesparaColors.primary,
                height: 1.3,
              ),
            ),
          
          const SizedBox(height: 4),
          
          // Time and status
          _buildTimeAndStatus(context, isMe),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        if (message.mediaUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              message.mediaUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: VesparaColors.background,
                child: const Center(
                  child: Icon(Icons.broken_image, color: VesparaColors.secondary),
                ),
              ),
            ),
          ),
        
        // Caption
        if (message.content != null && message.content!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content!,
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                _buildTimeAndStatus(context, isMe),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildTimeAndStatus(context, isMe),
          ),
      ],
    );
  }

  Widget _buildVideoContent(BuildContext context, bool isMe) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Thumbnail
        if (message.mediaThumbnailUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              message.mediaThumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
            ),
          )
        else
          Container(
            height: 200,
            color: VesparaColors.background,
          ),
        
        // Play button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 32,
          ),
        ),
        
        // Duration
        if (message.mediaDurationSeconds != null)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(message.mediaDurationSeconds!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceContent(BuildContext context, bool isMe) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: VesparaColors.glow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: VesparaColors.background,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Waveform placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform bars
                Row(
                  children: List.generate(
                    20,
                    (index) => Expanded(
                      child: Container(
                        height: (message.mediaWaveform?.elementAtOrNull(index) ?? 0.5) * 20 + 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: VesparaColors.glow.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(message.mediaDurationSeconds ?? 0),
                      style: TextStyle(
                        fontSize: 11,
                        color: VesparaColors.secondary,
                      ),
                    ),
                    _buildTimeAndStatus(context, isMe),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent(BuildContext context, bool isMe) {
    return _buildVoiceContent(context, isMe); // Similar to voice
  }

  Widget _buildFileContent(BuildContext context, bool isMe) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(message.mediaFilename ?? ''),
              color: VesparaColors.glow,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.mediaFilename ?? 'File',
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatFileSize(message.mediaFilesizeBytes ?? 0),
                  style: TextStyle(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                _buildTimeAndStatus(context, isMe),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContent(BuildContext context, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map placeholder
        Container(
          height: 150,
          width: double.infinity,
          color: VesparaColors.background,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.map,
                size: 48,
                color: VesparaColors.secondary.withOpacity(0.5),
              ),
              const Icon(
                Icons.location_on,
                color: VesparaColors.tagsRed,
                size: 32,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.locationName != null)
                Text(
                  message.locationName!,
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (message.locationAddress != null)
                Text(
                  message.locationAddress!,
                  style: TextStyle(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                  ),
                ),
              const SizedBox(height: 4),
              _buildTimeAndStatus(context, isMe),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactContent(BuildContext context, bool isMe) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: VesparaColors.glow,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.sharedContactName ?? 'Contact',
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (message.sharedContactPhone != null)
                  Text(
                    message.sharedContactPhone!,
                    style: TextStyle(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                    ),
                  ),
                const SizedBox(height: 4),
                _buildTimeAndStatus(context, isMe),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollContent(BuildContext context, bool isMe) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll, size: 20, color: VesparaColors.glow),
              const SizedBox(width: 8),
              Text(
                'POLL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.glow,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.pollQuestion ?? 'Poll',
            style: TextStyle(
              fontSize: 15,
              color: VesparaColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (message.pollOptions != null)
            ...message.pollOptions!.map((option) => _buildPollOption(option)),
          const SizedBox(height: 8),
          _buildTimeAndStatus(context, isMe),
        ],
      ),
    );
  }

  Widget _buildPollOption(PollOption option) {
    final totalVotes = message.pollOptions!.fold(0, (sum, o) => sum + o.voteCount);
    final percentage = totalVotes > 0 ? option.voteCount / totalVotes : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.primary,
                  ),
                ),
              ),
              Text(
                '${option.voteCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: VesparaColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(VesparaColors.glow),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifContent(BuildContext context, bool isMe) {
    return _buildImageContent(context, isMe); // Same as image
  }

  Widget _buildReactions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 4,
        children: message.reactions.map((reaction) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: VesparaColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VesparaColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
                if (reaction.count > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    reaction.count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeAndStatus(BuildContext context, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edited indicator
        if (message.isEdited) ...[
          Text(
            'edited',
            style: TextStyle(
              fontSize: 10,
              color: VesparaColors.secondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
        ],
        
        // Time
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 10,
            color: VesparaColors.secondary,
          ),
        ),
        
        // Status checkmarks for sent messages
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message.status == MessageStatus.read
                ? Icons.done_all
                : message.status == MessageStatus.delivered
                    ? Icons.done_all
                    : message.status == MessageStatus.sent
                        ? Icons.done
                        : message.status == MessageStatus.sending
                            ? Icons.access_time
                            : Icons.error_outline,
            size: 14,
            color: message.status == MessageStatus.read
                ? VesparaColors.glow
                : message.status == MessageStatus.failed
                    ? VesparaColors.tagsRed
                    : VesparaColors.secondary,
          ),
        ],
      ],
    );
  }

  void _showMessageOptions(BuildContext context, bool isMe, bool isStarred) {
    VesparaHaptics.mediumTap();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reaction bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '😂', '😮', '😢', '🙏', '👍'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onReact(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const Divider(color: VesparaColors.border),
              
              // Options
              ListTile(
                leading: const Icon(Icons.reply, color: VesparaColors.primary),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward, color: VesparaColors.primary),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(context);
                  onForward();
                },
              ),
              if (message.type == MessageType.text)
                ListTile(
                  leading: const Icon(Icons.copy, color: VesparaColors.primary),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(context);
                    onCopy();
                  },
                ),
              ListTile(
                leading: Icon(
                  isStarred ? Icons.star : Icons.star_border,
                  color: isStarred ? VesparaColors.tagsYellow : VesparaColors.primary,
                ),
                title: Text(isStarred ? 'Unstar' : 'Star'),
                onTap: () {
                  Navigator.pop(context);
                  onStar();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: VesparaColors.tagsRed),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Color _getSenderColor(String senderId) {
    // Generate consistent color based on sender ID
    final colors = [
      VesparaColors.glow,
      VesparaColors.success,
      VesparaColors.tagsBlue,
      VesparaColors.tagsPurple,
      VesparaColors.tagsYellow,
      VesparaColors.tagsRed,
    ];
    
    final hash = senderId.hashCode.abs();
    return colors[hash % colors.length];
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $ampm';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}
