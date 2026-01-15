import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

/// Tile 8: The Mirror - Analytics
/// Displays brutal truth stats: Ghost Rate, Flake Rate, Swipe Ratio
class MirrorTile extends ConsumerWidget {
  final VoidCallback onTap;
  
  const MirrorTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(userAnalyticsProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: VesparaGlass.tile,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VesparaSpacing.md,
            vertical: VesparaSpacing.sm,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: VesparaColors.primary,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: VesparaSpacing.md),
              
              // Stats bar
              Expanded(
                child: analytics.when(
                  data: (data) => data != null
                      ? _buildStatsBar(context, data)
                      : _buildEmptyStats(context),
                  loading: () => _buildStatsShimmer(),
                  error: (_, __) => _buildEmptyStats(context),
                ),
              ),
              
              // Label
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'THE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1,
                      color: VesparaColors.inactive,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    'MIRROR',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      letterSpacing: 2,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatsBar(BuildContext context, dynamic analytics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat(
          context,
          label: 'Ghost',
          value: '${(analytics.ghostRate * 100).toStringAsFixed(0)}%',
          color: analytics.ghostRate > 0.3
              ? VesparaColors.tagsRed
              : VesparaColors.tagsGreen,
        ),
        _buildStat(
          context,
          label: 'Flake',
          value: '${(analytics.flakeRate * 100).toStringAsFixed(0)}%',
          color: analytics.flakeRate > 0.3
              ? VesparaColors.tagsYellow
              : VesparaColors.tagsGreen,
        ),
        _buildStat(
          context,
          label: 'Swipe',
          value: '${(analytics.swipeRatio * 100).toStringAsFixed(0)}%',
          color: VesparaColors.secondary,
        ),
      ],
    );
  }
  
  Widget _buildStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: VesparaColors.inactive,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyStats(BuildContext context) {
    return Center(
      child: Text(
        'No data yet',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
  
  Widget _buildStatsShimmer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        3,
        (index) => Container(
          width: 40,
          height: 30,
          decoration: BoxDecoration(
            color: VesparaColors.shimmerBase,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
