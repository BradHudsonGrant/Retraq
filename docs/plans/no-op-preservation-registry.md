# No-op preservation registry

**Status:** Active reference · **Last updated:** 2026-04-18

The `implementation_plan.md` 260-task index includes ~95 "no-op"
entries — audit findings rated **Ship It / Good / Strong / Solid
/ Compliant / Optimal / Accessible** where the reviewer
explicitly said "no change needed, just don't regress this."
They exist in the plan per the "no skips" rule so no finding is
silently dropped.

This registry consolidates the current batch of no-op closures
from **Epic 4 (Product), Epic 8 (Performance), and Epic 13
(Brand)** into one place so the commit trail doesn't need 26
individual tiny commits. Each entry names the invariant being
preserved and points at the guard (test, lint, code reference)
that protects it.

If you find yourself tempted to remove one of these, open an
issue first — many of them encode product/design decisions
whose reasoning isn't obvious from the code.

---

## Epic 4 — Product (7 entries)

| Task | Invariant | Protected by |
|---|---|---|
| 4.11 | **Onboarding flow** — age gate → 3 intro pages → consent page sequence; age gate uses neutral "Are you {age} or older?" framing per Apple 1.3 / FTC COPPA. | Widget tests in `test/screens/onboarding_screen_test.dart`; country-aware age gate in `lib/services/locale_age_threshold.dart` (Task 12.3) |
| 4.12 | **Retention hooks** — streak counter + streak freeze + "on this day last year" card + milestone overlays — psychological hooks that reinforce habit without nagging. | Streak + milestone tests in `test/services/stats_service_*`, `test/utils/milestones_test.dart`; milestone copy in `lib/l10n/app_en.arb` |
| 4.13 | **No-home-edit/delete** — Home screen only SAVES, never edits or deletes. Edit/delete lives on Recap + Stats entry menus. Keeps the hero flow "open, write, done". | Home widget tests; CONTRIBUTING.md Protected surfaces section |
| 4.14 | **Free-tier posture** — v1 ships with zero paywalls, no SDK gates, no login. v1.1 monetization is a separate epic (see `docs/plans/v1.1-retraq-pro-bundle.md`). | `docs/plans/v1.1-retraq-pro-bundle.md`; no RevenueCat / subscription SDK in `pubspec.yaml` for v1 |
| 4.15 | **Name + tagline** — "Retraq" + "Lost traq? Retraq." — the v1 positioning is locked until post-launch data reshuffles. | Brand guide at `docs/retraq-branding-guide.md`; README + app_en.arb |
| 4.16 | **Voice entry** is a v1.1 candidate, not v1 scope. The "open, write, done" promise is text-first; voice would be an additive feature, not a replacement. | v1.1 bundle doc (`docs/plans/v1.1-retraq-pro-bundle.md`) explicitly park |
| 4.17 | **3-checkbox consent flow** — Privacy + Terms + Health Disclaimer each require separate acceptance. Collapsing to a single "I agree" checkbox would weaken meaningful-consent compliance under GDPR Art. 7 + PIPEDA Principle 3. | Widget test `test/screens/onboarding/consent_page_returning_user_test.dart::returning-user flag does NOT auto-tick consent checkboxes`; CONTRIBUTING.md Protected surfaces |

---

## Epic 8 — Performance (8 entries)

Each of these is an already-shipped performance pattern that
audit Agent 8 flagged as Optimal. The guard column names the
specific file / line / test that would fail if the pattern
silently reverted.

| Task | Invariant | Protected by |
|---|---|---|
| 8.13 | `flutter_animate` shake effect on save-validation errors runs on a short AnimationController (300ms) rather than a sustained StreamTicker. | `test/widgets/atoms/tab_swipe_edge_glow_test.dart` pattern, `lib/screens/home_screen.dart::_shakeController`; Task 7.18 AppMotion bypass lint prevents uncontrolled new animations |
| 8.14 | `watchEntriesForDate` uses a Drift query with indexed date column, not a full-table scan. | `test/services/entry_repository_test.dart`; Drift migration assertions in `test/services/database_migration_test.dart` |
| 8.15 | `watchAllStats` has a debounced 600ms signature-cache (SELECT aggregate "signature" on every journal_entries write; only recomputes full stats when the signature changes). | `lib/services/stats_service.dart::watchAllStats`; `test/services/stream_ordering_test.dart` pins emission coalescing behaviour |
| 8.16 | Export runs on `compute()` isolate so the UI thread isn't blocked during large JSON serialisation. | `lib/services/export_service.dart`; `test/services/export_service_real_invocation_test.dart` |
| 8.17 | Import dedup matches on `(date, created_at, label, entry_text_hash)` — re-importing the same backup is idempotent. | `test/services/entry_repository_test.dart` upsert cases |
| 8.18 | `NavigationBar` wrapped in `RepaintBoundary` so tab-bar repaints don't bleed into the PageView children. | `lib/screens/app_shell.dart`; would surface as visible jank if removed |
| 8.19 | `_shakeController` disposed in `home_screen.dart::dispose()` so the vsync doesn't leak across Hot Reload. | Required by Flutter framework; analyzer + `cancel_subscriptions` lint (Task 1.5) |
| 8.20 | FTS5 uses prefix matching (`MATCH '<token>*'`) so 3-character partial matches hit. Without the suffix, search would require full-token entries. | `lib/services/entry_repository.dart::searchEntries`; `test/services/entry_repository_test.dart` FTS5 prefix case |

---

## Epic 13 — Brand (13 entries; 13.18 closed separately)

Most of these encode product-voice + visual-identity decisions
from the SinceThen → Retraq rebrand pass (`docs/retraq-branding-
guide.md`). Changing any of them without a rebrand discussion
would fracture the voice consistency.

| Task | Invariant | Protected by |
|---|---|---|
| 13.8 | "Retraq" is distinctive vs journaling / memory-app category; no common-word collision. | `docs/retraq-branding-guide.md`; App Store / Play Store search results (preserve post-launch) |
| 13.9 | No naming conflicts in the App Store or Play Store under "Retraq" (verified 2026-04-05). | Manual verification; re-check at submission time |
| 13.10 | **Typography:** Lexend (UI, accessibility-optimised for cognitive load) + Manrope (headings/display). No system-default fallback as primary. | `lib/theme/app_theme.dart`; `pubspec.yaml` asset registration |
| 13.11 | Onboarding page copy preserved post-rebrand; same supportive tone ("If those questions make your mind go blank, you're in the right place."). | `lib/l10n/app_en.arb::onboardingTitle*` + `onboardingBody*` |
| 13.12 | Empty-state copy uses warm, low-pressure voice ("A fresh page", "No traqs from the last two days...") instead of "Journal is empty". | `lib/l10n/app_en.arb::emptyRecentHeadline` + `emptyRecentBody`; `lib/widgets/molecules/empty_recent_state.dart` (Task 2.13) |
| 13.13 | Milestone copy is celebratory, not numeric ("25 traqs! Look at you go." vs "25/∞"). | `test/utils/milestones_test.dart` pins the 9 thresholds (Task 1.2 follow-up) |
| 13.14 | Tagline "Lost traq? Retraq." used as App Store subtitle, not body copy — keeps it high-impact. | `docs/store-listing/ios.md` + `android.md`; Task 9.12 A/B-tests an alternative subtitle |
| 13.15 | "Traq" used as the entry noun throughout the app ("Drop a traq", "Your recent traqs"), not "entry" or "journal entry". | `lib/l10n/app_en.arb` — grep for "traq" across the ARB; 60+ hits |
| 13.16 | Clinical language forbidden (cure / treat / diagnose / FDA / HIPAA / clinically proven). | `Task 12.5` forbidden-claims lint in `.github/workflows/ci.yml`; `docs/legal/forbidden-claims.md` |
| 13.17 | Anti-obligation positioning: app never says "You missed a day", "Don't forget to journal", or similar guilt-driving copy. Streak freezes exist for this reason. | `lib/l10n/app_en.arb` nudge copy; Task 2.14 nudge subtitle explains skip-if-journaled |
| 13.19 | Social potential preserved — entries can be exported / shared individually but there's no social timeline, follower graph, or public-profile surface. | No social-network SDK in `pubspec.yaml`; `ExportService.shareEntryText` is single-entry share-sheet only |
| 13.20 | Premium perception — the free v1 should not feel like a shareware demo. No "upgrade to unlock" tooltips, no feature teasers. | `docs/plans/v1.1-retraq-pro-bundle.md` defers IAP entirely; no Paywall widget exists in v1 lib/ |
| 13.21 | Trademark symbol rules — use ™ on the wordmark in every marketing surface; use ® only after CIPO + USPTO registration completes (Task 13.6, blocked on B-15/B-16 user action). | `docs/retraq-branding-guide.md::trademark-usage`; store-listing copy pending trademark closure |

---

## Maintenance protocol

When a plan task in one of these three epics bubbles up again
(e.g., someone reports a change proposal that could regress one
of these invariants):

1. Look up the matching row above.
2. Trace the "Protected by" column to the concrete guard.
3. If the guard still exists + the invariant still holds, the
   proposal is a regression — push back with the row's rationale.
4. If the invariant itself should change (product pivot,
   regulatory change), update this file in the same commit as
   the code change — no silent drift.

Task 4.1 / 4.2 / 4.3 / 4.7 plan-rewrite closures live in
`implementation_plan.md` §0.1 + §0.2. All four remaining P0/P1
product items that needed plan edits are now closed.
