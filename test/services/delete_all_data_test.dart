// ignore_for_file: prefer_single_quotes

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/models/user.dart';
import 'package:retraq/services/database_service.dart';

import '../test_helpers.dart';

/// Task 12.9 — Regression test proving `deleteAllData` is total and
/// irrecoverable via ordinary DB read paths.
///
/// Retraq's privacy policy promises the "Delete All Data" option
/// irrevocably wipes every journal entry, consent record, user, and
/// setting. This test pins the contract: seed representative data
/// across all 4 tables + consent records, call deleteAllData, and
/// assert every table reads back empty (except the single
/// re-initialized default settings row that the method intentionally
/// creates so the app can start cleanly).
///
/// Scope caveats:
/// - Raw-file recoverability (forensic SQLCipher recovery from disk,
///   Android backup scoops via `adb backup`) is covered by the
///   allowBackup=false + data_extraction_rules at the OS layer and
///   the SQLCipher key management. Those are OS invariants, not
///   unit-testable here. We verify the in-DB delete surface.
/// - Widget data reset via HomeWidget is not asserted here (widget
///   service has its own tests + mock channel). The lock-state
///   secure-storage cleanup is exercised via LockoutController
///   tests.
void main() {
  late DatabaseService db;

  setUp(() async {
    db = DatabaseService.instance;
    await initTestDatabase();
  });

  tearDown(() async {
    await db.dispose();
  });

  test('deleteAllData — every non-settings table is empty after call',
      () async {
    // Seed: user, 3 entries (different dates + moods), 2 consent records.
    final userId = await db.userRepo.saveUser(
      User(
        displayName: 'Test User',
        email: 'test@example.com',
        subscriptionTier: 'free',
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await db.entries.saveEntry(
        JournalEntry(
          date: DateTime(2026, 4, 1 + i),
          entry: 'entry #$i',
          label: 'AM',
          title: null,
          mood: (i % 5) + 1,
          createdAt: DateTime(2026, 4, 1 + i, 9, 0),
          userId: userId,
        ),
      );
    }
    await db.userRepo.saveConsentRecord(
      consentType: 'privacy_policy',
      documentVersion: 'v1.0',
      acceptedAt: DateTime(2026, 3, 15),
    );
    await db.userRepo.saveConsentRecord(
      consentType: 'terms_of_service',
      documentVersion: 'v1.0',
      acceptedAt: DateTime(2026, 3, 15),
    );

    // Sanity: seeded data is readable.
    final entriesBefore = await db.entries.getAllEntries();
    expect(entriesBefore, hasLength(3));
    final userBefore = await db.userRepo.getUser();
    expect(userBefore, isNotNull);
    final consentBefore = await db.userRepo.getConsentRecords();
    expect(consentBefore, hasLength(2));

    // Act.
    await db.userRepo.deleteAllData();

    // Assert: every user-data table is empty.
    final entriesAfter = await db.entries.getAllEntries();
    expect(entriesAfter, isEmpty,
        reason: 'Delete-all must wipe every journal entry.');

    final userAfter = await db.userRepo.getUser();
    expect(userAfter, isNull,
        reason: 'Delete-all must wipe the user record.');

    final consentAfter = await db.userRepo.getConsentRecords();
    expect(consentAfter, isEmpty,
        reason: 'Delete-all must wipe every consent record.');

    // Settings gets re-inserted as a default row so the app can
    // start cleanly — that's intentional, not a data leak, since the
    // default row carries no user input. Verify it exists but is the
    // default (themeMode=0 / system, onboardingComplete=false).
    final settingsAfter = await db.settings.getSettings();
    expect(settingsAfter, isNotNull);
    expect(settingsAfter.onboardingComplete, isFalse);
    expect(settingsAfter.pinHash, isNull,
        reason: 'Re-inserted default settings must not carry a stale PIN.');
    expect(settingsAfter.biometricEnabled, isFalse);
    expect(settingsAfter.appLockEnabled, isFalse);
  });

  test('deleteAllData — FTS5 search index is cleared (no ghost entries)',
      () async {
    final userId = await db.userRepo.saveUser(
      User(
        displayName: 'FTS Tester',
        email: null,
        subscriptionTier: 'free',
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    await db.entries.saveEntry(
      JournalEntry(
        date: DateTime(2026, 4, 10),
        entry: 'distinctive-search-needle-pqrstuv',
        label: 'AM',
        title: null,
        createdAt: DateTime(2026, 4, 10, 9),
        userId: userId,
      ),
    );

    // Confirm FTS sees the needle.
    final matchesBefore =
        await db.entries.searchEntries('distinctive-search-needle-pqrstuv');
    expect(matchesBefore, hasLength(1));

    await db.userRepo.deleteAllData();

    // Confirm FTS returns nothing for the same needle — cascade /
    // trigger cleanup should have swept the FTS content table.
    final matchesAfter =
        await db.entries.searchEntries('distinctive-search-needle-pqrstuv');
    expect(matchesAfter, isEmpty,
        reason:
            'Delete-all must clear the FTS5 content table — an attacker who '
            'only has search access must not be able to see post-wipe ghosts.');
  });

  test('deleteAllData — idempotent (second call on empty DB succeeds)',
      () async {
    // Call on an already-clean DB. Should not throw.
    await db.userRepo.deleteAllData();
    await db.userRepo.deleteAllData();

    final entries = await db.entries.getAllEntries();
    expect(entries, isEmpty);
  });
}
