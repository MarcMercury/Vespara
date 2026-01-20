import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tag_style_guide.dart';

/// PATH OF PLEASURE - "The Heatmap"
/// 
/// Two sine waves that flow horizontally representing two players.
/// Wave 1 (Blue): Player A
/// Wave 2 (Pink): Player B  
/// At the center, waves intertwine and merge into a White/Gold node.
/// Symbolism: Connection through frequency.
class PathOfPleasurePainter extends CustomPainter {
  final double waveProgress; // 0.0 to 1.0 for wave animation
  
  PathOfPleasurePainter({this.waveProgress = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw background aura at merge point
    _drawMergeAura(canvas, center, size);
    
    // Draw Wave A (Blue - flows from left)
    _drawWaveA(canvas, size, waveProgress);
    
    // Draw Wave B (Pink - flows from right)  
    _drawWaveB(canvas, size, waveProgress);
    
    // Draw the Golden Zone merge node at center
    _drawGoldenZone(canvas, center, size);
    
    // Draw harmonic particles
    _drawHarmonicParticles(canvas, center, size, waveProgress);
  }
  
  void _drawMergeAura(Canvas canvas, Offset center, Size size) {
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          TagColors.royalGold.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.3))
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawCircle(center, size.width * 0.25, auraPaint);
  }
  
  void _drawWaveA(Canvas canvas, Size size, double progress) {
    final wavePath = Path();
    final amplitude = size.height * 0.15;
    final centerY = size.height / 2;
    final phaseShift = progress * math.pi * 4;
    
    // Create wave from left side
    wavePath.moveTo(0, centerY);
    
    for (double x = 0; x <= size.width; x += 2) {
      // Wave converges toward center
      final normalizedX = x / size.width;
      final distanceFromCenter = (normalizedX - 0.5).abs();
      final convergeFactor = 1.0 - math.pow(1.0 - distanceFromCenter, 2);
      
      // Sine wave with phase animation
      final waveY = math.sin((x / size.width) * math.pi * 3 + phaseShift) 
                    * amplitude * convergeFactor;
      
      // Approach center line as we get closer to middle
      final approachCenter = normalizedX < 0.5 
          ? centerY + waveY 
          : centerY + waveY * (1.0 - (normalizedX - 0.5) * 2).clamp(0.0, 1.0);
      
      wavePath.lineTo(x, approachCenter);
    }
    
    // Gradient paint from blue edge to white center
    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          TagColors.etherealBlue,
          TagColors.etherealBlue,
          Colors.white.withOpacity(0.8),
        ],
        stops: const [0.0, 0.4, 0.5],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = TagGlow.neonGlow;
    
    canvas.drawPath(wavePath, wavePaint);
    
    // Draw subtle trail
    final trailPaint = Paint()
      ..color = TagColors.etherealBlue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawPath(wavePath, trailPaint);
  }
  
  void _drawWaveB(Canvas canvas, Size size, double progress) {
    final wavePath = Path();
    final amplitude = size.height * 0.15;
    final centerY = size.height / 2;
    final phaseShift = -progress * math.pi * 4; // Opposite phase
    
    // Create wave from right side (inverted sine)
    wavePath.moveTo(size.width, centerY);
    
    for (double x = size.width; x >= 0; x -= 2) {
      final normalizedX = x / size.width;
      final distanceFromCenter = (normalizedX - 0.5).abs();
      final convergeFactor = 1.0 - math.pow(1.0 - distanceFromCenter, 2);
      
      // Inverted sine wave (complementary to Wave A)
      final waveY = math.sin((x / size.width) * math.pi * 3 + phaseShift + math.pi) 
                    * amplitude * convergeFactor;
      
      final approachCenter = normalizedX > 0.5 
          ? centerY + waveY 
          : centerY + waveY * (normalizedX * 2).clamp(0.0, 1.0);
      
      wavePath.lineTo(x, approachCenter);
    }
    
    // Gradient paint from pink edge to white center
    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.8),
          TagColors.blushPink,
          TagColors.blushPink,
        ],
        stops: const [0.5, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = TagGlow.neonGlow;
    
    canvas.drawPath(wavePath, wavePaint);
    
    // Draw subtle trail
    final trailPaint = Paint()
      ..color = TagColors.blushPink.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawPath(wavePath, trailPaint);
  }
  
  void _drawGoldenZone(Canvas canvas, Offset center, Size size) {
    // Pulsing golden merge point
    final nodeRadius = size.width * 0.08;
    
    // Outer glow ring
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          TagColors.royalGold,
          TagColors.royalGold.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: nodeRadius * 2))
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawCircle(center, nodeRadius * 1.5, glowPaint);
    
    // Core bright point
    final corePaint = Paint()
      ..color = Colors.white
      ..maskFilter = TagGlow.neonGlow;
    
    canvas.drawCircle(center, nodeRadius * 0.5, corePaint);
    
    // Infinity symbol suggestion (connection loop)
    _drawInfinityHint(canvas, center, nodeRadius);
  }
  
  void _drawInfinityHint(Canvas canvas, Offset center, double radius) {
    final infinityPaint = TagGlow.createGlowPaint(
      color: TagColors.royalGold,
      strokeWidth: 2.0,
      opacity: 0.6,
    );
    
    final path = Path();
    final loopSize = radius * 1.2;
    
    // Simple infinity/figure-8 suggestion
    path.moveTo(center.dx, center.dy);
    path.cubicTo(
      center.dx + loopSize, center.dy - loopSize * 0.5,
      center.dx + loopSize, center.dy + loopSize * 0.5,
      center.dx, center.dy,
    );
    path.cubicTo(
      center.dx - loopSize, center.dy - loopSize * 0.5,
      center.dx - loopSize, center.dy + loopSize * 0.5,
      center.dx, center.dy,
    );
    
    canvas.drawPath(path, infinityPaint);
  }
  
  void _drawHarmonicParticles(Canvas canvas, Offset center, Size size, double progress) {
    final particlePaint = Paint()
      ..maskFilter = TagGlow.ambientGlow;
    
    // Floating harmonic dots along the wave paths
    final particleCount = 6;
    for (int i = 0; i < particleCount; i++) {
      final t = (i / particleCount + progress) % 1.0;
      final x = t * size.width;
      final normalizedX = t;
      
      // Determine if particle is on blue or pink wave
      final isBlueWave = i % 2 == 0;
      particlePaint.color = isBlueWave 
          ? TagColors.etherealBlue.withOpacity(0.8)
          : TagColors.blushPink.withOpacity(0.8);
      
      // Calculate Y position on wave
      final amplitude = size.height * 0.15;
      final distanceFromCenter = (normalizedX - 0.5).abs();
      final convergeFactor = 1.0 - math.pow(1.0 - distanceFromCenter, 2);
      final phaseShift = (isBlueWave ? 1 : -1) * progress * math.pi * 4;
      final waveY = math.sin(normalizedX * math.pi * 3 + phaseShift) 
                    * amplitude * convergeFactor;
      
      final y = center.dy + waveY * (isBlueWave ? 1 : -1);
      
      canvas.drawCircle(Offset(x, y), 3, particlePaint);
    }
  }
  
  @override
  bool shouldRepaint(PathOfPleasurePainter oldDelegate) => 
      oldDelegate.waveProgress != waveProgress;
}

/// Animated widget wrapper for Path of Pleasure
class PathOfPleasureIcon extends StatefulWidget {
  final double size;
  
  const PathOfPleasureIcon({super.key, this.size = 100});
  
  @override
  State<PathOfPleasureIcon> createState() => _PathOfPleasureIconState();
}

class _PathOfPleasureIconState extends State<PathOfPleasureIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
          painter: PathOfPleasurePainter(waveProgress: _controller.value),
        );
      },
    );
  }
}
