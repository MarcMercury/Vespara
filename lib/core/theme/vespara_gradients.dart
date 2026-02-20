import 'package:flutter/material.dart';
import 'app_theme.dart';

/// ╔═══════════════════════════════════════════════════════════════════════════╗
/// ║                KULT GRADIENT SYSTEM                                        ║
/// ║  Rich, layered gradients for the Celestial Luxury aesthetic               ║
/// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Legacy class name retained for compatibility.
class VesparaGradients {
  VesparaGradients._();

  // ═══════════════════════════════════════════════════════════════════════════
  // MODULE ACCENT GRADIENTS — each tile gets its own signature gradient
  // ═══════════════════════════════════════════════════════════════════════════

  /// Discover — electric rose-to-magenta
  static const LinearGradient discover = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B9D), Color(0xFFC44569)],
  );

  /// Nest — deep teal-to-cyan
  static const LinearGradient nest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4ECDC4), Color(0xFF2C9F97)],
  );

  /// Planner — violet-to-indigo
  static const LinearGradient planner = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCE93D8), Color(0xFF7E57C2)],
  );

  /// Experiences — amber-to-deep-orange
  static const LinearGradient experiences = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB74D), Color(0xFFFF7043)],
  );

  /// Shredder — crimson-to-dark-rose
  static const LinearGradient shredder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF5350), Color(0xFFC62828)],
  );

  /// TAG — gold-to-amber
  static const LinearGradient tag = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
  );

  /// Get gradient by module index
  static LinearGradient forModule(int index) {
    switch (index) {
      case 0: return discover;
      case 1: return nest;
      case 2: return planner;
      case 3: return experiences;
      case 4: return shredder;
      case 5: return tag;
      default: return discover;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND MESH GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Main background — deep void with subtle warmth
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1523),
      Color(0xFF0F0B18),
      Color(0xFF16101F),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  /// Aurora — animated background overlay colors
  static const List<Color> auroraColors = [
    Color(0x15BFA6D8), // lavender haze
    Color(0x12FF6B9D), // rose whisper
    Color(0x104ECDC4), // teal ghost
    Color(0x10FFD54F), // gold trace
    Color(0x15BFA6D8), // back to lavender
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // GLASS OVERLAY GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Glass shine — top-left highlight
  static LinearGradient glassShine({double opacity = 0.12}) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(opacity),
      Colors.white.withOpacity(opacity * 0.3),
      Colors.transparent,
    ],
    stops: const [0.0, 0.3, 0.6],
  );

  /// Inner glow — radial light from center
  static RadialGradient innerGlow(Color color, {double opacity = 0.15}) =>
      RadialGradient(
        center: const Alignment(0.0, -0.3),
        radius: 1.2,
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      );

  /// Edge rim-light — subtle border glow
  static LinearGradient rimLight(Color color, {double opacity = 0.3}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.1),
          color.withOpacity(opacity * 0.5),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // SHIMMER SWEEP GRADIENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Shimmer sweep for loading states and emphasis
  static LinearGradient shimmerSweep({
    double progress = 0.0,
    Color baseColor = const Color(0xFF2D2638),
  }) {
    return LinearGradient(
      begin: Alignment(-1.0 + 2.0 * progress, -0.3),
      end: Alignment(-0.5 + 2.0 * progress, 0.3),
      colors: [
        baseColor,
        baseColor.withOpacity(0.5),
        Colors.white.withOpacity(0.1),
        baseColor.withOpacity(0.5),
        baseColor,
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    );
  }
}
