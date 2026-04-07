import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';

/// A satisfying full-screen overlay shown after a traq is saved.
/// Scale-up checkmark with floating particles, haptic feedback, auto-dismiss.
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

  @override
  void initState() {
    super.initState();

    // Entry: checkmark + ring + text (500ms with elastic overshoot)
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Particles burst outward (800ms)
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Exit: fade + scale down (300ms)
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Generate burst particles
    final rng = Random();
    _particles = List.generate(16, (i) {
      final angle = (i / 16) * 2 * pi + rng.nextDouble() * 0.4;
      final distance = 50.0 + rng.nextDouble() * 70;
      final size = 3.0 + rng.nextDouble() * 5;
      return _Particle(
        angle: angle,
        distance: distance,
        size: size,
        delay: rng.nextDouble() * 0.15,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkmark + particles
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_entryCtrl, _particleCtrl]),
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
                                            (entryT - 0.7).clamp(0.0, 1.0) * 3))
                                    .clamp(0.0, 1.0),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cs.primary.withValues(alpha: 0.15),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Particles
                            ..._particles.map((p) {
                              final rawT = ((_particleCtrl.value - p.delay) /
                                      (1 - p.delay))
                                  .clamp(0.0, 1.0);
                              final ease = Curves.easeOutCubic.transform(rawT);
                              final fadeOut =
                                  rawT > 0.5 ? (rawT - 0.5) / 0.5 : 0.0;
                              final dx = cos(p.angle) * p.distance * ease;
                              final dy = sin(p.angle) * p.distance * ease;

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
                                      color: cs.primary.withValues(
                                        alpha: 0.6 + 0.3 * (1.0 - ease),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // Main circle + check
                            Transform.scale(
                              scale: entryT.clamp(0.0, 1.3),
                              child: Opacity(
                                opacity: fadeIn,
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: cs.primary.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 24,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 44,
                                    color: cs.onPrimaryContainer,
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
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final double delay;

  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });
}
