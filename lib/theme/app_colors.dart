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
    onSurfaceVariant: Color(0xFF59615F),
    outline: Color(0xFF757C7A),
    outlineVariant: Color(0xFFACB3B1),
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
    onSurfaceVariant: Color(0xFFACB3B1),
    outline: Color(0xFF757C7A),
    outlineVariant: Color(0xFF59615F),
    inverseSurface: Color(0xFFF8FAF8),
    inversePrimary: Color(0xFF33694B),
  );
}
