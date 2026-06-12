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

    test('amoled is a true-black dark theme', () {
      final amoled = AppTheme.amoled();
      expect(amoled.colorScheme.brightness, Brightness.dark);
      expect(amoled.scaffoldBackgroundColor, const Color(0xFF000000));
      // Still the calm BMI bands + the editorial flat surfaces.
      expect(amoled.extension<FeatherPalette>(), isNotNull);
    });

    test('fromDynamic keeps our extension + shape, takes system colors', () {
      final dynamicScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF7A5C9E), // a "wallpaper" purple
        brightness: Brightness.light,
      );
      final theme = AppTheme.fromDynamic(dynamicScheme);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, dynamicScheme.primary); // system color
      expect(theme.extension<FeatherPalette>(), isNotNull); // BMI bands kept
      // amoled flavour blacks out the surfaces even with a dynamic scheme.
      final darkDynamic = ColorScheme.fromSeed(
        seedColor: const Color(0xFF7A5C9E),
        brightness: Brightness.dark,
      );
      expect(
        AppTheme.fromDynamic(darkDynamic, amoled: true).scaffoldBackgroundColor,
        const Color(0xFF000000),
      );
    });
  });

  group('palettes', () {
    test('Slate is available and near-monochrome', () {
      final slate = paletteById('slate');
      expect(slate.id, 'slate');
      expect(slate.label, 'Slate');
    });

    test('an unknown / dynamic id falls back to the default palette', () {
      expect(paletteById(dynamicPaletteId).id, featherPalettes.first.id);
      expect(paletteById('nope').id, featherPalettes.first.id);
    });
  });
}
