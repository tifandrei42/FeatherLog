import 'package:featherlog/domain/bmi.dart';
import 'package:featherlog/ui/theme/app_theme.dart';
import 'package:featherlog/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light and dark are Material 3 with the right brightness', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.useMaterial3, isTrue);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
    });

    test('registers the FeatherPalette extension', () {
      expect(AppTheme.light().extension<FeatherPalette>(), isNotNull);
      expect(AppTheme.dark().extension<FeatherPalette>(), isNotNull);
    });

    test('palette uses the sage positive token per brightness', () {
      expect(
        AppTheme.light().extension<FeatherPalette>()!.positive,
        FeatherColors.lightPositiveSage,
      );
      expect(
        AppTheme.dark().extension<FeatherPalette>()!.positive,
        FeatherColors.darkPositiveSage,
      );
    });

    test('forBmiCategory maps obese classes to the same calm color', () {
      final p = AppTheme.light().extension<FeatherPalette>()!;
      expect(p.forBmiCategory(BmiCategory.normal), p.normal);
      expect(
        p.forBmiCategory(BmiCategory.obeseClassI),
        p.forBmiCategory(BmiCategory.obeseClassIII),
      );
    });
  });
}
