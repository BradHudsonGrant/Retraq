# Anti-dark-pattern copy audit checklist

**Status:** Ship-ready · **Task:** 5.14 companion · **Last updated:** 2026-04-16

Every paywall, cancellation, subscription-management, and trial-
end surface in Retraq must pass this checklist before shipping.
The anti-subscription-trap positioning (see
`lifetime-sku-decision.md` + `positioning-one-pager.md`) is a
load-bearing promise; a single dark pattern breaks it.

Based on the deceptive.design taxonomy + FTC Click-to-Cancel
rule (effective 2025) + Apple App Store guideline 3.1.2 + Play
Console subscription policy.

## The test — 12 questions

Before any subscription / paywall / cancellation surface ships,
it passes ALL twelve:

### Purchase flow

1. **No pre-selected subscription SKU.** The three SKUs
   (Monthly / Annual / Lifetime) render with no default
   highlight. User picks actively.
2. **No scarcity / urgency timers.** No "24h flash sale," no
   "price goes up tomorrow," no countdown clock. Prices are
   stable; when we change prices we change them for new
   cohorts only.
3. **No bait-and-switch.** "Confirm" is "Confirm." "Purchase"
   is "Purchase." Only the platform-native purchase sheet
   (StoreKit / Play Billing) is the purchase action.
4. **No obscured Lifetime option.** All three SKUs equal-
   prominence on the same screen. No "subscribe now / more
   options..." dark accordion.
5. **No free-trial-to-paid sleight-of-hand.** Users in the
   14-day annual trial are NOT auto-upgraded to monthly if
   they cancel before trial-end. The trial cancellation is a
   single platform-settings tap; we add no in-app friction.

### Subscription-management flow

6. **Cancel path is one tap.** Settings → Subscription → Cancel
   goes directly to the platform subscription sheet. No "let's
   talk first" interstitial, no "cancel survey required," no
   "are you sure? are you REALLY sure?"
7. **No guilt-framed cancel copy.** Post-cancel status reads
   "Subscription cancelled — you'll keep Pro until {date}.
   Core journaling stays free forever." Not "You'll lose
   access to..." with sad-face framing.
8. **No auto-upsell on cancel.** No "50% off if you stay"
   intercept. No "pause instead of cancel" dark choice. The
   user asked to cancel; respect it.
9. **Refund path visible.** Within the platform refund windows
   (Apple 90d with cause, Play 48h auto), the cancel screen
   links to the platform refund flow. No burying.

### Copy + labeling

10. **No "save" framing on subscriptions.** "Save 30% annually"
    is fine (it's true — annual is 30% cheaper per month).
    "Save your streak — subscribe!" is not (streak protection
    + paywall = dark pattern).
11. **No medical / therapy / diagnostic claims on the paywall.**
    See `ai-non-claims.md` blocklist. Pro is power features
    plus (Monthly / Annual only) the cloud AI summary layer —
    never framed as treatment or clinical benefit.
12. **No "data at risk" scare copy.** All entries persist on
    the device forever, free-tier-accessible, regardless of
    Pro status. Any copy implying "cancel and lose your
    entries" is false and blocked.

## Specific surfaces — audit checklist

Run each surface through the 12 questions before ship:

### Paywall screen (v1.1)

- [ ] All three SKUs visible same screen (Q4)
- [ ] No pre-selection (Q1)
- [ ] No countdown / scarcity (Q2)
- [ ] Purchase CTA matches platform sheet action (Q3)
- [ ] Lifetime explicitly labeled "Buy once. Keep forever." (Q4)
- [ ] Trial terms plain-language for Annual: "14-day free
      trial, then $24.99/yr. Cancel anytime in Settings." (Q5)
- [ ] "Save 30%" shown on annual only if literally true vs
      monthly (Q10)
- [ ] No medical / therapy framing (Q11)
- [ ] Link to philosophy page "why these prices?" (from
      `lifetime-sku-decision.md`) for users who want context

### Settings → Subscription screen

- [ ] Active plan surfaced clearly (SKU name + renewal date)
- [ ] "Cancel subscription" one tap → platform sheet (Q6)
- [ ] No "pause" option (dark choice) (Q8)
- [ ] Post-cancel copy factual, no guilt (Q7)
- [ ] Refund link visible if in-window (Q9)
- [ ] Lifetime holders see "One-time purchase, no renewal"
      status — not a "manage subscription" label

### Trial-end reminder (day 10 of 14-day trial)

- [ ] In-app surface only, not a push notification (per
      `engagement-copy-review.md`)
- [ ] Copy: "Your Retraq Pro trial ends {date}. Cancel anytime
      in Settings." (Q7)
- [ ] No "last chance!" urgency (Q2)
- [ ] No "save your entries!" scare (Q12)
- [ ] Has a clear "Cancel trial" affordance that routes to
      platform settings (Q6)

### Cancel confirmation screen

- [ ] Single "Cancel subscription" button → platform sheet
- [ ] Post-cancel card: "Pro ends {date}. Your entries stay
      yours — always." (Q12)
- [ ] No re-engagement modal (Q8)
- [ ] No "what we'll miss about you" emotional framing (Q7)
- [ ] Optional, not required, Epic 11 opt-in cancel-reason
      survey (one question, skippable)

### Post-cancel state

- [ ] User sees "Retraq Free" on next app open, with all
      entries intact
- [ ] No in-app modal gatekeeping previously-accessible
      content (Q12)
- [ ] Cloud AI features (if user was on Monthly / Annual) roll
      back to on-device rule-based recap — gracefully, with
      one-time note: "Cloud summaries paused. Your weekly
      recap now runs on-device."
- [ ] NO re-subscribe nag dialogs. Pro option surfaces only
      if user visits Settings → Subscription.

## Language specifics — banned phrases

Do not use, ever, in any paywall / subscription / cancel
surface:

- "Don't lose access to..."
- "Before you go..."
- "You'll miss out on..."
- "Premium members get..."
- "Just $X! Only until..."
- "Protect your..." (streak / memories / data)
- "Continue your journey" (with paywall)
- "Are you sure? This cannot be undone." (about subscription
  cancel — it 100% can be undone by re-subscribing)
- "We'll miss you 😢"
- "Limited spots" / "invite only" (Retraq is not gated)

## Language specifics — neutral phrases that pass

Use these as the baseline for paywall / cancel copy:

- "Monthly — $2.99/mo, renews each month."
- "Annual — $24.99/yr. Includes 14-day free trial."
- "Lifetime — $5.99 once. Keep Pro forever."
- "Subscription cancelled. Pro ends {date}. Your entries stay
  yours — free tier keeps working."
- "Cancel anytime in Settings."
- "Manage via {Apple ID / Google Play} subscriptions."
- "Refund available via {Apple / Play} within {90 days / 48
  hours}."

## Regulatory alignment

This checklist is ALSO a compliance artifact. Items covered:

- **FTC Click-to-Cancel (2025):** Q6, Q8, Q9 — cancel as easy
  as sign-up, no retention friction.
- **California Automatic Renewal Law (ARL):** Q2, Q5 — clear
  disclosure, no "dark post-trial."
- **EU Consumer Rights Directive:** Q2, Q5, Q6 — 14-day
  withdrawal rights respected.
- **Quebec C.P.A. (Loi sur la protection du consommateur):**
  Q5, Q6 — consumer-friendly cancel, no misleading default.
- **Apple App Store 3.1.2(a):** Q3, Q5, Q6 — platform
  subscription management via settings, not in-app only.
- **Play Console Subscription Policy:** Q3, Q5, Q8 — no
  deceptive renewal, no dark retention patterns.

See Task 12.10 for the formal subscription disclosure UI that
complies with each of these; this doc is the copy-level
complement.

## Audit enforcement

- PR template adds checkbox: "Subscription / paywall / cancel
  surface in this PR passes the 12-question checklist."
- Epic 12 legal review signs off on any paywall copy change.
- Before each v1.1+ App Store / Play submission, a dedicated
  dry-run of the full checklist against screenshots of every
  surface.

## Sibling artifacts

- [`lifetime-sku-decision.md`](./lifetime-sku-decision.md) —
  the $5.99 one-time SKU this doc defends.
- [`trial-length-decision.md`](./trial-length-decision.md) —
  the 14-day annual-only trial this doc operationalizes.
- [`engagement-copy-review.md`](./engagement-copy-review.md) —
  the non-subscription equivalent copy checklist.
- [`ai-non-claims.md`](./ai-non-claims.md) — AI-tier claim
  blocklist.
- [`positioning-one-pager.md`](./positioning-one-pager.md) —
  'anti-subscription-trap' positioning proof point.
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.10 formal subscription disclosure UI.
