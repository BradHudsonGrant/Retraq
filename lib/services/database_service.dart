// SQL strings use double quotes for readability (they contain SQLite single quotes).
// ignore_for_file: prefer_single_quotes

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// sqlite3 v3 uses build hooks instead of manual library overrides.
import 'app_log.dart';
import 'entry_repository.dart';
import 'migration_strategy.dart';
import 'recap_service.dart';
import 'secure_storage.dart';
import 'settings_repository.dart';
import 'stats_service.dart';
import 'user_repository.dart';

export 'stats_service.dart' show StatsSnapshot;
export 'pin_service.dart' show PinService;

part 'database_service.g.dart';

/// SQLite table for journal entries.
@DataClassName('JournalEntryRow')
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get entry => text().nullable()();
  TextColumn get label => text().nullable()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get mood => integer().nullable()(); // 1-5 scale, null = no mood
  IntColumn get userId =>
      integer().nullable().references(
        Users,
        #id,
        onDelete: KeyAction.cascade,
      )();
}

/// SQLite table for users.
@DataClassName('UserRow')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text().nullable()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// SQLite table for user settings (singleton row, id always = 1).
class UserSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get themeMode =>
      integer().withDefault(const Constant(0))(); // 0=system, 1=light, 2=dark
  BoolColumn get isAllDayMode => boolean().withDefault(const Constant(true))();
  BoolColumn get askAboutToday => boolean().withDefault(const Constant(true))();
  BoolColumn get showEntryTitle =>
      boolean().withDefault(const Constant(false))();
  IntColumn get weekStartDay => integer().withDefault(const Constant(1))();
  IntColumn get nudgeHour => integer().withDefault(const Constant(20))();
  IntColumn get nudgeMinute => integer().withDefault(const Constant(0))();
  BoolColumn get appLockEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get pinHash => text().nullable()();
  BoolColumn get biometricEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get onboardingComplete =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get enterToSave => boolean().withDefault(const Constant(false))();
  BoolColumn get bulletPointsOnEnter =>
      boolean().withDefault(const Constant(false))();
  IntColumn get amPmCutoffHour => integer().withDefault(const Constant(14))();
  BoolColumn get moodEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get bionicReadingEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get userId => integer().nullable()();
}

/// SQLite table for consent records (privacy policy, terms of service).
@DataClassName('ConsentRecordRow')
class ConsentRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get consentType =>
      text()(); // 'privacy_policy' or 'terms_of_service'
  TextColumn get documentVersion => text()(); // date string like '2026-03-29'
  DateTimeColumn get acceptedAt => dateTime()();
  TextColumn get appVersion => text().nullable()();
}

@DriftDatabase(
  tables: [JournalEntries, Users, UserSettingsTable, ConsentRecords],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);
}

/// Singleton database service wrapping Drift (SQLite).
/// Initialises the database and exposes focused repositories.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  /// Log errors from stream watchers. Routes through [AppLog.error] so
  /// records survive release builds when `RETRAQ_LOG=true` is set, and
  /// so any registered [AppLog.sink] (tests / future Sentry adapter)
  /// can observe them.
  static void Function(String message)? onStreamError;

  static void logStreamError(String method, Object error) {
    final msg = 'DatabaseService.$method failed: $error';
    AppLog.error('DatabaseService.$method', error);
    onStreamError?.call(msg);
  }

  late AppDatabase _db;

  /// Expose the database for repositories (used internally).
  AppDatabase get db => _db;

  late EntryRepository entries;
  late SettingsRepository settings;
  late UserRepository userRepo;
  late StatsService stats;
  late RecapService recap;
  // PinService remains static (no DB dependency) — import pin_service.dart directly.

  static const _secureStorage = hardenedSecureStorage;
  static const _dbKeyName = 'retraq_db_key';

  static Future<String> _getOrCreateDbKey() async {
    var key = await _secureStorage.read(key: _dbKeyName);
    if (key == null) {
      final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      key = base64Encode(bytes);
      await _secureStorage.write(key: _dbKeyName, value: key);
    }
    return key;
  }

  /// Apply the encryption key and enable foreign keys on a raw database.
  /// Uses hex-encoded PRAGMA key to avoid SQL injection from special chars.
  static void _setupDb(dynamic db, String base64Key) {
    final keyBytes = base64Decode(base64Key);
    final hex = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    db.execute("PRAGMA key = \"x'$hex'\";");
    db.execute('PRAGMA foreign_keys = ON');
  }

  /// Must be called once before any DB operations (in main.dart).
  Future<void> init() async {
    // sqlite3 v3 uses build hooks (configured in pubspec.yaml) to bundle
    // SQLite3MultipleCiphers — no manual library override needed.

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'retraq.sqlite'));
    final encryptionKey = await _getOrCreateDbKey();

    // Clean up stale .bak files from previous migration attempts.
    // Overwrite with zeros before deleting to prevent data recovery.
    // Failures here can leave plaintext SQLite on disk, so log loudly so a
    // crash reporter (when wired) sees it instead of silently swallowing.
    final bakFile = File('${file.path}.bak');
    if (bakFile.existsSync()) {
      try {
        final bakLength = await bakFile.length();
        await bakFile.writeAsBytes(Uint8List(bakLength), flush: true);
        await bakFile.delete();
      } catch (e) {
        logStreamError('init.bakCleanup', e);
      }
    }

    if (file.existsSync()) {
      // Try opening with encryption first; if it fails, decide whether to
      // migrate or to abort. Do NOT migrate on arbitrary failure — a
      // corrupted encrypted DB or a rotated secure-storage key both surface
      // as open failures. Migrating in those cases would overwrite real
      // ciphertext with an empty encrypted DB and permanently lose data.
      // Only migrate when the on-disk file is demonstrably plaintext SQLite
      // (magic bytes "SQLite format 3\0").
      try {
        final testDb = AppDatabase(
          NativeDatabase(file, setup: (db) => _setupDb(db, encryptionKey)),
        );
        // Test that we can actually read from it.
        await testDb.customSelect('SELECT count(*) FROM sqlite_master').get();
        _db = testDb;
      } on Object catch (e, st) {
        final isPlaintext = await _looksLikePlaintextSqlite(file);
        if (isPlaintext) {
          // Existing unencrypted DB — safe to migrate.
          logStreamError('init.encryptedOpenFailed.migrating', e);
          await _migrateToEncrypted(file, encryptionKey);
        } else {
          // File exists but is not plaintext SQLite; the encrypted open
          // failed because the DB is corrupted, the secure-storage key was
          // rotated, or the device is in a transient failure state. Do NOT
          // clobber it — surface the error so the caller can prompt the
          // user to restore from export.
          logStreamError('init.encryptedOpenFailed.abort', e);
          Error.throwWithStackTrace(
            StateError(
              'Encrypted database at ${file.path} could not be opened and is '
              'not a plaintext SQLite file. Refusing to overwrite — check the '
              'secure-storage key or restore from backup.',
            ),
            st,
          );
        }
      }
    } else {
      _db = AppDatabase(
        NativeDatabase(file, setup: (db) => _setupDb(db, encryptionKey)),
      );
    }

    _initRepositories();

    // Verify foreign keys are enforced — catches silent PRAGMA failures.
    final fkResult = await _db.customSelect('PRAGMA foreign_keys').getSingle();
    assert(
      fkResult.data.values.first == 1,
      'PRAGMA foreign_keys is not ON after database init',
    );

    // Ensure settings defaults exist so watchSettings() emits immediately.
    await settings.getSettings();
  }

  /// SQLite plaintext magic bytes: "SQLite format 3\0".
  /// Only these bytes at offset 0 identify a plaintext SQLite database.
  /// An encrypted (SQLCipher / sqlite3mc) file starts with random ciphertext
  /// and will not match.
  static const List<int> _plaintextSqliteMagic = [
    0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
    0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
  ];

  /// Returns true iff [file] exists and begins with the SQLite plaintext
  /// magic bytes. Used to gate the destructive plaintext→encrypted migration
  /// path so that a failed encrypted-open on an already-encrypted file does
  /// not clobber real ciphertext.
  @visibleForTesting
  static Future<bool> looksLikePlaintextSqliteForTesting(File file) =>
      _looksLikePlaintextSqlite(file);

  static Future<bool> _looksLikePlaintextSqlite(File file) async {
    if (!file.existsSync()) return false;
    final length = await file.length();
    if (length < _plaintextSqliteMagic.length) return false;
    final raf = await file.open();
    try {
      final header = await raf.read(_plaintextSqliteMagic.length);
      for (var i = 0; i < _plaintextSqliteMagic.length; i++) {
        if (header[i] != _plaintextSqliteMagic[i]) return false;
      }
      return true;
    } finally {
      await raf.close();
    }
  }

  Future<void> _migrateToEncrypted(File file, String encryptionKey) async {
    // Belt-and-suspenders: refuse to migrate a file that isn't plaintext
    // SQLite. The call sites in init() already gate on _looksLikePlaintextSqlite,
    // but this guard protects any future caller (tests, migrations) from
    // accidentally destroying encrypted data by calling this directly.
    if (!await _looksLikePlaintextSqlite(file)) {
      throw StateError(
        'Refusing to migrate ${file.path}: file is not a plaintext SQLite '
        'database. Migration would overwrite existing ciphertext.',
      );
    }

    // Open unencrypted DB, read all data.
    final oldDb = AppDatabase(NativeDatabase(file));

    // Rename old file, create encrypted DB, import data.
    final backupFile = File('${file.path}.bak');
    await file.rename(backupFile.path);

    _db = AppDatabase(
      NativeDatabase(file, setup: (db) => _setupDb(db, encryptionKey)),
    );

    try {
      await copyAllTables(oldDb, _db);
    } finally {
      await oldDb.close();
    }

    // Migration succeeded — securely remove backup.
    // Overwrite with zeros before deleting to prevent data recovery.
    // If delete fails the migrated DB is still safe, but the plaintext backup
    // would linger on disk — log so a crash reporter (when wired) catches it.
    try {
      final bakLength = await backupFile.length();
      await backupFile.writeAsBytes(Uint8List(bakLength), flush: true);
      await backupFile.delete();
    } catch (e) {
      logStreamError('migrateToEncrypted.bakCleanup', e);
    }
  }

  /// Copy every row from every table in [source] into [target].
  ///
  /// MUST copy every column of every row (including nullable ones) so that
  /// the pre-encryption → encrypted migration does not silently reset any
  /// user setting to its schema default. Extracted so the column-copy logic
  /// can be exercised from tests without requiring SQLCipher.
  @visibleForTesting
  static Future<void> copyAllTables(
    AppDatabase source,
    AppDatabase target,
  ) async {
    final entryRows = await source.select(source.journalEntries).get();
    final userRows = await source.select(source.users).get();
    final settingsRows = await source.select(source.userSettingsTable).get();
    final consentRows = await source.select(source.consentRecords).get();

    await target.batch((batch) {
      // Users MUST be inserted before journal_entries because
      // journal_entries.user_id has a FK → users.id with PRAGMA foreign_keys=ON.
      for (final row in userRows) {
        batch.insert(
          target.users,
          UsersCompanion.insert(
            displayName: Value(row.displayName),
            email: Value(row.email),
            createdAt: row.createdAt,
          ),
        );
      }
      for (final row in entryRows) {
        batch.insert(
          target.journalEntries,
          JournalEntriesCompanion.insert(
            date: row.date,
            entry: Value(row.entry),
            label: Value(row.label),
            title: Value(row.title),
            createdAt: row.createdAt,
            mood: Value(row.mood),
            userId: Value(row.userId),
          ),
        );
      }
      for (final row in settingsRows) {
        batch.insert(
          target.userSettingsTable,
          UserSettingsTableCompanion(
            themeMode: Value(row.themeMode),
            isAllDayMode: Value(row.isAllDayMode),
            askAboutToday: Value(row.askAboutToday),
            showEntryTitle: Value(row.showEntryTitle),
            weekStartDay: Value(row.weekStartDay),
            nudgeHour: Value(row.nudgeHour),
            nudgeMinute: Value(row.nudgeMinute),
            appLockEnabled: Value(row.appLockEnabled),
            pinHash: Value(row.pinHash),
            biometricEnabled: Value(row.biometricEnabled),
            onboardingComplete: Value(row.onboardingComplete),
            enterToSave: Value(row.enterToSave),
            bulletPointsOnEnter: Value(row.bulletPointsOnEnter),
            amPmCutoffHour: Value(row.amPmCutoffHour),
            moodEnabled: Value(row.moodEnabled),
            bionicReadingEnabled: Value(row.bionicReadingEnabled),
            userId: Value(row.userId),
          ),
        );
      }
      for (final row in consentRows) {
        batch.insert(
          target.consentRecords,
          ConsentRecordsCompanion.insert(
            consentType: row.consentType,
            documentVersion: row.documentVersion,
            acceptedAt: row.acceptedAt,
            appVersion: Value(row.appVersion),
          ),
        );
      }
    });
  }

  /// Initialize with an in-memory database (for tests).
  @visibleForTesting
  Future<void> initInMemory() async {
    _db = AppDatabase(
      NativeDatabase.memory(
        setup: (db) {
          db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    _initRepositories();

    // Ensure settings defaults exist so watchSettings() emits immediately.
    await settings.getSettings();
  }

  void _initRepositories() {
    entries = EntryRepository(_db);
    settings = SettingsRepository(_db);
    userRepo = UserRepository(_db);
    stats = StatsService(_db);
    // expose RecapService on the facade so screens can
    // use db.recap.getWeeklySummary(...) instead of instantiating
    // their own RecapService(db.entries). Keeps the service surface
    // consistent with entries/settings/userRepo/stats.
    recap = RecapService(entries);
  }

  /// Clean up resources. Called when the app shuts down.
  Future<void> dispose() async {
    await _db.close();
  }
}
