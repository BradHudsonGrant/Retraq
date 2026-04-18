import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';
import 'animated_mesh_background.dart';

/// Brand ambient background used by AppShell across every tab.
///
/// The full-screen look is a single vertical gradient:
///
///   • Top       — a brand-tinted halo (the "glow" the user liked from
///                 the old Recap top gradient).
///   • Middle    — the plain [ColorScheme.surface] so card / text
///                 content still reads cleanly.
///   • Bottom    — a darker tint that blends the screen into the
///                 bottom navigation bar. Without this the screen
///                 surface met the navbar at a visible seam; the dark
///                 fade lets content "recede" into the nav chrome.
///
/// A very-low-opacity [AnimatedMeshBackground] drifts under the
/// gradient to add subtle motion without dominating the palette.
///
/// Intensity is brightness-aware so the same perceived contrast shows
/// up on both themes without the dark-green primary muddying the light
/// surface.
class BrandAmbientBackground extends StatelessWidget {
  const BrandAmbientBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  /// Foreground content painted on top of the ambient background.
  final Widget child;

  /// Uniform scale for both ends of the gradient and the mesh
  /// underlay. 1.0 applies the tuned per-brightness defaults.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = AppMotion.reduce(context);

    // Top halo: warm brand colour. In dark mode we use the mint primary
    // directly because it lifts cleanly off the deep surface; in light
    // mode primaryContainer (also a light mint) blends into the near-
    // white surface without reading as a dirty forest-green cast.
    final Color haloColor = isDark ? cs.primary : cs.primaryContainer;
    final double haloAlpha = (isDark ? 0.45 : 0.22) * intensity;

    // Bottom fade. Earlier passes used surfaceContainerLowest /
    // surfaceContainerHighest but those tokens are only ~6–30 RGB
    // levels away from cs.surface — the visible contrast from middle
    // to bottom came out as "basically the same shade", which matched
    // the user's "I don't see a difference" note. Switch to pure
    // Colors.black at per-brightness alphas so the bottom really does
    // darken into the navbar:
    //   dark  — 0.9 black over the near-black surface makes the foot
    //           read as proper black, letting the transparent navbar
    //           float directly on it.
    //   light — 0.18 black over the near-white surface gives a soft
    //           mid-gray fade; enough contrast to register as "darker
    //           at the bottom" without fighting the bright palette.
    const Color bottomColor = Colors.black;
    final double bottomAlpha = (isDark ? 0.9 : 0.18) * intensity;

    // Mesh underlay colours.
    final meshColors = <Color>[
      (isDark ? cs.primary : cs.primaryContainer).withValues(alpha: 0.5),
      (isDark ? cs.tertiary : cs.tertiaryContainer).withValues(alpha: 0.4),
      cs.secondaryContainer.withValues(alpha: 0.5),
    ];
    final double meshOuter = (isDark ? 0.10 : 0.045) * intensity;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base: scheme surface so the rest of the stack composites
        // over a predictable baseline.
        ColoredBox(color: cs.surface),

        // Animated mesh underlay (subtle motion). Skipped entirely
        // when the outer opacity would be imperceptible.
        if (meshOuter > 0.001)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedMeshBackground(
                colors: meshColors,
                baseColor: cs.surface,
                opacity: reduceMotion ? meshOuter * 0.6 : meshOuter,
              ),
            ),
          ),

        // Single full-screen vertical gradient covering both the top
        // halo and the bottom navbar-blend fade. Drawn as one
        // LinearGradient so the mid-screen stays perfectly
        // transparent-to-surface and the two tinted bands sit at the
        // extremes where content is sparse.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // Stops tuned so the darkening dominates the bottom
                  // half of the screen: halo fades by 25%, then only a
                  // ~15%-tall neutral band before the bottom fade
                  // starts at 40%. The visible "dark zone" now runs
                  // from mid-screen down to the navbar, giving the
                  // gradient real top-to-bottom contrast instead of
                  // reserving the darkening for the last few %.
                  stops: const [0.0, 0.25, 0.40, 1.0],
                  colors: [
                    haloColor.withValues(alpha: haloAlpha),
                    cs.surface.withValues(alpha: 0),
                    cs.surface.withValues(alpha: 0),
                    bottomColor.withValues(alpha: bottomAlpha),
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
