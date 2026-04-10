import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// One-shot particle burst — N particles fly outward from the center,
/// fading and (optionally) falling under gravity, then the controller stops.
///
/// Designed to be triggered programmatically via a [GlobalKey] (call
/// [ParticleBurstState.fire]) or to auto-fire on first build via
/// [autoStart]. Always one-shot — no repeating tickers — so widget tests
/// using `pumpAndSettle` converge cleanly.
///
/// Honors reduce-motion: when reduce-motion is on, [build] returns an empty
/// [SizedBox] and no controller is started.
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.colors,
    this.count = 16,
    this.minRadius = 2,
    this.maxRadius = 6,
    this.minDistance = 40,
    this.maxDistance = 120,
    this.duration = const Duration(milliseconds: 900),
    this.gravity = 60,
    this.autoStart = false,
  });

  /// Each particle samples a random color from this list.
  final List<Color> colors;

  /// Number of particles spawned per burst.
  final int count;

  /// Particle size range (logical px).
  final double minRadius;
  final double maxRadius;

  /// Travel distance range (logical px from center).
  final double minDistance;
  final double maxDistance;

  /// Burst duration.
  final Duration duration;

  /// Gravity strength (logical px applied at t=1.0). 0 = no gravity.
  final double gravity;

  /// Fire automatically when first inserted into the tree.
  final bool autoStart;

  @override
  State<ParticleBurst> createState() => ParticleBurstState();
}

class ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  final Random _rng = Random();
  List<_Particle> _particles = const [];

  AnimationController _ensureCtrl() {
    return _ctrl ??= AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) fire();
      });
    }
  }

  /// Generate a fresh batch of particles and start the controller from 0.
  /// Safe to call repeatedly — each call cancels the previous burst.
  void fire() {
    if (!mounted) return;
    if (AppMotion.reduce(context)) return;
    _particles = List.generate(widget.count, (_) {
      final angle = _rng.nextDouble() * 2 * pi;
      final dist =
          widget.minDistance +
          _rng.nextDouble() * (widget.maxDistance - widget.minDistance);
      final size =
          widget.minRadius +
          _rng.nextDouble() * (widget.maxRadius - widget.minRadius);
      final color = widget.colors[_rng.nextInt(widget.colors.length)];
      return _Particle(
        angle: angle,
        distance: dist,
        size: size,
        color: color,
        delay: _rng.nextDouble() * 0.15,
      );
    });
    _ensureCtrl()
      ..stop()
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduce(context)) return const SizedBox.shrink();
    final ctrl = _ensureCtrl();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          if (_particles.isEmpty || ctrl.value == 0) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            painter: _BurstPainter(
              particles: _particles,
              progress: ctrl.value,
              gravity: widget.gravity,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double delay;
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.delay,
  });
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.particles,
    required this.progress,
    required this.gravity,
  });

  final List<_Particle> particles;
  final double progress;
  final double gravity;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final p in particles) {
      final raw = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (raw <= 0) continue;
      // Ease-out for outward motion.
      final ease = 1 - pow(1 - raw, 3) as double;
      final dx = cos(p.angle) * p.distance * ease;
      final dy = sin(p.angle) * p.distance * ease + (raw * raw * gravity);
      final fadeOut = raw < 0.5 ? 1.0 : (1.0 - (raw - 0.5) * 2);
      final paint =
          Paint()..color = p.color.withValues(alpha: fadeOut.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(cx + dx, cy + dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress ||
      old.particles != particles ||
      old.gravity != gravity;
}
