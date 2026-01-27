import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/date_planner_service.dart';
import '../services/message_coach_service.dart';
import '../services/relationship_progress_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PHASE 4: PROACTIVE PARTNER - UI Components
/// ════════════════════════════════════════════════════════════════════════════
///
/// Widgets for:
/// - Date planning bottom sheet
/// - Message coaching overlay
/// - Relationship progress display

// ═══════════════════════════════════════════════════════════════════════════
// DATE PLANNER SHEET
// ═══════════════════════════════════════════════════════════════════════════

/// Bottom sheet for date planning - shows instant suggestions
class DatePlannerSheet extends ConsumerStatefulWidget {
  const DatePlannerSheet({
    super.key,
    required this.matchId,
    required this.onShare,
  });
  final String matchId;
  final Function(DateIdea idea, String message) onShare;

  @override
  ConsumerState<DatePlannerSheet> createState() => _DatePlannerSheetState();
}

class _DatePlannerSheetState extends ConsumerState<DatePlannerSheet> {
  List<DateIdea> _ideas = [];
  bool _isLoading = true;
  DateVibe? _selectedVibe;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  Future<void> _loadIdeas() async {
    final service = DatePlannerService.instance;

    List<DateIdea> ideas;
    if (_selectedVibe != null) {
      ideas = await service.getDateIdeasByVibe(
        matchId: widget.matchId,
        vibe: _selectedVibe!,
      );
    } else {
      ideas = await service.getDateIdeas(widget.matchId);
    }

    if (mounted) {
      setState(() {
        _ideas = ideas;
        _isLoading = false;
      });
    }
  }

  void _selectVibe(DateVibe vibe) {
    setState(() {
      _selectedVibe = vibe;
      _isLoading = true;
    });
    _loadIdeas();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🗓️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Ideas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Tap one to share with your match',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Vibe filters
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _VibeChip(
                    label: '✨ For You',
                    isSelected: _selectedVibe == null,
                    onTap: () {
                      setState(() => _selectedVibe = null);
                      _loadIdeas();
                    },
                  ),
                  _VibeChip(
                    label: '💕 Romantic',
                    isSelected: _selectedVibe == DateVibe.romantic,
                    onTap: () => _selectVibe(DateVibe.romantic),
                  ),
                  _VibeChip(
                    label: '🎉 Fun',
                    isSelected: _selectedVibe == DateVibe.fun,
                    onTap: () => _selectVibe(DateVibe.fun),
                  ),
                  _VibeChip(
                    label: '☕ Casual',
                    isSelected: _selectedVibe == DateVibe.casual,
                    onTap: () => _selectVibe(DateVibe.casual),
                  ),
                  _VibeChip(
                    label: '💰 Budget',
                    isSelected: _selectedVibe == DateVibe.cheap,
                    onTap: () => _selectVibe(DateVibe.cheap),
                  ),
                  _VibeChip(
                    label: '⚡ Quick',
                    isSelected: _selectedVibe == DateVibe.quick,
                    onTap: () => _selectVibe(DateVibe.quick),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ideas list
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else
              ...List.generate(_ideas.length, (index) {
                final idea = _ideas[index];
                return _DateIdeaCard(
                  idea: idea,
                  onTap: () async {
                    final service = DatePlannerService.instance;
                    final message = service.getShareMessage(idea);
                    widget.onShare(idea, message);
                    Navigator.pop(context);
                  },
                );
              }),

            const SizedBox(height: 24),
          ],
        ),
      );
}

class _VibeChip extends StatelessWidget {
  const _VibeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
}

class _DateIdeaCard extends StatelessWidget {
  const _DateIdeaCard({
    required this.idea,
    required this.onTap,
  });
  final DateIdea idea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(idea.categoryEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(icon: idea.timeEmoji, label: idea.timeOfDay),
                        const SizedBox(width: 8),
                        _InfoChip(icon: '💵', label: idea.cost),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.send_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// MESSAGE COACH OVERLAY
// ═══════════════════════════════════════════════════════════════════════════

/// Subtle overlay that shows coaching tips while typing
class MessageCoachOverlay extends StatefulWidget {
  const MessageCoachOverlay({
    super.key,
    required this.controller,
    this.onApplySuggestion,
    this.isEnabled = true,
  });
  final TextEditingController controller;
  final Function(String suggestion)? onApplySuggestion;
  final bool isEnabled;

  @override
  State<MessageCoachOverlay> createState() => _MessageCoachOverlayState();
}

class _MessageCoachOverlayState extends State<MessageCoachOverlay>
    with SingleTickerProviderStateMixin {
  final MessageCoachService _coach = MessageCoachService.instance;
  MessageAnalysis? _analysis;
  bool _isDismissed = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
    _coach.cancelPending();
    super.dispose();
  }

  void _onTextChanged() {
    if (!widget.isEnabled) return;

    final text = widget.controller.text;
    if (text.isEmpty) {
      _hideAnalysis();
      return;
    }

    _isDismissed = false;
    _coach.analyzeWhileTyping(text, (analysis) {
      if (mounted && !_isDismissed) {
        setState(() => _analysis = analysis);
        if (analysis != null) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });
  }

  void _hideAnalysis() {
    _isDismissed = true;
    _animationController.reverse();
  }

  void _applySuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    widget.onApplySuggestion?.call(suggestion);
    _hideAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    if (_analysis == null || !widget.isEnabled) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tone indicator
            Row(
              children: [
                Text(_analysis!.toneEmoji,
                    style: const TextStyle(fontSize: 16),),
                const SizedBox(width: 8),
                Text(
                  _analysis!.toneLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _hideAnalysis,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
              ],
            ),

            // Tips
            if (_analysis!.tips.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._analysis!.tips.map(
                (tip) => _CoachingTipRow(
                  tip: tip,
                  onApply: tip.suggestion != null
                      ? () => _applySuggestion(tip.suggestion!)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoachingTipRow extends StatelessWidget {
  const _CoachingTipRow({
    required this.tip,
    this.onApply,
  });
  final CoachingTip tip;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(tip.typeEmoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tip.message,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
            if (onApply != null)
              GestureDetector(
                onTap: onApply,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Use',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// RELATIONSHIP PROGRESS WIDGET
// ═══════════════════════════════════════════════════════════════════════════

/// Shows relationship progress in chat header
class RelationshipProgressBadge extends ConsumerStatefulWidget {
  const RelationshipProgressBadge({
    super.key,
    required this.matchId,
  });
  final String matchId;

  @override
  ConsumerState<RelationshipProgressBadge> createState() =>
      _RelationshipProgressBadgeState();
}

class _RelationshipProgressBadgeState
    extends ConsumerState<RelationshipProgressBadge> {
  RelationshipProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final service = RelationshipProgressService.instance;
    final progress = await service.getProgress(widget.matchId);

    if (mounted) {
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_progress == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showProgressSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_progress!.stage.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              _progress!.stage.label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => RelationshipProgressSheet(progress: _progress!),
    );
  }
}

/// Full progress sheet with milestones and next step
class RelationshipProgressSheet extends StatelessWidget {
  const RelationshipProgressSheet({
    super.key,
    required this.progress,
  });
  final RelationshipProgress progress;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stage header
              Row(
                children: [
                  Text(progress.stage.emoji,
                      style: const TextStyle(fontSize: 32),),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress.stage.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress.stage.progressPercent,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats
              _StatsRow(stats: progress.stats),

              const SizedBox(height: 24),

              // Next step
              if (progress.suggestedNextStep != null) ...[
                Text(
                  'Next Step',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                _NextStepCard(nextStep: progress.suggestedNextStep!),
              ],

              const SizedBox(height: 24),

              // Milestones
              if (progress.milestones.isNotEmpty) ...[
                Text(
                  'Milestones',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                ...progress.milestones.reversed.take(5).map(
                      (m) => _MilestoneRow(
                        milestone: m,
                      ),
                    ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final MatchStats stats;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: stats.daysSinceMatch.toString(),
            label: 'Days',
          ),
          _StatItem(
            value: stats.totalMessages.toString(),
            label: 'Messages',
          ),
          _StatItem(
            value: stats.averageResponseTime != null
                ? '${stats.averageResponseTime!.inMinutes}m'
                : '-',
            label: 'Avg Reply',
          ),
        ],
      );
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      );
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.nextStep});
  final NextStep nextStep;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(nextStep.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nextStep.action,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextStep.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (nextStep.urgency == NextStepUrgency.high)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🔥',
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      );
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone});
  final Milestone milestone;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                milestone.title,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              _formatDate(milestone.achievedAt),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
    return '${diff.inDays ~/ 30} months ago';
  }
}
