// ignore_for_file: prefer_single_quotes

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/stream_extensions.dart';
import 'app_log.dart';
import 'database_service.dart';
import 'secure_storage.dart';

/// Current document versions — bump when legal text changes.
// Bumped 2026-04-18 for Task 10.1 — added the "Optional Diagnostics
// (Crash Reporting)" section disclosing the new Sentry opt-in, plus
// amended Data Collection + Third-Party Services to note Sentry as
// the sole potential third party (off by default). Existing users
// walk through the reconsent flow on next launch.
// Prior bump 2026-04-16 for Task 12.2 — controller disclosure +
// supervisory-authority complaint routes (OPC Canada, CAI Quebec,
// CNIL/EDPB, ICO UK, CPPA California, OAIC Australia).
const String currentPrivacyPolicyVersion = '2026-04-18';
// Bumped 2026-04-16 for Task 12.6 — added mandatory consumer-law
// carve-out to the Governing Law section. Existing users will be
// walked through the re-consent flow on next launch.
const String currentTermsOfServiceVersion = '2026-04-16';
const String currentHealthDisclaimerVersion = '2026-03-29';

/// User CRUD, consent records, and data deletion.
class UserRepository {
  final AppDatabase _db;

  UserRepository(this._db);

  /// Save or update a user. Returns the row ID.
  Future<int> saveUser(User user) async {
    try {
      if (user.id != null) {
        await (_db.update(_db.users)
          ..where((t) => t.id.equals(user.id!))).write(
          UsersCompanion(
            displayName: Value(user.displayName),
            email: Value(user.email),
            subscriptionTier: Value(user.subscriptionTier),
          ),
        );
        return user.id!;
      } else {
        return await _db
            .into(_db.users)
            .insert(
              UsersCompanion.insert(
                displayName: Value(user.displayName),
                email: Value(user.email),
                subscriptionTier: Value(user.subscriptionTier),
                createdAt: user.createdAt,
              ),
            );
      }
    } catch (e) {
      AppLog.error('UserRepository.saveUser', e);
      rethrow;
    }
  }

  /// Convert a Drift row to our User model. Centralised so both
  /// [getUser] and [watchUser] enumerate the same five fields in one
  /// place instead of rebuilding the constructor twice.
  User _rowToUser(UserRow row) => User(
        id: row.id,
        displayName: row.displayName,
        email: row.email,
        subscriptionTier: row.subscriptionTier,
        createdAt: row.createdAt.toLocal(),
      );

  /// Get the first user (for single-user mode).
  Future<User?> getUser() async {
    try {
      final row = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
      return row == null ? null : _rowToUser(row);
    } catch (e) {
      AppLog.error('UserRepository.getUser', e);
      return null;
    }
  }

  /// Watch the first user for reactive updates.
  Stream<User?> watchUser() {
    return (_db.select(_db.users)..limit(1))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _rowToUser(row))
        .logStreamErrors('watchUser');
  }

  /// Delete all journal entries, settings, users, consent records,
  /// and clear related SharedPreferences keys. Re-insert default settings.
  Future<void> deleteAllData() async {
    try {
      await _db.transaction(() async {
        await _db.delete(_db.journalEntries).go();
        await _db.delete(_db.userSettingsTable).go();
        await _db.delete(_db.users).go();
        await _db.delete(_db.consentRecords).go();
        // Re-insert default settings row, pinned at id=1 so
        // SettingsRepository.watchSettings (which filters by id=1) stays
        // in sync. Without the explicit id, autoincrement would hand the
        // replacement row id=2+ and the watcher would never re-emit.
        await _db
            .into(_db.userSettingsTable)
            .insert(UserSettingsTableCompanion.insert(id: const Value(1)));
      });
      // Clear SharedPreferences keys related to age verification and reviews.
      // Lockout keys live in hardenedSecureStorage (LockoutController) — do
      // not clear them from prefs here; that block is below.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('age_verified');
        await prefs.remove('age_denied');
        await prefs.remove('review_prompt_shown');
        await prefs.remove('pin_length');
      } catch (e, st) {
        // Task 1.4 — SharedPreferences is unavailable in test envs
        // and can also fail on hostile storage; log via AppLog so the
        // failure is captured (and surfaces in release with
        // RETRAQ_LOG=true) without escalating to the caller.
        AppLog.warn('UserRepository.deleteAllData.prefs', e, st);
      }
      // Clear secure storage lockout state and PIN length.
      // IMPORTANT: Do NOT use deleteAll() — it would destroy the DB
      // encryption key (retraq_db_key), making the database unopenable.
      try {
        await hardenedSecureStorage.delete(key: 'pin_length');
        await hardenedSecureStorage.delete(key: 'lock_failed_attempts');
        await hardenedSecureStorage.delete(key: 'lock_lockout_count');
        await hardenedSecureStorage.delete(key: 'lock_lockout_start');
        await hardenedSecureStorage.delete(key: 'lock_lockout_end');
      } catch (e, st) {
        // Task 1.4 — secure storage may be unavailable in tests.
        AppLog.warn('UserRepository.deleteAllData.secureStorage', e, st);
      }
      // Clear home widget data
      try {
        await HomeWidget.saveWidgetData<int>('streak', 0);
        await HomeWidget.saveWidgetData<int>('totalEntries', 0);
        await HomeWidget.saveWidgetData<String>('lastEntryDate', '');
        await HomeWidget.saveWidgetData<int>('mood', 0);
        await HomeWidget.updateWidget(name: 'JournalWidget');
      } catch (e, st) {
        // Task 1.4 — home widget is Android-only and may not be
        // available in tests or on iOS; log and continue.
        AppLog.warn('UserRepository.deleteAllData.homeWidget', e, st);
      }
      // Previously we forced `SystemNavigator.pop()` / `exit(0)` from
      // inside this method after a 500ms delay. That was graceless —
      // the app just blinked out of existence before any success
      // toast the caller queued up could even paint, and it didn't
      // give the user a chance to read what had happened. Callers are
      // now responsible for showing a confirmation UI and calling
      // [requestAppExit] when the user is ready. That lets settings
      // and the lock-screen forgot-PIN flow run identical post-delete
      // copy instead of one silently slamming shut.
    } catch (e) {
      AppLog.error('UserRepository.deleteAllData', e);
      rethrow;
    }
  }

  /// Close the app cleanly. Use after [deleteAllData] once the user has
  /// acknowledged the post-delete confirmation dialog, so next launch
  /// re-derives db state from scratch instead of trying to keep the
  /// current in-memory tree (with wiped Drift watchers) alive.
  ///
  /// Android: Navigator.pop delivers the user back to the launcher.
  /// iOS: exit(0); iOS doesn't have a blessed "finish app" API, so
  /// this is the pragmatic compromise the Apple reviewer tends to
  /// accept for explicit user-initiated data resets.
  static Future<void> requestAppExit() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (Platform.isAndroid) {
      await SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  /// Save a consent record (e.g., privacy policy acceptance).
  Future<int> saveConsentRecord({
    required String consentType,
    required String documentVersion,
    required DateTime acceptedAt,
    String? appVersion,
  }) async {
    try {
      return await _db
          .into(_db.consentRecords)
          .insert(
            ConsentRecordsCompanion.insert(
              consentType: consentType,
              documentVersion: documentVersion,
              acceptedAt: acceptedAt,
              appVersion: Value(appVersion),
            ),
          );
    } catch (e) {
      AppLog.error('UserRepository.saveConsentRecord', e);
      rethrow;
    }
  }

  /// Check whether the user needs to re-consent to updated legal documents.
  /// Returns true if any required consent is missing or outdated.
  Future<bool> needsReconsent() async {
    try {
      final records = await getConsentRecords();
      bool hasCurrentPrivacy = false;
      bool hasCurrentTerms = false;
      bool hasCurrentHealthDisclaimer = false;
      for (final r in records) {
        if (r.consentType == 'privacy_policy' &&
            r.documentVersion == currentPrivacyPolicyVersion) {
          hasCurrentPrivacy = true;
        }
        if (r.consentType == 'terms_of_service' &&
            r.documentVersion == currentTermsOfServiceVersion) {
          hasCurrentTerms = true;
        }
        if (r.consentType == 'health_disclaimer' &&
            r.documentVersion == currentHealthDisclaimerVersion) {
          hasCurrentHealthDisclaimer = true;
        }
      }
      return !hasCurrentPrivacy ||
          !hasCurrentTerms ||
          !hasCurrentHealthDisclaimer;
    } catch (e) {
      AppLog.error('UserRepository.needsReconsent', e);
      return true; // Fail safe: require re-consent if we can't check
    }
  }

  /// Get all consent records, newest first.
  Future<List<ConsentRecordRow>> getConsentRecords() async {
    try {
      final rows =
          await (_db.select(_db.consentRecords)
            ..orderBy([(t) => OrderingTerm.desc(t.acceptedAt)])).get();
      return rows;
    } catch (e) {
      AppLog.error('UserRepository.getConsentRecords', e);
      return [];
    }
  }
}
