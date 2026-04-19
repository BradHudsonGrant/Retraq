import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';

/// A two-option segmented pill toggle with a sliding highlight.
/// The active indicator slides left/right with a fast, satisfying animation.
class SegmentedPill extends StatefulWidget {
  const SegmentedPill({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.isRightActive,
    required this.onTapLeft,
    required this.onTapRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool isRightActive;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;

  @override
  State<SegmentedPill> createState() => _SegmentedPillState();
}

class _SegmentedPillState extends State<SegmentedPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: widget.isRightActive ? 1.0 : 0.0,
    );
    // Material 3 emphasized-decelerate gives a spring-like landing without
    // overshoot — important so the highlight never escapes the pill bounds.
    _slide = CurvedAnimation(
      parent: _ctrl,
      curve: AppMotion.emphasizedDecelerate,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl.duration =
        AppMotion.aware(context, const Duration(milliseconds: 360));
  }

  @override
  void didUpdateWidget(SegmentedPill old) {
    super.didUpdateWidget(old);
    if (old.isRightActive != widget.isRightActive) {
      if (widget.isRightActive) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _vPad = AppSpacing.sm + 2;
  static const _hPad = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final textAnimDuration =
        AppMotion.aware(context, const Duration(milliseconds: 150));

    final labelStyle = tt.labelLarge!.copyWith(
      fontWeight: FontWeight.w500,
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    );

    // Measure both labels to find the wider one, then use that width for both.
    final textDirection = Directionality.of(context);
    final leftTp = TextPainter(
      text: TextSpan(text: widget.leftLabel, style: labelStyle),
      textDirection: textDirection,
    )..layout();
    final rightTp = TextPainter(
      text: TextSpan(text: widget.rightLabel, style: labelStyle),
      textDirection: textDirection,
    )..layout();

    final maxTextWidth =
        leftTp.width > rightTp.width ? leftTp.width : rightTp.width;
    final segmentWidth = maxTextWidth + _hPad * 2;

    leftTp.dispose();
    rightTp.dispose();

    return Semantics(
      label: '${widget.leftLabel} or ${widget.rightLabel}',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Stack(
          children: [
            // 1) Sliding highlight (bottom layer)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _slide,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _HighlightPainter(
                        progress: _slide.value,
                        color: cs.surfaceContainerLowest,
                        shadowColor: cs.onSurface.withValues(alpha: 0.06),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2) Labels — each segment has identical width
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label: widget.leftLabel,
                  selected: !widget.isRightActive,
                  child: InkWell(
                    onTap: widget.onTapLeft,
                    borderRadius: AppSpacing.borderRadiusFull,
                    child: SizedBox(
                      width: segmentWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: _vPad),
                        child: AnimatedDefaultTextStyle(
                          duration: textAnimDuration,
                          style: labelStyle.copyWith(
                            color:
                                !widget.isRightActive
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                          ),
                          child: Text(
                            widget.leftLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: widget.rightLabel,
                  selected: widget.isRightActive,
                  child: InkWell(
                    onTap: widget.onTapRight,
                    borderRadius: AppSpacing.borderRadiusFull,
                    child: SizedBox(
                      width: segmentWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: _vPad),
                        child: AnimatedDefaultTextStyle(
                          duration: textAnimDuration,
                          style: labelStyle.copyWith(
                            color:
                                widget.isRightActive
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                          ),
                          child: Text(
                            widget.rightLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.progress,
    required this.color,
    required this.shadowColor,
  });

  /// 0.0 = left active, 1.0 = right active
  final double progress;
  final Color color;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final halfWidth = size.width / 2;
    final left = progress * halfWidth;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 0, halfWidth, size.height),
      const Radius.circular(9999),
    );

    // Subtle shadow
    canvas.drawRRect(
      rect.shift(const Offset(0, 1)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Highlight fill
    canvas.drawRRect(rect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.shadowColor != shadowColor;
}
