# Trial length decision — Retraq Pro (v1.1)

**Status:** Recommendation — pending B-2 RevenueCat + Task 5.5
price decision · **Task:** 5.11 · **Last updated:** 2026-04-16

Trial length is high-leverage: 2026 journaling-category benchmarks
show sub-4-day trials convert 25.5% worse than ≥7-day trials. The
economics also swing the other way — a longer trial delays first
revenue and exposes more cancellation surface. This doc picks
Retraq's launch default and names the post-launch experiment that
will test around it.

## Recommendation

**v1.1 launch default: 14-day trial on the annual Pro SKU only.**

- **14 days** because journaling apps are high-engagement but
  low-frequency-early. A user needs enough trial time to
  accumulate a week or two of traqs that feel worth keeping —
  the fear-of-loss moment happens when they have ≥ 5 entries
  they wrote in the trial.
- **Annual-only trial** because the monthly SKU's $2.99 price
  point is already low enough that a trial would cannibalize
  directly-paid conversions without materially lifting annual
  upgrade. Monthly users can try and cancel within their first
  billing cycle with full refund (Apple / Play defaults handle
  this).
- **NO trial on the one-time $5.99 Pro Lifetime SKU.** Lifetime
  is an explicit anti-subscription-trap alternative (Task 5.14);
  offering a trial on it is internally contradictory.

## Why not 7 days

- 7-day trials do work for commodity SaaS, but category
  benchmarks for journaling show the knee of the curve is at
  10–14 days — the entries-written-in-trial variable dominates.
- A 7-day trial starting on a Wednesday cuts the user off
  before their second weekend-journaling cycle, which is when
  many users actually write.
- Aggressive trial-end reminders at day 5 / 6 feel "catch-up
  urgency" — exactly the tone our engagement-copy-review
  (`engagement-copy-review.md`) forbids.

## Why not 21 days

- 21-day trials are on the edge of App Store / Play guidance
  and can look like "free with delay" rather than a trial, which
  invites review scrutiny.
- Longer trials delay first revenue materially. At the v1.1
  target CAC (informed by Task 5.8 creator seeding cost), the
  break-even moves outside the projected payback window for
  paid-ad budgets.
- We can still TEST 21 days as an experimental upper bound post-
  launch (see A/B plan below). We just don't ship it as default.

## The exit criteria

We stay on 14 days until at least one of the following:

1. **Conversion < 8% (30-day post-trial cohort)** — category
   benchmark is 10.7% for journaling/lifestyle apps with paywalls
   at trial-end. Sustained underperformance below 8% triggers
   the A/B plan (`trial-length-ab-plan.md`) to test 21 days.
2. **Cancellation < 24h of start > 40%** — means the trial is
   too cheap to commit to; trial is being treated as free tier.
   Mitigations: add an explicit "You're in your trial — here's
   what you'll lose" nudge at day 7 (penalty-free copy per
   review) OR tighten to 10 days.
3. **Trial starts / day-7 completion funnel drops > 50%** —
   signals the trial-entry UX is the problem, not length.
   Fix UX first before touching length.

## Pre-launch checklist

Before the v1.1 release ships with the 14-day trial:

- [ ] RevenueCat entitlement configured with 14-day introductory
      offer on `retraq_pro_annual` only. `retraq_pro_monthly`
      runs standard (no trial). `retraq_pro_lifetime` runs
      one-time (no trial).
- [ ] Paywall copy makes the trial terms explicit in plain
      language — start date, billing date, cancellation path.
      Passes the anti-dark-pattern audit (Task 5.14).
- [ ] Apple's Subscription Notifications webhook wired so we
      detect trial starts, conversions, and cancellations for
      the retention cohort (Task 11.2).
- [ ] Settings → Subscription clearly surfaces: "Cancel your
      trial" with one-tap route to platform subscription
      management (no dark-pattern friction).
- [ ] Day-10 non-interruptive nudge planned (not a notification
      — in-app surface) reminding the user of the trial end
      date. Copy reviewed per engagement-copy-review.md.
- [ ] No day-13 / day-14 "last chance!" urgency notifications.
      Users should be able to let the trial end without being
      pestered.

## Alignment with Task 5.5 pricing A/B

Task 5.5's pricing A/B test cannot run concurrently with the
trial-length A/B test below — variable collision. Sequence:

1. v1.1 ships with 14-day trial + finalized pricing from 5.5.
2. Watch 30-day + 90-day conversion cohorts.
3. If Task 5.5's pricing confidence is established by week 12
   post-v1.1 and the trial-length exit criteria above are met,
   start the Task 5.11 A/B plan.
4. If Task 5.5 needs more data, hold Task 5.11 until pricing
   is locked.

## How this interacts with the one-time Pro SKU

The one-time $5.99 Pro Lifetime SKU is the positioning statement
— "no trial, no subscription trap, buy it once." Offering a
trial on it would undermine the whole Task 5.14 anti-dark-pattern
pitch. Keep the Lifetime SKU as a pure one-time purchase.

Acquisition funnel for users skeptical of subscriptions:

1. Free tier → enjoy journaling for free, indefinitely.
2. If they want Pro: annual with 14-day trial (standard
   subscription funnel) OR Lifetime one-time ($5.99 upfront).
3. Both tiers are always offered side-by-side on the paywall —
   never hide the Lifetime option behind a "maybe later" state.

## Sibling artifacts

- [`trial-length-ab-plan.md`](./trial-length-ab-plan.md) —
  the A/B test spec this decision enables.
- [`engagement-copy-review.md`](./engagement-copy-review.md) —
  trial-end nudge copy has to pass this.
- [`battlecards/daylio.md`](./battlecards/daylio.md),
  [`battlecards/rosebud-mindsera.md`](./battlecards/rosebud-mindsera.md)
  — competitor trial lengths referenced for rationale.
- Task 5.14 `lifetime-sku-decision.md` (planned) — the Lifetime
  SKU framing this doc defers to.
- `implementation_plan.md` Part II — v1.1 monetization.
