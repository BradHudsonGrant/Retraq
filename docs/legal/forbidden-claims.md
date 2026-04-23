# Forbidden claims — lint-enforced blocklist

**Status:** Enforced in CI · **Task:** 12.5 · **Last updated:** 2026-04-16

Retraq's conservative health-claim posture is a PRODUCT decision
(see `../gtm/positioning-one-pager.md`, `../gtm/ai-non-claims.md`)
AND a REGULATORY one (Apple 1.4.1 / 5.1.1(ix), Google Play
Health Apps policy, FTC Act §5). The Agent 12 audit rated
Retraq's current copy as "Compliant."

This document is the narrow version of that posture: six terms
no user-facing or repo-visible string can contain. Broader
per-surface writing rules live in:

- `../gtm/positioning-one-pager.md` — no "simple" / "powerful"
- `../gtm/ai-non-claims.md` — 12 blocked AI-claim categories
- `../store-listing/health-claim-guardrails.md` — three-tier
  red/yellow/green list for store-listing copy specifically
- `../gtm/engagement-copy-review.md` — no-loss-framing list

This 6-term list is the CI-enforced floor. The other lists are
reviewer-enforced but more nuanced.

## The six forbidden terms

The CI lint scans shipping surfaces only: `lib/` (excluding the
two disclaimer files listed below), `assets/`, `docs/gtm/` (minus
`ai-non-claims.md`), and `docs/store-listing/` (minus
`health-claim-guardrails.md` + `categories-and-health-declaration.md`).

Internal engineering / planning docs (`docs/plans/`,
`docs/legal/` except this file, `docs/brand/`, `docs/sessions/`)
are NOT scanned — they legitimately reference the terms when
documenting the policy itself, and scanning them creates
false-positive churn without any shipping-surface protection
benefit.

Any scanned file that contains — case-insensitively — any of:

| Term | Why forbidden | Legal basis |
|---|---|---|
| `cures` / `cure` | Medical-device claim | Apple 1.4.1, FTC §5 substantiation |
| `treats` / `treat` / `treating` | Medical-treatment claim | Apple 1.4.1, Play Health Apps |
| `diagnoses` / `diagnose` / `diagnosing` | Diagnostic claim | Apple 1.4.1, FDA / Health Canada |
| `FDA-approved` / `FDA approved` | False regulatory claim | FTC §5 (plus not true — not FDA cleared) |
| `HIPAA-compliant` / `HIPAA compliant` | False compliance claim | HIPAA applies only to covered entities; Retraq is NOT one |
| `clinically proven` | Unsubstantiated clinical claim | FTC §5 substantiation, Apple 3.1.7 |

...will fail the build.

**Pattern-match:** the CI lint uses case-insensitive regex with
word-boundary anchors so `treated` triggers but `retreated` does
not. `cure` and `treat` match as independent words, not
substrings.

## Allow-list for documentation + disclaimer contexts

The lint has five narrow exemptions split across two
categories.

**Documentation files that reference the terms to explain
why they're banned:**

1. **This file** (`docs/legal/forbidden-claims.md`) — the
   blocklist itself.
2. **`docs/gtm/ai-non-claims.md`** — the broader AI claim
   blocklist.
3. **`docs/store-listing/health-claim-guardrails.md`** — the
   store-listing red list.

**Legal disclaimer files that use the terms in negated form
to DISCLAIM them** (i.e. "Retraq does NOT diagnose, treat,
cure..."):

4. **`lib/legal/terms_of_service.dart`** — medical-device
   carve-out in the ToS requires the negated phrasing per
   Apple 1.4.1 / Play Health Apps guidance.
5. **`lib/legal/health_disclaimer.dart`** — user-facing
   health disclaimer explicitly uses "does not diagnose,
   treat, cure, or prevent" to make the non-medical-device
   posture unambiguous.

These five paths are excluded via `--glob '!...'` in the CI
script. Any NEW file that wants to mention the banned terms
(e.g. a new audit report, a new disclaimer surface) must
either: (a) get added to the exclusion list in the CI script
with counsel sign-off, OR (b) use alternate phrasing. Default
to option (b); option (a) requires explicit reviewer
acknowledgement.

## The CI lint

Added to `.github/workflows/ci.yml` (follow-up: see section
below). Script is Bash-portable, runs in Linux + macOS GitHub
Actions runners:

```bash
#!/bin/bash
# Task 12.5 — forbidden-claims lint. Fails CI if any of the six
# terms appear in shipping surfaces (lib/ + assets/ +
# docs/gtm/ + docs/store-listing/) outside the files listed in
# the exemption list above.
set -euo pipefail

# Use ripgrep (pre-installed on GitHub runners) for speed.
# Case-insensitive (-i), word-boundary anchors in each alternation,
# and --glob excludes on the exemption paths.
if rg -i \
     -e '\bcures?\b' \
     -e '\btreats?\b' \
     -e '\btreating\b' \
     -e '\bdiagnoses?\b' \
     -e '\bdiagnosing\b' \
     -e '\bFDA[- ]approved\b' \
     -e '\bHIPAA[- ]compliant\b' \
     -e '\bclinically proven\b' \
     --glob '!lib/legal/terms_of_service.dart' \
     --glob '!lib/legal/health_disclaimer.dart' \
     --glob '!docs/gtm/ai-non-claims.md' \
     --glob '!docs/store-listing/health-claim-guardrails.md' \
     --glob '!docs/store-listing/categories-and-health-declaration.md' \
     lib/ assets/ docs/gtm/ docs/store-listing/; then
  echo "::error::Forbidden health claim term detected. See docs/legal/forbidden-claims.md"
  exit 1
fi
```

### Why this specific regex set

- Word-boundary anchors (`\b`) prevent false positives on
  unrelated words that contain the stem (e.g. `retreat`,
  `curea`, `diagnosis-free`).
- The `s?` conjugation handles singular/plural without
  enumerating every form.
- The `[- ]` in `FDA[- ]approved` catches both "FDA-approved"
  and "FDA approved" without a space-vs-hyphen false negative.
- The phrase `clinically proven` is matched as a literal
  bigram — `clinical` alone is fine (it's a dictionary word
  that appears in guardrail docs and negated form like
  "not clinical"), but the paired phrase is the claim.

### Why NOT use the broader guardrails list

The 30+ term `health-claim-guardrails.md` red list is
context-sensitive: `ADHD` is RED everywhere in shipping copy
(marketing claim) but may appear in privacy-policy explanations
or historical audit docs. A CI lint that enforces it blindly
would fail every audit doc that references "ADHD" or "memory"
legitimately. The 6-term list above has zero legitimate-use
cases in the codebase outside the three exempted meta-docs, so
the CI floor enforces it without reviewer judgment required.

## Integration with existing CI

The lint runs after the l10n drift check (Task 10.9) and
before the test step, inside the main `analyze-and-test` job.
See `.github/workflows/ci.yml` — a follow-up commit will wire
the step in.

Failure message points offending file + line per ripgrep's
default output format; contributors fix by rephrasing the
claim using the allowed-phrasing guidance from
`health-claim-guardrails.md`.

## Exception path

If a regulated context ever legitimately requires one of
these terms (e.g. a future clinical-trial partnership doc),
the process is:

1. Propose the exemption in a PR with counsel sign-off noted.
2. Add the new path to the `--glob '!...'` list in the CI
   script.
3. Document the exemption in this file under a new "Active
   exemptions" section.

Currently there are no active exemptions beyond the three
meta-docs listed in the allow-list above.

## Sibling artifacts

- [`../gtm/ai-non-claims.md`](../gtm/ai-non-claims.md) —
  broader AI-specific blocklist
- [`../store-listing/health-claim-guardrails.md`](../store-listing/health-claim-guardrails.md)
  — red/yellow/green listing-copy list
- [`../gtm/engagement-copy-review.md`](../gtm/engagement-copy-review.md)
  — no-loss-framing rules
- [`../gtm/positioning-one-pager.md`](../gtm/positioning-one-pager.md)
  — no-simple / no-powerful rules
- [`ai-transparency.md`](./ai-transparency.md) — cloud AI
  transparency disclosures (the bigger post-v1.1 story)
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.5 source
