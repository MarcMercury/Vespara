import 'package:flutter/material.dart';

import '../../../core/providers/lane_of_lust_provider.dart';
import 'lane_card_illustrations.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// LANE OF LUST - Enhanced Playing Card Widget
/// Luxurious, sexy, alluring card design with smooth edges and illustrations
/// ════════════════════════════════════════════════════════════════════════════

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

  // Card dimensions
  double get width => isSmall ? 95 : (isDragging ? 155 : 175);
  double get height => isSmall ? 140 : (isDragging ? 225 : 250);
  double get borderRadius => isSmall ? 12 : 16;
  double get innerRadius => isSmall ? 9 : 13;

  @override
  Widget build(BuildContext context) {
    final displayColor = isRevealed ? card.indexColor : const Color(0xFF9B59B6);
    final illustration = getIllustrationForCard(card.text);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Outer shadow for depth
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: isDragging ? 20 : 12,
            offset: Offset(isDragging ? 4 : 2, isDragging ? 8 : 4),
            spreadRadius: isDragging ? 2 : 0,
          ),
          // Colored glow
          if (showGlow)
            BoxShadow(
              color: displayColor.withOpacity(isRevealed ? 0.35 : 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Main card background with gradient
            _buildCardBackground(displayColor),
            
            // Decorative border
            _buildDecorativeBorder(displayColor),
            
            // Inner content area
            _buildInnerContent(displayColor, illustration),
            
            // Card corners with suit-like symbols
            _buildCornerDecorations(displayColor),
            
            // Glossy overlay
            _buildGlossOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBackground(Color displayColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildDecorativeBorder(Color displayColor) {
    return Container(
      margin: EdgeInsets.all(isSmall ? 2 : 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(innerRadius),
        border: Border.all(
          color: displayColor.withOpacity(0.8),
          width: isSmall ? 2 : 3,
        ),
      ),
    );
  }

  Widget _buildInnerContent(Color displayColor, LaneIllustration illustration) {
    return Container(
      margin: EdgeInsets.all(isSmall ? 4 : 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(innerRadius - 2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isRevealed
              ? [
                  displayColor.withOpacity(0.08),
                  displayColor.withOpacity(0.03),
                  displayColor.withOpacity(0.08),
                ]
              : [
                  const Color(0xFF9B59B6).withOpacity(0.1),
                  const Color(0xFF6C3483).withOpacity(0.05),
                  const Color(0xFF9B59B6).withOpacity(0.1),
                ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 6 : 10),
        child: Column(
          children: [
            // Top: Index badge
            _buildIndexBadge(displayColor),
            
            SizedBox(height: isSmall ? 4 : 8),
            
            // Center: Illustration
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(isSmall ? 4 : 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: displayColor.withOpacity(0.08),
                    border: Border.all(
                      color: displayColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: LaneCardIllustration(
                    illustration: illustration,
                    color: displayColor.withOpacity(0.7),
                    size: isSmall ? 32 : 52,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: isSmall ? 2 : 6),
            
            // Card text
            Expanded(
              flex: 2,
              child: _buildCardText(displayColor),
            ),
            
            SizedBox(height: isSmall ? 2 : 4),
            
            // Category badge
            _buildCategoryBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexBadge(Color displayColor) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 6 : 10,
          vertical: isSmall ? 3 : 5,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRevealed
                ? [displayColor, displayColor.withOpacity(0.8)]
                : [const Color(0xFF9B59B6), const Color(0xFF6C3483)],
          ),
          borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          isRevealed ? '${card.desireIndex}' : '?',
          style: TextStyle(
            fontSize: isSmall ? 14 : 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardText(Color displayColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 2 : 4,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: displayColor.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          card.text,
          style: TextStyle(
            fontSize: isSmall ? 7 : 11,
            fontWeight: FontWeight.w600,
            color: isRevealed 
                ? displayColor.withOpacity(0.85) 
                : const Color(0xFF9B59B6).withOpacity(0.85),
            height: 1.2,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: isSmall ? 3 : 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            card.category.color.withOpacity(0.15),
            card.category.color.withOpacity(0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
        border: Border.all(
          color: card.category.color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        card.category.displayName,
        style: TextStyle(
          fontSize: isSmall ? 7 : 10,
          fontWeight: FontWeight.w700,
          color: card.category.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCornerDecorations(Color displayColor) {
    final cornerWidget = _CornerDecoration(
      color: displayColor.withOpacity(0.25),
      size: isSmall ? 14 : 20,
    );

    return Stack(
      children: [
        // Top right corner
        Positioned(
          top: isSmall ? 6 : 8,
          right: isSmall ? 6 : 8,
          child: cornerWidget,
        ),
        // Bottom left corner (rotated)
        Positioned(
          bottom: isSmall ? 6 : 8,
          left: isSmall ? 6 : 8,
          child: Transform.rotate(
            angle: 3.14159, // 180 degrees
            child: cornerWidget,
          ),
        ),
      ],
    );
  }

  Widget _buildGlossOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height * 0.35,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// Corner decoration that looks like a playing card suit
class _CornerDecoration extends StatelessWidget {
  final Color color;
  final double size;

  const _CornerDecoration({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Diamond shape
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();

    canvas.drawPath(path, paint);

    // Small dot in center
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mystery card back design (for unrevealed cards or deck)
class LaneCardBack extends StatelessWidget {
  final double width;
  final double height;
  final bool showGlow;

  const LaneCardBack({
    super.key,
    this.width = 175,
    this.height = 250,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    const mysteryColor = Color(0xFF9B59B6);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(2, 4),
          ),
          if (showGlow)
            BoxShadow(
              color: mysteryColor.withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Dark purple gradient background
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
            
            // Pattern overlay
            _buildPatternOverlay(),
            
            // Center mystery symbol
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      mysteryColor.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Text(
                  '🔥',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ),
            
            // Border
            Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 2,
                ),
              ),
            ),
            
            // Gloss
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: height * 0.3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
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

  Widget _buildPatternOverlay() {
    return CustomPaint(
      size: Size(width, height),
      painter: _PatternPainter(),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Diamond pattern
    const spacing = 20.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final path = Path();
        path.moveTo(x, y - 5);
        path.lineTo(x + 5, y);
        path.lineTo(x, y + 5);
        path.lineTo(x - 5, y);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
