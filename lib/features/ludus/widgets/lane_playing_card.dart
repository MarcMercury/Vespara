import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/providers/lane_of_lust_provider.dart';
import 'lane_card_illustrations.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// LANE OF LUST - Enhanced Playing Card Widget
/// Luxurious card design with flip animation and better readability
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// LANE CARD — SMALL (used in the player's lane timeline)
// ═══════════════════════════════════════════════════════════════════════════

class LaneCardSmall extends StatelessWidget {
  final LaneCard card;
  final bool highlighted;

  const LaneCardSmall({
    super.key,
    required this.card,
    this.highlighted = false,
  });

  static const double cardWidth = 72;
  static const double cardHeight = 108;

  @override
  Widget build(BuildContext context) {
    final color = card.indexColor;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        border: Border.all(
          color: highlighted ? const Color(0xFFFFD700) : color.withOpacity(0.6),
          width: highlighted ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(1, 3),
          ),
          if (highlighted)
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          children: [
            // Subtle gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    color.withOpacity(0.06),
                  ],
                ),
              ),
            ),

            // Top-left: desire index badge
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${card.desireIndex}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),

            // Center illustration
            Positioned.fill(
              top: 22,
              bottom: 28,
              child: Center(
                child: LaneCardIllustration(
                  illustration: getIllustrationForCard(card.text),
                  color: color.withOpacity(0.5),
                  size: 28,
                ),
              ),
            ),

            // Bottom: card text
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  card.text,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Gloss
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(9)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MYSTERY CARD — LARGE (the face-up/face-down card in play)
// ═══════════════════════════════════════════════════════════════════════════

class LaneMysteryCard extends StatelessWidget {
  final LaneCard card;
  final bool isRevealed;

  const LaneMysteryCard({
    super.key,
    required this.card,
    required this.isRevealed,
  });

  static const double cardWidth = 160;
  static const double cardHeight = 230;

  @override
  Widget build(BuildContext context) {
    return isRevealed ? _buildFrontFace() : _buildMysteryFace();
  }

  Widget _buildMysteryFace() {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(2, 6),
          ),
          BoxShadow(
            color: const Color(0xFF9B59B6).withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Dark gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6C3483),
                    Color(0xFF4A235A),
                    Color(0xFF6C3483),
                  ],
                ),
              ),
            ),

            // Diamond pattern
            CustomPaint(
              size: const Size(cardWidth, cardHeight),
              painter: _DiamondPatternPainter(),
            ),

            // Inner border
            Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 2,
                ),
              ),
            ),

            // Scenario text in the middle
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Question mark badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF9B59B6).withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card text (visible even unrevealed)
                    Text(
                      card.text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),

                    // "Where does this go?" label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Where does this go?',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Gloss overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: cardHeight * 0.3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontFace() {
    final color = card.indexColor;
    final illustration = getIllustrationForCard(card.text);

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.7), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(2, 6),
          ),
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    color.withOpacity(0.06),
                    color.withOpacity(0.12),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  // Top: desire index
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${card.desireIndex}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Illustration
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.08),
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: LaneCardIllustration(
                          illustration: illustration,
                          color: color.withOpacity(0.6),
                          size: 48,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Card text
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          card.text,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color.withOpacity(0.85),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          card.category.color.withOpacity(0.15),
                          card.category.color.withOpacity(0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: card.category.color.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      card.category.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: card.category.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner decoration top-right
            Positioned(
              top: 6,
              right: 6,
              child: _CornerDiamond(color: color.withOpacity(0.2), size: 16),
            ),
            // Corner decoration bottom-left
            Positioned(
              bottom: 6,
              left: 6,
              child: Transform.rotate(
                angle: pi,
                child:
                    _CornerDiamond(color: color.withOpacity(0.2), size: 16),
              ),
            ),

            // Gloss
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: cardHeight * 0.3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FLIP CARD — wraps mystery card with 3D flip animation
// ═══════════════════════════════════════════════════════════════════════════

class LaneFlipCard extends StatefulWidget {
  final LaneCard card;
  final bool isRevealed;

  const LaneFlipCard({
    super.key,
    required this.card,
    required this.isRevealed,
  });

  @override
  State<LaneFlipCard> createState() => _LaneFlipCardState();
}

class _LaneFlipCardState extends State<LaneFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    _showFront = widget.isRevealed;
    if (widget.isRevealed) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant LaneFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _flipController.forward();
      // At halfway point, switch to front face
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showFront = true);
      });
    } else if (!widget.isRevealed && oldWidget.isRevealed) {
      _flipController.reverse();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showFront = false);
      });
    }
    // If card changed (new mystery card), reset
    if (widget.card.id != oldWidget.card.id) {
      _flipController.value = widget.isRevealed ? 1.0 : 0.0;
      _showFront = widget.isRevealed;
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: _showFront
              ? LaneMysteryCard(card: widget.card, isRevealed: true)
              : LaneMysteryCard(card: widget.card, isRevealed: false),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DROP ZONE — the slot where a card can be placed
// ═══════════════════════════════════════════════════════════════════════════

class LaneDropSlot extends StatelessWidget {
  final bool isSelected;
  final bool isActive;
  final VoidCallback? onTap;

  const LaneDropSlot({
    super.key,
    this.isSelected = false,
    this.isActive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox(width: 6);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: isSelected ? LaneCardSmall.cardWidth + 4 : 36,
        height: LaneCardSmall.cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2ECC71).withOpacity(0.35),
                    const Color(0xFF2ECC71).withOpacity(0.15),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(isSelected ? 10 : 8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2ECC71)
                : Colors.white.withOpacity(0.25),
            width: isSelected ? 2.5 : 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isSelected
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: const Color(0xFF2ECC71).withOpacity(0.8),
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HERE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2ECC71).withOpacity(0.9),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                )
              : Icon(
                  Icons.add_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 18,
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

class _CornerDiamond extends StatelessWidget {
  final Color color;
  final double size;

  const _CornerDiamond({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DiamondPainter(color: color)),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  final Color color;
  _DiamondPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    canvas.drawPath(path, paint);

    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.15, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiamondPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 20.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final path = Path()
          ..moveTo(x, y - 5)
          ..lineTo(x + 5, y)
          ..lineTo(x, y + 5)
          ..lineTo(x - 5, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Keep old name for backward compatibility — delegates to new widget
class LanePlayingCard extends StatelessWidget {
  final LaneCard card;
  final bool isRevealed;
  final bool isSmall;
  final bool isDragging;
  final bool showGlow;

  const LanePlayingCard({
    super.key,
    required this.card,
    this.isRevealed = true,
    this.isSmall = false,
    this.isDragging = false,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isSmall) {
      return LaneCardSmall(card: card);
    }
    return LaneMysteryCard(card: card, isRevealed: isRevealed);
  }
}
