# IAP / subscription posture — v1 and v1.1

**Status:** Locked for v1 submission · **Task:** 9.10 ·
**Last updated:** 2026-04-16

Retraq's in-app-purchase posture across the two near-term
submission windows. Protects against Apple 3.1.1 / 3.1.2(a) and
Play Subscriptions policy review findings by documenting exactly
what IAP surface exists (none in v1) and what lands in v1.1.

## v1 — no IAP, no subscription

### What the listing says

- iOS: listing explicitly states "Free" with no "Offers in-app
  purchases" badge. App Store Connect "Price Tier" = Free,
  no subscription groups, no one-time IAPs configured.
- Play: same — Play Console shows "Free" with no "Contains
  ads" or "In-app purchases" labels.
- Landing page + press kit describe v1 as free; any paid-tier
  talk is clearly flagged as "coming in v1.1."

### What the binary contains

- No `purchases_flutter`, no `in_app_purchase`, no RevenueCat
  SDK in `pubspec.yaml`.
- No paywall screen, no subscription-management surface in
  Settings.
- No entitlement checks anywhere in the codebase (every feature
  is available to every user).
- No StoreKit / BillingClient calls of any kind.

### Why this matters for review

- App Review looks for half-wired IAP (e.g., `purchases_flutter`
  imported but no paywall surfaces it) and rejects under 2.3.1
  (misrepresentation) or 3.1.1 (non-functional IAP). v1 has
  none of that.
- App Store Connect "Paid Applications Agreement" is NOT
  required for v1 submission because no paid content ships.
  The agreement will be signed before v1.1 submission.
- Play Console's "Pricing & Distribution" section is set to
  Free; no merchant account needed.

### Confirmation checklist — v1 pre-submission

- [ ] `grep -r "purchases_flutter\|in_app_purchase\|RevenueCat" lib/`
      returns zero results
- [ ] `pubspec.yaml` has no IAP-related dependencies
- [ ] App Store Connect "In-App Purchases" tab is empty
- [ ] App Store Connect "Price Schedule" is Tier 0 (Free)
- [ ] Play Console "Pricing" is Free
- [ ] Play Console "In-app Products" is empty
- [ ] Store listing description does not mention "premium",
      "upgrade", or "subscription"

## v1.1 — RevenueCat three-SKU paywall

### The three SKUs

Per `../gtm/lifetime-sku-decision.md`, `../gtm/trial-length-decision.md`,
and `../gtm/price-anchoring-day-one.md`:

| SKU | Price | Billing | Trial | Cloud AI |
|---|---|---|---|---|
| Retraq Pro Monthly | $2.99/mo | Auto-renewing | None | Included |
| Retraq Pro Annual | $24.99/yr | Auto-renewing | 14 days | Included |
| Retraq Pro Lifetime | $5.99 one-time | Non-consumable IAP | None | **NOT included** |

### Platform product IDs

Planned IDs (subject to App Store Connect / Play Console final
naming — verify against RevenueCat dashboard before publish):

- `com.retraq.app.pro.monthly` — Apple; `retraq_pro_monthly`
  Play.
- `com.retraq.app.pro.annual` — Apple; `retraq_pro_annual` Play.
- `com.retraq.app.pro.lifetime` — Apple (non-consumable);
  `retraq_pro_lifetime` Play (non-consumable).

RevenueCat entitlement: `pro_features` — granted by any of the
three SKUs. `cloud_ai_summary` — granted by Monthly or Annual
only (NOT Lifetime, per the decision doc).

### Paywall disclosure requirements

Apple 3.1.2(a) + Play Subscriptions policy require the paywall
to display, visibly and before purchase:

- Subscription title (e.g., "Retraq Pro Monthly")
- Length of subscription (e.g., "1 month")
- Price per period (e.g., "$2.99/mo")
- Trial terms if applicable (e.g., "14-day free trial, then
  $24.99/year")
- Auto-renew disclosure (e.g., "Renews automatically unless
  cancelled")
- Links to Terms of Use and Privacy Policy (already in
  `lib/legal/`; paywall surfaces these via `InkWell` →
  `LegalScreen`)
- Cancel path (Settings → Subscription per platform defaults —
  see `../gtm/anti-dark-pattern-copy.md`)

### Epic / task coordination

- **Epic 12 Task 12.10** — formal subscription disclosure UI
  legal review (Apple 3.1.2(a), Play, Cal. ARL, EU CRD,
  Quebec C.P.A.)
- **Epic 13 paywall design** — actual paywall screen
  (coordinated with brand designer B-12 so Lifetime SKU is
  visually equal-prominence per anti-dark-pattern rules)
- **Epic 11 Task 11.10** — minimal pre-monetization metric
  `purchased_at − installed_at` via opt-in share
- **Epic 10** — CI / release pipeline stays unchanged (no
  payment server needed; RevenueCat handles receipts)

### External blockers

- **B-2 RevenueCat account** — blocks v1.1 submission entirely.
  Must be activated, products configured, API keys in GitHub
  Secrets before the first v1.1 CI run.
- **B-3 Apple Developer / B-4 Play Console** — required for
  paid-app signing (already B-3 and B-4 in
  `docs/external-blockers.md`).
- **B-5 Canadian business entity** — Apple's Paid Applications
  Agreement requires a banking / tax entity; blocks v1.1 submission.
- **Task 12.10** counsel review — ensures disclosure UI is
  defensible in every regulated market before ship.

### App Store Connect IAP configuration checklist — v1.1

Before v1.1 TestFlight:

- [ ] Sign Apple "Paid Applications Agreement"
- [ ] Create subscription group `retraq_pro` in ASC
- [ ] Add Monthly + Annual subscriptions to the group
- [ ] Add Lifetime as a standalone non-consumable IAP
- [ ] Configure introductory offer: 14-day free trial on Annual
      only (not Monthly, not Lifetime — per trial-length-decision)
- [ ] Localize price tier per region (use App Store Connect
      pricing matrix — our listed prices are USD base)
- [ ] Configure App-Specific Shared Secret for server-side
      receipt validation in RevenueCat
- [ ] Paywall screenshots + App Review notes explaining the
      three-tier structure

### Play Console configuration checklist — v1.1

Before v1.1 Internal Testing:

- [ ] Sign Play Console merchant agreement
- [ ] Create subscription products `retraq_pro_monthly` +
      `retraq_pro_annual` with base plans (monthly + annual
      respectively)
- [ ] Configure 14-day free trial offer on annual base plan
      only
- [ ] Create managed product `retraq_pro_lifetime` (non-
      consumable)
- [ ] Enable Play Billing Library v7 integration
- [ ] Configure real-time developer notifications endpoint
      (RevenueCat webhook)
- [ ] Data Safety form updated to disclose subscription
      pairing (if Apple / Google considers it personal data)
- [ ] Family Library: opt OUT for Lifetime SKU (lifetime on
      one Apple ID cannot be shared to Family; same on Play —
      it's a single-user license)

## What this document does NOT cover

- Refund UX — handled by platform defaults per
  `../gtm/anti-dark-pattern-copy.md`. No custom refund flow.
- Promotional offers (discounts, intro prices beyond the 14-day
  trial). These are deliberately out of scope for v1.1 —
  revisit at v1.2 only if activation data supports adding them.
- Family Sharing enablement — see above; OUT for Lifetime.
  Subscriptions (Monthly/Annual) follow platform defaults
  where Apple allows Family Sharing on subscriptions if the
  app opts in. Decision: OPT OUT for v1.1; revisit when
  caregiver tier (v2) is closer, since caregiver relationships
  don't map cleanly onto Family Sharing (adult child +
  elderly parent often on different Apple IDs).
- Gift IAPs — out of scope.

## Sibling artifacts

- [`../gtm/lifetime-sku-decision.md`](../gtm/lifetime-sku-decision.md)
  — $5.99 one-time Lifetime positioning
- [`../gtm/trial-length-decision.md`](../gtm/trial-length-decision.md)
  — 14-day annual-only trial
- [`../gtm/price-anchoring-day-one.md`](../gtm/price-anchoring-day-one.md)
  — pricing story vs Day One Gold
- [`../gtm/anti-dark-pattern-copy.md`](../gtm/anti-dark-pattern-copy.md)
  — paywall + cancellation copy checklist
- [`../gtm/ai-non-claims.md`](../gtm/ai-non-claims.md) —
  AI-tier claim blocklist (affects paywall copy)
- [`health-claim-guardrails.md`](./health-claim-guardrails.md)
  — listing-copy red list (affects paywall marketing copy)
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.10 subscription disclosure UI
- [`../plans/epic-09-app-store.md`](../plans/epic-09-app-store.md)
  — Task 9.7 v1.1 privacy nutrition label rewrite
- [`../external-blockers.md`](../external-blockers.md) — B-2
  RevenueCat + B-5 Canadian entity (v1.1 blockers)
