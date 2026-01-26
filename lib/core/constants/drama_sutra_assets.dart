import 'package:flutter/widgets.dart';

/// Pre-declare all Drama Sutra asset paths so Flutter includes them in the bundle
/// This file exists to force Flutter to include these assets in web builds

const List<String> dramaSutraAssetPaths = [
  // Group positions
  'assets/images/drama_sutra/group-sex-1_X5.png',
  'assets/images/drama_sutra/group-sex-2_X5.png',
  'assets/images/drama_sutra/group-sex-3_X5.png',
  'assets/images/drama_sutra/group-sex-4_X5.png',
  'assets/images/drama_sutra/group-sex-5_X5.png',
  'assets/images/drama_sutra/group-sex-6_X5.png',
  'assets/images/drama_sutra/group-sex-7_X5.png',
  'assets/images/drama_sutra/group-sex-8_X5.png',
  'assets/images/drama_sutra/group-sex-9_X5.png',
  'assets/images/drama_sutra/group-sex-10_X5.png',
  'assets/images/drama_sutra/group-sex-11_X5.png',
  'assets/images/drama_sutra/group-sex-12_X5.png',

  // Bingo positions
  'assets/images/drama_sutra/acrobat.png',
  'assets/images/drama_sutra/ballerina.png',
  'assets/images/drama_sutra/best-seat-in-the-house.png',
  'assets/images/drama_sutra/body-surfing.png',
  'assets/images/drama_sutra/celebration.png',
  'assets/images/drama_sutra/deep-throat.png',
  'assets/images/drama_sutra/doggy.png',
  'assets/images/drama_sutra/front-row-seat.png',
  'assets/images/drama_sutra/hammock.png',
  'assets/images/drama_sutra/head-over-heels.png',
  'assets/images/drama_sutra/helicopter.png',
  'assets/images/drama_sutra/missionary.png',
  'assets/images/drama_sutra/octopus.png',
  'assets/images/drama_sutra/power-pump.png',
  'assets/images/drama_sutra/pretzel.png',
  'assets/images/drama_sutra/pump-and-grind.png',
  'assets/images/drama_sutra/reverse-cowgirl.png',
  'assets/images/drama_sutra/sixty-nine.png',
  'assets/images/drama_sutra/superman.png',
  'assets/images/drama_sutra/table-delight.png',
  'assets/images/drama_sutra/threesome.png',
  'assets/images/drama_sutra/treasure-hunt.png',
  'assets/images/drama_sutra/tree-hugger.png',
  'assets/images/drama_sutra/wall-hug.png',
  'assets/images/drama_sutra/web-of-desire.png',
  'assets/images/drama_sutra/zombie.png',
];

/// Call this at app startup to ensure assets are precached
Future<void> precacheDramaSutraAssets(context) async {
  for (final path in dramaSutraAssetPaths) {
    try {
      await precacheImage(AssetImage(path), context);
    } catch (_) {
      // Asset may not be available on all platforms
    }
  }
}
