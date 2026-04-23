import 'package:flutter/material.dart';

/// Typography tokens matching the prototypes:
///   Headlines → Lexend (clean, round, optimised for reading proficiency)
///   Body/Labels → Manrope (geometric, highly readable)
///
/// We use fontFamily strings here which work with bundled font assets.
///
/// Text scaling: Flutter's default MediaQuery-based text scaling is used.
/// Do NOT add textScaleFactor overrides or TextScaler.noScaling anywhere
/// in the app — this would break WCAG 2.1 AA compliance (SC 1.4.4, 200%
/// text resize). Fixed-height containers should use flexible sizing to
/// accommodate scaled text.
class AppText {
  AppText._();

  static const String headlineFamily = 'Lexend';
  static const String bodyFamily = 'Manrope';

  static TextStyle get labelStyle => const TextStyle(
    fontFamily: headlineFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: 0.3,
  );

  static TextTheme get textTheme => const TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 57,
      fontWeight: FontWeight.w700,
    ),
    displayMedium: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 45,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 36,
      fontWeight: FontWeight.w700,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation('wght', 600)],
    ),
    headlineMedium: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation('wght', 600)],
    ),
    headlineSmall: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation('wght', 600)],
    ),

    // Title
    titleLarge: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation('wght', 600)],
    ),
    titleMedium: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontVariations: [FontVariation('wght', 500)],
    ),
    titleSmall: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontVariations: [FontVariation('wght', 500)],
    ),

    // Body — w450 via fontVariations for variable font crispness on OLED
    bodyLarge: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontVariations: [FontVariation('wght', 475)],
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontVariations: [FontVariation('wght', 475)],
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      fontVariations: [FontVariation('wght', 475)],
      height: 1.4,
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontVariations: [FontVariation('wght', 500)],
    ),
    labelMedium: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontVariations: [FontVariation('wght', 500)],
    ),
    labelSmall: TextStyle(
      fontFamily: headlineFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontVariations: [FontVariation('wght', 500)],
      letterSpacing: 0.3,
    ),
  );
}
