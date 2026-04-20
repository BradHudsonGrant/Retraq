import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../atoms/glow_box.dart';

/// Onboarding / pager dot indicators.
///
/// Each dot is ALWAYS wrapped in the same `GlowBox > AnimatedContainer`
/// structure regardless of active state — only the glow opacity, fill colour
/// and width animate. This avoids the parent-tree shift that previously
/// caused the active dot's `AnimatedContainer` to be re-mounted on every
/// page change (which made the size jump abruptly instead of animating
/// "along" with the page transition).
///
/// Each dot carries a stable `ValueKey('page_indicator_dot_$i')` so widget
/// tests can target dots without depending on `AnimatedContainer` instance
/// counts (which other animation layers can perturb).
class PageIndicatorDots extends StatelessWidget {
  const PageIndicatorDots({
    super.key,
    required this.count,
    required this.current,
  });
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = AppMotion.reduce(context);
    final dur = AppMotion.aware(context, const Duration(milliseconds: 280));
    final radius = BorderRadius.circular(AppSpacing.borderRadiusFull.topLeft.x);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;

        // Always-present GlowBox with animated opacity prevents the
        // AnimatedContainer from being reparented when active state flips.
        Widget dot = GlowBox(
          color: cs.primary,
          glowOpacity: active ? 0.55 : 0.0,
          blurRadius: 16,
          spreadRadius: 1,
          borderRadius: radius,
          child: AnimatedContainer(
            key: ValueKey('page_indicator_dot_$i'),
            duration: dur,
            curve: AppMotion.emphasized,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              // inactive dots previously used alpha 0.3 on
              // onSurfaceVariant, yielding ~2.0:1 contrast on the light
              // surface and failing WCAG 1.4.11 (3:1 minimum for non-text
              // UI state indicators). `outline` is the Material 3 token
              // designed for this exact use (functional boundaries /
              // distinguishable-but-secondary UI) and meets 3:1 on both
              // light and dark surfaces.
              color: active ? cs.primary : cs.outline,
              borderRadius: radius,
            ),
          ),
        );

        if (active && !reduceMotion) {
          // One-shot ping-pong scale: grow then settle. Restarts every time
          // the dot transitions from inactive → active because the wrapping
          // Animate widget is freshly inserted (keyed by `current`).
          dot = dot
              .animate(key: ValueKey('dot_pop_$current'))
              .scaleXY(
                begin: 1.0,
                end: 1.18,
                duration: 220.ms,
                curve: AppMotion.springSmooth,
              )
              .then()
              .scaleXY(
                begin: 1.18,
                end: 1.0,
                duration: 220.ms,
                curve: Curves.easeOut,
              );
        }
        return dot;
      }),
    );
  }
}
