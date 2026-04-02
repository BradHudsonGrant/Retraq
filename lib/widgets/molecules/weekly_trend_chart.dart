import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// A mini bar chart showing journal entries per week over the last ~12 weeks.
///
/// Bars animate in with a staggered grow-from-bottom effect. The latest bar
/// is fully opaque while older bars are slightly muted. Zero-entry weeks
/// still show a tiny stub so the chart never looks empty.
class WeeklyTrendChart extends StatefulWidget {
  const WeeklyTrendChart({
    super.key,
    required this.data,
    this.height = 120,
  });

  /// Entry counts per week, oldest first. Typically 12 items.
  final List<int> data;

  /// Total height of the bar area (excluding labels).
  final double height;

  @override
  State<WeeklyTrendChart> createState() => _WeeklyTrendChartState();
}

class _WeeklyTrendChartState extends State<WeeklyTrendChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Kick off animation after the first frame so MediaQuery is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disabled = MediaQuery.of(context).disableAnimations;
      if (disabled) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _buildChartLabel() {
    final data = widget.data;
    if (data.isEmpty) return 'Weekly trend chart: no data';
    final total = data.reduce((a, b) => a + b);
    final avg = (total / data.length).toStringAsFixed(1);
    return 'Weekly trend chart: ${data.join(', ')} entries over the last ${data.length} weeks, average $avg per week';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusXxl,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Entries per week',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: _buildChartLabel(),
            excludeSemantics: true,
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(double.infinity, widget.height),
                  painter: _TrendChartPainter(
                    data: widget.data,
                    animationValue: _controller.value,
                    primary: cs.primary,
                    onSurfaceVariant: cs.onSurfaceVariant,
                    outline: cs.outlineVariant,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _Labels(
            count: widget.data.length,
            onSurfaceVariant: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter — bars, average line, accent glow
// ---------------------------------------------------------------------------

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.data,
    required this.animationValue,
    required this.primary,
    required this.onSurfaceVariant,
    required this.outline,
  });

  final List<int> data;
  final double animationValue;
  final Color primary;
  final Color onSurfaceVariant;
  final Color outline;

  static const double _gap = 4;
  static const double _barRadius = 4;
  static const double _stubHeight = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final int count = data.length;
    final double barWidth =
        (size.width - _gap * (count - 1)) / count;
    final int maxVal = data.reduce(math.max);
    final double avg =
        data.isEmpty ? 0 : data.reduce((a, b) => a + b) / data.length;

    // ── Average dashed line ──
    if (maxVal > 0) {
      final double avgY =
          size.height - (avg / maxVal) * size.height;
      _drawDashedLine(canvas, size.width, avgY);
    }

    // ── Bars ──
    for (int i = 0; i < count; i++) {
      // Staggered interval per bar.
      final double start = i / (count * 2);
      final double end = start + (1.0 - start);
      final double t = Interval(start, end, curve: Curves.easeOutCubic)
          .transform(animationValue);

      final double x = i * (barWidth + _gap);
      final bool isLast = i == count - 1;
      final bool isEmpty = data[i] == 0;

      double barHeight;
      if (maxVal == 0) {
        barHeight = _stubHeight;
      } else if (isEmpty) {
        barHeight = _stubHeight;
      } else {
        barHeight = (data[i] / maxVal) * size.height;
        barHeight = math.max(barHeight, _stubHeight);
      }

      barHeight *= t;

      Color barColor;
      if (isEmpty) {
        barColor = primary.withValues(alpha: 0.2);
      } else if (isLast) {
        barColor = primary;
      } else {
        barColor = primary.withValues(alpha: 0.7);
      }

      final RRect rRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
        topLeft: const Radius.circular(_barRadius),
        topRight: const Radius.circular(_barRadius),
      );

      canvas.drawRRect(rRect, Paint()..color = barColor);

      // ── Accent glow on latest bar when it's the highest ──
      if (isLast && data[i] == maxVal && maxVal > 0 && t > 0.5) {
        const double dotRadius = 3.0;
        final double dotCx = x + barWidth / 2;
        final double dotCy = size.height - barHeight - dotRadius - 2;

        // Soft glow.
        canvas.drawCircle(
          Offset(dotCx, dotCy),
          dotRadius + 3,
          Paint()
            ..color = primary.withValues(alpha: 0.25 * t)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        // Solid dot.
        canvas.drawCircle(
          Offset(dotCx, dotCy),
          dotRadius,
          Paint()..color = primary,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, double width, double y) {
    const double dashWidth = 4;
    const double dashGap = 4;
    final paint = Paint()
      ..color = outline.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    double x = 0;
    while (x < width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dashWidth, width), y),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.data != data;
}

// ---------------------------------------------------------------------------
// Bottom labels — show every 3rd week + "Now"
// ---------------------------------------------------------------------------

class _Labels extends StatelessWidget {
  const _Labels({required this.count, required this.onSurfaceVariant});

  final int count;
  final Color onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 10,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(count, (i) {
        final int weeksAgo = count - 1 - i;
        final bool isLast = i == count - 1;

        // Show label for every 3rd position (from the end) plus "Now".
        final bool show = isLast || (weeksAgo > 0 && weeksAgo % 3 == 0);

        final String label =
            isLast ? 'Now' : '${weeksAgo}w';

        return Expanded(
          child: show
              ? Text(
                  label,
                  textAlign: TextAlign.center,
                  style: style,
                )
              : const SizedBox.shrink(),
        );
      }),
    );
  }
}
