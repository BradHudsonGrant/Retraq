# Retraq

Your memory backup. Jot your day in seconds. Built with Flutter.

## Features

- **Quick journaling** — AM/PM or all-day entries with rotating prompts
- **Mood tracking** — Optional 5-level emoji scale with stats
- **Recap** — Browse by week/month, search with highlighting, weekly summaries
- **Stats** — Streaks, trends, mood distribution, milestones
- **Security** — PIN lock, biometric unlock, SQLCipher encryption, FLAG_SECURE
- **Tablet layouts** — Adaptive two-pane UI on large screens
- **Home screen widget** — Android widget showing streak and mood
- **Premium** — RevenueCat integration for subscription features
- **Accessibility** — Semantics, reduce motion, 48dp targets, live regions
- **i18n ready** — Full ARB extraction, gen-l10n pipeline

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Testing

```bash
flutter test
```

293 tests covering services, models, screens, and widgets.

## Architecture

```
lib/
  models/          # JournalEntry, UserSettings, User
  services/        # DatabaseService (facade), EntryRepository, SettingsRepository,
                   #   UserRepository, StatsService, ExportService, etc.
  providers/       # SettingsProvider, PremiumProvider (InheritedWidget)
  screens/         # HomeScreen, RecapScreen, StatsScreen, SettingsScreen
  widgets/         # atoms/ molecules/ organisms/ (design system)
  theme/           # AppTheme, AppColors, AppSpacing, AppText
  utils/           # DateHelpers, AdaptiveLayout, JournalPrompts
  l10n/            # ARB files + generated localizations
```

## Tech Stack

- **Database:** Drift (SQLite) + SQLCipher encryption
- **State:** InheritedWidget + Stream subscriptions
- **Payments:** RevenueCat (purchases_flutter)
- **CI/CD:** GitHub Actions (test, build AAB/IPA, release)

## Targets

- Android (primary — Pixel 10 Pro test device)
- iOS (secondary)
