import 'package:flutter/material.dart';
import '../utils/haptic_patterns.dart';
import '../utils/player_colors.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG PLAYER CHIP - Player Display Widget
/// ════════════════════════════════════════════════════════════════════════════
///
/// A reusable widget for displaying player information across TAG games.

class TagPlayerChip extends StatelessWidget {
  /// Player name
  final String name;

  /// Player color
  final Color color;

  /// Player score (optional)
  final int? score;

  /// Whether this player is currently active/selected
  final bool isActive;

  /// Whether to show remove button
  final bool showRemove;

  /// Called when remove is tapped
  final VoidCallback? onRemove;

  /// Called when chip is tapped
  final VoidCallback? onTap;

  /// Size variant
  final TagPlayerChipSize size;

  /// Whether chip is in "turn" state (highlighted)
  final bool isTurn;

  const TagPlayerChip({
    super.key,
    required this.name,
    required this.color,
    this.score,
    this.isActive = true,
    this.showRemove = false,
    this.onRemove,
    this.onTap,
    this.size = TagPlayerChipSize.medium,
    this.isTurn = false,
  });

  double get _height => switch (size) {
        TagPlayerChipSize.small => 32,
        TagPlayerChipSize.medium => 44,
        TagPlayerChipSize.large => 56,
      };

  double get _fontSize => switch (size) {
        TagPlayerChipSize.small => 12,
        TagPlayerChipSize.medium => 14,
        TagPlayerChipSize.large => 18,
      };

  double get _avatarSize => switch (size) {
        TagPlayerChipSize.small => 24,
        TagPlayerChipSize.medium => 32,
        TagPlayerChipSize.large => 44,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _height,
        padding: EdgeInsets.only(
          left: 4,
          right: showRemove ? 4 : 12,
        ),
        decoration: BoxDecoration(
          color: isTurn
              ? color.withOpacity(0.3)
              : color.withOpacity(isActive ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(_height / 2),
          border: Border.all(
            color: isTurn ? color : color.withOpacity(isActive ? 0.5 : 0.2),
            width: isTurn ? 2 : 1,
          ),
          boxShadow: isTurn
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: _avatarSize,
              height: _avatarSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: color.contrastingText,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            // Name
            Text(
              name,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontSize: _fontSize,
                fontWeight: isTurn ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            // Score
            if (score != null) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  score.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _fontSize - 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            // Remove button
            if (showRemove) ...[
              SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  TagHaptics.selection();
                  onRemove?.call();
                },
                child: Container(
                  width: _avatarSize - 4,
                  height: _avatarSize - 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: _fontSize,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum TagPlayerChipSize { small, medium, large }

/// ════════════════════════════════════════════════════════════════════════════
/// TAG PLAYER LIST - Scrollable Player Display
/// ════════════════════════════════════════════════════════════════════════════

class TagPlayerList extends StatelessWidget {
  /// List of player names
  final List<String> players;

  /// Index of currently active player (-1 for none)
  final int activeIndex;

  /// Called when player is tapped
  final ValueChanged<int>? onPlayerTap;

  /// Called when remove is tapped
  final ValueChanged<int>? onRemove;

  /// Whether to allow removal
  final bool allowRemoval;

  /// Player scores (optional)
  final List<int>? scores;

  /// Scroll direction
  final Axis direction;

  /// Chip size
  final TagPlayerChipSize chipSize;

  const TagPlayerList({
    super.key,
    required this.players,
    this.activeIndex = -1,
    this.onPlayerTap,
    this.onRemove,
    this.allowRemoval = false,
    this.scores,
    this.direction = Axis.horizontal,
    this.chipSize = TagPlayerChipSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, color: Colors.white38, size: 20),
            SizedBox(width: 8),
            Text(
              'Add players to start',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final chips = List.generate(players.length, (i) {
      return Padding(
        padding: EdgeInsets.only(
          right: direction == Axis.horizontal ? 8 : 0,
          bottom: direction == Axis.vertical ? 8 : 0,
        ),
        child: TagPlayerChip(
          name: players[i],
          color: PlayerColors.forIndex(i),
          score: scores != null && i < scores!.length ? scores![i] : null,
          isActive: true,
          isTurn: i == activeIndex,
          showRemove: allowRemoval,
          onTap: () => onPlayerTap?.call(i),
          onRemove: () => onRemove?.call(i),
          size: chipSize,
        ),
      );
    });

    if (direction == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: chips,
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// TAG ADD PLAYER INPUT - Quick player addition
/// ════════════════════════════════════════════════════════════════════════════

class TagAddPlayerInput extends StatefulWidget {
  /// Called when player is added
  final ValueChanged<String> onAdd;

  /// Maximum players allowed
  final int maxPlayers;

  /// Current player count
  final int currentPlayerCount;

  /// Placeholder text
  final String placeholder;

  /// Auto-focus on mount
  final bool autoFocus;

  const TagAddPlayerInput({
    super.key,
    required this.onAdd,
    this.maxPlayers = 8,
    this.currentPlayerCount = 0,
    this.placeholder = 'Enter player name',
    this.autoFocus = false,
  });

  @override
  State<TagAddPlayerInput> createState() => _TagAddPlayerInputState();
}

class _TagAddPlayerInputState extends State<TagAddPlayerInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool get _canAdd =>
      _controller.text.trim().isNotEmpty &&
      widget.currentPlayerCount < widget.maxPlayers;

  void _addPlayer() {
    if (!_canAdd) return;
    TagHaptics.selection();
    widget.onAdd(_controller.text.trim());
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.maxPlayers - widget.currentPlayerCount;
    final isAtMax = remaining <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autoFocus,
                  enabled: !isAtMax,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: isAtMax ? 'Max players reached' : widget.placeholder,
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _addPlayer(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _canAdd ? _addPlayer : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _canAdd
                          ? PlayerColors.forIndex(widget.currentPlayerCount)
                          : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: _canAdd ? Colors.white : Colors.white38,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isAtMax) ...[
          const SizedBox(height: 8),
          Text(
            '$remaining player${remaining == 1 ? '' : 's'} remaining',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
