import 'package:flutter/material.dart';

/// Consistent spacing & radius tokens used across all widgets.
/// Centralised here so changes propagate everywhere.
class AppSpacing {
  AppSpacing._();

  // ── Spacing scale ──
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ── Page padding ──
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: lg);

  // ── Radius tokens (from prototypes' rounded corners) ──
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;  // 1.5rem — cards
  static const double radiusXxl = 32; // 2rem — sections
  static const double radiusFull = 9999;

  static final BorderRadius borderRadiusSm =
      BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd =
      BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg =
      BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl =
      BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusXxl =
      BorderRadius.circular(radiusXxl);
  static final BorderRadius borderRadiusFull =
      BorderRadius.circular(radiusFull);

  // ── Clearance for bottom nav bar overlap ──
  static const double navBarClearance = 100;
}
