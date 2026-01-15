import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/domain/models/roster_match.dart';

/// Tile 3: The Roster - CRM Pipeline
/// Displays Kanban board preview with stage avatars
class RosterTile extends ConsumerWidget {
  final VoidCallback onTap;
  
  const RosterTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipelineMatches = ref.watch(pipelineMatchesProvider);
    
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
                    'THE ROSTER',
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
                      Icons.view_kanban_outlined,
                      color: VesparaColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // ═══════════════════════════════════════════════════════════════
              // PIPELINE PREVIEW
              // ═══════════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: PipelineStage.values.map((stage) {
                  final matches = pipelineMatches[stage] ?? [];
                  return _buildStagePreview(
                    context,
                    stage: stage,
                    count: matches.length,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStagePreview(
    BuildContext context, {
    required PipelineStage stage,
    required int count,
  }) {
    return Column(
      children: [
        // Avatar stack
        SizedBox(
          width: 50,
          height: 30,
          child: Stack(
            children: List.generate(
              count > 3 ? 3 : (count > 0 ? count : 1),
              (index) => Positioned(
                left: index * 12.0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VesparaColors.surface,
                    border: Border.all(
                      color: count > 0 
                          ? VesparaColors.glow.withOpacity(0.5)
                          : VesparaColors.border,
                      width: 1,
                    ),
                  ),
                  child: count > 0
                      ? const Icon(
                          Icons.person,
                          size: 14,
                          color: VesparaColors.secondary,
                        )
                      : const SizedBox(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Stage label
        Text(
          stage.shortName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: VesparaColors.inactive,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
