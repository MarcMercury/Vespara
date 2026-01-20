import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tag_style_guide.dart';

/// ICE BREAKERS - "Shattering Tension"
/// 
/// A crystalline, geometric heart shape made of sharp shards.
/// The shards "breathe" (expand/contract) on a loop.
/// Abstract polygon structure suggesting a frozen core waiting to be cracked.
class IceBreakersPainter extends CustomPainter {
  final double breathProgress; // 0.0 to 1.0 for breathing animation
  
  IceBreakersPainter({this.breathProgress = 0.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;
    
    // Breathing scale factor (subtle expand/contract)
    final breathScale = 1.0 + (math.sin(breathProgress * math.pi * 2) * 0.05);
    
    // Draw the background glow aura
    _drawAura(canvas, center, radius * breathScale);
    
    // Draw crystalline shards forming abstract heart shape
    _drawCrystallineCore(canvas, center, radius * breathScale);
    
    // Draw the sharp shard fragments
    _drawShards(canvas, center, radius * breathScale, breathProgress);
    
    // Draw glowing nodes at intersection points
    _drawGlowNodes(canvas, center, radius * breathScale);
  }
  
  void _drawAura(Canvas canvas, Offset center, double radius) {
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          TagColors.etherealBlue.withOpacity(0.3),
          TagColors.etherealBlue.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5))
      ..maskFilter = TagGlow.intenseGlow;
    
    canvas.drawCircle(center, radius * 1.2, auraPaint);
  }
  
  void _drawCrystallineCore(Canvas canvas, Offset center, double radius) {
    final corePath = Path();
    
    // Create abstract heart-like polygon from sharp geometric shapes
    // Top-left shard cluster
    corePath.moveTo(center.dx, center.dy - radius * 0.8);
    corePath.lineTo(center.dx - radius * 0.5, center.dy - radius * 0.3);
    corePath.lineTo(center.dx - radius * 0.7, center.dy);
    corePath.lineTo(center.dx - radius * 0.4, center.dy + radius * 0.2);
    
    // Bottom point (heart tip suggestion)
    corePath.lineTo(center.dx, center.dy + radius * 0.9);
    
    // Right side mirror
    corePath.lineTo(center.dx + radius * 0.4, center.dy + radius * 0.2);
    corePath.lineTo(center.dx + radius * 0.7, center.dy);
    corePath.lineTo(center.dx + radius * 0.5, center.dy - radius * 0.3);
    corePath.close();
    
    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: TagGradients.ice,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill
      ..maskFilter = TagGlow.softGlow;
    
    canvas.drawPath(corePath, fillPaint);
    
    // Glowing edge
    final edgePaint = TagGlow.createGlowPaint(
      color: TagColors.etherealBlue,
      strokeWidth: 2.0,
    );
    canvas.drawPath(corePath, edgePaint);
  }
  
  void _drawShards(Canvas canvas, Offset center, double radius, double progress) {
    final shardPaint = TagGlow.createGlowPaint(
      color: TagColors.etherealBlue,
      strokeWidth: 1.5,
      opacity: 0.6,
    );
    
    // Floating shard fragments around the core
    final shardCount = 8;
    for (int i = 0; i < shardCount; i++) {
      final angle = (i / shardCount) * math.pi * 2 + progress * 0.5;
      final distance = radius * (0.9 + math.sin(progress * math.pi * 2 + i) * 0.1);
      
      final shardCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      
      // Draw small triangular shard
      final shardPath = Path();
      final shardSize = radius * 0.15;
      shardPath.moveTo(shardCenter.dx, shardCenter.dy - shardSize);
      shardPath.lineTo(shardCenter.dx - shardSize * 0.6, shardCenter.dy + shardSize * 0.5);
      shardPath.lineTo(shardCenter.dx + shardSize * 0.6, shardCenter.dy + shardSize * 0.5);
      shardPath.close();
      
      // Rotate shard
      canvas.save();
      canvas.translate(shardCenter.dx, shardCenter.dy);
      canvas.rotate(angle + math.pi / 4);
      canvas.translate(-shardCenter.dx, -shardCenter.dy);
      canvas.drawPath(shardPath, shardPaint);
      canvas.restore();
    }
  }
  
  void _drawGlowNodes(Canvas canvas, Offset center, double radius) {
    final nodePaint = Paint()
      ..color = Colors.white
      ..maskFilter = TagGlow.neonGlow;
    
    // Key intersection points that glow
    final nodes = [
      Offset(center.dx, center.dy - radius * 0.8), // Top
      Offset(center.dx - radius * 0.5, center.dy - radius * 0.3), // Top-left
      Offset(center.dx + radius * 0.5, center.dy - radius * 0.3), // Top-right
      Offset(center.dx, center.dy + radius * 0.9), // Bottom tip
      center, // Core center
    ];
    
    for (final node in nodes) {
      canvas.drawCircle(node, 3, nodePaint);
    }
  }
  
  @override
  bool shouldRepaint(IceBreakersPainter oldDelegate) => 
      oldDelegate.breathProgress != breathProgress;
}

/// Animated widget wrapper for Ice Breakers
class IceBreakersIcon extends StatefulWidget {
  final double size;
  
  const IceBreakersIcon({super.key, this.size = 100});
  
  @override
  State<IceBreakersIcon> createState() => _IceBreakersIconState();
}

class _IceBreakersIconState extends State<IceBreakersIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
          painter: IceBreakersPainter(breathProgress: _controller.value),
        );
      },
    );
  }
}
