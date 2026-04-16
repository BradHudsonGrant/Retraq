# Epic 11 — On-Device Analytics & Measurement (Privacy-Preserving)

Source: review-2026-04-16.md §Agent 11

> **Prime directive:** "No analytics, no telemetry, no tracking of any kind" (`lib/legal/privacy_policy.dart:12,31`) is a load-bearing product promise. Every task below assumes **default: nothing leaves the device**. The only exit door is a user-initiated, explicitly opt-in "Help improve Retraq" share sheet that reuses the existing `ExportService` plumbing and strips all free-text/titles/labels before handing bytes to the OS share intent. No HTTP client is added to the app as part of this epic.

---

## Opt-in "Help improve Retraq" export — shared spec

Referenced by Task 11.1, 11.2, 11.3, 11.6, 11.7, 11.11, 11.12.

**JSON shape (`anonymized_stats_v1.json`):**
```jsonc
{
  "schemaVersion": 1,
  "exportType": "anonymized_stats",
  "generatedAtUtc": "2026-05-01T00:00:00Z",       // day-bucketed, no HH:MM
  "appVersion": "1.1.0+42",
  "platform": "android",                           // ios | android
  "locale": "en-CA",
  "tier": "free",                                  // free | premium (when v1.1 ships)
  "installAgeDays": 37,                            // derived, not raw installedAt
  "firstEntryAgeDays": 35,                         // derived
  "variantBucket": "onboarding_copy_b",            // Task 11.7, opt-in only
  "counts": {
    "totalEntries": 48,
    "activeDays": 22,
    "longestStreak": 9,
    "currentStreak": 3,
    "entriesPerActiveDay": 2.18,
    "daysSinceLastEntry": 1
  },
  "featureCounters": { "export_tapped": 1, "recap_viewed": 6, "theme_changed": 2 },
  "onboardingFunnel": {
    "age_gate_ms": 4200, "consent_ms": 8100,
    "pin_setup_ms": null, "first_entry_ms": 41300
  },
  "moodDistribution": { "1": 2, "2": 3, "3": 10, "4": 8, "5": 4 },
  "weekdayActivity": [3, 7, 5, 4, 6, 8, 2],
  "recapFeedback": { "up": 4, "down": 1, "dismissed": 2 },
  "notifications": { "sent": 14, "opened": 4 }
}
```

**PII fields stripped (never present in anonymized export):**
- Entry `title`, `body`, `plainText`, `tags`, `labels`
- User-chosen `displayName`, `pronouns`, any free-text in `UserSettings`
- Raw `installedAt`, `firstEntryAt` ISO timestamps (only day-deltas leak)
- PIN hash, biometric state, encryption keys
- Recap generated summaries (bodies), recap prompts
- File paths, device name, advertising IDs, push tokens, IP hints
- Photo attachments, custom icon paths, notification bodies
- Install UUID (variant bucket is hashed; raw UUID never leaves)

**Presentation rule:** export is always routed through the OS share sheet. The app itself never opens a socket. The UI explicitly labels it "You choose where this goes — email it to yourself, drop it in a Discord thread, or delete it." A scrub preview diff is shown before share.

---

## Task 11.1 — Record install timestamp & first-entry timestamp

**Source:** A11 finding "No install timestamp or first-entry timestamp recorded" · **Rating:** Undefined
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
`Users` table (`lib/services/database_service.dart:46-59`) has no `createdAt`; `entries` table has no `firstSavedAt` cache. D1/D7/D30 retention and Time-To-First-Entry (TTFE) are literally unmeasurable — any product question about activation drops off a cliff.

#### Root cause (what isn't measurable and why)
No anchor timestamps exist. Even locally, there is nothing to diff against "now" to compute install age, TTFE, or cohort week. Schema versioning is already in place (Drift migrations), so the gap is purely one of unrecorded fields, not infrastructure.

#### Privacy design
- **What leaves the device?** Nothing by default.
- Stored as `INTEGER` epoch millis in the already-encrypted SQLCipher DB. Never read by any network code (none exists). When the Task 11.11 anonymized export runs, the raw timestamps are bucketed into `installAgeDays` / `firstEntryAgeDays` before serialization — the ISO values never exit.

#### Files touched
- `lib/services/database_service.dart` — add `createdAt` to `Users`, add `firstSavedAt` cached column on `Entries`
- `lib/services/migration_strategy.dart` (or the `MigrationStrategy` inside `database_service.dart`) — v`N→N+1` migration backfilling `createdAt = now()` for existing users, `firstSavedAt = MIN(entries.createdAt)` per user
- `lib/services/user_repository.dart` — set `createdAt` on first-row insert
- `lib/services/entry_repository.dart` — update `firstSavedAt` on first save
- `lib/services/export_service.dart` — include derived deltas (not raw timestamps) in anonymized variant

#### Implementation approach
1. Drift sketch:
   ```dart
   class Users extends Table {
     IntColumn get id => integer().autoIncrement()();
     DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
     // existing columns...
   }
   class Entries extends Table {
     // existing columns...
     DateTimeColumn get firstSavedAt => dateTime().nullable()();
   }
   ```
2. Migration SQL:
   ```sql
   ALTER TABLE users ADD COLUMN created_at INTEGER;
   UPDATE users SET created_at = strftime('%s','now')*1000 WHERE created_at IS NULL;
   ALTER TABLE entries ADD COLUMN first_saved_at INTEGER;
   UPDATE entries SET first_saved_at = created_at WHERE id IN
     (SELECT MIN(id) FROM entries GROUP BY user_id);
   ```
3. Hook point: `UserRepository.ensureDefaultUser()` sets `createdAt` only when inserting.
4. Hook point: `EntryRepository.save()` writes `firstSavedAt` iff the user has zero prior entries (guarded by `COUNT(*) = 0`).

#### Test plan
- Unit: new user insert populates `createdAt`; re-running `ensureDefaultUser` does not overwrite it.
- Unit: inserting the first entry stamps `firstSavedAt`; second entry does not shift it.
- Migration test: pre-migration fixture DB with 3 entries, post-migration has `createdAt` set and `firstSavedAt = MIN(createdAt)` on the first entry only.
- CI no-network assertion (shared fixture from Epic 6) still passes.

#### Acceptance criteria
- [ ] Schema migration tested against a canned pre-migration DB
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (day-deltas only, no ISO timestamps)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.1

#### Dependencies
- Blocks: 11.2 (app_sessions retention math), 11.11 (anonymized export needs deltas)
- Blocked by: Epic 6 (migration-test harness expansion)
- External: Epic 12 (privacy policy already matches; no update needed)

---

## Task 11.2 — Add local `app_sessions` table for cohort/retention math

**Source:** A11 finding "D1/D7/D30 retention unmeasurable without cohort tracking" · **Rating:** Undefined
**Priority:** P2 · **Effort:** M · **Tier:** v1.1

#### Problem
No session table exists, so D1/D7/D30 return rates, weekly active days, and "dormant" user detection are impossible. This is not just a product question — it is the signal needed to decide whether v1.1 monetization timing is right.

#### Root cause (what isn't measurable and why)
Lifecycle events (`AppLifecycleState.resumed`) fire but are not recorded. Nothing persists "the user opened the app today."

#### Privacy design
- **What leaves the device?** Nothing by default.
- Schema stores only: session start epoch, duration millis, cold/warm flag. No route names, no entry IDs, no PII.
- Anonymized export (11.11) rolls these up to `activeDays`, `entriesPerActiveDay` counts only — raw per-session rows never exit.
- Rolling TTL: prune rows older than 400 days on every cold start so a dormant reactivation cannot reveal a detailed 2-year usage history.

#### Files touched
- `lib/services/database_service.dart` — new `AppSessions` table
- `lib/services/migration_strategy.dart` — v`N→N+1` migration
- `lib/services/analytics_service.dart` (new) — `startSession()`, `endSession()` lifecycle hooks
- `lib/main.dart` or `lib/app.dart` — wire into `WidgetsBindingObserver` alongside existing lifecycle handling
- `lib/screens/stats_screen.dart` — "Your Stats" surface additions (active days, weekly trend)
- `lib/services/export_service.dart` — anonymized rollups

#### Implementation approach
1. Drift sketch:
   ```dart
   class AppSessions extends Table {
     IntColumn get id => integer().autoIncrement()();
     DateTimeColumn get startedAt => dateTime()();
     DateTimeColumn get endedAt => dateTime().nullable()();
     IntColumn get durationMs => integer().nullable()();
     BoolColumn get coldStart => boolean().withDefault(const Constant(false))();
   }
   ```
2. `AnalyticsService` is a thin facade. No network client, no isolate — pure DB writer with a debounce so foreground/background flicker doesn't create junk rows (min 2s).
3. On `AppLifecycleState.resumed` → open session. On `paused/inactive` → close. On app start after crash → `endedAt = startedAt` heuristic.
4. Stats screen shows "22 active days in the last 30" using count-distinct-by-day(startedAt).
5. TTL pruning via `DELETE FROM app_sessions WHERE started_at < ?` runs once per cold start.

#### Test plan
- Unit: `startSession`/`endSession` round-trip writes expected row.
- Unit: double-`resumed` within 2s does not create a second row.
- Integration: no network traffic triggered — asserted by CI fake `HttpOverrides.global` that throws on any `HttpClient` use.
- Migration test: fresh install creates table; existing DB upgrades cleanly.

#### Acceptance criteria
- [ ] Schema migration tested
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (rollups only)
- [ ] TTL pruning verified via unit test
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.2

#### Dependencies
- Blocks: 11.11 (rollups), 11.13 (kill switch toggles recording)
- Blocked by: 11.1 (`Users.createdAt` needed for cohort week)
- External: Epic 6 (integration-test journey suite exercises session writes)

---

## Task 11.3 — Reframe `StatsSnapshot` as engagement signal set; add `entriesPerActiveDay` + `daysSinceLastEntry`

**Source:** A11 finding "Existing StatsSnapshot fields are best engagement proxy" · **Rating:** Buildable
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
`StatsService` (`lib/services/stats_service.dart:20-503`) already computes strong signals, but they live purely as UI labels. They are the single best engagement proxy available on-device and are missing two churn predictors: `entriesPerActiveDay` and `daysSinceLastEntry`.

#### Root cause (what isn't measurable and why)
`StatsSnapshot` is typed for the stats screen, not for a rollup pipeline. Two high-signal fields are absent; the rest are present but not wired to anything downstream.

#### Privacy design
- **What leaves the device?** Nothing by default.
- Snapshot remains a plain in-memory Dart object — no new persistence.
- When the user taps "Help improve Retraq" (Task 11.11), `StatsSnapshot` → `Map<String, int/double>` adapter writes into `counts` block. Entry bodies/titles untouched.

#### Files touched
- `lib/services/stats_service.dart` — add `entriesPerActiveDay` and `daysSinceLastEntry` fields
- `lib/models/stats_snapshot.dart` — extend type
- `lib/screens/stats_screen.dart` — surface new fields as "Your Stats" tiles
- `lib/services/export_service.dart` — anonymized `counts` block builder

#### Implementation approach
1. `entriesPerActiveDay = totalEntries / activeDays` (guard `activeDays == 0 → 0.0`).
2. `daysSinceLastEntry = floor((now - lastEntryAt) / 24h)`; `null` if no entries.
3. Add user-visible "Your Stats" rows: "2.2 traqs per active day", "3 days since your last traq."
4. Anonymized export adapter rounds `entriesPerActiveDay` to 2 decimals, caps `daysSinceLastEntry` at 365 to prevent re-identification of long-dormant users.

#### Test plan
- Unit: zero-entry user → both fields safely null / 0.0.
- Unit: 48 entries across 22 days → 2.18 rounded.
- Unit: last entry = 72h ago → `daysSinceLastEntry == 3`.
- Golden: stats screen shows new tiles (ties to Epic 6 visual regression).

#### Acceptance criteria
- [ ] New fields computed and surfaced in "Your Stats"
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (counts only, capped)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.3

#### Dependencies
- Blocks: 11.11 (counts block consumer)
- Blocked by: none
- External: Epic 7 (UX copy review for new stats tile wording)

---

## Task 11.4 — Local-only `feature_counters` KV table

**Source:** A11 finding "No feature-usage counters (export tapped, recap viewed, theme changed)" · **Rating:** Buildable
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
Feature usage — export tapped, recap viewed, theme changed, "On This Day" opened, mood selector used — is invisible. Without it, "which Settings toggle matters" is guesswork, and the "Your app habits" premium surface has nothing to render.

#### Root cause (what isn't measurable and why)
No counter store. No naming convention. No call sites instrumented.

#### Privacy design
- **What leaves the device?** Nothing by default.
- KV shape: `(counter_key TEXT, value INTEGER, updated_at INTEGER)`. Keys are a closed enum defined in code; no free-form keys, no user text.
- Exported only via 11.11 anonymized path as `featureCounters` map; keys are not sensitive.

#### Files touched
- `lib/services/database_service.dart` — new `FeatureCounters` table
- `lib/services/migration_strategy.dart` — v`N→N+1` migration
- `lib/services/analytics_service.dart` (new, same facade as 11.2) — `bump(FeatureCounterKey key)`
- `lib/services/feature_counter_keys.dart` (new) — closed enum
- `lib/screens/settings/data_section.dart` — `bump(FeatureCounterKey.exportTapped)` hook
- `lib/screens/recap_screen.dart` — `bump(FeatureCounterKey.recapViewed)`
- `lib/screens/settings/appearance_section.dart` (or similar) — `bump(FeatureCounterKey.themeChanged)`
- `lib/screens/stats_screen.dart` — "Your app habits" tile

#### Implementation approach
1. Drift sketch:
   ```dart
   class FeatureCounters extends Table {
     TextColumn get key => text()();
     IntColumn get value => integer().withDefault(const Constant(0))();
     DateTimeColumn get updatedAt => dateTime()();
     @override Set<Column> get primaryKey => {key};
   }
   ```
2. Closed enum:
   ```dart
   enum FeatureCounterKey {
     exportTapped, recapViewed, themeChanged, onThisDayOpened,
     moodSelectorUsed, widgetOpened, notificationOpened,
   }
   ```
3. `AnalyticsService.bump` performs `INSERT OR REPLACE` with `value = value + 1`.
4. Wire call sites from an in-code grep list to avoid drift.
5. Kill switch (11.13) short-circuits `bump()` when off.

#### Test plan
- Unit: first `bump` inserts; second `bump` increments.
- Unit: kill switch off → bump is a no-op (11.13 dependency).
- Integration: tapping "Export my data" increments `exportTapped` exactly once.

#### Acceptance criteria
- [ ] Schema migration tested
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (counter keys are non-PII enum values)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.4

#### Dependencies
- Blocks: 11.11, 11.13
- Blocked by: none
- External: Epic 6 (instrumented integration paths)

---

## Task 11.5 — Per-step onboarding timestamps

**Source:** A11 finding "Onboarding funnel has no step instrumentation" · **Rating:** Buildable
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
`UserSettingsTable.onboardingComplete` is a single final-state boolean. Age gate, consent, PIN setup, first-entry time-to-complete are invisible — funnel drop-off is unmeasurable.

#### Root cause (what isn't measurable and why)
One boolean is insufficient to characterize a 4-5 step flow. Each step needs a completion timestamp.

#### Privacy design
- **What leaves the device?** Nothing by default.
- Columns are nullable timestamps; null = not reached. No free text.
- Anonymized export (11.11) emits millisecond deltas between consecutive steps, not wall-clock times.

#### Files touched
- `lib/services/database_service.dart` — add nullable `ageGateCompletedAt`, `consentCompletedAt`, `pinSetupCompletedAt`, `firstEntryCompletedAt` to `UserSettings`
- `lib/services/migration_strategy.dart` — v`N→N+1` migration (default NULL)
- `lib/screens/onboarding/age_gate_page.dart` — stamp on submit
- `lib/screens/onboarding/consent_page.dart` — stamp on accept
- `lib/screens/onboarding/pin_setup_page.dart` — stamp on confirm
- `lib/screens/home/home_screen.dart` (or first-save path) — stamp on first save if null
- `lib/services/export_service.dart` — derived `onboardingFunnel` block

#### Implementation approach
1. Add columns to `UserSettingsTable`; migration sets all to NULL.
2. At each step's success callback: `settingsRepo.update(..CompletedAt: DateTime.now())` iff currently null (idempotent).
3. Export adapter computes `age_gate_ms`, `consent_ms`, `pin_setup_ms`, `first_entry_ms` deltas from `users.createdAt` (Task 11.1). If any step is null in export, emit null.

#### Test plan
- Unit: step stamp is idempotent (second call doesn't overwrite).
- Migration: existing completed users get all NULLs (correct — we don't fake historical timings).
- Integration: full onboarding walkthrough produces 4 non-null stamps in order.

#### Acceptance criteria
- [ ] Schema migration tested
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (deltas only)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.5

#### Dependencies
- Blocks: 11.11
- Blocked by: 11.1 (anchor `createdAt`)
- External: Epic 6 (onboarding integration test captures stamps)

---

## Task 11.6 — Local `recap_feedback` table (thumbs up/down)

**Source:** A11 finding "AI recap effectiveness has no feedback loop" · **Rating:** Undefined
**Priority:** P2 · **Effort:** S · **Tier:** v1.1 (lands ahead of Gemini Nano)

#### Problem
`RecapService` (`lib/services/recap_service.dart:21-100`) produces AI-style recaps today via template; Gemini Nano and cloud models follow. No signal exists for "was this recap any good?" so tuning before model swap is impossible.

#### Root cause (what isn't measurable and why)
No feedback affordance, no storage. Once Gemini Nano ships, the window to retro-collect baseline "template-era" feedback closes.

#### Privacy design
- **What leaves the device?** Nothing by default.
- Schema stores: `recap_id` (FK to local `recaps`), `rating` (enum up/down/dismissed), `created_at`, `variantTag` (e.g. "template", "nano", "cloud"). **Never** the recap body, never the source entry text.
- Export (11.11) emits only aggregate counts in `recapFeedback`. Bodies, prompts, entry references never leave the device.

#### Files touched
- `lib/services/database_service.dart` — new `RecapFeedback` table
- `lib/services/migration_strategy.dart` — v`N→N+1` migration
- `lib/services/recap_service.dart` — `recordFeedback(recapId, RecapFeedbackRating rating, String variantTag)`
- `lib/screens/recap_screen.dart` — thumbs up / thumbs down UI (with a dismiss), keyboard accessible, 48dp targets
- `lib/services/export_service.dart` — aggregated counts block

#### Implementation approach
1. Drift sketch:
   ```dart
   class RecapFeedback extends Table {
     IntColumn get id => integer().autoIncrement()();
     IntColumn get recapId => integer()();
     TextColumn get rating => text()();       // 'up' | 'down' | 'dismissed'
     TextColumn get variantTag => text()();   // 'template' | 'nano' | 'cloud'
     DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
   }
   ```
2. Ship with `variantTag = 'template'` until Gemini Nano lands; the tag is non-PII.
3. UI: inline "Was this helpful?" row, one-tap toggle. Subtle, not guilt-inducing. Non-blocking.

#### Test plan
- Unit: `recordFeedback` writes a row; idempotent on the same (recapId, rating) pair.
- Widget: thumbs-up tap posts a single row and updates tint.
- Integration: no network traffic — CI assertion.

#### Acceptance criteria
- [ ] Schema migration tested
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (recap bodies never serialized)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.6

#### Dependencies
- Blocks: future Gemini Nano rollout comparison
- Blocked by: none
- External: Epic 7 (UX copy for "Was this helpful?"), Epic 12 (when cloud AI arrives, re-consent covers feedback emission)

---

## Task 11.7 — Deterministic local variant bucketer (on-device A/B)

**Source:** A11 finding "A/B testing readiness zero" · **Rating:** Undefined
**Priority:** P3 · **Effort:** S · **Tier:** v1.1

#### Problem
No remote config, no feature flag, no bucketing. On-device A/B for onboarding copy, default theme, default notification cadence is impossible — so pre-launch copy choices are picked by taste.

#### Root cause (what isn't measurable and why)
No stable-per-install identifier is hashed into a bucket, and no registry of experiments exists.

#### Privacy design
- **What leaves the device?** Nothing by default.
- `installUuid` is generated at first launch, stored in SQLCipher DB only. It is **never exported raw**.
- `bucketFor(experimentKey)` = `sha256(installUuid + experimentKey).first2bytes mod variantCount`. Deterministic, no server round-trip.
- Exported (11.11) only as short variant tags (`"onboarding_copy_b"`), one hop removed from the UUID.
- The opt-in export sheet has a secondary toggle: "Include which variants you saw" (default OFF). If OFF, variants omitted.

#### Files touched
- `lib/services/database_service.dart` — `UserSettings.installUuid` column (nullable, backfill on upgrade)
- `lib/services/migration_strategy.dart` — v`N→N+1` backfill with `Uuid().v4()`
- `lib/services/variant_bucketer.dart` (new) — pure function `variantFor(experimentKey, variants)`
- `lib/config/experiments.dart` (new) — registry of experiment keys and variant lists
- Consumers (future): `lib/screens/onboarding/*`, theme defaults

#### Implementation approach
1. On first launch, `UserRepository.ensureDefaultUser()` writes `installUuid = const Uuid().v4()`.
2. `VariantBucketer.variantFor('onboarding_copy_v1', ['a', 'b'])` returns `'a'` or `'b'` deterministically.
3. Registry ships initially with no live experiments — infrastructure only.
4. Kill switch (11.13) forces control variant.

#### Test plan
- Unit: same UUID + key → same variant across runs (determinism).
- Unit: distribution over 10k UUIDs is within ±3% of uniform.
- Unit: kill switch off → always returns variants[0].

#### Acceptance criteria
- [ ] installUuid generated on first launch and persisted
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles and never emits raw installUuid (only derived variant tag, behind secondary opt-in toggle)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.7

#### Dependencies
- Blocks: any future copy/defaults A/B
- Blocked by: 11.1 (same migration window is cheapest)
- External: Epic 12 (confirm variantUuid handling in privacy policy if ever questioned)

---

## Task 11.8 — Locally correlate mood with engagement ("You write more on good days")

**Source:** A11 finding "Mood data excellent qualitative retention signal, not correlated with engagement" · **Rating:** Measurable
**Priority:** P3 · **Effort:** M · **Tier:** v1.1

#### Problem
Mood 1-5 distribution (`stats_service.dart:294-331`) is shown in isolation. The signal "you write more / longer / more often on good days" is never computed — a premium-feeling insight left on the table.

#### Root cause (what isn't measurable and why)
All the data is already on-device (`entries.mood`, `entries.createdAt`, word count). It is simply not joined into a correlation.

#### Privacy design
- **What leaves the device?** Nothing by default.
- Computation is pure local aggregation. No new persistent storage.
- Export (11.11) already emits `moodDistribution` and `counts.entriesPerActiveDay`; this task reuses both — no new PII surface.

#### Files touched
- `lib/services/stats_service.dart` — `MoodEngagementCorrelation computeMoodEngagement()`
- `lib/models/stats_snapshot.dart` — optional new field
- `lib/screens/stats_screen.dart` — "Mood × writing" tile

#### Implementation approach
1. Group entries by `mood`, compute mean word count and entries/day for each bucket.
2. Produce a single human-readable sentence: "You write 2.3x more on 4-5 mood days."
3. Suppress display when sample per bucket < 5 to avoid noisy claims.

#### Test plan
- Unit: synthetic dataset with known mood/count distribution yields expected ratio.
- Unit: low-sample guard returns null insight.
- Golden: stats tile renders or is hidden depending on sample size.

#### Acceptance criteria
- [ ] Correlation computed on-device only
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (reuses existing blocks)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.8

#### Dependencies
- Blocks: none
- Blocked by: 11.3 (entriesPerActiveDay as denominator)
- External: Epic 7 (copy review for insight wording)

---

## Task 11.9 — De-scope caregiver metrics (explicit no-op)

**Source:** A11 finding "Caregiver metrics dropped from v1" · **Rating:** Undefined
**Priority:** P3 · **Effort:** XS · **Tier:** v2

#### Problem
Caregiver/Retraq Care tier was cut from v1 (see `memory/project_feature_decisions.md`). Any metric designed for it would be dead code plus a legal-surface risk (per Agent 12 findings on substitute decision-making).

#### Root cause (what isn't measurable and why)
The feature does not exist. Measuring it is meaningless until the backend controllership model is decided (which Agent 12 flagged as needing outside counsel).

#### Privacy design
- **What leaves the device?** Nothing — nothing to emit.
- Explicit architectural note in `docs/audit-2026-04-16-analytics.md` (or the repo's architecture docs) stating: "No caregiver-specific counters are recorded. Revisit only when the Retraq Care tier has a signed DPA, capacity-attestation flow, and Epic 12 sign-off."

#### Files touched
- `docs/` — architecture note (no code change)
- This plan file — reference

#### Implementation approach
1. Add a short section titled "Not measured: caregiver" to the architecture doc.
2. Block any PR that adds a counter prefixed `caregiver_*` via a lint rule or CODEOWNERS gate.

#### Test plan
- N/A (documentation task). Lint-rule smoke-test for the prefix ban.

#### Acceptance criteria
- [ ] Doc note added
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (no new surface)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore(privacy):` prefix referencing Task 11.9

#### Dependencies
- Blocks: nothing until v2 caregiver tier is re-opened
- Blocked by: nothing
- External: Epic 12 (feature is legally blocked anyway)

---

## Task 11.10 — Minimal pre-monetization metric: `purchased_at − installed_at`

**Source:** A11 finding "Revenue analytics premature" · **Rating:** Undefined
**Priority:** P3 · **Effort:** XS · **Tier:** v1.1

#### Problem
Full revenue analytics (MRR, churn, LTV) is premature — v1 ships free. But when v1.1 paid lands, the one signal that will matter most, "time from install to first purchase," is easy to wire today via a single column.

#### Root cause (what isn't measurable and why)
No purchase state exists yet; RevenueCat is not wired. A column reservation now avoids another migration at the worst moment (paywall launch).

#### Privacy design
- **What leaves the device?** Nothing by default.
- Stores only `firstPurchaseAt` epoch in SQLCipher; no receipt text, no SKU, no price.
- Export (11.11) emits `tier` ("free" / "premium") and derived `daysFromInstallToPurchase` — never the timestamp.

#### Files touched
- `lib/services/database_service.dart` — add `UserSettings.firstPurchaseAt` (nullable)
- `lib/services/migration_strategy.dart` — v`N→N+1` migration
- Future hook point documented: `lib/services/purchase_service.dart` (does not exist yet) will stamp on first successful purchase

#### Implementation approach
1. Column migration only. No call sites yet.
2. Short doc note in the future `purchase_service.dart` TODO: "on first successful purchase, set `firstPurchaseAt` iff null; do not update on restore."

#### Test plan
- Migration test: column added, defaults NULL.
- Doc-only PR review for call site expectations.

#### Acceptance criteria
- [ ] Column added and migrated
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (no timestamp emitted)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.10

#### Dependencies
- Blocks: future RevenueCat wiring (so it's ready)
- Blocked by: 11.1 (installedAt needed for the delta)
- External: Epic 12 (subscription disclosure UI lands in parallel)

---

## Task 11.11 — `exportAnonymizedStats()` via existing `ExportService` (opt-in "Help improve Retraq")

**Source:** A11 finding "Export service already schema-versioned — perfect vehicle for opt-in stats" · **Rating:** Buildable
**Priority:** P2 · **Effort:** M · **Tier:** v1.1

#### Problem
`ExportService` (`lib/services/export_service.dart:19-32`) already supports schema-versioned JSON export for full data portability. An anonymized variant stripping entry text/labels and keeping only counts/timestamps/settings/tier would be the only compliant opt-in analytics channel.

#### Root cause (what isn't measurable and why)
The infrastructure exists for a full export. A stripped variant requires a new builder and a clearly distinct user-facing entry point so users never confuse "share my whole journal" with "share anonymous stats."

#### Privacy design
- **What leaves the device?** Only what the user hands to the OS share sheet, and only after a visible scrub preview.
- Shape and stripped fields: see top-of-file shared spec.
- No auto-send, no network client, no background job. Must be invoked by a tap on a clearly-labeled "Help improve Retraq (optional)" row in Settings → Data.
- Default file name: `retraq_anonymized_stats_<YYYY-MM-DD>.json`.
- Copy uses the "anti-obligation" tone from the brand guide: "Completely optional. Nothing here identifies you."

#### Files touched
- `lib/services/export_service.dart` — `Future<File> exportAnonymizedStats()`
- `lib/services/stats_export_builder.dart` (new) — pure function assembling the JSON
- `lib/screens/settings/data_section.dart` — new row below full export
- `lib/screens/settings/help_improve_sheet.dart` (new) — scrub preview sheet
- `lib/l10n/app_en.arb` + peers — localized copy

#### Implementation approach
1. `StatsExportBuilder.build()` pulls counts (11.3), counters (11.4), funnel (11.5), recap feedback (11.6), variant (11.7, if opt-in secondary toggle on), `firstPurchaseAt` delta (11.10).
2. Scrub preview sheet renders the JSON in-app with syntax highlighting; user taps "Share" to hand it to the OS.
3. The file is written to the app cache dir and deleted after share intent completes (or after 10 minutes) — same hygiene as the existing export.

#### Test plan
- Unit: builder produces spec-compliant shape, no PII fields present (schema-validated in test).
- Unit: with variant toggle OFF, `variantBucket` key is absent.
- Integration: tapping "Help improve Retraq" never triggers a network socket (CI `HttpOverrides` fake).
- Golden: the preview sheet visually matches expected layout.

#### Acceptance criteria
- [ ] Builder emits spec-compliant JSON; schema test guards against new PII leaks
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (body/title/labels/names/tokens/UUID — verified by test)
- [ ] Scrub preview shown before share
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.11

#### Dependencies
- Blocks: 11.13 (kill switch UI sits above this row)
- Blocked by: 11.1–11.7, 11.10 (data sources)
- External: Epic 12 (privacy policy should add a single paragraph describing the opt-in export — non-blocker since default is still "nothing")

---

## Task 11.12 — Notification-open instrumentation for smart-nudge tuning

**Source:** A11 finding "Widget/notification engagement not measurable" · **Rating:** Buildable
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
`widget_service.dart` and `notification_service.dart` can send nudges but have no signal for "did it work?" — smart-nudge tuning is blind.

#### Root cause (what isn't measurable and why)
Launch-from-notification intents are not marked. There is no `notification_opened_at` write on the resulting cold start.

#### Privacy design
- **What leaves the device?** Nothing by default.
- New column `notification_opened_at` (last one wins) or a compact log table `(sent_at, opened_at, kind)` depending on desired fidelity; lean toward the latter with a 90-day TTL.
- `kind` is a closed enum: `daily_nudge`, `streak_reminder`, `on_this_day`. No notification body, no per-user template text.
- Export (11.11) emits `notifications: { sent, opened }` counts only.

#### Files touched
- `lib/services/database_service.dart` — new `NotificationEvents` table (or columns on existing `Nudges`)
- `lib/services/migration_strategy.dart` — v`N→N+1` migration
- `lib/services/notification_service.dart` — stamp `sent_at` on schedule, `opened_at` on intent
- `lib/services/widget_service.dart` — analogous `widget_tapped_at`
- `lib/main.dart` — intent extraction to route `opened_at` stamp
- `lib/services/export_service.dart` — rollup

#### Implementation approach
1. Drift sketch:
   ```dart
   class NotificationEvents extends Table {
     IntColumn get id => integer().autoIncrement()();
     TextColumn get kind => text()();
     DateTimeColumn get sentAt => dateTime()();
     DateTimeColumn get openedAt => dateTime().nullable()();
   }
   ```
2. On schedule: insert row with `sentAt` and null `openedAt`.
3. On launch-from-intent: find most recent matching row within last 6h and set `openedAt = now()`.
4. TTL pruning: `DELETE WHERE sent_at < now() - 90d` on cold start.

#### Test plan
- Unit: scheduling a nudge inserts a row; simulated open stamps it.
- Unit: unopened rows age out at 90d.
- Integration: no network egress (CI assertion).

#### Acceptance criteria
- [ ] Schema migration tested
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (counts only; `kind` is a closed enum)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `feat(stats):` prefix referencing Task 11.12

#### Dependencies
- Blocks: 11.11 (`notifications` block)
- Blocked by: 11.4 (shared analytics facade)
- External: Epic 6 (notification integration test)

---

## Task 11.13 — Analytics kill switch ("Keep usage stats") in Settings → Data

**Source:** A11 finding "No analytics kill switch" · **Rating:** Measurable
**Priority:** P2 · **Effort:** XS · **Tier:** v1.1

#### Problem
Once local counters, sessions, and funnel stamps exist, users deserve a single toggle to stop writing them. Not just for privacy posture — it strengthens the brand promise and gives the kill switch a meaningful surface the user can point to.

#### Root cause (what isn't measurable and why)
No setting, no gate. Every analytics writer must check a central flag.

#### Privacy design
- **What leaves the device?** Nothing by default. Kill switch only controls local writes; network emission was already impossible.
- Default: ON (writes enabled). The kill switch is clearly labeled: "Keep usage stats on this device. Never sent anywhere. Controls your local counters only."
- When OFF: `AnalyticsService.bump`, `startSession`, onboarding-step stamps, recap feedback, and notification-event writes all no-op. Existing rows are retained (user can re-enable without data loss) but can be purged via the existing "Delete all data" path.
- Kill switch state itself is stored in `UserSettings`; never exported.

#### Files touched
- `lib/services/database_service.dart` — `UserSettings.keepUsageStats` (bool, default true)
- `lib/services/migration_strategy.dart` — v`N→N+1` backfill default true
- `lib/services/analytics_service.dart` — short-circuit when false
- `lib/screens/settings/data_section.dart` — new toggle row
- `lib/l10n/app_en.arb` — copy

#### Implementation approach
1. Add setting. Migration defaults to true (preserves existing implicit behavior).
2. `AnalyticsService.isEnabled()` is read once per write call from cached settings; flip is immediate.
3. Toggle OFF shows a neutral confirmation: "Usage stats are now paused. Nothing is ever sent."
4. Toggle OFF also disables the "Help improve Retraq" row (Task 11.11) — no point exporting stale data.

#### Test plan
- Unit: switching off stops `bump`, `startSession`, stamps, notification-event writes (one test each).
- Widget: toggle renders under Settings → Data.
- Integration: toggle OFF + tap "Help improve Retraq" → export row is hidden / disabled.

#### Acceptance criteria
- [ ] Toggle persists across app restarts
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles and is gated by this toggle
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore(privacy):` prefix referencing Task 11.13

#### Dependencies
- Blocks: none
- Blocked by: 11.2, 11.4, 11.5, 11.6, 11.12 (so there is something to gate)
- External: Epic 7 (copy), Epic 12 (privacy policy can reference toggle)

---

## Task 11.14 — "On This Day" year-one recurrence engagement — explicit no-schema-work

**Source:** A11 finding "'On This Day' year-one recurrence engagement will emerge organically" · **Rating:** Measurable
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
"On This Day" views will measurably kick in at the 12-month install anniversary regardless — engagement should emerge from `entries.createdAt` alone. Building dedicated schema for it would over-engineer.

#### Root cause (what isn't measurable and why)
Nothing is missing. The moment an entry's creation date matches "today minus N years," a surface appears. The counter work from Task 11.4 (`onThisDayOpened`) is sufficient to measure engagement.

#### Privacy design
- **What leaves the device?** Nothing by default.
- Explicit architectural note: "Do not add `on_this_day_*` columns. Measurement handled via `FeatureCounterKey.onThisDayOpened` (Task 11.4)."

#### Files touched
- `docs/` — short architecture note
- This plan file — reference

#### Implementation approach
1. Architecture-doc paragraph only. No code change.
2. Reuse 11.4 counter at the "On This Day" tap handler.

#### Test plan
- N/A. Smoke test that tapping the "On This Day" row increments `onThisDayOpened` — that test already belongs to Task 11.4.

#### Acceptance criteria
- [ ] Doc note added
- [ ] Privacy policy line unchanged — no telemetry leaves device by default
- [ ] Opt-in anonymized export scrubs all entry text/titles (no new surface)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore(privacy):` prefix referencing Task 11.14

#### Dependencies
- Blocks: none
- Blocked by: 11.4 (counter reuse)
- External: none
