import 'package:flutter/material.dart';

import '../../widgets/settings_provider.dart';
import '../../services/recap_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';

/// Displays the weekly recap summary card.
///
/// Styled to visually match the day cards in [WeekDayList] — same
/// `surfaceContainerLow` fill, `borderRadiusXl` corners, `AppSpacing.lg`
/// padding and full width — so the entire week scroll reads as a single
/// rhythm. The accent here is a tinted left border + primary-coloured
/// title rather than a separate Material Card with its own elevation.
class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({super.key, required this.summary});

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      // "Featured card" treatment — deliberately distinct from the
      // regular content tier so the weekly recap reads as the hero
      // of the Recap screen:
      //   • Dark recessed surface (surfaceContainerLow) matching the
      //     Traq input well, inverting the normal card→content
      //     hierarchy so the recap feels like a "pocket" of its own.
      //   • Full 1.5px primary border on all four sides — the green
      //     now wraps the card instead of living only on the left
      //     edge, giving it an unmistakable brand frame.
      //   • Soft primary-tinted glow so the card appears to give off
      //     a faint halo, reinforcing the "hero tile" read without
      //     shouting.
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: cs.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Weekly Recap',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          BionicText(
            text: summary.observation,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.4),
            enabled:
                SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                false,
          ),
          if (summary.totalEntries > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${summary.totalEntries} entries \u00b7 ${summary.activeDays} days \u00b7 ${summary.preferredTime}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
