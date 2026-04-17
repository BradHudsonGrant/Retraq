# Category selection + Google Play Health Apps declaration

**Status:** Locked · **Task:** 9.4 · **Last updated:** 2026-04-16

The two listings have identical category posture. This doc is the
single source of truth answering: what category, why, and how we
handle Google Play's Health Apps declaration form.

Already surfaced in `ios.md` and `android.md`; this doc carries
the rationale + Health Apps answers so reviewers don't have to
reconstruct them from two listing files.

## Categories — locked

### Apple App Store

| Slot | Value |
|---|---|
| **Primary** | Lifestyle |
| **Secondary** | Health & Fitness |

Rationale: Lifestyle is the honest primary — Retraq is a journal,
not a clinical tool. Health & Fitness as secondary captures the
real ADHD-adult + wellness adjacency without triggering Apple
1.4.1 clinical-device review, provided the description copy
avoids medical language (see Task 9.8 guardrail list).

### Google Play

| Slot | Value |
|---|---|
| **Primary** | Lifestyle |
| **Tags** | Journaling, Productivity (if Play accepts multi-tag) |

**Primary is Lifestyle ONLY, not Health & Fitness.** Selecting
Health & Fitness triggers the Play Health Apps Declaration
questionnaire (January 2026 enforcement), which in turn invites
extra review of every health-adjacent phrase in the listing and
binary.

## Google Play Health Apps Declaration — answers

Q: **Does your app offer services or features that fall under
the Health Apps policy?**

A: **No**, with the following rationale documented for
reviewer visibility:

- Retraq is a personal journaling app; it does NOT claim to
  diagnose, treat, mitigate, or monitor any medical condition.
- Retraq does NOT track or aggregate health, fitness, or
  biometric data. The "mood" feature is an opt-in 5-level
  emoji scale the user picks freely, with no clinical
  framing; it is strictly analogous to a mood emoji on a
  social post.
- Retraq has no connectivity to health APIs, wearables, or
  medical devices. No HealthConnect / Health Connect
  integration.
- Retraq has no content described as wellness coaching,
  therapy, CBT, or any other named clinical modality. Retraq's
  store description is scrubbed of the triggering terms listed
  below.
- Cloud AI features (v1.1 opt-in, summary-only) do NOT provide
  interpretation, advice, diagnostic suggestion, or treatment
  recommendation. The summary is a condensation of user-written
  prose (see `docs/gtm/ai-non-claims.md` for the explicit
  allowed / blocked claim catalog).
- Retraq does NOT enable or support emergency / crisis
  response functions. The crisis-contact surface (Task 12.16)
  is a static, user-facing resource list — not an interactive
  health service.

If Google Play's automated scanning flags the listing for the
Health Apps questionnaire regardless, the answer above is
copy-pasteable into the free-text rationale field.

## Description-copy guardrails (reinforces 9.8)

To keep both listings safely outside the medical-device /
therapy envelope, description copy must NOT use any of these
terms:

- `treat`, `treatment`
- `diagnose`, `diagnostic`, `diagnosis`
- `therapy`, `therapist`, `therapeutic`
- `CBT`, `DBT`, `EMDR`, `ACT`, any named evidence-based therapy
- `clinical`, `clinically proven`
- `symptom tracker`, `symptom monitoring`
- `ADHD management` (management implies intervention)
- `dementia` (specific regulated condition; plus v1 is not
  caregiver-targeted)
- `depression`, `anxiety`, `PTSD`, `bipolar` (condition names
  in a feature-benefit context)
- `cure`, `heal`, `medical-grade`, `hospital-grade`

The `ai-non-claims.md` blocklist is the broader version of this
list for AI-tier copy; this description-copy list is the v1 core
listing equivalent.

## Allowed phrasing

Retraq CAN (and does) describe itself using:

- "Journal" / "journaling app"
- "Memory backup"
- "Recall" / "remember your week"
- "Mood scale" (noun, not verb — no "mood tracking")
- "On-device" / "private" / "offline"
- "Low-pressure habit" / "gentle reminders"
- "Designed for how ADHD-shaped memory actually works" — this
  is the edge case: it's a design-intent statement, not an
  efficacy claim. OK to use with care.

## Apple 5.1.1(ix) healthcare-data check

Although Retraq files as Lifestyle, Apple separately checks for
healthcare data handling under 5.1.1(ix). Retraq's posture:

- **No healthcare data is transmitted.** Zero-network invariant
  (Task 12.1).
- **No healthcare-adjacent data is stored in a shared location.**
  All storage is SQLCipher-encrypted and on-device.
- **Mood + journal entries that incidentally contain health
  information** (e.g. user writes "I had a migraine today") are
  stored with the same protection as any other entry.
- **Privacy policy** (`lib/legal/privacy_policy.dart`)
  explicitly addresses this — Task 12.2 landed controller
  disclosure + GDPR Art. 9 framing for EU markets.

## When the answer changes

The category posture + Health Apps "No" answer is correct for
v1. It MUST be re-evaluated when:

- **Cloud AI tier ships (v1.1).** Task 9.7 tracks the privacy
  nutrition label rewrite; the Health Apps answer should stay
  "No" because summary-only isn't a health service, but
  reviewers may ask. Keep the AI-non-claims list handy.
- **Caregiver tier ships (v2).** Retraq Care involves multi-
  user data sharing (invite codes, capacity attestation,
  possibly subject/viewer health-adjacent signals). Expect the
  answer to flip to "Yes" and require the full questionnaire.
  Planned for Epic 12 Task 12.12 outside-counsel review first.
- **Any medical partnership / clinical trial involvement
  starts.** Not in current roadmap; flag as a re-review
  trigger anyway.

## Sibling artifacts

- [`ios.md`](./ios.md) — canonical iOS listing copy with this
  category block
- [`android.md`](./android.md) — canonical Android listing
  copy with this category block
- [`aso-keyword-strategy.md`](./aso-keyword-strategy.md) —
  keyword targets informed by the category constraints
- [`../gtm/ai-non-claims.md`](../gtm/ai-non-claims.md) — AI-tier
  claim blocklist
- [`../plans/epic-09-app-store.md`](../plans/epic-09-app-store.md)
  — Task 9.8 medical-device guardrail
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.2 controller disclosure, 12.12 caregiver pre-build
  framework
