import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text.dart';

/// Central theme configuration — all MD3 tokens pulled from the HTML prototypes.
/// Usage: AppTheme.light / AppTheme.dark
class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: AppColors.lightScheme,
        textTheme: AppText.textTheme,
        scaffoldBackgroundColor: AppColors.lightScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightSurfaceContainerLow,
          foregroundColor: AppColors.lightScheme.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.lightScheme.surfaceContainerLowest.withValues(alpha: 0.8),
          indicatorColor: AppColors.lightScheme.primaryContainer,
          labelTextStyle: WidgetStatePropertyAll(
            AppText.labelStyle.copyWith(
              color: AppColors.lightScheme.onSurfaceVariant,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
          elevation: 0,
          color: AppColors.lightScheme.surfaceContainerLow,
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
          backgroundColor: AppColors.lightScheme.surfaceContainerHigh,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          hintStyle: TextStyle(
            color: AppColors.lightScheme.onSurfaceVariant.withValues(alpha: 0.75),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
          ),
          showDragHandle: true,
        ),
      );

  static final ThemeData dark = ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: AppColors.darkScheme,
        textTheme: AppText.textTheme,
        scaffoldBackgroundColor: AppColors.darkScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkScheme.surfaceContainerLow,
          foregroundColor: AppColors.darkScheme.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkScheme.surfaceContainerLow.withValues(alpha: 0.8),
          indicatorColor: AppColors.darkScheme.primaryContainer,
          labelTextStyle: WidgetStatePropertyAll(
            AppText.labelStyle.copyWith(
              color: AppColors.darkScheme.onSurfaceVariant,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusXl),
          elevation: 0,
          color: AppColors.darkScheme.surfaceContainerLow,
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
          backgroundColor: AppColors.darkScheme.surfaceContainerHigh,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          hintStyle: TextStyle(
            color: AppColors.darkScheme.onSurfaceVariant.withValues(alpha: 0.75),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
          ),
          showDragHandle: true,
        ),
      );
}
