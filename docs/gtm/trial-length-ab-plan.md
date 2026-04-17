# Trial length A/B plan — 7 / 14 / 21 day

**Status:** Experiment spec — blocked on Task 5.5 pricing lock +
RevenueCat (B-2) · **Task:** 5.11 companion · **Last updated:** 2026-04-16

The v1.1 launch default is 14-day trial on the annual Pro SKU
(see `trial-length-decision.md`). This doc specifies the post-
launch experiment that tests around it if the exit criteria
trigger.

## Pre-conditions — do NOT run this experiment until ALL true

- [ ] 12+ weeks of v1.1 conversion data at the 14-day baseline.
- [ ] Task 5.5 pricing A/B test has concluded with a winner.
      Variable collision: pricing and trial-length both move the
      same conversion metric.
- [ ] At least one of the exit criteria from
      `trial-length-decision.md` has tripped (conversion < 8%,
      or > 40% <24h cancellation, or funnel drop > 50%).
- [ ] Epic 11 anonymized opt-in export has enough sample (>= 500
      trial-starts per variant) to avoid reading noise.
- [ ] Ethics review completed — we are NOT running this test
      during a vulnerable-user window (e.g. onboarding users
      with mental-health disclosure in consent flow).

If any of these is false, hold the experiment.

## Variants

Three cells, one control + two challengers:

| Variant | Length | Notes |
|---|---|---|
| A (control) | 14 days | v1.1 launch default |
| B | 7 days | Shorter; tests if trial abandonment drops |
| C | 21 days | Longer; tests if entries-written dominates |

**Rejection note:** a 10-day variant was considered as a middle
ground but would force a third arm of the test, splitting
statistical power. Skip.

## Assignment

- **Bucketing:** deterministic on-device via the Epic 11
  `variantBucket` field (Task 11.7). User `installUuid` hashed
  → bucket 0/1/2 → maps to A/B/C.
- **Stickiness:** once bucketed, user stays in the bucket for
  the life of the install. Re-install resets.
- **Exclusions:** users who joined during Task 5.5 pricing test
  are excluded (their bucket is already carrying one
  experimental signal; adding a second is noise). New installs
  only.
- **Scope:** annual Pro SKU trial only. Lifetime SKU excluded
  (no trial). Monthly SKU excluded (no trial). Free tier
  excluded (no trial to test).

## Primary metric

**Trial-to-paid conversion rate at day 30 post-trial-start.**

Definition: of users who started a trial in week W, what % were
on an active paid subscription (annual Pro) on day 30 post-start?

## Secondary metrics

1. **Day-1 cancellation rate** — signals trial friction.
2. **Entries-logged-during-trial distribution** — do longer
   trials produce higher median entry counts? If yes, that
   corroborates the fear-of-loss hypothesis.
3. **Cancellation reason (if captured via post-cancel survey)**
   — price vs time vs fit.
4. **90-day retention** (among converted users) — longer trials
   may attract higher-commitment users who retain better.
5. **Revenue per install** — CAC payback window.

## Guardrail metrics

If any guardrail trips, the experiment pauses regardless of
primary-metric trends:

- **D28 retention drop > 10% in any variant** — signals the
  trial length is changing the *user* not just the conversion
  math. Stop.
- **"Keep usage stats" kill-switch (Task 11.13) toggle-off rate
  differs > 5% across variants** — signals users in one variant
  are perceiving manipulation. Stop.
- **App Store / Play review sentiment diverges > 0.3 stars
  across variants** — signals public-facing trial-length
  complaints. Stop.

## Duration + sample

- **Target sample per variant:** 500 trial-starts.
- **Expected weekly trial-start volume:** ~100/week at
  v1.1 week-12 baseline (rough projection; revise once
  actual data is in).
- **Expected experiment duration:** ~15 weeks to hit 500/variant
  on all three arms. If volume is higher, ship results sooner.
- **Minimum duration:** 4 weeks regardless of sample — fewer
  than 4 weeks is too sensitive to day-of-week effects.

## Analysis

- **Statistical test:** two-proportion z-test, α = 0.05,
  one-sided (we only care if B or C beats A).
- **Pairwise comparisons:** Bonferroni-correct for 2 tests
  (A vs B, A vs C) to α = 0.025 each.
- **Practical significance floor:** require ≥ 2 percentage-
  point lift vs A to declare a winner. A 0.5pp statistical
  winner in a 30% baseline conversion is not worth the
  operational complexity of re-configuring RevenueCat.

## Decision rules

At the end of the experiment:

- **C (21 days) wins by ≥ 2pp AND no guardrail tripped**:
  roll to 21 days, re-run the trial-length-decision.md
  exit criteria in 12 weeks.
- **B (7 days) wins by ≥ 2pp AND no guardrail tripped**:
  roll to 7 days. Reconsider whether the trial is carrying its
  weight at all — a 7-day trial that wins may be signaling
  that the trial as concept is underperforming direct
  conversion.
- **No variant beats by 2pp**: stay at 14 days. The variable
  isn't trial length.
- **Any guardrail tripped**: roll back to 14 days, investigate,
  consider a different experiment (pricing? paywall UX?
  onboarding? See Task 5.5 and Epic 11).

## Copy review note

Trial-end reminders differ per variant (day 4 / day 10 / day 17
respectively). ALL variants' reminder copy must pass the
`engagement-copy-review.md` 5-point checklist. A scarcity-framed
"last chance!" notification is NOT permitted in any variant,
even if it would lift conversion — that's the dark-pattern
boundary Task 5.14 defends.

## Ethics / anti-dark-pattern guardrails

- Trial-end cancellation must be one-tap from Settings →
  Subscription. Apple / Play defaults cover this; don't add
  in-app friction.
- Cancel-early refund posture mirrors platform defaults
  (Apple: refund available within 90 days with cause; Play:
  48h auto-refund). Don't suppress these affordances.
- Post-cancel survey is opt-in, Epic 11 "Help improve Retraq"
  routed — not a blocker to cancellation completion.
- No "your entries will be deleted" scare copy on cancel.
  Free-tier journaling remains available and all entries
  persist.

## Sibling artifacts

- [`trial-length-decision.md`](./trial-length-decision.md) — the
  launch default this experiment tests around.
- [`engagement-copy-review.md`](./engagement-copy-review.md) —
  trial-end reminder copy compliance.
- Task 5.5 pricing A/B plan (separate doc when Task 5.5 lands).
- Task 5.14 `lifetime-sku-decision.md` (planned) — reminds why
  the experiment is scoped to annual only.
- [`../../plans/epic-11-analytics.md`](../../plans/epic-11-analytics.md)
  — Task 11.7 variant bucketer, Task 11.13 kill switch.
