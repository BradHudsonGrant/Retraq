import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Reusable pill-shaped button used across the app.
/// Matches the "Save Entry" style from the Home prototype.
/// Includes a subtle press-scale animation for tactile feedback.
class SinceThenButton extends StatefulWidget {
  const SinceThenButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isOutlined = false,
    this.isSmall = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isSmall;

  @override
  State<SinceThenButton> createState() => _SinceThenButtonState();
}

class _SinceThenButtonState extends State<SinceThenButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null) setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final Widget button;

    if (widget.isOutlined) {
      button = OutlinedButton.icon(
        onPressed: widget.onPressed,
        icon: widget.icon != null
            ? Icon(widget.icon, size: widget.isSmall ? 16 : 20)
            : null,
        label: Text(
          widget.label,
          style: widget.isSmall ? tt.labelSmall : tt.labelLarge,
        ),
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmall ? AppSpacing.md : AppSpacing.lg,
            vertical: widget.isSmall ? AppSpacing.sm : AppSpacing.md,
          ),
        ),
      );
    } else {
      button = FilledButton.icon(
        onPressed: widget.onPressed,
        icon: widget.icon != null
            ? Icon(widget.icon, size: widget.isSmall ? 16 : 20,
                color: cs.onPrimary)
            : null,
        label: Text(
          widget.label,
          style: (widget.isSmall ? tt.labelSmall : tt.labelLarge)
              ?.copyWith(color: cs.onPrimary),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmall ? AppSpacing.md : AppSpacing.lg,
            vertical: widget.isSmall ? AppSpacing.sm : AppSpacing.md,
          ),
          elevation: 2,
        ),
      );
    }

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onPressed != null,
      child: reduceMotion
          ? button
          : GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: AnimatedScale(
                scale: _isPressed ? 0.96 : 1.0,
                duration: Duration(milliseconds: _isPressed ? 80 : 150),
                curve: Curves.easeOut,
                child: button,
              ),
            ),
    );
  }
}
