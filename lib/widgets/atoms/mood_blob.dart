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

/// A custom blob character for a mood level (1-5).
///
/// Renders the appropriate SVG blob tinted with [color].
/// When [isSelected] becomes true, plays a goopy squish-bounce animation.
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
  late final Animation<double> _scaleX;
  late final Animation<double> _scaleY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Goopy squish: aggressively widen + compress, then wobble back.
    _scaleX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.45,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.45,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _scaleY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.6,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: 1.25,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.25,
          end: 0.92,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.92,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    // If we start in the selected state (e.g., restoring a saved mood), park
    // the controller at the end so the glow halo is visible without playing
    // the squish animation on first frame.
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
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(_scaleX.value, _scaleY.value, 1.0),
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

    // Mood-coloured glow halo whose opacity rides the squish controller —
    // fades up to ~0.65 over the same 600ms the blob takes to settle.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GlowBox(
          color: widget.color,
          glowOpacity: 0.65 * _controller.value.clamp(0.0, 1.0),
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
