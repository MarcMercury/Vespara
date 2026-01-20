import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_theme.dart';

/// ╔═══════════════════════════════════════════════════════════════════════════╗
/// ║                     VESPARA MOTION SYSTEM                                  ║
/// ║       "Celestial Luxury" - Every transition should glide, not pop          ║
/// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Vespara Motion Constants & Curves
class VesparaMotion {
  VesparaMotion._();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DURATION CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Micro interactions (button press feedback)
  static const Duration micro = Duration(milliseconds: 100);
  
  /// Fast transitions (selection, toggles)
  static const Duration fast = Duration(milliseconds: 200);
  
  /// Standard transitions (page elements)
  static const Duration standard = Duration(milliseconds: 300);
  
  /// Emphasized transitions (modals, expansions)
  static const Duration emphasized = Duration(milliseconds: 500);
  
  /// Slow transitions (background animations)
  static const Duration slow = Duration(milliseconds: 800);
  
  /// Breathing effect cycle
  static const Duration breathing = Duration(seconds: 3);
  
  /// Staggered delay per tile
  static const Duration staggerDelay = Duration(milliseconds: 100);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CURVES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Standard easing (enter/exit)
  static const Curve standard_ = Curves.easeOutCubic;
  
  /// Deceleration (entering elements)
  static const Curve decelerate = Curves.decelerate;
  
  /// Spring bounce (interactive feedback)
  static const Curve spring = Curves.elasticOut;
  
  /// Tile press spring
  static const Curve tileSpring = Curves.easeOutBack;
  
  /// Smooth breathing
  static const Curve breathe = Curves.easeInOutSine;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SCALE VALUES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Tile press down scale
  static const double tilePressScale = 0.98;
  
  /// Breathing max scale
  static const double breathingMaxScale = 1.05;
  
  /// Breathing min opacity
  static const double breathingMinOpacity = 0.8;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // OFFSET VALUES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Staggered entrance slide offset
  static const Offset staggerSlideOffset = Offset(0, 0.1);
}

/// ═══════════════════════════════════════════════════════════════════════════
/// THE "BREATHING" EFFECT - Idle State Animation
/// Usage: Vespara Logo on login, "Tonight Mode" beacon
/// ═══════════════════════════════════════════════════════════════════════════
class BreathingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxScale;
  
  const BreathingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.minOpacity = 0.8,
    this.maxScale = 1.05,
  });
  
  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: VesparaMotion.breathe,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: widget.minOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: VesparaMotion.breathe,
    ));
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// THE "TILE SPRING" EFFECT - Interactive Feedback
/// Usage: All 8 Bento Tiles
/// ═══════════════════════════════════════════════════════════════════════════
class TileSpringWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  
  const TileSpringWidget({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.98,
  });
  
  @override
  State<TileSpringWidget> createState() => _TileSpringWidgetState();
}

class _TileSpringWidgetState extends State<TileSpringWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VesparaMotion.fast,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: VesparaMotion.tileSpring,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }
  
  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? widget.pressScale : _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// THE "GLASS LAYER" WIDGET - True Glassmorphism with BackdropFilter
/// Usage: Replace all standard Card backgrounds
/// ═══════════════════════════════════════════════════════════════════════════
class VesparaGlassWidget extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double borderOpacityTop;
  final double borderOpacityBottom;
  
  const VesparaGlassWidget({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.4,
    this.borderRadius,
    this.padding,
    this.borderOpacityTop = 0.2,
    this.borderOpacityBottom = 0.05,
  });
  
  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(VesparaBorderRadius.tile);
    
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: VesparaColors.background.withOpacity(opacity),
            border: GradientBorder(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(borderOpacityTop),
                  Colors.white.withOpacity(borderOpacityBottom),
                ],
              ),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Gradient Border Decoration
class GradientBorder extends BoxBorder {
  final Gradient gradient;
  final double width;
  
  const GradientBorder({
    required this.gradient,
    this.width = 1.0,
  });
  
  @override
  BorderSide get top => BorderSide.none;
  
  @override
  BorderSide get bottom => BorderSide.none;
  
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);
  
  @override
  bool get isUniform => true;
  
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    
    if (borderRadius != null) {
      canvas.drawRRect(
        borderRadius.toRRect(rect).deflate(width / 2),
        paint,
      );
    } else {
      canvas.drawRect(rect.deflate(width / 2), paint);
    }
  }
  
  @override
  ShapeBorder scale(double t) => GradientBorder(
    gradient: gradient,
    width: width * t,
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// STAGGERED ENTRANCE EXTENSIONS (using flutter_animate)
/// ═══════════════════════════════════════════════════════════════════════════
extension VesparaAnimateExtensions on Widget {
  /// Apply staggered entrance animation for dashboard tiles
  Widget staggeredEntrance(int index, {Duration? delay}) {
    final staggerDelay = delay ?? VesparaMotion.staggerDelay;
    return this
        .animate(delay: staggerDelay * index)
        .fadeIn(duration: VesparaMotion.standard, curve: VesparaMotion.standard_)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: VesparaMotion.standard,
          curve: VesparaMotion.standard_,
        );
  }
  
  /// Apply breathing effect
  Widget breathing({Duration? duration}) {
    return BreathingWidget(
      duration: duration ?? VesparaMotion.breathing,
      child: this,
    );
  }
  
  /// Wrap with tile spring effect
  Widget withTileSpring({VoidCallback? onTap}) {
    return TileSpringWidget(
      onTap: onTap,
      child: this,
    );
  }
  
  /// Wrap with glass effect
  Widget withGlass({
    double blur = 10.0,
    double opacity = 0.4,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return VesparaGlassWidget(
      blur: blur,
      opacity: opacity,
      borderRadius: borderRadius,
      padding: padding,
      child: this,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HERO EXPANSION HELPER
/// Usage: Wraps tile content for OpenContainer-style expansion
/// ═══════════════════════════════════════════════════════════════════════════
class TileHeroWrapper extends StatelessWidget {
  final String tag;
  final Widget child;
  
  const TileHeroWrapper({
    super.key,
    required this.tag,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        return Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: animation.drive(
              Tween<double>(begin: 1.0, end: 1.0).chain(
                CurveTween(curve: VesparaMotion.standard_),
              ),
            ),
            child: toHeroContext.widget,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}

/// Compatibility alias for legacy code using Motion
class Motion {
  Motion._();
  
  static Duration get micro => VesparaMotion.micro;
  static Duration get fast => VesparaMotion.fast;
  static Duration get standard => VesparaMotion.standard;
  static Duration get emphasized => VesparaMotion.emphasized;
  static Duration get slow => VesparaMotion.slow;
}
