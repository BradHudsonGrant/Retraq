import 'dart:math' as math;

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

/// Spark-burst tuning. Each mood gets its own count + radius + size
/// ranges so Amazing throws a loud shower while Rough barely sputters
/// a couple of pinpricks.
class _SparkTune {
  const _SparkTune({
    required this.count,
    required this.minRadius,
    required this.maxRadius,
    required this.minSize,
    required this.maxSize,
    required this.alpha,
  });

  final int count;
  final double minRadius;
  final double maxRadius;
  final double minSize;
  final double maxSize;
  final double alpha;
}

/// Full animation recipe for one mood level. Duration + keyframes
/// describe the whole gesture; the list MUST start at t=0 and end at
/// t=1 with both endpoints at the rest pose.
class _MoodAnim {
  const _MoodAnim({
    required this.duration,
    required this.keyframes,
    required this.sparks,
  });
  final Duration duration;
  final List<_Keyframe> keyframes;
  final _SparkTune sparks;
}

const _restPose = _Pose();

/// Per-mood animation recipes.
///
/// The shape of the gesture varies with mood so the tap feels happy or
/// sad by itself — consistent in structure (anticipation → main
/// action → follow-through) but radically different in energy:
///
/// **Amazing (5)** — full 12-principles bounce + big shower of sparks.
/// **Good (4)**   — same shape at 75% intensity, a healthy spray.
/// **Okay (3)**   — centred pop, modest sparks.
/// **Low (2)**    — spreads wide and sinks, a few small sparks.
/// **Rough (1)**  — heavy collapse, only a couple of tiny pinpricks.
const _moodAnimations = <int, _MoodAnim>{
  1: _MoodAnim(
    duration: Duration(milliseconds: 640),
    sparks: _SparkTune(
      count: 3,
      minRadius: 4,
      maxRadius: 10,
      minSize: 0.9,
      maxSize: 1.6,
      alpha: 0.55,
    ),
    keyframes: [
      _Keyframe(0.00, _restPose),
      _Keyframe(
        0.20,
        _Pose(sx: 1.03, sy: 0.96, dy: 1.5),
        curve: Curves.easeIn,
      ),
      _Keyframe(
        0.55,
        _Pose(sx: 1.10, sy: 0.84, dy: 3.5),
        curve: Curves.easeInOut,
      ),
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
    sparks: _SparkTune(
      count: 6,
      minRadius: 6,
      maxRadius: 14,
      minSize: 1.0,
      maxSize: 1.9,
      alpha: 0.65,
    ),
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
    sparks: _SparkTune(
      count: 10,
      minRadius: 8,
      maxRadius: 20,
      minSize: 1.2,
      maxSize: 2.4,
      alpha: 0.75,
    ),
    keyframes: [
      _Keyframe(0.00, _restPose),
      _Keyframe(0.45, _Pose(sx: 1.12, sy: 1.12), curve: Curves.easeOutCubic),
      _Keyframe(1.00, _restPose, curve: Curves.easeOutCubic),
    ],
  ),
  4: _MoodAnim(
    duration: Duration(milliseconds: 560),
    sparks: _SparkTune(
      count: 16,
      minRadius: 10,
      maxRadius: 28,
      minSize: 1.6,
      maxSize: 3.2,
      alpha: 0.85,
    ),
    keyframes: [
      _Keyframe(0.00, _restPose),
      _Keyframe(
        0.12,
        _Pose(sx: 1.04, sy: 0.94, dy: 0.5),
        curve: Curves.easeOut,
      ),
      _Keyframe(
        0.30,
        _Pose(sx: 0.95, sy: 1.14, dy: -2.5),
        curve: Curves.easeOut,
      ),
      _Keyframe(
        0.50,
        _Pose(sx: 1.22, sy: 1.22, dy: -1.5),
        curve: Curves.easeInOut,
      ),
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
    sparks: _SparkTune(
      count: 24,
      minRadius: 12,
      maxRadius: 38,
      minSize: 1.8,
      maxSize: 4.0,
      alpha: 0.95,
    ),
    keyframes: [
      _Keyframe(0.00, _restPose),
      _Keyframe(
        0.10,
        _Pose(sx: 1.07, sy: 0.90, dy: 1.0),
        curve: Curves.easeOut,
      ),
      _Keyframe(
        0.28,
        _Pose(sx: 0.92, sy: 1.22, dy: -5.0),
        curve: Curves.easeOutCubic,
      ),
      _Keyframe(
        0.45,
        _Pose(sx: 1.32, sy: 1.32, dy: -3.0),
        curve: Curves.easeInOut,
      ),
      _Keyframe(
        0.62,
        _Pose(sx: 0.96, sy: 1.05, dy: -0.5),
        curve: Curves.easeInOut,
      ),
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

/// A single spark — pre-computed at generation time so the animation
/// just samples a progress value (no allocations in the hot path).
class _Spark {
  const _Spark({
    required this.angle,
    required this.radius,
    required this.size,
  });
  final double angle;
  final double radius;
  final double size;
}

List<_Spark> _generateSparks(_SparkTune tune, int seed) {
  final rng = math.Random(seed);
  final sparks = <_Spark>[];
  for (var i = 0; i < tune.count; i++) {
    // Evenly-distributed base angle with jitter so the burst looks
    // organic rather than a perfect ring.
    final base = (i / tune.count) * 2 * math.pi;
    final jitter = (rng.nextDouble() - 0.5) * (2 * math.pi / tune.count) * 0.8;
    final angle = base + jitter;
    final radius = tune.minRadius +
        rng.nextDouble() * (tune.maxRadius - tune.minRadius);
    final size =
        tune.minSize + rng.nextDouble() * (tune.maxSize - tune.minSize);
    sparks.add(_Spark(angle: angle, radius: radius, size: size));
  }
  return sparks;
}

/// Paints the spark burst behind the blob. Sparks fly outward and
/// fade from full opacity to 0 across the animation's life.
class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.sparks,
    required this.progress,
    required this.color,
    required this.alpha,
  });

  final List<_Spark> sparks;

  /// 0..1 — shared controller progress. Sparks launch on the first
  /// ~55% of the animation and fade out over the rest.
  final double progress;

  final Color color;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    // Launch arc: 0 → 1 over the first 55% of the animation. This
    // is the outward travel curve. easeOutCubic gives a fast lift
    // then gentle settle.
    final launch =
        Curves.easeOutCubic.transform((progress / 0.55).clamp(0.0, 1.0));
    // Fade: sparks hold full opacity until 30%, then fade to 0 by 100%.
    final fade = progress < 0.30
        ? 1.0
        : (1.0 - ((progress - 0.30) / 0.70)).clamp(0.0, 1.0);
    if (fade <= 0) return;

    final centre = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: alpha * fade);

    for (final spark in sparks) {
      final r = spark.radius * launch;
      final dx = math.cos(spark.angle) * r;
      final dy = math.sin(spark.angle) * r;
      // Sparks shrink a touch as they travel so the burst reads as a
      // natural energy release rather than hard dots.
      final shrink = 0.7 + 0.3 * (1.0 - launch);
      canvas.drawCircle(centre + Offset(dx, dy), spark.size * shrink, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) {
    return old.progress != progress ||
        old.color != color ||
        old.sparks != sparks ||
        old.alpha != alpha;
  }
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
  List<_Spark> _sparks = const [];

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
      // don't replay the pop / sparks on first paint.
      _controller.value = 1.0;
    }
  }

  void _rebuildTracks() {
    final frames = _anim.keyframes;
    _sx = _buildTrack(frames, (p) => p.sx).animate(_controller);
    _sy = _buildTrack(frames, (p) => p.sy).animate(_controller);
    _dy = _buildTrack(frames, (p) => p.dy).animate(_controller);
    // Re-seed sparks off the mood value so each mood gets a distinct
    // but stable burst pattern (no flicker on rebuild).
    _sparks = _generateSparks(_anim.sparks, widget.mood * 977);
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
    // Give the spark painter room to draw beyond the blob bounds.
    // Twice the max radius covers the furthest spark in any mood.
    final sparkPad = _anim.sparks.maxRadius + _anim.sparks.maxSize + 4;
    final canvasSize = displaySize + sparkPad * 2;

    final svg = SizedBox(
      width: displaySize,
      height: displaySize,
      child: SvgPicture.asset(
        asset,
        colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
        width: displaySize,
        height: displaySize,
      ),
    );

    final animatedBlob = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _dy.value),
          // alignment: bottomCenter so the squash looks like the
          // blob is anchored to the floor, not floating free in the
          // middle of the cell.
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(_sx.value, _sy.value, 1.0),
            child: child,
          ),
        );
      },
      child: svg,
    );

    // Stack the sparks behind the blob. CustomPaint gets a canvas
    // larger than the blob so sparks can fly past its edges.
    final withSparks = SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(canvasSize, canvasSize),
                  painter: _SparkPainter(
                    sparks: _sparks,
                    progress: _controller.value,
                    color: widget.color,
                    alpha: _anim.sparks.alpha,
                  ),
                );
              },
            ),
          ),
          animatedBlob,
        ],
      ),
    );

    // No glow halo when not selected.
    if (!widget.isSelected) return withSparks;

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
      child: withSparks,
    );
  }
}
