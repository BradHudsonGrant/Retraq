import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'glow_box.dart';

/// Maps mood values (1-5) to their SVG asset paths.
const _moodAssets = {
  1: 'assets/images/moods/mood_1_rough.svg',
  2: 'assets/images/moods/mood_2_meh.svg',
  3: 'assets/images/moods/mood_3_okay.svg',
  4: 'assets/images/moods/mood_4_good.svg',
  5: 'assets/images/moods/mood_5_amazing.svg',
};

/// A silhouette-as-emotion mood glyph for a mood level (1-5).
///
/// The SVG assets themselves now do the emotional lifting — each mood
/// is a distinct silhouette (downward droplet → flat pill → circle →
/// upward droplet → sparkle) so the shape is legible at any size
/// without relying on tiny face details. This widget is responsible
/// only for tinting, resizing, and a short pop-on-select animation.
///
/// Selection animation is intentionally minimal: a brief elastic
/// scale-up so the tap feels responsive, no goopy squash-and-stretch.
/// The added glow halo carries most of the "you picked this one"
/// signal; the scale is just a reinforcing pulse.
class MoodBlob extends StatefulWidget {
  final int mood;
  final double size;
  final Color color;
  final bool isSelected;

  const MoodBlob({
    super.key,
    required this.mood,
    this.size = 32,
    required this.color,
    this.isSelected = false,
  });

  @override
  State<MoodBlob> createState() => _MoodBlobState();
}

class _MoodBlobState extends State<MoodBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // Single-knob minimal animation: scale overshoots slightly on
    // select, then settles via elasticOut. No separate X/Y axes,
    // no multi-phase squish — the glyph just "pops" into place.
    _pop = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.18,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_controller);

    // If we mount already-selected (restoring a saved mood), skip the
    // pop animation — no surprise motion on first paint — and park
    // the halo at full opacity.
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MoodBlob oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.isSelected && !oldWidget.isSelected && !reduceMotion) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _moodAssets[widget.mood.clamp(1, 5)]!;
    final selectedSize = widget.size * 1.15;
    final displaySize = widget.isSelected ? selectedSize : widget.size;

    final blob = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pop.value,
          child: child,
        );
      },
      child: SizedBox(
        width: displaySize,
        height: displaySize,
        child: SvgPicture.asset(
          asset,
          colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
          width: displaySize,
          height: displaySize,
        ),
      ),
    );

    // No glow halo when not selected.
    if (!widget.isSelected) return blob;

    // Mood-coloured glow halo rides the same controller so it fades
    // up in sync with the pop.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GlowBox(
          color: widget.color,
          glowOpacity: 0.6 * _controller.value.clamp(0.0, 1.0),
          blurRadius: 28,
          spreadRadius: 6,
          shape: BoxShape.circle,
          child: child!,
        );
      },
      child: blob,
    );
  }
}
