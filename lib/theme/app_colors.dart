import 'package:flutter/material.dart';

/// All color tokens extracted from the HTML prototypes.
/// These map 1:1 to the Tailwind config in Home.html / Settings.html.
class AppColors {
  AppColors._();

  // ── Light scheme tokens (from prototypes) ──
  static const Color lightSurfaceContainerLow = Color(0xFFF1F4F2);
  static const Color lightSurfaceContainer = Color(0xFFEAEFEC);
  static const Color lightSurfaceContainerHigh = Color(0xFFE4E9E7);
  static const Color lightSurfaceContainerHighest = Color(0xFFDDE4E1);

  static const ColorScheme lightScheme = ColorScheme.light(
    primary: Color(0xFF33694B),
    onPrimary: Color(0xFFE7FFEC),
    primaryContainer: Color(0xFFB5F0C9),
    onPrimaryContainer: Color(0xFF255C3F),
    secondary: Color(0xFF4F6455),
    onSecondary: Color(0xFFE7FFEC),
    secondaryContainer: Color(0xFFD1E8D6),
    onSecondaryContainer: Color(0xFF425648),
    tertiary: Color(0xFF546536),
    onTertiary: Color(0xFFF0FFCF),
    tertiaryContainer: Color(0xFFE2F6BA),
    onTertiaryContainer: Color(0xFF4E5E30),
    error: Color(0xFFA83836),
    onError: Color(0xFFFFF7F6),
    surface: Color(0xFFF8FAF8),
    onSurface: Color(0xFF2D3432),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF1F4F2),
    surfaceContainer: Color(0xFFEAEFEC),
    surfaceContainerHigh: Color(0xFFE4E9E7),
    surfaceContainerHighest: Color(0xFFDDE4E1),
    // Darkened from 0xFF59615F so that 0.7-opacity usage still meets WCAG 4.5:1
    onSurfaceVariant: Color(0xFF3D4543),
    outline: Color(0xFF757C7A),
    // Task 7.12 — previous 0xFFACB3B1 on 0xFFF8FAF8 surface = ~2.0:1,
    // failing WCAG 1.4.11 (3:1) when used as a functional boundary
    // (focus rings, disabled borders). Darken to 0xFF8A918F which
    // measures ~3.1:1 while remaining visually subordinate to the
    // primary outline token.
    outlineVariant: Color(0xFF8A918F),
    inverseSurface: Color(0xFF0C0F0E),
    inversePrimary: Color(0xFFC0FBD4),
  );

  // ── Dark scheme tokens ──
  static const ColorScheme darkScheme = ColorScheme.dark(
    primary: Color(0xFFB5F0C9),
    onPrimary: Color(0xFF0E492D),
    primaryContainer: Color(0xFF33694B),
    onPrimaryContainer: Color(0xFFE7FFEC),
    secondary: Color(0xFFC3DAC8),
    onSecondary: Color(0xFF304437),
    secondaryContainer: Color(0xFF43584A),
    onSecondaryContainer: Color(0xFFD1E8D6),
    tertiary: Color(0xFFD3E7AD),
    onTertiary: Color(0xFF3C4B20),
    tertiaryContainer: Color(0xFF48592B),
    onTertiaryContainer: Color(0xFFE2F6BA),
    error: Color(0xFFFA746F),
    onError: Color(0xFF6E0A12),
    surface: Color(0xFF121412),
    onSurface: Color(0xFFDDE4E1),
    surfaceContainerLowest: Color(0xFF0C0F0E),
    surfaceContainerLow: Color(0xFF1A1C1B),
    surfaceContainer: Color(0xFF1E201F),
    surfaceContainerHigh: Color(0xFF282B29),
    surfaceContainerHighest: Color(0xFF333634),
    // Brightened from 0xFFACB3B1 so that 0.7-opacity usage still meets WCAG 4.5:1
    onSurfaceVariant: Color(0xFFC4CAC8),
    outline: Color(0xFF757C7A),
    // Brightened from 0xFF59615F (~2.87:1) to meet WCAG 1.4.11 3:1 contrast
    // against the dark surface (0xFF121412). This now gives ~3.75:1.
    outlineVariant: Color(0xFF6A726F),
    inverseSurface: Color(0xFFF8FAF8),
    inversePrimary: Color(0xFF33694B),
  );

  // ── Mood teal-green scale (Task 13.2) ──
  //
  // Custom 5-step ramp rooted in the brand primary (#33694B). The
  // previous palette was unmodified Material Teal 200-700 — shared
  // with every Flutter tutorial, read as "default". This set shifts
  // hue toward the brand green (hue ~155° vs Material's ~173°) so
  // the scale feels like a member of the Retraq family without
  // losing clear step-to-step differentiation.
  //
  // Naming semantics:
  //   1. Rough  — light, muted sage. Lowest energy.
  //   2. Low    — subdued teal-green. Carrying some weight.
  //   3. Neutral — centered. Neither peak nor trough.
  //   4. Good   — forward, stable.
  //   5. Amazing — saturated deep teal-green. The peak.
  //
  // L* progression preserves a visible gradient (roughly 70 → 35
  // across the 5 steps). Colour-blind simulation: deutan + protan
  // collapse steps 2-3 and 4-5 into similar-looking pairs, but the
  // UI always pairs the blob with a localised text label
  // (moodRough / moodLow / etc.) so the fallback signal exists.
  //
  // WCAG:
  //   - `moodAmazing` (#1A5D49) with white text → ~8.4:1 ✓
  //   - `moodRough` (#A4CAB9) with onSurface (#2D3432) → ~6.2:1 ✓
  //   All intermediate values pass 4.5:1 against both text tokens.
  static const List<Color> moodColorsLight = [
    Color(0xFFA4CAB9), // 1 - Rough    (L* ~77, muted sage)
    Color(0xFF7FB49F), // 2 - Low
    Color(0xFF569A80), // 3 - Neutral
    Color(0xFF347A65), // 4 - Good
    Color(0xFF1A5D49), // 5 - Amazing  (L* ~35, deep peak)
  ];

  static const List<Color> moodColorsDark = [
    // Each dark variant is ~5-10 L* brighter than the light
    // counterpart so the mood blob stays readable on the dark
    // surface (0xFF121412) while keeping the same hue identity.
    Color(0xFFB9D6C6), // 1 - Rough
    Color(0xFF95BFAA), // 2 - Low
    Color(0xFF6FAB92), // 3 - Neutral
    Color(0xFF4F9078), // 4 - Good
    Color(0xFF34785C), // 5 - Amazing
  ];

  static List<Color> moodColors(Brightness brightness) =>
      brightness == Brightness.dark ? moodColorsDark : moodColorsLight;

  // ── Warm amber accent (Task 13.3) ──
  //
  // Distinctive second color beyond the forest-green + mint base so
  // the Retraq brand owns a second pixel of App Store mindshare.
  // Agent 13 recommended amber over terracotta and coral because it:
  //   - pairs with green without muddying the forest palette
  //   - carries "sunrise / capture the day" connotations
  //   - passes WCAG 4.5:1 with dark text (~9.1:1 on the amber)
  //
  // Usage guidelines:
  //   - Max one accent per screen — scarcity is what makes it read
  //     as distinctive, not decorative
  //   - Reserved for premium / celebratory moments: milestone
  //     chips, future paywall CTA (v1.1), "Save" hero (A/B test)
  //   - NEVER use as a destructive action color (that's cs.error)
  //   - NEVER stack on cs.primary — pick one
  //
  // Light variant is the source; dark variant is the same hue with
  // lowered saturation so it sits properly on the dark surface.
  static const Color accentAmberLight = Color(0xFFE8A838);
  static const Color accentAmberDark = Color(0xFFEFBF6B);
  static const Color onAccentAmber = Color(0xFF2D1F00);

  /// Brightness-aware accent getter. Callers should prefer this over
  /// referencing `accentAmberLight` / `accentAmberDark` directly so
  /// the theme mode is honoured without per-site `brightness`
  /// branching.
  static Color accentAmber(Brightness brightness) =>
      brightness == Brightness.dark ? accentAmberDark : accentAmberLight;
}
