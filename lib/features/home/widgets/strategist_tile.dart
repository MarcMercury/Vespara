import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

/// Tile 1: The Strategist - AI Planning
/// Displays Optimization Score and Tonight Mode toggle
class StrategistTile extends ConsumerWidget {
  final VoidCallback onTap;
  
  const StrategistTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTonightMode = ref.watch(tonightModeProvider);
    final optimizationScore = ref.watch(optimizationScoreProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: VesparaGlass.tile.copyWith(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VesparaColors.surface,
              VesparaColors.surface.withOpacity(0.8),
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
                    'THE STRATEGIST',
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
                      Icons.auto_awesome,
                      color: VesparaColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // ═══════════════════════════════════════════════════════════════
              // OPTIMIZATION SCORE
              // ═══════════════════════════════════════════════════════════════
              optimizationScore.when(
                data: (score) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: VesparaColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optimization Score',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                loading: () => _buildScoreShimmer(),
                error: (_, __) => const Text('--'),
              ),
              
              const Spacer(),
              
              // ═══════════════════════════════════════════════════════════════
              // TONIGHT MODE TOGGLE
              // ═══════════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VesparaSpacing.md,
                  vertical: VesparaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isTonightMode 
                      ? VesparaColors.glow.withOpacity(0.2)
                      : VesparaColors.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
                  border: Border.all(
                    color: isTonightMode
                        ? VesparaColors.glow
                        : VesparaColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          color: isTonightMode 
                              ? VesparaColors.primary 
                              : VesparaColors.inactive,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tonight Mode',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isTonightMode 
                                ? VesparaColors.primary 
                                : VesparaColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isTonightMode,
                      onChanged: (value) {
                        ref.read(tonightModeProvider.notifier).state = value;
                      },
                      activeColor: VesparaColors.primary,
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
  
  Widget _buildScoreShimmer() {
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(
        color: VesparaColors.shimmerBase,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
