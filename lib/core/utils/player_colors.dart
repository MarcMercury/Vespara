import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PLAYER COLORS - Unified Color Assignment for TAG Games
/// ════════════════════════════════════════════════════════════════════════════
///
/// Provides consistent player color assignment across all multiplayer TAG games.
/// Colors are designed to be visually distinct, accessible, and aesthetically pleasing.

class PlayerColors {
  PlayerColors._(); // Prevent instantiation

  /// Primary player color palette (8 distinct colors)
  /// Designed for high contrast against dark backgrounds
  static const List<Color> palette = [
    Color(0xFF4A9EFF), // Ethereal Blue
    Color(0xFFDC143C), // Crimson Red
    Color(0xFF9B59B6), // Royal Purple
    Color(0xFF2ECC71), // Emerald Green
    Color(0xFFF39C12), // Golden Orange
    Color(0xFF1ABC9C), // Teal
    Color(0xFFE74C3C), // Coral Red
    Color(0xFF3498DB), // Sky Blue
  ];

  /// Extended palette for games with more than 8 players
  static const List<Color> extendedPalette = [
    Color(0xFF4A9EFF), // Ethereal Blue
    Color(0xFFDC143C), // Crimson Red
    Color(0xFF9B59B6), // Royal Purple
    Color(0xFF2ECC71), // Emerald Green
    Color(0xFFF39C12), // Golden Orange
    Color(0xFF1ABC9C), // Teal
    Color(0xFFE74C3C), // Coral Red
    Color(0xFF3498DB), // Sky Blue
    Color(0xFFFF6B9D), // Hot Pink
    Color(0xFF00D4FF), // Electric Cyan
    Color(0xFFFFD93D), // Sunny Yellow
    Color(0xFFFF8C42), // Tangerine
    Color(0xFF98D8C8), // Mint
    Color(0xFFB8A9C9), // Lavender
    Color(0xFFF7DC6F), // Pale Gold
    Color(0xFF85C1E9), // Light Blue
  ];

  /// Get color for a player by index (wraps around if index > palette length)
  static Color forIndex(int index) => palette[index % palette.length];

  /// Get color from extended palette (for games with 9-16 players)
  static Color forIndexExtended(int index) =>
      extendedPalette[index % extendedPalette.length];

  /// Get a list of colors for N players
  static List<Color> forPlayerCount(int count) {
    if (count <= palette.length) {
      return palette.sublist(0, count);
    }
    return List.generate(count, forIndexExtended);
  }

  /// Get a random color from the palette
  static Color random() =>
      palette[DateTime.now().millisecondsSinceEpoch % palette.length];

  /// Get contrasting text color (black or white) for a given background
  static Color contrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Get a muted version of a color (for backgrounds)
  static Color muted(Color color, {double opacity = 0.2}) =>
      color.withOpacity(opacity);

  /// Get a slightly darker version of a color (for pressed states)
  static Color darker(Color color, {double factor = 0.8}) =>
      HSLColor.fromColor(color)
          .withLightness(
            (HSLColor.fromColor(color).lightness * factor).clamp(0.0, 1.0),
          )
          .toColor();

  /// Get a slightly lighter version of a color (for hover states)
  static Color lighter(Color color, {double factor = 1.2}) =>
      HSLColor.fromColor(color)
          .withLightness(
            (HSLColor.fromColor(color).lightness * factor).clamp(0.0, 1.0),
          )
          .toColor();

  /// Create a gradient from a player color
  static LinearGradient gradientFrom(Color color) => LinearGradient(
        colors: [
          color,
          lighter(color, factor: 1.3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Create a radial glow effect gradient
  static RadialGradient glowFrom(Color color, {double opacity = 0.4}) =>
      RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(0),
        ],
      );
}

/// Extension to add player color functionality to Color
extension PlayerColorExtension on Color {
  /// Get contrasting text color for this background
  Color get contrastingText => PlayerColors.contrastingTextColor(this);

  /// Get muted version of this color
  Color get muted => PlayerColors.muted(this);

  /// Get darker version of this color
  Color get darker => PlayerColors.darker(this);

  /// Get lighter version of this color
  Color get lighter => PlayerColors.lighter(this);

  /// Create a gradient from this color
  LinearGradient get gradient => PlayerColors.gradientFrom(this);

  /// Create a glow effect from this color
  RadialGradient get glow => PlayerColors.glowFrom(this);
}

/// Player model with assigned color
class ColoredPlayer {
  const ColoredPlayer({
    required this.name,
    required this.color,
    required this.index,
  });

  /// Create a player with auto-assigned color based on index
  factory ColoredPlayer.create(String name, int index) => ColoredPlayer(
        name: name,
        color: PlayerColors.forIndex(index),
        index: index,
      );
  final String name;
  final Color color;
  final int index;

  /// Get contrasting text color for this player's color
  Color get textColor => color.contrastingText;

  /// Get muted background color for this player
  Color get backgroundColor => color.muted;
}
