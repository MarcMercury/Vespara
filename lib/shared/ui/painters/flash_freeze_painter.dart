import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tag_style_guide.dart';

/// FLASH & FREEZE - "Stop/Go"
/// 
/// A traffic light interpreted as a Neon Sign.
/// Top Circle (Red): A glowing "Stop" square.
/// Bottom Circle (Green): A lightning bolt.
/// The "Tease": A silhouette of a garment falling between them.
/// Animation: Flicker effect switching between Green and Red.
class FlashFreezePainter extends CustomPainter {
  final double flickerProgress; // 0.0 to 1.0 for flicker animation
  final bool isFlashPhase; // true = green/go, false = red/stop
  
  FlashFreezePainter({
    this.flickerProgress = 0.0,
    this.isFlashPhase = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw dark housing background
    _drawHousing(canvas, size);
    
    // Calculate flicker state (broken neon effect)
    final flickerState = _calculateFlicker(flickerProgress);
    
    // Draw top light (Red/Stop)
    _drawStopLight(canvas, size, !isFlashPhase, flickerState);
    
    // Draw bottom light (Green/Go)
    _drawGoLight(canvas, size, isFlashPhase, flickerState);
    
    // Draw falling garment silhouette between lights
    _drawFallingGarment(canvas, size, flickerProgress);
    
    // Draw neon tubing frame
    _drawNeonFrame(canvas, size, flickerState);
  }
  
  double _calculateFlicker(double progress) {
    // Create broken neon flicker effect
    final flickerPattern = math.sin(progress * math.pi * 20) * 
                          math.sin(progress * math.pi * 7) *
                          math.sin(progress * math.pi * 13);
    
    // Mostly stable with occasional flickers
    if (flickerPattern.abs() > 0.7) {
      return 0.3 + math.Random().nextDouble() * 0.4; // Dim flicker
    }
    return 1.0; // Full brightness
  }
  
  void _drawHousing(Canvas canvas, Size size) {
    final housingRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.5,
        height: size.height * 0.85,
      ),
      const Radius.circular(16),
    );
    
    // Dark metallic housing
    final housingPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF2A2A2A),
          const Color(0xFF1A1A1A),
          const Color(0xFF0A0A0A),
        ],
      ).createShader(housingRect.outerRect);
    
    canvas.drawRRect(housingRect, housingPaint);
    
    // Subtle metallic edge
    final edgePaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRRect(housingRect, edgePaint);
  }
  
  void _drawStopLight(Canvas canvas, Size size, bool isActive, double flicker) {
    final center = Offset(size.width / 2, size.height * 0.28);
    final radius = size.width * 0.14;
    
    // Light socket
    final socketPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 1.1, socketPaint);
    
    if (isActive) {
      final activeOpacity = flicker;
      
      // Outer glow
      final glowPaint = Paint()
        ..color = TagColors.crimsonHeat.withOpacity(0.6 * activeOpacity)
        ..maskFilter = TagGlow.intenseGlow;
      
      canvas.drawCircle(center, radius * 1.3, glowPaint);
      
      // Main light
      final lightPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.9 * activeOpacity),
            TagColors.crimsonHeat.withOpacity(0.9 * activeOpacity),
            TagColors.crimsonHeat.withOpacity(0.6 * activeOpacity),
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = TagGlow.neonGlow;
      
      canvas.drawCircle(center, radius, lightPaint);
      
      // Stop symbol (square with rounded corners)
      _drawStopSymbol(canvas, center, radius * 0.5, activeOpacity);
    } else {
      // Inactive dim state
      final dimPaint = Paint()
        ..color = TagColors.crimsonHeat.withOpacity(0.15)
        ..maskFilter = TagGlow.ambientGlow;
      
      canvas.drawCircle(center, radius, dimPaint);
    }
  }
  
  void _drawStopSymbol(Canvas canvas, Offset center, double size, double opacity) {
    final stopRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size, height: size),
      Radius.circular(size * 0.2),
    );
    
    final symbolPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = TagGlow.neonGlow;
    
    canvas.drawRRect(stopRect, symbolPaint);
  }
  
  void _drawGoLight(Canvas canvas, Size size, bool isActive, double flicker) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.width * 0.14;
    
    // Light socket
    final socketPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 1.1, socketPaint);
    
    if (isActive) {
      final activeOpacity = flicker;
      
      // Outer glow
      final glowPaint = Paint()
        ..color = TagColors.toxicGreen.withOpacity(0.6 * activeOpacity)
        ..maskFilter = TagGlow.intenseGlow;
      
      canvas.drawCircle(center, radius * 1.3, glowPaint);
      
      // Main light
      final lightPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.9 * activeOpacity),
            TagColors.toxicGreen.withOpacity(0.9 * activeOpacity),
            TagColors.toxicGreen.withOpacity(0.6 * activeOpacity),
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = TagGlow.neonGlow;
      
      canvas.drawCircle(center, radius, lightPaint);
      
      // Lightning bolt symbol
      _drawLightningBolt(canvas, center, radius * 0.6, activeOpacity);
    } else {
      // Inactive dim state
      final dimPaint = Paint()
        ..color = TagColors.toxicGreen.withOpacity(0.15)
        ..maskFilter = TagGlow.ambientGlow;
      
      canvas.drawCircle(center, radius, dimPaint);
    }
  }
  
  void _drawLightningBolt(Canvas canvas, Offset center, double size, double opacity) {
    final boltPath = Path();
    
    // Lightning bolt shape
    boltPath.moveTo(center.dx + size * 0.1, center.dy - size);
    boltPath.lineTo(center.dx - size * 0.3, center.dy - size * 0.1);
    boltPath.lineTo(center.dx + size * 0.05, center.dy - size * 0.1);
    boltPath.lineTo(center.dx - size * 0.2, center.dy + size);
    boltPath.lineTo(center.dx + size * 0.3, center.dy + size * 0.1);
    boltPath.lineTo(center.dx - size * 0.05, center.dy + size * 0.1);
    boltPath.close();
    
    final boltPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = TagGlow.neonGlow;
    
    canvas.drawPath(boltPath, boltPaint);
  }
  
  void _drawFallingGarment(Canvas canvas, Size size, double progress) {
    // Subtle falling garment silhouette (abstract - like a tie or slip)
    final centerX = size.width / 2;
    final topY = size.height * 0.38;
    final bottomY = size.height * 0.62;
    
    // Animate falling motion
    final fallOffset = math.sin(progress * math.pi * 2) * size.height * 0.02;
    final swayOffset = math.sin(progress * math.pi * 4) * size.width * 0.02;
    
    final garmentPath = Path();
    
    // Abstract tie/ribbon shape
    garmentPath.moveTo(centerX + swayOffset, topY + fallOffset);
    
    // Top knot
    garmentPath.quadraticBezierTo(
      centerX + size.width * 0.04 + swayOffset,
      topY + size.height * 0.02 + fallOffset,
      centerX + swayOffset * 0.5,
      topY + size.height * 0.04 + fallOffset,
    );
    
    // Flowing down
    garmentPath.quadraticBezierTo(
      centerX - size.width * 0.03 - swayOffset,
      (topY + bottomY) / 2 + fallOffset,
      centerX + swayOffset,
      bottomY + fallOffset,
    );
    
    // Return up other side
    garmentPath.quadraticBezierTo(
      centerX + size.width * 0.03 + swayOffset,
      (topY + bottomY) / 2 + fallOffset,
      centerX - swayOffset * 0.5,
      topY + size.height * 0.04 + fallOffset,
    );
    
    garmentPath.close();
    
    // Subtle silhouette
    final garmentPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.15),
        ],
      ).createShader(Rect.fromLTWH(
        centerX - size.width * 0.05,
        topY,
        size.width * 0.1,
        bottomY - topY,
      ))
      ..maskFilter = TagGlow.ambientGlow;
    
    canvas.drawPath(garmentPath, garmentPaint);
  }
  
  void _drawNeonFrame(Canvas canvas, Size size, double flicker) {
    // Neon tubing frame around the housing
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.55,
        height: size.height * 0.9,
      ),
      const Radius.circular(20),
    );
    
    // Gradient neon frame
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TagColors.crimsonHeat.withOpacity(0.6 * flicker),
          TagColors.royalGold.withOpacity(0.4 * flicker),
          TagColors.toxicGreen.withOpacity(0.6 * flicker),
        ],
      ).createShader(frameRect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = TagGlow.neonGlow;
    
    canvas.drawRRect(frameRect, framePaint);
  }
  
  @override
  bool shouldRepaint(FlashFreezePainter oldDelegate) => 
      oldDelegate.flickerProgress != flickerProgress ||
      oldDelegate.isFlashPhase != isFlashPhase;
}

/// Animated widget wrapper for Flash & Freeze
class FlashFreezeIcon extends StatefulWidget {
  final double size;
  
  const FlashFreezeIcon({super.key, this.size = 100});
  
  @override
  State<FlashFreezeIcon> createState() => _FlashFreezeIconState();
}

class _FlashFreezeIconState extends State<FlashFreezeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFlashPhase = true;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Toggle between flash and freeze phases
    _controller.addListener(() {
      if (_controller.value < 0.01 || 
          (_controller.value > 0.49 && _controller.value < 0.51)) {
        setState(() {
          _isFlashPhase = !_isFlashPhase;
        });
      }
    });
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
          painter: FlashFreezePainter(
            flickerProgress: _controller.value,
            isFlashPhase: _isFlashPhase,
          ),
        );
      },
    );
  }
}
