# Sub-brand decision tree — v2 caregiver

**[Superseded 2026-04-23 — caregiver/memory-concern exploration abandoned.]**

**Status:** Strategy doc — activates when v2 caregiver tier
enters planning · **Task:** 13.5 · **Last updated:** 2026-04-16

Retraq's v1 voice is native to busy-brain adult culture (drop a traq,
"for people who forget Tuesday by Thursday"). That voice will NOT
land with Persona 2 (40-something caregiver) or Persona 3 (65+ with
memory concerns). When Retraq Care ships in v2, a sub-brand decision
must resolve before any caregiver-facing surface ships.

Gated by Epic 12 Task 12.12 (caregiver pre-build legal
framework). Paired with `../store-listing/age-rating-caregiver-uplift.md`
(age/rating uplift plan) and
`implementation_plan.md Part III.1` (v2 scope).

## The decision tree

```
Q1: Does Retraq Care ship standalone (separate app / sub-brand)
    or as a Premium feature inside the existing Retraq app?

├── Standalone app → NEW sub-brand required
│   Options: "Retraq for Family" / "Retraq Together" / "Retraq Care"
│
│   Q2: Who is the primary user of the new app — the person
│       with memory concerns, OR the caregiver?
│   ├── Memory-concern user (subject-first)
│   │   → UI/copy shifts to clinical-neutral. Lexend stays
│   │     (research-backed for cognitive accessibility).
│   │     Voice: "How was your day?" NOT "Drop a traq."
│   │     Palette: same primary green + warmer accent.
│   │     Store listing: Health & Wellness-adjacent (triggers
│   │     Play Health Apps Declaration review — see
│   │     categories-and-health-declaration.md v2 flip).
│   │
│   └── Caregiver (viewer-first)
│       → Dashboard-style app. Voice: informational,
│         reassuring, not playful. Copy example:
│         "[User] journaled 3 times this week."
│         Palette: primary green + warmer accent + more
│         data-visual heavy (charts, trend cards).
│         Store listing: Productivity / Family-Tools
│         category. Distinct from the subject-first app.
│
└── Premium feature inside existing Retraq → NO sub-brand
    Implementation: "Family Mode" toggle in Settings shifts
    copy + surfaces caregiver dashboard.
    Pros: lower marketing cost, one codebase, shared user base,
          faster to ship.
    Cons: persona friction — consumer users see
          "invite your caregiver" in their Settings and feel
          wrong. Caregiver users download Retraq expecting
          consumer journaling and find a family feature.
```

## Recommendation

**Standalone "Retraq for Family" sub-brand** when v2 ships.

### Why

- The three personas (consumer-adult, caregiver, memory-concern)
  have incompatible brand voices. Trying to stretch one app
  across all three produces copy that lands with none.
- App Store / Play Console category + age-rating posture for
  the caregiver tier (per
  `../store-listing/age-rating-caregiver-uplift.md`) flips from
  Everyone → Teen minimum, Health Apps Declaration flips from
  No → Yes. Keeping those under a separate package keeps the
  v1 consumer listing clean.
- Ad targeting + ASO keywords for caregiver search intent
  (`help my parent remember`, `family memory tool`) are
  entirely different from v1 ASO (`memory journal`,
  `quick mood log`). Separate listings let each rank natively.
- Marketing channel differences: v1 leverages general creator
  seeding + subreddit outreach (see `../gtm/battlecards/inflow.md`).
  v2 caregiver marketing flows through elder-care facilities,
  AARP, memory-care clinics — a completely separate go-to-market
  motion with different creative, different CAC assumptions,
  different tone.
- Legal posture diverges: caregiver tier requires
  Task 12.12's pre-build legal framework (controllership
  model, capacity attestation, mandatory-reporter analysis).
  Launching it inside the v1 app would require updating the
  v1 Privacy Policy, ToS, and consent flow in ways that
  complicate the consumer story.

### What "Retraq for Family" looks like

**Naming:**
- Primary: `Retraq for Family` (full wordmark)
- Store listing title: `Retraq for Family — memory journaling`
- App Store subtitle: `Stay connected through memory.` (30ch)
- Icon: derived from Retraq's Q motif with a softer warm
  accent replacing the teal

**Voice:**
- Warm-professional, not consumer-playful.
- "Your loved one journaled 3 times this week. Here are the
  moments they wanted to remember."
- NO "traq," NO "busy brains," NO "drop a," NO executive-
  function references.
- Crisis-adjacent copy ties to the Crisis Contacts feature
  per Task 12.16 with an extra emphasis on mandatory-reporter
  guidance (jurisdiction-specific, counsel-reviewed per
  Task 12.12).

**Visual:**
- **Keep:** Retraq logotype family (Lexend + Manrope —
  Task 13.10 preserved as-is), primary green `#33694B`.
- **Add:** warm accent hue (suggested amber/terracotta,
  pending Task 13.3 — tied to the CTA accent decision that's
  already tracked for v1.1).
- **Shift:** palette weighting. v1 leads with teal mood
  gradient; v2 leads with the warm accent + softer greens.
  The teal lives deeper in the UI (entry-detail surfaces)
  rather than on the home screen.
- **Layouts:** data-visualization-heavy (weekly trend card,
  mood-pattern summary) vs v1's entry-log-heavy layout.

**Technical:**
- Separate bundle ID: `com.retraq.family` (Apple) /
  `com.retraq.family` (Play).
- Shared Flutter codebase with feature-flag split (the bulk
  of code is identical: SQLCipher storage, encryption, share
  sheet, etc.). Differing surfaces gated by a
  `RetraqFlavor.family` constant.
- Separate App Store Connect + Play Console listings.
- Separate age-rating + privacy-label declarations per
  `age-rating-caregiver-uplift.md`.

### What this doc explicitly does NOT decide

- **Retraq Care pricing.** Separate decision — likely higher
  than consumer v1 pricing because caregiver tools command
  premium price points. Tracked against v2 monetization
  planning outside Epic 5.
- **Subject-first vs viewer-first app.** Depends on whether
  Retraq Care launches for caregivers watching capacitated
  users (viewer-first) or launches as a journaling app for
  users with early-stage cognitive decline (subject-first).
  The decision here says "standalone sub-brand"; whether
  that sub-brand is viewer-first or subject-first is a Q2
  decision inside the Q1 standalone-branch that happens at
  v2 scoping.
- **Legal framework.** Task 12.12 owns. This doc cross-
  references but does not duplicate.
- **Market sizing.** Outside Epic 13 scope; tracked in Epic
  5 Task 5.7 (caregiver wedge, v2 tier — blocked on user
  research that hasn't started).

## Why NOT the "Premium feature" path

Considered and rejected. Reasons:

1. **Brand voice contamination.** Once a caregiver surface
   exists in Settings, the v1 consumer user
   encounters it and the positioning story breaks. "Lost
   traq? Retraq." doesn't land if the Settings screen has
   a "Connect your parent" row.

2. **App Store review risk.** Mixing caregiver monitoring
   inside an app currently rated 4+ / Everyone would force a
   re-rating mid-lifecycle (current users' privacy
   expectations change). A standalone new SKU doesn't touch
   existing user relationships.

3. **Privacy policy scope blast.** Adding multi-user data
   sharing to the v1 app means the Privacy Policy covers
   both single-user consumer journaling AND caregiver sharing
   flows. Current policy is 1,200 words; adding caregiver
   pushes toward 2,500 and loses its "plain language"
   readability advantage (v1 is explicitly written for
   short / scannable length).

4. **Monetization blur.** Pricing a caregiver premium
   feature at $2-3/mo inside Retraq Pro would anchor it
   wrong (caregiver tools typically command $10-30/mo —
   see `../gtm/battlecards/inflow.md` price context).
   A separate app can set caregiver-appropriate pricing
   without dragging down consumer v1 pricing.

5. **ASO + marketing collision.** Apple Search Ads and Play
   keyword auctions for consumer-memory-journal keywords and
   "memory care" are in completely separate bidding pools.
   One listing cannot win both.

## Concept exploration checklist

When v2 activates, produce these three artifacts for user
testing (3 grandparents + 3 adult-children-caregivers per the
Agent 13 audit recommendation):

- [ ] **Wordmark variations** — "Retraq" + small "for
      Family" subtext vs compound wordmark (e.g.,
      "Retraq Family"). Compare readability at 24dp /
      40dp / 60dp (Task 13.4 silhouette rules apply here too).
- [ ] **Color pairing** — keep primary green, introduce a
      warm accent as family-identifier. Three candidate
      accents: amber `#E8A54B`, terracotta `#D47253`, or
      muted rose `#C57B7B`. Each tested for WCAG contrast
      against the same primary green.
- [ ] **Voice samples** — 5 lines of onboarding copy in
      the proposed sub-brand voice. Acceptance: none uses
      "traq" / "busy brains" / consumer-young-adult referents.

Compare candidate visual language against known caregiver-
market competitors for positioning clarity:

- **Medisafe** — pill reminder / caregiver dashboard hybrid.
  Warm + data-heavy. Heavy on pills icon.
- **Lotsa Helping Hands** — caregiver coordination. Calendar-
  driven, not journal-driven.
- **CareZone** — senior-care heavy. Green + white utilitarian.
- **MindMate** — brain-training + journaling competitor in the
  memory-care space. Bright + playful (WRONG tone for Retraq Care).

The gap Retraq Care occupies: caregiver-visible memory
journaling with zero-retention cloud posture and a warm-
professional voice. None of the above comps match.

## When this doc activates

Dormant until:

- Task 12.12 caregiver legal framework signed off (Epic 12).
- v2 scoping explicitly includes Retraq Care.
- User research on caregiver-market ICP has started (gated
  on v1 shipping, launch data stabilizing, and a deliberate
  product decision to pursue v2 caregiver vs other v2 wedges).

## Sibling artifacts

- [`../../implementation_plan.md`](../../implementation_plan.md)
  Part III.1 — Retraq Care v2 scope
- [`../store-listing/age-rating-caregiver-uplift.md`](../store-listing/age-rating-caregiver-uplift.md)
  — rating flip plan
- [`../store-listing/categories-and-health-declaration.md`](../store-listing/categories-and-health-declaration.md)
  — Play Health Apps Declaration flip
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.12 caregiver legal framework (gates this doc)
- [`../plans/epic-13-brand.md`](../plans/epic-13-brand.md) —
  Task 13.5 source; Task 13.1 icon design; Task 13.3 CTA
  accent color (shared motif for v2 warm accent)
- [`retraq-branding-guide.md`](./retraq-branding-guide.md) —
  canonical v1 brand (the thing v2 inherits from + diverges
  on voice)
- [`taglines.md`](./taglines.md) — v1 tagline bank (v2 gets
  its own, separate from "Lost traq? Retraq.")
- [`../external-blockers.md`](../external-blockers.md) —
  B-14 sub-brand decision (this doc operationalizes), B-10
  privacy counsel (gates it)
