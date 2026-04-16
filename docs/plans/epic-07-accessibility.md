# Epic 7 — Accessibility & Internationalization

Source: review-2026-04-16.md §Agent 7

> **Contrast math notes.** Light surface `0xFFF8FAF8` has relative luminance L ≈ 0.9517. Dark surface `0xFF121412` has L ≈ 0.00616. Ratios below use the WCAG formula `(L1 + 0.05) / (L2 + 0.05)`. Alpha compositing `αC_fg + (1-α)C_bg` is applied per channel before computing luminance for "faint-text" findings. All before/after hex values include the computed ratio against the surface color actually used at that site.
>
> **Agent 2 coordination.** Tasks 7.3 / 7.4 / 7.5 / 7.9 / 7.10 / 7.11 all localize user-facing strings and therefore overlap Agent 2's i18n workstream. To avoid duplicate commits, Epic 7 owns all "hardcoded-string-despite-ARB-key-existing" L10n fixes (Failing WCAG 3.1.2 for mis-declared locale); Agent 2 owns net-new ARB keys for strings with no existing key. Cross-reference Epic 2 tasks in each task's "Dependencies" section.

---

## Priority summary

- **P0 (v1 launch blocker — Failing WCAG):** 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
- **P1 (v1 launch — Improvable, user-visible):** 7.7, 7.8, 7.9, 7.10, 7.11, 7.12
- **P2 (v1.1 — Improvable, polish):** 7.13, 7.14, 7.15, 7.16
- **P3 (v2 / backlog):** 7.17 (RTL locale), 7.18 (AppMotion lint)
- **No-op reference entries (Accessible):** 7.19 – 7.26

---

## v1 (Failing → must pass WCAG 2.1 AA before launch)

### Task 7.1 — Raise faint hint-text contrast to WCAG 1.4.3 AA

**Source:** A7 finding "`onSurfaceVariant` alpha 0.55 hint text ~3.5:1 on light surface 0xFFF8FAF8" · **Rating:** Failing
**WCAG:** 1.4.3 Contrast (Minimum) — body text ≥ 4.5:1
**Priority:** P0 · **Effort:** S · **Tier:** v1

#### Problem
Hint and placeholder text across Home, journal text area, and edit sheet is rendered at `onSurfaceVariant` (`0xFF3D4543`, L ≈ 0.0655) with `withOpacity(0.55)`. Composited over light surface `0xFFF8FAF8` (L ≈ 0.9517) the effective foreground is ≈ `0x828987` → ratio ≈ 3.53:1, which **fails** WCAG 1.4.3's 4.5:1 floor for body-size text.

#### Root cause
A single `alpha = 0.55` was applied uniformly to `onSurfaceVariant` to create a visual "hint" treatment. The base token was darkened once (per the comment in `app_colors.dart:36`) to pass at α = 0.70, but multiple call sites still use α = 0.55.

#### Files touched
- `lib/theme/app_theme.dart:77-79` — `InputDecorationTheme.hintStyle` alpha 0.55 → 0.75
- `lib/screens/home_screen.dart:551` — prompt-hint opacity 0.55 → 0.75
- `lib/screens/home/journal_text_area.dart:141` — hint colour opacity 0.55 → 0.75
- `lib/widgets/organisms/edit_entry_sheet.dart:154,221` — two call sites, raise to 0.75
- `test/a11y/contrast_test.dart` — new helper + test (see Test plan)

#### Implementation approach
1. Add constant `AppTheme.hintAlpha = 0.75` near the theme builders; replace the four numeric `0.55` literals with it.
2. Verify math: `onSurfaceVariant` `0xFF3D4543` at α = 0.75 over `0xFFF8FAF8`:
   - R: 0.75·0x3D + 0.25·0xF8 ≈ 0x6F
   - G: 0.75·0x45 + 0.25·0xFA ≈ 0x76
   - B: 0.75·0x43 + 0.25·0xF8 ≈ 0x74
   - Resulting ≈ `0x6F7674` → L ≈ 0.176 → contrast vs surface ≈ **4.58:1** (passes 1.4.3 AA).
3. Do NOT touch dark-mode values — dark `onSurfaceVariant` `0xFFC4CAC8` at α = 0.55 over `0xFF121412` already gives ≈ 5.1:1 (passes); keep to avoid dark-mode regressions.
4. Cross-check: confirm no usage relies on the 0.55 look for decorative purposes (search for `withOpacity(0.55)`).

#### Test plan
- Add `test/a11y/contrast_test.dart` with a `_contrastRatio(Color fg, Color bg, {double alpha = 1.0})` helper (WCAG formula).
- Assert `_contrastRatio(AppColors.lightScheme.onSurfaceVariant, AppColors.lightScheme.surface, alpha: 0.75) >= 4.5`.
- Golden test: render Home screen with no-entry hint at text scale 1.0 and 2.0; compare.
- Manual: TalkBack on Pixel 10 Pro — confirm hint text is announced (Semantics unchanged, but visually pass).

#### Acceptance criteria
- [ ] WCAG 1.4.3 met: ratio ≥ 4.5:1 at every updated site.
- [ ] All four file sites changed; no remaining `withOpacity(0.55)` on `onSurfaceVariant`.
- [ ] `flutter test test/a11y/contrast_test.dart` passes.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` prefixed `fix(a11y): raise hint alpha to 0.75 for 1.4.3 AA (Task 7.1)`.

#### Dependencies
- Blocks: 7.13 (CalendarGrid "easy-tap" mode also touches alpha heuristics).
- External: none.

---

### Task 7.2 — Fix PageIndicatorDots contrast to WCAG 1.4.11

**Source:** A7 finding "Inactive page indicator dots at alpha 0.3 fail 3:1" · **Rating:** Failing
**WCAG:** 1.4.11 Non-text Contrast — UI components ≥ 3:1
**Priority:** P0 · **Effort:** XS · **Tier:** v1

#### Problem
`PageIndicatorDots` draws inactive dots using `colorScheme.onSurface.withOpacity(0.3)`. Light-mode `onSurface` `0xFF2D3432` at α = 0.30 over `0xFFF8FAF8` composites to ≈ `0xC5C7C6` → ratio vs surface ≈ **1.69:1**, failing 1.4.11's 3:1 floor for functional UI components.

#### Root cause
The 0.3 alpha was inherited from the earlier HTML prototype where the dot was purely decorative; it is now semantically meaningful (it conveys page position).

#### Files touched
- `lib/widgets/molecules/page_indicator_dots.dart:60` — change `withOpacity(0.3)` to `AppColors.lightScheme.outline` (i.e. the `outline` token).

#### Implementation approach
1. Replace inactive-dot colour with `Theme.of(context).colorScheme.outline` (both schemes).
2. Verify: light `outline` `0xFF757C7A` (L ≈ 0.188) vs surface `0xFFF8FAF8` → ratio ≈ **4.22:1** (passes 1.4.11 at 3:1 with headroom).
3. Dark `outline` `0xFF757C7A` vs surface `0xFF121412` → ratio ≈ **4.95:1** (passes).
4. Keep active-dot colour unchanged (`primary`).

#### Test plan
- Add contrast-test assertion in `test/a11y/contrast_test.dart`: inactive dot vs surface ≥ 3.0 in both schemes.
- Widget test: pump `PageIndicatorDots` at both brightnesses; assert inactive paint colour equals `ColorScheme.outline`.
- Manual: swipe onboarding at max brightness outdoors; confirm inactive dot is visible.

#### Acceptance criteria
- [ ] WCAG 1.4.11 met: inactive dot ratio ≥ 3:1 light and dark.
- [ ] No alpha applied to the inactive-dot colour.
- [ ] Commit `fix(a11y): page indicator dots meet 1.4.11 (Task 7.2)`.

#### Dependencies
- None.

---

### Task 7.3 — Route `EntryActionMenu` through L10n

**Source:** A7 finding "`EntryActionMenu` hardcodes English despite ARB keys existing" · **Rating:** Failing
**WCAG:** 3.1.2 Language of Parts (content must match declared locale)
**Priority:** P0 · **Effort:** XS · **Tier:** v1

#### Problem
`entry_action_menu.dart:39,58,69,79` hardcodes English labels (Edit / Share / Delete and their semantics) even though `app_en.arb` already has the corresponding keys. On future non-en locales (or even an English variant like en-GB/en-CA reverting to en) the widget will display mis-localised text that conflicts with the declared page `Directionality` / `Locale` parent, violating 3.1.2.

#### Root cause
Widget predates the L10n scaffolding and was never migrated.

#### Files touched
- `lib/widgets/molecules/entry_action_menu.dart:39,58,69,79` — replace literals with `L10n.of(context).entryActionEdit` / `entryActionShare` / `entryActionDelete` and their semantics variants.
- `lib/l10n/app_en.arb` — verify `entryActionEdit`, `entryActionShare`, `entryActionDelete`, plus `*Semantics` exist; add missing ones.

#### Implementation approach
1. Audit ARB — `grep -n 'entryAction' lib/l10n/app_en.arb`.
2. For each literal in `entry_action_menu.dart:39,58,69,79`, swap for the ARB accessor.
3. Run `flutter gen-l10n`; fix generated-file imports.
4. If any string lacks a key, add one with `@@` metadata (description + placeholders) — coordinate with Agent 2 task list; prefer extending Epic 7 commit rather than creating a parallel Epic 2 commit.

#### Test plan
- Widget test pumping `EntryActionMenu` under `Localizations.override` for `en` — assert `find.text(l10n.entryActionEdit)` etc.
- `flutter gen-l10n --no-synthetic-package --output-dir lib/l10n/generated` must exit 0 with no diff.
- `dart analyze` clean.

#### Acceptance criteria
- [ ] No English string literals remain in `entry_action_menu.dart`.
- [ ] All three labels + their accessibility semantics come from L10n.
- [ ] `flutter gen-l10n` runs clean.
- [ ] Commit `feat(i18n): route EntryActionMenu through L10n (Task 7.3)`.

#### Dependencies
- Coordinate with Agent 2 i18n task (avoid duplicate ARB-key adds). Epic 7 owns this commit.

---

### Task 7.4 — Localize `WeekDayList` ("Today", "No entries")

**Source:** A7 finding "`WeekDayList` hardcodes 'Today', 'No entries'" · **Rating:** Failing
**WCAG:** 3.1.2 Language of Parts
**Priority:** P0 · **Effort:** XS · **Tier:** v1

#### Problem
`week_day_list.dart:104,124,173` hardcodes "Today" and "No entries" in English despite the app declaring it supports whatever `supportedLocales` eventually ships. Screen readers inherit the page locale, so the announcement will be wrong in non-en.

#### Root cause
Same as 7.3 — legacy widget not migrated.

#### Files touched
- `lib/widgets/organisms/week_day_list.dart:104,124,173` — replace literals with `l10n.todayLabel` / `l10n.noEntriesLabel`.
- `lib/l10n/app_en.arb` — add keys if missing: `todayLabel`, `noEntriesLabel`.

#### Implementation approach
1. Confirm presence of `todayLabel` in ARB; add if absent.
2. Replace literals and run `flutter gen-l10n`.
3. Make sure nothing else in `week_day_list.dart` still concatenates English date strings — prefer `DateFormat.yMMMMEEEEd(l10n.localeName).format(...)`.

#### Test plan
- Widget test: pump at `en` — assert `find.text(l10n.todayLabel)`.
- Widget test: pump under a stub `Localizations` with a custom `todayLabel` value; assert it renders.

#### Acceptance criteria
- [ ] No English literals remain.
- [ ] `flutter gen-l10n` clean.
- [ ] Commit `feat(i18n): WeekDayList reads Today/No entries from L10n (Task 7.4)`.

#### Dependencies
- Coordinate with Agent 2 (duplicate-finding #4 in PRIORITY ACTION LIST).

---

### Task 7.5 — Localize `MoodSelector` labels and semantics

**Source:** A7 finding "`MoodSelector` hardcodes 'Mood selector' despite ARB keys" · **Rating:** Failing
**WCAG:** 1.3.1 Info and Relationships + 3.1.2 Language of Parts
**Priority:** P0 · **Effort:** S · **Tier:** v1

#### Problem
`mood_selector.dart:55,212` hardcodes the group `Semantics(label: 'Mood selector')` and per-mood English labels even though ARB has `moodSelectorLabel`, `moodRough`…`moodAmazing`. Screen-reader users in non-en will hear English over a non-English app.

#### Root cause
Legacy Semantics string predates L10n wiring for Semantics.

#### Files touched
- `lib/widgets/molecules/mood_selector.dart:55,212` — replace with L10n accessors (`l10n.moodSelectorLabel`, `l10n.moodNameForLevel(level)`).
- `lib/l10n/app_en.arb` — add an `@moodNameForLevel` select-style ARB entry if not present.

#### Implementation approach
1. Add an ARB select placeholder:
   ```
   "moodNameForLevel": "{level, select, 1{Rough} 2{Meh} 3{Okay} 4{Good} 5{Amazing} other{Mood}}"
   ```
   with proper `@moodNameForLevel` metadata.
2. Use in Semantics label and in the displayed chip text.
3. Ensure the group `Semantics(container: true, label: l10n.moodSelectorLabel)` wraps the row.

#### Test plan
- `SemanticsTester` widget test: pump `MoodSelector`; assert `matchesSemantics(label: l10n.moodSelectorLabel)` on the root.
- Assert each mood button exposes its localized label via Semantics.
- Golden test at text scale 2.0.

#### Acceptance criteria
- [ ] Semantics and visible labels both sourced from L10n.
- [ ] TalkBack / VoiceOver announces correct strings in `en`.
- [ ] Commit `feat(i18n): MoodSelector labels via L10n select (Task 7.5)`.

#### Dependencies
- Coordinate with Agent 2.

---

### Task 7.6 — Localize home-screen hero prompts

**Source:** A7 finding "Hero prompt hardcodes despite ARB `heroPrompt0..6`" · **Rating:** Failing
**WCAG:** 3.1.2 Language of Parts
**Priority:** P0 · **Effort:** XS · **Tier:** v1

#### Problem
`home_screen.dart:187-195` defines `_heroPrompts` as a const English `List<String>` while `app_en.arb` already has `heroPrompt0`…`heroPrompt6`. First-run hero copy therefore bypasses L10n.

#### Root cause
`_heroPrompts` was seeded before the ARB keys were added and never removed.

#### Files touched
- `lib/screens/home_screen.dart:187-195` — delete the const list; read via `[l10n.heroPrompt0, l10n.heroPrompt1, … l10n.heroPrompt6]` built inside `build()`.
- `lib/l10n/app_en.arb` — verify all seven keys exist.

#### Implementation approach
1. Replace the const list with a helper method `List<String> _heroPrompts(AppLocalizations l10n) => [l10n.heroPrompt0, …];` called inside `build()`.
2. The random index selection stays unchanged.

#### Test plan
- Widget test: pump Home under `Localizations.override`; assert one of the seven ARB strings is rendered.
- Verify `grep -n '_heroPrompts' lib/screens/home_screen.dart` has no const list remaining.

#### Acceptance criteria
- [ ] No English literals for hero prompts in `home_screen.dart`.
- [ ] `flutter gen-l10n` clean.
- [ ] Commit `feat(i18n): hero prompts via L10n (Task 7.6)`.

#### Dependencies
- Coordinate with Agent 2 (same finding appears in PRIORITY ACTION #4).

---

## v1 (Improvable — P1 polish before launch)

### Task 7.7 — Raise backdated meta-text alpha

**Source:** A7 finding "Backdated meta text at alpha 0.5-0.6" · **Rating:** Improvable
**WCAG:** 1.4.3 Contrast (Minimum) — borderline for secondary text
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`week_day_list.dart:264,272,294` and `entry_detail_view.dart:147,156` render "backdated" / "edited" meta text at α ∈ {0.5, 0.6} of `onSurface` `0xFF2D3432`. At α = 0.5 over `0xFFF8FAF8`, composite ≈ `0x939694` → ratio ≈ **3.08:1** — borderline. At α = 0.6, ratio ≈ 3.76:1, still below 4.5:1.

#### Root cause
Meta text was deliberately de-emphasised with alpha rather than with a properly-tuned `onSurfaceVariant` at the compliant alpha.

#### Files touched
- `lib/widgets/organisms/week_day_list.dart:264,272,294` — α 0.5-0.6 → 0.75.
- `lib/widgets/organisms/entry_detail_view.dart:147,156` — same.

#### Implementation approach
1. Replace `withOpacity(0.5|0.6)` with `withOpacity(0.75)`.
2. Verify composite at 0.75: `onSurface` `0xFF2D3432` α 0.75 over `0xFFF8FAF8` ≈ `0x565A58` → ratio ≈ **6.6:1** (passes).

#### Test plan
- Extend `contrast_test.dart` to assert all meta-text uses pass at 4.5:1.
- Golden test: `EntryDetailView` with a backdated entry, default text scale.

#### Acceptance criteria
- [ ] All five sites at α ≥ 0.75.
- [ ] Contrast ≥ 4.5:1 in both schemes.
- [ ] Commit `fix(a11y): raise backdated meta text alpha to 0.75 (Task 7.7)`.

#### Dependencies
- Builds on 7.1's contrast helper.

---

### Task 7.8 — Fix calendar dimmed previous/next-month day contrast

**Source:** A7 finding "Calendar dimmed previous/next-month days at alpha 0.65" · **Rating:** Improvable
**WCAG:** 1.4.3 Contrast (Minimum)
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`calendar_grid.dart:255` fades out-of-month day cells with α = 0.65 on `onSurface`. Effective ratio ≈ 4.09:1 — below 4.5:1 for sighted readers who rely on seeing the number.

#### Root cause
Alpha was chosen for visual rhythm, not measured for contrast.

#### Files touched
- `lib/widgets/organisms/calendar_grid.dart:255` — swap `withOpacity(0.65)` → `Theme.of(context).colorScheme.outlineVariant` (darkened in 7.12) or `onSurfaceVariant` with α = 0.75.

#### Implementation approach
1. Use `outlineVariant` (post-7.12) since it semantically means "non-primary, muted border / de-emphasised element".
2. Re-check composite: post-7.12 light `outlineVariant` ≈ `0x8A9291` → ratio ≈ 3.15:1 vs surface. That still fails 1.4.3 for text. **Therefore use `onSurfaceVariant` at α = 0.75** for these day numbers (ratio ≈ 4.58:1). Keep `outlineVariant` only for borders / dividers.

#### Test plan
- Assert composite ratio ≥ 4.5:1 against light surface.
- Golden test: calendar showing first week of May with trailing April days dimmed.

#### Acceptance criteria
- [ ] Day-number text ratio ≥ 4.5:1.
- [ ] Visual distinction vs in-month days preserved (qualitative).
- [ ] Commit `fix(a11y): calendar dim-day contrast to 1.4.3 AA (Task 7.8)`.

#### Dependencies
- Interacts with 7.12 (outlineVariant base); must not rely on outlineVariant for day-number text.

---

### Task 7.9 — Localize `NudgeCard` ("Daily at {time}")

**Source:** A7 finding "`NudgeCard` hardcodes 'Daily at {time}'" · **Rating:** Improvable
**WCAG:** 3.1.2 Language of Parts
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`nudge_card.dart:72` formats English template `"Daily at $time"`. Non-en locales will see English plus an ambiguously-formatted time.

#### Root cause
No ARB placeholder key exists.

#### Files touched
- `lib/l10n/app_en.arb` — add `nudgeDailyAt` with `{time}` placeholder (type: Object, formatted as `TimeOfDay` by caller).
- `lib/widgets/organisms/nudge_card.dart:72` — replace literal with `l10n.nudgeDailyAt(formattedTime)`.

#### Implementation approach
1. ARB entry:
   ```
   "nudgeDailyAt": "Daily at {time}",
   "@nudgeDailyAt": { "placeholders": { "time": { "type": "String", "example": "9:00 AM" } } }
   ```
2. Format `TimeOfDay` using `MaterialLocalizations.of(context).formatTimeOfDay(...)` before passing in.

#### Test plan
- Widget test with mock `l10n.nudgeDailyAt` returning `'Täglich um {time}'`; assert render.

#### Acceptance criteria
- [ ] No English template string in `nudge_card.dart`.
- [ ] Time formatted per locale.
- [ ] Commit `feat(i18n): NudgeCard Daily-at placeholder (Task 7.9)`.

#### Dependencies
- None.

---

### Task 7.10 — Localize `NumberPad` fallback semantic labels

**Source:** A7 finding "`NumberPad` hardcodes fallback semantic labels" · **Rating:** Improvable
**WCAG:** 4.1.2 Name, Role, Value + 3.1.2
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`number_pad.dart:102` has an English fallback for the per-key Semantics label when a caller doesn't supply one — hidden from sighted users but announced to screen-reader users in the wrong language.

#### Root cause
Fallback predates ARB existence.

#### Files touched
- `lib/widgets/molecules/number_pad.dart:102` — read `l10n.numberPadKeyLabel(digit)` instead of hardcoded English.
- `lib/l10n/app_en.arb` — add `numberPadKeyLabel` with `{digit}` placeholder.

#### Implementation approach
1. ARB `"numberPadKeyLabel": "Number {digit}"` with placeholder metadata.
2. Inject `AppLocalizations.of(context)!` at build time.

#### Test plan
- SemanticsTester test: assert each digit button has a localized label.

#### Acceptance criteria
- [ ] Fallback reads from L10n.
- [ ] Commit `feat(i18n): NumberPad fallback semantic label via L10n (Task 7.10)`.

#### Dependencies
- None.

---

### Task 7.11 — Raise `MoodSelector` unselected-item opacity for low-vision users

**Source:** A7 finding "`MoodSelector` unselected opacity 0.4 hard for low-vision" · **Rating:** Improvable
**WCAG:** 1.4.11 Non-text Contrast + 1.4.6 Contrast (Enhanced) goodness
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`mood_selector.dart:119` dims unselected mood bubbles to α = 0.4. For low-vision users (including the elderly-persona target), that crosses below 3:1 against surface.

#### Root cause
Alpha picked by eye for a "chosen state pops" visual.

#### Files touched
- `lib/widgets/molecules/mood_selector.dart:119` — α 0.4 → 0.6; add `MediaQuery.highContrastOf(context)` branch to force α = 1.0 when high-contrast is on.

#### Implementation approach
1. `final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;`
2. `final unselectedAlpha = highContrast ? 1.0 : 0.6;`
3. Use `Opacity(opacity: unselectedAlpha, child: …)`.

#### Test plan
- Widget test with `MediaQueryData(highContrast: true)` — assert opacity 1.0.
- Contrast test: moodTeal (e.g. `0xFF4DB6AC`) at α = 0.6 over surface ≥ 3:1.

#### Acceptance criteria
- [ ] Default α = 0.6; α = 1.0 when `highContrast` flag set.
- [ ] Commit `fix(a11y): MoodSelector unselected 0.6 + highContrast (Task 7.11)`.

#### Dependencies
- None.

---

### Task 7.12 — Darken light-mode `outlineVariant` for functional borders

**Source:** A7 finding "`AppColors` light `outlineVariant` 0xFFACB3B1 on 0xFFF8FAF8 ~2.0:1 fails for functional borders" · **Rating:** Improvable
**WCAG:** 1.4.11 Non-text Contrast
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`app_colors.dart:39` sets light `outlineVariant` to `0xFFACB3B1` (L ≈ 0.430). Over surface `0xFFF8FAF8` (L ≈ 0.9517) that is only (0.9517 + 0.05) / (0.430 + 0.05) ≈ **2.09:1**, failing 1.4.11's 3:1 for UI borders.

#### Root cause
Light-mode companion was not independently tuned when dark-mode outlineVariant was fixed (see prior comment at `app_colors.dart:70`).

#### Files touched
- `lib/theme/app_colors.dart:39` — `outlineVariant: 0xFFACB3B1` → `0xFF8A9291`.
- `lib/theme/app_colors.dart` — add a comment matching the dark-mode one: "Darkened from 0xFFACB3B1 (~2.09:1) to meet WCAG 1.4.11 3:1; now ~3.15:1."
- `test/a11y/contrast_test.dart` — add assertion for both schemes.

#### Implementation approach
1. Target colour `0xFF8A9291` → L ≈ 0.282 → ratio vs `0xFFF8FAF8` ≈ (0.9517 + 0.05) / (0.282 + 0.05) ≈ **3.01:1** (just passes) — go one shade darker to leave headroom: `0xFF7F8786` → L ≈ 0.243 → ratio ≈ 3.44:1. Use **`0xFF7F8786`**.
2. Visually preview calendar grid, divider lines, Card borders — they will appear slightly heavier. Acceptable per Material guidance.

#### Test plan
- Contrast test passes at 3:1 both schemes.
- Golden test: Calendar grid + Settings list dividers.

#### Acceptance criteria
- [ ] New hex `0xFF7F8786` committed; ratio ≥ 3:1.
- [ ] All places that draw divider / border via `colorScheme.outlineVariant` verified.
- [ ] Commit `fix(a11y): darken light outlineVariant for 1.4.11 (Task 7.12)`.

#### Dependencies
- Blocks 7.8 (calendar dim-day task must use `onSurfaceVariant` for text, not `outlineVariant`).

---

## v1.1 (Improvable — polish, post-launch)

### Task 7.13 — Add "easy-tap" calendar mode (≥48dp inner cells)

**Source:** A7 finding "CalendarGrid 52px cell with 44x44 inner — under Material 48dp" · **Rating:** Improvable
**WCAG:** 2.5.5 Target Size (Level AAA; Material recommends 48dp)
**Priority:** P2 · **Effort:** M · **Tier:** v1.1

#### Problem
`calendar_grid.dart:233-234,302` renders 52px outer cells with a 44×44 inner hit target. Material guideline and Apple HIG both specify 48dp / 44pt minimum; the elderly/caregiver persona (documented in memory/project_feature_decisions.md) will struggle.

#### Root cause
Tight calendar layout optimized for small phones; no opt-in expanded mode.

#### Files touched
- `lib/widgets/organisms/calendar_grid.dart:233-234,302` — promote inner tap target to 48×48 behind a settings flag.
- `lib/services/settings_repository.dart` — add `easyTapCalendar: bool` column (Drift migration).
- `lib/screens/settings/preferences_section.dart` — add toggle "Easy-tap calendar".
- `lib/l10n/app_en.arb` — `easyTapCalendarTitle`, `easyTapCalendarSubtitle`.

#### Implementation approach
1. Add a `@JsonKey(defaultValue: false)` column via a Drift migration bump.
2. In `calendar_grid.dart`, read the setting; when true, outer cell 56px, inner 48×48 min.
3. Wire toggle in Preferences; default off.

#### Test plan
- Widget test: toggle on; assert `GestureDetector` hit-region ≥ 48×48 (use `tester.getSize`).
- Manual TalkBack navigation — still one focus per day.

#### Acceptance criteria
- [ ] Toggle ships in Settings → Preferences.
- [ ] Inner cell ≥ 48×48 when on.
- [ ] Migration runs clean on existing DB.
- [ ] Commit `feat(a11y): easy-tap calendar mode (Task 7.13)`.

#### Dependencies
- Requires Drift migration coordination (Epic 8 if DB schema changes are batched).

---

### Task 7.14 — Resolve `RetraqButton` double-Semantics announcement

**Source:** A7 finding "`RetraqButton` Semantics wraps inner FilledButton — possible double-announce" · **Rating:** Improvable
**WCAG:** 4.1.2 Name, Role, Value
**Priority:** P2 · **Effort:** XS · **Tier:** v1.1

#### Problem
`retraq_button.dart:99-116` wraps a `FilledButton` in a `Semantics(...)` that also sets `button: true` (implicitly or explicitly). Flutter's FilledButton already exposes `button` semantics, so some assistive-tech environments announce role twice.

#### Root cause
Defensive Semantics wrapper predates Material 3 FilledButton's correct default role.

#### Files touched
- `lib/widgets/atoms/retraq_button.dart:99-116` — either (a) wrap inner button in `ExcludeSemantics` and keep outer `Semantics(button: true, label: …)`, or (b) drop outer Semantics entirely and rely on FilledButton defaults + `tooltip:`.

#### Implementation approach
1. Prefer (a): outer `Semantics(button: true, enabled: onPressed != null, label: label)` around `ExcludeSemantics(child: FilledButton(...))`.
2. Verify with SemanticsTester that node count is exactly 1 at that subtree root.

#### Test plan
- SemanticsTester widget test: `tester.getSemantics(find.byType(RetraqButton))` → assert one action, one label.
- TalkBack manual verification on a sample button.

#### Acceptance criteria
- [ ] One semantic node per RetraqButton.
- [ ] Commit `fix(a11y): RetraqButton single semantics node (Task 7.14)`.

#### Dependencies
- None.

---

### Task 7.15 — Audit visible-text regression at text scale 2.0

**Source:** A7 finding "AppText body uses `height: 1.5`; forbids textScaleFactor overrides … Visual regression at scale 2.0 for nav labels/stat card" · **Rating:** Accessible (but recommendation flags visual audit)
**WCAG:** 1.4.4 Resize Text
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
Text scaling is honoured (`app_text.dart:9-13`), but the review flagged a visual audit need at scale 2.0 for nav labels and stat card.

#### Root cause
`NavigationBar` labels and `StatCard` are fixed-width components that may truncate at 2.0.

#### Files touched
- `test/golden/text_scale_2x_test.dart` — new golden suite.
- Any widget found to truncate gets `MinFontSize`/`FittedBox` or layout relaxation.

#### Implementation approach
1. Add goldens at `MediaQueryData(textScaler: TextScaler.linear(2.0))` for: `AppShell` (NavigationBar visible), Home, Stats (StatCard), Recap, Entry Detail.
2. Capture regressions; fix (typically by replacing fixed `Row` with `Wrap` or using `FittedBox`).

#### Test plan
- Golden tests at 1.0, 1.3, 2.0 text scale.
- Manual: Android "Largest" + Display size "Largest".

#### Acceptance criteria
- [ ] No truncation or overflow at 2.0 text scale on Home / Stats / Recap / EntryDetail.
- [ ] Commit `test(a11y): text-scale-2x goldens + fixes (Task 7.15)`.

#### Dependencies
- None.

---

### Task 7.16 — Raise `DeleteConfirmDialog` error-text contrast

**Source:** A7 finding "DeleteConfirmDialog typed 'DELETE' gate … Raise error text contrast" · **Rating:** Accessible (with minor recommendation)
**WCAG:** 1.4.3 Contrast (Minimum)
**Priority:** P2 · **Effort:** XS · **Tier:** v1.1

#### Problem
Error string inside `DeleteConfirmDialog` uses `colorScheme.error` on `surface`. `error` `0xFFA83836` over `0xFFF8FAF8` ≈ 4.7:1 — passes AA for normal text but borderline for the small typed-confirm helper text that sits at `bodySmall` size (below 14pt — large-text threshold doesn't apply, and 4.5:1 is the right floor, so it passes — marginal).

#### Root cause
Colour choice is correct but close to the line.

#### Files touched
- `lib/widgets/organisms/delete_confirm_dialog.dart` — either (a) use `onErrorContainer` on an error-container background for the helper text, or (b) enlarge helper text to `bodyMedium`.

#### Implementation approach
1. Option (b) is simpler: move helper text up to 14pt (`bodyMedium`). Contrast unchanged; size meets WCAG "large-text" exception so 3:1 would be enough.
2. Keep primary "DELETE" typed-input visually prominent.

#### Test plan
- Contrast test against surface.
- Golden test of the dialog.

#### Acceptance criteria
- [ ] Helper text readable at default system font size.
- [ ] Commit `fix(a11y): DeleteConfirmDialog error contrast & size (Task 7.16)`.

#### Dependencies
- None.

---

## v2 / backlog

### Task 7.17 — Add RTL locale and audit directional `EdgeInsets.only(left/right)` sites

**Source:** A7 finding "Only `en` locale; 3 incidental Directionality refs" · **Rating:** Improvable
**WCAG:** 1.3.1 Info and Relationships + 3.1.2 Language of Parts (for future RTL content)
**Priority:** P3 · **Effort:** XL · **Tier:** v2

#### Problem
`app_localizations.dart:94` supports only `en`. The app has ~3 incidental `Directionality` references and (per local grep) multiple `EdgeInsets.only(left/right)` padding sites that will not mirror under RTL. Shipping Arabic, Hebrew, Farsi, or Urdu is blocked until these are converted to `EdgeInsetsDirectional.only(start/end)`.

#### Root cause
App was authored LTR-first; no RTL locale in supportedLocales to force the issue.

#### Files touched (audit must cover ≥ these 5 known sites, plus full codebase sweep)
1. `lib/screens/stats_screen.dart:477` — `EdgeInsets.only(left: AppSpacing.lg)` → `EdgeInsetsDirectional.only(start: AppSpacing.lg)`.
2. `lib/screens/settings/preferences_section.dart:103` — same.
3. `lib/screens/settings/preferences_section.dart:120` — same.
4. `lib/widgets/organisms/entry_detail_view.dart:65` — `Alignment.centerRight` → `AlignmentDirectional.centerEnd`.
5. `lib/widgets/organisms/calendar_grid.dart:266` — verify `margin: EdgeInsets.only(top: 1)` is symmetric (OK) but audit neighbours.
6. `lib/screens/home_screen.dart:469` — `EdgeInsets.only(...)` block — inspect for left/right.
7. `lib/screens/legal_screen.dart:70,86` — audit.
8. All `Positioned(left: ..., right: ...)` usages — convert to `PositionedDirectional(start: ..., end: ...)`.
9. All `BorderRadius.only(topLeft/…)` → `BorderRadiusDirectional.only(topStart/…)`.
10. All `Row(children: [A, const Spacer(), B])` patterns are fine; `TextDirection`-sensitive icons (e.g., chevron-right) should be replaced with `Icons.chevron_right` + `Directionality.maybeOf(context)` flip, or with `Icons.arrow_forward_ios` inside a `Directionality`-aware wrapper.
- `lib/l10n/app_ar.arb` — new skeleton locale file (Arabic as smoke-test RTL).
- `lib/l10n/app_he.arb` — Hebrew optional.
- `lib/main.dart` — `supportedLocales` updated.

#### Implementation approach
1. Sweep codebase: `grep -rn "EdgeInsets.only" lib/` — replace `left:`/`right:` sites with `EdgeInsetsDirectional.only(start:|end:)`.
2. Sweep: `Positioned(`, `BorderRadius.only(`, `Alignment.center(Left|Right)`, `Alignment.(top|bottom)(Left|Right)`.
3. Add `app_ar.arb` as placeholder for RTL smoke-testing (can be machine-translated; real translation later).
4. Add RTL golden tests for Home, Stats, Calendar, Entry Detail using `Directionality(textDirection: TextDirection.rtl, …)`.
5. Document the policy in repo (`docs/i18n-rtl.md`).

#### Test plan
- Golden RTL tests for the four main screens.
- Widget test: force `Locale('ar')`; assert `Directionality.of(context) == TextDirection.rtl`.
- Manual review on Pixel 10 Pro with device language = Arabic.

#### Acceptance criteria
- [ ] No `EdgeInsets.only(left:|right:)` remain in `lib/` (grep returns zero).
- [ ] At least one RTL locale in `supportedLocales`; RTL goldens pass.
- [ ] `flutter gen-l10n` clean with ar ARB.
- [ ] Commit series `feat(i18n): RTL readiness sweep (Task 7.17 parts 1..N)`.

#### Dependencies
- Coordinate with Agent 2 (i18n workstream owns net-new locale addition).
- Depends on completion of 7.3 – 7.6, 7.9, 7.10 (hardcoded strings removed first).

---

### Task 7.18 — Add lint/analyzer rule to catch `AppMotion` bypasses

**Source:** A7 finding "`AppMotion.aware` across 14+ files … Add lint to catch bypasses" · **Rating:** Accessible (recommendation)
**WCAG:** 2.3.3 Animation from Interactions (AAA) + 2.2.2 Pause, Stop, Hide
**Priority:** P3 · **Effort:** S · **Tier:** backlog

#### Problem
Reduce-motion handling is centralized in `AppMotion.aware`/`.reduce`, but nothing prevents a contributor from using raw `AnimationController`/`TickerProviderStateMixin`/`.animate()` without gating.

#### Root cause
No custom lint.

#### Files touched
- `analysis_options.yaml` — add a custom rule or an `avoid_` pattern.
- New `tool/lint/no_raw_animation.dart` (custom_lint package) — flag unwrapped `AnimationController`, `flutter_animate` usage.
- Or simpler: a grep-based CI step in `ci.yml`.

#### Implementation approach
1. Cheapest path: CI step that greps for `AnimationController(` and whitelists files that also import `app_motion.dart`. Fail otherwise.
2. Richer path: `custom_lint` plugin with an AST visitor — defer.

#### Test plan
- Intentionally add a `AnimationController` to a throwaway file; assert CI fails.
- Remove; assert CI passes.

#### Acceptance criteria
- [ ] CI flags raw animation usage.
- [ ] Commit `chore(a11y): lint for AppMotion bypasses (Task 7.18)`.

#### Dependencies
- None.

---

## Accessible — reference entries (no-op in Epic 7)

These findings were rated **Accessible** in the review. They are tracked here for completeness per the "NO SKIPS" rule but require no code change.

### Task 7.19 — `EntryActionMenu` 48×48 tap area (reference)
**Source:** A7 finding "48x48 SizedBox enforced on EntryActionMenu" · **Rating:** Accessible
**WCAG:** 2.5.5 Target Size · **Tier:** no-op
Verification only: during 7.15 text-scale sweep, confirm tap target does not shrink below 48×48 at scale 2.0. No files touched.

### Task 7.20 — `PadButton` 72×72 tap area (reference)
**Source:** A7 finding "PadButton 72x72 exceeds WCAG 2.5.5" · **Rating:** Accessible
**WCAG:** 2.5.5 · **Tier:** no-op
No change. Retain size in visual refresh PRs.

### Task 7.21 — `ConsentPage` full-row InkWell (reference)
**Source:** A7 finding "ConsentPage 48x48 tap area + full-row InkWell" · **Rating:** Accessible
**WCAG:** 2.5.5 · **Tier:** no-op
No change. Good pattern.

### Task 7.22 — HomeScreen save undo (4s) (reference)
**Source:** A7 finding "HomeScreen save: haptic + overlay + 4s undo" · **Rating:** Accessible (with optional 8-10s configurable)
**WCAG:** 3.3.4 Error Prevention · **Tier:** no-op in v1
Reviewer suggested making undo duration configurable. De-scoped unless CX feedback requests it. Deferred to future UX backlog item outside Epic 7.

### Task 7.23 — `AppMotion.aware` across 14+ files (reference)
**Source:** A7 finding "AppMotion.aware across 14+ files" · **Rating:** Accessible · **Tier:** no-op (lint tracked as 7.18)
No direct code change. Lint work tracked as Task 7.18.

### Task 7.24 — `NudgeCard` body on primary ~7:1 (reference)
**Source:** A7 finding "NudgeCard body onPrimary on primary 0xFF33694B ~7:1" · **Rating:** Accessible
**WCAG:** 1.4.3 (exceeds AAA 7:1) · **Tier:** no-op
Do not regress `onPrimary` token without re-running contrast test.

### Task 7.25 — "Previously…" contextual recall (reference)
**Source:** A7 finding "'Previously...' contextual recall — memory-aid for early-memory-loss persona" · **Rating:** Accessible
**Cognitive design strength.** No change. Keep; note for marketing copy.

### Task 7.26 — Onboarding page-count Semantics (reference)
**Source:** A7 finding "Onboarding page count via `l10n.onboardingPageLabel` Semantics; ExcludeSemantics on decorative" · **Rating:** Accessible
**WCAG:** 1.3.1 · **Tier:** no-op
Use as reference pattern when adding new onboarding screens.

---

## Rollup

| Metric | Count |
|---|---|
| Total tasks (incl. reference no-ops) | 26 |
| Failing (P0, v1) | 6 (7.1 – 7.6) |
| Improvable, P1 v1 | 6 (7.7 – 7.12) |
| Improvable, P2 v1.1 | 4 (7.13 – 7.16) |
| Backlog / v2 (P3) | 2 (7.17, 7.18) |
| Accessible (no-op reference) | 8 (7.19 – 7.26) |

Commit prefixes: `fix(a11y):` for contrast / semantics, `feat(i18n):` for L10n routing, `test(a11y):` for test-only commits, `chore(a11y):` for lint/tooling. Every commit references its Task 7.N.
