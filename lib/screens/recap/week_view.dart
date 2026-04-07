import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
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
    required this.weekOffset,
    required this.weekStart,
    required this.onPreviousWeek,
    this.onNextWeek,
    required this.onDaySelected,
  });

  final List<JournalEntry> weekEntries;
  final int weekStartDay;
  final WeeklySummary? weeklySummary;
  final int weekOffset;
  final DateTime weekStart;
  final VoidCallback onPreviousWeek;
  final VoidCallback? onNextWeek; // null = can't go forward (current week)
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Week navigation header ──
        _WeekNavigationHeader(
          weekStart: weekStart,
          weekEnd: weekEnd,
          isCurrentWeek: weekOffset == 0,
          onPrevious: onPreviousWeek,
          onNext: onNextWeek,
        ),

        const SizedBox(height: AppSpacing.md),

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
                    l10n.noEntriesYet,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  BionicText(
                    text:
                        weekOffset == 0
                            ? l10n.noEntriesYetMessage
                            : l10n.noEntriesForWeek,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    enabled:
                        SettingsProvider.maybeOf(
                          context,
                        )?.bionicReadingEnabled ??
                        false,
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
            referenceDate: weekStart,
          ),
      ],
    );
  }
}

class _WeekNavigationHeader extends StatelessWidget {
  const _WeekNavigationHeader({
    required this.weekStart,
    required this.weekEnd,
    required this.isCurrentWeek,
    required this.onPrevious,
    this.onNext,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final bool isCurrentWeek;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    final startLabel = DateFormat('MMM d').format(weekStart);
    final endLabel =
        weekStart.month == weekEnd.month
            ? DateFormat('d').format(weekEnd)
            : DateFormat('MMM d').format(weekEnd);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous week button
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: l10n.previousWeek,
          style: IconButton.styleFrom(
            backgroundColor: cs.surfaceContainerHigh,
            foregroundColor: cs.onSurface,
          ),
        ),

        // Week label
        Column(
          children: [
            if (isCurrentWeek)
              Text(
                l10n.thisWeekLabel,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              )
            else
              Text(
                '$startLabel – $endLabel',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            if (!isCurrentWeek)
              Text(
                '${weekStart.year}',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),

        // Next week button (disabled on current week)
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: isCurrentWeek ? l10n.currentWeek : l10n.nextWeek,
          style: IconButton.styleFrom(
            backgroundColor:
                onNext != null
                    ? cs.surfaceContainerHigh
                    : cs.surfaceContainerHigh.withValues(alpha: 0.3),
            foregroundColor:
                onNext != null
                    ? cs.onSurface
                    : cs.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
