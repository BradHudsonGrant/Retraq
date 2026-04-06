import 'package:flutter/material.dart';

import '../../providers/settings_provider.dart';
import '../../services/recap_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';

/// Displays the weekly recap summary card.
class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({super.key, required this.summary});

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Recap',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            BionicText(
              text: summary.observation,
              style: tt.bodyMedium?.copyWith(color: cs.onPrimaryContainer),
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
                    size: 16,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${summary.totalEntries} entries \u00b7 ${summary.activeDays} days \u00b7 ${summary.preferredTime}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
