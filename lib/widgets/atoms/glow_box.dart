import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// A cheap, GPU-friendly glow wrapper.
///
/// Renders [child] with an outer [BoxShadow] glow. Far cheaper than
/// `BackdropFilter` (no offscreen composite) and can be animated by passing
/// a [glowOpacity] driven by an external [Animation].
///
/// Honors reduce-motion: when reduce-motion is on, no glow is rendered.
class GlowBox extends StatelessWidget {
  const GlowBox({
    super.key,
    required this.child,
    required this.color,
    this.glowOpacity = 0.45,
    this.blurRadius = 24,
    this.spreadRadius = 2,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.enabled = true,
  });

  /// The widget to wrap with the glow.
  final Widget child;

  /// Glow color (alpha is multiplied by [glowOpacity]).
  final Color color;

  /// 0..1 multiplier for glow alpha. Animate this to pulse.
  final double glowOpacity;

  /// Shadow blur radius. Higher = softer/wider glow.
  final double blurRadius;

  /// Shadow spread. Higher = larger glow halo.
  final double spreadRadius;

  /// Required when [shape] is [BoxShape.rectangle]; ignored for circles.
  final BorderRadius? borderRadius;

  /// Match the shape of the child for clean halos.
  final BoxShape shape;

  /// Set false to render the child without any glow (e.g., for state toggles).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || AppMotion.reduce(context) || glowOpacity <= 0.001) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: glowOpacity.clamp(0.0, 1.0)),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A self-pulsing glow that loops on/off using a flutter `AnimationController`.
///
/// One-shot or short-loop only — never infinite if you want `pumpAndSettle`
/// in tests to converge. Set [pulseCount] to a finite number to bound it.
class PulsingGlow extends StatefulWidget {
  const PulsingGlow({
    super.key,
    required this.child,
    required this.color,
    this.minOpacity = 0.15,
    this.maxOpacity = 0.55,
    this.duration = const Duration(milliseconds: 1800),
    this.blurRadius = 28,
    this.spreadRadius = 3,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final Widget child;
  final Color color;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;
  final double blurRadius;
  final double spreadRadius;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeInOut,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = AppMotion.reduce(context);
    if (reduce) {
      _ctrl.stop();
      _ctrl.value = 0.0;
    } else if (!_started) {
      _started = true;
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduce(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final opacity =
            widget.minOpacity +
            (widget.maxOpacity - widget.minOpacity) * _curve.value;
        return GlowBox(
          color: widget.color,
          glowOpacity: opacity,
          blurRadius: widget.blurRadius,
          spreadRadius: widget.spreadRadius,
          borderRadius: widget.borderRadius,
          shape: widget.shape,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}
