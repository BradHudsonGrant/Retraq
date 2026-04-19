import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import 'glow_box.dart';

/// Reusable card wrapper matching the prototype rounded card style.
/// Used as the base for entry cards, stat cards, settings groups, etc.
/// Includes a subtle press-scale animation when tappable.
///
/// The [outlined] flag opts into the shared "content-card tier" look —
/// `surfaceContainerHigh` + a 1px `outlineVariant` hairline at alpha
/// 0.35 — used across StatCard, SettingsRow, RecentDayCard and the
/// rest of the minimal-border card system. Leave it false for the
/// recessed well variant (e.g. nested groups on Home) or when the
/// caller wants to drive the border treatment itself.
class RetraqCard extends StatefulWidget {
  const RetraqCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.elevation = 0,
    this.outlined = false,
    this.semanticLabel,
    this.glowOnTap = false,
    this.glowColor,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double elevation;

  /// When true, paints the shared content-card hairline outline
  /// (`outlineVariant` at alpha 0.35, width 1). Pair with
  /// `color: cs.surfaceContainerHigh` for the canonical tier, or
  /// override `color` for variants. Defaults to false so existing
  /// recessed-well callers keep their borderless appearance.
  final bool outlined;

  /// Optional label for screen readers. Used when [onTap] is provided.
  final String? semanticLabel;

  /// Pulse a [GlowBox] halo for ~400ms after tap.
  final bool glowOnTap;

  /// Glow color override. Defaults to the colorScheme primary.
  final Color? glowColor;

  @override
  State<RetraqCard> createState() => _RetraqCardState();
}

class _RetraqCardState extends State<RetraqCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  AnimationController? _glowCtrl;

  AnimationController _ensureGlowCtrl() {
    return _glowCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _glowCtrl?.dispose();
    super.dispose();
  }

  void _pulseGlow() {
    if (!widget.glowOnTap) return;
    if (AppMotion.reduce(context)) return;
    _ensureGlowCtrl()
      ..stop()
      ..value = 0
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final card = Container(
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: widget.color ?? cs.surfaceContainerLowest,
        borderRadius: widget.borderRadius ?? AppSpacing.borderRadiusXl,
        border: widget.outlined
            ? Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              )
            : null,
        boxShadow:
            widget.elevation > 0
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

    Widget wrapWithGlow(Widget child) {
      if (!widget.glowOnTap) return child;
      final glowCtrl = _ensureGlowCtrl();
      return AnimatedBuilder(
        animation: glowCtrl,
        builder: (context, c) {
          // Bell curve: 0 → 1 → 0 over 400ms.
          final v = glowCtrl.value;
          final pulse = (v < 0.5) ? v * 2 : (1 - v) * 2;
          return GlowBox(
            color: widget.glowColor ?? cs.primary,
            glowOpacity: pulse * 0.55,
            borderRadius: widget.borderRadius ?? AppSpacing.borderRadiusXl,
            blurRadius: 28,
            spreadRadius: 2,
            child: c!,
          );
        },
        child: child,
      );
    }

    if (widget.onTap != null) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;

      return Semantics(
        button: true,
        label: widget.semanticLabel,
        child: FocusableActionDetector(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap!();
                _pulseGlow();
                return null;
              },
            ),
          },
          child:
              reduceMotion
                  ? GestureDetector(
                    onTap: () {
                      widget.onTap!();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: wrapWithGlow(card),
                  )
                  : GestureDetector(
                    onTapDown: (_) => setState(() => _isPressed = true),
                    onTapUp: (_) {
                      setState(() => _isPressed = false);
                      widget.onTap!();
                      _pulseGlow();
                    },
                    onTapCancel: () => setState(() => _isPressed = false),
                    child: AnimatedScale(
                      scale: _isPressed ? 0.97 : 1.0,
                      duration: Duration(milliseconds: _isPressed ? 80 : 200),
                      curve: Curves.easeOutCubic,
                      child: wrapWithGlow(card),
                    ),
                  ),
        ),
      );
    }
    return card;
  }
}
