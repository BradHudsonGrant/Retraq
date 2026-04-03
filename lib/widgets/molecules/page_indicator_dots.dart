import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class PageIndicatorDots extends StatelessWidget {
  const PageIndicatorDots({super.key, required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final dur = reduceMotion ? Duration.zero : const Duration(milliseconds: 200);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: dur,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull.topLeft.x),
          ),
        );
      }),
    );
  }
}
