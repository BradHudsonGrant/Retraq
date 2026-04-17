import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// Edge-glow acknowledgement for rejected tab swipes.
///
/// Task 2.12 — AppShell's PageView uses `NeverScrollableScrollPhysics`
/// (tabs are managed by the bottom nav, not swipe). But when a user
/// swipes horizontally on the content area — a common instinct — the
/// app used to silently swallow it, leading users to think the app
/// had frozen. This widget wraps the tab content and pulses a brief
/// teal glow on the target edge when a horizontal drag is detected,
/// giving "we heard you, use the tabs" visual feedback.
///
/// Behavior:
/// - Fires only for horizontal drags with velocity beyond a soft
///   threshold — vertical scrolls pass through untouched
/// - Pulses the LEFT edge for a rightward-intent drag (user wanted
///   to reveal content on the right), and vice versa
/// - Debounced: at most one glow per 800ms so a flurry of taps
///   doesn't strobe
/// - Honours `AppMotion.reduce(context)` — reduce-motion users see
///   no animation and no glow (the feedback would be distracting
///   without serving the main purpose of hinting at tab nav)
class TabSwipeEdgeGlow extends StatefulWidget {
  const TabSwipeEdgeGlow({super.key, required this.child});

  final Widget child;

  @override
  State<TabSwipeEdgeGlow> createState() => _TabSwipeEdgeGlowState();
}

class _TabSwipeEdgeGlowState extends State<TabSwipeEdgeGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  _GlowSide? _glowSide;
  DateTime? _lastFire;

  static const _velocityThreshold = 400.0; // px/sec
  static const _debounce = Duration(milliseconds: 800);
  static const _pulseDuration = Duration(milliseconds: 320);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _pulseDuration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _glowSide = null);
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity.abs() < _velocityThreshold) return;

    // Debounce — strobing is worse than silence.
    final now = DateTime.now();
    if (_lastFire != null && now.difference(_lastFire!) < _debounce) {
      return;
    }
    _lastFire = now;

    // Reduce-motion bypass: skip the glow entirely. The bottom-nav
    // tabs remain the primary navigation signal.
    if (AppMotion.reduce(context)) return;

    // A leftward swipe (negative velocity) means the user expected
    // content to come in from the right → pulse the right edge so
    // the eye is drawn where they tried to reach.
    setState(() => _glowSide = velocity < 0 ? _GlowSide.right : _GlowSide.left);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // GestureDetector sits behind the child via HitTestBehavior
        // .deferToChild so taps + vertical scrolls propagate normally.
        // Only horizontal drags bubble up to us (the inner PageView
        // with NeverScrollableScrollPhysics ignores them).
        GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: widget.child,
        ),
        if (_glowSide != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // Ease in for the first 40%, ease out for the rest —
                  // brief visual ping.
                  final t = _controller.value;
                  final opacity = t < 0.4
                      ? t / 0.4
                      : (1.0 - (t - 0.4) / 0.6);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: _glowSide == _GlowSide.left
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        end: _glowSide == _GlowSide.left
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        colors: [
                          cs.primary.withValues(alpha: 0.22 * opacity),
                          cs.primary.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.35],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

enum _GlowSide { left, right }
