// ignore_for_file: prefer_single_quotes

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show listEquals, mapEquals, setEquals;
import '../models/journal_entry.dart';
import '../utils/date_helpers.dart';
import 'app_log.dart';
import 'database_service.dart';

/// All journal entry CRUD operations.
class EntryRepository {
  final AppDatabase _db;

  EntryRepository(this._db);

  /// Convert a Drift row to our JournalEntry model.
  /// Normalises dates to local time — Drift stores as UTC epoch seconds,
  /// and we must ensure the day is correct in the user's timezone.
  JournalEntry rowToEntry(JournalEntryRow row) {
    final localDate = row.date.toLocal();
    final localCreated = row.createdAt.toLocal();
    return JournalEntry(
      id: row.id,
      date: DateTime(localDate.year, localDate.month, localDate.day),
      entry: row.entry,
      label: row.label,
      title: row.title,
      mood: row.mood,
      createdAt: localCreated,
      userId: row.userId,
    );
  }

  /// Save or update a journal entry. Returns the row ID.
  Future<int> saveEntry(JournalEntry entry) async {
    // Normalize date to midnight to prevent same-day entries appearing as different dates
    final normalizedDate = DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
    );
    try {
      if (entry.id != null) {
        // Update existing
        await (_db.update(_db.journalEntries)
          ..where((t) => t.id.equals(entry.id!))).write(
          JournalEntriesCompanion(
            date: Value(normalizedDate),
            entry: Value(entry.entry),
            label: Value(entry.label),
            title: Value(entry.title),
            mood: Value(entry.mood),
            createdAt: Value(entry.createdAt),
            userId: Value(entry.userId),
          ),
        );
        return entry.id!;
      } else {
        // Insert new
        return await _db
            .into(_db.journalEntries)
            .insert(
              JournalEntriesCompanion.insert(
                date: normalizedDate,
                entry: Value(entry.entry),
                label: Value(entry.label),
                title: Value(entry.title),
                mood: Value(entry.mood),
                createdAt: entry.createdAt,
                userId: Value(entry.userId),
              ),
            );
      }
    } catch (e) {
      AppLog.error('EntryRepository.saveEntry', e);
      rethrow;
    }
  }

  /// Get entries for a specific date (matches by year/month/day).
  Future<List<JournalEntry>> getEntriesForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final rows =
          await (_db.select(_db.journalEntries)
                ..where((t) => t.date.isBiggerOrEqualValue(startOfDay))
                ..where((t) => t.date.isSmallerThanValue(endOfDay))
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
              .get();
      return rows.map(rowToEntry).toList();
    } catch (e) {
      AppLog.error('EntryRepository.getEntriesForDate', e);
      return [];
    }
  }

  /// Watch all entries for a specific date, oldest first.
  Stream<List<JournalEntry>> watchEntriesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (_db.select(_db.journalEntries)
          ..where((t) => t.date.isBiggerOrEqualValue(startOfDay))
          ..where((t) => t.date.isSmallerThanValue(endOfDay))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(rowToEntry).toList())
        .distinct(listEquals)
        .handleError(
          (e) => DatabaseService.logStreamError('watchEntriesForDate', e),
        );
  }

  /// Get all entries, newest first. Used for full exports.
  Future<List<JournalEntry>> getAllEntries() async {
    try {
      final rows =
          await (_db.select(_db.journalEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
      return rows.map(rowToEntry).toList();
    } catch (e) {
      AppLog.error('EntryRepository.getAllEntries', e);
      return [];
    }
  }

  /// Batch-insert multiple journal entries in a single transaction.
  Future<void> batchSaveEntries(List<JournalEntry> entries) async {
    await _db.batch((batch) {
      for (final entry in entries) {
        // Normalize date to midnight to prevent same-day entries appearing as different dates
        final normalizedDate = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        batch.insert(
          _db.journalEntries,
          JournalEntriesCompanion.insert(
            date: normalizedDate,
            entry: Value(entry.entry),
            label: Value(entry.label),
            title: Value(entry.title),
            mood: Value(entry.mood),
            createdAt: entry.createdAt,
            userId: Value(entry.userId),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Get recent entries, newest first.
  Future<List<JournalEntry>> getRecentEntries({int limit = 5}) async {
    try {
      final rows =
          await (_db.select(_db.journalEntries)
                ..orderBy([(t) => OrderingTerm.desc(t.date)])
                ..limit(limit))
              .get();
      return rows.map(rowToEntry).toList();
    } catch (e) {
      AppLog.error('EntryRepository.getRecentEntries', e);
      return [];
    }
  }

  /// Get entries in a date range (inclusive), newest first.
  Future<List<JournalEntry>> getEntriesForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    // Normalize to midnight so the range covers full days
    final startOfRange = DateTime(start.year, start.month, start.day);
    // Use start of the day after end date with < comparison to include all entries on the end date
    final endExclusive = DateTime(
      end.year,
      end.month,
      end.day,
    ).add(const Duration(days: 1));
    final rows =
        await (_db.select(_db.journalEntries)
              ..where(
                (t) =>
                    t.date.isBiggerOrEqualValue(startOfRange) &
                    t.date.isSmallerThanValue(endExclusive),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();
    return rows.map(rowToEntry).toList();
  }

  /// Watch recent entries, newest first.
  Stream<List<JournalEntry>> watchRecentEntries({int limit = 5}) {
    return (_db.select(_db.journalEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map(rowToEntry).toList())
        .distinct(listEquals)
        .handleError(
          (e) => DatabaseService.logStreamError('watchRecentEntries', e),
        );
  }

  /// Watch entries from the current week, newest first.
  Stream<List<JournalEntry>> watchWeekEntries({int weekStartDay = 1}) {
    final startOfWeek = weekStartDate(weekStartDay: weekStartDay);

    return (_db.select(_db.journalEntries)
          ..where((t) => t.date.isBiggerOrEqualValue(startOfWeek))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(rowToEntry).toList())
        .distinct(listEquals)
        .handleError(
          (e) => DatabaseService.logStreamError('watchWeekEntries', e),
        );
  }

  /// Watch entries for a specific week starting at [weekStart], newest first.
  Stream<List<JournalEntry>> watchWeekEntriesFrom(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7));

    return (_db.select(_db.journalEntries)
          ..where((t) => t.date.isBiggerOrEqualValue(weekStart))
          ..where((t) => t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(rowToEntry).toList())
        .distinct(listEquals)
        .handleError(
          (e) => DatabaseService.logStreamError('watchWeekEntriesFrom', e),
        );
  }

  /// Count of entries this week, respecting the user's weekStartDay setting.
  Future<int> getWeekEntryCount({required int weekStartDay}) async {
    try {
      final startOfWeek = weekStartDate(weekStartDay: weekStartDay);

      final count = _db.journalEntries.id.count();
      final query =
          _db.selectOnly(_db.journalEntries)
            ..addColumns([count])
            ..where(_db.journalEntries.date.isBiggerOrEqualValue(startOfWeek));
      final row = await query.getSingle();
      return row.read(count) ?? 0;
    } catch (e) {
      AppLog.error('EntryRepository.getWeekEntryCount', e);
      return 0;
    }
  }

  /// Watch count of entries this week.
  Stream<int> watchWeekEntryCount({required int weekStartDay}) {
    final startOfWeek = weekStartDate(weekStartDay: weekStartDay);

    final count = _db.journalEntries.id.count();
    final query =
        _db.selectOnly(_db.journalEntries)
          ..addColumns([count])
          ..where(_db.journalEntries.date.isBiggerOrEqualValue(startOfWeek));

    return query
        .watchSingle()
        .map((row) => row.read(count) ?? 0)
        .distinct()
        .handleError(
          (e) => DatabaseService.logStreamError('watchWeekEntryCount', e),
        );
  }

  /// Total entry count.
  Future<int> getTotalEntryCount() async {
    try {
      final count = _db.journalEntries.id.count();
      final query = _db.selectOnly(_db.journalEntries)..addColumns([count]);
      final row = await query.getSingle();
      return row.read(count) ?? 0;
    } catch (e) {
      AppLog.error('EntryRepository.getTotalEntryCount', e);
      return 0;
    }
  }

  /// Watch total entry count.
  Stream<int> watchTotalEntryCount() {
    final count = _db.journalEntries.id.count();
    final query = _db.selectOnly(_db.journalEntries)..addColumns([count]);
    return query
        .watchSingle()
        .map((row) => row.read(count) ?? 0)
        .distinct()
        .handleError(
          (e) => DatabaseService.logStreamError('watchTotalEntryCount', e),
        );
  }

  /// Watch count of distinct days that have entries.
  /// Uses SQL date extraction to count distinct calendar dates, ignoring
  /// time-of-day differences in the stored unix epoch timestamps.
  Stream<int> watchTotalDaysWithEntries() {
    return _db
        .customSelect(
          "SELECT COUNT(DISTINCT date(date, 'unixepoch', 'localtime')) as cnt FROM journal_entries",
          readsFrom: {_db.journalEntries},
        )
        .watchSingle()
        .map((row) => row.read<int>('cnt'))
        .distinct()
        .handleError(
          (e) => DatabaseService.logStreamError('watchTotalDaysWithEntries', e),
        );
  }

  /// All entries in a given month (for calendar dot indicators).
  Future<List<JournalEntry>> getMonthEntries(DateTime month) async {
    try {
      final start = DateTime(month.year, month.month);
      final end = startOfNextMonth(month);

      final rows =
          await (_db.select(_db.journalEntries)
                ..where((t) => t.date.isBiggerOrEqualValue(start))
                ..where((t) => t.date.isSmallerThanValue(end))
                ..orderBy([(t) => OrderingTerm.asc(t.date)]))
              .get();
      return rows.map(rowToEntry).toList();
    } catch (e) {
      AppLog.error('EntryRepository.getMonthEntries', e);
      return [];
    }
  }

  /// Watch all entries in a given month.
  Stream<List<JournalEntry>> watchMonthEntries(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = startOfNextMonth(month);

    return (_db.select(_db.journalEntries)
          ..where((t) => t.date.isBiggerOrEqualValue(start))
          ..where((t) => t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch()
        .map((rows) => rows.map(rowToEntry).toList())
        .distinct(listEquals)
        .handleError(
          (e) => DatabaseService.logStreamError('watchMonthEntries', e),
        );
  }

  /// Stream of days with entries for a given month (just the day numbers).
  /// More efficient than [watchMonthEntries] when only dot indicators are needed
  /// (e.g. CalendarGrid), since it returns only distinct day numbers instead of
  /// full entry objects.
  Stream<Set<int>> watchMonthEntryDays(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = startOfNextMonth(month);
    final startEpoch = start.toUtc().millisecondsSinceEpoch ~/ 1000;
    final endEpoch = end.toUtc().millisecondsSinceEpoch ~/ 1000;

    return _db
        .customSelect(
          "SELECT DISTINCT CAST(strftime('%d', date, 'unixepoch', 'localtime') AS INTEGER) as d "
          "FROM journal_entries WHERE date >= ? AND date < ?",
          variables: [Variable.withInt(startEpoch), Variable.withInt(endEpoch)],
          readsFrom: {_db.journalEntries},
        )
        .watch()
        .map((rows) => rows.map((r) => r.read<int>('d')).toSet())
        .distinct(setEquals);
  }

  /// Stream mapping day number → mood value for a given month.
  /// When a day has multiple entries with moods, the latest mood wins.
  /// Days without mood are omitted from the map.
  Stream<Map<int, int>> watchMonthEntryMoods(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = startOfNextMonth(month);
    final startEpoch = start.toUtc().millisecondsSinceEpoch ~/ 1000;
    final endEpoch = end.toUtc().millisecondsSinceEpoch ~/ 1000;

    return _db
        .customSelect(
          "SELECT CAST(strftime('%d', date, 'unixepoch', 'localtime') AS INTEGER) as d, "
          "mood FROM journal_entries "
          "WHERE date >= ? AND date < ? AND mood IS NOT NULL "
          "ORDER BY created_at ASC",
          variables: [Variable.withInt(startEpoch), Variable.withInt(endEpoch)],
          readsFrom: {_db.journalEntries},
        )
        .watch()
        .map((rows) {
          final map = <int, int>{};
          for (final row in rows) {
            map[row.read<int>('d')] = row.read<int>('mood');
          }
          return map;
        })
        .distinct(mapEquals);
  }

  /// Delete a journal entry by ID.
  Future<void> deleteEntry(int id) async {
    try {
      await (_db.delete(_db.journalEntries)
        ..where((t) => t.id.equals(id))).go();
    } catch (e) {
      AppLog.error('EntryRepository.deleteEntry', e);
      rethrow;
    }
  }

  /// Search entries by text content using the FTS5 index (prefix matching).
  /// The unicode61 tokenizer makes results case- and diacritic-insensitive.
  Future<List<JournalEntry>> searchEntries(
    String query, {
    int limit = 50,
  }) async {
    final ftsQuery = _toFtsQuery(query);
    if (ftsQuery == null) return [];
    final rows =
        await _db
            .customSelect(
              "SELECT je.* FROM journal_entries je "
              "JOIN journal_entries_fts ON journal_entries_fts.rowid = je.id "
              "WHERE journal_entries_fts MATCH ? "
              "ORDER BY je.date DESC LIMIT ?",
              variables: [
                Variable.withString(ftsQuery),
                Variable.withInt(limit),
              ],
              readsFrom: {_db.journalEntries},
            )
            .get();
    // Task 1.8 — delegate to the shared factory so FTS search stays
    // in sync with `rowToEntry`. Previously this inline mapper was
    // missing `userId`, a silent divergence the factory now prevents.
    return rows.map(JournalEntry.fromRawRow).toList();
  }

  /// Convert a free-form user query into an FTS5 MATCH expression.
  /// Splits on non-word characters (Unicode-aware), quotes each token to
  /// defang FTS5 operator keywords (AND/OR/NOT/NEAR), and appends `*` for
  /// trailing prefix matching. Returns null if no usable tokens remain.
  String? _toFtsQuery(String input) {
    final tokens =
        input
            .split(RegExp(r'[^\p{L}\p{N}_]+', unicode: true))
            .where((t) => t.isNotEmpty)
            .toList();
    if (tokens.isEmpty) return null;
    return tokens.map((t) => '"$t"*').join(' ');
  }
}
