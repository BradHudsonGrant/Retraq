import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../atoms/glow_box.dart';
import '../atoms/number_ticker.dart';

/// Animated stat card that displays a label, rolling counter, and icon.
///
/// Features a staggered entrance animation (slide + fade + spring scale)
/// powered by `flutter_animate`, and an animated counter that rolls up from
/// zero. For values ≥ 100 the counter switches to a per-digit [NumberTicker]
/// for a slot-machine effect; smaller values keep the cheaper
/// [TweenAnimationBuilder]. The icon halo gently shimmers to add a sense of
/// life. All effects respect the platform's `disableAnimations` accessibility
/// setting and short-circuit cleanly when reduce-motion is on.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.suffix,
    this.accentColor,
    this.delay = 0,
  });

  /// Descriptive label shown above the number (e.g. "Total Entries").
  final String label;

  /// The integer value to animate toward.
  final int value;

  /// Decorative icon shown in the top-right corner.
  final IconData icon;

  /// Optional unit suffix displayed after the number (e.g. "days").
  final String? suffix;

  /// Override color for the icon background and accent. Falls back to
  /// [ColorScheme.primary].
  final Color? accentColor;

  /// Milliseconds to wait before the entrance animation begins.
  /// Use increasing values across sibling cards for a cascade effect.
  final int delay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final reduceMotion = AppMotion.reduce(context);

    final accent = accentColor ?? cs.primary;
    final counterDuration = Duration(milliseconds: min(800 + value * 2, 1200));

    // ── Icon halo (with optional shimmer) ──
    Widget iconHalo = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: accent),
    );
    iconHalo = GlowBox(
      color: accent,
      glowOpacity: 0.35,
      blurRadius: 14,
      spreadRadius: 1,
      shape: BoxShape.circle,
      child: iconHalo,
    );
    if (!reduceMotion) {
      // One-shot shimmer (not looping) so `pumpAndSettle` based tests still
      // converge. Plays once on entrance.
      iconHalo = iconHalo
          .animate(delay: (delay + 600).ms)
          .shimmer(duration: 2600.ms, color: accent.withValues(alpha: 0.55));
    }

    // ── Card content ──
    final Widget cardContent = Semantics(
      label: '$label: $value${suffix != null ? ' $suffix' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: AppSpacing.borderRadiusXl,
          boxShadow: [
            BoxShadow(
              color: cs.onSurface.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon row — icon pinned to the right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                iconHalo,
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Animated counter + optional suffix
            _CounterRow(
              value: value,
              suffix: suffix,
              duration: counterDuration,
              reduceMotion: reduceMotion,
              textTheme: tt,
              colorScheme: cs,
            ),
          ],
        ),
      ),
    );

    // ── Entrance animation ──
    if (reduceMotion) return cardContent;

    return cardContent
        .animate(delay: delay.ms)
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.18,
          end: 0,
          duration: 500.ms,
          curve: AppMotion.emphasizedDecelerate,
        )
        .scaleXY(
          begin: 0.92,
          end: 1.0,
          duration: 520.ms,
          curve: AppMotion.springSmooth,
        );
  }
}

// ────────────────────────────────────────────────────────────────────
// Counter row — animated number with optional suffix
// ────────────────────────────────────────────────────────────────────

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.value,
    required this.suffix,
    required this.duration,
    required this.reduceMotion,
    required this.textTheme,
    required this.colorScheme,
  });

  final int value;
  final String? suffix;
  final Duration duration;
  final bool reduceMotion;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final valueStyle =
        textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700) ??
        const TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
    final suffixStyle = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    if (reduceMotion) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(value.toString(), style: valueStyle),
          if (suffix != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(suffix!, style: suffixStyle),
          ],
        ],
      );
    }

    // For multi-digit values use the per-digit slot machine. For small
    // values the cheaper TweenAnimationBuilder roll-up is plenty.
    final Widget number =
        value >= 100
            ? NumberTicker(value: value, style: valueStyle, duration: duration)
            : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return Text(
                  animatedValue.toInt().toString(),
                  style: valueStyle,
                );
              },
            );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        number,
        if (suffix != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(suffix!, style: suffixStyle),
        ],
      ],
    );
  }
}
