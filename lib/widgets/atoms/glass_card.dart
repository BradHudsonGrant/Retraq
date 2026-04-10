import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// Frosted-glass card with a backdrop blur and a subtle tinted overlay.
///
/// PERFORMANCE WARNING: `BackdropFilter` forces an offscreen composite layer
/// per filter. Use **at most once per visible screen**. For everything else
/// reach for [GlowBox] instead.
///
/// Honors reduce-motion: when reduce-motion is on, falls back to a plain
/// opaque container that approximates the same visual rectangle.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blurSigma = 18,
    this.tintAlpha = 0.18,
    this.borderAlpha = 0.18,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blurSigma;
  final double tintAlpha;
  final double borderAlpha;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduce = AppMotion.reduce(context);

    if (reduce) {
      // Static fallback — keeps layout identical without offscreen compositing.
      return DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: borderRadius,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Padding(padding: padding, child: child),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: tintAlpha),
            borderRadius: borderRadius,
            border: Border.all(
              color: cs.onSurface.withValues(alpha: borderAlpha),
              width: 1,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
