# Caregiver-tier age-rating uplift plan (v2)

**Status:** Pre-planned — not ready to submit · **Task:** 9.9
companion · **Last updated:** 2026-04-16

When Retraq Care (caregiver tier, v2) ships, the age rating on
both platforms flips from Everyone to **12+ / Teen minimum**.
This doc enumerates every questionnaire answer that flips so
the v2 submission doesn't require re-deriving the rationale
from scratch.

Paired with `age-rating-ios.md` (v1 baseline) and
`age-rating-android.md` (v1 baseline). Gated by Epic 12 Task
12.12 outside-counsel review.

## Why the rating flips

Retraq Care introduces:

1. **Multi-user data sharing.** Invite codes, subject → viewer
   views of entry metadata (mood trend, entry count, optional
   flagged words). This is in-app UGC sharing in the
   platform-review sense.
2. **Incidental health-adjacent data.** Journal entries
   summarized for a caregiver viewer can incidentally include
   mental / physical health references. The v1 on-device-only
   posture kept this out of the platform-review frame; sharing
   it with a second user pulls it in.
3. **Cross-user communication surfaces.** Even if caregiver
   read is "view-only" in v2 MVP, the invite-code flow creates
   a communication channel between accounts.

Each of these independently pushes the rating above Everyone /
4+.

## iOS App Store Connect — questions that flip

Baseline (v1): 4+. Target (v2 caregiver): **12+**.

| ASC question | v1 answer | v2 answer | Why it flips |
|---|---|---|---|
| User Generated Content | No | **Yes — shared with other users (invite-based)** | Caregiver view of subject data is inter-user content sharing |
| Medical/Treatment Information | None | **Infrequent/Mild** (review) | Caregiver dashboard shows mood trend + entry cadence — still not treatment, but pattern-display of health-adjacent data crosses into Mild in some reviewers' view. Legal should verify. |
| Horror/Fear Themes | None | None | Unchanged; anti-fear framing holds |
| Unrestricted Web Access | No | No | Unchanged |
| Contests | None | None | Unchanged |

**Additional iOS-specific questions for v2:**

- Does the app collect contact information? — **Yes** (caregiver
  invite codes pair with a subject account; minimal contact
  surface but it exists).
- Family Sharing enabled? — Decision pending. Likely **No** —
  caregiver relationships often cross Family Sharing boundaries
  (adult child + elderly parent on different Apple IDs). Use
  the invite-code model instead of platform Family Sharing.

**Expected v2 iOS rating: 12+.**

## Google Play IARC — questions that flip

Baseline (v1): Everyone. Target (v2 caregiver): **Teen (PEGI
12)** at minimum; possibly Mature 17+ if sensitive-content
review flips any Mild category to Moderate.

| IARC question | v1 answer | v2 answer | Why it flips |
|---|---|---|---|
| Users interact | No | **Yes (invite-based caregiver view)** | Multi-user data sharing |
| Shares personal information with other users | No | **Yes** | Entry metadata + mood trend shared with caregiver |
| Digital purchases | Yes (v1.1 IAP) | Yes (continued from v1.1 IAP) | No change beyond v1.1 |
| Unrestricted internet | No | No | Unchanged |
| Designated for Families | No | No | Adult-targeted tier; explicitly NOT for kids |
| Targets children | No | No | Caregiver tier targets adults caring for other adults (not kids) |

**Play Health Apps Declaration** flips v1 → v2:

- **v1 answer:** No (see `categories-and-health-declaration.md`).
- **v2 answer:** **Yes.** Caregiver view of mood + entry
  patterns is a health-adjacent aggregation UI that crosses
  the Health Apps policy threshold. Full questionnaire
  required; expect additional review cycles.

**Expected v2 Play rating: Teen (PEGI 12)** if no
sensitive-content items flip beyond Mild. Escalates to **Mature
17+** if reviewers flag the mood-trend dashboard as adult-themed
mental-health content.

## Feature-level prerequisites before v2 submission

Before any of the flips above are answered "Yes" on a real
submission, the app must have:

- [ ] **Capacity-attestation flow** (Epic 12 Task 12.12). Subject
      demonstrates capacity to consent to sharing; caregiver
      cannot unilaterally invite an incapacitated user.
- [ ] **Invite-code UX** with explicit opt-in per caregiver
      (no auto-accept).
- [ ] **Caregiver-facing ToS** (Epic 12 Task 12.12) with
      hold-harmless for data accuracy + explicit "not a medical
      device" disclaimer.
- [ ] **Play Data Safety form update** reflecting inter-user
      sharing (`android.md` Data Safety section needs a v2
      rewrite).
- [ ] **iOS Privacy Nutrition Label update** (Task 9.7) adding
      "Contact Info (Email or Account Pairing)" as a Linked
      data type if invites use email.
- [ ] **v2-specific listing-copy guardrail pass** —
      `health-claim-guardrails.md` red/yellow list re-applied to
      caregiver-tier marketing copy with extra scrutiny on
      "memory loss," "dementia," "Alzheimer" (all still RED).
- [ ] **Ethics / privacy-counsel sign-off** (Epic 12 Task 12.12)
      from B-6 / B-10.
- [ ] **Legal review of caregiver-specific listing copy** by
      privacy counsel before platform submission.

## Explicitly out-of-scope for v2 MVP

- Medical-device clearance (FDA, Health Canada, CE-MDD) — NOT
  pursued in v2. If the feature ever progresses into
  diagnostic territory, that's a v3+ decision requiring
  dedicated regulatory strategy.
- HealthKit / Health Connect integration — deferred. Keeps
  the tier outside the regulated-health-data envelope even
  when rating flips to 12+.
- Remote live communication between subject + caregiver —
  also deferred. MVP is one-way view only. Two-way communication
  is v3+.

## When this document activates

Currently dormant. Activates when:

- Epic 12 Task 12.12 caregiver legal framework is signed off.
- Caregiver feature spec enters active engineering.
- Pre-submission review is being planned for the first
  caregiver-tier release.

Re-read this doc + `categories-and-health-declaration.md` +
`health-claim-guardrails.md` before re-answering any
questionnaire.

## Sibling artifacts

- [`age-rating-ios.md`](./age-rating-ios.md) — v1 baseline
- [`age-rating-android.md`](./age-rating-android.md) — v1 baseline
- [`categories-and-health-declaration.md`](./categories-and-health-declaration.md)
  — Play Health Apps posture (flips for caregiver)
- [`health-claim-guardrails.md`](./health-claim-guardrails.md)
  — copy red list (unchanged for caregiver; re-apply with
  extra scrutiny)
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.12 caregiver pre-build legal framework (gates this)
- [`../../implementation_plan.md`](../../implementation_plan.md)
  Part III.1 — Retraq Care (caregiver tier) v2 scope
- [`../external-blockers.md`](../external-blockers.md) — B-10
  privacy counsel (caregiver pre-build)
