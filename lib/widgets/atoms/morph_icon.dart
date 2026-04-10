import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// Smooth crossfade + scale + slight rotate between two icons.
///
/// Used by the bottom navigation bar to swap outline ↔ filled icons with
/// more flair than the default `NavigationBar` crossfade. Honors
/// reduce-motion: when off, instantly swaps icons with no animation.
class MorphIcon extends StatelessWidget {
  const MorphIcon({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    this.size = 24,
    this.color,
    this.duration = AppMotion.base,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final double size;
  final Color? color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduce(context);
    if (reduce) {
      return Icon(selected ? selectedIcon : icon, size: size, color: color);
    }
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: AppMotion.emphasized,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: AppMotion.springSmooth),
          ),
          child: RotationTransition(
            turns: Tween<double>(begin: -0.06, end: 0.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Icon(
        selected ? selectedIcon : icon,
        key: ValueKey(selected),
        size: size,
        color: color,
      ),
    );
  }
}
