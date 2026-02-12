import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/vespara_gradients.dart';

/// ╔═══════════════════════════════════════════════════════════════════════════╗
/// ║              VESPARA PREMIUM EFFECTS                                       ║
/// ║  Glassmorphism, 3D tilt, shimmer sweep, neon glow, and more               ║
/// ╚═══════════════════════════════════════════════════════════════════════════╝

// ═══════════════════════════════════════════════════════════════════════════
// 1. PREMIUM GLASS CARD — Deep glassmorphism with animated border
// ═══════════════════════════════════════════════════════════════════════════

class VesparaPremiumGlassCard extends StatefulWidget {
  const VesparaPremiumGlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.backgroundOpacity = 0.15,
    this.borderGradient,
    this.borderWidth = 1.5,
    this.borderRadius = 24.0,
    this.glowColor,
    this.glowIntensity = 0.15,
    this.padding,
    this.animateBorder = true,
  });

  final Widget child;
  final double blur;
  final double backgroundOpacity;
  final LinearGradient? borderGradient;
  final double borderWidth;
  final double borderRadius;
  final Color? glowColor;
  final double glowIntensity;
  final EdgeInsetsGeometry? padding;
  final bool animateBorder;

  @override
  State<VesparaPremiumGlassCard> createState() =>
      _VesparaPremiumGlassCardState();
}

class _VesparaPremiumGlassCardState extends State<VesparaPremiumGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.animateBorder) {
      _borderController.repeat();
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final glow = widget.glowColor ?? VesparaColors.glow;

    return AnimatedBuilder(
      animation: _borderController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              // Outer glow
              BoxShadow(
                color: glow.withOpacity(widget.glowIntensity *
                    (0.6 + 0.4 * math.sin(_borderController.value * 2 * math.pi))),
                blurRadius: 30,
                spreadRadius: -5,
              ),
              // Depth shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blur,
                sigmaY: widget.blur,
              ),
              child: CustomPaint(
                painter: _AnimatedBorderPainter(
                  progress: _borderController.value,
                  borderRadius: widget.borderRadius,
                  borderWidth: widget.borderWidth,
                  gradient: widget.borderGradient,
                  glowColor: glow,
                ),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: VesparaColors.surface.withOpacity(widget.backgroundOpacity),
                    // Glass shine overlay
                    gradient: VesparaGradients.glassShine(opacity: 0.08),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated rotating border gradient
class _AnimatedBorderPainter extends CustomPainter {
  _AnimatedBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
    this.gradient,
    required this.glowColor,
  });

  final double progress;
  final double borderRadius;
  final double borderWidth;
  final LinearGradient? gradient;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius),
    );

    // Rotating gradient for the border
    final angle = progress * 2 * math.pi;
    final sweepGradient = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * math.pi,
      colors: [
        Colors.white.withOpacity(0.3),
        glowColor.withOpacity(0.2),
        Colors.white.withOpacity(0.05),
        glowColor.withOpacity(0.1),
        Colors.white.withOpacity(0.3),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_AnimatedBorderPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. 3D TILT CARD — Responds to pointer position for parallax depth
// ═══════════════════════════════════════════════════════════════════════════

class Vespara3DTiltCard extends StatefulWidget {
  const Vespara3DTiltCard({
    super.key,
    required this.child,
    this.maxTiltDegrees = 8.0,
    this.borderRadius = 24.0,
    this.depth = 1.0,
    this.glowColor,
    this.onTap,
    this.enableHoverGlow = true,
  });

  final Widget child;
  final double maxTiltDegrees;
  final double borderRadius;
  final double depth;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool enableHoverGlow;

  @override
  State<Vespara3DTiltCard> createState() => _Vespara3DTiltCardState();
}

class _Vespara3DTiltCardState extends State<Vespara3DTiltCard>
    with SingleTickerProviderStateMixin {
  double _rotateX = 0;
  double _rotateY = 0;
  double _glowX = 0.5;
  double _glowY = 0.5;
  bool _isHovered = false;
  late AnimationController _resetController;
  late Animation<double> _resetXAnimation;
  late Animation<double> _resetYAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resetXAnimation = Tween(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetYAnimation = Tween(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPointerHover(PointerEvent event, BoxConstraints constraints) {
    final dx = (event.localPosition.dx / constraints.maxWidth - 0.5) * 2;
    final dy = (event.localPosition.dy / constraints.maxHeight - 0.5) * 2;

    setState(() {
      _isHovered = true;
      _rotateY = dx * widget.maxTiltDegrees * (math.pi / 180);
      _rotateX = -dy * widget.maxTiltDegrees * (math.pi / 180);
      _glowX = event.localPosition.dx / constraints.maxWidth;
      _glowY = event.localPosition.dy / constraints.maxHeight;
    });
  }

  void _onPointerExit() {
    _resetXAnimation = Tween(begin: _rotateX, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetYAnimation = Tween(begin: _rotateY, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
    );
    _resetController.forward(from: 0);

    _resetController.addListener(_onResetTick);
    setState(() => _isHovered = false);
  }

  void _onResetTick() {
    if (!mounted) return;
    setState(() {
      _rotateX = _resetXAnimation.value;
      _rotateY = _resetYAnimation.value;
    });
    if (_resetController.isCompleted) {
      _resetController.removeListener(_onResetTick);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? VesparaColors.glow;

    return LayoutBuilder(
      builder: (context, constraints) => MouseRegion(
        onHover: (event) => _onPointerHover(event, constraints),
        onExit: (_) => _onPointerExit(),
        child: GestureDetector(
          onTapDown: (details) {
            final dx = (details.localPosition.dx / constraints.maxWidth - 0.5) * 2;
            final dy = (details.localPosition.dy / constraints.maxHeight - 0.5) * 2;
            setState(() {
              _isHovered = true;
              _rotateY = dx * widget.maxTiltDegrees * 0.5 * (math.pi / 180);
              _rotateX = -dy * widget.maxTiltDegrees * 0.5 * (math.pi / 180);
              _glowX = details.localPosition.dx / constraints.maxWidth;
              _glowY = details.localPosition.dy / constraints.maxHeight;
            });
          },
          onTapUp: (_) {
            _onPointerExit();
            widget.onTap?.call();
          },
          onTapCancel: _onPointerExit,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001 * widget.depth)
              ..rotateX(_rotateX)
              ..rotateY(_rotateY),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  // Dynamic glow follows pointer
                  if (_isHovered && widget.enableHoverGlow)
                    BoxShadow(
                      color: glow.withOpacity(0.3),
                      blurRadius: 40,
                      offset: Offset(
                        (_glowX - 0.5) * 20,
                        (_glowY - 0.5) * 20,
                      ),
                    ),
                  // Base depth shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: _isHovered ? 25 : 15,
                    offset: Offset(
                      _rotateY * 10,
                      8 + _rotateX.abs() * 5,
                    ),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // The actual card content
                  ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: widget.child,
                  ),

                  // Specular highlight overlay (moves with pointer)
                  if (_isHovered)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(
                                  (_glowX - 0.5) * 2,
                                  (_glowY - 0.5) * 2,
                                ),
                                radius: 0.8,
                                colors: [
                                  Colors.white.withOpacity(0.12),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. SHIMMER SWEEP — Animated light sweep effect
// ═══════════════════════════════════════════════════════════════════════════

class VesparaShimmerSweep extends StatefulWidget {
  const VesparaShimmerSweep({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.sweepColor = Colors.white,
    this.sweepOpacity = 0.08,
    this.borderRadius = 24.0,
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final Color sweepColor;
  final double sweepOpacity;
  final double borderRadius;
  final bool enabled;

  @override
  State<VesparaShimmerSweep> createState() => _VesparaShimmerSweepState();
}

class _VesparaShimmerSweepState extends State<VesparaShimmerSweep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(
        children: [
          child!,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: IgnorePointer(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    final progress = _controller.value;
                    return LinearGradient(
                      begin: Alignment(-1.0 + 3.0 * progress, -0.3),
                      end: Alignment(-0.5 + 3.0 * progress, 0.3),
                      colors: [
                        Colors.transparent,
                        widget.sweepColor.withOpacity(widget.sweepOpacity),
                        widget.sweepColor.withOpacity(widget.sweepOpacity * 2),
                        widget.sweepColor.withOpacity(widget.sweepOpacity),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. NEON GLOW TEXT — Text with animated neon glow effect
// ═══════════════════════════════════════════════════════════════════════════

class VesparaNeonText extends StatefulWidget {
  const VesparaNeonText({
    super.key,
    required this.text,
    required this.style,
    this.glowColor,
    this.glowRadius = 20.0,
    this.animate = true,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Color? glowColor;
  final double glowRadius;
  final bool animate;
  final TextAlign? textAlign;

  @override
  State<VesparaNeonText> createState() => _VesparaNeonTextState();
}

class _VesparaNeonTextState extends State<VesparaNeonText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? VesparaColors.glow;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final intensity = 0.5 + 0.5 * _controller.value;
        return Stack(
          children: [
            // Glow layer (blurred)
            Text(
              widget.text,
              textAlign: widget.textAlign,
              style: widget.style.copyWith(
                foreground: Paint()
                  ..color = glowColor.withOpacity(0.6 * intensity)
                  ..maskFilter = MaskFilter.blur(
                    BlurStyle.normal,
                    widget.glowRadius * intensity,
                  ),
              ),
            ),
            // Crisp text layer
            Text(
              widget.text,
              textAlign: widget.textAlign,
              style: widget.style,
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. ANIMATED GRADIENT BORDER — Rotating rainbow border effect
// ═══════════════════════════════════════════════════════════════════════════

class VesparaGradientBorder extends StatefulWidget {
  const VesparaGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = 24.0,
    this.colors,
    this.duration = const Duration(seconds: 3),
    this.enabled = true,
  });

  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final List<Color>? colors;
  final Duration duration;
  final bool enabled;

  @override
  State<VesparaGradientBorder> createState() => _VesparaGradientBorderState();
}

class _VesparaGradientBorderState extends State<VesparaGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.enabled) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        [
          VesparaColors.glow,
          const Color(0xFFFF6B9D),
          const Color(0xFF4ECDC4),
          const Color(0xFFFFD54F),
          VesparaColors.glow,
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _RotatingGradientBorderPainter(
          progress: _controller.value,
          borderWidth: widget.borderWidth,
          borderRadius: widget.borderRadius,
          colors: colors,
        ),
        child: Padding(
          padding: EdgeInsets.all(widget.borderWidth),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _RotatingGradientBorderPainter extends CustomPainter {
  _RotatingGradientBorderPainter({
    required this.progress,
    required this.borderWidth,
    required this.borderRadius,
    required this.colors,
  });

  final double progress;
  final double borderWidth;
  final double borderRadius;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius),
    );

    final angle = progress * 2 * math.pi;
    final gradient = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * math.pi,
      colors: colors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_RotatingGradientBorderPainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. ANIMATED SCALE ON TAP — Bouncy feedback for any widget
// ═══════════════════════════════════════════════════════════════════════════

class VesparaBounceTap extends StatefulWidget {
  const VesparaBounceTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  @override
  State<VesparaBounceTap> createState() => _VesparaBounceTapState();
}

class _VesparaBounceTapState extends State<VesparaBounceTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. STAGGERED LIST ENTRANCE — Each item animates in with delay
// ═══════════════════════════════════════════════════════════════════════════

class VesparaStaggeredItem extends StatelessWidget {
  const VesparaStaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 80),
    this.slideDuration = const Duration(milliseconds: 500),
    this.slideOffset = 30.0,
  });

  final int index;
  final Widget child;
  final Duration delayPerItem;
  final Duration slideDuration;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: slideDuration + delayPerItem * index,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Ensure the delay portion keeps things invisible
        final effectiveValue = ((value - (index * 0.1)).clamp(0.0, 1.0) / 0.9)
            .clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, slideOffset * (1 - effectiveValue)),
          child: Opacity(
            opacity: effectiveValue,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
