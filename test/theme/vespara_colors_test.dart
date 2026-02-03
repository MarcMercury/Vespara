import 'package:flutter_test/flutter_test.dart';
import 'package:vespara/core/theme/vespara_colors.dart';

void main() {
  group('VesparaColors', () {
    test('primary colors are defined', () {
      expect(VesparaColors.background, isNotNull);
      expect(VesparaColors.surface, isNotNull);
      expect(VesparaColors.glow, isNotNull);
    });

    test('glow color is the signature gold/amber', () {
      // Vespara's signature glow should be warm gold/amber
      expect(VesparaColors.glow.red, greaterThan(200));
      expect(VesparaColors.glow.green, greaterThan(100));
    });

    test('background is dark for night theme', () {
      // Night theme should have dark background
      final luminance = VesparaColors.background.computeLuminance();
      expect(luminance, lessThan(0.1));
    });
  });
}
