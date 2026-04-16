// ignore_for_file: prefer_single_quotes

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';
import 'secure_storage.dart';

/// Current document versions — bump when legal text changes.
// Bumped 2026-04-16 for Task 12.2 — added controller disclosure
// improvements + supervisory-authority complaint routes (OPC Canada,
// CAI Quebec, CNIL/EDPB, ICO UK, CPPA California, OAIC Australia).
const String currentPrivacyPolicyVersion = '2026-04-16';
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
      debugPrint('UserRepository.saveUser failed: $e');
      rethrow;
    }
  }

  /// Get the first user (for single-user mode).
  Future<User?> getUser() async {
    try {
      final row = await (_db.select(_db.users)..limit(1)).getSingleOrNull();
      if (row == null) return null;
      return User(
        id: row.id,
        displayName: row.displayName,
        email: row.email,
        subscriptionTier: row.subscriptionTier,
        createdAt: row.createdAt.toLocal(),
      );
    } catch (e) {
      debugPrint('UserRepository.getUser failed: $e');
      return null;
    }
  }

  /// Watch the first user for reactive updates.
  Stream<User?> watchUser() {
    return (_db.select(_db.users)..limit(1))
        .watchSingleOrNull()
        .map((row) {
          if (row == null) return null;
          return User(
            id: row.id,
            displayName: row.displayName,
            email: row.email,
            subscriptionTier: row.subscriptionTier,
            createdAt: row.createdAt.toLocal(),
          );
        })
        .handleError((e) => DatabaseService.logStreamError('watchUser', e));
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
        // Re-insert default settings row.
        await _db
            .into(_db.userSettingsTable)
            .insert(UserSettingsTableCompanion.insert());
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
      } catch (_) {
        // SharedPreferences may not be available in test environments.
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
      } catch (_) {
        // SecureStorage may not be available in test environments.
      }
      // Clear home widget data
      try {
        await HomeWidget.saveWidgetData<int>('streak', 0);
        await HomeWidget.saveWidgetData<int>('totalEntries', 0);
        await HomeWidget.saveWidgetData<String>('lastEntryDate', '');
        await HomeWidget.saveWidgetData<int>('mood', 0);
        await HomeWidget.updateWidget(name: 'JournalWidget');
      } catch (_) {
        // HomeWidget may not be available in test environments.
      }
      // Force-restart the app so the UI reflects the clean state.
      // Skip when running in Flutter test harness.
      if (Platform.environment.containsKey('FLUTTER_TEST') == false) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        } else {
          exit(0);
        }
      }
    } catch (e) {
      debugPrint('UserRepository.deleteAllData failed: $e');
      rethrow;
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
      debugPrint('UserRepository.saveConsentRecord failed: $e');
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
      debugPrint('UserRepository.needsReconsent failed: $e');
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
      debugPrint('UserRepository.getConsentRecords failed: $e');
      return [];
    }
  }
}
