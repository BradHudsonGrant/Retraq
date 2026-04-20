import 'package:flutter/material.dart';

/// Motion design tokens for Retraq.
///
/// Centralised durations, curves, and spring descriptions used across the app
/// so timings stay consistent. Every animation that consumes these tokens
/// should also funnel through [AppMotion.aware] (or check [AppMotion.reduce])
/// so it short-circuits when the user has reduce-motion enabled.
class AppMotion {
  AppMotion._();

  static const Duration instant = Duration.zero;
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration base = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 550);
  static const Duration hero = Duration(milliseconds: 800);
  static const Duration epic = Duration(milliseconds: 1200);

  // The Material 3 emphasized curve is the cubic specified in the spec.
  // We hand-roll it as a Cubic to avoid dependency on the newer `Easing`
  // class which may not exist in older Flutter SDKs.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Sharp ease-out for snappy entrances.
  static const Curve sharp = Curves.easeOutExpo;

  /// Bouncy spring with overshoot — use sparingly (selection pops, milestones).
  static const Curve springBouncy = Curves.elasticOut;

  /// Smooth spring with mild overshoot — the default for "tactile" feel.
  static const Curve springSmooth = Curves.easeOutBack;

  /// Critically damped spring — no overshoot. Use for press-back, drag release.
  static const SpringDescription tactile = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 22,
  );

  /// Bouncy spring — visible overshoot. Use for selection pops, milestones.
  static const SpringDescription bouncy = SpringDescription(
    mass: 1,
    stiffness: 350,
    damping: 14,
  );

  /// Standard delay between cascade items in a list reveal.
  static const Duration staggerStep = Duration(milliseconds: 60);

  /// Tighter stagger for grids (calendar cells, etc.).
  static const Duration staggerStepTight = Duration(milliseconds: 20);

  /// Returns [d] normally, or [Duration.zero] when reduce-motion is enabled.
  ///
  /// Always wrap user-facing durations through this when building widgets so
  /// the platform's "Remove animations" / accessibility settings short-circuit
  /// the animation cleanly.
  static Duration aware(BuildContext context, Duration d) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return d;
    return (mq.disableAnimations || mq.accessibleNavigation)
        ? Duration.zero
        : d;
  }

  /// Returns true when the platform requests reduced motion.
  static bool reduce(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return false;
    return mq.disableAnimations || mq.accessibleNavigation;
  }
}
