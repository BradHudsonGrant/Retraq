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

/// A single pose in the blob's selection animation. Each pose holds a
/// separate X/Y scale + Y-offset so we can do real squash-and-stretch
/// with (approximately) conserved volume plus a touch of secondary
/// translation — the 12-principles basics that make a tap feel like
/// animation rather than a canned scale tween.
class _Pose {
  const _Pose({this.sx = 1, this.sy = 1, this.dy = 0});
  final double sx;
  final double sy;
  final double dy;
}

/// A pose interpolates into the next pose at a given normalized time
/// with a given easing curve.
class _Keyframe {
  const _Keyframe(this.t, this.pose, {this.curve = Curves.linear});
  final double t;
  final _Pose pose;
  final Curve curve;
}

/// Full animation recipe for one mood level. Duration + keyframes
/// describe the whole gesture; the list MUST start at t=0 and end at
/// t=1 with both endpoints at the rest pose.
class _MoodAnim {
  const _MoodAnim({required this.duration, required this.keyframes});
  final Duration duration;
  final List<_Keyframe> keyframes;
}

const _restPose = _Pose();

/// Per-mood animation recipes.
///
/// The shape of the gesture varies with mood so the tap feels happy or
/// sad by itself — consistent in structure (anticipation → main
/// action → follow-through) but radically different in energy:
///
/// **Amazing (5)** — full 12-principles bounce.
///   1. Anticipation: slight squash down + tiny sink (it's winding up)
///   2. Main action: vertical stretch + leap upward (dy negative)
///   3. Peak: volumetric round-out at max scale
///   4. Follow-through: two diminishing elastic wobbles before rest
///
/// **Good (4)** — the same shape at 75% intensity: smaller anticipation,
/// shorter hang-time, single rebound instead of two.
///
/// **Okay (3)** — a centred, symmetric pop. No anticipation, no
/// translation; just a gentle scale swell and return. Baseline energy.
///
/// **Low (2)** — inverted: the blob *spreads wide and sinks* on the
/// main action (sy < 1, dy positive), settles back heavily with no
/// overshoot. Reads "tired".
///
/// **Rough (1)** — the fullest sad version: deeper sag, wider spread,
/// bigger downward translation, slow return. Reads "collapsing under
/// its own weight".
const _moodAnimations = <int, _MoodAnim>{
  1: _MoodAnim(
    duration: Duration(milliseconds: 640),
    keyframes: [
      _Keyframe(0.00, _restPose),
      // Initial give — the blob already looks like it can't hold
      // itself up. Slight sink + tiny horizontal spread.
      _Keyframe(
        0.20,
        _Pose(sx: 1.03, sy: 0.96, dy: 1.5),
        curve: Curves.easeIn,
      ),
      // Bottom of the sag — wider still, much shorter, clearly
      // sitting lower.
      _Keyframe(
        0.55,
        _Pose(sx: 1.10, sy: 0.84, dy: 3.5),
        curve: Curves.easeInOut,
      ),
      // Slow reluctant recovery — volume restores but the motion is
      // draggy, no overshoot.
      _Keyframe(
        0.85,
        _Pose(sx: 1.02, sy: 0.97, dy: 0.8),
        curve: Curves.easeOutCubic,
      ),
      _Keyframe(1.00, _restPose, curve: Curves.easeOut),
    ],
  ),
  2: _MoodAnim(
    duration: Duration(milliseconds: 540),
    keyframes: [
      _Keyframe(0.00, _restPose),
      _Keyframe(
        0.30,
        _Pose(sx: 1.05, sy: 0.92, dy: 2.0),
        curve: Curves.easeInOut,
      ),
      _Keyframe(
        0.70,
        _Pose(sx: 1.01, sy: 0.97, dy: 0.4),
        curve: Curves.easeOutCubic,
      ),
      _Keyframe(1.00, _restPose, curve: Curves.easeOut),
    ],
  ),
  3: _MoodAnim(
    duration: Duration(milliseconds: 420),
    keyframes: [
      _Keyframe(0.00, _restPose),
      // Centred pop — symmetric scale, no translation. Baseline.
      _Keyframe(0.45, _Pose(sx: 1.12, sy: 1.12), curve: Curves.easeOutCubic),
      _Keyframe(1.00, _restPose, curve: Curves.easeOutCubic),
    ],
  ),
  4: _MoodAnim(
    duration: Duration(milliseconds: 560),
    keyframes: [
      _Keyframe(0.00, _restPose),
      // Small anticipation squash.
      _Keyframe(
        0.12,
        _Pose(sx: 1.04, sy: 0.94, dy: 0.5),
        curve: Curves.easeOut,
      ),
      // Stretch-up on the way to the peak — vertical emphasis.
      _Keyframe(
        0.30,
        _Pose(sx: 0.95, sy: 1.14, dy: -2.5),
        curve: Curves.easeOut,
      ),
      // Peak — volumetric.
      _Keyframe(
        0.50,
        _Pose(sx: 1.22, sy: 1.22, dy: -1.5),
        curve: Curves.easeInOut,
      ),
      // One rebound dip before rest.
      _Keyframe(
        0.75,
        _Pose(sx: 1.02, sy: 0.98),
        curve: Curves.easeOutCubic,
      ),
      _Keyframe(1.00, _restPose, curve: Curves.easeOutCubic),
    ],
  ),
  5: _MoodAnim(
    duration: Duration(milliseconds: 720),
    keyframes: [
      _Keyframe(0.00, _restPose),
      // Anticipation: the blob squashes down like it's loading a jump.
      _Keyframe(
        0.10,
        _Pose(sx: 1.07, sy: 0.90, dy: 1.0),
        curve: Curves.easeOut,
      ),
      // Stretch-up: narrow + tall, leaping.
      _Keyframe(
        0.28,
        _Pose(sx: 0.92, sy: 1.22, dy: -5.0),
        curve: Curves.easeOutCubic,
      ),
      // Peak: big round volumetric moment up high.
      _Keyframe(
        0.45,
        _Pose(sx: 1.32, sy: 1.32, dy: -3.0),
        curve: Curves.easeInOut,
      ),
      // First rebound — counter-squash on the way down.
      _Keyframe(
        0.62,
        _Pose(sx: 0.96, sy: 1.05, dy: -0.5),
        curve: Curves.easeInOut,
      ),
      // Second rebound — diminishing elastic wobble.
      _Keyframe(
        0.80,
        _Pose(sx: 1.08, sy: 0.96),
        curve: Curves.easeInOut,
      ),
      _Keyframe(
        0.92,
        _Pose(sx: 0.98, sy: 1.02),
        curve: Curves.easeOutCubic,
      ),
      _Keyframe(1.00, _restPose, curve: Curves.easeOutCubic),
    ],
  ),
};

/// Builds a `TweenSequence<double>` from keyframe → keyframe by
/// picking one field per tween. The weights come from the gap
/// between consecutive keyframes so the timing matches the
/// keyframe list exactly.
TweenSequence<double> _buildTrack(
  List<_Keyframe> keyframes,
  double Function(_Pose) field,
) {
  final items = <TweenSequenceItem<double>>[];
  for (var i = 0; i < keyframes.length - 1; i++) {
    final a = keyframes[i];
    final b = keyframes[i + 1];
    final weight = (b.t - a.t) * 1000;
    if (weight <= 0) continue;
    items.add(
      TweenSequenceItem(
        tween: Tween(
          begin: field(a.pose),
          end: field(b.pose),
        ).chain(CurveTween(curve: b.curve)),
        weight: weight,
      ),
    );
  }
  return TweenSequence<double>(items);
}

/// A silhouette-as-emotion mood glyph for a mood level (1-5).
///
/// Static posture comes from the SVG. Dynamic character comes from a
/// per-mood multi-track tween (see [_moodAnimations]) applied on
/// selection: happy moods pop up with anticipation + follow-through
/// wobbles, sad moods sag wide and slow-settle without overshoot.
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
  late AnimationController _controller;
  late Animation<double> _sx;
  late Animation<double> _sy;
  late Animation<double> _dy;

  _MoodAnim get _anim =>
      _moodAnimations[widget.mood.clamp(1, 5)] ?? _moodAnimations[3]!;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _anim.duration);
    _rebuildTracks();

    if (widget.isSelected) {
      // Mount already-selected (restoring saved mood) — park the
      // controller at end so the glow halo shows immediately and we
      // don't replay the pop on first paint.
      _controller.value = 1.0;
    }
  }

  void _rebuildTracks() {
    final frames = _anim.keyframes;
    _sx = _buildTrack(frames, (p) => p.sx).animate(_controller);
    _sy = _buildTrack(frames, (p) => p.sy).animate(_controller);
    _dy = _buildTrack(frames, (p) => p.dy).animate(_controller);
  }

  @override
  void didUpdateWidget(MoodBlob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _controller.duration = _anim.duration;
      _rebuildTracks();
    }
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
        return Transform.translate(
          offset: Offset(0, _dy.value),
          // alignment: bottomCenter so the squash looks like the
          // blob is anchored to the floor, not floating free in the
          // middle of the cell.
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(
              _sx.value,
              _sy.value,
              1.0,
            ),
            child: child,
          ),
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

    // Mood-coloured glow halo — opacity rides the same controller so
    // it fades up in sync with the pop.
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
