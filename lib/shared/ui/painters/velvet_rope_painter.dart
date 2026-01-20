import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tag_style_guide.dart';

/// VELVET ROPE - "The Spin"
/// 
/// A circular orbital diagram with gyroscopic motion.
/// Glowing outer ring (The Rope) with intersecting orbital lines inside.
/// Deep Purple background with Gold accents.
class VelvetRopePainter extends CustomPainter {
  final double rotationProgress; // 0.0 to 1.0 for rotation animation
  
  VelvetRopePainter({this.rotationProgress = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;
    
    // Draw deep purple background aura
    _drawBackgroundAura(canvas, center, radius);
    
    // Draw the outer glowing ring (The Rope)
    _drawOuterRing(canvas, center, radius);
    
    // Draw rotating orbital rings (Gyroscope effect)
    _drawOrbitalRings(canvas, center, radius, rotationProgress);
    
    // Draw central nucleus
    _drawNucleus(canvas, center, radius);
    
    // Draw orbital particles
    _drawOrbitalParticles(canvas, center, radius, rotationProgress);
  }
  
  void _drawBackgroundAura(Canvas canvas, Offset center, double radius) {
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          TagColors.deepPurple.withOpacity(0.6),
          TagColors.deepPurple.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5))
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawCircle(center, radius * 1.3, auraPaint);
  }
  
  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    // Main velvet rope ring
    final ropePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          TagColors.royalGold,
          TagColors.deepPurple,
          TagColors.royalGold,
          TagColors.deepPurple,
          TagColors.royalGold,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = TagGlow.neonGlow;
    
    canvas.drawCircle(center, radius, ropePaint);
    
    // Inner glow line
    final innerGlowPaint = TagGlow.createGlowPaint(
      color: TagColors.royalGold,
      strokeWidth: 2,
      opacity: 0.5,
    );
    canvas.drawCircle(center, radius * 0.92, innerGlowPaint);
  }
  
  void _drawOrbitalRings(Canvas canvas, Offset center, double radius, double progress) {
    // Three orbital rings rotating on different axes
    final orbitals = [
      _OrbitalRing(
        tiltX: 0.3,
        tiltY: 0.0,
        rotationSpeed: 1.0,
        radiusFactor: 0.75,
        color: TagColors.royalGold.withOpacity(0.7),
      ),
      _OrbitalRing(
        tiltX: -0.2,
        tiltY: 0.4,
        rotationSpeed: -0.7,
        radiusFactor: 0.6,
        color: TagColors.etherealBlue.withOpacity(0.5),
      ),
      _OrbitalRing(
        tiltX: 0.5,
        tiltY: -0.3,
        rotationSpeed: 0.5,
        radiusFactor: 0.45,
        color: TagColors.royalGold.withOpacity(0.4),
      ),
    ];
    
    for (final orbital in orbitals) {
      _drawSingleOrbital(canvas, center, radius, progress, orbital);
    }
  }
  
  void _drawSingleOrbital(
    Canvas canvas, 
    Offset center, 
    double radius, 
    double progress,
    _OrbitalRing orbital,
  ) {
    final paint = TagGlow.createGlowPaint(
      color: orbital.color,
      strokeWidth: 1.5,
    );
    
    final orbitalRadius = radius * orbital.radiusFactor;
    final rotation = progress * math.pi * 2 * orbital.rotationSpeed;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // Apply 3D-like tilt transformation
    final matrix = Matrix4.identity()
      ..rotateX(orbital.tiltX + math.sin(rotation) * 0.1)
      ..rotateY(orbital.tiltY + math.cos(rotation) * 0.1)
      ..rotateZ(rotation);
    
    // Draw ellipse to simulate 3D tilted ring
    final path = Path();
    for (int i = 0; i <= 360; i += 5) {
      final angle = i * math.pi / 180;
      final x = math.cos(angle) * orbitalRadius;
      final y = math.sin(angle) * orbitalRadius * math.cos(orbital.tiltX);
      
      // Apply rotation
      final rotatedX = x * math.cos(rotation) - y * math.sin(rotation);
      final rotatedY = x * math.sin(rotation) + y * math.cos(rotation);
      
      if (i == 0) {
        path.moveTo(rotatedX, rotatedY);
      } else {
        path.lineTo(rotatedX, rotatedY);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }
  
  void _drawNucleus(Canvas canvas, Offset center, double radius) {
    // Core glow
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          TagColors.royalGold,
          TagColors.deepPurple,
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.25))
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawCircle(center, radius * 0.15, corePaint);
    
    // Bright center point
    final centerDot = Paint()
      ..color = Colors.white
      ..maskFilter = TagGlow.neonGlow;
    canvas.drawCircle(center, 4, centerDot);
  }
  
  void _drawOrbitalParticles(Canvas canvas, Offset center, double radius, double progress) {
    final particlePaint = Paint()
      ..color = TagColors.royalGold
      ..maskFilter = TagGlow.ambientGlow;
    
    // Small particles orbiting at different speeds
    final particles = [
      _Particle(angle: progress * math.pi * 2, radiusFactor: 0.75, size: 4),
      _Particle(angle: progress * math.pi * 2 + math.pi, radiusFactor: 0.75, size: 3),
      _Particle(angle: -progress * math.pi * 1.4, radiusFactor: 0.6, size: 3),
      _Particle(angle: progress * math.pi * 1.2 + math.pi / 3, radiusFactor: 0.45, size: 2),
    ];
    
    for (final particle in particles) {
      final x = center.dx + math.cos(particle.angle) * radius * particle.radiusFactor;
      final y = center.dy + math.sin(particle.angle) * radius * particle.radiusFactor * 0.7;
      canvas.drawCircle(Offset(x, y), particle.size, particlePaint);
    }
  }
  
  @override
  bool shouldRepaint(VelvetRopePainter oldDelegate) => 
      oldDelegate.rotationProgress != rotationProgress;
}

class _OrbitalRing {
  final double tiltX;
  final double tiltY;
  final double rotationSpeed;
  final double radiusFactor;
  final Color color;
  
  const _OrbitalRing({
    required this.tiltX,
    required this.tiltY,
    required this.rotationSpeed,
    required this.radiusFactor,
    required this.color,
  });
}

class _Particle {
  final double angle;
  final double radiusFactor;
  final double size;
  
  const _Particle({
    required this.angle,
    required this.radiusFactor,
    required this.size,
  });
}

/// Animated widget wrapper for Velvet Rope
class VelvetRopeIcon extends StatefulWidget {
  final double size;
  
  const VelvetRopeIcon({super.key, this.size = 100});
  
  @override
  State<VelvetRopeIcon> createState() => _VelvetRopeIconState();
}

class _VelvetRopeIconState extends State<VelvetRopeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
          painter: VelvetRopePainter(rotationProgress: _controller.value),
        );
      },
    );
  }
}
