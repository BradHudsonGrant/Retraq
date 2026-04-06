import 'package:flutter/material.dart';

/// Wraps any widget with a satisfying press-down scale animation.
/// Scales to [pressScale] on touch, springs back on release.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;
  bool _isFocused = false;

  void _onFocusChange(bool focused) {
    setState(() => _isFocused = focused);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final reduceMotion = mq.disableAnimations || mq.accessibleNavigation;
    final cs = Theme.of(context).colorScheme;

    return FocusableActionDetector(
      enabled: widget.onTap != null,
      mouseCursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onFocusChange: _onFocusChange,
      child: GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: (_isPressed && !reduceMotion) ? widget.pressScale : 1.0,
        duration: reduceMotion
            ? Duration.zero
            : Duration(milliseconds: _isPressed ? 80 : 150),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: _isFocused
                ? Border.all(color: cs.primary, width: 2)
                : null,
          ),
          child: widget.child,
        ),
      ),
    ));
  }
}
