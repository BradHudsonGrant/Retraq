# AI transparency disclosures for Retraq's recap tiers

**Status:** Spec for v1.1 cloud AI tier — companion to
`../gtm/ai-non-claims.md` · **Task:** 12.13 · **Last updated:** 2026-04-16

Retraq ships three recap tiers. This document specifies the
transparency disclosures required when each tier is active,
mapped to EU AI Act Art. 50, CNIL + OPC AI guidance, Quebec
Law 25 cross-border PI rules, and FTC Act §5 deceptive-AI
claims doctrine.

Paired with the v1.1 PIA (`pia-quebec-cloud-ai.md`) and the
consumer-facing `../gtm/ai-non-claims.md` blocklist.

## The three recap tiers

| Tier | What runs | Where | Data leaves device? | Ships | Tier label |
|---|---|---|---|---|---|
| **Tier 1** | Rule-based summary + calendar surfacing | On-device (Dart) | No | v1 (shipped) | Default for all users |
| **Tier 2** | Gemini Nano on-device LLM summary | On-device (Android Pixel-class hardware only) | No | v1.1 (free tier, Pixel-only) | Opt-in where hardware allows |
| **Tier 3** | Cloud LLM summary | Cloud (single provider, zero-retention contract) | Yes — past 7 days of entries | v1.1 (paid Monthly / Annual) | Opt-in + per-recap consent |

Tier 1 is NOT marketed or labelled as AI. It's deterministic
rule-based code (see `lib/services/recap_service.dart` when it
lands; at the moment recap helpers live outside a service per
Task 1.14 backlog).

Tier 2 + Tier 3 are AI-generated output and MUST carry the AI
label per the regulatory requirements below.

## What regulation requires what

### EU AI Act Art. 50 (transparency)

Effective August 2026 for general-purpose AI provisions:

- **AI-generated output must be identifiable as such.** Retraq
  complies via the `✨ AI summary` badge on every Tier 2 + Tier 3
  recap.
- **User must be informed they are interacting with an AI system.**
  The `What's this?` modal satisfies this on first-use + on
  demand.
- **Deep-fake / synthetic media** — not applicable (recap is
  text, not media).

### CNIL (France) AI guidance

- **Prior information obligation** on automated decision-making
  adjacent to personal data — the pre-send confirmation dialog
  satisfies this for Tier 3.
- **Data minimization** — Retraq sends only the past 7 days of
  entries, not the full archive. Documented in
  `pia-quebec-cloud-ai.md`.

### OPC (Canada) AI guidance

- **Meaningful consent** — users must understand what data
  goes where. The pre-send confirmation names the provider,
  data scope, and retention.
- **Purpose limitation** — recap generation is the only
  purpose. No cross-use for training or improvement.

### Quebec Law 25 (cross-border PI)

- **Privacy Impact Assessment (PIA) required** before cross-
  border transfer of Quebec personal information. See
  `pia-quebec-cloud-ai.md`.
- **Equivalent protection** — DPA with provider must match
  Law 25 protections (zero-retention, no training, right to
  access/delete).

### FTC Act §5 (US)

- **Deceptive AI claims prohibited.** Retraq's paired
  `../gtm/ai-non-claims.md` blocklist enforces no therapy /
  diagnosis / coaching claims.
- **Substantiation** — any quantitative claim about the AI's
  output requires evidence. Retraq makes none beyond "summary."

## User-facing UI — required elements

### Tier 1 — no AI disclosure

Tier 1 recaps carry no AI label. They are deterministic
rule-based summaries and must not be marketed as "AI-powered"
(category-adjacent misrepresentation).

### Tier 2 — on-device AI label

Every Tier 2 recap displays:

```
✨ AI summary · On-device (Gemini Nano)
[recap text]
[What's this?]
```

Tapping `What's this?` opens a modal:

> **AI-generated summary**
>
> This recap was created by Gemini Nano, a small language
> model that runs entirely on your phone.
>
> - **Where it runs:** Your device only. Nothing leaves your
>   phone.
> - **Data used:** Your past 7 days of Retraq entries.
> - **What it does:** Synthesizes a paragraph from what you
>   already wrote.
> - **What it does NOT do:** Interpret, advise, diagnose, or
>   suggest treatment. See our [AI principles](...).
>
> AI summaries may contain inaccuracies. The entries
> themselves are always your source of truth.
>
> [Close]

### Tier 3 — cloud AI label + pre-send confirmation

**Pre-send confirmation** (shown before EVERY Tier 3 recap
generation, not one-time):

```
Generate cloud AI recap?

Your last 7 days of Retraq entries will be sent to [Provider]
to generate this week's summary.

• Data is processed and discarded. Our provider contract
  forbids retention and training use.
• Nothing else is sent. Your full journal stays on your phone.
• You can fall back to the on-device recap at any time in
  Settings.

[Cancel] [Generate recap]
```

**Rendered recap label:**

```
✨ AI summary · Cloud ([Provider])
[recap text]
[What's this?] [How my data is handled]
```

Two modals required:

1. **`What's this?`** — same structure as Tier 2 but with
   the cloud provider named and data-in-motion disclosure.
2. **`How my data is handled`** — technical disclosure
   modal covering:
   - Provider name + region
   - Data sent per recap (exact schema)
   - Retention (zero beyond processing)
   - Purpose limitation (summary generation only, no training)
   - Right to access / delete (platform-default account
     deletion already removes local data; provider side
     retains nothing)
   - Link to the full Privacy Policy

## Implementation requirements

### `lib/services/recap_service.dart` (when Task 1.14 lands)

The service returns `RecapResult` with:

```dart
class RecapResult {
  final String body;
  final RecapSource source; // enum: rule, onDeviceAi, cloudAi
  final String? modelProvider; // "Gemini Nano" / "Anthropic" / "OpenAI"
  final DateTime generatedAt;
}
```

UI code consumes `source` to decide:
- No label for `rule`.
- Tier 2 label + on-device modal for `onDeviceAi`.
- Tier 3 label + cloud modal + pre-send confirmation for
  `cloudAi`.

### `lib/screens/recap_screen.dart`

New `AiRecapBadge` widget (molecule, per Task 1.11 widget
taxonomy) encapsulates the sparkle icon + tier-aware label
+ `What's this?` trigger. Reused across Home and Recap tabs.

### Consent storage

Tier 3 consent is NOT persistent — the pre-send confirmation
fires every time. This is a deliberate dark-pattern-avoidance
choice: users shouldn't wake up in year 3 having forgotten they
opted into cloud processing. Re-confirming per use is friction,
but it's the correct friction.

Tier 2 on-device opt-in IS persistent (single toggle in
Settings → AI) because nothing leaves the device.

## What Tier 3 MUST NOT include

- No user-editable system prompt. The model processes entries
  with a fixed, audited prompt. Users who want prompt-level
  control should use Rosebud / Mindsera — see
  `../gtm/battlecards/rosebud-mindsera.md`.
- No chat / conversation affordance. Summary is one-shot,
  one-way. Chat UX rearms the AI-assessment regulatory
  trigger.
- No cross-recap memory. Each generation is stateless on the
  provider side. The user's local journal IS the memory.
- No therapy / advice framing. `../gtm/ai-non-claims.md`
  blocklist applies end-to-end.
- No provider-level analytics. Provider contract must forbid
  logging beyond strict operational minimum (response time,
  error rate) for no more than 30 days.

## Provider selection criteria

Evaluation for the Tier 3 provider (Anthropic / Google /
OpenAI — one choice, not multi-model):

| Criterion | Weight |
|---|---|
| Zero-retention enforced via DPA | Required |
| Data residency — EU region available | Required for EU market |
| No training use of API inputs | Required |
| SOC 2 Type II certified | Required |
| Automated decision-making disclosure available | Required |
| Pricing per summary ≤ $0.001 at target volume | Required for v1.1 economics |
| Latency ≤ 3s for 7-day summary payload | Required for UX |

Final provider decision gates on B-2 RevenueCat (pricing
economics need paid-user volume data) and counsel review of
the DPA. Not decided as of 2026-04.

## Sibling artifacts

- [`pia-quebec-cloud-ai.md`](./pia-quebec-cloud-ai.md) —
  Quebec Law 25 PIA
- [`../gtm/ai-non-claims.md`](../gtm/ai-non-claims.md) —
  consumer-facing AI-claim blocklist
- [`../store-listing/health-claim-guardrails.md`](../store-listing/health-claim-guardrails.md)
  — store-listing red-list
- [`../../lib/legal/privacy_policy.dart`](../../lib/legal/privacy_policy.dart)
  — will be updated at Tier 3 launch to disclose provider +
  data flow (Task 9.7 nutrition label rewrite pair)
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.4 Art. 9 consent, Task 12.13 source
- [`../plans/epic-04-product.md`](../plans/epic-04-product.md)
  — Task 4.7 AI recap feature plan
- [`../../memory/project_ai_recap_plan.md`](../../memory/project_ai_recap_plan.md)
  — internal AI feature plan (template free / Gemini Nano
  free on Pixel / cloud premium)
