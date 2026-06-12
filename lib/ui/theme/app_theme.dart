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

/// Central theme builder for the "Almanac" design language: an editorial
/// data-journal — Fraunces (serif) for display/headline/titles and the hero
/// numerals, Inter for UI/body, a periwinkle accent aligned to the app icon,
/// and flat, hairline-bordered surfaces instead of heavy shadows. All colors
/// and shape flow from the design tokens, so re-skinning is changing tokens,
/// not hunting widgets.
class AppTheme {
  const AppTheme._();

  static ThemeData light([AccentPalette? palette]) =>
      _build(Brightness.light, palette ?? featherPalettes.first);
  static ThemeData dark([AccentPalette? palette]) =>
      _build(Brightness.dark, palette ?? featherPalettes.first);

  /// A pure-black dark variant for OLED screens: true-black background and
  /// surfaces, hairlines as faint white. Selected as the "Black" theme option.
  static ThemeData amoled([AccentPalette? palette]) =>
      _build(Brightness.dark, palette ?? featherPalettes.first, amoled: true);

  /// Builds a theme from a wallpaper-derived [scheme] (Material You, Android
  /// 12+). Keeps the app's editorial shape/typography and the [FeatherPalette]
  /// extension (BMI bands stay calm and consistent); only the base colors come
  /// from the system. [amoled] forces true-black surfaces in dark mode.
  static ThemeData fromDynamic(ColorScheme scheme, {bool amoled = false}) {
    final isDark = scheme.brightness == Brightness.dark;
    final blackSurface = amoled && isDark;
    final surface = blackSurface ? const Color(0xFF000000) : scheme.surface;
    final hairline = isDark
        ? Colors.white.withValues(alpha: amoled ? 0.12 : 0.10)
        : Colors.black.withValues(alpha: 0.10);
    final palette = FeatherPalette(
      positive: isDark
          ? FeatherColors.darkPositiveSage
          : FeatherColors.lightPositiveSage,
      sunrise: scheme.tertiary,
      underweight: BmiBandColors.underweight,
      normal: isDark ? BmiBandColors.normalDark : BmiBandColors.normalLight,
      overweight: BmiBandColors.overweight,
      obese: BmiBandColors.obese,
    );
    return _assemble(
      scheme.copyWith(surface: surface, outlineVariant: hairline),
      surface,
      palette,
    );
  }

  /// Readable on-color for a fill: white on dark colors, near-black on light.
  static Color _on(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark
      ? Colors.white
      : const Color(0xFF101418);

  /// A soft "container" tint: the accent blended onto the surface.
  static Color _soft(Color c, Color surface, bool isDark) =>
      Color.alphaBlend(c.withValues(alpha: isDark ? 0.22 : 0.15), surface);

  static ThemeData _build(
    Brightness brightness,
    AccentPalette accentPalette, {
    bool amoled = false,
  }) {
    final isDark = brightness == Brightness.dark;

    // AMOLED overrides the neutrals with true black + faint-white hairlines;
    // otherwise the per-theme paper/surface/hairline tokens apply.
    final paper = amoled
        ? const Color(0xFF000000)
        : (isDark ? FeatherColors.darkBgPaper : FeatherColors.lightBgPaper);
    final surface = amoled
        ? const Color(0xFF0A0A0A)
        : (isDark ? FeatherColors.darkSurface : FeatherColors.lightSurface);
    final hairline = amoled
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? FeatherColors.darkHairline : FeatherColors.lightHairline);
    final ink = isDark
        ? FeatherColors.darkInkStrong
        : FeatherColors.lightInkStrong;
    final muted = isDark
        ? FeatherColors.darkInkMuted
        : FeatherColors.lightInkMuted;
    final primary = accentPalette.primaryFor(brightness);
    final secondary = isDark
        ? accentPalette.secondaryDark
        : accentPalette.secondaryLight;
    final accent = isDark
        ? accentPalette.accentDark
        : accentPalette.accentLight;
    final primarySoft = _soft(primary, surface, isDark);
    final secondarySoft = _soft(secondary, surface, isDark);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: accentPalette.primaryLight,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: _on(primary),
          primaryContainer: primarySoft,
          onPrimaryContainer: ink,
          secondary: secondary,
          onSecondary: _on(secondary),
          secondaryContainer: secondarySoft,
          onSecondaryContainer: ink,
          tertiary: accent,
          onTertiary: _on(accent),
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: muted,
          outlineVariant: hairline,
        );

    final palette = FeatherPalette(
      positive: isDark
          ? FeatherColors.darkPositiveSage
          : FeatherColors.lightPositiveSage,
      sunrise: accent,
      underweight: BmiBandColors.underweight,
      normal: isDark ? BmiBandColors.normalDark : BmiBandColors.normalLight,
      overweight: BmiBandColors.overweight,
      obese: BmiBandColors.obese,
    );

    return _assemble(scheme, paper, palette);
  }

  /// Assembles the final [ThemeData] from a resolved [scheme], the scaffold
  /// [paper] color, and the app's [palette] extension. Shared by the curated
  /// palettes ([_build]) and Material You ([fromDynamic]) so the editorial
  /// shape, flatness, and typography are identical across both.
  static ThemeData _assemble(
    ColorScheme scheme,
    Color paper,
    FeatherPalette palette,
  ) {
    final surface = scheme.surface;
    final hairline = scheme.outlineVariant;
    final ink = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      extensions: [palette],
      fontFamily: 'Nunito',
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        // Editorial flatness: a hairline rule, not a drop shadow.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: hairline),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: muted,
          ),
        ),
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
