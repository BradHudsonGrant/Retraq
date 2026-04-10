import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/atoms/animated_mesh_background.dart';
import '../widgets/atoms/loader_dots.dart';
import '../widgets/atoms/retraq_logo.dart';

/// Branded splash screen shown while the app loads settings on startup.
///
/// The mesh shader is bounded with `oneShotDuration` so its ticker stops
/// well before the splash hands off to the real UI — no leaked timers.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedMeshBackground(
            colors: [
              cs.primary.withValues(alpha: isDark ? 0.85 : 0.55),
              cs.tertiary.withValues(alpha: isDark ? 0.7 : 0.45),
              cs.secondaryContainer.withValues(alpha: isDark ? 0.85 : 0.55),
            ],
            baseColor: cs.surface,
            opacity: isDark ? 1.0 : 0.9,
            oneShotDuration: const Duration(seconds: 6),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Animate(
                  effects: [
                    FadeEffect(duration: 600.ms, curve: Curves.easeOut),
                    ScaleEffect(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),
                  ],
                  child: const RetraqLogo(
                    size: 72,
                    animate: true,
                    showText: true,
                  ),
                ),
                const SizedBox(height: 36),
                Animate(
                  effects: [FadeEffect(delay: 350.ms, duration: 500.ms)],
                  child: LoaderDots(
                    color: cs.primary,
                    size: 9,
                    gap: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
