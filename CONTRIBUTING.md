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
- Run `flutter test` before pushing. 445+ tests should pass.
- Pre-existing failures tracked in `docs/external-blockers.md#d-4`.

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
