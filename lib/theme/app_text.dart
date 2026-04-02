import 'package:flutter/material.dart';

/// Typography tokens matching the prototypes:
///   Headlines → Lexend (clean, round, ADHD-friendly)
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
        letterSpacing: 0.5,
      );

  static TextTheme get textTheme => const TextTheme(
        // Display
        displayLarge: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 57,
            fontWeight: FontWeight.w700),
        displayMedium: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 45,
            fontWeight: FontWeight.w700),
        displaySmall: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 36,
            fontWeight: FontWeight.w700),

        // Headline
        headlineLarge: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 32,
            fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 28,
            fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 24,
            fontWeight: FontWeight.w600),

        // Title
        titleLarge: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 16,
            fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500),

        // Body
        bodyLarge: TextStyle(
            fontFamily: bodyFamily,
            fontSize: 16,
            fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(
            fontFamily: bodyFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400),
        bodySmall: TextStyle(
            fontFamily: bodyFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400),

        // Label
        labelLarge: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        labelMedium: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500),
        labelSmall: TextStyle(
            fontFamily: headlineFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5),
      );
}
