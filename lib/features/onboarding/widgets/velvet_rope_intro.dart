import 'package:flutter/material.dart';

import 'vespara_intro.dart';

/// VelvetRopeIntro - Wrapper for the exclusive entry animation
/// This provides a consistent API for the onboarding flow
class VelvetRopeIntro extends StatelessWidget {
  const VelvetRopeIntro({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => VesparaIntro(
        onComplete: onComplete,
      );
}
