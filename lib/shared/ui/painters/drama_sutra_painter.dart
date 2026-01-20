import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tag_style_guide.dart';

/// DRAMA-SUTRA - "Constellation Anatomy"
/// 
/// CRITICAL: Do not draw bodies. Draw Star Maps.
/// Connected dots (Stars) and thin lines form the suggestion
/// of two figures embracing. Looks like a Zodiac sign.
/// This abstraction bypasses all NSFW filters while remaining romantic.
class ConstellationPainter extends CustomPainter {
  final double twinkleProgress; // 0.0 to 1.0 for star twinkle animation
  
  ConstellationPainter({this.twinkleProgress = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw cosmic background gradient
    _drawCosmicBackground(canvas, size);
    
    // Draw distant background stars
    _drawBackgroundStars(canvas, size, twinkleProgress);
    
    // Draw the constellation figure (abstract embrace)
    _drawConstellationFigures(canvas, size, twinkleProgress);
    
    // Draw connecting nebula dust
    _drawNebulaDust(canvas, center, size);
  }
  
  void _drawCosmicBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          const Color(0xFF0F0F2A), // Deep navy center
          TagColors.navyVoid,
          const Color(0xFF050510), // Near black edges
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  }
  
  void _drawBackgroundStars(Canvas canvas, Size size, double progress) {
    final random = math.Random(42); // Fixed seed for consistent star positions
    final starCount = 30;
    
    for (int i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      // Twinkle effect - each star twinkles at different phase
      final twinklePhase = (progress * 2 + i * 0.1) % 1.0;
      final twinkle = (math.sin(twinklePhase * math.pi * 2) + 1) / 2;
      final opacity = 0.3 + twinkle * 0.5;
      final starSize = 1.0 + random.nextDouble() * 1.5;
      
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..maskFilter = TagGlow.ambientGlow;
      
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }
  }
  
  void _drawConstellationFigures(Canvas canvas, Size size, double progress) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * 0.4;
    
    // Define constellation points suggesting two abstract figures
    // Figure A (left-leaning) - Abstract form
    final figureA = _createAbstractFigure(
      center: Offset(center.dx - scale * 0.15, center.dy),
      scale: scale,
      leanAngle: -0.15,
    );
    
    // Figure B (right-leaning) - Abstract form  
    final figureB = _createAbstractFigure(
      center: Offset(center.dx + scale * 0.15, center.dy),
      scale: scale,
      leanAngle: 0.15,
      mirror: true,
    );
    
    // Draw connection lines between figures (the embrace)
    _drawEmbraceConnections(canvas, figureA, figureB, progress);
    
    // Draw Figure A constellation
    _drawConstellation(canvas, figureA, TagColors.etherealBlue, progress);
    
    // Draw Figure B constellation
    _drawConstellation(canvas, figureB, TagColors.blushPink, progress);
    
    // Draw heart region where figures meet (abstract)
    _drawHeartRegion(canvas, center, scale, progress);
  }
  
  List<Offset> _createAbstractFigure({
    required Offset center,
    required double scale,
    required double leanAngle,
    bool mirror = false,
  }) {
    // Abstract points suggesting a figure - NOT anatomically explicit
    // Think: zodiac constellation, not human form
    final multiplier = mirror ? -1.0 : 1.0;
    
    final points = <Offset>[
      // Head region (single point - like a star)
      Offset(0.0, -0.8),
      
      // Shoulder region (abstract curve)
      Offset(0.25 * multiplier, -0.5),
      
      // Arm reaching out (toward other figure)
      Offset(0.35 * multiplier, -0.3),
      Offset(0.4 * multiplier, -0.1),
      
      // Core/torso (minimal abstract points)
      Offset(0.15 * multiplier, -0.2),
      Offset(0.1 * multiplier, 0.1),
      
      // Lower abstract form
      Offset(0.2 * multiplier, 0.4),
      Offset(0.1 * multiplier, 0.7),
      Offset(-0.05 * multiplier, 0.9),
    ];
    
    // Apply lean angle and scale
    return points.map((p) {
      final rotatedX = p.dx * math.cos(leanAngle) - p.dy * math.sin(leanAngle);
      final rotatedY = p.dx * math.sin(leanAngle) + p.dy * math.cos(leanAngle);
      return Offset(
        center.dx + rotatedX * scale,
        center.dy + rotatedY * scale,
      );
    }).toList();
  }
  
  void _drawConstellation(Canvas canvas, List<Offset> points, Color color, double progress) {
    // Draw connecting lines (constellation style)
    final linePaint = TagGlow.createGlowPaint(
      color: color,
      strokeWidth: 1.5,
      opacity: 0.6,
    );
    
    // Connect sequential points
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
    
    // Draw some cross-connections for complexity
    if (points.length > 4) {
      canvas.drawLine(points[0], points[2], linePaint..color = color.withOpacity(0.3));
      canvas.drawLine(points[4], points[6], linePaint..color = color.withOpacity(0.3));
    }
    
    // Draw star points at each node
    for (int i = 0; i < points.length; i++) {
      final twinklePhase = (progress * 3 + i * 0.2) % 1.0;
      final twinkle = (math.sin(twinklePhase * math.pi * 2) + 1) / 2;
      
      // Core bright point
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(0.8 + twinkle * 0.2)
        ..maskFilter = TagGlow.neonGlow;
      
      final starSize = 3.0 + twinkle * 2.0;
      canvas.drawCircle(points[i], starSize, starPaint);
      
      // Colored halo
      final haloPaint = Paint()
        ..color = color.withOpacity(0.4 + twinkle * 0.2)
        ..maskFilter = TagGlow.intenseGlow;
      
      canvas.drawCircle(points[i], starSize * 2, haloPaint);
    }
  }
  
  void _drawEmbraceConnections(Canvas canvas, List<Offset> figureA, List<Offset> figureB, double progress) {
    // Subtle lines connecting the two figures (the embrace)
    final embracePaint = TagGlow.createGlowPaint(
      color: Colors.white,
      strokeWidth: 1.0,
      opacity: 0.3,
    );
    
    // Connect reaching arms (points 3 of each figure)
    if (figureA.length > 3 && figureB.length > 3) {
      canvas.drawLine(figureA[3], figureB[3], embracePaint);
    }
    
    // Connect at heart level (points 5)
    if (figureA.length > 5 && figureB.length > 5) {
      final heartLine = Paint()
        ..shader = LinearGradient(
          colors: [
            TagColors.etherealBlue.withOpacity(0.4),
            Colors.white.withOpacity(0.5),
            TagColors.blushPink.withOpacity(0.4),
          ],
        ).createShader(Rect.fromPoints(figureA[5], figureB[5]))
        ..strokeWidth = 1.5
        ..maskFilter = TagGlow.neonGlow;
      
      canvas.drawLine(figureA[5], figureB[5], heartLine);
    }
  }
  
  void _drawHeartRegion(Canvas canvas, Offset center, double scale, double progress) {
    // Subtle pulsing glow at the center where figures meet
    final pulsePhase = (math.sin(progress * math.pi * 2) + 1) / 2;
    final glowRadius = scale * 0.15 * (0.8 + pulsePhase * 0.4);
    
    final heartGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.3 + pulsePhase * 0.2),
          TagColors.blushPink.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius * 2))
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawCircle(
      Offset(center.dx, center.dy - scale * 0.1), 
      glowRadius, 
      heartGlow,
    );
    
    // Central star (heart point)
    final centralStar = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..maskFilter = TagGlow.neonGlow;
    
    canvas.drawCircle(
      Offset(center.dx, center.dy - scale * 0.1),
      4.0 + pulsePhase * 2,
      centralStar,
    );
  }
  
  void _drawNebulaDust(Canvas canvas, Offset center, Size size) {
    // Subtle nebula effect connecting the figures
    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.6,
        colors: [
          TagColors.deepPurple.withOpacity(0.15),
          TagColors.navyVoid.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: center,
        width: size.width * 0.8,
        height: size.height * 0.6,
      ))
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - size.height * 0.05),
        width: size.width * 0.6,
        height: size.height * 0.4,
      ),
      nebulaPaint,
    );
  }
  
  @override
  bool shouldRepaint(ConstellationPainter oldDelegate) => 
      oldDelegate.twinkleProgress != twinkleProgress;
}

/// Animated widget wrapper for Drama-Sutra
class DramaSutraIcon extends StatefulWidget {
  final double size;
  
  const DramaSutraIcon({super.key, this.size = 100});
  
  @override
  State<DramaSutraIcon> createState() => _DramaSutraIconState();
}

class _DramaSutraIconState extends State<DramaSutraIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
          painter: ConstellationPainter(twinkleProgress: _controller.value),
        );
      },
    );
  }
}
