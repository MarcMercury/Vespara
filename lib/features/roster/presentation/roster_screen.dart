import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/data/roster_repository.dart';
import '../../../core/domain/models/roster_match.dart';

/// The Roster Screen - CRM Pipeline Kanban Board
/// Pipeline: Incoming → The Bench → Active Rotation → Legacy
/// 
/// PHASE 2: Now connected to real-time Supabase streams
class RosterScreen extends ConsumerStatefulWidget {
  const RosterScreen({super.key});

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  PipelineStage? _dragTargetStage;
  RosterMatch? _draggingMatch;
  
  @override
  Widget build(BuildContext context) {
    // PHASE 2: Use real-time stream provider
    final matchesAsync = ref.watch(matchesStreamProvider);
    final pipelineMatches = ref.watch(pipelineMatchesStreamProvider);
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Pipeline stats
            _buildPipelineStats(context, pipelineMatches),
            
            // Kanban Board
            Expanded(
              child: _buildKanbanBoard(context, pipelineMatches),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          VesparaHaptics.lightTap();
          _showAddMatchSheet(context);
        },
        backgroundColor: VesparaColors.primary,
        child: const Icon(
          Icons.person_add,
          color: VesparaColors.background,
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
                  'THE ROSTER',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Relationship Pipeline',
                  style: Theme.of(context).textTheme.bodySmall,
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
              Icons.view_kanban_outlined,
              color: VesparaColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPipelineStats(
    BuildContext context,
    Map<PipelineStage, List<RosterMatch>> pipeline,
  ) {
    final totalMatches = pipeline.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final activeCount = pipeline[PipelineStage.activeRotation]?.length ?? 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VesparaSpacing.md),
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: VesparaGlass.tile,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            value: totalMatches.toString(),
            label: 'Total',
            color: VesparaColors.primary,
          ),
          Container(
            width: 1,
            height: 30,
            color: VesparaColors.border,
          ),
          _buildStatItem(
            context,
            value: activeCount.toString(),
            label: 'Active',
            color: VesparaColors.tagsGreen,
          ),
          Container(
            width: 1,
            height: 30,
            color: VesparaColors.border,
          ),
          _buildStatItem(
            context,
            value: (pipeline[PipelineStage.incoming]?.length ?? 0).toString(),
            label: 'Incoming',
            color: VesparaColors.glow,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: VesparaColors.secondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildKanbanBoard(
    BuildContext context,
    Map<PipelineStage, List<RosterMatch>> pipeline,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: PipelineStage.values.map((stage) {
          final matches = pipeline[stage] ?? [];
          return _buildPipelineColumn(context, stage, matches);
        }).toList(),
      ),
    );
  }
  
  Widget _buildPipelineColumn(
    BuildContext context,
    PipelineStage stage,
    List<RosterMatch> matches,
  ) {
    final isDropTarget = _dragTargetStage == stage;
    final columnWidth = MediaQuery.of(context).size.width * 0.75;
    
    return DragTarget<RosterMatch>(
      onWillAcceptWithDetails: (details) {
        if (details.data.stage != stage) {
          setState(() {
            _dragTargetStage = stage;
          });
          VesparaHaptics.selectionClick();
          return true;
        }
        return false;
      },
      onLeave: (_) {
        setState(() {
          _dragTargetStage = null;
        });
      },
      onAcceptWithDetails: (details) {
        _moveMatchToStage(details.data, stage);
        setState(() {
          _dragTargetStage = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: columnWidth,
          margin: const EdgeInsets.only(right: VesparaSpacing.md),
          decoration: BoxDecoration(
            color: isDropTarget
                ? VesparaColors.glow.withOpacity(0.1)
                : VesparaColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
            border: Border.all(
              color: isDropTarget
                  ? VesparaColors.glow
                  : VesparaColors.border,
              width: isDropTarget ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              _buildColumnHeader(context, stage, matches.length),
              
              // Match cards
              Expanded(
                child: matches.isEmpty
                    ? _buildEmptyColumn(context, stage)
                    : ListView.builder(
                        padding: const EdgeInsets.all(VesparaSpacing.sm),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          return _buildMatchCard(context, matches[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildColumnHeader(
    BuildContext context,
    PipelineStage stage,
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VesparaBorderRadius.tile),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStageColor(stage),
            ),
          ),
          const SizedBox(width: VesparaSpacing.sm),
          Expanded(
            child: Text(
              stage.displayName.toUpperCase(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 1.5,
                color: VesparaColors.primary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: VesparaColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: VesparaColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyColumn(BuildContext context, PipelineStage stage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VesparaSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStageIcon(stage),
              color: VesparaColors.inactive,
              size: 32,
            ),
            const SizedBox(height: VesparaSpacing.sm),
            Text(
              'No matches',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: VesparaSpacing.xs),
            Text(
              'Drag here to add',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: VesparaColors.inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMatchCard(BuildContext context, RosterMatch match) {
    final isDragging = _draggingMatch?.id == match.id;
    
    return LongPressDraggable<RosterMatch>(
      data: match,
      onDragStarted: () {
        VesparaHaptics.mediumTap();
        setState(() {
          _draggingMatch = match;
        });
      },
      onDragEnd: (_) {
        setState(() {
          _draggingMatch = null;
        });
      },
      feedback: Material(
        color: Colors.transparent,
        child: _buildMatchCardContent(context, match, isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildMatchCardContent(context, match),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDragging ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: () {
            VesparaHaptics.lightTap();
            _showMatchDetails(context, match);
          },
          child: _buildMatchCardContent(context, match),
        ),
      ),
    );
  }
  
  Widget _buildMatchCardContent(
    BuildContext context,
    RosterMatch match, {
    bool isDragging = false,
  }) {
    return Container(
      width: isDragging ? MediaQuery.of(context).size.width * 0.7 : null,
      margin: const EdgeInsets.only(bottom: VesparaSpacing.sm),
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
        border: Border.all(
          color: isDragging
              ? VesparaColors.glow
              : VesparaColors.border,
          width: isDragging ? 2 : 1,
        ),
        boxShadow: isDragging
            ? VesparaElevation.glow
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VesparaColors.background,
              border: Border.all(
                color: _getMomentumColor(match.momentumScore),
                width: 2,
              ),
            ),
            child: match.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      match.avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: VesparaColors.secondary,
                    size: 24,
                  ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.displayName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Momentum indicator
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getMomentumColor(match.momentumScore),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatLastInteraction(match.lastInteractionAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: VesparaColors.secondary,
                      ),
                    ),
                    if (match.isStale) ...[
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
                  ],
                ),
              ],
            ),
          ),
          
          // Drag handle
          const Icon(
            Icons.drag_indicator,
            color: VesparaColors.inactive,
            size: 20,
          ),
        ],
      ),
    );
  }
  
  Color _getStageColor(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.incoming:
        return VesparaColors.glow;
      case PipelineStage.bench:
        return VesparaColors.tagsYellow;
      case PipelineStage.activeRotation:
        return VesparaColors.tagsGreen;
      case PipelineStage.legacy:
        return VesparaColors.secondary;
    }
  }
  
  IconData _getStageIcon(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.incoming:
        return Icons.inbox_outlined;
      case PipelineStage.bench:
        return Icons.hourglass_empty;
      case PipelineStage.activeRotation:
        return Icons.favorite_outline;
      case PipelineStage.legacy:
        return Icons.history;
    }
  }
  
  Color _getMomentumColor(double score) {
    if (score > 0.7) return VesparaColors.tagsGreen;
    if (score > 0.4) return VesparaColors.tagsYellow;
    return VesparaColors.tagsRed;
  }
  
  String _formatLastInteraction(DateTime? date) {
    if (date == null) return 'No interaction yet';
    
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
  
  void _moveMatchToStage(RosterMatch match, PipelineStage newStage) async {
    VesparaHaptics.success();
    
    // PHASE 2: Update Supabase via repository
    final stageName = _stageToDbName(newStage);
    final repository = ref.read(rosterRepositoryProvider);
    
    // Optimistic UI update is handled by real-time stream
    final success = await repository.updateMatchStatus(match.id, stageName);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Moved ${match.displayName} to ${newStage.displayName}'
                : 'Failed to move ${match.displayName}',
          ),
          backgroundColor: success ? VesparaColors.surfaceElevated : Colors.red.shade800,
          action: success ? SnackBarAction(
            label: 'UNDO',
            textColor: VesparaColors.glow,
            onPressed: () async {
              // Undo: move back to original stage
              await repository.updateMatchStatus(match.id, _stageToDbName(match.stage));
            },
          ) : null,
        ),
      );
    }
  }
  
  /// Convert PipelineStage enum to database string
  String _stageToDbName(PipelineStage stage) {
    switch (stage) {
      case PipelineStage.incoming:
        return 'incoming';
      case PipelineStage.bench:
        return 'bench';
      case PipelineStage.activeRotation:
        return 'active';
      case PipelineStage.legacy:
        return 'legacy';
    }
  }
  
  void _showMatchDetails(BuildContext context, RosterMatch match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MatchDetailsSheet(match: match),
    );
  }
  
  void _showAddMatchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              'ADD TO ROSTER',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: VesparaSpacing.lg),
            Text(
              'Import from connected apps or add manually',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: VesparaSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.import_export),
                    label: const Text('IMPORT'),
                  ),
                ),
                const SizedBox(width: VesparaSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('MANUAL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VesparaSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Match Details Bottom Sheet
class _MatchDetailsSheet extends StatelessWidget {
  final RosterMatch match;
  
  const _MatchDetailsSheet({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VesparaBorderRadius.tile),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.all(VesparaSpacing.md),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VesparaColors.inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Profile header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VesparaSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
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
                    size: 40,
                  ),
                ),
                const SizedBox(width: VesparaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: VesparaColors.glow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          match.stage.displayName,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: VesparaColors.glow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VesparaSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.chat_bubble_outline,
                  label: 'Message',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.event_outlined,
                  label: 'Schedule',
                  onTap: () {},
                ),
                _buildActionButton(
                  context,
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  onTap: () {},
                ),
                _buildActionButton(
                  context,
                  icon: Icons.auto_delete_outlined,
                  label: 'Shred',
                  color: VesparaColors.tagsRed,
                  onTap: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          const Divider(color: VesparaColors.border),
          
          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(VesparaSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    label: 'Matched',
                    value: _formatDate(match.matchedAt),
                  ),
                  _buildDetailRow(
                    context,
                    label: 'Last interaction',
                    value: match.lastInteractionAt != null
                        ? _formatDate(match.lastInteractionAt!)
                        : 'None',
                  ),
                  _buildDetailRow(
                    context,
                    label: 'Momentum Score',
                    value: '${(match.momentumScore * 100).toStringAsFixed(0)}%',
                  ),
                  if (match.bio != null) ...[
                    const SizedBox(height: VesparaSpacing.md),
                    Text(
                      'BIO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: VesparaColors.secondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: VesparaSpacing.sm),
                    Text(
                      match.bio!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (match.tags.isNotEmpty) ...[
                    const SizedBox(height: VesparaSpacing.md),
                    Text(
                      'TAGS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: VesparaColors.secondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: VesparaSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: match.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: VesparaColors.glow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: VesparaColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        VesparaHaptics.lightTap();
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (color ?? VesparaColors.glow).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? VesparaColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color ?? VesparaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VesparaSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: VesparaColors.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
