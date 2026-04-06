import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text.dart';

/// Central theme configuration — all MD3 tokens pulled from the HTML prototypes.
/// Usage: AppTheme.light / AppTheme.dark
class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(
    brightness: Brightness.light,
    colorScheme: AppColors.lightScheme,
    surfaceContainerLow: AppColors.lightSurfaceContainerLow,
    navBarBackground: AppColors.lightScheme.surfaceContainerLowest,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    colorScheme: AppColors.darkScheme,
    surfaceContainerLow: AppColors.darkScheme.surfaceContainerLow,
    navBarBackground: AppColors.darkScheme.surfaceContainerLow,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color surfaceContainerLow,
    required Color navBarBackground,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: AppText.textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainerLow,
        foregroundColor: colorScheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBackground.withValues(alpha: 0.8),
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          AppText.labelStyle.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        backgroundColor: colorScheme.surfaceContainerHigh,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl),
          ),
        ),
        showDragHandle: true,
      ),
    );
  }
}
