# Google Play IARC age-rating answers — v1

**Status:** Ship-ready for v1 submission · **Task:** 9.9 ·
**Last updated:** 2026-04-16

Exact answers to the IARC (International Age Rating Coalition)
questionnaire used by Google Play Console for the v1 submission.
Expected output: **Everyone (PEGI 3 / ESRB E / CERO A)**.

Every item below specifies the question as it appears in IARC
and Retraq's answer + rationale. When any answer changes,
re-check the expected rating and update this doc before
re-submitting.

## Content categories

| Category | Answer | Rationale |
|---|---|---|
| Violence | **No** | No violence of any kind (realistic, fantasy, or implied). |
| Sexual content | **No** | None in UI, legal copy, or marketing. |
| Nudity | **No** | None. |
| Profanity | **No** | No profanity in UI copy. User-entered content is private; Play does not rate on-device private content. |
| Crude humor | **No** | None. |
| Scary or disturbing content | **No** | Anti-streak-shaming posture explicitly avoids fear / horror framing. |
| Controlled substances references | **No** | No references to alcohol, tobacco, drugs in UI or marketing. |
| Gambling or simulated gambling | **No** | No gambling mechanics. Milestone celebrations are neutral, per `docs/brand/taglines.md`. |

## Interactive elements

| Element | Answer | Rationale |
|---|---|---|
| Users interact | **No** | No user-to-user communication surface. Journal entries are local-only. |
| Shares location | **No** | App does not request or read location permissions. |
| Digital purchases | **No (v1)** | v1 ships with no IAP. **Flip to Yes when Retraq Pro (v1.1) ships via RevenueCat** — see `../gtm/lifetime-sku-decision.md`. |
| Unrestricted internet | **No** | No web view or browser functionality. External URL launch via `url_launcher` (crisis contacts, Task 12.16) is not "unrestricted internet" in the IARC sense — it's a specific-link launcher, same category as tapping a URL in a Notes app. |

## Privacy & data

The Play Data Safety form is separate from the age-rating
questionnaire. For the age rating only, IARC asks:

| Question | Answer |
|---|---|
| Does your app collect personal information? | **No** (local-only; data never leaves the device without explicit user-initiated OS share) |
| Does your app enable users to share personal information with each other? | **No** (no inter-user sharing surface) |
| Does your app access location? | **No** |

## Expected rating

**Everyone** globally:
- ESRB (North America): **E for Everyone**
- PEGI (Europe): **PEGI 3**
- CERO (Japan): **A** (All ages)
- USK (Germany): **0+** (no age restriction)
- Classind (Brazil): **Livre** (General)
- ACB (Australia): **G** (General)

No region-specific escalations expected.

## Google Play-specific age gates

Beyond IARC, Google Play has additional age-gate mechanisms for
apps with children-directed features or collected personal data
from children. Retraq answers:

| Gate | Answer | Rationale |
|---|---|---|
| Designated for Families (DFF) | **No** | Retraq's audience is general adults; it's not a kids-first app. Not enrolling in DFF. |
| Targets children as the primary audience? | **No** | Target demographic is 25–45 adults per `docs/gtm/positioning-one-pager.md`. |
| Contains features that COPPA would govern? | **No** | No child-targeted features; onboarding includes age-gate + consent flow (see Epic 12) that handles the edge case of an under-13 user attempting to install. |
| Family Policy self-cert required? | **No** | Only required if DFF program or ≤13 targeting. Neither applies. |

## When this document changes

### v1.1 ships with IAP

- Digital purchases: flip **No → Yes**.
- IARC re-check + re-submit the age-rating questionnaire.
- Expected rating stays **Everyone** (IAP presence alone does
  not escalate rating).

### v2 caregiver tier ships

- User interaction: flip **No → Yes** (caregiver-subject view
  is multi-user data sharing).
- Personal information sharing: flip **No → Yes**.
- Expected rating: **Teen / PEGI 12 minimum** (shared health-
  adjacent data between users crosses the Everyone threshold).
- Play Health Apps Declaration: flip to **Yes** per
  `categories-and-health-declaration.md` triggers.
- See `age-rating-caregiver-uplift.md` for the complete delta.

### Crisis-contacts feature expands to interactive hotline dialing

- Scary/disturbing content: review — crisis UI is sensitive but
  framed supportively; likely stays **No** but triggers reviewer
  scrutiny on the full questionnaire.

### App adds any ad SDK

- Currently rule: no ad SDKs ever in the Retraq app binary
  (load-bearing privacy claim, see `docs/gtm/privacy-narrative.md`).
- If this ever changes (should never happen in v1 or v1.1):
  re-answer controlled-substances / gambling-reference /
  mature-content gates because ad content is not under
  Retraq's control.

## Sibling artifacts

- [`age-rating-ios.md`](./age-rating-ios.md) — ASC questionnaire
  equivalent
- [`age-rating-caregiver-uplift.md`](./age-rating-caregiver-uplift.md)
  — pre-planned v2 caregiver flip
- [`health-claim-guardrails.md`](./health-claim-guardrails.md)
  — listing-copy guardrails that keep the rating defensible
- [`categories-and-health-declaration.md`](./categories-and-health-declaration.md)
  — Play Health Apps posture
- [`android.md`](./android.md) — canonical listing copy and
  Data Safety form
- [`../plans/epic-09-app-store.md`](../plans/epic-09-app-store.md)
  — Task 9.9 source
