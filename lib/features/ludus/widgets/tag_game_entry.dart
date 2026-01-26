import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/models/tag_rating.dart';
import '../../../core/domain/models/tags_game.dart';
import '../../../core/theme/vespara_icons.dart';
import 'tag_rating_display.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG GAME ENTRY - Standardized Setup Screen for All TAG Games
/// Consistent layout: Header → Ratings → Icon → Title → Tagline → Buttons
/// ════════════════════════════════════════════════════════════════════════════

class TagGameEntry extends StatefulWidget {
  // For games that need extra setup (player count, heat select)

  const TagGameEntry({
    super.key,
    required this.category,
    required this.rating,
    required this.emoji,
    required this.primaryColor,
    this.secondaryColor = Colors.white,
    required this.onPlay,
    this.onHowToPlay,
    this.playButtonLabel,
    this.customContent,
  });
  final GameCategory category;
  final TagRating rating;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onPlay;
  final VoidCallback? onHowToPlay;
  final String? playButtonLabel;
  final Widget? customContent;

  @override
  State<TagGameEntry> createState() => _TagGameEntryState();
}

class _TagGameEntryState extends State<TagGameEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Rating Badges
                  TagRatingDisplay(rating: widget.rating),

                  const SizedBox(height: 32),

                  // Animated Icon
                  _buildAnimatedIcon(),

                  const SizedBox(height: 24),

                  // Title
                  _buildTitle(),

                  const SizedBox(height: 8),

                  // Tagline
                  _buildTagline(),

                  const SizedBox(height: 24),

                  // How to Play Button
                  if (widget.onHowToPlay != null) _buildHowToPlayButton(),

                  const SizedBox(height: 24),

                  // Custom Content (player count, heat select, etc.)
                  if (widget.customContent != null) widget.customContent!,

                  const SizedBox(height: 32),

                  // Play Button
                  _buildPlayButton(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(VesparaIcons.back, color: Colors.white70),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(VesparaIcons.games,
                      size: 14, color: widget.primaryColor),
                  const SizedBox(width: 6),
                  const Text(
                    'TAG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const SizedBox(width: 48), // Balance the back button
          ],
        ),
      );

  Widget _buildAnimatedIcon() => AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) => Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.primaryColor.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor
                    .withOpacity(0.2 + _glowController.value * 0.3),
                blurRadius: 50 + _glowController.value * 30,
                spreadRadius: 15,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 80),
            ),
          ),
        ),
      );

  Widget _buildTitle() => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [widget.primaryColor, widget.secondaryColor],
        ).createShader(bounds),
        child: Text(
          widget.category.displayName.toUpperCase(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      );

  Widget _buildTagline() => Text(
        widget.category.description,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white60,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      );

  Widget _buildHowToPlayButton() => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onHowToPlay?.call();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(VesparaIcons.help, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'How to Play',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPlayButton() => GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          widget.onPlay();
        },
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryColor, widget.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor
                      .withOpacity(0.3 + _glowController.value * 0.2),
                  blurRadius: 20 + _glowController.value * 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(VesparaIcons.play, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.playButtonLabel ?? 'PLAY',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Standard dark background for TAG games
class TagGameBackground extends StatelessWidget {
  const TagGameBackground({
    super.key,
    required this.primaryColor,
    required this.child,
  });
  final Color primaryColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              const Color(0xFF1A1523),
              const Color(0xFF0D0D12),
            ],
          ),
        ),
        child: child,
      );
}
