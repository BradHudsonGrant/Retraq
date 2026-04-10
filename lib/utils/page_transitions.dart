import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Thin factory wrappers around the `animations` package's Material 3
/// motion system. Use these in custom `PageRoute` builders or
/// `PageTransitionSwitcher` so transitions stay consistent app-wide.
class AppPageTransitions {
  AppPageTransitions._();

  /// Material 3 fade-through — outgoing fades out, incoming fades in
  /// while scaling slightly. Use for top-level swaps where there's no
  /// spatial relationship between screens.
  static Widget fadeThrough({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    Color? fillColor,
  }) {
    return FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      fillColor: fillColor ?? Colors.transparent,
      child: child,
    );
  }

  /// Material 3 shared-axis — slides + fades along the given axis.
  /// Use for forward/back navigation in a stack.
  static Widget sharedAxis({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
    Color? fillColor,
  }) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: type,
      fillColor: fillColor ?? Colors.transparent,
      child: child,
    );
  }

  /// Build a `PageRoute` that uses fade-through. Drop into `Navigator.push`.
  static PageRoute<T> fadeThroughRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppMotion.slow,
      reverseTransitionDuration: AppMotion.base,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return fadeThrough(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Theme.of(context).colorScheme.surface,
          child: child,
        );
      },
    );
  }

  /// Build a `PageRoute` that uses shared-axis horizontal motion.
  static PageRoute<T> sharedAxisRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppMotion.slow,
      reverseTransitionDuration: AppMotion.base,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return sharedAxis(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          type: type,
          fillColor: Theme.of(context).colorScheme.surface,
          child: child,
        );
      },
    );
  }
}
