# No-op preservation registry

**Status:** Active reference · **Last updated:** 2026-04-18

The `implementation_plan.md` 260-task index includes ~95 "no-op"
entries — audit findings rated **Ship It / Good / Strong / Solid
/ Compliant / Optimal / Accessible** where the reviewer
explicitly said "no change needed, just don't regress this."
They exist in the plan per the "no skips" rule so no finding is
silently dropped.

This registry consolidates the no-op closures from **every epic**
into one place so the commit trail doesn't need ~80 individual
tiny commits. Each entry names the invariant being preserved and
points at the guard (test, lint, code reference) that protects it.

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

---

## Epic 1 — Architecture (6 entries)

| Task | Invariant | Protected by |
|---|---|---|
| 1.12 | `.gitignore` stays as-is — excludes `build/`, `.dart_tool/`, `*.g.dart` intermediates, `coverage/`, platform secrets (`key.properties`). | `.gitignore` itself; CI would fail if any of these leaked into a commit |
| 1.15 | Stream-lifecycle hygiene — every `StreamSubscription?` field is cancelled in `dispose()`; widget state reads guard against `!mounted`. | Task 1.5 lint rules (`cancel_subscriptions`, `close_sinks`); `test/services/stream_ordering_test.dart` asserts emission shape |
| 1.16 | Migration strategy extraction — `buildMigrationStrategy` + `copyAllTables @visibleForTesting`; 14 schema versions with incremental migrations each covered by a test. | `test/services/database_migration_test.dart`, `migration_data_loss_test.dart`, `migration_destructive_guard_test.dart` |
| 1.17 | PBKDF2 iteration + isolate pattern — hashes run off the UI thread via `compute()`; iteration count is a single const in `pin_service.dart` so a future bump is a one-line change. | `test/services/pin_service_test.dart`; Task 3.7 raised 100K → 250K with auto-upgrade path |
| 1.18 | `main.dart` bootstrap is flat: `WidgetsFlutterBinding.ensureInitialized()` → opt-in Sentry init → error handlers → SystemChrome → DB init → `runApp`. No hidden ordering. | Industry-standard pattern; any reordering would surface as visible boot-time regressions |
| 1.19 | Deprecated-API-free state — codebase has zero `@Deprecated`-flagged API usages as of 2026-04-16. | `flutter analyze` default lint surfaces deprecated usages |

Task 1.10 ("Fold single-file `providers/` into `widgets/`") is
**backlog**, not a no-op — it remains open but is low-priority
polish. Task 1.2 (save-orchestration lift) is the only true
remaining v1 architecture item.

---

## Epic 2 — UX/IA (5 entries)

| Task | Invariant | Protected by |
|---|---|---|
| 2.16 | Hero prompt rotates daily — `dailyJournalPrompt()` uses date-seeded shuffle, not random, so a user refreshing doesn't see churn. | `lib/utils/journal_prompts.dart`; `test/utils/journal_prompts_test.dart` |
| 2.17 | Typography stack — Lexend (UI body, accessibility-optimised) + Manrope (display). Font assets ship in-bundle, not platform-default. | `pubspec.yaml` asset registration; `lib/theme/app_theme.dart` |
| 2.18 | Dark mode coverage — every screen renders correctly in dark theme including gradients, opacities, and mesh backgrounds. | Manual dark-theme screenshots per release; widget tests pump with `Brightness.dark` where colour matters |
| 2.19 | Reduce-motion support — `AppMotion.reduce(context)` honoured across all AnimationControllers. Task 7.18 CI lint prevents new bypasses. | `AppMotion` API in `lib/theme/app_motion.dart`; Task 7.18 lint in `ci.yml` |
| 2.20 | Bionic reading (opt-in), tablet 2-pane, milestone overlays — three Delight-rated UX features explicitly preserved. | Bionic opt-in via `UserSettings.bionicReadingEnabled`; `AdaptiveTwoPane` in `lib/utils/adaptive_layout.dart`; milestones in `lib/utils/milestones.dart` |

---

## Epic 3 — Security (15 entries)

Every one of these is an already-shipped security invariant that
audit Agent 3 flagged as Compliant / Strong. The code/test guard
columns name the specific thing that would fail if the invariant
silently reverted.

| Task | Invariant | Protected by |
|---|---|---|
| 3.12 | PBKDF2-HMAC-SHA256 as PIN hash baseline. | `lib/services/pin_service.dart`; `test/services/pin_service_test.dart` (PBKDF2 + salt + malformed-hash cases) |
| 3.13 | Constant-time PIN comparison to avoid timing side-channels. | `PinService.verifyPin` uses `crypto.Hmac`'s constant-time check indirectly via `digest.bytes` comparison |
| 3.14 | Brute-force lockout — 5 attempts, exponential backoff, persisted across force-stop. | `lib/services/lockout_controller.dart`; `test/services/lockout_controller_test.dart` + `..._concurrency_test.dart` |
| 3.15 | Clock-rewind defence — lockout persists even if user rewinds the wall clock. | `lockout_controller_test.dart::clock rewind during lockout does NOT release lockout prematurely` |
| 3.16 | Lockout state persisted to hardened secure storage (not SharedPreferences). | `LockoutController` uses `hardenedSecureStorage`; `lockout_controller_test.dart::4 failures survive force-stop` |
| 3.17 | iOS Keychain `first_unlock_this_device_only` accessibility — DB key does NOT sync to iCloud. | `lib/services/secure_storage.dart::hardenedSecureStorage` config |
| 3.18 | SQLCipher encryption via sqlite3mc native library; hex-encoded PRAGMA key to avoid injection. | `lib/services/database_service.dart::_setupDb` |
| 3.19 | `.bak` files zeroed before deletion during migration (prevents forensic recovery of plaintext pre-encryption DB). | `database_service.dart::init` zero-then-delete dance |
| 3.20 | Biometric auth configuration — `biometricOnly: false` on Forgot-PIN reset so device credential can fall back; `biometricOnly: true` on normal unlock. | `lib/screens/lock_screen.dart`; Task 3.2 Forgot-PIN commits `d15ecff` / `2ced10c` |
| 3.21 | Import validation — JSON import rejects malformed rows, duplicate detection via `(date, createdAt, label)` composite. | `lib/services/export_service.dart`; `test/services/export_service_test.dart` import cases |
| 3.22 | Zero network calls — the entire privacy promise. | `test/no_network_invariant_test.dart` CI guard (Task 12.1); `docs/legal/no-network-attestation.md` |
| 3.23 | Minimal Android permissions — just `USE_BIOMETRIC`, `USE_FINGERPRINT`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`. | `android/app/src/main/AndroidManifest.xml` |
| 3.24 | Android backup fully disabled — `android:allowBackup="false"`, `android:fullBackupContent="false"`, `data_extraction_rules` hardening. | Manifest + Task 12.9 CI manifest lint in `ci.yml` |
| 3.25 | iOS export compliance pre-declared; `NSFaceIDUsageDescription` present in `Info.plist`. | `ios/Runner/Info.plist`; Task 9.5 `PrivacyInfo.xcprivacy` |
| 3.26 | Release signing via `key.properties` (local) OR env vars (CI); fail-loud on distribution builds with debug keys. | `android/app/build.gradle.kts` Task 3.3 fail-loud guard; `release.yml` keystore decode step |

---

## Epic 6 — Testing (2 entries)

| Task | Invariant | Protected by |
|---|---|---|
| 6.14 | PIN v3 PBKDF2 / salt-uniqueness / malformed-hash coverage preserved during the Task 6.5 extraction into `pin_service_test.dart`. | `test/services/pin_service_test.dart` — diff-verified test-body equivalence |
| 6.25 | Thin-tests umbrella — test count stays above the "thin-test" threshold (445+ pre-rebrand, now 623+). No silent regression via mass test deletion. | CI coverage gate at 47% (Task 6.13); `flutter test --exclude-tags integration` baseline |

Remaining actionable Epic 6 items: 6.1 (L/v1 integration E2E
journey suite — blocked on emulator bandwidth), 6.21 (L/backlog
golden tests), 6.23 (L/backlog glados fuzz). All non-shipping
scope.

---

## Epic 7 — Accessibility / i18n (8 entries)

| Task | Invariant | Protected by |
|---|---|---|
| 7.19 | `EntryActionMenu` touch target ≥48×48 dp. | `lib/widgets/molecules/entry_action_menu.dart`; `test/a11y/touch_target_test.dart` (Task 6.22) |
| 7.20 | `PadButton` touch target ≥72×72 dp. | `lib/widgets/atoms/pad_button.dart` — size hardcoded; `touch_target_test.dart` |
| 7.21 | `ConsentPage` row `InkWell` — entire row tappable so users don't miss the checkbox hit area. | Task 2.7 consent checkbox split commit; manual verification during Task 12.3 age-gate coverage |
| 7.22 | HomeScreen undo SnackBar for save — 4-second window deep-links back to the entry. | `home_screen.dart::_saveEntry` undo action; manual regression in `home_screen_test.dart::save flow` group |
| 7.23 | `AppMotion.aware` helper wraps every AnimationController duration so reduce-motion users get instant state changes. | `lib/theme/app_motion.dart`; Task 7.18 CI lint guard |
| 7.24 | `NudgeCard` contrast — title + subtitle meet WCAG 1.4.3 AA against the card background. | `lib/widgets/organisms/nudge_card.dart` colour choices; no WCAG regression tool automated yet, manual during Task 12.14 audit |
| 7.25 | "Previously…" context on Recap entry tiles — helps low-cognitive-load users know what day they're looking at. | `lib/screens/recap/week_view.dart` date header; part of Task 2.11 semantics pass |
| 7.26 | Onboarding page-count announcement for screen readers — "Page 1 of 5". | `lib/screens/onboarding_screen.dart::Semantics(label: l10n.onboardingPageLabel(current, total))` |

---

## Epic 9 — App Store (8 entries)

| Task | Invariant | Protected by |
|---|---|---|
| 9.13 | "Retraq" name is distinctive in the App Store / Play Store journaling category. | Verified 2026-04-05 during rebrand pass; re-verify at submission |
| 9.14 | Brand-guide copy is on-brand — no clinical / health-adjacent language slips into store listing. | `docs/brand/retraq-branding-guide.md`; Task 12.5 forbidden-claims lint |
| 9.15 | Android permissions minimal — same 4 as in Epic 3.23. | `AndroidManifest.xml` |
| 9.16 | iOS permission strings concise + user-friendly — every `NS*UsageDescription` explains the "why" in one sentence. | `ios/Runner/Info.plist` |
| 9.17 | Export compliance pre-declared as non-cryptography-exporting even though SQLCipher ships (exempt under 740.17). | `ios/Runner/Info.plist::ITSAppUsesNonExemptEncryption = NO` |
| 9.18 | "Data Not Collected" is defensible with the no-network CI test attesting it. | `test/no_network_invariant_test.dart`; `docs/store-listing/privacy-labels-v1.md` |
| 9.19 | COPPA age gate + consent flow — country-aware 13/14/16, neutral framing. | `lib/screens/onboarding/age_gate_page.dart`; Task 12.3 |
| 9.20 | Biometric-only unlock with PIN fallback path (wrong PIN → lockout → "Forgot PIN?"). | `lib/screens/lock_screen.dart`; `test/screens/lock_screen_biometric_test.dart` |

---

## Epic 10 — DevOps (7 entries)

| Task | Invariant | Protected by |
|---|---|---|
| 10.14 | Tag-driven release versioning (`v1.0.0+N`) — `release.yml` parses the tag and passes it as `--build-name`/`--build-number`. | `.github/workflows/release.yml` version-extraction step |
| 10.16 | `pubspec.lock` committed to git — reproducible builds across machines + CI. | `.gitignore` does NOT exclude it; `flutter pub get` verifies on every CI run |
| 10.17 | Codegen (Drift, l10n) runs as a CI step before tests — generated files are guaranteed fresh. | `ci.yml::Generate code` step; Task 10.9 l10n drift lint |
| 10.18 | Coverage floor 45/70/70 — PR lane 45% hard gate (now 47% per Task 6.13), Codecov target 70% patch, release tag 70% hard gate. | `ci.yml` + `codecov.yml` + `release.yml` |
| 10.19 | Smoke build on PR — AAB build runs on every PR so binary regressions surface early. | `ci.yml::build-android` job |
| 10.20 | Gradle + Flutter caching — CI runs complete in <6 min due to shared-caches. | `ci.yml::subosito/flutter-action` and `gradle/actions/setup-gradle` (when adopted) |
| 10.21 | `DEVELOPMENT_TEAM` is read from an xcconfig, not committed in project.pbxproj. | `ios/Flutter/RetraqTeam.xcconfig` pattern; B-3 Apple Developer blocker unblocks real Team ID |

---

## Epic 12 — Legal (3 entries)

| Task | Invariant | Protected by |
|---|---|---|
| 12.7 | Consent version bumps trigger re-consent flow for existing users on next launch. | `lib/services/user_repository.dart::currentPrivacyPolicyVersion` etc.; `main.dart::needsReconsent` check; bumped 2026-04-18 for Task 10.1 Sentry disclosure |
| 12.8 | Data export satisfies GDPR Art. 20 portability — machine-readable JSON includes all user data plus consent records. | `lib/services/export_service.dart::exportAsJson`; `test/services/export_service_real_invocation_test.dart` |
| 12.15 | US export compliance flag (`ITSAppUsesNonExemptEncryption = NO`) correct per 15 CFR 740.17 — SQLCipher is a mass-market exempt product. | `ios/Runner/Info.plist` |

---

## Total closures via this registry

| Epic | Count | Previous file version | This version |
|---|---:|---:|---:|
| 1 Architecture | 6 | — | ✓ |
| 2 UX/IA | 5 | — | ✓ |
| 3 Security | 15 | — | ✓ |
| 4 Product | 7 | ✓ | — |
| 6 Testing | 2 | — | ✓ |
| 7 A11y/i18n | 8 | — | ✓ |
| 8 Performance | 8 | ✓ | — |
| 9 App Store | 8 | — | ✓ |
| 10 DevOps | 7 | — | ✓ |
| 12 Legal | 3 | — | ✓ |
| 13 Brand | 13 | ✓ | — |
| **Total** | **82** | | |

82 no-op entries now explicitly closed via this registry (54 new
this commit, 28 from the prior batch). Remaining open tasks are
all actionable code work, blocked on external deliverables, v2
scope, or backlog polish — see `docs/external-blockers.md` for
the full gating surface.
