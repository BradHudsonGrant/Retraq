# Lifetime SKU decision — $5.99 one-time Pro

**Status:** Recommended — pending Task 5.5 price lock + B-2 RevenueCat ·
**Task:** 5.14 · **Last updated:** 2026-04-16

> **Recommendation:** Ship the Lifetime SKU at **$5.99 one-time**
> alongside the subscription tier, priced well BELOW the 2-year
> equivalent so it reads as an "anti-subscription escape hatch"
> not a discount SKU. The positioning narrative — "buy it once,
> keep it forever" — is a category flank Day One / Rosebud /
> Mindsera / Finch / Daylio cannot match without re-architecting.

Pair with `price-anchoring-day-one.md`, `trial-length-decision.md`,
and the planned `anti-dark-pattern-copy.md` (companion doc).

## The decision

Retraq v1.1 ships with **three Pro SKUs, all surfaced on the
paywall**:

| SKU | Price | Billing | Trial | Cloud AI | Positioning |
|---|---|---|---|---|---|
| Pro Monthly | $2.99/mo | Auto-renewing subscription | None | Included | Standard subscription — low barrier, cancel anytime |
| Pro Annual | $24.99/yr | Auto-renewing subscription | 14 days | Included | Commitment path — ~30% effective discount vs monthly |
| **Pro Lifetime** | **$5.99 one-time** | Single purchase, non-consumable | None | **NOT included** | **The escape hatch — power features forever, no cloud AI, no subscription** |

**Key design choice:** Pro Lifetime **does NOT include cloud AI**.
Cloud AI is an ongoing server cost Retraq can't deliver under a
one-time purchase. Users who want the weekly AI summary pick
Monthly or Annual. Users who want the non-AI power features
forever pick Lifetime.

## Why $5.99 specifically

- **Below "impulse ceiling"**: $5.99 is in the one-tap range for
  target users; $9.99+ triggers "do I really want this"
  hesitation that hurts conversion.
- **2-year equivalent of monthly is $71.76**: pricing Lifetime at
  $5.99 signals "we're not trying to arbitrage you" — it's a
  statement of intent, not a pricing optimization.
- **Below annual ($24.99)**: makes the Lifetime option
  strictly better on $/lifetime dimensions for users who'd use
  Pro features for > 4 months. The annual subscriber is buying
  cloud AI, not the power features.
- **Above $0.99–$2.99 range**: too cheap signals "not a real
  product" and invites review-bomb trolling.
- **Below $9.99–$14.99 "one-time premium" category norm**: we're
  explicitly undercutting to lean into the anti-subscription-
  trap positioning. Price IS the message here.

## Why NOT bundle cloud AI into Lifetime

This is the anti-instinctive part. The intuitive move is
"Lifetime includes everything, maximum value." Here's why we don't:

1. **Ongoing cost.** A Lifetime user at $5.99 generates exactly
   $5.99 of revenue, ever. Cloud AI at ~$0.30/user/mo for a
   zero-retention provider contract would put Lifetime users
   underwater in month 20.
2. **Positioning clarity.** Lifetime is the "on-device only"
   promise made concrete. Bundling cloud AI blurs that —
   subscriptions are for cloud features, Lifetime is for
   device features.
3. **Selection bias.** Users who pick Lifetime value the
   "no servers know anything about me" story. They're the
   least likely to opt into cloud AI anyway.
4. **Option to add later.** If a Lifetime holder decides they
   want cloud AI later, they subscribe to Monthly. They don't
   downgrade from a "Lifetime-with-AI" that never existed.

## Positioning — "no subscription trap"

The Lifetime SKU is the product statement that counters a common
paid-app complaint: subscription fatigue. Across journaling and
productivity app review threads, users post:

- "I have 12 active subscriptions I forgot about."
- "I cancel everything monthly just so I don't get trapped."
- "I will pay DOUBLE for a one-time purchase."

The $5.99 one-time price turns that complaint into an acquisition
vector. Marketing copy positions it as:

> **Buy Retraq Pro once. Keep it forever. No renewal, no
> reminder, no 'your subscription is expiring' email three years
> from now.**

## Paywall UX rules

When the paywall renders, Lifetime MUST be:

- **Visible on the same screen as Monthly + Annual.** Do not
  hide behind a "maybe later" state. Do not reveal-on-scroll.
  Three SKUs, three equal-height cards.
- **Labeled clearly as one-time purchase.** The word "Lifetime"
  appears in the card title. "One-time purchase" or "Buy once"
  appears in the body, not buried.
- **Not framed as the "cheap option".** Copy frames it as the
  "different option" — respectful of subscription fatigue, not
  a downgrade.
- **Paired with a "why this costs what it does" link** to a
  short philosophy page explaining the three-SKU design. Not
  mandatory to read; available for skeptical users.

## Anti-dark-pattern audit (Task 5.14 deliverable)

When the paywall ships, every pattern on the Deceptive Design
list (deceptive.design) gets checked. Known traps Retraq will
NOT use:

- **Pre-selected subscription default.** Neutral default — user
  actively picks which SKU.
- **Scarcity timers.** No "only 24h left at this price!"
  countdown. Prices don't change on the paywall.
- **Hidden cancel affordance.** Settings → Subscription → Cancel
  is one tap. No "Are you sure? Are you REALLY sure?" dark
  patterns.
- **Free-trial-to-paid friction.** Cancel the trial at any time
  via platform settings (Apple / Play defaults); we don't add
  in-app friction.
- **Guilt-framed cancel copy.** No "You'll lose access to..." —
  factual list of what changes post-cancel, not emotional
  blackmail.
- **Auto-upsell on cancel.** No "Here's 50% off if you stay"
  intercept. If user wants to cancel, respect it.
- **Receipt manipulation.** No "Confirm" buttons that are
  actually "Purchase" buttons in disguise. Platform-native
  purchase sheets only.
- **Obscured Lifetime option.** The whole point of this SKU is
  that it's the non-subscription option; hiding it would
  defeat the positioning.

A complete anti-dark-pattern audit checklist lives in
`anti-dark-pattern-copy.md` (companion doc — see below).

## Revenue model impact

Rough modeling (numbers are illustrative, not projections):

- 1000 new Pro conversions per month at launch.
- Distribution guess: 50% Annual, 30% Monthly, 20% Lifetime.
- **Monthly revenue at steady state:**
  - 500 × $24.99/12 = $1,041 (annual amortized)
  - 300 × $2.99 = $897 (monthly)
  - 200 × $5.99 = $1,198 (one-time, does not renew)
  - Plus renewals on previous cohorts.
- LTV per cohort (24-month view):
  - Annual user: ~$40 (2x annual with ~80% renewal)
  - Monthly user: ~$35 (12 months avg at $2.99)
  - Lifetime user: $5.99 forever.

**Conclusion:** Lifetime generates ~15% of revenue while carrying
the positioning weight of "we're not a subscription trap." The
math sustains because subscription SKUs carry the bulk of
revenue and cloud-AI cost.

If Lifetime share exceeds ~30%, Cloud AI subsidization math
breaks; raise Lifetime to $8.99 or cap it (limited-time sale,
not a dark pattern — genuine scarcity based on cost math). If
Lifetime share stays ≤ 20%, the positioning is doing its job.

## Sibling artifacts

- [`price-anchoring-day-one.md`](./price-anchoring-day-one.md) —
  the AI-tier price comparison.
- [`trial-length-decision.md`](./trial-length-decision.md) —
  'NO trial on Lifetime SKU' rule comes from here.
- [`engagement-copy-review.md`](./engagement-copy-review.md) —
  paywall copy has to pass this checklist too.
- `anti-dark-pattern-copy.md` (planned companion) — the full
  paywall + cancellation anti-pattern audit checklist.
- [`../plans/epic-04-product.md`](../plans/epic-04-product.md)
  — Task 4.9 v1.1 premium feature plan.
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.10 subscription disclosure (Apple 3.1.2(a), Google
  Play, Cal. ARL, EU CRD, Quebec C.P.A.).
