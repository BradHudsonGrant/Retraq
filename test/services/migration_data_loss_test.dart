// ignore_for_file: prefer_single_quotes

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/database_service.dart';

/// Regression test for the pre-encryption → encrypted migration data-loss bug.
///
/// Prior to the fix, `_migrateToEncrypted` copied only 14 of 19 columns from
/// `UserSettingsTable`, silently dropping:
///   - moodEnabled
///   - moodRequired
///   - moodOnlyEntries
///   - bionicReadingEnabled
///   - userId
///
/// Every affected user who upgraded from a pre-encryption install had these
/// settings reset to schema defaults with no possible recovery (the `.bak`
/// was zero-overwritten and deleted). This test pins every column of every
/// table so that any future refactor of the column-copy logic will fail loudly
/// if a column is dropped.
void main() {
  group('_migrateToEncrypted (via copyAllTables)', () {
    late AppDatabase source;
    late AppDatabase target;

    setUp(() {
      // Two fresh, independent in-memory databases.
      // Raw construction on purpose — we do NOT want DatabaseService.initInMemory
      // to auto-insert a default settings row into the source, since we need
      // to insert our own row with non-default values for every column.
      source = AppDatabase(
        NativeDatabase.memory(
          setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      target = AppDatabase(
        NativeDatabase.memory(
          setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
        ),
      );
    });

    tearDown(() async {
      await source.close();
      await target.close();
    });

    test(
      'copies every UserSettingsTable column — no silent data loss',
      () async {
        // ── Arrange: insert a settings row into the source whose every
        // column differs from the schema default, so that if any column is
        // missed during the copy we will see the default (not our value).
        //
        // Schema defaults (from UserSettingsTable):
        //   themeMode=0, isAllDayMode=true, askAboutToday=true,
        //   showEntryTitle=false, weekStartDay=1, nudgeHour=20, nudgeMinute=0,
        //   appLockEnabled=false, pinHash=null, biometricEnabled=false,
        //   onboardingComplete=false, enterToSave=false,
        //   bulletPointsOnEnter=false, amPmCutoffHour=14, moodEnabled=false,
        //   moodRequired=false, moodOnlyEntries=false,
        //   bionicReadingEnabled=false, userId=null
        //
        // Our values flip every bool, shift every int, and set every nullable
        // to a known value.
        await source
            .into(source.userSettingsTable)
            .insert(
              UserSettingsTableCompanion.insert(
                themeMode: const Value(2), // flipped from 0 → 2 (dark)
                isAllDayMode: const Value(false), // flipped from true
                askAboutToday: const Value(false), // flipped from true
                showEntryTitle: const Value(true), // flipped from false
                weekStartDay: const Value(7), // flipped from 1 → 7 (Sunday)
                nudgeHour: const Value(9), // flipped from 20 → 9
                nudgeMinute: const Value(45), // flipped from 0 → 45
                appLockEnabled: const Value(true), // flipped from false
                pinHash: const Value('v3:100:abc:def'), // was null
                biometricEnabled: const Value(true), // flipped from false
                onboardingComplete: const Value(true), // flipped from false
                enterToSave: const Value(true), // flipped from false
                bulletPointsOnEnter: const Value(true), // flipped from false
                amPmCutoffHour: const Value(3), // flipped from 14 → 3
                moodEnabled: const Value(true), // flipped from false ***
                moodRequired: const Value(true), // flipped from false ***
                moodOnlyEntries: const Value(true), // flipped from false ***
                bionicReadingEnabled: const Value(
                  true,
                ), // flipped from false ***
                userId: const Value(4242), // was null ***
              ),
            );

        // Sanity check: the source row looks the way we inserted it.
        final sourceRow =
            await (source.select(source.userSettingsTable)).getSingle();
        expect(sourceRow.themeMode, 2);
        expect(sourceRow.moodEnabled, true);
        expect(sourceRow.userId, 4242);

        // ── Act: run the migration copy from source → target.
        await DatabaseService.copyAllTables(source, target);

        // ── Assert: the target settings row contains EVERY non-default value
        // we put into the source. If any column is missed by the copy, the
        // assertion for that column will fail because the schema default is
        // the opposite of what we set.
        final targetRow =
            await (target.select(target.userSettingsTable)).getSingle();

        expect(targetRow.themeMode, 2, reason: 'themeMode was not copied');
        expect(
          targetRow.isAllDayMode,
          false,
          reason: 'isAllDayMode was not copied',
        );
        expect(
          targetRow.askAboutToday,
          false,
          reason: 'askAboutToday was not copied',
        );
        expect(
          targetRow.showEntryTitle,
          true,
          reason: 'showEntryTitle was not copied',
        );
        expect(
          targetRow.weekStartDay,
          7,
          reason: 'weekStartDay was not copied',
        );
        expect(targetRow.nudgeHour, 9, reason: 'nudgeHour was not copied');
        expect(targetRow.nudgeMinute, 45, reason: 'nudgeMinute was not copied');
        expect(
          targetRow.appLockEnabled,
          true,
          reason: 'appLockEnabled was not copied',
        );
        expect(
          targetRow.pinHash,
          'v3:100:abc:def',
          reason: 'pinHash was not copied',
        );
        expect(
          targetRow.biometricEnabled,
          true,
          reason: 'biometricEnabled was not copied',
        );
        expect(
          targetRow.onboardingComplete,
          true,
          reason: 'onboardingComplete was not copied',
        );
        expect(
          targetRow.enterToSave,
          true,
          reason: 'enterToSave was not copied',
        );
        expect(
          targetRow.bulletPointsOnEnter,
          true,
          reason: 'bulletPointsOnEnter was not copied',
        );
        expect(
          targetRow.amPmCutoffHour,
          3,
          reason: 'amPmCutoffHour was not copied',
        );

        // These five are the regression-pinning asserts — they are the exact
        // columns that the original `_migrateToEncrypted` was silently dropping.
        expect(
          targetRow.moodEnabled,
          true,
          reason: 'REGRESSION: moodEnabled was dropped during migration',
        );
        expect(
          targetRow.moodRequired,
          true,
          reason: 'REGRESSION: moodRequired was dropped during migration',
        );
        expect(
          targetRow.moodOnlyEntries,
          true,
          reason: 'REGRESSION: moodOnlyEntries was dropped during migration',
        );
        expect(
          targetRow.bionicReadingEnabled,
          true,
          reason:
              'REGRESSION: bionicReadingEnabled was dropped during migration',
        );
        expect(
          targetRow.userId,
          4242,
          reason: 'REGRESSION: userId was dropped during migration',
        );
      },
    );

    test(
      'also copies Users, JournalEntries, and ConsentRecords tables',
      () async {
        // Smoke-check that the other three tables still round-trip correctly
        // after the refactor, so we don't silently break them on the way.
        final userInsertedId = await source
            .into(source.users)
            .insert(
              UsersCompanion.insert(
                displayName: const Value('Ada Lovelace'),
                email: const Value('ada@example.com'),
                subscriptionTier: const Value('premium'),
                createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
              ),
            );

        await source
            .into(source.journalEntries)
            .insert(
              JournalEntriesCompanion.insert(
                date: DateTime.utc(2026, 1, 3),
                entry: const Value('hello world'),
                label: const Value('AM'),
                title: const Value('my title'),
                createdAt: DateTime.utc(2026, 1, 3, 8, 30),
                mood: const Value(4),
                userId: Value(userInsertedId),
              ),
            );

        await source
            .into(source.consentRecords)
            .insert(
              ConsentRecordsCompanion.insert(
                consentType: 'privacy_policy',
                documentVersion: '2026-03-29',
                acceptedAt: DateTime.utc(2026, 3, 29, 12, 0, 0),
                appVersion: const Value('1.2.3'),
              ),
            );

        await DatabaseService.copyAllTables(source, target);

        final copiedUsers = await target.select(target.users).get();
        expect(copiedUsers, hasLength(1));
        expect(copiedUsers.single.displayName, 'Ada Lovelace');
        expect(copiedUsers.single.email, 'ada@example.com');
        expect(copiedUsers.single.subscriptionTier, 'premium');
        // Drift stores DateTime as unix-seconds (UTC) and reads back in local
        // time, so compare using isAtSameMomentAs rather than == to avoid a
        // spurious timezone mismatch in the assertion.
        expect(
          copiedUsers.single.createdAt.isAtSameMomentAs(
            DateTime.utc(2026, 1, 2, 3, 4, 5),
          ),
          isTrue,
        );

        final copiedEntries = await target.select(target.journalEntries).get();
        expect(copiedEntries, hasLength(1));
        expect(copiedEntries.single.entry, 'hello world');
        expect(copiedEntries.single.label, 'AM');
        expect(copiedEntries.single.title, 'my title');
        expect(copiedEntries.single.mood, 4);
        expect(copiedEntries.single.userId, copiedUsers.single.id);
        expect(
          copiedEntries.single.date.isAtSameMomentAs(DateTime.utc(2026, 1, 3)),
          isTrue,
        );
        expect(
          copiedEntries.single.createdAt.isAtSameMomentAs(
            DateTime.utc(2026, 1, 3, 8, 30),
          ),
          isTrue,
        );

        final copiedConsents = await target.select(target.consentRecords).get();
        expect(copiedConsents, hasLength(1));
        expect(copiedConsents.single.consentType, 'privacy_policy');
        expect(copiedConsents.single.documentVersion, '2026-03-29');
        expect(
          copiedConsents.single.acceptedAt.isAtSameMomentAs(
            DateTime.utc(2026, 3, 29, 12, 0, 0),
          ),
          isTrue,
        );
        expect(copiedConsents.single.appVersion, '1.2.3');
      },
    );
  });
}
