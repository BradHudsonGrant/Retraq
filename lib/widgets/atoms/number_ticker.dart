import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// A character-by-character morphing number display.
///
/// Each digit lives in its own clipped vertical strip; when the value
/// changes the strip slides to the new digit using a Material-3 emphasized
/// curve. Reduce-motion fallback is plain text.
///
/// Suitable for medium-frequency value changes (stat cards, milestones).
/// Don't use it for rapidly-updating timers — the per-digit slide is
/// more expensive than a single `TweenAnimationBuilder` for trivial cases.
class NumberTicker extends StatelessWidget {
  const NumberTicker({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve = AppMotion.emphasized,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduce(context)) {
      return Text(value.toString(), style: style);
    }
    final digits = value.toString().split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < digits.length; i++)
          _DigitSlot(
            digit: int.tryParse(digits[i]) ?? 0,
            style: style,
            duration: duration,
            curve: curve,
          ),
      ],
    );
  }
}

class _DigitSlot extends StatelessWidget {
  const _DigitSlot({
    required this.digit,
    required this.style,
    required this.duration,
    required this.curve,
  });

  final int digit;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    // Estimate the digit width using a TextPainter so the slot is fixed.
    final tp = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width;
    final h = tp.height;

    return SizedBox(
      width: w,
      height: h,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: digit.toDouble(), end: digit.toDouble()),
          duration: duration,
          curve: curve,
          builder: (context, animatedDigit, _) {
            // Render the 0..9 column and translate so the requested digit is
            // visible. animatedDigit interpolates between the previous and
            // current target on each rebuild.
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Transform.translate(
                  offset: Offset(0, -animatedDigit * h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 10; i++)
                        SizedBox(
                          width: w,
                          height: h,
                          child: Center(
                            child: Text(i.toString(), style: style),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
