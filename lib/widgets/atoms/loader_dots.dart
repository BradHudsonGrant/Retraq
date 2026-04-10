import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// Three-dot loader that bounces in sequence — replaces the stock
/// `CircularProgressIndicator` on the splash screen for a more on-brand
/// "alive" feel that's clearly synced with the rest of the screen.
///
/// Honors reduce-motion: when on, renders three static dots without a ticker.
class LoaderDots extends StatefulWidget {
  const LoaderDots({
    super.key,
    this.color,
    this.size = 8,
    this.gap = 6,
    this.duration = const Duration(milliseconds: 1100),
  });

  /// Dot fill color. Defaults to the colorScheme primary.
  final Color? color;

  /// Diameter of each dot.
  final double size;

  /// Gap between dots.
  final double gap;

  /// One full bounce cycle.
  final Duration duration;

  @override
  State<LoaderDots> createState() => _LoaderDotsState();
}

class _LoaderDotsState extends State<LoaderDots>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  AnimationController _ensureCtrl() {
    return _ctrl ??= AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppMotion.reduce(context)) {
      _ensureCtrl();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.color ?? cs.primary;

    if (AppMotion.reduce(context)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
            child: _Dot(color: color, size: widget.size, scale: 1.0),
          );
        }),
      );
    }

    return AnimatedBuilder(
      animation: _ensureCtrl(),
      builder: (context, _) {
        final t = _ensureCtrl().value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot lags by 0.18 of the cycle. Bounces up + scales by
            // sampling a sine over a 0..1 phase window then easing back to 1.
            final phase = ((t - i * 0.18) % 1.0 + 1.0) % 1.0;
            // Cosine bell that peaks at phase 0.5 and is 0 elsewhere.
            final lift = phase < 0.5
                ? Curves.easeOut.transform(phase * 2)
                : Curves.easeIn.transform((1 - phase) * 2);
            final scale = 0.85 + lift * 0.45;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
              child: Transform.translate(
                offset: Offset(0, -lift * 6),
                child: _Dot(
                  color: color,
                  size: widget.size,
                  scale: scale,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.size,
    required this.scale,
  });

  final Color color;
  final double size;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
