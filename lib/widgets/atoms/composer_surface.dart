import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';

/// Focus-responsive bordered container for text composers.
///
/// TitleField and JournalTextArea share the same "recessed well"
/// surface with a primary-tinted border + soft outer halo on focus
/// so both fields feel like one unified composer. This atom is that
/// shared chrome; callers pass the [focusNode] of the inner TextField
/// plus the [child] to render inside.
///
/// - Background: `surfaceContainerLow` — sits below the raised content
///   cards so inputs read as "wells you type into" rather than
///   "cards you review".
/// - Border: `outlineVariant` at alpha 0.3 when resting, `primary` at
///   alpha 0.55 when focused. Width steps 1.0 → 1.4 so the focus state
///   is felt without being shouty.
/// - Shadow: outer `BlurStyle.outer` halo in primary at alpha 0.22,
///   suppressed under reduce-motion.
/// - Transition: 240ms with `AppMotion.standard` — same as the rest of
///   the shell so focus travel between sibling composers feels
///   continuous. Drops to `Duration.zero` under reduce-motion.
class ComposerSurface extends StatefulWidget {
  const ComposerSurface({
    super.key,
    required this.focusNode,
    required this.child,
    this.borderRadius,
  });

  final FocusNode focusNode;
  final Widget child;

  /// Override the resting/focused border radius. Defaults to
  /// `AppSpacing.borderRadiusXl` to match the rest of the card shell.
  final BorderRadius? borderRadius;

  @override
  State<ComposerSurface> createState() => _ComposerSurfaceState();
}

class _ComposerSurfaceState extends State<ComposerSurface> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
    _hasFocus = widget.focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant ComposerSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
      _hasFocus = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (!mounted) return;
    final hasFocus = widget.focusNode.hasFocus;
    if (hasFocus != _hasFocus) {
      setState(() => _hasFocus = hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = AppMotion.reduce(context);

    final borderColor = _hasFocus
        ? cs.primary.withValues(alpha: 0.55)
        : cs.outlineVariant.withValues(alpha: 0.3);

    return AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: widget.borderRadius ?? AppSpacing.borderRadiusXl,
        border: Border.all(color: borderColor, width: _hasFocus ? 1.4 : 1.0),
        boxShadow: [
          if (_hasFocus && !reduceMotion)
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.22),
              blurRadius: 22,
              spreadRadius: 1,
              blurStyle: BlurStyle.outer,
            ),
        ],
      ),
      child: widget.child,
    );
  }
}
