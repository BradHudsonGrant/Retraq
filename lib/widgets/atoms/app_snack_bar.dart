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
  static void show(
    BuildContext context,
    String message, {
    bool error = false,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          backgroundColor: error ? cs.errorContainer : null,
          content: Text(
            message,
            style: error
                ? tt.bodyMedium?.copyWith(color: cs.onErrorContainer)
                : null,
          ),
          action: action,
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
