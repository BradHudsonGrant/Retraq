import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/app_motion.dart';

/// Detects Flutter test environment so we never start an infinite ticker
/// (which would cause `pumpAndSettle` to time out forever).
bool get _kIsFlutterTest =>
    WidgetsBinding.instance.runtimeType.toString().contains('Test');

/// A drifting mesh-gradient background driven by a single GLSL fragment shader.
///
/// Loads `assets/shaders/mesh.frag`, uniforms `uSize`, `uTime`, `uColor1..3`,
/// and `uBase`. The shader sums three Gaussian color blobs that slowly drift
/// across the canvas, producing a smooth mesh-gradient effect in one shader
/// pass — significantly cheaper than animating multiple `RadialGradient`
/// `Paint`s in a `CustomPainter`.
///
/// Honors reduce-motion: when reduce-motion is on, renders a plain
/// `LinearGradient` of the same colors with no animation.
///
/// Wrap in `Stack` and place behind the screen content. Always wrap the
/// shader-driven version in a `RepaintBoundary` (already done internally).
class AnimatedMeshBackground extends StatefulWidget {
  const AnimatedMeshBackground({
    super.key,
    required this.colors,
    this.baseColor,
    this.opacity = 1.0,
    this.oneShotDuration,
    this.speed = 1.0,
  });

  /// 3 color stops sampled by the shader (mesh blobs).
  final List<Color> colors;

  /// The background tint the mesh fades into. Defaults to surface.
  final Color? baseColor;

  /// Optional outer opacity multiplier 0..1.
  final double opacity;

  /// If non-null, the time uniform stops advancing after this duration —
  /// useful for splash/onboarding where the screen exits soon after.
  final Duration? oneShotDuration;

  /// Multiplier on the time uniform sent to the shader. 1.0 preserves
  /// the shader's own drift frequencies; >1.0 makes the blobs move
  /// faster, <1.0 slower. Exposed so callers can pick a drift speed
  /// that matches how prominent the mesh is in their composition
  /// (quiet ambient layer → lower, hero splash → higher).
  final double speed;

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  double _time = 0;
  Duration? _startedAt;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/mesh.frag',
      );
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader();
      });
      _maybeStartTicker();
    } catch (e) {
      // Shader compile failed (older device, missing asset). The build()
      // method already falls back to a static gradient when _shader is null.
      // Do NOT start the ticker — there's no animation to perform.
      debugPrint('AnimatedMeshBackground shader load failed: $e');
    }
  }

  void _maybeStartTicker() {
    if (!mounted) return;
    if (_shader == null) return;
    if (_stopped) return;
    if (AppMotion.reduce(context)) return;
    // Never run an infinite ticker inside a `flutter test` run — would
    // cause `pumpAndSettle` to time out.
    if (_kIsFlutterTest) return;
    if (_ticker.isActive) return;
    _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = AppMotion.reduce(context);
    if (reduce) {
      if (_ticker.isActive) _ticker.stop();
      return;
    }
    _maybeStartTicker();
  }

  void _onTick(Duration elapsed) {
    _startedAt ??= elapsed;
    final t = (elapsed - _startedAt!).inMicroseconds / 1e6;
    if (widget.oneShotDuration != null &&
        Duration(microseconds: (t * 1e6).toInt()) >= widget.oneShotDuration!) {
      _stopped = true;
      _ticker.stop();
    }
    if (mounted) {
      setState(() => _time = t);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = widget.baseColor ?? cs.surface;

    // Fallback: shader missing, reduce-motion on, or load failed.
    if (_shader == null || AppMotion.reduce(context)) {
      return Opacity(
        opacity: widget.opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  widget.colors[0].withValues(alpha: 0.35),
                  base,
                ),
                base,
                Color.alphaBlend(
                  widget.colors[widget.colors.length - 1].withValues(
                    alpha: 0.35,
                  ),
                  base,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Opacity(
        opacity: widget.opacity,
        child: CustomPaint(
          painter: _MeshShaderPainter(
            shader: _shader!,
            // Scale the time uniform so the same shader can drive a
            // quiet ambient drift (speed < 1) or a more overtly
            // animated hero layer (speed > 1) without editing the
            // shader itself.
            time: _time * widget.speed,
            colors: widget.colors,
            base: base,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MeshShaderPainter extends CustomPainter {
  _MeshShaderPainter({
    required this.shader,
    required this.time,
    required this.colors,
    required this.base,
  });

  final ui.FragmentShader shader;
  final double time;
  final List<Color> colors;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    // Pad colors list to length 3 if shorter (e.g. caller passed 2).
    final c1 = colors.isNotEmpty ? colors[0] : base;
    final c2 = colors.length > 1 ? colors[1] : c1;
    final c3 = colors.length > 2 ? colors[2] : c2;

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, c1.r)
      ..setFloat(4, c1.g)
      ..setFloat(5, c1.b)
      ..setFloat(6, c1.a)
      ..setFloat(7, c2.r)
      ..setFloat(8, c2.g)
      ..setFloat(9, c2.b)
      ..setFloat(10, c2.a)
      ..setFloat(11, c3.r)
      ..setFloat(12, c3.g)
      ..setFloat(13, c3.b)
      ..setFloat(14, c3.a)
      ..setFloat(15, base.r)
      ..setFloat(16, base.g)
      ..setFloat(17, base.b)
      ..setFloat(18, base.a);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshShaderPainter old) {
    return old.time != time || old.colors != colors || old.base != base;
  }
}
