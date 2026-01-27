import 'package:equatable/equatable.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG RATING SYSTEM
/// The Three-Rating System for TAG Games
/// Because knowing what you're getting into is part of the turn-on.
/// ════════════════════════════════════════════════════════════════════════════

/// 🏎️ Velocity Meter - How fast might this get you going? (0-100 mph)
enum VelocityRating {
  /// 25 mph - Warm up the engines
  warmUp(25, 'Warm Up', 'Getting started', '🏘️'),

  /// 30 mph - Light cruising
  cruising(30, 'Cruising', 'Light cruising', '🏘️'),

  /// 50 mph - Picking up speed
  speeding(50, 'Speeding', 'Picking up speed', '🏘️'),

  /// 55 mph - Highway speed
  highway(55, 'Highway', 'Steady pace', '🏘️'),

  /// 60 mph - Fast lane
  fastLane(60, 'Fast Lane', 'Moving quick', '🏘️'),

  /// 75 mph - Racing
  racing(75, 'Racing', 'High speed', '🏘️'),

  /// 80 mph - Full speed
  fullSpeed(80, 'Full Speed', 'Almost there', '🏘️'),

  /// 99 mph - Redline
  redline(99, 'Redline', 'Maximum intensity', '🏘️');

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
  fullSession(
    'Full Session',
    '60+ min',
    'Take your time; the night\'s young',
    '🌟',
  );

  final String label;
  final String timeRange;
  final String description;
  final String emoji;

  const DurationRating(
    this.label,
    this.timeRange,
    this.description,
    this.emoji,
  );
}

/// Complete TAG Rating for a game
class TagRating extends Equatable {
  const TagRating({
    required this.velocity,
    required this.heat,
    required this.duration,
  });
  final VelocityRating velocity;
  final HeatRating heat;
  final DurationRating duration;

  /// Down to Clown game rating - 30 mph / PG-13 / Quickie
  static const downToClown = TagRating(
    velocity: VelocityRating.cruising,
    heat: HeatRating.pg13,
    duration: DurationRating.quickie,
  );

  /// Ice Breakers game rating - 25 mph / PG-13 / Quickie
  static const iceBreakers = TagRating(
    velocity: VelocityRating.warmUp,
    heat: HeatRating.pg13,
    duration: DurationRating.quickie,
  );

  /// Share or Dare game rating - 50 mph / PG-13 to X / Foreplay
  static const shareOrDare = TagRating(
    velocity: VelocityRating.speeding,
    heat: HeatRating.r, // PG-13 to X range
    duration: DurationRating.foreplay,
  );

  /// Path of Pleasure game rating - 55 mph / PG-13 / Foreplay
  static const pathOfPleasure = TagRating(
    velocity: VelocityRating.highway,
    heat: HeatRating.pg13,
    duration: DurationRating.foreplay,
  );

  /// Lane of Lust game rating - 60 mph / R / Foreplay
  static const laneOfLust = TagRating(
    velocity: VelocityRating.fastLane,
    heat: HeatRating.r,
    duration: DurationRating.foreplay,
  );

  /// Drama-Sutra game rating - 80 mph / X / Quickie
  static const dramaSutra = TagRating(
    velocity: VelocityRating.fullSpeed,
    heat: HeatRating.x,
    duration: DurationRating.quickie,
  );

  /// Flash & Freeze game rating - 75 mph / X / Quickie
  static const flashFreeze = TagRating(
    velocity: VelocityRating.racing,
    heat: HeatRating.x,
    duration: DurationRating.quickie,
  );

  /// Dice Breakers game rating - 99 mph / XXX / Foreplay
  static const diceBreakers = TagRating(
    velocity: VelocityRating.redline,
    heat: HeatRating.xxx,
    duration: DurationRating.foreplay,
  );

  @override
  List<Object?> get props => [velocity, heat, duration];
}
