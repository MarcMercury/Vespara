import 'package:flutter/material.dart';

import '../../../core/domain/models/tag_rating.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG RATING DISPLAY WIDGET
/// Shows the Three-Rating System for any TAG game
/// 🏎️ Velocity | 🔥 Heat | ⏱️ Duration
/// ════════════════════════════════════════════════════════════════════════════

class TagRatingDisplay extends StatelessWidget {
  final TagRating rating;
  final bool compact;

  const TagRatingDisplay({
    super.key,
    required this.rating,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [VesparaColors.glow, Colors.pinkAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TAG RATING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Three ratings
          Row(
            children: [
              // Velocity
              Expanded(
                child: _buildRatingColumn(
                  emoji: '🏎️',
                  label: 'Velocity',
                  value: rating.velocity.display,
                  subtitle: rating.velocity.label,
                  color: _getVelocityColor(rating.velocity),
                ),
              ),
              
              // Divider
              Container(
                width: 1,
                height: 60,
                color: Colors.white12,
              ),
              
              // Heat
              Expanded(
                child: _buildRatingColumn(
                  emoji: '🔥',
                  label: 'Heat',
                  value: rating.heat.code,
                  subtitle: rating.heat.label,
                  color: _getHeatColor(rating.heat),
                ),
              ),
              
              // Divider
              Container(
                width: 1,
                height: 60,
                color: Colors.white12,
              ),
              
              // Duration
              Expanded(
                child: _buildRatingColumn(
                  emoji: '⏱️',
                  label: 'Duration',
                  value: rating.duration.label,
                  subtitle: rating.duration.timeRange,
                  color: VesparaColors.glow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingColumn({
    required String emoji,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompactView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactChip('🏎️', rating.velocity.display, _getVelocityColor(rating.velocity)),
        const SizedBox(width: 8),
        _buildCompactChip('🔥', rating.heat.code, _getHeatColor(rating.heat)),
        const SizedBox(width: 8),
        _buildCompactChip('⏱️', rating.duration.label, VesparaColors.glow),
      ],
    );
  }

  Widget _buildCompactChip(String emoji, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getVelocityColor(VelocityRating velocity) {
    switch (velocity) {
      case VelocityRating.innocent:
        return Colors.green;
      case VelocityRating.flirty:
        return Colors.yellow;
      case VelocityRating.sparks:
        return Colors.orange;
      case VelocityRating.fullThrottle:
        return Colors.red;
    }
  }

  Color _getHeatColor(HeatRating heat) {
    switch (heat) {
      case HeatRating.pg:
        return Colors.green;
      case HeatRating.pg13:
        return Colors.yellow;
      case HeatRating.r:
        return Colors.orange;
      case HeatRating.x:
        return Colors.red;
      case HeatRating.xxx:
        return Colors.redAccent;
    }
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// TAG RATING SELECTOR
/// Allows users to see/filter by TAG ratings
/// ════════════════════════════════════════════════════════════════════════════

class TagRatingInfoSheet extends StatelessWidget {
  const TagRatingInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'THE TAG RATING SYSTEM',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Every TAG game comes with our Three-Rating System.\nBecause knowing what you\'re getting into is part of the turn-on.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Velocity Meter
            _buildRatingSection(
              emoji: '🏎️',
              title: 'Velocity Meter',
              subtitle: '0–100 mph · How fast might this get you going?',
              items: [
                _RatingItem('0 mph', 'Innocent fun — safe for brunch'),
                _RatingItem('40 mph', 'Flirty tension and teasing'),
                _RatingItem('70 mph', 'Expect sparks — possibly skin'),
                _RatingItem('100 mph', 'Full throttle. Buckle up.'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Heat Rating
            _buildRatingSection(
              emoji: '🔥',
              title: 'Heat Rating',
              subtitle: 'PG–XXX · What kind of action might you see?',
              items: [
                _RatingItem('PG', 'Playful, suggestive, mostly teasing'),
                _RatingItem('PG-13', 'Light touching, kissing, bold flirting'),
                _RatingItem('R', 'Risqué, passionate, hands-on'),
                _RatingItem('X', 'Explicit, adventurous, clothing unlikely'),
                _RatingItem('XXX', 'Uninhibited, wild, gloriously unfiltered'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Duration
            _buildRatingSection(
              emoji: '⏱️',
              title: 'Duration',
              subtitle: 'Every pleasure deserves its pace',
              items: [
                _RatingItem('Quickie', '5–15 min — Fast, fun, dangerous in the best way'),
                _RatingItem('Foreplay', '20–45 min — Builds slowly, burns beautifully'),
                _RatingItem('Full Session', '60+ min — Take your time; the night\'s young'),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Philosophy
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VesparaColors.glow.withOpacity(0.1),
                    Colors.pinkAccent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TAG\'s Philosophy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPhilosophyItem('✅', 'Consensual — The Yes Zone', 
                    'No confusion. No surprises. No pressure.'),
                  _buildPhilosophyItem('✨', 'Playful — The Spark', 
                    'Sexy is better with laughter.'),
                  _buildPhilosophyItem('🌈', 'Inclusive — The Invitation', 
                    'Every body, every pairing, every orientation.'),
                  _buildPhilosophyItem('🛡️', 'Trusted — The Promise', 
                    'Games people actually want to say yes to.'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required String emoji,
    required String title,
    required String subtitle,
    required List<_RatingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPhilosophyItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingItem {
  final String value;
  final String description;
  
  _RatingItem(this.value, this.description);
}
