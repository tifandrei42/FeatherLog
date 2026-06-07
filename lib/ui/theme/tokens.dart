import 'package:flutter/material.dart';

/// Design tokens — the single source of truth for FeatherLog's visual language
/// (UI_DESIGN.md §2–4). Widgets should read from `ThemeData`/`ColorScheme`
/// where possible; these tokens feed that theme (see `app_theme.dart`) and
/// provide the few app-specific values Material's scheme doesn't cover
/// (BMI bands, the goal/positive accent).

/// Color tokens for the two themes ("Daylight" / "Twilight").
class FeatherColors {
  const FeatherColors._();

  // --- Light theme — vibrant, aktiBMI-inspired multi-color palette ---
  // Leaf-green primary (buttons / progress / active), blue "info" secondary
  // (delta pills; also keeps harmony with the blue app icon), amber accent for
  // milestones. A clean off-white surface keeps the colors popping.
  static const lightBgPaper = Color(0xFFF6F8F3); // faint green-tinted paper
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFEDF2E9);
  static const lightInkStrong = Color(0xFF1F2A24);
  static const lightInkMuted = Color(0xFF5C6A62);
  static const lightInkFaint = Color(0xFF9AA79E);
  static const lightPrimary = Color(0xFF2FA84F); // leaf green (buttons/active)
  static const lightPrimarySoft = Color(0xFFD8F3DD); // green tint / container
  static const lightSecondary = Color(0xFF2D6CDF); // info blue (delta pills)
  static const lightSecondarySoft = Color(0xFFDCE7FB);
  static const lightAccentSunrise = Color(0xFFF4A52A); // amber milestones
  static const lightPositiveSage = Color(0xFF2FA84F);
  static const lightHairline = Color(0xFFE3E9DE);

  // --- Dark theme — vibrant palette on a warm charcoal ---
  static const darkBgPaper = Color(0xFF12181A);
  static const darkSurface = Color(0xFF1A2220);
  static const darkSurfaceAlt = Color(0xFF232D29);
  static const darkInkStrong = Color(0xFFE8EEEA);
  static const darkInkMuted = Color(0xFF9AA8A0);
  static const darkInkFaint = Color(0xFF5E6C64);
  static const darkPrimary = Color(0xFF5CC46E); // green reads on dark
  static const darkPrimarySoft = Color(0xFF1F3A28);
  static const darkSecondary = Color(0xFF6FA0F5); // info blue
  static const darkSecondarySoft = Color(0xFF213352);
  static const darkAccentSunrise = Color(0xFFF4B556);
  static const darkPositiveSage = Color(0xFF5CC46E);
  static const darkHairline = Color(0xFF28322D);
}

/// Calm, non-alarmist BMI band colors (UI_DESIGN.md §2). Resolved per-brightness
/// via [bmiBandColor].
class BmiBandColors {
  const BmiBandColors._();

  // Semantic gauge colors (aktiBMI-style): blue → green → orange → red. The
  // obese band is a softened red (not full alarm-red) to stay encouraging.
  static const underweight = Color(0xFF3B82F6); // blue
  static const normalLight = Color(0xFF22C55E); // green
  static const normalDark = Color(0xFF4ADE80);
  static const overweight = Color(0xFFF59E0B); // orange
  static const obese = Color(0xFFEF5350); // soft red
}

/// 4pt spacing scale (UI_DESIGN.md §4).
class Spacing {
  const Spacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
  static const huge = 64.0;
}

/// Corner radii — soft and rounded (UI_DESIGN.md §4).
class Radii {
  const Radii._();

  static const sm = 12.0;
  static const md = 16.0; // inputs
  static const lg = 24.0; // cards
  static const pill = 999.0; // buttons
}

/// A selectable accent palette for the in-app theme chooser. Only the accent
/// roles vary between palettes; the neutral surfaces/ink ([FeatherColors]) and
/// the semantic BMI bands ([BmiBandColors]) are shared. Soft/"container" tints
/// are derived in `app_theme.dart`, so each entry stays compact.
@immutable
class AccentPalette {
  const AccentPalette({
    required this.id,
    required this.label,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondaryLight,
    required this.secondaryDark,
    required this.accentLight,
    required this.accentDark,
  });

  final String id;
  final String label;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondaryLight;
  final Color secondaryDark;
  final Color accentLight;
  final Color accentDark;

  /// The primary color for [brightness] (also used as the chooser swatch).
  Color primaryFor(Brightness b) =>
      b == Brightness.dark ? primaryDark : primaryLight;
}

/// The curated palettes offered by the theme chooser. The first is the default.
const List<AccentPalette> featherPalettes = [
  AccentPalette(
    id: 'meadow',
    label: 'Meadow',
    primaryLight: Color(0xFF2FA84F),
    primaryDark: Color(0xFF5CC46E),
    secondaryLight: Color(0xFF2D6CDF),
    secondaryDark: Color(0xFF6FA0F5),
    accentLight: Color(0xFFF4A52A),
    accentDark: Color(0xFFF4B556),
  ),
  AccentPalette(
    id: 'ocean',
    label: 'Ocean',
    primaryLight: Color(0xFF2D7FF0),
    primaryDark: Color(0xFF6BA6FF),
    secondaryLight: Color(0xFF14B8A6),
    secondaryDark: Color(0xFF3FD0C9),
    accentLight: Color(0xFFFB7185),
    accentDark: Color(0xFFFB8DA0),
  ),
  AccentPalette(
    id: 'grape',
    label: 'Grape',
    primaryLight: Color(0xFF7C5CF0),
    primaryDark: Color(0xFFA593FF),
    secondaryLight: Color(0xFFEC4899),
    secondaryDark: Color(0xFFF472B6),
    accentLight: Color(0xFFF4A52A),
    accentDark: Color(0xFFF4B556),
  ),
  AccentPalette(
    id: 'sunset',
    label: 'Sunset',
    primaryLight: Color(0xFFF26D4B),
    primaryDark: Color(0xFFFB9A6B),
    secondaryLight: Color(0xFF6366F1),
    secondaryDark: Color(0xFF9CA3FF),
    accentLight: Color(0xFF14B8A6),
    accentDark: Color(0xFF3FD0C9),
  ),
  AccentPalette(
    id: 'rose',
    label: 'Rose',
    primaryLight: Color(0xFFE11D48),
    primaryDark: Color(0xFFFB6F88),
    secondaryLight: Color(0xFF4F46E5),
    secondaryDark: Color(0xFF818CF8),
    accentLight: Color(0xFFF59E0B),
    accentDark: Color(0xFFFBBF24),
  ),
];

/// Looks up a palette by [id], falling back to the default (first) palette.
AccentPalette paletteById(String? id) => featherPalettes.firstWhere(
  (p) => p.id == id,
  orElse: () => featherPalettes.first,
);
