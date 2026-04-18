import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../atoms/glow_box.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool? isDark; // null = system (adapts to current theme)
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final effectiveDark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final card = AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppSpacing.sm),
      // Unselected: shared content-card tier (surfaceContainerHigh +
      // outlineVariant). Selected: recessed surface + full-opacity
      // primary outline so the selection state still reads clearly.
      decoration: BoxDecoration(
        color: isSelected ? cs.surfaceContainerLowest : cs.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isSelected
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.35),
          width: isSelected ? 2 : 1,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 72,
            child:
                isDark == null
                    ? _buildSystemPreview(cs)
                    : _buildThemePreview(cs, effectiveDark),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: tt.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                ExcludeSemantics(
                  child: Icon(Icons.check_circle, color: cs.primary, size: 18),
                )
              else
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    // Glow halo when selected; spring scale otherwise unchanged.
    final cardWithGlow =
        isSelected
            ? GlowBox(
              color: cs.primary,
              glowOpacity: 0.5,
              blurRadius: 24,
              spreadRadius: 1,
              borderRadius: AppSpacing.borderRadiusLg,
              child: card,
            )
            : card;

    return Semantics(
      button: true,
      label: '$label theme',
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusLg,
        child: AnimatedScale(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
          curve: AppMotion.springSmooth,
          scale: isSelected ? 1.04 : 1.0,
          child: cardWithGlow,
        ),
      ),
    );
  }

  /// Half-light / half-dark split preview for the System card.
  Widget _buildSystemPreview(ColorScheme cs) {
    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusMd,
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: cs.surfaceContainerLow,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 5,
                    width: 24,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.lightScheme.surfaceContainerLowest,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.darkScheme.surfaceContainerLowest,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 5,
                    width: 24,
                    decoration: BoxDecoration(
                      color: AppColors.darkScheme.onSurface.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.darkScheme.surfaceContainer,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Standard single-theme preview for Day/Night cards.
  Widget _buildThemePreview(ColorScheme cs, bool dark) {
    return Container(
      decoration: BoxDecoration(
        color:
            dark
                ? AppColors.darkScheme.surfaceContainerLowest
                : cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: (dark
                      ? AppColors.darkScheme.onSurface
                      : cs.onSurfaceVariant)
                  .withValues(alpha: 0.2),
              borderRadius: AppSpacing.borderRadiusFull,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color:
                  dark
                      ? AppColors.darkScheme.surfaceContainer
                      : AppColors.lightScheme.surfaceContainerLowest,
              borderRadius: AppSpacing.borderRadiusSm,
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 5,
            width: 60,
            decoration: BoxDecoration(
              color: (dark
                      ? AppColors.darkScheme.onSurface
                      : cs.onSurfaceVariant)
                  .withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusFull,
            ),
          ),
        ],
      ),
    );
  }
}
