# Store-listing A/B test plan

**Status:** Spec ready — activate T+14 days post-launch ·
**Task:** 9.12 · **Last updated:** 2026-04-16

A/B tests for store-listing elements that benefit from real
impression data. Runs via Apple's Product Page Optimization
(PPO) and Google Play's Store Listing Experiments.

Pre-condition: need at least 14 days of baseline global-release
data (end of Phase D in `launch-plan.md`) before starting any
test. Otherwise we're chasing noise.

## Primary experiment — iOS App Store subtitle pun

### The question

The subtitle `Lost traq? Retraq.` (28 chars, primary per
`../gtm/narrative-hook.md`) is strong brand voice but forces
users to learn an unusual spelling before converting. Does the
pun help or hurt Impression → Install conversion?

### Variants

Apple PPO allows 3 variants (control + 2 challengers):

| Variant | Subtitle (≤30 chars) | Angle |
|---|---|---|
| **A (control)** | `Lost traq? Retraq.` (28) | Brand pun — primary per narrative hook |
| **B** | `Your memory backup.` (19) | Non-pun privacy / recall frame |
| **C** | `The journal that remembers.` (28) | Non-pun recall-first frame |

All three stay within 30-char limit. All three pass the
`health-claim-guardrails.md` green-list check. All three pass
the `positioning-one-pager.md` "no 'simple'/'fast'" rule.

### Metric definitions

**Primary:** Impression → Install conversion rate
(per App Store Connect PPO report).

**Secondary:**
- Impression → Product Page View rate
- Product Page View → Install rate
- Install → 7-day retention rate (do the winning installs stick?)

**Guardrail:**
- 7-day uninstall rate per variant — if variant B or C wins on
  conversion but loses on retention by ≥ 5pp, the "winning"
  pitch attracts a worse-fit audience. Stay with control.

### Duration + sample

- **Duration:** 14 days.
- **Split:** 33/33/33 across A/B/C.
- **Minimum impressions per arm:** 10,000.
- **Skip if:** daily organic impression volume < 2,500 (extend
  to 21 days or pause until launch-flywheel builds).

### Analysis

- Two-proportion z-test pairwise (A vs B, A vs C), α = 0.05,
  one-sided (we only roll out a challenger if it beats A).
- Bonferroni correction for 2 tests: each uses α = 0.025.
- Practical-significance floor: 2pp lift required before
  rolling out. A 0.3pp statistically-significant win isn't
  worth the brand-consistency cost of changing the primary
  subtitle.

### Decision rules

- **Variant B wins by ≥ 2pp AND guardrail intact:** roll B as
  new control; re-check pairing with icon + screenshot copy
  in `privacy-narrative.md` (which leads with a similar
  frame — consistency wins).
- **Variant C wins by ≥ 2pp AND guardrail intact:** roll C as
  new control.
- **A wins or no challenger beats by 2pp:** keep `Lost traq?
  Retraq.` and mark this question settled for at least 6 months.
- **Guardrail tripped:** roll back to A regardless of primary
  metric.

### Why not paywall A/B tests

This subtitle test is explicitly for the iOS App Store LISTING
subtitle. It does NOT include any paywall copy — paywall A/B is
governed by `../gtm/anti-dark-pattern-copy.md` and Task 5.5,
and is out-of-scope here.

## Secondary experiment — Android Play short description

Google Play Store Listing Experiments allow up to 5 variants.
Same three subtitle candidates, adapted to Play's 80-char short
description slot:

| Variant | Short description (≤80 chars) |
|---|---|
| **A (control)** | `Memory backup for busy brains. Drop a sentence a day, retraq your week.` (69) |
| **B** | `Your memory backup. On-device journal with weekly recap. No sync, no ads.` (72) |
| **C** | `The journal that remembers. Weekly recap of a week you wouldn't have.` (69) |

Aligns with the iOS test so a winning frame on one platform
informs the other rather than getting two divergent narratives.

### Secondary metric

- Play Console Store Listing Experiment report gives Install
  Conversion Rate natively — same decision rules as iOS.

## Do NOT test — preserved as-is

The following elements are **not** subject to A/B testing on the
store listings (lock these until a strategic re-review):

- **App icon** — brand consistency > listing micro-optimization.
  Revisit only if B-7 icon designer lands a v2 and the team
  explicitly decides to test.
- **Primary screenshot order** — ordering is set by
  `../gtm/privacy-narrative.md` + `engagement-hook-spec.md`
  and leads with recall → privacy → empty-state warmth.
  Don't split-test until there's a strategic hypothesis.
- **Category selection** — locked by
  `categories-and-health-declaration.md`.
- **Age rating** — not a testable variable.
- **Privacy nutrition label** — not a testable variable.
- **Promotional text** (iOS) and feature graphic (Play) —
  testable but deprioritized; run only after the subtitle
  experiment has settled.

## Timeline

| Week (post-launch) | Milestone |
|---|---|
| T+0 to T+14 | Baseline-collection phase. No tests running. |
| T+14 to T+28 | iOS subtitle A/B/C + Play short-description A/B/C in parallel. Same three frames per platform for consistency. |
| T+28 to T+35 | Analyze results; make rollout decision. |
| T+35+ | If a challenger won, update `../gtm/narrative-hook.md` + `ios.md` + `android.md` with the new subtitle. Begin next cycle (promotional text / screenshots). |

## External prerequisites

Before these experiments can start:

- [ ] v1 launched on both platforms (Phase D complete per
      `launch-plan.md`).
- [ ] ≥ 14 days of baseline impression data.
- [ ] Apple PPO + Play Store Listing Experiments features
      enabled (automatic after App Store Connect + Play Console
      setup, but verify on day T).
- [ ] At least 2,500 daily organic impressions per platform —
      otherwise the 10,000/arm minimum isn't reached inside
      14 days.

## Audit + documentation

After every experiment:

- Append winning variant, timeline, sample size, and metrics
  to `../gtm/narrative-hook.md` distribution checklist entries.
- Update `CHANGELOG.md` under the version that rolled out the
  winning change.
- Keep the losing variants in an "also-ran" section for
  future reference and to avoid retesting the same frames.

## Sibling artifacts

- [`launch-plan.md`](./launch-plan.md) — must complete before
  this activates
- [`../gtm/narrative-hook.md`](../gtm/narrative-hook.md) — the
  source of the three frames under test
- [`../gtm/positioning-one-pager.md`](../gtm/positioning-one-pager.md)
  — writing rules (no 'simple'/'fast'/'clinical')
- [`health-claim-guardrails.md`](./health-claim-guardrails.md)
  — red-list verification for every variant
- [`ios.md`](./ios.md), [`android.md`](./android.md) —
  canonical listings that get updated post-experiment
- [`../plans/epic-09-app-store.md`](../plans/epic-09-app-store.md)
  — Task 9.12 source
