import 'package:equatable/equatable.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG RATING SYSTEM
/// The Three-Rating System for TAG Games
/// Because knowing what you're getting into is part of the turn-on.
/// ════════════════════════════════════════════════════════════════════════════

/// 🏎️ Velocity Meter - How fast might this get you going? (0-100 mph)
enum VelocityRating {
  /// 0 mph - Innocent fun — safe for brunch
  innocent(0, 'Innocent Fun', 'Safe for brunch', '🏎️'),
  
  /// 40 mph - Flirty tension and teasing
  flirty(40, 'Flirty Tension', 'Teasing energy', '🏎️'),
  
  /// 70 mph - Expect sparks — possibly skin
  sparks(70, 'Expect Sparks', 'Possibly skin', '🏎️'),
  
  /// 100 mph - Full throttle. Buckle up.
  fullThrottle(100, 'Full Throttle', 'Buckle up', '🏎️');

  final int mph;
  final String label;
  final String description;
  final String emoji;
  
  const VelocityRating(this.mph, this.label, this.description, this.emoji);
  
  String get display => '$mph mph';
}

/// 🔥 Heat Rating - What kind of action might you see?
enum HeatRating {
  /// PG - Playful, suggestive, mostly teasing
  pg('PG', 'Playful', 'Suggestive, mostly teasing', '🔥'),
  
  /// PG-13 - Light touching, kissing, bold flirting
  pg13('PG-13', 'Flirty', 'Light touching, bold flirting', '🔥🔥'),
  
  /// R - Risqué, passionate, hands-on
  r('R', 'Risqué', 'Passionate, hands-on', '🔥🔥🔥'),
  
  /// X - Explicit, adventurous, clothing unlikely
  x('X', 'Explicit', 'Adventurous, clothing unlikely', '🔥🔥🔥🔥'),
  
  /// XXX - Uninhibited, wild, gloriously unfiltered
  xxx('XXX', 'Uninhibited', 'Wild, gloriously unfiltered', '🔥🔥🔥🔥🔥');

  final String code;
  final String label;
  final String description;
  final String emoji;
  
  const HeatRating(this.code, this.label, this.description, this.emoji);
}

/// ⏱️ Duration Rating - How long will you be playing?
enum DurationRating {
  /// 5-15 min — Fast, fun, dangerous in the best way
  quickie('Quickie', '5-15 min', 'Fast, fun, dangerous in the best way', '⚡'),
  
  /// 20-45 min — Builds slowly, burns beautifully
  foreplay('Foreplay', '20-45 min', 'Builds slowly, burns beautifully', '🌙'),
  
  /// 60+ min — Take your time; the night's young
  fullSession('Full Session', '60+ min', 'Take your time; the night\'s young', '🌟');

  final String label;
  final String timeRange;
  final String description;
  final String emoji;
  
  const DurationRating(this.label, this.timeRange, this.description, this.emoji);
}

/// Complete TAG Rating for a game
class TagRating extends Equatable {
  final VelocityRating velocity;
  final HeatRating heat;
  final DurationRating duration;
  
  const TagRating({
    required this.velocity,
    required this.heat,
    required this.duration,
  });
  
  /// Down to Clown game rating
  static const downToClown = TagRating(
    velocity: VelocityRating.flirty,
    heat: HeatRating.pg13,
    duration: DurationRating.quickie,
  );
  
  @override
  List<Object?> get props => [velocity, heat, duration];
}
