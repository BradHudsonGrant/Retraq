// ignore_for_file: prefer_single_quotes

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show listEquals;
import '../models/journal_entry.dart';
import 'app_log.dart';
import 'database_service.dart';

/// All stats/analytics queries.
class StatsService {
  final AppDatabase _db;

  StatsService(this._db);

  /// Count consecutive days with entries ending today or yesterday.
  ///
  /// Strict streak: any gap breaks the count. The earlier "1 freeze per
  /// 7-day window" allowance was removed in the Traq rename sweep since
  /// the UX was confusing (users couldn't tell when a freeze was being
  /// spent on their behalf) and the extra code paths were carrying
  /// disproportionate maintenance cost.
  Future<int> getCurrentStreak() async {
    try {
      final now = DateTime.now();
      final todayStr = _dateStr(now);

      // Query a modest window back — any real streak longer than ~3
      // years would already have hit the safety break below, and
      // limiting the fetch keeps the DB round-trip cheap on big
      // journals.
      final earliestRelevant = now.subtract(const Duration(days: 1200));
      final earliestRelevantStr = _dateStr(earliestRelevant);

      final rows = await _db
          .customSelect(
            "SELECT DISTINCT date(date, 'unixepoch', 'localtime') AS d "
            "FROM journal_entries WHERE date(date, 'unixepoch', 'localtime') <= ? "
            "AND date(date, 'unixepoch', 'localtime') >= ? "
            "ORDER BY d DESC LIMIT 1100",
            variables: [
              Variable<String>(todayStr),
              Variable<String>(earliestRelevantStr),
            ],
            readsFrom: {_db.journalEntries},
          )
          .get();

      if (rows.isEmpty) return 0;

      final entryDates = <String>{};
      for (final row in rows) {
        entryDates.add(row.read<String>('d'));
      }

      // The streak must anchor to today or yesterday — otherwise there's
      // no "current" streak to report.
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = _dateStr(yesterday);
      if (!entryDates.contains(todayStr) &&
          !entryDates.contains(yesterdayStr)) {
        return 0;
      }

      int streak = 0;
      var cursor = DateTime(now.year, now.month, now.day);
      while (true) {
        final cursorStr = _dateStr(cursor);
        if (entryDates.contains(cursorStr)) {
          streak++;
        } else {
          if (streak == 0) {
            // Today is empty but yesterday isn't: skip today and anchor
            // the streak at yesterday. This keeps the streak visible all
            // day on the day after the user last journaled, matching the
            // usual "habit tracker" expectation.
            cursor = cursor.subtract(const Duration(days: 1));
            continue;
          }
          break;
        }
        cursor = cursor.subtract(const Duration(days: 1));
        if (streak > 1095) break;
      }

      return streak;
    } catch (e) {
      AppLog.error('StatsService.getCurrentStreak', e);
      return 0;
    }
  }

  /// Longest streak within the current calendar month.
  Future<int> getLongestStreakThisMonth() async {
    try {
      final now = DateTime.now();
      final monthStart =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final todayStr = _dateStr(now);

      final rows =
          await _db
              .customSelect(
                "WITH dates AS ("
                "  SELECT DISTINCT date(date, 'unixepoch', 'localtime') AS d"
                "  FROM journal_entries"
                "  WHERE date(date, 'unixepoch', 'localtime') BETWEEN ? AND ?"
                "), grouped AS ("
                "  SELECT d, date(d, '-' || (ROW_NUMBER() OVER (ORDER BY d) - 1) || ' days') AS grp"
                "  FROM dates"
                ")"
                "SELECT COALESCE(MAX(cnt), 0) AS longest FROM ("
                "  SELECT COUNT(*) AS cnt FROM grouped GROUP BY grp"
                ")",
                variables: [
                  Variable<String>(monthStart),
                  Variable<String>(todayStr),
                ],
                readsFrom: {_db.journalEntries},
              )
              .get();

      return rows.first.read<int>('longest');
    } catch (e) {
      AppLog.error('StatsService.getLongestStreakThisMonth', e);
      return 0;
    }
  }

  /// Format a DateTime as 'YYYY-MM-DD'.
  static String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Find the longest ever run of consecutive days with entries.
  /// Uses SQL window functions to compute entirely in the database.
  Future<int> getLongestStreak() async {
    try {
      final rows =
          await _db
              .customSelect(
                // Group consecutive dates: subtract row_number days from each date.
                // Dates in the same consecutive run will produce the same group key.
                // Then count each group and take the max.
                "WITH dates AS ("
                "  SELECT DISTINCT date(date, 'unixepoch', 'localtime') AS d"
                "  FROM journal_entries"
                "), grouped AS ("
                "  SELECT d, date(d, '-' || (ROW_NUMBER() OVER (ORDER BY d) - 1) || ' days') AS grp"
                "  FROM dates"
                ")"
                "SELECT COALESCE(MAX(cnt), 0) AS longest FROM ("
                "  SELECT COUNT(*) AS cnt FROM grouped GROUP BY grp"
                ")",
                readsFrom: {_db.journalEntries},
              )
              .get();

      return rows.first.read<int>('longest');
    } catch (e) {
      AppLog.error('StatsService.getLongestStreak', e);
      return 0;
    }
  }

  /// Return entry counts per week for the last [weeks] weeks.
  /// Returns a `List<int>` of length [weeks], index 0 = oldest week.
  ///
  /// The previous implementation bucketed in SQL with `strftime('%Y-%W', ...)`
  /// and matched each row against a Dart-computed `strftimeYW(weekStart)`
  /// label. SQLite's `%W` uses "first Monday of year" numbering which the
  /// Dart helper approximated as `dayOfYear // 7`, so the two week IDs
  /// drifted apart: rows could get bucketed into a week the result list
  /// never asked for, and the visible bars became effectively random.
  ///
  /// The fix is to do the bucketing in Dart from raw timestamps. Bucket
  /// [weeks - 1] (rightmost bar) covers the last 7 days ending today;
  /// each earlier bucket is the prior 7-day window. This matches what
  /// the chart labels ("Now", "3w", "6w") actually describe.
  Future<List<int>> getWeeklyEntryCounts({int weeks = 12}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Last bucket covers [today - 6, today]; earliest covers
      // [today - weeks*7 + 1, today - (weeks-1)*7]. Include an extra day
      // in the query window so a midnight-boundary entry doesn't slip
      // past the cutoff; we recheck ranges in Dart.
      final windowStart = today.subtract(Duration(days: weeks * 7));
      final windowStartEpoch =
          windowStart.toUtc().millisecondsSinceEpoch ~/ 1000;

      final rows = await _db
          .customSelect(
            'SELECT date FROM journal_entries WHERE date >= ?',
            variables: [Variable.withInt(windowStartEpoch)],
            readsFrom: {_db.journalEntries},
          )
          .get();

      final result = List<int>.filled(weeks, 0);
      for (final row in rows) {
        final epoch = row.read<int>('date');
        final entryDate =
            DateTime.fromMillisecondsSinceEpoch(epoch * 1000).toLocal();
        final day = DateTime(entryDate.year, entryDate.month, entryDate.day);
        final daysAgo = today.difference(day).inDays;
        if (daysAgo < 0 || daysAgo >= weeks * 7) continue;
        // bucketIdx = weeks - 1 for daysAgo in 0..6, weeks - 2 for 7..13, etc.
        final bucketIdx = weeks - 1 - (daysAgo ~/ 7);
        if (bucketIdx >= 0 && bucketIdx < weeks) {
          result[bucketIdx]++;
        }
      }
      return result;
    } catch (e) {
      AppLog.error('StatsService.getWeeklyEntryCounts', e);
      return List.filled(weeks, 0);
    }
  }

  /// Return the day of week (1=Mon..7=Sun) with the most entries.
  /// Returns 0 if no entries exist.
  Future<int> getMostActiveWeekday() async {
    try {
      final rows =
          await _db
              .customSelect(
                "SELECT CAST(strftime('%w', date, 'unixepoch', 'localtime') AS INTEGER) as dow, "
                "COUNT(*) as cnt FROM journal_entries GROUP BY dow ORDER BY cnt DESC LIMIT 1",
                readsFrom: {_db.journalEntries},
              )
              .get();

      if (rows.isEmpty) return 0;

      // strftime %w: 0=Sunday, 1=Monday, ..., 6=Saturday
      // Convert to 1=Mon..7=Sun
      final dow = rows.first.read<int>('dow');
      return dow == 0 ? 7 : dow;
    } catch (e) {
      AppLog.error('StatsService.getMostActiveWeekday', e);
      return 0;
    }
  }

  /// Internal helper — total distinct days with entries (non-stream).
  /// Uses SQL date extraction to count distinct calendar dates, ignoring
  /// time-of-day differences in the stored unix epoch timestamps.
  Future<int> getTotalDaysWithEntries() async {
    try {
      final result =
          await _db
              .customSelect(
                "SELECT COUNT(DISTINCT date(date, 'unixepoch', 'localtime')) as cnt FROM journal_entries",
                readsFrom: {_db.journalEntries},
              )
              .getSingle();
      return result.read<int>('cnt');
    } catch (e) {
      AppLog.error('StatsService.getTotalDaysWithEntries', e);
      return 0;
    }
  }

  /// Total entry count (used internally by getAllStats).
  Future<int> _getTotalEntryCount() async {
    try {
      final count = _db.journalEntries.id.count();
      final query = _db.selectOnly(_db.journalEntries)..addColumns([count]);
      final row = await query.getSingle();
      return row.read(count) ?? 0;
    } catch (e) {
      AppLog.error('StatsService._getTotalEntryCount', e);
      return 0;
    }
  }

  /// Average mood across all entries with mood set (1.0-5.0), or null.
  Future<double?> getAverageMood() async {
    try {
      final rows =
          await _db
              .customSelect(
                "SELECT AVG(CAST(mood AS REAL)) as avg_mood FROM journal_entries WHERE mood IS NOT NULL",
                readsFrom: {_db.journalEntries},
              )
              .get();
      final val = rows.first.readNullable<double>('avg_mood');
      return val;
    } catch (e) {
      AppLog.error('StatsService.getAverageMood', e);
      return null;
    }
  }

  /// Distribution of mood values (count per mood level 1-5).
  /// Returns a `Map<int, int>` where key=mood (1-5), value=count.
  Future<Map<int, int>> getMoodDistribution() async {
    try {
      final rows =
          await _db
              .customSelect(
                "SELECT mood, COUNT(*) as cnt FROM journal_entries WHERE mood IS NOT NULL GROUP BY mood ORDER BY mood",
                readsFrom: {_db.journalEntries},
              )
              .get();
      final result = <int, int>{};
      for (final row in rows) {
        result[row.read<int>('mood')] = row.read<int>('cnt');
      }
      return result;
    } catch (e) {
      AppLog.error('StatsService.getMoodDistribution', e);
      return {};
    }
  }

  /// Returns "On This Day" entries — prior-year journal entries matching
  /// today's month + day. Used by the Stats screen to surface recurring
  /// memories.
  ///
  /// Task 1.3 — previously lived inline inside `stats_screen.dart`,
  /// which made it untestable without spinning up the whole widget.
  /// The business rule is small but has two sharp edges worth pinning
  /// in a dedicated test: leap-day behaviour (Feb 29 from a non-leap
  /// year) and "entries on the same calendar day" equality across
  /// timezones.
  ///
  /// [today] defaults to `DateTime.now()` and is overridable for tests
  /// so time-dependent assertions remain deterministic.
  /// [yearsBack] defaults to 1 (the Stats screen's "one year ago"
  /// surface). Callers asking for the full "on-this-day N years ago"
  /// list across many years can iterate this method.
  Future<List<JournalEntry>> onThisDayEntries({
    DateTime? today,
    int yearsBack = 1,
  }) async {
    assert(yearsBack > 0, 'yearsBack must be positive');
    final now = today ?? DateTime.now();
    // Feb 29 requested from a non-leap target year silently snaps to
    // Feb 28 — same behaviour as `DateTime(year, 2, 29)` which
    // Dart normalises into "Mar 1". Snapping to Feb 28 keeps the
    // surface populated on the 3-out-of-4 non-leap years instead of
    // jumping to March and surfacing the wrong day.
    final targetYear = now.year - yearsBack;
    final isLeapDayRequest = now.month == 2 && now.day == 29;
    final targetIsLeapYear =
        targetYear % 4 == 0 && (targetYear % 100 != 0 || targetYear % 400 == 0);
    final targetDay =
        (isLeapDayRequest && !targetIsLeapYear) ? 28 : now.day;
    final target = DateTime(targetYear, now.month, targetDay);
    try {
      return await DatabaseService.instance.entries
          .getEntriesForDate(target);
    } catch (e) {
      AppLog.error('StatsService.onThisDayEntries', e);
      return const [];
    }
  }

  /// Lightweight data for the home screen widget.
  ///
  /// Only queries current streak and total entry count — much cheaper than
  /// [getAllStats] which computes 9+ metrics. Designed to run quickly in a
  /// background isolate on mobile.
  Future<WidgetData> getWidgetData() async {
    try {
      final results = await Future.wait([
        getCurrentStreak(),
        _getTotalEntryCount(),
      ]);
      return WidgetData(currentStreak: results[0], totalEntries: results[1]);
    } catch (e) {
      AppLog.error('StatsService.getWidgetData', e);
      return const WidgetData();
    }
  }

  // ---------------------------------------------------------------------------
  // Batch query helpers — consolidate multiple independent queries into fewer
  // database round-trips for use by [getAllStats].
  // ---------------------------------------------------------------------------

  /// Single query returning both total entry count and total distinct days.
  Future<({int totalEntries, int totalDays})> _getBatchCounts() async {
    try {
      final row =
          await _db
              .customSelect(
                "SELECT COUNT(*) AS cnt, "
                "COUNT(DISTINCT date(date, 'unixepoch', 'localtime')) AS days "
                "FROM journal_entries",
                readsFrom: {_db.journalEntries},
              )
              .getSingle();
      return (
        totalEntries: row.read<int>('cnt'),
        totalDays: row.read<int>('days'),
      );
    } catch (e) {
      AppLog.error('StatsService._getBatchCounts', e);
      return (totalEntries: 0, totalDays: 0);
    }
  }

  /// Single query returning mood distribution; average mood is derived in Dart.
  Future<({double? averageMood, Map<int, int> distribution})>
  _getBatchMoodStats() async {
    try {
      final rows =
          await _db
              .customSelect(
                "SELECT mood, COUNT(*) AS cnt "
                "FROM journal_entries WHERE mood IS NOT NULL "
                "GROUP BY mood ORDER BY mood",
                readsFrom: {_db.journalEntries},
              )
              .get();
      final distribution = <int, int>{};
      int totalCount = 0;
      double weightedSum = 0;
      for (final row in rows) {
        final mood = row.read<int>('mood');
        final count = row.read<int>('cnt');
        distribution[mood] = count;
        totalCount += count;
        weightedSum += mood * count;
      }
      final averageMood = totalCount > 0 ? weightedSum / totalCount : null;
      return (averageMood: averageMood, distribution: distribution);
    } catch (e) {
      AppLog.error('StatsService._getBatchMoodStats', e);
      return (averageMood: null, distribution: const <int, int>{});
    }
  }

  /// Single query returning both all-time longest streak and current-month
  /// longest streak. Uses two independent grouped sub-CTEs within one
  /// statement so only one database round-trip is needed.
  Future<({int longestStreak, int longestStreakThisMonth})>
  _getBatchStreaks() async {
    try {
      final now = DateTime.now();
      final monthStart =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final todayStr = _dateStr(now);

      final rows =
          await _db
              .customSelect(
                // All-time streak
                "WITH all_dates AS ("
                "  SELECT DISTINCT date(date, 'unixepoch', 'localtime') AS d"
                "  FROM journal_entries"
                "), all_grouped AS ("
                "  SELECT d,"
                "    date(d, '-' || (ROW_NUMBER() OVER (ORDER BY d) - 1) || ' days') AS grp"
                "  FROM all_dates"
                "), "
                // Month-only streak (bounded to current month)
                "month_dates AS ("
                "  SELECT DISTINCT date(date, 'unixepoch', 'localtime') AS d"
                "  FROM journal_entries"
                "  WHERE date(date, 'unixepoch', 'localtime') BETWEEN ? AND ?"
                "), month_grouped AS ("
                "  SELECT d,"
                "    date(d, '-' || (ROW_NUMBER() OVER (ORDER BY d) - 1) || ' days') AS grp"
                "  FROM month_dates"
                ")"
                "SELECT"
                "  COALESCE((SELECT MAX(cnt) FROM (SELECT COUNT(*) AS cnt FROM all_grouped GROUP BY grp)), 0) AS longest,"
                "  COALESCE((SELECT MAX(cnt) FROM (SELECT COUNT(*) AS cnt FROM month_grouped GROUP BY grp)), 0) AS longest_month",
                variables: [
                  Variable<String>(monthStart),
                  Variable<String>(todayStr),
                ],
                readsFrom: {_db.journalEntries},
              )
              .get();

      if (rows.isEmpty) {
        return (longestStreak: 0, longestStreakThisMonth: 0);
      }

      return (
        longestStreak: rows.first.read<int>('longest'),
        longestStreakThisMonth: rows.first.read<int>('longest_month'),
      );
    } catch (e) {
      AppLog.error('StatsService._getBatchStreaks', e);
      return (longestStreak: 0, longestStreakThisMonth: 0);
    }
  }

  /// Combined stats snapshot — computes all stats with consolidated queries
  /// to reduce database round-trips. Use [watchAllStats] for the stream.
  Future<StatsSnapshot> getAllStats({int weeks = 12}) async {
    try {
      // 6 parallel queries instead of the original 9:
      //  _getBatchCounts      = _getTotalEntryCount + getTotalDaysWithEntries
      //  _getBatchMoodStats   = getAverageMood + getMoodDistribution
      //  _getBatchStreaks      = getLongestStreak + getLongestStreakThisMonth
      //  (remaining 3 unchanged)
      final results = await Future.wait([
        _getBatchCounts(), // 0
        getCurrentStreak(), // 1
        _getBatchStreaks(), // 2
        getWeeklyEntryCounts(weeks: weeks), // 3
        getMostActiveWeekday(), // 4
        _getBatchMoodStats(), // 5
      ]);

      final counts = results[0] as ({int totalEntries, int totalDays});
      final currentStreak = results[1] as int;
      final streaks =
          results[2] as ({int longestStreak, int longestStreakThisMonth});
      final moodStats =
          results[5] as ({double? averageMood, Map<int, int> distribution});

      return StatsSnapshot(
        totalEntries: counts.totalEntries,
        totalDays: counts.totalDays,
        currentStreak: currentStreak,
        longestStreak: streaks.longestStreak,
        weeklyTrends: results[3] as List<int>,
        mostActiveWeekday: results[4] as int,
        averageMood: moodStats.averageMood,
        moodDistribution: moodStats.distribution,
        longestStreakThisMonth: streaks.longestStreakThisMonth,
      );
    } catch (e) {
      AppLog.error('StatsService.getAllStats', e);
      return const StatsSnapshot();
    }
  }

  /// Single stream that recomputes all stats when journal_entries changes.
  /// Replaces 4+ independent watch streams with one trigger.
  ///
  /// The trigger query selects an aggregate "signature" of every column that
  /// stats actually depend on (count, sum-of-mood, min/max date). Stats are
  /// independent of entry text, so editing an entry's body produces an
  /// identical signature and the cached snapshot is reused — `getAllStats`
  /// is never run for cosmetic-only writes. The 600ms debounce collapses
  /// autosave bursts during typing into a single recompute.
  Stream<StatsSnapshot> watchAllStats({int weeks = 12}) {
    String? lastSignature;
    StatsSnapshot? cached;
    return _db
        .customSelect(
          "SELECT COUNT(*) AS c, COALESCE(SUM(mood), 0) AS s, "
          "COALESCE(MAX(date), 0) AS mx, COALESCE(MIN(date), 0) AS mn, "
          "COUNT(mood) AS mc "
          "FROM journal_entries",
          readsFrom: {_db.journalEntries},
        )
        .watchSingle()
        .transform(_debounce(const Duration(milliseconds: 600)))
        .asyncMap((row) async {
          final sig =
              '${row.read<int>('c')}|${row.read<int>('s')}|'
              '${row.read<int>('mx')}|${row.read<int>('mn')}|'
              '${row.read<int>('mc')}';
          final prev = cached;
          if (sig == lastSignature && prev != null) return prev;
          lastSignature = sig;
          final snapshot = await getAllStats(weeks: weeks);
          cached = snapshot;
          return snapshot;
        })
        .distinct()
        .handleError((e) => DatabaseService.logStreamError('watchAllStats', e));
  }

  /// Debounces a stream: only emits the latest value after [duration] of silence.
  /// Uses StreamController to properly clean up timers on subscription cancel.
  static StreamTransformer<T, T> _debounce<T>(Duration duration) {
    return StreamTransformer<T, T>((stream, cancelOnError) {
      Timer? timer;
      final controller = StreamController<T>(onCancel: () => timer?.cancel());
      final sub = stream.listen(
        (data) {
          timer?.cancel();
          timer = Timer(duration, () => controller.add(data));
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
        cancelOnError: cancelOnError,
      );
      controller.onCancel = () {
        timer?.cancel();
        sub.cancel();
      };
      return controller.stream.listen(null);
    });
  }
}

/// Immutable snapshot of all stats — computed once per journal change.
class StatsSnapshot {
  final int totalEntries;
  final int totalDays;
  final int currentStreak;
  final int longestStreak;
  final int longestStreakThisMonth;
  final List<int> weeklyTrends;
  final int mostActiveWeekday;
  final double? averageMood;
  final Map<int, int> moodDistribution;

  const StatsSnapshot({
    this.totalEntries = 0,
    this.totalDays = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.longestStreakThisMonth = 0,
    this.weeklyTrends = const [],
    this.mostActiveWeekday = 0,
    this.averageMood,
    this.moodDistribution = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsSnapshot &&
          totalEntries == other.totalEntries &&
          totalDays == other.totalDays &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          longestStreakThisMonth == other.longestStreakThisMonth &&
          mostActiveWeekday == other.mostActiveWeekday &&
          averageMood == other.averageMood &&
          listEquals(weeklyTrends, other.weeklyTrends) &&
          _mapEquals(moodDistribution, other.moodDistribution);

  static bool _mapEquals(Map<int, int> a, Map<int, int> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    totalEntries,
    totalDays,
    currentStreak,
    longestStreak,
    longestStreakThisMonth,
    mostActiveWeekday,
    averageMood,
    Object.hashAll(weeklyTrends),
    Object.hashAll(moodDistribution.entries),
  );
}

/// Lightweight data subset for the home screen widget.
class WidgetData {
  final int currentStreak;
  final int totalEntries;

  const WidgetData({this.currentStreak = 0, this.totalEntries = 0});
}
