import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/vespara_gradients.dart';

/// ╔═══════════════════════════════════════════════════════════════════════════╗
/// ║              VESPARA ANIMATED BACKGROUND                                   ║
/// ║  Slow-moving aurora mesh that breathes life into every screen              ║
/// ╚═══════════════════════════════════════════════════════════════════════════╝

class VesparaAnimatedBackground extends StatefulWidget {
  const VesparaAnimatedBackground({
    super.key,
    required this.child,
    this.enableAurora = true,
    this.enableParticles = true,
    this.particleCount = 25,
    this.auroraIntensity = 1.0,
  });

  final Widget child;
  final bool enableAurora;
  final bool enableParticles;
  final int particleCount;
  final double auroraIntensity;

  @override
  State<VesparaAnimatedBackground> createState() =>
      _VesparaAnimatedBackgroundState();
}

class _VesparaAnimatedBackgroundState extends State<VesparaAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _auroraController;
  late AnimationController _particleController;
  late List<_FloatingParticle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _particles = List.generate(
      widget.particleCount,
      (_) => _FloatingParticle.random(_random),
    );
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient background
        Container(
          decoration: const BoxDecoration(gradient: VesparaGradients.background),
        ),

        // Aurora blobs
        if (widget.enableAurora)
          AnimatedBuilder(
            animation: _auroraController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _AuroraPainter(
                progress: _auroraController.value,
                intensity: widget.auroraIntensity,
              ),
            ),
          ),

        // Floating particles (stars)
        if (widget.enableParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ParticlePainter(
                particles: _particles,
                progress: _particleController.value,
              ),
            ),
          ),

        // Child content
        widget.child,
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// AURORA PAINTER — Soft, drifting color blobs
/// ═══════════════════════════════════════════════════════════════════════════

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.progress,
    this.intensity = 1.0,
  });

  final double progress;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      _AuroraBlob(
        center: Offset(
          size.width * (0.3 + 0.2 * math.sin(progress * 2 * math.pi)),
          size.height * (0.2 + 0.1 * math.cos(progress * 2 * math.pi * 0.7)),
        ),
        radius: size.width * 0.5,
        color: const Color(0xFFBFA6D8), // lavender
        opacity: 0.06 * intensity,
      ),
      _AuroraBlob(
        center: Offset(
          size.width * (0.7 + 0.15 * math.cos(progress * 2 * math.pi * 1.3)),
          size.height * (0.5 + 0.2 * math.sin(progress * 2 * math.pi * 0.5)),
        ),
        radius: size.width * 0.45,
        color: const Color(0xFFFF6B9D), // rose
        opacity: 0.04 * intensity,
      ),
      _AuroraBlob(
        center: Offset(
          size.width * (0.5 + 0.25 * math.sin(progress * 2 * math.pi * 0.8)),
          size.height * (0.8 + 0.1 * math.cos(progress * 2 * math.pi * 1.1)),
        ),
        radius: size.width * 0.4,
        color: const Color(0xFF4ECDC4), // teal
        opacity: 0.05 * intensity,
      ),
    ];

    for (final blob in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withOpacity(blob.opacity),
            blob.color.withOpacity(0),
          ],
        ).createShader(
          Rect.fromCircle(center: blob.center, radius: blob.radius),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

      canvas.drawCircle(blob.center, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.progress != progress;
}

class _AuroraBlob {
  const _AuroraBlob({
    required this.center,
    required this.radius,
    required this.color,
    required this.opacity,
  });

  final Offset center;
  final double radius;
  final Color color;
  final double opacity;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PARTICLE PAINTER — Twinkling star-dust
/// ═══════════════════════════════════════════════════════════════════════════

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  final List<_FloatingParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.phaseOffset) % 1.0;

      // Slow drift
      final x = size.width * (p.startX + p.driftX * math.sin(t * 2 * math.pi));
      final y = size.height *
          (p.startY + p.driftY * math.cos(t * 2 * math.pi * p.speed));

      // Twinkle: fade in and out
      final twinkle = (math.sin(t * 2 * math.pi * p.twinkleSpeed + p.phaseOffset * 6) + 1) / 2;
      final opacity = p.baseOpacity * (0.3 + 0.7 * twinkle);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.8);

      canvas.drawCircle(Offset(x, y), p.radius, paint);

      // Bright core
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.6);
      canvas.drawCircle(Offset(x, y), p.radius * 0.3, corePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _FloatingParticle {
  _FloatingParticle({
    required this.startX,
    required this.startY,
    required this.driftX,
    required this.driftY,
    required this.radius,
    required this.baseOpacity,
    required this.speed,
    required this.phaseOffset,
    required this.twinkleSpeed,
    required this.color,
  });

  factory _FloatingParticle.random(math.Random rng) {
    final colors = [
      VesparaColors.glow,
      VesparaColors.primary,
      const Color(0xFFFF6B9D),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFD54F),
    ];

    return _FloatingParticle(
      startX: rng.nextDouble(),
      startY: rng.nextDouble(),
      driftX: 0.02 + rng.nextDouble() * 0.04,
      driftY: 0.02 + rng.nextDouble() * 0.04,
      radius: 1.0 + rng.nextDouble() * 2.5,
      baseOpacity: 0.3 + rng.nextDouble() * 0.5,
      speed: 0.5 + rng.nextDouble() * 1.5,
      phaseOffset: rng.nextDouble(),
      twinkleSpeed: 1.0 + rng.nextDouble() * 3.0,
      color: colors[rng.nextInt(colors.length)],
    );
  }

  final double startX, startY;
  final double driftX, driftY;
  final double radius;
  final double baseOpacity;
  final double speed;
  final double phaseOffset;
  final double twinkleSpeed;
  final Color color;
}
