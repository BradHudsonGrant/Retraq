import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Task 1.7 — Centralised SnackBar helper.
///
/// The app previously recreated the same SnackBar styling (floating
/// behavior + AppSpacing.borderRadiusLg + error-variant background) at
/// 40+ call sites. Any visual-system change required a sweep; a few
/// sites had already drifted. This helper is the single source of
/// truth.
///
/// Public API:
///  - [AppSnackBar.show] — plain message, optional action + duration.
///  - [AppSnackBar.error] — shorthand for the error-container variant.
///
/// Callers should pass a [ScaffoldMessengerState]-hosted [BuildContext];
/// the helper calls [ScaffoldMessenger.of] internally and hides any
/// in-flight SnackBar before showing the next so rapid re-shows don't
/// queue up.
class AppSnackBar {
  const AppSnackBar._();

  /// Show a standard floating SnackBar.
  ///
  /// When [error] is true, the SnackBar uses the theme's errorContainer
  /// background with onErrorContainer foreground — matching the
  /// previous inline `Theme.of(context).colorScheme.errorContainer`
  /// pattern.
  ///
  /// Non-error toasts adopt Retraq's brand: the surfaceContainerHighest
  /// fill with a 1px primary-tinted outline gives the toast a quiet
  /// chip-like presence that sits on top of the gradient without
  /// fighting it. Matches the pill / card shapes used across the rest
  /// of the app.
  static void show(
    BuildContext context,
    String message, {
    bool error = false,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final textStyle = error
        ? tt.bodyMedium?.copyWith(
            color: cs.onErrorContainer,
            fontWeight: FontWeight.w500,
          )
        : tt.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
            side: BorderSide(
              color: error
                  ? cs.error.withValues(alpha: 0.32)
                  : cs.primary.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          backgroundColor: error
              ? cs.errorContainer
              : cs.surfaceContainerHighest,
          content: Text(message, style: textStyle),
          action: action,
          actionOverflowThreshold: 0.25,
          duration: duration,
        ),
      );
  }

  /// Convenience shorthand for the error-variant SnackBar. Identical
  /// to [show] with `error: true`.
  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, error: true, action: action, duration: duration);
  }
}
