import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'conversation_health_monitor.dart';
import 'smart_defaults_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GENTLE NUDGE SYSTEM - Subtle Encouragement
/// ════════════════════════════════════════════════════════════════════════════
///
/// Provides helpful nudges without being annoying:
/// - Conversation reminders
/// - Profile improvement tips
/// - Game suggestions
/// - Activity prompts
///
/// All nudges are dismissible and respect user preferences.

class GentleNudgeSystem {
  static GentleNudgeSystem? _instance;
  static GentleNudgeSystem get instance => _instance ??= GentleNudgeSystem._();

  GentleNudgeSystem._();

  final ConversationHealthMonitor _conversationMonitor = ConversationHealthMonitor.instance;
  final SmartDefaultsService _smartDefaults = SmartDefaultsService.instance;

  // Nudge preferences
  bool _nudgesEnabled = true;
  final Set<String> _dismissedNudges = {};
  final Map<String, DateTime> _lastShownTime = {};

  // Cooldowns
  static const Duration _conversationNudgeCooldown = Duration(hours: 6);
  static const Duration _profileNudgeCooldown = Duration(days: 1);
  static const Duration _gameNudgeCooldown = Duration(hours: 12);

  // Stream for UI to listen to
  final _nudgeController = StreamController<Nudge>.broadcast();
  Stream<Nudge> get nudgeStream => _nudgeController.stream;

  // ═══════════════════════════════════════════════════════════════════════════
  // NUDGE GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check for nudges to show (call periodically or on screen changes)
  Future<List<Nudge>> checkForNudges() async {
    if (!_nudgesEnabled) return [];

    final nudges = <Nudge>[];

    // Check conversation nudges
    final conversationNudges = await _checkConversationNudges();
    nudges.addAll(conversationNudges);

    // Check profile nudges
    final profileNudges = await _checkProfileNudges();
    nudges.addAll(profileNudges);

    return nudges;
  }

  Future<List<Nudge>> _checkConversationNudges() async {
    if (!_canShowNudge('conversation', _conversationNudgeCooldown)) {
      return [];
    }

    try {
      final matchesNeedingAttention = await _conversationMonitor.getMatchesNeedingAttention();
      
      return matchesNeedingAttention.take(3).map((match) {
        return Nudge(
          id: 'conversation_${match.matchId}',
          type: NudgeCategory.conversation,
          title: match.otherUserName,
          message: match.message,
          action: NudgeAction(
            label: 'Message',
            route: '/chat/${match.matchId}',
          ),
          imageUrl: match.otherUserPhoto,
          priority: _nudgeTypePriority(match.nudgeType),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Nudge>> _checkProfileNudges() async {
    if (!_canShowNudge('profile', _profileNudgeCooldown)) {
      return [];
    }

    try {
      final suggestions = await _smartDefaults.getProfileSuggestions();
      
      return suggestions.take(2).map((suggestion) {
        return Nudge(
          id: 'profile_${suggestion.field}',
          type: NudgeCategory.profile,
          title: 'Improve your profile',
          message: suggestion.message,
          action: NudgeAction(
            label: 'Update',
            route: '/profile/edit',
          ),
          priority: suggestion.priority,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  int _nudgeTypePriority(NudgeType type) {
    switch (type) {
      case NudgeType.unansweredMessage:
        return 1;
      case NudgeType.noFirstMessage:
        return 2;
      case NudgeType.conversationDying:
        return 3;
      case NudgeType.noResponse:
        return 4;
      case NudgeType.milestone:
        return 5;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get game suggestion nudge for a match
  Future<Nudge?> getGameSuggestionNudge(String matchId) async {
    if (!_canShowNudge('game_$matchId', _gameNudgeCooldown)) {
      return null;
    }

    try {
      final suggestion = await _smartDefaults.suggestGame(matchId: matchId);
      
      _markNudgeShown('game_$matchId');

      return Nudge(
        id: 'game_suggestion_$matchId',
        type: NudgeCategory.game,
        title: 'Ready to play?',
        message: suggestion.reason,
        action: NudgeAction(
          label: 'Play ${_gameDisplayName(suggestion.gameType)}',
          route: '/games/${suggestion.gameType}',
          data: {
            'matchId': matchId,
            'suggestedHeat': suggestion.suggestedHeat,
          },
        ),
        priority: 3,
      );
    } catch (e) {
      return null;
    }
  }

  String _gameDisplayName(String gameType) {
    switch (gameType) {
      case 'down_to_clown':
        return 'Down to Clown';
      case 'ice_breakers':
        return 'Ice Breakers';
      case 'velvet_rope':
        return 'Share or Dare';
      case 'path_of_pleasure':
        return 'Path of Pleasure';
      case 'lane_of_lust':
        return 'Lane of Lust';
      case 'drama_sutra':
        return 'Drama-Sutra';
      default:
        return gameType;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTEXTUAL NUDGES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Show a nudge for current context
  void showContextualNudge(Nudge nudge) {
    if (_dismissedNudges.contains(nudge.id)) return;
    _nudgeController.add(nudge);
  }

  /// Create a "good time to message" nudge
  Nudge? createGoodTimeNudge(String matchName, String matchId) {
    return Nudge(
      id: 'good_time_$matchId',
      type: NudgeCategory.timing,
      title: 'Good time to message $matchName',
      message: 'They\'re usually active now',
      action: NudgeAction(
        label: 'Message',
        route: '/chat/$matchId',
      ),
      priority: 4,
    );
  }

  /// Create a milestone celebration nudge
  Nudge createMilestoneNudge({
    required String matchName,
    required String milestone,
    required String matchId,
  }) {
    return Nudge(
      id: 'milestone_${matchId}_$milestone',
      type: NudgeCategory.celebration,
      title: '🎉 $milestone with $matchName!',
      message: 'You\'re building something special',
      action: NudgeAction(
        label: 'Celebrate',
        route: '/chat/$matchId',
      ),
      priority: 2,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NUDGE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dismiss a nudge (won't show again)
  void dismissNudge(String nudgeId) {
    _dismissedNudges.add(nudgeId);
  }

  /// Temporarily dismiss (will show again after cooldown)
  void snoozeNudge(String nudgeId, Duration duration) {
    _lastShownTime[nudgeId] = DateTime.now().add(duration);
  }

  /// Enable/disable nudges
  void setNudgesEnabled(bool enabled) {
    _nudgesEnabled = enabled;
  }

  bool get nudgesEnabled => _nudgesEnabled;

  bool _canShowNudge(String category, Duration cooldown) {
    final lastShown = _lastShownTime[category];
    if (lastShown == null) return true;
    return DateTime.now().difference(lastShown) > cooldown;
  }

  void _markNudgeShown(String category) {
    _lastShownTime[category] = DateTime.now();
  }

  /// Clear all dismissed nudges (reset)
  void reset() {
    _dismissedNudges.clear();
    _lastShownTime.clear();
  }

  void dispose() {
    _nudgeController.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum NudgeCategory {
  conversation,
  profile,
  game,
  timing,
  celebration,
  tip,
}

class Nudge {
  final String id;
  final NudgeCategory type;
  final String title;
  final String message;
  final NudgeAction? action;
  final String? imageUrl;
  final int priority; // Lower = more important

  Nudge({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.action,
    this.imageUrl,
    this.priority = 5,
  });
}

class NudgeAction {
  final String label;
  final String route;
  final Map<String, dynamic>? data;

  NudgeAction({
    required this.label,
    required this.route,
    this.data,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Subtle nudge card widget
class NudgeCard extends StatelessWidget {
  final Nudge nudge;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const NudgeCard({
    super.key,
    required this.nudge,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (nudge.imageUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(nudge.imageUrl!),
                radius: 24,
              )
            else
              CircleAvatar(
                backgroundColor: _getCategoryColor(nudge.type).withOpacity(0.2),
                radius: 24,
                child: Icon(
                  _getCategoryIcon(nudge.type),
                  color: _getCategoryColor(nudge.type),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nudge.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nudge.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            if (nudge.action != null)
              TextButton(
                onPressed: onAction,
                child: Text(nudge.action!.label),
              ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(NudgeCategory type) {
    switch (type) {
      case NudgeCategory.conversation:
        return Colors.blue;
      case NudgeCategory.profile:
        return Colors.purple;
      case NudgeCategory.game:
        return Colors.orange;
      case NudgeCategory.timing:
        return Colors.green;
      case NudgeCategory.celebration:
        return Colors.pink;
      case NudgeCategory.tip:
        return Colors.teal;
    }
  }

  IconData _getCategoryIcon(NudgeCategory type) {
    switch (type) {
      case NudgeCategory.conversation:
        return Icons.chat_bubble_outline;
      case NudgeCategory.profile:
        return Icons.person_outline;
      case NudgeCategory.game:
        return Icons.sports_esports_outlined;
      case NudgeCategory.timing:
        return Icons.access_time;
      case NudgeCategory.celebration:
        return Icons.celebration;
      case NudgeCategory.tip:
        return Icons.lightbulb_outline;
    }
  }
}

/// Nudge listener widget - shows nudges as they arrive
class NudgeListener extends ConsumerStatefulWidget {
  final Widget child;
  final void Function(BuildContext, Nudge)? onNudge;

  const NudgeListener({
    super.key,
    required this.child,
    this.onNudge,
  });

  @override
  ConsumerState<NudgeListener> createState() => _NudgeListenerState();
}

class _NudgeListenerState extends ConsumerState<NudgeListener> {
  late final StreamSubscription<Nudge> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = GentleNudgeSystem.instance.nudgeStream.listen(_handleNudge);
  }

  void _handleNudge(Nudge nudge) {
    if (widget.onNudge != null) {
      widget.onNudge!(context, nudge);
    } else {
      _showDefaultNudge(nudge);
    }
  }

  void _showDefaultNudge(Nudge nudge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${nudge.title}: ${nudge.message}'),
        action: nudge.action != null
            ? SnackBarAction(
                label: nudge.action!.label,
                onPressed: () {
                  // Navigate to action route
                },
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
