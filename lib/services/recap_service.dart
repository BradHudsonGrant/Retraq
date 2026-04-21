// ignore_for_file: prefer_single_quotes

import '../utils/date_helpers.dart';
import 'entry_repository.dart';

/// Weekly recap generation.
///
/// Stats (entry count, streak, busiest day, mood distribution) and the
/// observation string are all computed deterministically from the entry
/// data. There is no AI/ML inference — the recap is a plain template.
class RecapService {
  final EntryRepository _entries;

  RecapService(this._entries);

  static const _dayNames = {
    DateTime.monday: "Monday",
    DateTime.tuesday: "Tuesday",
    DateTime.wednesday: "Wednesday",
    DateTime.thursday: "Thursday",
    DateTime.friday: "Friday",
    DateTime.saturday: "Saturday",
    DateTime.sunday: "Sunday",
  };

  Future<WeeklySummary> getWeeklySummary(
    DateTime weekStart,
    int weekStartDay,
  ) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final entries = await _entries.getEntriesForDateRange(weekStart, weekEnd);

    // Count entries per weekday
    final entryCountPerDay = <int, int>{};
    for (final entry in entries) {
      entryCountPerDay[entry.date.weekday] =
          (entryCountPerDay[entry.date.weekday] ?? 0) + 1;
    }

    final totalEntries = entries.length;

    // Busiest day
    String busiestDay = "";
    if (entryCountPerDay.isNotEmpty) {
      final busiestWeekday =
          entryCountPerDay.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
      busiestDay = _dayNames[busiestWeekday] ?? "";
    }

    // Preferred time: count AM vs PM labels
    int amCount = 0;
    int pmCount = 0;
    for (final entry in entries) {
      if (entry.label == "AM") {
        amCount++;
      } else if (entry.label == "PM") {
        pmCount++;
      }
    }
    String preferredTime;
    if (amCount > 0 && pmCount == 0) {
      preferredTime = "morning";
    } else if (pmCount > 0 && amCount == 0) {
      preferredTime = "evening";
    } else {
      preferredTime = "throughout the day";
    }

    // Active days (unique days with entries)
    final activeDaysSet = entries.map((e) => dateOnly(e.date)).toSet();
    final activeDays = activeDaysSet.length;

    // Streak: consecutive days with entries starting from weekStart
    int streak = 0;
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayNorm = dateOnly(day);
      if (activeDaysSet.contains(dayNorm)) {
        streak++;
      } else {
        if (streak > 0) break; // stop at first gap after entries start
      }
    }

    // Mood statistics
    final moodDistribution = <int, int>{};
    int moodSum = 0;
    int moodCount = 0;
    for (final entry in entries) {
      if (entry.mood != null) {
        moodDistribution[entry.mood!] =
            (moodDistribution[entry.mood!] ?? 0) + 1;
        moodSum += entry.mood!;
        moodCount++;
      }
    }
    final averageMood = moodCount > 0 ? moodSum / moodCount : null;

    final observation = _buildObservation(
      totalEntries: totalEntries,
      activeDays: activeDays,
      streak: streak,
      busiestDay: busiestDay,
      averageMood: averageMood,
    );

    return WeeklySummary(
      totalEntries: totalEntries,
      busiestDay: busiestDay,
      preferredTime: preferredTime,
      activeDays: activeDays,
      streak: streak,
      observation: observation,
      averageMood: averageMood,
      moodDistribution: moodDistribution,
    );
  }

  static String _buildObservation({
    required int totalEntries,
    required int activeDays,
    required int streak,
    required String busiestDay,
    required double? averageMood,
  }) {
    String observation;
    if (totalEntries == 0) {
      observation =
          "No entries this week. That's okay \u2014 every week is different.";
    } else if (totalEntries == 1) {
      observation =
          "You captured one moment this week. Even a single entry matters.";
    } else if (activeDays == 7) {
      observation =
          "You journaled every day this week! Incredible consistency.";
    } else if (streak >= 3) {
      observation = "You're on a $streak-day streak. Nice momentum!";
    } else {
      observation =
          "You wrote $totalEntries entries across $activeDays days. $busiestDay was your most active day.";
    }
    if (averageMood != null) {
      observation += " Your average mood was ${_moodLabel(averageMood)}.";
    }
    return observation;
  }

  static String _moodLabel(double avg) {
    if (avg >= 4.5) return "Amazing";
    if (avg >= 3.5) return "Good";
    if (avg >= 2.5) return "Neutral";
    if (avg >= 1.5) return "Low";
    return "Rough";
  }
}

/// Summary data for a single week.
class WeeklySummary {
  final int totalEntries;
  final String busiestDay;
  final String preferredTime;
  final int activeDays;
  final int streak;
  final String observation;
  final double? averageMood;
  final Map<int, int> moodDistribution; // mood value -> count

  const WeeklySummary({
    this.totalEntries = 0,
    this.busiestDay = "",
    this.preferredTime = "throughout the day",
    this.activeDays = 0,
    this.streak = 0,
    this.observation = "",
    this.averageMood,
    this.moodDistribution = const {},
  });
}
