# Retraq

Your memory backup. Jot your day in seconds. Built with Flutter.

Tagline: "Lost traq? Retraq."

## Features

- **Quick journaling** — AM/PM or all-day traqs with rotating hero prompts;
  one tap to type, one tap to save.
- **Mood tracking** — Optional 5-level scale with on-device stats (mood is
  opt-in and off by default).
- **Recap** — Browse by week/month, full-text search with FTS5 + highlighting,
  weekly summary card, "on this day last year" recurrence.
- **Stats** — Streaks, trends, weekly activity, mood distribution, milestones.
- **Security** — Optional PIN lock with PBKDF2 v3 hashing, biometric unlock,
  SQLCipher AES-256 database encryption, unconditional FLAG_SECURE
  (screenshot / Recents thumbnail blocking on Android regardless of PIN).
- **Tablet layouts** — Adaptive two-pane UI on large screens.
- **Home-screen widget** — Android widget showing streak + recent mood.
- **Accessibility** — WCAG 2.1 AA target (contrast fixes landing across
  Epic 7), Semantics labels, reduce-motion respect, 48dp touch targets,
  typed-"DELETE" destructive confirmations, undo snackbar on save.
- **Privacy-first** — Zero network calls. Zero analytics. Zero telemetry.
  Data never leaves the device unless the user exports it. CI-guarded
  no-network invariant (see Task 12.1).
- **i18n ready** — Full ARB extraction, `gen-l10n` pipeline. Currently
  English-only; locale scaffolding is in place.

## Setup

Scripts live at `app/scripts/`:

```bash
./scripts/setup.sh        # install deps, generate code, run analyze
./scripts/build-android.sh  # release APK + AAB
./scripts/build-ios.sh      # release IPA (macOS only)
```

Or manually:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run
```

Flutter version is pinned at **3.41.6** (`.fvmrc`); CI enforces the match
(Task 10.3).

## Testing

```bash
flutter test                         # unit + widget tests
flutter test integration_test/       # end-to-end (Android emulator)
```

445+ unit/widget tests covering services, models, screens, and widgets;
migration data-loss regression pinned; security tests for PIN v1→v3
upgrade, lockout + clock-rewind, destructive-migration guard (Task 1.1).

## Architecture

```
app/
├── lib/
│   ├── models/            JournalEntry, UserSettings, User
│   ├── services/          DatabaseService (facade), EntryRepository,
│   │                      SettingsRepository, UserRepository, StatsService,
│   │                      ExportService, NotificationService, WidgetService,
│   │                      ScreenSecurityService, PinService
│   ├── providers/         SettingsProvider (InheritedWidget; Task 1.13
│   │                      migration pending)
│   ├── screens/           HomeScreen (Jot), RecapScreen, StatsScreen,
│   │                      SettingsScreen, LockScreen, OnboardingScreen,
│   │                      SplashScreen
│   ├── widgets/           atoms/ molecules/ organisms/ (atomic design;
│   │                      see docs/widget-taxonomy.md for layer rules)
│   ├── theme/             AppTheme, AppColors, AppSpacing, AppText,
│   │                      AppMotion (reduce-motion-aware)
│   ├── utils/             DateHelpers, AdaptiveLayout, JournalPrompts,
│   │                      TestKeys
│   ├── legal/             PrivacyPolicy, TermsOfService, HealthDisclaimer
│   │                      (with consent versioning for re-consent flow)
│   └── l10n/              ARB files + generated localizations
├── test/                  Unit + widget tests
├── integration_test/      End-to-end tests
├── scripts/               setup.sh, build-android.sh, build-ios.sh
├── docs/
│   ├── plans/             Per-epic implementation plans
│   │                      (epic-01 … epic-13, 260 tasks)
│   ├── external-blockers.md  External action items for the user
│   ├── legal/             Legal-attestation artifacts
│   └── store-listing/     App Store / Play Console listing copy
├── .github/workflows/     CI (analyze, test, coverage, smoke builds,
│                          integration tests) + release (tag-driven,
│                          signed Android, unsigned iOS pending Task 10.2)
├── implementation_plan.md Authoritative roadmap
├── CONTRIBUTING.md        Widget taxonomy, commit conventions, testing
├── CHANGELOG.md           Release notes — feeds App Store / Play "What's New"
└── README.md
```

For contribution guidelines (widget layer rules, ARB hygiene, the
AppSnackBar helper, etc.), see [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Tech stack

- **Database:** Drift (SQLite) with SQLCipher AES-256 encryption + FTS5
  full-text search.
- **State:** pure `StatefulWidget` + `Stream` subscriptions + one
  `InheritedWidget` (`SettingsProvider`).
- **Security:** PBKDF2-HMAC-SHA256 v3 hashing (100K iterations, 16-byte
  salt, constant-time verify), hardened `FlutterSecureStorage`,
  unconditional `FLAG_SECURE`, `allowBackup=false`, `data_extraction_rules`
  excluding all, clock-rewind-safe lockout.
- **CI/CD:** GitHub Actions, SHA-pinned third-party actions, coverage
  floor gate, tag-driven release pipeline with real Android signing.
  iOS TestFlight automation is pending (Task 10.2).

## Targets

- **Android:** primary (Pixel 10 Pro test device; broader device matrix
  testing pending pre-launch).
- **iOS:** secondary (build pipeline in place; signed release automation
  pending Task 10.2).

## Roadmap

The authoritative roadmap is [`implementation_plan.md`](implementation_plan.md).
Per-epic task plans live in [`docs/plans/`](docs/plans/). External-input
items for the user live in [`docs/external-blockers.md`](docs/external-blockers.md).

## License

See [LICENSE](LICENSE).
