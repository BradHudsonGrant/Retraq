# Epic 6 — Testing & Reliability Expansion

Source: review-2026-04-16.md §Agent 6

This epic expands the testing surface from a strong unit/widget base (445 tests) plus one integration smoke into a launch-ready reliability net. Every row of Agent 6's Detailed Findings Table has a corresponding task below — Solid-rated findings receive brief preservation entries so the pattern is not lost during future refactors.

Priority order: P0 (launch blockers) → P1 (v1 must-haves) → P2 (v1.1) → P3 (v2 / backlog preservation).

---

### Task 6.1 — Expand integration E2E suite from smoke to journey coverage

**Source:** A6 finding "Integration coverage — integration_test/app_test.dart (single test)" · **Rating:** Thin
**Priority:** P0 · **Effort:** XL · **Tier:** v1

#### Problem
`integration_test/app_test.dart` contains exactly one end-to-end smoke test. Every critical user journey — create/view/edit/delete entry, PIN setup & unlock, onboarding completion, export round-trip, biometric fallback — is unverified at the app-binary level. A schema migration, platform-channel change, or Material 3 upgrade can land green on unit tests while shipping a broken binary to TestFlight.

#### Root cause (what's untested and why that's risky)
- Unit/widget tests run against mocked Drift (in-memory) and mocked secure-storage channels; they cannot exercise the real SQLCipher open path, real FlutterSecureStorage, real permission dialogs, or real navigation lifecycle.
- Integration harness exists (`integration_test/` with driver) but was never extended past the initial smoke.
- Play Console pre-launch-report and TestFlight will find regressions after upload; CI cannot catch them today.

#### Files touched
- `integration_test/app_test.dart` — replace single smoke with grouped journey suites
- `integration_test/journeys/crud_flow_test.dart` — new
- `integration_test/journeys/pin_setup_flow_test.dart` — new
- `integration_test/journeys/onboarding_flow_test.dart` — new
- `integration_test/journeys/export_roundtrip_test.dart` — new
- `integration_test/journeys/biometric_fallback_test.dart` — new
- `integration_test/helpers/journey_helpers.dart` — shared finders, pump strategies, seeded DB
- `.github/workflows/ci.yml` — widen emulator job to run journey suite with `--dart-define=INTEGRATION_SUITE=journey`

#### Implementation approach
1. Stand up a shared `JourneyHarness` that nukes the app DB and secure-storage between tests, waits for first frame, then exposes a `tester` and `app` handle.
   ```dart
   class JourneyHarness {
     Future<void> freshLaunch(WidgetTester tester) async {
       await _wipeAppData();
       app.main();
       await tester.pumpAndSettle(const Duration(seconds: 3));
     }
   }
   ```
2. Named tests, one per journey:
   - `crud_flow_test.dart` → tests `create entry`, `view entry from week list`, `edit entry preserves mood`, `delete entry with typed gate`, `deleted entry removed from FTS search`
   - `pin_setup_flow_test.dart` → `enable PIN from settings`, `PIN required after cold start`, `wrong PIN triggers lockout`, `forgot PIN destructive wipe with confirmation`
   - `onboarding_flow_test.dart` → `age gate under 13 denies`, `age gate 13+ proceeds`, `consent page records version`, `skipping optional nudge still completes onboarding`
   - `export_roundtrip_test.dart` → `export → wipe → import restores entries with stable IDs`, `import dedup skips duplicates`, `malformed JSON rejected with user-visible error`
   - `biometric_fallback_test.dart` → mock `local_auth` channel to return `notAvailable`, assert PIN fallback surfaces; then return `success`, assert biometric bypass
3. Use `find.byKey(TestKeys.*)` exclusively (lint rule already enforced) so the suite survives refactors.
4. Add `testTimeout: 2m` in `dart_test.yaml` under the `integration` tag (see Task 6.22).

#### Coverage targets
- 14 named integration tests across 5 files
- First-run through delete-entry covered on both platforms' emulators
- Coverage delta: integration line count from ~30 to ~1,200 LOC; app-level coverage from <1% to ~25% (app/services/secure-storage real paths)

#### Acceptance criteria
- [ ] Tests pass locally and in CI (Android emulator API 34)
- [ ] Coverage floor raised on integration side (app_shell + main now exercised)
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.1

#### Dependencies
- Blocks Task 6.12 (integration tag split) before it can gate CI
- Blocked by nothing; can start immediately
- External: Play Console emulator time quota (CI already pays this)

---

### Task 6.2 — Add timezone/DST edge-case tests

**Source:** A6 finding "Timezone/DST edge cases — (none)" · **Rating:** Missing
**Priority:** P0 · **Effort:** L · **Tier:** v1

#### Problem
`date_helpers` and streak queries use `DateTime.now()` / `.toLocal()` without any DST or timezone coverage. Users who write at 01:30 local on a spring-forward night, or at 01:30 during fall-back (which happens twice), can silently lose or duplicate streak days. Quebec (EST/EDT), EU spring-forward, US fall-back, and NZDT (which crosses the calendar date line relative to UTC) are all unverified.

#### Root cause (what's untested and why that's risky)
- No test wraps calls in a fixed `Clock` or injects `TZDateTime`; all date logic uses the system clock in CI (always UTC on Linux runners).
- Streak queries rely on `DATE(createdAt, 'localtime')` SQLite, which silently uses UTC when `localtime` modifier is applied on a server-less environment.
- Regression would ship unnoticed and corrupt "longest streak" — a signature feature.

#### Files touched
- `test/utils/date_helpers_timezone_test.dart` — new
- `test/services/stats_service_timezone_test.dart` — new
- `test/services/entry_repository_timezone_test.dart` — new
- `test/helpers/fake_clock.dart` — new `Clock` facade + `TZDateTime` helper
- `lib/utils/date_helpers.dart` — add optional `Clock` parameter if currently hardcoded to `DateTime.now()` (test-enabling only)
- `pubspec.yaml` — add `timezone: ^0.9.3` dev dependency

#### Implementation approach
1. Scenario enumeration (each becomes a named `test(...)`):
   - `EU spring-forward`: 2026-03-29 02:00 Europe/Berlin → 03:00 jump. Entry at 01:59 and 03:01 must land on the same local date (2026-03-29) and count as one streak day.
   - `US fall-back`: 2026-11-01 02:00 America/New_York → 01:00 repeat. Two entries at "01:30 EDT" and "01:30 EST" must merge into 2026-11-01, not split into two days.
   - `NZDT midnight rollover`: 2026-04-05 23:30 Pacific/Auckland = 2026-04-05 10:30 UTC. Entry UTC storage must reconstruct as 2026-04-05 local, not 2026-04-04.
   - `Quebec EST (America/Toronto)`: entry at 2026-01-15 23:59 EST vs 2026-01-16 00:01 EST must split into two streak days; SQLite `localtime` must not regress to UTC.
   - `Samoa skip-a-day` (defensive): 2011-style date skip sanity — ensure our code doesn't crash on locations where a local date literally does not exist.
2. Skeleton:
   ```dart
   test('EU spring-forward: entries straddling 02:00 land on same local date', () {
     tz.initializeTimeZones();
     final berlin = tz.getLocation('Europe/Berlin');
     final before = tz.TZDateTime(berlin, 2026, 3, 29, 1, 59).toUtc();
     final after  = tz.TZDateTime(berlin, 2026, 3, 29, 3,  1).toUtc();
     expect(localDateKey(before, berlin), equals(localDateKey(after, berlin)));
   });
   ```
3. `StatsService` streak test builds a fixture of 7 entries seeded across DST boundary, asserts `getCurrentStreak() == 7` not 6 or 8.

#### Coverage targets
- 12 timezone tests (3 scenarios × 4 surfaces: date_helpers, entry_repository, stats_service, calendar_grid date-key)
- Streak math covered for 4 distinct IANA zones
- Coverage delta on `date_helpers.dart`: ~55% → ~90%

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] Coverage floor raised on `date_helpers.dart` to 90%+
- [ ] No flakiness in 10 consecutive CI runs (deterministic — no real `DateTime.now()`)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.2

#### Dependencies
- Blocks: none
- Blocked by: small refactor to allow `Clock` injection in `date_helpers.dart` if not already injected
- External: none

---

### Task 6.3 — Mock local_auth channel for biometric flow tests

**Source:** A6 finding "Biometric auth flows — (none)" · **Rating:** Missing
**Priority:** P0 · **Effort:** M · **Tier:** v1

#### Problem
The biometric unlock path — which is the primary login experience for users with PIN + biometric enabled — has zero automated coverage. `local_auth` is invoked through a platform channel; failing to mock it means no test can exercise success, cancellation, `notAvailable`, `lockedOut`, or `notEnrolled` branches.

#### Root cause (what's untested and why that's risky)
- No MethodChannel mock installed for `plugins.flutter.io/local_auth_android` or `local_auth_ios`.
- Branching logic in `pin_service` / unlock screen is uncovered — regressions in fallback will only surface on a physical device.
- A silent failure (e.g. `authenticate` returning `false` without throwing) could leave users locked out with no fallback surfaced.

#### Files touched
- `test/services/biometric_auth_test.dart` — new
- `test/helpers/local_auth_mock.dart` — new MethodChannel mock factory
- `test/screens/unlock_screen_biometric_test.dart` — new widget test driving unlock UI
- Possibly `lib/services/pin_service.dart` — wrap `LocalAuthentication()` in an injectable interface if not already

#### Implementation approach
1. Install MethodChannel mock:
   ```dart
   TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
     .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/local_auth'), (call) async {
       switch (call.method) {
         case 'getAvailableBiometrics': return <String>['face'];
         case 'authenticate': return scenario.authResult;
         case 'isDeviceSupported': return true;
       }
       return null;
     });
   ```
2. Named tests:
   - `biometric success → navigates to home`
   - `biometric cancelled by user → stays on unlock, PIN still available`
   - `biometric notAvailable → PIN fallback shown immediately`
   - `biometric lockedOut → toast + PIN fallback`
   - `biometric notEnrolled → settings-deep-link surfaced`
   - `PIN-fallback entry after biometric fail → unlock succeeds`
3. Test fixture: seeded PIN hash matching "1234" so the PIN fallback branch completes without stubbing verification.

#### Coverage targets
- 6 biometric branch tests
- `pin_service.dart` coverage from ~40% (sync paths only) to ~80%
- `unlock_screen.dart` coverage from widget-smoke to full branch

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] Coverage floor raised on `pin_service.dart` to 80%
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.3

#### Dependencies
- Blocks Task 6.1 biometric journey (6.1 uses integration; 6.3 adds unit-level branch coverage)
- Blocked by: none
- External: none

---

### Task 6.4 — Add concurrency and race condition tests

**Source:** A6 finding "Concurrency & races — (none)" · **Rating:** Missing
**Priority:** P0 · **Effort:** M · **Tier:** v1

#### Problem
Concurrent writes to `saveEntry`, failed-attempt counter increments under rapid PIN retry, and stream ordering during batched writes are untested. A user mashing the save button or a widget auto-save firing during an import can race with UI writes, producing double rows, split increments, or stream out-of-order emissions.

#### Root cause (what's untested and why that's risky)
- Drift provides `transaction()` but repository methods don't wrap multi-step writes uniformly; no test asserts atomicity.
- `LockoutController` increments failed-attempts with async reads — a 2-click rapid PIN submit could decrement twice or skip increment.
- Stream consumers (HomeScreen, StatsScreen) assume strictly monotonic emissions; a race could emit stale-then-fresh out of order.

#### Files touched
- `test/services/entry_repository_concurrency_test.dart` — new
- `test/services/lockout_controller_concurrency_test.dart` — new
- `test/services/stream_ordering_test.dart` — new

#### Implementation approach
1. Concurrent saves:
   ```dart
   test('100 concurrent saveEntry calls produce 100 distinct rows', () async {
     final futures = List.generate(100, (i) => repo.saveEntry(_fixture(i)));
     await Future.wait(futures);
     expect(await repo.countAll(), 100);
   });
   ```
2. Rapid failed-attempt: fire 10 `recordFailedAttempt()` concurrently, assert final count == 10 not <10.
3. Stream ordering: subscribe to `watchWeekEntriesFrom`, fire 20 interleaved insert/update/delete, buffer emissions, assert each emission reflects a monotonically advancing `max(createdAt)` — no out-of-order snapshots.
4. Fuzz variant: run each concurrency test 50× with `math.Random(seed)` jitter to shake out ordering dependencies.

#### Coverage targets
- 3 concurrency suites, ~15 test cases total
- Atomicity covered on `saveEntry`, `deleteEntry`, `recordFailedAttempt`, `watchWeekEntriesFrom`
- Coverage delta: repository layer from 68% → 78%

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] No flakiness in 10 consecutive CI runs (deterministic seeding)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.4

#### Dependencies
- Blocks: none
- Blocked by: none
- External: Drift in-memory DB (already in test_helpers)

---

### Task 6.5 — Extract dedicated pin_service_test.dart and cover async/isolate path

**Source:** A6 finding "pin_service.dart async/isolate path — (no dedicated file)" · **Rating:** Thin
**Priority:** P1 · **Effort:** M · **Tier:** v1

#### Problem
PIN tests currently live inside `test/services/database_service_test.dart` (lines 20-86, 558-659), mixing DB migration coverage with PIN crypto coverage. The async/isolate PBKDF2 path — used on Android 8+ to keep the main isolate responsive during the ~500ms key derivation — is not exercised; only the synchronous fallback is.

#### Root cause (what's untested and why that's risky)
- Async isolate code path silently falls back to sync in tests because `compute()` behaves differently under `flutter_test`.
- If `compute()` throws in production (isolate spawn failure on constrained devices), no test catches it.
- File coupling: any PIN test refactor forces touching migration tests.

#### Files touched
- `test/services/pin_service_test.dart` — new dedicated file
- `test/services/database_service_test.dart` — remove PIN-specific tests after migration
- `test/helpers/isolate_harness.dart` — new helper forcing real isolate execution via `IsolateNameServer`

#### Implementation approach
1. Move existing PIN tests verbatim, preserve `group('PIN v3 PBKDF2')`, `group('salt uniqueness')`, `group('malformed hash')`.
2. Add async-path tests:
   ```dart
   test('verifyPinAsync uses isolate and completes under 1s on test runner', () async {
     final sw = Stopwatch()..start();
     final ok = await pinService.verifyPinAsync('1234');
     sw.stop();
     expect(ok, isTrue);
     expect(sw.elapsedMilliseconds, lessThan(2000));
   });

   test('verifyPinAsync propagates errors from isolate', () async {
     await pinService.setPin('1234');
     await _corruptStoredHash();
     expect(() => pinService.verifyPinAsync('1234'), throwsA(isA<PinHashMalformedException>()));
   });
   ```
3. Add "isolate spawn failure" branch with a `debugIsolateSpawner` override that throws.

#### Coverage targets
- ~20 PIN-specific tests in dedicated file
- `pin_service.dart` coverage from ~40% to ~85%
- Async/isolate path explicitly covered (6 cases)

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] `database_service_test.dart` no longer contains PIN assertions (single responsibility)
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.5

#### Dependencies
- Blocks: Task 6.3 (biometric tests can share helpers)
- Blocked by: none
- External: none

---

### Task 6.6 — Add direct tests for entry_repository and settings_repository

**Source:** A6 finding "Repository direct tests — only user_repository_test.dart" · **Rating:** Thin
**Priority:** P1 · **Effort:** M · **Tier:** v1

#### Problem
Only `user_repository_test.dart` has direct repository coverage. `entry_repository` (the most hit-path code in the app) and `settings_repository` (singleton id=1 footgun) are only tested transitively through `database_service_test` and widget tests. Regressions in pure repository logic (parameter coercion, stream signature-caching, upsert vs insert semantics) surface as widget test failures with unhelpful stack traces.

#### Root cause (what's untested and why that's risky)
- Mixing concerns: widget tests fail for repository reasons, making triage slow.
- Repository signatures evolve; without dedicated tests, deprecated parameter paths rot silently.
- `settings_repository` hardcodes `id.equals(1)` — breaks under multi-user cloud sync. A direct test documents current behavior and catches unintended change.

#### Files touched
- `test/services/entry_repository_test.dart` — new
- `test/services/settings_repository_test.dart` — new
- `test/helpers/repository_harness.dart` — new in-memory Drift builder for repositories

#### Implementation approach
1. `entry_repository_test.dart` groups:
   - `saveEntry` upsert behavior (new vs existing id)
   - `watchEntriesForDate` emits seeded rows, emits new rows on insert, does not emit on unrelated writes
   - `watchMonthEntries` correctly boundaries a 28/29/30/31-day month including Feb leap year
   - `watchWeekEntriesFrom` respects ISO week start regardless of locale
   - `searchByText` covers FTS5 prefix tokens, Unicode tokens, empty query edge
   - `deleteEntry` cascades FTS rows via trigger (assert FTS row count)
   - `getTotalEntryCount` matches SQL COUNT(*) under various filters
2. `settings_repository_test.dart` groups:
   - `watchSettings()` emits current row, emits on update
   - Updating a single field preserves other fields (no clobber)
   - `id=1` singleton constraint explicitly asserted (will break if multi-user migration lands without update here)
3. Fixture: `RepositoryHarness.fresh()` returns `(db, entryRepo, settingsRepo)` with migrations run to latest schema v14.

#### Coverage targets
- 25 direct repository tests
- `entry_repository.dart` coverage from ~60% to ~85%
- `settings_repository.dart` coverage from ~50% to ~90%

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] Coverage floor raised: CI 45% → 50%
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.6

#### Dependencies
- Blocks: Task 6.12 (coverage gate raise)
- Blocked by: none
- External: none

---

### Task 6.7 — Add on-device streak SQL integration test

**Source:** A6 finding "Streak SQL on in-memory SQLite falls back to 0 — test/services/stats_service_test.dart:67-70" · **Rating:** Thin
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`getCurrentStreak` and `getLongestStreak` use SQLite's `ROW_NUMBER()` window function and `date(... , 'localtime')`. The in-memory SQLite used in `flutter_test` omits the `localtime` modifier's real semantics and silently falls back to 0, masking real bugs. The existing test at `stats_service_test.dart:67-70` literally asserts the fallback-to-0 behavior.

#### Root cause (what's untested and why that's risky)
- `sqlite3_flutter_libs` in test mode doesn't include timezone data; `localtime` becomes a no-op.
- Streak math ships to production without verification that the window function actually computes correct streaks.
- A regression (e.g. off-by-one on week boundaries) will only be caught post-release.

#### Files touched
- `integration_test/streak_sql_on_device_test.dart` — new integration test running on real Android/iOS SQLite
- `test/services/stats_service_test.dart` — update comment explaining why in-memory returns 0; add TODO pointer to on-device test

#### Implementation approach
1. Integration test seeds 14 entries across 2 weeks on the real device DB.
2. Asserts `getCurrentStreak() == 14`, `getLongestStreak() == 14`.
3. Seeds a gap (skip day 7), asserts `getCurrentStreak() == 7`, `getLongestStreak() == 7` (ties break deterministically).
4. Run in CI emulator job (piggyback on Task 6.1 emulator setup).

#### Coverage targets
- 4 on-device streak tests
- `stats_service.dart` streak functions covered by a real window-function execution path
- Coverage delta: negligible line-coverage, but branch-coverage of `localtime` semantics goes from 0% → 100%

#### Acceptance criteria
- [ ] Tests pass locally and in CI emulator
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.7

#### Dependencies
- Blocks: none
- Blocked by: Task 6.1 (emulator lane must be established)
- External: CI Android emulator

---

### Task 6.8 — Strengthen notification scheduling tests beyond message content

**Source:** A6 finding "Notification scheduling — test/services/notification_service_test.dart" · **Rating:** Thin
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`notification_service_test.dart` currently only verifies the notification body string. The actual scheduling behavior — time computation across DST, reschedule on boot, cancellation on disable, exact-alarm permission branches — is not tested. Nudge reliability is a differentiating feature and currently has no regression net.

#### Root cause (what's untested and why that's risky)
- `flutter_local_notifications` provides `zonedSchedule(...)` which is the primary API; the test mock doesn't intercept it, only message building.
- Android 14 `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` permission branches are uncovered.
- Reboot rescheduling via `RECEIVE_BOOT_COMPLETED` has no verification.

#### Files touched
- `test/services/notification_service_test.dart` — expand
- `test/helpers/flutter_local_notifications_mock.dart` — new mock installer capturing scheduled calls

#### Implementation approach
1. Mock plugin to capture a list of `ScheduledNotification { id, zonedTime, payload }`.
2. Named tests:
   - `scheduleDailyNudge(time=08:30) schedules next occurrence in user's tz`
   - `scheduleDailyNudge respects DST spring-forward — next fire skips 02:30 hour`
   - `disableNudges cancels all pending with zero residual`
   - `reschedule on boot reads saved settings and re-queues`
   - `exact-alarm permission denied falls back to inexact`

#### Coverage targets
- 8 notification tests (up from 2)
- `notification_service.dart` coverage from ~45% to ~80%

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.8

#### Dependencies
- Blocks: none
- Blocked by: Task 6.2 (shares fake clock)
- External: none

---

### Task 6.9 — Make export_service_test invoke real service instead of replicating JSON shape

**Source:** A6 finding "Export service file output — test/services/export_service_test.dart:56-80" · **Rating:** Thin
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`export_service_test.dart:56-80` builds the expected JSON blob by hand and compares against a second hand-built JSON blob. It never actually calls `ExportService.exportJson(...)` to produce the file. Any bug in the service is invisible to the test because the service isn't invoked.

#### Root cause (what's untested and why that's risky)
- Test was likely stubbed during early scaffolding and never completed.
- Export round-trip (export → wipe → import → diff) is untested end-to-end at unit level.
- Schema versioning (`schemaVersion: 1`) could regress to 0 silently.

#### Files touched
- `test/services/export_service_test.dart` — rewrite to invoke service
- `test/fixtures/export_roundtrip_fixture.dart` — new seeded-data fixture

#### Implementation approach
1. Named tests:
   - `exportJson writes file matching schema v1 — fields present: schemaVersion, exportedAt, entries, settings, consents`
   - `exportJson → importJson round-trip preserves all fields including createdAt ms precision`
   - `exportJson with 0 entries produces valid empty array not null`
   - `exportJson with 10k entries uses compute() isolate (measured by not blocking main isolate >50ms)`
   - `importJson dedups by (createdAt, mood, text) tuple — duplicate import yields 0 new rows`
   - `importJson rejects schemaVersion=99 with user-visible error message`
2. Use `MemoryFileSystem` from package:file to avoid real disk I/O.

#### Coverage targets
- 8 export tests invoking real service
- `export_service.dart` coverage from ~35% (content replication) to ~80% (real paths)

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] Coverage floor raised on export_service to 80%
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.9

#### Dependencies
- Blocks: Task 6.1 integration export round-trip
- Blocked by: none
- External: `package:file` (already transitively present)

---

### Task 6.10 — Add smoke tests for main, app_shell, splash, reconsent

**Source:** A6 finding "main, splash, app_shell, reconsent — mostly untested" · **Rating:** Thin
**Priority:** P1 · **Effort:** M · **Tier:** v1

#### Problem
`main.dart`, `app_shell.dart`, `splash_screen.dart`, and the reconsent flow have only incidental coverage via the single integration smoke. These are the first four frames a user sees; regressions here are user-visible immediately.

#### Root cause (what's untested and why that's risky)
- `main.dart` has branching for consent-not-recorded → reconsent, PIN-set → unlock, and first-launch → onboarding. All three paths uncovered.
- `app_shell` has IndexedStack + 4 tabs with AutomaticKeepAliveClientMixin; a refactor lazifying tabs (see Epic 8) must not regress current behavior.
- Splash screen visibility duration is tied to DB init; a long-running migration could show the splash indefinitely.

#### Files touched
- `test/app_main_branching_test.dart` — new
- `test/screens/app_shell_test.dart` — new
- `test/screens/splash_screen_test.dart` — new
- `test/screens/reconsent_flow_test.dart` — new

#### Implementation approach
1. `app_main_branching_test.dart`:
   - `first launch → onboarding shown`
   - `PIN set → unlock screen shown first`
   - `consent version bumped → reconsent shown before home`
2. `app_shell_test.dart`:
   - `4 tabs render, tap each, active tab highlighted`
   - `Home keeps state across tab switch` (AutomaticKeepAlive assertion)
   - `NavigationBar wrapped in RepaintBoundary` (regression for Epic 8 perf work)
3. `splash_screen_test.dart`:
   - `splash visible for at least one frame`
   - `splash dismisses after DB init completes`
4. `reconsent_flow_test.dart`:
   - `accept advances to home`
   - `decline routes to export-then-delete flow`

#### Coverage targets
- 12 tests across 4 files
- `main.dart` branching coverage 0% → 75%
- `app_shell.dart` coverage 30% → 80%
- `splash_screen.dart` coverage 0% → 80%

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] Coverage floor raised: CI 50% → 55%
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.10

#### Dependencies
- Blocks: none
- Blocked by: Task 6.6 (repository harness used to seed first-launch state)
- External: none

---

### Task 6.11 — Fill widget coverage gaps: mood_blob, mesh_background, glass_card, theme_card, week_day_list, weekly_trend_chart

**Source:** A6 finding "Widget coverage 42/~45 — Missing: mood_blob, mesh_background, glass_card, theme_card, week_day_list, weekly_trend_chart" · **Rating:** Solid
**Priority:** P1 · **Effort:** M · **Tier:** v1.1

#### Problem
Widget coverage is already strong (42 of ~45 widgets) but six widgets are untested: `mood_blob`, `mesh_background`, `glass_card`, `theme_card`, `week_day_list`, `weekly_trend_chart`. `week_day_list` and `weekly_trend_chart` are high-traffic UI and both are candidates for visual regression.

#### Root cause (what's untested and why that's risky)
- Visual-only widgets often skipped because they "just render"; but `week_day_list` has Today pill logic, `weekly_trend_chart` computes bar heights from mood data, `mood_blob` animates via AppMotion.aware — all have real logic.

#### Files touched
- `test/widgets/atoms/mood_blob_test.dart` — new
- `test/widgets/molecules/mesh_background_test.dart` — new
- `test/widgets/molecules/glass_card_test.dart` — new
- `test/widgets/molecules/theme_card_test.dart` — new
- `test/widgets/organisms/week_day_list_test.dart` — new
- `test/widgets/organisms/weekly_trend_chart_test.dart` — new

#### Implementation approach
1. `mood_blob_test.dart`: renders for moods 1-5, asserts distinct color per mood, reduced-motion path does not animate.
2. `mesh_background_test.dart`: renders in light and dark theme, asserts gradient stops differ.
3. `glass_card_test.dart`: applies BackdropFilter only when MediaQuery disableAnimations false.
4. `theme_card_test.dart`: tap calls onTap, selected state shows check mark, disabled state is not tappable.
5. `week_day_list_test.dart`: today's date shows "Today" pill, empty day shows "No entries" placeholder, backdated entries show date meta.
6. `weekly_trend_chart_test.dart`: bar height proportional to mood value, seven bars always rendered, missing days show zero-height bar.

#### Coverage targets
- 18 widget tests
- Widget layer coverage 42/45 → 45/45
- Coverage delta: ~3% overall line coverage

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] Coverage floor raised: CI 55% → 58%
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.11

#### Dependencies
- Blocks: Task 6.17 (goldens need widget tests first)
- Blocked by: none
- External: none

---

### Task 6.12 — Split dart_test.yaml into fast unit vs slow integration tags

**Source:** A6 finding "dart_test.yaml integration tag empty — dart_test.yaml:1-6" · **Rating:** Thin
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`dart_test.yaml` defines an `integration` tag but it's empty — no timeout, no exclusion, no platform filter. CI runs unit and widget tests together, and cannot separately gate integration. The new journey suite from Task 6.1 will 10× CI runtime unless tagged and lane-split.

#### Root cause (what's untested and why that's risky)
- Developers running `flutter test` locally pick up all tests including slow ones.
- PR CI lane can't skip integration without an explicit `--exclude-tags`.

#### Files touched
- `dart_test.yaml` — populate `integration` tag config
- `test/helpers/tagged_test.dart` — thin wrapper re-exporting `testWidgets` with default integration tag for journey files
- `.github/workflows/ci.yml` — split unit lane (`--exclude-tags integration`) from integration lane

#### Implementation approach
```yaml
# dart_test.yaml
tags:
  integration:
    timeout: 2m
    retry: 1
  slow:
    timeout: 1m
presets:
  ci_unit:
    exclude_tags: "integration"
  ci_integration:
    tags: "integration"
```
1. Journey files opt in with `@Tags(['integration'])` at top.
2. CI unit lane runs `flutter test --exclude-tags integration --coverage`.
3. Emulator lane runs `flutter test integration_test/` separately.

#### Coverage targets
- No direct coverage delta — infrastructure only
- CI runtime reduction on PR unit lane: ~30% (skip 14 integration tests)

#### Acceptance criteria
- [ ] Unit lane passes in under 3 minutes in CI
- [ ] Integration lane runs on emulator without affecting unit-lane runtime
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.12

#### Dependencies
- Blocks: Task 6.1 CI integration
- Blocked by: none
- External: none

---

### Task 6.13 — Align coverage thresholds between CI floor and Codecov targets

**Source:** A6 finding "Coverage threshold — ci.yml:58; codecov.yml" · **Rating:** Thin
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
CI enforces a 45% floor; `codecov.yml` targets 60% project / 70% patch. The delta means PRs pass CI while Codecov comments label them as failing coverage. Developers ignore the Codecov bot because it's always red; the gate effectively doesn't exist.

#### Root cause (what's untested and why that's risky)
- Threshold drift happens when targets are bumped in one place and forgotten in another.
- Release workflow uses 70% gate — creates tag-time surprise failures.

#### Files touched
- `.github/workflows/ci.yml` — bump floor from 45 → aligned with codecov
- `codecov.yml` — keep targets, tighten thresholds section
- `docs/contributing.md` if present — document tier rules

#### Implementation approach
1. After Tasks 6.1, 6.3-6.11 land, measure new floor. Realistically should reach 58-62%.
2. Set tiered gates:
   - PR floor: 55% (must not regress)
   - Patch target: 70% (Codecov only, soft)
   - Release floor: 65% (hard gate on `release.yml`)
3. Add `.github/workflows/ci.yml` step that prints current coverage and highlights delta from previous main.

#### Coverage targets
- Infrastructure change; depends on upstream tasks completing
- Eventual alignment: CI 55% / Codecov 70% / Release 65%

#### Acceptance criteria
- [ ] CI coverage gate raised from 45% to at least 55%
- [ ] Release gate raised from 70% to match codecov project target
- [ ] No flakiness — gate change is deterministic
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.13

#### Dependencies
- Blocks: none (final step after upstream expansion)
- Blocked by: Tasks 6.1, 6.3-6.11 (need coverage gains first)
- External: Codecov config

---

### Task 6.14 — Preserve PIN v3 PBKDF2 / salt uniqueness / malformed-hash coverage during extraction

**Source:** A6 finding "PIN v3 PBKDF2, salt uniqueness, malformed-hash — test/services/database_service_test.dart:20-86,558-659" · **Rating:** Solid
**Priority:** P2 · **Effort:** XS · **Tier:** v1

#### Problem
This finding is Solid — recommended action is extraction (Task 6.5). This entry exists to ensure the existing coverage is carried verbatim into the new `pin_service_test.dart` and not accidentally dropped.

#### Root cause (what's untested and why that's risky)
Nothing new to test; risk is regression during the file-move in Task 6.5.

#### Files touched
- `test/services/pin_service_test.dart` — destination (created in Task 6.5)

#### Implementation approach
1. During Task 6.5, use `git mv` semantics: copy verbatim test bodies, confirm pass before deleting originals.
2. Add a checklist item: verify all three groups (`PBKDF2`, `salt uniqueness`, `malformed hash`) present in new file with identical assertion counts.

#### Coverage targets
- Zero delta — preservation task

#### Acceptance criteria
- [ ] Count of PIN-related test cases unchanged pre/post extraction
- [ ] All assertions identical (diff is pure file-move)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.14

#### Dependencies
- Folded into Task 6.5 execution
- Blocked by: none
- External: none

---

### Task 6.15 — Extend lockout_controller tests with post-timer expiry

**Source:** A6 finding "Lockout persistence + clock-rewind — test/services/lockout_controller_test.dart:140-181" · **Rating:** Solid
**Priority:** P2 · **Effort:** XS · **Tier:** v1

#### Problem
Existing coverage verifies lockout persists across app restart and cannot be bypassed by rewinding the clock. Missing: verification that lockout automatically expires after the timer legitimately elapses forward.

#### Root cause (what's untested and why that's risky)
Symmetry: reverse-clock-attack is covered, forward-legitimate-elapsed is not. A bug where the timer check uses `<` instead of `<=` could leave users permanently locked out one millisecond past the boundary.

#### Files touched
- `test/services/lockout_controller_test.dart` — add cases

#### Implementation approach
```dart
test('lockout expires exactly at timer elapsed', () {
  final clock = FakeClock(start: _now);
  final ctrl = LockoutController(clock: clock);
  ctrl.recordFailedAttempt(); // ... × 5
  expect(ctrl.isLockedOut, isTrue);
  clock.advance(const Duration(minutes: 5));
  expect(ctrl.isLockedOut, isFalse);
});

test('lockout expires exactly at timer-1ms is still locked', () {
  clock.advance(const Duration(minutes: 5) - const Duration(milliseconds: 1));
  expect(ctrl.isLockedOut, isTrue);
});
```

#### Coverage targets
- 2 additional test cases
- `lockout_controller.dart` branch coverage on expiry: partial → full

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.15

#### Dependencies
- Blocks: none
- Blocked by: Task 6.2 fake-clock helper
- External: none

---

### Task 6.16 — Add v13→v14 direct migration path test

**Source:** A6 finding "Migration chain v3-v14 raw SQL — test/services/migration_strategy_test.dart" · **Rating:** Solid
**Priority:** P2 · **Effort:** XS · **Tier:** v1

#### Problem
Chain coverage v3→v14 exists. Missing: direct v13→v14 single-hop test, which is the path a user who installed last week hits on today's update.

#### Root cause (what's untested and why that's risky)
Chain tests exercise the composite sequence; a bug in the final hop could be masked by earlier migrations preparing state the v14 migration accidentally relies on.

#### Files touched
- `test/services/migration_strategy_test.dart` — add one test

#### Implementation approach
```dart
test('direct v13→v14 migration', () async {
  final db = await openV13Seed();
  await MigrationStrategy.upgrade(db, from: 13, to: 14);
  expect(await db.schemaVersion(), 14);
  // Assert v14-specific columns/triggers exist
  expect(await db.hasColumn('journal', 'updatedAt'), isTrue);
});
```

#### Coverage targets
- 1 additional migration test
- Migration strategy coverage unchanged (already solid); branch for direct-hop added

#### Acceptance criteria
- [ ] Test passes locally and in CI
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.16

#### Dependencies
- Blocks: none
- Blocked by: none
- External: none

---

### Task 6.17 — Preserve column-drop regression coverage

**Source:** A6 finding "Migration column-drop regression — test/services/migration_data_loss_test.dart" · **Rating:** Solid
**Priority:** P2 · **Effort:** XS · **Tier:** v1

#### Problem
Finding is Solid; recommendation is "Keep." Preservation entry only — no new tests. Included so any future consolidation of migration tests explicitly flags this file as must-retain.

#### Root cause (what's untested and why that's risky)
Nothing to add; risk is accidental deletion during cleanup.

#### Files touched
- `test/services/migration_data_loss_test.dart` — add DO-NOT-DELETE header comment citing review date

#### Implementation approach
1. Prepend file with:
   ```dart
   // Preserved per review-2026-04-16 Agent 6 — column-drop regression suite.
   // Protects against silent data loss during Drift schema migrations.
   // Do not delete or consolidate without review.
   ```

#### Coverage targets
- Zero delta

#### Acceptance criteria
- [ ] Header comment added
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.17

#### Dependencies
- Blocks: none
- Blocked by: none
- External: none

---

### Task 6.18 — Preserve boundary/edge DB test coverage

**Source:** A6 finding "Boundary/edge DB data (10K char, CJK, FK violation, 0/23 cutoff) — database_service_test.dart:294-352" · **Rating:** Solid
**Priority:** P2 · **Effort:** XS · **Tier:** v1

#### Problem
Existing boundary coverage (very long text, CJK, FK violations, 0/23 day-cutoff) is strong. Preservation entry ensuring this block is not lost when Task 6.5 extracts PIN tests from the same file.

#### Root cause (what's untested and why that's risky)
Split file refactors often drop tangential blocks accidentally.

#### Files touched
- `test/services/database_service_test.dart` — add preservation header comment

#### Implementation approach
1. Bracket lines 294-352 with preservation comments:
   ```dart
   // BEGIN preserve per review-2026-04-16 Agent 6 (boundary/edge DB data).
   // 10K-char body, CJK unicode, FK violation surfacing, 0/23-hour cutoff.
   ```
2. Ensure no overlap with Task 6.5 extraction region.

#### Coverage targets
- Zero delta

#### Acceptance criteria
- [ ] Preservation comments present
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.18

#### Dependencies
- Blocks: Task 6.5 (execute 6.18 first so 6.5 sees the markers)
- Blocked by: none
- External: none

---

### Task 6.19 — Preserve test_helpers, mocking strategy, TestKeys, flakiness-guard patterns

**Source:** A6 findings "Test helpers — test/test_helpers.dart:1-158", "Mocking strategy — secure_storage MethodChannel mock; real SQLite", "TestKeys pattern — lib/utils/test_keys.dart", "Flakiness guards — test_helpers.dart:57-67" · **Rating:** Solid (all four)
**Priority:** P2 · **Effort:** S · **Tier:** v1

#### Problem
Four Solid findings recommending "Keep": `test_helpers.dart` wrapWidget/flushDriftTimers, secure-storage MethodChannel mock paired with real SQLite (catches migration/FK issues mocks would miss), TestKeys pattern for refactor-resilience, and flakiness guards (animation-reduced + Drift timer flush). Need a documented pattern reference so new contributors don't reinvent.

#### Root cause (what's untested and why that's risky)
Patterns are good but undocumented. Future tests may bypass them (e.g., stubbing SQLite instead of using real) and introduce flakiness or false passes.

#### Files touched
- `test/test_helpers.dart` — add Dartdoc comments on `wrapWidget`, `flushDriftTimers`
- `test/README.md` — new (yes, new .md file — documentation of existing infra, not speculative) — OR — if rule "never create .md unless requested" applies strictly, fold into `test_helpers.dart` header Dartdoc instead

#### Implementation approach
1. Given the user instruction "NEVER create documentation files (*.md) or README files unless explicitly required", prefer Dartdoc-in-source approach:
   ```dart
   /// Standard test bootstrap. Use in every widget test.
   ///
   /// - Wraps child in MaterialApp with l10n + theme
   /// - Installs animation-reduced MediaQuery to avoid timing-dependent flakes
   /// - Returns after a single pumpAndSettle so finders work immediately
   ///
   /// Do not bypass. See review-2026-04-16 Agent 6 for rationale.
   Future<void> wrapWidget(WidgetTester tester, Widget child) async { ... }
   ```
2. Same treatment for `flushDriftTimers` (explains why 400ms), `test_keys.dart` class-level Dartdoc, and the secure-storage mock factory.

#### Coverage targets
- Zero direct coverage delta; enables preservation

#### Acceptance criteria
- [ ] Dartdoc present on all four patterns
- [ ] Analyzer passes with `package_api_docs` lint if enabled
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.19

#### Dependencies
- Blocks: none
- Blocked by: none
- External: none

---

### Task 6.20 — Preserve CI/CD readiness posture and verify on every major workflow change

**Source:** A6 finding "CI/CD readiness — .github/workflows/ci.yml" · **Rating:** Solid
**Priority:** P2 · **Effort:** XS · **Tier:** v1

#### Problem
CI config (Ubuntu, Flutter 3.41.6 SHA-pinned, 45% coverage floor, Android emulator) is rated Solid. Task 6.12 and 6.13 modify CI — this preservation entry ensures the pinning, emulator lane, and SHA discipline survive those changes.

#### Root cause (what's untested and why that's risky)
CI churn often loses SHA pinning. Supply-chain attacks via unpinned actions are a known risk vector.

#### Files touched
- `.github/workflows/ci.yml` — audit step added to new `ci-audit` job that greps for `@v1`/`@v2` unpinned refs and fails build

#### Implementation approach
1. Add audit job:
   ```yaml
   ci-audit:
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@<sha>
       - name: Verify SHA pinning
         run: |
           if grep -rE '@v[0-9]+\s*$' .github/workflows/; then
             echo "Unpinned GitHub Action detected"
             exit 1
           fi
   ```

#### Coverage targets
- Supply-chain pin discipline preserved

#### Acceptance criteria
- [ ] `ci-audit` job passes on all current workflows
- [ ] Fails intentionally when a test commit unpins one action
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.20

#### Dependencies
- Blocks: none
- Blocked by: none
- External: none

---

### Task 6.21 — Add golden / visual regression tests for 5-10 key widgets

**Source:** A6 finding "Golden / visual regression — (none)" · **Rating:** Missing
**Priority:** P2 · **Effort:** L · **Tier:** v2

#### Problem
No golden tests exist. Theme refactors, font bumps, or Material 3 library upgrades ship visual regressions invisibly. Five to ten key widgets would catch 95% of visual regressions at negligible CI cost.

#### Root cause (what's untested and why that's risky)
- Visual design is a brand asset (per Agent 13); regressions degrade premium perception.
- Goldens are the only scalable way to catch theme-level regressions without eyeballing screenshots.

#### Files touched
- `test/goldens/retraq_button_test.dart` — new
- `test/goldens/mood_blob_test.dart` — new
- `test/goldens/calendar_grid_test.dart` — new
- `test/goldens/entry_card_test.dart` — new
- `test/goldens/pin_setup_sheet_test.dart` — new
- `test/goldens/glass_card_test.dart` — new
- `test/goldens/weekly_trend_chart_test.dart` — new
- `test/goldens/page_indicator_dots_test.dart` — new
- `test/goldens/nudge_card_test.dart` — new
- `test/goldens/week_day_list_test.dart` — new
- `test/goldens/golden_harness.dart` — new shared loader, font setup
- `test/goldens/**/*.png` — generated artifacts (committed)
- `pubspec.yaml` — add `golden_toolkit: ^0.15.0` dev dep

#### Implementation approach
1. Use `golden_toolkit` to enforce consistent font loading across CI runners.
2. For each widget, render light + dark variants at three textScaleFactor values (1.0, 1.3, 2.0).
3. `RetraqButton` golden matrix: 4 variants × 2 themes × 3 scales = 24 goldens.
4. CI lane: goldens updated only via `flutter test --update-goldens` run by developer locally, committed, then verified in CI.
5. Golden failure in CI surfaces diff artifact attached to workflow run.

#### Coverage targets
- 10 widgets covered with ~80 golden images total
- Visual regression detection: 0 → effective

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] CI runs in under 4 minutes including goldens
- [ ] No flakiness in 10 consecutive CI runs (font loading deterministic)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.21

#### Dependencies
- Blocks: none
- Blocked by: Task 6.11 (widgets must have basic tests first)
- External: `golden_toolkit` package

---

### Task 6.22 — Add accessibility tests using SemanticsTester and 48dp touch-target verification

**Source:** A6 finding "Accessibility tests — 3 incidental matches" · **Rating:** Missing
**Priority:** P2 · **Effort:** M · **Tier:** v2

#### Problem
Only 3 incidental accessibility assertions exist. WCAG 2.1 AA is a stated commitment (Agent 7). Without `SemanticsTester` coverage, screen-reader regressions ship unnoticed. Touch-target sizes (48dp min) are similarly unverified.

#### Root cause (what's untested and why that's risky)
- EU Accessibility Act in effect since 2025-06-28; penalties up to €100K / 4% revenue.
- Screen reader UX degradation is invisible to sighted developers.

#### Files touched
- `test/a11y/semantics_test.dart` — new
- `test/a11y/touch_target_test.dart` — new
- `test/a11y/a11y_harness.dart` — new helper wrapping `SemanticsTester`

#### Implementation approach
1. Per-screen semantics snapshot:
   ```dart
   testWidgets('HomeScreen exposes mood buttons as toggleable', (tester) async {
     await tester.pumpWidget(wrapWidget(const HomeScreen()));
     final semantics = SemanticsTester(tester);
     expect(
       semantics,
       includesNodeWith(label: 'Mood 3 of 5', isInMutuallyExclusiveGroup: true),
     );
   });
   ```
2. Touch-target enforcement test for every interactive atom:
   ```dart
   testWidgets('all buttons meet 48dp minimum', (tester) async {
     // For each variant of RetraqButton, PadButton, EntryActionMenu:
     final size = tester.getSize(find.byType(RetraqButton));
     expect(size.width, greaterThanOrEqualTo(48));
     expect(size.height, greaterThanOrEqualTo(48));
   });
   ```
3. Cover the WCAG-failing widgets surfaced by Agent 7 (PageIndicatorDots, EntryActionMenu, MoodSelector semantics).

#### Coverage targets
- ~20 a11y tests across 6 screens and 10 widgets
- Explicit regression net for 48dp and Semantics

#### Acceptance criteria
- [ ] Tests pass locally and in CI
- [ ] No flakiness in 10 consecutive CI runs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.22

#### Dependencies
- Blocks: none
- Blocked by: Task 6.11 (widgets covered)
- External: none

---

### Task 6.23 — Add fuzz / property tests via glados for PIN, date, search

**Source:** A6 finding "Fuzz / property tests — (none)" · **Rating:** Missing
**Priority:** P3 · **Effort:** M · **Tier:** v2

#### Problem
No property-based tests. Edge cases in PIN hashing (byte-range collisions), date helpers (year boundaries, leap year), and FTS5 tokenizer (Unicode, emoji, mixed RTL) are caught only by example-based tests the developer thought to write.

#### Root cause (what's untested and why that's risky)
- Security-critical code (PIN) benefits especially from shrinking counterexamples.
- FTS5 search is a core feature; malformed queries could crash the query layer.

#### Files touched
- `test/fuzz/pin_property_test.dart` — new
- `test/fuzz/date_property_test.dart` — new
- `test/fuzz/search_property_test.dart` — new
- `pubspec.yaml` — add `glados: ^1.1.5` dev dep

#### Implementation approach
1. PIN property: for any byte string of length 4-12, `hash(x) == hash(x)` and `hash(x) != hash(y)` with high probability; no hash result contains `\0` mid-string.
2. Date property: `localDateKey(t) == localDateKey(t + 1ms)` for t not near midnight; `localDateKey(t)` changes exactly at 00:00 local.
3. Search property: for any Unicode string, `searchByText(s)` does not throw and returns a subset of `findAll()` for literal matches.

#### Coverage targets
- 3 property suites, effectively hundreds of generated cases per CI run
- Edge coverage on PIN hash, date key, FTS tokenization

#### Acceptance criteria
- [ ] Tests pass locally and in CI with `glados` seed fixed for reproducibility
- [ ] No flakiness in 10 consecutive CI runs (fixed seed)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.23

#### Dependencies
- Blocks: none
- Blocked by: Task 6.5 (PIN extraction), Task 6.2 (date helpers under test)
- External: `glados` package

---

### Task 6.24 — Add performance benchmarks for large-entry load and 365-day calendar

**Source:** A6 finding "Performance benchmarks — (none)" · **Rating:** Missing
**Priority:** P3 · **Effort:** M · **Tier:** v2

#### Problem
No performance benchmarks. Agent 8's analysis predicts the app handles 10k+ entries, but this is unverified. MonthView / SearchView virtualization regressions (flagged Bottleneck by Agent 8) would silently degrade scrolling FPS.

#### Root cause (what's untested and why that's risky)
- Without baseline numbers, PRs that subtly regress (e.g. removing `const`, wrapping virtualized list) cannot be flagged.
- "It felt fast on my Pixel" is not a regression gate.

#### Files touched
- `integration_test/perf/large_entry_load_test.dart` — new
- `integration_test/perf/calendar_365_day_scroll_test.dart` — new
- `integration_test/perf/perf_harness.dart` — shared `FrameTimingSummarizer`

#### Implementation approach
1. Large-entry load: seed 10,000 entries, launch app, measure time to first frame on HomeScreen.
   ```dart
   testWidgets('cold start with 10k entries < 800ms', (tester) async {
     await seed10kEntries();
     await binding.traceAction(() async {
       app.main();
       await tester.pumpAndSettle();
     }, reportKey: 'cold_start_10k');
     final summary = await binding.reportData!;
     expect(summary['cold_start_10k']['worst_frame_ms'], lessThan(16));
   });
   ```
2. Calendar 365-day scroll: render full year calendar, fling-scroll from January to December, assert 95th-percentile frame build time < 16ms.
3. Save to `build/perf_baselines/` and fail CI if regression > 15% vs committed baseline.

#### Coverage targets
- 2 performance benchmarks with committed baselines
- Regression gate on cold-start and calendar scroll

#### Acceptance criteria
- [ ] Tests pass locally and in CI emulator
- [ ] Baseline committed; regression threshold documented in file header
- [ ] No flakiness in 10 consecutive CI runs (median over 5 runs used for comparison)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.24

#### Dependencies
- Blocks: none
- Blocked by: Task 6.1 (integration lane established)
- External: CI emulator with stable hardware profile

---

### Task 6.25 — Extend notification_service / export_service / stats_service thin tests (umbrella preservation)

**Source:** A6 bottom-line umbrella guidance covering all Thin-rated service tests
**Priority:** P3 · **Effort:** S · **Tier:** backlog

#### Problem
A6's bottom line notes the gap between "strong unit/widget" and "shallow E2E." Tasks 6.7, 6.8, 6.9 each address one thin service; this entry captures any residual "thin" tests not otherwise covered — currently none, but the entry preserves the pattern so future thin-rated findings from the next audit attach here.

#### Root cause (what's untested and why that's risky)
Placeholder for continuous test-expansion discipline. No immediate risk.

#### Files touched
- None this epic; backlog slot for next audit's attach point

#### Implementation approach
1. When the next audit flags a new thin-rated service test, it lands here rather than growing a fresh task.
2. Acceptance: no code change this epic; re-evaluate after 2026-07-01 audit.

#### Coverage targets
- None this epic

#### Acceptance criteria
- [ ] Entry retained in backlog
- [ ] Reviewed and either closed or repurposed at next audit checkpoint

#### Dependencies
- Blocks: none
- Blocked by: next audit
- External: none

---

### Task 6.26 — Codify "always use wrapWidget + flushDriftTimers" via custom lint

**Source:** A6 finding "Flakiness guards — test_helpers.dart:57-67" · **Rating:** Solid
**Priority:** P3 · **Effort:** S · **Tier:** backlog

#### Problem
Flakiness guards (animation-reduced MediaQuery, Drift timer flush) are strong but rely on developer discipline. A new contributor writing `await tester.pumpWidget(child)` directly bypasses both.

#### Root cause (what's untested and why that's risky)
- Pattern preservation depends on reviewers catching it manually.
- Flakiness returns as soon as one contributor bypasses the helper.

#### Files touched
- `tool/lint/require_wrap_widget.dart` — new custom analyzer plugin (optional; skip if too heavy)
- Alternative: `analysis_options.yaml` — add regex-based grep pre-commit hook forbidding `tester.pumpWidget(` outside `test/test_helpers.dart`

#### Implementation approach
1. Lightweight: pre-commit hook or CI step:
   ```bash
   if git diff --name-only main...HEAD | xargs -I{} grep -lE 'tester\.pumpWidget\(' {} \
     | grep -v 'test_helpers.dart$'; then
     echo "Use wrapWidget(tester, child) instead of tester.pumpWidget"
     exit 1
   fi
   ```
2. Document exception via `// ignore: direct_pump` inline comment if ever needed.

#### Coverage targets
- Infrastructure; preserves existing flakiness guarantees

#### Acceptance criteria
- [ ] Lint/hook catches a test-case bypass intentionally introduced in a PR
- [ ] No false positives on existing tests
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `test:` prefix referencing Task 6.26

#### Dependencies
- Blocks: none
- Blocked by: none
- External: none

---

## Summary

- **Total tasks:** 26 (one per row of Agent 6's Detailed Findings Table)
- **Ordering:** Priority-first, then tier, then effort
- **Source coverage:** Every finding — Solid, Thin, and Missing — has a corresponding entry (Solid findings use brief preservation entries; Thin/Missing have full-depth plans)
