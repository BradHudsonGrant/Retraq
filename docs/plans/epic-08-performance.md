# Epic 8 — Performance & Technical Scalability

Source: review-2026-04-16.md §Agent 8

This epic covers the 20 findings in the Agent 8 Detailed Findings Table. Findings are reordered by priority: Bottleneck (virtualization) first as v1 launch blocker; Bottleneck (future) next for cloud-sync / multi-user schema work (v2, cross-referenced with Part III); Watch items for v1.1 polish; Optimal items as brief reference entries (no-op).

Total tasks: 20
Priority counts: P0=1 · P1=4 · P2=9 · P3=6
Tier counts: v1=1 · v1.1=9 · v2=3 · no-op=7

---

### Task 8.1 — Remove shrinkWrap/NeverScrollable from MonthView and SearchView to restore virtualization

**Source:** A8 finding "`SliverList.builder` wrapped in `shrinkWrap:true` + NeverScrollableScrollPhysics defeats virtualization" · **Rating:** Bottleneck
**Priority:** P0 · **Effort:** M · **Tier:** v1

#### Problem
`MonthView` and `SearchView` use `SliverList.builder` inside `CustomScrollView(shrinkWrap: true, physics: NeverScrollableScrollPhysics)` inside a parent `SingleChildScrollView`. The combination forces layout of every child up-front and throws away the sliver's lazy build. On a 2-year / 700+ entry account, frame builds balloon and scroll jank appears.

#### Root cause
Nested scrollables with `shrinkWrap:true` collapse the viewport-based viewport math Flutter needs for virtualization. Every sliver item is built eagerly because the parent `SingleChildScrollView` has unbounded height and the inner `CustomScrollView` is told not to scroll.

#### Files touched
- `lib/screens/recap/month_view.dart:196-229` — swap nested CustomScrollView for a single real scroll surface
- `lib/screens/recap/search_view.dart:140-148` — same pattern
- `lib/screens/recap_screen.dart` — verify parent layout no longer wraps the view in `SingleChildScrollView`
- `test/screens/recap/month_view_test.dart` (new) — widget test that asserts lazy build (item builder not called for off-screen indices)

#### Implementation approach
1. In `MonthView.build`:
   - Delete the outer `SingleChildScrollView` and the inner `CustomScrollView(shrinkWrap: true, physics: NeverScrollableScrollPhysics())`.
   - Replace with a single `CustomScrollView(slivers: [...])` where header widgets become `SliverToBoxAdapter` and the list becomes `SliverList.builder` at the root.
   - Widget-tree diff (illustrative):
     ```
     - SingleChildScrollView(
     -   child: Column(children: [header, CustomScrollView(shrinkWrap:true, physics: Never..., slivers:[SliverList.builder(...)])])
     - )
     + CustomScrollView(slivers: [
     +   SliverToBoxAdapter(child: header),
     +   SliverList.builder(itemBuilder: ..., itemCount: ...),
     + ])
     ```
2. Apply identical transformation in `SearchView` (slivers: search-bar adapter, filter-chips adapter, `SliverList.builder` for results).
3. Audit callers — if parent wraps `MonthView` in a `SingleChildScrollView` or `Column` with `Expanded`, ensure the new `CustomScrollView` is given bounded height (use `Expanded` or `Flexible`).
4. Verify `RepaintBoundary` wrappers on list tiles remain; keep `itemExtent`/`prototypeItem` if known to help the sliver fast-path.

#### Benchmark plan
- **Before/after metric**: frames-per-second during a 200-entry scroll using `flutter run --profile --trace-skia` + DevTools timeline; count item-builder invocations via a counter injected into `itemBuilder`.
- **Measurement method**: Scripted widget-test that wires 1000 fake entries into `MonthView` and asserts `buildCount < 30` (viewport-sized) instead of `== 1000`.
- Record the 95th-percentile frame build time in the commit message.

#### Test plan
- New widget test `test/screens/recap/month_view_virtualization_test.dart` — seed 500 entries, scroll to index 0, assert itemBuilder called ≤ 40 times.
- Same test for `search_view_virtualization_test.dart`.
- Full `flutter test` regression to confirm no behavior change (taps, date-header sticky, empty state).
- Manual: open on device with 700 real entries — scroll feels smooth, no jank.

#### Acceptance criteria
- [ ] Before/after frame-build count and FPS measured and improvement documented in commit
- [ ] New virtualization tests pass for both views
- [ ] No correctness regression in `flutter test`
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `perf:` prefix referencing Task 8.1

#### Dependencies
- Blocks: any "all entries" view (long-tail list) and future cloud-synced paging.
- Blocked by: none.

---

### Task 8.2 — Add `userId` filtering + `idx_journal_user_date` index to all entry queries

**Source:** A8 finding "Entry queries never filter by `userId`; no index on userId" · **Rating:** Bottleneck (future)
**Priority:** P1 · **Effort:** L · **Tier:** v2 (cross-reference Part III cloud sync)

#### Problem
`journal_entries` has a `userId` FK with ON DELETE CASCADE, but every watch query in `EntryRepository` ignores it. The instant a second user (family sharing, Retraq Care) or cloud-sync account lands, Alice's queries will return Bob's entries.

#### Root cause
Queries were written for the single-user invariant. No `WHERE userId = ?` clause and no composite index to make it selective.

#### Files touched
- `lib/services/database_service.dart:29-43` — add Drift column + index DDL
- `lib/services/entry_repository.dart:99-112,207-233,332-345,272-294,299-394,409-465` — add userId WHERE to every query and watcher
- `lib/services/migration_strategy.dart` — bump schema version, write migration
- `lib/services/user_repository.dart` — expose `currentUserId` stream
- `test/services/entry_repository_multiuser_test.dart` (new)

#### Implementation approach
1. **Drift table change** (`database_service.dart`):
   ```dart
   class JournalEntries extends Table {
     IntColumn get userId => integer().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
     // ...existing columns
   }
   // Index added via custom statement:
   // CREATE INDEX IF NOT EXISTS idx_journal_user_date ON journal_entries(userId, date DESC);
   ```
2. **Schema version bump**: `schemaVersion` from N → N+1 in `AppDatabase`.
3. **Migration sketch** (`migration_strategy.dart`):
   ```dart
   await m.customStatement(
     'CREATE INDEX IF NOT EXISTS idx_journal_user_date ON journal_entries(userId, date DESC)'
   );
   // backfill not required — userId already populated on existing rows
   ```
4. Rewrite every watcher to accept `userId` param:
   ```dart
   Stream<List<Entry>> watchMonthEntries(int userId, DateTime month) =>
     (select(journalEntries)..where((e) => e.userId.equals(userId) & e.date.isBetweenValues(start, end))).watch()...
   ```
5. Inject `currentUserId` from `UserRepository` at caller sites (providers/services).
6. Keep `idx_journal_date` as fallback for single-user queries; drop `idx_journal_mood` only if the new composite covers it — measure first.

#### Benchmark plan
- Run `PRAGMA index_list(journal_entries)` before/after to confirm `idx_journal_user_date` exists.
- EXPLAIN QUERY PLAN for `SELECT * FROM journal_entries WHERE userId=? AND date BETWEEN ? AND ?` — expect `SEARCH TABLE journal_entries USING INDEX idx_journal_user_date`.
- Seed 10k entries across 3 userIds, measure `watchMonthEntries` cold latency.

#### Test plan
- `test/services/entry_repository_multiuser_test.dart`: create 2 users, insert entries under each, assert `watchMonthEntries(aliceId)` never returns Bob's rows.
- Migration test: open a pre-migration DB, run migration, assert index exists and all rows preserved.
- Full `flutter test` regression.

#### Acceptance criteria
- [ ] EXPLAIN QUERY PLAN confirms index usage
- [ ] Multi-user isolation test green
- [ ] Migration test green
- [ ] Commit pushed with `refactor(perf):` prefix referencing Task 8.2

#### Dependencies
- Blocks: Cloud sync (Part III), Retraq Care tier, multi-user settings (Task 8.4).
- Blocked by: Task 8.3 (schema should bump once for userId + updatedAt together).

---

### Task 8.3 — Add `updatedAt`, `deletedAt` (soft-delete), and `serverId` UUID for cloud-sync readiness

**Source:** A8 finding "Cloud sync readiness: no `updatedAt`, no tombstones, no server-assigned IDs" · **Rating:** Bottleneck (future)
**Priority:** P1 · **Effort:** L · **Tier:** v2 (cross-reference Part III cloud sync)

#### Problem
Current schema cannot support differential sync: no way to ask "give me everything changed since T", no tombstones for deletions (deleted rows vanish from both client and server), no stable server-assigned identifier independent of the local autoincrement rowid.

#### Root cause
Schema optimized for local-only use. Cloud sync requires last-write-wins timestamps, tombstone rows to propagate deletes, and collision-free identifiers.

#### Files touched
- `lib/services/database_service.dart:29-43` — add three columns to `JournalEntries` (and likely `UserSettings`, `ConsentRecords`)
- `lib/services/migration_strategy.dart` — schema version bump + migration
- `lib/services/entry_repository.dart` — soft-delete path, `updatedAt` bump on every write, UUID generation on insert
- `lib/services/export_service.dart:19-32` — include new fields in export schema (bump `schemaVersion`)
- `pubspec.yaml` — add `uuid: ^4.x` if not present

#### Implementation approach
1. **Drift table change**:
   ```dart
   class JournalEntries extends Table {
     // ...existing
     DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
     DateTimeColumn get deletedAt => dateTime().nullable()();
     TextColumn get serverId => text().withDefault(const Constant(''))(); // UUID v7, populated on insert
   }
   ```
2. **Migration sketch**:
   ```dart
   await m.addColumn(journalEntries, journalEntries.updatedAt);
   await m.addColumn(journalEntries, journalEntries.deletedAt);
   await m.addColumn(journalEntries, journalEntries.serverId);
   // Backfill: updatedAt = createdAt, serverId = Uuid().v7() per row
   await customStatement("UPDATE journal_entries SET updatedAt = createdAt WHERE updatedAt IS NULL");
   // Row-by-row UUID backfill via Dart (SQLite has no UUID generator)
   ```
3. Every `update`/`insert` in `EntryRepository` sets `updatedAt: DateTime.now()` and (on insert) `serverId: Uuid().v7()`.
4. Replace `delete()` with soft-delete: `UPDATE ... SET deletedAt = now(), updatedAt = now()`. Add `onlyAlive` filter helper and apply to every watcher: `..where((e) => e.deletedAt.isNull())`.
5. Add periodic housekeeping: purge rows where `deletedAt < now - 30 days` once sync is confirmed (backlog).
6. Same treatment for `UserSettings` and `ConsentRecords` if they will sync.

#### Benchmark plan
- Measure write latency before/after (extra column writes are negligible but verify).
- Confirm read path unaffected: EXPLAIN QUERY PLAN for watchers with `deletedAt IS NULL` stays on indexed scan (add covering column if needed).

#### Test plan
- Migration test: pre-migration DB upgrades, all rows get UUIDs and `updatedAt=createdAt`.
- Soft-delete test: delete entry → no longer visible in watchers; tombstone row still present with `deletedAt` set.
- Export schema test: exported JSON contains new fields, `schemaVersion` bumped.
- Full `flutter test` regression.

#### Acceptance criteria
- [ ] Migration leaves every row with a valid UUID and updatedAt
- [ ] Deleting an entry tombstones instead of removing
- [ ] Export schema version bumped and documented
- [ ] Commit pushed with `refactor(perf):` prefix referencing Task 8.3

#### Dependencies
- Blocks: Cloud sync (Part III).
- Pair with Task 8.2 in same schema version bump.

---

### Task 8.4 — Replace Settings id=1 singleton with per-user settings row

**Source:** A8 finding "Settings singleton (id=1); `watchSettings()` hardcoded `id.equals(1)`" · **Rating:** Bottleneck (future)
**Priority:** P1 · **Effort:** M · **Tier:** v2 (cross-reference Part III cloud sync)

#### Problem
`UserSettings` is treated as a singleton keyed on `id=1`. Under multi-user / family sharing, the second user overwrites the first user's settings or sees them leak.

#### Root cause
`SettingsRepository.watchSettings()` hardcodes `id.equals(1)`; `DatabaseService` seeds exactly one row. No `userId` FK.

#### Files touched
- `lib/services/database_service.dart:62-91` — add `userId` FK + unique index on `UserSettings`; drop id=1 seed
- `lib/services/settings_repository.dart:104-109` — key on `userId` instead of `id=1`
- `lib/services/migration_strategy.dart` — migration that converts id=1 row to per-user row
- `lib/services/user_repository.dart` — on first-launch / new-user event, create the settings row
- `test/services/settings_repository_multiuser_test.dart` (new)

#### Implementation approach
1. **Drift table change**:
   ```dart
   class UserSettings extends Table {
     IntColumn get userId => integer().customConstraint('NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE')();
     // ...existing fields
     @override
     Set<Column> get primaryKey => {userId};
   }
   ```
2. **Migration sketch**:
   ```dart
   // old row id=1 gets userId from the single existing user (or default user created in earlier migration)
   await customStatement('UPDATE user_settings SET userId = (SELECT id FROM users LIMIT 1) WHERE userId IS NULL');
   await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS idx_user_settings_user ON user_settings(userId)');
   ```
3. Rewrite `watchSettings()` to `watch(userId)`:
   ```dart
   Stream<Settings> watchSettings(int userId) =>
     (select(userSettings)..where((s) => s.userId.equals(userId))).watchSingle();
   ```
4. Add `createDefaultSettings(userId)` called from `UserRepository.createUser`.
5. Drop the `id=1` seeder in `DatabaseService.init`.

#### Benchmark plan
- Confirm `watchSettings` still single-row lookup (indexed on userId).
- EXPLAIN QUERY PLAN shows `SEARCH TABLE user_settings USING INDEX idx_user_settings_user`.

#### Test plan
- New multi-user test: create 2 users, change theme on A, assert B unaffected.
- Migration test: pre-migration DB has id=1 row → migration assigns it to existing user.
- Full `flutter test` regression.

#### Acceptance criteria
- [ ] No hardcoded `id.equals(1)` remains anywhere
- [ ] Multi-user isolation test green
- [ ] Migration test green
- [ ] Commit pushed with `refactor(perf):` prefix referencing Task 8.4

#### Dependencies
- Blocked by: Task 8.2 (userId query refactor) and Task 8.3 (schema bump).

---

### Task 8.5 — Convert AppShell PageView to lazy IndexedStack and pause streams on inactive tabs

**Source:** A8 finding "4 tabs eagerly constructed; Home/Stats/Recap all `AutomaticKeepAliveClientMixin`" · **Rating:** Watch
**Priority:** P2 · **Effort:** M · **Tier:** v1.1

#### Problem
All 4 tabs are built eagerly at shell-mount. Home/Stats/Recap keep state via `AutomaticKeepAliveClientMixin`, meaning their stream subscriptions never pause. Memory grows linearly and wakelocks on Stats debounce timer keep running even when user is on Settings tab.

#### Root cause
`PageView` with `NeverScrollableScrollPhysics` still instantiates every child upfront. `KeepAlive` locks them in. No `AppLifecycleState`-aware pause hook on child streams.

#### Files touched
- `lib/screens/app_shell.dart:67-80` — swap PageView → lazy IndexedStack (or `Navigator` per-tab)
- `lib/screens/home_screen.dart:60-62,114-160` — pause stream subs when inactive
- `lib/screens/stats_screen.dart:57` — pause watchAllStats when inactive
- `lib/screens/recap_screen.dart:32-35` — pause month/search streams when inactive
- `test/screens/app_shell_lazy_test.dart` (new)

#### Implementation approach
1. Replace `PageView` with `IndexedStack` whose children are built lazily on first visit (keep a `Set<int> _visited`; build a `SizedBox.shrink()` for unvisited indices).
2. Add an `InheritedNotifier<TabActivationNotifier>` that fires when the active index changes.
3. In each tab's State, listen and call `_pauseStreams()` / `_resumeStreams()` — pause by calling `.pause()` on `StreamSubscription` handles.
4. Alternative simpler approach: remove `AutomaticKeepAliveClientMixin` on Stats/Recap (keep on Home only if necessary) and let the build re-trigger. Measure memory diff.
5. Keep `NavigationBar` behavior identical.

#### Benchmark plan
- Measure heap snapshot in DevTools at startup and after 60s of idling on Settings tab; compare before/after.
- Count live `StreamSubscription` instances via `debugPrint` hook.

#### Test plan
- Widget test asserts lazy build: mount AppShell, verify HomeScreen `initState` fires but StatsScreen/RecapScreen do not until selected.
- Regression: switching tabs preserves scroll position where needed (Home's scroll should survive).
- Full `flutter test` regression.

#### Acceptance criteria
- [ ] Heap delta measured and documented
- [ ] Lazy-build test green
- [ ] No UX regression in tab switching
- [ ] Commit pushed with `perf:` prefix referencing Task 8.5

#### Dependencies
- None; can ship independently.

---

### Task 8.6 — Switch HomeScreen's 3 live streams to StreamBuilder with tab-blur pausing

**Source:** A8 finding "Home screen holds 3 live stream subs even when on another tab" · **Rating:** Watch
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
HomeScreen subscribes to 3 streams (today entry, week entries, recent entries) in `initState`. They stay active even when user is deep inside Stats or Settings. Every journal write causes rebuild work off-screen.

#### Root cause
Raw `subscription.listen(...)` in `initState` with no pause hook. `AutomaticKeepAliveClientMixin` compounds it.

#### Files touched
- `lib/screens/home_screen.dart:60-62,114-160`
- `test/screens/home_screen_test.dart` (extend)

#### Implementation approach
1. Either refactor the three streams into `StreamBuilder<T>` in the widget tree (simplest) or add pause/resume integrated with Task 8.5's `TabActivationNotifier`.
2. Drop `AutomaticKeepAliveClientMixin` if stream-builder approach used — state is cheap to rebuild from the stream.
3. Verify no flicker on tab switch by preserving last snapshot via `initialData`.

#### Benchmark plan
- Count rebuilds of HomeScreen when on Stats tab before/after a 10-entry batch write — expect 0 after.

#### Test plan
- Widget test: place HomeScreen inside a Stack where parent toggles `Offstage`, write 5 entries, assert builder not called.
- Regression for existing Home behavior (progress bar, hero prompt, recent cards).

#### Acceptance criteria
- [ ] Rebuild count on inactive tab drops to 0
- [ ] No UX regression
- [ ] Commit pushed with `perf:` prefix referencing Task 8.6

#### Dependencies
- Pairs with Task 8.5 if using shared notifier.

---

### Task 8.7 — Cap `getCurrentStreak` date window and/or add persistent streak counter

**Source:** A8 finding "`getLongestStreak` uses ROW_NUMBER() over all DISTINCT dates; `getCurrentStreak` pulls up to 1100 rows to Dart" · **Rating:** Watch
**Priority:** P2 · **Effort:** M · **Tier:** v1.1

#### Problem
At 10k+ entries the streak algorithms pull 1100+ date rows and run window functions over all DISTINCT dates. Acceptable at 2k; degrades above that.

#### Root cause
Algorithm pulls rows to Dart and walks them. Longest-streak window function scans full table.

#### Files touched
- `lib/services/stats_service.dart:160-187,28-115`
- `lib/services/database_service.dart` — new `StreakCounters` table if persistent approach chosen
- `lib/services/migration_strategy.dart` — schema bump
- `test/services/stats_service_perf_test.dart` (new)

#### Implementation approach
**Option A (quickest):** cap the WHERE on `getCurrentStreak` to `date >= now - 365 days` — a year-long streak is the practical ceiling for user-visible stat.
**Option B (robust):** persistent counter table:
```dart
class StreakCounters extends Table {
  IntColumn get userId => integer()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastEntryDate => dateTime().nullable()();
  @override Set<Column> get primaryKey => {userId};
}
```
Update on every entry insert/delete via a transaction. O(1) reads forever.

Pick Option A for v1.1, plan Option B as a follow-up tracked in the same task.

#### Benchmark plan
- Seed 10k entries across 5 years, time `getCurrentStreak` and `getLongestStreak` before/after.
- Target: < 10ms for both.

#### Test plan
- Perf test harness in `test/perf/streak_bench.dart`.
- Correctness: match old result for 2k entries.

#### Acceptance criteria
- [ ] Perf improvement documented
- [ ] Correctness preserved
- [ ] Commit pushed with `perf:` prefix referencing Task 8.7

---

### Task 8.8 — Show synchronous splash if DB init cold-start regresses beyond 400ms

**Source:** A8 finding "`await DatabaseService.instance.init()` blocks first frame on secure-storage read, SQLCipher open, PRAGMA verify, settings seed" · **Rating:** Watch
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
150-400ms cold-start is acceptable today, but any future init work (migrations, integrity checks) will push it past the "first frame in 500ms" guideline. No splash = user sees black screen during init.

#### Root cause
`main()` awaits `DatabaseService.instance.init()` before `runApp`. The init itself does secure-storage read + SQLCipher open + `SELECT 1` + default-settings seed.

#### Files touched
- `lib/main.dart:51`
- `lib/screens/splash_screen.dart` (new, if not present)
- `android/app/src/main/res/drawable/launch_background.xml` — verify native splash matches

#### Implementation approach
1. Keep `init()` await but ensure native splash bitmap (flutter_native_splash) covers until first frame.
2. Add a `Stopwatch` guard: if init exceeds 400ms, log a perf warning via existing logging infra.
3. If it regresses, move init to `runApp` + `FutureBuilder`-gated app root.

#### Benchmark plan
- Measure cold start via `flutter run --trace-startup --profile` — record `timeToFirstFrameMicros` before/after.

#### Test plan
- Smoke: app launches without black flash on low-end device.
- Regression: `flutter test`.

#### Acceptance criteria
- [ ] Cold-start metric captured and within 500ms target
- [ ] Commit pushed with `perf:` prefix referencing Task 8.8

---

### Task 8.9 — Signature-cache `watchTotalDaysWithEntries` / `watchMonthEntryMoods` / `watchMonthEntryDays` if they become hot

**Source:** A8 finding "`watchTotalDaysWithEntries`, `watchMonthEntryMoods`, `watchMonthEntryDays` full-scan on every journal write" · **Rating:** Watch
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
These watchers re-query on every journal mutation. Only matter when listener is attached, but MonthView's heatmap subscribes them. No debounce/signature cache today.

#### Root cause
No intermediate layer; queries re-run on every `journal_entries` stream tick.

#### Files touched
- `lib/services/entry_repository.dart:299-394`
- `test/services/entry_repository_cache_test.dart` (new)

#### Implementation approach
1. Wrap each watcher in the same signature-based debounce pattern used by `watchAllStats` (600ms debounce, skip emit if result signature unchanged).
2. Extract the pattern into `lib/services/_stream_cache.dart` helper if not already extracted.

#### Benchmark plan
- Count downstream emits during a 10-entry batch insert before/after — expect 1-2 after.

#### Test plan
- Stream test with manual clock asserts debounced emits.
- Regression.

#### Acceptance criteria
- [ ] Emit-count reduction documented
- [ ] Commit pushed with `perf:` prefix referencing Task 8.9

---

### Task 8.10 — Move `getTotalEntryCount` off the main isolate post-save

**Source:** A8 finding "Duplicate `_getTotalEntryCount` query; `getTotalEntryCount()` on main isolate after every save" · **Rating:** Watch
**Priority:** P2 · **Effort:** XS · **Tier:** v1.1

#### Problem
After every save, HomeScreen queries total entry count on the main isolate. Currently fast (< 5ms at 10k) but adds to save-tap latency.

#### Root cause
Direct `.count()` call after save; no caching.

#### Files touched
- `lib/screens/home_screen.dart:755`
- `lib/services/entry_repository.dart:272-294`

#### Implementation approach
1. Dedupe: use the single `getTotalEntryCount()` call path.
2. Cache the value in a `ValueNotifier<int>`; update optimistically on insert (+1) / delete (-1).
3. Reconcile every 60s by re-querying off-main via `compute()` or Drift's isolate executor.

#### Benchmark plan
- Time post-save user-visible latency before/after.

#### Test plan
- Test asserts counter increments on insert without query.

#### Acceptance criteria
- [ ] Save→UI update latency reduced
- [ ] Commit pushed with `perf:` prefix referencing Task 8.10

---

### Task 8.11 — Verify `WidgetService.update()` on save is fire-and-forget

**Source:** A8 finding "HomeScreen calls `WidgetService.instance.update()` on every save, synchronously" · **Rating:** Watch
**Priority:** P2 · **Effort:** XS · **Tier:** v1.1

#### Problem
Widget update after save may block the save-handler's async chain if awaited.

#### Root cause
Unclear whether the call is `await`ed or fired-and-forgotten.

#### Files touched
- `lib/screens/home_screen.dart:779`
- `lib/services/widget_service.dart`

#### Implementation approach
1. Audit call site: wrap in `unawaited(WidgetService.instance.update())` to be explicit.
2. Inside `update()`, ensure the platform-channel call doesn't block on IO.

#### Benchmark plan
- Compare save-tap latency with/without widget installed.

#### Test plan
- Static analysis: `unawaited_futures` lint catches future regressions (tie to Task 12 lint expansion).

#### Acceptance criteria
- [ ] Call site explicitly fire-and-forget
- [ ] Commit pushed with `perf:` prefix referencing Task 8.11

---

### Task 8.12 — Cache SQLCipher-probe result to avoid throwaway AppDatabase on every open

**Source:** A8 finding "DB init does sync `file.existsSync()` + creates throwaway AppDatabase to probe encryption" · **Rating:** Watch
**Priority:** P3 · **Effort:** S · **Tier:** v1.1

#### Problem
On every cold start, init opens a throwaway AppDatabase instance to probe whether the file is encrypted. Adds ~20-50ms.

#### Root cause
Defensive probe added during plaintext→encrypted migration era; now only matters on upgrade.

#### Files touched
- `lib/services/database_service.dart:195-212`

#### Implementation approach
1. Write a `db_probe_ok` flag to secure storage after successful encrypted open.
2. On subsequent launches, skip probe if flag present.
3. Keep probe path as fallback (flag missing → re-probe).

#### Benchmark plan
- Measure init duration on warm start before/after.

#### Test plan
- Test: first launch probes; second launch skips.
- Regression: upgrade path still probes.

#### Acceptance criteria
- [ ] Init duration measured and improvement recorded
- [ ] Commit pushed with `perf:` prefix referencing Task 8.12

---

### Task 8.13 — Keep `flutter_animate` + AnimatedBuilder shake on HomeScreen as-is (reference entry)

**Source:** A8 finding "RecentDayCard wrapped in `flutter_animate` per build; HomeScreen uses AnimatedBuilder + TweenSequence shake" · **Rating:** Watch
**Priority:** P3 · **Effort:** XS · **Tier:** v1.1 (monitor only)

#### Problem
`flutter_animate` is invoked per build on `RecentDayCard`; the home-screen shake uses `AnimatedBuilder` + `TweenSequence`. Currently GPU-cheap and gated by `AppMotion.reduced` respect, so acceptable.

#### Root cause
N/A — not a regression; monitor for future issues.

#### Files touched
- `lib/screens/home/recent_day_card.dart:153-165` (reference)
- `lib/screens/home_screen.dart:298-302` (reference)

#### Implementation approach
No code change. Add a comment documenting the "AppMotion-gated" expectation so future refactors don't accidentally ignore reduced-motion.

#### Benchmark plan
- Establish baseline: Flutter DevTools "Performance overlay" on a 60-entry week view. Re-check in each future audit.

#### Test plan
- None beyond existing widget tests.

#### Acceptance criteria
- [ ] Comment added clarifying motion-gate intent
- [ ] Commit pushed with `docs(perf):` prefix referencing Task 8.13

---

### Task 8.14 — Keep `watchEntriesForDate`/`watchMonthEntries`/`watchWeekEntriesFrom` as-is (reference entry)

**Source:** A8 finding "`watchEntriesForDate`, `watchMonthEntries`, `watchWeekEntriesFrom` map to models on every journal write" · **Rating:** Optimal
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Date-range WHERE clauses are covered by existing indexes; model-map cost is minimal.

#### Root cause
N/A.

#### Files touched
- `lib/services/entry_repository.dart:99-112,207-233,332-345` (reference only)

#### Implementation approach
No change. Keep indexes (`idx_journal_date`, `idx_journal_date_mood`) intact during Task 8.2's userId refactor — they become part of a composite.

#### Benchmark plan
- Spot-check EXPLAIN QUERY PLAN in the Task 8.2 rework to confirm index usage after composite is added.

#### Test plan
- Existing tests.

#### Acceptance criteria
- [ ] No regression after Task 8.2 ships.

---

### Task 8.15 — Keep `watchAllStats` signature-cache + 600ms debounce as-is (reference entry)

**Source:** A8 finding "Stats screen subscribes to `watchAllStats` with signature-cache + 600ms debounce" · **Rating:** Optimal
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Exemplar pattern; extract into helper for Task 8.9 reuse.

#### Root cause
N/A.

#### Files touched
- `lib/services/stats_service.dart:519-546` (reference)
- `lib/screens/stats_screen.dart:57` (reference)

#### Implementation approach
Document the pattern in a dartdoc comment on `watchAllStats` so future contributors recognize the idiom. Extract helper `_SignatureDebouncer<T>` into `lib/services/_stream_cache.dart` when Task 8.9 ships.

#### Benchmark plan
- N/A.

#### Test plan
- N/A.

#### Acceptance criteria
- [ ] Extracted helper re-used by Task 8.9.

---

### Task 8.16 — Keep `compute()`-isolate JSON/text export as-is (reference entry)

**Source:** A8 finding "Export uses `compute()` isolate for JSON encode and text format" · **Rating:** Optimal
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. 10k entries ≈ a few MB, already offloaded.

#### Root cause
N/A.

#### Files touched
- `lib/services/export_service.dart:208,233,295` (reference)

#### Implementation approach
No change. Note: when Task 8.3's soft-delete/`updatedAt`/`serverId` fields ship, remember to include them in the export payload and bump `schemaVersion`.

#### Benchmark plan
- N/A.

#### Test plan
- N/A.

#### Acceptance criteria
- [ ] Export payload updated (tracked in Task 8.3).

---

### Task 8.17 — Keep import dedup min/max/Set-lookup/batch-insert as-is (reference entry)

**Source:** A8 finding "Import dedup pre-scans min/max date, uses O(1) Set lookup, batches inserts" · **Rating:** Optimal
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None.

#### Root cause
N/A.

#### Files touched
- `lib/services/export_service.dart:308-465` (reference)

#### Implementation approach
No change.

#### Benchmark plan
- N/A.

#### Test plan
- N/A.

#### Acceptance criteria
- [ ] None.

---

### Task 8.18 — Keep NavigationBar RepaintBoundary + 321 const usages as-is (reference entry)

**Source:** A8 finding "NavigationBar wrapped in RepaintBoundary, 321 const usages across screens" · **Rating:** Optimal
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None.

#### Root cause
N/A.

#### Files touched
- `lib/screens/app_shell.dart:81` (reference)

#### Implementation approach
No change. Preserve `RepaintBoundary` when Task 8.5 swaps PageView for IndexedStack — keep wrapping the bottom bar.

#### Benchmark plan
- N/A.

#### Test plan
- N/A.

#### Acceptance criteria
- [ ] `RepaintBoundary` preserved in Task 8.5 diff.

---

### Task 8.19 — Keep eagerly-created `_shakeController` as-is (reference entry)

**Source:** A8 finding "`_shakeController` + Animation eagerly created at state-init" · **Rating:** Optimal
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Negligible.

#### Root cause
N/A.

#### Files touched
- `lib/screens/home_screen.dart:67-77` (reference)

#### Implementation approach
No change.

#### Benchmark plan
- N/A.

#### Test plan
- N/A.

#### Acceptance criteria
- [ ] None.

---

### Task 8.20 — Keep FTS5 prefix-match + LIMIT 50 search as-is (reference entry)

**Source:** A8 finding "FTS5 search prefix-match on every token + LIMIT 50" · **Rating:** Optimal
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Scales well.

#### Root cause
N/A.

#### Files touched
- `lib/services/entry_repository.dart:409-465` (reference)

#### Implementation approach
No change. Verify FTS5 index still intact after Task 8.2's userId addition — may need to rebuild FTS external-content trigger if schema moves.

#### Benchmark plan
- Spot-check `EXPLAIN QUERY PLAN` for search after Task 8.2 lands.

#### Test plan
- Existing search tests.

#### Acceptance criteria
- [ ] No regression after Task 8.2.
