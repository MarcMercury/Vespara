import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ╔═══════════════════════════════════════════════════════════════════════════╗
/// ║                     VESPARA HAPTIC FEEDBACK SYSTEM                        ║
/// ║           "Celestial Luxury" - Every tap should feel tactile              ║
/// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Vespara Haptic Feedback Service
/// Provides tactile feedback for all interactions (luxury feel)
/// Note: Uses HapticFeedback from Flutter which is web-safe (no-op on web)
class VesparaHaptics {
  VesparaHaptics._();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CORE IMPACTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Light Impact - Standard button taps, menu selections
  /// Usage: InkWell taps, navigation buttons
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }
  
  /// Alias for light()
  static Future<void> lightTap() async {
    await light();
  }
  
  /// Medium Impact - Snapping cards, confirming selections
  /// Usage: TAGS carousel snap, Kanban card drop
  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Heavy Impact - Major actions, critical toggles
  /// Usage: Ghost Protocol activation, Tonight Mode toggle
  static Future<void> heavyTap() async {
    await HapticFeedback.heavyImpact();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC FEEDBACK
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Selection Click - For toggles and sliders
  /// Usage: Consent meter changes, settings toggles
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
  
  /// Success Feedback - Positive confirmation pattern
  /// Usage: Match found, vouch confirmed, profile saved
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }
  
  /// Error Feedback - Double heavy buzz
  /// Usage: Validation errors, failed actions
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
  }
  
  /// Warning Feedback - Double medium buzz
  /// Usage: Destructive action confirmation, stale match alert
  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL EFFECTS (Phase 5)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Carousel Snap - When a card snaps into place
  /// Usage: TAGS Game Carousel, Date Idea Carousel
  static Future<void> carouselSnap() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Ghost Protocol - Heavy dramatic feedback
  /// Usage: Activating Ghost Protocol to fade a connection
  static Future<void> ghostProtocol() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }
  
  /// Tonight Mode Toggle - Heavy pulse
  /// Usage: Toggling Tonight Mode on/off
  static Future<void> tonightModeToggle() async {
    await HapticFeedback.heavyImpact();
  }
  
  /// Match Found - Celebration pattern
  /// Usage: New match notification, mutual interest detected
  static Future<void> matchFound() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }
  
  /// Tile Press - Light feedback for tile interactions
  /// Usage: Bento tile press down
  static Future<void> tilePress() async {
    await HapticFeedback.lightImpact();
  }
  
  /// Swipe Card - Light feedback for card swipes
  /// Usage: TAGS card swipe, profile card swipe
  static Future<void> swipeCard() async {
    await HapticFeedback.selectionClick();
  }
}

/// Extension for easy haptic feedback on widgets
extension HapticFeedbackExtension on Widget {
  /// Wrap widget with light haptic on tap
  Widget withHapticFeedback({
    VoidCallback? onTap,
    bool lightImpact = true,
  }) {
    return GestureDetector(
      onTap: () async {
        if (lightImpact) {
          await VesparaHaptics.lightTap();
        } else {
          await VesparaHaptics.mediumTap();
        }
        onTap?.call();
      },
      child: this,
    );
  }
  
  /// Wrap widget with carousel snap haptic on scroll end
  Widget withCarouselSnapHaptic() {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        VesparaHaptics.carouselSnap();
        return false;
      },
      child: this,
    );
  }
}

/// A button wrapper that automatically adds haptic feedback
class HapticButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Future<void> Function()? hapticFeedback;
  
  const HapticButton({
    super.key,
    required this.child,
    this.onPressed,
    this.hapticFeedback,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await (hapticFeedback?.call() ?? VesparaHaptics.lightTap());
        onPressed?.call();
      },
      child: child,
    );
  }
}

/// An InkWell replacement with automatic haptic feedback
class HapticInkWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  
  const HapticInkWell({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap != null
          ? () async {
              await VesparaHaptics.lightTap();
              onTap!();
            }
          : null,
      onLongPress: onLongPress != null
          ? () async {
              await VesparaHaptics.mediumTap();
              onLongPress!();
            }
          : null,
      borderRadius: borderRadius,
      splashColor: splashColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}
