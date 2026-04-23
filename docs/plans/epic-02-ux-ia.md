# Epic 2 — UX/UI & Information Architecture

Source: review-2026-04-16.md §Agent 2

Order: Barrier-rated (P0) → Friction P1 → Friction P2 → Delight no-ops (P3).
All 20 Detailed Findings rows from Agent 2's table get a task entry below — no skips.

---

### Task 2.1 — Localize mood selector labels and semantics

**Source:** A2 finding "Mood labels + semantics hardcoded" · **Rating:** Barrier
**Priority:** P0 · **Effort:** S · **Tier:** v1 launch

#### Problem
`_moodOptions` hardcodes English labels (`'Rough'/'Low'/'Neutral'/'Good'/'Amazing'`) and the Semantics wrapper uses a hardcoded `'Mood selector'` label. Non-English users see English mood labels and screen-reader announcements, breaking the polished localization elsewhere in the app. This is a Barrier because it excludes non-English and non-sighted non-English users from one of the app's signature interactions.

#### Root cause
`mood_selector.dart` was written before the ARB localization pass and was never revisited. Labels were defined as compile-time constants in `MoodOption` rather than looked up from `L10n`.

#### Files touched
- `lib/widgets/molecules/mood_selector.dart:25-31,55` — replace hardcoded label list and Semantics label with `L10n` lookups
- `lib/l10n/app_en.arb` — add `moodRough`, `moodLow`, `moodNeutral`, `moodGood`, `moodAmazing`, `moodSelectorLabel`
- `lib/l10n/app_*.arb` — add the same keys to every other locale ARB (translations can be stubbed; translator will fill)

#### Implementation approach
1. Convert `_moodOptions` from a top-level `const` list into a `static List<MoodOption> _options(L10n l10n)` helper inside `MoodSelector`, or read labels lazily inside `build`.
2. Call it from `build(context)` so labels are rebuilt when locale changes.
   ```dart
   final l10n = L10n.of(context)!;
   final options = [
     MoodOption(1, '\u{1F622}', l10n.moodRough),
     MoodOption(2, '\u{1F614}', l10n.moodLow),
     MoodOption(3, '\u{1F610}', l10n.moodNeutral),
     MoodOption(4, '\u{1F60A}', l10n.moodGood),
     MoodOption(5, '\u{1F929}', l10n.moodAmazing),
   ];
   ```
3. Replace `Semantics(label: 'Mood selector', ...)` with `Semantics(label: l10n.moodSelectorLabel, ...)`.
4. Add new ARB entries with `@`-metadata descriptions so translators have context.

#### Test plan
- Add/update `test/widgets/mood_selector_test.dart` — pump with a non-en locale and assert labels come from `L10n`.
- Add a Semantics test that asserts `l10n.moodSelectorLabel` is present on the container.
- Manual: switch device language to French on Pixel 10 Pro, open mood card, verify labels localize.

#### Acceptance criteria
- [ ] All 5 mood labels render from ARB across en + at least one other supported locale
- [ ] `Semantics` label on the selector container is localized
- [ ] `flutter analyze` clean, `flutter test` passes (445+ tests)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `fix(ux):` prefix referencing Task 2.1

#### Dependencies
- Coordinates with Epic 7 (accessibility/i18n) — Epic 7 owns the ARB hygiene pass; Task 2.1 supplies these specific keys. Land before Epic 7 closes out to keep the accessibility gap list clean.

---

### Task 2.2 — Localize Week/Month segmented pill labels on Recap

**Source:** A2 finding "Week/Month segmented pill labels hardcoded" · **Rating:** Barrier
**Priority:** P0 · **Effort:** XS · **Tier:** v1 launch

#### Problem
The Recap screen's primary view-toggle pill shows `'Week'` and `'Month'` in English regardless of device locale, breaking the localized experience at one of the app's top-level navigation points.

#### Root cause
Strings were inlined in `recap_screen.dart` when the SegmentedPill was first introduced; never migrated to ARB.

#### Files touched
- `lib/screens/recap_screen.dart:371-372` — replace string literals with `l10n.weekLabel` / `l10n.monthLabel`
- `lib/l10n/app_en.arb` + siblings — add `weekLabel`, `monthLabel` (check if already present; reuse if so)

#### Implementation approach
1. Grep `app_en.arb` for existing `week` / `month` keys — if present (e.g., already used on Stats), reuse.
2. Otherwise add `weekLabel` / `monthLabel` with `@`-metadata.
3. Update the two `leftLabel`/`rightLabel` args to `SegmentedPill`.

#### Test plan
- Widget test: pump RecapScreen with a non-en locale, assert SegmentedPill children render localized strings.
- Manual: switch locale, verify pill labels.

#### Acceptance criteria
- [ ] Pill labels render from `L10n` in every supported locale
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(ux):` prefix referencing Task 2.2

#### Dependencies
- Coordinates with Epic 7 (accessibility/i18n).

---

### Task 2.3 — Localize Stats week-tap snackbar with ICU plural

**Source:** A2 finding "Stats week-tap snackbar concatenates hardcoded plural" · **Rating:** Barrier
**Priority:** P0 · **Effort:** S · **Tier:** v1 launch

#### Problem
Tapping a bar on Stats shows a SnackBar built from English-concatenated string fragments: `'$range: $count $entries'` where `entries` is `count == 1 ? 'entry' : 'entries'`. This breaks localization and also violates ICU plural rules for languages with more than two plural forms (Russian, Arabic, Polish, etc.).

#### Root cause
The bar-tap interaction was added later than the rest of Stats' localization and predates the ICU-plural ARB helpers now used elsewhere.

#### Files touched
- `lib/screens/stats_screen.dart:81-91` — replace concatenation with single ICU-plural ARB lookup
- `lib/l10n/app_en.arb` + siblings — add `statsWeekTapMessage` with `{count, plural, ...}` ICU syntax embedding the date range

#### Implementation approach
1. Add ARB entry modeled on existing plural helpers:
   ```json
   "statsWeekTapMessage": "{range}: {count, plural, =0{no entries} =1{1 entry} other{{count} entries}}",
   "@statsWeekTapMessage": {
     "placeholders": {
       "range": {"type": "String"},
       "count": {"type": "int"}
     }
   }
   ```
2. Rewrite the SnackBar content:
   ```dart
   content: Text(l10n.statsWeekTapMessage(range, count)),
   ```
3. Drop the local `entries` variable.

#### Test plan
- Widget test: tap a bar with count=0, 1, 2, 5; assert SnackBar text matches expected plural form.
- Locale test: pump a locale with non-binary plurals (e.g., `ru`) and assert the plural picker is exercised.

#### Acceptance criteria
- [ ] SnackBar message built from single ARB call with ICU plural
- [ ] No string concatenation remains in `_onBarTap`
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(ux):` prefix referencing Task 2.3

#### Dependencies
- Coordinates with Epic 7 (accessibility/i18n).

---

### Task 2.4 — Show "Forgot PIN?" escape from the first failed attempt

**Source:** A2 finding "Forgot-PIN escape appears only after 2 full lockouts (~10 failed attempts)" · **Rating:** Barrier
**Priority:** P0 · **Effort:** XS · **Tier:** v1 launch

#### Problem
`lock_screen.dart:278` gates the "Forgot PIN?" button behind `_lockout.lockoutCount >= 2`, which means ~10 failed attempts (two full lockouts) before the escape hatch appears. For users who juggle multiple PINs and benefit from recognition over recall, this is a hard Barrier — users will uninstall before reaching the button.

#### Root cause
Defensive anti-brute-force instinct during original implementation. But the Forgot-PIN flow already requires a separate recovery challenge, so exposing the button early doesn't weaken security — it only removes a psychological cliff.

#### Files touched
- `lib/screens/lock_screen.dart:278-290` — change gate from `>= 2` lockouts to first failed attempt (or always-visible)

#### Implementation approach
1. Replace gate:
   ```dart
   if (_lockout.failedAttempts >= 1 || _lockout.lockoutCount >= 1)
     Padding(...)
   ```
   Or, simpler and kinder: always show the button once the user has begun entering a PIN (i.e., show unconditionally when lock screen is mounted for an existing user).
2. Verify `_lockout` exposes `failedAttempts`; if not, add a getter.
3. Keep the button styling muted (`alpha: 0.75`) so it doesn't dominate the first-impression lock screen.

#### Test plan
- Widget test: `testWidgets('Forgot PIN button visible after first failed attempt')` — mount lock screen, enter wrong PIN once, assert `find.text(l10n.forgotPin)` is found.
- Regression: existing lockout tests still pass.
- Manual on Pixel 10 Pro: enter one wrong PIN, confirm button visible and routes to recovery flow.

#### Acceptance criteria
- [ ] "Forgot PIN?" visible from first failed attempt (or unconditionally on mount for returning users)
- [ ] Forgot-PIN recovery flow unchanged and still functional
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(ux):` prefix referencing Task 2.4

#### Dependencies
- Blocked by: nothing. Blocks: nothing. External: none.

---

### Task 2.5 — Collapse Stats tab into Recap via segmented pill

**Source:** A2 finding "4 tabs instead of 3; Stats overlaps Recap's weekly_summary_card" · **Rating:** Friction
**Priority:** P1 · **Effort:** L · **Tier:** v1 launch

#### Problem
`AppShell` ships 4 bottom tabs (Jot / Recap / Stats / Settings) but Stats' bar chart + streaks duplicate insights already surfaced on Recap's `weekly_summary_card`. Four-tab navigation blurs IA, makes the bottom nav feel heavy, and forces users to remember "was that on Stats or Recap?"

#### Root cause
Stats was added as a separate surface during Epic 4; the weekly-summary card on Recap grew organically and eventually overlapped Stats content without Stats being consolidated.

#### Files touched
- `lib/screens/app_shell.dart:60-149` — remove Stats destination from NavigationBar; remove `StatsScreen` from PageView children; adjust `_currentIndex` arithmetic (3 tabs now)
- `lib/screens/recap_screen.dart` — add a SegmentedPill at the top (Entries / Insights) that swaps between the current recap body and an inlined Stats body
- `lib/screens/stats_screen.dart` — either convert to an embeddable `StatsBody` widget or inline relevant sections into Recap
- `lib/widgets/test_keys.dart` — drop `navStatsTab` key, keep `navJournalTab/navRecapTab/navSettingsTab`, add `recapEntriesInsightsPill` key
- `integration_test/` — update any test that taps the Stats tab

#### Implementation approach
1. Extract the body of `StatsScreen` into a reusable `StatsBody` StatelessWidget that takes no navigation responsibility.
2. In `RecapScreen`, add a segmented pill at the top:
   ```dart
   SegmentedPill(
     key: TestKeys.recapEntriesInsightsPill,
     leftLabel: l10n.entriesLabel,
     rightLabel: l10n.insightsLabel,
     isRightActive: _showInsights,
     onTapLeft: () => setState(() => _showInsights = false),
     onTapRight: () => setState(() => _showInsights = true),
   ),
   ```
3. Conditionally render `StatsBody` when `_showInsights == true`, else current Recap body.
4. Remove Stats destination from `NavigationBar.destinations` and from the PageView children. Re-index subsequent tabs.
5. Update `AppRouter` / deep-link handlers that referenced Stats index `2`.
6. Update ARB: add `entriesLabel`, `insightsLabel`.

#### Test plan
- Integration test: tap each of the 3 remaining tabs, assert correct pane renders.
- Integration test: on Recap, tap "Insights" pill, assert bar chart renders; tap "Entries", assert entries list renders.
- Update existing Stats-tab integration tests to route through the Recap pill.
- Manual on Pixel 10 Pro: verify bottom nav feels lighter, verify no dead code paths trigger.

#### Acceptance criteria
- [ ] Bottom nav shows 3 tabs (Jot / Recap / Settings)
- [ ] Recap screen exposes Entries/Insights pill with both panes functional
- [ ] All previously Stats-only widgets render inside Recap's Insights pane
- [ ] No references to `StatsScreen` as a top-level route remain
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(ux):` prefix referencing Task 2.5

#### Dependencies
- Blocks: any Epic 4 (feature) work that adds to Stats — it lands inside Insights pane after this task
- Blocked by: nothing
- External: none

---

### Task 2.6 — Detect prior consent and collapse onboarding intros for reinstalls

**Source:** A2 finding "Onboarding intros cannot be skipped by returning/reinstall users" · **Rating:** Friction
**Priority:** P1 · **Effort:** M · **Tier:** v1 launch

#### Problem
Users who already completed onboarding, then uninstalled/reinstalled (or migrated from an older build), are forced back through all 3 intro pages. Consent itself must remain gated by regulation, but the intros are pure marketing — forcing them is friction with no compliance benefit.

#### Root cause
Onboarding only checks `_ageVerifiedKey` in SharedPreferences (which resets on uninstall). No cross-install marker persists; no lightweight "returning-user" path exists.

#### Files touched
- `lib/screens/onboarding_screen.dart:83-114,270-283` — branch on a returning-user signal
- `lib/services/onboarding_service.dart` (or analog) — add an app-version marker stored in hardened secure storage (survives uninstall on Android with auto-restore, survives app updates)
- `lib/l10n/app_en.arb` + siblings — add a "Welcome back" string for the condensed path

#### Implementation approach
1. On onboarding mount, in addition to reading `ageDeniedSecureKey`, read a new `priorConsentVersionSecureKey` from hardened secure storage.
2. If present AND age-verified: advance `_controller.initialPage` past the 3 intro pages directly to the consent page (which is still required — do not auto-accept).
3. Render a subtle "Welcome back" header above the consent checkboxes in this branch.
4. On successful consent + finish, write current `consentVersion` to the secure marker.
5. Document in `docs/onboarding-flow.md` that the marker only shortens intros, never bypasses consent.

#### Test plan
- Widget test: mount with no prior marker → 5-page flow. Mount with marker + age verified → lands on consent page.
- Widget test: completing consent writes the marker.
- Manual: complete onboarding, force-stop + clear app data, restart → full flow. Then uninstall/reinstall on a device with auto-restore (if possible) → shortened flow.

#### Acceptance criteria
- [ ] Reinstall with restored secure storage skips intros, lands on consent
- [ ] Consent itself is still required (no silent acceptance)
- [ ] Fresh install unaffected (5-page flow)
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(ux):` prefix referencing Task 2.6

#### Dependencies
- Coordinates with Epic 3 (security/privacy) — the secure-storage key must not be considered PII; note in privacy review.
- Coordinates with Epic 12 (legal/compliance) — confirm that skipping intros while keeping consent gated satisfies Canadian PIPEDA notice requirements.

---

### Task 2.7 — Split consent checkbox from document link

**Source:** A2 finding "Consent underlined label opens full legal screen; implies 'tap to toggle'" · **Rating:** Friction
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
On the consent page, the underlined label next to each checkbox is wrapped in an `InkWell` that opens the full legal document. Users expect an underlined text next to a checkbox to be the label of that checkbox (tap-to-toggle). The current behavior accidentally navigates away when users try to check the box by tapping the text — a subtle but real consent-capture risk.

#### Root cause
The outer `InkWell` on the row toggles the checkbox, but the inner `InkWell` on the Text intercepts and routes to `onTapLink`. The underline decoration follows from the link styling.

#### Files touched
- `lib/screens/onboarding/consent_page.dart:216-247` — restructure row to separate label (checkbox toggle) from a visually distinct "View" affordance (document open)

#### Implementation approach
1. Remove the inner `InkWell` wrapping the `Text`. Let the outer row's `InkWell` remain the single tap surface for toggling the checkbox.
2. Add a small trailing `TextButton.icon` (icon: `Icons.open_in_new`, label: `l10n.viewLabel`) that calls `onTapLink`.
3. Remove `decoration: TextDecoration.underline` from the label text — it no longer functions as a link.
4. Add ARB key `viewLabel`.

#### Test plan
- Widget test: tap the text label → checkbox toggles; tap "View" → link callback fires; tap row whitespace → checkbox toggles.
- Manual: visually confirm the label no longer looks like a hyperlink.

#### Acceptance criteria
- [ ] Tapping the label (or row) toggles the checkbox and does not open the legal doc
- [ ] A separate, visually distinct affordance opens the legal doc
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(ux):` prefix referencing Task 2.7

#### Dependencies
- Coordinates with Epic 12 (legal/compliance) — confirm that a "View" button (rather than underlined inline link) still satisfies informed-consent UX guidance.

---

### Task 2.8 — Add "Discard and switch" option to AM/PM switch dialog

**Source:** A2 finding "AM/PM switch with typed text: dialog lacks 'Discard and switch' option" · **Rating:** Friction
**Priority:** P1 · **Effort:** XS · **Tier:** v1 launch

#### Problem
When user has typed text and switches AM/PM, dialog offers only Cancel / Save-and-Switch. The date-override chip's sibling flow offers Discard-and-Switch as a third option. The inconsistency is surprising, and forces users who made an accidental entry to save it before switching.

#### Root cause
The dialog was implemented before the date-chip's analogous three-action pattern was standardized; never back-ported.

#### Files touched
- `lib/screens/home_screen.dart:619-656` — add third action button to the dialog
- `lib/l10n/app_en.arb` + siblings — add `discardAndSwitchButton` key

#### Implementation approach
1. Add ARB entry `discardAndSwitchButton` (and optional `discardAndSwitchContent` if the body copy needs tweaking).
2. Update the dialog:
   ```dart
   actions: [
     TextButton(
       onPressed: () => Navigator.pop(ctx, 'cancel'),
       child: Text(l10n.cancelLabel),
     ),
     TextButton(
       onPressed: () => Navigator.pop(ctx, 'discard'),
       child: Text(l10n.discardAndSwitchButton),
     ),
     FilledButton(
       onPressed: () => Navigator.pop(ctx, 'save'),
       child: Text(l10n.saveAndSwitchButton),
     ),
   ],
   ```
3. Branch on the returned String: `'discard'` → clear controllers then switch; `'save'` → `_saveEntry` then switch; anything else → no-op.

#### Test plan
- Widget test: type text, tap AM/PM, verify three buttons present; tap Discard → controllers cleared, period flipped, no save; tap Save → entry saved, period flipped; tap Cancel → no change.
- Manual on Pixel 10 Pro.

#### Acceptance criteria
- [ ] Dialog presents three actions with the Discard option between Cancel and Save
- [ ] Each action produces the documented side effect
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(ux):` prefix referencing Task 2.8

#### Dependencies
- Blocked by: nothing.

---

### Task 2.9 — Add reset-X to the date-override chip

**Source:** A2 finding "Date chip override has only colored border as signal" · **Rating:** Friction
**Priority:** P1 · **Effort:** XS · **Tier:** v1 launch

#### Problem
When a user overrides the entry date, the chip shows `MMM d, yyyy` and swaps its border color to `cs.primary.withValues(alpha: 0.5)`. That's the only affordance — there's no explicit way to return to "today" short of opening the date picker and navigating back. Users have to remember that "subtle border color = overridden". Poor recognition, no clear escape.

#### Root cause
The chip was originally single-purpose (open picker); the override state was added without adding a reset action.

#### Files touched
- `lib/screens/home_screen.dart:232-270` — when `_selectedDate != null`, render a trailing close icon that resets to today

#### Implementation approach
1. Wrap `Chip` (or replace with a custom `InputChip` when override active) and add `onDeleted: _selectedDate != null ? () => setState(() => _selectedDate = null) : null` + `deleteIcon: Icon(Icons.close, size: 16)`.
2. Ensure `Semantics` label announces "Reset to today" for the close icon, localized via a new ARB key `resetToTodayLabel`.
3. Keep the border-color signal — the X is additive, not replacement.

#### Test plan
- Widget test: select a date, assert close icon visible and semantically labeled. Tap it, assert chip returns to default (no `_selectedDate`) and border returns to outlineVariant.
- Widget test: with no override, assert no close icon.
- Manual.

#### Acceptance criteria
- [ ] Override chip shows a tap-target X when active
- [ ] Tapping the X returns to today and removes the override styling
- [ ] Semantics labels the reset action, localized
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(ux):` prefix referencing Task 2.9

#### Dependencies
- Coordinates with Epic 7 (accessibility/i18n) for the new ARB key.

---

### Task 2.10 — Localize import summary SnackBar with full-sentence ARB

**Source:** A2 finding "Import summary SnackBar concatenates hardcoded fragments" · **Rating:** Friction
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
The import success SnackBar calls `l10n.importSuccess(imported, ...)` but two of its arguments are hardcoded English fragments — `', $skipped duplicates skipped'` and `', $errors errors'`. Non-English users see an English tail spliced into a localized lead. Also violates ICU plural rules.

#### Root cause
The ARB entry was authored with placeholder parameters rather than full-sentence variants, leading the caller to build English fragments for the "optional" parts.

#### Files touched
- `lib/screens/settings/data_section.dart:217-231` — call a new full-sentence ARB method instead of fragment concatenation
- `lib/l10n/app_en.arb` + siblings — replace `importSuccess` signature with one ICU-plural message per case, or a single `{select}` message covering the four permutations (skipped>0, errors>0, both, neither)

#### Implementation approach
1. Redesign ARB:
   ```json
   "importSuccess": "Imported {imported, plural, =1{1 entry} other{{imported} entries}}{skipped, plural, =0{} other{, {skipped} duplicate{skipped, plural, =1{} other{s}} skipped}}{errors, plural, =0{} other{, {errors} error{errors, plural, =1{} other{s}}}}"
   ```
   (Or split into four distinct keys selected in Dart — whichever the team's ARB style prefers.)
2. Rewrite caller:
   ```dart
   content: Text(l10n.importSuccess(imported, skipped, errors)),
   ```
3. Drop the two inline English fragments.

#### Test plan
- Widget test: invoke import with combinations (0/0, 1/0, 0/1, 3/2, 10/5) and assert the message in en matches expected English and in fr matches expected French.
- Edge: `imported=0` scenario.

#### Acceptance criteria
- [ ] No hardcoded English fragments in the import success path
- [ ] ICU plurals applied to all three counters
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(ux):` prefix referencing Task 2.10

#### Dependencies
- Coordinates with Epic 7 (accessibility/i18n) for ICU plural hygiene across all locales.

---

### Task 2.11 — Localize Stats "Statistics overview" and entry-preview semantics

**Source:** A2 finding "Stats 'Statistics overview' + 'Entry for $label: $entryPreview' semantics hardcoded" · **Rating:** Friction
**Priority:** P1 · **Effort:** XS · **Tier:** v1 launch

#### Problem
Screen reader users on non-English locales hear `"Statistics overview"` and `"Entry for Yesterday: <preview>"` in English while the visible labels are localized. Creates a jarring disconnect for VoiceOver/TalkBack users.

#### Root cause
Semantics labels were added during an accessibility pass before the ARB migration and not back-ported.

#### Files touched
- `lib/screens/stats_screen.dart:228` — replace `'Statistics overview'` with `l10n.statisticsOverviewSemantics`
- `lib/screens/home/recent_day_card.dart:47` — replace `'Entry for $label: $entryPreview'` with an `l10n.entryForSemantics(label, entryPreview)` call
- `lib/l10n/app_en.arb` + siblings — add both keys with `@`-metadata

#### Implementation approach
1. Add ARB entries:
   ```json
   "statisticsOverviewSemantics": "Statistics overview",
   "entryForSemantics": "Entry for {label}: {preview}"
   ```
2. Replace the literals in both files.

#### Test plan
- Semantics test: pump both widgets with a non-en locale, call `tester.getSemantics(...)`, assert localized label.
- Manual: enable TalkBack on Pixel 10 Pro in fr locale, confirm announcements.

#### Acceptance criteria
- [ ] Both semantics labels come from `L10n`
- [ ] No hardcoded English in Semantics labels on Stats or recent-day card
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(ux):` prefix referencing Task 2.11

#### Dependencies
- Coordinates with Epic 7 (accessibility/i18n).

---

### Task 2.12 — Add subtle edge-glow feedback when users attempt to swipe tabs

**Source:** A2 finding "NeverScrollableScrollPhysics on PageView — accidental swipes get no feedback" · **Rating:** Friction
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
`AppShell`'s PageView uses `NeverScrollableScrollPhysics`, which is correct (tabs are managed by the bottom nav, not swipe). But when a user swipes horizontally on the content area — a common instinct — nothing happens, not even a hint. Users conclude the app is frozen, or retry, or tap frustrated.

#### Root cause
The "no swipe" rule was implemented as a hard silence rather than an acknowledgement + redirection.

#### Files touched
- `lib/screens/app_shell.dart:67-80` — wrap the PageView to detect swipe gestures, pulse an edge glow overlay when swipe velocity exceeds threshold

#### Implementation approach
1. Wrap the PageView with a `GestureDetector(onHorizontalDragEnd: ...)` sibling (since the PageView itself swallows drags with NeverScrollableScrollPhysics).
2. Or use a `Listener` on raw pointer events to detect rejected drag starts and trigger an animated `Overlay` with an `IgnorePointer`-wrapped `DecoratedBox` showing a radial gradient edge glow for ~200ms.
3. Respect `AppMotion.reduce(context)` — skip the glow animation and surface a SnackBar-like hint instead.
4. Debounce so the glow fires at most once per 800ms.

#### Test plan
- Integration test: simulate `WidgetTester.drag` across the content area, assert an overlay widget with a known key appears and dismisses.
- Reduce-motion test: with `MediaQuery(disableAnimations: true, ...)` wrap, assert no animated overlay.
- Manual on Pixel 10 Pro: swipe left/right, see subtle brand-teal glow on target edge.

#### Acceptance criteria
- [ ] Attempted horizontal swipes on content area trigger a brief visual acknowledgement
- [ ] Reduce-motion skips the animation
- [ ] Does not hijack taps or vertical scrolls
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(ux):` prefix referencing Task 2.12

#### Dependencies
- May want to revisit after Task 2.5 (tab collapse) to ensure the glow still makes sense with 3 tabs.

---

### Task 2.13 — Add empty-recent illustration/microcopy to Home

**Source:** A2 finding "Home empty-recent state is plain text line only" · **Rating:** Friction
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
When both yesterday and day-before entries are empty, the home screen shows a single flat line of `l10n.noRecentEntries` / `l10n.recentEntriesPlaceholder` text. For a journaling app whose whole pitch is "no pressure," this is the single most-seen empty state and it does nothing to reinforce the product's warmth.

#### Root cause
Placeholder copy was added as a first pass; a proper empty-state composition never landed.

#### Files touched
- `lib/screens/home_screen.dart:388-400,466-482` — replace plain-text padding with a small illustration + encouraging microcopy composition
- `lib/widgets/molecules/empty_recent_state.dart` (new file) — reusable empty-state widget
- `assets/illustrations/empty_recent.svg` (new asset) OR reuse an existing brand vector
- `pubspec.yaml` — register new asset if added
- `lib/l10n/app_en.arb` + siblings — add microcopy (e.g., `emptyRecentHeadline`, `emptyRecentBody`)

#### Implementation approach
1. Create a `EmptyRecentState` StatelessWidget that renders: a 64-96dp illustration (teal-accent blob or pencil-sketch notepad), a headline, a one-line body. All color/spacing via `AppColors` / `AppSpacing`.
2. Replace both usages in `home_screen.dart` with `const EmptyRecentState()`.
3. If adding an SVG, use existing `flutter_svg` dep (verify).
4. Microcopy should echo brand voice — reference `design:ux-copy` guidance if unsure.

#### Test plan
- Widget test: pump Home with empty yesterday + day-before lists, assert `EmptyRecentState` renders with localized text.
- Widget test: with at least one entry, assert `EmptyRecentState` does NOT render.
- Manual on phone and tablet layouts.

#### Acceptance criteria
- [ ] Empty-recent state shows illustration + localized microcopy (not just a flat line)
- [ ] Non-empty state is unaffected
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(ux):` prefix referencing Task 2.13

#### Dependencies
- Coordinates with Epic 13 (brand/visual identity) for illustration alignment with the Retraq brand guide.
- Coordinates with Epic 7 (accessibility/i18n) for new ARB strings.

---

### Task 2.14 — Explain nudge skip-if-journaled behaviour in Settings

**Source:** A2 finding "Nudge setting: single time picker; no copy explaining skip-if-journaled behaviour" · **Rating:** Friction
**Priority:** P2 · **Effort:** XS · **Tier:** v1.1

#### Problem
The nudge card on Settings exposes a time picker but nowhere does it tell the user "we won't remind you if you've already journaled today." This matters: users without that context assume the app will nag them after they've already done the work, which makes them leave the nudge off entirely.

#### Root cause
The skip-if-journaled behavior was implemented in the notifications layer but never surfaced in UX copy.

#### Files touched
- `lib/screens/settings/nudge_card.dart` (or wherever `NudgeCard` is defined) — add a subtitle / help row with the explanation
- `lib/l10n/app_en.arb` + siblings — add `nudgeSkipIfJournaledHint`

#### Implementation approach
1. Add ARB entry: `"nudgeSkipIfJournaledHint": "We'll only remind you if you haven't journaled yet."`
2. In `NudgeCard`, add a small `Text` below the time picker using `tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)`.
3. Consider also adding an `info` icon that, when tapped, shows a BottomSheet with a slightly longer explanation (skip if not helpful).

#### Test plan
- Widget test: pump Settings, find the nudge card, assert the hint text is present.
- Manual: verify copy reads naturally.

#### Acceptance criteria
- [ ] Skip-if-journaled behavior is surfaced in Settings nudge card
- [ ] Hint is localized
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(ux):` prefix referencing Task 2.14

#### Dependencies
- Coordinates with Epic 7 (i18n) for the new ARB string.

---

### Task 2.15 — Tune save-success overlay hold after entry #10

**Source:** A2 finding "Save-success overlay holds ~1600ms before auto-dismiss" · **Rating:** Delight/Friction
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
The overlay's 200ms warm-up + 600ms entry + 1000ms hold + 400ms exit totals ~2200ms. Wonderful for the first few saves; by entry #20 it feels slow and blocks the next thought. The review recommends shortening the hold (to ~400ms) after entry #10 while keeping the full animation for milestone entries (1, 5, 10, 25, 50, 100, 250, 500, 1000).

#### Root cause
The overlay was tuned for first-impression delight and never conditionally scaled down for power users.

#### Files touched
- `lib/widgets/organisms/save_success_overlay.dart:134-167` — accept a `celebratory` bool or a `holdDuration` param; shorten hold when not celebratory
- Caller in `lib/screens/home_screen.dart` (search for `SaveSuccessOverlay`) — pass `celebratory: isMilestone(count)` where milestones come from existing `_milestoneForCount`

#### Implementation approach
1. Add parameter to `SaveSuccessOverlay`:
   ```dart
   final Duration holdDuration;
   const SaveSuccessOverlay({
     super.key,
     this.holdDuration = const Duration(milliseconds: 1000),
     required this.onDismissed,
   });
   ```
2. Use `widget.holdDuration` in the `_play()` delay instead of the hardcoded 1000ms.
3. In home save flow, compute `final isMilestone = _milestoneForCount(newCount, l10n) != null;` and pass `holdDuration: isMilestone ? const Duration(milliseconds: 1000) : const Duration(milliseconds: 400)` when showing the overlay. Keep full hold when `newCount <= 10`.

#### Test plan
- Widget test (fakeAsync): verify that on non-milestone save with count > 10, the overlay dismisses ~1200ms earlier than on a milestone save.
- Manual: save 12 entries quickly, feel the shortened hold on the non-milestone ones; confirm milestone #25 still gets the full hold.

#### Acceptance criteria
- [ ] Overlay hold is 400ms for routine saves after entry #10; 1000ms for milestones and for first 10 saves
- [ ] Milestone overlays still render full animation including content
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(ux):` prefix referencing Task 2.15

#### Dependencies
- Blocked by: nothing.

---

### Task 2.16 — Keep hero prompt daily rotation as-is

**Source:** A2 finding "Hero prompt rotates daily via _heroPrompts[dayOfYear % 7]" · **Rating:** Delight
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None — this is a Delight-rated observation. Seven hand-crafted hero prompts cycle deterministically across the week so every day feels a touch different without feeling random or pushy.

#### Root cause
N/A — working as designed.

#### Files touched
- `lib/screens/home_screen.dart:187-201` — no change; keep as reference for future prompt packs

#### Implementation approach
1. No-op. When adding future prompt variants (seasonal, localized packs), follow this same deterministic `dayOfYear %` pattern so rotation is stable across app relaunches within the same day.

#### Test plan
- Existing coverage suffices. No new tests required.

#### Acceptance criteria
- [ ] Reference entry recorded in this plan; no code change shipped

#### Dependencies
- None.

---

### Task 2.17 — Keep typography stack (Lexend + Manrope) as-is

**Source:** A2 finding "Typography: Lexend (headline) + Manrope (body), variable fontVariations, no textScaleFactor overrides (WCAG 1.4.4 preserved)" · **Rating:** Delight
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. The Lexend headline + Manrope body pairing with variable-axis fontVariations and no `textScaleFactor` overrides is a Delight — WCAG 1.4.4 resize is preserved, and Lexend is specifically tuned for reading fluency.

#### Root cause
N/A — working as designed.

#### Files touched
- `lib/theme/app_text.dart` — no change

#### Implementation approach
1. No-op. Document the choice in the branding guide (`docs/retraq-branding-guide.md`) if not already there, so future designers know not to collapse to a single face.

#### Test plan
- Existing golden/font tests suffice.

#### Acceptance criteria
- [ ] Reference entry recorded in this plan; no code change shipped

#### Dependencies
- Epic 7 (accessibility) may cite this as evidence of WCAG 1.4.4 compliance.

---

### Task 2.18 — Keep dark mode coverage as-is, spot-check mesh on AMOLED

**Source:** A2 finding "Dark mode thorough: lock screen, splash, overlays adapt; mood blobs Brightness-aware" · **Rating:** Delight
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Dark mode is covered across lock screen, splash, overlays, and mood-blob colors are `Brightness`-aware. Review suggests a spot-check of the mesh background on AMOLED (true blacks) to confirm it doesn't introduce visible banding.

#### Root cause
N/A — working as designed.

#### Files touched
- `lib/theme/app_theme.dart` — no change unless the AMOLED spot-check reveals banding

#### Implementation approach
1. Manual spot-check on Pixel 10 Pro (AMOLED display) in dark mode: open each screen, look for banding or color-posterization on the mesh gradient background. If found, dither or adjust gradient stops.
2. Otherwise, no-op.

#### Test plan
- Manual spot-check only. Capture screenshots in dark mode on AMOLED and attach to the audit record.

#### Acceptance criteria
- [ ] Reference entry recorded; AMOLED spot-check logged in `reviews/` folder

#### Dependencies
- None.

---

### Task 2.19 — Keep reduce-motion support, document in a11y README

**Source:** A2 finding "Reduce-motion honored everywhere: AppMotion.reduce(context), MediaQuery.disableAnimations" · **Rating:** Delight
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Reduce-motion is honored consistently through `AppMotion.reduce(context)` and `MediaQuery.disableAnimations` on lock screen and save-success overlay. Review recommends documenting this in the README / a11y page.

#### Root cause
N/A — working as designed.

#### Files touched
- `lib/screens/lock_screen.dart:331-347` — no change
- `lib/widgets/organisms/save_success_overlay.dart:127-150` — no change
- `docs/accessibility.md` (create if missing, minor edit if present) — add a "Reduce motion" section

#### Implementation approach
1. No-op on code. In `docs/accessibility.md`, add a short paragraph explaining the two motion hooks (`AppMotion.reduce(context)`, `MediaQuery.disableAnimations`) and listing where they are honored. This is documentation work, not a .md-ban violation — the docs file already exists as part of the audit evidence pattern.

#### Test plan
- Existing reduce-motion tests suffice. No new tests.

#### Acceptance criteria
- [ ] Reference entry recorded; docs section added if missing

#### Dependencies
- Coordinates with Epic 7 (accessibility) — Epic 7 may own the broader a11y doc and can absorb this paragraph.

---

### Task 2.20 — Keep bionic reading, tablet 2-pane, and milestone overlays as-is

**Source:** A2 finding "Bionic reading opt-in; tablet 2-pane; milestones inside save overlay" · **Rating:** Delight
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Three Delight signals bundled: bionic reading is opt-in (not forced on users who find it distracting), tablet uses a proper 2-pane layout (not stretched phone UI), and milestone celebrations live inside the save overlay rather than as separate interruptions.

#### Root cause
N/A — working as designed.

#### Files touched
- `lib/screens/home_screen.dart:421-426,792-805` — no change; keep as reference

#### Implementation approach
1. No-op. When adding new AI/recap features (see `project_ai_recap_plan.md`), preserve these three patterns: bionic is opt-in, tablet gets a 2-pane treatment, milestones reinforce the core save moment rather than hijack it.

#### Test plan
- Existing coverage suffices.

#### Acceptance criteria
- [ ] Reference entry recorded; no code change shipped

#### Dependencies
- Task 2.15 (overlay hold tuning) must preserve milestone-full-hold behavior — already covered there.
