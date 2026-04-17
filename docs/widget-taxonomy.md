# Widget taxonomy

Retraq's `lib/widgets/` tree is organized into three layers following Brad
Frost's atomic design. This page describes the rules for deciding which
layer a new widget belongs in and gives worked examples drawn from the
current codebase.

> **TL;DR** — Atoms are leaves. Molecules compose 2+ atoms and add tap/
> hover/focus interaction. Organisms compose molecules and atoms and are
> allowed to consume app-level state (repositories, streams, DI services).

---

## Layers

### Atoms (`lib/widgets/atoms/`)

**Rules**
- **No other atoms or molecules inside.** An atom is a leaf in the
  widget tree.
- **No business logic.** Atoms do not touch repositories, streams,
  services, or shared providers.
- **Primitive or style-layer props only.** They take colours, text
  styles, labels, and callbacks — not domain models.
- **Stateless unless animation requires a ticker.** `AnimationController`
  is allowed; app-level state is not.

**Examples**
- `app_snack_bar.dart` — static helper over `ScaffoldMessenger`.
- `bionic_text.dart` — bolds the start of each word in a `Text`. No
  services, no streams.
- `retraq_button.dart` — pill-shaped button with press-scale animation.
- `glow_box.dart`, `glass_card.dart`, `mood_blob.dart`, `particle_burst.dart`.

### Molecules (`lib/widgets/molecules/`)

**Rules**
- **Compose 2+ atoms** into a reusable interactive unit.
- **May hold local visual state** — hover, focus, toggled, animating.
- **Zero repository access.** They do not read from the database or
  any app-level stream directly. Parent widgets (usually organisms)
  feed them data as constructor args.
- **May contain small amounts of derived state** (e.g. "which segment is
  active"), but never authoritative app state.

**Examples**
- `mood_selector.dart` — a row of 5 mood atoms with local "isPressed"
  animation state, but the selection itself comes from props.
- `segmented_pill.dart` — left/right toggle atoms, active-ness passed in.
- `entry_card.dart` — composes text atoms + an action-menu molecule.
- `empty_recent_state.dart`, `number_pad.dart`, `weekly_trend_chart.dart`.

### Organisms (`lib/widgets/organisms/`)

**Rules**
- **Compose molecules and atoms** into a self-contained UI surface
  (sheet, card, dialog, full row of functionality).
- **May consume DI services, streams, and repositories** via
  `DatabaseService.instance`, `SettingsProvider.of(context)`, or future
  `get_it` lookups.
- **Cannot be placed inside another organism.** Organisms are
  page-level. If you find yourself nesting two organisms, the inner
  one probably wants to become a molecule instead.
- **Owns its own state for its feature slice** (e.g. edit sheet owns
  the draft buffer; overlay owns its animation lifecycle).

**Examples**
- `edit_entry_sheet.dart` — reads/writes via `DatabaseService.instance`.
- `save_success_overlay.dart` — animation lifecycle, dismiss callbacks.
- `nudge_card.dart` — reads settings, triggers notification scheduling.
- `calendar_grid.dart`, `entry_detail_view.dart`, `week_day_list.dart`,
  `delete_confirm_dialog.dart`.

---

## FAQ

### How do I decide between "molecule" and "organism" when the widget
### needs both state AND composition?

Ask "who owns the data it renders?"
- If the parent always passes the data in via constructor, it's a
  **molecule**.
- If the widget reaches into `DatabaseService.instance` or a repository
  itself, it's an **organism**.

### My widget holds only visual state (hover, pressed). Molecule or atom?

**Atom** if it has no child widgets of its own from our codebase (it may
wrap primitive Flutter widgets like `GestureDetector`, `Padding`, etc).
**Molecule** if it composes 2+ of our atoms.

`PressableScale` is an atom — it wraps its child directly. `NudgeCard`
is an organism because it composes `GlowBox`, `BionicText`, `FilledButton`,
and localized text layouts, and reads `SettingsProvider`.

### What about services and repositories?

They live in `lib/services/`, not `lib/widgets/`. Only organisms may
import from `lib/services/`. A molecule or atom that imports a service
is a smell — extract the service call to the caller and pass data in.

### Where do screens fit?

Screens live in `lib/screens/` and are allowed to compose organisms
freely. Think of a screen as "an organism that happens to be routed to"
— same rules apply.

---

## See also

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — the short-form version of
  these rules for PR authors.
- Brad Frost's [Atomic Design](https://atomicdesign.bradfrost.com/chapter-2/)
  for the original taxonomy.
