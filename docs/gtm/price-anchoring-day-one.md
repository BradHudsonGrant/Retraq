# Price anchoring against Day One Gold

**Status:** Ship-ready (pending Task 5.5 price lock) ·
**Task:** 5.13 · **Last updated:** 2026-04-16

Day One Gold ($74.99/yr) is the category price anchor for
"journal + AI summary at premium tier." Retraq's planned
cloud-AI tier at $2–3/mo ($24–36/yr) is a clean undercut — but
the undercut only does work if someone actually sees the
comparison. This doc names where to frame the comparison and
where not to.

## The price landscape (2026-04)

| App | Tier | Price | What it includes |
|---|---|---|---|
| Day One | Basic (free) | $0 | 1 journal, 7 entries cap |
| Day One | Plus | $34.99/yr | Unlimited journals + entries, no AI |
| Day One | Gold | $74.99/yr | Plus + AI summaries ("Moments," writing prompts, themes) |
| Rosebud | Pro | $89/yr or $8.99/mo | AI-guided journaling (chat + prompts) |
| Mindsera | Premium | $129/yr or $12.99/mo | Multi-model AI with Socratic prompts |
| Finch | Premium | $29.99/yr or $4.49/mo | Pet care + custom goals (no AI) |
| Daylio | Premium | $23.99/yr or $2.99/mo | Unlimited moods + export |
| Apple Journal | N/A | Free (bundled) | Apple Intelligence on iOS 18+ devices |
| **Retraq v1.1** | Pro Lifetime | **$5.99 one-time** | Power features, never cloud AI |
| **Retraq v1.1** | Pro Cloud AI | **$2.99/mo or $24.99/yr** (pending Task 5.5 lock) | Weekly AI summary of your journal (opt-in, zero-retention) |

## The framing — "cloud AI for the price of coffee, not a subscription"

The headline comparison is Retraq Cloud AI tier vs Day One Gold:

> "Day One Gold is $74.99/yr for AI summaries that live on their
> servers. Retraq Cloud AI is $24.99/yr for summaries that run on
> an opt-in basis with zero-retention provider contract. Same
> premium category, a third of the price, better privacy posture."

Three lines of escalating explicitness depending on the surface:

| Surface | Copy | Naming competitor? |
|---|---|---|
| App Store listing (iOS, Play) | "Weekly AI summaries for $2.99/mo. Category average: $6–12/mo." | **Never** — Apple + Play both forbid naming competitors in listings |
| Landing page | "Compare: Retraq Cloud AI $24.99/yr vs. category average of $74.99/yr for premium AI journaling tiers." | **Implicit** — category average framing, no brand names |
| Press kit | "Retraq's Cloud AI tier is priced at $24.99/yr — a third of Day One Gold's $74.99/yr — with an opt-in posture and zero-retention provider contract that Day One Gold does not offer." | **Yes** — press kit is where direct comparison is legitimate |
| Blog / technical writeup | Free to name + link | **Yes** |
| Creator DM (1:1) | Free to name in conversational context | **Yes, with care** |
| Paid ad copy | Apple Search Ads + Play ads follow listing rules | **Never** |

## Why the App Store / Play rule matters

Both stores forbid competitor names in:
- Listing title / subtitle
- Listing description
- Promotional text
- In-app purchase descriptions
- Screenshots (no "Better than [X]" overlay)

Retraq's cross-platform launch (Android first per
`android-first-positioning.md`) cannot ship a listing that names
Day One. Even implicit visuals (a red Day One-colored bar graph
we're "taller" than) get flagged in review.

## The permissible in-listing pattern

Use "category average" anchoring without names:

> **Pro Cloud AI — $2.99/mo or $24.99/yr.**
> Unlimited weekly AI summaries on top of your on-device journal.
> Most premium AI journaling tiers charge $6–12/mo; Retraq's tier
> stays small because the free journal does the heavy lifting.

This lands the price-point story without naming anyone.

## Screenshot overlay — Pricing screen

Overlay copy for the screenshot in the iOS + Play listing set
(Task 9.1, blocked on B-17 screenshot vendor):

> **$2.99/mo. Or $5.99 once, forever.**
>
> The cloud AI summary tier is monthly. The core journal is
> either $0 forever or $5.99 one-time. No subscription traps.

The "$5.99 once, forever" line is the Lifetime SKU positioning
(Task 5.14 — sibling doc will detail the anti-subscription-trap
frame).

## What this doc does NOT claim

- **No quality comparison** — we don't claim Retraq's AI summary
  is "better than Day One's." (That's likely false and also
  violates the `ai-non-claims.md` rules.)
- **No feature parity claim** — Day One Gold's prompt library,
  Moments engine, and cross-device sync are real features we
  don't match. The undercut is on **price + privacy posture**,
  not feature surface.
- **No "killer" framing** — "the Day One killer" is incel-
  brained tech-blog copy and invites review scrutiny. Don't use.

## When the Day One comparison fails

Three cases where the comparison is wrong to make:

1. **User is already a Day One power user with years of entries.**
   Switching costs dominate. Don't try to flip them.
2. **User is on iOS and wants iCloud sync.** Day One's
   cross-device sync is valuable; Retraq's v1 is device-local
   (v2 cloud sync). Don't claim feature parity.
3. **User wants AI conversation, not summaries.** Day One's
   AI is summary-style (matches Retraq). Rosebud / Mindsera are
   the competitors if conversation is the need.

## Sibling artifacts

- [`trial-length-decision.md`](./trial-length-decision.md) — v1.1
  trial length that interacts with this pricing story.
- [`battlecards/rosebud-mindsera.md`](./battlecards/rosebud-mindsera.md)
  — AI conversation competitors (different frame).
- [`ai-non-claims.md`](./ai-non-claims.md) — what Retraq's AI
  tier is allowed to claim.
- [`positioning-one-pager.md`](./positioning-one-pager.md) —
  'anti-subscription-trap' positioning proof point.
- Task 5.14 `lifetime-sku-decision.md` (planned) — the $5.99
  one-time SKU framing this doc assumes.
- [`../plans/epic-09-app-store.md`](../plans/epic-09-app-store.md)
  — Task 9.1 screenshot set.
