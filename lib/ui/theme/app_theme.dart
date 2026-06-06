import 'package:flutter/material.dart';

import '../../domain/bmi.dart';
import 'tokens.dart';

/// App-specific colors that Material's [ColorScheme] doesn't model, exposed via
/// the theme so widgets read them with `Theme.of(context).extension<...>()`
/// instead of hard-coding hex values.
@immutable
class FeatherPalette extends ThemeExtension<FeatherPalette> {
  const FeatherPalette({
    required this.positive,
    required this.sunrise,
    required this.underweight,
    required this.normal,
    required this.overweight,
    required this.obese,
  });

  /// Progress toward goal / losses in the right direction; goal line.
  final Color positive;

  /// Highlights, milestones, celebration.
  final Color sunrise;

  final Color underweight;
  final Color normal;
  final Color overweight;
  final Color obese;

  /// The calm color for a given BMI category.
  Color forBmiCategory(BmiCategory c) => switch (c) {
    BmiCategory.underweight => underweight,
    BmiCategory.normal => normal,
    BmiCategory.overweight => overweight,
    BmiCategory.obeseClassI ||
    BmiCategory.obeseClassII ||
    BmiCategory.obeseClassIII => obese,
  };

  @override
  FeatherPalette copyWith({
    Color? positive,
    Color? sunrise,
    Color? underweight,
    Color? normal,
    Color? overweight,
    Color? obese,
  }) => FeatherPalette(
    positive: positive ?? this.positive,
    sunrise: sunrise ?? this.sunrise,
    underweight: underweight ?? this.underweight,
    normal: normal ?? this.normal,
    overweight: overweight ?? this.overweight,
    obese: obese ?? this.obese,
  );

  @override
  FeatherPalette lerp(ThemeExtension<FeatherPalette>? other, double t) {
    if (other is! FeatherPalette) return this;
    return FeatherPalette(
      positive: Color.lerp(positive, other.positive, t)!,
      sunrise: Color.lerp(sunrise, other.sunrise, t)!,
      underweight: Color.lerp(underweight, other.underweight, t)!,
      normal: Color.lerp(normal, other.normal, t)!,
      overweight: Color.lerp(overweight, other.overweight, t)!,
      obese: Color.lerp(obese, other.obese, t)!,
    );
  }
}

/// Central theme builder. All colors/shape flow from the design tokens
/// (UI_DESIGN.md), so re-skinning is changing tokens, not hunting widgets.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: FeatherColors.lightPrimary,
          brightness: brightness,
        ).copyWith(
          primary: isDark
              ? FeatherColors.darkPrimary
              : FeatherColors.lightPrimary,
          surface: isDark
              ? FeatherColors.darkSurface
              : FeatherColors.lightSurface,
          outlineVariant: isDark
              ? FeatherColors.darkHairline
              : FeatherColors.lightHairline,
        );

    final palette = FeatherPalette(
      positive: isDark
          ? FeatherColors.darkPositiveSage
          : FeatherColors.lightPositiveSage,
      sunrise: isDark
          ? FeatherColors.darkAccentSunrise
          : FeatherColors.lightAccentSunrise,
      underweight: BmiBandColors.underweight,
      normal: isDark ? BmiBandColors.normalDark : BmiBandColors.normalLight,
      overweight: BmiBandColors.overweight,
      obese: BmiBandColors.obese,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? FeatherColors.darkBgPaper
          : FeatherColors.lightBgPaper,
      extensions: [palette],
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
        ),
      ),
    );
  }
}
