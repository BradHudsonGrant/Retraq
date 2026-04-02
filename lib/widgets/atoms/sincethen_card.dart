import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Reusable card wrapper matching the prototype rounded card style.
/// Used as the base for entry cards, stat cards, settings groups, etc.
/// Includes a subtle press-scale animation when tappable.
class SinceThenCard extends StatefulWidget {
  const SinceThenCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.elevation = 0,
    this.semanticLabel,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double elevation;

  /// Optional label for screen readers. Used when [onTap] is provided.
  final String? semanticLabel;

  @override
  State<SinceThenCard> createState() => _SinceThenCardState();
}

class _SinceThenCardState extends State<SinceThenCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final card = Container(
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: widget.color ?? cs.surfaceContainerLowest,
        borderRadius: widget.borderRadius ?? AppSpacing.borderRadiusXl,
        boxShadow: widget.elevation > 0
            ? [
                BoxShadow(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;

      return Semantics(
        button: true,
        label: widget.semanticLabel,
        child: FocusableActionDetector(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) { widget.onTap!(); return null; },
            ),
          },
          child: reduceMotion
              ? GestureDetector(
                  onTap: widget.onTap,
                  behavior: HitTestBehavior.opaque,
                  child: card,
                )
              : GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) {
                    setState(() => _isPressed = false);
                    widget.onTap!();
                  },
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: AnimatedScale(
                    scale: _isPressed ? 0.97 : 1.0,
                    duration: Duration(milliseconds: _isPressed ? 80 : 150),
                    curve: Curves.easeOut,
                    child: card,
                  ),
                ),
        ),
      );
    }
    return card;
  }
}
