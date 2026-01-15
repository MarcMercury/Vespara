import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

/// Tile 2: The Scope - Discovery
/// Displays a stack of Focus Batch profile cards
class ScopeTile extends ConsumerWidget {
  final VoidCallback onTap;
  
  const ScopeTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusBatch = ref.watch(focusBatchProvider);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: VesparaGlass.tile,
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
                    'THE SCOPE',
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
                      Icons.remove_red_eye_outlined,
                      color: VesparaColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: VesparaSpacing.md),
              
              // ═══════════════════════════════════════════════════════════════
              // FOCUS BATCH CARD STACK
              // ═══════════════════════════════════════════════════════════════
              Expanded(
                child: focusBatch.when(
                  data: (matches) => _buildCardStack(context, matches.length),
                  loading: () => _buildCardStackShimmer(),
                  error: (_, __) => _buildCardStack(context, 0),
                ),
              ),
              
              const SizedBox(height: VesparaSpacing.sm),
              
              // ═══════════════════════════════════════════════════════════════
              // FOCUS BATCH LABEL
              // ═══════════════════════════════════════════════════════════════
              Center(
                child: Text(
                  'Focus Batch',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the visual card stack
  Widget _buildCardStack(BuildContext context, int count) {
    return Center(
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(
            count > 5 ? 5 : (count > 0 ? count : 3),
            (index) {
              final reverseIndex = (count > 5 ? 5 : (count > 0 ? count : 3)) - 1 - index;
              return Positioned(
                top: reverseIndex * 6.0,
                child: Transform.rotate(
                  angle: (reverseIndex - 2) * 0.03,
                  child: Container(
                    width: 80 - (reverseIndex * 4),
                    height: 100 - (reverseIndex * 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          VesparaColors.surfaceElevated,
                          VesparaColors.surface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: reverseIndex == 0
                            ? VesparaColors.glow.withOpacity(0.5)
                            : VesparaColors.border,
                        width: reverseIndex == 0 ? 1.5 : 1,
                      ),
                      boxShadow: reverseIndex == 0
                          ? VesparaElevation.glow
                          : null,
                    ),
                    child: reverseIndex == 0
                        ? Center(
                            child: Icon(
                              Icons.person_outline,
                              color: VesparaColors.secondary,
                              size: 32,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardStackShimmer() {
    return Center(
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: VesparaColors.shimmerBase,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
