import 'package:flutter/material.dart';

/// Design tokens — the single source of truth for FeatherLog's visual language
/// (UI_DESIGN.md §2–4). Widgets should read from `ThemeData`/`ColorScheme`
/// where possible; these tokens feed that theme (see `app_theme.dart`) and
/// provide the few app-specific values Material's scheme doesn't cover
/// (BMI bands, the goal/positive accent).

/// Color tokens for the two themes ("Daylight" / "Twilight").
class FeatherColors {
  const FeatherColors._();

  // --- Light theme ("Daylight") ---
  static const lightBgPaper = Color(0xFFFBFCFE);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF1F5FA);
  static const lightInkStrong = Color(0xFF1B2530);
  static const lightInkMuted = Color(0xFF5A6675);
  static const lightInkFaint = Color(0xFF9AA7B4);
  static const lightPrimary = Color(0xFF4F86C6);
  static const lightPrimarySoft = Color(0xFF9DC1E6);
  static const lightAccentSunrise = Color(0xFFF2A65A);
  static const lightPositiveSage = Color(0xFF6BAF92);
  static const lightHairline = Color(0xFFE4EAF1);

  // --- Dark theme ("Twilight") ---
  static const darkBgPaper = Color(0xFF0F1822);
  static const darkSurface = Color(0xFF18222E);
  static const darkSurfaceAlt = Color(0xFF1F2B38);
  static const darkInkStrong = Color(0xFFE8EDF2);
  static const darkInkMuted = Color(0xFF9AA7B4);
  static const darkInkFaint = Color(0xFF5E6C7A);
  static const darkPrimary = Color(0xFF7FB0D9);
  static const darkAccentSunrise = Color(0xFFF2B179);
  static const darkPositiveSage = Color(0xFF7CC4A4);
  static const darkHairline = Color(0xFF26323F);
}

/// Calm, non-alarmist BMI band colors (UI_DESIGN.md §2). Resolved per-brightness
/// via [bmiBandColor].
class BmiBandColors {
  const BmiBandColors._();

  static const underweight = Color(0xFF7FB0D9); // cool (same both themes)
  static const normalLight = Color(0xFF6BAF92); // sage
  static const normalDark = Color(0xFF7CC4A4);
  static const overweight = Color(0xFFE7B45A); // warm (same both themes)
  static const obese = Color(0xFFD98C6A); // muted terracotta, not red
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
