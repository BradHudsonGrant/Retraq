import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_spacing.dart';

/// Monthly calendar grid with entry dot indicators.
/// Respects the user's weekStartDay setting for column order.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.entryDays,
    this.selectedDay,
    this.onDaySelected,
    this.onPreviousMonth,
    this.onNextMonth,
    this.weekStartDay = 1,
  });

  final DateTime month;
  final Set<int> entryDays;
  final int? selectedDay;
  final ValueChanged<int>? onDaySelected;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  /// 1 = Monday, 7 = Sunday
  final int weekStartDay;

  /// Day-of-week labels in the correct order. Cached per weekStartDay.
  static final _labelCache = <int, List<String>>{};

  List<String> get _dayLabels {
    return _labelCache.putIfAbsent(weekStartDay, () {
      const allLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
      final startIndex = (weekStartDay - 1) % 7;
      return [
        ...allLabels.sublist(startIndex),
        ...allLabels.sublist(0, startIndex),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                'Month at a glance',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: onPreviousMonth,
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Previous month',
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
                    tooltip: 'Next month',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Day-of-week labels ──
          Row(
            children: _dayLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
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
    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(_DayCell(
        day: day,
        isSelected: day == selectedDay,
        hasEntry: entryDays.contains(day),
        onTap: () => onDaySelected?.call(day),
      ));
    }

    // Next month padding
    final remaining = (7 - cells.length % 7) % 7;
    for (var i = 1; i <= remaining; i++) {
      cells.add(_DayCell(day: i, isDimmed: true));
    }

    // Chunk into rows of 7
    final weeks = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: cells
              .sublist(i, i + 7)
              .map((c) => Expanded(child: c))
              .toList(),
        ),
      ));
    }

    return weeks;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    this.isSelected = false,
    this.hasEntry = false,
    this.isDimmed = false,
    this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool hasEntry;
  final bool isDimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      button: !isDimmed,
      label: 'Day $day${hasEntry ? ', has entries' : ''}${isSelected ? ', selected' : ''}',
      child: InkWell(
      onTap: isDimmed ? null : onTap,
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: isSelected
                  ? BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: tt.bodySmall?.copyWith(
                  color: isDimmed
                      ? cs.onSurfaceVariant.withValues(alpha: 0.65)
                      : isSelected
                          ? cs.onPrimary
                          : cs.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (hasEntry && !isDimmed)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? cs.onPrimary : cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }
}
