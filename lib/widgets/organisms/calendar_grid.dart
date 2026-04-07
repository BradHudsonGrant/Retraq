import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Monthly calendar grid with entry dot indicators.
/// Respects the user's weekStartDay setting for column order.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.entryDays,
    this.dayMoods = const {},
    this.selectedDay,
    this.onDaySelected,
    this.onPreviousMonth,
    this.onNextMonth,
    this.weekStartDay = 1,
  });

  final DateTime month;
  final Set<int> entryDays;

  /// Mood value (1-5) per day number. Used to tint entry dot indicators.
  final Map<int, int> dayMoods;

  final int? selectedDay;
  final ValueChanged<int>? onDaySelected;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  /// 1 = Monday, 7 = Sunday
  final int weekStartDay;

  List<String> _dayLabels(L10n l10n) {
    final allLabels = [
      l10n.dayMo,
      l10n.dayTu,
      l10n.dayWe,
      l10n.dayTh,
      l10n.dayFr,
      l10n.daySa,
      l10n.daySu,
    ];
    final startIndex = (weekStartDay - 1) % 7;
    return [
      ...allLabels.sublist(startIndex),
      ...allLabels.sublist(0, startIndex),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusXxl,
      ),
      child: Column(
        children: [
          // ── Header with navigation ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.monthAtGlance,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: onPreviousMonth,
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.previousMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(month),
                    style: tt.labelLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: onNextMonth,
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.nextMonth,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Day-of-week labels ──
          Row(
            children:
                _dayLabels(l10n)
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Calendar day cells ──
          ..._buildWeeks(context),
        ],
      ),
    );
  }

  List<Widget> _buildWeeks(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // Offset from the configured start day
    final startOffset = (firstOfMonth.weekday - weekStartDay + 7) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    final cells = <Widget>[];

    // Previous month padding
    final prevMonth = DateTime(month.year, month.month, 0);
    for (var i = 0; i < startOffset; i++) {
      final day = prevMonth.day - startOffset + i + 1;
      cells.add(_DayCell(day: day, isDimmed: true));
    }

    // Current month days
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final brightness = Theme.of(context).brightness;
    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(
        _DayCell(
          day: day,
          isSelected: day == selectedDay,
          hasEntry: entryDays.contains(day),
          moodValue: dayMoods[day],
          brightness: brightness,
          isToday: isCurrentMonth && day == now.day,
          onTap: () => onDaySelected?.call(day),
        ),
      );
    }

    // Next month padding
    final remaining = (7 - cells.length % 7) % 7;
    for (var i = 1; i <= remaining; i++) {
      cells.add(_DayCell(day: i, isDimmed: true));
    }

    // Chunk into rows of 7
    final weeks = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children:
                cells.sublist(i, i + 7).map((c) => Expanded(child: c)).toList(),
          ),
        ),
      );
    }

    return weeks;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    this.isSelected = false,
    this.hasEntry = false,
    this.moodValue,
    this.brightness = Brightness.light,
    this.isToday = false,
    this.isDimmed = false,
    this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool hasEntry;

  /// Mood value 1-5 for this day, or null if no mood set.
  final int? moodValue;

  /// Current brightness, used to pick the right mood color palette.
  final Brightness brightness;

  final bool isToday;
  final bool isDimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;

    final a11yLabel = StringBuffer(l10n.calendarDayA11y(day));
    if (isToday) a11yLabel.write(l10n.calendarDayTodaySuffix);
    if (hasEntry) a11yLabel.write(l10n.calendarDayHasEntriesSuffix);
    if (isSelected) a11yLabel.write(l10n.calendarDaySelectedSuffix);

    return Semantics(
      button: !isDimmed,
      label: a11yLabel.toString(),
      child: InkWell(
        onTap: isDimmed ? null : onTap,
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 52,
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration:
                  isSelected
                      ? BoxDecoration(color: cs.primary, shape: BoxShape.circle)
                      : isToday
                      ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      )
                      : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: tt.bodySmall?.copyWith(
                      color:
                          isDimmed
                              ? cs.onSurfaceVariant.withValues(alpha: 0.65)
                              : isSelected
                              ? cs.onPrimary
                              : cs.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  if (hasEntry && !isDimmed)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? cs.onPrimary
                                : moodValue != null &&
                                    moodValue! >= 1 &&
                                    moodValue! <= 5
                                ? AppColors.moodColors(brightness)[moodValue! -
                                    1]
                                : cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
