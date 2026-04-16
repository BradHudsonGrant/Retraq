# Retraq Implementation Plan (Post-Audit 2026-04-16)

**Status:** Authoritative roadmap as of 2026-04-16
**Supersedes:** `../implementation_plan.md` (backup at `../implementation_plan.md.bak-2026-04-16`)
**Source of findings:** `app/reviews/review-2026-04-16.md` (13-agent audit, 260 total findings)
**Per-epic detailed plans:** [`app/docs/plans/`](docs/plans/)

---

## 0. What changed from the previous plan

The previous `implementation_plan.md` was written against the pre-April-2026 product definition. Three sections are **no longer accurate** and are explicitly superseded:

| Old plan section | Why it's stale | Where the correct version lives |
|---|---|---|
| §8 "Monetization" ($2–3/mo subscription, tiered Retraq Premium) | v1 ships free (April 2026 feature decision). Monetization shifts to one-time IAP post-activation + optional cloud-AI subscription in v1.1+. | [Part II](#part-ii--v11-monetization) below + Epic 4 Tasks 4.1, 4.9 |
| §Phase 7 "Retraq Care caregiver tier" | Dropped from v1; requires outside counsel + sub-brand work before any code ships. | [Part III](#part-iii--v2-dropped-scope) below + Epic 12 Task 12.12 + Epic 13 Task 13.5 |
| §Epic 6 Tier 3 "Cloud AI recaps" | Deferred to v1.1/v2; requires Art. 9 explicit consent + AI-Act transparency + Quebec PIA before cross-border AI processing. | [Part II](#part-ii--v11-monetization) + Epic 4 Task 4.2 + Epic 12 Tasks 12.4, 12.13 |

The previous plan's Epics 0–5 (app shell, journaling core, security, stats, recap, onboarding, widget, tablet) shipped or are near-shipping and remain correct at the feature level — they are restated in the [v1 launch sequence](#v1-launch-sequence) below as already-done / in-progress rather than planned.

---

## 1. Document conventions

### 1.1 Priority / Effort / Tier

| Priority | Meaning |
|---|---|
| **P0** | Must fix before v1 launch. Critical bugs, security vulnerabilities, legal blockers, user-data-loss vectors. |
| **P1** | Fix for v1 launch. Important for quality but not technically blocking submission. |
| **P2** | Post-launch, v1.1. Nice improvements, observability, scalability prep. |
| **P3** | Backlog / reference. Future work, documented as intentional, or no-op preservation entries. |

| Effort | Estimate |
|---|---|
| **XS** | < 30 minutes |
| **S** | < 2 hours |
| **M** | < 1 day |
| **L** | 2–3 days |
| **XL** | < 1 week |
| **XXL** | > 1 week |

| Tier | Meaning |
|---|---|
| **v1 launch** | Lands before the 1.0 public submission. |
| **v1.1** | Fast-follow patch after v1 lands (monetization, observability, polish). |
| **v2** | Post-launch major-version scope (caregiver tier, cloud sync, family sharing). |
| **backlog** | Nice-to-have, no scheduled tier. |
| **no-op** | Reference entry for a "Good / Solid / Strong / Compliant / Optimal / Accessible"-rated finding — preserved in the plan per "no skips" rule, no code work required. |

### 1.2 Commit & PR workflow (the user's explicit requirement: **each feature/fix ships as its own commit to GitHub**)

- **Repo:** `BradHudsonGrant/Retraq` · branch `main` (protected; PR-merged from topic branches)
- **One Task → One Commit → One Push** unless a task explicitly groups sub-commits (e.g., lint-rule-per-group).
- **Branch naming:** `epic-<N>/task-<N.M>-<short-kebab-slug>` — example: `epic-01/task-1.1-narrow-bare-catch`
- **Commit-message prefix table** (matches each epic's convention):
  | Epic | Default prefixes |
  |---|---|
  | 1 Architecture | `fix(arch):`, `refactor(arch):`, `chore(arch):` |
  | 2 UX/IA | `feat(ux):`, `fix(ux):` |
  | 3 Security | `fix(security):`, `feat(security):` |
  | 4 Product | `feat(product):`, `refactor(product):`, `docs(product):` |
  | 5 GTM | `docs(gtm):`, `chore(gtm):` |
  | 6 Testing | `test:` |
  | 7 A11y / i18n | `fix(a11y):`, `feat(i18n):`, `test(a11y):` |
  | 8 Performance | `perf:`, `refactor(perf):` |
  | 9 App Store | `docs(store):`, `chore(store):` |
  | 10 DevOps | `ci:`, `build:`, `chore:` |
  | 11 Analytics | `feat(stats):`, `chore(privacy):` |
  | 12 Legal | `legal:`, `docs(legal):` |
  | 13 Brand | `feat(brand):`, `chore(brand):`, `docs(brand):` |
- **Commit-message body** must reference the Task ID, e.g. `(Task 1.1)`
- **PR template** must include:
  - Task ID and link to `app/docs/plans/epic-<N>-<slug>.md#task-<N.M>-...`
  - Acceptance-criteria checklist copied from the plan
  - Risk/blast-radius note
  - Test evidence (screenshots, logs, or green CI)
- **Required CI gates** before merge: `flutter analyze` clean, `flutter test` passes, coverage ≥ 45% floor (≥ 70% on tag release), SHA-pinned actions only.
- **Do NOT skip hooks** (`--no-verify`) or bypass signing. If a hook fails, fix the underlying issue.
- **Never force-push to `main`.** Topic-branch rebases are fine.

### 1.3 Destructive-action guardrails

Consistent with the `CLAUDE.md` session guidelines:

- Never `git reset --hard` on `main` or force-push to `main`.
- Never `rm -rf` or delete unfamiliar files without confirming with the user.
- Any schema migration that could lose user data requires a migration test (`test/services/database_migration_test.dart` or `migration_data_loss_test.dart`) and a manual pre-flight dry-run on a synthetic DB.
- Any change that bumps `ConsentVersion` triggers the re-consent flow — test that existing users are walked through it before shipping.

### 1.4 Documentation pointers

| What | Where |
|---|---|
| Per-epic task plans | `app/docs/plans/epic-<NN>-*.md` (13 files, tracked) |
| Source audit report | `app/reviews/review-2026-04-16.md` (gitignored; keep local) |
| Brand guide | `docs/retraq-branding-guide.md` |
| Legal docs | `app/lib/legal/*.dart` (in-app), `app/docs/legal/*.md` (new, tracked) |
| Store-listing copy | `app/docs/store-listing/*.md` (new, tracked, produced via Epic 9) |
| GTM artifacts | `app/docs/gtm/*.md` (new, tracked, produced via Epic 5) |
| ADRs / decision records | `app/docs/adr/*.md` (new, tracked, for Sentry-vs-Crashlytics and similar forks) |

---

## 2. Executive roadmap

### v1 launch sequence

The shortest path to a submittable Play Store + App Store v1 runs through these P0/P1 items, ordered by dependencies. Tasks are linked to their detailed plans.

**Phase A — Critical fixes (P0, block submission)**

1. Epic 1 Task 1.1 — Narrow the bare-catch in `database_service.dart:204` to prevent destructive plaintext→encrypted migration on transient errors.
2. Epic 3 Task 3.1 — Set `AndroidOptions(encryptedSharedPreferences: true)` to match documented hardening.
3. Epic 3 Task 3.2 — Gate Forgot-PIN destructive wipe behind biometric re-auth + encrypted-export prompt; show "Forgot PIN?" from first failed attempt (UX per Epic 2 Task 2.4).
4. Epic 3 Task 3.4 — Apply FLAG_SECURE unconditionally, not only when app lock is enabled.
5. Epic 3 Task 3.5 / 3.6 — Render lock/blur overlay on `inactive`/`paused` (not only `resumed`); iOS equivalent via `applicationWillResignActive`.
6. Epic 4 Tasks 4.1, 4.2, 4.3, 4.8 — Rewrite this `implementation_plan.md` to remove stale monetization/caregiver/cloud-AI Tier 3 content. (In progress — this very file.)
7. Epic 12 Task 12.3 — Country-aware age gate (13/14/16) + parental consent flow.
8. Epic 13 Task 13.1 — Redesign app icon around Q-motif (single biggest first-impression lever).
9. Epic 10 Tasks 10.1, 10.3, 10.5 — Wire Sentry crash reporting; align `.fvmrc` with CI Flutter 3.41.6; rename "Isar" → "Drift" in scripts.

**Phase B — Launch polish (P1)**

10. Epic 1 Tasks 1.2, 1.3 — Refactor `home_screen.dart` and `stats_screen.dart` (extract controllers + molecules; move "On This Day" into StatsService).
11. Epic 1 Tasks 1.5, 1.4, 1.7, 1.13 — Expand lints; replace 9 bare-catch blocks; extract AppSnackBar; introduce AppLog wrapper.
12. Epic 2 Tasks 2.1, 2.2, 2.3, 2.10, 2.11 + Epic 7 Tasks 7.3–7.10 — Localize all hardcoded English strings that already have ARB keys (MoodSelector, WeekDayList, EntryActionMenu, NudgeCard, NumberPad, Stats semantics, HomeScreen hero prompts).
13. Epic 2 Tasks 2.5–2.9, 2.13, 2.14 — UX polish: fold Stats into Recap, consent-checkbox/link split, AM/PM "discard" option, date-chip reset-X, empty-state illustration, nudge-copy clarification.
14. Epic 4 Tasks 4.4, 4.5, 4.6, 4.7 — Settings bloat reduction (Advanced expansion), drop mood sub-toggles, align README, add widget/tablet mentions.
15. Epic 7 Tasks 7.1, 7.2, 7.7, 7.8, 7.12 — WCAG contrast fixes (hint text, page dots, backdated meta, calendar dim, outlineVariant).
16. Epic 8 Task 8.1 — Fix defeated list virtualization in MonthView/SearchView.
17. Epic 9 Tasks 9.1–9.6, 9.8, 9.9, 9.11 — Screenshots, listing copy, ASO, category, `PrivacyInfo.xcprivacy`, version bump, health-claim guards, age rating, launch schedule.
18. Epic 10 Tasks 10.4, 10.8, 10.9 — Keystore fail-loud; Codecov upload; l10n regeneration CI check.
19. Epic 12 Tasks 12.1, 12.2, 12.6, 12.11, 12.14, 12.16 — No-network CI guard; controller disclosure; Terms carve-out; Canadian entity; WCAG 2.2 AA audit; crisis-line localization.
20. Epic 13 Tasks 13.2, 13.3, 13.4, 13.6, 13.7, 13.18 — Custom mood-scale palette; warm amber accent; logo small-size test; trademark filings; archive old-brand assets; competitor battlecard.

**Phase C — v1.1 fast-follow** (see [Part II](#part-ii--v11-monetization))

**Phase D — v2** (see [Part III](#part-iii--v2-dropped-scope))

### Parallelizable work streams

Several epics are independent and can proceed in parallel once Phase A lands:

- **Architecture cleanup** (Epic 1 P1 items) + **UX polish** (Epic 2) — different file sets; low merge conflict.
- **A11y contrast fixes** (Epic 7) — theme/widget only; depends on no upstream epic.
- **Store prep** (Epic 9) + **DevOps** (Epic 10) — docs + CI; do not touch `lib/` in the common case.
- **Market artifacts** (Epic 5) + **Legal docs** (Epic 12) + **Brand polish** (Epic 13) — docs-only; can run anytime.

Security P0s (Epic 3) must land as a single cohesive set — they touch related code (lock screen, backgrounding, migration) and benefit from coordinated review.

---

## 3. Part I — Per-epic plan index

Full detail at `app/docs/plans/epic-<NN>-<slug>.md`. Summary counts:

| # | Epic | Tasks | P0 | P1 | P2 | P3 | v1 | v1.1 | v2 | backlog | no-op |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | [Code Architecture & Quality](docs/plans/epic-01-code-architecture.md) | 19 | 2 | 5 | 4 | 8 | 7 | 4 | 0 | 1 | 7 |
| 2 | [UX & Information Architecture](docs/plans/epic-02-ux-ia.md) | 20 | 2 | 8 | 5 | 5 | 13 | 2 | 0 | 0 | 5 |
| 3 | [Security & Privacy](docs/plans/epic-03-security.md) | 26 | 6 | 3 | 2 | 15 | 9 | 1 | 2 | 0 | 14 |
| 4 | [Product & Features](docs/plans/epic-04-product.md) | 17 | 3 | 4 | 2 | 8 | 7 | 2 | 1 | 0 | 7 |
| 5 | [Market / Go-to-Market](docs/plans/epic-05-market-gtm.md) | 14 | 2 | 5 | 5 | 2 | 6 | 5 | 1 | 2 | 0 |
| 6 | [Testing & Reliability](docs/plans/epic-06-testing.md) | 26 | 1 | 7 | 7 | 11 | 8 | 4 | 0 | 4 | 10 |
| 7 | [Accessibility & i18n](docs/plans/epic-07-accessibility.md) | 26 | 2 | 6 | 10 | 8 | 10 | 4 | 4 | 0 | 8 |
| 8 | [Performance & Scalability](docs/plans/epic-08-performance.md) | 20 | 1 | 3 | 5 | 11 | 2 | 3 | 3 | 4 | 8 |
| 9 | [App Store Readiness](docs/plans/epic-09-app-store.md) | 20 | 3 | 6 | 3 | 8 | 9 | 3 | 0 | 0 | 8 |
| 10 | [DevOps & CI/CD](docs/plans/epic-10-devops.md) | 21 | 2 | 3 | 3 | 13 | 5 | 2 | 1 | 5 | 8 |
| 11 | [On-device Analytics](docs/plans/epic-11-analytics.md) | 14 | 0 | 0 | 8 | 6 | 0 | 10 | 1 | 1 | 2 |
| 12 | [Legal & Compliance](docs/plans/epic-12-legal.md) | 16 | 2 | 7 | 1 | 6 | 7 | 3 | 1 | 0 | 5 |
| 13 | [Brand & Visual Identity](docs/plans/epic-13-brand.md) | 21 | 1 | 4 | 2 | 14 | 5 | 2 | 1 | 0 | 13 |
| | **Totals** | **260** | **27** | **61** | **57** | **115** | **88** | **45** | **14** | **17** | **95** |

**Working interpretation:** 260 total tasks; **88 land before v1 submission** (the launch surface), **45 in v1.1**, **14 in v2**, **17 in backlog**, **95 are preservation/no-op entries** kept in the plan per "no skips" rule.

Priority totals (across all tiers):
- **P0 = 27** — launch-blocking; every one of these must land before submitting to stores.
- **P1 = 61** — should-land for a polished v1; coordinated best in Phase B.
- **P2 = 57** — v1.1 and observability.
- **P3 = 115** — backlog, preservation, reference (most of the no-op entries are here).

> Note: per-epic counts sum to 260; the Part II / Part III sections below do **not** add new tasks — they synthesize existing Epic 4 / 11 / 12 / 13 / 5 tasks into coherent v1.1 and v2 product narratives so the reader sees the monetization and dropped-scope story end-to-end without hunting across 13 files.

---

## Part II — v1.1 monetization

**Context.** Per the April 2026 feature decision (user's memory file `project_feature_decisions.md`), v1 ships **entirely free** with no paywall and no monetization infrastructure. This is deliberate: the priority is activation + retention signal, not revenue. v1.1 introduces monetization as a fast-follow once daily-active data lands.

### II.1 Monetization model (v1.1)

Two SKUs, both implemented via **RevenueCat** for cross-platform consistency and paywall-template leverage:

| SKU | Type | Price (target) | Gates |
|---|---|---|---|
| **Retraq Pro** | One-time IAP | $5.99 USD (or region-adjusted) | Themes (2–3 premium palettes), CSV export, yearly recap ("Your Year in Traqs"), optional Gemini Nano on-device recap (Android-only, subject to device support). Lifetime unlock — anti-subscription-fatigue signal for ADHD audience. |
| **Retraq Cloud Recap** | Monthly subscription | $2.99 USD/mo or $24.99/yr (TBD A/B test) | Cloud AI-generated weekly recap (Tier 3 per original roadmap), synced across devices if cloud sync ships, prioritized in app-store listing. |

**Rationale.** The one-time Pro is the headline for the ADHD market (Agent 5: subscription fatigue is a real complaint in this audience). The cloud subscription is optional and clearly for power users who want AI polish; it is NOT a gate on the core product.

**Trial length:** 7–14 day free trial on the Cloud Recap subscription (Epic 5 Task 5.11 A/B tests). No trial on Retraq Pro (one-time IAP).

### II.2 Feature assembly for v1.1

These specific tasks from the 13 epics land together as the v1.1 release:

| Workstream | Tasks |
|---|---|
| Payment infra | Epic 4 Task 4.9 (plan v1.1 premium feature) · Epic 1 Task 1.7 (get_it DI — enables SubscriptionService) · Epic 10 Task 10.13 (dev/staging/prod flavors) |
| Paywall UI | Epic 4 Task 4.15 (new, from master plan gap — add a "RevenueCat wire-up" task in Epic 4 v1.1 batch) · Epic 12 Task 12.10 (subscription disclosure UI for 5 jurisdictions) · Epic 13 Task 13.3 (warm accent on CTA) |
| Analytics | Epic 11 Tasks 11.1, 11.2, 11.3, 11.4, 11.5, 11.7, 11.10 (install/session/counter/variant/purchased\_at-minus-installed\_at) · Epic 11 Task 11.11 (opt-in anonymized export) |
| AI recap (Tier 2 on-device) | Epic 4 Task 4.2 (mark Tier 3 out-of-scope for v1.1; Tier 2 Gemini Nano is the v1.1 unlock) · Epic 11 Task 11.6 (recap feedback thumbs) · Epic 12 Task 12.4 (Art. 9 explicit consent gate) · Epic 12 Task 12.13 (AI Act transparency for the day Tier 3 ships) |
| Observability | Epic 10 Task 10.1 (Sentry, already v1) · Epic 1 Task 1.2 (crash-reporting opt-in, already v1) · Epic 11 Task 11.12 (notification-open counter) |
| Marketing | Epic 5 Task 5.5 (RevenueCat A/B paywall) · Epic 5 Task 5.8 (ADHDTok creator seeding — reviews drive Pro purchases) · Epic 5 Task 5.11 (trial-length A/B) · Epic 5 Task 5.14 (lifetime SKU vs subscription-trap defense) |

### II.3 v1.1 go/no-go gates

v1.1 ships only when ALL of the following are true:

1. v1 D7 retention ≥ target (target set post-launch based on first 2-week data).
2. At least 100 daily-active users — enough to power A/B variants without 50/50 bucketing starving either arm.
3. Subscription disclosure UI (Epic 12 Task 12.10) reviewed by privacy counsel ($1000–2500 budget).
4. AI recap feedback loop (Epic 11 Task 11.6) live for ≥ 2 weeks on the Tier 1 template version so Tier 2 prompt tuning has baseline thumbs-up/down data.
5. Age gate hardening (Epic 12 Task 12.3) complete — paid tiers can't ship until this is done.

### II.4 What v1.1 deliberately does NOT include

- **Cloud sync** — out of scope until v2. Per-device purchases only in v1.1.
- **Cloud AI Tier 3** — deferred to v2 pending Art. 9 explicit consent UX (Epic 12.4), AI Act transparency (Epic 12.13), Quebec PIA (Epic 12.13), and a DPA with the chosen model provider.
- **Caregiver / Retraq Care** — deferred to v2 (see Part III).
- **Family plan** — deferred to v2.

---

## Part III — v2 dropped scope

These features were in the original `implementation_plan.md` but have been dropped from v1/v1.1. They're preserved in this plan so the work isn't forgotten — and so nobody accidentally reintroduces them without the gating legal / technical prerequisites.

### III.1 Retraq Care (caregiver tier)

**Dropped from v1 decision:** 2026-04-06 (memory `project_feature_decisions.md`).
**Reintroduced in v2 only after:**

1. Epic 12 Task 12.12 — Caregiver pre-build legal framework signed off by outside privacy counsel ($5000–15000 CAD budget). Controllership model, capacity attestation, mandatory-reporter analysis, DPA template must ALL be resolved.
2. Epic 13 Task 13.5 — Sub-brand decision tree resolved (recommendation: "Retraq for Family" standalone sub-brand with shared Lexend+green but warmer, less-playful voice; separate App Store listing).
3. Epic 8 Tasks 8.2, 8.3, 8.4 — Schema additions (`userId` filtering on every query, `idx_journal_user_date`, `updatedAt`, `deletedAt`, `serverId` UUID, per-user settings row instead of id=1 singleton). Without these, multi-user caregiver data WILL leak across accounts.
4. Epic 3 Task 3.11 — Per-entry visibility ACL design; role column on Users.

**v2 feature sketch (non-binding, for context only):**

- Invite flow — user (the "subject") generates a caregiver invite code; caregiver (the "viewer") claims it in a separate Retraq-for-Family app.
- Read-only access by default; caregiver sees a dashboard of entry frequency, mood trend, recent entries' presence-or-absence (not necessarily content), flagged words user has pre-approved.
- Panic button — user-initiated revocation, instant and unconditional.
- Capacity attestation at invite — subject must demonstrate capacity to consent (no caregiver-initiated invites for incapacitated users without POA upload — hard problem; likely out-of-scope for v2 MVP).
- Separate ToS for caregivers; hold-harmless for data accuracy; explicit "not a medical device" disclaimer.
- No mandatory-reporter role for Retraq itself (app surfaces no automated elder-abuse alerts).

### III.2 Cloud AI Tier 3

**Dropped from v1 decision:** 2026-04-06.
**Reintroduced in v2 (or late v1.1) only after:**

1. Epic 12 Task 12.4 — Art. 9 explicit consent UX distinct from general ToS.
2. Epic 12 Task 12.13 — AI Act Art. 50 transparency disclosures; per-recap consent; pre-send confirmation.
3. Quebec PIA (Privacy Impact Assessment) complete — required under Law 25 for cross-border transfer of Quebec PI.
4. DPA signed with chosen AI provider (Anthropic / Google / OpenAI) with 0-retention terms.
5. Epic 3 Task 3.10 — Zero-knowledge envelope design if any PII is sent (current thinking: entries decrypted only on-device, encrypted request payload with provider-specific encryption at the transport layer; no long-term server storage).

### III.3 Cloud sync / family sharing

**Always-deferred to v2.** Requires Epic 8 Tasks 8.3, 8.4 schema work + Epic 3 Task 3.10 zero-knowledge design. Without these, cloud sync would upload plaintext journal content to the server — fundamentally incompatible with Retraq's privacy positioning.

**Design principle (non-binding):** user-passphrase-derived AES-GCM envelope; server sees only opaque ciphertext; reset-passphrase = orphan data (user's choice between convenience and security). This is the defining constraint that makes cloud sync compatible with the Retraq promise.

### III.4 Widget V2, voice entry, photo attachments, tags

These are **v1.1+ candidates** (not dropped outright):

| Feature | Where planned | Tier | Notes |
|---|---|---|---|
| Voice entry | Epic 4 Task 4.16 (reference), Agent 5 finding | v1.1 | Top ADHD-fit feature per Agent 5 competitive analysis; natural follow-on to "open, write, done." |
| Photo attachments | Memory `project_feature_decisions.md:15-18` (deferred) | v2 | Deliberately not v1 — "open, write, done" promise, no capture friction. |
| Tags | Memory deferred | v1.1+ | User-data insight could drive this as a v1.1 differentiator vs. Daylio's mood-only model. |
| Widget V2 (richer home-screen) | Current widget ships v1 | v1.1 | Current version is MVP; V2 with mood picker + quick-save inline is a v1.1 candidate. |

---

## 4. Appendices

### Appendix A — Traceability matrix (260 tasks)

All 260 tasks. Priority / Effort / Tier / Title. Detailed plan linked from the epic file.

#### Epic 1 — Code Architecture & Quality (`docs/plans/epic-01-code-architecture.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 1.1 | P0 | M | v1 | Narrow the bare catch around encrypted DB open |
| 1.2 | P1 | L | v1 | Extract _HomeSaveController and lift save logic out of home_screen.dart |
| 1.3 | P1 | L | v1 | Move Stats "On This Day" logic into StatsService |
| 1.4 | P1 | S | v1 | Replace remaining bare catches with typed handlers |
| 1.5 | P1 | S | v1 | Expand analysis_options.yaml with stricter lint rules |
| 1.6 | P2 | L | v1.1 | Replace singleton services with minimal DI (get_it) |
| 1.7 | P1 | S | v1 | Extract AppSnackBar helper |
| 1.8 | P2 | S | v1.1 | Introduce JournalEntry.fromRawRow to kill Drift mapping duplication |
| 1.9 | P2 | S | v1.1 | Adopt equatable for UserSettings |
| 1.10 | P3 | XS | backlog | Fold single-file providers/ into widgets/ |
| 1.11 | P3 | XS | no-op | Document atoms/molecules/organisms boundary rules in CONTRIBUTING |
| 1.12 | P3 | XS | no-op | Keep .gitignore as-is (reference) |
| 1.13 | P0 | M | v1 | Introduce AppLog wrapper + wire Sentry |
| 1.14 | P2 | S | v1.1 | Promote RecapService onto DatabaseService facade |
| 1.15 | P3 | XS | no-op | Keep stream-lifecycle hygiene as-is |
| 1.16 | P3 | XS | no-op | Keep migration strategy extraction as-is |
| 1.17 | P3 | XS | no-op | Keep PBKDF2 iteration + isolate as-is |
| 1.18 | P3 | XS | no-op | Keep main.dart bootstrap as-is |
| 1.19 | P3 | XS | no-op | Keep deprecated-API-free state as-is |

#### Epic 2 — UX & Information Architecture (`docs/plans/epic-02-ux-ia.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 2.1 | P0 | S | v1 | Localize mood selector labels and semantics |
| 2.2 | P0 | XS | v1 | Localize Week/Month segmented pill labels |
| 2.3 | P1 | S | v1 | Localize Stats week-tap snackbar with ICU plural |
| 2.4 | P0 | S | v1 | Show "Forgot PIN?" from first failed attempt |
| 2.5 | P1 | M | v1 | Collapse Stats tab into Recap via segmented pill |
| 2.6 | P1 | S | v1 | Detect prior consent and collapse onboarding intros |
| 2.7 | P1 | S | v1 | Split consent checkbox from document link |
| 2.8 | P1 | S | v1 | Add "Discard and switch" to AM/PM dialog |
| 2.9 | P1 | XS | v1 | Add reset-X to date-override chip |
| 2.10 | P1 | XS | v1 | Localize import summary SnackBar |
| 2.11 | P1 | XS | v1 | Localize Stats semantics |
| 2.12 | P2 | S | v1.1 | Add subtle edge-glow feedback on tab swipe attempts |
| 2.13 | P2 | M | v1.1 | Add empty-recent illustration/microcopy to Home |
| 2.14 | P2 | XS | v1 | Explain nudge skip-if-journaled behaviour |
| 2.15 | P2 | S | v1 | Tune save-success overlay hold after entry #10 |
| 2.16 | P3 | XS | no-op | Keep hero prompt daily rotation |
| 2.17 | P3 | XS | no-op | Keep typography stack |
| 2.18 | P3 | XS | no-op | Keep dark mode coverage |
| 2.19 | P3 | XS | no-op | Keep reduce-motion support |
| 2.20 | P3 | XS | no-op | Keep bionic reading, tablet 2-pane, milestones |

#### Epic 3 — Security & Privacy (`docs/plans/epic-03-security.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 3.1 | P0 | S | v1 | Set AndroidOptions(encryptedSharedPreferences: true) |
| 3.2 | P0 | M | v1 | Gate Forgot-PIN behind biometric + encrypted export |
| 3.3 | P0 | S | v1 | Fail release build when no real Android keystore |
| 3.4 | P0 | S | v1 | Apply FLAG_SECURE unconditionally |
| 3.5 | P0 | S | v1 | Render lock/blur on inactive/paused |
| 3.6 | P0 | M | v1 | iOS blur hook on applicationWillResignActive |
| 3.7 | P1 | S | v1.1 | Raise PBKDF2 iterations to 200-300K and re-version hash |
| 3.8 | P1 | S | v1 | Verify widget never reads DB while locked |
| 3.9 | P1 | S | v1 | Add in-UI warning on plaintext share-sheet export |
| 3.10 | P2 | XL | v2 | Design zero-knowledge cloud-sync envelope (gate) |
| 3.11 | P2 | XL | v2 | Design role + per-entry visibility for family sharing (gate) |
| 3.12 | P3 | XS | no-op | PBKDF2-HMAC-SHA256 baseline |
| 3.13 | P3 | XS | no-op | Constant-time PIN comparison |
| 3.14 | P3 | XS | no-op | Brute-force lockout |
| 3.15 | P3 | XS | no-op | Clock-rewind defense |
| 3.16 | P3 | XS | no-op | Lockout persisted to secure storage |
| 3.17 | P3 | XS | no-op | iOS Keychain first_unlock accessibility |
| 3.18 | P3 | XS | no-op | SQLCipher encryption via sqlite3mc |
| 3.19 | P3 | XS | no-op | .bak zeroed before deletion |
| 3.20 | P3 | XS | no-op | Biometric auth configuration |
| 3.21 | P3 | XS | no-op | Import validation |
| 3.22 | P3 | XS | no-op | Zero network calls |
| 3.23 | P3 | XS | no-op | Minimal Android permissions |
| 3.24 | P3 | XS | no-op | Android backup fully disabled |
| 3.25 | P3 | XS | no-op | iOS export compliance + Face ID string |
| 3.26 | P3 | XS | no-op | Release signing via key.properties/env |

#### Epic 4 — Product & Features (`docs/plans/epic-04-product.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 4.1 | P0 | M | v1 | Rewrite implementation_plan.md monetization section |
| 4.2 | P0 | S | v1 | Rewrite Epic 6 (cloud AI Tier 3 removal from v1) |
| 4.3 | P0 | S | v1 | Move caregiver/Alzheimer features to v2 |
| 4.4 | P1 | M | v1 | Hide AM/PM cutoff, bullets, bionic behind Advanced |
| 4.5 | P1 | S | v1 | Ship mood as single switch for v1 |
| 4.6 | P1 | S | v1 | Align README.md with current state |
| 4.7 | P1 | S | v1 | Add widget + tablet Epic mentions |
| 4.8 | P2 | XS | v1 | Rename "Journal" → "Jot" in plan nav refs |
| 4.9 | P2 | L | v1.1 | Plan v1.1 premium feature |
| 4.10 | P3 | XS | no-op | Preserve hero flow |
| 4.11 | P3 | XS | no-op | Preserve onboarding flow |
| 4.12 | P3 | XS | no-op | Preserve retention hooks |
| 4.13 | P3 | XS | no-op | Preserve no-home-edit/delete |
| 4.14 | P3 | XS | no-op | Preserve free-tier posture |
| 4.15 | P3 | XS | no-op | Preserve name + tagline |
| 4.16 | P3 | XS | no-op | Voice entry as v1.1 candidate |
| 4.17 | P3 | XS | no-op | Preserve 3-checkbox consent |

#### Epic 5 — Market & Go-to-Market (`docs/plans/epic-05-market-gtm.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 5.1 | P0 | M | v1 | v1 launch narrative hook + differentiation one-pager |
| 5.2 | P1 | M | v1 | Daylio battlecard + "memory backup" positioning |
| 5.3 | P1 | S | v1 | Apple Journal counter-positioning for iOS |
| 5.4 | P1 | S | v1 | "Your memories never leave your phone" privacy narrative |
| 5.5 | P1 | L | v1.1 | RevenueCat paywall A/B + price tier decision |
| 5.6 | P0 | S | v1 | Position vs Inflow as budget ADHD journal |
| 5.7 | P2 | L | v2 | Retraq Care caregiver wedge + memory-clinic pipeline |
| 5.8 | P1 | M | v1.1 | Seed ADHDTok creators, r/ADHD mods, therapists |
| 5.9 | P2 | M | v1.1 | Lightweight engagement hook spec vs Finch/Stoic |
| 5.10 | P2 | S | v1.1 | Position Retraq AI as enhancement vs Rosebud |
| 5.11 | P2 | S | v1.1 | Trial length 7-14 day A/B |
| 5.12 | P2 | XS | backlog | Quick Journal niche note |
| 5.13 | P2 | XS | v1.1 | Day One Gold price anchoring for cloud AI tier |
| 5.14 | P2 | S | v1.1 | Subscription-trap defense + lifetime SKU decision |

#### Epic 6 — Testing & Reliability (`docs/plans/epic-06-testing.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 6.1 | P1 | L | v1 | Expand integration E2E from smoke to journey |
| 6.2 | P1 | M | v1 | Timezone/DST edge-case tests |
| 6.3 | P1 | M | v1 | Mock local_auth channel for biometric tests |
| 6.4 | P2 | M | v1.1 | Concurrency and race-condition tests |
| 6.5 | P2 | S | v1 | Extract dedicated pin_service_test.dart |
| 6.6 | P2 | M | v1 | Direct tests for entry_repository + settings_repository |
| 6.7 | P2 | M | v1.1 | On-device streak SQL integration test |
| 6.8 | P2 | M | v1.1 | Notification scheduling tests beyond content |
| 6.9 | P2 | S | v1.1 | export_service_test invokes real service |
| 6.10 | P2 | S | v1 | Smoke tests for main, app_shell, splash, reconsent |
| 6.11 | P2 | M | v1 | Widget coverage gaps (6 widgets) |
| 6.12 | P1 | XS | v1 | Split dart_test.yaml fast unit vs slow integration |
| 6.13 | P1 | XS | v1 | Align CI floor with Codecov targets |
| 6.14 | P3 | XS | no-op | Preserve PIN v3 coverage during extraction |
| 6.15 | P3 | S | v1.1 | Extend lockout_controller tests with post-timer |
| 6.16 | P3 | S | v1.1 | v13→v14 direct migration path test |
| 6.17 | P3 | XS | no-op | Preserve column-drop regression |
| 6.18 | P3 | XS | no-op | Preserve boundary/edge DB tests |
| 6.19 | P3 | XS | no-op | Preserve test_helpers + patterns |
| 6.20 | P3 | XS | no-op | Preserve CI/CD posture |
| 6.21 | P0 | L | backlog | Golden / visual regression tests |
| 6.22 | P1 | M | backlog | Accessibility tests (SemanticsTester, 48dp) |
| 6.23 | P3 | L | backlog | Fuzz / property tests via glados |
| 6.24 | P3 | M | backlog | Performance benchmarks |
| 6.25 | P3 | XS | no-op | Thin-tests umbrella preservation |
| 6.26 | P3 | S | v1.1 | Codify wrapWidget + flushDriftTimers via custom lint |

#### Epic 7 — Accessibility & i18n (`docs/plans/epic-07-accessibility.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 7.1 | P0 | S | v1 | Raise faint hint-text contrast to 1.4.3 AA |
| 7.2 | P0 | XS | v1 | Fix PageIndicatorDots contrast to 1.4.11 |
| 7.3 | P1 | S | v1 | Route EntryActionMenu through L10n |
| 7.4 | P1 | S | v1 | Localize WeekDayList |
| 7.5 | P1 | S | v1 | Localize MoodSelector |
| 7.6 | P1 | S | v1 | Localize home-screen hero prompts |
| 7.7 | P1 | XS | v1 | Raise backdated meta-text alpha |
| 7.8 | P1 | S | v1 | Fix calendar dim contrast |
| 7.9 | P2 | XS | v1 | Localize NudgeCard |
| 7.10 | P2 | XS | v1 | Localize NumberPad fallbacks |
| 7.11 | P2 | XS | v1 | Raise MoodSelector unselected opacity |
| 7.12 | P2 | XS | v1 | Darken light-mode outlineVariant |
| 7.13 | P2 | M | v2 | "Easy-tap" calendar mode (≥48dp cells) |
| 7.14 | P2 | S | v1.1 | Resolve RetraqButton double-Semantics |
| 7.15 | P2 | M | v1.1 | Audit text scale 2.0 regressions |
| 7.16 | P2 | XS | v1 | Raise DeleteConfirmDialog error-text contrast |
| 7.17 | P2 | L | v2 | Add RTL locale + audit EdgeInsets.only |
| 7.18 | P2 | S | v1.1 | Lint rule for AppMotion bypasses |
| 7.19 | P3 | XS | no-op | EntryActionMenu 48×48 (reference) |
| 7.20 | P3 | XS | no-op | PadButton 72×72 (reference) |
| 7.21 | P3 | XS | no-op | ConsentPage InkWell (reference) |
| 7.22 | P3 | XS | no-op | HomeScreen undo (reference) |
| 7.23 | P3 | XS | no-op | AppMotion.aware (reference) |
| 7.24 | P3 | XS | no-op | NudgeCard contrast (reference) |
| 7.25 | P3 | XS | no-op | "Previously…" context (reference) |
| 7.26 | P3 | XS | no-op | Onboarding page-count (reference) |

#### Epic 8 — Performance & Scalability (`docs/plans/epic-08-performance.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 8.1 | P0 | M | v1 | Remove shrinkWrap/NeverScrollable from Month/Search views |
| 8.2 | P1 | M | v2 | Add userId filtering + idx_journal_user_date |
| 8.3 | P1 | L | v2 | Add updatedAt, deletedAt, serverId UUID |
| 8.4 | P1 | M | v2 | Per-user settings row replacing id=1 singleton |
| 8.5 | P2 | M | v1.1 | Lazy IndexedStack + pause streams on inactive tabs |
| 8.6 | P2 | S | v1.1 | HomeScreen streams → StreamBuilder with tab-blur |
| 8.7 | P2 | S | v1.1 | Cap getCurrentStreak window |
| 8.8 | P2 | XS | backlog | Synchronous splash if DB init regresses |
| 8.9 | P2 | S | backlog | Signature-cache monthly watches if hot |
| 8.10 | P3 | XS | backlog | Move getTotalEntryCount off main isolate |
| 8.11 | P3 | XS | v1 | Verify WidgetService.update fire-and-forget |
| 8.12 | P3 | S | backlog | Cache SQLCipher-probe result |
| 8.13 | P3 | XS | no-op | flutter_animate shake preserved |
| 8.14 | P3 | XS | no-op | watchEntriesForDate preserved |
| 8.15 | P3 | XS | no-op | watchAllStats signature-cache preserved |
| 8.16 | P3 | XS | no-op | compute() isolate export preserved |
| 8.17 | P3 | XS | no-op | Import dedup preserved |
| 8.18 | P3 | XS | no-op | NavigationBar RepaintBoundary preserved |
| 8.19 | P3 | XS | no-op | _shakeController preserved |
| 8.20 | P3 | XS | no-op | FTS5 prefix match preserved |

#### Epic 9 — App Store Readiness (`docs/plans/epic-09-app-store.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 9.1 | P0 | L | v1 | Produce complete App Store + Play screenshot set |
| 9.2 | P0 | M | v1 | Draft listing copy (title, subtitle, desc, keywords) |
| 9.3 | P1 | M | v1 | ASO keyword research + strategy table |
| 9.4 | P1 | S | v1 | Lock category + Google Play Health declaration |
| 9.5 | P0 | S | v1 | Add PrivacyInfo.xcprivacy |
| 9.6 | P1 | XS | v1 | Bump version from 1.0.0+1 |
| 9.7 | P2 | M | v1.1 | Plan cloud-AI privacy nutrition label rewrite |
| 9.8 | P1 | S | v1 | Guard "memory backup" framing against 1.4.1 risk |
| 9.9 | P1 | S | v1 | 4+/Everyone rating + caregiver uplift plan |
| 9.10 | P1 | S | v1 | Document v1 (no IAP) → v1.1 (RevenueCat) posture |
| 9.11 | P1 | M | v1 | TestFlight + Internal → soft-launch → global |
| 9.12 | P2 | S | v1 | A/B subtitle: with/without "Lost traq?" pun |
| 9.13 | P3 | XS | no-op | Retraq distinctive (reference) |
| 9.14 | P3 | XS | no-op | Brand-guide copy on-brand (reference) |
| 9.15 | P3 | XS | no-op | Android permissions minimal (reference) |
| 9.16 | P3 | XS | no-op | iOS permission strings concise (reference) |
| 9.17 | P3 | XS | no-op | Export compliance pre-declared (reference) |
| 9.18 | P3 | XS | no-op | "Data Not Collected" defensible (reference) |
| 9.19 | P3 | XS | no-op | COPPA age gate + consent (reference) |
| 9.20 | P3 | XS | no-op | Biometric-only + PIN fallback (reference) |

#### Epic 10 — DevOps & CI/CD (`docs/plans/epic-10-devops.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 10.1 | P0 | M | v1 | Wire Sentry crash reporting |
| 10.2 | P1 | L | v1.1 | iOS TestFlight upload via fastlane |
| 10.3 | P0 | XS | v1 | Align .fvmrc with CI Flutter 3.41.6 |
| 10.4 | P1 | S | v1 | Fail loud when Android release falls to debug keys |
| 10.5 | P1 | XS | v1 | Rename "Isar" → "Drift" in scripts |
| 10.6 | P2 | S | v1 | Prerequisite checks in build scripts |
| 10.7 | P2 | M | v1.1 | Play Store internal track deployment |
| 10.8 | P1 | XS | v1 | Upload LCOV to Codecov |
| 10.9 | P2 | XS | v1 | CI enforcement of l10n/ARB regeneration |
| 10.10 | P3 | M | backlog | Port build scripts to Dart / add .ps1 |
| 10.11 | P3 | XS | backlog | ios-podfile ecosystem for Dependabot |
| 10.12 | P3 | S | backlog | Hand-curated CHANGELOG.md |
| 10.13 | P3 | L | v2 | Dev/staging/prod product flavors |
| 10.14 | P3 | XS | no-op | Tag-driven release versioning (reference) |
| 10.15 | P3 | XS | no-op | SHA-pinned actions (reference) |
| 10.16 | P3 | XS | no-op | pubspec.lock committed (reference) |
| 10.17 | P3 | XS | no-op | Codegen integrated (reference) |
| 10.18 | P3 | XS | no-op | Coverage 45/70/70 (reference) |
| 10.19 | P3 | XS | no-op | Smoke build on PR (reference) |
| 10.20 | P3 | XS | no-op | Gradle/Flutter caching (reference) |
| 10.21 | P3 | XS | no-op | DEVELOPMENT_TEAM via xcconfig (reference) |

#### Epic 11 — On-device Analytics (`docs/plans/epic-11-analytics.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 11.1 | P2 | S | v1.1 | Install + first-entry timestamps |
| 11.2 | P2 | M | v1.1 | Local app_sessions table for cohort/retention |
| 11.3 | P2 | S | v1.1 | Reframe StatsSnapshot + add entriesPerActiveDay |
| 11.4 | P2 | M | v1.1 | Local-only feature_counters KV table |
| 11.5 | P2 | S | v1.1 | Per-step onboarding timestamps |
| 11.6 | P2 | M | v1.1 | Local recap_feedback table (thumbs) |
| 11.7 | P2 | S | v1.1 | Deterministic local variant bucketer |
| 11.8 | P3 | S | v1.1 | Correlate mood with engagement |
| 11.9 | P3 | XS | no-op | De-scope caregiver metrics |
| 11.10 | P2 | XS | v1.1 | Purchased_at − installed_at minimal metric |
| 11.11 | P2 | M | v1.1 | exportAnonymizedStats() opt-in share |
| 11.12 | P3 | S | v1.1 | Notification-open counter |
| 11.13 | P3 | S | v1.1 | Analytics kill switch in Settings → Data |
| 11.14 | P3 | XS | no-op | On-This-Day year-one recurrence |

#### Epic 12 — Legal & Compliance (`docs/plans/epic-12-legal.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 12.1 | P1 | S | v1 | CI integration guard for no-network posture |
| 12.2 | P1 | M | v1 | Controller disclosure + supervisory authorities |
| 12.3 | P0 | M | v1 | Country-aware age gate (13/14/16) |
| 12.4 | P1 | M | v1.1 | Art. 9 explicit consent gate for cloud AI |
| 12.5 | P3 | XS | no-op | Health claims copy already conservative |
| 12.6 | P1 | S | v1 | Mandatory local consumer law carve-out to Terms |
| 12.7 | P3 | XS | no-op | Consent version bumps (reference) |
| 12.8 | P3 | XS | no-op | Data export satisfies GDPR 20 (reference) |
| 12.9 | P2 | S | v1 | Verify Delete-All-Data is irrecoverable |
| 12.10 | P0 | M | v1.1 | Subscription disclosure UI (5 jurisdictions) |
| 12.11 | P1 | S | v1 | Disclose Canadian entity + mailing address |
| 12.12 | P0 | XL | v2 | Caregiver pre-build legal framework |
| 12.13 | P1 | M | v1.1 | AI transparency disclosures for cloud AI |
| 12.14 | P1 | L | v1 | Independent WCAG 2.2 AA audit |
| 12.15 | P3 | XS | no-op | US export compliance flag correct |
| 12.16 | P1 | S | v1 | Localize crisis contacts per locale |

#### Epic 13 — Brand & Visual Identity (`docs/plans/epic-13-brand.md`)

| ID | P | E | Tier | Title |
|---|---|---|---|---|
| 13.1 | P0 | L | v1 | Redesign app icon (Q-motif) |
| 13.2 | P1 | S | v1.1 | Custom mood-scale palette |
| 13.3 | P1 | S | v1.1 | Warm amber accent for CTAs |
| 13.4 | P2 | S | v1 | Logo small-size silhouette test |
| 13.5 | P3 | L | v2 | Sub-brand decision tree for caregiver |
| 13.6 | P1 | M | v1 | CIPO + USPTO trademark filings |
| 13.7 | P1 | S | v1 | Archive Lately/SinceThen assets; lock Retraq brand |
| 13.8 | P3 | XS | no-op | Retraq distinctive (reference) |
| 13.9 | P3 | XS | no-op | No store conflicts (reference) |
| 13.10 | P3 | XS | no-op | Lexend + Manrope (reference) |
| 13.11 | P3 | XS | no-op | Onboarding copy preserved (reference) |
| 13.12 | P3 | XS | no-op | Empty state copy preserved (reference) |
| 13.13 | P3 | XS | no-op | Milestone copy preserved (reference) |
| 13.14 | P3 | XS | no-op | Tagline as subtitle (reference) |
| 13.15 | P3 | XS | no-op | Traq vocabulary preserved (reference) |
| 13.16 | P3 | XS | no-op | Clinical-language forbidden (reference) |
| 13.17 | P3 | XS | no-op | Anti-obligation positioning (reference) |
| 13.18 | P2 | S | v1 | Competitor visual battlecard |
| 13.19 | P3 | XS | no-op | Social potential preserved (reference) |
| 13.20 | P3 | XS | no-op | Premium perception (reference) |
| 13.21 | P3 | XS | no-op | Trademark symbol rules (reference) |

### Appendix B — Files most heavily touched

The plan's 88 v1-launch tasks concentrate on these files. Merge-conflict risk is highest where multiple epics touch the same file.

| File | Epics that modify it | Coordination note |
|---|---|---|
| `lib/services/database_service.dart` | 1 (Tasks 1.1), 3, 8, 11 | Task 1.1 must land first (critical bug); subsequent schema work in Epic 8/11 builds on stable init path. |
| `lib/screens/home_screen.dart` | 1 (refactor), 2 (UX polish), 7 (hero prompts L10n), 8 (stream pause) | Epic 1 Task 1.2 refactor lands first; others rebase onto extracted HomeSaveController. |
| `lib/screens/stats_screen.dart` | 1 (Task 1.3), 2 (Task 2.5 fold-into-Recap) | Task 1.3 first, then Task 2.5 fold. |
| `lib/l10n/app_en.arb` | 2 (i18n leaks), 7 (a11y i18n), 12 (legal text), 13 (brand copy preservation annotations) | All ARB edits coordinate — batch a single `flutter gen-l10n` regeneration commit per epic rather than mixing. |
| `lib/theme/app_colors.dart` | 7 (contrast fixes), 13 (mood-scale custom, amber accent) | Epic 7 contrast fixes first, then Epic 13 palette extensions. |
| `lib/legal/privacy_policy.dart` · `terms_of_service.dart` · `health_disclaimer.dart` | 12 (controller disclosure, carve-out, crisis lines, Art. 9, AI transparency) | Single consent-version bump per coordinated release; don't scatter. |
| `android/app/src/main/AndroidManifest.xml` · `android/app/build.gradle.kts` | 3 (FLAG_SECURE, keystore fail-loud), 10 (CI hook) | Coordinated review. |
| `ios/Runner/Info.plist` · `ios/Runner/PrivacyInfo.xcprivacy` | 3 (iOS blur), 9 (PrivacyInfo entries), 12 (legal) | Coordinated review. |
| `.github/workflows/ci.yml` · `release.yml` | 6 (test splits), 10 (Sentry symbols, Codecov, l10n check), 12 (no-network guard) | One workflow-edit commit per epic; avoid simultaneous PRs. |
| `pubspec.yaml` | 1 (get_it, sentry_flutter, equatable), 10 (Dependabot) | Batch dependency adds; run `flutter pub outdated` as CI check (Epic 10). |
| `lib/services/export_service.dart` | 3 (warning on plaintext share), 11 (anonymized stats export), 12 (GDPR portability docs) | Epic 11 adds a new export variant; Epic 3 adds a UI warning on the primary export. No schema collision. |

### Appendix C — Key architectural decisions (ADRs to write)

The plan references several forks that deserve ADRs in `app/docs/adr/`:

| ADR | Task origin | Decision |
|---|---|---|
| `001-crash-reporting-sentry-vs-crashlytics.md` | Epic 10 Task 10.1 | Recommendation: **Sentry**. Rationale: privacy-friendlier defaults, better Dart stack traces, opt-in toggle maps cleanly; avoids Firebase SDK bloat. |
| `002-state-management-stateful-widget-plus-streams.md` | Epic 1 audit (pure-StatefulWidget scaling concern) | Decision: **stay with StatefulWidget + Streams + SettingsProvider** through v1.1. Re-evaluate if home/stats screens regrow past 600 LOC post-refactor. |
| `003-di-get-it.md` | Epic 1 Task 1.7 | Recommendation: **get_it** over provider/Riverpod. Rationale: minimal, ~3kB, explicit registration; compatible with StatefulWidget pattern. |
| `004-monetization-one-time-plus-cloud-sub.md` | Epic 4 Task 4.9, Part II above | Decision: one-time Retraq Pro + optional monthly Cloud Recap. Anti-subscription-fatigue framing for ADHD market. |
| `005-subbrand-caregiver-retraq-for-family.md` | Epic 13 Task 13.5 | Decision gate: produce 3 concepts at v2 planning; recommendation is standalone sub-brand "Retraq for Family" with shared typography + palette but warmer voice. |
| `006-analytics-privacy-local-only.md` | Epic 11 prime directive | Decision: **zero telemetry by default**; opt-in anonymized stats share via existing `ExportService`. No HTTP client added to app for analytics. |
| `007-age-gate-country-aware.md` | Epic 12 Task 12.3 | Decision: country-aware threshold table; fall back to device locale + optional self-declaration (no geo-IP). |
| `008-icon-direction-q-motif.md` | Epic 13 Task 13.1 | Decision gate: 3 concepts (Q-pin, Q-speech-bubble, Q-dot-marker) tested against 12 competitor icons. Winner locked after shelf test. |

### Appendix D — Budget summary

External one-time costs for v1 launch (all CAD unless noted):

| Workstream | Item | Low | High |
|---|---|---|---|
| Legal | Privacy counsel initial review (12.2) | $500 | $1500 |
| Legal | Art. 9 consent review for cloud AI (12.4, v1.1) | $2000 | $5000 |
| Legal | Terms carve-out review (12.6) | $500 | $1000 |
| Legal | Subscription disclosure review (12.10, v1.1) | $1000 | $2500 |
| Legal | Caregiver pre-build framework (12.12, v2) | $5000 | $15000 |
| Legal | AI Act transparency + PIA (12.13, v1.1) | $1500 | $3000 |
| A11y | Independent WCAG 2.2 AA audit (12.14) | $3000 | $10000 |
| Brand | Icon design (13.1) | $500 | $2500 |
| Brand | CIPO + USPTO filings (13.6) | $500 | $2000 |
| Brand | Trademark attorney (13.6 optional) | $500 | $1500 |
| Infra | Sentry plan (free tier sufficient initially) | $0 | $0 |
| Infra | RevenueCat (free tier up to $2.5K MTR) | $0 | $0 |
| Infra | Apple Developer Program | $99 USD/yr | $99 USD/yr |
| Infra | Google Play Developer | $25 USD one-time | $25 USD one-time |
| | **v1 launch subtotal (excl. v1.1/v2 legal)** | **$5,625 CAD** | **$18,625 CAD** |
| | **Full plan (v1+v1.1+v2)** | **~$15,000 CAD** | **~$44,000 CAD** |

All budgets exclude the user's own time.

### Appendix E — Post-commit verification checklist

After every task's commit lands on `main`:

- [ ] CI green (analyze + test + coverage ≥ 45%)
- [ ] Acceptance criteria in the task plan checked off
- [ ] Commit message references Task ID
- [ ] Commit pushed to `BradHudsonGrant/Retraq`
- [ ] If consent-version bumped: re-consent flow tested in an integration run
- [ ] If schema migration: migration test added and passes
- [ ] If legal-text change: backup of prior text in `app/docs/legal/<date>-<topic>.md`
- [ ] If icon/logo change: home-screen shelf test artifact archived

---

## 5. Changelog of this plan

| Date | Change |
|---|---|
| 2026-04-16 | Initial authoritative rewrite, 260 tasks across 13 epics, synthesized from `review-2026-04-16.md` audit. Supersedes the pre-April plan (backed up as `../implementation_plan.md.bak-2026-04-16`). |

Future updates append here.
