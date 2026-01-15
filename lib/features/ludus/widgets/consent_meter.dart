import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/tags_game.dart';
import '../../../core/utils/haptics.dart';

/// Consent Meter Widget - The Vibe Check Slider
/// Mandatory consent level selection before games load
class ConsentMeter extends StatelessWidget {
  final ConsentLevel currentLevel;
  final ValueChanged<ConsentLevel> onLevelChanged;
  
  const ConsentMeter({
    super.key,
    required this.currentLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: VesparaGlass.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONSENT LEVEL',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  letterSpacing: 2,
                  color: VesparaColors.secondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getConsentColor(currentLevel).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getConsentColor(currentLevel).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      currentLevel.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentLevel.displayName.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _getConsentColor(currentLevel),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.md),
          
          // Custom slider track
          _buildCustomSlider(context),
          
          const SizedBox(height: VesparaSpacing.sm),
          
          // Level labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ConsentLevel.values.map((level) {
              final isSelected = level == currentLevel;
              return Text(
                level.displayName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? _getConsentColor(level)
                      : VesparaColors.inactive,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCustomSlider(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final segmentWidth = trackWidth / (ConsentLevel.values.length - 1);
        final thumbPosition = currentLevel.value * segmentWidth;
        
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final position = details.localPosition.dx.clamp(0.0, trackWidth);
            final newValue = (position / segmentWidth).round();
            final newLevel = ConsentLevel.values[newValue.clamp(0, ConsentLevel.values.length - 1)];
            
            if (newLevel != currentLevel) {
              VesparaHaptics.selectionClick();
              onLevelChanged(newLevel);
            }
          },
          onTapDown: (details) {
            final position = details.localPosition.dx.clamp(0.0, trackWidth);
            final newValue = (position / segmentWidth).round();
            final newLevel = ConsentLevel.values[newValue.clamp(0, ConsentLevel.values.length - 1)];
            
            VesparaHaptics.selectionClick();
            onLevelChanged(newLevel);
          },
          child: Container(
            height: 40,
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Track background
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        VesparaColors.tagsGreen,
                        VesparaColors.tagsYellow,
                        VesparaColors.tagsRed,
                      ],
                    ),
                  ),
                ),
                
                // Track overlay (inactive portion)
                Positioned(
                  left: thumbPosition + 15,
                  right: 0,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: VesparaColors.background.withOpacity(0.7),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
                
                // Level dots
                ...ConsentLevel.values.map((level) {
                  final dotPosition = level.value * segmentWidth;
                  final isActive = level.value <= currentLevel.value;
                  
                  return Positioned(
                    left: dotPosition - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? _getConsentColor(level)
                            : VesparaColors.surface,
                        border: Border.all(
                          color: VesparaColors.border,
                          width: 1,
                        ),
                      ),
                    ),
                  );
                }),
                
                // Thumb
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  left: thumbPosition - 15,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VesparaColors.background,
                      border: Border.all(
                        color: _getConsentColor(currentLevel),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getConsentColor(currentLevel).withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        currentLevel.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
