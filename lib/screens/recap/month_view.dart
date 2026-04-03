import 'package:flutter/material.dart';

import '../../models/journal_entry.dart';
import '../../theme/app_spacing.dart';
import '../../utils/adaptive_layout.dart';
import '../../widgets/organisms/calendar_grid.dart';
import '../../widgets/organisms/entry_detail_view.dart';

/// Month / calendar view section of the Recap screen.
class RecapMonthView extends StatelessWidget {
  const RecapMonthView({
    super.key,
    required this.selectedMonth,
    required this.entryDays,
    this.selectedDay,
    required this.selectedEntries,
    required this.weekStartDay,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime selectedMonth;
  final Set<int> entryDays;
  final int? selectedDay;
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
        left: SingleChildScrollView(
          child: _buildCalendarGrid(),
        ),
        right: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: selectedDay != null && selectedEntries.isNotEmpty
              ? EntryDetailView(
                  entries: selectedEntries,
                  date: DateTime(
                    selectedMonth.year,
                    selectedMonth.month,
                    selectedDay!,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxl),
                  child: Center(
                    child: Text(
                      selectedDay != null
                          ? 'No entry for this day'
                          : 'Select a day to view entries',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPhoneLayout(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarGrid(),

        // Entry detail (when a day is selected)
        if (selectedDay != null && selectedEntries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          EntryDetailView(
            entries: selectedEntries,
            date: DateTime(
              selectedMonth.year,
              selectedMonth.month,
              selectedDay!,
            ),
          ),
        ] else if (selectedDay != null && selectedEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                'No entry for this day',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
      ],
    );
  }

  CalendarGrid _buildCalendarGrid() {
    return CalendarGrid(
      month: selectedMonth,
      entryDays: entryDays,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
      onPreviousMonth: onPreviousMonth,
      onNextMonth: onNextMonth,
      weekStartDay: weekStartDay,
    );
  }
}
