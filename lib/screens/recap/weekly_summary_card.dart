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
      // Raised content tier (surfaceContainerHigh) shared with all
      // other content cards across the shell. Identified as the
      // weekly recap card via a soft 2px primary-tinted left accent
      // that blends with the outlineVariant outline on the other
      // three sides — the old 3px full-opacity primary bar read as
      // harsh against the lighter surface.
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
          right: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
          left: BorderSide(
            color: cs.primary.withValues(alpha: 0.55),
            width: 2,
          ),
        ),
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
