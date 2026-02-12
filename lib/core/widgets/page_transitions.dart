import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ╔═══════════════════════════════════════════════════════════════════════════╗
/// ║          VESPARA PAGE TRANSITIONS                                          ║
/// ║  Cinematic route transitions worthy of a luxury app                        ║
/// ╚═══════════════════════════════════════════════════════════════════════════╝

// ═══════════════════════════════════════════════════════════════════════════
// 1. CELESTIAL FADE — Blur + fade + subtle scale
// ═══════════════════════════════════════════════════════════════════════════

class VesparaCelestialRoute<T> extends PageRouteBuilder<T> {
  VesparaCelestialRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Outgoing page blurs and fades
            final secondaryCurve = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOut,
            );

            return Stack(
              children: [
                // Outgoing page: blur + scale down + fade
                if (secondaryAnimation.value > 0)
                  BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: secondaryCurve.value * 5,
                      sigmaY: secondaryCurve.value * 5,
                    ),
                    child: Transform.scale(
                      scale: 1.0 - secondaryCurve.value * 0.05,
                      child: Opacity(
                        opacity: 1.0 - secondaryCurve.value * 0.3,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),

                // Incoming page: fade + subtle rise + scale
                FadeTransition(
                  opacity: curvedAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(curvedAnimation),
                    child: ScaleTransition(
                      scale: Tween(begin: 0.97, end: 1.0).animate(curvedAnimation),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        );

  final Widget page;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. SLIDE-UP REVEAL — From bottom with glass blur
// ═══════════════════════════════════════════════════════════════════════════

class VesparaSlideUpRoute<T> extends PageRouteBuilder<T> {
  VesparaSlideUpRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutExpo,
              reverseCurve: Curves.easeInCubic,
            );

            return Stack(
              children: [
                // Background darkening
                FadeTransition(
                  opacity: Tween(begin: 0.0, end: 0.4).animate(curvedAnimation),
                  child: const ColoredBox(
                    color: Colors.black,
                    child: SizedBox.expand(),
                  ),
                ),
                // Page slides up
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.8),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: FadeTransition(
                    opacity: curvedAnimation,
                    child: child,
                  ),
                ),
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          opaque: false,
        );

  final Widget page;
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. PORTAL EXPAND — Expands from a point (for tile taps)
// ═══════════════════════════════════════════════════════════════════════════

class VesparaPortalRoute<T> extends PageRouteBuilder<T> {
  VesparaPortalRoute({
    required this.page,
    this.originColor,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return AnimatedBuilder(
              animation: curvedAnimation,
              builder: (context, _) {
                return Stack(
                  children: [
                    // Expanding color wash
                    if (originColor != null)
                      Positioned.fill(
                        child: Opacity(
                          opacity: (1 - curvedAnimation.value) * 0.3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                radius: 0.5 + curvedAnimation.value * 1.5,
                                colors: [
                                  originColor!.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Main content
                    FadeTransition(
                      opacity: curvedAnimation,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.92, end: 1.0).animate(curvedAnimation),
                        child: child,
                      ),
                    ),
                  ],
                );
              },
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        );

  final Widget page;
  final Color? originColor;
}

// ═══════════════════════════════════════════════════════════════════════════
// CONVENIENCE NAVIGATION HELPER
// ═══════════════════════════════════════════════════════════════════════════

extension VesparaNavigation on BuildContext {
  /// Navigate with the Celestial fade (default for most screens)
  Future<T?> pushCelestial<T>(Widget page) {
    return Navigator.of(this).push<T>(VesparaCelestialRoute(page: page));
  }

  /// Navigate with slide-up (for modals and detail views)
  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(VesparaSlideUpRoute(page: page));
  }

  /// Navigate with portal expand (for tile taps)
  Future<T?> pushPortal<T>(Widget page, {Color? color}) {
    return Navigator.of(this).push<T>(
      VesparaPortalRoute(page: page, originColor: color),
    );
  }
}
