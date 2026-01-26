import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// CONTENT RATING - Unified Heat Level System for TAG Games
/// ════════════════════════════════════════════════════════════════════════════
///
/// All TAG games use this unified content rating system for consistency.
/// Maps to database values and provides display helpers.

enum ContentRating {
  /// 🟢 PG - Fun & flirty, keep it clean
  /// Social icebreakers, mild flirtation, no explicit content
  pg,

  /// 🟡 PG-13 - Suggestive, getting warmer
  /// Sensual themes, suggestive content, moderate intimacy
  pg13,

  /// 🔴 R - Adult content, things get spicy
  /// Explicit themes, adult content, requires maturity
  r,

  /// ⚫ X - Extreme, no limits
  /// Very explicit, intense content, full consent required
  x,

  /// 💀 XXX - Maximum intensity
  /// Extreme explicit content, for experienced players only
  xxx,
}

extension ContentRatingExtension on ContentRating {
  /// Database value for storage (matches existing schema values)
  String get dbValue {
    switch (this) {
      case ContentRating.pg:
        return 'PG';
      case ContentRating.pg13:
        return 'PG-13';
      case ContentRating.r:
        return 'R';
      case ContentRating.x:
        return 'X';
      case ContentRating.xxx:
        return 'XXX';
    }
  }

  /// User-friendly display name with emoji indicator
  String get displayName {
    switch (this) {
      case ContentRating.pg:
        return '🟢 Social';
      case ContentRating.pg13:
        return '🟡 Sensual';
      case ContentRating.r:
        return '🔴 Explicit';
      case ContentRating.x:
        return '⚫ Extreme';
      case ContentRating.xxx:
        return '💀 No Limits';
    }
  }

  /// Short label without emoji
  String get label {
    switch (this) {
      case ContentRating.pg:
        return 'Social';
      case ContentRating.pg13:
        return 'Sensual';
      case ContentRating.r:
        return 'Explicit';
      case ContentRating.x:
        return 'Extreme';
      case ContentRating.xxx:
        return 'No Limits';
    }
  }

  /// Description of what content to expect
  String get description {
    switch (this) {
      case ContentRating.pg:
        return 'Fun & flirty, keep it clean';
      case ContentRating.pg13:
        return 'Suggestive content, getting warmer';
      case ContentRating.r:
        return 'Adult content, things get spicy';
      case ContentRating.x:
        return 'Extreme content, no limits';
      case ContentRating.xxx:
        return 'Maximum intensity, experienced players only';
    }
  }

  /// Emoji indicator
  String get emoji {
    switch (this) {
      case ContentRating.pg:
        return '🟢';
      case ContentRating.pg13:
        return '🟡';
      case ContentRating.r:
        return '🔴';
      case ContentRating.x:
        return '⚫';
      case ContentRating.xxx:
        return '💀';
    }
  }

  /// Theme color for this rating level
  Color get color {
    switch (this) {
      case ContentRating.pg:
        return const Color(0xFF4CAF50); // Green
      case ContentRating.pg13:
        return const Color(0xFFFF9800); // Orange
      case ContentRating.r:
        return const Color(0xFFDC143C); // Crimson
      case ContentRating.x:
        return const Color(0xFF1A1A1A); // Near black
      case ContentRating.xxx:
        return const Color(0xFF6A0DAD); // Purple
    }
  }

  /// Background color (lighter variant for cards/containers)
  Color get backgroundColor => color.withOpacity(0.15);

  /// Border color (medium opacity)
  Color get borderColor => color.withOpacity(0.5);

  /// Numeric index (0-4) for comparison and progression tracking
  int get numericValue => index;

  /// Check if this rating includes content up to a certain level
  bool includes(ContentRating other) => index >= other.index;

  /// Get list of all ratings up to and including this level
  List<ContentRating> get includedRatings =>
      ContentRating.values.where((r) => r.index <= index).toList();

  /// Get database values for all included ratings (for SQL IN queries)
  List<String> get includedDbValues =>
      includedRatings.map((r) => r.dbValue).toList();

  /// Parse from database value
  static ContentRating fromDbValue(String value) {
    switch (value.toUpperCase()) {
      case 'PG':
        return ContentRating.pg;
      case 'PG-13':
        return ContentRating.pg13;
      case 'R':
        return ContentRating.r;
      case 'X':
        return ContentRating.x;
      case 'XXX':
        return ContentRating.xxx;
      default:
        return ContentRating.pg; // Safe default
    }
  }

  /// Parse from numeric value (1-5 scale used in some games)
  static ContentRating fromNumeric(int value) {
    if (value <= 1) return ContentRating.pg;
    if (value == 2) return ContentRating.pg13;
    if (value == 3) return ContentRating.r;
    if (value == 4) return ContentRating.x;
    return ContentRating.xxx;
  }

  /// Convert to numeric value (1-5 scale)
  int get toNumeric => index + 1;
}

/// Helper class for content rating operations
class ContentRatingHelper {
  /// Get all ratings as a list (useful for selectors)
  static List<ContentRating> get all => ContentRating.values;

  /// Get ratings suitable for general audiences (PG, PG-13)
  static List<ContentRating> get generalAudience => [
        ContentRating.pg,
        ContentRating.pg13,
      ];

  /// Get adult ratings only (R, X, XXX)
  static List<ContentRating> get adultOnly => [
        ContentRating.r,
        ContentRating.x,
        ContentRating.xxx,
      ];

  /// Default rating for new games
  static ContentRating get defaultRating => ContentRating.pg;

  /// Maximum rating (for admin/testing)
  static ContentRating get maximum => ContentRating.xxx;

  /// Validate if a string is a valid rating
  static bool isValid(String value) =>
      ['PG', 'PG-13', 'R', 'X', 'XXX'].contains(value.toUpperCase());
}
