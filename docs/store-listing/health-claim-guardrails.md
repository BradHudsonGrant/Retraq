# Health-claim guardrails for store listings

**Status:** Ship-ready · **Task:** 9.8 · **Last updated:** 2026-04-16

> This is the **red/yellow/green word list** every App Store and
> Play Console listing file in `docs/store-listing/` has to pass
> before submission. Any red-list word anywhere in a listing file
> (title, subtitle, short description, long description,
> promotional text, screenshot overlay) is a hard fail.
>
> Applies equally to paid ads and landing-page hero copy. Companion
> to `docs/gtm/ai-non-claims.md` (which covers the AI-tier claim
> surface) and `categories-and-health-declaration.md` (which
> covers the category-side of the medical-device envelope).

## Why this exists

- **Apple 1.4.1 (Medical Device)** rejects apps that implicitly
  claim medical benefit without appropriate clearance (FDA,
  Health Canada, CE-MDD).
- **Apple 3.1.7 (Uncontrolled health claims)** rejects apps
  making diagnosis, treatment, or prognosis claims.
- **Apple 5.1.1(ix)** requires special handling of healthcare
  data — can push the app into a higher review tier.
- **Google Play Health Apps policy** (Jan 2026) enforces
  substantiation for any health-benefit claim + requires the
  Health Apps Declaration form if Health & Fitness is primary
  category (we file Lifestyle — see
  `categories-and-health-declaration.md`).
- **Google Play Misleading Claims policy** rejects
  unsubstantiated "scientifically proven" / "evidence-based"
  framing.
- **FTC Act §5** mandates competent and reliable scientific
  evidence for health / wellness claims in US advertising.
- **EU AI Act** flags mental-health-assessment claims as
  high-risk, triggering conformity assessment (cross-ref
  `../gtm/ai-non-claims.md`).

## Red list — reject on sight

Any of these appearing in any listing file is a hard submission
blocker. The CI check (see below) fails the build.

- `treat`, `treats`, `treating`, `treatment`, `treatments`
- `diagnose`, `diagnoses`, `diagnosing`, `diagnosis`, `diagnostic`
- `cure`, `cures`, `curing`
- `heal`, `heals`, `healing`, `healed` (metaphorical OK in
  press/blog, NEVER in listings)
- `therapy`, `therapist`, `therapies`, `therapeutic`,
  `therapeutically`
- `clinical`, `clinically`, `clinically-proven`,
  `clinically proven`
- `evidence-based`, `research-backed`, `scientifically-proven`,
  `scientifically proven`, `studies show`
- `medical`, `medical-grade`, `hospital-grade`, `FDA-cleared`,
  `FDA-approved`, `FDA approved` (unless literally true and
  certified — it is not, and won't be in v1)
- `CBT`, `DBT`, `EMDR`, `ACT`, `IFS` (named modalities)
- `dementia`, `Alzheimer`, `Alzheimer's`, `cognitive decline`,
  `cognitive impairment`
- `depression`, `anxiety`, `PTSD`, `bipolar`, `OCD`, `BPD`,
  `schizophrenia` (condition names in listing copy — these can
  appear in the crisis-contacts feature description but NOT in
  marketing copy)
- `symptom`, `symptoms`, `symptom tracker`, `symptom monitoring`
- `memory loss`, `memory problems`, `forgetting is a problem`
- `psychologist`, `psychiatrist`, `counselor`, `social worker`
- `ADHD management`, `manage your ADHD`, `manage your anxiety`,
  `manage your depression` (management verb)
- `behavior change`, `rewire your brain`, `neural pathways`,
  `neuroplasticity`

## Yellow list — require reviewer ack

These are category-adjacent and permissible in specific
contexts, but any use in a listing file requires explicit
sign-off from brand review (Epic 13) + legal (Epic 12). They
should appear in the PR description with rationale:

- `ADHD`, `ADHD-friendly`, `ADHD-adjacent`, `ADHDer`,
  `for ADHD brains` — allowed as audience descriptor, NOT as
  intervention claim. Sentence-level context check required.
- `neurodivergent`, `neurodivergent-friendly` — same as ADHD.
- `memory`, `forgetful`, `forget`, `remember` — central to the
  'memory backup' positioning but adjacent to cognitive-
  function territory. OK when paired with a
  user-behavioral-frame ('days you forget what you had for
  lunch') not a clinical frame ('memory impairment').
- `busy brain`, `scattered brain`, `executive function` —
  audience-descriptor OK, function-claim NOT OK.
- `wellness`, `well-being`, `self-care` — borderline with Play
  Health Apps. Avoid as primary frame; OK as adjacent language.
- `journal`, `journaling` — green on its own but yellow when
  paired with `therapeutic` or `CBT` modifiers.
- `mood`, `mood scale`, `mood log` — green as noun, yellow as
  verb-object ('track your mood' borderline).

## Green list — safe, use freely

- `journal`, `diary`, `notebook` (as nouns)
- `memory backup`, `recall`, `retraq`, `remember your week`
- `recap`, `weekly recap`, `summary`, `on this day`
- `daily`, `every day`, `once a day` (frequency-neutral)
- `private`, `on-device`, `offline`, `encrypted`, `never leaves
  your phone`
- `simple` — but see below on positioning warnings
- `no ads`, `no tracking`, `no sync`, `no account required`
- `mood scale`, `blob emoji`, `5-point` (feature-descriptive)
- `habit`, `light habit`, `low-pressure` (compare to red-list
  'behavior change')
- `quick`, `one sentence`, `a line a day` (speed-descriptive;
  tone-compatible with brand voice)
- `ADHDTok`, `r/ADHD` (community-reference contexts only —
  audience-descriptor, not claim)

## Positioning warning — "simple" is green but lazy

Green in the regulatory sense, BUT the positioning-one-pager
explicitly bans "simple" as a headline claim because the word
is commoditized across every competitor in the category. Use
it for feature-level descriptions if needed, never as the
primary pitch. See `../gtm/positioning-one-pager.md` writing
rules.

## CI enforcement

A follow-up task (`tool/check_store_copy.dart` — tracked as
T-task against this spec) will implement the lint step:

```dart
// Greps every .md file in docs/store-listing/ for red-list
// words (case-insensitive, with word-boundary anchors so
// 'treated' triggers but 'retreat' does not).
// Exit 1 + print the offending file+line on any hit.
// Runs in .github/workflows/ci.yml after the existing l10n
// drift check (Task 10.9).
```

The red list above is the authoritative input. When the lint
ships, CONTRIBUTING.md gets an entry pointing PR authors here
when the check fails.

Until the lint ships: manual review per PR that touches
`docs/store-listing/*.md`.

## Audit trail

Every listing submission (Apple, Play) records which listing-file
SHA was submitted. If a regulator ever challenges a claim, the
audit trail points to the exact listing version + this guardrail
file in effect at the time.

## Sibling artifacts

- [`categories-and-health-declaration.md`](./categories-and-health-declaration.md)
  — the category-selection half of the medical-device envelope
- [`ios.md`](./ios.md), [`android.md`](./android.md) — listing
  copy this guardrail protects
- [`aso-keyword-strategy.md`](./aso-keyword-strategy.md) —
  keyword targets that pre-filter for green/yellow-safe terms
- [`../gtm/ai-non-claims.md`](../gtm/ai-non-claims.md) — AI-tier
  claim blocklist (the sibling of this list for AI-specific copy)
- [`../gtm/positioning-one-pager.md`](../gtm/positioning-one-pager.md)
  — writing rules that complement this list
- [`../plans/epic-09-app-store.md`](../plans/epic-09-app-store.md)
  — Task 9.2 listing copy, Task 9.4 categories, Task 9.7 v1.1
  nutrition label rewrite
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  legal-counsel review trigger for yellow-list use

## Maintenance cadence

Review this list:
- Before every App Store / Play Console submission
- When Apple / Play publish a policy update (track via App
  Store Review News + Play Console policy notifications)
- When FTC / FDA / Health Canada / EMA / EU publish new
  guidance relevant to wellness apps
- When the v1.1 cloud AI tier goes up for review (pairs with
  `ai-non-claims.md` + Task 9.7)
