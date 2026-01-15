import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

/// Tile 5: The Shredder - Purge
/// Small tile showing stale matches count for Ghost Protocol
class ShredderTile extends ConsumerWidget {
  final VoidCallback onTap;
  
  const ShredderTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staleCount = ref.watch(staleMatchesCountProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: VesparaGlass.tile.copyWith(
          gradient: staleCount > 0
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VesparaColors.tagsRed.withOpacity(0.1),
                    VesparaColors.surface,
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(VesparaSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: staleCount > 0
                      ? VesparaColors.tagsRed.withOpacity(0.2)
                      : VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_delete_outlined,
                  color: staleCount > 0
                      ? VesparaColors.tagsRed
                      : VesparaColors.secondary,
                  size: 22,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Count
              Text(
                '$staleCount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: staleCount > 0
                      ? VesparaColors.tagsRed
                      : VesparaColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Label
              Text(
                'STALE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                  color: VesparaColors.inactive,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
