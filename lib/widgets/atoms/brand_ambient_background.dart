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
    final double haloAlpha = (isDark ? 0.22 : 0.10) * intensity;

    // Bottom fade: a darker surface variant that the navbar sits on
    // seamlessly. In dark mode surfaceContainerLowest is the near-
    // black token — almost matches the navbar. In light mode the
    // surfaceContainerHighest token is slightly darker than the plain
    // surface so the screen still darkens toward the navbar for depth
    // even though the overall palette stays bright.
    final Color bottomColor =
        isDark ? cs.surfaceContainerLowest : cs.surfaceContainerHighest;
    final double bottomAlpha = (isDark ? 0.85 : 0.55) * intensity;

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
                  stops: const [0.0, 0.35, 0.70, 1.0],
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
