import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_profile_coach.dart';
import '../services/instant_conversation_starters.dart';
import '../services/match_insights_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// ZERO-FRICTION AI WIDGETS
/// ════════════════════════════════════════════════════════════════════════════
///
/// Design principle: ONE TAP to use AI features
/// - No modals, no forms, no extra steps
/// - AI options appear inline
/// - Tap once to apply

// ═══════════════════════════════════════════════════════════════════════════
// CONVERSATION STARTER CHIPS
// ═══════════════════════════════════════════════════════════════════════════

/// Shows conversation starters as tappable chips above the message input
class StarterChips extends ConsumerStatefulWidget {
  const StarterChips({
    super.key,
    required this.matchId,
    required this.onSend,
    required this.onEdit,
    this.isFirstMessage = true,
  });
  final String matchId;
  final Function(String text) onSend;
  final Function(String text) onEdit;
  final bool isFirstMessage;

  @override
  ConsumerState<StarterChips> createState() => _StarterChipsState();
}

class _StarterChipsState extends ConsumerState<StarterChips>
    with SingleTickerProviderStateMixin {
  List<ConversationStarter> _starters = [];
  bool _isLoading = true;
  bool _isVisible = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadStarters();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStarters() async {
    final service = InstantConversationStarters.instance;

    final starters = widget.isFirstMessage
        ? await service.getFirstMessageStarters(widget.matchId)
        : await service.getStarters(widget.matchId);

    if (mounted) {
      setState(() {
        _starters = starters;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  void _hideChips() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || (_starters.isEmpty && !_isLoading)) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap to send',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _hideChips,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              _buildLoadingChips()
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _starters
                    .map(
                      (starter) => _StarterChip(
                        starter: starter,
                        onTap: () {
                          widget.onSend(starter.text);
                          _hideChips();
                        },
                        onLongPress: () {
                          widget.onEdit(starter.text);
                          _hideChips();
                        },
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChips() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
          3,
          (index) => Container(
            width: 120,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      );
}

class _StarterChip extends StatelessWidget {
  const _StarterChip({
    required this.starter,
    required this.onTap,
    required this.onLongPress,
  });
  final ConversationStarter starter;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  starter.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.send_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// BIO IMPROVE BUTTON
// ═══════════════════════════════════════════════════════════════════════════

/// A magical button that shows bio improvement options
class BioImproveButton extends ConsumerStatefulWidget {
  const BioImproveButton({
    super.key,
    required this.currentBio,
    required this.onApply,
  });
  final String currentBio;
  final Function(String newBio) onApply;

  @override
  ConsumerState<BioImproveButton> createState() => _BioImproveButtonState();
}

class _BioImproveButtonState extends ConsumerState<BioImproveButton> {
  bool _showOptions = false;
  List<BioOption> _options = [];
  bool _isLoading = false;

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _showOptions = true;
    });

    final coach = AIProfileCoach.instance;
    final options = await coach.getImprovedBios(widget.currentBio);

    if (mounted) {
      setState(() {
        _options = options;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The magic button
          if (!_showOptions)
            TextButton.icon(
              onPressed: _loadOptions,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('✨ Improve with AI'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),

          // Options appear inline
          if (_showOptions) ...[
            Row(
              children: [
                Text(
                  'Pick a style:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showOptions = false),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              ..._options.map(
                (option) => _BioOptionCard(
                  option: option,
                  onTap: () {
                    widget.onApply(option.text);
                    setState(() => _showOptions = false);
                  },
                ),
              ),
          ],
        ],
      );
}

class _BioOptionCard extends StatelessWidget {
  const _BioOptionCard({
    required this.option,
    required this.onTap,
  });
  final BioOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(option.styleEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    option.styleLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Use this',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                option.text,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// MATCH INSIGHT CARD
// ═══════════════════════════════════════════════════════════════════════════

/// Shows compatibility insight on a match card
class InsightBadge extends StatelessWidget {
  const InsightBadge({
    super.key,
    required this.insight,
  });
  final String insight;

  @override
  Widget build(BuildContext context) {
    if (insight.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 12,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              insight,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed insight panel for profile view
class InsightPanel extends ConsumerStatefulWidget {
  const InsightPanel({
    super.key,
    required this.otherUserId,
  });
  final String otherUserId;

  @override
  ConsumerState<InsightPanel> createState() => _InsightPanelState();
}

class _InsightPanelState extends ConsumerState<InsightPanel> {
  MatchInsight? _insight;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    final service = MatchInsightsService.instance;
    final insight = await service.getDetailedInsight(widget.otherUserId);

    if (mounted) {
      setState(() {
        _insight = insight;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Finding compatibility...',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_insight == null || _insight!.quickInsight.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Compatibility',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                _insight!.compatibilityEmoji,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick insight
          Text(
            _insight!.quickInsight,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // AI insight if available
          if (_insight!.hasAIInsight) ...[
            const SizedBox(height: 8),
            Text(
              _insight!.aiInsight!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],

          // Shared interests
          if (_insight!.hasSharedInterests) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _insight!.sharedInterests
                  .take(5)
                  .map(
                    (interest) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Conversation topics
          if (_insight!.conversationTopics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Things to talk about:',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 6),
            ..._insight!.conversationTopics.map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        topic,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INLINE QUICK ACTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Quick action chip for profile editing
class QuickActionChip extends StatelessWidget {
  const QuickActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              else
                Icon(icon,
                    size: 14, color: Theme.of(context).colorScheme.primary,),
              const SizedBox(width: 6),
              Text(
                label,
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

/// Row of quick AI actions for profile editing
class AIQuickActions extends StatelessWidget {
  const AIQuickActions({
    super.key,
    this.onImproveBio,
    this.onSuggestInterests,
    this.onGeneratePromptAnswer,
  });
  final VoidCallback? onImproveBio;
  final VoidCallback? onSuggestInterests;
  final VoidCallback? onGeneratePromptAnswer;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (onImproveBio != null)
              QuickActionChip(
                icon: Icons.auto_awesome,
                label: 'Improve bio',
                onTap: onImproveBio!,
              ),
            if (onSuggestInterests != null) ...[
              const SizedBox(width: 8),
              QuickActionChip(
                icon: Icons.interests,
                label: 'Suggest interests',
                onTap: onSuggestInterests!,
              ),
            ],
            if (onGeneratePromptAnswer != null) ...[
              const SizedBox(width: 8),
              QuickActionChip(
                icon: Icons.edit_note,
                label: 'Help with prompts',
                onTap: onGeneratePromptAnswer!,
              ),
            ],
          ],
        ),
      );
}
