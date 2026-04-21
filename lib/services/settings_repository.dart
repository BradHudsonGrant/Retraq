// ignore_for_file: prefer_single_quotes

import 'package:drift/drift.dart';
import '../models/user_settings.dart';
import '../utils/stream_extensions.dart';
import 'app_log.dart';
import 'database_service.dart';

/// Settings CRUD operations (singleton row pattern).
class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  /// Convert a Drift row to our UserSettings model.
  UserSettings _rowToSettings(UserSettingsTableData row) {
    return UserSettings(
      themeMode: row.themeMode,
      isAllDayMode: row.isAllDayMode,
      askAboutToday: row.askAboutToday,
      showEntryTitle: row.showEntryTitle,
      weekStartDay: row.weekStartDay,
      nudgeHour: row.nudgeHour,
      nudgeMinute: row.nudgeMinute,
      appLockEnabled: row.appLockEnabled,
      pinHash: row.pinHash,
      biometricEnabled: row.biometricEnabled,
      onboardingComplete: row.onboardingComplete,
      enterToSave: row.enterToSave,
      bulletPointsOnEnter: row.bulletPointsOnEnter,
      amPmCutoffHour: row.amPmCutoffHour,
      moodEnabled: row.moodEnabled,
      bionicReadingEnabled: row.bionicReadingEnabled,
    );
  }

  /// Load the singleton settings row, or create defaults if first launch.
  ///
  /// The table is a singleton pinned at `id == 1`. Any orphan rows at
  /// id > 1 (which can appear if `deleteAllData` cleared the table and
  /// let autoincrement hand the replacement row a new id) get merged
  /// into id=1 so that [watchSettings] — which filters by id=1 — stays
  /// in sync with [saveSettings] writes.
  Future<UserSettings> getSettings() async {
    try {
      return await _db.transaction(() async {
        final canonical =
            await (_db.select(_db.userSettingsTable)
              ..where((t) => t.id.equals(1))).getSingleOrNull();
        if (canonical != null) {
          // Sweep any stale rows left over from an earlier autoincrement
          // bug so the watcher keeps seeing a clean single-row stream.
          await (_db.delete(_db.userSettingsTable)
            ..where((t) => t.id.isNotValue(1))).go();
          return _rowToSettings(canonical);
        }

        // id=1 is empty — either first launch or a post-delete reset that
        // landed the new row at id>1. Promote the first orphan row if one
        // exists (preserves the user's settings) or insert defaults.
        final orphan =
            await (_db.select(_db.userSettingsTable)
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(1)).getSingleOrNull();
        await (_db.delete(_db.userSettingsTable)).go();
        final companion =
            orphan != null
                ? _settingsToCompanion(
                  _rowToSettings(orphan),
                  id: const Value(1),
                )
                : UserSettingsTableCompanion.insert(id: const Value(1));
        await _db.into(_db.userSettingsTable).insert(companion);
        return orphan != null ? _rowToSettings(orphan) : const UserSettings();
      });
    } catch (e) {
      AppLog.error('SettingsRepository.getSettings', e);
      return const UserSettings();
    }
  }

  /// Single source of truth for UserSettings → Drift companion mapping.
  /// Used by both the orphan-promotion path in [getSettings] and by
  /// [saveSettings] so the field list is only enumerated once.
  UserSettingsTableCompanion _settingsToCompanion(
    UserSettings s, {
    Value<int>? id,
  }) {
    return UserSettingsTableCompanion(
      id: id ?? const Value.absent(),
      themeMode: Value(s.themeMode),
      isAllDayMode: Value(s.isAllDayMode),
      askAboutToday: Value(s.askAboutToday),
      showEntryTitle: Value(s.showEntryTitle),
      weekStartDay: Value(s.weekStartDay),
      nudgeHour: Value(s.nudgeHour),
      nudgeMinute: Value(s.nudgeMinute),
      appLockEnabled: Value(s.appLockEnabled),
      pinHash: Value(s.pinHash),
      biometricEnabled: Value(s.biometricEnabled),
      onboardingComplete: Value(s.onboardingComplete),
      enterToSave: Value(s.enterToSave),
      bulletPointsOnEnter: Value(s.bulletPointsOnEnter),
      amPmCutoffHour: Value(s.amPmCutoffHour),
      moodEnabled: Value(s.moodEnabled),
      bionicReadingEnabled: Value(s.bionicReadingEnabled),
    );
  }

  /// Persist updated settings. Upserts at the canonical id=1 row so the
  /// watcher (which filters by id=1) always sees the write. Wrapped in
  /// a transaction to avoid races.
  Future<void> saveSettings(UserSettings s) async {
    try {
      await _db.transaction(() async {
        final companion = _settingsToCompanion(s, id: const Value(1));

        // Defensive cleanup: drop any orphans that earlier autoincrement
        // inserts may have left behind, then upsert the canonical row.
        await (_db.delete(_db.userSettingsTable)
          ..where((t) => t.id.isNotValue(1))).go();
        await _db.into(_db.userSettingsTable).insertOnConflictUpdate(companion);
      });
      // Drift's watch auto-emits on writes — no manual notification needed.
    } catch (e) {
      AppLog.error('SettingsRepository.saveSettings', e);
      rethrow;
    }
  }

  /// Watch settings for real-time reactive changes.
  /// Drift's watch is internally optimized — it only re-queries on table
  /// writes, so multiple subscriptions share the same query cost.
  Stream<UserSettings?> watchSettings() {
    return (_db.select(_db.userSettingsTable)..where((t) => t.id.equals(1)))
        .watchSingleOrNull()
        .map((row) => row != null ? _rowToSettings(row) : null)
        .logStreamErrors('watchSettings');
  }
}
