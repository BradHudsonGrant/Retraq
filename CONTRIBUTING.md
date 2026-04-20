# Contributing

Retraq is a pre-v1 Flutter app. This file captures a few patterns worth
knowing before writing code here.

## Setup

- `flutter pub get` and `flutter gen-l10n` once after cloning.
- Use the Flutter version in `.fvmrc`. Version drift has caused pain before.
- Commits go to `main`; no long-lived feature branches.

## Widget layering (`lib/widgets/`)

- **atoms/** — leaf widgets. No other Retraq widgets inside, no business
  logic. Primitive or style-layer props only.
- **molecules/** — compose 2+ atoms. May hold local visual state
  (hover/focus/toggled). **No** repository access — data comes from the
  parent.
- **organisms/** — compose molecules and atoms. May consume services and
  streams. Not nested inside another organism.

Rule of thumb: if the widget reads from `DatabaseService.instance` or a
repository, it's an organism. If it composes atoms and takes data in, it's
a molecule. Leaf = atom.

See [`docs/widget-taxonomy.md`](docs/widget-taxonomy.md) for the long form.

## Localization

- User-facing strings go through `lib/l10n/app_en.arb` and
  `L10n.of(context)!` — never inline.
- Include a `description` in the `@key` block so translators have context.
- Run `flutter gen-l10n` after editing the ARB.

## SnackBars

Use `AppSnackBar.show(context, message)` or `AppSnackBar.error(...)` (see
`lib/widgets/atoms/app_snack_bar.dart`). Don't reconstruct the styling
inline.

## Tests

- Widget tests for anything with non-trivial behavior.
- Cover new ARB keys with at least one non-default-locale pump.
- `flutter test` before pushing.

### Test helpers — reach for these first

`test/test_helpers.dart` exposes four patterns. Use them instead of rolling
your own `MaterialApp` root:

- `wrapWidget(child)` — MaterialApp + l10n + Scaffold + reduce-motion. Default.
- `wrapScreen(child)` — same, without the Scaffold (for widgets that bring
  their own, e.g. LockScreen).
- `wrapScrollable(child)` — wraps in a `SingleChildScrollView` for tall
  widgets that overflow the 600px test viewport.
- `flushDriftTimers(tester)` — call at the end of any test that subscribes
  to a Drift stream, to drain `StreamQueryStore`'s zero-duration timers.
- `setUpFakeSecureStorage()` — mocks the FlutterSecureStorage MethodChannel.
  SQLite stays real on purpose; mocking both hides migration bugs.

Prefer `find.byKey(TestKeys.foo)` over `find.text(...)` for tappable
surfaces — keys survive copy edits and localization.

## Commits

Conventional prefixes (`feat`, `fix`, `refactor`, `chore`, `docs`, `test`,
`perf`). Keep messages short; explain *why* in the body when it's not
obvious. No `--amend` on pushed commits.

## Security

- No network calls — enforced by `test/no_network_invariant_test.dart`.
- Never commit `SENTRY_DSN`, keys, or anything that should live in GitHub
  Secrets.

## Protected surfaces — don't regress these without a discussion

A few UX choices are load-bearing for the Retraq promise:

- **Hero save flow** (`lib/screens/home_screen.dart`) — "open, write, done."
  No mandatory fields, no mid-flow modals, no extra confirmation dialogs.
- **3-checkbox consent flow** (`lib/screens/onboarding/consent_page.dart`)
  — legally required; don't collapse to a single "I agree" or auto-tick
  any row.
- **"Data Not Collected" privacy posture** — no analytics, no telemetry.
  Any SDK that changes this triggers the v1.1 privacy-label rewrite and
  cannot ride along with unrelated work.
- **Local-only storage** (SQLCipher path in `database_service.dart`) — no
  cloud sync in v1. The zero-network invariant is the differentiator.

If a change brushes against one of these, open an issue first.
