import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

/// Tile 7: The Core - Preferences & Settings
/// Small tile showing settings gear and user avatar
class CoreTile extends ConsumerWidget {
  final VoidCallback onTap;
  
  const CoreTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustScore = ref.watch(trustScoreProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: VesparaGlass.tile,
        child: Padding(
          padding: const EdgeInsets.all(VesparaSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with trust ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Trust ring
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: trustScore / 100,
                      strokeWidth: 2,
                      backgroundColor: VesparaColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        VesparaColors.glow,
                      ),
                    ),
                  ),
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VesparaColors.surface,
                      border: Border.all(
                        color: VesparaColors.border,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: VesparaColors.secondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Settings icon
              const Icon(
                Icons.settings_outlined,
                color: VesparaColors.secondary,
                size: 16,
              ),
              
              // Label
              Text(
                'CORE',
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
