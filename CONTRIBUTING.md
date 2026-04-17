# Contributing

Retraq is a pre-v1 Flutter app. The rules here exist to keep the
codebase honest as we scale the contributor pool.

## Before you start

- Run `flutter pub get` and `flutter gen-l10n` once after cloning.
- Use the pinned Flutter version in `.fvmrc`. Version drift has cost
  us time before (see `docs/external-blockers.md#d-7`).
- All PRs target `main`. No long-lived feature branches.

## Widget taxonomy

When adding a widget under `lib/widgets/`, place it in the right layer:

- **Atom** (`atoms/`) — leaf widget. No other atoms or molecules
  inside. No business logic. Only primitive or style-layer props.
  Examples: `retraq_button.dart`, `bionic_text.dart`, `glow_box.dart`.

- **Molecule** (`molecules/`) — composes 2+ atoms, may hold local
  visual state (hover/focus/toggled), **zero** repository access. Data
  comes from the parent via constructor args. Examples:
  `mood_selector.dart`, `segmented_pill.dart`, `entry_card.dart`.

- **Organism** (`organisms/`) — composes molecules and atoms, may
  consume DI services and streams, cannot be placed inside another
  organism. Examples: `edit_entry_sheet.dart`, `nudge_card.dart`,
  `calendar_grid.dart`.

**Decision guide:** if the widget reads from `DatabaseService.instance`
or a repository, it's an organism. If it composes only our atoms and
just takes data in, it's a molecule. If it's a leaf with no other
Retraq widgets inside, it's an atom.

See [`docs/widget-taxonomy.md`](docs/widget-taxonomy.md) for the long
form with worked examples and FAQ.

## Localization

- User-facing strings go through ARB (`lib/l10n/app_en.arb`) and
  `L10n.of(context)!`, never inline.
- Include an `@key` metadata block with a `description` so translators
  have context.
- Run `flutter gen-l10n` after editing ARB. The generated files are
  checked in.

## SnackBars

Use `AppSnackBar.show(context, message)` or `AppSnackBar.error(context,
message)` (see `lib/widgets/atoms/app_snack_bar.dart`). Do not
reconstruct the styling inline. The one exception in the codebase —
the success-colored biometric-enabled toast in `security_section.dart` —
is commented as such.

## Tests

- Every new widget with non-trivial behavior gets a widget test.
- Every new ARB key gets covered by at least one test pumping the
  widget with a non-default locale.
- Run `flutter test` before pushing. 525+ tests should pass
  (the session-wide Epic 6 expansion added ~170 cases; see
  `docs/plans/epic-06-testing.md`).
- Pre-existing failures tracked in `docs/external-blockers.md#d-4`.

### Test harness patterns (Task 6.19 + 6.26)

Use the helpers in `test/test_helpers.dart` — do NOT build your
own `MaterialApp` root in a widget test unless you have a
specific reason:

- **`wrapWidget(child)`** — MaterialApp + l10n delegates + Scaffold
  + reduce-motion MediaQuery. Default for most widget tests.
- **`wrapScreen(child)`** — same without the Scaffold, for widgets
  that bring their own (LockScreen, SplashScreen).
- **`wrapScrollable(child)`** — wraps in SingleChildScrollView for
  tall widgets (WeekDayList) that overflow the 600px test viewport.
- **`flushDriftTimers(tester)`** — call at the end of any test that
  subscribes to a Drift stream. Drains `StreamQueryStore` zero-
  duration timers that would otherwise trigger "pending timers"
  warnings.
- **`setUpFakeSecureStorage()`** — mocks the FlutterSecureStorage
  MethodChannel only; SQLite stays real. If you're tempted to
  mock SQLite too, don't — the "real DB + mock platform channels"
  line is what makes our migration tests meaningful.

New tests should use `find.byKey(TestKeys.foo)` (see
`lib/utils/test_keys.dart`) rather than `find.text('...')` for
tappable surfaces. Key-based finders survive ARB edits, rebranding,
and theme changes.

If you MUST bypass a helper, add an inline comment explaining why
(e.g., `// direct pumpWidget — this test asserts MaterialApp itself`)
so the pattern is auditable during reviews.

## Commits and pushes

- Conventional commit prefixes: `feat`, `fix`, `refactor`, `chore`,
  `docs`, `test`, `perf`, `legal`.
- Reference the Task number in the commit body where relevant
  (e.g. `Task 1.7`).
- Direct commits to `main` are the current flow. No `--amend` on
  pushed commits without explicit confirmation.

## Security

- No network calls (enforced by `no_network_invariant_test.dart`).
- Never commit `SENTRY_DSN`, keys, or anything that should live in
  `GitHub Secrets`.
- See `docs/external-blockers.md` for the full "needs a human"
  checklist.

## Protected surfaces (do not regress)

Some UX choices are load-bearing for the Retraq promise and are NOT
up for iteration without an explicit product decision. Changing
these surfaces requires an issue + discussion before any PR lands.

- **Hero save flow** (`lib/screens/home_screen.dart` hero-prompt
  area, single TextArea, auto-save, haptic save overlay) — "open,
  write, done" is the core promise. Do not add mandatory fields,
  extra confirmation dialogs, or mid-flow modal interruptions.
  Reference: Epic 4 Task 4.10 (Agent 4 ship-it rating).
- **3-checkbox consent flow** (`lib/screens/onboarding/consent_page.dart`)
  — legally required under PIPEDA / Apple 1.3 / FTC neutral age
  screen. Don't simplify to a single "I agree" or auto-tick any
  row. Reference: Epic 4 Task 4.17, Epic 12 Tasks 12.3 / 12.5.
- **"Data Not Collected" v1 privacy posture** — no analytics / no
  telemetry. Any SDK addition that changes this triggers the v1.1
  privacy-label rewrite (see
  [`docs/store-listing/privacy-labels-v1.1.md`](docs/store-listing/privacy-labels-v1.1.md))
  and cannot be bundled with unrelated work.
- **Local-only storage**
  (`lib/services/database_service.dart` SQLCipher path) — never
  add a cloud sync shim in v1. The zero-network invariant is the
  defining differentiator. Reference: Epic 3 Task 3.10 (v2 gate).

If you propose a change that brushes up against one of these
surfaces, open an issue first and link it from the PR.
