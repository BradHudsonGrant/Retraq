# iOS App Store Connect age-rating answers — v1

**Status:** Ship-ready for v1 submission · **Task:** 9.9 ·
**Last updated:** 2026-04-16

Exact answers to the App Store Connect "Age Rating" questionnaire
for the v1 submission. Expected output rating: **4+**.

Every item below specifies the question as it appears in ASC and
Retraq's answer + rationale. When any answer changes, re-check
the expected rating and update this doc before re-submitting.

## Content descriptors

For each item, the ASC options are None / Infrequent/Mild /
Frequent/Intense. Retraq's answers:

| Descriptor | Answer | Rationale |
|---|---|---|
| Cartoon or Fantasy Violence | **None** | No fictional or illustrated violence anywhere in app. Mood blobs are emotion indicators, not characters. |
| Realistic Violence | **None** | Ditto. |
| Prolonged Graphic or Sadistic Realistic Violence | **None** | Ditto. |
| Profanity or Crude Humor | **None** | No profanity in any UI copy, legal text, or brand materials. User-entered content is private (on-device only). |
| Mature/Suggestive Themes | **None** | No suggestive visuals or themes. |
| Horror/Fear Themes | **None** | Anti-streak-shaming posture explicitly rejects horror/fear manipulation. |
| Medical/Treatment Information | **None** | Guarded by Task 9.8 `health-claim-guardrails.md` — no medical or treatment claims ship in listing or in-app copy. |
| Alcohol, Tobacco, or Drug Use or References | **None** | No references in UI or marketing. |
| Sexual Content or Nudity | **None** | Ditto. |
| Graphic Sexual Content or Nudity | **None** | Ditto. |
| Simulated Gambling | **None** | No gambling mechanics or rewards loops. Milestone celebrations are neutral copy per `docs/brand/taglines.md`. |
| Contests | **None** | No contests of any kind. |

## Other features

| Feature | Answer | Rationale |
|---|---|---|
| Unrestricted Web Access | **No** | App contains no web view; no browsing functionality. Crisis-contacts feature (Task 12.16) links to `findahelpline.com` via `url_launcher` as a fallback — this is an external-URL launch, not in-app web browsing, and does not require "Yes." |
| Gambling | **No** | No gambling. |
| User Generated Content (shared with other users) | **No** | Journal entries are stored locally, never shared with other users or a server. User-initiated export via OS share sheet is a deliberate user-driven export (same posture as Photos / Notes exports), not UGC-sharing in the App Store sense. |

## Sign-in / account features

| Question | Answer |
|---|---|
| Does the app require sign-in? | **No** |
| Does the app include Sign in with Apple? | **No** (no auth required) |
| Does the app collect contact information? | **No** |
| Does the app use advertising identifier (IDFA)? | **No** |

## Expected rating

**4+** — no age-restriction content descriptors triggered, no
web access, no UGC sharing, no gambling.

## iOS 13+ features the answers assume

- No ARKit / AR world-scale experiences.
- No HealthKit integration (v1). Do NOT enable; triggers 5.1.1(ix).
- No Siri Intents for personal data (v1).
- No Sign in with Apple (no auth).
- No CarPlay / Apple Watch companion (v1).
- No Family Sharing enabled (v1; caregiver tier is v2 only).

## When this document changes

Any of the following MUST trigger re-answering the questionnaire
and an updated submission:

### v1.1 cloud AI tier ships

- Re-confirm "Medical/Treatment Information = None" — holds,
  because summaries are user-written-prose condensations, not
  medical content (see `../gtm/ai-non-claims.md`).
- Re-confirm "Unrestricted Web Access = No" — holds, the AI
  tier calls out to a specific provider via a managed backend,
  not a web browser.
- Sign-in: still No (cloud AI tier can be entitlement-gated
  via RevenueCat without platform sign-in).
- Privacy nutrition label rewrite per Task 9.7.

### v2 caregiver tier ships

See `age-rating-caregiver-uplift.md` for the full delta. TL;DR:
  - UGC shared with other users: flips to "Yes" (caregiver
    view of subject data is in-app sharing).
  - Minimum rating expected: 12+.
  - Health Apps Declaration (Play): flips to "Yes"; full
    questionnaire required.

### Crisis contacts feature is substantially expanded

Current implementation (Task 12.16) is a static, read-only list
with external URL launches. If v1.1+ ever adds interactive
crisis intervention, conversational AI for mental-health
support, or hotline auto-dialing, re-answer the Medical/Treatment
Information descriptor (will likely trip to Infrequent/Mild at
minimum) and expect Apple 1.4.1 / 5.1.1(ix) review.

## Sibling artifacts

- [`age-rating-android.md`](./age-rating-android.md) — Play
  Store IARC questionnaire equivalent
- [`age-rating-caregiver-uplift.md`](./age-rating-caregiver-uplift.md)
  — pre-planned v2 caregiver flip
- [`health-claim-guardrails.md`](./health-claim-guardrails.md)
  — listing-copy red list that keeps "Medical/Treatment = None"
  defensible
- [`categories-and-health-declaration.md`](./categories-and-health-declaration.md)
  — Play Health Apps posture (sibling to the iOS equivalent)
- [`../plans/epic-09-app-store.md`](../plans/epic-09-app-store.md)
  — Task 9.9 source
