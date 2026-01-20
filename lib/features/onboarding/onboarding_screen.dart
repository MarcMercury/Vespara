import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/exclusive_onboarding_screen.dart';

/// OnboardingScreen - The Exclusive Club Interview
/// A luxurious onboarding experience with velvet rope intro,
/// age verification, comprehensive profile building, and AI bio generation
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return const ExclusiveOnboardingScreen();
  }
}
