import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models/content_rating.dart';
import '../utils/haptic_patterns.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG GAME CARD - Shared Card Widget
/// ════════════════════════════════════════════════════════════════════════════
///
/// A reusable animated card widget for displaying game prompts, questions,
/// and actions across all TAG games.

class TagGameCard extends StatefulWidget {
  /// Main content/prompt text
  final String content;

  /// Optional title/category at the top
  final String? title;

  /// Optional subtitle/instruction below content
  final String? subtitle;

  /// Card background color
  final Color backgroundColor;

  /// Text color (auto-calculated from background if null)
  final Color? textColor;

  /// Accent color for decorations
  final Color? accentColor;

  /// Icon to display (optional)
  final IconData? icon;

  /// Whether to show flip animation on tap
  final bool flipOnTap;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Callback when card flip completes
  final VoidCallback? onFlipComplete;

  /// Whether card starts face down (for flip reveal)
  final bool startFaceDown;

  /// Content rating badge to display
  final ContentRating? contentRating;

  /// Optional player name for attribution
  final String? playerName;

  /// Optional player color
  final Color? playerColor;

  /// Border radius
  final double borderRadius;

  /// Card elevation
  final double elevation;

  /// Card padding
  final EdgeInsets padding;

  /// Whether to show shimmer loading effect
  final bool isLoading;

  const TagGameCard({
    super.key,
    required this.content,
    this.title,
    this.subtitle,
    required this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.icon,
    this.flipOnTap = false,
    this.onTap,
    this.onFlipComplete,
    this.startFaceDown = false,
    this.contentRating,
    this.playerName,
    this.playerColor,
    this.borderRadius = 24,
    this.elevation = 8,
    this.padding = const EdgeInsets.all(24),
    this.isLoading = false,
  });

  @override
  State<TagGameCard> createState() => _TagGameCardState();
}

class _TagGameCardState extends State<TagGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFaceUp = true;

  @override
  void initState() {
    super.initState();
    _isFaceUp = !widget.startFaceDown;

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutBack,
    ));

    if (widget.startFaceDown) {
      _flipController.value = 0;
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.flipOnTap && !_isFaceUp) {
      _flipCard();
    }
    widget.onTap?.call();
  }

  void _flipCard() {
    TagHaptics.cardFlip();
    _flipController.forward().then((_) {
      setState(() => _isFaceUp = true);
      widget.onFlipComplete?.call();
    });
  }

  /// Flip the card programmatically
  void flip() => _flipCard();

  Color get _effectiveTextColor {
    if (widget.textColor != null) return widget.textColor!;
    // Calculate contrast
    final luminance = widget.backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingCard();
    }

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        final showFront = angle < math.pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: showFront ? _buildCardBack() : _buildCardFront(),
        );
      },
    );
  }

  Widget _buildCardFront() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withOpacity(0.3),
                blurRadius: widget.elevation * 2,
                offset: Offset(0, widget.elevation),
              ),
            ],
          ),
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row with optional rating badge
              if (widget.title != null || widget.contentRating != null)
                _buildTitleRow(),

              // Icon
              if (widget.icon != null) ...[
                const SizedBox(height: 16),
                Icon(
                  widget.icon,
                  size: 48,
                  color: widget.accentColor ?? _effectiveTextColor.withOpacity(0.7),
                ),
              ],

              // Main content
              const Spacer(),
              Text(
                widget.content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _effectiveTextColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const Spacer(),

              // Subtitle
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _effectiveTextColor.withOpacity(0.7),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),

              // Player attribution
              if (widget.playerName != null) ...[
                const SizedBox(height: 12),
                _buildPlayerChip(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.backgroundColor.withOpacity(0.8),
              widget.backgroundColor,
              widget.backgroundColor.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: widget.backgroundColor.withOpacity(0.3),
              blurRadius: widget.elevation * 2,
              offset: Offset(0, widget.elevation),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 64,
                color: _effectiveTextColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap to reveal',
                style: TextStyle(
                  color: _effectiveTextColor.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.title != null)
          Expanded(
            child: Text(
              widget.title!.toUpperCase(),
              style: TextStyle(
                color: _effectiveTextColor.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        if (widget.contentRating != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.contentRating!.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.contentRating!.color.withOpacity(0.5),
              ),
            ),
            child: Text(
              widget.contentRating!.displayName,
              style: TextStyle(
                color: widget.contentRating!.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (widget.playerColor ?? Colors.white).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.playerColor ?? _effectiveTextColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.playerName!,
            style: TextStyle(
              color: _effectiveTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShimmerBox(width: 100, height: 16),
          const SizedBox(height: 24),
          _ShimmerBox(width: double.infinity, height: 24),
          const SizedBox(height: 12),
          _ShimmerBox(width: 200, height: 24),
          const SizedBox(height: 12),
          _ShimmerBox(width: 150, height: 24),
        ],
      ),
    );
  }
}

/// Shimmer loading box
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerBox({required this.width, required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 2, 0),
              end: Alignment(_controller.value * 2, 0),
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
        );
      },
    );
  }
}
