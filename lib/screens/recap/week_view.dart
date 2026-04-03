import 'package:flutter/material.dart';

import '../../models/journal_entry.dart';
import '../../providers/settings_provider.dart';
import '../../services/recap_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/atoms/bionic_text.dart';
import '../../widgets/organisms/week_day_list.dart';
import 'weekly_summary_card.dart';

/// Week view section of the Recap screen.
class RecapWeekView extends StatelessWidget {
  const RecapWeekView({
    super.key,
    required this.weekEntries,
    required this.weekStartDay,
    this.weeklySummary,
    required this.onDaySelected,
  });

  final List<JournalEntry> weekEntries;
  final int weekStartDay;
  final WeeklySummary? weeklySummary;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekly summary card
        if (weeklySummary != null) ...[
          WeeklySummaryCard(summary: weeklySummary!),
          const SizedBox(height: AppSpacing.md),
        ],

        if (weekEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 48,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No entries yet',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  BionicText(
                    text: 'Your journal entries will appear here once you start writing.',
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    enabled: SettingsProvider.maybeOf(context)?.bionicReadingEnabled ?? false,
                  ),
                ],
              ),
            ),
          )
        else
          WeekDayList(
            weekStartDay: weekStartDay,
            entries: weekEntries,
            onDaySelected: onDaySelected,
          ),
      ],
    );
  }
}
