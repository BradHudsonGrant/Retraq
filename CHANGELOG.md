# Changelog

All notable changes to Retraq are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). This file
is the source of truth for App Store and Play Console "What's New"
copy — auto-generated release notes from git commits stay available
via GitHub Releases but are not shipped to stores.

The project uses [semantic versioning](https://semver.org/): MAJOR.MINOR.PATCH.

## [Unreleased]

### Added
- Widget taxonomy guide and `CONTRIBUTING.md` covering atoms / molecules /
  organisms layering rules, ARB hygiene, and the AppSnackBar helper.
- `AppLog` release-safe diagnostics wrapper over `dart:developer.log`
  with an opt-in `--dart-define=RETRAQ_LOG=true` release toggle and a
  test sink (future Sentry/Crashlytics adapter point).
- `AppSnackBar.show/error` helper centralising 20+ previously-inline
  SnackBar styling call sites.
- Plaintext-export "Share this file?" warning dialog before the OS
  share sheet receives an unencrypted journal copy.
- Warmer empty-state on Home when there are no recent traqs, with
  headline and low-pressure body copy.
- Discard-and-switch option on the AM/PM switch dialog for users who
  want to flip the period without saving accidental text.
- Reset-X on the date-override chip returns to today without reopening
  the picker.
- Nudge-card subtitle explaining the skip-if-already-journaled
  behaviour so users stop disabling the reminder under a false
  assumption.

### Changed
- **Security:** PIN hashes now use PBKDF2 with 250 000 iterations (v4).
  Existing v3 (100K) and v2 (600K) hashes auto-upgrade on next
  successful unlock.
- **Performance:** `getCurrentStreak` date window capped at 3.3 years
  — no correctness change, avoids scanning the full distinct-date
  set for users with many years of data.
- **Performance:** `WidgetService.update()` on save is explicitly
  fire-and-forget so the save-tap UI path isn't blocked by a
  platform-channel round-trip.
- **Performance:** Home screen caches total entry count via
  `watchTotalEntryCount()` instead of awaiting a fresh count query on
  every save.
- **UX:** Consent checkboxes during onboarding and reconsent now show
  a dedicated "View" button for the legal document — tapping the
  checkbox label toggles the box, closing a subtle consent-capture
  footgun.
- **UX:** Save-success overlay hold is dynamic: 400ms for routine
  saves after entry 10, 1000ms for milestone saves.
- **i18n:** Import summary SnackBar now uses ICU plurals across all
  three counters (imported, skipped, errors). Nudge card body copy
  and Change Time button also localized.
- **A11y:** MoodSelector unselected opacity raised to 0.6 (1.0 under
  high contrast). DeleteConfirmDialog error text lifted to 14pt.
  RetraqButton collapses to a single Semantics node.
- **Architecture:** `UserSettings` equality via `Equatable`.
  `JournalEntry.fromRawRow` factory shared between typed and
  FTS-search mappers (closes a latent drift that was dropping
  `userId` from search results).
- All 44 `debugPrint` sites in `lib/services/` migrated to `AppLog`.

### Fixed
- Android release builds now fail loud if no real keystore is
  configured, instead of silently falling back to the debug
  certificate.
- `FLAG_SECURE` is applied unconditionally (previously only when the
  app-lock PIN was set up).
- Lifecycle lock now triggers on `inactive` / `paused` / `hidden`,
  not only `resumed`.
- Narrowed 8 previously-bare `catch (_)` sites to typed `catch (e, st)`
  with `AppLog.warn`/`.error` so production failures are no longer
  silently swallowed.

### Security
- Raised PBKDF2 iterations from 100K → 250K. See "Changed" above.
- Documented controller disclosure and EU/Canada supervisory
  authority complaint routes in the privacy policy
  (PIPEDA/GDPR/UK ICO/CPPA/OAIC).
- Added mandatory consumer-law carve-outs to the Terms of Use
  (Quebec C.P.A., EU CRD, UK, California, Australia).
- `StatsService.onStreamError` et al. now route through `AppLog`
  so release-mode crash-adjacent diagnostics can be wired to a sink
  without touching callers.
- **Country-aware age gate** — onboarding now reads the device
  locale and enforces 13 / 14 / 16 as the minimum self-attestation
  age per COPPA (US/CA/GB/AU/NZ: 13), Quebec Law 25 (QC: 14), and
  GDPR Art. 8 member-state choices (DE/NL/FR/IT/LU/IE/RO/HU/HR/SI:
  16; AT/BG/CY/LT/ES: 14). Backed by a 13-country regulatory table
  with 12 unit tests. No IP geolocation — uses the platform's
  `Localizations.localeOf(context)` region only, keeping the
  zero-network promise.
- **CI health-claim lint (Task 12.5)** — builds now fail if any
  of six banned terms (`cure`, `treat`, `diagnose`, `FDA-approved`,
  `HIPAA-compliant`, `clinically proven`) appear in shipping
  surfaces. Five exempt paths cover the disclaimer files that
  legitimately negate these terms.
- **CI AppMotion bypass lint (Task 7.18)** — any file under
  `lib/screens/` or `lib/widgets/` declaring an `AnimationController`
  without referencing a reduce-motion guard fails the build.
  Honours WCAG 2.3.3 + 2.2.2.
- **CI SHA-pinning audit (Task 6.20)** — every GitHub Action in
  `.github/workflows/*.yml` must pin to a 40-char commit SHA,
  never `@v1` or `@main`. Guards against supply-chain attacks on
  unpinned actions.
- **CI l10n drift check (Task 10.9)** — PRs with stale
  `lib/l10n/app_localizations*.dart` (i.e., ARB edited without
  running `flutter gen-l10n`) now fail immediately instead of
  landing silent translation gaps.

### Testing
- Expanded the test suite from ~445 to **~617 cases** across Epic 6:
  - Direct `entry_repository` + `settings_repository` tests (+20)
  - Dedicated `pin_service_test.dart` extracted with async/isolate
    coverage (+25)
  - Timezone / DST edge cases for `date_helpers` (+17)
  - AppShell + SplashScreen smoke tests (+11)
  - Notification schedule-time math with DST coverage (+7)
  - All 6 Task 6.11 widget coverage gaps closed (MoodBlob,
    GlassCard, ThemeCard, WeeklyTrendChart, WeekDayList,
    AnimatedMeshBackground) (+45)
  - Concurrent-write race coverage for EntryRepository (+5)
  - ExportService real-invocation tests (import path) (+7)
  - Lockout post-timer expiry + doubled-window (+3)
  - Explicit v13→v14 migration assertions (+2)
  - 48dp touch-target accessibility verification (+6)
  - Task 1.9 Equatable props-length guard (+8)
  - AppLog test sink (+6)
  - Locale age threshold table (+12)
- **dart_test.yaml split** into unit + integration tags so the PR
  lane can run `--exclude-tags=integration` for fast feedback while
  the emulator lane runs integration-tagged journey tests.

### Strategy / documentation
- Full Epic 5 GTM cluster shipped: positioning one-pager +
  narrative hook + privacy narrative + five competitor battlecards
  (Daylio, Apple Journal, Inflow, Rosebud/Mindsera, Quick Journal)
  + Android-first launch rationale + engagement hook spec + share
  card visual brief + engagement copy review + trial-length
  decision & A/B plan + Day One price anchoring + Lifetime SKU
  decision + anti-dark-pattern paywall audit.
- Full Epic 9 store-listing cluster: categories + Play Health
  Apps declaration, health-claim red/yellow/green guardrails,
  iOS + Android + caregiver-uplift age rating, IAP posture
  (v1 free / v1.1 RevenueCat three-SKU), v1 launch plan (4-phase
  staged rollout), subtitle A/B test plan.
- Legal: AI transparency + Quebec PIA templates, Canadian entity
  disclosure template, forbidden-claims blocklist.
- Brand: sub-brand decision tree for v2 caregiver ("Retraq for
  Family" standalone recommendation), competitor visual-positioning
  battlecard.
- Analytics: architecture doc establishing the no-caregiver-metrics
  commitment and the "Help improve Retraq" opt-in-export exit door.

### Deferred / blocked
- **PR #22 (AGP 9.1.1)** — closed. Blocked upstream by Flutter
  3.41.6's Gradle plugin lacking AGP 9 support. Revisit when
  Flutter SDK ships AGP 9 compatibility.
- **B-24 Codecov token** — new external-blocker item. Codecov
  upload step landed (commit `8790891`) but is silent until the
  `CODECOV_TOKEN` secret is added to GitHub Secrets.

## [1.0.0+2] — 2026-04-14

Initial TestFlight / Play Internal Testing build. Core v1 feature
set:

- AM/PM or all-day traqs with rotating hero prompts.
- Optional 5-level mood scale (off by default).
- Full-text search via FTS5, weekly summary card, "on this day"
  recall.
- Stats: streaks, trends, weekly activity, mood distribution.
- Optional PIN lock with PBKDF2 v3 hashing + biometric unlock.
- SQLCipher AES-256 database encryption.
- Android home-screen widget showing streak + recent mood.
- Tablet two-pane adaptive layout.
- 100% local data; no network calls (enforced by
  `no_network_invariant_test.dart`).
