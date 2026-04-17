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
