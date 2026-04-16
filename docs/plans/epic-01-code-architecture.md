# Epic 1 — Code Architecture & Quality

Source: review-2026-04-16.md §Agent 1
Total tasks: 18

---

### Task 1.1 — Narrow the bare catch around encrypted DB open

**Source:** A1 finding "`database_service.dart:204` swallows ALL exceptions from the encryption-test open and silently triggers plaintext→encrypted migration" · **Rating:** Critical
**Priority:** P0 · **Effort:** S · **Tier:** v1 launch

#### Problem
Any transient failure when opening the existing database (file lock, permission error, SQLCipher key mismatch, corrupt page, out-of-disk) currently falls into the `catch (_)` on line 204 and silently invokes `_migrateToEncrypted` on live user data. Users whose database is merely temporarily unavailable could lose it to an unnecessary migration, or worse, have their encrypted DB treated as plaintext.

#### Root cause
The original intent was "if the DB isn't encrypted yet, migrate it." That is a *very specific* failure mode (SQLite error code 26 NOTADB, or failure to decrypt the header), but the current code treats every exception the same way.

#### Files touched
- `lib/services/database_service.dart:195-212` — narrow the catch, add file-header inspection fallback.
- `test/services/database_service_encryption_test.dart` (new) — exercises the narrowed branch.

#### Implementation approach
1. Read the first 16 bytes of `file` before attempting the encrypted open. A plaintext SQLite database begins with the ASCII string `SQLite format 3\0` (`53 51 4C 69 74 65 20 66 6F 72 6D 61 74 20 33 00`). If the magic is present, we *know* the DB is plaintext and the migration path is correct. If the magic is absent and the encrypted open fails, we treat it as encrypted-and-something-else-wrong (propagate).
2. Catch only `SqliteException` on error code 26 (NOTADB) or `DriftRemoteException` wrapping the same, in addition to the header-check path.
3. On any other exception, log via `logStreamError('init.encryptedOpen', e)` and rethrow so the app fails loudly rather than destructively migrating.

```dart
if (file.existsSync()) {
  final isPlaintext = _looksLikePlaintextSqlite(file);
  try {
    final testDb = AppDatabase(
      NativeDatabase(file, setup: (db) => _setupDb(db, encryptionKey)),
    );
    await testDb.customSelect('SELECT count(*) FROM sqlite_master').get();
    _db = testDb;
  } on SqliteException catch (e) {
    if (isPlaintext || e.extendedResultCode == 26) {
      await _migrateToEncrypted(file, encryptionKey);
    } else {
      logStreamError('init.encryptedOpen', e);
      rethrow;
    }
  }
}

bool _looksLikePlaintextSqlite(File f) {
  final raf = f.openSync();
  try {
    final header = raf.readSync(16);
    const magic = [
      0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20,
      0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
    ];
    for (var i = 0; i < 16; i++) {
      if (header[i] != magic[i]) return false;
    }
    return true;
  } finally {
    raf.closeSync();
  }
}
```

#### Test plan
- New tests: `test/services/database_service_encryption_test.dart` — (a) fresh install uses encrypted path, (b) real plaintext DB with SQLite magic triggers migration, (c) random-bytes file does not trigger migration and instead propagates, (d) partial/locked file propagates without migrating.
- Modified tests: none.
- Regression: `flutter test`, `flutter analyze`.
- Manual verification: launch debug build against a pre-existing encrypted DB (no migration runs); launch against a manually-created plaintext SQLite fixture (migration runs once, key stored).

#### Acceptance criteria
- [ ] `catch (_)` on old line 204 is gone; only a narrowed catch remains.
- [ ] `_migrateToEncrypted` is only called when plaintext magic is present or `SqliteException` code 26 is raised.
- [ ] New encryption test suite exercises all four branches.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `fix(arch):` referencing Task 1.1.

#### Dependencies
- Blocks: Task 1.6 (error-path hardening benefits from this being correct).
- Blocked by: none.
- External: none.

---

### Task 1.2 — Extract _HomeSaveController and lift save logic out of home_screen.dart

**Source:** A1 finding "`home_screen.dart` is 806 LOC with 3 StreamSubscriptions, 2 TextEditingControllers, AnimationController, 5 lifecycle mixins, inline save logic, inline progress bar widgets" · **Rating:** Concern
**Priority:** P1 · **Effort:** L · **Tier:** v1 launch

#### Problem
`home_screen.dart` at 806 LOC owns data subscriptions, save orchestration, input controllers, mood picker, progress-bar drawing, and all layout. It is fragile, hard to test, and any new feature (share-to, widgets, voice entry) will push it past 1000 LOC.

#### Root cause
Feature growth added responsibilities inside `_HomeScreenState` rather than creating dedicated controllers or molecules.

#### Files touched
- `lib/screens/home_screen.dart:37-806` — reduce to ≤400 LOC by removing save orchestration and progress bar code.
- `lib/screens/home/home_save_controller.dart` (new) — ChangeNotifier/Listenable holding `title`, `entry`, `mood`, `currentEntryId`, and the `save()`/`resolveConflict()` methods.
- `lib/widgets/molecules/progress_bar.dart` (new) — lift `_buildProgressBar` out of the screen.
- `lib/widgets/molecules/title_field.dart` (new) — lift `_buildTitleField` out.
- `test/screens/home/home_save_controller_test.dart` (new).
- `test/widgets/molecules/progress_bar_test.dart` (new).

#### Implementation approach
1. Create `HomeSaveController` with fields `(TextEditingController titleCtrl, TextEditingController entryCtrl, int? mood, DateTime targetDate, JournalEntry? existingEntry)` and methods `save()`, `updateMood()`, `applyDateOverride()`. Inject `EntryRepository` via constructor.
2. Move all `setState` calls in save paths into the controller's notifiers; screen listens with `ValueListenableBuilder`/`AnimatedBuilder`.
3. Extract `_buildProgressBar` (estimated lines ~500-560 in `home_screen.dart`) into a pure stateless `ProgressBar` molecule taking `int streak, int target`.
4. Extract `_buildTitleField` into a `TitleField` molecule taking `TextEditingController controller, FocusNode focus, bool enabled`.
5. Leave stream subscriptions (`watchEntryForDate`, settings stream) on the screen but push side-effect branches (e.g. "entry externally changed") into controller callbacks.

```dart
class HomeSaveController extends ChangeNotifier {
  HomeSaveController(this._repo);
  final EntryRepository _repo;
  final titleCtrl = TextEditingController();
  final entryCtrl = TextEditingController();
  int? mood;
  int? currentEntryId;
  DateTime targetDate = DateTime.now();

  Future<void> save() async { /* moved from _HomeScreenState._save */ }
  @override
  void dispose() { titleCtrl.dispose(); entryCtrl.dispose(); super.dispose(); }
}
```

#### Test plan
- New tests: `home_save_controller_test.dart` — saves new entry, updates existing entry, handles empty-text skip, mood-only entry gate. `progress_bar_test.dart` — renders correct proportion, handles 0-day streak. `title_field_test.dart` — fires onChanged, respects enabled.
- Modified tests: `test/screens/home_screen_test.dart` — update mock wiring for injected controller.
- Regression: `flutter test`, `flutter analyze`.
- Manual verification: save entry, update entry, clear entry, dismiss keyboard with unsaved text, switch dates — all unchanged visually and behaviorally.

#### Acceptance criteria
- [ ] `home_screen.dart` ≤ 400 LOC.
- [ ] `HomeSaveController` has ≥ 80% branch coverage.
- [ ] `ProgressBar` and `TitleField` exist under `lib/widgets/molecules/`.
- [ ] No behavioral regression in existing widget tests.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `refactor(arch):` referencing Task 1.2.

#### Dependencies
- Blocks: Task 1.3 (stats refactor follows the same pattern).
- Blocked by: none.
- External: none.

---

### Task 1.3 — Move Stats "On This Day" logic into StatsService and slim stats_screen.dart / recap_screen.dart

**Source:** A1 finding "`stats_screen.dart` (756) and `recap_screen.dart` (455) each hold multiple streams + business logic alongside layout" · **Rating:** Concern
**Priority:** P1 · **Effort:** M · **Tier:** v1 launch

#### Problem
Stats and Recap screens hold non-trivial business logic (On-This-Day lookup, mood aggregation, streak windows) mixed into widget state. This breaks unit testability and duplicates calculations that belong in the stats service.

#### Root cause
When StatsService was first introduced it only covered streaks; later features were added directly into the screens instead of extending the service.

#### Files touched
- `lib/services/stats_service.dart` — add `Future<List<JournalEntry>> onThisDayEntries(DateTime today)`, `Stream<MoodSummary> watchMoodSummary(DateRange)`, `Future<RecapSnapshot> recapFor(DateTime weekOf)`.
- `lib/screens/stats_screen.dart:35,97` — replace inline queries with `StatsService` calls.
- `lib/screens/recap_screen.dart:37-38` — same.
- `test/services/stats_service_on_this_day_test.dart` (new).

#### Implementation approach
1. Audit the two screens for every direct `DatabaseService`/`EntryRepository` call and aggregation helper; list them with their line ranges.
2. For each, add a typed method on `StatsService` returning a domain object (`OnThisDayResult`, `MoodSummary`, `RecapSnapshot`). Cache-only behavior lives inside the service; UI just consumes.
3. Screens are left as thin `StreamBuilder`/`FutureBuilder` consumers. Target ≤ 500 LOC on `stats_screen.dart`, ≤ 350 on `recap_screen.dart`.
4. Keep a deprecation shim only if required by a widget test mid-refactor; otherwise update tests to call the service directly.

#### Test plan
- New tests: `stats_service_on_this_day_test.dart` — entries from same day-of-year across multiple years returned sorted desc, empty handling, leap-day handling (Feb 29 requesting from non-leap year). Additional specs for mood summary and recap aggregation.
- Modified tests: existing `stats_screen_test.dart`, `recap_screen_test.dart` — update mocks.
- Regression: `flutter test`, `flutter analyze`.
- Manual verification: Stats tab renders On-This-Day block with prior-year entries; Recap tab shows weekly summary counts unchanged.

#### Acceptance criteria
- [ ] `stats_screen.dart` ≤ 500 LOC, `recap_screen.dart` ≤ 350 LOC.
- [ ] No direct `EntryRepository`/`_db` calls from either screen.
- [ ] New service methods have ≥ 75% line coverage.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `refactor(arch):` referencing Task 1.3.

#### Dependencies
- Blocks: Task 1.14 (RecapService facade promotion).
- Blocked by: Task 1.2 (establishes the controller pattern).
- External: none.

---

### Task 1.4 — Replace remaining bare catches with typed handlers and plumb crash reporter

**Source:** A1 finding "9 bare `catch (_)` blocks discard error info; 125+ `async` paths with only `debugPrint` on failure and no crash reporter wired" · **Rating:** Concern
**Priority:** P1 · **Effort:** M · **Tier:** v1 launch

#### Problem
Production crashes will be invisible. Every bare `catch (_)` drops the exception and stack, and `debugPrint` vanishes in release builds, so any regression after launch will be undiagnosable.

#### Root cause
Incremental defensive coding accumulated; no central logging façade ever arrived, and crash reporting was deferred.

#### Files touched
- `lib/services/user_repository.dart:113,125,135` — narrow and log.
- `lib/screens/onboarding_screen.dart:91,204,231` — narrow and log.
- `lib/screens/settings/data_section.dart:134` — narrow and log.
- `lib/screens/settings/security_section.dart:37` — narrow and log.
- `lib/services/database_service.dart` — ensure `onStreamError` callback is exposed.
- `lib/services/app_log.dart` (new, paired with Task 1.13 — coordinate) — thin wrapper used here.
- `test/services/user_repository_error_paths_test.dart` (new).

#### Implementation approach
1. Introduce (or reuse from Task 1.13) `AppLog.warn(String scope, Object e, [StackTrace? st])` backed by `dart:developer` in debug and `logStreamError` in release; make it a single call-site that later wires to Sentry/Crashlytics.
2. For each bare catch, replace with a typed catch appropriate to the call:
   - `SharedPreferences`/`FlutterSecureStorage` → `catch (e, st) { AppLog.warn('settings.clear', e, st); }` (intentional swallow in test env is preserved, but logged).
   - `HomeWidget` failures → `AppLog.warn('widget.update', e, st)`.
3. Leave a single documented bare-catch only when `// ignore: avoid_catches_without_on_clauses` is justified (e.g. isolate boundary). Minimize to zero if possible.
4. Add a `DatabaseService.onStreamError` hook (void Function(Object, StackTrace)?) so callers can register a Sentry handler later without changes here.

```dart
} catch (e, st) {
  AppLog.warn('user_repository.clearPrefs', e, st);
}
```

#### Test plan
- New tests: `user_repository_error_paths_test.dart` — simulate SharedPreferences throwing; assert log invoked via injected `AppLog` sink.
- Modified tests: add lightweight verification in `onboarding_screen_test.dart` that errors no longer silently pass.
- Regression: `flutter test`, `flutter analyze`.
- Manual verification: toggle biometric with mis-configured keystore — error is logged with scope/stack, UI remains usable.

#### Acceptance criteria
- [ ] Zero `catch (_)` in the 8 call sites named above.
- [ ] `DatabaseService.onStreamError` is documented and wired in `main.dart`.
- [ ] Static grep `catch \(_\)` across `lib/` has been reviewed and justified or eliminated.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `fix(arch):` referencing Task 1.4.

#### Dependencies
- Blocks: none.
- Blocked by: Task 1.13 (AppLog wrapper).
- External: crash reporter selection (Sentry vs Crashlytics) deferred; this task only wires the hook.

---

### Task 1.5 — Expand analysis_options.yaml with stricter lint rules

**Source:** A1 finding "`analysis_options.yaml` enables only 8 lint rules and relies on `flutter_lints` base" · **Rating:** Concern
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
Missing rules allow idiomatic bugs to slip by: unclosed sinks, uncanceled subscriptions, un-awaited futures, dynamic calls, empty else branches.

#### Root cause
The project was bootstrapped with default `flutter_lints` and never extended.

#### Files touched
- `analysis_options.yaml:23-31` — add rules.
- Any file surfaced by the new rules (expected small delta; fix in same commit).

#### Implementation approach
1. Add the following under `linter.rules`:

```yaml
    cancel_subscriptions: true
    close_sinks: true
    unawaited_futures: true
    prefer_final_locals: true
    avoid_dynamic_calls: true
    avoid_empty_else: true
    unnecessary_lambdas: true
    avoid_returning_null_for_future: true
```

2. Run `flutter analyze`; fix each flagged site (most likely: missing `unawaited(...)` on fire-and-forget, `final` on locals, one or two dynamic calls around map access).
3. Where an `unawaited_futures` warning is intentional (background DB write), wrap with `unawaited(...)` from `dart:async`.

#### Test plan
- New tests: none.
- Modified tests: update any test caught by new rules.
- Regression: `flutter analyze` must exit 0; `flutter test` full suite.
- Manual verification: n/a.

#### Acceptance criteria
- [ ] `analysis_options.yaml` has all 8 new rules enabled.
- [ ] `flutter analyze` returns zero warnings/errors.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `chore(arch):` referencing Task 1.5.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: none.

---

### Task 1.6 — Replace singleton services with minimal DI (get_it)

**Source:** A1 finding "Singleton sprawl: 6 distinct singletons + static `PinService` — untestable without `@visibleForTesting` back doors" · **Rating:** Concern
**Priority:** P1 · **Effort:** L · **Tier:** v1 launch

#### Problem
`DatabaseService`, `NotificationService`, `ReviewService`, `ScreenSecurityService`, `WidgetService`, `ExportService`, plus static `PinService` are global singletons. Tests must reach in via `@visibleForTesting` setters; the upcoming RevenueCat/subscription service would only worsen this.

#### Root cause
Services were added one-at-a-time, each choosing the fastest shape (global instance) rather than introducing a container.

#### Files touched
- `pubspec.yaml` — add `get_it: ^7.7.0`.
- `lib/di/service_locator.dart` (new) — setup function `Future<void> configureDependencies()`.
- `lib/services/database_service.dart` — remove `DatabaseService.instance`; expose a normal constructor.
- Same removal for `notification_service`, `review_service`, `screen_security_service`, `widget_service`, `export_service`.
- `lib/services/pin_service.dart` — convert from static methods to instance methods registered as `LazySingleton`.
- `lib/main.dart:22-53` — call `configureDependencies()` before `runApp`.
- All screens that do `DatabaseService.instance` → `GetIt.I<DatabaseService>()` (or accept via constructor where already stateful).
- `test/test_support/di_harness.dart` (new) — `resetAndRegister({DatabaseService? db, ...})` for test overrides.

#### Implementation approach
1. Add `get_it` dependency; create `service_locator.dart` with registrations as `LazySingleton` (so cold start cost equals the old lazy initializer).
2. In `main.dart`, call `await configureDependencies()` right after `WidgetsFlutterBinding.ensureInitialized()`.
3. Replace every `DatabaseService.instance` / `NotificationService.instance` / etc. with `GetIt.I<T>()`. Prefer injecting via constructor for newly-refactored widgets (e.g., `HomeSaveController` from Task 1.2 already takes a repo).
4. `PinService` becomes an instance class; its static methods become normal methods. A thin top-level helper `pinService => GetIt.I<PinService>()` can ease migration.
5. For tests: `di_harness.dart` resets the locator and registers mocks.

#### Test plan
- New tests: `test/di/service_locator_test.dart` — verifies registrations resolve and are singletons.
- Modified tests: every test previously using `DatabaseService.instance = fakeDb` switches to `resetAndRegister(db: fakeDb)`.
- Regression: full `flutter test`; `flutter analyze`.
- Manual verification: cold start time unchanged (eyeball); app operates normally; background services (notifications, widget updates) still run.

#### Acceptance criteria
- [ ] Zero static `.instance` service getters remain in `lib/services/`.
- [ ] `GetIt` registrations cover all 7 services.
- [ ] Tests no longer set singleton instances via back-door setters.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `refactor(arch):` referencing Task 1.6.

#### Dependencies
- Blocks: future RevenueCat/subscription work.
- Blocked by: Task 1.2, Task 1.3 (refactored controllers already expect DI).
- External: none.

---

### Task 1.7 — Extract AppSnackBar helper to deduplicate 36 SnackBar constructions

**Source:** A1 finding "Duplicated SnackBar styling (36 SnackBar constructions, 22 RoundedRectangleBorder with `AppSpacing.borderRadiusLg`)" · **Rating:** Concern
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
The same SnackBar styling (shape, padding, behavior, duration) is recreated in 36 call sites. Any visual-system change requires 36 edits; inconsistencies have already appeared.

#### Root cause
No helper existed when the first SnackBar was written; subsequent authors copy-pasted.

#### Files touched
- `lib/widgets/atoms/app_snack_bar.dart` (new) — `AppSnackBar.show(BuildContext, String, {bool error = false, SnackBarAction? action})` plus `AppSnackBar.error(...)`.
- `lib/screens/home_screen.dart:682-691,694-705,734-747,509-523` — replace inline constructions.
- `lib/utils/entry_action_dialogs.dart:59` — replace.
- All other 30+ call sites in `lib/screens/`.
- `test/widgets/atoms/app_snack_bar_test.dart` (new).

#### Implementation approach
1. Create `AppSnackBar` with a single public `show`:

```dart
class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool error = false,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        backgroundColor: error
            ? Theme.of(context).colorScheme.errorContainer
            : null,
        content: Text(message),
        action: action,
        duration: duration,
      ));
  }
}
```

2. Search-and-replace each call site. Preserve custom `action:` parameters.
3. Add a golden/widget test asserting the shape, duration, and error-variant background.

#### Test plan
- New tests: `app_snack_bar_test.dart` — show default, show with action, show error variant, hides previous snackbar on rapid re-show.
- Modified tests: any that assert on a specific SnackBar construction should call `AppSnackBar.show` via the finder.
- Regression: `flutter test`, `flutter analyze`.
- Manual verification: trigger save, delete, undo, error toast — styling identical to before.

#### Acceptance criteria
- [ ] Grep for `SnackBar(` in `lib/` returns only occurrences inside `app_snack_bar.dart`.
- [ ] All call sites compile without custom `shape:` or `behavior:` arguments.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `refactor(arch):` referencing Task 1.7.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: none.

---

### Task 1.8 — Introduce JournalEntry.fromRawRow to kill Drift mapping duplication

**Source:** A1 finding "Drift mapping duplication: `rowToEntry` redefined inline inside `EntryRepository.searchEntries`" · **Rating:** Concern
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
`EntryRepository.rowToEntry` (lines 18-31) and the inline mapper in `searchEntries` (lines 429-450) diverge silently when a new field is added to `JournalEntry` — the FTS search path has already drifted from the canonical mapping.

#### Root cause
FTS search uses `customSelect` (returns `QueryRow`) rather than the typed `journalEntries` table, so the existing `rowToEntry(JournalEntryRow)` could not be reused without a shared constructor.

#### Files touched
- `lib/models/journal_entry.dart` — add `JournalEntry.fromRawRow(QueryRow row)` factory.
- `lib/services/entry_repository.dart:18-31,429-450` — replace both mapping sites with `JournalEntry.fromRawRow`/`rowToEntry` that both delegate to the new factory.
- `test/models/journal_entry_test.dart` — add coverage for the new factory.

#### Implementation approach
1. Add a `JournalEntry.fromRawRow(QueryRow row)` factory that reads columns by name with nullable variants where appropriate. Normalize dates to local midnight.
2. Refactor `rowToEntry(JournalEntryRow)` to call a private `_normalize` helper identical to the new factory's date logic.
3. Update `searchEntries` to `.map((row) => JournalEntry.fromRawRow(row))`.

```dart
factory JournalEntry.fromRawRow(QueryRow row) {
  final dateRaw = row.read<int>('date');
  final createdRaw = row.read<int>('created_at');
  final localDate = DateTime.fromMillisecondsSinceEpoch(dateRaw * 1000).toLocal();
  return JournalEntry(
    id: row.read<int>('id'),
    date: DateTime(localDate.year, localDate.month, localDate.day),
    entry: row.readNullable<String>('entry'),
    label: row.readNullable<String>('label'),
    title: row.readNullable<String>('title'),
    mood: row.readNullable<int>('mood'),
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdRaw * 1000).toLocal(),
  );
}
```

#### Test plan
- New tests: `journal_entry_test.dart` — factory parses a raw row correctly including nullable fields and UTC→local normalization.
- Modified tests: none.
- Regression: `flutter test`, `flutter analyze`.
- Manual verification: FTS search returns entries that display identical metadata vs. tapping them from list (titles, moods, dates match).

#### Acceptance criteria
- [ ] `JournalEntry.fromRawRow` exists; both repository paths use it.
- [ ] Adding a new nullable field to `JournalEntry` requires edits in exactly one mapping location.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `refactor(arch):` referencing Task 1.8.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: none.

---

### Task 1.9 — Adopt equatable for UserSettings to replace manual == / hashCode

**Source:** A1 finding "`RetraqApp` manually rebuilds on settings-stream changes by comparing `UserSettings` via `==`/hashCode on 18 fields — brittle" · **Rating:** Concern
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
`UserSettings` manually implements `==` and `hashCode` across 18 fields. Every time a new setting lands, authors must remember to update both — and one field was already missed in a past audit. A field that silently falls out of equality causes `RetraqApp` to stop rebuilding when that setting changes.

#### Root cause
No equality helper adopted; `freezed` is considered heavier than necessary for a single model.

#### Files touched
- `pubspec.yaml` — add `equatable: ^2.0.5`.
- `lib/models/user_settings.dart:94-136` — replace manual `==` / `hashCode` with `Equatable.props`.
- `test/models/user_settings_equatable_test.dart` (new).

#### Implementation approach
1. Change `class UserSettings` to `class UserSettings extends Equatable`.
2. Remove manual `==` and `hashCode`; override `List<Object?> get props` listing all 18 fields.
3. Keep `copyWith` unchanged.
4. Because `Equatable` makes instances immutable by convention, confirm all fields are already `final` (they are in current audit).

```dart
class UserSettings extends Equatable {
  const UserSettings({ /* existing ctor */ });
  // fields unchanged
  @override
  List<Object?> get props => [
    themeMode, isAllDayMode, askAboutToday, showEntryTitle, weekStartDay,
    nudgeHour, nudgeMinute, appLockEnabled, pinHash, biometricEnabled,
    onboardingComplete, enterToSave, bulletPointsOnEnter, amPmCutoffHour,
    moodEnabled, moodRequired, moodOnlyEntries, bionicReadingEnabled,
  ];
}
```

#### Test plan
- New tests: `user_settings_equatable_test.dart` — equals across all-fields identical, not-equals on each individual field, `props` length equals declared field count (guard against forgetting a field).
- Modified tests: any existing equality test continues to pass.
- Regression: `flutter test`, `flutter analyze`.
- Manual verification: toggle a setting in the UI; app rebuilds exactly once per change (verify with a temporary `debugPrint` in `RetraqApp.build`).

#### Acceptance criteria
- [ ] `UserSettings` extends `Equatable`.
- [ ] Manual `==` and `hashCode` are removed.
- [ ] Test asserts `props.length == 18`.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `refactor(arch):` referencing Task 1.9.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: none.

---

### Task 1.10 — Fold single-file providers/ into widgets/ (or populate it)

**Source:** A1 finding "Orphan check: single-file `providers/` directory contains only `settings_provider.dart`" · **Rating:** Concern
**Priority:** P2 · **Effort:** XS · **Tier:** v1 launch

#### Problem
`lib/providers/` exists solely to hold `settings_provider.dart`. Either the directory is a hint of a broader DI pattern that never materialized, or the file belongs next to its widget consumers.

#### Root cause
An `InheritedWidget` was introduced once and the directory was never expanded or collapsed.

#### Files touched
- `lib/providers/settings_provider.dart` → move to `lib/widgets/settings_provider.dart` (or into `lib/di/` as part of Task 1.6's service locator).
- All imports of `package:retraq/providers/settings_provider.dart` in `lib/` and `test/` — update.
- `lib/providers/` — delete empty directory.

#### Implementation approach
1. If Task 1.6 lands first: move `SettingsProvider` into `lib/di/service_locator.dart` as a scoped provider, eliminating the InheritedWidget in favor of `GetIt.I<SettingsStream>()`.
2. Otherwise: move the file to `lib/widgets/settings_provider.dart` and update all `import` statements via find/replace.
3. Remove the now-empty `providers/` directory.

#### Test plan
- New tests: none.
- Modified tests: import paths updated.
- Regression: `flutter analyze`, `flutter test`.
- Manual verification: theme toggle, mood toggle propagate through the app.

#### Acceptance criteria
- [ ] `lib/providers/` no longer exists, OR is documented and populated with ≥ 2 providers.
- [ ] All imports updated; no broken references.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `chore(arch):` referencing Task 1.10.

#### Dependencies
- Blocks: none.
- Blocked by: prefer after Task 1.6.
- External: none.

---

### Task 1.11 — Document atoms/molecules/organisms boundary rules in CONTRIBUTING

**Source:** A1 finding "Atoms/molecules/organisms hierarchy correctly applied; 35 widgets neatly categorized" · **Rating:** Good
**Priority:** P2 · **Effort:** XS · **Tier:** v1 launch

#### Problem
The structure is healthy but informal — there is no documented rule for "when does a molecule graduate to an organism?" New contributors will blur the layers.

#### Root cause
Taxonomy was applied in practice but never written down.

#### Files touched
- `CONTRIBUTING.md` (new, or existing) — add "Widget taxonomy" section.
- `docs/widget-taxonomy.md` (new) — longer-form reference linked from CONTRIBUTING.

#### Implementation approach
1. Write concise rules:
   - **Atom:** no other atoms/molecules inside; no business logic; takes only primitive or style-layer props.
   - **Molecule:** composes 2+ atoms; may hold local visual state (hover, focus); zero repository access.
   - **Organism:** composes molecules/atoms; may consume DI services and streams; cannot be placed inside another organism.
2. Include a short FAQ with 3-4 worked examples drawn from actual widgets (e.g. `ProgressBar` = molecule, `HomeComposer` = organism).
3. Link from repo README.

#### Test plan
- New tests: none.
- Modified tests: none.
- Regression: docs-only.
- Manual verification: dev reads the guide and can classify a candidate widget without asking.

#### Acceptance criteria
- [ ] `CONTRIBUTING.md` contains a "Widget taxonomy" section with 3 rules and 3 examples.
- [ ] Linked from README.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `chore(arch):` referencing Task 1.11.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: none.

---

### Task 1.12 — Keep `.g.dart`, `/build/`, `.claude/` gitignore as-is (reference)

**Source:** A1 finding "`.g.dart`, `/build/`, `.claude/` correctly gitignored; Drift part-of codegen works" · **Rating:** Good
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
No action needed; keep as reference.

#### Root cause
n/a

#### Files touched
- `.gitignore:48` — unchanged.

#### Implementation approach
No action needed; keep as reference. The configuration is correct and should only be revisited if Drift codegen changes its output convention or if a new generator is added.

#### Test plan
- Regression: n/a.

#### Acceptance criteria
- [ ] Documented as intentional.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: none.

---

### Task 1.13 — Introduce AppLog wrapper for release-safe diagnostics

**Source:** A1 finding "No `dart:developer` logger; `debugPrint` only; release builds lose diagnostics" · **Rating:** Concern
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
`debugPrint` output is suppressed in release builds. Once the app ships, developers have no way to opt into lightweight telemetry or correlate user reports with logs.

#### Root cause
No logging abstraction was ever introduced.

#### Files touched
- `lib/services/app_log.dart` (new) — thin façade over `dart:developer`'s `log()` with scope + level.
- `lib/services/*.dart` — replace `debugPrint(...)` with `AppLog.info/warn/error(...)`.

#### Implementation approach
1. Create `AppLog` with methods `info`, `warn`, `error`, each taking `(String scope, String message, [Object? error, StackTrace? st])`. Delegate to `developer.log(message, name: scope, level: ..., error: error, stackTrace: st)`.
2. Gate release-build behavior behind a compile-time `const kEnableReleaseLogs = bool.fromEnvironment('RETRAQ_LOG', defaultValue: false)`; callers remain unaware.
3. Provide a test-visible sink (`AppLog.sink = (record) => ...`) so tests can assert emitted logs without coupling to `developer.log`.
4. Convert the ~40 highest-value `debugPrint` sites (services, error paths) first; lower-value UI traces can be migrated incrementally.

```dart
class AppLog {
  static LogSink? sink;
  static void warn(String scope, Object e, [StackTrace? st]) {
    sink?.call(LogRecord('warn', scope, e.toString(), st));
    developer.log(e.toString(), name: scope, level: 900, error: e, stackTrace: st);
  }
}
```

#### Test plan
- New tests: `test/services/app_log_test.dart` — captures records via sink; asserts scope/level propagation.
- Modified tests: none initially.
- Regression: `flutter test`, `flutter analyze`.
- Manual verification: run a debug build, confirm `flutter run` console shows labeled output; run a release build with `--dart-define=RETRAQ_LOG=true` and confirm logs surface in `logcat`/`oslog`.

#### Acceptance criteria
- [ ] `AppLog` exists with `info`/`warn`/`error` signatures.
- [ ] ≥ 40 `debugPrint` call sites in `lib/services/` converted.
- [ ] Test sink captures records.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `refactor(arch):` referencing Task 1.13.

#### Dependencies
- Blocks: Task 1.4 (uses AppLog for narrowed catches).
- Blocked by: none.
- External: decision on whether to wire Sentry/Crashlytics as a `LogSink` subclass (deferred to v1.1).

---

### Task 1.14 — Promote RecapService onto the DatabaseService facade

**Source:** A1 finding cross-reference (see memory item 35 in review top-level priority list) tied to stats/recap refactor · **Rating:** Concern (implicit via stats_screen/recap_screen row)
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
Recap computations currently live outside the repository façade, meaning callers must import both `DatabaseService` and recap helpers. This inconsistency grows friction and blocks future caching or memoization.

#### Root cause
Recap arrived after the facade pattern was established and was never brought under the same shape.

#### Files touched
- `lib/services/database_service.dart` — expose `RecapService get recap` accessor.
- `lib/services/recap_service.dart` (new or promoted from helper) — owns recap data access.
- `lib/screens/recap_screen.dart:37-38` — updated imports.
- `test/services/recap_service_test.dart` (new).

#### Implementation approach
1. Fold recap helpers into a `RecapService(this._db, this._statsService)` class.
2. Register via `GetIt` alongside other services (Task 1.6) and add `DatabaseService.recap` accessor returning the same instance for symmetry.
3. `recap_screen.dart` switches from free functions to service calls.

#### Test plan
- New tests: `recap_service_test.dart` — weekly/monthly aggregation snapshots stable across timezones.
- Modified tests: `recap_screen_test.dart` — updated mocks.
- Regression: `flutter test`, `flutter analyze`.
- Manual verification: Recap tab continues to show weekly summaries identical to before.

#### Acceptance criteria
- [ ] `RecapService` exists and is registered.
- [ ] `DatabaseService.recap` accessor is available.
- [ ] Recap screen no longer imports free helpers.
- [ ] `flutter analyze` clean, `flutter test` passes, coverage does not drop below 45%.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with message prefixed `refactor(arch):` referencing Task 1.14.

#### Dependencies
- Blocks: none.
- Blocked by: Task 1.3, Task 1.6.
- External: none.

---

### Task 1.15 — Keep stream-lifecycle hygiene as-is (reference)

**Source:** A1 finding "Stream lifecycle correctly handled: `StreamSubscription?.cancel()` in dispose, `if (!mounted) return` guards, `handleError` on every `.watch()` stream" · **Rating:** Good
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
No action needed; keep as reference.

#### Root cause
n/a

#### Files touched
- `lib/services/entry_repository.dart:109-111,202-203` — unchanged.
- `lib/screens/home_screen.dart:163-173` — unchanged.

#### Implementation approach
No action needed; keep as reference. Task 1.5 adds `cancel_subscriptions`/`close_sinks` lints so this discipline is enforced going forward by the analyzer.

#### Test plan
- Regression: covered by the new lint rules in Task 1.5.

#### Acceptance criteria
- [ ] Documented as intentional.

#### Dependencies
- Blocks: none.
- Blocked by: Task 1.5 would make future regressions fail CI.
- External: none.

---

### Task 1.16 — Keep migration strategy extraction as-is (reference)

**Source:** A1 finding "`buildMigrationStrategy` extracted, `copyAllTables` annotated `@visibleForTesting`, 14 schema versions with incremental migrations" · **Rating:** Good
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
No action needed; keep as reference.

#### Root cause
n/a

#### Files touched
- `lib/services/database_service.dart:106-117` — unchanged.
- `lib/services/migration_strategy.dart` — unchanged.

#### Implementation approach
No action needed; keep as reference. When adding schema version 15, follow the existing `onUpgrade` branch pattern and add a dedicated step-up test.

#### Test plan
- Regression: existing migration tests continue to cover 1→14.

#### Acceptance criteria
- [ ] Documented as intentional.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: none.

---

### Task 1.17 — Keep PBKDF2 iteration count and isolate dispatch as-is (reference)

**Source:** A1 finding "Pure Dart PBKDF2 at 100K iterations with documented rationale and isolate dispatch via `compute()`" · **Rating:** Good
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
No action needed; keep as reference.

#### Root cause
n/a

#### Files touched
- `lib/services/pin_service.dart:13-18,60-73` — unchanged.

#### Implementation approach
No action needed; keep as reference. Revisit iteration count annually per OWASP guidance; PBKDF2-SHA256 at 600K iterations may be appropriate for high-end devices by 2027. Any change must ship behind a versioned hash migration (already supported).

#### Test plan
- Regression: existing pin_service tests cover the migration path.

#### Acceptance criteria
- [ ] Documented as intentional.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: OWASP ASVS iteration-count guidance review (annual).

---

### Task 1.18 — Keep main.dart bootstrap and global error handlers as-is (reference)

**Source:** A1 finding "`main.dart` uses `WidgetsFlutterBinding.ensureInitialized()`, sets `FlutterError.onError` and `PlatformDispatcher.instance.onError` global handlers, defers non-critical services to post-first-frame" · **Rating:** Good
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
No action needed; keep as reference.

#### Root cause
n/a

#### Files touched
- `lib/main.dart:22-53,96-113` — unchanged.

#### Implementation approach
No action needed; keep as reference. When Sentry/Crashlytics is wired (per Task 1.13 / Task 1.4 hook), its handler should be installed inside these existing callbacks so crash reporting simply extends the already-correct bootstrap shape.

#### Test plan
- Regression: `main.dart` is exercised by integration tests.

#### Acceptance criteria
- [ ] Documented as intentional.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: none.

---

### Task 1.19 — Keep deprecated-API-free state as-is (reference)

**Source:** A1 finding "No deprecated API usage: no `withOpacity`, no `FlatButton`/`RaisedButton`, no `WillPopScope`; uses `withValues(alpha:)` throughout" · **Rating:** Good
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
No action needed; keep as reference.

#### Root cause
n/a

#### Files touched
- `lib/` — unchanged.

#### Implementation approach
No action needed; keep as reference. Consider adding a repo-level grep hook (pre-commit) that fails on `withOpacity(`, `FlatButton`, `RaisedButton`, `WillPopScope` to prevent regression. Not in scope for this task.

#### Test plan
- Regression: grep on each PR.

#### Acceptance criteria
- [ ] Documented as intentional.

#### Dependencies
- Blocks: none.
- Blocked by: none.
- External: none.

---

Note: Task 1.12, 1.15, 1.16, 1.17, 1.18, 1.19 are "Good"-rated findings captured per NO SKIPS rule; they exist as reference-only entries with no implementation work.
