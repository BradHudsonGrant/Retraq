import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../atoms/retraq_card.dart';

/// A mini bar chart showing journal entries per week over the last ~12 weeks.
///
/// Bars animate in with a staggered grow-from-bottom effect. The latest bar
/// is fully opaque while older bars are slightly muted. Zero-entry weeks
/// still show a tiny stub so the chart never looks empty.
///
/// Each bar column is tappable. When tapped, a brief highlight is shown and
/// [onWeekTapped] fires with the week index (0 = oldest).
class WeeklyTrendChart extends StatefulWidget {
  const WeeklyTrendChart({
    super.key,
    required this.data,
    this.height = 120,
    this.onWeekTapped,
  });

  /// Entry counts per week, oldest first. Typically 12 items.
  final List<int> data;

  /// Total height of the bar area (excluding labels).
  final double height;

  /// Called when a bar column is tapped, with the week index (0 = oldest).
  final ValueChanged<int>? onWeekTapped;

  @override
  State<WeeklyTrendChart> createState() => _WeeklyTrendChartState();
}

class _WeeklyTrendChartState extends State<WeeklyTrendChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Index of the bar currently highlighted by a tap, or -1 for none.
  int _highlightedIndex = -1;

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

  void _onBarTapped(int index) {
    setState(() => _highlightedIndex = index);

    // Clear highlight after a brief moment.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _highlightedIndex = -1);
    });

    widget.onWeekTapped?.call(index);
  }

  /// Build the semantics label for a specific bar.
  String _barSemanticLabel(int index) {
    final data = widget.data;
    final int weeksAgo = data.length - 1 - index;
    final now = DateTime.now();
    final weekStart = now.subtract(
      Duration(days: weeksAgo * 7 + now.weekday - 1),
    );
    final month = _monthAbbr(weekStart.month);
    final count = data[index];
    final entries = count == 1 ? 'entry' : 'entries';
    return 'Week of $month ${weekStart.day}, $count $entries';
  }

  static String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
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

    return RetraqCard(
      color: cs.surfaceContainerHigh,
      outlined: true,
      borderRadius: AppSpacing.borderRadiusXxl,
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
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return SizedBox(
                  height: widget.height,
                  child: Stack(
                    children: [
                      // Painted bars and average line.
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrendChartPainter(
                            data: widget.data,
                            animationValue: _controller.value,
                            primary: cs.primary,
                            onSurfaceVariant: cs.onSurfaceVariant,
                            outline: cs.outlineVariant,
                            highlightedIndex: _highlightedIndex,
                          ),
                        ),
                      ),
                      // Invisible tap targets covering the full column height.
                      Positioned.fill(
                        child: _BarTapTargets(
                          count: widget.data.length,
                          onTap: _onBarTapped,
                          semanticLabelBuilder: _barSemanticLabel,
                        ),
                      ),
                    ],
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
// Tap target row — transparent columns that cover the full bar height
// ---------------------------------------------------------------------------

class _BarTapTargets extends StatelessWidget {
  const _BarTapTargets({
    required this.count,
    required this.onTap,
    required this.semanticLabelBuilder,
  });

  final int count;
  final ValueChanged<int> onTap;
  final String Function(int index) semanticLabelBuilder;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Semantics(
            button: true,
            label: semanticLabelBuilder(i),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: const SizedBox.expand(),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// CustomPainter — bars, average line, accent glow, highlight
// ---------------------------------------------------------------------------

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.data,
    required this.animationValue,
    required this.primary,
    required this.onSurfaceVariant,
    required this.outline,
    this.highlightedIndex = -1,
  });

  final List<int> data;
  final double animationValue;
  final Color primary;
  final Color onSurfaceVariant;
  final Color outline;
  final int highlightedIndex;

  static const double _gap = 4;
  static const double _barRadius = 4;
  static const double _stubHeight = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final int count = data.length;
    final double barWidth = (size.width - _gap * (count - 1)) / count;
    final int maxVal = data.reduce(math.max);
    final double avg =
        data.isEmpty ? 0 : data.reduce((a, b) => a + b) / data.length;

    if (maxVal > 0) {
      final double avgY = size.height - (avg / maxVal) * size.height;
      _drawDashedLine(canvas, size.width, avgY);
    }

    for (int i = 0; i < count; i++) {
      // Staggered interval per bar.
      final double start = i / (count * 2);
      final double end = start + (1.0 - start);
      final double t = Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ).transform(animationValue);

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

      // Brighten the bar when highlighted.
      if (i == highlightedIndex) {
        barColor = Color.lerp(barColor, Colors.white, 0.3)!;
      }

      final RRect rRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
        topLeft: const Radius.circular(_barRadius),
        topRight: const Radius.circular(_barRadius),
      );

      // Soft outer glow halo behind the highlighted bar so the user can see
      // exactly which week they tapped without flashing colours.
      if (i == highlightedIndex) {
        canvas.drawRRect(
          rRect.inflate(2),
          Paint()
            ..color = primary.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      canvas.drawRRect(rRect, Paint()..color = barColor);

      // Accent glow on latest bar when it's the highest
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
    final paint =
        Paint()
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
      oldDelegate.data != data ||
      oldDelegate.highlightedIndex != highlightedIndex;
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
      fontSize: 12,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(count, (i) {
        final int weeksAgo = count - 1 - i;
        final bool isLast = i == count - 1;

        // Show label for every 3rd position (from the end) plus "Now".
        final bool show = isLast || (weeksAgo > 0 && weeksAgo % 3 == 0);

        final String label = isLast ? 'Now' : '${weeksAgo}w';

        return Expanded(
          child:
              show
                  ? Text(label, textAlign: TextAlign.center, style: style)
                  : const SizedBox.shrink(),
        );
      }),
    );
  }
}
