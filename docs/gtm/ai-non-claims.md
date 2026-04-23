# AI claims Retraq will NOT make

**Status:** Ship-ready · **Task:** 5.10 (companion) · **Last updated:** 2026-04-16

This is a **blocklist** for marketing, store-listing, onboarding,
in-app copy, and paywall language. Any claim on this list makes
Retraq vulnerable under Apple 1.4.1, Play Console Health Apps
policy, FTC advertising rules, or the EU AI Act — and undermines
the product positioning at the same time.

**Scope:** applies to all v1 and v1.1 cloud-AI tier copy.
**Re-review cadence:** every major privacy-policy / legal review
(Epic 12), and before any AI-related App Store submission.

## Blocked claims — never use

| Claim category | Example phrasing | Why blocked |
|---|---|---|
| **Therapy** | "AI therapist," "AI therapy," "therapeutic journaling" | Medical-device risk (Apple 1.4.1, Play Health policy); implies licensed clinical practice |
| **Coaching** | "AI coach," "your AI coach," "personalized coaching" | Marketed coaching claims trigger therapy/wellness overlap in regulated markets; undermines the memory-backup frame |
| **Named modality** | "AI-guided CBT," "DBT-informed AI prompts," "EMDR support" | Named evidence-based therapies are clinical claims; we are not licensed to deliver them |
| **Diagnosis** | "AI detects depression," "mood-disorder screening," "identifies anxiety patterns" | Medical-device classification trigger; FDA / Health Canada / EMA territory |
| **Treatment** | "AI treats," "AI reduces symptoms," "manages your condition" | Same; plus FTC advertising rules forbid unsubstantiated outcomes |
| **Behavioral outcomes** | "Change your habits," "rewire your brain," "build new neural pathways" | Unsubstantiated claims; attracts FTC scrutiny even in wellness apps |
| **Clinical outcomes** | "Better sleep," "reduced anxiety," "improved focus" | Health benefit claims without clinical trial basis |
| **Medical advice** | "What your symptoms mean," "should you see a doctor" | Unlicensed medical advice |
| **Predictive mental health** | "AI predicts your mood," "forecasts your mental state" | Algorithmic-discrimination concerns (Quebec Law 25, EU AI Act high-risk category) |
| **Emotional labor framing** | "AI understands you," "feels what you feel" | Sets false expectations; category-confused with companionship apps |
| **Expert / authority mimicry** | "Ask our AI expert," "AI psychologist" | Dishonest framing; "expert" vs unlicensed algorithm |
| **Retention-manipulation** | "AI remembers you always," "never forgets" about the AI itself | Parasocial framing; counter to the anti-streak-shaming brand voice |

## Allowed claims — safe to use

These describe what Retraq's AI tier actually does (v1.1, opt-in,
summary-only) without triggering the blocklist:

| Allowed claim | Context |
|---|---|
| "Your week, summarized" | Paywall headline |
| "A paragraph recap of the week you wrote yourself" | Feature description |
| "AI-generated weekly summary" | Feature list, neutral phrasing |
| "Optional cloud summary (opt-in)" | Settings toggle label |
| "Summary of your entries" | Recap card in-app label |
| "Synthesizes the week you wrote" | Blog / press kit |
| "AI filter on your memory, not your therapist" | Press soundbite |

## Language-adjacent rules

- **Verbs matter:** `summarize`, `synthesize`, `recap`, `condense`
  are safe. `interpret`, `analyze`, `advise`, `recommend`,
  `diagnose`, `understand` are blocked.
- **Nouns matter:** `summary`, `recap`, `overview`, `synthesis`
  are safe. `insight`, `analysis`, `assessment`, `advice`,
  `treatment`, `intervention` are blocked or require legal review.
- **Adjectives matter:** `AI-generated`, `algorithmic`, `optional`
  are safe. `intelligent`, `smart`, `personalized`, `empathetic`,
  `emotional` are blocked or require legal review.

## Platform-specific checks

### Apple App Store

- **1.4.1 Health & Safety:** App Review rejects apps making therapy
  / coaching / diagnosis claims without appropriate licensing. Any
  blocked claim from the table is a near-certain rejection.
- **Privacy Nutrition Label:** when cloud AI ships (v1.1), prompts +
  outputs are "Data Linked to You" and must be disclosed. Label
  rewrite plan is Task 9.7.

### Google Play

- **Health Apps category policy** requires substantiation for any
  "medical" or "health" claim. Retraq files under Lifestyle /
  Productivity (Task 9.4); any blocked claim would force
  recategorization and invite additional review.

### FTC (US advertising)

- **Substantiation rule** — health/wellness claims require
  "competent and reliable scientific evidence." We do not have
  that evidence base for any blocked claim.
- **Endorsement guides** — AI-as-spokesperson framing triggers
  disclosure rules. Avoid entirely.

### EU AI Act

- **High-risk category triggers** include "AI systems intended to
  assess emotional state or mental health." Any blocked claim
  pushes Retraq's AI tier from low-risk (summary) into high-risk
  (assessment), requiring conformity assessment.
- **Transparency obligations** still apply to the summary tier —
  user must know they're reading AI output. Handled in the
  AI-tier messaging doc.

### Quebec Law 25 / Canadian PIPEDA

- **Automated decision-making disclosure** required for any
  algorithmic processing of personal info. Summary-as-service is
  borderline; Task 12.13 tracks the PIA.
- **Health info** (which incidentally appears in journal entries)
  triggers Art. 9 consent in GDPR territories — handled by
  Task 12.4 explicit consent gate.

## PR-level enforcement

The three ways this list is enforced in practice:

1. **CONTRIBUTING.md** points to this doc under a "marketing copy
   review" section (follow-up: add a pointer).
2. **Epic 12 legal reviews** check any user-facing AI copy against
   this list before approving a release.
3. **PR template checkbox** (follow-up): "Any AI-related user-
   facing copy in this PR has been checked against
   `docs/gtm/ai-non-claims.md`."

## Sibling artifacts

- [`./battlecards/rosebud-mindsera.md`](./battlecards/rosebud-mindsera.md)
  — primary consumer of this blocklist.
- [`./positioning-one-pager.md`](./positioning-one-pager.md) — the
  'no clinical language' writing rule top-level.
- [`./privacy-narrative.md`](./privacy-narrative.md) — v1.1 privacy
  label transition for AI tier.
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.4 Art. 9 consent, Task 12.13 AI transparency / Quebec PIA.
- [`../plans/epic-09-app-store.md`](../plans/epic-09-app-store.md)
  — Task 9.4 category decision, Task 9.8 medical-device guardrail.
