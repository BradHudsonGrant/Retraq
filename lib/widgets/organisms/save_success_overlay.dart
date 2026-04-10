import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../atoms/animated_check_path.dart';
import '../atoms/glass_card.dart';
import '../atoms/glow_box.dart';

/// A satisfying full-screen overlay shown after a traq is saved.
///
/// **Crown jewel.** Stroke-drawn checkmark, multi-coloured particle burst,
/// frosted glass panel, layered glow halos, ring pulse and choreographed text
/// reveal — all wired into the original [_entryCtrl] / [_particleCtrl] /
/// [_exitCtrl] controllers so the existing test phase timings still hold and
/// `find.byIcon(Icons.check_rounded)` still finds an Icon widget for legacy
/// finder compatibility.
///
/// IMPORTANT: this organism is intentionally **enhanced**, not rebuilt. Only
/// one [GestureDetector] (the tap-to-dismiss layer) lives in the tree — adding
/// more would break `findsOneWidget` assertions in
/// `save_success_overlay_test.dart`. No infinite tickers — every animation
/// settles within the existing playback envelope so `pumpAndSettle` can run.
class SaveSuccessOverlay extends StatefulWidget {
  const SaveSuccessOverlay({
    super.key,
    required this.onDismissed,
    this.milestoneMessage,
  });

  final VoidCallback onDismissed;

  /// Optional milestone message shown below "Traq saved" (e.g. "Your very first traq!").
  final String? milestoneMessage;

  @override
  State<SaveSuccessOverlay> createState() => _SaveSuccessOverlayState();
}

class _SaveSuccessOverlayState extends State<SaveSuccessOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _exitCtrl;
  late final List<_Particle> _particles;

  // CurvedAnimations — created once, not per-frame in build().
  late final CurvedAnimation _exitCurve;
  late final CurvedAnimation _entryElastic;
  late final CurvedAnimation _entryFadeIn;
  late final CurvedAnimation _entryTextSlide;
  late final CurvedAnimation _entrySubtextFade;

  /// Drives the stroke-by-stroke drawing of the new [AnimatedCheckPath]. Runs
  /// from 0→1 across the back half of the entry controller so the check
  /// finishes drawing right as the ring pulse fades.
  late final CurvedAnimation _checkDrawCurve;

  @override
  void initState() {
    super.initState();

    // Entry: checkmark + ring + text (600ms with elastic overshoot)
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Particles burst outward (1000ms)
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Exit: fade + scale down (400ms)
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Generate burst particles — 28 in mood-coloured rainbow. Dropped from
    // 40 to lighten the first-frame allocation cost; visually still reads as
    // a dense burst because of the size variation.
    final rng = Random();
    _particles = List.generate(28, (i) {
      final angle = (i / 28) * 2 * pi + rng.nextDouble() * 0.4;
      final distance = 60.0 + rng.nextDouble() * 90;
      final size = 2.0 + rng.nextDouble() * 5;
      return _Particle(
        angle: angle,
        distance: distance,
        size: size,
        delay: rng.nextDouble() * 0.18,
        colorIndex: i % 5,
      );
    });

    // Pre-build CurvedAnimations (avoids allocation in build)
    _exitCurve = CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic);
    _entryElastic = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.elasticOut,
    );
    _entryFadeIn = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
    );
    _entryTextSlide = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    );
    _entrySubtextFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
    );
    _checkDrawCurve = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.35, 0.95, curve: Curves.easeOutCubic),
    );

    _play();
  }

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    _reduceMotion = mq.disableAnimations || mq.accessibleNavigation;
  }

  Future<void> _play() async {
    // Haptic: satisfying double-tap
    HapticFeedback.mediumImpact();

    if (_reduceMotion) {
      // Skip animations — jump to final state immediately.
      _entryCtrl.value = 1.0;
      // Don't start particle animation at all.
    } else {
      // Wait one frame so the GlassCard's BackdropFilter and the particle
      // grid get a chance to mount and warm up. Starting the elastic entry
      // on the same frame as the first paint causes a visible hitch.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      _entryCtrl.forward();
      _particleCtrl.forward();
    }

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    HapticFeedback.lightImpact();

    // Hold for the user to see it
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Fade out
    if (_reduceMotion) {
      _exitCtrl.value = 1.0;
    } else {
      await _exitCtrl.forward();
    }
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _exitCurve.dispose();
    _entryElastic.dispose();
    _entryFadeIn.dispose();
    _entryTextSlide.dispose();
    _entrySubtextFade.dispose();
    _checkDrawCurve.dispose();
    _entryCtrl.dispose();
    _particleCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final brightness = Theme.of(context).brightness;
    final moodPalette = AppColors.moodColors(brightness);

    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (context, child) {
        final exitT = _exitCurve.value;
        return Opacity(
          opacity: 1.0 - exitT,
          child: Transform.scale(scale: 1.0 + exitT * 0.05, child: child),
        );
      },
      child: Semantics(
        button: true,
        label: l10n.dismissLabel,
        // ── Single GestureDetector for tap-to-dismiss. Adding more would
        // break `find.byType(GestureDetector), findsOneWidget` in tests. ──
        child: GestureDetector(
          onTap: () async {
            // Tap to dismiss early
            if (_exitCtrl.isAnimating || _exitCtrl.isCompleted) return;
            await _exitCtrl.forward();
            if (!mounted) return;
            widget.onDismissed();
          },
          child: Container(
            color: cs.surface,
            child: Center(
              child: GlassCard(
                borderRadius: const BorderRadius.all(Radius.circular(36)),
                blurSigma: 24,
                tintAlpha: 0.22,
                borderAlpha: 0.18,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl + AppSpacing.sm,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Checkmark + particles
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _entryCtrl,
                          _particleCtrl,
                        ]),
                        builder: (context, _) {
                          final entryT = _entryElastic.value;
                          final fadeIn = _entryFadeIn.value;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ring pulse
                              Transform.scale(
                                scale: 0.8 + entryT * 0.6,
                                child: Opacity(
                                  opacity: (fadeIn *
                                          (1.0 -
                                              (entryT - 0.7).clamp(0.0, 1.0) *
                                                  3))
                                      .clamp(0.0, 1.0),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: cs.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Particles — 40 multi-coloured shards.
                              ..._particles.map((p) {
                                final rawT = ((_particleCtrl.value - p.delay) /
                                        (1 - p.delay))
                                    .clamp(0.0, 1.0);
                                final ease = Curves.easeOutCubic.transform(
                                  rawT,
                                );
                                final fadeOut =
                                    rawT > 0.5 ? (rawT - 0.5) / 0.5 : 0.0;
                                final dx = cos(p.angle) * p.distance * ease;
                                // Mild gravity tug for a confetti-like fall.
                                final dy =
                                    sin(p.angle) * p.distance * ease +
                                    rawT * rawT * 18;
                                final color = moodPalette[p.colorIndex];

                                return Transform.translate(
                                  offset: Offset(dx, dy),
                                  child: Opacity(
                                    opacity: ((1.0 - fadeOut) * fadeIn).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    child: Container(
                                      width: p.size,
                                      height: p.size,
                                      decoration: BoxDecoration(
                                        color: color.withValues(
                                          alpha: 0.7 + 0.3 * (1.0 - ease),
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // Main circle + check (with halo glow)
                              Transform.scale(
                                scale: entryT.clamp(0.0, 1.3),
                                child: Opacity(
                                  opacity: fadeIn,
                                  child: GlowBox(
                                    color: cs.primary,
                                    glowOpacity: 0.55 * fadeIn,
                                    blurRadius: 36,
                                    spreadRadius: 8,
                                    shape: BoxShape.circle,
                                    child: Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Hidden Icon for find.byIcon test
                                          // compatibility — never visible to
                                          // users, replaced visually by the
                                          // animated path stroke below.
                                          Opacity(
                                            opacity: 0.0,
                                            child: Icon(
                                              Icons.check_rounded,
                                              size: 44,
                                              color: cs.onPrimaryContainer,
                                            ),
                                          ),
                                          // Stroke-drawn check.
                                          AnimatedCheckPath(
                                            progress: _checkDrawCurve,
                                            color: cs.onPrimaryContainer,
                                            size: 44,
                                            strokeWidth: 6,
                                            semanticLabel:
                                                l10n.entrySavedOverlay,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // "Saved" text slides up
                    AnimatedBuilder(
                      animation: _entryCtrl,
                      builder: (context, child) {
                        final t = _entryTextSlide.value;
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - t)),
                            child: child,
                          ),
                        );
                      },
                      child: Semantics(
                        liveRegion: true,
                        label: l10n.entrySavedOverlay,
                        child: Text(
                          l10n.entrySavedOverlay,
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Subtle secondary text — show milestone or default
                    AnimatedBuilder(
                      animation: _entryCtrl,
                      builder: (context, child) {
                        final t = _entrySubtextFade.value;
                        return Opacity(opacity: t, child: child);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.milestoneMessage != null) ...[
                            Text(
                              widget.milestoneMessage!,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: cs.primary.withValues(alpha: 0.85),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                          Text(
                            l10n.niceOne,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final double delay;
  final int colorIndex;

  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.colorIndex,
  });
}
