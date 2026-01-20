import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tag_style_guide.dart';

/// LANE OF LUST - "The Timeline"
/// 
/// A perspective road view like the movie Tron.
/// Vanishing point grid on the floor with floating cards
/// hovering above the road at different distances.
/// Retro-wave gradients (Magenta to Orange).
class LaneOfLustPainter extends CustomPainter {
  final double scrollProgress; // 0.0 to 1.0 for road scroll animation
  
  LaneOfLustPainter({this.scrollProgress = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw synthwave sky gradient
    _drawSkyGradient(canvas, size);
    
    // Draw horizon glow
    _drawHorizonGlow(canvas, size);
    
    // Draw perspective grid floor
    _drawPerspectiveGrid(canvas, size, scrollProgress);
    
    // Draw side rails (neon edges)
    _drawSideRails(canvas, size);
    
    // Draw floating cards at different distances
    _drawFloatingCards(canvas, size, scrollProgress);
    
    // Draw sun/destination point
    _drawVanishingPoint(canvas, size);
  }
  
  void _drawSkyGradient(Canvas canvas, Size size) {
    final horizonY = size.height * 0.4;
    
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0A0015), // Deep purple-black
          const Color(0xFF1A0030), // Dark purple
          TagColors.retroMagenta.withOpacity(0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);
  }
  
  void _drawHorizonGlow(Canvas canvas, Size size) {
    final horizonY = size.height * 0.4;
    final center = Offset(size.width / 2, horizonY);
    
    // Warm glow at horizon
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          TagColors.warmOrange.withOpacity(0.6),
          TagColors.retroMagenta.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCenter(
        center: center, 
        width: size.width, 
        height: size.height * 0.4,
      ))
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * 0.8, height: size.height * 0.3),
      glowPaint,
    );
  }
  
  void _drawPerspectiveGrid(Canvas canvas, Size size, double progress) {
    final horizonY = size.height * 0.4;
    final vanishingPoint = Offset(size.width / 2, horizonY);
    
    final gridPaint = TagGlow.createGlowPaint(
      color: TagColors.retroMagenta,
      strokeWidth: 1.0,
      opacity: 0.5,
    );
    
    // Draw perspective lines converging to vanishing point
    final lineCount = 12;
    for (int i = 0; i <= lineCount; i++) {
      final bottomX = (i / lineCount) * size.width;
      
      canvas.drawLine(
        Offset(bottomX, size.height),
        vanishingPoint,
        gridPaint,
      );
    }
    
    // Draw horizontal grid lines with perspective
    final horizontalCount = 8;
    for (int i = 0; i < horizontalCount; i++) {
      // Animate lines scrolling toward viewer
      final baseT = (i / horizontalCount + progress) % 1.0;
      final t = math.pow(baseT, 1.5); // Non-linear for perspective
      
      final y = horizonY + (size.height - horizonY) * t;
      
      // Width expands as lines get closer
      final leftEdge = size.width / 2 - (size.width / 2) * t;
      final rightEdge = size.width / 2 + (size.width / 2) * t;
      
      // Opacity fades at horizon
      final opacity = t.clamp(0.1, 0.8);
      
      final linePaint = TagGlow.createGlowPaint(
        color: TagColors.retroMagenta,
        strokeWidth: 1.0 + t * 2,
        opacity: opacity,
      );
      
      canvas.drawLine(
        Offset(leftEdge, y),
        Offset(rightEdge, y),
        linePaint,
      );
    }
  }
  
  void _drawSideRails(Canvas canvas, Size size) {
    final horizonY = size.height * 0.4;
    final vanishingPoint = Offset(size.width / 2, horizonY);
    
    // Left rail
    final leftRailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          TagColors.warmOrange,
          TagColors.retroMagenta,
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, horizonY, 50, size.height - horizonY))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = TagGlow.neonGlow;
    
    canvas.drawLine(Offset(0, size.height), vanishingPoint, leftRailPaint);
    
    // Right rail
    canvas.drawLine(Offset(size.width, size.height), vanishingPoint, leftRailPaint);
  }
  
  void _drawFloatingCards(Canvas canvas, Size size, double progress) {
    final horizonY = size.height * 0.4;
    final vanishingPoint = Offset(size.width / 2, horizonY);
    
    // Define floating cards at different distances
    final cards = [
      _FloatingCard(distance: 0.3 + progress * 0.2, xOffset: -0.15, rotation: 0.1),
      _FloatingCard(distance: 0.5 + progress * 0.15, xOffset: 0.2, rotation: -0.05),
      _FloatingCard(distance: 0.7 + progress * 0.1, xOffset: -0.08, rotation: 0.02),
      _FloatingCard(distance: 0.85 + progress * 0.05, xOffset: 0.1, rotation: -0.08),
    ];
    
    // Sort by distance (furthest first)
    cards.sort((a, b) => a.distance.compareTo(b.distance));
    
    for (final card in cards) {
      final effectiveDistance = card.distance % 1.0;
      if (effectiveDistance < 0.15) continue; // Skip cards too close to horizon
      
      _drawSingleCard(canvas, size, horizonY, effectiveDistance, card);
    }
  }
  
  void _drawSingleCard(
    Canvas canvas, 
    Size size, 
    double horizonY, 
    double distance, 
    _FloatingCard card,
  ) {
    // Calculate position based on perspective
    final perspectiveScale = math.pow(distance, 1.2);
    final y = horizonY + (size.height - horizonY) * perspectiveScale * 0.7;
    final x = size.width / 2 + card.xOffset * size.width * perspectiveScale;
    
    // Card size scales with distance
    final cardWidth = size.width * 0.15 * perspectiveScale;
    final cardHeight = cardWidth * 1.4;
    
    // Card floats above the grid
    final floatY = y - cardHeight * 0.5;
    
    canvas.save();
    canvas.translate(x, floatY);
    canvas.rotate(card.rotation);
    
    final cardRect = Rect.fromCenter(
      center: Offset.zero,
      width: cardWidth,
      height: cardHeight,
    );
    
    // Card shadow/glow
    final shadowPaint = Paint()
      ..color = TagColors.retroMagenta.withOpacity(0.4)
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect.inflate(4), const Radius.circular(4)),
      shadowPaint,
    );
    
    // Card fill
    final cardPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF2A0040),
          const Color(0xFF1A0025),
        ],
      ).createShader(cardRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(4)),
      cardPaint,
    );
    
    // Card border
    final borderPaint = TagGlow.createGlowPaint(
      color: TagColors.warmOrange,
      strokeWidth: 1.5,
      opacity: 0.8,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(4)),
      borderPaint,
    );
    
    // Abstract content on card (simple glow lines)
    _drawCardContent(canvas, cardRect);
    
    canvas.restore();
  }
  
  void _drawCardContent(Canvas canvas, Rect cardRect) {
    final contentPaint = TagGlow.createGlowPaint(
      color: TagColors.warmOrange,
      strokeWidth: 1.0,
      opacity: 0.5,
    );
    
    // Simple abstract lines suggesting content
    final lineSpacing = cardRect.height / 5;
    for (int i = 1; i < 4; i++) {
      final y = cardRect.top + lineSpacing * i;
      final width = cardRect.width * (0.4 + (i % 2) * 0.3);
      canvas.drawLine(
        Offset(cardRect.left + 8, y),
        Offset(cardRect.left + 8 + width, y),
        contentPaint,
      );
    }
  }
  
  void _drawVanishingPoint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.4;
    final center = Offset(size.width / 2, horizonY);
    
    // Synthwave sun (half circle at horizon)
    final sunPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TagColors.warmOrange,
          TagColors.retroMagenta,
          TagColors.deepPurple,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.12))
      ..maskFilter = TagGlow.neonGlow;
    
    // Clip to show only top half
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawCircle(center, size.width * 0.1, sunPaint);
    
    // Sun lines (horizontal stripes through sun)
    final linePaint = Paint()
      ..color = const Color(0xFF1A0030)
      ..strokeWidth = 2;
    
    for (int i = 1; i < 5; i++) {
      final y = horizonY - size.width * 0.1 + (size.width * 0.02) * i;
      if (y < horizonY) {
        canvas.drawLine(
          Offset(center.dx - size.width * 0.1, y),
          Offset(center.dx + size.width * 0.1, y),
          linePaint,
        );
      }
    }
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(LaneOfLustPainter oldDelegate) => 
      oldDelegate.scrollProgress != scrollProgress;
}

class _FloatingCard {
  final double distance;
  final double xOffset;
  final double rotation;
  
  const _FloatingCard({
    required this.distance,
    required this.xOffset,
    required this.rotation,
  });
}

/// Animated widget wrapper for Lane of Lust
class LaneOfLustIcon extends StatefulWidget {
  final double size;
  
  const LaneOfLustIcon({super.key, this.size = 100});
  
  @override
  State<LaneOfLustIcon> createState() => _LaneOfLustIconState();
}

class _LaneOfLustIconState extends State<LaneOfLustIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: LaneOfLustPainter(scrollProgress: _controller.value),
        );
      },
    );
  }
}
