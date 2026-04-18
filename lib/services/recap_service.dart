// ignore_for_file: prefer_single_quotes

import 'ai/recap_ai_provider.dart';
import 'app_log.dart';
import 'entry_repository.dart';

/// Weekly recap generation.
///
/// Stats (entry count, streak, busiest day, mood distribution) are always
/// computed deterministically from the Drift query. The `observation`
/// string is produced by a [RecapAiProvider] — the [TemplateRecapAiProvider]
/// by default, or a [PlatformRecapAiProvider] when the user has opted in
/// *and* the device reports on-device AI capability.
class RecapService {
  final EntryRepository _entries;
  final RecapAiProvider _templateProvider;
  final RecapAiProvider _platformProvider;

  RecapService(
    this._entries, {
    RecapAiProvider? templateProvider,
    RecapAiProvider? platformProvider,
  })  : _templateProvider = templateProvider ?? const TemplateRecapAiProvider(),
        _platformProvider = platformProvider ?? PlatformRecapAiProvider();

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
    int weekStartDay, {
    bool useOnDeviceAi = false,
  }) async {
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
    final activeDaysSet =
        entries.map((e) {
          final d = e.date;
          return DateTime(d.year, d.month, d.day);
        }).toSet();
    final activeDays = activeDaysSet.length;

    // Streak: consecutive days with entries starting from weekStart
    int streak = 0;
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayNorm = DateTime(day.year, day.month, day.day);
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

    // Always compute a template observation — it's the guaranteed
    // fallback if the on-device AI is disabled, unavailable, or errors.
    String observation = await _templateProvider.summarize(
      totalEntries: totalEntries,
      activeDays: activeDays,
      streak: streak,
      busiestDay: busiestDay,
      preferredTime: preferredTime,
      averageMood: averageMood,
      entries: entries,
    );

    // Only reach for on-device AI if the user has opted in AND there's
    // actual content worth summarizing. The empty/single-entry template
    // strings are already the correct thing to show in those cases.
    if (useOnDeviceAi && totalEntries >= 2) {
      try {
        final status = await _platformProvider.checkStatus();
        if (status == RecapAiStatus.available) {
          final aiObservation = await _platformProvider.summarize(
            totalEntries: totalEntries,
            activeDays: activeDays,
            streak: streak,
            busiestDay: busiestDay,
            preferredTime: preferredTime,
            averageMood: averageMood,
            entries: entries,
          );
          if (aiObservation.isNotEmpty) {
            observation = aiObservation;
          }
        }
      } catch (e) {
        // Never fail the recap just because the AI call failed — the
        // user still sees the deterministic template summary above.
        AppLog.error('RecapService.platformAi', e);
      }
    }

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
