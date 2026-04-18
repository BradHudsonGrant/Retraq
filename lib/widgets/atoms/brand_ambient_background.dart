import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';
import 'animated_mesh_background.dart';

/// Subtle brand-coloured ambient background used by AppShell across every
/// tab.
///
/// The Recap screen previously carried its own top-of-page primary-tinted
/// linear gradient, which users liked — but it stopped at 280px and only
/// existed on that one screen. This widget generalises the idea:
///
///   • A very-low-opacity [AnimatedMeshBackground] with three brand
///     colours drifts across the full screen. The effect stays well
///     below ~10% effective opacity on dark and ~5% on light so card
///     content remains the focus, not the gradient.
///   • A static brand-tinted halo sits on top of the mesh, anchored to
///     the top of the screen, fading out by ~40% of the viewport
///     height. This is the "glow" the user liked from Recap, now
///     shared.
///
/// Intensity is brightness-aware by default: light mode uses the
/// lighter primaryContainer token and runs at roughly half the
/// intensity of dark mode, because overlaying the dark-green primary on
/// a near-white surface reads as "muddy" rather than "ambient".
/// Callers can override via [intensity] if needed.
///
/// The widget honours reduce-motion (no shader ticker) and plays nicely
/// on both the light and dark schemes by pulling its colours from the
/// active [ColorScheme].
class BrandAmbientBackground extends StatelessWidget {
  const BrandAmbientBackground({
    super.key,
    required this.child,
    this.topHaloFraction = 0.42,
    this.intensity = 1.0,
  });

  /// Foreground content painted on top of the ambient background. Use
  /// Scaffold / SafeArea / CustomScrollView etc. as usual inside [child].
  final Widget child;

  /// How far down the screen the top brand halo extends before fully
  /// fading into [ColorScheme.surface]. 0.42 = ~42% of the screen height.
  final double topHaloFraction;

  /// Uniform scale for both the halo and the mesh underlay. 1.0 applies
  /// the tuned per-brightness defaults; smaller values make the effect
  /// more subtle, larger values push it brighter. Intended as an escape
  /// hatch for screens that want more or less ambient tint than the
  /// shell-default.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = AppMotion.reduce(context);

    // Tuned per-brightness defaults. Light mode is noticeably quieter
    // than dark because a dark-green overlay on a near-white surface
    // muddies the whole canvas before it reads as "ambient"; dark mode
    // can carry more because each overlay lifts the deep surface
    // without fighting on-surface text.
    final double haloStrength = (isDark ? 0.10 : 0.045) * intensity;
    final double meshOuter = (isDark ? 0.12 : 0.05) * intensity;

    // Pick three brand-family colours for the mesh. In dark mode the
    // primary token is the lighter mint so it lifts cleanly off the
    // deep surface. In light mode we use primaryContainer (also a
    // light mint) so the mesh blends into the pale surface instead of
    // dragging it toward the dark forest-green primary.
    final Color meshSeed1 = isDark ? cs.primary : cs.primaryContainer;
    final Color meshSeed2 = isDark
        ? cs.tertiary
        : cs.tertiaryContainer;
    final Color meshSeed3 = cs.secondaryContainer;

    // Same rationale for the halo: the lighter on-brand token blends
    // cleanly into whichever surface is underneath instead of reading
    // as a dirty colour cast.
    final Color haloColor = isDark ? cs.primary : cs.primaryContainer;

    // The inner shader alphas combine multiplicatively with meshOuter.
    // Keeping the per-blob alphas bounded (0.45–0.65) lets the outer
    // meshOuter be the single knob that controls visible intensity.
    final meshColors = <Color>[
      meshSeed1.withValues(alpha: 0.55),
      meshSeed2.withValues(alpha: 0.45),
      meshSeed3.withValues(alpha: 0.55),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base: scheme surface so the rest of the stack can alpha-composite
        // over a predictable baseline instead of a transparent window.
        ColoredBox(color: cs.surface),

        // Animated mesh underlay. Suppressed when intensity drives the
        // outer opacity below perceptible; otherwise shown — the widget
        // itself handles reduce-motion fallback to a static gradient.
        if (meshOuter > 0.001)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedMeshBackground(
                colors: meshColors,
                baseColor: cs.surface,
                // Drop the mesh further under reduce-motion — the
                // fallback is a crisp static linear gradient which
                // reads louder than the drifting version at the same
                // alpha, so compensate.
                opacity: reduceMotion ? meshOuter * 0.6 : meshOuter,
              ),
            ),
          ),

        // Static top halo — the "glow" the user liked from the old Recap
        // header, now shared across tabs. Uses a vertical alignment-based
        // gradient so it scales with the device height.
        if (haloStrength > 0.001)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, topHaloFraction],
                    colors: [
                      haloColor.withValues(alpha: haloStrength),
                      cs.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Foreground content.
        child,
      ],
    );
  }
}
