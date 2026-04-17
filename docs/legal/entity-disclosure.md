# Canadian business entity + mailing address disclosure

**Status:** Template — activate on B-5 entity registration ·
**Task:** 12.11 · **Last updated:** 2026-04-16

Retraq must publish a legal entity name + physical Canadian
mailing address in its Privacy Policy, Terms of Use, and any
future commercial email footers. This is compliance with:

- **PIPEDA s. 5(3)** — accountability (identifiable data
  controller)
- **Quebec Law 25** — accountability + designated person
  disclosure
- **CASL s. 6** — physical mailing address required in every
  Commercial Electronic Message (CEM); applies to any future
  marketing / release / re-consent email

v1 currently ships with a placeholder in the Privacy Policy
(see `lib/legal/privacy_policy.dart` line 68) naming
`contact@retraq.app` as the controller contact and pointing to
this document for the entity + address pending B-5 registration.

## Decision — entity type

Recommended: **sole proprietorship registered in Ontario** OR
**Canadian-controlled private corporation (CCPC) federally
registered at CIPO**.

- **Sole proprietorship** — cheapest ($60-80 one-time
  registration at ServiceOntario), no separate tax return in
  year 1 (income flows to personal return), fastest to
  stand up. Good fit if Retraq's first year is pre-revenue
  or below the HST threshold ($30K).
- **CCPC (federal CIPO)** — ~$200 one-time + annual filing
  (~$12), creates a separate legal person, limits liability,
  enables Apple / Play paid developer accounts under the
  entity rather than personal name, eligible for future
  SR&ED + Canadian small-business tax rate. Recommended once
  paid Pro SKU activates in v1.1.

**Decision:** ship v1 under sole proprietorship; migrate to
CCPC before v1.1 Pro launches. Both options satisfy the
CASL / PIPEDA / Law 25 disclosure requirement.

## Physical address

Three options in order of preference:

1. **Registered-agent / virtual-office service** (iPostal1,
   Earth Class Mail, Anytime Mailbox) — ~$15-25/month,
   scan-and-forward incoming mail. **Recommended** because it
   keeps personal address off public-facing legal surfaces.
2. **Business P.O. Box** (Canada Post) — ~$15/month, requires
   in-person pickup. Not usable as a registered-office address
   in most provinces; OK as a mailing-only disclosure.
3. **Home address** — zero cost but publishes the founder's
   residence on every store listing, privacy policy, and
   email footer. Hard to un-publish once scraped. Only use
   if the other two are genuinely out of reach.

**Decision:** go with option 1; iPostal1's Toronto virtual
mailbox is ~$15/month with mail-scan-and-forward.

## Name availability check before registration

Before filing, confirm the intended operating name doesn't
collide with:

- Existing business names in Ontario (NUANS search, ~$20)
  or federally (Corporations Canada search, free)
- Trademarks (CIPO + USPTO — see Task 13.6)
- Domain name availability (already own retraq.app per B-7 /
  B-9 verification)

Candidate names (in order of preference):

1. **Retraq Inc.** — cleanest, matches product name.
   Availability check needed.
2. **Retraq Technologies Inc.** — descriptive variant, more
   likely to clear collision check.
3. **Retraq Labs Inc.** — alternative if both above collide.

## Artifacts to update when B-5 completes

Replace placeholder text in these files with the confirmed
entity + address:

### `lib/legal/privacy_policy.dart`

Current placeholder (line 68):

```
...the data controller ... is the App's developer, reachable
at `contact@retraq.app`. A Canadian business entity name and
mailing address will be published here alongside the controller
contact once entity registration completes...
```

Replace with (example — substitute real values):

```
...the data controller for any processing that does occur
(for example, receipt of a privacy inquiry sent to the
contact address below) is:

  Retraq Inc.
  [Street address, Suite number]
  Toronto, Ontario [Postal code]
  Canada

Reachable at `contact@retraq.app`.
```

Bump `currentPrivacyPolicyVersion` in `user_repository.dart`
to trigger the re-consent flow (same pattern as Task 12.2).

### `lib/legal/terms_of_service.dart`

Add equivalent entity + mailing-address block. Bump
`currentTermsOfServiceVersion`.

### `docs/external-blockers.md`

Mark B-5 complete with the registration date, name, and
address. Update item status from `[ ]` to `[x]`.

### `CHANGELOG.md`

Add entry under `[Unreleased]` or the next shipping version:

```
### Changed
- **Legal:** Privacy Policy + Terms of Use now disclose the
  Canadian business entity ({ENTITY NAME}) and physical
  mailing address, per PIPEDA s. 5(3), Quebec Law 25, and
  CASL s. 6.
```

### `lib/services/user_repository.dart`

Bump both `currentPrivacyPolicyVersion` and
`currentTermsOfServiceVersion` to the date of entity
disclosure (ISO-8601). This triggers the re-consent flow for
existing users so they see the updated entity information.

### Future email footers

When any CEM template ships (currently none — Retraq has no
outbound email), the footer must include:

```
Retraq Inc. · [Street, Suite] · Toronto, ON [Postal] · Canada
contact@retraq.app · Unsubscribe: [link]
```

Per CASL, the physical address and unsubscribe mechanism are
both required for every CEM.

## What this disclosure does NOT need to be

- NOT the founder's personal home address (use virtual
  mailbox).
- NOT a telephone number (CASL doesn't require it; adds
  attack surface).
- NOT a Social Insurance Number or business number (those
  are for government filings, not public disclosure).
- NOT a billing address for Stripe / RevenueCat (that's
  separately provided to the payment processor; users don't
  see it).

## When the address changes

If the registered-agent / virtual-office address changes:

1. Update all artifacts listed above in a single commit.
2. Bump both policy versions (triggers re-consent).
3. Update CIPO + NUANS + Apple / Play developer program
   records within their mandated timelines (typically 30
   days).
4. Log the change in `CHANGELOG.md`.

## External blockers this resolves

- **B-5 Canadian entity registration** — the load-bearing
  blocker. Once this is filed, this doc becomes actionable.
- **B-3 Apple Developer account** — Apple requires a legal
  entity for the Paid Applications Agreement (v1.1 paywall
  launch). Entity must exist first.
- **B-4 Play Console** — requires a legal entity for merchant
  registration to collect IAP revenue.

## Sibling artifacts

- [`../../lib/legal/privacy_policy.dart`](../../lib/legal/privacy_policy.dart)
  — current placeholder
- [`../../lib/legal/terms_of_service.dart`](../../lib/legal/terms_of_service.dart)
  — mirrors privacy-policy entity block
- [`../../lib/services/user_repository.dart`](../../lib/services/user_repository.dart)
  — `currentPrivacyPolicyVersion` / `currentTermsOfServiceVersion`
  bump pattern
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.2 controller disclosure landed; Task 12.11 source
- [`../../CHANGELOG.md`](../../CHANGELOG.md) — user-facing log
  of the v1 → disclosure version bump
- [`../external-blockers.md`](../external-blockers.md) — B-5
  Canadian entity (this task's blocker)
