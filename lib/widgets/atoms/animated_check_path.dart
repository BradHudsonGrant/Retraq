import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// A checkmark drawn stroke-by-stroke using `Path.computeMetrics` +
/// `extractPath`. Driven by an external [Animation<double>] (0..1) so the
/// caller can sequence it with other animations.
///
/// When [progress.value] is 1.0 a complete check is shown; values below 1
/// reveal a partial stroke. Honors reduce-motion: when reduce-motion is on,
/// always renders the full check (no animated reveal).
class AnimatedCheckPath extends StatelessWidget {
  const AnimatedCheckPath({
    super.key,
    required this.progress,
    required this.color,
    this.size = 44,
    this.strokeWidth = 5,
    this.semanticLabel = 'checkmark',
  });

  final Animation<double> progress;
  final Color color;
  final double size;
  final double strokeWidth;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduce(context);
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) {
            final t = reduce ? 1.0 : progress.value.clamp(0.0, 1.0);
            return CustomPaint(
              painter: _CheckPainter(
                progress: t,
                color: color,
                strokeWidth: strokeWidth,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final h = size.height;

    // Build the check stroke as a relative path inside the box.
    // Two segments: down-right then up-right.
    final path =
        Path()
          ..moveTo(w * 0.20, h * 0.52)
          ..lineTo(w * 0.42, h * 0.74)
          ..lineTo(w * 0.80, h * 0.30);

    // Extract the partial path up to `progress * totalLength`.
    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0.0, (acc, m) => acc + m.length);
    final visibleLength = totalLength * progress;

    final visible = Path();
    var remaining = visibleLength;
    for (final m in metrics) {
      if (remaining <= 0) break;
      final take = remaining.clamp(0.0, m.length);
      visible.addPath(m.extractPath(0, take), Offset.zero);
      remaining -= take;
    }

    // Apply ease so the reveal feels Material-3 emphasized.
    final eased = AppMotion.emphasizedDecelerate.transform(
      progress.clamp(0.0, 1.0),
    );
    final paint =
        Paint()
          ..color = color.withValues(alpha: eased)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = strokeWidth;

    canvas.drawPath(visible, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
