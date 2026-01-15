import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/domain/models/roster_match.dart';
import '../../../core/services/openai_service.dart';

/// The Shredder Screen - Ghost Protocol
/// Gracefully end connections with AI-generated closure messages
class ShredderScreen extends ConsumerStatefulWidget {
  const ShredderScreen({super.key});

  @override
  ConsumerState<ShredderScreen> createState() => _ShredderScreenState();
}

class _ShredderScreenState extends ConsumerState<ShredderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shredderController;
  bool _isShredderActive = false;
  RosterMatch? _matchBeingShredded;
  final List<RosterMatch> _shreddedMatches = [];
  
  @override
  void initState() {
    super.initState();
    _shredderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }
  
  @override
  void dispose() {
    _shredderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staleMatches = ref.watch(staleMatchesProvider);
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Info banner
            _buildInfoBanner(context),
            
            // Stale matches list
            Expanded(
              child: Builder(
                builder: (context) {
                  // Filter out already shredded
                  final remaining = staleMatches
                      .where((m) => !_shreddedMatches.any((s) => s.id == m.id))
                      .toList();
                  
                  if (remaining.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  
                  return _buildMatchesList(context, remaining);
                },
              ),
            ),
            
            // Shredder zone
            _buildShredderZone(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
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
                  'THE SHREDDER',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Ghost Protocol',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VesparaColors.tagsRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete_sweep,
              color: VesparaColors.tagsRed,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VesparaSpacing.md),
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              color: VesparaColors.glow,
              size: 20,
            ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'End connections gracefully',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Drag matches to the shredder for AI-generated closure messages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
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
            'All clear!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: VesparaSpacing.sm),
          Text(
            'No stale connections need attention',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_shreddedMatches.isNotEmpty) ...[
            const SizedBox(height: VesparaSpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_shreddedMatches.length} connection${_shreddedMatches.length > 1 ? 's' : ''} gracefully ended',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: VesparaColors.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMatchesList(BuildContext context, List<RosterMatch> matches) {
    return ListView.builder(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return _buildDraggableMatch(context, matches[index]);
      },
    );
  }
  
  Widget _buildDraggableMatch(BuildContext context, RosterMatch match) {
    return LongPressDraggable<RosterMatch>(
      data: match,
      onDragStarted: () {
        VesparaHaptics.mediumTap();
        setState(() => _isShredderActive = true);
      },
      onDragEnd: (_) {
        setState(() => _isShredderActive = false);
      },
      onDraggableCanceled: (_, __) {
        setState(() => _isShredderActive = false);
      },
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: _buildMatchCard(context, match, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildMatchCard(context, match),
      ),
      child: _buildMatchCard(context, match),
    );
  }
  
  Widget _buildMatchCard(
    BuildContext context,
    RosterMatch match, {
    bool isDragging = false,
  }) {
    final daysSinceContact = match.lastContactDate != null
        ? DateTime.now().difference(match.lastContactDate!).inDays
        : 0;
    
    return Container(
      width: isDragging ? 320 : null,
      margin: const EdgeInsets.only(bottom: VesparaSpacing.sm),
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: isDragging
            ? VesparaColors.tagsRed.withOpacity(0.1)
            : VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
        border: Border.all(
          color: isDragging
              ? VesparaColors.tagsRed.withOpacity(0.5)
              : VesparaColors.border,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: VesparaColors.tagsRed.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VesparaColors.background,
              border: Border.all(
                color: VesparaColors.tagsYellow.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: match.avatarUrl != null
                ? ClipOval(
                    child: Image.network(match.avatarUrl!, fit: BoxFit.cover),
                  )
                : const Icon(
                    Icons.person,
                    color: VesparaColors.secondary,
                    size: 26,
                  ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: VesparaColors.tagsRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${daysSinceContact}d silent',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: VesparaColors.tagsRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  match.source ?? 'Unknown source',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          // Drag hint
          if (!isDragging)
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.drag_indicator,
                color: VesparaColors.inactive,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildShredderZone(BuildContext context) {
    return DragTarget<RosterMatch>(
      onWillAcceptWithDetails: (details) {
        VesparaHaptics.lightTap();
        return true;
      },
      onAcceptWithDetails: (details) {
        _showGhostProtocolSheet(context, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(VesparaSpacing.md),
          padding: const EdgeInsets.all(VesparaSpacing.lg),
          decoration: BoxDecoration(
            color: isHovering
                ? VesparaColors.tagsRed.withOpacity(0.2)
                : _isShredderActive
                    ? VesparaColors.tagsRed.withOpacity(0.1)
                    : VesparaColors.surface,
            borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
            border: Border.all(
              color: isHovering
                  ? VesparaColors.tagsRed
                  : _isShredderActive
                      ? VesparaColors.tagsRed.withOpacity(0.5)
                      : VesparaColors.border,
              width: isHovering ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isHovering ? 20 : 16),
                decoration: BoxDecoration(
                  color: isHovering
                      ? VesparaColors.tagsRed.withOpacity(0.3)
                      : VesparaColors.tagsRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHovering ? Icons.delete_forever : Icons.delete_sweep,
                  color: VesparaColors.tagsRed,
                  size: isHovering ? 36 : 28,
                ),
              ),
              const SizedBox(height: VesparaSpacing.sm),
              Text(
                isHovering ? 'RELEASE TO SHRED' : 'DROP HERE TO END CONNECTION',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isHovering
                      ? VesparaColors.tagsRed
                      : VesparaColors.secondary,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showGhostProtocolSheet(BuildContext context, RosterMatch match) {
    // PHASE 5: Special Ghost Protocol haptic pattern
    VesparaHaptics.ghostProtocol();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GhostProtocolSheet(
        match: match,
        onConfirm: () {
          setState(() {
            _shreddedMatches.add(match);
          });
          // Would update backend here
        },
      ),
    );
  }
}

/// Ghost Protocol Sheet - Generate and send closure message
class _GhostProtocolSheet extends StatefulWidget {
  final RosterMatch match;
  final VoidCallback onConfirm;
  
  const _GhostProtocolSheet({
    required this.match,
    required this.onConfirm,
  });

  @override
  State<_GhostProtocolSheet> createState() => _GhostProtocolSheetState();
}

class _GhostProtocolSheetState extends State<_GhostProtocolSheet> {
  String? _generatedMessage;
  bool _isLoading = false;
  bool _sendMessage = true;
  String _selectedTone = 'kind';
  
  final List<Map<String, dynamic>> _tones = [
    {'id': 'kind', 'label': 'Kind', 'icon': Icons.favorite_border},
    {'id': 'honest', 'label': 'Honest', 'icon': Icons.psychology},
    {'id': 'brief', 'label': 'Brief', 'icon': Icons.short_text},
  ];
  
  @override
  void initState() {
    super.initState();
    _generateMessage();
  }
  
  Future<void> _generateMessage() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final message = await OpenAIService.generateGhostProtocol(
        matchName: widget.match.name,
        tone: _selectedTone,
        duration: widget.match.lastContactDate != null
            ? DateTime.now().difference(widget.match.lastContactDate!).inDays
            : 30,
      );
      
      setState(() {
        _generatedMessage = message;
      });
    } catch (e) {
      setState(() {
        _generatedMessage = _getFallbackMessage();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  String _getFallbackMessage() {
    switch (_selectedTone) {
      case 'honest':
        return "Hey ${widget.match.name}, I wanted to be upfront with you. I've been doing some reflecting and I don't think I'm able to give this the attention it deserves right now. I wish you the best.";
      case 'brief':
        return "Hey ${widget.match.name}, I've enjoyed getting to know you but I think it's best we part ways. Take care.";
      case 'kind':
      default:
        return "Hi ${widget.match.name}, I hope you're doing well. I've been reflecting on things and while I've really appreciated our connection, I think it's best if we both move forward separately. I wish you nothing but the best in everything you do.";
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
                  color: VesparaColors.tagsRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_sweep,
                  color: VesparaColors.tagsRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: VesparaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GHOST PROTOCOL',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        letterSpacing: 2,
                        color: VesparaColors.tagsRed,
                      ),
                    ),
                    Text(
                      'End connection with ${widget.match.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Tone selector
          Container(
            padding: const EdgeInsets.all(VesparaSpacing.sm),
            decoration: BoxDecoration(
              color: VesparaColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: _tones.map((tone) {
                final isSelected = _selectedTone == tone['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      VesparaHaptics.lightTap();
                      setState(() {
                        _selectedTone = tone['id'];
                      });
                      _generateMessage();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? VesparaColors.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tone['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? VesparaColors.primary
                                : VesparaColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tone['label'] as String,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? VesparaColors.primary
                                  : VesparaColors.secondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Generated message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(VesparaSpacing.md),
            decoration: BoxDecoration(
              color: VesparaColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VesparaColors.border),
            ),
            child: _isLoading
                ? Column(
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2),
                      const SizedBox(height: VesparaSpacing.md),
                      Text(
                        'Generating closure message...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: VesparaColors.glow,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI-GENERATED MESSAGE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: VesparaColors.glow,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VesparaSpacing.sm),
                      Text(
                        _generatedMessage ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
          
          const SizedBox(height: VesparaSpacing.md),
          
          // Send message toggle
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VesparaSpacing.md,
              vertical: VesparaSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: VesparaColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send closure message',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Message will be sent before archiving',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _sendMessage,
                  onChanged: (value) {
                    VesparaHaptics.lightTap();
                    setState(() => _sendMessage = value);
                  },
                  activeColor: VesparaColors.glow,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: VesparaSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          VesparaHaptics.heavyTap();
                          widget.onConfirm();
                          Navigator.pop(context);
                          _showConfirmationSnackbar(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.tagsRed,
                  ),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: Text(_sendMessage ? 'SEND & ARCHIVE' : 'ARCHIVE'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
        ],
      ),
    );
  }
  
  void _showConfirmationSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: VesparaColors.tagsGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _sendMessage
                    ? 'Message sent. ${widget.match.name} archived.'
                    : '${widget.match.name} archived.',
              ),
            ),
          ],
        ),
        backgroundColor: VesparaColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
