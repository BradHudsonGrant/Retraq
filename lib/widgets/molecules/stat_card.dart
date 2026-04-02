import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Animated stat card that displays a label, rolling counter, and icon.
///
/// Features a staggered entrance animation (slide + fade) and an animated
/// counter that rolls up from zero. Both animations respect the platform's
/// `disableAnimations` accessibility setting.
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
    final disableAnimations =
        MediaQuery.of(context).disableAnimations;

    final accent = accentColor ?? cs.primary;
    final counterDuration =
        Duration(milliseconds: min(800 + value * 2, 1200));

    // ── Card content ──
    Widget cardContent = Semantics(
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
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Animated counter + optional suffix
          _CounterRow(
            value: value,
            suffix: suffix,
            duration: counterDuration,
            disableAnimations: disableAnimations,
            textTheme: tt,
            colorScheme: cs,
          ),
        ],
      ),
    ));

    // ── Entrance animation ──
    if (disableAnimations) return cardContent;

    return _StaggeredEntrance(
      delay: delay,
      child: cardContent,
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
    required this.disableAnimations,
    required this.textTheme,
    required this.colorScheme,
  });

  final int value;
  final String? suffix;
  final Duration duration;
  final bool disableAnimations;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final valueStyle = textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final suffixStyle = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    if (disableAnimations) {
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(animatedValue.toInt().toString(), style: valueStyle),
            if (suffix != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(suffix!, style: suffixStyle),
            ],
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Staggered entrance — fade + slide from below with configurable delay
// ────────────────────────────────────────────────────────────────────

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({
    required this.delay,
    required this.child,
  });

  final int delay;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance> {
  bool _ready = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay <= 0) {
      _ready = true;
    } else {
      _delayTimer = Timer(Duration(milliseconds: widget.delay), () {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _ready ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress,
          child: FractionalTranslation(
            translation: Offset(0, 0.15 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
