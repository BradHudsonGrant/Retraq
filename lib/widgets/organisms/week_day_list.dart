import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/journal_entry.dart';
import '../../widgets/settings_provider.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../utils/entry_action_dialogs.dart';
import '../atoms/bionic_text.dart';
import '../atoms/retraq_chip.dart';
import '../molecules/entry_action_menu.dart';

/// Vertical scrollable list showing each day of a week
/// with its journal entries listed inline beneath each day header.
class WeekDayList extends StatelessWidget {
  const WeekDayList({
    super.key,
    required this.weekStartDay,
    required this.entries,
    this.selectedDay,
    this.onDaySelected,
    this.referenceDate,
  });

  /// 1 = Monday, 7 = Sunday
  final int weekStartDay;

  /// All entries for the week (already filtered by caller).
  final List<JournalEntry> entries;

  /// Currently selected day (full DateTime).
  final DateTime? selectedDay;

  /// Called when a day header is tapped.
  final ValueChanged<DateTime>? onDaySelected;

  /// Start of the week to display. If null, uses the current week.
  final DateTime? referenceDate;

  /// The 7 dates for the week.
  List<DateTime> _weekDates() {
    if (referenceDate != null) {
      return List.generate(7, (i) => referenceDate!.add(Duration(days: i)));
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday; // 1=Mon, 7=Sun
    final offset = (weekday - weekStartDay + 7) % 7;
    final startOfWeek = today.subtract(Duration(days: offset));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  /// Group entries by date (day precision), oldest-first within each day so
  /// readers scan top-to-bottom chronologically. Matches the order the Jot
  /// "Recent" card uses so the two surfaces never disagree.
  Map<DateTime, List<JournalEntry>> _groupByDate() {
    final map = <DateTime, List<JournalEntry>>{};
    for (final entry in entries) {
      final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
      (map[key] ??= []).add(entry);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final dates = _weekDates();
    final grouped = _groupByDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reduceMotion = AppMotion.reduce(context);

    // Skip days after "today" so the current week doesn't render empty
    // placeholder cards for Friday/Saturday/etc. Past weeks still show
    // every day (empty ones get a "No entries" line).
    final visibleDates = dates
        .where((d) => !d.isAfter(today))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Each day of the week (future days are hidden)
        ...visibleDates.asMap().entries.map((mapEntry) {
          final dayIndex = mapEntry.key;
          final date = mapEntry.value;
          final isToday = date == today;
          final dayEntries = grouped[date] ?? [];
          final dayLabel = DateFormat(
            'EEEE',
          ).format(date); // Monday, Tuesday...
          final dateLabel = DateFormat('MMM d').format(date); // Mar 26

          // Task 7.4 — semantic label uses localized "Today" + empty-
          // state phrase. Plural handling of entry count is deferred to
          // a future ICU-plural ARB key (Task 2.3 follow-up); for now
          // keep the English fragment conditional on count but prefix
          // with the localized weekday/today.
          final todayOrDayName = isToday ? l10n.todayLabel : dayLabel;
          final dayCard = Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Semantics(
              button: true,
              label:
                  '$todayOrDayName, $dateLabel'
                  '${dayEntries.isEmpty ? ', ${l10n.noEntriesForDay.toLowerCase()}' : ''}'
                  '${dayEntries.isNotEmpty ? ', ${dayEntries.length} ${dayEntries.length == 1 ? 'entry' : 'entries'}' : ''}',
              child: InkWell(
                onTap: () => onDaySelected?.call(date),
                borderRadius: AppSpacing.borderRadiusXl,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: AppSpacing.borderRadiusXl,
                    // Shared minimal-border content-tier style:
                    // surfaceContainerHigh fill + 1px outlineVariant
                    // outline. Matches RecentDayCard, StatCard, and
                    // the other content cards across the shell.
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header row (Task 7.4 — localized "Today").
                      Row(
                        children: [
                          Text(
                            isToday ? l10n.todayLabel : dayLabel,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isToday ? cs.primary : cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            dateLabel,
                            style: tt.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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

                      // Entries for this day — flat rows within the day
                      // card, separated by a thin divider. No nested box
                      // wrapper so every card on the page reads at the
                      // same visual width.
                      if (dayEntries.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        for (var i = 0; i < dayEntries.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                          _InlineEntry(entry: dayEntries[i]),
                        ],
                      ] else ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          // Task 7.4 — localized empty-day label.
                          l10n.noEntriesForDay,
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

          if (reduceMotion) return dayCard;
          final delayMs = dayIndex * 60;
          return Animate(
            effects: [
              FadeEffect(
                delay: delayMs.ms,
                duration: 380.ms,
                curve: Curves.easeOut,
              ),
              SlideEffect(
                delay: delayMs.ms,
                begin: const Offset(0, 0.08),
                end: Offset.zero,
                duration: 440.ms,
                curve: AppMotion.emphasizedDecelerate,
              ),
            ],
            child: dayCard,
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
    // Show a wall-clock time only when the entry has no AM/PM bucket label;
    // the chip already communicates "when" for labelled entries.
    final hasLabel = entry.label != null;
    final timeLabel =
        hasLabel ? null : DateFormat('h:mm a').format(entry.createdAt);
    // Backdated marker: if the entry was WRITTEN on a different day from the
    // day it's ABOUT, surface that so "12:34 AM" on yesterday's card doesn't
    // look like it's seconds away from another entry on the same day.
    final createdDate = DateTime(
      entry.createdAt.year,
      entry.createdAt.month,
      entry.createdAt.day,
    );
    final entryDate = DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
    );
    final isBackdated = createdDate != entryDate;
    final backdatedLabel =
        isBackdated ? DateFormat('MMM d').format(entry.createdAt) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time + label + title + actions row
        Row(
          children: [
            if (timeLabel != null)
              Text(
                backdatedLabel != null
                    ? '$backdatedLabel · $timeLabel'
                    : timeLabel,
                // Task 7.7 — alpha raised from 0.6 to 0.75 for WCAG 1.4.3.
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                  fontStyle: isBackdated ? FontStyle.italic : null,
                ),
              ),
            if (hasLabel && backdatedLabel != null) ...[
              Text(
                '$backdatedLabel · ',
                // Task 7.7 — alpha raised from 0.6 to 0.75 for WCAG 1.4.3.
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (hasLabel)
              RetraqChip(
                label: entry.label!,
                color:
                    entry.label == 'AM'
                        ? cs.primaryContainer
                        : cs.tertiaryContainer,
                textColor:
                    entry.label == 'AM'
                        ? cs.onPrimaryContainer
                        : cs.onTertiaryContainer,
              ),
            if (entry.title != null && entry.title!.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '·',
                // Task 7.7 — separator dot; alpha raised from 0.5 to 0.75.
                // Still visually secondary to the adjacent text.
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  entry.title!,
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (entry.title == null || entry.title!.isEmpty) const Spacer(),
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
          BionicText(
            text: entry.entry!,
            style: tt.bodyMedium?.copyWith(height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            enabled:
                SettingsProvider.maybeOf(context)?.bionicReadingEnabled ??
                false,
          ),
      ],
    );
  }
}
