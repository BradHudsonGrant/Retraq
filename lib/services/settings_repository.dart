// ignore_for_file: prefer_single_quotes

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../models/user_settings.dart';
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
      moodRequired: row.moodRequired,
      moodOnlyEntries: row.moodOnlyEntries,
    );
  }

  /// Load the singleton settings row, or create defaults if first launch.
  Future<UserSettings> getSettings() async {
    try {
      final row = await (_db.select(_db.userSettingsTable)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();
      if (row != null) return _rowToSettings(row);

      // First launch — insert defaults
      final defaults = UserSettings();
      await _db.into(_db.userSettingsTable).insert(
            UserSettingsTableCompanion.insert(),
          );
      return defaults;
    } catch (e) {
      debugPrint('SettingsRepository.getSettings failed: $e');
      return UserSettings();
    }
  }

  /// Persist updated settings. Wrapped in a transaction to avoid races.
  Future<void> saveSettings(UserSettings s) async {
    try {
      await _db.transaction(() async {
        final existing = await (_db.select(_db.userSettingsTable)..limit(1))
            .getSingleOrNull();

        final companion = UserSettingsTableCompanion(
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
          moodRequired: Value(s.moodRequired),
          moodOnlyEntries: Value(s.moodOnlyEntries),
        );

        if (existing != null) {
          await (_db.update(_db.userSettingsTable)
                ..where((t) => t.id.equals(existing.id)))
              .write(companion);
        } else {
          await _db.into(_db.userSettingsTable).insert(companion);
        }
      });
      // Drift's watch auto-emits on writes — no manual notification needed.
    } catch (e) {
      debugPrint('SettingsRepository.saveSettings failed: $e');
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
        .handleError((e) => DatabaseService.logStreamError('watchSettings', e));
  }
}
