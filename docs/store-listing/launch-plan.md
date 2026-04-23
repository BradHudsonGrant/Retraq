# Retraq v1 launch plan

**Status:** Ready to execute when B-3 Apple Developer + B-4 Play
Console accounts land · **Task:** 9.11 · **Last updated:** 2026-04-16

Staged rollout plan for Retraq v1 across iOS and Android. Informed
by the Android-first decision (see `../gtm/android-first-positioning.md`)
and sequenced against Epic 10 observability readiness (Sentry — B-1
gates, Crashlytics path explicitly rejected per Task 10.1 decision).

## Rollout principles

1. **Android first, iOS second.** 4-week stagger per
   `android-first-positioning.md`. Android accumulates 4★+
   reviews before facing the Apple Journal comparison.
2. **Closed → Open → Public** on each platform. Staged
   rollout percentages avoid "everyone gets a shipped p0."
3. **Rollback gated on objective thresholds**, not vibes. If
   the thresholds trip, we pause and investigate — no debate.
4. **Review sentiment is a guardrail**, not a metric to game.
   If testers say the app is confusing, we fix; we don't
   manipulate the rating.

## Phase A — Pre-launch setup (week −2 to week 0)

Before any tester touches a build:

- [ ] **Apple Developer account active** (B-3) — paid annual
      membership ($99/yr).
- [ ] **Play Console account active** (B-4) — one-time $25
      registration.
- [ ] **Canadian business entity registered** (B-5) — required
      for Apple Paid Applications Agreement in v1.1 but
      optional for v1 free submission; still tracked here.
- [ ] **Apple App Store Connect app created** — bundle ID
      `com.retraq.app`.
- [ ] **Play Console app created** — package name
      `com.retraq.app`.
- [ ] **Sentry project created** (B-1) + DSN in GitHub Secrets.
      Without Sentry, we fly blind on crashes.
- [ ] **App icon finalized** (B-7 designer) — the single
      biggest first-impression lever per Task 13.1.
- [ ] **Screenshots produced** (B-17 vendor) — 5-screenshot
      set with overlay copy per `../gtm/privacy-narrative.md`.
- [ ] **Listing copy scrubbed through** `health-claim-guardrails.md`
      (Task 9.8) and signed off.
- [ ] **Categories locked** per
      `categories-and-health-declaration.md` (Task 9.4).
- [ ] **Age-rating questionnaires answered** per
      `age-rating-ios.md` + `age-rating-android.md` (Task 9.9).

## Phase B — Internal Testing (week 0–2)

**iOS: TestFlight Internal Testing** — internal team only,
up to 100 Apple IDs. No separate App Review required.

**Android: Play Internal Testing track** — internal team only,
up to 100 Gmail addresses, no Play Review required, builds go
live within minutes.

### Invite list — ~25 testers

- 3 core contributors (minimum).
- 5 friends/family who match the ICP persona (busy brains,
  journal-curious, memory-keen).
- 5 other adults for "does this make sense at all?" check.
- 5 technically-inclined testers who will actually file bug
  reports (preferably on different Android device vendors —
  Pixel, Samsung, OnePlus).
- 5 iOS-only testers with different iPhone models (iPhone 13+
  should cover the baseline; one older iPhone 11/12 for
  backwards-compat verification).
- 2 accessibility-focused testers (TalkBack / VoiceOver users).

### Device-testing matrix

Minimum device coverage before advancing to Phase C:

| Platform | Device | Why |
|---|---|---|
| Android | Pixel 10 Pro | Primary dev device — already covered |
| Android | Older Pixel (5/6) | Older GPU, memory-constrained |
| Android | Samsung Galaxy S23+ | Largest Android OEM; OneUI has UX quirks |
| Android | Tablet (Pixel Tab / Galaxy Tab) | Adaptive 2-pane layout verification |
| iOS | iPhone 15+ | Default simulator coverage extended to hardware |
| iOS | iPhone 12 or 13 | Older device for memory + size-class |
| iOS | iPad | Adaptive 2-pane on iPadOS |

### Pass criteria before Phase C

- [ ] Zero p0 crashes in the last 5 days of Phase B.
- [ ] Every tester has logged ≥ 5 traqs successfully.
- [ ] At least 3 testers confirm "I actually want to keep
      using this" (qualitative).
- [ ] Crash-free rate ≥ 99.5% (Sentry).
- [ ] Biometric-unlock flow tested on at least one iOS +
      one Android device.
- [ ] Export → re-import roundtrip verified by ≥ 2 testers.
- [ ] App-store listing drafts reviewed and approved in
      private listings on both stores.

## Phase C — Soft launch (week 3–4)

**iOS: TestFlight Open Testing** (up to 10,000 external testers)
with a public TestFlight link. Separate App Review required —
budget 24–48h for approval.

**Android: Play Open Testing track** with geo-restricted
release to **CA, AU, NZ**. English-speaking, IARC-lenient, low
total-user volume (good for "catch a crash without poisoning
global review sentiment").

### Geo scope rationale

- **Canada** — home market; low risk and easy to iterate.
- **Australia + New Zealand** — English-speaking, different
  device-mix than NA (more Samsung / older Android), good
  coverage for Android-specific issues.
- **Explicitly excluded in soft launch:** US (high review
  volume risk), UK (EU-adjacent legal context we'd rather have
  more observability data for first), Germany (GDPR scrutiny),
  all non-English markets (localization work blocks this).

### What gets measured

Via Sentry + Play Console + App Store Connect dashboards (no
Epic 11 opt-in export at this stage — too early for that
signal):

| Metric | Target | Guardrail |
|---|---|---|
| Crash-free rate | ≥ 99.5% | Pause if < 99% |
| ANR rate (Play) | < 0.5% | Pause if > 1% |
| 1-star review rate | < 5% | Pause + investigate if > 10% |
| Uninstall rate (7-day) | < 30% | Pause if > 50% |
| Mean D1 retention | ≥ 45% | Investigate if < 35% |
| Mean D7 retention | ≥ 25% | Investigate if < 18% |

### Pass criteria before Phase D

- [ ] All Phase C metrics hit target for at least 7 consecutive
      days.
- [ ] No p0 crash identified in the last 7 days.
- [ ] Store review sentiment ≥ 4.2 stars (≥ 20 reviews).
- [ ] No regulatory request / App Review concern raised on
      either platform.
- [ ] Any ASO keyword adjustment informed by soft-launch
      search-term data has been applied.

## Phase D — Global release (week 5–6)

**iOS: App Store public release** — unfurl by region starting
with Anglophone + Western EU, excluding high-regulatory-
friction markets (China, Russia) on day one.

**Android: Play Production** with **staged rollout percentages**:
  - Day 0: 10% of target users in target regions
  - Day 3: 25% if no regressions
  - Day 7: 50%
  - Day 14: 100%

### Global scope

Target regions for v1:
- North America (CA, US)
- Europe: UK, IE, FR, DE, NL, SE, DK, NO, FI
- Oceania: AU, NZ
- Asia (English): SG, HK
- Japan (English + ASO in Japanese — deferred to v1.1
  localization)

Excluded from v1 global release:
- China (data-localization requirements we haven't scoped)
- Russia (sanctions / App Store policy friction)
- Non-English markets requiring localization (tracked for
  v1.1 per Epic 7 RTL + translation work)

### Pass criteria — v1 done

- [ ] Global release on both platforms for 14+ consecutive days.
- [ ] No regressions surfaced post-50% rollout.
- [ ] Store rating ≥ 4.3 average across both stores.
- [ ] v1.1 roadmap (from `implementation_plan.md` Part II)
      re-confirmed against real-world usage data.

## Rollback criteria — any phase

Regardless of phase, we pause the rollout if:

- **p0 crash** (app unusable, data loss risk, security
  regression) — immediate halt + hotfix.
- **Crash-free rate drops below 99%** over rolling 3 days.
- **1-star review rate above 10%** over rolling 3 days.
- **Regulator / App Review escalation** — halt and consult
  legal (Epic 12).
- **Privacy regression identified** (network call detected by
  `no_network_invariant_test.dart` in CI or similar) — halt
  and investigate; this is the load-bearing privacy claim.

Rollback procedure (Android):
1. Pause staged rollout in Play Console.
2. Identify regression, fix, push hotfix to Internal.
3. Re-start rollout at the last safe percentage.

Rollback procedure (iOS):
1. App Store doesn't support automatic rollback. Instead,
   "Remove from sale" the regressed version.
2. Publish fixed build; users who already have the regressed
   version get the fix on next auto-update.
3. Communicate via push notification ONLY if the regression
   is security-related; otherwise let the standard update
   path handle it.

## Observability backstop

Without wired Sentry (B-1 blocker), this plan leans on:

- Manual tester reports from Phase B.
- Platform-native crash dashboards (App Store Connect + Play
  Console) — less granular than Sentry but sufficient for
  p0 detection at Phase C volumes.
- Play Pre-Launch Report on every new build (automatic for
  Internal + Closed tracks).

**If B-1 lands before Phase C**, we wire Sentry before any
real user sees a build. **If B-1 slips past Phase C**, we
accept the reduced granularity but pause more aggressively
(tighter crash-free threshold 99.7% instead of 99.5%).

## External blockers

Gating the launch plan:

- **B-1 Sentry DSN** — crash reporting wiring (Task 10.1)
- **B-3 Apple Developer account** — mandatory for any iOS
  submission
- **B-4 Play Console account** — mandatory for any Android
  submission
- **B-5 Canadian business entity** — optional for v1 free;
  required for v1.1 paid
- **B-7 Icon designer** — launch without a distinctive icon
  caps Phase D rating ceiling; tracked as a launch-blocker
  per Task 13.1
- **B-17 Screenshot vendor** — launch screenshots informed by
  `../gtm/privacy-narrative.md` + `../gtm/engagement-hook-spec.md`

## Sibling artifacts

- [`../gtm/android-first-positioning.md`](../gtm/android-first-positioning.md)
  — launch ordering rationale
- [`../gtm/positioning-one-pager.md`](../gtm/positioning-one-pager.md)
  — narrative hook used across phases
- [`categories-and-health-declaration.md`](./categories-and-health-declaration.md)
  — category posture
- [`age-rating-ios.md`](./age-rating-ios.md),
  [`age-rating-android.md`](./age-rating-android.md) — rating
  questionnaire answers
- [`iap-posture.md`](./iap-posture.md) — v1 free posture
  (paywall lands in v1.1, separate launch cycle)
- [`../plans/epic-10-devops.md`](../plans/epic-10-devops.md)
  — Task 10.1 crash reporting (Sentry not Crashlytics)
- [`../external-blockers.md`](../external-blockers.md) — the
  full B-list gating this plan
