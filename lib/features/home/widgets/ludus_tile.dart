import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/domain/models/tags_game.dart';

/// Tile 6: The Ludus - Events & TAGS
/// Split view showing Plan (Events) and Play (TAGS)
class LudusTile extends ConsumerWidget {
  final VoidCallback onTap;
  
  const LudusTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentLevel = ref.watch(tagsConsentLevelProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: VesparaGlass.tile.copyWith(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VesparaColors.surface,
              VesparaColors.surface.withOpacity(0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(VesparaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════════════
              // HEADER
              // ═══════════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'THE LUDUS',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      letterSpacing: 2,
                      color: VesparaColors.secondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.casino_outlined,
                      color: VesparaColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: VesparaSpacing.md),
              
              // ═══════════════════════════════════════════════════════════════
              // SPLIT VIEW: PLAN vs PLAY
              // ═══════════════════════════════════════════════════════════════
              Expanded(
                child: Row(
                  children: [
                    // PLAN (Events)
                    Expanded(
                      child: _buildPlanSection(context),
                    ),
                    
                    // Divider
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: VesparaSpacing.md),
                      color: VesparaColors.border,
                    ),
                    
                    // PLAY (TAGS)
                    Expanded(
                      flex: 2,
                      child: _buildPlaySection(context, consentLevel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the PLAN section for events
  Widget _buildPlanSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: VesparaColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              'PLAN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
        
        const Spacer(),
        
        // Event placeholder
        Container(
          padding: const EdgeInsets.all(VesparaSpacing.sm),
          decoration: BoxDecoration(
            color: VesparaColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: VesparaColors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Friday Dinner',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+ Create Event',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: VesparaColors.glow,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
      ],
    );
  }
  
  /// Build the PLAY section for TAGS games
  Widget _buildPlaySection(BuildContext context, ConsentLevel consentLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label with consent meter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sports_esports_outlined,
                  size: 14,
                  color: VesparaColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'PLAY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: VesparaColors.secondary,
                  ),
                ),
              ],
            ),
            // Mini consent indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getConsentColor(consentLevel).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                consentLevel.emoji,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: VesparaSpacing.sm),
        
        // Game cards carousel preview
        Expanded(
          child: Row(
            children: [
              _buildGameCardPreview(
                context,
                icon: Icons.style_outlined,
                label: 'Pleasure Deck',
              ),
              const SizedBox(width: VesparaSpacing.sm),
              _buildGameCardPreview(
                context,
                icon: Icons.route_outlined,
                label: 'Path',
              ),
              const SizedBox(width: VesparaSpacing.sm),
              _buildGameCardPreview(
                context,
                icon: Icons.meeting_room_outlined,
                label: 'Room',
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildGameCardPreview(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              VesparaColors.surfaceElevated,
              VesparaColors.background,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: VesparaColors.glow.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: VesparaColors.glow.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: VesparaColors.primary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: VesparaColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getConsentColor(ConsentLevel level) {
    switch (level) {
      case ConsentLevel.green:
        return VesparaColors.tagsGreen;
      case ConsentLevel.yellow:
        return VesparaColors.tagsYellow;
      case ConsentLevel.red:
        return VesparaColors.tagsRed;
    }
  }
}
