import 'package:intl/intl.dart';

String formatDateLabel(DateTime date, {bool capitalize = true}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final entryDate = DateTime(date.year, date.month, date.day);
  final diff = today.difference(entryDate).inDays;

  String label;
  if (diff == 0) {
    label = 'today';
  } else if (diff == 1) {
    label = 'yesterday';
  } else if (diff < 7) {
    label = DateFormat('EEEE').format(date);
  } else {
    label = DateFormat('MMM d').format(date);
  }
  if (capitalize) {
    return label[0].toUpperCase() + label.substring(1);
  }
  return label;
}

String formatHour(int hour) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:00 $period';
}

/// Calculate the start of the current week given a weekStartDay (1=Mon..7=Sun).
DateTime weekStartDate({int weekStartDay = 1}) {
  final now = DateTime.now();
  final offset = (now.weekday - weekStartDay + 7) % 7;
  return DateTime(now.year, now.month, now.day - offset);
}

/// First day of the month after [month], handling December → January.
DateTime startOfNextMonth(DateTime month) {
  return (month.month == 12)
      ? DateTime(month.year + 1, 1)
      : DateTime(month.year, month.month + 1);
}

/// Compute strftime('%Y-%W')-compatible week label for a given date.
/// %W = week number of year (Monday as first day), zero-padded.
String strftimeYW(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  final w = (dayOfYear + 6 - (date.weekday == 7 ? 6 : date.weekday - 1)) ~/ 7;
  return '${date.year}-${w.toString().padLeft(2, '0')}';
}
