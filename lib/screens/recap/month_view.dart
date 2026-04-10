import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/journal_entry.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../utils/adaptive_layout.dart';
import '../../widgets/atoms/bionic_text.dart';
import '../../widgets/organisms/calendar_grid.dart';
import '../../widgets/organisms/entry_detail_view.dart';

/// Month / calendar view section of the Recap screen.
class RecapMonthView extends StatelessWidget {
  const RecapMonthView({
    super.key,
    required this.selectedMonth,
    required this.entryDays,
    this.dayMoods = const {},
    this.selectedDay,
    required this.monthEntries,
    required this.selectedEntries,
    required this.weekStartDay,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime selectedMonth;
  final Set<int> entryDays;
  final Map<int, int> dayMoods;
  final int? selectedDay;
  final List<JournalEntry> monthEntries;
  final List<JournalEntry> selectedEntries;
  final int weekStartDay;
  final ValueChanged<int> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (isTablet(context)) {
      return _buildTabletLayout(context, cs, tt);
    }
    return _buildPhoneLayout(context, cs, tt);
  }

  Widget _buildTabletLayout(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: AdaptiveTwoPane(
        leftFraction: 0.5,
        left: SingleChildScrollView(child: _buildCalendarGrid()),
        right: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildEntryList(cs, tt),
        ),
      ),
    );
  }

  Widget _buildPhoneLayout(BuildContext context, ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarGrid(),
        const SizedBox(height: AppSpacing.md),
        _buildEntryList(cs, tt),
      ],
    );
  }

  Widget _buildEntryList(ColorScheme cs, TextTheme tt) {
    // Day selected — show entries for that day
    if (selectedDay != null) {
      if (selectedEntries.isNotEmpty) {
        return Animate(
          key: ValueKey('day-$selectedDay-${selectedMonth.month}'),
          effects: [
            FadeEffect(duration: 380.ms, curve: Curves.easeOut),
            SlideEffect(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
              duration: 420.ms,
              curve: AppMotion.emphasizedDecelerate,
            ),
          ],
          child: EntryDetailView(
            entries: selectedEntries,
            date: DateTime(
              selectedMonth.year,
              selectedMonth.month,
              selectedDay!,
            ),
          ),
        );
      }
      return Animate(
        key: ValueKey('day-empty-$selectedDay-${selectedMonth.month}'),
        effects: [FadeEffect(duration: 320.ms, curve: Curves.easeOut)],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(
            child: Text(
              'No entry for this day',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }

    // No day selected — show all entries for the month grouped by day
    if (monthEntries.isEmpty) {
      return Animate(
        key: ValueKey('month-empty-${selectedMonth.month}'),
        effects: [FadeEffect(duration: 320.ms, curve: Curves.easeOut)],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(
            child: BionicText(
              text: 'No entries this month.',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              enabled: false, // Static empty state
            ),
          ),
        ),
      );
    }

    return _MonthEntryList(
      key: ValueKey('month-${selectedMonth.year}-${selectedMonth.month}'),
      entries: monthEntries,
      selectedMonth: selectedMonth,
    );
  }

  CalendarGrid _buildCalendarGrid() {
    return CalendarGrid(
      month: selectedMonth,
      entryDays: entryDays,
      dayMoods: dayMoods,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
      onPreviousMonth: onPreviousMonth,
      onNextMonth: onNextMonth,
      weekStartDay: weekStartDay,
    );
  }
}

/// Groups month entries by day and renders them with date dividers.
class _MonthEntryList extends StatelessWidget {
  const _MonthEntryList({
    super.key,
    required this.entries,
    required this.selectedMonth,
  });

  final List<JournalEntry> entries;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduce(context);

    // Group by day
    final grouped = <int, List<JournalEntry>>{};
    for (final entry in entries) {
      final day = entry.date.day;
      (grouped[day] ??= []).add(entry);
    }

    // Within each day, sort oldest-first so readers scan top-to-bottom
    // chronologically. Days themselves are ordered newest first below.
    for (final list in grouped.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    // Sort days descending (newest first)
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final detail = EntryDetailView(
          entries: grouped[day]!,
          date: DateTime(selectedMonth.year, selectedMonth.month, day),
        );
        if (reduceMotion) return detail;
        // Cap stagger so a long month does not delay later items past ~700ms.
        final delayMs = (index * 50).clamp(0, 700);
        return Animate(
          effects: [
            FadeEffect(
              delay: delayMs.ms,
              duration: 360.ms,
              curve: Curves.easeOut,
            ),
            SlideEffect(
              delay: delayMs.ms,
              begin: const Offset(0, 0.08),
              end: Offset.zero,
              duration: 400.ms,
              curve: AppMotion.emphasizedDecelerate,
            ),
          ],
          child: detail,
        );
      },
    );
  }
}
