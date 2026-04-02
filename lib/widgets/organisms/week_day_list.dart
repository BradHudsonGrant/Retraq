import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../theme/app_spacing.dart';
import '../../utils/entry_action_dialogs.dart';
import '../atoms/sincethen_chip.dart';
import '../molecules/entry_action_menu.dart';

/// Vertical scrollable list showing each day of the current week
/// with its journal entries listed inline beneath each day header.
/// No calendar grid, no strip — just a day-by-day feed.
class WeekDayList extends StatelessWidget {
  const WeekDayList({
    super.key,
    required this.weekStartDay,
    required this.entries,
    this.selectedDay,
    this.onDaySelected,
  });

  /// 1 = Monday, 7 = Sunday
  final int weekStartDay;

  /// All entries for the current week (already filtered by caller).
  final List<JournalEntry> entries;

  /// Currently selected day (full DateTime).
  final DateTime? selectedDay;

  /// Called when a day header is tapped.
  final ValueChanged<DateTime>? onDaySelected;

  /// The 7 dates for the current week.
  List<DateTime> _weekDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday; // 1=Mon, 7=Sun
    final offset = (weekday - weekStartDay + 7) % 7;
    final startOfWeek = today.subtract(Duration(days: offset));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  /// Group entries by date (day precision).
  Map<DateTime, List<JournalEntry>> _groupByDate() {
    final map = <DateTime, List<JournalEntry>>{};
    for (final entry in entries) {
      final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
      (map[key] ??= []).add(entry);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dates = _weekDates();
    final grouped = _groupByDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week header
        Text(
          'This week',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Each day of the week
        ...dates.map((date) {
          final isToday = date == today;
          final isFuture = date.isAfter(today);
          final dayEntries = grouped[date] ?? [];
          final dayLabel = DateFormat('EEEE').format(date); // Monday, Tuesday...
          final dateLabel = DateFormat('MMM d').format(date); // Mar 26

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Semantics(
              button: !isFuture,
              label: '${isToday ? 'Today' : dayLabel}, $dateLabel'
                  '${dayEntries.isEmpty && !isFuture ? ', no entries' : ''}'
                  '${dayEntries.isNotEmpty ? ', ${dayEntries.length} ${dayEntries.length == 1 ? 'entry' : 'entries'}' : ''}',
              enabled: !isFuture,
              child: InkWell(
                onTap: isFuture ? null : () => onDaySelected?.call(date),
                borderRadius: AppSpacing.borderRadiusXl,
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: AppSpacing.borderRadiusXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day header row
                    Row(
                      children: [
                        Text(
                          isToday ? 'Today' : dayLabel,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isFuture
                                ? cs.onSurfaceVariant.withValues(alpha: 0.65)
                                : isToday
                                    ? cs.primary
                                    : cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          dateLabel,
                          style: tt.labelMedium?.copyWith(
                            color: isFuture
                                ? cs.onSurfaceVariant.withValues(alpha: 0.65)
                                : cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        if (dayEntries.isNotEmpty)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    // Entries for this day
                    if (dayEntries.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      ...dayEntries.map((entry) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _InlineEntry(entry: entry),
                          )),
                    ] else if (!isFuture) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No entries',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Compact inline rendering of a single journal entry within a day card.
class _InlineEntry extends StatelessWidget {
  const _InlineEntry({required this.entry});

  final JournalEntry entry;

  Future<void> _confirmEdit(BuildContext context) async {
    await confirmAndEditEntry(context, entry);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await confirmAndDeleteEntry(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final timeLabel = DateFormat('h:mm a').format(entry.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time + label + title + actions row
          Row(
            children: [
              Text(
                timeLabel,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              if (entry.label != null) ...[
                const SizedBox(width: AppSpacing.sm),
                SinceThenChip(
                  label: entry.label!,
                  color: entry.label == 'AM'
                      ? cs.primaryContainer
                      : cs.tertiaryContainer,
                  textColor: entry.label == 'AM'
                      ? cs.onPrimaryContainer
                      : cs.onTertiaryContainer,
                ),
              ],
              if (entry.title != null && entry.title!.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '·',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.title!,
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (entry.title == null || entry.title!.isEmpty)
                const Spacer(),
              EntryActionMenu(
                entry: entry,
                onEdit: () => _confirmEdit(context),
                onDelete: () => _confirmDelete(context),
                iconSize: 18,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Entry text
          if (entry.entry != null && entry.entry!.isNotEmpty)
            Text(
              entry.entry!,
              style: tt.bodyMedium?.copyWith(height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
