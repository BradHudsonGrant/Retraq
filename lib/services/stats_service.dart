// ignore_for_file: prefer_single_quotes

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../utils/date_helpers.dart';
import 'database_service.dart';

/// All stats/analytics queries.
class StatsService {
  final AppDatabase _db;

  StatsService(this._db);

  /// Count consecutive days with entries ending today or yesterday.
  /// Uses SQL window functions to avoid pulling all rows into Dart.
  Future<int> getCurrentStreak() async {
    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final rows = await _db.customSelect(
        // Assign each distinct date a row_number descending, then compute
        // the difference between the date and the row offset from a reference.
        // Consecutive days will share the same group value.
        "WITH dates AS ("
        "  SELECT DISTINCT date(date, 'unixepoch', 'localtime') AS d"
        "  FROM journal_entries"
        "  ORDER BY d DESC"
        "), ranked AS ("
        "  SELECT d, ROW_NUMBER() OVER (ORDER BY d DESC) AS rn"
        "  FROM dates"
        "  WHERE d <= ?"
        ")"
        "SELECT COUNT(*) AS streak FROM ranked "
        "WHERE date(d, '+' || (rn - 1) || ' days') = ("
        "  SELECT d FROM ranked WHERE rn = 1"
        ")",
        variables: [Variable<String>(todayStr)],
        readsFrom: {_db.journalEntries},
      ).get();

      final streak = rows.first.read<int>('streak');

      // If the most recent entry day isn't today or yesterday, streak is 0
      if (streak > 0) {
        final topRow = await _db.customSelect(
          "SELECT date(date, 'unixepoch', 'localtime') AS d "
          "FROM journal_entries ORDER BY d DESC LIMIT 1",
          readsFrom: {_db.journalEntries},
        ).get();
        if (topRow.isNotEmpty) {
          final topDate = topRow.first.read<String>('d');
          final yesterday = now.subtract(const Duration(days: 1));
          final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
          if (topDate != todayStr && topDate != yesterdayStr) return 0;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('StatsService.getCurrentStreak failed: $e');
      return 0;
    }
  }

  /// Find the longest ever run of consecutive days with entries.
  /// Uses SQL window functions to compute entirely in the database.
  Future<int> getLongestStreak() async {
    try {
      final rows = await _db.customSelect(
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
      ).get();

      return rows.first.read<int>('longest');
    } catch (e) {
      debugPrint('StatsService.getLongestStreak failed: $e');
      return 0;
    }
  }

  /// Return entry counts per week for the last [weeks] weeks.
  /// Returns a List<int> of length [weeks], index 0 = oldest week.
  Future<List<int>> getWeeklyEntryCounts({int weeks = 12}) async {
    try {
      final now = DateTime.now();
      final cutoff = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: weeks * 7));
      final cutoffEpoch = cutoff.toUtc().millisecondsSinceEpoch ~/ 1000;

      final rows = await _db.customSelect(
        "SELECT strftime('%Y-%W', date, 'unixepoch', 'localtime') as week, "
        "COUNT(*) as cnt FROM journal_entries "
        "WHERE date >= ? GROUP BY week ORDER BY week ASC",
        variables: [Variable.withInt(cutoffEpoch)],
        readsFrom: {_db.journalEntries},
      ).get();

      // Build a map of week-label → count
      final weekCounts = <String, int>{};
      for (final row in rows) {
        weekCounts[row.read<String>('week')] = row.read<int>('cnt');
      }

      // Generate expected week labels for each of the N weeks
      final result = <int>[];
      for (var i = weeks - 1; i >= 0; i--) {
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i * 7));
        final label = strftimeYW(weekStart);
        result.add(weekCounts[label] ?? 0);
      }
      return result;
    } catch (e) {
      debugPrint('StatsService.getWeeklyEntryCounts failed: $e');
      return List.filled(weeks, 0);
    }
  }

  /// Return the day of week (1=Mon..7=Sun) with the most entries.
  /// Returns 0 if no entries exist.
  Future<int> getMostActiveWeekday() async {
    try {
      final rows = await _db.customSelect(
        "SELECT CAST(strftime('%w', date, 'unixepoch', 'localtime') AS INTEGER) as dow, "
        "COUNT(*) as cnt FROM journal_entries GROUP BY dow ORDER BY cnt DESC LIMIT 1",
        readsFrom: {_db.journalEntries},
      ).get();

      if (rows.isEmpty) return 0;

      // strftime %w: 0=Sunday, 1=Monday, ..., 6=Saturday
      // Convert to 1=Mon..7=Sun
      final dow = rows.first.read<int>('dow');
      return dow == 0 ? 7 : dow;
    } catch (e) {
      debugPrint('StatsService.getMostActiveWeekday failed: $e');
      return 0;
    }
  }

  /// Internal helper — total distinct days with entries (non-stream).
  /// Uses SQL date extraction to count distinct calendar dates, ignoring
  /// time-of-day differences in the stored unix epoch timestamps.
  Future<int> getTotalDaysWithEntries() async {
    try {
      final result = await _db.customSelect(
        "SELECT COUNT(DISTINCT date(date, 'unixepoch', 'localtime')) as cnt FROM journal_entries",
        readsFrom: {_db.journalEntries},
      ).getSingle();
      return result.read<int>('cnt');
    } catch (e) {
      debugPrint('StatsService.getTotalDaysWithEntries failed: $e');
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
      debugPrint('StatsService._getTotalEntryCount failed: $e');
      return 0;
    }
  }

  /// Average mood across all entries with mood set (1.0-5.0), or null.
  Future<double?> getAverageMood() async {
    try {
      final rows = await _db.customSelect(
        "SELECT AVG(CAST(mood AS REAL)) as avg_mood FROM journal_entries WHERE mood IS NOT NULL",
        readsFrom: {_db.journalEntries},
      ).get();
      final val = rows.first.readNullable<double>('avg_mood');
      return val;
    } catch (e) {
      debugPrint('StatsService.getAverageMood failed: $e');
      return null;
    }
  }

  /// Distribution of mood values (count per mood level 1-5).
  /// Returns a Map<int, int> where key=mood (1-5), value=count.
  Future<Map<int, int>> getMoodDistribution() async {
    try {
      final rows = await _db.customSelect(
        "SELECT mood, COUNT(*) as cnt FROM journal_entries WHERE mood IS NOT NULL GROUP BY mood ORDER BY mood",
        readsFrom: {_db.journalEntries},
      ).get();
      final result = <int, int>{};
      for (final row in rows) {
        result[row.read<int>('mood')] = row.read<int>('cnt');
      }
      return result;
    } catch (e) {
      debugPrint('StatsService.getMoodDistribution failed: $e');
      return {};
    }
  }

  /// Combined stats snapshot — computes all stats in a single trigger instead
  /// of N independent full-table scans. Use [watchAllStats] for the stream.
  Future<StatsSnapshot> getAllStats({int weeks = 12}) async {
    try {
      // One trigger, all queries batched in parallel
      final results = await Future.wait([
        _getTotalEntryCount(),
        getTotalDaysWithEntries(),
        getCurrentStreak(),
        getLongestStreak(),
        getWeeklyEntryCounts(weeks: weeks),
        getMostActiveWeekday(),
        getAverageMood(),
        getMoodDistribution(),
      ]);
      return StatsSnapshot(
        totalEntries: results[0] as int,
        totalDays: results[1] as int,
        currentStreak: results[2] as int,
        longestStreak: results[3] as int,
        weeklyTrends: results[4] as List<int>,
        mostActiveWeekday: results[5] as int,
        averageMood: results[6] as double?,
        moodDistribution: results[7] as Map<int, int>,
      );
    } catch (e) {
      debugPrint('StatsService.getAllStats failed: $e');
      return const StatsSnapshot();
    }
  }

  /// Single stream that recomputes all stats when journal_entries changes.
  /// Replaces 4+ independent watch streams with one trigger.
  Stream<StatsSnapshot> watchAllStats({int weeks = 12}) {
    return _db.select(_db.journalEntries).watch()
        .transform(_debounce(const Duration(milliseconds: 300)))
        .asyncMap((_) => getAllStats(weeks: weeks))
        .distinct()
        .handleError((e) => DatabaseService.logStreamError('watchAllStats', e));
  }

  /// Debounces a stream: only emits the latest value after [duration] of silence.
  /// Uses StreamController to properly clean up timers on subscription cancel.
  static StreamTransformer<T, T> _debounce<T>(Duration duration) {
    return StreamTransformer<T, T>((stream, cancelOnError) {
      Timer? timer;
      final controller = StreamController<T>(
        onCancel: () => timer?.cancel(),
      );
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
  final List<int> weeklyTrends;
  final int mostActiveWeekday;
  final double? averageMood;
  final Map<int, int> moodDistribution;

  const StatsSnapshot({
    this.totalEntries = 0,
    this.totalDays = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
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
        mostActiveWeekday,
        averageMood,
        Object.hashAll(weeklyTrends),
        Object.hashAll(moodDistribution.entries),
      );
}
