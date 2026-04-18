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
///   • A low-opacity [AnimatedMeshBackground] with three brand colours
///     drifts across the full screen. Contribution stays under ~25%
///     opacity so card content remains the focus, not the gradient.
///   • A static primary-tinted halo sits on top of the mesh, anchored to
///     the top of the screen, fading out by ~40% of the viewport height.
///     This is the "glow" the user liked from Recap, now shared.
///
/// The widget honours reduce-motion (no shader ticker) and plays nicely
/// on both the light and dark schemes by pulling its colours from the
/// active [ColorScheme].
class BrandAmbientBackground extends StatelessWidget {
  const BrandAmbientBackground({
    super.key,
    required this.child,
    this.topHaloFraction = 0.42,
    this.topHaloStrength = 0.18,
    this.meshOpacity = 0.22,
  });

  /// Foreground content painted on top of the ambient background. Use
  /// Scaffold / SafeArea / CustomScrollView etc. as usual inside [child].
  final Widget child;

  /// How far down the screen the top primary halo extends before fully
  /// fading into [ColorScheme.surface]. 0.42 = ~42% of the screen height.
  final double topHaloFraction;

  /// Peak alpha of the top halo. Keep low (≤0.25) so content cards don't
  /// fight the tint for attention.
  final double topHaloStrength;

  /// Alpha multiplier applied to the animated mesh underlay. Set to 0 to
  /// hide the mesh entirely and render only the static halo.
  final double meshOpacity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = AppMotion.reduce(context);

    // Pick three brand-family colours for the mesh. Tertiary anchors the
    // warm side (sage-yellow in light, olive in dark); primary and
    // secondaryContainer give two green tones so the mesh stays
    // recognisably Retraq rather than looking like a generic gradient.
    final meshColors = <Color>[
      cs.primary.withValues(alpha: 0.65),
      cs.tertiary.withValues(alpha: 0.45),
      cs.secondaryContainer.withValues(alpha: 0.6),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base: scheme surface so the rest of the stack can alpha-composite
        // over a predictable baseline instead of a transparent window.
        ColoredBox(color: cs.surface),

        // Animated mesh underlay. Suppressed entirely when the user has
        // reduce-motion on — the fallback LinearGradient inside the widget
        // still gives a hint of colour without an infinite ticker.
        if (meshOpacity > 0.001)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedMeshBackground(
                colors: meshColors,
                baseColor: cs.surface,
                opacity: reduceMotion ? meshOpacity * 0.6 : meshOpacity,
              ),
            ),
          ),

        // Static top halo — the "glow" the user liked from the old Recap
        // header, now shared across tabs. Uses a vertical alignment-based
        // gradient so it scales with the device height.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, topHaloFraction],
                  colors: [
                    cs.primary.withValues(alpha: topHaloStrength),
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
