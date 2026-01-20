import 'package:flutter/material.dart';

/// TAG Visual Engine - Global Style Guide
/// Celestial Luxury aesthetic with programmatic art
/// 
/// All visuals use abstract forms: silhouettes, constellations, and fluid lines.
/// No photorealism. No external images.
class TagColors {
  TagColors._();
  
  /// Deep background - The void
  static const Color obsidian = Color(0xFF121212);
  
  /// Mind/Ice - Cool intellectual energy
  static const Color etherealBlue = Color(0xFF00E5FF);
  
  /// Body/Fire - Passionate heat
  static const Color crimsonHeat = Color(0xFFFF2E63);
  
  /// Risk/Go - Electric action
  static const Color toxicGreen = Color(0xFF00FF9D);
  
  /// Reward/Win - Triumphant glow
  static const Color royalGold = Color(0xFFFFD700);
  
  /// Deep purple - Mystery and luxury
  static const Color deepPurple = Color(0xFF4A0080);
  
  /// Navy void - Cosmic depth
  static const Color navyVoid = Color(0xFF0A0A2E);
  
  /// Soft pink - Feminine energy
  static const Color blushPink = Color(0xFFFF69B4);
  
  /// Retro magenta - Synthwave
  static const Color retroMagenta = Color(0xFFFF00FF);
  
  /// Warm orange - Sunset heat
  static const Color warmOrange = Color(0xFFFF6B35);
}

/// Glow effects for neon tubing aesthetic
class TagGlow {
  TagGlow._();
  
  /// Standard neon outer glow
  static MaskFilter get neonGlow => const MaskFilter.blur(BlurStyle.outer, 10);
  
  /// Intense outer glow for emphasis
  static MaskFilter get intenseGlow => const MaskFilter.blur(BlurStyle.outer, 20);
  
  /// Soft inner glow for subtle depth
  static MaskFilter get softGlow => const MaskFilter.blur(BlurStyle.normal, 6);
  
  /// Subtle ambient glow
  static MaskFilter get ambientGlow => const MaskFilter.blur(BlurStyle.outer, 4);
  
  /// Create a glowing paint with the neon effect
  static Paint createGlowPaint({
    required Color color,
    double strokeWidth = 2.0,
    double opacity = 0.8,
    MaskFilter? customGlow,
  }) {
    return Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = customGlow ?? neonGlow;
  }
  
  /// Create a fill paint with glow effect
  static Paint createGlowFillPaint({
    required Color color,
    double opacity = 0.6,
    MaskFilter? customGlow,
  }) {
    return Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = customGlow ?? softGlow;
  }
}

/// Gradient presets for TAG visuals
class TagGradients {
  TagGradients._();
  
  /// Ice gradient - Cyan to deep blue
  static const List<Color> ice = [
    Color(0xFF00E5FF),
    Color(0xFF0066FF),
    Color(0xFF001B44),
  ];
  
  /// Fire gradient - Crimson to orange
  static const List<Color> fire = [
    Color(0xFFFF2E63),
    Color(0xFFFF6B35),
    Color(0xFFFFD700),
  ];
  
  /// Velvet gradient - Deep purple to gold
  static const List<Color> velvet = [
    Color(0xFF4A0080),
    Color(0xFF7B00A8),
    Color(0xFFFFD700),
  ];
  
  /// Retrowave gradient - Magenta to orange
  static const List<Color> retrowave = [
    Color(0xFFFF00FF),
    Color(0xFFFF2E63),
    Color(0xFFFF6B35),
  ];
  
  /// Cosmic gradient - Navy to starlight
  static const List<Color> cosmic = [
    Color(0xFF0A0A2E),
    Color(0xFF1A1A4E),
    Color(0xFFFFFFFF),
  ];
  
  /// Passion gradient - Blue to pink merge
  static const List<Color> passion = [
    Color(0xFF00E5FF),
    Color(0xFFFFFFFF),
    Color(0xFFFF69B4),
  ];
}
